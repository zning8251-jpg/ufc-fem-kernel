!===============================================================================
! MODULE: MD_Model_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Model L3→L4/L5 unified bridge
! BRIEF:  DataPlatform registration, step-load/BC build, amplitude update,
!         section projection, and (disabled) contact build.
!===============================================================================


MODULE MD_Model_Brg
    ! ------------------------------------------------------------------------
    ! USE statements (merged from DataPlatform + Contact)
    ! ------------------------------------------------------------------------
    USE IF_Base_DP,     ONLY: &
        dp_init, dp_create_dp_array1d, dp_create_dp_array2d, dp_create_int_array1d, &
        dp_create_int_array2d, dp_create_char_array1d, DP_FORMAT_BINARY, DP_FORMAT_TXT
    USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Err_Chain,        ONLY: UFC_Err_Wrap, LAYER_L3_MD
    USE IF_Prec_Core,             ONLY: wp, i4
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
    USE MD_Constr_Prop, ONLY: UF_ContactPropertyDB, UF_ContactPropertyDef
    USE MD_DOF_Mgr,         ONLY: UF_DOFLabelMap_GetSlot
    USE MD_DOF_Impl,          ONLY: UF_NodalDOF, UF_DOFManagerType
    USE MD_LBC_Brg,       ONLY: BC_DISPLACEMENT, BC_ENCASTRE, BC_PINNED, &
                                  BC_XSYMM, BC_YSYMM, BC_ZSYMM
    USE MD_Step_Sync,        ONLY: MD_Step_SyncFromLegacy
    USE MD_Solv_Sync,         ONLY: MD_Solver_SyncFromStep
    USE MD_Amp_Mgr,      ONLY: MD_Amp_SyncFromLegacy
    USE MD_LoadBC_Sync,      ONLY: MD_LoadBC_SyncFromLegacy
    USE MD_Constr_Sync,  ONLY: MD_Constraint_SyncFromLegacy
    USE MD_Int_Sync, ONLY: MD_Interaction_SyncFromLegacy
    USE MD_Mat_Sync,         ONLY: MD_Mat_SyncFromLegacy
    USE MD_Sect_Sync,     ONLY: MD_Section_SyncFromLegacy, MD_Section_PopulateLegacyFromDomain
    USE MD_Mesh_Sync,        ONLY: MD_Mesh_SyncFromLegacy
    USE MD_Out_Sync,      ONLY: MD_Output_SyncFromLegacy
    USE MD_Part_Sync,        ONLY: MD_Part_SyncFromLegacy
    USE MD_Asm_Sync,            ONLY: MD_Assembly_SyncFromLegacy
    USE MD_Model_Lib_Core,       ONLY: UF_ModelDef
    USE MD_Model_Def, ONLY: MD_Model_Ctx
    USE MD_Sect_Lib,         ONLY: SECTION_SHELL, SECTION_BEAM, SECTION_TRUSS, SECTION_MEMBRANE
    USE MD_Sets_Mgr,        ONLY: MAX_SET_NAME
    USE Phys_ContmMesh,      ONLY: ContMeshCtx
    USE Phys_LoadBC,         ONLY: LoadBC_Step
    ! DANGLING-REF (v2.0): RT_ContactSurface and RT_ContactTypes modules
    ! have been deleted. RT_ContactCore.contact_init_from_pair signature
    ! changed (5 args, not 2). Contact bridge subroutines below are
    ! non-functional until migrated to RT_Cont_Def + RT_ContactCore API.
    ! See: UFC_DOMAIN_PILLAR_ARCHITECTURE.md P3 Contact.
    !
    ! USE RT_ContactCore,      ONLY: contact_init_from_pair
    ! USE RT_ContactSurface,   ONLY: surface_init, surface_add_nodes, ...
    ! USE RT_ContactTypes,     ONLY: RT_ContactSurface, RT_ContactPairDef, ...
    USE RT_Asm_Brg, ONLY: RT_Asm_Brg_FromL3Model
    USE RT_Asm_Domain
    USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
    USE MD_Mesh_API,     ONLY: MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg
    USE UF_ModelVarRegistry, ONLY: UF_ModelVarContext, UF_MV_InitContext, UF_MV_RegisterField, &
                                  UF_MV_SetCurrentContext, UF_MV_Type_DP, UF_MV_Loc_Node

    IMPLICIT NONE
    PRIVATE

    ! ------------------------------------------------------------------------
    ! Public bridge routines (DataPlatform + Contact)
    ! ------------------------------------------------------------------------
    PUBLIC :: UF_BindModelRuntime_ToDataPlatform
    PUBLIC :: UF_BuildContMesh_FromUFModel
    PUBLIC :: UF_BuildStepBC_ForNewCore
    PUBLIC :: UF_BuildStepLoad_ForNewCore
    PUBLIC :: UF_ProjectSectionsToModelCtx
    PUBLIC :: UF_register_model_in_dataplatform
    PUBLIC :: UF_UpdateStepLoadAmplitudes_ForNewCore
    ! DANGLING-REF (v2.0): Contact bridge routines disabled until
    ! migrated to RT_Cont_Def + RT_ContactCore API.
    ! PUBLIC :: UF_BuildContact_FromUFModel
    ! PUBLIC :: UF_BuildContactPairDef_FromDB
    ! PUBLIC :: UF_BuildContactSurface_FromNodeSet
    ! PUBLIC :: UF_FillSurfaceDofMap_FromDOFMgr

    ! ------------------------------------------------------------------------
    ! DataPlatform constants (symbolic variable names)
    ! ------------------------------------------------------------------------
    CHARACTER(LEN=*), PARAMETER :: DP_VAR_NODE_COORDS   = 'Model/Nodes/Coords'
    CHARACTER(LEN=*), PARAMETER :: DP_VAR_ELEM_CONN     = 'Model/Elements/Conn'
    CHARACTER(LEN=*), PARAMETER :: DP_VAR_ELEM_TYPE     = 'Model/Elements/Type'
    CHARACTER(LEN=*), PARAMETER :: DP_VAR_NODE_DOF      = 'Model/DOF/NodeEqn'
    CHARACTER(LEN=*), PARAMETER :: DP_VAR_DOF_TO_NODE   = 'Model/DOF/DofToNode'
    CHARACTER(LEN=*), PARAMETER :: DP_VAR_DOF_TO_LOCAL  = 'Model/DOF/DofToLocal'

CONTAINS

    !---------------------------------------------------------------------------
    ! DataPlatform bridge subroutines
    !---------------------------------------------------------------------------

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_BindModelRuntime_ToDataPlatform
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Register model in DataPlatform and init ModelVar context.
    !---------------------------------------------------------------------------

    SUBROUTINE UF_BindModelRuntime_ToDataPlatform(modelDef, mv_ctx, ierr)
        TYPE(UF_ModelDef),      INTENT(INOUT) :: modelDef
        TYPE(UF_ModelVarContext), INTENT(INOUT) :: mv_ctx
        INTEGER(i4),            INTENT(OUT)   :: ierr

        TYPE(ErrorStatusType) :: status
        INTEGER(i4) :: dims(2)
        INTEGER(i4) :: ierr_loc

        ierr = 0
        CALL UF_register_model_in_dataplatform(modelDef, ierr)
        IF (ierr /= 0) RETURN

        CALL UF_MV_InitContext(TRIM(modelDef%name), mv_ctx)

        ! Mesh : md_layer%mesh
        dims = 0_i4
        dims(1) = 3_i4
        IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized) THEN
            dims(2) = INT(g_ufc_global%md_layer%mesh%desc%nNodes, i4)
        ELSE
            dims(2) = modelDef%assembly%total_nodes
        END IF
        IF (dims(2) > 0) THEN
            CALL UF_MV_RegisterField(mv_ctx, 'U', UF_MV_Loc_Node, UF_MV_Type_DP, 2_i4, dims, &
                                     is_history=.FALSE., is_persistent=.TRUE., ierr=ierr_loc)
            CALL UF_MV_RegisterField(mv_ctx, 'V', UF_MV_Loc_Node, UF_MV_Type_DP, 2_i4, dims, &
                                     is_history=.FALSE., is_persistent=.TRUE., ierr=ierr_loc)
            CALL UF_MV_RegisterField(mv_ctx, 'A', UF_MV_Loc_Node, UF_MV_Type_DP, 2_i4, dims, &
                                     is_history=.FALSE., is_persistent=.TRUE., ierr=ierr_loc)
            CALL UF_MV_RegisterField(mv_ctx, 'REACTION', UF_MV_Loc_Node, UF_MV_Type_DP, 2_i4, dims, &
                                     is_history=.FALSE., is_persistent=.TRUE., ierr=ierr_loc)
        END IF

        CALL UF_MV_SetCurrentContext(mv_ctx)
        CALL init_error_status(status)
    END SUBROUTINE UF_BindModelRuntime_ToDataPlatform

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_BuildContMesh_FromUFModel
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Build continuum mesh from UF_Model for single-elem CPE4.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_BuildContMesh_FromUFModel(modelDef, mdlCtx, contMesh, matId)
        TYPE(UF_ModelDef), INTENT(IN)    :: modelDef
        TYPE(MD_Model_Ctx),    INTENT(INOUT) :: mdlCtx
        TYPE(ContMeshCtx), INTENT(INOUT) :: contMesh
        INTEGER(i4),       INTENT(IN)    :: matId

        INTEGER(i4) :: nnode, nelem, ndim, conn_rows, nNodePerElem, e, k, nodeId
        REAL(wp)    :: X_nodes(2,4)

        IF (.NOT. ASSOCIATED(modelDef%dof_mgr)) RETURN
        IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%mesh%initialized) RETURN
        ! Mesh : md_layer%mesh
        nnode = INT(g_ufc_global%md_layer%mesh%desc%nNodes, i4)
        nelem = INT(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
        IF (nnode <= 0_i4 .OR. nelem <= 0_i4) RETURN

        ndim = modelDef%dimension
        IF (ndim /= 2_i4) RETURN

        conn_rows = SIZE(g_ufc_global%md_layer%mesh%raw_data%element_connect, 1)
        e = 1_i4
        nNodePerElem = 0_i4
        DO k = 1_i4, conn_rows
            IF (g_ufc_global%md_layer%mesh%raw_data%element_connect(k,e) > 0_i8) THEN
                nNodePerElem = nNodePerElem + 1_i4
            ELSE
                EXIT
            END IF
        END DO
        IF (nNodePerElem /= 4_i4) RETURN

        DO k = 1_i4, 4_i4
            nodeId = INT(g_ufc_global%md_layer%mesh%raw_data%element_connect(k,e), i4)
            IF (nodeId < 1_i4 .OR. nodeId > nnode) THEN
                X_nodes(:,k) = 0.0_wp
            ELSE
                X_nodes(1,k) = g_ufc_global%md_layer%mesh%raw_data%node_coords(1,nodeId)
                X_nodes(2,k) = g_ufc_global%md_layer%mesh%raw_data%node_coords(2,nodeId)
            END IF
        END DO

        CALL contMesh%InitOneElemCPE4(X_nodes, matId)

        IF (ALLOCATED(contMesh%idof)) THEN
            DO k = 1_i4, 4_i4
                nodeId = INT(g_ufc_global%md_layer%mesh%raw_data%element_connect(k,e), i4)
                IF (nodeId < 1_i4 .OR. nodeId > modelDef%dof_mgr%num_nodes) CYCLE
                contMesh%idof(1,k) = modelDef%dof_mgr%nodal_dofs(nodeId)%eqn_number(1)
                contMesh%idof(2,k) = modelDef%dof_mgr%nodal_dofs(nodeId)%eqn_number(2)
            END DO
        END IF

        mdlCtx%desc%nGlobalNodes = nnode
        mdlCtx%desc%nGlobalElems = nelem
        mdlCtx%desc%nDof         = modelDef%dof_mgr%num_total_dof
        mdlCtx%desc%nEq          = modelDef%dof_mgr%num_total_dof
        mdlCtx%desc%hasStruct    = .TRUE.
        mdlCtx%desc%dimType      = '2D'
    END SUBROUTINE UF_BuildContMesh_FromUFModel

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_BuildStepBC_ForNewCore
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Build step boundary conditions from model definition.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_BuildStepBC_ForNewCore(modelDef, step_index, stepLoad)
        TYPE(UF_ModelDef), INTENT(INOUT) :: modelDef
        INTEGER(i4),       INTENT(IN)    :: step_index
        TYPE(LoadBC_Step), INTENT(INOUT) :: stepLoad

        INTEGER(i4) :: i, j, k, node_id, dof, eq, label, slot
        INTEGER(i4) :: len_region, len_set
        REAL(wp)    :: time_val, amp_val, val
        CHARACTER(LEN=256) :: region, set_name
        LOGICAL :: found_set, match
        TYPE(MD_Amp_Slot_Desc), POINTER :: amp_ptr
        TYPE(UF_NodalDOF),     POINTER :: ndof_ptr

        IF (.NOT. ASSOCIATED(modelDef%dof_mgr)) RETURN
        IF (step_index < 1_i4 .OR. step_index > modelDef%step_mgr%num_steps) RETURN

        time_val = modelDef%step_mgr%steps(step_index)%current_time

        DO i = 1, modelDef%step_mgr%steps(step_index)%loadbc%num_bcs
            IF (.NOT. modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%is_active) CYCLE

            IF (modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type /= BC_DISPLACEMENT .AND. &
                modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type /= BC_ENCASTRE    .AND. &
                modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type /= BC_PINNED      .AND. &
                modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type /= BC_XSYMM       .AND. &
                modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type /= BC_YSYMM       .AND. &
                modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type /= BC_ZSYMM) CYCLE

            amp_val = 1.0_wp
            IF (LEN_TRIM(modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%amplitude_name) > 0) THEN
                amp_ptr => modelDef%get_amplitude( &
                    modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%amplitude_name)
                IF (ASSOCIATED(amp_ptr)) amp_val = amp_ptr%evaluate(time_val)
            END IF

            SELECT CASE (modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type)
            CASE (BC_DISPLACEMENT)
                val = modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%magnitude * amp_val
            CASE DEFAULT
                val = 0.0_wp
            END SELECT

            IF (modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%node_id > 0 .AND. &
                modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%region_type == 0) THEN

                node_id = modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%node_id
                SELECT CASE (modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type)
                CASE (BC_DISPLACEMENT)
                    DO label = modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%dof_first, &
                                 modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%dof_last
                        slot = 0_i4
                        CALL UF_DOFLabelMap_GetSlot(modelDef%dof_label_map, label, slot)
                        IF (slot <= 0_i4) CYCLE
                        ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                        IF (.NOT. ASSOCIATED(ndof_ptr)) CYCLE
                        eq = ndof_ptr%get_eqn(slot)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, val)
                    END DO
                CASE (BC_ENCASTRE)
                    DO dof = 1, 6
                        ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                        IF (.NOT. ASSOCIATED(ndof_ptr)) CYCLE
                        eq = ndof_ptr%get_eqn(dof)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                    END DO
                CASE (BC_PINNED)
                    DO dof = 1, 3
                        ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                        IF (.NOT. ASSOCIATED(ndof_ptr)) CYCLE
                        eq = ndof_ptr%get_eqn(dof)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                    END DO
                CASE (BC_XSYMM)
                    ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                    IF (ASSOCIATED(ndof_ptr)) THEN
                        eq = ndof_ptr%get_eqn(1)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        eq = ndof_ptr%get_eqn(5)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        eq = ndof_ptr%get_eqn(6)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                    END IF
                CASE (BC_YSYMM)
                    ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                    IF (ASSOCIATED(ndof_ptr)) THEN
                        eq = ndof_ptr%get_eqn(2)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        eq = ndof_ptr%get_eqn(4)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        eq = ndof_ptr%get_eqn(6)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                    END IF
                CASE (BC_ZSYMM)
                    ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                    IF (ASSOCIATED(ndof_ptr)) THEN
                        eq = ndof_ptr%get_eqn(3)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        eq = ndof_ptr%get_eqn(4)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        eq = ndof_ptr%get_eqn(5)
                        IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                    END IF
                END SELECT
                CYCLE
            END IF

            region = TRIM(modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%region_name)
            len_region = LEN_TRIM(region)
            IF (len_region <= 0) CYCLE

            found_set = .FALSE.
            DO j = 1, modelDef%assembly%num_node_sets
                set_name = TRIM(modelDef%assembly%node_sets(j)%name)
                len_set  = LEN_TRIM(set_name)
                match = .FALSE.
                IF (len_set == len_region) THEN
                    IF (set_name(1:len_set) == region(1:len_region)) match = .TRUE.
                ELSEIF (len_set > len_region + 1) THEN
                    IF (set_name(len_set-len_region+1:len_set) == region(1:len_region) .AND. &
                        set_name(len_set-len_region:len_set-len_region) == ".") match = .TRUE.
                END IF
                IF (.NOT. match) CYCLE

                found_set = .TRUE.
                DO k = 1, modelDef%assembly%node_sets(j)%num_nodes
                    node_id = modelDef%assembly%node_sets(j)%node_ids(k)
                    SELECT CASE (modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%bc_type)
                    CASE (BC_DISPLACEMENT)
                        DO label = modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%dof_first, &
                                     modelDef%step_mgr%steps(step_index)%loadbc%bcs(i)%dof_last
                            slot = 0_i4
                            CALL UF_DOFLabelMap_GetSlot(modelDef%dof_label_map, label, slot)
                            IF (slot <= 0_i4) CYCLE
                            ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                            IF (.NOT. ASSOCIATED(ndof_ptr)) CYCLE
                            eq = ndof_ptr%get_eqn(slot)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, val)
                        END DO
                    CASE (BC_ENCASTRE)
                        DO dof = 1, 6
                            ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                            IF (.NOT. ASSOCIATED(ndof_ptr)) CYCLE
                            eq = ndof_ptr%get_eqn(dof)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        END DO
                    CASE (BC_PINNED)
                        DO dof = 1, 3
                            ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                            IF (.NOT. ASSOCIATED(ndof_ptr)) CYCLE
                            eq = ndof_ptr%get_eqn(dof)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        END DO
                    CASE (BC_XSYMM)
                        ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                        IF (ASSOCIATED(ndof_ptr)) THEN
                            eq = ndof_ptr%get_eqn(1)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                            eq = ndof_ptr%get_eqn(5)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                            eq = ndof_ptr%get_eqn(6)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        END IF
                    CASE (BC_YSYMM)
                        ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                        IF (ASSOCIATED(ndof_ptr)) THEN
                            eq = ndof_ptr%get_eqn(2)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                            eq = ndof_ptr%get_eqn(4)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                            eq = ndof_ptr%get_eqn(6)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        END IF
                    CASE (BC_ZSYMM)
                        ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                        IF (ASSOCIATED(ndof_ptr)) THEN
                            eq = ndof_ptr%get_eqn(3)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                            eq = ndof_ptr%get_eqn(4)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                            eq = ndof_ptr%get_eqn(5)
                            IF (eq > 0_i4) CALL stepLoad%FixDof(eq, 0.0_wp)
                        END IF
                    END SELECT
                END DO
            END DO
        END DO
    END SUBROUTINE UF_BuildStepBC_ForNewCore

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_BuildStepLoad_ForNewCore
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Build step concentrated loads from model definition.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_BuildStepLoad_ForNewCore(modelDef, step_index, stepLoad)
        TYPE(UF_ModelDef), INTENT(INOUT) :: modelDef
        INTEGER(i4),       INTENT(IN)    :: step_index
        TYPE(LoadBC_Step), INTENT(INOUT) :: stepLoad

        INTEGER(i4) :: ndof, i, j, k, node_id, dof, eq, ampId
        INTEGER(i4) :: len_region, len_set
        CHARACTER(LEN=256) :: region, set_name
        LOGICAL :: found_set, match
        TYPE(UF_NodalDOF), POINTER :: ndof_ptr

        IF (.NOT. ASSOCIATED(modelDef%dof_mgr)) RETURN
        ndof = modelDef%dof_mgr%num_total_dof
        IF (ndof <= 0_i4) RETURN

        CALL stepLoad%Init(ndof)
        IF (step_index < 1_i4 .OR. step_index > modelDef%step_mgr%num_steps) RETURN

        DO i = 1, modelDef%step_mgr%steps(step_index)%loadbc%num_cloads
            IF (.NOT. modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%is_active) CYCLE

            ampId = 0_i4
            IF (LEN_TRIM(modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%amplitude_name) > 0) THEN
                IF (modelDef%num_amplitudes > 0 .AND. ALLOCATED(modelDef%amplitudes)) THEN
                    DO j = 1, modelDef%num_amplitudes
                        IF (TRIM(modelDef%amplitudes(j)%name) == &
                            TRIM(modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%amplitude_name)) THEN
                            ampId = j
                            EXIT
                        END IF
                    END DO
                END IF
            END IF

            IF (modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%node_id > 0 .AND. &
                LEN_TRIM(modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%nset_name) == 0) THEN

                node_id = modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%node_id
                dof     = modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%dof
                ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                IF (ASSOCIATED(ndof_ptr)) THEN
                    eq = ndof_ptr%get_eqn(dof)
                    IF (eq > 0_i4) THEN
                        IF (ampId > 0_i4) THEN
                            CALL stepLoad%AddDofLoadWithAmp(eq, &
                                 modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%magnitude, ampId)
                        ELSE
                            CALL stepLoad%AddDofLoad(eq, &
                                 modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%magnitude)
                        END IF
                    END IF
                END IF
                CYCLE
            END IF

            region = TRIM(modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%nset_name)
            len_region = LEN_TRIM(region)
            IF (len_region <= 0) CYCLE

            found_set = .FALSE.
            DO j = 1, modelDef%assembly%num_node_sets
                set_name = TRIM(modelDef%assembly%node_sets(j)%name)
                len_set  = LEN_TRIM(set_name)
                match = .FALSE.
                IF (len_set == len_region) THEN
                    IF (set_name(1:len_set) == region(1:len_region)) match = .TRUE.
                ELSEIF (len_set > len_region + 1) THEN
                    IF (set_name(len_set-len_region+1:len_set) == region(1:len_region) .AND. &
                        set_name(len_set-len_region:len_set-len_region) == ".") match = .TRUE.
                END IF
                IF (.NOT. match) CYCLE

                found_set = .TRUE.
                DO k = 1, modelDef%assembly%node_sets(j)%num_nodes
                    node_id = modelDef%assembly%node_sets(j)%node_ids(k)
                    dof     = modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%dof
                    ndof_ptr => modelDef%dof_mgr%get_nodal_dof(node_id)
                    IF (ASSOCIATED(ndof_ptr)) THEN
                        eq = ndof_ptr%get_eqn(dof)
                        IF (eq > 0_i4) THEN
                            IF (ampId > 0_i4) THEN
                                CALL stepLoad%AddDofLoadWithAmp(eq, &
                                     modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%magnitude, ampId)
                            ELSE
                                CALL stepLoad%AddDofLoad(eq, &
                                     modelDef%step_mgr%steps(step_index)%loadbc%cloads(i)%magnitude)
                            END IF
                        END IF
                    END IF
                END DO
            END DO
        END DO
    END SUBROUTINE UF_BuildStepLoad_ForNewCore

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_ProjectSectionsToModelCtx
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Project section definitions into ModelCtx descriptor.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_ProjectSectionsToModelCtx(modelDef, mdlCtx)
        TYPE(UF_ModelDef), INTENT(IN)    :: modelDef
        TYPE(MD_Model_Ctx),    INTENT(INOUT) :: mdlCtx

        INTEGER(i4) :: nsec, i

        nsec = modelDef%section_db%num_sections
        mdlCtx%desc%nSections = nsec

        IF (ALLOCATED(mdlCtx%desc%sections)) DEALLOCATE(mdlCtx%desc%sections)
        IF (nsec <= 0) RETURN

        ALLOCATE(mdlCtx%desc%sections(nsec))

        DO i = 1, nsec
            CALL mdlCtx%desc%sections(i)%Init( &
                id           = modelDef%section_db%sections(i)%id, &
                name         = TRIM(modelDef%section_db%sections(i)%name), &
                sectionType  = modelDef%section_db%sections(i)%section_type, &
                materialId   = modelDef%section_db%sections(i)%material_id, &
                materialName = TRIM(modelDef%section_db%sections(i)%material_name), &
                thickness    = modelDef%section_db%sections(i)%thickness )

            ! SECTION_* from MD_SectLib - canonical codes for UF_SectionDef%section_type
            SELECT CASE (modelDef%section_db%sections(i)%section_type)
            CASE (SECTION_SHELL)
                mdlCtx%desc%sections(i)%thickness = modelDef%section_db%sections(i)%shell_thickness
                mdlCtx%desc%sections(i)%nIntPoints = modelDef%section_db%sections(i)%num_integration_points
            CASE (SECTION_MEMBRANE)
                mdlCtx%desc%sections(i)%thickness = modelDef%section_db%sections(i)%membrane_thickness
            CASE (SECTION_TRUSS)
                mdlCtx%desc%sections(i)%area = modelDef%section_db%sections(i)%truss_area
            CASE (SECTION_BEAM)
                mdlCtx%desc%sections(i)%area = modelDef%section_db%sections(i)%area
                mdlCtx%desc%sections(i)%I11  = modelDef%section_db%sections(i)%Iyy
                mdlCtx%desc%sections(i)%I22  = modelDef%section_db%sections(i)%Izz
                mdlCtx%desc%sections(i)%I12  = modelDef%section_db%sections(i)%Iyz
                mdlCtx%desc%sections(i)%J    = modelDef%section_db%sections(i)%J
            END SELECT
        END DO
    END SUBROUTINE UF_ProjectSectionsToModelCtx

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_register_model_in_dataplatform
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Sync all L3 domains from legacy model and register in DP.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_register_model_in_dataplatform(model, ierr)
        TYPE(UF_ModelDef), INTENT(IN) :: model
        INTEGER(i4),       INTENT(OUT) :: ierr

        TYPE(ErrorStatusType) :: dp_status
        REAL(wp), POINTER     :: node_coords_dp(:,:)
        INTEGER,  POINTER     :: elem_conn_dp(:,:)
        INTEGER,  POINTER     :: elem_type_dp(:)
        INTEGER,  POINTER     :: node_dof_dp(:,:)
        INTEGER,  POINTER     :: dof_to_node_dp(:)
        INTEGER,  POINTER     :: dof_to_local_dp(:)
        INTEGER(i4) :: nnode, nelem, ndim_coords, conn_rows, dof_per_node, num_total_dof, nid

        ierr = 0

        IF (g_ufc_global%IsReady()) THEN
            IF (g_ufc_global%md_layer%l3Frozen) THEN
                ierr = IF_STATUS_INVALID
                RETURN
            END IF
            CALL MD_Step_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Solver_SyncFromStep(g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Amp_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_LoadBC_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            ! UF_ModelDef%assembly -> md_layer%assembly (instances/sets/surfaces/legacy UF constraints)
            ! Before MD_Constraint_SyncFromLegacy (uses md_layer%assembly%constraint_union).
            CALL MD_Assembly_SyncFromLegacy(model%assembly, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Constraint_SyncFromLegacy(g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Interaction_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Mat_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Section_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Section_PopulateLegacyFromDomain(g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Part_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Output_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            CALL MD_Mesh_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
        ELSE
            ! Global not fully Ready: still sync UF assembly -> md_layer when L3 is live.
            IF (g_ufc_global%md_layer%initialized .AND. (.NOT. g_ufc_global%md_layer%l3Frozen) .AND. &
                g_ufc_global%md_layer%assembly%initialized) THEN
                CALL MD_Assembly_SyncFromLegacy(model%assembly, g_ufc_global%md_layer, dp_status)
                IF (dp_status%status_code /= IF_STATUS_OK) THEN
                    ierr = dp_status%status_code
                    RETURN
                END IF
            END IF
            ! If mesh domain is already up, allow flat assembly -> mesh without full IsReady().
            IF (g_ufc_global%md_layer%initialized .AND. (.NOT. g_ufc_global%md_layer%l3Frozen) .AND. &
                g_ufc_global%md_layer%mesh%initialized) THEN
                CALL MD_Mesh_SyncFromLegacy(model, g_ufc_global%md_layer, dp_status)
                IF (dp_status%status_code /= IF_STATUS_OK) THEN
                    ierr = dp_status%status_code
                    RETURN
                END IF
            END IF
        END IF

        CALL dp_init(dp_status)
        IF (dp_status%status_code /= IF_STATUS_OK) THEN
            ierr = dp_status%status_code
            RETURN
        END IF

        IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized) THEN
            nnode = INT(g_ufc_global%md_layer%mesh%raw_data%nNodes, i4)
            nelem = INT(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
        ELSE
            nnode = model%assembly%total_nodes
            nelem = model%assembly%total_elements
        END IF

        ! Assembly bounds pipeline (order — keep BuildPattern/global assemble **after** this block):
        !   (1) L3 mesh/model ready   (2) RT_Asm_Brg_FromL3Model -> bridge%assembly_desc
        !   (3) SyncL3BoundsFromBridge -> rt_layer%assembly%l3_bounds
        !   (4) separate step: RT_Assembly_Domain%BuildPattern / RT_Asm_Solv global assembly (solver harness).
        IF (g_ufc_global%IsReady() .AND. g_ufc_global%rt_layer%initialized .AND. &
            g_ufc_global%rt_layer%bridge%initialized .AND. &
            g_ufc_global%md_layer%mesh%initialized .AND. &
            nnode > 0 .AND. nelem > 0) THEN
            IF (ALLOCATED(g_ufc_global%md_layer%mesh%raw_data%node_coords)) THEN
                ndim_coords = SIZE(g_ufc_global%md_layer%mesh%raw_data%node_coords, 1)
            ELSE
                ndim_coords = 3
            END IF
            CALL RT_Asm_Brg_FromL3Model(INT(nnode, i4), INT(nelem, i4), INT(ndim_coords, i4), &
                g_ufc_global%rt_layer%bridge%assembly_desc, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            IF (g_ufc_global%rt_layer%assembly%initialized) THEN
                CALL g_ufc_global%rt_layer%assembly%SyncL3BoundsFromBridge(g_ufc_global%rt_layer%bridge, dp_status)
                IF (dp_status%status_code /= IF_STATUS_OK) THEN
                    ierr = dp_status%status_code
                    RETURN
                END IF
            END IF
        END IF

        IF (nnode > 0 .AND. g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized .AND. &
            ALLOCATED(g_ufc_global%md_layer%mesh%raw_data%node_coords)) THEN
            ndim_coords = SIZE(g_ufc_global%md_layer%mesh%raw_data%node_coords, 1)
            CALL dp_create_dp_array2d(DP_VAR_NODE_COORDS, ndim_coords, nnode, node_coords_dp, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            node_coords_dp(1:ndim_coords, 1:nnode) = &
                g_ufc_global%md_layer%mesh%raw_data%node_coords(1:ndim_coords, 1:nnode)
        END IF

        IF (nelem > 0 .AND. g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized .AND. &
            ALLOCATED(g_ufc_global%md_layer%mesh%raw_data%element_connect)) THEN
            conn_rows = SIZE(g_ufc_global%md_layer%mesh%raw_data%element_connect, 1)
            CALL dp_create_int_array2d(DP_VAR_ELEM_CONN, conn_rows, nelem, elem_conn_dp, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            elem_conn_dp(1:conn_rows, 1:nelem) = &
                INT(g_ufc_global%md_layer%mesh%raw_data%element_connect(1:conn_rows, 1:nelem))
        END IF

        IF (nelem > 0 .AND. g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized .AND. &
            ALLOCATED(g_ufc_global%md_layer%mesh%raw_data%element_types)) THEN
            CALL dp_create_int_array1d(DP_VAR_ELEM_TYPE, nelem, elem_type_dp, dp_status)
            IF (dp_status%status_code /= IF_STATUS_OK) THEN
                ierr = dp_status%status_code
                RETURN
            END IF
            elem_type_dp(1:nelem) = g_ufc_global%md_layer%mesh%raw_data%element_types(1:nelem)
        END IF

        IF (nnode > 0 .AND. model%dof_mgr%num_nodes == nnode) THEN
            dof_per_node  = model%dof_mgr%nodal_dofs(1)%num_dof
            num_total_dof = model%dof_mgr%num_total_dof

            IF (dof_per_node > 0) THEN
                CALL dp_create_int_array2d(DP_VAR_NODE_DOF, dof_per_node, nnode, node_dof_dp, dp_status)
                IF (dp_status%status_code /= IF_STATUS_OK) THEN
                    ierr = dp_status%status_code
                    RETURN
                END IF
                node_dof_dp(:,:) = 0
                DO nid = 1, nnode
                    node_dof_dp(1:dof_per_node, nid) = &
                        model%dof_mgr%nodal_dofs(nid)%eqn_number(1:dof_per_node)
                END DO
            END IF

            IF (num_total_dof > 0 .AND. ALLOCATED(model%dof_mgr%dof_to_node) .AND. &
                ALLOCATED(model%dof_mgr%dof_to_local)) THEN
                CALL dp_create_int_array1d(DP_VAR_DOF_TO_NODE, num_total_dof, dof_to_node_dp, dp_status)
                IF (dp_status%status_code /= IF_STATUS_OK) THEN
                    ierr = dp_status%status_code
                    RETURN
                END IF
                CALL dp_create_int_array1d(DP_VAR_DOF_TO_LOCAL, num_total_dof, dof_to_local_dp, dp_status)
                IF (dp_status%status_code /= IF_STATUS_OK) THEN
                    ierr = dp_status%status_code
                    RETURN
                END IF
                dof_to_node_dp(1:num_total_dof)  = model%dof_mgr%dof_to_node(1:num_total_dof)
                dof_to_local_dp(1:num_total_dof) = model%dof_mgr%dof_to_local(1:num_total_dof)
            END IF
        END IF

        CALL register_materials(model, ierr)
        IF (ierr /= 0) RETURN
        CALL register_sections(model, ierr)
        IF (ierr /= 0) RETURN
    END SUBROUTINE UF_register_model_in_dataplatform

    !---------------------------------------------------------------------------
    ! SUBROUTINE: UF_UpdateStepLoadAmplitudes_ForNewCore
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Update amplitude values for all step loads at given time.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_UpdateStepLoadAmplitudes_ForNewCore(modelDef, time, stepLoad)
        TYPE(UF_ModelDef), INTENT(IN)    :: modelDef
        REAL(wp),          INTENT(IN)    :: time
        TYPE(LoadBC_Step), INTENT(INOUT) :: stepLoad

        INTEGER(i4) :: i
        REAL(wp)    :: val

        IF (modelDef%num_amplitudes <= 0) RETURN
        IF (.NOT. ALLOCATED(modelDef%amplitudes)) RETURN

        DO i = 1, modelDef%num_amplitudes
            val = modelDef%amplitudes(i)%evaluate(time)
            CALL stepLoad%SetAmplitudeValue(i, val)
        END DO
    END SUBROUTINE UF_UpdateStepLoadAmplitudes_ForNewCore

    SUBROUTINE register_materials(model, ierr)
        TYPE(UF_ModelDef), INTENT(IN) :: model
        INTEGER(i4),       INTENT(OUT) :: ierr

        TYPE(ErrorStatusType) :: dp_status
        INTEGER(i4) :: nmat, i
        CHARACTER(LEN=64), POINTER :: mat_names(:)
        REAL(wp), POINTER :: density(:), elastic(:,:), thermal(:,:)

        ierr = 0
        nmat = model%material_db%num_materials
        IF (nmat <= 0) RETURN

        CALL dp_create_char_array1d("Model/Materials/Names", nmat, 64, mat_names, dp_status)
        IF (dp_status%status_code /= IF_STATUS_OK) THEN
            ierr = dp_status%status_code
            RETURN
        END IF
        CALL dp_create_dp_array1d("Model/Materials/Density", nmat, density, dp_status)
        CALL dp_create_dp_array2d("Model/Materials/Elastic", 2, nmat, elastic, dp_status)
        CALL dp_create_dp_array2d("Model/Materials/Thermal", 3, nmat, thermal, dp_status)

        DO i = 1, nmat
            mat_names(i) = TRIM(model%material_db%materials(i)%name)
            density(i) = model%material_db%materials(i)%density
            elastic(1, i) = model%material_db%materials(i)%E
            elastic(2, i) = model%material_db%materials(i)%nu
            thermal(1, i) = model%material_db%materials(i)%alpha
            thermal(2, i) = model%material_db%materials(i)%conductivity
            thermal(3, i) = model%material_db%materials(i)%specific_heat
        END DO
    END SUBROUTINE register_materials

    SUBROUTINE register_sections(model, ierr)
        TYPE(UF_ModelDef), INTENT(IN) :: model
        INTEGER(i4),       INTENT(OUT) :: ierr

        TYPE(ErrorStatusType) :: dp_status
        INTEGER(i4) :: nsec, i
        CHARACTER(LEN=64), POINTER :: sec_names(:), sec_mats(:), sec_elsets(:)
        INTEGER(i4), POINTER :: sec_types(:)
        REAL(wp), POINTER :: sec_thick(:)

        ierr = 0
        nsec = model%section_db%num_sections
        IF (nsec <= 0) RETURN

        CALL dp_create_char_array1d("Model/Sections/Names", nsec, 64, sec_names, dp_status)
        IF (dp_status%status_code /= IF_STATUS_OK) THEN
            ierr = dp_status%status_code
            RETURN
        END IF
        CALL dp_create_int_array1d("Model/Sections/Types", nsec, sec_types, dp_status)
        CALL dp_create_char_array1d("Model/Sections/MatNames", nsec, 64, sec_mats, dp_status)
        CALL dp_create_char_array1d("Model/Sections/ElsetNames", nsec, 64, sec_elsets, dp_status)
        CALL dp_create_dp_array1d("Model/Sections/Thickness", nsec, sec_thick, dp_status)

        DO i = 1, nsec
            sec_names(i) = TRIM(model%section_db%sections(i)%name)
            sec_types(i) = model%section_db%sections(i)%section_type
            sec_mats(i) = TRIM(model%section_db%sections(i)%material_name)
            sec_elsets(i) = TRIM(model%section_db%sections(i)%elset_name)
            IF (model%section_db%sections(i)%section_type == 2) THEN
                sec_thick(i) = model%section_db%sections(i)%shell_thickness
            ELSE
                sec_thick(i) = model%section_db%sections(i)%thickness
            END IF
        END DO
    END SUBROUTINE register_sections

    !---------------------------------------------------------------------------
    ! Contact bridge section (DANGLING-REF v2.0 — disabled)
    !---------------------------------------------------------------------------

    ! DANGLING-REF (v2.0): UF_BuildContactPairDef_FromDB disabled.
    ! Uses deleted RT_ContactTypes (RT_ContactPairDef, constants).
    ! Will be migrated to RT_Cont_Def + RT_ContactCore API.
    !
    ! SUBROUTINE UF_BuildContactPairDef_FromDB(modelDef, prop_name, ...)
    !   ... (body commented out — see git history for original)
    ! END SUBROUTINE UF_BuildContactPairDef_FromDB

    ! DANGLING-REF (v2.0): UF_BuildContactSurface_FromNodeSet disabled.
    ! Uses deleted RT_ContactSurface type and surface_init/surface_add_nodes.
    ! Will be migrated to RT_Cont_Def + RT_ContactCore API.
    !
    ! SUBROUTINE UF_BuildContactSurface_FromNodeSet(modelDef, nset_name, ...)
    !   ... (body commented out — see git history for original)
    ! END SUBROUTINE UF_BuildContactSurface_FromNodeSet

    ! DANGLING-REF (v2.0): UF_BuildContact_FromUFModel disabled.
    ! Uses deleted RT_ContactTypes (RT_ContactPairDef, RT_ContactPair, RT_ContactSurface)
    ! and contact_init_from_pair (signature changed: 2 args -> 5 args).
    ! Will be migrated to RT_Cont_Def + RT_ContactCore API.
    !
    ! SUBROUTINE UF_BuildContact_FromUFModel(modelDef, slave_nset, ...)
    !   ... (body commented out — see git history for original)
    ! END SUBROUTINE UF_BuildContact_FromUFModel

    ! DANGLING-REF (v2.0): UF_FillSurfaceDofMap_FromDOFMgr disabled.
    ! Uses deleted RT_ContactSurface type.
    ! Will be migrated when Contact bridge is rebuilt.
    !
    ! SUBROUTINE UF_FillSurfaceDofMap_FromDOFMgr(dof_mgr, surf, nnode_tot)
    !   ... (body commented out — see git history for original)
    ! END SUBROUTINE UF_FillSurfaceDofMap_FromDOFMgr

END MODULE MD_Model_Brg
