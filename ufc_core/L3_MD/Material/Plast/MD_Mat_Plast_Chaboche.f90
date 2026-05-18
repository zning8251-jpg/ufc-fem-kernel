!===============================================================================
! MODULE: MD_Mat_Plast_Chaboche
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  Plastic family implementation -- MD_Mat_Plast_Chaboche.
! **W1**：**props** / **`MD_Mat_Desc`/`cfg%id`** / **Populate** → L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`** / **`PH_MatPlast_*`**（**210** / **MAT_PLAST_CHABOCHE**）。
!===============================================================================
MODULE MD_Mat_Plast_Chaboche
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init
  USE MD_KW_Def, ONLY: KW_ASTNodeType
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_PL

  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHABOCHE_MAT_ID = 210_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: CHABOCHE_MAT_NA = "Chaboche Kinematic Hardening"

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_E = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_SIGMA_Y0 = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_H = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_N_COMP = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_C1 = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_GAMMA1 = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_C2 = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_GAMMA2 = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_C3 = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_PROP_GAMMA3 = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_MIN_PROPS = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_MAX_PROPS = 11_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_STATEV_EPS_EQV = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_STATEV_WORK = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_STATEV_ALPHA1 = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_STATEV_ALPHA2 = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_STATEV_ALPHA3 = 15_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CHAB_STATEV_EPS_P = 21_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Chab_MatDesc
    ! Elastic parameters
    REAL(wp) :: E = 0.0_wp                 ! Young's modulus
    REAL(wp) :: nu = 0.0_wp                ! Poisson's ratio
    REAL(wp) :: lambda = 0.0_wp            ! Lame parameter lambda
    REAL(wp) :: mu = 0.0_wp                ! Shear modulus mu
    REAL(wp) :: K = 0.0_wp                 ! Bulk modulus K

    ! Chaboche parameters
    REAL(wp) :: sigma_y0 = 0.0_wp          ! Initial yield stress
    REAL(wp) :: H = 0.0_wp                 ! Isotropic hardening modulus
    INTEGER(i4) :: n_components = 2        ! Number of back-stress components (1-3)
    REAL(wp) :: C(3) = 0.0_wp             ! Back-stress parameters C
    REAL(wp) :: gamma(3) = 0.0_wp         ! Back-stress parameters gamma

    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Chab_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Chab_MatDesc_Valid
  END TYPE Chab_MatDesc

  !> @brief Chaboche material state (State category)
  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Chab_MatState
    REAL(wp) :: eps_p_eqv = 0.0_wp        ! Equivalent plastic strain
    REAL(wp) :: plastic_work = 0.0_wp     ! Plastic work
    REAL(wp), ALLOCATABLE :: eps_p(:)     ! Plastic strain tensor (Voigt: 6 components)
    REAL(wp), ALLOCATABLE :: alpha1(:)    ! First back-stress component (6 components)
    REAL(wp), ALLOCATABLE :: alpha2(:)    ! Second back-stress component (6 components)
    REAL(wp), ALLOCATABLE :: alpha3(:)    ! Third back-stress component (6 components, optional)
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Chab_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Chab_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Chab_MatState_InitFromInputs
  END TYPE Chab_MatState

  !> @brief Chaboche material context (Ctx category)
  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Chab_MatCtx
    INTEGER(i4) :: ndir = 3
    INTEGER(i4) :: nshr = 3
    INTEGER(i4) :: ntens = 6
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Chab_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Chab_MatCtx_InitDefaults
  END TYPE Chab_MatCtx

  !> @brief Chaboche material algorithm (Algo category)
  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Chab_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Chab_MatAlgo_InitDefaults
  END TYPE Chab_MatAlgo

  ! Keyword / DescBase Chaboche (input deck; MD_KWMapper)
  TYPE, PUBLIC, EXTENDS(DescBase) :: ChabProperties
    CHARACTER(LEN=64) :: materialName = ""
    REAL(wp) :: C1 = 0.0_wp
    REAL(wp) :: gamma1 = 0.0_wp
    REAL(wp) :: C2 = 0.0_wp
    REAL(wp) :: gamma2 = 0.0_wp
    REAL(wp) :: Q = 0.0_wp
    REAL(wp) :: b = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: Init => ChabProperties_Init_Base
    PROCEDURE, PUBLIC :: Valid => ChabProperties_Valid_Fn
    PROCEDURE, PUBLIC :: Clear => ChabProperties_Clear
  END TYPE ChabProperties

  TYPE, PUBLIC, EXTENDS(ChabProperties) :: ChabocheProperties
  END TYPE ChabocheProperties

  PUBLIC :: Chab_MatDesc, Chab_MatState, Chab_MatCtx, Chab_MatAlgo
  PUBLIC :: ChabProperties, ChabocheProperties
  PUBLIC :: MD_Mat_Chaboche_Unified_Cfg, MD_Mat_Chaboche_Unified_Parse
  PUBLIC :: Parse_CHABOCHE_Keyword, Valid_CHABOCHE_Keyword
  PUBLIC :: CHABOCHE_MAT_NA
  PUBLIC :: MD_MAT_CHAB_PROP_E, MD_MAT_CHAB_PROP_NU, MD_MAT_CHAB_PROP_SIGMA_Y0, MD_MAT_CHAB_PROP_H, MD_MAT_CHAB_PROP_N_COMP
  PUBLIC :: MD_MAT_CHAB_PROP_C1, MD_MAT_CHAB_PROP_GAMMA1, MD_MAT_CHAB_PROP_C2, MD_MAT_CHAB_PROP_GAMMA2, MD_MAT_CHAB_PROP_C3, MD_MAT_CHAB_PROP_GAMMA3
  PUBLIC :: MD_MAT_CHAB_MIN_PROPS, MD_MAT_CHAB_MAX_PROPS
  PUBLIC :: MD_MAT_CHAB_STATEV_EPS_EQV, MD_MAT_CHAB_STATEV_WORK, MD_MAT_CHAB_STATEV_ALPHA1, MD_MAT_CHAB_STATEV_ALPHA2, MD_MAT_CHAB_STATEV_ALPHA3, MD_MAT_CHAB_STATEV_EPS_P
  PUBLIC :: UF_Chaboche_ValidateProps

CONTAINS

  !=============================================================================
  ! Chab Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Chab_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Chab_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    REAL(wp), PARAMETER :: TWO = 2.0_wp
    REAL(wp), PARAMETER :: THREE = 3.0_wp

    CALL init_error_status(status)

    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Chab_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF

    ! Extract properties
    this%E = props(1)
    this%nu = props(2)
    this%sigma_y0 = props(3)
    this%H = props(4)
    this%n_components = MAX(1_i4, MIN(3_i4, INT(props(5))))
    this%C(1) = props(6)
    this%gamma(1) = props(7)
    this%C(2) = props(8)
    this%gamma(2) = props(9)

    ! Optional third component
    IF (nprops >= 11) THEN
      this%C(3) = props(10)
      this%gamma(3) = props(11)
    ELSE
      this%C(3) = ZERO
      this%gamma(3) = ZERO
    END IF

    ! Compute derived parameters
    this%mu = this%E / (TWO * (ONE + this%nu))
    this%lambda = this%E * this%nu / ((ONE + this%nu) * (ONE - TWO * this%nu))
    this%K = this%E / (THREE * (ONE - TWO * this%nu))

    ! Set base class fields
    this%cfg%id = MD_MAT_CHABOCHE_MAT_ID
    this%name = "Chaboche Kinematic Hardening"
    this%cfg%class_id = MD_MAT_CATEGORY_PL
    this%pop%nProps = nprops
    this%pop%nStateV = 15 + 6 * this%n_components  ! eps_p(6) + eps_p_eqv(1) + plastic_work(1) + alpha components

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props

    this%init = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE Chab_MatDesc_InitFromProps

  FUNCTION Chab_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Chab_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    is_valid = .TRUE.

    IF (.NOT. this%init) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%E <= ZERO .OR. this%sigma_y0 <= ZERO .OR. &
        this%C(1) <= ZERO .OR. this%gamma(1) <= ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

  END FUNCTION Chab_MatDesc_Valid

  !=============================================================================
  ! Chab_MatState Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Chab_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Chab_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p, offset

    IF (.NOT. this%init) RETURN

    n_eps_p = MIN(6, SIZE(this%eps_p, 1))

    ! Store equivalent plastic strain
    IF (nstatev >= 1) THEN
      statev(1) = this%eps_p_eqv
    END IF

    ! Store plastic work
    IF (nstatev >= 2) THEN
      statev(2) = this%plastic_work
    END IF

    ! Store back-stress components
    offset = 2
    IF (ALLOCATED(this%alpha1)) THEN
      DO i = 1, MIN(6, nstatev - offset)
        statev(offset + i) = this%alpha1(i)
      END DO
      offset = offset + 6
    END IF

    IF (ALLOCATED(this%alpha2)) THEN
      DO i = 1, MIN(6, nstatev - offset)
        statev(offset + i) = this%alpha2(i)
      END DO
      offset = offset + 6
    END IF

    IF (ALLOCATED(this%alpha3)) THEN
      DO i = 1, MIN(6, nstatev - offset)
        statev(offset + i) = this%alpha3(i)
      END DO
      offset = offset + 6
    END IF

    ! Store plastic strain components
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO

  END SUBROUTINE Chab_MatState_SyncToStateV

  SUBROUTINE Chab_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Chab_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p, offset

    IF (nstatev >= 1) THEN
      this%eps_p_eqv = statev(1)
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF

    IF (nstatev >= 2) THEN
      this%plastic_work = statev(2)
    ELSE
      this%plastic_work = 0.0_wp
    END IF

    ! Load back-stress components
    offset = 2
    IF (ALLOCATED(this%alpha1)) THEN
      DO i = 1, MIN(6, SIZE(this%alpha1, 1), nstatev - offset)
        this%alpha1(i) = statev(offset + i)
      END DO
      offset = offset + 6
    END IF

    IF (ALLOCATED(this%alpha2)) THEN
      DO i = 1, MIN(6, SIZE(this%alpha2, 1), nstatev - offset)
        this%alpha2(i) = statev(offset + i)
      END DO
      offset = offset + 6
    END IF

    IF (ALLOCATED(this%alpha3)) THEN
      DO i = 1, MIN(6, SIZE(this%alpha3, 1), nstatev - offset)
        this%alpha3(i) = statev(offset + i)
      END DO
      offset = offset + 6
    END IF

    n_eps_p = MIN(6, nstatev - offset)

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF

    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(offset + i)
    END DO

    this%init = .TRUE.

  END SUBROUTINE Chab_MatState_SyncFromStateV

  SUBROUTINE Chab_MatState_InitFromInputs(this, ndir, nshr, n_components)
    CLASS(Chab_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr, n_components

    INTEGER(i4) :: ntens

    ntens = ndir + nshr

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF

    IF (.NOT. ALLOCATED(this%alpha1)) THEN
      ALLOCATE(this%alpha1(ntens))
      this%alpha1 = 0.0_wp
    END IF

    IF (n_components >= 2 .AND. .NOT. ALLOCATED(this%alpha2)) THEN
      ALLOCATE(this%alpha2(ntens))
      this%alpha2 = 0.0_wp
    END IF

    IF (n_components >= 3 .AND. .NOT. ALLOCATED(this%alpha3)) THEN
      ALLOCATE(this%alpha3(ntens))
      this%alpha3 = 0.0_wp
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
    this%plastic_work = 0.0_wp
    this%init = .TRUE.

  END SUBROUTINE Chab_MatState_InitFromInputs

  !=============================================================================
  ! Chab_MatCtx Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Chab_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Chab_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc

    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr

    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc

    this%init = .TRUE.

  END SUBROUTINE Chab_MatCtx_InitFromInputs

  SUBROUTINE Chab_MatCtx_InitDefaults(this)
    CLASS(Chab_MatCtx), INTENT(INOUT) :: this

    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%init = .TRUE.

  END SUBROUTINE Chab_MatCtx_InitDefaults

  !=============================================================================
  ! Chab_MatAlgo Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Chab_MatAlgo_InitDefaults(this)
    CLASS(Chab_MatAlgo), INTENT(INOUT) :: this

    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%init = .TRUE.

  END SUBROUTINE Chab_MatAlgo_InitDefaults

  SUBROUTINE UF_Chaboche_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_comp
    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    CALL init_error_status(status)

    IF (nprops < MD_MAT_CHAB_MIN_PROPS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      WRITE (status%message, '(A,I0,A,I0,A)') 'Insufficient properties: ', nprops, &
          ' provided, minimum ', MD_MAT_CHAB_MIN_PROPS, ' required'
      RETURN
    END IF

    IF (props(MD_MAT_CHAB_PROP_E) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Young''s modulus must be positive'
      RETURN
    END IF

    IF (props(MD_MAT_CHAB_PROP_NU) <= ZERO .OR. props(MD_MAT_CHAB_PROP_NU) >= 0.5_wp) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Poisson''s ratio must be in (0, 0.5)'
      RETURN
    END IF

    IF (props(MD_MAT_CHAB_PROP_SIGMA_Y0) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Initial yield stress must be positive'
      RETURN
    END IF

    n_comp = INT(props(MD_MAT_CHAB_PROP_N_COMP))
    IF (n_comp < 1 .OR. n_comp > 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Number of back-stress components must be 1-3'
      RETURN
    END IF

    IF (props(MD_MAT_CHAB_PROP_C1) < ZERO .OR. props(MD_MAT_CHAB_PROP_GAMMA1) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Back-stress parameters C and gamma must be non-negative'
      RETURN
    END IF

    IF (props(MD_MAT_CHAB_PROP_C2) < ZERO .OR. props(MD_MAT_CHAB_PROP_GAMMA2) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Back-stress parameters C and gamma must be non-negative'
      RETURN
    END IF

    IF (nprops >= MD_MAT_CHAB_PROP_C3) THEN
      IF (props(MD_MAT_CHAB_PROP_C3) < ZERO .OR. props(MD_MAT_CHAB_PROP_GAMMA3) < ZERO) THEN
        status%status_code = MD_MAT_STATUS_INVALID
        status%message = 'Back-stress parameters C and gamma must be non-negative'
        RETURN
      END IF
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Chaboche_ValidateProps

  SUBROUTINE ChabProperties_Init_Base(this)
    CLASS(ChabProperties), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = 'DESC::CHABOCHE'
  END SUBROUTINE ChabProperties_Init_Base

  SUBROUTINE ChabProperties_Init(this, materialName, status)
    CLASS(ChabProperties), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: materialName
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL this%Init()
    this%materialName = TRIM(materialName)
    this%C1 = 0.0_wp
    this%gamma1 = 0.0_wp
    this%C2 = 0.0_wp
    this%gamma2 = 0.0_wp
    this%Q = 0.0_wp
    this%b = 0.0_wp
  END SUBROUTINE ChabProperties_Init

  FUNCTION ChabProperties_Valid_Fn(this) RESULT(ok)
    CLASS(ChabProperties), INTENT(IN) :: this
    LOGICAL :: ok
    ok = .TRUE.
  END FUNCTION ChabProperties_Valid_Fn

  SUBROUTINE ChabProperties_Clear(this)
    CLASS(ChabProperties), INTENT(INOUT) :: this
    this%materialName = ""
    this%C1 = 0.0_wp
    this%gamma1 = 0.0_wp
    this%C2 = 0.0_wp
    this%gamma2 = 0.0_wp
    this%Q = 0.0_wp
    this%b = 0.0_wp
  END SUBROUTINE ChabProperties_Clear

  SUBROUTINE MD_Mat_Chaboche_Unified_Parse(material_type, ast_node, chaboche, material_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: material_type
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    TYPE(ChabProperties), INTENT(OUT) :: chaboche
    CHARACTER(LEN=*), INTENT(IN) :: material_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (TRIM(material_type) == 'CHABOCHE') THEN
      CALL Parse_CHABOCHE_Keyword(ast_node, chaboche, material_name, status)
    ELSE
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Mat_Chaboche_Unified_Parse: unsupported material_type ' // TRIM(material_type)
    END IF
  END SUBROUTINE MD_Mat_Chaboche_Unified_Parse

  SUBROUTINE MD_Mat_Chaboche_Unified_Cfg(operation, status)
    CHARACTER(LEN=*), INTENT(IN) :: operation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
        TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
      CONTINUE
    ELSE
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Mat_Chaboche_Unified_Cfg: unknown operation ' // TRIM(operation)
    END IF
  END SUBROUTINE MD_Mat_Chaboche_Unified_Cfg

  SUBROUTINE Parse_CHABOCHE_Keyword(ast_node, chaboche, materialName, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    TYPE(ChabProperties), INTENT(OUT) :: chaboche
    CHARACTER(LEN=*), INTENT(IN) :: materialName
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL ChabProperties_Init(chaboche, TRIM(materialName), status)
    IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 6) THEN
      chaboche%C1 = ast_node%data_lines(1)%real_values(1)
      chaboche%gamma1 = ast_node%data_lines(1)%real_values(2)
      chaboche%C2 = ast_node%data_lines(1)%real_values(3)
      chaboche%gamma2 = ast_node%data_lines(1)%real_values(4)
      chaboche%Q = ast_node%data_lines(1)%real_values(5)
      chaboche%b = ast_node%data_lines(1)%real_values(6)
    END IF
    IF (.NOT. chaboche%Valid()) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Chaboche validation failed"
    ELSE
      status%status_code = MD_MAT_STATUS_OK
    END IF
  END SUBROUTINE Parse_CHABOCHE_Keyword

  SUBROUTINE Valid_CHABOCHE_Keyword(chaboche, status)
    TYPE(ChabProperties), INTENT(IN) :: chaboche
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. chaboche%Valid()) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Chaboche validation failed"
    ELSE
      status%status_code = MD_MAT_STATUS_OK
    END IF
  END SUBROUTINE Valid_CHABOCHE_Keyword

END MODULE MD_Mat_Plast_Chaboche

