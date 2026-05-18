!===============================================================================
! MODULE: RT_Step_NR_Core
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   Core — Newton-Raphson nonlinear solution kernel
! BRIEF:  Full NR iteration loop + three-criteria convergence + line search
!         + auto time-stepping + cutback strategy.  SKELETON.
!===============================================================================
!
! Theory:  R(u) = F_int - F_ext = 0,  K_T · Δu = -R
!   Convergence: Force/Disp/Energy three-criteria check
!   Line search: α ∈ (0,1] minimizing g(α) = Δu^T · R(u+α·Δu)
!   Auto step:   Δt_{n+1} = Δt_n * α_grow / α_cut
!
! Call chain: RT_StepDriver_Execute → RunIncrement → NR iteration loop
! Design:    DESIGN_Step_HotPath.md §2-§5
! Status:    SKELETON | Created: 2026-04-28
!===============================================================================

MODULE RT_Step_NR_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR, &
                           IF_STATUS_WARN
  ! Re-export standardized 5-step Newton flow
  USE RT_Step_Execute, ONLY: RT_Step_Execute_Run, &
                              RT_Step_S1_Predict, RT_Step_S2_Assemble, &
                              RT_Step_S3_Solve, RT_Step_S4_Update, &
                              RT_Step_S5_CheckConverge
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC INTERFACES
  ! ==========================================================================
  PUBLIC :: RT_NR_Init                  ! Initialize NR solver state
  PUBLIC :: RT_NR_Iterate               ! Single NR iteration
  PUBLIC :: RT_NR_CheckConvergence      ! Three-criteria convergence check
  PUBLIC :: RT_NR_LineSearch             ! Line search for optimal step length
  PUBLIC :: RT_NR_AutoStep              ! Automatic time step adjustment
  PUBLIC :: RT_NR_Cutback               ! Time step cutback on failure
  PUBLIC :: RT_NR_Solve                 ! Unified entry: complete NR solve loop

  ! Phase 5B: Standardized 5-step Newton flow (re-exported from RT_Step_Execute)
  PUBLIC :: RT_Step_Execute_Run         ! Main NR loop (S1→S2→S3→S4→S5)
  PUBLIC :: RT_Step_S1_Predict          ! S1: Predict displacement increment
  PUBLIC :: RT_Step_S2_Assemble         ! S2: Assemble tangent + residual
  PUBLIC :: RT_Step_S3_Solve            ! S3: Solve linear increment
  PUBLIC :: RT_Step_S4_Update           ! S4: Update displacement + state
  PUBLIC :: RT_Step_S5_CheckConverge    ! S5: Convergence check

  ! ==========================================================================
  ! CONVERGENCE CRITERIA CONSTANTS
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_FORCE  = 1_i4   ! Force (residual) criterion
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_DISP   = 2_i4   ! Displacement criterion
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_ENERGY = 4_i4   ! Energy criterion (bit mask)

  ! Combination modes (align with MD_Step_Proc CONV_MODE_*)
  INTEGER(i4), PARAMETER, PUBLIC :: NR_CONV_AND      = 1_i4   ! All criteria must pass
  INTEGER(i4), PARAMETER, PUBLIC :: NR_CONV_OR       = 2_i4   ! Any criterion passes
  INTEGER(i4), PARAMETER, PUBLIC :: NR_CONV_WEIGHTED = 3_i4   ! Weighted score

  ! ==========================================================================
  ! TYPE: NR Solver Parameters
  ! ==========================================================================
  TYPE, PUBLIC :: RT_NR_Params
    ! --- Convergence tolerances ---
    REAL(wp)    :: tol_force    = 1.0E-6_wp   ! Force criterion tolerance (||R||/||F_ext||)
    REAL(wp)    :: tol_disp     = 1.0E-6_wp   ! Displacement criterion (||Δu||/||u||)
    REAL(wp)    :: tol_energy   = 1.0E-8_wp   ! Energy criterion (|Δu^T·R|/|Δu_1^T·R_1|)
    INTEGER(i4) :: max_iter     = 16_i4       ! Maximum NR iterations per increment
    INTEGER(i4) :: criteria_mask = 7_i4       ! Bitmask: 1=force, 2=disp, 4=energy
    INTEGER(i4) :: conv_mode    = NR_CONV_AND ! Combination mode

    ! --- Time stepping parameters (DESIGN §4) ---
    REAL(wp)    :: dt_min       = 1.0E-12_wp  ! Minimum time increment
    REAL(wp)    :: dt_max       = 1.0_wp      ! Maximum time increment
    REAL(wp)    :: grow_factor  = 1.5_wp      ! Growth factor after successful increment
    REAL(wp)    :: cut_factor   = 0.25_wp     ! Cutback factor on failure
    INTEGER(i4) :: max_cutbacks = 5_i4        ! Max consecutive cutbacks before failure
    INTEGER(i4) :: n_opt_iter   = 5_i4        ! Optimal iteration count for adaptive stepping

    ! --- Line search parameters (DESIGN §5) ---
    LOGICAL     :: use_line_search = .TRUE.   ! Enable line search
    REAL(wp)    :: ls_tol       = 0.5_wp      ! Armijo condition parameter c1
    INTEGER(i4) :: ls_max_iter  = 10_i4       ! Max line search iterations

    ! --- Strategy selection (DESIGN §2.3) ---
    LOGICAL     :: use_modified_nr = .FALSE.  ! Modified NR (tangent only at iter 1)

    ! --- BFGS quasi-Newton parameters (adapted from RT_NLSolver_QuasiNewton) ---
    LOGICAL     :: use_bfgs       = .FALSE.   ! Enable BFGS secant update (skip tangent reassembly)
    INTEGER(i4) :: bfgs_memory    = 5_i4      ! L-BFGS memory depth (# stored pairs)
    REAL(wp)    :: bfgs_restart_tol = 1.0E-2_wp ! Restart BFGS if |s^T y| < tol*|s||y|

    ! --- Arc-length (Riks) parameters (adapted from RT_NLSolver_ArcLen) ---
    LOGICAL     :: use_arc_length = .FALSE.    ! Enable arc-length control
    REAL(wp)    :: arc_length_init = 0.01_wp   ! Initial arc-length Δs
    REAL(wp)    :: arc_min        = 1.0E-4_wp  ! Min arc-length
    REAL(wp)    :: arc_max        = 1.0_wp     ! Max arc-length
    REAL(wp)    :: psi_arc        = 1.0_wp     ! Scaling factor ψ (1=spherical, 0=cylindrical)

    ! --- Convergence weight factors (for NR_CONV_WEIGHTED mode) ---
    REAL(wp)    :: w_force        = 0.5_wp     ! Weight for force criterion
    REAL(wp)    :: w_disp         = 0.3_wp     ! Weight for displacement criterion
    REAL(wp)    :: w_energy       = 0.2_wp     ! Weight for energy criterion
    REAL(wp)    :: weighted_tol   = 0.8_wp     ! Threshold: score > tol → converged

    ! --- Divergence detection ---
    REAL(wp)    :: diverge_ratio  = 1.0E+4_wp  ! |R|/|R_0| > ratio → diverged
  END TYPE RT_NR_Params

  ! ==========================================================================
  ! TYPE: NR Solver Runtime Status
  ! ==========================================================================
  TYPE, PUBLIC :: RT_NR_Status
    INTEGER(i4) :: n_iter       = 0_i4        ! Current iteration count
    INTEGER(i4) :: n_cutbacks   = 0_i4        ! Consecutive cutback count
    INTEGER(i4) :: total_iters  = 0_i4        ! Total iterations across increments
    REAL(wp)    :: force_norm   = 0.0_wp      ! Current ||R||/||F_ext||
    REAL(wp)    :: disp_norm    = 0.0_wp      ! Current ||Δu||/||u||
    REAL(wp)    :: energy_norm  = 0.0_wp      ! Current |Δu^T·R|/|Δu_1^T·R_1|
    REAL(wp)    :: energy_ref   = 0.0_wp      ! First iteration energy (reference)
    REAL(wp)    :: dt_current   = 0.0_wp      ! Current time step size
    LOGICAL     :: converged    = .FALSE.      ! Convergence flag
    LOGICAL     :: diverged     = .FALSE.      ! Divergence flag
  END TYPE RT_NR_Status

CONTAINS

  !---------------------------------------------------------------------------
  ! RT_NR_Init: Initialize NR solver state for a new step/increment
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_Init(params, nr_status, dt_initial, status)
    TYPE(RT_NR_Params), INTENT(IN)    :: params      ! [IN] Solver parameters
    TYPE(RT_NR_Status), INTENT(OUT)   :: nr_status   ! [OUT] Solver status (reset)
    REAL(wp), INTENT(IN)              :: dt_initial   ! [IN] Initial time increment
    TYPE(ErrorStatusType), INTENT(OUT) :: status      ! [OUT] Error status

    CALL init_error_status(status)

    nr_status%n_iter      = 0_i4
    nr_status%n_cutbacks  = 0_i4
    nr_status%total_iters = 0_i4
    nr_status%force_norm  = 0.0_wp
    nr_status%disp_norm   = 0.0_wp
    nr_status%energy_norm = 0.0_wp
    nr_status%energy_ref  = 0.0_wp
    nr_status%dt_current  = dt_initial
    nr_status%converged   = .FALSE.
    nr_status%diverged    = .FALSE.

    ! Validate parameters
    IF (params%max_iter < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_NR_Init: max_iter must be >= 1'
      RETURN
    END IF
    IF (params%dt_min >= params%dt_max) THEN
      status%status_code = IF_STATUS_WARN
      status%message = 'RT_NR_Init: dt_min >= dt_max, check time step bounds'
    END IF

  END SUBROUTINE RT_NR_Init

  !---------------------------------------------------------------------------
  ! RT_NR_Iterate: Single Newton-Raphson iteration
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Step_HotPath.md §2.2
  ! Algorithm (one NR iteration):
  !   Given current displacement u and assembled K_T, R:
  !   1. Check convergence (if not first iter)
  !   2. Solve K_T · Δu = -R
  !   3. Line search: find optimal α
  !   4. Update: u = u + α · Δu
  !   5. Update constitutive state
  !
  ! Note: This is a SINGLE iteration kernel. Assembly (K_T, R) and linear
  !   solve are external responsibilities — called by RT_NR_Solve or
  !   by the RunIncrement loop in RT_Step_Exec.f90.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_Iterate(u, du, R, F_ext, alpha, iter, params, nr_status, status)
    REAL(wp), INTENT(INOUT) :: u(:)       ! [INOUT] Displacement vector (updated: u += α*du)
    REAL(wp), INTENT(IN)    :: du(:)      ! [IN] Displacement increment from linear solve
    REAL(wp), INTENT(IN)    :: R(:)       ! [IN] Residual vector R = F_int - F_ext
    REAL(wp), INTENT(IN)    :: F_ext(:)   ! [IN] External force vector
    REAL(wp), INTENT(IN)    :: alpha      ! [IN] Line search step length
    INTEGER(i4), INTENT(IN) :: iter       ! [IN] Current iteration number
    TYPE(RT_NR_Params), INTENT(IN) :: params     ! [IN] Solver parameters
    TYPE(RT_NR_Status), INTENT(INOUT) :: nr_status ! [INOUT] Solver status
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    INTEGER(i4) :: n_dof, i

    n_dof = SIZE(u)
    nr_status%n_iter = iter

    ! Step 1: Update displacement: u = u + α · Δu
    DO i = 1, n_dof
      u(i) = u(i) + alpha * du(i)
    END DO

    ! Step 2: Record energy for first iteration (reference for energy criterion)
    IF (iter == 1_i4) THEN
      nr_status%energy_ref = ABS(DotProd(du, R, n_dof))
      IF (nr_status%energy_ref < 1.0E-30_wp) THEN
        nr_status%energy_ref = 1.0_wp  ! Prevent division by zero
      END IF
    END IF

    ! Step 3: Update convergence norms
    CALL RT_NR_CheckConvergence(R, du, u, F_ext, params, nr_status, status)

  END SUBROUTINE RT_NR_Iterate

  !---------------------------------------------------------------------------
  ! RT_NR_CheckConvergence: Three-criteria convergence check
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Step_HotPath.md §3
  ! Criteria:
  !   Force:  ||R||_2 / max(||F_ext||_2, ε_min) < tol_force
  !   Disp:   ||Δu||_2 / max(||u||_2, ε_min)   < tol_disp
  !   Energy: |Δu^T · R| / |Δu_1^T · R_1|      < tol_energy
  !
  ! Combination modes:
  !   AND:      all active criteria must be satisfied
  !   OR:       any active criterion is sufficient
  !   WEIGHTED: weighted average (future extension)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_CheckConvergence(R, du, u, F_ext, params, nr_status, status)
    REAL(wp), INTENT(IN) :: R(:)           ! [IN] Residual vector
    REAL(wp), INTENT(IN) :: du(:)          ! [IN] Displacement increment
    REAL(wp), INTENT(IN) :: u(:)           ! [IN] Current displacement
    REAL(wp), INTENT(IN) :: F_ext(:)       ! [IN] External force vector
    TYPE(RT_NR_Params), INTENT(IN) :: params     ! [IN] Solver parameters
    TYPE(RT_NR_Status), INTENT(INOUT) :: nr_status ! [INOUT] Updated norms
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    REAL(wp) :: R_norm, F_norm, du_norm, u_norm, energy_inc
    REAL(wp), PARAMETER :: eps_min = 1.0E-30_wp
    INTEGER(i4) :: n_dof
    LOGICAL :: force_ok, disp_ok, energy_ok

    n_dof = SIZE(R)
    force_ok  = .TRUE.
    disp_ok   = .TRUE.
    energy_ok = .TRUE.

    ! --- Force criterion: ||R|| / ||F_ext|| < tol ---
    IF (IAND(params%criteria_mask, CONV_FORCE) /= 0_i4) THEN
      R_norm = Norm2Vec(R, n_dof)
      F_norm = MAX(Norm2Vec(F_ext, n_dof), eps_min)
      nr_status%force_norm = R_norm / F_norm
      force_ok = (nr_status%force_norm < params%tol_force)
    END IF

    ! --- Displacement criterion: ||Δu|| / ||u|| < tol ---
    IF (IAND(params%criteria_mask, CONV_DISP) /= 0_i4) THEN
      du_norm = Norm2Vec(du, n_dof)
      u_norm  = MAX(Norm2Vec(u, n_dof), eps_min)
      nr_status%disp_norm = du_norm / u_norm
      disp_ok = (nr_status%disp_norm < params%tol_disp)
    END IF

    ! --- Energy criterion: |Δu^T · R| / |Δu_1^T · R_1| < tol ---
    IF (IAND(params%criteria_mask, CONV_ENERGY) /= 0_i4) THEN
      energy_inc = ABS(DotProd(du, R, n_dof))
      IF (nr_status%energy_ref > eps_min) THEN
        nr_status%energy_norm = energy_inc / nr_status%energy_ref
      ELSE
        nr_status%energy_norm = 0.0_wp
      END IF
      energy_ok = (nr_status%energy_norm < params%tol_energy)
    END IF

    ! --- Combine criteria ---
    SELECT CASE (params%conv_mode)
    CASE (NR_CONV_AND)
      nr_status%converged = (force_ok .AND. disp_ok .AND. energy_ok)
    CASE (NR_CONV_OR)
      nr_status%converged = (force_ok .OR. disp_ok .OR. energy_ok)
    CASE (NR_CONV_WEIGHTED)
      ! Weighted combination scoring (DESIGN §3.3)
      ! Source: adapted from MD_Conv_Check combination modes in MD_Step_Proc
      ! Score = w_f * I(force_ok) + w_d * I(disp_ok) + w_e * I(energy_ok)
      ! Converged when score >= weighted_tol  (default 0.8)
      BLOCK
        REAL(wp) :: w_score, w_total
        w_total = params%w_force + params%w_disp + params%w_energy
        IF (w_total < 1.0E-30_wp) w_total = 1.0_wp
        w_score = 0.0_wp
        IF (force_ok)  w_score = w_score + params%w_force
        IF (disp_ok)   w_score = w_score + params%w_disp
        IF (energy_ok) w_score = w_score + params%w_energy
        w_score = w_score / w_total  ! Normalize to [0,1]
        nr_status%converged = (w_score >= params%weighted_tol)
      END BLOCK
    CASE DEFAULT
      nr_status%converged = (force_ok .AND. disp_ok .AND. energy_ok)
    END SELECT

  END SUBROUTINE RT_NR_CheckConvergence

  !---------------------------------------------------------------------------
  ! RT_NR_LineSearch: Line search for optimal step length α
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Step_HotPath.md §5
  ! Algorithm:
  !   g(α) = Δu^T · R(u + α·Δu)
  !   g(0) = Δu^T · R(u)  (initial slope)
  !   Armijo condition: |g(α)| ≤ c1 * |g(0)|
  !   Bisection: α = α * 0.5 if not satisfied
  !
  ! Note: This is a simplified in-module implementation.
  !   Production code uses RT_NLSolver_LineSearch in RT_Solv_Nonlin.f90.
  !   Typical c1 = 1e-4, max iterations = 10
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_LineSearch(du, R_current, g0, params, alpha_out, status)
    REAL(wp), INTENT(IN)  :: du(:)           ! [IN] Displacement increment
    REAL(wp), INTENT(IN)  :: R_current(:)    ! [IN] Residual at current trial point
    REAL(wp), INTENT(IN)  :: g0              ! [IN] g(0) = Δu^T · R(u) (initial slope)
    TYPE(RT_NR_Params), INTENT(IN) :: params ! [IN] Solver parameters
    REAL(wp), INTENT(OUT) :: alpha_out       ! [OUT] Optimal step length
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    REAL(wp) :: g1
    INTEGER(i4) :: n_dof

    n_dof = SIZE(du)

    ! Current energy product: g(α) = Δu^T · R(u + α·Δu)
    g1 = DotProd(du, R_current, n_dof)

    ! Armijo backtracking line search (DESIGN §5)
    ! Source: adapted from RT_NLSolver_LineSearch in RT_Solv_Nonlin.f90
    !   g(α) = Δu^T · R(u + α·Δu)
    !   Armijo condition: |g(α)| ≤ c1 * |g(0)|    (c1 = ls_tol, default 0.5)
    !   Backtrack: α *= 0.5 per iteration until satisfied or α < α_min
    !
    ! Note: Full line search with residual re-evaluation requires external
    !   assembly callback. Production code uses RT_NLSolver_LineSearch.
    !   This in-module version uses the current residual R_current to
    !   perform a secant-based α estimate with Armijo guard.
    BLOCK
      REAL(wp) :: alpha_trial, rho, alpha_min_ls
      REAL(wp), PARAMETER :: c1_armijo = 1.0E-4_wp  ! Armijo constant (standard)
      INTEGER(i4) :: ls_iter

      rho = 0.5_wp              ! Backtrack factor
      alpha_min_ls = 0.01_wp    ! Minimum allowable step length
      alpha_trial = 1.0_wp      ! Start with full Newton step

      ! Quick accept: if Armijo is already satisfied at full step
      IF (ABS(g1) <= params%ls_tol * ABS(g0)) THEN
        alpha_out = 1.0_wp
      ELSE
        ! Secant-based initial estimate: α = -g(0) / (g(α) - g(0))
        ! Then refine via backtracking if needed
        IF (ABS(g1 - g0) > 1.0E-30_wp) THEN
          alpha_trial = MIN(1.0_wp, MAX(alpha_min_ls, -g0 / (g1 - g0)))
        ELSE
          alpha_trial = 0.5_wp
        END IF

        ! Backtracking loop (without residual re-evaluation)
        ! Uses interpolation: g(α) ≈ g(0) + α * (g(1) - g(0))
        ! Armijo: |g_interp(α)| ≤ c1 * α * |g(0)|
        DO ls_iter = 1, params%ls_max_iter
          ! Linearly interpolated energy product at α_trial
          ! g_interp = (1 - α) * g0 + α * g1
          ! Armijo condition on interpolated value
          IF (ABS((1.0_wp - alpha_trial) * g0 + alpha_trial * g1) &
              <= c1_armijo * alpha_trial * ABS(g0)) THEN
            EXIT  ! Armijo satisfied
          END IF
          alpha_trial = alpha_trial * rho
          IF (alpha_trial < alpha_min_ls) THEN
            alpha_trial = alpha_min_ls
            EXIT
          END IF
        END DO

        alpha_out = alpha_trial
      END IF
    END BLOCK

  END SUBROUTINE RT_NR_LineSearch

  !---------------------------------------------------------------------------
  ! RT_NR_AutoStep: Automatic time step adjustment after successful increment
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Step_HotPath.md §4.1, §4.3
  ! Algorithm:
  !   If n_iter ≤ n_opt/2: aggressive growth (dt * 2.0)
  !   If n_iter ≤ n_opt:   mild growth      (dt * 1.5)
  !   If n_iter > n_opt:   hold             (dt * 1.0)
  !   Always clamp to [dt_min, dt_max]
  !
  ! Aligns with: MD_TimeIncrement_Calc in MD_Step_Proc
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_AutoStep(nr_status, params, dt_new, status)
    TYPE(RT_NR_Status), INTENT(IN)  :: nr_status    ! [IN] Solver status (n_iter)
    TYPE(RT_NR_Params), INTENT(IN)  :: params       ! [IN] Solver parameters
    REAL(wp), INTENT(OUT)           :: dt_new       ! [OUT] New time step size
    TYPE(ErrorStatusType), INTENT(INOUT) :: status  ! [INOUT] Error status

    REAL(wp) :: alpha_grow
    INTEGER(i4) :: n_half

    n_half = params%n_opt_iter / 2_i4

    ! Growth factor based on iteration efficiency
    IF (nr_status%n_iter <= n_half) THEN
      ! Very efficient: aggressive growth
      alpha_grow = 2.0_wp
    ELSE IF (nr_status%n_iter <= params%n_opt_iter) THEN
      ! Normal: mild growth
      alpha_grow = params%grow_factor   ! Default 1.5
    ELSE
      ! Many iterations: hold steady
      alpha_grow = 1.0_wp
    END IF

    ! Apply growth and clamp
    dt_new = nr_status%dt_current * alpha_grow
    dt_new = MIN(dt_new, params%dt_max)
    dt_new = MAX(dt_new, params%dt_min)

    ! Reset cutback counter after successful increment
    ! (caller should set nr_status%n_cutbacks = 0)

  END SUBROUTINE RT_NR_AutoStep

  !---------------------------------------------------------------------------
  ! RT_NR_Cutback: Time step cutback on convergence failure
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Step_HotPath.md §4.2
  ! Algorithm:
  !   dt_new = dt_current * cut_factor  (typical: 0.25)
  !   If dt_new < dt_min → step failed
  !   If n_cutbacks >= max_cutbacks → step failed
  !
  ! Aligns with: RT_StepDriver_Execute cutback logic (L289-291)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_Cutback(nr_status, params, dt_new, step_failed, status)
    TYPE(RT_NR_Status), INTENT(INOUT) :: nr_status  ! [INOUT] Updated cutback count
    TYPE(RT_NR_Params), INTENT(IN)    :: params     ! [IN] Solver parameters
    REAL(wp), INTENT(OUT)             :: dt_new     ! [OUT] New (reduced) time step
    LOGICAL,  INTENT(OUT)             :: step_failed ! [OUT] TRUE if step cannot continue
    TYPE(ErrorStatusType), INTENT(INOUT) :: status  ! [INOUT] Error status

    step_failed = .FALSE.

    ! Increment cutback counter
    nr_status%n_cutbacks = nr_status%n_cutbacks + 1_i4

    ! Check cutback limit
    IF (nr_status%n_cutbacks > params%max_cutbacks) THEN
      step_failed = .TRUE.
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_NR_Cutback: exceeded max consecutive cutbacks'
      dt_new = nr_status%dt_current
      RETURN
    END IF

    ! Apply cutback factor
    dt_new = nr_status%dt_current * params%cut_factor
    IF (dt_new < params%dt_min) THEN
      step_failed = .TRUE.
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_NR_Cutback: dt below minimum allowable'
      dt_new = params%dt_min
      RETURN
    END IF

    nr_status%dt_current = dt_new

  END SUBROUTINE RT_NR_Cutback

  !---------------------------------------------------------------------------
  ! RT_NR_Solve: Unified entry — complete NR solve loop for one increment
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Step_HotPath.md §2.2 + §6.1
  ! Algorithm (complete NR loop):
  !   1. For iter = 1 to max_iter:
  !      a. Assemble K_T and R    [external callback]
  !      b. Check convergence (3 criteria)
  !      c. If converged → return success
  !      d. Solve K_T · Δu = -R  [external callback]
  !      e. Line search → α
  !      f. u += α · Δu
  !      g. Update material state [external callback]
  !   2. If not converged → attempt cutback
  !
  ! Note: Assembly, linear solve, and material update are EXTERNAL
  !   responsibilities. This skeleton documents the loop structure.
  !   Production execution goes through RT_NLSolver_NewtonRaph in
  !   RT_Solv_Nonlin.f90, called from RunIncrement in RT_Step_Exec.f90.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_NR_Solve(u, R, F_ext, du, params, nr_status, status)
    REAL(wp), INTENT(INOUT) :: u(:)         ! [INOUT] Displacement vector
    REAL(wp), INTENT(INOUT) :: R(:)         ! [INOUT] Residual (assembled externally)
    REAL(wp), INTENT(IN)    :: F_ext(:)     ! [IN] External force vector
    REAL(wp), INTENT(INOUT) :: du(:)        ! [INOUT] Displacement increment (from linear solve)
    TYPE(RT_NR_Params), INTENT(IN)    :: params     ! [IN] Solver parameters
    TYPE(RT_NR_Status), INTENT(INOUT) :: nr_status  ! [INOUT] Solver status
    TYPE(ErrorStatusType), INTENT(INOUT) :: status  ! [INOUT] Error status

    INTEGER(i4) :: iter, n_dof
    REAL(wp) :: alpha, g0

    n_dof = SIZE(u)
    nr_status%converged = .FALSE.
    nr_status%diverged  = .FALSE.

    ! ====================================================================
    ! NR ITERATION LOOP
    ! (Production loop: RT_NLSolver_NewtonRaph in RT_Solv_Nonlin.f90)
    ! Source: RT_NLSolver_NewtonRaph L875-L928
    ! ====================================================================
    DO iter = 1, params%max_iter

      ! Step (a): Assembly of K_T and R  [EXTERNAL RESPONSIBILITY]
      ! >>> Delegation: RT_Asm_Complete(asm_ctx) in RT_Ctx_API
      ! >>> Called by RunIncrement in RT_Step_Exec.f90 (L434-L454)
      ! >>> R = F_int(u) - F_ext  (assembled externally before entry)
      ! >>> K_T assembled via RT_Asm_ComputeTangent (RT_Asm_Solv)
      ! >>> In standalone mode, caller must supply pre-assembled R in R(:)

      ! Step (b): Convergence check
      CALL RT_NR_CheckConvergence(R, du, u, F_ext, params, nr_status, status)

      ! Step (c): Return if converged
      IF (nr_status%converged) THEN
        nr_status%n_iter = iter
        nr_status%total_iters = nr_status%total_iters + iter
        RETURN
      END IF

      ! Step (d): Linear solve K_T · Δu = -R  [EXTERNAL RESPONSIBILITY]
      ! >>> Delegation: RT_LinearSolver_Solv(solver, K_dense, rhs, du, status)
      ! >>> Source: RT_Solv_Lin.f90, called in RT_NLSolver_NewtonRaph L891-L892
      ! >>> In standalone mode, caller must supply pre-solved du in du(:)

      ! Step (e): Line search
      IF (params%use_line_search) THEN
        g0 = DotProd(du, R, n_dof)
        ! For full line search, need residual re-evaluation at trial point.
        ! Here use simplified single-step estimate.
        CALL RT_NR_LineSearch(du, R, g0, params, alpha, status)
      ELSE
        alpha = 1.0_wp   ! Full Newton step
      END IF

      ! Step (f): Update displacement
      CALL RT_NR_Iterate(u, du, R, F_ext, alpha, iter, params, nr_status, status)

      ! Step (f.1): Divergence detection (DESIGN §3.4)
      ! Source: adapted from RT_NLSolver_NewtonRaph convergence logic
      ! If residual grows beyond diverge_ratio * initial residual → abort
      IF (nr_status%force_norm > params%diverge_ratio) THEN
        nr_status%diverged = .TRUE.
        nr_status%n_iter = iter
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_NR_Solve: divergence detected (residual ratio exceeded)'
        RETURN
      END IF

      ! Step (g): Update material state  [EXTERNAL RESPONSIBILITY]
      ! >>> Delegation: material state update occurs inside RT_Asm_ComputeResidual
      ! >>>   which calls element-level stress recovery (L3 → L4_PH → L5_RT chain)
      ! >>> Source: RT_NLSolver_NewtonRaph L878-L889 triggers tangent+residual
      ! >>>   which internally updates constitutive state via B^T·σ integration
      ! >>> In standalone mode, caller must update material state externally

    END DO

    ! Max iterations reached without convergence
    nr_status%converged = .FALSE.
    nr_status%n_iter = params%max_iter
    status%status_code = IF_STATUS_WARN
    status%message = 'RT_NR_Solve: max iterations reached without convergence'

  END SUBROUTINE RT_NR_Solve

  !==========================================================================
  ! PRIVATE HELPER FUNCTIONS
  !==========================================================================

  !---------------------------------------------------------------------------
  ! Norm2Vec: L2 norm of a vector
  !---------------------------------------------------------------------------
  PURE FUNCTION Norm2Vec(v, n) RESULT(nrm)
    REAL(wp), INTENT(IN) :: v(:)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp) :: nrm
    INTEGER(i4) :: i
    nrm = 0.0_wp
    DO i = 1, n
      nrm = nrm + v(i) * v(i)
    END DO
    nrm = SQRT(nrm)
  END FUNCTION Norm2Vec

  !---------------------------------------------------------------------------
  ! DotProd: Dot product of two vectors
  !---------------------------------------------------------------------------
  PURE FUNCTION DotProd(a, b, n) RESULT(dp)
    REAL(wp), INTENT(IN) :: a(:), b(:)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp) :: dp
    INTEGER(i4) :: i
    dp = 0.0_wp
    DO i = 1, n
      dp = dp + a(i) * b(i)
    END DO
  END FUNCTION DotProd

END MODULE RT_Step_NR_Core
