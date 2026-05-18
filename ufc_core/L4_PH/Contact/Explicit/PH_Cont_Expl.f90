!===============================================================================
! MODULE: PH_Cont_Expl
! LAYER:  L4_PH
! DOMAIN: Contact / Explicit
! ROLE:   Core
! BRIEF:  Explicit contact force, energy, critical dt, damping
!
! Theory: Belytschko FEM §9.1; LS-DYNA Theory §3.2
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_Expl
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! ===================================================================
  ! Public Procedures - Pure Physics Computation
  ! ===================================================================
  PUBLIC :: PH_ContExpl_ComputeForce
  PUBLIC :: PH_ContExpl_ComputeEnergy
  PUBLIC :: PH_ContExpl_CriticalTimeStep
  PUBLIC :: PH_ContExpl_GetEnergyStats
  PUBLIC :: PH_ContExpl_ApplyDamping

  ! ===================================================================
  ! Constants
  ! ===================================================================
  REAL(wp), PARAMETER, PUBLIC :: PH_ContExpl_MIN_PENETRATION = 1.0e-12_wp
  REAL(wp), PARAMETER, PUBLIC :: PH_ContExpl_DEFAULT_SAFETY = 0.8_wp

CONTAINS

  !===========================================================================
  ! Compute Contact Force (Penalty Method + Optional Damping)
  !===========================================================================
  SUBROUTINE PH_ContExpl_ComputeForce(penalty_stiffness, n_contacts, &
                                      node_ids, penetrations, normals, &
                                      coords, velocities, F_contact, n_dofs, &
                                      use_damping, damping_normal, damping_tangent, &
                                      dt, work_done, status)
    !! Compute explicit contact forces using penalty method
    !! 
    !! Physical Model:
    !!   F_contact = -k_penalty * penetration * normal + F_damping
    !! 
    !! Arguments:
    !!   penalty_stiffness: Penalty factor k
    !!   n_contacts: Number of active contact points
    !!   node_ids: Slave node IDs (n_contacts)
    !!   penetrations: Penetration depths (n_contacts)
    !!   normals: Contact normals (n_contacts, 3)
    !!   coords: Nodal coordinates (n_nodes, 3)
    !!   velocities: Nodal velocities (n_dofs)
    !!   F_contact: Output contact forces (n_dofs)
    !!   n_dofs: Total degrees of freedom
    !!   use_damping: Enable damping flag
    !!   damping_normal: Normal damping coefficient c_n
    !!   damping_tangent: Tangential damping coefficient c_t
    !!   dt: Time step (optional, for work accumulation)
    !!   work_done: Work done by contact forces (optional, output)
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:)      ! (n_contacts)
    REAL(wp), INTENT(IN) :: penetrations(:)     ! (n_contacts)
    REAL(wp), INTENT(IN) :: normals(:,:)        ! (n_contacts, 3)
    REAL(wp), INTENT(IN) :: coords(:,:)         ! (n_nodes, 3)
    REAL(wp), INTENT(IN) :: velocities(:)       ! (n_dofs)
    REAL(wp), INTENT(OUT) :: F_contact(:)       ! (n_dofs)
    INTEGER(i4), INTENT(IN) :: n_dofs
    LOGICAL, INTENT(IN), OPTIONAL :: use_damping
    REAL(wp), INTENT(IN), OPTIONAL :: damping_normal
    REAL(wp), INTENT(IN), OPTIONAL :: damping_tangent
    REAL(wp), INTENT(IN), OPTIONAL :: dt
    REAL(wp), INTENT(OUT), OPTIONAL :: work_done
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, node_id, dof_idx
    REAL(wp) :: penetration, normal(3), force(3)
    REAL(wp) :: v_relative(3), damping_force(3)
    REAL(wp) :: c_n, c_t, v_n(3), v_t(3)
    REAL(wp) :: local_work
    
    ! Initialize
    IF (PRESENT(status)) CALL init_error_status(status)
    F_contact = 0.0_wp
    local_work = 0.0_wp
    
    ! Validate input
    IF (SIZE(node_ids) /= n_contacts .OR. SIZE(penetrations) /= n_contacts) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'PH_ContExpl_ComputeForce: Array size mismatch'
      END IF
      RETURN
    END IF
    
    ! Process each contact point
    DO i = 1, n_contacts
      penetration = penetrations(i)
      
      ! Skip if no penetration
      IF (penetration <= PH_ContExpl_MIN_PENETRATION) CYCLE
      
      ! Get contact normal
      normal = normals(i, :)
      
      ! Compute penalty force: F = -k * penetration * normal
      force = -penalty_stiffness * penetration * normal
      
      ! Add damping if enabled
      IF (PRESENT(use_damping) .AND. use_damping) THEN
        node_id = node_ids(i)
        
        ! Get slave node velocity
        dof_idx = (node_id - 1) * 3 + 1
        IF (dof_idx >= 1 .AND. dof_idx + 2 <= SIZE(velocities)) THEN
          v_relative = velocities(dof_idx:dof_idx+2)
          
          ! Normal/tangential damping decomposition
          c_n = 0.1_wp  ! Default
          IF (PRESENT(damping_normal)) c_n = damping_normal
          c_t = 0.0_wp
          IF (PRESENT(damping_tangent)) c_t = damping_tangent
          
          ! Decompose velocity into normal and tangential components
          v_n = DOT_PRODUCT(v_relative, normal) * normal
          v_t = v_relative - v_n
          
          ! Compute damping force
          damping_force = -c_n * v_n - c_t * v_t
          force = force + damping_force
        END IF
      END IF
      
      ! Apply force to slave node
      node_id = node_ids(i)
      dof_idx = (node_id - 1) * 3 + 1
      
      IF (dof_idx >= 1 .AND. dof_idx + 2 <= n_dofs) THEN
        F_contact(dof_idx:dof_idx+2) = F_contact(dof_idx:dof_idx+2) + force
        
        ! Accumulate work if dt provided
        IF (PRESENT(dt) .AND. dt > 0.0_wp) THEN
          local_work = local_work + DOT_PRODUCT(force, v_relative) * dt
        END IF
      END IF
    END DO
    
    ! Return work done
    IF (PRESENT(work_done)) work_done = local_work
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContExpl_ComputeForce

  !===========================================================================
  ! Compute Contact Energy
  !===========================================================================
  SUBROUTINE PH_ContExpl_ComputeEnergy(penalty_stiffness, n_contacts, &
                                       penetrations, E_contact, status)
    !! Compute contact strain energy
    !! 
    !! Physical Model:
    !!   E_contact = Σ (1/2) * k_penalty * penetration_i^2
    !! 
    !! Arguments:
    !!   penalty_stiffness: Penalty factor k
    !!   n_contacts: Number of active contact points
    !!   penetrations: Penetration depths (n_contacts)
    !!   E_contact: Total contact energy (output)
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: n_contacts
    REAL(wp), INTENT(IN) :: penetrations(:)  ! (n_contacts)
    REAL(wp), INTENT(OUT) :: E_contact
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i
    REAL(wp) :: penetration
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate
    IF (SIZE(penetrations) /= n_contacts) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'PH_ContExpl_ComputeEnergy: Array size mismatch'
      END IF
      E_contact = 0.0_wp
      RETURN
    END IF
    
    ! Compute energy: E = Σ ½*k*p²
    E_contact = 0.0_wp
    DO i = 1, n_contacts
      penetration = penetrations(i)
      IF (penetration > PH_ContExpl_MIN_PENETRATION) THEN
        E_contact = E_contact + 0.5_wp * penalty_stiffness * penetration * penetration
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContExpl_ComputeEnergy

  !===========================================================================
  ! Critical Time Step (CFL Condition)
  !===========================================================================
  SUBROUTINE PH_ContExpl_CriticalTimeStep(penalty_stiffness, mass_min, dt_crit, status)
    !! Compute critical time step for explicit integration
    !! 
    !! Stability Criterion (CFL):
    !!   dt_crit = 2 * sqrt(m_min / k_penalty) * safety_factor
    !! 
    !! Arguments:
    !!   penalty_stiffness: Penalty stiffness k
    !!   mass_min: Minimum nodal mass in contact zone
    !!   dt_crit: Critical time step (output)
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: penalty_stiffness
    REAL(wp), INTENT(IN) :: mass_min
    REAL(wp), INTENT(OUT) :: dt_crit
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate parameters
    IF (penalty_stiffness <= 0.0_wp .OR. mass_min <= 0.0_wp) THEN
      dt_crit = HUGE(1.0_wp)
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_WARN
        status%message = 'PH_ContExpl_CriticalTimeStep: Invalid penalty or mass'
      END IF
      RETURN
    END IF
    
    ! CFL condition: dt < 2*sqrt(m/k)
    dt_crit = 2.0_wp * SQRT(mass_min / penalty_stiffness) * PH_ContExpl_DEFAULT_SAFETY
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContExpl_CriticalTimeStep

  !===========================================================================
  ! Energy Statistics
  !===========================================================================
  SUBROUTINE PH_ContExpl_GetEnergyStats(E_contact, work_contact, energy_error, status)
    !! Compute contact energy error metric
    !! 
    !! Energy Balance:
    !!   energy_error = E_contact - work_contact
    !!   (Should be ~0 for conservative system)
    !! 
    !! Arguments:
    !!   E_contact: Contact strain energy
    !!   work_contact: Work done by contact forces
    !!   energy_error: Energy balance error (output)
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: E_contact
    REAL(wp), INTENT(IN) :: work_contact
    REAL(wp), INTENT(OUT) :: energy_error
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Energy balance check
    energy_error = E_contact - work_contact
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContExpl_GetEnergyStats

  !===========================================================================
  ! Apply Damping Force (Standalone)
  !===========================================================================
  SUBROUTINE PH_ContExpl_ApplyDamping(velocity, normal, damping_normal, &
                                      damping_tangent, damping_force, status)
    !! Compute damping force from velocity
    !! 
    !! Damping Model:
    !!   F_damp = -c_n * v_n - c_t * v_t
    !!   where v_n = (v·n)n, v_t = v - v_n
    !! 
    !! Arguments:
    !!   velocity: Relative velocity vector (3)
    !!   normal: Contact normal vector (3)
    !!   damping_normal: Normal damping coefficient c_n
    !!   damping_tangent: Tangential damping coefficient c_t
    !!   damping_force: Output damping force (3)
    !!   status: Error status
    
    REAL(wp), INTENT(IN) :: velocity(3)
    REAL(wp), INTENT(IN) :: normal(3)
    REAL(wp), INTENT(IN) :: damping_normal
    REAL(wp), INTENT(IN) :: damping_tangent
    REAL(wp), INTENT(OUT) :: damping_force(3)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: v_n(3), v_t(3), v_normal
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Decompose velocity
    v_normal = DOT_PRODUCT(velocity, normal)
    v_n = v_normal * normal
    v_t = velocity - v_n
    
    ! Compute damping force
    damping_force = -damping_normal * v_n - damping_tangent * v_t
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContExpl_ApplyDamping

END MODULE PH_Cont_Expl