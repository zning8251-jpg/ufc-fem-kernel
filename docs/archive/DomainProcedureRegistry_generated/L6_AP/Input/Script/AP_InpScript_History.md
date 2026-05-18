# `AP_InpScript_History.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_History.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_InpScript_History`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_History`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_History`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_History.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CmdHistory` (lines 22–34)

```fortran
  TYPE, PUBLIC :: CmdHistory
    TYPE(HistoryEntry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: num_entries = 0
    INTEGER(i4) :: max_entries = MAX_HISTORY
    INTEGER(i4) :: idx = 0
    LOGICAL :: enabled = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Add
    PROCEDURE :: Get
    PROCEDURE :: Clear
  END TYPE CmdHistory
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Hist_Init` | 40 | `SUBROUTINE Hist_Init(this, max_entries, status)` |
| SUBROUTINE | `Hist_Add` | 71 | `SUBROUTINE Hist_Add(this, cmd, source, status)` |
| SUBROUTINE | `Hist_Get` | 110 | `SUBROUTINE Hist_Get(this, index, cmd, status)` |
| SUBROUTINE | `Hist_Clear` | 132 | `SUBROUTINE Hist_Clear(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
