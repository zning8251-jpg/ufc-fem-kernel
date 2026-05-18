!===============================================================================
! Module: UFC_Populate_Template                                       [v1.1]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Common — Populate Phase: Pointer Association & Initialization
!
! Purpose:
!   Reference implementation template for the UFC "Populate Phase" — the three
!   mandatory tasks that MUST be completed before any physics algorithm call:
!
!   Task 1: Read INP → fill L3_MD Desc types (immutable model configuration)
!   Task 2: ALLOCATE arrays for L4_PH State + L5_RT Domain Ctx
!   Task 3: Establish pointer associations (three-tier Ctx chain, zero-copy)
!
! Three-Tier Ctx Architecture (pointer chain):
!
!   RT_XXX_Domain_Ctx             (Level 3: domain-specific aggregator)
!     └─ com_ctx  POINTER ──►  RT_Com_Base_Ctx   (Level 2: LFLAGS / elem_id)
!                                 └─ global_ctx POINTER ──►  RT_Global_Ctx
!                                                             (Level 1: SINGLETON
!                                                              time / step / kinc)
!
! Hot-path access (zero-copy O(1)):
!   time_now = mat_rt_ctx%com_ctx%global_ctx%time_current
!
! Key design rules:
!   - RT_Global_Ctx: ONE instance per analysis (TARGET :: global_ctx)
!   - RT_Com_Base_Ctx: ONE instance per call domain (or per thread)
!   - ALLOCATE occurs in Populate phase only, NEVER inside increment loop
!   - DEALLOCATE closes the loop at Step end / Model unload
!   - Pointer ownership: caller allocates TARGET; receiver stores POINTER
!
! Structured status baseline:
!   Concrete IF_Err_Brg bridges initialize status via init_error_status(...)
!   and treat status%status_code as the bridge-facing status field.
!
! Changelog:
!   v1.1 (2026-05)  UFC_Populate_All: success path uses init_error_status(status, IF_STATUS_OK)
!                   instead of legacy status%code assignment.
! Note:
!   This comment refresh aligns header/example wording to the
!   IF_Err_Brg + structured status baseline.
!
! Step 2 (Populate) preconditions:
!   - Step 1 (TYPE definitions) must be 100% complete before this template
!   - All Desc/State/Algo/Ctx TYPEs defined in templates/* must be stable
!
! Four-chain coverage:
!   Theory chain  : Data layout supports variational formulation (see PLAN docs)
!   Logic chain   : Subroutine call-order contract enforced by task sequence
!   Compute chain : Algorithm injection in Step 3 (PH_XXX subroutines)
!   Data chain    : Pointer map + lifecycle enforced in this template
!
!===============================================================================
MODULE UFC_Populate_Template
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Global_Types,  ONLY: RT_Global_Ctx
  USE RT_Com_Types,     ONLY: RT_Com_Base_Ctx
  USE RT_Domain_Types,  ONLY: RT_Mat_Domain_Ctx,     RT_Elem_Domain_Ctx,   &
                               RT_Load_Domain_Ctx,    RT_BC_Domain_Ctx,     &
                               RT_Contact_Domain_Ctx, RT_Fric_Domain_Ctx,  &
                               RT_Constr_Domain_Ctx,  RT_Field_Domain_Ctx,  &
                               RT_Analy_Domain_Ctx,                         &
                               RT_Special_Domain_Ctx, RT_Fluid_Domain_Ctx,  &
                               RT_Misc_Domain_Ctx,    RT_CFD_Domain_Ctx
  USE PH_Mat_Types,     ONLY: PH_Mat_Base_State
  USE PH_Elem_Types,    ONLY: PH_Elem_Base_State
  IMPLICIT NONE
  PRIVATE

  !-- Public entry points
  PUBLIC :: UFC_Populate_All
  PUBLIC :: UFC_Populate_Init_Global
  PUBLIC :: UFC_Populate_Domain_Mat
  PUBLIC :: UFC_Populate_Domain_Elem
  PUBLIC :: UFC_Populate_Domain_Load
  PUBLIC :: UFC_Populate_Domain_BC
  PUBLIC :: UFC_Populate_Domain_Contact
  PUBLIC :: UFC_Populate_Domain_Fric
  PUBLIC :: UFC_Populate_Domain_Constr
  PUBLIC :: UFC_Populate_Domain_Field
  PUBLIC :: UFC_Populate_Domain_Analy
  PUBLIC :: UFC_Populate_Domain_Special
  PUBLIC :: UFC_Populate_Domain_Fluid
  PUBLIC :: UFC_Populate_Domain_Misc
  PUBLIC :: UFC_Populate_Domain_CFD
  PUBLIC :: UFC_Populate_Teardown

CONTAINS

  !============================================================================
  ! UFC_Populate_All — Master orchestrator for the Populate Phase
  !
  !   Calls the three mandatory tasks in strict order:
  !     1) Global singleton initialisation
  !     2) Domain-level ALLOCATE + State array sizing
  !     3) Pointer association (the most critical step)
  !
  !   MUST be called once before the first increment loop.
  !   After this call, all pointer chains are live and hot-path access works.
  !============================================================================
  SUBROUTINE UFC_Populate_All( &
      global_ctx,    &   ! INOUT  Level 1 singleton (caller owns TARGET)
      com_ctx,       &   ! INOUT  Level 2 common context
      mat_rt_ctx,    &   ! INOUT  Material domain runtime context
      elem_rt_ctx,   &   ! INOUT  Element domain runtime context
      load_rt_ctx,   &   ! INOUT  Load domain runtime context
      bc_rt_ctx,     &   ! INOUT  BC domain runtime context
      n_mats,        &   ! IN     number of material instances
      n_elems,       &   ! IN     number of element instances
      status         )   ! OUT    structured status for bridge callers

    TYPE(RT_Global_Ctx),       INTENT(INOUT), TARGET  :: global_ctx
    TYPE(RT_Com_Base_Ctx),     INTENT(INOUT), TARGET  :: com_ctx
    TYPE(RT_Mat_Domain_Ctx),   INTENT(INOUT)          :: mat_rt_ctx
    TYPE(RT_Elem_Domain_Ctx),  INTENT(INOUT)          :: elem_rt_ctx
    TYPE(RT_Load_Domain_Ctx),  INTENT(INOUT)          :: load_rt_ctx
    TYPE(RT_BC_Domain_Ctx),    INTENT(INOUT)          :: bc_rt_ctx
    INTEGER(i4),               INTENT(IN)             :: n_mats
    INTEGER(i4),               INTENT(IN)             :: n_elems
    TYPE(ErrorStatusType),     INTENT(OUT)            :: status

    !-- Task 1: Initialise global context (time = 0, kstep = 1)
    CALL UFC_Populate_Init_Global(global_ctx)

    !-- Task 2: Pointer association — com_ctx → global_ctx (Level 2 → Level 1)
    com_ctx%global_ctx => global_ctx

    !-- Task 3: Domain-level pointer associations + optional ALLOCATE
    CALL UFC_Populate_Domain_Mat(mat_rt_ctx, com_ctx)
    CALL UFC_Populate_Domain_Elem(elem_rt_ctx, com_ctx)
    CALL UFC_Populate_Domain_Load(load_rt_ctx, com_ctx)
    CALL UFC_Populate_Domain_BC(bc_rt_ctx, com_ctx)

    !-- Structured status success for bridge callers
    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE UFC_Populate_All

  !============================================================================
  ! Task 1: Initialise the global context singleton
  !   Sets time_current=0, dtime=0, kstep=1, kinc=0, iter=0
  !   Also zeroes convergence flags and sets default Newmark parameters.
  !============================================================================
  SUBROUTINE UFC_Populate_Init_Global(global_ctx)
    TYPE(RT_Global_Ctx), INTENT(INOUT) :: global_ctx

    global_ctx%time_current   = 0.0_wp
    global_ctx%time_total     = 0.0_wp
    global_ctx%dtime          = 0.0_wp
    global_ctx%kstep          = 1_i4
    global_ctx%kinc           = 0_i4
    global_ctx%iter           = 0_i4
    global_ctx%is_converged   = .FALSE.
    global_ctx%residual_norm  = 0.0_wp
    !-- Default Newmark-β: β=0.25, γ=0.50, α=0.0 (average acceleration)
    global_ctx%newmark_params = [0.25_wp, 0.50_wp, 0.0_wp]

  END SUBROUTINE UFC_Populate_Init_Global

  !============================================================================
  ! Domain init templates — Level 3 Ctx → Level 2 com_ctx pointer association
  !
  ! Pattern (identical for all domains):
  !   domain_ctx%com_ctx => com_ctx        ! non-owning pointer
  !   [optional] domain_ctx%ph_state => allocated_state_array(i)
  !
  ! HOT-PATH ACCESS after association:
  !   time_now = domain_ctx%com_ctx%global_ctx%time_current  ← O(1), zero-copy
  !============================================================================

  SUBROUTINE UFC_Populate_Domain_Mat(mat_ctx, com_ctx)
    TYPE(RT_Mat_Domain_Ctx),  INTENT(INOUT)        :: mat_ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN),   TARGET :: com_ctx
    !-- Level 3 → Level 2 pointer association
    mat_ctx%com_ctx => com_ctx
    !-- ph_state pointer: caller must set mat_ctx%ph_state => mat_state_array(i)
    !   after ALLOCATE(mat_state_array(n_mats)) in the caller
    !-- pnewdt reset for new increment
    mat_ctx%pnewdt = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Mat

  SUBROUTINE UFC_Populate_Domain_Elem(elem_ctx, com_ctx)
    TYPE(RT_Elem_Domain_Ctx), INTENT(INOUT)        :: elem_ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN),   TARGET :: com_ctx
    elem_ctx%com_ctx => com_ctx
    elem_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Elem

  SUBROUTINE UFC_Populate_Domain_Load(load_ctx, com_ctx)
    TYPE(RT_Load_Domain_Ctx), INTENT(INOUT)        :: load_ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN),   TARGET :: com_ctx
    load_ctx%com_ctx => com_ctx
    load_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Load

  SUBROUTINE UFC_Populate_Domain_BC(bc_ctx, com_ctx)
    TYPE(RT_BC_Domain_Ctx),   INTENT(INOUT)        :: bc_ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN),   TARGET :: com_ctx
    bc_ctx%com_ctx => com_ctx
    bc_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_BC

  SUBROUTINE UFC_Populate_Domain_Contact(cont_ctx, com_ctx)
    TYPE(RT_Contact_Domain_Ctx), INTENT(INOUT)        :: cont_ctx
    TYPE(RT_Com_Base_Ctx),       INTENT(IN),   TARGET :: com_ctx
    cont_ctx%com_ctx => com_ctx
    cont_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Contact

  SUBROUTINE UFC_Populate_Domain_Fric(fric_ctx, com_ctx)
    TYPE(RT_Fric_Domain_Ctx), INTENT(INOUT)        :: fric_ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN),   TARGET :: com_ctx
    fric_ctx%com_ctx => com_ctx
    fric_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Fric

  SUBROUTINE UFC_Populate_Domain_Constr(constr_ctx, com_ctx)
    TYPE(RT_Constr_Domain_Ctx), INTENT(INOUT)        :: constr_ctx
    TYPE(RT_Com_Base_Ctx),      INTENT(IN),   TARGET :: com_ctx
    constr_ctx%com_ctx => com_ctx
    constr_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Constr

  SUBROUTINE UFC_Populate_Domain_Field(field_ctx, com_ctx)
    TYPE(RT_Field_Domain_Ctx), INTENT(INOUT)        :: field_ctx
    TYPE(RT_Com_Base_Ctx),     INTENT(IN),   TARGET :: com_ctx
    field_ctx%com_ctx => com_ctx
    field_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Field

  SUBROUTINE UFC_Populate_Domain_Analy(analy_ctx, com_ctx)
    TYPE(RT_Analy_Domain_Ctx), INTENT(INOUT)        :: analy_ctx
    TYPE(RT_Com_Base_Ctx),     INTENT(IN),   TARGET :: com_ctx
    analy_ctx%com_ctx => com_ctx
  END SUBROUTINE UFC_Populate_Domain_Analy

  !-- New domains (Special / Fluid / Misc / CFD)
  SUBROUTINE UFC_Populate_Domain_Special(spec_ctx, com_ctx)
    TYPE(RT_Special_Domain_Ctx), INTENT(INOUT)        :: spec_ctx
    TYPE(RT_Com_Base_Ctx),       INTENT(IN),   TARGET :: com_ctx
    spec_ctx%com_ctx => com_ctx
    spec_ctx%pnewdt  = 1.0_wp
    !-- State pointers: caller sets spec_ctx%dflow_state => dflow_state_var etc.
  END SUBROUTINE UFC_Populate_Domain_Special

  SUBROUTINE UFC_Populate_Domain_Fluid(fluid_ctx, com_ctx)
    TYPE(RT_Fluid_Domain_Ctx), INTENT(INOUT)        :: fluid_ctx
    TYPE(RT_Com_Base_Ctx),     INTENT(IN),   TARGET :: com_ctx
    fluid_ctx%com_ctx => com_ctx
    fluid_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Fluid

  SUBROUTINE UFC_Populate_Domain_Misc(misc_ctx, com_ctx)
    TYPE(RT_Misc_Domain_Ctx), INTENT(INOUT)        :: misc_ctx
    TYPE(RT_Com_Base_Ctx),    INTENT(IN),   TARGET :: com_ctx
    misc_ctx%com_ctx => com_ctx
    misc_ctx%pnewdt  = 1.0_wp
  END SUBROUTINE UFC_Populate_Domain_Misc

  SUBROUTINE UFC_Populate_Domain_CFD(cfd_ctx, com_ctx)
    TYPE(RT_CFD_Domain_Ctx), INTENT(INOUT)        :: cfd_ctx
    TYPE(RT_Com_Base_Ctx),   INTENT(IN),   TARGET :: com_ctx
    cfd_ctx%com_ctx => com_ctx
    cfd_ctx%cfd_iter     = 0_i4
    cfd_ctx%cfd_residual = 0.0_wp
    cfd_ctx%cfd_converged = .FALSE.
  END SUBROUTINE UFC_Populate_Domain_CFD

  !============================================================================
  ! UFC_Populate_Teardown — Nullify all domain pointers (lifecycle close)
  !
  !   Called at Step end / Model unload.
  !   Does NOT DEALLOCATE TARGET objects — caller owns those.
  !   Prevents dangling-pointer access after the analysis step completes.
  !============================================================================
  SUBROUTINE UFC_Populate_Teardown( &
      com_ctx,     &
      mat_rt_ctx,  &
      elem_rt_ctx, &
      load_rt_ctx, &
      bc_rt_ctx    )

    TYPE(RT_Com_Base_Ctx),    INTENT(INOUT) :: com_ctx
    TYPE(RT_Mat_Domain_Ctx),  INTENT(INOUT) :: mat_rt_ctx
    TYPE(RT_Elem_Domain_Ctx), INTENT(INOUT) :: elem_rt_ctx
    TYPE(RT_Load_Domain_Ctx), INTENT(INOUT) :: load_rt_ctx
    TYPE(RT_BC_Domain_Ctx),   INTENT(INOUT) :: bc_rt_ctx

    !-- Nullify Level 2 → Level 1 chain
    NULLIFY(com_ctx%global_ctx)

    !-- Nullify Level 3 → Level 2 chains
    NULLIFY(mat_rt_ctx%com_ctx)
    NULLIFY(mat_rt_ctx%ph_state)
    NULLIFY(elem_rt_ctx%com_ctx)
    NULLIFY(elem_rt_ctx%ph_state)
    NULLIFY(load_rt_ctx%com_ctx)
    NULLIFY(bc_rt_ctx%com_ctx)

  END SUBROUTINE UFC_Populate_Teardown

END MODULE UFC_Populate_Template


!===============================================================================
! UFC_Populate_Usage_Example — Inline usage demonstration (NOT compiled module)
!
! Shows how to wire the three-tier Ctx chain in a typical analysis driver.
! Copy-paste into your RT_StepDriver or equivalent L5_RT driver module.
!===============================================================================
!
! PROGRAM UFC_Driver_Example
!   USE UFC_Populate_Template
!   USE RT_Global_Types,  ONLY: RT_Global_Ctx
!   USE RT_Com_Types,     ONLY: RT_Com_Base_Ctx
!   USE RT_Domain_Types,  ONLY: RT_Mat_Domain_Ctx, RT_Elem_Domain_Ctx
!   USE PH_Mat_Types,     ONLY: PH_Mat_Base_State
!   USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
!
!   !-- Singleton: ONE global_ctx per analysis (TARGET so pointers can bind)
!   TYPE(RT_Global_Ctx),     TARGET  :: global_ctx
!
!   !-- Per-call common context (TARGET; all domains share one or one per thread)
!   TYPE(RT_Com_Base_Ctx),   TARGET  :: com_ctx
!
!   !-- Domain runtime contexts
!   TYPE(RT_Mat_Domain_Ctx)          :: mat_rt_ctx
!   TYPE(RT_Elem_Domain_Ctx)         :: elem_rt_ctx
!
!   !-- Per-material-point state arrays (POINTER TARGET)
!   TYPE(PH_Mat_Base_State), POINTER, TARGET :: mat_states(:)
!
!   TYPE(ErrorStatusType) :: status   ! structured status from IF_Err_Brg
!   INTEGER :: n_mats, n_elems, i
!
!   n_mats  = 100   ! from INP reader
!   n_elems = 200
!
!   !=========================================================================
!   ! POPULATE PHASE (once, before increment loop)
!   !=========================================================================
!
!   ! Task 1 + 3 combined via master orchestrator
!   ! Caller/bridge convention: initialize status before the Populate call.
!   CALL init_error_status(status, IF_STATUS_OK)
!   CALL UFC_Populate_All(global_ctx, com_ctx, mat_rt_ctx, elem_rt_ctx, &
!                         ??? , ???, n_mats, n_elems, status)
!   IF (status%status_code /= IF_STATUS_OK) STOP 'Populate failed'
!
!   ! Task 2: ALLOCATE state arrays
!   ALLOCATE(mat_states(n_mats))
!
!   ! Task 3 supplement: bind per-material-point state pointer
!   !   (done in the bridge, not here — shown for clarity)
!   !   mat_rt_ctx%ph_state => mat_states(mat_id)
!
!   !=========================================================================
!   ! INCREMENT LOOP
!   !=========================================================================
!   DO kstep = 1, n_steps
!     CALL global_ctx%Reset(kstep)
!     DO kinc = 1, max_incs
!       CALL global_ctx%Update(dtime)
!
!       !-- L5_RT bridge populates com_ctx fields before each material call
!       com_ctx%lflags  = lflags_from_solver
!       com_ctx%jelem   = current_elem_id
!       com_ctx%npt     = current_gauss_pt
!       ! time is accessed via pointer — zero copy:
!       ! time_now = mat_rt_ctx%com_ctx%global_ctx%time_current
!
!       DO i = 1, n_mats
!         mat_rt_ctx%ph_state => mat_states(i)   ! bind per-point state
!         CALL PH_Mat_Elas_Eval(...)   ! Step 3: algorithm call (示意；以族内核为准)
!       END DO
!
!     END DO
!   END DO
!
!   !=========================================================================
!   ! TEARDOWN (lifecycle close)
!   !=========================================================================
!   CALL UFC_Populate_Teardown(com_ctx, mat_rt_ctx, elem_rt_ctx, ??? , ???)
!   DEALLOCATE(mat_states)
!
! END PROGRAM UFC_Driver_Example
