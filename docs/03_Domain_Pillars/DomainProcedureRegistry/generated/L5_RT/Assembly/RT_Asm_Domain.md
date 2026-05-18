# `RT_Asm_Domain.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Domain`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Assembly_Ctx` (lines 68–71)

```fortran
  TYPE, PUBLIC :: RT_Assembly_Ctx
    INTEGER(i4) :: step_idx = 0_i4   ! [ ] Step L3→L5
    INTEGER(i4) :: incr_idx = 0_i4   ! [ ]
  END TYPE RT_Assembly_Ctx
```

### `RT_Assembly_State` (lines 73–86)

```fortran
  TYPE, PUBLIC :: RT_Assembly_State
    INTEGER(i4)               :: nEq         = 0_i4   ! total equations
    INTEGER(i4)               :: nnz         = 0_i4   ! non-zeros in K
    INTEGER(i8)               :: nnz_long    = 0_i8   ! for large models
    INTEGER(i4), ALLOCATABLE  :: rowPtr(:)             ! CSR row pointer (nEq+1)
    INTEGER(i4), ALLOCATABLE  :: colIdx(:)             ! CSR column index (nnz)
    REAL(wp),    ALLOCATABLE  :: values(:)             ! CSR values (nnz)
    REAL(wp),    ALLOCATABLE  :: F_global(:)           ! (nEq) global force
    REAL(wp),    ALLOCATABLE  :: F_internal(:)         ! (nEq) internal force
    INTEGER(i4), ALLOCATABLE  :: eqNum(:)              ! DOF  ?equation map
    INTEGER(i4), ALLOCATABLE  :: permutation(:)        ! renumbering perm
    LOGICAL                   :: patternBuilt = .FALSE.
    LOGICAL                   :: assembled    = .FALSE.
  END TYPE RT_Assembly_State
```

### `RT_Assembly_Ctrl` (lines 88–94)

```fortran
  TYPE, PUBLIC :: RT_Assembly_Ctrl
    INTEGER(i4) :: renumMethod   = RT_RENUM_RCM
    INTEGER(i4) :: assemblyMode  = RT_ASM_OMP
    INTEGER(i4) :: nColorGroups  = 0_i4     ! for coloring-based assembly
    LOGICAL     :: symmetric     = .TRUE.    ! exploit symmetry
    LOGICAL     :: reusePatt     = .TRUE.    ! reuse sparsity pattern
  END TYPE RT_Assembly_Ctrl
```

### `RT_Asm_BuildPattern_Arg` (lines 99–103)

```fortran
  TYPE, PUBLIC :: RT_Asm_BuildPattern_Arg
    INTEGER(i4) :: nEq = 0_i4   ! number of equations (IN)
    INTEGER(i4) :: nnz = 0_i4   ! non-zeros          (IN)
    TYPE(ErrorStatusType) :: status  !                (OUT)
  END TYPE RT_Asm_BuildPattern_Arg
```

### `RT_Asm_GetSummary_Arg` (lines 105–108)

```fortran
  TYPE, PUBLIC :: RT_Asm_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE RT_Asm_GetSummary_Arg
```

### `RT_Assembly_Domain` (lines 110–124)

```fortran
  TYPE, PUBLIC :: RT_Assembly_Domain
    TYPE(RT_Assembly_Ctx)   :: ctx
    TYPE(RT_Assembly_State) :: state
    TYPE(RT_Assembly_Ctrl)  :: ctrl
    ! Copy of L3/bridge mesh-scale bounds (from bridge%assembly_desc after MD_Model_Brg / FromL3Model).
    TYPE(RT_Asm_Desc)       :: l3_bounds
    LOGICAL                 :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SyncStepIncr
    PROCEDURE :: Finalize
    PROCEDURE :: SyncL3BoundsFromBridge
    PROCEDURE :: BuildPattern
    PROCEDURE :: GetSummary
  END TYPE RT_Assembly_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 128 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `SyncStepIncr` | 145 | `SUBROUTINE SyncStepIncr(this, step_idx, incr_idx)` |
| SUBROUTINE | `Init` | 154 | `SUBROUTINE Init(this, status, step_idx, incr_idx)` |
| SUBROUTINE | `SyncL3BoundsFromBridge` | 176 | `SUBROUTINE SyncL3BoundsFromBridge(this, rt_xfer, status)` |
| SUBROUTINE | `BuildPattern` | 211 | `SUBROUTINE BuildPattern(this, arg)` |
| SUBROUTINE | `RT_Assembly_BuildPattern_Impl` | 218 | `SUBROUTINE RT_Assembly_BuildPattern_Impl(this, nEq, nnz, status)` |
| SUBROUTINE | `GetSummary` | 263 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `RT_Assembly_GetSummary_Impl` | 270 | `SUBROUTINE RT_Assembly_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
