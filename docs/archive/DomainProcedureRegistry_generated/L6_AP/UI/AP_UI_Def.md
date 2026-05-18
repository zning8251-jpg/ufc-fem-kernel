# `AP_UI_Def.f90`

- **Source**: `L6_AP/UI/AP_UI_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_UI_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_UI_Desc` (lines 15–19)

```fortran
  TYPE :: AP_UI_Desc
    INTEGER(i4)       :: output_unit = 6
    INTEGER(i4)       :: line_width  = 80
    CHARACTER(LEN=32) :: banner_char = "="
  END TYPE AP_UI_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
