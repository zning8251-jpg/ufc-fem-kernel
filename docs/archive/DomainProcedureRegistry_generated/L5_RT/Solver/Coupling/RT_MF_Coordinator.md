# `RT_MF_Coordinator.f90`

- **Source**: `L5_RT/Solver/Coupling/RT_MF_Coordinator.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_MF_Coordinator`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_MF_Coordinator`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_MF_Coordinator`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/Coupling/RT_MF_Coordinator.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_MF_Coordinator_Init` | 52 | `SUBROUTINE RT_MF_Coordinator_Init(desc, state, algo, err_status)` |
| FUNCTION | `i4toa` | 84 | `FUNCTION i4toa(val) RESULT(str)` |
| SUBROUTINE | `RT_MF_Coordinator_Run` | 96 | `SUBROUTINE RT_MF_Coordinator_Run(desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `RT_MF_Coordinator_Finalize` | 138 | `SUBROUTINE RT_MF_Coordinator_Finalize(state, err_status)` |
| SUBROUTINE | `RT_MF_Oneway_Loop` | 152 | `SUBROUTINE RT_MF_Oneway_Loop(desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `RT_MF_Staggered_Loop` | 185 | `SUBROUTINE RT_MF_Staggered_Loop(desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `RT_MF_PartIter_Loop` | 227 | `SUBROUTINE RT_MF_PartIter_Loop(desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `RT_MF_Monolithic_Loop` | 280 | `SUBROUTINE RT_MF_Monolithic_Loop(desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `RT_MF_Solve_SingleField` | 328 | `SUBROUTINE RT_MF_Solve_SingleField(field_id, desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `RT_MF_Exchange_Interface` | 398 | `SUBROUTINE RT_MF_Exchange_Interface(desc, state, ctx, err_status)` |
| SUBROUTINE | `RT_MF_ConvCheck_Coupling` | 447 | `SUBROUTINE RT_MF_ConvCheck_Coupling(desc, state, algo, ctx, err_status)` |
| SUBROUTINE | `compute_L2_norm_pair` | 505 | `SUBROUTINE compute_L2_norm_pair(A, B, nnode, ndof, norm)` |
| SUBROUTINE | `RT_MF_Aitken_Accelerate` | 527 | `SUBROUTINE RT_MF_Aitken_Accelerate(state, algo)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
