!===============================================================================
! MODULE:  MD_Sets_Mgr
! LAYER:   L3_MD
! DOMAIN:  Part / Sets
! ROLE:    _Mgr
! BRIEF:   Sets manager — P0 Register/Query for node sets, element sets,
!          surface definitions (legacy UF_ types).
!===============================================================================
MODULE MD_Sets_Mgr
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE
    PUBLIC :: UF_NodeSet, UF_ElemSet, UF_Surface, UF_SurfaceFacet
    PUBLIC :: MAX_SET_NAME, SURF_TYPE_ELEMENT, SURF_TYPE_NODE
    
    INTEGER(i4), PARAMETER :: MAX_SET_NAME = 80
    INTEGER(i4), PARAMETER :: SURF_TYPE_ELEMENT = 1
    INTEGER(i4), PARAMETER :: SURF_TYPE_NODE = 2
    
    TYPE :: UF_NodeSet
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4), ALLOCATABLE :: node_ids(:)
        LOGICAL :: is_generate = .FALSE.
        INTEGER(i4) :: gen_first = 0, gen_last = 0, gen_incr = 1
    CONTAINS
        PROCEDURE :: init => nodeset_init
        PROCEDURE :: add_node => nodeset_add_node
        PROCEDURE :: add_range => nodeset_add_range
        PROCEDURE :: contains => nodeset_contains
    END TYPE UF_NodeSet
    
    TYPE :: UF_ElemSet
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: num_elems = 0
        INTEGER(i4), ALLOCATABLE :: elem_ids(:)
        LOGICAL :: is_generate = .FALSE.
        INTEGER(i4) :: gen_first = 0, gen_last = 0, gen_incr = 1
    CONTAINS
        PROCEDURE :: init => elemset_init
        PROCEDURE :: add_elem => elemset_add_elem
        PROCEDURE :: add_range => elemset_add_range
        PROCEDURE :: contains => elemset_contains
    END TYPE UF_ElemSet
    
    TYPE :: UF_SurfaceFacet
        INTEGER(i4) :: elem_id = 0
        INTEGER(i4) :: face_id = 0
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: normal(3) = 0.0_wp
    END TYPE UF_SurfaceFacet
    
    TYPE :: UF_Surface
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: surface_type = SURF_TYPE_ELEMENT
        INTEGER(i4) :: num_facets = 0
        TYPE(UF_SurfaceFacet), ALLOCATABLE :: facets(:)
        REAL(wp) :: total_area = 0.0_wp
    CONTAINS
        PROCEDURE :: init => surface_init
        PROCEDURE :: add_facet => surface_add_facet
    END TYPE UF_Surface
    
CONTAINS
    !=============================================================================
    !> @brief Initialize node set (legacy interface)
    !! @details Allocates storage for node IDs
    !! @param[inout] this Node set instance
    !! @param[in] name Set name
    !! @param[in] capacity Initial capacity n_cap ? ?(optional, default=1000)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE nodeset_init(this, name, capacity)
        CLASS(UF_NodeSet), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap
        cap = 1000
        IF (PRESENT(capacity)) cap = capacity
        this%name = TRIM(name)
        this%num_nodes = 0
        IF (ALLOCATED(this%node_ids)) DEALLOCATE(this%node_ids)
        ALLOCATE(this%node_ids(cap))
    END SUBROUTINE nodeset_init
    
    !=============================================================================
    !> @brief Add node to set (legacy interface)
    !! @details Appends node ID to set, auto-expands if needed
    !! @param[inout] this Node set instance
    !! @param[in] node_id Node ID n_id ? ? !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE nodeset_add_node(this, node_id)
        CLASS(UF_NodeSet), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_id
        INTEGER(i4), ALLOCATABLE :: temp(:)
        IF (this%num_nodes >= SIZE(this%node_ids)) THEN
            ALLOCATE(temp(SIZE(this%node_ids)*2))
            temp(1:this%num_nodes) = this%node_ids(1:this%num_nodes)
            CALL MOVE_ALLOC(temp, this%node_ids)
        END IF
        this%num_nodes = this%num_nodes + 1
        this%node_ids(this%num_nodes) = node_id
    END SUBROUTINE nodeset_add_node
    
    !=============================================================================
    !> @brief Add node range to set (legacy interface)
    !! @details Adds nodes in range [first, last] with increment incr
    !! Theory: Adds nodes n_i = first + i·incr for i = 0, ..., ?last-first)/incr ? !! @param[inout] this Node set instance
    !! @param[in] first First node ID ? ? !! @param[in] last Last node ID ? ? !! @param[in] incr Increment incr ? ?(optional, default=1)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE nodeset_add_range(this, first, last, incr)
        CLASS(UF_NodeSet), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: first, last
        INTEGER(i4), INTENT(IN), OPTIONAL :: incr
        INTEGER(i4) :: inc, i
        inc = 1
        IF (PRESENT(incr)) inc = incr
        this%is_generate = .TRUE.
        DO i = first, last, inc
            CALL this%add_node(i)
        END DO
    END SUBROUTINE nodeset_add_range
    
    !=============================================================================
    !> @brief Check if set contains node (legacy interface)
    !! @details Searches for node ID in set
    !! @param[in] this Node set instance
    !! @param[in] node_id Node ID n_id ? ?to search for
    !! @return True if node ID found
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    FUNCTION nodeset_contains(this, node_id) RESULT(found)
        CLASS(UF_NodeSet), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node_id
        LOGICAL :: found
        INTEGER(i4) :: i
        found = .FALSE.
        DO i = 1, this%num_nodes
            IF (this%node_ids(i) == node_id) THEN
                found = .TRUE.
                RETURN
            END IF
        END DO
    END FUNCTION nodeset_contains
    
    !=============================================================================
    !> @brief Initialize element set (legacy interface)
    !! @details Allocates storage for element IDs
    !! @param[inout] this Element set instance
    !! @param[in] name Set name
    !! @param[in] capacity Initial capacity n_cap ? ?(optional, default=1000)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE elemset_init(this, name, capacity)
        CLASS(UF_ElemSet), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap
        cap = 1000
        IF (PRESENT(capacity)) cap = capacity
        this%name = TRIM(name)
        this%num_elems = 0
        IF (ALLOCATED(this%elem_ids)) DEALLOCATE(this%elem_ids)
        ALLOCATE(this%elem_ids(cap))
    END SUBROUTINE elemset_init
    
    !=============================================================================
    !> @brief Add element to set (legacy interface)
    !! @details Appends element ID to set, auto-expands if needed
    !! @param[inout] this Element set instance
    !! @param[in] elem_id Element ID e_id ? ? !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE elemset_add_elem(this, elem_id)
        CLASS(UF_ElemSet), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: elem_id
        INTEGER(i4), ALLOCATABLE :: temp(:)
        IF (this%num_elems >= SIZE(this%elem_ids)) THEN
            ALLOCATE(temp(SIZE(this%elem_ids)*2))
            temp(1:this%num_elems) = this%elem_ids(1:this%num_elems)
            CALL MOVE_ALLOC(temp, this%elem_ids)
        END IF
        this%num_elems = this%num_elems + 1
        this%elem_ids(this%num_elems) = elem_id
    END SUBROUTINE elemset_add_elem
    
    !=============================================================================
    !> @brief Add element range to set (legacy interface)
    !! @details Adds elements in range [first, last] with increment incr
    !! Theory: Adds elements e_i = first + i·incr for i = 0, ..., ?last-first)/incr ? !! @param[inout] this Element set instance
    !! @param[in] first First element ID ? ? !! @param[in] last Last element ID ? ? !! @param[in] incr Increment incr ? ?(optional, default=1)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE elemset_add_range(this, first, last, incr)
        CLASS(UF_ElemSet), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: first, last
        INTEGER(i4), INTENT(IN), OPTIONAL :: incr
        INTEGER(i4) :: inc, i
        inc = 1
        IF (PRESENT(incr)) inc = incr
        this%is_generate = .TRUE.
        DO i = first, last, inc
            CALL this%add_elem(i)
        END DO
    END SUBROUTINE elemset_add_range
    
    !=============================================================================
    !> @brief Check if set contains element (legacy interface)
    !! @details Searches for element ID in set
    !! @param[in] this Element set instance
    !! @param[in] elem_id Element ID e_id ? ?to search for
    !! @return True if element ID found
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    FUNCTION elemset_contains(this, elem_id) RESULT(found)
        CLASS(UF_ElemSet), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: elem_id
        LOGICAL :: found
        INTEGER(i4) :: i
        found = .FALSE.
        DO i = 1, this%num_elems
            IF (this%elem_ids(i) == elem_id) THEN
                found = .TRUE.
                RETURN
            END IF
        END DO
    END FUNCTION elemset_contains
    
    !=============================================================================
    !> @brief Initialize surface (legacy interface)
    !! @details Allocates storage for surface facets
    !! @param[inout] this Surface instance
    !! @param[in] name Surface name
    !! @param[in] surf_type Surface type (optional)
    !! @param[in] capacity Initial capacity n_cap ? ?(optional, default=1000)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE surface_init(this, name, surf_type, capacity)
        CLASS(UF_Surface), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN), OPTIONAL :: surf_type, capacity
        INTEGER(i4) :: cap
        cap = 1000
        IF (PRESENT(capacity)) cap = capacity
        this%name = TRIM(name)
        IF (PRESENT(surf_type)) this%surface_type = surf_type
        this%num_facets = 0
        IF (ALLOCATED(this%facets)) DEALLOCATE(this%facets)
        ALLOCATE(this%facets(cap))
    END SUBROUTINE surface_init
    
    !=============================================================================
    !> @brief Add facet to surface (legacy interface)
    !! @details Appends facet (element ID, face ID) to surface, auto-expands if needed
    !! @param[inout] this Surface instance
    !! @param[in] elem_id Element ID e_id ? ? !! @param[in] face_id Face ID f_id ? ? !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE surface_add_facet(this, elem_id, face_id)
        CLASS(UF_Surface), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: elem_id, face_id
        TYPE(UF_SurfaceFacet), ALLOCATABLE :: temp(:)
        IF (this%num_facets >= SIZE(this%facets)) THEN
            ALLOCATE(temp(SIZE(this%facets)*2))
            temp(1:this%num_facets) = this%facets(1:this%num_facets)
            CALL MOVE_ALLOC(temp, this%facets)
        END IF
        this%num_facets = this%num_facets + 1
        this%facets(this%num_facets)%elem_id = elem_id
        this%facets(this%num_facets)%face_id = face_id
    END SUBROUTINE surface_add_facet
END MODULE MD_Sets_Mgr