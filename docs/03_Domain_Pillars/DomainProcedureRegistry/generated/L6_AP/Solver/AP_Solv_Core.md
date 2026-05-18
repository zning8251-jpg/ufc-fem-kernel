# `AP_Solv_Core.f90`

- **Source**: `L6_AP/Solver/AP_Solv_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Solv_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Solv_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Solv`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Solver/AP_Solv_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Solver_Core_Init` | 30 | `SUBROUTINE AP_Solver_Core_Init(desc, algo, status)` |
| SUBROUTINE | `AP_Solver_Core_Finalize` | 39 | `SUBROUTINE AP_Solver_Core_Finalize(desc, algo, status)` |
| SUBROUTINE | `AP_Solver_Configure` | 51 | `SUBROUTINE AP_Solver_Configure(desc, algo, solver_type, tol, max_iter, status)` |
| FUNCTION | `AP_Solver_Get_Type` | 78 | `FUNCTION AP_Solver_Get_Type(algo) RESULT(t)` |
| SUBROUTINE | `AP_Solver_Run_Step` | 87 | `SUBROUTINE AP_Solver_Run_Step(desc, algo, step_id, status)` |
| SUBROUTINE | `AP_Solver_Run_All_Steps` | 105 | `SUBROUTINE AP_Solver_Run_All_Steps(desc, algo, n_steps, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
