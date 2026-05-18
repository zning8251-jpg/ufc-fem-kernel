!===============================================================================
! MODULE: MD_MatPOR_Gurson
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  Creep family implementation -- MD_MatPOR_Gurson.
!         **W1**：**Gurson** 系 **MD_Mat_Desc** 子类 + **props** 布局；**Populate**→**`desc%props`**；与 L4 **GTN** 核一致；**mat_id** 以本模块 **PARAMETER** 与 **`MD_Mat_Ids`** 对表为准。
!===============================================================================
MODULE MD_Mat_Creep_Gurson
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_PL

  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_E = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_SIGMA_Y0 = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_H = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_Q1 = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_Q2 = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_Q3 = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_F0 = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_FC = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_FF = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_FN = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_SN = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_PROP_EPSILON_N = 13_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_MIN_PROPS = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GUR_MAX_PROPS = 13_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Gurson_MatDesc
    ! Elastic parameters
    REAL(wp) :: E = 0.0_wp                 ! Young's modulus
    REAL(wp) :: nu = 0.0_wp                ! Poisson's ratio
    REAL(wp) :: lambda = 0.0_wp            ! Lame parameter lambda
    REAL(wp) :: mu = 0.0_wp                ! Shear modulus mu
    REAL(wp) :: K = 0.0_wp                 ! Bulk modulus K

    ! Gurson (GTN) parameters
    REAL(wp) :: sigma_y0 = 0.0_wp          ! Initial yield stress
    REAL(wp) :: H = 0.0_wp                 ! Hardening modulus
    REAL(wp) :: q1 = 1.5_wp                ! Tvergaard parameter q1
    REAL(wp) :: q2 = 1.0_wp                ! Tvergaard parameter q2
    REAL(wp) :: q3 = 2.25_wp               ! Tvergaard parameter q3
    REAL(wp) :: f0 = 0.0_wp                ! Initial void volume fraction
    REAL(wp) :: fc = 0.15_wp               ! Critical void volume fraction
    REAL(wp) :: ff = 0.25_wp               ! Final void volume fraction
    REAL(wp) :: fn = 0.04_wp               ! Nucleation void volume fraction
    REAL(wp) :: sn = 0.1_wp                ! Nucleation standard deviation
    REAL(wp) :: epsilon_n = 0.3_wp         ! Nucleation mean strain

    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Gurson_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Gurson_MatDesc_Valid
  END TYPE Gurson_MatDesc

  !> @brief Gurson material state (State category)
  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Gurson_MatState
    REAL(wp) :: eps_p_eqv = 0.0_wp        ! Equivalent plastic strain
    REAL(wp) :: f = 0.0_wp                 ! Void volume fraction
    REAL(wp) :: f_nucleation = 0.0_wp     ! Nucleation void fraction
    REAL(wp) :: plastic_work = 0.0_wp     ! Plastic work
    REAL(wp), ALLOCATABLE :: eps_p(:)     ! Plastic strain tensor (Voigt: 6 components)
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Gurson_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Gurson_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Gurson_MatState_InitFromInputs
  END TYPE Gurson_MatState

  !> @brief Gurson material context (Ctx category)
  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Gurson_MatCtx
    INTEGER(i4) :: ndir = 3
    INTEGER(i4) :: nshr = 3
    INTEGER(i4) :: ntens = 6
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Gurson_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Gurson_MatCtx_InitDefaults
  END TYPE Gurson_MatCtx

  !> @brief Gurson material algorithm (Algo category)
  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Gurson_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Gurson_MatAlgo_InitDefaults
  END TYPE Gurson_MatAlgo

  PUBLIC :: Gurson_MatDesc, Gurson_MatState, Gurson_MatCtx, Gurson_MatAlgo
  PUBLIC :: UF_Gurson_ValidateProps

CONTAINS

  !=============================================================================
  ! Gurson Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Gurson_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Gurson_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    REAL(wp), PARAMETER :: TWO = 2.0_wp
    REAL(wp), PARAMETER :: THREE = 3.0_wp

    CALL init_error_status(status)

    IF (nprops < 10) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Gurson_MatDesc: Insufficient properties (need at least 10)"
      RETURN
    END IF

    ! Extract properties
    this%E = props(1)
    this%nu = props(2)
    this%sigma_y0 = props(3)
    this%H = props(4)
    this%q1 = props(5)
    this%q2 = props(6)
    this%q3 = props(7)
    this%f0 = props(8)
    this%fc = props(9)
    this%ff = props(10)

    ! Optional nucleation parameters
    IF (nprops >= 11) THEN
      this%fn = props(11)
    ELSE
      this%fn = 0.04_wp
    END IF

    IF (nprops >= 12) THEN
      this%sn = props(12)
    ELSE
      this%sn = 0.1_wp
    END IF

    IF (nprops >= 13) THEN
      this%epsilon_n = props(13)
    ELSE
      this%epsilon_n = 0.3_wp
    END IF

    ! Compute derived parameters
    this%mu = this%E / (TWO * (ONE + this%nu))
    this%lambda = this%E * this%nu / ((ONE + this%nu) * (ONE - TWO * this%nu))
    this%K = this%E / (THREE * (ONE - TWO * this%nu))

    ! Set base class fields
    this%cfg%id = 207_i4  ! MD_MAT_GURSON_MAT_ID
    this%name = "Gurson-Tvergaard-Needleman (GTN)"
    this%cfg%class_id = MD_MAT_CATEGORY_PL
    this%pop%nProps = nprops
    this%pop%nStateV = 12  ! eps_p(6) + eps_p_eqv(1) + f(1) + f_nucleation(1) + plastic_work(1) + other(2)

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props

    this%init = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE Gurson_MatDesc_InitFromProps

  FUNCTION Gurson_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Gurson_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    is_valid = .TRUE.

    IF (.NOT. this%init) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%E <= ZERO .OR. this%sigma_y0 <= ZERO .OR. &
        this%q1 <= ZERO .OR. this%q2 <= ZERO .OR. this%q3 <= ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

  END FUNCTION Gurson_MatDesc_Valid

  !=============================================================================
  ! Gurson_MatState Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Gurson_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Gurson_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    IF (.NOT. this%init) RETURN

    n_eps_p = MIN(6, SIZE(this%eps_p, 1))

    ! Store equivalent plastic strain
    IF (nstatev >= 1) THEN
      statev(1) = this%eps_p_eqv
    END IF

    ! Store void volume fraction
    IF (nstatev >= 2) THEN
      statev(2) = this%f
    END IF

    ! Store nucleation void fraction
    IF (nstatev >= 3) THEN
      statev(3) = this%f_nucleation
    END IF

    ! Store plastic work
    IF (nstatev >= 4) THEN
      statev(4) = this%plastic_work
    END IF

    ! Store plastic strain components
    DO i = 1, MIN(n_eps_p, nstatev - 4)
      statev(4 + i) = this%eps_p(i)
    END DO

  END SUBROUTINE Gurson_MatState_SyncToStateV

  SUBROUTINE Gurson_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Gurson_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    IF (nstatev >= 1) THEN
      this%eps_p_eqv = statev(1)
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF

    IF (nstatev >= 2) THEN
      this%f = statev(2)
    ELSE
      this%f = 0.0_wp
    END IF

    IF (nstatev >= 3) THEN
      this%f_nucleation = statev(3)
    ELSE
      this%f_nucleation = 0.0_wp
    END IF

    IF (nstatev >= 4) THEN
      this%plastic_work = statev(4)
    ELSE
      this%plastic_work = 0.0_wp
    END IF

    n_eps_p = MIN(6, nstatev - 4)

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF

    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(4 + i)
    END DO

    this%init = .TRUE.

  END SUBROUTINE Gurson_MatState_SyncFromStateV

  SUBROUTINE Gurson_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Gurson_MatState), INTENT(INOUT) :: this
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
    this%f = 0.0_wp
    this%f_nucleation = 0.0_wp
    this%plastic_work = 0.0_wp
    this%init = .TRUE.

  END SUBROUTINE Gurson_MatState_InitFromInputs

  !=============================================================================
  ! Gurson_MatCtx Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Gurson_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Gurson_MatCtx), INTENT(INOUT) :: this
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

  END SUBROUTINE Gurson_MatCtx_InitFromInputs

  SUBROUTINE Gurson_MatCtx_InitDefaults(this)
    CLASS(Gurson_MatCtx), INTENT(INOUT) :: this

    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%init = .TRUE.

  END SUBROUTINE Gurson_MatCtx_InitDefaults

  !=============================================================================
  ! Gurson_MatAlgo Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Gurson_MatAlgo_InitDefaults(this)
    CLASS(Gurson_MatAlgo), INTENT(INOUT) :: this

    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%init = .TRUE.

  END SUBROUTINE Gurson_MatAlgo_InitDefaults

  SUBROUTINE UF_Gurson_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp

    CALL init_error_status(status)

    IF (nprops < MD_MAT_GUR_MIN_PROPS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      WRITE (status%message, '(A,I0,A,I0)') 'Insufficient Gurson properties: ', nprops, &
          ' provided, minimum ', MD_MAT_GUR_MIN_PROPS, ' required'
      RETURN
    END IF

    IF (props(MD_MAT_GUR_PROP_E) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Young''s modulus must be positive'
      RETURN
    END IF

    IF (props(MD_MAT_GUR_PROP_NU) <= ZERO .OR. props(MD_MAT_GUR_PROP_NU) >= 0.5_wp) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Poisson''s ratio must be in (0, 0.5)'
      RETURN
    END IF

    IF (props(MD_MAT_GUR_PROP_SIGMA_Y0) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Initial yield stress must be positive'
      RETURN
    END IF

    IF (props(MD_MAT_GUR_PROP_F0) < ZERO .OR. props(MD_MAT_GUR_PROP_F0) >= ONE) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Initial void volume fraction must be in [0, 1)'
      RETURN
    END IF

    IF (props(MD_MAT_GUR_PROP_FC) <= props(MD_MAT_GUR_PROP_F0) .OR. props(MD_MAT_GUR_PROP_FC) >= ONE) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Critical void volume fraction must be > f0 and < 1'
      RETURN
    END IF

    IF (props(MD_MAT_GUR_PROP_FF) <= props(MD_MAT_GUR_PROP_FC) .OR. props(MD_MAT_GUR_PROP_FF) >= ONE) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Final void volume fraction must be > fc and < 1'
      RETURN
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Gurson_ValidateProps


END MODULE MD_Mat_Creep_Gurson