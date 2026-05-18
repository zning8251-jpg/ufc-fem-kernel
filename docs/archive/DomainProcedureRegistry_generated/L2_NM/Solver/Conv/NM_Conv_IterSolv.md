# `NM_Conv_IterSolv.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_IterSolv.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Conv_IterSolv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_IterSolv`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv_IterSolv`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_IterSolv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Iter_Solv_Params_Ctrl` (lines 42–45)

```fortran
    TYPE, PUBLIC :: Iter_Solv_Params_Ctrl
    INTEGER(i4) :: solver_type = NM_SOLV_METHOD_BICGSTAB
    INTEGER(i4) :: max_iterations = 1000_i4
  END TYPE Iter_Solv_Params_Ctrl
```

### `Iter_Solv_Params_Tol` (lines 47–50)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Params_Tol
    REAL(DP) :: tolerance = 1.0E-6_DP
    REAL(DP) :: restart_tolerance = 1.0E-4_DP
  END TYPE Iter_Solv_Params_Tol
```

### `Iter_Solv_Params_Algo` (lines 52–56)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Params_Algo
    INTEGER(i4) :: restart_frequency = 30_i4  !< GMRES restart
    INTEGER(i4) :: bicgstab_l = 2_i4          !< BiCGSTAB(l)
    INTEGER(i4) :: idr_s = 4_i4               !< IDR(s)
  END TYPE Iter_Solv_Params_Algo
```

### `Iter_Solv_Params_Flags` (lines 58–61)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Params_Flags
    LOGICAL :: use_preconditioner = .TRUE.
    LOGICAL :: verbose = .FALSE.
  END TYPE Iter_Solv_Params_Flags
```

### `Iter_Solv_Params` (lines 63–68)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Params
    TYPE(Iter_Solv_Params_Ctrl)  :: ctrl
    TYPE(Iter_Solv_Params_Tol)   :: tol
    TYPE(Iter_Solv_Params_Algo)  :: algo
    TYPE(Iter_Solv_Params_Flags) :: flags
  END TYPE Iter_Solv_Params
```

### `Iter_Solv_State_Iter` (lines 71–73)

```fortran
    TYPE, PUBLIC :: Iter_Solv_State_Iter
    INTEGER(i4) :: iteration = 0_i4
  END TYPE Iter_Solv_State_Iter
```

### `Iter_Solv_State_Residual` (lines 75–79)

```fortran
  TYPE, PUBLIC :: Iter_Solv_State_Residual
    REAL(DP) :: residual_norm = ZERO
    REAL(DP) :: residual_norm_init = ZERO
    REAL(DP) :: relative_residual = ZERO
  END TYPE Iter_Solv_State_Residual
```

### `Iter_Solv_State_Flags` (lines 81–83)

```fortran
  TYPE, PUBLIC :: Iter_Solv_State_Flags
    LOGICAL :: converged = .FALSE.
  END TYPE Iter_Solv_State_Flags
```

### `Iter_Solv_State_Stats` (lines 85–88)

```fortran
  TYPE, PUBLIC :: Iter_Solv_State_Stats
    INTEGER(i4) :: n_restarts = 0_i4
    REAL(DP) :: solve_time = ZERO
  END TYPE Iter_Solv_State_Stats
```

### `Iter_Solv_State` (lines 90–95)

```fortran
  TYPE, PUBLIC :: Iter_Solv_State
    TYPE(Iter_Solv_State_Iter)     :: iter
    TYPE(Iter_Solv_State_Residual) :: residual
    TYPE(Iter_Solv_State_Flags)    :: flags
    TYPE(Iter_Solv_State_Stats)    :: stats
  END TYPE Iter_Solv_State
```

### `Iter_Solv_Result_Sol` (lines 98–100)

```fortran
    TYPE, PUBLIC :: Iter_Solv_Result_Sol
    REAL(DP), ALLOCATABLE :: x(:)            !< solution
  END TYPE Iter_Solv_Result_Sol
```

### `Iter_Solv_Result_Residual` (lines 102–104)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Result_Residual
    REAL(DP) :: residual_norm = ZERO         !< final residual
  END TYPE Iter_Solv_Result_Residual
```

### `Iter_Solv_Result_Stats` (lines 106–109)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4       !< iter count
    INTEGER(i4) :: n_matvecs = 0_i4          !< matvec count
  END TYPE Iter_Solv_Result_Stats
```

### `Iter_Solv_Result_Flags` (lines 111–113)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Result_Flags
    LOGICAL :: converged = .FALSE.           !< converged
  END TYPE Iter_Solv_Result_Flags
```

### `Iter_Solv_Result_Meta` (lines 115–117)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Result_Meta
    CHARACTER(LEN=128) :: message = ""       !< message
  END TYPE Iter_Solv_Result_Meta
```

### `Iter_Solv_Result` (lines 119–125)

```fortran
  TYPE, PUBLIC :: Iter_Solv_Result
    TYPE(Iter_Solv_Result_Sol)      :: sol
    TYPE(Iter_Solv_Result_Residual) :: residual
    TYPE(Iter_Solv_Result_Stats)    :: stats
    TYPE(Iter_Solv_Result_Flags)    :: flags
    TYPE(Iter_Solv_Result_Meta)     :: meta
  END TYPE Iter_Solv_Result
```

### `GMRES_Workspace` (lines 128–133)

```fortran
  TYPE, PUBLIC :: GMRES_Workspace
    REAL(DP), ALLOCATABLE :: V(:,:)          !< Krylov vecs
    REAL(DP), ALLOCATABLE :: H(:,:)          !< Hessenberg
    REAL(DP), ALLOCATABLE :: g(:)            !< RHS
    REAL(DP), ALLOCATABLE :: cs(:), sn(:)    !< Givens
  END TYPE GMRES_Workspace
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Apply_Givens_Rotation` | 154 | `SUBROUTINE Apply_Givens_Rotation(c, s, x1, x2)` |
| SUBROUTINE | `Calc_Givens_Rotation` | 166 | `SUBROUTINE Calc_Givens_Rotation(a, b, c, s)` |
| SUBROUTINE | `NM_BiCGSTAB_L_Solv` | 187 | `SUBROUTINE NM_BiCGSTAB_L_Solv(A, b, x, params, precond, result, status)` |
| SUBROUTINE | `NM_BiCGSTAB_Solv` | 201 | `SUBROUTINE NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)` |
| FUNCTION | `NM_Conv_Check` | 318 | `FUNCTION NM_Conv_Check(residual_norm, b_norm, tolerance) RESULT(converged)` |
| SUBROUTINE | `NM_GMRES_M_Solv` | 331 | `SUBROUTINE NM_GMRES_M_Solv(A, b, x, params, precond, result, status)` |
| SUBROUTINE | `NM_GMRES_Solv` | 465 | `SUBROUTINE NM_GMRES_Solv(A, b, x, params, precond, result, status)` |
| SUBROUTINE | `NM_IDR_Solv` | 483 | `SUBROUTINE NM_IDR_Solv(A, b, x, params, precond, result, status)` |
| SUBROUTINE | `NM_Iter_Solv` | 497 | `SUBROUTINE NM_Iter_Solv(A, b, x, params, precond, result, status)` |
| FUNCTION | `NM_Residual` | 526 | `FUNCTION NM_Residual(A, x, b) RESULT(r)` |
| SUBROUTINE | `NM_TFQMR_Solv` | 534 | `SUBROUTINE NM_TFQMR_Solv(A, b, x, params, precond, result, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
