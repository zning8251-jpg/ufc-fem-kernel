!===============================================================================
! MODULE: NM_Solv_IterSolver
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (Krylov iterative solvers: PCG, BiCGSTAB, GMRES)
! BRIEF:  Iterative linear solvers with preconditioning support
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_IterSolver
    USE IF_Prec_Core, ONLY: wp, i4
    USE NM_Solv_MemPool
    USE NM_Solv_Preconditioner
    USE NM_Mtx_Core
    IMPLICIT NONE
    PRIVATE
    
    !---------------------------------------------------------------------------
    ! Public procedures
    !---------------------------------------------------------------------------
    PUBLIC :: iter_pcg, iter_bicgstab, iter_gmres
    PUBLIC :: iter_cg, iter_iccg
    PUBLIC :: UF_IterParams
    
    !---------------------------------------------------------------------------
    ! Solver status codes
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: NM_ITER_SUCCESS = 0
    INTEGER(i4), PARAMETER, PUBLIC :: NM_ITER_MAX_ITER = 1
    INTEGER(i4), PARAMETER, PUBLIC :: NM_ITER_BREAKDOWN = -1
    INTEGER(i4), PARAMETER, PUBLIC :: NM_ITER_DIVERGE = -2
    INTEGER(i4), PARAMETER, PUBLIC :: NM_ITER_STAGNATE = -3
    
    !---------------------------------------------------------------------------
    ! Constants
    !---------------------------------------------------------------------------
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    REAL(wp), PARAMETER :: SMALL = 1.0E-30_wp
    
    !---------------------------------------------------------------------------
    ! Iteration parameters
    !---------------------------------------------------------------------------
    TYPE :: UF_IterParams
        INTEGER(i4) :: max_iter = 1000      ! Maximum iterations
        REAL(wp) :: tol_rel = 1.0E-6_wp     ! Relative tolerance
        REAL(wp) :: tol_abs = 1.0E-12_wp    ! Absolute tolerance
        INTEGER(i4) :: restart = 30         ! GMRES restart parameter
        INTEGER(i4) :: print_level = 0      ! 0=silent, 1=final, 2=each iter
        ! Output
        INTEGER(i4) :: iter_count = 0       ! Actual iterations
        REAL(wp) :: res_init = ZERO         ! Initial residual norm
        REAL(wp) :: res_final = ZERO        ! Final residual norm
    END TYPE UF_IterParams

CONTAINS

    SUBROUTINE givens_rotation(a, b, c, s)
        REAL(wp), INTENT(IN) :: a, b
        REAL(wp), INTENT(OUT) :: c, s
        
        REAL(wp) :: t, r
        
        IF (ABS(b) < SMALL) THEN
            c = ONE
            s = ZERO
        ELSE IF (ABS(b) > ABS(a)) THEN
            t = a / b
            r = SQRT(ONE + t*t)
            s = ONE / r
            c = t * s
        ELSE
            t = b / a
            r = SQRT(ONE + t*t)
            c = ONE / r
            s = t * c
        END IF
        
    END SUBROUTINE givens_rotation

    SUBROUTINE iter_bicgstab(mat, b, x, pc, params, ierr, pool)
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_IterParams), INTENT(INOUT) :: params
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_MemoryPool_t), INTENT(INOUT), OPTIONAL :: pool
        
        INTEGER(i4) :: n, k
        REAL(wp) :: alpha, beta, omega, rho, rho_old
        REAL(wp) :: bnorm, rnorm, tol
        TYPE(UF_WorkVec_r) :: w_r, w_r0, w_p, w_v, w_s, w_t, w_phat, w_shat
        REAL(wp), POINTER :: r(:) => NULL(), r0(:) => NULL(), p(:) => NULL(), v(:) => NULL(), &
                          s(:) => NULL(), t(:) => NULL(), phat(:) => NULL(), shat(:) => NULL()
        LOGICAL :: use_pool
        
        ierr = NM_ITER_SUCCESS
        n = mat%nrows
        
        use_pool = PRESENT(pool)
        IF (use_pool) THEN
            CALL UF_Mem_GetRealVec(pool, n, w_r)
            CALL UF_Mem_GetRealVec(pool, n, w_r0)
            CALL UF_Mem_GetRealVec(pool, n, w_p)
            CALL UF_Mem_GetRealVec(pool, n, w_v)
            CALL UF_Mem_GetRealVec(pool, n, w_s)
            CALL UF_Mem_GetRealVec(pool, n, w_t)
            CALL UF_Mem_GetRealVec(pool, n, w_phat)
            CALL UF_Mem_GetRealVec(pool, n, w_shat)

            r    => w_r%p(1:n)
            r0   => w_r0%p(1:n)
            p    => w_p%p(1:n)
            v    => w_v%p(1:n)
            s    => w_s%p(1:n)
            t    => w_t%p(1:n)
            phat => w_phat%p(1:n)
            shat => w_shat%p(1:n)
        ELSE
            ALLOCATE(r(n), r0(n), p(n), v(n), s(n), t(n), phat(n), shat(n))
        END IF
        
        ! Initial residual: r = b - A*x
        CALL mat%matvec(x, r)
        r = b(1:n) - r
        r0 = r
        
        ! Compute initial residual norm
        bnorm = vec_norm2(n, b)
        rnorm = vec_norm2(n, r)
        params%res_init = rnorm
        
        IF (bnorm < SMALL) bnorm = ONE
        tol = MAX(params%tol_rel * bnorm, params%tol_abs)
        
        IF (rnorm <= tol) THEN
            params%iter_count = 0
            params%res_final = rnorm
            DEALLOCATE(r, r0, p, v, s, t, phat, shat)
            RETURN
        END IF
        
        ! Initialize
        rho = ONE
        alpha = ONE
        omega = ONE
        v = ZERO
        p = ZERO
        
        ! BiCGSTAB iterations
        DO k = 1, params%max_iter
            rho_old = rho
            rho = vec_dot(n, r0, r)
            
            IF (ABS(rho) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            
            ! beta = (rho / rho_old) * (alpha / omega)
            beta = (rho / rho_old) * (alpha / omega)
            
            ! p = r + beta * (p - omega * v)
            p = r + beta * (p - omega * v)
            
            ! Apply preconditioner: phat = M^(-1) * p
            CALL precond_apply(pc, p, phat)
            
            ! v = A * phat
            CALL mat%matvec(phat, v)
            
            ! alpha = rho / (r0, v)
            alpha = vec_dot(n, r0, v)
            IF (ABS(alpha) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            alpha = rho / alpha
            
            ! s = r - alpha * v
            s = r - alpha * v
            
            ! Early convergence check
            rnorm = vec_norm2(n, s)
            IF (rnorm <= tol) THEN
                x = x + alpha * phat
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_SUCCESS
                EXIT
            END IF
            
            ! Apply preconditioner: shat = M^(-1) * s
            CALL precond_apply(pc, s, shat)
            
            ! t = A * shat
            CALL mat%matvec(shat, t)
            
            ! omega = (t, s) / (t, t)
            omega = vec_dot(n, t, t)
            IF (ABS(omega) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            omega = vec_dot(n, t, s) / omega
            
            ! x = x + alpha * phat + omega * shat
            x = x + alpha * phat + omega * shat
            
            ! r = s - omega * t
            r = s - omega * t
            
            ! Check convergence
            rnorm = vec_norm2(n, r)
            
            IF (params%print_level >= 2) THEN
                WRITE(*,'(A,I6,A,ES12.4)') '  BiCGSTAB iter ', k, ', residual = ', rnorm
            END IF
            
            IF (rnorm <= tol) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_SUCCESS
                EXIT
            END IF
            
            IF (ABS(omega) < SMALL) THEN
                ierr = NM_ITER_STAGNATE
                EXIT
            END IF
            
            IF (k == params%max_iter) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_MAX_ITER
            END IF
        END DO
        
        IF (params%print_level >= 1) THEN
            WRITE(*,'(A,I6,A,ES12.4,A,ES12.4)') &
                '  BiCGSTAB converged in ', params%iter_count, &
                ' iterations, res = ', params%res_final, &
                ', reduction = ', params%res_final / MAX(params%res_init, SMALL)
        END IF
        
        IF (ASSOCIATED(r)) THEN
            IF (use_pool) THEN
                CALL UF_Mem_ReleaseRealVec(pool, w_r)
                CALL UF_Mem_ReleaseRealVec(pool, w_r0)
                CALL UF_Mem_ReleaseRealVec(pool, w_p)
                CALL UF_Mem_ReleaseRealVec(pool, w_v)
                CALL UF_Mem_ReleaseRealVec(pool, w_s)
                CALL UF_Mem_ReleaseRealVec(pool, w_t)
                CALL UF_Mem_ReleaseRealVec(pool, w_phat)
                CALL UF_Mem_ReleaseRealVec(pool, w_shat)
            ELSE
                DEALLOCATE(r, r0, p, v, s, t, phat, shat)
            END IF
        END IF
        
    END SUBROUTINE iter_bicgstab

    SUBROUTINE iter_cg(mat, b, x, params, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(UF_IterParams), INTENT(INOUT) :: params
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, k
        REAL(wp) :: alpha, beta, rho, rho_old, bnorm, rnorm, tol, pAp
        REAL(wp), ALLOCATABLE :: r(:), p(:), Ap(:)
        
        ierr = NM_ITER_SUCCESS
        n = mat%nrows
        
        ALLOCATE(r(n), p(n), Ap(n))
        
        ! Initial residual: r = b - A*x
        CALL mat%matvec(x, r)
        r = b(1:n) - r
        
        ! Compute initial residual norm
        bnorm = vec_norm2(n, b)
        rnorm = vec_norm2(n, r)
        params%res_init = rnorm
        
        IF (bnorm < SMALL) bnorm = ONE
        tol = MAX(params%tol_rel * bnorm, params%tol_abs)
        
        IF (rnorm <= tol) THEN
            params%iter_count = 0
            params%res_final = rnorm
            DEALLOCATE(r, p, Ap)
            RETURN
        END IF
        
        ! Initialize: p = r, rho = r^T * r
        p = r
        rho = vec_dot(n, r, r)
        
        ! CG iterations
        DO k = 1, params%max_iter
            ! Ap = A * p
            CALL mat%matvec(p, Ap)
            
            ! alpha = rho / (p^T * A * p)
            pAp = vec_dot(n, p, Ap)
            IF (ABS(pAp) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            alpha = rho / pAp
            
            ! x = x + alpha * p
            CALL vec_axpy(n, alpha, p, x)
            
            ! r = r - alpha * Ap
            CALL vec_axpy(n, -alpha, Ap, r)
            
            ! Check convergence
            rnorm = vec_norm2(n, r)
            
            IF (params%print_level >= 2) THEN
                WRITE(*,'(A,I6,A,ES12.4)') '  CG iter ', k, ', residual = ', rnorm
            END IF
            
            IF (rnorm <= tol) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_SUCCESS
                EXIT
            END IF
            
            ! beta = rho_new / rho_old
            rho_old = rho
            rho = vec_dot(n, r, r)
            
            IF (ABS(rho_old) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            beta = rho / rho_old
            
            ! p = r + beta * p
            p = r + beta * p
            
            IF (k == params%max_iter) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_MAX_ITER
            END IF
        END DO
        
        IF (params%print_level >= 1) THEN
            WRITE(*,'(A,I6,A,ES12.4,A,ES12.4)') &
                '  CG converged in ', params%iter_count, &
                ' iterations, res = ', params%res_final, &
                ', reduction = ', params%res_final / MAX(params%res_init, SMALL)
        END IF
        
        DEALLOCATE(r, p, Ap)
        
    END SUBROUTINE iter_cg

    SUBROUTINE iter_gmres(mat, b, x, pc, params, ierr, pool, matPool)
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_IterParams), INTENT(INOUT) :: params
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_MemoryPool_t), INTENT(INOUT), OPTIONAL :: pool
        TYPE(UF_MatrixPool_t), INTENT(INOUT), OPTIONAL :: matPool
        
        INTEGER(i4) :: n, m, k, i, j, iter_total
        REAL(wp) :: bnorm, rnorm, tol, temp, c, s
        TYPE(UF_WorkMat_r) :: w_V, w_H
        TYPE(UF_WorkVec_r) :: w_g, w_y, w_r, w_w, w_cs, w_sn
        REAL(wp), POINTER :: V(:,:) => NULL(), H(:,:) => NULL()
        REAL(wp), POINTER :: g(:) => NULL(), y(:) => NULL(), r(:) => NULL(), w(:) => NULL()
        REAL(wp), POINTER :: cs(:) => NULL(), sn(:) => NULL()
        LOGICAL :: use_vecPool, use_matPool
        
        ierr = NM_ITER_SUCCESS
        n = mat%nrows
        m = MIN(params%restart, n, params%max_iter)
        
        use_vecPool = PRESENT(pool)
        use_matPool = PRESENT(matPool)
        
        IF (use_matPool) THEN
            CALL UF_Mem_GetRealMat(matPool, n, m+1, w_V)
            CALL UF_Mem_GetRealMat(matPool, m+1, m, w_H)
            V => w_V%p(1:n, 1:m+1)
            H => w_H%p(1:m+1, 1:m)
        ELSE
            ALLOCATE(V(n, m+1), H(m+1, m))
        END IF
        
        IF (use_vecPool) THEN
            CALL UF_Mem_GetRealVec(pool, m+1, w_g)
            CALL UF_Mem_GetRealVec(pool, m+1, w_y)
            CALL UF_Mem_GetRealVec(pool, n,   w_r)
            CALL UF_Mem_GetRealVec(pool, n,   w_w)
            CALL UF_Mem_GetRealVec(pool, m,   w_cs)
            CALL UF_Mem_GetRealVec(pool, m,   w_sn)
            
            g  => w_g%p(1:m+1)
            y  => w_y%p(1:m+1)
            r  => w_r%p(1:n)
            w  => w_w%p(1:n)
            cs => w_cs%p(1:m)
            sn => w_sn%p(1:m)
        ELSE
            ALLOCATE(V, H)
            ALLOCATE(g(m+1), y(m+1), r(n), w(n), cs(m), sn(m))
        END IF
        
        ! Compute initial residual
        CALL mat%matvec(x, r)
        r = b(1:n) - r
        
        bnorm = vec_norm2(n, b)
        rnorm = vec_norm2(n, r)
        params%res_init = rnorm
        
        IF (bnorm < SMALL) bnorm = ONE
        tol = MAX(params%tol_rel * bnorm, params%tol_abs)
        
        iter_total = 0
        
        ! Outer iteration (restart loop)
        DO WHILE (rnorm > tol .AND. iter_total < params%max_iter)
            ! Apply preconditioner to initial residual
            CALL precond_apply(pc, r, w)
            rnorm = vec_norm2(n, w)
            
            IF (rnorm < SMALL) EXIT
            
            V(:,1) = w / rnorm
            g = ZERO
            g(1) = rnorm
            H = ZERO
            
            ! Inner iteration (Arnoldi process)
            DO k = 1, m
                iter_total = iter_total + 1
                
                ! w = A * M^(-1) * v_k
                CALL mat%matvec(V(:,k), r)
                CALL precond_apply(pc, r, w)
                
                ! Modified Gram-Schmidt orthogonalization
                DO j = 1, k
                    H(j,k) = vec_dot(n, w, V(:,j))
                    w = w - H(j,k) * V(:,j)
                END DO
                
                H(k+1,k) = vec_norm2(n, w)
                
                IF (ABS(H(k+1,k)) > SMALL) THEN
                    V(:,k+1) = w / H(k+1,k)
                END IF
                
                ! Apply previous Givens rotations
                DO j = 1, k-1
                    temp = cs(j) * H(j,k) + sn(j) * H(j+1,k)
                    H(j+1,k) = -sn(j) * H(j,k) + cs(j) * H(j+1,k)
                    H(j,k) = temp
                END DO
                
                ! Generate new Givens rotation
                CALL givens_rotation(H(k,k), H(k+1,k), c, s)
                cs(k) = c
                sn(k) = s
                
                H(k,k) = c * H(k,k) + s * H(k+1,k)
                H(k+1,k) = ZERO
                
                ! Update g
                temp = c * g(k) + s * g(k+1)
                g(k+1) = -s * g(k) + c * g(k+1)
                g(k) = temp
                
                rnorm = ABS(g(k+1))
                
                IF (params%print_level >= 2) THEN
                    WRITE(*,'(A,I6,A,ES12.4)') '  GMRES iter ', iter_total, ', residual = ', rnorm
                END IF
                
                IF (rnorm <= tol .OR. iter_total >= params%max_iter) EXIT
            END DO
            
            ! Solve upper triangular system H*y = g
            DO i = MIN(k, m), 1, -1
                y(i) = g(i)
                DO j = i+1, MIN(k, m)
                    y(i) = y(i) - H(i,j) * y(j)
                END DO
                IF (ABS(H(i,i)) > SMALL) THEN
                    y(i) = y(i) / H(i,i)
                END IF
            END DO
            
            ! Update solution: x = x + V * y
            DO i = 1, MIN(k, m)
                x = x + y(i) * V(:,i)
            END DO
            
            ! Compute new residual for restart
            IF (rnorm > tol .AND. iter_total < params%max_iter) THEN
                CALL mat%matvec(x, r)
                r = b(1:n) - r
                rnorm = vec_norm2(n, r)
            END IF
        END DO
        
        params%iter_count = iter_total
        params%res_final = rnorm
        
        IF (rnorm <= tol) THEN
            ierr = NM_ITER_SUCCESS
        ELSE IF (iter_total >= params%max_iter) THEN
            ierr = NM_ITER_MAX_ITER
        END IF
        
        IF (params%print_level >= 1) THEN
            WRITE(*,'(A,I6,A,ES12.4,A,ES12.4)') &
                '  GMRES converged in ', params%iter_count, &
                ' iterations, res = ', params%res_final, &
                ', reduction = ', params%res_final / MAX(params%res_init, SMALL)
        END IF
        
        IF (ASSOCIATED(V)) THEN
            IF (use_matPool) THEN
                CALL UF_Mem_ReleaseRealMat(matPool, w_V)
                CALL UF_Mem_ReleaseRealMat(matPool, w_H)
            ELSE
                DEALLOCATE(V, H)
            END IF
        END IF
        
        IF (ASSOCIATED(g)) THEN
            IF (use_vecPool) THEN
                CALL UF_Mem_ReleaseRealVec(pool, w_g)
                CALL UF_Mem_ReleaseRealVec(pool, w_y)
                CALL UF_Mem_ReleaseRealVec(pool, w_r)
                CALL UF_Mem_ReleaseRealVec(pool, w_w)
                CALL UF_Mem_ReleaseRealVec(pool, w_cs)
                CALL UF_Mem_ReleaseRealVec(pool, w_sn)
            ELSE
                DEALLOCATE(g, y, r, w, cs, sn)
            END IF
        END IF
        
    END SUBROUTINE iter_gmres

    SUBROUTINE iter_iccg(mat, b, x, params, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(UF_IterParams), INTENT(INOUT) :: params
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, k, i, j, kk, jj
        REAL(wp) :: alpha, beta, rho, rho_old, bnorm, rnorm, tol, pAp
        REAL(wp) :: sum_val, diag_val
        REAL(wp), ALLOCATABLE :: r(:), z(:), p(:), Ap(:)
        REAL(wp), ALLOCATABLE :: L_diag(:), L_val(:)
        INTEGER(i4), ALLOCATABLE :: L_col(:), L_row(:)
        INTEGER(i4) :: nnz_L
        
        ierr = NM_ITER_SUCCESS
        n = mat%nrows
        
        ALLOCATE(r(n), z(n), p(n), Ap(n), L_diag(n))
        
        ! =========================================================
        ! Step 1: Compute IC(0) factorization - Only diagonal part
        ! L * L^T â ?A, where L has same sparsity as lower(A)
        ! Simplified: Store only diagonal of L for efficiency
        ! =========================================================
        L_diag = ZERO
        
        DO i = 1, n
            sum_val = ZERO
            diag_val = ZERO
            
            ! Get diagonal element of A
            DO kk = mat%row_ptr(i), mat%row_ptr(i+1) - 1
                j = mat%col_ind(kk)
                IF (j == i) THEN
                    diag_val = mat%val(kk)
                ELSE IF (j < i) THEN
                    ! Contribution from L_{ij}^2
                    IF (L_diag(j) > SMALL) THEN
                        sum_val = sum_val + (mat%val(kk) / L_diag(j))**2
                    END IF
                END IF
            END DO
            
            ! L_{ii} = sqrt(A_{ii} - sum_{k<i} L_{ik}^2)
            L_diag(i) = SQRT(MAX(diag_val - sum_val, SMALL))
        END DO
        
        ! =========================================================
        ! Step 2: Initial residual: r = b - A*x
        ! =========================================================
        CALL mat%matvec(x, r)
        r = b(1:n) - r
        
        bnorm = vec_norm2(n, b)
        rnorm = vec_norm2(n, r)
        params%res_init = rnorm
        
        IF (bnorm < SMALL) bnorm = ONE
        tol = MAX(params%tol_rel * bnorm, params%tol_abs)
        
        IF (rnorm <= tol) THEN
            params%iter_count = 0
            params%res_final = rnorm
            DEALLOCATE(r, z, p, Ap, L_diag)
            RETURN
        END IF
        
        ! =========================================================
        ! Step 3: Apply preconditioner: z = M^(-1) * r
        ! M = L * L^T, solve L*L^T*z = r
        ! Simplified: Use diagonal scaling M = diag(L)^2
        ! =========================================================
        DO i = 1, n
            z(i) = r(i) / (L_diag(i) * L_diag(i))
        END DO
        
        ! Initialize
        p = z
        rho = vec_dot(n, r, z)
        
        ! =========================================================
        ! Step 4: ICCG iterations
        ! =========================================================
        DO k = 1, params%max_iter
            ! Ap = A * p
            CALL mat%matvec(p, Ap)
            
            ! alpha = rho / (p^T * A * p)
            pAp = vec_dot(n, p, Ap)
            IF (ABS(pAp) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            alpha = rho / pAp
            
            ! x = x + alpha * p
            CALL vec_axpy(n, alpha, p, x)
            
            ! r = r - alpha * Ap
            CALL vec_axpy(n, -alpha, Ap, r)
            
            ! Check convergence
            rnorm = vec_norm2(n, r)
            
            IF (params%print_level >= 2) THEN
                WRITE(*,'(A,I6,A,ES12.4)') '  ICCG iter ', k, ', residual = ', rnorm
            END IF
            
            IF (rnorm <= tol) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_SUCCESS
                EXIT
            END IF
            
            ! Apply preconditioner: z = M^(-1) * r
            DO i = 1, n
                z(i) = r(i) / (L_diag(i) * L_diag(i))
            END DO
            
            ! beta = rho_new / rho_old
            rho_old = rho
            rho = vec_dot(n, r, z)
            
            IF (ABS(rho_old) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            beta = rho / rho_old
            
            ! p = z + beta * p
            p = z + beta * p
            
            IF (k == params%max_iter) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_MAX_ITER
            END IF
        END DO
        
        IF (params%print_level >= 1) THEN
            WRITE(*,'(A,I6,A,ES12.4,A,ES12.4)') &
                '  ICCG converged in ', params%iter_count, &
                ' iterations, res = ', params%res_final, &
                ', reduction = ', params%res_final / MAX(params%res_init, SMALL)
        END IF
        
        DEALLOCATE(r, z, p, Ap, L_diag)
        
    END SUBROUTINE iter_iccg

    SUBROUTINE iter_pcg(mat, b, x, pc, params, ierr, pool)
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_IterParams), INTENT(INOUT) :: params
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_MemoryPool_t), INTENT(INOUT), OPTIONAL :: pool
        
        INTEGER(i4) :: n, k
        REAL(wp) :: alpha, beta, rho, rho_old, bnorm, rnorm, tol
        TYPE(UF_WorkVec_r) :: w_r, w_z, w_p, w_q
        REAL(wp), POINTER :: r(:) => NULL(), z(:) => NULL(), p(:) => NULL(), q(:) => NULL()
        LOGICAL :: use_pool
        
        ierr = NM_ITER_SUCCESS
        n = mat%nrows
        
        use_pool = PRESENT(pool)
        IF (use_pool) THEN
            CALL UF_Mem_GetRealVec(pool, n, w_r)
            CALL UF_Mem_GetRealVec(pool, n, w_z)
            CALL UF_Mem_GetRealVec(pool, n, w_p)
            CALL UF_Mem_GetRealVec(pool, n, w_q)

            r => w_r%p(1:n)
            z => w_z%p(1:n)
            p => w_p%p(1:n)
            q => w_q%p(1:n)
        ELSE
            ALLOCATE(r(n), z(n), p(n), q(n))
        END IF
        
        ! Initial residual: r = b - A*x
        CALL mat%matvec(x, r)
        r = b(1:n) - r
        
        ! Compute initial residual norm
        bnorm = vec_norm2(n, b)
        rnorm = vec_norm2(n, r)
        params%res_init = rnorm
        
        IF (bnorm < SMALL) bnorm = ONE
        tol = MAX(params%tol_rel * bnorm, params%tol_abs)
        
        IF (rnorm <= tol) THEN
            params%iter_count = 0
            params%res_final = rnorm
            DEALLOCATE(r, z, p, q)
            RETURN
        END IF
        
        ! Apply preconditioner: z = M^(-1) * r
        CALL precond_apply(pc, r, z)
        
        ! Initialize
        p = z
        rho = vec_dot(n, r, z)
        
        ! CG iterations
        DO k = 1, params%max_iter
            ! q = A * p
            CALL mat%matvec(p, q)
            
            ! alpha = rho / (p^T * q)
            alpha = vec_dot(n, p, q)
            IF (ABS(alpha) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            alpha = rho / alpha
            
            ! x = x + alpha * p
            CALL vec_axpy(n, alpha, p, x)
            
            ! r = r - alpha * q
            CALL vec_axpy(n, -alpha, q, r)
            
            ! Check convergence
            rnorm = vec_norm2(n, r)
            
            IF (params%print_level >= 2) THEN
                WRITE(*,'(A,I6,A,ES12.4)') '  PCG iter ', k, ', residual = ', rnorm
            END IF
            
            IF (rnorm <= tol) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_SUCCESS
                EXIT
            END IF
            
            ! Apply preconditioner: z = M^(-1) * r
            CALL precond_apply(pc, r, z)
            
            ! beta = rho_new / rho_old
            rho_old = rho
            rho = vec_dot(n, r, z)
            
            IF (ABS(rho_old) < SMALL) THEN
                ierr = NM_ITER_BREAKDOWN
                EXIT
            END IF
            beta = rho / rho_old
            
            ! p = z + beta * p
            p = z + beta * p
            
            IF (k == params%max_iter) THEN
                params%iter_count = k
                params%res_final = rnorm
                ierr = NM_ITER_MAX_ITER
            END IF
        END DO
        
        IF (params%print_level >= 1) THEN
            WRITE(*,'(A,I6,A,ES12.4,A,ES12.4)') &
                '  PCG converged in ', params%iter_count, &
                ' iterations, res = ', params%res_final, &
                ', reduction = ', params%res_final / MAX(params%res_init, SMALL)
        END IF
        
        IF (ASSOCIATED(r)) THEN
            IF (use_pool) THEN
                CALL UF_Mem_ReleaseRealVec(pool, w_r)
                CALL UF_Mem_ReleaseRealVec(pool, w_z)
                CALL UF_Mem_ReleaseRealVec(pool, w_p)
                CALL UF_Mem_ReleaseRealVec(pool, w_q)
            ELSE
                DEALLOCATE(r, z, p, q)
            END IF
        END IF
        
    END SUBROUTINE iter_pcg
END MODULE NM_Solv_IterSolver