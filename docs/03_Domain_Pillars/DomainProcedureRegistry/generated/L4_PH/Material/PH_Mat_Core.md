# `PH_Mat_Core.f90`

- **Source**: `L4_PH/Material/PH_Mat_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `PH_Mat_Desc_Effective_Model` | 72 | `PURE FUNCTION PH_Mat_Desc_Effective_Model(desc) RESULT(m)` |
| SUBROUTINE | `PH_Mat_Core_Init` | 86 | `SUBROUTINE PH_Mat_Core_Init(status)` |
| SUBROUTINE | `PH_Mat_Core_Finalize` | 102 | `SUBROUTINE PH_Mat_Core_Finalize(status)` |
| SUBROUTINE | `PH_Mat_Core_Init_SDV` | 116 | `SUBROUTINE PH_Mat_Core_Init_SDV(mat_type, mat_id, nsdv, sdv, status)` |
| SUBROUTINE | `PH_Mat_Core_Execute` | 159 | `SUBROUTINE PH_Mat_Core_Execute(domain, mat_pt_idx, status)` |
| SUBROUTINE | `PH_Mat_Execute_Flow` | 173 | `SUBROUTINE PH_Mat_Execute_Flow(domain, mat_pt_idx, status)` |
| SUBROUTINE | `PH_Mat_Execute_Tangent_Flow` | 225 | `SUBROUTINE PH_Mat_Execute_Tangent_Flow(domain, mat_pt_idx, status)` |
| SUBROUTINE | `PH_Mat_S1_FetchState` | 267 | `SUBROUTINE PH_Mat_S1_FetchState(domain, mat_pt_idx, desc, ctx, state, algo, status)` |
| SUBROUTINE | `PH_Mat_S2_Dispatch` | 288 | `SUBROUTINE PH_Mat_S2_Dispatch(desc, status)` |
| SUBROUTINE | `PH_Mat_S3_StressUpdate` | 301 | `SUBROUTINE PH_Mat_S3_StressUpdate(desc, ctx, state, algo, status)` |
| SUBROUTINE | `PH_Mat_S4_Tangent` | 369 | `SUBROUTINE PH_Mat_S4_Tangent(desc, ctx, state, algo, status)` |
| SUBROUTINE | `PH_Mat_Core_Update_Stress` | 429 | `SUBROUTINE PH_Mat_Core_Update_Stress(mat_type, mat_id, nprops, props, &` |
| SUBROUTINE | `PH_Mat_Core_Compute_Tangent` | 494 | `SUBROUTINE PH_Mat_Core_Compute_Tangent(mat_type, mat_id, nprops, props, &` |
| FUNCTION | `PH_Mat_Core_Get_NSDV` | 545 | `FUNCTION PH_Mat_Core_Get_NSDV(mat_type, mat_id) RESULT(nsdv)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
