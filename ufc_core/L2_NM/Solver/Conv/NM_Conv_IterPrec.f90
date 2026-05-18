!===============================================================================
! MODULE: NM_Conv_IterPrec
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Proc (preconditioning for convergence iterative solvers)
! BRIEF:  Preconditioners for BiCGSTAB/GMRES/QMR/IDR: ILU, IC, AMG, SPAI
!
! Theory: Saad (2003); Trottenberg et al. (2001)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Conv_IterPrec
!> Status: Production | Last verified: 2026-03-01
!> Theory: Numerical method implementation | Ref: Saad(2003) Iterative Methods
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, TINY
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief precond type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_ILU = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_IC = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_JACOBI = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_GAUSS_SEIDEL = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_SSOR = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_AMG = 6
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_SPAI = 7
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_MULTILEVEL = 8

  !> @brief ILU variant enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ILU_0 = 0
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ILU_K = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ILU_T = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_MILU = 3

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief precond params
  TYPE, PUBLIC :: Preconditioner_Params
    INTEGER(i4) :: precond_type = NM_SOLV_PREC_ILU
    INTEGER(i4) :: ilu_variant = NM_ILU_0
    INTEGER(i4) :: fill_level = 0_i4       !< ILU fill
    REAL(DP) :: drop_tolerance = 1.0E-4_DP !< drop tol
    REAL(DP) :: omega = 1.0_DP             !< SOR omega
    INTEGER(i4) :: sweeps = 1_i4           !< sweeps
    ! AMG
    INTEGER(i4) :: amg_levels = 10_i4
    INTEGER(i4) :: amg_coarsening = 1_i4
    REAL(DP) :: amg_strong_threshold = 0.25_DP
    ! SPAI
    INTEGER(i4) :: spai_max_nnz = 50_i4
  END TYPE Preconditioner_Params

  !> @brief precond data
  TYPE, PUBLIC :: Preconditioner_Data
    INTEGER(i4) :: precond_type = 0_i4
    ! ILU
    REAL(DP), ALLOCATABLE :: L(:,:)        !< L factor
    REAL(DP), ALLOCATABLE :: U(:,:)        !< U factor
    ! diagonal
    REAL(DP), ALLOCATABLE :: D_inv(:)      !< D inv
    ! SPAI
    REAL(DP), ALLOCATABLE :: M(:,:)        !< sparse approx
    ! AMG
    TYPE(NM_AMG_Level), POINTER :: amg_hierarchy => NULL()
  END TYPE Preconditioner_Data

  !> @brief AMG level
  TYPE :: NM_AMG_Level
    REAL(DP), ALLOCATABLE :: A(:,:)        !< coarse matrix
    REAL(DP), ALLOCATABLE :: P(:,:)        !< prolong
    REAL(DP), ALLOCATABLE :: R(:,:)        !< restrict
    INTEGER(i4) :: n_fine = 0_i4
    INTEGER(i4) :: n_coarse = 0_i4
    TYPE(NM_AMG_Level), POINTER :: next => NULL()
  END TYPE NM_AMG_Level

  !> @brief precond result
  TYPE, PUBLIC :: Preconditioner_Result
    REAL(DP), ALLOCATABLE :: z(:)          !< z = M^{-1}*r
    INTEGER(i4) :: n_applications = 0_i4   !< apply count
    REAL(DP) :: setup_time = ZERO          !< setup time
    REAL(DP) :: apply_time = ZERO          !< apply time
  END TYPE Preconditioner_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! precond setup
  PUBLIC :: NM_Preconditioner_Setup
  PUBLIC :: NM_ILU_Setup
  PUBLIC :: NM_IC_Setup
  PUBLIC :: NM_Jacobi_Setup
  PUBLIC :: NM_SSOR_Setup
  PUBLIC :: NM_SPAI_Setup
  PUBLIC :: NM_AMG_Setup
  
  ! precond apply
  PUBLIC :: NM_Preconditioner_Apply
  PUBLIC :: NM_ILU_Solv
  PUBLIC :: NM_IC_Solv
  PUBLIC :: NM_Jacobi_Apply
  PUBLIC :: NM_SSOR_Apply
  PUBLIC :: NM_SPAI_Apply
  PUBLIC :: NM_AMG_VCycle
  
  ! utils
  PUBLIC :: NM_Preconditioner_Destroy
  PUBLIC :: NM_Estimate_Condition_Number

CONTAINS

  !=============================================================================
  ! PRECONDITIONER SETUP
  !=============================================================================

  !> @brief precond setup main
  !! @param[in] A coeff matrix
  !! @param[in] params precond params
  !! @param[out] precond_data precond data
  !! @param[out] status error status
  SUBROUTINE NM_Preconditioner_Setup(A, params, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    precond_data%precond_type = params%precond_type

    SELECT CASE (params%precond_type)
    CASE (NM_SOLV_PREC_ILU)
      CALL NM_ILU_Setup(A, params, precond_data, status)
    CASE (NM_SOLV_PREC_IC)
      CALL NM_IC_Setup(A, params, precond_data, status)
    CASE (NM_SOLV_PREC_JACOBI)
      CALL NM_Jacobi_Setup(A, precond_data, status)
    CASE (NM_SOLV_PREC_SSOR)
      CALL NM_SSOR_Setup(A, params, precond_data, status)
    CASE (NM_SOLV_PREC_SPAI)
      CALL NM_SPAI_Setup(A, params, precond_data, status)
    CASE (NM_SOLV_PREC_AMG)
      CALL NM_AMG_Setup(A, params, precond_data, status)
    CASE DEFAULT
      CALL NM_ILU_Setup(A, params, precond_data, status)
    END SELECT

  END SUBROUTINE NM_Preconditioner_Setup

  !> @brief ILU(k)set
  !! @details LU decomposition ?k-grade
  SUBROUTINE NM_ILU_Setup(A, params, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: L(:,:), U(:,:)
    INTEGER(i4) :: n, i, j, k
    REAL(DP) :: sum_val

    CALL init_error_status(status)

    n = SIZE(A, 1)
    ALLOCATE(L(n,n), U(n,n))
    L = ZERO
    U = ZERO

    ! ILU(0):  A pattern
    DO i = 1, n
      L(i,i) = ONE

      DO j = i, n
        ! U(i,j) = A(i,j) - sum(L(i,k)*U(k,j), k=1:i-1)
        sum_val = A(i,j)
        DO k = 1, i-1
          IF (A(i,k) /= ZERO .AND. A(k,j) /= ZERO) THEN
            sum_val = sum_val - L(i,k) * U(k,j)
          END IF
        END DO
        U(i,j) = sum_val
      END DO

      DO j = i+1, n
        ! L(j,i) = (A(j,i) - sum(L(j,k)*U(k,i), k=1:i-1)) / U(i,i)
        sum_val = A(j,i)
        DO k = 1, i-1
          IF (A(j,k) /= ZERO .AND. A(k,i) /= ZERO) THEN
            sum_val = sum_val - L(j,k) * U(k,i)
          END IF
        END DO
        IF (ABS(U(i,i)) > 1.0E-14_DP) THEN
          L(j,i) = sum_val / U(i,i)
        ELSE
          L(j,i) = ZERO
        END IF
      END DO
    END DO

    precond_data%L = L
    precond_data%U = U

    DEALLOCATE(L, U)

  END SUBROUTINE NM_ILU_Setup

  !> @brief IC(k)set
  !! @details Cholesky decomposition ?matrix ?
  SUBROUTINE NM_IC_Setup(A, params, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: L(:,:)
    INTEGER(i4) :: n, i, j, k
    REAL(DP) :: sum_val

    CALL init_error_status(status)

    n = SIZE(A, 1)
    ALLOCATE(L(n,n))
    L = ZERO

    ! IC 
    DO i = 1, n
      DO j = 1, i
        sum_val = A(i,j)
        DO k = 1, j-1
          sum_val = sum_val - L(i,k) * L(j,k)
        END DO

        IF (i == j) THEN
          IF (sum_val > ZERO) THEN
            L(i,i) = SQRT(sum_val)
          ELSE
            L(i,i) = ONE  ! fix non-PD
          END IF
        ELSE
          IF (ABS(L(j,j)) > 1.0E-14_DP) THEN
            L(i,j) = sum_val / L(j,j)
          END IF
        END IF
      END DO
    END DO

    precond_data%L = L

    DEALLOCATE(L)

  END SUBROUTINE NM_IC_Setup

  !> @brief Jacobi set
  SUBROUTINE NM_Jacobi_Setup(A, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n, i

    CALL init_error_status(status)

    n = SIZE(A, 1)
    ALLOCATE(precond_data%D_inv(n))

    DO i = 1, n
      IF (ABS(A(i,i)) > 1.0E-14_DP) THEN
        precond_data%D_inv(i) = ONE / A(i,i)
      ELSE
        precond_data%D_inv(i) = ONE
      END IF
    END DO

  END SUBROUTINE NM_Jacobi_Setup

  !> @brief SSOR set
  SUBROUTINE NM_SSOR_Setup(A, params, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! SSOR Jacobi 
    CALL NM_Jacobi_Setup(A, precond_data, status)

  END SUBROUTINE NM_SSOR_Setup

  !> @brief SPAI setup
  !! @details sparse approx inverse
  SUBROUTINE NM_SPAI_Setup(A, params, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    n = SIZE(A, 1)

    !  implements ?
    ALLOCATE(precond_data%M(n,n))
    precond_data%M = ZERO

    DO n = 1, SIZE(A, 1)
      IF (ABS(A(n,n)) > 1.0E-14_DP) THEN
        precond_data%M(n,n) = ONE / A(n,n)
      ELSE
        precond_data%M(n,n) = ONE
      END IF
    END DO

  END SUBROUTINE NM_SPAI_Setup

  !> @brief AMGset
  !! @details  
  SUBROUTINE NM_AMG_Setup(A, params, precond_data, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Preconditioner_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(OUT) :: precond_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    !  implements ?
    CALL init_error_status(status)

    ALLOCATE(precond_data%amg_hierarchy)
    precond_data%amg_hierarchy%A = A
    precond_data%amg_hierarchy%n_fine = SIZE(A, 1)

  END SUBROUTINE NM_AMG_Setup

  !=============================================================================
  ! PRECONDITIONER APPLICATION
  !=============================================================================

  !> @brief precond apply
  !! @param[in] precond_data precond data
  !! @param[in] r residual
  !! @param[out] z precond result
  !! @param[out] status error status
  SUBROUTINE NM_Preconditioner_Apply(precond_data, r, z, status)
    TYPE(Preconditioner_Data), INTENT(IN) :: precond_data
    REAL(DP), INTENT(IN) :: r(:)
    REAL(DP), INTENT(OUT) :: z(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (precond_data%precond_type)
    CASE (NM_SOLV_PREC_ILU)
      CALL NM_ILU_Solv(precond_data%L, precond_data%U, r, z, status)
    CASE (NM_SOLV_PREC_IC)
      CALL NM_IC_Solv(precond_data%L, r, z, status)
    CASE (NM_SOLV_PREC_JACOBI)
      CALL NM_Jacobi_Apply(precond_data%D_inv, r, z)
    CASE (NM_SOLV_PREC_SSOR)
      CALL NM_SSOR_Apply(precond_data%D_inv, r, z)
    CASE (NM_SOLV_PREC_SPAI)
      CALL NM_SPAI_Apply(precond_data%M, r, z)
    CASE (NM_SOLV_PREC_AMG)
      CALL NM_AMG_VCycle(precond_data%amg_hierarchy, r, z, status)
    CASE DEFAULT
      z = r
    END SELECT

  END SUBROUTINE NM_Preconditioner_Apply

  !> @brief ILU 
  ! ! @details L U z = r
  SUBROUTINE NM_ILU_Solv(L, U, r, z, status)
    REAL(DP), INTENT(IN) :: L(:,:), U(:,:), r(:)
    REAL(DP), INTENT(OUT) :: z(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: y(:)
    INTEGER(i4) :: n, i, j

    CALL init_error_status(status)

    n = SIZE(r)
    ALLOCATE(y(n))

    ! : L y = r
    DO i = 1, n
      y(i) = r(i)
      DO j = 1, i-1
        y(i) = y(i) - L(i,j) * y(j)
      END DO
      IF (ABS(L(i,i)) > 1.0E-14_DP) THEN
        y(i) = y(i) / L(i,i)
      END IF
    END DO

    ! : U z = y
    DO i = n, 1, -1
      z(i) = y(i)
      DO j = i+1, n
        z(i) = z(i) - U(i,j) * z(j)
      END DO
      IF (ABS(U(i,i)) > 1.0E-14_DP) THEN
        z(i) = z(i) / U(i,i)
      END IF
    END DO

    DEALLOCATE(y)

  END SUBROUTINE NM_ILU_Solv

  !> @brief IC solve
  !! @details solve L*L^T*z = r
  SUBROUTINE NM_IC_Solv(L, r, z, status)
    REAL(DP), INTENT(IN) :: L(:,:), r(:)
    REAL(DP), INTENT(OUT) :: z(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: y(:)
    INTEGER(i4) :: n, i, j

    CALL init_error_status(status)

    n = SIZE(r)
    ALLOCATE(y(n))

    ! : L y = r
    DO i = 1, n
      y(i) = r(i)
      DO j = 1, i-1
        y(i) = y(i) - L(i,j) * y(j)
      END DO
      IF (ABS(L(i,i)) > 1.0E-14_DP) THEN
        y(i) = y(i) / L(i,i)
      END IF
    END DO

    ! : L^T z = y
    DO i = n, 1, -1
      z(i) = y(i)
      DO j = i+1, n
        z(i) = z(i) - L(j,i) * z(j)
      END DO
      IF (ABS(L(i,i)) > 1.0E-14_DP) THEN
        z(i) = z(i) / L(i,i)
      END IF
    END DO

    DEALLOCATE(y)

  END SUBROUTINE NM_IC_Solv

  !> @brief Jacobi 
  SUBROUTINE NM_Jacobi_Apply(D_inv, r, z)
    REAL(DP), INTENT(IN) :: D_inv(:), r(:)
    REAL(DP), INTENT(OUT) :: z(:)

    z = D_inv * r

  END SUBROUTINE NM_Jacobi_Apply

  !> @brief SSOR 
  SUBROUTINE NM_SSOR_Apply(D_inv, r, z)
    REAL(DP), INTENT(IN) :: D_inv(:), r(:)
    REAL(DP), INTENT(OUT) :: z(:)

    ! same as Jacobi
    z = D_inv * r

  END SUBROUTINE NM_SSOR_Apply

  !> @brief SPAI 
  SUBROUTINE NM_SPAI_Apply(M, r, z)
    REAL(DP), INTENT(IN) :: M(:,:), r(:)
    REAL(DP), INTENT(OUT) :: z(:)

    z = MATMUL(M, r)

  END SUBROUTINE NM_SPAI_Apply

  !> @brief AMG V-Cycle
  SUBROUTINE NM_AMG_VCycle(level, r, z, status)
    TYPE(NM_AMG_Level), POINTER, INTENT(IN) :: level
    REAL(DP), INTENT(IN) :: r(:)
    REAL(DP), INTENT(OUT) :: z(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    !  implements ?
    CALL init_error_status(status)
    z = r

  END SUBROUTINE NM_AMG_VCycle

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief  data
  SUBROUTINE NM_Preconditioner_Destroy(precond_data)
    TYPE(Preconditioner_Data), INTENT(INOUT) :: precond_data

    IF (ALLOCATED(precond_data%L)) DEALLOCATE(precond_data%L)
    IF (ALLOCATED(precond_data%U)) DEALLOCATE(precond_data%U)
    IF (ALLOCATED(precond_data%D_inv)) DEALLOCATE(precond_data%D_inv)
    IF (ALLOCATED(precond_data%M)) DEALLOCATE(precond_data%M)

    ! free AMG
    IF (ASSOCIATED(precond_data%amg_hierarchy)) THEN
      DEALLOCATE(precond_data%amg_hierarchy)
    END IF

  END SUBROUTINE NM_Preconditioner_Destroy

  !> @brief  condition
  FUNCTION NM_Estimate_Condition_Number(A) RESULT(cond)
    REAL(DP), INTENT(IN) :: A(:,:)
    REAL(DP) :: cond

    REAL(DP), ALLOCATABLE :: eigenvalues(:), work(:)
    INTEGER(i4) :: n, lwork, info

    n = SIZE(A, 1)
    lwork = 3 * n

    ALLOCATE(eigenvalues(n), work(lwork))

    ! use diag est
    cond = MAXVAL(ABS([(A(i,i), i=1,n)])) / &
           MAX(MINVAL(ABS([(A(i,i), i=1,n)])), 1.0E-14_DP)

    DEALLOCATE(eigenvalues, work)

  END FUNCTION NM_Estimate_Condition_Number

END MODULE NM_Conv_IterPrec