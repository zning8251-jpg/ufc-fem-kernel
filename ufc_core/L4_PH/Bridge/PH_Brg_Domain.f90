!===============================================================================
! MODULE: PH_Brg_Domain
! LAYER:  L4_PH
! DOMAIN: Bridge
! ROLE:   Domain
! BRIEF:  L4 cross-layer bridge domain (Init/Finalize/RegisterLib/GetSummary)
!
! Four-Type: PH_Brg_Ctx, PH_Brg_State, PH_Brg_Params (Algo)
! Constants: PH_BRG_UEL/UMAT/VUMAT/GPU/EXTERNAL, PH_BRG_MAX_LIBS
! Contract: Bridge/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Bridge | Role:Domain_Core | FuncSet?Init+Reg | Hot:No
!>>> Basis: UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md 附录 ph_layer%bridge 最晚Init/最早Finalize
!>>> UFC_PH_CONTRACT | Bridge/CONTRACT.md

MODULE PH_Brg_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_BRG_UEL       = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BRG_UMAT      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BRG_VUMAT     = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BRG_GPU       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BRG_EXTERNAL  = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BRG_MAX_LIBS  = 32_i4

  !---------------------------------------------------------------------------
  ! TYPE: PH_Brg_Inc_Evo_Ctx
  ! PHASE: Increment | VERB: Evolve
  ! KIND:  Ctx (auxiliary)
  ! DESC:  Increment-phase evolution context - step/increment tracking
  !        for Bridge evolution. Mirrors PH_Mat_Inc_Evo_Ctx pattern.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Brg_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Brg_Inc_Evo_Ctx

  TYPE, PUBLIC :: PH_Brg_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Brg_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: step_idx          = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4) :: incr_idx          = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4) :: nRegisteredLibs   = 0_i4
    INTEGER(i4) :: libTypes(PH_BRG_MAX_LIBS) = 0_i4
    LOGICAL     :: libActive(PH_BRG_MAX_LIBS) = .FALSE.
    INTEGER(i4) :: nUEL   = 0_i4
    INTEGER(i4) :: nUMAT  = 0_i4
  END TYPE PH_Brg_Ctx

  TYPE, PUBLIC :: PH_Brg_State
    INTEGER(i4) :: totalCalls      = 0_i4
    INTEGER(i4) :: failedCalls     = 0_i4
    INTEGER(i4) :: lastErrorCode   = 0_i4
    REAL(wp)    :: totalBridgeTime = 0.0_wp
    REAL(wp)    :: gpuTransferTime = 0.0_wp
  END TYPE PH_Brg_State

  TYPE, PUBLIC :: PH_Brg_Params
    LOGICAL     :: enableUEL       = .FALSE.
    LOGICAL     :: enableUMAT      = .FALSE.
    LOGICAL     :: enableGPU       = .FALSE.
    LOGICAL     :: enableExternal  = .FALSE.
    INTEGER(i4) :: gpuDeviceId     = 0_i4
    LOGICAL     :: gpuAsyncTransfer = .FALSE.
  END TYPE PH_Brg_Params

  TYPE, PUBLIC :: PH_Brg_RegisterLib_Arg
    INTEGER(i4)       :: libType = PH_BRG_UEL
    CHARACTER(LEN=256) :: libPath = ""
    INTEGER(i4)       :: libId   = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Brg_RegisterLib_Arg

  TYPE, PUBLIC :: PH_Brg_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Brg_GetSummary_Arg

  TYPE, PUBLIC :: PH_Brg_Domain
    TYPE(PH_Brg_Ctx)    :: ctx
    TYPE(PH_Brg_State)  :: state
    TYPE(PH_Brg_Params) :: params
    LOGICAL                :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterLib
    PROCEDURE :: GetSummary
  END TYPE PH_Brg_Domain

CONTAINS

  SUBROUTINE Finalize(this)
    CLASS(PH_Brg_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%ctx%inc%step_idx = 0_i4
    this%ctx%inc%incr_idx = 0_i4
    this%ctx%inc%step_idx = 0_i4
    this%ctx%inc%incr_idx = 0_i4
    this%ctx%nRegisteredLibs = 0_i4
    this%ctx%libTypes(:)     = 0_i4
    this%ctx%libActive(:)    = .FALSE.
    this%ctx%nUEL  = 0_i4
    this%ctx%nUMAT = 0_i4
    this%state = PH_Brg_State()
    this%params = PH_Brg_Params()
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE Init(this, stepId, status, incr_idx)
    CLASS(PH_Brg_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: stepId   ! step_idx (md_layer%step )
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4),             INTENT(IN), OPTIONAL :: incr_idx
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctx   = PH_Brg_Ctx()
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%ctx%inc%step_idx = stepId
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    this%params = PH_Brg_Params()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  SUBROUTINE RegisterLib(this, arg)
    CLASS(PH_Brg_Domain),        INTENT(INOUT) :: this
    TYPE(PH_Brg_RegisterLib_Arg), INTENT(INOUT) :: arg
    CALL PH_Brg_RegisterLib_Impl(this, arg%libType, arg%libPath, &
                                    arg%libId, arg%status)
  END SUBROUTINE RegisterLib

  SUBROUTINE PH_Brg_RegisterLib_Impl(this, libType, libPath, libId, status)
    CLASS(PH_Brg_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: libType
    CHARACTER(LEN=*),        INTENT(IN)    :: libPath
    INTEGER(i4),             INTENT(OUT)   :: libId
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      libId = 0_i4
      RETURN
    END IF
    IF (this%ctx%nRegisteredLibs >= PH_BRG_MAX_LIBS) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A)') "Maximum library capacity exceeded (", &
            PH_BRG_MAX_LIBS, ")"
      libId = 0_i4
      RETURN
    END IF
    IF (libType < PH_BRG_UEL .OR. libType > PH_BRG_EXTERNAL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid library type"
      libId = 0_i4
      RETURN
    END IF
    this%ctx%nRegisteredLibs = this%ctx%nRegisteredLibs + 1_i4
    libId = this%ctx%nRegisteredLibs
    this%ctx%libTypes(libId)  = libType
    this%ctx%libActive(libId) = .TRUE.
    SELECT CASE(libType)
    CASE(PH_BRG_UEL)
      this%ctx%nUEL  = this%ctx%nUEL  + 1_i4
    CASE(PH_BRG_UMAT, PH_BRG_VUMAT)
      this%ctx%nUMAT = this%ctx%nUMAT + 1_i4
    END SELECT
    ! libPath: reserved for future dynamic load; not persisted in ctx yet.
    this%state%totalCalls = this%state%totalCalls + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Brg_RegisterLib_Impl

  SUBROUTINE GetSummary(this, arg)
    CLASS(PH_Brg_Domain),      INTENT(IN)    :: this
    TYPE(PH_Brg_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL PH_Brg_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  SUBROUTINE PH_Brg_GetSummary_Impl(this, summary, status)
    CLASS(PH_Brg_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      RETURN
    END IF
    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,I0,A,ES10.3,A,ES10.3)') &
      "Bridge Summary: Libs=", this%ctx%nRegisteredLibs, &
      ", UEL=", this%ctx%nUEL, &
      ", UMAT=", this%ctx%nUMAT, &
      ", Calls=", this%state%totalCalls, &
      ", Failed=", this%state%failedCalls, &
      ", LastErr=", this%state%lastErrorCode, &
      ", Time=", this%state%totalBridgeTime, &
      ", GPU=", this%state%gpuTransferTime
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Brg_GetSummary_Impl

END MODULE PH_Brg_Domain