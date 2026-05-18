# `MD_Mat_Plast_Brg.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Plast_Brg_Populate_L4` | 42 | `SUBROUTINE MD_Mat_Plast_Brg_Populate_L4(l3_desc, l4_props, l4_temps, &` |
| SUBROUTINE | `MD_Mat_Plast_Brg_Get_Props` | 116 | `SUBROUTINE MD_Mat_Plast_Brg_Get_Props(l3_desc, props, nprops, status)` |
| SUBROUTINE | `MD_Mat_Plast_Brg_Get_Elastic_Params` | 155 | `SUBROUTINE MD_Mat_Plast_Brg_Get_Elastic_Params(l3_desc, E, nu, G, K, status)` |
| SUBROUTINE | `MD_Mat_Plast_Brg_Validate_For_L4` | 186 | `SUBROUTINE MD_Mat_Plast_Brg_Validate_For_L4(l3_desc, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
