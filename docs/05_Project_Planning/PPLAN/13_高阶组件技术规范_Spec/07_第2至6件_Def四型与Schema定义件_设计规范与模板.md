# 第 2-6 件：Def (四型与 Schema 定义件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/07_第2至6件_Def四型与Schema定义件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 2-6 件 (Schema, Desc, State, Algo, Ctx)  
> **目标**：彻底分离数据的生命周期，统一使用四型（Desc/State/Algo/Ctx）定义数据承载体，禁用面向对象嵌套。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **数据与逻辑分离 (Data/Logic Segregation)**：将数据结构定义统一收拢在 `_Def.f90` 中，主计算文件不再混杂任何 `TYPE` 定义。
2. **生命周期分离**：通过分离只读配置 (`Desc`) 和动态演化变量 (`State`)，杜绝多线程下意外覆盖常量的并发 BUG。

### 1.2 架构红线 (Red Lines)
- **禁止过程绑定 (No Type-Bound Procedures)**：由于 Fortran 的 OOP 会引发虚函数表开销并阻碍 GPU 卸载，四型中**绝对禁止**使用 `CONTAINS` 绑定 `PROCEDURE`。
- **禁止在 Def 中写逻辑**：`_Def.f90` 内部只能包含常量（`PARAMETER`）、枚举值定义、以及 `TYPE` 结构体声明。不允许写具体的计算逻辑。
- **优先连续内存**：尽可能避免在 `TYPE` 内部使用 `POINTER`。若需要支持 AI 互操作，必须使用 `BIND(C)`。

---

## 2. 核心架构机制与四型定义

- **Desc (Description)**：拓扑、弹性模量等。一旦在 `Init` 时期 `Populate` 完毕，永远视为 `INTENT(IN)`。
- **State (State)**：应力、应变、损伤因子等。随迭代更新，要求支持**双缓冲回滚**。通常为 `INTENT(INOUT)`。
- **Algo (Algorithm)**：最大迭代步数、求解器选择器（Enum）、容差。作为路由判据。
- **Ctx (Context)**：局部雅可比、缓存巨型数组。生命周期为单步/单次迭代，避免在计算时反复 `ALLOCATE`。

---

## 3. 伪代码模板与合同定义

```fortran
!=============================================================================
! MODULE: PH_Elem_Def
! 描述: 单元域的基础数据结构与四型定义
!=============================================================================
MODULE PH_Elem_Def
    USE ISO_C_BINDING
    IMPLICIT NONE
    PRIVATE

    ! 导出全部 TYPE 与枚举
    PUBLIC :: PH_Elem_Desc, PH_Elem_State, PH_Elem_Algo, PH_Elem_Ctx
    PUBLIC :: ELEM_TYPE_C3D8, ELEM_TYPE_CPE4

    ! 常量枚举定义
    INTEGER, PARAMETER :: ELEM_TYPE_C3D8 = 101
    INTEGER, PARAMETER :: ELEM_TYPE_CPE4 = 102

    ! 1. Desc: 只读拓扑与属性 (建议 BIND(C) 或扁平数组)
    TYPE :: PH_Elem_Desc
        INTEGER :: elem_id
        INTEGER :: elem_type
        REAL*8, ALLOCATABLE :: nodal_coords(:,:)
        REAL*8, ALLOCATABLE :: section_props(:)
    END TYPE PH_Elem_Desc

    ! 2. State: 动态物理状态 (强烈建议 BIND(C) 以便 AI 读写)
    TYPE, BIND(C) :: PH_Elem_State
        REAL(C_DOUBLE) :: stress(6)
        REAL(C_DOUBLE) :: strain(6)
        REAL(C_DOUBLE) :: plastic_eq
        LOGICAL(C_BOOL) :: is_active
    END TYPE PH_Elem_State

    ! 3. Algo: 算法控制开关
    TYPE :: PH_Elem_Algo
        LOGICAL :: use_reduced_integration
        INTEGER :: hourglass_control_type
        REAL*8  :: stability_tolerance
    END TYPE PH_Elem_Algo

    ! 4. Ctx: 运行时临时缓存池 (避免热路径 ALLOCATE)
    TYPE :: PH_Elem_Ctx
        REAL*8, ALLOCATABLE :: local_stiffness(:,:)
        REAL*8, ALLOCATABLE :: local_residual(:)
        REAL*8 :: b_matrix(6, 24) ! 临时形函数导数矩阵
    END TYPE PH_Elem_Ctx

END MODULE PH_Elem_Def
```

---

## 4. 合同检验点 (Checklist)
1. 检查 `_Def.f90` 内是否有可执行程序 (`SUBROUTINE` 的内部逻辑实现)？（如有，必须剥离出 Def）。
2. 检查 `Desc` 是否在计算子程序中被标记为了 `INTENT(INOUT)`？（严重红线违规）。
3. 检查 `TYPE` 内是否大量嵌套了其他复杂的 `TYPE POINTER`？（应向扁平化方向整改）。