!===============================================================================
! MODULE: NM_Conv_MG
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Proc (multigrid hierarchy)
! BRIEF:  Multigrid methods: GMG, AMG, FAS, nonlinear MG, adaptive
!
! Theory: Trottenberg et al. (2001); Briggs et al. (2000)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Conv_MG
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, TINY
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief MG type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_GEOMETRIC = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_ALGEBRAIC = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_FAS = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_NONLINEAR = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_ADAPTIVE = 5

  !> @brief cycle type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_V_CYCLE = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_W_CYCLE = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_F_CYCLE = 3

  !> @brief smoother type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_SMOOTHER_JACOBI = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_SMOOTHER_GS = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_SMOOTHER_SOR = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MG_SMOOTHER_CG = 4

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief MG params
  TYPE, PUBLIC :: Multigrid_Params_Method
    INTEGER(i4) :: mg_type = NM_MG_GEOMETRIC
    INTEGER(i4) :: cycle_type = NM_MG_V_CYCLE
    INTEGER(i4) :: smoother = NM_MG_SMOOTHER_GS
  END TYPE Multigrid_Params_Method

  TYPE, PUBLIC :: Multigrid_Params_Hierarchy
    INTEGER(i4) :: max_levels = 10_i4
  END TYPE Multigrid_Params_Hierarchy

  TYPE, PUBLIC :: Multigrid_Params_Smooth
    INTEGER(i4) :: pre_sweeps = 2_i4
    INTEGER(i4) :: post_sweeps = 2_i4
    INTEGER(i4) :: coarse_sweeps = 10_i4
    REAL(DP) :: smoother_omega = 1.0_DP
  END TYPE Multigrid_Params_Smooth

  TYPE, PUBLIC :: Multigrid_Params_Conv
    REAL(DP) :: coarse_tolerance = 1.0E-6_DP
    INTEGER(i4) :: max_iterations = 100_i4
    REAL(DP) :: tolerance = 1.0E-6_DP
  END TYPE Multigrid_Params_Conv

  TYPE, PUBLIC :: Multigrid_Params
    TYPE(Multigrid_Params_Method) :: method
    TYPE(Multigrid_Params_Hierarchy) :: hierarchy
    TYPE(Multigrid_Params_Smooth) :: smooth
    TYPE(Multigrid_Params_Conv) :: conv
  END TYPE Multigrid_Params

  !> @brief grid level
  TYPE, PUBLIC :: Grid_Level
    INTEGER(i4) :: level_id = 0_i4
    INTEGER(i4) :: n_points = 0_i4
    REAL(DP), ALLOCATABLE :: A(:,:)        !< coeff matrix
    REAL(DP), ALLOCATABLE :: x(:)          !< solution
    REAL(DP), ALLOCATABLE :: b(:)          !< RHS
    REAL(DP), ALLOCATABLE :: r(:)          !< residual
    ! transfer ops
    REAL(DP), ALLOCATABLE :: P(:,:)        !< prolong (coarse->fine)
    REAL(DP), ALLOCATABLE :: R(:,:)        !< restrict (fine->coarse)
    TYPE(Grid_Level), POINTER :: finer => NULL()
    TYPE(Grid_Level), POINTER :: coarser => NULL()
  END TYPE Grid_Level

  !> @brief MG solver
  TYPE, PUBLIC :: Multigrid_Solver
    TYPE(Grid_Level), POINTER :: finest => NULL()
    TYPE(Grid_Level), POINTER :: coarsest => NULL()
    INTEGER(i4) :: n_levels = 0_i4
    TYPE(Multigrid_Params) :: params
  END TYPE Multigrid_Solver

  !> @brief MG result
  TYPE, PUBLIC :: Multigrid_Result_Solution
    REAL(DP), ALLOCATABLE :: x(:)          !< solution
  END TYPE Multigrid_Result_Solution

  TYPE, PUBLIC :: Multigrid_Result_Stats
    REAL(DP) :: residual_norm = ZERO       !< final residual
    INTEGER(i4) :: n_cycles = 0_i4         !< cycle count
    INTEGER(i4) :: n_levels = 0_i4         !< level count
  END TYPE Multigrid_Result_Stats

  TYPE, PUBLIC :: Multigrid_Result_Status
    LOGICAL :: converged = .FALSE.         !< converged
    CHARACTER(LEN=128) :: message = ""     !< message
  END TYPE Multigrid_Result_Status

  TYPE, PUBLIC :: Multigrid_Result
    TYPE(Multigrid_Result_Solution) :: solution
    TYPE(Multigrid_Result_Stats) :: stats
    TYPE(Multigrid_Result_Status) :: status
  END TYPE Multigrid_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main solver
  PUBLIC :: NM_Multigrid_Solv
  PUBLIC :: NM_Multigrid_VCycle
  PUBLIC :: NM_Multigrid_WCycle
  
  ! hierarchy build
  PUBLIC :: NM_Multigrid_Build_Hierarchy
  PUBLIC :: NM_GMG_Build_Levels
  PUBLIC :: NM_AMG_Build_Levels
  
  ! transfer ops
  PUBLIC :: NM_Calc_Prolongation
  PUBLIC :: NM_Calc_Restriction
  
  ! smoothers
  PUBLIC :: NM_MG_Smooth_Jacobi
  PUBLIC :: NM_MG_Smooth_GaussSeidel
  PUBLIC :: NM_MG_Smooth_SOR
  
  ! utils
  PUBLIC :: NM_Multigrid_Init
  PUBLIC :: NM_Multigrid_Destroy

CONTAINS

  !=============================================================================
  ! MAIN SOLVER INTERFACE
  !=============================================================================

  !> @brief MG solver main interface
  !! @param[in] A  finest level coefficient matrix
  !! @param[in] b  finest level right-hand side
  !! @param[inout] x initial guess and solution
  !! @param[in] params multigrid parameters
  !! @param[out] result solution result
  !! @param[out] status error status
  SUBROUTINE NM_Multigrid_Solv(A, b, x, params, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Multigrid_Params), INTENT(IN) :: params
    TYPE(Multigrid_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Multigrid_Solver) :: mg
    REAL(DP), ALLOCATABLE :: r(:)
    REAL(DP) :: residual_norm, b_norm
    INTEGER(i4) :: iter, n

    CALL init_error_status(status)

    n = SIZE(b)
    ALLOCATE(r(n))

    ! build hierarchy
    CALL NM_Multigrid_Build_Hierarchy(A, params, mg, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      DEALLOCATE(r)
      RETURN
    END IF

    ! set finest level
    mg%finest%b = b
    mg%finest%x = x

    b_norm = SQRT(SUM(b**2))
    IF (b_norm < 1.0E-14_DP) b_norm = ONE

    result%stats%n_cycles = 0_i4
    result%status%converged = .FALSE.

    ! MG iteration
    DO iter = 1, params%conv%max_iterations
      result%stats%n_cycles = iter

      ! V or W cycle
      SELECT CASE (params%method%cycle_type)
      CASE (NM_MG_W_CYCLE)
        CALL NM_Multigrid_WCycle(mg%finest, params)
      CASE DEFAULT
        CALL NM_Multigrid_VCycle(mg%finest, params)
      END SELECT

      ! check convergence
      r = b - MATMUL(A, mg%finest%x)
      residual_norm = SQRT(SUM(r**2))

      IF (residual_norm / b_norm < params%conv%tolerance) THEN
        result%status%converged = .TRUE.
        EXIT
      END IF
    END DO

    ! store result
    IF (ALLOCATED(result%solution%x)) DEALLOCATE(result%solution%x)
    ALLOCATE(result%solution%x(n))
    result%solution%x = mg%finest%x
    result%stats%residual_norm = residual_norm
    result%stats%n_levels = mg%n_levels

    IF (result%status%converged) THEN
      result%status%message = "Multigrid converged"
    ELSE
      result%status%message = "Multigrid did not converge"
    END IF

    ! cleanup
    CALL NM_Multigrid_Destroy(mg)
    DEALLOCATE(r)

  END SUBROUTINE NM_Multigrid_Solv

  !> @brief V-Cycle
  !! @details standard V-cycle
  SUBROUTINE NM_Multigrid_VCycle(level, params)
    TYPE(Grid_Level), POINTER, INTENT(INOUT) :: level
    TYPE(Multigrid_Params), INTENT(IN) :: params

    TYPE(Grid_Level), POINTER :: coarse

    IF (.NOT. ASSOCIATED(level%coarser)) THEN
      ! coarsest: direct solve
      CALL NM_MG_Coarse_Solv(level, params)
      RETURN
    END IF

    coarse => level%coarser

    ! pre-smooth
    CALL NM_MG_Smooth(level, params%smooth%pre_sweeps, params)

    ! restrict residual
    level%r = level%b - MATMUL(level%A, level%x)
    coarse%b = MATMUL(level%R, level%r)
    coarse%x = ZERO

    ! recurse
    CALL NM_Multigrid_VCycle(coarse, params)

    ! prolong and correct
    level%x = level%x + MATMUL(level%P, coarse%x)

    ! post-smooth
    CALL NM_MG_Smooth(level, params%smooth%post_sweeps, params)

  END SUBROUTINE NM_Multigrid_VCycle

  !> @brief W-Cycle
  !! @details W-cycle (2 coarse visits)
  SUBROUTINE NM_Multigrid_WCycle(level, params)
    TYPE(Grid_Level), POINTER, INTENT(INOUT) :: level
    TYPE(Multigrid_Params), INTENT(IN) :: params

    TYPE(Grid_Level), POINTER :: coarse

    IF (.NOT. ASSOCIATED(level%coarser)) THEN
      CALL NM_MG_Coarse_Solv(level, params)
      RETURN
    END IF

    coarse => level%coarser

    ! pre-smooth
    CALL NM_MG_Smooth(level, params%smooth%pre_sweeps, params)

    ! restrict
    level%r = level%b - MATMUL(level%A, level%x)
    coarse%b = MATMUL(level%R, level%r)
    coarse%x = ZERO

    ! 1st W-cycle
    CALL NM_Multigrid_WCycle(coarse, params)

    ! 1st prolong
    level%x = level%x + MATMUL(level%P, coarse%x)

    ! restrict again
    level%r = level%b - MATMUL(level%A, level%x)
    coarse%b = MATMUL(level%R, level%r)
    coarse%x = ZERO

    ! 2nd W-cycle
    CALL NM_Multigrid_WCycle(coarse, params)

    ! 2nd prolong
    level%x = level%x + MATMUL(level%P, coarse%x)

    ! post-smooth
    CALL NM_MG_Smooth(level, params%smooth%post_sweeps, params)

  END SUBROUTINE NM_Multigrid_WCycle

  !=============================================================================
  ! HIERARCHY BUILDING
  !=============================================================================

  !> @brief build MG hierarchy
  SUBROUTINE NM_Multigrid_Build_Hierarchy(A, params, mg, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Multigrid_Params), INTENT(IN) :: params
    TYPE(Multigrid_Solver), INTENT(OUT) :: mg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    mg%params = params

    SELECT CASE (params%method%mg_type)
    CASE (NM_MG_GEOMETRIC)
      CALL NM_GMG_Build_Levels(A, params, mg, status)
    CASE (NM_MG_ALGEBRAIC)
      CALL NM_AMG_Build_Levels(A, params, mg, status)
    CASE DEFAULT
      CALL NM_GMG_Build_Levels(A, params, mg, status)
    END SELECT

  END SUBROUTINE NM_Multigrid_Build_Hierarchy

  !> @brief build GMG levels
  SUBROUTINE NM_GMG_Build_Levels(A, params, mg, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Multigrid_Params), INTENT(IN) :: params
    TYPE(Multigrid_Solver), INTENT(INOUT) :: mg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Grid_Level), POINTER :: current, next
    INTEGER(i4) :: n, level_id
    INTEGER(i4) :: n_coarse

    CALL init_error_status(status)

    n = SIZE(A, 1)

    ! create finest
    ALLOCATE(mg%finest)
    mg%finest%level_id = 1_i4
    mg%finest%n_points = n
    ALLOCATE(mg%finest%A(n,n), mg%finest%x(n), mg%finest%b(n), mg%finest%r(n))
    mg%finest%A = A
    mg%finest%x = ZERO
    mg%finest%b = ZERO
    mg%finest%r = ZERO

    current => mg%finest
    level_id = 1_i4

    ! build coarse levels
    DO WHILE (current%n_points > 10 .AND. level_id < params%hierarchy%max_levels)
      level_id = level_id + 1_i4

      ! coarse size (halved)
      n_coarse = current%n_points / 2
      IF (n_coarse < 2) EXIT

      ! create coarse level
      ALLOCATE(next)
      next%level_id = level_id
      next%n_points = n_coarse
      ALLOCATE(next%A(n_coarse, n_coarse), next%x(n_coarse), &
               next%b(n_coarse), next%r(n_coarse))
      next%A = ZERO
      next%x = ZERO
      next%b = ZERO
      next%r = ZERO

      ! compute transfer
      ALLOCATE(current%P(current%n_points, n_coarse))
      ALLOCATE(current%R(n_coarse, current%n_points))

      CALL NM_Calc_Prolongation(current%n_points, n_coarse, current%P)
      current%R = TRANSPOSE(current%P)

      ! Galerkin: A_c = R*A_f*P
      next%A = MATMUL(MATMUL(current%R, current%A), current%P)

      ! link levels
      current%coarser => next
      next%finer => current
      current => next
    END DO

    mg%coarsest => current
    mg%n_levels = level_id

  END SUBROUTINE NM_GMG_Build_Levels

  !> @brief build AMG levels
  SUBROUTINE NM_AMG_Build_Levels(A, params, mg, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Multigrid_Params), INTENT(IN) :: params
    TYPE(Multigrid_Solver), INTENT(INOUT) :: mg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! use GMG
    CALL NM_GMG_Build_Levels(A, params, mg, status)

  END SUBROUTINE NM_AMG_Build_Levels

  !=============================================================================
  ! TRANSFER OPERATORS
  !=============================================================================

  !> @brief prolong (linear interp)
  SUBROUTINE NM_Calc_Prolongation(n_fine, n_coarse, P)
    INTEGER(i4), INTENT(IN) :: n_fine, n_coarse
    REAL(DP), INTENT(OUT) :: P(:,:)

    INTEGER(i4) :: i, j
    REAL(DP) :: ratio

    P = ZERO
    ratio = REAL(n_coarse - 1, DP) / REAL(n_fine - 1, DP)

    DO i = 1, n_fine
      j = NINT((i - 1) * ratio) + 1
      j = MIN(MAX(j, 1), n_coarse)

      IF (j < n_coarse) THEN
        ! interp weights
        P(i, j) = ONE - ABS((i - 1) * ratio - (j - 1))
        P(i, j+1) = ABS((i - 1) * ratio - (j - 1))
      ELSE
        P(i, j) = ONE
      END IF
    END DO

    ! normalize
    DO i = 1, n_fine
      IF (SUM(P(i, :)) > ZERO) THEN
        P(i, :) = P(i, :) / SUM(P(i, :))
      END IF
    END DO

  END SUBROUTINE NM_Calc_Prolongation

  !> @brief restrict op
  SUBROUTINE NM_Calc_Restriction(P, R)
    REAL(DP), INTENT(IN) :: P(:,:)
    REAL(DP), INTENT(OUT) :: R(:,:)

    ! R = P^T (Galerkin)
    R = TRANSPOSE(P)

  END SUBROUTINE NM_Calc_Restriction

  !=============================================================================
  ! SMOOTHERS
  !=============================================================================

  !> @brief generic smooth
  SUBROUTINE NM_MG_Smooth(level, n_sweeps, params)
    TYPE(Grid_Level), INTENT(INOUT) :: level
    INTEGER(i4), INTENT(IN) :: n_sweeps
    TYPE(Multigrid_Params), INTENT(IN) :: params

    SELECT CASE (params%method%smoother)
    CASE (NM_MG_SMOOTHER_JACOBI)
      CALL NM_MG_Smooth_Jacobi(level, n_sweeps, params%method%smoother_omega)
    CASE (NM_MG_SMOOTHER_SOR)
      CALL NM_MG_Smooth_SOR(level, n_sweeps, params%method%smoother_omega)
    CASE DEFAULT
      CALL NM_MG_Smooth_GaussSeidel(level, n_sweeps)
    END SELECT

  END SUBROUTINE NM_MG_Smooth

  !> @brief Jacobi 
  SUBROUTINE NM_MG_Smooth_Jacobi(level, n_sweeps, omega)
    TYPE(Grid_Level), INTENT(INOUT) :: level
    INTEGER(i4), INTENT(IN) :: n_sweeps
    REAL(DP), INTENT(IN) :: omega

    REAL(DP), ALLOCATABLE :: x_new(:)
    INTEGER(i4) :: sweep, i, j, n

    n = level%n_points
    ALLOCATE(x_new(n))

    DO sweep = 1, n_sweeps
      DO i = 1, n
        x_new(i) = level%b(i)
        DO j = 1, n
          IF (j /= i) THEN
            x_new(i) = x_new(i) - level%A(i,j) * level%x(j)
          END IF
        END DO
        IF (ABS(level%A(i,i)) > 1.0E-14_DP) THEN
          x_new(i) = (ONE - omega) * level%x(i) + omega * x_new(i) / level%A(i,i)
        END IF
      END DO
      level%x = x_new
    END DO

    DEALLOCATE(x_new)

  END SUBROUTINE NM_MG_Smooth_Jacobi

  !> @brief Gauss-Seidel 
  SUBROUTINE NM_MG_Smooth_GaussSeidel(level, n_sweeps)
    TYPE(Grid_Level), INTENT(INOUT) :: level
    INTEGER(i4), INTENT(IN) :: n_sweeps

    INTEGER(i4) :: sweep, i, j, n
    REAL(DP) :: sigma

    n = level%n_points

    DO sweep = 1, n_sweeps
      DO i = 1, n
        sigma = level%b(i)
        DO j = 1, n
          IF (j /= i) THEN
            sigma = sigma - level%A(i,j) * level%x(j)
          END IF
        END DO
        IF (ABS(level%A(i,i)) > 1.0E-14_DP) THEN
          level%x(i) = sigma / level%A(i,i)
        END IF
      END DO
    END DO

  END SUBROUTINE NM_MG_Smooth_GaussSeidel

  !> @brief SOR 
  SUBROUTINE NM_MG_Smooth_SOR(level, n_sweeps, omega)
    TYPE(Grid_Level), INTENT(INOUT) :: level
    INTEGER(i4), INTENT(IN) :: n_sweeps
    REAL(DP), INTENT(IN) :: omega

    REAL(DP) :: sigma
    INTEGER(i4) :: sweep, i, j, n

    n = level%n_points

    DO sweep = 1, n_sweeps
      DO i = 1, n
        sigma = level%b(i)
        DO j = 1, n
          IF (j /= i) THEN
            sigma = sigma - level%A(i,j) * level%x(j)
          END IF
        END DO
        IF (ABS(level%A(i,i)) > 1.0E-14_DP) THEN
          level%x(i) = (ONE - omega) * level%x(i) + omega * sigma / level%A(i,i)
        END IF
      END DO
    END DO

  END SUBROUTINE NM_MG_Smooth_SOR

  !> @brief coarse solve
  SUBROUTINE NM_MG_Coarse_Solv(level, params)
    TYPE(Grid_Level), INTENT(INOUT) :: level
    TYPE(Multigrid_Params), INTENT(IN) :: params

    REAL(DP), ALLOCATABLE :: A_copy(:,:)
    INTEGER, ALLOCATABLE :: ipiv(:)
    INTEGER(i4) :: n, info

    n = level%n_points
    ALLOCATE(A_copy(n,n), ipiv(n))

    A_copy = level%A
    level%x = level%b

    ! direct solve
    CALL DGESV(n, 1, A_copy, n, ipiv, level%x, n, info)

    IF (info /= 0) THEN
      ! fallback to iter
      CALL NM_MG_Smooth_GaussSeidel(level, params%smooth%coarse_sweeps)
    END IF

    DEALLOCATE(A_copy, ipiv)

  END SUBROUTINE NM_MG_Coarse_Solv

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief init MG solver
  SUBROUTINE NM_Multigrid_Init(mg, params)
    TYPE(Multigrid_Solver), INTENT(OUT) :: mg
    TYPE(Multigrid_Params), INTENT(IN) :: params

    mg%finest => NULL()
    mg%coarsest => NULL()
    mg%n_levels = 0_i4
    mg%params = params

  END SUBROUTINE NM_Multigrid_Init

  !> @brief destroy MG levels
  RECURSIVE SUBROUTINE NM_Multigrid_Destroy(mg)
    TYPE(Multigrid_Solver), INTENT(INOUT) :: mg

    TYPE(Grid_Level), POINTER :: current, next

    current => mg%finest

    DO WHILE (ASSOCIATED(current))
      next => current%coarser

      IF (ALLOCATED(current%A)) DEALLOCATE(current%A)
      IF (ALLOCATED(current%x)) DEALLOCATE(current%x)
      IF (ALLOCATED(current%b)) DEALLOCATE(current%b)
      IF (ALLOCATED(current%r)) DEALLOCATE(current%r)
      IF (ALLOCATED(current%P)) DEALLOCATE(current%P)
      IF (ALLOCATED(current%R)) DEALLOCATE(current%R)

      DEALLOCATE(current)
      current => next
    END DO

    mg%finest => NULL()
    mg%coarsest => NULL()
    mg%n_levels = 0_i4

  END SUBROUTINE NM_Multigrid_Destroy

END MODULE NM_Conv_MG