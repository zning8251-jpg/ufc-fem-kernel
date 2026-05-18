# `RT_Solv_Core.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Solv_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Solv_Core_Init` | 52 | `SUBROUTINE RT_Solv_Core_Init(cfg, sol_state, status)` |
| SUBROUTINE | `RT_Solv_Core_Solve_Linear` | 92 | `SUBROUTINE RT_Solv_Core_Solve_Linear(cfg, sol_state, n_dof, &` |
| SUBROUTINE | `RT_Solv_Core_Solve_Nonlinear` | 183 | `SUBROUTINE RT_Solv_Core_Solve_Nonlinear(cfg, sol_state, &` |
| SUBROUTINE | `RT_Solv_Core_Check_Convergence` | 272 | `SUBROUTINE RT_Solv_Core_Check_Convergence(cfg, sol_state, &` |
| SUBROUTINE | `RT_Solv_Core_Apply_Increment` | 325 | `SUBROUTINE RT_Solv_Core_Apply_Increment(n_dof, u, du, alpha, status)` |
| SUBROUTINE | `RT_Solv_Core_Cutback` | 347 | `SUBROUTINE RT_Solv_Core_Cutback(sol_state, cutback_factor, &` |
| SUBROUTINE | `RT_Solv_Core_Finalize` | 393 | `SUBROUTINE RT_Solv_Core_Finalize(sol_state, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
