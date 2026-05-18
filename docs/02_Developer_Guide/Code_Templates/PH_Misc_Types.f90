! =============================================================================
! FILE: PH_Misc_Types.f90
! LAYER: L4_PH  —  Physical Handler Layer
! DOMAIN: Miscellaneous Standard Subroutines
!         (Motion / Pore-pressure / Acoustics / Damage / XFEM / Viscoelastic)
!
! SUBROUTINES COVERED (Abaqus/Standard):
!   UMOTION           — prescribed rigid-body motion
!   UPOREP            — initial pore-pressure conditions
!   UPRESS            — non-uniform surface/edge pressure BC
!   UPSD              — power spectral density (random response)
!   UDMGINI           — damage initiation criterion
!   UXFEMNONLOCALWEIGHT — nonlocal weight function for XFEM enrichment
!   VOIDRI            — initial void ratio distribution (geostatic)
!   UTRSNETWORK       — viscoelastic transient network (polymer)
!
! PATTERN: Ctx / State / Algo  (3 TYPE per subroutine, 24 total)
! =============================================================================

MODULE PH_Misc_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ---------------------------------------------------------------------------
  ! UMOTION — user-prescribed rigid-body motion (nodes on rigid surfaces)
  !   Called to define translational/rotational displacement of a rigid body.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UMOTION_Ctx
    REAL(wp)    :: time(2)     = 0.0_wp   ! I  TIME(1)=step, TIME(2)=total
    REAL(wp)    :: dtime       = 0.0_wp   ! I  DTIME
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    INTEGER(i4) :: node        = 0_i4     ! I  reference node number
    INTEGER(i4) :: ndof_node   = 0_i4    ! I  number of DOF at node
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UMOTION_Ctx

  TYPE, PUBLIC :: PH_Misc_UMOTION_State
    REAL(wp)    :: disp(6)     = 0.0_wp   ! O  prescribed displacement (u1,u2,u3,r1,r2,r3)
    REAL(wp)    :: veloc(6)    = 0.0_wp   ! O  velocity
    REAL(wp)    :: accel(6)    = 0.0_wp   ! O  acceleration
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UMOTION_State

  TYPE, PUBLIC :: PH_Misc_UMOTION_Algo
    LOGICAL     :: smooth_ramp      = .TRUE.  ! use smooth step function
    LOGICAL     :: enforce_rotation = .FALSE. ! prescribe rotation DOFs too
    REAL(wp)    :: disp_tol        = 1.0e-10_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UMOTION_Algo

  ! ---------------------------------------------------------------------------
  ! UPOREP — initial pore-pressure conditions
  !   Called at the beginning of an analysis to initialise pore-pressure field.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UPOREP_Ctx
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  COORDS  material point coordinates
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: layer       = 0_i4
    INTEGER(i4) :: kspt        = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPOREP_Ctx

  TYPE, PUBLIC :: PH_Misc_UPOREP_State
    REAL(wp)    :: pore_pressure = 0.0_wp  ! O  initial pore pressure
    LOGICAL     :: is_updated    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPOREP_State

  TYPE, PUBLIC :: PH_Misc_UPOREP_Algo
    REAL(wp)    :: hydrostatic_gradient = 9810.0_wp  ! rho*g (Pa/m)
    REAL(wp)    :: datum_elevation      = 0.0_wp
    REAL(wp)    :: p_ref                = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPOREP_Algo

  ! ---------------------------------------------------------------------------
  ! UPRESS — non-uniform pressure BC
  !   Returns pressure magnitude on a surface/edge as a function of position.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UPRESS_Ctx
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  COORDS
    REAL(wp)    :: normal(3)   = 0.0_wp   ! I  outward surface normal
    REAL(wp)    :: time(2)     = 0.0_wp
    REAL(wp)    :: dtime       = 0.0_wp
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: jltyp       = 0_i4    ! I  load interaction type key
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPRESS_Ctx

  TYPE, PUBLIC :: PH_Misc_UPRESS_State
    REAL(wp)    :: pressure    = 0.0_wp   ! O  pressure magnitude
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPRESS_State

  TYPE, PUBLIC :: PH_Misc_UPRESS_Algo
    LOGICAL     :: use_follower_force = .TRUE.  ! pressure follows deformation
    REAL(wp)    :: pressure_floor     = 0.0_wp
    REAL(wp)    :: pressure_ceil      = 1.0e30_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPRESS_Algo

  ! ---------------------------------------------------------------------------
  ! UPSD — user-defined power spectral density (random response)
  !   Returns the PSD value at a given frequency for a load component.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UPSD_Ctx
    REAL(wp)    :: freq        = 0.0_wp   ! I  excitation frequency (Hz)
    INTEGER(i4) :: kcomp       = 0_i4    ! I  load component index
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    CHARACTER(LEN=8) :: psdname = ' '    ! I  PSD definition name
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPSD_Ctx

  TYPE, PUBLIC :: PH_Misc_UPSD_State
    REAL(wp)    :: psd_value   = 0.0_wp  ! O  spectral density value
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPSD_State

  TYPE, PUBLIC :: PH_Misc_UPSD_Algo
    LOGICAL     :: one_sided   = .TRUE.   ! one-sided PSD convention
    REAL(wp)    :: freq_min    = 0.0_wp
    REAL(wp)    :: freq_max    = 1.0e6_wp
    REAL(wp)    :: psd_floor   = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UPSD_Algo

  ! ---------------------------------------------------------------------------
  ! UDMGINI — user-defined damage initiation criterion
  !   Returns the damage initiation function value (criterion ≥ 1 → initiate).
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UDMGINI_Ctx
    REAL(wp)    :: stress(6)   = 0.0_wp   ! I  Cauchy stress tensor
    REAL(wp)    :: strain(6)   = 0.0_wp   ! I  total strain
    REAL(wp)    :: eqplas      = 0.0_wp   ! I  equivalent plastic strain
    REAL(wp)    :: triaxiality = 0.0_wp   ! I  stress triaxiality
    REAL(wp)    :: lode_angle  = 0.0_wp   ! I  Lode angle
    REAL(wp)    :: strainrate  = 0.0_wp   ! I  equivalent strain rate
    REAL(wp)    :: temp        = 0.0_wp
    REAL(wp)    :: time(2)     = 0.0_wp
    REAL(wp)    :: dtime       = 0.0_wp
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: nprops      = 0_i4
    REAL(wp), POINTER :: props(:)
    INTEGER(i4) :: nstatv      = 0_i4
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UDMGINI_Ctx

  TYPE, PUBLIC :: PH_Misc_UDMGINI_State
    REAL(wp)    :: dmg_criterion = 0.0_wp  ! O  damage criterion value
    REAL(wp)    :: pnewdt        = 1.0_wp
    REAL(wp), ALLOCATABLE :: statev(:)     ! IO SDV update
    LOGICAL     :: is_updated    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UDMGINI_State

  TYPE, PUBLIC :: PH_Misc_UDMGINI_Algo
    INTEGER(i4) :: criterion_type  = 0_i4  ! 0=user, 1=Hosford-Coulomb
    REAL(wp)    :: initiation_tol  = 1.0e-6_wp
    LOGICAL     :: track_history   = .TRUE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UDMGINI_Algo

  ! ---------------------------------------------------------------------------
  ! UXFEMNONLOCALWEIGHT — nonlocal weight function for XFEM crack propagation
  !   Returns the nonlocal weight at a given distance from the crack tip.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UXFEMNONLOCALWEIGHT_Ctx
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  query point coordinates
    REAL(wp)    :: ctip(3)     = 0.0_wp   ! I  crack tip coordinates
    REAL(wp)    :: distance    = 0.0_wp   ! I  |coords - ctip|
    REAL(wp)    :: radius_ref  = 0.0_wp   ! I  reference radius
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UXFEMNONLOCALWEIGHT_Ctx

  TYPE, PUBLIC :: PH_Misc_UXFEMNONLOCALWEIGHT_State
    REAL(wp)    :: weight      = 0.0_wp   ! O  nonlocal weight [0,1]
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UXFEMNONLOCALWEIGHT_State

  TYPE, PUBLIC :: PH_Misc_UXFEMNONLOCALWEIGHT_Algo
    INTEGER(i4) :: weight_function  = 0_i4  ! 0=bell, 1=Gaussian, 2=cubic spline
    REAL(wp)    :: decay_exponent   = 2.0_wp
    REAL(wp)    :: cutoff_ratio     = 1.0_wp  ! weight=0 for r > cutoff*r_ref
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UXFEMNONLOCALWEIGHT_Algo

  ! ---------------------------------------------------------------------------
  ! VOIDRI — initial void-ratio distribution (geostatic / porous media)
  !   Called at beginning of analysis to set the initial void ratio field.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_VOIDRI_Ctx
    REAL(wp)    :: coords(3)   = 0.0_wp   ! I  material point coordinates
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: layer       = 0_i4
    INTEGER(i4) :: kspt        = 0_i4
    INTEGER(i4) :: nprops      = 0_i4
    REAL(wp), POINTER :: props(:)
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_VOIDRI_Ctx

  TYPE, PUBLIC :: PH_Misc_VOIDRI_State
    REAL(wp)    :: void_ratio  = 0.0_wp   ! O  initial void ratio e
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_VOIDRI_State

  TYPE, PUBLIC :: PH_Misc_VOIDRI_Algo
    REAL(wp)    :: void_ratio_min  = 0.0_wp    ! admissible lower bound
    REAL(wp)    :: void_ratio_max  = 10.0_wp   ! admissible upper bound
    LOGICAL     :: use_depth_profile = .FALSE.  ! linear-with-depth option
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_VOIDRI_Algo

  ! ---------------------------------------------------------------------------
  ! UTRSNETWORK — viscoelastic transient network (Bergstrom-Boyce type)
  !   Returns stress and tangent for a network in a transient network model.
  ! ---------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_Misc_UTRSNETWORK_Ctx
    REAL(wp)    :: defgrd(3,3) = 0.0_wp   ! I  deformation gradient F
    REAL(wp)    :: defgrd_prev(3,3) = 0.0_wp ! I  F at start of increment
    REAL(wp)    :: temp        = 0.0_wp
    REAL(wp)    :: dtemp       = 0.0_wp
    REAL(wp)    :: time(2)     = 0.0_wp
    REAL(wp)    :: dtime       = 0.0_wp
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: nprops      = 0_i4
    REAL(wp), POINTER :: props(:)
    INTEGER(i4) :: nstatv      = 0_i4
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UTRSNETWORK_Ctx

  TYPE, PUBLIC :: PH_Misc_UTRSNETWORK_State
    REAL(wp)    :: stress(6)   = 0.0_wp   ! O  Cauchy stress (network contribution)
    REAL(wp)    :: ddsdde(6,6) = 0.0_wp   ! O  material Jacobian
    REAL(wp), ALLOCATABLE :: statev(:)     ! IO SDV (e.g. Cv, be-bar)
    REAL(wp)    :: pnewdt      = 1.0_wp
    LOGICAL     :: is_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UTRSNETWORK_State

  TYPE, PUBLIC :: PH_Misc_UTRSNETWORK_Algo
    INTEGER(i4) :: max_iter         = 50_i4
    REAL(wp)    :: converge_tol     = 1.0e-10_wp
    LOGICAL     :: use_symmetric_jac= .TRUE.
    REAL(wp)    :: pnewdt_cutback   = 0.5_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Misc_UTRSNETWORK_Algo

END MODULE PH_Misc_Types
