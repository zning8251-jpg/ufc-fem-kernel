# `PH_L4_Populate.f90`

- **Source**: `L4_PH/Material/PH_L4_Populate.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_L4_Populate`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_L4_Populate`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_L4_Populate`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_L4_Populate.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_L4_Build_D_iso6` | 35 | `PURE SUBROUTINE PH_L4_Build_D_iso6(E, nu, D)` |
| SUBROUTINE | `PH_L4_Pack_Props_From_L3` | 51 | `SUBROUTINE PH_L4_Pack_Props_From_L3(md, ph_dom, idx, np, status)` |
| SUBROUTINE | `PH_L4_Alloc_State_ForFamily` | 109 | `SUBROUTINE PH_L4_Alloc_State_ForFamily(ph_dom, idx, phm)` |
| SUBROUTINE | `PH_L4_Populate_Material` | 195 | `SUBROUTINE PH_L4_Populate_Material(ph_dom, mat_id, status, md_src)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
