!===============================================================================
! MODULE:  MD_DOF_Impl
! LAYER:   L3_MD
! DOMAIN:  Mesh / DOF
! ROLE:    _Impl
! BRIEF:   DOF implementation — equation numbering and DOF management.
! **W2**：方程编号与 **DOF 状态枚举** 实现层；与 **`MD_DOF_Mgr`** 编排及单元自由度拓扑对齐。
!===============================================================================

MODULE MD_DOF_Impl
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE
    
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_DOF_PER_NODE = 12
    
    ! DOF types
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_INACTIVE = 0
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_FREE = 1
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_FIXED = 2
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_PRESCRIBED = 3
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_SLAVE = 4      ! MPC dependent
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_LAGRANGE = 5   ! Lagrange multiplier
    
    ! DOF labels (Abaqus compatible)
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_UX = 1         ! X-displacement
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_UY = 2         ! Y-displacement
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_UZ = 3         ! Z-displacement
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_RX = 4         ! X-rotation
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_RY = 5         ! Y-rotation
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_RZ = 6         ! Z-rotation
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_TEMP = 11      ! Temperature
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_PORE = 8       ! Pore pressure
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_DOF_EPOT = 9       ! Electric potential
    
    !--------------------------------------------------------------------------
    ! Nodal DOF Definition
    !--------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_NodalDOF
        INTEGER(i4) :: node_id = 0
        INTEGER(i4) :: num_dof = 0
        INTEGER(i4) :: dof_status(MD_MESH_MAX_DOF_PER_NODE) = MD_MESH_DOF_INACTIVE
        INTEGER(i4) :: eqn_number(MD_MESH_MAX_DOF_PER_NODE) = 0   ! Global equation number
        REAL(wp) :: prescribed_value(MD_MESH_MAX_DOF_PER_NODE) = 0.0_wp
        REAL(wp) :: reaction(MD_MESH_MAX_DOF_PER_NODE) = 0.0_wp
    CONTAINS
        PROCEDURE :: init => ndof_init
        PROCEDURE :: activate => ndof_activate
        PROCEDURE :: fix => ndof_fix
        PROCEDURE :: prescribe => ndof_prescribe
        PROCEDURE :: get_eqn => ndof_get_eqn
        PROCEDURE :: is_free => ndof_is_free
    END TYPE UF_NodalDOF
    
    !--------------------------------------------------------------------------
    ! DOF Manager
    !--------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_DOFManagerType
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4) :: num_total_dof = 0
        INTEGER(i4) :: num_free_dof = 0
        INTEGER(i4) :: num_fixed_dof = 0
        INTEGER(i4) :: num_prescribed_dof = 0
        TYPE(UF_NodalDOF), ALLOCATABLE :: nodal_dofs(:)
        ! Mapping arrays
        INTEGER(i4), ALLOCATABLE :: dof_to_node(:)   ! eqn -> node
        INTEGER(i4), ALLOCATABLE :: dof_to_local(:)  ! eqn -> local dof
        ! Solution vectors (references)
        REAL(wp), ALLOCATABLE :: displacement(:)
        REAL(wp), ALLOCATABLE :: velocity(:)
        REAL(wp), ALLOCATABLE :: acceleration(:)
    CONTAINS
        PROCEDURE :: init => dofmgr_init
        PROCEDURE :: activate_dofs => dofmgr_activate_dofs
        PROCEDURE :: fix_dof => dofmgr_fix_dof
        PROCEDURE :: prescribe_dof => dofmgr_prescribe_dof
        PROCEDURE :: number_equations => dofmgr_number_eqns
        PROCEDURE :: get_nodal_dof => dofmgr_get_nodal
        PROCEDURE :: get_element_dofs => dofmgr_get_elem_dofs
        PROCEDURE :: assemble_vector => dofmgr_assemble_vec
        PROCEDURE :: scatter_solution => dofmgr_scatter
        PROCEDURE :: print_summary => dofmgr_print_summary
        PROCEDURE :: destroy => dofmgr_destroy
    END TYPE UF_DOFManagerType
    
CONTAINS

    !--------------------------------------------------------------------------
    ! Nodal DOF Methods
    !--------------------------------------------------------------------------
    SUBROUTINE ndof_init(this, node_id, ndof)
        CLASS(UF_NodalDOF), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_id, ndof
        this%node_id = node_id
        this%num_dof = ndof
        this%dof_status = MD_MESH_DOF_INACTIVE
        this%dof_status(1:ndof) = MD_MESH_DOF_FREE
        this%eqn_number = 0
        this%prescribed_value = 0.0_wp
    END SUBROUTINE ndof_init
    
    SUBROUTINE ndof_activate(this, dof)
        CLASS(UF_NodalDOF), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: dof
        IF (dof >= 1 .AND. dof <= MD_MESH_MAX_DOF_PER_NODE) THEN
            IF (this%dof_status(dof) == MD_MESH_DOF_INACTIVE) THEN
                this%dof_status(dof) = MD_MESH_DOF_FREE
                this%num_dof = MAX(this%num_dof, dof)
            END IF
        END IF
    END SUBROUTINE ndof_activate
    
    SUBROUTINE ndof_fix(this, dof)
        CLASS(UF_NodalDOF), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: dof
        IF (dof >= 1 .AND. dof <= MD_MESH_MAX_DOF_PER_NODE) THEN
            this%dof_status(dof) = MD_MESH_DOF_FIXED
            this%prescribed_value(dof) = 0.0_wp
        END IF
    END SUBROUTINE ndof_fix
    
    SUBROUTINE ndof_prescribe(this, dof, value)
        CLASS(UF_NodalDOF), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: dof
        REAL(wp), INTENT(IN) :: value
        IF (dof >= 1 .AND. dof <= MD_MESH_MAX_DOF_PER_NODE) THEN
            this%dof_status(dof) = MD_MESH_DOF_PRESCRIBED
            this%prescribed_value(dof) = value
        END IF
    END SUBROUTINE ndof_prescribe
    
    FUNCTION ndof_get_eqn(this, dof) RESULT(eqn)
        CLASS(UF_NodalDOF), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: dof
        INTEGER(i4) :: eqn
        eqn = 0
        IF (dof >= 1 .AND. dof <= MD_MESH_MAX_DOF_PER_NODE) eqn = this%eqn_number(dof)
    END FUNCTION ndof_get_eqn
    
    FUNCTION ndof_is_free(this, dof) RESULT(is_free)
        CLASS(UF_NodalDOF), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: dof
        LOGICAL :: is_free
        is_free = .FALSE.
        IF (dof >= 1 .AND. dof <= MD_MESH_MAX_DOF_PER_NODE) THEN
            is_free = (this%dof_status(dof) == MD_MESH_DOF_FREE)
        END IF
    END FUNCTION ndof_is_free

    !--------------------------------------------------------------------------
    ! DOF Manager Methods
    !--------------------------------------------------------------------------
    SUBROUTINE dofmgr_init(this, nnodes, dof_per_node)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nnodes, dof_per_node
        INTEGER(i4) :: i
        this%num_nodes = nnodes
        ALLOCATE(this%nodal_dofs(nnodes))
        DO i = 1, nnodes
            CALL this%nodal_dofs(i)%init(i, dof_per_node)
        END DO
    END SUBROUTINE dofmgr_init
    
    SUBROUTINE dofmgr_activate_dofs(this, node_ids, dofs)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_ids(:), dofs(:)
        INTEGER(i4) :: i, j, nid
        DO i = 1, SIZE(node_ids)
            nid = node_ids(i)
            IF (nid >= 1 .AND. nid <= this%num_nodes) THEN
                DO j = 1, SIZE(dofs)
                    CALL this%nodal_dofs(nid)%activate(dofs(j))
                END DO
            END IF
        END DO
    END SUBROUTINE dofmgr_activate_dofs
    
    SUBROUTINE dofmgr_fix_dof(this, node_id, dof)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_id, dof
        IF (node_id >= 1 .AND. node_id <= this%num_nodes) THEN
            CALL this%nodal_dofs(node_id)%fix(dof)
        END IF
    END SUBROUTINE dofmgr_fix_dof
    
    SUBROUTINE dofmgr_prescribe_dof(this, node_id, dof, value)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_id, dof
        REAL(wp), INTENT(IN) :: value
        IF (node_id >= 1 .AND. node_id <= this%num_nodes) THEN
            CALL this%nodal_dofs(node_id)%prescribe(dof, value)
        END IF
    END SUBROUTINE dofmgr_prescribe_dof
    
    SUBROUTINE dofmgr_number_eqns(this)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        INTEGER(i4) :: i, j, eqn_count

        eqn_count = 0
        this%num_free_dof       = 0
        this%num_fixed_dof      = 0
        this%num_prescribed_dof = 0

        ! Reset all equation numbers to zero so that non-free DOFs have eqn=0
        DO i = 1, this%num_nodes
            DO j = 1, this%nodal_dofs(i)%num_dof
                this%nodal_dofs(i)%eqn_number(j) = 0
            END DO
        END DO

        ! Number free DOFs first
        DO i = 1, this%num_nodes
            DO j = 1, this%nodal_dofs(i)%num_dof
                IF (this%nodal_dofs(i)%dof_status(j) == MD_MESH_DOF_FREE) THEN
                    eqn_count = eqn_count + 1
                    this%nodal_dofs(i)%eqn_number(j) = eqn_count
                    this%num_free_dof = this%num_free_dof + 1
                END IF
            END DO
        END DO

        ! Count fixed and prescribed
        DO i = 1, this%num_nodes
            DO j = 1, this%nodal_dofs(i)%num_dof
                SELECT CASE(this%nodal_dofs(i)%dof_status(j))
                    CASE(MD_MESH_DOF_FIXED)
                        this%num_fixed_dof = this%num_fixed_dof + 1
                    CASE(MD_MESH_DOF_PRESCRIBED)
                        this%num_prescribed_dof = this%num_prescribed_dof + 1
                END SELECT
            END DO
        END DO

        this%num_total_dof = eqn_count

        ! Rebuild mapping and solution arrays (safe for repeated calls)
        IF (ALLOCATED(this%dof_to_node)) DEALLOCATE(this%dof_to_node)
        IF (ALLOCATED(this%dof_to_local)) DEALLOCATE(this%dof_to_local)
        IF (ALLOCATED(this%displacement)) DEALLOCATE(this%displacement)

        IF (eqn_count > 0) THEN
            ALLOCATE(this%dof_to_node(eqn_count), this%dof_to_local(eqn_count))
            ALLOCATE(this%displacement(eqn_count))
            this%displacement = 0.0_wp

            DO i = 1, this%num_nodes
                DO j = 1, this%nodal_dofs(i)%num_dof
                    IF (this%nodal_dofs(i)%eqn_number(j) > 0) THEN
                        eqn_count = this%nodal_dofs(i)%eqn_number(j)
                        this%dof_to_node(eqn_count)  = i
                        this%dof_to_local(eqn_count) = j
                    END IF
                END DO
            END DO
        END IF
    END SUBROUTINE dofmgr_number_eqns
    
    FUNCTION dofmgr_get_nodal(this, node_id) RESULT(ptr)
        CLASS(UF_DOFManagerType), INTENT(IN), TARGET :: this
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(UF_NodalDOF), POINTER :: ptr
        ptr => NULL()
        IF (node_id >= 1 .AND. node_id <= this%num_nodes) THEN
            ptr => this%nodal_dofs(node_id)
        END IF
    END FUNCTION dofmgr_get_nodal
    
    SUBROUTINE dofmgr_get_elem_dofs(this, node_ids, elem_dofs, ndof)
        CLASS(UF_DOFManagerType), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node_ids(:)
        INTEGER(i4), INTENT(OUT) :: elem_dofs(:)
        INTEGER(i4), INTENT(OUT) :: ndof
        INTEGER(i4) :: i, j, k, nid
        ndof = 0
        DO i = 1, SIZE(node_ids)
            nid = node_ids(i)
            IF (nid >= 1 .AND. nid <= this%num_nodes) THEN
                DO j = 1, this%nodal_dofs(nid)%num_dof
                    ndof = ndof + 1
                    IF (ndof <= SIZE(elem_dofs)) THEN
                        elem_dofs(ndof) = this%nodal_dofs(nid)%eqn_number(j)
                    END IF
                END DO
            END IF
        END DO
    END SUBROUTINE dofmgr_get_elem_dofs
    
    SUBROUTINE dofmgr_assemble_vec(this, elem_dofs, elem_vec, global_vec)
        CLASS(UF_DOFManagerType), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: elem_dofs(:)
        REAL(wp), INTENT(IN) :: elem_vec(:)
        REAL(wp), INTENT(INOUT) :: global_vec(:)
        INTEGER(i4) :: i, eq
        DO i = 1, SIZE(elem_dofs)
            eq = elem_dofs(i)
            IF (eq > 0 .AND. eq <= SIZE(global_vec)) THEN
                global_vec(eq) = global_vec(eq) + elem_vec(i)
            END IF
        END DO
    END SUBROUTINE dofmgr_assemble_vec
    
    SUBROUTINE dofmgr_scatter(this, solution)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: solution(:)
        this%displacement = solution
    END SUBROUTINE dofmgr_scatter
    
    SUBROUTINE dofmgr_print_summary(this, unit_num)
        CLASS(UF_DOFManagerType), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A)') '=== DOF Summary ==='
        WRITE(unit_num, '(A,I8)') '  Total nodes:      ', this%num_nodes
        WRITE(unit_num, '(A,I8)') '  Free DOFs:        ', this%num_free_dof
        WRITE(unit_num, '(A,I8)') '  Fixed DOFs:       ', this%num_fixed_dof
        WRITE(unit_num, '(A,I8)') '  Prescribed DOFs:  ', this%num_prescribed_dof
        WRITE(unit_num, '(A,I8)') '  Total equations:  ', this%num_total_dof
    END SUBROUTINE dofmgr_print_summary
    
    SUBROUTINE dofmgr_destroy(this)
        CLASS(UF_DOFManagerType), INTENT(INOUT) :: this
        IF (ALLOCATED(this%nodal_dofs)) DEALLOCATE(this%nodal_dofs)
        IF (ALLOCATED(this%dof_to_node)) DEALLOCATE(this%dof_to_node)
        IF (ALLOCATED(this%dof_to_local)) DEALLOCATE(this%dof_to_local)
        IF (ALLOCATED(this%displacement)) DEALLOCATE(this%displacement)
        IF (ALLOCATED(this%velocity)) DEALLOCATE(this%velocity)
        IF (ALLOCATED(this%acceleration)) DEALLOCATE(this%acceleration)
    END SUBROUTINE dofmgr_destroy

END MODULE MD_DOF_Impl