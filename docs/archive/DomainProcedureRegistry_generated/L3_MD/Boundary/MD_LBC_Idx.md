# `MD_LBC_Idx.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Idx.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_LBC_Idx`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Idx`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC`
- **第四段角色（四段式）**: `_Idx`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Idx.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_LoadBC_Idx_Bind` | 31 | `SUBROUTINE MD_LoadBC_Idx_Bind(dom)` |
| SUBROUTINE | `MD_LoadBC_Idx_Reset` | 36 | `SUBROUTINE MD_LoadBC_Idx_Reset()` |
| SUBROUTINE | `MD_LoadBC_GetLoadsForStep_Idx` | 45 | `SUBROUTINE MD_LoadBC_GetLoadsForStep_Idx(step_idx, arg, status)` |
| SUBROUTINE | `MD_LoadBC_GetBCsForStep_Idx` | 94 | `SUBROUTINE MD_LoadBC_GetBCsForStep_Idx(step_idx, arg, status)` |
| SUBROUTINE | `MD_LoadBC_GetBC_Idx` | 143 | `SUBROUTINE MD_LoadBC_GetBC_Idx(bc_idx, arg, status)` |
| SUBROUTINE | `MD_LoadBC_GetLoad_Idx` | 157 | `SUBROUTINE MD_LoadBC_GetLoad_Idx(load_idx, arg, status)` |
| SUBROUTINE | `MD_LoadBC_GetLoadByName_Idx` | 171 | `SUBROUTINE MD_LoadBC_GetLoadByName_Idx(name, arg, status)` |
| SUBROUTINE | `MD_LoadBC_GetBCByName_Idx` | 187 | `SUBROUTINE MD_LoadBC_GetBCByName_Idx(name, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
