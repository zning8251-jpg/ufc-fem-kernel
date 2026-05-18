!===============================================================================
! MODULE: MD_WB_Brg
! LAYER:  L3_MD
! DOMAIN: WriteBack
! ROLE:   Brg — Container-aware WriteBack dispatcher
! BRIEF:  Whitelist-gated routing of L5_RT write-backs to L3 domain methods.
!===============================================================================
!
! Procedures:
!   [P0] Init_WriteBack_API / Finalize_WriteBack_API
!   [P1] MD_WB_SetContainer
!   [P3] MD_WB_Step / MD_WB_Amplitude / MD_WB_LoadBC / MD_WB_Mesh /
!        MD_WB_Mesh_NodePos / MD_WB_Mesh_NodeDisp / MD_WB_Mesh_NodeVel /
!        MD_WB_Mesh_NodeAcc / MD_WB_Mesh_ElemStress /
!        MD_WB_Model / MD_WB_Interaction / MD_WB_Output
!
! Data chain: g_l3 (module SAVE pointer) set by MD_WB_SetContainer.
! Contract (L3 Sec 7.2): L3 write-back only via g_l3%desc%*%WriteBack*
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:WB | Role:API | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | WriteBack/CONTRACT.md

MODULE MD_WB_Brg
  USE IF_Prec_Core,    ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Log_Logger, ONLY: IF_Log_Info, IF_Log_Warning, IF_Log_Debug
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE UFC_GlobalContainer_Core,  ONLY: g_ufc_global
  USE MD_WB_Mgr,         ONLY: Is_WriteBack_Allowed, &
                                        Init_WriteBack_WhiteList, &
                                        Finalize_WriteBack_WhiteList
  USE MD_Mesh_API,             ONLY: MD_Mesh_WriteBack_ElemStress_Arg, MD_Mesh_WriteBack_ElemStress_Idx
  IMPLICIT NONE
  PRIVATE

  !--- Module-level container pointer (TARGET must be set by caller) ---
  TYPE(MD_L3_LayerContainer), POINTER, SAVE :: g_l3 => NULL()
  LOGICAL,                             SAVE :: g_api_initialized = .FALSE.

  !--- WriteBack denial error code (L3_MD local) ---
  INTEGER(i4), PARAMETER, PUBLIC :: STATUS_WRITEBACK_DENIED = 11_i4

  !--- Statistics ---
  INTEGER(i4), SAVE :: g_total_writebacks = 0_i4
  INTEGER(i4), SAVE :: g_denied_writebacks = 0_i4

  PUBLIC :: Init_WriteBack_API
  PUBLIC :: Finalize_WriteBack_API
  PUBLIC :: MD_WB_SetContainer
  PUBLIC :: MD_WB_Step
  PUBLIC :: MD_WB_Amplitude
  PUBLIC :: MD_WB_LoadBC
  PUBLIC :: MD_WB_Mesh
  PUBLIC :: MD_WB_Mesh_NodePos
  PUBLIC :: MD_WB_Mesh_NodeDisp
  PUBLIC :: MD_WB_Mesh_NodeVel
  PUBLIC :: MD_WB_Mesh_NodeAcc
  PUBLIC :: MD_WB_Mesh_ElemStress
  PUBLIC :: MD_WB_Model
  PUBLIC :: MD_WB_Interaction
  PUBLIC :: MD_WB_Output

CONTAINS

  !====================================================================
  ! Init_WriteBack_API ??initialise whitelist + reset stats
  !====================================================================
  SUBROUTINE Init_WriteBack_API(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ! If container's writeback already initialized (MD_L3_Init), skip Mgr global
    IF (.NOT. (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%desc%writeback%initialized)) THEN
      CALL Init_WriteBack_WhiteList(status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    g_total_writebacks = 0_i4
    g_denied_writebacks = 0_i4
    g_api_initialized   = .TRUE.
    CALL IF_Log_Info("MD_WB_Brg: initialized")

  END SUBROUTINE Init_WriteBack_API

  !====================================================================
  ! Finalize_WriteBack_API ??report stats + release whitelist
  !====================================================================
  SUBROUTINE Finalize_WriteBack_API()
    CHARACTER(LEN=64) :: buf

    WRITE(buf,'(A,I0,A,I0)') "WriteBack total=", g_total_writebacks, &
                               "  denied=", g_denied_writebacks
    CALL IF_Log_Info(TRIM(buf))
    CALL Finalize_WriteBack_WhiteList()
    g_l3              => NULL()
    g_api_initialized = .FALSE.

  END SUBROUTINE Finalize_WriteBack_API

  !====================================================================
  ! MD_WB_SetContainer ??bind module pointer to the L3 layer container
  !
  ! Must be called once (typically in L5_RT global init) before any
  ! MD_WB_* facade is used.  Container must have TARGET attribute.
  !====================================================================
  SUBROUTINE MD_WB_SetContainer(container, status)
    TYPE(MD_L3_LayerContainer), TARGET, INTENT(INOUT) :: container
    TYPE(ErrorStatusType),              INTENT(OUT)   :: status

    CALL init_error_status(status)
    g_l3 => container
    IF (.NOT. ASSOCIATED(g_l3)) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    CALL IF_Log_Debug("MD_WB_SetContainer: L3 container bound")
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_WB_SetContainer

  !====================================================================
  ! Private helper ??guard + whitelist check
  !====================================================================
  SUBROUTINE WB_Guard(domain_name, field_name, status)
    CHARACTER(LEN=*),      INTENT(IN)  :: domain_name, field_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    g_total_writebacks = g_total_writebacks + 1_i4

    IF (.NOT. g_api_initialized .OR. .NOT. ASSOCIATED(g_l3)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "WriteBack API not initialised or container not bound"
      RETURN
    END IF

    ! Prefer container's writeback (single source of truth); fallback to Mgr global
    IF (ASSOCIATED(g_l3) .AND. g_l3%desc%writeback%initialized) THEN
      IF (.NOT. g_l3%desc%writeback%IsAllowed(domain_name, field_name)) THEN
        g_denied_writebacks = g_denied_writebacks + 1_i4
        status%status_code  = STATUS_WRITEBACK_DENIED
        status%message = "WriteBack denied: " // TRIM(domain_name) // &
                         "." // TRIM(field_name) // " not in whitelist"
        CALL IF_Log_Warning(TRIM(status%message))
        RETURN
      END IF
    ELSE
      IF (.NOT. Is_WriteBack_Allowed(domain_name, field_name)) THEN
        g_denied_writebacks = g_denied_writebacks + 1_i4
        status%status_code  = STATUS_WRITEBACK_DENIED
        status%message = "WriteBack denied: " // TRIM(domain_name) // &
                         "." // TRIM(field_name) // " not in whitelist"
        CALL IF_Log_Warning(TRIM(status%message))
        RETURN
      END IF
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE WB_Guard

  !====================================================================
  ! MD_WB_Step ??update Step domain runtime state
  !
  ! Whitelist fields: step.currentTime, step.currentStepInc, step.is_complete
  ! Domain: step%WriteBack(step_idx, current_time, current_increment, is_complete, status)
  !====================================================================
  SUBROUTINE MD_WB_Step(step_idx, currentTime, currentInc, is_complete, status)
    INTEGER(i4),           INTENT(IN)  :: step_idx
    REAL(wp),              INTENT(IN)  :: currentTime
    INTEGER(i4),           INTENT(IN)  :: currentInc
    LOGICAL,               INTENT(IN)  :: is_complete
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("step", "currentTime", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL g_l3%desc%step%WriteBack(step_idx, currentTime, currentInc, is_complete, status)

  END SUBROUTINE MD_WB_Step

  !====================================================================
  ! MD_WB_Amplitude ??update Amplitude domain runtime state (one entry)
  !
  ! Whitelist fields: amplitude.currentValue
  ! Optional step_idx, incr_idx for data chain (L3→L5).
  !====================================================================
  SUBROUTINE MD_WB_Amplitude(idx, currentValue, currentTime, currentIndex, status, step_idx, incr_idx)
    INTEGER(i4),           INTENT(IN)  :: idx
    REAL(wp),              INTENT(IN)  :: currentValue
    REAL(wp),              INTENT(IN)  :: currentTime
    INTEGER(i4),           INTENT(IN)  :: currentIndex
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4),           INTENT(IN), OPTIONAL :: step_idx, incr_idx

    CALL WB_Guard("amplitude", "currentValue", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (PRESENT(step_idx) .AND. PRESENT(incr_idx)) THEN
      CALL g_l3%desc%amplitude%WriteBack(idx, currentValue, currentTime, &
          currentIndex, step_idx=step_idx, incr_idx=incr_idx, status=status)
    ELSE
      CALL g_l3%desc%amplitude%WriteBack(idx, currentValue, currentTime, &
          currentIndex, status=status)
    END IF

  END SUBROUTINE MD_WB_Amplitude

  !====================================================================
  ! MD_WB_LoadBC ??update LoadBC domain runtime state
  !
  ! Whitelist fields: loadbc.currentLoadScale, loadbc.currentBCValue
  ! Pass load_idx=0 to skip load update; bc_idx=0 to skip BC update.
  ! Optional step_idx, incr_idx for data chain (L3→L5).
  !====================================================================
  SUBROUTINE MD_WB_LoadBC(load_idx, bc_idx, load_scale, load_active, &
                           bc_value, bc_active, status, step_idx, incr_idx)
    INTEGER(i4),           INTENT(IN)  :: load_idx, bc_idx
    REAL(wp),              INTENT(IN)  :: load_scale, bc_value
    LOGICAL,               INTENT(IN)  :: load_active, bc_active
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4),           INTENT(IN), OPTIONAL :: step_idx, incr_idx

    CALL WB_Guard("loadbc", "currentLoadScale", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (PRESENT(step_idx) .AND. PRESENT(incr_idx)) THEN
      CALL g_l3%desc%loadbc%WriteBack(load_idx, bc_idx, load_scale, load_active, &
          bc_value, bc_active, status, step_idx=step_idx, incr_idx=incr_idx)
    ELSE
      CALL g_l3%desc%loadbc%WriteBack(load_idx, bc_idx, load_scale, load_active, &
          bc_value, bc_active, status)
    END IF

  END SUBROUTINE MD_WB_LoadBC

  !====================================================================
  ! MD_WB_Mesh ??update Mesh domain assembly state (nAssembled)
  !
  ! Whitelist field: mesh.currentDOF ??domain WriteBack_State(n_assembled)
  !====================================================================
  SUBROUTINE MD_WB_Mesh(n_assembled, status)
    INTEGER(i4),           INTENT(IN)  :: n_assembled
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("mesh", "currentDOF", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL g_l3%desc%mesh%WriteBack_State(n_assembled, status)

  END SUBROUTINE MD_WB_Mesh

  !====================================================================
  ! MD_WB_Mesh_NodePos - update node currentCoords (large-deform only)
  ! Whitelist field: mesh.node_coordinate -> node_state(i)%currentCoords
  !====================================================================
  SUBROUTINE MD_WB_Mesh_NodePos(node_idx, new_coords, status)
    INTEGER(i4),           INTENT(IN)  :: node_idx
    REAL(wp),              INTENT(IN)  :: new_coords(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("mesh", "node_coordinate", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL g_l3%desc%mesh%WriteBack_NodePos(INT(node_idx, i8), new_coords, status)

  END SUBROUTINE MD_WB_Mesh_NodePos

  !====================================================================
  ! MD_WB_Mesh_NodeDisp - update node displacement (solution field u)
  ! Whitelist field: mesh.currentNodeDisp -> node_state(i)%disp
  !====================================================================
  SUBROUTINE MD_WB_Mesh_NodeDisp(node_idx, new_disp, status)
    INTEGER(i4),           INTENT(IN)  :: node_idx
    REAL(wp),              INTENT(IN)  :: new_disp(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("mesh", "currentNodeDisp", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL g_l3%desc%mesh%WriteBack_NodeDisp(INT(node_idx, i8), new_disp, status)
  END SUBROUTINE MD_WB_Mesh_NodeDisp

  !====================================================================
  ! MD_WB_Mesh_NodeVel - update node velocity (mesh.currentNodeVel)
  !====================================================================
  SUBROUTINE MD_WB_Mesh_NodeVel(node_idx, new_vel, status)
    INTEGER(i4),           INTENT(IN)  :: node_idx
    REAL(wp),              INTENT(IN)  :: new_vel(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("mesh", "currentNodeVel", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL g_l3%desc%mesh%WriteBack_NodeVel(INT(node_idx, i8), new_vel, status)
  END SUBROUTINE MD_WB_Mesh_NodeVel

  !====================================================================
  ! MD_WB_Mesh_NodeAcc - update node acceleration (mesh.currentNodeAcc)
  !====================================================================
  SUBROUTINE MD_WB_Mesh_NodeAcc(node_idx, new_acc, status)
    INTEGER(i4),           INTENT(IN)  :: node_idx
    REAL(wp),              INTENT(IN)  :: new_acc(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("mesh", "currentNodeAcc", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL g_l3%desc%mesh%WriteBack_NodeAcc(INT(node_idx, i8), new_acc, status)
  END SUBROUTINE MD_WB_Mesh_NodeAcc

  !====================================================================
  ! MD_WB_Mesh_ElemStress - update elem_state(elem_idx)%ipStates(ip_idx)%sigma
  ! Whitelist field: mesh.elem_ip_stress -> elem_state%ipStates%sigma
  !====================================================================
  SUBROUTINE MD_WB_Mesh_ElemStress(elem_idx, ip_idx, sigma, status)
    INTEGER(i4),           INTENT(IN)  :: elem_idx, ip_idx
    REAL(wp),              INTENT(IN)  :: sigma(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Mesh_WriteBack_ElemStress_Arg) :: arg

    CALL WB_Guard("mesh", "elem_ip_stress", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    arg%ip_idx = ip_idx
    arg%sigma = sigma
    CALL MD_Mesh_WriteBack_ElemStress_Idx(elem_idx, arg, status)
  END SUBROUTINE MD_WB_Mesh_ElemStress

  !====================================================================
  ! MD_WB_Model ??mark model build complete
  !
  ! Whitelist fields: model.isBuilt, model.build_timestamp
  !====================================================================
  SUBROUTINE MD_WB_Model(isBuilt, build_timestamp, status)
    LOGICAL,               INTENT(IN)  :: isBuilt
    REAL(wp),              INTENT(IN)  :: build_timestamp
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL WB_Guard("model", "isBuilt", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL g_l3%desc%model%WriteBack(isBuilt, build_timestamp, status)

  END SUBROUTINE MD_WB_Model

  !====================================================================
  ! MD_WB_Interaction ??update contact pair runtime state
  !
  ! Whitelist: interaction.isActive (WriteBack_Active), interaction.currentContactStatus (WriteBack_State)
  ! Optional step_idx, incr_idx for data chain (L3→L5).
  !====================================================================
  SUBROUTINE MD_WB_Interaction(pair_idx, contact_status, isActive, status, step_idx, incr_idx)
    INTEGER(i4),           INTENT(IN)  :: pair_idx
    INTEGER(i4),           INTENT(IN)  :: contact_status
    LOGICAL,               INTENT(IN)  :: isActive
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4),           INTENT(IN), OPTIONAL :: step_idx, incr_idx

    CALL WB_Guard("interaction", "isActive", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL g_l3%desc%interaction%WriteBack_Active(pair_idx, isActive, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    IF (PRESENT(step_idx) .AND. PRESENT(incr_idx)) THEN
      CALL g_l3%desc%interaction%WriteBack_State(pair_idx, 0.0_wp, 0.0_wp, 0.0_wp, &
          contact_status, status, step_idx=step_idx, incr_idx=incr_idx)
    ELSE
      CALL g_l3%desc%interaction%WriteBack_State(pair_idx, 0.0_wp, 0.0_wp, 0.0_wp, &
          contact_status, status)
    END IF

  END SUBROUTINE MD_WB_Interaction

  !====================================================================
  ! MD_WB_Output ??update Output domain write-tracking state
  !
  ! Whitelist field: output.lastWrittenInc
  ! Optional step_idx, incr_idx for data chain (L3→L5).
  !====================================================================
  SUBROUTINE MD_WB_Output(lastWrittenInc, lastWrittenTime, totalFrames, status, step_idx, incr_idx)
    INTEGER(i4),           INTENT(IN)  :: lastWrittenInc, totalFrames
    REAL(wp),              INTENT(IN)  :: lastWrittenTime
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4),           INTENT(IN), OPTIONAL :: step_idx, incr_idx

    CALL WB_Guard("output", "lastWrittenInc", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (PRESENT(step_idx) .AND. PRESENT(incr_idx)) THEN
      CALL g_l3%desc%output%WriteBack(lastWrittenInc, lastWrittenTime, totalFrames, &
          status, step_idx=step_idx, incr_idx=incr_idx)
    ELSE
      CALL g_l3%desc%output%WriteBack(lastWrittenInc, lastWrittenTime, totalFrames, status)
    END IF

  END SUBROUTINE MD_WB_Output

END MODULE MD_WB_Brg
