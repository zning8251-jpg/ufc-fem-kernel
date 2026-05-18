# `RT_Elem_Core.f90`

- **Source**: `L5_RT/Element/RT_Elem_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `elem_callback_iface` | 29 | `SUBROUTINE elem_callback_iface(e, status)` |
| SUBROUTINE | `RT_Element_Core_Init` | 38 | `SUBROUTINE RT_Element_Core_Init(desc, state, ctx, status)` |
| SUBROUTINE | `RT_Element_Core_Finalize` | 58 | `SUBROUTINE RT_Element_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `RT_Element_Loop_Ke` | 74 | `SUBROUTINE RT_Element_Loop_Ke(desc, ctx, elem_compute, Ke_callback, status)` |
| SUBROUTINE | `RT_Element_Loop_Fe` | 102 | `SUBROUTINE RT_Element_Loop_Fe(desc, ctx, elem_compute_F, Fe_callback, status)` |
| SUBROUTINE | `RT_Element_Loop_Mass` | 130 | `SUBROUTINE RT_Element_Loop_Mass(desc, ctx, elem_compute_M, Me_callback, status)` |
| SUBROUTINE | `RT_Element_Loop_Stress` | 158 | `SUBROUTINE RT_Element_Loop_Stress(desc, ctx, compute_stress, status)` |
| SUBROUTINE | `RT_Element_Loop_Internal_Force` | 180 | `SUBROUTINE RT_Element_Loop_Internal_Force(desc, ctx, compute_fint, &` |
| SUBROUTINE | `RT_Element_Get_DOF_Map` | 209 | `SUBROUTINE RT_Element_Get_DOF_Map(desc, ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
