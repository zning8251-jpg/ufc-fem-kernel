# `NM_Solv_LinDirCholesky.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinDirCholesky.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinDirCholesky`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinDirCholesky`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinDirCholesky`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinDirCholesky.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `i4_to_str` | 46 | `FUNCTION i4_to_str(i) RESULT(str)` |
| SUBROUTINE | `NM_Cholesky_Decompose_InPlace` | 52 | `SUBROUTINE NM_Cholesky_Decompose_InPlace(A, status)` |
| SUBROUTINE | `NM_Cholesky_Banded` | 100 | `SUBROUTINE NM_Cholesky_Banded(A_band, kd, L_band, status)` |
| SUBROUTINE | `NM_Cholesky_Block` | 158 | `SUBROUTINE NM_Cholesky_Block(A, L, block_size, status)` |
| SUBROUTINE | `NM_Cholesky_Check_SPD` | 208 | `SUBROUTINE NM_Cholesky_Check_SPD(A, is_spd, status)` |
| SUBROUTINE | `NM_Cholesky_Decompose` | 255 | `SUBROUTINE NM_Cholesky_Decompose(A, L, status)` |
| SUBROUTINE | `NM_Cholesky_Downdate` | 319 | `SUBROUTINE NM_Cholesky_Downdate(L, v, status)` |
| SUBROUTINE | `NM_Cholesky_GetStatistics` | 362 | `SUBROUTINE NM_Cholesky_GetStatistics(L, stats, status)` |
| SUBROUTINE | `NM_Cholesky_Invert` | 396 | `SUBROUTINE NM_Cholesky_Invert(L, Ainv, status)` |
| SUBROUTINE | `NM_Cholesky_LogDet` | 433 | `SUBROUTINE NM_Cholesky_LogDet(L, logdet, status)` |
| SUBROUTINE | `NM_Cholesky_Modified` | 464 | `SUBROUTINE NM_Cholesky_Modified(A, L, D, status)` |
| SUBROUTINE | `NM_Cholesky_Rank1Update` | 532 | `SUBROUTINE NM_Cholesky_Rank1Update(L, v, status)` |
| SUBROUTINE | `NM_Cholesky_Solv` | 578 | `SUBROUTINE NM_Cholesky_Solv(L, b, x, status)` |
| SUBROUTINE | `Solv_Lower_Block` | 627 | `SUBROUTINE Solv_Lower_Block(L, B, X)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
