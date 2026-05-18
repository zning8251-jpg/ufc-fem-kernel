!===============================================================================
! MODULE: MD_Int_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Interaction/Contact L3→L5 bridge
! BRIEF:  Build contact surfaces/pairs from UF_Model, map DOF/displacement
!         for Contact Manager facade, support 2D/3D penalty contact.
! PILOT:  L3→L5 桥唯一宿主在本文件；勿在 `L3_MD/Interaction/` 再引入同名 `MODULE MD_Int_Brg` 存根。
!===============================================================================


MODULE MD_Int_Brg
    USE IF_Err_Brg, ONLY: log_error, init_error_status, ErrorStatusType, IF_STATUS_OK
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Int_API, ONLY: CONTACT_2D, CONTACT_3D, CONTACT_SURFACE, COORD_3D_GENERA
    USE MD_Cont_Mgr, ONLY: MD_Interaction_Domain, MD_ContactProperty
    USE MD_Int_Mgr
    USE MD_Int_Def
    USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
    USE MD_TypeSystem, ONLY: UF_Model, UF_Part, UF_NodeState
    USE RT_Solv_Def, ONLY: RT_Sol_DofMap
    USE RT_Solv_CoreMemPool
    USE MD_Mesh_Mgr, ONLY: UF_ElementType, UF_GetElementType, UF_GetFaceLocalNodes

    IMPLICIT NONE
    PRIVATE

    ! PUBLIC procedures (A-Z)
    PUBLIC :: MD_Contact_Brg_BuildStepPairs, MD_Contact_Brg_ConvertProperty
    PUBLIC :: UF_ContBrg_GetPropForInteract, UF_ContBrg_IncrInit
    PUBLIC :: UF_ContBrg_InitFromMD, UF_ContBrg_IterationInit

    !-----------------------------------------------------------------------------
    ! Bridge-level state (lifetime = analysis)
    !   - bridge_problem : contact_problem in manager has been built
    !   - bridge_dofmap_i  : global DOF mapping for surfaces has been set
    !   - bridge_contact         : CONTACT_2D / CONTACT_3D (UF_Contact_Types)
    !   - bridge_ndof                : DOFs per node used for contact (1..3)
    !   - bridge_global_d      : (bridge_ndof, maxNodeId) eq numbering map
    !   - bridge_E_ref               : reference Young's modulus for penalty scaling
    !-----------------------------------------------------------------------------
    LOGICAL, SAVE :: bridge_problem = .FALSE.
    LOGICAL, SAVE :: bridge_dofmap_i = .FALSE.

    INTEGER(i4), SAVE :: bridge_contact = CONTACT_3D
    INTEGER(i4), SAVE :: bridge_ndof = 3_i4
    INTEGER(i4), SAVE :: bridge_max_node = 0_i4

    REAL(wp), SAVE :: bridge_E_ref = 2.0E11_wp   ! Default: steel-like

    INTEGER(i4), ALLOCATABLE, SAVE :: bridge_global_d(:,:)  ! (ndof, maxNodeId)

CONTAINS

    !---------------------------------------------------------------------------
    ! Merged bridge functions from MD_Interaction_DefBrg
    !---------------------------------------------------------------------------

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_Contact_Brg_BuildStepPairs
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Build step-active contact pairs (Domain or legacy fallback).
    !---------------------------------------------------------------------------
    SUBROUTINE MD_Contact_Brg_BuildStepPairs(ctx)
        TYPE(MD_Contact_BuildStepPairs_Ctx_Type), INTENT(INOUT) :: ctx
        TYPE(MD_ContactPair_Type), ALLOCATABLE :: active_pairs(:)
        INTEGER(i4), ALLOCATABLE :: pair_indices(:)
        INTEGER(i4) :: i, n_active, max_pairs
        TYPE(ErrorStatusType) :: status

        ctx%nPairs = 0_i4
        IF (ALLOCATED(ctx%pair_ids)) DEALLOCATE(ctx%pair_ids)

        !--- Index-tree + flat domain: prefer md_layer%interaction ---
        IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%interaction%initialized) THEN
            max_pairs = MAX(1_i4, g_ufc_global%md_layer%interaction%n_pairs)
            ALLOCATE(pair_indices(max_pairs))
            CALL g_ufc_global%md_layer%interaction%GetPairsForStep( &
                ctx%stepId, pair_indices, n_active, status)
            IF (status%status_code == IF_STATUS_OK .AND. n_active > 0_i4) THEN
                ctx%nPairs = n_active
                ALLOCATE(ctx%pair_ids(ctx%nPairs))
                DO i = 1, ctx%nPairs
                    ctx%pair_ids(i) = pair_indices(i)
                END DO
            END IF
            IF (ALLOCATED(pair_indices)) DEALLOCATE(pair_indices)
            RETURN
        END IF

        !--- Legacy fallback ---
        CALL MD_ContactCtrl_GetPairsForStep(ctx%md_contact_ctrl, ctx%stepId, active_pairs, ctx%nPairs)
        IF (ctx%nPairs == 0) RETURN
        ALLOCATE(ctx%pair_ids(ctx%nPairs))
        DO i = 1, ctx%nPairs
            ctx%pair_ids(i) = active_pairs(i)%cfg%id
        END DO
        IF (ALLOCATED(active_pairs)) DEALLOCATE(active_pairs)
    END SUBROUTINE MD_Contact_Brg_BuildStepPairs

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_Contact_Brg_ConvertProperty
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Convert contact property for bridge (penalty/friction/radius).
    !---------------------------------------------------------------------------
    !> Purpose: Convert contact property for bridge (merged from MD_Interaction_DefBrg)
    SUBROUTINE MD_Contact_Brg_ConvertProperty(ctx)
        TYPE(MD_Contact_ConvertProperty_Ctx_Type), INTENT(INOUT) :: ctx

        ctx%penalty_stiffness = ctx%md_property%penalty_stiffness
        ctx%friction_coeff = ctx%md_property%friction%mu_static
        ctx%search_radius = ctx%md_property%search_radius
        
    END SUBROUTINE MD_Contact_Brg_ConvertProperty

    !---------------------------------------------------------------------------
    ! Original bridge functions
    !---------------------------------------------------------------------------

    SUBROUTINE Brg_AddSurfaceFromPart(part, localSurfId, globalSurfId, &
                                       X, Y, Z, contact_dim, ierr)
        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: localSurfId
        INTEGER(i4), INTENT(IN) :: globalSurfId
        REAL(wp), INTENT(IN) :: X(:), Y(:), Z(:)
        INTEGER(i4), INTENT(IN) :: contact_dim
        INTEGER(i4), INTENT(OUT) :: ierr

        INTEGER(i4), ALLOCATABLE :: nodeIds(:)
        INTEGER(i4) :: nUnique
        INTEGER(i4) :: status

        ierr = 0_i4

        IF (.NOT. ALLOCATED(part%surfSets)) RETURN
        IF (localSurfId < 1_i4 .OR. localSurfId > SIZE(part%surfSets)) RETURN

        CALL Brg_CollectSurfaceNodes(part, localSurfId, nodeIds, nUnique)
        IF (nUnique <= 0_i4) THEN
            ierr = -1_i4
            RETURN
        END IF

        status = 0_i4
        CALL contact_add_surface(globalSurfId, nodeIds, nUnique, X, Y, Z, &
                                 is_master=.FALSE., coord_type=COORD_3D_GENERA, ierr=status)
        IF (status /= 0_i4) THEN
            ierr = status
        END IF

        IF (ALLOCATED(nodeIds)) DEALLOCATE(nodeIds)

    END SUBROUTINE Brg_AddSurfaceFromPart

    !> Build global coordinates from md_layer%mesh (index-tree + flat domain)
    !> When g_ufc_global%IsReady() and md_layer%mesh initialized: use mesh single source
    SUBROUTINE Brg_BuildGlobalCoordinates_FromMesh(X, Y, Z, maxNodeId, ierr)
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: X(:), Y(:), Z(:)
        INTEGER(i4), INTENT(OUT) :: maxNodeId
        INTEGER(i4), INTENT(OUT) :: ierr

        INTEGER(i4) :: nNodes, i

        ierr = 0_i4
        maxNodeId = 0_i4

        IF (.NOT. g_ufc_global%IsReady()) THEN
            ierr = -1_i4
            RETURN
        END IF
        IF (.NOT. g_ufc_global%md_layer%mesh%initialized) THEN
            ierr = -1_i4
            RETURN
        END IF
        IF (.NOT. ALLOCATED(g_ufc_global%md_layer%mesh%raw_data%node_coords)) THEN
            ierr = -2_i4
            RETURN
        END IF

        nNodes = INT(g_ufc_global%md_layer%mesh%raw_data%nNodes, i4)
        IF (nNodes <= 0_i4) RETURN

        maxNodeId = nNodes
        ALLOCATE(X(maxNodeId), Y(maxNodeId), Z(maxNodeId))
        X = 0.0_wp
        Y = 0.0_wp
        Z = 0.0_wp

        ! node_coords(spatial_dim, nNodes); Z=0 for 2D
        DO i = 1, MIN(nNodes, INT(SIZE(g_ufc_global%md_layer%mesh%raw_data%node_coords, 2), i4))
            X(i) = g_ufc_global%md_layer%mesh%raw_data%node_coords(1, i)
            Y(i) = g_ufc_global%md_layer%mesh%raw_data%node_coords(2, i)
            IF (g_ufc_global%md_layer%mesh%raw_data%spatial_dim >= 3_i4) THEN
                Z(i) = g_ufc_global%md_layer%mesh%raw_data%node_coords(3, i)
            ELSE
                Z(i) = 0.0_wp
            END IF
        END DO
    END SUBROUTINE Brg_BuildGlobalCoordinates_FromMesh

    SUBROUTINE Brg_BuildGlobalCoordinates(model, X, Y, Z, maxNodeId, ierr)
        TYPE(UF_Model), INTENT(IN) :: model
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: X(:), Y(:), Z(:)
        INTEGER(i4), INTENT(OUT) :: maxNodeId
        INTEGER(i4), INTENT(OUT) :: ierr

        INTEGER(i4) :: iPart, iNode, id
        TYPE(ErrorStatusType) :: mem_status
        LOGICAL :: use_mem_pool, X_from_pool, Y_from_pool, Z_from_pool
        REAL(wp), POINTER :: X_ptr(:), Y_ptr(:), Z_ptr(:)

        CALL init_error_status(mem_status)
        use_mem_pool = g_core_mem_pool%initialized
        X_from_pool = .FALSE.
        Y_from_pool = .FALSE.
        Z_from_pool = .FALSE.

        ierr = 0_i4
        maxNodeId = 0_i4

        IF (.NOT. ALLOCATED(model%parts)) THEN
            ierr = -1_i4
            RETURN
        END IF

        ! Find maximum id over all parts
        DO iPart = 1, SIZE(model%parts)
            IF (.NOT. ALLOCATED(model%parts(iPart)%nodes)) CYCLE
            DO iNode = 1, SIZE(model%parts(iPart)%nodes)
                id = model%parts(iPart)%nodes(iNode)%cfg%id
                IF (id > maxNodeId) maxNodeId = id
            END DO
        END DO

        IF (maxNodeId <= 0_i4) THEN
            ierr = -2_i4
            RETURN
        END IF

        IF (use_mem_pool) THEN
            CALL g_core_mem_pool%AllocDP1D('contact_X', maxNodeId, X_ptr, mem_status)
            IF (mem_status%status_code == 0) THEN
                X_from_pool = .TRUE.
                X => X_ptr
            ELSE
                ALLOCATE(X(maxNodeId))
            END IF
        ELSE
            ALLOCATE(X(maxNodeId))
        END IF
        X = 0.0_wp

        IF (use_mem_pool) THEN
            CALL g_core_mem_pool%AllocDP1D('contact_Y', maxNodeId, Y_ptr, mem_status)
            IF (mem_status%status_code == 0) THEN
                Y_from_pool = .TRUE.
                Y => Y_ptr
            ELSE
                ALLOCATE(Y(maxNodeId))
            END IF
        ELSE
            ALLOCATE(Y(maxNodeId))
        END IF
        Y = 0.0_wp

        IF (use_mem_pool) THEN
            CALL g_core_mem_pool%AllocDP1D('contact_Z', maxNodeId, Z_ptr, mem_status)
            IF (mem_status%status_code == 0) THEN
                Z_from_pool = .TRUE.
                Z => Z_ptr
            ELSE
                ALLOCATE(Z(maxNodeId))
            END IF
        ELSE
            ALLOCATE(Z(maxNodeId))
        END IF
        Z = 0.0_wp

        DO iPart = 1, SIZE(model%parts)
            IF (.NOT. ALLOCATED(model%parts(iPart)%nodes)) CYCLE
            DO iNode = 1, SIZE(model%parts(iPart)%nodes)
                id = model%parts(iPart)%nodes(iNode)%cfg%id
                IF (id < 1_i4 .OR. id > maxNodeId) CYCLE
                X(id) = model%parts(iPart)%nodes(iNode)%coords(1)
                Y(id) = model%parts(iPart)%nodes(iNode)%coords(2)
                Z(id) = model%parts(iPart)%nodes(iNode)%coords(3)
            END DO
        END DO

        IF (X_from_pool) DEALLOCATE(X)
        IF (Y_from_pool) DEALLOCATE(Y)
        IF (Z_from_pool) DEALLOCATE(Z)

    END SUBROUTINE Brg_BuildGlobalCoordinates

    SUBROUTINE Brg_BuildGlobalDofMap(dofMap, ierr)
        TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
        INTEGER(i4), INTENT(OUT) :: ierr

        INTEGER(i4) :: nDOF, nNodeArray
        INTEGER(i4) :: id, eqStart, nNodeDof, loc
        INTEGER(i4) :: maxNodeIdLocal

        ierr = 0_i4

        nDOF = dofMap%nTotalEq
        IF (nDOF <= 0_i4) RETURN

        ! Determine maximum id from eqToNode mapping
        maxNodeIdLocal = 0_i4
        IF (ALLOCATED(dofMap%eqToNode)) THEN
            IF (SIZE(dofMap%eqToNode) >= 1) THEN
                maxNodeIdLocal = MAXVAL(dofMap%eqToNode)
            END IF
        END IF

        IF (maxNodeIdLocal <= 0_i4) THEN
            ierr = -1_i4
            RETURN
        END IF

        bridge_max_node = maxNodeIdLocal

        ! Determine ndof for contact: up to 3, but not exceeding nodeNumDof
        bridge_ndof = 3_i4
        IF (ALLOCATED(dofMap%nodeNumDof)) THEN
            IF (SIZE(dofMap%nodeNumDof) > 0) THEN
                bridge_ndof = MIN(3_i4, MAXVAL(dofMap%nodeNumDof))
                IF (bridge_ndof <= 0_i4) bridge_ndof = 3_i4
            END IF
        END IF

        IF (ALLOCATED(bridge_global_d)) DEALLOCATE(bridge_global_d)
        ALLOCATE(bridge_global_d(bridge_ndof, bridge_max_node))
        bridge_global_d = 0_i4

        IF (.NOT. ALLOCATED(dofMap%nodeToEqStart)) RETURN
        IF (.NOT. ALLOCATED(dofMap%nodeNumDof)) RETURN

        nNodeArray = SIZE(dofMap%nodeToEqStart)

        DO id = 1, MIN(bridge_max_node, nNodeArray)
            eqStart = dofMap%nodeToEqStart(id)
            nNodeDof = 0_i4
            IF (eqStart > 0_i4) THEN
                nNodeDof = dofMap%nodeNumDof(id)
            END IF
            DO loc = 1, MIN(bridge_ndof, nNodeDof)
                IF (eqStart <= 0_i4) EXIT
                IF (eqStart + loc - 1_i4 > nDOF) EXIT
                bridge_global_d(loc, id) = eqStart + loc - 1_i4
            END DO
        END DO

    END SUBROUTINE Brg_BuildGlobalDofMap

    SUBROUTINE Brg_CollectSurfaceNodes(part, surfId, nodeIds, nUnique)
        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: surfId
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: nodeIds(:)
        INTEGER(i4), INTENT(OUT) :: nUnique

        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: iFace, id, faceId, elemIdx, nFaceNode
        INTEGER(i4) :: localNodes(9)
        TYPE(UF_ElementType), POINTER :: ElemType
        INTEGER(i4) :: k, nMax

        nUnique = 0_i4

        IF (.NOT. ALLOCATED(part%surfSets)) THEN
            ALLOCATE(nodeIds(1))
            nodeIds(1) = 0_i4
            RETURN
        END IF

        IF (surfId < 1_i4 .OR. surfId > SIZE(part%surfSets)) THEN
            ALLOCATE(nodeIds(1))
            nodeIds(1) = 0_i4
            RETURN
        END IF

        IF (.NOT. ALLOCATED(part%surfSets(surfId)%faces)) THEN
            ALLOCATE(nodeIds(1))
            nodeIds(1) = 0_i4
            RETURN
        END IF

        nMax = SIZE(part%surfSets(surfId)%faces, 2) * 9
        ALLOCATE(tmp(MAX(1_i4, nMax)))

        DO iFace = 1, SIZE(part%surfSets(surfId)%faces, 2)
            id = part%surfSets(surfId)%faces(1, iFace)
            faceId = part%surfSets(surfId)%faces(2, iFace)

            elemIdx = Brg_FindElementIndex(part, id)
            IF (elemIdx < 1_i4) CYCLE

            ElemType => UF_GetElementType(part%elements(elemIdx)%elemTypeId)
            IF (.NOT. ASSOCIATED(ElemType)) CYCLE

            CALL UF_GetFaceLocalNodes(ElemType, faceId, localNodes, nFaceNode)
            IF (nFaceNode < 1_i4) CYCLE

            DO k = 1, nFaceNode
                id = part%elements(elemIdx)%conn(localNodes(k))
                IF (Brg_HasInt(tmp, nUnique, id)) CYCLE
                nUnique = nUnique + 1_i4
                tmp(nUnique) = id
            END DO
        END DO

        ALLOCATE(nodeIds(MAX(1_i4, nUnique)))
        IF (nUnique > 0_i4) nodeIds(1:nUnique) = tmp(1:nUnique)

        DEALLOCATE(tmp)

    END SUBROUTINE Brg_CollectSurfaceNodes

    INTEGER(i4) FUNCTION Brg_FindElementIndex(part, id) RESULT(idx)
        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: id
        INTEGER(i4) :: i

        idx = -1_i4
        IF (.NOT. ALLOCATED(part%elements)) RETURN

        DO i = 1, SIZE(part%elements)
            IF (part%elements(i)%cfg%id == id) THEN
                idx = i
                RETURN
            END IF
        END DO

    END FUNCTION Brg_FindElementIndex

    LOGICAL FUNCTION Brg_HasInt(arr, nUsed, val) RESULT(found)
        INTEGER(i4), INTENT(IN) :: arr(:)
        INTEGER(i4), INTENT(IN) :: nUsed, val
        INTEGER(i4) :: i

        found = .FALSE.
        DO i = 1, nUsed
            IF (arr(i) == val) THEN
                found = .TRUE.
                RETURN
            END IF
        END DO

    END FUNCTION Brg_HasInt

    SUBROUTINE Brg_DecodeGlobalSurfId(model, globalId, partIndex, localSurfId)
        TYPE(UF_Model), INTENT(IN) :: model
        INTEGER(i4), INTENT(IN) :: globalId
        INTEGER(i4), INTENT(OUT) :: partIndex
        INTEGER(i4), INTENT(OUT) :: localSurfId

        INTEGER(i4) :: iPart, offset, nSurf

        partIndex = 0_i4
        localSurfId = 0_i4

        IF (globalId < 1_i4) RETURN

        offset = 0_i4

        ! Part-level region
        IF (ALLOCATED(model%parts)) THEN
            DO iPart = 1, SIZE(model%parts)
                IF (.NOT. ALLOCATED(model%parts(iPart)%surfSets)) CYCLE
                nSurf = SIZE(model%parts(iPart)%surfSets)
                IF (globalId > offset .AND. globalId <= offset + nSurf) THEN
                    partIndex = iPart
                    localSurfId = globalId - offset
                    RETURN
                END IF
                offset = offset + nSurf
            END DO
        END IF

        ! Assembly-level region (partIndex = 0)
        IF (ALLOCATED(model%assembly%surfSets)) THEN
            nSurf = SIZE(model%assembly%surfSets)
            IF (globalId > offset .AND. globalId <= offset + nSurf) THEN
                partIndex = 0_i4
                localSurfId = globalId - offset
                RETURN
            END IF
            offset = offset + nSurf
        END IF

    END SUBROUTINE Brg_DecodeGlobalSurfId

    !> Find global surface ID by name (part-level then assembly-level).
    !> Returns 0 if not found. Used for Domain path (master_surface/slave_surface names).
    INTEGER(i4) FUNCTION Brg_FindGlobalSurfIdByName(model, name) RESULT(globalId)
        TYPE(UF_Model), INTENT(IN) :: model
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: iPart, iSurf, offset, nSurf

        globalId = 0_i4
        offset = 0_i4

        IF (ALLOCATED(model%parts)) THEN
            DO iPart = 1, SIZE(model%parts)
                IF (.NOT. ALLOCATED(model%parts(iPart)%surfSets)) CYCLE
                DO iSurf = 1, SIZE(model%parts(iPart)%surfSets)
                    IF (TRIM(model%parts(iPart)%surfSets(iSurf)%name) == TRIM(name)) THEN
                        globalId = offset + iSurf
                        RETURN
                    END IF
                END DO
                offset = offset + SIZE(model%parts(iPart)%surfSets)
            END DO
        END IF

        IF (ALLOCATED(model%assembly%surfSets)) THEN
            DO iSurf = 1, SIZE(model%assembly%surfSets)
                IF (TRIM(model%assembly%surfSets(iSurf)%name) == TRIM(name)) THEN
                    globalId = offset + iSurf
                    RETURN
                END IF
            END DO
        END IF
    END FUNCTION Brg_FindGlobalSurfIdByName

    SUBROUTINE Brg_Estimate_Eref_FromModel(model)
        TYPE(UF_Model), INTENT(IN) :: model

        INTEGER(i4) :: nMat, iMat, nE
        REAL(wp) :: E, Emax, Esum

        Emax = 0.0_wp
        Esum = 0.0_wp
        nE = 0_i4

        IF (ALLOCATED(model%materialDB%materials)) THEN
            nMat = SIZE(model%materialDB%materials)
            DO iMat = 1, nMat
                IF (.NOT. ALLOCATED(model%materialDB%materials(iMat)%props)) CYCLE
                IF (SIZE(model%materialDB%materials(iMat)%props) < 1) CYCLE

                E = model%materialDB%materials(iMat)%props(1)
                IF (E <= 0.0_wp) CYCLE

                nE = nE + 1_i4
                Esum = Esum + E
                IF (E > Emax) Emax = E
            END DO
        END IF

        IF (nE > 0_i4) THEN
            bridge_E_ref = Emax
        ELSE
            bridge_E_ref = 2.0E11_wp
        END IF

    END SUBROUTINE Brg_Estimate_Eref_FromModel

    SUBROUTINE UF_ContBrg_GetPropForInteract(model, propertyId, mu_s, mu_k, penalty_scale)
        TYPE(UF_Model), INTENT(IN) :: model
        INTEGER(i4), INTENT(IN) :: propertyId
        REAL(wp), INTENT(OUT) :: mu_s, mu_k, penalty_scale

        ! Default: smooth contact, generic penalty scaling
        mu_s = 0.0_wp
        mu_k = 0.0_wp
        penalty_scale = 10.0_wp

        IF (propertyId <= 0_i4) RETURN
        IF (.NOT. ALLOCATED(model%contactProps)) RETURN
        IF (propertyId > SIZE(model%contactProps)) RETURN

        mu_s = model%contactProps(propertyId)%mu_s
        mu_k = model%contactProps(propertyId)%mu_k
        penalty_scale = model%contactProps(propertyId)%penalty_scale

    END SUBROUTINE UF_ContBrg_GetPropForInteract

    !> Get contact property from Domain by name (mu_s, mu_k, penalty_scale).
    !> Used when md_layer%interaction is ready.
    SUBROUTINE Brg_GetPropFromDomain(prop_name, mu_s, mu_k, penalty_scale)
        CHARACTER(LEN=*), INTENT(IN)  :: prop_name
        REAL(wp),        INTENT(OUT) :: mu_s, mu_k, penalty_scale
        TYPE(MD_ContactProperty) :: prop
        LOGICAL :: found
        TYPE(ErrorStatusType) :: status

        mu_s = 0.0_wp
        mu_k = 0.0_wp
        penalty_scale = 10.0_wp

        IF (.NOT. g_ufc_global%IsReady()) RETURN
        IF (.NOT. g_ufc_global%md_layer%interaction%initialized) RETURN

        CALL g_ufc_global%md_layer%interaction%GetProperty( &
            TRIM(prop_name), prop, found, status)
        IF (.NOT. found) RETURN

        mu_s = prop%friction%mu_static
        mu_k = prop%friction%mu_kinetic
        IF (prop%pressure_overclosure%penalty_stiffness > 0.0_wp) THEN
            penalty_scale = prop%pressure_overclosure%penalty_stiffness / 1.0E6_wp
        END IF
    END SUBROUTINE Brg_GetPropFromDomain

    !> Estimate E_ref from md_layer%material (Domain path).
    SUBROUTINE Brg_Estimate_Eref_FromDomain()
        INTEGER(i4) :: i, n
        REAL(wp) :: E, Emax

        Emax = 0.0_wp
        IF (.NOT. g_ufc_global%IsReady()) RETURN
        IF (.NOT. g_ufc_global%md_layer%material%initialized) RETURN
        IF (.NOT. ALLOCATED(g_ufc_global%md_layer%material%desc_array)) RETURN

        n = SIZE(g_ufc_global%md_layer%material%desc_array)
        DO i = 1, n
            IF (.NOT. ALLOCATED(g_ufc_global%md_layer%material%desc_array(i)%props)) CYCLE
            IF (g_ufc_global%md_layer%material%desc_array(i)%pop%nProps < 1) CYCLE
            E = g_ufc_global%md_layer%material%desc_array(i)%props(1)
            IF (E > 0.0_wp .AND. E > Emax) Emax = E
        END DO
        IF (Emax > 0.0_wp) bridge_E_ref = Emax
    END SUBROUTINE Brg_Estimate_Eref_FromDomain

  subroutine UF_ContBrg_IncrInit(nodeStates, dofMap, ierr)
    type(RT_NodeState), intent(in) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in) :: dofMap
    integer(i4),        intent(out):: ierr

    integer(i4) :: nDOF, status
    real(wp), allocatable :: disp(:)

    integer(i4), allocatable :: nodeidtostateid(:)
    integer(i4) :: maxNodeIdLocal
    integer(i4) :: eq, id, locDof, stateIdx
    type(ErrorStatusType) :: mem_status
    logical :: use_mem_pool, disp_from_pool, nodeid_from_poo
    real(wp), pointer :: disp_ptr(:)
    integer(i4), pointer :: nodeid_ptr(:)

    call init_error_status(mem_status)
    use_mem_pool = g_core_mem_pool%initialized
    disp_from_pool = .false.
    nodeid_from_poo = .false.

    ierr = 0_i4

    if (.not. bridge_problem) then
      ! Contact problem has not been built -> nothing to do.
      return
    end if


    nDOF = dofMap%nTotalEq
    if (nDOF <= 0_i4) return

    !------------------------------------------------------------------
    ! 1) Build and cache global DOF mapping (once per analysis)
    !------------------------------------------------------------------
    if (.not. bridge_dofmap_i) then
      call Brg_BuildGlobalDofMap(dofMap, status)
      if (status /= 0_i4) then
        ierr = status
        call log_error('MD_Contact_Brg', 'Brg_BuildGlobalDofMap failed in IncrementInit')
        return
      end if
      bridge_dofmap_i = .true.
    end if

    !------------------------------------------------------------------
    ! 2) Build disp vector disp(:) from nodeStates
    !------------------------------------------------------------------
    if (use_mem_pool) then
      call g_core_mem_pool%AllocDP1D('contact_disp', nDOF, disp_ptr, mem_status)
      if (mem_status%status_code == 0) then
        disp_from_pool = .true.
        disp => disp_ptr
      else
        allocate(disp(nDOF))
      end if
    else
      allocate(disp(nDOF))
    end if
    disp = 0.0_wp

    ! Map id -> nodeStates index for quick lookup

    maxNodeIdLocal = 0_i4
    do stateIdx = 1, size(nodeStates)
      if (nodeStates(stateIdx)%cfg%id > maxNodeIdLocal) &
        maxNodeIdLocal = nodeStates(stateIdx)%cfg%id
    end do

    if (maxNodeIdLocal > 0_i4) then
      if (use_mem_pool) then
        call g_core_mem_pool%AllocInt1D('nodeid_to_state', maxNodeIdLocal, nodeid_ptr, mem_status)
        if (mem_status%status_code == 0) then
          nodeid_from_poo = .true.
          nodeidtostateid => nodeid_ptr
        else
          allocate(nodeidtostateid(maxNodeIdLocal))
        end if
      else
        allocate(nodeidtostateid(maxNodeIdLocal))
      end if
      nodeidtostateid = 0_i4
      do stateIdx = 1, size(nodeStates)
        id = nodeStates(stateIdx)%cfg%id
        if (id >= 1_i4 .and. id <= maxNodeIdLocal) then
          nodeidtostateid(id) = stateIdx
        end if
      end do
    end if

    do eq = 1, nDOF
      if (.not. allocated(dofMap%eqToNode)) exit
      if (.not. allocated(dofMap%eqToLocal)) exit

      id = dofMap%eqToNode(eq)
      locDof = dofMap%eqToLocal(eq)

      if (id <= 0_i4 .or. locDof <= 0_i4) cycle
      if (allocated(nodeidtostateid)) then
        if (id > size(nodeidtostateid)) cycle
        stateIdx = nodeidtostateid(id)
      else
        stateIdx = 0_i4
      end if
      if (stateIdx <= 0_i4) cycle

      if (allocated(nodeStates(stateIdx)%u_curr)) then
        if (size(nodeStates(stateIdx)%u_curr) >= locDof) then
          disp(eq) = nodeStates(stateIdx)%u_curr(locDof)
        end if
      end if
    end do

    if (allocated(nodeidtostateid)) deallocate(nodeidtostateid)

    !------------------------------------------------------------------
    ! 3) Call Contact Manager inc init (global search + penalty setup)
    !------------------------------------------------------------------
    if (bridge_E_ref <= 0.0_wp) bridge_E_ref = 2.0E11_wp

    status = 0_i4
    call contact_increment_init(disp, bridge_global_d, bridge_ndof, bridge_E_ref, status)
    if (status /= 0_i4) then
      if (ierr == 0_i4) ierr = status
    end if

    if (allocated(disp)) deallocate(disp)

  end subroutine UF_ContBrg_IncrInit

  subroutine UF_ContBrg_InitFromMD(model, contact_dim, ierr)
    type(UF_Model), intent(in) :: model
    integer(i4),    intent(in) :: contact_dim   ! 2 / 3 or CONTACT_2D / CONTACT_3D
    integer(i4),    intent(out):: ierr

    integer(i4) :: nSurfaces, nPairs
    integer(i4) :: iPart, iInt
    integer(i4) :: masterId, slaveId
    integer(i4) :: partIndex, localSurfId
    integer(i4) :: status
    integer(i4) :: nInt

    logical, allocatable :: surface_defined(:)
    real(wp), allocatable :: X(:), Y(:), Z(:)
    integer(i4) :: maxNodeId
    type(ErrorStatusType) :: mem_status
    logical :: use_mem_pool, X_from_pool, Y_from_pool, Z_from_pool

    call init_error_status(mem_status)
    use_mem_pool = g_core_mem_pool%initialized
    X_from_pool = .false.
    Y_from_pool = .false.
    Z_from_pool = .false.

    real(wp) :: mu_s, mu_k, penalty_scale
    integer(i4) :: pair_id

    ierr = 0_i4

    ! Cleanup previous contact problem if any
    if (bridge_problem) then
      call contact_Mgr_cleanup()
      bridge_problem = .false.
    end if

    !------------------------------------------------------------------
    ! 1) Count global surfaces (part-level + assembly-level)
    !------------------------------------------------------------------
    nSurfaces = 0_i4

    if (allocated(model%parts)) then
      do iPart = 1, size(model%parts)
        if (allocated(model%parts(iPart)%surfSets)) then
          nSurfaces = nSurfaces + size(model%parts(iPart)%surfSets)
        end if
      end do
    end if

    if (allocated(model%assembly%surfSets)) then
      nSurfaces = nSurfaces + size(model%assembly%surfSets)
    end if

    if (nSurfaces <= 0_i4) then
      ! No surfaces -> nothing to initialize in Contact Manager
      return
    end if

    !------------------------------------------------------------------
    ! 2) Count Surface-to-Surface interactions -> number of contact pairs
    !    Index-tree + flat domain: md_layer%interaction only (legacy model%interactions removed)
    !------------------------------------------------------------------
    if (g_ufc_global%IsReady() .and. g_ufc_global%md_layer%interaction%initialized) then
      nPairs = g_ufc_global%md_layer%interaction%n_pairs
      nInt   = nPairs
    else
      nPairs = 0_i4
      nInt   = 0_i4
      return
    end if

    if (nPairs <= 0_i4) then
      return
    end if

    !------------------------------------------------------------------
    ! 3) Init Contact Manager problem shell
    !------------------------------------------------------------------
    bridge_contact = CONTACT_3D
    if (contact_dim == CONTACT_2D .or. contact_dim == 2_i4) bridge_contact = CONTACT_2D
    if (contact_dim == CONTACT_3D .or. contact_dim == 3_i4) bridge_contact = CONTACT_3D

    call contact_Mgr_init(bridge_contact, nSurfaces, nPairs, status)
    if (status /= 0_i4) then
      ierr = status
      call log_error('MD_Contact_Brg', 'contact_Mgr_init failed in UF_ContBrg_InitFromMD')
      return
    end if

    !------------------------------------------------------------------
    ! 4) Build global coordinate arrays X/Y/Z indexed by id
    !    Index-tree + flat domain: prefer md_layer%mesh when ready
    !------------------------------------------------------------------
    if (g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized) then
      call Brg_BuildGlobalCoordinates_FromMesh(X, Y, Z, maxNodeId, status)
    else
      call Brg_BuildGlobalCoordinates(model, X, Y, Z, maxNodeId, status)
    end if
    if (status /= 0_i4) then
      ierr = status
      call log_error('MD_Contact_Brg', 'Brg_BuildGlobalCoordinates failed in UF_ContBrg_InitFromMD')
      return
    end if

    !------------------------------------------------------------------
    ! 5) Create contact surfaces for all part-level surfaces that
    !    actually participate in interactions. Assembly-level surfaces
    !    are left uninitialized (n_nodes=0) and effectively inactive.
    !------------------------------------------------------------------
    allocate(surface_defined(nSurfaces))
    surface_defined(:) = .false.

    ! Domain path only: iterate pairs from md_layer%interaction (legacy removed)
    if (g_ufc_global%IsReady() .and. g_ufc_global%md_layer%interaction%initialized) then
      do iInt = 1, nInt
        if (iInt > g_ufc_global%md_layer%interaction%n_pairs) exit
        masterId = Brg_FindGlobalSurfIdByName(model, &
          trim(g_ufc_global%md_layer%interaction%pairs(iInt)%master_surface))
        slaveId  = Brg_FindGlobalSurfIdByName(model, &
          trim(g_ufc_global%md_layer%interaction%pairs(iInt)%slave_surface))
        if (masterId < 1_i4 .or. slaveId < 1_i4) cycle

        if (.not. surface_defined(masterId)) then
          call Brg_DecodeGlobalSurfId(model, masterId, partIndex, localSurfId)
          if (partIndex > 0_i4 .and. localSurfId > 0_i4) then
            call Brg_AddSurfaceFromPart(model%parts(partIndex), localSurfId, masterId, &
                                           X, Y, Z, bridge_contact, status)
            if (status == 0_i4) surface_defined(masterId) = .true.
          end if
        end if
        if (.not. surface_defined(slaveId)) then
          call Brg_DecodeGlobalSurfId(model, slaveId, partIndex, localSurfId)
          if (partIndex > 0_i4 .and. localSurfId > 0_i4) then
            call Brg_AddSurfaceFromPart(model%parts(partIndex), localSurfId, slaveId, &
                                           X, Y, Z, bridge_contact, status)
            if (status == 0_i4) surface_defined(slaveId) = .true.
          end if
        end if
      end do
    end if

    if (allocated(surface_defined)) deallocate(surface_defined)
    if (allocated(X)) deallocate(X)
    if (allocated(Y)) deallocate(Y)
    if (allocated(Z)) deallocate(Z)

    !------------------------------------------------------------------
    ! 6) Create contact pairs, using propertyId -> (mu_s, mu_k, penalty_scale)
    !    Domain path: GetProperty(prop_name); legacy: UF_ContBrg_GetPropForInteract
    !------------------------------------------------------------------
    pair_id = 0_i4

    ! Domain path only: create pairs from md_layer%interaction (legacy removed)
    if (g_ufc_global%IsReady() .and. g_ufc_global%md_layer%interaction%initialized) then
      do iInt = 1, nInt
        if (iInt > g_ufc_global%md_layer%interaction%n_pairs) exit
        masterId = Brg_FindGlobalSurfIdByName(model, &
          trim(g_ufc_global%md_layer%interaction%pairs(iInt)%master_surface))
        slaveId  = Brg_FindGlobalSurfIdByName(model, &
          trim(g_ufc_global%md_layer%interaction%pairs(iInt)%slave_surface))
        if (masterId < 1_i4 .or. slaveId < 1_i4) cycle

        pair_id = pair_id + 1_i4
        mu_s = 0.0_wp
        mu_k = 0.0_wp
        penalty_scale = 10.0_wp
        if (len_trim(g_ufc_global%md_layer%interaction%pairs(iInt)%prop_name) > 0) then
          call Brg_GetPropFromDomain( &
            trim(g_ufc_global%md_layer%interaction%pairs(iInt)%prop_name), &
            mu_s, mu_k, penalty_scale)
        end if

        status = 0_i4
        call contact_add_pair(pair_id, masterId, slaveId, &
                              mu_static=mu_s, mu_kinetic=mu_k, &
                              penalty_scale=penalty_scale, ierr=status)
        if (status /= 0_i4 .and. ierr == 0_i4) ierr = status
      end do
    end if

    !------------------------------------------------------------------
    ! 7) Estimate reference modulus E_ref from model materials
    !    Domain path: md_layer%material; legacy: model%materialDB
    !------------------------------------------------------------------
    if (g_ufc_global%IsReady() .and. g_ufc_global%md_layer%material%initialized) then
      call Brg_Estimate_Eref_FromDomain()
    else
      call Brg_Estimate_Eref_FromModel(model)
    end if

    bridge_problem = .true.
    bridge_dofmap_i  = .false.
    ! bridge_max_node is determined later when DOF map is built

  end subroutine UF_ContBrg_InitFromMD

  subroutine UF_ContBrg_IterationInit(nodeStates, dofMap, ierr)
    type(RT_NodeState), intent(in) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in) :: dofMap
    integer(i4),        intent(out):: ierr

    integer(i4) :: nDOF
    real(wp), allocatable :: disp(:)

    integer(i4), allocatable :: nodeidtostateid(:)
    integer(i4) :: maxNodeIdLocal
    integer(i4) :: eq, id, locDof, stateIdx
    type(ErrorStatusType) :: mem_status
    logical :: use_mem_pool, disp_from_pool, nodeid_from_poo
    real(wp), pointer :: disp_ptr(:)
    integer(i4), pointer :: nodeid_ptr(:)

    call init_error_status(mem_status)
    use_mem_pool = g_core_mem_pool%initialized
    disp_from_pool = .false.
    nodeid_from_poo = .false.

    ierr = 0_i4

    if (.not. bridge_problem) return

    nDOF = dofMap%nTotalEq
    if (nDOF <= 0_i4) return

    ! Ensure DOF mapping is available (should already be built in IncrementInit)
    if (.not. bridge_dofmap_i) then
      call Brg_BuildGlobalDofMap(dofMap, ierr)
      if (ierr /= 0_i4) then
        call log_error('MD_Contact_Brg', 'Brg_BuildGlobalDofMap failed in IterationInit')
        return
      end if
      bridge_dofmap_i = .true.
    end if

    allocate(disp(nDOF))
    disp = 0.0_wp

    ! Map id -> nodeStates index

    maxNodeIdLocal = 0_i4
    do stateIdx = 1, size(nodeStates)
      if (nodeStates(stateIdx)%cfg%id > maxNodeIdLocal) &
        maxNodeIdLocal = nodeStates(stateIdx)%cfg%id
    end do

    if (maxNodeIdLocal > 0_i4) then
      if (use_mem_pool) then
        call g_core_mem_pool%AllocInt1D('nodeid_to_state', maxNodeIdLocal, nodeid_ptr, mem_status)
        if (mem_status%status_code == 0) then
          nodeid_from_poo = .true.
          nodeidtostateid => nodeid_ptr
        else
          allocate(nodeidtostateid(maxNodeIdLocal))
        end if
      else
        allocate(nodeidtostateid(maxNodeIdLocal))
      end if
      nodeidtostateid = 0_i4
      do stateIdx = 1, size(nodeStates)
        id = nodeStates(stateIdx)%cfg%id
        if (id >= 1_i4 .and. id <= maxNodeIdLocal) then
          nodeidtostateid(id) = stateIdx
        end if
      end do
    end if

    do eq = 1, nDOF
      if (.not. allocated(dofMap%eqToNode)) exit
      if (.not. allocated(dofMap%eqToLocal)) exit

      id = dofMap%eqToNode(eq)
      locDof = dofMap%eqToLocal(eq)

      if (id <= 0_i4 .or. locDof <= 0_i4) cycle
      if (allocated(nodeidtostateid)) then
        if (id > size(nodeidtostateid)) cycle
        stateIdx = nodeidtostateid(id)
      else
        stateIdx = 0_i4
      end if
      if (stateIdx <= 0_i4) cycle

      if (allocated(nodeStates(stateIdx)%u_curr)) then
        if (size(nodeStates(stateIdx)%u_curr) >= locDof) then
          disp(eq) = nodeStates(stateIdx)%u_curr(locDof)
        end if
      end if
    end do

    if (allocated(nodeidtostateid)) deallocate(nodeidtostateid)

    call contact_iteration_init(disp, bridge_global_d, bridge_ndof)

    if (allocated(disp)) deallocate(disp)

  end subroutine UF_ContBrg_IterationInit
END MODULE MD_Int_Brg
