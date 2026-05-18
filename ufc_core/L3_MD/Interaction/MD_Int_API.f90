!======================================================================
! MODULE:  MD_Int_API
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Thin re-export layer aggregating 8 sub-modules.
!          Backward-compatible PUBLIC interface (149 symbols).
!          Sub-modules: Types, Convert, Detect, Enforce,
!          Friction, Stiffness, Query, Manager.
!          Orchestrating procedures: ApplyPenaltyMethod,
!          ApplyLagrangeMultiplier, UpdateGeometry, ApplyFriction.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_API
    !==================================================================
    ! USE sub-modules (no ONLY => all their PUBLIC symbols accessible)
    !==================================================================
    USE MD_Int_Types
    USE MD_Int_Convert
    USE MD_Int_Detect
    USE MD_Int_Enforce
    USE MD_Int_Friction
    USE MD_Int_Stiffness
    USE MD_Int_Query, query_dot3__ => contact_dot3   ! rename to avoid clash with Types
    USE MD_Int_Manager

    IMPLICIT NONE
    PRIVATE

    !==================================================================
    ! PART 1: Re-export from MD_Int_Types
    !     Constants, enumerations, types, utility functions
    !==================================================================
    ! Contact type constants
    PUBLIC :: CONTACT_2D, CONTACT_3D
    PUBLIC :: CONTACT_NODE_TO, CONTACT_SURFACE, CONTACT_SELF_CO, CONTACT_GENERAL
    ! Contact state constants
    PUBLIC :: CSTATE_SEPARATE, CSTATE_STICKING, CSTATE_SLIDING
    PUBLIC :: CSTATE_INVALID, CSTATE_INITIAL
    ! Enforcement method constants
    PUBLIC :: ENFORCE_PENALTY, ENFORCE_LAGRANG, ENFORCE_AUG_LAG, ENFORCE_DIRECT
    ! Friction model constants
    PUBLIC :: FRICTION_NONE, FRICTION_COULOM, FRICTION_COULOMB
    PUBLIC :: FRICTION_STICK, FRICTION_VELOCI, FRICTION_PRESSU
    PUBLIC :: FRICTION_EXPONENTIAL, FRICTION_USER
    ! Sliding / normal / pressure-overclosure constants
    PUBLIC :: SLIDING_SMALL, SLIDING_FINITE
    PUBLIC :: NORMAL_HARD, NORMAL_EXPONENT, NORMAL_LINEAR, NORMAL_TABULAR
    PUBLIC :: PRESSURE_OVERCLOSURE_HARD, PRESSURE_OVERCLOSURE_LINEAR
    PUBLIC :: PRESSURE_OVERCLOSURE_EXPONENTIAL
    ! Coordinate system constants
    PUBLIC :: COORD_AXISYMMET, COORD_PLANE_STR, COORD_PLANE_STRESS, COORD_3D_GENERA
    ! FEAP-style algorithm constants
    PUBLIC :: CONTACT_ALGO_PE, CONTACT_ALGO_LA, CONTACT_ALGO_AU, CONTACT_ALGO_DI
    PUBLIC :: FRICTION_ALGO_C, FRICTION_ALGO_S, FRICTION_ALGO_R
    ! Core types
    PUBLIC :: ContNode, ContSegment, ContSurface, ContAlgoCtrl, ContForceRes
    PUBLIC :: ContAlgoDesc, UF_ContactAlgoDesc, ContContext
    PUBLIC :: FrictionParams, ContPairDef, ContCandidate
    PUBLIC :: BucketGrid, BVHTree, ContPair
    ! Structured interface types
    PUBLIC :: Cont_ApplyPenaltyMethod_In, Cont_ApplyPenaltyMethod_Out
    PUBLIC :: Cont_ApplyLagrangeMultiplier_In, Cont_ApplyLagrangeMultiplier_Out
    PUBLIC :: ContForceRes_Init_In, ContForceRes_Init_Out
    PUBLIC :: Cont_UpdateGeometry_In, Cont_UpdateGeometry_Out
    PUBLIC :: Cont_ApplyFriction_In, Cont_ApplyFriction_Out
    ! Module-level variables (user callbacks)
    PUBLIC :: is_uinter_activ, is_fric_active
    PUBLIC :: user_uinter, user_fric
    ! Utility functions
    PUBLIC :: md_cont_cross_product, contact_dot3, contact_has_int
    PUBLIC :: md_cont_point_in_aabb
    ! TYPE-bound procedure implementations (needed for type binding)
    PUBLIC :: ContNode_Destroy, ContForceRes_Init, ContForceRes_Destroy
    ! Re-exported from downstream modules
    PUBLIC :: MD_NodeDisp
    PUBLIC :: ErrorStatusType, init_error_status, IF_STATUS_OK
    ! Arg bundle types
    PUBLIC :: MD_IC_ContactAddK_Arg, MD_IC_ContactAddForce_Arg
    PUBLIC :: MD_IC_ContactAssemTriplets_Arg, MD_IC_ContactInit_Arg
    PUBLIC :: MD_IC_ContactUpdateGeom_Arg, MD_IC_ContactEvalFace_Arg

    !==================================================================
    ! PART 2: Re-export from MD_Int_Convert
    !     Geometry, projection, shape functions, gap/normal/tangent
    !==================================================================
    PUBLIC :: Cont_Geometry_project_point_2d, Cont_Geometry_project_point_3d
    PUBLIC :: Cont_Geometry_Compute_gap_2d, Cont_Geometry_Compute_gap_3d
    PUBLIC :: Cont_Geometry_Compute_normal_2d, Cont_Geometry_Compute_normal_3d
    PUBLIC :: Cont_Geometry_Compute_tangent_2d, Cont_Geometry_Compute_tangent_3d
    PUBLIC :: Cont_Geometry_shape_functions_2d, Cont_Geometry_shape_functions_3d
    PUBLIC :: Cont_Geometry_newton_projection_3d
    PUBLIC :: Cont_Geometry_Compute_jacobian_2d, Cont_Geometry_Compute_jacobian_3d
    PUBLIC :: Cont_Geometry_update_contact_point
    ! Orchestrating geometry procedures (also from Convert)
    PUBLIC :: Cont_UpdateGeometry, Cont_UpdateGeometry_Simple
    PUBLIC :: Cont_ComputeRelativeVelocity, Cont_ProjectToSurface, Cont_ComputeTangents

    !==================================================================
    ! PART 3: Re-export from MD_Int_Detect
    !     Bucket grid, BVH tree, search, detection
    !==================================================================
    PUBLIC :: Cont_Search_global_init, Cont_Search_find_candidates
    PUBLIC :: Cont_Search_local_update, Cont_Search_update_tracking
    PUBLIC :: Cont_Bucket_grid_init, Cont_Bucket_grid_build
    PUBLIC :: Cont_Bucket_grid_query, Cont_Bucket_grid_cleanup
    PUBLIC :: Cont_BVH_tree_build, Cont_BVH_tree_query, Cont_BVH_tree_cleanup
    PUBLIC :: brute_force_search
    PUBLIC :: md_cont_aabb_overlap_test
    PUBLIC :: contact_detect, contact_detect_2d, contact_detect_3d

    !==================================================================
    ! PART 4: Re-export from MD_Int_Enforce
    !     Penalty, Lagrange, augmented Lagrange enforcement
    !==================================================================
    PUBLIC :: Cont_Enforce_penalty
    PUBLIC :: Cont_Enforce_augmented_lagrange
    PUBLIC :: Cont_Enforce_lagrange_multiplier
    PUBLIC :: Cont_Enforce_update_multipliers

    !==================================================================
    ! PART 5: Re-export from MD_Int_Friction
    !     Friction models and algorithms
    !==================================================================
    PUBLIC :: Cont_ApplyFriction
    PUBLIC :: Cont_Friction_COULOM, Cont_Friction_STICK
    PUBLIC :: Cont_Friction_velocity_dependent, Cont_Friction_update_state
    PUBLIC :: Cont_Friction_Compute_force
    PUBLIC :: Cont_Friction_Compute_force_2d, Cont_Friction_Compute_force_3d
    PUBLIC :: Cont_Friction_Compute_Stiff
    PUBLIC :: Cont_Friction_check_slip_condition
    PUBLIC :: Cont_Friction_Compute_slip_direction
    PUBLIC :: Cont_Friction_pressure_dependent
    PUBLIC :: Cont_Friction_bond_debond
    PUBLIC :: Cont_Friction_contact_damping, Cont_Friction_critical_damping
    PUBLIC :: Cont_Friction_set_damping_ratio

    !==================================================================
    ! PART 6: Re-export from MD_Int_Stiffness
    !     Local stiffness, CSR assembly, force vectors
    !==================================================================
    PUBLIC :: Cont_Compute_stif_local_2d, Cont_Compute_stif_local_3d
    PUBLIC :: md_cont_assemble_stif_csr, md_cont_add_stif_contact_to_csr
    PUBLIC :: contact_stif_pattern_csr, penalty_stif_csr
    PUBLIC :: alm_stif_csr, alm_stif_csr_from_nodes
    PUBLIC :: Cont_Compute_stif_force_vector
    PUBLIC :: Cont_AsmPenaltyStiff
    PUBLIC :: contact_add_contact_k, contact_add_force
    PUBLIC :: contact_Assemble_triplets, contact_Assemble_contact_pair
    PUBLIC :: contact_assemble_surface_to_surface_penalty
    PUBLIC :: contact_assemble_surface_to_surface_penalty_cross
    PUBLIC :: contact_add_contact_k_Arg, contact_add_force_Arg
    PUBLIC :: contact_Assemble_triplets_Arg

    !==================================================================
    ! PART 7: Re-export from MD_Int_Query
    !     Find/lookup, UF_* user function API
    !==================================================================
    PUBLIC :: contact_find_Elem_index, contact_find_node_index_in_part
    PUBLIC :: contact_find_node_state_index, contact_get_node_coord_curr
    ! UF procedures
    PUBLIC :: UF_Contact_ApplyConstraint
    PUBLIC :: UF_Contact_ComputeNormalForce
    PUBLIC :: UF_ContactForce_ComputeNormalForce
    PUBLIC :: UF_Contact_ComputeStiffness
    PUBLIC :: UF_Contact_ComputeTotalForce
    PUBLIC :: UF_ContactForce_ComputeTotalForce
    PUBLIC :: UF_Contact_GetOutputStatistics
    PUBLIC :: UF_Contact_Search_GetStatistics
    PUBLIC :: UF_Contact_UpdateState, UF_ContactState_UpdateState
    PUBLIC :: UF_ContactOutput_GetContactPressure
    PUBLIC :: UF_ContactOutput_GetSlipDistance
    PUBLIC :: UF_ContactSearch_GetStatistics
    PUBLIC :: UF_ContactStiffness_ComputePenaltyStiffness

    !==================================================================
    ! PART 8: Re-export from MD_Int_Manager
    !     Surface management, contact init, user callbacks
    !==================================================================
    PUBLIC :: Cont_Surface_init, Cont_Surface_add_nodes
    PUBLIC :: Cont_Surface_build_segments_2d, Cont_Surface_build_segments_3d
    PUBLIC :: Cont_Surface_update_coords
    PUBLIC :: Cont_Surface_Compute_normals_2d, Cont_Surface_Compute_normals_3d
    PUBLIC :: Cont_Surface_Compute_bbox, Cont_Surface_Compute_bbox_internal
    PUBLIC :: Cont_Surface_build_topology, Cont_Surface_Valid
    PUBLIC :: contact_init, contact_init_Arg, contact_init_from_pair
    PUBLIC :: contact_update_geometry, contact_update_geometry_Arg
    PUBLIC :: contact_decode_global_surf_id, contact_collect_surface_nodes
    PUBLIC :: contact_compute_face_normal_area
    PUBLIC :: contact_Eval_face_gap, contact_Evaluate_face_gap
    PUBLIC :: contact_Eval_face_gap_Arg
    PUBLIC :: uinter_call, ucontprop_call
    PUBLIC :: user_contact_init, user_contact_Reg
    PUBLIC :: fric_call, vfric_call

    !==================================================================
    ! PART 9: Orchestrating procedures (remain in thin layer)
    !==================================================================
    PUBLIC :: Cont_ApplyPenaltyMethod
    PUBLIC :: Cont_ApplyLagrangeMultiplier
    ! Structured interface procedures
    PUBLIC :: ContForceRes_Init_Structured
    PUBLIC :: Cont_UpdateGeometry_Structured
    PUBLIC :: Cont_ApplyFriction_Structured

CONTAINS

    !==================================================================
    ! Cont_ApplyPenaltyMethod - FEAP-style penalty method orchestrator
    ! Calls: Cont_UpdateGeometry (Convert), Cont_ApplyFriction (Friction),
    !        Cont_ComputeRelativeVelocity (Convert),
    !        Cont_AsmPenaltyStiff (Stiffness)
    !==================================================================
    SUBROUTINE Cont_ApplyPenaltyMethod(contact_nodes, displacements, velocities, &
                                         control, forces, stiffness, status)
        TYPE(ContNode), INTENT(INOUT) :: contact_nodes(:)
        REAL(wp), INTENT(IN) :: displacements(:)
        REAL(wp), INTENT(IN) :: velocities(:)
        TYPE(ContAlgoCtrl), INTENT(IN) :: control
        TYPE(ContForceRes), INTENT(OUT) :: forces
        REAL(wp), INTENT(INOUT) :: stiffness(:,:)
        INTEGER(i4), INTENT(OUT) :: status

        INTEGER(i4) :: i, node_idx, dof_start
        REAL(wp) :: gap, penetration, normal_force, tangent_force(2)
        REAL(wp) :: penalty_normal, penalty_tangent
        REAL(wp) :: relative_veloci(3), slip_rate(2)
        REAL(wp) :: n_vector(3), t1_vector(3), t2_vector(3)

        status = 0
        forces%nActiveCont = 0
        forces%total_normal_fo = 0.0_wp
        forces%total_friction = 0.0_wp

        CALL forces%Init(SIZE(contact_nodes), status)
        IF (status /= 0) RETURN

        DO i = 1, SIZE(contact_nodes)
            IF (.NOT. contact_nodes(i)%active) CYCLE

            CALL Cont_UpdateGeometry(contact_nodes(i), displacements, gap, &
                                      n_vector, t1_vector, t2_vector)

            penetration = -gap

            IF (gap > control%tolerance_gap) THEN
                contact_nodes(i)%state = CSTATE_SEPARATE
                contact_nodes(i)%force_n = 0.0_wp
                contact_nodes(i)%force_t = 0.0_wp
                forces%normal_forces(i) = 0.0_wp
                forces%tangent_forces(:,i) = 0.0_wp
                CYCLE
            ELSE
                contact_nodes(i)%state = CSTATE_STICKING
                forces%nActiveCont = forces%nActiveCont + 1
            END IF

            penalty_normal = control%penalty_stiffne
            penalty_tangent = control%penalty_stiffne

            normal_force = -penalty_normal * penetration
            contact_nodes(i)%force_n = normal_force
            forces%normal_forces(i) = normal_force
            forces%total_normal_fo = forces%total_normal_fo + ABS(normal_force)

            IF (control%include_frictio) THEN
                CALL Cont_ComputeRelativeVelocity(contact_nodes(i), velocities, relative_veloci)
                CALL Cont_ApplyFriction(contact_nodes(i), relative_veloci, control, &
                                          tangent_force, slip_rate)

                contact_nodes(i)%force_t(1) = tangent_force(1)
                contact_nodes(i)%force_t(2) = tangent_force(2)
                contact_nodes(i)%force_t(3) = 0.0_wp

                forces%tangent_forces(1,i) = tangent_force(1)
                forces%tangent_forces(2,i) = tangent_force(2)
                forces%total_friction = forces%total_friction + &
                                            SQRT(tangent_force(1)**2 + tangent_force(2)**2)

                node_idx = contact_nodes(i)%global_id
                dof_start = 3 * (node_idx - 1) + 1
            END IF

            CALL Cont_AsmPenaltyStiff(contact_nodes(i), penalty_normal, &
                                                penalty_tangent, n_vector, &
                                                t1_vector, t2_vector, stiffness)
        END DO

    END SUBROUTINE

    !==================================================================
    ! Cont_ApplyLagrangeMultiplier - Lagrange multiplier method orchestrator
    ! Calls: Cont_UpdateGeometry_Simple (Convert)
    !==================================================================
    SUBROUTINE Cont_ApplyLagrangeMultiplier(contact_nodes, displacements, &
                                              control, constraint_matr, constraint_rhs, &
                                              lagrange_multip, status)
        TYPE(ContNode), INTENT(IN) :: contact_nodes(:)
        REAL(wp), INTENT(IN) :: displacements(:)
        TYPE(ContAlgoCtrl), INTENT(IN) :: control
        REAL(wp), INTENT(OUT) :: constraint_matr(:,:)
        REAL(wp), INTENT(OUT) :: constraint_rhs(:)
        REAL(wp), INTENT(INOUT) :: lagrange_multip(:)
        INTEGER(i4), INTENT(OUT) :: status

        INTEGER(i4) :: i, node_idx, constraint_eq
        REAL(wp) :: gap, n_vector(3)

        status = 0
        constraint_matr = 0.0_wp
        constraint_rhs = 0.0_wp
        constraint_eq = 0

        DO i = 1, SIZE(contact_nodes)
            IF (.NOT. contact_nodes(i)%active) CYCLE

            CALL Cont_UpdateGeometry_Simple(contact_nodes(i), displacements, gap, n_vector)

            IF (gap <= control%tolerance_gap) THEN
                constraint_eq = constraint_eq + 1
                node_idx = contact_nodes(i)%global_id
                constraint_matr(constraint_eq, 3*node_idx-2) = n_vector(1)
                constraint_matr(constraint_eq, 3*node_idx-1) = n_vector(2)
                constraint_matr(constraint_eq, 3*node_idx)   = n_vector(3)
                constraint_rhs(constraint_eq) = -gap
                lagrange_multip(constraint_eq) = contact_nodes(i)%force_n
            END IF
        END DO

    END SUBROUTINE

    !==================================================================
    ! ContForceRes_Init_Structured - Structured interface for Init
    !==================================================================
    SUBROUTINE ContForceRes_Init_Structured(in, out, force_res)
        TYPE(ContForceRes_Init_In), INTENT(IN) :: in
        TYPE(ContForceRes_Init_Out), INTENT(OUT) :: out
        TYPE(ContForceRes), INTENT(INOUT) :: force_res

        INTEGER(i4) :: status_local
        CALL force_res%Init(in%pop%n_nodes, status_local)
        out%status = status_local
    END SUBROUTINE

    !==================================================================
    ! Cont_UpdateGeometry_Structured - Structured interface for geometry
    !==================================================================
    SUBROUTINE Cont_UpdateGeometry_Structured(in, out, contact_node)
        TYPE(Cont_UpdateGeometry_In), INTENT(IN) :: in
        TYPE(Cont_UpdateGeometry_Out), INTENT(OUT) :: out
        TYPE(ContNode), INTENT(INOUT) :: contact_node

        out%status = 0
        CALL Cont_UpdateGeometry(contact_node, in%displacements, out%gap, &
                                 out%n_vector, out%t1_vector, out%t2_vector)
    END SUBROUTINE

    !==================================================================
    ! Cont_ApplyFriction_Structured - Structured interface for friction
    !==================================================================
    SUBROUTINE Cont_ApplyFriction_Structured(in, out, contact_node)
        TYPE(Cont_ApplyFriction_In), INTENT(IN) :: in
        TYPE(Cont_ApplyFriction_Out), INTENT(OUT) :: out
        TYPE(ContNode), INTENT(INOUT) :: contact_node

        out%status = 0
        CALL Cont_ApplyFriction(contact_node, in%relative_velocity, in%control, &
                                out%tangent_force, out%slip_rate)
    END SUBROUTINE

END MODULE MD_Int_API
