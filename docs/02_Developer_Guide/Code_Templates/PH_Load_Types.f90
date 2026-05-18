!===============================================================================
! Module: PH_Load_Types                                           [Template v1.1]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Load — Ctx / State / Algo types for per-increment load computation
!
! Purpose:
!   Defines the Ctx / State / Algo three-type system for load computation at the
!   PH_ (physical) layer.
!
!   v1.1 additions:
!   - Added: PH_Load_Base_State    (computed load output: value, tangent)
!   - Added: PH_Load_DFLUX_Ctx    (DFLUX: flux + coords + surface name)
!   - Added: PH_Load_FILM_Ctx     (FILM: film coeff + sink temp at contact pt)
!   - Added: PH_Load_HETVAL_Ctx   (HETVAL: material point context)
!
! Type roles:
!   PH_Load_Base_Ctx  – Per-increment driving inputs for load evaluation:
!                        coordinates, time, element/face information
!
!   PH_Load_Base_Algo – Per-increment iteration control for load application
!
! Field assignment (DLOAD/CLOAD parameter map):
!   COORDS  → coords(3)       integration point / node coordinates
!   TIME    → time_current    current analysis time
!   NOEL    → elem_id         current element number
!   NPT     → integ_pt_id     current integration point
!   KSTEP   → step_id         current analysis step
!   KINC    → inc_id          current increment
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!===============================================================================
MODULE PH_Load_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Load_Base_Ctx
  PUBLIC :: PH_Load_Base_Algo
  PUBLIC :: PH_Load_Base_State
  PUBLIC :: PH_Load_DFLUX_Ctx
  PUBLIC :: PH_Load_FILM_Ctx
  PUBLIC :: PH_Load_HETVAL_Ctx

  !-----------------------------------------------------------------------------
  ! CTX — Load Computation Context (per-increment driving inputs)
  !    These are "THIS increment's driving inputs" for load evaluation
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_Base_Ctx
    !-- Spatial context
    REAL(wp) :: coords(3) = 0.0_wp   ! COORDS  integration point/node coords
    !-- Temporal context (via RT_Com_Base_Ctx; kept here for direct access)
    REAL(wp) :: time_current = 0.0_wp  ! TIME(1)  current step time
    REAL(wp) :: time_total = 0.0_wp    ! TIME(2)  total analysis time
    !-- Element/Node identification
    INTEGER(i4) :: elem_id = 0     ! NOEL   element number
    INTEGER(i4) :: integ_pt_id = 0 ! NPT    integration point
    INTEGER(i4) :: node_id = 0     ! NODE   node number (for CLOAD)
    !-- Element face information
    INTEGER(i4) :: face_id = 0     ! Face identifier
    INTEGER(i4) :: layer_id = 0    ! LAYER  shell/composite layer
    INTEGER(i4) :: sect_pt_id = 0  ! KSPT   section point within layer
    !-- ABAQUS load type identifier
    CHARACTER(LEN=80) :: sname = '' ! SNAME surface name
    INTEGER(i4) :: jltyp = 0       ! JLTYP load type code
  END TYPE PH_Load_Base_Ctx

  !-----------------------------------------------------------------------------
  ! STATE — Load Computation Output
  !    Computed load values returned at each call.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_Base_State
    !-- Computed load output
    REAL(wp) :: value     = 0.0_wp  ! Computed load magnitude (DLOAD: F; DFLUX: Q)
    REAL(wp) :: value_vec(3) = 0.0_wp ! Vectorial load (body force DLOAD)
    REAL(wp) :: d_value   = 0.0_wp  ! d(value)/d(variable) for tangent
    !-- Convergence bookkeeping
    LOGICAL     :: converged   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Per-Increment Algorithm Control
  !    Iteration control for load evaluation
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_Base_Algo
    !-- Iteration control
    INTEGER(i4) :: max_iter = 10      ! Maximum evaluation iterations
    REAL(wp)    :: tolerance = 1.0e-6_wp  ! Convergence tolerance
    !-- Load update control
    LOGICAL  :: allow_update = .TRUE.  ! Allow load magnitude update
    !-- Time-step suggestion
    REAL(wp) :: pnewdt_min = 0.1_wp   ! Minimum acceptable time step ratio
    REAL(wp) :: pnewdt_max = 2.0_wp   ! Maximum allowed time step ratio
  END TYPE PH_Load_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_Load_DFLUX_Ctx — DFLUX/VDFLUX-specific context
  !   Additional fields needed for thermal flux computation
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_DFLUX_Ctx
    REAL(wp) :: temp      = 0.0_wp   ! TEMP: current temperature [K]
    REAL(wp) :: coords(3) = 0.0_wp   ! COORDS: integration point coords
    INTEGER(i4) :: jltyp  = 11_i4   ! JLTYP: 1=body, 11=face n
    CHARACTER(LEN=80) :: sname = ''  ! SNAME: surface/element set name
    INTEGER(i4) :: noel   = 0_i4    ! NOEL: element number
    INTEGER(i4) :: npt    = 0_i4    ! NPT: integration point
    INTEGER(i4) :: layer  = 0_i4    ! LAYER: shell layer
    INTEGER(i4) :: kspt   = 0_i4    ! KSPT: section point
  END TYPE PH_Load_DFLUX_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Load_FILM_Ctx — FILM/VFILM-specific context
  !   Fields for film condition (convection) computation
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_FILM_Ctx
    REAL(wp) :: temp      = 0.0_wp   ! Current surface temperature [K]
    REAL(wp) :: coords(3) = 0.0_wp   ! Contact point coordinates
    INTEGER(i4) :: jltyp  = 11_i4   ! JLTYP: face identifier
    CHARACTER(LEN=80) :: sname = ''  ! Surface name
    INTEGER(i4) :: noel   = 0_i4    ! Element number
    INTEGER(i4) :: npt    = 0_i4    ! Integration point
    !-- Outputs filled by FILM/VFILM
    REAL(wp) :: h_film    = 0.0_wp   ! Film coefficient [W/(m²·K)]
    REAL(wp) :: temp_sink = 0.0_wp   ! Sink temperature [K]
    REAL(wp) :: dh_dtemp  = 0.0_wp   ! dh/dT for Jacobian
    REAL(wp) :: dsink_dtemp = 0.0_wp ! dT_sink/dT for Jacobian
  END TYPE PH_Load_FILM_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Load_HETVAL_Ctx — HETVAL-specific context
  !   Internal heat generation computation
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_HETVAL_Ctx
    REAL(wp) :: temp      = 0.0_wp   ! TEMP: current temperature [K]
    REAL(wp) :: dtemp     = 0.0_wp   ! DTEMP: temperature increment
    REAL(wp), POINTER :: statev(:) ! STATEV: solution-dep. variables
    INTEGER(i4) :: nstatv = 0_i4    ! NSTATV: no. of state variables
    CHARACTER(LEN=80) :: cmname = '' ! CMNAME: material name
    !-- Output
    REAL(wp) :: flux      = 0.0_wp   ! Computed heat flux [W/m³]
    REAL(wp) :: dflux_dtemp = 0.0_wp ! dFlux/dT for Jacobian
  END TYPE PH_Load_HETVAL_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Load_VDLOAD_Ctx — VDLOAD (Explicit vectorised distributed load) driving Ctx
  !   VDLOAD(F, KSTEP, KINC, TIME, AMPLITUDE, NBLOCK, NDIM, COORDS, DIRCOS,
  !          JLTYP, SNAME, STEPTIME, TOTALTIME, AMPLITUDE_VALUE)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_VDLOAD_Ctx
    INTEGER(i4) :: nblock     = 1_i4   ! NBLOCK: integration pts in this call
    INTEGER(i4) :: ndim       = 3_i4   ! NDIM: spatial dimension
    INTEGER(i4) :: jltyp      = 0_i4   ! JLTYP: load type identifier
    CHARACTER(LEN=80) :: sname = ''    ! SNAME: element set name
    REAL(wp), POINTER :: coords(:,:)   ! [nblock, ndim] integration pt coords
    REAL(wp), POINTER :: dircos(:,:,:) ! [nblock, ndim, ndim] direction cosines
    REAL(wp) :: step_time     = 0.0_wp
    REAL(wp) :: total_time    = 0.0_wp
    REAL(wp) :: amplitude     = 1.0_wp ! Current amplitude value
  END TYPE PH_Load_VDLOAD_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Load_VDLOAD_State — VDLOAD output state
  !   F(NBLOCK): traction/pressure magnitudes output by VDLOAD
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_VDLOAD_State
    REAL(wp), ALLOCATABLE :: f_blk(:)   ! [nblock] distributed load values
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_VDLOAD_State

  !-----------------------------------------------------------------------------
  ! PH_Load_UTRACLOAD_Ctx — UTRACLOAD non-uniform traction load driving Ctx
  !   UTRACLOAD(ALPHA, T_USER, KSTEP, KINC, TIME, NOEL, NPT, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_UTRACLOAD_Ctx
    INTEGER(i4) :: noel    = 0_i4    ! NOEL: element number
    INTEGER(i4) :: npt     = 0_i4    ! NPT: integration point number
    INTEGER(i4) :: layer   = 0_i4    ! LAYER: layer number (composite)
    INTEGER(i4) :: kspt    = 0_i4    ! KSPT: section point in layer
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    REAL(wp) :: coords(3)  = 0.0_wp  ! Integration point coordinates
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    !-- Output slots
    REAL(wp) :: alpha      = 0.0_wp  ! OUT: traction direction/magnitude multiplier
    REAL(wp) :: t_user(3)  = 0.0_wp  ! OUT: user traction vector [Pa]
  END TYPE PH_Load_UTRACLOAD_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Load_DFLUX_State — DFLUX output state (heat flux computation result)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_DFLUX_State
    REAL(wp) :: flux_val    = 0.0_wp  ! OUT: computed heat flux [W/mxb2 or W/mxb3]
    REAL(wp) :: dflux_dtemp = 0.0_wp  ! OUT: dFlux/dT for Jacobian
    LOGICAL  :: converged   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_DFLUX_State

  !-----------------------------------------------------------------------------
  ! PH_Load_FILM_State — FILM convection output state
  !   Output: film coefficient h and dh/dT
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_FILM_State
    REAL(wp) :: h_coeff      = 0.0_wp  ! OUT: film (convection) coefficient h [W/(mxb2·K)]
    REAL(wp) :: dh_dtemp     = 0.0_wp  ! OUT: dh/dT for Jacobian
    REAL(wp) :: sink_t    = 0.0_wp  ! OUT: sink temperature T_sink [K]
    LOGICAL  :: converged    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_FILM_State

  !-----------------------------------------------------------------------------
  ! PH_Load_HETVAL_State — HETVAL heat generation output state
  !   Output: volumetric heat generation rate and its temperature derivative
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_HETVAL_State
    REAL(wp) :: flux         = 0.0_wp  ! OUT: volumetric heat generation [W/mxb3]
    REAL(wp) :: dflux_dtemp  = 0.0_wp  ! OUT: d(flux)/dT
    LOGICAL  :: converged    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_HETVAL_State

  !-----------------------------------------------------------------------------
  ! PH_Load_DLOAD_Ctx — DLOAD per-call driving inputs
  !   DLOAD(F, KSTEP, KINC, TIME, NOEL, NPT, COORDS, JLTYP, SNAME)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_DLOAD_Ctx
    REAL(wp) :: coords(3) = 0.0_wp  ! I COORDS  spatial coordinates
    REAL(wp) :: time(2)   = 0.0_wp  ! I TIME(2) step/total time
    INTEGER(i4) :: noel   = 0_i4    ! I NOEL    element number
    INTEGER(i4) :: npt    = 0_i4    ! I NPT     integration point
    INTEGER(i4) :: jltyp  = 0_i4    ! I JLTYP   load type flag
    INTEGER(i4) :: kstep  = 0_i4
    INTEGER(i4) :: kinc   = 0_i4
    CHARACTER(LEN=80) :: sname = ' ' ! I SNAME   surface/element set name
  END TYPE PH_Load_DLOAD_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Load_DLOAD_State — DLOAD output (distributed load magnitude)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_DLOAD_State
    REAL(wp) :: f          = 0.0_wp  ! O F       distributed load magnitude
    LOGICAL  :: is_valid   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_DLOAD_State

  !-----------------------------------------------------------------------------
  ! PH_Load_DLOAD_Algo — DLOAD algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_DLOAD_Algo
    LOGICAL     :: follower_force = .FALSE.  ! follower force flag
    INTEGER(i4) :: amplitude_id   = 0_i4    ! 0=instant, >0=amplitude table id
    REAL(wp)    :: scale_factor   = 1.0_wp  ! load scale factor
  END TYPE PH_Load_DLOAD_Algo

  !-----------------------------------------------------------------------------
  ! PH_Load_DFLUX_Algo — DFLUX algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_DFLUX_Algo
    INTEGER(i4) :: flux_type   = 0_i4   ! 0=body heat, 1=surface flux
    REAL(wp)    :: scale_factor = 1.0_wp
    LOGICAL     :: temp_dependent = .FALSE.
  END TYPE PH_Load_DFLUX_Algo

  !-----------------------------------------------------------------------------
  ! PH_Load_FILM_Algo — FILM (convection) algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_FILM_Algo
    REAL(wp)    :: h_ref       = 0.0_wp  ! reference film coefficient
    LOGICAL     :: nonlinear   = .FALSE.  ! temperature-dependent h
    INTEGER(i4) :: newton_max  = 5_i4   ! max Newton iterations for h(T)
  END TYPE PH_Load_FILM_Algo

  !-----------------------------------------------------------------------------
  ! PH_Load_VDLOAD_Algo — VDLOAD block algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_VDLOAD_Algo
    INTEGER(i4) :: nblock_max  = 512_i4  ! max block size
    LOGICAL     :: follower    = .FALSE.
    REAL(wp)    :: scale_factor = 1.0_wp
  END TYPE PH_Load_VDLOAD_Algo

  !-----------------------------------------------------------------------------
  ! PH_Load_UTRACLOAD_State — UTRACLOAD traction output state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_UTRACLOAD_State
    REAL(wp) :: traction(3)  = 0.0_wp  ! O TRACTION components
    REAL(wp) :: dtrac_dtemp  = 0.0_wp  ! O d(traction)/d(temp)
    LOGICAL  :: is_valid      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Load_UTRACLOAD_State

  !-----------------------------------------------------------------------------
  ! PH_Load_UTRACLOAD_Algo — UTRACLOAD algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_UTRACLOAD_Algo
    LOGICAL     :: pressure_only = .FALSE.  ! normal component only
    REAL(wp)    :: scale_factor  = 1.0_wp
  END TYPE PH_Load_UTRACLOAD_Algo

  !-----------------------------------------------------------------------------
  ! PH_Load_HETVAL_Algo — HETVAL heat generation algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Load_HETVAL_Algo
    REAL(wp)    :: heat_scale  = 1.0_wp  ! scale factor on heat output
    LOGICAL     :: coupled     = .FALSE.  ! thermo-mechanically coupled
    INTEGER(i4) :: nsvars_used = 0_i4    ! number of state vars used
  END TYPE PH_Load_HETVAL_Algo

END MODULE PH_Load_Types