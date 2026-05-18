# `RT_Brg_Mgr.f90`

- **Source**: `L5_RT/Bridge/RT_Brg_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Brg_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Brg_Mgr`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Brg`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Bridge/RT_Brg_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Bridge_Ctx` (lines 33–36)

```fortran
  TYPE, PUBLIC :: RT_Bridge_Ctx
    INTEGER(i4) :: step_idx = 0_i4   ! [ ] Step checkpoint
    INTEGER(i4) :: incr_idx = 0_i4   ! [ ] checkpoint
  END TYPE RT_Bridge_Ctx
```

### `RT_Brg_GetSummary_Arg` (lines 39–42)

```fortran
  TYPE, PUBLIC :: RT_Brg_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""    ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Brg_GetSummary_Arg
```

### `RT_Bridge_Domain` (lines 44–65)

```fortran
  TYPE, PUBLIC :: RT_Bridge_Domain
    TYPE(RT_Bridge_Ctx)       :: ctx
    TYPE(RT_Brg_State) :: state
    TYPE(RT_Brg_Ctrl_Desc)  :: ctrl
    ! Mesh-scale assembly descriptor bounds (filled from L3 via RT_Asm_Brg_FromL3Model on MD_Model_Brg path).
    ! Not a substitute for RT_Asm_Domain%Init / BuildPattern ordering — consumers must respect that lifecycle.
    TYPE(RT_Asm_Desc) :: assembly_desc
    LOGICAL               :: initialized = .FALSE.
    !--- WriteBack/Output bridge coordination (v4.0) ---
    LOGICAL :: wb_enabled       = .TRUE.   ! enable write-back after convergence
    LOGICAL :: output_enabled   = .TRUE.   ! enable output after convergence
    INTEGER(i4) :: wb_frequency = 1_i4     ! write-back every N increments
    INTEGER(i4) :: last_wb_incr = 0_i4     ! last write-back increment
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SyncStepIncr
    PROCEDURE :: Finalize
    PROCEDURE :: GetSummary
    PROCEDURE :: CallL4
    PROCEDURE :: CallL6
    PROCEDURE :: MapErrorCode
  END TYPE RT_Bridge_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 77 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `SyncStepIncr` | 85 | `SUBROUTINE SyncStepIncr(this, step_idx, incr_idx)` |
| SUBROUTINE | `Init` | 94 | `SUBROUTINE Init(this, status, step_idx, incr_idx)` |
| SUBROUTINE | `GetSummary` | 111 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `RT_Bridge_GetSummary_Impl` | 117 | `SUBROUTINE RT_Bridge_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `CallL4` | 141 | `SUBROUTINE CallL4(this, slot_id, operation, status)` |
| SUBROUTINE | `CallL6` | 164 | `SUBROUTINE CallL6(this, request_type, payload_size, status)` |
| SUBROUTINE | `MapErrorCode` | 187 | `SUBROUTINE MapErrorCode(this, source_layer, source_code, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
