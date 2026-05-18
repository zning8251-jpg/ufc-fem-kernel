!===============================================================================
! MODULE: PH_Cont_Brg
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Brg
! BRIEF:  Unified contact interface layer (facade) with parameter validation
!
! Theory: KKT, penalty, augmented Lagrangian, Coulomb friction
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Contact | Role:API | FuncSet?Facade | 热路�?�?!>>> Basis:PLAN/04_实施路线�任务规�?实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md ��?5.1 / �附�L4 接触门面�委�?Core?!>>> UFC_PH_CONTRACT | Contact/CONTRACT.md

MODULE PH_Cont_Brg
!> [API] Unified contact interface layer
!> Theory: KKT conditions, penalty method, augmented Lagrangian, Coulomb friction
!> Status: Production | Last verified: 2026-02-28
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE PH_Cont_Ctx_Def, ONLY: PH_ContactCtx, PH_Cont_Time_Desc
  USE PH_Cont_Mgr, ONLY: PH_Cont_AlgorithmFramework, &
                             PH_Cont_ConvergenceCheck, &
                             PH_Cont_SearchPairs, &
                             PH_Cont_DetectPenetration, &
                             PH_Cont_CalculateGap, &
                             PH_Cont_ApplyConstraints, &
                             PH_Cont_UpdateFriction, &
                             PH_Cont_CheckConvergence, &
                             PH_Cont_Penetration_Algo, &
                             PH_Cont_Friction_Algo, &
                             PH_Cont_Thermal_Contact, &
                             PH_Cont_Dynamic_Contact
  USE PH_Cont_Ctx_Def, ONLY: PH_Cont_AlgorithmFramework_In, PH_Cont_AlgorithmFramework_Out, &
                           PH_Cont_ConvergenceCheck_In, PH_Cont_ConvergenceCheck_Out, &
                           PH_Cont_SearchPairs_In, PH_Cont_SearchPairs_Out, &
                           PH_Cont_DetectPenetration_In, PH_Cont_DetectPenetration_Out, &
                           PH_Cont_CalculateGap_In, PH_Cont_CalculateGap_Out, &
                           PH_Cont_ApplyConstraints_In, PH_Cont_ApplyConstraints_Out, &
                           PH_Cont_UpdateFriction_In, PH_Cont_UpdateFriction_Out, &
                           PH_Cont_Penetration_Algo_In, PH_Cont_Penetration_Algo_Out, &
                           PH_Cont_Friction_Algo_In, PH_Cont_Friction_Algo_Out, &
                           PH_Cont_Thermal_Contact_In, PH_Cont_Thermal_Contact_Out, &
                           PH_Cont_Dynamic_Contact_In, PH_Cont_Dynamic_Contact_Out

  IMPLICIT NONE
  PRIVATE

  ! ========== PUBLIC INTERFACES ==========
  PUBLIC :: PH_Cont_AlgorithmFramework_API
  PUBLIC :: PH_Cont_ConvergenceCheck_API
  PUBLIC :: PH_Cont_SearchPairs_API
  PUBLIC :: PH_Cont_DetectPenetration_API
  PUBLIC :: PH_Cont_CalculateGap_API
  PUBLIC :: PH_Cont_ApplyConstraints_API
  PUBLIC :: PH_Cont_UpdateFriction_API
  PUBLIC :: PH_Cont_CheckConvergence_API
  PUBLIC :: PH_Cont_Penetration_Algo_API
  PUBLIC :: PH_Cont_Penetration_Algo_Structured
  PUBLIC :: PH_Cont_Friction_Algo_API
  PUBLIC :: PH_Cont_Friction_Algo_Structured
  PUBLIC :: PH_Cont_Thermal_Contact_API
  PUBLIC :: PH_Cont_Thermal_Contact_Structured
  PUBLIC :: PH_Cont_Dynamic_Contact_API
  PUBLIC :: PH_Cont_Dynamic_Contact_Structured

CONTAINS

  SUBROUTINE PH_Cont_AlgorithmFramework_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_AlgorithmFramework_In), INTENT(IN) :: in
      TYPE(PH_Cont_AlgorithmFramework_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_AlgorithmFramework_API: Context not initialized'
          RETURN
      END IF
      
      IF (in%dt < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_AlgorithmFramework_API: Invalid dt (< 0)'
          RETURN
      END IF
      
      IF (SIZE(in%normal_vector) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_AlgorithmFramework_API: Invalid normal_vector size'
          RETURN
      END IF
      
      IF (SIZE(in%relative_velocity) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_AlgorithmFramework_API: Invalid relative_velocity size'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_AlgorithmFramework(ctx, in, out)
      
  END SUBROUTINE PH_Cont_AlgorithmFramework_API

  SUBROUTINE PH_Cont_ApplyConstraints_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ApplyConstraints_In), INTENT(INOUT) :: in
      TYPE(PH_Cont_ApplyConstraints_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ASSOCIATED(in%stiffness_matrix)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ApplyConstraints_API: stiffness_matrix not associated'
          RETURN
      END IF
      
      IF (.NOT. ASSOCIATED(in%force_vector)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ApplyConstraints_API: force_vector not associated'
          RETURN
      END IF
      
      IF (SIZE(in%stiffness_matrix, 1) /= SIZE(in%stiffness_matrix, 2)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ApplyConstraints_API: stiffness_matrix must be square'
          RETURN
      END IF
      
      IF (SIZE(in%force_vector) /= SIZE(in%stiffness_matrix, 1)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ApplyConstraints_API: Inconsistent matrix/vector sizes'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_ApplyConstraints(ctx, in, out)
      
  END SUBROUTINE PH_Cont_ApplyConstraints_API

  SUBROUTINE PH_Cont_CalculateGap_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_CalculateGap_In), INTENT(IN) :: in
      TYPE(PH_Cont_CalculateGap_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ASSOCIATED(in%node_coords)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_CalculateGap_API: node_coords not associated'
          RETURN
      END IF
      
      IF (.NOT. ASSOCIATED(in%node_displacements)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_CalculateGap_API: node_displacements not associated'
          RETURN
      END IF
      
      IF (SIZE(in%node_coords, 1) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_CalculateGap_API: Invalid node_coords dimensions'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_CalculateGap(ctx, in, out)
      
  END SUBROUTINE PH_Cont_CalculateGap_API

  SUBROUTINE PH_Cont_CheckConvergence_API(ctx, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ConvergenceCheck_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_CheckConvergence_API: Context not initialized'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_CheckConvergence(ctx, out)
      
  END SUBROUTINE PH_Cont_CheckConvergence_API

  SUBROUTINE PH_Cont_ConvergenceCheck_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_ConvergenceCheck_In), INTENT(IN) :: in
      TYPE(PH_Cont_ConvergenceCheck_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (in%tolerance < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ConvergenceCheck_API: Invalid tolerance (< 0)'
          RETURN
      END IF
      
      IF (in%max_iterations < 1) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_ConvergenceCheck_API: Invalid max_iterations (< 1)'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_ConvergenceCheck(ctx, in, out)
      
  END SUBROUTINE PH_Cont_ConvergenceCheck_API

  SUBROUTINE PH_Cont_DetectPenetration_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_DetectPenetration_In), INTENT(IN) :: in
      TYPE(PH_Cont_DetectPenetration_Out), INTENT(OUT) :: out
      INTEGER(i4) :: n
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ASSOCIATED(in%surface_faces)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_DetectPenetration_API: surface_faces not associated'
          RETURN
      END IF
      
      ! AP-8: Pre-allocate out%penetration_depth (amortized; only when size grows)
      n = SIZE(in%surface_faces, 3)
      IF (.NOT. ALLOCATED(out%penetration_depth) .OR. SIZE(out%penetration_depth) < n) THEN
          IF (ALLOCATED(out%penetration_depth)) DEALLOCATE(out%penetration_depth)
          ALLOCATE(out%penetration_depth(n))
      END IF
      
      ! Delegate to Methods layer (uses ctx%penetration_depth_buf, no alloc in warm path)
      CALL PH_Cont_DetectPenetration(ctx, in, out)
      
  END SUBROUTINE PH_Cont_DetectPenetration_API

  SUBROUTINE PH_Cont_Dynamic_Contact_API(ctx, relative_velocity, contact_area, dt, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: relative_velocity(3)  ! Relative velocity v_rel ??^3
      REAL(wp), INTENT(IN) :: contact_area  ! Contact area A
      REAL(wp), INTENT(IN) :: dt  ! Time step ?t
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      TYPE(PH_Cont_Dynamic_Contact_In) :: in
      TYPE(PH_Cont_Dynamic_Contact_Out) :: out
      
      ! Construct structured input
      in%relative_velocity = relative_velocity
      in%contact_area = contact_area
      in%dt = dt
      
      ! Call structured interface
      CALL PH_Cont_Dynamic_Contact_Structured(ctx, in, out)
      
      ! Copy status back
      status = out%status
      
  END SUBROUTINE PH_Cont_Dynamic_Contact_API

  SUBROUTINE PH_Cont_Dynamic_Contact_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_Dynamic_Contact_In), INTENT(IN) :: in
      TYPE(PH_Cont_Dynamic_Contact_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Dynamic_Contact_Structured: Context not initialized'
          RETURN
      END IF
      
      IF (.NOT. ctx%dynamic_contact_enabled) THEN
          out%status%status_code = IF_STATUS_OK
          RETURN
      END IF
      
      IF (in%contact_area < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Dynamic_Contact_Structured: Invalid contact_area (< 0)'
          RETURN
      END IF
      
      IF (in%dt < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Dynamic_Contact_Structured: Invalid dt (< 0)'
          RETURN
      END IF
      
      ! Delegate to Methods layer (extract parameters from structured input)
      CALL PH_Cont_Dynamic_Contact(ctx, in%relative_velocity, in%contact_area, in%dt, out%status)
      
  END SUBROUTINE PH_Cont_Dynamic_Contact_Structured

  SUBROUTINE PH_Cont_Friction_Algo_API(ctx, slip_velocity, slip_magnitude, dt, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: slip_velocity(3)  ! Slip velocity v_slip ??^3
      REAL(wp), INTENT(IN) :: slip_magnitude  ! Slip magnitude ||v_slip||
      REAL(wp), INTENT(IN) :: dt  ! Time step ?t
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      TYPE(PH_Cont_Friction_Algo_In) :: in
      TYPE(PH_Cont_Friction_Algo_Out) :: out
      
      ! Construct structured input
      in%slip_velocity = slip_velocity
      in%slip_magnitude = slip_magnitude
      in%dt = dt
      
      ! Call structured interface
      CALL PH_Cont_Friction_Algo_Structured(ctx, in, out)
      
      ! Copy status back
      status = out%status
      
  END SUBROUTINE PH_Cont_Friction_Algo_API

  SUBROUTINE PH_Cont_Friction_Algo_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_Friction_Algo_In), INTENT(IN) :: in
      TYPE(PH_Cont_Friction_Algo_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Friction_Algo_Structured: Context not initialized'
          RETURN
      END IF
      
      IF (in%dt < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Friction_Algo_Structured: Invalid dt (< 0)'
          RETURN
      END IF
      
      IF (in%slip_magnitude < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Friction_Algo_Structured: Invalid slip_magnitude (< 0)'
          RETURN
      END IF
      
      ! Delegate to Methods layer (extract parameters from structured input)
      CALL PH_Cont_Friction_Algo(ctx, in%slip_velocity, in%slip_magnitude, in%dt, out%status)
      
  END SUBROUTINE PH_Cont_Friction_Algo_Structured

  SUBROUTINE PH_Cont_Penetration_Algo_API(ctx, slave_coords, master_coords, &
                                          num_slave_nodes, num_master_nodes, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: slave_coords(:,:)  ! Slave coordinates X_slave ??^(3 n_slave)
      REAL(wp), INTENT(IN) :: master_coords(:,:)  ! Master coordinates X_master ??^(3 n_master)
      INTEGER(i4), INTENT(IN) :: num_slave_nodes  ! Number of slave nodes
      INTEGER(i4), INTENT(IN) :: num_master_nodes  ! Number of master nodes
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      TYPE(PH_Cont_Penetration_Algo_In) :: in
      TYPE(PH_Cont_Penetration_Algo_Out) :: out
      
      ! Construct structured input
      ALLOCATE(in%slave_coords(SIZE(slave_coords,1), SIZE(slave_coords,2)))
      ALLOCATE(in%master_coords(SIZE(master_coords,1), SIZE(master_coords,2)))
      in%slave_coords = slave_coords
      in%master_coords = master_coords
      in%num_slave_nodes = num_slave_nodes
      in%num_master_nodes = num_master_nodes
      
      ! Call structured interface
      CALL PH_Cont_Penetration_Algo_Structured(ctx, in, out)
      
      ! Copy status back
      status = out%status
      
      ! Cleanup
      DEALLOCATE(in%slave_coords, in%master_coords)
      
  END SUBROUTINE PH_Cont_Penetration_Algo_API

  SUBROUTINE PH_Cont_Penetration_Algo_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_Penetration_Algo_In), INTENT(IN) :: in
      TYPE(PH_Cont_Penetration_Algo_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Penetration_Algo_Structured: Context not initialized'
          RETURN
      END IF
      
      IF (.NOT. ALLOCATED(in%slave_coords) .OR. .NOT. ALLOCATED(in%master_coords)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Penetration_Algo_Structured: Coordinates not allocated'
          RETURN
      END IF
      
      IF (SIZE(in%slave_coords, 1) /= 3 .OR. SIZE(in%master_coords, 1) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Penetration_Algo_Structured: Invalid coordinate dimensions'
          RETURN
      END IF
      
      IF (in%num_slave_nodes < 1 .OR. in%num_master_nodes < 1) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Penetration_Algo_Structured: Invalid node counts'
          RETURN
      END IF
      
      ! Delegate to Methods layer (extract parameters from structured input)
      CALL PH_Cont_Penetration_Algo(ctx, in%slave_coords, in%master_coords, &
                                     in%num_slave_nodes, in%num_master_nodes, out%status)
      
  END SUBROUTINE PH_Cont_Penetration_Algo_Structured

  SUBROUTINE PH_Cont_SearchPairs_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_SearchPairs_In), INTENT(IN) :: in
      TYPE(PH_Cont_SearchPairs_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ASSOCIATED(in%node_coords)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_SearchPairs_API: node_coords not associated'
          RETURN
      END IF
      
      IF (.NOT. ASSOCIATED(in%node_displacements)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_SearchPairs_API: node_displacements not associated'
          RETURN
      END IF
      
      IF (SIZE(in%node_coords, 1) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_SearchPairs_API: Invalid node_coords dimensions'
          RETURN
      END IF
      
      IF (SIZE(in%node_displacements, 1) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_SearchPairs_API: Invalid node_displacements dimensions'
          RETURN
      END IF
      
      IF (SIZE(in%node_coords, 2) /= SIZE(in%node_displacements, 2)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_SearchPairs_API: Inconsistent array sizes'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_SearchPairs(ctx, in, out)
      
  END SUBROUTINE PH_Cont_SearchPairs_API

  SUBROUTINE PH_Cont_Thermal_Contact_API(ctx, temperature_slave, temperature_master, &
                                         contact_pressure, status)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      REAL(wp), INTENT(IN) :: temperature_slave  ! Slave temperature T_slave
      REAL(wp), INTENT(IN) :: temperature_master  ! Master temperature T_master
      REAL(wp), INTENT(IN) :: contact_pressure  ! Contact pressure ?_n
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      TYPE(PH_Cont_Thermal_Contact_In) :: in
      TYPE(PH_Cont_Thermal_Contact_Out) :: out
      
      ! Construct structured input
      in%temperature_slave = temperature_slave
      in%temperature_master = temperature_master
      in%contact_pressure = contact_pressure
      
      ! Call structured interface
      CALL PH_Cont_Thermal_Contact_Structured(ctx, in, out)
      
      ! Copy status back
      status = out%status
      
  END SUBROUTINE PH_Cont_Thermal_Contact_API

  SUBROUTINE PH_Cont_Thermal_Contact_Structured(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_Thermal_Contact_In), INTENT(IN) :: in
      TYPE(PH_Cont_Thermal_Contact_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ctx%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Thermal_Contact_Structured: Context not initialized'
          RETURN
      END IF
      
      IF (.NOT. ctx%thermal_contact_enabled) THEN
          out%status%status_code = IF_STATUS_OK
          RETURN
      END IF
      
      IF (in%temperature_slave < 0.0_wp .OR. in%temperature_master < 0.0_wp) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_Thermal_Contact_Structured: Invalid temperatures (< 0K)'
          RETURN
      END IF
      
      ! Delegate to Methods layer (extract parameters from structured input)
      CALL PH_Cont_Thermal_Contact(ctx, in%temperature_slave, in%temperature_master, &
                                    in%contact_pressure, out%status)
      
  END SUBROUTINE PH_Cont_Thermal_Contact_Structured

  SUBROUTINE PH_Cont_UpdateFriction_API(ctx, in, out)
      TYPE(PH_ContactCtx), INTENT(INOUT) :: ctx
      TYPE(PH_Cont_UpdateFriction_In), INTENT(IN) :: in
      TYPE(PH_Cont_UpdateFriction_Out), INTENT(OUT) :: out
      
      CALL init_error_status(out%status)
      
      ! Parameter validation
      IF (.NOT. ASSOCIATED(in%relative_velocities)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_UpdateFriction_API: relative_velocities not associated'
          RETURN
      END IF
      
      IF (SIZE(in%relative_velocities, 1) /= 3) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'PH_Cont_UpdateFriction_API: Invalid relative_velocities dimensions'
          RETURN
      END IF
      
      ! Delegate to Methods layer
      CALL PH_Cont_UpdateFriction(ctx, in, out)
      
  END SUBROUTINE PH_Cont_UpdateFriction_API
END MODULE PH_Cont_Brg