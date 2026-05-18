! =============================================================================
! FILE: PH_Fluid_Types.f90
! LAYER: L4_PH  —  Physical Handler Layer
! DOMAIN: Fluid / Electrical / Electromagnetic Subroutines (Standard)
!
! SUBROUTINES COVERED:
!   UDECURRENT         — DC electrical current density (Standard)
!   UDEMPOTENTIAL      — DC electrical potential (Standard)
!   UDSECURRENT        — surface charge/current density (Standard)
!   UFLUID             — fluid bulk properties in fluid-filled cavities (Standard)
!   UFLUIDCONNECTORLOSS   — connector fluid loss coefficient (Standard)
!   UFLUIDCONNECTORVALVE  — connector fluid valve (Standard)
!   UFLUIDLEAKOFF      — fluid leak-off in fracturing simulation (Standard)
!   UFLUIDPIPEFRICTION — pipe friction pressure loss (Standard)
!
! PATTERN: each subroutine → Ctx / State / Algo  (3 TYPE each)
! Total new TYPE: 24
! =============================================================================

MODULE PH_Fluid_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ---------------------------------------------------------------------------
  ! UDECURRENT — user-defined DC electrical current density
  !   Returns current density vector at a material point.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UDECURRENT_Ctx
    REAL(wp)    :: coords(3)    = 0.0_wp  ! I  COORDS  current position
    REAL(wp)    :: potential    = 0.0_wp  ! I  POT     electric potential
    REAL(wp)    :: dpotdx(3)   = 0.0_wp  ! I  DPOTDX  grad(potential)
    REAL(wp)    :: time(2)      = 0.0_wp  ! I  TIME
    REAL(wp)    :: dtime        = 0.0_wp  ! I  DTIME
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: npt          = 0_i4
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDECURRENT_Ctx

  TYPE, PUBLIC :: PH_Fluid_UDECURRENT_State
    REAL(wp)    :: curr_density(3) = 0.0_wp  ! O  CJDEC  current density vector
    REAL(wp)    :: dcurr_dpot(3)   = 0.0_wp  ! O  d(J)/d(V) conductivity contrib
    REAL(wp)    :: dcurr_dgpot(3,3)= 0.0_wp  ! O  d(J)/d(gradV)
    LOGICAL     :: is_updated      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDECURRENT_State

  TYPE, PUBLIC :: PH_Fluid_UDECURRENT_Algo
    LOGICAL     :: provide_jacobian    = .TRUE.
    REAL(wp)    :: conductivity_ref    = 1.0_wp
    REAL(wp)    :: tol_convergence     = 1.0e-10_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDECURRENT_Algo

  ! ---------------------------------------------------------------------------
  ! UDEMPOTENTIAL — user-defined DC electric potential boundary
  !   Returns prescribed potential and its normal-flux contribution.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UDEMPOTENTIAL_Ctx
    REAL(wp)    :: coords(3)    = 0.0_wp
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: npt          = 0_i4
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDEMPOTENTIAL_Ctx

  TYPE, PUBLIC :: PH_Fluid_UDEMPOTENTIAL_State
    REAL(wp)    :: potential_bc = 0.0_wp  ! O  prescribed electric potential
    REAL(wp)    :: flux_bc      = 0.0_wp  ! O  normal current flux
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDEMPOTENTIAL_State

  TYPE, PUBLIC :: PH_Fluid_UDEMPOTENTIAL_Algo
    LOGICAL     :: use_grounded     = .FALSE.  ! force zero potential reference
    REAL(wp)    :: potential_tol    = 1.0e-12_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDEMPOTENTIAL_Algo

  ! ---------------------------------------------------------------------------
  ! UDSECURRENT — user-defined surface charge / current density
  !   Applied on element surfaces; returns surface charge density.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UDSECURRENT_Ctx
    REAL(wp)    :: coords(3)    = 0.0_wp
    REAL(wp)    :: normal(3)    = 0.0_wp  ! I  outward surface normal
    REAL(wp)    :: potential    = 0.0_wp  ! I  potential at surface point
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: npt          = 0_i4
    INTEGER(i4) :: jltyp        = 0_i4   ! I  load interaction type
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDSECURRENT_Ctx

  TYPE, PUBLIC :: PH_Fluid_UDSECURRENT_State
    REAL(wp)    :: surf_charge  = 0.0_wp  ! O  CHRGSE  surface charge density
    REAL(wp)    :: dcharg_dpot  = 0.0_wp  ! O  d(chargse)/d(pot)
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDSECURRENT_State

  TYPE, PUBLIC :: PH_Fluid_UDSECURRENT_Algo
    LOGICAL     :: provide_dsurface_dpot = .TRUE.
    REAL(wp)    :: charge_tol            = 1.0e-12_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UDSECURRENT_Algo

  ! ---------------------------------------------------------------------------
  ! UFLUID — fluid bulk properties in hydrostatic fluid-filled cavities
  !   Returns density, bulk modulus, and viscosity of a user-defined fluid.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UFLUID_Ctx
    REAL(wp)    :: pressure     = 0.0_wp  ! I  cavity pressure
    REAL(wp)    :: temp         = 0.0_wp  ! I  fluid temperature
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUID_Ctx

  TYPE, PUBLIC :: PH_Fluid_UFLUID_State
    REAL(wp)    :: density      = 0.0_wp  ! O  RHO     fluid mass density
    REAL(wp)    :: bulk_mod     = 0.0_wp  ! O  BULK    bulk modulus
    REAL(wp)    :: viscosity    = 0.0_wp  ! O  VISC    dynamic viscosity
    REAL(wp)    :: d_rho_dp     = 0.0_wp  ! O  d(RHO)/d(P)
    REAL(wp)    :: d_bulk_dp    = 0.0_wp  ! O  d(BULK)/d(P)
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUID_State

  TYPE, PUBLIC :: PH_Fluid_UFLUID_Algo
    LOGICAL     :: compressible      = .TRUE.
    LOGICAL     :: temp_dependent    = .FALSE.
    REAL(wp)    :: rho_ref           = 1000.0_wp  ! reference density (kg/m3)
    REAL(wp)    :: bulk_ref          = 2.0e9_wp   ! reference bulk modulus (Pa)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUID_Algo

  ! ---------------------------------------------------------------------------
  ! UFLUIDCONNECTORLOSS — user loss coefficient for fluid connector element
  !   Returns pressure-drop coefficient in a pipe-network connector.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UFLUIDCONNECTORLOSS_Ctx
    REAL(wp)    :: mflow_rate   = 0.0_wp  ! I  mass flow rate
    REAL(wp)    :: pressure_in  = 0.0_wp  ! I  upstream pressure
    REAL(wp)    :: pressure_out = 0.0_wp  ! I  downstream pressure
    REAL(wp)    :: density      = 0.0_wp  ! I  fluid density
    REAL(wp)    :: viscosity    = 0.0_wp  ! I  dynamic viscosity
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDCONNECTORLOSS_Ctx

  TYPE, PUBLIC :: PH_Fluid_UFLUIDCONNECTORLOSS_State
    REAL(wp)    :: pressure_loss    = 0.0_wp  ! O  total pressure loss
    REAL(wp)    :: d_ploss_d_mflow  = 0.0_wp  ! O  Jacobian w.r.t. mass flow
    REAL(wp)    :: d_ploss_d_pin    = 0.0_wp  ! O  Jacobian w.r.t. inlet P
    REAL(wp)    :: d_ploss_d_pout   = 0.0_wp  ! O  Jacobian w.r.t. outlet P
    LOGICAL     :: is_updated       = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDCONNECTORLOSS_State

  TYPE, PUBLIC :: PH_Fluid_UFLUIDCONNECTORLOSS_Algo
    LOGICAL     :: provide_jacobian  = .TRUE.
    REAL(wp)    :: loss_tol          = 1.0e-10_wp
    REAL(wp)    :: Re_transition     = 2300.0_wp  ! laminar-turbulent Reynolds
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDCONNECTORLOSS_Algo

  ! ---------------------------------------------------------------------------
  ! UFLUIDCONNECTORVALVE — user-defined valve behaviour in a fluid connector
  !   Returns effective open area fraction of a valve vs. control variable.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UFLUIDCONNECTORVALVE_Ctx
    REAL(wp)    :: ctrl_var     = 0.0_wp  ! I  control variable (e.g. pressure)
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDCONNECTORVALVE_Ctx

  TYPE, PUBLIC :: PH_Fluid_UFLUIDCONNECTORVALVE_State
    REAL(wp)    :: open_area    = 1.0_wp   ! O  effective open area fraction [0,1]
    REAL(wp)    :: d_area_d_cv  = 0.0_wp   ! O  d(open_area)/d(ctrl_var)
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDCONNECTORVALVE_State

  TYPE, PUBLIC :: PH_Fluid_UFLUIDCONNECTORVALVE_Algo
    REAL(wp)    :: open_tol     = 1.0e-6_wp  ! tolerance for fully open/closed
    LOGICAL     :: allow_reverse = .TRUE.     ! bidirectional flow
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDCONNECTORVALVE_Algo

  ! ---------------------------------------------------------------------------
  ! UFLUIDLEAKOFF — user-defined fluid leak-off (hydraulic fracturing)
  !   Returns the leak-off velocity into the rock matrix.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UFLUIDLEAKOFF_Ctx
    REAL(wp)    :: coords(3)    = 0.0_wp
    REAL(wp)    :: pressure_frac= 0.0_wp  ! I  fracture fluid pressure
    REAL(wp)    :: pressure_pore= 0.0_wp  ! I  pore (matrix) pressure
    REAL(wp)    :: temp         = 0.0_wp
    REAL(wp)    :: dtemp        = 0.0_wp
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: npt          = 0_i4
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDLEAKOFF_Ctx

  TYPE, PUBLIC :: PH_Fluid_UFLUIDLEAKOFF_State
    REAL(wp)    :: leakoff_vel  = 0.0_wp  ! O  UTLEAKOFF  leak-off velocity (m/s)
    REAL(wp)    :: d_vl_dp      = 0.0_wp  ! O  d(vl)/d(pfrac)
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDLEAKOFF_State

  TYPE, PUBLIC :: PH_Fluid_UFLUIDLEAKOFF_Algo
    REAL(wp)    :: filter_cake_coeff = 0.0_wp  ! filter-cake resistance coeff
    LOGICAL     :: include_pore_effect = .TRUE.
    REAL(wp)    :: leakoff_tol       = 1.0e-12_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDLEAKOFF_Algo

  ! ---------------------------------------------------------------------------
  ! UFLUIDPIPEFRICTION — pipe-friction pressure loss in pipe-flow elements
  !   Returns Darcy-Weisbach friction factor and Jacobians.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Fluid_UFLUIDPIPEFRICTION_Ctx
    REAL(wp)    :: reynolds     = 0.0_wp  ! I  Re     Reynolds number
    REAL(wp)    :: mflow_rate   = 0.0_wp  ! I  mass flow rate
    REAL(wp)    :: pipe_diam    = 0.0_wp  ! I  pipe inner diameter
    REAL(wp)    :: roughness    = 0.0_wp  ! I  roughness height
    REAL(wp)    :: viscosity    = 0.0_wp  ! I  dynamic viscosity
    REAL(wp)    :: time(2)      = 0.0_wp
    REAL(wp)    :: dtime        = 0.0_wp
    INTEGER(i4) :: noel         = 0_i4
    INTEGER(i4) :: kstep        = 0_i4
    INTEGER(i4) :: kinc         = 0_i4
    INTEGER(i4) :: nprops       = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname  = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDPIPEFRICTION_Ctx

  TYPE, PUBLIC :: PH_Fluid_UFLUIDPIPEFRICTION_State
    REAL(wp)    :: friction_fac = 0.0_wp  ! O  Darcy-Weisbach friction factor f
    REAL(wp)    :: d_f_d_Re     = 0.0_wp  ! O  d(f)/d(Re)
    REAL(wp)    :: pressure_drop= 0.0_wp  ! O  derived pressure drop per unit L
    LOGICAL     :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDPIPEFRICTION_State

  TYPE, PUBLIC :: PH_Fluid_UFLUIDPIPEFRICTION_Algo
    INTEGER(i4) :: correlation_type = 0_i4  ! 0=Colebrook, 1=Churchill, user…
    REAL(wp)    :: Re_laminar_max   = 2300.0_wp
    REAL(wp)    :: Re_turbulent_min = 4000.0_wp
    LOGICAL     :: provide_jacobian = .TRUE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fluid_UFLUIDPIPEFRICTION_Algo

END MODULE PH_Fluid_Types
