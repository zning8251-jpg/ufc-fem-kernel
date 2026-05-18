# L3_MD层Group_ID转换函数设计

## 文档概述

本文档规范化UFC三维正交坐标Group_ID的外部API和内部实现两层转换机制：
- **外部API层（用户可见）**：1-based编号 [1-5][1-4][1-12]
- **内部实现层（L3_MD存储）**：0-based索引 [0-4][0-3][0-11]

这种**两层API设计**确保：
✅ 用户友好性：与ABAQUS PROC编号习惯一致  
✅ 实现高效性：内部使用0-based索引避免复杂转换  
✅ 兼容性：向外暴露1-based，向内使用0-based  

---

## 1️⃣ 坐标编号体系对比

### 1.1 外部API编号（用户层）- **1-based**

```
用户指定分析类型时使用1-based编号

Solver范围：    1-5  (Standard, Explicit, Acoustic, EM, CFD)
Coupling范围：  1-4  (OneShot, OneWay, Weak, Strong)
Physics范围：   1-12 (Structure, Thermal, ..., Special)

Group_ID编码公式（1-based）：
  Group_ID = Solver × 100 + Coupling × 10 + Physics
           = [1-5] × 100 + [1-4] × 10 + [1-12]

示例：
  [1][1][1] = 111   → Standard + OneShot + Structure
  [1][3][7] = 137   → Standard + Weak + ThermalStruct
  [1][4][8] = 148   → Standard + Strong + ElectroStruct
  [5][4][9] = 549   → CFD + Strong + FluidStruct(FSI)
```

### 1.2 内部实现编号（L3_MD存储）- **0-based**

```
L3_MD存储和矩阵运算时使用0-based索引

Solver范围：    0-4  (对应1-5)
Coupling范围：  0-3  (对应1-4)
Physics范围：   0-11 (对应1-12)

内部索引转换：
  Internal_Idx = (Solver - 1) × 100 + (Coupling - 1) × 10 + (Physics - 1)
               = [0-4] × 100 + [0-3] × 10 + [0-11]

存储矩阵：
  COMPAT_MATRIX(0:4, 0:3, 0:11)  ! 0-based索引的约束矩阵

示例转换：
  用户输入: [1][1][1] (1-based)
  转换为: [0][0][0] (0-based for storage)
  
  用户输入: [1][3][7] (1-based)
  转换为: [0][2][6] (0-based for storage)
```

---

## 2️⃣ Fortran实现框架

### 2.1 TYPE定义（L3_MD_Group_DESC）

```fortran
! ========== L3_MD/mod_analysis_group.f90 ==========

MODULE MD_Analysis_Group_Module
  IMPLICIT NONE
  
  ! 3D坐标类型定义（用户看到的是1-based）
  TYPE :: MD_Analysis_Group_DESC
    ! 外部API编号（1-based，用户可见）
    INTEGER :: solver_1based      ! 1-5
    INTEGER :: coupling_1based    ! 1-4
    INTEGER :: physics_1based     ! 1-12
    
    ! 内部索引（0-based，用于矩阵访问）
    INTEGER :: solver_idx         ! 0-4
    INTEGER :: coupling_idx       ! 0-3
    INTEGER :: physics_idx        ! 0-11
    
    ! 编码值（方便传递）
    INTEGER :: group_id           ! Solver×100 + Coupling×10 + Physics (1-based)
    INTEGER :: group_internal     ! 内部运算用0-based编码
    
    ! 有效性检查
    LOGICAL :: is_valid           ! 是否为有效组合
  END TYPE MD_Analysis_Group_DESC
  
  ! 约束矩阵（0-based索引）
  INTEGER, PARAMETER :: COMPAT_MATRIX(0:4, 0:3, 0:11) = &
    RESHAPE([ ... ], SHAPE=[5, 4, 12])

CONTAINS

  ! ========== 核心转换函数 ==========
  
  SUBROUTINE initialize_group_from_external_api( &
      solver_id, coupling_id, physics_id, group_desc, error)
    !! 从外部API的1-based编号初始化Group_DESC
    
    INTEGER, INTENT(IN) :: solver_id       ! 1-5 (1-based)
    INTEGER, INTENT(IN) :: coupling_id     ! 1-4 (1-based)
    INTEGER, INTENT(IN) :: physics_id      ! 1-12 (1-based)
    TYPE(MD_Analysis_Group_DESC), INTENT(OUT) :: group_desc
    INTEGER, INTENT(OUT) :: error
    
    ! 输入验证（1-based范围检查）
    IF (solver_id < 1 .OR. solver_id > 5) THEN
      error = -1  ! 无效的Solver
      RETURN
    END IF
    IF (coupling_id < 1 .OR. coupling_id > 4) THEN
      error = -2  ! 无效的Coupling
      RETURN
    END IF
    IF (physics_id < 1 .OR. physics_id > 12) THEN
      error = -3  ! 无效的Physics
      RETURN
    END IF
    
    ! 保存外部API编号（1-based）
    group_desc%solver_1based = solver_id
    group_desc%coupling_1based = coupling_id
    group_desc%physics_1based = physics_id
    
    ! 转换为内部0-based索引
    group_desc%solver_idx = solver_id - 1       ! 0-4
    group_desc%coupling_idx = coupling_id - 1   ! 0-3
    group_desc%physics_idx = physics_id - 1     ! 0-11
    
    ! 计算编码值（使用1-based）
    group_desc%group_id = solver_id * 100 + coupling_id * 10 + physics_id
    
    ! 计算内部运算编码（使用0-based）
    group_desc%group_internal = group_desc%solver_idx * 100 + &
                                group_desc%coupling_idx * 10 + &
                                group_desc%physics_idx
    
    ! 检查有效性（使用0-based索引访问矩阵）
    IF (COMPAT_MATRIX(group_desc%solver_idx, &
                      group_desc%coupling_idx, &
                      group_desc%physics_idx) == 0) THEN
      group_desc%is_valid = .FALSE.
      error = -4  ! 无效的组合
      RETURN
    END IF
    
    group_desc%is_valid = .TRUE.
    error = 0
    
  END SUBROUTINE initialize_group_from_external_api
  
  
  SUBROUTINE get_group_external_api(group_desc, solver_id, &
                                    coupling_id, physics_id)
    !! 获取Group的外部API编号（1-based）
    
    TYPE(MD_Analysis_Group_DESC), INTENT(IN) :: group_desc
    INTEGER, INTENT(OUT) :: solver_id, coupling_id, physics_id
    
    solver_id = group_desc%solver_1based
    coupling_id = group_desc%coupling_1based
    physics_id = group_desc%physics_1based
    
  END SUBROUTINE get_group_external_api
  
  
  SUBROUTINE get_group_internal_index(group_desc, solver_idx, &
                                      coupling_idx, physics_idx)
    !! 获取Group的内部0-based索引（用于矩阵访问）
    
    TYPE(MD_Analysis_Group_DESC), INTENT(IN) :: group_desc
    INTEGER, INTENT(OUT) :: solver_idx, coupling_idx, physics_idx
    
    solver_idx = group_desc%solver_idx
    coupling_idx = group_desc%coupling_idx
    physics_idx = group_desc%physics_idx
    
  END SUBROUTINE get_group_internal_index
  
  
  SUBROUTINE print_group_info(group_desc)
    !! 打印Group信息（展示两套编号）
    
    TYPE(MD_Analysis_Group_DESC), INTENT(IN) :: group_desc
    CHARACTER(len=64) :: solver_name, coupling_name, physics_name
    
    ! 获取名称
    CALL get_solver_name(group_desc%solver_1based, solver_name)
    CALL get_coupling_name(group_desc%coupling_1based, coupling_name)
    CALL get_physics_name(group_desc%physics_1based, physics_name)
    
    ! 打印信息
    PRINT *, "=== UFC Group Information ==="
    PRINT *, "External API (1-based):"
    PRINT *, "  Solver:  ", group_desc%solver_1based, " (", TRIM(solver_name), ")"
    PRINT *, "  Coupling:", group_desc%coupling_1based, " (", TRIM(coupling_name), ")"
    PRINT *, "  Physics: ", group_desc%physics_1based, " (", TRIM(physics_name), ")"
    PRINT *, "  Group_ID:", group_desc%group_id
    PRINT *, ""
    PRINT *, "Internal (0-based for L3_MD):"
    PRINT *, "  Indices: [", group_desc%solver_idx, "][", &
             group_desc%coupling_idx, "][", group_desc%physics_idx, "]"
    PRINT *, "  Status:  ", MERGE("VALID  ", "INVALID", group_desc%is_valid)
    
  END SUBROUTINE print_group_info

END MODULE MD_Analysis_Group_Module
```

---

## 3️⃣ 约束矩阵映射（0-based）

### 3.1 约束矩阵初始化

```fortran
! 约束矩阵使用0-based索引 [0:4, 0:3, 0:11]
! 值为1表示有效，0表示无效

INTEGER, PARAMETER :: COMPAT_MATRIX(0:4, 0:3, 0:11) = &
  RESHAPE([ &
    ! Solver=0 (Standard)
    !  Coupling=0(OneShot)        Coupling=1(OneWay)         Coupling=2(Weak)           Coupling=3(Strong)
    !  P0 P1 P2 ... P11           P0 P1 P2 ... P11            P0 P1 P2 ... P11           P0 P1 P2 ... P11
    1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, &  ! Physics 0-11
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, &
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, &
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, &
    
    ! Solver=1 (Explicit)
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! OneShot
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! OneWay (not allowed)
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! Weak (not allowed)
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! Strong (not allowed)
    
    ! Solver=2 (Acoustic)
    0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, &  ! OneShot
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! OneWay
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! Weak
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! Strong
    
    ! Solver=3 (EM)
    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, &  ! OneShot
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! OneWay
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! Weak
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! Strong
    
    ! Solver=4 (CFD)
    0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, &  ! OneShot
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, &  ! OneWay
    0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, &  ! Weak
    0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0  &  ! Strong
  ], SHAPE=[5, 4, 12])
```

---

## 4️⃣ PROC到Group_ID的1-based映射

### 4.1 关键PROC映射表

```fortran
! ========== PROC_ID到Group_ID的映射表 ==========

TYPE :: PROC_To_Group_Mapping
  INTEGER :: proc_id
  INTEGER :: solver_1based
  INTEGER :: coupling_1based
  INTEGER :: physics_1based
  CHARACTER(len=32) :: analysis_type
END TYPE

TYPE(PROC_To_Group_Mapping), PARAMETER :: PROC_MAPPING(:) = [ &
  ! PROC 1-10: 结构准静态/瞬态
  PROC_To_Group_Mapping(1, 1, 1, 1, "Static"),           ! [1][1][1]
  PROC_To_Group_Mapping(10, 1, 1, 1, "Quasistatic"),     ! [1][1][1]
  
  ! PROC 32: 热-结构耦合
  PROC_To_Group_Mapping(32, 1, 3, 7, "ThermalStruct"),   ! [1][3][7]
  
  ! PROC 34: 热-结构瞬态
  PROC_To_Group_Mapping(34, 1, 3, 7, "ThermalTransient"),! [1][3][7]
  
  ! PROC 35: 电-结构耦合
  PROC_To_Group_Mapping(35, 1, 4, 8, "ElectroStruct"),   ! [1][4][8]
  
  ! PROC 33: 多场耦合
  PROC_To_Group_Mapping(33, 1, 4, 11, "MultiField"),     ! [1][4][11]
  
  ! ... 其他PROC映射
]

CONTAINS

  SUBROUTINE map_proc_to_group(proc_id, group_desc, error)
    !! 从PROC_ID获取对应的Group_DESC
    
    INTEGER, INTENT(IN) :: proc_id
    TYPE(MD_Analysis_Group_DESC), INTENT(OUT) :: group_desc
    INTEGER, INTENT(OUT) :: error
    
    INTEGER :: i
    LOGICAL :: found
    
    found = .FALSE.
    DO i = 1, SIZE(PROC_MAPPING)
      IF (PROC_MAPPING(i)%proc_id == proc_id) THEN
        CALL initialize_group_from_external_api( &
          PROC_MAPPING(i)%solver_1based, &
          PROC_MAPPING(i)%coupling_1based, &
          PROC_MAPPING(i)%physics_1based, &
          group_desc, error)
        found = .TRUE.
        EXIT
      END IF
    END DO
    
    IF (.NOT. found) THEN
      error = -5  ! PROC not found
    END IF
    
  END SUBROUTINE map_proc_to_group

END MODULE
```

---

## 5️⃣ 用户文档指南

### 5.1 外部API使用指南（用户看到）

**用户编程时**：
```fortran
! 用户代码（使用1-based编号）
INTEGER :: solver, coupling, physics
INTEGER :: error

solver = 1      ! Standard
coupling = 3    ! Weak
physics = 7     ! ThermalStruct

! 调用初始化函数（自动处理1-based到0-based的转换）
TYPE(MD_Analysis_Group_DESC) :: group
CALL initialize_group_from_external_api(solver, coupling, physics, group, error)

! 验证有效性
IF (error /= 0) THEN
  PRINT *, "Invalid group combination"
END IF

! 打印信息（展示两套编号供开发者参考）
CALL print_group_info(group)
```

**输出示例**：
```
=== UFC Group Information ===
External API (1-based):
  Solver:  1 (Standard)
  Coupling: 3 (Weak)
  Physics: 7 (ThermalStruct)
  Group_ID: 137

Internal (0-based for L3_MD):
  Indices: [0][2][6]
  Status: VALID
```

### 5.2 验收标准

✅ **所有PROC-to-Group映射使用1-based表示**  
✅ **转换函数正确处理1-based↔0-based转换**  
✅ **约束矩阵内部使用0-based索引**  
✅ **用户API和内部实现完全解耦**  
✅ **打印输出同时展示两套编号便于调试**  

---

## 6️⃣ 总结

| 维度 | 外部API | 内部实现 | 转换公式 |
|------|--------|--------|---------|
| Solver | 1-5 | 0-4 | internal = external - 1 |
| Coupling | 1-4 | 0-3 | internal = external - 1 |
| Physics | 1-12 | 0-11 | internal = external - 1 |
| Group_ID | [1-5][1-4][1-12] | [0-4][0-3][0-11] | matrix[idx] = idx + 1 for user |

**关键优势**：
- 🎯 用户友好：1-based符合工程直观
- ⚙️ 实现高效：0-based便于矩阵运算
- 🔄 转换透明：自动在API边界处理
- 📊 可追踪：同时输出两套编号便于调试

