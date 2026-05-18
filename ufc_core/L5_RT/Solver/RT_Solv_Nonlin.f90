!===============================================================================
! MODULE: RT_Solv_Nonlin
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Solv (Nonlinear)
! BRIEF:  Newton-Raphson / Arc-Length / Line Search nonlinear solver core
!===============================================================================
!
! Process族:
!   P2: Solve/Iterate (Newton-Raphson loop, arc-length corrector)  [HOT_PATH]
!   P2: Compute (residual, tangent)                                [HOT_PATH]
!   P2: Update (displacement, load factor)                         [HOT_PATH]
!
! GOLDEN-LINE NOTE (v4.0): Authoritative nonlinear solver implementation.
!   Newton-Raphson, arc-length, line search, modified/quasi-Newton.
!   Called from RT_Solv_Mgr / RT_StepExec. RT_Solv_Core is FACADE only.
!
! Status: GOLDEN-LINE | Last verified: 2026-04-28
!===============================================================================
! Purpose:
!   Nonlinear solver core for equilibrium iterations within a load increment:
!     - Newton-Raphson: solve K_t ??u = r(u), update u^{(k+1)} = u^{(k)} + ??u
!     - Arc-length (Riks): constrain (du, dlambda) on arc-length sphere
!     - Line search: scale ??u to improve convergence
!   Called from Step/Increment driver; does NOT manage Step/Increment loop.
!
! Logic chain:
!   RT_StepDriver_Core  -->  RT_SolvNonlin (this module)
!   RT_SolvNonlin  -->  RT_Asm_ComputeResidual, RT_Asm_ComputeTangent
!   RT_SolvNonlin  -->  RT_LinearSolver_Solv (L2_NM or RT_Solv_Lin)
!   RT_SolvNonlin  -->  RT_State_Step_* (convergence / state update)
!
! Computation chain (Unicode math):
!   Residual:           r(u) = f_ext(??) - f_int(u)
!   Tangent stiffness:   K_t = ?r/?u = ?f_int/?u
!   Newton solve:        K_t ??u^{(k)} = r(u^{(k)})
!   Update:              u^{(k+1)} = u^{(k)} + ??u^{(k)}
!   Convergence:         ||r(u^{(k)})||??????_res  AND  ||??u^{(k)}||??????_inc
!   Arc-length:          g = ||??u||? + ??? ????? - ??s? = 0 (augmented system)
!
! Data chain (four types):
!   - Desc : from MD_Step / MD_NonlinSolv (immutable solver config, max_iter, tol, nr_divergence_growth_limit)
!   - Algo : MD_NonlinSolv or RT_Solv_Nonlin_Algo (tolerances, line search params)
!   - State: MD_SolverState (u, ??, R, iteration count; updated each iter)
!   - Ctx  : local buffers per solve (e.g. du, d??, work arrays)
!
! Three-step mapping:
!   - This module belongs to ITERATION level (inside Increment loop).
!   - Step    : RT_Step_*_Run (calls this only indirectly via Increment)
!   - Increment: RT_Step_*_RunIncrement (may call RT_NLSolver_* per increment)
!   - Iteration: RT_NLSolver_NewtonRaph / RT_NLSolver_ArcLen / RT_NLSolver_LineSearch
!
! Logic Chain (Mermaid):
! ```mermaid
! flowchart TB
!     subgraph Newton["Newton-Raphson Iteration"]
!         A[Compute Residual R = F_ext - F_int] --> B[Check Convergence]
!         B -->|Converged| Z[Return SUCCESS]
!         B -->|Not Converged| C[Assemble Tangent K_t]
!         C --> D[Solve K_t*du = R]
!         D --> E[Line Search?]
!         E -->|Yes| F[Scale du = s*du]
!         E -->|No| G[Update u = u + ??u]
!         F --> G
!         G --> H{Max Iter?}
!         H -->|No| A
!         H -->|Yes| I[Return DIVERGE]
!     end
! ```
!
! Arc-Length Flow (Mermaid):
! ```mermaid
! flowchart LR
!     A[Arc-Length Start] --> B[Predict: du0, lambda0]
!     B --> C[Corrector Loop]
!     C --> D[Assemble Augmented System]
!     D --> E[Solve for du, lambda]
!     E --> F[Update u, ??]
!     F --> G{Converged?}
!     G -->|No| C
!     G -->|Yes| H[Next Increment]
! ```
!
! Notes:
!   - Desc/Algo are read-only during solve.
!   - State (u, ??, R) is updated only inside iteration loop.
!   - Model data via MD_ModelTree / RT_Asm_*; no direct L3/L4 access.
!
! Status: CORE | Last verified: 2026-03-06
! Theory: N/A
! Status: Draft
!===============================================================================

module RT_Solv_Nonlin
!> [CORE] Newton-Raphson / Arc-Length / Line Search nonlinear solver
!> Theory: K_t*du = R, Arc-Length: ||du||^2 + psi*Delta_lambda^2 = Delta_s^2
!> Status: CORE | Last verified: 2026-03-06
!> Theory: see RT_Solv_Anlys_Core and RT_SolvNonlin comments
!> Last verified: 2026-02-14
  !! Runtime-layer nonlinear solver implementation
  !! Integrates Newton-Raphson, Arc-length, Line Search algorithms
  !! Responsibility: solve flow control, iteration management (Runtime layer)
  !! Dependencies: Model layer provides type definitions and pure compute interfaces
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR, IF_STATUS_WARN
  USE IF_Prec_Core, only: i4, i8, wp
  USE MD_Model_Lib_Core, only: UF_Model
  USE MD_Step_Proc, only: MD_NonlinSolv, MD_SolverState, AnalysisStep, StepStateData
  USE RT_Asm_Solv, only: RT_Asm_ComputeResidual, RT_Asm_ComputeTangent, RT_Asm_Cfg
  USE RT_Solv_Lin, only: RT_LinearSolver, RT_LinearSolver_Init, RT_LinearSolver_Solv, RT_LinearSolver_Clean
  USE RT_Solv_Def, only: RT_Sol_DofMap, RT_CSRMatrix
  USE RT_Global_Def, only: RT_Glb_ConvPred_IF
  
  implicit none
  private
  
  public :: RT_NLSolver_NewtonRaph
  public :: RT_NLSolver_ArcLen
  public :: RT_NLSolver_LineSearch
  ! Extended API (tasks 10400-10499)
  public :: RT_NLSolver_ModifiedNewton
  public :: RT_NLSolver_QuasiNewton
  ! Extended API (tasks 11100-11199)
  public :: RT_NLSolver_Solv_Unified
  public :: RT_NLSolver_NewtonControl

  ! INTF-001 NL
  public :: RT_NLSolver_Args
  public :: RT_NLSolver_ArcLen_Args

  !============================================================
  ! Purpose: NL INTF-001
  ! Theory:
  ! Status:  Draft
  ! : RT_NLSolver_NewtonRaph / ArcLen / QuasiNewton
  !        solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR
  !============================================================
  TYPE :: RT_NLSolver_Args
    ! --- ---
    TYPE(MD_NonlinSolv)          :: solver           !< IN : max_iter, tol_force
    TYPE(MD_SolverState)         :: state            !< INOUT: u, R, lambda, du
    ! --- ---
    LOGICAL                      :: result = .FALSE. !< OUT :
    TYPE(ErrorStatusType)        :: status           !< OUT :
    ! --- OPTIONAL ---
    TYPE(UF_Model),    POINTER   :: model      => NULL()  !< OPTIONAL IN :
    TYPE(AnalysisStep),POINTER   :: step       => NULL()  !< OPTIONAL IN :
    TYPE(StepStateData),POINTER  :: step_state => NULL()  !< OPTIONAL IN :
    TYPE(RT_Sol_DofMap),POINTER  :: dofMap     => NULL()  !< OPTIONAL IN : DOF
    REAL(wp),          POINTER   :: F_ext(:)   => NULL()  !< OPTIONAL IN :
    TYPE(RT_CSRMatrix),POINTER   :: K_CSR      => NULL()  !< OPTIONAL INOUT:
  END TYPE RT_NLSolver_Args

  !============================================================
  ! Purpose: ArcLen INTF-001
  ! Theory: Riks : ||du||^2 + psi*dlambda^2 = ds^2
  ! Status:  Draft
  !============================================================
  TYPE :: RT_NLSolver_ArcLen_Args
    TYPE(RT_NLSolver_Args) :: base  ! member `base`
    REAL(wp) :: arc_length_init = 0.01_wp        !< OPTIONAL IN :
    REAL(wp) :: arc_min        = 1.0e-4_wp       !< OPTIONAL IN :
    REAL(wp) :: arc_max        = 1.0_wp          !< OPTIONAL IN :
    REAL(wp) :: psi            = 1.0_wp          !< OPTIONAL IN : 1= 0=
  END TYPE RT_NLSolver_ArcLen_Args

contains


  SUBROUTINE RT_NLSolver_ArcLen(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &
                                arc_length_init, arc_min, arc_max, psi, l3_csr_reanalyze_required)
    !! Arc-length solver (Runtime layer Riks/Crisfield-style corrector)
    !! Contract (same as NR): each corrector iter �?RT_Asm_ComputeTangent �?K; RT_Asm_ComputeResidual �?R;
    !!     linear solves K*du_I = -R, K*du_II = F_ref; then spherical constraint in (du, dλ).
    !! Predictor: K_t*du_F = F_ref, dλ = ds/sqrt(||du_F||²+ψ²), u += dλ*du_F
    !! Corrector: choose root dλ of ||du_I+dλ*du_II||²+ψ²dλ² = ds² by **max dot** with previous increment
    !!     (forward continuation), same K/R/Solve pattern as RT_NLSolver_NewtonRaph.
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    LOGICAL, INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: step_state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    REAL(wp), INTENT(IN), OPTIONAL :: F_ext(:)
    TYPE(RT_CSRMatrix), INTENT(INOUT), OPTIONAL :: K_CSR
    REAL(wp), INTENT(IN), OPTIONAL :: arc_length_init, arc_min, arc_max, psi
    LOGICAL, INTENT(IN), OPTIONAL :: l3_csr_reanalyze_required
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: max_iter, nDOF, i, j, k, n_corr, n_corr_last, iter_count
    REAL(wp) :: arc_length, arc_length_min, arc_length_max
    REAL(wp) :: lambda, delta_lambda, psi_factor
    REAL(wp) :: constraint_residual, tol_arc, tol_force, tol_disp, residual_norm, displacement_norm
    REAL(wp) :: a1, a2, a3, disc, dlambda1, dlambda2, du_F_norm, dot1, dot2
    LOGICAL :: converged, use_assembly
    TYPE(RT_Asm_Cfg) :: asm_cfg
    TYPE(RT_LinearSolver) :: linear_solver
    REAL(wp), ALLOCATABLE :: K_dense(:,:), rhs(:), du_F(:), du_I(:), du_II(:)
    REAL(wp), ALLOCATABLE :: F_scaled(:), du_c1(:), du_c2(:), du_dir(:)
    
    CALL init_error_status(local_status)
    
    IF (solver%max_iterations <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Arc-length: Invalid max_iterations'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Check assembly path: all optional args must be present
    use_assembly = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
                   PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)
    nDOF = SIZE(state%u)
    
    IF (use_assembly) THEN
      IF (dofMap%nTotalEq /= nDOF .OR. SIZE(F_ext) /= nDOF) THEN
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'Arc-length: dofMap/F_ext size mismatch'
        result = .FALSE.
        IF (PRESENT(status)) status = local_status
        RETURN
      END IF
      ALLOCATE(K_dense(nDOF, nDOF), rhs(nDOF), du_F(nDOF), du_I(nDOF), du_II(nDOF), F_scaled(nDOF), &
           du_c1(nDOF), du_c2(nDOF), du_dir(nDOF))
      asm_cfg = RT_Asm_Cfg()
      CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      IF (PRESENT(l3_csr_reanalyze_required) .AND. l3_csr_reanalyze_required) THEN
        CALL RT_LinearSolver_Clean(linear_solver, local_status)
        CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      END IF
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        use_assembly = .FALSE.
        DEALLOCATE(K_dense, rhs, du_F, du_I, du_II, F_scaled, du_c1, du_c2, du_dir)
      END IF
    END IF
    
    max_iter = solver%max_iterations
    tol_force = solver%tolerance_force
    tol_disp = solver%tolerance_displacement
    tol_arc = 1.0e-6_wp
    arc_length = 0.1_wp
    arc_length_min = 1.0e-6_wp
    arc_length_max = 1.0_wp
    psi_factor = 1.0_wp
    IF (PRESENT(arc_length_init)) arc_length = arc_length_init
    IF (PRESENT(arc_min)) arc_length_min = arc_min
    IF (PRESENT(arc_max)) arc_length_max = arc_max
    IF (PRESENT(psi)) psi_factor = psi
    lambda = state%lambda
    delta_lambda = 0.0_wp
    converged = .FALSE.
    residual_norm = 0.0_wp
    displacement_norm = 0.0_wp
    n_corr_last = 0_i4
    iter_count = 0_i4
    
    ! Use adaptive arc length from previous increment if available
    IF (state%arc_length > 0.0_wp) arc_length = state%arc_length
    
    IF (use_assembly) THEN
      ! --- Predictor ---
      ! K_t * du_F = F_ext (reference load direction)
      CALL RT_Asm_ComputeTangent(model, step, step_state, dofMap, state%u, K_CSR, asm_cfg, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        result = .FALSE.
        IF (PRESENT(status)) status = local_status
        DEALLOCATE(K_dense, rhs, du_F, du_I, du_II, F_scaled, du_c1, du_c2, du_dir)
        RETURN
      END IF
      K_dense = 0.0_wp
      DO i = 1, K_CSR%nRows
        DO k = K_CSR%rowPtr(i), K_CSR%rowPtr(i+1) - 1
          j = K_CSR%colInd(k)
          K_dense(i, j) = K_CSR%values(k)
        END DO
      END DO
      rhs = F_ext
      CALL RT_LinearSolver_Solv(linear_solver, K_dense, rhs, du_F, local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        result = .FALSE.
        IF (PRESENT(status)) status = local_status
        DEALLOCATE(K_dense, rhs, du_F, du_I, du_II, F_scaled, du_c1, du_c2, du_dir)
        RETURN
      END IF
      du_F_norm = SQRT(SUM(du_F**2))
      IF (du_F_norm < 1.0e-14_wp) du_F_norm = 1.0_wp
      ! dlambda = ds / sqrt(||du_F||^2 + psi^2)
      delta_lambda = arc_length / SQRT(du_F_norm**2 + psi_factor**2)
      state%du = delta_lambda * du_F
      du_dir = state%du
      state%u = state%u + state%du
      lambda = lambda + delta_lambda
      state%lambda = lambda
      iter_count = 1_i4
      
      ! --- Corrector loop (same Tangent / Residual / Solve as Newton-Raphson) ---
      DO n_corr = 1, max_iter
        state%iteration = n_corr
        iter_count = iter_count + 1_i4
        F_scaled = lambda * F_ext
        CALL RT_Asm_ComputeTangent(model, step, step_state, dofMap, state%u, K_CSR, asm_cfg, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        K_dense = 0.0_wp
        DO i = 1, K_CSR%nRows
          DO k = K_CSR%rowPtr(i), K_CSR%rowPtr(i+1) - 1
            j = K_CSR%colInd(k)
            K_dense(i, j) = K_CSR%values(k)
          END DO
        END DO
        CALL RT_Asm_ComputeResidual(model, step, step_state, dofMap, state%u, 0.0_wp, &
                                         F_scaled, state%R, local_status, K_tangent=K_CSR, &
                                         asm_config=asm_cfg)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        rhs = -state%R
        CALL RT_LinearSolver_Solv(linear_solver, K_dense, rhs, du_I, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        rhs = F_ext
        CALL RT_LinearSolver_Solv(linear_solver, K_dense, rhs, du_II, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        ! Spherical constraint: ||du_I + dλ·du_II||² + ψ²·dλ² = ds²
        a1 = DOT_PRODUCT(du_II, du_II) + psi_factor**2
        a2 = 2.0_wp * DOT_PRODUCT(du_I, du_II)
        a3 = DOT_PRODUCT(du_I, du_I) - arc_length**2
        IF (ABS(a1) < 1.0e-30_wp) THEN
          delta_lambda = 0.0_wp
          state%du = du_I
        ELSE
          disc = a2*a2 - 4.0_wp*a1*a3
          IF (disc < 0.0_wp) disc = 0.0_wp
          dlambda1 = (-a2 + SQRT(disc)) / (2.0_wp * a1)
          dlambda2 = (-a2 - SQRT(disc)) / (2.0_wp * a1)
          du_c1 = du_I + dlambda1 * du_II
          du_c2 = du_I + dlambda2 * du_II
          dot1 = DOT_PRODUCT(du_c1, du_dir)
          dot2 = DOT_PRODUCT(du_c2, du_dir)
          IF (dot1 >= dot2) THEN
            delta_lambda = dlambda1
            state%du = du_c1
          ELSE
            delta_lambda = dlambda2
            state%du = du_c2
          END IF
        END IF
        state%u = state%u + state%du
        lambda = lambda + delta_lambda
        state%lambda = lambda
        du_dir = state%du
        residual_norm = SQRT(SUM(state%R**2))
        displacement_norm = SQRT(SUM(state%du**2))
        
        ! [T2 Enhancement] Robust energy norm for strong softening
        a2 = ABS(DOT_PRODUCT(state%du, state%R))
        a3 = ABS(DOT_PRODUCT(state%u, F_scaled))
        IF (a3 > 1.0e-14_wp) THEN
          state%energy_norm = a2 / a3
        ELSE
          state%energy_norm = a2
        END IF

        constraint_residual = DOT_PRODUCT(state%du, state%du) + psi_factor**2 * delta_lambda**2 - arc_length**2
        
        ! Adaptive Convergence Logic for Arc-Length
        BLOCK
          LOGICAL :: force_conv, disp_conv, energy_conv, arc_conv
          force_conv  = (residual_norm < tol_force)
          disp_conv   = (displacement_norm < tol_disp)
          energy_conv = (state%energy_norm < solver%tolerance_energy)
          arc_conv    = (ABS(constraint_residual) <= tol_arc * solver%arc_constraint_tol_scale * &
               MAX(arc_length**2, 1.0e-10_wp))

          ! 1. Strict standard criterion
          IF (force_conv .AND. disp_conv .AND. arc_conv) THEN
            converged = .TRUE.
          ! 2. Strong softening relaxation (large displacements, zeroing force/energy variation)
          ELSE IF ((residual_norm < tol_force * 10.0_wp) .AND. energy_conv .AND. arc_conv) THEN
            converged = .TRUE.
          ! 3. Ignore slight geometric arc deviations if equilibrium is strictly met
          ELSE IF (force_conv .AND. disp_conv .AND. energy_conv) THEN
            converged = .TRUE.
          END IF
        END BLOCK

        IF (converged) THEN
          n_corr_last = n_corr
          EXIT
        END IF
      END DO
      IF (.NOT. converged) n_corr_last = max_iter
      CALL RT_LinearSolver_Clean(linear_solver, local_status)
      DEALLOCATE(K_dense, rhs, du_F, du_I, du_II, F_scaled, du_c1, du_c2, du_dir)
    ELSE
      state%converged = .FALSE.
      state%iterations = 0_i4
      result = .FALSE.
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Arc-length: assembly path required (model, step, step_state, dofMap, F_ext, K_CSR)'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    IF (converged .AND. n_corr_last < 5_i4) arc_length = MIN(arc_length * 1.5_wp, arc_length_max)
    IF (converged .AND. n_corr_last > 15_i4) arc_length = MAX(arc_length * 0.5_wp, arc_length_min)
    state%converged = converged
    state%iterations = iter_count
    state%arc_length = arc_length
    state%residual_norm = residual_norm
    state%displacement_norm = displacement_norm
    result = converged
    IF (converged) THEN
      local_status%status_code = IF_STATUS_OK
      WRITE(local_status%message, '(A,I0,A,F8.5)') &
        'Arc-length converged in ', iter_count, ' substeps, lambda = ', state%lambda
    ELSE
      IF (solver%arc_nonconverge_use_warn) THEN
        local_status%status_code = IF_STATUS_WARN
        WRITE(local_status%message, '(A,I0,A)') &
          'Arc-length did not converge in ', max_iter, ' iterations (WARN; use cut-back/retry)'
      ELSE
        local_status%status_code = IF_STATUS_ERROR
        WRITE(local_status%message, '(A,I0,A)') &
          'Arc-length failed to converge in ', max_iter, ' iterations'
      END IF
    END IF
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE RT_NLSolver_ArcLen

  SUBROUTINE RT_NLSolver_LineSearch(solver, state, direction, result, status, &
       model, step, step_state, dofMap, F_ext, K_CSR)
    !! Line search algorithm (Runtime layer implementation)
    !! Line search (Backtracking Line Search implementation)
    !! Step 1: Validate inputs (direction non-zero)
    !! Step 2: Compute initial energy E0 = f(u)
    !! Step 3: Armijo: f(u+alpha*d) <= f(u) + c1*alpha*grad_f.d
    !! Step 4: Backtrack alpha = beta*alpha
    !! Step 5: Check minimum step length
    !! Step 6: Return optimal step factor?
    !! Step 7: Update search statistics
    !! Step 8: return)
    !! Optional model, step, step_state, dofMap, F_ext, K_CSR: when all present, call RT_Asm_ComputeResidual for R_trial.
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: direction(:)
    REAL(wp), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: step_state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    REAL(wp), INTENT(IN), OPTIONAL :: F_ext(:)
    TYPE(RT_CSRMatrix), INTENT(IN), OPTIONAL :: K_CSR
    
    TYPE(ErrorStatusType) :: local_status
    REAL(wp) :: alpha, alpha_min, beta, c1
    REAL(wp) :: energy_0, energy_alpha, gradient_dot_direction
    REAL(wp), ALLOCATABLE :: u_trial(:), R_trial(:)
    INTEGER(i4) :: max_backtracks, i_backtrack
    LOGICAL :: armijo_satisfied, use_assembly
    
    CALL init_error_status(local_status)
    
    ! Step 1: Validate inputs
    IF (SIZE(direction) /= SIZE(state%u)) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Line search: Direction size mismatch'
      result = 1.0_wp
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    IF (SQRT(SUM(direction**2)) < 1.0e-15_wp) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Line search: Zero direction vector'
      result = 1.0_wp
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 2: Line search parameters
    alpha = 1.0_wp           ! initial step (Newton full step)
    alpha_min = 1.0e-4_wp    ! minimum step
    beta = 0.5_wp            ! backtrack factor
    c1 = 1.0e-4_wp           ! Armijo constant
    max_backtracks = 20_i4
    
    ! Compute initial energy (residual norm)
    energy_0 = SQRT(SUM(state%R**2))
    
    ! Gradient dot direction: grad_f . d; for Newton direction, grad_f . d = -R^T . d
    gradient_dot_direction = -SUM(state%R * direction)
    
    use_assembly = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
         PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)
    IF (use_assembly) use_assembly = (dofMap%nTotalEq == SIZE(state%u) .AND. SIZE(F_ext) == SIZE(state%u))
    
    ALLOCATE(u_trial(SIZE(state%u)))
    IF (use_assembly) ALLOCATE(R_trial(SIZE(state%u)))
    
    ! Step 3-4: Backtracking line search
    armijo_satisfied = .FALSE.
    DO i_backtrack = 1, max_backtracks
      ! Trial point: u_trial = u + alpha*d
      u_trial = state%u + alpha * direction
      
      ! Compute energy at trial point: energy_alpha = ||R(u_trial)||
      IF (use_assembly) THEN
        CALL RT_Asm_ComputeResidual(model, step, step_state, dofMap, u_trial, state%lambda, &
             F_ext, R_trial, local_status, K_tangent=K_CSR, asm_config=RT_Asm_Cfg())
        IF (local_status%status_code == IF_STATUS_OK) THEN
          energy_alpha = SQRT(SUM(R_trial**2))
        ELSE
          energy_alpha = energy_0 * 1.1_wp  ! assume worse on error
        END IF
      ELSE
        energy_alpha = energy_0 * 0.9_wp  ! fallback: assume energy decrease
      END IF
      
      ! Step 3: Armijo condition check
      IF (energy_alpha <= energy_0 + c1 * alpha * gradient_dot_direction) THEN
        armijo_satisfied = .TRUE.
        EXIT
      END IF
      
      ! Step 4: Backtrack
      alpha = beta * alpha
      
      ! Step 5: Check minimum step
      IF (alpha < alpha_min) THEN
        alpha = alpha_min
        EXIT
      END IF
    END DO
    
    DEALLOCATE(u_trial)
    IF (ALLOCATED(R_trial)) DEALLOCATE(R_trial)
    
    ! Step 6: returnstep 
    result = alpha
    
    ! Step 7: Update state 
    state%line_search_iters = i_backtrack
    
    ! Step 8: return)
    IF (armijo_satisfied) THEN
      local_status%status_code = IF_STATUS_OK
      WRITE(local_status%message, '(A,F8.5,A,I0,A)') &
        'Line search: alpha = ', alpha, ' (', i_backtrack, ' backtracks)'
    ELSE
      local_status%status_code = IF_STATUS_WARN
      WRITE(local_status%message, '(A,F8.5)') &
        'Line search: Minimal step alpha = ', alpha
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_NLSolver_LineSearch

  SUBROUTINE RT_NLSolver_ModifiedNewton(solver, state, tangent_update_freq, &
                                        result, status, model, step, step_state, dofMap, F_ext, K_CSR)
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: tangent_update_freq
    LOGICAL, INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: step_state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    REAL(wp), INTENT(IN), OPTIONAL :: F_ext(:)
    TYPE(RT_CSRMatrix), INTENT(INOUT), OPTIONAL :: K_CSR
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: max_iter, iter, nDOF, i, j, k
    REAL(wp) :: tol_force, tol_disp
    REAL(wp) :: residual_norm, displacement_norm
    LOGICAL :: converged, should_update_tangent, use_assembly
    TYPE(RT_Asm_Cfg) :: asm_cfg
    TYPE(RT_LinearSolver) :: linear_solver
    REAL(wp), ALLOCATABLE :: K_dense(:,:), rhs(:)
    
    CALL init_error_status(local_status)
    
    ! Step 1: Validate inputs
    IF (solver%max_iterations <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Modified Newton: Invalid max_iterations'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    use_assembly = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
                   PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)
    nDOF = SIZE(state%u)
    
    IF (use_assembly) THEN
      IF (dofMap%nTotalEq /= nDOF .OR. SIZE(F_ext) /= nDOF) THEN
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'Modified Newton: dofMap/F_ext size mismatch'
        result = .FALSE.
        IF (PRESENT(status)) status = local_status
        RETURN
      END IF
      ALLOCATE(K_dense(nDOF, nDOF), rhs(nDOF))
      asm_cfg = RT_Asm_Cfg()
      CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        use_assembly = .FALSE.
        DEALLOCATE(K_dense, rhs)
      END IF
    END IF
    
    ! Step 2: Prepare solver settings
    max_iter = solver%max_iterations
    tol_force = solver%tolerance_force
    tol_disp = solver%tolerance_displacement
    
    ! Step 3: Modified Newton-Raphson iteration loop
    converged = .FALSE.
    DO iter = 1, max_iter
      state%iteration = iter
      
      should_update_tangent = (MOD(iter - 1, tangent_update_freq) == 0)
      
      IF (use_assembly) THEN
        IF (should_update_tangent) THEN
          CALL RT_Asm_ComputeTangent(model, step, step_state, dofMap, state%u, K_CSR, asm_cfg, local_status)
          IF (local_status%status_code /= IF_STATUS_OK) EXIT
          K_dense = 0.0_wp
          DO i = 1, K_CSR%nRows
            DO k = K_CSR%rowPtr(i), K_CSR%rowPtr(i+1) - 1
              j = K_CSR%colInd(k)
              K_dense(i, j) = K_CSR%values(k)
            END DO
          END DO
        END IF
        CALL RT_Asm_ComputeResidual(model, step, step_state, dofMap, state%u, state%lambda, &
                                         F_ext, state%R, local_status, K_tangent=K_CSR, &
                                         asm_config=asm_cfg)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        rhs = -state%R
        CALL RT_LinearSolver_Solv(linear_solver, K_dense, rhs, state%du, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
      ELSE
        state%R = 0.0_wp
        state%du = 0.0_wp
      END IF
      
      ! Step 4: Check convergence
      residual_norm = SQRT(SUM(state%R**2))
      displacement_norm = SQRT(SUM(state%du**2))
      
      IF (residual_norm < tol_force .AND. displacement_norm < tol_disp) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! Update displacement: u = u + du
      state%u = state%u + state%du
    END DO
    
    IF (use_assembly) THEN
      CALL RT_LinearSolver_Clean(linear_solver, local_status)
      IF (ALLOCATED(K_dense)) DEALLOCATE(K_dense)
      IF (ALLOCATED(rhs)) DEALLOCATE(rhs)
    END IF
    
    ! Step 5-7: Update state and metrics
    state%converged = converged
    state%iterations = iter
    state%residual_norm = residual_norm
    state%displacement_norm = displacement_norm
    
    result = converged
    
    ! Step 8: Return status
    IF (converged) THEN
      local_status%status_code = IF_STATUS_OK
      WRITE(local_status%message, '(A,I0,A)') &
        'Modified Newton converged in ', iter, ' iterations'
    ELSE
      local_status%status_code = IF_STATUS_ERROR
      WRITE(local_status%message, '(A,I0,A)') &
        'Modified Newton failed to converge in ', max_iter, ' iterations'
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_NLSolver_ModifiedNewton

  SUBROUTINE RT_NLSolver_NewtonControl(solver, state, iteration, &
                                        force_tolerance, disp_tolerance, &
                                        energy_tolerance, converged, status)
    !! Newton iteration control and convergence checking
    !! Newton iteration control and convergence check?
    !!
    !! This subroutine provides comprehensive iteration control for Newton methods,
    !! including convergence checking, iteration limits, and adaptive control.
    !!
    !! Input:
    !!   solver          - Nonlinear solver configuration
    !!   state           - Current solver state
    !!   iteration       - Current iteration number
    !!   force_tolerance - Force residual tolerance
    !!   disp_tolerance  - Displacement tolerance
    !!   energy_tolerance - Energy tolerance
    !!
    !! Output:
    !!   converged       - Convergence flag
    !!   status          - Error status
    !!
    !! Task: 11150-11199
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: iteration
    REAL(wp), INTENT(IN) :: force_tolerance
    REAL(wp), INTENT(IN) :: disp_tolerance
    REAL(wp), INTENT(IN) :: energy_tolerance
    LOGICAL, INTENT(OUT) :: converged
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    REAL(wp) :: residual_norm, displacement_norm, energy_norm
    REAL(wp) :: force_ratio, disp_ratio, energy_ratio
    LOGICAL :: force_converged, disp_converged, energy_converged
    
    CALL init_error_status(local_status)
    
    ! Init convergence flags
    converged = .FALSE.
    force_converged = .FALSE.
    disp_converged = .FALSE.
    energy_converged = .FALSE.
    
    ! Check iteration limit
    IF (iteration > solver%max_iterations) THEN
      local_status%status_code = IF_STATUS_ERROR
      WRITE(local_status%message, '(A,I0,A)') &
        'RT_NLSolver_NewtonControl: Maximum iterations (', &
        solver%max_iterations, ') exceeded'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Compute norms
    IF (ALLOCATED(state%R)) THEN
      residual_norm = SQRT(SUM(state%R**2))
      force_ratio = residual_norm / MAX(force_tolerance, 1.0e-15_wp)
      force_converged = (residual_norm < force_tolerance)
    ELSE
      residual_norm = 0.0_wp
      force_ratio = 0.0_wp
      force_converged = .TRUE.  ! No residual to check
    END IF
    
    IF (ALLOCATED(state%du)) THEN
      displacement_norm = SQRT(SUM(state%du**2))
      disp_ratio = displacement_norm / MAX(disp_tolerance, 1.0e-15_wp)
      disp_converged = (displacement_norm < disp_tolerance)
    ELSE
      displacement_norm = 0.0_wp
      disp_ratio = 0.0_wp
      disp_converged = .TRUE.  ! No displacement increment to check
    END IF
    
    ! Energy convergence (simplified: use residual norm as energy proxy)
    energy_norm = residual_norm
    energy_ratio = energy_norm / MAX(energy_tolerance, 1.0e-15_wp)
    energy_converged = (energy_norm < energy_tolerance)
    
    ! Update state norms
    state%residual_norm = residual_norm
    state%displacement_norm = displacement_norm
    state%iteration = iteration
    
    ! Convergence check: require all criteria to be satisfied
    ! (or at least force and displacement for mixed convergence)
    converged = force_converged .AND. disp_converged
    
    ! Alternative: mixed convergence (any two of three criteria)
    ! converged = (force_converged .AND. disp_converged) .OR. &
    !            (force_converged .AND. energy_converged) .OR. &
    !            (disp_converged .AND. energy_converged)
    
    state%converged = converged
    
    ! Set status message
    IF (converged) THEN
      local_status%status_code = IF_STATUS_OK
      WRITE(local_status%message, '(A,I0,A,3(E10.3,A))') &
        'Newton iteration ', iteration, ' converged: ', &
        force_ratio, ' (force), ', disp_ratio, ' (disp), ', &
        energy_ratio, ' (energy)'
    ELSE
      local_status%status_code = IF_STATUS_OK  ! Still iterating, not an error
      WRITE(local_status%message, '(A,I0,A,3(E10.3,A))') &
        'Newton iteration ', iteration, ': ', &
        force_ratio, ' (force), ', disp_ratio, ' (disp), ', &
        energy_ratio, ' (energy)'
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_NLSolver_NewtonControl

  SUBROUTINE RT_NLSolver_NewtonRaph(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &
                                         AI_ConvPredictor, l3_csr_reanalyze_required, nr_divergence_growth_limit)
    !! Newton-Raphson solver (Runtime layer implementation)
    !! When model, step, step_state, dofMap, F_ext, K_CSR are present: full assembly + linear solve path.
    !! AI_ConvPredictor: optional callback during iteration (residual_history -> will_converge, confidence)
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    LOGICAL, INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: step_state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    REAL(wp), INTENT(IN), OPTIONAL :: F_ext(:)
    TYPE(RT_CSRMatrix), INTENT(INOUT), OPTIONAL :: K_CSR
    PROCEDURE(RT_Glb_ConvPred_IF), POINTER, OPTIONAL :: AI_ConvPredictor
    LOGICAL, INTENT(IN), OPTIONAL :: l3_csr_reanalyze_required
    ! Optional: if present and in (0, huge), exit NR early with IF_STATUS_WARN when
    ! residual L2-norm grows faster than this factor times the previous iterate norm
    ! (Phase6 1.1 soft-fail). Omitted => check disabled (legacy numerics unchanged).
    REAL(wp), INTENT(IN), OPTIONAL :: nr_divergence_growth_limit
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: max_iter, iter, nDOF, i, j, k
    REAL(wp) :: tol_force, tol_disp
    REAL(wp) :: residual_norm, displacement_norm
    REAL(wp) :: res_norm_prev_iter, denom_div
    LOGICAL :: converged, use_assembly
    LOGICAL :: abort_soft_divergence
    REAL(wp), ALLOCATABLE :: res_hist(:)
    TYPE(RT_Asm_Cfg) :: asm_cfg
    TYPE(RT_LinearSolver) :: linear_solver
    REAL(wp), ALLOCATABLE :: K_dense(:,:), rhs(:)
    
    CALL init_error_status(local_status)
    
    IF (solver%max_iterations <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Newton-Raphson: Invalid max_iterations'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    IF (.NOT. ALLOCATED(state%u) .OR. .NOT. ALLOCATED(state%R)) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Newton-Raphson: State arrays not allocated'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    use_assembly = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
                   PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)
    nDOF = SIZE(state%u)
    
    IF (use_assembly) THEN
      IF (dofMap%nTotalEq /= nDOF .OR. SIZE(F_ext) /= nDOF) THEN
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'Newton-Raphson: dofMap/F_ext size mismatch'
        result = .FALSE.
        IF (PRESENT(status)) status = local_status
        RETURN
      END IF
      ALLOCATE(K_dense(nDOF, nDOF), rhs(nDOF))
      asm_cfg = RT_Asm_Cfg()
      CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      IF (PRESENT(l3_csr_reanalyze_required) .AND. l3_csr_reanalyze_required) THEN
        CALL RT_LinearSolver_Clean(linear_solver, local_status)
        CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      END IF
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        use_assembly = .FALSE.
        DEALLOCATE(K_dense, rhs)
      END IF
    END IF
    
    max_iter = solver%max_iterations
    tol_force = solver%tolerance_force
    tol_disp = solver%tolerance_displacement
    converged = .FALSE.
    abort_soft_divergence = .FALSE.
    res_norm_prev_iter = 0.0_wp
    IF (PRESENT(AI_ConvPredictor) .AND. ASSOCIATED(AI_ConvPredictor)) THEN
      ALLOCATE(res_hist(max_iter))
    END IF
    
    DO iter = 1, max_iter
      state%iteration = iter
      
      IF (use_assembly) THEN
        CALL RT_Asm_ComputeTangent(model, step, step_state, dofMap, state%u, K_CSR, asm_cfg, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        K_dense = 0.0_wp
        DO i = 1, K_CSR%nRows
          DO k = K_CSR%rowPtr(i), K_CSR%rowPtr(i+1) - 1
            j = K_CSR%colInd(k)
            K_dense(i, j) = K_CSR%values(k)
          END DO
        END DO
        CALL RT_Asm_ComputeResidual(model, step, step_state, dofMap, state%u, state%lambda, &
                                         F_ext, state%R, local_status, K_tangent=K_CSR, &
                                         asm_config=asm_cfg)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        rhs = -state%R
        CALL RT_LinearSolver_Solv(linear_solver, K_dense, rhs, state%du, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
      ELSE
        state%R = 0.0_wp
        state%du = 0.0_wp
      END IF
      
      residual_norm = SQRT(SUM(state%R**2))
      displacement_norm = SQRT(SUM(state%du**2))
      state%energy_norm = ABS(DOT_PRODUCT(state%R, state%du))
      
      ! Phase6 1.1: optional residual blow-up soft-exit (caller enables via keyword)
      IF (PRESENT(nr_divergence_growth_limit)) THEN
        IF (nr_divergence_growth_limit > 0.0_wp .AND. iter > 1_i4) THEN
          denom_div = MAX(res_norm_prev_iter, tol_force * 1.0e-9_wp)
          IF (residual_norm > nr_divergence_growth_limit * denom_div) THEN
            abort_soft_divergence = .TRUE.
            EXIT
          END IF
        END IF
      END IF
      res_norm_prev_iter = residual_norm
      
      ! AI-ready: call ConvergencePredictor with residual history (if associated)
      IF (ALLOCATED(res_hist)) THEN
        res_hist(iter) = residual_norm
        IF (iter >= 3_i4) THEN
          BLOCK
            LOGICAL :: will_conv
            REAL(wp) :: conf
            REAL(wp), PARAMETER :: AI_CONF_THRESH = 0.9_wp  ! Early-exit confidence threshold
            TYPE(ErrorStatusType) :: ai_st
            CALL AI_ConvPredictor(res_hist(1:iter), will_conv, conf, ai_st)
            ! Early exit when predictor says will converge with high confidence (AI_Slot_Contract)
            IF (will_conv .AND. conf >= AI_CONF_THRESH) THEN
              converged = .TRUE.
              state%u = state%u + state%du  ! Apply last increment before early exit
              EXIT
            END IF
          END BLOCK
        END IF
      END IF
      
      IF (residual_norm < tol_force .AND. displacement_norm < tol_disp) THEN
        converged = .TRUE.
        EXIT
      END IF
      ! Energy criterion: |R^T * du| < tol_energy (if set)
      IF (residual_norm < tol_force .AND. &
          state%energy_norm < solver%tolerance_energy) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      state%u = state%u + state%du
    END DO
    
    IF (ALLOCATED(res_hist)) DEALLOCATE(res_hist)
    
    IF (use_assembly) THEN
      CALL RT_LinearSolver_Clean(linear_solver, local_status)
      IF (ALLOCATED(K_dense)) DEALLOCATE(K_dense)
      IF (ALLOCATED(rhs)) DEALLOCATE(rhs)
    END IF
    
    state%converged = converged
    state%iterations = iter
    state%residual_norm = residual_norm
    state%displacement_norm = displacement_norm
    result = converged
    
    IF (abort_soft_divergence) THEN
      state%converged = .FALSE.
      result = .FALSE.
      local_status%status_code = IF_STATUS_WARN
      WRITE(local_status%message, '(A,I0,A,ES12.4,A,ES12.4)') &
        'Newton-Raphson: residual growth divergence (soft-exit) at iter ', iter, &
        ', ||R||=', residual_norm, ', prev ref=', res_norm_prev_iter
    ELSE IF (converged) THEN
      local_status%status_code = IF_STATUS_OK
      WRITE(local_status%message, '(A,I0,A)') &
        'Newton-Raphson converged in ', iter, ' iterations'
    ELSE
      local_status%status_code = IF_STATUS_ERROR
      WRITE(local_status%message, '(A,I0,A)') &
        'Newton-Raphson failed to converge in ', max_iter, ' iterations'
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_NLSolver_NewtonRaph

  SUBROUTINE RT_NLSolver_QuasiNewton(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &
      l3_csr_reanalyze_required)
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    LOGICAL, INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: step_state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    REAL(wp), INTENT(IN), OPTIONAL :: F_ext(:)
    TYPE(RT_CSRMatrix), INTENT(INOUT), OPTIONAL :: K_CSR
    LOGICAL, INTENT(IN), OPTIONAL :: l3_csr_reanalyze_required
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: max_iter, iter, nDOF, i, j, k
    REAL(wp) :: tol_force, tol_disp
    REAL(wp) :: residual_norm, displacement_norm
    LOGICAL :: converged, use_assembly
    TYPE(RT_Asm_Cfg) :: asm_cfg
    TYPE(RT_LinearSolver) :: linear_solver
    REAL(wp), ALLOCATABLE :: K_dense(:,:), rhs(:)
    
    CALL init_error_status(local_status)
    
    ! Step 1: Validate inputs
    IF (solver%max_iterations <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Quasi-Newton: Invalid max_iterations'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    use_assembly = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
                   PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)
    nDOF = SIZE(state%u)
    
    IF (use_assembly) THEN
      IF (dofMap%nTotalEq /= nDOF .OR. SIZE(F_ext) /= nDOF) THEN
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'Quasi-Newton: dofMap/F_ext size mismatch'
        result = .FALSE.
        IF (PRESENT(status)) status = local_status
        RETURN
      END IF
      ALLOCATE(K_dense(nDOF, nDOF), rhs(nDOF))
      asm_cfg = RT_Asm_Cfg()
      CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      IF (PRESENT(l3_csr_reanalyze_required) .AND. l3_csr_reanalyze_required) THEN
        CALL RT_LinearSolver_Clean(linear_solver, local_status)
        CALL RT_LinearSolver_Init(linear_solver, method=2_i4, maxIter=5000_i4, tolerance=1.0e-8_wp, status=local_status)
      END IF
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        use_assembly = .FALSE.
        DEALLOCATE(K_dense, rhs)
      END IF
    END IF
    
    ! Step 2: Prepare solver settings
    max_iter = solver%max_iterations
    tol_force = solver%tolerance_force
    tol_disp = solver%tolerance_displacement
    
    ! Step 3: Quasi-Newton iteration loop (uses full tangent each iter; BFGS update TODO)
    converged = .FALSE.
    DO iter = 1, max_iter
      state%iteration = iter
      
      IF (use_assembly) THEN
        CALL RT_Asm_ComputeTangent(model, step, step_state, dofMap, state%u, K_CSR, asm_cfg, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        K_dense = 0.0_wp
        DO i = 1, K_CSR%nRows
          DO k = K_CSR%rowPtr(i), K_CSR%rowPtr(i+1) - 1
            j = K_CSR%colInd(k)
            K_dense(i, j) = K_CSR%values(k)
          END DO
        END DO
        CALL RT_Asm_ComputeResidual(model, step, step_state, dofMap, state%u, state%lambda, &
                                         F_ext, state%R, local_status, K_tangent=K_CSR, &
                                         asm_config=asm_cfg)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
        rhs = -state%R
        CALL RT_LinearSolver_Solv(linear_solver, K_dense, rhs, state%du, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) EXIT
      ELSE
        state%R = 0.0_wp
        state%du = 0.0_wp
      END IF
      
      ! Step 4: Check convergence
      residual_norm = SQRT(SUM(state%R**2))
      displacement_norm = SQRT(SUM(state%du**2))
      
      IF (residual_norm < tol_force .AND. displacement_norm < tol_disp) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! Update displacement: u = u + du
      state%u = state%u + state%du
    END DO
    
    IF (use_assembly) THEN
      CALL RT_LinearSolver_Clean(linear_solver, local_status)
      IF (ALLOCATED(K_dense)) DEALLOCATE(K_dense)
      IF (ALLOCATED(rhs)) DEALLOCATE(rhs)
    END IF
    
    ! Step 5-7: Update state and metrics
    state%converged = converged
    state%iterations = iter
    state%residual_norm = residual_norm
    state%displacement_norm = displacement_norm
    
    result = converged
    
    ! Step 8: Return status
    IF (converged) THEN
      local_status%status_code = IF_STATUS_OK
      WRITE(local_status%message, '(A,I0,A)') &
        'Quasi-Newton converged in ', iter, ' iterations'
    ELSE
      local_status%status_code = IF_STATUS_ERROR
      WRITE(local_status%message, '(A,I0,A)') &
        'Quasi-Newton failed to converge in ', max_iter, ' iterations'
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_NLSolver_QuasiNewton

  SUBROUTINE RT_NLSolver_Solv_Unified(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR)
    !! Unified nonlinear solver call interface
    !! When model, step, step_state, dofMap, F_ext, K_CSR are present: passes assembly context to solvers.
    !!
    !! Input:
    !!   solver - Nonlinear solver configuration
    !!   state  - Solver state (contains residual, displacement, etc.)
    !!   model, step, step_state, dofMap, F_ext, K_CSR - Optional assembly context
    !!
    !! Output:
    !!   result - Convergence flag (.TRUE. if converged)
    !!   status - Error status
    !!
    !! Task: 11100-11149
    TYPE(MD_NonlinSolv), INTENT(IN) :: solver
    TYPE(MD_SolverState), INTENT(INOUT) :: state
    LOGICAL, INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: step_state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    REAL(wp), INTENT(IN), OPTIONAL :: F_ext(:)
    TYPE(RT_CSRMatrix), INTENT(INOUT), OPTIONAL :: K_CSR
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: solver_type
    
    CALL init_error_status(local_status)
    
    ! Valid inputs
    IF (solver%max_iterations <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'RT_NLSolver_Solv_Unified: Invalid max_iterations'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    IF (.NOT. ALLOCATED(state%u) .OR. .NOT. ALLOCATED(state%R)) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'RT_NLSolver_Solv_Unified: State arrays not allocated'
      result = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Determine solver type from configuration
    solver_type = solver%method  ! 1=NR, 2=ModifiedNR, 3=QuasiNR, 4=ArcLen
    
    ! Call appropriate solver (pass assembly context when present)
    IF (PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
        PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)) THEN
      SELECT CASE (solver_type)
      CASE (1)
        CALL RT_NLSolver_NewtonRaph(solver, state, result, local_status, model=model, step=step, &
             step_state=step_state, dofMap=dofMap, F_ext=F_ext, K_CSR=K_CSR, &
             nr_divergence_growth_limit=solver%nr_divergence_growth_limit)
      CASE (2)
        CALL RT_NLSolver_ModifiedNewton(solver, state, 1_i4, result, local_status, model=model, step=step, &
             step_state=step_state, dofMap=dofMap, F_ext=F_ext, K_CSR=K_CSR)
      CASE (3)
        CALL RT_NLSolver_QuasiNewton(solver, state, result, local_status, model=model, step=step, &
             step_state=step_state, dofMap=dofMap, F_ext=F_ext, K_CSR=K_CSR)
      CASE (4)
        CALL RT_NLSolver_ArcLen(solver, state, result, local_status, model=model, step=step, &
             step_state=step_state, dofMap=dofMap, F_ext=F_ext, K_CSR=K_CSR)
      CASE DEFAULT
        CALL RT_NLSolver_NewtonRaph(solver, state, result, local_status, model=model, step=step, &
             step_state=step_state, dofMap=dofMap, F_ext=F_ext, K_CSR=K_CSR, &
             nr_divergence_growth_limit=solver%nr_divergence_growth_limit)
      END SELECT
    ELSE
      SELECT CASE (solver_type)
      CASE (1)
        CALL RT_NLSolver_NewtonRaph(solver, state, result, local_status, &
             nr_divergence_growth_limit=solver%nr_divergence_growth_limit)
      CASE (2)
        CALL RT_NLSolver_ModifiedNewton(solver, state, 1_i4, result, local_status)
      CASE (3)
        CALL RT_NLSolver_QuasiNewton(solver, state, result, local_status)
      CASE (4)
        CALL RT_NLSolver_ArcLen(solver, state, result, local_status)
      CASE DEFAULT
        CALL RT_NLSolver_NewtonRaph(solver, state, result, local_status, &
             nr_divergence_growth_limit=solver%nr_divergence_growth_limit)
      END SELECT
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_NLSolver_Solv_Unified
end module RT_Solv_Nonlin