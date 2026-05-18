# `PH_Brg_Domain.f90`

- **Source**: `L4_PH/Bridge/PH_Brg_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Brg_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Brg_Domain`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Brg_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/PH_Brg_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Brg_Inc_Evo_Ctx` (lines 38–41)

```fortran
  TYPE, PUBLIC :: PH_Brg_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Brg_Inc_Evo_Ctx
```

### `PH_Brg_Ctx` (lines 43–54)

```fortran
  TYPE, PUBLIC :: PH_Brg_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Brg_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: step_idx          = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4) :: incr_idx          = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4) :: nRegisteredLibs   = 0_i4
    INTEGER(i4) :: libTypes(PH_BRG_MAX_LIBS) = 0_i4
    LOGICAL     :: libActive(PH_BRG_MAX_LIBS) = .FALSE.
    INTEGER(i4) :: nUEL   = 0_i4
    INTEGER(i4) :: nUMAT  = 0_i4
  END TYPE PH_Brg_Ctx
```

### `PH_Brg_State` (lines 56–62)

```fortran
  TYPE, PUBLIC :: PH_Brg_State
    INTEGER(i4) :: totalCalls      = 0_i4
    INTEGER(i4) :: failedCalls     = 0_i4
    INTEGER(i4) :: lastErrorCode   = 0_i4
    REAL(wp)    :: totalBridgeTime = 0.0_wp
    REAL(wp)    :: gpuTransferTime = 0.0_wp
  END TYPE PH_Brg_State
```

### `PH_Brg_Params` (lines 64–71)

```fortran
  TYPE, PUBLIC :: PH_Brg_Params
    LOGICAL     :: enableUEL       = .FALSE.
    LOGICAL     :: enableUMAT      = .FALSE.
    LOGICAL     :: enableGPU       = .FALSE.
    LOGICAL     :: enableExternal  = .FALSE.
    INTEGER(i4) :: gpuDeviceId     = 0_i4
    LOGICAL     :: gpuAsyncTransfer = .FALSE.
  END TYPE PH_Brg_Params
```

### `PH_Brg_RegisterLib_Arg` (lines 73–78)

```fortran
  TYPE, PUBLIC :: PH_Brg_RegisterLib_Arg
    INTEGER(i4)       :: libType = PH_BRG_UEL
    CHARACTER(LEN=256) :: libPath = ""
    INTEGER(i4)       :: libId   = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Brg_RegisterLib_Arg
```

### `PH_Brg_GetSummary_Arg` (lines 80–83)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Brg_GetSummary_Arg
```

### `PH_Brg_Domain` (lines 85–95)

```fortran
  TYPE, PUBLIC :: PH_Brg_Domain
    TYPE(PH_Brg_Ctx)    :: ctx
    TYPE(PH_Brg_State)  :: state
    TYPE(PH_Brg_Params) :: params
    LOGICAL                :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterLib
    PROCEDURE :: GetSummary
  END TYPE PH_Brg_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 99 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 116 | `SUBROUTINE Init(this, stepId, status, incr_idx)` |
| SUBROUTINE | `RegisterLib` | 133 | `SUBROUTINE RegisterLib(this, arg)` |
| SUBROUTINE | `PH_Brg_RegisterLib_Impl` | 140 | `SUBROUTINE PH_Brg_RegisterLib_Impl(this, libType, libPath, libId, status)` |
| SUBROUTINE | `GetSummary` | 181 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `PH_Brg_GetSummary_Impl` | 187 | `SUBROUTINE PH_Brg_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
