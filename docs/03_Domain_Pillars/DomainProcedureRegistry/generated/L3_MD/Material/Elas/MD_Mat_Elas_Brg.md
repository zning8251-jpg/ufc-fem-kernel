# `MD_Mat_Elas_Brg.f90`

- **Source**: `L3_MD/Material/Elas/MD_Mat_Elas_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Elas_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Elas_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Elas`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Material/Elas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Elas/MD_Mat_Elas_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Elas_Brg_Populate_L4` | 50 | `SUBROUTINE MD_Mat_Elas_Brg_Populate_L4(l3_desc, l4_props, l4_temps, &` |
| SUBROUTINE | `MD_Mat_Elas_Brg_Get_Props` | 109 | `SUBROUTINE MD_Mat_Elas_Brg_Get_Props(l3_desc, props, nprops, status)` |
| SUBROUTINE | `MD_Mat_Elas_Brg_Get_Derived_Params` | 149 | `SUBROUTINE MD_Mat_Elas_Brg_Get_Derived_Params(l3_desc, E, nu, G, K, &` |
| SUBROUTINE | `MD_Mat_Elas_Brg_Validate_For_L4` | 186 | `SUBROUTINE MD_Mat_Elas_Brg_Validate_For_L4(l3_desc, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
