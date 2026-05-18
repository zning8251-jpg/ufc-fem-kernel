!===============================================================================
! Module: PH_BC_Types                                            [Template v1.1]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Boundary Condition — Ctx / State / Algo types for per-increment BC
!
! Purpose:
!   Defines the full Ctx / State / Algo three-type system for BC computation
!   at the PH_ layer.  v1.1 adds subroutine-specific Ctx types covering:
!   DISP/VDISP, UPOT, UTEMP, UMASFL
!
! v1.1 additions:
!   - Added: PH_BC_Base_State     (computed BC output: prescribed value, tangent)
!   - Added: PH_BC_UPOT_Ctx      (multi-field potential BC: UPOT)
!   - Added: PH_BC_UTEMP_Ctx     (prescribed temperature: UTEMP)
!   - Added: PH_BC_UMASFL_Ctx    (mass flow rate BC: UMASFL)
!
! Field assignment (DISP parameter map):
!   NODE    → node_id         current node number
!   NDOF    → dof_number      current DOF (1=UX,2=UY,...)
!   TIME    → time_current    current analysis time
!   KSTEP   → step_id         current analysis step
!   KINC    → inc_id          current increment
!
! Layer dependency:
!   USE IF_Prec      (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_BC_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_BC_Base_Ctx
  PUBLIC :: PH_BC_Base_State
  PUBLIC :: PH_BC_Base_Algo
  PUBLIC :: PH_BC_UPOT_Ctx
  PUBLIC :: PH_BC_UTEMP_Ctx
  PUBLIC :: PH_BC_UMASFL_Ctx

  !-----------------------------------------------------------------------------
  ! CTX — BC Computation Context (per-increment driving inputs)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_Base_Ctx
    !-- Node identification
    INTEGER(i4) :: node_id = 0    ! NODE   current node number
    INTEGER(i4) :: dof_number = 0 ! NDOF   current degree of freedom
    CHARACTER(LEN=8) :: doflab = '' ! DOFLAB  DOF label string
    !-- Temporal context
    REAL(wp) :: time_current = 0.0_wp  ! TIME(1)  current step time
    REAL(wp) :: time_total = 0.0_wp    ! TIME(2)  total analysis time
    !-- Step/Increment identification
    INTEGER(i4) :: step_id = 0   ! KSTEP  analysis step number
    INTEGER(i4) :: inc_id = 0    ! KINC   increment number
  END TYPE PH_BC_Base_Ctx

  !-----------------------------------------------------------------------------
  ! STATE — BC Computation Output
  !   Computed prescribed values returned at each call.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_Base_State
    !-- Prescribed value output
    REAL(wp) :: disp_val  = 0.0_wp  ! DISP: prescribed displacement/rotation
    REAL(wp) :: d_disp    = 0.0_wp  ! d(disp)/d(time) for velocity/linearisation
    !-- Convergence bookkeeping
    LOGICAL     :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_BC_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Per-Increment Algorithm Control
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_Base_Algo
    !-- Iteration control
    INTEGER(i4) :: max_iter = 10     ! Maximum evaluation iterations
    REAL(wp)    :: tolerance = 1.0e-6_wp  ! Convergence tolerance
    !-- Time-step suggestion
    REAL(wp) :: pnewdt_min = 0.1_wp  ! Minimum acceptable time step ratio
    REAL(wp) :: pnewdt_max = 2.0_wp  ! Maximum allowed time step ratio
  END TYPE PH_BC_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_BC_UPOT_Ctx — UPOT: multi-field potential boundary condition
  !   Used for coupled thermal-electrical-pore pressure analyses.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UPOT_Ctx
    INTEGER(i4) :: node_id   = 0_i4   ! Node number
    INTEGER(i4) :: dof_id    = 0_i4   ! DOF: 8=T, 9=elec pot, 11=pore p
    CHARACTER(LEN=8) :: doflab = ''    ! DOF label ("TEMP","EPOT","POR")
    REAL(wp) :: time_current = 0.0_wp  ! Current step time
    REAL(wp) :: time_total   = 0.0_wp  ! Total analysis time
    INTEGER(i4) :: step_id   = 0_i4   ! KSTEP
    INTEGER(i4) :: inc_id    = 0_i4   ! KINC
    !-- Output
    REAL(wp) :: pot_val      = 0.0_wp  ! Prescribed potential value
    REAL(wp) :: d_pot        = 0.0_wp  ! d(pot)/d(time)
  END TYPE PH_BC_UPOT_Ctx

  !-----------------------------------------------------------------------------
  ! PH_BC_UTEMP_Ctx — UTEMP: prescribed temperature at nodes
  !   Called during thermal analysis; user specifies nodal temperature.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UTEMP_Ctx
    INTEGER(i4) :: node_id   = 0_i4
    REAL(wp) :: coords(3)    = 0.0_wp  ! Node coordinates
    REAL(wp) :: time_current = 0.0_wp
    REAL(wp) :: time_total   = 0.0_wp
    INTEGER(i4) :: step_id   = 0_i4
    INTEGER(i4) :: inc_id    = 0_i4
    !-- Output
    REAL(wp) :: temp_val     = 0.0_wp  ! Prescribed temperature [K]
    REAL(wp) :: d_t       = 0.0_wp  ! dT/dt rate for transient
  END TYPE PH_BC_UTEMP_Ctx

  !-----------------------------------------------------------------------------
  ! PH_BC_UMASFL_Ctx — UMASFL: prescribed mass flow rate
  !   Used in coupled thermal-fluid analyses.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UMASFL_Ctx
    INTEGER(i4) :: node_id   = 0_i4
    INTEGER(i4) :: dof_id    = 0_i4   ! DOF for mass flow
    CHARACTER(LEN=8) :: doflab = ''
    REAL(wp) :: time_current = 0.0_wp
    REAL(wp) :: time_total   = 0.0_wp
    INTEGER(i4) :: step_id   = 0_i4
    INTEGER(i4) :: inc_id    = 0_i4
    !-- Output
    REAL(wp) :: masfl_val    = 0.0_wp  ! Prescribed mass flow rate [kg/s]
    REAL(wp) :: d_masfl      = 0.0_wp  ! d(masfl)/d(time)
  END TYPE PH_BC_UMASFL_Ctx

  !-----------------------------------------------------------------------------
  ! PH_BC_DISP_State — DISP subroutine output state
  !   Output: prescribed displacement value and its time derivative
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_DISP_State
    REAL(wp) :: u_val    = 0.0_wp   ! OUT: prescribed displacement / rotation [m or rad]
    REAL(wp) :: du_dt    = 0.0_wp   ! OUT: d(u)/d(time) velocity for dynamics
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_BC_DISP_State

  !-----------------------------------------------------------------------------
  ! PH_BC_VDISP_Ctx — VDISP (Explicit vectorised BC) driving Ctx
  !   VDISP(U, KSTEP, KINC, TIME, NBLOCK, NDOF, NCOORDS, KDDOF, NODES, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_VDISP_Ctx
    INTEGER(i4) :: nblock    = 1_i4    ! NBLOCK: nodes in this call
    INTEGER(i4) :: ndof      = 0_i4    ! NDOF: DOF index
    INTEGER(i4) :: ncoords   = 3_i4    ! NCOORDS: spatial dimension
    INTEGER(i4) :: kddof     = 0_i4    ! KDDOF: DOF type identifier
    INTEGER(i4), POINTER :: nodes(:)     ! [nblock] node numbers
    REAL(wp),    POINTER :: coords(:,:)  ! [nblock, ncoords] nodal coords
    REAL(wp) :: step_time    = 0.0_wp
    REAL(wp) :: total_time   = 0.0_wp
  END TYPE PH_BC_VDISP_Ctx

  !-----------------------------------------------------------------------------
  ! PH_BC_VDISP_State — VDISP output state
  !   U(NBLOCK): prescribed values for each node in the block
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_VDISP_State
    REAL(wp), ALLOCATABLE :: u_blk(:)    ! [nblock] prescribed DOF values
    INTEGER(i4) :: nblock = 0
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_BC_VDISP_State

  !-----------------------------------------------------------------------------
  ! PH_BC_UTEMP_State — UTEMP prescribed temperature output state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UTEMP_State
    REAL(wp) :: temp_val  = 0.0_wp  ! OUT: prescribed temperature [K]
    REAL(wp) :: dtemp_dt  = 0.0_wp  ! OUT: dT/dt rate [K/s]
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_BC_UTEMP_State

  !-----------------------------------------------------------------------------
  ! PH_BC_UMASFL_State — UMASFL prescribed mass flow output state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UMASFL_State
    REAL(wp) :: masfl_val  = 0.0_wp  ! OUT: prescribed mass flow rate [kg/s]
    REAL(wp) :: d_masfl_dt = 0.0_wp  ! OUT: d(masfl)/dt
    LOGICAL  :: converged  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_BC_UMASFL_State

  !-----------------------------------------------------------------------------
  ! PH_BC_DISP_Ctx — DISP prescribed displacement per-call driving inputs
  !   DISP(U, KSTEP, KINC, TIME, NODE, NDI, JDOF, COORDS)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_DISP_Ctx
    REAL(wp) :: coords(3) = 0.0_wp  ! I COORDS  node coordinates
    REAL(wp) :: time(2)   = 0.0_wp  ! I TIME(2)
    INTEGER(i4) :: node   = 0_i4    ! I NODE    global node number
    INTEGER(i4) :: ndi    = 3_i4    ! I NDI     no. direct components
    INTEGER(i4) :: jdof   = 0_i4    ! I JDOF    DOF being constrained
    INTEGER(i4) :: kstep  = 0_i4
    INTEGER(i4) :: kinc   = 0_i4
  END TYPE PH_BC_DISP_Ctx

  !-----------------------------------------------------------------------------
  ! PH_BC_DISP_Algo — DISP algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_DISP_Algo
    LOGICAL     :: ramp     = .TRUE.   ! ramp displacement over step
    REAL(wp)    :: scale    = 1.0_wp   ! scale factor
    INTEGER(i4) :: amp_id   = 0_i4    ! amplitude table id
  END TYPE PH_BC_DISP_Algo

  !-----------------------------------------------------------------------------
  ! PH_BC_VDISP_Algo — VDISP (explicit vectorised) algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_VDISP_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: ramp       = .TRUE.
    REAL(wp)    :: scale      = 1.0_wp
  END TYPE PH_BC_VDISP_Algo

  !-----------------------------------------------------------------------------
  ! PH_BC_UPOT_State — UPOT electrical/pore-pressure output
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UPOT_State
    REAL(wp) :: pot          = 0.0_wp  ! O POT     prescribed potential
    REAL(wp) :: dpot_dt      = 0.0_wp  ! O dPOT/dt rate
    LOGICAL  :: is_valid     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_BC_UPOT_State

  !-----------------------------------------------------------------------------
  ! PH_BC_UPOT_Algo — UPOT algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UPOT_Algo
    INTEGER(i4) :: dof_type = 0_i4   ! 0=electric, 1=pore pressure
    REAL(wp)    :: scale    = 1.0_wp
  END TYPE PH_BC_UPOT_Algo

  !-----------------------------------------------------------------------------
  ! PH_BC_UTEMP_Algo — UTEMP prescribed temperature algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UTEMP_Algo
    LOGICAL     :: ramp       = .TRUE.
    REAL(wp)    :: scale      = 1.0_wp
    INTEGER(i4) :: nfield     = 0_i4   ! number of predefined fields
  END TYPE PH_BC_UTEMP_Algo

  !-----------------------------------------------------------------------------
  ! PH_BC_UMASFL_Algo — UMASFL mass flow rate algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_BC_UMASFL_Algo
    REAL(wp)    :: scale      = 1.0_wp
    LOGICAL     :: conserve   = .TRUE.  ! enforce mass conservation
  END TYPE PH_BC_UMASFL_Algo

END MODULE PH_BC_Types