!===============================================================================
! MODULE: RT_Solv_ContResidual
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Proc (Contact Residual)
! BRIEF:  Integrate contact residual/stiffness into global NR system
!===============================================================================
!
! Theory:  Wriggers Computational Contact Mechanics §6.1; ABAQUS Theory §5.1
!
! Mathematical Model:
!   R_total(u) = R_internal(u) + R_contact(u) - R_external(lambda)
!   K_tangent = K_material + K_contact
!
! Process族:
!   P1: Populate (assemble contact residual into global RHS)    [HOT_PATH]
!   P2: Compute (update contact state, check convergence)       [HOT_PATH]
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE RT_Solv_ContResidual
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE PH_Cont_CSR, ONLY: PH_ContCSR_AssembleResidual, PH_ContCSR_AssembleStiffnessWithFriction
  USE PH_Cont_Friction, ONLY: PH_Cont_FrictModel, PH_Cont_FrictState, PH_FRICT_COULOMB
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Solv_Cont_AssembleGlobalResidual
  PUBLIC :: RT_Solv_Cont_UpdateContactState
  PUBLIC :: RT_Solv_Cont_CheckConvergence
  
  ! ===================================================================
  ! Type Definitions (Local to avoid circular dependencies)
  ! ===================================================================
  
  !> Contact pair data structure
  TYPE, PUBLIC :: RT_ContactData
    INTEGER(i4) :: slave_node_id       ! Slave node ID
    INTEGER(i4) :: master_node_id      ! Master node ID (or surface ID)
    REAL(wp) :: penetration_depth = 0.0_wp  ! Current penetration
    REAL(wp) :: contact_normal(3) = [0.0_wp, 0.0_wp, 0.0_wp]  ! Contact normal direction
    REAL(wp) :: penalty_stiffness = 0.0_wp  ! Penalty stiffness for this pair
    LOGICAL :: is_active = .FALSE.     ! Active contact flag
  END TYPE RT_ContactData
  
  !> Solver state with contact support
  TYPE, PUBLIC :: RT_Solver_State
    INTEGER(i4) :: n_dofs              ! Total degrees of freedom
    REAL(wp), ALLOCATABLE :: displacement(:)  ! Displacement field [n_dofs]
    REAL(wp), ALLOCATABLE :: velocity(:)      ! Velocity field [n_dofs]
    REAL(wp), ALLOCATABLE :: acceleration(:)  ! Acceleration field [n_dofs]
    REAL(wp), ALLOCATABLE :: reference_coords(:)  ! Reference coordinates [n_dofs]
    
    ! CSR matrix storage
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)
    INTEGER(i4), ALLOCATABLE :: col_idx(:)
    REAL(wp), ALLOCATABLE :: values(:)
  END TYPE RT_Solver_State
  
  ! ===================================================================
  ! Constants
  ! ===================================================================
  REAL(wp), PARAMETER, PUBLIC :: RT_Solv_Cont_CONV_TOL = 1.0e-6_wp
  REAL(wp), PARAMETER, PUBLIC :: RT_Solv_Cont_ZERO_PENETRATION = 1.0e-12_wp
  
CONTAINS

  !===========================================================================
  !> @brief Assemble contact residual into global RHS vector
  !===========================================================================
  SUBROUTINE RT_Solv_Cont_AssembleGlobalResidual( &
       solver_state, n_contacts, contact_data, &
       frict_model, penalty_stiffness, &
       global_rhs, assemble_contact_stiffness, status)
    !! Assemble contact residual force into global system RHS vector
    !! 
    !! Algorithm:
    !!   1. Extract active contact pairs from contact_data
    !!   2. Compute penetration and contact normal for each pair
    !!   3. Calculate contact force: F_c = -k * penetration * normal
    !!   4. If friction enabled, add tangential friction force
    !!   5. Assemble into global residual: R += F_contact
    !! 
    !! Arguments:
    !!   solver_state: Global solver state (contains displacement field u)
    !!   n_contacts: Number of active contact points
    !!   contact_data: Contact pair data structure (slave/master nodes, normals, etc.)
    !!   frict_model: Friction model parameters (mu_static, mu_kinetic, etc.)
    !!   penalty_stiffness: Penalty stiffness parameter k
    !!   global_rhs: Global residual vector [n_dofs] - INOUT (additive)
    !!   assemble_contact_stiffness: Flag to also assemble tangent stiffness
    !!   status: Error status
    
    TYPE(RT_Solver_State), INTENT(INOUT) :: solver_state
    INTEGER(i4), INTENT(IN) :: n_contacts
    TYPE(RT_ContactData), INTENT(INOUT) :: contact_data(:)  ! Array of contact pairs
    TYPE(PH_Cont_FrictModel), INTENT(IN) :: frict_model
    REAL(wp), INTENT(IN) :: penalty_stiffness
    REAL(wp), INTENT(INOUT) :: global_rhs(:)  ! [n_dofs]
    LOGICAL, INTENT(IN), OPTIONAL :: assemble_contact_stiffness
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c, dof_idx, n_dof_per_node
    INTEGER(i4) :: slave_node_id, master_node_id
    REAL(wp) :: penetration, normal(3), tangent_vel(3)
    REAL(wp) :: contact_force(3), force_mag
    REAL(wp), ALLOCATABLE :: node_ids(:), normals(:,:), penetrations(:), tangent_vels(:,:)
    TYPE(ErrorStatusType) :: local_status
    LOGICAL :: do_assemble_stiffness
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Determine assembly mode
    do_assemble_stiffness = .FALSE.
    IF (PRESENT(assemble_contact_stiffness)) THEN
      do_assemble_stiffness = assemble_contact_stiffness
    END IF
    
    ! Validate input
    IF (SIZE(global_rhs) /= solver_state%n_dofs) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_Solv_Cont_AssembleGlobalResidual: RHS size mismatch'
      END IF
      RETURN
    END IF
    
    ! Return early if no contacts
    IF (n_contacts <= 0) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Allocate temporary arrays for PH_ContCSR_Algo API
    ALLOCATE(node_ids(n_contacts), normals(n_contacts, 3), &
             penetrations(n_contacts), tangent_vels(n_contacts, 3))
    
    ! Extract contact data for active pairs
    DO i = 1, n_contacts
      IF (.NOT. contact_data(i)%is_active) CYCLE
      
      ! Get slave node ID and compute penetration
      slave_node_id = contact_data(i)%slave_node_id
      penetration = contact_data(i)%penetration_depth
      
      ! Skip if no penetration
      IF (penetration <= RT_Solv_Cont_ZERO_PENETRATION) CYCLE
      
      ! Store contact data
      node_ids(i) = slave_node_id
      normals(i, :) = contact_data(i)%contact_normal
      penetrations(i) = penetration
      
      ! Compute relative tangential velocity (for friction)
      master_node_id = contact_data(i)%master_node_id
      DO c = 1, 3
        tangent_vels(i, c) = solver_state%velocity(3*(slave_node_id-1)+c) - &
                            solver_state%velocity(3*(master_node_id-1)+c)
      END DO
    END DO
    
    ! Call PH_ContCSR_Algo to assemble residual (pure physics computation)
    CALL PH_ContCSR_AssembleResidual( &
         n_contacts, node_ids, normals, penetrations, &
         penalty_stiffness, &
         solver_state%n_dofs, global_rhs, &
         local_status)
    
    ! Check for errors
    IF (local_status%status_code /= IF_STATUS_OK) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_Solv_Cont_AssembleGlobalResidual: PH_ContCSR failed'
      END IF
      RETURN
    END IF
    
    ! Optionally assemble contact tangent stiffness
    IF (do_assemble_stiffness) THEN
      CALL PH_ContCSR_AssembleStiffnessWithFriction( &
           n_contacts, node_ids, normals, penetrations, tangent_vels, &
           frict_model, penalty_stiffness, &
           solver_state%n_dofs, &
           solver_state%row_ptr, solver_state%col_idx, solver_state%values, &
           assemble_tangent=.TRUE., status=local_status)
      
      IF (local_status%status_code /= IF_STATUS_OK) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_ERROR
          status%message = 'RT_Solv_Cont_AssembleGlobalResidual: Contact stiffness assembly failed'
        END IF
        RETURN
      END IF
    END IF
    
    ! Cleanup
    DEALLOCATE(node_ids, normals, penetrations, tangent_vels)
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Cont_AssembleGlobalResidual

  !===========================================================================
  !> @brief Update contact state before residual evaluation
  !===========================================================================
  SUBROUTINE RT_Solv_Cont_UpdateContactState(solver_state, contact_data, &
                                             n_contacts, status)
    !! Update contact kinematics (penetration, normal, etc.) based on current displacement
    !! 
    !! Algorithm:
    !!   1. For each contact pair:
    !!      a. Get current nodal positions: x = X + u
    !!      b. Find closest point projection on master surface
    !!      c. Compute penetration: p = (x_slave - x_master) · normal
    !!      d. Update contact normal direction
    !!      e. Detect active/inactive status
    !! 
    !! Arguments:
    !!   solver_state: Global solver state (contains displacement field u)
    !!   contact_data: Contact pair data structure - INOUT
    !!   n_contacts: Number of contact pairs
    !!   status: Error status
    
    TYPE(RT_Solver_State), INTENT(IN) :: solver_state
    TYPE(RT_ContactData), INTENT(INOUT) :: contact_data(:)
    INTEGER(i4), INTENT(IN) :: n_contacts
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c
    INTEGER(i4) :: slave_node_id, master_node_id
    REAL(wp) :: X_slave(3), X_master(3), u_slave(3), u_master(3)
    REAL(wp) :: x_slave(3), x_master(3), gap_vector(3)
    REAL(wp) :: normal(3), penetration, gap_mag
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Loop over all contact pairs
    DO i = 1, n_contacts
      slave_node_id = contact_data(i)%slave_node_id
      master_node_id = contact_data(i)%master_node_id
      
      ! Get reference coordinates
      DO c = 1, 3
        X_slave(c) = solver_state%reference_coords(3*(slave_node_id-1)+c)
        X_master(c) = solver_state%reference_coords(3*(master_node_id-1)+c)
        
        ! Get current displacements
        u_slave(c) = solver_state%displacement(3*(slave_node_id-1)+c)
        u_master(c) = solver_state%displacement(3*(master_node_id-1)+c)
        
        ! Compute current positions: x = X + u
        x_slave(c) = X_slave(c) + u_slave(c)
        x_master(c) = X_master(c) + u_master(c)
      END DO
      
      ! Compute gap vector
      gap_vector = x_slave - x_master
      
      ! Use predefined normal or compute from master surface geometry
      normal = contact_data(i)%contact_normal
      
      ! Normalize normal (safety check)
      gap_mag = SQRT(SUM(normal**2))
      IF (gap_mag > 1.0e-12_wp) THEN
        normal = normal / gap_mag
      END IF
      
      ! Compute penetration: p = gap · normal
      penetration = DOT_PRODUCT(gap_vector, normal)
      
      ! Update contact data
      contact_data(i)%penetration_depth = penetration
      contact_data(i)%contact_normal = normal
      
      ! Determine active status (penetration > 0 means contact)
      IF (penetration > RT_Solv_Cont_ZERO_PENETRATION) THEN
        contact_data(i)%is_active = .TRUE.
      ELSE
        contact_data(i)%is_active = .FALSE.
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Cont_UpdateContactState

  !===========================================================================
  !> @brief Check contact contribution to convergence
  !===========================================================================
  SUBROUTINE RT_Solv_Cont_CheckConvergence(contact_data, n_contacts, &
                                           global_residual, conv_norm, &
                                           is_converged, status)
    !! Check if contact forces have converged in Newton-Raphson iteration
    !! 
    !! Convergence Criteria:
    !!   ||R_contact|| / ||R_total|| < tolerance
    !! 
    !! where:
    !!   R_contact = contact residual forces
    !!   R_total = total system residual (internal + contact - external)
    !! 
    !! Arguments:
    !!   contact_data: Contact pair data structure
    !!   n_contacts: Number of contact pairs
    !!   global_residual: Current global residual vector
    !!   conv_norm: Output convergence norm (ratio)
    !!   is_converged: Output convergence flag
    !!   status: Error status
    
    TYPE(RT_ContactData), INTENT(IN) :: contact_data(:)
    INTEGER(i4), INTENT(IN) :: n_contacts
    REAL(wp), INTENT(IN) :: global_residual(:)
    REAL(wp), INTENT(OUT) :: conv_norm
    LOGICAL, INTENT(OUT) :: is_converged
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i
    REAL(wp) :: contact_force_norm, total_residual_norm
    REAL(wp) :: force_mag, tol
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Compute L2 norm of contact forces
    contact_force_norm = 0.0_wp
    DO i = 1, n_contacts
      IF (contact_data(i)%is_active) THEN
        force_mag = ABS(contact_data(i)%penetration_depth) * &
                   contact_data(i)%penalty_stiffness
        contact_force_norm = contact_force_norm + force_mag**2
      END IF
    END DO
    contact_force_norm = SQRT(contact_force_norm)
    
    ! Compute L2 norm of total residual
    total_residual_norm = SQRT(SUM(global_residual**2))
    
    ! Compute convergence ratio
    IF (total_residual_norm > 1.0e-12_wp) THEN
      conv_norm = contact_force_norm / total_residual_norm
    ELSE
      conv_norm = 0.0_wp
    END IF
    
    ! Check convergence
    tol = RT_Solv_Cont_CONV_TOL
    IF (conv_norm < tol) THEN
      is_converged = .TRUE.
    ELSE
      is_converged = .FALSE.
    END IF
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Cont_CheckConvergence

END MODULE RT_Solv_ContResidual