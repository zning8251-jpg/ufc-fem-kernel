# `MD_Constr_Mgr.f90`

- **Source**: `L3_MD/Constraint/MD_Constr_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Constr_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Constr_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Constr`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Constraint/MD_Constr_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Constr_Algo` (lines 52–58)

```fortran
  TYPE, PUBLIC :: MD_Constr_Algo
    INTEGER(i4) :: default_enforcement = 1_i4    !! 1=Transform, 2=Lagrange, 3=Penalty
    REAL(wp)    :: default_penalty       = 1.0E+10_wp  !! Default penalty stiffness
    REAL(wp)    :: default_tolerance     = 1.0E-8_wp   !! Constraint tolerance
    INTEGER(i4) :: max_aug_lag_iter      = 10_i4       !! Max augmented Lagrangian iterations
    LOGICAL     :: auto_detect_redundant = .TRUE.      !! Auto-detect redundant constraints
  END TYPE MD_Constr_Algo
```

### `MD_Constr_Ctx` (lines 63–68)

```fortran
  TYPE, PUBLIC :: MD_Constr_Ctx
    INTEGER(i4) :: current_constraint_id = 0_i4
    INTEGER(i4) :: operation_type        = 0_i4  ! 1=Add, 2=Modify, 3=Delete
    LOGICAL     :: validation_pending    = .FALSE.
    CHARACTER(LEN=64) :: last_operation  = ""
  END TYPE MD_Constr_Ctx
```

### `MD_Constraint_Domain` (lines 76–104)

```fortran
  TYPE, PUBLIC :: MD_Constraint_Domain
    !--- Desc (Write-Once) ---
    TYPE(MD_ConstraintUnion) :: constraint_union
    
    !--- State: None (purely Desc in L3) ---
    
    !--- Algo (Solve-phase read-only) ---
    TYPE(MD_Constr_Algo) :: algo
    
    !--- Ctx (transient, not stored) ---
    ! MD_Constr_Ctx created per-operation
    
    !--- Internal ---
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddTie
    PROCEDURE :: AddMPC
    PROCEDURE :: AddCpl
    PROCEDURE :: AddRigid
    PROCEDURE :: GetTie
    PROCEDURE :: GetMPC
    PROCEDURE :: GetCpl
    PROCEDURE :: GetRigid
    PROCEDURE :: ValidateAll
    PROCEDURE :: SyncFromUnion
    PROCEDURE :: GetSummary
  END TYPE MD_Constraint_Domain
```

### `MD_Constr_GetTie_Arg` (lines 107–109)

```fortran
  TYPE, PUBLIC :: MD_Constr_GetTie_Arg
    TYPE(TieConstraintDef) :: def
  END TYPE MD_Constr_GetTie_Arg
```

### `MD_Constr_GetMPC_Arg` (lines 110–112)

```fortran
  TYPE, PUBLIC :: MD_Constr_GetMPC_Arg
    TYPE(MPCConstraintDef) :: def
  END TYPE MD_Constr_GetMPC_Arg
```

### `MD_Constr_GetCpl_Arg` (lines 113–115)

```fortran
  TYPE, PUBLIC :: MD_Constr_GetCpl_Arg
    TYPE(CplConstraintDef) :: def
  END TYPE MD_Constr_GetCpl_Arg
```

### `MD_Constr_GetRigid_Arg` (lines 116–118)

```fortran
  TYPE, PUBLIC :: MD_Constr_GetRigid_Arg
    TYPE(RigidBodyDef) :: def
  END TYPE MD_Constr_GetRigid_Arg
```

### `MD_Constr_GetSummary_Arg` (lines 123–126)

```fortran
  TYPE, PUBLIC :: MD_Constr_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""   ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Constr_GetSummary_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 133 | `SUBROUTINE Init(this, status)` |
| SUBROUTINE | `Finalize` | 155 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `AddTie` | 184 | `SUBROUTINE AddTie(this, tie_def, status)` |
| SUBROUTINE | `AddMPC` | 223 | `SUBROUTINE AddMPC(this, mpc_def, status)` |
| SUBROUTINE | `AddCpl` | 262 | `SUBROUTINE AddCpl(this, cpl_def, status)` |
| SUBROUTINE | `AddRigid` | 301 | `SUBROUTINE AddRigid(this, rigid_def, status)` |
| SUBROUTINE | `GetTie` | 340 | `SUBROUTINE GetTie(this, idx, tie_def, status)` |
| SUBROUTINE | `GetMPC` | 367 | `SUBROUTINE GetMPC(this, idx, mpc_def, status)` |
| SUBROUTINE | `GetCpl` | 394 | `SUBROUTINE GetCpl(this, idx, cpl_def, status)` |
| SUBROUTINE | `GetRigid` | 421 | `SUBROUTINE GetRigid(this, idx, rigid_def, status)` |
| SUBROUTINE | `ValidateAll` | 450 | `SUBROUTINE ValidateAll(this, valid, status)` |
| SUBROUTINE | `SyncFromUnion` | 512 | `SUBROUTINE SyncFromUnion(this, src_union, status)` |
| SUBROUTINE | `AddTieRaw` | 593 | `SUBROUTINE AddTieRaw(this, tie_def, status)` |
| SUBROUTINE | `AddMPCRaw` | 612 | `SUBROUTINE AddMPCRaw(this, mpc_def, status)` |
| SUBROUTINE | `AddCplRaw` | 631 | `SUBROUTINE AddCplRaw(this, cpl_def, status)` |
| SUBROUTINE | `AddRigidRaw` | 650 | `SUBROUTINE AddRigidRaw(this, rigid_def, status)` |
| SUBROUTINE | `GetSummary` | 672 | `SUBROUTINE GetSummary(this, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
