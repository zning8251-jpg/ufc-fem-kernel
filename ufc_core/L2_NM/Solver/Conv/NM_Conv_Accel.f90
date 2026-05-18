!===============================================================================
! MODULE: NM_Conv_Accel
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Proc (convergence acceleration methods)
! BRIEF:  Aitken, Shanks, epsilon, Richardson, vector epsilon extrapolation
!
! Theory: Brezinski & Redivo Zaglia (1991); Weniger (1989)
!
! Status: CORE | Last verified: 2026-03-24
!===============================================================================

MODULE NM_Conv_Accel
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, TINY
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief acceleration method enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACCEL_AITKEN = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACCEL_SHANKS = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACCEL_EPSILON = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACCEL_RICHARDSON = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACCEL_VEC_EPS = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ACCEL_MIN_POLY = 6

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief accelerator params
    TYPE, PUBLIC :: Accel_Params_Ctrl
    INTEGER(i4) :: method = NM_ACCEL_AITKEN
    INTEGER(i4) :: max_iterations = 100_i4
  END TYPE Accel_Params_Ctrl

  TYPE, PUBLIC :: Accel_Params_Tol
    REAL(DP) :: tolerance = 1.0E-10_DP
  END TYPE Accel_Params_Tol

  TYPE, PUBLIC :: Accel_Params_Order
    INTEGER(i4) :: shanks_order = 2_i4       !< Shanksorder
    INTEGER(i4) :: epsilon_order = 6_i4      !< epsilon algorithm order
    INTEGER(i4) :: richardson_order = 4_i4   !< Richardson extrapolation order
  END TYPE Accel_Params_Order

  TYPE, PUBLIC :: Accel_Params_Flags
    LOGICAL :: adaptive = .TRUE.             !< adaptive method selection
  END TYPE Accel_Params_Flags

  TYPE, PUBLIC :: Accel_Params
    TYPE(Accel_Params_Ctrl)  :: ctrl
    TYPE(Accel_Params_Tol)   :: tol
    TYPE(Accel_Params_Order) :: order
    TYPE(Accel_Params_Flags) :: flags
  END TYPE Accel_Params

  !> @brief sequence storage
  TYPE, PUBLIC :: Seq_Storage
    REAL(DP), ALLOCATABLE :: values(:)       !< scalar seq
    REAL(DP), ALLOCATABLE :: vectors(:,:)    !< vector seq
    INTEGER(i4) :: n_terms = 0_i4            !< current terms
    INTEGER(i4) :: max_terms = 0_i4          !< max terms
    INTEGER(i4) :: dimension = 1_i4          !< dim (1=scalar)
  END TYPE Seq_Storage

  !> @brief epsilon table
  TYPE, PUBLIC :: Eps_Table
    REAL(DP), ALLOCATABLE :: table(:,:)      !< epsilon table
    INTEGER(i4) :: order = 0_i4              !< current order
  END TYPE Eps_Table

  !> @brief vector epsilon table
  TYPE, PUBLIC :: Vec_Eps_Table
    REAL(DP), ALLOCATABLE :: table(:,:,:)    !< vector eps table
    INTEGER(i4) :: order = 0_i4
  END TYPE Vec_Eps_Table

  !> @brief acceleration result
    TYPE, PUBLIC :: Accel_Result_Sol
    REAL(DP) :: value = ZERO                 !< scalar result
    REAL(DP), ALLOCATABLE :: vector(:)       !< vector result
  END TYPE Accel_Result_Sol

  TYPE, PUBLIC :: Accel_Result_Error
    REAL(DP) :: error_estimate = ZERO        !< error est
  END TYPE Accel_Result_Error

  TYPE, PUBLIC :: Accel_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4       !< iter count
  END TYPE Accel_Result_Stats

  TYPE, PUBLIC :: Accel_Result_Flags
    LOGICAL :: converged = .FALSE.           !< converged
  END TYPE Accel_Result_Flags

  TYPE, PUBLIC :: Accel_Result_Meta
    CHARACTER(LEN=128) :: message = ""       !< message
  END TYPE Accel_Result_Meta

  TYPE, PUBLIC :: Accel_Result
    TYPE(Accel_Result_Sol)   :: sol
    TYPE(Accel_Result_Error) :: error
    TYPE(Accel_Result_Stats) :: stats
    TYPE(Accel_Result_Flags) :: flags
    TYPE(Accel_Result_Meta)  :: meta
  END TYPE Accel_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main interface
  PUBLIC :: NM_Accel_Seq
  PUBLIC :: NM_Accel_VecSeq
  
  ! Aitken
  PUBLIC :: NM_Aitken_D2
  PUBLIC :: NM_Aitken_Iter
  
  ! Shanks
  PUBLIC :: NM_Shanks_Tf
  PUBLIC :: NM_Shanks_Tf_Ord
  
  ! epsilon
  PUBLIC :: NM_Eps_Algo
  PUBLIC :: NM_Build_Eps_Tbl
  PUBLIC :: NM_Eps_Extrap
  
  ! vector epsilon algorithm
  PUBLIC :: NM_Vec_Eps_Algo
  
  ! Richardson extrapolation
  PUBLIC :: NM_Rich_Extrap
  
  ! utils
  PUBLIC :: NM_Store_SeqTerm
  PUBLIC :: NM_Err_Est
  PUBLIC :: NM_Select_Method

CONTAINS

  SUBROUTINE NM_Accel_Seq(params, sequence, result, status)
    TYPE(Accel_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: sequence(:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (SIZE(sequence) < 3) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Sequence too short for acceleration"
      RETURN
    END IF

    SELECT CASE (params%ctrl%method)
    CASE (NM_ACCEL_AITKEN)
      CALL NM_Aitken_D2(sequence, result, status)
    CASE (NM_ACCEL_SHANKS)
      CALL NM_Shanks_Tf_Ord(sequence, params%order%shanks_order, &
                             result, status)
    CASE (NM_ACCEL_EPSILON)
      CALL NM_Eps_Algo(sequence, result, status)
    CASE (NM_ACCEL_RICHARDSON)
      CALL NM_Rich_Extrap(sequence, params%order%richardson_order, &
                          result, status)
    CASE DEFAULT
      CALL NM_Aitken_D2(sequence, result, status)
    END SELECT

  END SUBROUTINE NM_Accel_Seq

  SUBROUTINE NM_Accel_VecSeq(params, sequence, result, status)
    TYPE(Accel_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: sequence(:,:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_dim, n_terms

    CALL init_error_status(status)

    n_dim = SIZE(sequence, 1)
    n_terms = SIZE(sequence, 2)

    IF (n_terms < 3) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Vector sequence too short for acceleration"
      RETURN
    END IF

    IF (.NOT. ALLOCATED(result%sol%vector)) ALLOCATE(result%sol%vector(n_dim))

    SELECT CASE (params%ctrl%method)
    CASE (NM_ACCEL_VEC_EPS)
      CALL NM_Vec_Eps_Algo(sequence, result, status)
    CASE DEFAULT
      ! Aitken per component
      CALL NM_Vec_Aitken(sequence, result, status)
    END SELECT

  END SUBROUTINE NM_Accel_VecSeq

  SUBROUTINE NM_Aitken_D2(sequence, result, status)
    REAL(DP), INTENT(IN) :: sequence(:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: delta1, delta2, denominator
    INTEGER(i4) :: n

    CALL init_error_status(status)

    n = SIZE(sequence)

    ! use last 3 terms
    delta1 = sequence(n) - sequence(n-1)
    delta2 = sequence(n-1) - sequence(n-2)
    denominator = delta1 - delta2

    IF (ABS(denominator) < 1.0E-14_DP) THEN
      ! denom too small
      result%sol%value = sequence(n)
      result%error%error_estimate = ABS(delta1)
      result%meta%message = "Aitken: denominator too small"
    ELSE
      ! Aitken accel
      result%sol%value = sequence(n-2) - delta2**2 / denominator
      result%error%error_estimate = ABS(sequence(n) - result%sol%value)
      result%flags%converged = (result%error%error_estimate < 1.0E-10_DP)
      result%meta%message = "Aitken acceleration applied"
    END IF

    result%stats%n_iterations = n

  END SUBROUTINE NM_Aitken_D2

  SUBROUTINE NM_Aitken_Iter(x0, fixed_point_func, tol, max_iter, &
                             result, status)
    REAL(DP), INTENT(IN) :: x0
    INTERFACE
      FUNCTION fixed_point_func(x) RESULT(fx)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x
        REAL(DP) :: fx
      END FUNCTION
    END INTERFACE
    REAL(DP), INTENT(IN) :: tol
    INTEGER(i4), INTENT(IN) :: max_iter
    TYPE(Acceleration_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: x(3), x_accel
    REAL(DP) :: delta1, delta2, denominator
    INTEGER(i4) :: iter

    CALL init_error_status(status)

    ! initial
    x(1) = x0
    x(2) = fixed_point_func(x(1))
    x(3) = fixed_point_func(x(2))

    DO iter = 1, max_iter
      ! Aitken accel
      delta1 = x(3) - x(2)
      delta2 = x(2) - x(1)
      denominator = delta1 - delta2

      IF (ABS(denominator) > 1.0E-14_DP) THEN
        x_accel = x(1) - delta2**2 / denominator
      ELSE
        x_accel = x(3)
      END IF

      ! check convergence
      result%error%error_estimate = ABS(x_accel - x(3))
      IF (result%error%error_estimate < tol) THEN
        result%sol%value = x_accel
        result%flags%converged = .TRUE.
        result%stats%n_iterations = iter
        result%meta%message = "Aitken iteration converged"
        EXIT
      END IF

      ! next iter
      x(1) = x_accel
      x(2) = fixed_point_func(x(1))
      x(3) = fixed_point_func(x(2))
    END DO

    IF (.NOT. result%flags%converged) THEN
      result%sol%value = x(3)
      result%stats%n_iterations = max_iter
      result%meta%message = "Aitken iteration did not converge"
    END IF

  END SUBROUTINE NM_Aitken_Iter

  FUNCTION NM_Aitken_Val(x0, x1, x2) RESULT(x_accel)
    REAL(DP), INTENT(IN) :: x0, x1, x2
    REAL(DP) :: x_accel

    REAL(DP) :: delta1, delta2, denom

    delta1 = x2 - x1
    delta2 = x1 - x0
    denom = delta1 - delta2

    IF (ABS(denom) > 1.0E-14_DP) THEN
      x_accel = x0 - delta2**2 / denom
    ELSE
      x_accel = x2
    END IF

  END FUNCTION NM_Aitken_Val

  SUBROUTINE NM_Build_Epsilon_Table(sequence, eps_table, status)
    REAL(DP), INTENT(IN) :: sequence(:)
    TYPE(Epsilon_Table), INTENT(OUT) :: eps_table
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n, max_order, i, k

    CALL init_error_status(status)

    n = SIZE(sequence)
    max_order = MIN(n-1, 10_i4)  ! limit max order

    eps_table%order = max_order

    IF (ALLOCATED(eps_table%table)) DEALLOCATE(eps_table%table)
    ALLOCATE(eps_table%table(n, 0:max_order))
    eps_table%table = ZERO

    ! Initialize row 0
    eps_table%table(1:n, 0) = sequence

    ! build epsilon 
    DO k = 1, max_order
      DO i = 1, n - k
        IF (k == 1) THEN
          ! first col: inverse diff
          IF (ABS(eps_table%table(i+1, k-1) - eps_table%table(i, k-1)) > 1.0E-14_DP) THEN
            eps_table%table(i, k) = ONE / &
              (eps_table%table(i+1, k-1) - eps_table%table(i, k-1))
          ELSE
            eps_table%table(i, k) = HUGE(ONE)
          END IF
        ELSE
          ! higher order
          IF (ABS(eps_table%table(i+1, k-1) - eps_table%table(i, k-1)) > 1.0E-14_DP) THEN
            eps_table%table(i, k) = eps_table%table(i+1, k-2) + ONE / &
              (eps_table%table(i+1, k-1) - eps_table%table(i, k-1))
          ELSE
            eps_table%table(i, k) = eps_table%table(i+1, k-2)
          END IF
        END IF
      END DO
    END DO

  END SUBROUTINE NM_Build_Eps_Tbl

  SUBROUTINE NM_Eps_Algo(sequence, result, status)
    REAL(DP), INTENT(IN) :: sequence(:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Eps_Table) :: eps_table

    CALL init_error_status(status)

    ! build epsilon table
    CALL NM_Build_Eps_Tbl(sequence, eps_table, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! extract result
    CALL NM_Eps_Extrap(eps_table, result)

    result%meta%message = "Epsilon algorithm applied"

  END SUBROUTINE NM_Epsilon_Algorithm

  SUBROUTINE NM_Eps_Extrap(eps_table, result)
    TYPE(Eps_Table), INTENT(IN) :: eps_table
    TYPE(Accel_Result), INTENT(OUT) :: result

    INTEGER(i4) :: n, max_k

    n = SIZE(eps_table%table, 1)

    ! last even col
    max_k = 2 * (eps_table%order / 2)
    IF (max_k > 0) THEN
      result%sol%value = eps_table%table(1, max_k)
      IF (max_k >= 2) THEN
        result%error%error_estimate = ABS(eps_table%table(1, max_k) - &
                                     eps_table%table(1, max_k-2))
      ELSE
        result%error%error_estimate = ABS(eps_table%table(1, max_k) - &
                                     eps_table%table(1, 0))
      END IF
    ELSE
      result%sol%value = eps_table%table(1, 0)
      result%error%error_estimate = ZERO
    END IF

    result%flags%converged = (result%error%error_estimate < 1.0E-10_DP)
    result%stats%n_iterations = n

  END SUBROUTINE NM_Eps_Extrap

  FUNCTION NM_Err_Est(sequence) RESULT(error)
    REAL(DP), INTENT(IN) :: sequence(:)
    REAL(DP) :: error

    INTEGER(i4) :: n

    n = SIZE(sequence)
    IF (n >= 2) THEN
      error = ABS(sequence(n) - sequence(n-1))
    ELSE
      error = HUGE(ONE)
    END IF

  END FUNCTION NM_Err_Est

  SUBROUTINE NM_Rich_Extrap(sequence, order, result, status)
    REAL(DP), INTENT(IN) :: sequence(:)
    INTEGER(i4), INTENT(IN) :: order
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: T(:,:)
    REAL(DP) :: h
    INTEGER(i4) :: n, i, k

    CALL init_error_status(status)

    n = SIZE(sequence)

    IF (n < order + 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Sequence too short for Richardson extrapolation"
      RETURN
    END IF

    ALLOCATE(T(n, order+1))
    T = ZERO

    ! init col 0
    T(1:n, 1) = sequence

    ! build Richardson table
    h = ONE
    DO k = 2, order + 1
      DO i = 1, n - k + 1
        ! Richardson formula
        T(i, k) = T(i+1, k-1) + (T(i+1, k-1) - T(i, k-1)) / (2.0_DP**(k-1) - ONE)
      END DO
    END DO

    ! extract result
    result%sol%value = T(1, order+1)
    result%error%error_estimate = ABS(T(1, order+1) - T(1, order))
    result%flags%converged = (result%error%error_estimate < 1.0E-10_DP)
    result%stats%n_iterations = n
    result%meta%message = "Richardson extrapolation applied"

    DEALLOCATE(T)

  END SUBROUTINE NM_Rich_Extrap

  FUNCTION NM_Select_Method(sequence) RESULT(best_method)
    REAL(DP), INTENT(IN) :: sequence(:)
    INTEGER(i4) :: best_method

    INTEGER(i4) :: n

    n = SIZE(sequence)

    IF (n < 3) THEN
      best_method = NM_ACCEL_AITKEN
    ELSE IF (n < 6) THEN
      best_method = NM_ACCEL_EPSILON
    ELSE
      best_method = NM_ACCEL_SHANKS
    END IF

  END FUNCTION NM_Select_Method

  SUBROUTINE NM_Shanks_Tf(sequence, result, status)
    REAL(DP), INTENT(IN) :: sequence(:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! first-order Shanks = Aitken
    CALL NM_Aitken_D2(sequence, result, status)
    result%meta%message = "Shanks transform (1st order) applied"

  END SUBROUTINE NM_Shanks_Tf

  SUBROUTINE NM_Shanks_Tf_Ord(sequence, order, result, status)
    REAL(DP), INTENT(IN) :: sequence(:)
    INTEGER(i4), INTENT(IN) :: order
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: e_table(:,:)
    INTEGER(i4) :: n, k, i

    CALL init_error_status(status)

    n = SIZE(sequence)

    IF (n < 2*order + 1) THEN
      ! seq too short
      CALL NM_Shanks_Tf(sequence, result, status)
      RETURN
    END IF

    ! build epsilon table (simplified impl)
    ALLOCATE(e_table(n, order+1))
    e_table = ZERO

    ! col 0: raw seq
    e_table(1:n, 1) = sequence

    ! build e-table
    DO k = 1, order
      DO i = 1, n - 2*k
        IF (k == 1) THEN
          ! 1st = Aitken
          e_table(i, k+1) = NM_Aitken_Val(e_table(i, k), &
                                             e_table(i+1, k), &
                                             e_table(i+2, k))
        ELSE
          ! higher-order Shanks
          e_table(i, k+1) = e_table(i+1, k) + &
                            ONE / (ONE/(e_table(i+1, k) - e_table(i, k)) + &
                                   ONE/(e_table(i+1, k) - e_table(i+2, k)))
        END IF
      END DO
    END DO

    ! return highest order
    result%sol%value = e_table(1, order+1)
    result%error%error_estimate = ABS(e_table(1, order+1) - e_table(1, order))
    result%flags%converged = (result%error%error_estimate < 1.0E-10_DP)
    result%stats%n_iterations = n
    result%meta%message = "Higher-order Shanks transform applied"

    DEALLOCATE(e_table)

  END SUBROUTINE NM_Shanks_Tf_Ord

  SUBROUTINE NM_Store_SeqTerm(storage, value, vector)
    TYPE(Seq_Storage), INTENT(INOUT) :: storage
    REAL(DP), INTENT(IN), OPTIONAL :: value
    REAL(DP), INTENT(IN), OPTIONAL :: vector(:)

    INTEGER(i4) :: idx

    IF (storage%n_terms >= storage%max_terms) THEN
      ! shift out oldest
      IF (storage%dimension == 1) THEN
        storage%values(1:storage%max_terms-1) = storage%values(2:storage%max_terms)
      ELSE
        storage%vectors(:, 1:storage%max_terms-1) = storage%vectors(:, 2:storage%max_terms)
      END IF
      storage%n_terms = storage%max_terms - 1
    END IF

    storage%n_terms = storage%n_terms + 1
    idx = storage%n_terms

    IF (PRESENT(value) .AND. storage%dimension == 1) THEN
      storage%values(idx) = value
    END IF

    IF (PRESENT(vector) .AND. storage%dimension > 1) THEN
      storage%vectors(:, idx) = vector
    END IF

  END SUBROUTINE NM_Store_SeqTerm

  SUBROUTINE NM_Vec_Aitken(sequence, result, status)
    REAL(DP), INTENT(IN) :: sequence(:,:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: delta1(:), delta2(:), denominator(:)
    INTEGER(i4) :: n_dim, n_terms, i

    CALL init_error_status(status)

    n_dim = SIZE(sequence, 1)
    n_terms = SIZE(sequence, 2)

    ALLOCATE(delta1(n_dim), delta2(n_dim), denominator(n_dim))

    ! apply Aitken per component
    delta1 = sequence(:, n_terms) - sequence(:, n_terms-1)
    delta2 = sequence(:, n_terms-1) - sequence(:, n_terms-2)
    denominator = delta1 - delta2

    DO i = 1, n_dim
      IF (ABS(denominator(i)) > 1.0E-14_DP) THEN
        result%sol%vector(i) = sequence(i, n_terms-2) - delta2(i)**2 / denominator(i)
      ELSE
        result%sol%vector(i) = sequence(i, n_terms)
      END IF
    END DO

    result%error%error_estimate = SQRT(SUM((sequence(:, n_terms) - result%sol%vector)**2))
    result%flags%converged = (result%error%error_estimate < 1.0E-10_DP)
    result%stats%n_iterations = n_terms
    result%meta%message = "Vector Aitken acceleration applied"

    DEALLOCATE(delta1, delta2, denominator)

  END SUBROUTINE NM_Vec_Aitken

  SUBROUTINE NM_Vec_Eps_Algo(sequence, result, status)
    REAL(DP), INTENT(IN) :: sequence(:,:)
    TYPE(Accel_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Vec_Eps_Table) :: vec_eps
    INTEGER(i4) :: n_dim, n_terms, max_order, i, k, d
    REAL(DP) :: diff_norm, inv_diff

    CALL init_error_status(status)

    n_dim = SIZE(sequence, 1)
    n_terms = SIZE(sequence, 2)
    max_order = MIN(n_terms - 1, 6_i4)

    IF (.NOT. ALLOCATED(result%sol%vector)) ALLOCATE(result%sol%vector(n_dim))

    vec_eps%order = max_order
    ALLOCATE(vec_eps%table(n_dim, n_terms, 0:max_order))
    vec_eps%table = ZERO

    ! Initialize row 0
    DO i = 1, n_terms
      vec_eps%table(:, i, 0) = sequence(:, i)
    END DO

    ! build vector eps table
    DO k = 1, max_order
      DO i = 1, n_terms - k
        IF (k == 1) THEN
          ! first col
          diff_norm = SUM((vec_eps%table(:, i+1, k-1) - &
                           vec_eps%table(:, i, k-1))**2)
          IF (diff_norm > 1.0E-14_DP) THEN
            inv_diff = ONE / diff_norm
            vec_eps%table(:, i, k) = (vec_eps%table(:, i+1, k-1) - &
                                       vec_eps%table(:, i, k-1)) * inv_diff
          ELSE
            vec_eps%table(:, i, k) = ZERO
          END IF
        ELSE
          ! higher order
          diff_norm = SUM((vec_eps%table(:, i+1, k-1) - &
                           vec_eps%table(:, i, k-1))**2)
          IF (diff_norm > 1.0E-14_DP) THEN
            inv_diff = ONE / diff_norm
            vec_eps%table(:, i, k) = vec_eps%table(:, i+1, k-2) + &
              (vec_eps%table(:, i+1, k-1) - vec_eps%table(:, i, k-1)) * inv_diff
          ELSE
            vec_eps%table(:, i, k) = vec_eps%table(:, i+1, k-2)
          END IF
        END IF
      END DO
    END DO

    ! extract result
    result%sol%vector = vec_eps%table(:, 1, max_order)
    result%error%error_estimate = SQRT(SUM((sequence(:, n_terms) - result%sol%vector)**2))
    result%flags%converged = (result%error%error_estimate < 1.0E-10_DP)
    result%stats%n_iterations = n_terms
    result%meta%message = "Vector epsilon algorithm applied"

    DEALLOCATE(vec_eps%table)

  END SUBROUTINE NM_Vec_Eps_Algo
END MODULE NM_Conv_Accel