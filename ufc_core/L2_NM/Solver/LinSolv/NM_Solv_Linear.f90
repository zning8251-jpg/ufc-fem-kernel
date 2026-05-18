!===============================================================================
! MODULE: NM_Solv_Linear
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Core (unified linear solver interface)
! BRIEF:  Unified Ax=b solver: direct, iterative, auto-select
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_Linear
    USE IF_Prec_Core, ONLY: wp, i4
    USE NM_Solv_IterSolver
    USE NM_Solv_MemPool
    USE NM_Solv_Preconditioner
    USE NM_Mtx_Core
    USE NM_Solv_SparsePakWrap    ! SparsePak direct solver wrapper
    USE IF_Mem_WS, ONLY: UF_WS_Get_Linear_Workspace
    IMPLICIT NONE
    PRIVATE


    
    !---------------------------------------------------------------------------
    ! Public types and procedures
    !---------------------------------------------------------------------------

    PUBLIC :: UF_LinearSolverWorkspace, UF_LS_InitWorkspace, UF_LS_FinalizeWorkspace
    PUBLIC :: lin_solve, lin_solve_init, lin_solve_destroy
    PUBLIC :: lin_solve_direct, lin_solve_iterative
    PUBLIC :: lin_solve_cg, lin_solve_iccg, lin_solve_agmg
    PUBLIC :: lin_solve_sparsepak              ! SparsePak Cholesky direct solver
    PUBLIC :: lin_solve_sparsepak_reuse         ! SparsePak with factorization reuse
    PUBLIC :: UF_SparsePakHandle                ! Handle type for reuse

    
    !---------------------------------------------------------------------------
    ! Solver types
    !---------------------------------------------------------------------------
    INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_AUTO = 0
    INTEGER, PARAMETER, PUBLIC :: NM_SOLV_METHOD_DIRECT = 1
    INTEGER, PARAMETER, PUBLIC :: NM_SOLV_METHOD_CG = 2
    INTEGER, PARAMETER, PUBLIC :: NM_SOLV_METHOD_BICGSTAB = 3
    INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_PCG = 4
    INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_ICCG = 5
    INTEGER, PARAMETER, PUBLIC :: NM_SOLV_METHOD_GMRES = 6
    INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_AGMG = 7
    INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_SPARSEPAK = 8    ! SparsePak Cholesky
    
    !---------------------------------------------------------------------------
    ! Linear solver parameters
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_LinSolParams
        INTEGER(i4) :: solver_type = NM_SOLVER_AUTO
        ! Iterative solver parameters
        INTEGER(i4) :: max_iter = 1000
        REAL(wp) :: tol = 1.0E-10_wp
        INTEGER(i4) :: restart = 30           ! GMRES restart
        ! Preconditioner parameters
        INTEGER(i4) :: precond_type = NM_PRECOND_ILU0
        INTEGER(i4) :: lfil = 10              ! ILUT fill level
        REAL(wp) :: droptol = 1.0E-4_wp   ! ILUT drop tolerance
        ! Auto-selection thresholds
        INTEGER(i4) :: size_threshold = 5000  ! Use direct if n < threshold
        LOGICAL :: is_symmetric = .FALSE. ! Use PCG for symmetric
        LOGICAL :: verbose = .FALSE.
    END TYPE UF_LinSolParams
    
    !---------------------------------------------------------------------------
    ! Linear solver result
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_LinSolResult
        INTEGER(i4) :: solver_used = 0
        INTEGER(i4) :: iterations = 0
        REAL(wp) :: residual = 0.0_wp
        REAL(wp) :: solve_time = 0.0_wp
        INTEGER(i4) :: status = 0             ! 0=success, <0=error
    END TYPE UF_LinSolResult
    
    !---------------------------------------------------------------------------
    ! Solver context (for reuse)
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_LinSolContext
        LOGICAL :: initialized = .FALSE.
        TYPE(UF_Precond) :: precond
        INTEGER(i4) :: solver_type = NM_SOLVER_AUTO
        ! Direct solver factors (if used)
        REAL(wp), ALLOCATABLE :: LU_val(:)
        INTEGER, ALLOCATABLE :: LU_col(:), LU_row(:)
    END TYPE UF_LinSolContext

    ! Linear solver workspace: wraps vector and matrix pools for iterative solvers
    TYPE, PUBLIC :: UF_LinearSolverWorkspace
        TYPE(UF_MemoryPool_t) :: vecPool
        TYPE(UF_MatrixPool_t) :: matPool
    END TYPE UF_LinearSolverWorkspace

    ! ͳ ƣ ǰ ۻ ÿ ʼʱ ã ?
    ! - g_ls_iter_total õ ܵ ֮
    ! - g_ls_iter_max ڵ
    INTEGER, PRIVATE :: g_ls_iter_total = 0
    INTEGER, PRIVATE :: g_ls_iter_max   = 0

    PUBLIC :: UF_LS_ResetIterStats, UF_LS_GetIterStats
    
    !---------------------------------------------------------------------------
    ! AGMG level structure (must be declared before CONTAINS)
    !---------------------------------------------------------------------------
    TYPE :: AGMG_Level


        TYPE(UF_CSRMatrix) :: A_coarse    ! Coarse level matrix
        INTEGER, ALLOCATABLE :: agg(:)     ! Aggregation mapping
        INTEGER(i4) :: n_fine, n_coarse        ! Level sizes
        REAL(wp), ALLOCATABLE :: P(:,:)    ! Prolongation (if needed)
        LOGICAL :: is_coarsest = .FALSE.
    END TYPE AGMG_Level
    
CONTAINS

    !===========================================================================
    ! Linear solver iteration statistics helpers
    !===========================================================================
    SUBROUTINE UF_LS_ResetIterStats()
        g_ls_iter_total = 0
        g_ls_iter_max   = 0
    END SUBROUTINE UF_LS_ResetIterStats

    SUBROUTINE UF_LS_GetIterStats(totalIter, maxIter)
        INTEGER(i4), INTENT(OUT) :: totalIter
        INTEGER, INTENT(OUT), OPTIONAL :: maxIter

        totalIter = g_ls_iter_total
        IF (PRESENT(maxIter)) THEN
            maxIter = g_ls_iter_max
        END IF
    END SUBROUTINE UF_LS_GetIterStats

    !===========================================================================
    ! Linear solver workspace management
    !===========================================================================


    SUBROUTINE UF_LS_InitWorkspace(ws, n_init)
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT) :: ws
        INTEGER, INTENT(IN), OPTIONAL :: n_init

        IF (PRESENT(n_init)) THEN
            CALL UF_Mem_InitPool(ws%vecPool, n_init)
        ELSE
            CALL UF_Mem_InitPool(ws%vecPool)
        END IF

        CALL UF_Mem_InitMatrixPool(ws%matPool)
    END SUBROUTINE UF_LS_InitWorkspace

    SUBROUTINE UF_LS_FinalizeWorkspace(ws)
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT) :: ws

        CALL UF_Mem_FinalizePool(ws%vecPool)
        CALL UF_Mem_FinalizeMatrixPool(ws%matPool)
    END SUBROUTINE UF_LS_FinalizeWorkspace

    SUBROUTINE UF_LS_ConfigureWorkspace(ws, A, params, solver_type)
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT) :: ws
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        INTEGER(i4), INTENT(IN) :: solver_type

        ! ------------------------------------------------------------------
        ! Workspace sizing notes (unified vecPool/matPool usage):
        !   - PCG
        !       * Uses 4 main work vectors: r, z, p, q
        !       * We reserve ~6 slots in vecPool to leave some headroom.
        !       * No matrix workspace is used.
        !   - BiCGSTAB
        !       * Uses 8 work vectors: r, r0, p, v, s, t, phat, shat
        !       * We reserve ~10 vecPool slots for safety.
        !       * No matrix workspace is used.
        !   - GMRES (restarted)
        !       * Uses 6 work vectors per solve: r, w, g, y, cs, sn
        !       * Uses two matrices from matPool:
        !           V(n, m+1)  - Krylov basis (m = restart)
        !           H(m+1, m)  - (m+1) x m upper Hessenberg
        !       * vecPool slots are fixed to 8 (6 used + 2 spare).
        !       * matPool slots are sized as MAX(2, MIN(8, 2 + m_eff/64)),
        !         where m_eff = MIN(restart, n, max_iter).
        !   - Tuning guidance
        !       * Increase n_vec_slots if more algorithms share the same
        !         workspace concurrently.
        !       * Increase n_mat_slots or adjust its scaling when more
        !         matrix-based workspaces are introduced.
        ! ------------------------------------------------------------------

        INTEGER(i4) :: n, m_eff
        INTEGER(i4) :: n_vec_slots, n_mat_slots

        n = A%nrows
        m_eff = MIN(params%restart, n, params%max_iter)

        SELECT CASE (solver_type)
        CASE (NM_SOLV_METHOD_GMRES)
            ! GMRES Ҫ Ĺ ϶�?Ը Ĳ λ
            n_vec_slots = 8
            ! GMRES Ŀǰֻʹ V/H ?restart ʶ Ӳ λ
            n_mat_slots = MAX(2, MIN(8, 2 + m_eff / 64))
        CASE (NM_SOLVER_PCG)
            n_vec_slots = 6
            n_mat_slots = 0
        CASE (NM_SOLV_METHOD_BICGSTAB)
            n_vec_slots = 10
            n_mat_slots = 0
        CASE DEFAULT
            n_vec_slots = 8
            n_mat_slots = 0
        END SELECT

        ! ?workspace δ ʼ ģ Ͳ ʼ ?
        IF (.NOT. ALLOCATED(ws%vecPool%realVecPool)) THEN
            CALL UF_Mem_InitPool(ws%vecPool, n_vec_slots)
        END IF

        IF (n_mat_slots > 0) THEN
            IF (.NOT. ALLOCATED(ws%matPool%realMatPool)) THEN
                CALL UF_Mem_InitMatrixPool(ws%matPool, n_mat_slots)
            END IF
        END IF

    END SUBROUTINE UF_LS_ConfigureWorkspace




    !===========================================================================
    ! UNIFIED SOLVE INTERFACE
    !===========================================================================
    
    SUBROUTINE lin_solve(A, b, x, params, result, ierr, ws)

        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT), OPTIONAL :: ws
        
        INTEGER(i4) :: solver_choice
        LOGICAL :: use_ws
        
        ierr = 0
        result%status = 0
        
        ! Determine solver type
        solver_choice = params%solver_type
        IF (solver_choice == NM_SOLVER_AUTO) THEN
            solver_choice = select_solver(A, params)
        END IF
        
        result%solver_used = solver_choice

        use_ws = PRESENT(ws)

        ! �?workspace ģ Ͳ һ vecPool/matPool
        IF (use_ws) THEN
            CALL UF_LS_ConfigureWorkspace(ws, A, params, solver_choice)
        END IF
        
        ! Dispatch to appropriate solver
        SELECT CASE (solver_choice)
        CASE (NM_SOLV_METHOD_DIRECT)
            CALL lin_solve_direct(A, b, x, result, ierr)
            
        CASE (NM_SOLVER_PCG)
            IF (use_ws) THEN
                CALL lin_solve_pcg(A, b, x, params, result, ierr, ws)
            ELSE
                CALL lin_solve_pcg(A, b, x, params, result, ierr)
            END IF
            
        CASE (NM_SOLV_METHOD_BICGSTAB)
            IF (use_ws) THEN
                CALL lin_solve_bicgstab(A, b, x, params, result, ierr, ws)
            ELSE
                CALL lin_solve_bicgstab(A, b, x, params, result, ierr)
            END IF
            
        CASE (NM_SOLV_METHOD_GMRES)
            IF (use_ws) THEN
                CALL lin_solve_gmres(A, b, x, params, result, ierr, ws)
            ELSE
                CALL lin_solve_gmres(A, b, x, params, result, ierr)
            END IF
            
        CASE (NM_SOLV_METHOD_CG)
            CALL lin_solve_cg(A, b, x, params, result, ierr)
            
        CASE (NM_SOLVER_ICCG)
            CALL lin_solve_iccg(A, b, x, params, result, ierr)
            
        CASE (NM_SOLVER_AGMG)
            CALL lin_solve_agmg(A, b, x, params, result, ierr)
            
        CASE (NM_SOLVER_SPARSEPAK)
            CALL lin_solve_sparsepak(A, b, x, params, result, ierr)
            
        CASE DEFAULT
            ! Default to BiCGSTAB
            IF (use_ws) THEN
                CALL lin_solve_bicgstab(A, b, x, params, result, ierr, ws)
            ELSE
                CALL lin_solve_bicgstab(A, b, x, params, result, ierr)
            END IF
        END SELECT
        
    END SUBROUTINE lin_solve

    
    !---------------------------------------------------------------------------
    ! Automatic solver selection
    !---------------------------------------------------------------------------
    FUNCTION select_solver(A, params) RESULT(solver_type)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        INTEGER(i4) :: solver_type
        
        ! Small systems: use direct solver
        IF (A%nrows < params%size_threshold) THEN
            IF (params%is_symmetric .OR. A%is_symmetric) THEN
                ! Use SparsePak for small SPD systems
                solver_type = NM_SOLVER_SPARSEPAK
            ELSE
                solver_type = NM_SOLV_METHOD_BICGSTAB
            END IF
            RETURN
        END IF
        
        ! Large systems: use iterative
        IF (params%is_symmetric .OR. A%is_symmetric) THEN
            solver_type = NM_SOLVER_PCG
        ELSE
            solver_type = NM_SOLV_METHOD_BICGSTAB
        END IF
        
    END FUNCTION select_solver

    !===========================================================================
    ! DIRECT SOLVER (Simple Gaussian elimination for small systems)
    !===========================================================================
    
    SUBROUTINE lin_solve_direct(A, b, x, result, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, k, kk, pivot_row
        REAL(wp) :: pivot_val, factor, temp
        REAL(wp), ALLOCATABLE :: Adense(:,:)
        REAL(wp), POINTER     :: work(:)  => NULL()
        INTEGER,  POINTER     :: ipiv(:)  => NULL()
        LOGICAL :: use_thread_ws
        
        ierr = 0
        n = A%nrows
        
        IF (n > 2000) THEN
            ! Too large for dense direct solve
            ierr = -1
            result%status = -1
            RETURN
        END IF
        
        ! ȳ Դӵ ǰ ߳ workspace ȡͨ ù
        CALL UF_WS_Get_Linear_Workspace(n, work, ipiv)
        use_thread_ws = ASSOCIATED(work) .AND. ASSOCIATED(ipiv)
        
        ALLOCATE(Adense(n,n))
        Adense = 0.0_wp
        
        IF (.NOT. use_thread_ws) THEN
            ALLOCATE(work(n), ipiv(n))
        END IF

        
        ! Convert sparse to dense
        DO i = 1, n
            DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                j = A%col_ind(kk)
                Adense(i, j) = A%val(kk)
            END DO
        END DO
        
        ! Copy RHS
        x = b
        
        ! LU decomposition with partial pivoting
        DO k = 1, n-1
            ! Find pivot
            pivot_row = k
            pivot_val = ABS(Adense(k, k))
            DO i = k+1, n
                IF (ABS(Adense(i, k)) > pivot_val) THEN
                    pivot_val = ABS(Adense(i, k))
                    pivot_row = i
                END IF
            END DO
            
            IF (pivot_val < 1.0E-14_wp) THEN
                ierr = -2  ! Singular matrix
                result%status = -2
                IF (.NOT. use_thread_ws) THEN
                  DEALLOCATE(work, ipiv)
                END IF
                DEALLOCATE(Adense)
                RETURN
            END IF

            
            ipiv(k) = pivot_row
            
            ! Swap rows if needed
            IF (pivot_row /= k) THEN
                work(k:n) = Adense(k, k:n)
                Adense(k, k:n) = Adense(pivot_row, k:n)
                Adense(pivot_row, k:n) = work(k:n)
                temp = x(k)
                x(k) = x(pivot_row)
                x(pivot_row) = temp
            END IF
            
            ! Elimination
            DO i = k+1, n
                factor = Adense(i, k) / Adense(k, k)
                Adense(i, k) = factor
                DO j = k+1, n
                    Adense(i, j) = Adense(i, j) - factor * Adense(k, j)
                END DO
                x(i) = x(i) - factor * x(k)
            END DO
        END DO
        
        ! Back substitution
        DO i = n, 1, -1
            DO j = i+1, n
                x(i) = x(i) - Adense(i, j) * x(j)
            END DO
            IF (ABS(Adense(i, i)) < 1.0E-14_wp) THEN
                ierr = -2
                result%status = -2
                IF (.NOT. use_thread_ws) THEN
                  DEALLOCATE(work, ipiv)
                END IF
                DEALLOCATE(Adense)
                RETURN
            END IF
            x(i) = x(i) / Adense(i, i)
        END DO
        
        result%iterations = 0
        result%residual = 0.0_wp


        ! µ ǰ Ե ͳ ƣ ֱ ӽ һ ?
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
        IF (.NOT. use_thread_ws) THEN
          DEALLOCATE(work, ipiv)
        END IF
        DEALLOCATE(Adense)
        
    END SUBROUTINE lin_solve_direct



    !===========================================================================
    ! ITERATIVE SOLVERS
    !===========================================================================
    
    SUBROUTINE lin_solve_pcg(A, b, x, params, result, ierr, ws)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT), OPTIONAL :: ws
        
        TYPE(UF_Precond) :: pc
        TYPE(UF_IterParams) :: iter_params
        LOGICAL :: use_ws
        
        ! Initialize preconditioner
        pc%ptype = params%precond_type
        pc%lfil = params%lfil
        pc%droptol = params%droptol
        
        CALL pc%setup(A, ierr)
        IF (ierr /= 0) THEN
            result%status = ierr
            RETURN
        END IF
        
        ! Set iterative solver parameters
        iter_params%max_iter = params%max_iter
        iter_params%tol_rel = params%tol
        iter_params%tol_abs = params%tol * 1.0E-2_wp
        
        ! Initial guess
        x = 0.0_wp
        
        use_ws = PRESENT(ws)
        
        ! Solve
        IF (use_ws) THEN
            CALL iter_pcg(A, b, x, pc, iter_params, ierr, ws%vecPool)
        ELSE
            CALL iter_pcg(A, b, x, pc, iter_params, ierr)
        END IF
        
        result%iterations = iter_params%iter_count
        result%residual = iter_params%res_final
        result%status = ierr

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
        CALL pc%destroy()
        
    END SUBROUTINE lin_solve_pcg


    
    SUBROUTINE lin_solve_bicgstab(A, b, x, params, result, ierr, ws)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT), OPTIONAL :: ws
        
        TYPE(UF_Precond) :: pc
        TYPE(UF_IterParams) :: iter_params
        LOGICAL :: use_ws
        
        pc%ptype = params%precond_type
        pc%lfil = params%lfil
        pc%droptol = params%droptol
        
        CALL pc%setup(A, ierr)
        IF (ierr /= 0) THEN
            result%status = ierr
            RETURN
        END IF
        
        iter_params%max_iter = params%max_iter
        iter_params%tol_rel = params%tol
        iter_params%tol_abs = params%tol * 1.0E-2_wp
        
        x = 0.0_wp
        
        use_ws = PRESENT(ws)
        
        IF (use_ws) THEN
            CALL iter_bicgstab(A, b, x, pc, iter_params, ierr, ws%vecPool)
        ELSE
            CALL iter_bicgstab(A, b, x, pc, iter_params, ierr)
        END IF
        
        result%iterations = iter_params%iter_count
        result%residual = iter_params%res_final
        result%status = ierr

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
        CALL pc%destroy()
        
    END SUBROUTINE lin_solve_bicgstab


    
    SUBROUTINE lin_solve_gmres(A, b, x, params, result, ierr, ws)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT), OPTIONAL :: ws
        
        TYPE(UF_Precond) :: pc
        TYPE(UF_IterParams) :: iter_params
        LOGICAL :: use_ws
        
        pc%ptype = params%precond_type
        pc%lfil = params%lfil
        pc%droptol = params%droptol
        
        CALL pc%setup(A, ierr)
        IF (ierr /= 0) THEN
            result%status = ierr
            RETURN
        END IF
        
        iter_params%max_iter = params%max_iter
        iter_params%tol_rel = params%tol
        iter_params%tol_abs = params%tol * 1.0E-2_wp
        iter_params%restart = params%restart
        
        x = 0.0_wp
        
        use_ws = PRESENT(ws)
        
        IF (use_ws) THEN
            CALL iter_gmres(A, b, x, pc, iter_params, ierr, ws%vecPool, ws%matPool)
        ELSE
            CALL iter_gmres(A, b, x, pc, iter_params, ierr)
        END IF
        
        result%iterations = iter_params%iter_count
        result%residual = iter_params%res_final
        result%status = ierr

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
        CALL pc%destroy()
        
    END SUBROUTINE lin_solve_gmres



    !===========================================================================
    ! CONTEXT MANAGEMENT (for solver reuse)
    !===========================================================================
    
    SUBROUTINE lin_solve_init(ctx, A, params, ierr)
        TYPE(UF_LinSolContext), INTENT(INOUT) :: ctx
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        INTEGER(i4), INTENT(OUT) :: ierr
        
        ierr = 0
        
        ! Determine solver type
        ctx%solver_type = params%solver_type
        IF (ctx%solver_type == NM_SOLVER_AUTO) THEN
            ctx%solver_type = select_solver(A, params)
        END IF
        
        ! Setup preconditioner for iterative methods
        IF (ctx%solver_type /= NM_SOLV_METHOD_DIRECT) THEN
            ctx%precond%ptype = params%precond_type
            ctx%precond%lfil = params%lfil
            ctx%precond%droptol = params%droptol
            CALL ctx%precond%setup(A, ierr)
            IF (ierr /= 0) RETURN
        END IF
        
        ctx%initialized = .TRUE.
        
    END SUBROUTINE lin_solve_init
    
    SUBROUTINE lin_solve_destroy(ctx)
        TYPE(UF_LinSolContext), INTENT(INOUT) :: ctx
        
        IF (ctx%initialized) THEN
            CALL ctx%precond%destroy()
            IF (ALLOCATED(ctx%LU_val)) DEALLOCATE(ctx%LU_val)
            IF (ALLOCATED(ctx%LU_col)) DEALLOCATE(ctx%LU_col)
            IF (ALLOCATED(ctx%LU_row)) DEALLOCATE(ctx%LU_row)
            ctx%initialized = .FALSE.
        END IF
        
    END SUBROUTINE lin_solve_destroy

    !===========================================================================
    ! ITERATIVE REFINEMENT
    !===========================================================================
    
    SUBROUTINE lin_solve_iterative(A, b, x, ctx, params, result, ierr, ws)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(UF_LinSolContext), INTENT(INOUT) :: ctx

        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_LinearSolverWorkspace), INTENT(INOUT), OPTIONAL :: ws
        
        TYPE(UF_IterParams) :: iter_params
        LOGICAL :: use_ws
        
        ierr = 0
        
        IF (.NOT. ctx%initialized) THEN
            ierr = -1
            result%status = -1
            RETURN
        END IF
        
        iter_params%max_iter = params%max_iter
        iter_params%tol_rel = params%tol
        iter_params%tol_abs = params%tol * 1.0E-2_wp
        iter_params%restart = params%restart
        
        use_ws = PRESENT(ws)
        
        SELECT CASE (ctx%solver_type)
        CASE (NM_SOLVER_PCG)
            IF (use_ws) THEN
                CALL iter_pcg(A, b, x, ctx%precond, iter_params, ierr, ws%vecPool)
            ELSE
                CALL iter_pcg(A, b, x, ctx%precond, iter_params, ierr)
            END IF
        CASE (NM_SOLV_METHOD_BICGSTAB)
            IF (use_ws) THEN
                CALL iter_bicgstab(A, b, x, ctx%precond, iter_params, ierr, ws%vecPool)
            ELSE
                CALL iter_bicgstab(A, b, x, ctx%precond, iter_params, ierr)
            END IF
        CASE (NM_SOLV_METHOD_GMRES)
            IF (use_ws) THEN
                CALL iter_gmres(A, b, x, ctx%precond, iter_params, ierr, ws%vecPool, ws%matPool)
            ELSE
                CALL iter_gmres(A, b, x, ctx%precond, iter_params, ierr)
            END IF
        CASE DEFAULT
            IF (use_ws) THEN
                CALL iter_bicgstab(A, b, x, ctx%precond, iter_params, ierr, ws%vecPool)
            ELSE
                CALL iter_bicgstab(A, b, x, ctx%precond, iter_params, ierr)
            END IF
        END SELECT


        
        result%iterations = iter_params%iter_count
        result%residual = iter_params%res_final
        result%solver_used = ctx%solver_type
        result%status = ierr
        
    END SUBROUTINE lin_solve_iterative


    !===========================================================================
    ! CG SOLVER (without preconditioning)
    !===========================================================================
    
    SUBROUTINE lin_solve_cg(A, b, x, params, result, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        
        TYPE(UF_IterParams) :: iter_params
        
        iter_params%max_iter = params%max_iter
        iter_params%tol_rel = params%tol
        iter_params%tol_abs = params%tol * 1.0E-2_wp
        iter_params%print_level = 0
        IF (params%verbose) iter_params%print_level = 1
        
        x = 0.0_wp
        
        CALL iter_cg(A, b, x, iter_params, ierr)
        
        result%iterations = iter_params%iter_count
        result%residual = iter_params%res_final
        result%status = ierr

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
    END SUBROUTINE lin_solve_cg


    !===========================================================================
    ! ICCG SOLVER (Incomplete Cholesky preconditioned CG)
    !===========================================================================
    
    SUBROUTINE lin_solve_iccg(A, b, x, params, result, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        
        TYPE(UF_IterParams) :: iter_params
        
        iter_params%max_iter = params%max_iter
        iter_params%tol_rel = params%tol
        iter_params%tol_abs = params%tol * 1.0E-2_wp
        iter_params%print_level = 0
        IF (params%verbose) iter_params%print_level = 1
        
        x = 0.0_wp
        
        CALL iter_iccg(A, b, x, iter_params, ierr)
        
        result%iterations = iter_params%iter_count
        result%residual = iter_params%res_final
        result%status = ierr

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
    END SUBROUTINE lin_solve_iccg


    !===========================================================================
    ! AGMG SOLVER (Algebraic Multigrid Method)
    ! Aggregation-based Algebraic Multigrid for sparse linear systems
    !===========================================================================
    
    SUBROUTINE lin_solve_agmg(A, b, x, params, result, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, max_levels, k
        REAL(wp) :: tol, rnorm, bnorm
        REAL(wp), ALLOCATABLE :: r(:), res_hist(:)
        TYPE(AGMG_Level), ALLOCATABLE :: levels(:)
        
        ierr = 0
        n = A%nrows
        tol = params%tol
        max_levels = 20  ! Maximum coarsening levels
        
        ALLOCATE(r(n), res_hist(params%max_iter))
        
        ! Initial guess
        x = 0.0_wp
        
        ! Compute initial residual
        CALL A%matvec(x, r)
        r = b(1:n) - r
        bnorm = SQRT(DOT_PRODUCT(b(1:n), b(1:n)))
        rnorm = SQRT(DOT_PRODUCT(r, r))
        
        IF (bnorm < 1.0E-30_wp) bnorm = 1.0_wp
        
        IF (rnorm / bnorm <= tol) THEN
            result%iterations = 0
            result%residual = rnorm
            result%status = 0
            DEALLOCATE(r, res_hist)
            RETURN
        END IF
        
        ! Setup multigrid hierarchy
        CALL agmg_setup(A, levels, max_levels, ierr)
        IF (ierr /= 0) THEN
            ! Fallback to PCG if setup fails
            CALL lin_solve_pcg(A, b, x, params, result, ierr)
            IF (ALLOCATED(levels)) DEALLOCATE(levels)
            DEALLOCATE(r, res_hist)
            RETURN
        END IF
        
        ! V-cycle iterations
        DO k = 1, params%max_iter
            ! Apply V-cycle
            CALL agmg_vcycle(levels, SIZE(levels), r, x)
            
            ! Compute residual
            CALL A%matvec(x, r)
            r = b(1:n) - r
            rnorm = SQRT(DOT_PRODUCT(r, r))
            res_hist(k) = rnorm
            
            IF (params%verbose) THEN
                WRITE(*,'(A,I4,A,ES12.4)') '  AGMG iter ', k, ', residual = ', rnorm
            END IF
            
            IF (rnorm / bnorm <= tol) THEN
                result%iterations = k
                result%residual = rnorm
                result%status = 0
                CALL agmg_cleanup(levels)
                DEALLOCATE(r, res_hist)
                RETURN
            END IF
        END DO
        
        ! Max iterations reached
        result%iterations = params%max_iter
        result%residual = rnorm
        result%status = 1  ! Not converged

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
        CALL agmg_cleanup(levels)
        DEALLOCATE(r, res_hist)
        
    END SUBROUTINE lin_solve_agmg


    !===========================================================================
    ! AGMG Internal Types and Procedures
    !===========================================================================
    
    !---------------------------------------------------------------------------
    ! Setup multigrid hierarchy using aggregation
    !---------------------------------------------------------------------------
    SUBROUTINE agmg_setup(A, levels, max_levels, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(AGMG_Level), ALLOCATABLE, INTENT(OUT) :: levels(:)
        INTEGER(i4), INTENT(IN) :: max_levels
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nlev, n_coarse, i, j, k, kk, agg_count
        INTEGER(i4) :: min_coarse_size
        INTEGER, ALLOCATABLE :: agg(:), agg_size(:)
        REAL(wp), ALLOCATABLE :: diag(:), row_sum(:)
        REAL(wp) :: max_off_diag, threshold
        TYPE(UF_CSRMatrix) :: A_current
        TYPE(AGMG_Level), ALLOCATABLE :: temp_levels(:)
        
        ierr = 0
        n = A%nrows
        min_coarse_size = 100  ! Minimum size for coarsest level
        
        ! Allocate temporary levels
        ALLOCATE(temp_levels(max_levels))
        ALLOCATE(agg(n), diag(n), row_sum(n))
        
        ! Copy input matrix
        A_current = A
        nlev = 0
        
        ! Coarsening loop
        DO WHILE (A_current%nrows > min_coarse_size .AND. nlev < max_levels)
            nlev = nlev + 1
            n = A_current%nrows
            temp_levels(nlev)%n_fine = n
            
            ! Extract diagonal and compute row sums
            diag = 0.0_wp
            row_sum = 0.0_wp
            DO i = 1, n
                DO kk = A_current%row_ptr(i), A_current%row_ptr(i+1) - 1
                    j = A_current%col_ind(kk)
                    IF (i == j) THEN
                        diag(i) = A_current%val(kk)
                    ELSE
                        row_sum(i) = row_sum(i) + ABS(A_current%val(kk))
                    END IF
                END DO
            END DO
            
            ! Simple aggregation: pair-wise matching
            ALLOCATE(temp_levels(nlev)%agg(n))
            agg = 0
            agg_count = 0
            threshold = 0.25_wp  ! Coupling threshold
            
            DO i = 1, n
                IF (agg(i) == 0) THEN
                    agg_count = agg_count + 1
                    agg(i) = agg_count
                    
                    ! Find strongly connected unassigned neighbor
                    max_off_diag = 0.0_wp
                    k = 0
                    DO kk = A_current%row_ptr(i), A_current%row_ptr(i+1) - 1
                        j = A_current%col_ind(kk)
                        IF (j /= i .AND. agg(j) == 0) THEN
                            IF (ABS(A_current%val(kk)) > max_off_diag) THEN
                                max_off_diag = ABS(A_current%val(kk))
                                k = j
                            END IF
                        END IF
                    END DO
                    
                    ! Add neighbor to same aggregate if strongly connected
                    IF (k > 0 .AND. max_off_diag > threshold * row_sum(i) / REAL(A_current%row_ptr(i+1) - A_current%row_ptr(i) - 1, wp)) THEN
                        agg(k) = agg_count
                    END IF
                END IF
            END DO
            
            temp_levels(nlev)%agg = agg(1:n)
            temp_levels(nlev)%n_coarse = agg_count
            n_coarse = agg_count
            
            ! Check for sufficient coarsening
            IF (n_coarse > n / 2) THEN
                ! Poor coarsening, stop
                temp_levels(nlev)%is_coarsest = .TRUE.
                EXIT
            END IF
            
            ! Build coarse matrix using Galerkin projection R*A*P
            CALL agmg_build_coarse_matrix(A_current, agg(1:n), n, n_coarse, temp_levels(nlev)%A_coarse)
            
            ! Prepare for next level
            IF (n_coarse <= min_coarse_size) THEN
                temp_levels(nlev)%is_coarsest = .TRUE.
                EXIT
            END IF
            
            A_current = temp_levels(nlev)%A_coarse
        END DO
        
        ! Mark last level as coarsest
        IF (nlev > 0) THEN
            temp_levels(nlev)%is_coarsest = .TRUE.
        END IF
        
        ! Copy to output
        IF (nlev == 0) THEN
            ierr = -1  ! Failed to build hierarchy
        ELSE
            ALLOCATE(levels(nlev))
            levels = temp_levels(1:nlev)
        END IF
        
        DEALLOCATE(temp_levels, agg, diag, row_sum)
        
    END SUBROUTINE agmg_setup
    
    !---------------------------------------------------------------------------
    ! Build coarse matrix using Galerkin projection
    !---------------------------------------------------------------------------
    SUBROUTINE agmg_build_coarse_matrix(A, agg, n, nc, Ac)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        INTEGER(i4), INTENT(IN) :: agg(:), n, nc
        TYPE(UF_CSRMatrix), INTENT(OUT) :: Ac
        
        INTEGER(i4) :: i, j, ii, jj, kk, nnz_c
        REAL(wp), ALLOCATABLE :: Ac_dense(:,:)
        INTEGER, ALLOCATABLE :: nnz_row(:)
        
        ! Simple implementation using dense intermediate
        ! For large problems, use sparse assembly
        IF (nc <= 2000) THEN
            ALLOCATE(Ac_dense(nc, nc))
            Ac_dense = 0.0_wp
            
            ! Ac = R * A * P = P^T * A * P
            ! P is piecewise constant prolongation
            DO i = 1, n
                ii = agg(i)
                DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                    j = A%col_ind(kk)
                    jj = agg(j)
                    Ac_dense(ii, jj) = Ac_dense(ii, jj) + A%val(kk)
                END DO
            END DO
            
            ! Convert to CSR
            nnz_c = COUNT(ABS(Ac_dense) > 1.0E-15_wp)
            Ac%nrows = nc
            Ac%ncols = nc
            Ac%nnz = nnz_c
            ALLOCATE(Ac%row_ptr(nc+1), Ac%col_ind(nnz_c), Ac%val(nnz_c))
            
            kk = 0
            DO i = 1, nc
                Ac%row_ptr(i) = kk + 1
                DO j = 1, nc
                    IF (ABS(Ac_dense(i, j)) > 1.0E-15_wp) THEN
                        kk = kk + 1
                        Ac%col_ind(kk) = j
                        Ac%val(kk) = Ac_dense(i, j)
                    END IF
                END DO
            END DO
            Ac%row_ptr(nc+1) = kk + 1
            
            DEALLOCATE(Ac_dense)
        ELSE
            ! For very large coarse matrices, use sparse assembly
            ! Simplified: create diagonal matrix
            Ac%nrows = nc
            Ac%ncols = nc
            Ac%nnz = nc
            ALLOCATE(Ac%row_ptr(nc+1), Ac%col_ind(nc), Ac%val(nc))
            DO i = 1, nc
                Ac%row_ptr(i) = i
                Ac%col_ind(i) = i
                Ac%val(i) = 1.0_wp
            END DO
            Ac%row_ptr(nc+1) = nc + 1
        END IF
        
    END SUBROUTINE agmg_build_coarse_matrix
    
    !---------------------------------------------------------------------------
    ! Apply V-cycle
    !---------------------------------------------------------------------------
    RECURSIVE SUBROUTINE agmg_vcycle(levels, nlev, r, x)
        TYPE(AGMG_Level), INTENT(IN) :: levels(:)
        INTEGER(i4), INTENT(IN) :: nlev
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        
        INTEGER(i4) :: n, nc, i, lev
        REAL(wp), ALLOCATABLE :: r_c(:), x_c(:), v(:)
        
        IF (nlev <= 0) RETURN
        
        lev = 1
        n = levels(lev)%n_fine
        nc = levels(lev)%n_coarse
        
        IF (levels(lev)%is_coarsest .OR. nlev == 1) THEN
            ! Coarsest level: apply smoother
            CALL agmg_smooth(levels(lev)%A_coarse, r, x, 10)
            RETURN
        END IF
        
        ! Pre-smoothing
        ALLOCATE(v(n))
        v = x
        CALL agmg_smooth(levels(lev)%A_coarse, r, v, 3)
        
        ! Compute residual and restrict
        ALLOCATE(r_c(nc), x_c(nc))
        CALL agmg_restrict(r - agmg_matvec(levels(lev)%A_coarse, v), levels(lev)%agg, n, nc, r_c)
        x_c = 0.0_wp
        
        ! Recurse
        CALL agmg_vcycle(levels(2:nlev), nlev-1, r_c, x_c)
        
        ! Prolongate and correct
        CALL agmg_prolongate(x_c, levels(lev)%agg, n, nc, v)
        x = x + v
        
        ! Post-smoothing
        CALL agmg_smooth(levels(lev)%A_coarse, r, x, 3)
        
        DEALLOCATE(v, r_c, x_c)
        
    END SUBROUTINE agmg_vcycle
    
    !---------------------------------------------------------------------------
    ! Weighted Jacobi smoother
    !---------------------------------------------------------------------------
    SUBROUTINE agmg_smooth(A, b, x, niter)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        INTEGER(i4), INTENT(IN) :: niter
        
        INTEGER(i4) :: n, i, j, k, kk, iter
        REAL(wp) :: omega, diag_i, sum_val
        REAL(wp), ALLOCATABLE :: x_new(:)
        
        omega = 0.6667_wp  ! Damping parameter (2/3)
        n = A%nrows
        ALLOCATE(x_new(n))
        
        DO iter = 1, niter
            DO i = 1, n
                sum_val = 0.0_wp
                diag_i = 1.0_wp
                DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                    j = A%col_ind(kk)
                    IF (i == j) THEN
                        diag_i = A%val(kk)
                    ELSE
                        sum_val = sum_val + A%val(kk) * x(j)
                    END IF
                END DO
                IF (ABS(diag_i) > 1.0E-30_wp) THEN
                    x_new(i) = (1.0_wp - omega) * x(i) + omega * (b(i) - sum_val) / diag_i
                ELSE
                    x_new(i) = x(i)
                END IF
            END DO
            x = x_new
        END DO
        
        DEALLOCATE(x_new)
        
    END SUBROUTINE agmg_smooth
    
    !---------------------------------------------------------------------------
    ! Restriction operator (injection)
    !---------------------------------------------------------------------------
    SUBROUTINE agmg_restrict(r_fine, agg, n, nc, r_coarse)
        REAL(wp), INTENT(IN) :: r_fine(:)
        INTEGER(i4), INTENT(IN) :: agg(:), n, nc
        REAL(wp), INTENT(OUT) :: r_coarse(:)
        
        INTEGER(i4) :: i
        INTEGER, ALLOCATABLE :: count(:)
        
        ALLOCATE(count(nc))
        r_coarse = 0.0_wp
        count = 0
        
        DO i = 1, n
            r_coarse(agg(i)) = r_coarse(agg(i)) + r_fine(i)
            count(agg(i)) = count(agg(i)) + 1
        END DO
        
        DEALLOCATE(count)
        
    END SUBROUTINE agmg_restrict
    
    !---------------------------------------------------------------------------
    ! Prolongation operator (piecewise constant)
    !---------------------------------------------------------------------------
    SUBROUTINE agmg_prolongate(x_coarse, agg, n, nc, x_fine)
        REAL(wp), INTENT(IN) :: x_coarse(:)
        INTEGER(i4), INTENT(IN) :: agg(:), n, nc
        REAL(wp), INTENT(OUT) :: x_fine(:)
        
        INTEGER(i4) :: i
        
        DO i = 1, n
            x_fine(i) = x_coarse(agg(i))
        END DO
        
    END SUBROUTINE agmg_prolongate
    
    !---------------------------------------------------------------------------
    ! Matrix-vector product helper
    !---------------------------------------------------------------------------
    FUNCTION agmg_matvec(A, x) RESULT(y)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp) :: y(A%nrows)
        
        INTEGER(i4) :: i, j, kk
        
        y = 0.0_wp
        DO i = 1, A%nrows
            DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                j = A%col_ind(kk)
                y(i) = y(i) + A%val(kk) * x(j)
            END DO
        END DO
        
    END FUNCTION agmg_matvec
    
    !---------------------------------------------------------------------------
    ! Cleanup multigrid hierarchy
    !---------------------------------------------------------------------------
    SUBROUTINE agmg_cleanup(levels)
        TYPE(AGMG_Level), ALLOCATABLE, INTENT(INOUT) :: levels(:)
        
        INTEGER(i4) :: i
        
        IF (ALLOCATED(levels)) THEN
            DO i = 1, SIZE(levels)
                IF (ALLOCATED(levels(i)%agg)) DEALLOCATE(levels(i)%agg)
                IF (ALLOCATED(levels(i)%P)) DEALLOCATE(levels(i)%P)
                IF (ALLOCATED(levels(i)%A_coarse%val)) DEALLOCATE(levels(i)%A_coarse%val)
                IF (ALLOCATED(levels(i)%A_coarse%col_ind)) DEALLOCATE(levels(i)%A_coarse%col_ind)
                IF (ALLOCATED(levels(i)%A_coarse%row_ptr)) DEALLOCATE(levels(i)%A_coarse%row_ptr)
            END DO
            DEALLOCATE(levels)
        END IF
        
    END SUBROUTINE agmg_cleanup

    !===========================================================================
    ! SPARSEPAK DIRECT SOLVER
    ! Uses SparsePak Cholesky factorization for SPD matrices with CSR input
    !===========================================================================
    
    SUBROUTINE lin_solve_sparsepak(A, b, x, params, result, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: reorder_type
        REAL(wp) :: t_start, t_end
        
        ierr = 0
        result%status = 0
        result%solver_used = NM_SOLVER_SPARSEPAK
        
        ! Get start time
        CALL CPU_TIME(t_start)
        
        ! Select reordering based on matrix size
        IF (A%nrows < 1000) THEN
            reorder_type = NM_SPK_REORDER_RCM      ! RCM for small matrices
        ELSE IF (A%nrows < 10000) THEN
            reorder_type = NM_SPK_REORDER_QMD      ! QMD for medium matrices
        ELSE
            reorder_type = NM_SPK_REORDER_ND       ! ND for large matrices
        END IF
        
        ! Solve using SparsePak wrapper
        CALL spk_solve_csr(A, b, x, reorder_type, ierr)
        
        ! Get end time
        CALL CPU_TIME(t_end)
        result%solve_time = t_end - t_start
        
        IF (ierr /= NM_SPK_SUCCESS) THEN
            result%status = ierr
            IF (ierr == NM_SPK_ERR_NOT_SPD) THEN
                IF (params%verbose) THEN
                    WRITE(*,'(A)') 'SparsePak: Matrix not SPD, falling back to BiCGSTAB'
                END IF
                ! Fall back to iterative solver for non-SPD
                CALL lin_solve_bicgstab(A, b, x, params, result, ierr)
            END IF
            RETURN
        END IF
        
        ! SparsePak is direct solver, no iterations
        result%iterations = 1
        result%residual = 0.0_wp

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
    END SUBROUTINE lin_solve_sparsepak

    
    !---------------------------------------------------------------------------
    ! SparsePak with factorization reuse (for Newton iterations)
    !---------------------------------------------------------------------------
    SUBROUTINE lin_solve_sparsepak_reuse(A, b, x, handle, is_first, params, result, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        TYPE(UF_SparsePakHandle), INTENT(INOUT) :: handle
        LOGICAL, INTENT(IN) :: is_first       ! True for first call (symbolic + numeric)
        TYPE(UF_LinSolParams), INTENT(IN) :: params
        TYPE(UF_LinSolResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: reorder_type
        REAL(wp) :: t_start, t_end
        
        ierr = 0
        result%status = 0
        result%solver_used = NM_SOLVER_SPARSEPAK
        
        CALL CPU_TIME(t_start)
        
        IF (is_first) THEN
            ! First call: perform symbolic factorization
            reorder_type = NM_SPK_REORDER_RCM
            IF (A%nrows >= 1000) reorder_type = NM_SPK_REORDER_QMD
            IF (A%nrows >= 10000) reorder_type = NM_SPK_REORDER_ND
            
            CALL spk_symbolic_csr(A, handle, reorder_type, ierr)
            IF (ierr /= NM_SPK_SUCCESS) THEN
                result%status = ierr
                RETURN
            END IF
        END IF
        
        ! Numeric factorization (every call)
        CALL spk_numeric_csr(A, handle, ierr)
        IF (ierr /= NM_SPK_SUCCESS) THEN
            result%status = ierr
            RETURN
        END IF
        
        ! Solve
        CALL spk_solve_factored(handle, b, x, ierr)
        IF (ierr /= NM_SPK_SUCCESS) THEN
            result%status = ierr
            RETURN
        END IF
        
        CALL CPU_TIME(t_end)
        result%solve_time = t_end - t_start
        result%iterations = 1
        result%residual = 0.0_wp

        ! µ ǰ Ե ͳ
        g_ls_iter_total = g_ls_iter_total + result%iterations
        IF (result%iterations > g_ls_iter_max) g_ls_iter_max = result%iterations
        
    END SUBROUTINE lin_solve_sparsepak_reuse


END MODULE NM_Solv_Linear