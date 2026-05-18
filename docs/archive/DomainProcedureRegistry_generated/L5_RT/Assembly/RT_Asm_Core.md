# `RT_Asm_Core.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_Core_Init` | 66 | `SUBROUTINE RT_Asm_Core_Init(desc, algo, state, ctx, status)` |
| SUBROUTINE | `RT_Asm_Core_Zero_System` | 90 | `SUBROUTINE RT_Asm_Core_Zero_System(state, status)` |
| SUBROUTINE | `RT_Asm_Core_Scatter_Ke` | 112 | `SUBROUTINE RT_Asm_Core_Scatter_Ke(state, Ke, dof_map, ndof_e, status)` |
| SUBROUTINE | `RT_Asm_Core_Scatter_Fe` | 151 | `SUBROUTINE RT_Asm_Core_Scatter_Fe(state, Fe, dof_map, ndof_e, status)` |
| SUBROUTINE | `RT_Asm_Core_Scatter_Me` | 181 | `SUBROUTINE RT_Asm_Core_Scatter_Me(state, Me, dof_map, ndof_e, status)` |
| SUBROUTINE | `RT_Asm_Core_Scatter_Ce` | 214 | `SUBROUTINE RT_Asm_Core_Scatter_Ce(state, Ce, dof_map, ndof_e, status)` |
| SUBROUTINE | `RT_Asm_Core_Apply_BC` | 247 | `SUBROUTINE RT_Asm_Core_Apply_BC(state, ctx, n_bc, bc_dofs, bc_values, &` |
| SUBROUTINE | `RT_Asm_Core_Compute_Residual` | 301 | `SUBROUTINE RT_Asm_Core_Compute_Residual(state, ctx, u, R, rnorm, status)` |
| SUBROUTINE | `RT_Asm_Core_Finalize` | 342 | `SUBROUTINE RT_Asm_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `RT_Asm_Core_Build_DofMap` | 358 | `SUBROUTINE RT_Asm_Core_Build_DofMap(desc, ctx, connectivity, &` |
| SUBROUTINE | `RT_Asm_Core_Assemble_K` | 382 | `SUBROUTINE RT_Asm_Core_Assemble_K(desc, algo, state, ctx, status)` |
| SUBROUTINE | `RT_Asm_Core_Assemble_F` | 394 | `SUBROUTINE RT_Asm_Core_Assemble_F(desc, algo, state, ctx, status)` |
| SUBROUTINE | `RT_Asm_Core_Assemble_M` | 406 | `SUBROUTINE RT_Asm_Core_Assemble_M(desc, algo, state, ctx, rho, status)` |
| SUBROUTINE | `RT_Asm_Core_Apply_Constraints` | 419 | `SUBROUTINE RT_Asm_Core_Apply_Constraints(state, ctx, status)` |
| SUBROUTINE | `RT_Asm_Core_Apply_MPC` | 436 | `SUBROUTINE RT_Asm_Core_Apply_MPC(state, n_mpc, slave_dofs, master_dofs, &` |
| SUBROUTINE | `RT_Asm_Core_Apply_Contact` | 494 | `SUBROUTINE RT_Asm_Core_Apply_Contact(state, Kc, Fc, dof_map_c, ndof_c, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
