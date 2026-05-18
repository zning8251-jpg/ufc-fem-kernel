# `PH_MatPLM_Kernels.f90`

- **Source**: `L4_PH/Material/Dispatch/PH_MatPLM_Kernels.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_MatPLM_Kernels`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_MatPLM_Kernels`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_MatPLM_Kernels`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Dispatch/PH_MatPLM_Kernels.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_DruckerPrager_UMAT` | 35 | `SUBROUTINE UF_DruckerPrager_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_CamClay_UMAT` | 47 | `SUBROUTINE UF_CamClay_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_JohnsonCook_UMAT` | 59 | `SUBROUTINE UF_JohnsonCook_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Gurson_UMAT` | 71 | `SUBROUTINE UF_Gurson_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_CapPlasticity_UMAT` | 83 | `SUBROUTINE UF_CapPlasticity_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_CrushableFoam_UMAT` | 91 | `SUBROUTINE UF_CrushableFoam_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_SoftRock_UMAT` | 99 | `SUBROUTINE UF_SoftRock_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Foam3Stage_UMAT` | 111 | `SUBROUTINE UF_Foam3Stage_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Ceramic_UMAT` | 123 | `SUBROUTINE UF_Ceramic_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Viscoplastic_UMAT` | 135 | `SUBROUTINE UF_Viscoplastic_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_RateDependentPlasticity_UMAT` | 147 | `SUBROUTINE UF_RateDependentPlasticity_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_ZerilliArmstrong_UMAT` | 159 | `SUBROUTINE UF_ZerilliArmstrong_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_ViscoplasticDamageEM_UMAT` | 171 | `SUBROUTINE UF_ViscoplasticDamageEM_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Nanomaterial_UMAT` | 183 | `SUBROUTINE UF_Nanomaterial_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
