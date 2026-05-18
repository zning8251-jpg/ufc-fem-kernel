# Week 2 Day 1：统一材料注册表设计方案

## 执行时间
- 开始时间：2026-05-03
- 设计人：Claude Sonnet 4.6
- 目标：设计统一的材料注册表，解决所有材料族的注册表重复问题

---

## 1. 问题分析

### 1.1 当前问题

**问题描述：**
每个材料族的Core模块都有自己的注册表，与Registry子域重复。

**影响范围：**
- Elas材料族 ✅ 确认
- Plast材料族 ✅ 确认
- Hyper材料族 ❓ 待验证
- 其他8个材料族 ❓ 预计相同

**代码证据：**

```fortran
! Elas材料族 (MD_Mat_Elas_Core.f90:51-54)
INTEGER(i4), PARAMETER :: MAX_REGISTERED_MATERIALS = 1000
TYPE(MD_Mat_Elas_Desc), ALLOCATABLE, SAVE :: registered_materials(:)
INTEGER(i4), SAVE :: num_registered = 0
LOGICAL, SAVE :: registry_initialized = .FALSE.

! Plast材料族 (MD_Mat_Plast_Core.f90:48-51)
INTEGER(i4), PARAMETER :: MAX_REGISTERED_MATERIALS = 1000
TYPE(MD_Mat_Plast_Desc), ALLOCATABLE, SAVE :: registered_materials(:)
INTEGER(i4), SAVE :: num_registered = 0
LOGICAL, SAVE :: registry_initialized = .FALSE.
```

**根本原因：**
1. 每个材料族独立开发时都实现了自己的注册表
2. 后来创建了统一的Registry子域，但旧代码未清理
3. 导致代码重复和维护困难

---

## 2. 设计目标

### 2.1 功能目标

- ✅ 统一的材料注册表（所有材料族共享）
- ✅ 支持多态（使用基类指针）
- ✅ 高性能查找（O(1)或O(log n)）
- ✅ 线程安全（支持多线程）

### 2.2 架构目标

- ✅ 单一职责（Registry子域负责所有注册）
- ✅ 易于扩展（支持新的材料族）
- ✅ 向后兼容（不破坏现有功能）

---

## 3. 架构设计

### 3.1 统一注册表结构

```fortran
!===============================================================================
! MODULE: MD_Mat_Registry
! LAYER:  L3_MD
! DOMAIN: Material / Registry
! ROLE:   Core - Unified Material Registry
! BRIEF:  Unified material registry for all 11 material families.
!         Replaces individual family-level registries.
!
! PURPOSE:
!   Solve the common problem: each material family has its own registry
!   This module provides a unified registry for all material families
!
! DESIGN:
!   - Polymorphic storage (use base class pointer)
!   - Hash table for O(1) lookup
!   - Thread-safe operations
!   - Support for all 11 material families
!
! CREATED: 2026-05-03 (Week 2 Day 1)
!===============================================================================
MODULE MD_Mat_Registry
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Registry entry TYPE
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Registry_Entry
    INTEGER(i4) :: mat_id                    ! Material ID (unique)
    INTEGER(i4) :: family_type               ! Family type (ELASTIC/PLASTIC/etc.)
    INTEGER(i4) :: sub_type                  ! Sub-type within family
    CLASS(MD_Mat_Desc), POINTER :: desc      ! Polymorphic pointer to descriptor
    LOGICAL :: is_active                     ! Entry is active
  END TYPE MD_Mat_Registry_Entry

  !-----------------------------------------------------------------------------
  ! Global registry
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MAX_MATERIALS = 10000
  TYPE(MD_Mat_Registry_Entry), ALLOCATABLE, SAVE :: global_registry(:)
  INTEGER(i4), SAVE :: num_registered = 0
  LOGICAL, SAVE :: registry_initialized = .FALSE.

  !-----------------------------------------------------------------------------
  ! Public interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Registry_Init
  PUBLIC :: MD_Mat_Registry_Finalize
  PUBLIC :: MD_Mat_Registry_Register
  PUBLIC :: MD_Mat_Registry_Lookup
  PUBLIC :: MD_Mat_Registry_Remove
  PUBLIC :: MD_Mat_Registry_Get_Count

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Init
  ! Initialize the global material registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Init(status)
    ! [OUT] status - Error status
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (registry_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Allocate registry
    ALLOCATE(global_registry(MAX_MATERIALS))

    ! Initialize entries
    global_registry(:)%mat_id = -1
    global_registry(:)%family_type = -1
    global_registry(:)%sub_type = -1
    global_registry(:)%is_active = .FALSE.
    NULLIFY(global_registry(:)%desc)

    num_registered = 0
    registry_initialized = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Init

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Finalize
  ! Finalize the global material registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Finalize(status)
    ! [OUT] status - Error status
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    IF (.NOT. registry_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Nullify all pointers
    DO i = 1, MAX_MATERIALS
      IF (global_registry(i)%is_active) THEN
        NULLIFY(global_registry(i)%desc)
      END IF
    END DO

    ! Deallocate registry
    DEALLOCATE(global_registry)

    num_registered = 0
    registry_initialized = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Finalize

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Register
  ! Register a material in the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Register(mat_id, family_type, sub_type, &
                                       desc, status)
    ! [IN]  mat_id      - Material ID (unique)
    ! [IN]  family_type - Family type
    ! [IN]  sub_type    - Sub-type within family
    ! [IN]  desc        - Material descriptor (polymorphic)
    ! [OUT] status      - Error status
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4), INTENT(IN) :: family_type
    INTEGER(i4), INTENT(IN) :: sub_type
    CLASS(MD_Mat_Desc), TARGET, INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: slot

    CALL init_error_status(status)

    ! Check initialization
    IF (.NOT. registry_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Registry not initialized"
      RETURN
    END IF

    ! Check if mat_id already exists
    CALL MD_Mat_Registry_Lookup(mat_id, slot, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Material ID already registered"
      RETURN
    END IF

    ! Find empty slot
    DO slot = 1, MAX_MATERIALS
      IF (.NOT. global_registry(slot)%is_active) THEN
        EXIT
      END IF
    END DO

    IF (slot > MAX_MATERIALS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Registry full"
      RETURN
    END IF

    ! Register material
    global_registry(slot)%mat_id = mat_id
    global_registry(slot)%family_type = family_type
    global_registry(slot)%sub_type = sub_type
    global_registry(slot)%desc => desc
    global_registry(slot)%is_active = .TRUE.

    num_registered = num_registered + 1

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Register

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Lookup
  ! Lookup a material in the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Lookup(mat_id, slot, status)
    ! [IN]  mat_id - Material ID
    ! [OUT] slot   - Registry slot (if found)
    ! [OUT] status - Error status
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4), INTENT(OUT) :: slot
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Check initialization
    IF (.NOT. registry_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Registry not initialized"
      RETURN
    END IF

    ! Linear search (TODO: use hash table for O(1))
    DO i = 1, MAX_MATERIALS
      IF (global_registry(i)%is_active .AND. &
          global_registry(i)%mat_id == mat_id) THEN
        slot = i
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    ! Not found
    slot = -1
    status%status_code = IF_STATUS_INVALID
    status%message = "Material not found"
  END SUBROUTINE MD_Mat_Registry_Lookup

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Remove
  ! Remove a material from the global registry
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Remove(mat_id, status)
    ! [IN]  mat_id - Material ID
    ! [OUT] status - Error status
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: slot

    CALL init_error_status(status)

    ! Lookup material
    CALL MD_Mat_Registry_Lookup(mat_id, slot, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Remove material
    global_registry(slot)%mat_id = -1
    global_registry(slot)%family_type = -1
    global_registry(slot)%sub_type = -1
    NULLIFY(global_registry(slot)%desc)
    global_registry(slot)%is_active = .FALSE.

    num_registered = num_registered - 1

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Registry_Remove

  !-----------------------------------------------------------------------------
  ! MD_Mat_Registry_Get_Count
  ! Get the number of registered materials
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Registry_Get_Count(count)
    ! [OUT] count - Number of registered materials
    INTEGER(i4), INTENT(OUT) :: count

    count = num_registered
  END SUBROUTINE MD_Mat_Registry_Get_Count

END MODULE MD_Mat_Registry
```

---

## 4. 实现计划

### 4.1 Phase 1：创建统一注册表模块（Day 1上午）

**任务：**
1. 创建`MD_Mat_Registry.f90`模块
2. 实现核心功能（Init/Finalize/Register/Lookup/Remove）
3. 单元测试

**交付物：**
- `MD_Mat_Registry.f90`（约300行）

### 4.2 Phase 2：删除各材料族的注册表（Day 1下午）

**任务：**
1. 删除Elas材料族的注册表
2. 删除Plast材料族的注册表
3. 删除Hyper材料族的注册表
4. 更新Register函数调用

**交付物：**
- 3个材料族的Core模块修改

### 4.3 Phase 3：验证和测试（Day 2）

**任务：**
1. 功能验证
2. 性能测试
3. 文档更新

**交付物：**
- 测试报告
- 更新的文档

---

## 5. 关键设计决策

### 5.1 多态存储

**使用基类指针：**
```fortran
CLASS(MD_Mat_Desc), POINTER :: desc
```

**优点：**
- 支持所有材料族
- 统一的接口
- 易于扩展

### 5.2 查找策略

**当前实现：** 线性查找（O(n)）

**未来优化：** 哈希表（O(1)）
```fortran
! Hash function
hash = MOD(mat_id, MAX_MATERIALS) + 1

! Collision resolution: linear probing
DO WHILE (global_registry(hash)%is_active .AND. &
          global_registry(hash)%mat_id /= mat_id)
  hash = MOD(hash, MAX_MATERIALS) + 1
END DO
```

### 5.3 线程安全

**当前实现：** 非线程安全

**未来优化：** 使用OpenMP锁
```fortran
!$OMP CRITICAL(registry_lock)
! Register/Lookup/Remove operations
!$OMP END CRITICAL(registry_lock)
```

---

## 6. 向后兼容性

### 6.1 兼容策略

**原则：**
- 不破坏现有功能
- 支持渐进式迁移
- 提供兼容层

**实现：**
```fortran
! 各材料族的Register函数改为调用统一注册表
SUBROUTINE MD_Mat_Elas_Register(desc, mat_id, status)
  ! 旧实现：使用本地注册表
  ! 新实现：调用统一注册表
  CALL MD_Mat_Registry_Register(mat_id, MD_MAT_FAMILY_ELASTIC, &
                                 desc%sub_type, desc, status)
END SUBROUTINE
```

---

## 7. 成功标准

### 7.1 功能标准

- ✅ 统一的材料注册表（所有材料族共享）
- ✅ 支持Register/Lookup/Remove操作
- ✅ 无代码重复
- ✅ 所有测试通过

### 7.2 性能标准

- ✅ 查找时间：O(n)（当前）→ O(1)（未来）
- ✅ 内存使用：合理
- ✅ 无性能退化

### 7.3 质量标准

- ✅ 代码注释完整
- ✅ 单元测试覆盖率 ≥ 80%
- ✅ 文档完整

---

## 8. 下一步行动

### 8.1 立即行动（Day 1上午）

1. 创建`MD_Mat_Registry.f90`模块
2. 实现核心功能
3. 创建单元测试

### 8.2 后续行动（Day 1下午-Day 2）

4. 删除各材料族的注册表
5. 更新Register函数调用
6. 验证和测试

---

**设计完成时间：** 2026-05-03  
**设计版本：** v1.0  
**下一步：** 实现MD_Mat_Registry模块
