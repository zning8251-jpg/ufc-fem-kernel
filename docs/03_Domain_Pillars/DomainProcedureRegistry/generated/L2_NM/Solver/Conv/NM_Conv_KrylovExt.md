# `NM_Conv_KrylovExt.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_KrylovExt.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Conv_KrylovExt`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_KrylovExt`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv_KrylovExt`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_KrylovExt.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Krylov_Extension_Params_Type` (lines 39–41)

```fortran
    TYPE, PUBLIC :: Krylov_Extension_Params_Type
    INTEGER(i4) :: extension_type = NM_KRYLOV_RESTART_ADAPTIVE
  END TYPE Krylov_Extension_Params_Type
```

### `Krylov_Extension_Params_Basis` (lines 43–46)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Params_Basis
    INTEGER(i4) :: max_basis_size = 50_i4
    INTEGER(i4) :: min_basis_size = 10_i4
  END TYPE Krylov_Extension_Params_Basis
```

### `Krylov_Extension_Params_Thresh` (lines 48–50)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Params_Thresh
    REAL(DP) :: residual_ratio_threshold = 0.1_DP
  END TYPE Krylov_Extension_Params_Thresh
```

### `Krylov_Extension_Params_Eigen` (lines 52–55)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Params_Eigen
    INTEGER(i4) :: max_eigenvectors = 5_i4
    REAL(DP) :: eigenvalue_tolerance = 1.0E-6_DP
  END TYPE Krylov_Extension_Params_Eigen
```

### `Krylov_Extension_Params_Flags` (lines 57–59)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Params_Flags
    LOGICAL :: use_selective_orthogonalization = .TRUE.
  END TYPE Krylov_Extension_Params_Flags
```

### `Krylov_Extension_Params` (lines 61–67)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Params
    TYPE(Krylov_Extension_Params_Type)   :: ext_type
    TYPE(Krylov_Extension_Params_Basis)  :: basis
    TYPE(Krylov_Extension_Params_Thresh) :: thresh
    TYPE(Krylov_Extension_Params_Eigen)  :: eigen
    TYPE(Krylov_Extension_Params_Flags)  :: flags
  END TYPE Krylov_Extension_Params
```

### `Krylov_Basis` (lines 70–75)

```fortran
  TYPE, PUBLIC :: Krylov_Basis
    REAL(DP), ALLOCATABLE :: V(:,:)        !< Krylov vecs
    REAL(DP), ALLOCATABLE :: H(:,:)        !< Hessenberg
    INTEGER(i4) :: dimension = 0_i4        !< current dim
    INTEGER(i4) :: max_dim = 0_i4          !< max dim
  END TYPE Krylov_Basis
```

### `Augmented_Krylov_Subspace` (lines 78–83)

```fortran
  TYPE, PUBLIC :: Augmented_Krylov_Subspace
    TYPE(Krylov_Basis) :: standard_basis
    REAL(DP), ALLOCATABLE :: U(:,:)        !< aug vectors
    REAL(DP), ALLOCATABLE :: C(:,:)        !< C = A·U
    INTEGER(i4) :: n_augmented = 0_i4
  END TYPE Augmented_Krylov_Subspace
```

### `Spectral_Info` (lines 86–90)

```fortran
  TYPE, PUBLIC :: Spectral_Info
    REAL(DP), ALLOCATABLE :: eigenvalues(:)
    REAL(DP), ALLOCATABLE :: eigenvectors(:,:)
    INTEGER(i4) :: n_converged = 0_i4
  END TYPE Spectral_Info
```

### `Recursive_Krylov_Data` (lines 93–97)

```fortran
  TYPE, PUBLIC :: Recursive_Krylov_Data
    TYPE(Krylov_Basis) :: inner_basis
    TYPE(Krylov_Basis) :: outer_basis
    INTEGER(i4) :: recursion_level = 0_i4
  END TYPE Recursive_Krylov_Data
```

### `Krylov_Extension_Result_Sol` (lines 100–102)

```fortran
    TYPE, PUBLIC :: Krylov_Extension_Result_Sol
    REAL(DP), ALLOCATABLE :: x(:)          !< solution
  END TYPE Krylov_Extension_Result_Sol
```

### `Krylov_Extension_Result_Residual` (lines 104–106)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Result_Residual
    REAL(DP) :: residual_norm = ZERO
  END TYPE Krylov_Extension_Result_Residual
```

### `Krylov_Extension_Result_Stats` (lines 108–112)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4
    INTEGER(i4) :: n_matvecs = 0_i4
    INTEGER(i4) :: basis_size = 0_i4
  END TYPE Krylov_Extension_Result_Stats
```

### `Krylov_Extension_Result_Flags` (lines 114–116)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Result_Flags
    LOGICAL :: converged = .FALSE.
  END TYPE Krylov_Extension_Result_Flags
```

### `Krylov_Extension_Result_Meta` (lines 118–120)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Result_Meta
    CHARACTER(LEN=128) :: message = ""
  END TYPE Krylov_Extension_Result_Meta
```

### `Krylov_Extension_Result` (lines 122–128)

```fortran
  TYPE, PUBLIC :: Krylov_Extension_Result
    TYPE(Krylov_Extension_Result_Sol)      :: sol
    TYPE(Krylov_Extension_Result_Residual) :: residual
    TYPE(Krylov_Extension_Result_Stats)    :: stats
    TYPE(Krylov_Extension_Result_Flags)    :: flags
    TYPE(Krylov_Extension_Result_Meta)     :: meta
  END TYPE Krylov_Extension_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Krylov_Extended_Solv` | 171 | `SUBROUTINE NM_Krylov_Extended_Solv(A, b, x, params, result, status)` |
| SUBROUTINE | `NM_Adaptive_Restart_GMRES` | 195 | `SUBROUTINE NM_Adaptive_Restart_GMRES(A, b, x, params, result, status)` |
| SUBROUTINE | `NM_Augmented_GMRES` | 315 | `SUBROUTINE NM_Augmented_GMRES(A, b, x, params, result, status)` |
| SUBROUTINE | `NM_Deflated_GMRES` | 362 | `SUBROUTINE NM_Deflated_GMRES(A, b, x, params, result, status)` |
| SUBROUTINE | `NM_Build_Krylov_Basis` | 385 | `SUBROUTINE NM_Build_Krylov_Basis(A, v0, m, basis, status)` |
| SUBROUTINE | `NM_Extend_Krylov_Basis` | 421 | `SUBROUTINE NM_Extend_Krylov_Basis(A, basis, num_vectors, status)` |
| SUBROUTINE | `NM_Orthogonalize_Vector` | 458 | `SUBROUTINE NM_Orthogonalize_Vector(w, V, h)` |
| SUBROUTINE | `NM_Calc_Ritz_Pairs` | 481 | `SUBROUTINE NM_Calc_Ritz_Pairs(A, basis, eigenvectors, n_converged)` |
| SUBROUTINE | `NM_Augment_Subspace` | 520 | `SUBROUTINE NM_Augment_Subspace(aug_subspace, new_vectors)` |
| SUBROUTINE | `NM_Se_Au_Vectors` | 540 | `SUBROUTINE NM_Se_Au_Vectors(eigenvalues, eigenvectors, &` |
| SUBROUTINE | `NM_Co_Sp_Preconditioner` | 562 | `SUBROUTINE NM_Co_Sp_Preconditioner(A, spectral_info, M)` |
| SUBROUTINE | `NM_Update_Spectral_Info` | 584 | `SUBROUTINE NM_Update_Spectral_Info(basis, spectral_info)` |
| SUBROUTINE | `NM_Krylov_Basis_Init` | 598 | `SUBROUTINE NM_Krylov_Basis_Init(n, max_dim, basis)` |
| SUBROUTINE | `NM_Krylov_Basis_Destroy` | 617 | `SUBROUTINE NM_Krylov_Basis_Destroy(basis)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
