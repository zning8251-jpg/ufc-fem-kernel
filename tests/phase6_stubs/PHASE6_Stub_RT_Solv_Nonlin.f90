! Harness-only RT_Solv_Nonlin: RT_NLSolver_ArcLen entry contract (assembly path required).
! Mirrors production guard in ufc_core/L5_RT/Solver/RT_Solv_Nonlin.f90 for Phase6 track12 smoke.
MODULE RT_Solv_Nonlin
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Model_Lib_Core, ONLY: UF_Model
  USE MD_Step_Proc, ONLY: MD_NonlinSolv, MD_SolverState, AnalysisStep, StepStateData
  USE RT_Solv_Def, ONLY: RT_Sol_DofMap, RT_CSRMatrix
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: RT_NLSolver_ArcLen

CONTAINS

  SUBROUTINE RT_NLSolver_ArcLen(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &
                                arc_length_init, arc_min, arc_max, psi, l3_csr_reanalyze_required)
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
    LOGICAL :: use_assembly

    CALL init_error_status(local_status)
    result = .FALSE.

    IF (solver%max_iterations <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Arc-length: Invalid max_iterations'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF

    use_assembly = PRESENT(model) .AND. PRESENT(step) .AND. PRESENT(step_state) .AND. &
                   PRESENT(dofMap) .AND. PRESENT(F_ext) .AND. PRESENT(K_CSR)

    IF (.NOT. use_assembly) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Arc-length: assembly path required (model, step, step_state, dofMap, F_ext, K_CSR)'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF

    ! Harness: assembly args present but no full solve — report not implemented
    local_status%status_code = IF_STATUS_INVALID
    local_status%message = 'Arc-length: assembly path required (model, step, step_state, dofMap, F_ext, K_CSR)'
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE RT_NLSolver_ArcLen

END MODULE RT_Solv_Nonlin
