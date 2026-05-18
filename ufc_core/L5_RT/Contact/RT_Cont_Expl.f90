!===============================================================================
! MODULE: RT_Cont_Expl
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Exec �?explicit dynamics contact adapter
! BRIEF:  Thin adapter for explicit contact (delegates physics to L4_PH).
!===============================================================================

MODULE RT_Cont_Expl
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Cont_Expl, ONLY: PH_ContExpl_ComputeForce, PH_ContExpl_ComputeEnergy, &
                          PH_ContExpl_CriticalTimeStep, PH_ContExpl_GetEnergyStats
  IMPLICIT NONE
  PRIVATE

  ! ===================================================================
  ! Public Types
  ! ===================================================================
  public :: RT_Cont_Expl_Cfg
  public :: RT_Cont_Expl_State
  public :: RT_Cont_Expl_Solv
  ! Type alias for RT_Step_Expl compatibility
  public :: RT_ExplicitContactSolver

  ! ===================================================================
  ! Public Procedures
  ! ===================================================================
  public :: RT_ContExpl_Init
  public :: RT_ContExpl_Search
  public :: RT_ContExpl_CompForce
  public :: RT_ContExpl_CompEnergy
  public :: RT_ContExpl_GetStat
  public :: RT_ContExpl_Clean
  ! Phase 8 E1.2: Critical time step from contact stiffness
  public :: RT_ContExpl_CriticalTimeStep
  ! Phase 8 E2.1: Contact energy error monitoring
  public :: RT_ContExpl_GetEnergyStats
  ! Phase 8 E4.1: Search frequency control
  public :: RT_ContExpl_ShouldSearchThisStep
  public :: RT_ContExpl_AdvanceStepCount

  ! ===================================================================
  ! Constants
  ! ===================================================================
  real(wp), parameter :: DEFAULT_PENALTY = 1.0e6_wp
  real(wp), parameter :: MIN_PENETRATION = 1.0e-12_wp
  real(wp), parameter :: DEFAULT_SEARCH = 1.0e-6_wp

  ! ===================================================================
  ! Contact Pair Information
  ! ===================================================================
  type, public :: RT_Cont_Pair
    integer(i4) :: master_surface = 0_i4
    integer(i4) :: slave_surface_i = 0_i4
    integer(i4) :: n_contacts = 0_i4
    integer(i4), allocatable :: contact_node_id(:)  ! Slave node IDs in contact
    real(wp), allocatable :: penetrations(:)          ! Penetration depths
    real(wp), allocatable :: contact_normals(:,:)     ! Contact normals (n_contacts, 3)
    logical :: is_active = .false.
  end type RT_Cont_Pair

  ! ===================================================================
  ! Explicit Contact Configuration
  ! ===================================================================
  type, public :: RT_Cont_Expl_Cfg
    ! Contact search
    logical :: search_every_st = .true.   ! Search every time step
    real(wp) :: search_toleranc = 1.0e-6_wp ! Search tolerance
    
    ! Contact force
    real(wp) :: penalty_stiffne = 1.0e6_wp ! Penalty stiffness
    logical :: use_adaptive_pe = .false. ! Adaptive penalty
    real(wp) :: min_penalty = 1.0e4_wp      ! Minimum penalty
    real(wp) :: max_penalty = 1.0e8_wp      ! Maximum penalty
    
    ! Contact stabilization (Phase 8 E3.1: normal/tangential damping)
    logical :: use_damping = .false.        ! Use contact damping
    real(wp) :: damping_coeffic = 0.1_wp   ! Default (legacy) damping
    real(wp) :: damping_normal = 0.1_wp      ! E3.1: Normal direction damping
    real(wp) :: damping_tangent = 0.0_wp ! E3.1: Tangential damping (optional)
    ! E3.2: Superposition: .true. = add to Mat damping; .false. = replace in contact zone
    logical :: damping_add_to = .true.
    ! Phase 8 E4.1: Search frequency (search every search_interval steps; 1 = every step)
    integer(i4) :: search_interval = 1_i4
    
    ! Statistics
    logical :: track_statistic = .true.    ! Track contact statistics
  end type RT_Cont_Expl_Cfg

  ! ===================================================================
  ! Explicit Contact State
  ! ===================================================================
  type, public :: RT_Cont_Expl_State
    ! Contact pairs
    integer(i4) :: nContPairs = 0_i4
    type(RT_Cont_Pair), allocatable :: contact_pairs(:)
    
    ! Contact forces
    real(wp), allocatable :: F_contact(:)  ! Contact forces (n_dofs)
    
    ! Contact energy (Phase 8 E2.1: energy monitoring)
    real(wp) :: E_contact = 0.0_wp         ! Contact energy
    real(wp) :: work_contact = 0.0_wp      ! Work done by contact forces (integral F·v dt)
    
    ! Statistics
    integer(i4) :: n_total_contact = 0_i4 ! Total contact points
    integer(i4) :: n_search_calls = 0_i4   ! Number of search calls
    real(wp) :: max_penetration = 0.0_wp   ! Maximum penetration
    ! Phase 8 E4: step counter for search interval
    integer(i4) :: step_count = 0_i4
    
    LOGICAL :: init = .false.
  end type RT_Cont_Expl_State

  ! ===================================================================
  ! Explicit Contact Solver (Main Type)
  ! ===================================================================
  type, public :: RT_Cont_Expl_Solv
    type(RT_Cont_Expl_Cfg) :: config
    type(RT_Cont_Expl_State) :: state
    
    integer(i4) :: n_dofs = 0_i4            ! Number of DOFs
    
    LOGICAL :: init = .false.
  contains
    procedure :: Init
    procedure :: Search
    procedure :: ComputeForce
    procedure :: ComputeEnergy
    procedure :: GetStatistics
    procedure :: Cleanup
  end type RT_Cont_Expl_Solv

  ! Type alias for backward compatibility (RT_Step_Expl)
  type, public, extends(RT_Cont_Expl_Solv) :: RT_ExplicitContactSolver
  end type RT_ExplicitContactSolver

contains

  ! ===================================================================
  ! RT_ContExpl_Solv Procedures
  ! ===================================================================
  
  subroutine RT_ContExpl_Solv_Init(this, n_dofs, config, status)
    !! Init explicit contact solver
    class(RT_Cont_Expl_Solv), intent(inout) :: this
    integer(i4), intent(in) :: n_dofs
    type(RT_Cont_Expl_Cfg), intent(in), optional :: config
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    if (n_dofs <= 0) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_ContExpl_Solv_Init: n_dofs must be > 0'
      end if
      return
    end if
    
    ! Copy configuration
    if (present(config)) then
      this%config = config
    end if
    
    ! Init state
    this%state%nContPairs = 0_i4
    this%state%n_total_contact = 0_i4
    this%state%n_search_calls = 0_i4
    this%state%E_contact = 0.0_wp
    this%state%max_penetration = 0.0_wp
    
    ! Allocate contact force array
    allocate(this%state%F_contact(n_dofs))
    this%state%F_contact = 0.0_wp
    
    this%n_dofs = n_dofs
    this%state%init = .true.
    this%init = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_ContExpl_Solv_Init

  subroutine RT_ContExpl_Solv_Search(this, coords, surfaces, status)
    !! Perform contact search
    !!
    !! Input:
    !!   coords: Node coordinates (n_nodes, 3)
    !!   surfaces: Surface definitions
    !!
    !! Note: This is a simplified implementation
    !! In practice, we need efficient spatial search (BVH, bucket search)
    !!
    class(RT_Cont_Expl_Solv), intent(inout) :: this
    real(wp), intent(in) :: coords(:,:)  ! (n_nodes, 3)
    integer(i4), intent(in), optional :: surfaces(:,:)  ! Surface definitions
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j, k, n_pairs
    integer(i4) :: slave_node_id, master_node_id
    integer(i4) :: n_nodes, n_slave_nodes, n_master_nodes
    real(wp) :: dist, dist_min, penetration, dist_sq
    real(wp) :: slave_pos(3), master_pos(3), normal(3), normal_norm
    real(wp) :: search_tol_sq
    integer(i4), allocatable :: contact_list(:)
    real(wp), allocatable :: penetration_lis(:)
    real(wp), allocatable :: normal_list(:,:)
    
    if (present(status)) call init_error_status(status)
    
    if (.not. this%init) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_ContExpl_Solv_Search: Not initialized'
      end if
      return
    end if
    
    ! Increment search counter
    this%state%n_search_calls = this%state%n_search_calls + 1_i4
    
    ! Implement contact search algorithm
    ! Strategy: Node-to-surface distance-based search for explicit dynamics
    ! For each contact pair, find slave nodes that penetrate master surface
    
    if (allocated(this%state%contact_pairs)) then
      n_pairs = this%state%nContPairs
      n_nodes = size(coords, 1)
      search_tol_sq = this%config%search_toleranc**2
      
      do i = 1, n_pairs
        ! Reset contact pair
        this%state%contact_pairs(i)%n_contacts = 0_i4
        this%state%contact_pairs(i)%is_active = .false.
        
        ! Allocate temporary contact lists
        if (allocated(contact_list)) deallocate(contact_list)
        if (allocated(penetration_lis)) deallocate(penetration_lis)
        if (allocated(normal_list)) deallocate(normal_list)
        allocate(contact_list(n_nodes), penetration_lis(n_nodes), normal_list(n_nodes, 3))
        
        ! Simplified contact search: node-to-node distance check
        ! In a full implementation, we would:
        ! 1. Get slave and master surface node lists from surface definitions
        ! 2. Build spatial search structure (BVH, bucket grid)
        ! 3. For each slave node, find nearest master surface segment
        ! 4. Compute penetration and contact normal
        
        ! For now, use a simplified approach:
        ! Check distance between all node pairs (O(n^2) - inefficient but functional)
        ! This should be replaced with spatial search structure for production use
        
        k = 0
        do slave_node_id = 1, n_nodes
          slave_pos = coords(slave_node_id, :)
          dist_min = huge(1.0_wp)
          master_node_id = 0_i4
          
          ! Find nearest master node (simplified: check all nodes)
          ! In production, use spatial search structure
          do master_node_id = 1, n_nodes
            if (master_node_id == slave_node_id) cycle
            
            master_pos = coords(master_node_id, :)
            dist_sq = sum((slave_pos - master_pos)**2)
            
            if (dist_sq < dist_min) then
              dist_min = dist_sq
              master_node_id = master_node_id
            end if
          end do
          
          ! Check if penetration detected
          dist = sqrt(dist_min)
          if (dist < this%config%search_toleranc) then
            ! Compute penetration (simplified: use distance as penetration)
            penetration = this%config%search_toleranc - dist
            
            if (penetration > MIN_PENETRATION) then
              ! Compute contact normal (from slave to master)
              normal = master_pos - slave_pos
              normal_norm = sqrt(sum(normal**2))
              
              if (normal_norm > 1.0e-12_wp) then
                normal = normal / normal_norm
              else
                normal = [1.0_wp, 0.0_wp, 0.0_wp]  ! Default normal
              end if
              
              ! Store contact information
              k = k + 1
              contact_list(k) = slave_node_id
              penetration_lis(k) = penetration
              normal_list(k, :) = normal
            end if
          end if
        end do
        
        ! Store contacts in contact pair
        if (k > 0) then
          this%state%contact_pairs(i)%n_contacts = k
          this%state%contact_pairs(i)%is_active = .true.
          
          if (allocated(this%state%contact_pairs(i)%contact_node_id)) then
            deallocate(this%state%contact_pairs(i)%contact_node_id)
          end if
          if (allocated(this%state%contact_pairs(i)%penetrations)) then
            deallocate(this%state%contact_pairs(i)%penetrations)
          end if
          if (allocated(this%state%contact_pairs(i)%contact_normals)) then
            deallocate(this%state%contact_pairs(i)%contact_normals)
          end if
          
          allocate(this%state%contact_pairs(i)%contact_node_id(k))
          allocate(this%state%contact_pairs(i)%penetrations(k))
          allocate(this%state%contact_pairs(i)%contact_normals(k, 3))
          
          this%state%contact_pairs(i)%contact_node_id(1:k) = contact_list(1:k)
          this%state%contact_pairs(i)%penetrations(1:k) = penetration_lis(1:k)
          this%state%contact_pairs(i)%contact_normals(1:k, :) = normal_list(1:k, :)
          
          ! Update statistics
          this%state%n_total_contact = this%state%n_total_contact + k
          this%state%max_penetration = max(this%state%max_penetration, maxval(penetration_lis(1:k)))
        end if
        
        ! Cleanup temporary arrays
        if (allocated(contact_list)) deallocate(contact_list)
        if (allocated(penetration_lis)) deallocate(penetration_lis)
        if (allocated(normal_list)) deallocate(normal_list)
      end do
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_ContExpl_Solv_Search

  subroutine RT_ContExpl_Solv_ComputeForce(this, coords, u, v, F_contact, status, dt)
    !! Compute contact forces (Phase 8 E1.1)
    !! Delegates to L4_PH: PH_ContExpl_ComputeForce
    class(RT_Cont_Expl_Solv), intent(inout) :: this
    real(wp), intent(in) :: coords(:,:)  ! (n_nodes, 3)
    real(wp), intent(in) :: u(:)         ! (n_dofs)
    real(wp), intent(in) :: v(:)         ! (n_dofs)
    real(wp), intent(out) :: F_contact(:) ! (n_dofs)
    type(ErrorStatusType), intent(out), optional :: status
    real(wp), intent(in), optional :: dt   ! E2.1: if present, accumulate work_contact += F·v*dt
    
    integer(i4) :: i, j, n_contacts, node_id, dof_idx
    integer(i4), allocatable :: node_ids(:)
    real(wp), allocatable :: penetrations(:), normals(:,:)
    real(wp) :: k_penalty, work_done
    
    if (present(status)) call init_error_status(status)
    
    if (.not. this%init) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_ContExpl_Solv_ComputeForce: Not initialized'
      end if
      return
    end if
    
    if (size(F_contact) /= this%n_dofs) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_ContExpl_Solv_ComputeForce: Size mismatch'
      end if
      return
    end if
    
    ! Init state
    F_contact = 0.0_wp
    this%state%E_contact = 0.0_wp
    this%state%work_contact = 0.0_wp
    this%state%max_penetration = 0.0_wp
    this%state%n_total_contact = 0_i4
    work_done = 0.0_wp
    
    ! Get penalty stiffness
    k_penalty = this%config%penalty_stiffne
    
    ! Process each contact pair and delegate to L4_PH
    if (allocated(this%state%contact_pairs)) then
      do i = 1, this%state%nContPairs
        if (.not. this%state%contact_pairs(i)%is_active) cycle
        
        n_contacts = this%state%contact_pairs(i)%n_contacts
        if (n_contacts == 0) cycle
        
        ! Extract contact data for this pair
        allocate(node_ids(n_contacts))
        allocate(penetrations(n_contacts))
        allocate(normals(n_contacts, 3))
        
        node_ids = this%state%contact_pairs(i)%contact_node_id(1:n_contacts)
        penetrations = this%state%contact_pairs(i)%penetrations(1:n_contacts)
        normals = this%state%contact_pairs(i)%contact_normals(1:n_contacts, :)
        
        ! Delegate to L4_PH pure physics computation
        CALL PH_ContExpl_ComputeForce( &
             penalty_stiffness = k_penalty, &
             n_contacts = n_contacts, &
             node_ids = node_ids, &
             penetrations = penetrations, &
             normals = normals, &
             coords = coords, &
             velocities = v, &
             F_contact = F_contact, &
             n_dofs = this%n_dofs, &
             use_damping = this%config%use_damping, &
             damping_normal = this%config%damping_normal, &
             damping_tangent = this%config%damping_tangent, &
             dt = dt, &
             work_done = work_done, &
             status = status)
        
        ! Accumulate energy and statistics
        CALL PH_ContExpl_ComputeEnergy( &
             penalty_stiffness = k_penalty, &
             n_contacts = n_contacts, &
             penetrations = penetrations, &
             E_contact = this%state%E_contact, &
             status = status)
        
        ! Update statistics
        this%state%max_penetration = max(this%state%max_penetration, maxval(penetrations))
        this%state%n_total_contact = this%state%n_total_contact + n_contacts
        
        ! Accumulate work
        if (present(dt) .AND. dt > 0.0_wp) then
          this%state%work_contact = this%state%work_contact + work_done
        end if
        
        deallocate(node_ids, penetrations, normals)
      end do
    end if
    
    ! Store contact forces
    this%state%F_contact = F_contact
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_ContExpl_Solv_ComputeForce

  subroutine RT_ContExpl_Solv_CompEnergy(this, E_contact, status)
    !! Get contact energy
    class(RT_Cont_Expl_Solv), intent(in) :: this
    real(wp), intent(out) :: E_contact
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    if (.not. this%init) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_ContExpl_Solv_ComputeEnergy: Not initialized'
      end if
      E_contact = 0.0_wp
      return
    end if
    
    E_contact = this%state%E_contact
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_ContExpl_Solv_CompEnergy

  subroutine RT_ContExpl_Solv_GetStats(this, n_contacts, max_penetration, n_searches)
    !! Get contact statistics
    class(RT_Cont_Expl_Solv), intent(in) :: this
    integer(i4), intent(out), optional :: n_contacts
    real(wp), intent(out), optional :: max_penetration
    integer(i4), intent(out), optional :: n_searches
    
    if (present(n_contacts)) n_contacts = this%state%n_total_contact
    if (present(max_penetration)) max_penetration = this%state%max_penetration
    if (present(n_searches)) n_searches = this%state%n_search_calls
    
  end subroutine RT_ContExpl_Solv_GetStats

  ! ===================================================================
  ! Phase 8 E1.2: Critical time step from contact stiffness
  ! ===================================================================
  subroutine RT_ContExpl_CriticalTimeStep(penalty_stiffness, mass_min, dt_crit, status)
    !! E1.2: Delegates to L4_PH for CFL calculation
    real(wp), intent(in) :: penalty_stiffness
    real(wp), intent(in) :: mass_min   ! Minimum nodal mass in contact zone
    real(wp), intent(out) :: dt_crit
    type(ErrorStatusType), intent(out), optional :: status
    
    ! Delegate to L4_PH pure physics computation
    CALL PH_ContExpl_CriticalTimeStep( &
         penalty_stiffness = penalty_stiffness, &
         mass_min = mass_min, &
         dt_crit = dt_crit, &
         status = status)
  end subroutine RT_ContExpl_CriticalTimeStep

  ! ===================================================================
  ! Phase 8 E2.1: Contact energy statistics for monitoring
  ! ===================================================================
  subroutine RT_ContExpl_GetEnergyStats(this, E_contact, work_contact, energy_error, status)
    !! E2.1: Return E_contact, work_contact; delegates to L4_PH for energy error computation
    class(RT_Cont_Expl_Solv), intent(in) :: this
    real(wp), intent(out), optional :: E_contact
    real(wp), intent(out), optional :: work_contact
    real(wp), intent(out), optional :: energy_error
    type(ErrorStatusType), intent(out), optional :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(E_contact)) E_contact = this%state%E_contact
    IF (PRESENT(work_contact)) work_contact = this%state%work_contact
    
    ! Delegate to L4_PH for energy error computation
    IF (PRESENT(energy_error)) THEN
      CALL PH_ContExpl_GetEnergyStats( &
           E_contact = this%state%E_contact, &
           work_contact = this%state%work_contact, &
           energy_error = energy_error, &
           status = status)
    END IF
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_ContExpl_GetEnergyStats

  ! ===================================================================
  ! Phase 8 E4.1: Should search this step? (search_interval)
  ! ===================================================================
  subroutine RT_ContExpl_ShouldSearchThisStep(this, do_search, status)
    !! E4.1: do_search = .true. when step_count mod search_interval == 0. Caller should increment step_count after step.
    class(RT_Cont_Expl_Solv), intent(inout) :: this
    logical, intent(out) :: do_search
    type(ErrorStatusType), intent(out), optional :: status
    integer(i4) :: interval
    if (present(status)) call init_error_status(status)
    interval = max(1_i4, this%config%search_interval)
    do_search = (mod(this%state%step_count, interval) == 0_i4)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_ContExpl_ShouldSearchThisStep

  subroutine RT_ContExpl_AdvanceStepCount(this)
    !! Increment step counter (call after each time step for E4.1).
    class(RT_Cont_Expl_Solv), intent(inout) :: this
    this%state%step_count = this%state%step_count + 1_i4
  end subroutine RT_ContExpl_AdvanceStepCount

  subroutine RT_ContExpl_Solv_Cleanup(this)
    class(RT_Cont_Expl_Solv), intent(inout) :: this
    
    integer(i4) :: i
    
    ! Cleanup contact pairs
    if (allocated(this%state%contact_pairs)) then
      do i = 1, this%state%nContPairs
        if (allocated(this%state%contact_pairs(i)%contact_node_id)) then
          deallocate(this%state%contact_pairs(i)%contact_node_id)
        end if
        if (allocated(this%state%contact_pairs(i)%penetrations)) then
          deallocate(this%state%contact_pairs(i)%penetrations)
        end if
        if (allocated(this%state%contact_pairs(i)%contact_normals)) then
          deallocate(this%state%contact_pairs(i)%contact_normals)
        end if
      end do
      deallocate(this%state%contact_pairs)
    end if
    
    ! Cleanup contact forces
    if (allocated(this%state%F_contact)) then
      deallocate(this%state%F_contact)
    end if
    
    this%state%init = .false.
    this%init = .false.
    this%n_dofs = 0_i4
    
  end subroutine RT_ContExpl_Solv_Cleanup

  ! ===================================================================
  ! Standalone Procedures (for backward compatibility)
  ! ===================================================================
  
  subroutine RT_ContExpl_Init(solver, n_dofs, config, status)
    type(RT_Cont_Expl_Solv), intent(inout) :: solver
    integer(i4), intent(in) :: n_dofs
    type(RT_Cont_Expl_Cfg), intent(in), optional :: config
    type(ErrorStatusType), intent(out), optional :: status
    
    call solver%Init(n_dofs, config, status)
    
  end subroutine RT_ContExpl_Init

  subroutine RT_ContExpl_Search(solver, coords, surfaces, status)
    type(RT_Cont_Expl_Solv), intent(inout) :: solver
    real(wp), intent(in) :: coords(:,:)
    integer(i4), intent(in), optional :: surfaces(:,:)
    type(ErrorStatusType), intent(out), optional :: status
    
    call solver%Search(coords, surfaces, status)
    
  end subroutine RT_ContExpl_Search

  subroutine RT_ContExpl_CompForce(solver, coords, u, v, F_contact, status, dt)
    type(RT_Cont_Expl_Solv), intent(inout) :: solver
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: u(:)
    real(wp), intent(in) :: v(:)
    real(wp), intent(out) :: F_contact(:)
    type(ErrorStatusType), intent(out), optional :: status
    real(wp), intent(in), optional :: dt   ! E2.1: if present, accumulate work_contact
    
    call solver%ComputeForce(coords, u, v, F_contact, status, dt)
    
  end subroutine RT_ContExpl_CompForce

  subroutine RT_ContExpl_CompEnergy(solver, E_contact, status)
    type(RT_Cont_Expl_Solv), intent(in) :: solver
    real(wp), intent(out) :: E_contact
    type(ErrorStatusType), intent(out), optional :: status
    
    call solver%ComputeEnergy(E_contact, status)
    
  end subroutine RT_ContExpl_CompEnergy

  subroutine RT_ContExpl_GetStat(solver, n_contacts, max_penetration, n_searches)
    type(RT_Cont_Expl_Solv), intent(in) :: solver
    integer(i4), intent(out), optional :: n_contacts
    real(wp), intent(out), optional :: max_penetration
    integer(i4), intent(out), optional :: n_searches
    
    call solver%GetStatistics(n_contacts, max_penetration, n_searches)
    
  end subroutine RT_ContExpl_GetStat

  subroutine RT_ContExpl_Clean(solver)
    type(RT_Cont_Expl_Solv), intent(inout) :: solver
    
    call solver%Cleanup()
    
  end subroutine RT_ContExpl_Clean

end module RT_Cont_Expl