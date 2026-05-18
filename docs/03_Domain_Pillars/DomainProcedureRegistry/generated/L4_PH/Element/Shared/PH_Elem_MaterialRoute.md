# `PH_Elem_MaterialRoute.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_MaterialRoute.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_MaterialRoute`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_MaterialRoute`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_MaterialRoute`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_MaterialRoute.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_MatRoute_BuildElasticSlot` | 48 | `SUBROUTINE PH_Elem_MatRoute_BuildElasticSlot(mat_pt_idx, rt_ctx, mat_slot, status)` |
| SUBROUTINE | `PH_Elem_MatRoute_Elastic3D` | 94 | `SUBROUTINE PH_Elem_MatRoute_Elastic3D(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ElasticUniaxial` | 127 | `SUBROUTINE PH_Elem_MatRoute_ElasticUniaxial(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_MatRoute_BeamElasticConstants` | 152 | `SUBROUTINE PH_Elem_MatRoute_BeamElasticConstants(rt_ctx, mat_slot, E_young, nu, status)` |
| SUBROUTINE | `PH_Elem_MatRoute_DashpotScalar` | 174 | `SUBROUTINE PH_Elem_MatRoute_DashpotScalar(rt_ctx, mat_slot, rel_velocity, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ThermalConductivityScalar` | 197 | `SUBROUTINE PH_Elem_MatRoute_ThermalConductivityScalar(rt_ctx, mat_slot, temp_gradient, &` |
| SUBROUTINE | `PH_Elem_MatRoute_MassScalar` | 220 | `SUBROUTINE PH_Elem_MatRoute_MassScalar(rt_ctx, mat_slot, n_node, mass_total, &` |
| SUBROUTINE | `PH_Elem_MatRoute_AcousticFluid` | 249 | `SUBROUTINE PH_Elem_MatRoute_AcousticFluid(rt_ctx, mat_slot, density, bulk_modulus, &` |
| SUBROUTINE | `PH_Elem_MatRoute_CohesiveLinear` | 279 | `SUBROUTINE PH_Elem_MatRoute_CohesiveLinear(rt_ctx, mat_slot, K_n, K_s, &` |
| SUBROUTINE | `PH_Elem_MatRoute_GasketLinear` | 325 | `SUBROUTINE PH_Elem_MatRoute_GasketLinear(rt_ctx, mat_slot, K_g, h_0, p_max, status)` |
| SUBROUTINE | `PH_Elem_MatRoute_InfiniteDecay` | 356 | `SUBROUTINE PH_Elem_MatRoute_InfiniteDecay(rt_ctx, mat_slot, decay_rate, decay_type, &` |
| SUBROUTINE | `PH_Elem_MatRoute_PorousTwoPhase` | 387 | `SUBROUTINE PH_Elem_MatRoute_PorousTwoPhase(rt_ctx, mat_slot, model_flag, alpha_vg, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ElasticPlaneStrain` | 439 | `SUBROUTINE PH_Elem_MatRoute_ElasticPlaneStrain(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ElasticPlaneStress` | 479 | `SUBROUTINE PH_Elem_MatRoute_ElasticPlaneStress(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ElasticAxisymmetric` | 513 | `SUBROUTINE PH_Elem_MatRoute_ElasticAxisymmetric(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ThermoElastic3D` | 551 | `SUBROUTINE PH_Elem_MatRoute_ThermoElastic3D(rt_ctx, mat_slot, dstrain_total, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ThermoElasticPlaneStrain` | 567 | `SUBROUTINE PH_Elem_MatRoute_ThermoElasticPlaneStrain(rt_ctx, mat_slot, dstrain_total, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ThermoElasticPlaneStress` | 583 | `SUBROUTINE PH_Elem_MatRoute_ThermoElasticPlaneStress(rt_ctx, mat_slot, dstrain_total, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ThermoElasticAxisymmetric` | 599 | `SUBROUTINE PH_Elem_MatRoute_ThermoElasticAxisymmetric(rt_ctx, mat_slot, dstrain_total, &` |
| SUBROUTINE | `PH_Elem_MatRoute_ValidateElasticSlot` | 616 | `SUBROUTINE PH_Elem_MatRoute_ValidateElasticSlot(rt_ctx, mat_slot, status)` |
| SUBROUTINE | `PH_Elem_MatRoute_ValidateScalarSlot` | 661 | `SUBROUTINE PH_Elem_MatRoute_ValidateScalarSlot(rt_ctx, mat_slot, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
