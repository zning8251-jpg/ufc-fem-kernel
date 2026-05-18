!===============================================================================
! MODULE: MD_MatVSC_Def
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Viscoelastic/Viscoplastic/Creep family Desc/State/Ctx/Algo types.
!         Models: RateFoamExt, NL_Visc, ViscPlast, PolymerCure, etc.
!         **W1**：**`*_MatDesc`**（如 **PronyVisc**）+ **InitFromProps**；**props** 与 **Populate**/**`desc%props`**、**PH_MAT_VISCOELASTIC** 协同。
!===============================================================================

MODULE MD_Mat_Visco_Contract

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_FOAM, MD_MAT_CATEGORY_VI

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PronyVisc (Prony Series Linear Viscoelastic)
  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: PronyVisc_MatDesc
    REAL(wp) :: MD_MAT_E_inf = 0.0_wp, nu = 0.0_wp
    INTEGER(i4) :: n_prony = 0
    REAL(wp), ALLOCATABLE :: g_prony(:), tau_prony(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => PronyVisc_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => PronyVisc_MatDesc_Valid
  END TYPE PronyVisc_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: PronyVisc_MatState
    REAL(wp), ALLOCATABLE :: q_prony(:,:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => PronyVisc_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => PronyVisc_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => PronyVisc_MatState_InitFromInputs
  END TYPE PronyVisc_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: PronyVisc_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => PronyVisc_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => PronyVisc_MatCtx_InitDefaults
  END TYPE PronyVisc_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PronyVisc_MatAlgo
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => PronyVisc_MatAlgo_InitDefaults
  END TYPE PronyVisc_MatAlgo

  !=============================================================================
  ! RateFoamExt (Rate-Dependent Foam Extended)
  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: RateFoamExt_MatDesc
    REAL(wp) :: MD_MAT_E_inf = 0.0_wp, nu_inf = 0.0_wp
    INTEGER(i4) :: n_prony = 0
    REAL(wp), ALLOCATABLE :: g_prony(:), tau_prony(:)
    REAL(wp) :: sigma_y = 0.0_wp, H_iso = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => RateFoamExt_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => RateFoamExt_MatDesc_Valid
  END TYPE RateFoamExt_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: RateFoamExt_MatState
    REAL(wp) :: eps_vol_pl = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_p(:), q_prony(:,:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => RateFoamExt_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => RateFoamExt_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => RateFoamExt_MatState_InitFromInputs
  END TYPE RateFoamExt_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: RateFoamExt_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => RateFoamExt_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => RateFoamExt_MatCtx_InitDefaults
  END TYPE RateFoamExt_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: RateFoamExt_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => RateFoamExt_MatAlgo_InitDefaults
  END TYPE RateFoamExt_MatAlgo

CONTAINS

  !=============================================================================
  ! PronyVisc Type-Bound Procedures
  !=============================================================================

  SUBROUTINE PronyVisc_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(PronyVisc_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "PronyVisc_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%MD_MAT_E_inf = props(1)
    this%nu = props(2)
    IF (nprops >= 4) this%n_prony = MAX(0_i4, MIN(10_i4, INT(props(4))))
    IF (this%n_prony > 0 .AND. nprops >= 4 + 2 * this%n_prony) THEN
      IF (.NOT. ALLOCATED(this%g_prony)) THEN
        ALLOCATE(this%g_prony(this%n_prony), this%tau_prony(this%n_prony))
      END IF
      DO i = 1, this%n_prony
        this%g_prony(i) = props(4 + i)
        this%tau_prony(i) = props(4 + this%n_prony + i)
      END DO
    END IF
    this%cfg%id = 401_i4
    this%name = "Prony Viscoelastic"
    this%cfg%class_id = MD_MAT_CATEGORY_VI
    this%pop%nProps = nprops
    this%pop%nStateV = 6 * MAX(1, this%n_prony)
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE PronyVisc_MatDesc_InitFromProps

  FUNCTION PronyVisc_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(PronyVisc_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_inf > ZERO
  END FUNCTION PronyVisc_MatDesc_Valid

  SUBROUTINE PronyVisc_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(PronyVisc_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (ALLOCATED(this%q_prony)) THEN
      DO i = 1, MIN(SIZE(this%q_prony, 1), (nstatev - offset) / 6)
        DO j = 1, MIN(6, SIZE(this%q_prony, 2))
          IF (offset + j <= nstatev) statev(offset + j) = this%q_prony(i, j)
        END DO
        offset = offset + 6
      END DO
    END IF
  END SUBROUTINE PronyVisc_MatState_SyncToStateV

  SUBROUTINE PronyVisc_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(PronyVisc_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, offset
    offset = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE PronyVisc_MatState_SyncFromStateV

  SUBROUTINE PronyVisc_MatState_InitFromInputs(this, ndir, nshr, n_prony)
    CLASS(PronyVisc_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr, n_prony
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (n_prony > 0) THEN
      IF (.NOT. ALLOCATED(this%q_prony)) THEN
        ALLOCATE(this%q_prony(n_prony, ntens))
        this%q_prony = 0.0_wp
      END IF
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
    this%is_initialized = .TRUE.
  END SUBROUTINE PronyVisc_MatState_InitFromInputs

  SUBROUTINE PronyVisc_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(PronyVisc_MatCtx), INTENT(INOUT) :: this
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
    this%is_initialized = .TRUE.
  END SUBROUTINE PronyVisc_MatCtx_InitFromInputs

  SUBROUTINE PronyVisc_MatCtx_InitDefaults(this)
    CLASS(PronyVisc_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE PronyVisc_MatCtx_InitDefaults

  SUBROUTINE PronyVisc_MatAlgo_InitDefaults(this)
    CLASS(PronyVisc_MatAlgo), INTENT(INOUT) :: this
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE PronyVisc_MatAlgo_InitDefaults

  !=============================================================================
  ! RateFoamExt Type-Bound Procedures
  !=============================================================================

  SUBROUTINE RateFoamExt_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(RateFoamExt_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateFoamExt_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%MD_MAT_E_inf = props(1)
    this%nu_inf = props(2)
    this%sigma_y = props(3)
    this%H_iso = props(4)
    IF (nprops >= 5) this%n_prony = MAX(0_i4, MIN(10_i4, INT(props(5))))
    IF (this%n_prony > 0 .AND. nprops >= 5 + 2 * this%n_prony) THEN
      IF (.NOT. ALLOCATED(this%g_prony)) THEN
        ALLOCATE(this%g_prony(this%n_prony), this%tau_prony(this%n_prony))
      END IF
      DO i = 1, this%n_prony
        this%g_prony(i) = props(5 + i)
        this%tau_prony(i) = props(5 + this%n_prony + i)
      END DO
    END IF
    this%cfg%id = 510_i4
    this%name = "Rate-Dependent Foam Extended"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 7 + 6 * this%n_prony
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE RateFoamExt_MatDesc_InitFromProps

  FUNCTION RateFoamExt_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(RateFoamExt_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_inf > ZERO .AND. this%sigma_y > ZERO
  END FUNCTION RateFoamExt_MatDesc_Valid

  SUBROUTINE RateFoamExt_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(RateFoamExt_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, n_eps_p, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_vol_pl
      offset = offset + 1
    END IF
    n_eps_p = MIN(6, SIZE(this%eps_p, 1))
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO
    offset = offset + n_eps_p
    IF (ALLOCATED(this%q_prony)) THEN
      DO i = 1, MIN(SIZE(this%q_prony, 1), (nstatev - offset) / 6)
        DO j = 1, MIN(6, SIZE(this%q_prony, 2))
          IF (offset + j <= nstatev) statev(offset + j) = this%q_prony(i, j)
        END DO
        offset = offset + 6
      END DO
    END IF
  END SUBROUTINE RateFoamExt_MatState_SyncToStateV

  SUBROUTINE RateFoamExt_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(RateFoamExt_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, n_eps_p, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%eps_vol_pl = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_vol_pl = 0.0_wp
    END IF
    n_eps_p = MIN(6, nstatev - offset)
    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF
    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(offset + i)
    END DO
    offset = offset + n_eps_p
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoamExt_MatState_SyncFromStateV

  SUBROUTINE RateFoamExt_MatState_InitFromInputs(this, ndir, nshr, n_prony)
    CLASS(RateFoamExt_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr, n_prony
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF
    IF (n_prony > 0) THEN
      IF (.NOT. ALLOCATED(this%q_prony)) THEN
        ALLOCATE(this%q_prony(n_prony, ntens))
        this%q_prony = 0.0_wp
      END IF
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
    this%eps_vol_pl = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoamExt_MatState_InitFromInputs

  SUBROUTINE RateFoamExt_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(RateFoamExt_MatCtx), INTENT(INOUT) :: this
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
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoamExt_MatCtx_InitFromInputs

  SUBROUTINE RateFoamExt_MatCtx_InitDefaults(this)
    CLASS(RateFoamExt_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoamExt_MatCtx_InitDefaults

  SUBROUTINE RateFoamExt_MatAlgo_InitDefaults(this)
    CLASS(RateFoamExt_MatAlgo), INTENT(INOUT) :: this
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoamExt_MatAlgo_InitDefaults

END MODULE MD_Mat_Visco_Contract
