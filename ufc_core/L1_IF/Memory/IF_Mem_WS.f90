!===============================================================================
! MODULE: IF_Mem_WS
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — workspace and solver buffer management
! BRIEF:  Create/destroy workspace; solver persistent buffers (linear/NL);
!         reuse; statistics. Legacy UF_WS_* aliases.
!===============================================================================

MODULE IF_Mem_WS
!> [CORE]
!> Theory: Workspace management, memory reuse mechanism, L4/L5 layer decoupling interface, solver workspace
!> Status: 100% (Merged element workspace interface, solver workspace, solver buffer) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_MEM_ERROR
    USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, IF_MEM_DOMAIN_SOLV
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: IF_WS_Create
    PUBLIC :: IF_WS_Destroy
    PUBLIC :: IF_WS_Get
    PUBLIC :: IF_WS_Resize
    PUBLIC :: IF_WS_Clear
    PUBLIC :: IF_WS_Save
    PUBLIC :: IF_WS_Load
    PUBLIC :: IF_WS_GetState
    PUBLIC :: IF_WS_SetState
    
    ! Extended workspace management API (task350-399)
    PUBLIC :: IF_WS_Reuse, IF_WS_EstimateSize, IF_WS_GetStatistics
    PUBLIC :: IF_WS_Compact, IF_WS_GetReuseCount
    
    ! Solver workspace API (merged from IF_Workspace_Solver)
    PUBLIC :: IF_WS_Alloc_SolverVec, IF_WS_Free_SolverVec
    
    ! Solver persistent buffers (canonical IF_WS_*; legacy UF_WS_*)
    PUBLIC :: IF_WS_Get_NL_DeltaWorkspace, IF_WS_Get_Linear_Workspace, IF_WS_Finalize
    PUBLIC :: UF_WS_Get_NL_DeltaWorkspace, UF_WS_Get_Lin_Workspace, UF_WS_Get_Linear_Workspace, UF_WS_Finalize
    
    ! ==========================================================================
    ! WORKSPACE TYPE
    ! ==========================================================================
    TYPE, PUBLIC :: Workspace
        INTEGER(i4) :: id = 0_i4                    ! Workspace ID
        CHARACTER(len=64) :: name = ""              ! Workspace name
        INTEGER(i8) :: size = 0_i8                  ! Workspace size in bytes
        REAL(wp), POINTER :: data(:) => NULL()      ! Workspace data
        LOGICAL :: init = .FALSE.                   ! Initialization flag
        INTEGER(i8) :: timestamp = 0_i8             ! Creation timestamp
        INTEGER(i4) :: ref_count = 0_i4             ! Reference count
        INTEGER(i4) :: reuse_count = 0_i4           ! Reuse count (task350-399)
        LOGICAL :: is_reusable = .TRUE.             ! Can be reused
    END TYPE Workspace
    
    ! ==========================================================================
    ! WORKSPACE STATE TYPE
    ! ==========================================================================
    TYPE, PUBLIC :: WorkspaceState
        INTEGER(i4) :: id = 0_i4
        INTEGER(i8) :: size = 0_i8
        INTEGER(i8) :: timestamp = 0_i8
        LOGICAL :: is_active = .FALSE.
        LOGICAL :: is_persistent = .FALSE.
    END TYPE WorkspaceState
    
    ! ==========================================================================
    ! WORKSPACE MANAGER TYPE
    ! ==========================================================================
    TYPE, PUBLIC :: WorkspaceManager
        TYPE(Workspace), ALLOCATABLE :: workspaces(:)
        INTEGER(i4) :: num_workspaces = 0_i4
        INTEGER(i4) :: max_workspaces = 100_i4
        INTEGER(i4) :: next_id = 1_i4
        LOGICAL :: init = .FALSE.
    END TYPE WorkspaceManager
    
    ! ==========================================================================
    ! GLOBAL WORKSPACE MANAGER
    ! ==========================================================================
    TYPE(WorkspaceManager), SAVE :: g_ws_manager
    
    ! ==========================================================================
    ! SOLVER PERSISTENT BUFFERS (merged from UF_WorkspaceManager)
    ! ==========================================================================
    ! Persistent workspace for nonlinear/linear solver (reused across calls)
    ! TARGET required for pointer assignment (delta_ws => g_delta_ws(1:ndof))
    REAL(wp), ALLOCATABLE, TARGET, SAVE :: g_delta_ws(:)
    REAL(wp), ALLOCATABLE, TARGET, SAVE :: g_lin_work(:)
    INTEGER(i4), ALLOCATABLE, TARGET, SAVE :: g_lin_ipiv(:)
    
    ! ==========================================================================
    ! ELEMENT WORKSPACE INTERFACE (merged from RT_Elem_WS_Intf) - specification part
    ! ==========================================================================
    ABSTRACT INTERFACE
        SUBROUTINE StructWS_Proc(nDOF, Ke, Re, Me, Ce, B)
            IMPORT :: i4, wp
            INTEGER(i4), INTENT(IN) :: nDOF
            REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
            REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)
            REAL(wp), POINTER, INTENT(OUT) :: B(:,:)
        END SUBROUTINE StructWS_Proc
        SUBROUTINE MultiFieldWS_Proc(nDOF, Ke, Re, Me, Ce)
            IMPORT :: i4, wp
            INTEGER(i4), INTENT(IN) :: nDOF
            REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
            REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)
        END SUBROUTINE MultiFieldWS_Proc
        SUBROUTINE StructBmWS_Proc(nDOF, mB)
            IMPORT :: i4, wp
            INTEGER(i4), INTENT(IN) :: nDOF
            REAL(wp), POINTER, INTENT(OUT) :: mB(:)
        END SUBROUTINE StructBmWS_Proc
        SUBROUTINE StructBmWS_Proc_2(nDOF, B, mB)
            IMPORT :: i4, wp
            INTEGER(i4), INTENT(IN) :: nDOF
            REAL(wp), POINTER, INTENT(OUT) :: B(:,:)
            REAL(wp), POINTER, INTENT(OUT) :: mB(:)
        END SUBROUTINE StructBmWS_Proc_2
        SUBROUTINE PoroCapacityWS_Proc(nDOF, Spp)
            IMPORT :: i4, wp
            INTEGER(i4), INTENT(IN) :: nDOF
            REAL(wp), POINTER, INTENT(OUT) :: Spp(:,:)
        END SUBROUTINE PoroCapacityWS_Proc
        SUBROUTINE ThermalCapacityWS_Proc(nDOF, Ctt)
            IMPORT :: i4, wp
            INTEGER(i4), INTENT(IN) :: nDOF
            REAL(wp), POINTER, INTENT(OUT) :: Ctt(:,:)
        END SUBROUTINE ThermalCapacityWS_Proc
    END INTERFACE
    PROCEDURE(StructWS_Proc), POINTER, SAVE :: g_struct_ws_proc => NULL()
    PROCEDURE(MultiFieldWS_Proc), POINTER, SAVE :: g_multifield_ws_proc => NULL()
    PROCEDURE(StructBmWS_Proc), POINTER, SAVE :: g_struct_bm_proc => NULL()
    PROCEDURE(StructBmWS_Proc_2), POINTER, SAVE :: g_struct_bm_proc_2 => NULL()
    PROCEDURE(PoroCapacityWS_Proc), POINTER, SAVE :: g_poro_capacity_proc => NULL()
    PROCEDURE(ThermalCapacityWS_Proc), POINTER, SAVE :: g_thermal_capacity_proc => NULL()
    PUBLIC :: RT_Elem_WS_GetStruct, RT_Elem_WS_GetMultiField, RT_Elem_WS_GetStructBm
    PUBLIC :: RT_Elem_WS_GetStructBm_2, RT_Elem_WS_GetPoroCapacity, RT_Elem_WS_GetThermCapacity
    PUBLIC :: GetStructWS
    PUBLIC :: RT_Elem_WS_RegStruct, RT_Elem_WS_RegMultiField, RT_Elem_WS_RegStructBm
    PUBLIC :: RT_Elem_WS_RegStructBm_2, RT_Elem_WS_RegPoroCapacity, RT_Elem_WS_RegThermCapacity
    
CONTAINS
    
    !> @brief Init workspace manager
    !! @param[in] max_workspaces Maximum number of workspaces
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Mgr_Init(max_workspaces, status)
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_workspaces
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        IF (g_ws_manager%init) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF
        
        IF (PRESENT(max_workspaces)) THEN
            g_ws_manager%max_workspaces = max_workspaces
        END IF
        
        ALLOCATE(g_ws_manager%workspaces(g_ws_manager%max_workspaces))
        g_ws_manager%num_workspaces = 0
        g_ws_manager%next_id = 1
        g_ws_manager%init = .TRUE.
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Mgr_Init
    
    !> @brief Create a new workspace
    !! @param[in] name Workspace name
    !! @param[in] size Workspace size in bytes
    !! @param[out] ws_id Workspace ID
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Create(name, size, ws_id, status)
        CHARACTER(len=*), INTENT(IN) :: name
        INTEGER(i8), INTENT(IN) :: size
        INTEGER(i4), INTENT(OUT) :: ws_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx, i
        INTEGER(i8) :: timestamp
        TYPE(ErrorStatusType) :: init_status
        
        CALL init_error_status(status)
        
        ! Init manager if needed
        IF (.NOT. g_ws_manager%init) THEN
            CALL IF_WS_Mgr_Init(status=init_status)
            IF (init_status%status_code /= IF_STATUS_OK) THEN
                status = init_status
                RETURN
            END IF
        END IF
        
        ! Check if workspace limit reached
        IF (g_ws_manager%num_workspaces >= g_ws_manager%max_workspaces) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'IF_WS_Create: Maximum workspaces reached'
            RETURN
        END IF
        
        ! Find free slot
        idx = -1
        DO i = 1, g_ws_manager%max_workspaces
            IF (.NOT. g_ws_manager%workspaces(i)%init) THEN
                idx = i
                EXIT
            END IF
        END DO
        
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'IF_WS_Create: No free workspace slot'
            RETURN
        END IF
        
        ! Create workspace
        CALL SYSTEM_CLOCK(COUNT=timestamp)
        g_ws_manager%workspaces(idx)%id = g_ws_manager%next_id
        g_ws_manager%workspaces(idx)%name = name
        g_ws_manager%workspaces(idx)%size = size
        g_ws_manager%workspaces(idx)%timestamp = timestamp
        g_ws_manager%workspaces(idx)%ref_count = 1
        g_ws_manager%workspaces(idx)%init = .TRUE.
        
        ! Allocate workspace data
        ALLOCATE(g_ws_manager%workspaces(idx)%data(INT(size / KIND(1.0_wp), KIND=i4)), &
                 STAT=status%status_code)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%message = 'IF_WS_Create: Memory allocation failed'
            g_ws_manager%workspaces(idx)%init = .FALSE.
            RETURN
        END IF
        g_ws_manager%workspaces(idx)%data = 0.0_wp
        
        ws_id = g_ws_manager%workspaces(idx)%id
        g_ws_manager%next_id = g_ws_manager%next_id + 1
        g_ws_manager%num_workspaces = g_ws_manager%num_workspaces + 1
    END SUBROUTINE IF_WS_Create
    
    !> @brief Destroy a workspace
    !! @param[in] ws_id Workspace ID
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Destroy(ws_id, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx
        TYPE(ErrorStatusType) :: dealloc_status
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_Destroy: Workspace not found'
            RETURN
        END IF
        
        ! Decrement reference count
        g_ws_manager%workspaces(idx)%ref_count = &
            g_ws_manager%workspaces(idx)%ref_count - 1
        
        ! Destroy if no references
        IF (g_ws_manager%workspaces(idx)%ref_count <= 0) THEN
            IF (ASSOCIATED(g_ws_manager%workspaces(idx)%data)) THEN
                DEALLOCATE(g_ws_manager%workspaces(idx)%data)
            END IF
            g_ws_manager%workspaces(idx)%init = .FALSE.
            g_ws_manager%workspaces(idx)%id = 0
            g_ws_manager%workspaces(idx)%name = ""
            g_ws_manager%workspaces(idx)%size = 0
            g_ws_manager%workspaces(idx)%timestamp = 0
            g_ws_manager%workspaces(idx)%ref_count = 0
            g_ws_manager%num_workspaces = g_ws_manager%num_workspaces - 1
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Destroy
    
    !> @brief Get workspace by ID
    !! @param[in] ws_id Workspace ID
    !! @param[out] ws Workspace
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Get(ws_id, ws, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        TYPE(Workspace), INTENT(OUT) :: ws
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_Get: Workspace not found'
            RETURN
        END IF
        
        ws = g_ws_manager%workspaces(idx)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Get
    
    !> @brief Resize workspace
    !! @param[in] ws_id Workspace ID
    !! @param[in] new_size New size in bytes
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Resize(ws_id, new_size, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        INTEGER(i8), INTENT(IN) :: new_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx, n_old, n_new, n_copy
        INTEGER(i8) :: old_size
        REAL(wp), POINTER :: new_data(:)
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_Resize: Workspace not found'
            RETURN
        END IF
        
        old_size = g_ws_manager%workspaces(idx)%size
        
        ! Reallocate by allocating new, copying, and deallocating old
        IF (new_size /= old_size) THEN
            n_old = INT(old_size / KIND(1.0_wp), KIND=i4)
            n_new = INT(new_size / KIND(1.0_wp), KIND=i4)
            n_copy = MIN(n_old, n_new)
            
            ! Allocate new memory
            ALLOCATE(new_data(n_new), STAT=status%status_code)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%message = 'IF_WS_Resize: Memory allocation failed'
                RETURN
            END IF
            new_data = 0.0_wp
            
            ! Copy old data if exists
            IF (ASSOCIATED(g_ws_manager%workspaces(idx)%data) .AND. n_copy > 0) THEN
                new_data(1:n_copy) = g_ws_manager%workspaces(idx)%data(1:n_copy)
            END IF
            
            ! Deallocate old memory
            IF (ASSOCIATED(g_ws_manager%workspaces(idx)%data)) THEN
                DEALLOCATE(g_ws_manager%workspaces(idx)%data)
            END IF
            
            ! Update pointer
            g_ws_manager%workspaces(idx)%data => new_data
            g_ws_manager%workspaces(idx)%size = new_size
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE IF_WS_Resize
    
    !> @brief Clear workspace (set all data to zero)
    !! @param[in] ws_id Workspace ID
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Clear(ws_id, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_Clear: Workspace not found'
            RETURN
        END IF
        
        IF (ASSOCIATED(g_ws_manager%workspaces(idx)%data)) THEN
            g_ws_manager%workspaces(idx)%data = 0.0_wp
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Clear
    
    !> @brief Save workspace to file (persistence)
    !! @param[in] ws_id Workspace ID
    !! @param[in] filename File name
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Save(ws_id, filename, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        CHARACTER(len=*), INTENT(IN) :: filename
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx, unit, i
        INTEGER(i8) :: n
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_Save: Workspace not found'
            RETURN
        END IF
        
        OPEN(NEWUNIT=unit, FILE=filename, FORM='UNFORMATTED', &
             STATUS='REPLACE', IOSTAT=status%status_code)
        IF (status%status_code /= 0) THEN
            status%message = 'IF_WS_Save: Failed to open file'
            RETURN
        END IF
        
        n = SIZE(g_ws_manager%workspaces(idx)%data, KIND=i8)
        WRITE(unit) g_ws_manager%workspaces(idx)%id
        WRITE(unit) g_ws_manager%workspaces(idx)%name
        WRITE(unit) n
        WRITE(unit) g_ws_manager%workspaces(idx)%data(1:n)
        
        CLOSE(unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Save
    
    !> @brief Load workspace from file
    !! @param[in] filename File name
    !! @param[out] ws_id Workspace ID
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Load(filename, ws_id, status)
        CHARACTER(len=*), INTENT(IN) :: filename
        INTEGER(i4), INTENT(OUT) :: ws_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: unit, id
        INTEGER(i8) :: n
        CHARACTER(len=64) :: name
        
        CALL init_error_status(status)
        
        OPEN(NEWUNIT=unit, FILE=filename, FORM='UNFORMATTED', &
             STATUS='OLD', IOSTAT=status%status_code)
        IF (status%status_code /= 0) THEN
            status%message = 'IF_WS_Load: Failed to open file'
            RETURN
        END IF
        
        READ(unit) id
        READ(unit) name
        READ(unit) n
        
        CALL IF_WS_Create(name, n * KIND(1.0_wp), ws_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CLOSE(unit)
            RETURN
        END IF
        
        ! Load data (simplified - would need to get workspace pointer)
        CLOSE(unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Load
    
    !> @brief Get workspace state
    !! @param[in] ws_id Workspace ID
    !! @param[out] state Workspace state
    !! @param[out] status Error status
    SUBROUTINE IF_WS_GetState(ws_id, state, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        TYPE(WorkspaceState), INTENT(OUT) :: state
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_GetState: Workspace not found'
            RETURN
        END IF
        
        state%id = g_ws_manager%workspaces(idx)%id
        state%size = g_ws_manager%workspaces(idx)%size
        state%timestamp = g_ws_manager%workspaces(idx)%timestamp
        state%is_active = g_ws_manager%workspaces(idx)%init
        state%is_persistent = .FALSE.  ! Would be set based on persistence flag
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_GetState
    
    !> @brief Set workspace state
    !! @param[in] ws_id Workspace ID
    !! @param[in] state Workspace state
    !! @param[out] status Error status
    SUBROUTINE IF_WS_SetState(ws_id, state, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        TYPE(WorkspaceState), INTENT(IN) :: state
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_SetState: Workspace not found'
            RETURN
        END IF
        
        ! Update workspace state (limited - most fields are read-only)
        g_ws_manager%workspaces(idx)%timestamp = state%timestamp
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_SetState
    
    !> @brief Find workspace by ID (internal helper)
    !! @param[in] ws_id Workspace ID
    !! @return Workspace index, or -1 if not found
    FUNCTION IF_WS_FindById(ws_id) RESULT(idx)
        INTEGER(i4), INTENT(IN) :: ws_id
        INTEGER(i4) :: idx
        
        INTEGER(i4) :: i
        
        idx = -1
        DO i = 1, g_ws_manager%max_workspaces
            IF (g_ws_manager%workspaces(i)%init .AND. &
                g_ws_manager%workspaces(i)%id == ws_id) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION IF_WS_FindById
    
    ! ==========================================================================
    ! WORKSPACE REUSE MECHANISM (task350-399)
    ! ==========================================================================
    
    !> @brief Reuse existing workspace if available
    !! @param[in] name Workspace name
    !! @param[in] min_size Minimum required size
    !! @param[out] ws_id Workspace ID
    !! @param[out] reused .TRUE. if workspace was reused
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Reuse(name, min_size, ws_id, reused, status)
        CHARACTER(len=*), INTENT(IN) :: name
        INTEGER(i8), INTENT(IN) :: min_size
        INTEGER(i4), INTENT(OUT) :: ws_id
        LOGICAL, INTENT(OUT) :: reused
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: i
        
        CALL init_error_status(status)
        reused = .FALSE.
        
        ! Find reusable workspace with matching name and sufficient size
        DO i = 1, g_ws_manager%max_workspaces
            IF (g_ws_manager%workspaces(i)%init .AND. &
                g_ws_manager%workspaces(i)%is_reusable .AND. &
                g_ws_manager%workspaces(i)%name == name .AND. &
                g_ws_manager%workspaces(i)%size >= min_size .AND. &
                g_ws_manager%workspaces(i)%ref_count == 0) THEN
                ! Reuse this workspace
                ws_id = g_ws_manager%workspaces(i)%id
                g_ws_manager%workspaces(i)%ref_count = 1
                g_ws_manager%workspaces(i)%reuse_count = &
                    g_ws_manager%workspaces(i)%reuse_count + 1
                reused = .TRUE.
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO
        
        ! No reusable workspace found, create new one
        CALL IF_WS_Create(name, min_size, ws_id, status)
        reused = .FALSE.
    END SUBROUTINE IF_WS_Reuse
    
    !> @brief Estimate workspace size based on problem parameters
    !! @param[in] n_nodes Number of nodes
    !! @param[in] n_elements Number of elements
    !! @param[in] n_dof_per_node DOF per node
    !! @param[out] estimated_size Estimated size in bytes
    SUBROUTINE IF_WS_EstimateSize(n_nodes, n_elements, n_dof_per_node, estimated_size)
        INTEGER(i4), INTENT(IN) :: n_nodes, n_elements, n_dof_per_node
        INTEGER(i8), INTENT(OUT) :: estimated_size
        
        INTEGER(i8) :: node_size, element_size, dof_size
        
        ! Estimate sizes for different workspace components
        node_size = INT(n_nodes, KIND=i8) * INT(n_dof_per_node, KIND=i8) * KIND(1.0_wp)
        element_size = INT(n_elements, KIND=i8) * 8_i8 * KIND(1.0_wp)  ! Simplified
        dof_size = INT(n_nodes, KIND=i8) * INT(n_dof_per_node, KIND=i8) * KIND(1.0_wp)
        
        ! Total estimated size (with 20% overhead)
        estimated_size = INT(1.2_wp * REAL(node_size + element_size + dof_size, KIND=wp), KIND=i8)
    END SUBROUTINE IF_WS_EstimateSize
    
    !> @brief Get workspace statistics
    !! @param[out] total_workspaces Total number of workspaces
    !! @param[out] total_size Total size in bytes
    !! @param[out] reused_count Total reuse count
    !! @param[out] status Error status
    SUBROUTINE IF_WS_GetStatistics(total_workspaces, total_size, reused_count, status)
        INTEGER(i4), INTENT(OUT) :: total_workspaces
        INTEGER(i8), INTENT(OUT) :: total_size
        INTEGER(i4), INTENT(OUT) :: reused_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: i
        
        CALL init_error_status(status)
        
        total_workspaces = g_ws_manager%num_workspaces
        total_size = 0_i8
        reused_count = 0
        
        DO i = 1, g_ws_manager%max_workspaces
            IF (g_ws_manager%workspaces(i)%init) THEN
                total_size = total_size + g_ws_manager%workspaces(i)%size
                reused_count = reused_count + g_ws_manager%workspaces(i)%reuse_count
            END IF
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_GetStatistics
    
    !> @brief Compact workspace pool (remove unused workspaces)
    !! @param[out] freed_count Number of workspaces freed
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Compact(freed_count, status)
        INTEGER(i4), INTENT(OUT) :: freed_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: i
        
        CALL init_error_status(status)
        freed_count = 0
        
        DO i = 1, g_ws_manager%max_workspaces
            IF (g_ws_manager%workspaces(i)%init .AND. &
                g_ws_manager%workspaces(i)%ref_count == 0 .AND. &
                .NOT. g_ws_manager%workspaces(i)%is_reusable) THEN
                ! Destroy unused non-reusable workspace
                CALL IF_WS_Destroy(g_ws_manager%workspaces(i)%id, status)
                IF (status%status_code == IF_STATUS_OK) THEN
                    freed_count = freed_count + 1
                END IF
            END IF
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_Compact
    
    !> @brief Get reuse count for a workspace
    !! @param[in] ws_id Workspace ID
    !! @param[out] reuse_count Reuse count
    !! @param[out] status Error status
    SUBROUTINE IF_WS_GetReuseCount(ws_id, reuse_count, status)
        INTEGER(i4), INTENT(IN) :: ws_id
        INTEGER(i4), INTENT(OUT) :: reuse_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: idx
        
        CALL init_error_status(status)
        
        idx = IF_WS_FindById(ws_id)
        IF (idx < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_WS_GetReuseCount: Workspace not found'
            RETURN
        END IF
        
        reuse_count = g_ws_manager%workspaces(idx)%reuse_count
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_WS_GetReuseCount
    
    ! ==========================================================================
    ! ELEMENT WORKSPACE REGISTRATION FUNCTIONS
    ! ==========================================================================
    
    !> @brief Register structural workspace procedure
    !! @param[in] proc Procedure pointer for structural workspace
    SUBROUTINE RT_Elem_WS_RegStruct(proc)
        PROCEDURE(StructWS_Proc) :: proc
        g_struct_ws_proc => proc
    END SUBROUTINE RT_Elem_WS_RegStruct
    
    !> @brief Register multi-field workspace procedure
    !! @param[in] proc Procedure pointer for multi-field workspace
    SUBROUTINE RT_Elem_WS_RegMultiField(proc)
        PROCEDURE(MultiFieldWS_Proc) :: proc
        g_multifield_ws_proc => proc
    END SUBROUTINE RT_Elem_WS_RegMultiField
    
    !> @brief Register structural beam workspace procedure
    !! @param[in] proc Procedure pointer for structural beam workspace
    SUBROUTINE RT_Elem_WS_RegStructBm(proc)
        PROCEDURE(StructBmWS_Proc) :: proc
        g_struct_bm_proc => proc
    END SUBROUTINE RT_Elem_WS_RegStructBm
    
    !> @brief Register structural beam workspace procedure (variant 2)
    !! @param[in] proc Procedure pointer for structural beam workspace
    SUBROUTINE RT_Elem_WS_RegStructBm_2(proc)
        PROCEDURE(StructBmWS_Proc_2) :: proc
        g_struct_bm_proc_2 => proc
    END SUBROUTINE RT_Elem_WS_RegStructBm_2
    
    !> @brief Register porous capacity workspace procedure
    !! @param[in] proc Procedure pointer for porous capacity workspace
    SUBROUTINE RT_Elem_WS_RegPoroCapacity(proc)
        PROCEDURE(PoroCapacityWS_Proc) :: proc
        g_poro_capacity_proc => proc
    END SUBROUTINE RT_Elem_WS_RegPoroCapacity
    
    !> @brief Register thermal capacity workspace procedure
    !! @param[in] proc Procedure pointer for thermal capacity workspace
    SUBROUTINE RT_Elem_WS_RegThermCapacity(proc)
        PROCEDURE(ThermalCapacityWS_Proc) :: proc
        g_thermal_capacity_proc => proc
    END SUBROUTINE RT_Elem_WS_RegThermCapacity
    
    ! ==========================================================================
    ! ELEMENT WORKSPACE ACCESS FUNCTIONS
    ! ==========================================================================
    
    !> @brief Get structural workspace
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] Ke Stiffness matrix pointer
    !! @param[out] Re Residual vector pointer
    !! @param[out] Me Mass matrix pointer
    !! @param[out] Ce Damping matrix pointer
    !! @param[out] B Strain-displacement matrix pointer
    SUBROUTINE RT_Elem_WS_GetStruct(nDOF, Ke, Re, Me, Ce, B)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
        REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)
        REAL(wp), POINTER, INTENT(OUT) :: B(:,:)
        
        IF (ASSOCIATED(g_struct_ws_proc)) THEN
            CALL g_struct_ws_proc(nDOF, Ke, Re, Me, Ce, B)
        ELSE
            NULLIFY(Ke, Re, Me, Ce, B)
        END IF
    END SUBROUTINE RT_Elem_WS_GetStruct
    
    !> @brief Get multi-field workspace
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] Ke Stiffness matrix pointer
    !! @param[out] Re Residual vector pointer
    !! @param[out] Me Mass matrix pointer
    !! @param[out] Ce Damping matrix pointer
    SUBROUTINE RT_Elem_WS_GetMultiField(nDOF, Ke, Re, Me, Ce)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
        REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)
        
        IF (ASSOCIATED(g_multifield_ws_proc)) THEN
            CALL g_multifield_ws_proc(nDOF, Ke, Re, Me, Ce)
        ELSE
            NULLIFY(Ke, Re, Me, Ce)
        END IF
    END SUBROUTINE RT_Elem_WS_GetMultiField
    
    !> @brief Get structural beam workspace
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] mB Beam matrix pointer
    SUBROUTINE RT_Elem_WS_GetStructBm(nDOF, mB)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: mB(:)
        
        IF (ASSOCIATED(g_struct_bm_proc)) THEN
            CALL g_struct_bm_proc(nDOF, mB)
        ELSE
            NULLIFY(mB)
        END IF
    END SUBROUTINE RT_Elem_WS_GetStructBm
    
    !> @brief Get structural beam workspace (variant 2)
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] B Strain-displacement matrix pointer
    !! @param[out] mB Beam matrix pointer
    SUBROUTINE RT_Elem_WS_GetStructBm_2(nDOF, B, mB)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: B(:,:)
        REAL(wp), POINTER, INTENT(OUT) :: mB(:)
        
        IF (ASSOCIATED(g_struct_bm_proc_2)) THEN
            CALL g_struct_bm_proc_2(nDOF, B, mB)
        ELSE
            NULLIFY(B, mB)
        END IF
    END SUBROUTINE RT_Elem_WS_GetStructBm_2
    
    !> @brief Get porous capacity workspace
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] Spp Porous capacity matrix pointer
    SUBROUTINE RT_Elem_WS_GetPoroCapacity(nDOF, Spp)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: Spp(:,:)
        
        IF (ASSOCIATED(g_poro_capacity_proc)) THEN
            CALL g_poro_capacity_proc(nDOF, Spp)
        ELSE
            NULLIFY(Spp)
        END IF
    END SUBROUTINE RT_Elem_WS_GetPoroCapacity
    
    !> @brief Get thermal capacity workspace
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] Ctt Thermal capacity matrix pointer
    SUBROUTINE RT_Elem_WS_GetThermCapacity(nDOF, Ctt)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: Ctt(:,:)
        
        IF (ASSOCIATED(g_thermal_capacity_proc)) THEN
            CALL g_thermal_capacity_proc(nDOF, Ctt)
        ELSE
            NULLIFY(Ctt)
        END IF
    END SUBROUTINE RT_Elem_WS_GetThermCapacity
    
    !> @brief Get structural workspace (compatibility alias)
    !! @param[in] nDOF Number of degrees of freedom
    !! @param[out] Ke Stiffness matrix pointer
    !! @param[out] Re Residual vector pointer
    !! @param[out] Me Mass matrix pointer
    !! @param[out] Ce Damping matrix pointer
    !! @param[out] B Strain-displacement matrix pointer
    SUBROUTINE GetStructWS(nDOF, Ke, Re, Me, Ce, B)
        INTEGER(i4), INTENT(IN) :: nDOF
        REAL(wp), POINTER, INTENT(OUT) :: Ke(:,:), Re(:)
        REAL(wp), POINTER, INTENT(OUT) :: Me(:,:), Ce(:,:)
        REAL(wp), POINTER, INTENT(OUT) :: B(:,:)
        CALL RT_Elem_WS_GetStruct(nDOF, Ke, Re, Me, Ce, B)
    END SUBROUTINE GetStructWS
    
    ! ==========================================================================
    ! SOLVER WORKSPACE API (merged from IF_Workspace_Solver)
    ! ==========================================================================
    
    !> @brief Allocate solver workspace vector (real 1D)
    !! Routes to IF_Mem_Mgr IF_MEM_DOMAIN_SOLV
    !! @param[in] n Size of vector
    !! @param[in] name Workspace name
    !! @param[out] ptr Pointer to allocated workspace
    !! @param[out] id Pointer ID
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Alloc_SolverVec(n, name, ptr, id, status)
        INTEGER(i4), INTENT(IN) :: n
        CHARACTER(len=*), INTENT(IN) :: name
        REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
        INTEGER(i4), INTENT(OUT) :: id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL UF_Mem_AllocReal1D(IF_MEM_DOMAIN_SOLV, 0_i4, n, name, ptr, id, status)
    END SUBROUTINE IF_WS_Alloc_SolverVec
    
    !> @brief Free solver workspace vector by id
    !! @param[in] id Pointer ID
    !! @param[out] status Error status
    SUBROUTINE IF_WS_Free_SolverVec(id, status)
        INTEGER(i4), INTENT(IN) :: id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL UF_Mem_FreeReal1D(id, status)
    END SUBROUTINE IF_WS_Free_SolverVec
    
    ! ==========================================================================
    ! SOLVER PERSISTENT BUFFERS API (merged from UF_WorkspaceManager)
    ! ==========================================================================
    
    SUBROUTINE IF_WS_Get_NL_DeltaWorkspace(ndof, delta_ws)
        INTEGER(i4), INTENT(IN) :: ndof
        REAL(wp), POINTER, INTENT(OUT) :: delta_ws(:)
        INTEGER(i4) :: cur
        NULLIFY(delta_ws)
        IF (ndof <= 0) RETURN
        cur = 0
        IF (ALLOCATED(g_delta_ws)) cur = SIZE(g_delta_ws)
        IF (cur < ndof) THEN
            IF (ALLOCATED(g_delta_ws)) DEALLOCATE(g_delta_ws)
            ALLOCATE(g_delta_ws(ndof))
        END IF
        delta_ws => g_delta_ws(1:ndof)
    END SUBROUTINE IF_WS_Get_NL_DeltaWorkspace

    SUBROUTINE IF_WS_Get_Linear_Workspace(n, work, ipiv)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), POINTER, INTENT(OUT) :: work(:)
        INTEGER(i4), POINTER, INTENT(OUT) :: ipiv(:)
        INTEGER(i4) :: cur
        NULLIFY(work)
        NULLIFY(ipiv)
        IF (n <= 0) RETURN
        cur = 0
        IF (ALLOCATED(g_lin_work)) cur = SIZE(g_lin_work)
        IF (cur < n) THEN
            IF (ALLOCATED(g_lin_work)) DEALLOCATE(g_lin_work)
            IF (ALLOCATED(g_lin_ipiv)) DEALLOCATE(g_lin_ipiv)
            ALLOCATE(g_lin_work(n), g_lin_ipiv(n))
        END IF
        work => g_lin_work(1:n)
        ipiv => g_lin_ipiv(1:n)
    END SUBROUTINE IF_WS_Get_Linear_Workspace

    SUBROUTINE IF_WS_Finalize()
        IF (ALLOCATED(g_delta_ws)) DEALLOCATE(g_delta_ws)
        IF (ALLOCATED(g_lin_work)) DEALLOCATE(g_lin_work)
        IF (ALLOCATED(g_lin_ipiv)) DEALLOCATE(g_lin_ipiv)
    END SUBROUTINE IF_WS_Finalize

    SUBROUTINE UF_WS_Get_NL_DeltaWorkspace(ndof, delta_ws)
        INTEGER(i4), INTENT(IN) :: ndof
        REAL(wp), POINTER, INTENT(OUT) :: delta_ws(:)
        CALL IF_WS_Get_NL_DeltaWorkspace(ndof, delta_ws)
    END SUBROUTINE UF_WS_Get_NL_DeltaWorkspace

    SUBROUTINE UF_WS_Get_Lin_Workspace(n, work, ipiv)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), POINTER, INTENT(OUT) :: work(:)
        INTEGER(i4), POINTER, INTENT(OUT) :: ipiv(:)
        CALL IF_WS_Get_Linear_Workspace(n, work, ipiv)
    END SUBROUTINE UF_WS_Get_Lin_Workspace

    SUBROUTINE UF_WS_Get_Linear_Workspace(n, work, ipiv)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), POINTER, INTENT(OUT) :: work(:)
        INTEGER(i4), POINTER, INTENT(OUT) :: ipiv(:)
        CALL IF_WS_Get_Linear_Workspace(n, work, ipiv)
    END SUBROUTINE UF_WS_Get_Linear_Workspace

    SUBROUTINE UF_WS_Finalize()
        CALL IF_WS_Finalize()
    END SUBROUTINE UF_WS_Finalize
    
END MODULE IF_Mem_WS