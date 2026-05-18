# `MD_Mat_Elas_Dispatch.f90`

- **Source**: `L3_MD/Material/Dispatch/MD_Mat_Elas_Dispatch.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Elas_Dispatch`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Elas_Dispatch`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Elas_Dispatch`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Dispatch/MD_Mat_Elas_Dispatch.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Elastic_Eval_Dispatch` | 27 | `SUBROUTINE UF_Elastic_Eval_Dispatch(material_id, nprops, props, ctx, algo, status)` |
| SUBROUTINE | `UF_Elastic_Eval_Dispatch_FromDesc` | 80 | `SUBROUTINE UF_Elastic_Eval_Dispatch_FromDesc(desc, ctx, algo, status)` |
| SUBROUTINE | `UF_Elastic_UMAT_Dispatch` | 135 | `SUBROUTINE UF_Elastic_UMAT_Dispatch(material_id, stress, statev, ddsdde, &` |
| SUBROUTINE | `MD_MAT_UMAT_Elastic_Dispatch` | 187 | `SUBROUTINE MD_MAT_UMAT_Elastic_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_Elastic_UMAT_Wrapper` | 213 | `SUBROUTINE UF_Elastic_UMAT_Wrapper(material_id, stress, statev, ddsdde, &` |
| SUBROUTINE | `UF_Elastic_Legacy_Isotropic` | 243 | `SUBROUTINE UF_Elastic_Legacy_Isotropic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Elastic_Legacy_Orthotropic` | 255 | `SUBROUTINE UF_Elastic_Legacy_Orthotropic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Elastic_Legacy_TransverseIso` | 267 | `SUBROUTINE UF_Elastic_Legacy_TransverseIso(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Elastic_Legacy_Anisotropic` | 279 | `SUBROUTINE UF_Elastic_Legacy_Anisotropic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Elastic_Legacy_Porous` | 291 | `SUBROUTINE UF_Elastic_Legacy_Porous(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
