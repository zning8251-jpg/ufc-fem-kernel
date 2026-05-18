!===============================================================================
! MODULE:  MD_LBC_Domain
! LAYER:   L3_MD
! DOMAIN:  Boundary [DEPRECATED]
! ROLE:    _Domain — retained for backward compatibility
! BRIEF:   LoadBC domain aggregate.
!
! DEPRECATED (Phase 3): Types migrated to L3_MD/LoadBC/MD_LBC_Def.f90.
!   New code should USE MD_LoadBC_Def instead.
!===============================================================================

MODULE MD_LBC_Domain
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core,    ONLY: wp, i4
    ! New types from MD_BC_Def and MD_Load_Def (four-kind aligned)
  USE MD_BC_Def, ONLY: MD_BC_Base_Desc => MD_BC_Base_Desc, &
                        MD_BC_Base_State => MD_BC_Base_State, &
                        MD_BC_Base_Algo => MD_BC_Base_Algo, &
                        MD_BC_Base_Ctx => MD_BC_Base_Ctx
  USE MD_Load_Def, ONLY: MD_Load_Base_Desc => MD_Load_Base_Desc, &
                         MD_Load_Base_State => MD_Load_Base_State, &
                         MD_Load_Base_Algo => MD_Load_Base_Algo, &
                         MD_Load_Base_Ctx => MD_Load_Base_Ctx, &
                         MD_LoadBC_State => MD_LoadBC_State, &
                         MD_LoadBC_Algo => MD_LoadBC_Algo, &
                         MD_LoadBC_Ctx => MD_LoadBC_Ctx
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Load/BC/IC type enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CLOAD        = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_DLOAD        = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_DSLOAD       = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_BODY_FORCE   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_GRAVITY      = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_CENTRIFUGAL  = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_TEMPERATURE  = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOAD_PRESSURE     = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_DISPLACEMENT   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_VELOCITY       = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_ACCELERATION   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_SYMMETRY       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_ANTISYMMETRY   = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_ENCASTRE       = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: BC_PINNED         = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_TEMPERATURE    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_VELOCITY       = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_STRESS        = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_DISPLACEMENT   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_FIELD          = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_PRESSURE       = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_SATURATION    = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IC_VOID_RATIO     = 8_i4

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_Algo
  ! KIND:  Algo
  ! DESC:  Legacy shim — default amplitude, ramp mode, scale factor.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_Algo
    INTEGER(i4) :: default_amp_type = 0_i4
    INTEGER(i4) :: ramp_mode        = 0_i4
    LOGICAL     :: auto_scale       = .TRUE.
    REAL(wp)    :: scale_factor     = 1.0_wp
  END TYPE MD_LBC_Algo

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_Ctx
  ! KIND:  Ctx
  ! DESC:  Runtime context — current load/BC/IC IDs + last operation.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_Ctx
    INTEGER(i4) :: current_load_id   = 0_i4
    INTEGER(i4) :: current_bc_id     = 0_i4
    INTEGER(i4) :: current_ic_id     = 0_i4
    INTEGER(i4) :: operation_type    = 0_i4
    INTEGER(i4) :: last_step_idx     = 0_i4
    INTEGER(i4) :: last_incr_idx     = 0_i4   ! [ ]
    CHARACTER(LEN=64) :: last_operation = ""
  END TYPE MD_LBC_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Load_Desc
  ! KIND:  Desc
  ! DESC:  Single load descriptor — type, target set, magnitude, amplitude ref.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Load_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: load_id    = 0_i4
    INTEGER(i4)       :: load_type  = LOAD_CLOAD
    CHARACTER(LEN=64) :: target_set = ""
    INTEGER(i4)       :: dof        = 0_i4
    INTEGER(i4)       :: node_id    = 0_i4
    REAL(wp)          :: magnitude  = 0.0_wp
    INTEGER(i4)       :: amp_ref    = 0_i4
    INTEGER(i4)       :: step_ref   = 0_i4
  END TYPE MD_Load_Desc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Load_State
  ! KIND:  State
  ! DESC:  Single load runtime state — scale, active flag, step/incr index.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Load_State
    REAL(wp)    :: currentLoadScale = 0.0_wp
    LOGICAL     :: isActive         = .TRUE.
    ! [Data chain] three-step indexing L3 -> L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_Load_State

  !---------------------------------------------------------------------------
  ! TYPE:  MD_BC_Desc
  ! KIND:  Desc
  ! DESC:  Single BC descriptor — type, target set, DOF range, value.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: bc_id      = 0_i4
    INTEGER(i4)       :: bc_type    = BC_DISPLACEMENT
    CHARACTER(LEN=64) :: target_set = ""
    INTEGER(i4)       :: dof        = 0_i4
    INTEGER(i4)       :: dof_last   = 0_i4
    INTEGER(i4)       :: node_id    = 0_i4
    INTEGER(i4)       :: region_type= 0_i4
    REAL(wp)          :: value      = 0.0_wp
    INTEGER(i4)       :: amp_ref    = 0_i4
    INTEGER(i4)       :: step_ref   = 0_i4
  END TYPE MD_BC_Desc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_BC_State
  ! KIND:  State
  ! DESC:  Single BC runtime state — current value, active, step/incr index.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_State
    REAL(wp)    :: currentValue = 0.0_wp
    LOGICAL     :: isActive     = .TRUE.
    ! [Data chain] three-step indexing L3 -> L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_BC_State

  !---------------------------------------------------------------------------
  ! TYPE:  MD_IC_Desc
  ! KIND:  Desc
  ! DESC:  Initial condition descriptor — type, target set, value array.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_IC_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: ic_id      = 0_i4
    INTEGER(i4)       :: ic_type    = IC_TEMPERATURE
    CHARACTER(LEN=64) :: target_set = ""
    INTEGER(i4)       :: dof        = 0_i4
    REAL(wp)          :: value      = 0.0_wp
    REAL(wp)          :: values(6)  = 0.0_wp
    INTEGER(i4)       :: field_var  = 0_i4
  END TYPE MD_IC_Desc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetSummary_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetSummary — summary string + error status.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_LBC_GetSummary_Arg

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_Domain
  ! KIND:  Desc
  ! DESC:  Domain container — loads + BCs + ICs + state + algo (TBP lifecycle).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_Domain
    TYPE(MD_Load_Desc), ALLOCATABLE :: loads(:)
    TYPE(MD_BC_Desc),   ALLOCATABLE :: bcs(:)
    TYPE(MD_IC_Desc),   ALLOCATABLE :: initial_conds(:)
    INTEGER(i4)                     :: n_loads = 0_i4
    INTEGER(i4)                     :: n_bcs   = 0_i4
    INTEGER(i4)                     :: n_ics   = 0_i4
    TYPE(MD_Load_State), ALLOCATABLE :: load_state(:)
    TYPE(MD_BC_State),   ALLOCATABLE :: bc_state(:)
    TYPE(MD_LBC_Algo) :: algo
    INTEGER(i4) :: cap_loads = 0_i4
    INTEGER(i4) :: cap_bcs   = 0_i4
    INTEGER(i4) :: cap_ics   = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddLoad
    PROCEDURE :: AddBC
    PROCEDURE :: AddInitialCondition
    PROCEDURE :: GetLoadsForStep
    PROCEDURE :: GetBCsForStep
    PROCEDURE :: GetLoad
    PROCEDURE :: GetBC
    PROCEDURE :: GetInitialCondition
    PROCEDURE :: GetICsByType
    PROCEDURE :: GetLoadByName
    PROCEDURE :: GetBCByName
    PROCEDURE :: GetLoadsByType
    PROCEDURE :: GetBCsByType
    PROCEDURE :: ActivateForStep
    PROCEDURE :: RegisterLoadType
    PROCEDURE :: RegisterBCType
    PROCEDURE :: WriteBack
    PROCEDURE :: GetSummary
  END TYPE MD_LoadBC_Domain

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetLoadsForStep_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetLoadsForStep — load indices + count.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetLoadsForStep_Arg
    INTEGER(i4), ALLOCATABLE :: load_indices(:)
    INTEGER(i4) :: n_found = 0_i4
  END TYPE MD_LBC_GetLoadsForStep_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetBCsForStep_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetBCsForStep — BC indices + count.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetBCsForStep_Arg
    INTEGER(i4), ALLOCATABLE :: bc_indices(:)
    INTEGER(i4) :: n_found = 0_i4
  END TYPE MD_LBC_GetBCsForStep_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetBC_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetBC — single BC descriptor output.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetBC_Arg
    TYPE(MD_BC_Desc) :: desc
  END TYPE MD_LBC_GetBC_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetLoad_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetLoad — single load descriptor output.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetLoad_Arg
    TYPE(MD_Load_Desc) :: desc
  END TYPE MD_LBC_GetLoad_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetLoadByName_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetLoadByName — index + found flag.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetLoadByName_Arg
    INTEGER(i4) :: load_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_LBC_GetLoadByName_Arg
  !---------------------------------------------------------------------------
  ! TYPE:  MD_LBC_GetBCByName_Arg
  ! KIND:  Arg
  ! DESC:  Arg bundle for GetBCByName — index + found flag.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LBC_GetBCByName_Arg
    INTEGER(i4) :: bc_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_LBC_GetBCByName_Arg

  ! Idx API: see MODULE MD_LBC_Idx (UFC_Global_Init: MD_LoadBC_Idx_Bind(md_layer%loadbc)).

CONTAINS

  !====================================================================
  ! Type-bound procedure implementations (no g_ufc_global; use this%frozen)
  !====================================================================
  SUBROUTINE Init(this, est_loads, est_bcs, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: est_loads, est_bcs
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%cap_loads = MAX(16_i4, est_loads)
    this%cap_bcs   = MAX(16_i4, est_bcs)
    this%cap_ics   = 8_i4
    ALLOCATE(this%loads(this%cap_loads))
    ALLOCATE(this%bcs(this%cap_bcs))
    ALLOCATE(this%initial_conds(this%cap_ics))
    ALLOCATE(this%load_state(this%cap_loads))
    ALLOCATE(this%bc_state(this%cap_bcs))
    this%n_loads     = 0_i4
    this%n_bcs       = 0_i4
    this%n_ics       = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  SUBROUTINE Finalize(this)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    IF (ALLOCATED(this%loads))         DEALLOCATE(this%loads)
    IF (ALLOCATED(this%bcs))           DEALLOCATE(this%bcs)
    IF (ALLOCATED(this%initial_conds)) DEALLOCATE(this%initial_conds)
    IF (ALLOCATED(this%load_state))    DEALLOCATE(this%load_state)
    IF (ALLOCATED(this%bc_state))      DEALLOCATE(this%bc_state)
    this%n_loads     = 0_i4
    this%n_bcs       = 0_i4
    this%n_ics       = 0_i4
    this%cap_loads   = 0_i4
    this%cap_bcs     = 0_i4
    this%cap_ics     = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE AddBC(this, desc, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    TYPE(MD_BC_Desc),        INTENT(IN)    :: desc
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    TYPE(MD_BC_Desc),  ALLOCATABLE :: tmp_d(:)
    TYPE(MD_BC_State), ALLOCATABLE :: tmp_s(:)
    INTEGER(i4) :: new_cap
    CALL init_error_status(status)
    IF (this%frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddBC not allowed"
      RETURN
    END IF
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (this%n_bcs >= this%cap_bcs) THEN
      new_cap = MAX(16_i4, this%cap_bcs * 2_i4)
      ALLOCATE(tmp_d(new_cap)); ALLOCATE(tmp_s(new_cap))
      IF (this%n_bcs > 0) THEN
        tmp_d(1:this%n_bcs) = this%bcs(1:this%n_bcs)
        tmp_s(1:this%n_bcs) = this%bc_state(1:this%n_bcs)
      END IF
      CALL MOVE_ALLOC(tmp_d, this%bcs)
      CALL MOVE_ALLOC(tmp_s, this%bc_state)
      this%cap_bcs = new_cap
    END IF
    this%n_bcs = this%n_bcs + 1_i4
    this%bcs(this%n_bcs) = desc
    this%bcs(this%n_bcs)%bc_id = this%n_bcs
    this%bc_state(this%n_bcs)%currentValue = desc%value
    this%bc_state(this%n_bcs)%isActive     = .TRUE.
    this%bc_state(this%n_bcs)%step_idx     = 0_i4
    this%bc_state(this%n_bcs)%incr_idx     = 0_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddBC

  SUBROUTINE AddLoad(this, desc, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    TYPE(MD_Load_Desc),      INTENT(IN)    :: desc
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    TYPE(MD_Load_Desc),  ALLOCATABLE :: tmp_d(:)
    TYPE(MD_Load_State), ALLOCATABLE :: tmp_s(:)
    INTEGER(i4) :: new_cap
    CALL init_error_status(status)
    IF (this%frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "L3 frozen: AddLoad not allowed"
      RETURN
    END IF
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (this%n_loads >= this%cap_loads) THEN
      new_cap = MAX(16_i4, this%cap_loads * 2_i4)
      ALLOCATE(tmp_d(new_cap)); ALLOCATE(tmp_s(new_cap))
      IF (this%n_loads > 0) THEN
        tmp_d(1:this%n_loads) = this%loads(1:this%n_loads)
        tmp_s(1:this%n_loads) = this%load_state(1:this%n_loads)
      END IF
      CALL MOVE_ALLOC(tmp_d, this%loads)
      CALL MOVE_ALLOC(tmp_s, this%load_state)
      this%cap_loads = new_cap
    END IF
    this%n_loads = this%n_loads + 1_i4
    this%loads(this%n_loads) = desc
    this%loads(this%n_loads)%load_id = this%n_loads
    this%load_state(this%n_loads)%currentLoadScale = desc%magnitude
    this%load_state(this%n_loads)%isActive         = .TRUE.
    this%load_state(this%n_loads)%step_idx         = 0_i4
    this%load_state(this%n_loads)%incr_idx         = 0_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddLoad

  SUBROUTINE AddInitialCondition(this, desc, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    TYPE(MD_IC_Desc),        INTENT(IN)    :: desc
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    TYPE(MD_IC_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (this%n_ics >= this%cap_ics) THEN
      new_cap = MAX(8_i4, this%cap_ics * 2_i4)
      ALLOCATE(tmp(new_cap))
      IF (this%n_ics > 0) tmp(1:this%n_ics) = this%initial_conds(1:this%n_ics)
      CALL MOVE_ALLOC(tmp, this%initial_conds)
      this%cap_ics = new_cap
    END IF
    this%n_ics = this%n_ics + 1_i4
    this%initial_conds(this%n_ics) = desc
    this%initial_conds(this%n_ics)%ic_id = this%n_ics
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddInitialCondition

  SUBROUTINE GetLoadsForStep(this, step_idx, load_indices, n_found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: step_idx
    INTEGER(i4),             INTENT(OUT) :: load_indices(:)
    INTEGER(i4),             INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_loads
      IF (this%loads(i)%step_ref == step_idx) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(load_indices)) load_indices(n_found) = i
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetLoadsForStep

  SUBROUTINE GetBCsForStep(this, step_idx, bc_indices, n_found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: step_idx
    INTEGER(i4),             INTENT(OUT) :: bc_indices(:)
    INTEGER(i4),             INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_bcs
      IF (this%bcs(i)%step_ref == step_idx) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(bc_indices)) bc_indices(n_found) = i
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetBCsForStep

  SUBROUTINE GetLoad(this, idx, desc, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: idx
    TYPE(MD_Load_Desc),      INTENT(OUT) :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_loads) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    desc = this%loads(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetLoad

  SUBROUTINE GetBC(this, idx, desc, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: idx
    TYPE(MD_BC_Desc),        INTENT(OUT) :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_bcs) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    desc = this%bcs(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetBC

  SUBROUTINE GetInitialCondition(this, idx, desc, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: idx
    TYPE(MD_IC_Desc),        INTENT(OUT) :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_ics) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    desc = this%initial_conds(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetInitialCondition

  SUBROUTINE GetICsByType(this, ic_type, ic_indices, n_found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: ic_type
    INTEGER(i4),             INTENT(OUT) :: ic_indices(:)
    INTEGER(i4),             INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_ics
      IF (this%initial_conds(i)%ic_type == ic_type) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(ic_indices)) ic_indices(n_found) = i
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetICsByType

  SUBROUTINE GetLoadByName(this, name, load_idx, found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),        INTENT(IN)  :: name
    INTEGER(i4),             INTENT(OUT) :: load_idx
    LOGICAL,                 INTENT(OUT) :: found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    load_idx = 0_i4
    found = .FALSE.
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "LoadBC domain not initialized"
      RETURN
    END IF
    DO i = 1, this%n_loads
      IF (TRIM(this%loads(i)%name) == TRIM(name)) THEN
        found = .TRUE.
        load_idx = i
        EXIT
      END IF
    END DO
    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "Load '", TRIM(name), "' not found"
    END IF
  END SUBROUTINE GetLoadByName

  SUBROUTINE GetBCByName(this, name, bc_idx, found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),        INTENT(IN)  :: name
    INTEGER(i4),             INTENT(OUT) :: bc_idx
    LOGICAL,                 INTENT(OUT) :: found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    bc_idx = 0_i4
    found = .FALSE.
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "LoadBC domain not initialized"
      RETURN
    END IF
    DO i = 1, this%n_bcs
      IF (TRIM(this%bcs(i)%name) == TRIM(name)) THEN
        found = .TRUE.
        bc_idx = i
        EXIT
      END IF
    END DO
    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "BC '", TRIM(name), "' not found"
    END IF
  END SUBROUTINE GetBCByName

  SUBROUTINE WriteBack(this, load_idx, bc_idx, load_scale, load_active, bc_value, bc_active, &
       status, step_idx, incr_idx)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: load_idx, bc_idx
    REAL(wp),                INTENT(IN)    :: load_scale, bc_value
    LOGICAL,                 INTENT(IN)    :: load_active, bc_active
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4),             INTENT(IN), OPTIONAL :: step_idx, incr_idx
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (load_idx > 0 .AND. load_idx <= this%n_loads) THEN
      this%load_state(load_idx)%currentLoadScale = load_scale
      this%load_state(load_idx)%isActive         = load_active
      IF (PRESENT(step_idx)) this%load_state(load_idx)%step_idx = step_idx
      IF (PRESENT(incr_idx)) this%load_state(load_idx)%incr_idx = incr_idx
    END IF
    IF (bc_idx > 0 .AND. bc_idx <= this%n_bcs) THEN
      this%bc_state(bc_idx)%currentValue = bc_value
      this%bc_state(bc_idx)%isActive     = bc_active
      IF (PRESENT(step_idx)) this%bc_state(bc_idx)%step_idx = step_idx
      IF (PRESENT(incr_idx)) this%bc_state(bc_idx)%incr_idx = incr_idx
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE WriteBack

  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_LoadBC_Domain),        INTENT(IN)    :: this
    TYPE(MD_LBC_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%summary = "LoadBC Domain: not initialized"
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    WRITE(arg%summary, '(A,I0,A,I0,A,I0)') &
      "LoadBC Summary: n_loads=", this%n_loads, &
      ", n_bcs=", this%n_bcs, &
      ", n_ics=", this%n_ics
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE GetSummary

  !====================================================================
  ! GetLoadsByType
  ! Query loads matching a given load_type.
  !====================================================================
  SUBROUTINE GetLoadsByType(this, load_type, load_indices, n_found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: load_type
    INTEGER(i4),             INTENT(OUT) :: load_indices(:)
    INTEGER(i4),             INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_loads
      IF (this%loads(i)%load_type == load_type) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(load_indices)) load_indices(n_found) = i
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetLoadsByType

  !====================================================================
  ! GetBCsByType
  ! Query BCs matching a given bc_type.
  !====================================================================
  SUBROUTINE GetBCsByType(this, bc_type, bc_indices, n_found, status)
    CLASS(MD_LoadBC_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: bc_type
    INTEGER(i4),             INTENT(OUT) :: bc_indices(:)
    INTEGER(i4),             INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_bcs
      IF (this%bcs(i)%bc_type == bc_type) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(bc_indices)) bc_indices(n_found) = i
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetBCsByType

  !====================================================================
  ! ActivateForStep
  ! Activate/deactivate loads and BCs for a given analysis step.
  ! Sets load_state%isActive / bc_state%isActive based on step_ref match.
  !====================================================================
  SUBROUTINE ActivateForStep(this, step_idx, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: step_idx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%n_loads
      IF (this%loads(i)%step_ref == step_idx .OR. this%loads(i)%step_ref == 0_i4) THEN
        this%load_state(i)%isActive = .TRUE.
      ELSE
        this%load_state(i)%isActive = .FALSE.
      END IF
    END DO
    DO i = 1, this%n_bcs
      IF (this%bcs(i)%step_ref == step_idx .OR. this%bcs(i)%step_ref == 0_i4) THEN
        this%bc_state(i)%isActive = .TRUE.
      ELSE
        this%bc_state(i)%isActive = .FALSE.
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE ActivateForStep

  !====================================================================
  ! RegisterLoadType
  ! Register a load type descriptor and return assigned index.
  ! Convenience wrapper for AddLoad with auto-ID assignment.
  !====================================================================
  SUBROUTINE RegisterLoadType(this, desc, assigned_idx, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    TYPE(MD_Load_Desc),      INTENT(IN)    :: desc
    INTEGER(i4),             INTENT(OUT)   :: assigned_idx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL this%AddLoad(desc, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      assigned_idx = this%n_loads
    ELSE
      assigned_idx = 0_i4
    END IF
  END SUBROUTINE RegisterLoadType

  !====================================================================
  ! RegisterBCType
  ! Register a BC type descriptor and return assigned index.
  ! Convenience wrapper for AddBC with auto-ID assignment.
  !====================================================================
  SUBROUTINE RegisterBCType(this, desc, assigned_idx, status)
    CLASS(MD_LoadBC_Domain), INTENT(INOUT) :: this
    TYPE(MD_BC_Desc),        INTENT(IN)    :: desc
    INTEGER(i4),             INTENT(OUT)   :: assigned_idx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL this%AddBC(desc, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      assigned_idx = this%n_bcs
    ELSE
      assigned_idx = 0_i4
    END IF
  END SUBROUTINE RegisterBCType

END MODULE MD_LBC_Domain
