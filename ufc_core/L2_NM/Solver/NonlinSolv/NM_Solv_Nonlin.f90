!===============================================================================
! MODULE: NM_Solv_Nonlin
! LAYER:  L2_NM
! DOMAIN: Solver/NonlinSolv
! ROLE:   Core (nonlinear solvers: Newton, arc-length, line search, L-BFGS)
! BRIEF:  Nonlinear solution framework with multiple strategy dispatch
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_Nonlin
    USE IF_Prec_Core, ONLY: wp
    USE NM_Solv_MemPool
    USE NM_Mtx_Core
    USE IF_Mem_WS, ONLY: UF_WS_Get_NL_DeltaWorkspace
    IMPLICIT NONE
    PRIVATE



    
    !---------------------------------------------------------------------------
    ! Public types and procedures
    !---------------------------------------------------------------------------
    PUBLIC :: UF_NLParams, UF_NLResult
    PUBLIC :: nl_newton_raphson
    PUBLIC :: nl_arc_length_crisfield
    PUBLIC :: nl_line_search
    PUBLIC :: nl_convergence_check
    PUBLIC :: nl_lbfgs
    
    !---------------------------------------------------------------------------
    ! Nonlinear solver types
    !---------------------------------------------------------------------------
    INTEGER, PARAMETER, PUBLIC :: NM_NL_TYPE_NEWTON = 1
    INTEGER, PARAMETER, PUBLIC :: NM_NL_TYPE_LBFGS = 2
    INTEGER, PARAMETER, PUBLIC :: NM_NL_TYPE_MODIFIED_NR = 3
    INTEGER, PARAMETER, PUBLIC :: NM_NL_TYPE_ARC_LENGTH = 4
    INTEGER, PARAMETER, PUBLIC :: NM_NL_TYPE_RIKS = 5
    
    !---------------------------------------------------------------------------
    ! Convergence criteria types
    !---------------------------------------------------------------------------
    INTEGER, PARAMETER, PUBLIC :: NM_CONV_FORCE = 1      ! Force residual
    INTEGER, PARAMETER, PUBLIC :: NM_CONV_DISP = 2       ! Displacement increment
    INTEGER, PARAMETER, PUBLIC :: NM_CONV_ENERGY = 3     ! Energy norm
    INTEGER, PARAMETER, PUBLIC :: NM_CONV_MIXED = 4      ! Combined criteria
    
    !---------------------------------------------------------------------------
    ! Nonlinear solver parameters
    !---------------------------------------------------------------------------
    TYPE :: UF_NLParams
        INTEGER(i4) :: solver_type = NM_NL_TYPE_NEWTON
        INTEGER(i4) :: conv_type = NM_CONV_MIXED
        INTEGER(i4) :: max_iter = 50           ! Max iterations per increment
        REAL(wp) :: tol_force = 1.0E-6_wp  ! Force residual tolerance
        REAL(wp) :: tol_disp = 1.0E-6_wp   ! Displacement tolerance
        REAL(wp) :: tol_energy = 1.0E-10_wp ! Energy tolerance
        LOGICAL :: use_line_search = .FALSE.
        REAL(wp) :: ls_min = 0.1_wp        ! Min line search factor
        REAL(wp) :: ls_max = 1.0_wp        ! Max line search factor
        ! Arc-length parameters
        REAL(wp) :: arc_length = 0.0_wp    ! Initial arc length
        REAL(wp) :: arc_min = 1.0E-6_wp    ! Min arc length
        REAL(wp) :: arc_max = 1.0E+2_wp    ! Max arc length
        REAL(wp) :: psi = 1.0_wp           ! Scaling parameter (0=load, 1=sphere)
        ! Adaptive stepping
        LOGICAL :: adaptive = .TRUE.
        INTEGER(i4) :: target_iter = 5         ! Target iterations for adaptation
        ! L-BFGS parameters
        INTEGER(i4) :: lbfgs_m = 10            ! Number of stored vectors (memory)
    END TYPE UF_NLParams
    
    !---------------------------------------------------------------------------
    ! Nonlinear solver result
    !---------------------------------------------------------------------------
    TYPE :: UF_NLResult
        INTEGER(i4) :: iterations = 0
        INTEGER(i4) :: converged = 0           ! 1=converged, 0=not, -1=diverged
        REAL(wp) :: residual_norm = 0.0_wp
        REAL(wp) :: disp_norm = 0.0_wp
        REAL(wp) :: energy_norm = 0.0_wp
        REAL(wp) :: load_factor = 0.0_wp
        REAL(wp) :: arc_length = 0.0_wp
    END TYPE UF_NLResult
    
    !---------------------------------------------------------------------------
    ! Abstract interface for residual and tangent computation
    !---------------------------------------------------------------------------
    ABSTRACT INTERFACE
        SUBROUTINE residual_interface(u, lambda, F_ext, R, ierr)
            IMPORT :: wp
            REAL(wp), INTENT(IN) :: u(:)         ! Current displacement
            REAL(wp), INTENT(IN) :: lambda       ! Load factor
            REAL(wp), INTENT(IN) :: F_ext(:)     ! External force
            REAL(wp), INTENT(OUT) :: R(:)        ! Residual = F_int - lambda*F_ext
            INTEGER(i4), INTENT(OUT) :: ierr
        END SUBROUTINE residual_interface
        
        SUBROUTINE tangent_interface(u, K, ierr)
            IMPORT :: wp, UF_CSRMatrix
            REAL(wp), INTENT(IN) :: u(:)         ! Current displacement
            TYPE(UF_CSRMatrix), INTENT(INOUT) :: K  ! Tangent stiffness
            INTEGER(i4), INTENT(OUT) :: ierr
        END SUBROUTINE tangent_interface
    END INTERFACE
    
CONTAINS

    SUBROUTINE adjust_arc_length(arc_len, iter, params)
        REAL(wp), INTENT(INOUT) :: arc_len
        INTEGER(i4), INTENT(IN) :: iter
        TYPE(UF_NLParams), INTENT(IN) :: params
        
        REAL(wp) :: factor
        
        IF (.NOT. params%adaptive) RETURN
        
        ! Adjust based on iteration count vs target
        factor = SQRT(REAL(params%target_iter, wp) / MAX(REAL(iter, wp), 1.0_wp))
        factor = MAX(0.25_wp, MIN(4.0_wp, factor))
        
        arc_len = arc_len * factor
        arc_len = MAX(params%arc_min, MIN(params%arc_max, arc_len))
        
    END SUBROUTINE adjust_arc_length

    SUBROUTINE lbfgs_line_search(u, p, lambda, F_ext, compute_residual, &
                                  g, f0, steplength, ierr)
        REAL(wp), INTENT(IN) :: u(:)
        REAL(wp), INTENT(IN) :: p(:)
        REAL(wp), INTENT(IN) :: lambda
        REAL(wp), INTENT(IN) :: F_ext(:)
        PROCEDURE(residual_interface) :: compute_residual
        REAL(wp), INTENT(IN) :: g(:)      ! Current gradient
        REAL(wp), INTENT(IN) :: f0        ! Current residual norm
        REAL(wp), INTENT(INOUT) :: steplength
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: ndof, k, max_ls
        REAL(wp) :: alpha, alpha_lo, alpha_hi
        REAL(wp) :: f_new, slope0, c1, c2, rho
        REAL(wp), ALLOCATABLE :: u_trial(:), R_trial(:)
        
        ierr = 0
        max_ls = 20
        ndof = SIZE(u)
        
        ALLOCATE(u_trial(ndof), R_trial(ndof))
        
        ! Armijo and Wolfe parameters
        c1 = 1.0E-4_wp   ! Sufficient decrease parameter
        c2 = 0.9_wp      ! Curvature parameter (for Wolfe)
        rho = 0.5_wp     ! Backtracking factor
        
        ! Initial slope: slope0 = g^T * p (should be negative)
        slope0 = DOT_PRODUCT(g, p)
        IF (slope0 >= 0.0_wp) THEN
            ! Not a descent direction
            steplength = 0.0_wp
            ierr = -1
            GOTO 100
        END IF
        
        alpha = 1.0_wp
        
        ! Backtracking line search
        DO k = 1, max_ls
            u_trial = u + alpha * p
            CALL compute_residual(u_trial, lambda, F_ext, R_trial, ierr)
            IF (ierr /= 0) THEN
                alpha = alpha * rho
                CYCLE
            END IF
            
            f_new = SQRT(DOT_PRODUCT(R_trial, R_trial))
            
            ! Armijo condition: f(x + alpha*p) <= f(x) + c1*alpha*slope0
            ! For residual minimization: ||R_new||^2 <= ||R||^2 + c1*alpha*slope0
            IF (f_new <= f0 + c1 * alpha * ABS(slope0) .OR. f_new < 1.0E-12_wp) THEN
                steplength = alpha
                GOTO 100
            END IF
            
            alpha = alpha * rho
        END DO
        
        ! Line search did not satisfy Armijo, but use last alpha anyway
        steplength = alpha
        IF (steplength < 1.0E-10_wp) THEN
            ierr = -1
        END IF
        
100     CONTINUE
        DEALLOCATE(u_trial, R_trial)
        
    END SUBROUTINE lbfgs_line_search

    SUBROUTINE nl_arc_length_crisfield(K, R, u, F_ext, lambda, dlambda, &
                                        params, compute_residual, compute_tangent, &
                                        linear_solve, result, ierr, pool, iter_id_out, resid_norm_out)

        TYPE(UF_CSRMatrix), INTENT(INOUT) :: K
        REAL(wp), INTENT(INOUT) :: R(:)
        REAL(wp), INTENT(INOUT) :: u(:)
        REAL(wp), INTENT(IN) :: F_ext(:)
        REAL(wp), INTENT(INOUT) :: lambda       ! Load factor
        REAL(wp), INTENT(INOUT) :: dlambda      ! Load factor increment
        TYPE(UF_NLParams), INTENT(IN) :: params
        PROCEDURE(residual_interface) :: compute_residual
        PROCEDURE(tangent_interface) :: compute_tangent
        INTERFACE
            SUBROUTINE linear_solve(K, b, x, ierr)
                IMPORT :: UF_CSRMatrix, wp
                TYPE(UF_CSRMatrix), INTENT(IN) :: K
                REAL(wp), INTENT(IN) :: b(:)
                REAL(wp), INTENT(OUT) :: x(:)
                INTEGER(i4), INTENT(OUT) :: ierr
            END SUBROUTINE linear_solve
        END INTERFACE
        TYPE(UF_NLResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_MemoryPool_t), INTENT(INOUT), OPTIONAL :: pool
        INTEGER, INTENT(OUT), OPTIONAL :: iter_id_out
        REAL(wp), INTENT(OUT), OPTIONAL :: resid_norm_out


        
        INTEGER(i4) :: iter, ndof
        REAL(wp) :: arc_len, psi2
        REAL(wp) :: a1, a2, a3, discriminant, ddlambda1, ddlambda2, ddlambda
        REAL(wp) :: R_norm, R_norm0, du_norm
        TYPE(UF_WorkVec_r) :: w_du, w_du_bar, w_du_hat, w_delta
        REAL(wp), POINTER :: du(:) => NULL(), du_bar(:) => NULL(), du_hat(:) => NULL(), delta_u(:) => NULL()
        LOGICAL :: converged
        LOGICAL :: use_pool
        
        ierr = 0
        ndof = SIZE(u)
        use_pool = PRESENT(pool)
        
        IF (use_pool) THEN
            CALL UF_Mem_GetRealVec(pool, ndof, w_du)
            CALL UF_Mem_GetRealVec(pool, ndof, w_du_bar)
            CALL UF_Mem_GetRealVec(pool, ndof, w_du_hat)
            CALL UF_Mem_GetRealVec(pool, ndof, w_delta)

            du      => w_du%p(1:ndof)
            du_bar  => w_du_bar%p(1:ndof)
            du_hat  => w_du_hat%p(1:ndof)
            delta_u => w_delta%p(1:ndof)
        ELSE
            ALLOCATE(du(ndof), du_bar(ndof), du_hat(ndof), delta_u(ndof))
        END IF
        
        arc_len = params%arc_length
        psi2 = params%psi * params%psi
        
        result%converged = 0
        result%iterations = 0
        result%arc_length = arc_len
        
        du = 0.0_wp
        
        ! Initial residual
        CALL compute_residual(u, lambda, F_ext, R, ierr)
        IF (ierr /= 0) GOTO 999
        
        R_norm0 = SQRT(DOT_PRODUCT(R, R))
        
        ! Arc-length iteration loop
        DO iter = 1, params%max_iter
            result%iterations = iter
            
            ! Compute tangent stiffness
            CALL compute_tangent(u, K, ierr)
            IF (ierr /= 0) GOTO 999
            
            ! Solve K * du_bar = -R (residual correction)
            R = -R
            CALL linear_solve(K, R, du_bar, ierr)
            IF (ierr /= 0) GOTO 999
            R = -R
            
            ! Solve K * du_hat = F_ext (load correction)
            CALL linear_solve(K, F_ext, du_hat, ierr)
            IF (ierr /= 0) GOTO 999
            
            ! Arc-length constraint: ||du||^2 + psi^2*(dlambda*||F||)^2 = arc_len^2
            ! Quadratic equation for ddlambda: a1*ddlambda^2 + a2*ddlambda + a3 = 0
            a1 = DOT_PRODUCT(du_hat, du_hat) + psi2 * DOT_PRODUCT(F_ext, F_ext)
            a2 = 2.0_wp * (DOT_PRODUCT(du + du_bar, du_hat) + psi2 * dlambda * DOT_PRODUCT(F_ext, F_ext))
            a3 = DOT_PRODUCT(du + du_bar, du + du_bar) + psi2 * dlambda * dlambda * DOT_PRODUCT(F_ext, F_ext) - arc_len * arc_len
            
            discriminant = a2*a2 - 4.0_wp*a1*a3
            
            IF (discriminant < 0.0_wp) THEN
                ! Arc length too large, need to reduce
                ierr = -3
                GOTO 999
            END IF
            
            ! Two roots
            ddlambda1 = (-a2 + SQRT(discriminant)) / (2.0_wp * a1)
            ddlambda2 = (-a2 - SQRT(discriminant)) / (2.0_wp * a1)
            
            ! Choose root that gives positive stiffness (continuation in same direction)
            IF (DOT_PRODUCT(du + du_bar + ddlambda1*du_hat, du) > &
                DOT_PRODUCT(du + du_bar + ddlambda2*du_hat, du)) THEN
                ddlambda = ddlambda1
            ELSE
                ddlambda = ddlambda2
            END IF
            
            ! Update increments
            delta_u = du_bar + ddlambda * du_hat
            du = du + delta_u
            dlambda = dlambda + ddlambda
            lambda = lambda + ddlambda
            u = u + delta_u
            
            ! Compute new residual
            CALL compute_residual(u, lambda, F_ext, R, ierr)
            IF (ierr /= 0) GOTO 999
            
            R_norm = SQRT(DOT_PRODUCT(R, R))
            du_norm = SQRT(DOT_PRODUCT(delta_u, delta_u))
            
            result%residual_norm = R_norm
            result%disp_norm = du_norm
            result%load_factor = lambda
            
            ! Check convergence
            CALL nl_convergence_check(R_norm, R_norm0, du_norm, 1.0_wp, &
                                      0.0_wp, params, converged)
            
            IF (converged) THEN
                result%converged = 1
                GOTO 999
            END IF
            
            IF (R_norm > 1.0E+10_wp .OR. ISNAN(R_norm)) THEN
                result%converged = -1
                ierr = -2
                GOTO 999
            END IF
            
        END DO
        
        result%converged = 0
        ierr = -1
        
999     CONTINUE
        IF (PRESENT(iter_id_out)) iter_id_out = result%iterations
        IF (PRESENT(resid_norm_out)) resid_norm_out = result%residual_norm

        IF (ASSOCIATED(du)) THEN
            IF (use_pool) THEN
                CALL UF_Mem_ReleaseRealVec(pool, w_du)
                CALL UF_Mem_ReleaseRealVec(pool, w_du_bar)
                CALL UF_Mem_ReleaseRealVec(pool, w_du_hat)
                CALL UF_Mem_ReleaseRealVec(pool, w_delta)
            ELSE
                DEALLOCATE(du, du_bar, du_hat, delta_u)
            END IF
        END IF
        
    END SUBROUTINE nl_arc_length_crisfield

    SUBROUTINE nl_convergence_check(R_norm, R_norm0, du_norm, du_norm0, &
                                     energy, params, converged)
        REAL(wp), INTENT(IN) :: R_norm, R_norm0
        REAL(wp), INTENT(IN) :: du_norm, du_norm0
        REAL(wp), INTENT(IN) :: energy
        TYPE(UF_NLParams), INTENT(IN) :: params
        LOGICAL, INTENT(OUT) :: converged
        
        REAL(wp) :: ref_R, ref_du
        LOGICAL :: conv_R, conv_du, conv_E
        
        ! Reference values (avoid division by zero)
        ref_R = MAX(R_norm0, 1.0E-10_wp)
        ref_du = MAX(du_norm0, 1.0E-10_wp)
        
        ! Individual convergence checks
        conv_R = (R_norm / ref_R < params%tol_force) .OR. (R_norm < 1.0E-12_wp)
        conv_du = (du_norm / ref_du < params%tol_disp) .OR. (du_norm < 1.0E-14_wp)
        conv_E = (energy < params%tol_energy)
        
        converged = .FALSE.
        
        SELECT CASE (params%conv_type)
        CASE (NM_CONV_FORCE)
            converged = conv_R
        CASE (NM_CONV_DISP)
            converged = conv_du
        CASE (NM_CONV_ENERGY)
            converged = conv_E
        CASE (NM_CONV_MIXED)
            converged = (conv_R .AND. conv_du) .OR. conv_E
        CASE DEFAULT
            converged = conv_R .AND. conv_du
        END SELECT
        
    END SUBROUTINE nl_convergence_check

    SUBROUTINE nl_lbfgs(R, u, F_ext, lambda, params, &
                        compute_residual, result, ierr, pool, iter_id_out, resid_norm_out)

        REAL(wp), INTENT(INOUT) :: R(:)             ! Residual vector
        REAL(wp), INTENT(INOUT) :: u(:)             ! Total displacement
        REAL(wp), INTENT(IN) :: F_ext(:)            ! External force
        REAL(wp), INTENT(IN) :: lambda              ! Current load factor
        TYPE(UF_NLParams), INTENT(IN) :: params
        PROCEDURE(residual_interface) :: compute_residual
        TYPE(UF_NLResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_MemoryPool_t), INTENT(INOUT), OPTIONAL :: pool
        INTEGER, INTENT(OUT), OPTIONAL :: iter_id_out
        REAL(wp), INTENT(OUT), OPTIONAL :: resid_norm_out


        
        INTEGER(i4) :: ndof, m, k, iter, i, j, bound
        REAL(wp) :: R_norm, R_norm0, gnorm, alpha, steplength
        REAL(wp) :: ys, yy, gamma_k
        TYPE(UF_WorkVec_r) :: w_g, w_g_old, w_p, w_s, w_y, w_q
        REAL(wp), POINTER :: g(:) => NULL(), g_old(:) => NULL(), p(:) => NULL(), &
                          s(:) => NULL(), y(:) => NULL(), q(:) => NULL()
        REAL(wp), ALLOCATABLE :: S_mat(:,:), Y_mat(:,:)  ! Storage for s and y vectors
        REAL(wp), ALLOCATABLE :: rho(:), alpha_arr(:)
        LOGICAL :: converged
        LOGICAL :: use_pool
        
        ierr = 0
        ndof = SIZE(u)
        m = MIN(params%lbfgs_m, ndof)  ! Number of stored correction pairs
        use_pool = PRESENT(pool)
        
        IF (use_pool) THEN
            CALL UF_Mem_GetRealVec(pool, ndof, w_g)
            CALL UF_Mem_GetRealVec(pool, ndof, w_g_old)
            CALL UF_Mem_GetRealVec(pool, ndof, w_p)
            CALL UF_Mem_GetRealVec(pool, ndof, w_s)
            CALL UF_Mem_GetRealVec(pool, ndof, w_y)
            CALL UF_Mem_GetRealVec(pool, ndof, w_q)

            g      => w_g%p(1:ndof)
            g_old  => w_g_old%p(1:ndof)
            p      => w_p%p(1:ndof)
            s      => w_s%p(1:ndof)
            y      => w_y%p(1:ndof)
            q      => w_q%p(1:ndof)
        ELSE
            ALLOCATE(g(ndof), g_old(ndof), p(ndof), s(ndof), y(ndof), q(ndof))
        END IF
        
        ALLOCATE(S_mat(ndof, m), Y_mat(ndof, m))
        ALLOCATE(rho(m), alpha_arr(m))
        
        result%converged = 0
        result%iterations = 0
        result%load_factor = lambda
        
        ! Compute initial residual: g = R(u)
        CALL compute_residual(u, lambda, F_ext, R, ierr)
        IF (ierr /= 0) GOTO 999
        
        g = R  ! Gradient = residual for minimization of ||R||^2
        R_norm0 = SQRT(DOT_PRODUCT(g, g))
        R_norm = R_norm0
        
        IF (R_norm0 < 1.0E-14_wp) THEN
            result%converged = 1
            result%residual_norm = R_norm0
            GOTO 999
        END IF
        
        k = 0  ! Iteration counter
        bound = 0  ! Number of stored pairs
        
        ! L-BFGS iteration loop
        DO iter = 1, params%max_iter
            result%iterations = iter
            
            ! =========================================================
            ! Step 1: Compute search direction using L-BFGS two-loop
            ! =========================================================
            q = g
            
            ! First loop: compute alpha and update q
            DO i = bound, 1, -1
                j = MOD(k - bound + i - 1, m) + 1  ! Circular index
                alpha_arr(i) = rho(j) * DOT_PRODUCT(S_mat(:,j), q)
                q = q - alpha_arr(i) * Y_mat(:,j)
            END DO
            
            ! Initial Hessian approximation: H_0 = gamma_k * I
            IF (bound > 0) THEN
                j = MOD(k - 1, m) + 1
                ys = DOT_PRODUCT(Y_mat(:,j), S_mat(:,j))
                yy = DOT_PRODUCT(Y_mat(:,j), Y_mat(:,j))
                IF (ABS(yy) > 1.0E-30_wp) THEN
                    gamma_k = ys / yy
                ELSE
                    gamma_k = 1.0_wp
                END IF
            ELSE
                gamma_k = 1.0_wp / MAX(R_norm, 1.0_wp)
            END IF
            
            p = gamma_k * q  ! r = H_0 * q
            
            ! Second loop: compute final direction
            DO i = 1, bound
                j = MOD(k - bound + i - 1, m) + 1
                alpha = rho(j) * DOT_PRODUCT(Y_mat(:,j), p)
                p = p + (alpha_arr(i) - alpha) * S_mat(:,j)
            END DO
            
            ! Search direction: p = -H * g
            p = -p
            
            ! =========================================================
            ! Step 2: Line search (backtracking with Armijo condition)
            ! =========================================================
            steplength = 1.0_wp
            CALL lbfgs_line_search(u, p, lambda, F_ext, compute_residual, &
                                   g, R_norm, steplength, ierr)
            IF (ierr /= 0) THEN
                ! Line search failed, try steepest descent
                p = -g
                steplength = 0.1_wp / MAX(R_norm, 1.0_wp)
            END IF
            
            ! =========================================================
            ! Step 3: Update solution
            ! =========================================================
            g_old = g
            s = steplength * p
            u = u + s
            
            ! Compute new residual
            CALL compute_residual(u, lambda, F_ext, R, ierr)
            IF (ierr /= 0) GOTO 999
            
            g = R
            R_norm = SQRT(DOT_PRODUCT(g, g))
            result%residual_norm = R_norm
            
            ! =========================================================
            ! Step 4: Check convergence
            ! =========================================================
            CALL nl_convergence_check(R_norm, R_norm0, SQRT(DOT_PRODUCT(s, s)), &
                                      1.0_wp, 0.0_wp, params, converged)
            
            IF (converged) THEN
                result%converged = 1
                GOTO 999
            END IF
            
            ! Check for divergence
            IF (R_norm > 1.0E+10_wp .OR. ISNAN(R_norm)) THEN
                result%converged = -1
                ierr = -2
                GOTO 999
            END IF
            
            ! =========================================================
            ! Step 5: Update L-BFGS storage
            ! =========================================================
            y = g - g_old
            ys = DOT_PRODUCT(y, s)
            
            ! Skip update if curvature condition not satisfied
            IF (ys > 1.0E-10_wp * DOT_PRODUCT(s, s) * SQRT(DOT_PRODUCT(y, y))) THEN
                j = MOD(k, m) + 1  ! Circular storage
                S_mat(:, j) = s
                Y_mat(:, j) = y
                rho(j) = 1.0_wp / ys
                
                k = k + 1
                bound = MIN(bound + 1, m)
            END IF
            
        END DO
        
        ! Max iterations reached
        result%converged = 0
        ierr = -1
        
999     CONTINUE
        IF (PRESENT(iter_id_out)) iter_id_out = result%iterations
        IF (PRESENT(resid_norm_out)) resid_norm_out = result%residual_norm

        IF (ASSOCIATED(g)) THEN
            IF (use_pool) THEN
                CALL UF_Mem_ReleaseRealVec(pool, w_g)
                CALL UF_Mem_ReleaseRealVec(pool, w_g_old)
                CALL UF_Mem_ReleaseRealVec(pool, w_p)
                CALL UF_Mem_ReleaseRealVec(pool, w_s)
                CALL UF_Mem_ReleaseRealVec(pool, w_y)
                CALL UF_Mem_ReleaseRealVec(pool, w_q)
            ELSE
                DEALLOCATE(g, g_old, p, s, y, q)
            END IF
        END IF
        DEALLOCATE(S_mat, Y_mat, rho, alpha_arr)
        
    END SUBROUTINE nl_lbfgs

    SUBROUTINE nl_line_search(u, du, lambda, F_ext, compute_residual, alpha, ierr)
        REAL(wp), INTENT(IN) :: u(:)
        REAL(wp), INTENT(IN) :: du(:)
        REAL(wp), INTENT(IN) :: lambda
        REAL(wp), INTENT(IN) :: F_ext(:)
        PROCEDURE(residual_interface) :: compute_residual
        REAL(wp), INTENT(OUT) :: alpha
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: ndof, k, max_ls
        REAL(wp) :: g0, g1, alpha_old
        REAL(wp), ALLOCATABLE :: u_trial(:), R_trial(:)
        REAL(wp), PARAMETER :: c = 0.5_wp  ! Armijo parameter
        REAL(wp), PARAMETER :: rho = 0.5_wp ! Backtracking factor
        
        ierr = 0
        max_ls = 10
        ndof = SIZE(u)
        ALLOCATE(u_trial(ndof), R_trial(ndof))
        
        ! Compute initial gradient: g0 = du^T * R(u)
        CALL compute_residual(u, lambda, F_ext, R_trial, ierr)
        IF (ierr /= 0) THEN
            alpha = 1.0_wp
            GOTO 100
        END IF
        g0 = DOT_PRODUCT(du, R_trial)
        
        alpha = 1.0_wp
        
        DO k = 1, max_ls
            u_trial = u + alpha * du
            CALL compute_residual(u_trial, lambda, F_ext, R_trial, ierr)
            IF (ierr /= 0) THEN
                alpha = alpha * rho
                CYCLE
            END IF
            
            g1 = DOT_PRODUCT(du, R_trial)
            
            ! Armijo-like condition based on residual projection
            IF (ABS(g1) <= (1.0_wp - c * alpha) * ABS(g0) .OR. ABS(g1) < 1.0E-12_wp) THEN
                GOTO 100
            END IF
            
            alpha = alpha * rho
        END DO
        
        ! If line search fails, use full step
        alpha = 1.0_wp
        
100     CONTINUE
        DEALLOCATE(u_trial, R_trial)
        
    END SUBROUTINE nl_line_search

    SUBROUTINE nl_newton_raphson(K, R, du, u, F_ext, lambda, params, &
                                  compute_residual, compute_tangent, &
                                  linear_solve, result, ierr, pool, iter_id_out, resid_norm_out)

        TYPE(UF_CSRMatrix), INTENT(INOUT) :: K      ! Tangent stiffness
        REAL(wp), INTENT(INOUT) :: R(:)             ! Residual vector
        REAL(wp), INTENT(OUT) :: du(:)              ! Displacement increment
        REAL(wp), INTENT(INOUT) :: u(:)             ! Total displacement
        REAL(wp), INTENT(IN) :: F_ext(:)            ! External force
        REAL(wp), INTENT(IN) :: lambda              ! Current load factor
        TYPE(UF_NLParams), INTENT(IN) :: params
        PROCEDURE(residual_interface) :: compute_residual
        PROCEDURE(tangent_interface) :: compute_tangent
        INTERFACE
            SUBROUTINE linear_solve(K, b, x, ierr)
                IMPORT :: UF_CSRMatrix, wp
                TYPE(UF_CSRMatrix), INTENT(IN) :: K
                REAL(wp), INTENT(IN) :: b(:)
                REAL(wp), INTENT(OUT) :: x(:)
                INTEGER(i4), INTENT(OUT) :: ierr
            END SUBROUTINE linear_solve
        END INTERFACE
        TYPE(UF_NLResult), INTENT(OUT) :: result
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_MemoryPool_t), INTENT(INOUT), OPTIONAL :: pool
        INTEGER, INTENT(OUT), OPTIONAL :: iter_id_out
        REAL(wp), INTENT(OUT), OPTIONAL :: resid_norm_out


        
        INTEGER(i4) :: iter, ndof
        REAL(wp) :: R_norm, R_norm0, du_norm, du_norm0, energy
        REAL(wp) :: alpha
        TYPE(UF_WorkVec_r) :: w_delta
        REAL(wp), POINTER :: delta_u(:)  => NULL()
        REAL(wp), POINTER :: delta_ws(:) => NULL()
        LOGICAL :: converged
        LOGICAL :: use_pool
        LOGICAL :: use_thread_ws
        
        ierr = 0
        ndof = SIZE(u)
        use_pool = PRESENT(pool)
        
        ! ???????? ?workspace ?????? ?
        CALL UF_WS_Get_NL_DeltaWorkspace(ndof, delta_ws)
        use_thread_ws = ASSOCIATED(delta_ws)
        
        IF (use_thread_ws) THEN
            delta_u => delta_ws
        ELSE IF (use_pool) THEN
            CALL UF_Mem_GetRealVec(pool, ndof, w_delta)
            delta_u => w_delta%p(1:ndof)
        ELSE
            ALLOCATE(delta_u(ndof))
        END IF

        
        du = 0.0_wp
        result%converged = 0
        result%iterations = 0
        result%load_factor = lambda
        
        ! Initial residual
        CALL compute_residual(u, lambda, F_ext, R, ierr)
        IF (ierr /= 0) THEN
            WRITE(*,'(A,I0)') '  [NR] compute_residual failed (initial), ierr=', ierr
            GOTO 900
        END IF
        
        R_norm0 = SQRT(DOT_PRODUCT(R, R))
        du_norm0 = 1.0_wp
        
        ! Newton-Raphson iteration loop
        DO iter = 1, params%max_iter
            result%iterations = iter
            
            ! Compute tangent stiffness (skip if modified NR and not first iter)
            IF (params%solver_type == NM_NL_TYPE_NEWTON .OR. iter == 1) THEN
                CALL compute_tangent(u, K, ierr)
                IF (ierr /= 0) THEN
                    WRITE(*,'(A,I0,A,I0)') '  [NR] compute_tangent failed, iter=', iter, ', ierr=', ierr
                    GOTO 900
                END IF
            END IF
            
            ! Solve for displacement correction: K * delta_u = -R
            R = -R  ! RHS = -R
            CALL linear_solve(K, R, delta_u, ierr)
            IF (ierr /= 0) THEN
                R = -R  ! Restore R sign before returning
                WRITE(*,'(A,I0,A,I0)') '  [NR] linear_solve failed, iter=', iter, ', ierr=', ierr
                GOTO 900
            END IF
            R = -R  ! Restore R sign
            
            ! Line search (optional)
            alpha = 1.0_wp
            IF (params%use_line_search) THEN
                CALL nl_line_search(u, delta_u, lambda, F_ext, &
                                   compute_residual, alpha, ierr)
                IF (ierr /= 0) alpha = 1.0_wp
            END IF
            
            ! Update displacement
            u = u + alpha * delta_u
            du = du + alpha * delta_u
            
            ! Compute new residual
            CALL compute_residual(u, lambda, F_ext, R, ierr)
            IF (ierr /= 0) THEN
                WRITE(*,'(A,I0,A,I0)') '  [NR] compute_residual failed, iter=', iter, ', ierr=', ierr
                GOTO 900
            END IF
            
            ! Convergence measures
            R_norm = SQRT(DOT_PRODUCT(R, R))
            du_norm = SQRT(DOT_PRODUCT(delta_u, delta_u))
            energy = ABS(DOT_PRODUCT(delta_u, R))
            
            IF (iter == 1) du_norm0 = MAX(du_norm, 1.0E-10_wp)
            
            result%residual_norm = R_norm
            result%disp_norm = du_norm
            result%energy_norm = energy
            
            ! Check convergence
            CALL nl_convergence_check(R_norm, R_norm0, du_norm, du_norm0, &
                                      energy, params, converged)
            
            IF (converged) THEN
                result%converged = 1
                GOTO 900
            END IF
            
            ! Check for divergence
            IF (R_norm > 1.0E+10_wp .OR. ISNAN(R_norm)) THEN
                result%converged = -1
                ierr = -2
                GOTO 900
            END IF
            
        END DO
        
        ! Max iterations reached
        result%converged = 0
        ierr = -1
        
900     CONTINUE
        IF (PRESENT(iter_id_out)) iter_id_out = result%iterations
        IF (PRESENT(resid_norm_out)) resid_norm_out = result%residual_norm

        IF (ASSOCIATED(delta_u)) THEN
            IF (.NOT. use_thread_ws) THEN
                IF (use_pool) THEN
                    CALL UF_Mem_ReleaseRealVec(pool, w_delta)
                ELSE
                    DEALLOCATE(delta_u)
                END IF
            END IF
        END IF
        
    END SUBROUTINE nl_newton_raphson
END MODULE NM_Solv_Nonlin