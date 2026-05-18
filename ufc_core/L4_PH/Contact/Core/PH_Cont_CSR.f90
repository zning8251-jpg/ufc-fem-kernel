!===============================================================================
! MODULE: PH_Cont_CSR
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Core
! BRIEF:  Contact stiffness CSR assembly + residual force integration
!
! Theory: Wriggers Computational Contact Mechanics §6.2; ABAQUS Theory §5.2
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_CSR
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Cont_Friction, ONLY: PH_Cont_FrictModel, PH_Cont_FrictState, &
                              PH_ContFric_TangentStiff, PH_FRICT_COULOMB
  IMPLICIT NONE
  PRIVATE

  ! ===================================================================
  ! Public Procedures - CSR Matrix Assembly
  ! ===================================================================
  PUBLIC :: PH_ContCSR_AssembleStiffness
  PUBLIC :: PH_ContCSR_AssembleStiffnessWithFriction
  PUBLIC :: PH_ContCSR_AssembleResidual
  PUBLIC :: PH_ContCSR_ComputeTangentStiffness
  PUBLIC :: PH_ContCSR_ComputeContactForceVector
  PUBLIC :: PH_ContCSR_AssembleStiffness_Parallel
  PUBLIC :: PH_ContCSR_AssembleResidual_Parallel

  ! ===================================================================
  ! Constants
  ! ===================================================================
  REAL(wp), PARAMETER, PUBLIC :: PH_ContCSR_ZERO_TOL = 1.0e-12_wp

CONTAINS

  !===========================================================================
  ! Assemble Contact Stiffness Matrix (CSR Format)
  !===========================================================================
  SUBROUTINE PH_ContCSR_AssembleStiffness(n_contacts, node_ids, normals, &
                                          penetrations, penalty_stiffness, &
                                          n_dofs, row_ptr, col_idx, values, &
                                          assemble_tangent, status)
    !! Assemble contact contribution to global stiffness matrix in CSR format
    !! 
    !! Mathematical Model:
    !!   K_contact = Σ ∂F_c/∂u = Σ k_penalty * (n �?n)
    !! 
    !! CSR Format:
    !!   - row_ptr(i): Start index of row i
    !!   - col_idx(j): Column index for entry j
    !!   - values(j): Value of entry j
    !! 
    !! Arguments:
    !!   n_contacts: Number of active contact points
    !!   node_ids: Slave node IDs (n_contacts)
    !!   normals: Contact normals (n_contacts, 3)
    !!   penetrations: Penetration depths (n_contacts)
    !!   penalty_stiffness: Penalty factor k
    !!   n_dofs: Total degrees of freedom
    !!   row_ptr: CSR row pointers (n_dofs+1)
    !!   col_idx: CSR column indices (nnz)
    !!   values: CSR values (nnz) - INOUT (additive)
    !!   assemble_tangent: Flag to assemble tangent stiffness
    !!   status: Error status
    
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:)         ! (n_contacts)
    REAL(wp), INTENT(IN) :: normals(:,:)           ! (n_contacts, 3)
    REAL(wp), INTENT(IN) :: penetrations(:)        ! (n_contacts)
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_dofs
    INTEGER(i4), INTENT(IN) :: row_ptr(:)          ! (n_dofs+1)
    INTEGER(i4), INTENT(IN) :: col_idx(:)          ! (nnz)
    REAL(wp), INTENT(INOUT) :: values(:)           ! (nnz)
    LOGICAL, INTENT(IN), OPTIONAL :: assemble_tangent
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c, dof_i, dof_j, idx, n_dof_per_node, k
    REAL(wp) :: normal(3), k_normal(3,3), k_penalty
    LOGICAL :: do_assemble_tangent
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate input
    IF (SIZE(node_ids) /= n_contacts .OR. SIZE(normals,1) /= n_contacts) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'PH_ContCSR_AssembleStiffness: Array size mismatch'
      END IF
      RETURN
    END IF
    
    ! Determine assembly mode
    do_assemble_tangent = .TRUE.
    IF (PRESENT(assemble_tangent)) do_assemble_tangent = assemble_tangent
    
    ! Process each contact point
    DO i = 1, n_contacts
      IF (penetrations(i) <= PH_ContCSR_ZERO_TOL) CYCLE
      
      ! Get contact normal and compute normal stiffness matrix
      normal = normals(i, :)
      
      IF (do_assemble_tangent) THEN
        ! Tangent stiffness: K = k * (n �?n)
        k_penalty = penalty_stiffness
      ELSE
        ! Secant stiffness (simplified)
        k_penalty = penalty_stiffness
      END IF
      
      ! Compute dyadic product: k_normal = k_penalty * (normal �?normal)
      k_normal = MATMUL(RESHAPE(normal, [3,1]), RESHAPE(normal, [1,3])) * k_penalty
      
      ! Assemble to global CSR matrix
      ! Each node has 3 DOFs (ux, uy, uz)
      n_dof_per_node = 3
      
      DO c = 1, 3  ! ux, uy, uz
        dof_i = (node_ids(i) - 1) * n_dof_per_node + c
        
        ! Find row in CSR matrix
        IF (dof_i < 1 .OR. dof_i > n_dofs) CYCLE
        
        ! Loop over columns in this row
        DO dof_j = dof_i, dof_i + 2  ! Only 3x3 block for this node
          IF (dof_j > n_dofs) CYCLE
          
          ! Find position in CSR structure
          idx = -1
          DO k = row_ptr(dof_i), row_ptr(dof_i+1) - 1
            IF (col_idx(k) == dof_j) THEN
              idx = k
              EXIT
            END IF
          END DO
          
          ! Add stiffness if found
          IF (idx > 0) THEN
            values(idx) = values(idx) + k_normal(c, dof_j - dof_i + 1)
          END IF
        END DO
      END DO
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_AssembleStiffness

  !===========================================================================
  ! Assemble Contact Stiffness Matrix WITH Friction (CSR Format)
  !===========================================================================
  SUBROUTINE PH_ContCSR_AssembleStiffnessWithFriction(n_contacts, node_ids, normals, &
                                                      penetrations, tangent_vel, &
                                                      frict_model, penalty_stiffness, &
                                                      n_dofs, row_ptr, col_idx, values, &
                                                      assemble_tangent, status)
    !! Assemble contact stiffness matrix with friction contribution in CSR format
    !! 
    !! Mathematical Model:
    !!   K_contact = K_normal + K_friction
    !!   K_friction = ∂F_friction/∂u = μ * k_penalty * (t �?t)
    !! where:
    !!   t = tangent direction vector
    !!   μ = friction coefficient
    !! 
    !! Arguments:
    !!   n_contacts: Number of active contact points
    !!   node_ids: Slave node IDs (n_contacts)
    !!   normals: Contact normals (n_contacts, 3)
    !!   penetrations: Penetration depths (n_contacts)
    !!   tangent_vel: Tangential velocity (n_contacts, 3)
    !!   frict_model: Friction model parameters
    !!   penalty_stiffness: Penalty factor k
    !!   n_dofs: Total degrees of freedom
    !!   row_ptr: CSR row pointers (n_dofs+1)
    !!   col_idx: CSR column indices (nnz)
    !!   values: CSR values (nnz) - INOUT (additive)
    !!   assemble_tangent: Flag to assemble tangent stiffness
    !!   status: Error status
    
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:)         ! (n_contacts)
    REAL(wp), INTENT(IN) :: normals(:,:)           ! (n_contacts, 3)
    REAL(wp), INTENT(IN) :: penetrations(:)        ! (n_contacts)
    REAL(wp), INTENT(IN) :: tangent_vel(:,:)       ! (n_contacts, 3)
    TYPE(PH_Cont_FrictModel), INTENT(IN) :: frict_model
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_dofs
    INTEGER(i4), INTENT(IN) :: row_ptr(:)          ! (n_dofs+1)
    INTEGER(i4), INTENT(IN) :: col_idx(:)          ! (nnz)
    REAL(wp), INTENT(INOUT) :: values(:)           ! (nnz)
    LOGICAL, INTENT(IN), OPTIONAL :: assemble_tangent
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c, dof_i, dof_j, idx, n_dof_per_node, k
    REAL(wp) :: normal(3), k_normal(3,3), k_friction(3,3)
    REAL(wp) :: frict_force(3), vel_mag, t_dir(3)
    REAL(wp) :: k_penalty, mu_eff
    LOGICAL :: do_assemble_tangent
    TYPE(PH_Cont_FrictState) :: frict_state
    TYPE(ErrorStatusType) :: local_status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate input
    IF (SIZE(node_ids) /= n_contacts .OR. SIZE(normals,1) /= n_contacts) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'PH_ContCSR_AssembleStiffnessWithFriction: Array size mismatch'
      END IF
      RETURN
    END IF
    
    ! Determine assembly mode
    do_assemble_tangent = .TRUE.
    IF (PRESENT(assemble_tangent)) do_assemble_tangent = assemble_tangent
    
    ! Process each contact point
    DO i = 1, n_contacts
      IF (penetrations(i) <= PH_ContCSR_ZERO_TOL) CYCLE
      
      ! Get contact normal
      normal = normals(i, :)
      
      ! Compute normal stiffness: K_normal = k * (n �?n)
      k_penalty = penalty_stiffness
      k_normal = MATMUL(RESHAPE(normal, [3,1]), RESHAPE(normal, [1,3])) * k_penalty
      
      ! Compute friction stiffness using PH_ContFriction_Algo API
      IF (frict_model%model_type == PH_FRICT_COULOMB) THEN
        ! Initialize friction state
        frict_state%normal_force = penalty_stiffness * penetrations(i)
        frict_state%tangent_vel = tangent_vel(i, :)
        
        ! Compute friction tangent stiffness
        CALL PH_ContFric_TangentStiff(frict_model, frict_state, &
                                     frict_state%normal_force, &
                                     k_friction, local_status)
        
        mu_eff = frict_model%mu_kinetic
        IF (mu_eff <= 0.0_wp) mu_eff = frict_model%mu_static
      ELSE
        ! Simplified friction for other models
        vel_mag = SQRT(SUM(tangent_vel(i,:)**2))
        IF (vel_mag > 1.0e-12_wp) THEN
          t_dir = tangent_vel(i, :) / vel_mag
          mu_eff = frict_model%mu_kinetic
          k_friction = MATMUL(RESHAPE(t_dir, [3,1]), RESHAPE(t_dir, [1,3])) * &
                      (mu_eff * k_penalty)
        ELSE
          k_friction = 0.0_wp
        END IF
      END IF
      
      ! Assemble combined stiffness: K_total = K_normal + K_friction
      n_dof_per_node = 3
      
      DO c = 1, 3  ! ux, uy, uz
        dof_i = (node_ids(i) - 1) * n_dof_per_node + c
        
        ! Find row in CSR matrix
        IF (dof_i < 1 .OR. dof_i > n_dofs) CYCLE
        
        ! Loop over columns in this row
        DO dof_j = dof_i, dof_i + 2  ! Only 3x3 block for this node
          IF (dof_j > n_dofs) CYCLE
          
          ! Find position in CSR structure
          idx = -1
          DO k = row_ptr(dof_i), row_ptr(dof_i+1) - 1
            IF (col_idx(k) == dof_j) THEN
              idx = k
              EXIT
            END IF
          END DO
          
          ! Add combined stiffness if found
          IF (idx > 0) THEN
            values(idx) = values(idx) + k_normal(c, dof_j - dof_i + 1) + &
                         k_friction(c, dof_j - dof_i + 1)
          END IF
        END DO
      END DO
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_AssembleStiffnessWithFriction

  !===========================================================================
  ! Assemble Residual Force Vector
  !===========================================================================
  SUBROUTINE PH_ContCSR_AssembleResidual(n_contacts, node_ids, normals, &
                                         penetrations, penalty_stiffness, &
                                         n_dofs, rhs, status)
    !! Assemble contact contribution to global residual force vector
    !! 
    !! Mathematical Model:
    !!   R_contact = Σ F_c = Σ (-k_penalty * penetration * normal)
    !! 
    !! Arguments:
    !!   n_contacts: Number of active contact points
    !!   node_ids: Slave node IDs (n_contacts)
    !!   normals: Contact normals (n_contacts, 3)
    !!   penetrations: Penetration depths (n_contacts)
    !!   penalty_stiffness: Penalty factor k
    !!   n_dofs: Total degrees of freedom
    !!   rhs: Global residual vector (n_dofs) - INOUT (additive)
    !!   status: Error status
    
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:)         ! (n_contacts)
    REAL(wp), INTENT(IN) :: normals(:,:)           ! (n_contacts, 3)
    REAL(wp), INTENT(IN) :: penetrations(:)        ! (n_contacts)
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_dofs
    REAL(wp), INTENT(INOUT) :: rhs(:)              ! (n_dofs)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c, dof_idx, n_dof_per_node
    REAL(wp) :: normal(3), force(3), penetration
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate
    IF (SIZE(rhs) /= n_dofs) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'PH_ContCSR_AssembleResidual: RHS size mismatch'
      END IF
      RETURN
    END IF
    
    n_dof_per_node = 3
    
    ! Process each contact point
    DO i = 1, n_contacts
      penetration = penetrations(i)
      
      ! Skip if no penetration
      IF (penetration <= PH_ContCSR_ZERO_TOL) CYCLE
      
      ! Compute contact force: F = -k * p * n
      normal = normals(i, :)
      force = -penalty_stiffness * penetration * normal
      
      ! Assemble to global residual
      dof_idx = (node_ids(i) - 1) * n_dof_per_node
      
      DO c = 1, 3
        IF (dof_idx + c >= 1 .AND. dof_idx + c <= n_dofs) THEN
          rhs(dof_idx + c) = rhs(dof_idx + c) + force(c)
        END IF
      END DO
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_AssembleResidual

  !===========================================================================
  ! Compute Tangent Stiffness Matrix (3x3 block)
  !===========================================================================
  SUBROUTINE PH_ContCSR_ComputeTangentStiffness(normal, penalty_stiffness, &
                                                penetration, K_tangent, status)
    !! Compute contact tangent stiffness matrix (3x3 block for one node)
    !! 
    !! Mathematical Model:
    !!   K_tangent = k_penalty * (normal �?normal)
    !! 
    !! Arguments:
    !!   normal: Contact normal vector (3)
    !!   penalty_stiffness: Penalty factor k
    !!   penetration: Penetration depth
    !!   K_tangent: Output 3x3 tangent stiffness matrix
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: normal(3)
    REAL(wp), INTENT(IN) :: penalty_stiffness
    REAL(wp), INTENT(IN) :: penetration
    REAL(wp), INTENT(OUT) :: K_tangent(3,3)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Compute dyadic product: K = k * (n �?n)
    K_tangent = MATMUL(RESHAPE(normal, [3,1]), RESHAPE(normal, [1,3])) * penalty_stiffness
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_ComputeTangentStiffness

  !===========================================================================
  ! Compute Contact Force Vector (3 DOFs per node)
  !===========================================================================
  SUBROUTINE PH_ContCSR_ComputeContactForceVector(normal, penetration, &
                                                  penalty_stiffness, F_contact, status)
    !! Compute contact force vector for one contact point
    !! 
    !! Physical Model:
    !!   F_contact = -k_penalty * penetration * normal
    !! 
    !! Arguments:
    !!   normal: Contact normal vector (3)
    !!   penetration: Penetration depth
    !!   penalty_stiffness: Penalty factor k
    !!   F_contact: Output force vector (3)
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: normal(3)
    REAL(wp), INTENT(IN) :: penetration
    REAL(wp), INTENT(IN) :: penalty_stiffness
    REAL(wp), INTENT(OUT) :: F_contact(3)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Compute force
    F_contact = -penalty_stiffness * penetration * normal
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_ComputeContactForceVector

  !===========================================================================
  ! Parallel Assembly using ThreadWS (Thread-Safe Workspace)
  !===========================================================================
  SUBROUTINE PH_ContCSR_AssembleStiffness_Parallel(n_contacts, node_ids, normals, &
                                                   penetrations, penalty_stiffness, &
                                                   n_dofs, row_ptr, col_idx, values, &
                                                   thread_ws, thread_id, status)
    !! Assemble contact stiffness in parallel using ThreadWS
    !! 
    !! Thread Safety:
    !!   - Each thread works on its own slice of contact pairs
    !!   - ThreadWS provides local workspace for partial results
    !!   - Final assembly is done by master thread
    !!
    !! Arguments:
    !!   n_contacts: Number of active contact points
    !!   node_ids: Slave node IDs (n_contacts)
    !!   normals: Contact normals (n_contacts, 3)
    !!   penetrations: Penetration depths (n_contacts)
    !!   penalty_stiffness: Penalty factor k
    !!   n_dofs: Total degrees of freedom
    !!   row_ptr: CSR row pointers (n_dofs+1)
    !!   col_idx: CSR column indices (nnz)
    !!   values: CSR values (nnz) - INOUT (additive)
    !!   thread_ws: Thread workspace for local storage
    !!   thread_id: ID of current thread (0-based)
    !!   status: Error status
    
    USE RT_Step_WS, ONLY: ThreadWS
    
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:)
    REAL(wp), INTENT(IN) :: normals(:,:)
    REAL(wp), INTENT(IN) :: penetrations(:)
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_dofs
    INTEGER(i4), INTENT(IN) :: row_ptr(:)
    INTEGER(i4), INTENT(IN) :: col_idx(:)
    REAL(wp), INTENT(INOUT) :: values(:)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: thread_id
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c, dof_i, dof_j, idx, n_dof_per_node, k
    INTEGER(i4) :: n_threads, contacts_per_thread, start_idx, end_idx
    REAL(wp) :: normal(3), k_normal(3,3), k_penalty
    REAL(wp), POINTER :: local_values(:) => NULL()
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Get thread information
    n_threads = thread_ws%n_threads
    contacts_per_thread = (n_contacts + n_threads - 1) / n_threads
    start_idx = thread_id * contacts_per_thread + 1
    end_idx = MIN((thread_id + 1) * contacts_per_thread, n_contacts)
    
    ! Get local workspace from ThreadWS
    CALL ThreadWS_GetLocalArray(thread_ws, thread_id, 'values', local_values)
    IF (.NOT. ASSOCIATED(local_values)) THEN
      ALLOCATE(local_values(SIZE(values)))
      local_values = 0.0_wp
    ELSE
      local_values = 0.0_wp
    END IF
    
    ! Process slice of contacts
    DO i = start_idx, end_idx
      IF (penetrations(i) <= PH_ContCSR_ZERO_TOL) CYCLE
      
      normal = normals(i, :)
      k_penalty = penalty_stiffness
      k_normal = MATMUL(RESHAPE(normal, [3,1]), RESHAPE(normal, [1,3])) * k_penalty
      
      n_dof_per_node = 3
      DO c = 1, 3
        dof_i = (node_ids(i) - 1) * n_dof_per_node + c
        IF (dof_i < 1 .OR. dof_i > n_dofs) CYCLE
        
        DO dof_j = dof_i, dof_i + 2
          IF (dof_j > n_dofs) CYCLE
          idx = -1
          DO k = row_ptr(dof_i), row_ptr(dof_i+1) - 1
            IF (col_idx(k) == dof_j) THEN
              idx = k
              EXIT
            END IF
          END DO
          IF (idx > 0) THEN
            local_values(idx) = local_values(idx) + k_normal(c, dof_j - dof_i + 1)
          END IF
        END DO
      END DO
    END DO
    
    ! Copy local to global (thread-safe atomic add would be done here)
    ! In a real implementation, use critical section or atomic operations
    !$OMP CRITICAL
    DO idx = 1, SIZE(values)
      values(idx) = values(idx) + local_values(idx)
    END DO
    !$OMP END CRITICAL
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_AssembleStiffness_Parallel

  !===========================================================================
  ! Parallel Residual Assembly using ThreadWS
  !===========================================================================
  SUBROUTINE PH_ContCSR_AssembleResidual_Parallel(n_contacts, node_ids, normals, &
                                                  penetrations, penalty_stiffness, &
                                                  n_dofs, rhs, thread_ws, thread_id, status)
    !! Assemble contact residual in parallel using ThreadWS
    
    USE RT_Step_WS, ONLY: ThreadWS
    
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:)
    REAL(wp), INTENT(IN) :: normals(:,:)
    REAL(wp), INTENT(IN) :: penetrations(:)
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_dofs
    REAL(wp), INTENT(INOUT) :: rhs(:)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: thread_id
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, c, dof_idx, n_dof_per_node
    INTEGER(i4) :: n_threads, contacts_per_thread, start_idx, end_idx
    REAL(wp) :: normal(3), force(3), penetration
    REAL(wp), POINTER :: local_rhs(:) => NULL()
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    n_threads = thread_ws%n_threads
    contacts_per_thread = (n_contacts + n_threads - 1) / n_threads
    start_idx = thread_id * contacts_per_thread + 1
    end_idx = MIN((thread_id + 1) * contacts_per_thread, n_contacts)
    
    CALL ThreadWS_GetLocalArray(thread_ws, thread_id, 'rhs', local_rhs)
    IF (.NOT. ASSOCIATED(local_rhs)) THEN
      ALLOCATE(local_rhs(n_dofs))
      local_rhs = 0.0_wp
    ELSE
      local_rhs = 0.0_wp
    END IF
    
    n_dof_per_node = 3
    
    DO i = start_idx, end_idx
      penetration = penetrations(i)
      IF (penetration <= PH_ContCSR_ZERO_TOL) CYCLE
      
      normal = normals(i, :)
      force = -penalty_stiffness * penetration * normal
      
      dof_idx = (node_ids(i) - 1) * n_dof_per_node
      DO c = 1, 3
        IF (dof_idx + c >= 1 .AND. dof_idx + c <= n_dofs) THEN
          local_rhs(dof_idx + c) = local_rhs(dof_idx + c) + force(c)
        END IF
      END DO
    END DO
    
    !$OMP CRITICAL
    DO i = 1, n_dofs
      rhs(i) = rhs(i) + local_rhs(i)
    END DO
    !$OMP END CRITICAL
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContCSR_AssembleResidual_Parallel

END MODULE PH_Cont_CSR