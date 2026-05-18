# `MD_Mat_Hyper_Contract.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_Hyper_Contract.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Hyper_Contract`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Hyper_Contract`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Hyper_Contract`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_Hyper_Contract.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Hyperfoam_MatDesc_InitFromProps` | 320 | `SUBROUTINE Hyperfoam_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Hyperfoam_MatDesc_Valid` | 358 | `FUNCTION Hyperfoam_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Hyperfoam_MatState_SyncToStateV` | 368 | `SUBROUTINE Hyperfoam_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Hyperfoam_MatState_SyncFromStateV` | 375 | `SUBROUTINE Hyperfoam_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Hyperfoam_MatState_InitFromInputs` | 387 | `SUBROUTINE Hyperfoam_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Hyperfoam_MatCtx_InitFromInputs` | 406 | `SUBROUTINE Hyperfoam_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Hyperfoam_MatCtx_InitDefaults` | 421 | `SUBROUTINE Hyperfoam_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Hyperfoam_MatAlgo_InitDefaults` | 433 | `SUBROUTINE Hyperfoam_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Mullins_MatDesc_InitFromProps` | 450 | `SUBROUTINE Mullins_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Mullins_MatDesc_Valid` | 478 | `FUNCTION Mullins_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Mullins_MatState_SyncToStateV` | 485 | `SUBROUTINE Mullins_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Mullins_MatState_SyncFromStateV` | 505 | `SUBROUTINE Mullins_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Mullins_MatState_InitFromInputs` | 531 | `SUBROUTINE Mullins_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Mullins_MatCtx_InitFromInputs` | 552 | `SUBROUTINE Mullins_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Mullins_MatCtx_InitDefaults` | 567 | `SUBROUTINE Mullins_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Mullins_MatAlgo_InitDefaults` | 579 | `SUBROUTINE Mullins_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `NeoHookean_MatDesc_InitFromProps` | 596 | `SUBROUTINE NeoHookean_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `NeoHookean_MatDesc_Valid` | 622 | `FUNCTION NeoHookean_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `NeoHookean_MatState_SyncToStateV` | 629 | `SUBROUTINE NeoHookean_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `NeoHookean_MatState_SyncFromStateV` | 636 | `SUBROUTINE NeoHookean_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `NeoHookean_MatState_InitFromInputs` | 643 | `SUBROUTINE NeoHookean_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `NeoHookean_MatCtx_InitFromInputs` | 661 | `SUBROUTINE NeoHookean_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `NeoHookean_MatCtx_InitDefaults` | 676 | `SUBROUTINE NeoHookean_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `NeoHookean_MatAlgo_InitDefaults` | 688 | `SUBROUTINE NeoHookean_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `MooneyRivlin_MatDesc_InitFromProps` | 705 | `SUBROUTINE MooneyRivlin_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MooneyRivlin_MatDesc_Valid` | 732 | `FUNCTION MooneyRivlin_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MooneyRivlin_MatState_SyncToStateV` | 739 | `SUBROUTINE MooneyRivlin_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MooneyRivlin_MatState_SyncFromStateV` | 746 | `SUBROUTINE MooneyRivlin_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MooneyRivlin_MatState_InitFromInputs` | 753 | `SUBROUTINE MooneyRivlin_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MooneyRivlin_MatCtx_InitFromInputs` | 771 | `SUBROUTINE MooneyRivlin_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `MooneyRivlin_MatCtx_InitDefaults` | 786 | `SUBROUTINE MooneyRivlin_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MooneyRivlin_MatAlgo_InitDefaults` | 798 | `SUBROUTINE MooneyRivlin_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Ogden_MatDesc_InitFromProps` | 815 | `SUBROUTINE Ogden_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Ogden_MatDesc_Valid` | 855 | `FUNCTION Ogden_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Ogden_MatState_SyncToStateV` | 871 | `SUBROUTINE Ogden_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Ogden_MatState_SyncFromStateV` | 878 | `SUBROUTINE Ogden_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Ogden_MatState_InitFromInputs` | 885 | `SUBROUTINE Ogden_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Ogden_MatCtx_InitFromInputs` | 903 | `SUBROUTINE Ogden_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Ogden_MatCtx_InitDefaults` | 918 | `SUBROUTINE Ogden_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Ogden_MatAlgo_InitDefaults` | 930 | `SUBROUTINE Ogden_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `Yeoh_MatDesc_InitFromProps` | 947 | `SUBROUTINE Yeoh_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Yeoh_MatDesc_Valid` | 975 | `FUNCTION Yeoh_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Yeoh_MatState_SyncToStateV` | 982 | `SUBROUTINE Yeoh_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Yeoh_MatState_SyncFromStateV` | 989 | `SUBROUTINE Yeoh_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Yeoh_MatState_InitFromInputs` | 996 | `SUBROUTINE Yeoh_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Yeoh_MatCtx_InitFromInputs` | 1014 | `SUBROUTINE Yeoh_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Yeoh_MatCtx_InitDefaults` | 1029 | `SUBROUTINE Yeoh_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Yeoh_MatAlgo_InitDefaults` | 1041 | `SUBROUTINE Yeoh_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `ArrudaBoyce_MatDesc_InitFromProps` | 1058 | `SUBROUTINE ArrudaBoyce_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `ArrudaBoyce_MatDesc_Valid` | 1085 | `FUNCTION ArrudaBoyce_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `ArrudaBoyce_MatState_SyncToStateV` | 1092 | `SUBROUTINE ArrudaBoyce_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `ArrudaBoyce_MatState_SyncFromStateV` | 1099 | `SUBROUTINE ArrudaBoyce_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `ArrudaBoyce_MatState_InitFromInputs` | 1106 | `SUBROUTINE ArrudaBoyce_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `ArrudaBoyce_MatCtx_InitFromInputs` | 1124 | `SUBROUTINE ArrudaBoyce_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `ArrudaBoyce_MatCtx_InitDefaults` | 1139 | `SUBROUTINE ArrudaBoyce_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `ArrudaBoyce_MatAlgo_InitDefaults` | 1151 | `SUBROUTINE ArrudaBoyce_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `DielectricElast_MatDesc_InitFromProps` | 1168 | `SUBROUTINE DielectricElast_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `DielectricElast_MatDesc_Valid` | 1195 | `FUNCTION DielectricElast_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `DielectricElast_MatState_SyncToStateV` | 1202 | `SUBROUTINE DielectricElast_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `DielectricElast_MatState_SyncFromStateV` | 1215 | `SUBROUTINE DielectricElast_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `DielectricElast_MatState_InitFromInputs` | 1228 | `SUBROUTINE DielectricElast_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `DielectricElast_MatCtx_InitFromInputs` | 1247 | `SUBROUTINE DielectricElast_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, electric_field, kstep, kinc)` |
| SUBROUTINE | `DielectricElast_MatCtx_InitDefaults` | 1263 | `SUBROUTINE DielectricElast_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `DielectricElast_MatAlgo_InitDefaults` | 1276 | `SUBROUTINE DielectricElast_MatAlgo_InitDefaults(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
