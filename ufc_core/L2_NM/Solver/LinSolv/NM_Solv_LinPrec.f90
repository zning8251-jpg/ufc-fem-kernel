!===============================================================================
! MODULE: NM_Solv_LinPrec
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (preconditioner dispatcher)
! BRIEF:  Preconditioner core: Jacobi, SSOR, ILU(0), ILU(k)
!
! Theory: Saad (2003); Benzi (2002)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinPrec
!> Theory: Numerical method implementation | Ref: Saad(2003) Iterative Methods
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Mtx_Sparse, ONLY: NM_CSR_Type
  USE NM_Solv_LinDir, ONLY: NM_LinSolv_Direct_Forward_Substitution, &
                                   NM_LinSolv_Direct_Backward_Substitution
  IMPLICIT NONE
  PRIVATE

  !> @brief  
  INTEGER, PARAMETER, PUBLIC :: NM_SOLV_PREC_NONE = 0        !<  
  INTEGER, PARAMETER, PUBLIC :: NM_SOLV_PREC_JACOBI = 1      !< Jacobi
  INTEGER, PARAMETER, PUBLIC :: NM_SOLV_PREC_SSOR = 2        !< SSOR
  INTEGER, PARAMETER, PUBLIC :: NM_SOLV_PREC_ILU0 = 3        !< ILU(0)
  INTEGER, PARAMETER, PUBLIC :: NM_SOLV_PREC_ILUK = 4        !< ILU(k)

  !> @brief Jacobi 
  TYPE, PUBLIC :: Jacobi_Preconditioner
    INTEGER(i4) :: n_size                     !< matrix 
    REAL(DP), ALLOCATABLE :: diag_inv(:)  !<  D^{-1}
  END TYPE

  !> @brief SSOR 
  TYPE, PUBLIC :: SSOR_Preconditioner
    INTEGER(i4) :: n_size                     !< matrix 
    REAL(DP) :: omega                     !< relaxation  ω (0,2)
    REAL(DP), ALLOCATABLE :: diag(:)      !<   D
    TYPE(NM_CSR_Type) :: L_lower          !<  
    TYPE(NM_CSR_Type) :: U_upper          !<  
  END TYPE

  !> @brief ILU 
  TYPE, PUBLIC :: NM_ILU_Preconditioner
    INTEGER(i4) :: n_size                     !< matrix 
    INTEGER(i4) :: fill_level                 !<  -grade  k
    TYPE(NM_CSR_Type) :: L_factor         !<  
    TYPE(NM_CSR_Type) :: U_factor         !<  
  END TYPE

  !> @brief  param
  TYPE, PUBLIC :: Preconditioner_Params
    INTEGER(i4) :: precond_type              !<  
    INTEGER(i4) :: ilu_fill_level            !< ILU -grade 
    REAL(DP) :: ssor_omega                !< SSORrelaxation 
    REAL(DP) :: drop_tolerance            !<  
  END TYPE

  ! Public interfaces
  PUBLIC :: NM_LinSolv_Prec_Jacobi_Build
  PUBLIC :: NM_LinSolv_Prec_Jacobi_Apply
  PUBLIC :: NM_LinSolv_Prec_SSOR_Build
  PUBLIC :: NM_LinSolv_Prec_SSOR_Apply
  PUBLIC :: NM_LinSolv_Prec_ILU0_Build
  PUBLIC :: NM_LinSolv_Prec_ILU_Apply
  
  ! Extended preconditioner API (scope 1450-1499)
  PUBLIC :: NM_LinSolv_Prec_SelectOptimal, NM_LinSolv_Prec_GetEffectiveness
  PUBLIC :: NM_LinSolv_Prec_GetStatistics, NM_LinSolv_Prec_ComparePreconditioners

CONTAINS

  SUBROUTINE NM_LinSolv_Prec_ComparePreconditioners(A, precond_types, effectiveness, &
                                               best_type, status)
    TYPE(NM_CSR_Type), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: precond_types(:)
    REAL(DP), INTENT(OUT) :: effectiveness(:)
    INTEGER(i4), INTENT(OUT) :: best_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, num_types, best_idx
    REAL(DP) :: max_effectiveness
    
    CALL init_error_status(status)
    
    num_types = SIZE(precond_types)
    IF (SIZE(effectiveness) < num_types) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_LinSolv_Prec_ComparePreconditioners: Array size mismatch"
      RETURN
    END IF
    
    ! Evaluate each preconditioner
    max_effectiveness = 0.0_DP
    best_idx = 1
    
    DO i = 1, num_types
      CALL NM_LinSolv_Prec_GetEffectiveness(A, precond_types(i), effectiveness(i), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      
      IF (effectiveness(i) > max_effectiveness) THEN
        max_effectiveness = effectiveness(i)
        best_idx = i
      END IF
    END DO
    
    best_type = precond_types(best_idx)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Prec_ComparePreconditioners

  SUBROUTINE NM_LinSolv_Prec_GetEffectiveness(A, precond_type, effectiveness, status)
    TYPE(NM_CSR_Type), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: precond_type
    REAL(DP), INTENT(OUT) :: effectiveness
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP) :: cond_A_est, cond_MA_est, diag_max, diag_min
    INTEGER(i4) :: i, k, n
    
    CALL init_error_status(status)
    
    ! Estimate cond(A) from diagonal: max|a_ii| / min|a_ii|
    n = A%n
    diag_max = TINY(1.0_DP)
    diag_min = HUGE(1.0_DP)
    DO i = 1, n
      DO k = A%ia(i), A%ia(i+1) - 1
        IF (A%ja(k) == i) THEN
          diag_max = MAX(diag_max, ABS(A%a(k)))
          diag_min = MIN(diag_min, MAX(ABS(A%a(k)), SMALL))
          EXIT
        END IF
      END DO
    END DO
    cond_A_est = diag_max / diag_min
    cond_A_est = MAX(cond_A_est, 1.0_DP)
    
    ! Heuristic: preconditioner typically improves cond by factor depending on type
    SELECT CASE(precond_type)
    CASE(NM_SOLV_PREC_JACOBI)
      cond_MA_est = cond_A_est * 0.8_DP
    CASE(NM_SOLV_PREC_SSOR)
      cond_MA_est = cond_A_est * 0.5_DP
    CASE(NM_SOLV_PREC_ILU0)
      cond_MA_est = cond_A_est * 0.3_DP
    CASE DEFAULT
      cond_MA_est = cond_A_est
    END SELECT
    
    effectiveness = MAX(0.0_DP, 1.0_DP - cond_MA_est / cond_A_est)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Prec_GetEffectiveness

  SUBROUTINE NM_LinSolv_Prec_GetStatistics(precond_type, stats, status)
    INTEGER(i4), INTENT(IN) :: precond_type
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=32) :: precond_name
    
    CALL init_error_status(status)
    
    SELECT CASE(precond_type)
    CASE(NM_SOLV_PREC_NONE)
      precond_name = "None"
    CASE(NM_SOLV_PREC_JACOBI)
      precond_name = "Jacobi"
    CASE(NM_SOLV_PREC_SSOR)
      precond_name = "SSOR"
    CASE(NM_SOLV_PREC_ILU0)
      precond_name = "ILU(0)"
    CASE(NM_SOLV_PREC_ILUK)
      precond_name = "ILU(k)"
    CASE DEFAULT
      precond_name = "Unknown"
    END SELECT
    
    WRITE(stats, '(A,A)') 'Preconditioner Statistics: type=', TRIM(precond_name)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Prec_GetStatistics

  SUBROUTINE NM_LinSolv_Prec_ILU0_Build(A, precond)
    TYPE(NM_CSR_Type), INTENT(IN) :: A
    TYPE(NM_ILU_Preconditioner), INTENT(OUT) :: precond

    INTEGER(i4) :: n, i, j, k, ii, jj, ki, kj
    REAL(DP), ALLOCATABLE :: A_work(:,:)
    REAL(DP) :: multiplier
    INTEGER(i4) :: nnz_L, nnz_U

    n = A%n
    precond%n_size = n
    precond%fill_level = 0

    ! simplified impl  matrix ILU(0)
    !  -grade   ILUalgorithm 
    ALLOCATE(A_work(n, n))
    A_work = ZERO

    ! CSR to dense
    DO i = 1, n
      DO k = A%ia(i), A%ia(i+1) - 1
        j = A%ja(k)
        A_work(i, j) = A%a(k)
      END DO
    END DO

    ! ILU(0)  ( algorithm )
    DO k = 1, n-1
      IF (ABS(A_work(k, k)) < SMALL) CYCLE

      DO i = k+1, n
        IF (ABS(A_work(i, k)) < SMALL) CYCLE

        !  : L(i,k) = A(i,k) / A(k,k)
        multiplier = A_work(i, k) / A_work(k, k)
        A_work(i, k) = multiplier

        ! update i( 
        DO j = k+1, n
          IF (ABS(A_work(i, j)) > SMALL) THEN
            A_work(i, j) = A_work(i, j) - multiplier * A_work(k, j)
          END IF
        END DO
      END DO
    END DO

    !  L/Umatrix
    nnz_L = 0
    nnz_U = 0
    DO i = 1, n
      DO j = 1, n
        IF (j < i .AND. ABS(A_work(i,j)) > SMALL) nnz_L = nnz_L + 1
        IF (j >= i .AND. ABS(A_work(i,j)) > SMALL) nnz_U = nnz_U + 1
      END DO
    END DO

    ! Initialize NM_CSR_Type L/U factors
    precond%L_factor%n = n
    precond%L_factor%m = n
    precond%L_factor%nnz = nnz_L
    ALLOCATE(precond%L_factor%ia(n+1), precond%L_factor%ja(nnz_L), precond%L_factor%a(nnz_L))
    precond%L_factor%is_allocated = .TRUE.
    precond%U_factor%n = n
    precond%U_factor%m = n
    precond%U_factor%nnz = nnz_U
    ALLOCATE(precond%U_factor%ia(n+1), precond%U_factor%ja(nnz_U), precond%U_factor%a(nnz_U))
    precond%U_factor%is_allocated = .TRUE.

    !  L/U (CSR )
    nnz_L = 0
    nnz_U = 0
    precond%L_factor%ia(1) = 1
    precond%U_factor%ia(1) = 1

    DO i = 1, n
      DO j = 1, n
        IF (j < i .AND. ABS(A_work(i,j)) > SMALL) THEN
          nnz_L = nnz_L + 1
          precond%L_factor%ja(nnz_L) = j
          precond%L_factor%a(nnz_L) = A_work(i, j)
        ELSE IF (j >= i .AND. ABS(A_work(i,j)) > SMALL) THEN
          nnz_U = nnz_U + 1
          precond%U_factor%ja(nnz_U) = j
          precond%U_factor%a(nnz_U) = A_work(i, j)
        END IF
      END DO

      precond%L_factor%ia(i+1) = nnz_L + 1
      precond%U_factor%ia(i+1) = nnz_U + 1
    END DO

    ! L 
    DO i = 1, n
      DO k = precond%L_factor%ia(i), precond%L_factor%ia(i+1) - 1
        IF (precond%L_factor%ja(k) == i) THEN
          precond%L_factor%a(k) = ONE
        END IF
      END DO
    END DO

    DEALLOCATE(A_work)

  END SUBROUTINE NM_LinSolv_Prec_ILU0_Build

  SUBROUTINE NM_LinSolv_Prec_ILU_Apply(precond, r, z)
    TYPE(NM_ILU_Preconditioner), INTENT(IN) :: precond
    REAL(DP), INTENT(IN)  :: r(:)
    REAL(DP), INTENT(OUT) :: z(:)

    REAL(DP), ALLOCATABLE :: y(:)

    ALLOCATE(y(precond%n_size))

    !  : L·y = r
    CALL NM_LinSolv_Direct_Forward_Substitution(precond%L_factor, r, y)

    !  : U·z = y
    CALL NM_LinSolv_Direct_Backward_Substitution(precond%U_factor, y, z)

    DEALLOCATE(y)

  END SUBROUTINE NM_LinSolv_Prec_ILU_Apply

  SUBROUTINE NM_LinSolv_Prec_Jacobi_Apply(precond, r, z)
    TYPE(Jacobi_Preconditioner), INTENT(IN) :: precond
    REAL(DP), INTENT(IN)  :: r(:)
    REAL(DP), INTENT(OUT) :: z(:)

    INTEGER(i4) :: i

    ! z_i = r_i / D_ii
    DO i = 1, precond%n_size
      z(i) = precond%diag_inv(i) * r(i)
    END DO

  END SUBROUTINE NM_LinSolv_Prec_Jacobi_Apply

  SUBROUTINE NM_LinSolv_Prec_Jacobi_Build(A, precond)
    TYPE(NM_CSR_Type), INTENT(IN) :: A
    TYPE(Jacobi_Preconditioner), INTENT(OUT) :: precond

    INTEGER(i4) :: i, k, col

    precond%n_size = A%n
    ALLOCATE(precond%diag_inv(precond%n_size))
    precond%diag_inv = ZERO

    !  
    DO i = 1, A%n
      DO k = A%ia(i), A%ia(i+1) - 1
        col = A%ja(k)
        IF (col == i) THEN
          !  
          IF (ABS(A%a(k)) > SMALL) THEN
            precond%diag_inv(i) = ONE / A%a(k)
          ELSE
            precond%diag_inv(i) = ONE  ! avoid division by zero
          END IF
          EXIT
        END IF
      END DO
    END DO

  END SUBROUTINE NM_LinSolv_Prec_Jacobi_Build

  SUBROUTINE NM_LinSolv_Prec_SelectOptimal(A, recommended_type, status)
    TYPE(NM_CSR_Type), INTENT(IN) :: A
    INTEGER(i4), INTENT(OUT) :: recommended_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, k, col, n
    REAL(DP) :: diag_dominance, sparsity_ratio
    INTEGER(i4) :: nnz, diag_nnz
    
    CALL init_error_status(status)
    
    n = A%n
    nnz = A%nnz
    
    ! Compute diagonal dominance
    diag_nnz = 0
    DO i = 1, n
      DO k = A%ia(i), A%ia(i+1) - 1
        col = A%ja(k)
        IF (col == i) THEN
          diag_nnz = diag_nnz + 1
          EXIT
        END IF
      END DO
    END DO
    
    sparsity_ratio = REAL(nnz, DP) / REAL(n*n, DP)
    
    ! Heuristic selection
    IF (sparsity_ratio > 0.5_DP) THEN
      ! Dense matrix: Use SSOR
      recommended_type = NM_SOLV_PREC_SSOR
    ELSE IF (diag_nnz == n .AND. sparsity_ratio < 0.1_DP) THEN
      ! Sparse and diagonal dominant: Use Jacobi
      recommended_type = NM_SOLV_PREC_JACOBI
    ELSE
      ! General sparse: Use ILU(0)
      recommended_type = NM_SOLV_PREC_ILU0
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Prec_SelectOptimal

  SUBROUTINE NM_LinSolv_Prec_SSOR_Apply(precond, r, z)
    TYPE(SSOR_Preconditioner), INTENT(IN) :: precond
    REAL(DP), INTENT(IN)  :: r(:)
    REAL(DP), INTENT(OUT) :: z(:)

    REAL(DP), ALLOCATABLE :: y(:)
    INTEGER(i4) :: i, k, col
    REAL(DP) :: sum_val, omega

    ALLOCATE(y(precond%n_size))
    omega = precond%omega

    !  1:   (D + ωL)·y = ω·r
    DO i = 1, precond%n_size
      sum_val = ZERO

      ! computation Σ L(i,j)·y(j)
      DO k = precond%L_lower%ia(i), precond%L_lower%ia(i+1) - 1
        col = precond%L_lower%ja(k)
        sum_val = sum_val + precond%L_lower%a(k) * y(col)
      END DO

      ! y(i) = [ω·r(i) - ω·sum] / D(i,i)
      y(i) = (omega * r(i) - omega * sum_val) / precond%diag(i)
    END DO

    !  2:   y D·y
    DO i = 1, precond%n_size
      y(i) = y(i) * precond%diag(i)
    END DO

    !  3:   (D + ωU)·z = y
    DO i = precond%n_size, 1, -1
      sum_val = ZERO

      ! computation Σ U(i,j)·z(j)
      DO k = precond%U_upper%ia(i), precond%U_upper%ia(i+1) - 1
        col = precond%U_upper%ja(k)
        sum_val = sum_val + precond%U_upper%a(k) * z(col)
      END DO

      ! z(i) = [y(i) - ω·sum] / D(i,i)
      z(i) = (y(i) - omega * sum_val) / precond%diag(i)
    END DO

    DEALLOCATE(y)

  END SUBROUTINE NM_LinSolv_Prec_SSOR_Apply

  SUBROUTINE NM_LinSolv_Prec_SSOR_Build(A, omega, precond)
    TYPE(NM_CSR_Type), INTENT(IN) :: A
    REAL(DP), INTENT(IN) :: omega
    TYPE(SSOR_Preconditioner), INTENT(OUT) :: precond

    INTEGER(i4) :: i, j, k, col, nnz_L, nnz_U
    INTEGER, ALLOCATABLE :: L_col_idx(:), U_col_idx(:)
    REAL(DP), ALLOCATABLE :: L_values(:), U_values(:)

    precond%n_size = A%n
    precond%omega = omega
    ALLOCATE(precond%diag(precond%n_size))
    precond%diag = ZERO

    !  
    nnz_L = 0
    nnz_U = 0
    DO i = 1, A%n
      DO k = A%ia(i), A%ia(i+1) - 1
        col = A%ja(k)
        IF (col < i) nnz_L = nnz_L + 1
        IF (col > i) nnz_U = nnz_U + 1
        IF (col == i) precond%diag(i) = A%a(k)
      END DO
    END DO

    !  L/Umatrix - Initialize NM_CSR_Type
    precond%L_lower%n = precond%n_size
    precond%L_lower%m = precond%n_size
    precond%L_lower%nnz = nnz_L
    ALLOCATE(precond%L_lower%ia(precond%n_size+1), precond%L_lower%ja(nnz_L), precond%L_lower%a(nnz_L))
    precond%L_lower%is_allocated = .TRUE.
    precond%U_upper%n = precond%n_size
    precond%U_upper%m = precond%n_size
    precond%U_upper%nnz = nnz_U
    ALLOCATE(precond%U_upper%ia(precond%n_size+1), precond%U_upper%ja(nnz_U), precond%U_upper%a(nnz_U))
    precond%U_upper%is_allocated = .TRUE.

    !  L/Umatrix
    ALLOCATE(L_col_idx(nnz_L), L_values(nnz_L))
    ALLOCATE(U_col_idx(nnz_U), U_values(nnz_U))

    nnz_L = 0
    nnz_U = 0
    precond%L_lower%ia(1) = 1
    precond%U_upper%ia(1) = 1

    DO i = 1, A%n
      DO k = A%ia(i), A%ia(i+1) - 1
        col = A%ja(k)

        IF (col < i) THEN
          !  
          nnz_L = nnz_L + 1
          precond%L_lower%ja(nnz_L) = col
          precond%L_lower%a(nnz_L) = A%a(k)
        ELSE IF (col > i) THEN
          !  
          nnz_U = nnz_U + 1
          precond%U_upper%ja(nnz_U) = col
          precond%U_upper%a(nnz_U) = A%a(k)
        END IF
      END DO

      precond%L_lower%ia(i+1) = nnz_L + 1
      precond%U_upper%ia(i+1) = nnz_U + 1
    END DO

  END SUBROUTINE NM_LinSolv_Prec_SSOR_Build
END MODULE NM_Solv_LinPrec