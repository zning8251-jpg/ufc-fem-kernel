!======================================================================
! MODULE:  MD_Int_Mgr
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Mgr
! BRIEF:   Contact manager - lifecycle management for contact
!          problems. Init, surface/pair addition, DOF mapping,
!          geometry update, global search, increment/iteration
!          init, force/stiffness assembly, state update.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
!   manager pattern for lifecycle management.
!
! Logic chain:
!   Initialization: contact_Mgr_init -> Validate dimensions -> Allocate surfaces/pairs ->
!   Set global enforcement method -> Mark initialized. Surface addition: contact_add_surface ->
!   Validate surface ID -> Initialize surface -> Add nodes -> Build segments -> Compute bbox ->
!   Build topology. Pair addition: contact_add_pair -> Validate pair ID -> Set master/slave
!   surfaces -> Set contact type/enforcement -> Set penalty/friction parameters -> Initialize
!   active pair. DOF mapping: contact_setup_dof_mapping -> Loop surfaces -> Allocate DOF map ->
!   Fill DOF map from global DOF mapping. Geometry update: contact_update_geometry -> Loop
!   surfaces -> Update coordinates from displacement vector. Global search: contact_global_search ->
!   Initialize search -> Find candidates -> Update active pair. Increment init:
!   contact_increment_init -> Setup DOF mapping -> Update geometry -> Global search for all pairs.
!   Iteration init: contact_iteration_init -> Update geometry. Force/stiffness assembly:
!   contact_Assem_csr -> Loop contact points -> Compute local stiffness/force -> Assemble to CSR.
!   Assembly with damping: contact_assemble_csr_with_damping -> Compute damping forces -> Add to
!   assembly. State update: contact_update_state -> Loop contact points -> Update state based on gap.
!   Statistics: contact_get_Stats -> Loop contact points -> Compute total force/max penetration.
!   Cleanup: contact_Mgr_cleanup -> Deallocate surfaces/pairs -> Mark uninitialized. Dependency:
!   L3_MD Contact Mgr -> L1 IF (Precision), L3_MD (Contact Core), L4_PH (Contact evaluation),
!   L5_RT (Contact state).
!
! Computation chain:
!   Init: Validate dim (2/3), n_surfaces, n_pairs -> Allocate surfaces(n_surfaces) ->
!   Allocate pairs(n_pairs), active_pairs(n_pairs) -> Set global_enforcem = ENFORCE_PENALTY ->
!   Mark init = TRUE. Add surface: Validate surf_id -> Initialize surface (id, n_nodes, n_segs,
!   is_master, coord_type) -> Add nodes (node_ids, X, Y, Z) -> Build segments (2D: n_nodes-1,
!   3D: n_nodes/4) -> Compute bbox -> Build topology. Add pair: Validate pair_id -> Set
!   master_surface, slave_surface_i -> Set contact_type (default CONTACT_NODE_TO) -> Set
!   enforcement_met (default ENFORCE_PENALTY) -> Set penalty_normal, penalty_tangent ->
!   Set friction (mu_static, mu_kinetic) -> Set penalty_scale -> Set active = TRUE ->
!   Initialize active pair from pair definition. Setup DOF mapping: Loop surfaces -> Allocate
!   dof_map(ndof, n_nodes) -> Fill dof_map(i_dof, i_node) = dof_map(i_dof, node_ids(i_node)).
!   Update geometry: Loop surfaces -> Update coords from disp via dof_map. Global search:
!   Initialize search (master surface, slave surface, pair) -> Find candidates -> Update
!   active pair with candidates. Increment init: Setup DOF mapping -> Update geometry ->
!   Global search for all pairs. Iteration init: Update geometry. Assemble CSR: Loop contact
!   points -> If gap < 0: Compute local stiffness K_local(6,6), force F_local(6) ->
!   Get DOF indices (slave 3 DOFs, master 3 DOFs) -> Assemble K_local to CSR -> Add F_local
!   to RHS. Assemble with damping: Assemble CSR -> Compute velocity components -> Compute
!   damping forces (normal, tangential) -> Add damping forces to RHS. Update state: Loop
!   contact points -> If gap < 0: Set state = CSTATE_STICKING, pressure = penalty * (-gap) ->
!   Else: Set state = CSTATE_SEPARATE, pressure = 0. Get statistics: Loop contact points ->
!   If gap < 0: Accumulate total_force += pressure, max_pen = MAX(max_pen, -gap), n_active++.
!   Cleanup: Deallocate surfaces, pairs, active_pairs -> Set init = FALSE.
!
! Data chain:
!   Input: dim (contact dimension 2/3), n_surfaces, n_pairs, surf_id, node_ids, X/Y/Z
!   (coordinates), is_master, coord_type, pair_id, master_surf_id, slave_surf_id,
!   contact_type, enforcement_met, penalty_n, penalty_t, mu_static, mu_kinetic,
!   penalty_scale, dof_map (global DOF mapping), ndof, disp (displacement vector),
!   E_ref (reference modulus), row_ptr/col_idx/values (CSR format), rhs (right-hand side),
!   velocity (velocity vector), damping_ratio, mass. Output: Updated global_contact state
!   (surfaces, pairs, active_pairs), ierr (error status), total_force, max_pen, n_active
!   (statistics), updated CSR values and RHS. State: UF_ContProblem state (contact_dim,
!   n_surfaces, n_pairs, global_enforcem, surfaces, pairs, active_pairs, total_contact_f,
!   max_penetration, n_active_contac), init flag (initialization status), global_contact
!   (module-level contact problem storage).
!
! Data structure:
!   Container path: Contact (contact manager).
!   - Desc: ContPairDef (contact pair definition with master/slave surfaces, contact type,
!   enforcement method, penalty parameters, friction parameters) - stored in global_contact%pairs.
!   - Algo: Global enforcement method (ENFORCE_PENALTY, ENFORCE_LAGRANG, ENFORCE_AUG_LAG,
!   ENFORCE_DIRECT), contact search algorithms (via MD_Contact_Core), force/stiffness assembly
!   algorithms, damping algorithms.
!   - Ctx: UF_ContProblem (contact problem context aggregating surfaces, pairs, active pairs,
!   enforcement method, statistics), global_contact (module-level context storage).
!   - State: ContSurface state (surfaces with nodes, segments, coordinates, DOF mapping),
!   ContPair state (active pairs with contact nodes, gaps, normals, forces, states), contact
!   problem statistics (total force, max penetration, n_active). Supporting types: ContSurface,
!   ContPairDef, ContPair, ContCandidate (from MD_Contact_Core).
!
! Three-step mapping:
!   Contact initialization: Step level (initialize contact manager, add surfaces and pairs).
!   DOF mapping setup: Step level (setup DOF mapping for contact surfaces).
!   Geometry/search/assembly: Increment/iteration level (update geometry, search, assemble forces/stiffness).
!
! Contents (A-Z):
!   Functions: (None - all subroutines)
!   Subroutines: contact_add_pair, contact_add_surface, contact_Assem_csr,
!     contact_assemble_csr_with_damping, contact_get_Stats, contact_global_search,
!     contact_increment_init, contact_iteration_init, contact_Mgr_cleanup,
!     contact_Mgr_init, contact_set_damping, contact_set_method,
!     contact_setup_dof_mapping, contact_update_geometry, contact_update_state
!   Types: UF_ContProblem
!
! Notes:
!   Unified contact manager: Provides unified interface for contact problem lifecycle management.
!   Module-level storage: Uses module-level global_contact for problem state. Initialization check:
!   All procedures check init flag before operations. Error handling: Optional ierr parameter for
!   error reporting. CSR assembly: Assembles contact stiffness/forces to CSR format for global
!   system. Damping support: Supports velocity-based damping with normal and tangential components.
!   Statistics: Provides contact statistics (total force, max penetration, active contact count).
!   Integration: Integrates with MD_Contact_Core for core contact functionality. Logic/Computation
!   chain diagrams: see MD_Cont_Mgr_Chains.md
!
! Status: PROD | Last verified: 2026-03-02
! Status: Draft
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Cont | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Interaction/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Cont | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Int_Mgr
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg,            ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
    USE MD_Int_API, ONLY: ENFORCE_PENALTY, ENFORCE_LAGRANG, ENFORCE_AUG_LAG, ENFORCE_DIRECT, &
                           ContSurface, ContPairDef, ContPair, ContCandidate, FrictionParams, &
                           CONTACT_2D, CONTACT_NODE_TO, COORD_3D_GENERA, &
                           CSTATE_STICKING, CSTATE_SEPARATE, &
                           Cont_Surface_init, Cont_Surface_add_nodes, &
                           Cont_Surface_build_segments_2d, Cont_Surface_build_segments_3d, &
                           Cont_Surface_Compute_bbox, Cont_Surface_build_topology, &
                           Cont_Surface_update_coords, &
                           Cont_Search_global_init, Cont_Search_find_candidates, &
                           Cont_Compute_stif_local_3d, Cont_Friction_contact_damping, &
                           contact_init_from_pair, md_cont_assemble_stif_csr
    USE MD_Int_Def, ONLY: MD_ContactCtrl_Type, MD_ContactPair_Type, MD_ContactProperty_Type, &
                          MD_ContactCtrl_Init, MD_ContactCtrl_AddPair, MD_ContactCtrl_AddProperty
    USE MD_Cont_Mgr, ONLY: MD_ContactPairDef, MD_ContactProperty, CONT_FORM_SURFACE
    USE UFC_GlobalContainer_Core,   ONLY: g_ufc_global
    USE MD_Step_Mgr,        ONLY: MD_Step_Domain
    IMPLICIT NONE
    PRIVATE

    !===========================================================================
    ! Contact Problem Type
    !===========================================================================

    TYPE, PUBLIC :: UF_ContProblem
        INTEGER(i4) :: contact_dim = 3
        INTEGER(i4) :: n_surfaces = 0
        INTEGER(i4) :: n_pairs = 0
        INTEGER(i4) :: global_enforcem = ENFORCE_PENALTY

        TYPE(ContSurface), ALLOCATABLE :: surfaces(:)
        TYPE(ContPairDef), ALLOCATABLE :: pairs(:)
        TYPE(ContPair), ALLOCATABLE :: active_pairs(:)

        REAL(wp) :: total_contact_f = 0.0_wp
        REAL(wp) :: max_penetration = 0.0_wp
        INTEGER(i4) :: n_active_contac = 0
    END TYPE UF_ContProblem

    !===========================================================================
    ! PUBLIC interfaces (A-Z)
    !===========================================================================

    PUBLIC :: contact_add_pair, contact_add_surface, contact_Assem_csr
    PUBLIC :: contact_assemble_csr_with_damping, contact_get_Stats
    PUBLIC :: contact_global_search, contact_increment_init
    PUBLIC :: contact_iteration_init, contact_Mgr_cleanup, contact_Mgr_init
    PUBLIC :: contact_set_damping, contact_set_method, contact_setup_dof_mapping
    PUBLIC :: contact_update_geometry, contact_update_state
    ! Merged from MD_Interaction_DefMgr
    PUBLIC :: MD_Contact_Mgr_FindProperty, MD_Contact_Mgr_Init
    PUBLIC :: MD_Contact_Mgr_RegisterPair, MD_Contact_Mgr_RegisterProperty
    PUBLIC :: MD_Contact_Mgr_ValidateAll

    !===========================================================================
    ! Module-level storage
    !===========================================================================

    TYPE(UF_ContProblem), SAVE, TARGET :: global_contact
    LOGICAL, SAVE :: init = .FALSE.

CONTAINS

    !===========================================================================
    ! Functions merged from MD_Interaction_DefMgr
    !===========================================================================

    !> Purpose: Find contact property by name (merged from MD_Interaction_DefMgr)
    SUBROUTINE MD_Contact_Mgr_FindProperty(ctrl, property_name, property, found)
        TYPE(MD_ContactCtrl_Type), INTENT(IN) :: ctrl
        CHARACTER(len=*), INTENT(IN) :: property_name
        TYPE(MD_ContactProperty_Type), INTENT(OUT) :: property
        LOGICAL, INTENT(OUT) :: found

        INTEGER(i4) :: i

        found = .FALSE.

        DO i = 1, ctrl%nProperties
            IF (TRIM(ctrl%properties(i)%name) == TRIM(property_name)) THEN
                property = ctrl%properties(i)
                found = .TRUE.
                RETURN
            END IF
        END DO

    END SUBROUTINE MD_Contact_Mgr_FindProperty

    !> Purpose: Initialize contact control (merged from MD_Interaction_DefMgr)
    !! Inline: directly call MD_ContactCtrl_Init
    SUBROUTINE MD_Contact_Mgr_Init(ctrl)
        TYPE(MD_ContactCtrl_Type), INTENT(INOUT) :: ctrl

        CALL MD_ContactCtrl_Init(ctrl)

    END SUBROUTINE MD_Contact_Mgr_Init

    !> Purpose: Register contact pair with validation (merged from MD_Interaction_DefMgr)
    SUBROUTINE MD_Contact_Mgr_RegisterPair(ctrl, pair, success, error_msg)
        TYPE(MD_ContactCtrl_Type), INTENT(INOUT) :: ctrl
        TYPE(MD_ContactPair_Type), INTENT(IN) :: pair
        LOGICAL, INTENT(OUT) :: success
        CHARACTER(len=*), INTENT(OUT) :: error_msg

        INTEGER(i4) :: i

        success = .TRUE.
        error_msg = ""

        ! Validate contact pair
        IF (pair%cfg%id <= 0) THEN
            success = .FALSE.
            error_msg = "Contact pair ID must be positive"
            RETURN
        END IF

        IF (LEN_TRIM(pair%name) == 0) THEN
            success = .FALSE.
            error_msg = "Contact pair name cannot be empty"
            RETURN
        END IF

        IF (LEN_TRIM(pair%masterSurface%name) == 0) THEN
            success = .FALSE.
            error_msg = "Master surface name cannot be empty"
            RETURN
        END IF

        IF (LEN_TRIM(pair%slaveSurface%name) == 0) THEN
            success = .FALSE.
            error_msg = "Slave surface name cannot be empty"
            RETURN
        END IF

        ! Check ID uniqueness
        DO i = 1, ctrl%nPairs
            IF (ctrl%pairs(i)%cfg%id == pair%cfg%id) THEN
                success = .FALSE.
                error_msg = "Contact pair ID already exists"
                RETURN
            END IF
        END DO

        ! Delegate to md_layer%interaction when IsReady (INTERACTION_DOMAIN_DESIGN §Phase C)
        IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%interaction%initialized) THEN
            BLOCK
                TYPE(MD_ContactPairDef) :: pair_def
                TYPE(ErrorStatusType) :: st
                pair_def%master_surface = pair%masterSurface%name
                pair_def%slave_surface  = pair%slaveSurface%name
                pair_def%prop_name      = pair%propertyName
                pair_def%pair_id        = pair%cfg%id
                pair_def%formulation    = CONT_FORM_SURFACE
                pair_def%small_sliding  = pair%small_sliding
                pair_def%active_in_all_steps = (pair%stepId <= 0_i4)
                CALL g_ufc_global%md_layer%interaction%AddPair(pair_def, st)
                IF (st%status_code == IF_STATUS_OK .AND. pair%stepId > 0_i4) THEN
                    CALL g_ufc_global%md_layer%step%AddPairId(pair%stepId, &
                        g_ufc_global%md_layer%interaction%n_pairs, st)
                END IF
            END BLOCK
        END IF

        ! Inline: directly call MD_ContactCtrl_AddPair (legacy ctrl)
        CALL MD_ContactCtrl_AddPair(ctrl, pair)

    END SUBROUTINE MD_Contact_Mgr_RegisterPair

    !> Purpose: Register contact property with validation (merged from MD_Interaction_DefMgr)
    SUBROUTINE MD_Contact_Mgr_RegisterProperty(ctrl, property, success, error_msg)
        TYPE(MD_ContactCtrl_Type), INTENT(INOUT) :: ctrl
        TYPE(MD_ContactProperty_Type), INTENT(IN) :: property
        LOGICAL, INTENT(OUT) :: success
        CHARACTER(len=*), INTENT(OUT) :: error_msg

        INTEGER(i4) :: i

        success = .TRUE.
        error_msg = ""

        ! Validate contact property
        IF (property%cfg%id <= 0) THEN
            success = .FALSE.
            error_msg = "Contact property ID must be positive"
            RETURN
        END IF

        IF (LEN_TRIM(property%name) == 0) THEN
            success = .FALSE.
            error_msg = "Contact property name cannot be empty"
            RETURN
        END IF

        IF (property%penalty_stiffness <= 0.0_wp) THEN
            success = .FALSE.
            error_msg = "Penalty stiffness must be positive"
            RETURN
        END IF

        ! Check ID uniqueness
        DO i = 1, ctrl%nProperties
            IF (ctrl%properties(i)%cfg%id == property%cfg%id) THEN
                success = .FALSE.
                error_msg = "Contact property ID already exists"
                RETURN
            END IF
        END DO

        ! Delegate to md_layer%interaction when IsReady (INTERACTION_DOMAIN_DESIGN §Phase C)
        IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%interaction%initialized) THEN
            BLOCK
                TYPE(MD_ContactProperty) :: prop_desc
                TYPE(ErrorStatusType) :: st
                prop_desc%name = property%name
                prop_desc%friction%mu_static  = property%friction%mu_static
                prop_desc%friction%mu_kinetic = property%friction%mu_kinetic
                prop_desc%has_friction = (property%friction%mu_static > 0.0_wp .OR. &
                                          property%friction%mu_kinetic > 0.0_wp)
                prop_desc%pressure_overclosure%penalty_stiffness = property%penalty_stiffness
                CALL g_ufc_global%md_layer%interaction%AddProperty(prop_desc, st)
            END BLOCK
        END IF

        ! Inline: directly call MD_ContactCtrl_AddProperty (legacy ctrl)
        CALL MD_ContactCtrl_AddProperty(ctrl, property)

    END SUBROUTINE MD_Contact_Mgr_RegisterProperty

    !> Purpose: Validate all contact definitions (merged from MD_Interaction_DefMgr)
    SUBROUTINE MD_Contact_Mgr_ValidateAll(ctrl, is_valid, nErrors)
        TYPE(MD_ContactCtrl_Type), INTENT(IN) :: ctrl
        LOGICAL, INTENT(OUT) :: is_valid
        INTEGER(i4), INTENT(OUT) :: nErrors

        INTEGER(i4) :: i
        LOGICAL :: property_found
        TYPE(MD_ContactProperty_Type) :: prop

        is_valid = .TRUE.
        nErrors = 0_i4

        ! Validate contact pairs
        DO i = 1, ctrl%nPairs
            ! Check whether contact pair references valid property
            IF (LEN_TRIM(ctrl%pairs(i)%propertyName) > 0) THEN
                CALL MD_Contact_Mgr_FindProperty(ctrl, ctrl%pairs(i)%propertyName, prop, property_found)
                IF (.NOT. property_found) THEN
                    nErrors = nErrors + 1_i4
                END IF
            END IF
        END DO

        ! Validate contact properties
        DO i = 1, ctrl%nProperties
            IF (ctrl%properties(i)%penalty_stiffness <= 0.0_wp) THEN
                nErrors = nErrors + 1_i4
            END IF
        END DO

        IF (nErrors > 0_i4) is_valid = .FALSE.

    END SUBROUTINE MD_Contact_Mgr_ValidateAll

    !===========================================================================
    ! Original contact manager functions
    !===========================================================================

    !===========================================================================
    ! Subroutine Index (Alphabetical Order A-Z)
    !===========================================================================

    ! contact_set_damping - Process contact set damping
    ! contact_update_state - Process contact update state
    ! contact_assemble_csr_with_damping - Process contact assemble csr with damping
    ! contact_get_Stats - Process contact get Stats
    ! contact_iteration_init - Initialize contact iteration
    ! contact_increment_init - Initialize contact increment
    ! contact_setup_dof_mapping - Process contact setup dof mapping
    ! contact_Assem_csr - Process contact Assem csr
    ! contact_set_method - Process contact set method
    ! contact_Mgr_cleanup - Cleanup contact Mgr
    ! contact_Mgr_init - Initialize contact Mgr
    ! contact_add_surface - Process contact add surface
    ! contact_update_geometry - Process contact update geometry
    ! contact_global_search - Process contact global search
    ! contact_add_pair - Process contact add pair

    !===========================================================================

    !> Purpose: Process contact set damping
    SUBROUTINE contact_set_damping(pair_id, damping_ratio, mass, ierr)
        INTEGER(i4), INTENT(IN) :: pair_id
        REAL(wp), INTENT(IN) :: damping_ratio
        REAL(wp), INTENT(IN) :: mass
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        TYPE(FrictionParams) :: fric_params
        REAL(wp) :: k_n, k_t, c_crit_n, c_crit_t

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        IF (pair_id < 1 .OR. pair_id > global_contact%n_pairs) THEN
            IF (PRESENT(ierr)) ierr = -2
            RETURN
        END IF

        fric_params = global_contact%pairs(pair_id)%definition%friction
        fric_params%damping_ratio = damping_ratio

        IF (damping_ratio > 0.0_wp .AND. mass > 0.0_wp) THEN
            k_n = global_contact%pairs(pair_id)%penalty_normal
            k_t = global_contact%pairs(pair_id)%penalty_tangent

            c_crit_n = 2.0_wp * SQRT(mass * k_n)
            c_crit_t = 2.0_wp * SQRT(mass * k_t)

            fric_params%damping_n = damping_ratio * c_crit_n
            fric_params%damping_t = damping_ratio * c_crit_t
        ELSE
            fric_params%damping_n = 0.0_wp
            fric_params%damping_t = 0.0_wp
        END IF

        global_contact%pairs(pair_id)%definition%friction = fric_params
    END SUBROUTINE contact_set_damping

    !> Purpose: Process contact update state
    SUBROUTINE contact_update_state(pair_id, ierr)
        INTEGER(i4), INTENT(IN) :: pair_id
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        TYPE(ContPair) :: cpair
        INTEGER(i4) :: i

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        cpair = global_contact%active_pairs(pair_id)

        DO i = 1, cpair%n_contact_point
            IF (cpair%gaps(i) < 0.0_wp) THEN
                cpair%contact_state(i) = CSTATE_STICKING
                cpair%contact_pressur(i) = &
                    global_contact%pairs(pair_id)%penalty_normal * (-cpair%gaps(i))
            ELSE
                cpair%contact_state(i) = CSTATE_SEPARATE
                cpair%contact_pressur(i) = 0.0_wp
            END IF
        END DO

        global_contact%active_pairs(pair_id) = cpair
    END SUBROUTINE contact_update_state

    !> Purpose: Process contact assemble csr with damping
    SUBROUTINE co_as_csr_w_damping(pair_id, row_ptr, col_idx, values, rhs, &
                                                velocity, dof_map, ndof, ierr)
        INTEGER(i4), INTENT(IN) :: pair_id
        INTEGER(i4), INTENT(IN) :: row_ptr(:)
        INTEGER(i4), INTENT(IN) :: col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:)
        REAL(wp), INTENT(INOUT) :: rhs(:)
        REAL(wp), INTENT(IN) :: velocity(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        TYPE(ContPair) :: cpair
        TYPE(ContSurface) :: master_surf, slave_surf
        TYPE(FrictionParams) :: fric_params
        REAL(wp) :: K_local(6,6), F_local(6)
        REAL(wp) :: F_damp_n, F_damp_t(3)
        REAL(wp) :: v_normal, v_tangent(3)
        REAL(wp) :: v_slave(3), v_master(3)
        INTEGER(i4) :: dof_indices(6)
        INTEGER(i4) :: i, j, n_contact
        INTEGER(i4) :: status
        INTEGER(i4) :: slave_node_id, master_node_id
        REAL(wp) :: c_n, c_t

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        IF (.NOT. global_contact%pairs(pair_id)%active) THEN
            RETURN
        END IF

        cpair = global_contact%active_pairs(pair_id)
        master_surf = global_contact%surfaces(global_contact%pairs(pair_id)%master_surface)
        slave_surf = global_contact%surfaces(global_contact%pairs(pair_id)%slave_surface_i)
        fric_params = global_contact%pairs(pair_id)%definition%friction

        n_contact = cpair%n_contact_point

        IF (fric_params%damping_ratio > 0.0_wp) THEN
            c_n = fric_params%damping_n
            c_t = fric_params%damping_t
        ELSE
            c_n = 0.0_wp
            c_t = 0.0_wp
        END IF

        DO i = 1, n_contact
            IF (cpair%gaps(i) < 0.0_wp) THEN
                CALL Cont_Compute_stif_local_3d( &
                    global_contact%pairs(pair_id)%penalty_normal, &
                    global_contact%pairs(pair_id)%penalty_tangent, &
                    cpair%normals(:, i), &
                    cpair%tangents(:, i), &
                    [0.0_wp, 0.0_wp, 0.0_wp], &
                    -cpair%gaps(i), K_local, F_local)

                DOF_indices(1:3) = [slave_surf%dof_map(1, cpair%contact_nodes(i)), &
                                       slave_surf%dof_map(2, cpair%contact_nodes(i)), &
                                       slave_surf%dof_map(3, cpair%contact_nodes(i))]
                
                IF (cpair%master_elements(i) > 0 .AND. cpair%master_elements(i) <= master_surf%n_segments) THEN
                    DOF_indices(4:6) = [master_surf%dof_map(1, master_surf%segments(cpair%master_elements(i))%nodes(1)), &
                                           master_surf%dof_map(2, master_surf%segments(cpair%master_elements(i))%nodes(1)), &
                                           master_surf%dof_map(3, master_surf%segments(cpair%master_elements(i))%nodes(1))]
                ELSE
                    DOF_indices(4:6) = [0, 0, 0]
                END IF

                CALL md_cont_assemble_stif_csr(K_local, dof_indices, row_ptr, col_idx, values)

                DO j = 1, 6
                    IF (dof_indices(j) > 0 .AND. dof_indices(j) <= SIZE(rhs)) THEN
                        rhs(dof_indices(j)) = rhs(dof_indices(j)) - F_local(j)
                    END IF
                END DO

                IF (c_n > 0.0_wp .OR. c_t > 0.0_wp) THEN
                    slave_node_id = cpair%contact_nodes(i)
                    IF (slave_node_id > 0 .AND. slave_node_id <= SIZE(slave_surf%node_ids)) THEN
                        v_slave = 0.0_wp
                        IF (dof_map(1, slave_node_id) > 0 .AND. dof_map(1, slave_node_id) <= SIZE(velocity)) THEN
                            v_slave(1) = velocity(dof_map(1, slave_node_id))
                        END IF
                        IF (dof_map(2, slave_node_id) > 0 .AND. dof_map(2, slave_node_id) <= SIZE(velocity)) THEN
                            v_slave(2) = velocity(dof_map(2, slave_node_id))
                        END IF
                        IF (dof_map(3, slave_node_id) > 0 .AND. dof_map(3, slave_node_id) <= SIZE(velocity)) THEN
                            v_slave(3) = velocity(dof_map(3, slave_node_id))
                        END IF

                        v_normal = SUM(v_slave * cpair%normals(:, i))
                        v_tangent = v_slave - v_normal * cpair%normals(:, i)

                        CALL Cont_Friction_contact_damping(v_normal, v_tangent, &
                                                   cpair%normals(:, i), &
                                                   cpair%tangents(:, i), &
                                                   c_n, c_t, F_damp_n, F_damp_t)

                        DO j = 1, 3
                            IF (dof_indices(j) > 0 .AND. dof_indices(j) <= SIZE(rhs)) THEN
                                IF (j == 1) THEN
                                    rhs(dof_indices(j)) = rhs(dof_indices(j)) - F_damp_n * cpair%normals(1, i) - F_damp_t(1)
                                ELSE IF (j == 2) THEN
                                    rhs(dof_indices(j)) = rhs(dof_indices(j)) - F_damp_n * cpair%normals(2, i) - F_damp_t(2)
                                ELSE IF (j == 3) THEN
                                    rhs(dof_indices(j)) = rhs(dof_indices(j)) - F_damp_n * cpair%normals(3, i) - F_damp_t(3)
                                END IF
                            END IF
                        END DO
                    END IF
                END IF
            END IF
        END DO
    END SUBROUTINE contact_assemble_csr_with_damping

    !> Purpose: Process contact get Stats
    SUBROUTINE contact_get_Stats(pair_id, total_force, max_pen, n_active, ierr)
        INTEGER(i4), INTENT(IN) :: pair_id
        REAL(wp), INTENT(OUT) :: total_force
        REAL(wp), INTENT(OUT) :: max_pen
        INTEGER(i4), INTENT(OUT) :: n_active
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        TYPE(ContPair) :: cpair
        INTEGER(i4) :: i

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            total_force = 0.0_wp
            max_pen = 0.0_wp
            n_active = 0
            RETURN
        END IF

        cpair = global_contact%active_pairs(pair_id)

        total_force = 0.0_wp
        max_pen = 0.0_wp
        n_active = 0

        DO i = 1, cpair%n_contact_point
            IF (cpair%gaps(i) < 0.0_wp) THEN
                total_force = total_force + cpair%contact_pressur(i)
                max_pen = MAX(max_pen, -cpair%gaps(i))
                n_active = n_active + 1
            END IF
        END DO
    END SUBROUTINE contact_get_Stats

    !> Purpose: Initialize contact iteration
    SUBROUTINE contact_iteration_init(disp, dof_map, ndof, ierr)
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: status

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        ! Inline: directly call contact_update_geometry
        CALL contact_update_geometry(disp, dof_map, ndof, status)
    END SUBROUTINE contact_iteration_init

    !> Purpose: Initialize contact increment
    SUBROUTINE contact_increment_init(disp, dof_map, ndof, E_ref, ierr)
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof
        REAL(wp), INTENT(IN) :: E_ref
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: i_pair, status

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        CALL contact_setup_dof_mapping(dof_map, ndof, status)

        ! Inline: directly call contact_update_geometry
        CALL contact_update_geometry(disp, dof_map, ndof, status)

        DO i_pair = 1, global_contact%n_pairs
            ! Inline: directly call contact_global_search
            CALL contact_global_search(i_pair, status)
        END DO
    END SUBROUTINE contact_increment_init

    !> Purpose: Process contact setup dof mapping
    SUBROUTINE contact_setup_dof_mapping(dof_map, ndof, ierr)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: i_surf, i_node, i_dof

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        DO i_surf = 1, global_contact%n_surfaces
            IF (.NOT. ALLOCATED(global_contact%surfaces(i_surf)%dof_map)) THEN
                ALLOCATE(global_contact%surfaces(i_surf)%dof_map(ndof, &
                       global_contact%surfaces(i_surf)%pop%n_nodes))
            END IF

            DO i_node = 1, global_contact%surfaces(i_surf)%pop%n_nodes
                DO i_dof = 1, ndof
                    global_contact%surfaces(i_surf)%dof_map(i_dof, i_node) = &
                        dof_map(i_dof, global_contact%surfaces(i_surf)%node_ids(i_node))
                END DO
            END DO
        END DO
    END SUBROUTINE contact_setup_dof_mapping

    !> Purpose: Process contact Assem csr
    SUBROUTINE contact_Assem_csr(pair_id, row_ptr, col_idx, values, rhs, ierr)
        INTEGER(i4), INTENT(IN) :: pair_id
        INTEGER(i4), INTENT(IN) :: row_ptr(:)
        INTEGER(i4), INTENT(IN) :: col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:)
        REAL(wp), INTENT(INOUT) :: rhs(:)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        TYPE(ContPair) :: cpair
        TYPE(ContSurface) :: master_surf, slave_surf
        REAL(wp) :: K_local(6,6), F_local(6)
        INTEGER(i4) :: dof_indices(6)
        INTEGER(i4) :: i, j, n_contact
        INTEGER(i4) :: status

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        IF (.NOT. global_contact%pairs(pair_id)%active) THEN
            RETURN
        END IF

        cpair = global_contact%active_pairs(pair_id)
        master_surf = global_contact%surfaces(global_contact%pairs(pair_id)%master_surface)
        slave_surf = global_contact%surfaces(global_contact%pairs(pair_id)%slave_surface_i)

        n_contact = cpair%n_contact_point

        DO i = 1, n_contact
            IF (cpair%gaps(i) < 0.0_wp) THEN
                CALL Cont_Compute_stif_local_3d( &
                    global_contact%pairs(pair_id)%penalty_normal, &
                    global_contact%pairs(pair_id)%penalty_tangent, &
                    cpair%normals(:, i), &
                    cpair%tangents(:, i), &
                    [0.0_wp, 0.0_wp, 0.0_wp], &
                    -cpair%gaps(i), K_local, F_local)

                DOF_indices(1:3) = [slave_surf%dof_map(1, cpair%contact_nodes(i)), &
                                       slave_surf%dof_map(2, cpair%contact_nodes(i)), &
                                       slave_surf%dof_map(3, cpair%contact_nodes(i))]
                
                IF (cpair%master_elements(i) > 0 .AND. cpair%master_elements(i) <= master_surf%n_segments) THEN
                    DOF_indices(4:6) = [master_surf%dof_map(1, master_surf%segments(cpair%master_elements(i))%nodes(1)), &
                                           master_surf%dof_map(2, master_surf%segments(cpair%master_elements(i))%nodes(1)), &
                                           master_surf%dof_map(3, master_surf%segments(cpair%master_elements(i))%nodes(1))]
                ELSE
                    DOF_indices(4:6) = [0, 0, 0]
                END IF

                CALL md_cont_assemble_stif_csr(K_local, dof_indices, row_ptr, col_idx, values)

                DO j = 1, 6
                    IF (dof_indices(j) > 0 .AND. dof_indices(j) <= SIZE(rhs)) THEN
                        rhs(dof_indices(j)) = rhs(dof_indices(j)) - F_local(j)
                    END IF
                END DO
            END IF
        END DO
    END SUBROUTINE contact_Assem_csr

    !> Purpose: Process contact set method
    SUBROUTINE contact_set_method(method)
        INTEGER(i4), INTENT(IN) :: method
        INTEGER(i4) :: eff_method

        eff_method = method
        IF (eff_method <= 0_i4) eff_method = ENFORCE_PENALTY

        global_contact%global_enforcem = eff_method
    END SUBROUTINE contact_set_method

    !> Purpose: Cleanup contact Mgr
    SUBROUTINE contact_Mgr_cleanup()
        IF (init) THEN
            IF (ALLOCATED(global_contact%surfaces)) &
                DEALLOCATE(global_contact%surfaces)
            IF (ALLOCATED(global_contact%pairs)) &
                DEALLOCATE(global_contact%pairs)
            IF (ALLOCATED(global_contact%active_pairs)) &
                DEALLOCATE(global_contact%active_pairs)
            init = .FALSE.
        END IF
    END SUBROUTINE contact_Mgr_cleanup

    !> Purpose: Initialize contact Mgr
    SUBROUTINE contact_Mgr_init(dim, n_surfaces, n_pairs, ierr)
        INTEGER(i4), INTENT(IN) :: dim
        INTEGER(i4), INTENT(IN) :: n_surfaces
        INTEGER(i4), INTENT(IN) :: n_pairs
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0

        IF (dim /= 2 .AND. dim /= 3) THEN
            IF (PRESENT(ierr)) ierr = -10
            RETURN
        END IF

        IF (n_surfaces < 0) THEN
            IF (PRESENT(ierr)) ierr = -11
            RETURN
        END IF

        IF (n_pairs < 0) THEN
            IF (PRESENT(ierr)) ierr = -12
            RETURN
        END IF

        CALL contact_Mgr_cleanup()

        global_contact%contact_dim = dim
        global_contact%n_surfaces = n_surfaces
        global_contact%n_pairs = n_pairs
        global_contact%global_enforcem = ENFORCE_PENALTY

        IF (n_surfaces > 0) THEN
            ALLOCATE(global_contact%surfaces(n_surfaces))
        END IF

        IF (n_pairs > 0) THEN
            ALLOCATE(global_contact%pairs(n_pairs))
            ALLOCATE(global_contact%active_pairs(n_pairs))
        END IF

        init = .TRUE.
    END SUBROUTINE contact_Mgr_init

    !> Purpose: Process contact add surface
    SUBROUTINE contact_add_surface(surf_id, node_ids, n_nodes, X, Y, Z, &
                                    is_master, coord_type, ierr)
        INTEGER(i4), INTENT(IN) :: surf_id
        INTEGER(i4), INTENT(IN) :: node_ids(:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(IN) :: X(:), Y(:), Z(:)
        LOGICAL, INTENT(IN), OPTIONAL :: is_master
        INTEGER(i4), INTENT(IN), OPTIONAL :: coord_type
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: n_segs, ct
        LOGICAL :: master_flag

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        IF (surf_id < 1 .OR. surf_id > global_contact%n_surfaces) THEN
            IF (PRESENT(ierr)) ierr = -2
            RETURN
        END IF

        master_flag = .FALSE.
        IF (PRESENT(is_master)) master_flag = is_master

        ct = COORD_3D_GENERA
        IF (PRESENT(coord_type)) ct = coord_type

        IF (global_contact%contact_dim == CONTACT_2D) THEN
            n_segs = n_nodes - 1
        ELSE
            n_segs = n_nodes / 4
        END IF

        CALL Cont_Surface_init(global_contact%surfaces(surf_id), &
                          surf_id, n_nodes, MAX(1, n_segs), master_flag, ct)

        CALL Cont_Surface_add_nodes(global_contact%surfaces(surf_id), &
                               node_ids, X, Y, Z, n_nodes)

        IF (global_contact%contact_dim == CONTACT_2D) THEN
            CALL Cont_Surface_build_segments_2d(global_contact%surfaces(surf_id))
        ELSE
            CALL Cont_Surface_build_segments_3d(global_contact%surfaces(surf_id), &
                                          RESHAPE(node_ids, [4, n_segs]), n_segs)
        END IF

        CALL Cont_Surface_Compute_bbox(global_contact%surfaces(surf_id))
        CALL Cont_Surface_build_topology(global_contact%surfaces(surf_id))
    END SUBROUTINE contact_add_surface

    !> Purpose: Process contact update geometry
    SUBROUTINE contact_update_geometry(disp, dof_map, ndof, ierr)
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: i

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        DO i = 1, global_contact%n_surfaces
            CALL Cont_Surface_update_coords(global_contact%surfaces(i), disp, dof_map, ndof)
        END DO
    END SUBROUTINE contact_update_geometry

    !> Purpose: Process contact global search
    SUBROUTINE contact_global_search(pair_id, ierr, preallocated_se, preallocated_te)
        INTEGER(i4), INTENT(IN) :: pair_id
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4), INTENT(IN), OPTIONAL, TARGET :: preallocated_se(:)
        TYPE(ContCandidate), INTENT(IN), OPTIONAL, TARGET :: preallocated_te(:)

        TYPE(ContCandidate), ALLOCATABLE :: candidates(:)
        INTEGER(i4) :: n_candidates

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        IF (pair_id < 1 .OR. pair_id > global_contact%n_pairs) THEN
            IF (PRESENT(ierr)) ierr = -2
            RETURN
        END IF

        CALL Cont_Search_global_init( &
            global_contact%surfaces(global_contact%pairs(pair_id)%master_surface), &
            global_contact%surfaces(global_contact%pairs(pair_id)%slave_surface_i), &
            global_contact%pairs(pair_id))

        CALL Cont_Search_find_candidates( &
            global_contact%surfaces(global_contact%pairs(pair_id)%master_surface), &
            global_contact%surfaces(global_contact%pairs(pair_id)%slave_surface_i), &
            global_contact%pairs(pair_id), candidates, n_candidates, 1, &
            preallocated_se=preallocated_se, &
            preallocated_te=preallocated_te)
    END SUBROUTINE contact_global_search

    !> Purpose: Process contact add pair
    SUBROUTINE contact_add_pair(pair_id, master_surf_id, slave_surf_id, &
                                 contact_type, enforcement_met, penalty_n, penalty_t, &
                                 mu_static, mu_kinetic, penalty_scale, ierr)
        INTEGER(i4), INTENT(IN) :: pair_id
        INTEGER(i4), INTENT(IN) :: master_surf_id
        INTEGER(i4), INTENT(IN) :: slave_surf_id
        INTEGER(i4), INTENT(IN), OPTIONAL :: contact_type
        INTEGER(i4), INTENT(IN), OPTIONAL :: enforcement_met
        REAL(wp), INTENT(IN), OPTIONAL :: penalty_n
        REAL(wp), INTENT(IN), OPTIONAL :: penalty_t
        REAL(wp), INTENT(IN), OPTIONAL :: mu_static
        REAL(wp), INTENT(IN), OPTIONAL :: mu_kinetic
        REAL(wp), INTENT(IN), OPTIONAL :: penalty_scale
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0

        IF (.NOT. init) THEN
            IF (PRESENT(ierr)) ierr = -1
            RETURN
        END IF

        IF (pair_id < 1 .OR. pair_id > global_contact%n_pairs) THEN
            IF (PRESENT(ierr)) ierr = -2
            RETURN
        END IF

        global_contact%pairs(pair_id)%cfg%id = pair_id
        global_contact%pairs(pair_id)%master_surface = master_surf_id
        global_contact%pairs(pair_id)%slave_surface_i = slave_surf_id

        IF (PRESENT(contact_type)) THEN
            global_contact%pairs(pair_id)%contact_type = contact_type
        ELSE
            global_contact%pairs(pair_id)%contact_type = CONTACT_NODE_TO
        END IF

        IF (PRESENT(enforcement_met)) THEN
            global_contact%pairs(pair_id)%enforcement_met = enforcement_met
        ELSE
            global_contact%pairs(pair_id)%enforcement_met = ENFORCE_PENALTY
        END IF

        IF (PRESENT(penalty_n)) THEN
            global_contact%pairs(pair_id)%penalty_normal = penalty_n
        END IF

        IF (PRESENT(penalty_t)) THEN
            global_contact%pairs(pair_id)%penalty_tangent = penalty_t
        END IF

        IF (PRESENT(mu_static)) THEN
            global_contact%pairs(pair_id)%friction%mu_static = mu_static
        END IF

        IF (PRESENT(mu_kinetic)) THEN
            global_contact%pairs(pair_id)%friction%mu_kinetic = mu_kinetic
        END IF

        IF (PRESENT(penalty_scale)) THEN
            global_contact%pairs(pair_id)%penalty_scale = penalty_scale
        END IF

        global_contact%pairs(pair_id)%active = .TRUE.
        global_contact%pairs(pair_id)%is_self_contact = &
            (master_surf_id == slave_surf_id)

        CALL contact_init_from_pair(global_contact%active_pairs(pair_id), &
                                    global_contact%pairs(pair_id))
    END SUBROUTINE contact_add_pair

END MODULE MD_Int_Mgr