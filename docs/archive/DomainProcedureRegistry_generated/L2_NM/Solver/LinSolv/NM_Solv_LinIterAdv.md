# `NM_Solv_LinIterAdv.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinIterAdv.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinIterAdv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinIterAdv`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinIterAdv`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinIterAdv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_LinSolv_Iter_Params` (lines 35–43)

```fortran
  TYPE, PUBLIC :: NM_LinSolv_Iter_Params
    INTEGER(i4) :: max_iter = 1000_i4
    REAL(wp) :: tolerance = 1.0e-8_wp
    REAL(wp) :: abs_tolerance = 1.0e-10_wp
    LOGICAL :: use_preconditioner = .FALSE.
    REAL(wp) :: omega = 1.0_wp          ! Richardson relaxation parameter
    LOGICAL :: verbose = .FALSE.
    INTEGER(i4) :: print_freq = 10_i4
  END TYPE NM_LinSolv_Iter_Params
```

### `NM_LinSolv_Iter_State` (lines 48–55)

```fortran
  TYPE, PUBLIC :: NM_LinSolv_Iter_State
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: iter = 0_i4
    REAL(wp) :: residual_norm = 0.0_wp
    REAL(wp) :: residual_norm0 = 0.0_wp
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: func_evals = 0_i4
  END TYPE NM_LinSolv_Iter_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_CGS_Solv` | 64 | `SUBROUTINE NM_CGS_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)` |
| SUBROUTINE | `MatVec_proc` | 78 | `SUBROUTINE MatVec_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 84 | `SUBROUTINE Precond_proc(r, z, status)` |
| SUBROUTINE | `NM_MinRes_Solv` | 192 | `SUBROUTINE NM_MinRes_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)` |
| SUBROUTINE | `MatVec_proc` | 205 | `SUBROUTINE MatVec_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 211 | `SUBROUTINE Precond_proc(r, z, status)` |
| SUBROUTINE | `NM_QMR_Solv` | 227 | `SUBROUTINE NM_QMR_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)` |
| SUBROUTINE | `MatVec_proc` | 242 | `SUBROUTINE MatVec_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 248 | `SUBROUTINE Precond_proc(r, z, status)` |
| SUBROUTINE | `NM_Richardson_Solv` | 372 | `SUBROUTINE NM_Richardson_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)` |
| SUBROUTINE | `MatVec_proc` | 385 | `SUBROUTINE MatVec_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 391 | `SUBROUTINE Precond_proc(r, z, status)` |
| SUBROUTINE | `NM_SymmLQ_Solv` | 475 | `SUBROUTINE NM_SymmLQ_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)` |
| SUBROUTINE | `MatVec_proc` | 487 | `SUBROUTINE MatVec_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 493 | `SUBROUTINE Precond_proc(r, z, status)` |
| SUBROUTINE | `NM_TFQMR_Solv` | 509 | `SUBROUTINE NM_TFQMR_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)` |
| SUBROUTINE | `MatVec_proc` | 522 | `SUBROUTINE MatVec_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 528 | `SUBROUTINE Precond_proc(r, z, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 77–90 | `INTERFACE` |
| 204–217 | `INTERFACE` |
| 241–254 | `INTERFACE` |
| 384–397 | `INTERFACE` |
| 486–499 | `INTERFACE` |
| 521–534 | `INTERFACE` |
