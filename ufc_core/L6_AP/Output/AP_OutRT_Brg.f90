!======================================================================
! Module: AP_OutRT_Brg
! Layer:  L6_AP - Application Layer
! Domain: Output / Bridge
! Purpose: Bridge AP_Output_Domain <-> RT_Output_Domain (L5_RT).
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE AP_OutRT_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Out_Def,       ONLY: OutputRequestEntry, AP_OUTPUT_REQ_FIELD, AP_OUTPUT_REQ_HISTORY
  USE AP_Out_Domain,         ONLY: AP_Output_Domain
  USE MD_Out_API, ONLY: MD_Output_Domain, MD_OutputRequest_Desc, OUT_FIELD, OUT_HISTORY
  USE MD_Out_Def,       ONLY: FldOutReq, HistOutReq, &
       OUT_REGION_ALL, OUT_REGION_NSET, OUT_REGION_ELSET, &
       OUT_LOC_NODE, OUT_LOC_ELEM_CENTROID, OUT_FREQ_INCREMENT, &
       OUT_VAR_U, OUT_VAR_S, OUT_VAR_E, OUT_VAR_PEEQ, OUT_VAR_RF, OUT_VAR_TEMP, &
       OUT_VAR_V, OUT_VAR_A, OUT_VAR_CF, OUT_VAR_MISES, OUT_VAR_PE, OUT_VAR_EE, &
       OUT_VAR_ALLIE, OUT_VAR_ALLKE, OUT_VAR_ALLPD, OUT_VAR_ALLSE
  USE RT_Out_Mgr,           ONLY: RT_Out_Cfg
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Out_SyncToRT
  PUBLIC :: AP_Out_EntryToFldReq
  PUBLIC :: AP_Out_EntryToHistReq

CONTAINS

  !====================================================================
  ! AP_Out_SyncToRT
  ! Sync output requests to RT_Out_Cfg. Prefers md_layer%output (single source).
  !====================================================================
  SUBROUTINE AP_Out_SyncToRT(ap_domain, rt_cfg, status)
    TYPE(AP_Output_Domain), INTENT(IN)    :: ap_domain
    TYPE(RT_Out_Cfg),      INTENT(INOUT) :: rt_cfg
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(OutputRequestEntry) :: entry
    TYPE(MD_OutputRequest_Desc) :: desc
    TYPE(FldOutReq)          :: fld_req
    TYPE(HistOutReq)         :: hist_req
    INTEGER(i4)              :: i, j, n
    CHARACTER(LEN=256)       :: var_str

    CALL init_error_status(status)
    IF (.NOT. ap_domain%initialized) RETURN

    ! Prefer md_layer%output (single source, index tree + flat domain)
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%output%initialized .AND. &
        g_ufc_global%md_layer%output%n_requests > 0_i4) THEN
      n = g_ufc_global%md_layer%output%n_requests
      DO i = 1, n
        CALL g_ufc_global%md_layer%output%GetRequest(i, desc, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        var_str = ""
        IF (desc%n_variables > 0) THEN
          var_str = TRIM(desc%variables(1))
          DO j = 2, MIN(desc%n_variables, 32)
            var_str = TRIM(var_str) // "," // TRIM(desc%variables(j))
          END DO
        END IF
        IF (LEN_TRIM(var_str) == 0) var_str = "PRESELECT"
        entry%req_type = MERGE(AP_OUTPUT_REQ_FIELD, AP_OUTPUT_REQ_HISTORY, desc%request_type == OUT_FIELD)
        entry%name = desc%name
        entry%region = desc%target_set
        entry%position = 0_i4
        entry%frequency = desc%frequency
        entry%variable_str = var_str
        entry%step_id = desc%step_ref
        IF (entry%req_type == AP_OUTPUT_REQ_FIELD) THEN
          CALL AP_Out_EntryToFldReq(entry, fld_req, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
          CALL rt_cfg%AddFieldRequest(fld_req, status)
        ELSE
          CALL AP_Out_EntryToHistReq(entry, hist_req, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
          CALL rt_cfg%AddHistoryRequest(hist_req, status)
        END IF
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END DO
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Fallback: ap_domain local storage
    n = ap_domain%GetRequestCount()
    IF (n <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    DO i = 1, n
      entry = ap_domain%output_requests(i)
      IF (entry%req_type == AP_OUTPUT_REQ_FIELD) THEN
        CALL AP_Out_EntryToFldReq(entry, fld_req, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        CALL rt_cfg%AddFieldRequest(fld_req, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      ELSE IF (entry%req_type == AP_OUTPUT_REQ_HISTORY) THEN
        CALL AP_Out_EntryToHistReq(entry, hist_req, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        CALL rt_cfg%AddHistoryRequest(hist_req, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Out_SyncToRT

  !====================================================================
  ! AP_Out_EntryToFldReq
  ! Convert OutputRequestEntry (FIELD) -> FldOutReq
  !====================================================================
  SUBROUTINE AP_Out_EntryToFldReq(entry, fld_req, status)
    TYPE(OutputRequestEntry), INTENT(IN)  :: entry
    TYPE(FldOutReq),          INTENT(OUT) :: fld_req
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    INTEGER(i4) :: pos, reg_type
    INTEGER(i4), ALLOCATABLE :: var_ids(:)
    INTEGER(i4) :: j

    CALL init_error_status(status)
    CALL fld_req%Clear()

    pos = entry%position
    IF (pos <= 0) pos = OUT_LOC_ELEM_CENTROID

    reg_type = OUT_REGION_ALL
    IF (LEN_TRIM(entry%region) > 0) reg_type = OUT_REGION_NSET

    CALL fld_req%Init(name=TRIM(entry%name), region_name=TRIM(entry%region), &
         region_type=reg_type, position=pos, frequency=entry%frequency, &
         frequency_type=OUT_FREQ_INCREMENT)
    fld_req%step_id = entry%step_id

    CALL AP_Out_ParseVariableStr(entry%variable_str, var_ids)
    IF (ALLOCATED(var_ids)) THEN
      DO j = 1, SIZE(var_ids)
        IF (var_ids(j) /= 0_i4) CALL fld_req%AddVariable(var_ids(j))
      END DO
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Out_EntryToFldReq

  !====================================================================
  ! AP_Out_EntryToHistReq
  ! Convert OutputRequestEntry (HISTORY) -> HistOutReq
  !====================================================================
  SUBROUTINE AP_Out_EntryToHistReq(entry, hist_req, status)
    TYPE(OutputRequestEntry), INTENT(IN)  :: entry
    TYPE(HistOutReq),         INTENT(OUT) :: hist_req
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: reg_type
    INTEGER(i4), ALLOCATABLE :: var_ids(:)
    INTEGER(i4) :: j

    CALL init_error_status(status)
    CALL hist_req%Clear()

    reg_type = OUT_REGION_ALL
    IF (LEN_TRIM(entry%region) > 0) reg_type = OUT_REGION_NSET

    CALL hist_req%Init(name=TRIM(entry%name), region_name=TRIM(entry%region), &
         region_type=reg_type, frequency=entry%frequency, &
         frequency_type=OUT_FREQ_INCREMENT)
    hist_req%step_id = entry%step_id

    CALL AP_Out_ParseVariableStr(entry%variable_str, var_ids)
    IF (ALLOCATED(var_ids)) THEN
      DO j = 1, SIZE(var_ids)
        IF (var_ids(j) /= 0_i4) CALL hist_req%AddVariable(var_ids(j))
      END DO
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Out_EntryToHistReq

  !====================================================================
  ! AP_Out_ParseVariableStr (internal)
  ! Map variable_str (PRESELECT, U, S, U,S,PEEQ) -> var_ids
  !====================================================================
  SUBROUTINE AP_Out_ParseVariableStr(variable_str, var_ids)
    CHARACTER(LEN=*),              INTENT(IN)  :: variable_str
    INTEGER(i4), ALLOCATABLE,      INTENT(OUT) :: var_ids(:)

    CHARACTER(LEN=32) :: tok, up
    INTEGER(i4)      :: i, j, n, start, len_str
    INTEGER(i4)      :: var_id

    IF (ALLOCATED(var_ids)) DEALLOCATE(var_ids)
    len_str = LEN_TRIM(variable_str)
    IF (len_str <= 0) RETURN

    up = variable_str
    CALL ToUpper(up)

    IF (TRIM(up) == 'PRESELECT' .OR. TRIM(up) == 'ALL') THEN
      ALLOCATE(var_ids(6))
      var_ids(1) = OUT_VAR_U
      var_ids(2) = OUT_VAR_S
      var_ids(3) = OUT_VAR_E
      var_ids(4) = OUT_VAR_PEEQ
      var_ids(5) = OUT_VAR_RF
      var_ids(6) = OUT_VAR_TEMP
      RETURN
    END IF

    n = 0
    DO i = 1, len_str + 1
      IF (i > len_str .OR. variable_str(i:i) == ',' .OR. variable_str(i:i) == ' ') THEN
        IF (i > 1 .AND. variable_str(i-1:i-1) /= ',' .AND. variable_str(i-1:i-1) /= ' ') THEN
          n = n + 1
        END IF
      END IF
    END DO
    IF (n <= 0) RETURN

    ALLOCATE(var_ids(n))
    n = 0
    start = 1
    DO i = 1, len_str + 1
      IF (i > len_str .OR. variable_str(i:i) == ',' .OR. variable_str(i:i) == ' ') THEN
        IF (i > start) THEN
          tok = variable_str(start:i-1)
          CALL ToUpper(tok)
          var_id = VarNameToId(TRIM(tok))
          IF (var_id /= 0_i4) THEN
            n = n + 1
            var_ids(n) = var_id
          END IF
        END IF
        start = i + 1
      END IF
    END DO
  END SUBROUTINE AP_Out_ParseVariableStr

  PURE FUNCTION VarNameToId(name) RESULT(id)
    CHARACTER(LEN=*), INTENT(IN) :: name
    INTEGER(i4) :: id
    id = 0_i4
    SELECT CASE (TRIM(name))
    CASE ('U')   ; id = OUT_VAR_U
    CASE ('S')   ; id = OUT_VAR_S
    CASE ('E')   ; id = OUT_VAR_E
    CASE ('PEEQ'); id = OUT_VAR_PEEQ
    CASE ('RF')  ; id = OUT_VAR_RF
    CASE ('TEMP'); id = OUT_VAR_TEMP
    CASE ('V')   ; id = OUT_VAR_V
    CASE ('A')   ; id = OUT_VAR_A
    CASE ('CF')  ; id = OUT_VAR_CF
    CASE ('MISES'); id = OUT_VAR_MISES
    CASE ('PE')  ; id = OUT_VAR_PE
    CASE ('EE')  ; id = OUT_VAR_EE
    CASE ('ALLIE'); id = OUT_VAR_ALLIE
    CASE ('ALLKE'); id = OUT_VAR_ALLKE
    CASE ('ALLPD'); id = OUT_VAR_ALLPD
    CASE ('ALLSE'); id = OUT_VAR_ALLSE
    END SELECT
  END FUNCTION VarNameToId

  SUBROUTINE ToUpper(s)
    CHARACTER(LEN=*), INTENT(INOUT) :: s
    INTEGER(i4) :: i, c
    DO i = 1, LEN(s)
      c = IACHAR(s(i:i))
      IF (c >= IACHAR('a') .AND. c <= IACHAR('z')) &
           s(i:i) = ACHAR(c - 32)
    END DO
  END SUBROUTINE ToUpper

END MODULE AP_OutRT_Brg
