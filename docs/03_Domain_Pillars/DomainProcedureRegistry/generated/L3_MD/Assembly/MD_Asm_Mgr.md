# `MD_Asm_Mgr.f90`

- **Source**: `L3_MD/Assembly/MD_Asm_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Asm_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Asm_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Asm`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Assembly/MD_Asm_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Instance_Desc` (lines 40–49)

```fortran
  TYPE, PUBLIC :: MD_Instance_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: inst_id    = 0_i4
    INTEGER(i4)       :: part_ref   = 0_i4
    REAL(wp)          :: translation(3) = (/ 0.0_wp, 0.0_wp, 0.0_wp /)
    REAL(wp)          :: rotation(3,3)  = RESHAPE( &
      (/ 1.0_wp,0.0_wp,0.0_wp, 0.0_wp,1.0_wp,0.0_wp, 0.0_wp,0.0_wp,1.0_wp /), &
      (/ 3, 3 /) )
    LOGICAL           :: dependent  = .FALSE.
  END TYPE MD_Instance_Desc
```

### `MD_SetDef` (lines 57–63)

```fortran
  TYPE, PUBLIC :: MD_SetDef
    CHARACTER(LEN=64)          :: name    = ""
    INTEGER(i4)                :: set_id  = 0_i4
    INTEGER(i4), ALLOCATABLE   :: members(:)
    INTEGER(i4)                :: n_members = 0_i4
    LOGICAL                    :: is_internal = .FALSE.
  END TYPE MD_SetDef
```

### `MD_SurfaceDef` (lines 71–77)

```fortran
  TYPE, PUBLIC :: MD_SurfaceDef
    CHARACTER(LEN=64)          :: name      = ""
    INTEGER(i4)                :: surf_id   = 0_i4
    INTEGER(i4), ALLOCATABLE   :: elem_ids(:)
    INTEGER(i4), ALLOCATABLE   :: face_ids(:)
    INTEGER(i4)                :: n_faces   = 0_i4
  END TYPE MD_SurfaceDef
```

### `MD_Asm_GetSummary_Arg` (lines 88–91)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Asm_GetSummary_Arg
```

### `MD_Asm_GetInstance_Arg` (lines 98–100)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetInstance_Arg
    TYPE(MD_Instance_Desc) :: desc
  END TYPE MD_Asm_GetInstance_Arg
```

### `MD_Asm_GetNodeSet_Arg` (lines 106–108)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetNodeSet_Arg
    TYPE(MD_SetDef) :: def
  END TYPE MD_Asm_GetNodeSet_Arg
```

### `MD_Asm_GetElemSet_Arg` (lines 114–116)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetElemSet_Arg
    TYPE(MD_SetDef) :: def
  END TYPE MD_Asm_GetElemSet_Arg
```

### `MD_Asm_GetSurface_Arg` (lines 122–124)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetSurface_Arg
    TYPE(MD_SurfaceDef) :: def
  END TYPE MD_Asm_GetSurface_Arg
```

### `MD_Asm_GetSurfaceByName_Arg` (lines 126–129)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetSurfaceByName_Arg
    TYPE(MD_SurfaceDef) :: def
    LOGICAL :: found = .FALSE.
  END TYPE MD_Asm_GetSurfaceByName_Arg
```

### `MD_Asm_GetNodeSetByName_Arg` (lines 130–133)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetNodeSetByName_Arg
    TYPE(MD_SetDef) :: def
    LOGICAL :: found = .FALSE.
  END TYPE MD_Asm_GetNodeSetByName_Arg
```

### `MD_Asm_GetElemSetByName_Arg` (lines 134–137)

```fortran
  TYPE, PUBLIC :: MD_Asm_GetElemSetByName_Arg
    TYPE(MD_SetDef) :: def
    LOGICAL :: found = .FALSE.
  END TYPE MD_Asm_GetElemSetByName_Arg
```

### `MD_Asm_Algo` (lines 150–157)

```fortran
  TYPE, PUBLIC :: MD_Asm_Algo
    REAL(wp)    :: default_tie_tolerance = 0.01_wp
    LOGICAL     :: auto_adjust           = .TRUE.
    INTEGER(i4) :: max_constraint_iters  = 100_i4
    LOGICAL     :: small_sliding_default = .FALSE.
    REAL(wp)    :: mpc_penalty_factor    = 1.0E+8_wp
    LOGICAL     :: rigid_auto_ref      = .TRUE.
  END TYPE MD_Asm_Algo
```

### `MD_Asm_State` (lines 164–172)

```fortran
  TYPE, PUBLIC :: MD_Asm_State
    INTEGER(i4) :: active_constraints    = 0_i4
    INTEGER(i4) :: active_contact_pairs  = 0_i4
    INTEGER(i4) :: total_constraint_violations = 0_i4
    REAL(wp)    :: max_constraint_error  = 0.0_wp
    LOGICAL     :: tie_satisfied         = .TRUE.
    LOGICAL     :: mpc_satisfied         = .TRUE.
    INTEGER(i4) :: failed_constraints    = 0_i4
  END TYPE MD_Asm_State
```

### `MD_Asm_Ctx` (lines 179–188)

```fortran
  TYPE, PUBLIC :: MD_Asm_Ctx
    INTEGER(i4) :: current_inst_id = 0_i4
    LOGICAL     :: transform_cached = .FALSE.
    REAL(wp)    :: cached_translation(3) = (/ 0.0_wp, 0.0_wp, 0.0_wp /)
    REAL(wp)    :: cached_rotation(3,3)  = RESHAPE( &
      (/ 1.0_wp,0.0_wp,0.0_wp, 0.0_wp,1.0_wp,0.0_wp, 0.0_wp,0.0_wp,1.0_wp /), &
      (/ 3, 3 /) )
    INTEGER(i4) :: current_constraint_idx = 0_i4
    LOGICAL     :: constraint_cache_valid = .FALSE.
  END TYPE MD_Asm_Ctx
```

### `MD_ConstraintDef` (lines 195–203)

```fortran
  TYPE, PUBLIC :: MD_ConstraintDef
    CHARACTER(LEN=64) :: name            = ""
    INTEGER(i4)       :: constraint_id   = 0_i4
    INTEGER(i4)       :: constraint_type = CONSTRAINT_TIE
    CHARACTER(LEN=64) :: master_surface  = ""
    CHARACTER(LEN=64) :: slave_surface   = ""
    REAL(wp)          :: tolerance       = 0.0_wp
    LOGICAL           :: adjust          = .TRUE.
  END TYPE MD_ConstraintDef
```

### `MD_Assembly_Domain` (lines 211–260)

```fortran
  TYPE, PUBLIC :: MD_Assembly_Domain
    TYPE(MD_Instance_Desc),   ALLOCATABLE :: instances(:)
    TYPE(MD_SetDef),          ALLOCATABLE :: node_sets(:)
    TYPE(MD_SetDef),          ALLOCATABLE :: elem_sets(:)
    TYPE(MD_SurfaceDef),      ALLOCATABLE :: surfaces(:)
    TYPE(MD_ConstraintDef),   ALLOCATABLE :: constraints(:)
    TYPE(MD_ConstraintUnion)              :: constraint_union
    TYPE(MD_InteractionUnion)             :: interaction_union

    INTEGER(i4) :: n_instances   = 0_i4
    INTEGER(i4) :: n_node_sets   = 0_i4
    INTEGER(i4) :: n_elem_sets   = 0_i4
    INTEGER(i4) :: n_surfaces    = 0_i4
    INTEGER(i4) :: n_constraints = 0_i4

    TYPE(MD_Asm_Algo) :: algo
    TYPE(MD_Asm_State) :: state
    TYPE(MD_Asm_Ctx) :: ctx
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddInstance
    PROCEDURE :: AddNodeSet
    PROCEDURE :: AddElemSet
    PROCEDURE :: AddSurface
    PROCEDURE :: AddConstraint
    PROCEDURE :: AddTie
    PROCEDURE :: AddMPC
    PROCEDURE :: AddCpl
    PROCEDURE :: AddRigid
    PROCEDURE :: GetInstance
    PROCEDURE :: GetNodeSet
    PROCEDURE :: GetNodeSetByName
    PROCEDURE :: GetElemSet
    PROCEDURE :: GetElemSetByName
    PROCEDURE :: GetSurface
    PROCEDURE :: GetSurfaceByName
    PROCEDURE :: GetConstraint
    PROCEDURE :: GetConstraintByName
    PROCEDURE :: GetTie
    PROCEDURE :: GetMPC
    PROCEDURE :: GetCpl
    PROCEDURE :: GetRigid
    PROCEDURE :: AddContactPair
    PROCEDURE :: GetContactPair
    PROCEDURE :: GetSummary
    PROCEDURE :: ReleaseConstraintUnion
    PROCEDURE :: ReleaseInteractionUnion
  END TYPE MD_Assembly_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AddConstraint` | 323 | `SUBROUTINE AddConstraint(this, def, status)` |
| SUBROUTINE | `AddElemSet` | 361 | `SUBROUTINE AddElemSet(this, def, status)` |
| SUBROUTINE | `AddInstance` | 412 | `SUBROUTINE AddInstance(this, desc, status)` |
| SUBROUTINE | `AddNodeSet` | 463 | `SUBROUTINE AddNodeSet(this, def, status)` |
| SUBROUTINE | `AddSurface` | 514 | `SUBROUTINE AddSurface(this, def, status)` |
| SUBROUTINE | `AddTie` | 568 | `SUBROUTINE AddTie(this, tie_def, status)` |
| SUBROUTINE | `AddMPC` | 584 | `SUBROUTINE AddMPC(this, mpc_def, status)` |
| SUBROUTINE | `AddCpl` | 599 | `SUBROUTINE AddCpl(this, cpl_def, status)` |
| SUBROUTINE | `AddRigid` | 614 | `SUBROUTINE AddRigid(this, rigid_def, status)` |
| SUBROUTINE | `AddContactPair` | 632 | `SUBROUTINE AddContactPair(this, pair_def, status)` |
| SUBROUTINE | `GetInstance` | 650 | `SUBROUTINE GetInstance(this, idx, desc, status)` |
| SUBROUTINE | `GetNodeSet` | 665 | `SUBROUTINE GetNodeSet(this, idx, def, status)` |
| SUBROUTINE | `GetNodeSetByName` | 680 | `SUBROUTINE GetNodeSetByName(this, name, def, status)` |
| SUBROUTINE | `GetElemSet` | 702 | `SUBROUTINE GetElemSet(this, idx, def, status)` |
| SUBROUTINE | `GetElemSetByName` | 717 | `SUBROUTINE GetElemSetByName(this, name, def, status)` |
| SUBROUTINE | `GetSurface` | 739 | `SUBROUTINE GetSurface(this, idx, def, status)` |
| SUBROUTINE | `GetSurfaceByName` | 754 | `SUBROUTINE GetSurfaceByName(this, name, def, status)` |
| SUBROUTINE | `GetConstraint` | 776 | `SUBROUTINE GetConstraint(this, idx, def, status)` |
| SUBROUTINE | `GetConstraintByName` | 794 | `SUBROUTINE GetConstraintByName(this, name, def, status)` |
| SUBROUTINE | `GetTie` | 854 | `SUBROUTINE GetTie(this, idx, tie_def, status)` |
| SUBROUTINE | `GetMPC` | 870 | `SUBROUTINE GetMPC(this, idx, mpc_def, status)` |
| SUBROUTINE | `GetCpl` | 886 | `SUBROUTINE GetCpl(this, idx, cpl_def, status)` |
| SUBROUTINE | `GetRigid` | 902 | `SUBROUTINE GetRigid(this, idx, rigid_def, status)` |
| SUBROUTINE | `GetContactPair` | 918 | `SUBROUTINE GetContactPair(this, idx, pair_def, status)` |
| SUBROUTINE | `MD_Assembly_GetInstance_Idx` | 937 | `SUBROUTINE MD_Assembly_GetInstance_Idx(inst_idx, arg, status)` |
| SUBROUTINE | `MD_Assembly_GetNodeSet_Idx` | 953 | `SUBROUTINE MD_Assembly_GetNodeSet_Idx(set_idx, arg, status)` |
| SUBROUTINE | `MD_Assembly_GetElemSet_Idx` | 969 | `SUBROUTINE MD_Assembly_GetElemSet_Idx(set_idx, arg, status)` |
| SUBROUTINE | `MD_Assembly_GetSurface_Idx` | 985 | `SUBROUTINE MD_Assembly_GetSurface_Idx(surf_idx, arg, status)` |
| SUBROUTINE | `MD_Assembly_GetSurfaceByName_Idx` | 1001 | `SUBROUTINE MD_Assembly_GetSurfaceByName_Idx(name, arg, status)` |
| SUBROUTINE | `MD_Assembly_GetNodeSetByName_Idx` | 1024 | `SUBROUTINE MD_Assembly_GetNodeSetByName_Idx(name, arg, status)` |
| SUBROUTINE | `MD_Assembly_GetElemSetByName_Idx` | 1047 | `SUBROUTINE MD_Assembly_GetElemSetByName_Idx(name, arg, status)` |
| SUBROUTINE | `Init` | 1073 | `SUBROUTINE Init(this, status)` |
| SUBROUTINE | `Finalize` | 1123 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `ReleaseConstraintUnion` | 1178 | `SUBROUTINE ReleaseConstraintUnion(this)` |
| SUBROUTINE | `ReleaseInteractionUnion` | 1217 | `SUBROUTINE ReleaseInteractionUnion(this)` |
| SUBROUTINE | `GetSummary` | 1227 | `SUBROUTINE GetSummary(this, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
