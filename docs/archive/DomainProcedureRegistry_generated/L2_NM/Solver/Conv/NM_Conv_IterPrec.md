# `NM_Conv_IterPrec.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_IterPrec.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Conv_IterPrec`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_IterPrec`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv_IterPrec`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_IterPrec.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Preconditioner_Params` (lines 48–61)

```fortran
  TYPE, PUBLIC :: Preconditioner_Params
    INTEGER(i4) :: precond_type = NM_SOLV_PREC_ILU
    INTEGER(i4) :: ilu_variant = NM_ILU_0
    INTEGER(i4) :: fill_level = 0_i4       !< ILU fill
    REAL(DP) :: drop_tolerance = 1.0E-4_DP !< drop tol
    REAL(DP) :: omega = 1.0_DP             !< SOR omega
    INTEGER(i4) :: sweeps = 1_i4           !< sweeps
    ! AMG
    INTEGER(i4) :: amg_levels = 10_i4
    INTEGER(i4) :: amg_coarsening = 1_i4
    REAL(DP) :: amg_strong_threshold = 0.25_DP
    ! SPAI
    INTEGER(i4) :: spai_max_nnz = 50_i4
  END TYPE Preconditioner_Params
```

### `Preconditioner_Data` (lines 64–75)

```fortran
  TYPE, PUBLIC :: Preconditioner_Data
    INTEGER(i4) :: precond_type = 0_i4
    ! ILU
    REAL(DP), ALLOCATABLE :: L(:,:)        !< L factor
    REAL(DP), ALLOCATABLE :: U(:,:)        !< U factor
    ! diagonal
    REAL(DP), ALLOCATABLE :: D_inv(:)      !< D inv
    ! SPAI
    REAL(DP), ALLOCATABLE :: M(:,:)        !< sparse approx
    ! AMG
    TYPE(NM_AMG_Level), POINTER :: amg_hierarchy => NULL()
  END TYPE Preconditioner_Data
```

### `NM_AMG_Level` (lines 78–85)

```fortran
  TYPE :: NM_AMG_Level
    REAL(DP), ALLOCATABLE :: A(:,:)        !< coarse matrix
    REAL(DP), ALLOCATABLE :: P(:,:)        !< prolong
    REAL(DP), ALLOCATABLE :: R(:,:)        !< restrict
    INTEGER(i4) :: n_fine = 0_i4
    INTEGER(i4) :: n_coarse = 0_i4
    TYPE(NM_AMG_Level), POINTER :: next => NULL()
  END TYPE NM_AMG_Level
```

### `Preconditioner_Result` (lines 88–93)

```fortran
  TYPE, PUBLIC :: Preconditioner_Result
    REAL(DP), ALLOCATABLE :: z(:)          !< z = M^{-1}*r
    INTEGER(i4) :: n_applications = 0_i4   !< apply count
    REAL(DP) :: setup_time = ZERO          !< setup time
    REAL(DP) :: apply_time = ZERO          !< apply time
  END TYPE Preconditioner_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Preconditioner_Setup` | 132 | `SUBROUTINE NM_Preconditioner_Setup(A, params, precond_data, status)` |
| SUBROUTINE | `NM_ILU_Setup` | 163 | `SUBROUTINE NM_ILU_Setup(A, params, precond_data, status)` |
| SUBROUTINE | `NM_IC_Setup` | 220 | `SUBROUTINE NM_IC_Setup(A, params, precond_data, status)` |
| SUBROUTINE | `NM_Jacobi_Setup` | 265 | `SUBROUTINE NM_Jacobi_Setup(A, precond_data, status)` |
| SUBROUTINE | `NM_SSOR_Setup` | 288 | `SUBROUTINE NM_SSOR_Setup(A, params, precond_data, status)` |
| SUBROUTINE | `NM_SPAI_Setup` | 301 | `SUBROUTINE NM_SPAI_Setup(A, params, precond_data, status)` |
| SUBROUTINE | `NM_AMG_Setup` | 329 | `SUBROUTINE NM_AMG_Setup(A, params, precond_data, status)` |
| SUBROUTINE | `NM_Preconditioner_Apply` | 353 | `SUBROUTINE NM_Preconditioner_Apply(precond_data, r, z, status)` |
| SUBROUTINE | `NM_ILU_Solv` | 382 | `SUBROUTINE NM_ILU_Solv(L, U, r, z, status)` |
| SUBROUTINE | `NM_IC_Solv` | 423 | `SUBROUTINE NM_IC_Solv(L, r, z, status)` |
| SUBROUTINE | `NM_Jacobi_Apply` | 463 | `SUBROUTINE NM_Jacobi_Apply(D_inv, r, z)` |
| SUBROUTINE | `NM_SSOR_Apply` | 472 | `SUBROUTINE NM_SSOR_Apply(D_inv, r, z)` |
| SUBROUTINE | `NM_SPAI_Apply` | 482 | `SUBROUTINE NM_SPAI_Apply(M, r, z)` |
| SUBROUTINE | `NM_AMG_VCycle` | 491 | `SUBROUTINE NM_AMG_VCycle(level, r, z, status)` |
| SUBROUTINE | `NM_Preconditioner_Destroy` | 508 | `SUBROUTINE NM_Preconditioner_Destroy(precond_data)` |
| FUNCTION | `NM_Estimate_Condition_Number` | 524 | `FUNCTION NM_Estimate_Condition_Number(A) RESULT(cond)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
