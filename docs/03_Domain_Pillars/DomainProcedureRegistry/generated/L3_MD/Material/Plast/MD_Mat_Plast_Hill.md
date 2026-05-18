# `MD_Mat_Plast_Hill.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_Hill.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Hill`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Hill`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast_Hill`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_Hill.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Hill_MatDesc_InitFromProps` | 113 | `SUBROUTINE Hill_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Hill_MatDesc_Valid` | 189 | `FUNCTION Hill_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Hill_MatState_SyncToStateV` | 213 | `SUBROUTINE Hill_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Hill_MatState_SyncFromStateV` | 234 | `SUBROUTINE Hill_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Hill_MatState_InitFromInputs` | 262 | `SUBROUTINE Hill_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Hill_MatCtx_InitFromInputs` | 301 | `SUBROUTINE Hill_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Hill_MatCtx_InitDefaults` | 320 | `SUBROUTINE Hill_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Hill_MatAlgo_InitDefaults` | 338 | `SUBROUTINE Hill_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `UF_Hill_ValidateProps` | 352 | `SUBROUTINE UF_Hill_ValidateProps(props, nprops, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
