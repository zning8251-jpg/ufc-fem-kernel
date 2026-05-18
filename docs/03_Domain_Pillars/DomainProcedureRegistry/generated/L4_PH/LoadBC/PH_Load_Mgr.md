# `PH_Load_Mgr.f90`

- **Source**: `L4_PH/LoadBC/PH_Load_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Load_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Load_Mgr`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Load`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Load_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Load_Ctx` (lines 27–43)

```fortran
  TYPE, PUBLIC :: PH_Load_Ctx
    INTEGER(i4) :: integration_method = LOAD_INTEG_GAUSS
    INTEGER(i4) :: n_integration_points = 2_i4
    LOGICAL     :: use_consistent_load = .TRUE.
    LOGICAL     :: account_follower = .FALSE.
    INTEGER(i4) :: n_loads_applied = 0_i4
    REAL(wp)    :: total_load_magnitude = 0.0_wp
    INTEGER(i4) :: n_concentrated_loads = 0_i4
    INTEGER(i4) :: n_distributed_loads = 0_i4
    INTEGER(i4) :: n_body_forces = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => PH_Load_Ctx_Init
    PROCEDURE, PUBLIC :: Clear => PH_Load_Ctx_Clear
    PROCEDURE, PUBLIC :: SetIntegMethod => PH_Load_Ctx_SetIntegMethod
    PROCEDURE, PUBLIC :: GetIntegMethod => PH_Load_Ctx_GetIntegMethod
    PROCEDURE, PUBLIC :: IncrementCount => PH_Load_Ctx_IncrementCount
  END TYPE PH_Load_Ctx
```

### `PH_Load_Ctx_Init_Arg` (lines 46–51)

```fortran
  TYPE, PUBLIC :: PH_Load_Ctx_Init_Arg
    INTEGER(i4) :: method = LOAD_INTEG_GAUSS     ! [IN] integration method
    INTEGER(i4) :: n_points = 2_i4               ! [IN] number of integration points
    TYPE(PH_Load_Ctx) :: ctx                     ! [OUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_Ctx_Init_Arg
```

### `PH_Load_Ctx_SetIntegMethod_Arg` (lines 55–60)

```fortran
  TYPE, PUBLIC :: PH_Load_Ctx_SetIntegMethod_Arg
    TYPE(PH_Load_Ctx) :: ctx                     ! [INOUT]
    INTEGER(i4) :: method = LOAD_INTEG_GAUSS     ! [IN]
    INTEGER(i4) :: n_points = 2_i4               ! [IN]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_Ctx_SetIntegMethod_Arg
```

### `PH_Load_Ctx_IncrementCount_Arg` (lines 64–69)

```fortran
  TYPE, PUBLIC :: PH_Load_Ctx_IncrementCount_Arg
    TYPE(PH_Load_Ctx) :: ctx                     ! [INOUT]
    CHARACTER(LEN=32) :: load_type = ''           ! [IN]
    REAL(wp) :: magnitude = 0.0_wp               ! [IN] optional magnitude
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_Ctx_IncrementCount_Arg
```

### `PH_Load_AssembleCLoad_Arg` (lines 120–123)

```fortran
  TYPE, PUBLIC :: PH_Load_AssembleCLoad_Arg
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl                   ! [IN]
    TYPE(PH_Load_LoadRhs_Type) :: rhs                   ! [INOUT]
  END TYPE PH_Load_AssembleCLoad_Arg
```

### `PH_Load_AssembleGravity_Arg` (lines 127–130)

```fortran
  TYPE, PUBLIC :: PH_Load_AssembleGravity_Arg
    TYPE(PH_Load_LoadCtrl_Type) :: ctrl                   ! [IN]
    TYPE(PH_Load_LoadMassRhs_Type) :: mass_rhs                   ! [INOUT]
  END TYPE PH_Load_AssembleGravity_Arg
```

### `PH_Load_ComputeEquivForce_Arg` (lines 134–139)

```fortran
  TYPE, PUBLIC :: PH_Load_ComputeEquivForce_Arg
    INTEGER(i4) :: load_type = 0_i4              ! [IN] MD_LBC_Domain: LOAD_DLOAD / etc.
    REAL(wp) :: magnitude(3) = 0.0_wp            ! [IN] load magnitude vector
    REAL(wp), ALLOCATABLE :: elem_coords(:,:)    ! [IN] (nDim, nNodes)
    REAL(wp), ALLOCATABLE :: equiv_forces(:,:)   ! [OUT] (nDim, nNodes)
  END TYPE PH_Load_ComputeEquivForce_Arg
```

### `PH_Load_ApplyBody_Gravity_Arg` (lines 146–156)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyBody_Gravity_Arg
    REAL(wp) :: density = 0.0_wp                 ! [IN]
    REAL(wp) :: gravity_vector(3) = 0.0_wp       ! [IN] gravity acceleration
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyBody_Gravity_Arg
```

### `PH_Load_ApplyBody_Generic_Arg` (lines 160–169)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyBody_Generic_Arg
    REAL(wp), ALLOCATABLE :: body_force_density(:) ! [IN] body force per unit volume
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyBody_Generic_Arg
```

### `PH_Load_ApplyConcentrated_Single_Arg` (lines 176–182)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyConcentrated_Single_Arg
    INTEGER(i4) :: dof_index = 0_i4              ! [IN]
    REAL(wp) :: load_magnitude = 0.0_wp          ! [IN]
    REAL(wp) :: amplitude_factor = 1.0_wp        ! [IN]
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyConcentrated_Single_Arg
```

### `PH_Load_ApplyConcentrated_Batch_Arg` (lines 186–193)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyConcentrated_Batch_Arg
    INTEGER(i4), ALLOCATABLE :: dof_indices(:)   ! [IN]
    REAL(wp), ALLOCATABLE :: load_magnitudes(:)  ! [IN]
    REAL(wp), ALLOCATABLE :: amplitude_factors(:) ! [IN] optional per-load
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyConcentrated_Batch_Arg
```

### `PH_Load_ApplyDistributed_Surface_Arg` (lines 200–209)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyDistributed_Surface_Arg
    REAL(wp), ALLOCATABLE :: traction_vector(:)  ! [IN] surface traction
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyDistributed_Surface_Arg
```

### `PH_Load_ApplyDistributed_Edge_Arg` (lines 213–221)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyDistributed_Edge_Arg
    REAL(wp) :: edge_length = 0.0_wp             ! [IN]
    INTEGER(i4) :: n_gp = 0_i4                   ! [IN]
    REAL(wp), ALLOCATABLE :: traction_vector(:)  ! [IN] edge traction
    INTEGER(i4), ALLOCATABLE :: edge_dofs(:)     ! [IN] edge DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyDistributed_Edge_Arg
```

### `PH_Load_ApplyFollower_Pressure_Arg` (lines 228–241)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyFollower_Pressure_Arg
    REAL(wp) :: pressure = 0.0_wp                ! [IN]
    LOGICAL :: compute_tangent = .FALSE.         ! [IN]
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)       ! [IN] (nNodes, 2, nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)    ! [IN] (nNodes, 3)
    REAL(wp), ALLOCATABLE :: displacement(:,:)   ! [IN] (nNodes, 3)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    REAL(wp), ALLOCATABLE :: K_T(:,:)            ! [INOUT] tangent stiffness
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyFollower_Pressure_Arg
```

### `PH_Load_ComputeFollowerTangent_Arg` (lines 245–249)

```fortran
  TYPE, PUBLIC :: PH_Load_ComputeFollowerTangent_Arg
    REAL(wp) :: pressure = 0.0_wp                ! [IN]
    REAL(wp), ALLOCATABLE :: K_T(:,:)            ! [INOUT] tangent stiffness
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ComputeFollowerTangent_Arg
```

### `PH_Load_ApplyPressure_Surface_Arg` (lines 256–266)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyPressure_Surface_Arg
    REAL(wp) :: pressure = 0.0_wp                ! [IN]
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)       ! [IN] (nNodes, 2, nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)    ! [IN] (nNodes, 3)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyPressure_Surface_Arg
```

### `PH_Load_ApplyThermal_Uniform_Arg` (lines 273–284)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyThermal_Uniform_Arg
    REAL(wp) :: delta_T = 0.0_wp                 ! [IN] temperature change
    REAL(wp) :: alpha = 0.0_wp                   ! [IN] thermal expansion coeff
    REAL(wp) :: D_matrix(6,6) = 0.0_wp           ! [IN] elasticity matrix
    REAL(wp), ALLOCATABLE :: B_matrix(:,:,:)     ! [IN] (6, nDofElem, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyThermal_Uniform_Arg
```

### `PH_Load_ApplyThermal_Gradient_Arg` (lines 288–301)

```fortran
  TYPE, PUBLIC :: PH_Load_ApplyThermal_Gradient_Arg
    REAL(wp) :: T_ref = 0.0_wp                   ! [IN] reference temperature
    REAL(wp) :: alpha = 0.0_wp                   ! [IN] thermal expansion coeff
    REAL(wp) :: D_matrix(6,6) = 0.0_wp           ! [IN] elasticity matrix
    REAL(wp), ALLOCATABLE :: T_nodes(:)          ! [IN] nodal temperatures
    REAL(wp), ALLOCATABLE :: shape_funcs(:,:)    ! [IN] (nNodes, nGP)
    REAL(wp), ALLOCATABLE :: B_matrix(:,:,:)     ! [IN] (6, nDofElem, nGP)
    REAL(wp), ALLOCATABLE :: detJ(:)             ! [IN] (nGP)
    REAL(wp), ALLOCATABLE :: gauss_weights(:)    ! [IN] (nGP)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)     ! [IN] element DOF mapping
    REAL(wp), ALLOCATABLE :: F(:)                ! [INOUT] global force vector
    TYPE(PH_Load_Ctx) :: load_ctx                ! [INOUT]
    TYPE(ErrorStatusType) :: status               ! [OUT]
  END TYPE PH_Load_ApplyThermal_Gradient_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Load_Ctx_Init` | 309 | `SUBROUTINE PH_Load_Ctx_Init(this, method, n_points)` |
| SUBROUTINE | `PH_Load_Ctx_Init_Structured` | 326 | `SUBROUTINE PH_Load_Ctx_Init_Structured(arg)` |
| SUBROUTINE | `PH_Load_Ctx_Clear` | 333 | `SUBROUTINE PH_Load_Ctx_Clear(this)` |
| SUBROUTINE | `PH_Load_Ctx_SetIntegMethod` | 342 | `SUBROUTINE PH_Load_Ctx_SetIntegMethod(this, method, n_points)` |
| SUBROUTINE | `PH_Load_Ctx_SetIntegMethod_Structured` | 350 | `SUBROUTINE PH_Load_Ctx_SetIntegMethod_Structured(arg)` |
| FUNCTION | `PH_Load_Ctx_GetIntegMethod` | 358 | `FUNCTION PH_Load_Ctx_GetIntegMethod(this) RESULT(method)` |
| SUBROUTINE | `PH_Load_Ctx_IncrementCount` | 364 | `SUBROUTINE PH_Load_Ctx_IncrementCount(this, load_type, magnitude)` |
| SUBROUTINE | `PH_Load_Ctx_IncrementCount_Structured` | 380 | `SUBROUTINE PH_Load_Ctx_IncrementCount_Structured(arg)` |
| SUBROUTINE | `PH_Load_AssembleCLoad` | 391 | `SUBROUTINE PH_Load_AssembleCLoad(arg)` |
| SUBROUTINE | `PH_Load_AssembleGravity` | 408 | `SUBROUTINE PH_Load_AssembleGravity(arg)` |
| SUBROUTINE | `PH_Load_ComputeEquivForce` | 428 | `SUBROUTINE PH_Load_ComputeEquivForce(arg)` |
| SUBROUTINE | `PH_Load_ApplyBody_Generic` | 456 | `SUBROUTINE PH_Load_ApplyBody_Generic(arg)` |
| SUBROUTINE | `PH_Load_ApplyBody_Gravity` | 501 | `SUBROUTINE PH_Load_ApplyBody_Gravity(arg)` |
| SUBROUTINE | `PH_Load_ApplyConcentrated_Single` | 550 | `SUBROUTINE PH_Load_ApplyConcentrated_Single(arg)` |
| SUBROUTINE | `PH_Load_ApplyConcentrated_Batch` | 577 | `SUBROUTINE PH_Load_ApplyConcentrated_Batch(arg)` |
| SUBROUTINE | `PH_Load_ApplyDistributed_Edge` | 635 | `SUBROUTINE PH_Load_ApplyDistributed_Edge(arg)` |
| SUBROUTINE | `PH_Load_ApplyDistributed_Surface` | 669 | `SUBROUTINE PH_Load_ApplyDistributed_Surface(arg)` |
| SUBROUTINE | `PH_Load_ApplyFollower_Pressure` | 717 | `SUBROUTINE PH_Load_ApplyFollower_Pressure(arg)` |
| SUBROUTINE | `PH_Load_ComputeFollowerTangent` | 799 | `SUBROUTINE PH_Load_ComputeFollowerTangent(arg)` |
| SUBROUTINE | `PH_Load_ApplyPressure_Surface` | 814 | `SUBROUTINE PH_Load_ApplyPressure_Surface(arg)` |
| FUNCTION | `PH_Load_ComputeSurfaceNormal` | 863 | `FUNCTION PH_Load_ComputeSurfaceNormal(dx_dxi, dx_deta) RESULT(normal)` |
| SUBROUTINE | `PH_Load_ApplyThermal_Gradient` | 881 | `SUBROUTINE PH_Load_ApplyThermal_Gradient(arg)` |
| SUBROUTINE | `PH_Load_ApplyThermal_Uniform` | 937 | `SUBROUTINE PH_Load_ApplyThermal_Uniform(arg)` |
| SUBROUTINE | `PH_Load_AssembleLoadVector` | 999 | `SUBROUTINE PH_Load_AssembleLoadVector(ctrl, time, F, status)` |
| SUBROUTINE | `AssembleSingleCLoad` | 1067 | `SUBROUTINE AssembleSingleCLoad(cache, F_vec, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
