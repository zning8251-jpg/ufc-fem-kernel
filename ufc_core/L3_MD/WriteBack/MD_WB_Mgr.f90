!===============================================================================
! MODULE: MD_WB_Mgr
! LAYER:  L3_MD
! DOMAIN: WriteBack
! ROLE:   Mgr — WriteBack whitelist management
! BRIEF:  Init/Register/IsAllowed/Finalize for write-back whitelist.
!===============================================================================
!
! Procedures:
!   [P0] Init_WriteBack_WhiteList / Finalize_WriteBack_WhiteList
!   [P0] Register_WriteBack_Field
!   [P0] Is_WriteBack_Allowed  (Query)
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:WB | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | WriteBack/CONTRACT.md

MODULE MD_WB_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Log_Logger, ONLY: IF_Log_Info, IF_Log_Warning
  USE MD_WB_Def,     ONLY: MD_WriteBack_Entry, WB_DOMAIN_STEP, WB_DOMAIN_AMPLITUDE, &
                                    WB_DOMAIN_LOADBC, WB_DOMAIN_MESH, WB_DOMAIN_MODEL, &
                                    WB_DOMAIN_INTERACTION, WB_DOMAIN_OUTPUT, &
                                    WB_DOMAIN_ASSEMBLY, WB_DOMAIN_CONSTRAINT, &
                                    WB_DOMAIN_MATERIAL, WB_DOMAIN_SECTION
  USE MD_WB_Domain, ONLY: MD_WriteBack_WhiteListDomain
  IMPLICIT NONE
  PRIVATE

  ! Backward-compatible API
  PUBLIC :: Init_WriteBack_WhiteList
  PUBLIC :: Is_WriteBack_Allowed
  PUBLIC :: Register_WriteBack_Field
  PUBLIC :: Finalize_WriteBack_WhiteList

  ! Module-level domain (flat storage)
  TYPE(MD_WriteBack_WhiteListDomain), SAVE :: g_wb_domain
  LOGICAL, SAVE :: g_whitelist_initialized = .FALSE.

  INTEGER(i4), SAVE :: g_writeback_attempts = 0_i4
  INTEGER(i4), SAVE :: g_writeback_allowed  = 0_i4
  INTEGER(i4), SAVE :: g_writeback_denied   = 0_i4

CONTAINS

  SUBROUTINE Init_WriteBack_WhiteList(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (g_whitelist_initialized) RETURN

    CALL g_wb_domain%Init(200_i4, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === MESH domain ===
    CALL Register_WriteBack_Field("mesh", "currentDOF",       .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("mesh", "node_coordinate",  .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("mesh", "currentNodeDisp",  .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("mesh", "elem_ip_stress",  .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("mesh", "currentNodeVel",   .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("mesh", "currentNodeAcc",   .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === STEP domain ===
    CALL Register_WriteBack_Field("step", "currentTime",      .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("step", "currentStepInc",   .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("step", "currentStepIter",  .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("step", "is_complete",      .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === LOADBC domain ===
    CALL Register_WriteBack_Field("loadbc", "currentLoadScale", .TRUE., .TRUE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("loadbc", "currentBCValue",   .TRUE., .TRUE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === AMPLITUDE domain ===
    CALL Register_WriteBack_Field("amplitude", "currentValue",  .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === INTERACTION domain ===
    CALL Register_WriteBack_Field("interaction", "isActive",           .TRUE., .TRUE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("interaction", "currentContactStatus",.TRUE., .TRUE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === OUTPUT domain ===
    CALL Register_WriteBack_Field("output", "lastWrittenInc",  .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === MODEL domain ===
    CALL Register_WriteBack_Field("model", "isBuilt",          .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("model", "build_timestamp",  .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === ASSEMBLY domain ===
    CALL Register_WriteBack_Field("assembly", "isAssembled",    .TRUE., .FALSE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === CONSTRAINT domain ===
    CALL Register_WriteBack_Field("constraint", "isActive",     .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === MATERIAL domain ===
    CALL Register_WriteBack_Field("material", "state_vars",     .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL Register_WriteBack_Field("material", "stress",         .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! === SECTION domain ===
    CALL Register_WriteBack_Field("section", "thickness",       .TRUE., .TRUE.,  status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    g_whitelist_initialized = .TRUE.
    CALL IF_Log_Info("WriteBack whitelist initialized (Domain)")
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init_WriteBack_WhiteList

  SUBROUTINE Register_WriteBack_Field(domain_name, field_name, is_active, &
                                       requires_lock, status)
    CHARACTER(LEN=*),      INTENT(IN)  :: domain_name, field_name
    LOGICAL,               INTENT(IN)  :: is_active, requires_lock
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: domain_id

    CALL init_error_status(status)
    domain_id = 0_i4
    IF (TRIM(domain_name) == "mesh")        domain_id = WB_DOMAIN_MESH
    IF (TRIM(domain_name) == "step")        domain_id = WB_DOMAIN_STEP
    IF (TRIM(domain_name) == "loadbc")      domain_id = WB_DOMAIN_LOADBC
    IF (TRIM(domain_name) == "amplitude")   domain_id = WB_DOMAIN_AMPLITUDE
    IF (TRIM(domain_name) == "interaction") domain_id = WB_DOMAIN_INTERACTION
    IF (TRIM(domain_name) == "output")      domain_id = WB_DOMAIN_OUTPUT
    IF (TRIM(domain_name) == "model")       domain_id = WB_DOMAIN_MODEL
    IF (TRIM(domain_name) == "assembly")    domain_id = WB_DOMAIN_ASSEMBLY
    IF (TRIM(domain_name) == "constraint")  domain_id = WB_DOMAIN_CONSTRAINT
    IF (TRIM(domain_name) == "material")    domain_id = WB_DOMAIN_MATERIAL
    IF (TRIM(domain_name) == "section")     domain_id = WB_DOMAIN_SECTION

    CALL g_wb_domain%AddEntry(domain_name, field_name, domain_id, &
                              is_active, requires_lock, status)
  END SUBROUTINE Register_WriteBack_Field

  FUNCTION Is_WriteBack_Allowed(domain_name, field_name) RESULT(is_allowed)
    CHARACTER(LEN=*), INTENT(IN) :: domain_name, field_name
    LOGICAL :: is_allowed

    g_writeback_attempts = g_writeback_attempts + 1_i4
    is_allowed = g_wb_domain%IsAllowed(domain_name, field_name)
    IF (is_allowed) THEN
      g_writeback_allowed = g_writeback_allowed + 1_i4
    ELSE
      g_writeback_denied = g_writeback_denied + 1_i4
      CALL IF_Log_Warning("WriteBack denied: " // TRIM(domain_name) // "." // TRIM(field_name))
    END IF
  END FUNCTION Is_WriteBack_Allowed

  SUBROUTINE Finalize_WriteBack_WhiteList()
    CHARACTER(LEN=80) :: buf

    CALL g_wb_domain%Finalize()
    WRITE(buf,'(A,I0,A,I0,A,I0)') &
      "WB whitelist stats: attempts=", g_writeback_attempts, &
      " allowed=", g_writeback_allowed, &
      " denied=",  g_writeback_denied
    CALL IF_Log_Info(TRIM(buf))

    g_whitelist_initialized = .FALSE.
    g_writeback_attempts    = 0_i4
    g_writeback_allowed     = 0_i4
    g_writeback_denied      = 0_i4
  END SUBROUTINE Finalize_WriteBack_WhiteList

END MODULE MD_WB_Mgr