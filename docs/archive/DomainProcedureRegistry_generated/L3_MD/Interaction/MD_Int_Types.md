# `MD_Int_Types.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Types.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Int_Types`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Types`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int`
- **第四段角色（四段式）**: `_Types`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Types.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Int_ContNode_State` (lines 130–155)

```fortran
  TYPE, PUBLIC :: MD_Int_ContNode_State
    INTEGER(i4) :: global_id       = 0_i4              ! [in]    Global node ID
    INTEGER(i4) :: local_id        = 0_i4              ! [in]    Local node ID
    INTEGER(i4) :: state           = MD_INT_CSTATE_INITIAL ! [inout] Contact state
    INTEGER(i4) :: matched_segment = 0_i4              ! [inout] Matched segment ID
    INTEGER(i4) :: dof_y           = 0_i4              ! [in]    DOF Y index
    INTEGER(i4) :: dof_z           = 0_i4              ! [in]    DOF Z index
    INTEGER(i4) :: dof_x           = 0_i4              ! [in]    DOF X index
    INTEGER(i4) :: skew_flag       = 0_i4              ! [in]    Skew system flag
    LOGICAL     :: was_sliding     = .FALSE.           ! [inout] Previous sliding flag
    LOGICAL     :: active          = .TRUE.            ! [inout] Active flag
    REAL(wp)    :: coords(3)       = 0.0_wp            ! [inout] Current coordinates
    REAL(wp)    :: coords_init(3)  = 0.0_wp            ! [in]    Initial coordinates
    REAL(wp)    :: gap              = 0.0_wp            ! [inout] Normal gap
    REAL(wp)    :: penetration      = 0.0_wp            ! [inout] Penetration depth
    REAL(wp)    :: normal(3)       = 0.0_wp            ! [inout] Normal vector
    REAL(wp)    :: tangent(3)      = 0.0_wp            ! [inout] Tangent vector
    REAL(wp)    :: xi_local(2)     = 0.0_wp            ! [inout] Local parametric coords
    REAL(wp)    :: force_n          = 0.0_wp            ! [inout] Normal force
    REAL(wp)    :: force_t(3)      = 0.0_wp            ! [inout] Tangential force
    REAL(wp)    :: slip             = 0.0_wp            ! [inout] Accumulated slip
    REAL(wp)    :: beta             = 0.0_wp            ! [inout] Augmented multiplier
    REAL(wp)    :: lambda           = 0.0_wp            ! [inout] Lagrange multiplier
  CONTAINS
    PROCEDURE, PUBLIC :: Destroy => MD_Int_ContNode_Destroy
  END TYPE MD_Int_ContNode_State
```

### `MD_Int_AlgoCtrl_Algo` (lines 163–173)

```fortran
  TYPE, PUBLIC :: MD_Int_AlgoCtrl_Algo
    INTEGER(i4) :: algorithm_type  = MD_INT_CALGO_PENALTY  ! [in] Algorithm type
    INTEGER(i4) :: friction_model  = MD_INT_FALGO_COULOMB  ! [in] Friction algorithm
    REAL(wp)    :: penalty_stiffne = 1.0e6_wp              ! [in] Normal penalty stiffness
    REAL(wp)    :: penalty_tangent = 1.0e5_wp              ! [in] Tangent penalty stiffness
    REAL(wp)    :: friction_coeffi = 0.3_wp                ! [in] Friction coefficient
    REAL(wp)    :: tolerance_gap   = 1.0e-6_wp             ! [in] Gap tolerance
    REAL(wp)    :: tolerance_slip  = 1.0e-8_wp             ! [in] Slip tolerance
    LOGICAL     :: use_adaptive_pe = .TRUE.                ! [in] Adaptive penalty flag
    LOGICAL     :: include_frictio = .TRUE.                ! [in] Include friction flag
  END TYPE MD_Int_AlgoCtrl_Algo
```

### `MD_Int_ForceRes_State` (lines 181–191)

```fortran
  TYPE, PUBLIC :: MD_Int_ForceRes_State
    REAL(wp), ALLOCATABLE :: normal_forces(:)               ! [out] Normal forces
    REAL(wp), ALLOCATABLE :: tangent_forces(:,:)             ! [out] Tangential forces
    REAL(wp), ALLOCATABLE :: lagrange_multip(:)              ! [out] Lagrange multipliers
    INTEGER(i4)           :: nActiveCont    = 0_i4          ! [out] Active contact count
    REAL(wp)              :: total_normal_fo = 0.0_wp       ! [out] Total normal force
    REAL(wp)              :: total_friction  = 0.0_wp       ! [out] Total friction force
  CONTAINS
    PROCEDURE, PUBLIC :: Destroy => MD_Int_ForceRes_Destroy
    PROCEDURE, PUBLIC :: Init    => MD_Int_ForceRes_Init
  END TYPE MD_Int_ForceRes_State
```

### `MD_Int_AlgoSpec_Algo` (lines 199–210)

```fortran
  TYPE, PUBLIC :: MD_Int_AlgoSpec_Algo
    CHARACTER(LEN=80) :: name              = ''            ! [in] Algorithm name
    INTEGER(i4)       :: method            = 0_i4          ! [in] Enforcement method
    INTEGER(i4)       :: frictionModel     = 0_i4          ! [in] Friction model
    LOGICAL           :: regularize_frict  = .FALSE.       ! [in] Regularize friction
    INTEGER(i4)       :: searchAlgo        = 0_i4          ! [in] Search algorithm
    REAL(wp)          :: searchRadius      = 0.0_wp        ! [in] Search radius
    LOGICAL           :: use_stabilization = .FALSE.       ! [in] Use stabilization
    REAL(wp)          :: stabFactor        = 0.0_wp        ! [in] Stabilization factor
    INTEGER(i4)       :: user_int(4)       = 0_i4          ! [in] User integer params
    REAL(wp)          :: user_real(4)      = 0.0_wp        ! [in] User real params
  END TYPE MD_Int_AlgoSpec_Algo
```

### `MD_Int_UF_AlgoSpec_Algo` (lines 218–229)

```fortran
  TYPE, PUBLIC :: MD_Int_UF_AlgoSpec_Algo
    CHARACTER(LEN=80) :: name              = ''            ! [in] Algorithm name
    INTEGER(i4)       :: method            = 0_i4          ! [in] Enforcement method
    INTEGER(i4)       :: frictionModel     = 0_i4          ! [in] Friction model
    LOGICAL           :: regularize_frict  = .FALSE.       ! [in] Regularize friction
    INTEGER(i4)       :: searchAlgo        = 0_i4          ! [in] Search algorithm
    REAL(wp)          :: searchRadius      = 0.0_wp        ! [in] Search radius
    LOGICAL           :: use_stabilization = .FALSE.       ! [in] Use stabilization
    REAL(wp)          :: stabFactor        = 0.0_wp        ! [in] Stabilization factor
    INTEGER(i4)       :: user_int(4)       = 0_i4          ! [in] User integer params
    REAL(wp)          :: user_real(4)      = 0.0_wp        ! [in] User real params
  END TYPE MD_Int_UF_AlgoSpec_Algo
```

### `MD_Int_Context_Ctx` (lines 237–246)

```fortran
  TYPE, PUBLIC :: MD_Int_Context_Ctx
    INTEGER(i4) :: pairId         = 0_i4                   ! [in] Contact pair ID
    INTEGER(i4) :: id             = 0_i4                   ! [in] Context ID
    INTEGER(i4) :: incId          = 0_i4                   ! [in] Increment ID
    REAL(wp)    :: time           = 0.0_wp                 ! [in] Current time
    REAL(wp)    :: lambda         = 0.0_wp                 ! [in] Load factor
    INTEGER(i4) :: interactionId  = 0_i4                   ! [in] Interaction ID
    INTEGER(i4) :: slaveSurfId    = 0_i4                   ! [in] Slave surface ID
    INTEGER(i4) :: masterSurfId   = 0_i4                   ! [in] Master surface ID
  END TYPE MD_Int_Context_Ctx
```

### `MD_Int_Segment_Desc` (lines 254–267)

```fortran
  TYPE, PUBLIC :: MD_Int_Segment_Desc
    INTEGER(i4) :: id             = 0_i4                   ! [in]    Segment ID
    INTEGER(i4) :: surface_id     = 0_i4                   ! [in]    Parent surface ID
    INTEGER(i4) :: n_nodes        = 0_i4                   ! [in]    Node count
    INTEGER(i4) :: nodes(4)       = 0_i4                   ! [in]    Node IDs
    INTEGER(i4) :: state          = MD_INT_CSTATE_INITIAL  ! [inout] Contact state
    REAL(wp)    :: length          = 0.0_wp                 ! [out]   Segment length
    REAL(wp)    :: tangent(3)     = 0.0_wp                 ! [out]   Tangent vector
    REAL(wp)    :: normal(3)      = 0.0_wp                 ! [out]   Normal vector
    REAL(wp)    :: centroid(3)    = 0.0_wp                 ! [out]   Centroid coords
    REAL(wp)    :: jacobian(4)    = 0.0_wp                 ! [out]   Jacobian values
    REAL(wp)    :: avg_pressure    = 0.0_wp                 ! [out]   Average pressure
    REAL(wp)    :: avg_traction    = 0.0_wp                 ! [out]   Average traction
  END TYPE MD_Int_Segment_Desc
```

### `MD_Int_Surface_Desc` (lines 275–294)

```fortran
  TYPE, PUBLIC :: MD_Int_Surface_Desc
    INTEGER(i4) :: id             = 0_i4                   ! [in]    Surface ID
    INTEGER(i4) :: n_nodes        = 0_i4                   ! [in]    Node count
    INTEGER(i4) :: n_segments     = 0_i4                   ! [in]    Segment count
    INTEGER(i4) :: coord_type     = MD_INT_COORD_3D        ! [in]    Coordinate type
    INTEGER(i4) :: print_flag     = 0_i4                   ! [in]    Print flag
    INTEGER(i4) :: port_flag      = 0_i4                   ! [in]    Port flag
    LOGICAL     :: is_closed      = .FALSE.                ! [in]    Closed surface
    LOGICAL     :: is_master      = .FALSE.                ! [in]    Master surface
    LOGICAL     :: is_rigid       = .FALSE.                ! [in]    Rigid body
    INTEGER(i4), ALLOCATABLE :: node_ids(:)                ! [in]    Node ID array
    INTEGER(i4), ALLOCATABLE :: dof_map(:,:)               ! [in]    DOF mapping
    REAL(wp), ALLOCATABLE    :: coords(:,:)                ! [in]    Reference coords
    REAL(wp), ALLOCATABLE    :: coords_current(:,:)        ! [inout] Current coords
    TYPE(MD_Int_Segment_Desc), ALLOCATABLE :: segments(:)  ! [inout] Segment array
    REAL(wp)    :: bbox_min(3)    = 0.0_wp                 ! [out]   Bounding box min
    REAL(wp)    :: bbox_max(3)    = 0.0_wp                 ! [out]   Bounding box max
    INTEGER(i4), ALLOCATABLE :: node_to_seg(:,:)           ! [in]    Node-to-segment map
    INTEGER(i4) :: max_seg_per_nod = 0_i4                  ! [in]    Max segments per node
  END TYPE MD_Int_Surface_Desc
```

### `MD_Int_FricParams_Algo` (lines 302–322)

```fortran
  TYPE, PUBLIC :: MD_Int_FricParams_Algo
    INTEGER(i4) :: model          = MD_INT_FMODEL_COULOMB  ! [in] Friction model
    REAL(wp)    :: mu_static      = 0.0_wp                 ! [in] Static friction coeff
    REAL(wp)    :: mu_kinetic     = 0.0_wp                 ! [in] Kinetic friction coeff
    REAL(wp)    :: tolerance      = 0.01_wp                ! [in] Friction tolerance
    REAL(wp)    :: slip_rate_ref  = 1.0_wp                 ! [in] Reference slip rate
    REAL(wp)    :: decay_coeff    = 0.0_wp                 ! [in] Decay coefficient
    LOGICAL     :: velocity_depend = .FALSE.               ! [in] Velocity dependent
    LOGICAL     :: pressure_depend = .FALSE.               ! [in] Pressure dependent
    INTEGER(i4) :: n_table_points = 0_i4                   ! [in] Table point count
    REAL(wp), ALLOCATABLE :: table_velocity(:)              ! [in] Velocity table
    REAL(wp), ALLOCATABLE :: table_mu(:)                    ! [in] Friction coeff table
    REAL(wp)    :: pressure_alpha = 0.0_wp                 ! [in] Pressure exponent
    REAL(wp)    :: pressure_ref   = 1.0E6_wp               ! [in] Reference pressure
    REAL(wp)    :: bond_strength  = 0.0_wp                 ! [in] Bond strength
    REAL(wp)    :: bond_delta_f   = 0.0_wp                 ! [in] Bond force increment
    REAL(wp)    :: damage         = 0.0_wp                 ! [inout] Damage variable
    REAL(wp)    :: damping_ratio  = 0.0_wp                 ! [in] Damping ratio
    REAL(wp)    :: damping_n      = 0.0_wp                 ! [in] Normal damping
    REAL(wp)    :: damping_t      = 0.0_wp                 ! [in] Tangent damping
  END TYPE MD_Int_FricParams_Algo
```

### `MD_Int_PairDef_Desc` (lines 330–359)

```fortran
  TYPE, PUBLIC :: MD_Int_PairDef_Desc
    INTEGER(i4) :: id              = 0_i4                  ! [in] Pair ID
    INTEGER(i4) :: master_surface  = 0_i4                  ! [in] Master surface ID
    INTEGER(i4) :: slave_surface_i = 0_i4                  ! [in] Slave surface ID
    INTEGER(i4) :: contact_type    = MD_INT_CTYPE_NODE_TO  ! [in] Contact type
    INTEGER(i4) :: enforcement_met = MD_INT_ENFORCE_PENALTY ! [in] Enforcement method
    INTEGER(i4) :: sliding_type    = MD_INT_SLIDING_FINITE ! [in] Sliding type
    INTEGER(i4) :: normal_behavior = MD_INT_NORMAL_HARD    ! [in] Normal behavior
    LOGICAL     :: active          = .TRUE.                ! [in] Active flag
    LOGICAL     :: is_self_contact = .FALSE.               ! [in] Self-contact flag
    REAL(wp)    :: penalty_normal   = 0.0_wp                ! [in] Normal penalty
    REAL(wp)    :: penalty_tangent  = 0.0_wp                ! [in] Tangent penalty
    REAL(wp)    :: penalty_scale    = 10.0_wp               ! [in] Penalty scale factor
    REAL(wp)    :: penalty_n        = 0.0_wp                ! [in] Penalty normal value
    REAL(wp)    :: penalty_t        = 0.0_wp                ! [in] Penalty tangent value
    REAL(wp)    :: adaptive_alpha_min = 1.0_wp              ! [in] Adaptive alpha min
    REAL(wp)    :: adaptive_alpha_max = 10.0_wp             ! [in] Adaptive alpha max
    REAL(wp)    :: adaptive_e_modu  = 0.0_wp                ! [in] Adaptive E modulus
    REAL(wp)    :: adaptive_h_min   = 0.0_wp                ! [in] Adaptive h min
    REAL(wp)    :: penalty_ratio_t  = 0.1_wp                ! [in] Penalty tangent ratio
    REAL(wp)    :: penetration_tol  = 1.0E-10_wp            ! [in] Penetration tolerance
    REAL(wp)    :: max_penetration  = 0.0_wp                ! [in] Max penetration
    LOGICAL     :: use_adaptive_pe = .FALSE.               ! [in] Adaptive penalty flag
    REAL(wp)    :: aug_lagrange_to  = 1.0E-6_wp             ! [in] Aug Lagrange tol
    INTEGER(i4) :: aug_lagrange_ma = 10_i4                 ! [in] Aug Lagrange max iter
    REAL(wp)    :: search_toleranc  = 0.0_wp                ! [in] Search tolerance
    REAL(wp)    :: gap_tolerance    = 1.0E-10_wp            ! [in] Gap tolerance
    REAL(wp)    :: initial_clearan  = 0.0_wp                ! [in] Initial clearance
    TYPE(MD_Int_FricParams_Algo) :: friction                ! [in] Friction parameters
  END TYPE MD_Int_PairDef_Desc
```

### `MD_Int_Candidate_Desc` (lines 367–371)

```fortran
  TYPE, PUBLIC :: MD_Int_Candidate_Desc
    INTEGER(i4) :: slave_node      = 0_i4                  ! [in] Slave node ID
    INTEGER(i4) :: master_segment  = 0_i4                  ! [in] Master segment ID
    REAL(wp)    :: distance        = 0.0_wp                ! [out] Distance
  END TYPE MD_Int_Candidate_Desc
```

### `MD_Int_Bucket_Desc` (lines 385–388)

```fortran
    TYPE :: MD_Int_Bucket_Desc
      INTEGER(i4) :: n_items = 0_i4                        ! [inout] Item count
      INTEGER(i4), ALLOCATABLE :: item_ids(:)              ! [inout] Item ID array
    END TYPE
```

### `MD_Int_BucketGrid_Ctx` (lines 379–390)

```fortran
  TYPE, PUBLIC :: MD_Int_BucketGrid_Ctx
    INTEGER(i4) :: nx = 0_i4                               ! [in] Grid X divisions
    INTEGER(i4) :: ny = 0_i4                               ! [in] Grid Y divisions
    INTEGER(i4) :: nz = 0_i4                               ! [in] Grid Z divisions
    REAL(wp)    :: origin(3)    = 0.0_wp                   ! [in] Grid origin
    REAL(wp)    :: cell_size(3) = 0.0_wp                   ! [in] Cell dimensions
    TYPE :: MD_Int_Bucket_Desc
      INTEGER(i4) :: n_items = 0_i4                        ! [inout] Item count
      INTEGER(i4), ALLOCATABLE :: item_ids(:)              ! [inout] Item ID array
    END TYPE
    TYPE(MD_Int_Bucket_Desc), ALLOCATABLE :: buckets(:,:,:) ! [inout] Bucket array
  END TYPE MD_Int_BucketGrid_Ctx
```

### `MD_Int_BVHNode_Desc` (lines 401–411)

```fortran
    TYPE :: MD_Int_BVHNode_Desc
      INTEGER(i4) :: id          = 0_i4                    ! [in] Node ID
      INTEGER(i4) :: left_child  = 0_i4                    ! [in] Left child index
      INTEGER(i4) :: right_child = 0_i4                    ! [in] Right child index
      INTEGER(i4) :: segment_id  = 0_i4                    ! [in] Segment ID (leaf)
      INTEGER(i4) :: first_prim  = 0_i4                    ! [in] First primitive index
      INTEGER(i4) :: n_prims     = 0_i4                    ! [in] Primitive count
      LOGICAL     :: is_leaf     = .FALSE.                 ! [in] Leaf flag
      REAL(wp)    :: bbox_min(3) = 0.0_wp                  ! [out] Bounding box min
      REAL(wp)    :: bbox_max(3) = 0.0_wp                  ! [out] Bounding box max
    END TYPE
```

### `MD_Int_BVHTree_Ctx` (lines 398–414)

```fortran
  TYPE, PUBLIC :: MD_Int_BVHTree_Ctx
    INTEGER(i4) :: n_nodes = 0_i4                          ! [in] Tree node count
    INTEGER(i4) :: root    = 0_i4                          ! [in] Root node index
    TYPE :: MD_Int_BVHNode_Desc
      INTEGER(i4) :: id          = 0_i4                    ! [in] Node ID
      INTEGER(i4) :: left_child  = 0_i4                    ! [in] Left child index
      INTEGER(i4) :: right_child = 0_i4                    ! [in] Right child index
      INTEGER(i4) :: segment_id  = 0_i4                    ! [in] Segment ID (leaf)
      INTEGER(i4) :: first_prim  = 0_i4                    ! [in] First primitive index
      INTEGER(i4) :: n_prims     = 0_i4                    ! [in] Primitive count
      LOGICAL     :: is_leaf     = .FALSE.                 ! [in] Leaf flag
      REAL(wp)    :: bbox_min(3) = 0.0_wp                  ! [out] Bounding box min
      REAL(wp)    :: bbox_max(3) = 0.0_wp                  ! [out] Bounding box max
    END TYPE
    TYPE(MD_Int_BVHNode_Desc), ALLOCATABLE :: nodes(:)     ! [inout] Tree nodes
    INTEGER(i4), ALLOCATABLE :: prim_indices(:)            ! [in] Primitive indices
  END TYPE MD_Int_BVHTree_Ctx
```

### `MD_Int_ContPair_State` (lines 422–450)

```fortran
  TYPE, PUBLIC :: MD_Int_ContPair_State
    INTEGER(i4) :: id              = 0_i4                  ! [in]    Pair ID
    INTEGER(i4) :: master_surf_id  = 0_i4                  ! [in]    Master surface ID
    INTEGER(i4) :: slave_surf_id   = 0_i4                  ! [in]    Slave surface ID
    INTEGER(i4) :: contact_type    = 0_i4                  ! [in]    Contact type
    INTEGER(i4) :: dimension       = 3_i4                  ! [in]    Spatial dimension
    REAL(wp)    :: search_toleranc  = 0.0_wp                ! [in]    Search tolerance
    REAL(wp)    :: gap_tolerance    = 1.0E-6_wp             ! [in]    Gap tolerance
    LOGICAL     :: is_self_contact = .FALSE.               ! [in]    Self-contact flag
    LOGICAL     :: active          = .TRUE.                ! [inout] Active flag
    LOGICAL     :: use_bucket_sear = .TRUE.                ! [in]    Use bucket search
    LOGICAL     :: use_bvh_search  = .FALSE.               ! [in]    Use BVH search
    INTEGER(i4) :: n_contact_point = 0_i4                  ! [inout] Contact point count
    INTEGER(i4), ALLOCATABLE :: contact_nodes(:)           ! [inout] Contact node IDs
    INTEGER(i4), ALLOCATABLE :: master_elements(:)         ! [inout] Master element IDs
    INTEGER(i4), ALLOCATABLE :: contact_state(:)           ! [inout] Per-point states
    REAL(wp), ALLOCATABLE    :: gaps(:)                    ! [inout] Gap values
    REAL(wp), ALLOCATABLE    :: normals(:,:)               ! [inout] Normal vectors
    REAL(wp), ALLOCATABLE    :: tangents(:,:)              ! [inout] Tangent vectors
    REAL(wp), ALLOCATABLE    :: xi_local(:,:)              ! [inout] Local coords
    REAL(wp), ALLOCATABLE    :: tangential_slip(:,:)       ! [inout] Tangential slip
    REAL(wp), ALLOCATABLE    :: contact_pressur(:)         ! [inout] Contact pressure
    REAL(wp), ALLOCATABLE    :: friction_force(:,:)        ! [inout] Friction forces
    TYPE(MD_Int_BucketGrid_Ctx), POINTER :: bucket_grid => NULL() ! [inout] Bucket grid
    TYPE(MD_Int_BVHTree_Ctx),    POINTER :: bvh_tree    => NULL() ! [inout] BVH tree
    INTEGER(i4), ALLOCATABLE :: prev_contact_no(:)         ! [inout] Previous contact nodes
    INTEGER(i4), ALLOCATABLE :: prev_master_ele(:)         ! [inout] Previous master elems
    REAL(wp), ALLOCATABLE    :: prev_xi_local(:,:)         ! [inout] Previous local coords
  END TYPE MD_Int_ContPair_State
```

### `MD_Int_PenaltyMethod_Arg` (lines 462–467)

```fortran
  TYPE, PUBLIC :: MD_Int_PenaltyMethod_Arg
    TYPE(MD_Int_ContNode_State), POINTER :: contact_nodes(:) => NULL() ! [in]
    REAL(wp), POINTER :: displacements(:) => NULL()                    ! [in]
    REAL(wp), POINTER :: velocities(:)    => NULL()                    ! [in]
    TYPE(MD_Int_AlgoCtrl_Algo)  :: control                             ! [in]
  END TYPE MD_Int_PenaltyMethod_Arg
```

### `MD_Int_PenaltyRes_Arg` (lines 474–478)

```fortran
  TYPE, PUBLIC :: MD_Int_PenaltyRes_Arg
    TYPE(MD_Int_ForceRes_State) :: forces                               ! [out]
    REAL(wp), POINTER :: stiffness(:,:) => NULL()                      ! [out]
    INTEGER(i4)       :: status = 0_i4                                 ! [out]
  END TYPE MD_Int_PenaltyRes_Arg
```

### `MD_Int_LagrangeMethod_Arg` (lines 485–489)

```fortran
  TYPE, PUBLIC :: MD_Int_LagrangeMethod_Arg
    TYPE(MD_Int_ContNode_State), POINTER :: contact_nodes(:) => NULL() ! [in]
    REAL(wp), POINTER :: displacements(:) => NULL()                    ! [in]
    TYPE(MD_Int_AlgoCtrl_Algo)  :: control                             ! [in]
  END TYPE MD_Int_LagrangeMethod_Arg
```

### `MD_Int_LagrangeRes_Arg` (lines 496–501)

```fortran
  TYPE, PUBLIC :: MD_Int_LagrangeRes_Arg
    REAL(wp), POINTER :: constraint_matr(:,:) => NULL()                ! [out]
    REAL(wp), POINTER :: constraint_rhs(:)    => NULL()                ! [out]
    REAL(wp), POINTER :: lagrange_multip(:)   => NULL()                ! [out]
    INTEGER(i4)       :: status = 0_i4                                 ! [out]
  END TYPE MD_Int_LagrangeRes_Arg
```

### `MD_Int_ForceResInit_Arg` (lines 508–510)

```fortran
  TYPE, PUBLIC :: MD_Int_ForceResInit_Arg
    INTEGER(i4) :: n_nodes = 0_i4                                      ! [in]
  END TYPE MD_Int_ForceResInit_Arg
```

### `MD_Int_ForceResInitOut_Arg` (lines 517–519)

```fortran
  TYPE, PUBLIC :: MD_Int_ForceResInitOut_Arg
    INTEGER(i4) :: status = 0_i4                                       ! [out]
  END TYPE MD_Int_ForceResInitOut_Arg
```

### `MD_Int_UpdateGeom_Arg` (lines 526–529)

```fortran
  TYPE, PUBLIC :: MD_Int_UpdateGeom_Arg
    TYPE(MD_Int_ContNode_State) :: contact_node                        ! [in]
    REAL(wp), POINTER :: displacements(:) => NULL()                    ! [in]
  END TYPE MD_Int_UpdateGeom_Arg
```

### `MD_Int_UpdateGeomRes_Arg` (lines 536–542)

```fortran
  TYPE, PUBLIC :: MD_Int_UpdateGeomRes_Arg
    REAL(wp)    :: gap          = 0.0_wp                               ! [out]
    REAL(wp)    :: n_vector(3)  = 0.0_wp                               ! [out]
    REAL(wp)    :: t1_vector(3) = 0.0_wp                               ! [out]
    REAL(wp)    :: t2_vector(3) = 0.0_wp                               ! [out]
    INTEGER(i4) :: status       = 0_i4                                  ! [out]
  END TYPE MD_Int_UpdateGeomRes_Arg
```

### `MD_Int_ApplyFric_Arg` (lines 549–553)

```fortran
  TYPE, PUBLIC :: MD_Int_ApplyFric_Arg
    TYPE(MD_Int_ContNode_State) :: contact_node                        ! [in]
    REAL(wp) :: relative_velocity(3) = 0.0_wp                          ! [in]
    TYPE(MD_Int_AlgoCtrl_Algo)  :: control                             ! [in]
  END TYPE MD_Int_ApplyFric_Arg
```

### `MD_Int_ApplyFricRes_Arg` (lines 560–564)

```fortran
  TYPE, PUBLIC :: MD_Int_ApplyFricRes_Arg
    REAL(wp)    :: tangent_force(2) = 0.0_wp                           ! [out]
    REAL(wp)    :: slip_rate(2)     = 0.0_wp                           ! [out]
    INTEGER(i4) :: status           = 0_i4                              ! [out]
  END TYPE MD_Int_ApplyFricRes_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `md_int_uinter_intf` | 574 | `SUBROUTINE md_int_uinter_intf(sigma, ddsddr, stiff, flux, ddfddt, ddfddr, &` |
| SUBROUTINE | `md_int_fric_intf` | 597 | `SUBROUTINE md_int_fric_intf(mu, ddmudp, ddmudv, press, slip, temp, &` |
| SUBROUTINE | `MD_Int_ContNode_Destroy` | 635 | `SUBROUTINE MD_Int_ContNode_Destroy(this)` |
| SUBROUTINE | `MD_Int_ForceRes_Init` | 655 | `SUBROUTINE MD_Int_ForceRes_Init(this, nNodes, status)` |
| SUBROUTINE | `MD_Int_ForceRes_Destroy` | 693 | `SUBROUTINE MD_Int_ForceRes_Destroy(this)` |
| FUNCTION | `MD_Int_CrossProduct` | 709 | `FUNCTION MD_Int_CrossProduct(a, b) RESULT(c)` |
| FUNCTION | `MD_Int_Dot3` | 723 | `FUNCTION MD_Int_Dot3(a, b) RESULT(val)` |
| FUNCTION | `MD_Int_HasInt` | 735 | `FUNCTION MD_Int_HasInt(arr, nUsed, val) RESULT(found)` |
| FUNCTION | `MD_Int_PointInAABB` | 755 | `PURE FUNCTION MD_Int_PointInAABB(point, bbox_min, bbox_max) RESULT(inside)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
