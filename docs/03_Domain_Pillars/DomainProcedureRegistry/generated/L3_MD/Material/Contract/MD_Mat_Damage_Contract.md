# `MD_Mat_Damage_Contract.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_Damage_Contract.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Damage_Contract`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Damage_Contract`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Damage_Contract`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_Damage_Contract.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DuctileDmg_MatDesc_InitFromProps` | 401 | `SUBROUTINE DuctileDmg_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `DuctileDmg_MatDesc_Valid` | 448 | `FUNCTION DuctileDmg_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `DuctileDmg_MatState_SyncToStateV` | 472 | `SUBROUTINE DuctileDmg_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `DuctileDmg_MatState_SyncFromStateV` | 509 | `SUBROUTINE DuctileDmg_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `DuctileDmg_MatState_InitFromInputs` | 554 | `SUBROUTINE DuctileDmg_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `DuctileDmg_MatCtx_InitFromInputs` | 589 | `SUBROUTINE DuctileDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, strain_rate, dtime, kstep, kinc)` |
| SUBROUTINE | `DuctileDmg_MatCtx_InitDefaults` | 609 | `SUBROUTINE DuctileDmg_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `DuctileDmg_MatAlgo_InitDefaults` | 628 | `SUBROUTINE DuctileDmg_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `ThermalDmg_MatDesc_InitFromProps` | 648 | `SUBROUTINE ThermalDmg_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `ThermalDmg_MatDesc_Valid` | 680 | `FUNCTION ThermalDmg_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `ThermalDmg_MatState_SyncToStateV` | 687 | `SUBROUTINE ThermalDmg_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `ThermalDmg_MatState_SyncFromStateV` | 715 | `SUBROUTINE ThermalDmg_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `ThermalDmg_MatState_InitFromInputs` | 753 | `SUBROUTINE ThermalDmg_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `ThermalDmg_MatCtx_InitFromInputs` | 776 | `SUBROUTINE ThermalDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtemp, dtime, kstep, kinc)` |
| SUBROUTINE | `ThermalDmg_MatCtx_InitDefaults` | 792 | `SUBROUTINE ThermalDmg_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `ThermalDmg_MatAlgo_InitDefaults` | 805 | `SUBROUTINE ThermalDmg_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `CreepDmg_MatDesc_InitFromProps` | 823 | `SUBROUTINE CreepDmg_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `CreepDmg_MatDesc_Valid` | 854 | `FUNCTION CreepDmg_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `CreepDmg_MatState_SyncToStateV` | 861 | `SUBROUTINE CreepDmg_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `CreepDmg_MatState_SyncFromStateV` | 877 | `SUBROUTINE CreepDmg_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `CreepDmg_MatState_InitFromInputs` | 897 | `SUBROUTINE CreepDmg_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `CreepDmg_MatCtx_InitFromInputs` | 917 | `SUBROUTINE CreepDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `CreepDmg_MatCtx_InitDefaults` | 932 | `SUBROUTINE CreepDmg_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `CreepDmg_MatAlgo_InitDefaults` | 944 | `SUBROUTINE CreepDmg_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `CDP_MatDesc_InitFromProps` | 962 | `SUBROUTINE CDP_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `CDP_MatDesc_Valid` | 995 | `FUNCTION CDP_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `CDP_MatState_SyncToStateV` | 1002 | `SUBROUTINE CDP_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `CDP_MatState_SyncFromStateV` | 1031 | `SUBROUTINE CDP_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `CDP_MatState_InitFromInputs` | 1072 | `SUBROUTINE CDP_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `CDP_MatCtx_InitFromInputs` | 1098 | `SUBROUTINE CDP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `CDP_MatCtx_InitDefaults` | 1113 | `SUBROUTINE CDP_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `CDP_MatAlgo_InitDefaults` | 1125 | `SUBROUTINE CDP_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Hashin_MatDesc_InitFromProps` | 1143 | `SUBROUTINE Hashin_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Hashin_MatDesc_Valid` | 1176 | `FUNCTION Hashin_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Hashin_MatState_SyncToStateV` | 1184 | `SUBROUTINE Hashin_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Hashin_MatState_SyncFromStateV` | 1208 | `SUBROUTINE Hashin_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Hashin_MatState_InitFromInputs` | 1240 | `SUBROUTINE Hashin_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Hashin_MatCtx_InitFromInputs` | 1262 | `SUBROUTINE Hashin_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Hashin_MatCtx_InitDefaults` | 1277 | `SUBROUTINE Hashin_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Hashin_MatAlgo_InitDefaults` | 1289 | `SUBROUTINE Hashin_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `DiffuseCrack_MatDesc_InitFromProps` | 1306 | `SUBROUTINE DiffuseCrack_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `DiffuseCrack_MatDesc_Valid` | 1335 | `FUNCTION DiffuseCrack_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `DiffuseCrack_MatState_SyncToStateV` | 1342 | `SUBROUTINE DiffuseCrack_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `DiffuseCrack_MatState_SyncFromStateV` | 1358 | `SUBROUTINE DiffuseCrack_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `DiffuseCrack_MatState_InitFromInputs` | 1376 | `SUBROUTINE DiffuseCrack_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `DiffuseCrack_MatCtx_InitFromInputs` | 1396 | `SUBROUTINE DiffuseCrack_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `DiffuseCrack_MatCtx_InitDefaults` | 1411 | `SUBROUTINE DiffuseCrack_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `DiffuseCrack_MatAlgo_InitDefaults` | 1423 | `SUBROUTINE DiffuseCrack_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Puck_MatDesc_InitFromProps` | 1440 | `SUBROUTINE Puck_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Puck_MatDesc_Valid` | 1473 | `FUNCTION Puck_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Puck_MatState_SyncToStateV` | 1481 | `SUBROUTINE Puck_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Puck_MatState_SyncFromStateV` | 1501 | `SUBROUTINE Puck_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Puck_MatState_InitFromInputs` | 1527 | `SUBROUTINE Puck_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Puck_MatCtx_InitFromInputs` | 1548 | `SUBROUTINE Puck_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Puck_MatCtx_InitDefaults` | 1563 | `SUBROUTINE Puck_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Puck_MatAlgo_InitDefaults` | 1575 | `SUBROUTINE Puck_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `BrittleCrack_MatDesc_InitFromProps` | 1592 | `SUBROUTINE BrittleCrack_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `BrittleCrack_MatDesc_Valid` | 1620 | `FUNCTION BrittleCrack_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `BrittleCrack_MatState_SyncToStateV` | 1627 | `SUBROUTINE BrittleCrack_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `BrittleCrack_MatState_SyncFromStateV` | 1634 | `SUBROUTINE BrittleCrack_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `BrittleCrack_MatState_InitFromInputs` | 1646 | `SUBROUTINE BrittleCrack_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `BrittleCrack_MatCtx_InitFromInputs` | 1665 | `SUBROUTINE BrittleCrack_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `BrittleCrack_MatCtx_InitDefaults` | 1680 | `SUBROUTINE BrittleCrack_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `BrittleCrack_MatAlgo_InitDefaults` | 1692 | `SUBROUTINE BrittleCrack_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `ProgressiveDmg_MatDesc_InitFromProps` | 1709 | `SUBROUTINE ProgressiveDmg_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `ProgressiveDmg_MatDesc_Valid` | 1742 | `FUNCTION ProgressiveDmg_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `ProgressiveDmg_MatState_SyncToStateV` | 1750 | `SUBROUTINE ProgressiveDmg_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `ProgressiveDmg_MatState_SyncFromStateV` | 1766 | `SUBROUTINE ProgressiveDmg_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `ProgressiveDmg_MatState_InitFromInputs` | 1786 | `SUBROUTINE ProgressiveDmg_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `ProgressiveDmg_MatCtx_InitFromInputs` | 1806 | `SUBROUTINE ProgressiveDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `ProgressiveDmg_MatCtx_InitDefaults` | 1821 | `SUBROUTINE ProgressiveDmg_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `ProgressiveDmg_MatAlgo_InitDefaults` | 1833 | `SUBROUTINE ProgressiveDmg_MatAlgo_InitDefaults(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
