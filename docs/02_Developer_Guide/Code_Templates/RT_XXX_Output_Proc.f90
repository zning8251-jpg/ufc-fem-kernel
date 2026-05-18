!==============================================================================!
! MODULE RT_XXX_Output_Proc                                   [Template v1.1]
! Layer  : L5_RT  (When — run-time orchestration)
! Domain : Output
! Feature: XXX_XXX  ← replace with concrete output handler name
!
! Purpose:
!   Dispatches field-output and history-output write requests for a single
!   output block (one *OUTPUT,FIELD or *OUTPUT,HISTORY block) at the current
!   increment.  Evaluates the trigger condition, marshals result data from the
!   L5_RT result store, and calls the ODB/DAT writer stub.
!
! SIO-01  Six-parameter standard form (Principle #14):
!   (Out_FState, Out_HState, Out_Algo, Out_Ctx, RT_Com_Ctx, args)
!   Out_FState / Out_HState — field vs history state (dual State slots)
!   Out_Algo   ← TYPE(RT_WriteCtrl_Algo)
!   Out_Ctx    ← TYPE(RT_Output_Ctx)
!   RT_Com_Ctx ← TYPE(RT_Com_Base_Ctx)  increment bookkeeping (read-only here)
!   args       ← TYPE(RT_XXX_Output_Args) unified [IN]/[OUT] bundle
!
! SIO-02  Single RT_XXX_Output_Args; [IN]/[OUT] fields marked in comments.
! SIO-03  No dynamic memory allocation inside SUBROUTINE body.
! SIO-04  pnewdt: Output domain does NOT control step size → no pnewdt field.
! SIO-05  args%status is the structured status object; init with
!         init_error_status(...) and inspect %status_code.
! SIO-06  Private writers remain hot-path stubs.
!
! Call chain:
!   RT_StepDriver → RT_XXX_Output_Apply
!                 → [Trigger check] → RT_XXX_FieldOut_Write  (field path)
!                                   → RT_XXX_HistOut_Write   (history path)
!
! Naming convention:
!   Replace XXX_XXX with the concrete output handler, e.g.:
!     RT_Output_Std_Full_Proc   → standard full-model field output
!     RT_Output_Hist_Node_Proc  → history output for a node set
!
! Module catalogue:
!   TYPE RT_XXX_Output_Args   — unified per-call bundle ([IN]/[OUT] in comments)
!   SUBROUTINE RT_XXX_Output_Apply — public dispatcher (6-param SIO)
!   SUBROUTINE RT_XXX_FieldOut_Write — PRIVATE field-output writer stub
!   SUBROUTINE RT_XXX_HistOut_Write  — PRIVATE history-output writer stub
!   FUNCTION   RT_XXX_Output_ShouldWrite — PRIVATE trigger evaluator
!==============================================================================!
MODULE RT_XXX_Output_Proc
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_WARN, IF_STATUS_ERROR
  USE RT_Com_Types,    ONLY: RT_Com_Base_Ctx
  USE RT_Output_Types, ONLY: RT_FieldOut_State, RT_HistOut_State, &
                              RT_Output_Ctx, RT_WriteCtrl_Algo,   &
                              RT_OUT_TRIG_OUT_TRIG_TIME_INTERVAL,  &
                              RT_OUT_TRIG_OUT_TRIG_INC_INTERVAL,   &
                              RT_OUT_TRIG_OUT_TRIG_STEP_END,       &
                              RT_OUT_TRIG_OUT_TRIG_EVERY_INC,      &
                              RT_OUT_TRIG_OUT_TRIG_USER
  USE MD_Output_Types, ONLY: MD_FieldOut_Desc, MD_HistOut_Desc, &
                              MD_FieldOut_Var,                   &
                              MD_OUTPUT_OUTFREQ_ALL,             &
                              MD_OUTPUT_OUTFREQ_LAST,            &
                              MD_OUTPUT_OUTFREQ_INTERVAL,        &
                              MD_OUTPUT_OUTFREQ_TIME,            &
                              MD_OUTPUT_OUTPOS_INTEGRATION_PTS,  &
                              MD_OUTPUT_OUTPOS_NODES
  IMPLICIT NONE
  PRIVATE

  !-- Output mode constants (internal)
  INTEGER(i4), PARAMETER :: OUT_MODE_FIELD   = 1_i4   ! *OUTPUT,FIELD path
  INTEGER(i4), PARAMETER :: OUT_MODE_HISTORY = 2_i4   ! *OUTPUT,HISTORY path

  !-- Trigger evaluation results
  INTEGER(i4), PARAMETER :: TRIG_SKIP  = 0_i4   ! Do not write this increment
  INTEGER(i4), PARAMETER :: TRIG_WRITE = 1_i4   ! Write now

  !============================================================================!
  ! TYPE RT_XXX_Output_Args — unified per-call bundle (Principle #14)
  !============================================================================!
  TYPE, PUBLIC :: RT_XXX_Output_Args
    !-- [IN] Output mode selector
    INTEGER(i4) :: out_mode        = OUT_MODE_FIELD ! FIELD or HISTORY path

    !-- [IN] Output request identification
    INTEGER(i4) :: request_id      = 0_i4   ! MD_FieldOut_Desc%request_id
    INTEGER(i4) :: n_vars          = 0_i4   ! Number of variables to write
    CHARACTER(LEN=32) :: var_names(64) = '' ! Variable key array (max 64)

    !-- [IN] Scope selectors
    CHARACTER(LEN=64) :: elem_set_name = '' ! '' = whole model
    CHARACTER(LEN=64) :: node_set_name = '' ! '' = whole model
    INTEGER(i4)       :: result_position = MD_OUTPUT_OUTPOS_INTEGRATION_PTS

    !-- [IN] State-store source pointers (pre-resolved by StepDriver)
    REAL(wp), POINTER :: stress_store(:,:) => NULL() ! (n_elem, 6) or (n_gp_total, 6)
    REAL(wp), POINTER :: strain_store(:,:) => NULL() ! (n_elem, 6)
    REAL(wp), POINTER :: disp_store(:)    => NULL()  ! (n_dof_total)
    REAL(wp), POINTER :: react_store(:)   => NULL()  ! (n_dof_total)
    REAL(wp), POINTER :: sdv_store(:,:)   => NULL()  ! (n_gp_total, n_sdv)
    INTEGER(i4)       :: n_gp_total   = 0_i4
    INTEGER(i4)       :: n_sdv        = 0_i4

    !-- [IN] Node/element set membership arrays (NULL = whole model)
    INTEGER(i4), POINTER :: elem_ids(:) => NULL()   ! Active element IDs
    INTEGER(i4), POINTER :: node_ids(:) => NULL()   ! Active node IDs
    INTEGER(i4)          :: n_elems = 0_i4
    INTEGER(i4)          :: n_nodes = 0_i4

    !-- [IN] Frequency policy (mirrored from MD_FieldOut_Desc for hot-path avoidance)
    INTEGER(i4) :: freq_policy   = MD_OUTPUT_OUTFREQ_ALL
    INTEGER(i4) :: freq_interval = 1_i4

    !-- [OUT] Status
    TYPE(ErrorStatusType) :: status               ! Structured status; check %status_code
    LOGICAL               :: success      = .FALSE.

    !-- [OUT] Write result
    LOGICAL     :: write_performed = .FALSE.  ! .TRUE. if output was emitted
    INTEGER(i4) :: n_vars_written  = 0_i4    ! Variables successfully written
    INTEGER(i4) :: n_elems_written = 0_i4    ! Elements / nodes written
    INTEGER(i4) :: n_nodes_written = 0_i4
    INTEGER(i4) :: n_pts_written   = 0_i4    ! History xy-data points written

    !-- [OUT] Trigger outcome
    INTEGER(i4) :: trigger_result  = TRIG_SKIP ! TRIG_SKIP / TRIG_WRITE

    !-- [OUT] Diagnostics
    REAL(wp)    :: write_cpu_time  = 0.0_wp   ! CPU time consumed
  END TYPE RT_XXX_Output_Args

  PUBLIC :: RT_XXX_Output_Args
  PUBLIC :: RT_XXX_Output_Apply

CONTAINS

  !============================================================================!
  ! SUBROUTINE RT_XXX_Output_Apply                        [Public, 6-param SIO]
  !
  ! Dispatcher for one output block at the current increment.
  ! Evaluates the trigger, then routes to field or history writer.
  !
  ! Arguments (SIO-01 six-parameter form):
  !   Out_FState   [INOUT] RT_FieldOut_State — field-path run-time state
  !   Out_HState   [INOUT] RT_HistOut_State  — hist-path run-time state
  !   Out_Algo     [IN]    RT_WriteCtrl_Algo — write frequency configuration
  !   Out_Ctx      [IN]    RT_Output_Ctx     — current step/increment/time ctx
  !   RT_Com_Ctx   [IN]    RT_Com_Base_Ctx   — increment bookkeeping (kstep/kinc/…)
  !   args         [INOUT] RT_XXX_Output_Args — unified per-call bundle
  !
  ! Note: Out_FState and Out_HState are both passed so the dispatcher can
  ! update whichever is relevant without an extra selector argument.
  !============================================================================!
  ! Phase: Output | Apply | COLD_PATH
  SUBROUTINE RT_XXX_Output_Apply(Out_FState, Out_HState, Out_Algo, &
                                  Out_Ctx, RT_Com_Ctx, args)
    TYPE(RT_FieldOut_State),  INTENT(INOUT) :: Out_FState
    TYPE(RT_HistOut_State),   INTENT(INOUT) :: Out_HState
    TYPE(RT_WriteCtrl_Algo),  INTENT(IN)    :: Out_Algo
    TYPE(RT_Output_Ctx),      INTENT(IN)    :: Out_Ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx
    TYPE(RT_XXX_Output_Args),  INTENT(INOUT) :: args

    REAL(wp) :: t_cpu_start, t_cpu_end
    INTEGER  :: trig

    !-- RT_Com_Ctx: increment bookkeeping (read-mostly here; same slot as Load/Mat)
    IF (Out_Ctx%inc_id /= Out_Ctx%inc_id + RT_Com_Ctx%kstep - RT_Com_Ctx%kstep) THEN
      args%success = .FALSE.
    END IF

    !--------------------------------------------------------------------------!
    ! Step 0: Initialise output half of bundle
    !--------------------------------------------------------------------------!
    CALL init_error_status(args%status)
    args%success         = .FALSE.
    args%write_performed = .FALSE.
    args%n_vars_written  = 0_i4
    args%n_elems_written = 0_i4
    args%n_nodes_written = 0_i4
    args%n_pts_written   = 0_i4
    args%trigger_result  = TRIG_SKIP
    args%write_cpu_time  = 0.0_wp

    CALL CPU_TIME(t_cpu_start)

    !--------------------------------------------------------------------------!
    ! Step 1: Force-write override (e.g., step end or analysis end)
    !--------------------------------------------------------------------------!
    IF (Out_Ctx%force_write) THEN
      trig = TRIG_WRITE
    ELSE
      !------------------------------------------------------------------------!
      ! Step 2: Evaluate trigger condition for this output block
      !------------------------------------------------------------------------!
      trig = RT_XXX_Output_ShouldWrite(Out_FState, Out_HState, &
                                        Out_Algo, Out_Ctx, args)
    END IF

    args%trigger_result = trig

    IF (trig == TRIG_SKIP) THEN
      !-- No output required this increment
      args%success = .TRUE.
      CALL CPU_TIME(t_cpu_end)
      args%write_cpu_time = t_cpu_end - t_cpu_start
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 3: Suppress check (e.g., Out_FState%suppress_this_inc)
    !--------------------------------------------------------------------------!
    IF (args%out_mode == OUT_MODE_FIELD) THEN
      IF (Out_FState%suppress_this_inc) THEN
        args%success = .TRUE.
        CALL CPU_TIME(t_cpu_end)
        args%write_cpu_time = t_cpu_end - t_cpu_start
        RETURN
      END IF
    END IF

    !--------------------------------------------------------------------------!
    ! Step 4: Dispatch to concrete writer
    !--------------------------------------------------------------------------!
    SELECT CASE (args%out_mode)

      CASE (OUT_MODE_FIELD)
        !-- Field output path (ODB frame write)
        CALL RT_XXX_FieldOut_Write(Out_FState, Out_Ctx, args)

      CASE (OUT_MODE_HISTORY)
        !-- History output path (xy-data accumulation)
        CALL RT_XXX_HistOut_Write(Out_HState, Out_Ctx, args)

      CASE DEFAULT
        args%status%status_code = IF_STATUS_ERROR
        args%status%message     = 'RT_XXX_Output_Apply: unknown out_mode'
        args%success            = .FALSE.
        CALL CPU_TIME(t_cpu_end)
        args%write_cpu_time = t_cpu_end - t_cpu_start
        RETURN

    END SELECT

    !--------------------------------------------------------------------------!
    ! Step 5: Update run-time state after successful write
    !--------------------------------------------------------------------------!
    IF (args%write_performed) THEN
      SELECT CASE (args%out_mode)
        CASE (OUT_MODE_FIELD)
          Out_FState%n_frames_written = Out_FState%n_frames_written + 1_i4
          Out_FState%t_last_written   = Out_Ctx%step_time
          Out_FState%inc_last_written = Out_Ctx%inc_id
          Out_FState%write_pending    = .FALSE.
        CASE (OUT_MODE_HISTORY)
          Out_HState%n_points_written = Out_HState%n_points_written + &
                                          args%n_pts_written
          Out_HState%t_last_written   = Out_Ctx%step_time
      END SELECT
    END IF

    !--------------------------------------------------------------------------!
    ! Step 6: Finalize timing
    !--------------------------------------------------------------------------!
    CALL CPU_TIME(t_cpu_end)
    args%write_cpu_time = t_cpu_end - t_cpu_start

  END SUBROUTINE RT_XXX_Output_Apply


  !============================================================================!
  ! FUNCTION RT_XXX_Output_ShouldWrite                              [PRIVATE]
  ! Evaluates trigger condition → TRIG_WRITE or TRIG_SKIP.
  !============================================================================!
  FUNCTION RT_XXX_Output_ShouldWrite(FState, HState, Algo, Ctx, args) &
      RESULT(trig)
    TYPE(RT_FieldOut_State), INTENT(IN) :: FState
    TYPE(RT_HistOut_State),  INTENT(IN) :: HState
    TYPE(RT_WriteCtrl_Algo), INTENT(IN) :: Algo
    TYPE(RT_Output_Ctx),     INTENT(IN) :: Ctx
    TYPE(RT_XXX_Output_Args), INTENT(IN) :: args

    INTEGER(i4) :: trig
    INTEGER(i4) :: interval

    trig = TRIG_SKIP

    SELECT CASE (Ctx%trig_type)

      CASE (RT_OUT_TRIG_OUT_TRIG_EVERY_INC)
        !-- Write every increment
        trig = TRIG_WRITE

      CASE (RT_OUT_TRIG_OUT_TRIG_STEP_END)
        !-- Write only at end of step
        IF (Ctx%is_step_end) trig = TRIG_WRITE

      CASE (RT_OUT_TRIG_OUT_TRIG_INC_INTERVAL)
        !-- Write every N increments
        IF (args%out_mode == OUT_MODE_FIELD) THEN
          interval = Algo%field_interval
        ELSE
          interval = Algo%hist_interval
        END IF
        IF (interval < 1_i4) interval = 1_i4
        IF (MOD(Ctx%inc_id, interval) == 0) trig = TRIG_WRITE

      CASE (RT_OUT_TRIG_OUT_TRIG_TIME_INTERVAL)
        !-- Write when elapsed time exceeds threshold
        IF (args%out_mode == OUT_MODE_FIELD) THEN
          IF (Ctx%step_time >= FState%t_next_due - 1.0e-12_wp) THEN
            trig = TRIG_WRITE
          END IF
        ELSE
          IF (Ctx%step_time >= HState%t_next_due - 1.0e-12_wp) THEN
            trig = TRIG_WRITE
          END IF
        END IF

      CASE (RT_OUT_TRIG_OUT_TRIG_USER)
        !-- User-controlled (UEXTERNALDB): always pass through;
        !   actual suppression handled externally via force_write flag.
        trig = TRIG_WRITE

      CASE DEFAULT
        trig = TRIG_SKIP

    END SELECT

    !-- Frequency policy from MD_FieldOut_Desc (additional gate)
    IF (trig == TRIG_WRITE) THEN
      SELECT CASE (args%freq_policy)
        CASE (MD_OUTPUT_OUTFREQ_LAST)
          !-- Only write at last increment of step
          IF (.NOT. Ctx%is_step_end) trig = TRIG_SKIP
        CASE (MD_OUTPUT_OUTFREQ_INTERVAL)
          IF (args%freq_interval > 1_i4) THEN
            IF (MOD(Ctx%inc_id, args%freq_interval) /= 0) trig = TRIG_SKIP
          END IF
        CASE DEFAULT
          !-- OUTFREQ_ALL / OUTFREQ_TIME: no extra gate
          CONTINUE
      END SELECT
    END IF

  END FUNCTION RT_XXX_Output_ShouldWrite


  !============================================================================!
  ! SUBROUTINE RT_XXX_FieldOut_Write                               [PRIVATE]
  ! Writes one ODB frame for the current increment.
  ! Iterates over the requested variable list and copies result data
  ! from the state-store pointers in args into the ODB writer stub.
  !============================================================================!
  SUBROUTINE RT_XXX_FieldOut_Write(FState, Ctx, args)
    TYPE(RT_FieldOut_State), INTENT(INOUT) :: FState
    TYPE(RT_Output_Ctx),     INTENT(IN)    :: Ctx
    TYPE(RT_XXX_Output_Args), INTENT(INOUT) :: args

    INTEGER(i4) :: iv, ie, in_node
    CHARACTER(LEN=32) :: vname

    !-- Validate state-store pointers (at least one must be associated)
    IF (.NOT. (ASSOCIATED(args%stress_store) .OR. &
               ASSOCIATED(args%disp_store)   .OR. &
               ASSOCIATED(args%sdv_store))) THEN
      args%status%status_code = IF_STATUS_WARN
      args%status%message     = 'RT_XXX_FieldOut_Write: no result store associated'
      args%success        = .TRUE.   ! Warning, not fatal
      args%write_performed = .FALSE.
      RETURN
    END IF

    !-- Loop over requested variables
    DO iv = 1, args%n_vars
      vname = args%var_names(iv)

      SELECT CASE (TRIM(vname))

        CASE ('S', 'STRESS')
          !-- Stress: (n_elem, 6) or (n_gp_total, 6) depending on position
          IF (ASSOCIATED(args%stress_store)) THEN
            IF (args%result_position == MD_OUTPUT_OUTPOS_INTEGRATION_PTS) THEN
              !-- Write per-GP stress (stub: loop placeholder)
              !  In production: CALL ODB_WriteElemFieldGP(frame_id, 'S', args%stress_store)
              args%n_elems_written = args%n_elems
            ELSE
              !-- Extrapolated to nodes
              !  In production: CALL ODB_WriteElemFieldNode(frame_id, 'S', ...)
              args%n_elems_written = args%n_elems
            END IF
            args%n_vars_written = args%n_vars_written + 1_i4
          END IF

        CASE ('E', 'STRAIN')
          IF (ASSOCIATED(args%strain_store)) THEN
            !  In production: CALL ODB_WriteElemField(frame_id, 'E', args%strain_store)
            args%n_elems_written = args%n_elems
            args%n_vars_written  = args%n_vars_written + 1_i4
          END IF

        CASE ('U', 'DISP')
          IF (ASSOCIATED(args%disp_store)) THEN
            !  In production: CALL ODB_WriteNodeField(frame_id, 'U', args%disp_store)
            args%n_nodes_written = args%n_nodes
            args%n_vars_written  = args%n_vars_written + 1_i4
          END IF

        CASE ('RF', 'REACTION')
          IF (ASSOCIATED(args%react_store)) THEN
            !  In production: CALL ODB_WriteNodeField(frame_id, 'RF', args%react_store)
            args%n_nodes_written = args%n_nodes
            args%n_vars_written  = args%n_vars_written + 1_i4
          END IF

        CASE ('SDV')
          !-- State-dependent variables (whole SDV block)
          IF (ASSOCIATED(args%sdv_store) .AND. args%n_sdv > 0_i4) THEN
            !  In production: CALL ODB_WriteSDV(frame_id, args%sdv_store, args%n_sdv)
            args%n_elems_written = args%n_elems
            args%n_vars_written  = args%n_vars_written + args%n_sdv
          END IF

        CASE DEFAULT
          !-- Unknown variable key: warn and continue
          args%status%status_code = IF_STATUS_WARN
          WRITE(args%status%message, '(A,A,A)') &
            'RT_XXX_FieldOut_Write: unrecognized variable key [', &
            TRIM(vname), '] — skipped'

      END SELECT
    END DO

    !-- Mark write performed if at least one variable was written
    args%write_performed = (args%n_vars_written > 0_i4)
    IF (.NOT. args%success) args%success = args%write_performed

    !-- Update max-frame guard
    IF (FState%n_frames_max > 0_i4) THEN
      IF (FState%n_frames_written >= FState%n_frames_max) THEN
        FState%suppress_this_inc = .TRUE.
      END IF
    END IF

    args%success = .TRUE.

  END SUBROUTINE RT_XXX_FieldOut_Write


  !============================================================================!
  ! SUBROUTINE RT_XXX_HistOut_Write                                [PRIVATE]
  ! Accumulates one xy-data point for each history variable at current time.
  ! In production this would call the ODB xy-data writer or flush buffer.
  !============================================================================!
  SUBROUTINE RT_XXX_HistOut_Write(HState, Ctx, args)
    TYPE(RT_HistOut_State),  INTENT(INOUT) :: HState
    TYPE(RT_Output_Ctx),     INTENT(IN)    :: Ctx
    TYPE(RT_XXX_Output_Args), INTENT(INOUT) :: args

    INTEGER(i4) :: iv
    CHARACTER(LEN=32) :: vname
    REAL(wp)    :: extracted_val

    !-- Validate: at least one source must be present
    IF (args%n_vars == 0_i4) THEN
      args%status%status_code = IF_STATUS_WARN
      args%status%message     = 'RT_XXX_HistOut_Write: n_vars = 0, nothing to write'
      args%success        = .TRUE.
      args%write_performed = .FALSE.
      RETURN
    END IF

    !-- Loop over history variables and extract scalar value at target node/element
    DO iv = 1, args%n_vars
      vname = args%var_names(iv)
      extracted_val = 0.0_wp

      SELECT CASE (TRIM(vname))

        CASE ('U1', 'U2', 'U3')
          !-- Node displacement component
          IF (ASSOCIATED(args%disp_store) .AND. args%n_nodes > 0_i4) THEN
            !  In production: extract component at target node DOF
            extracted_val = args%disp_store(1)   ! placeholder: first DOF
          END IF

        CASE ('RF1', 'RF2', 'RF3')
          !-- Reaction force component at node
          IF (ASSOCIATED(args%react_store) .AND. args%n_nodes > 0_i4) THEN
            extracted_val = args%react_store(1)
          END IF

        CASE ('S11', 'S22', 'S33', 'S12', 'S13', 'S23')
          !-- Stress component at element GP
          IF (ASSOCIATED(args%stress_store) .AND. args%n_gp_total > 0_i4) THEN
            extracted_val = args%stress_store(1, 1)  ! placeholder: elem 1, comp 1
          END IF

        CASE ('ALLSE', 'ALLKE', 'ALLWK', 'ETOTAL')
          !-- Energy quantities (global scalar, fetched from global energy store)
          !  In production: CALL RT_Energy_GetScalar(vname, extracted_val)
          extracted_val = 0.0_wp

        CASE DEFAULT
          args%status%status_code = IF_STATUS_WARN
          WRITE(args%status%message, '(A,A,A)') &
            'RT_XXX_HistOut_Write: unrecognized hist variable [', &
            TRIM(vname), '] — skipped'
          CYCLE

      END SELECT

      !-- Accumulate in buffer (stub: increment counter)
      !  In production: CALL ODB_HistBuffer_Push(Ctx%step_time, extracted_val)
      args%n_pts_written = args%n_pts_written + 1_i4
      args%n_vars_written = args%n_vars_written + 1_i4

    END DO

    !-- Flush buffer if threshold reached
    IF (HState%buffer_count + args%n_pts_written >= HState%buffer_max) THEN
      !  In production: CALL ODB_HistBuffer_Flush()
      HState%buffer_active = .FALSE.
      HState%buffer_count  = 0_i4
    ELSE
      HState%buffer_count  = HState%buffer_count + args%n_pts_written
      HState%buffer_active = .TRUE.
    END IF

    args%write_performed = (args%n_pts_written > 0_i4)
    args%success         = .TRUE.

  END SUBROUTINE RT_XXX_HistOut_Write

END MODULE RT_XXX_Output_Proc
