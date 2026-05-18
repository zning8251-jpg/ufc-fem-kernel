# `NM_TimeInt_HHT.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_HHT.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_TimeInt_HHT`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_HHT`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_HHT`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_HHT.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_TimeInt_HHT_Integrate` | 26 | `SUBROUTINE NM_TimeInt_HHT_Integrate(integrator, M, C, K_tan, F_ext, F_int, &` |
| SUBROUTINE | `NM_TimeInt_HHT_Predict` | 128 | `SUBROUTINE NM_TimeInt_HHT_Predict(integrator, u_n, v_n)` |
| SUBROUTINE | `NM_TimeInt_HHT_Correct` | 163 | `SUBROUTINE NM_TimeInt_HHT_Correct(integrator, a_np1, u_np1, v_np1)` |
| SUBROUTINE | `NM_TimeInt_HHT_Equilibrium_Iteration` | 186 | `SUBROUTINE NM_TimeInt_HHT_Equilibrium_Iteration(integrator, M, C, K_tan, &` |
| SUBROUTINE | `NM_TimeInt_HHT_Compute_Effective_Force` | 258 | `SUBROUTINE NM_TimeInt_HHT_Compute_Effective_Force(integrator, F_int, u, R_eff)` |
| SUBROUTINE | `NM_TimeInt_HHT_Update_History` | 280 | `SUBROUTINE NM_TimeInt_HHT_Update_History(integrator, u_new, v_new, a_new, R_new)` |
| SUBROUTINE | `Build_HHT_Effective_Stiffness` | 296 | `SUBROUTINE Build_HHT_Effective_Stiffness(integrator, M, C, K_tan, K_eff)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
