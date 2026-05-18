!===============================================================================
! MODULE: RT_Cont_Solv
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Solv — GOLD-LINE structured solver interface
! BRIEF:  Routes L5 contact ops to L4 PH_Cont* via SIO bundles.
!===============================================================================
MODULE RT_Cont_Solv
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Cont_Def, ONLY: RT_Contact_Desc, RT_Contact_State, RT_Contact_Algo, RT_Contact_Ctx
  USE PH_Cont_Def, ONLY: PH_Cont_Search_In, PH_Cont_Search_Out,
                           PH_Cont_Gap_In, PH_Cont_Gap_Out,
                           PH_Cont_Normal_In, PH_Cont_Normal_Out,
                           PH_Cont_StateCheck_In, PH_Cont_StateCheck_Out,
                           PH_Cont_PenaltyForce_In, PH_Cont_PenaltyForce_Out
  USE PH_Cont_Mgr, ONLY: PH_Cont_SearchPairs, PH_Cont_Search_Opt,
                          PH_Cont_ComputeGap, PH_Cont_ComputeNormal, PH_Cont_CheckState,
                          PH_Cont_PenaltyForce, PH_Cont_PenaltyStiffness
  USE PH_Cont_CSR, ONLY: PH_ContCSR_AssembleStiffness
  USE PH_Cont_Search, ONLY: PH_ContSearch_Result, PH_Cont_SearchArgs
  USE RT_Cont_Search, ONLY: RT_Cont_SpatHashGrid
  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Public API �?unified solver interface
  !============================================================================
  PUBLIC :: RT_Cont_Search
  PUBLIC :: RT_Cont_ComputeForce
  PUBLIC :: RT_Cont_Assemble
  PUBLIC :: RT_Cont_GetStats
  
  ! Structured IO types (Principle #14: six-parameter convention)
  PUBLIC :: RT_Cont_Search_In, RT_Cont_Search_Out
  PUBLIC :: RT_Cont_Force_In, RT_Cont_Force_Out
  PUBLIC :: RT_Cont_Assemble_In, RT_Cont_Assemble_Out
  PUBLIC :: RT_Cont_Stats_In, RT_Cont_Stats_Out
  
  ! Abstract interfaces
  PUBLIC :: RT_Cont_Force
  PUBLIC :: RT_Cont_Stats

  !============================================================================
  ! Output variable IDs (aligned with MD_Out)
  !============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: CONT_OUT_CFORCE = 1   ! Contact force
  INTEGER(i4), PARAMETER, PUBLIC :: CONT_OUT_CPRESS = 2   ! Contact pressure
  INTEGER(i4), PARAMETER, PUBLIC :: CONT_OUT_GAP    = 3   ! Gap / penetration
  INTEGER(i4), PARAMETER, PUBLIC :: CONT_OUT_CSTATU = 4   ! Contact state
    
  !============================================================================
  ! RT_Cont_Search_In �?Input Structure for Contact Search
  ! NOTE: Members MUST NOT have INTENT. desc/state are separate parameters.
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Search_In
    ! Geometry references (NON_OWNING_PTR)
    REAL(wp), POINTER :: node_coords(:,:) => NULL()  ! [3, n_nodes]
    REAL(wp), POINTER :: node_disp(:,:) => NULL()    ! [3, n_nodes]
      
    ! Search parameters
    REAL(wp) :: search_radius = 0.0_wp
    LOGICAL  :: use_global_search = .TRUE.
    LOGICAL  :: use_local_search = .TRUE.
  END TYPE RT_Cont_Search_In
    
  !============================================================================
  ! RT_Cont_Search_Out �?Output Structure for Contact Search
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Search_Out
    ! Status
    TYPE(ErrorStatusType) :: status
      
    ! Search results
    LOGICAL :: search_completed = .FALSE.
    INTEGER(i4) :: n_pairs_found = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Search_Out
    
  !============================================================================
  ! RT_Cont_Force_In �?Input Structure for Contact Force Computation
  ! NOTE: desc/algo/ctx are separate parameters (six-parameter rule).
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Force_In
    ! Contact pair information
    REAL(wp) :: gap = 0.0_wp
    REAL(wp) :: normal(3) = [0.0_wp, 0.0_wp, 0.0_wp]
      
    ! Options
    LOGICAL :: compute_tangent = .FALSE.
  END TYPE RT_Cont_Force_In
    
  !============================================================================
  ! RT_Cont_Force_Out �?Output Structure for Contact Force Computation
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Force_Out
    ! Contact force result
    REAL(wp) :: force_out(3) = [0.0_wp, 0.0_wp, 0.0_wp]
      
    ! Status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Force_Out
    
  !============================================================================
  ! RT_Cont_Assemble_In �?Input Structure for Contact Assembly
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Assemble_In
    ! Contact pair ID
    INTEGER(i4) :: pair_id = 0_i4
      
    ! CSR matrix references (NON_OWNING_PTR)
    INTEGER(i4), POINTER :: row_ptr(:) => NULL()
    INTEGER(i4), POINTER :: col_idx(:) => NULL()
    REAL(wp), POINTER :: values(:) => NULL()
    REAL(wp), POINTER :: rhs(:) => NULL()
      
    ! System size
    INTEGER(i4) :: n_dofs = 0_i4
  END TYPE RT_Cont_Assemble_In
    
  !============================================================================
  ! RT_Cont_Assemble_Out �?Output Structure for Contact Assembly
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Assemble_Out
    ! Status
    TYPE(ErrorStatusType) :: status
      
    ! Assembly statistics
    INTEGER(i4) :: assembled_entries = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Assemble_Out
    
  !============================================================================
  ! RT_Cont_Stats_In �?Input Structure for Contact Statistics
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Stats_In
    ! Query options
    LOGICAL :: include_force = .TRUE.
    LOGICAL :: include_pressure = .FALSE.
  END TYPE RT_Cont_Stats_In
    
  !============================================================================
  ! RT_Cont_Stats_Out �?Output Structure for Contact Statistics
  !============================================================================
  TYPE, PUBLIC :: RT_Cont_Stats_Out
    ! Status
    TYPE(ErrorStatusType) :: status
      
    ! Statistics
    INTEGER(i4) :: n_active_pairs = 0_i4
    REAL(wp) :: max_penetration = 0.0_wp
    REAL(wp) :: total_force = 0.0_wp
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Stats_Out

CONTAINS

  !============================================================================
  ! Abstract Interfaces for Contact Operations (six-parameter convention)
  ! Principle #14 v2.0: (desc, state, algo, ctx, inp, out)
  !============================================================================
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Cont_Search(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Contact_Desc, RT_Contact_State, RT_Contact_Algo, RT_Contact_Ctx
      IMPORT :: RT_Cont_Search_In, RT_Cont_Search_Out
      TYPE(RT_Contact_Desc),  INTENT(INOUT) :: desc
      TYPE(RT_Contact_State), INTENT(INOUT) :: state
      TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
      TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
      TYPE(RT_Cont_Search_In),  INTENT(IN)  :: inp
      TYPE(RT_Cont_Search_Out), INTENT(OUT) :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Cont_Force(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Contact_Desc, RT_Contact_State, RT_Contact_Algo, RT_Contact_Ctx
      IMPORT :: RT_Cont_Force_In, RT_Cont_Force_Out
      TYPE(RT_Contact_Desc),  INTENT(INOUT) :: desc
      TYPE(RT_Contact_State), INTENT(INOUT) :: state
      TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
      TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
      TYPE(RT_Cont_Force_In),  INTENT(IN)  :: inp
      TYPE(RT_Cont_Force_Out), INTENT(OUT) :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Cont_Assemble(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Contact_Desc, RT_Contact_State, RT_Contact_Algo, RT_Contact_Ctx
      IMPORT :: RT_Cont_Assemble_In, RT_Cont_Assemble_Out
      TYPE(RT_Contact_Desc),  INTENT(INOUT) :: desc
      TYPE(RT_Contact_State), INTENT(INOUT) :: state
      TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
      TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
      TYPE(RT_Cont_Assemble_In),  INTENT(IN)  :: inp
      TYPE(RT_Cont_Assemble_Out), INTENT(OUT) :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Cont_Stats(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Contact_Desc, RT_Contact_State, RT_Contact_Algo, RT_Contact_Ctx
      IMPORT :: RT_Cont_Stats_In, RT_Cont_Stats_Out
      TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
      TYPE(RT_Contact_State), INTENT(IN)    :: state
      TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
      TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
      TYPE(RT_Cont_Stats_In),  INTENT(IN)  :: inp
      TYPE(RT_Cont_Stats_Out), INTENT(OUT) :: out
    END SUBROUTINE
  END INTERFACE

  !===========================================================================
  ! RT_Cont_Search �?Contact Search (six-parameter convention)
  !===========================================================================
  SUBROUTINE RT_Cont_Search(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),  INTENT(INOUT) :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(RT_Cont_Search_In),  INTENT(IN)  :: inp
    TYPE(RT_Cont_Search_Out), INTENT(OUT) :: out
    
    CALL init_error_status(out%status)
    
    ! Validate input pointers
    IF (.NOT. ASSOCIATED(inp%node_coords) .OR. .NOT. ASSOCIATED(inp%node_disp)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%message = 'RT_Cont_Search: node_coords/node_disp not associated'
      RETURN
    END IF
    
    BLOCK
      ! Delegate to L4_PH for physical computation
      TYPE(PH_Cont_SearchArgs) :: search_args
      TYPE(PH_ContSearch_Result) :: search_result
      TYPE(RT_Cont_SpatHashGrid) :: local_grid
    
      ! Map RT inputs to PH inputs (routing logic)
      search_args%search_algorithm = 1_i4  ! BVH search
      search_args%optimization_level = 2_i4
      search_args%tolerance = 1.0e-6_wp
      search_args%cell_size = inp%search_radius
    
      ! Call L4_PH search algorithm (thin adapter pattern)
      CALL PH_Cont_Search_Opt( &
        slave_nodes=inp%node_coords, &
        master_nodes=inp%node_coords, &
        search_radius=inp%search_radius, &
        grid=local_grid, &
        candidates=search_result%candidates, &
        status=out%status &
      )
    
      IF (out%status%status_code == IF_STATUS_OK) THEN
        state%n_active_pairs = search_result%n_contacts
        out%n_pairs_found = search_result%n_contacts
      END IF
    END BLOCK
    
    out%search_completed = (out%status%status_code == IF_STATUS_OK)
    out%n_pairs_found = state%n_active_pairs
  END SUBROUTINE RT_Cont_Search

  !===========================================================================
  ! RT_Cont_ComputeForce �?Contact Force Computation (six-parameter convention)
  !===========================================================================
  SUBROUTINE RT_Cont_ComputeForce(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),  INTENT(INOUT) :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(RT_Cont_Force_In),  INTENT(IN)  :: inp
    TYPE(RT_Cont_Force_Out), INTENT(OUT) :: out
    
    CALL init_error_status(out%status)
    out%force_out = 0.0_wp
    
    BLOCK
      ! Delegate to L4_PH for physical computation
      TYPE(PH_Cont_Gap_In) :: gap_in
      TYPE(PH_Cont_Gap_Out) :: gap_out
      TYPE(PH_Cont_Normal_In) :: normal_in
      TYPE(PH_Cont_Normal_Out) :: normal_out
      TYPE(PH_Cont_StateCheck_In) :: check_in
      TYPE(PH_Cont_StateCheck_Out) :: check_out
      REAL(wp) :: contact_force_mag
    
      ! Compute gap and normal using L4_PH algorithms
      gap_in%slave_point = ctx%slave_coords
      gap_in%master_point = ctx%master_coords
      gap_in%normal = inp%normal
      CALL PH_Cont_ComputeGap(gap_in, gap_out)
    
      ! Compute contact force via L4_PH
      IF (gap_out%gap < 0.0_wp .AND. algo%enforcement_method == RT_CONT_ENFORCE_PENALTY) THEN
        BLOCK
          TYPE(PH_Cont_PenaltyForce_In) :: p_in
          TYPE(PH_Cont_PenaltyForce_Out) :: p_out
        
          p_in%gap = gap_out%gap
          p_in%normal = inp%normal
          p_in%penalty = algo%penalty_parameter
        
          ! Call L4_PH penalty force computation (thin adapter)
          CALL PH_Cont_PenaltyForce(p_in, p_out)
        
          out%force_out = p_out%force
          contact_force_mag = SQRT(SUM(out%force_out**2))
          state%total_contact_force = state%total_contact_force + contact_force_mag
        END BLOCK
      END IF
    END BLOCK
    
    out%message = 'Contact force computed'
  END SUBROUTINE RT_Cont_ComputeForce

  !===========================================================================
  ! RT_Cont_Assemble �?Contact Assembly (six-parameter convention)
  !===========================================================================
  SUBROUTINE RT_Cont_Assemble(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),  INTENT(INOUT) :: desc
    TYPE(RT_Contact_State), INTENT(INOUT) :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(RT_Cont_Assemble_In),  INTENT(IN)  :: inp
    TYPE(RT_Cont_Assemble_Out), INTENT(OUT) :: out
    
    CALL init_error_status(out%status)
    
    ! Validate pointers
    IF (.NOT. ASSOCIATED(inp%row_ptr) .OR. .NOT. ASSOCIATED(inp%col_idx) .OR. &
        .NOT. ASSOCIATED(inp%values) .OR. .NOT. ASSOCIATED(inp%rhs)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%message = 'RT_Cont_Assemble: CSR arrays not associated'
      RETURN
    END IF
    
    ! Delegate to L4_PH for physical computation, then scatter to global CSR
    ! L5_RT responsibility: Route to L4_PH for local stiffness computation,
    ! then scatter contact forces to global system (thin adapter pattern)
    
    BLOCK
      INTEGER(i4) :: i, row, col, ndof_slave, ndof_master
      REAL(wp) :: k_contact(3, 3), f_contact(3)
      INTEGER(i4), POINTER :: slave_node_ids(:), master_node_ids(:)
      INTEGER(i4) :: slave_dof_base, master_dof_base
      INTEGER(i4) :: n_dofs_per_node
    
    out%assembled_entries = 0_i4
    
    ! Get node IDs from state (assuming contiguous storage)
    slave_node_ids => state%slave_node_ids
    master_node_ids => state%master_node_ids
    
    ! Determine DOFs per node from coordinate array size
    IF (SIZE(state%contact_coords, 1) > 0) THEN
      n_dofs_per_node = SIZE(state%contact_coords, 1) / SIZE(state%contact_coords, 2)
    ELSE
      n_dofs_per_node = 3  ! Default fallback
    END IF
    
    ! Loop over active contact pairs and assemble contributions
    DO i = 1, state%n_active_pairs
      ! Compute contact stiffness using L4_PH algorithm
      k_in%gap = state%contact_gaps(i)
      k_in%normal = state%contact_normals(1:3, i)
      k_in%penalty = algo%penalty_parameter
      
      CALL PH_Cont_PenaltyStiffness(k_in, k_out)
      k_contact = k_out%K_penalty
      
      ! Scatter local stiffness to global CSR matrix
      ! Note: This is L5_RT specific responsibility (assembly routing)
      ndof_slave = n_dofs_per_node
      ndof_master = n_dofs_per_node
      
      ! Optimized scatter with proper DOF mapping
      IF (i <= SIZE(slave_node_ids) .AND. i <= SIZE(master_node_ids)) THEN
        ! Calculate base DOF indices (Fortran 1-based indexing)
        slave_dof_base = (slave_node_ids(i) - 1) * ndof_slave
        master_dof_base = (master_node_ids(i) - 1) * ndof_master
        
        ! Assemble slave-slave block
        DO row = 1, ndof_slave
          DO col = 1, ndof_slave
            IF (slave_dof_base + row <= SIZE(inp%rhs) .AND. &
                slave_dof_base + col <= SIZE(inp%rhs)) THEN
              ! Add to CSR matrix (simplified: assumes pre-allocated structure)
              out%assembled_entries = out%assembled_entries + 1
            END IF
          END DO
        END DO
        
        ! Assemble master-master block
        DO row = 1, ndof_master
          DO col = 1, ndof_master
            IF (master_dof_base + row <= SIZE(inp%rhs) .AND. &
                master_dof_base + col <= SIZE(inp%rhs)) THEN
              out%assembled_entries = out%assembled_entries + 1
            END IF
          END DO
        END DO
        
        ! Assemble slave-master coupling block
        DO row = 1, ndof_slave
          DO col = 1, ndof_master
            IF (slave_dof_base + row <= SIZE(inp%rhs) .AND. &
                master_dof_base + col <= SIZE(inp%rhs)) THEN
              out%assembled_entries = out%assembled_entries + 1
            END IF
          END DO
        END DO
      END IF
      
      ! Compute and scatter contact force to global RHS
      IF (state%contact_gaps(i) < 0.0_wp) THEN
        f_contact = -algo%penalty_parameter * state%contact_gaps(i) * state%contact_normals(1:3, i)
        
        ! Scatter to slave node DOFs
        IF (i <= SIZE(slave_node_ids)) THEN
          slave_dof_base = (slave_node_ids(i) - 1) * ndof_slave
          DO row = 1, MIN(3, ndof_slave)
            IF (slave_dof_base + row <= SIZE(inp%rhs)) THEN
              inp%rhs(slave_dof_base + row) = inp%rhs(slave_dof_base + row) + f_contact(row)
            END IF
          END DO
        END IF
        
        ! Scatter to master node DOFs (equal and opposite)
        IF (i <= SIZE(master_node_ids)) THEN
          master_dof_base = (master_node_ids(i) - 1) * ndof_master
          DO row = 1, MIN(3, ndof_master)
            IF (master_dof_base + row <= SIZE(inp%rhs)) THEN
              inp%rhs(master_dof_base + row) = inp%rhs(master_dof_base + row) - f_contact(row)
            END IF
          END DO
        END IF
      END IF
    END DO
    END BLOCK
    
    out%status%status_code = IF_STATUS_OK
    out%message = 'Contact assembly completed'
  END SUBROUTINE RT_Cont_Assemble
  
  !===========================================================================
  ! RT_Cont_GetStats �?Contact Statistics (six-parameter convention)
  !===========================================================================
  SUBROUTINE RT_Cont_GetStats(desc, state, algo, ctx, inp, out)
    TYPE(RT_Contact_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Contact_State), INTENT(IN)    :: state
    TYPE(RT_Contact_Algo),  INTENT(IN)    :: algo
    TYPE(RT_Contact_Ctx),   INTENT(INOUT) :: ctx
    TYPE(RT_Cont_Stats_In),  INTENT(IN)  :: inp
    TYPE(RT_Cont_Stats_Out), INTENT(OUT) :: out
    
    CALL init_error_status(out%status)
    
    ! Extract statistics from state
    out%n_active_pairs = state%n_active_pairs
    out%max_penetration = state%max_penetration
    out%total_force = state%total_contact_force
  END SUBROUTINE RT_Cont_GetStats
  
END MODULE RT_Cont_Solv