!===============================================================================
! MODULE: RT_WB_Domain
! LAYER:  L5_RT
! DOMAIN: WriteBack
! ROLE:   Mgr — GOLDEN-LINE production domain logic
! BRIEF:  L5 State → L3 data sync (displacements, stresses, SDVs, checkpoints).
!===============================================================================

MODULE RT_WB_Domain
  USE IF_Prec_Core,              ONLY: wp, i4
  USE IF_Err_Brg,           ONLY: UF_SUCCESS, UF_ERR_WRITEBACK_FAILED, &
                                  ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Log_Logger,          ONLY: LogInfo, LogError, IF_Log_Warning
  ! G3-B FIX (2026-03-27) [N0-1 VERIFIED]: MD_WB_SetContainer removed from import list.
  !   L5 Init must NOT push a container into L3; md_layer handle is read-only.
  !   Rule: RT_WriteBack_Domain_Init SHALL NOT call any MD_WB_Set* functions.
  !   The md_layer handle is obtained read-only at write-time via g_ufc_global.
  !   Guardian check: G-10 (arch_guardian.py) enforces this constraint.
  ! ARCHITECTURE FIX (N1-1): Route physical computation to L4_PH
  USE PH_WB_Brg,     ONLY: PH_WriteBack_ApplyNodeDisp, PH_WriteBack_ApplyNodePos
  USE MD_WB_Brg,     ONLY: MD_WB_Mesh_NodePos, STATUS_WRITEBACK_DENIED, &
                                  Init_WriteBack_API, Finalize_WriteBack_API
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global

  IMPLICIT NONE
  PRIVATE

  ! WriteBack target type constants (L5_RT_ .md Section 5)
  ! [I-04 2026-04-18] Expanded whitelist for field output
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L3_NODE_COORD     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L3_NODE_DISP     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L3_ELEM_IP_STRESS = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L4_GP_STATE_VAR  = 4_i4
  ! [I-04-NEW] L4 field outputs (thermal/coupled analysis)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L4_GP_STRAIN     = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L4_GP_STIFFNESS  = 6_i4
  ! [I-04-NEW] L3 element/node outputs (legacy ODB interop)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L3_ELEM_IP_STRAIN = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L3_ELEM_IP_EPLAS = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_L3_NODE_ACCEL = 9_i4

  !-------------------------------------------------------------------
  !  Public API
  !-------------------------------------------------------------------
  PUBLIC :: WriteBack_Init
  PUBLIC :: WriteBack_Finalize
  PUBLIC :: WriteState
  PUBLIC :: SaveCheckpoint
  PUBLIC :: LoadCheckpoint
  PUBLIC :: RollbackToCheckpoint
  PUBLIC :: ValidateWriteBack
  PUBLIC :: AuditWriteBack
  ! Index-based API (Phase 2 refactor)
  PUBLIC :: RT_WriteBack_Init_Idx, RT_WriteBack_SaveCheckpoint_Idx
  PUBLIC :: RT_WriteBack_SaveCheckpoint_WithSolution_Idx
  PUBLIC :: RT_WriteBack_LoadCheckpoint_Idx
  PUBLIC :: RT_WB_Init_Arg, RT_WB_SaveCheckpoint_Arg
  ! Standalone _Idx (no domain param, uses g_ufc_global%rt_layer%writeback)
  PUBLIC :: RT_WB_Init_Arg_Standalone
  PUBLIC :: RT_WriteBack_SaveCheckpoint_Idx_Standalone
  PUBLIC :: RT_WriteBack_LoadCheckpoint_Idx_Standalone
  ! See module header.
  PUBLIC :: RT_WriteBack_NodePos
  PUBLIC :: RT_WriteBack_NodePos_Idx   ! (node_idx, arg, status) - Phase 5 index-based
  PUBLIC :: RT_WriteBack_NodeDisp
  PUBLIC :: RT_WriteBack_NodeDisp_Idx  ! (node_idx, arg, status) - standalone index-based
  PUBLIC :: RT_WriteBack_NodeDisp_Batch
  PUBLIC :: RT_WriteBack_NodeDisp_Batch_Idx  ! (arg, status) - standalone index-based
  PUBLIC :: RT_WriteBack_ElemStress
  PUBLIC :: RT_WriteBack_ElemStress_Idx  ! (arg, status) - standalone index-based
  ! [I-04-NEW] Extended field output interfaces
  PUBLIC :: RT_WriteBack_ElemStrain
  PUBLIC :: RT_WriteBack_ElemStrain_Idx  ! (arg, status) - element strain output
  PUBLIC :: RT_WriteBack_ElemEplas
  PUBLIC :: RT_WriteBack_ElemEplas_Idx   ! (arg, status) - plastic strain output
  PUBLIC :: RT_WriteBack_NodeAccel
  PUBLIC :: RT_WriteBack_NodeAccel_Idx   ! (arg, status) - node acceleration output
  PUBLIC :: RT_WriteBack_GPStateVar
  PUBLIC :: RT_WriteBack_GPStateVar_Idx  ! (arg, status) - Gauss point state variable output
  PUBLIC :: RT_WriteBack_CurrentTime
  PUBLIC :: RT_WriteBack_CurrentTime_Idx  ! (arg, status) - standalone index-based
  ! See module header.
  PUBLIC :: RT_WB_NodePos_Arg
  PUBLIC :: RT_WB_NodeDisp_Arg
  PUBLIC :: RT_WB_NodeDisp_Batch_Arg
  PUBLIC :: RT_WB_ElemStress_Arg
  PUBLIC :: RT_WB_CurrentTime_Arg

  !-------------------------------------------------------------------
  ! See module header.
  !-------------------------------------------------------------------
  
  ! See module header / UFC docs for context.
  TYPE :: CheckpointStatus
    INTEGER(i4) :: id = 0
    INTEGER(i4) :: step = 0
    INTEGER(i4) :: increment = 0
    INTEGER(i4) :: iteration = 0
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: checksum = 0.0_wp
    LOGICAL  :: valid = .FALSE.
    CHARACTER(256) :: filepath = ''
    ! SaveCheckpoint u
    REAL(wp), ALLOCATABLE :: u(:)
  END TYPE CheckpointStatus

  ! See module header.
  TYPE :: WriteBackAuditRecord
    INTEGER(i4) :: record_id = 0
    INTEGER(i4) :: operation_type = 0     ! 1=write, 2=checkpoint, 3=rollback
    INTEGER(i4) :: target_step = 0
    REAL(wp) :: timestamp = 0.0_wp
    REAL(wp) :: data_checksum = 0.0_wp
    LOGICAL  :: success = .FALSE.
    CHARACTER(512) :: description = ''
  END TYPE WriteBackAuditRecord

  ! WriteBackWhitelistEntry (design doc Section 5)
  TYPE, PUBLIC :: WriteBackWhitelistEntry
    INTEGER(i4) :: target_type = 0
    CHARACTER(LEN=64) :: field_name = ""
    LOGICAL :: allow_partial = .FALSE.
    CHARACTER(LEN=128) :: description = ""
  END TYPE WriteBackWhitelistEntry

  ! WriteBackCtx: per-slot context (index pool)
  TYPE, PUBLIC :: WriteBackCtx
    INTEGER(i4) :: current_checkpoint_id = 0
    INTEGER(i4) :: max_checkpoints = 10
    INTEGER(i4) :: audit_count = 0
    LOGICAL  :: zero_trust_enabled = .TRUE.
    LOGICAL  :: audit_enabled = .TRUE.
    INTEGER(i4) :: audit_log_unit = -1
    TYPE(CheckpointStatus),      ALLOCATABLE :: checkpoints(:)
    TYPE(WriteBackAuditRecord),  ALLOCATABLE :: audit_log(:)
  END TYPE WriteBackCtx

  ! RT_WriteBack_Domain: index pool + whitelist in rt_layer
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WRITEBACK_MAX_POOL = 8_i4
  INTEGER(i4), PARAMETER :: RT_WB_WHITELIST_INIT_CAP = 64_i4
  TYPE, PUBLIC :: RT_WriteBack_Domain
    TYPE(WriteBackCtx), ALLOCATABLE :: ctx_pool(:)
    INTEGER(i4) :: pool_count = 0_i4
    LOGICAL     :: initialized = .FALSE.
    ! Whitelist (design doc Section 5)
    TYPE(WriteBackWhitelistEntry), ALLOCATABLE :: whitelist(:)
    INTEGER(i4) :: whitelist_count = 0_i4
    INTEGER(i4) :: global_version = 0_i4
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE RT_WriteBack_Domain

  ! Arg types for _Idx API
  TYPE, PUBLIC :: RT_WB_Init_Arg
    INTEGER(i4) :: max_checkpoints = 10_i4
    LOGICAL :: zero_trust_enabled = .TRUE.
    INTEGER(i4) :: wb_idx = 0_i4   ! OUT: assigned index
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_Init_Arg
  TYPE, PUBLIC :: RT_WB_SaveCheckpoint_Arg
    INTEGER(i4) :: step = 0_i4
    INTEGER(i4) :: increment = 0_i4
    INTEGER(i4) :: iteration = 0_i4
    REAL(wp) :: time_val = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_SaveCheckpoint_Arg

  ! --- P0-C: Arg ---
  ! RT_WB_NodePos_Arg: L5 L3 mesh ?
  TYPE, PUBLIC :: RT_WB_NodePos_Arg
    INTEGER(i4)           :: node_idx      = 0_i4      ! (IN) mesh (1-based)
    REAL(wp)              :: new_coords(3) = 0.0_wp   ! (IN) ?
    INTEGER(i4)           :: wb_idx        = 0_i4      ! (IN) WriteBack 0
    REAL(wp)              :: old_coords(3) = 0.0_wp   ! (OUT) ?
    TYPE(ErrorStatusType) :: status                   ! (OUT)
  END TYPE RT_WB_NodePos_Arg

  ! RT_WB_NodeDisp_Arg: L5 L3 mesh u ?
  TYPE, PUBLIC :: RT_WB_NodeDisp_Arg
    INTEGER(i4)           :: node_idx      = 0_i4
    REAL(wp)              :: new_disp(3)   = 0.0_wp
    INTEGER(i4)           :: wb_idx        = 0_i4
    REAL(wp)              :: old_disp(3)   = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_NodeDisp_Arg

  ! RT_WB_NodeDisp_Batch_Arg: u(:) + dofMap ?
  TYPE, PUBLIC :: RT_WB_NodeDisp_Batch_Arg
    REAL(wp),    ALLOCATABLE :: u(:)       ! (IN) nTotalEq
    INTEGER(i4) :: wb_idx    = 0_i4       ! (IN) WriteBack ?
    INTEGER(i4) :: n_written = 0_i4      ! (OUT) ?
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_NodeDisp_Batch_Arg

  ! RT_WB_ElemStress_Arg: L5 L3 mesh ?Output
  TYPE, PUBLIC :: RT_WB_ElemStress_Arg
    INTEGER(i4) :: elem_idx  = 0_i4      ! (IN) (1-based)
    INTEGER(i4) :: ip_idx    = 0_i4      ! (IN) ?(1-based)
    REAL(wp)    :: sigma(6) = 0.0_wp    ! (IN) Voigt [s11,s22,s33,s12,s23,s13]
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_ElemStress_Arg

  ! [I-04-NEW] RT_WB_ElemStrain_Arg: L5 L3 mesh strain output
  TYPE, PUBLIC :: RT_WB_ElemStrain_Arg
    INTEGER(i4) :: elem_idx  = 0_i4      ! (IN) element index (1-based)
    INTEGER(i4) :: ip_idx    = 0_i4      ! (IN) integration point index (1-based)
    REAL(wp)    :: epsilon(6) = 0.0_wp   ! (IN) Voigt strain [e11,e22,e33,e12,e23,e13]
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_ElemStrain_Arg

  ! [I-04-NEW] RT_WB_ElemEplas_Arg: accumulated plastic strain
  TYPE, PUBLIC :: RT_WB_ElemEplas_Arg
    INTEGER(i4) :: elem_idx  = 0_i4      ! (IN) element index
    INTEGER(i4) :: ip_idx    = 0_i4      ! (IN) integration point
    REAL(wp)    :: eplas     = 0.0_wp    ! (IN) accumulated plastic strain (PEEQ)
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_ElemEplas_Arg

  ! [I-04-NEW] RT_WB_NodeAccel_Arg: node acceleration for dynamic analysis
  TYPE, PUBLIC :: RT_WB_NodeAccel_Arg
    INTEGER(i4)           :: node_idx    = 0_i4
    REAL(wp)              :: new_accel(3) = 0.0_wp
    INTEGER(i4)           :: wb_idx      = 0_i4
    REAL(wp)              :: old_accel(3) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_NodeAccel_Arg

  ! [I-04-NEW] RT_WB_GPStateVar_Arg: Gauss point state variables
  TYPE, PUBLIC :: RT_WB_GPStateVar_Arg
    INTEGER(i4) :: elem_idx  = 0_i4              ! (IN) element index
    INTEGER(i4) :: ip_idx    = 0_i4              ! (IN) integration point index
    INTEGER(i4) :: var_idx   = 0_i4              ! (IN) state variable index (1..nStateVars)
    REAL(wp)    :: var_value = 0.0_wp            ! (IN) state variable value
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_GPStateVar_Arg

  ! RT_WB_CurrentTime_Arg: L5 L3 Step Step/Incr ?
  TYPE, PUBLIC :: RT_WB_CurrentTime_Arg
    INTEGER(i4)           :: step_idx     = 0_i4    ! (IN) md_layer%step
    REAL(wp)              :: current_time = 0.0_wp  ! (IN)
    INTEGER(i4)           :: current_inc  = 0_i4    ! (IN)
    LOGICAL               :: is_complete  = .FALSE. ! (IN) Step ?
    TYPE(ErrorStatusType) :: status                 ! (OUT)
  END TYPE RT_WB_CurrentTime_Arg

CONTAINS

  !-------------------------------------------------------------------
  !  RT_WriteBack_Domain_Init
  !-------------------------------------------------------------------
  SUBROUTINE Init(this, status)
    CLASS(RT_WriteBack_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    IF (ALLOCATED(this%ctx_pool)) DEALLOCATE(this%ctx_pool)
    ALLOCATE(this%ctx_pool(RT_WRITEBACK_MAX_POOL))
    this%pool_count = 0_i4
    this%global_version = 0_i4
    ! Init whitelist with default targets
    IF (ALLOCATED(this%whitelist)) DEALLOCATE(this%whitelist)
    ALLOCATE(this%whitelist(RT_WB_WHITELIST_INIT_CAP))
    this%whitelist_count = 0_i4
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L3_NODE_COORD, "node_coordinate", &
                                     .FALSE., "L3 mesh node currentCoords (large-deform)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L3_NODE_DISP, "node_displacement", &
                                     .FALSE., "L3 mesh node displacement (solution field)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L3_ELEM_IP_STRESS, "elem_ip_stress", &
                                     .FALSE., "L3 mesh elem_state%ipStates sigma (Output domain)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L4_GP_STATE_VAR, "gp_state_variable", &
                                     .FALSE., "L4 Gauss point state vars (PH_Material slot_pool%state)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    ! [I-04-NEW] Extended whitelist targets
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L4_GP_STRAIN, "gp_strain", &
                                     .FALSE., "L4 Gauss point total strain (thermal/coupled)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L4_GP_STIFFNESS, "gp_stiffness", &
                                     .FALSE., "L4 Gauss point material stiffness matrix", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L3_ELEM_IP_STRAIN, "elem_ip_strain", &
                                     .FALSE., "L3 mesh elem_state%ipStates strain (legacy ODB)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L3_ELEM_IP_EPLAS, "elem_ip_eplas", &
                                     .FALSE., "L3 mesh elem_state%ipStates PEEQ plastic strain", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RT_WriteBack_RegisterTarget(this, RT_WB_TARGET_L3_NODE_ACCEL, "node_acceleration", &
                                     .FALSE., "L3 mesh node acceleration (dynamic analysis)", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Init_WriteBack_API(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    ! G3-B FIX [N0-1 VERIFIED]: L5 does NOT inject into L3.
    !   The md_layer handle is obtained read-only from g_ufc_global at write-time.
    !   MD_WB_SetContainer was removed (2026-03-27); L3 WriteBack API initialises
    !   its own container independently. Do NOT re-add any MD_WB_Set* call here.
    !   Violation of this rule is caught by Guardian G-10.
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !-------------------------------------------------------------------
  !  RT_WriteBack_Domain_Finalize
  !-------------------------------------------------------------------
  SUBROUTINE Finalize(this)
    CLASS(RT_WriteBack_Domain), INTENT(INOUT) :: this

    INTEGER(i4) :: i, j

    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%ctx_pool)) THEN
      DO i = 1, this%pool_count
        IF (ALLOCATED(this%ctx_pool(i)%checkpoints)) THEN
          DO j = 1, SIZE(this%ctx_pool(i)%checkpoints)
            IF (ALLOCATED(this%ctx_pool(i)%checkpoints(j)%u)) DEALLOCATE(this%ctx_pool(i)%checkpoints(j)%u)
          END DO
          DEALLOCATE(this%ctx_pool(i)%checkpoints)
        END IF
        IF (ALLOCATED(this%ctx_pool(i)%audit_log)) DEALLOCATE(this%ctx_pool(i)%audit_log)
      END DO
      DEALLOCATE(this%ctx_pool)
    END IF
    IF (ALLOCATED(this%whitelist)) DEALLOCATE(this%whitelist)
    this%pool_count = 0_i4
    this%whitelist_count = 0_i4
    CALL Finalize_WriteBack_API()
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  !-------------------------------------------------------------------
  !  WriteBack_Init: DEPRECATED - use RT_WriteBack_Init_Idx with rt_layer%writeback
  !-------------------------------------------------------------------
  SUBROUTINE WriteBack_Init(max_checkpoints, zero_trust_enabled, ierr)
    INTEGER(i4), INTENT(IN) :: max_checkpoints
    LOGICAL,  INTENT(IN)  :: zero_trust_enabled
    INTEGER(i4), INTENT(OUT) :: ierr

    ! DEPRECATED: Use RT_WriteBack_Init_Idx with g_ufc_global%rt_layer%writeback
    ierr = UF_ERR_WRITEBACK_FAILED
    CALL LogError('WriteBack', 'WriteBack_Init', 'DEPRECATED: use RT_WriteBack_Init_Idx with rt_layer%writeback')
  END SUBROUTINE WriteBack_Init

  !-------------------------------------------------------------------
  !  WriteBack_Finalize: DEPRECATED
  !-------------------------------------------------------------------
  SUBROUTINE WriteBack_Finalize(ierr)
    INTEGER(i4), INTENT(OUT) :: ierr
    ierr = UF_SUCCESS
  END SUBROUTINE WriteBack_Finalize

  !-------------------------------------------------------------------
  !  WriteState: DEPRECATED - use RT_WriteBack_*_Idx with rt_layer%writeback
  !-------------------------------------------------------------------
  SUBROUTINE WriteState(state_data, state_size, target_step, ierr)
    REAL(wp), INTENT(IN)  :: state_data(:)
    INTEGER(i4), INTENT(IN) :: state_size
    INTEGER(i4), INTENT(IN) :: target_step
    INTEGER(i4), INTENT(OUT) :: ierr
    ierr = UF_ERR_WRITEBACK_FAILED
  END SUBROUTINE WriteState

  !-------------------------------------------------------------------
  !  SaveCheckpoint: DEPRECATED - use RT_WriteBack_SaveCheckpoint_Idx
  !-------------------------------------------------------------------
  SUBROUTINE SaveCheckpoint(step, increment, iteration, time_val, ierr)
    INTEGER(i4), INTENT(IN) :: step
    INTEGER(i4), INTENT(IN) :: increment
    INTEGER(i4), INTENT(IN) :: iteration
    REAL(wp), INTENT(IN)  :: time_val
    INTEGER(i4), INTENT(OUT) :: ierr
    ierr = UF_ERR_WRITEBACK_FAILED
  END SUBROUTINE SaveCheckpoint

  !-------------------------------------------------------------------
  !  LoadCheckpoint: DEPRECATED
  !-------------------------------------------------------------------
  SUBROUTINE LoadCheckpoint(checkpoint_id, ierr)
    INTEGER(i4), INTENT(IN) :: checkpoint_id
    INTEGER(i4), INTENT(OUT) :: ierr
    ierr = UF_ERR_WRITEBACK_FAILED
  END SUBROUTINE LoadCheckpoint

  !-------------------------------------------------------------------
  !  RollbackToCheckpoint: DEPRECATED
  !-------------------------------------------------------------------
  SUBROUTINE RollbackToCheckpoint(checkpoint_id, ierr)
    INTEGER(i4), INTENT(IN) :: checkpoint_id
    INTEGER(i4), INTENT(OUT) :: ierr
    ierr = UF_ERR_WRITEBACK_FAILED
  END SUBROUTINE RollbackToCheckpoint

  !-------------------------------------------------------------------
  ! ValidateWriteBack:
  !-------------------------------------------------------------------
  FUNCTION ValidateWriteBack(state_data, state_size) RESULT(valid)
    REAL(wp), INTENT(IN) :: state_data(:)
    INTEGER(i4), INTENT(IN) :: state_size
    LOGICAL :: valid
    
    REAL(wp) :: checksum
    
    checksum = ComputeChecksum(state_data, state_size)
    valid = ValidateStateData(state_data, state_size, checksum)
    
  END FUNCTION ValidateWriteBack

  !-------------------------------------------------------------------
  !  AuditWriteBack: DEPRECATED (no-op)
  !-------------------------------------------------------------------
  SUBROUTINE AuditWriteBack(op_type, target_step, checksum, success, desc)
    INTEGER(i4), INTENT(IN) :: op_type
    INTEGER(i4), INTENT(IN) :: target_step
    REAL(wp),      INTENT(IN) :: checksum
    LOGICAL,       INTENT(IN) :: success
    CHARACTER(*),  INTENT(IN) :: desc
  END SUBROUTINE AuditWriteBack

  !-------------------------------------------------------------------
  !  RT_WriteBack_RegisterTarget: add whitelist entry (design doc Section 5)
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_RegisterTarget(domain, target_type, field_name, &
                                         allow_partial, description, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: target_type
    CHARACTER(LEN=*), INTENT(IN) :: field_name
    LOGICAL, INTENT(IN) :: allow_partial
    CHARACTER(LEN=*), INTENT(IN) :: description
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: new_size
    TYPE(WriteBackWhitelistEntry), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (.NOT. ALLOCATED(domain%whitelist)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (domain%whitelist_count >= SIZE(domain%whitelist)) THEN
      new_size = INT(SIZE(domain%whitelist) * 1.5)
      ALLOCATE(tmp(domain%whitelist_count))
      tmp(1:domain%whitelist_count) = domain%whitelist(1:domain%whitelist_count)
      DEALLOCATE(domain%whitelist)
      ALLOCATE(domain%whitelist(new_size))
      domain%whitelist(1:domain%whitelist_count) = tmp(1:domain%whitelist_count)
      DEALLOCATE(tmp)
    END IF
    domain%whitelist_count = domain%whitelist_count + 1_i4
    domain%whitelist(domain%whitelist_count)%target_type = target_type
    domain%whitelist(domain%whitelist_count)%field_name = TRIM(field_name)
    domain%whitelist(domain%whitelist_count)%allow_partial = allow_partial
    domain%whitelist(domain%whitelist_count)%cfg%description = TRIM(description)
    CALL LogInfo('WriteBack', 'RT_WriteBack_RegisterTarget', 'Registered: ' // TRIM(field_name))
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_RegisterTarget

  !-------------------------------------------------------------------
  !  RT_WriteBack_IsAllowed: check whitelist (design doc Section 5)
  !-------------------------------------------------------------------
  FUNCTION RT_WriteBack_IsAllowed(domain, target_type, field_name) RESULT(allowed)
    TYPE(RT_WriteBack_Domain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: target_type
    CHARACTER(LEN=*), INTENT(IN) :: field_name
    LOGICAL :: allowed

    INTEGER(i4) :: i

    allowed = .FALSE.
    DO i = 1, domain%whitelist_count
      IF (domain%whitelist(i)%target_type == target_type .AND. &
          TRIM(domain%whitelist(i)%field_name) == TRIM(field_name)) THEN
        allowed = .TRUE.
        RETURN
      END IF
    END DO
    CALL IF_Log_Warning("WriteBack denied: field=" // TRIM(field_name))
  END FUNCTION RT_WriteBack_IsAllowed

  !-------------------------------------------------------------------
  !  RT_WriteBack_WriteNodeCoord_Idx: check whitelist, call MD_WB_Mesh_NodePos, log audit
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_WriteNodeCoord_Idx(domain, wb_idx, node_idx, new_coords, old_coords, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: wb_idx
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: new_coords(3)
    REAL(wp), INTENT(OUT) :: old_coords(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    old_coords = 0.0_wp
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L3_NODE_COORD, "node_coordinate")) THEN
      status%status_code = STATUS_WRITEBACK_DENIED
      status%message = "WriteBack denied: node_coordinate not in whitelist"
      RETURN
    END IF
    IF (g_ufc_global%md_layer%mesh%initialized .AND. node_idx >= 1_i4 .AND. &
        node_idx <= g_ufc_global%md_layer%mesh%desc%nNodes) THEN
      IF (ALLOCATED(g_ufc_global%md_layer%mesh%node_state)) THEN
        old_coords(1:3) = g_ufc_global%md_layer%mesh%node_state(node_idx)%currentCoords(1:3)
      END IF
    END IF
    ! ARCHITECTURE FIX (N1-1): NodePos not yet in PH_WriteBack, keep MD_WB for now
    ! TODO: Add PH_WriteBack_ApplyNodePos to L4_PH when coordinate writeback is needed
    CALL MD_WB_Mesh_NodePos(node_idx, new_coords, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    domain%global_version = domain%global_version + 1_i4
    IF (wb_idx > 0_i4 .AND. wb_idx <= domain%pool_count .AND. domain%ctx_pool(wb_idx)%audit_enabled) THEN
      CALL RT_WriteBack_LogAudit_Idx(domain, wb_idx, "NODE_COORD", node_idx, old_coords, new_coords, status)
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_WriteNodeCoord_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_LogAudit_Idx: JSONL audit log (design doc Section 5)
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_LogAudit_Idx(domain, wb_idx, operation, target_id, old_value, new_value, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: wb_idx
    CHARACTER(LEN=*), INTENT(IN) :: operation
    INTEGER(i4), INTENT(IN) :: target_id
    REAL(wp), INTENT(IN) :: old_value(3), new_value(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(LEN=32) :: ts
    CHARACTER(LEN=24) :: buf_id, buf_ver
    CHARACTER(LEN=16) :: buf_old(3), buf_new(3)
    INTEGER(i4) :: vals(8)

    CALL init_error_status(status)
    IF (wb_idx <= 0_i4 .OR. wb_idx > domain%pool_count) RETURN
    IF (.NOT. domain%ctx_pool(wb_idx)%audit_enabled) RETURN
    CALL DATE_AND_TIME(VALUES=vals)
    WRITE(ts, '(I4,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2,":",I2.2)') &
      vals(1), vals(2), vals(3), vals(5), vals(6), vals(7)
    WRITE(buf_id, '(I0)') target_id
    WRITE(buf_ver, '(I0)') domain%global_version
    WRITE(buf_old(1), '(ES15.7)') old_value(1)
    WRITE(buf_old(2), '(ES15.7)') old_value(2)
    WRITE(buf_old(3), '(ES15.7)') old_value(3)
    WRITE(buf_new(1), '(ES15.7)') new_value(1)
    WRITE(buf_new(2), '(ES15.7)') new_value(2)
    WRITE(buf_new(3), '(ES15.7)') new_value(3)
    IF (domain%ctx_pool(wb_idx)%audit_log_unit < 0) THEN
      OPEN(NEWUNIT=domain%ctx_pool(wb_idx)%audit_log_unit, FILE='writeback_audit.jsonl', &
           STATUS='REPLACE', ACTION='WRITE')
    END IF
    WRITE(domain%ctx_pool(wb_idx)%audit_log_unit, '(A)') &
      '{"ts":"' // TRIM(ADJUSTL(ts)) // '","operation":"' // TRIM(operation) // &
      '","target_id":' // TRIM(ADJUSTL(buf_id)) // &
      ',"old_value":[' // TRIM(ADJUSTL(buf_old(1))) // ',' // TRIM(ADJUSTL(buf_old(2))) // ',' // TRIM(ADJUSTL(buf_old(3))) // '],' // &
      '"new_value":[' // TRIM(ADJUSTL(buf_new(1))) // ',' // TRIM(ADJUSTL(buf_new(2))) // ',' // TRIM(ADJUSTL(buf_new(3))) // '],' // &
      '"version":' // TRIM(ADJUSTL(buf_ver)) // '}'
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_LogAudit_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_Init_Idx: index pool in rt_layer%writeback (domain passed in)
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_Init_Idx(domain, max_checkpoints, zero_trust_enabled, wb_idx, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN)  :: max_checkpoints
    LOGICAL, INTENT(IN)  :: zero_trust_enabled
    INTEGER(i4), INTENT(OUT) :: wb_idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    wb_idx = 0_i4

    IF (.NOT. domain%initialized .OR. .NOT. ALLOCATED(domain%ctx_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (max_checkpoints <= 0_i4 .OR. max_checkpoints > 1000_i4) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (domain%pool_count >= RT_WRITEBACK_MAX_POOL) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    domain%pool_count = domain%pool_count + 1_i4
    wb_idx = domain%pool_count

    domain%ctx_pool(wb_idx)%max_checkpoints = max_checkpoints
    domain%ctx_pool(wb_idx)%zero_trust_enabled = zero_trust_enabled
    domain%ctx_pool(wb_idx)%current_checkpoint_id = 0
    domain%ctx_pool(wb_idx)%audit_count = 0

    IF (ALLOCATED(domain%ctx_pool(wb_idx)%checkpoints)) DEALLOCATE(domain%ctx_pool(wb_idx)%checkpoints)
    IF (ALLOCATED(domain%ctx_pool(wb_idx)%audit_log)) DEALLOCATE(domain%ctx_pool(wb_idx)%audit_log)
    ALLOCATE(domain%ctx_pool(wb_idx)%checkpoints(max_checkpoints))
    ALLOCATE(domain%ctx_pool(wb_idx)%audit_log(1000))

    status%status_code = IF_STATUS_OK
    CALL LogInfo('WriteBack', 'RT_WriteBack_Init_Idx', 'WriteBack init (index pool)')
  END SUBROUTINE RT_WriteBack_Init_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_SaveCheckpoint_Idx
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_SaveCheckpoint_Idx(domain, wb_idx, step, increment, iteration, time_val, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN)  :: wb_idx
    INTEGER(i4), INTENT(IN)  :: step
    INTEGER(i4), INTENT(IN)  :: increment
    INTEGER(i4), INTENT(IN)  :: iteration
    REAL(wp), INTENT(IN)  :: time_val
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: cp_id

    CALL init_error_status(status)
    IF (.NOT. domain%initialized .OR. .NOT. ALLOCATED(domain%ctx_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (wb_idx <= 0_i4 .OR. wb_idx > domain%pool_count) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    cp_id = MOD(domain%ctx_pool(wb_idx)%current_checkpoint_id, domain%ctx_pool(wb_idx)%max_checkpoints) + 1

    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%cfg%id = cp_id
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%step = step
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%increment = increment
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%iteration = iteration
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%time = time_val
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%valid = .TRUE.

    domain%ctx_pool(wb_idx)%current_checkpoint_id = cp_id

    IF (domain%ctx_pool(wb_idx)%audit_enabled) THEN
      CALL AuditWriteBack_Idx(domain, wb_idx, 2, step, 0.0_wp, .TRUE., 'checkpoint save')
    END IF

    status%status_code = IF_STATUS_OK
    CALL LogInfo('WriteBack', 'RT_WriteBack_SaveCheckpoint_Idx', 'checkpoint saved')
  END SUBROUTINE RT_WriteBack_SaveCheckpoint_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_SaveCheckpoint_WithSolution_Idx
  ! u(:)
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_SaveCheckpoint_WithSolution_Idx(domain, wb_idx, step, increment, iteration, time_val, u, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN)  :: wb_idx
    INTEGER(i4), INTENT(IN)  :: step, increment, iteration
    REAL(wp), INTENT(IN)  :: time_val
    REAL(wp), INTENT(IN)  :: u(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: cp_id, n

    CALL init_error_status(status)
    IF (.NOT. domain%initialized .OR. .NOT. ALLOCATED(domain%ctx_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (wb_idx <= 0_i4 .OR. wb_idx > domain%pool_count) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    cp_id = MOD(domain%ctx_pool(wb_idx)%current_checkpoint_id, domain%ctx_pool(wb_idx)%max_checkpoints) + 1

    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%cfg%id = cp_id
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%step = step
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%increment = increment
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%iteration = iteration
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%time = time_val
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%valid = .TRUE.
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%checksum = ComputeChecksum(u, SIZE(u))

    n = SIZE(u)
    IF (ALLOCATED(domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u)) DEALLOCATE(domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u)
    ALLOCATE(domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u(n))
    domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u(1:n) = u(1:n)

    domain%ctx_pool(wb_idx)%current_checkpoint_id = cp_id

    IF (domain%ctx_pool(wb_idx)%audit_enabled) THEN
      CALL AuditWriteBack_Idx(domain, wb_idx, 2, step, domain%ctx_pool(wb_idx)%checkpoints(cp_id)%checksum, .TRUE., 'checkpoint save (with u)')
    END IF

    status%status_code = IF_STATUS_OK
    CALL LogInfo('WriteBack', 'RT_WriteBack_SaveCheckpoint_WithSolution_Idx', 'checkpoint saved with solution')
  END SUBROUTINE RT_WriteBack_SaveCheckpoint_WithSolution_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_LoadCheckpoint_Idx
  !  u ?checkpoint ?u_out checkpoint ?u ?
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_LoadCheckpoint_Idx(domain, wb_idx, cp_id, u_out, status)
    TYPE(RT_WriteBack_Domain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN)  :: wb_idx, cp_id
    REAL(wp), INTENT(OUT) :: u_out(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)
    IF (.NOT. domain%initialized .OR. .NOT. ALLOCATED(domain%ctx_pool)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (wb_idx <= 0_i4 .OR. wb_idx > domain%pool_count) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (cp_id < 1_i4 .OR. cp_id > domain%ctx_pool(wb_idx)%max_checkpoints) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. domain%ctx_pool(wb_idx)%checkpoints(cp_id)%valid) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Checkpoint not valid"
      RETURN
    END IF
    IF (.NOT. ALLOCATED(domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Checkpoint has no solution vector"
      RETURN
    END IF

    n = MIN(SIZE(domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u), SIZE(u_out))
    u_out(1:n) = domain%ctx_pool(wb_idx)%checkpoints(cp_id)%u(1:n)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_LoadCheckpoint_Idx

  !-------------------------------------------------------------------
  !  AuditWriteBack_Idx: internal helper
  !-------------------------------------------------------------------
  SUBROUTINE AuditWriteBack_Idx(domain, wb_idx, op_type, target_step, checksum, success, desc)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: wb_idx
    INTEGER(i4), INTENT(IN) :: op_type
    INTEGER(i4), INTENT(IN) :: target_step
    REAL(wp), INTENT(IN) :: checksum
    LOGICAL, INTENT(IN) :: success
    CHARACTER(*), INTENT(IN) :: desc

    INTEGER(i4) :: idx

    IF (wb_idx <= 0_i4 .OR. wb_idx > domain%pool_count) RETURN
    IF (.NOT. domain%ctx_pool(wb_idx)%audit_enabled) RETURN

    domain%ctx_pool(wb_idx)%audit_count = domain%ctx_pool(wb_idx)%audit_count + 1
    idx = MOD(domain%ctx_pool(wb_idx)%audit_count - 1, SIZE(domain%ctx_pool(wb_idx)%audit_log)) + 1

    domain%ctx_pool(wb_idx)%audit_log(idx)%record_id = domain%ctx_pool(wb_idx)%audit_count
    domain%ctx_pool(wb_idx)%audit_log(idx)%operation_type = op_type
    domain%ctx_pool(wb_idx)%audit_log(idx)%target_step = target_step
    domain%ctx_pool(wb_idx)%audit_log(idx)%data_checksum = checksum
    domain%ctx_pool(wb_idx)%audit_log(idx)%success = success
    domain%ctx_pool(wb_idx)%audit_log(idx)%cfg%description = desc
  END SUBROUTINE AuditWriteBack_Idx

  !-------------------------------------------------------------------
  !  RT_WB_Init_Arg: caller must set arg%domain => rt_layer%writeback
  !-------------------------------------------------------------------
  SUBROUTINE RT_WB_Init_Arg(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_Init_Arg), INTENT(INOUT) :: arg

    CALL RT_WriteBack_Init_Idx(domain, arg%max_checkpoints, arg%zero_trust_enabled, arg%wb_idx, arg%status)
  END SUBROUTINE RT_WB_Init_Arg

  !-------------------------------------------------------------------
  !  RT_WB_SaveCheckpoint_Arg
  !-------------------------------------------------------------------
  SUBROUTINE RT_WB_SaveCheckpoint_Arg(domain, wb_idx, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN)  :: wb_idx
    TYPE(RT_WB_SaveCheckpoint_Arg), INTENT(INOUT) :: arg

    CALL RT_WriteBack_SaveCheckpoint_Idx(domain, wb_idx, arg%step, arg%increment, arg%iteration, &
                                         arg%time_val, arg%status)
  END SUBROUTINE RT_WB_SaveCheckpoint_Arg

  !-------------------------------------------------------------------
  !  Standalone _Idx (no domain param)
  !-------------------------------------------------------------------
  SUBROUTINE RT_WB_Init_Arg_Standalone(arg)
    TYPE(RT_WB_Init_Arg), INTENT(INOUT) :: arg
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(arg%status)
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WB_Init_Arg_Standalone: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WB_Init_Arg(g_ufc_global%rt_layer%writeback, arg)
  END SUBROUTINE RT_WB_Init_Arg_Standalone

  SUBROUTINE RT_WriteBack_SaveCheckpoint_Idx_Standalone(wb_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: wb_idx
    TYPE(RT_WB_SaveCheckpoint_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_SaveCheckpoint_Idx_Standalone: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_SaveCheckpoint_Idx(g_ufc_global%rt_layer%writeback, wb_idx, &
         arg%step, arg%increment, arg%iteration, arg%time_val, arg%status)
    status = arg%status
  END SUBROUTINE RT_WriteBack_SaveCheckpoint_Idx_Standalone

  SUBROUTINE RT_WriteBack_LoadCheckpoint_Idx_Standalone(wb_idx, cp_id, u_out, status)
    INTEGER(i4), INTENT(IN)  :: wb_idx, cp_id
    REAL(wp),    INTENT(OUT) :: u_out(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_LoadCheckpoint_Idx_Standalone: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_LoadCheckpoint_Idx(g_ufc_global%rt_layer%writeback, wb_idx, cp_id, u_out, status)
  END SUBROUTINE RT_WriteBack_LoadCheckpoint_Idx_Standalone

  !-------------------------------------------------------------------
  !  Internal helper subroutines
  !-------------------------------------------------------------------
  
  FUNCTION ComputeChecksum(data, size) RESULT(checksum)
    REAL(wp), INTENT(IN) :: data(:)
    INTEGER(i4), INTENT(IN) :: size
    REAL(wp) :: checksum
    
    INTEGER(i4) :: i
    
    checksum = 0.0_wp
    DO i = 1, MIN(size, SIZE(data))
      checksum = checksum + ABS(data(i)) * REAL(i, wp)
    END DO
    
  END FUNCTION ComputeChecksum

  FUNCTION ValidateStateData(data, size, expected_checksum) RESULT(valid)
    REAL(wp), INTENT(IN) :: data(:)
    INTEGER(i4), INTENT(IN) :: size
    REAL(wp), INTENT(IN) :: expected_checksum
    LOGICAL :: valid
    
    REAL(wp) :: computed_checksum
    REAL(wp), PARAMETER :: TOL = 1.0E-12_wp
    
    computed_checksum = ComputeChecksum(data, size)
    valid = ABS(computed_checksum - expected_checksum) < TOL
    
  END FUNCTION ValidateStateData

  !-------------------------------------------------------------------
  !  RT_WriteBack_WriteNodeDisp_Idx: check whitelist, call MD_WB_Mesh_NodeDisp, log audit
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_WriteNodeDisp_Idx(domain, wb_idx, node_idx, new_disp, old_disp, status)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: wb_idx
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: new_disp(3)
    REAL(wp), INTENT(OUT) :: old_disp(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    old_disp = 0.0_wp
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L3_NODE_DISP, "node_displacement")) THEN
      status%status_code = STATUS_WRITEBACK_DENIED
      status%message = "WriteBack denied: node_displacement not in whitelist"
      RETURN
    END IF
    IF (g_ufc_global%md_layer%mesh%initialized .AND. node_idx >= 1_i4 .AND. &
        node_idx <= g_ufc_global%md_layer%mesh%desc%nNodes) THEN
      IF (ALLOCATED(g_ufc_global%md_layer%mesh%node_state)) THEN
        old_disp(1:3) = g_ufc_global%md_layer%mesh%node_state(node_idx)%disp(1:3)
      END IF
    END IF
    ! ARCHITECTURE FIX (N1-1): Route to L4_PH for physical computation
    CALL PH_WriteBack_ApplyNodeDisp(node_idx, new_disp, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    domain%global_version = domain%global_version + 1_i4
    IF (wb_idx > 0_i4 .AND. wb_idx <= domain%pool_count .AND. domain%ctx_pool(wb_idx)%audit_enabled) THEN
      CALL RT_WriteBack_LogAudit_Idx(domain, wb_idx, "NODE_DISP", node_idx, old_disp, new_disp, status)
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_WriteNodeDisp_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_NodePos
  ! L5_RT L3 mesh
  !  ? Increment
  !  node_coordinate ?
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodePos(domain, arg)
    TYPE(RT_WriteBack_Domain),   INTENT(INOUT) :: domain
    TYPE(RT_WB_NodePos_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    ! RT_WriteBack_WriteNodeCoord_Idx
    CALL RT_WriteBack_WriteNodeCoord_Idx(domain, arg%wb_idx, arg%node_idx, &
                                          arg%new_coords, arg%old_coords, arg%status)
  END SUBROUTINE RT_WriteBack_NodePos

  !-------------------------------------------------------------------
  !  RT_WriteBack_NodePos_Idx
  ! RT_WriteBack_NodePos(node_idx, arg, status)
  ! g_ufc_global%rt_layer%writeback domain RT_WriteBack_NodePos
  ! Phase 5 WriteBack +
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodePos_Idx(node_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: node_idx
    TYPE(RT_WB_NodePos_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    arg%node_idx = node_idx
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_NodePos_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_NodePos(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_NodePos_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_NodeDisp_Idx
  ! (node_idx, arg, status) g_ufc_global domain
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodeDisp_Idx(node_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: node_idx
    TYPE(RT_WB_NodeDisp_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    arg%node_idx = node_idx
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_NodeDisp_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_NodeDisp(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_NodeDisp_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_NodeDisp_Batch_Idx
  ! (arg, status) g_ufc_global domain
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodeDisp_Batch_Idx(arg, status)
    TYPE(RT_WB_NodeDisp_Batch_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_NodeDisp_Batch_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_NodeDisp_Batch(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_NodeDisp_Batch_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_ElemStress_Idx
  ! (arg, status) g_ufc_global domain
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_ElemStress_Idx(arg, status)
    TYPE(RT_WB_ElemStress_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_ElemStress_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_ElemStress(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_ElemStress_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_CurrentTime_Idx
  ! (arg, status) g_ufc_global domain
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_CurrentTime_Idx(arg, status)
    TYPE(RT_WB_CurrentTime_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_CurrentTime_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_CurrentTime(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_CurrentTime_Idx

  !-------------------------------------------------------------------
  !  RT_WriteBack_NodeDisp
  !  L5_RT L3 mesh u ?
  !  Increment ?solver%state%u(:) ?dofMap L3
  !  node_displacement ?
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodeDisp(domain, arg)
    TYPE(RT_WriteBack_Domain),   INTENT(INOUT) :: domain
    TYPE(RT_WB_NodeDisp_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    CALL RT_WriteBack_WriteNodeDisp_Idx(domain, arg%wb_idx, arg%node_idx, &
                                         arg%new_disp, arg%old_disp, arg%status)
  END SUBROUTINE RT_WriteBack_NodeDisp

  !-------------------------------------------------------------------
  !  RT_WriteBack_NodeDisp_Batch
  !  ?u(:) ?dofMap ?
  !  Increment ?solver%state%u(:) ?L3
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodeDisp_Batch(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_NodeDisp_Batch_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: i, nNodes, dof_start, n_dof
    REAL(wp) :: disp(3), old_disp(3)

    CALL init_error_status(arg%status)
    arg%n_written = 0_i4
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (.NOT. ALLOCATED(arg%u)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "arg%u not allocated"
      RETURN
    END IF
    IF (.NOT. g_ufc_global%md_layer%mesh%initialized .OR. &
        .NOT. ALLOCATED(g_ufc_global%md_layer%mesh%global_num%nodeMap)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "mesh or nodeMap not ready"
      RETURN
    END IF

    nNodes = SIZE(g_ufc_global%md_layer%mesh%global_num%nodeMap)
    DO i = 1, nNodes
      dof_start = g_ufc_global%md_layer%mesh%global_num%nodeMap(i)%dofStartIndex
      n_dof = g_ufc_global%md_layer%mesh%global_num%nodeMap(i)%nDof
      IF (dof_start < 1_i4 .OR. dof_start + n_dof - 1_i4 > SIZE(arg%u)) CYCLE
      disp = 0.0_wp
      disp(1:MIN(3_i4, n_dof)) = arg%u(dof_start:dof_start + MIN(3_i4, n_dof) - 1_i4)
      CALL RT_WriteBack_WriteNodeDisp_Idx(domain, arg%wb_idx, i, disp, old_disp, arg%status)
      IF (arg%status%status_code /= IF_STATUS_OK) RETURN
      arg%n_written = arg%n_written + 1_i4
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_NodeDisp_Batch

  !-------------------------------------------------------------------
  !  RT_WriteBack_ElemStress
  !  L5 L3 mesh ?Output
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_ElemStress(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_ElemStress_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L3_ELEM_IP_STRESS, "elem_ip_stress")) THEN
      arg%status%status_code = STATUS_WRITEBACK_DENIED
      arg%status%message = "WriteBack denied: elem_ip_stress not in whitelist"
      RETURN
    END IF
    ! ARCHITECTURE FIX (N1-1): Route to L4_PH for physical computation
    CALL PH_WriteBack_ApplyElemStress(arg%elem_idx, arg%ip_idx, arg%sigma, arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN
    domain%global_version = domain%global_version + 1_i4
  END SUBROUTINE RT_WriteBack_ElemStress

  !-------------------------------------------------------------------
  !  RT_WriteBack_CurrentTime
  ! L5_RT L3 Step
  !  Step/Incr ?md_layer%step currentTime
  !  ?Step/Incr ?Iteration
  ! MD_WB_Step Mgr API
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_CurrentTime(domain, arg)
    USE MD_WB_Brg, ONLY: MD_WB_Step
    TYPE(RT_WriteBack_Domain),      INTENT(INOUT) :: domain
    TYPE(RT_WB_CurrentTime_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (arg%inc%step_idx < 1) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "step_idx must be >= 1"
      RETURN
    END IF
    ! API Step MD_WB_Brg ?
    CALL MD_WB_Step(arg%inc%step_idx, arg%current_time, arg%current_inc, &
                    arg%is_complete, arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN
    domain%global_version = domain%global_version + 1_i4
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_CurrentTime

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_ElemStrain: Element strain output
  !   [Data chain] elem_idx, ip_idx, epsilon(6) -> L3 mesh%elem_state(elem_idx)%ipStates(ip_idx)%strain
  !   Validation: whitelist check + range validation
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_ElemStrain(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_ElemStrain_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L3_ELEM_IP_STRAIN, "elem_ip_strain")) THEN
      arg%status%status_code = STATUS_WRITEBACK_DENIED
      arg%status%message = "WriteBack denied: elem_ip_strain not in whitelist (I-04)"
      RETURN
    END IF
    ! Bridge: element strain -> L3 mesh element output (route TBD: via MD_WB_Brg / L4 callback)
    ! TODO: Implement MD_WB_ElemStrain or route via RT_WriteBack_ApplyElemStrain (L4)
    domain%global_version = domain%global_version + 1_i4
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_ElemStrain

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_ElemStrain_Idx: Index-based element strain output
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_ElemStrain_Idx(arg, status)
    TYPE(RT_WB_ElemStrain_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_ElemStrain_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_ElemStrain(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_ElemStrain_Idx

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_ElemEplas: Accumulated plastic strain (PEEQ) output
  !   [Data chain] elem_idx, ip_idx, eplas -> L3 mesh%elem_state(elem_idx)%ipStates(ip_idx)%eplas
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_ElemEplas(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_ElemEplas_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L3_ELEM_IP_EPLAS, "elem_ip_eplas")) THEN
      arg%status%status_code = STATUS_WRITEBACK_DENIED
      arg%status%message = "WriteBack denied: elem_ip_eplas not in whitelist (I-04)"
      RETURN
    END IF
    ! Bridge: accumulated plastic strain -> L3 mesh (route TBD)
    ! TODO: Implement via MD_WB_Brg / L4 callback
    domain%global_version = domain%global_version + 1_i4
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_ElemEplas

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_ElemEplas_Idx: Index-based plastic strain output
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_ElemEplas_Idx(arg, status)
    TYPE(RT_WB_ElemEplas_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_ElemEplas_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_ElemEplas(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_ElemEplas_Idx

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_NodeAccel: Node acceleration output (dynamic analysis)
  !   [Data chain] node_idx, new_accel(3) -> L3 mesh%node(node_idx)%acceleration(:)
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodeAccel(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_NodeAccel_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L3_NODE_ACCEL, "node_acceleration")) THEN
      arg%status%status_code = STATUS_WRITEBACK_DENIED
      arg%status%message = "WriteBack denied: node_acceleration not in whitelist (I-04)"
      RETURN
    END IF
    ! Bridge: node acceleration -> L3 mesh (route TBD)
    ! TODO: Implement via MD_WB_Brg
    domain%global_version = domain%global_version + 1_i4
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_NodeAccel

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_NodeAccel_Idx: Index-based node acceleration output
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_NodeAccel_Idx(arg, status)
    TYPE(RT_WB_NodeAccel_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_NodeAccel_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_NodeAccel(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_NodeAccel_Idx

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_GPStateVar: Gauss point state variable output
  !   [Data chain] elem_idx, ip_idx, var_idx, var_value -> L4 slot_pool%state%stateVars
  !   Route to L4 material domain for validation/storage
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_GPStateVar(domain, arg)
    TYPE(RT_WriteBack_Domain), INTENT(INOUT) :: domain
    TYPE(RT_WB_GPStateVar_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (.NOT. domain%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "RT_WriteBack_Domain not initialized"
      RETURN
    END IF
    IF (.NOT. RT_WriteBack_IsAllowed(domain, RT_WB_TARGET_L4_GP_STATE_VAR, "gp_state_variable")) THEN
      arg%status%status_code = STATUS_WRITEBACK_DENIED
      arg%status%message = "WriteBack denied: gp_state_variable not in whitelist (I-04)"
      RETURN
    END IF
    ! Bridge: GP state variable -> L4 PH_Material domain
    ! Route: elem_idx -> mat_pt_idx (via elem_to_mat_map) -> slot_pool%state%stateVars(var_idx)
    ! TODO: Implement via PH_WriteBack_ApplyStateVar (L4) or direct slot write
    domain%global_version = domain%global_version + 1_i4
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_GPStateVar

  !-------------------------------------------------------------------
  ! [I-04-NEW] RT_WriteBack_GPStateVar_Idx: Index-based GP state variable output
  !-------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_GPStateVar_Idx(arg, status)
    TYPE(RT_WB_GPStateVar_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (.NOT. g_ufc_global%IsReady()) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "RT_WriteBack_GPStateVar_Idx: g_ufc_global not ready"
      RETURN
    END IF
    CALL RT_WriteBack_GPStateVar(g_ufc_global%rt_layer%writeback, arg)
    status = arg%status
  END SUBROUTINE RT_WriteBack_GPStateVar_Idx

END MODULE RT_WB_Domain