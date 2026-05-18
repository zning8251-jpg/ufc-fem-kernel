!===============================================================================
! MODULE: MD_Out_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Output L3→L5 bridge
! BRIEF:  Convert L3_MD output definitions to L5_RT output tasks; check
!         output frequency.
!===============================================================================


MODULE MD_Out_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Out_Def
  USE MD_Out_API, ONLY: MD_Output_Domain, MD_OutputRequest_Desc, &
       OUT_FIELD, OUT_HISTORY
  USE MD_Step_Mgr, ONLY: MD_Step_Domain
  USE MD_Out_Mgr, ONLY: MD_Out_Mgr_GetRequestsForStep
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE
  
  ! BuildFieldOutTasks/BuildHistOutTasks/ShouldOutput context types defined in MD_Out_Def

  PUBLIC :: MD_Out_Brg_BuildFieldOutTasks
  PUBLIC :: MD_Out_Brg_BuildHistOutTasks
  PUBLIC :: MD_Out_Brg_BuildFieldOutTasks_FromDomain
  PUBLIC :: MD_Out_Brg_BuildHistOutTasks_FromDomain
  PUBLIC :: MD_Out_Brg_BuildFieldOutTasks_Select
  PUBLIC :: MD_Out_Brg_BuildHistOutTasks_Select
  PUBLIC :: MD_Out_Brg_ShouldOutput
  
CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_BuildFieldOutTasks
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Build field output tasks from definitions (legacy path).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_BuildFieldOutTasks(ctx)
    TYPE(MD_Out_BuildFieldOutTasks_Ctx_Type), INTENT(INOUT) :: ctx
    TYPE(MD_FieldOut_Type), ALLOCATABLE :: active_fieldouts(:)
    INTEGER(i4) :: i
    ctx%nFieldOuts = 0_i4
    IF (ALLOCATED(ctx%fieldout_ids)) DEALLOCATE(ctx%fieldout_ids)
    CALL MD_OutCtrl_GetFieldOutsForStep(ctx%md_out_ctrl, ctx%step_ctx%stepId, &
                                         active_fieldouts, ctx%nFieldOuts)
    IF (ctx%nFieldOuts == 0) RETURN
    ALLOCATE(ctx%fieldout_ids(ctx%nFieldOuts))
    DO i = 1, ctx%nFieldOuts
      ctx%fieldout_ids(i) = active_fieldouts(i)%cfg%id
    END DO
    IF (ALLOCATED(active_fieldouts)) DEALLOCATE(active_fieldouts)
  END SUBROUTINE MD_Out_Brg_BuildFieldOutTasks

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_BuildFieldOutTasks_FromDomain
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Build field output tasks via index-tree domain (bypass MD_OutCtrl).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_BuildFieldOutTasks_FromDomain(output_domain, step_domain, &
       step_idx, fieldout_ids, n_found, status)
    TYPE(MD_Output_Domain),     INTENT(IN)  :: output_domain
    TYPE(MD_Step_Domain),       INTENT(IN)  :: step_domain
    INTEGER(i4),                INTENT(IN)  :: step_idx
    INTEGER(i4),                INTENT(OUT) :: fieldout_ids(:)
    INTEGER(i4),                INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    INTEGER(i4), ALLOCATABLE :: req_indices(:)
    INTEGER(i4) :: i, req_id, n_req
    TYPE(MD_OutputRequest_Desc) :: req

    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. output_domain%initialized .OR. .NOT. step_domain%initialized) RETURN

    ALLOCATE(req_indices(output_domain%n_requests))
    CALL MD_Out_Mgr_GetRequestsForStep(output_domain, step_domain, step_idx, &
         req_indices, n_req, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      DEALLOCATE(req_indices)
      RETURN
    END IF

    DO i = 1, n_req
      req_id = req_indices(i)
      IF (req_id < 1 .OR. req_id > output_domain%n_requests) CYCLE
      req = output_domain%requests(req_id)
      IF (req%request_type == OUT_FIELD) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(fieldout_ids)) fieldout_ids(n_found) = req_id
      END IF
    END DO
    DEALLOCATE(req_indices)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Out_Brg_BuildFieldOutTasks_FromDomain

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_BuildFieldOutTasks_Select
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Unified dispatcher: FromDomain when ready, else legacy.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_BuildFieldOutTasks_Select(ctx, step_idx, status)
    TYPE(MD_Out_BuildFieldOutTasks_Ctx_Type), INTENT(INOUT) :: ctx
    INTEGER(i4),                             INTENT(IN)    :: step_idx
    TYPE(ErrorStatusType),                    INTENT(OUT)   :: status

    INTEGER(i4), ALLOCATABLE :: ids(:)
    INTEGER(i4) :: n_found

    CALL init_error_status(status)
    ctx%nFieldOuts = 0_i4
    IF (ALLOCATED(ctx%fieldout_ids)) DEALLOCATE(ctx%fieldout_ids)

    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%output%initialized .AND. &
        g_ufc_global%md_layer%output%n_requests > 0_i4 .AND. &
        g_ufc_global%md_layer%step%initialized) THEN
      ALLOCATE(ids(g_ufc_global%md_layer%output%n_requests))
      CALL MD_Out_Brg_BuildFieldOutTasks_FromDomain( &
           g_ufc_global%md_layer%output, g_ufc_global%md_layer%step, &
           step_idx, ids, n_found, status)
      IF (status%status_code == IF_STATUS_OK .AND. n_found > 0_i4) THEN
        ctx%nFieldOuts = n_found
        ALLOCATE(ctx%fieldout_ids(n_found))
        ctx%fieldout_ids(1:n_found) = ids(1:n_found)
      END IF
      IF (ALLOCATED(ids)) DEALLOCATE(ids)
    ELSE
      ctx%step_ctx%stepId = step_idx
      CALL MD_Out_Brg_BuildFieldOutTasks(ctx)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE MD_Out_Brg_BuildFieldOutTasks_Select
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_BuildHistOutTasks
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Build history output tasks from definitions (legacy path).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_BuildHistOutTasks(ctx)
    TYPE(MD_Out_BuildHistOutTasks_Ctx_Type), INTENT(INOUT) :: ctx
    TYPE(MD_HistOut_Type), ALLOCATABLE :: active_histouts(:)
    INTEGER(i4) :: i
    ctx%nHistOuts = 0_i4
    IF (ALLOCATED(ctx%histout_ids)) DEALLOCATE(ctx%histout_ids)
    CALL MD_OutCtrl_GetHistOutsForStep(ctx%md_out_ctrl, ctx%step_ctx%stepId, &
                                        active_histouts, ctx%nHistOuts)
    IF (ctx%nHistOuts == 0) RETURN
    ALLOCATE(ctx%histout_ids(ctx%nHistOuts))
    DO i = 1, ctx%nHistOuts
      ctx%histout_ids(i) = active_histouts(i)%cfg%id
    END DO
    IF (ALLOCATED(active_histouts)) DEALLOCATE(active_histouts)
  END SUBROUTINE MD_Out_Brg_BuildHistOutTasks

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_BuildHistOutTasks_FromDomain
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Build history output tasks via index-tree domain.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_BuildHistOutTasks_FromDomain(output_domain, step_domain, &
       step_idx, histout_ids, n_found, status)
    TYPE(MD_Output_Domain),     INTENT(IN)  :: output_domain
    TYPE(MD_Step_Domain),       INTENT(IN)  :: step_domain
    INTEGER(i4),                INTENT(IN)  :: step_idx
    INTEGER(i4),                INTENT(OUT) :: histout_ids(:)
    INTEGER(i4),                INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    INTEGER(i4), ALLOCATABLE :: req_indices(:)
    INTEGER(i4) :: i, req_id, n_req
    TYPE(MD_OutputRequest_Desc) :: req

    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. output_domain%initialized .OR. .NOT. step_domain%initialized) RETURN

    ALLOCATE(req_indices(output_domain%n_requests))
    CALL MD_Out_Mgr_GetRequestsForStep(output_domain, step_domain, step_idx, &
         req_indices, n_req, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      DEALLOCATE(req_indices)
      RETURN
    END IF

    DO i = 1, n_req
      req_id = req_indices(i)
      IF (req_id < 1 .OR. req_id > output_domain%n_requests) CYCLE
      req = output_domain%requests(req_id)
      IF (req%request_type == OUT_HISTORY) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(histout_ids)) histout_ids(n_found) = req_id
      END IF
    END DO
    DEALLOCATE(req_indices)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Out_Brg_BuildHistOutTasks_FromDomain

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_BuildHistOutTasks_Select
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Unified dispatcher: FromDomain when ready, else legacy.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_BuildHistOutTasks_Select(ctx, step_idx, status)
    TYPE(MD_Out_BuildHistOutTasks_Ctx_Type), INTENT(INOUT) :: ctx
    INTEGER(i4),                            INTENT(IN)    :: step_idx
    TYPE(ErrorStatusType),                   INTENT(OUT)   :: status

    INTEGER(i4), ALLOCATABLE :: ids(:)
    INTEGER(i4) :: n_found

    CALL init_error_status(status)
    ctx%nHistOuts = 0_i4
    IF (ALLOCATED(ctx%histout_ids)) DEALLOCATE(ctx%histout_ids)

    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%output%initialized .AND. &
        g_ufc_global%md_layer%output%n_requests > 0_i4 .AND. &
        g_ufc_global%md_layer%step%initialized) THEN
      ALLOCATE(ids(g_ufc_global%md_layer%output%n_requests))
      CALL MD_Out_Brg_BuildHistOutTasks_FromDomain( &
           g_ufc_global%md_layer%output, g_ufc_global%md_layer%step, &
           step_idx, ids, n_found, status)
      IF (status%status_code == IF_STATUS_OK .AND. n_found > 0_i4) THEN
        ctx%nHistOuts = n_found
        ALLOCATE(ctx%histout_ids(n_found))
        ctx%histout_ids(1:n_found) = ids(1:n_found)
      END IF
      IF (ALLOCATED(ids)) DEALLOCATE(ids)
    ELSE
      ctx%step_ctx%stepId = step_idx
      CALL MD_Out_Brg_BuildHistOutTasks(ctx)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE MD_Out_Brg_BuildHistOutTasks_Select
  
  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Out_Brg_ShouldOutput
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Check if output should occur based on frequency mode.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Out_Brg_ShouldOutput(ctx)
    TYPE(MD_Out_ShouldOutput_Ctx_Type), INTENT(INOUT) :: ctx
    INTEGER(i4) :: i
    ctx%should_output = .FALSE.
    SELECT CASE(ctx%frequency%freq_mode)
    CASE(OUT_FREQ_EVERY_INCR)
      ctx%should_output = .TRUE.
    CASE(OUT_FREQ_INTERVAL)
      IF (MOD(ctx%current_incr, ctx%frequency%interval) == 0) ctx%should_output = .TRUE.
    CASE(OUT_FREQ_TIMEPOINTS)
      DO i = 1, ctx%frequency%nTimePoints
        IF (ABS(ctx%current_time - ctx%frequency%time_points(i)) < 1.0e-8_wp) THEN
          ctx%should_output = .TRUE.
          EXIT
        END IF
      END DO
    CASE DEFAULT
      ctx%should_output = .FALSE.
    END SELECT
    IF (ctx%frequency%last_incr_only) ctx%should_output = .FALSE.
  END SUBROUTINE MD_Out_Brg_ShouldOutput

END MODULE MD_Out_Brg
