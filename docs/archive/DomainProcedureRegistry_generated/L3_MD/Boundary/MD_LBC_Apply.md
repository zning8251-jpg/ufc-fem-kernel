# `MD_LBC_Apply.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Apply.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_LBC_Apply`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Apply`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC`
- **第四段角色（四段式）**: `_Apply`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Apply.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `LoadBC_DistributeLoad_ToNodes` | 60 | `SUBROUTINE LoadBC_DistributeLoad_ToNodes(loadDef, model, nodeSet, time, F, status, md_layer)` |
| SUBROUTINE | `LoadBC_DistributeLoad_ToElements` | 128 | `SUBROUTINE LoadBC_DistributeLoad_ToElements(loadDef, model, elemSet, time, F, status, md_layer)` |
| SUBROUTINE | `LoadBC_DistributeLoad_ToSurface` | 210 | `SUBROUTINE LoadBC_DistributeLoad_ToSurface(loadDef, model, surfaceSet, time, F, status, md_layer)` |
| SUBROUTINE | `LoadBC_ApplyBC_Velocity` | 310 | `SUBROUTINE LoadBC_ApplyBC_Velocity(bcDef, model, time, velocity, dof_mask, status, md_layer)` |
| SUBROUTINE | `LoadBC_ApplyBC_Acceleration` | 381 | `SUBROUTINE LoadBC_ApplyBC_Acceleration(bcDef, model, time, acceleration, dof_mask, status, md_layer)` |
| SUBROUTINE | `LoadBC_ApplyBC_Displacement_GetNodes` | 452 | `SUBROUTINE LoadBC_ApplyBC_Displacement_GetNodes(bcDef, model, time, nodeIds, &` |
| SUBROUTINE | `ApplyLoad_FollowerForce` | 517 | `SUBROUTINE ApplyLoad_FollowerForce(F, model, loadDef, displacement, &` |
| SUBROUTINE | `ApplyLoad_PressureFollowing` | 592 | `SUBROUTINE ApplyLoad_PressureFollowing(F, model, loadDef, displacement, &` |
| SUBROUTINE | `ApplyLoad_BodyForce` | 670 | `SUBROUTINE ApplyLoad_BodyForce(F, model, loadDef, density, &` |
| SUBROUTINE | `UF_DisplacementBC_GetStatistics` | 756 | `SUBROUTINE UF_DisplacementBC_GetStatistics(bc_def, stats, status)` |
| SUBROUTINE | `UF_DisplacementBC_ApplyAtTime` | 770 | `SUBROUTINE UF_DisplacementBC_ApplyAtTime(bc_def, time, amplitude_factor, &` |
| SUBROUTINE | `UF_VelocityBC_GetStatistics` | 791 | `SUBROUTINE UF_VelocityBC_GetStatistics(bc_def, stats, status)` |
| SUBROUTINE | `UF_AccelerationBC_GetStatistics` | 805 | `SUBROUTINE UF_AccelerationBC_GetStatistics(bc_def, stats, status)` |
| SUBROUTINE | `UF_ConcentratedLoad_GetStatistics` | 819 | `SUBROUTINE UF_ConcentratedLoad_GetStatistics(load_def, stats, status)` |
| SUBROUTINE | `UF_ConcentratedLoad_ApplyAtTime` | 833 | `SUBROUTINE UF_ConcentratedLoad_ApplyAtTime(load_def, time, amplitude_factor, &` |
| SUBROUTINE | `UF_DistributedLoad_GetStatistics` | 854 | `SUBROUTINE UF_DistributedLoad_GetStatistics(load_def, stats, status)` |
| SUBROUTINE | `UF_DistributedLoad_ComputeNodalForces` | 868 | `SUBROUTINE UF_DistributedLoad_ComputeNodalForces(load_def, element_area, &` |
| SUBROUTINE | `UF_InitialDisplacement_GetStatistics` | 889 | `SUBROUTINE UF_InitialDisplacement_GetStatistics(ic_def, stats, status)` |
| SUBROUTINE | `UF_InitialVelocity_GetStatistics` | 902 | `SUBROUTINE UF_InitialVelocity_GetStatistics(ic_def, stats, status)` |
| SUBROUTINE | `UF_InitialTemperature_GetStatistics` | 915 | `SUBROUTINE UF_InitialTemperature_GetStatistics(ic_def, stats, status)` |
| SUBROUTINE | `UF_TemperatureField_GetStatistics` | 927 | `SUBROUTINE UF_TemperatureField_GetStatistics(field_def, stats, status)` |
| SUBROUTINE | `UF_TemperatureField_Interpolate` | 941 | `SUBROUTINE UF_TemperatureField_Interpolate(field_def, coordinates, &` |
| SUBROUTINE | `MD_Amp_Slot_GetStatistics` | 952 | `SUBROUTINE MD_Amp_Slot_GetStatistics(amp_def, stats, status)` |
| SUBROUTINE | `UF_LoadCombination_ComputeEffectiveLoad` | 963 | `SUBROUTINE UF_LoadCombination_ComputeEffectiveLoad(load_defs, n_loads, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
