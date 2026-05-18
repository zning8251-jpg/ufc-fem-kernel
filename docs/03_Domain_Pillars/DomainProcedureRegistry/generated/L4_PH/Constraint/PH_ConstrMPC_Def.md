# `PH_ConstrMPC_Def.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrMPC_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ConstrMPC_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrMPC_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrMPC`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrMPC_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MPC_Term` (lines 41–45)

```fortran
  TYPE :: MPC_Term
    INTEGER(i4) :: node_id = 0_i4       ! Node ID
    INTEGER(i4) :: dof_type = 0_i4      ! DOF type (1=u1, 2=u2, 3=u3, 4=ur1, 5=ur2, 6=ur3)
    REAL(wp) :: coef = ZERO             ! Coefficient a_i
  END TYPE MPC_Term
```

### `MPC_Constraint` (lines 50–57)

```fortran
  TYPE :: MPC_Constraint
    CHARACTER(LEN=64) :: constraint_name = ""
    INTEGER(i4) :: num_terms = 0_i4                     ! Number of terms
    TYPE(MPC_Term), ALLOCATABLE :: terms(:)             ! Constraint terms
    REAL(wp) :: rhs_value = ZERO                        ! Right-hand side c
    INTEGER(i4) :: master_dof_id = 0_i4                 ! Master DOF ID for elimination method
    LOGICAL :: is_active = .TRUE.                       ! Whether constraint is active
  END TYPE MPC_Constraint
```

### `MPC_Params` (lines 62–67)

```fortran
  TYPE :: MPC_Params
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY  ! PH_CONS_* (PH_ConstraintDomain_Algo)
    REAL(wp) :: penalty_factor = 1.0e12_wp              ! Penalty parameter kappa
    REAL(wp) :: tolerance = 1.0e-8_wp                   ! Constraint violation tolerance
    LOGICAL :: auto_detect_master = .FALSE.             ! Auto-detect master DOF
  END TYPE MPC_Params
```

### `MPC_State` (lines 72–79)

```fortran
  TYPE :: MPC_State
    INTEGER(i4) :: num_constraints = 0_i4               ! Total number of constraints
    REAL(wp) :: max_violation = ZERO                    ! Maximum constraint violation
    REAL(wp) :: avg_violation = ZERO                    ! Average constraint violation
    INTEGER(i4) :: num_violations = 0_i4                ! Number of violated constraints
    LOGICAL :: is_satisfied = .TRUE.                    ! Whether all constraints satisfied
    REAL(wp), ALLOCATABLE :: lagrange_multipliers(:)    ! Lagrange multipliers (Lagrange method)
  END TYPE MPC_State
```

### `PH_Constr_MPC_Def` (lines 84–91)

```fortran
  TYPE :: PH_Constr_MPC_Def
    INTEGER(i4) :: n_terms = 0_i4
    INTEGER(i4) :: ndof_per_node = 3_i4
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: dof_ids(:)
    REAL(wp), ALLOCATABLE :: coefficients(:)
    REAL(wp) :: rhs = ZERO
  END TYPE PH_Constr_MPC_Def
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
