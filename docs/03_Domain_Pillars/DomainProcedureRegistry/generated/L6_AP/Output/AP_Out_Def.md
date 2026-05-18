# `AP_Out_Def.f90`

- **Source**: `L6_AP/Output/AP_Out_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Out_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Out_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Out`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_Out_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `OutputRequestEntry` (lines 29–40)

```fortran
  TYPE, PUBLIC :: OutputRequestEntry
    INTEGER(i4) :: request_id   = 0_i4
    INTEGER(i4) :: req_type     = 0_i4   ! AP_OUTPUT_REQ_FIELD / AP_OUTPUT_REQ_HISTORY
    CHARACTER(LEN=64) :: name   = ' '
    CHARACTER(LEN=64) :: region = ' '
    INTEGER(i4) :: position     = 0_i4   ! node/elem_in/centroid (OUT_LOC_* from L3)
    INTEGER(i4) :: frequency    = 1_i4
    INTEGER(i4) :: n_vars       = 0_i4
    INTEGER(i4), ALLOCATABLE :: variables(:)
    CHARACTER(LEN=256) :: variable_str = ' '  ! e.g. PRESELECT, U, S (for bridge to L3)
    INTEGER(i4) :: step_id      = 0_i4   ! step when request was defined
  END TYPE OutputRequestEntry
```

### `FrameEntry` (lines 43–49)

```fortran
  TYPE, PUBLIC :: FrameEntry
    INTEGER(i4) :: frame_id     = 0_i4
    INTEGER(i4) :: step_id      = 0_i4
    INTEGER(i4) :: inc_id       = 0_i4
    REAL(wp)    :: time         = 0.0_wp
    INTEGER(i4) :: request_id   = 0_i4   ! which output request
  END TYPE FrameEntry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
