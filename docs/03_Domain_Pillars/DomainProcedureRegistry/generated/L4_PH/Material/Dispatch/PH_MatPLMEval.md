# `PH_MatPLMEval.f90`

- **Source**: `L4_PH/Material/Dispatch/PH_MatPLMEval.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_MatPLMEval`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_MatPLMEval`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_MatPLMEval`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Dispatch/PH_MatPLMEval.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Plastic_Eval_Dispatch` | 80 | `SUBROUTINE UF_Plastic_Eval_Dispatch(material_id, desc, ctx, algo, status)` |
| SUBROUTINE | `UF_Plastic_UMAT_Dispatch` | 325 | `SUBROUTINE UF_Plastic_UMAT_Dispatch(material_id, stress, statev, ddsdde, &` |
| SUBROUTINE | `Plast_Legacy_Invoke` | 382 | `SUBROUTINE Plast_Legacy_Invoke(material_id, stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_Plastic_Leg_CompProgressive` | 409 | `SUBROUTINE UF_Plastic_Leg_CompProgressive(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_ThermoElectroMagneto` | 419 | `SUBROUTINE UF_Plastic_Leg_ThermoElectroMagneto(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_ThermoViscoplastic` | 429 | `SUBROUTINE UF_Plastic_Leg_ThermoViscoplastic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_ViscoelasticDmg` | 439 | `SUBROUTINE UF_Plastic_Leg_ViscoelasticDmg(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_ViscoplasticDmgEM` | 449 | `SUBROUTINE UF_Plastic_Leg_ViscoplasticDmgEM(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| FUNCTION | `UF_Plastic_GetLegacyID` | 459 | `FUNCTION UF_Plastic_GetLegacyID(legacy_id) RESULT(new_id)` |
| SUBROUTINE | `UF_Plastic_Leg_Biomaterial` | 485 | `SUBROUTINE UF_Plastic_Leg_Biomaterial(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_ConcreteDmg` | 495 | `SUBROUTINE UF_Plastic_Leg_ConcreteDmg(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_CrushableFoam` | 505 | `SUBROUTINE UF_Plastic_Leg_CrushableFoam(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_DruckerPrager` | 515 | `SUBROUTINE UF_Plastic_Leg_DruckerPrager(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_Geotechnical` | 525 | `SUBROUTINE UF_Plastic_Leg_Geotechnical(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_HashinComp` | 535 | `SUBROUTINE UF_Plastic_Leg_HashinComp(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_JohnsonCook` | 545 | `SUBROUTINE UF_Plastic_Leg_JohnsonCook(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_MohrCoulomb` | 555 | `SUBROUTINE UF_Plastic_Leg_MohrCoulomb(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_MultiscaleDmg` | 565 | `SUBROUTINE UF_Plastic_Leg_MultiscaleDmg(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_Nanomaterial` | 575 | `SUBROUTINE UF_Plastic_Leg_Nanomaterial(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_PuckComp` | 585 | `SUBROUTINE UF_Plastic_Leg_PuckComp(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Leg_SmartMat` | 595 | `SUBROUTINE UF_Plastic_Leg_SmartMat(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_CamClay` | 605 | `SUBROUTINE UF_Plastic_Legacy_CamClay(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_Cap` | 615 | `SUBROUTINE UF_Plastic_Legacy_Cap(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_CastIron` | 625 | `SUBROUTINE UF_Plastic_Legacy_CastIron(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_Ceramic` | 635 | `SUBROUTINE UF_Plastic_Legacy_Ceramic(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_Chaboche` | 645 | `SUBROUTINE UF_Plastic_Legacy_Chaboche(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_FGM` | 655 | `SUBROUTINE UF_Plastic_Legacy_FGM(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_Foam3Stage` | 665 | `SUBROUTINE UF_Plastic_Legacy_Foam3Stage(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_Gurson` | 675 | `SUBROUTINE UF_Plastic_Legacy_Gurson(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_Hill` | 685 | `SUBROUTINE UF_Plastic_Legacy_Hill(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_SoftRock` | 695 | `SUBROUTINE UF_Plastic_Legacy_SoftRock(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_Legacy_VonMises` | 705 | `SUBROUTINE UF_Plastic_Legacy_VonMises(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Plastic_UMAT_Wrapper` | 716 | `SUBROUTINE UF_Plastic_UMAT_Wrapper(material_id, stress, statev, ddsdde, &` |
| SUBROUTINE | `PH_MAT_UMAT_Plastic_Dispatch` | 752 | `SUBROUTINE PH_MAT_UMAT_Plastic_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_ConcreteDamage_UMAT` | 788 | `SUBROUTINE UF_ConcreteDamage_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_CompProgDmg_UMAT` | 800 | `SUBROUTINE UF_CompProgDmg_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_PuckCompositeDamage_UMAT` | 812 | `SUBROUTINE UF_PuckCompositeDamage_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_HashinCompDmg_UMAT` | 824 | `SUBROUTINE UF_HashinCompDmg_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |
| SUBROUTINE | `UF_Biomaterial_UMAT` | 836 | `SUBROUTINE UF_Biomaterial_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drplde, drpldt, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
