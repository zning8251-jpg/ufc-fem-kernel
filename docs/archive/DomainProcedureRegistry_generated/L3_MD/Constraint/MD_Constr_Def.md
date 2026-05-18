# `MD_Constr_Def.f90`

- **Source**: `L3_MD/Constraint/MD_Constr_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Constr_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Constr_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Constr`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Constraint/MD_Constr_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `TieConstraintDef` (lines 118–133)

```fortran
  TYPE, PUBLIC :: TieConstraintDef
    INTEGER(i4)       :: tie_id           = 0_i4
    CHARACTER(LEN=64) :: name             = ""
    CHARACTER(LEN=64) :: slave_surface    = ""
    CHARACTER(LEN=64) :: master_surface   = ""
    INTEGER(i4)       :: slave_surface_id  = 0_i4
    INTEGER(i4)       :: master_surface_id = 0_i4
    REAL(wp)          :: position_tolerance = 0.0_wp
    LOGICAL           :: adjust           = .TRUE.
    LOGICAL           :: is_active        = .TRUE.
    INTEGER(i4)       :: n_pairs          = 0_i4
    INTEGER(i4), ALLOCATABLE :: slave_nodes(:)
    INTEGER(i4), ALLOCATABLE :: master_nodes(:)
  CONTAINS
    PROCEDURE :: Valid => TieConstraintDef_Valid_TBP
  END TYPE TieConstraintDef
```

### `MPCConstraintDef` (lines 138–150)

```fortran
  TYPE, PUBLIC :: MPCConstraintDef
    INTEGER(i4)       :: mpc_id       = 0_i4
    CHARACTER(LEN=64) :: name         = ""
    INTEGER(i4)       :: mpc_type     = MPC_TYPE_GENERAL
    INTEGER(i4)       :: n_terms      = 0_i4
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: dof_ids(:)
    REAL(wp),    ALLOCATABLE :: coefficients(:)
    REAL(wp)          :: equation_rhs = 0.0_wp
    LOGICAL           :: is_active    = .TRUE.
  CONTAINS
    PROCEDURE :: Valid => MPCConstraintDef_Valid_TBP
  END TYPE MPCConstraintDef
```

### `CplConstraintDef` (lines 155–169)

```fortran
  TYPE, PUBLIC :: CplConstraintDef
    INTEGER(i4)       :: coupling_id    = 0_i4
    CHARACTER(LEN=64) :: name           = ""
    INTEGER(i4)       :: coupling_type  = COUPLING_TYPE_KINEMATIC
    INTEGER(i4)       :: ref_node       = 0_i4
    CHARACTER(LEN=64) :: surface_name   = ""
    LOGICAL           :: constrain_dof(6) = (/ .TRUE., .TRUE., .TRUE., &
                                               .FALSE., .FALSE., .FALSE. /)
    INTEGER(i4)       :: n_coupled      = 0_i4
    INTEGER(i4), ALLOCATABLE :: coupled_nodes(:)
    REAL(wp),    ALLOCATABLE :: weights(:)
    LOGICAL           :: is_active      = .TRUE.
  CONTAINS
    PROCEDURE :: Valid => CplConstraintDef_Valid_TBP
  END TYPE CplConstraintDef
```

### `RigidBodyDef` (lines 174–187)

```fortran
  TYPE, PUBLIC :: RigidBodyDef
    INTEGER(i4)       :: rigid_id      = 0_i4
    CHARACTER(LEN=64) :: name          = ""
    INTEGER(i4)       :: rbe_kind      = RBE_TYPE_RBE2
    INTEGER(i4)       :: ref_node      = 0_i4
    CHARACTER(LEN=64) :: element_set   = ""
    LOGICAL           :: tie_nset      = .FALSE.
    LOGICAL           :: is_active     = .TRUE.
    INTEGER(i4)       :: n_tied        = 0_i4
    INTEGER(i4), ALLOCATABLE :: tied_nodes(:)
    REAL(wp),    ALLOCATABLE :: tied_weights(:)
  CONTAINS
    PROCEDURE :: Valid => RigidBodyDef_Valid_TBP
  END TYPE RigidBodyDef
```

### `EmbeddedRegionDef` (lines 195–212)

```fortran
  TYPE, PUBLIC :: EmbeddedRegionDef
    INTEGER(i4)       :: embed_id       = 0_i4
    CHARACTER(LEN=64) :: name           = ""
    CHARACTER(LEN=64) :: host_surface   = ""       ! Host surface or element set
    CHARACTER(LEN=64) :: embedded_set   = ""       ! Embedded element set name
    CHARACTER(LEN=64) :: host_set       = ""       ! Host element set name
    INTEGER(i4)       :: host_surface_id = 0_i4
    LOGICAL           :: use_rounding   = .TRUE.   ! Round embedded nodes onto host boundary
    LOGICAL           :: is_active      = .TRUE.
    INTEGER(i4)       :: n_embedded_elem = 0_i4
    INTEGER(i4)       :: n_embedded_node = 0_i4
    INTEGER(i4), ALLOCATABLE :: embedded_elem_ids(:)
    INTEGER(i4), ALLOCATABLE :: embedded_node_ids(:)
    INTEGER(i4), ALLOCATABLE :: host_elem_ids(:)
    REAL(wp),    ALLOCATABLE :: host_coeffs(:,:)  ! Interpolation coeffs per embedded node
  CONTAINS
    PROCEDURE :: Valid => EmbeddedRegionDef_Valid_TBP
  END TYPE EmbeddedRegionDef
```

### `MD_ConstraintUnion` (lines 217–230)

```fortran
  TYPE, PUBLIC :: MD_ConstraintUnion
    TYPE(TieConstraintDef),  ALLOCATABLE :: tie(:)
    TYPE(MPCConstraintDef),  ALLOCATABLE :: mpc(:)
    TYPE(CplConstraintDef),  ALLOCATABLE :: cpl(:)
    TYPE(RigidBodyDef),      ALLOCATABLE :: rigid(:)
    TYPE(EmbeddedRegionDef), ALLOCATABLE :: embedded(:)
    INTEGER(i4) :: n_tie      = 0_i4
    INTEGER(i4) :: n_mpc      = 0_i4
    INTEGER(i4) :: n_cpl      = 0_i4
    INTEGER(i4) :: n_rigid    = 0_i4
    INTEGER(i4) :: n_embedded = 0_i4
    INTEGER(i4) :: n_total    = 0_i4
    LOGICAL     :: validated  = .FALSE.
  END TYPE MD_ConstraintUnion
```

### `MD_Constraint_State` (lines 235–239)

```fortran
  TYPE, PUBLIC :: MD_Constraint_State
    LOGICAL     :: assembled    = .FALSE.
    INTEGER(i4) :: n_active     = 0_i4
    INTEGER(i4) :: n_suppressed = 0_i4
  END TYPE MD_Constraint_State
```

### `MD_Constraint_Algo` (lines 246–251)

```fortran
  TYPE, PUBLIC :: MD_Constraint_Algo
    INTEGER(i4) :: default_enforcement = 1_i4    !! 1=Transform, 2=Lagrange, 3=Penalty
    REAL(wp)    :: default_penalty     = 1.0E+10_wp
    REAL(wp)    :: default_tolerance   = 1.0E-8_wp
    LOGICAL     :: use_elimination     = .FALSE.  !! Prefer elimination over penalty
  END TYPE MD_Constraint_Algo
```

### `MD_Constraint_Ctx` (lines 257–262)

```fortran
  TYPE, PUBLIC :: MD_Constraint_Ctx
    INTEGER(i4) :: current_constraint_id = 0_i4
    INTEGER(i4) :: operation_type        = 0_i4  ! 1=Add, 2=Modify, 3=Delete
    LOGICAL     :: validation_pending    = .FALSE.
    CHARACTER(LEN=64) :: last_operation  = ""
  END TYPE MD_Constraint_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `TieConstraintDef_Init` | 294 | `SUBROUTINE TieConstraintDef_Init(def, name, slave_surf, master_surf, status)` |
| FUNCTION | `TieConstraintDef_Valid` | 315 | `FUNCTION TieConstraintDef_Valid(def) RESULT(ok)` |
| FUNCTION | `TieConstraintDef_Valid_TBP` | 322 | `FUNCTION TieConstraintDef_Valid_TBP(this) RESULT(ok)` |
| SUBROUTINE | `TieConstraintDef_Cleanup` | 328 | `SUBROUTINE TieConstraintDef_Cleanup(def, status)` |
| SUBROUTINE | `MPCConstraintDef_Init` | 342 | `SUBROUTINE MPCConstraintDef_Init(def, name, mpc_type, status)` |
| SUBROUTINE | `MPCConstraintDef_AddTerm` | 358 | `SUBROUTINE MPCConstraintDef_AddTerm(def, node_id, dof_id, coeff, status)` |
| FUNCTION | `MPCConstraintDef_Valid` | 398 | `FUNCTION MPCConstraintDef_Valid(def) RESULT(ok)` |
| FUNCTION | `MPCConstraintDef_Valid_TBP` | 406 | `FUNCTION MPCConstraintDef_Valid_TBP(this) RESULT(ok)` |
| SUBROUTINE | `MPCConstraintDef_Cleanup` | 412 | `SUBROUTINE MPCConstraintDef_Cleanup(def, status)` |
| SUBROUTINE | `CplConstraintDef_Init` | 427 | `SUBROUTINE CplConstraintDef_Init(def, name, ref_node, surf, status)` |
| SUBROUTINE | `CplConstraintDef_SetDOFs` | 446 | `SUBROUTINE CplConstraintDef_SetDOFs(def, dof_flags)` |
| FUNCTION | `CplConstraintDef_Valid` | 452 | `FUNCTION CplConstraintDef_Valid(def) RESULT(ok)` |
| FUNCTION | `CplConstraintDef_Valid_TBP` | 459 | `FUNCTION CplConstraintDef_Valid_TBP(this) RESULT(ok)` |
| SUBROUTINE | `CplConstraintDef_Cleanup` | 465 | `SUBROUTINE CplConstraintDef_Cleanup(def, status)` |
| SUBROUTINE | `RigidBodyDef_Init` | 480 | `SUBROUTINE RigidBodyDef_Init(def, name, ref_node, element_set, status, rbe_kind)` |
| FUNCTION | `RigidBodyDef_Valid` | 504 | `FUNCTION RigidBodyDef_Valid(def) RESULT(ok)` |
| FUNCTION | `RigidBodyDef_Valid_TBP` | 511 | `FUNCTION RigidBodyDef_Valid_TBP(this) RESULT(ok)` |
| SUBROUTINE | `EmbeddedRegionDef_Init` | 520 | `SUBROUTINE EmbeddedRegionDef_Init(def, name, host_set, embedded_set, status, use_rounding)` |
| FUNCTION | `EmbeddedRegionDef_Valid` | 546 | `FUNCTION EmbeddedRegionDef_Valid(def) RESULT(ok)` |
| FUNCTION | `EmbeddedRegionDef_Valid_TBP` | 554 | `FUNCTION EmbeddedRegionDef_Valid_TBP(this) RESULT(ok)` |
| SUBROUTINE | `EmbeddedRegionDef_Cleanup` | 560 | `SUBROUTINE EmbeddedRegionDef_Cleanup(def, status)` |
| SUBROUTINE | `RigidBodyDef_Cleanup` | 579 | `SUBROUTINE RigidBodyDef_Cleanup(def, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
