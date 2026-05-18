!===============================================================================
! MODULE:  MD_BC_Def
! LAYER:   L3_MD
! DOMAIN:  BC
! ROLE:    _Def - four-type authority
! BRIEF:   BC-only constants, enumerations, and four-type definitions.
!===============================================================================
MODULE MD_BC_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: &
    BC_FAMILY_DISP   = 1_i4, &
    BC_FAMILY_VEL    = 2_i4, &
    BC_FAMILY_ACC    = 3_i4, &
    BC_FAMILY_POT    = 4_i4, &
    BC_FAMILY_TEMP   = 5_i4, &
    BC_FAMILY_MASFL  = 6_i4

  INTEGER(i4), PARAMETER, PUBLIC :: &
    BC_DISPLACEMENT   = 1_i4, &
    BC_VELOCITY       = 2_i4, &
    BC_ACCELERATION   = 3_i4, &
    BC_SYMMETRY       = 4_i4, &
    BC_ANTISYMMETRY   = 5_i4, &
    BC_ENCASTRE       = 6_i4, &
    BC_PINNED         = 7_i4

  INTEGER(i4), PARAMETER, PUBLIC :: &
    IC_TEMPERATURE    = 1_i4, &
    IC_VELOCITY       = 2_i4, &
    IC_STRESS         = 3_i4, &
    IC_DISPLACEMENT   = 4_i4, &
    IC_FIELD          = 5_i4, &
    IC_PRESSURE       = 6_i4, &
    IC_SATURATION     = 7_i4, &
    IC_VOID_RATIO     = 8_i4

  TYPE, PUBLIC :: MD_BC_Desc
    INTEGER(i4)       :: bc_id = 0_i4
    INTEGER(i4)       :: bc_family = 0_i4
    CHARACTER(LEN=64) :: bc_name = ""
    LOGICAL           :: is_initialized = .FALSE.
    INTEGER(i4) :: node_set_id = 0_i4
    INTEGER(i4) :: dof_start = 1_i4
    INTEGER(i4) :: dof_end = 6_i4
    INTEGER(i4) :: bc_type = 0_i4
    REAL(wp) :: magnitude = 0.0_wp
    INTEGER(i4) :: amplitude_id = 0_i4
    INTEGER(i4) :: field_type = 0_i4
  CONTAINS
    PROCEDURE :: Init => BC_Desc_Init
    PROCEDURE :: Reset => BC_Desc_Reset
  END TYPE MD_BC_Desc

  TYPE, PUBLIC :: MD_BC_State
    REAL(wp) :: accumulated = 0.0_wp
    REAL(wp) :: last_value = 0.0_wp
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: iterations = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_BC_State

  TYPE, PUBLIC :: MD_BC_Algo
    INTEGER(i4) :: apply_mode = 1_i4
    REAL(wp) :: penalty_factor = 1.0e12_wp
    REAL(wp) :: ramp_fraction = 1.0_wp
    LOGICAL :: use_ramp = .FALSE.
    REAL(wp) :: lagrange_multiplier = 0.0_wp
  END TYPE MD_BC_Algo

  TYPE, PUBLIC :: MD_BC_Domain
    TYPE(MD_BC_Desc), ALLOCATABLE :: bcs(:)
    INTEGER(i4) :: n_bcs = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => BC_Domain_Init
    PROCEDURE :: Finalize => BC_Domain_Finalize
    PROCEDURE :: AddBC => BC_Domain_AddBC
    PROCEDURE :: GetBC => BC_Domain_GetBC
  END TYPE MD_BC_Domain

CONTAINS

  SUBROUTINE BC_Desc_Init(this)
    CLASS(MD_BC_Desc), INTENT(INOUT) :: this
    this%bc_id = 0_i4
    this%bc_family = 0_i4
    this%bc_name = ""
    this%is_initialized = .FALSE.
    this%node_set_id = 0_i4
    this%dof_start = 1_i4
    this%dof_end = 6_i4
    this%bc_type = 0_i4
    this%magnitude = 0.0_wp
    this%amplitude_id = 0_i4
    this%field_type = 0_i4
  END SUBROUTINE

  SUBROUTINE BC_Desc_Reset(this)
    CLASS(MD_BC_Desc), INTENT(INOUT) :: this
    CALL this%Init()
  END SUBROUTINE

  SUBROUTINE BC_Domain_Init(this, status)
    CLASS(MD_BC_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    this%n_bcs = 0_i4
    this%initialized = .TRUE.
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE BC_Domain_Finalize(this, status)
    CLASS(MD_BC_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (ALLOCATED(this%bcs)) DEALLOCATE(this%bcs)
    this%n_bcs = 0_i4
    this%initialized = .FALSE.
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE BC_Domain_AddBC(this, bc, status)
    CLASS(MD_BC_Domain), INTENT(INOUT) :: this
    TYPE(MD_BC_Desc), INTENT(IN) :: bc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_BC_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n
    CALL init_error_status(status)
    n = this%n_bcs + 1
    IF (ALLOCATED(this%bcs)) THEN
      ALLOCATE(tmp(n), SOURCE=this%bcs)
      DEALLOCATE(this%bcs)
    ELSE
      ALLOCATE(tmp(n))
    END IF
    tmp(n) = bc
    CALL MOVE_ALLOC(tmp, this%bcs)
    this%n_bcs = n
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE BC_Domain_GetBC(this, idx, bc, found)
    CLASS(MD_BC_Domain), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: idx
    TYPE(MD_BC_Desc), INTENT(OUT) :: bc
    LOGICAL, INTENT(OUT) :: found
    found = .FALSE.
    IF (.NOT. ALLOCATED(this%bcs)) RETURN
    IF (idx < 1 .OR. idx > this%n_bcs) RETURN
    bc = this%bcs(idx)
    found = .TRUE.
  END SUBROUTINE

END MODULE MD_BC_Def
