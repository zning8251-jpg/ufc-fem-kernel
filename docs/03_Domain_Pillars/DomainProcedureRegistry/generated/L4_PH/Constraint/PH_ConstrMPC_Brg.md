# `PH_ConstrMPC_Brg.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrMPC_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ConstrMPC_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrMPC_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrMPC`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrMPC_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_MPC_Apply_Desc` (lines 49–52)

```fortran
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Desc
    TYPE(MPC_Constraint), ALLOCATABLE :: constraints(:)  ! MPC constraint definitions
    INTEGER(i4) :: num_constraints = 0_i4  ! Number of constraints
  END TYPE PH_Constr_MPC_Apply_Desc
```

### `PH_Constr_MPC_Apply_Algo` (lines 56–60)

```fortran
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Algo
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY
    REAL(wp) :: penalty_factor = 1.0e12_wp  ! Penalty parameter ??
    REAL(wp) :: tolerance = 1.0e-8_wp  ! Constraint violation tolerance
  END TYPE PH_Constr_MPC_Apply_Algo
```

### `PH_Constr_MPC_Apply_Ctx` (lines 63–67)

```fortran
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Ctx
    REAL(wp), ALLOCATABLE :: stiffness_matrix(:,:)  ! Stiffness matrix K  ??^(n??n)
    REAL(wp), ALLOCATABLE :: force_vector(:)  ! Force vector F  ??^n
    INTEGER(i4) :: n_dofs = 0_i4  ! Number of DOFs
  END TYPE PH_Constr_MPC_Apply_Ctx
```

### `PH_Constr_MPC_Apply_State` (lines 70–74)

```fortran
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_State
    REAL(wp), ALLOCATABLE :: stiffness_modified(:,:)  ! Modified stiffness K_mod
    REAL(wp), ALLOCATABLE :: force_modified(:)  ! Modified force F_mod
    TYPE(MPC_State) :: violation_state  ! Constraint violation state
  END TYPE PH_Constr_MPC_Apply_State
```

### `PH_Constr_MPC_Apply_Arg` (lines 79–85)

```fortran
  TYPE, PUBLIC :: PH_Constr_MPC_Apply_Arg
    TYPE(PH_Constr_MPC_Apply_Desc) :: desc                   ! [IN]
    TYPE(PH_Constr_MPC_Apply_Algo) :: algo                   ! [IN]
    TYPE(PH_Constr_MPC_Apply_Ctx) :: ctx                   ! [IN]
    TYPE(PH_Constr_MPC_Apply_State) :: state                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_MPC_Apply_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_MPC_Apply` | 117 | `SUBROUTINE PH_Constr_MPC_Apply(arg)` |
| SUBROUTINE | `PH_Constr_MPC_Init` | 178 | `SUBROUTINE PH_Constr_MPC_Init(params, state, mpc, n_terms, ndof_per_node)` |
| SUBROUTINE | `PH_Constr_MPC_AddTerm` | 217 | `SUBROUTINE PH_Constr_MPC_AddTerm(constraint, node_id, dof_type, coef)` |
| SUBROUTINE | `PH_Constr_MPC_AssembleMatrix` | 256 | `SUBROUTINE PH_Constr_MPC_AssembleMatrix(constraints, num_constraints, &` |
| SUBROUTINE | `PH_Constr_MPC_ApplyConstraint` | 278 | `SUBROUTINE PH_Constr_MPC_ApplyConstraint(params, constraints, num_constraints, &` |
| SUBROUTINE | `PH_Constr_MPC_CheckViolation` | 326 | `SUBROUTINE PH_Constr_MPC_CheckViolation(params, constraints, num_constraints, &` |
| SUBROUTINE | `PH_Constr_MPC_AssemblePenalty` | 384 | `SUBROUTINE PH_Constr_MPC_AssemblePenalty(mpc, n_dof_total, kappa, K, R)` |
| SUBROUTINE | `PH_Constr_MPC_AssembleLagrangeBlock` | 404 | `SUBROUTINE PH_Constr_MPC_AssembleLagrangeBlock(mpc, n_dof_total, C_row)` |
| SUBROUTINE | `PH_Constr_MPC_Finalize` | 416 | `SUBROUTINE PH_Constr_MPC_Finalize(mpc)` |
| SUBROUTINE | `PH_Constr_MPC_Opt` | 434 | `SUBROUTINE PH_Constr_MPC_Opt(mpc, optimization_level, status)` |
| SUBROUTINE | `PH_Constr_MPC_CheckConsistency` | 450 | `SUBROUTINE PH_Constr_MPC_CheckConsistency(mpc, is_consistent, status)` |
| SUBROUTINE | `PH_Constr_MPC_ComputeViolation` | 467 | `SUBROUTINE PH_Constr_MPC_ComputeViolation(mpc, u_nodal, violation, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
