# `RT_Cont_Ctrl.f90`

- **Source**: `L5_RT/Contact/RT_Cont_Ctrl.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Cont_Ctrl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_Ctrl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont`
- **第四段角色（四段式）**: `_Ctrl`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_Ctrl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Cont_Detect_Pairs` | 78 | `SUBROUTINE RT_Cont_Detect_Pairs(node_coords, node_displacements, &` |
| SUBROUTINE | `RT_Cont_Comp_Forces` | 131 | `SUBROUTINE RT_Cont_Comp_Forces(cont_algo, cont_state, gap, normal, &` |
| SUBROUTINE | `RT_Cont_Assem_Global` | 178 | `SUBROUTINE RT_Cont_Assem_Global(force, K_contact, slave_dof, master_dof, &` |
| SUBROUTINE | `RT_Cont_Chk_Conv` | 214 | `SUBROUTINE RT_Cont_Chk_Conv(force_residual, gap_residual, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
