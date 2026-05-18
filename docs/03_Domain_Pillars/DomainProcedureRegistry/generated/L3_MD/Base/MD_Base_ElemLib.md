# `MD_Base_ElemLib.f90`

- **Source**: `L3_MD/Base/MD_Base_ElemLib.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Base_ElemLib`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_ElemLib`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_ElemLib`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_ElemLib.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_ComputeJacobian` | 106 | `SUBROUTINE UF_ComputeJacobian(coords, dN_dxi, detJ, dN_dx)` |
| SUBROUTINE | `UF_GetGaussPoints` | 140 | `SUBROUTINE UF_GetGaussPoints(topo, order, nDim, gaussCoords, weights)` |
| SUBROUTINE | `UF_GetShapeFunctions` | 232 | `SUBROUTINE UF_GetShapeFunctions(elemName, xi, sf)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
