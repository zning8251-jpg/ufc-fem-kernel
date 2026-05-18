!===============================================================================
! MODULE: PH_WB_Def
! LAYER:  L4_PH
! DOMAIN: WriteBack
! ROLE:   Def — L4 WriteBack TYPE definitions
! BRIEF:  L4 WriteBack types for format preparation of physics results.
!
! DESIGN NOTE (P6 半贯通柱): L4 WriteBack only does format preparation.
!   - WB-01: L5→L3 is the ONLY legal L3 step-state mutation path
!   - WB-02: L4 must NOT write L3 directly
!   - L4 scope: physics→write-back format conversion, buffer preparation
!   - L4 scope exclusion: file I/O, state persistence, checkpoint management (L5)
!===============================================================================
MODULE PH_WB_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  ! Public types
  PUBLIC :: PH_WB_Desc
  PUBLIC :: PH_WB_State
  PUBLIC :: PH_WB_Algo
  PUBLIC :: PH_WB_Ctx
  PUBLIC :: PH_WB_Arg

  ! ==========================================================================
  ! TYPE: PH_WB_Desc
  ! KIND: Desc
  ! BRIEF: WriteBack immutable configuration — what fields to write back
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WB_Desc
    LOGICAL :: write_disp   = .TRUE.    ! Write displacement
    LOGICAL :: write_vel    = .FALSE.   ! Write velocity
    LOGICAL :: write_accel  = .FALSE.   ! Write acceleration
    LOGICAL :: write_stress = .TRUE.    ! Write stress
    LOGICAL :: write_strain = .TRUE.    ! Write strain
    INTEGER(i4) :: output_freq = 1_i4   ! Every N increments
  CONTAINS
    PROCEDURE :: Init     => PH_WB_Desc_Init
    PROCEDURE :: Validate => PH_WB_Desc_Validate
  END TYPE PH_WB_Desc

  ! ==========================================================================
  ! TYPE: PH_WB_State
  ! KIND: State
  ! BRIEF: WriteBack runtime state — buffer positions, written counts
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WB_State
    INTEGER(i4) :: total_nodes_written = 0_i4
    INTEGER(i4) :: total_elems_written = 0_i4
    REAL(wp), ALLOCATABLE :: disp_buffer(:,:)
    REAL(wp), ALLOCATABLE :: stress_buffer(:,:)
    REAL(wp), ALLOCATABLE :: strain_buffer(:,:)
    TYPE(ErrorStatusType) :: status
  CONTAINS
    PROCEDURE :: Init     => PH_WB_State_Init
    PROCEDURE :: Finalize => PH_WB_State_Finalize
    PROCEDURE :: Reset    => PH_WB_State_Reset
  END TYPE PH_WB_State

  ! ==========================================================================
  ! TYPE: PH_WB_Algo
  ! KIND: Algo
  ! BRIEF: WriteBack algorithm control — format strategy, validation
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WB_Algo
    INTEGER(i4) :: format_id        = 1_i4  ! 1=binary, 2=HDF5, 3=ASCII
    LOGICAL     :: validate_checksum = .TRUE.
    LOGICAL     :: compress_buffer   = .FALSE.
    REAL(wp)    :: compression_tol   = 1.0e-12_wp
  END TYPE PH_WB_Algo

  ! ==========================================================================
  ! TYPE: PH_WB_Ctx
  ! KIND: Ctx
  ! BRIEF: WriteBack context — current step/inc + pointer state
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WB_Ctx
    INTEGER(i4) :: current_step_id  = 0_i4
    INTEGER(i4) :: current_inc_id   = 0_i4
    INTEGER(i4) :: buffer_head      = 1_i4
    INTEGER(i4) :: buffer_tail      = 0_i4
    LOGICAL     :: buffer_full      = .FALSE.
  END TYPE PH_WB_Ctx

  ! ==========================================================================
  ! TYPE: PH_WB_Arg
  ! BRIEF: Structured I/O bundle for WriteBack operations
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WB_Arg
    TYPE(PH_WB_Desc)  :: desc     ! [IN]  config
    TYPE(PH_WB_State) :: state    ! [INOUT] state
    TYPE(PH_WB_Algo)  :: algo     ! [IN]  algo
    TYPE(PH_WB_Ctx)   :: ctx      ! [IN]  context
    INTEGER(i4)        :: n_values = 0_i4
    REAL(wp), ALLOCATABLE :: buffer(:)  ! [OUT] formatted buffer
    TYPE(ErrorStatusType) :: status
  END TYPE PH_WB_Arg

CONTAINS

  SUBROUTINE PH_WB_Desc_Init(this)
    CLASS(PH_WB_Desc), INTENT(INOUT) :: this
    this%write_disp   = .TRUE.
    this%write_vel    = .FALSE.
    this%write_accel  = .FALSE.
    this%write_stress = .TRUE.
    this%write_strain = .TRUE.
    this%output_freq  = 1_i4
  END SUBROUTINE PH_WB_Desc_Init

  SUBROUTINE PH_WB_Desc_Validate(this, status)
    CLASS(PH_WB_Desc), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (this%output_freq < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WB_Desc: output_freq must be >= 1'
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_WB_Desc_Validate

  SUBROUTINE PH_WB_State_Init(this, n_nodes, n_elems)
    CLASS(PH_WB_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_nodes, n_elems
    CALL init_error_status(this%status)
    this%total_nodes_written = 0_i4
    this%total_elems_written = 0_i4
    IF (ALLOCATED(this%disp_buffer))   DEALLOCATE(this%disp_buffer)
    IF (ALLOCATED(this%stress_buffer)) DEALLOCATE(this%stress_buffer)
    IF (ALLOCATED(this%strain_buffer)) DEALLOCATE(this%strain_buffer)
    IF (n_nodes > 0_i4) THEN
      ALLOCATE(this%disp_buffer(3, n_nodes), STAT=this%status%status_code)
      this%disp_buffer = 0.0_wp
    END IF
    IF (n_elems > 0_i4) THEN
      ALLOCATE(this%stress_buffer(6, n_elems), STAT=this%status%status_code)
      ALLOCATE(this%strain_buffer(6, n_elems), STAT=this%status%status_code)
      this%stress_buffer = 0.0_wp
      this%strain_buffer = 0.0_wp
    END IF
  END SUBROUTINE PH_WB_State_Init

  SUBROUTINE PH_WB_State_Finalize(this)
    CLASS(PH_WB_State), INTENT(INOUT) :: this
    IF (ALLOCATED(this%disp_buffer))   DEALLOCATE(this%disp_buffer)
    IF (ALLOCATED(this%stress_buffer)) DEALLOCATE(this%stress_buffer)
    IF (ALLOCATED(this%strain_buffer)) DEALLOCATE(this%strain_buffer)
  END SUBROUTINE PH_WB_State_Finalize

  SUBROUTINE PH_WB_State_Reset(this)
    CLASS(PH_WB_State), INTENT(INOUT) :: this
    this%total_nodes_written = 0_i4
    this%total_elems_written = 0_i4
    IF (ALLOCATED(this%disp_buffer))   this%disp_buffer = 0.0_wp
    IF (ALLOCATED(this%stress_buffer)) this%stress_buffer = 0.0_wp
    IF (ALLOCATED(this%strain_buffer)) this%strain_buffer = 0.0_wp
  END SUBROUTINE PH_WB_State_Reset

END MODULE PH_WB_Def
