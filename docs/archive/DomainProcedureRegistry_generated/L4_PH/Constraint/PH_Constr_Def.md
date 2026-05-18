# `PH_Constr_Def.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Constr_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constraint_Desc` (lines 76–84)

```fortran
    TYPE, PUBLIC :: PH_Constraint_Desc
        INTEGER(i4) :: n_terms   = 0        !< Number of constraint terms
        INTEGER(i4) :: dep_idx   = 0        !< Dependent DOF index
        REAL(wp)    :: rhs       = ZERO     !< Constraint RHS value
        INTEGER(i4) :: dof_ids(64) = 0      !< DOF indices involved
        REAL(wp)    :: coeffs(64)  = ZERO   !< Constraint coefficients
        INTEGER(i4) :: constraint_type = 0  !< 1=MPC, 2=Tie, 3=RBE, 4=Periodic
        INTEGER(i4) :: enforcement     = 0  !< PH_CONSTR_PENALTY / LAGRANGE / ELIMINATION
    END TYPE PH_Constraint_Desc
```

### `PH_Constraint_Algo` (lines 90–95)

```fortran
    TYPE, PUBLIC :: PH_Constraint_Algo
        INTEGER(i4) :: method = PH_CONSTR_PENALTY  !< Enforcement method (PH_CONS_*)
        REAL(wp)    :: alpha  = 1.0e6_wp         !< Penalty parameter
        REAL(wp)    :: tol    = 1.0e-8_wp        !< Constraint violation tolerance
        INTEGER(i4) :: max_iter = 10             !< Max Uzawa iterations (aug. Lagrange)
    END TYPE PH_Constraint_Algo
```

### `PH_Constr_Ctx` (lines 102–135)

```fortran
    TYPE, PUBLIC :: PH_Constr_Ctx
        ! Constraint identification
        INTEGER(i4) :: constraint_id = 0
        INTEGER(i4) :: constraint_type = 0  ! 1=MPC, 2=Tie, 3=RBE, 4=Periodic
        
        ! Constraint parameters
        INTEGER(i4) :: n_dofs = 0
        INTEGER(i4), ALLOCATABLE :: dof_map(:)      ! DOF mapping
        REAL(wp), ALLOCATABLE :: constraint_matrix(:,:)  ! Constraint matrix A
        REAL(wp), ALLOCATABLE :: constraint_rhs(:)  ! Constraint RHS b
        
        ! Constraint state
        REAL(wp), ALLOCATABLE :: u_nodal(:)         ! Nodal displacements
        REAL(wp), ALLOCATABLE :: lambda(:)          ! Lagrange multipliers
        REAL(wp) :: violation_norm = ZERO
        REAL(wp) :: max_violation = ZERO
        
        ! Enforcement method
        INTEGER(i4) :: enforcement_method = PH_CONSTR_LAGRANGE  ! PH_CONS_* (PH_ConstraintDomain_Algo)
        REAL(wp) :: penalty_parameter = 1.0e6_wp
        
        ! Constraint forces
        REAL(wp), ALLOCATABLE :: constraint_forces(:)
        
        ! Convergence
        REAL(wp) :: tolerance = 1.0e-6_wp
        INTEGER(i4) :: iteration_count = 0
        LOGICAL :: converged = .FALSE.
        
        ! Flags
        LOGICAL :: is_initialized = .FALSE.
        LOGICAL :: is_active = .TRUE.
        
    END TYPE PH_Constr_Ctx
```

### `PH_Constr_Ctx_Init_Arg` (lines 144–152)

```fortran
  TYPE, PUBLIC :: PH_Constr_Ctx_Init_Arg
    INTEGER(i4) :: constraint_id                   ! [IN]
    INTEGER(i4) :: constraint_type                   ! [IN]
    INTEGER(i4) :: n_dofs                   ! [IN]
    INTEGER(i4) :: enforcement_method  ! PH_CONS_* (PH_ConstraintDomain_Algo)                   ! [IN]
    REAL(wp) :: penalty_parameter                   ! [IN]
    TYPE(PH_Constr_Ctx) :: ctx                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Init_Arg
```

### `PH_Constr_Ctx_Clear_Arg` (lines 158–161)

```fortran
  TYPE, PUBLIC :: PH_Constr_Ctx_Clear_Arg
    TYPE(PH_Constr_Ctx) :: ctx                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Clear_Arg
```

### `PH_Constr_Ctx_Copy_Arg` (lines 167–171)

```fortran
  TYPE, PUBLIC :: PH_Constr_Ctx_Copy_Arg
    TYPE(PH_Constr_Ctx) :: ctx_src                   ! [IN]
    TYPE(PH_Constr_Ctx) :: ctx_dst                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Copy_Arg
```

### `PH_Constr_Ctx_Valid_Arg` (lines 177–181)

```fortran
  TYPE, PUBLIC :: PH_Constr_Ctx_Valid_Arg
    TYPE(PH_Constr_Ctx) :: ctx                   ! [IN]
    LOGICAL :: is_valid                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Ctx_Valid_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_Ctx_Init` | 191 | `SUBROUTINE PH_Constr_Ctx_Init(ctx, constraint_id, constraint_type, &` |
| SUBROUTINE | `PH_Constr_Ctx_Init_Structured` | 244 | `SUBROUTINE PH_Constr_Ctx_Init_Structured(arg)` |
| SUBROUTINE | `PH_Constr_Ctx_Clear` | 260 | `SUBROUTINE PH_Constr_Ctx_Clear(ctx, status)` |
| SUBROUTINE | `PH_Constr_Ctx_Clear_Structured` | 289 | `SUBROUTINE PH_Constr_Ctx_Clear_Structured(arg)` |
| SUBROUTINE | `PH_Constr_Ctx_Copy` | 304 | `SUBROUTINE PH_Constr_Ctx_Copy(ctx_src, ctx_dst, status)` |
| SUBROUTINE | `PH_Constr_Ctx_Copy_Structured` | 369 | `SUBROUTINE PH_Constr_Ctx_Copy_Structured(arg)` |
| SUBROUTINE | `PH_Constr_Ctx_Valid` | 383 | `SUBROUTINE PH_Constr_Ctx_Valid(ctx, is_valid, status)` |
| SUBROUTINE | `PH_Constr_Ctx_Valid_Structured` | 426 | `SUBROUTINE PH_Constr_Ctx_Valid_Structured(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
