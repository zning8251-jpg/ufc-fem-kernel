# `RT_Solv_Brg.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Solv_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Brg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_ConvertCSR_ToNumCore` | 89 | `subroutine RT_ConvertCSR_ToNumCore(rt_csr, uf_csr, status)` |
| SUBROUTINE | `RT_ConvertCSR_FromNumCore` | 124 | `subroutine RT_ConvertCSR_FromNumCore(uf_csr, rt_csr, status)` |
| SUBROUTINE | `RT_UF_CSR_Free` | 158 | `subroutine RT_UF_CSR_Free(uf_csr, status)` |
| SUBROUTINE | `RT_CSR_An_FromNumCore` | 169 | `subroutine RT_CSR_An_FromNumCore(K_csr, bandwidth, profile, avg_row_width, status)` |
| SUBROUTINE | `RT_Precond_Create` | 205 | `subroutine RT_Precond_Create(K_csr, precond_type, precond, status)` |
| SUBROUTINE | `RT_Precond_Create_FromCfg` | 256 | `subroutine RT_Precond_Create_FromCfg(K_csr, cfg, precond, status)` |
| SUBROUTINE | `RT_DestroyPreconditioner` | 288 | `subroutine RT_DestroyPreconditioner(precond, status)` |
| SUBROUTINE | `RT_LinearSolver_Iterative` | 305 | `subroutine RT_LinearSolver_Iterative(K_csr, b, x, cfg, state, status)` |
| SUBROUTINE | `RT_Cfg_To_UF_LinSolParams` | 382 | `subroutine RT_Cfg_To_UF_LinSolParams(cfg, params_uf)` |
| SUBROUTINE | `RT_UF_LinSolResult_To_State` | 432 | `subroutine RT_UF_LinSolResult_To_State(result_uf, state)` |
| SUBROUTINE | `RT_Cfg_To_UF_NLParams` | 444 | `subroutine RT_Cfg_To_UF_NLParams(cfg, params_uf)` |
| SUBROUTINE | `RT_UF_NLResult_To_State` | 481 | `subroutine RT_UF_NLResult_To_State(result_uf, state)` |
| SUBROUTINE | `RT_LinearSolver_Direct` | 497 | `subroutine RT_LinearSolver_Direct(K_csr, b, x, cfg, state, status)` |
| SUBROUTINE | `RT_LinearSolver_Unified` | 528 | `subroutine RT_LinearSolver_Unified(K_csr, b, x, cfg, state, status)` |
| SUBROUTINE | `RT_LinearSolver_AGMG` | 589 | `subroutine RT_LinearSolver_AGMG(K_csr, b, x, cfg, state, status)` |
| SUBROUTINE | `RT_LinearSolver_SparsePak` | 622 | `subroutine RT_LinearSolver_SparsePak(K_csr, b, x, cfg, state, status)` |
| SUBROUTINE | `RT_Li_Sp_Reuse` | 655 | `subroutine RT_Li_Sp_Reuse(K_csr, b, x, handle, is_first, cfg, state, status)` |
| SUBROUTINE | `RT_Solv_Bridge_Unified` | 698 | `subroutine RT_Solv_Bridge_Unified(K_csr, R, U, solver_type, solver_params, &` |
| SUBROUTINE | `RT_Solv_Bridge_Opt` | 813 | `subroutine RT_Solv_Bridge_Opt(K_csr, solver_type, optimization_flags, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
