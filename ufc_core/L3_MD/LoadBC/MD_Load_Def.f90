!===============================================================================
! MODULE:  MD_Load_Def
! LAYER:   L3_MD
! DOMAIN:  Load
! ROLE:    _Def - four-type authority
! BRIEF:   Load-only constants, enumerations, and four-type definitions.
!===============================================================================
MODULE MD_Load_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: &
    LOAD_FAMILY_DIST    = 1_i4, &
    LOAD_FAMILY_CONC    = 2_i4, &
    LOAD_FAMILY_FLUX    = 3_i4, &
    LOAD_FAMILY_FILM    = 4_i4, &
    LOAD_FAMILY_HETVAL  = 5_i4, &
    LOAD_FAMILY_BODY    = 6_i4, &
    LOAD_FAMILY_SURF    = 7_i4, &
    LOAD_FAMILY_WAVE    = 8_i4

  INTEGER(i4), PARAMETER, PUBLIC :: &
    LOAD_CLOAD        = 1_i4, &
    LOAD_DLOAD        = 2_i4, &
    LOAD_DSLOAD       = 3_i4, &
    LOAD_BODY_FORCE   = 4_i4, &
    LOAD_GRAVITY      = 5_i4, &
    LOAD_CENTRIFUGAL  = 6_i4, &
    LOAD_TEMPERATURE  = 7_i4, &
    LOAD_PRESSURE     = 8_i4

  TYPE, PUBLIC :: MD_Load_Desc
    INTEGER(i4)       :: load_id        = 0_i4
    INTEGER(i4)       :: load_family    = 0_i4
    CHARACTER(LEN=64) :: load_name      = ""
    LOGICAL           :: is_initialized = .FALSE.
    REAL(wp)          :: magnitude      = 0.0_wp
    REAL(wp)          :: scale_factor   = 1.0_wp
    INTEGER(i4)       :: time_dependence = 0_i4
    INTEGER(i4)       :: amplitude_id   = 0_i4
    INTEGER(i4)       :: load_type      = 0_i4
    INTEGER(i4)       :: element_face   = 0_i4
    INTEGER(i4)       :: node_id        = 0_i4
    INTEGER(i4)       :: dof_number     = 0_i4
    REAL(wp)          :: ambient_temp   = 0.0_wp
    REAL(wp)          :: film_coeff     = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => Load_Desc_Init
    PROCEDURE :: Reset  => Load_Desc_Reset
  END TYPE MD_Load_Desc

  TYPE, PUBLIC :: MD_Load_State
    REAL(wp) :: accumulated     = 0.0_wp
    REAL(wp) :: last_magnitude  = 0.0_wp
    REAL(wp) :: work_done       = 0.0_wp
    LOGICAL  :: converged    = .FALSE.
    INTEGER(i4) :: iterations   = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Load_State

  TYPE, PUBLIC :: MD_Load_Domain
    TYPE(MD_Load_Desc), ALLOCATABLE :: loads(:)
    INTEGER(i4)                     :: n_loads = 0_i4
    LOGICAL                         :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => Load_Domain_Init
    PROCEDURE :: Finalize => Load_Domain_Finalize
    PROCEDURE :: AddLoad  => Load_Domain_AddLoad
    PROCEDURE :: GetLoad  => Load_Domain_GetLoad
  END TYPE MD_Load_Domain

CONTAINS

  SUBROUTINE Load_Desc_Init(this)
    CLASS(MD_Load_Desc), INTENT(INOUT) :: this
    this%load_id = 0_i4
    this%load_family = 0_i4
    this%load_name = ""
    this%is_initialized = .FALSE.
    this%magnitude = 0.0_wp
    this%scale_factor = 1.0_wp
    this%time_dependence = 0_i4
    this%amplitude_id = 0_i4
    this%load_type = 0_i4
    this%element_face = 0_i4
    this%node_id = 0_i4
    this%dof_number = 0_i4
    this%ambient_temp = 0.0_wp
    this%film_coeff = 0.0_wp
  END SUBROUTINE

  SUBROUTINE Load_Desc_Reset(this)
    CLASS(MD_Load_Desc), INTENT(INOUT) :: this
    CALL this%Init()
  END SUBROUTINE

  SUBROUTINE Load_Domain_Init(this, status)
    CLASS(MD_Load_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    this%n_loads = 0_i4
    this%initialized = .TRUE.
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Load_Domain_Finalize(this, status)
    CLASS(MD_Load_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    IF (ALLOCATED(this%loads)) DEALLOCATE(this%loads)
    this%n_loads = 0_i4
    this%initialized = .FALSE.
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Load_Domain_AddLoad(this, load, status)
    CLASS(MD_Load_Domain), INTENT(INOUT) :: this
    TYPE(MD_Load_Desc), INTENT(IN) :: load
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Load_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n
    CALL init_error_status(status)
    n = this%n_loads + 1
    IF (ALLOCATED(this%loads)) THEN
      ALLOCATE(tmp(n), SOURCE=this%loads)
      DEALLOCATE(this%loads)
    ELSE
      ALLOCATE(tmp(n))
    END IF
    tmp(n) = load
    CALL MOVE_ALLOC(tmp, this%loads)
    this%n_loads = n
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE Load_Domain_GetLoad(this, idx, load, found)
    CLASS(MD_Load_Domain), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: idx
    TYPE(MD_Load_Desc), INTENT(OUT) :: load
    LOGICAL, INTENT(OUT) :: found
    found = .FALSE.
    IF (.NOT. ALLOCATED(this%loads)) RETURN
    IF (idx < 1 .OR. idx > this%n_loads) RETURN
    load = this%loads(idx)
    found = .TRUE.
  END SUBROUTINE

END MODULE MD_Load_Def
