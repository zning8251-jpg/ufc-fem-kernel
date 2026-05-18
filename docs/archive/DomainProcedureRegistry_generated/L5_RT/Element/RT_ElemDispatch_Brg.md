# `RT_ElemDispatch_Brg.f90`

- **Source**: `L5_RT/Element/RT_ElemDispatch_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_ElemDispatch_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_ElemDispatch_Brg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_ElemDispatch`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_ElemDispatch_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Elem_Brg_ComputeKe` | 34 | `SUBROUTINE RT_Elem_Brg_ComputeKe(elem_type, ke_in, ke_out, status)` |
| SUBROUTINE | `RT_Elem_Brg_ComputeFe` | 74 | `SUBROUTINE RT_Elem_Brg_ComputeFe(elem_type, fe_in, fe_out, status)` |
| SUBROUTINE | `RT_Elem_Brg_ComputeMe` | 111 | `SUBROUTINE RT_Elem_Brg_ComputeMe(elem_type, me_in, me_out, status)` |
| SUBROUTINE | `RT_Elem_Brg_ComputeCe` | 146 | `SUBROUTINE RT_Elem_Brg_ComputeCe(elem_type, coords, alpha, beta, Ce, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
