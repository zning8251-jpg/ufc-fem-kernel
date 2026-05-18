!===============================================================================
! Module: MD_Output_Types                                        [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Output — Field/history output request descriptors
!
! Purpose:
!   Defines Desc types for the Output domain at the MD layer.
!   Output requests are declared in the INP file and are immutable after
!   model-data loading.  Actual result data lives in L5_RT output buffers.
!
! Type catalogue (4 TYPEs):
!   MD_FieldOut_Desc   – Field output request (*OUTPUT,FIELD)
!   MD_HistOut_Desc    – History output request (*OUTPUT,HISTORY)
!   MD_FieldOut_Var    – Single field output variable identifier
!   MD_Output_Registry – Container of all output requests for one step
!
! Output frequency constants (OUTFREQ_XXX):
!   OUTFREQ_ALL       = 0   Every increment
!   OUTFREQ_LAST      = 1   Last increment only
!   OUTFREQ_INTERVAL  = 2   Every n-th increment
!   OUTFREQ_TIME      = 3   At specified time values
!
! Layer dependency:
!   USE IF_Prec     (wp, i4)
!===============================================================================
MODULE MD_Output_Types
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_FieldOut_Desc
  PUBLIC :: MD_HistOut_Desc
  PUBLIC :: MD_FieldOut_Var
  PUBLIC :: MD_Output_Registry

  !-- Output frequency policy
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTFREQ_ALL      = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTFREQ_LAST     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTFREQ_INTERVAL = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTFREQ_TIME     = 3_i4  ! migrated

  !-- Output position constants (Abaqus result positions)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTPOS_INTEGRATION_PTS = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTPOS_NODES           = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTPOS_CENTROID        = 3_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTPUT_OUTPOS_ELEMENT_NODAL   = 4_i4  ! migrated

  !-- Max number of variables in one request
  INTEGER(i4), PARAMETER :: MD_OUTPUT_MAX_OUT_VARS = 64_i4  ! migrated

  !-----------------------------------------------------------------------------
  ! MD_FieldOut_Var — Identifies a single output variable
  !   e.g. 'S' (stress), 'U' (displacement), 'SDV1' (state-dependent variable)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_FieldOut_Var
    CHARACTER(LEN=32) :: var_name  = ''     ! Abaqus variable key (e.g. 'S','U')
    INTEGER(i4)       :: var_index = 0      ! Sub-component index (0 = all)
    INTEGER(i4)       :: position  = OUTPOS_INTEGRATION_PTS  ! Result position
  END TYPE MD_FieldOut_Var

  !-----------------------------------------------------------------------------
  ! MD_FieldOut_Desc — Field output request (*OUTPUT,FIELD)
  !   Corresponds to one *ELEMENT OUTPUT / *NODE OUTPUT block.
  !   Applies to an element/node set and controls write frequency.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_FieldOut_Desc
    !-- Identification
    INTEGER(i4)       :: request_id  = 0    ! Sequential request index
    CHARACTER(LEN=64) :: request_name = ''  ! Optional label

    !-- Target set (empty = whole model)
    CHARACTER(LEN=64) :: elem_set_name = ''
    CHARACTER(LEN=64) :: node_set_name = ''

    !-- Write frequency
    INTEGER(i4) :: freq_policy  = OUTFREQ_ALL   ! OUTFREQ_XXX
    INTEGER(i4) :: freq_interval = 1_i4          ! Used when OUTFREQ_INTERVAL

    !-- Variable list
    TYPE(MD_FieldOut_Var) :: vars(MAX_OUT_VARS)
    INTEGER(i4)           :: nvars = 0

    !-- Save for restart
    LOGICAL :: save_for_restart = .FALSE.

    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_FieldOut_Desc

  !-----------------------------------------------------------------------------
  ! MD_HistOut_Desc — History output request (*OUTPUT,HISTORY)
  !   Corresponds to one *NODE OUTPUT / *ENERGY OUTPUT block with
  !   continuous-time write-out.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_HistOut_Desc
    !-- Identification
    INTEGER(i4)       :: request_id   = 0
    CHARACTER(LEN=64) :: request_name = ''

    !-- Target (node set, element set, or specific node/element ID)
    CHARACTER(LEN=64) :: set_name = ''
    INTEGER(i4)       :: target_id = 0   ! Specific node/elem ID (0 = set-wide)

    !-- Write frequency (time-based for history)
    INTEGER(i4) :: freq_policy   = OUTFREQ_INTERVAL
    INTEGER(i4) :: freq_interval = 1_i4

    !-- Variable list
    TYPE(MD_FieldOut_Var) :: vars(MAX_OUT_VARS)
    INTEGER(i4)           :: nvars = 0

    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_HistOut_Desc

  !-----------------------------------------------------------------------------
  ! MD_Output_Registry — All output requests for the analysis / one step
  !   L5_RT output domain queries this at write-time to decide what to emit.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_Registry
    TYPE(MD_FieldOut_Desc), POINTER :: field_reqs(:)
    INTEGER(i4) :: n_field = 0

    TYPE(MD_HistOut_Desc), POINTER :: hist_reqs(:)
    INTEGER(i4) :: n_hist = 0

    !-- Owning step reference
    INTEGER(i4) :: step_id = 0

  CONTAINS
    PROCEDURE :: Init         => OutReg_Init
    PROCEDURE :: AddField     => OutReg_AddField
    PROCEDURE :: AddHist      => OutReg_AddHist
    PROCEDURE :: Clear        => OutReg_Clear
  END TYPE MD_Output_Registry

CONTAINS

  SUBROUTINE OutReg_Init(self, step_id)
    CLASS(MD_Output_Registry), INTENT(INOUT) :: self
    INTEGER(i4),               INTENT(IN)    :: step_id

    self%step_id = step_id
    ALLOCATE(self%field_reqs(16))
    ALLOCATE(self%hist_reqs(16))
    self%n_field = 0
    self%n_hist  = 0
  END SUBROUTINE OutReg_Init

  SUBROUTINE OutReg_AddField(self, req)
    CLASS(MD_Output_Registry), INTENT(INOUT) :: self
    TYPE(MD_FieldOut_Desc),    INTENT(IN)    :: req

    self%n_field = self%n_field + 1
    self%field_reqs(self%n_field) = req
  END SUBROUTINE OutReg_AddField

  SUBROUTINE OutReg_AddHist(self, req)
    CLASS(MD_Output_Registry), INTENT(INOUT) :: self
    TYPE(MD_HistOut_Desc),     INTENT(IN)    :: req

    self%n_hist = self%n_hist + 1
    self%hist_reqs(self%n_hist) = req
  END SUBROUTINE OutReg_AddHist

  SUBROUTINE OutReg_Clear(self)
    CLASS(MD_Output_Registry), INTENT(INOUT) :: self
    IF (ALLOCATED(self%field_reqs)) DEALLOCATE(self%field_reqs)
    IF (ALLOCATED(self%hist_reqs))  DEALLOCATE(self%hist_reqs)
    self%n_field = 0
    self%n_hist  = 0
  END SUBROUTINE OutReg_Clear

END MODULE MD_Output_Types


!===============================================================================
! MODULE MD_Output_Domain_Types                                  [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Output — Flat-storage independent domain container
!
! PURPOSE: Four-type domain container for Output request domain.
!   MD_Out_Desc   — output request config (write-once after parse)
!   MD_Out_State  — runtime output state (last written increment, etc.)
!   MD_Out_Algo   — output frequency/filter parameters (read-only during solve)
!   MD_Out_Ctx    — hot-path context (no ALLOCATABLE)
!===============================================================================
MODULE MD_Output_Domain_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Out_Desc
  PUBLIC :: MD_Out_State
  PUBLIC :: MD_Out_Algo
  PUBLIC :: MD_Out_Ctx
  PUBLIC :: MD_Output_Domain
  PUBLIC :: MD_Output_Domain_Init
  PUBLIC :: MD_Output_Domain_Finalize
  PUBLIC :: MD_Output_WriteBack

  !-- Output type constants --
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUT_TYPE_FIELD   = 1_i4  ! *OUTPUT, FIELD
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUT_TYPE_HISTORY = 2_i4  ! *OUTPUT, HISTORY

  !-- Output frequency constants --
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTFREQ_ALL      = 0_i4  ! Every increment
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTFREQ_LAST     = 1_i4  ! Last increment only
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTFREQ_INTERVAL = 2_i4  ! Every n-th increment
  INTEGER(i4), PARAMETER, PUBLIC :: MD_OUTFREQ_TIME     = 3_i4  ! At specified times

  !=============================================================================
  ! Desc — Output request configuration (write-once after parse)
  !=============================================================================
  TYPE, PUBLIC :: MD_Out_Desc
    CHARACTER(LEN=80) :: request_name  = ''              ! Request name
    INTEGER(i4)       :: request_id    = 0_i4            ! 1-based index
    INTEGER(i4)       :: out_type      = MD_OUT_TYPE_FIELD  ! Field or history
    INTEGER(i4)       :: step_ref      = 0_i4            ! Step this request belongs to
    CHARACTER(LEN=80) :: target_set    = ''              ! Node/element set name
    INTEGER(i4)       :: freq_mode     = MD_OUTFREQ_ALL  ! Output frequency mode
    INTEGER(i4)       :: freq_interval = 1_i4            ! Interval (for INTERVAL mode)
    REAL(wp)          :: freq_time     = 0.0_wp          ! Time interval (for TIME mode)
    !-- Variable list (write-once; variable names from *OUTPUT, *NODE OUTPUT, etc.) --
    INTEGER(i4)              :: n_vars       = 0_i4      ! Number of requested variables
    CHARACTER(LEN=16), ALLOCATABLE :: var_names(:)       ! Variable identifiers (U,S,E,...)
  END TYPE MD_Out_Desc

  !=============================================================================
  ! State — Runtime output state (WriteBack whitelist gated)
  !=============================================================================
  TYPE, PUBLIC :: MD_Out_State
    INTEGER(i4) :: last_written_inc   = 0_i4    ! Last increment written
    REAL(wp)    :: last_written_time  = 0.0_wp  ! Last time point written
    INTEGER(i4) :: total_written      = 0_i4    ! Total frames/points written
    LOGICAL     :: is_active          = .FALSE. ! Active in current step
  END TYPE MD_Out_State

  !=============================================================================
  ! Algo — Output filter parameters (read-only during solve)
  !=============================================================================
  TYPE, PUBLIC :: MD_Out_Algo
    LOGICAL     :: write_on_cutback   = .FALSE. ! Write on cutback increments
    LOGICAL     :: write_last_inc     = .TRUE.  ! Always write last increment
    INTEGER(i4) :: buffer_size        = 0_i4    ! Output buffer size (0 = default)
  END TYPE MD_Out_Algo

  !=============================================================================
  ! Ctx — Hot-path context (NO ALLOCATABLE)
  !=============================================================================
  TYPE, PUBLIC :: MD_Out_Ctx
    INTEGER(i4) :: request_idx        = 0_i4    ! Active request index in domain array
    INTEGER(i4) :: step_idx           = 0_i4    ! Step index from L5_RT
    INTEGER(i4) :: incr_idx           = 0_i4    ! Increment index from L5_RT
    LOGICAL     :: is_last_increment  = .FALSE. ! Last increment flag
  END TYPE MD_Out_Ctx

  !=============================================================================
  ! MD_Output_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Output_Domain
    TYPE(MD_Out_Desc),  ALLOCATABLE :: desc(:)
    TYPE(MD_Out_State), ALLOCATABLE :: state(:)
    TYPE(MD_Out_Algo),  ALLOCATABLE :: algo(:)
    INTEGER(i4) :: n_requests   = 0_i4
    INTEGER(i4) :: max_requests = 0_i4
    LOGICAL     :: initialized  = .FALSE.
    LOGICAL     :: frozen       = .FALSE.
  CONTAINS
    PROCEDURE :: Init      => MD_Output_Domain_Init
    PROCEDURE :: Finalize  => MD_Output_Domain_Finalize
    PROCEDURE :: WriteBack => MD_Output_WriteBack
  END TYPE MD_Output_Domain

CONTAINS

  SUBROUTINE MD_Output_Domain_Init(this, cap_requests, status)
    CLASS(MD_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: cap_requests
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Output_Domain_Finalize(this)
    ALLOCATE(this%desc(cap_requests))
    ALLOCATE(this%state(cap_requests))
    ALLOCATE(this%algo(cap_requests))
    this%n_requests   = 0_i4
    this%max_requests = cap_requests
    this%initialized  = .TRUE.
    this%frozen       = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Output_Domain_Init

  SUBROUTINE MD_Output_Domain_Finalize(this)
    CLASS(MD_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%desc)) THEN
      DO i = 1, this%n_requests
        IF (ALLOCATED(this%desc(i)%var_names)) DEALLOCATE(this%desc(i)%var_names)
      END DO
      DEALLOCATE(this%desc)
    END IF
    IF (ALLOCATED(this%state)) DEALLOCATE(this%state)
    IF (ALLOCATED(this%algo))  DEALLOCATE(this%algo)
    this%n_requests   = 0_i4
    this%max_requests = 0_i4
    this%initialized  = .FALSE.
    this%frozen       = .FALSE.
  END SUBROUTINE MD_Output_Domain_Finalize

  SUBROUTINE MD_Output_WriteBack(this, request_id, new_state, status)
    CLASS(MD_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: request_id
    TYPE(MD_Out_State),      INTENT(IN)    :: new_state
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. request_id < 1_i4 .OR. &
        request_id > this%n_requests) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Output_WriteBack: invalid request_id=', request_id
      RETURN
    END IF
    this%state(request_id) = new_state
    status%status_code     = IF_STATUS_OK
  END SUBROUTINE MD_Output_WriteBack

END MODULE MD_Output_Domain_Types
