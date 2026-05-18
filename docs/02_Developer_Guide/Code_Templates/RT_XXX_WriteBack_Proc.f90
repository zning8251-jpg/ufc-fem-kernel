!==============================================================================!
! MODULE RT_WriteBack_XXX_Proc                            [Template v1.0]
! Layer  : L5_RT  (When — run-time orchestration)
! Domain : WriteBack
! Feature: XXX_XXX  ← replace with concrete write-back handler name
!
! Purpose:
!   Writes computed result data (displacements, velocities, accelerations,
!   stresses, strains, reactions) from the L5_RT increment result store back
!   to the L3_MD model data containers.  This is a pure data-movement domain:
!   no physics, no Newton iteration, no step-size control.
!
! SIO-01  Six-parameter standard form (Principle #14):
!   (WB_Desc, WB_State, [Algo absent], WB_Ctx, args)
!   WB_Desc   ← TYPE(RT_WriteBack_Desc)  [Desc role — write config]
!   WB_State  ← TYPE(RT_WriteBack_State) [State role — progress tracking]
!   WB_Ctx    ← TYPE(RT_WriteBack_Ctx)   [Ctx role — buffer pointers]
!   args      ← TYPE(RT_XXX_WriteBack_Args)  unified [IN]/[OUT] bundle (INOUT)
!
!   Note: RT_WriteBack_Types has no Algo TYPE (pure data op).
!         The Algo slot is filled by a local RT_WB_Ctrl dummy TYPE declared here
!         to maintain the 6-position interface signature.
!
! SIO-02  Single RT_XXX_WriteBack_Args; [IN]/[OUT] fields in comments.
! SIO-03  No dynamic memory allocation inside SUBROUTINE body.
! SIO-04  pnewdt: WriteBack domain does NOT control step size → no pnewdt.
! SIO-05  args%status is the structured status object; init with
!         init_error_status(...) and inspect %status_code.
!
! Call chain:
!   RT_StepDriver (post-convergence) → RT_XXX_WriteBack_Apply
!     → RT_XXX_WB_NodeResults   (displacements / reactions)
!     → RT_XXX_WB_ElemResults   (stresses / strains / SDV)
!     → RT_XXX_WB_DynResults    (velocities / accelerations — dynamic only)
!
! Write-back sequence (mandatory order):
!   1. Node results (u, RF) — must precede element results (DOF map reuse)
!   2. Element GP results (sigma, eps, SDV)
!   3. Dynamic results (v, a) — only if lflags indicate dynamic step
!
! Module catalogue:
!   TYPE RT_WB_Ctrl            — local Algo-slot placeholder (no fields)
!   TYPE RT_XXX_WriteBack_Args — unified [IN]/[OUT] bundle
!   SUBROUTINE RT_XXX_WriteBack_Apply  — public dispatcher (6-param SIO)
!   SUBROUTINE RT_XXX_WB_NodeResults   — PRIVATE node result write-back
!   SUBROUTINE RT_XXX_WB_ElemResults   — PRIVATE element GP result write-back
!   SUBROUTINE RT_XXX_WB_DynResults    — PRIVATE dynamic result write-back
!==============================================================================!
MODULE RT_XXX_WriteBack_Proc
  USE IF_Prec_Core,            ONLY: wp, i4
  USE IF_Err_Brg,         ONLY: ErrorStatusType, init_error_status, &
                                 IF_STATUS_OK, IF_STATUS_WARN, IF_STATUS_ERROR
  USE RT_WriteBack_Types, ONLY: RT_WriteBack_Desc, RT_WriteBack_State, &
                                 RT_WriteBack_Ctx,                      &
                                 RT_FIELD_FIELD_U, RT_FIELD_FIELD_V,    &
                                 RT_FIELD_FIELD_A, RT_FIELD_FIELD_S,    &
                                 RT_FIELD_FIELD_E, RT_FIELD_FIELD_RF
  IMPLICIT NONE
  PRIVATE

  !-- Write-back channel bitmask constants (used in RT_XXX_WriteBack_Args)
  INTEGER(i4), PARAMETER, PUBLIC :: WB_CHAN_NODE   = 1_i4  ! u, RF
  INTEGER(i4), PARAMETER, PUBLIC :: WB_CHAN_ELEM   = 2_i4  ! sigma, eps, SDV
  INTEGER(i4), PARAMETER, PUBLIC :: WB_CHAN_DYN    = 4_i4  ! v, a

  !============================================================================!
  ! TYPE RT_WB_Ctrl                                        [Algo-slot holder]
  ! Empty placeholder TYPE occupying the Algo parameter position in the
  ! 6-param SIO signature.  No algorithmic choice is needed for WriteBack.
  !============================================================================!
  TYPE, PUBLIC :: RT_WB_Ctrl
    INTEGER(i4) :: reserved = 0_i4  ! No fields needed
  END TYPE RT_WB_Ctrl

  !============================================================================!
  ! TYPE RT_XXX_WriteBack_Args — unified write-back bundle (Principle #14)
  !============================================================================!
  TYPE, PUBLIC :: RT_XXX_WriteBack_Args
    !-- [IN] Step context / channels / source pointers / topology / csys
    INTEGER(i4) :: step_id        = 0_i4
    INTEGER(i4) :: inc_id         = 0_i4
    REAL(wp)    :: step_time      = 0.0_wp
    LOGICAL     :: is_dynamic     = .FALSE.
    LOGICAL     :: is_step_end    = .FALSE.
    INTEGER(i4) :: channels       = WB_CHAN_NODE + WB_CHAN_ELEM
    REAL(wp), POINTER :: u_new(:)   => NULL()
    REAL(wp), POINTER :: rf_new(:)  => NULL()
    REAL(wp), POINTER :: v_new(:)   => NULL()
    REAL(wp), POINTER :: a_new(:)   => NULL()
    REAL(wp), POINTER :: sigma_new(:,:) => NULL()
    REAL(wp), POINTER :: eps_new(:,:)   => NULL()
    REAL(wp), POINTER :: sdv_new(:,:)   => NULL()
    INTEGER(i4), POINTER :: node_dof_map(:,:) => NULL()
    INTEGER(i4), POINTER :: gp_elem_map(:)    => NULL()
    INTEGER(i4) :: n_nodes      = 0_i4
    INTEGER(i4) :: n_gp_total   = 0_i4
    INTEGER(i4) :: n_dof_total  = 0_i4
    INTEGER(i4) :: n_sdv        = 0_i4
    LOGICAL     :: use_local_csys = .FALSE.
    REAL(wp)    :: rot_matrix(3,3) = 0.0_wp

    !-- [OUT] Status, counts, timing
    TYPE(ErrorStatusType) :: status            ! Structured status; check %status_code
    LOGICAL               :: success = .FALSE.
    INTEGER(i4) :: n_nodes_written    = 0_i4
    INTEGER(i4) :: n_gp_written       = 0_i4
    INTEGER(i4) :: n_dof_written      = 0_i4
    INTEGER(i4) :: channels_written   = 0_i4
    REAL(wp)    :: wb_cpu_time        = 0.0_wp
  END TYPE RT_XXX_WriteBack_Args

  PUBLIC :: RT_XXX_WriteBack_Apply

CONTAINS

  !============================================================================!
  ! SUBROUTINE RT_XXX_WriteBack_Apply                     [Public, 6-param SIO]
  !
  ! Post-convergence write-back dispatcher.
  ! Called once per converged increment (before output domain).
  !
  ! Arguments (SIO-01 six-parameter form):
  !   WB_Desc   [IN]    RT_WriteBack_Desc  — write-back configuration
  !   WB_State  [INOUT] RT_WriteBack_State — progress state (updated here)
  !   WB_Ctrl   [IN]    RT_WB_Ctrl         — Algo-slot placeholder
  !   WB_Ctx    [INOUT] RT_WriteBack_Ctx   — buffer pointers
  !   args      [INOUT] RT_XXX_WriteBack_Args — unified IO bundle
  !============================================================================!
  ! Phase: WriteBack | Apply | COLD_PATH
  SUBROUTINE RT_XXX_WriteBack_Apply(WB_Desc, WB_State, WB_Ctrl, &
                                     WB_Ctx, args)
    TYPE(RT_WriteBack_Desc),      INTENT(IN)    :: WB_Desc
    TYPE(RT_WriteBack_State),     INTENT(INOUT) :: WB_State
    TYPE(RT_WB_Ctrl),             INTENT(IN)    :: WB_Ctrl
    TYPE(RT_WriteBack_Ctx),       INTENT(INOUT) :: WB_Ctx
    TYPE(RT_XXX_WriteBack_Args),  INTENT(INOUT) :: args

    REAL(wp)    :: t_cpu_start, t_cpu_end
    INTEGER(i4) :: write_trigger

    !--------------------------------------------------------------------------!
    ! Step 0: Initialise output fields on args
    !--------------------------------------------------------------------------!
    CALL init_error_status(args%status)
    args%success          = .FALSE.
    args%n_nodes_written  = 0_i4
    args%n_gp_written     = 0_i4
    args%n_dof_written    = 0_i4
    args%channels_written = 0_i4
    args%wb_cpu_time      = 0.0_wp

    CALL CPU_TIME(t_cpu_start)

    !--------------------------------------------------------------------------!
    ! Step 1: Evaluate write trigger
    !   Write frequency check (mirror of RT_WriteBack_Desc%write_frequency).
    !   Force write at step end or when write_frequency = 1.
    !--------------------------------------------------------------------------!
    IF (args%is_step_end .OR. (WB_Desc%write_frequency <= 1_i4)) THEN
      write_trigger = 1_i4
    ELSE
      IF (MOD(args%inc_id, WB_Desc%write_frequency) == 0) THEN
        write_trigger = 1_i4
      ELSE
        write_trigger = 0_i4
      END IF
    END IF

    IF (write_trigger == 0_i4) THEN
      !-- Not due this increment; skip without error
      args%success = .TRUE.
      CALL CPU_TIME(t_cpu_end)
      args%wb_cpu_time = t_cpu_end - t_cpu_start
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 2: Node results (displacement + reaction force)
    !--------------------------------------------------------------------------!
    IF (IAND(args%channels, WB_CHAN_NODE) /= 0_i4) THEN
      CALL RT_XXX_WB_NodeResults(WB_Desc, WB_Ctx, args)
      IF (args%status%status_code == IF_STATUS_ERROR) THEN
        CALL CPU_TIME(t_cpu_end)
        args%wb_cpu_time = t_cpu_end - t_cpu_start
        RETURN
      END IF
      args%channels_written = IOR(args%channels_written, WB_CHAN_NODE)
    END IF

    !--------------------------------------------------------------------------!
    ! Step 3: Element GP results (stress / strain / SDV)
    !--------------------------------------------------------------------------!
    IF (IAND(args%channels, WB_CHAN_ELEM) /= 0_i4) THEN
      CALL RT_XXX_WB_ElemResults(WB_Desc, WB_Ctx, args)
      IF (args%status%status_code == IF_STATUS_ERROR) THEN
        CALL CPU_TIME(t_cpu_end)
        args%wb_cpu_time = t_cpu_end - t_cpu_start
        RETURN
      END IF
      args%channels_written = IOR(args%channels_written, WB_CHAN_ELEM)
    END IF

    !--------------------------------------------------------------------------!
    ! Step 4: Dynamic results (velocity + acceleration)
    !--------------------------------------------------------------------------!
    IF (IAND(args%channels, WB_CHAN_DYN) /= 0_i4 .AND. args%is_dynamic) THEN
      CALL RT_XXX_WB_DynResults(WB_Desc, WB_Ctx, args)
      IF (args%status%status_code == IF_STATUS_ERROR) THEN
        CALL CPU_TIME(t_cpu_end)
        args%wb_cpu_time = t_cpu_end - t_cpu_start
        RETURN
      END IF
      args%channels_written = IOR(args%channels_written, WB_CHAN_DYN)
    END IF

    !--------------------------------------------------------------------------!
    ! Step 5: Update WB_State progress counters
    !--------------------------------------------------------------------------!
    WB_State%last_write_step      = args%step_id
    WB_State%last_write_increment = args%inc_id
    WB_State%total_writes         = WB_State%total_writes + 1_i4
    WB_State%current_write_count  = WB_State%current_write_count + 1_i4
    WB_State%last_write_time      = args%step_time
    WB_State%n_nodes_written      = args%n_nodes_written
    WB_State%n_gp_written         = args%n_gp_written
    WB_State%n_total_dofs         = args%n_dof_written
    WB_State%last_write_successful = .TRUE.

    !--------------------------------------------------------------------------!
    ! Step 6: Finalize timing
    !--------------------------------------------------------------------------!
    CALL CPU_TIME(t_cpu_end)
    args%wb_cpu_time = t_cpu_end - t_cpu_start
    args%success     = .TRUE.

  END SUBROUTINE RT_XXX_WriteBack_Apply


  !============================================================================!
  ! SUBROUTINE RT_XXX_WB_NodeResults                              [PRIVATE]
  ! Writes node displacement and reaction force from the Newton solution vector
  ! back to the L3_MD node result store (or output buffer).
  !============================================================================!
  SUBROUTINE RT_XXX_WB_NodeResults(Desc, Ctx, args)
    TYPE(RT_WriteBack_Desc),     INTENT(IN)    :: Desc
    TYPE(RT_WriteBack_Ctx),      INTENT(INOUT) :: Ctx
    TYPE(RT_XXX_WriteBack_Args),  INTENT(INOUT) :: args

    INTEGER(i4) :: in_node, idof, offset

    !-- Validate source pointers
    IF (.NOT. ASSOCIATED(args%u_new)) THEN
      args%status%status_code = IF_STATUS_WARN
      args%status%message     = 'RT_XXX_WB_NodeResults: u_new not associated'
      RETURN
    END IF

    !-- Copy displacement to Ctx buffer (pre-allocated, no ALLOCATABLE)
    !   In production: loop over node_dof_map and scatter into node result store.
    !   Stub: iterate n_nodes (topology provided via node_dof_map pointer).
    IF (ASSOCIATED(args%node_dof_map)) THEN
      DO in_node = 1, args%n_nodes
        !  In production:
        !    DO idof = 1, SIZE(args%node_dof_map, 2)
        !      global_dof = args%node_dof_map(in_node, idof)
        !      Ctx%u_buffer(in_node * dof_stride + idof) = args%u_new(global_dof)
        !    END DO
        CONTINUE
      END DO
    END IF

    !-- Reaction force write-back (conditional on Desc flag)
    IF (Desc%write_reaction .AND. ASSOCIATED(args%rf_new)) THEN
      !  In production: scatter rf_new → node reaction store
      CONTINUE
    END IF

    args%n_nodes_written = args%n_nodes
    args%n_dof_written   = args%n_dof_total

  END SUBROUTINE RT_XXX_WB_NodeResults


  !============================================================================!
  ! SUBROUTINE RT_XXX_WB_ElemResults                              [PRIVATE]
  ! Writes stress / strain / SDV from the per-GP result arrays back to the
  ! L3_MD / L4_PH element state store.
  !============================================================================!
  SUBROUTINE RT_XXX_WB_ElemResults(Desc, Ctx, args)
    TYPE(RT_WriteBack_Desc),     INTENT(IN)    :: Desc
    TYPE(RT_WriteBack_Ctx),      INTENT(INOUT) :: Ctx
    TYPE(RT_XXX_WriteBack_Args),  INTENT(INOUT) :: args

    INTEGER(i4) :: igp, icomp

    !-- Stress write-back
    IF (Desc%write_stress .AND. ASSOCIATED(args%sigma_new)) THEN
      !-- Coordinate rotation if required
      IF (args%use_local_csys) THEN
        !  In production: rotate sigma_new(igp, :) by rot_matrix before storing
        CONTINUE
      END IF
      DO igp = 1, args%n_gp_total
        !  In production:
        !    elem_id = args%gp_elem_map(igp)
        !    CALL RT_ElemState_SetStress(elem_id, igp, args%sigma_new(igp, :))
        CONTINUE
      END DO
    END IF

    !-- Strain write-back
    IF (Desc%write_strain .AND. ASSOCIATED(args%eps_new)) THEN
      DO igp = 1, args%n_gp_total
        !  In production: CALL RT_ElemState_SetStrain(elem_id, igp, args%eps_new(igp, :))
        CONTINUE
      END DO
    END IF

    !-- SDV write-back (state-dependent variables)
    IF (ASSOCIATED(args%sdv_new) .AND. args%n_sdv > 0_i4) THEN
      DO igp = 1, args%n_gp_total
        !  In production: CALL RT_ElemState_SetSDV(elem_id, igp, args%sdv_new(igp, :))
        CONTINUE
      END DO
    END IF

    args%n_gp_written = args%n_gp_total

  END SUBROUTINE RT_XXX_WB_ElemResults


  !============================================================================!
  ! SUBROUTINE RT_XXX_WB_DynResults                               [PRIVATE]
  ! Writes velocity and acceleration (dynamic analysis) back to node store.
  ! Called only when args%is_dynamic = .TRUE.
  !============================================================================!
  SUBROUTINE RT_XXX_WB_DynResults(Desc, Ctx, args)
    TYPE(RT_WriteBack_Desc),     INTENT(IN)    :: Desc
    TYPE(RT_WriteBack_Ctx),      INTENT(INOUT) :: Ctx
    TYPE(RT_XXX_WriteBack_Args),  INTENT(INOUT) :: args

    INTEGER(i4) :: in_node

    !-- Velocity write-back
    IF (Desc%write_velocity .AND. ASSOCIATED(args%v_new)) THEN
      DO in_node = 1, args%n_nodes
        !  In production: CALL RT_NodeState_SetVelocity(in_node, args%v_new(...))
        CONTINUE
      END DO
    END IF

    !-- Acceleration write-back
    IF (Desc%write_acceleration .AND. ASSOCIATED(args%a_new)) THEN
      DO in_node = 1, args%n_nodes
        !  In production: CALL RT_NodeState_SetAcceleration(in_node, args%a_new(...))
        CONTINUE
      END DO
    END IF

    !-- args%n_nodes_written already set by RT_XXX_WB_NodeResults; no double-count
    CONTINUE

  END SUBROUTINE RT_XXX_WB_DynResults

END MODULE RT_XXX_WriteBack_Proc