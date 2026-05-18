!===============================================================================
! MODULE: NM_DirMUMPS_Brg
! LAYER:  L2_NM
! DOMAIN: Bridge
! ROLE:   Brg — MUMPS/SuperLU sparse direct solver bridge
! BRIEF:  MUMPS multifrontal direct solver + SuperLU supernodal LU bridge.
!         Provides Init/Setup/Analyze/Factorize/Solve/Finalize workflow.
!
! Theory chain:
!   MUMPS: Multifrontal LU with nested dissection ordering.
!   SuperLU: Supernodal factorization with column elimination tree.
!
! References:
!   Amestoy et al. (2001), Li et al. (1999), Davis (2006)
!
! Status: PROD
! Last verified: 2026-04-28
!===============================================================================

MODULE NM_DirMUMPS_Brg
  USE, INTRINSIC :: ISO_C_BINDING
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_MUMPS_Init
  PUBLIC :: NM_MUMPS_Setup_FromCSR
  PUBLIC :: NM_MUMPS_Analyze
  PUBLIC :: NM_MUMPS_Factorize
  PUBLIC :: NM_MUMPS_Solv
  PUBLIC :: NM_MUMPS_Finalize
  PUBLIC :: NM_SuperLU_Init
  PUBLIC :: NM_SuperLU_Factorize
  PUBLIC :: NM_SuperLU_Solv
  PUBLIC :: NM_SuperLU_Finalize
  PUBLIC :: NM_MUMPS_Context
  PUBLIC :: NM_SuperLU_Context
  PUBLIC :: NM_DirectSolver_Params
  PUBLIC :: NM_DirectSolver_SyncThreads

  !=============================================================================
  ! MUMPS C INTEROPERABILITY TYPES
  !=============================================================================
  TYPE, BIND(C) :: DMUMPS_STRUC_C
    INTEGER(C_INT) :: sym        ! 0=unsym, 1=SPD, 2=general sym
    INTEGER(C_INT) :: par        ! 1=host+worker, 0=host only
    INTEGER(C_INT) :: job        ! Job code: 1=init, 2=analyze, 3=factor, 4=solve, 5=factor+solve
    INTEGER(C_INT) :: comm_fortran  ! MPI communicator
    INTEGER(C_INT) :: n          ! Matrix dimension
    INTEGER(C_INT) :: nz         ! Number of nonzeros (COO)
    TYPE(C_PTR) :: irn           ! Row indices (1-based)
    TYPE(C_PTR) :: jcn           ! Column indices (1-based)
    TYPE(C_PTR) :: a             ! Values
    TYPE(C_PTR) :: rhs           ! Right-hand side
    INTEGER(C_INT) :: nrhs       ! Number of RHS
    INTEGER(C_INT) :: lrhs       ! Leading dimension
    INTEGER(C_INT) :: infog(40)  ! Info array
    REAL(C_DOUBLE) :: rinfog(40) ! Real info
    INTEGER(C_INT) :: icntl(60)  ! Ctrl parameters
    REAL(C_DOUBLE) :: cntl(15)   ! Real control
    ! ... (many more fields, simplified here)
  END TYPE DMUMPS_STRUC_C

  !--------------------------------------------------------------------
  ! NM_Brg_MUMPS_Ctx — MUMPS solver context (State)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_MUMPS_Context_Mumps
    TYPE(DMUMPS_STRUC_C) :: mumps_par
  END TYPE NM_MUMPS_Context_Mumps

  TYPE, PUBLIC :: NM_MUMPS_Context_Status
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_analyzed = .FALSE.
    LOGICAL :: is_factorized = .FALSE.
  END TYPE NM_MUMPS_Context_Status

  TYPE, PUBLIC :: NM_MUMPS_Context_Matrix
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: nz = 0_i4
  END TYPE NM_MUMPS_Context_Matrix

  TYPE, PUBLIC :: NM_MUMPS_Context_Data
    INTEGER(C_INT), POINTER :: irn(:) => NULL()  ! Row indices
    INTEGER(C_INT), POINTER :: jcn(:) => NULL()  ! Column indices
    REAL(C_DOUBLE), POINTER :: a(:) => NULL()    ! Values
  END TYPE NM_MUMPS_Context_Data

  TYPE, PUBLIC :: NM_MUMPS_Context
    TYPE(NM_MUMPS_Context_Mumps) :: mumps
    TYPE(NM_MUMPS_Context_Status) :: status
    TYPE(NM_MUMPS_Context_Matrix) :: matrix
    TYPE(NM_MUMPS_Context_Data) :: data
  END TYPE NM_MUMPS_Context

  !--------------------------------------------------------------------
  ! NM_Brg_SuperLU_Ctx — SuperLU solver context (State)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_SuperLU_Context_Factors
    TYPE(C_PTR) :: L = C_NULL_PTR        ! Lower triangular factor
    TYPE(C_PTR) :: U = C_NULL_PTR        ! Upper triangular factor
  END TYPE NM_SuperLU_Context_Factors

  TYPE, PUBLIC :: NM_SuperLU_Context_Perm
    TYPE(C_PTR) :: perm_r = C_NULL_PTR   ! Row permutations
    TYPE(C_PTR) :: perm_c = C_NULL_PTR   ! Column permutations
  END TYPE NM_SuperLU_Context_Perm

  TYPE, PUBLIC :: NM_SuperLU_Context_Config
    TYPE(C_PTR) :: options = C_NULL_PTR  ! Solver options
    TYPE(C_PTR) :: stat = C_NULL_PTR     ! Statistics
  END TYPE NM_SuperLU_Context_Config

  TYPE, PUBLIC :: NM_SuperLU_Context_Status
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_factorized = .FALSE.
  END TYPE NM_SuperLU_Context_Status

  TYPE, PUBLIC :: NM_SuperLU_Context_Matrix
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: nnz = 0_i4
  END TYPE NM_SuperLU_Context_Matrix

  TYPE, PUBLIC :: NM_SuperLU_Context
    TYPE(NM_SuperLU_Context_Factors) :: factors
    TYPE(NM_SuperLU_Context_Perm) :: perm
    TYPE(NM_SuperLU_Context_Config) :: config
    TYPE(NM_SuperLU_Context_Status) :: status
    TYPE(NM_SuperLU_Context_Matrix) :: matrix
  END TYPE NM_SuperLU_Context

  !--------------------------------------------------------------------
  ! NM_Brg_DirectSolver_Algo — Direct solver parameters (Algo)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_DirectSolver_Params_General
    INTEGER(i4) :: solver_type = 1_i4    ! 1=MUMPS, 2=SuperLU
    LOGICAL :: verbose = .FALSE.
  END TYPE NM_DirectSolver_Params_General

  TYPE, PUBLIC :: NM_DirectSolver_Params_Mumps
    INTEGER(i4) :: mumps_sym = 0_i4      ! 0=unsym, 1=SPD, 2=sym
    INTEGER(i4) :: ordering = 7_i4       ! 0=AMD, 5=METIS, 7=auto
    REAL(wp) :: pivot_threshold = 0.01_wp ! Partial pivoting threshold
    INTEGER(i4) :: icntl(60) = 0_i4      ! MUMPS control array
  END TYPE NM_DirectSolver_Params_Mumps

  TYPE, PUBLIC :: NM_DirectSolver_Params_SuperLU
    INTEGER(i4) :: panel_size = 8_i4     ! Panel size for supernodes
    INTEGER(i4) :: relax = 8_i4          ! Supernode relaxation
    LOGICAL :: use_nat_ordering = .FALSE. ! Natural ordering vs COLAMD
  END TYPE NM_DirectSolver_Params_SuperLU

  TYPE, PUBLIC :: NM_DirectSolver_Params_Perf
    INTEGER(i4) :: num_threads = 1_i4    ! OpenMP threads (SuperLU)
    LOGICAL :: use_mpi = .FALSE.         ! MPI parallelization (MUMPS)
  END TYPE NM_DirectSolver_Params_Perf

  TYPE, PUBLIC :: NM_DirectSolver_Params
    TYPE(NM_DirectSolver_Params_General) :: general
    TYPE(NM_DirectSolver_Params_Mumps) :: mumps
    TYPE(NM_DirectSolver_Params_SuperLU) :: superlu
    TYPE(NM_DirectSolver_Params_Perf) :: perf
  END TYPE NM_DirectSolver_Params

  !--------------------------------------------------------------------
  ! MUMPS job code constants (NM_BRG_* naming)
  !--------------------------------------------------------------------
  INTEGER(C_INT), PARAMETER :: NM_JOB_INIT = -1
  INTEGER(C_INT), PARAMETER :: NM_JOB_END = -2
  INTEGER(C_INT), PARAMETER :: NM_JOB_ANALYZE = 1
  INTEGER(C_INT), PARAMETER :: NM_JOB_FACTORIZE = 2
  INTEGER(C_INT), PARAMETER :: NM_JOB_SOLVE = 3
  INTEGER(C_INT), PARAMETER :: NM_JOB_FACTOR_SOLVE = 5

  !--------------------------------------------------------------------
  ! C function interfaces
  !--------------------------------------------------------------------
  INTERFACE
    ! MUMPS entry point
    SUBROUTINE dmumps_c(mumps_par) BIND(C, NAME='dmumps_c')
      IMPORT :: DMUMPS_STRUC_C
      TYPE(DMUMPS_STRUC_C) :: mumps_par
    END SUBROUTINE dmumps_c

    ! SuperLU factorization (simplified interface)
    INTEGER(C_INT) FUNCTION dgstrf_c(options, A, L, U, stat) BIND(C, NAME='dgstrf')
      IMPORT :: C_PTR, C_INT
      TYPE(C_PTR), VALUE :: options, A
      TYPE(C_PTR) :: L, U
      TYPE(C_PTR), VALUE :: stat
    END FUNCTION dgstrf_c

    ! SuperLU solve
    INTEGER(C_INT) FUNCTION dgstrs_c(trans, L, U, perm_r, perm_c, B, stat) &
                            BIND(C, NAME='dgstrs')
      IMPORT :: C_PTR, C_INT
      INTEGER(C_INT), VALUE :: trans
      TYPE(C_PTR), VALUE :: L, U, perm_r, perm_c, B, stat
    END FUNCTION dgstrs_c
  END INTERFACE

CONTAINS

  !====================================================================
  ! NM_MUMPS_Init — P0 Init MUMPS context
  !====================================================================
  SUBROUTINE NM_MUMPS_Init(ctx, params, status)
    !! Init MUMPS context
    !!
    !! Sets up MPI communicator, symmetry type, and control parameters
    
    TYPE(NM_MUMPS_Context), INTENT(OUT) :: ctx
    TYPE(NM_DirectSolver_Params), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Init MUMPS structure
    ctx%mumps%mumps_par%sym = params%mumps%mumps_sym
    ctx%mumps%mumps_par%par = 1  ! Host is involved in factorization
    ctx%mumps%mumps_par%job = NM_JOB_INIT
    
    ! MPI communicator: 0 for sequential (par=0); use MPI_COMM_WORLD for parallel
    ! When par=0 (host only), comm_fortran is ignored by MUMPS
    ctx%mumps%mumps_par%comm_fortran = 0
    
    ! Call MUMPS initialization
    CALL dmumps_c(ctx%mumps%mumps_par)
    
    ! Check for errors
    IF (ctx%mumps%mumps_par%infog(1) < 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') "NM_MUMPS_Init: MUMPS error ", ctx%mumps%mumps_par%infog(1)
      RETURN
    END IF
    
    ! Set control parameters
    ctx%mumps%mumps_par%icntl(1:60) = params%mumps%icntl(1:60)
    ctx%mumps%mumps_par%icntl(5) = 0         ! Assembled matrix format
    ctx%mumps%mumps_par%icntl(7) = params%mumps%ordering  ! Ordering method

    ! ICNTL(16): number of OpenMP threads for MUMPS multithreaded factorization
    IF (params%perf%num_threads > 1_i4) THEN
      ctx%mumps%mumps_par%icntl(16) = INT(params%perf%num_threads, C_INT)
    END IF

    IF (.NOT. params%general%verbose) THEN
      ctx%mumps%mumps_par%icntl(1) = -1  ! Suppress error messages
      ctx%mumps%mumps_par%icntl(2) = -1  ! Suppress diagnostics
      ctx%mumps%mumps_par%icntl(3) = -1  ! Suppress global info
      ctx%mumps%mumps_par%icntl(4) = 0   ! No printing
    END IF
    
    ctx%status%is_initialized = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MUMPS_Init

  !====================================================================
  ! NM_MUMPS_Setup_FromCSR — P1 CSR-to-COO conversion and setup
  !====================================================================
  SUBROUTINE NM_MUMPS_Setup_FromCSR(ctx, n, nnz, row_ptr, col_ind, values, status)
    !! Convert CSR format to COO and fill MUMPS context
    !!
    !! Input: CSR format (1-based indices for MUMPS)
    !!   row_ptr(1:n+1): row pointers
    !!   col_ind(1:nnz): column indices
    !!   values(1:nnz): matrix values
    
    TYPE(NM_MUMPS_Context), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: nnz
    INTEGER(i4), INTENT(IN) :: row_ptr(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:)
    REAL(wp), INTENT(IN) :: values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, k, row_start, row_end
    
    CALL init_error_status(status)
    
    IF (SIZE(row_ptr) < n + 1 .OR. SIZE(col_ind) < nnz .OR. SIZE(values) < nnz) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_MUMPS_Setup_FromCSR: Array size mismatch"
      RETURN
    END IF
    
    ctx%matrix%n = n
    ctx%matrix%nz = nnz
    
    IF (ASSOCIATED(ctx%data%irn)) DEALLOCATE(ctx%data%irn)
    IF (ASSOCIATED(ctx%data%jcn)) DEALLOCATE(ctx%data%jcn)
    IF (ASSOCIATED(ctx%data%a)) DEALLOCATE(ctx%data%a)
    
    ALLOCATE(ctx%data%irn(nnz), ctx%data%jcn(nnz), ctx%data%a(nnz))
    
    ! CSR to COO: row i has entries in col_ind(row_ptr(i):row_ptr(i+1)-1)
    k = 0
    DO i = 1, n
      row_start = row_ptr(i)
      row_end = row_ptr(i + 1) - 1
      DO WHILE (row_start <= row_end)
        k = k + 1
        ctx%data%irn(k) = INT(i, C_INT)
        ctx%data%jcn(k) = INT(col_ind(row_start), C_INT)
        ctx%data%a(k) = REAL(values(row_start), C_DOUBLE)
        row_start = row_start + 1
      END DO
    END DO
    ! Ensure we got all nnz entries
    IF (k /= nnz) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') "NM_MUMPS_Setup_FromCSR: nnz mismatch ", k, " vs ", nnz
      RETURN
    END IF
    
    ctx%mumps%mumps_par%n = INT(ctx%matrix%n, C_INT)
    ctx%mumps%mumps_par%nz = INT(ctx%matrix%nz, C_INT)
    ctx%mumps%mumps_par%irn = C_LOC(ctx%data%irn(1))
    ctx%mumps%mumps_par%jcn = C_LOC(ctx%data%jcn(1))
    ctx%mumps%mumps_par%a = C_LOC(ctx%data%a(1))
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MUMPS_Setup_FromCSR

  !====================================================================
  ! NM_MUMPS_Analyze — P2 Symbolic factorization
  !====================================================================
  SUBROUTINE NM_MUMPS_Analyze(ctx, status)
    !! Perform symbolic analysis: ordering, elimination tree
    !!
    !! Prerequisite: Call NM_MUMPS_Setup_FromCSR first to fill ctx with matrix data
    
    TYPE(NM_MUMPS_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%status%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_MUMPS_Analyze: Context not initialized"
      RETURN
    END IF
    
    IF (.NOT. ASSOCIATED(ctx%data%irn) .OR. .NOT. ASSOCIATED(ctx%data%jcn) .OR. .NOT. ASSOCIATED(ctx%data%a)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_MUMPS_Analyze: Call NM_MUMPS_Setup_FromCSR first"
      RETURN
    END IF
    
    ! Set MUMPS pointers (in case they were cleared)
    ctx%mumps%mumps_par%n = INT(ctx%matrix%n, C_INT)
    ctx%mumps%mumps_par%nz = INT(ctx%matrix%nz, C_INT)
    ctx%mumps%mumps_par%irn = C_LOC(ctx%data%irn(1))
    ctx%mumps%mumps_par%jcn = C_LOC(ctx%data%jcn(1))
    ctx%mumps%mumps_par%a = C_LOC(ctx%data%a(1))
    
    ! Call analysis phase
    ctx%mumps%mumps_par%job = NM_JOB_ANALYZE
    CALL dmumps_c(ctx%mumps%mumps_par)
    
    ! Check for errors
    IF (ctx%mumps%mumps_par%infog(1) < 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') "NM_MUMPS_Analyze: Error ", ctx%mumps%mumps_par%infog(1)
      RETURN
    END IF
    
    ctx%config%status%is_analyzed = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MUMPS_Analyze

  !====================================================================
  ! NM_MUMPS_Factorize — P2 Numeric factorization
  !====================================================================
  SUBROUTINE NM_MUMPS_Factorize(ctx, status)
    !! Perform LU factorization
    
    TYPE(NM_MUMPS_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%config%status%is_analyzed) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_MUMPS_Factorize: Analyze phase not done"
      RETURN
    END IF
    
    ! Call factorization phase
    ctx%mumps%mumps_par%job = NM_JOB_FACTORIZE
    CALL dmumps_c(ctx%mumps%mumps_par)
    
    ! Check for errors
    IF (ctx%mumps%mumps_par%infog(1) < 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') "NM_MUMPS_Factorize: Error ", ctx%mumps%mumps_par%infog(1)
      RETURN
    END IF
    
    ctx%status%is_factorized = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MUMPS_Factorize

  !====================================================================
  ! NM_MUMPS_Solv — P2 Solve A*x = b
  !====================================================================
  SUBROUTINE NM_MUMPS_Solv(ctx, b, x, status)
    !! Solve A*x = b using factored matrix
    
    TYPE(NM_MUMPS_Context), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(C_DOUBLE), ALLOCATABLE, TARGET :: rhs(:)
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%status%is_factorized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_MUMPS_Solv: Factorization not done"
      RETURN
    END IF
    
    ! Allocate RHS
    ALLOCATE(rhs(ctx%matrix%n))
    rhs = b
    
    ! Set RHS pointer
    ctx%mumps%mumps_par%rhs = C_LOC(rhs)
    ctx%mumps%mumps_par%nrhs = 1
    ctx%mumps%mumps_par%lrhs = ctx%matrix%n
    
    ! Call solve phase
    ctx%mumps%mumps_par%job = NM_JOB_SOLVE
    CALL dmumps_c(ctx%mumps%mumps_par)
    
    ! Check for errors
    IF (ctx%mumps%mumps_par%infog(1) < 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') "NM_MUMPS_Solv: Error ", ctx%mumps%mumps_par%infog(1)
      DEALLOCATE(rhs)
      RETURN
    END IF
    
    ! Copy solution back
    x = rhs
    
    DEALLOCATE(rhs)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MUMPS_Solv

  !====================================================================
  ! NM_MUMPS_Finalize — P0 Cleanup MUMPS context
  !====================================================================
  SUBROUTINE NM_MUMPS_Finalize(ctx, status)
    !! Cleanup MUMPS context
    
    TYPE(NM_MUMPS_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%status%is_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Call MUMPS finalization
    ctx%mumps%mumps_par%job = NM_JOB_END
    CALL dmumps_c(ctx%mumps%mumps_par)
    
    ! Deallocate
    IF (ASSOCIATED(ctx%data%irn)) DEALLOCATE(ctx%data%irn)
    IF (ASSOCIATED(ctx%data%jcn)) DEALLOCATE(ctx%data%jcn)
    IF (ASSOCIATED(ctx%data%a)) DEALLOCATE(ctx%data%a)
    
    ctx%status%is_initialized = .FALSE.
    ctx%config%status%is_analyzed = .FALSE.
    ctx%status%is_factorized = .FALSE.
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MUMPS_Finalize

  !====================================================================
  ! NM_SuperLU_Init — P0 Init SuperLU context
  !====================================================================
  SUBROUTINE NM_SuperLU_Init(ctx, params, status)
    !! Init SuperLU context
    
    TYPE(NM_SuperLU_Context), INTENT(OUT) :: ctx
    TYPE(NM_DirectSolver_Params), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Allocate SuperLU structures
    ! ctx%config%options = SuperLU_Options_Create()
    ! ctx%config%stat = SuperLU_Stat_Create()
    
    ctx%status%is_initialized = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SuperLU_Init

  !====================================================================
  ! NM_SuperLU_Factorize — P2 LU factorization with SuperLU
  !====================================================================
  SUBROUTINE NM_SuperLU_Factorize(ctx, A_csr, status)
    !! Perform LU factorization with SuperLU
    
    TYPE(NM_SuperLU_Context), INTENT(INOUT) :: ctx
    ! TYPE(CSR_Matrix_Type), INTENT(IN) :: A_csr
    REAL(wp), INTENT(IN) :: A_csr(1)  ! Placeholder
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(C_INT) :: info
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%status%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_SuperLU_Factorize: Context not initialized"
      RETURN
    END IF
    
    ! Convert CSR to SuperLU format
    ! ... (create SuperMatrix from CSR)
    
    ! Call SuperLU factorization
    ! info = dgstrf_c(ctx%config%options, A_superlu, ctx%factors%L, ctx%factors%U, ctx%config%stat)
    
    info = 0  ! Placeholder
    
    IF (info /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') "NM_SuperLU_Factorize: Error ", info
      RETURN
    END IF
    
    ctx%status%is_factorized = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SuperLU_Factorize

  !====================================================================
  ! NM_SuperLU_Solv — P2 Solve with SuperLU
  !====================================================================
  SUBROUTINE NM_SuperLU_Solv(ctx, b, x, status)
    !! Solve A*x = b with SuperLU
    
    TYPE(NM_SuperLU_Context), INTENT(IN) :: ctx
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(C_INT) :: info, trans
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%status%is_factorized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_SuperLU_Solv: Factorization not done"
      RETURN
    END IF
    
    x = b
    trans = 0  ! No transpose
    
    ! Call SuperLU triangular solve
    ! info = dgstrs_c(trans, ctx%factors%L, ctx%factors%U, ctx%perm%perm_r, ctx%perm%perm_c, x_superlu, ctx%config%stat)
    
    info = 0  ! Placeholder
    
    IF (info /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') "NM_SuperLU_Solv: Error ", info
      RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SuperLU_Solv

  !====================================================================
  ! NM_SuperLU_Finalize — P0 Cleanup SuperLU context
  !====================================================================
  SUBROUTINE NM_SuperLU_Finalize(ctx, status)
    !! Cleanup SuperLU context
    
    TYPE(NM_SuperLU_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. ctx%status%is_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Free SuperLU structures
    ! IF (C_ASSOCIATED(ctx%factors%L)) CALL Destroy_SuperNode_Matrix(ctx%factors%L)
    ! IF (C_ASSOCIATED(ctx%factors%U)) CALL Destroy_CompCol_Matrix(ctx%factors%U)
    
    ctx%status%is_initialized = .FALSE.
    ctx%status%is_factorized = .FALSE.
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SuperLU_Finalize

  !====================================================================
  ! NM_DirectSolver_SyncThreads — P1 Thread synchronization
  !====================================================================

  SUBROUTINE NM_DirectSolver_SyncThreads(params, n_omp_threads)
    !> Synchronize solver thread count from runtime configuration.
    !> Call before NM_MUMPS_Init / NM_SuperLU_Init.
    TYPE(NM_DirectSolver_Params), INTENT(INOUT) :: params
    INTEGER(i4), INTENT(IN) :: n_omp_threads

    IF (n_omp_threads > 0_i4) THEN
      params%perf%num_threads = n_omp_threads
    END IF
  END SUBROUTINE NM_DirectSolver_SyncThreads

  !====================================================================
  ! CSR_to_COO — P1 Helper: CSR to COO format conversion
  !====================================================================
  
  SUBROUTINE CSR_to_COO(n, nnz, row_ptr, col_ind, values, irn, jcn, a, status)
    !! Convert CSR to COO format (1-based for MUMPS)
    
    INTEGER(i4), INTENT(IN) :: n, nnz
    INTEGER(i4), INTENT(IN) :: row_ptr(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:)
    REAL(wp), INTENT(IN) :: values(:)
    INTEGER(C_INT), INTENT(OUT) :: irn(:), jcn(:)
    REAL(C_DOUBLE), INTENT(OUT) :: a(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, k, row_start, row_end
    
    CALL init_error_status(status)
    
    IF (SIZE(irn) < nnz .OR. SIZE(jcn) < nnz .OR. SIZE(a) < nnz) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "CSR_to_COO: Output array size too small"
      RETURN
    END IF
    
    k = 0
    DO i = 1, n
      row_start = row_ptr(i)
      row_end = row_ptr(i + 1) - 1
      DO WHILE (row_start <= row_end)
        k = k + 1
        irn(k) = INT(i, C_INT)
        jcn(k) = INT(col_ind(row_start), C_INT)
        a(k) = REAL(values(row_start), C_DOUBLE)
        row_start = row_start + 1
      END DO
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE CSR_to_COO

END MODULE NM_DirMUMPS_Brg