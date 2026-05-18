# Week 2 Day 3：统一L5调度机制设计方案

## 执行时间
- 开始时间：2026-05-03
- 设计人：Claude Sonnet 4.6
- 目标：设计统一的L5调度机制，解决所有材料族的调度重复问题

---

## 1. 问题分析

### 1.1 当前问题

**问题描述：**
每个材料族的L5层都有自己的调度机制（RT_Mat_XXX_Core），与L5_RT子域重复。

**影响范围：**
- Elas材料族 ✅ 确认（RT_Mat_Elas_Core.f90）
- Plast材料族 ✅ 确认（RT_Mat_Plast_Core.f90）
- Hyper材料族 ✅ 确认（RT_Mat_Hyper_Core.f90）
- 其他8个材料族 ❓ 预计相同

**代码证据：**

```fortran
! RT_Mat_Core.f90 - 统一调度入口
MODULE RT_Mat_Core
  ! 包含材料族路由逻辑
  SUBROUTINE RT_Mat_Compute(...)
    SELECT CASE (family_type)
      CASE (MD_MAT_FAMILY_ELASTIC)
        CALL RT_Mat_Elas_Compute(...)
      CASE (MD_MAT_FAMILY_PLASTIC)
        CALL RT_Mat_Plast_Compute(...)
      ! ...
    END SELECT
  END SUBROUTINE
END MODULE

! RT_Mat_Elas_Core.f90 - Elas材料族调度
MODULE RT_Mat_Elas_Core
  SUBROUTINE RT_Mat_Elas_Compute(...)
    ! Elas材料族的计算逻辑
  END SUBROUTINE
END MODULE

! RT_Mat_Plast_Core.f90 - Plast材料族调度
MODULE RT_Mat_Plast_Core
  SUBROUTINE RT_Mat_Plast_Compute(...)
    ! Plast材料族的计算逻辑
  END SUBROUTINE
END MODULE
```

**根本原因：**
1. 每个材料族独立开发时都实现了自己的L5调度
2. RT_Mat_Core作为统一入口，但各材料族仍有独立调度
3. 导致代码重复和维护困难

---

## 2. 设计目标

### 2.1 功能目标

- ✅ 统一的L5调度机制（所有材料族共享）
- ✅ 支持材料族路由（基于family_type）
- ✅ 高性能调度（O(1)查找）
- ✅ 易于扩展（支持新的材料族）

### 2.2 架构目标

- ✅ 单一职责（RT_Mat_Core负责所有调度）
- ✅ 清晰的接口（统一的Compute接口）
- ✅ 向后兼容（不破坏现有功能）

---

## 3. 架构设计

### 3.1 当前架构分析

**当前数据流：**
```
Element计算
  → RT_Mat_Core::RT_Mat_Compute (统一入口)
    → SELECT CASE (family_type)
      → RT_Mat_Elas_Core::RT_Mat_Elas_Compute (Elas调度)
      → RT_Mat_Plast_Core::RT_Mat_Plast_Compute (Plast调度)
      → RT_Mat_Hyper_Core::RT_Mat_Hyper_Compute (Hyper调度)
      → ...
```

**问题：**
- RT_Mat_Core已经是统一入口
- 但各材料族仍有独立的Core模块
- 这些Core模块主要是调度逻辑，不是计算逻辑

### 3.2 优化后的架构

**优化后的数据流：**
```
Element计算
  → RT_Mat_Dispatch::RT_Mat_Dispatch_Compute (统一调度)
    → 基于family_type和sub_type路由
    → 直接调用L4层计算函数
      → PH_Mat_Elas_Compute (L4计算)
      → PH_Mat_Plast_Compute (L4计算)
      → PH_Mat_Hyper_Compute (L4计算)
```

**优点：**
- 消除L5层的重复调度代码
- 直接调用L4层计算函数
- 简化架构，减少层级

---

## 4. 设计决策

### 4.1 决策1：保留RT_Mat_Core还是创建新模块？

**选项A：保留RT_Mat_Core，增强其功能**
- 优点：向后兼容，不破坏现有代码
- 缺点：RT_Mat_Core已经存在，可能有历史包袱

**选项B：创建RT_Mat_Dispatch新模块**
- 优点：清晰的职责，全新设计
- 缺点：需要更新调用方

**推荐：选项A - 保留RT_Mat_Core**
- 理由：RT_Mat_Core已经是统一入口，增强其功能更合理

### 4.2 决策2：删除各材料族的Core模块？

**选项A：完全删除RT_Mat_XXX_Core模块**
- 优点：彻底消除重复
- 缺点：可能破坏现有代码

**选项B：保留但简化RT_Mat_XXX_Core模块**
- 优点：向后兼容
- 缺点：仍有部分重复

**推荐：选项B - 保留但简化**
- 理由：保持向后兼容，逐步迁移

---

## 5. 实现方案

### 5.1 增强RT_Mat_Core模块

```fortran
!===============================================================================
! MODULE: RT_Mat_Core
! LAYER:  L5_RT
! DOMAIN: Material
! ROLE:   Core - Unified Material Dispatch
! BRIEF:  Unified material dispatch for all 11 material families.
!         Routes material computations to appropriate L4 functions.
!
! ENHANCED: Week 2 Day 3 - Unified dispatch mechanism
!===============================================================================
MODULE RT_Mat_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE MD_Mat_Family_Def, ONLY: MD_MAT_FAMILY_ELASTIC, &
                                MD_MAT_FAMILY_PLASTIC, &
                                MD_MAT_FAMILY_HYPERELASTIC
  ! Import L4 compute functions
  USE PH_Mat_Elas_Core, ONLY: PH_Mat_Elas_Compute
  USE PH_Mat_Plast_Core, ONLY: PH_Mat_Plast_Compute
  USE PH_Mat_Hyper_Core, ONLY: PH_Mat_Hyper_Compute
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Compute
  PUBLIC :: RT_Mat_Update_State

CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Mat_Compute
  ! Unified material computation dispatch
  ! ENHANCED: Direct dispatch to L4 functions
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Compute(family_type, sub_type, mat_id, &
                            strain, stress, ddsdde, &
                            state_vars, temp, dtemp, &
                            status)
    ! [IN]  family_type - Material family type
    ! [IN]  sub_type    - Material sub-type
    ! [IN]  mat_id      - Material ID
    ! [IN]  strain      - Strain tensor
    ! [OUT] stress      - Stress tensor
    ! [OUT] ddsdde      - Material tangent
    ! [INOUT] state_vars - State variables
    ! [IN]  temp        - Temperature
    ! [IN]  dtemp       - Temperature increment
    ! [OUT] status      - Error status
    INTEGER(i4), INTENT(IN) :: family_type
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: mat_id
    REAL(wp), INTENT(IN) :: strain(:)
    REAL(wp), INTENT(OUT) :: stress(:)
    REAL(wp), INTENT(OUT) :: ddsdde(:,:)
    REAL(wp), INTENT(INOUT) :: state_vars(:)
    REAL(wp), INTENT(IN) :: temp
    REAL(wp), INTENT(IN) :: dtemp
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Dispatch based on family type
    SELECT CASE (family_type)
    CASE (MD_MAT_FAMILY_ELASTIC)
      ! Direct call to L4 elastic computation
      CALL PH_Mat_Elas_Compute(sub_type, mat_id, &
                               strain, stress, ddsdde, &
                               temp, dtemp, status)

    CASE (MD_MAT_FAMILY_PLASTIC)
      ! Direct call to L4 plastic computation
      CALL PH_Mat_Plast_Compute(sub_type, mat_id, &
                                strain, stress, ddsdde, &
                                state_vars, temp, dtemp, status)

    CASE (MD_MAT_FAMILY_HYPERELASTIC)
      ! Direct call to L4 hyperelastic computation
      CALL PH_Mat_Hyper_Compute(sub_type, mat_id, &
                                strain, stress, ddsdde, &
                                temp, dtemp, status)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "Unknown material family type"
    END SELECT

  END SUBROUTINE RT_Mat_Compute

END MODULE RT_Mat_Core
```

### 5.2 简化RT_Mat_XXX_Core模块

```fortran
!===============================================================================
! MODULE: RT_Mat_Elas_Core
! LAYER:  L5_RT
! DOMAIN: Material / Elas
! ROLE:   Core - Elastic Material Runtime (SIMPLIFIED)
! BRIEF:  Simplified wrapper for elastic material computations.
!         Main dispatch logic moved to RT_Mat_Core.
!
! SIMPLIFIED: Week 2 Day 3 - Removed duplicate dispatch logic
!===============================================================================
MODULE RT_Mat_Elas_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE PH_Mat_Elas_Core, ONLY: PH_Mat_Elas_Compute
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Elas_Compute

CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Mat_Elas_Compute
  ! Wrapper for elastic material computation
  ! SIMPLIFIED: Direct call to L4 function
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Elas_Compute(sub_type, mat_id, &
                                 strain, stress, ddsdde, &
                                 temp, dtemp, status)
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: mat_id
    REAL(wp), INTENT(IN) :: strain(:)
    REAL(wp), INTENT(OUT) :: stress(:)
    REAL(wp), INTENT(OUT) :: ddsdde(:,:)
    REAL(wp), INTENT(IN) :: temp
    REAL(wp), INTENT(IN) :: dtemp
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Direct call to L4 computation
    CALL PH_Mat_Elas_Compute(sub_type, mat_id, &
                             strain, stress, ddsdde, &
                             temp, dtemp, status)
  END SUBROUTINE RT_Mat_Elas_Compute

END MODULE RT_Mat_Elas_Core
```

---

## 6. 实现计划

### 6.1 Phase 1：分析现有调度机制（Day 3上午）✅

**任务：**
1. 读取RT_Mat_Core.f90
2. 读取RT_Mat_Elas_Core.f90
3. 读取RT_Mat_Plast_Core.f90
4. 读取RT_Mat_Hyper_Core.f90
5. 识别重复的调度逻辑

**交付物：**
- 调度机制分析报告

### 6.2 Phase 2：设计统一调度方案（Day 3下午）

**任务：**
1. 设计增强的RT_Mat_Core
2. 设计简化的RT_Mat_XXX_Core
3. 设计迁移策略

**交付物：**
- 统一调度设计文档（本文档）

### 6.3 Phase 3：实现统一调度（Day 4上午）

**任务：**
1. 增强RT_Mat_Core模块
2. 简化RT_Mat_Elas_Core
3. 简化RT_Mat_Plast_Core
4. 简化RT_Mat_Hyper_Core

**交付物：**
- 更新的RT_Mat_Core.f90
- 简化的RT_Mat_XXX_Core.f90

### 6.4 Phase 4：验证和测试（Day 4下午）

**任务：**
1. 功能验证
2. 性能测试
3. 文档更新

**交付物：**
- 测试报告
- 更新的文档

---

## 7. 向后兼容性

### 7.1 兼容策略

**原则：**
- 保留RT_Mat_XXX_Core模块（简化为wrapper）
- 不破坏现有调用方
- 支持渐进式迁移

**实现：**
```fortran
! 旧代码仍然可以调用
CALL RT_Mat_Elas_Compute(...)

! 新代码可以直接调用统一入口
CALL RT_Mat_Compute(MD_MAT_FAMILY_ELASTIC, ...)
```

---

## 8. 成功标准

### 8.1 功能标准

- ✅ 统一的L5调度机制（RT_Mat_Core）
- ✅ 支持所有11个材料族
- ✅ 向后兼容（保留RT_Mat_XXX_Core）
- ✅ 所有测试通过

### 8.2 性能标准

- ✅ 调度性能：O(1)（SELECT CASE）
- ✅ 无性能退化
- ✅ 内存使用：合理

### 8.3 质量标准

- ✅ 代码注释完整
- ✅ 单元测试覆盖率 ≥ 80%
- ✅ 文档完整

---

## 9. 风险评估

### 9.1 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 破坏现有调用 | 低 | 高 | 保留RT_Mat_XXX_Core |
| 性能退化 | 低 | 中 | 性能测试 |
| L4接口不统一 | 中 | 中 | 标准化L4接口 |

---

## 10. 下一步行动

### 10.1 立即行动（Day 3下午）

1. 完成本设计文档
2. 创建git commit
3. 准备Day 4的实现工作

### 10.2 后续行动（Day 4）

4. 增强RT_Mat_Core模块
5. 简化RT_Mat_XXX_Core模块
6. 验证和测试

---

**设计完成时间：** 2026-05-03  
**设计版本：** v1.0  
**下一步：** Day 4 - 实现统一调度机制
