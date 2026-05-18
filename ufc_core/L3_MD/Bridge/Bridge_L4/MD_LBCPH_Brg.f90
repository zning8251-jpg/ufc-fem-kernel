!===============================================================================
! MODULE: MD_LBCPH_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L4
! ROLE:   Brg — LoadBC L3→L4 bridge
! BRIEF:  Bridge L3_MD boundary/load descriptions to L4_PH caches.
!===============================================================================
!   - BuildStepBCs / BuildStepLoads: MD_LoadBC_Ctrl -> PH_BC_Cache_Type /
!     PH_Load_LoadCache_Type
!   - *_FromDomain / *_Idx: MD_L3_LayerContainer%loadbc or g_ufc_global paths
!   - LoadBC_FromDesc / BC_FromDesc / Load_FromDesc: L6 UF_* -> MD_LoadBC
!
! Logic chain:
!   MD_LoadBC_GetBCsForStep / GetLoadsForStep -> this bridge ->
!   PH_BC_Cache_Type(:) / PH_Load_LoadCache_Type(:) -> PH_BC/PH_Load_Algo ->
!   RT_Ldbc_* -> RT_Asm_Ldbc_Apply.
!
! Data chain (field mapping):
!   MD_BC_Desc -> PH_BC_Cache_Type:
!     node_id -> nodeId; dof -> dof; value -> value;
!     current_time -> current_time (from step/runner);
!     amp_ref>0 + md_layer%amplitude -> EvalAtTime -> amp_factor, else 1.
!   MD_Load_Desc -> PH_Load_LoadCache_Type:
!     load_id -> loadId; load_type -> loadType; target_set -> target;
!     magnitude -> magnitude(1) (remaining components 0 unless extended);
!     current_time -> current_time; amp_ref + amplitude -> amp_factor.
!   String load types in Ctrl path map to MD_LBC_Domain LOAD_* (same codes as PH_Load_LoadCache_Type%loadType).
!   Downstream RT uses MD_LBCRT_Brg for equation IDs (see RT_DofMapUtils).
!   MD_LBC load_type -> PH cache via MD_LoadBC_ToLdbcLoadType (MD_LoadBC_Map); see UFC_LoadBC_Enum_Mapping.md
!
! Status: CORE | Refactored: API merged from MD_LBC_Brg
!===============================================================================


MODULE MD_LBCPH_Brg
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  USE MD_LoadBC_Types
  USE PH_BC_Def
  USE PH_Load_Def
  USE MD_LBC_Mgr, ONLY: g_md_loadbc_domain, MD_LoadBC_Runtime_Domain, MD_LoadBC_Algo, &
                            MD_LoadBC, MD_BC, MD_Load, &
                            MD_LoadBC_ToLdbcLoadType, MD_LOADBC_LDBC_INVALID
  USE MD_LBC_Brg, ONLY: UF_LoadBCManager, UF_BCDef, UF_CLoadDef
  USE MD_LBC_Domain, ONLY: MD_BC_Desc, MD_Load_Desc, &
       LOAD_CLOAD, LOAD_DLOAD, LOAD_DSLOAD, LOAD_BODY_FORCE, LOAD_GRAVITY, &
       LOAD_TEMPERATURE, LOAD_PRESSURE, &
       MD_LBC_GetBCsForStep_Arg, MD_LBC_GetBC_Arg, &
       MD_LBC_GetLoadsForStep_Arg, MD_LBC_GetLoad_Arg
  USE MD_LBC_Idx, ONLY: MD_LoadBC_GetBCsForStep_Idx, MD_LoadBC_GetBC_Idx, &
       MD_LoadBC_GetLoadsForStep_Idx, MD_LoadBC_GetLoad_Idx
  ! New Types aligned with four-category (Desc/State/Algo/Ctx)
  USE MD_BC_Def, ONLY: MD_BC_Base_Desc, MD_BC_Disp_Desc, MD_BC_DISP_Desc
  USE MD_Load_Def, ONLY: MD_Load_Base_Desc, MD_Load_Dist_Desc, MD_Load_DLOAD_Desc
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Amp_UF, ONLY: MD_Amp_Slot_Ctx
  USE MD_Amp_Mgr, ONLY: MD_Amp_GetFactor
  USE MD_Model_Lib_Core, ONLY: UF_Model
  ! Amplitude ? md_layer%amplitude%EvalAtTime(amp_ref, t, val, status)
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! Structured Interface Types (Ctx category)
  !=============================================================================
  !---------------------------------------------------------------------------
  ! TYPE: MD_LoadBC_StepBCsOut_Type
  ! KIND: State
  ! DESC: Step BCs output structure
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_StepBCsOut_Type
    INTEGER(i4) :: nBCs = 0_i4
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: ph_bc_cache(:)        ! PH BC
  END TYPE MD_LoadBC_StepBCsOut_Type

  !---------------------------------------------------------------------------
  ! TYPE: MD_LoadBC_StepLoadsOut_Type
  ! KIND: State
  ! DESC: Step loads output structure
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_StepLoadsOut_Type
    INTEGER(i4) :: nLoads = 0_i4
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE :: ph_load_cache(:)    ! PH Load
  END TYPE MD_LoadBC_StepLoadsOut_Type

  !---------------------------------------------------------------------------
  ! TYPE: MD_LoadBC_BuildStepBCs_Ctx_Type
  ! KIND: Ctx
  ! DESC: Build step BCs context (controller + step context + output cache)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_BuildStepBCs_Ctx_Type
    TYPE(MD_LoadBC_Ctrl_Type) :: md_loadbc_ctrl
    TYPE(MD_LoadBC_StepCtx_Type) :: step_ctx
    INTEGER(i4) :: nBCs = 0_i4
    TYPE(PH_BC_Cache_Type), ALLOCATABLE :: ph_bc_cache(:)
  END TYPE MD_LoadBC_BuildStepBCs_Ctx_Type

  !---------------------------------------------------------------------------
  ! TYPE: MD_LoadBC_BuildStepLoads_Ctx_Type
  ! KIND: Ctx
  ! DESC: Build step loads context (controller + step context + output cache)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_BuildStepLoads_Ctx_Type
    TYPE(MD_LoadBC_Ctrl_Type) :: md_loadbc_ctrl
    TYPE(MD_LoadBC_StepCtx_Type) :: step_ctx
    INTEGER(i4) :: nLoads = 0_i4
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE :: ph_load_cache(:)
  END TYPE MD_LoadBC_BuildStepLoads_Ctx_Type
  
  PUBLIC :: MD_LoadBC_PH_Brg_BuildStepBCs
  PUBLIC :: MD_LoadBC_PH_Brg_BuildStepLoads
  PUBLIC :: MD_LoadBC_PH_Brg_BuildStepBCs_FromDomain
  PUBLIC :: MD_LoadBC_PH_Brg_BuildStepLoads_FromDomain
  PUBLIC :: MD_LoadBC_PH_Brg_BuildStepBCs_Idx
  PUBLIC :: MD_LoadBC_PH_Brg_BuildStepLoads_Idx
  PUBLIC :: LoadBC_FromDesc
  PUBLIC :: BC_FromDesc
  PUBLIC :: Load_FromDesc

CONTAINS

  !> Map MD_LBC load kind (or legacy 1..8) -> canonical MD_LBC_Domain code for PH cache.
  INTEGER(i4) FUNCTION MD_LoadBC_PH_Brg_LoadTypeToLdbc(md_kind)
    INTEGER(i4), INTENT(IN) :: md_kind
    INTEGER(i4) :: lt
    lt = MD_LoadBC_ToLdbcLoadType(md_kind)
    IF (lt == MD_LOADBC_LDBC_INVALID) THEN
      IF (md_kind >= 1_i4 .AND. md_kind <= 8_i4) THEN
        MD_LoadBC_PH_Brg_LoadTypeToLdbc = md_kind
      ELSE
        MD_LoadBC_PH_Brg_LoadTypeToLdbc = LOAD_CLOAD
      END IF
    ELSE
      MD_LoadBC_PH_Brg_LoadTypeToLdbc = lt
    END IF
  END FUNCTION MD_LoadBC_PH_Brg_LoadTypeToLdbc

  !=============================================================================
  ! LoadBC API UF_* ?MD_LoadBC/MD_BC/MD_Load MD_LBC_Brg ? !=============================================================================
  SUBROUTINE LoadBC_FromDesc(desc_loadbc, md_loadbc, status)
    TYPE(UF_LoadBCManager), INTENT(IN), TARGET :: desc_loadbc
    TYPE(MD_LoadBC), INTENT(INOUT) :: md_loadbc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    CALL md_loadbc%Init(desc_loadbc%num_bcs, desc_loadbc%num_cloads, &
                        desc_loadbc%num_dloads, desc_loadbc%num_bforces, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    md_loadbc%desc => desc_loadbc
    DO i = 1, desc_loadbc%num_bcs
      CALL BC_FromDesc(desc_loadbc%bcs(i), md_loadbc%bcs(i), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO
    DO i = 1, desc_loadbc%num_cloads
      CALL Load_FromDesc(desc_loadbc%cloads(i), md_loadbc%loads(i), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO
    md_loadbc%num_bcs = desc_loadbc%num_bcs
    md_loadbc%num_loads = desc_loadbc%num_cloads + desc_loadbc%num_dloads + desc_loadbc%num_bforces
    status%status_code = IF_STATUS_OK
  END SUBROUTINE LoadBC_FromDesc

  SUBROUTINE BC_FromDesc(desc_bc, md_bc, status)
    TYPE(UF_BCDef), INTENT(IN) :: desc_bc
    TYPE(MD_BC), INTENT(INOUT) :: md_bc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL md_bc%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    md_bc%name = TRIM(desc_bc%name)
    md_bc%bc_type = desc_bc%bc_type
    md_bc%region_name = TRIM(desc_bc%region_name)
    md_bc%region_type = desc_bc%region_type
    md_bc%node_id = desc_bc%node_id
    md_bc%dof_first = desc_bc%dof_first
    md_bc%dof_last = desc_bc%dof_last
    md_bc%magnitude = desc_bc%magnitude
    md_bc%amplitude_name = TRIM(desc_bc%amplitude_name)
    md_bc%active = desc_bc%active
    md_bc%op_new = desc_bc%op_new
    status%status_code = IF_STATUS_OK
  END SUBROUTINE BC_FromDesc

  SUBROUTINE Load_FromDesc(desc_cload, md_load, status)
    TYPE(UF_CLoadDef), INTENT(IN) :: desc_cload
    TYPE(MD_Load), INTENT(INOUT) :: md_load
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL md_load%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    md_load%name = TRIM(desc_cload%name)
    md_load%region_name = TRIM(desc_cload%nset_name)
    md_load%load_type = 1
    md_load%dof = desc_cload%dof
    md_load%magnitude = desc_cload%magnitude
    md_load%amplitude_name = TRIM(desc_cload%amplitude_name)
    md_load%active = desc_cload%active
    md_load%op_new = desc_cload%op_new
    md_load%follower = desc_cload%follower
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Load_FromDesc

  !=============================================================================
  ! Bridge: BuildStepBCs / BuildStepLoads (FromDomain / Idx variants)
  !=============================================================================

  !=============================================================================
  !> @brief Build step BCs (structured interface)
  !! @details ?step stepId BC PH BC
  !! Theory: Step BC ?A(t) PH
  !! @param[inout] ctx Build step BCs context (contains controller, step context, output cache)
  !! @note Structured interface - uses MD_LoadBC_BuildStepBCs_Ctx_Type to encapsulate all parameters
  !=============================================================================
  SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs(ctx)
    TYPE(MD_LoadBC_BuildStepBCs_Ctx_Type), INTENT(INOUT) :: ctx
    TYPE(MD_LoadBC_Ctrl_GetBCsForStep_Ctx_Type) :: get_ctx
    INTEGER(i4) :: i
    REAL(wp) :: amp_factor
    ctx%nBCs = 0_i4
    IF (ALLOCATED(ctx%ph_bc_cache)) DEALLOCATE(ctx%ph_bc_cache)
    get_ctx%ctrl = ctx%md_loadbc_ctrl
    get_ctx%stepId = ctx%step_ctx%stepId
    CALL MD_LoadBC_Ctrl_GetBCsForStep_Ctx(get_ctx)
    ctx%nBCs = get_ctx%nActiveBCs
    IF (ctx%nBCs == 0) RETURN
    ALLOCATE(ctx%ph_bc_cache(ctx%nBCs))
    DO i = 1, ctx%nBCs
      ctx%ph_bc_cache(i)%nodeId = i
      ctx%ph_bc_cache(i)%dof = get_ctx%bc_list(i)%dof
      ctx%ph_bc_cache(i)%value = get_ctx%bc_list(i)%magnitude
      ctx%ph_bc_cache(i)%current_time = ctx%step_ctx%current_time
      
      ! Phase A: Use LoadBC domain container to get amplitude factor
      ! Future: Will use MD_Amp_Domain container when implemented
      IF (LEN_TRIM(get_ctx%bc_list(i)%ampName) > 0) THEN
        ! Get amplitude factor using domain container interface
        ! Note: Requires domain%ctx%model to be set - use global domain container
        IF (ASSOCIATED(g_md_loadbc_domain%ctx%model)) THEN
          CALL g_md_loadbc_domain%algo%GetAmplitudeFactor( &
            g_md_loadbc_domain, get_ctx%bc_list(i)%ampName, &
            ctx%step_ctx%current_time, amp_factor)
        ELSE
          amp_factor = 1.0_wp  ! Default factor if model context not available
        END IF
      ELSE
        amp_factor = 1.0_wp
      END IF
      ctx%ph_bc_cache(i)%amp_factor = amp_factor
    END DO
  END SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs
  
  !=============================================================================
  !> @brief Build step loads (structured interface)
  !! @details ?step stepId PH Load
  !! Theory: Step ?A(t) PH
  !! @param[inout] ctx Build step loads context (contains controller, step context, output cache)
  !! @note Structured interface - uses MD_LoadBC_BuildStepLoads_Ctx_Type to encapsulate all parameters
  !=============================================================================
  SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads(ctx)
    TYPE(MD_LoadBC_BuildStepLoads_Ctx_Type), INTENT(INOUT) :: ctx
    TYPE(MD_LoadBC_Ctrl_GetLoadsForStep_Ctx_Type) :: get_ctx
    INTEGER(i4) :: i
    REAL(wp) :: amp_factor
    ctx%nLoads = 0_i4
    IF (ALLOCATED(ctx%ph_load_cache)) DEALLOCATE(ctx%ph_load_cache)
    get_ctx%ctrl = ctx%md_loadbc_ctrl
    get_ctx%stepId = ctx%step_ctx%stepId
    CALL MD_LoadBC_Ctrl_GetLoadsForStep_Ctx(get_ctx)
    ctx%nLoads = get_ctx%nActiveLoads
    IF (ctx%nLoads == 0) RETURN
    ALLOCATE(ctx%ph_load_cache(ctx%nLoads))
    DO i = 1, ctx%nLoads
      ctx%ph_load_cache(i)%loadId = get_ctx%load_list(i)%cfg%id
      SELECT CASE(TRIM(get_ctx%load_list(i)%loadType))
      CASE("CLOAD");     ctx%ph_load_cache(i)%loadType = LOAD_CLOAD
      CASE("DLOAD");     ctx%ph_load_cache(i)%loadType = LOAD_DLOAD
      CASE("BODYFORCE"); ctx%ph_load_cache(i)%loadType = LOAD_BODY_FORCE
      CASE("GRAVITY");   ctx%ph_load_cache(i)%loadType = LOAD_GRAVITY
      CASE("PRESSURE");  ctx%ph_load_cache(i)%loadType = LOAD_DSLOAD
      CASE("THERMAL");   ctx%ph_load_cache(i)%loadType = LOAD_TEMPERATURE
      CASE DEFAULT;      ctx%ph_load_cache(i)%loadType = LOAD_CLOAD
      END SELECT
      ctx%ph_load_cache(i)%target = get_ctx%load_list(i)%target
      ctx%ph_load_cache(i)%magnitude = get_ctx%load_list(i)%magnitude
      ctx%ph_load_cache(i)%current_time = ctx%step_ctx%current_time
      
      ! Phase A: Use LoadBC domain container to get amplitude factor
      ! Future: Will use MD_Amp_Domain container when implemented
      IF (LEN_TRIM(get_ctx%load_list(i)%ampName) > 0) THEN
        ! Get amplitude factor using domain container interface
        ! Note: Requires domain%ctx%model to be set - use global domain container
        IF (ASSOCIATED(g_md_loadbc_domain%ctx%model)) THEN
          CALL g_md_loadbc_domain%algo%GetAmplitudeFactor( &
            g_md_loadbc_domain, get_ctx%load_list(i)%ampName, &
            ctx%step_ctx%current_time, amp_factor)
        ELSE
          amp_factor = 1.0_wp  ! Default factor if model context not available
        END IF
      ELSE
        amp_factor = 1.0_wp
      END IF
      ctx%ph_load_cache(i)%amp_factor = amp_factor
    END DO
  END SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads

  !=============================================================================
  ! Bridge BuildStepBCs / BuildStepLoads Domain
  ! Design: BOUNDARY_DOMAIN_DESIGN.md md_layer%loadbc%GetBCsForStep
  !=============================================================================
  SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs_FromDomain(md_layer, step_idx, current_time, &
                                                       ph_bc_cache, n_bcs, status)
    TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer
    INTEGER(i4),                INTENT(IN)    :: step_idx
    REAL(wp),                   INTENT(IN)    :: current_time
    TYPE(PH_BC_Cache_Type), ALLOCATABLE, INTENT(OUT) :: ph_bc_cache(:)
    INTEGER(i4),                INTENT(OUT)   :: n_bcs
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4), ALLOCATABLE :: bc_indices(:)
    TYPE(MD_BC_Desc) :: bc_desc
    INTEGER(i4) :: i, idx

    CALL init_error_status(status)
    n_bcs = 0_i4
    IF (ALLOCATED(ph_bc_cache)) DEALLOCATE(ph_bc_cache)
    IF (.NOT. md_layer%loadbc%initialized) RETURN

    ALLOCATE(bc_indices(MAX(1_i4, md_layer%loadbc%n_bcs)))
    CALL md_layer%loadbc%GetBCsForStep(step_idx, bc_indices, n_bcs, status)
    IF (status%status_code /= IF_STATUS_OK .OR. n_bcs == 0) RETURN

    ALLOCATE(ph_bc_cache(n_bcs))
    DO i = 1, n_bcs
      idx = bc_indices(i)
      CALL md_layer%loadbc%GetBC(idx, bc_desc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      ph_bc_cache(i)%nodeId = bc_desc%node_id
      ph_bc_cache(i)%dof = bc_desc%dof
      ph_bc_cache(i)%value = bc_desc%value
      ph_bc_cache(i)%current_time = current_time
      IF (bc_desc%amp_ref > 0_i4 .AND. md_layer%amplitude%initialized) THEN
        CALL md_layer%amplitude%EvalAtTime(bc_desc%amp_ref, current_time, &
                                           ph_bc_cache(i)%amp_factor, status)
        IF (status%status_code /= IF_STATUS_OK) ph_bc_cache(i)%amp_factor = 1.0_wp
      ELSE
        ph_bc_cache(i)%amp_factor = 1.0_wp
      END IF
    END DO
  END SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs_FromDomain

  SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads_FromDomain(md_layer, step_idx, current_time, &
                                                         ph_load_cache, n_loads, status)
    TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer
    INTEGER(i4),                INTENT(IN)    :: step_idx
    REAL(wp),                   INTENT(IN)    :: current_time
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE, INTENT(OUT) :: ph_load_cache(:)
    INTEGER(i4),                INTENT(OUT)   :: n_loads
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4), ALLOCATABLE :: load_indices(:)
    TYPE(MD_Load_Desc) :: load_desc
    INTEGER(i4) :: i, idx

    CALL init_error_status(status)
    n_loads = 0_i4
    IF (ALLOCATED(ph_load_cache)) DEALLOCATE(ph_load_cache)
    IF (.NOT. md_layer%loadbc%initialized) RETURN

    ALLOCATE(load_indices(MAX(1_i4, md_layer%loadbc%n_loads)))
    CALL md_layer%loadbc%GetLoadsForStep(step_idx, load_indices, n_loads, status)
    IF (status%status_code /= IF_STATUS_OK .OR. n_loads == 0) RETURN

    ALLOCATE(ph_load_cache(n_loads))
    DO i = 1, n_loads
      idx = load_indices(i)
      CALL md_layer%loadbc%GetLoad(idx, load_desc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      ph_load_cache(i)%loadId = load_desc%load_id
      ph_load_cache(i)%loadType = MD_LoadBC_PH_Brg_LoadTypeToLdbc(load_desc%load_type)
      ph_load_cache(i)%target = load_desc%target_set
      ph_load_cache(i)%magnitude = 0.0_wp
      ph_load_cache(i)%magnitude(1) = load_desc%magnitude
      ph_load_cache(i)%current_time = current_time
      IF (load_desc%amp_ref > 0_i4 .AND. md_layer%amplitude%initialized) THEN
        CALL md_layer%amplitude%EvalAtTime(load_desc%amp_ref, current_time, &
                                           ph_load_cache(i)%amp_factor, status)
        IF (status%status_code /= IF_STATUS_OK) ph_load_cache(i)%amp_factor = 1.0_wp
      ELSE
        ph_load_cache(i)%amp_factor = 1.0_wp
      END IF
    END DO
  END SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads_FromDomain

  !=============================================================================
  ! Bridge: BuildStepBCs_Idx / BuildStepLoads_Idx (Phase 4 Bridge - entity_idx)
  !   Uses g_ufc_global internally; no md_layer parameter.
  !=============================================================================
  SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs_Idx(step_idx, current_time, &
                                                ph_bc_cache, n_bcs, status)
    INTEGER(i4),                INTENT(IN)    :: step_idx
    REAL(wp),                   INTENT(IN)    :: current_time
    TYPE(PH_BC_Cache_Type), ALLOCATABLE, INTENT(OUT) :: ph_bc_cache(:)
    INTEGER(i4),                INTENT(OUT)   :: n_bcs
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    TYPE(MD_LBC_GetBCsForStep_Arg) :: step_arg
    TYPE(MD_LBC_GetBC_Arg) :: bc_arg
    INTEGER(i4) :: i, idx

    CALL init_error_status(status)
    n_bcs = 0_i4
    IF (ALLOCATED(ph_bc_cache)) DEALLOCATE(ph_bc_cache)
    ASSOCIATE(dom => g_ufc_global%md_layer%loadbc)
      IF (.NOT. dom%initialized) RETURN
    END ASSOCIATE

    CALL MD_LoadBC_GetBCsForStep_Idx(step_idx, step_arg, status)
    IF (status%status_code /= IF_STATUS_OK .OR. step_arg%n_found == 0) RETURN
    n_bcs = step_arg%n_found

    ALLOCATE(ph_bc_cache(n_bcs))
    DO i = 1, n_bcs
      idx = step_arg%bc_indices(i)
      CALL MD_LoadBC_GetBC_Idx(idx, bc_arg, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      ph_bc_cache(i)%nodeId = bc_arg%desc%node_id
      ph_bc_cache(i)%dof = bc_arg%desc%dof
      ph_bc_cache(i)%value = bc_arg%desc%value
      ph_bc_cache(i)%current_time = current_time
      IF (bc_arg%desc%amp_ref > 0 .AND. g_ufc_global%md_layer%amplitude%initialized) THEN
        CALL g_ufc_global%md_layer%amplitude%EvalAtTime(bc_arg%desc%amp_ref, current_time, &
                                                         ph_bc_cache(i)%amp_factor, status)
        IF (status%status_code /= IF_STATUS_OK) ph_bc_cache(i)%amp_factor = 1.0_wp
      ELSE
        ph_bc_cache(i)%amp_factor = 1.0_wp
      END IF
    END DO
    IF (ALLOCATED(step_arg%bc_indices)) DEALLOCATE(step_arg%bc_indices)
  END SUBROUTINE MD_LoadBC_PH_Brg_BuildStepBCs_Idx

  SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads_Idx(step_idx, current_time, &
                                                  ph_load_cache, n_loads, status)
    INTEGER(i4),                INTENT(IN)    :: step_idx
    REAL(wp),                   INTENT(IN)    :: current_time
    TYPE(PH_Load_LoadCache_Type), ALLOCATABLE, INTENT(OUT) :: ph_load_cache(:)
    INTEGER(i4),                INTENT(OUT)   :: n_loads
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    TYPE(MD_LBC_GetLoadsForStep_Arg) :: step_arg
    TYPE(MD_LBC_GetLoad_Arg) :: load_arg
    INTEGER(i4) :: i, idx

    CALL init_error_status(status)
    n_loads = 0_i4
    IF (ALLOCATED(ph_load_cache)) DEALLOCATE(ph_load_cache)
    ASSOCIATE(dom => g_ufc_global%md_layer%loadbc)
      IF (.NOT. dom%initialized) RETURN
    END ASSOCIATE

    CALL MD_LoadBC_GetLoadsForStep_Idx(step_idx, step_arg, status)
    IF (status%status_code /= IF_STATUS_OK .OR. step_arg%n_found == 0) RETURN
    n_loads = step_arg%n_found

    ALLOCATE(ph_load_cache(n_loads))
    DO i = 1, n_loads
      idx = step_arg%load_indices(i)
      CALL MD_LoadBC_GetLoad_Idx(idx, load_arg, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      ph_load_cache(i)%loadId = load_arg%desc%load_id
      ph_load_cache(i)%loadType = MD_LoadBC_PH_Brg_LoadTypeToLdbc(load_arg%desc%load_type)
      ph_load_cache(i)%target = load_arg%desc%target_set
      ph_load_cache(i)%magnitude = 0.0_wp
      ph_load_cache(i)%magnitude(1) = load_arg%desc%magnitude
      ph_load_cache(i)%current_time = current_time
      IF (load_arg%desc%amp_ref > 0 .AND. g_ufc_global%md_layer%amplitude%initialized) THEN
        CALL g_ufc_global%md_layer%amplitude%EvalAtTime(load_arg%desc%amp_ref, current_time, &
                                                         ph_load_cache(i)%amp_factor, status)
        IF (status%status_code /= IF_STATUS_OK) ph_load_cache(i)%amp_factor = 1.0_wp
      ELSE
        ph_load_cache(i)%amp_factor = 1.0_wp
      END IF
    END DO
    IF (ALLOCATED(step_arg%load_indices)) DEALLOCATE(step_arg%load_indices)
  END SUBROUTINE MD_LoadBC_PH_Brg_BuildStepLoads_Idx

END MODULE MD_LBCPH_Brg

