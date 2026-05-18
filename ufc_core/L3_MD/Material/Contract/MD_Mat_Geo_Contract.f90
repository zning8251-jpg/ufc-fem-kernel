!===============================================================================
! MODULE: MD_MatPlgGeotech_Def
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Geotechnical plasticity Desc types + keyword parsers.
!         Drucker-Prager & Mohr-Coulomb models.
!         **W1**?**DPProperties** ? + ?? ? **`props`** / **Populate**?L4 **PH_MatGeo_*** ? **`desc%props`**?**MD_MAT_GEO_***??
!===============================================================================
MODULE MD_Mat_Geo_Contract
    USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_OK, &
        init_error_status, uf_set_error_status
    USE IF_Prec_Core, ONLY: i4, wp
    USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, UF_Model
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_MAX_NAME_LEN, KW_MAX_VALUE_LEN
    IMPLICIT NONE
    PRIVATE

    ! --- from MD_MAT_DP ---
    !=============================================================================
    ! Shear Criterion Types
    !=============================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DP_SHEAR_LINEAR = 1
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DP_SHEAR_HYPERBOLIC = 2
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DP_SHEAR_EXPONENT = 3

    !=============================================================================
    ! Drucker-Prager Properties Data Type
    !=============================================================================
    TYPE, PUBLIC, EXTENDS(DescBase) :: DPProperties
        ! Shear criterion type
        INTEGER(i4) :: shearCriterion = MD_MAT_DP_SHEAR_LINEAR

        ! Linear shear criterion parameters
        REAL(wp) :: frictionAngle_beta = 0.0_wp  ! Friction angle ï¿?(degrees)
        REAL(wp) :: flowStressRatio_kappa = 0.778_wp  ! Flow stress ratio ï¿?(0.778-1.0)
        REAL(wp) :: dilationAngle_psi = 0.0_wp   ! Dilation angle ï¿?(degrees)

        ! Hyperbolic shear criterion parameters
        REAL(wp) :: frictionAngle_highPressure = 0.0_wp  ! High pressure friction angle
        REAL(wp) :: initialTensileStrength = 0.0_wp     ! Initial tensile strength p_t|_0
        REAL(wp) :: dilationAngle_highPressure = 0.0_wp ! High pressure dilation angle

        ! Exponent form parameters
        REAL(wp) :: materialConstant_a = 0.0_wp  ! Mat constant a
        REAL(wp) :: exponent_b = 1.0_wp          ! Exponent b (?1)

        ! Flow potential eccentricity (for HYPERBOLIC/EXPONENT FORM)
        REAL(wp) :: eccentricity = 0.1_wp

        ! Temperature and field variable dependencies
        INTEGER(i4) :: dependencies = 0
        REAL(wp), ALLOCATABLE :: tempData(:)
        REAL(wp), ALLOCATABLE :: fieldVarData(:,:)
        INTEGER(i4) :: nDataPoints = 0
    CONTAINS
        PROCEDURE, PUBLIC :: Init => DPProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid => DPProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => DPProperties_Clear
        PROCEDURE, PUBLIC :: ComputeYieldFunction => DPProperties_ComputeYieldFunction
    END TYPE DPProperties


    !=============================================================================
    ! Drucker-Prager Properties Manager
    !=============================================================================
    TYPE, PUBLIC :: DPPropertiesManager
        INTEGER(i4) :: numProperties = 0_i4
        TYPE(DPProperties), ALLOCATABLE :: properties(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => DPPropertiesManager_Add
        PROCEDURE, PUBLIC :: Find => DPPropertiesManager_Find
        PROCEDURE, PUBLIC :: Clear => DPPropertiesManager_Clear
    END TYPE DPPropertiesManager

    TYPE, PUBLIC, EXTENDS(DPProperties) :: DruckerPragerProperties
    END TYPE DruckerPragerProperties

    PUBLIC :: DPProperties, DruckerPragerProperties, DPPropertiesManager
    PUBLIC :: MD_MAT_DP_SHEAR_LINEAR, MD_MAT_DP_SHEAR_HYPERBOLIC, MD_MAT_DP_SHEAR_EXPONENT
    PUBLIC :: MD_Mat_DruckerPrager_Unified_Configure
    PUBLIC :: MD_Mat_DruckerPrager_Unified_Parse
    PUBLIC :: Parse_DRUCKER_PRAGER_Keyword
    PUBLIC :: Valid_DRUCKER_PRAGER_Keyword
    PUBLIC :: Valid_DRUCKER_PRAGER_Mat
    PUBLIC :: Validate_DRUCKER_PRAGER_PhysicalValues

    ! --- from MD_MAT_MC ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: MCProperties
        ! Basic parameters
        REAL(wp) :: frictionAngle_phi = 0.0_wp  ! Friction angle ï¿?(degrees)
        REAL(wp) :: cohesion_c = 0.0_wp          ! Cohesion c
        REAL(wp) :: dilationAngle_psi = 0.0_wp  ! Dilation angle ï¿?(degrees)

        ! Tension cutoff
        REAL(wp) :: tensionCutoff = 0.0_wp      ! Tension cutoff stress (Rankine surface)
        LOGICAL :: useTensionCutoff = .FALSE.

        ! Apex smoothing
        LOGICAL :: useApexSmoothing = .FALSE.
        REAL(wp) :: smoothingParameter = 0.0_wp

        ! Temperature and field variable dependencies
        INTEGER(i4) :: dependencies = 0
        REAL(wp), ALLOCATABLE :: tempData(:)
        REAL(wp), ALLOCATABLE :: fieldVarData(:,:)
        INTEGER(i4) :: nDataPoints = 0
    CONTAINS
        PROCEDURE, PUBLIC :: Init => MCProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid => MCProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => MCProperties_Clear
        PROCEDURE, PUBLIC :: ComputeYieldFunction => MCProperties_ComputeYieldFunction
    END TYPE MCProperties


    TYPE, PUBLIC :: MCPropertiesManager
        INTEGER(i4) :: numProperties = 0_i4
        TYPE(MCProperties), ALLOCATABLE :: properties(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => MCPropertiesManager_Add
        PROCEDURE, PUBLIC :: Find => MCPropertiesManager_Find
        PROCEDURE, PUBLIC :: Clear => MCPropertiesManager_Clear
    END TYPE MCPropertiesManager

    TYPE, PUBLIC, EXTENDS(MCProperties) :: MohrCoulombProperties
    END TYPE MohrCoulombProperties

    PUBLIC :: MCProperties, MohrCoulombProperties, MCPropertiesManager
    PUBLIC :: MD_Mat_MohrCoulomb_Unified_Configure
    PUBLIC :: MD_Mat_MohrCoulomb_Unified_Parse
    PUBLIC :: Parse_MOHR_COULOMB_Keyword
    PUBLIC :: Valid_MOHR_COULOMB_Keyword
    PUBLIC :: Valid_MOHR_COULOMB_Mat
    PUBLIC :: Validate_MOHR_COULOMB_PhysicalValues

CONTAINS

    SUBROUTINE DPProperties_Init_Base(this)
        CLASS(DPProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::DRUCKERPRAGER'
    END SUBROUTINE DPProperties_Init_Base

    SUBROUTINE DPProperties_Init(this, beta, kappa, psi, status)
        CLASS(DPProperties), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: beta, kappa, psi
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        CALL this%Init()

        IF (beta < 0.0_wp .OR. beta > 90.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Friction angle must be in [0, 90] degrees")
            RETURN
        END IF

        IF (kappa < 0.778_wp .OR. kappa > 1.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Flow stress ratio must be in [0.778, 1.0] range")
            RETURN
        END IF

        IF (psi < 0.0_wp .OR. psi > 90.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Dilation angle must be in [0, 90] degrees")
            RETURN
        END IF

        this%frictionAngle_beta = beta
        this%flowStressRatio_kappa = kappa
        this%dilationAngle_psi = psi
        this%shearCriterion = MD_MAT_DP_SHEAR_LINEAR

    END SUBROUTINE DPProperties_Init

    FUNCTION DPProperties_Valid_Fn(this) RESULT(ok)
        CLASS(DPProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .FALSE.
        IF (this%shearCriterion == MD_MAT_DP_SHEAR_LINEAR) THEN
            IF (this%frictionAngle_beta < 0.0_wp .OR. this%frictionAngle_beta > 90.0_wp) RETURN
            IF (this%flowStressRatio_kappa < 0.778_wp .OR. this%flowStressRatio_kappa > 1.0_wp) RETURN
        END IF
        IF (this%shearCriterion == MD_MAT_DP_SHEAR_EXPONENT) THEN
            IF (this%exponent_b < 1.0_wp) RETURN
        END IF
        ok = .TRUE.
    END FUNCTION DPProperties_Valid_Fn

    SUBROUTINE DPProperties_Clear(this)
        CLASS(DPProperties), INTENT(INOUT) :: this
        this%shearCriterion = MD_MAT_DP_SHEAR_LINEAR
        this%frictionAngle_beta = 0.0_wp
        this%flowStressRatio_kappa = 0.778_wp
        this%dilationAngle_psi = 0.0_wp
        this%frictionAngle_highPressure = 0.0_wp
        this%initialTensileStrength = 0.0_wp
        this%dilationAngle_highPressure = 0.0_wp
        this%materialConstant_a = 0.0_wp
        this%exponent_b = 1.0_wp
        this%eccentricity = 0.1_wp
        this%dependencies = 0
        this%nDataPoints = 0
        IF (ALLOCATED(this%tempData)) DEALLOCATE(this%tempData)
        IF (ALLOCATED(this%fieldVarData)) DEALLOCATE(this%fieldVarData)
    END SUBROUTINE DPProperties_Clear

    !=============================================================================
    ! Compute yield function: f = éˆ­æ¬½?+ ä¼ªè·¯I?- k
    !=============================================================================
    FUNCTION DPProperties_ComputeYieldFunction(this, I1, J2) RESULT(f)
        CLASS(DPProperties), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: I1, J2  ! First invariant and second deviatoric invariant
        REAL(wp) :: f

        REAL(wp) :: alpha, k, beta_rad

        IF (this%shearCriterion == MD_MAT_DP_SHEAR_LINEAR) THEN
            ! Compute ï¿?and k from friction angle and flow stress ratio
            beta_rad = this%frictionAngle_beta * 3.141592653589793_wp / 180.0_wp
            alpha = 2.0_wp * SIN(beta_rad) / (3.0_wp - SIN(beta_rad))
            k = 6.0_wp * COS(beta_rad) / (3.0_wp - SIN(beta_rad))  ! Simplified
            f = SQRT(J2) + alpha * I1 - k
        ELSE
            ! Simplified: use linear form
            f = SQRT(J2) + 0.1_wp * I1 - 1.0e6_wp
        END IF

    END FUNCTION DPProperties_ComputeYieldFunction

    !=============================================================================
    ! DPPropertiesManager Procedures
    !=============================================================================

    SUBROUTINE DPPropertiesManager_Add(this, prop, status)
        CLASS(DPPropertiesManager), INTENT(INOUT) :: this
        TYPE(DPProperties), INTENT(IN) :: prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(DPProperties), ALLOCATABLE :: temp_props(:)
        INTEGER(i4) :: new_id

        CALL init_error_status(status)

        IF (.NOT. ALLOCATED(this%properties)) THEN
            ALLOCATE(this%properties(10))
            this%numProperties = 0
        ELSE IF (this%numProperties >= SIZE(this%properties)) THEN
            ALLOCATE(temp_props(SIZE(this%properties) * 2))
            temp_props(1:this%numProperties) = this%properties
            CALL MOVE_ALLOC(temp_props, this%properties)
        END IF

        new_id = this%numProperties + 1
        this%numProperties = new_id
        this%properties(new_id) = prop

    END SUBROUTINE DPPropertiesManager_Add

    FUNCTION DPPropertiesManager_Find(this, index) RESULT(prop)
        CLASS(DPPropertiesManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: index
        TYPE(DPProperties), POINTER :: prop

        prop => NULL()
        IF (.NOT. ALLOCATED(this%properties)) RETURN
        IF (index < 1 .OR. index > this%numProperties) RETURN
        prop => this%properties(index)

    END FUNCTION DPPropertiesManager_Find

    SUBROUTINE DPProperties_Clear(this)
        CLASS(DPPropertiesManager), INTENT(INOUT) :: this
        INTEGER(i4) :: i

        IF (ALLOCATED(this%properties)) THEN
            DO i = 1, this%numProperties
                CALL this%properties(i)%Clear()
            END DO
            DEALLOCATE(this%properties)
        END IF
        this%numProperties = 0
    END SUBROUTINE DPPropertiesManager_Clear



    SUBROUTINE md_mat_get_param_value(ast_node, param_name, param_value)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        CHARACTER(LEN=*), INTENT(IN) :: param_name
        CHARACTER(LEN=*), INTENT(OUT) :: param_value

        INTEGER(i4) :: i
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: key

        param_value = ""
        DO i = 1, ast_node%param_count
            key = TRIM(ast_node%params(i)%name)
            IF (TRIM(key) == TRIM(param_name)) THEN
                param_value = TRIM(ast_node%params(i)%value)
                RETURN
            END IF
        END DO

    END SUBROUTINE md_mat_get_param_value

    SUBROUTINE MD_Mat_Dr_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 17250-17299
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = 'MD_Mat_DruckerPrager_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Mat_DruckerPrager_Unified_Configure

    SUBROUTINE MD_Mat_Dr_Un_Parse(material_type, ast_node, druckerPrager, material_name, status)
        !! Unified parse: material_type 'MD_MAT_DRUCKER_PRAGER' -> Parse_DRUCKER_PRAGER_Keyword.
        !! Task: 17200-17249
        CHARACTER(LEN=*), INTENT(IN) :: material_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(DPProperties), INTENT(OUT) :: druckerPrager
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        IF (TRIM(material_type) == 'MD_MAT_DRUCKER_PRAGER' .OR. TRIM(material_type) == 'DRUCKER PRAGER') THEN
            CALL Parse_DRUCKER_PRAGER_Keyword(ast_node, druckerPrager, material_name, status)
        ELSE
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = 'MD_Mat_DruckerPrager_Unified_Parse: unsupported material_type ' // TRIM(material_type)
        END IF
    END SUBROUTINE MD_Mat_DruckerPrager_Unified_Parse

    SUBROUTINE Parse_DRUCKER_PRAGER_Keyword(ast_node, druckerPrager, material_name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(DPProperties), INTENT(OUT) :: druckerPrager
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: shear_criterion_str, eccentricity_str, dependencies_str
        INTEGER(i4) :: shear_criterion, dependencies, i, data_line_count
        REAL(wp) :: beta, kappa, psi, eccentricity

        CALL init_error_status(status)

        ! Init
        CALL druckerPrager%Clear()

        ! Parse SHEAR CRITERION parameter
        CALL md_mat_get_param_value(ast_node, "SHEAR CRITERION", shear_criterion_str)
        IF (LEN_TRIM(shear_criterion_str) == 0) THEN
            shear_criterion = MD_MAT_DP_SHEAR_LINEAR
        ELSE
            SELECT CASE (TRIM(shear_criterion_str))
            CASE ("LINEAR")
                shear_criterion = MD_MAT_DP_SHEAR_LINEAR
            CASE ("HYPERBOLIC")
                shear_criterion = MD_MAT_DP_SHEAR_HYPERBOLIC
            CASE ("EXPONENT FORM", "EXPONENT")
                shear_criterion = MD_MAT_DP_SHEAR_EXPONENT
            CASE DEFAULT
                shear_criterion = MD_MAT_DP_SHEAR_LINEAR
            END SELECT
        END IF
        druckerPrager%shearCriterion = shear_criterion

        ! Parse ECCENTRICITY parameter
        CALL md_mat_get_param_value(ast_node, "ECCENTRICITY", eccentricity_str)
        IF (LEN_TRIM(eccentricity_str) > 0) THEN
            READ(eccentricity_str, *, IOSTAT=i) eccentricity
            IF (i == 0) THEN
                druckerPrager%eccentricity = eccentricity
            END IF
        END IF

        ! Parse DEPENDENCIES parameter
        CALL md_mat_get_param_value(ast_node, "DEPENDENCIES", dependencies_str)
        IF (LEN_TRIM(dependencies_str) > 0) THEN
            READ(dependencies_str, *, IOSTAT=i) dependencies
            IF (i /= 0) dependencies = 0
        ELSE
            dependencies = 0
        END IF
        druckerPrager%dependencies = dependencies

        ! Parse data lines
        data_line_count = ast_node%data_line_count
        IF (data_line_count < 1) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "*DRUCKER PRAGER requires at least one data line")
            RETURN
        END IF

        ! Parse parameters based on shear criterion type
        IF (shear_criterion == MD_MAT_DP_SHEAR_LINEAR) THEN
            ! Linear: beta, kappa, psi
            IF (ast_node%data_lines(1)%col_count < 3) THEN
                CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                    "*DRUCKER PRAGER LINEAR requires: beta, kappa, psi")
                RETURN
            END IF
            beta = ast_node%data_lines(1)%real_values(1)
            kappa = ast_node%data_lines(1)%real_values(2)
            psi = ast_node%data_lines(1)%real_values(3)
            CALL druckerPrager%Init(beta, kappa, psi, status)
            IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

        ELSE IF (shear_criterion == MD_MAT_DP_SHEAR_HYPERBOLIC) THEN
            ! Hyperbolic: beta_high, p_t0, unused, psi_high
            IF (ast_node%data_lines(1)%col_count < 4) THEN
                CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                    "*DRUCKER PRAGER HYPERBOLIC requires at least 4 parameters")
                RETURN
            END IF
            druckerPrager%frictionAngle_highPressure = ast_node%data_lines(1)%real_values(1)
            druckerPrager%initialTensileStrength = ast_node%data_lines(1)%real_values(2)
            druckerPrager%dilationAngle_highPressure = ast_node%data_lines(1)%real_values(4)

        ELSE IF (shear_criterion == MD_MAT_DP_SHEAR_EXPONENT) THEN
            ! Exponent form: a, b, unused, psi_high
            IF (ast_node%data_lines(1)%col_count < 4) THEN
                CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                    "*DRUCKER PRAGER EXPONENT FORM requires at least 4 parameters")
                RETURN
            END IF
            druckerPrager%materialConstant_a = ast_node%data_lines(1)%real_values(1)
            druckerPrager%exponent_b = ast_node%data_lines(1)%real_values(2)
            druckerPrager%dilationAngle_highPressure = ast_node%data_lines(1)%real_values(4)
        END IF

        ! TODO: Parse temperature and field variable dependencies if present

        ! Valid
        IF (.NOT. druckerPrager%Valid()) THEN
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = "Drucker-Prager validation failed"
        ELSE
            status%status_code = MD_MAT_STATUS_OK
        END IF

    END SUBROUTINE Parse_DRUCKER_PRAGER_Keyword


    SUBROUTINE Va_DR_PR_PhysicalValues(druckerPrager, status)
        TYPE(DPProperties), INTENT(IN) :: druckerPrager
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (druckerPrager%shearCriterion == 1) THEN
            IF (druckerPrager%frictionAngle_beta < 0.0_wp .OR. &
                druckerPrager%frictionAngle_beta > 60.0_wp) THEN
                CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                    "Friction angle out of reasonable range (0 to 60 degrees)")
                RETURN
            END IF
        END IF

    END SUBROUTINE Validate_DRUCKER_PRAGER_PhysicalValues

    SUBROUTINE Valid_DRUCKER_PRAGER_Keyword(druckerPrager, material_name, model, status)
        TYPE(DPProperties), INTENT(IN) :: druckerPrager
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Basic validation
        IF (.NOT. druckerPrager%Valid()) THEN
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = "Drucker-Prager validation failed"
            RETURN
        END IF
        status%status_code = MD_MAT_STATUS_OK

        ! Valid Mat exists (if model provided)
        IF (PRESENT(model)) THEN
            CALL Valid_DRUCKER_PRAGER_Mat(material_name, model, status)
            IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
        END IF

        ! Valid physical value ranges
        CALL Validate_DRUCKER_PRAGER_PhysicalValues(druckerPrager, status)

    END SUBROUTINE Valid_DRUCKER_PRAGER_Keyword

    SUBROUTINE Valid_DRUCKER_PRAGER_Mat(material_name, model, status)
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! TODO: Implement Mat validation when Mat system is available
        IF (LEN_TRIM(material_name) == 0) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Mat name must be specified for DRUCKER PRAGER")
        END IF

    END SUBROUTINE Valid_DRUCKER_PRAGER_Mat
    SUBROUTINE MCProperties_Init_Base(this)
        CLASS(MCProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::MOHRCOULOMB'
    END SUBROUTINE MCProperties_Init_Base

    SUBROUTINE MCProperties_Init(this, phi, c, psi, status)
        CLASS(MCProperties), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: phi, c, psi
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        CALL this%Init()

        IF (phi < 0.0_wp .OR. phi > 90.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Friction angle must be in [0, 90] degrees")
            RETURN
        END IF

        IF (c < 0.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Cohesion must be non-negative")
            RETURN
        END IF

        IF (psi < 0.0_wp .OR. psi > 90.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Dilation angle must be in [0, 90] degrees")
            RETURN
        END IF

        this%frictionAngle_phi = phi
        this%cohesion_c = c
        this%dilationAngle_psi = psi
        this%useTensionCutoff = .FALSE.
        this%useApexSmoothing = .FALSE.

    END SUBROUTINE MCProperties_Init

    FUNCTION MCProperties_Valid_Fn(this) RESULT(ok)
        CLASS(MCProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .FALSE.
        IF (this%frictionAngle_phi < 0.0_wp .OR. this%frictionAngle_phi > 90.0_wp) RETURN
        IF (this%cohesion_c < 0.0_wp) RETURN
        IF (this%dilationAngle_psi < 0.0_wp .OR. this%dilationAngle_psi > 90.0_wp) RETURN

        IF (this%dilationAngle_psi > this%frictionAngle_phi) RETURN
        ok = .TRUE.
    END FUNCTION MCProperties_Valid_Fn

    SUBROUTINE MCProperties_Clear(this)
        CLASS(MCProperties), INTENT(INOUT) :: this
        this%frictionAngle_phi = 0.0_wp
        this%cohesion_c = 0.0_wp
        this%dilationAngle_psi = 0.0_wp
        this%tensionCutoff = 0.0_wp
        this%useTensionCutoff = .FALSE.
        this%useApexSmoothing = .FALSE.
        this%smoothingParameter = 0.0_wp
        this%dependencies = 0
        this%nDataPoints = 0
        IF (ALLOCATED(this%tempData)) DEALLOCATE(this%tempData)
        IF (ALLOCATED(this%fieldVarData)) DEALLOCATE(this%fieldVarData)
    END SUBROUTINE MCProperties_Clear

    !=============================================================================
    ! Compute yield function: f = Iéˆ§ä¼®ç©in(ï¿?/3 + éˆ­æ¬½éˆ§å®ç©‚sin(ï¿?è·¯sin(ï¿? + cos(ï¿?/?] - cè·¯cos(ï¿?
    !=============================================================================
    FUNCTION MCProperties_ComputeYieldFunction(this, I1, J2, theta) RESULT(f)
        CLASS(MCProperties), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: I1, J2, theta  ! First invariant, second deviatoric invariant, Lode angle
        REAL(wp) :: f

        REAL(wp) :: phi_rad, sqrt3, term1, term2

        phi_rad = this%frictionAngle_phi * 3.141592653589793_wp / 180.0_wp
        sqrt3 = SQRT(3.0_wp)

        term1 = I1 * SIN(phi_rad) / 3.0_wp
        term2 = SQRT(J2) * (SIN(theta) * SIN(phi_rad) + COS(theta) / sqrt3)
        f = term1 + term2 - this%cohesion_c * COS(phi_rad)

    END FUNCTION MCProperties_ComputeYieldFunction

    !=============================================================================
    ! MCPropertiesManager Procedures
    !=============================================================================

    SUBROUTINE MCPropertiesManager_Add(this, prop, status)
        CLASS(MCPropertiesManager), INTENT(INOUT) :: this
        TYPE(MCProperties), INTENT(IN) :: prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(MCProperties), ALLOCATABLE :: temp_props(:)
        INTEGER(i4) :: new_id

        CALL init_error_status(status)

        IF (.NOT. ALLOCATED(this%properties)) THEN
            ALLOCATE(this%properties(10))
            this%numProperties = 0
        ELSE IF (this%numProperties >= SIZE(this%properties)) THEN
            ALLOCATE(temp_props(SIZE(this%properties) * 2))
            temp_props(1:this%numProperties) = this%properties
            CALL MOVE_ALLOC(temp_props, this%properties)
        END IF

        new_id = this%numProperties + 1
        this%numProperties = new_id
        this%properties(new_id) = prop

    END SUBROUTINE MCPropertiesManager_Add

    FUNCTION MCPropertiesManager_Find(this, index) RESULT(prop)
        CLASS(MCPropertiesManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: index
        TYPE(MCProperties), POINTER :: prop

        prop => NULL()
        IF (.NOT. ALLOCATED(this%properties)) RETURN
        IF (index < 1 .OR. index > this%numProperties) RETURN
        prop => this%properties(index)

    END FUNCTION MCPropertiesManager_Find

    SUBROUTINE MCPropertiesManager_Clear(this)
        CLASS(MCPropertiesManager), INTENT(INOUT) :: this
        INTEGER(i4) :: i

        IF (ALLOCATED(this%properties)) THEN
            DO i = 1, this%numProperties
                CALL this%properties(i)%Clear()
            END DO
            DEALLOCATE(this%properties)
        END IF
        this%numProperties = 0
    END SUBROUTINE MCPropertiesManager_Clear
    SUBROUTINE MD_Mat_Mo_Un_Configure(operation, status)
        !! Unified configure (placeholder). Task: 17100-17199
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = 'MD_Mat_MohrCoulomb_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Mat_MohrCoulomb_Unified_Configure

    SUBROUTINE MD_Mat_Mo_Un_Parse(material_type, ast_node, mohrCoulomb, material_name, status)
        !! Unified parse entry: material_type 'MD_MAT_MOHR_COULOMB' -> Parse_MOHR_COULOMB_Keyword.
        !! Task: 17000-17099
        CHARACTER(LEN=*), INTENT(IN) :: material_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(MCProperties), INTENT(OUT) :: mohrCoulomb
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        IF (TRIM(material_type) == 'MD_MAT_MOHR_COULOMB' .OR. TRIM(material_type) == 'MOHR COULOMB') THEN
            CALL Parse_MOHR_COULOMB_Keyword(ast_node, mohrCoulomb, material_name, status)
        ELSE
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = 'MD_Mat_MohrCoulomb_Unified_Parse: unsupported material_type ' // TRIM(material_type)
        END IF
    END SUBROUTINE MD_Mat_MohrCoulomb_Unified_Parse

    SUBROUTINE Parse_MOHR_COULOMB_Keyword(ast_node, mohrCoulomb, material_name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(MCProperties), INTENT(OUT) :: mohrCoulomb
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: dependencies_str
        INTEGER(i4) :: dependencies, i, data_line_count
        REAL(wp) :: phi, c, psi, tension_cutoff

        CALL init_error_status(status)

        ! Init
        CALL mohrCoulomb%Clear()

        ! Parse DEPENDENCIES parameter
        CALL md_mat_get_param_value(ast_node, "DEPENDENCIES", dependencies_str)
        IF (LEN_TRIM(dependencies_str) > 0) THEN
            READ(dependencies_str, *, IOSTAT=i) dependencies
            IF (i /= 0) dependencies = 0
        ELSE
            dependencies = 0
        END IF
        mohrCoulomb%dependencies = dependencies

        ! Parse data lines
        data_line_count = ast_node%data_line_count
        IF (data_line_count < 1) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "*MOHR COULOMB requires at least one data line")
            RETURN
        END IF

        ! Parse first data line: phi, c, psi, optional tension_cutoff
        IF (ast_node%data_lines(1)%col_count < 3) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "*MOHR COULOMB data line requires: phi, c, psi")
            RETURN
        END IF

        phi = ast_node%data_lines(1)%real_values(1)
        c = ast_node%data_lines(1)%real_values(2)
        psi = ast_node%data_lines(1)%real_values(3)

        IF (ast_node%data_lines(1)%col_count >= 4) THEN
            tension_cutoff = ast_node%data_lines(1)%real_values(4)
            mohrCoulomb%tensionCutoff = tension_cutoff
            mohrCoulomb%useTensionCutoff = .TRUE.
        END IF

        CALL mohrCoulomb%Init(phi, c, psi, status)
        IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

        ! TODO: Parse temperature and field variable dependencies if present

        ! Valid
        IF (.NOT. mohrCoulomb%Valid()) THEN
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = "Mohr-Coulomb validation failed"
        ELSE
            status%status_code = MD_MAT_STATUS_OK
        END IF

    END SUBROUTINE Parse_MOHR_COULOMB_Keyword


    SUBROUTINE Va_MO_CO_PhysicalValues(mohrCoulomb, status)
        TYPE(MCProperties), INTENT(IN) :: mohrCoulomb
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (mohrCoulomb%frictionAngle_phi < 0.0_wp .OR. &
            mohrCoulomb%frictionAngle_phi > 60.0_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Friction angle out of reasonable range (0 to 60 degrees)")
            RETURN
        END IF

        IF (mohrCoulomb%cohesion_c < 1.0e3_wp .OR. &
            mohrCoulomb%cohesion_c > 1.0e8_wp) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Cohesion out of reasonable range (1e3 to 1e8 Pa)")
            RETURN
        END IF

    END SUBROUTINE Validate_MOHR_COULOMB_PhysicalValues

    SUBROUTINE Valid_MOHR_COULOMB_Keyword(mohrCoulomb, material_name, model, status)
        TYPE(MCProperties), INTENT(IN) :: mohrCoulomb
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Basic validation
        IF (.NOT. mohrCoulomb%Valid()) THEN
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = "Mohr-Coulomb validation failed"
            RETURN
        END IF
        status%status_code = MD_MAT_STATUS_OK

        ! Valid Mat exists (if model provided)
        IF (PRESENT(model)) THEN
            CALL Valid_MOHR_COULOMB_Mat(material_name, model, status)
            IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
        END IF

        ! Valid physical value ranges
        CALL Validate_MOHR_COULOMB_PhysicalValues(mohrCoulomb, status)

    END SUBROUTINE Valid_MOHR_COULOMB_Keyword

    SUBROUTINE Valid_MOHR_COULOMB_Mat(material_name, model, status)
        CHARACTER(LEN=*), INTENT(IN) :: material_name
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! TODO: Implement Mat validation when Mat system is available
        IF (LEN_TRIM(material_name) == 0) THEN
            CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, &
                "Mat name must be specified for MOHR COULOMB")
        END IF

    END SUBROUTINE Valid_MOHR_COULOMB_Mat

END MODULE MD_Mat_Geo_Contract
