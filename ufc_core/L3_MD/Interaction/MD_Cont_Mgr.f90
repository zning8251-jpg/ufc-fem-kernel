!======================================================================
! MODULE:  MD_Cont_Mgr
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Mgr
! BRIEF:   Contact domain container. Contact pairs, properties,
!          friction laws, writeback management.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
!   MD_Interaction_WriteBack_Active (isActive per pair).
!
! Computation chain:
!   Init:        ALLOCATE(pairs(max_pairs), props(max_props)); n_pairs=0, n_props=0.
!   AddProperty: props(n+1) = prop; n_props++; O(1).
!   AddPair:     pairs(n+1) = pair_def; n_pairs++; O(1).
!   GetProperty: linear search by name (n_props < 1000; acceptable). O(n_props).
!   GetPairsForStep: return slice or index list; O(n_pairs).
!   WriteBack_State: pair_state(idx)%gap / normal_force / tangent_force. O(1).
!   WriteBack_Active: pair_state(idx)%isActive. O(1).
!   Finalize:    DEALLOCATE(pairs, props, pair_state).
!
! Data chain:
!   Container: g_ufc_global%md_layer%interaction (TYPE :: MD_Interaction_Domain)
!   Desc (Write-Once after parse):
!     pairs(:)%master_surface / slave_surface / prop_name / formulation / adjust
!     props(:)%name / friction / cohesion / damping / pressure_overclosure
!   State (WriteBack whitelist):
!     pair_state(:)%gap           <- MD_Interaction_WriteBack_State only
!     pair_state(:)%normal_force  <- MD_Interaction_WriteBack_State only
!     pair_state(:)%tangent_force <- MD_Interaction_WriteBack_State only
!     pair_state(:)%isActive      <- MD_Interaction_WriteBack_Active only
!     pair_state(:)%contact_state <- MD_Interaction_WriteBack_State only
!   Algo (Solve-phase read-only):
!     algo%search_radius / penalty_factor / lagrange_tol / max_search_iter
!   Ctx (transient, not resident):
!     Per-pair iteration tracking held by L5_RT internally.
!
! Three-step mapping:
!   Analysis step: Init/AddProperty/AddPair (parse); GetPairsForStep (boundary).
!   Increment:     WriteBack_State (gap/forces after enforce); WriteBack_Active.
!   Iteration:     GetPairsForStep (read-only per Newton iteration).
!
! WriteBack whitelist (L5_RT -> L3_MD only via these APIs):
!   MD_Interaction_WriteBack_State:  pair_state(idx)%gap / normal_force /
!                                    tangent_force / contact_state
!   MD_Interaction_WriteBack_Active: pair_state(idx)%isActive
!   Prohibited (frozen after parse):
!     master_surface / slave_surface / prop_name / friction / cohesion / algo
!
! Contents (A-Z):
!   Types:
!     ContAlgo
!     ContCtx
!     MD_ContactPairDef
!     MD_ContactPairState
!     MD_ContactProperty
!     MD_Interaction_Domain
!   Subroutines:
!     MD_Interaction_Domain_AddPair
!     MD_Interaction_Domain_AddProperty
!     MD_Interaction_Domain_Finalize
!     MD_Interaction_Domain_GetPairsForStep
!     MD_Interaction_Domain_GetProperty
!     MD_Interaction_Domain_Init
!     MD_Interaction_Domain_ValidateAllRefs
!     MD_Interaction_WriteBack_Active
!     MD_Interaction_WriteBack_State
!
! Notes:
!   - MD_Friction_Type / MD_ContactProperty_Type in MD_Int_Def.f90.
!   - MD_ContactCtrl_Type (legacy) retired; Domain uses flat pairs/props only.
!   - MD_ContactProperty wraps the existing types; L3→L5 接触桥仅
!     `L3_MD/Bridge/Bridge_L5/MD_Int_Brg.f90`（域目录内不保留空 Brg 存根）。
!   - Logic/Computation chain diagrams: MD_Interaction_Domain_Core_Chains.md
!
! Status: Phase B (Arg-wrapped) | Last verified: 2026-03-05
! Theory: N/A
! Status: Draft
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Cont | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Interaction/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Cont | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Cont_Mgr
  USE IF_Prec_Core,                ONLY: wp, i4
  USE IF_Err_Brg,             ONLY: ErrorStatusType, init_error_status, &
                                     IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Int_Def,   ONLY: MD_Friction_Type, MD_Cohesion_Type, &
                                     MD_ContactDamping_Type, &
                                     MD_ContactProperty_Type, &
                                     MD_ContactPairDef, MD_InteractionUnion, &
                                     CONT_FORM_SURFACE, CONT_FORM_NODE, CONT_FORM_GENERAL, &
                                     CONT_STATE_OPEN, CONT_STATE_CLOSED, CONT_STATE_SLIDING
  USE MD_Mesh_API,    ONLY: MD_Mesh_Domain
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Step_Mgr,    ONLY: MD_Step_Desc
  USE MD_Cont_Aux_Def, ONLY: MD_Cont_Stp_Ctl_Algo

  IMPLICIT NONE
  PRIVATE

  ! CONT_FORM_*, CONT_STATE_* moved to MD_Int_Def
  PUBLIC :: CONT_FORM_SURFACE, CONT_FORM_NODE, CONT_FORM_GENERAL
  PUBLIC :: CONT_STATE_OPEN, CONT_STATE_CLOSED, CONT_STATE_SLIDING

  !============================================================================
  ! ContAlgo: Contact algorithm parameters (Algo category)
  ! Frozen after L6_AP parse; read-only during Solve phase.
  ! Legacy — prefer MD_Cont_Algo (P1 gap fill) which embeds stp_ctl.
  !============================================================================
  TYPE, PUBLIC :: ContAlgo
    REAL(wp)    :: search_radius     = 0.0_wp   !! Contact detection radius
    REAL(wp)    :: penalty_factor    = 1.0E+5_wp !! Augmented Lagrangian penalty k_N
    REAL(wp)    :: lagrange_tol      = 1.0E-8_wp !! Lagrange multiplier convergence tol
    INTEGER(i4) :: max_search_iter   = 10_i4     !! Max contact search iterations
    LOGICAL     :: auto_penalty      = .TRUE.     !! Automatic penalty calculation
    LOGICAL     :: adjust_midplane   = .FALSE.    !! Adjust midplane for shells
  END TYPE ContAlgo

  !============================================================================
  ! MD_Cont_Algo: Unified Contact algorithm aggregate (P1 gap fill)
  ! Composes MD_Cont_Stp_Ctl_Algo (step-level control) + legacy ContAlgo.
  ! [Phase:Stp|Verb:Ctl] aligned with PH_Mat_Algo / PH_Elem_Algo pattern.
  !============================================================================
  TYPE, PUBLIC :: MD_Cont_Algo
    TYPE(MD_Cont_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] step-level control
    TYPE(ContAlgo)             :: legacy     ! legacy fields (use stp_ctl for new code)
  END TYPE MD_Cont_Algo

  !============================================================================
  ! MD_ContactProperty: Unified contact property (replaces MD_ContactProperty_Type)
  ! Wraps friction/cohesion/damping; Desc category; frozen after parse.
  !============================================================================
  TYPE, PUBLIC :: MD_ContactProperty
    CHARACTER(LEN=64)            :: name     = ""
    TYPE(MD_Friction_Type)       :: friction
    TYPE(MD_Cohesion_Type)       :: cohesion
    TYPE(MD_ContactDamping_Type) :: damping
    TYPE(MD_ContactProperty_Type):: pressure_overclosure  !! Hard/soft/exponential
    LOGICAL                      :: has_friction  = .FALSE.
    LOGICAL                      :: has_cohesion  = .FALSE.
    LOGICAL                      :: has_damping   = .FALSE.
  END TYPE MD_ContactProperty

  ! MD_ContactPairDef, MD_InteractionUnion moved to MD_Int_Def
  PUBLIC :: MD_ContactPairDef, MD_InteractionUnion

  ! Index-based Get* ( Phase 3)
  TYPE, PUBLIC :: MD_Interaction_GetPair_Arg
    TYPE(MD_ContactPairDef) :: pair_def
  END TYPE MD_Interaction_GetPair_Arg
  TYPE, PUBLIC :: MD_Interaction_GetProperty_Arg
    TYPE(MD_ContactProperty) :: prop
  END TYPE MD_Interaction_GetProperty_Arg
  PUBLIC :: MD_Interaction_GetPair_Arg, MD_Interaction_GetPair_Idx
  PUBLIC :: MD_Interaction_GetProperty_Arg, MD_Interaction_GetProperty_Idx

  !============================================================================
  ! MD_ContactPairState: Per-pair runtime state (State category)
  ! Updated exclusively via MD_Interaction_WriteBack_State / WriteBack_Active.
  ! L5_RT reads via GetPairsForStep (returns Desc+State snapshot).
  !============================================================================
  TYPE, PUBLIC :: MD_ContactPairState
    REAL(wp)    :: gap            = 0.0_wp    !! Normal gap g_N
    REAL(wp)    :: normal_force   = 0.0_wp    !! Contact pressure p_N
    REAL(wp)    :: tangent_force  = 0.0_wp    !! Friction traction ||t_T||
    INTEGER(i4) :: contact_state  = CONT_STATE_OPEN
    LOGICAL     :: isActive       = .FALSE.
    ! [Data chain] three-step indexing L3→L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_ContactPairState

  !============================================================================
  ! ContCtx: Contact transient context (Ctx category)
  ! Not resident in global container; created per-operation.
  !============================================================================
  TYPE, PUBLIC :: ContCtx
    INTEGER(i4) :: current_pair_id   = 0_i4
    INTEGER(i4) :: operation_type    = 0_i4  ! 1=Add, 2=Modify, 3=Delete
    LOGICAL     :: search_pending    = .FALSE.
    INTEGER(i4) :: last_step_idx     = 0_i4
    INTEGER(i4) :: last_incr_idx     = 0_i4   ! [ ]
    CHARACTER(LEN=64) :: last_operation = ""
  END TYPE ContCtx

  !============================================================================
  ! MD_Interaction_Domain: Unified domain container
  ! Container path: g_ufc_global%md_layer%interaction
  !
  ! Lifecycle: Init -> AddProperty + AddPair (parse) -> [frozen] ->
  !            GetPairsForStep (L4/L5 RO) -> WriteBack (L5_RT) -> Finalize.
  !============================================================================
  TYPE, PUBLIC :: MD_Interaction_Domain
    !--- Desc (Write-Once after parse) ---
    TYPE(MD_ContactPairDef),   ALLOCATABLE :: pairs(:)
    TYPE(MD_ContactProperty),  ALLOCATABLE :: props(:)
    INTEGER(i4)                            :: n_pairs = 0_i4
    INTEGER(i4)                            :: n_props = 0_i4
    !--- State (WriteBack whitelist) ---
    TYPE(MD_ContactPairState), ALLOCATABLE :: pair_state(:)
    !--- Algo (Solve-phase read-only) ---
    TYPE(ContAlgo)                         :: algo
    !--- Ctx (transient, not stored) ---
    ! ContCtx created per-operation
    !--- Internal ---
    LOGICAL                                :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init               => MD_Interaction_Domain_Init
    PROCEDURE :: Finalize           => MD_Interaction_Domain_Finalize
    PROCEDURE :: AddPair            => MD_Interaction_Domain_AddPair
    PROCEDURE :: AddProperty        => MD_Interaction_Domain_AddProperty
    PROCEDURE :: GetPairsForStep    => MD_Interaction_Domain_GetPairsForStep
    PROCEDURE :: GetPair            => MD_Interaction_Domain_GetPair
    PROCEDURE :: GetProperty        => MD_Interaction_Domain_GetProperty
    PROCEDURE :: GetPairByName      => MD_Interaction_Domain_GetPairByName
    PROCEDURE :: GetContactSummary  => MD_Interaction_Domain_GetContactSummary
    PROCEDURE :: GetSummary         => MD_Interaction_Domain_GetSummary
    PROCEDURE :: WriteBack_State    => MD_Interaction_WriteBack_State
    PROCEDURE :: WriteBack_Active   => MD_Interaction_WriteBack_Active
    PROCEDURE :: ValidateAllRefs    => MD_Interaction_Domain_ValidateAllRefs
  END TYPE MD_Interaction_Domain

  ! ============================================================
  ! Arg types for Arg-wrapped interfaces (Phase B)
  ! ============================================================
  TYPE, PUBLIC :: MD_Interaction_AddPair_Arg
    TYPE(MD_ContactPairDef)   :: pair_def      ! (IN)
    TYPE(ErrorStatusType)     :: status
  END TYPE MD_Interaction_AddPair_Arg

  TYPE, PUBLIC :: MD_Interaction_AddProperty_Arg
    TYPE(MD_ContactProperty)  :: prop          ! (IN)
    TYPE(ErrorStatusType)     :: status
  END TYPE MD_Interaction_AddProperty_Arg

  TYPE, PUBLIC :: MD_Interaction_GetSummary_Arg
    CHARACTER(LEN=512)        :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType)     :: status
  END TYPE MD_Interaction_GetSummary_Arg

  ! Arg for GetPairByName (Phase B: >4 params -> Arg)
  TYPE, PUBLIC :: MD_Interaction_GetPairByName_Arg
    INTEGER(i4) :: pair_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_Interaction_GetPairByName_Arg

  PUBLIC :: MD_Interaction_Domain, MD_ContactPairDef, MD_ContactPairState, &
            MD_ContactProperty, MD_InteractionUnion, ContAlgo, ContCtx, &
            MD_Interaction_AddPair_Arg, MD_Interaction_AddProperty_Arg, &
            MD_Interaction_GetSummary_Arg, MD_Interaction_GetPairByName_Arg, &
            MD_Interaction_GetPairByName_Idx

CONTAINS

  !============================================================================
  ! MD_Interaction_Domain_AddPair
  ! Register one contact pair during L6_AP parse phase.
  ! Simultaneously allocates the matching pair_state entry.
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_AddPair(this, pair_def, status)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    TYPE(MD_ContactPairDef),      INTENT(IN)    :: pair_def
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    this%n_pairs                       = this%n_pairs + 1_i4
    this%pairs(this%n_pairs)           = pair_def
    this%pairs(this%n_pairs)%pair_id   = this%n_pairs
    this%pair_state(this%n_pairs)%isActive = pair_def%active_in_all_steps

  END SUBROUTINE MD_Interaction_Domain_AddPair

  !============================================================================
  ! MD_Interaction_Domain_AddProperty
  ! Register one contact property during L6_AP parse phase.
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_AddProperty(this, prop, status)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    TYPE(MD_ContactProperty),     INTENT(IN)    :: prop
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    this%n_props           = this%n_props + 1_i4
    this%props(this%n_props) = prop

  END SUBROUTINE MD_Interaction_Domain_AddProperty

  !============================================================================
  ! MD_Interaction_Domain_Finalize
  ! Deallocate all arrays; called in reverse init order (L5->L4->L3).
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_Finalize(this)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this

    IF (ALLOCATED(this%pairs))      DEALLOCATE(this%pairs)
    IF (ALLOCATED(this%props))      DEALLOCATE(this%props)
    IF (ALLOCATED(this%pair_state)) DEALLOCATE(this%pair_state)
    this%n_pairs     = 0_i4
    this%n_props     = 0_i4
    this%initialized = .FALSE.

  END SUBROUTINE MD_Interaction_Domain_Finalize

  !============================================================================
  ! MD_Interaction_Domain_GetPairsForStep
  ! Returns count and index list of active pairs in the specified step.
  ! Design: INTERACTION_DOMAIN_DESIGN.md Phase D, step%pair_ids
  ! Called by L4_PH (step boundary) and L5_RT (per iteration, read-only).
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_GetPairsForStep(this, step_idx, &
                                                    pair_indices, n_active, status)
    CLASS(MD_Interaction_Domain), INTENT(IN)  :: this
    INTEGER(i4),                  INTENT(IN)  :: step_idx
    INTEGER(i4),                  INTENT(OUT) :: pair_indices(:)
    INTEGER(i4),                  INTENT(OUT) :: n_active
    TYPE(ErrorStatusType),        INTENT(OUT) :: status

    INTEGER(i4) :: i, j, np
    TYPE(MD_Step_Desc) :: step_desc

    CALL init_error_status(status)
    n_active = 0_i4

    IF (.NOT. this%initialized .OR. this%n_pairs < 1_i4) RETURN

    !--- Index tree step%pair_ids ---
    IF (g_ufc_global%IsReady()) THEN
      CALL g_ufc_global%md_layer%step%GetStep(step_idx, step_desc, status)
      IF (status%status_code == IF_STATUS_OK .AND. ALLOCATED(step_desc%pair_ids)) THEN
        np = SIZE(step_desc%pair_ids)
        IF (np > 0_i4) THEN
          n_active = MIN(np, SIZE(pair_indices))
          DO j = 1_i4, n_active
            pair_indices(j) = step_desc%pair_ids(j)
          END DO
          RETURN
        END IF
      END IF
    END IF

    !--- active_in_all_steps / pair_state%isActive ---
    DO i = 1_i4, this%n_pairs
      IF (this%pairs(i)%active_in_all_steps .OR. &
          this%pair_state(i)%isActive) THEN
        n_active              = n_active + 1_i4
        pair_indices(n_active) = i
      END IF
    END DO

  END SUBROUTINE MD_Interaction_Domain_GetPairsForStep

  !============================================================================
  ! MD_Interaction_Domain_GetPair
  ! Get contact pair by index (1-based). For Assembly GetContactPair delegation.
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_GetPair(this, idx, pair_def, status)
    CLASS(MD_Interaction_Domain), INTENT(IN)  :: this
    INTEGER(i4),                 INTENT(IN)  :: idx
    TYPE(MD_ContactPairDef),     INTENT(OUT) :: pair_def
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_pairs) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    pair_def = this%pairs(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Interaction_Domain_GetPair

  !============================================================================
  ! MD_Interaction_Domain_GetProperty
  ! Read-only lookup of contact property by name.  O(n_props).
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_GetProperty(this, name, prop, found, status)
    CLASS(MD_Interaction_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),             INTENT(IN)  :: name
    TYPE(MD_ContactProperty),     INTENT(OUT) :: prop
    LOGICAL,                      INTENT(OUT) :: found
    TYPE(ErrorStatusType),        INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    found = .FALSE.

    DO i = 1_i4, this%n_props
      IF (TRIM(this%props(i)%name) == TRIM(name)) THEN
        prop  = this%props(i)
        found = .TRUE.
        RETURN
      END IF
    END DO

  END SUBROUTINE MD_Interaction_Domain_GetProperty

  !============================================================================
  ! MD_Interaction_GetPair_Idx - Standalone index-based API ( Phase 3)
  !============================================================================
  SUBROUTINE MD_Interaction_GetPair_Idx(pair_idx, arg, status)
    INTEGER(i4),                        INTENT(IN)    :: pair_idx
    TYPE(MD_Interaction_GetPair_Arg),   INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),              INTENT(OUT)   :: status
    ASSOCIATE(dom => g_ufc_global%md_layer%interaction)
      CALL dom%GetPair(pair_idx, arg%pair_def, status)
    END ASSOCIATE
  END SUBROUTINE MD_Interaction_GetPair_Idx

  !============================================================================
  ! MD_Interaction_GetProperty_Idx - Standalone index-based API ( Phase 3)
  !============================================================================
  SUBROUTINE MD_Interaction_GetProperty_Idx(prop_idx, arg, status)
    INTEGER(i4),                           INTENT(IN)    :: prop_idx
    TYPE(MD_Interaction_GetProperty_Arg),  INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),                 INTENT(OUT)   :: status

    CALL init_error_status(status)
    ASSOCIATE(dom => g_ufc_global%md_layer%interaction)
      IF (.NOT. dom%initialized .OR. prop_idx < 1 .OR. prop_idx > dom%n_props) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      arg%prop = dom%props(prop_idx)
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Interaction_GetProperty_Idx

  !============================================================================
  ! MD_Interaction_Domain_Init
  ! Allocate pairs, props, and pair_state arrays.
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_Init(this, max_pairs, max_props, status)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                  INTENT(IN)    :: max_pairs
    INTEGER(i4),                  INTENT(IN)    :: max_props
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (max_pairs < 1_i4 .OR. max_props < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ALLOCATE(this%pairs(max_pairs))
    ALLOCATE(this%props(max_props))
    ALLOCATE(this%pair_state(max_pairs))
    this%n_pairs     = 0_i4
    this%n_props     = 0_i4
    this%initialized = .TRUE.

  END SUBROUTINE MD_Interaction_Domain_Init

  !============================================================================
  ! MD_Interaction_WriteBack_Active
  ! Update isActive flag for a contact pair (e.g., deactivation at step boundary).
  ! ONLY legal L5_RT WriteBack path for isActive.
  !============================================================================
  SUBROUTINE MD_Interaction_WriteBack_Active(this, pair_idx, isActive, status)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                  INTENT(IN)    :: pair_idx
    LOGICAL,                      INTENT(IN)    :: isActive
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (pair_idx < 1_i4 .OR. pair_idx > this%n_pairs) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    this%pair_state(pair_idx)%isActive = isActive

  END SUBROUTINE MD_Interaction_WriteBack_Active

  !============================================================================
  ! MD_Interaction_WriteBack_State
  ! Update gap / normal_force / tangent_force / contact_state per increment.
  ! ONLY legal L5_RT WriteBack path for runtime contact state.
  ! Prohibited: master_surface, slave_surface, prop_name, friction, algo fields.
  !============================================================================
  SUBROUTINE MD_Interaction_WriteBack_State(this, pair_idx, gap, &
                                             normal_force, tangent_force, &
                                             contact_state, status, step_idx, incr_idx)
    CLASS(MD_Interaction_Domain), INTENT(INOUT) :: this
    INTEGER(i4),                  INTENT(IN)    :: pair_idx
    REAL(wp),                     INTENT(IN)    :: gap
    REAL(wp),                     INTENT(IN)    :: normal_force
    REAL(wp),                     INTENT(IN)    :: tangent_force
    INTEGER(i4),                  INTENT(IN)    :: contact_state
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status
    INTEGER(i4),                  INTENT(IN), OPTIONAL :: step_idx, incr_idx

    CALL init_error_status(status)
    IF (pair_idx < 1_i4 .OR. pair_idx > this%n_pairs) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    this%pair_state(pair_idx)%gap           = gap
    this%pair_state(pair_idx)%normal_force  = normal_force
    this%pair_state(pair_idx)%tangent_force = tangent_force
    this%pair_state(pair_idx)%contact_state = contact_state
    IF (PRESENT(step_idx)) this%pair_state(pair_idx)%inc%step_idx = step_idx
    IF (PRESENT(incr_idx)) this%pair_state(pair_idx)%inc%incr_idx = incr_idx

  END SUBROUTINE MD_Interaction_WriteBack_State

  !============================================================================
  ! MD_Interaction_Domain_ValidateAllRefs
  ! Validate all cross-domain references in Interaction domain.
  ! This is called by MD_L3_ValidateBindings to ensure surface names exist.
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_ValidateAllRefs(this, mesh_domain, valid, status)
    CLASS(MD_Interaction_Domain), INTENT(IN)  :: this
    TYPE(MD_Mesh_Domain),         INTENT(IN)  :: mesh_domain
    LOGICAL,                      INTENT(OUT) :: valid
    TYPE(ErrorStatusType),        INTENT(OUT) :: status

    INTEGER(i4) :: i, j
    LOGICAL     :: found

    CALL init_error_status(status)
    valid = .TRUE.

    IF (.NOT. this%initialized) THEN
      valid = .FALSE.
      status%status_code = IF_STATUS_INVALID
      status%message = "Interaction domain not initialized"
      RETURN
    END IF

    ! Validate all contact pair surface references
    DO i = 1, this%n_pairs
      ! Check master surface exists in mesh
      CALL mesh_domain%GetSurfaceByName(this%pairs(i)%master_surface, found, status)
      IF (.NOT. found) THEN
        valid = .FALSE.
        WRITE(status%message, '(A,I0,A,A)') "Contact pair[", i, &
              "] master surface '", TRIM(this%pairs(i)%master_surface), &
              "' does not exist in mesh domain"
        RETURN
      END IF

      ! Check slave surface exists in mesh
      CALL mesh_domain%GetSurfaceByName(this%pairs(i)%slave_surface, found, status)
      IF (.NOT. found) THEN
        valid = .FALSE.
        WRITE(status%message, '(A,I0,A,A)') "Contact pair[", i, &
              "] slave surface '", TRIM(this%pairs(i)%slave_surface), &
              "' does not exist in mesh domain"
        RETURN
      END IF

      ! Check property reference exists
      found = .FALSE.
      DO j = 1, this%n_props
        IF (TRIM(this%props(j)%name) == TRIM(this%pairs(i)%prop_name)) THEN
          found = .TRUE.
          EXIT
        END IF
      END DO
      
      IF (.NOT. found) THEN
        valid = .FALSE.
        WRITE(status%message, '(A,I0,A,A)') "Contact pair[", i, &
              "] property '", TRIM(this%pairs(i)%prop_name), &
              "' does not exist"
        RETURN
      END IF
    END DO
    
    IF (valid) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "One or more contact references are invalid"
    END IF
  END SUBROUTINE MD_Interaction_Domain_ValidateAllRefs

  !============================================================================
  ! MD_Interaction_Domain_GetPairByName
  ! Get contact pair index by name (linear search)
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_GetPairByName(this, name, pair_idx, found, status)
    CLASS(MD_Interaction_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),             INTENT(IN)  :: name
    INTEGER(i4),                  INTENT(OUT) :: pair_idx
    LOGICAL,                      INTENT(OUT) :: found
    TYPE(ErrorStatusType),        INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    pair_idx = 0_i4
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Interaction domain not initialized"
      RETURN
    END IF

    DO i = 1, this%n_pairs
      IF (TRIM(this%pairs(i)%master_surface) == TRIM(name) .OR. &
          TRIM(this%pairs(i)%slave_surface) == TRIM(name)) THEN
        pair_idx = i
        found = .TRUE.
        EXIT
      END IF
    END DO

    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "Contact pair '", TRIM(name), "' not found"
    END IF

  END SUBROUTINE MD_Interaction_Domain_GetPairByName

  !============================================================================
  ! MD_Interaction_GetPairByName_Idx - Index-style API (Phase B)
  !   Lookup by master_surface or slave_surface name
  !============================================================================
  SUBROUTINE MD_Interaction_GetPairByName_Idx(name, arg, status)
    CHARACTER(LEN=*), INTENT(IN)    :: name
    TYPE(MD_Interaction_GetPairByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%pair_idx = 0_i4
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%interaction)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Interaction domain not initialized"
        RETURN
      END IF
      DO i = 1, dom%n_pairs
        IF (TRIM(dom%pairs(i)%master_surface) == TRIM(name) .OR. &
            TRIM(dom%pairs(i)%slave_surface) == TRIM(name)) THEN
          arg%found = .TRUE.
          arg%pair_idx = i
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    WRITE(status%message, '(A,A,A)') "Contact pair '", TRIM(name), "' not found"
  END SUBROUTINE MD_Interaction_GetPairByName_Idx

  !============================================================================
  ! MD_Interaction_Domain_GetContactSummary
  ! Get summary string of all contact pairs and properties
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_GetContactSummary(this, summary, status)
    CLASS(MD_Interaction_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),           INTENT(OUT) :: summary
    TYPE(ErrorStatusType),        INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Interaction domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,I0)') &
      "Contact Summary: Total=", this%n_pairs, &
      " (Active=", this%n_pairs, &
      ", Properties=", this%n_props, &
      "), Algo: penalty=", this%algo%penalty_factor, &
      ", tol=", this%algo%lagrange_tol

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Interaction_Domain_GetContactSummary

  !============================================================================
  ! MD_Interaction_Domain_GetSummary  [Phase B Arg wrapper]
  ! Delegates to GetContactSummary_Impl (the existing scatter-param impl).
  !============================================================================
  SUBROUTINE MD_Interaction_Domain_GetSummary(this, arg)
    CLASS(MD_Interaction_Domain),        INTENT(IN)    :: this
    TYPE(MD_Interaction_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL MD_Interaction_Domain_GetContactSummary(this, arg%summary, arg%status)
  END SUBROUTINE MD_Interaction_Domain_GetSummary

END MODULE MD_Cont_Mgr