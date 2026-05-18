# `MD_Mat_User_Contract.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_User_Contract.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_User_Contract`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_User_Contract`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_User_Contract`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_User_Contract.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NortonCreep_MatDesc_InitFromProps` | 1416 | `SUBROUTINE NortonCreep_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `NortonCreep_MatDesc_Valid` | 1446 | `FUNCTION NortonCreep_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `NortonCreep_MatState_SyncToStateV` | 1453 | `SUBROUTINE NortonCreep_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `NortonCreep_MatState_SyncFromStateV` | 1470 | `SUBROUTINE NortonCreep_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `NortonCreep_MatState_InitFromInputs` | 1493 | `SUBROUTINE NortonCreep_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `NortonCreep_MatCtx_InitFromInputs` | 1516 | `SUBROUTINE NortonCreep_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `NortonCreep_MatCtx_InitDefaults` | 1531 | `SUBROUTINE NortonCreep_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `NortonCreep_MatAlgo_InitDefaults` | 1543 | `SUBROUTINE NortonCreep_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `GarofaloCreep_MatDesc_InitFromProps` | 1561 | `SUBROUTINE GarofaloCreep_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `GarofaloCreep_MatDesc_Valid` | 1592 | `FUNCTION GarofaloCreep_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `GarofaloCreep_MatState_SyncToStateV` | 1599 | `SUBROUTINE GarofaloCreep_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `GarofaloCreep_MatState_SyncFromStateV` | 1616 | `SUBROUTINE GarofaloCreep_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `GarofaloCreep_MatState_InitFromInputs` | 1639 | `SUBROUTINE GarofaloCreep_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `GarofaloCreep_MatCtx_InitFromInputs` | 1662 | `SUBROUTINE GarofaloCreep_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `GarofaloCreep_MatCtx_InitDefaults` | 1677 | `SUBROUTINE GarofaloCreep_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `GarofaloCreep_MatAlgo_InitDefaults` | 1689 | `SUBROUTINE GarofaloCreep_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `CompLamina_MatDesc_InitFromProps` | 1707 | `SUBROUTINE CompLamina_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `CompLamina_MatDesc_Valid` | 1737 | `FUNCTION CompLamina_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `CompLamina_MatState_SyncToStateV` | 1744 | `SUBROUTINE CompLamina_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `CompLamina_MatState_SyncFromStateV` | 1764 | `SUBROUTINE CompLamina_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `CompLamina_MatState_InitFromInputs` | 1790 | `SUBROUTINE CompLamina_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `CompLamina_MatCtx_InitFromInputs` | 1811 | `SUBROUTINE CompLamina_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `CompLamina_MatCtx_InitDefaults` | 1826 | `SUBROUTINE CompLamina_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `CompLamina_MatAlgo_InitDefaults` | 1838 | `SUBROUTINE CompLamina_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `MCC_MatDesc_InitFromProps` | 1855 | `SUBROUTINE MCC_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MCC_MatDesc_Valid` | 1887 | `FUNCTION MCC_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MCC_MatState_SyncToStateV` | 1894 | `SUBROUTINE MCC_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MCC_MatState_SyncFromStateV` | 1916 | `SUBROUTINE MCC_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MCC_MatState_InitFromInputs` | 1945 | `SUBROUTINE MCC_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MCC_MatCtx_InitFromInputs` | 1969 | `SUBROUTINE MCC_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `MCC_MatCtx_InitDefaults` | 1984 | `SUBROUTINE MCC_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MCC_MatAlgo_InitDefaults` | 1996 | `SUBROUTINE MCC_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `SMA_MatDesc_InitFromProps` | 2015 | `SUBROUTINE SMA_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `SMA_MatDesc_Valid` | 2050 | `FUNCTION SMA_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `SMA_MatState_SyncToStateV` | 2057 | `SUBROUTINE SMA_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `SMA_MatState_SyncFromStateV` | 2074 | `SUBROUTINE SMA_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `SMA_MatState_InitFromInputs` | 2097 | `SUBROUTINE SMA_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `SMA_MatCtx_InitFromInputs` | 2120 | `SUBROUTINE SMA_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `SMA_MatCtx_InitDefaults` | 2135 | `SUBROUTINE SMA_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `SMA_MatAlgo_InitDefaults` | 2147 | `SUBROUTINE SMA_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `CrushFoam_MatDesc_InitFromProps` | 2165 | `SUBROUTINE CrushFoam_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `CrushFoam_MatDesc_Valid` | 2195 | `FUNCTION CrushFoam_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `CrushFoam_MatState_SyncToStateV` | 2202 | `SUBROUTINE CrushFoam_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `CrushFoam_MatState_SyncFromStateV` | 2219 | `SUBROUTINE CrushFoam_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `CrushFoam_MatState_InitFromInputs` | 2242 | `SUBROUTINE CrushFoam_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `CrushFoam_MatCtx_InitFromInputs` | 2265 | `SUBROUTINE CrushFoam_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `CrushFoam_MatCtx_InitDefaults` | 2280 | `SUBROUTINE CrushFoam_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `CrushFoam_MatAlgo_InitDefaults` | 2292 | `SUBROUTINE CrushFoam_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Piezo_MatDesc_InitFromProps` | 2310 | `SUBROUTINE Piezo_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Piezo_MatDesc_Valid` | 2356 | `FUNCTION Piezo_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Piezo_MatState_SyncToStateV` | 2362 | `SUBROUTINE Piezo_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Piezo_MatState_SyncFromStateV` | 2375 | `SUBROUTINE Piezo_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Piezo_MatState_InitFromInputs` | 2388 | `SUBROUTINE Piezo_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Piezo_MatCtx_InitFromInputs` | 2407 | `SUBROUTINE Piezo_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, electric_field, kstep, kinc)` |
| SUBROUTINE | `Piezo_MatCtx_InitDefaults` | 2423 | `SUBROUTINE Piezo_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Piezo_MatAlgo_InitDefaults` | 2436 | `SUBROUTINE Piezo_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `RateFoam_MatDesc_InitFromProps` | 2453 | `SUBROUTINE RateFoam_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `RateFoam_MatDesc_Valid` | 2490 | `FUNCTION RateFoam_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `RateFoam_MatState_SyncToStateV` | 2497 | `SUBROUTINE RateFoam_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `RateFoam_MatState_SyncFromStateV` | 2522 | `SUBROUTINE RateFoam_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `RateFoam_MatState_InitFromInputs` | 2546 | `SUBROUTINE RateFoam_MatState_InitFromInputs(this, ndir, nshr, n_prony)` |
| SUBROUTINE | `RateFoam_MatCtx_InitFromInputs` | 2575 | `SUBROUTINE RateFoam_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `RateFoam_MatCtx_InitDefaults` | 2590 | `SUBROUTINE RateFoam_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `RateFoam_MatAlgo_InitDefaults` | 2602 | `SUBROUTINE RateFoam_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `LaRC_MatDesc_InitFromProps` | 2620 | `SUBROUTINE LaRC_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `LaRC_MatDesc_Valid` | 2654 | `FUNCTION LaRC_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `LaRC_MatState_SyncToStateV` | 2662 | `SUBROUTINE LaRC_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `LaRC_MatState_SyncFromStateV` | 2678 | `SUBROUTINE LaRC_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `LaRC_MatState_InitFromInputs` | 2698 | `SUBROUTINE LaRC_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `LaRC_MatCtx_InitFromInputs` | 2718 | `SUBROUTINE LaRC_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `LaRC_MatCtx_InitDefaults` | 2733 | `SUBROUTINE LaRC_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `LaRC_MatAlgo_InitDefaults` | 2745 | `SUBROUTINE LaRC_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `SMP_MatDesc_InitFromProps` | 2762 | `SUBROUTINE SMP_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `SMP_MatDesc_Valid` | 2791 | `FUNCTION SMP_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `SMP_MatState_SyncToStateV` | 2799 | `SUBROUTINE SMP_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `SMP_MatState_SyncFromStateV` | 2816 | `SUBROUTINE SMP_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `SMP_MatState_InitFromInputs` | 2835 | `SUBROUTINE SMP_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `SMP_MatCtx_InitFromInputs` | 2858 | `SUBROUTINE SMP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `SMP_MatCtx_InitDefaults` | 2873 | `SUBROUTINE SMP_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `SMP_MatAlgo_InitDefaults` | 2885 | `SUBROUTINE SMP_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `NoTension_MatDesc_InitFromProps` | 2902 | `SUBROUTINE NoTension_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `NoTension_MatDesc_Valid` | 2928 | `FUNCTION NoTension_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `NoTension_MatState_SyncToStateV` | 2935 | `SUBROUTINE NoTension_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `NoTension_MatState_SyncFromStateV` | 2942 | `SUBROUTINE NoTension_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `NoTension_MatState_InitFromInputs` | 2954 | `SUBROUTINE NoTension_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `NoTension_MatCtx_InitFromInputs` | 2973 | `SUBROUTINE NoTension_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `NoTension_MatCtx_InitDefaults` | 2988 | `SUBROUTINE NoTension_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `NoTension_MatAlgo_InitDefaults` | 3000 | `SUBROUTINE NoTension_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `PQFiber_MatDesc_InitFromProps` | 3017 | `SUBROUTINE PQFiber_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `PQFiber_MatDesc_Valid` | 3047 | `FUNCTION PQFiber_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `PQFiber_MatState_SyncToStateV` | 3054 | `SUBROUTINE PQFiber_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `PQFiber_MatState_SyncFromStateV` | 3061 | `SUBROUTINE PQFiber_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `PQFiber_MatState_InitFromInputs` | 3073 | `SUBROUTINE PQFiber_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `PQFiber_MatCtx_InitFromInputs` | 3092 | `SUBROUTINE PQFiber_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `PQFiber_MatCtx_InitDefaults` | 3107 | `SUBROUTINE PQFiber_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `PQFiber_MatAlgo_InitDefaults` | 3119 | `SUBROUTINE PQFiber_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `CZM_MatDesc_InitFromProps` | 3137 | `SUBROUTINE CZM_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `CZM_MatDesc_Valid` | 3167 | `FUNCTION CZM_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `CZM_MatState_SyncToStateV` | 3175 | `SUBROUTINE CZM_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `CZM_MatState_SyncFromStateV` | 3195 | `SUBROUTINE CZM_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `CZM_MatState_InitFromInputs` | 3221 | `SUBROUTINE CZM_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `CZM_MatCtx_InitFromInputs` | 3242 | `SUBROUTINE CZM_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `CZM_MatCtx_InitDefaults` | 3257 | `SUBROUTINE CZM_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `CZM_MatAlgo_InitDefaults` | 3269 | `SUBROUTINE CZM_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Fabric_MatDesc_InitFromProps` | 3286 | `SUBROUTINE Fabric_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Fabric_MatDesc_Valid` | 3319 | `FUNCTION Fabric_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Fabric_MatState_SyncToStateV` | 3327 | `SUBROUTINE Fabric_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Fabric_MatState_SyncFromStateV` | 3343 | `SUBROUTINE Fabric_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Fabric_MatState_InitFromInputs` | 3363 | `SUBROUTINE Fabric_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Fabric_MatCtx_InitFromInputs` | 3383 | `SUBROUTINE Fabric_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Fabric_MatCtx_InitDefaults` | 3398 | `SUBROUTINE Fabric_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Fabric_MatAlgo_InitDefaults` | 3410 | `SUBROUTINE Fabric_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `ThermoMech_MatDesc_InitFromProps` | 3427 | `SUBROUTINE ThermoMech_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `ThermoMech_MatDesc_Valid` | 3457 | `FUNCTION ThermoMech_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `ThermoMech_MatState_SyncToStateV` | 3465 | `SUBROUTINE ThermoMech_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `ThermoMech_MatState_SyncFromStateV` | 3482 | `SUBROUTINE ThermoMech_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `ThermoMech_MatState_InitFromInputs` | 3501 | `SUBROUTINE ThermoMech_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `ThermoMech_MatCtx_InitFromInputs` | 3524 | `SUBROUTINE ThermoMech_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `ThermoMech_MatCtx_InitDefaults` | 3539 | `SUBROUTINE ThermoMech_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `ThermoMech_MatAlgo_InitDefaults` | 3551 | `SUBROUTINE ThermoMech_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `MagnetoMech_MatDesc_InitFromProps` | 3568 | `SUBROUTINE MagnetoMech_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MagnetoMech_MatDesc_Valid` | 3596 | `FUNCTION MagnetoMech_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MagnetoMech_MatState_SyncToStateV` | 3603 | `SUBROUTINE MagnetoMech_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MagnetoMech_MatState_SyncFromStateV` | 3620 | `SUBROUTINE MagnetoMech_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MagnetoMech_MatState_InitFromInputs` | 3637 | `SUBROUTINE MagnetoMech_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MagnetoMech_MatCtx_InitFromInputs` | 3657 | `SUBROUTINE MagnetoMech_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, H_field_ext, kstep, kinc)` |
| SUBROUTINE | `MagnetoMech_MatCtx_InitDefaults` | 3673 | `SUBROUTINE MagnetoMech_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MagnetoMech_MatAlgo_InitDefaults` | 3686 | `SUBROUTINE MagnetoMech_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `PoroFluid_MatDesc_InitFromProps` | 3703 | `SUBROUTINE PoroFluid_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `PoroFluid_MatDesc_Valid` | 3732 | `FUNCTION PoroFluid_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `PoroFluid_MatState_SyncToStateV` | 3740 | `SUBROUTINE PoroFluid_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `PoroFluid_MatState_SyncFromStateV` | 3757 | `SUBROUTINE PoroFluid_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `PoroFluid_MatState_InitFromInputs` | 3776 | `SUBROUTINE PoroFluid_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `PoroFluid_MatCtx_InitFromInputs` | 3796 | `SUBROUTINE PoroFluid_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `PoroFluid_MatCtx_InitDefaults` | 3811 | `SUBROUTINE PoroFluid_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `PoroFluid_MatAlgo_InitDefaults` | 3823 | `SUBROUTINE PoroFluid_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `BioSoftTissue_MatDesc_InitFromProps` | 3840 | `SUBROUTINE BioSoftTissue_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `BioSoftTissue_MatDesc_Valid` | 3869 | `FUNCTION BioSoftTissue_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `BioSoftTissue_MatState_SyncToStateV` | 3876 | `SUBROUTINE BioSoftTissue_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `BioSoftTissue_MatState_SyncFromStateV` | 3883 | `SUBROUTINE BioSoftTissue_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `BioSoftTissue_MatState_InitFromInputs` | 3890 | `SUBROUTINE BioSoftTissue_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `BioSoftTissue_MatCtx_InitFromInputs` | 3908 | `SUBROUTINE BioSoftTissue_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `BioSoftTissue_MatCtx_InitDefaults` | 3923 | `SUBROUTINE BioSoftTissue_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `BioSoftTissue_MatAlgo_InitDefaults` | 3935 | `SUBROUTINE BioSoftTissue_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `NoCompression_MatDesc_InitFromProps` | 3952 | `SUBROUTINE NoCompression_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `NoCompression_MatDesc_Valid` | 3978 | `FUNCTION NoCompression_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `NoCompression_MatState_SyncToStateV` | 3985 | `SUBROUTINE NoCompression_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `NoCompression_MatState_SyncFromStateV` | 3992 | `SUBROUTINE NoCompression_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `NoCompression_MatState_InitFromInputs` | 4004 | `SUBROUTINE NoCompression_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `NoCompression_MatCtx_InitFromInputs` | 4023 | `SUBROUTINE NoCompression_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `NoCompression_MatCtx_InitDefaults` | 4038 | `SUBROUTINE NoCompression_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `NoCompression_MatAlgo_InitDefaults` | 4050 | `SUBROUTINE NoCompression_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Multiscale_MatDesc_InitFromProps` | 4067 | `SUBROUTINE Multiscale_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Multiscale_MatDesc_Valid` | 4094 | `FUNCTION Multiscale_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Multiscale_MatState_SyncToStateV` | 4101 | `SUBROUTINE Multiscale_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Multiscale_MatState_SyncFromStateV` | 4115 | `SUBROUTINE Multiscale_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Multiscale_MatState_InitFromInputs` | 4129 | `SUBROUTINE Multiscale_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Multiscale_MatCtx_InitFromInputs` | 4151 | `SUBROUTINE Multiscale_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Multiscale_MatCtx_InitDefaults` | 4166 | `SUBROUTINE Multiscale_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Multiscale_MatAlgo_InitDefaults` | 4178 | `SUBROUTINE Multiscale_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `TempDependent_MatDesc_InitFromProps` | 4195 | `SUBROUTINE TempDependent_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `TempDependent_MatDesc_Valid` | 4223 | `FUNCTION TempDependent_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `TempDependent_MatState_SyncToStateV` | 4230 | `SUBROUTINE TempDependent_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `TempDependent_MatState_SyncFromStateV` | 4237 | `SUBROUTINE TempDependent_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `TempDependent_MatState_InitFromInputs` | 4249 | `SUBROUTINE TempDependent_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `TempDependent_MatCtx_InitFromInputs` | 4268 | `SUBROUTINE TempDependent_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `TempDependent_MatCtx_InitDefaults` | 4283 | `SUBROUTINE TempDependent_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `TempDependent_MatAlgo_InitDefaults` | 4295 | `SUBROUTINE TempDependent_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `MC_Geo_MatDesc_InitFromProps` | 4312 | `SUBROUTINE MC_Geo_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MC_Geo_MatDesc_Valid` | 4341 | `FUNCTION MC_Geo_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MC_Geo_MatState_SyncToStateV` | 4348 | `SUBROUTINE MC_Geo_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MC_Geo_MatState_SyncFromStateV` | 4365 | `SUBROUTINE MC_Geo_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MC_Geo_MatState_InitFromInputs` | 4384 | `SUBROUTINE MC_Geo_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MC_Geo_MatCtx_InitFromInputs` | 4407 | `SUBROUTINE MC_Geo_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `MC_Geo_MatCtx_InitDefaults` | 4422 | `SUBROUTINE MC_Geo_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MC_Geo_MatAlgo_InitDefaults` | 4434 | `SUBROUTINE MC_Geo_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatDesc_InitFromProps` | 4452 | `SUBROUTINE MD_MAT_DP_Geo_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MD_MAT_DP_Geo_MatDesc_Valid` | 4481 | `FUNCTION MD_MAT_DP_Geo_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatState_SyncToStateV` | 4488 | `SUBROUTINE MD_MAT_DP_Geo_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatState_SyncFromStateV` | 4505 | `SUBROUTINE MD_MAT_DP_Geo_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatState_InitFromInputs` | 4524 | `SUBROUTINE MD_MAT_DP_Geo_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatCtx_InitFromInputs` | 4547 | `SUBROUTINE MD_MAT_DP_Geo_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatCtx_InitDefaults` | 4562 | `SUBROUTINE MD_MAT_DP_Geo_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MD_MAT_DP_Geo_MatAlgo_InitDefaults` | 4574 | `SUBROUTINE MD_MAT_DP_Geo_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `CappedDP_MatDesc_InitFromProps` | 4592 | `SUBROUTINE CappedDP_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `CappedDP_MatDesc_Valid` | 4623 | `FUNCTION CappedDP_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `CappedDP_MatState_SyncToStateV` | 4630 | `SUBROUTINE CappedDP_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `CappedDP_MatState_SyncFromStateV` | 4647 | `SUBROUTINE CappedDP_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `CappedDP_MatState_InitFromInputs` | 4666 | `SUBROUTINE CappedDP_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `CappedDP_MatCtx_InitFromInputs` | 4689 | `SUBROUTINE CappedDP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `CappedDP_MatCtx_InitDefaults` | 4704 | `SUBROUTINE CappedDP_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `CappedDP_MatAlgo_InitDefaults` | 4716 | `SUBROUTINE CappedDP_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `JointedRock_MatDesc_InitFromProps` | 4734 | `SUBROUTINE JointedRock_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `JointedRock_MatDesc_Valid` | 4764 | `FUNCTION JointedRock_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `JointedRock_MatState_SyncToStateV` | 4772 | `SUBROUTINE JointedRock_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `JointedRock_MatState_SyncFromStateV` | 4788 | `SUBROUTINE JointedRock_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `JointedRock_MatState_InitFromInputs` | 4808 | `SUBROUTINE JointedRock_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `JointedRock_MatCtx_InitFromInputs` | 4828 | `SUBROUTINE JointedRock_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `JointedRock_MatCtx_InitDefaults` | 4843 | `SUBROUTINE JointedRock_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `JointedRock_MatAlgo_InitDefaults` | 4855 | `SUBROUTINE JointedRock_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `GeoCreep_MatDesc_InitFromProps` | 4872 | `SUBROUTINE GeoCreep_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `GeoCreep_MatDesc_Valid` | 4902 | `FUNCTION GeoCreep_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `GeoCreep_MatState_SyncToStateV` | 4909 | `SUBROUTINE GeoCreep_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `GeoCreep_MatState_SyncFromStateV` | 4926 | `SUBROUTINE GeoCreep_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `GeoCreep_MatState_InitFromInputs` | 4945 | `SUBROUTINE GeoCreep_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `GeoCreep_MatCtx_InitFromInputs` | 4968 | `SUBROUTINE GeoCreep_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `GeoCreep_MatCtx_InitDefaults` | 4983 | `SUBROUTINE GeoCreep_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `GeoCreep_MatAlgo_InitDefaults` | 4995 | `SUBROUTINE GeoCreep_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `ExtDP_MatDesc_InitFromProps` | 5012 | `SUBROUTINE ExtDP_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `ExtDP_MatDesc_Valid` | 5042 | `FUNCTION ExtDP_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `ExtDP_MatState_SyncToStateV` | 5049 | `SUBROUTINE ExtDP_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `ExtDP_MatState_SyncFromStateV` | 5066 | `SUBROUTINE ExtDP_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `ExtDP_MatState_InitFromInputs` | 5085 | `SUBROUTINE ExtDP_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `ExtDP_MatCtx_InitFromInputs` | 5108 | `SUBROUTINE ExtDP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `ExtDP_MatCtx_InitDefaults` | 5123 | `SUBROUTINE ExtDP_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `ExtDP_MatAlgo_InitDefaults` | 5135 | `SUBROUTINE ExtDP_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Ortho3D_MatDesc_InitFromProps` | 5153 | `SUBROUTINE Ortho3D_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Ortho3D_MatDesc_Valid` | 5186 | `FUNCTION Ortho3D_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Ortho3D_MatState_SyncToStateV` | 5194 | `SUBROUTINE Ortho3D_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Ortho3D_MatState_SyncFromStateV` | 5201 | `SUBROUTINE Ortho3D_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Ortho3D_MatState_InitFromInputs` | 5208 | `SUBROUTINE Ortho3D_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Ortho3D_MatCtx_InitFromInputs` | 5226 | `SUBROUTINE Ortho3D_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Ortho3D_MatCtx_InitDefaults` | 5241 | `SUBROUTINE Ortho3D_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Ortho3D_MatAlgo_InitDefaults` | 5253 | `SUBROUTINE Ortho3D_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Aniso21_MatDesc_InitFromProps` | 5270 | `SUBROUTINE Aniso21_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Aniso21_MatDesc_Valid` | 5303 | `FUNCTION Aniso21_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Aniso21_MatState_SyncToStateV` | 5309 | `SUBROUTINE Aniso21_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Aniso21_MatState_SyncFromStateV` | 5316 | `SUBROUTINE Aniso21_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Aniso21_MatState_InitFromInputs` | 5323 | `SUBROUTINE Aniso21_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Aniso21_MatCtx_InitFromInputs` | 5341 | `SUBROUTINE Aniso21_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Aniso21_MatCtx_InitDefaults` | 5356 | `SUBROUTINE Aniso21_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Aniso21_MatAlgo_InitDefaults` | 5368 | `SUBROUTINE Aniso21_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `VDW_MatDesc_InitFromProps` | 5385 | `SUBROUTINE VDW_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `VDW_MatDesc_Valid` | 5414 | `FUNCTION VDW_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `VDW_MatState_SyncToStateV` | 5421 | `SUBROUTINE VDW_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `VDW_MatState_SyncFromStateV` | 5428 | `SUBROUTINE VDW_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `VDW_MatState_InitFromInputs` | 5435 | `SUBROUTINE VDW_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `VDW_MatCtx_InitFromInputs` | 5453 | `SUBROUTINE VDW_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `VDW_MatCtx_InitDefaults` | 5468 | `SUBROUTINE VDW_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `VDW_MatAlgo_InitDefaults` | 5480 | `SUBROUTINE VDW_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Marlow_MatDesc_InitFromProps` | 5497 | `SUBROUTINE Marlow_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Marlow_MatDesc_Valid` | 5533 | `FUNCTION Marlow_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Marlow_MatState_SyncToStateV` | 5543 | `SUBROUTINE Marlow_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Marlow_MatState_SyncFromStateV` | 5550 | `SUBROUTINE Marlow_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Marlow_MatState_InitFromInputs` | 5557 | `SUBROUTINE Marlow_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Marlow_MatCtx_InitFromInputs` | 5575 | `SUBROUTINE Marlow_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Marlow_MatCtx_InitDefaults` | 5590 | `SUBROUTINE Marlow_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Marlow_MatAlgo_InitDefaults` | 5602 | `SUBROUTINE Marlow_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Gent_MatDesc_InitFromProps` | 5619 | `SUBROUTINE Gent_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Gent_MatDesc_Valid` | 5646 | `FUNCTION Gent_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Gent_MatState_SyncToStateV` | 5653 | `SUBROUTINE Gent_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Gent_MatState_SyncFromStateV` | 5660 | `SUBROUTINE Gent_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Gent_MatState_InitFromInputs` | 5667 | `SUBROUTINE Gent_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Gent_MatCtx_InitFromInputs` | 5685 | `SUBROUTINE Gent_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Gent_MatCtx_InitDefaults` | 5700 | `SUBROUTINE Gent_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Gent_MatAlgo_InitDefaults` | 5712 | `SUBROUTINE Gent_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `MC_Concrete_MatDesc_InitFromProps` | 5729 | `SUBROUTINE MC_Concrete_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MC_Concrete_MatDesc_Valid` | 5758 | `FUNCTION MC_Concrete_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MC_Concrete_MatState_SyncToStateV` | 5765 | `SUBROUTINE MC_Concrete_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MC_Concrete_MatState_SyncFromStateV` | 5782 | `SUBROUTINE MC_Concrete_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MC_Concrete_MatState_InitFromInputs` | 5801 | `SUBROUTINE MC_Concrete_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MC_Concrete_MatCtx_InitFromInputs` | 5824 | `SUBROUTINE MC_Concrete_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `MC_Concrete_MatCtx_InitDefaults` | 5839 | `SUBROUTINE MC_Concrete_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MC_Concrete_MatAlgo_InitDefaults` | 5851 | `SUBROUTINE MC_Concrete_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `NL_Visc_MatDesc_InitFromProps` | 5869 | `SUBROUTINE NL_Visc_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `NL_Visc_MatDesc_Valid` | 5906 | `FUNCTION NL_Visc_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `NL_Visc_MatState_SyncToStateV` | 5913 | `SUBROUTINE NL_Visc_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `NL_Visc_MatState_SyncFromStateV` | 5930 | `SUBROUTINE NL_Visc_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `NL_Visc_MatState_InitFromInputs` | 5952 | `SUBROUTINE NL_Visc_MatState_InitFromInputs(this, ndir, nshr, n_prony)` |
| SUBROUTINE | `NL_Visc_MatCtx_InitFromInputs` | 5976 | `SUBROUTINE NL_Visc_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `NL_Visc_MatCtx_InitDefaults` | 5991 | `SUBROUTINE NL_Visc_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `NL_Visc_MatAlgo_InitDefaults` | 6003 | `SUBROUTINE NL_Visc_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `PolymerCure_MatDesc_InitFromProps` | 6020 | `SUBROUTINE PolymerCure_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `PolymerCure_MatDesc_Valid` | 6050 | `FUNCTION PolymerCure_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `PolymerCure_MatState_SyncToStateV` | 6058 | `SUBROUTINE PolymerCure_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `PolymerCure_MatState_SyncFromStateV` | 6074 | `SUBROUTINE PolymerCure_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `PolymerCure_MatState_InitFromInputs` | 6094 | `SUBROUTINE PolymerCure_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `PolymerCure_MatCtx_InitFromInputs` | 6114 | `SUBROUTINE PolymerCure_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `PolymerCure_MatCtx_InitDefaults` | 6129 | `SUBROUTINE PolymerCure_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `PolymerCure_MatAlgo_InitDefaults` | 6141 | `SUBROUTINE PolymerCure_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `ViscPlastDmg_MatDesc_InitFromProps` | 6158 | `SUBROUTINE ViscPlastDmg_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `ViscPlastDmg_MatDesc_Valid` | 6188 | `FUNCTION ViscPlastDmg_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `ViscPlastDmg_MatState_SyncToStateV` | 6196 | `SUBROUTINE ViscPlastDmg_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `ViscPlastDmg_MatState_SyncFromStateV` | 6217 | `SUBROUTINE ViscPlastDmg_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `ViscPlastDmg_MatState_InitFromInputs` | 6242 | `SUBROUTINE ViscPlastDmg_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `ViscPlastDmg_MatCtx_InitFromInputs` | 6266 | `SUBROUTINE ViscPlastDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `ViscPlastDmg_MatCtx_InitDefaults` | 6281 | `SUBROUTINE ViscPlastDmg_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `ViscPlastDmg_MatAlgo_InitDefaults` | 6293 | `SUBROUTINE ViscPlastDmg_MatAlgo_InitDefaults(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
