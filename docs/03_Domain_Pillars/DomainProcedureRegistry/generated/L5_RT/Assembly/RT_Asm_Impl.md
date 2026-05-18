# `RT_Asm_Impl.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Impl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_Init_Impl` | 60 | `SUBROUTINE RT_Asm_Init_Impl(desc, state, algo, ctx, n_elem, n_node, n_dof_per_node, &` |
| SUBROUTINE | `RT_Asm_BuildPattern_Impl` | 94 | `SUBROUTINE RT_Asm_BuildPattern_Impl(desc, state, algo, ctx, nEq, nnz, renum_method, status)` |
| SUBROUTINE | `RT_Asm_AssembleK_Impl` | 122 | `SUBROUTINE RT_Asm_AssembleK_Impl(desc, state, algo, ctx, elem_id, Ke, dof_map, &` |
| SUBROUTINE | `RT_Asm_AssembleM_Impl` | 194 | `SUBROUTINE RT_Asm_AssembleM_Impl(desc, state, algo, ctx, elem_id, Me, dof_map, &` |
| SUBROUTINE | `RT_Asm_AssembleF_Impl` | 251 | `SUBROUTINE RT_Asm_AssembleF_Impl(desc, state, algo, ctx, elem_id, Fe, dof_map, &` |
| SUBROUTINE | `RT_Asm_ApplyConstraints_Impl` | 319 | `SUBROUTINE RT_Asm_ApplyConstraints_Impl(desc, state, algo, ctx, dof_indices, &` |
| SUBROUTINE | `RT_Asm_ComputeResidual_Impl` | 396 | `SUBROUTINE RT_Asm_ComputeResidual_Impl(desc, state, algo, ctx, f_external, &` |
| SUBROUTINE | `RT_Asm_Finalize_Impl` | 432 | `SUBROUTINE RT_Asm_Finalize_Impl(desc, state, algo, ctx, keep_pattern, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
