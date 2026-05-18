# `RT_Cont_Brg.f90`

- **Source**: `L5_RT/Contact/RT_Cont_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Cont_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_Brg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Contact_Brg_FromL3` | 27 | `SUBROUTINE RT_Contact_Brg_FromL3(n_pairs, n_surfaces, desc, status)` |
| SUBROUTINE | `RT_Contact_Brg_ToL4` | 49 | `SUBROUTINE RT_Contact_Brg_ToL4(desc, algo, ctx, status)` |
| SUBROUTINE | `RT_Contact_Brg_WriteBack` | 82 | `SUBROUTINE RT_Contact_Brg_WriteBack(state, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
