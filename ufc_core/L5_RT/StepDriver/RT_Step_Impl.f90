!===============================================================================
! MODULE: RT_Step_Impl
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   Impl — Explicit/Implicit dynamics driver implementation
! BRIEF:  Central-difference (explicit), Newmark-β/HHT-α (implicit).
!
! Status: GOLDEN-LINE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Step_Impl
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Model_Lib_Core, ONLY: UF_Model
  USE MD_Step_Proc, ONLY: UF_DynamicParams, AnalysisStep, StepStateData, &
       INTEG_NEWMARK_BETA, INTEG_HHT_ALPHA
  USE RT_Solv_Def, ONLY: RT_Sol_DofMap, RT_CSRMatrix, RT_CSR_Free
  USE RT_Asm_Solv, ONLY: RT_Asm_ComputeResidual, RT_Asm_ComputeTangent, RT_Asm_GlobalLoad, &
       RT_Asm_CSRMass_FromModel, RT_Asm_Cfg
  USE RT_Asm_MassDamp, ONLY: MASS_TYPE_LUMP, MASS_TYPE_CONSIST
  USE RT_Solv_Lin, ONLY: RT_LinearSolver, RT_LinearSolver_Init, RT_LinearSolver_Solv, RT_LinearSolver_Clean
  USE RT_Step_Def, ONLY: RT_DynExpl_TimeCfg, RT_DynExpl_State, RT_DynExpl_Ctx, &
                                 RT_DynImpl_TimeCfg, RT_DynImpl_State, RT_DynImpl_Ctx, &
                                 RT_DynImpl_Runner, INTEG_CENTRAL_DIFF
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_DynExpl_Run
  PUBLIC :: RT_DynImpl_Run
  PUBLIC :: RT_Dyn_CFL_dt_central_diff
  PUBLIC :: RT_Dyn_Estimate_omega_max_csr_lumped
  PUBLIC :: RT_Dyn_Clamp_dt_cfl_csr

CONTAINS

  !===========================================================================
  ! Explicit Dynamics Utilities
  !===========================================================================

  SUBROUTINE RT_Dyn_Clamp_dt_cfl_csr(dt_in, K_csr, M_diag, nDOF, cfl_safety, dt_out, omega_max_out)
    REAL(wp), INTENT(IN) :: dt_in
    TYPE(RT_CSRMatrix), INTENT(IN) :: K_csr
    REAL(wp), INTENT(IN) :: M_diag(:)
    INTEGER(i4), INTENT(IN) :: nDOF
    REAL(wp), INTENT(IN) :: cfl_safety
    REAL(wp), INTENT(OUT) :: dt_out
    REAL(wp), INTENT(OUT) :: omega_max_out
    REAL(wp) :: k_sum, m_min, omega_cfl

    k_sum = 0.0_wp
    m_min = HUGE(1.0_wp)

    IF (K_csr%init .AND. ALLOCATED(K_csr%values)) THEN
      k_sum = MAXVAL(ABS(K_csr%values))
    END IF

    IF (SIZE(M_diag) >= nDOF) THEN
      m_min = MINVAL(M_diag(1:nDOF))
    END IF

    IF (m_min < 1.0e-15_wp .OR. k_sum < 1.0e-15_wp) THEN
      dt_out = dt_in
      omega_max_out = 0.0_wp
      RETURN
    END IF

    omega_cfl = SQRT(k_sum / m_min)
    dt_out = MIN(dt_in, cfl_safety * 2.0_wp / omega_cfl)
    omega_max_out = omega_cfl
  END SUBROUTINE RT_Dyn_Clamp_dt_cfl_csr

  FUNCTION RT_Dyn_Estimate_omega_max_csr_lumped(K_csr, M_diag, nDOF) RESULT(omega_max)
    TYPE(RT_CSRMatrix), INTENT(IN) :: K_csr
    REAL(wp), INTENT(IN) :: M_diag(:)
    INTEGER(i4), INTENT(IN) :: nDOF
    REAL(wp) :: omega_max
    REAL(wp) :: k_max, m_min

    k_max = 0.0_wp
    m_min = HUGE(1.0_wp)

    IF (K_csr%init .AND. ALLOCATED(K_csr%values)) THEN
      k_max = MAXVAL(ABS(K_csr%values))
    END IF

    IF (SIZE(M_diag) >= nDOF) THEN
      m_min = MINVAL(M_diag(1:nDOF))
    END IF

    IF (m_min < 1.0e-15_wp .OR. k_max < 1.0e-15_wp) THEN
      omega_max = 0.0_wp
    ELSE
      omega_max = SQRT(k_max / m_min)
    END IF
  END FUNCTION RT_Dyn_Estimate_omega_max_csr_lumped

  FUNCTION RT_Dyn_CFL_dt_central_diff(omega_max, cfl_safety) RESULT(dt_cfl)
    REAL(wp), INTENT(IN) :: omega_max
    REAL(wp), INTENT(IN) :: cfl_safety
    REAL(wp) :: dt_cfl

    IF (omega_max < 1.0e-15_wp) THEN
      dt_cfl = HUGE(1.0_wp)
    ELSE
      dt_cfl = cfl_safety * 2.0_wp / omega_max
    END IF
  END FUNCTION RT_Dyn_CFL_dt_central_diff

  !===========================================================================
  ! RT_DynExpl_Run: Central-difference explicit dynamics
  !===========================================================================
  SUBROUTINE RT_DynExpl_Run(dyn_params, status, u, n_dof, model, step, state, dofMap, &
       apply_cfl_clamp, cfl_safety, omega_max_out, dt_effective_out)
    TYPE(UF_DynamicParams), INTENT(IN) :: dyn_params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(INOUT), OPTIONAL :: u(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_dof
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap
    LOGICAL, INTENT(IN), OPTIONAL :: apply_cfl_clamp
    REAL(wp), INTENT(IN), OPTIONAL :: cfl_safety
    REAL(wp), INTENT(OUT), OPTIONAL :: omega_max_out
    REAL(wp), INTENT(OUT), OPTIONAL :: dt_effective_out

    INTEGER(i4) :: nDOF, inc, max_inc, i
    REAL(wp) :: dt, total_time, t, csf, om_cfl
    REAL(wp), ALLOCATABLE :: v_half(:), F_ext(:), R(:), M_diag(:)
    TYPE(RT_CSRMatrix) :: M_csr, K_cfl
    TYPE(ErrorStatusType) :: st
    LOGICAL :: use_asm
    TYPE(RT_Asm_Cfg) :: dyn_asm

    CALL init_error_status(status)
    use_asm = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(state) .AND. &
              PRESENT(dofMap) .AND. PRESENT(u) .AND. PRESENT(n_dof)
    IF (use_asm) use_asm = (dofMap%nTotalEq > 0_i4 .AND. SIZE(u) >= n_dof .AND. n_dof > 0_i4)

    IF (.NOT. use_asm) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    nDOF = dofMap%nTotalEq
    dt = MAX(1.0e-10_wp, step%inc_ctrl%initial_inc)
    total_time = MAX(dt, step%time_period)
    IF (PRESENT(omega_max_out)) omega_max_out = 0.0_wp
    IF (PRESENT(dt_effective_out)) dt_effective_out = dt

    ALLOCATE(v_half(nDOF), F_ext(nDOF), R(nDOF), M_diag(nDOF))
    v_half = 0.0_wp
    F_ext = 0.0_wp
    R = 0.0_wp
    M_diag = 1.0_wp

    M_csr%init = .FALSE.
    CALL RT_Asm_CSRMass_FromModel(model, nDOF, MASS_TYPE_LUMP, M_csr, st)
    IF (st%status_code == IF_STATUS_OK .AND. M_csr%init .AND. &
        ALLOCATED(M_csr%rowPtr) .AND. ALLOCATED(M_csr%values)) THEN
      DO i = 1, nDOF
        IF (M_csr%rowPtr(i) >= 1 .AND. M_csr%rowPtr(i) <= SIZE(M_csr%values)) &
          M_diag(i) = M_csr%values(M_csr%rowPtr(i))
        IF (M_diag(i) < 1.0e-15_wp) M_diag(i) = 1.0_wp
      END DO
    END IF

    K_cfl%init = .FALSE.
    IF (PRESENT(apply_cfl_clamp) .AND. apply_cfl_clamp) THEN
      csf = 0.9_wp
      IF (PRESENT(cfl_safety)) csf = cfl_safety
      CALL RT_Asm_ComputeTangent(model, step, state, dofMap, u(1:nDOF), K_cfl, RT_Asm_Cfg(), st)
      IF (st%status_code == IF_STATUS_OK .AND. K_cfl%init) THEN
        CALL RT_Dyn_Clamp_dt_cfl_csr(dt, K_cfl, M_diag, nDOF, csf, dt, om_cfl)
        IF (PRESENT(omega_max_out)) omega_max_out = om_cfl
        CALL RT_CSR_Free(K_cfl)
      END IF
    END IF

    IF (PRESENT(dt_effective_out)) dt_effective_out = dt
    max_inc = MIN(step%inc_ctrl%max_num_inc, INT(total_time / dt, i4) + 1_i4)
    IF (max_inc < 1_i4) max_inc = 1_i4

    dyn_asm = RT_Asm_Cfg()
    t = 0.0_wp
    DO inc = 1, max_inc
      t = MIN(total_time, t + dt)
      CALL RT_Asm_GlobalLoad(model, step, t, dofMap, F_ext, dyn_asm, st)
      IF (st%status_code /= IF_STATUS_OK) EXIT
      CALL RT_Asm_ComputeResidual(model, step, state, dofMap, u(1:nDOF), 1.0_wp, F_ext, R, st, &
          asm_config=dyn_asm)
      IF (st%status_code /= IF_STATUS_OK) EXIT
      DO i = 1, nDOF
        v_half(i) = v_half(i) + dt * (R(i) / M_diag(i))
        u(i) = u(i) + dt * v_half(i)
      END DO
      IF (t >= total_time - 1.0e-12_wp) EXIT
    END DO

    IF (M_csr%init) CALL RT_CSR_Free(M_csr)
    DEALLOCATE(v_half, F_ext, R, M_diag)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_DynExpl_Run

  !===========================================================================
  ! RT_DynImpl_Run: Newmark-beta / HHT-alpha implicit dynamics
  !===========================================================================
  SUBROUTINE RT_DynImpl_Run(dyn_params, status, u, n_dof, model, step, state, dofMap)
    TYPE(UF_DynamicParams), INTENT(IN) :: dyn_params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), INTENT(INOUT), OPTIONAL :: u(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_dof
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(AnalysisStep), INTENT(IN), OPTIONAL :: step
    TYPE(StepStateData), INTENT(IN), OPTIONAL :: state
    TYPE(RT_Sol_DofMap), INTENT(IN), OPTIONAL :: dofMap

    INTEGER(i4) :: nDOF, inc, max_inc, i, j, it, scheme
    INTEGER(i4) :: max_nr_dyn
    REAL(wp) :: dt, total_time, t, t_np1, beta, gamma, c1, cg, ar, br, fac_k, fac_m
    REAL(wp) :: tol_du, tol_r, du_nrm, r_nrm, inv_beta_dt, half_over_beta_m1
    REAL(wp) :: alp
    REAL(wp), ALLOCATABLE :: v(:), a(:), u_n(:), v_n(:), a_n(:)
    REAL(wp), ALLOCATABLE :: F_ext(:), F_n_save(:), Rbf(:), R_n_save(:), Ma(:), Mv(:), Kv(:), rhs(:), du(:)
    REAL(wp), ALLOCATABLE :: a_np1(:), v_np1(:), K_eff(:,:), K_dense(:,:), M_dense(:,:)
    TYPE(RT_CSRMatrix) :: K_csr, M_csr
    TYPE(RT_LinearSolver) :: linear_solver
    TYPE(ErrorStatusType) :: st
    TYPE(RT_Asm_Cfg) :: asm_cfg
    LOGICAL :: use_asm, dense_ok, converged_nr, lin_ready, use_hht

    CALL init_error_status(status)
    lin_ready = .FALSE.

    use_asm = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(state) .AND. PRESENT(dofMap) &
         .AND. PRESENT(u) .AND. PRESENT(n_dof)
    IF (use_asm) use_asm = (dofMap%nTotalEq > 0_i4 .AND. SIZE(u) >= n_dof .AND. n_dof > 0_i4)

    IF (.NOT. use_asm) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    nDOF = dofMap%nTotalEq
    dt = MAX(1.0e-10_wp, step%inc_ctrl%initial_inc)
    total_time = MAX(dt, step%time_period)
    scheme = dyn_params%integration_type
    use_hht = (scheme == INTEG_HHT_ALPHA)

    beta = dyn_params%beta
    gamma = dyn_params%gamma
    IF (beta <= 0.0_wp .OR. beta > 0.5_wp) beta = 0.25_wp
    IF (gamma <= 0.0_wp .OR. gamma > 0.5_wp) gamma = 0.5_wp

    alp = 0.0_wp
    IF (use_hht) THEN
      alp = dyn_params%alpha
      IF (alp < -0.333_wp .OR. alp > 0.0_wp) alp = 0.0_wp
    END IF

    tol_du = dyn_params%tol_du
    tol_r = dyn_params%tol_r
    IF (tol_du <= 0.0_wp) tol_du = 1.0e-6_wp
    IF (tol_r <= 0.0_wp) tol_r = 1.0e-6_wp

    max_inc = MIN(step%inc_ctrl%max_num_inc, INT(total_time / dt, i4) + 1_i4)
    IF (max_inc < 1_i4) max_inc = 1_i4
    max_nr_dyn = 16_i4

    ALLOCATE(v(nDOF), a(nDOF), u_n(nDOF), v_n(nDOF), a_n(nDOF))
    ALLOCATE(F_ext(nDOF), F_n_save(nDOF), Rbf(nDOF), R_n_save(nDOF), Ma(nDOF), Mv(nDOF), Kv(nDOF), rhs(nDOF), du(nDOF))
    ALLOCATE(a_np1(nDOF), v_np1(nDOF), K_eff(nDOF, nDOF), K_dense(nDOF, nDOF), M_dense(nDOF, nDOF))

    u_n = u(1:nDOF)
    v_n = 0.0_wp
    a_n = 0.0_wp
    v = 0.0_wp
    a = 0.0_wp
    F_n_save = 0.0_wp
    R_n_save = 0.0_wp

    M_csr%init = .FALSE.
    CALL RT_Asm_CSRMass_FromModel(model, nDOF, MASS_TYPE_CONSIST, M_csr, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'RT_DynImpl_Run: mass assembly failed'
      RETURN
    END IF

    dense_ok = .FALSE.
    IF (M_csr%init) CALL RT_DynImpl_CSRToDense(M_csr, nDOF, M_dense, dense_ok)
    IF (.NOT. dense_ok) M_dense = 0.0_wp

    inv_beta_dt = 1.0_wp / (beta * dt * dt)
    half_over_beta_m1 = (0.5_wp / beta) - 1.0_wp
    c1 = inv_beta_dt
    cg = gamma / (beta * dt)

    asm_cfg = RT_Asm_Cfg()
    t = 0.0_wp
    DO inc = 1, max_inc
      t = MIN(total_time, t + dt)
      t_np1 = t

      CALL RT_Asm_GlobalLoad(model, step, t_np1, dofMap, F_ext, asm_cfg, st)
      IF (st%status_code /= IF_STATUS_OK) EXIT

      F_n_save = F_ext
      a_np1 = a_n
      v_np1 = v_n

      converged_nr = .FALSE.
      DO it = 1, max_nr_dyn
        CALL RT_Asm_ComputeTangent(model, step, state, dofMap, u(1:nDOF), K_csr, asm_cfg, st)
        IF (st%status_code /= IF_STATUS_OK) EXIT

        dense_ok = .FALSE.
        IF (K_csr%init) CALL RT_DynImpl_CSRToDense(K_csr, nDOF, K_dense, dense_ok)
        IF (.NOT. dense_ok) K_dense = 0.0_wp

        CALL RT_Asm_ComputeResidual(model, step, state, dofMap, u(1:nDOF), 1.0_wp, F_ext, Rbf, st, &
            asm_config=asm_cfg)
        IF (st%status_code /= IF_STATUS_OK) EXIT

        IF (use_hht) THEN
          CALL RT_DynImpl_MatVec(nDOF, M_dense, a_np1, Ma)
          CALL RT_DynImpl_MatVec(nDOF, M_dense, v_np1, Mv)
          R_n_save = (1.0_wp + alp) * Rbf - alp * R_n_save - Ma - (1.0_wp + alp) * 0.0_wp
        ELSE
          CALL RT_DynImpl_MatVec(nDOF, M_dense, a_np1, Ma)
          R_n_save = Rbf - Ma
        END IF

        fac_k = 1.0_wp
        IF (use_hht) fac_k = 1.0_wp + alp
        fac_m = c1
        fac_k = fac_k + fac_m * 0.0_wp

        DO i = 1, nDOF
          DO j = 1, nDOF
            K_eff(i, j) = fac_k * K_dense(i, j) + fac_m * M_dense(i, j)
          END DO
          rhs(i) = -R_n_save(i)
        END DO

        IF (.NOT. lin_ready) THEN
          CALL RT_LinearSolver_Init(linear_solver, nDOF, status)
          lin_ready = .TRUE.
        END IF

        CALL RT_LinearSolver_Solv(linear_solver, K_eff, rhs, du, st)
        IF (st%status_code /= IF_STATUS_OK) EXIT

        DO i = 1, nDOF
          u(i) = u(i) + du(i)
        END DO

        du_nrm = SQRT(SUM(du**2))
        r_nrm = SQRT(SUM(R_n_save**2))

        IF (du_nrm < tol_du .AND. r_nrm < tol_r) THEN
          converged_nr = .TRUE.
          EXIT
        END IF

        a_np1 = c1 * (u(1:nDOF) - u_n) - cg * v_n - half_over_beta_m1 * a_n
        v_np1 = v_n + dt * ((1.0_wp - gamma) * a_n + gamma * a_np1)
      END DO

      IF (.NOT. converged_nr) THEN
        status%status_code = IF_STATUS_WARN
        status%message = 'RT_DynImpl_Run: NR did not converge at some increment'
      END IF

      u_n = u(1:nDOF)
      v_n = v_np1
      a_n = a_np1
      R_n_save = Rbf

      IF (t >= total_time - 1.0e-12_wp) EXIT
    END DO

    IF (M_csr%init) CALL RT_CSR_Free(M_csr)
    IF (lin_ready) CALL RT_LinearSolver_Clean(linear_solver)
    DEALLOCATE(v, a, u_n, v_n, a_n, F_ext, F_n_save, Rbf, R_n_save, Ma, Mv, Kv, rhs, du, a_np1, v_np1, K_eff, K_dense, M_dense)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_DynImpl_Run

  !===========================================================================
  ! Internal utilities
  !===========================================================================
  SUBROUTINE RT_DynImpl_CSRToDense(K_csr, nDOF, K_dense, ok)
    TYPE(RT_CSRMatrix), INTENT(IN) :: K_csr
    INTEGER(i4), INTENT(IN) :: nDOF
    REAL(wp), INTENT(INOUT) :: K_dense(:,:)
    LOGICAL, INTENT(OUT) :: ok
    INTEGER(i4) :: i, j, k, p0, p1
    ok = .FALSE.
    K_dense = 0.0_wp
    IF (.NOT. K_csr%init) RETURN
    IF (K_csr%nRows /= nDOF .OR. K_csr%nCols /= nDOF) RETURN
    IF (.NOT. ALLOCATED(K_csr%rowPtr) .OR. .NOT. ALLOCATED(K_csr%colInd) .OR. &
        .NOT. ALLOCATED(K_csr%values)) RETURN
    DO i = 1, nDOF
      p0 = K_csr%rowPtr(i)
      p1 = K_csr%rowPtr(i + 1) - 1
      DO k = p0, p1
        j = K_csr%colInd(k)
        IF (j >= 1_i4 .AND. j <= nDOF) K_dense(i, j) = K_dense(i, j) + K_csr%values(k)
      END DO
    END DO
    ok = .TRUE.
  END SUBROUTINE RT_DynImpl_CSRToDense

  SUBROUTINE RT_DynImpl_MatVec(n, A, x, y)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: A(n, n), x(n)
    REAL(wp), INTENT(OUT) :: y(n)
    INTEGER(i4) :: i, j
    REAL(wp) :: s
    DO i = 1, n
      s = 0.0_wp
      DO j = 1, n
        s = s + A(i, j) * x(j)
      END DO
      y(i) = s
    END DO
  END SUBROUTINE RT_DynImpl_MatVec

END MODULE RT_Step_Impl