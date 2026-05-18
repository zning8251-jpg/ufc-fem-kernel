!===============================================================================
! Module: PH_Explicit_Types                                      [Template v1.0]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Explicit — Ctx / State / Algo for Abaqus/Explicit user subroutines
!
! Purpose:
!   Defines the three-type system (Ctx/State/Algo) for subroutines that are
!   exclusive to Abaqus/Explicit:
!     VDISP        — prescribed displacement/velocity/acceleration (vectorised)
!     VDLOAD       — distributed loads in Explicit (vectorised)
!     VUFIELD      — predefined field variables (vectorised Explicit)
!     VUSDFLD      — solution-dependent field variables (vectorised Explicit)
!     VUINTER      — user-defined surface interactions (vectorised Explicit)
!     VUINTERACTION— generalised contact interaction (Explicit, Abaqus 6.14+)
!     VUAMP        — user-defined amplitude in Explicit (vectorised)
!
! Design notes:
!   • Vectorised routines (nblock pattern): all arrays sized [nblock, ...]
!   • POINTER fields: non-owning; caller manages lifetime
!   • No Desc types here: L3_MD owns all model descriptions
!   • Three-tier Ctx architecture (Level 3 domain Ctx):
!       com_ctx POINTER → RT_Com_Base_Ctx → RT_Global_Ctx (time source)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_Explicit_Types
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Expl_VDISP_Ctx
  PUBLIC :: PH_Expl_VDISP_State
  PUBLIC :: PH_Expl_VDISP_Algo
  PUBLIC :: PH_Expl_VDLOAD_Ctx
  PUBLIC :: PH_Expl_VDLOAD_State
  PUBLIC :: PH_Expl_VDLOAD_Algo
  PUBLIC :: PH_Expl_VUFIELD_Ctx
  PUBLIC :: PH_Expl_VUFIELD_State
  PUBLIC :: PH_Expl_VUFIELD_Algo
  PUBLIC :: PH_Expl_VUSDFLD_Ctx
  PUBLIC :: PH_Expl_VUSDFLD_State
  PUBLIC :: PH_Expl_VUSDFLD_Algo
  PUBLIC :: PH_Expl_VUINTER_Ctx
  PUBLIC :: PH_Expl_VUINTER_State
  PUBLIC :: PH_Expl_VUINTER_Algo
  PUBLIC :: PH_Expl_VUINTERACTION_Ctx
  PUBLIC :: PH_Expl_VUINTERACTION_State
  PUBLIC :: PH_Expl_VUINTERACTION_Algo
  PUBLIC :: PH_Expl_VUAMP_Ctx
  PUBLIC :: PH_Expl_VUAMP_State
  PUBLIC :: PH_Expl_VUAMP_Algo

  !=============================================================================
  ! VDISP — Prescribed displacement/velocity/acceleration (Explicit, vectorised)
  !   Called each explicit increment to apply kinematic boundary conditions.
  !   nblock nodes processed per call; each node may have multiple DOFs.
  !=============================================================================

  ! ------------------------------------------------------------------ !
  ! PH_Expl_VDISP_Ctx
  !   Driving inputs for vectorised prescribed kinematic BC.
  !   VDISP is called once per BC set per increment.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Expl_VDISP_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! number of nodes in this block
    INTEGER(i4)           :: ndofel     = 0_i4   ! total DOFs per node (typically 3 or 6)
    REAL(wp)              :: time(2)    = 0.0_wp  ! TIME(1)=step, TIME(2)=total
    REAL(wp)              :: dtime      = 0.0_wp  ! time increment
    REAL(wp)              :: period     = 0.0_wp  ! step period
    !-- Node coordinates at start of increment
    REAL(wp), POINTER :: coords(:,:)           ! [nblock, 3] node coordinates
    !-- Current kinematic state (input)
    REAL(wp), POINTER :: u(:,:)                ! [nblock, ndofel] displacement
    REAL(wp), POINTER :: v(:,:)                ! [nblock, ndofel] velocity
    REAL(wp), POINTER :: a(:,:)                ! [nblock, ndofel] acceleration
    !-- Amplitude and boundary condition type
    INTEGER(i4), POINTER :: jdltype(:)         ! [nblock] BC type flag
    CHARACTER(LEN=8)      :: amplitude_name = ' '  ! amplitude curve name
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VDISP_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_Expl_VDISP_State
  !   Output prescribed kinematic values returned by VDISP.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Expl_VDISP_State
    REAL(wp), ALLOCATABLE :: uout(:,:)   ! [nblock, ndofel] O prescribed displacement
    REAL(wp), ALLOCATABLE :: vout(:,:)   ! [nblock, ndofel] O prescribed velocity
    REAL(wp), ALLOCATABLE :: aout(:,:)   ! [nblock, ndofel] O prescribed acceleration
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VDISP_State

  ! ------------------------------------------------------------------ !
  ! PH_Expl_VDISP_Algo
  !   Algorithmic parameters controlling VDISP interpolation.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Expl_VDISP_Algo
    LOGICAL     :: smooth_step         = .FALSE.  ! use smooth-step ramp
    INTEGER(i4) :: ramp_type           = 0_i4     ! 0=linear, 1=user amplitude
    REAL(wp)    :: ramp_start          = 0.0_wp   ! ramp start time (step-relative)
    REAL(wp)    :: ramp_end            = 1.0_wp   ! ramp end time (step-relative)
    LOGICAL     :: enforce_velocity    = .FALSE.  ! prescribe velocity instead of disp
    LOGICAL     :: enforce_accel       = .FALSE.  ! prescribe acceleration instead
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VDISP_Algo

  !=============================================================================
  ! VDLOAD — User-defined distributed loads (Abaqus/Explicit, vectorised)
  !   Analogous to DLOAD but vectorised: nblock surface facets per call.
  !=============================================================================

  TYPE, PUBLIC :: PH_Expl_VDLOAD_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! number of load facets
    REAL(wp)              :: time(2)    = 0.0_wp  ! TIME(2)
    REAL(wp)              :: dtime      = 0.0_wp
    REAL(wp)              :: period     = 0.0_wp
    !-- Facet geometry
    REAL(wp), POINTER :: coords(:,:)           ! [nblock, 3] centroid coords
    REAL(wp), POINTER :: normal(:,:)           ! [nblock, 3] outward normal
    REAL(wp), POINTER :: area(:)               ! [nblock] facet area
    !-- Velocity at facet (useful for velocity-dependent loads)
    REAL(wp), POINTER :: v(:,:)                ! [nblock, 3] velocity vector
    !-- Load type and amplitude
    INTEGER(i4), POINTER :: jltyp(:)           ! [nblock] load type flags
    CHARACTER(LEN=8)      :: amplitude_name = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VDLOAD_Ctx

  TYPE, PUBLIC :: PH_Expl_VDLOAD_State
    REAL(wp), ALLOCATABLE :: value(:)    ! [nblock] O load magnitude (pressure etc.)
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VDLOAD_State

  TYPE, PUBLIC :: PH_Expl_VDLOAD_Algo
    INTEGER(i4) :: load_component = 0_i4    ! 0=pressure, 1-3=traction components
    LOGICAL     :: follower_force = .FALSE.  ! rotate with geometry (NLGEOM)
    REAL(wp)    :: scale_factor   = 1.0_wp  ! overall scale
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VDLOAD_Algo

  !=============================================================================
  ! VUFIELD — User-defined predefined field variables (Explicit, vectorised)
  !   VUFIELD defines field variable histories at all nodes simultaneously.
  !   Called once per increment before material/element routines.
  !=============================================================================

  TYPE, PUBLIC :: PH_Expl_VUFIELD_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! number of nodes
    INTEGER(i4)           :: nfield     = 0_i4   ! number of field variables
    REAL(wp)              :: time(2)    = 0.0_wp
    REAL(wp)              :: dtime      = 0.0_wp
    REAL(wp), POINTER :: coords(:,:)          ! [nblock, 3] node coordinates
    REAL(wp), POINTER :: temp(:)              ! [nblock] temperature at nodes
    REAL(wp), POINTER :: field_prev(:,:)       ! [nblock, nfield] field at step start
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFIELD_Ctx

  TYPE, PUBLIC :: PH_Expl_VUFIELD_State
    REAL(wp), ALLOCATABLE :: field_curr(:,:) ! [nblock, nfield] O updated field values
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFIELD_State

  TYPE, PUBLIC :: PH_Expl_VUFIELD_Algo
    LOGICAL     :: interpolate_spatial = .FALSE. ! spatial interpolation between nodes
    INTEGER(i4) :: interp_order        = 1_i4   ! 1=linear, 2=quadratic
    REAL(wp)    :: field_floor         = -1.0e30_wp
    REAL(wp)    :: field_ceil          = +1.0e30_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFIELD_Algo

  !=============================================================================
  ! VUSDFLD — Solution-dependent field variables (Explicit, vectorised)
  !   Vectorised counterpart of USDFLD: updates field vars at material pts.
  !=============================================================================

  TYPE, PUBLIC :: PH_Expl_VUSDFLD_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! number of material points
    INTEGER(i4)           :: nfieldv    = 0_i4   ! number of field variables
    INTEGER(i4)           :: nstatv     = 0_i4   ! number of SDVs
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp)              :: time(2)    = 0.0_wp
    REAL(wp)              :: dtime      = 0.0_wp
    REAL(wp), POINTER :: coords(:,:)          ! [nblock, 3]
    REAL(wp), POINTER :: temp(:)              ! [nblock] temperature
    REAL(wp), POINTER :: dtemp(:)             ! [nblock] temperature increment
    REAL(wp), POINTER :: field_prev(:,:)       ! [nblock, nfieldv] previous field
    REAL(wp), POINTER :: statev_prev(:,:)      ! [nblock, nstatv] previous SDVs
    REAL(wp), POINTER :: stress(:,:)          ! [nblock, ntens] current stress
    REAL(wp), POINTER :: props(:)             ! [nprops] material constants
    CHARACTER(LEN=8)      :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUSDFLD_Ctx

  TYPE, PUBLIC :: PH_Expl_VUSDFLD_State
    REAL(wp), ALLOCATABLE :: field_curr(:,:)   ! [nblock, nfieldv] O updated fields
    REAL(wp), ALLOCATABLE :: statev_curr(:,:)  ! [nblock, nstatv]  O updated SDVs
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUSDFLD_State

  TYPE, PUBLIC :: PH_Expl_VUSDFLD_Algo
    LOGICAL     :: use_stress_in_update  = .TRUE.  ! allow stress-based field update
    LOGICAL     :: clamp_field_values    = .FALSE.  ! clamp field to [lo, hi]
    REAL(wp)    :: field_lo              = 0.0_wp
    REAL(wp)    :: field_hi              = 1.0e30_wp
    INTEGER(i4) :: update_frequency      = 1_i4    ! update every N increments
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUSDFLD_Algo

  !=============================================================================
  ! VUINTER — User-defined surface interaction (Explicit, vectorised)
  !   Defines traction-separation law or contact constitutive for Explicit.
  !   nblock: contact points processed simultaneously.
  !=============================================================================

  TYPE, PUBLIC :: PH_Expl_VUINTER_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! contact points in block
    REAL(wp)              :: time(2)    = 0.0_wp
    REAL(wp)              :: dtime      = 0.0_wp
    !-- Contact kinematics
    REAL(wp), POINTER :: coords(:,:)          ! [nblock, 3] contact point coords
    REAL(wp), POINTER :: normal(:,:)          ! [nblock, 3] contact normal
    REAL(wp), POINTER :: slip(:,:)            ! [nblock, 2] relative tangential slip
    REAL(wp), POINTER :: gap(:)               ! [nblock] contact gap (> 0 open)
    REAL(wp), POINTER :: temp(:)              ! [nblock] surface temperature
    REAL(wp), POINTER :: dtemp(:)             ! [nblock] temperature increment
    !-- Contact SDVs
    INTEGER(i4)           :: nstatv     = 0_i4
    REAL(wp), POINTER :: statev_prev(:,:)      ! [nblock, nstatv]
    !-- Properties
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)             ! [nprops] interaction constants
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUINTER_Ctx

  TYPE, PUBLIC :: PH_Expl_VUINTER_State
    REAL(wp), ALLOCATABLE :: traction(:,:)    ! [nblock, 3] O contact traction vector
    REAL(wp), ALLOCATABLE :: ddtddg(:,:,:)    ! [nblock, 3, 3] O traction stiffness (d traction/d gap)
    REAL(wp), ALLOCATABLE :: statev_curr(:,:)  ! [nblock, nstatv] O updated SDVs
    REAL(wp), ALLOCATABLE :: pnewdt(:)        ! [nblock] O step-size control signal
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUINTER_State

  TYPE, PUBLIC :: PH_Expl_VUINTER_Algo
    LOGICAL     :: cohesive_behavior   = .FALSE.  ! traction-separation (cohesive zone)
    LOGICAL     :: friction_included   = .TRUE.   ! include tangential frictional traction
    REAL(wp)    :: pen_stiffness       = 0.0_wp   ! penalty contact stiffness (0=auto)
    REAL(wp)    :: gap_tol             = 1.0e-10_wp ! contact gap tolerance
    INTEGER(i4) :: tangent_type        = 0_i4     ! 0=no tangent, 1=full tangent
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUINTER_Algo

  !=============================================================================
  ! VUINTERACTION — Generalised contact interaction (Abaqus/Explicit 6.14+)
  !   More general than VUINTER: handles full contact pair interaction including
  !   heat generation, wear, pressure-overclosure.  Vectorised block call.
  !=============================================================================

  TYPE, PUBLIC :: PH_Expl_VUINTERACTION_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! contact facets/points per block
    INTEGER(i4)           :: nfdir      = 2_i4   ! number of frictional directions
    REAL(wp)              :: time(2)    = 0.0_wp
    REAL(wp)              :: dtime      = 0.0_wp
    !-- Contact kinematics
    REAL(wp), POINTER :: coords_m(:,:)        ! [nblock, 3] master surface coords
    REAL(wp), POINTER :: coords_s(:,:)        ! [nblock, 3] slave surface coords
    REAL(wp), POINTER :: normal(:,:)          ! [nblock, 3] contact normal (slave→master)
    REAL(wp), POINTER :: slip(:,:)            ! [nblock, nfdir] relative slip
    REAL(wp), POINTER :: gap(:)               ! [nblock] normal gap
    REAL(wp), POINTER :: area(:)              ! [nblock] contact area
    !-- Thermal / field
    REAL(wp), POINTER :: temp_m(:)            ! [nblock] master surface temp
    REAL(wp), POINTER :: temp_s(:)            ! [nblock] slave surface temp
    !-- Pressure-overclosure state
    REAL(wp), POINTER :: pressure_prev(:)      ! [nblock] contact pressure at start
    !-- SDVs
    INTEGER(i4)           :: nstatv     = 0_i4
    REAL(wp), POINTER :: statev_prev(:,:)      ! [nblock, nstatv]
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUINTERACTION_Ctx

  TYPE, PUBLIC :: PH_Expl_VUINTERACTION_State
    REAL(wp), ALLOCATABLE :: traction(:,:)     ! [nblock, 3] O  contact traction
    REAL(wp), ALLOCATABLE :: heat_gen_m(:)     ! [nblock] O  heat generated at master
    REAL(wp), ALLOCATABLE :: heat_gen_s(:)     ! [nblock] O  heat generated at slave
    REAL(wp), ALLOCATABLE :: wear_depth(:)     ! [nblock] O  wear depth increment
    REAL(wp), ALLOCATABLE :: statev_curr(:,:)   ! [nblock, nstatv] O updated SDVs
    REAL(wp), ALLOCATABLE :: pnewdt(:)         ! [nblock] O step-size signal
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUINTERACTION_State

  TYPE, PUBLIC :: PH_Expl_VUINTERACTION_Algo
    LOGICAL     :: include_thermal    = .FALSE.  ! compute frictional heat generation
    LOGICAL     :: include_wear       = .FALSE.  ! compute wear depth
    LOGICAL     :: cohesive           = .FALSE.  ! use traction-separation
    REAL(wp)    :: heat_partition     = 0.5_wp   ! fraction of fric heat to slave
    REAL(wp)    :: pen_stiffness      = 0.0_wp   ! 0 = auto
    REAL(wp)    :: mu_ref             = 0.0_wp   ! reference friction coefficient
    INTEGER(i4) :: overclosure_model  = 0_i4    ! 0=hard, 1=exponential, 2=linear
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUINTERACTION_Algo

  !=============================================================================
  ! VUAMP — User-defined amplitude (Abaqus/Explicit, vectorised)
  !   Called each explicit increment to evaluate user amplitude curve.
  !   Multiple evaluation points may be requested simultaneously (nblock).
  !=============================================================================

  TYPE, PUBLIC :: PH_Expl_VUAMP_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! evaluation points in block
    REAL(wp)              :: time_total = 0.0_wp  ! current total analysis time
    REAL(wp)              :: time_step  = 0.0_wp  ! current step time
    REAL(wp)              :: dtime      = 0.0_wp
    !-- Requested evaluation times (may differ from global time for offset amps)
    REAL(wp), POINTER :: t_eval(:)             ! [nblock] requested eval times
    !-- Amplitude state from previous call
    REAL(wp), POINTER :: amp_prev(:)            ! [nblock] amplitude at t_eval - dtime
    !-- Parameters
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)              ! [nprops] amplitude parameters
    CHARACTER(LEN=8)      :: ampname    = ' '      ! amplitude definition name
    !-- Control flags
    INTEGER(i4)           :: call_type  = 0_i4    ! 0=displacement, 1=velocity amplitude
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUAMP_Ctx

  TYPE, PUBLIC :: PH_Expl_VUAMP_State
    REAL(wp), ALLOCATABLE :: amp(:)       ! [nblock] O  amplitude value at t_eval
    REAL(wp), ALLOCATABLE :: damp_dt(:)  ! [nblock] O  d(amp)/dt (rate for velocity)
    REAL(wp), ALLOCATABLE :: d2amp_dt2(:)! [nblock] O  d²(amp)/dt² (acceleration)
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUAMP_State

  TYPE, PUBLIC :: PH_Expl_VUAMP_Algo
    LOGICAL     :: smooth_step         = .FALSE.   ! apply smooth-step filter
    INTEGER(i4) :: interp_type         = 0_i4     ! 0=step, 1=linear, 2=cubic spline
    REAL(wp)    :: amp_floor           = 0.0_wp   ! clamp minimum amplitude
    REAL(wp)    :: amp_ceil            = 1.0e30_wp
    LOGICAL     :: provide_derivatives = .TRUE.   ! fill damp_dt + d2amp_dt2
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUAMP_Algo

  ! ---------------------------------------------------------------------------
  ! VEXTERNALDB — Explicit external database / pre/post-processing hook
  !   Called at key analysis phases (open/close/start-step/end-step/end-inc).
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VEXTERNALDB_Ctx
    INTEGER(i4) :: lop          = 0_i4   ! I  phase flag: 0=open,1=start-step,2=end-inc,3=end-step,4=close
    INTEGER(i4) :: lrestart     = 0_i4   ! I  restart flag
    REAL(wp)    :: time(2)      = 0.0_wp ! I  TIME
    REAL(wp)    :: dtime        = 0.0_wp ! I  DTIME
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: numthreads   = 1_i4   ! I  number of parallel threads
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VEXTERNALDB_Ctx

  TYPE, PUBLIC :: PH_Expl_VEXTERNALDB_State
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VEXTERNALDB_State

  TYPE, PUBLIC :: PH_Expl_VEXTERNALDB_Algo
    LOGICAL     :: enable_open      = .TRUE.
    LOGICAL     :: enable_close     = .TRUE.
    LOGICAL     :: enable_per_inc   = .FALSE.  ! call at every increment
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VEXTERNALDB_Algo

  ! ---------------------------------------------------------------------------
  ! VFABRIC — user fabric/woven material constitutive law (Explicit)
  !   Block-vectorised material update for fabric/woven composites.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VFABRIC_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: ndir        = 3_i4  ! number of direct stress components
    INTEGER(i4)           :: nshr        = 3_i4  ! number of shear  components
    INTEGER(i4)           :: nstatv      = 0_i4
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: stran(:,:)          ! [nblock, ndir+nshr]  engineering strain
    REAL(wp), POINTER :: dstran(:,:)         ! [nblock, ndir+nshr]  strain increment
    REAL(wp), POINTER :: defgrd_prev(:,:,:)   ! [nblock,3,3]
    REAL(wp), POINTER :: defgrd_curr(:,:,:)   ! [nblock,3,3]
    REAL(wp), POINTER :: temp(:)             ! [nblock]
    REAL(wp), POINTER :: dtemp(:)            ! [nblock]
    REAL(wp), POINTER :: props(:)            ! material constants
    CHARACTER(LEN=8)      :: cmname      = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VFABRIC_Ctx

  TYPE, PUBLIC :: PH_Expl_VFABRIC_State
    REAL(wp), ALLOCATABLE :: stress(:,:)         ! [nblock, ndir+nshr]  O
    REAL(wp), ALLOCATABLE :: statev(:,:)         ! [nblock, nstatv]     IO
    REAL(wp), ALLOCATABLE :: pnewdt(:)           ! [nblock]             O
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VFABRIC_State

  TYPE, PUBLIC :: PH_Expl_VFABRIC_Algo
    LOGICAL     :: use_large_strain    = .TRUE.
    LOGICAL     :: use_symmetric_jac   = .TRUE.
    REAL(wp)    :: stress_tol          = 1.0e-10_wp
    INTEGER(i4) :: max_iter            = 50_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VFABRIC_Algo

  ! ---------------------------------------------------------------------------
  ! VUCHARLENGTH — user characteristic element length (Explicit)
  !   Returns element characteristic length for stable time step estimate.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUCHARLENGTH_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: noel_blk    = 0_i4
    REAL(wp), POINTER :: coords(:,:,:)       ! [nblock, nnode, 3]
    REAL(wp), POINTER :: defgrd(:,:,:)       ! [nblock, 3, 3]
    CHARACTER(LEN=8)      :: cmname      = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUCHARLENGTH_Ctx

  TYPE, PUBLIC :: PH_Expl_VUCHARLENGTH_State
    REAL(wp), ALLOCATABLE :: char_length(:)      ! [nblock]  O  characteristic length
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUCHARLENGTH_State

  TYPE, PUBLIC :: PH_Expl_VUCHARLENGTH_Algo
    INTEGER(i4) :: method        = 0_i4   ! 0=min-edge, 1=inscribed-sphere, 2=user
    REAL(wp)    :: safety_factor = 1.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUCHARLENGTH_Algo

  ! ---------------------------------------------------------------------------
  ! VUCREEPNETWORK — viscoelastic network creep law (Explicit, vectorised)
  !   Block-vectorised transient network update for polymer creep.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUCREEPNETWORK_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: nstatv      = 0_i4
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: defgrd(:,:,:)       ! [nblock,3,3] deformation gradient
    REAL(wp), POINTER :: temp(:)             ! [nblock]
    REAL(wp), POINTER :: dtemp(:)            ! [nblock]
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8)      :: cmname      = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUCREEPNETWORK_Ctx

  TYPE, PUBLIC :: PH_Expl_VUCREEPNETWORK_State
    REAL(wp), ALLOCATABLE :: stress(:,:)         ! [nblock,6]  O
    REAL(wp), ALLOCATABLE :: statev(:,:)         ! [nblock,nstatv] IO
    REAL(wp), ALLOCATABLE :: pnewdt(:)           ! [nblock]
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUCREEPNETWORK_State

  TYPE, PUBLIC :: PH_Expl_VUCREEPNETWORK_Algo
    INTEGER(i4) :: max_iter         = 50_i4
    REAL(wp)    :: converge_tol     = 1.0e-10_wp
    LOGICAL     :: use_symmetric    = .TRUE.
    REAL(wp)    :: pnewdt_cutback   = 0.5_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUCREEPNETWORK_Algo

  ! ---------------------------------------------------------------------------
  ! VUEOS — user equation-of-state (Explicit, Mie-Grüneisen / shock EOS)
  !   Returns pressure and internal energy update for EOS-based materials.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUEOS_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: nstatv      = 0_i4
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: density(:)          ! [nblock]  current mass density
    REAL(wp), POINTER :: density_ref(:)      ! [nblock]  reference density
    REAL(wp), POINTER :: energy(:)           ! [nblock]  specific internal energy
    REAL(wp), POINTER :: deform_rate(:,:)    ! [nblock,6] deformation rate
    REAL(wp), POINTER :: temp(:)             ! [nblock]
    REAL(wp), POINTER :: dtemp(:)            ! [nblock]
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8)      :: cmname      = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUEOS_Ctx

  TYPE, PUBLIC :: PH_Expl_VUEOS_State
    REAL(wp), ALLOCATABLE :: pressure(:)         ! [nblock]  O  hydrostatic pressure
    REAL(wp), ALLOCATABLE :: energy_curr(:)       ! [nblock]  O  updated internal energy
    REAL(wp), ALLOCATABLE :: dp_drho(:)          ! [nblock]  O  d(P)/d(rho)
    REAL(wp), ALLOCATABLE :: dp_de(:)            ! [nblock]  O  d(P)/d(e)
    REAL(wp), ALLOCATABLE :: statev(:,:)         ! [nblock,nstatv] IO
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUEOS_State

  TYPE, PUBLIC :: PH_Expl_VUEOS_Algo
    INTEGER(i4) :: eos_type          = 0_i4  ! 0=Mie-Gruneisen, 1=JWL, 2=user
    LOGICAL     :: provide_jacobians = .TRUE.
    REAL(wp)    :: pressure_tol      = 1.0e-10_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUEOS_Algo

  ! ---------------------------------------------------------------------------
  ! VUFLUIDEXCH — user fluid exchange (Explicit, cavity/pipe network)
  !   Block-vectorised mass/energy flow between fluid cavities.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUFLUIDEXCH_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: pressure(:,:)       ! [nblock,2] (cavity1, cavity2)
    REAL(wp), POINTER :: temp(:,:)           ! [nblock,2] temperatures
    REAL(wp), POINTER :: area(:)             ! [nblock] exchange area
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8)      :: exchname    = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFLUIDEXCH_Ctx

  TYPE, PUBLIC :: PH_Expl_VUFLUIDEXCH_State
    REAL(wp), ALLOCATABLE :: mass_flow(:)        ! [nblock]  O  mass flow rate
    REAL(wp), ALLOCATABLE :: heat_flow(:)        ! [nblock]  O  heat flow rate
    REAL(wp), ALLOCATABLE :: d_mflow_d_p1(:)     ! [nblock]  O  Jacobian
    REAL(wp), ALLOCATABLE :: d_mflow_d_p2(:)     ! [nblock]  O  Jacobian
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFLUIDEXCH_State

  TYPE, PUBLIC :: PH_Expl_VUFLUIDEXCH_Algo
    LOGICAL     :: compressible         = .TRUE.
    LOGICAL     :: include_heat_exch    = .FALSE.
    REAL(wp)    :: flow_tol             = 1.0e-10_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFLUIDEXCH_Algo

  ! ---------------------------------------------------------------------------
  ! VUFLUIDEXCHEFFAREA — effective exchange area for VUFLUIDEXCH (Explicit)
  !   Returns a scaling factor for the geometric exchange area.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUFLUIDEXCHEFFAREA_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: pressure(:,:)       ! [nblock,2]
    REAL(wp), POINTER :: temp(:,:)           ! [nblock,2]
    REAL(wp), POINTER :: area_geom(:)        ! [nblock]  geometric area
    CHARACTER(LEN=8)      :: exchname    = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFLUIDEXCHEFFAREA_Ctx

  TYPE, PUBLIC :: PH_Expl_VUFLUIDEXCHEFFAREA_State
    REAL(wp), ALLOCATABLE :: area_eff(:)         ! [nblock]  O  effective area
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFLUIDEXCHEFFAREA_State

  TYPE, PUBLIC :: PH_Expl_VUFLUIDEXCHEFFAREA_Algo
    REAL(wp)    :: area_scale_max = 1.0_wp
    REAL(wp)    :: area_scale_min = 0.0_wp
    LOGICAL     :: pressure_dep   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUFLUIDEXCHEFFAREA_Algo

  ! ---------------------------------------------------------------------------
  ! VUTRS — user transient-network relaxation (Explicit)
  !   Block-vectorised equivalent of Standard UTRS for viscoelastic networks.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUTRS_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: nstatv      = 0_i4
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: defgrd(:,:,:)       ! [nblock,3,3]
    REAL(wp), POINTER :: defgrd_prev(:,:,:)   ! [nblock,3,3]
    REAL(wp), POINTER :: temp(:)             ! [nblock]
    REAL(wp), POINTER :: dtemp(:)            ! [nblock]
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8)      :: cmname      = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUTRS_Ctx

  TYPE, PUBLIC :: PH_Expl_VUTRS_State
    REAL(wp), ALLOCATABLE :: stress(:,:)         ! [nblock,6]   O
    REAL(wp), ALLOCATABLE :: statev(:,:)         ! [nblock,nstatv] IO
    REAL(wp), ALLOCATABLE :: pnewdt(:)           ! [nblock]
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUTRS_State

  TYPE, PUBLIC :: PH_Expl_VUTRS_Algo
    INTEGER(i4) :: max_iter      = 50_i4
    REAL(wp)    :: tol           = 1.0e-10_wp
    LOGICAL     :: use_symmetric = .TRUE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUTRS_Algo

  ! ---------------------------------------------------------------------------
  ! VUVISCOSITY — user viscosity for viscous pressure (Explicit)
  !   Returns artificial viscosity pressure for shock capturing.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VUVISCOSITY_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: density(:)          ! [nblock]
    REAL(wp), POINTER :: wave_speed(:)       ! [nblock]  bulk sound speed
    REAL(wp), POINTER :: vol_strain_rate(:)  ! [nblock]  volumetric strain rate
    REAL(wp), POINTER :: char_length(:)      ! [nblock]  characteristic element length
    REAL(wp), POINTER :: temp(:)             ! [nblock]
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8)      :: cmname      = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUVISCOSITY_Ctx

  TYPE, PUBLIC :: PH_Expl_VUVISCOSITY_State
    REAL(wp), ALLOCATABLE :: visc_pressure(:)    ! [nblock]  O  artificial viscosity pressure
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUVISCOSITY_State

  TYPE, PUBLIC :: PH_Expl_VUVISCOSITY_Algo
    REAL(wp)    :: linear_coeff   = 0.06_wp   ! linear viscosity coefficient
    REAL(wp)    :: quadratic_coeff= 1.2_wp    ! quadratic viscosity coefficient
    LOGICAL     :: only_compress  = .TRUE.    ! apply only in compression
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VUVISCOSITY_Algo

  ! ---------------------------------------------------------------------------
  ! VWAVE — user wave kinematics for ocean loading (Explicit)
  !   Returns wave elevation, velocity, and acceleration at a point.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Expl_VWAVE_Ctx
    INTEGER(i4)           :: nblock      = 0_i4
    REAL(wp)              :: dtime       = 0.0_wp
    REAL(wp), POINTER :: coords(:,:)         ! [nblock,3]  query positions
    REAL(wp), POINTER :: time_total(:)       ! [nblock]    total time
    INTEGER(i4)           :: nprops      = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8)      :: wavename    = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VWAVE_Ctx

  TYPE, PUBLIC :: PH_Expl_VWAVE_State
    REAL(wp), ALLOCATABLE :: elevation(:)        ! [nblock]    O  wave surface elevation
    REAL(wp), ALLOCATABLE :: velocity(:,:)       ! [nblock,3]  O  wave particle velocity
    REAL(wp), ALLOCATABLE :: accel(:,:)          ! [nblock,3]  O  wave particle acceleration
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VWAVE_State

  TYPE, PUBLIC :: PH_Expl_VWAVE_Algo
    INTEGER(i4) :: wave_theory       = 0_i4  ! 0=Airy, 1=Stokes5, 2=Stream, 3=user
    LOGICAL     :: include_current   = .FALSE.
    LOGICAL     :: include_stretching= .FALSE.
    REAL(wp)    :: depth             = 1000.0_wp  ! water depth (m)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Expl_VWAVE_Algo

END MODULE PH_Explicit_Types
