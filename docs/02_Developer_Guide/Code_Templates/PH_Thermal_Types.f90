!===============================================================================
! Module: PH_Thermal_Types                                       [Template v1.0]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Thermal — Thermal analysis and coupled thermo-mechanical PH types
!
! Purpose:
!   Provides the PH-layer (Ctx/State/Algo) types that are specific to thermal
!   and coupled thermo-mechanical analyses in Abaqus Standard.  These complement
!   the UMATHT types defined in PH_Mat_Types by providing:
!
!   • PH_Therm_UMATHT_Block_Ctx   — wrapper for batch (vectorised-style) UMATHT
!   • PH_Therm_UMATHT_Block_State — batch output collector
!   • PH_Therm_UMATHT_Block_Algo  — batch algorithmic control
!   • PH_Therm_CoupledField_Ctx   — driving context for fully-coupled
!                                    temperature-displacement increments
!   • PH_Therm_CoupledField_State — coupled state (flux + mechanical coupling terms)
!   • PH_Therm_CoupledField_Algo  — coupled iteration control
!   • PH_Therm_DFLUX_Ctx          — concentrated/distributed heat flux BC (DFLUX)
!   • PH_Therm_DFLUX_State        — heat flux output (FLUX per facet)
!   • PH_Therm_DFLUX_Algo         — DFLUX algorithmic parameters
!   • PH_Therm_FILM_Ctx           — surface film (convection) BC
!   • PH_Therm_FILM_State         — film coefficient and sink temperature
!   • PH_Therm_FILM_Algo          — film coefficient iteration
!
! Design:
!   • No Desc types here — L3 MD_Mat_UMATHT_Desc already defined in MD_Mat_Types
!   • Pointer-link pattern: com_ctx => RT_Com_Base_Ctx for zero-copy time access
!   • Thermal SDV arrays are ALLOCATABLE (owned) or POINTER (non-owning)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_Thermal_Types
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Therm_UMATHT_Block_Ctx
  PUBLIC :: PH_Therm_UMATHT_Block_State
  PUBLIC :: PH_Therm_UMATHT_Block_Algo
  PUBLIC :: PH_Therm_CoupledField_Ctx
  PUBLIC :: PH_Therm_CoupledField_State
  PUBLIC :: PH_Therm_CoupledField_Algo
  PUBLIC :: PH_Therm_DFLUX_Ctx
  PUBLIC :: PH_Therm_DFLUX_State
  PUBLIC :: PH_Therm_DFLUX_Algo
  PUBLIC :: PH_Therm_FILM_Ctx
  PUBLIC :: PH_Therm_FILM_State
  PUBLIC :: PH_Therm_FILM_Algo

  !=============================================================================
  ! UMATHT Block — batch wrapper for UMATHT across npt integration points
  !   In Standard, UMATHT is called sequentially per point.  This wrapper
  !   collects a block of results for diagnostic and assembly purposes.
  !=============================================================================

  ! ------------------------------------------------------------------ !
  ! PH_Therm_UMATHT_Block_Ctx
  !   Aggregates the per-point driving inputs for a group of integration
  !   points sharing the same material assignment.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Therm_UMATHT_Block_Ctx
    INTEGER(i4)           :: npt       = 0_i4   ! number of integration points in block
    INTEGER(i4)           :: ntgrd     = 3_i4   ! spatial dimension of thermal gradient
    INTEGER(i4)           :: ntens     = 6_i4   ! number of stress/strain components
    REAL(wp)              :: dtime     = 0.0_wp  ! shared time increment
    REAL(wp)              :: time(2)   = 0.0_wp  ! TIME(2) array
    !-- Per-point arrays
    REAL(wp), POINTER :: temp(:)             ! [npt] temperature at end of increment
    REAL(wp), POINTER :: dtemp(:)            ! [npt] temperature increment
    REAL(wp), POINTER :: dtemdx(:,:)         ! [npt, ntgrd] temperature gradient
    REAL(wp), POINTER :: coords(:,:)         ! [npt, 3] integration point coords
    REAL(wp), POINTER :: celent(:)           ! [npt] element characteristic length
    INTEGER(i4)           :: nstatv    = 0_i4
    REAL(wp), POINTER :: statev(:,:)         ! [npt, nstatv] SDVs at start
    INTEGER(i4)           :: nprops    = 0_i4
    REAL(wp), POINTER :: props(:)            ! [nprops] (shared across points)
    CHARACTER(LEN=8)      :: cmname    = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_UMATHT_Block_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_Therm_UMATHT_Block_State
  !   Collected outputs from the block of UMATHT calls.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Therm_UMATHT_Block_State
    INTEGER(i4)           :: npt       = 0_i4
    INTEGER(i4)           :: ntgrd     = 3_i4
    INTEGER(i4)           :: ntens     = 6_i4
    !-- Per-point outputs
    REAL(wp), ALLOCATABLE :: dudt(:)             ! [npt] dU/dT  internal energy rate
    REAL(wp), ALLOCATABLE :: rpl(:)              ! [npt] volumetric heat generation
    REAL(wp), ALLOCATABLE :: drpldt(:)           ! [npt] dRPL/dT
    REAL(wp), ALLOCATABLE :: drplde(:,:)         ! [npt, ntens] dRPL/dε
    REAL(wp), ALLOCATABLE :: flux(:,:)           ! [npt, ntgrd] heat flux vector
    REAL(wp), ALLOCATABLE :: dfdt(:,:)           ! [npt, ntgrd] dflux/dT
    REAL(wp), ALLOCATABLE :: dfdg(:,:,:)         ! [npt, ntgrd, ntgrd] dflux/d(grad T)
    REAL(wp), ALLOCATABLE :: statev_curr(:,:)     ! [npt, nstatv] updated SDVs
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_UMATHT_Block_State

  ! ------------------------------------------------------------------ !
  ! PH_Therm_UMATHT_Block_Algo
  !   Algorithmic parameters for the block-level UMATHT loop.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Therm_UMATHT_Block_Algo
    LOGICAL     :: symmetrize_conductance  = .FALSE.  ! force DFDG to be symmetric
    LOGICAL     :: skip_zero_dtemp         = .FALSE.  ! skip pts with |dtemp|<tol
    REAL(wp)    :: dtemp_tol               = 1.0e-14_wp
    INTEGER(i4) :: max_iter                = 20_i4    ! inner NR iteration limit
    REAL(wp)    :: flux_conv_tol           = 1.0e-10_wp
    LOGICAL     :: collect_diagnostics     = .FALSE.  ! accumulate block residuals
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_UMATHT_Block_Algo

  !=============================================================================
  ! CoupledField — Fully coupled temperature-displacement increment
  !   Stores the combined thermo-mechanical driving inputs and outputs for a
  !   fully coupled increment (Abaqus *COUPLED TEMPERATURE-DISPLACEMENT step).
  !=============================================================================

  TYPE, PUBLIC :: PH_Therm_CoupledField_Ctx
    !-- Mechanical driving
    REAL(wp)  :: dstran(6)   = 0.0_wp   ! mechanical strain increment
    REAL(wp)  :: dfgrd1(3,3) = 0.0_wp   ! deformation gradient at end of increment
    REAL(wp)  :: drot(3,3)   = 0.0_wp   ! rotation increment
    !-- Thermal driving
    REAL(wp)  :: temp        = 0.0_wp   ! temperature at end of increment
    REAL(wp)  :: dtemp       = 0.0_wp   ! temperature increment
    REAL(wp)  :: dtemdx(3)  = 0.0_wp   ! temperature gradient at end
    !-- Shared increment info
    REAL(wp)  :: dtime       = 0.0_wp
    REAL(wp)  :: time(2)     = 0.0_wp
    REAL(wp)  :: coords(3)   = 0.0_wp
    REAL(wp)  :: celent      = 0.0_wp
    INTEGER(i4) :: nstatv    = 0_i4
    INTEGER(i4) :: nprops    = 0_i4
    REAL(wp), POINTER :: statev(:)   ! [nstatv] SDVs at start
    REAL(wp), POINTER :: props(:)    ! [nprops]
    CHARACTER(LEN=8) :: cmname = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_CoupledField_Ctx

  TYPE, PUBLIC :: PH_Therm_CoupledField_State
    !-- Mechanical outputs (UMAT-style)
    REAL(wp) :: stress(6)    = 0.0_wp   ! O Cauchy stress tensor
    REAL(wp) :: ddsdde(6,6)  = 0.0_wp   ! O tangent modulus
    !-- Thermal outputs (UMATHT-style)
    REAL(wp) :: flux(3)      = 0.0_wp   ! O heat flux vector
    REAL(wp) :: dfdt(3)      = 0.0_wp   ! O dflux/dT
    REAL(wp) :: dfdg(3,3)    = 0.0_wp   ! O dflux/d(grad T)
    REAL(wp) :: dudt         = 0.0_wp   ! O dU/dT
    REAL(wp) :: rpl          = 0.0_wp   ! IO volumetric heat generation
    REAL(wp) :: drpldt       = 0.0_wp   ! O dRPL/dT
    REAL(wp) :: drplde(6)    = 0.0_wp   ! O dRPL/dε
    !-- Coupling terms
    REAL(wp) :: ddsddt(6)    = 0.0_wp   ! O dσ/dT  thermal tangent coupling
    REAL(wp) :: drplde_therm(6) = 0.0_wp! O dRPL/dε coupling
    !-- SDVs
    REAL(wp), ALLOCATABLE :: statev_curr(:) ! [nstatv] O updated SDVs
    REAL(wp) :: pnewdt       = 1.0_wp   ! IO cutback signal
    LOGICAL  :: is_updated   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_CoupledField_State

  TYPE, PUBLIC :: PH_Therm_CoupledField_Algo
    INTEGER(i4) :: max_iter_mech     = 20_i4      ! mechanical NR iterations
    INTEGER(i4) :: max_iter_therm    = 20_i4      ! thermal NR iterations
    REAL(wp)    :: stress_conv_tol   = 1.0e-6_wp
    REAL(wp)    :: flux_conv_tol     = 1.0e-10_wp
    LOGICAL     :: symmetric_tangent = .TRUE.     ! enforce symmetric ddsdde
    LOGICAL     :: use_operator_split = .FALSE.   ! staggered vs monolithic solve
    REAL(wp)    :: pnewdt_min        = 0.1_wp     ! minimum allowed pnewdt
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_CoupledField_Algo

  !=============================================================================
  ! DFLUX — Distributed heat flux BC (thermal)
  !   User-defined heat flux per unit area on surfaces/volumes (DFLUX).
  !   Called per integration point on the thermal boundary.
  !=============================================================================

  TYPE, PUBLIC :: PH_Therm_DFLUX_Ctx
    REAL(wp)  :: temp        = 0.0_wp   ! I temperature at integration point
    REAL(wp)  :: time(2)     = 0.0_wp   ! I TIME(2)
    REAL(wp)  :: dtime       = 0.0_wp   ! I time increment
    REAL(wp)  :: coords(3)   = 0.0_wp   ! I integration point coordinates
    REAL(wp)  :: normal(3)   = 0.0_wp   ! I outward surface normal (surface flux)
    REAL(wp)  :: area        = 0.0_wp   ! I facet/point area weight
    INTEGER(i4) :: jltyp     = 0_i4    ! I load type flag
    INTEGER(i4) :: nprops    = 0_i4
    REAL(wp), POINTER :: props(:)   ! [nprops] material/load constants
    CHARACTER(LEN=8) :: amplitude_name = ' '
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_DFLUX_Ctx

  TYPE, PUBLIC :: PH_Therm_DFLUX_State
    REAL(wp) :: flux    = 0.0_wp   ! O  heat flux magnitude (W/m² or W/m³)
    REAL(wp) :: dfluxdt = 0.0_wp   ! O  dflux/dT (linearisation for Newton)
    LOGICAL  :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_DFLUX_State

  TYPE, PUBLIC :: PH_Therm_DFLUX_Algo
    LOGICAL     :: provide_linearisation = .TRUE.  ! fill dfluxdt for Newton
    INTEGER(i4) :: flux_type             = 0_i4   ! 0=surface, 1=volumetric (body flux)
    REAL(wp)    :: flux_scale            = 1.0_wp
    LOGICAL     :: temperature_dependent = .FALSE. ! flag: flux depends on T
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_DFLUX_Algo

  !=============================================================================
  ! FILM — Surface film (convection) boundary condition
  !   User defines film coefficient h and sink temperature T_sink.
  !   ABAQUS FILM subroutine arguments: TEMP, KSTEP, KINC, TIME, DTIME,
  !     COORDS, JLTYP, FIELD, NFIELD → returns H, SINKtemp
  !=============================================================================

  TYPE, PUBLIC :: PH_Therm_FILM_Ctx
    REAL(wp)  :: temp        = 0.0_wp   ! I temperature at surface point
    REAL(wp)  :: time(2)     = 0.0_wp   ! I TIME(2)
    REAL(wp)  :: dtime       = 0.0_wp
    REAL(wp)  :: coords(3)   = 0.0_wp   ! I surface point coordinates
    REAL(wp)  :: normal(3)   = 0.0_wp   ! I outward normal
    INTEGER(i4) :: jltyp     = 0_i4    ! I film type flag
    INTEGER(i4) :: nfield    = 0_i4    ! number of predefined field variables
    REAL(wp), POINTER :: field(:)   ! [nfield] field variable values
    INTEGER(i4) :: nprops    = 0_i4
    REAL(wp), POINTER :: props(:)
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_FILM_Ctx

  TYPE, PUBLIC :: PH_Therm_FILM_State
    REAL(wp) :: h_film    = 0.0_wp   ! O  film (convection) coefficient h [W/(m²·K)]
    REAL(wp) :: sink_t = 0.0_wp   ! O  sink temperature T_sink [K]
    REAL(wp) :: dhdt      = 0.0_wp   ! O  dh/dT (linearisation)
    LOGICAL  :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_FILM_State

  TYPE, PUBLIC :: PH_Therm_FILM_Algo
    LOGICAL     :: temperature_dependent_h    = .FALSE. ! h depends on surface T
    LOGICAL     :: temperature_dependent_sink = .FALSE. ! T_sink depends on field
    LOGICAL     :: provide_dh_dt             = .TRUE.  ! fill dhdt for Newton
    REAL(wp)    :: h_floor                   = 0.0_wp  ! minimum film coefficient
    REAL(wp)    :: sink_temp_default         = 293.15_wp ! default ambient temp [K]
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Therm_FILM_Algo

END MODULE PH_Thermal_Types
