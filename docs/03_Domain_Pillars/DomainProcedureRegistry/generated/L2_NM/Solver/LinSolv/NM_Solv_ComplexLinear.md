# `NM_Solv_ComplexLinear.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_ComplexLinear.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_ComplexLinear`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_ComplexLinear`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_ComplexLinear`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_ComplexLinear.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_ComplexLinSolv_Cfg` (lines 23–27)

```fortran
  TYPE, PUBLIC :: NM_ComplexLinSolv_Cfg
    INTEGER(i4) :: mtype     = NM_COMPLEX_MTYPE_HERMITIAN
    REAL(wp)    :: refactor_tol = 0.01_wp   ! |Δω/ω| threshold for refactor
    LOGICAL     :: verbose   = .FALSE.
  END TYPE NM_ComplexLinSolv_Cfg
```

### `NM_ComplexLinSolv_Ctx` (lines 29–37)

```fortran
  TYPE, PUBLIC :: NM_ComplexLinSolv_Ctx
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_factorized  = .FALSE.
    INTEGER(i4) :: n           = 0_i4
    INTEGER(i4) :: nnz         = 0_i4
    REAL(wp)    :: last_omega   = -1.0_wp
    TYPE(NM_ComplexLinSolv_Cfg) :: cfg
    ! TODO: PARDISO handle (pt, iparm, dparm) when MKL linked
  END TYPE NM_ComplexLinSolv_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_ComplexLinearSolver_Init` | 46 | `SUBROUTINE NM_ComplexLinearSolver_Init(ctx, n, nnz, cfg, status)` |
| SUBROUTINE | `NM_ComplexLinearSolver_Factorize` | 61 | `SUBROUTINE NM_ComplexLinearSolver_Factorize(ctx, K_real, K_imag, ia, ja, omega, status)` |
| SUBROUTINE | `NM_ComplexLinearSolver_Solve` | 76 | `SUBROUTINE NM_ComplexLinearSolver_Solve(ctx, K_real, K_imag, ia, ja, &` |
| SUBROUTINE | `NM_ComplexLinearSolver_Finalize` | 104 | `SUBROUTINE NM_ComplexLinearSolver_Finalize(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
