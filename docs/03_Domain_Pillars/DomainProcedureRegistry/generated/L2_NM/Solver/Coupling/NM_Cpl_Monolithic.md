# `NM_Cpl_Monolithic.f90`

- **Source**: `L2_NM/Solver/Coupling/NM_Cpl_Monolithic.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Cpl_Monolithic`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Cpl_Monolithic`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Cpl_Monolithic`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Coupling/NM_Cpl_Monolithic.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Coupling_Mono_Init` | 25 | `SUBROUTINE NM_Coupling_Mono_Init(coupling_type, n_fields, mono_ctx, status)` |
| SUBROUTINE | `NM_Coupling_Mono_Assemble` | 38 | `SUBROUTINE NM_Coupling_Mono_Assemble(fields, matrices, coupling_terms, mono_ctx, status)` |
| SUBROUTINE | `NM_Coupling_Mono_Direct_Solv` | 55 | `SUBROUTINE NM_Coupling_Mono_Direct_Solv(mono_matrix, rhs, solution, status)` |
| SUBROUTINE | `NM_Coupling_Mono_Iter_Solv` | 68 | `SUBROUTINE NM_Coupling_Mono_Iter_Solv(mono_matrix, rhs, solution, params, max_iter, tol, status)` |
| SUBROUTINE | `NM_Coupling_Mono_Schur_Solv` | 84 | `SUBROUTINE NM_Coupling_Mono_Schur_Solv(K11, K12, K21, K22, f1, f2, u1, u2, status)` |
| SUBROUTINE | `NM_Coupling_Mono_BlockPrec` | 100 | `SUBROUTINE NM_Coupling_Mono_BlockPrec(mono_matrix, preconditioner, params, status)` |
| SUBROUTINE | `NM_Coupling_Mono_Cleanup` | 115 | `SUBROUTINE NM_Coupling_Mono_Cleanup(mono_ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
