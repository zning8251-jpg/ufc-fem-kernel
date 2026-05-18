# `MD_Mat_Plast_J2.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_J2.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Plast_J2`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_J2`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast_J2`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_J2.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `VM_MatDesc_InitFromProps` | 105 | `SUBROUTINE VM_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `VM_MatDesc_Valid` | 151 | `FUNCTION VM_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `VM_MatState_SyncToStateV` | 191 | `SUBROUTINE VM_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `VM_MatState_SyncFromStateV` | 214 | `SUBROUTINE VM_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `VM_MatState_InitFromInputs` | 244 | `SUBROUTINE VM_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `VM_MatCtx_InitFromInputs` | 283 | `SUBROUTINE VM_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `VM_MatCtx_InitDefaults` | 302 | `SUBROUTINE VM_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `VM_MatAlgo_InitDefaults` | 320 | `SUBROUTINE VM_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `UF_VonMises_ValidateProps` | 338 | `SUBROUTINE UF_VonMises_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_VonMises_GetStatistics` | 385 | `SUBROUTINE UF_VonMises_GetStatistics(props, nprops, stats, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
