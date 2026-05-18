!===============================================================================
! Module: PH_Contact_Types                                        [Template v1.1]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Contact — Ctx / State / Algo types for per-increment contact
!
! Purpose:
!   Defines the full Ctx / State / Algo three-type system for contact
!   computation at the PH_ layer.  v1.1 adds:
!   - PH_Contact_Base_State   (traction output: normal + tangential)
!   - PH_Contact_VUINTER_Ctx  (Explicit vectorised block context)
!   - PH_Contact_GAPCON_Ctx   (gap conductance thermal)
!
! Type roles:
!   PH_Contact_Base_Ctx  – Per-increment driving inputs for contact eval
!   PH_Contact_Base_State– Traction / pressure output (UINTER/VUINTER returns)
!   PH_Contact_Base_Algo – Per-increment iteration control
!
! Field assignment (UINTER/UFRIC parameter map):
!   GAP    → gap           current gap
!   SLIP1  → slip1         tangent slip 1
!   SLIP2  → slip2         tangent slip 2
!   TEMP   → temp          contact temperature
!   PRES   → pressure      normal pressure
!   NOEL   → elem_id       contact element
!   NPT    → integ_pt_id   integration point
!
! Layer dependency:
!   USE IF_Prec      (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_Contact_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Contact_Base_Ctx
  PUBLIC :: PH_Contact_Base_State
  PUBLIC :: PH_Contact_Base_Algo
  PUBLIC :: PH_Contact_VUINTER_Ctx
  PUBLIC :: PH_Contact_GAPCON_Ctx

  !-----------------------------------------------------------------------------
  ! CTX — Contact Computation Context (per-increment driving inputs)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_Base_Ctx
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
  END TYPE PH_Contact_Base_Ctx

  !-----------------------------------------------------------------------------
  ! STATE — Contact Computation Output
  !   Traction/pressure results written by UINTER/VUINTER.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_Base_State
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
  END TYPE PH_Contact_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Per-Increment Algorithm Control
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_Base_Algo
    !-- Contact iterations
    INTEGER(i4) :: max_iter = 50       ! Maximum contact iterations
    REAL(wp)    :: tolerance = 1.0e-5_wp  ! Convergence tolerance
    !-- Time-step suggestion
    REAL(wp) :: pnewdt_min = 0.1_wp   ! Minimum acceptable time step ratio
    REAL(wp) :: pnewdt_max = 2.0_wp   ! Maximum allowed time step ratio
    !-- Stabilization
    LOGICAL  :: use_stabilization = .FALSE. ! Use stabilization
  END TYPE PH_Contact_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_Contact_VUINTER_Ctx — VUINTER (Explicit block) driving inputs
  !   All arrays have first dimension = nblock.
  !   Maps to VUINTER arguments: NBLOCK, NFDIR, NSHR
  !-----------------------------------------------------------------------------
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

  !-----------------------------------------------------------------------------
  ! PH_Contact_GAPCON_Ctx — GAPCON: gap thermal conductance
  !   Used in Standard contact thermal analyses.
  !-----------------------------------------------------------------------------
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

  !-----------------------------------------------------------------------------
  ! PH_Contact_UINTER_State — UINTER output state
  !   Carries traction, Jacobian, and status written back by UINTER.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_UINTER_State
    REAL(wp) :: traction(3)     = 0.0_wp  ! OUT: contact traction vector [Pa]
    REAL(wp) :: dtraction(3,3)  = 0.0_wp  ! OUT: traction Jacobian [Pa/m]
    REAL(wp), ALLOCATABLE :: svars(:)     ! IO:  state variables [nsvars]
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_UINTER_State

  !-----------------------------------------------------------------------------
  ! PH_Contact_VUINTER_State — VUINTER block output state (Explicit)
  !   Block arrays for all contact pairs in the block.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_VUINTER_State
    REAL(wp), ALLOCATABLE :: traction_blk(:,:)   ! [nblock, 3] output tractions
    REAL(wp), ALLOCATABLE :: dtraction_blk(:,:,:)! [nblock, 3, 3] Jacobian
    REAL(wp), ALLOCATABLE :: svars_blk(:,:)      ! [nblock, nsvars]
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_VUINTER_State

  !-----------------------------------------------------------------------------
  ! PH_Contact_GAPCON_State — GAPCON gap conductance output state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_GAPCON_State
    REAL(wp) :: cond         = 0.0_wp  ! OUT: gap conductance [W/(mxb2·K)]
    REAL(wp) :: dcond_dgap   = 0.0_wp  ! OUT: d(cond)/d(gap)
    REAL(wp) :: dcond_dpres  = 0.0_wp  ! OUT: d(cond)/d(pressure)
    LOGICAL  :: converged    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_GAPCON_State

  !-----------------------------------------------------------------------------
  ! PH_Contact_GAPUNIT_Ctx — GAPUNIT radiation/electrical conductance Ctx
  !   GAPUNIT: unit emissivity and electrical conductance for gap elements
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx
    REAL(wp) :: gap      = 0.0_wp    ! Current gap [m]
    REAL(wp) :: temp1    = 0.0_wp    ! Surface 1 temperature [K]
    REAL(wp) :: temp2    = 0.0_wp    ! Surface 2 temperature [K]
    REAL(wp) :: pressure = 0.0_wp    ! Contact pressure [Pa]
    REAL(wp) :: coords(3)= 0.0_wp    ! Contact point coordinates
  END TYPE PH_Contact_GAPUNIT_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Contact_GAPUNIT_State — GAPUNIT output state
  !   Carries unit conductance (thermal/electrical) computed by user
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_State
    REAL(wp) :: unit_cond     = 0.0_wp  ! OUT: unit conductance [W/(mxb2·K)] or [A/V]
    REAL(wp) :: dcond_dgap    = 0.0_wp  ! OUT: d(cond)/d(gap)
    REAL(wp) :: dcond_dtemp1  = 0.0_wp  ! OUT: d(cond)/d(T1)
    REAL(wp) :: dcond_dtemp2  = 0.0_wp  ! OUT: d(cond)/d(T2)
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_GAPUNIT_State

  !-----------------------------------------------------------------------------
  ! PH_Contact_UINTER_Ctx — UINTER per-call driving inputs
  !   UINTER(STRESS, DDSDDT, FLUX, DDFLUX, SVARS, NSVARS, PROPS, COORDS, ...)
  !-----------------------------------------------------------------------------
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

  !-----------------------------------------------------------------------------
  ! PH_Contact_UINTER_Algo — UINTER algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_UINTER_Algo
    INTEGER(i4) :: max_iter   = 20_i4
    REAL(wp)    :: tol_stress = 1.0e-8_wp
    LOGICAL     :: thermal    = .FALSE.   ! include thermal flux
    LOGICAL     :: symmetric  = .TRUE.    ! symmetric contact stiffness
  END TYPE PH_Contact_UINTER_Algo

  !-----------------------------------------------------------------------------
  ! PH_Contact_VUINTER_Algo — VUINTER vectorised algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_VUINTER_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: thermal    = .FALSE.
    REAL(wp)    :: tol_stress = 1.0e-8_wp
  END TYPE PH_Contact_VUINTER_Algo

  !-----------------------------------------------------------------------------
  ! PH_Contact_GAPCON_Algo — GAPCON thermal contact conductance algorithm
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_GAPCON_Algo
    REAL(wp)    :: h_ref      = 0.0_wp   ! reference conductance
    LOGICAL     :: pressure_dep = .FALSE. ! pressure-dependent conductance
    INTEGER(i4) :: interp     = 0_i4     ! 0=step, 1=linear interpolation
  END TYPE PH_Contact_GAPCON_Algo

  !-----------------------------------------------------------------------------
  ! PH_Contact_GAPUNIT_Algo — GAPUNIT radiation algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Algo
    REAL(wp)    :: emissivity = 0.0_wp  ! emissivity coefficient
    REAL(wp)    :: boltzmann  = 5.67e-8_wp ! Stefan-Boltzmann
    LOGICAL     :: view_factor= .FALSE.  ! use view factor
  END TYPE PH_Contact_GAPUNIT_Algo

  ! ------------------------------------------------------------------ !
  ! PH_Contact_GAPCON_Ctx
  !   Driving context for GAPCON (gap conductance / radiation).
  !   Passed on each contact-interface integration-point call.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Contact_GAPCON_Ctx
    REAL(wp)    :: clearance    = 0.0_wp  ! I clearance (> 0 = open gap)
    REAL(wp)    :: pressure     = 0.0_wp  ! I contact pressure (compressive +)
    REAL(wp)    :: temp_a       = 0.0_wp  ! I temperature at surface A
    REAL(wp)    :: temp_b       = 0.0_wp  ! I temperature at surface B
    REAL(wp)    :: dtime        = 0.0_wp  ! I time increment
    REAL(wp)    :: coords(3)    = 0.0_wp  ! I coordinates of contact point
    INTEGER(i4) :: nprops       = 0_i4   ! I number of gap-conductance props
    REAL(wp), POINTER :: props(:)    ! I [nprops] user-defined props
    REAL(wp)    :: mass_flow    = 0.0_wp  ! I mass flow rate (fluid gap)
    LOGICAL     :: is_open      = .TRUE.  ! I gap open flag
  END TYPE PH_Contact_GAPCON_Ctx

END MODULE PH_Contact_Types