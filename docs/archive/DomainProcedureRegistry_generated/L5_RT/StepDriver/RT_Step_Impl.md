# `RT_Step_Impl.f90`

- **Source**: `L5_RT/StepDriver/RT_Step_Impl.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_Step_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Step_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Step_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `StepDriver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/StepDriver/RT_Step_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Dyn_Clamp_dt_cfl_csr` | 39 | `SUBROUTINE RT_Dyn_Clamp_dt_cfl_csr(dt_in, K_csr, M_diag, nDOF, cfl_safety, dt_out, omega_max_out)` |
| FUNCTION | `RT_Dyn_Estimate_omega_max_csr_lumped` | 71 | `FUNCTION RT_Dyn_Estimate_omega_max_csr_lumped(K_csr, M_diag, nDOF) RESULT(omega_max)` |
| FUNCTION | `RT_Dyn_CFL_dt_central_diff` | 96 | `FUNCTION RT_Dyn_CFL_dt_central_diff(omega_max, cfl_safety) RESULT(dt_cfl)` |
| SUBROUTINE | `RT_DynExpl_Run` | 111 | `SUBROUTINE RT_DynExpl_Run(dyn_params, status, u, n_dof, model, step, state, dofMap, &` |
| SUBROUTINE | `RT_DynImpl_Run` | 207 | `SUBROUTINE RT_DynImpl_Run(dyn_params, status, u, n_dof, model, step, state, dofMap)` |
| SUBROUTINE | `RT_DynImpl_CSRToDense` | 392 | `SUBROUTINE RT_DynImpl_CSRToDense(K_csr, nDOF, K_dense, ok)` |
| SUBROUTINE | `RT_DynImpl_MatVec` | 415 | `SUBROUTINE RT_DynImpl_MatVec(n, A, x, y)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
