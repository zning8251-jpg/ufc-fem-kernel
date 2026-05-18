# `PH_Mat_Geo_DruckerPrager_Core.f90`

- **Source**: `L4_PH/Material/Geo/PH_Mat_Geo_DruckerPrager_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Geo_DruckerPrager_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Geo_DruckerPrager_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Geo_DruckerPrager`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Geo`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Geo/PH_Mat_Geo_DruckerPrager_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DP_UpdateConstitutive` | 79 | `SUBROUTINE DP_UpdateConstitutive(mat_desc, nprops, props, &` |
| SUBROUTINE | `DP_ConsistentTangent` | 295 | `SUBROUTINE DP_ConsistentTangent(D_e, K, mu, alpha, beta, H, sqrt_J2, dlambda, ntens, D_ep)` |
| SUBROUTINE | `PH_Mat_PLG_DruckerPrager_Update` | 333 | `SUBROUTINE PH_Mat_PLG_DruckerPrager_Update(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
