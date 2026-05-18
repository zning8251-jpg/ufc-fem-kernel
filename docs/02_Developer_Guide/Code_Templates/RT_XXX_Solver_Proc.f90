!==============================================================================!
! MODULE RT_Solver_XXX_XXX_Proc                               [Template v1.0]
! Layer  : L5_RT  (When — run-time orchestration)
! Domain : Solver
! Feature: XXX_XXX  ← replace with concrete solver variant name
!          e.g. RT_Solver_NR_Sparse_Proc (Newton-Raphson, sparse direct)
!
! Purpose:
!   Drives one complete Newton-Raphson iteration for a single increment.
!   Coordinates the sequence:
!     1. Assemble K, f  (delegates to Assembly domain)
!     2. Solve K·Δu = f (delegates to linear solver backend)
!     3. Update u_trial += Δu
!     4. Check convergence criteria
!     5. Return converged / cutback signal to StepDriver
!
! SIO-01  Six-parameter standard form (Principle #14):
!   (NR_Algo, NR_State, Conv_Ctx, Lin_Ctx, args)
!   NR_Algo   ← TYPE(RT_NR_Algo)           [Algo — NR configuration]
!   NR_State  ← TYPE(RT_NR_State)          [State — per-iteration NR state]
!   Conv_Ctx  ← TYPE(RT_ConvergeCrit_Ctx)  [Ctx role A — tolerances]
!   Lin_Ctx   ← TYPE(RT_LinSolv_Ctx)       [Ctx role B — linear system]
!   args       ← TYPE(RT_XXX_Solver_Args)   unified [IN]/[OUT] bundle (INOUT)
!
!   Note: Two Ctx types are used because both are independent "call-scoped
!   read-only + output" containers.  This is an explicit SIO-01 extension
!   permitted when two distinct contexts serve the single SIO Ctx role.
!
! SIO-02  Single RT_XXX_Solver_Args; [IN]/[OUT] fields in comments.
! SIO-03  No dynamic memory allocation inside SUBROUTINE body.
! SIO-04  pnewdt: Solver domain aggregates pnewdt from all physics domains
!         (passed via args%pnewdt_physics).  A cutback is signalled by
!         setting args%cutback_req = .TRUE. and args%pnewdt_new < 1.0.
! SIO-05  args%status is the structured status object; init with
!         init_error_status(...) and inspect %status_code.
!
! Newton-Raphson iteration within one increment:
!   Iteration 0 (predictor):  u_trial = u_n + Δu_predictor (ramp load)
!   Iteration 1..max_iter:
!     a. Call assembly domain  → K, f_int
!     b. f_res = f_ext - f_int  (residual)
!     c. Solve K·Δu = f_res
!     d. u_trial += Δu
!     e. Evaluate convergence norms
!   Post-loop:
!     If not converged → cutback_req = .TRUE., pnewdt_new < 1.0
!
! Module catalogue:
!   TYPE RT_XXX_Solver_Args        — unified [IN]/[OUT] bundle
!   SUBROUTINE RT_XXX_Solver_Apply — public dispatcher (6-param SIO)
!   SUBROUTINE RT_XXX_Solver_Iterate — PRIVATE single NR iteration
!   SUBROUTINE RT_XXX_Solver_CheckConv — PRIVATE convergence check
!   FUNCTION   RT_XXX_Solver_ComputeNorm — PRIVATE residual/disp norm
!==============================================================================!
MODULE RT_XXX_Solver_Proc
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_WARN, IF_STATUS_ERROR
  USE RT_Solver_Types, ONLY: RT_NR_Algo, RT_NR_State, &
                              RT_LinSolv_Ctx, RT_ConvergeCrit_Ctx, &
                              RT_NR_TANGENT_NR_TANGENT_FULL,         &
                              RT_NR_TANGENT_NR_TANGENT_MODIFIED,     &
                              RT_NR_TANGENT_NR_TANGENT_INITIAL,      &
                              RT_CONV_CONV_NORM_L2,                  &
                              RT_CONV_CONV_NORM_LINF,                &
                              RT_CONV_CONV_NORM_L1
  IMPLICIT NONE
  PRIVATE

  !-- Convergence result codes
  INTEGER(i4), PARAMETER :: CONV_YES     = 1_i4  ! Increment converged
  INTEGER(i4), PARAMETER :: CONV_NO      = 0_i4  ! Not yet converged
  INTEGER(i4), PARAMETER :: CONV_CUTBACK = -1_i4 ! Diverged, cutback needed

  !-- pnewdt constants
  REAL(wp), PARAMETER :: PNEWDT_NO_CHANGE = 1.0_wp
  REAL(wp), PARAMETER :: PNEWDT_DEFAULT_CUTBACK = 0.25_wp

  !============================================================================!
  ! TYPE RT_XXX_Solver_Args — unified per-NR-iteration bundle (Principle #14)
  !============================================================================!
  TYPE, PUBLIC :: RT_XXX_Solver_Args
    !-- [IN] Increment / DOF / pointers / physics signals / flags
    INTEGER(i4) :: step_id    = 0_i4
    INTEGER(i4) :: inc_id     = 0_i4
    REAL(wp)    :: step_time  = 0.0_wp
    REAL(wp)    :: dtime      = 0.0_wp
    INTEGER(i4) :: n_dof_total = 0_i4
    REAL(wp), POINTER :: u_trial(:)  => NULL()   ! [INOUT via pointer] trial u
    REAL(wp), POINTER :: u_old(:)    => NULL()   ! [IN] u at t_n
    REAL(wp), POINTER :: du_total(:) => NULL()   ! [INOUT via pointer] ΣΔu
    REAL(wp), POINTER :: f_ext(:)    => NULL()   ! [IN] external load
    REAL(wp)    :: pnewdt_physics = PNEWDT_NO_CHANGE  ! [IN] min pnewdt from physics
    REAL(wp)    :: res_ref_override   = 0.0_wp
    REAL(wp)    :: disp_ref_override  = 0.0_wp
    INTEGER(i4) :: lflags(6) = 0_i4
    LOGICAL     :: is_first_iter_of_inc = .FALSE.
    LOGICAL     :: severe_disc = .FALSE.

    !-- [OUT] Status, convergence, norms, linear solve, timing
    TYPE(ErrorStatusType) :: status            ! Structured status; check %status_code
    LOGICAL               :: success = .FALSE.
    INTEGER(i4) :: conv_result   = CONV_NO
    LOGICAL     :: converged     = .FALSE.
    LOGICAL     :: cutback_req   = .FALSE.
    REAL(wp)    :: pnewdt_new    = PNEWDT_NO_CHANGE
    REAL(wp)    :: res_norm_abs  = 0.0_wp
    REAL(wp)    :: res_norm_rel  = 1.0_wp
    REAL(wp)    :: disp_norm_abs = 0.0_wp
    REAL(wp)    :: disp_norm_rel = 1.0_wp
    INTEGER(i4) :: n_iter_linsolver = 0_i4
    REAL(wp)    :: achieved_lin_tol = 0.0_wp
    LOGICAL     :: linsolver_ok     = .FALSE.
    REAL(wp)    :: solver_cpu_time  = 0.0_wp
    REAL(wp)    :: linsolver_cpu_time = 0.0_wp
  END TYPE RT_XXX_Solver_Args

  PUBLIC :: RT_XXX_Solver_Apply

CONTAINS

  !============================================================================!
  ! SUBROUTINE RT_XXX_Solver_Apply                        [Public, 6-param SIO]
  !
  ! Executes one Newton-Raphson iteration for the current increment.
  ! Called repeatedly by StepDriver until converged or cutback triggered.
  !
  ! Arguments (SIO-01 six-parameter form):
  !   NR_Algo   [IN]    RT_NR_Algo           — NR algorithm parameters
  !   NR_State  [INOUT] RT_NR_State          — per-iteration state (updated)
  !   Conv_Ctx  [IN]    RT_ConvergeCrit_Ctx  — convergence tolerances
  !   Lin_Ctx   [INOUT] RT_LinSolv_Ctx       — linear system (rhs IN, du OUT)
  !   args       [INOUT]  RT_XXX_Solver_Args — unified IO bundle
  !
  ! On entry: Lin_Ctx%rhs holds the assembled residual f_res = f_ext - f_int.
  ! On exit:  Lin_Ctx%du  holds the displacement correction Δu.
  !           args%u_trial  is updated: u_trial += Δu.
  !           NR_State    is updated with new norms and iteration counter.
  !============================================================================!
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Solver_Apply(NR_Algo, NR_State, Conv_Ctx, Lin_Ctx, &
                                   args)
    TYPE(RT_NR_Algo),          INTENT(IN)    :: NR_Algo
    TYPE(RT_NR_State),         INTENT(INOUT) :: NR_State
    TYPE(RT_ConvergeCrit_Ctx), INTENT(IN)    :: Conv_Ctx
    TYPE(RT_LinSolv_Ctx),      INTENT(INOUT) :: Lin_Ctx
    TYPE(RT_XXX_Solver_Args),  INTENT(INOUT) :: args

    REAL(wp) :: t_cpu_start, t_cpu_end, t_lin_start, t_lin_end
    REAL(wp) :: res_norm, disp_norm
    INTEGER  :: conv_flag

    !--------------------------------------------------------------------------!
    ! Step 0: Initialise
    !--------------------------------------------------------------------------!
    CALL init_error_status(args%status)
    args%success          = .FALSE.
    args%conv_result      = CONV_NO
    args%converged        = .FALSE.
    args%cutback_req      = .FALSE.
    args%pnewdt_new       = PNEWDT_NO_CHANGE
    args%res_norm_abs     = 0.0_wp
    args%res_norm_rel     = 1.0_wp
    args%disp_norm_abs    = 0.0_wp
    args%disp_norm_rel    = 1.0_wp
    args%n_iter_linsolver = 0_i4
    args%achieved_lin_tol = 0.0_wp
    args%linsolver_ok     = .FALSE.
    args%solver_cpu_time  = 0.0_wp
    args%linsolver_cpu_time = 0.0_wp

    CALL CPU_TIME(t_cpu_start)

    !--------------------------------------------------------------------------!
    ! Step 1: Validate prerequisites
    !--------------------------------------------------------------------------!
    IF (.NOT. ASSOCIATED(Lin_Ctx%rhs)) THEN
      args%status%status_code = IF_STATUS_ERROR
      args%status%message     = 'RT_XXX_Solver_Apply: Lin_Ctx%rhs not associated'
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(Lin_Ctx%du)) THEN
      args%status%status_code = IF_STATUS_ERROR
      args%status%message     = 'RT_XXX_Solver_Apply: Lin_Ctx%du not associated'
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(args%u_trial)) THEN
      args%status%status_code = IF_STATUS_ERROR
      args%status%message     = 'RT_XXX_Solver_Apply: args%u_trial not associated'
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 2: Check physics pnewdt signal (pre-solve cutback gate)
    !   If any physics domain has already requested a cutback this iteration,
    !   skip the linear solve and return cutback immediately.
    !--------------------------------------------------------------------------!
    IF (args%pnewdt_physics < PNEWDT_NO_CHANGE) THEN
      args%cutback_req  = .TRUE.
      args%pnewdt_new   = args%pnewdt_physics
      args%conv_result  = CONV_CUTBACK
      NR_State%pnewdt_min  = args%pnewdt_physics
      NR_State%cutback_req = .TRUE.
      args%success = .TRUE.  ! Cutback is a valid (non-error) outcome
      CALL CPU_TIME(t_cpu_end)
      args%solver_cpu_time = t_cpu_end - t_cpu_start
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 3: Set reference norms on first iteration of the increment
    !--------------------------------------------------------------------------!
    IF (args%is_first_iter_of_inc) THEN
      res_norm = RT_XXX_Solver_ComputeNorm(Lin_Ctx%rhs, &
                                            args%n_dof_total, &
                                            Conv_Ctx%res_norm_type)
      IF (args%res_ref_override > 0.0_wp) THEN
        NR_State%res_ref = args%res_ref_override
      ELSE
        NR_State%res_ref = MAX(res_norm, Conv_Ctx%zero_force_tol)
      END IF
      NR_State%disp_ref = MAX(NR_State%disp_ref, Conv_Ctx%zero_force_tol)
    END IF

    !--------------------------------------------------------------------------!
    ! Step 4: Linear solve  K · Δu = f_res
    !--------------------------------------------------------------------------!
    CALL CPU_TIME(t_lin_start)
    CALL RT_XXX_Solver_Iterate(NR_Algo, Lin_Ctx, args)
    CALL CPU_TIME(t_lin_end)
    args%linsolver_cpu_time = t_lin_end - t_lin_start

    IF (.NOT. args%linsolver_ok) THEN
      args%status%status_code = IF_STATUS_ERROR
      args%status%message     = 'RT_XXX_Solver_Apply: linear solver failed'
      CALL CPU_TIME(t_cpu_end)
      args%solver_cpu_time = t_cpu_end - t_cpu_start
      RETURN
    END IF

    !--------------------------------------------------------------------------!
    ! Step 5: Update trial solution  u_trial += Δu
    !--------------------------------------------------------------------------!
    IF (args%n_dof_total > 0_i4) THEN
      args%u_trial(1:args%n_dof_total) = args%u_trial(1:args%n_dof_total) + &
                                        Lin_Ctx%du(1:args%n_dof_total)
      IF (ASSOCIATED(args%du_total)) THEN
        args%du_total(1:args%n_dof_total) = args%du_total(1:args%n_dof_total) + &
                                           Lin_Ctx%du(1:args%n_dof_total)
      END IF
    END IF

    !--------------------------------------------------------------------------!
    ! Step 6: Compute convergence norms
    !--------------------------------------------------------------------------!
    args%res_norm_abs  = RT_XXX_Solver_ComputeNorm(Lin_Ctx%rhs, &
                                                    args%n_dof_total, &
                                                    Conv_Ctx%res_norm_type)
    args%disp_norm_abs = RT_XXX_Solver_ComputeNorm(Lin_Ctx%du, &
                                                    args%n_dof_total, &
                                                    Conv_Ctx%disp_norm_type)
    IF (NR_State%res_ref > Conv_Ctx%zero_force_tol) THEN
      args%res_norm_rel = args%res_norm_abs / NR_State%res_ref
    ELSE
      args%res_norm_rel = args%res_norm_abs
    END IF
    IF (NR_State%disp_ref > Conv_Ctx%zero_force_tol) THEN
      args%disp_norm_rel = args%disp_norm_abs / NR_State%disp_ref
    ELSE
      args%disp_norm_rel = args%disp_norm_abs
    END IF

    !-- Update NR_State (shared across iterations)
    NR_State%iter          = NR_State%iter + 1_i4
    NR_State%n_iter_total  = NR_State%n_iter_total + 1_i4
    NR_State%res_norm_abs  = args%res_norm_abs
    NR_State%res_norm_rel  = args%res_norm_rel
    NR_State%disp_norm_abs = args%disp_norm_abs
    NR_State%disp_norm_rel = args%disp_norm_rel
    NR_State%pnewdt_min    = args%pnewdt_physics

    !--------------------------------------------------------------------------!
    ! Step 7: Check convergence
    !--------------------------------------------------------------------------!
    CALL RT_XXX_Solver_CheckConv(NR_Algo, NR_State, Conv_Ctx, args, &
                                  conv_flag)
    args%conv_result = conv_flag
    args%converged   = (conv_flag == CONV_YES)
    args%cutback_req = (conv_flag == CONV_CUTBACK)
    NR_State%converged   = args%converged
    NR_State%cutback_req = args%cutback_req
    IF (args%cutback_req) THEN
      args%pnewdt_new = NR_Algo%cutback_factor
      NR_State%n_cutbacks = NR_State%n_cutbacks + 1_i4
    END IF

    !--------------------------------------------------------------------------!
    ! Step 8: Finalise
    !--------------------------------------------------------------------------!
    CALL CPU_TIME(t_cpu_end)
    args%solver_cpu_time = t_cpu_end - t_cpu_start
    args%success = .TRUE.

  END SUBROUTINE RT_XXX_Solver_Apply


  !============================================================================!
  ! SUBROUTINE RT_XXX_Solver_Iterate                              [PRIVATE]
  ! Calls the linear solver backend: K · Δu = f_res.
  ! On entry: Lin_Ctx%rhs = residual.
  ! On exit:  Lin_Ctx%du  = displacement correction.
  !============================================================================!
  SUBROUTINE RT_XXX_Solver_Iterate(Algo, Lin_Ctx, args)
    TYPE(RT_NR_Algo),       INTENT(IN)    :: Algo
    TYPE(RT_LinSolv_Ctx),   INTENT(INOUT) :: Lin_Ctx
    TYPE(RT_XXX_Solver_Args),INTENT(INOUT) :: args

    !-- Stub: In production, dispatch to selected solver backend:
    !
    !   SELECT CASE (Lin_Ctx%method)
    !     CASE (RT_LINSOL_LINSOL_DIRECT_SPARSE)
    !       CALL RT_LinSolv_Sparse_Direct(Lin_Ctx)     ! e.g. PARDISO / MUMPS
    !     CASE (RT_LINSOL_LINSOL_ITERATIVE_CG)
    !       CALL RT_LinSolv_CG(Lin_Ctx)                ! Preconditioned CG
    !     CASE (RT_LINSOL_LINSOL_ITERATIVE_GMRES)
    !       CALL RT_LinSolv_GMRES(Lin_Ctx)             ! GMRES
    !     CASE DEFAULT
    !       CALL RT_LinSolv_Dense(Lin_Ctx)             ! Dense LU (debug only)
    !   END SELECT
    !
    !   Lin_Ctx%solved = (solver_status == 0)
    !   Lin_Ctx%n_iter_solver = solver_iters
    !   Lin_Ctx%achieved_tol  = solver_tol
    !
    !-- Placeholder: copy rhs to du (identity solve for template)
    IF (ASSOCIATED(Lin_Ctx%du) .AND. ASSOCIATED(Lin_Ctx%rhs)) THEN
      IF (Lin_Ctx%ndof > 0_i4) THEN
        Lin_Ctx%du(1:Lin_Ctx%ndof) = Lin_Ctx%rhs(1:Lin_Ctx%ndof)
      END IF
    END IF

    Lin_Ctx%solved         = .TRUE.
    Lin_Ctx%n_iter_solver  = 1_i4
    Lin_Ctx%achieved_tol   = 0.0_wp

    args%n_iter_linsolver = Lin_Ctx%n_iter_solver
    args%achieved_lin_tol = Lin_Ctx%achieved_tol
    args%linsolver_ok     = Lin_Ctx%solved

  END SUBROUTINE RT_XXX_Solver_Iterate


  !============================================================================!
  ! SUBROUTINE RT_XXX_Solver_CheckConv                            [PRIVATE]
  ! Evaluates residual and displacement convergence criteria.
  ! Returns CONV_YES, CONV_NO, or CONV_CUTBACK.
  !============================================================================!
  SUBROUTINE RT_XXX_Solver_CheckConv(Algo, NR_State, Conv, args, conv_flag)
    TYPE(RT_NR_Algo),          INTENT(IN)    :: Algo
    TYPE(RT_NR_State),         INTENT(INOUT) :: NR_State
    TYPE(RT_ConvergeCrit_Ctx), INTENT(IN)    :: Conv
    TYPE(RT_XXX_Solver_Args),   INTENT(IN)    :: args
    INTEGER(i4),               INTENT(OUT)   :: conv_flag

    LOGICAL :: res_ok, disp_ok

    conv_flag = CONV_NO

    !-- Residual criterion
    IF (Conv%res_tol_abs > 0.0_wp) THEN
      res_ok = (args%res_norm_abs <= Conv%res_tol_abs)
    ELSE
      res_ok = (args%res_norm_rel <= Conv%res_tol_rel)
    END IF

    !-- Displacement correction criterion
    IF (Conv%disp_tol_abs > 0.0_wp) THEN
      disp_ok = (args%disp_norm_abs <= Conv%disp_tol_abs)
    ELSE
      disp_ok = (args%disp_norm_rel <= Conv%disp_tol_rel)
    END IF

    !-- Both must be satisfied
    IF (res_ok .AND. disp_ok) THEN
      conv_flag = CONV_YES
      RETURN
    END IF

    !-- Cutback: max iterations exceeded
    IF (NR_State%iter >= Algo%max_iter_eq) THEN
      IF (NR_State%n_cutbacks < Algo%max_cutbacks) THEN
        conv_flag = CONV_CUTBACK
      ELSE
        !-- Too many cutbacks: terminal error
        conv_flag = CONV_CUTBACK
      END IF
      RETURN
    END IF

    !-- Severe discontinuity tolerance (looser convergence gate)
    IF (args%severe_disc) THEN
      IF (args%res_norm_rel <= Conv%severe_disc_tol) THEN
        conv_flag = CONV_YES
        NR_State%severe_disc = .TRUE.
        RETURN
      END IF
    END IF

    conv_flag = CONV_NO

  END SUBROUTINE RT_XXX_Solver_CheckConv


  !============================================================================!
  ! FUNCTION RT_XXX_Solver_ComputeNorm                            [PRIVATE]
  ! Computes the selected vector norm (L2 / L-inf / L1).
  !============================================================================!
  FUNCTION RT_XXX_Solver_ComputeNorm(vec, n, norm_type) RESULT(norm_val)
    REAL(wp),    INTENT(IN) :: vec(:)
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: norm_type
    REAL(wp)                :: norm_val

    INTEGER(i4) :: ii

    norm_val = 0.0_wp
    IF (n <= 0_i4) RETURN

    SELECT CASE (norm_type)

      CASE (RT_CONV_CONV_NORM_L2)
        !-- Euclidean / Frobenius
        norm_val = SQRT(DOT_PRODUCT(vec(1:n), vec(1:n)))

      CASE (RT_CONV_CONV_NORM_LINF)
        !-- L-infinity (max abs)
        norm_val = MAXVAL(ABS(vec(1:n)))

      CASE (RT_CONV_CONV_NORM_L1)
        !-- L1 (sum of absolute values)
        DO ii = 1, n
          norm_val = norm_val + ABS(vec(ii))
        END DO

      CASE DEFAULT
        norm_val = SQRT(DOT_PRODUCT(vec(1:n), vec(1:n)))

    END SELECT

  END FUNCTION RT_XXX_Solver_ComputeNorm

END MODULE RT_XXX_Solver_Proc