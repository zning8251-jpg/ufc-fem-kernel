!===============================================================================
! MODULE: MD_Mat_Plast_Hill
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  Plastic family implementation -- MD_Mat_Plast_Hill.
! **W1**：**props** / **`MD_Mat_Desc`/`cfg%id`** / **Populate** → L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`** / **`PH_MatPlast_*`**（**205** / **MAT_PLAST_ANISO_HIL**）。
!===============================================================================
MODULE MD_Mat_Plast_Hill
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_PL

  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_MAT_ID = 205_i4
  CHARACTER(LEN=*), PARAMETER, PUBLIC :: MD_MAT_HILL_MAT_NAME = "Hill Anisotropic Plasticity"

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_E = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H11 = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H22 = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H33 = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H12 = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H23 = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H13 = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H44 = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_SIGMA_Y0 = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H55 = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H66 = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_H_HARDENIN = 13_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_PROP_N_HARDENIN = 14_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HILL_MIN_PROPS = 10_i4

  !> @brief Hill anisotropic material descriptor (Desc category)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Hill_MatDesc
    ! Elastic parameters
    REAL(wp) :: E = 0.0_wp                 ! Young's modulus
    REAL(wp) :: nu = 0.0_wp                ! Poisson's ratio
    REAL(wp) :: G = 0.0_wp                  ! Shear modulus
    REAL(wp) :: K = 0.0_wp                  ! Bulk modulus

    ! Hill anisotropy coefficients
    REAL(wp) :: H11 = 0.0_wp               ! Hill coefficient H11
    REAL(wp) :: H22 = 0.0_wp               ! Hill coefficient H22
    REAL(wp) :: H33 = 0.0_wp               ! Hill coefficient H33
    REAL(wp) :: H12 = 0.0_wp               ! Hill coefficient H12
    REAL(wp) :: H23 = 0.0_wp               ! Hill coefficient H23
    REAL(wp) :: H13 = 0.0_wp               ! Hill coefficient H13
    REAL(wp) :: H44 = 0.0_wp               ! Hill coefficient H44
    REAL(wp) :: H55 = 0.0_wp               ! Hill coefficient H55
    REAL(wp) :: H66 = 0.0_wp               ! Hill coefficient H66

    ! Yield and hardening
    REAL(wp) :: sigma_y0 = 0.0_wp         ! Initial yield stress
    REAL(wp) :: H_hardening = 0.0_wp      ! Hardening modulus
    REAL(wp) :: n_hardening = 1.0_wp       ! Hardening exponent

    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Hill_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Hill_MatDesc_Valid
  END TYPE Hill_MatDesc

  !> @brief Hill material state (State category)
  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Hill_MatState
    REAL(wp) :: eps_p_eqv = 0.0_wp        ! Equivalent plastic strain
    REAL(wp), ALLOCATABLE :: eps_p(:)     ! Plastic strain tensor (Voigt: 6 components)
    REAL(wp), ALLOCATABLE :: alpha(:)     ! Back stress tensor (for kinematic hardening)
    REAL(wp) :: kappa = 0.0_wp            ! Hardening parameter
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Hill_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Hill_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Hill_MatState_InitFromInputs
  END TYPE Hill_MatState

  !> @brief Hill material context (Ctx category)
  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Hill_MatCtx
    INTEGER(i4) :: ndir = 3
    INTEGER(i4) :: nshr = 3
    INTEGER(i4) :: ntens = 6
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Hill_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Hill_MatCtx_InitDefaults
  END TYPE Hill_MatCtx

  !> @brief Hill material algorithm (Algo category)
  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Hill_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Hill_MatAlgo_InitDefaults
  END TYPE Hill_MatAlgo

  PUBLIC :: Hill_MatDesc, Hill_MatState, Hill_MatCtx, Hill_MatAlgo
  PUBLIC :: UF_Hill_ValidateProps

CONTAINS

  !=============================================================================
  ! Hill Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Hill_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Hill_MatDesc), INTENT(INOUT) :: this
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
      status%message = "Hill_MatDesc: Insufficient properties (need at least 10)"
      RETURN
    END IF

    ! Extract properties
    this%E = props(1)
    this%nu = props(2)
    this%H11 = props(3)
    this%H22 = props(4)
    this%H33 = props(5)
    this%H12 = props(6)
    this%H23 = props(7)
    this%H13 = props(8)
    this%H44 = props(9)
    this%sigma_y0 = props(10)

    ! Optional parameters
    IF (nprops >= 11) THEN
      this%H55 = props(11)
    ELSE
      this%H55 = this%H44
    END IF

    IF (nprops >= 12) THEN
      this%H66 = props(12)
    ELSE
      this%H66 = this%H44
    END IF

    IF (nprops >= 13) THEN
      this%H_hardening = props(13)
    ELSE
      this%H_hardening = this%E / 100.0_wp
    END IF

    IF (nprops >= 14) THEN
      this%n_hardening = props(14)
    ELSE
      this%n_hardening = ONE
    END IF

    ! Compute derived parameters
    this%G = this%E / (TWO * (ONE + this%nu))
    this%K = this%E / (THREE * (ONE - TWO * this%nu))

    ! Set base class fields
    this%cfg%id = MD_MAT_HILL_MAT_ID
    this%name = MD_MAT_HILL_MAT_NAME
    this%cfg%class_id = MD_MAT_CATEGORY_PL
    this%pop%nProps = nprops
    this%pop%nStateV = 7  ! eps_p(6) + eps_p_eqv(1)

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props

    this%init = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE Hill_MatDesc_InitFromProps

  FUNCTION Hill_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Hill_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    is_valid = .TRUE.

    IF (.NOT. this%init) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%E <= ZERO .OR. this%H44 <= ZERO .OR. this%sigma_y0 <= ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

  END FUNCTION Hill_MatDesc_Valid

  !=============================================================================
  ! Hill_MatState Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Hill_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Hill_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    IF (.NOT. this%init) RETURN

    n_eps_p = MIN(6, SIZE(this%eps_p, 1))

    DO i = 1, MIN(n_eps_p, nstatev)
      statev(i) = this%eps_p(i)
    END DO

    IF (nstatev >= n_eps_p + 1) THEN
      statev(n_eps_p + 1) = this%eps_p_eqv
    END IF

  END SUBROUTINE Hill_MatState_SyncToStateV

  SUBROUTINE Hill_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Hill_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    n_eps_p = MIN(6, nstatev - 1)

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF

    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(i)
    END DO

    IF (nstatev >= n_eps_p + 1) THEN
      this%eps_p_eqv = statev(n_eps_p + 1)
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF

    this%init = .TRUE.

  END SUBROUTINE Hill_MatState_SyncFromStateV

  SUBROUTINE Hill_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Hill_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr

    INTEGER(i4) :: ntens

    ntens = ndir + nshr

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF

    IF (.NOT. ALLOCATED(this%alpha)) THEN
      ALLOCATE(this%alpha(ntens))
      this%alpha = 0.0_wp
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
    this%kappa = 0.0_wp
    this%init = .TRUE.

  END SUBROUTINE Hill_MatState_InitFromInputs

  !=============================================================================
  ! Hill_MatCtx Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Hill_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Hill_MatCtx), INTENT(INOUT) :: this
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

  END SUBROUTINE Hill_MatCtx_InitFromInputs

  SUBROUTINE Hill_MatCtx_InitDefaults(this)
    CLASS(Hill_MatCtx), INTENT(INOUT) :: this

    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%init = .TRUE.

  END SUBROUTINE Hill_MatCtx_InitDefaults

  !=============================================================================
  ! Hill_MatAlgo Type-Bound Procedures
  !=============================================================================

  SUBROUTINE Hill_MatAlgo_InitDefaults(this)
    CLASS(Hill_MatAlgo), INTENT(INOUT) :: this

    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%init = .TRUE.

  END SUBROUTINE Hill_MatAlgo_InitDefaults

  SUBROUTINE UF_Hill_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    CALL init_error_status(status)

    IF (nprops < MD_MAT_HILL_MIN_PROPS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      WRITE (status%message, '(A,I0,A)') 'Insufficient properties: need at least ', MD_MAT_HILL_MIN_PROPS, ' properties'
      RETURN
    END IF

    IF (props(MD_MAT_HILL_PROP_E) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Young''s modulus must be positive'
      RETURN
    END IF

    IF (props(MD_MAT_HILL_PROP_NU) < ZERO .OR. props(MD_MAT_HILL_PROP_NU) >= 0.5_wp) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Poisson''s ratio must be in [0, 0.5)'
      RETURN
    END IF

    IF (props(MD_MAT_HILL_PROP_SIGMA_Y0) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Initial yield stress must be positive'
      RETURN
    END IF

    IF (props(MD_MAT_HILL_PROP_H44) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Hill coef H44 must be positive'
      RETURN
    END IF

    IF (nprops >= MD_MAT_HILL_PROP_H55 .AND. props(MD_MAT_HILL_PROP_H55) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Hill coef H55 must be positive'
      RETURN
    END IF

    IF (nprops >= MD_MAT_HILL_PROP_H66 .AND. props(MD_MAT_HILL_PROP_H66) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Hill coef H66 must be positive'
      RETURN
    END IF

    IF (nprops >= MD_MAT_HILL_PROP_H_HARDENIN .AND. props(MD_MAT_HILL_PROP_H_HARDENIN) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Hardening modulus must be non-negative'
      RETURN
    END IF

    IF (nprops >= MD_MAT_HILL_PROP_N_HARDENIN .AND. props(MD_MAT_HILL_PROP_N_HARDENIN) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'Hardening exponent must be positive'
      RETURN
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Hill_ValidateProps


END MODULE MD_Mat_Plast_Hill

