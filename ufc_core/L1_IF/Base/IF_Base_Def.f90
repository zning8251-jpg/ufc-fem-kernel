!===============================================================================
! MODULE: IF_Base_ModelDef
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Def — immutable descriptor + context + state + algo TYPEs
! BRIEF:  Four-type TYPE definitions for the Base domain.
!===============================================================================
MODULE IF_Base_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! IF_Base_Desc — immutable descriptor (set once at Init, read-only after)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Base_Desc
    INTEGER(i4)        :: ndim          = 3       ! spatial dimensions
    INTEGER(i4)        :: analysis_type = 0       ! 0=static, 1=dynamic, 2=thermal
    CHARACTER(LEN=128) :: version       = "UFC v1.0"
  END TYPE IF_Base_Desc

  !---------------------------------------------------------------------------
  ! IF_Base_Ctx — per-call context (populated before each operation)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Base_Call_Ctx
    INTEGER(i4) :: caller_layer = 0_i4   ! originating layer (1..6)
    INTEGER(i4) :: call_phase   = 0_i4   ! P0..P3 phase tag
  END TYPE IF_Base_Call_Ctx

  !---------------------------------------------------------------------------
  ! IF_Base_State — mutable runtime state (updated during analysis)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Base_State
    LOGICAL     :: initialized   = .FALSE.
    INTEGER(i4) :: current_step  = 0_i4
    INTEGER(i4) :: current_incr  = 0_i4
  END TYPE IF_Base_State

  !---------------------------------------------------------------------------
  ! IF_Base_Algo — algorithm configuration (read-only after setup)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Base_Algo
    INTEGER(i4) :: sym_capacity  = 256_i4  ! initial symbol-table capacity
    INTEGER(i4) :: n_threads     = 1_i4    ! requested thread count
  END TYPE IF_Base_Algo

  !---------------------------------------------------------------------------
  ! IF_SymEntry — single symbol table entry (name/id/kind)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_SymEntry
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4)       :: id   = 0_i4   ! registered integer id
    INTEGER(i4)       :: kind = 0_i4   ! IF_SYM_* enumeration
  END TYPE IF_SymEntry

  !---------------------------------------------------------------------------
  ! IF_DeviceCaps — device capability descriptor (set-once at Init)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_DeviceCaps
    INTEGER(i4) :: nCPUCores    = 1_i4
    INTEGER(i4) :: nGPUDevices  = 0_i4
    LOGICAL     :: gpuAvailable = .FALSE.
    LOGICAL     :: mpiAvailable = .FALSE.
    LOGICAL     :: ompAvailable = .FALSE.
  END TYPE IF_DeviceCaps

  !--------------------------------------------------------------------
  ! BaseCtx - Minimal context base for L4_PH/L6_AP
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: BaseCtx
    INTEGER(i4) :: ctx_id   = 0_i4
    INTEGER(i4) :: ctx_level = 0_i4   ! Layer level (1..6)
    LOGICAL     :: is_active = .FALSE.
    TYPE(ErrorStatusType) :: err_status
  CONTAINS
    PROCEDURE, PUBLIC :: Init     => BaseCtx_Init
    PROCEDURE, PUBLIC :: Cleanup  => BaseCtx_Cleanup
    PROCEDURE, PUBLIC :: ClearStatus => BaseCtx_ClearStatus
    PROCEDURE, PUBLIC :: SetStatus   => BaseCtx_SetStatus
    PROCEDURE, PUBLIC :: IsOK       => BaseCtx_IsOK
    PROCEDURE, PUBLIC :: IsError    => BaseCtx_IsError
  END TYPE BaseCtx

CONTAINS

  SUBROUTINE BaseCtx_Init(this, ctx_level)
    CLASS(BaseCtx), INTENT(INOUT) :: this
    INTEGER(i4),    INTENT(IN), OPTIONAL :: ctx_level

    CALL init_error_status(this%err_status)
    this%ctx_id    = 0_i4
    this%ctx_level = 0_i4
    this%is_active = .TRUE.
    IF (PRESENT(ctx_level)) this%ctx_level = ctx_level
  END SUBROUTINE BaseCtx_Init

  SUBROUTINE BaseCtx_Cleanup(this)
    CLASS(BaseCtx), INTENT(INOUT) :: this

    this%ctx_id    = 0_i4
    this%ctx_level = 0_i4
    this%is_active = .FALSE.
    CALL init_error_status(this%err_status)
  END SUBROUTINE BaseCtx_Cleanup

  SUBROUTINE BaseCtx_ClearStatus(this)
    CLASS(BaseCtx), INTENT(INOUT) :: this
    CALL init_error_status(this%err_status)
  END SUBROUTINE BaseCtx_ClearStatus

  SUBROUTINE BaseCtx_SetStatus(this, status)
    CLASS(BaseCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(IN) :: status
    this%err_status = status
  END SUBROUTINE BaseCtx_SetStatus

  FUNCTION BaseCtx_IsOK(this) RESULT(ok)
    CLASS(BaseCtx), INTENT(IN) :: this
    LOGICAL :: ok
    ok = (this%err_status%status_code == IF_STATUS_OK)
  END FUNCTION BaseCtx_IsOK

  FUNCTION BaseCtx_IsError(this) RESULT(is_err)
    CLASS(BaseCtx), INTENT(IN) :: this
    LOGICAL :: is_err
    is_err = (this%err_status%status_code /= IF_STATUS_OK)
  END FUNCTION BaseCtx_IsError

END MODULE IF_Base_Def
