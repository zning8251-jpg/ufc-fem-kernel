# `NM_TimeInt_Core.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_TimeInt_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_Core`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_TimeInt_Core_Init` | 28 | `SUBROUTINE NM_TimeInt_Core_Init(desc, state, algo, status)` |
| SUBROUTINE | `NM_TimeInt_Core_Finalize` | 41 | `SUBROUTINE NM_TimeInt_Core_Finalize(state, status)` |
| SUBROUTINE | `NM_TimeInt_Newmark_Predict` | 60 | `SUBROUTINE NM_TimeInt_Newmark_Predict(desc, state, algo, status)` |
| SUBROUTINE | `NM_TimeInt_Newmark_Correct` | 91 | `SUBROUTINE NM_TimeInt_Newmark_Correct(desc, state, algo, status)` |
| SUBROUTINE | `NM_TimeInt_Central_Diff` | 114 | `SUBROUTINE NM_TimeInt_Central_Diff(desc, state, algo, M_diag, F, status)` |
| SUBROUTINE | `NM_TimeInt_HHT_Alpha` | 146 | `SUBROUTINE NM_TimeInt_HHT_Alpha(desc, state, algo, status)` |
| SUBROUTINE | `NM_TimeInt_Compute_Stable_DT` | 174 | `SUBROUTINE NM_TimeInt_Compute_Stable_DT(desc, algo, omega_max, dt_crit, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
