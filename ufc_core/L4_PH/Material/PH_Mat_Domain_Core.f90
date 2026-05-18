!===============================================================================
! MODULE: PH_Mat_Domain_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Domain
! BRIEF:  Material domain container - slot pool, lifecycle, and IP-level access.
! **W1**：**槽池与四型真源** **`PH_Mat_Slot`/`PH_Mat_Desc`**；**Populate** 写入 **`desc%props`**、**`cfg%matId`** / **`cfg%matModel`**；
!         四型字段已全量嵌套至辅 TYPE（Depth 2 cap），DEPRECATED 平字段已清理。
! **USE 约定（2026-04-30）**：域外消费 **`PH_Mat_Slot` / `PH_MAT_*` / 四型** 时 **请 `USE PH_Mat_Def`**；本文件仅保留 **TYPE/例程定义真源**。
!===============================================================================
MODULE PH_Mat_Domain_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Aux_Def, ONLY: PH_Mat_Cfg_Init_Desc, PH_Mat_Pop_Vld_Desc, &
                             PH_Mat_Inc_Evo_Ctx, PH_Mat_Lcl_Comp_Ctx, &
                             PH_Mat_Lcl_Comp_State, PH_Mat_Lcl_Evo_State, &
                             PH_Mat_Stp_Ctl_Algo, PH_Mat_Lcl_Comp_ArgIn, &
                             PH_Mat_Lcl_Comp_ArgOut, PH_Mat_Slot_PhaseIdx
  USE PH_Mat_Enum, ONLY: PH_MAT_UNKNOWN

  IMPLICIT NONE
  PRIVATE

  !--- [PUBLIC TYPES] ---
  PUBLIC :: PH_Mat_Desc
  PUBLIC :: PH_Mat_Ctx
  PUBLIC :: PH_Mat_State
  PUBLIC :: PH_Mat_Algo
  PUBLIC :: PH_Mat_Slot
  PUBLIC :: PH_Mat_Domain
  PUBLIC :: PH_Mat_Init_Arg
  PUBLIC :: PH_Mat_GetCtx_Arg
  PUBLIC :: PH_Mat_GetState_Arg
  PUBLIC :: PH_Mat_SetCtx_Arg
  PUBLIC :: PH_Mat_SetState_Arg
  PUBLIC :: PH_Mat_Eval_Arg
  PUBLIC :: PH_Mat_Constitutive_Ifc

  !--- [AUXILIARY TYPE RE-EXPORTS] ---
  PUBLIC :: PH_Mat_Cfg_Init_Desc, PH_Mat_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Inc_Evo_Ctx, PH_Mat_Lcl_Comp_Ctx
  PUBLIC :: PH_Mat_Lcl_Comp_State, PH_Mat_Lcl_Evo_State
  PUBLIC :: PH_Mat_Stp_Ctl_Algo
  PUBLIC :: PH_Mat_Lcl_Comp_ArgIn, PH_Mat_Lcl_Comp_ArgOut
  PUBLIC :: PH_Mat_Slot_PhaseIdx

  !--- [PUBLIC PROCEDURES] ---
  PUBLIC :: PH_Mat_Domain_Init, PH_Mat_Domain_Finalize
  PUBLIC :: PH_Mat_Apply_Init_Arg
  PUBLIC :: PH_Mat_AllocSlot_Idx
  PUBLIC :: PH_Mat_GetCtx_Idx, PH_Mat_GetState_Idx
  PUBLIC :: PH_Mat_SetCtx_Idx, PH_Mat_SetState_Idx
  PUBLIC :: PH_Mat_State_DualWrite_Stress6
  PUBLIC :: PH_Mat_State_DualWrite_Ctan66
  PUBLIC :: PH_Mat_State_DualWrite_StateVars

  !=============================================================================
  ! TYPE: PH_Mat_Desc
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Desc
    TYPE(PH_Mat_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Pop_Vld_Desc)  :: pop
    REAL(wp), ALLOCATABLE :: props(:) ! [Phase:Pop|Verb:Brg]
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Desc

  !=============================================================================
  ! TYPE: PH_Mat_Ctx
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Ctx
    TYPE(PH_Mat_Inc_Evo_Ctx)  :: inc
    TYPE(PH_Mat_Lcl_Comp_Ctx) :: lcl
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Ctx

  !=============================================================================
  ! TYPE: PH_Mat_State
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_State
    TYPE(PH_Mat_Lcl_Comp_State) :: comp
    TYPE(PH_Mat_Lcl_Evo_State)  :: evo
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_State

  !=============================================================================
  ! TYPE: PH_Mat_Eval_Arg
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Eval_Arg
    TYPE(PH_Mat_Lcl_Comp_ArgIn)  :: inp
    TYPE(PH_Mat_Lcl_Comp_ArgOut) :: out
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Eval_Arg

  !=============================================================================
  ! ABSTRACT INTERFACE: PH_Mat_Constitutive_Ifc
  !=============================================================================
  ABSTRACT INTERFACE
    SUBROUTINE PH_Mat_Constitutive_Ifc(desc, state, arg, status)
      IMPORT :: PH_Mat_Desc, PH_Mat_State, PH_Mat_Eval_Arg, i4
      TYPE(PH_Mat_Desc),     INTENT(IN)    :: desc
      TYPE(PH_Mat_State),    INTENT(INOUT) :: state
      TYPE(PH_Mat_Eval_Arg), INTENT(INOUT) :: arg
      INTEGER(i4),           INTENT(OUT)   :: status
    END SUBROUTINE
  END INTERFACE

  !=============================================================================
  ! TYPE: PH_Mat_Algo
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Algo
    TYPE(PH_Mat_Stp_Ctl_Algo) :: stp
    PROCEDURE(PH_Mat_Constitutive_Ifc), POINTER, NOPASS :: constitutive => NULL()
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Mat_Algo

  !=============================================================================
  ! TYPE: PH_Mat_Slot
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Slot
    TYPE(PH_Mat_Desc)  :: desc
    TYPE(PH_Mat_Ctx)   :: ctx
    TYPE(PH_Mat_State)  :: state
    TYPE(PH_Mat_Algo)  :: algo
    TYPE(PH_Mat_Slot_PhaseIdx) :: phase   ! Phase tracking flags (semantic only)
    LOGICAL             :: active = .FALSE.
  END TYPE PH_Mat_Slot

  !=============================================================================
  ! TYPE: PH_Mat_Init_Arg
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Init_Arg
    INTEGER(i4)           :: stepId     = 0_i4
    INTEGER(i4)           :: mat_pt_idx = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_Init_Arg

  !=============================================================================
  ! TYPE: PH_Mat_GetCtx_Arg / PH_Mat_GetState_Arg (SIO-style bundles)
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_GetCtx_Arg
    TYPE(PH_Mat_Ctx)      :: ctx
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_GetCtx_Arg

  TYPE, PUBLIC :: PH_Mat_GetState_Arg
    TYPE(PH_Mat_State)    :: state
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_GetState_Arg

  TYPE, PUBLIC :: PH_Mat_SetCtx_Arg
    TYPE(PH_Mat_Ctx) :: ctx
  END TYPE PH_Mat_SetCtx_Arg

  TYPE, PUBLIC :: PH_Mat_SetState_Arg
    TYPE(PH_Mat_State) :: state
  END TYPE PH_Mat_SetState_Arg

  !=============================================================================
  ! TYPE: PH_Mat_Domain
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Domain
    TYPE(PH_Mat_Slot), ALLOCATABLE :: slot_pool(:)
    INTEGER(i4) :: pool_count = 0_i4
    INTEGER(i4) :: step_idx   = 0_i4
    INTEGER(i4) :: incr_idx   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => PH_Mat_Domain_Init
    PROCEDURE :: Finalize => PH_Mat_Domain_Finalize
  END TYPE PH_Mat_Domain

CONTAINS

  SUBROUTINE PH_Mat_Domain_Init(this, stepId, status)
    CLASS(PH_Mat_Domain), INTENT(INOUT) :: this
    INTEGER(i4),          INTENT(IN)    :: stepId
    TYPE(ErrorStatusType), INTENT(OUT)  :: status
    CALL init_error_status(status)
    IF (ALLOCATED(this%slot_pool)) CALL this%Finalize()
    ALLOCATE(this%slot_pool(1024)) ! PH_MAT_MAX_POOL
    this%pool_count  = 0_i4
    this%step_idx    = stepId
    this%incr_idx    = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Domain_Init

  SUBROUTINE PH_Mat_Domain_Finalize(this)
    CLASS(PH_Mat_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    IF (ALLOCATED(this%slot_pool)) THEN
      DO i = 1, SIZE(this%slot_pool)
        CALL PH_Mat_Clear_Slot(this%slot_pool(i))
      END DO
      DEALLOCATE(this%slot_pool)
    END IF
    this%pool_count  = 0_i4
    this%step_idx    = 0_i4
    this%incr_idx    = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE PH_Mat_Domain_Finalize

  SUBROUTINE PH_Mat_Clear_Slot(slot)
    TYPE(PH_Mat_Slot), INTENT(INOUT) :: slot
    IF (ALLOCATED(slot%desc%props)) DEALLOCATE(slot%desc%props)
    IF (ALLOCATED(slot%state%comp%C_tan)) DEALLOCATE(slot%state%comp%C_tan)
    IF (ALLOCATED(slot%state%comp%stress)) DEALLOCATE(slot%state%comp%stress)
    IF (ALLOCATED(slot%state%evo%stateVars)) DEALLOCATE(slot%state%evo%stateVars)
    IF (ALLOCATED(slot%state%evo%stateVars_n)) DEALLOCATE(slot%state%evo%stateVars_n)
    slot%desc = PH_Mat_Desc()
    slot%ctx  = PH_Mat_Ctx()
    slot%algo = PH_Mat_Algo()
    slot%phase = PH_Mat_Slot_PhaseIdx()
    slot%active = .FALSE.
  END SUBROUTINE PH_Mat_Clear_Slot

  SUBROUTINE PH_Mat_State_DualWrite_Stress6(st, s6)
    TYPE(PH_Mat_State), INTENT(INOUT) :: st
    REAL(wp), INTENT(IN) :: s6(6)
    IF (ALLOCATED(st%comp%stress)) THEN
      IF (SIZE(st%comp%stress) >= 6_i4) st%comp%stress(1:6) = s6(1:6)
    END IF
  END SUBROUTINE PH_Mat_State_DualWrite_Stress6

  SUBROUTINE PH_Mat_State_DualWrite_Ctan66(st, d66)
    TYPE(PH_Mat_State), INTENT(INOUT) :: st
    REAL(wp), INTENT(IN) :: d66(6, 6)
    IF (ALLOCATED(st%comp%C_tan)) THEN
      IF (SIZE(st%comp%C_tan, 1) >= 6_i4 .AND. SIZE(st%comp%C_tan, 2) >= 6_i4) &
        st%comp%C_tan(1:6, 1:6) = d66(1:6, 1:6)
    END IF
  END SUBROUTINE PH_Mat_State_DualWrite_Ctan66

  SUBROUTINE PH_Mat_State_DualWrite_StateVars(st, nsdv, sdv_pack)
    TYPE(PH_Mat_State), INTENT(INOUT) :: st
    INTEGER(i4), INTENT(IN) :: nsdv
    REAL(wp), INTENT(IN) :: sdv_pack(:)
    INTEGER(i4) :: m, npack
    IF (nsdv <= 0_i4) RETURN
    npack = INT(SIZE(sdv_pack), KIND=i4)
    IF (ALLOCATED(st%evo%stateVars)) THEN
      m = MIN(nsdv, npack, INT(SIZE(st%evo%stateVars), KIND=i4))
      IF (m > 0_i4) st%evo%stateVars(1:m) = sdv_pack(1:m)
    END IF
    IF (ALLOCATED(st%evo%stateVars_n)) THEN
      m = MIN(nsdv, npack, INT(SIZE(st%evo%stateVars_n), KIND=i4))
      IF (m > 0_i4) st%evo%stateVars_n(1:m) = sdv_pack(1:m)
    END IF
  END SUBROUTINE PH_Mat_State_DualWrite_StateVars

  SUBROUTINE PH_Mat_AllocSlot_Idx(dom, mat_pt_idx, status)
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: dom
    INTEGER(i4), INTENT(OUT) :: mat_pt_idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. dom%initialized .OR. .NOT. ALLOCATED(dom%slot_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Mat_AllocSlot_Idx: domain not initialized"
      RETURN
    END IF
    IF (dom%pool_count >= INT(SIZE(dom%slot_pool), KIND=i4)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Mat_AllocSlot_Idx: slot pool exhausted"
      RETURN
    END IF
    dom%pool_count = dom%pool_count + 1_i4
    mat_pt_idx = dom%pool_count
    CALL PH_Mat_Clear_Slot(dom%slot_pool(mat_pt_idx))
    dom%slot_pool(mat_pt_idx)%active = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_AllocSlot_Idx

  SUBROUTINE PH_Mat_Apply_Init_Arg(dom, arg)
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: dom
    TYPE(PH_Mat_Init_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: idx

    CALL init_error_status(arg%status)
    CALL PH_Mat_AllocSlot_Idx(dom, idx, arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN
    arg%mat_pt_idx = idx
    dom%slot_pool(idx)%ctx%inc%step_idx = arg%stepId
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Apply_Init_Arg

  SUBROUTINE PH_Mat_GetCtx_Idx(dom, mat_pt_idx, arg)
    TYPE(PH_Mat_Domain), INTENT(IN) :: dom
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    TYPE(PH_Mat_GetCtx_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. dom%initialized .OR. .NOT. ALLOCATED(dom%slot_pool)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Mat_GetCtx_Idx: domain not initialized"
      RETURN
    END IF
    IF (mat_pt_idx < 1_i4 .OR. mat_pt_idx > dom%pool_count) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Mat_GetCtx_Idx: mat_pt_idx out of range"
      RETURN
    END IF
    arg%ctx = dom%slot_pool(mat_pt_idx)%ctx
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_GetCtx_Idx

  SUBROUTINE PH_Mat_GetState_Idx(dom, mat_pt_idx, arg)
    TYPE(PH_Mat_Domain), INTENT(IN) :: dom
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    TYPE(PH_Mat_GetState_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. dom%initialized .OR. .NOT. ALLOCATED(dom%slot_pool)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Mat_GetState_Idx: domain not initialized"
      RETURN
    END IF
    IF (mat_pt_idx < 1_i4 .OR. mat_pt_idx > dom%pool_count) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Mat_GetState_Idx: mat_pt_idx out of range"
      RETURN
    END IF
    arg%state = dom%slot_pool(mat_pt_idx)%state
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_GetState_Idx

  SUBROUTINE PH_Mat_SetCtx_Idx(dom, mat_pt_idx, arg)
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: dom
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    TYPE(PH_Mat_SetCtx_Arg), INTENT(IN) :: arg

    IF (.NOT. dom%initialized .OR. .NOT. ALLOCATED(dom%slot_pool)) RETURN
    IF (mat_pt_idx < 1_i4 .OR. mat_pt_idx > dom%pool_count) RETURN
    dom%slot_pool(mat_pt_idx)%ctx = arg%ctx
  END SUBROUTINE PH_Mat_SetCtx_Idx

  SUBROUTINE PH_Mat_SetState_Idx(dom, mat_pt_idx, arg)
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: dom
    INTEGER(i4), INTENT(IN) :: mat_pt_idx
    TYPE(PH_Mat_SetState_Arg), INTENT(IN) :: arg

    IF (.NOT. dom%initialized .OR. .NOT. ALLOCATED(dom%slot_pool)) RETURN
    IF (mat_pt_idx < 1_i4 .OR. mat_pt_idx > dom%pool_count) RETURN
    dom%slot_pool(mat_pt_idx)%state = arg%state
  END SUBROUTINE PH_Mat_SetState_Idx

END MODULE PH_Mat_Domain_Core

