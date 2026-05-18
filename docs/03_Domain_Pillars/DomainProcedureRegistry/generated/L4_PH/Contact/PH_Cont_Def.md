# `PH_Cont_Def.f90`

- **Source**: `L4_PH/Contact/PH_Cont_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/PH_Cont_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Cont_Constr_Desc_Config` (lines 92–95)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Config
      INTEGER(i4) :: method = 1
      LOGICAL :: adaptive_penalty = .TRUE.
  END TYPE PH_Cont_Constr_Desc_Config
```

### `PH_Cont_Constr_Desc_Penalty` (lines 97–101)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Penalty
      REAL(wp) :: penalty_parameter = 1.0e6_wp
      REAL(wp) :: penalty_growth_factor = 2.0_wp
      REAL(wp) :: penalty_reduction_factor = 0.5_wp
  END TYPE PH_Cont_Constr_Desc_Penalty
```

### `PH_Cont_Constr_Desc_Config` (lines 103–106)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Config
      INTEGER(i4) :: method = 1
      LOGICAL :: adaptive_penalty = .TRUE.
  END TYPE PH_Cont_Constr_Desc_Config
```

### `PH_Cont_Constr_Desc_Penalty` (lines 108–112)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Penalty
      REAL(wp) :: penalty_parameter = 1.0e6_wp
      REAL(wp) :: penalty_growth_factor = 2.0_wp
      REAL(wp) :: penalty_reduction_factor = 0.5_wp
  END TYPE PH_Cont_Constr_Desc_Penalty
```

### `PH_Cont_Constr_Desc` (lines 114–117)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Desc
      TYPE(PH_Cont_Constr_Desc_Config) :: config
      TYPE(PH_Cont_Constr_Desc_Penalty) :: penalty
  END TYPE PH_Cont_Constr_Desc
```

### `PH_Fric_Cfg_Model` (lines 120–123)

```fortran
  TYPE, PUBLIC :: PH_Fric_Cfg_Model
      INTEGER(i4) :: model_type = 1  ! 1=Coulomb, 2=Tresca, 3=Rate-dependent, 4=Viscoelastic
      LOGICAL :: stick_slip_transition = .TRUE.
  END TYPE PH_Fric_Cfg_Model
```

### `PH_Fric_Cfg_Coeff` (lines 126–129)

```fortran
  TYPE, PUBLIC :: PH_Fric_Cfg_Coeff
      REAL(wp) :: mu_static = ZERO
      REAL(wp) :: mu_dynamic = ZERO
  END TYPE PH_Fric_Cfg_Coeff
```

### `PH_Fric_Cfg_Physical` (lines 132–136)

```fortran
  TYPE, PUBLIC :: PH_Fric_Cfg_Physical
      REAL(wp) :: friction_stiffness = ZERO
      REAL(wp) :: critical_slip_velocity = ZERO
      REAL(wp) :: regularization_parameter = ZERO
  END TYPE PH_Fric_Cfg_Physical
```

### `PH_Cont_Friction_Desc` (lines 139–144)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Desc
      TYPE(PH_Fric_Cfg_Model)    :: model
      TYPE(PH_Fric_Cfg_Coeff)    :: coeff
      TYPE(PH_Fric_Cfg_Physical) :: phys
      ! NOTE: Flat fields removed after P2 migration (zero external references verified)
  END TYPE PH_Cont_Friction_Desc
```

### `PH_Cont_Search_Desc_Algo` (lines 147–149)

```fortran
  TYPE, PUBLIC :: PH_Cont_Search_Desc_Algo
      INTEGER(i4) :: search_algorithm = 1
  END TYPE PH_Cont_Search_Desc_Algo
```

### `PH_Cont_Search_Desc_Params` (lines 151–155)

```fortran
  TYPE, PUBLIC :: PH_Cont_Search_Desc_Params
      REAL(wp) :: search_radius = ZERO
      REAL(wp) :: tolerance = 1.0e-6_wp
      LOGICAL :: adaptive_search = .TRUE.
  END TYPE PH_Cont_Search_Desc_Params
```

### `PH_Cont_Search_Desc_Algo` (lines 157–159)

```fortran
  TYPE, PUBLIC :: PH_Cont_Search_Desc_Algo
      INTEGER(i4) :: search_algorithm = 1
  END TYPE PH_Cont_Search_Desc_Algo
```

### `PH_Cont_Search_Desc_Params` (lines 161–165)

```fortran
  TYPE, PUBLIC :: PH_Cont_Search_Desc_Params
      REAL(wp) :: search_radius = ZERO
      REAL(wp) :: tolerance = 1.0e-6_wp
      LOGICAL :: adaptive_search = .TRUE.
  END TYPE PH_Cont_Search_Desc_Params
```

### `PH_Cont_Search_Desc` (lines 167–170)

```fortran
  TYPE, PUBLIC :: PH_Cont_Search_Desc
      TYPE(PH_Cont_Search_Desc_Algo) :: algo
      TYPE(PH_Cont_Search_Desc_Params) :: params
  END TYPE PH_Cont_Search_Desc
```

### `PH_Cont_Cfg_Penalty_Desc` (lines 173–176)

```fortran
  TYPE, PUBLIC :: PH_Cont_Cfg_Penalty_Desc
      REAL(wp) :: penalty_normal  = 1.0E6_wp   ! normal penalty stiffness
      REAL(wp) :: penalty_tangent = 1.0E5_wp   ! tangential penalty
  END TYPE PH_Cont_Cfg_Penalty_Desc
```

### `PH_Cont_Cfg_Tol_Desc` (lines 179–182)

```fortran
  TYPE, PUBLIC :: PH_Cont_Cfg_Tol_Desc
      REAL(wp) :: gap_tolerance   = 1.0E-6_wp  ! gap tolerance for open/closed
      REAL(wp) :: mu_friction     = 0.0_wp     ! Coulomb friction coefficient
  END TYPE PH_Cont_Cfg_Tol_Desc
```

### `PH_Cont_Desc` (lines 185–194)

```fortran
  TYPE, PUBLIC :: PH_Cont_Desc
      TYPE(PH_Cont_Constr_Desc) :: constr
      TYPE(PH_Cont_Friction_Desc) :: friction
      TYPE(PH_Cont_Search_Desc) :: search
      TYPE(PH_Cont_Cfg_Penalty_Desc) :: cfg_penalty
      TYPE(PH_Cont_Cfg_Tol_Desc) :: cfg_tol
      INTEGER(i4) :: contact_pair_id = 0
      INTEGER(i4) :: slave_surface_id = 0
      INTEGER(i4) :: master_surface_id = 0
  END TYPE PH_Cont_Desc
```

### `PH_Cont_SearchStrategy_Arg` (lines 202–211)

```fortran
  TYPE, PUBLIC :: PH_Cont_SearchStrategy_Arg
    REAL(wp), POINTER :: slave_coords(:,:)  => NULL()  ! [IN]  (3, n_slave)
    REAL(wp), POINTER :: master_coords(:,:) => NULL()  ! [IN]  (3, n_master)
    REAL(wp) :: search_radius = 0.0_wp                 ! [IN]  search radius
    INTEGER(i4) :: n_candidates = 0                    ! [OUT] found candidates
    INTEGER(i4), POINTER :: candidate_slave(:)  => NULL()  ! [OUT] slave IDs
    INTEGER(i4), POINTER :: candidate_master(:) => NULL()  ! [OUT] master IDs
    REAL(wp), POINTER :: candidate_dist(:)      => NULL()  ! [OUT] distances
    TYPE(ErrorStatusType) :: status                    ! [OUT]
  END TYPE PH_Cont_SearchStrategy_Arg
```

### `PH_Cont_Constr_Algo_Iter` (lines 229–231)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Iter
      INTEGER(i4) :: max_iterations = 50
  END TYPE PH_Cont_Constr_Algo_Iter
```

### `PH_Cont_Constr_Algo_Tol` (lines 233–236)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Tol
      REAL(wp) :: tolerance = 1.0e-6_wp
      REAL(wp) :: relative_tolerance = 1.0e-6_wp
  END TYPE PH_Cont_Constr_Algo_Tol
```

### `PH_Cont_Constr_Algo_Solver` (lines 238–241)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Solver
      INTEGER(i4) :: optimization_strategy = 1
      REAL(wp) :: convergence_acceleration = 1.0_wp
  END TYPE PH_Cont_Constr_Algo_Solver
```

### `PH_Cont_Constr_Algo_Iter` (lines 243–245)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Iter
      INTEGER(i4) :: max_iterations = 50
  END TYPE PH_Cont_Constr_Algo_Iter
```

### `PH_Cont_Constr_Algo_Tol` (lines 247–250)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Tol
      REAL(wp) :: tolerance = 1.0e-6_wp
      REAL(wp) :: relative_tolerance = 1.0e-6_wp
  END TYPE PH_Cont_Constr_Algo_Tol
```

### `PH_Cont_Constr_Algo_Solver` (lines 252–255)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Solver
      INTEGER(i4) :: optimization_strategy = 1
      REAL(wp) :: convergence_acceleration = 1.0_wp
  END TYPE PH_Cont_Constr_Algo_Solver
```

### `PH_Cont_Constr_Algo` (lines 257–261)

```fortran
  TYPE, PUBLIC :: PH_Cont_Constr_Algo
      TYPE(PH_Cont_Constr_Algo_Iter) :: iter
      TYPE(PH_Cont_Constr_Algo_Tol) :: tol
      TYPE(PH_Cont_Constr_Algo_Solver) :: solver
  END TYPE PH_Cont_Constr_Algo
```

### `PH_Cont_Friction_Algo_Rate` (lines 264–268)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Rate
      REAL(wp) :: decay_rate = ZERO
      REAL(wp) :: pressure_exponent = ZERO
      REAL(wp) :: transition_velocity = ZERO
  END TYPE PH_Cont_Friction_Algo_Rate
```

### `PH_Cont_Friction_Algo_Config` (lines 270–272)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Config
      LOGICAL :: rate_dependency = .FALSE.
  END TYPE PH_Cont_Friction_Algo_Config
```

### `PH_Cont_Friction_Algo_Rate` (lines 274–278)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Rate
      REAL(wp) :: decay_rate = ZERO
      REAL(wp) :: pressure_exponent = ZERO
      REAL(wp) :: transition_velocity = ZERO
  END TYPE PH_Cont_Friction_Algo_Rate
```

### `PH_Cont_Friction_Algo_Config` (lines 280–282)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Config
      LOGICAL :: rate_dependency = .FALSE.
  END TYPE PH_Cont_Friction_Algo_Config
```

### `PH_Cont_Friction_Algo` (lines 284–287)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Algo
      TYPE(PH_Cont_Friction_Algo_Rate) :: rate
      TYPE(PH_Cont_Friction_Algo_Config) :: config
  END TYPE PH_Cont_Friction_Algo
```

### `PH_Cont_Stp_Method_Algo` (lines 290–293)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stp_Method_Algo
      INTEGER(i4) :: method       = 1        ! 1=penalty, 2=Lagrange, 3=augmented
      REAL(wp)    :: scale_factor = 1.0_wp   ! penalty scaling factor
  END TYPE PH_Cont_Stp_Method_Algo
```

### `PH_Cont_Algo` (lines 296–302)

```fortran
  TYPE, PUBLIC :: PH_Cont_Algo
      TYPE(PH_Cont_Constr_Algo) :: constr
      TYPE(PH_Cont_Friction_Algo) :: friction
      TYPE(PH_Cont_Stp_Method_Algo) :: stp_method
      ! --- Phase 6B: Procedure-as-Parameter strategy pointer ---
      PROCEDURE(ContactSearchStrategy_Ifc), POINTER, NOPASS :: search_strategy => NULL()
  END TYPE PH_Cont_Algo
```

### `PH_Cont_Lcl_Pos_Ctx` (lines 309–312)

```fortran
  TYPE, PUBLIC :: PH_Cont_Lcl_Pos_Ctx
    REAL(wp) :: x_slave(3)      = 0.0_wp   ! slave point coords
    REAL(wp) :: x_master(3)     = 0.0_wp   ! master point coords
  END TYPE PH_Cont_Lcl_Pos_Ctx
```

### `PH_Cont_Lcl_Normal_Ctx` (lines 315–317)

```fortran
  TYPE, PUBLIC :: PH_Cont_Lcl_Normal_Ctx
    REAL(wp) :: normal(3)       = 0.0_wp   ! contact normal
  END TYPE PH_Cont_Lcl_Normal_Ctx
```

### `PH_Cont_Lcl_Stiff_Ctx` (lines 320–322)

```fortran
  TYPE, PUBLIC :: PH_Cont_Lcl_Stiff_Ctx
    REAL(wp) :: K_contact(24,24)= 0.0_wp   ! contact stiffness contribution
  END TYPE PH_Cont_Lcl_Stiff_Ctx
```

### `PH_Cont_Ctx` (lines 325–329)

```fortran
  TYPE, PUBLIC :: PH_Cont_Ctx
    TYPE(PH_Cont_Lcl_Pos_Ctx)   :: lcl_pos
    TYPE(PH_Cont_Lcl_Normal_Ctx):: lcl_normal
    TYPE(PH_Cont_Lcl_Stiff_Ctx) :: lcl_stiff
  END TYPE PH_Cont_Ctx
```

### `PH_Contact_InterfaceCtx` (lines 341–357)

```fortran
  TYPE, PUBLIC :: PH_Contact_InterfaceCtx
    !-- Gap and slip
    REAL(wp) :: gap = 0.0_wp        ! GAP    current contact gap
    REAL(wp) :: slip1 = 0.0_wp      ! SLIP1  tangent slip direction 1
    REAL(wp) :: slip2 = 0.0_wp      ! SLIP2  tangent slip direction 2
    !-- Contact conditions
    REAL(wp) :: pressure = 0.0_wp   ! PRES   normal contact pressure
    REAL(wp) :: temp = 0.0_wp       ! TEMP   contact temperature
    !-- Contact point info
    REAL(wp) :: coords(3) = 0.0_wp  ! COORDS contact point coordinates
    !-- Identification
    INTEGER(i4) :: elem_id = 0      ! NOEL   contact element
    INTEGER(i4) :: integ_pt_id = 0  ! NPT    integration point
    !-- Tangent directions
    REAL(wp) :: tang1(3) = 0.0_wp   ! Tangent direction 1
    REAL(wp) :: tang2(3) = 0.0_wp   ! Tangent direction 2
  END TYPE PH_Contact_InterfaceCtx
```

### `PH_Contact_VUINTER_Ctx` (lines 380–394)

```fortran
  TYPE, PUBLIC :: PH_Contact_VUINTER_Ctx
    INTEGER(i4) :: nblock = 1_i4     ! NBLOCK: block size
    INTEGER(i4) :: nfdir  = 2_i4     ! NFDIR: friction/tangential directions
    INTEGER(i4) :: nshr   = 1_i4     ! NSHR: shear components
    !-- Block arrays [nblock]
    REAL(wp), POINTER :: gap_blk(:)      ! Gap at each contact point
    REAL(wp), POINTER :: slip1_blk(:)    ! Slip dir-1
    REAL(wp), POINTER :: slip2_blk(:)    ! Slip dir-2
    REAL(wp), POINTER :: pres_blk(:)     ! Normal pressure
    REAL(wp), POINTER :: temp_blk(:)     ! Temperature at contact
    REAL(wp), POINTER :: coords_blk(:,:) ! Contact coordinates [nblock,3]
    !-- State variables block [nblock, nstatv]
    REAL(wp), POINTER :: svars_blk(:,:)
    INTEGER(i4) :: nstatv = 0_i4
  END TYPE PH_Contact_VUINTER_Ctx
```

### `PH_Contact_GAPCON_Ctx` (lines 398–409)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_Ctx
    REAL(wp) :: gap      = 0.0_wp    ! GAP: current gap [m]
    REAL(wp) :: pressure = 0.0_wp    ! Pressure at interface [Pa]
    REAL(wp) :: temp1    = 0.0_wp    ! Surface 1 temperature [K]
    REAL(wp) :: temp2    = 0.0_wp    ! Surface 2 temperature [K]
    REAL(wp) :: coords(3) = 0.0_wp   ! Contact point coordinates
    INTEGER(i4) :: node_id = 0_i4   ! NOEL (node pair identification)
    !-- Output
    REAL(wp) :: cond     = 0.0_wp    ! Gap conductance [W/(m²·K)]
    REAL(wp) :: dcond_dgap  = 0.0_wp ! d(cond)/d(gap) Jacobian
    REAL(wp) :: dcond_dpres = 0.0_wp ! d(cond)/d(pres) Jacobian
  END TYPE PH_Contact_GAPCON_Ctx
```

### `PH_Contact_UINTER_Ctx` (lines 413–426)

```fortran
  TYPE, PUBLIC :: PH_Contact_UINTER_Ctx
    REAL(wp), POINTER :: coords(:,:)  ! I COORDS   [ndim, 2] master/slave nodes
    REAL(wp), POINTER :: cdisp(:)     ! I CDISP    contact displacement [ndim]
    REAL(wp), POINTER :: cdispdot(:)  ! I CDISPDOT relative velocity
    REAL(wp) :: temp(2)   = 0.0_wp   ! I TEMP(2)  temperatures at nodes
    REAL(wp) :: dtemp(2)  = 0.0_wp   ! I DTEMP(2) temperature increments
    REAL(wp) :: time(2)   = 0.0_wp   ! I TIME(2)
    REAL(wp) :: dtime     = 0.0_wp   ! I DTIME
    INTEGER(i4) :: noel   = 0_i4
    INTEGER(i4) :: npt    = 0_i4
    INTEGER(i4) :: kstep  = 0_i4
    INTEGER(i4) :: kinc   = 0_i4
    INTEGER(i4) :: ndim   = 3_i4
  END TYPE PH_Contact_UINTER_Ctx
```

### `PH_Contact_GAPUNIT_Ctx_Geom` (lines 429–433)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Geom
    REAL(wp) :: gap      = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
    REAL(wp) :: coords(3)= 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Geom
```

### `PH_Contact_GAPUNIT_Ctx_Thermal` (lines 435–438)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Thermal
    REAL(wp) :: temp1    = 0.0_wp
    REAL(wp) :: temp2    = 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Thermal
```

### `PH_Contact_GAPUNIT_Ctx_Geom` (lines 440–444)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Geom
    REAL(wp) :: gap      = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
    REAL(wp) :: coords(3)= 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Geom
```

### `PH_Contact_GAPUNIT_Ctx_Thermal` (lines 446–449)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Thermal
    REAL(wp) :: temp1    = 0.0_wp
    REAL(wp) :: temp2    = 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Thermal
```

### `PH_Contact_GAPUNIT_Ctx` (lines 451–454)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx
    TYPE(PH_Contact_GAPUNIT_Ctx_Geom) :: geom
    TYPE(PH_Contact_GAPUNIT_Ctx_Thermal) :: thermal
  END TYPE PH_Contact_GAPUNIT_Ctx
```

### `PH_Cont_Geometry_State` (lines 461–468)

```fortran
  TYPE, PUBLIC :: PH_Cont_Geometry_State
      REAL(wp) :: gap = ZERO
      REAL(wp) :: penetration = ZERO
      REAL(wp) :: previous_gap = ZERO
      REAL(wp), ALLOCATABLE :: normal_vector(:)    ! (3) - Unit normal
      REAL(wp), ALLOCATABLE :: tangent_vector1(:)  ! (3) - First tangent
      REAL(wp), ALLOCATABLE :: tangent_vector2(:)  ! (3) - Second tangent
  END TYPE PH_Cont_Geometry_State
```

### `PH_Cont_Force_State` (lines 471–479)

```fortran
  TYPE, PUBLIC :: PH_Cont_Force_State
      REAL(wp), ALLOCATABLE :: normal_force(:)     ! (3) - Normal force vector
      REAL(wp), ALLOCATABLE :: friction_force(:)   ! (3) - Friction force vector
      REAL(wp) :: normal_force_magnitude = ZERO
      REAL(wp) :: friction_force_magnitude = ZERO
      REAL(wp), ALLOCATABLE :: contact_traction(:)  ! (3) - Total traction
      REAL(wp) :: contact_pressure = ZERO
      REAL(wp) :: shear_traction = ZERO
  END TYPE PH_Cont_Force_State
```

### `PH_Cont_Stiffness_State_Matrix` (lines 482–485)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix
```

### `PH_Cont_Stiffness_State_Scalar` (lines 487–490)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar
```

### `PH_Cont_Stiffness_State_Matrix` (lines 492–495)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix
```

### `PH_Cont_Stiffness_State_Scalar` (lines 497–500)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar
```

### `PH_Cont_Stiffness_State_Matrix` (lines 502–505)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix
```

### `PH_Cont_Stiffness_State_Scalar` (lines 507–510)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar
```

### `PH_Cont_Stiffness_State_Matrix` (lines 512–515)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix
```

### `PH_Cont_Stiffness_State_Scalar` (lines 517–520)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar
```

### `PH_Cont_Stiffness_State` (lines 522–525)

```fortran
  TYPE, PUBLIC :: PH_Cont_Stiffness_State
      TYPE(PH_Cont_Stiffness_State_Matrix) :: matrix
      TYPE(PH_Cont_Stiffness_State_Scalar) :: scalar
  END TYPE PH_Cont_Stiffness_State
```

### `PH_Cont_Friction_State_Slip` (lines 528–533)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip
```

### `PH_Cont_Friction_State_Slip` (lines 535–540)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip
```

### `PH_Cont_Friction_State_Slip` (lines 542–547)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip
```

### `PH_Cont_Friction_State_Slip` (lines 549–554)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip
```

### `PH_Cont_Friction_State` (lines 556–559)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_State
      TYPE(PH_Cont_Friction_State_Slip) :: slip
      INTEGER(i4) :: friction_state = 0
  END TYPE PH_Cont_Friction_State
```

### `PH_Cont_Convergence_State` (lines 562–572)

```fortran
  TYPE, PUBLIC :: PH_Cont_Convergence_State
      REAL(wp) :: residual_norm = ZERO
      REAL(wp) :: residual_norm_previous = ZERO
      REAL(wp) :: convergence_rate = ZERO
      INTEGER(i4) :: iteration_count = 0
      LOGICAL :: force_converged = .FALSE.
      LOGICAL :: displacement_converged = .FALSE.
      LOGICAL :: gap_converged = .FALSE.
      LOGICAL :: friction_converged = .FALSE.
      CHARACTER(LEN=50) :: convergence_method = "Relative"
  END TYPE PH_Cont_Convergence_State
```

### `PH_Cont_Itr_Quick_State_Force` (lines 575–578)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force
```

### `PH_Cont_Itr_Quick_State_Geom` (lines 580–583)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom
```

### `PH_Cont_Itr_Quick_State_Force` (lines 585–588)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force
```

### `PH_Cont_Itr_Quick_State_Geom` (lines 590–593)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom
```

### `PH_Cont_Itr_Quick_State_Force` (lines 595–598)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force
```

### `PH_Cont_Itr_Quick_State_Geom` (lines 600–603)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom
```

### `PH_Cont_Itr_Quick_State_Force` (lines 605–608)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force
```

### `PH_Cont_Itr_Quick_State_Geom` (lines 610–613)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom
```

### `PH_Cont_Itr_Quick_State` (lines 615–619)

```fortran
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State
      INTEGER(i4) :: contact_status = 0
      TYPE(PH_Cont_Itr_Quick_State_Force) :: force
      TYPE(PH_Cont_Itr_Quick_State_Geom) :: geom
  END TYPE PH_Cont_Itr_Quick_State
```

### `PH_Cont_State` (lines 622–630)

```fortran
  TYPE, PUBLIC :: PH_Cont_State
      INTEGER(i4) :: contact_state = 0  ! 0=separate, 1=contact, 2=sticking, 3=sliding
      TYPE(PH_Cont_Geometry_State) :: geometry
      TYPE(PH_Cont_Force_State) :: force
      TYPE(PH_Cont_Stiffness_State) :: stiffness
      TYPE(PH_Cont_Friction_State) :: friction
      TYPE(PH_Cont_Convergence_State) :: convergence
      TYPE(PH_Cont_Itr_Quick_State) :: itr_quick
  END TYPE PH_Cont_State
```

### `PH_Contact_InterfaceState` (lines 640–654)

```fortran
  TYPE, PUBLIC :: PH_Contact_InterfaceState
    !-- Contact traction output
    REAL(wp) :: traction_n  = 0.0_wp   ! Normal traction (pressure) [Pa]
    REAL(wp) :: traction_t1 = 0.0_wp   ! Shear traction dir-1 [Pa]
    REAL(wp) :: traction_t2 = 0.0_wp   ! Shear traction dir-2 [Pa]
    !-- Jacobian (AKI/BKI in UINTER)
    REAL(wp) :: dtn_dgap     = 0.0_wp  ! dtraction_n/dgap
    REAL(wp) :: dtt1_dslip1  = 0.0_wp  ! dtraction_t1/dslip1
    REAL(wp) :: dtt2_dslip2  = 0.0_wp  ! dtraction_t2/dslip2
    !-- State variables
    REAL(wp), ALLOCATABLE :: svars(:)  ! Solution-dependent state variables
    !-- Convergence bookkeeping
    LOGICAL     :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_InterfaceState
```

### `PH_Contact_UINTER_State_Traction` (lines 659–663)

```fortran
  TYPE, PUBLIC :: PH_Contact_UINTER_State_Traction
    REAL(wp) :: traction_n  = 0.0_wp
    REAL(wp) :: traction_t1 = 0.0_wp
    REAL(wp) :: traction_t2 = 0.0_wp
  END TYPE PH_Contact_UINTER_State_Traction
```

### `PH_Contact_UINTER_State_Jacobian` (lines 665–669)

```fortran
  TYPE, PUBLIC :: PH_Contact_UINTER_State_Jacobian
    REAL(wp) :: dtn_dgap     = 0.0_wp
    REAL(wp) :: dtt1_dslip1  = 0.0_wp
    REAL(wp) :: dtt2_dslip2  = 0.0_wp
  END TYPE PH_Contact_UINTER_State_Jacobian
```

### `PH_Contact_UINTER_State` (lines 672–675)

```fortran
  TYPE, PUBLIC :: PH_Contact_UINTER_State
    TYPE(PH_Contact_UINTER_State_Traction) :: traction
    TYPE(PH_Contact_UINTER_State_Jacobian) :: jacobian
  END TYPE PH_Contact_UINTER_State
```

### `PH_Contact_VUINTER_State` (lines 679–686)

```fortran
  TYPE, PUBLIC :: PH_Contact_VUINTER_State
    REAL(wp), ALLOCATABLE :: traction_blk(:,:)   ! [nblock, 3] output tractions
    REAL(wp), ALLOCATABLE :: dtraction_blk(:,:,:)! [nblock, 3, 3] Jacobian
    REAL(wp), ALLOCATABLE :: svars_blk(:,:)      ! [nblock, nsvars]
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_VUINTER_State
```

### `PH_Contact_GAPCON_State_Conduct` (lines 689–694)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct
```

### `PH_Contact_GAPCON_State_Conduct` (lines 696–701)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct
```

### `PH_Contact_GAPCON_State_Conduct` (lines 703–708)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct
```

### `PH_Contact_GAPCON_State_Conduct` (lines 710–715)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct
```

### `PH_Contact_GAPCON_State` (lines 717–720)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_State
    REAL(wp) :: gap = 0.0_wp
    TYPE(PH_Contact_GAPCON_State_Conduct) :: conduct
  END TYPE PH_Contact_GAPCON_State
```

### `PH_Contact_GAPUNIT_State` (lines 724–731)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_State
    REAL(wp) :: unit_cond     = 0.0_wp  ! OUT: unit conductance [W/(m²·K)] or [A/V]
    REAL(wp) :: dcond_dgap    = 0.0_wp  ! OUT: d(cond)/d(gap)
    REAL(wp) :: dcond_dtemp1  = 0.0_wp  ! OUT: d(cond)/d(T1)
    REAL(wp) :: dcond_dtemp2  = 0.0_wp  ! OUT: d(cond)/d(T2)
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_GAPUNIT_State
```

### `PH_Cont_PenaltyForce_Arg` (lines 740–744)

```fortran
  TYPE, PUBLIC :: PH_Cont_PenaltyForce_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: penalty                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_PenaltyForce_Arg
```

### `PH_Cont_PenaltyStiffness_Arg` (lines 750–753)

```fortran
  TYPE, PUBLIC :: PH_Cont_PenaltyStiffness_Arg
    REAL(wp) :: penalty                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_PenaltyStiffness_Arg
```

### `PH_Cont_LagrangeForce_Arg` (lines 759–762)

```fortran
  TYPE, PUBLIC :: PH_Cont_LagrangeForce_Arg
    REAL(wp) :: lambda                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_LagrangeForce_Arg
```

### `PH_Cont_AugLagForce_Arg` (lines 768–773)

```fortran
  TYPE, PUBLIC :: PH_Cont_AugLagForce_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: penalty                   ! [IN]
    REAL(wp) :: lambda                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AugLagForce_Arg
```

### `PH_Cont_AugLagUpdate_Arg` (lines 779–785)

```fortran
  TYPE, PUBLIC :: PH_Cont_AugLagUpdate_Arg
    REAL(wp) :: gap              ! Gap value (negative = penetration)                   ! [IN]
    REAL(wp) :: penalty          ! Penalty parameter (rho)                   ! [IN]
    REAL(wp) :: lambda           ! Current Lagrange multiplier                   ! [IN]
    REAL(wp) :: lambda_updated   ! Updated Lagrange multiplier                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AugLagUpdate_Arg
```

### `PH_Cont_CoulombFriction_Arg` (lines 791–795)

```fortran
  TYPE, PUBLIC :: PH_Cont_CoulombFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_CoulombFriction_Arg
```

### `PH_Cont_StickSlip_Arg` (lines 801–807)

```fortran
  TYPE, PUBLIC :: PH_Cont_StickSlip_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    REAL(wp) :: friction_stiffness                   ! [IN]
    LOGICAL :: is_sticking                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_StickSlip_Arg
```

### `PH_Cont_ComputeSlip_Arg` (lines 813–815)

```fortran
  TYPE, PUBLIC :: PH_Cont_ComputeSlip_Arg
    REAL(wp) :: time_step                   ! [IN]
  END TYPE PH_Cont_ComputeSlip_Arg
```

### `PH_Cont_FrictionStiffness_Arg` (lines 821–824)

```fortran
  TYPE, PUBLIC :: PH_Cont_FrictionStiffness_Arg
    REAL(wp) :: friction_stiffness                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_FrictionStiffness_Arg
```

### `PH_Cont_ExponentialFriction_Arg` (lines 830–835)

```fortran
  TYPE, PUBLIC :: PH_Cont_ExponentialFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    REAL(wp) :: decay_rate                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ExponentialFriction_Arg
```

### `PH_Cont_PressureDependentFriction_Arg` (lines 841–847)

```fortran
  TYPE, PUBLIC :: PH_Cont_PressureDependentFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: contact_area                   ! [IN]
    REAL(wp) :: friction_coeff_base                   ! [IN]
    REAL(wp) :: pressure_exponent                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_PressureDependentFriction_Arg
```

### `PH_Cont_VelocityDependentFriction_Arg` (lines 853–859)

```fortran
  TYPE, PUBLIC :: PH_Cont_VelocityDependentFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff_static                   ! [IN]
    REAL(wp) :: friction_coeff_kinetic                   ! [IN]
    REAL(wp) :: transition_velocity                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_VelocityDependentFriction_Arg
```

### `PH_Cont_Gap_Arg` (lines 869–871)

```fortran
  TYPE, PUBLIC :: PH_Cont_Gap_Arg
    REAL(wp) :: gap                   ! [OUT]
  END TYPE PH_Cont_Gap_Arg
```

### `PH_Cont_Normal_Arg` (lines 877–879)

```fortran
  TYPE, PUBLIC :: PH_Cont_Normal_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Normal_Arg
```

### `PH_Cont_StateCheck_Arg` (lines 885–889)

```fortran
  TYPE, PUBLIC :: PH_Cont_StateCheck_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: tolerance                   ! [IN]
    LOGICAL :: is_contact                   ! [OUT]
  END TYPE PH_Cont_StateCheck_Arg
```

### `PH_Cont_NearestPoint_Arg` (lines 895–899)

```fortran
  TYPE, PUBLIC :: PH_Cont_NearestPoint_Arg
    REAL(wp) :: parameter                   ! [OUT]
    REAL(wp) :: distance                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_NearestPoint_Arg
```

### `PH_Cont_Penetration_Arg` (lines 905–908)

```fortran
  TYPE, PUBLIC :: PH_Cont_Penetration_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: penetration                   ! [OUT]
  END TYPE PH_Cont_Penetration_Arg
```

### `PH_Cont_AlgorithmFramework_Arg` (lines 918–922)

```fortran
  TYPE, PUBLIC :: PH_Cont_AlgorithmFramework_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: dt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AlgorithmFramework_Arg
```

### `PH_Cont_ConvergenceCheck_Arg` (lines 928–934)

```fortran
  TYPE, PUBLIC :: PH_Cont_ConvergenceCheck_Arg
    REAL(wp) :: residual                   ! [IN]
    REAL(wp) :: tolerance                   ! [IN]
    INTEGER(i4) :: max_iterations                   ! [IN]
    LOGICAL :: converged                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ConvergenceCheck_Arg
```

### `PH_Cont_SearchPairs_Arg` (lines 940–942)

```fortran
  TYPE, PUBLIC :: PH_Cont_SearchPairs_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_SearchPairs_Arg
```

### `PH_Cont_DetectPenetration_Arg` (lines 948–950)

```fortran
  TYPE, PUBLIC :: PH_Cont_DetectPenetration_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_DetectPenetration_Arg
```

### `PH_Cont_CalculateGap_Arg` (lines 956–958)

```fortran
  TYPE, PUBLIC :: PH_Cont_CalculateGap_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_CalculateGap_Arg
```

### `PH_Cont_ApplyConstraints_Arg` (lines 964–966)

```fortran
  TYPE, PUBLIC :: PH_Cont_ApplyConstraints_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ApplyConstraints_Arg
```

### `PH_Cont_UpdateFriction_Arg` (lines 972–974)

```fortran
  TYPE, PUBLIC :: PH_Cont_UpdateFriction_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_UpdateFriction_Arg
```

### `PH_Contact_UINTER_Algo` (lines 986–991)

```fortran
  TYPE, PUBLIC :: PH_Contact_UINTER_Algo
    INTEGER(i4) :: max_iter   = 20_i4
    REAL(wp)    :: tol_stress = 1.0e-8_wp
    LOGICAL     :: thermal    = .FALSE.   ! include thermal flux
    LOGICAL     :: symmetric  = .TRUE.    ! symmetric contact stiffness
  END TYPE PH_Contact_UINTER_Algo
```

### `PH_Contact_VUINTER_Algo` (lines 994–998)

```fortran
  TYPE, PUBLIC :: PH_Contact_VUINTER_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: thermal    = .FALSE.
    REAL(wp)    :: tol_stress = 1.0e-8_wp
  END TYPE PH_Contact_VUINTER_Algo
```

### `PH_Contact_GAPCON_Algo` (lines 1001–1005)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPCON_Algo
    REAL(wp)    :: h_ref      = 0.0_wp   ! reference conductance
    LOGICAL     :: pressure_dep = .FALSE. ! pressure-dependent conductance
    INTEGER(i4) :: interp     = 0_i4     ! 0=step, 1=linear interpolation
  END TYPE PH_Contact_GAPCON_Algo
```

### `PH_Contact_GAPUNIT_Algo` (lines 1008–1012)

```fortran
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Algo
    REAL(wp)    :: emissivity = 0.0_wp  ! emissivity coefficient
    REAL(wp)    :: boltzmann  = 5.67e-8_wp ! Stefan-Boltzmann
    LOGICAL     :: view_factor= .FALSE.  ! use view factor
  END TYPE PH_Contact_GAPUNIT_Algo
```

### `PH_Cont_Friction_Model` (lines 1015–1025)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Model
      INTEGER(i4) :: model_type = 1  ! 1=Coulomb, 2=Tresca, 3=Rate-dependent, 4=Viscoelastic
      REAL(wp) :: mu_static = ZERO   ! Static friction coef
      REAL(wp) :: mu_dynamic = ZERO  ! Dynamic friction coef
      REAL(wp) :: mu_temperature = ZERO  ! Temperature-dependent factor
      REAL(wp) :: critical_slip_velocity = ZERO  ! Transition velocity
      REAL(wp) :: viscosity = ZERO   ! Viscous friction parameter
      REAL(wp) :: regularization_parameter = ZERO  ! Friction regularization
      LOGICAL :: stick_slip_transition = .TRUE.
      LOGICAL :: rate_dependency = .FALSE.
  END TYPE PH_Cont_Friction_Model
```

### `PH_Cont_Thermal_Properties` (lines 1028–1038)

```fortran
  TYPE, PUBLIC :: PH_Cont_Thermal_Properties
      REAL(wp) :: thermal_conductivity = ZERO
      REAL(wp) :: thermal_conductance = ZERO
      REAL(wp) :: heat_capacity = ZERO
      REAL(wp) :: thermal_expansion = ZERO
      REAL(wp) :: interface_thermal_resistance = ZERO
      REAL(wp) :: contact_temperature = ZERO
      REAL(wp) :: heat_flux = ZERO
      LOGICAL :: thermal_contact_enabled = .FALSE.
      LOGICAL :: temperature_dependent_friction = .FALSE.
  END TYPE PH_Cont_Thermal_Properties
```

### `PH_Cont_Dynamic_Properties` (lines 1041–1049)

```fortran
  TYPE, PUBLIC :: PH_Cont_Dynamic_Properties
      REAL(wp) :: damping_coefficient = ZERO
      REAL(wp) :: restitution_coeff = ZERO
      REAL(wp) :: impact_velocity_threshold = ZERO
      REAL(wp) :: effective_mass = ZERO
      REAL(wp) :: contact_time = ZERO
      LOGICAL :: impact_detection = .FALSE.
      LOGICAL :: energy_dissipation = .TRUE.
  END TYPE PH_Cont_Dynamic_Properties
```

### `PH_Cont_Optimization_Params` (lines 1052–1059)

```fortran
  TYPE, PUBLIC :: PH_Cont_Optimization_Params
      LOGICAL :: adaptive_penalty = .TRUE.
      LOGICAL :: adaptive_friction = .TRUE.
      REAL(wp) :: penalty_growth_factor = 2.0_wp
      REAL(wp) :: penalty_reduction_factor = 0.5_wp
      REAL(wp) :: convergence_acceleration = 1.0_wp
      INTEGER(i4) :: optimization_strategy = 1  ! 1=conjugate_gradient, 2=Newton, 3=quasi-Newton
  END TYPE PH_Cont_Optimization_Params
```

### `PH_Cont_Penetration_Algo_Arg` (lines 1070–1074)

```fortran
  TYPE, PUBLIC :: PH_Cont_Penetration_Algo_Arg
    INTEGER(i4) :: num_slave_nodes  ! Number of slave nodes                   ! [IN]
    INTEGER(i4) :: num_master_nodes  ! Number of master nodes                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Penetration_Algo_Arg
```

### `PH_Cont_Friction_Algo_Arg` (lines 1082–1086)

```fortran
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Arg
    REAL(wp) :: slip_magnitude  ! Slip magnitude ||v_slip||                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Friction_Algo_Arg
```

### `PH_Cont_Thermal_Contact_Arg` (lines 1094–1099)

```fortran
  TYPE, PUBLIC :: PH_Cont_Thermal_Contact_Arg
    REAL(wp) :: temperature_slave  ! Slave temperature T_slave                   ! [IN]
    REAL(wp) :: temperature_master  ! Master temperature T_master                   ! [IN]
    REAL(wp) :: contact_pressure  ! Contact pressure σ_n                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Thermal_Contact_Arg
```

### `PH_Cont_Dynamic_Contact_Arg` (lines 1107–1111)

```fortran
  TYPE, PUBLIC :: PH_Cont_Dynamic_Contact_Arg
    REAL(wp) :: contact_area  ! Contact area A                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Dynamic_Contact_Arg
```

### `PH_Cont_AlgorithmFramework_Impl_Arg` (lines 1119–1123)

```fortran
  TYPE, PUBLIC :: PH_Cont_AlgorithmFramework_Impl_Arg
    REAL(wp) :: gap  ! Gap function g                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AlgorithmFramework_Impl_Arg
```

### `PH_Cont_ComputeTangentVectors_Arg` (lines 1131–1133)

```fortran
  TYPE, PUBLIC :: PH_Cont_ComputeTangentVectors_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ComputeTangentVectors_Arg
```

### `PH_Cont_ComputeContactForces_Arg` (lines 1141–1146)

```fortran
  TYPE, PUBLIC :: PH_Cont_ComputeContactForces_Arg
    REAL(wp) :: slip_magnitude  ! Slip magnitude ||v_slip||                   ! [IN]
    REAL(wp) :: temperature_factor  ! Temperature effect factor                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ComputeContactForces_Arg
```

### `PH_Cont_ApplyImpactResponse_Arg` (lines 1154–1157)

```fortran
  TYPE, PUBLIC :: PH_Cont_ApplyImpactResponse_Arg
    REAL(wp) :: impact_energy  ! Impact energy E_impact                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ApplyImpactResponse_Arg
```

### `PH_Cont_ComputeTemperatureEffect_Arg` (lines 1164–1168)

```fortran
  TYPE, PUBLIC :: PH_Cont_ComputeTemperatureEffect_Arg
    REAL(wp) :: temperature  ! Interface temperature T                   ! [IN]
    REAL(wp) :: effect_factor  ! Temperature effect factor                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ComputeTemperatureEffect_Arg
```

### `PH_Contact_BVH_Node` (lines 1176–1184)

```fortran
  TYPE :: PH_Contact_BVH_Node
    REAL(wp) :: bbox_min(3)                    ! Bounding box minimum
    REAL(wp) :: bbox_max(3)                    ! Bounding box maximum
    INTEGER(i4) :: first_primitive = 0_i4      ! First primitive index
    INTEGER(i4) :: n_primitives = 0_i4         ! Number of primitives in node
    LOGICAL :: is_leaf = .FALSE.               ! Leaf node flag
    TYPE(PH_Contact_BVH_Node), POINTER :: left => NULL()
    TYPE(PH_Contact_BVH_Node), POINTER :: right => NULL()
  END TYPE PH_Contact_BVH_Node
```

### `PH_Contact_Surface_Desc` (lines 1188–1206)

```fortran
  TYPE, PUBLIC :: PH_Contact_Surface_Desc
    INTEGER(i4) :: surface_id = 0_i4           ! Unique surface ID
    CHARACTER(len=64) :: surface_name = ''     ! Surface name (from L3)
    
    !-- Surface topology
    INTEGER(i4) :: n_nodes = 0_i4              ! Number of nodes on surface
    INTEGER(i4) :: n_segments = 0_i4           ! Number of surface segments
    INTEGER(i4), ALLOCATABLE :: node_ids(:)    ! Node IDs on surface
    INTEGER(i4), ALLOCATABLE :: segment_conn(:,:) ! Segment connectivity
    
    !-- Surface geometry (populated from L3)
    REAL(wp), ALLOCATABLE :: coords(:,:)       ! Nodal coordinates (3 x n_nodes)
    REAL(wp), ALLOCATABLE :: normals(:,:)      ! Nodal normals (3 x n_nodes)
    
    !-- Search structure (BVH/Octree pre-built)
    INTEGER(i4) :: search_structure_type = 1_i4 ! 1=None, 2=BVH, 3=Octree
    TYPE(PH_Contact_BVH_Node), POINTER :: bvh_root => NULL()
    ! NOTE: BVH build/query ops live in PH_ContBVHBuilder_Algo / PH_ContBVHQuery_Algo
  END TYPE PH_Contact_Surface_Desc
```

### `PH_Contact_Pair_Desc` (lines 1210–1242)

```fortran
  TYPE, PUBLIC :: PH_Contact_Pair_Desc
    INTEGER(i4) :: pair_id = 0_i4              ! Unique contact pair ID
    CHARACTER(len=64) :: pair_name = ''        ! Contact pair name
    
    !-- Master-Slave assignment
    TYPE(PH_Contact_Surface_Desc) :: master_surface  ! Master surface
    TYPE(PH_Contact_Surface_Desc) :: slave_surface   ! Slave surface
    
    !-- Contact algorithm parameters (from L3 Desc)
    TYPE(PH_Cont_Desc) :: algo_params
    
    !-- Contact enforcement method
    INTEGER(i4) :: enforcement_method = 1_i4   ! 1=Penalty, 2=Lagrange, 3=AugLag
    REAL(wp) :: penalty_normal = 1.0e6_wp      ! Normal penalty stiffness
    REAL(wp) :: penalty_tangential = 1.0e6_wp  ! Tangential penalty stiffness
    
    !-- Friction model
    INTEGER(i4) :: friction_model = 1_i4       ! 1=Coulomb, 2=Tresca, 3=User
    REAL(wp) :: friction_coeff_static = 0.0_wp ! Static friction coefficient
    REAL(wp) :: friction_coeff_dynamic = 0.0_wp ! Dynamic friction coefficient
    
    !-- Contact detection settings
    REAL(wp) :: search_tolerance = 1.0e-6_wp   ! Geometric tolerance
    LOGICAL :: finite_sliding_flag = .TRUE.    ! Finite sliding enabled
    
    !-- Thermal contact (optional)
    LOGICAL :: thermal_contact = .FALSE.       ! Thermal coupling enabled
    REAL(wp) :: thermal_conductance = 0.0_wp   ! Gap-dependent conductance
    
    !-- Damage/Failure (optional)
    LOGICAL :: enable_damage = .FALSE.         ! Contact damage evolution
    REAL(wp) :: damage_threshold = 1.0e10_wp   ! Damage initiation threshold
  END TYPE PH_Contact_Pair_Desc
```

### `PH_Cont_Eval_Arg` (lines 1251–1269)

```fortran
  TYPE, PUBLIC :: PH_Cont_Eval_Arg
    !-- IN: Contact pair topology
    INTEGER(i4) :: n_slave_nodes  = 0_i4        ! [IN] Number of slave nodes
    INTEGER(i4) :: n_master_faces = 0_i4        ! [IN] Number of master faces
    REAL(wp), ALLOCATABLE :: slave_coords(:,:)  ! [IN] Slave node coords (3, n_slave)
    REAL(wp), ALLOCATABLE :: master_coords(:,:,:) ! [IN] Master face coords (3, max_face_nodes, n_faces)
    !-- INOUT: Detected pairs from S1
    INTEGER(i4) :: n_active_pairs = 0_i4        ! [INOUT] Number of active contact pairs
    INTEGER(i4), ALLOCATABLE :: pair_slave(:)   ! [INOUT] Slave node IDs for active pairs
    INTEGER(i4), ALLOCATABLE :: pair_master(:)  ! [INOUT] Master face IDs for active pairs
    !-- INOUT: Gap/penetration from S2
    REAL(wp), ALLOCATABLE :: gap(:)             ! [INOUT] Gap values per active pair
    REAL(wp), ALLOCATABLE :: normal(:,:)        ! [INOUT] Normal vectors (3, n_active)
    !-- INOUT: Forces from S3
    REAL(wp), ALLOCATABLE :: f_contact(:,:)     ! [INOUT] Contact force vectors (3, n_slave)
    !-- OUT: Assembled contributions for S4
    REAL(wp), ALLOCATABLE :: K_contact(:,:)     ! [OUT] Contact stiffness (sparse CSR or dense)
    REAL(wp), ALLOCATABLE :: rhs_contact(:)     ! [OUT] Contact RHS contribution
  END TYPE PH_Cont_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ContactSearchStrategy_Ifc` | 217 | `SUBROUTINE ContactSearchStrategy_Ifc(arg, status)` |
| SUBROUTINE | `PH_Cont_SearchStrategy_Ifc` | 1277 | `SUBROUTINE PH_Cont_SearchStrategy_Ifc(desc, state, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
