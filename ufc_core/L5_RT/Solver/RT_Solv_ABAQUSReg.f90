!===============================================================================
! MODULE: RT_Solv_ABAQUSReg
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Reg (ABAQUS Registry)
! BRIEF:  ABAQUS-compatible solver registry for core analysis types
!===============================================================================
!
! Process族:
!   P0: Register (solver registry population)         [COLD_PATH]
!   P0: Validate (solver config validation)           [COLD_PATH]
!
! Constants: ABAQUS_SOLVER_STATIC / DYNAMIC_EXPLICIT / DYNAMIC_IMPLICIT
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

module RT_Solv_ABAQUSReg
!> Status: CORE | 仅支持三种核心分析类�?
!> Theory: UFC Solver Architecture - Minimal Implementation (精简�?
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! ABAQUS Solver Categories (精简�?- 仅保留三种核心分�?
    !=============================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: ABAQUS_SOLVER_STATIC = 1
    INTEGER(i4), PARAMETER, PUBLIC :: ABAQUS_SOLVER_DYNAMIC_EXPLICIT = 2
    INTEGER(i4), PARAMETER, PUBLIC :: ABAQUS_SOLVER_DYNAMIC_IMPLICIT = 3

    !=============================================================================
    ! ABAQUS Solver Registry Entry
    !=============================================================================
    TYPE, PUBLIC :: ABAQUS_SolverRegistryEntry
        INTEGER(i4) :: solver_id = 0
        CHARACTER(LEN=64) :: abaqus_keyword = ""
        CHARACTER(LEN=64) :: abaqus_name = ""
        INTEGER(i4) :: category = 0
        CHARACTER(LEN=256) :: description = ""
        CHARACTER(LEN=128) :: parser_module = ""
        CHARACTER(LEN=128) :: unified_parse_proc = ""
        LOGICAL :: is_linear = .FALSE.
        LOGICAL :: is_dynamic = .FALSE.
        LOGICAL :: supports_nonlinear = .TRUE.
        LOGICAL :: supports_contact = .TRUE.
        LOGICAL :: supports_parallel = .TRUE.
        CHARACTER(LEN=64) :: default_algorithm = ""
        REAL(wp) :: default_tolerance = 1.0e-6_wp
        INTEGER(i4) :: default_max_iterations = 100
    END TYPE ABAQUS_SolverRegistryEntry

    !=============================================================================
    ! Complete ABAQUS Solver Registry (精简�?- �?3 种核心分�?
    !=============================================================================
    TYPE(ABAQUS_SolverRegistryEntry), PARAMETER, PUBLIC :: ABAQUS_SOLVERS(3) = [ &
        ! 1. Static Solver - 隐式静力分析
        ABAQUS_SolverRegistryEntry( &
            ABAQUS_SOLVER_STATIC, &
            "STATIC", &
            "STATIC", &
            ABAQUS_SOLVER_STATIC, &
            "General static analysis for linear and nonlinear problems (Newton-Raphson)", &
            "", &  ! 解析器已移除，直接使�?RT_SolvNonlin
            "", &
            .FALSE., .FALSE., .TRUE(), .TRUE(), .TRUE(), &
            "NEWTON_RAPHSON", 1.0e-8_wp, 500 &
        ), &
        ! 2. Dynamic Explicit Solver - 显式动力分析
        ABAQUS_SolverRegistryEntry( &
            ABAQUS_SOLVER_DYNAMIC_EXPLICIT, &
            "DYNAMIC, EXPLICIT", &
            "DYNAMIC EXPLICIT", &
            ABAQUS_SOLVER_DYNAMIC_EXPLICIT, &
            "Explicit dynamic analysis for transient problems (Central Difference)", &
            "", &  ! 解析器已移除，直接使�?RT_DynExpl_Runner
            "", &
            .FALSE., .TRUE(), .TRUE(), .TRUE(), .TRUE(), &
            "CENTRAL_DIFFERENCE", 1.0e-6_wp, 1000000 &
        ), &
        ! 3. Dynamic Implicit Solver - 隐式动力分析
        ABAQUS_SolverRegistryEntry( &
            ABAQUS_SOLVER_DYNAMIC_IMPLICIT, &
            "DYNAMIC, IMPLICIT", &
            "DYNAMIC IMPLICIT", &
            ABAQUS_SOLVER_DYNAMIC_IMPLICIT, &
            "Implicit dynamic analysis for transient problems (Newmark/HHT-alpha)", &
            "", &  ! 解析器已移除，直接使�?RT_DynImpl_Runner
            "", &
            .FALSE., .TRUE(), .TRUE(), .TRUE(), .TRUE(), &
            "NEWMARK_BETA", 1.0e-6_wp, 500 &
        ) &
    ]

    !=============================================================================
    ! Public Interfaces
    !=============================================================================
    PUBLIC :: ABAQUS_SOLVERS
    PUBLIC :: GetSolverById
    PUBLIC :: GetSolverByKeyword
    PUBLIC :: GetSolverCount
    PUBLIC :: ValidateSolverConfig
    PUBLIC :: PrintSolverRegistry
    PUBLIC :: GetSolverCapabilities

CONTAINS

    FUNCTION GetSolverById(solver_id) RESULT(solver_entry)
        INTEGER(i4), INTENT(IN) :: solver_id
        TYPE(ABAQUS_SolverRegistryEntry) :: solver_entry
        
        INTEGER(i4) :: i
        
        solver_entry = ABAQUS_SOLVERS(1)  ! Default
        DO i = 1, SIZE(ABAQUS_SOLVERS)
            IF (ABAQUS_SOLVERS(i)%solver_id == solver_id) THEN
                solver_entry = ABAQUS_SOLVERS(i)
                RETURN
            END IF
        END DO
    END FUNCTION GetSolverById

    FUNCTION GetSolverByKeyword(keyword) RESULT(solver_entry)
        CHARACTER(LEN=*), INTENT(IN) :: keyword
        TYPE(ABAQUS_SolverRegistryEntry) :: solver_entry
        
        INTEGER(i4) :: i
        CHARACTER(LEN=64) :: keyword_upper, solver_keyword_upper
        
        keyword_upper = keyword
        CALL to_upper(keyword_upper)
        
        solver_entry = ABAQUS_SOLVERS(1)  ! Default
        DO i = 1, SIZE(ABAQUS_SOLVERS)
            solver_keyword_upper = ABAQUS_SOLVERS(i)%abaqus_keyword
            CALL to_upper(solver_keyword_upper)
            
            IF (TRIM(keyword_upper) == TRIM(solver_keyword_upper)) THEN
                solver_entry = ABAQUS_SOLVERS(i)
                RETURN
            END IF
        END DO
    END FUNCTION GetSolverByKeyword

    SUBROUTINE GetSolverCapabilities(solver_id, is_linear, is_dynamic, supports_nonlinear, supports_contact, supports_parallel)
        INTEGER(i4), INTENT(IN) :: solver_id
        LOGICAL, INTENT(OUT) :: is_linear, is_dynamic, supports_nonlinear, supports_contact, supports_parallel
        
        TYPE(ABAQUS_SolverRegistryEntry) :: solver_entry
        
        solver_entry = GetSolverById(solver_id)
        is_linear = solver_entry%is_linear
        is_dynamic = solver_entry%is_dynamic
        supports_nonlinear = solver_entry%supports_nonlinear
        supports_contact = solver_entry%supports_contact
        supports_parallel = solver_entry%supports_parallel
    END SUBROUTINE GetSolverCapabilities

    FUNCTION GetSolverCount() RESULT(count)
        INTEGER(i4) :: count
        
        count = SIZE(ABAQUS_SOLVERS)
    END FUNCTION GetSolverCount

    FUNCTION LOGICAL_TO_STRING(log_val) RESULT(str_val)
        LOGICAL, INTENT(IN) :: log_val
        CHARACTER(LEN=5) :: str_val
        
        IF (log_val) THEN
            str_val = "TRUE "
        ELSE
            str_val = "FALSE"
        END IF
    END FUNCTION LOGICAL_TO_STRING

    SUBROUTINE PrintSolverRegistry(unit)
        INTEGER(i4), INTENT(IN), OPTIONAL :: unit
        INTEGER(i4) :: out_unit, i
        
        out_unit = 6_i4
        IF (PRESENT(unit)) out_unit = unit
        
        WRITE(out_unit, '(/,A)') "=== ABAQUS Solver Registry ==="
        WRITE(out_unit, '(A,I0,A)') "Total Solvers: ", SIZE(ABAQUS_SOLVERS)
        WRITE(out_unit, '(A)') ""
        
        DO i = 1, SIZE(ABAQUS_SOLVERS)
            WRITE(out_unit, '(A,I0,A)') "Solver ", i, ": ", TRIM(ABAQUS_SOLVERS(i)%abaqus_name)
            WRITE(out_unit, '(A,A)') "  Keyword: ", TRIM(ABAQUS_SOLVERS(i)%abaqus_keyword)
            WRITE(out_unit, '(A,A)') "  Description: ", TRIM(ABAQUS_SOLVERS(i)%cfg%description)
            WRITE(out_unit, '(A,A)') "  Linear: ", LOGICAL_TO_STRING(ABAQUS_SOLVERS(i)%is_linear)
            WRITE(out_unit, '(A,A)') "  Dynamic: ", LOGICAL_TO_STRING(ABAQUS_SOLVERS(i)%is_dynamic)
            WRITE(out_unit, '(A,A)') "  Contact: ", LOGICAL_TO_STRING(ABAQUS_SOLVERS(i)%supports_contact)
            WRITE(out_unit, '(A,A)') "  Algorithm: ", TRIM(ABAQUS_SOLVERS(i)%default_algorithm)
            WRITE(out_unit, '(A)') ""
        END DO
        
        WRITE(out_unit, '(A)') "================================"
    END SUBROUTINE PrintSolverRegistry

    SUBROUTINE to_upper(str)
        CHARACTER(LEN=*), INTENT(INOUT) :: str
        INTEGER(i4) :: i, len_str, diff
        
        diff = ICHAR('a') - ICHAR('A')
        len_str = LEN(str)
        DO i = 1, len_str
            IF (str(i:i) >= 'a' .AND. str(i:i) <= 'z') THEN
                str(i:i) = CHAR(ICHAR(str(i:i)) - diff)
            END IF
        END DO
    END SUBROUTINE to_upper

    SUBROUTINE ValidateSolverConfig(solver_type, tolerance, max_iterations, is_valid, error_msg)
        INTEGER(i4), INTENT(IN) :: solver_type
        REAL(wp), INTENT(IN) :: tolerance
        INTEGER(i4), INTENT(IN) :: max_iterations
        LOGICAL, INTENT(OUT) :: is_valid
        CHARACTER(LEN=*), INTENT(OUT) :: error_msg
        
        is_valid = .FALSE.
        error_msg = ""
        
        ! 仅验证三种核心分析类�?
        IF (solver_type < ABAQUS_SOLVER_STATIC .OR. &
            solver_type > ABAQUS_SOLVER_DYNAMIC_IMPLICIT) THEN
            error_msg = "Invalid solver type ID - only STATIC/DYNAMIC_EXPLICIT/DYNAMIC_IMPLICIT supported"
            RETURN
        END IF
        
        IF (tolerance <= 0.0_wp) THEN
            error_msg = "Tolerance must be positive"
            RETURN
        END IF
        
        IF (max_iterations <= 0) THEN
            error_msg = "Maximum iterations must be positive"
            RETURN
        END IF
        
        is_valid = .TRUE.
    END SUBROUTINE ValidateSolverConfig
END module RT_Solv_ABAQUSReg