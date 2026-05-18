# `PH_Mat_Geo_CamClay_Core.f90`

- **Source**: `L4_PH/Material/Geo/PH_Mat_Geo_CamClay_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Geo_CamClay_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Geo_CamClay_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Geo_CamClay`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Geo`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Geo/PH_Mat_Geo_CamClay_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `CamClay_UpdateConstitutive` | 91 | `SUBROUTINE CamClay_UpdateConstitutive(mat_desc, nprops, props, &` |
| SUBROUTINE | `ComputeStressInvariants` | 249 | `SUBROUTINE ComputeStressInvariants(stress, ndim, p, q, s_dev)` |
| SUBROUTINE | `ComputeYieldFunction` | 289 | `SUBROUTINE ComputeYieldFunction(p, q, p0, M, lambda, kappa, f)` |
| SUBROUTINE | `ReturnMapping` | 306 | `SUBROUTINE ReturnMapping(p_trial, q_trial, s_dev, p0_old, &` |
| SUBROUTINE | `PH_Mat_PLG_CamClay_Update` | 406 | `SUBROUTINE PH_Mat_PLG_CamClay_Update(ctx, status)` |
| SUBROUTINE | `PH_Mat_Geo_CC_Eval_Wrapper` | 451 | `SUBROUTINE PH_Mat_Geo_CC_Eval_Wrapper(desc, state, algo, strain_in, stress, ddsdde, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
