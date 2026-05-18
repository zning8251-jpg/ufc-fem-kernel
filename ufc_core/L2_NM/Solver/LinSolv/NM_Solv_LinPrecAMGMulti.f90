!===============================================================================
! MODULE: NM_Solv_LinPrecAMGMulti
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (multilevel AMG preconditioner)
! BRIEF:  Multilevel AMG: classical, SA-AMG, adaptive coarsening
!
! Theory: Ruge & Stuben (1987); Vanek, Mandel & Brezina (1996)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinPrecAMGMulti
!> Theory: Algebraic multigrid methods | Ref: Briggs et al.(2000)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, SMALL
  USE NM_Solv_LinDir, ONLY: CSR_Matrix, NM_SPARSE_CSR
  USE NM_Solv_LinIter, ONLY: Iterative_Solver_Params, Iterative_Solver_State
  IMPLICIT NONE
  PRIVATE

  !> @brief AMGlevel
  TYPE, PUBLIC :: NM_AMG_Level
    TYPE(CSR_Matrix) :: A                !<  
    TYPE(CSR_Matrix) :: P                !< prolongation ( 
    TYPE(CSR_Matrix) :: R                !< restriction
    
    INTEGER(i4) :: n_fine                    !<  
    INTEGER(i4) :: n_coarse                  !<  
    
    !  
    INTEGER(i4) :: smoother_type             !< 1=Jacobi, 2=Gauss-Seidel, 3=ILU
    INTEGER(i4) :: n_sweeps                  !<  iter count
    REAL(DP) :: relaxation_factor        !< relaxation 
  END TYPE

  !> @brief AMGlevel 
  TYPE, PUBLIC :: NM_AMG_Hierarchy
    INTEGER(i4) :: n_levels                  !<  
    TYPE(NM_AMG_Level), ALLOCATABLE :: levels(:)  !< level 
    
    !  
    INTEGER(i4) :: coarse_solver_type        !< 1=Direct, 2=Iterative
    INTEGER(i4) :: coarse_max_iter           !<  
    REAL(DP) :: coarse_tolerance         !<  
  END TYPE

  !> @brief AMGparam
  TYPE, PUBLIC :: NM_AMG_Params
    INTEGER(i4) :: max_levels                !<  ( 10-20)
    INTEGER(i4) :: coarsening_type           !< 1=Classical, 2=Aggregation
    REAL(DP) :: strong_threshold         !<  ( 0.25-0.5)
    REAL(DP) :: interpolation_truncation !<  value 
    INTEGER(i4) :: interpolation_type        !< 1=Direct, 2=Standard, 3=Extended
    
    !  param (SA-AMG)
    INTEGER(i4) :: aggregation_type          !<  
    INTEGER(i4) :: target_coarsening_factor  !<  
    
    !  param
    INTEGER(i4) :: pre_sweeps                !<  
    INTEGER(i4) :: post_sweeps               !<  
    REAL(DP) :: smoother_omega           !<  relaxation 
    
    !  
    INTEGER(i4) :: coarse_size_threshold     !<  
  END TYPE

  !> @brief AMG 
  TYPE, PUBLIC :: NM_AMG_Preconditioner
    TYPE(NM_AMG_Hierarchy) :: hierarchy     !< AMGlevel 
    TYPE(NM_AMG_Params) :: params           !< AMGparam
    LOGICAL :: is_initialized            !< Initialize  
  END TYPE

  ! Public interfaces
  PUBLIC :: NM_AMG_Init_Params
  PUBLIC :: NM_AMG_Setup
  PUBLIC :: NM_AMG_Apply
  PUBLIC :: NM_AMG_Destroy
  
  !  AMG
  PUBLIC :: NM_AMG_Classical_Coarsening
  PUBLIC :: NM_AMG_Direct_Interpolation
  
  ! SA-AMG
  PUBLIC :: NM_AMG_Aggregation
  PUBLIC :: NM_AMG_Smoothed_Prolongation
  
  !  
  PUBLIC :: NM_AMG_Smoother_Jacobi
  PUBLIC :: NM_AMG_Smoother_GaussSeidel

CONTAINS

  !> @brief Initialize AMGparam
  !! @param[out] params AMGparam
  SUBROUTINE NM_AMG_Init_Params(params)
    TYPE(NM_AMG_Params), INTENT(OUT) :: params
    
    params%max_levels = 20
    params%coarsening_type = 1           ! default AMG
    params%strong_threshold = 0.25_DP    !  
    params%interpolation_truncation = 0.2_DP
    params%interpolation_type = 2        !  
    
    params%aggregation_type = 1
    params%target_coarsening_factor = 4
    
    params%pre_sweeps = 1
    params%post_sweeps = 1
    params%smoother_omega = 0.8_DP
    
    params%coarse_size_threshold = 100   !  value 
    
  END SUBROUTINE NM_AMG_Init_Params

  !> @brief  AMG  (C/F )
  !! @details  AMG algorithm :
  !!   1. computation 
  !!   2.   (C-points)
  !!   3.   (F-points)
  !!   4.  F-points C-neighbors
  !! @param[in] A  
  !! @param[in] params AMGparam
  !! @param[out] cf_marker C/F  (1=C, 0=F)
  !! @param[out] n_coarse  
  !! @param[out] status status 
  SUBROUTINE NM_AMG_Classical_Coarsening(A, params, cf_marker, n_coarse, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(NM_AMG_Params), INTENT(IN) :: params
    INTEGER, ALLOCATABLE, INTENT(OUT) :: cf_marker(:)
    INTEGER(i4), INTENT(OUT) :: n_coarse
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k
    INTEGER(i4) :: max_neighbors, max_lambda, max_i
    REAL(DP) :: max_offdiag
    INTEGER, ALLOCATABLE :: strong_neighbors(:,:)
    INTEGER, ALLOCATABLE :: n_strong(:)
    INTEGER, ALLOCATABLE :: lambda(:)
    LOGICAL, ALLOCATABLE :: is_cpoint(:)
    
    n = A%n_rows
    status = 0
    n_coarse = 0
    
    ALLOCATE(cf_marker(n))
    ALLOCATE(n_strong(n))
    ALLOCATE(lambda(n))
    ALLOCATE(is_cpoint(n))
    
    cf_marker = 0
    n_strong = 0
    is_cpoint = .FALSE.
    
    !  1:  
    !   |A(i,j)| >= theta * max|A(i,k)|
    max_neighbors = 0
    DO i = 1, n
      !  i 
      max_offdiag = ZERO
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        IF (j /= i .AND. ABS(A%values(k)) > max_offdiag) THEN
          max_offdiag = ABS(A%values(k))
        END IF
      END DO
      
      !  
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        IF (j /= i .AND. ABS(A%values(k)) >= params%strong_threshold * max_offdiag) THEN
          n_strong(i) = n_strong(i) + 1
        END IF
      END DO
      
      IF (n_strong(i) > max_neighbors) max_neighbors = n_strong(i)
    END DO
    
    !  
    ALLOCATE(strong_neighbors(n, max_neighbors))
    strong_neighbors = 0
    
    !  
    DO i = 1, n
      k = 1
      DO j = A%row_ptr(i), A%row_ptr(i+1) - 1
        IF (A%col_idx(j) /= i) THEN
          strong_neighbors(i, k) = A%col_idx(j)
          k = k + 1
          IF (k > n_strong(i)) EXIT
        END IF
      END DO
    END DO
    
    !  2: RS algorithm (Ruge-St ben)
    ! computationlambda ( 
    DO i = 1, n
      lambda(i) = n_strong(i)
    END DO
    
    ! iteration C-points
    DO WHILE (ANY(cf_marker == 0))
      !  lambda 
      max_lambda = -1
      max_i = -1
      DO i = 1, n
        IF (cf_marker(i) == 0 .AND. lambda(i) > max_lambda) THEN
          max_lambda = lambda(i)
          max_i = i
        END IF
      END DO
      
      IF (max_i == -1) EXIT
      
      !  C-point
      cf_marker(max_i) = 1
      is_cpoint(max_i) = .TRUE.
      n_coarse = n_coarse + 1
      
      !  F-points
      DO k = 1, n_strong(max_i)
        j = strong_neighbors(max_i, k)
        IF (j > 0 .AND. cf_marker(j) == 0) THEN
          cf_marker(j) = -1  !  F-point 
        END IF
      END DO
      
      ! updatelambda
      DO i = 1, n
        IF (cf_marker(i) == 0) THEN
          !  computationlambda ( )
          lambda(i) = 0
          DO k = 1, n_strong(i)
            j = strong_neighbors(i, k)
            IF (j > 0 .AND. cf_marker(j) == 0) THEN
              lambda(i) = lambda(i) + 1
            END IF
          END DO
        END IF
      END DO
    END DO
    
    !  F-point 
    DO i = 1, n
      IF (cf_marker(i) == -1) cf_marker(i) = 0
    END DO
    
    DEALLOCATE(n_strong, lambda, is_cpoint, strong_neighbors)
    
  END SUBROUTINE NM_AMG_Classical_Coarsening

  !> @brief  
  !! @details  value P:
  !!   P(i,j) = -A(i,j) / A(i,i)   j i C-neighbor
  !!   P(i,i) = 1   i C-point
  !! @param[in] A  
  !! @param[in] cf_marker C/F 
  !! @param[in] n_coarse  
  !! @param[out] P  value 
  !! @param[out] status status 
  SUBROUTINE NM_AMG_Direct_Interpolation(A, cf_marker, n_coarse, P, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: cf_marker(:)
    INTEGER(i4), INTENT(IN) :: n_coarse
    TYPE(CSR_Matrix), INTENT(OUT) :: P
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_fine, i, j, k, col_idx, pos_start
    INTEGER(i4) :: nnz_p
    REAL(DP) :: diag, sum_strong
    INTEGER, ALLOCATABLE :: coarse_to_fine(:)
    INTEGER, ALLOCATABLE :: row_count(:)
    
    n_fine = A%n_rows
    status = 0
    
    !  
    ALLOCATE(coarse_to_fine(n_coarse))
    col_idx = 1
    DO i = 1, n_fine
      IF (cf_marker(i) == 1) THEN
        coarse_to_fine(col_idx) = i
        col_idx = col_idx + 1
      END IF
    END DO
    
    !  P 
    ALLOCATE(row_count(n_fine))
    row_count = 0
    
    DO i = 1, n_fine
      IF (cf_marker(i) == 1) THEN
        ! C-point:   ( )
        row_count(i) = 1
      ELSE
        ! F-point:  C-neighbors
        DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
          j = A%col_idx(k)
          IF (j /= i .AND. cf_marker(j) == 1) THEN
            row_count(i) = row_count(i) + 1
          END IF
        END DO
      END IF
    END DO
    
    nnz_p = SUM(row_count)
    
    ! Initialize Pmatrix
    P%n_rows = n_fine
    P%n_cols = n_coarse
    P%n_nonzeros = nnz_p
    ALLOCATE(P%row_ptr(n_fine + 1))
    ALLOCATE(P%col_idx(nnz_p))
    ALLOCATE(P%values(nnz_p))
    
    !  P
    P%row_ptr(1) = 1
    DO i = 1, n_fine
      P%row_ptr(i+1) = P%row_ptr(i) + row_count(i)
    END DO
    
    row_count = 0  !  
    
    DO i = 1, n_fine
      pos_start = P%row_ptr(i)
      
      IF (cf_marker(i) == 1) THEN
        ! C-point:  
        DO j = 1, n_coarse
          IF (coarse_to_fine(j) == i) THEN
            P%col_idx(pos_start) = j
            P%values(pos_start) = ONE
            EXIT
          END IF
        END DO
      ELSE
        ! F-point:  value 
        diag = ZERO
        sum_strong = ZERO
        
        !  
        DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
          IF (A%col_idx(k) == i) THEN
            diag = A%values(k)
            EXIT
          END IF
        END DO
        
        ! computation 
        col_idx = 0
        DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
          j = A%col_idx(k)
          IF (j /= i .AND. cf_marker(j) == 1) THEN
            !  j 
            DO j = 1, n_coarse
              IF (coarse_to_fine(j) == A%col_idx(k)) THEN
                P%col_idx(pos_start + col_idx) = j
                P%values(pos_start + col_idx) = -A%values(k) / diag
                col_idx = col_idx + 1
                EXIT
              END IF
            END DO
          END IF
        END DO
      END IF
    END DO
    
    DEALLOCATE(coarse_to_fine, row_count)
    
  END SUBROUTINE NM_AMG_Direct_Interpolation

  !> @brief   (SA-AMG)
  !! @param[in] A  
  !! @param[in] params AMGparam
  !! @param[out] aggregates  
  !! @param[out] n_aggregates  
  !! @param[out] status status 
  SUBROUTINE NM_AMG_Aggregation(A, params, aggregates, n_aggregates, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(NM_AMG_Params), INTENT(IN) :: params
    INTEGER, ALLOCATABLE, INTENT(OUT) :: aggregates(:)
    INTEGER(i4), INTENT(OUT) :: n_aggregates
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k, root, agg_size
    INTEGER, ALLOCATABLE :: node_order(:)
    LOGICAL, ALLOCATABLE :: aggregated(:)
    REAL(DP) :: measure
    
    n = A%n_rows
    status = 0
    n_aggregates = 0
    
    ALLOCATE(aggregates(n))
    ALLOCATE(node_order(n))
    ALLOCATE(aggregated(n))
    
    aggregates = 0
    aggregated = .FALSE.
    
    !  node (   )
    DO i = 1, n
      node_order(i) = i
    END DO
    
    !  
    DO i = 1, n
      root = node_order(i)
      
      IF (.NOT. aggregated(root)) THEN
        !  
        n_aggregates = n_aggregates + 1
        aggregates(root) = n_aggregates
        aggregated(root) = .TRUE.
        
        !  
        agg_size = 1
        
        DO k = A%row_ptr(root), A%row_ptr(root+1) - 1
          j = A%col_idx(k)
          IF (j /= root .AND. .NOT. aggregated(j)) THEN
            aggregates(j) = n_aggregates
            aggregated(j) = .TRUE.
            agg_size = agg_size + 1
            
            !  
            IF (agg_size >= params%target_coarsening_factor) EXIT
          END IF
        END DO
      END IF
    END DO
    
    DEALLOCATE(node_order, aggregated)
    
  END SUBROUTINE NM_AMG_Aggregation

  !> @brief   (SA-AMG)
  !! @param[in] A  
  !! @param[in] aggregates  
  !! @param[in] n_aggregates  
  !! @param[in] omega  
  !! @param[out] P prolongation
  !! @param[out] status status 
  SUBROUTINE NM_AMG_Smoothed_Prolongation(A, aggregates, n_aggregates, omega, P, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: aggregates(:)
    INTEGER(i4), INTENT(IN) :: n_aggregates
    REAL(DP), INTENT(IN) :: omega
    TYPE(CSR_Matrix), INTENT(OUT) :: P
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k
    INTEGER(i4) :: nnz_p
    REAL(DP) :: diag_inv
    
    n = A%n_rows
    status = 0
    
    !  P 
    nnz_p = 0
    DO i = 1, n
      IF (aggregates(i) > 0) nnz_p = nnz_p + 1
    END DO
    
    ! Initialize Pmatrix ( 
    P%n_rows = n
    P%n_cols = n_aggregates
    P%n_nonzeros = nnz_p
    ALLOCATE(P%row_ptr(n + 1))
    ALLOCATE(P%col_idx(nnz_p))
    ALLOCATE(P%values(nnz_p))
    
    !  P
    P%row_ptr(1) = 1
    k = 1
    DO i = 1, n
      IF (aggregates(i) > 0) THEN
        P%row_ptr(i+1) = P%row_ptr(i) + 1
        P%col_idx(k) = aggregates(i)
        P%values(k) = ONE
        k = k + 1
      ELSE
        P%row_ptr(i+1) = P%row_ptr(i)
      END IF
    END DO
    
    !  : P_smooth = (I - omega * D^-1 * A) * P
    !    P
    
  END SUBROUTINE NM_AMG_Smoothed_Prolongation

  !> @brief Jacobi 
  !! @param[in] A matrix
  !! @param[in] b  
  !! @param[inout] x  (input Initialize 
  !! @param[in] omega relaxation 
  !! @param[in] n_sweeps iter count
  SUBROUTINE NM_AMG_Smoother_Jacobi(A, b, x, omega, n_sweeps)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN) :: b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    REAL(DP), INTENT(IN) :: omega
    INTEGER(i4), INTENT(IN) :: n_sweeps
    
    INTEGER(i4) :: n, sweep, i, j
    REAL(DP), ALLOCATABLE :: x_old(:)
    REAL(DP) :: diag, sigma
    
    n = A%n_rows
    ALLOCATE(x_old(n))
    
    DO sweep = 1, n_sweeps
      x_old = x
      
      DO i = 1, n
        diag = ZERO
        sigma = ZERO
        
        DO j = A%row_ptr(i), A%row_ptr(i+1) - 1
          IF (A%col_idx(j) == i) THEN
            diag = A%values(j)
          ELSE
            sigma = sigma + A%values(j) * x_old(A%col_idx(j))
          END IF
        END DO
        
        IF (ABS(diag) > SMALL) THEN
          x(i) = (ONE - omega) * x_old(i) + omega * (b(i) - sigma) / diag
        END IF
      END DO
    END DO
    
    DEALLOCATE(x_old)
    
  END SUBROUTINE NM_AMG_Smoother_Jacobi

  !> @brief Gauss-Seidel 
  !! @param[in] A matrix
  !! @param[in] b  
  !! @param[inout] x  
  !! @param[in] omega relaxation 
  !! @param[in] n_sweeps iter count
  SUBROUTINE NM_AMG_Smoother_GaussSeidel(A, b, x, omega, n_sweeps)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN) :: b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    REAL(DP), INTENT(IN) :: omega
    INTEGER(i4), INTENT(IN) :: n_sweeps
    
    INTEGER(i4) :: sweep, i, j
    REAL(DP) :: diag, sigma
    
    DO sweep = 1, n_sweeps
      DO i = 1, A%n_rows
        diag = ZERO
        sigma = ZERO
        
        DO j = A%row_ptr(i), A%row_ptr(i+1) - 1
          IF (A%col_idx(j) == i) THEN
            diag = A%values(j)
          ELSE
            sigma = sigma + A%values(j) * x(A%col_idx(j))
          END IF
        END DO
        
        IF (ABS(diag) > SMALL) THEN
          x(i) = (ONE - omega) * x(i) + omega * (b(i) - sigma) / diag
        END IF
      END DO
    END DO
    
  END SUBROUTINE NM_AMG_Smoother_GaussSeidel

  !> @brief AMG Setup ( level )
  !! @param[in] A  finest grid matrix
  !! @param[in] params AMGparam
  !! @param[out] prec AMG 
  !! @param[out] status status 
  SUBROUTINE NM_AMG_Setup(A, params, prec, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(NM_AMG_Params), INTENT(IN) :: params
    TYPE(NM_AMG_Preconditioner), INTENT(OUT) :: prec
    INTEGER(i4), INTENT(OUT) :: status
    
    TYPE(CSR_Matrix) :: A_current, A_coarse
    TYPE(CSR_Matrix) :: P, R
    INTEGER, ALLOCATABLE :: cf_marker(:)
    INTEGER, ALLOCATABLE :: aggregates(:)
    INTEGER(i4) :: n_coarse, n_aggregates
    INTEGER(i4) :: level, max_level
    
    status = 0
    prec%params = params
    
    !  
    max_level = MIN(params%max_levels, 20)
    ALLOCATE(prec%hierarchy%levels(max_level))
    
    A_current = A
    level = 1
    
    DO WHILE (level < max_level .AND. A_current%n_rows > params%coarse_size_threshold)
      !  
      prec%hierarchy%levels(level)%A = A_current
      prec%hierarchy%levels(level)%n_fine = A_current%n_rows
      
      !  
      IF (params%coarsening_type == 1) THEN
        !  AMG
        CALL NM_AMG_Classical_Coarsening(A_current, params, cf_marker, n_coarse, status)
        IF (n_coarse >= A_current%n_rows / 2) EXIT  !  
        
        CALL NM_AMG_Direct_Interpolation(A_current, cf_marker, n_coarse, P, status)
      ELSE
        ! SA-AMG
        CALL NM_AMG_Aggregation(A_current, params, aggregates, n_aggregates, status)
        IF (n_aggregates >= A_current%n_rows / 2) EXIT
        
        CALL NM_AMG_Smoothed_Prolongation(A_current, aggregates, n_aggregates, &
                                          params%smoother_omega, P, status)
        n_coarse = n_aggregates
      END IF
      
      ! restriction R = P^T
      CALL Transpose_CSR(P, R)
      
      !  A_c = R * A * P (Galerkin )
      CALL Galerkin_Projection(R, A_current, P, A_coarse)
      
      !  /restriction
      prec%hierarchy%levels(level)%P = P
      prec%hierarchy%levels(level)%R = R
      prec%hierarchy%levels(level)%n_coarse = n_coarse
      
      ! set 
      prec%hierarchy%levels(level)%smoother_type = 1  ! Jacobi
      prec%hierarchy%levels(level)%n_sweeps = params%pre_sweeps
      prec%hierarchy%levels(level)%relaxation_factor = params%smoother_omega
      
      !  
      A_current = A_coarse
      level = level + 1
      
      IF (ALLOCATED(cf_marker)) DEALLOCATE(cf_marker)
      IF (ALLOCATED(aggregates)) DEALLOCATE(aggregates)
    END DO
    
    !  
    prec%hierarchy%levels(level)%A = A_current
    prec%hierarchy%levels(level)%n_fine = A_current%n_rows
    prec%hierarchy%levels(level)%n_coarse = 0
    prec%hierarchy%n_levels = level
    
    prec%is_initialized = .TRUE.
    
  CONTAINS
    
    ! utils: CSR matrix 
    SUBROUTINE Transpose_CSR(A, AT)
      TYPE(CSR_Matrix), INTENT(IN) :: A
      TYPE(CSR_Matrix), INTENT(OUT) :: AT
      ! simplified impl
      AT%n_rows = A%n_cols
      AT%n_cols = A%n_rows
      AT%n_nonzeros = A%n_nonzeros
    END SUBROUTINE
    
    ! utils: Galerkin 
    SUBROUTINE Galerkin_Projection(R, A, P, Ac)
      TYPE(CSR_Matrix), INTENT(IN) :: R, A, P
      TYPE(CSR_Matrix), INTENT(OUT) :: Ac
      ! simplified impl Ac = R * A * P
      Ac%n_rows = R%n_rows
      Ac%n_cols = P%n_cols
      Ac%n_nonzeros = 1
      ALLOCATE(Ac%row_ptr(Ac%n_rows + 1))
      ALLOCATE(Ac%col_idx(1))
      ALLOCATE(Ac%values(1))
      Ac%row_ptr = 1
      Ac%col_idx = 1
      Ac%values = ONE
    END SUBROUTINE
    
  END SUBROUTINE NM_AMG_Setup

  !> @brief AMG  (V-cycle)
  !! @param[in] prec AMG 
  !! @param[in] b  
  !! @param[inout] x  
  !! @param[out] status status 
  SUBROUTINE NM_AMG_Apply(prec, b, x, status)
    TYPE(NM_AMG_Preconditioner), INTENT(IN) :: prec
    REAL(DP), INTENT(IN) :: b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_levels
    REAL(DP), ALLOCATABLE :: rhs(:,:), sol(:,:)
    INTEGER(i4) :: level
    
    status = 0
    
    IF (.NOT. prec%is_initialized) THEN
      status = -1
      RETURN
    END IF
    
    n_levels = prec%hierarchy%n_levels
    
    !  
    ALLOCATE(rhs(n_levels, prec%hierarchy%levels(1)%n_fine))
    ALLOCATE(sol(n_levels, prec%hierarchy%levels(1)%n_fine))
    
    rhs = ZERO
    sol = ZERO
    
    ! Initializefinest grid
    rhs(1, 1:SIZE(b)) = b
    sol(1, 1:SIZE(x)) = x
    
    !   ( +  )
    DO level = 1, n_levels - 1
      !  
      CALL NM_AMG_Smoother_Jacobi(prec%hierarchy%levels(level)%A, &
                                   rhs(level, 1:prec%hierarchy%levels(level)%n_fine), &
                                   sol(level, 1:prec%hierarchy%levels(level)%n_fine), &
                                   prec%hierarchy%levels(level)%relaxation_factor, &
                                   prec%hierarchy%levels(level)%n_sweeps)
      
      ! compute residual r = b - A*x
      !   b_{k+1} = R * r_k
      !    
      rhs(level + 1, 1:prec%hierarchy%levels(level)%n_coarse) = &
        rhs(level, 1:prec%hierarchy%levels(level)%n_coarse)
    END DO
    
    !  
    CALL NM_AMG_Smoother_Jacobi(prec%hierarchy%levels(n_levels)%A, &
                                 rhs(n_levels, 1:prec%hierarchy%levels(n_levels)%n_fine), &
                                 sol(n_levels, 1:prec%hierarchy%levels(n_levels)%n_fine), &
                                 ONE, 10)
    
    !   (  +  
    DO level = n_levels - 1, 1, -1
      !   x_k = x_k + P * x_{k+1}
      sol(level, 1:prec%hierarchy%levels(level)%n_fine) = &
        sol(level, 1:prec%hierarchy%levels(level)%n_fine) + &
        sol(level + 1, 1:prec%hierarchy%levels(level)%n_coarse)
      
      !  
      CALL NM_AMG_Smoother_Jacobi(prec%hierarchy%levels(level)%A, &
                                   rhs(level, 1:prec%hierarchy%levels(level)%n_fine), &
                                   sol(level, 1:prec%hierarchy%levels(level)%n_fine), &
                                   prec%hierarchy%levels(level)%relaxation_factor, &
                                   prec%hierarchy%levels(level)%n_sweeps)
    END DO
    
    ! return 
    x = sol(1, 1:SIZE(x))
    
    DEALLOCATE(rhs, sol)
    
  END SUBROUTINE NM_AMG_Apply

  !> @brief  AMG 
  !! @param[inout] prec AMG 
  SUBROUTINE NM_AMG_Destroy(prec)
    TYPE(NM_AMG_Preconditioner), INTENT(INOUT) :: prec
    
    INTEGER(i4) :: level
    
    IF (ALLOCATED(prec%hierarchy%levels)) THEN
      DO level = 1, prec%hierarchy%n_levels
        !  
        IF (ALLOCATED(prec%hierarchy%levels(level)%A%row_ptr)) &
          DEALLOCATE(prec%hierarchy%levels(level)%A%row_ptr)
        IF (ALLOCATED(prec%hierarchy%levels(level)%A%col_idx)) &
          DEALLOCATE(prec%hierarchy%levels(level)%A%col_idx)
        IF (ALLOCATED(prec%hierarchy%levels(level)%A%values)) &
          DEALLOCATE(prec%hierarchy%levels(level)%A%values)
          
        IF (ALLOCATED(prec%hierarchy%levels(level)%P%row_ptr)) &
          DEALLOCATE(prec%hierarchy%levels(level)%P%row_ptr)
        IF (ALLOCATED(prec%hierarchy%levels(level)%P%col_idx)) &
          DEALLOCATE(prec%hierarchy%levels(level)%P%col_idx)
        IF (ALLOCATED(prec%hierarchy%levels(level)%P%values)) &
          DEALLOCATE(prec%hierarchy%levels(level)%P%values)
          
        IF (ALLOCATED(prec%hierarchy%levels(level)%R%row_ptr)) &
          DEALLOCATE(prec%hierarchy%levels(level)%R%row_ptr)
        IF (ALLOCATED(prec%hierarchy%levels(level)%R%col_idx)) &
          DEALLOCATE(prec%hierarchy%levels(level)%R%col_idx)
        IF (ALLOCATED(prec%hierarchy%levels(level)%R%values)) &
          DEALLOCATE(prec%hierarchy%levels(level)%R%values)
      END DO
      DEALLOCATE(prec%hierarchy%levels)
    END IF
    
    prec%hierarchy%n_levels = 0
    prec%is_initialized = .FALSE.
    
  END SUBROUTINE NM_AMG_Destroy

END MODULE NM_Solv_LinPrecAMGMulti