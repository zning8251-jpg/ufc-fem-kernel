! Harness-only MD_Step_Proc subset for Phase6 driver / arclen smoke.
MODULE MD_Step_Proc
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: AnalysisStep, MD_NonlinSolv, MD_SolverState, StepStateData

  TYPE :: AnalysisStep
    REAL(wp) :: time_period = 1.0_wp
    REAL(wp) :: start_time = 0.0_wp
    CHARACTER(LEN=80) :: name = ''
    INTEGER(i4) :: procedure = 0_i4
  END TYPE AnalysisStep

  TYPE :: MD_NonlinSolv
    INTEGER(i4) :: method = 0_i4
    INTEGER(i4) :: max_iterations = 25_i4
    REAL(wp) :: tolerance_force = 1.0E-5_wp
    REAL(wp) :: tolerance_displacement = 1.0E-5_wp
    REAL(wp) :: tolerance_energy = 1.0E-5_wp
    REAL(wp) :: arc_constraint_tol_scale = 1.0_wp
    LOGICAL :: arc_nonconverge_use_warn = .TRUE.
  END TYPE MD_NonlinSolv

  TYPE :: MD_SolverState
    REAL(wp), ALLOCATABLE :: u(:)
    REAL(wp), ALLOCATABLE :: du(:)
    REAL(wp), ALLOCATABLE :: R(:)
    REAL(wp) :: lambda = 0.0_wp
    REAL(wp) :: arc_length = 0.0_wp
    REAL(wp) :: residual_norm = 0.0_wp
    REAL(wp) :: displacement_norm = 0.0_wp
    REAL(wp) :: energy_norm = 0.0_wp
    INTEGER(i4) :: iteration = 0_i4
    INTEGER(i4) :: iterations = 0_i4
    LOGICAL :: converged = .FALSE.
  END TYPE MD_SolverState

  TYPE :: StepStateData
    REAL(wp) :: currentTime = 0.0_wp
  END TYPE StepStateData

END MODULE MD_Step_Proc
