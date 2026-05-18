!===============================================================================
! MODULE: NM_Solv_AMGInterface
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Brg (bridge to HSL MI20 AMG library)
! BRIEF:  Interface to Algebraic Multigrid (AMG) preconditioner via HSL MI20
!
! Theory: AMG coarsening + interpolation + V-cycle smoothing; Ref: Ruge&Stuben(1987)
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_AMGInterface
    USE hsl_mi20_double  ! HSL MI20 AMG library
    USE IF_Prec_Core, ONLY: wp, i4
    USE NM_Mtx_Core, ONLY: UF_CSRMatrix
    IMPLICIT NONE
    PRIVATE
    
    !--------------------------------------------------------------------------
    ! Public interface
    !--------------------------------------------------------------------------
    PUBLIC :: UF_AMG_Precond
    PUBLIC :: UF_AMG_Control
    PUBLIC :: UF_AMG_Info
    PUBLIC :: amg_setup, amg_apply, amg_solve, amg_destroy
    PUBLIC :: amg_set_defaults
    
    ! Krylov solver constants
    INTEGER(i4), PARAMETER, PUBLIC :: NM_AMG_PURE = 0       ! Pure AMG, no Krylov
    INTEGER(i4), PARAMETER, PUBLIC :: NM_AMG_PCG = 1        ! Conjugate Gradient
    INTEGER(i4), PARAMETER, PUBLIC :: NM_AMG_GMRES = 2      ! GMRES
    INTEGER(i4), PARAMETER, PUBLIC :: NM_AMG_BICGSTAB = 3   ! BiCGSTAB
    INTEGER(i4), PARAMETER, PUBLIC :: NM_AMG_MINRES = 4     ! MINRES
    
    !--------------------------------------------------------------------------
    ! AMG Control parameters
    !--------------------------------------------------------------------------
    TYPE :: UF_AMG_Control
        ! Coarsening parameters
        REAL(wp) :: st_parameter = 0.25_wp      ! Strong connection threshold
        INTEGER(i4) :: aggressive = 1            ! Aggressive coarsening steps
        INTEGER(i4) :: max_levels = 100          ! Maximum coarsening levels
        INTEGER(i4) :: max_points = 1            ! Max points on coarsest level
        REAL(wp) :: reduction = 0.8_wp           ! Stagnation detection
        
        ! Smoother parameters
        INTEGER(i4) :: smoother = 2              ! 1=Jacobi, 2=Gauss-Seidel
        INTEGER(i4) :: pre_smoothing = 2         ! Pre-smoothing iterations
        INTEGER(i4) :: post_smoothing = 2        ! Post-smoothing iterations
        REAL(wp) :: damping = 0.8_wp             ! Jacobi damping factor
        
        ! V-cycle parameters
        INTEGER(i4) :: v_iterations = 1          ! V-cycle iterations per apply
        INTEGER(i4) :: coarse_solver = 3         ! Coarse solver type
        INTEGER(i4) :: coarse_solver_its = 10    ! Coarse solver iterations
        
        ! Krylov solver for amg_solve
        INTEGER(i4) :: krylov_solver = 3         ! 0=AMG,1=PCG,2=GMRES,3=BiCGSTAB,4=MINRES
        REAL(wp) :: rel_tol = 1.0E-6_wp          ! Relative tolerance
        
        ! Output control
        INTEGER(i4) :: print_level = 0           ! 0=silent, 1=summary, 2=details
        
    END TYPE UF_AMG_Control
    
    !--------------------------------------------------------------------------
    ! AMG Information/status
    !--------------------------------------------------------------------------
    TYPE :: UF_AMG_Info
        INTEGER(i4) :: flag = 0                  ! Error/warning flag
        INTEGER(i4) :: clevels = 0               ! Number of coarse levels
        INTEGER(i4) :: cpoints = 0               ! Points on coarsest level
        INTEGER(i4) :: coarse_ops = 0            ! Coarse level operations
        REAL(wp) :: operator_complexity = 0.0_wp ! Sum(nnz)/nnz(A)
        REAL(wp) :: grid_complexity = 0.0_wp     ! Sum(n)/n(A)
        REAL(wp) :: setup_time = 0.0_wp          ! Setup time (seconds)
        REAL(wp) :: apply_time = 0.0_wp          ! Total apply time
        INTEGER(i4) :: apply_count = 0           ! Number of applies
    END TYPE UF_AMG_Info
    
    !--------------------------------------------------------------------------
    ! AMG Preconditioner data structure
    !--------------------------------------------------------------------------
    TYPE :: UF_AMG_Precond
        INTEGER(i4) :: n = 0                     ! Problem size
        INTEGER(i4) :: nnz = 0                   ! Number of non-zeros
        LOGICAL :: is_setup = .FALSE.            ! Setup complete flag
        
        ! Control and info
        TYPE(UF_AMG_Control) :: control
        TYPE(UF_AMG_Info) :: info
        
        ! HSL MI20 data structures (actual AMG data)
        TYPE(mi20_data), ALLOCATABLE :: coarse_data(:)
        TYPE(mi20_control) :: mi20_ctrl
        TYPE(mi20_solve_control) :: solve_ctrl
        TYPE(mi20_info) :: mi20_info
        TYPE(mi20_keep) :: keep
        
        ! Coordinate format storage for setup
        INTEGER(i4), ALLOCATABLE :: row(:)
        INTEGER(i4), ALLOCATABLE :: col(:)
        REAL(wp), ALLOCATABLE :: val(:)
        
    CONTAINS
        PROCEDURE :: destroy => amg_precond_destroy
        
    END TYPE UF_AMG_Precond
    
    ! Constants
    REAL(wp), PARAMETER :: SMALL = 1.0E-30_wp
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    
    ! Error codes
    INTEGER(i4), PARAMETER :: NM_AMG_SUCCESS = 0
    INTEGER(i4), PARAMETER :: NM_AMG_ERR_ALLOC = -1
    INTEGER(i4), PARAMETER :: NM_AMG_ERR_INPUT = -2
    INTEGER(i4), PARAMETER :: NM_AMG_ERR_COARSEN = -3
    INTEGER(i4), PARAMETER :: NM_AMG_ERR_NO_SETUP = -4
    
CONTAINS

    !===========================================================================
    ! Set default control parameters
    !===========================================================================
    SUBROUTINE amg_set_defaults(control)
        TYPE(UF_AMG_Control), INTENT(OUT) :: control
        
        control%st_parameter = 0.25_wp
        control%aggressive = 1
        control%max_levels = 100
        control%max_points = 1
        control%reduction = 0.8_wp
        
        control%smoother = 2          ! Gauss-Seidel
        control%pre_smoothing = 2
        control%post_smoothing = 2
        control%damping = 0.8_wp
        
        control%v_iterations = 1
        control%coarse_solver = 3
        control%coarse_solver_its = 10
        
        control%krylov_solver = 3     ! BiCGSTAB
        control%rel_tol = 1.0E-6_wp
        
        control%print_level = 0
        
    END SUBROUTINE amg_set_defaults
    
    !===========================================================================
    ! Setup AMG preconditioner using HSL MI20
    !
    ! Converts CSR matrix to coordinate format and calls mi20_setup_coord
    !
    ! Input:
    !   K       - CSR matrix (should be SPD for best results)
    !   control - Optional control parameters
    !
    ! Output:
    !   amg     - AMG preconditioner ready for application
    !   ierr    - Error code (0 = success)
    !===========================================================================
    SUBROUTINE amg_setup(amg, K, ierr, control)
        TYPE(UF_AMG_Precond), INTENT(INOUT) :: amg
        TYPE(UF_CSRMatrix), INTENT(IN) :: K
        INTEGER(i4), INTENT(OUT) :: ierr
        TYPE(UF_AMG_Control), INTENT(IN), OPTIONAL :: control
        
        INTEGER(i4) :: n, nnz, i, j, k_idx, istat
        REAL(wp) :: t_start, t_end
        
        ierr = NM_AMG_SUCCESS
        
        ! Record start time
        CALL CPU_TIME(t_start)
        
        ! Set control parameters
        IF (PRESENT(control)) THEN
            amg%control = control
        ELSE
            CALL amg_set_defaults(amg%control)
        END IF
        
        n = K%nrows
        nnz = K%nnz
        amg%n = n
        amg%nnz = nnz
        
        IF (n < 1 .OR. nnz < 1) THEN
            ierr = NM_AMG_ERR_INPUT
            RETURN
        END IF
        
        ! Allocate coordinate format arrays for mi20_setup_coord
        IF (ALLOCATED(amg%row)) DEALLOCATE(amg%row)
        IF (ALLOCATED(amg%col)) DEALLOCATE(amg%col)
        IF (ALLOCATED(amg%val)) DEALLOCATE(amg%val)
        
        ALLOCATE(amg%row(nnz), amg%col(nnz), amg%val(nnz), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_AMG_ERR_ALLOC
            RETURN
        END IF
        
        ! Convert CSR to coordinate format
        ! CSR: row_ptr(i) to row_ptr(i+1)-1 contains column indices for row i
        DO i = 1, n
            DO j = K%row_ptr(i), K%row_ptr(i + 1) - 1
                amg%row(j) = i
                amg%col(j) = K%col_ind(j)
                amg%val(j) = K%val(j)
            END DO
        END DO
        
        ! Configure MI20 control parameters
        amg%mi20_ctrl%error = -1          ! Suppress error messages
        amg%mi20_ctrl%print = -1          ! Suppress convergence info
        IF (amg%control%print_level >= 2) THEN
            amg%mi20_ctrl%error = 6
            amg%mi20_ctrl%print = 6
        END IF
        
        amg%mi20_ctrl%st_parameter = amg%control%st_parameter
        amg%mi20_ctrl%aggressive = amg%control%aggressive
        amg%mi20_ctrl%max_levels = amg%control%max_levels
        amg%mi20_ctrl%smoother = amg%control%smoother
        amg%mi20_ctrl%pre_smoothing = amg%control%pre_smoothing
        amg%mi20_ctrl%post_smoothing = amg%control%post_smoothing
        amg%mi20_ctrl%damping = amg%control%damping
        amg%mi20_ctrl%v_iterations = amg%control%v_iterations
        amg%mi20_ctrl%coarse_solver = amg%control%coarse_solver
        amg%mi20_ctrl%coarse_solver_its = amg%control%coarse_solver_its
        
        ! Call HSL MI20 setup with coordinate format
        CALL mi20_setup_coord(amg%row, amg%col, amg%val, nnz, n, &
                              amg%coarse_data, amg%keep, amg%mi20_ctrl, amg%mi20_info)
        
        IF (amg%mi20_info%flag < 0) THEN
            IF (amg%control%print_level >= 1) THEN
                WRITE(*,*) 'Error from mi20_setup_coord, flag = ', amg%mi20_info%flag
            END IF
            ierr = NM_AMG_ERR_COARSEN
            RETURN
        END IF
        
        ! Record setup statistics
        amg%info%clevels = amg%mi20_info%clevels
        amg%info%cpoints = amg%mi20_info%cpoints
        amg%info%operator_complexity = 0.0_wp

        
        CALL CPU_TIME(t_end)
        amg%info%setup_time = t_end - t_start
        
        amg%is_setup = .TRUE.
        
        IF (amg%control%print_level >= 1) THEN
            WRITE(*,'(A)') '=========================================='  
            WRITE(*,'(A)') 'AMG Preconditioner Setup Complete'
            WRITE(*,'(A,I10)') '  Problem size:      ', n
            WRITE(*,'(A,I10)') '  Non-zeros:         ', nnz
            WRITE(*,'(A,I10)') '  Coarse levels:     ', amg%info%clevels
            WRITE(*,'(A,F10.3)') '  Setup time (s):    ', amg%info%setup_time
            WRITE(*,'(A)') '=========================================='
        END IF
        
    END SUBROUTINE amg_setup
    
    !===========================================================================
    ! Apply AMG as preconditioner: y = M^(-1) * x (one V-cycle)
    !
    ! Uses solve_control%krylov_solver = 0 for pure AMG application
    !===========================================================================
    SUBROUTINE amg_apply(amg, x, y)
        TYPE(UF_AMG_Precond), INTENT(INOUT) :: amg
        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: n
        REAL(wp) :: t_start, t_end
        
        CALL CPU_TIME(t_start)
        
        n = amg%n
        
        IF (.NOT. amg%is_setup) THEN
            y(1:n) = x(1:n)
            RETURN
        END IF
        
        ! Use pure AMG (no Krylov) for preconditioner application
        amg%solve_ctrl%krylov_solver = 0  ! Pure AMG
        amg%solve_ctrl%rel_tol = 1.0E-1_wp  ! Loose tolerance for single V-cycle
        
        ! Call MI20 solve
        CALL mi20_solve(amg%coarse_data, x, y, amg%keep, amg%mi20_ctrl, &
                        amg%solve_ctrl, amg%mi20_info)
        
        CALL CPU_TIME(t_end)
        amg%info%apply_time = amg%info%apply_time + (t_end - t_start)
        amg%info%apply_count = amg%info%apply_count + 1
        
    END SUBROUTINE amg_apply
    
    !===========================================================================
    ! Solve linear system using AMG with Krylov acceleration
    !
    ! Solves: A * x = b using AMG-preconditioned Krylov method
    !
    ! Krylov solver options (control%krylov_solver):
    !   0 = Pure AMG (no Krylov)
    !   1 = PCG (requires A to be SPD)
    !   2 = GMRES
    !   3 = BiCGSTAB (default)
    !   4 = MINRES (requires A to be symmetric)
    !
    ! Input:
    !   amg  - Setup AMG preconditioner
    !   b    - Right-hand side vector
    !
    ! Output:
    !   x    - Solution vector
    !   ierr - Error code
    !===========================================================================
    SUBROUTINE amg_solve(amg, b, x, ierr)
        TYPE(UF_AMG_Precond), INTENT(INOUT) :: amg
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n
        REAL(wp) :: t_start, t_end
        
        ierr = NM_AMG_SUCCESS
        
        CALL CPU_TIME(t_start)
        
        n = amg%n
        
        IF (.NOT. amg%is_setup) THEN
            ierr = NM_AMG_ERR_NO_SETUP
            x(1:n) = b(1:n)
            RETURN
        END IF
        
        ! Initialize solution to zero
        x(1:n) = ZERO
        
        ! Configure solve control
        amg%solve_ctrl%krylov_solver = amg%control%krylov_solver
        amg%solve_ctrl%rel_tol = amg%control%rel_tol
        
        ! Call MI20 solve with Krylov acceleration
        CALL mi20_solve(amg%coarse_data, b, x, amg%keep, amg%mi20_ctrl, &
                        amg%solve_ctrl, amg%mi20_info)
        
        IF (amg%mi20_info%flag < 0) THEN
            IF (amg%control%print_level >= 1) THEN
                WRITE(*,*) 'Error from mi20_solve, flag = ', amg%mi20_info%flag
            END IF
            ierr = amg%mi20_info%flag
        END IF
        
        CALL CPU_TIME(t_end)
        
        IF (amg%control%print_level >= 1) THEN
            WRITE(*,'(A,I6,A,E12.4)') '  AMG solve: ', &
                amg%mi20_info%iterations, ' iterations, residual = ', &
                amg%mi20_info%residual
        END IF
        
    END SUBROUTINE amg_solve
    
    !===========================================================================
    ! Destroy AMG preconditioner
    !===========================================================================
    SUBROUTINE amg_destroy(amg)
        TYPE(UF_AMG_Precond), INTENT(INOUT) :: amg
        
        CALL amg_precond_destroy(amg)
        
    END SUBROUTINE amg_destroy
    
    SUBROUTINE amg_precond_destroy(this)
        CLASS(UF_AMG_Precond), INTENT(INOUT) :: this
        
        ! Finalize HSL MI20 data
        IF (this%is_setup .AND. ALLOCATED(this%coarse_data)) THEN
            CALL mi20_finalize(this%coarse_data, this%keep, this%mi20_ctrl, this%mi20_info)
        END IF
        
        ! Deallocate arrays
        IF (ALLOCATED(this%coarse_data)) DEALLOCATE(this%coarse_data)
        IF (ALLOCATED(this%row)) DEALLOCATE(this%row)
        IF (ALLOCATED(this%col)) DEALLOCATE(this%col)
        IF (ALLOCATED(this%val)) DEALLOCATE(this%val)
        
        this%n = 0
        this%nnz = 0
        this%is_setup = .FALSE.
        
        ! Reset info
        this%info%flag = 0
        this%info%clevels = 0
        this%info%cpoints = 0
        this%info%setup_time = 0.0_wp
        this%info%apply_time = 0.0_wp
        this%info%apply_count = 0
        
    END SUBROUTINE amg_precond_destroy

END MODULE NM_Solv_AMGInterface