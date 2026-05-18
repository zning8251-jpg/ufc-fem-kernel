!===============================================================================
! MODULE: MD_Mat_Plast_JohnsonCook
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  Plastic family implementation -- MD_Mat_Plast_JohnsonCook.
! **W1**：**props** / **`MD_Mat_Desc`/`cfg%id`** / **Populate** → L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`** / **`PH_MatPlast_*`**（**206** / **MAT_PLAST_JOHNSON_C**）。
!===============================================================================
MODULE MD_Mat_Plast_JohnsonCook
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_PL
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init
  USE MD_KW_Def, ONLY: KW_ASTNodeType

  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JOHNSONCOOK_MAT = 206_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_JOHNSONCOOK_MAT_NAME = "Johnson-Cook Plasticity"

  ! Property indices (legacy UMAT props array; matches former Core layout)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_E = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_A = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_B = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_N = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_C = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_M = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_T_MELT = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_T_REF = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_PROP_EPS_DOT0 = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_JC_MIN_PROPS = 7_i4

  !---------------------------------------------------------------------------
  ! Keyword / DescBase Johnson-Cook (input deck; MD_KWMapper)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(DescBase) :: JCProperties
    CHARACTER(LEN=64) :: materialName = ""
    REAL(wp) :: A = 0.0_wp
    REAL(wp) :: B = 0.0_wp
    REAL(wp) :: n = 0.0_wp
    REAL(wp) :: C = 0.0_wp
    REAL(wp) :: m = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: Init => JCProperties_Init_Base
    PROCEDURE, PUBLIC :: Valid => JCProperties_Valid_Fn
    PROCEDURE, PUBLIC :: Clear => JCProperties_Clear
  END TYPE JCProperties

  TYPE, PUBLIC, EXTENDS(JCProperties) :: JohnsonCookProperties
  END TYPE JohnsonCookProperties

  !> @brief Johnson-Cook material descriptor (Desc category)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_MAT_JC_MatDesc
    ! Elastic parameters
    REAL(wp) :: E = 0.0_wp                 ! Young's modulus
    REAL(wp) :: nu = 0.0_wp                ! Poisson's ratio
    REAL(wp) :: lambda = 0.0_wp            ! Lame parameter lambda
    REAL(wp) :: mu = 0.0_wp                ! Shear modulus mu

    ! Johnson-Cook parameters
    REAL(wp) :: A = 0.0_wp                 ! Yield stress at reference conditions
    REAL(wp) :: B = 0.0_wp                 ! Hardening modulus
    REAL(wp) :: n = 0.0_wp                 ! Hardening exponent
    REAL(wp) :: C = 0.0_wp                 ! Strain rate sensitivity coefficient
    REAL(wp) :: m = 0.0_wp                 ! Temperature sensitivity exponent

    ! Reference conditions
    REAL(wp) :: T_melt = 1800.0_wp         ! Melting temperature (K)
    REAL(wp) :: T_ref = 300.0_wp           ! Reference temperature (K)
    REAL(wp) :: eps_dot0 = 1.0_wp          ! Reference strain rate (1/s)

    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MD_MAT_JC_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MD_MAT_JC_MatDesc_Valid
  END TYPE MD_MAT_JC_MatDesc

  !> @brief Johnson-Cook material state (State category)
  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MD_MAT_JC_MatState
    REAL(wp) :: eps_p_eqv = 0.0_wp        ! Equivalent plastic strain
    REAL(wp) :: eps_dot_eqv = 0.0_wp       ! Equivalent plastic strain rate
    REAL(wp) :: plastic_work = 0.0_wp     ! Plastic work
    REAL(wp), ALLOCATABLE :: eps_p(:)     ! Plastic strain tensor (Voigt: 6 components)
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MD_MAT_JC_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MD_MAT_JC_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MD_MAT_JC_MatState_InitFromInputs
  END TYPE MD_MAT_JC_MatState

  !> @brief Johnson-Cook material context (Ctx category)
  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MD_MAT_JC_MatCtx
    INTEGER(i4) :: ndir = 3
    INTEGER(i4) :: nshr = 3
    INTEGER(i4) :: ntens = 6
    REAL(wp) :: temp = 0.0_wp             ! Current temperature
    REAL(wp) :: dtemp = 0.0_wp             ! Temperature increment
    REAL(wp) :: dtime = 0.0_wp             ! Time increment
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MD_MAT_JC_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MD_MAT_JC_MatCtx_InitDefaults
  END TYPE MD_MAT_JC_MatCtx

  !> @brief Johnson-Cook material algorithm (Algo category)
  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MD_MAT_JC_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    REAL(wp) :: min_eps_dot = 1.0e-6_wp    ! Minimum strain rate for regularization
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MD_MAT_JC_MatAlgo_InitDefaults
  END TYPE MD_MAT_JC_MatAlgo

  PUBLIC :: MD_MAT_JC_MatDesc, MD_MAT_JC_MatState, MD_MAT_JC_MatCtx, MD_MAT_JC_MatAlgo
  PUBLIC :: JCProperties, JohnsonCookProperties
  PUBLIC :: MD_Mat_JohnsonCook_Unified_Configure, MD_Mat_JohnsonCook_Unified_Parse
  PUBLIC :: Parse_JOHNSON_COOK_Keyword, Valid_JOHNSON_COOK_Keyword
  PUBLIC :: UF_JohnsonCook_ValidateProps

CONTAINS

  !=============================================================================
  ! JC Type-Bound Procedures
  !=============================================================================

  SUBROUTINE MD_MAT_JC_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MD_MAT_JC_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    REAL(wp), PARAMETER :: TWO = 2.0_wp
    REAL(wp), PARAMETER :: THREE = 3.0_wp

    CALL init_error_status(status)

    IF (nprops < 7) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MD_MAT_JC_MatDesc: Insufficient properties (need at least 7)"
      RETURN
    END IF

    ! Extract properties
    this%E = props(1)
    this%nu = props(2)
    this%A = props(3)
    this%B = props(4)
    this%n = props(5)
    this%C = props(6)
    this%m = props(7)

    ! Optional parameters
    IF (nprops >= 8) THEN
      this%T_melt = props(8)
    END IF

    IF (nprops >= 9) THEN
      this%T_ref = props(9)
    END IF

    IF (nprops >= 10) THEN
      this%eps_dot0 = props(10)
    END IF

    ! Compute derived parameters
    this%mu = this%E / (TWO * (ONE + this%nu))
    this%lambda = this%E * this%nu / ((ONE + this%nu) * (ONE - TWO * this%nu))

    ! Set base class fields
    this%cfg%id = MD_MAT_JOHNSONCOOK_MAT
    this%name = MD_MAT_JOHNSONCOOK_MAT_NAME
    this%cfg%class_id = MD_MAT_CATEGORY_PL
    this%pop%nProps = nprops
    this%pop%nStateV = 9  ! eps_p(6) + eps_p_eqv(1) + eps_dot_eqv(1) + plastic_work(1)

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props

    this%init = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE MD_MAT_JC_MatDesc_InitFromProps

  FUNCTION MD_MAT_JC_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MD_MAT_JC_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    is_valid = .TRUE.

    IF (.NOT. this%init) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%E <= ZERO .OR. this%A <= ZERO .OR. this%B < ZERO .OR. &
        this%n < ZERO .OR. this%C < ZERO .OR. this%m < ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

  END FUNCTION MD_MAT_JC_MatDesc_Valid

  !=============================================================================
  ! MD_MAT_JC_MatState Type-Bound Procedures
  !=============================================================================

  SUBROUTINE MD_MAT_JC_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MD_MAT_JC_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    IF (.NOT. this%init) RETURN

    n_eps_p = MIN(6, SIZE(this%eps_p, 1))

    ! Store equivalent plastic strain
    IF (nstatev >= 1) THEN
      statev(1) = this%eps_p_eqv
    END IF

    ! Store equivalent plastic strain rate
    IF (nstatev >= 2) THEN
      statev(2) = this%eps_dot_eqv
    END IF

    ! Store plastic work
    IF (nstatev >= 3) THEN
      statev(3) = this%plastic_work
    END IF

    ! Store plastic strain components
    DO i = 1, MIN(n_eps_p, nstatev - 3)
      statev(3 + i) = this%eps_p(i)
    END DO

  END SUBROUTINE MD_MAT_JC_MatState_SyncToStateV

  SUBROUTINE MD_MAT_JC_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MD_MAT_JC_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    IF (nstatev >= 1) THEN
      this%eps_p_eqv = statev(1)
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF

    IF (nstatev >= 2) THEN
      this%eps_dot_eqv = statev(2)
    ELSE
      this%eps_dot_eqv = 0.0_wp
    END IF

    IF (nstatev >= 3) THEN
      this%plastic_work = statev(3)
    ELSE
      this%plastic_work = 0.0_wp
    END IF

    n_eps_p = MIN(6, nstatev - 3)

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF

    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(3 + i)
    END DO

    this%init = .TRUE.

  END SUBROUTINE MD_MAT_JC_MatState_SyncFromStateV

  SUBROUTINE MD_MAT_JC_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MD_MAT_JC_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr

    INTEGER(i4) :: ntens

    ntens = ndir + nshr

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF

    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF

    this%eps_p_eqv = 0.0_wp
    this%eps_dot_eqv = 0.0_wp
    this%plastic_work = 0.0_wp
    this%init = .TRUE.

  END SUBROUTINE MD_MAT_JC_MatState_InitFromInputs

  !=============================================================================
  ! MD_MAT_JC_MatCtx Type-Bound Procedures
  !=============================================================================

  SUBROUTINE MD_MAT_JC_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtemp, dtime, kstep, kinc)
    CLASS(MD_MAT_JC_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtemp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc

    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr

    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtemp)) this%dtemp = dtemp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc

    this%init = .TRUE.

  END SUBROUTINE MD_MAT_JC_MatCtx_InitFromInputs

  SUBROUTINE MD_MAT_JC_MatCtx_InitDefaults(this)
    CLASS(MD_MAT_JC_MatCtx), INTENT(INOUT) :: this

    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 300.0_wp  ! Default reference temperature
    this%dtemp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%init = .TRUE.

  END SUBROUTINE MD_MAT_JC_MatCtx_InitDefaults

  !=============================================================================
  ! MD_MAT_JC_MatAlgo Type-Bound Procedures
  !=============================================================================

  SUBROUTINE MD_MAT_JC_MatAlgo_InitDefaults(this)
    CLASS(MD_MAT_JC_MatAlgo), INTENT(INOUT) :: this

    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%min_eps_dot = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%init = .TRUE.

  END SUBROUTINE MD_MAT_JC_MatAlgo_InitDefaults

  SUBROUTINE UF_JohnsonCook_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    CHARACTER(LEN=16) :: req_str, prov_str

    CALL init_error_status(status)

    IF (nprops < MD_MAT_JC_MIN_PROPS) THEN
      WRITE (req_str, '(I0)') MD_MAT_JC_MIN_PROPS
      WRITE (prov_str, '(I0)') nprops
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Johnson-Cook. Required: " // TRIM(req_str) // &
          ", Provided: " // TRIM(prov_str)
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_E) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Young's modulus must be positive"
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_NU) < -ONE .OR. props(MD_MAT_JC_PROP_NU) >= 0.5_wp) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Poisson's ratio must be in [-1, 0.5)"
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_A) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Yield stress A must be positive"
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_B) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Hardening modulus B cannot be negative"
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_N) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Hardening exponent n must be non-negative"
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_C) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Strain rate sensitivity coef C must be non-negative"
      RETURN
    END IF

    IF (props(MD_MAT_JC_PROP_M) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Temperature sensitivity exponent m must be non-negative"
      RETURN
    END IF

    IF (nprops >= MD_MAT_JC_PROP_T_MELT .AND. props(MD_MAT_JC_PROP_T_MELT) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Melting temperature must be positive"
      RETURN
    END IF

    IF (nprops >= MD_MAT_JC_PROP_T_REF .AND. props(MD_MAT_JC_PROP_T_REF) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Reference temperature must be positive"
      RETURN
    END IF

    IF (nprops >= MD_MAT_JC_PROP_EPS_DOT0 .AND. props(MD_MAT_JC_PROP_EPS_DOT0) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Reference strain rate must be positive"
      RETURN
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_JohnsonCook_ValidateProps

  !===========================================================================
  ! Johnson-Cook keyword Desc (DescBase) + parse entry points
  !===========================================================================

  SUBROUTINE JCProperties_Init_Base(this)
    CLASS(JCProperties), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = 'DESC::JOHNSONCOOK'
  END SUBROUTINE JCProperties_Init_Base

  SUBROUTINE JCProperties_Init(this, materialName, status)
    CLASS(JCProperties), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: materialName
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL this%Init()
    this%materialName = TRIM(materialName)
    this%A = 0.0_wp
    this%B = 0.0_wp
    this%n = 0.0_wp
    this%C = 0.0_wp
    this%m = 0.0_wp
  END SUBROUTINE JCProperties_Init

  FUNCTION JCProperties_Valid_Fn(this) RESULT(ok)
    CLASS(JCProperties), INTENT(IN) :: this
    LOGICAL :: ok
    ok = .TRUE.
  END FUNCTION JCProperties_Valid_Fn

  SUBROUTINE JCProperties_Clear(this)
    CLASS(JCProperties), INTENT(INOUT) :: this
    this%materialName = ""
    this%A = 0.0_wp
    this%B = 0.0_wp
    this%n = 0.0_wp
    this%C = 0.0_wp
    this%m = 0.0_wp
  END SUBROUTINE JCProperties_Clear

  SUBROUTINE MD_Mat_JohnsonCook_Unified_Configure(operation, status)
    CHARACTER(LEN=*), INTENT(IN) :: operation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
        TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
      CONTINUE
    ELSE
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Mat_JohnsonCook_Unified_Configure: unknown operation ' // TRIM(operation)
    END IF
  END SUBROUTINE MD_Mat_JohnsonCook_Unified_Configure

  SUBROUTINE MD_Mat_JohnsonCook_Unified_Parse(material_type, ast_node, johnsonCook, material_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: material_type
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    TYPE(JCProperties), INTENT(OUT) :: johnsonCook
    CHARACTER(LEN=*), INTENT(IN) :: material_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (TRIM(material_type) == 'MD_MAT_JOHNSON_COOK' .OR. TRIM(material_type) == 'JOHNSON COOK') THEN
      CALL Parse_JOHNSON_COOK_Keyword(ast_node, johnsonCook, material_name, status)
    ELSE
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Mat_JohnsonCook_Unified_Parse: unsupported material_type ' // TRIM(material_type)
    END IF
  END SUBROUTINE MD_Mat_JohnsonCook_Unified_Parse

  SUBROUTINE Parse_JOHNSON_COOK_Keyword(ast_node, johnsonCook, materialName, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    TYPE(JCProperties), INTENT(OUT) :: johnsonCook
    CHARACTER(LEN=*), INTENT(IN) :: materialName
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL JCProperties_Init(johnsonCook, TRIM(materialName), status)
    IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 5) THEN
      johnsonCook%A = ast_node%data_lines(1)%real_values(1)
      johnsonCook%B = ast_node%data_lines(1)%real_values(2)
      johnsonCook%n = ast_node%data_lines(1)%real_values(3)
      johnsonCook%C = ast_node%data_lines(1)%real_values(4)
      johnsonCook%m = ast_node%data_lines(1)%real_values(5)
    END IF
    IF (.NOT. johnsonCook%Valid()) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Johnson-Cook validation failed"
    ELSE
      status%status_code = MD_MAT_STATUS_OK
    END IF
  END SUBROUTINE Parse_JOHNSON_COOK_Keyword

  SUBROUTINE Valid_JOHNSON_COOK_Keyword(johnsonCook, status)
    TYPE(JCProperties), INTENT(IN) :: johnsonCook
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. johnsonCook%Valid()) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Johnson-Cook validation failed"
    ELSE
      status%status_code = MD_MAT_STATUS_OK
    END IF
  END SUBROUTINE Valid_JOHNSON_COOK_Keyword

END MODULE MD_Mat_Plast_JohnsonCook

