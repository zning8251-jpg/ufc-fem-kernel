---
name: ufc-solver-router
description: "UFC 求解器类型路由技能。基于 RT_SolverType 枚举（§6）执行求解器路由决策：STD（隐式/UMAT）、EXP（显式/VUMAT）、CFD、EMF、THM、PMF、DIF、CPL；包含禁止组合矩阵、PROC_* 正交性说明、UMAT/VUMAT 路由示例。触发：求解器路由、RT_SolverType、solver-router、UMAT/VUMAT 选择。"
---

# UFC Solver Router 可执行技能

## 何时使用

| 场景 | 触发条件 |
|------|----------|
| 新建分析步 | 用户说「这是什么分析类型」「该用哪个求解器」 |
| UMAT/VUMAT 选择 | 用户说「UMAT 还是 VUMAT」「implicit 还是 explicit」 |
| 多场耦合设计 | 用户说「热力耦合用哪个引擎」「CPL 耦合机制」 |
| 域路由决策 | 用户说「Contact 域用 STD 还是 EXP」 |

---

## 第一步：RT_SolverType 枚举体系

### 枚举定义（来源：UFC_命名规范_v3.0.md 第六节「场景 4/5 — 变量、常量、接口」）

```fortran
! 求解器类型枚举
INTEGER(i4), PARAMETER :: RT_SOLVER_UNKNOWN    = 0_i4  ! 未初始化
INTEGER(i4), PARAMETER :: RT_SOLVER_IMPLICIT  = 1_i4  ! Abaqus/Standard (UMAT/UEL)
INTEGER(i4), PARAMETER :: RT_SOLVER_EXPLICIT  = 2_i4  ! Abaqus/Explicit (VUMAT/VUEL)
INTEGER(i4), PARAMETER :: RT_SOLVER_CFD       = 3_i4  ! Abaqus/CFD
INTEGER(i4), PARAMETER :: RT_SOLVER_EMF       = 4_i4  ! 电磁场 (stub)
INTEGER(i4), PARAMETER :: RT_SOLVER_THM       = 5_i4  ! 纯热传导 (stub)
INTEGER(i4), PARAMETER :: RT_SOLVER_PMF       = 6_i4  ! 渗流 (stub)
INTEGER(i4), PARAMETER :: RT_SOLVER_DIF       = 7_i4  ! 扩散 (stub)
INTEGER(i4), PARAMETER :: RT_SOLVER_CPL       = 8_i4  ! 多场耦合 (RT_MF_Coordinator)
```

### 枚举值速查

| 枚举值 | 求解引擎 | 用户子程序 | 典型场景 |
|--------|----------|-----------|----------|
| `RT_SOLVER_IMPLICIT` (1) | Abaqus/Standard | **UMAT** / UEL | 静态、模态、屈曲、隐式动力学 |
| `RT_SOLVER_EXPLICIT` (2) | Abaqus/Explicit | **VUMAT** / VUEL | 高速碰撞、冲击、显式动力学 |
| `RT_SOLVER_CFD` (3) | Abaqus/CFD | CFD 用户子程序 | 流体动力学 |
| `RT_SOLVER_EMF` (4) | EMF stub | — | 电磁场（待实现） |
| `RT_SOLVER_THM` (5) | THM stub | — | 热传导（待实现） |
| `RT_SOLVER_PMF` (6) | PMF stub | — | 孔隙渗流（待实现） |
| `RT_SOLVER_DIF` (7) | DIF stub | — | 物质扩散（待实现） |
| `RT_SOLVER_CPL` (8) | 多场协调器 | RT_MF_Coordinator | 热-结构、电-热、流-固耦合 |

---

## 第二步：PROC_* 与 RT_SolverType 正交性

**核心原则**：`PROC_*` 和 `RT_SolverType` 描述不同维度，**必须正交**：

| 维度 | 说明 |
|------|------|
| **PROC_*** | 「做什么分析」— 分析步类型（Static, Dynamic, Frequency, HeatTransfer...） |
| **RT_SolverType** | 「用什么引擎」— 数值求解器（STD/EXP/CFD...） |

### 正交组合示例

```
PROC_STATIC + RT_SOLVER_IMPLICIT → 隐式静态分析（UMAT）
PROC_STATIC + RT_SOLVER_EXPLICIT → 显式静态分析（VUMAT，罕见）

PROC_DYNAMIC + RT_SOLVER_IMPLICIT → 隐式动力学（UMAT）
PROC_DYNAMIC + RT_SOLVER_EXPLICIT → 显式动力学（VUMAT）

PROC_HEAT_TRANSFER + RT_SOLVER_THM → 纯热传导
PROC_COUPLED_TEMP_DISP + RT_SOLVER_CPL → 热-结构耦合
```

---

## 第三步：禁止组合矩阵

| 用户子程序 | STD (IMPLICIT) | EXP (EXPLICIT) | 说明 |
|-----------|-----------------|-----------------|------|
| **UMAT** | ✅ 允许 | ❌ 禁止 | Abaqus/Standard 专用 |
| **VUMAT** | ❌ 禁止 | ✅ 允许 | Abaqus/Explicit 专用 |
| **UEL** | ✅ 允许 | ❌ 禁止 | Abaqus/Standard 专用 |
| **VUEL** | ❌ 禁止 | ✅ 允许 | Abaqus/Explicit 专用 |

> **硬约束**：UMAT 仅限隐式，VUMAT 仅限显式。违反此约束将导致 **Abaqus 运行时错误**。

---

## 第四步：路由决策流程

```
                    开始
                      │
                      ▼
            ┌─────────────────┐
            │ 分析类型是什么？ │
            └────────┬────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌────────┐  ┌─────────┐  ┌────────┐
   │ 静态   │  │ 动力学  │  │ 热分析 │
   └────┬───┘  └────┬────┘  └────┬───┘
        │            │            │
        ▼            ▼            ▼
   需要隐式？    高速冲击？    纯热传导？
   ┌────┴────┐  ┌───┴────┐  ┌───┴────┐
   │   是    │  │   是   │  │   是   │
   ▼         ▼  ▼        ▼  ▼        ▼
┌─────────┐ ┌────────┐ ┌────────┐
│STD+UMAT │ │EXP+VUMAT│ │THM stub│
│(隐式静态)│ │(显式冲击)│ │(热传导)│
└─────────┘ └────────┘ └────────┘
```

---

## 第五步：代码示例

### 5.1 求解器类型路由

```fortran
SUBROUTINE Select_SolverType(analysis_type, solver_type, ierr)
  INTEGER(i4), INTENT(IN)  :: analysis_type  ! PROC_* 类型
  INTEGER(i4), INTENT(OUT) :: solver_type    ! RT_SolverType
  INTEGER(i4), INTENT(OUT) :: ierr

  SELECT CASE (analysis_type)
  CASE (PROC_STATIC, PROC_MODAL, PROC_BUCKLE)
    solver_type = RT_SOLVER_IMPLICIT  ! Abaqus/Standard + UMAT
    ierr = 0

  CASE (PROC_DYNAMIC_EXPLICIT)
    solver_type = RT_SOLVER_EXPLICIT   ! Abaqus/Explicit + VUMAT
    ierr = 0

  CASE (PROC_HEAT_TRANSFER)
    solver_type = RT_SOLVER_THM        ! 纯热传导
    ierr = 0

  CASE (PROC_COUPLED_TEMP_DISP)
    solver_type = RT_SOLVER_CPL        ! 多场耦合
    ierr = 0

  CASE DEFAULT
    ierr = -1
    solver_type = RT_SOLVER_UNKNOWN
  END SELECT
END SUBROUTINE
```

### 5.2 UMAT/VUMAT 路由守卫

```fortran
SUBROUTINE Validate_User_Material(solver_type, umat_name, ierr)
  INTEGER(i4), INTENT(IN)  :: solver_type
  CHARACTER(*), INTENT(IN) :: umat_name
  INTEGER(i4), INTENT(OUT) :: ierr

  SELECT CASE (solver_type)
  CASE (RT_SOLVER_IMPLICIT)
    IF (.NOT. Is_UMAT(umat_name)) THEN
      ierr = -1  ! 错误：隐式分析必须用 UMAT
      RETURN
    END IF

  CASE (RT_SOLVER_EXPLICIT)
    IF (.NOT. Is_VUMAT(umat_name)) THEN
      ierr = -1  ! 错误：显式分析必须用 VUMAT
      RETURN
    END IF

  CASE DEFAULT
    ierr = -2  ! 未知的求解器类型
  END SELECT

  ierr = 0
END SUBROUTINE
```

### 5.3 多场耦合协调器

```fortran
! RT_MF_Coordinator — CPL 耦合引擎
MODULE RT_MF_Coordinator
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  USE RT_MF_Types,  ONLY: RT_MF_Desc, RT_MF_State, &
                           RT_MF_Algo, RT_MF_Ctx

  TYPE(RT_MF_Ctx), POINTER :: mf_ctx  ! 多场上下文

  CONTAINS

  SUBROUTINE RT_MF_Coordinator_Step(mf_desc, mf_state, mf_algo, mf_ctx, args)
    TYPE(RT_MF_Desc),    INTENT(IN)    :: mf_desc
    TYPE(RT_MF_State),   INTENT(INOUT) :: mf_state
    TYPE(RT_MF_Algo),    INTENT(IN)    :: mf_algo
    TYPE(RT_MF_Ctx),     INTENT(INOUT) :: mf_ctx
    TYPE(RT_MF_Step_Arg),INTENT(INOUT) :: args

    ! 协调 STR(UMAT) ↔ THM 热交换
    CALL Str2Thm_Exchange(mf_ctx)
    CALL Thm2Str_Exchange(mf_ctx)

    ! 迭代收敛
    DO WHILE (.NOT. Converged(mf_state))
      CALL Solve_Structural(mf_ctx)
      CALL Solve_Thermal(mf_ctx)
      CALL Exchange_Data(mf_ctx)
    END DO
  END SUBROUTINE
END MODULE
```

---

## 第六步：域级路由规则

| 域 | STD (IMPLICIT) | EXP (EXPLICIT) | CPL | 说明 |
|----|----------------|----------------|-----|------|
| **Material** | ✅ UMAT | ✅ VUMAT | — | 材料本构 |
| **Element** | ✅ UEL | ✅ VUEL | — | 用户单元 |
| **Contact** | ✅ Standard contact | ✅ Explicit contact | — | 接触算法 |
| **LoadBC** | ✅ | ✅ | ✅ | 载荷/边界条件 |
| **Output** | ✅ | ✅ | ✅ | 输出场变量 |
| **Coupling** | — | — | ✅ | 多场耦合协调 |

---

## 第七步：故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 「UMAT 在显式分析中不可用」 | UMAT 用于 STD，误用于 EXP | 改用 VUMAT 或切换为隐式分析 |
| 「VUMAT 在隐式分析中不可用」 | VUMAT 用于 EXP，误用于 STD | 改用 UMAT 或切换为显式分析 |
| 「多场耦合不收敛」 | CPL 协调器配置错误 | 检查 RT_MF_Coordinator 迭代设置 |
| 「求解器类型未知」 | analysis_type 未映射到 RT_SolverType | 在 Select_SolverType 中添加 CASE 分支 |

---

**技能版本**: v1.0 | **日期**: 2026-04-04
**规范锚点**: [`UFC_命名规范_v3.0.md`](../../../05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md) 第六节
