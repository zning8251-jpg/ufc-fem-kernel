!===============================================================================
! MODULE:  MD_Mesh_NodeDef
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Def
! BRIEF:   Node definition with coordinates, DOF, BC and load support
!          (Desc node definition).
!===============================================================================

!===============================================================================
! Module: MD_Node_Algo
! Layer:  L3_MD - Model Definition Layer
! Domain: Ctx - Context
! Purpose: [TODO: Add module purpose]
! Theory:  [TODO: Add theory reference]
! Status:  Phase B | Last verified: 2026-03-11
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Mesh_NodeDef
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE MD_Base_ObjModel, ONLY: DescBase, StateBase, CAT_DESC, CAT_STATE
    USE MD_DOF_Mgr, ONLY: MD_DOFMap, MD_MESH_MAX_DOF_PER_NOD
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: MD_Node_Type, MD_Node_State
    PUBLIC :: MD_Node_Create, MD_Node_Destroy
    PUBLIC :: MD_Node_SetCoords, MD_Node_GetCoords
    PUBLIC :: MD_Node_SetDOF, MD_Node_GetDOF
    PUBLIC :: MD_Node_Transform, MD_Node_GetDistance
    PUBLIC :: MD_Node_GetStatistics, MD_Node_Valid
    
    ! ==========================================================================
    ! CONSTANTS
    ! ==========================================================================
    INTEGER(i4), PARAMETER :: MD_MESH_MAX_NODE_NAME = 80
    INTEGER(i4), PARAMETER :: MD_MESH_MAX_NODE_TAGS = 100
    
    ! ==========================================================================
    ! NODE TYPE - Extended Node Definition (task3000-3049)
    ! ==========================================================================
    TYPE, PUBLIC, EXTENDS(DescBase) :: MD_Node_Type
        ! Basic identification
        INTEGER(i4) :: id = 0_i4                    ! Node ID (1-based)
        CHARACTER(LEN=MD_MESH_MAX_NODE_NAME) :: name = ""    ! Node name (optional)
        
        ! Spatial coordinates
        REAL(wp) :: coords(3) = 0.0_wp              ! Coordinates (x, y, z)
        INTEGER(i4) :: spatial_dim = 3_i4          ! Spatial dimension (2 or 3)
        
        ! DOF information
        INTEGER(i4) :: nDof = 0_i4               ! Number of active DOFs
        INTEGER(i4) :: dof_map(MD_MESH_MAX_DOF_PER_NOD) = 0_i4  ! DOF mapping to global system
        INTEGER(i4) :: dof_offset = 0_i4           ! Offset in global DOF array
        
        ! Boundary conditions and loads
        LOGICAL :: bc_applied(MD_MESH_MAX_DOF_PER_NOD) = .FALSE.  ! BC flags per DOF
        REAL(wp) :: bc_values(MD_MESH_MAX_DOF_PER_NOD) = 0.0_wp   ! BC prescribed values
        REAL(wp) :: load_values(MD_MESH_MAX_DOF_PER_NOD) = 0.0_wp ! Load values per DOF
        
        ! Node properties
        REAL(wp) :: mass = 0.0_wp                   ! Nodal mass (for point mass)
        REAL(wp) :: temperature = 0.0_wp           ! Nodal temperature
        REAL(wp) :: pressure = 0.0_wp               ! Nodal pressure (for fluid)
        
        ! Connectivity information
        INTEGER(i4) :: nElems = 0_i4         ! Number of connected elements
        INTEGER(i4), ALLOCATABLE :: element_list(:) ! List of connected element IDs
        
        ! Tags and metadata
        INTEGER(i4) :: num_tags = 0_i4
        CHARACTER(LEN=MD_MESH_MAX_NODE_NAME), ALLOCATABLE :: tags(:)
        
        ! Status flags
        LOGICAL :: is_active = .TRUE.               ! Active/inactive flag
        LOGICAL :: is_boundary = .FALSE.            ! Boundary node flag
        LOGICAL :: is_contact = .FALSE.             ! Contact node flag
        
    CONTAINS
        PROCEDURE :: Init => Node_Init
        PROCEDURE :: Clean => Node_Clean
        PROCEDURE :: Valid => Node_Valid_Fn
        PROCEDURE :: GetCoords => Node_GetCoords
        PROCEDURE :: SetCoords => Node_SetCoords
        PROCEDURE :: GetDOF => Node_GetDOF
        PROCEDURE :: SetDOF => Node_SetDOF
        PROCEDURE :: Transform => Node_Transform
        PROCEDURE :: GetDistance => Node_GetDistance
        PROCEDURE :: GetStatistics => Node_GetStatistics
        PROCEDURE :: AddElement => Node_AddElement
        PROCEDURE :: RemoveElement => Node_RemoveElement
        PROCEDURE :: AddTag => Node_AddTag
        PROCEDURE :: HasTag => Node_HasTag
    END TYPE MD_Node_Type
    
    ! ==========================================================================
    ! NODE STATE - Node State Variables (task3000-3049)
    ! ==========================================================================
    TYPE, PUBLIC, EXTENDS(StateBase) :: MD_Node_State
        INTEGER(i4) :: node_id = 0_i4              ! Reference to node ID
        
        ! Displacement state
        REAL(wp) :: displacement(3) = 0.0_wp       ! Displacement (u_x, u_y, u_z)
        REAL(wp) :: velocity(3) = 0.0_wp           ! Velocity (v_x, v_y, v_z)
        REAL(wp) :: acceleration(3) = 0.0_wp       ! Acceleration (a_x, a_y, a_z)
        
        ! Rotation state (for beam/shell nodes)
        REAL(wp) :: rotation(3) = 0.0_wp           ! Rotation (?_x, ?_y, ?_z)
        REAL(wp) :: angular_velocity(3) = 0.0_wp   ! Angular velocity
        REAL(wp) :: angular_acceleration(3) = 0.0_wp ! Angular acceleration
        
        ! Temperature and pressure state
        REAL(wp) :: temperature = 0.0_wp
        REAL(wp) :: temperature_rate = 0.0_wp
        REAL(wp) :: pressure = 0.0_wp
        
        ! Reaction forces
        REAL(wp) :: reaction_force(3) = 0.0_wp     ! Reaction forces
        REAL(wp) :: reaction_moment(3) = 0.0_wp    ! Reaction moments
        
        ! History variables
        REAL(wp), ALLOCATABLE :: history(:)        ! User-defined history variables
        
    CONTAINS
        PROCEDURE :: Init => NodeState_Init
        PROCEDURE :: Clean => NodeState_Clean
        PROCEDURE :: Update => NodeState_Update
        PROCEDURE :: GetDisplacement => NodeState_GetDisplacement
        PROCEDURE :: SetDisplacement => NodeState_SetDisplacement
    END TYPE MD_Node_State
    
CONTAINS
    
    ! ==========================================================================
    ! NODE INITIALIZATION AND CLEANUP (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE Node_Init(this, id, coords, name, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: id
        REAL(wp), INTENT(IN) :: coords(3)
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        CALL this%DescBase%Init(CAT_DESC, 'NODE')
        
        this%cfg%id = id
        this%coords = coords
        this%spatial_dim = 3_i4
        IF (PRESENT(name)) this%name = TRIM(name)
        
        this%nDof = 0_i4
        this%dof_map = 0_i4
        this%dof_offset = 0_i4
        this%bc_applied = .FALSE.
        this%bc_values = 0.0_wp
        this%load_values = 0.0_wp
        
        this%mass = 0.0_wp
        this%temperature = 0.0_wp
        this%pressure = 0.0_wp
        
        this%nElems = 0_i4
        IF (ALLOCATED(this%element_list)) DEALLOCATE(this%element_list)
        
        this%num_tags = 0_i4
        IF (ALLOCATED(this%tags)) DEALLOCATE(this%tags)
        
        this%is_active = .TRUE.
        this%is_boundary = .FALSE.
        this%is_contact = .FALSE.
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_Init
    
    SUBROUTINE Node_Clean(this)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        
        IF (ALLOCATED(this%element_list)) DEALLOCATE(this%element_list)
        IF (ALLOCATED(this%tags)) DEALLOCATE(this%tags)
        
        CALL this%DescBase%Clean()
        
    END SUBROUTINE Node_Clean
    
    ! ==========================================================================
    ! NODE COORDINATE OPERATIONS (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE Node_GetCoords(this, coords, status)
        CLASS(MD_Node_Type), INTENT(IN) :: this
        REAL(wp), INTENT(OUT) :: coords(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        coords = this%coords
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_GetCoords
    
    SUBROUTINE Node_SetCoords(this, coords, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: coords(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        this%coords = coords
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_SetCoords
    
    ! ==========================================================================
    ! NODE DOF OPERATIONS (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE Node_GetDOF(this, nDof, dof_map, dof_offset, status)
        CLASS(MD_Node_Type), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: nDof
        INTEGER(i4), INTENT(OUT) :: dof_map(MD_MESH_MAX_DOF_PER_NOD)
        INTEGER(i4), INTENT(OUT) :: dof_offset
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        nDof = this%nDof
        dof_map = this%dof_map
        dof_offset = this%dof_offset
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_GetDOF
    
    SUBROUTINE Node_SetDOF(this, nDof, dof_map, dof_offset, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nDof
        INTEGER(i4), INTENT(IN) :: dof_map(MD_MESH_MAX_DOF_PER_NOD)
        INTEGER(i4), INTENT(IN) :: dof_offset
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        IF (nDof < 0 .OR. nDof > MD_MESH_MAX_DOF_PER_NOD) THEN
            IF (PRESENT(status)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "MD_Node_SetDOF: Invalid nDof"
            END IF
            RETURN
        END IF
        
        this%nDof = nDof
        this%dof_map = dof_map
        this%dof_offset = dof_offset
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_SetDOF
    
    ! ==========================================================================
    ! NODE TRANSFORMATION OPERATIONS (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE Node_Transform(this, translation, rotation_matrix, scale, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN), OPTIONAL :: translation(3)
        REAL(wp), INTENT(IN), OPTIONAL :: rotation_matrix(3,3)
        REAL(wp), INTENT(IN), OPTIONAL :: scale
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Translation
        IF (PRESENT(translation)) THEN
            this%coords = this%coords + translation
        END IF
        
        ! Rotation
        IF (PRESENT(rotation_matrix)) THEN
            this%coords = MATMUL(rotation_matrix, this%coords)
        END IF
        
        ! Scaling
        IF (PRESENT(scale)) THEN
            this%coords = this%coords * scale
        END IF
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_Transform
    
    REAL(wp) FUNCTION Node_GetDistance(this, other_coords) RESULT(distance)
        CLASS(MD_Node_Type), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: other_coords(3)
        
        REAL(wp) :: diff(3)
        
        diff = this%coords - other_coords
        distance = SQRT(DOT_PRODUCT(diff, diff))
        
    END FUNCTION Node_GetDistance
    
    ! ==========================================================================
    ! NODE ELEMENT CONNECTIVITY (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE Node_AddElement(this, element_id, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: element_id
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4), ALLOCATABLE :: temp_list(:)
        INTEGER(i4) :: i
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Check if already in list
        IF (ALLOCATED(this%element_list)) THEN
            DO i = 1, this%nElems
                IF (this%element_list(i) == element_id) THEN
                    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
                    RETURN
                END IF
            END DO
        END IF
        
        ! Add to list
        this%nElems = this%nElems + 1
        IF (ALLOCATED(this%element_list)) THEN
            ALLOCATE(temp_list(this%nElems))
            temp_list(1:this%nElems-1) = this%element_list
            temp_list(this%nElems) = element_id
            DEALLOCATE(this%element_list)
            this%element_list = temp_list
        ELSE
            ALLOCATE(this%element_list(1))
            this%element_list(1) = element_id
        END IF
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_AddElement
    
    SUBROUTINE Node_RemoveElement(this, element_id, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: element_id
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4), ALLOCATABLE :: temp_list(:)
        INTEGER(i4) :: i, j
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        IF (.NOT. ALLOCATED(this%element_list) .OR. this%nElems == 0) THEN
            IF (PRESENT(status)) status%status_code = IF_STATUS_NOT_FOUND
            RETURN
        END IF
        
        ! Find and remove
        j = 0
        DO i = 1, this%nElems
            IF (this%element_list(i) /= element_id) THEN
                j = j + 1
                IF (j < i) this%element_list(j) = this%element_list(i)
            END IF
        END DO
        
        IF (j < this%nElems) THEN
            this%nElems = j
            IF (j > 0) THEN
                ALLOCATE(temp_list(j))
                temp_list = this%element_list(1:j)
                DEALLOCATE(this%element_list)
                this%element_list = temp_list
            ELSE
                DEALLOCATE(this%element_list)
            END IF
            IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        ELSE
            IF (PRESENT(status)) status%status_code = IF_STATUS_NOT_FOUND
        END IF
        
    END SUBROUTINE Node_RemoveElement
    
    ! ==========================================================================
    ! NODE TAGS OPERATIONS (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE Node_AddTag(this, tag, status)
        CLASS(MD_Node_Type), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: tag
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CHARACTER(LEN=MD_MESH_MAX_NODE_NAME), ALLOCATABLE :: temp_tags(:)
        INTEGER(i4) :: i
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Check if already exists
        IF (ALLOCATED(this%tags)) THEN
            DO i = 1, this%num_tags
                IF (TRIM(this%tags(i)) == TRIM(tag)) THEN
                    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
                    RETURN
                END IF
            END DO
        END IF
        
        ! Add tag
        this%num_tags = this%num_tags + 1
        IF (ALLOCATED(this%tags)) THEN
            ALLOCATE(temp_tags(this%num_tags))
            temp_tags(1:this%num_tags-1) = this%tags
            temp_tags(this%num_tags) = TRIM(tag)
            DEALLOCATE(this%tags)
            this%tags = temp_tags
        ELSE
            ALLOCATE(this%tags(1))
            this%tags(1) = TRIM(tag)
        END IF
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_AddTag
    
    LOGICAL FUNCTION Node_HasTag(this, tag) RESULT(has_tag)
        CLASS(MD_Node_Type), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: tag
        
        INTEGER(i4) :: i
        
        has_tag = .FALSE.
        
        IF (ALLOCATED(this%tags)) THEN
            DO i = 1, this%num_tags
                IF (TRIM(this%tags(i)) == TRIM(tag)) THEN
                    has_tag = .TRUE.
                    RETURN
                END IF
            END DO
        END IF
        
    END FUNCTION Node_HasTag
    
    ! ==========================================================================
    ! NODE VALIDATION AND STATISTICS (task3050-3099)
    ! ==========================================================================
    
    FUNCTION Node_Valid_Fn(this) RESULT(ok)
        CLASS(MD_Node_Type), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%cfg%id <= 0) ok = .FALSE.
        IF (this%nDof < 0 .OR. this%nDof > MD_MESH_MAX_DOF_PER_NOD) ok = .FALSE.
    END FUNCTION Node_Valid_Fn

    
    SUBROUTINE Node_GetStatistics(this, stats, status)
        CLASS(MD_Node_Type), INTENT(IN) :: this
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        WRITE(stats, '(A,I0,A,3(ES12.5,1X),A,I0,A,I0,A,L1)') &
            'Node Statistics: id=', this%cfg%id, &
            ', coords=(', this%coords, &
            '), nDof=', this%nDof, &
            ', nElems=', this%nElems, &
            ', is_active=', this%is_active
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE Node_GetStatistics
    
    ! ==========================================================================
    ! STANDALONE NODE OPERATIONS (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE MD_Node_Create(node, id, coords, name, status)
        TYPE(MD_Node_Type), INTENT(OUT) :: node
        INTEGER(i4), INTENT(IN) :: id
        REAL(wp), INTENT(IN) :: coords(3)
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%Init(id, coords, name, status)
        
    END SUBROUTINE MD_Node_Create
    
    SUBROUTINE MD_Node_Destroy(node, status)
        TYPE(MD_Node_Type), INTENT(INOUT) :: node
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        CALL node%Clean()
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE MD_Node_Destroy
    
    SUBROUTINE MD_Node_SetCoords(node, coords, status)
        TYPE(MD_Node_Type), INTENT(INOUT) :: node
        REAL(wp), INTENT(IN) :: coords(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%SetCoords(coords, status)
        
    END SUBROUTINE MD_Node_SetCoords
    
    SUBROUTINE MD_Node_GetCoords(node, coords, status)
        TYPE(MD_Node_Type), INTENT(IN) :: node
        REAL(wp), INTENT(OUT) :: coords(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%GetCoords(coords, status)
        
    END SUBROUTINE MD_Node_GetCoords
    
    SUBROUTINE MD_Node_SetDOF(node, nDof, dof_map, dof_offset, status)
        TYPE(MD_Node_Type), INTENT(INOUT) :: node
        INTEGER(i4), INTENT(IN) :: nDof
        INTEGER(i4), INTENT(IN) :: dof_map(MD_MESH_MAX_DOF_PER_NOD)
        INTEGER(i4), INTENT(IN) :: dof_offset
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%SetDOF(nDof, dof_map, dof_offset, status)
        
    END SUBROUTINE MD_Node_SetDOF
    
    SUBROUTINE MD_Node_GetDOF(node, nDof, dof_map, dof_offset, status)
        TYPE(MD_Node_Type), INTENT(IN) :: node
        INTEGER(i4), INTENT(OUT) :: nDof
        INTEGER(i4), INTENT(OUT) :: dof_map(MD_MESH_MAX_DOF_PER_NOD)
        INTEGER(i4), INTENT(OUT) :: dof_offset
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%GetDOF(nDof, dof_map, dof_offset, status)
        
    END SUBROUTINE MD_Node_GetDOF
    
    SUBROUTINE MD_Node_Transform(node, translation, rotation_matrix, scale, status)
        TYPE(MD_Node_Type), INTENT(INOUT) :: node
        REAL(wp), INTENT(IN), OPTIONAL :: translation(3)
        REAL(wp), INTENT(IN), OPTIONAL :: rotation_matrix(3,3)
        REAL(wp), INTENT(IN), OPTIONAL :: scale
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%Transform(translation, rotation_matrix, scale, status)
        
    END SUBROUTINE MD_Node_Transform
    
    REAL(wp) FUNCTION MD_Node_GetDistance(node, other_coords) RESULT(distance)
        TYPE(MD_Node_Type), INTENT(IN) :: node
        REAL(wp), INTENT(IN) :: other_coords(3)
        
        distance = node%GetDistance(other_coords)
        
    END FUNCTION MD_Node_GetDistance
    
    SUBROUTINE MD_Node_GetStatistics(node, stats, status)
        TYPE(MD_Node_Type), INTENT(IN) :: node
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        CALL node%GetStatistics(stats, status)
        
    END SUBROUTINE MD_Node_GetStatistics
    
    SUBROUTINE MD_Node_Valid(node, status)
        TYPE(MD_Node_Type), INTENT(IN) :: node
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        IF (.NOT. node%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Node validation failed"
        END IF
        
    END SUBROUTINE MD_Node_Valid
    
    ! ==========================================================================
    ! NODE STATE OPERATIONS (task3050-3099)
    ! ==========================================================================
    
    SUBROUTINE NodeState_Init(this, node_id, status)
        CLASS(MD_Node_State), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        CALL this%StateBase%Init(CAT_STATE, 'MD_MESH_NODE_STATE')
        
        this%node_id = node_id
        this%displacement = 0.0_wp
        this%velocity = 0.0_wp
        this%acceleration = 0.0_wp
        this%rotation = 0.0_wp
        this%angular_velocity = 0.0_wp
        this%angular_acceleration = 0.0_wp
        this%temperature = 0.0_wp
        this%temperature_rate = 0.0_wp
        this%pressure = 0.0_wp
        this%reaction_force = 0.0_wp
        this%reaction_moment = 0.0_wp
        
        IF (ALLOCATED(this%history)) DEALLOCATE(this%history)
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE NodeState_Init
    
    SUBROUTINE NodeState_Clean(this)
        CLASS(MD_Node_State), INTENT(INOUT) :: this
        
        IF (ALLOCATED(this%history)) DEALLOCATE(this%history)
        
        CALL this%StateBase%Clean()
        
    END SUBROUTINE NodeState_Clean
    
    SUBROUTINE NodeState_Update(this, dt, status)
        CLASS(MD_Node_State), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: dt
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Update displacement: u_new = u_old + v*dt + 0.5*a*dt^2
        this%displacement = this%displacement + this%velocity * dt + &
                            HALF * this%acceleration * dt * dt
        
        ! Update velocity: v_new = v_old + a*dt
        this%velocity = this%velocity + this%acceleration * dt
        
        ! Update rotation similarly
        this%rotation = this%rotation + this%angular_velocity * dt + &
                        HALF * this%angular_acceleration * dt * dt
        this%angular_velocity = this%angular_velocity + this%angular_acceleration * dt
        
        ! Update temperature
        this%temperature = this%temperature + this%temperature_rate * dt
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE NodeState_Update
    
    SUBROUTINE NodeState_GetDisplacement(this, displacement, status)
        CLASS(MD_Node_State), INTENT(IN) :: this
        REAL(wp), INTENT(OUT) :: displacement(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        displacement = this%displacement
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE NodeState_GetDisplacement
    
    SUBROUTINE NodeState_SetDisplacement(this, displacement, status)
        CLASS(MD_Node_State), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: displacement(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        this%displacement = displacement
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE NodeState_SetDisplacement

END MODULE MD_Mesh_NodeDef