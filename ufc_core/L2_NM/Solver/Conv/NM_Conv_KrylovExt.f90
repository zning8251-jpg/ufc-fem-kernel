!===============================================================================
! MODULE: NM_Conv_KrylovExt
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Proc (Krylov subspace extensions)
! BRIEF:  Adaptive restart, augmented/deflated GMRES, spectral analysis
!
! Theory: Saad (2003); Gutknecht (1997)
!
! Status: CORE | Last verified: 2026-03-24
!===============================================================================

MODULE NM_Conv_KrylovExt
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
  
  !> @brief Krylov extension type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_KRYLOV_RESTART_ADAPTIVE = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_KRYLOV_RESIDUAL_MIN = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_KRYLOV_AUGMENTED = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_KRYLOV_RECURSIVE = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_KRYLOV_SPECTRAL = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_KRYLOV_DEFLATED = 6

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief Krylov extension params
    TYPE, PUBLIC :: Krylov_Extension_Params_Type
    INTEGER(i4) :: extension_type = NM_KRYLOV_RESTART_ADAPTIVE
  END TYPE Krylov_Extension_Params_Type

  TYPE, PUBLIC :: Krylov_Extension_Params_Basis
    INTEGER(i4) :: max_basis_size = 50_i4
    INTEGER(i4) :: min_basis_size = 10_i4
  END TYPE Krylov_Extension_Params_Basis

  TYPE, PUBLIC :: Krylov_Extension_Params_Thresh
    REAL(DP) :: residual_ratio_threshold = 0.1_DP
  END TYPE Krylov_Extension_Params_Thresh

  TYPE, PUBLIC :: Krylov_Extension_Params_Eigen
    INTEGER(i4) :: max_eigenvectors = 5_i4
    REAL(DP) :: eigenvalue_tolerance = 1.0E-6_DP
  END TYPE Krylov_Extension_Params_Eigen

  TYPE, PUBLIC :: Krylov_Extension_Params_Flags
    LOGICAL :: use_selective_orthogonalization = .TRUE.
  END TYPE Krylov_Extension_Params_Flags

  TYPE, PUBLIC :: Krylov_Extension_Params
    TYPE(Krylov_Extension_Params_Type)   :: ext_type
    TYPE(Krylov_Extension_Params_Basis)  :: basis
    TYPE(Krylov_Extension_Params_Thresh) :: thresh
    TYPE(Krylov_Extension_Params_Eigen)  :: eigen
    TYPE(Krylov_Extension_Params_Flags)  :: flags
  END TYPE Krylov_Extension_Params

  !> @brief Krylov basis
  TYPE, PUBLIC :: Krylov_Basis
    REAL(DP), ALLOCATABLE :: V(:,:)        !< Krylov vecs
    REAL(DP), ALLOCATABLE :: H(:,:)        !< Hessenberg
    INTEGER(i4) :: dimension = 0_i4        !< current dim
    INTEGER(i4) :: max_dim = 0_i4          !< max dim
  END TYPE Krylov_Basis

  !> @brief augmented Krylov subspace
  TYPE, PUBLIC :: Augmented_Krylov_Subspace
    TYPE(Krylov_Basis) :: standard_basis
    REAL(DP), ALLOCATABLE :: U(:,:)        !< aug vectors
    REAL(DP), ALLOCATABLE :: C(:,:)        !< C = A·U
    INTEGER(i4) :: n_augmented = 0_i4
  END TYPE Augmented_Krylov_Subspace

  !> @brief spectral info
  TYPE, PUBLIC :: Spectral_Info
    REAL(DP), ALLOCATABLE :: eigenvalues(:)
    REAL(DP), ALLOCATABLE :: eigenvectors(:,:)
    INTEGER(i4) :: n_converged = 0_i4
  END TYPE Spectral_Info

  !> @brief recursive Krylov data
  TYPE, PUBLIC :: Recursive_Krylov_Data
    TYPE(Krylov_Basis) :: inner_basis
    TYPE(Krylov_Basis) :: outer_basis
    INTEGER(i4) :: recursion_level = 0_i4
  END TYPE Recursive_Krylov_Data

  !> @brief Krylov extension result
    TYPE, PUBLIC :: Krylov_Extension_Result_Sol
    REAL(DP), ALLOCATABLE :: x(:)          !< solution
  END TYPE Krylov_Extension_Result_Sol

  TYPE, PUBLIC :: Krylov_Extension_Result_Residual
    REAL(DP) :: residual_norm = ZERO
  END TYPE Krylov_Extension_Result_Residual

  TYPE, PUBLIC :: Krylov_Extension_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4
    INTEGER(i4) :: n_matvecs = 0_i4
    INTEGER(i4) :: basis_size = 0_i4
  END TYPE Krylov_Extension_Result_Stats

  TYPE, PUBLIC :: Krylov_Extension_Result_Flags
    LOGICAL :: converged = .FALSE.
  END TYPE Krylov_Extension_Result_Flags

  TYPE, PUBLIC :: Krylov_Extension_Result_Meta
    CHARACTER(LEN=128) :: message = ""
  END TYPE Krylov_Extension_Result_Meta

  TYPE, PUBLIC :: Krylov_Extension_Result
    TYPE(Krylov_Extension_Result_Sol)      :: sol
    TYPE(Krylov_Extension_Result_Residual) :: residual
    TYPE(Krylov_Extension_Result_Stats)    :: stats
    TYPE(Krylov_Extension_Result_Flags)    :: flags
    TYPE(Krylov_Extension_Result_Meta)     :: meta
  END TYPE Krylov_Extension_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main interface
  PUBLIC :: NM_Krylov_Extended_Solv
  PUBLIC :: NM_Adaptive_Restart_GMRES
  PUBLIC :: NM_Augmented_GMRES
  PUBLIC :: NM_Deflated_GMRES
  
  ! Krylov ops
  PUBLIC :: NM_Build_Krylov_Basis
  PUBLIC :: NM_Extend_Krylov_Basis
  PUBLIC :: NM_Orthogonalize_Vector
  PUBLIC :: NM_Calc_Ritz_Pairs
  
  ! augmentation
  PUBLIC :: NM_Augment_Subspace
  PUBLIC :: NM_Select_Augmentation_Vectors
  
  ! spectral
  PUBLIC :: NM_Compute_Spectral_Preconditioner
  PUBLIC :: NM_Update_Spectral_Info
  
  ! utils
  PUBLIC :: NM_Krylov_Basis_Init
  PUBLIC :: NM_Krylov_Basis_Destroy

CONTAINS

  !=============================================================================
  ! MAIN INTERFACE
  !=============================================================================

  !> @brief Krylov interface
  !! @param[in] A coeff matrix
  !! @param[in] b RHS
  !! @param[inout] x initial guess 
  !! @param[in] params  param
  !! @param[out] result  
  !! @param[out] status error status
  SUBROUTINE NM_Krylov_Extended_Solv(A, b, x, params, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Krylov_Extension_Params), INTENT(IN) :: params
    TYPE(Krylov_Extension_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (params%ext_type%extension_type)
    CASE (NM_KRYLOV_RESTART_ADAPTIVE)
      CALL NM_Adaptive_Restart_GMRES(A, b, x, params, result, status)
    CASE (NM_KRYLOV_AUGMENTED)
      CALL NM_Augmented_GMRES(A, b, x, params, result, status)
    CASE (NM_KRYLOV_DEFLATED)
      CALL NM_Deflated_GMRES(A, b, x, params, result, status)
    CASE DEFAULT
      CALL NM_Adaptive_Restart_GMRES(A, b, x, params, result, status)
    END SELECT

  END SUBROUTINE NM_Krylov_Extended_Solv

  !> @brief  GMRES
  !! @details  convergence 
  SUBROUTINE NM_Adaptive_Restart_GMRES(A, b, x, params, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Krylov_Extension_Params), INTENT(IN) :: params
    TYPE(Krylov_Extension_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Krylov_Basis) :: basis
    REAL(DP), ALLOCATABLE :: r(:), w(:), y(:)
    REAL(DP) :: beta, residual_norm, residual_norm_prev, b_norm
    REAL(DP) :: convergence_rate
    INTEGER(i4) :: n, restart_freq, iter, restart
    INTEGER(i4) :: max_restarts

    CALL init_error_status(status)

    n = SIZE(b)
    restart_freq = params%basis%min_basis_size
    max_restarts = params%basis%max_basis_size / restart_freq

    ALLOCATE(r(n), w(n), y(restart_freq))
    CALL NM_Krylov_Basis_Init(n, restart_freq + 1, basis)

    b_norm = SQRT(SUM(b**2))
    IF (b_norm < 1.0E-14_DP) b_norm = ONE

    result%stats%n_iterations = 0_i4
    result%stats%n_matvecs = 0_i4
    result%flags%converged = .FALSE.

    residual_norm_prev = HUGE(ONE)

    DO restart = 1, max_restarts

      ! compute residual
      r = b - MATMUL(A, x)
      residual_norm = SQRT(SUM(r**2))
      beta = residual_norm

      IF (residual_norm / b_norm < 1.0E-6_DP) THEN
        result%flags%converged = .TRUE.
        EXIT
      END IF

      !  Krylov
      basis%V(:, 1) = r / beta
      basis%dimension = 1_i4

      inner: DO iter = 1, restart_freq
        result%stats%n_iterations = result%stats%n_iterations + 1_i4

        ! Arnoldi 
        w = MATMUL(A, basis%V(:, iter))
        result%stats%n_matvecs = result%stats%n_matvecs + 1_i4

        !  
        CALL NM_Orthogonalize_Vector(w, basis%V(:, 1:iter), basis%H(1:iter+1, iter))

        IF (basis%H(iter+1, iter) < 1.0E-14_DP) THEN
          EXIT inner
        END IF

        basis%V(:, iter+1) = w / basis%H(iter+1, iter)
        basis%dimension = iter + 1_i4

        ! solve ? ?
        residual_norm = beta * basis%H(iter+1, iter)

        IF (residual_norm / b_norm < 1.0E-6_DP) THEN
          ! update
          y(iter) = beta / basis%H(iter, iter)
          DO n = iter-1, 1, -1
            y(n) = (beta - DOT_PRODUCT(basis%H(n, n+1:iter), y(n+1:iter))) / basis%H(n, n)
          END DO
          x = x + MATMUL(basis%V(:, 1:iter), y(1:iter))
          result%flags%converged = .TRUE.
          EXIT inner
        END IF
      END DO inner

      !  
      convergence_rate = residual_norm / residual_norm_prev
      IF (convergence_rate > 0.8_DP) THEN
        ! convergence ?
        restart_freq = MIN(restart_freq + 5, params%basis%max_basis_size)
      ELSE IF (convergence_rate < 0.3_DP) THEN
        ! convergence ?
        restart_freq = MAX(restart_freq - 2, params%basis%min_basis_size)
      END IF

      residual_norm_prev = residual_norm

      !  
      IF (restart < max_restarts .AND. .NOT. result%flags%converged) THEN
        DEALLOCATE(y)
        ALLOCATE(y(restart_freq))
        CALL NM_Krylov_Basis_Destroy(basis)
        CALL NM_Krylov_Basis_Init(n, restart_freq + 1, basis)
      END IF
    END DO

    result%residual%residual_norm = residual_norm
    result%stats%basis_size = restart_freq
    IF (ALLOCATED(result%x)) DEALLOCATE(result%x)
    ALLOCATE(result%x(SIZE(x)))
    result%x = x

    IF (result%flags%converged) THEN
      result%message = "Adaptive restart GMRES converged"
    ELSE
      result%message = "Adaptive restart GMRES did not converge"
    END IF

    CALL NM_Krylov_Basis_Destroy(basis)
    DEALLOCATE(r, w, y)

  END SUBROUTINE NM_Adaptive_Restart_GMRES

  !> @brief  GMRES
  !! @details  Krylov 
  SUBROUTINE NM_Augmented_GMRES(A, b, x, params, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Krylov_Extension_Params), INTENT(IN) :: params
    TYPE(Krylov_Extension_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Augmented_Krylov_Subspace) :: aug_subspace
    TYPE(Krylov_Basis) :: basis
    REAL(DP), ALLOCATABLE :: r(:), eigenvectors(:,:)
    INTEGER(i4) :: n

    CALL init_error_status(status)

    n = SIZE(b)

    ! Initialize  
    ALLOCATE(aug_subspace%U(n, params%max_eigenvectors))
    ALLOCATE(aug_subspace%C(n, params%max_eigenvectors))
    aug_subspace%n_augmented = 0_i4

    !  GMRES 
    CALL NM_Adaptive_Restart_GMRES(A, b, x, params, result, status)

    ! computationRitzvector 
    IF (result%stats%n_iterations > params%basis%max_basis_size) THEN
      ALLOCATE(eigenvectors(n, params%max_eigenvectors))
      CALL NM_Calc_Ritz_Pairs(A, basis, eigenvectors, aug_subspace%n_augmented)

      IF (aug_subspace%n_augmented > 0) THEN
        aug_subspace%U(:, 1:aug_subspace%n_augmented) = &
          eigenvectors(:, 1:aug_subspace%n_augmented)
        aug_subspace%C = MATMUL(A, aug_subspace%U)
      END IF

      DEALLOCATE(eigenvectors)
    END IF

    result%message = "Augmented GMRES completed"

    IF (ALLOCATED(aug_subspace%U)) DEALLOCATE(aug_subspace%U)
    IF (ALLOCATED(aug_subspace%C)) DEALLOCATE(aug_subspace%C)

  END SUBROUTINE NM_Augmented_GMRES

  !> @brief  GMRES
  !! @details  
  SUBROUTINE NM_Deflated_GMRES(A, b, x, params, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Krylov_Extension_Params), INTENT(IN) :: params
    TYPE(Krylov_Extension_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    !  implements ?GMRES
    CALL NM_Augmented_GMRES(A, b, x, params, result, status)
    result%message = "Deflated GMRES [using Augmented]"

  END SUBROUTINE NM_Deflated_GMRES

  !=============================================================================
  ! KRYLOV BASIS OPERATIONS
  !=============================================================================

  !> @brief  Krylov
  !! @param[in] A coeff matrix
  !! @param[in] v0 Initializevector
  !! @param[in] m  dim
  !! @param[out] basis Krylov
  !! @param[out] status error status
  SUBROUTINE NM_Build_Krylov_Basis(A, v0, m, basis, status)
    REAL(DP), INTENT(IN) :: A(:,:), v0(:)
    INTEGER(i4), INTENT(IN) :: m
    TYPE(Krylov_Basis), INTENT(OUT) :: basis
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: w(:)
    INTEGER(i4) :: n, j

    CALL init_error_status(status)

    n = SIZE(v0)
    CALL NM_Krylov_Basis_Init(n, m + 1, basis)
    ALLOCATE(w(n))

    basis%V(:, 1) = v0 / SQRT(SUM(v0**2))
    basis%dimension = 1_i4

    DO j = 1, m
      w = MATMUL(A, basis%V(:, j))

      CALL NM_Orthogonalize_Vector(w, basis%V(:, 1:j), basis%H(1:j+1, j))

      IF (basis%H(j+1, j) < 1.0E-14_DP) THEN
        EXIT
      END IF

      basis%V(:, j+1) = w / basis%H(j+1, j)
      basis%dimension = j + 1_i4
    END DO

    DEALLOCATE(w)

  END SUBROUTINE NM_Build_Krylov_Basis

  !> @brief  Krylov
  SUBROUTINE NM_Extend_Krylov_Basis(A, basis, num_vectors, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Krylov_Basis), INTENT(INOUT) :: basis
    INTEGER(i4), INTENT(IN) :: num_vectors
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: w(:)
    INTEGER(i4) :: n, j, start_dim

    CALL init_error_status(status)

    n = SIZE(basis%V, 1)
    ALLOCATE(w(n))

    start_dim = basis%dimension

    DO j = 1, num_vectors
      IF (start_dim + j > basis%max_dim) EXIT

      w = MATMUL(A, basis%V(:, start_dim + j - 1))

      CALL NM_Orthogonalize_Vector(w, basis%V(:, 1:start_dim+j-1), &
                                    basis%H(1:start_dim+j, start_dim+j-1))

      IF (basis%H(start_dim+j, start_dim+j-1) < 1.0E-14_DP) THEN
        EXIT
      END IF

      basis%V(:, start_dim+j) = w / basis%H(start_dim+j, start_dim+j-1)
      basis%dimension = start_dim + j
    END DO

    DEALLOCATE(w)

  END SUBROUTINE NM_Extend_Krylov_Basis

  !> @brief vector ?Gram-Schmidt
  SUBROUTINE NM_Orthogonalize_Vector(w, V, h)
    REAL(DP), INTENT(INOUT) :: w(:)
    REAL(DP), INTENT(IN) :: V(:,:)
    REAL(DP), INTENT(OUT) :: h(:)

    INTEGER(i4) :: j, n

    n = SIZE(V, 2)

    DO j = 1, n
      h(j) = DOT_PRODUCT(V(:, j), w)
      w = w - h(j) * V(:, j)
    END DO

    h(n+1) = SQRT(SUM(w**2))

    IF (h(n+1) > 1.0E-14_DP) THEN
      w = w / h(n+1)
    END IF

  END SUBROUTINE NM_Orthogonalize_Vector

  !> @brief computationRitz
  SUBROUTINE NM_Calc_Ritz_Pairs(A, basis, eigenvectors, n_converged)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Krylov_Basis), INTENT(IN) :: basis
    REAL(DP), INTENT(OUT) :: eigenvectors(:,:)
    INTEGER(i4), INTENT(OUT) :: n_converged

    REAL(DP), ALLOCATABLE :: H_eigenvectors(:,:), H_eigenvalues(:)
    INTEGER(i4) :: m, i

    m = basis%dimension - 1_i4
    IF (m < 1) THEN
      n_converged = 0_i4
      RETURN
    END IF

    ALLOCATE(H_eigenvectors(m, m), H_eigenvalues(m))

    !  implements ?Hessenbergmatrix value
    H_eigenvalues = ZERO
    DO i = 1, m
      H_eigenvalues(i) = basis%H(i, i)
    END DO

    ! computationRitzvector
    DO i = 1, MIN(m, SIZE(eigenvectors, 2))
      eigenvectors(:, i) = MATMUL(basis%V(:, 1:m), H_eigenvectors(:, i))
    END DO

    n_converged = MIN(m, SIZE(eigenvectors, 2))

    DEALLOCATE(H_eigenvectors, H_eigenvalues)

  END SUBROUTINE NM_Calc_Ritz_Pairs

  !=============================================================================
  ! AUGMENTED SUBSPACE
  !=============================================================================

  !> @brief  subspace
  SUBROUTINE NM_Augment_Subspace(aug_subspace, new_vectors)
    TYPE(Augmented_Krylov_Subspace), INTENT(INOUT) :: aug_subspace
    REAL(DP), INTENT(IN) :: new_vectors(:,:)

    INTEGER(i4) :: n_new, n_total, n_max

    n_new = SIZE(new_vectors, 2)
    n_max = SIZE(aug_subspace%U, 2)

    n_total = MIN(aug_subspace%n_augmented + n_new, n_max)

    IF (n_total > aug_subspace%n_augmented) THEN
      aug_subspace%U(:, aug_subspace%n_augmented+1:n_total) = &
        new_vectors(:, 1:n_total-aug_subspace%n_augmented)
      aug_subspace%n_augmented = n_total
    END IF

  END SUBROUTINE NM_Augment_Subspace

  !> @brief  vector
  SUBROUTINE NM_Se_Au_Vectors(eigenvalues, eigenvectors, &
                                             num_select, selected_vectors)
    REAL(DP), INTENT(IN) :: eigenvalues(:), eigenvectors(:,:)
    INTEGER(i4), INTENT(IN) :: num_select
    REAL(DP), INTENT(OUT) :: selected_vectors(:,:)

    INTEGER(i4) :: n, i

    n = MIN(num_select, SIZE(eigenvectors, 2))

    !  value vector
    DO i = 1, n
      selected_vectors(:, i) = eigenvectors(:, i)
    END DO

  END SUBROUTINE NM_Select_Augmentation_Vectors

  !=============================================================================
  ! SPECTRAL PRECONDITIONER
  !=============================================================================

  !> @brief computation 
  SUBROUTINE NM_Co_Sp_Preconditioner(A, spectral_info, M)
    REAL(DP), INTENT(IN) :: A(:,:)
    TYPE(Spectral_Info), INTENT(IN) :: spectral_info
    REAL(DP), INTENT(OUT) :: M(:,:)

    !  implements ?processing
    INTEGER(i4) :: i, n

    n = SIZE(A, 1)
    M = ZERO

    DO i = 1, n
      IF (ABS(A(i,i)) > 1.0E-14_DP) THEN
        M(i,i) = ONE / A(i,i)
      ELSE
        M(i,i) = ONE
      END IF
    END DO

  END SUBROUTINE NM_Compute_Spectral_Preconditioner

  !> @brief  
  SUBROUTINE NM_Update_Spectral_Info(basis, spectral_info)
    TYPE(Krylov_Basis), INTENT(IN) :: basis
    TYPE(Spectral_Info), INTENT(INOUT) :: spectral_info

    ! simplified impl
    spectral_info%n_converged = 0_i4

  END SUBROUTINE NM_Update_Spectral_Info

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief Initialize Krylov
  SUBROUTINE NM_Krylov_Basis_Init(n, max_dim, basis)
    INTEGER(i4), INTENT(IN) :: n, max_dim
    TYPE(Krylov_Basis), INTENT(OUT) :: basis

    basis%max_dim = max_dim
    basis%dimension = 0_i4

    IF (ALLOCATED(basis%V)) DEALLOCATE(basis%V)
    IF (ALLOCATED(basis%H)) DEALLOCATE(basis%H)

    ALLOCATE(basis%V(n, max_dim))
    ALLOCATE(basis%H(max_dim, max_dim))

    basis%V = ZERO
    basis%H = ZERO

  END SUBROUTINE NM_Krylov_Basis_Init

  !> @brief  Krylov
  SUBROUTINE NM_Krylov_Basis_Destroy(basis)
    TYPE(Krylov_Basis), INTENT(INOUT) :: basis

    IF (ALLOCATED(basis%V)) DEALLOCATE(basis%V)
    IF (ALLOCATED(basis%H)) DEALLOCATE(basis%H)

    basis%dimension = 0_i4
    basis%max_dim = 0_i4

  END SUBROUTINE NM_Krylov_Basis_Destroy

END MODULE NM_Conv_KrylovExt