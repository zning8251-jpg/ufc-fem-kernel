# `NM_Base_Def.f90`

- **Source**: `L2_NM/Base/NM_Base_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Base_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Base_Def`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Base`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Base/NM_Base_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_ArcLen_Type` (lines 62–68)

```fortran
    TYPE :: NM_ArcLen_Type
        REAL(wp)    :: arcLen     = 0.0_wp     ! Current arc-length
        INTEGER(i4) :: method     = 1_i4       ! 1=CRISFIELD, 2=RAMM, 3=RIKS
        REAL(wp)    :: maxStep    = 0.1_wp     ! Maximum step size
        REAL(wp)    :: minStep    = 1.0e-6_wp  ! Minimum step size
        LOGICAL     :: enAdaptStep = .TRUE.    ! Enable adaptive stepping
    END TYPE NM_ArcLen_Type
```

### `NM_LinSolv_Type` (lines 70–78)

```fortran
    TYPE :: NM_LinSolv_Type
        INTEGER(i4)        :: solvType   = NM_LINSOL_CG    ! Solver type
        INTEGER(i4)        :: precType   = NM_PREC_ILU0    ! Preconditioner type
        REAL(wp)           :: tol        = 1.0e-8_wp       ! Relative tolerance
        INTEGER(i4)        :: maxIter    = 1000_i4         ! Max iterations
        LOGICAL            :: usePrecond = .TRUE.           ! Use preconditioner
        LOGICAL            :: enResOut   = .FALSE.          ! Output residual history
        CHARACTER(LEN=64)  :: directSolv = "MUMPS"         ! Direct solver name
    END TYPE NM_LinSolv_Type
```

### `NM_NLSolv_Type` (lines 80–86)

```fortran
    TYPE :: NM_NLSolv_Type
        INTEGER(i4)  :: method       = NM_NL_NR    ! Nonlinear method
        REAL(wp)     :: tol          = 1.0e-6_wp   ! Force/energy tolerance
        INTEGER(i4)  :: maxIter      = 50_i4       ! Max Newton iterations
        LOGICAL      :: enLineSearch = .TRUE.       ! Enable line search
        TYPE(NM_ArcLen_Type) :: ArcLen              ! Arc-length parameters
    END TYPE NM_NLSolv_Type
```

### `NM_EigenSolv_Type` (lines 88–95)

```fortran
    TYPE :: NM_EigenSolv_Type
        INTEGER(i4)  :: method    = NM_EIGEN_LANCZOS  ! Algorithm
        INTEGER(i4)  :: nEigen    = 10_i4             ! Number of eigenvalues
        REAL(wp)     :: tol       = 1.0e-8_wp         ! Convergence tolerance
        INTEGER(i4)  :: maxIter   = 300_i4            ! Max iterations
        INTEGER(i4)  :: blockSize = 1_i4              ! Block size (LOBPCG)
        LOGICAL      :: massNorm  = .TRUE.             ! Mass-normalise eigenvectors
    END TYPE NM_EigenSolv_Type
```

### `NM_TimeInt_Type` (lines 97–105)

```fortran
    TYPE :: NM_TimeInt_Type
        INTEGER(i4)  :: scheme     = NM_TI_NEWMARK_BETA  ! Scheme
        REAL(wp)     :: beta       = 0.25_wp             ! Newmark β
        REAL(wp)     :: gamma      = 0.5_wp              ! Newmark γ
        REAL(wp)     :: alpha      = 0.0_wp              ! HHT α (negative damping)
        LOGICAL      :: enAdapt    = .FALSE.              ! Adaptive time stepping
        REAL(wp)     :: dtMax      = 1.0_wp              ! Maximum dt
        REAL(wp)     :: dtMin      = 1.0e-8_wp           ! Minimum dt
    END TYPE NM_TimeInt_Type
```

### `NM_Precond_Type` (lines 107–114)

```fortran
    TYPE :: NM_Precond_Type
        INTEGER(i4)  :: precType   = NM_PREC_ILU0   ! Preconditioner type
        INTEGER(i4)  :: fillLevel  = 0_i4            ! ILU fill level
        REAL(wp)     :: dropTol    = 1.0e-4_wp       ! ILUT drop tolerance
        INTEGER(i4)  :: amgCycle   = 1_i4            ! AMG cycle: 1=V, 2=W, 3=F
        INTEGER(i4)  :: amgSmooth  = 2_i4            ! AMG smoother sweeps
        LOGICAL      :: enReorder  = .FALSE.          ! Enable matrix reordering
    END TYPE NM_Precond_Type
```

### `NM_NumCtrl_Type` (lines 116–122)

```fortran
    TYPE :: NM_NumCtrl_Type
        TYPE(NM_LinSolv_Type)   :: LinSolv     ! Linear solver config
        TYPE(NM_NLSolv_Type)    :: NLSolv      ! Nonlinear solver config
        TYPE(NM_EigenSolv_Type) :: EigenSolv   ! Eigenvalue solver config
        TYPE(NM_TimeInt_Type)   :: TimeInt     ! Time integration config
        TYPE(NM_Precond_Type)   :: Precond     ! Preconditioner config
    END TYPE NM_NumCtrl_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
