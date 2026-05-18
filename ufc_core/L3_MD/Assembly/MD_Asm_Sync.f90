!===============================================================================
! MODULE:  MD_Asm_Sync
! LAYER:   L3_MD
! DOMAIN:  Assembly
! ROLE:    _Sync
! BRIEF:   Legacy UF assembly types + SyncFromLegacy mapper.
!          UF_AssemblyDef -> MD_Assembly_Domain synchronization.
! Pilot:   ufc-layer-l3-l4-l5-pilot.md — 本域以 **MD_Assembly_Domain** 为 L3 金线（半柱
!          H3）；同步子程序体 DRY，不改 UF→MD 语义。
!===============================================================================

MODULE MD_Asm_Sync

    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, &
                          IF_STATUS_MEM_ERROR
    USE MD_Asm_Inst, ONLY: UF_InstanceDef, MAX_INSTANCE_NAME
    USE MD_Part_Mgr, ONLY: UF_PartDef, UF_Node, UF_Element
    USE MD_Sets_Mgr, ONLY: UF_NodeSet, UF_ElemSet, UF_Surface, MAX_SET_NAME
    USE MD_Constr_Def, ONLY: CONSTRAINT_TIE, CONSTRAINT_COUPLING, CONSTRAINT_MPC, CONSTRAINT_RIGID
    USE MD_Asm_Mgr, ONLY: MD_Assembly_Domain, MD_Instance_Desc, &
                                 MD_SetDef, MD_SurfaceDef, MD_ConstraintDef
    USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
    IMPLICIT NONE
    
    PRIVATE
    ! Re-export MD_Constr_Def enumerators (UF_Constraint%constraint_type uses legacy 1-4 in mapper)
    PUBLIC :: CONSTRAINT_TIE, CONSTRAINT_COUPLING, CONSTRAINT_MPC, CONSTRAINT_RIGID
    PUBLIC :: UF_AssemblyDef, MAX_ASSEMBLY_NAME
    PUBLIC :: MD_Assembly_AddInstance_Arg
    PUBLIC :: MD_Asm_GetInstance_Arg
    PUBLIC :: MD_Asm_GetSummary_Arg
    PUBLIC :: MD_Assembly_SyncFromLegacy
    PUBLIC :: MD_Assembly_MirrorUFConstraintToDomain
    
    !---------------------------------------------------------------------------
    ! TYPE:  MD_Assembly_AddInstance_Arg
    ! KIND:  Arg
    ! DESC:  Arg bundle for AddInstance
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Assembly_AddInstance_Arg
      TYPE(UF_InstanceDef)  :: inst          ! [in]  instance to add
      INTEGER(i4)           :: inst_idx = 0_i4 ! [out] assigned 1-based index
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Assembly_AddInstance_Arg

    !---------------------------------------------------------------------------
    ! TYPE:  MD_Asm_GetInstance_Arg
    ! KIND:  Arg
    ! DESC:  Arg bundle for GetInstance (read by index)
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Asm_GetInstance_Arg
      TYPE(UF_InstanceDef)  :: inst          ! [out] instance descriptor
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Asm_GetInstance_Arg

    !---------------------------------------------------------------------------
    ! TYPE:  MD_Asm_GetSummary_Arg
    ! KIND:  Arg
    ! DESC:  Arg bundle for GetSummary
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Asm_GetSummary_Arg
      CHARACTER(LEN=512)    :: summary = ""  ! [out]
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Asm_GetSummary_Arg

    INTEGER(i4), PARAMETER :: MD_ASM_MAX_ASSEMBLY_NAME = 80_i4
    INTEGER(i4), PARAMETER :: MAX_ASSEMBLY_NAME = MD_ASM_MAX_ASSEMBLY_NAME
    INTEGER(i4), PARAMETER :: MAX_INSTANCES = 10000_i4
    INTEGER(i4), PARAMETER :: MAX_ASSEMBLY_SETS = 5000_i4
    ! UF_Constraint%constraint_type simplified codes (mapper → UF_Constraint_To_MD_ConstraintDef)
    INTEGER(i4), PARAMETER :: UF_CST_LEGACY_TIE = 1_i4
    INTEGER(i4), PARAMETER :: UF_CST_LEGACY_COUPLING = 2_i4
    INTEGER(i4), PARAMETER :: UF_CST_LEGACY_MPC = 3_i4
    INTEGER(i4), PARAMETER :: UF_CST_LEGACY_RIGID = 4_i4

    ! ==========================================================================
    ! UF_Constraint%constraint_type legacy codes (L6 / command payload; not MD_Constr_Def)
    ! ==========================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_RIGID_BODY = 4_i4
    ! Phase B Tier 1: Advanced constraint types (ABAQUS 2020 alignment)
    INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_EMBEDDED = 5_i4
    INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_TRANSFORM = 6_i4
    INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_CLEARANCE = 7_i4
    INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_SHELL_SOLID_COUPLING = 8_i4
    INTEGER(i4), PARAMETER, PUBLIC :: CONSTRAINT_CYCLIC_SYMMETRY = 9_i4
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_Constraint
    ! KIND:  Desc
    ! DESC:  Legacy constraint descriptor for assembly-level constraints
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_Constraint
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: constraint_type = 0
        ! For TIE constraint
        CHARACTER(LEN=MAX_SET_NAME) :: master_surface = ""
        CHARACTER(LEN=MAX_SET_NAME) :: slave_surface = ""
        REAL(wp) :: position_tolerance = 0.0_wp
        ! For MPC constraint
        INTEGER(i4) :: num_terms = 0                    ! n_terms
        INTEGER(i4), ALLOCATABLE :: mpc_nodes(:)
        INTEGER(i4), ALLOCATABLE :: mpc_dofs(:)
        REAL(wp), ALLOCATABLE :: mpc_coeffs(:)          ! Coefficients
        ! L6_AP command payload (optional); not consumed by MD_ConstraintDef mirror
        INTEGER(i4) :: n_properties = 0_i4
        REAL(wp), ALLOCATABLE :: properties(:)
    END TYPE UF_Constraint
    
    !---------------------------------------------------------------------------
    ! TYPE:  UF_AssemblyDef
    ! KIND:  Desc
    ! DESC:  Legacy assembly definition — instances, sets, constraints, globals
    !---------------------------------------------------------------------------
    TYPE :: UF_AssemblyDef
        CHARACTER(LEN=MAX_ASSEMBLY_NAME) :: name = ""
        
        ! Instances
        INTEGER(i4) :: num_instances = 0                ! n_instances
        TYPE(UF_InstanceDef), ALLOCATABLE :: instances(:)
        
        ! Assembly-level sets (reference instance.set_name)
        INTEGER(i4) :: num_node_sets = 0               ! n_node_sets
        INTEGER(i4) :: num_elem_sets = 0               ! n_elem_sets
        INTEGER(i4) :: num_surfaces = 0                ! n_surfaces
        TYPE(UF_NodeSet), ALLOCATABLE :: node_sets(:)
        TYPE(UF_ElemSet), ALLOCATABLE :: elem_sets(:)
        TYPE(UF_Surface), ALLOCATABLE :: surfaces(:)
        
        ! Constraints (TIE, MPC, etc.)
        INTEGER(i4) :: num_constraints = 0              ! n_constraints
        TYPE(UF_Constraint), ALLOCATABLE :: constraints(:)
        
        ! Global counts (after assembly)
        INTEGER(i4) :: total_nodes = 0                  ! n_nodes
        INTEGER(i4) :: total_elements = 0               ! n_elems
        INTEGER(i4) :: total_dofs = 0                   ! n_dofs
        
        ! Global coordinate arrays (flattened from instances)
        REAL(wp), ALLOCATABLE :: global_coords(:,:)    ! X in R^(3 x n_nodes)
        INTEGER(i4), ALLOCATABLE :: global_conn(:,:)   ! conn in Z^(max_npe x n_elems)
        INTEGER(i4), ALLOCATABLE :: global_elem_type(:)! Element types
        
    CONTAINS
        PROCEDURE :: init => assembly_init
        PROCEDURE :: add_instance => assembly_add_instance
        PROCEDURE :: add_node_set => assembly_add_node_set
        PROCEDURE :: add_elem_set => assembly_add_elem_set
        PROCEDURE :: add_surface => assembly_add_surface
        PROCEDURE :: add_constraint => assembly_add_constraint
        PROCEDURE :: find_instance => assembly_find_instance
        PROCEDURE :: get_instance  => assembly_get_instance
        PROCEDURE :: find_node_set => assembly_find_node_set
        PROCEDURE :: assemble => assembly_assemble
        PROCEDURE :: append_instance_sets => assembly_append_instance_sets
        PROCEDURE :: get_node_coords => assembly_get_node_coords
        PROCEDURE :: release_global_arrays => assembly_release_global_arrays
        PROCEDURE :: clear => assembly_clear
        PROCEDURE :: get_summary => assembly_get_summary
    END TYPE UF_AssemblyDef

CONTAINS
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_init
    ! PHASE:      Init
    ! PURPOSE:    Initialize assembly with optional name; allocate arrays
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_init(this, name, ierr)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: astat

        IF (PRESENT(ierr)) ierr = 0_i4

        IF (PRESENT(name)) THEN
            this%name = TRIM(name)
        ELSE
            this%name = "Assembly-1"
        END IF

        this%num_instances = 0
        this%num_node_sets = 0
        this%num_elem_sets = 0
        this%num_surfaces = 0
        this%num_constraints = 0

        this%total_nodes = 0
        this%total_elements = 0
        this%total_dofs = 0

        IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
        IF (ALLOCATED(this%node_sets)) DEALLOCATE(this%node_sets)
        IF (ALLOCATED(this%elem_sets)) DEALLOCATE(this%elem_sets)
        IF (ALLOCATED(this%surfaces)) DEALLOCATE(this%surfaces)
        IF (ALLOCATED(this%constraints)) DEALLOCATE(this%constraints)

        ALLOCATE(this%instances(MAX_INSTANCES), stat=astat)
        IF (astat /= 0) GOTO 10
        ALLOCATE(this%node_sets(MAX_ASSEMBLY_SETS), stat=astat)
        IF (astat /= 0) GOTO 10
        ALLOCATE(this%elem_sets(MAX_ASSEMBLY_SETS), stat=astat)
        IF (astat /= 0) GOTO 10
        ALLOCATE(this%surfaces(MAX_ASSEMBLY_SETS), stat=astat)
        IF (astat /= 0) GOTO 10
        ALLOCATE(this%constraints(1000), stat=astat)
        IF (astat /= 0) GOTO 10
        RETURN

10      CONTINUE
        IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
        IF (ALLOCATED(this%node_sets)) DEALLOCATE(this%node_sets)
        IF (ALLOCATED(this%elem_sets)) DEALLOCATE(this%elem_sets)
        IF (ALLOCATED(this%surfaces)) DEALLOCATE(this%surfaces)
        IF (ALLOCATED(this%constraints)) DEALLOCATE(this%constraints)
        IF (PRESENT(ierr)) ierr = IF_STATUS_MEM_ERROR

    END SUBROUTINE assembly_init
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_add_instance
    ! PHASE:      Mutate
    ! PURPOSE:    Append instance to assembly; auto-assign sequential ID
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_add_instance(this, inst)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_InstanceDef), INTENT(IN) :: inst

        IF (.NOT. ALLOCATED(this%instances)) RETURN
        IF (this%num_instances >= SIZE(this%instances)) RETURN
        
        this%num_instances = this%num_instances + 1
        this%instances(this%num_instances) = inst
        this%instances(this%num_instances)%cfg%id = this%num_instances
        
    END SUBROUTINE assembly_add_instance
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_add_node_set
    ! PHASE:      Mutate
    ! PURPOSE:    Append assembly-level node set
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_add_node_set(this, nset)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_NodeSet), INTENT(IN) :: nset

        IF (.NOT. ALLOCATED(this%node_sets)) RETURN
        IF (this%num_node_sets >= SIZE(this%node_sets)) RETURN
        
        this%num_node_sets = this%num_node_sets + 1
        this%node_sets(this%num_node_sets) = nset
        
    END SUBROUTINE assembly_add_node_set
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_add_elem_set
    ! PHASE:      Mutate
    ! PURPOSE:    Append assembly-level element set
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_add_elem_set(this, eset)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_ElemSet), INTENT(IN) :: eset

        IF (.NOT. ALLOCATED(this%elem_sets)) RETURN
        IF (this%num_elem_sets >= SIZE(this%elem_sets)) RETURN
        
        this%num_elem_sets = this%num_elem_sets + 1
        this%elem_sets(this%num_elem_sets) = eset
        
    END SUBROUTINE assembly_add_elem_set
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_add_surface
    ! PHASE:      Mutate
    ! PURPOSE:    Append assembly-level surface definition
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_add_surface(this, surf)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_Surface), INTENT(IN) :: surf

        IF (.NOT. ALLOCATED(this%surfaces)) RETURN
        IF (this%num_surfaces >= SIZE(this%surfaces)) RETURN
        
        this%num_surfaces = this%num_surfaces + 1
        this%surfaces(this%num_surfaces) = surf
        
    END SUBROUTINE assembly_add_surface
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_add_constraint
    ! PHASE:      Mutate
    ! PURPOSE:    Append constraint to assembly
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_add_constraint(this, constr)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_Constraint), INTENT(IN) :: constr

        IF (.NOT. ALLOCATED(this%constraints)) RETURN
        IF (this%num_constraints >= SIZE(this%constraints)) RETURN
        
        this%num_constraints = this%num_constraints + 1
        this%constraints(this%num_constraints) = constr
        
    END SUBROUTINE assembly_add_constraint
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   assembly_find_instance
    ! PHASE:      Query
    ! PURPOSE:    Find instance index by name; returns -1 if not found
    !---------------------------------------------------------------------------
    FUNCTION assembly_find_instance(this, name) RESULT(idx)
        CLASS(UF_AssemblyDef), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx
        INTEGER(i4) :: i

        idx = -1
        IF (.NOT. ALLOCATED(this%instances)) RETURN
        DO i = 1, this%num_instances
            IF (TRIM(this%instances(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO
        
    END FUNCTION assembly_find_instance
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   assembly_get_instance
    ! PHASE:      Query
    ! PURPOSE:    Get instance pointer by name; returns NULL if not found
    !---------------------------------------------------------------------------
    FUNCTION assembly_get_instance(this, name) RESULT(inst_ptr)
        CLASS(UF_AssemblyDef), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_InstanceDef), POINTER :: inst_ptr
        INTEGER(i4) :: idx
        
        NULLIFY(inst_ptr)
        idx = this%find_instance(name)
        IF (idx > 0) THEN
            inst_ptr => this%instances(idx)
        END IF
    END FUNCTION assembly_get_instance

    !---------------------------------------------------------------------------
    ! FUNCTION:   assembly_find_node_set
    ! PHASE:      Query
    ! PURPOSE:    Find node set index by name; returns -1 if not found
    !---------------------------------------------------------------------------
    FUNCTION assembly_find_node_set(this, name) RESULT(idx)
        CLASS(UF_AssemblyDef), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx
        INTEGER(i4) :: i

        idx = -1
        IF (.NOT. ALLOCATED(this%node_sets)) RETURN
        DO i = 1, this%num_node_sets
            IF (TRIM(this%node_sets(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION assembly_find_node_set

    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_assemble
    ! PHASE:      Compute
    ! PURPOSE:    Compute global numbering and flatten geometry from parts
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_assemble(this, parts, num_parts, dof_per_node)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_PartDef), INTENT(IN), TARGET :: parts(:)
        INTEGER(i4), INTENT(IN) :: num_parts
        INTEGER(i4), INTENT(IN), OPTIONAL :: dof_per_node

        INTEGER(i4) :: i, j, k, p, inst_idx
        INTEGER(i4) :: local_node_label, local_node_idx
        INTEGER(i4) :: local_elem_label, local_elem_idx
        INTEGER(i4) :: node_count, elem_count, dof_count
        INTEGER(i4) :: ndof
        INTEGER(i4) :: astat
        TYPE(UF_PartDef), POINTER :: part_ptr
        
        ndof = 3
        IF (PRESENT(dof_per_node)) ndof = dof_per_node

        IF (.NOT. ALLOCATED(this%instances)) RETURN

        this%num_node_sets = 0
        this%num_elem_sets = 0
        this%num_surfaces = 0
        
        ! First pass: count totals and assign offsets
        node_count = 0
        elem_count = 0
        dof_count = 0
        
        DO i = 1, this%num_instances
            ! Find the part
            NULLIFY(part_ptr)
            DO p = 1, num_parts
                IF (TRIM(parts(p)%name) == TRIM(this%instances(i)%part_name)) THEN
                    part_ptr => parts(p)
                    EXIT
                END IF
            END DO
            
            IF (.NOT. ASSOCIATED(part_ptr)) CYCLE
            
            this%instances(i)%part_id     = part_ptr%cfg%id
            this%instances(i)%node_offset = node_count
            this%instances(i)%elem_offset = elem_count
            this%instances(i)%dof_offset = dof_count

            CALL assembly_append_instance_sets(this, this%instances(i), part_ptr)
            
            node_count = node_count + part_ptr%num_nodes
            elem_count = elem_count + part_ptr%num_elements
            dof_count = dof_count + part_ptr%num_nodes * ndof
        END DO
        
        this%total_nodes = node_count
        this%total_elements = elem_count
        this%total_dofs = dof_count
        
        ! Allocate global arrays
        IF (ALLOCATED(this%global_coords)) DEALLOCATE(this%global_coords)
        IF (ALLOCATED(this%global_conn)) DEALLOCATE(this%global_conn)
        IF (ALLOCATED(this%global_elem_type)) DEALLOCATE(this%global_elem_type)
        
        IF (this%total_nodes > 0) THEN
            ALLOCATE(this%global_coords(3, this%total_nodes), stat=astat)
            IF (astat /= 0) THEN
              IF (ALLOCATED(this%global_coords)) DEALLOCATE(this%global_coords)
              this%total_nodes = 0; this%total_elements = 0; this%total_dofs = 0
              RETURN
            END IF
            this%global_coords = 0.0_wp
        END IF

        IF (this%total_elements > 0) THEN
            ALLOCATE(this%global_conn(27, this%total_elements), stat=astat)  ! Max 27 nodes/elem
            IF (astat /= 0) THEN
              IF (ALLOCATED(this%global_coords)) DEALLOCATE(this%global_coords)
              IF (ALLOCATED(this%global_conn)) DEALLOCATE(this%global_conn)
              this%total_nodes = 0; this%total_elements = 0; this%total_dofs = 0
              RETURN
            END IF
            ALLOCATE(this%global_elem_type(this%total_elements), stat=astat)
            IF (astat /= 0) THEN
              IF (ALLOCATED(this%global_coords)) DEALLOCATE(this%global_coords)
              IF (ALLOCATED(this%global_conn)) DEALLOCATE(this%global_conn)
              IF (ALLOCATED(this%global_elem_type)) DEALLOCATE(this%global_elem_type)
              this%total_nodes = 0; this%total_elements = 0; this%total_dofs = 0
              RETURN
            END IF
            this%global_conn = 0
            this%global_elem_type = 0
        END IF

        ! Second pass: fill global arrays
        DO i = 1, this%num_instances
            NULLIFY(part_ptr)
            DO p = 1, num_parts
                IF (parts(p)%cfg%id == this%instances(i)%part_id) THEN
                    part_ptr => parts(p)
                    EXIT
                END IF
            END DO
            IF (.NOT. ASSOCIATED(part_ptr)) CYCLE
            
            ! Copy node coordinates (transformed)
            DO j = 1, part_ptr%num_nodes
                k = this%instances(i)%node_offset + j
                this%global_coords(:, k) = this%instances(i)%transform_point( &
                    part_ptr%nodes(j)%coords)
            END DO
            
            ! Copy element connectivity (with offset)
            DO j = 1, part_ptr%num_elements
                k = this%instances(i)%elem_offset + j
                this%global_elem_type(k) = part_ptr%elements(j)%elem_type
                DO inst_idx = 1, part_ptr%elements(j)%num_nodes
                    local_node_label = part_ptr%elements(j)%connectivity(inst_idx)
                    local_node_idx = part_node_index(part_ptr, local_node_label)
                    IF (local_node_idx > 0) THEN
                        this%global_conn(inst_idx, k) = local_node_idx + this%instances(i)%node_offset
                    END IF
                END DO
            END DO
        END DO
        
    END SUBROUTINE assembly_assemble

    SUBROUTINE assembly_append_instance_sets(this, inst, part_ptr)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        TYPE(UF_InstanceDef),  INTENT(IN)    :: inst
        TYPE(UF_PartDef),      INTENT(IN)    :: part_ptr

        TYPE(UF_NodeSet) :: nset
        TYPE(UF_ElemSet) :: eset
        TYPE(UF_Surface) :: surf
        INTEGER(i4) :: i, j, local_idx, global_idx
        CHARACTER(LEN=MAX_SET_NAME) :: full_name

        DO i = 1, part_ptr%num_node_sets
            full_name = TRIM(inst%name)//"."//TRIM(part_ptr%node_sets(i)%name)
            CALL nset%init(full_name, part_ptr%node_sets(i)%num_nodes)
            DO j = 1, part_ptr%node_sets(i)%num_nodes
                local_idx = part_node_index(part_ptr, part_ptr%node_sets(i)%node_ids(j))
                IF (local_idx > 0) THEN
                    global_idx = inst%node_offset + local_idx
                    CALL nset%add_node(global_idx)
                END IF
            END DO
            CALL this%add_node_set(nset)
        END DO

        DO i = 1, part_ptr%num_elem_sets
            full_name = TRIM(inst%name)//"."//TRIM(part_ptr%elem_sets(i)%name)
            CALL eset%init(full_name, part_ptr%elem_sets(i)%num_elems)
            DO j = 1, part_ptr%elem_sets(i)%num_elems
                local_idx = part_elem_index(part_ptr, part_ptr%elem_sets(i)%elem_ids(j))
                IF (local_idx > 0) THEN
                    global_idx = inst%elem_offset + local_idx
                    CALL eset%add_elem(global_idx)
                END IF
            END DO
            CALL this%add_elem_set(eset)
        END DO

        DO i = 1, part_ptr%num_surfaces
            full_name = TRIM(inst%name)//"."//TRIM(part_ptr%surfaces(i)%name)
            CALL surf%init(full_name, part_ptr%surfaces(i)%surface_type, part_ptr%surfaces(i)%num_facets)
            DO j = 1, part_ptr%surfaces(i)%num_facets
                local_idx = part_elem_index(part_ptr, part_ptr%surfaces(i)%facets(j)%elem_id)
                IF (local_idx > 0) THEN
                    global_idx = inst%elem_offset + local_idx
                    CALL surf%add_facet(global_idx, part_ptr%surfaces(i)%facets(j)%face_id)
                END IF
            END DO
            CALL this%add_surface(surf)
        END DO
    END SUBROUTINE assembly_append_instance_sets

    INTEGER(i4) FUNCTION part_node_index(part_ptr, node_id) RESULT(idx)
        TYPE(UF_PartDef), INTENT(IN) :: part_ptr
        INTEGER(i4),      INTENT(IN) :: node_id
        INTEGER(i4) :: i

        idx = 0
        DO i = 1, part_ptr%num_nodes
            IF (part_ptr%nodes(i)%cfg%id == node_id) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION part_node_index

    INTEGER(i4) FUNCTION part_elem_index(part_ptr, elem_id) RESULT(idx)
        TYPE(UF_PartDef), INTENT(IN) :: part_ptr
        INTEGER(i4),      INTENT(IN) :: elem_id
        INTEGER(i4) :: i

        idx = 0
        DO i = 1, part_ptr%num_elements
            IF (part_ptr%elements(i)%cfg%id == elem_id) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION part_elem_index
    
    !---------------------------------------------------------------------------
    ! FUNCTION:   assembly_get_node_coords
    ! PHASE:      Query
    ! PURPOSE:    Get node coordinates by global ID from flattened array
    !---------------------------------------------------------------------------
    FUNCTION assembly_get_node_coords(this, global_node_id) RESULT(coords)
        CLASS(UF_AssemblyDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: global_node_id
        REAL(wp) :: coords(3)
        
        coords = 0.0_wp
        IF (global_node_id < 1 .OR. global_node_id > this%total_nodes) RETURN
        IF (.NOT. ALLOCATED(this%global_coords)) RETURN
        
        coords = this%global_coords(:, global_node_id)
        
    END FUNCTION assembly_get_node_coords
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_release_global_arrays
    ! PHASE:      Finalize
    ! PURPOSE:    Release flattened coordinate/connectivity arrays
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_release_global_arrays(this)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        IF (ALLOCATED(this%global_coords)) DEALLOCATE(this%global_coords)
        IF (ALLOCATED(this%global_conn)) DEALLOCATE(this%global_conn)
        IF (ALLOCATED(this%global_elem_type)) DEALLOCATE(this%global_elem_type)
    END SUBROUTINE assembly_release_global_arrays
    
    !---------------------------------------------------------------------------
    ! SUBROUTINE: assembly_clear
    ! PHASE:      Finalize
    ! PURPOSE:    Clear all assembly data and release arrays
    !---------------------------------------------------------------------------
    SUBROUTINE assembly_clear(this)
        CLASS(UF_AssemblyDef), INTENT(INOUT) :: this
        
        this%num_instances = 0
        this%num_node_sets = 0
        this%num_elem_sets = 0
        this%num_surfaces = 0
        this%num_constraints = 0
        this%total_nodes = 0
        this%total_elements = 0
        this%total_dofs = 0
        
        IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
        IF (ALLOCATED(this%node_sets)) DEALLOCATE(this%node_sets)
        IF (ALLOCATED(this%elem_sets)) DEALLOCATE(this%elem_sets)
        IF (ALLOCATED(this%surfaces)) DEALLOCATE(this%surfaces)
        IF (ALLOCATED(this%constraints)) DEALLOCATE(this%constraints)
        IF (ALLOCATED(this%global_coords)) DEALLOCATE(this%global_coords)
        IF (ALLOCATED(this%global_conn)) DEALLOCATE(this%global_conn)
        IF (ALLOCATED(this%global_elem_type)) DEALLOCATE(this%global_elem_type)
        
    END SUBROUTINE assembly_clear
    
    SUBROUTINE assembly_get_summary(this, arg)
        CLASS(UF_AssemblyDef), INTENT(IN)    :: this
        TYPE(MD_Asm_GetSummary_Arg), INTENT(INOUT) :: arg
        CALL init_error_status(arg%status)
        WRITE(arg%summary, '(A,A,A,I0,A,I0,A,I0)') &
          "Assembly[", TRIM(this%name), "] instances=", this%num_instances, &
          " nodes=", this%total_nodes, &
          " elems=", this%total_elements
        arg%status%status_code = IF_STATUS_OK
    END SUBROUTINE assembly_get_summary


  !====================================================================
  ! Mirror one L6 / command-line UF_Constraint into md_layer%assembly
  ! (legacy MD_ConstraintDef list) for tools that read assembly.constraints
  ! alongside constraint_union. Safe no-op if assembly domain not Init.
  !====================================================================
  SUBROUTINE MD_Assembly_MirrorUFConstraintToDomain(md_layer, uf_cst, status)
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(UF_Constraint),        INTENT(IN)    :: uf_cst
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: idx
    TYPE(MD_ConstraintDef) :: cst_def

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized .OR. .NOT. md_layer%assembly%initialized) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'MD_Assembly_MirrorUFConstraintToDomain: assembly not active; skip'
      RETURN
    END IF

    ! Forward to md_layer%assembly
    idx = md_layer%assembly%n_constraints + 1_i4
    CALL UF_Constraint_To_MD_ConstraintDef(uf_cst, idx, cst_def)
    CALL md_layer%assembly%AddConstraint(cst_def, status)
  END SUBROUTINE MD_Assembly_MirrorUFConstraintToDomain


  !====================================================================
  ! MD_Assembly_SyncFromLegacy
  ! Sync UF_AssemblyDef (legacy) -> md_layer%assembly (flat domain)
  !
  ! Safe to call multiple times: Assembly domain is cleared (Finalize)
  ! then re-Init before populating.
  ! Constraints in constraint_union are synced by MD_ConstraintSync
  ! (not here); this module handles legacy UF_Constraint only.
  !====================================================================
  SUBROUTINE MD_Assembly_SyncFromLegacy(asm_def, md_layer, status)
    TYPE(UF_AssemblyDef),       INTENT(IN)    :: asm_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: i
    TYPE(MD_Instance_Desc) :: inst_desc
    TYPE(MD_SetDef)        :: set_def
    TYPE(MD_SurfaceDef)    :: surf_def
    TYPE(MD_ConstraintDef) :: cst_def

    CALL init_error_status(status)

    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Asm_Sync: md_layer not initialized"
      RETURN
    END IF

    IF (.NOT. md_layer%assembly%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_Asm_Sync: assembly domain not initialized"
      RETURN
    END IF

    ! Idempotent repopulate: clear domain then Init (matches CONTRACT / header).
    CALL md_layer%assembly%Finalize()
    CALL md_layer%assembly%Init(status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      IF (LEN_TRIM(status%message) == 0) THEN
        status%message = "MD_Assembly_SyncFromLegacy: assembly Init failed after Finalize"
      END IF
      RETURN
    END IF

    !-- 1) Instances: UF_InstanceDef -> MD_Instance_Desc
    !   part_ref = uf_inst%part_id (-> MD_Part_Domain)
    DO i = 1, asm_def%num_instances
      IF (i > SIZE(asm_def%instances)) EXIT
      CALL UF_Instance_To_MD_Instance(asm_def%instances(i), inst_desc)
      CALL md_layer%assembly%AddInstance(inst_desc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    !------------------------------------------------------------------
    ! 2) Node sets: UF_NodeSet -> MD_SetDef
    !------------------------------------------------------------------
    DO i = 1, asm_def%num_node_sets
      IF (i > SIZE(asm_def%node_sets)) EXIT
      CALL UF_NodeSet_To_MD_SetDef(asm_def%node_sets(i), i, set_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      CALL md_layer%assembly%AddNodeSet(set_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    !------------------------------------------------------------------
    ! 3) Elem sets: UF_ElemSet -> MD_SetDef
    !------------------------------------------------------------------
    DO i = 1, asm_def%num_elem_sets
      IF (i > SIZE(asm_def%elem_sets)) EXIT
      CALL UF_ElemSet_To_MD_SetDef(asm_def%elem_sets(i), i, set_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      CALL md_layer%assembly%AddElemSet(set_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    !------------------------------------------------------------------
    ! 4) Surfaces: UF_Surface -> MD_SurfaceDef
    !------------------------------------------------------------------
    DO i = 1, asm_def%num_surfaces
      IF (i > SIZE(asm_def%surfaces)) EXIT
      CALL UF_Surface_To_MD_SurfaceDef(asm_def%surfaces(i), i, surf_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      CALL md_layer%assembly%AddSurface(surf_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    !------------------------------------------------------------------
    ! 5) Legacy simplified constraints: UF_Constraint -> MD_ConstraintDef
    !    Note: full-type constraints (Tie/MPC/Rigid) are synced by
    !    MD_ConstraintSync, which writes to md_layer%constraint.
    !    Here we only migrate the simplified UF_Constraint legacy array.
    !------------------------------------------------------------------
    DO i = 1, asm_def%num_constraints
      IF (i > SIZE(asm_def%constraints)) EXIT
      CALL UF_Constraint_To_MD_ConstraintDef(asm_def%constraints(i), i, cst_def)
      CALL md_layer%assembly%AddConstraint(cst_def, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Assembly_SyncFromLegacy

  !====================================================================
  ! Private conversion helpers
  !====================================================================

  SUBROUTINE md_asm_setdef_alloc_copy_ids(def, n, src_ids, err_label, status)
    TYPE(MD_SetDef), INTENT(INOUT) :: def
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: src_ids(:)
    CHARACTER(LEN=*), INTENT(IN) :: err_label
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    INTEGER(i4) :: astat

    IF (n <= 0_i4) RETURN
    IF (INT(SIZE(src_ids), i4) < n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = TRIM(err_label) // ": id array shorter than n"
      def%n_members = 0_i4
      RETURN
    END IF
    IF (ALLOCATED(def%members)) DEALLOCATE(def%members)
    ALLOCATE(def%members(n), stat=astat)
    IF (astat /= 0) THEN
      status%status_code = IF_STATUS_MEM_ERROR
      status%message = TRIM(err_label) // ": ALLOCATE members failed"
      def%n_members = 0_i4
      RETURN
    END IF
    def%members(1:n) = src_ids(1:n)
  END SUBROUTINE md_asm_setdef_alloc_copy_ids

  !--------------------------------------------------------------------
  ! UF_InstanceDef -> MD_Instance_Desc
  ! part_ref: UF_InstanceDef%part_id -> MD_Instance_Desc%part_ref
  !--------------------------------------------------------------------
  SUBROUTINE UF_Instance_To_MD_Instance(uf_inst, desc)
    TYPE(UF_InstanceDef), INTENT(IN)  :: uf_inst
    TYPE(MD_Instance_Desc), INTENT(OUT) :: desc

    desc%name        = uf_inst%name
    desc%inst_id     = uf_inst%cfg%id
    desc%part_ref    = uf_inst%part_id        ! MD_Part_Domain slot
    desc%translation = uf_inst%translation
    desc%rotation    = uf_inst%rotation_matrix
    desc%dependent   = uf_inst%is_dependent

  END SUBROUTINE UF_Instance_To_MD_Instance

  !--------------------------------------------------------------------
  ! UF_NodeSet -> MD_SetDef
  !--------------------------------------------------------------------
  SUBROUTINE UF_NodeSet_To_MD_SetDef(uf_nset, set_idx, def, status)
    TYPE(UF_NodeSet), INTENT(IN)  :: uf_nset
    INTEGER(i4),      INTENT(IN)  :: set_idx
    TYPE(MD_SetDef),  INTENT(OUT) :: def
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    INTEGER(i4) :: n

    def%name     = uf_nset%name
    def%set_id   = set_idx
    n = uf_nset%num_nodes
    def%n_members = n
    IF (n > 0_i4 .AND. ALLOCATED(uf_nset%node_ids)) THEN
      CALL md_asm_setdef_alloc_copy_ids(def, n, uf_nset%node_ids, &
        "UF_NodeSet_To_MD_SetDef", status)
    END IF

  END SUBROUTINE UF_NodeSet_To_MD_SetDef

  !--------------------------------------------------------------------
  ! UF_ElemSet -> MD_SetDef
  !--------------------------------------------------------------------
  SUBROUTINE UF_ElemSet_To_MD_SetDef(uf_eset, set_idx, def, status)
    TYPE(UF_ElemSet), INTENT(IN)  :: uf_eset
    INTEGER(i4),      INTENT(IN)  :: set_idx
    TYPE(MD_SetDef),  INTENT(OUT) :: def
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    INTEGER(i4) :: n

    def%name     = uf_eset%name
    def%set_id   = set_idx
    n = uf_eset%num_elems
    def%n_members = n
    IF (n > 0_i4 .AND. ALLOCATED(uf_eset%elem_ids)) THEN
      CALL md_asm_setdef_alloc_copy_ids(def, n, uf_eset%elem_ids, &
        "UF_ElemSet_To_MD_SetDef", status)
    END IF

  END SUBROUTINE UF_ElemSet_To_MD_SetDef

  !--------------------------------------------------------------------
  ! UF_Surface -> MD_SurfaceDef
  ! facets(i)%elem_id -> elem_ids(:), facets(i)%face_id -> face_ids(:)
  !--------------------------------------------------------------------
  SUBROUTINE UF_Surface_To_MD_SurfaceDef(uf_surf, surf_idx, def, status)
    TYPE(UF_Surface),  INTENT(IN)  :: uf_surf
    INTEGER(i4),       INTENT(IN)  :: surf_idx
    TYPE(MD_SurfaceDef), INTENT(OUT) :: def
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    INTEGER(i4) :: n, j
    INTEGER(i4) :: astat

    def%name    = uf_surf%name
    def%surf_id = surf_idx
    n = uf_surf%num_facets
    def%n_faces = n
    IF (n > 0 .AND. ALLOCATED(uf_surf%facets)) THEN
      IF (ALLOCATED(def%elem_ids)) DEALLOCATE(def%elem_ids)
      IF (ALLOCATED(def%face_ids)) DEALLOCATE(def%face_ids)
      ALLOCATE(def%elem_ids(n), stat=astat)
      IF (astat /= 0) THEN
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "UF_Surface_To_MD_SurfaceDef: ALLOCATE elem_ids failed"
        def%n_faces = 0_i4
        RETURN
      END IF
      ALLOCATE(def%face_ids(n), stat=astat)
      IF (astat /= 0) THEN
        IF (ALLOCATED(def%elem_ids)) DEALLOCATE(def%elem_ids)
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "UF_Surface_To_MD_SurfaceDef: ALLOCATE face_ids failed"
        def%n_faces = 0_i4
        RETURN
      END IF
      DO j = 1, n
        def%elem_ids(j) = uf_surf%facets(j)%elem_id
        def%face_ids(j) = uf_surf%facets(j)%face_id
      END DO
    END IF

  END SUBROUTINE UF_Surface_To_MD_SurfaceDef

  !--------------------------------------------------------------------
  ! UF_Constraint -> MD_ConstraintDef (legacy simplified mapping)
  !--------------------------------------------------------------------
  SUBROUTINE UF_Constraint_To_MD_ConstraintDef(uf_cst, cst_idx, def)
    TYPE(UF_Constraint),    INTENT(IN)  :: uf_cst
    INTEGER(i4),            INTENT(IN)  :: cst_idx
    TYPE(MD_ConstraintDef), INTENT(OUT) :: def

    def%name            = uf_cst%name
    def%constraint_id   = cst_idx
    ! Map UF legacy codes (1-4) -> MD_Constr_Def enumerators
    SELECT CASE (uf_cst%constraint_type)
    CASE (UF_CST_LEGACY_TIE)
      def%constraint_type = CONSTRAINT_TIE
    CASE (UF_CST_LEGACY_COUPLING)
      def%constraint_type = CONSTRAINT_COUPLING
    CASE (UF_CST_LEGACY_MPC)
      def%constraint_type = CONSTRAINT_MPC
    CASE (UF_CST_LEGACY_RIGID)
      def%constraint_type = CONSTRAINT_RIGID
    CASE default
      def%constraint_type = uf_cst%constraint_type
    END SELECT
    def%master_surface  = uf_cst%master_surface
    def%slave_surface   = uf_cst%slave_surface
    def%tolerance       = uf_cst%position_tolerance
    def%adjust          = .TRUE.

  END SUBROUTINE UF_Constraint_To_MD_ConstraintDef

END MODULE MD_Asm_Sync

