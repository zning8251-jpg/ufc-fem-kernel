# `MD_Mat_Creep_Gurson.f90`

- **Source**: `L3_MD/Material/Creep/MD_Mat_Creep_Gurson.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Creep_Gurson`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Creep_Gurson`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Creep_Gurson`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Creep`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Creep/MD_Mat_Creep_Gurson.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Gurson_MatDesc_InitFromProps` | 108 | `SUBROUTINE Gurson_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Gurson_MatDesc_Valid` | 179 | `FUNCTION Gurson_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Gurson_MatState_SyncToStateV` | 204 | `SUBROUTINE Gurson_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Gurson_MatState_SyncFromStateV` | 242 | `SUBROUTINE Gurson_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Gurson_MatState_InitFromInputs` | 288 | `SUBROUTINE Gurson_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `Gurson_MatCtx_InitFromInputs` | 324 | `SUBROUTINE Gurson_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Gurson_MatCtx_InitDefaults` | 343 | `SUBROUTINE Gurson_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Gurson_MatAlgo_InitDefaults` | 361 | `SUBROUTINE Gurson_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `UF_Gurson_ValidateProps` | 375 | `SUBROUTINE UF_Gurson_ValidateProps(props, nprops, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
