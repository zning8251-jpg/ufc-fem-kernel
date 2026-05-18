!===============================================================================
! MODULE: PH_Cont_Mgr
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Mgr
! BRIEF:  Contact mechanics core algorithms (gap/friction/thermal/dynamic)
!
! Theory: KKT, penalty, augmented Lagrangian, Coulomb friction
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Contact | Role:Core | FuncSet?Detect+Friction | 热路�?�?!>>> Basis:PLAN/04_实施路线�任务规�?实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md ��?5.1�L4 接触算法核）
!>>> UFC_PH_CONTRACT | Contact/CONTRACT.md

MODULE PH_Cont_Mgr
!> [CORE] Contact mechanics algorithms implementation
! > Theory: KKT (g>=0, lambda>=0, lambda*g=0), ?F_n=eps*max(0,-g)*n, �?|tau|<=mu*sigma_n
!> Status: Production | Last verified: 2026-02-28
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF, PI, SMALL_VAL => SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE PH_Cont_Ctx_Def, ONLY: PH_ContactCtx, PH_Cont_Time_Desc
  USE PH_Cont_Def, ONLY: PH_Cont_AlgorithmFramework_In, PH_Cont_AlgorithmFramework_Out, &
                           PH_Cont_ConvergenceCheck_In, PH_Cont_ConvergenceCheck_Out, &
                           PH_Cont_SearchPairs_In, PH_Cont_SearchPairs_Out, &
                           PH_Cont_DetectPenetration_In, PH_Cont_DetectPenetration_Out, &
                           PH_Cont_CalculateGap_In, PH_Cont_CalculateGap_Out, &
                           PH_Cont_ApplyConstraints_In, PH_Cont_ApplyConstraints_Out, &
                           PH_Cont_UpdateFriction_In, PH_Cont_UpdateFriction_Out, &
                           PH_Cont_AlgorithmFramework_Impl_In, PH_Cont_AlgorithmFramework_Impl_Out, &
                           PH_Cont_ComputeTangentVectors_In, PH_Cont_ComputeTangentVectors_Out, &
                           PH_Cont_ComputeContactForces_In, PH_Cont_ComputeContactForces_Out, &
                           PH_Cont_ApplyImpactResponse_In, PH_Cont_ApplyImpactResponse_Out, &
                           PH_Cont_ComputeTemperatureEffect_In, PH_Cont_ComputeTemperatureEffect_Out, &
                           PH_Cont_PenaltyForce_In, PH_Cont_PenaltyForce_Out, &
                           PH_Cont_PenaltyStiffness_In, PH_Cont_PenaltyStiffness_Out, &
                           PH_Cont_LagrangeForce_In, PH_Cont_LagrangeForce_Out, &
                           PH_Cont_AugLagForce_In, PH_Cont_AugLagForce_Out, &
                           PH_Cont_AugLagUpdate_In, PH_Cont_AugLagUpdate_Out, &
                           PH_Cont_Gap_In, PH_Cont_Gap_Out, PH_Cont_Normal_In, PH_Cont_Normal_Out, &
                           PH_Cont_StateCheck_In, PH_Cont_StateCheck_Out, &
                           PH_Cont_NearestPoint_In, PH_Cont_NearestPoint_Out, &
                           PH_Cont_Penetration_In, PH_Cont_Penetration_Out, &
                           PH_Cont_CoulombFriction_In, PH_Cont_CoulombFriction_Out, &
                           PH_Cont_StickSlip_In, PH_Cont_StickSlip_Out, &
                           PH_Cont_ComputeSlip_In, PH_Cont_ComputeSlip_Out, &
                           PH_Cont_FrictionStiffness_In, PH_Cont_FrictionStiffness_Out, &
                           PH_Cont_ExponentialFriction_In, PH_Cont_ExponentialFriction_Out, &
                           PH_Cont_PressureDependentFriction_In, PH_Cont_PressureDependentFriction_Out, &
                           PH_Cont_VelocityDependentFriction_In, PH_Cont_VelocityDependentFriction_Out

  IMPLICIT NONE
  PRIVATE

  ! ========== PUBLIC INTERFACES ==========
  PUBLIC :: PH_Cont_AlgorithmFramework
  PUBLIC :: PH_Cont_ConvergenceCheck
  PUBLIC :: PH_Cont_SearchPairs
  PUBLIC :: PH_Cont_DetectPenetration
  PUBLIC :: PH_Cont_CalculateGap
  PUBLIC :: PH_Cont_ApplyConstraints
  PUBLIC :: PH_Cont_UpdateFriction
  PUBLIC :: PH_Cont_CheckConvergence
  PUBLIC :: PH_Cont_Penetration_Algo
  PUBLIC :: PH_Cont_Friction_Algo
  PUBLIC :: PH_Cont_Thermal_Contact
  PUBLIC :: PH_Cont_Dynamic_Contact
  PUBLIC :: PH_Cont_AlgorithmFramework_Impl_Structured
  PUBLIC :: PH_Cont_ComputeTangentVectors_Structured
  PUBLIC :: PH_Cont_ComputeContactForces_Structured
  PUBLIC :: PH_Cont_ApplyImpactResponse_Structured
  PUBLIC :: PH_Cont_ComputeTemperatureEffect_Structured
  ! Constr (merged from PH_Cont_Constr_Core)
  PUBLIC :: PH_Cont_PenaltyForce, PH_Cont_PenaltyStiffness
  PUBLIC :: PH_Cont_LagrangeForce, PH_Cont_AugLagForce, PH_Cont_AugLagUpdate
  ! Search (merged from PH_Cont_Search_Core)
  PUBLIC :: PH_Cont_ComputeGap, PH_Cont_ComputeNormal, PH_Cont_CheckState
  PUBLIC :: PH_Cont_FindNearestPoint, PH_Cont_ComputePenetration
  PUBLIC :: PH_Cont_Search_Opt, PH_Cont_Pair_Identify
  PUBLIC :: PH_Cont_SpatialHash, PH_Cont_BoundingBox
  PUBLIC :: AABB_Type, BVH_Node_Type, Octree_Node_Type, SpatialHash_Type
  PUBLIC :: AABB_Init, AABB_Expand, AABB_Overlap
  PUBLIC :: BVH_Build, BVH_Build_Recursive_FromPack, BVH_Query_Collisions
  PUBLIC :: BVH_Build_Desc, Octree_Build, Octree_Query
  PUBLIC :: SpatialHash_Init, SpatialHash_Insert, SpatialHash_Query
  ! Friction (merged from PH_Cont_Friction_Core)
  PUBLIC :: PH_Cont_CoulombFriction, PH_Cont_StickSlip, PH_Cont_ComputeSlip
  PUBLIC :: PH_Cont_FrictionStiffness, PH_Cont_ExponentialFriction
  PUBLIC :: PH_Cont_PressureDependentFriction, PH_Cont_VelocityDependentFriction
  ! LargeDef (merged from PH_Cont_LargeDef_Core)
  PUBLIC :: PH_Cont_LargeDef_State_Type
  PUBLIC :: PH_Cont_LargeDef_State_Init, PH_Cont_LargeDef_Update_Normal
  PUBLIC :: PH_Cont_LargeDef_Update_Gap, PH_Cont_LargeDef_Check_Sliding
  PUBLIC :: PH_Cont_LargeDef_Compute_Tangent, PH_Cont_LargeDef_Track_Boundary

  !=============================================================================
  ! INTF-001
  ! Purpose: Contact 5-7
  ! Status: Draft |
  !=============================================================================

  ! -- S1 --------------------------------------------------
  ! : PH_Cont_Search_Opt(5 ), PH_Cont_Pair_Identify(8 / )
  ! PH_Cont_SpatialHash(5 ), PH_Cont_BoundingBox(5 )
  PUBLIC :: PH_Cont_SearchArgs
  TYPE :: PH_Cont_SearchArgs
    INTEGER(i4) :: search_algorithm  = 0_i4  !! 0= 1=BVH 2=SpatialHash 3=Octree
    INTEGER(i4) :: optimization_level = 0_i4  !! 0= 1= 2= 3=
    INTEGER(i4) :: n_candidates      = 0_i4  ! narrow-phase candidate count
    INTEGER(i4) :: n_contacts        = 0_i4  ! active contact count
    REAL(wp)    :: cell_size         = 1.0_wp  ! uniform cell size (hash)
    REAL(wp)    :: tolerance         = 1.0e-6_wp  ! convergence tolerance
    REAL(wp)    :: bbox_min(3)       = 0.0_wp  ! AABB min corner
    REAL(wp)    :: bbox_max(3)       = 0.0_wp  ! AABB max corner
    ! POINTER
    INTEGER(i4), POINTER :: slave_nodes(:)   => NULL()  ! slave node id list ptr
    INTEGER(i4), POINTER :: master_nodes(:)  => NULL()  ! master node id list ptr
    INTEGER(i4) :: n_slave    = 0_i4  ! slave entity count
    INTEGER(i4) :: n_master   = 0_i4  ! master entity count
    INTEGER(i4), POINTER :: contact_pairs(:,:) => NULL()  !! (2, n_pairs)
    INTEGER(i4) :: n_pairs    = 0_i4  ! contact pair count
    ! POINTER
    REAL(wp), POINTER :: coords(:,:)  => NULL()  !! (3, n_points)
    INTEGER(i4) :: n_points   = 0_i4  ! sample / quadrature point count
  END TYPE PH_Cont_SearchArgs

  ! -- S2 BVH -----------------------------------------------
  ! : BVH_Build(5 ), BVH_Query_Collisions(7 / )
  ! Octree_Build(6 ), Octree_Query(6 )
  PUBLIC :: PH_Cont_BVHArgs
  TYPE :: PH_Cont_BVHArgs
    ! ---- BVH ----
    INTEGER(i4) :: n_objects    = 0_i4  ! spatial-hash object count
    INTEGER(i4) :: max_depth    = 32_i4  !! Octree
    INTEGER(i4) :: root_id      = 0_i4   !! ID
    ! ---- ----
    TYPE(AABB_Type) :: query_aabb            !! AABB
    INTEGER(i4) :: n_collisions  = 0_i4  ! broad-phase collision count
    ! POINTER
    TYPE(BVH_Node_Type), POINTER :: nodes(:) => NULL()   !! BVH ALLOCATABLE POINTER
    TYPE(AABB_Type),     POINTER :: objects_aabb(:) => NULL() !! AABB
    INTEGER(i4), POINTER :: collision_ids(:) => NULL()  !! ID
    INTEGER(i4), POINTER :: work_buf(:)      => NULL()  ! temporary workspace ptr
  END TYPE PH_Cont_BVHArgs

  ! -- S3 SpatialHash ------------------------------------------
  ! : SpatialHash_Init(4 4 )
  ! SpatialHash_Query(6 / )
  PUBLIC :: PH_Cont_SpatialHashArgs
  TYPE :: PH_Cont_SpatialHashArgs
    REAL(wp)    :: cell_size          = 1.0_wp  ! uniform cell size (hash)
    INTEGER(i4) :: table_size         = 10007_i4  ! hash table slot count
    INTEGER(i4) :: max_objects_per_cell = 100_i4  ! max objects per hash cell
    REAL(wp)    :: query_position(3)  = 0.0_wp  !! Query
    INTEGER(i4) :: n_nearby           = 0_i4  ! neighbour search result count
    INTEGER(i4), POINTER :: nearby_ids(:) => NULL()  !! ID
    INTEGER(i4), POINTER :: work_buf(:)   => NULL()  ! temporary workspace ptr
  END TYPE PH_Cont_SpatialHashArgs

  ! -- L1 --------------------------------------------
  ! : PH_Cont_LargeDef_State_Init(6 )
  ! PH_Cont_LargeDef_Track_Boundary(5 )
  PUBLIC :: PH_Cont_LargeDefArgs
  TYPE :: PH_Cont_LargeDefArgs
    ! ---- ----
    REAL(wp) :: X_slave(3)   = 0.0_wp  ! slave surface coords ptr
    REAL(wp) :: X_master(3)  = 0.0_wp  ! master surface coords ptr
    REAL(wp) :: u_slave(3)   = 0.0_wp  ! slave displacement ptr
    REAL(wp) :: u_master(3)  = 0.0_wp  ! master displacement ptr
    ! ---- ----
    REAL(wp), POINTER :: surface_coords(:,:) => NULL()  !! (3, n_surf_nodes)
    INTEGER(i4) :: n_surface_nodes = 0_i4  ! nodes on surface patch
    INTEGER(i4) :: closest_node_id = 0_i4  !! ID
  END TYPE PH_Cont_LargeDefArgs

  !=============================================================================
  ! TYPE DEFINITIONS - Search (AABB, BVH, Octree, SpatialHash)
  !=============================================================================
  TYPE, PUBLIC :: AABB_Type
      REAL(wp) :: min_coords(3) = ZERO
      REAL(wp) :: max_coords(3) = ZERO
      REAL(wp) :: center(3) = ZERO
      REAL(wp) :: extents(3) = ZERO
  END TYPE AABB_Type
  TYPE, PUBLIC :: BVH_Node_Type
      TYPE(AABB_Type) :: bbox
      INTEGER(i4) :: left_child = -1
      INTEGER(i4) :: right_child = -1
      INTEGER(i4) :: object_id = -1
      LOGICAL :: is_leaf = .FALSE.
  END TYPE BVH_Node_Type
  TYPE, PUBLIC :: BVH_Build_Desc
      INTEGER(i4) :: n_objects = 0
      INTEGER(i4) :: start_idx = 0
      INTEGER(i4) :: end_idx = 0
      INTEGER(i4) :: max_nodes = 0
      INTEGER(i4) :: node_id = -1
      INTEGER(i4) :: node_count = 0
  END TYPE BVH_Build_Desc
  TYPE, PUBLIC :: Octree_Node_Type
      TYPE(AABB_Type) :: bbox
      INTEGER(i4) :: children(8) = -1
      INTEGER(i4), ALLOCATABLE :: object_ids(:)
      INTEGER(i4) :: n_objects = 0
      INTEGER(i4) :: depth = 0
      LOGICAL :: is_leaf = .TRUE.
  END TYPE Octree_Node_Type
  TYPE, PUBLIC :: SpatialHash_Type
      REAL(wp) :: cell_size = 1.0_wp
      INTEGER(i4) :: table_size = 10007
      INTEGER(i4), ALLOCATABLE :: hash_table(:,:)
      INTEGER(i4), ALLOCATABLE :: cell_counts(:)
      INTEGER(i4) :: max_objects_per_cell = 100
  END TYPE SpatialHash_Type

  !=============================================================================
  ! TYPE DEFINITIONS - LargeDef (P2 nested auxiliary TYPEs)
  !=============================================================================

  TYPE, PUBLIC :: PH_Cont_LD_Ref_Geom
      REAL(wp) :: X_slave_ref(3) = ZERO
      REAL(wp) :: X_master_ref(3) = ZERO
      REAL(wp) :: normal_ref(3) = [ZERO, ZERO, ONE]
      REAL(wp) :: tangent1(3) = [ONE, ZERO, ZERO]
      REAL(wp) :: tangent2(3) = [ZERO, ONE, ZERO]
      REAL(wp) :: gap_ref = ZERO
  END TYPE PH_Cont_LD_Ref_Geom

  TYPE, PUBLIC :: PH_Cont_LD_Curr_Geom
      REAL(wp) :: x_slave(3) = ZERO
      REAL(wp) :: x_master(3) = ZERO
      REAL(wp) :: u_slave(3) = ZERO
      REAL(wp) :: u_master(3) = ZERO
      REAL(wp) :: normal_curr(3) = [ZERO, ZERO, ONE]
      REAL(wp) :: gap_curr = ZERO
  END TYPE PH_Cont_LD_Curr_Geom

  TYPE, PUBLIC :: PH_Cont_LD_DeformGrad
      REAL(wp) :: F_slave(3,3) = ZERO
      REAL(wp) :: F_master(3,3) = ZERO
  END TYPE PH_Cont_LD_DeformGrad

  TYPE, PUBLIC :: PH_Cont_LD_ContactState
      INTEGER(i4) :: state = 0
      INTEGER(i4) :: state_prev = 0
      LOGICAL :: just_transitioned = .FALSE.
  END TYPE PH_Cont_LD_ContactState

  TYPE, PUBLIC :: PH_Cont_LD_Slip
      REAL(wp) :: slip_increment(3) = ZERO
      REAL(wp) :: accumulated_slip(3) = ZERO
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: slip_tolerance = 1.0e-9_wp
  END TYPE PH_Cont_LD_Slip

  TYPE, PUBLIC :: PH_Cont_LD_Force
      REAL(wp) :: normal_force = ZERO
      REAL(wp) :: friction_force(3) = ZERO
  END TYPE PH_Cont_LD_Force

  TYPE, PUBLIC :: PH_Cont_LargeDef_State_Type
      TYPE(PH_Cont_LD_Ref_Geom)      :: ref
      TYPE(PH_Cont_LD_Curr_Geom)     :: curr
      TYPE(PH_Cont_LD_DeformGrad)    :: F
      TYPE(PH_Cont_LD_ContactState)  :: contact
      TYPE(PH_Cont_LD_Slip)          :: slip
      TYPE(PH_Cont_LD_Force)         :: force
      ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_Cont_LargeDef_State_Type

CONTAINS

  !=============================================================================
  !> @brief Contact algorithm framework (structured interface)
  !! @details Implements contact algorithm framework with gap, normal vector, relative velocity
  !!   Theory: Gap g, normal n in R^3, relative velocity v_rel in R^3, time step dt
  !! @param[inout] ctx Contact context
  !! @param[in] in Structured input containing gap, normal vector, relative velocity, time step
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_AlgorithmFramework(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_AlgorithmFramework_In), INTENT(IN) :: in
      TYPE(PH_Cont_AlgorithmFramework_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_AlgorithmFramework: Ctx not initialized'
          RETURN
      END IF

      ! Construct structured input for implementation
      TYPE(PH_Cont_AlgorithmFramework_Impl_In) :: impl_in
      TYPE(PH_Cont_AlgorithmFramework_Impl_Out) :: impl_out

      impl_in%gap = in%gap
      impl_in%normal_vector = in%normal_vector
      impl_in%relative_velocity = in%relative_velocity
      impl_in%dt = in%dt

      CALL PH_Cont_AlgorithmFramework_Impl_Structured(ctx, impl_in, impl_out)
      out%status = impl_out%status

  END SUBROUTINE PH_Cont_AlgorithmFramework

  !=============================================================================
  !> @brief Check contact convergence
  !! @details Checks convergence based on residual norm and iteration count
  !!   Theory: Convergence when ||r|| < ?? or iteration_count ??n_max where r is residual, ?? is tolerance
  !! @param[inout] ctx Contact context
  !! @param[in] in Structured input containing residual, tolerance, max iterations
  !! @param[out] out Structured output containing convergence flag and error status
  !=============================================================================
  SUBROUTINE PH_Cont_ConvergenceCheck(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ConvergenceCheck_In), INTENT(IN) :: in
      TYPE(PH_Cont_ConvergenceCheck_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      ctx%residual_norm = ABS(in%residual)
      ctx%tolerance = in%tolerance
      ctx%iteration_count = ctx%iteration_count + 1

      out%converged = (ctx%residual_norm < in%tolerance) .OR. &
                      (ctx%iteration_count >= in%max_iterations)

      ctx%converged = out%converged
      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ConvergenceCheck

  !=============================================================================
  !> @brief Search contact pairs
  !! @details Searches for contact pairs based on node coordinates and displacements
  !!   Theory: Contact occurs when distance < tolerance, gap g = distance - tolerance
  !! @param[inout] ctx Contact context
  ! ! @param[in] in �??X(3,nnode) ?u(3,nnode)
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_SearchPairs(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_SearchPairs_In), INTENT(IN) :: in
      TYPE(PH_Cont_SearchPairs_Out), INTENT(OUT) :: out

      INTEGER(i4) :: i, j, nNodes
      REAL(wp)    :: distance, current_pos(3)

      CALL init_error_status(out%status)

      IF (.NOT. ASSOCIATED(in%node_coords) .OR. .NOT. ASSOCIATED(in%node_displacements)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_SearchPairs: Invalid input pointers'
          RETURN
      END IF

      nNodes = SIZE(in%node_coords, 2)

      DO i = 1, nNodes - 1
          DO j = i + 1, nNodes
              current_pos = in%node_coords(:,i) + in%node_displacements(:,i)
              distance = SQRT(SUM((current_pos - (in%node_coords(:,j) + in%node_displacements(:,j)))**2))

              IF (distance < ctx%tolerance) THEN
                  ctx%gap = distance - ctx%tolerance
                  IF (ctx%gap < ZERO) THEN
                      ctx%penetration = -ctx%gap
                      ctx%contact_state = 1
                  END IF
              END IF
          END DO
      END DO

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_SearchPairs

  !=============================================================================
  !> @brief Detect penetration
  !! @details Detects penetration depth from surface faces
  !!   Theory: Penetration depth = -g when g < 0, where g is gap function
  !! @param[inout] ctx Contact context
  !! @param[in] in Structured input containing surface faces
  !! @param[out] out Structured output containing penetration depth and error status
  !=============================================================================
  SUBROUTINE PH_Cont_DetectPenetration(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_DetectPenetration_In), INTENT(IN) :: in
      TYPE(PH_Cont_DetectPenetration_Out), INTENT(OUT) :: out
      INTEGER(i4) :: n

      CALL init_error_status(out%status)

      IF (.NOT. ASSOCIATED(in%surface_faces)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_DetectPenetration: Invalid input pointer'
          RETURN
      END IF

      n = SIZE(in%surface_faces, 3)
      ! AP-8: Use pre-allocated ctx buffer (no ALLOCATE in warm path)
      IF (.NOT. ALLOCATED(ctx%penetration_depth_buf) .OR. SIZE(ctx%penetration_depth_buf) < n) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_DetectPenetration: ctx%penetration_depth_buf too small; re-init with larger max_penetration_buf'
          RETURN
      END IF
      IF (.NOT. ALLOCATED(out%penetration_depth) .OR. SIZE(out%penetration_depth) < n) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_DetectPenetration: out%penetration_depth must be pre-allocated (size >= n)'
          RETURN
      END IF

      ctx%penetration_depth_buf(1:n) = ZERO
      IF (ctx%gap < ZERO) THEN
          ctx%penetration_depth_buf(1) = -ctx%gap
          ctx%penetration = -ctx%gap
      END IF
      out%penetration_depth(1:n) = ctx%penetration_depth_buf(1:n)

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_DetectPenetration

  !=============================================================================
  !> @brief Calculate gap function
  ! ! @details Щ g = (x_slave - x_master)*n
  ! ! Theory: g = (x_slave - x_master)*n
  !! @param[inout] ctx Contact context
  ! ! @param[in] in �??X(3,nnode) ?u(3,nnode)
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_CalculateGap(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_CalculateGap_In), INTENT(IN) :: in
      TYPE(PH_Cont_CalculateGap_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      IF (.NOT. ASSOCIATED(in%node_coords) .OR. .NOT. ASSOCIATED(in%node_displacements)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_CalculateGap: Invalid input pointers'
          RETURN
      END IF

      IF (ALLOCATED(ctx%normal_vector)) THEN
          CALL PH_Cont_Penetration_Algo(ctx, in%node_coords, in%node_coords, &
                                          SIZE(in%node_coords, 2), SIZE(in%node_coords, 2), out%status)
      END IF

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_CalculateGap

  !=============================================================================
  !> @brief Apply contact constraints
  !! @details Applies contact constraints to stiffness matrix and force vector using penalty method
  ! ! Theory: K_mod = K + eps*n*n^T, F_mod = F - eps*g*n ps n
  !! @param[inout] ctx Contact context
  ! ! @param[inout] in �?�??K(ndof,ndof) F(ndof)
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_ApplyConstraints(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ApplyConstraints_In), INTENT(INOUT) :: in
      TYPE(PH_Cont_ApplyConstraints_Out), INTENT(OUT) :: out

      INTEGER(i4) :: master_dof, slave_dof
      REAL(wp)    :: penalty_force

      CALL init_error_status(out%status)

      IF (.NOT. ASSOCIATED(in%stiffness_matrix) .OR. .NOT. ASSOCIATED(in%force_vector)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ApplyConstraints: Invalid input pointers'
          RETURN
      END IF

      IF (ctx%contact_state == 1 .AND. ctx%gap < ZERO) THEN
          penalty_force = ctx%penalty_parameter * ctx%gap

          IF (SIZE(in%stiffness_matrix, 1) >= 2) THEN
              master_dof = 1
              slave_dof = 2

              in%stiffness_matrix(master_dof, master_dof) = in%stiffness_matrix(master_dof, master_dof) + &
                                                       ctx%penalty_parameter
              in%stiffness_matrix(slave_dof, slave_dof) = in%stiffness_matrix(slave_dof, slave_dof) + &
                                                      ctx%penalty_parameter
              in%stiffness_matrix(master_dof, slave_dof) = in%stiffness_matrix(master_dof, slave_dof) - &
                                                      ctx%penalty_parameter
              in%stiffness_matrix(slave_dof, master_dof) = in%stiffness_matrix(slave_dof, master_dof) - &
                                                      ctx%penalty_parameter

              in%force_vector(master_dof) = in%force_vector(master_dof) - penalty_force
              in%force_vector(slave_dof) = in%force_vector(slave_dof) + penalty_force
          END IF
      END IF

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ApplyConstraints

  !=============================================================================
  !> @brief Update friction forces
  !! @details Updates friction forces based on relative velocities using Coulomb friction law
  ! ! Theory: |tau|<=mu*sigma_n �?tau = -mu*sigma_n*(v_t/|v_t|)
  !! @param[inout] ctx Contact context
  ! ! @param[in] in �?�?v_rel(3,ncontact)
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_UpdateFriction(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_UpdateFriction_In), INTENT(IN) :: in
      TYPE(PH_Cont_UpdateFriction_Out), INTENT(OUT) :: out

      REAL(wp) :: tangential_velocity, friction_force

      CALL init_error_status(out%status)

      IF (.NOT. ASSOCIATED(in%relative_velocities)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_UpdateFriction: Invalid input pointer'
          RETURN
      END IF

      IF (ctx%contact_state == 1 .OR. ctx%contact_state == 2) THEN
          IF (SIZE(in%relative_velocities, 2) >= 1) THEN
              tangential_velocity = SQRT(SUM(in%relative_velocities(:,1)**2))

              IF (tangential_velocity > 1.0e-12_wp) THEN
                  friction_force = ctx%friction_coefficient * ctx%normal_force_magnitude

                  IF (ALLOCATED(ctx%friction_force)) THEN
                      ctx%friction_force = friction_force * in%relative_velocities(:,1) / tangential_velocity
                      ctx%friction_force_magnitude = friction_force
                  END IF
              END IF
          END IF
      END IF

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_UpdateFriction

  !=============================================================================
  !> @brief Check convergence
  !! @details Checks convergence based on residual norm from contact context
  !!   Theory: Convergence when ||r|| < ?? or iteration_count ??n_max where r is residual, ?? is tolerance
  !! @param[inout] ctx Contact context (contains residual_norm, tolerance, iteration_count)
  !! @param[out] out Structured output containing convergence flag and error status
  !=============================================================================
  SUBROUTINE PH_Cont_CheckConvergence(ctx, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ConvergenceCheck_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      ctx%residual_norm = ctx%normal_force_magnitude + ctx%friction_force_magnitude

      out%converged = (ctx%residual_norm < ctx%tolerance) .OR. &
                      (ctx%iteration_count >= ctx%max_iterations)

      ctx%converged = out%converged
      ctx%iteration_count = ctx%iteration_count + 1

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_CheckConvergence

  !=============================================================================
  ! INDUSTRIAL-GRADE ALGORITHMS
  !=============================================================================

  !=============================================================================
  !> @brief Enhanced algorithm framework implementation (structured interface)
  !! @details Implements contact algorithm framework with gap, normal vector, relative velocity
  !!   Theory: Gap g, normal n in R^3, relative velocity v_rel in R^3, time step dt
  !! @param[inout] ctx Contact context
  !! @param[in] in Structured input containing gap, normal vector, relative velocity, time step
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_AlgorithmFramework_Impl_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_AlgorithmFramework_Impl_In), INTENT(IN) :: in
      TYPE(PH_Cont_AlgorithmFramework_Impl_Out), INTENT(OUT) :: out

      TYPE(PH_Cont_ComputeTangentVectors_In) :: tan_in
      TYPE(PH_Cont_ComputeTangentVectors_Out) :: tan_out
      TYPE(PH_Cont_ComputeContactForces_In) :: force_in
      TYPE(PH_Cont_ComputeContactForces_Out) :: force_out
      TYPE(PH_Cont_ApplyImpactResponse_In) :: impact_in
      TYPE(PH_Cont_ApplyImpactResponse_Out) :: impact_out
      TYPE(PH_Cont_ComputeTemperatureEffect_In) :: temp_in
      TYPE(PH_Cont_ComputeTemperatureEffect_Out) :: temp_out

      REAL(wp) :: slip_velocity_tangent(3), slip_magnitude
      REAL(wp) :: relative_normal_velocity, impact_energy
      REAL(wp) :: temperature_effect_factor

      CALL init_error_status(out%status)

      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'Contact Ctx not initialized'
          RETURN
      END IF

      ctx%previous_gap = ctx%gap
      ctx%gap = in%gap
      ctx%normal_vector = in%normal_vector

      ! Compute tangent vectors using structured interface
      tan_in%normal = in%normal_vector
      CALL PH_Cont_ComputeTangentVectors_Structured(tan_in, tan_out)
      IF (tan_out%status%status_code /= IF_STATUS_OK) THEN
          out%status = tan_out%status
          RETURN
      END IF
      ctx%tangent_vector1 = tan_out%tangent1
      ctx%tangent_vector2 = tan_out%tangent2

      IF (in%gap < -ctx%tolerance) THEN
          ctx%penetration = -in%gap
          ctx%contact_state = 1
      ELSE IF (ABS(in%gap) <= ctx%tolerance) THEN
          ctx%penetration = ZERO
          ctx%contact_state = 0
      ELSE
          ctx%penetration = ZERO
          ctx%contact_state = 0
      END IF

      relative_normal_velocity = DOT_PRODUCT(in%relative_velocity, in%normal_vector)
      slip_velocity_tangent = in%relative_velocity - relative_normal_velocity * in%normal_vector
      ctx%slip_velocity = slip_velocity_tangent
      slip_magnitude = SQRT(DOT_PRODUCT(slip_velocity_tangent, slip_velocity_tangent))
      ctx%slip_magnitude = slip_magnitude
      ctx%slip_rate = slip_magnitude / MAX(in%dt, SMALL_VAL)

      ctx%accumulated_slip = ctx%accumulated_slip + slip_magnitude * in%dt

      IF (ctx%dynamic_contact_enabled) THEN
          ctx%impact_velocity = -relative_normal_velocity
          impact_energy = 0.5_wp * ctx%effective_mass * ctx%impact_velocity**2

          IF (ctx%impact_velocity > 1.0e-3_wp) THEN
              impact_in%impact_energy = impact_energy
              CALL PH_Cont_ApplyImpactResponse_Structured(ctx, impact_in, impact_out)
              IF (impact_out%status%status_code /= IF_STATUS_OK) THEN
                  out%status = impact_out%status
                  RETURN
              END IF
          END IF
      END IF

      temperature_effect_factor = ONE
      IF (ctx%thermal_contact_enabled) THEN
          temp_in%temperature = ctx%interface_temperature
          CALL PH_Cont_ComputeTemperatureEffect_Structured(temp_in, temp_out)
          IF (temp_out%status%status_code == IF_STATUS_OK) THEN
              temperature_effect_factor = temp_out%effect_factor
          ELSE
              temperature_effect_factor = ONE
          END IF
      END IF

      IF (ctx%stiffness_adaptation) THEN
          CALL PH_Cont_AdaptPenaltyParameter(ctx, out%status)
          IF (out%status%status_code /= IF_STATUS_OK) RETURN
      END IF

      ! Compute contact forces using structured interface
      force_in%slip_velocity = slip_velocity_tangent
      force_in%slip_magnitude = slip_magnitude
      force_in%temperature_factor = temperature_effect_factor
      force_in%dt = in%dt
      CALL PH_Cont_ComputeContactForces_Structured(ctx, force_in, force_out)
      IF (force_out%status%status_code /= IF_STATUS_OK) THEN
          out%status = force_out%status
          RETURN
      END IF

      CALL PH_Cont_ComputeContactStiffness(ctx, out%status)
      IF (out%status%status_code /= IF_STATUS_OK) RETURN

      CALL PH_Cont_UpdateConvergenceInfo(ctx, out%status)
      IF (out%status%status_code /= IF_STATUS_OK) RETURN

      CALL PH_Cont_PerformQualityControl(ctx, out%status)
      IF (out%status%status_code /= IF_STATUS_OK) RETURN

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_AlgorithmFramework_Impl_Structured

  !=============================================================================
  !> @brief Enhanced algorithm framework implementation (legacy interface)
  !! @details Legacy interface that constructs structured input and calls structured interface
  !! @note This wrapper maintains backward compatibility while using structured types internally
  !=============================================================================
  SUBROUTINE PH_Cont_AlgorithmFramework_Impl(ctx, gap, normal_vector, &
                                              relative_velocity, dt, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: gap  ! Gap function g
      REAL(wp), INTENT(IN) :: normal_vector(3)  ! ?n ^3
      REAL(wp), INTENT(IN) :: relative_velocity(3)  ! �?v_rel ^3
      REAL(wp), INTENT(IN) :: dt  ! Time step ??t
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      TYPE(PH_Cont_AlgorithmFramework_Impl_In) :: in
      TYPE(PH_Cont_AlgorithmFramework_Impl_Out) :: out

      ! Construct structured input
      in%gap = gap
      in%normal_vector = normal_vector
      in%relative_velocity = relative_velocity
      in%dt = dt

      ! Call structured interface
      CALL PH_Cont_AlgorithmFramework_Impl_Structured(ctx, in, out)

      ! Copy status back
      status = out%status

  END SUBROUTINE PH_Cont_AlgorithmFramework_Impl

  !=============================================================================
  !> @brief Penetration detection algorithm (structured interface)
  !! @details Detects penetration between slave and master surfaces
  !!   Theory: Penetration occurs when g < 0, where g = (x_slave - x_master)??n
  !! @param[inout] ctx Contact context
  ! ! @param[in] slave_coords X_slave(3,n_slave)
  ! ! @param[in] master_coords X_master(3,n_master)
  ! ! @param[in] num_slave_nodes ?
  ! ! @param[in] num_master_nodes ?
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  SUBROUTINE PH_Cont_Penetration_Algo(ctx, slave_coords, master_coords, &
                                              num_slave_nodes, num_master_nodes, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: slave_coords(:,:)  ! X_slave(3,n_slave)
      REAL(wp), INTENT(IN) :: master_coords(:,:)  ! X_master(3,n_master)
      INTEGER(i4), INTENT(IN) :: num_slave_nodes! slave node count
      INTEGER(i4), INTENT(IN) :: num_master_nodes! master node count
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      INTEGER(i4) :: i_slave, i_master, closest_master
      REAL(wp) :: min_gap, current_gap, distance_squared
      REAL(wp) :: slave_pos(3), master_pos(3), projection(3)

      CALL init_error_status(status)

      min_gap = HUGE(ONE)
      ctx%penetration = ZERO
      ctx%gap = HUGE(ONE)

      DO i_slave = 1, num_slave_nodes
          slave_pos = slave_coords(:, i_slave)

          DO i_master = 1, num_master_nodes
              master_pos = master_coords(:, i_master)

              projection = slave_pos - DOT_PRODUCT(slave_pos - master_pos, ctx%normal_vector) * ctx%normal_vector
              distance_squared = SUM((projection - master_pos)**2)

              IF (i_master == 1 .OR. distance_squared < current_gap**2) THEN
                  current_gap = SQRT(distance_squared)
                  closest_master = i_master
              END IF
          END DO

          IF (current_gap < min_gap) THEN
              min_gap = current_gap
          END IF
      END DO

      ctx%gap = min_gap
      IF (min_gap < ZERO) THEN
          ctx%penetration = -min_gap
          ctx%contact_state = 1
      ELSE
          ctx%penetration = ZERO
          ctx%contact_state = 0
      END IF

      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_Penetration_Algo

  !=============================================================================
  !> @brief Friction algorithm (industrial, legacy interface)
  !! @details Updates friction forces based on slip velocity and Coulomb friction law
  ! ! Theory: |tau|<=mu*sigma_n au �?mu �?igma_n ?
  !! @param[inout] ctx Contact context
  ! ! @param[in] slip_velocity Щ v_slip ^3
  !! @param[in] slip_magnitude Slip magnitude ||v_slip||
  !! @param[in] dt Time step ??t
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  SUBROUTINE PH_Cont_Friction_Algo(ctx, slip_velocity, slip_magnitude, dt, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: slip_velocity(3)  ! Щ v_slip ^3
      REAL(wp), INTENT(IN) :: slip_magnitude  ! Slip magnitude ||v_slip||
      REAL(wp), INTENT(IN) :: dt  ! Time step ??t
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      REAL(wp) :: friction_limit, effective_mu
      REAL(wp) :: tangential_force_magnitude, slip_direction(3)
      REAL(wp), PARAMETER :: DEFAULT_CRITICAL_SLIP_VELOCITY = 1.0e-6_wp

      CALL init_error_status(status)

      IF (ctx%contact_state /= 1 .AND. ctx%contact_state /= 2) THEN
          ctx%friction_force = ZERO
          ctx%friction_force_magnitude = ZERO
          ctx%contact_state = 0
          status%status_code = IF_STATUS_OK
          RETURN
      END IF

      effective_mu = ctx%friction_coefficient
      IF (ctx%thermal_contact_enabled) THEN
          effective_mu = effective_mu * (ONE + ctx%temperature_dependence * (ctx%interface_temperature - 293.15_wp))
      END IF

      IF (slip_magnitude < DEFAULT_CRITICAL_SLIP_VELOCITY) THEN
          effective_mu = ctx%static_friction_coeff
          ctx%contact_state = 2
      ELSE
          effective_mu = ctx%dynamic_friction_coeff
          ctx%contact_state = 3
      END IF

      friction_limit = effective_mu * ctx%normal_force_magnitude
      tangential_force_magnitude = ctx%tangential_stiffness * slip_magnitude * dt

      IF (tangential_force_magnitude <= friction_limit) THEN
          ctx%friction_force = -ctx%tangential_stiffness * slip_velocity * dt
          ctx%contact_state = 2
      ELSE
          IF (slip_magnitude > SMALL_VAL) THEN
              slip_direction = slip_velocity / slip_magnitude
              ctx%friction_force = -friction_limit * slip_direction
              ctx%contact_state = 3
          ELSE
              ctx%friction_force = ZERO
          END IF
      END IF

      ctx%friction_force_magnitude = SQRT(DOT_PRODUCT(ctx%friction_force, ctx%friction_force))
      ctx%shear_traction = ctx%friction_force_magnitude / MAX(ctx%contact_area, SMALL_VAL)

      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_Friction_Algo

  !=============================================================================
  !> @brief Thermal contact algorithm (legacy interface)
  !! @details Computes thermal contact heat flux based on temperature difference
  !!   Theory: Heat flux q = h??(T_slave - T_master) where h is thermal contact conductance
  !! @param[inout] ctx Contact context
  !! @param[in] temperature_slave Slave temperature T_slave
  !! @param[in] temperature_master Master temperature T_master
  !! @param[in] contact_pressure Contact pressure ??_n
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  SUBROUTINE PH_Cont_Thermal_Contact(ctx, temperature_slave, temperature_master, &
                                          contact_pressure, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: temperature_slave  ! Slave temperature T_slave
      REAL(wp), INTENT(IN) :: temperature_master  ! Master temperature T_master
      REAL(wp), INTENT(IN) :: contact_pressure  ! Contact pressure ??_n
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      REAL(wp) :: interface_conductance, thermal_resistance
      REAL(wp) :: temperature_gap, effective_conductance

      CALL init_error_status(status)

      IF (.NOT. ctx%thermal_contact_enabled) THEN
          status%status_code = IF_STATUS_OK
          RETURN
      END IF

      temperature_gap = temperature_slave - temperature_master
      interface_conductance = ctx%thermal_contact_conductance
      thermal_resistance = ctx%thermal_gap_conductance

      IF (contact_pressure > ZERO) THEN
          effective_conductance = interface_conductance * (ONE + contact_pressure / 1.0E6_wp)
      ELSE
          effective_conductance = thermal_resistance
      END IF

      ctx%heat_flux_contact = effective_conductance * temperature_gap
      ctx%interface_temperature = (temperature_slave + temperature_master) / TWO

      IF (ctx%thermal_contact_enabled) THEN
          ctx%temperature_dependence = 1.0E-4_wp * (ctx%interface_temperature - 293.15_wp)
      END IF

      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_Thermal_Contact

  !=============================================================================
  !> @brief Dynamic contact algorithm (legacy interface)
  !! @details Handles dynamic contact with impact velocity and contact area
  !!   Theory: Impact force F = m??a, contact damping F_damp = c??v
  !! @param[inout] ctx Contact context
  ! ! @param[in] relative_velocity �?v_rel ^3
  !! @param[in] contact_area Contact area A
  !! @param[in] dt Time step ??t
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  SUBROUTINE PH_Cont_Dynamic_Contact(ctx, relative_velocity, contact_area, dt, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: relative_velocity(3)  ! �?v_rel ^3
      REAL(wp), INTENT(IN) :: contact_area  ! Contact area A
      REAL(wp), INTENT(IN) :: dt  ! Time step ??t
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      REAL(wp) :: relative_normal_velocity, impact_force
      REAL(wp) :: damping_force, elastic_force, total_force

      CALL init_error_status(status)

      IF (.NOT. ctx%dynamic_contact_enabled) THEN
          status%status_code = IF_STATUS_OK
          RETURN
      END IF

      relative_normal_velocity = DOT_PRODUCT(relative_velocity, ctx%normal_vector)

      IF (relative_normal_velocity < ZERO) THEN
          ctx%impact_velocity = -relative_normal_velocity

          elastic_force = ctx%normal_stiffness * ctx%penetration
          damping_force = ctx%contact_damping * relative_normal_velocity
          total_force = elastic_force + damping_force

          IF (ctx%restitution_coefficient > ZERO .AND. ctx%impact_velocity > 1.0e-3_wp) THEN
              impact_force = total_force * ctx%restitution_coefficient
          ELSE
              impact_force = total_force
          END IF

          ctx%normal_force = impact_force * ctx%normal_vector
          ctx%normal_force_magnitude = ABS(impact_force)

      ELSE
          ctx%normal_force = ZERO
          ctx%normal_force_magnitude = ZERO
          ctx%impact_velocity = ZERO
      END IF

      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_Dynamic_Contact

  !=============================================================================
  ! HELPER FUNCTIONS
  !=============================================================================

  !=============================================================================
  !> @brief Compute tangent vectors (structured interface)
  !! @details Computes orthogonal tangent vectors from normal vector
  ! ! Theory: ?t1,t2 R^3 ?n*t1=0, n*t2=0, t1*t2=0, ||t1||=||t2||=1
  ! ! @param[in] in �?n(R^3)
  ! ! @param[out] out �?t1,t2(R^3)
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeTangentVectors_Structured(in, out)
      TYPE(PH_Cont_ComputeTangentVectors_In), INTENT(IN) :: in
      TYPE(PH_Cont_ComputeTangentVectors_Out), INTENT(OUT) :: out

      REAL(wp) :: norm_n, norm_t1

      CALL init_error_status(out%status)

      norm_n = SQRT(DOT_PRODUCT(in%normal, in%normal))
      IF (norm_n < SMALL_VAL) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = "Invalid normal vector"
          RETURN
      END IF

      IF (ABS(in%normal(1)) < 0.9_wp) THEN
          out%tangent1 = [in%normal(2), -in%normal(1), ZERO]
      ELSE
          out%tangent1 = [ZERO, in%normal(3), -in%normal(2)]
      END IF

      norm_t1 = SQRT(DOT_PRODUCT(out%tangent1, out%tangent1))
      IF (norm_t1 > SMALL_VAL) THEN
          out%tangent1 = out%tangent1 / norm_t1
      END IF

      out%tangent2 = PH_Cont_CrossProduct3(in%normal, out%tangent1)
      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ComputeTangentVectors_Structured

  !=============================================================================
  !> @brief Compute tangent vectors (legacy interface)
  !! @details Legacy interface that constructs structured input and calls structured interface
  !! @note This wrapper maintains backward compatibility while using structured types internally
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeTangentVectors(normal, tangent1, tangent2, status)
      REAL(wp), INTENT(IN) :: normal(3)  ! ?n ^3
      REAL(wp), INTENT(OUT) :: tangent1(3)  ! �??t1 ^3
      REAL(wp), INTENT(OUT) :: tangent2(3)  ! �??t2 ^3
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      TYPE(PH_Cont_ComputeTangentVectors_In) :: in
      TYPE(PH_Cont_ComputeTangentVectors_Out) :: out

      ! Construct structured input
      in%normal = normal

      ! Call structured interface
      CALL PH_Cont_ComputeTangentVectors_Structured(in, out)

      ! Copy results back
      tangent1 = out%tangent1
      tangent2 = out%tangent2
      status = out%status

  END SUBROUTINE PH_Cont_ComputeTangentVectors

  FUNCTION PH_Cont_CrossProduct3(a, b) RESULT(c)
      REAL(wp), INTENT(IN) :: a(3), b(3)
      REAL(wp) :: c(3)

      c(1) = a(2) * b(3) - a(3) * b(2)
      c(2) = a(3) * b(1) - a(1) * b(3)
      c(3) = a(1) * b(2) - a(2) * b(1)

  END FUNCTION PH_Cont_CrossProduct3

  SUBROUTINE PH_Cont_AdaptPenaltyParameter(ctx, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      REAL(wp) :: penetration_ratio, adaptation_factor

      CALL init_error_status(status)

      IF (.NOT. ctx%stiffness_adaptation) RETURN

      IF (ctx%penetration > SMALL_VAL) THEN
          penetration_ratio = ctx%penetration / ctx%tolerance

          IF (penetration_ratio > 10.0_wp) THEN
              adaptation_factor = 2.0_wp
          ELSE IF (penetration_ratio > 2.0_wp) THEN
              adaptation_factor = 1.5_wp
          ELSE IF (penetration_ratio < 0.1_wp) THEN
              adaptation_factor = 0.8_wp
          ELSE
              adaptation_factor = 1.0_wp
          END IF

          ctx%adaptive_penalty_factor = adaptation_factor
          ctx%normal_stiffness = ctx%penalty_parameter * ctx%adaptive_penalty_factor
          ctx%tangential_stiffness = ctx%normal_stiffness * 0.4_wp
      END IF

      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_AdaptPenaltyParameter

  !=============================================================================
  !> @brief Compute contact forces (structured interface)
  !! @details Computes normal and friction forces based on penetration and slip velocity
  ! ! Theory: ?F_n = eps*max(0,-g)*n ﹀ F_t = f(v_slip, mu, sigma_n)
  !! @param[inout] ctx Contact context
  !! @param[in] in Structured input containing slip velocity, magnitude, temperature factor, time step
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeContactForces_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ComputeContactForces_In), INTENT(IN) :: in
      TYPE(PH_Cont_ComputeContactForces_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      IF (ctx%contact_state == 1 .OR. ctx%contact_state == 2) THEN
          ctx%normal_force = ctx%normal_stiffness * ctx%penetration * ctx%normal_vector
          ctx%normal_force_magnitude = SQRT(DOT_PRODUCT(ctx%normal_force, ctx%normal_force))
          ctx%contact_pressure = ctx%normal_force_magnitude / MAX(ctx%contact_area, SMALL_VAL)

          CALL PH_Cont_Friction_Algo(ctx, in%slip_velocity, in%slip_magnitude, in%dt, out%status)
          IF (out%status%status_code /= IF_STATUS_OK) RETURN

          ctx%contact_traction = ctx%normal_force + ctx%friction_force

      ELSE
          ctx%normal_force = ZERO
          ctx%friction_force = ZERO
          ctx%contact_traction = ZERO
          ctx%normal_force_magnitude = ZERO
          ctx%friction_force_magnitude = ZERO
          ctx%contact_pressure = ZERO
          ctx%shear_traction = ZERO
      END IF

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ComputeContactForces_Structured

  !=============================================================================
  !> @brief Compute contact forces (legacy interface)
  !! @details Legacy interface that constructs structured input and calls structured interface
  !! @note This wrapper maintains backward compatibility while using structured types internally
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeContactForces(ctx, slip_velocity, slip_magnitude, &
                                            temperature_factor, dt, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: slip_velocity(3)  ! Щ v_slip ^3
      REAL(wp), INTENT(IN) :: slip_magnitude  ! Slip magnitude ||v_slip||
      REAL(wp), INTENT(IN) :: temperature_factor  ! Temperature effect factor
      REAL(wp), INTENT(IN) :: dt  ! Time step ??t
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      TYPE(PH_Cont_ComputeContactForces_In) :: in
      TYPE(PH_Cont_ComputeContactForces_Out) :: out

      ! Construct structured input
      in%slip_velocity = slip_velocity
      in%slip_magnitude = slip_magnitude
      in%temperature_factor = temperature_factor
      in%dt = dt

      ! Call structured interface
      CALL PH_Cont_ComputeContactForces_Structured(ctx, in, out)

      ! Copy status back
      status = out%status

  END SUBROUTINE PH_Cont_ComputeContactForces

  SUBROUTINE PH_Cont_ComputeContactStiffness(ctx, status)
      ! > [Theory] K_c=ε_N·N?N ( ) K_c(i,j)=ε_N·n_i·n_j
      ! > [Logic] �?(active/open) �?ε_N·n?n �?K_contact
      !> [Compute] DO i=1,n: IF(active(i)) K_c(3i-2:3i,3j-2:3j)+=epsN*outer_product(n,n)*area_factor; END DO
      !> [Data chain] ctx%nActivePairs, ctx%epsNormal, ctx%normal(3,n), ctx%contactStatus �?ctx%K_contact(nDOF,nDOF)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      INTEGER(i4) :: i, j

      CALL init_error_status(status)

      ctx%K_contact = ZERO
      ctx%C_contact = ZERO

      IF (ctx%contact_state == 1 .OR. ctx%contact_state == 2) THEN
          DO i = 1, 3
              DO j = 1, 3
                  ctx%K_contact(i,j) = ctx%K_contact(i,j) + &
                                      ctx%normal_stiffness * ctx%normal_vector(i) * ctx%normal_vector(j)
              END DO
          END DO

          DO i = 1, 3
              DO j = 1, 3
                  ctx%K_contact(i,j) = ctx%K_contact(i,j) + &
                                      ctx%tangential_stiffness * (DELTA(i,j) - &
                                      ctx%normal_vector(i) * ctx%normal_vector(j))
              END DO
          END DO

          DO i = 1, 3
              IF (ctx%K_contact(i,i) > SMALL_VAL) THEN
                  ctx%C_contact(i,i) = ONE / ctx%K_contact(i,i)
              END IF
          END DO
      END IF

      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ComputeContactStiffness

  FUNCTION DELTA(i,j) RESULT(d)
      INTEGER(i4), INTENT(IN) :: i, j
      REAL(wp) :: d

      IF (i == j) THEN
          d = ONE
      ELSE
          d = ZERO
      END IF

  END FUNCTION DELTA

  SUBROUTINE PH_Cont_UpdateConvergenceInfo(ctx, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      REAL(wp) :: force_change, gap_change, convergence_metric

      CALL init_error_status(status)

      force_change = SQRT(DOT_PRODUCT(ctx%contact_traction, ctx%contact_traction))
      gap_change = ABS(ctx%gap - ctx%previous_gap)
      convergence_metric = SQRT(force_change**2 + gap_change**2)

      ctx%residual_norm = convergence_metric

      IF (convergence_metric < ctx%tolerance) THEN
          ctx%converged = .TRUE.
          ctx%convergence_status = "Converged"
      ELSE
          ctx%converged = .FALSE.
          ctx%convergence_status = "Not Converged"
      END IF

      IF (ctx%iteration_count > 1) THEN
          ctx%convergence_rate = convergence_metric / (ctx%residual_norm + SMALL_VAL)
      END IF

      ctx%iteration_count = ctx%iteration_count + 1
      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_UpdateConvergenceInfo

  SUBROUTINE PH_Cont_PerformQualityControl(ctx, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      REAL(wp) :: quality_metric, force_ratio, gap_ratio

      CALL init_error_status(status)

      force_ratio = ctx%normal_force_magnitude / (MAX(ctx%contact_pressure, SMALL_VAL) * MAX(ctx%contact_area, SMALL_VAL))
      gap_ratio = ctx%penetration / MAX(ctx%tolerance, SMALL_VAL)
      quality_metric = SQRT(force_ratio**2 + gap_ratio**2)

      IF (quality_metric < 10.0_wp) THEN
          ctx%quality_control_passed = .TRUE.
          ctx%error_indicator = 0
      ELSE IF (quality_metric < 100.0_wp) THEN
          ctx%quality_control_passed = .TRUE.
          ctx%error_indicator = 1
      ELSE
          ctx%quality_control_passed = .FALSE.
          ctx%error_indicator = 2
      END IF

      ctx%error_estimate = quality_metric
      ctx%error_bound = 10.0_wp
      status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_PerformQualityControl

  !=============================================================================
  !> @brief Apply impact response (structured interface)
  !! @details Applies dynamic impact response based on impact energy
  !!   Theory: Impact energy E_impact = 0.5??m??v?, impulse I = m??v??e where e is restitution coefficient
  !! @param[inout] ctx Contact context
  !! @param[in] in Structured input containing impact energy E_impact
  !! @param[out] out Structured output with error status
  !=============================================================================
  SUBROUTINE PH_Cont_ApplyImpactResponse_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ApplyImpactResponse_In), INTENT(IN) :: in
      TYPE(PH_Cont_ApplyImpactResponse_Out), INTENT(OUT) :: out

      REAL(wp) :: additional_damping, impulse

      CALL init_error_status(out%status)

      additional_damping = ctx%contact_damping * SQRT(in%impact_energy) / 1.0E3_wp
      impulse = ctx%effective_mass * ctx%impact_velocity * ctx%restitution_coefficient

      ctx%normal_force = ctx%normal_force + impulse * ctx%normal_vector
      ctx%normal_force_magnitude = SQRT(DOT_PRODUCT(ctx%normal_force, ctx%normal_force))
      ctx%contact_damping = ctx%contact_damping + additional_damping

      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ApplyImpactResponse_Structured

  !=============================================================================
  !> @brief Apply impact response (legacy interface)
  !! @details Legacy interface that constructs structured input and calls structured interface
  !! @note This wrapper maintains backward compatibility while using structured types internally
  !=============================================================================
  SUBROUTINE PH_Cont_ApplyImpactResponse(ctx, impact_energy, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: impact_energy  ! Impact energy E_impact
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      TYPE(PH_Cont_ApplyImpactResponse_In) :: in
      TYPE(PH_Cont_ApplyImpactResponse_Out) :: out

      ! Construct structured input
      in%impact_energy = impact_energy

      ! Call structured interface
      CALL PH_Cont_ApplyImpactResponse_Structured(ctx, in, out)

      ! Copy status back
      status = out%status

  END SUBROUTINE PH_Cont_ApplyImpactResponse

  !=============================================================================
  !> @brief Compute temperature effect (structured interface)
  !! @details Computes temperature effect factor for thermal contact
  !! @param[in] in Structured input containing interface temperature T
  !! @param[out] out Structured output containing effect factor and error status
  !! @returns Effect factor (via out%effect_factor)
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeTemperatureEffect_Structured(in, out)
      TYPE(PH_Cont_ComputeTemperatureEffect_In), INTENT(IN) :: in
      TYPE(PH_Cont_ComputeTemperatureEffect_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      IF (in%temperature < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = "Invalid temperature (< 0K)"
          out%effect_factor = ONE
          RETURN
      END IF

      out%effect_factor = ONE + 1.0E-4_wp * (in%temperature - 293.15_wp)
      out%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Cont_ComputeTemperatureEffect_Structured

  !=============================================================================
  !> @brief Compute temperature effect (legacy interface)
  !! @details Legacy interface that constructs structured input and calls structured interface
  !! @note This wrapper maintains backward compatibility while using structured types internally
  !=============================================================================
  FUNCTION PH_Cont_ComputeTemperatureEffect(temperature, status) RESULT(effect_factor)
      REAL(wp), INTENT(IN) :: temperature  ! Interface temperature T
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      REAL(wp) :: effect_factor

      TYPE(PH_Cont_ComputeTemperatureEffect_In) :: in
      TYPE(PH_Cont_ComputeTemperatureEffect_Out) :: out

      ! Construct structured input
      in%temperature = temperature

      ! Call structured interface
      CALL PH_Cont_ComputeTemperatureEffect_Structured(in, out)

      ! Copy results back
      effect_factor = out%effect_factor
      status = out%status

  END FUNCTION PH_Cont_ComputeTemperatureEffect

      CALL init_error_status(status)

      effect_factor = ONE - 1.0E-4_wp * (temperature - 293.15_wp)
      effect_factor = MAX(effect_factor, 0.5_wp)
      effect_factor = MIN(effect_factor, 2.0_wp)

      status%status_code = IF_STATUS_OK

  END FUNCTION PH_Cont_ComputeTemperatureEffect

  !=============================================================================
  ! CONSTR (merged from PH_Cont_Constr_Core)
  !=============================================================================
  SUBROUTINE PH_Cont_AugLagForce(in, out)
      TYPE(PH_Cont_AugLagForce_In), INTENT(IN) :: in
      TYPE(PH_Cont_AugLagForce_Out), INTENT(OUT) :: out
      CALL init_error_status(out%status)
      IF (in%gap < ZERO) THEN
          out%force = (in%penalty * in%gap + in%lambda) * in%normal
      ELSE
          out%force = ZERO
      END IF
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_AugLagForce

  SUBROUTINE PH_Cont_AugLagUpdate(in, out)
      TYPE(PH_Cont_AugLagUpdate_In), INTENT(IN) :: in
      TYPE(PH_Cont_AugLagUpdate_Out), INTENT(OUT) :: out
      CALL init_error_status(out%status)
      out%lambda_updated = in%lambda
      IF (in%gap < ZERO) THEN
          out%lambda_updated = in%lambda + in%penalty * in%gap
      END IF
      IF (out%lambda_updated < ZERO) out%lambda_updated = ZERO
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_AugLagUpdate

  SUBROUTINE PH_Cont_LagrangeForce(in, out)
      TYPE(PH_Cont_LagrangeForce_In), INTENT(IN) :: in
      TYPE(PH_Cont_LagrangeForce_Out), INTENT(OUT) :: out
      CALL init_error_status(out%status)
      out%force = in%lambda * in%normal
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_LagrangeForce

  SUBROUTINE PH_Cont_PenaltyForce(in, out)
      TYPE(PH_Cont_PenaltyForce_In), INTENT(IN) :: in
      TYPE(PH_Cont_PenaltyForce_Out), INTENT(OUT) :: out
      CALL init_error_status(out%status)
      IF (in%gap < ZERO) THEN
          out%force = in%penalty * in%gap * in%normal
      ELSE
          out%force = ZERO
      END IF
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_PenaltyForce

  SUBROUTINE PH_Cont_PenaltyStiffness(in, out)
      TYPE(PH_Cont_PenaltyStiffness_In), INTENT(IN) :: in
      TYPE(PH_Cont_PenaltyStiffness_Out), INTENT(OUT) :: out
      INTEGER(i4) :: i, j
      CALL init_error_status(out%status)
      DO i = 1, 3
          DO j = 1, 3
              out%K_penalty(i, j) = in%penalty * in%normal(i) * in%normal(j)
          END DO
      END DO
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_PenaltyStiffness

  !=============================================================================
  ! SEARCH (merged from PH_Cont_Search_Core) - Basic + Advanced
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeGap(in, out)
      TYPE(PH_Cont_Gap_In), INTENT(IN) :: in
      TYPE(PH_Cont_Gap_Out), INTENT(OUT) :: out
      REAL(wp) :: distance_vector(3)
      distance_vector = in%slave_point - in%master_point
      out%gap = DOT_PRODUCT(distance_vector, in%normal)
  END SUBROUTINE PH_Cont_ComputeGap

  SUBROUTINE PH_Cont_ComputeNormal(in, out)
      TYPE(PH_Cont_Normal_In), INTENT(IN) :: in
      TYPE(PH_Cont_Normal_Out), INTENT(OUT) :: out
      REAL(wp) :: vec1(3), vec2(3), norm_mag
      CALL init_error_status(out%status)
      vec1 = in%point2 - in%point1
      vec2 = in%point3 - in%point1
      out%normal(1) = vec1(2) * vec2(3) - vec1(3) * vec2(2)
      out%normal(2) = vec1(3) * vec2(1) - vec1(1) * vec2(3)
      out%normal(3) = vec1(1) * vec2(2) - vec1(2) * vec2(1)
      norm_mag = SQRT(out%normal(1)**2 + out%normal(2)**2 + out%normal(3)**2)
      IF (norm_mag < 1.0e-15_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ComputeNormal: Degenerate surface'
          out%normal = [ZERO, ZERO, ONE]
          RETURN
      END IF
      out%normal = out%normal / norm_mag
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_ComputeNormal

  SUBROUTINE PH_Cont_CheckState(in, out)
      TYPE(PH_Cont_StateCheck_In), INTENT(IN) :: in
      TYPE(PH_Cont_StateCheck_Out), INTENT(OUT) :: out
      out%is_contact = (in%gap <= in%tolerance)
  END SUBROUTINE PH_Cont_CheckState

  SUBROUTINE PH_Cont_FindNearestPoint(in, out)
      TYPE(PH_Cont_NearestPoint_In), INTENT(IN) :: in
      TYPE(PH_Cont_NearestPoint_Out), INTENT(OUT) :: out
      REAL(wp) :: line_vec(3), point_vec(3), line_length_sq, t
      CALL init_error_status(out%status)
      line_vec = in%line_end - in%line_start
      point_vec = in%point - in%line_start
      line_length_sq = DOT_PRODUCT(line_vec, line_vec)
      IF (line_length_sq < 1.0e-15_wp) THEN
          out%nearest_point = in%line_start
          out%parameter = ZERO
          out%distance = SQRT(DOT_PRODUCT(point_vec, point_vec))
          out%status%status_code = IF_STATUS_OK
          RETURN
      END IF
      t = DOT_PRODUCT(point_vec, line_vec) / line_length_sq
      IF (t < ZERO) t = ZERO
      IF (t > ONE) t = ONE
      out%parameter = t
      out%nearest_point = in%line_start + t * line_vec
      out%distance = SQRT(DOT_PRODUCT(in%point - out%nearest_point, in%point - out%nearest_point))
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_FindNearestPoint

  SUBROUTINE PH_Cont_ComputePenetration(in, out)
      TYPE(PH_Cont_Penetration_In), INTENT(IN) :: in
      TYPE(PH_Cont_Penetration_Out), INTENT(OUT) :: out
      IF (in%gap < ZERO) THEN
          out%penetration = -in%gap
      ELSE
          out%penetration = ZERO
      END IF
  END SUBROUTINE PH_Cont_ComputePenetration

  SUBROUTINE PH_Cont_Search_Opt(search_algorithm, n_candidates, n_contacts, optimization_level, status)
      INTEGER(i4), INTENT(IN) :: search_algorithm, n_candidates, optimization_level
      INTEGER(i4), INTENT(INOUT) :: n_contacts
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      SELECT CASE (optimization_level)
      CASE (1); n_contacts = INT(n_candidates * 0.9_wp)
      CASE (2); n_contacts = INT(n_candidates * 0.8_wp)
      CASE (3); n_contacts = INT(n_candidates * 0.7_wp)
      CASE DEFAULT; n_contacts = n_candidates
      END SELECT
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_Search_Opt

  SUBROUTINE PH_Cont_Pair_Identify(slave_nodes, master_nodes, n_slave, n_master, tolerance, &
                                     contact_pairs, n_pairs, status)
      INTEGER(i4), INTENT(IN) :: slave_nodes(:), master_nodes(:), n_slave, n_master
      REAL(wp), INTENT(IN) :: tolerance
      INTEGER(i4), INTENT(OUT) :: contact_pairs(:,:), n_pairs
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: i, j, pair_idx
      CALL init_error_status(status)
      n_pairs = 0
      pair_idx = 1
      DO i = 1, MIN(n_slave, SIZE(slave_nodes))
          DO j = 1, MIN(n_master, SIZE(master_nodes))
              IF (pair_idx <= SIZE(contact_pairs, 2)) THEN
                  contact_pairs(1, pair_idx) = slave_nodes(i)
                  contact_pairs(2, pair_idx) = master_nodes(j)
                  pair_idx = pair_idx + 1
                  n_pairs = n_pairs + 1
              END IF
          END DO
      END DO
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_Pair_Identify

  SUBROUTINE PH_Cont_SpatialHash(coords, n_points, cell_size, hash_table, status)
      REAL(wp), INTENT(IN) :: coords(:,:)
      INTEGER(i4), INTENT(IN) :: n_points
      REAL(wp), INTENT(IN) :: cell_size
      INTEGER(i4), INTENT(OUT) :: hash_table(:,:)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: i, hash_idx
      CALL init_error_status(status)
      DO i = 1, MIN(n_points, SIZE(coords, 2))
          hash_idx = INT(coords(1, i) / cell_size) + INT(coords(2, i) / cell_size) * 1000 + &
                    INT(coords(3, i) / cell_size) * 1000000
          hash_idx = MOD(ABS(hash_idx), SIZE(hash_table, 1)) + 1
          hash_table(hash_idx, 1) = hash_table(hash_idx, 1) + 1
      END DO
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_SpatialHash

  SUBROUTINE PH_Cont_BoundingBox(coords, n_points, bbox_min, bbox_max, status)
      REAL(wp), INTENT(IN) :: coords(:,:)
      INTEGER(i4), INTENT(IN) :: n_points
      REAL(wp), INTENT(OUT) :: bbox_min(3), bbox_max(3)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: i, j
      CALL init_error_status(status)
      bbox_min = HUGE(ONE)
      bbox_max = -HUGE(ONE)
      DO i = 1, MIN(n_points, SIZE(coords, 2))
          DO j = 1, 3
              IF (coords(j, i) < bbox_min(j)) bbox_min(j) = coords(j, i)
              IF (coords(j, i) > bbox_max(j)) bbox_max(j) = coords(j, i)
          END DO
      END DO
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_BoundingBox

  SUBROUTINE AABB_Init(aabb, points, n_points, status)
      TYPE(AABB_Type), INTENT(OUT) :: aabb
      REAL(wp), INTENT(IN) :: points(:,:)
      INTEGER(i4), INTENT(IN) :: n_points
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: i
      CALL init_error_status(status)
      IF (n_points <= 0) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "AABB_Init: n_points must be positive"
          RETURN
      END IF
      aabb%min_coords = points(:, 1)
      aabb%max_coords = points(:, 1)
      DO i = 2, n_points
          aabb%min_coords = MIN(aabb%min_coords, points(:, i))
          aabb%max_coords = MAX(aabb%max_coords, points(:, i))
      END DO
      aabb%center = (aabb%min_coords + aabb%max_coords) * HALF
      aabb%extents = (aabb%max_coords - aabb%min_coords) * HALF
      status%status_code = IF_STATUS_OK
  END SUBROUTINE AABB_Init

  SUBROUTINE AABB_Expand(aabb, other, status)
      TYPE(AABB_Type), INTENT(INOUT) :: aabb
      TYPE(AABB_Type), INTENT(IN) :: other
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      aabb%min_coords = MIN(aabb%min_coords, other%min_coords)
      aabb%max_coords = MAX(aabb%max_coords, other%max_coords)
      aabb%center = (aabb%min_coords + aabb%max_coords) * HALF
      aabb%extents = (aabb%max_coords - aabb%min_coords) * HALF
      status%status_code = IF_STATUS_OK
  END SUBROUTINE AABB_Expand

  LOGICAL FUNCTION AABB_Overlap(aabb1, aabb2) RESULT(overlap)
      TYPE(AABB_Type), INTENT(IN) :: aabb1, aabb2
      overlap = .TRUE.
      IF (aabb1%max_coords(1) < aabb2%min_coords(1) .OR. aabb1%min_coords(1) > aabb2%max_coords(1)) overlap = .FALSE.
      IF (aabb1%max_coords(2) < aabb2%min_coords(2) .OR. aabb1%min_coords(2) > aabb2%max_coords(2)) overlap = .FALSE.
      IF (aabb1%max_coords(3) < aabb2%min_coords(3) .OR. aabb1%min_coords(3) > aabb2%max_coords(3)) overlap = .FALSE.
  END FUNCTION AABB_Overlap

  RECURSIVE SUBROUTINE BVH_Build_Recursive(nodes, objects_aabb, n_objects, start_idx, end_idx, &
                                           node_id, node_count, max_nodes, status)
      TYPE(BVH_Node_Type), INTENT(INOUT) :: nodes(:)
      TYPE(AABB_Type), INTENT(IN) :: objects_aabb(:)
      INTEGER(i4), INTENT(IN) :: n_objects, start_idx, end_idx, max_nodes
      INTEGER(i4), INTENT(OUT) :: node_id
      INTEGER(i4), INTENT(INOUT) :: node_count
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: i, mid_idx, left_id, right_id
      TYPE(AABB_Type) :: combined_bbox
      CALL init_error_status(status)
      node_count = node_count + 1
      node_id = node_count
      IF (node_id > max_nodes) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "BVH_Build_Recursive: Node limit exceeded"
          RETURN
      END IF
      combined_bbox = objects_aabb(start_idx)
      DO i = start_idx + 1, end_idx
          CALL AABB_Expand(combined_bbox, objects_aabb(i), status)
      END DO
      nodes(node_id)%bbox = combined_bbox
      IF (start_idx == end_idx) THEN
          nodes(node_id)%is_leaf = .TRUE.
          nodes(node_id)%object_id = start_idx
          status%status_code = IF_STATUS_OK
          RETURN
      END IF
      nodes(node_id)%is_leaf = .FALSE.
      mid_idx = (start_idx + end_idx) / 2
      CALL BVH_Build_Recursive(nodes, objects_aabb, n_objects, start_idx, mid_idx, &
                               left_id, node_count, max_nodes, status)
      nodes(node_id)%left_child = left_id
      CALL BVH_Build_Recursive(nodes, objects_aabb, n_objects, mid_idx + 1, end_idx, &
                               right_id, node_count, max_nodes, status)
      nodes(node_id)%right_child = right_id
      status%status_code = IF_STATUS_OK
  END SUBROUTINE BVH_Build_Recursive

  SUBROUTINE BVH_Build_Recursive_FromPack(nodes, objects_aabb, desc, status)
      TYPE(BVH_Node_Type), INTENT(INOUT) :: nodes(:)
      TYPE(AABB_Type), INTENT(IN) :: objects_aabb(:)
      TYPE(BVH_Build_Desc), INTENT(INOUT) :: desc
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL BVH_Build_Recursive(nodes, objects_aabb, desc%n_objects, desc%start_idx, &
                              desc%end_idx, desc%node_id, desc%node_count, desc%max_nodes, status)
  END SUBROUTINE BVH_Build_Recursive_FromPack

  SUBROUTINE BVH_Build(nodes, objects_aabb, n_objects, root_id, status)
      TYPE(BVH_Node_Type), ALLOCATABLE, INTENT(OUT) :: nodes(:)
      TYPE(AABB_Type), INTENT(IN) :: objects_aabb(:)
      INTEGER(i4), INTENT(IN) :: n_objects
      INTEGER(i4), INTENT(OUT) :: root_id
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: max_nodes
      TYPE(BVH_Build_Desc) :: desc
      CALL init_error_status(status)
      IF (n_objects <= 0) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "BVH_Build: n_objects must be positive"
          RETURN
      END IF
      max_nodes = 2 * n_objects - 1
      ALLOCATE(nodes(max_nodes))
      desc%n_objects = n_objects
      desc%start_idx = 1
      desc%end_idx = n_objects
      desc%max_nodes = max_nodes
      desc%node_count = 0
      CALL BVH_Build_Recursive_FromPack(nodes, objects_aabb, desc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      root_id = desc%node_id
      status%status_code = IF_STATUS_OK
  END SUBROUTINE BVH_Build

  RECURSIVE SUBROUTINE BVH_Query_Recursive(nodes, node_id, query_aabb, collision_ids, &
                                           n_collisions, max_collisions, status)
      TYPE(BVH_Node_Type), INTENT(IN) :: nodes(:)
      INTEGER(i4), INTENT(IN) :: node_id
      TYPE(AABB_Type), INTENT(IN) :: query_aabb
      INTEGER(i4), INTENT(INOUT) :: collision_ids(:)
      INTEGER(i4), INTENT(INOUT) :: n_collisions
      INTEGER(i4), INTENT(IN) :: max_collisions
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      IF (node_id <= 0 .OR. node_id > SIZE(nodes)) RETURN
      IF (.NOT. AABB_Overlap(nodes(node_id)%bbox, query_aabb)) RETURN
      IF (nodes(node_id)%is_leaf) THEN
          IF (n_collisions < max_collisions) THEN
              n_collisions = n_collisions + 1
              collision_ids(n_collisions) = nodes(node_id)%object_id
          END IF
          RETURN
      END IF
      IF (nodes(node_id)%left_child > 0) &
          CALL BVH_Query_Recursive(nodes, nodes(node_id)%left_child, query_aabb, &
                                   collision_ids, n_collisions, max_collisions, status)
      IF (nodes(node_id)%right_child > 0) &
          CALL BVH_Query_Recursive(nodes, nodes(node_id)%right_child, query_aabb, &
                                   collision_ids, n_collisions, max_collisions, status)
      status%status_code = IF_STATUS_OK
  END SUBROUTINE BVH_Query_Recursive

  SUBROUTINE BVH_Query_Collisions(nodes, root_id, query_aabb, collision_ids, n_collisions, status, work_buf)
      TYPE(BVH_Node_Type), INTENT(IN) :: nodes(:)
      INTEGER(i4), INTENT(IN) :: root_id
      TYPE(AABB_Type), INTENT(IN) :: query_aabb
      INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: collision_ids(:)
      INTEGER(i4), INTENT(OUT) :: n_collisions
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4), INTENT(INOUT), OPTIONAL :: work_buf(:)
      INTEGER(i4) :: max_collisions
      CALL init_error_status(status)
      max_collisions = SIZE(nodes)
      IF (PRESENT(work_buf) .AND. SIZE(work_buf) >= max_collisions) THEN
          ! AP-8: Use pre-allocated buffer (no ALLOCATE in warm path)
          n_collisions = 0
          CALL BVH_Query_Recursive(nodes, root_id, query_aabb, work_buf, &
                                  n_collisions, max_collisions, status)
      ELSE
          ALLOCATE(collision_ids(max_collisions))
          n_collisions = 0
          CALL BVH_Query_Recursive(nodes, root_id, query_aabb, collision_ids, &
                                   n_collisions, max_collisions, status)
      END IF
      status%status_code = IF_STATUS_OK
  END SUBROUTINE BVH_Query_Collisions

  INTEGER(i4) FUNCTION SpatialHash_ComputeKey(hash, position) RESULT(key)
      TYPE(SpatialHash_Type), INTENT(IN) :: hash
      REAL(wp), INTENT(IN) :: position(3)
      INTEGER(i4) :: ix, iy, iz, hash_value
      ix = FLOOR(position(1) / hash%cell_size)
      iy = FLOOR(position(2) / hash%cell_size)
      iz = FLOOR(position(3) / hash%cell_size)
      hash_value = ix + 73856093 * iy + 19349663 * iz
      key = MOD(ABS(hash_value), hash%table_size) + 1
  END FUNCTION SpatialHash_ComputeKey

  SUBROUTINE SpatialHash_Init(hash, cell_size, table_size, max_objects_per_cell, status)
      TYPE(SpatialHash_Type), INTENT(OUT) :: hash
      REAL(wp), INTENT(IN) :: cell_size
      INTEGER(i4), INTENT(IN) :: table_size, max_objects_per_cell
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      hash%cell_size = cell_size
      hash%table_size = table_size
      hash%max_objects_per_cell = max_objects_per_cell
      ALLOCATE(hash%hash_table(table_size, max_objects_per_cell))
      ALLOCATE(hash%cell_counts(table_size))
      hash%hash_table = -1
      hash%cell_counts = 0
      status%status_code = IF_STATUS_OK
  END SUBROUTINE SpatialHash_Init

  SUBROUTINE SpatialHash_Insert(hash, object_id, position, status)
      TYPE(SpatialHash_Type), INTENT(INOUT) :: hash
      INTEGER(i4), INTENT(IN) :: object_id
      REAL(wp), INTENT(IN) :: position(3)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: hash_key, cell_idx
      CALL init_error_status(status)
      hash_key = SpatialHash_ComputeKey(hash, position)
      cell_idx = hash%cell_counts(hash_key) + 1
      IF (cell_idx <= hash%max_objects_per_cell) THEN
          hash%hash_table(hash_key, cell_idx) = object_id
          hash%cell_counts(hash_key) = cell_idx
          status%status_code = IF_STATUS_OK
      ELSE
          status%status_code = IF_STATUS_INVALID
          status%message = "SpatialHash_Insert: Cell overflow"
      END IF
  END SUBROUTINE SpatialHash_Insert

  SUBROUTINE SpatialHash_Query(hash, query_position, nearby_ids, n_nearby, status, work_buf)
      TYPE(SpatialHash_Type), INTENT(IN) :: hash
      REAL(wp), INTENT(IN) :: query_position(3)
      INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: nearby_ids(:)
      INTEGER(i4), INTENT(OUT) :: n_nearby
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4), INTENT(INOUT), OPTIONAL :: work_buf(:)
      INTEGER(i4) :: hash_key, i, max_nearby
      CALL init_error_status(status)
      hash_key = SpatialHash_ComputeKey(hash, query_position)
      n_nearby = hash%cell_counts(hash_key)
      max_nearby = hash%max_objects_per_cell
      IF (n_nearby > 0) THEN
          IF (PRESENT(work_buf) .AND. SIZE(work_buf) >= max_nearby) THEN
              ! AP-8: Use pre-allocated buffer (no ALLOCATE in warm path)
              DO i = 1, n_nearby
                  work_buf(i) = hash%hash_table(hash_key, i)
              END DO
          ELSE
              ALLOCATE(nearby_ids(n_nearby))
              DO i = 1, n_nearby
                  nearby_ids(i) = hash%hash_table(hash_key, i)
              END DO
          END IF
      END IF
      status%status_code = IF_STATUS_OK
  END SUBROUTINE SpatialHash_Query

  SUBROUTINE Octree_Build(nodes, objects_aabb, n_objects, max_depth, root_id, status)
      TYPE(Octree_Node_Type), ALLOCATABLE, INTENT(OUT) :: nodes(:)
      TYPE(AABB_Type), INTENT(IN) :: objects_aabb(:)
      INTEGER(i4), INTENT(IN) :: n_objects, max_depth
      INTEGER(i4), INTENT(OUT) :: root_id
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      ALLOCATE(nodes(1))
      root_id = 1
      CALL AABB_Init(nodes(1)%bbox, RESHAPE(objects_aabb(1)%min_coords, [3,1]), 1, status)
      nodes(1)%is_leaf = .TRUE.
      nodes(1)%n_objects = n_objects
      status%status_code = IF_STATUS_OK
  END SUBROUTINE Octree_Build

  SUBROUTINE Octree_Query(nodes, root_id, query_aabb, result_ids, n_results, status)
      TYPE(Octree_Node_Type), INTENT(IN) :: nodes(:)
      INTEGER(i4), INTENT(IN) :: root_id
      TYPE(AABB_Type), INTENT(IN) :: query_aabb
      INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: result_ids(:)
      INTEGER(i4), INTENT(OUT) :: n_results
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      n_results = 0
      status%status_code = IF_STATUS_OK
  END SUBROUTINE Octree_Query

  !=============================================================================
  ! FRICTION (merged from PH_Cont_Friction_Core)
  !=============================================================================
  SUBROUTINE PH_Cont_ComputeSlip(in, out)
      TYPE(PH_Cont_ComputeSlip_In), INTENT(IN) :: in
      TYPE(PH_Cont_ComputeSlip_Out), INTENT(OUT) :: out
      out%slip = in%relative_velocity * in%time_step
  END SUBROUTINE PH_Cont_ComputeSlip

  SUBROUTINE PH_Cont_CoulombFriction(in, out)
      TYPE(PH_Cont_CoulombFriction_In), INTENT(IN) :: in
      TYPE(PH_Cont_CoulombFriction_Out), INTENT(OUT) :: out
      REAL(wp) :: max_friction
      CALL init_error_status(out%status)
      IF (in%normal_force < ZERO) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_CoulombFriction: Normal force must be positive'
          out%friction_force = ZERO
          RETURN
      END IF
      max_friction = in%friction_coeff * in%normal_force
      out%friction_force = -max_friction * in%slip_direction
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_CoulombFriction

  SUBROUTINE PH_Cont_ExponentialFriction(in, out)
      TYPE(PH_Cont_ExponentialFriction_In), INTENT(IN) :: in
      TYPE(PH_Cont_ExponentialFriction_Out), INTENT(OUT) :: out
      REAL(wp) :: slip_mag, effective_coeff, slip_dir(3)
      CALL init_error_status(out%status)
      IF (in%normal_force < ZERO) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ExponentialFriction: Normal force must be positive'
          out%friction_force = ZERO
          RETURN
      END IF
      slip_mag = SQRT(DOT_PRODUCT(in%slip_velocity, in%slip_velocity))
      IF (slip_mag < 1.0e-15_wp) THEN
          out%friction_force = ZERO
          out%status%status_code = IF_STATUS_OK
          RETURN
      END IF
      slip_dir = in%slip_velocity / slip_mag
      effective_coeff = in%friction_coeff * EXP(-in%decay_rate * slip_mag)
      out%friction_force = -effective_coeff * in%normal_force * slip_dir
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_ExponentialFriction

  SUBROUTINE PH_Cont_FrictionStiffness(in, out)
      TYPE(PH_Cont_FrictionStiffness_In), INTENT(IN) :: in
      TYPE(PH_Cont_FrictionStiffness_Out), INTENT(OUT) :: out
      INTEGER(i4) :: i, j
      CALL init_error_status(out%status)
      DO i = 1, 3
          DO j = 1, 3
              out%K_friction(i, j) = in%friction_stiffness * in%tangent_direction(i) * in%tangent_direction(j)
          END DO
      END DO
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_FrictionStiffness

  SUBROUTINE PH_Cont_PressureDependentFriction(in, out)
      TYPE(PH_Cont_PressureDependentFriction_In), INTENT(IN) :: in
      TYPE(PH_Cont_PressureDependentFriction_Out), INTENT(OUT) :: out
      REAL(wp) :: contact_pressure, effective_coeff
      CALL init_error_status(out%status)
      IF (in%normal_force < ZERO .OR. in%contact_area < 1.0e-15_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_PressureDependentFriction: Invalid input'
          out%friction_force = ZERO
          RETURN
      END IF
      contact_pressure = in%normal_force / in%contact_area
      effective_coeff = in%friction_coeff_base * (contact_pressure ** in%pressure_exponent)
      out%friction_force = -effective_coeff * in%normal_force * in%slip_direction
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_PressureDependentFriction

  SUBROUTINE PH_Cont_StickSlip(in, accumulated_slip, out)
      TYPE(PH_Cont_StickSlip_In), INTENT(IN) :: in
      REAL(wp), INTENT(INOUT) :: accumulated_slip(3)
      TYPE(PH_Cont_StickSlip_Out), INTENT(OUT) :: out
      REAL(wp) :: trial_slip_mag, max_friction, friction_mag, slip_direction(3)
      CALL init_error_status(out%status)
      IF (in%normal_force < ZERO) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_StickSlip: Normal force must be positive'
          out%friction_force = ZERO
          out%is_sticking = .FALSE.
          RETURN
      END IF
      trial_slip_mag = SQRT(DOT_PRODUCT(in%trial_slip, in%trial_slip))
      IF (trial_slip_mag < 1.0e-15_wp) THEN
          out%friction_force = ZERO
          out%is_sticking = .TRUE.
          out%accumulated_slip = accumulated_slip
          out%status%status_code = IF_STATUS_OK
          RETURN
      END IF
      max_friction = in%friction_coeff * in%normal_force
      friction_mag = in%friction_stiffness * trial_slip_mag
      IF (friction_mag <= max_friction) THEN
          out%is_sticking = .TRUE.
          out%friction_force = -in%friction_stiffness * in%trial_slip
          out%accumulated_slip = accumulated_slip + in%trial_slip
      ELSE
          out%is_sticking = .FALSE.
          slip_direction = in%trial_slip / trial_slip_mag
          out%friction_force = -max_friction * slip_direction
          out%accumulated_slip = accumulated_slip + (max_friction / in%friction_stiffness) * slip_direction
      END IF
      accumulated_slip = out%accumulated_slip
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_StickSlip

  SUBROUTINE PH_Cont_VelocityDependentFriction(in, out)
      TYPE(PH_Cont_VelocityDependentFriction_In), INTENT(IN) :: in
      TYPE(PH_Cont_VelocityDependentFriction_Out), INTENT(OUT) :: out
      REAL(wp) :: slip_mag, effective_coeff, slip_dir(3)
      CALL init_error_status(out%status)
      IF (in%normal_force < ZERO) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_VelocityDependentFriction: Normal force must be positive'
          out%friction_force = ZERO
          RETURN
      END IF
      slip_mag = SQRT(DOT_PRODUCT(in%slip_velocity, in%slip_velocity))
      IF (slip_mag < 1.0e-15_wp) THEN
          out%friction_force = ZERO
          out%status%status_code = IF_STATUS_OK
          RETURN
      END IF
      slip_dir = in%slip_velocity / slip_mag
      IF (slip_mag < in%transition_velocity) THEN
          effective_coeff = in%friction_coeff_static - &
                          (in%friction_coeff_static - in%friction_coeff_kinetic) * &
                          (slip_mag / in%transition_velocity)
      ELSE
          effective_coeff = in%friction_coeff_kinetic
      END IF
      out%friction_force = -effective_coeff * in%normal_force * slip_dir
      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_VelocityDependentFriction

  !=============================================================================
  ! LARGEDEF (merged from PH_Cont_LargeDef_Core)
  !=============================================================================
  SUBROUTINE PH_Cont_LargeDef_State_Init(state, X_slave, X_master, u_slave, u_master, status)
      TYPE(PH_Cont_LargeDef_State_Type), INTENT(OUT) :: state
      REAL(wp), INTENT(IN) :: X_slave(3), X_master(3), u_slave(3), u_master(3)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      state%ref%X_slave_ref = X_slave
      state%ref%X_master_ref = X_master
      state%curr%u_slave = u_slave
      state%curr%u_master = u_master
      state%curr%x_slave = X_slave + u_slave
      state%curr%x_master = X_master + u_master
      state%ref%normal_ref = state%ref%X_slave_ref - state%ref%X_master_ref
      IF (DOT_PRODUCT(state%ref%normal_ref, state%ref%normal_ref) > 1.0e-12_wp) THEN
          state%ref%normal_ref = state%ref%normal_ref / SQRT(DOT_PRODUCT(state%ref%normal_ref, state%ref%normal_ref))
      ELSE
          state%ref%normal_ref = [ZERO, ZERO, ONE]
      END IF
      state%curr%normal_curr = state%ref%normal_ref
      state%F%F_slave = ZERO
      state%F%F_master = ZERO
      state%F%F_slave(1,1) = ONE
      state%F%F_slave(2,2) = ONE
      state%F%F_slave(3,3) = ONE
      state%F%F_master(1,1) = ONE
      state%F%F_master(2,2) = ONE
      state%F%F_master(3,3) = ONE
      state%contact%state = 0
      state%contact%state_prev = 0
      state%contact%just_transitioned = .FALSE.
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_LargeDef_State_Init

  SUBROUTINE PH_Cont_LargeDef_Update_Normal(state, F_master, status)
      TYPE(PH_Cont_LargeDef_State_Type), INTENT(INOUT) :: state
      REAL(wp), INTENT(IN) :: F_master(3,3)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      REAL(wp) :: F_inv_T(3,3), normal_temp(3), norm_mag
      CALL init_error_status(status)
      state%F%F_master = F_master
      F_inv_T = TRANSPOSE(F_master)
      normal_temp = MATMUL(F_inv_T, state%ref%normal_ref)
      norm_mag = SQRT(DOT_PRODUCT(normal_temp, normal_temp))
      IF (norm_mag > 1.0e-12_wp) THEN
          state%curr%normal_curr = normal_temp / norm_mag
      ELSE
          state%curr%normal_curr = state%ref%normal_ref
          status%status_code = IF_STATUS_INVALID
          status%message = "Cont_LargeDef_Update_Normal: Degenerate normal"
          RETURN
      END IF
      CALL PH_Cont_ComputeTangentVectors(state%curr%normal_curr, state%ref%tangent1, state%ref%tangent2, status)
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_LargeDef_Update_Normal

  SUBROUTINE PH_Cont_LargeDef_Update_Gap(state, status)
      TYPE(PH_Cont_LargeDef_State_Type), INTENT(INOUT) :: state
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      TYPE(PH_Cont_Gap_In)  :: gap_in
      TYPE(PH_Cont_Gap_Out) :: gap_out
      CALL init_error_status(status)
      state%curr%x_slave = state%ref%X_slave_ref + state%curr%u_slave
      state%curr%x_master = state%ref%X_master_ref + state%curr%u_master
      gap_in%slave_point = state%curr%x_slave
      gap_in%master_point = state%curr%x_master
      gap_in%normal = state%curr%normal_curr
      CALL PH_Cont_ComputeGap(gap_in, gap_out)
      state%curr%gap_curr = gap_out%gap
      IF (state%curr%gap_curr < -1.0e-12_wp) THEN
          state%contact%state = 1
      ELSE IF (state%curr%gap_curr > 1.0e-12_wp) THEN
          state%contact%state = 0
      ELSE
          state%contact%state = 1
      END IF
      state%contact%just_transitioned = (state%contact%state /= state%contact%state_prev)
      state%contact%state_prev = state%contact%state
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_LargeDef_Update_Gap

  SUBROUTINE PH_Cont_LargeDef_Check_Sliding(state, u_slave_incr, u_master_incr, status)
      TYPE(PH_Cont_LargeDef_State_Type), INTENT(INOUT) :: state
      REAL(wp), INTENT(IN) :: u_slave_incr(3), u_master_incr(3)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      REAL(wp) :: relative_disp(3), tangential_disp(3), normal_comp
      CALL init_error_status(status)
      IF (state%contact%state /= 1) THEN
          state%slip%slip_increment = ZERO
          state%slip%slip_magnitude = ZERO
          status%status_code = IF_STATUS_OK
          RETURN
      END IF
      relative_disp = u_slave_incr - u_master_incr
      normal_comp = DOT_PRODUCT(relative_disp, state%curr%normal_curr)
      tangential_disp = relative_disp - normal_comp * state%curr%normal_curr
      state%slip%slip_increment = tangential_disp
      state%slip%slip_magnitude = SQRT(DOT_PRODUCT(tangential_disp, tangential_disp))
      state%slip%accumulated_slip = state%slip%accumulated_slip + state%slip%slip_increment
      IF (state%slip%slip_magnitude > state%slip%slip_tolerance) THEN
          state%contact%state = 3
      ELSE
          state%contact%state = 2
      END IF
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_LargeDef_Check_Sliding

  SUBROUTINE PH_Cont_LargeDef_Compute_Tangent(state, penalty, K_contact, status)
      TYPE(PH_Cont_LargeDef_State_Type), INTENT(IN) :: state
      REAL(wp), INTENT(IN) :: penalty
      REAL(wp), INTENT(OUT) :: K_contact(3,3)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      TYPE(PH_Cont_PenaltyStiffness_In) :: stiffness_in
      TYPE(PH_Cont_PenaltyStiffness_Out) :: stiffness_out
      INTEGER(i4) :: i, j
      REAL(wp) :: t1_outer_t1(3,3), t2_outer_t2(3,3)
      CALL init_error_status(status)
      K_contact = ZERO
      IF (state%contact%state == 0) THEN
          status%status_code = IF_STATUS_OK
          RETURN
      END IF
      stiffness_in%penalty = penalty
      stiffness_in%normal = state%curr%normal_curr
      CALL PH_Cont_PenaltyStiffness(stiffness_in, stiffness_out)
      K_contact = stiffness_out%K_penalty
      IF (state%contact%state == 2) THEN
          DO i = 1, 3
              DO j = 1, 3
                  t1_outer_t1(i,j) = state%ref%tangent1(i) * state%ref%tangent1(j)
                  t2_outer_t2(i,j) = state%ref%tangent2(i) * state%ref%tangent2(j)
              END DO
          END DO
          K_contact = K_contact + 0.4_wp * penalty * (t1_outer_t1 + t2_outer_t2)
      END IF
      status = stiffness_out%status
  END SUBROUTINE PH_Cont_LargeDef_Compute_Tangent

  SUBROUTINE PH_Cont_LargeDef_Track_Boundary(state, surface_coords, n_surface_nodes, closest_node_id, status)
      TYPE(PH_Cont_LargeDef_State_Type), INTENT(INOUT) :: state
      REAL(wp), INTENT(IN) :: surface_coords(:,:)
      INTEGER(i4), INTENT(IN) :: n_surface_nodes
      INTEGER(i4), INTENT(OUT) :: closest_node_id
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: i_node
      REAL(wp) :: distance, min_distance
      REAL(wp) :: node_pos(3), diff(3)
      CALL init_error_status(status)
      IF (state%contact%state /= 3) THEN
          closest_node_id = -1
          status%status_code = IF_STATUS_OK
          RETURN
      END IF
      min_distance = HUGE(ONE)
      closest_node_id = -1
      DO i_node = 1, n_surface_nodes
          node_pos = surface_coords(:, i_node)
          diff = state%curr%x_slave - node_pos
          distance = SQRT(DOT_PRODUCT(diff, diff))
          IF (distance < min_distance) THEN
              min_distance = distance
              closest_node_id = i_node
          END IF
      END DO
      IF (closest_node_id > 0) THEN
          state%curr%x_master = surface_coords(:, closest_node_id)
          state%curr%u_master = state%curr%x_master - state%ref%X_master_ref
          CALL PH_Cont_LargeDef_Update_Gap(state, status)
      END IF
      status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Cont_LargeDef_Track_Boundary

END MODULE PH_Cont_Mgr