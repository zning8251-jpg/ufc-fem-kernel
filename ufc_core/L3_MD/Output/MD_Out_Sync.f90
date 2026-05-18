!======================================================================
! Module: MD_OutSync
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Sync
! Purpose: Sync legacy UF_ModelDef output data to MD_Output_Domain.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================

MODULE MD_Out_Sync
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Out_API, ONLY: MD_Output_Domain, MD_OutputRequest_Desc, &
       OUT_FIELD, OUT_HISTORY, FMT_ODB
  USE MD_Step_Mgr,   ONLY: MD_Step_Domain, MD_Step_Desc
  USE MD_Model_Lib_Core,         ONLY: UF_ModelDef
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE MD_Out_Lib,           ONLY: UF_FieldOutputDef, UF_HistoryOutputDef, UF_OutputManager
  USE MD_Out_Def,          ONLY: MD_OutCtrl_Type, MD_FieldOut_Type, MD_HistOut_Type, &
       MD_OutVariable_Type, MD_OutFrequency_Type, OUT_FREQ_INTERVAL, OUT_FREQ_TIMEPOINTS, &
       MD_OutCtrl_Init, MD_OutCtrl_Free, MD_OutCtrl_AddFieldOut, MD_OutCtrl_AddHistOut
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Output_SyncFromLegacy
  PUBLIC :: MD_OutCtrl_PopulateFromDomain

CONTAINS

  !====================================================================
  ! MD_Output_SyncFromLegacy
  ! Sync step%output (legacy) -> output domain + step%output_ids
  !====================================================================
  SUBROUTINE MD_Output_SyncFromLegacy(model_def, md_layer, status)
    TYPE(UF_ModelDef),           INTENT(IN)    :: model_def
    TYPE(MD_L3_LayerContainer),  INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: n_steps, s, i, req_id
    TYPE(MD_OutputRequest_Desc) :: req_desc

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_OutSync: md_layer not initialized"
      RETURN
    END IF

    n_steps = model_def%step_mgr%num_steps
    IF (n_steps <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Sync each step's output -> Domain + step%output_ids
    DO s = 1, n_steps
      ! Field outputs
      IF (ALLOCATED(model_def%step_mgr%steps(s)%output%fields)) THEN
        DO i = 1, model_def%step_mgr%steps(s)%output%num_field
          IF (i > SIZE(model_def%step_mgr%steps(s)%output%fields)) EXIT
          CALL UF_FieldOutputDef_To_MD_OutputRequest_Desc( &
               model_def%step_mgr%steps(s)%output%fields(i), s, req_desc)
          CALL md_layer%output%AddRequest(req_desc, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
          req_id = md_layer%output%n_requests
          CALL md_layer%step%AddOutputId(s, req_id, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO
      END IF

      ! History outputs
      IF (ALLOCATED(model_def%step_mgr%steps(s)%output%histories)) THEN
        DO i = 1, model_def%step_mgr%steps(s)%output%num_history
          IF (i > SIZE(model_def%step_mgr%steps(s)%output%histories)) EXIT
          CALL UF_HistoryOutputDef_To_MD_OutputRequest_Desc( &
               model_def%step_mgr%steps(s)%output%histories(i), s, req_desc)
          CALL md_layer%output%AddRequest(req_desc, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
          req_id = md_layer%output%n_requests
          CALL md_layer%step%AddOutputId(s, req_id, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Output_SyncFromLegacy

  !====================================================================
  ! Conversion helpers: UF_* -> MD_OutputRequest_Desc
  !====================================================================
  SUBROUTINE UF_FieldOutputDef_To_MD_OutputRequest_Desc(uf_fld, step_ref, desc)
    TYPE(UF_FieldOutputDef), INTENT(IN)  :: uf_fld
    INTEGER(i4),             INTENT(IN)  :: step_ref
    TYPE(MD_OutputRequest_Desc), INTENT(OUT) :: desc

    INTEGER(i4) :: k, nv

    desc%name         = uf_fld%name
    desc%request_type = OUT_FIELD
    desc%target_set   = uf_fld%region_name
    desc%frequency    = MAX(1_i4, uf_fld%frequency)
    desc%time_interval = MERGE(REAL(uf_fld%time_interval, wp), 0.0_wp, uf_fld%time_interval > 0_i4)
    desc%format       = FMT_ODB
    desc%step_ref     = step_ref
    desc%n_variables  = MIN(32_i4, uf_fld%num_variables)
    desc%variables    = ""
    DO k = 1, desc%n_variables
      desc%variables(k) = VarIdToName(uf_fld%variables(k))
    END DO
  END SUBROUTINE UF_FieldOutputDef_To_MD_OutputRequest_Desc

  SUBROUTINE UF_HistoryOutputDef_To_MD_OutputRequest_Desc(uf_hist, step_ref, desc)
    TYPE(UF_HistoryOutputDef), INTENT(IN)  :: uf_hist
    INTEGER(i4),               INTENT(IN)  :: step_ref
    TYPE(MD_OutputRequest_Desc), INTENT(OUT) :: desc

    INTEGER(i4) :: k

    desc%name         = uf_hist%name
    desc%request_type = OUT_HISTORY
    desc%target_set   = uf_hist%region_name
    desc%frequency    = MAX(1_i4, uf_hist%frequency)
    desc%time_interval = 0.0_wp
    desc%format       = FMT_ODB
    desc%step_ref     = step_ref
    desc%n_variables  = MIN(32_i4, uf_hist%num_variables)
    desc%variables    = ""
    DO k = 1, desc%n_variables
      desc%variables(k) = VarIdToName(uf_hist%variables(k))
    END DO
  END SUBROUTINE UF_HistoryOutputDef_To_MD_OutputRequest_Desc

  !====================================================================
  ! MD_OutCtrl_PopulateFromDomain
  ! Bridge: Domain -> MD_OutCtrl (for legacy MD_Out_Brg / L5_RT compatibility)
  ! Design: OUTPUT_DOMAIN_DESIGN.md Phase B - FldOutReq/HistOutReq from Domain
  ! @deprecated Prefer MD_Out_Brg_BuildFieldOutTasks_Select / BuildHistOutTasks_Select
  !   which use Domain directly when g_ufc_global%IsReady() and output initialized.
  !====================================================================
  SUBROUTINE MD_OutCtrl_PopulateFromDomain(ctrl, output_domain, step_domain, status)
    TYPE(MD_OutCtrl_Type),      INTENT(INOUT) :: ctrl
    TYPE(MD_Output_Domain),     INTENT(IN)    :: output_domain
    TYPE(MD_Step_Domain),       INTENT(IN)    :: step_domain
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: s, i, req_id, n_steps
    TYPE(MD_OutputRequest_Desc) :: req
    TYPE(MD_FieldOut_Type) :: fld_out
    TYPE(MD_HistOut_Type) :: hist_out

    CALL init_error_status(status)
    CALL MD_OutCtrl_Free(ctrl)
    CALL MD_OutCtrl_Init(ctrl)

    IF (.NOT. output_domain%initialized .OR. .NOT. step_domain%initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    n_steps = step_domain%n_steps
    IF (n_steps <= 0 .OR. .NOT. ALLOCATED(step_domain%steps)) RETURN

    DO s = 1, n_steps
      IF (.NOT. ALLOCATED(step_domain%steps(s)%output_ids)) CYCLE
      DO i = 1, SIZE(step_domain%steps(s)%output_ids)
        req_id = step_domain%steps(s)%output_ids(i)
        IF (req_id < 1 .OR. req_id > output_domain%n_requests) CYCLE
        req = output_domain%requests(req_id)

        IF (req%request_type == OUT_FIELD) THEN
          CALL MD_OutputRequest_Desc_To_MD_FieldOut_Type(req, s, fld_out)
          CALL MD_OutCtrl_AddFieldOut(ctrl, fld_out)
        ELSE IF (req%request_type == OUT_HISTORY) THEN
          CALL MD_OutputRequest_Desc_To_MD_HistOut_Type(req, s, hist_out)
          CALL MD_OutCtrl_AddHistOut(ctrl, hist_out)
        END IF
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_OutCtrl_PopulateFromDomain

  !--------------------------------------------------------------------
  ! Conversion: MD_OutputRequest_Desc -> MD_FieldOut_Type / MD_HistOut_Type
  !--------------------------------------------------------------------
  SUBROUTINE MD_OutputRequest_Desc_To_MD_FieldOut_Type(desc, step_ref, fld_out)
    TYPE(MD_OutputRequest_Desc), INTENT(IN)  :: desc
    INTEGER(i4),                 INTENT(IN)  :: step_ref
    TYPE(MD_FieldOut_Type),      INTENT(OUT) :: fld_out

    INTEGER(i4) :: k

    fld_out%cfg%id       = desc%request_id
    fld_out%name     = desc%name
    fld_out%stepId   = step_ref
    fld_out%region   = MERGE(TRIM(desc%target_set), "WHOLE_MODEL", LEN_TRIM(desc%target_set) > 0)
    fld_out%frequency%freq_mode     = OUT_FREQ_INTERVAL
    fld_out%frequency%interval      = MAX(1_i4, desc%frequency)
    fld_out%frequency%time_interval = desc%time_interval
    IF (desc%time_interval > 0.0_wp) fld_out%frequency%freq_mode = OUT_FREQ_TIMEPOINTS
    fld_out%nVariables = desc%n_variables
    IF (desc%n_variables > 0) THEN
      ALLOCATE(fld_out%variables(desc%n_variables))
      DO k = 1, desc%n_variables
        fld_out%variables(k)%name = desc%variables(k)
      END DO
    END IF
  END SUBROUTINE MD_OutputRequest_Desc_To_MD_FieldOut_Type

  SUBROUTINE MD_OutputRequest_Desc_To_MD_HistOut_Type(desc, step_ref, hist_out)
    TYPE(MD_OutputRequest_Desc), INTENT(IN)  :: desc
    INTEGER(i4),                 INTENT(IN)  :: step_ref
    TYPE(MD_HistOut_Type),       INTENT(OUT) :: hist_out

    INTEGER(i4) :: k

    hist_out%cfg%id       = desc%request_id
    hist_out%name     = desc%name
    hist_out%stepId   = step_ref
    hist_out%region   = MERGE(TRIM(desc%target_set), "", LEN_TRIM(desc%target_set) > 0)
    hist_out%frequency%freq_mode     = OUT_FREQ_INTERVAL
    hist_out%frequency%interval      = MAX(1_i4, desc%frequency)
    hist_out%frequency%time_interval = desc%time_interval
    IF (desc%time_interval > 0.0_wp) hist_out%frequency%freq_mode = OUT_FREQ_TIMEPOINTS
    hist_out%nVariables = desc%n_variables
    IF (desc%n_variables > 0) THEN
      ALLOCATE(hist_out%variables(desc%n_variables))
      DO k = 1, desc%n_variables
        hist_out%variables(k)%name = desc%variables(k)
      END DO
    END IF
  END SUBROUTINE MD_OutputRequest_Desc_To_MD_HistOut_Type

  !--------------------------------------------------------------------
  ! VarIdToName: Map OUT_U/OUT_S etc to "U"/"S"/...
  !--------------------------------------------------------------------
  FUNCTION VarIdToName(var_id) RESULT(name)
    INTEGER(i4), INTENT(IN) :: var_id
    CHARACTER(LEN=16) :: name
    SELECT CASE (var_id)
      CASE (1)  ; name = "U"
      CASE (2)  ; name = "V"
      CASE (3)  ; name = "A"
      CASE (4)  ; name = "RF"
      CASE (5)  ; name = "CF"
      CASE (6)  ; name = "NT"
      CASE (11) ; name = "S"
      CASE (12) ; name = "E"
      CASE (13) ; name = "PE"
      CASE (14) ; name = "EE"
      CASE (15) ; name = "LE"
      CASE (16) ; name = "NE"
      CASE (17) ; name = "PEEQ"
      CASE (18) ; name = "MISES"
      CASE (19) ; name = "PRESS"
      CASE (20) ; name = "TRIAX"
      CASE (21) ; name = "SDV"
      CASE (22) ; name = "STATUS"
      CASE (23) ; name = "SSE"
      CASE (24) ; name = "SPD"
      CASE (25) ; name = "SCD"
      CASE (26) ; name = "DAMAGE"
      CASE (31) ; name = "ENER"
      CASE (32) ; name = "EVOL"
      CASE (33) ; name = "IVOL"
      CASE (41) ; name = "COORD"
      CASE (51) ; name = "HFL"
      CASE (52) ; name = "RFL"
      CASE (60) ; name = "ALLKE"
      CASE (61) ; name = "ALLIE"
      CASE (62) ; name = "ALLSE"
      CASE (63) ; name = "ALLPD"
      CASE (64) ; name = "ALLCD"
      CASE (65) ; name = "ALLWK"
      CASE (66) ; name = "ALLVD"
      CASE (67) ; name = "ALLAE"
      CASE DEFAULT
        WRITE(name, '(A,I0)') "V", var_id
    END SELECT
  END FUNCTION VarIdToName

END MODULE MD_Out_Sync