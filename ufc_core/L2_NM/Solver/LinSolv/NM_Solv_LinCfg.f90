!===============================================================================
! MODULE: NM_Solv_LinCfg
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (auto-configuration)
! BRIEF:  Adaptive linear solver and preconditioner selection by problem size
!
! Status: CORE | Last verified: 2026-03-10
!===============================================================================

MODULE NM_Solv_LinCfg
    USE IF_Prec_Core, ONLY: wp, i4
    USE NM_Mtx_Core, ONLY: UF_CSRMatrix, csr_analyze_bandwidth, csr_reorder_rcm
    USE NM_Solv_LinDir, ONLY: CSR_Matrix, Direct_Solver_Params, &
        NM_LinSolv_Direct_Solv_System, NM_SOLVER_LU, NM_SOLVER_CHOLESKY
    IMPLICIT NONE
    PRIVATE

    ! Types for API compatibility (match NM_SparseSolvInterface/NM_LinearSolver)
    TYPE, PUBLIC :: NM_LinSolv_Config_Params
        INTEGER(i4) :: solver_type = 0
        INTEGER(i4) :: max_iter = 1000
        REAL(wp) :: tol = 1.0E-10_wp
        INTEGER(i4) :: restart = 30
        INTEGER(i4) :: precond_type = 2
        INTEGER(i4) :: lfil = 10
        REAL(wp) :: droptol = 1.0E-4_wp
        INTEGER(i4) :: size_threshold = 5000
        LOGICAL :: is_symmetric = .FALSE.
        LOGICAL :: verbose = .FALSE.
    END TYPE NM_LinSolv_Config_Params

    TYPE, PUBLIC :: NM_LinSolv_Config_Result
        INTEGER(i4) :: solver_used = 0
        INTEGER(i4) :: iterations = 0
        REAL(wp) :: residual = 0.0_wp
        REAL(wp) :: solve_time = 0.0_wp
        INTEGER(i4) :: status = 0
    END TYPE NM_LinSolv_Config_Result

    ! Legacy aliases for NM_LinearSolver compatibility
    TYPE, PUBLIC :: UF_LinSolParams
        INTEGER(i4) :: solver_type = 0
        INTEGER(i4) :: max_iter = 1000
        REAL(wp) :: tol = 1.0E-10_wp
        INTEGER(i4) :: restart = 30
        INTEGER(i4) :: precond_type = 2
        INTEGER(i4) :: lfil = 10
        REAL(wp) :: droptol = 1.0E-4_wp
        INTEGER(i4) :: size_threshold = 5000
        LOGICAL :: is_symmetric = .FALSE.
        LOGICAL :: verbose = .FALSE.
    END TYPE UF_LinSolParams

    TYPE, PUBLIC :: UF_LinSolResult
        INTEGER(i4) :: solver_used = 0
        INTEGER(i4) :: iterations = 0
        REAL(wp) :: residual = 0.0_wp
        REAL(wp) :: solve_time = 0.0_wp
        INTEGER(i4) :: status = 0
    END TYPE UF_LinSolResult

    INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_DIRECT   = 1
    INTEGER(i4), PARAMETER :: NM_SOLVER_PCG      = 4
    INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_GMRES    = 6
    INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_BICGSTAB = 3

    PUBLIC :: NM_LinSolv_Config
    PUBLIC :: NM_LinSolv_Config_AutoConfigure
    PUBLIC :: NM_LinSolv_Config_Estimate_Memory
    PUBLIC :: NM_LinSolv_Config_Recommend_Precond
    PUBLIC :: NM_LinSolv_Config_Check_SPD
    PUBLIC :: NM_LinSolv_Config_Solve_Optimized
    PUBLIC :: NM_LinSolv_Config_For_Physics
    PUBLIC :: NM_LinSolv_Config_Print_Summary

    ! Preconditioner constants (match NM_Preconditioner)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_NONE = 0
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_DIAG = 1
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ILU0 = 2
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ILUK = 3
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_IC0 = 4
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ICK = 5
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_SSOR = 6
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_AMG = 7
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ILUT = 8
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_BLOCK_JACOBI = 9
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_BLOCK_ILU0 = 10
    INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_JACOBI = NM_PRECOND_DIAG
    INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_PREC_IC = NM_PRECOND_IC0

    INTEGER(i4), PARAMETER, PUBLIC :: NM_PROBLEM_SPD = 1
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PROBLEM_SYMMETRIC = 2
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PROBLEM_GENERAL = 3

    INTEGER(i4), PARAMETER, PUBLIC :: NM_PHYSICS_STRUCTURAL = 1
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PHYSICS_THERMAL = 2
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PHYSICS_COUPLED = 3
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PHYSICS_CONTACT = 4
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PHYSICS_FLUID = 5
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PHYSICS_EIGENVALUE = 6

    TYPE :: NM_LinSolv_Config
        INTEGER(i4) :: problem_size = 0
        INTEGER(i4) :: problem_type = NM_PROBLEM_SPD
        INTEGER(i4) :: bandwidth = 0
        INTEGER(i4) :: profile = 0
        REAL(wp) :: fill_ratio = 0.0_wp
        REAL(wp) :: avg_row_width = 0.0_wp
        REAL(wp) :: condition_estimate = 0.0_wp
        INTEGER(i4) :: recommended_solver = NM_SOLVER_PCG
        INTEGER(i4) :: recommended_precond = NM_PRECOND_ILU0
        INTEGER(i4) :: ilu_fill_level = 0
        INTEGER(i4) :: recommended_max_iter = 1000
        REAL(wp) :: recommended_tol = 1.0E-10_wp
        LOGICAL :: use_reordering = .FALSE.
        INTEGER(i4), ALLOCATABLE :: perm(:)
        INTEGER(i4), ALLOCATABLE :: inv_perm(:)
        REAL(wp) :: matrix_memory = 0.0_wp
        REAL(wp) :: precond_memory = 0.0_wp
        REAL(wp) :: solver_memory = 0.0_wp
        REAL(wp) :: total_memory = 0.0_wp
    CONTAINS
        PROCEDURE :: destroy => NM_LinSolv_Config_Destroy
    END TYPE NM_LinSolv_Config

CONTAINS

    SUBROUTINE NM_LinSolv_Config_Destroy(this)
        CLASS(NM_LinSolv_Config), INTENT(INOUT) :: this
        IF (ALLOCATED(this%perm)) DEALLOCATE(this%perm)
        IF (ALLOCATED(this%inv_perm)) DEALLOCATE(this%inv_perm)
    END SUBROUTINE NM_LinSolv_Config_Destroy

    SUBROUTINE NM_LinSolv_Config_AutoConfigure(K, config, verbose)
        TYPE(UF_CSRMatrix), INTENT(IN) :: K
        TYPE(NM_LinSolv_Config), INTENT(OUT) :: config
        LOGICAL, INTENT(IN), OPTIONAL :: verbose

        LOGICAL :: print_info
        INTEGER(i4) :: n
        REAL(wp) :: sparsity

        print_info = .FALSE.
        IF (PRESENT(verbose)) print_info = verbose

        n = K%nrows
        config%problem_size = n

        CALL csr_analyze_bandwidth(K, config%bandwidth, config%profile, &
                                   config%avg_row_width)

        config%fill_ratio = REAL(K%nnz, wp) / REAL(n, wp)**2
        sparsity = 1.0_wp - config%fill_ratio

        CALL NM_LinSolv_Config_Estimate_Memory(K, config)

        config%problem_type = NM_PROBLEM_SPD

        IF (n < 5000) THEN
            config%recommended_solver = NM_SOLV_METHOD_DIRECT
            config%recommended_precond = NM_PRECOND_NONE
            config%recommended_max_iter = 1
            config%use_reordering = .FALSE.

        ELSE IF (n < 20000) THEN
            config%recommended_solver = NM_SOLVER_PCG
            config%recommended_precond = NM_PRECOND_ILU0
            config%ilu_fill_level = 0
            config%recommended_max_iter = MIN(n, 2000)
            config%use_reordering = .FALSE.

        ELSE IF (n < 50000) THEN
            config%recommended_solver = NM_SOLVER_PCG
            config%recommended_precond = NM_PRECOND_AMG
            config%ilu_fill_level = 0
            config%recommended_max_iter = MIN(n / 5, 1000)
            config%use_reordering = .FALSE.

        ELSE
            config%recommended_solver = NM_SOLVER_PCG
            config%recommended_precond = NM_PRECOND_AMG
            config%recommended_max_iter = MIN(n / 10, 5000)
            config%use_reordering = .FALSE.
        END IF

        IF (config%bandwidth > n / 10) THEN
            config%ilu_fill_level = config%ilu_fill_level + 1
            config%recommended_tol = 1.0E-12_wp
        END IF

        IF (print_info) THEN
            WRITE(*,'(A)') '=============================================='
            WRITE(*,'(A)') ' Solver Auto-Configuration Report'
            WRITE(*,'(A)') '=============================================='
            WRITE(*,'(A,I10)')     ' Problem size:        ', n
            WRITE(*,'(A,I10)')     ' Non-zeros:           ', K%nnz
            WRITE(*,'(A,ES10.2)')  ' Fill ratio:          ', config%fill_ratio
            WRITE(*,'(A,I10)')     ' Bandwidth:           ', config%bandwidth
            WRITE(*,'(A,F10.2)')   ' Avg row width:       ', config%avg_row_width
            WRITE(*,'(A)')         ''
            WRITE(*,'(A,A)')       ' Recommended solver:  ', NM_LinSolv_Config_Solver_Name(config%recommended_solver)
            WRITE(*,'(A,A)')       ' Recommended precond: ', NM_LinSolv_Config_Precond_Name(config%recommended_precond)
            WRITE(*,'(A,I10)')     ' Max iterations:      ', config%recommended_max_iter
            WRITE(*,'(A,ES10.2)')  ' Tolerance:           ', config%recommended_tol
            WRITE(*,'(A,L5)')      ' Use reordering:      ', config%use_reordering
            WRITE(*,'(A)')         ''
            WRITE(*,'(A,F10.2,A)') ' Matrix memory:       ', config%matrix_memory, ' MB'
            WRITE(*,'(A,F10.2,A)') ' Precond memory:      ', config%precond_memory, ' MB'
            WRITE(*,'(A,F10.2,A)') ' Total memory:        ', config%total_memory, ' MB'
            WRITE(*,'(A)') '=============================================='
        END IF

    END SUBROUTINE NM_LinSolv_Config_AutoConfigure

    SUBROUTINE NM_LinSolv_Config_Estimate_Memory(K, config)
        TYPE(UF_CSRMatrix), INTENT(IN) :: K
        TYPE(NM_LinSolv_Config), INTENT(INOUT) :: config

        REAL(wp) :: bytes_per_real, bytes_per_int
        REAL(wp) :: MB
        INTEGER(i4) :: n, nnz
        REAL(wp) :: precond_fill_factor

        bytes_per_real = 8.0_wp
        bytes_per_int = 4.0_wp
        MB = 1024.0_wp * 1024.0_wp

        n = K%nrows
        nnz = K%nnz

        config%matrix_memory = (nnz * bytes_per_real + &
                                nnz * bytes_per_int + &
                                (n+1) * bytes_per_int) / MB

        SELECT CASE (config%recommended_precond)
            CASE (NM_PRECOND_NONE)
                precond_fill_factor = 0.0_wp
            CASE (NM_PRECOND_DIAG)
                precond_fill_factor = REAL(n, wp) / REAL(nnz, wp)
            CASE (NM_PRECOND_ILU0, NM_PRECOND_IC0)
                precond_fill_factor = 1.0_wp
            CASE (NM_PRECOND_ILUK, NM_PRECOND_ICK)
                precond_fill_factor = 1.0_wp + 0.5_wp * config%ilu_fill_level
            CASE (NM_PRECOND_SSOR)
                precond_fill_factor = 1.0_wp
            CASE (NM_PRECOND_AMG)
                precond_fill_factor = 2.0_wp
            CASE DEFAULT
                precond_fill_factor = 1.0_wp
        END SELECT

        config%precond_memory = precond_fill_factor * config%matrix_memory

        SELECT CASE (config%recommended_solver)
            CASE (NM_SOLVER_PCG)
                config%solver_memory = 4.0_wp * n * bytes_per_real / MB
            CASE (NM_SOLV_METHOD_GMRES)
                config%solver_memory = 30.0_wp * n * bytes_per_real / MB
            CASE (NM_SOLV_METHOD_BICGSTAB)
                config%solver_memory = 8.0_wp * n * bytes_per_real / MB
            CASE DEFAULT
                config%solver_memory = n * bytes_per_real / MB
        END SELECT

        config%total_memory = config%matrix_memory + config%precond_memory + &
                              config%solver_memory

    END SUBROUTINE NM_LinSolv_Config_Estimate_Memory

    FUNCTION NM_LinSolv_Config_Recommend_Precond(K, problem_type) RESULT(precond)
        TYPE(UF_CSRMatrix), INTENT(IN) :: K
        INTEGER(i4), INTENT(IN) :: problem_type
        INTEGER(i4) :: precond

        INTEGER(i4) :: n
        REAL(wp) :: fill_ratio

        n = K%nrows
        fill_ratio = REAL(K%nnz, wp) / REAL(n, wp)**2

        IF (n < 5000) THEN
            precond = NM_PRECOND_NONE
        ELSE IF (problem_type == NM_PROBLEM_SPD) THEN
            IF (fill_ratio < 0.01_wp) THEN
                precond = NM_PRECOND_IC0
            ELSE IF (fill_ratio < 0.05_wp) THEN
                precond = NM_PRECOND_ILU0
            ELSE
                precond = NM_PRECOND_AMG
            END IF
        ELSE IF (problem_type == NM_PROBLEM_SYMMETRIC) THEN
            precond = NM_PRECOND_ILUK
        ELSE
            precond = NM_PRECOND_ILUK
        END IF

    END FUNCTION NM_LinSolv_Config_Recommend_Precond

    FUNCTION NM_LinSolv_Config_Check_SPD(K, check_symmetry, check_diagonal) RESULT(is_spd)
        TYPE(UF_CSRMatrix), INTENT(IN) :: K
        LOGICAL, INTENT(IN), OPTIONAL :: check_symmetry, check_diagonal
        LOGICAL :: is_spd

        LOGICAL :: do_symmetry, do_diagonal
        INTEGER(i4) :: i, jj
        REAL(wp) :: diag_val, tol

        do_symmetry = .TRUE.
        do_diagonal = .TRUE.
        IF (PRESENT(check_symmetry)) do_symmetry = check_symmetry
        IF (PRESENT(check_diagonal)) do_diagonal = check_diagonal

        is_spd = .TRUE.
        tol = 1.0E-14_wp

        IF (do_diagonal) THEN
            DO i = 1, K%nrows
                diag_val = 0.0_wp
                DO jj = K%row_ptr(i), K%row_ptr(i+1) - 1
                    IF (K%col_ind(jj) == i) THEN
                        diag_val = K%val(jj)
                        EXIT
                    END IF
                END DO

                IF (diag_val <= tol) THEN
                    is_spd = .FALSE.
                    RETURN
                END IF
            END DO
        END IF

        IF (do_symmetry .AND. K%nrows > 0) THEN
            is_spd = .TRUE.
        END IF

    END FUNCTION NM_LinSolv_Config_Check_SPD

    SUBROUTINE NM_LinSolv_Config_Solve_Optimized(K, b, x, params, result, verbose)
        TYPE(UF_CSRMatrix), INTENT(INOUT) :: K
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(INOUT) :: x(:)
        TYPE(NM_LinSolv_Config_Params), INTENT(INOUT) :: params
        TYPE(NM_LinSolv_Config_Result), INTENT(OUT) :: result
        LOGICAL, INTENT(IN), OPTIONAL :: verbose

        TYPE(NM_LinSolv_Config) :: config
        LOGICAL :: print_info

        print_info = .FALSE.
        IF (PRESENT(verbose)) print_info = verbose

        CALL NM_LinSolv_Config_AutoConfigure(K, config, print_info)
        IF (params%max_iter <= 0) THEN
            params%solver_type = config%recommended_solver
            params%precond_type = config%recommended_precond
            params%max_iter = config%recommended_max_iter
            params%tol = config%recommended_tol
        END IF

        result%status = 0
        result%iterations = 0
        result%residual = 0.0_wp

        IF (config%recommended_solver == NM_SOLV_METHOD_DIRECT .OR. K%nrows < params%size_threshold) THEN
            ! Direct solve: convert UF_CSRMatrix to CSR_Matrix and call NM_LinSolv_Direct_Solv_System
            BLOCK
                TYPE(CSR_Matrix) :: A_csr
                TYPE(Direct_Solver_Params) :: dparams
                INTEGER(i4) :: n, nnz, i
                n = K%nrows
                nnz = K%nnz
                A_csr%n_rows = n
                A_csr%n_cols = K%ncols
                A_csr%n_nonzeros = nnz
                ALLOCATE(A_csr%row_ptr(n+1), A_csr%col_idx(nnz), A_csr%values(nnz))
                A_csr%row_ptr(1:n+1) = K%row_ptr(1:n+1)
                A_csr%col_idx(1:nnz) = K%col_ind(1:nnz)
                A_csr%values(1:nnz) = K%val(1:nnz)
                dparams%solver_type = NM_SOLVER_LU
                dparams%storage_format = 1
                dparams%use_reordering = config%use_reordering
                dparams%symbolic_factorization = .TRUE.
                dparams%pivot_threshold = 1.0e-10_wp
                CALL NM_LinSolv_Direct_Solv_System(A_csr, b, dparams, x)
                DEALLOCATE(A_csr%row_ptr, A_csr%col_idx, A_csr%values)
                result%status = 0
                result%solver_used = NM_SOLV_METHOD_DIRECT
            END BLOCK
        ELSE
            ! Iterative path: would need CG/GMRES; for now leave x unchanged, status=-1
            result%status = -1
        END IF

        CALL config%destroy()

    END SUBROUTINE NM_LinSolv_Config_Solve_Optimized

    FUNCTION NM_LinSolv_Config_Solver_Name(solver_type) RESULT(name)
        INTEGER(i4), INTENT(IN) :: solver_type
        CHARACTER(LEN=16) :: name

        SELECT CASE (solver_type)
            CASE (NM_SOLVER_PCG)
                name = 'PCG'
            CASE (NM_SOLV_METHOD_GMRES)
                name = 'GMRES'
            CASE (NM_SOLV_METHOD_BICGSTAB)
                name = 'BiCGSTAB'
            CASE (NM_SOLV_METHOD_DIRECT)
                name = 'Direct'
            CASE DEFAULT
                name = 'Unknown'
        END SELECT
    END FUNCTION NM_LinSolv_Config_Solver_Name

    FUNCTION NM_LinSolv_Config_Precond_Name(precond_type) RESULT(name)
        INTEGER(i4), INTENT(IN) :: precond_type
        CHARACTER(LEN=16) :: name

        SELECT CASE (precond_type)
            CASE (NM_PRECOND_NONE)
                name = 'None'
            CASE (NM_PRECOND_DIAG)
                name = 'Diagonal'
            CASE (NM_PRECOND_ILU0)
                name = 'ILU(0)'
            CASE (NM_PRECOND_ILUK)
                name = 'ILU(k)'
            CASE (NM_PRECOND_IC0)
                name = 'IC(0)'
            CASE (NM_PRECOND_ICK)
                name = 'IC(k)'
            CASE (NM_PRECOND_SSOR)
                name = 'SSOR'
            CASE (NM_PRECOND_AMG)
                name = 'AMG'
            CASE (NM_PRECOND_ILUT)
                name = 'ILUT'
            CASE (NM_PRECOND_BLOCK_JACOBI)
                name = 'BlockJacobi'
            CASE (NM_PRECOND_BLOCK_ILU0)
                name = 'BlockILU0'
            CASE DEFAULT
                name = 'Unknown'
        END SELECT
    END FUNCTION NM_LinSolv_Config_Precond_Name

    SUBROUTINE NM_LinSolv_Config_For_Physics(physics_type, n, config)
        INTEGER(i4), INTENT(IN) :: physics_type
        INTEGER(i4), INTENT(IN) :: n
        TYPE(NM_LinSolv_Config), INTENT(OUT) :: config

        config%problem_size = n

        SELECT CASE (physics_type)

        CASE (NM_PHYSICS_STRUCTURAL)
            config%problem_type = NM_PROBLEM_SPD
            IF (n < 5000) THEN
                config%recommended_solver = NM_SOLV_METHOD_DIRECT
                config%recommended_precond = NM_PRECOND_NONE
            ELSE IF (n < 20000) THEN
                config%recommended_solver = NM_SOLVER_PCG
                config%recommended_precond = NM_PRECOND_IC0
                config%use_reordering = .FALSE.
            ELSE
                config%recommended_solver = NM_SOLVER_PCG
                config%recommended_precond = NM_PRECOND_AMG
                config%use_reordering = .FALSE.
            END IF
            config%recommended_tol = 1.0E-10_wp

        CASE (NM_PHYSICS_THERMAL)
            config%problem_type = NM_PROBLEM_SPD
            IF (n < 5000) THEN
                config%recommended_solver = NM_SOLV_METHOD_DIRECT
                config%recommended_precond = NM_PRECOND_NONE
            ELSE IF (n < 20000) THEN
                config%recommended_solver = NM_SOLVER_PCG
                config%recommended_precond = NM_PRECOND_ILU0
            ELSE
                config%recommended_solver = NM_SOLVER_PCG
                config%recommended_precond = NM_PRECOND_AMG
            END IF
            config%recommended_tol = 1.0E-8_wp

        CASE (NM_PHYSICS_COUPLED)
            config%problem_type = NM_PROBLEM_GENERAL
            IF (n < 10000) THEN
                config%recommended_solver = NM_SOLV_METHOD_GMRES
                config%recommended_precond = NM_PRECOND_ILUK
                config%ilu_fill_level = 2
            ELSE
                config%recommended_solver = NM_SOLV_METHOD_GMRES
                config%recommended_precond = NM_PRECOND_BLOCK_ILU0
                config%use_reordering = .TRUE.
            END IF
            config%recommended_tol = 1.0E-8_wp

        CASE (NM_PHYSICS_CONTACT)
            config%problem_type = NM_PROBLEM_SYMMETRIC
            config%recommended_solver = NM_SOLV_METHOD_GMRES
            config%recommended_precond = NM_PRECOND_ILUT
            config%ilu_fill_level = 3
            config%recommended_tol = 1.0E-8_wp
            config%recommended_max_iter = MAX(n / 5, 2000)

        CASE (NM_PHYSICS_FLUID)
            config%problem_type = NM_PROBLEM_GENERAL
            IF (n < 50000) THEN
                config%recommended_solver = NM_SOLV_METHOD_BICGSTAB
                config%recommended_precond = NM_PRECOND_ILUT
            ELSE
                config%recommended_solver = NM_SOLV_METHOD_BICGSTAB
                config%recommended_precond = NM_PRECOND_AMG
            END IF
            config%recommended_tol = 1.0E-6_wp

        CASE (NM_PHYSICS_EIGENVALUE)
            config%problem_type = NM_PROBLEM_SPD
            config%recommended_solver = NM_SOLVER_PCG
            config%recommended_precond = NM_PRECOND_IC0
            config%recommended_tol = 1.0E-12_wp

        CASE DEFAULT
            config%problem_type = NM_PROBLEM_SPD
            config%recommended_solver = NM_SOLVER_PCG
            config%recommended_precond = NM_PRECOND_ILU0
            config%recommended_tol = 1.0E-10_wp

        END SELECT

        IF (config%recommended_max_iter == 0) THEN
            config%recommended_max_iter = MIN(2 * n, 10000)
        END IF

    END SUBROUTINE NM_LinSolv_Config_For_Physics

    SUBROUTINE NM_LinSolv_Config_Print_Summary(iou)
        INTEGER, INTENT(IN), OPTIONAL :: iou
        INTEGER(i4) :: unit_num

        unit_num = 6
        IF (PRESENT(iou)) unit_num = iou

        WRITE(unit_num,'(A)') ''
        WRITE(unit_num,'(A)') '================================================================'
        WRITE(unit_num,'(A)') '  L2_NM LinSolv Algorithm Library Summary'
        WRITE(unit_num,'(A)') '================================================================'
        WRITE(unit_num,'(A)') ''
        WRITE(unit_num,'(A)') '  [KRYLOV SOLVERS]'
        WRITE(unit_num,'(A)') '    Core:     CG, GMRES, BiCGSTAB, FGMRES, TFQMR'
        WRITE(unit_num,'(A)') ''
        WRITE(unit_num,'(A)') '  [PRECONDITIONERS]'
        WRITE(unit_num,'(A)') '    Diagonal:   Jacobi, Block Jacobi'
        WRITE(unit_num,'(A)') '    ILU Family: ILU0, ILU(k), ILUT, MILU0'
        WRITE(unit_num,'(A)') '    IC Family:  IC0, SSOR'
        WRITE(unit_num,'(A)') '    Multigrid:  AMG (hsl_mi20)'
        WRITE(unit_num,'(A)') ''
        WRITE(unit_num,'(A)') '  [OPTIMAL CONFIGURATIONS]'
        WRITE(unit_num,'(A)') '    n < 5K:          Direct'
        WRITE(unit_num,'(A)') '    5K < n < 20K:    PCG + IC0/ILU0'
        WRITE(unit_num,'(A)') '    n > 20K:         PCG + AMG'
        WRITE(unit_num,'(A)') '================================================================'
        WRITE(unit_num,'(A)') ''

    END SUBROUTINE NM_LinSolv_Config_Print_Summary

END MODULE NM_Solv_LinCfg