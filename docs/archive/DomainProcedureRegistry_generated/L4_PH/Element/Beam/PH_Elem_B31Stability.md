# `PH_Elem_B31Stability.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31Stability.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B31Stability`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31Stability`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31Stability`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31Stability.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_Stab_Desc_Type` (lines 28–53)

```fortran
TYPE :: B31_Stab_Desc_Type
  ! Buckling analysis parameters
  INTEGER(i4) :: n_modes_requested        ! Number of buckling modes to extract
  REAL(wp) :: load_ref                 ! Reference load magnitude
  CHARACTER(len=32) :: method          ! 'EIGEN', 'RIKS', 'CRISFIELD'
  
  ! Arc-length control parameters
  REAL(wp) :: arc_length_initial       ! Initial arc length radius
  REAL(wp) :: arc_length_min           ! Minimum arc length
  REAL(wp) :: arc_length_max           ! Maximum arc length
  REAL(wp) :: max_displacement         ! Maximum displacement limit
  
  ! Iteration control
  INTEGER(i4) :: max_iterations            ! Max NR iterations per step
  REAL(wp) :: tol_force                  ! Force convergence tolerance
  REAL(wp) :: tol_energy                 ! Energy convergence tolerance
  REAL(wp) :: tol_displacement           ! Displacement convergence tolerance
  
  ! Imperfection parameters
  REAL(wp) :: imperfection_scale        ! Scale factor for geometric imperfection
  INTEGER(i4) :: imperfection_mode         ! Buckling mode number for imperfection
  
  ! Critical point detection
  LOGICAL  :: detect_snap_through       ! Enable snap-through detection
  LOGICAL  :: detect_bifurcation        ! Enable bifurcation detection
END TYPE B31_Stab_Desc_Type
```

### `B31_Stab_State_Type` (lines 55–83)

```fortran
TYPE :: B31_Stab_State_Type
  ! Load parameter
  REAL(wp) :: lambda                   ! Current load factor
  REAL(wp) :: lambda_prev              ! Previous load factor
  REAL(wp) :: dlambda                  ! Load increment
  
  ! Arc-length variables
  REAL(wp) :: arc_length_current       ! Current arc length radius
  REAL(wp) :: ds                       ! Arc length increment
  REAL(wp) :: constraint_value         ! Constraint equation value
  
  ! Displacement state
  REAL(wp) :: u_total(:)               ! Total displacement vector
  REAL(wp) :: u_predictor(:)           ! Predictor displacement
  REAL(wp) :: u_corrector(:)           ! Corrector displacement
  
  ! Path following
  INTEGER(i4) :: branch_direction          ! +1 or -1 for path direction
  LOGICAL  :: passed_limit_point        ! Flag for limit point passage
  
  ! Critical points
  INTEGER(i4) :: n_critical_points         ! Number of detected critical points
  REAL(wp), ALLOCATABLE :: critical_loads(:)    ! Critical load factors
  REAL(wp), ALLOCATABLE :: critical_disps(:,:)  ! Critical displacements
  
  ! Mode shapes
  REAL(wp), ALLOCATABLE :: buckling_modes(:,:,:) ! Mode shapes at nodes
  REAL(wp), ALLOCATABLE :: eigenvalues(:)        ! Eigenvalues λ_i
END TYPE B31_Stab_State_Type
```

### `B31_Stab_AlgoCtx_Type` (lines 85–117)

```fortran
TYPE :: B31_Stab_AlgoCtx_Type
  ! Work arrays
  REAL(wp) :: K_mat(:,:)               ! Material stiffness matrix
  REAL(wp) :: K_geo(:,:)               ! Geometric stiffness matrix
  REAL(wp) :: K_tan(:,:)               ! Tangent stiffness matrix
  REAL(wp) :: F_int(:)                 ! Internal force vector
  REAL(wp) :: F_ext(:)                 ! External reference load
  REAL(wp) :: F_resid(:)               ! Residual force vector
  
  ! Eigensolver workspace
  REAL(wp) :: subspace_vecs(:,:)       ! Subspace iteration vectors
  INTEGER(i4) :: n_subspace_iter          ! Subspace iterations
  
  ! Arc-length algorithm
  INTEGER(i4) :: pivot_sign              ! Sign of tangent matrix pivot
  INTEGER(i4) :: last_pivot_sign         ! Previous pivot sign
  LOGICAL  :: negative_pivot_detected ! Negative pivot flag
  
  ! Iteration history
  INTEGER(i4) :: nr_iter                 ! Newton-Raphson iterations
  REAL(wp) :: residual_norm            ! Residual norm
  REAL(wp) :: energy_norm              ! Energy norm
  REAL(wp) :: displacement_norm        ! Displacement norm
  LOGICAL  :: converged               ! Convergence flag
  
  ! Path tracking
  INTEGER(i4) :: total_steps             ! Total load steps completed
  INTEGER(i4) :: failed_steps            ! Number of failed steps
  
  ! Temporary arrays
  REAL(wp) :: temp_n(:)                ! Temporary vector (size = n_dof)
  REAL(wp) :: temp_m(:,:)              ! Temporary matrix
END TYPE B31_Stab_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_Stab_Initialize` | 134 | `SUBROUTINE PH_Elem_B31_Stab_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_Stab_LinearBuckling` | 220 | `SUBROUTINE PH_Elem_B31_Stab_LinearBuckling(&` |
| SUBROUTINE | `PH_Elem_B31_Stab_ArcLengthRiks` | 368 | `SUBROUTINE PH_Elem_B31_Stab_ArcLengthRiks(&` |
| SUBROUTINE | `PH_Elem_B31_Stab_ArcLengthCrisfield` | 527 | `SUBROUTINE PH_Elem_B31_Stab_ArcLengthCrisfield(&` |
| SUBROUTINE | `PH_Elem_B31_Stab_IntroduceImperfection` | 571 | `SUBROUTINE PH_Elem_B31_Stab_IntroduceImperfection(&` |
| SUBROUTINE | `PH_Elem_B31_Stab_DetectCriticalPoint` | 646 | `SUBROUTINE PH_Elem_B31_Stab_DetectCriticalPoint(&` |
| SUBROUTINE | `PH_Elem_B31_Stab_PostBucklingPath` | 707 | `SUBROUTINE PH_Elem_B31_Stab_PostBucklingPath(&` |
| SUBROUTINE | `K_mat_func` | 718 | `SUBROUTINE K_mat_func(u, K_mat, status)` |
| SUBROUTINE | `K_geo_func` | 726 | `SUBROUTINE K_geo_func(u, lambda, K_geo, status)` |
| SUBROUTINE | `F_int_func` | 734 | `SUBROUTINE F_int_func(u, lambda, F_int, status)` |
| SUBROUTINE | `PH_Elem_B31_Stab_GramSchmidt` | 815 | `SUBROUTINE PH_Elem_B31_Stab_GramSchmidt(V, n, m)` |
| SUBROUTINE | `PH_Elem_B31_Stab_SolveLinearSystem` | 834 | `SUBROUTINE PH_Elem_B31_Stab_SolveLinearSystem(A, b, x, status)` |
| SUBROUTINE | `PH_Elem_B31_Stab_JacobiEigen` | 845 | `SUBROUTINE PH_Elem_B31_Stab_JacobiEigen(A, B, n, eigenvalues, eigenvectors, status)` |
| SUBROUTINE | `PH_Elem_B31_Stab_SortEigenvalues` | 858 | `SUBROUTINE PH_Elem_B31_Stab_SortEigenvalues(eigenvalues, eigenvectors, n)` |
| SUBROUTINE | `PH_Elem_B31_Stab_CheckPivotSign` | 881 | `SUBROUTINE PH_Elem_B31_Stab_CheckPivotSign(K, prev_sign, curr_sign, neg_detected)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 717–724 | `INTERFACE` |
| 725–732 | `INTERFACE` |
| 733–740 | `INTERFACE` |
