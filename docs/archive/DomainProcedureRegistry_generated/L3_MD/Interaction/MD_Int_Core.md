# `MD_Int_Core.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Int_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Int_CoreInit` | 41 | `SUBROUTINE MD_Int_CoreInit(desc, state, status)` |
| SUBROUTINE | `MD_Int_CoreFinalize` | 64 | `SUBROUTINE MD_Int_CoreFinalize(desc, state, status)` |
| SUBROUTINE | `MD_Int_AddSurface` | 82 | `SUBROUTINE MD_Int_AddSurface(desc, id, name, surface_type, status)` |
| SUBROUTINE | `MD_Int_AddPairEntry` | 114 | `SUBROUTINE MD_Int_AddPairEntry(desc, pair_id, master_id, slave_id, status)` |
| SUBROUTINE | `MD_Int_SetFriction` | 146 | `SUBROUTINE MD_Int_SetFriction(desc, pair_id, mu, status)` |
| SUBROUTINE | `MD_Int_GetPairEntry` | 172 | `SUBROUTINE MD_Int_GetPairEntry(desc, idx, pair, status)` |
| FUNCTION | `MD_Int_GetNPairs` | 194 | `FUNCTION MD_Int_GetNPairs(desc) RESULT(n)` |
| SUBROUTINE | `MD_Int_Validate` | 206 | `SUBROUTINE MD_Int_Validate(desc, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
