!===============================================================================
! MODULE: MD_Mat_Plast_J2
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  Plastic family implementation -- MD_Mat_Plast_J2.
! **W1**：**props** / **`MD_Mat_Desc`/`cfg%id`** / **Populate** → L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`** / **`PH_MatPlast_*`**（**mat_id** 见模块内 **PARAMETER** / **Init**）。
!===============================================================================
MODULE MD_Mat_Plast_J2
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Plast_Registry, ONLY: MD_MAT_VONMISES_MAT_NA
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_PL

  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: MD_MAT_VM_PROP_E = 1_i4
  INTEGER(i4), PARAMETER :: MD_MAT_VM_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER :: MD_MAT_VM_PROP_SY0 = 3_i4
  INTEGER(i4), PARAMETER :: MD_MAT_VM_PROP_H = 4_i4
  INTEGER(i4), PARAMETER :: MD_MAT_VM_MIN_PROPS = 4_i4

  !> @brief Von Mises material descriptor (Desc category)
  !! All material parameters encapsulated in structure
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: VM_MatDesc
    ! Base parameters (extracted from props array)
    REAL(wp) :: E = 0.0_wp                 ! Young's modulus
    REAL(wp) :: nu = 0.0_wp                ! Poisson's ratio
    REAL(wp) :: sigma_y0 = 0.0_wp          ! Initial yield stress
    REAL(wp) :: H = 0.0_wp                 ! Hardening modulus

    ! Derived parameters (computed)
    REAL(wp) :: lambda = 0.0_wp            ! Lame parameter lambda
    REAL(wp) :: mu = 0.0_wp                ! Shear modulus mu
    REAL(wp) :: K = 0.0_wp                 ! Bulk modulus K

    ! Hardening type
    INTEGER(i4) :: hardening_type = 1      ! 1=isotropic, 2=kinematic, 3=mixed

    ! Initialization flag
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => VM_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => VM_MatDesc_Valid
  END TYPE VM_MatDesc

  !> @brief Von Mises material state (State category)
  !! All state variables encapsulated in structure
  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: VM_MatState
    ! Plastic strain components
    REAL(wp) :: eps_p_eqv = 0.0_wp        ! Equivalent plastic strain
    REAL(wp), ALLOCATABLE :: eps_p(:)     ! Plastic strain tensor (Voigt: 6 components)

    ! Back stress (for kinematic hardening)
    REAL(wp), ALLOCATABLE :: alpha(:)     ! Back stress tensor (Voigt: 6 components)

    ! Hardening parameter
    REAL(wp) :: kappa = 0.0_wp            ! Hardening parameter

    ! Initialization flag
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => VM_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => VM_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => VM_MatState_InitFromInputs
  END TYPE VM_MatState

  !> @brief Von Mises material context (Ctx category)
  !! Runtime context information
  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: VM_MatCtx
    INTEGER(i4) :: ndir = 3               ! Number of direct stress components
    INTEGER(i4) :: nshr = 3               ! Number of shear stress components
    INTEGER(i4) :: ntens = 6              ! Total: ndir + nshr
    REAL(wp) :: temp = 0.0_wp             ! Temperature
    REAL(wp) :: dtime = 0.0_wp           ! Time increment
    INTEGER(i4) :: kstep = 0               ! Step number
    INTEGER(i4) :: kinc = 0                ! Increment number
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => VM_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => VM_MatCtx_InitDefaults
  END TYPE VM_MatCtx

  !> @brief Von Mises material algorithm (Algo category)
  !! Algorithm configuration parameters
  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: VM_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1  ! 1=radial return, 2=cutting plane
    REAL(wp) :: yield_tolerance = 1.0e-6_wp   ! Yield function tolerance
    LOGICAL :: use_consistent_tangent = .TRUE. ! Use consistent tangent stiffness
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => VM_MatAlgo_InitDefaults
  END TYPE VM_MatAlgo

  PUBLIC :: VM_MatDesc, VM_MatState, VM_MatCtx, VM_MatAlgo
  PUBLIC :: UF_VonMises_ValidateProps, UF_VonMises_GetStatistics

CONTAINS

  !=============================================================================
  ! VM Type-Bound Procedures
  !=============================================================================

  SUBROUTINE VM_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(VM_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    REAL(wp), PARAMETER :: TWO = 2.0_wp
    REAL(wp), PARAMETER :: THREE = 3.0_wp

    CALL init_error_status(status)

    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "VM_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF

    ! Extract properties
    this%E = props(1)
    this%nu = props(2)
    this%sigma_y0 = props(3)
    this%H = props(4)

    ! Compute derived parameters
    this%mu = this%E / (TWO * (ONE + this%nu))           ! Shear modulus
    this%lambda = this%E * this%nu / ((ONE + this%nu) * (ONE - TWO * this%nu))  ! Lame parameter
    this%K = this%E / (THREE * (ONE - TWO * this%nu))    ! Bulk modulus

    ! Set base class fields
    this%cfg%id = 201_i4  ! MD_MAT_VONMISES_MAT_ID
    this%name = "von Mises Plasticity"
    this%cfg%class_id = MD_MAT_CATEGORY_PL
    this%pop%nProps = nprops
    this%pop%nStateV = 7  ! eps_p(6) + eps_p_eqv(1)

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props

    this%init = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE VM_MatDesc_InitFromProps

  FUNCTION VM_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(VM_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid

    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp

    is_valid = .TRUE.

    IF (.NOT. this%init) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%E <= ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%nu < -ONE .OR. this%nu >= 0.5_wp) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%sigma_y0 <= ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%H < ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

  END FUNCTION VM_MatDesc_Valid

  !=============================================================================
  ! VM_MatState Type-Bound Procedures
  !=============================================================================

  SUBROUTINE VM_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(VM_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    IF (.NOT. this%init) RETURN

    n_eps_p = MIN(6, SIZE(this%eps_p, 1))

    ! Store plastic strain components
    DO i = 1, MIN(n_eps_p, nstatev)
      statev(i) = this%eps_p(i)
    END DO

    ! Store equivalent plastic strain
    IF (nstatev >= n_eps_p + 1) THEN
      statev(n_eps_p + 1) = this%eps_p_eqv
    END IF

  END SUBROUTINE VM_MatState_SyncToStateV

  SUBROUTINE VM_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(VM_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p

    n_eps_p = MIN(6, nstatev - 1)

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF

    ! Load plastic strain components
    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(i)
    END DO

    ! Load equivalent plastic strain
    IF (nstatev >= n_eps_p + 1) THEN
      this%eps_p_eqv = statev(n_eps_p + 1)
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF

    this%init = .TRUE.

  END SUBROUTINE VM_MatState_SyncFromStateV

  SUBROUTINE VM_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(VM_MatState), INTENT(INOUT) :: this
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

  END SUBROUTINE VM_MatState_InitFromInputs

  !=============================================================================
  ! VM_MatCtx Type-Bound Procedures
  !=============================================================================

  SUBROUTINE VM_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(VM_MatCtx), INTENT(INOUT) :: this
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

  END SUBROUTINE VM_MatCtx_InitFromInputs

  SUBROUTINE VM_MatCtx_InitDefaults(this)
    CLASS(VM_MatCtx), INTENT(INOUT) :: this

    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%init = .TRUE.

  END SUBROUTINE VM_MatCtx_InitDefaults

  !=============================================================================
  ! VM_MatAlgo Type-Bound Procedures
  !=============================================================================

  SUBROUTINE VM_MatAlgo_InitDefaults(this)
    CLASS(VM_MatAlgo), INTENT(INOUT) :: this

    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%init = .TRUE.

  END SUBROUTINE VM_MatAlgo_InitDefaults

  !=============================================================================
  ! Legacy props-array contract (same layout as VM_MatDesc_InitFromProps: E,nu,sy0,H)
  !=============================================================================

  SUBROUTINE UF_VonMises_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CHARACTER(LEN=32) :: reqch, prvch
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp

    CALL init_error_status(status)

    IF (nprops < MD_MAT_VM_MIN_PROPS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      WRITE (reqch, '(I0)') MD_MAT_VM_MIN_PROPS
      WRITE (prvch, '(I0)') nprops
      status%message = "Insufficient Mat parameters for Von Mises. " // &
                       "Required: " // TRIM(reqch) // ", Provided: " // TRIM(prvch)
      RETURN
    END IF

    IF (props(MD_MAT_VM_PROP_E) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Young's modulus must be positive"
      RETURN
    END IF

    IF (props(MD_MAT_VM_PROP_NU) < -ONE .OR. props(MD_MAT_VM_PROP_NU) >= 0.5_wp) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Poisson's ratio must be in [-1, 0.5)"
      RETURN
    END IF

    IF (props(MD_MAT_VM_PROP_SY0) <= ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Initial yield stress must be positive"
      RETURN
    END IF

    IF (props(MD_MAT_VM_PROP_H) < ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Hardening modulus cannot be negative"
      RETURN
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_VonMises_ValidateProps

  SUBROUTINE UF_VonMises_GetStatistics(props, nprops, stats, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (nprops >= MD_MAT_VM_MIN_PROPS) THEN
      WRITE (stats, '(A,A,ES12.5,A,F6.3,A,ES12.5,A,ES12.5)') &
        'Von Mises Plastic Statistics: name="', TRIM(MD_MAT_VONMISES_MAT_NA), &
        '", E=', props(MD_MAT_VM_PROP_E), &
        ', nu=', props(MD_MAT_VM_PROP_NU), &
        ', sigma_y0=', props(MD_MAT_VM_PROP_SY0), &
        ', H=', props(MD_MAT_VM_PROP_H)
    ELSE
      stats = "Von Mises Plastic Statistics: Insufficient properties"
    END IF

    IF (PRESENT(status)) status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_VonMises_GetStatistics

END MODULE MD_Mat_Plast_J2

