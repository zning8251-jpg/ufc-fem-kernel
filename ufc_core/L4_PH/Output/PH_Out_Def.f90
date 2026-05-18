!===============================================================================
! MODULE: PH_Out_Def
! LAYER:  L4_PH
! DOMAIN: Output
! ROLE:   Def — L4 Output four-type AUTHORITY
! BRIEF:  Four-type definitions for L4 Output thin layer:
!         - PH_Out_Desc: output request metadata (format, variables, frequency)
!         - PH_Out_State: output state (buffer positions, timestamps)
!         - PH_Out_Algo: output strategy (coordinate system, interpolation)
!         - PH_Out_Ctx: current output context (current frame, buffer ptrs)
!
! DESIGN NOTE (P5 半贯通柱): L4 Output is intentionally a thin layer.
!   - Trigger decisions → L5_RT (RT_Out_Mgr)
!   - File I/O → L5_RT (RT_Writer_*)
!   - Physics transforms (coordinate/tensor/IP→node) → here
!
! ABI_Flat mapping:
!   UVARM/VUVARM/URDFIL/UHISTR/USDFLD → PH_Out_Desc state variables
!===============================================================================
MODULE PH_Out_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! Public type declarations
  ! ==========================================================================
  PUBLIC :: PH_Out_Desc
  PUBLIC :: PH_Out_State
  PUBLIC :: PH_Out_Algo
  PUBLIC :: PH_Out_Ctx
  PUBLIC :: PH_Out_Arg

  !-- Output format type constants
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUT_VTK   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUT_HDF5  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUT_ODB   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUT_BINARY = 4_i4

  !-- Tensor component indices (Voigt notation)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_XX = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_YY = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_ZZ = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_XY = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_YZ = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_ZX = 6_i4

  ! ==========================================================================
  ! TYPE: PH_Out_Desc
  ! KIND: Desc
  ! BRIEF: Output request metadata — format, requested variables, frequency
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Out_Desc
    INTEGER(i4) :: output_format    = PH_OUT_VTK     ! VTK/HDF5/ODB/BINARY
    INTEGER(i4) :: n_field_vars     = 0_i4           ! Number of active field variables
    INTEGER(i4) :: n_history_vars   = 0_i4           ! Number of active history vars
    INTEGER(i4) :: write_frequency  = 1_i4           ! Every N increments
    LOGICAL     :: output_at_end    = .TRUE.         ! Force output at step end
    LOGICAL     :: output_initial    = .FALSE.        ! Write initial state
    CHARACTER(LEN=64) :: coordinate_system = "GLOBAL" ! GLOBAL/LOCAL/CYLINDRICAL
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Desc

  ! ==========================================================================
  ! TYPE: PH_Out_State
  ! KIND: State
  ! BRIEF: Output state — buffer positions, last write timestamp
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Out_State
    INTEGER(i4) :: last_write_step  = 0_i4           ! Step of last write
    INTEGER(i4) :: last_write_inc   = 0_i4           ! Increment of last write
    INTEGER(i4) :: frame_count      = 0_i4           ! Total frames written
    REAL(wp)    :: last_write_time  = 0.0_wp         ! Time of last write
    LOGICAL     :: buffer_dirty     = .FALSE.        ! Buffer contains unwritten data
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_State

  ! ==========================================================================
  ! TYPE: PH_Out_Algo
  ! KIND: Algo
  ! BRIEF: Output algorithm strategy — coordinate transform method, interpolation
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Out_Algo
    INTEGER(i4) :: transform_method    = 1_i4        ! 1=direct, 2=rotation_matrix
    INTEGER(i4) :: interpolation_order  = 1_i4       ! 1=linear, 2=quadratic
    LOGICAL     :: extrapolate_boundary = .FALSE.    ! Extrapolate at boundaries
    REAL(wp)    :: extrapolation_limit  = 0.1_wp     ! Max extrapolation fraction
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Algo

  ! ==========================================================================
  ! TYPE: PH_Out_Ctx
  ! KIND: Ctx
  ! BRIEF: Output context — current frame ID, buffer pointers
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Out_Ctx
    INTEGER(i4) :: current_frame_id   = 0_i4
    INTEGER(i4) :: current_step_id    = 0_i4
    INTEGER(i4) :: current_inc_id     = 0_i4
    REAL(wp)    :: current_time       = 0.0_wp
    LOGICAL     :: is_triggered       = .FALSE.      ! Output triggered at this inc
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Ctx

  ! ==========================================================================
  ! TYPE: PH_Out_Arg
  ! BRIEF: Structured I/O bundle for output operations
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Out_Arg
    TYPE(PH_Out_Desc)  :: desc     ! [IN]  output configuration
    TYPE(PH_Out_State) :: state    ! [INOUT] output state
    TYPE(PH_Out_Algo)  :: algo     ! [IN]  algorithm strategy
    TYPE(PH_Out_Ctx)   :: ctx      ! [IN]  current context
    INTEGER(i4)        :: n_values = 0_i4     ! [IN]  number of values to process
    REAL(wp), ALLOCATABLE :: buffer(:)        ! [OUT] output data buffer
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Arg

END MODULE PH_Out_Def
