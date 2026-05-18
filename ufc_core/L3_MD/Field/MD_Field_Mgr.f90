!===============================================================================
! MODULE: MD_Field_Mgr
! LAYER:  L3_MD
! DOMAIN: Field
! ROLE:   Mgr — Field variable management and state container
! BRIEF:  Nodal/element state containers, field-state manager, Desc registry API.
! PILOT:  Desc registry + state mgr stay thin — numeric kernels live L4 `PH_Field_*`;
!         bridge-side UniFld stays `MD_UniFldRT_Brg` (material IP eval, not this file).
!===============================================================================
!
! Types:
!   MD_NodeDisp       — Node id + translational displacement (for bridge)
!   MD_NodalField     — Nodal field variable (values + old + increment)
!   MD_ElemIPData     — Element integration point data (stress/strain/SDV)
!   MD_FieldMgr_Type  — Unified field-state manager
!
! Procedures (Desc registry API, merged from former MD_Field_Core):
!   [P0] MD_Field_Domain_Init / MD_Field_Domain_Finalize
!   [P0] MD_Field_Define / MD_Field_Set_Initial / MD_Field_Set_InitCond
!   [P0] MD_Field_Get_By_ID / MD_Field_Get_By_Name / MD_Field_Get_Count
!
! Status: FOUR-TYPE | CORE | Last verified: 2026-04-28
!===============================================================================
MODULE MD_Field_Mgr
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE MD_Field_Def, ONLY: MD_Field_Desc, MD_Field_State, MD_Field_Ctx, &
                            MD_FieldEntry, MD_FieldRegionRef, &
                            MD_FieldInitCond, MD_FIELD_MAX, &
                            MD_FIELD_DISPLACEMENT, MD_FIELD_VELOCITY, &
                            MD_FIELD_ACCELERATION, MD_FIELD_TEMPERATURE, &
                            MD_FIELD_PORE_PRESSURE, MD_FIELD_ELECTRIC_POT, &
                            MD_FIELD_MAGNETIC_POT, MD_FIELD_USER, &
                            MD_FIELD_ENTITY_NODE, MD_FIELD_DIST_UNIFORM
    IMPLICIT NONE
    PRIVATE
    
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_MAX_NAME_LEN = 32
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_MAX_SDV = 200
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_MAX_FIELDS = 20
    
    ! Compatibility aliases. New code should import MD_FIELD_* from MD_Field_Def.
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_DISPLACEMENT  = MD_FIELD_DISPLACEMENT
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_VELOCITY      = MD_FIELD_VELOCITY
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_ACCELERATION  = MD_FIELD_ACCELERATION
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_TEMPERATURE   = MD_FIELD_TEMPERATURE
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_PORE_PRESSURE = MD_FIELD_PORE_PRESSURE
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_ELECTRIC_POT  = MD_FIELD_ELECTRIC_POT
    INTEGER(i4), PARAMETER, PUBLIC :: MD_FLD_MAGNETIC_POT  = MD_FIELD_MAGNETIC_POT

    PUBLIC :: MD_Field_Domain_Init
    PUBLIC :: MD_Field_Domain_Finalize
    PUBLIC :: MD_Field_Define
    PUBLIC :: MD_Field_Set_Initial
    PUBLIC :: MD_Field_Set_InitCond
    PUBLIC :: MD_Field_Get_By_ID
    PUBLIC :: MD_Field_Get_By_Name
    PUBLIC :: MD_Field_Get_Count

    !--------------------------------------------------------------------------
    ! MD_NodeDisp: global node id + translational displacement
    ! Used by contact / bridge for current-config coordinate update.
    !--------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_NodeDisp
        INTEGER(i4) :: id = 0_i4
        REAL(wp)    :: u_curr(3) = 0.0_wp
    END TYPE MD_NodeDisp
    
    !--------------------------------------------------------------------------
    ! Nodal Field Variable
    !--------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_NodalField
        CHARACTER(LEN=MD_FLD_MAX_NAME_LEN) :: name = ""
        INTEGER(i4) :: field_type = MD_FLD_DISPLACEMENT
        INTEGER(i4) :: num_components = 3
        INTEGER(i4) :: num_nodes = 0
        REAL(wp), ALLOCATABLE :: values(:,:)        ! (ncomp, nnodes)
        REAL(wp), ALLOCATABLE :: old_values(:,:)    ! Previous increment
        REAL(wp), ALLOCATABLE :: increment(:,:)     ! Delta values
    CONTAINS
        PROCEDURE :: init => nodal_init
        PROCEDURE :: set_value => nodal_set_value
        PROCEDURE :: get_value => nodal_get_value
        PROCEDURE :: update => nodal_update
        PROCEDURE :: store_old => nodal_store_old
        PROCEDURE :: restore => nodal_restore
        PROCEDURE :: destroy => nodal_destroy
    END TYPE MD_NodalField
    
    !--------------------------------------------------------------------------
    ! Element State (all integration points in element)
    !--------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_ElemIPData
        INTEGER(i4) :: elem_id = 0
        INTEGER(i4) :: num_int_points = 0
        INTEGER(i4) :: num_sdv = 0
        
        ! Element-level variables (SoA)
        REAL(wp), ALLOCATABLE :: sdv(:,:)        ! (nsdv, nip)
        REAL(wp), ALLOCATABLE :: sdv_old(:,:)    ! (nsdv, nip)
        
        REAL(wp), ALLOCATABLE :: stress(:,:)     ! (ncomp, nip)
        REAL(wp), ALLOCATABLE :: strain(:,:)
        REAL(wp), ALLOCATABLE :: stress_old(:,:)
        REAL(wp), ALLOCATABLE :: strain_old(:,:)
    CONTAINS
        PROCEDURE :: init => elemstate_init
        PROCEDURE :: commit_all => elemstate_commit_all
        PROCEDURE :: revert_all => elemstate_revert_all
        PROCEDURE :: destroy => elemstate_destroy
    END TYPE MD_ElemIPData
    
    !--------------------------------------------------------------------------
    ! Field State Manager
    !--------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_FieldMgr_Type
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4) :: num_elements = 0
        INTEGER(i4) :: num_fields = 0
        ! Nodal fields
        TYPE(MD_NodalField), ALLOCATABLE :: fields(:)
        ! Element states
        TYPE(MD_ElemIPData), ALLOCATABLE :: elem_states(:)
    CONTAINS
        PROCEDURE :: init => fsmgr_init
        PROCEDURE :: add_field => fsmgr_add_field
        PROCEDURE :: get_field => fsmgr_get_field
        PROCEDURE :: init_element_states => fsmgr_init_elem_states
        PROCEDURE :: get_elem_state => fsmgr_get_elem_state
        PROCEDURE :: commit_increment => fsmgr_commit
        PROCEDURE :: revert_increment => fsmgr_revert
        PROCEDURE :: destroy => fsmgr_destroy
    END TYPE MD_FieldMgr_Type
    
CONTAINS

    !--------------------------------------------------------------------------
    ! Desc registry API (merged from the former MD_Field_Core blueprint).
    !--------------------------------------------------------------------------
    SUBROUTINE MD_Field_Domain_Init(desc, state, ctx, status)
        TYPE(MD_Field_Desc),   INTENT(INOUT) :: desc
        TYPE(MD_Field_State),  INTENT(OUT)   :: state
        TYPE(MD_Field_Ctx),    INTENT(OUT)   :: ctx
        TYPE(ErrorStatusType), INTENT(OUT)   :: status

        CALL init_error_status(status)
        desc%n_fields = 0
        state%allocated   = .FALSE.
        state%initialized = .FALSE.
        ctx%current_step  = 0
        ctx%current_time  = 0.0_wp
        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Field_Domain_Init

    SUBROUTINE MD_Field_Domain_Finalize(desc, state, ctx, status)
        TYPE(MD_Field_Desc),   INTENT(INOUT) :: desc
        TYPE(MD_Field_State),  INTENT(INOUT) :: state
        TYPE(MD_Field_Ctx),    INTENT(INOUT) :: ctx
        TYPE(ErrorStatusType), INTENT(OUT)   :: status

        CALL init_error_status(status)
        desc%n_fields = 0
        state%allocated = .FALSE.
        ctx%current_step = 0
        ctx%current_incr = 0
        ctx%current_time = 0.0_wp
        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Field_Domain_Finalize

    SUBROUTINE MD_Field_Define(desc, id, name, n_comp, entity, status, &
                               field_type, distribution_kind, region, initial)
        TYPE(MD_Field_Desc),   INTENT(INOUT) :: desc
        INTEGER(i4),           INTENT(IN)    :: id
        CHARACTER(LEN=*),      INTENT(IN)    :: name
        INTEGER(i4),           INTENT(IN)    :: n_comp
        INTEGER(i4),           INTENT(IN)    :: entity
        TYPE(ErrorStatusType), INTENT(OUT)   :: status
        INTEGER(i4), INTENT(IN), OPTIONAL :: field_type
        INTEGER(i4), INTENT(IN), OPTIONAL :: distribution_kind
        TYPE(MD_FieldRegionRef), INTENT(IN), OPTIONAL :: region
        TYPE(MD_FieldInitCond), INTENT(IN), OPTIONAL :: initial
        INTEGER(i4) :: idx

        CALL init_error_status(status)
        IF (desc%n_fields >= MD_FIELD_MAX) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "[MD_Field_Define]: max fields exceeded"
            RETURN
        END IF

        desc%n_fields = desc%n_fields + 1
        idx = desc%n_fields
        desc%fields(idx)%cfg%id          = id
        desc%fields(idx)%name        = name
        desc%fields(idx)%n_comp      = n_comp
        desc%fields(idx)%entity_kind = entity
        desc%fields(idx)%entity      = entity
        IF (PRESENT(field_type)) THEN
            desc%fields(idx)%field_type = field_type
        ELSE
            desc%fields(idx)%field_type = MD_FIELD_USER
        END IF
        IF (PRESENT(distribution_kind)) THEN
            desc%fields(idx)%distribution_kind = distribution_kind
        ELSE
            desc%fields(idx)%distribution_kind = MD_FIELD_DIST_UNIFORM
        END IF
        IF (PRESENT(region)) THEN
            desc%fields(idx)%region = region
        ELSE
            desc%fields(idx)%region%entity_kind = entity
        END IF
        IF (PRESENT(initial)) THEN
            desc%fields(idx)%initial_condition = initial
            IF (ALLOCATED(initial%values) .AND. initial%n_values > 0) THEN
                desc%fields(idx)%init_val = initial%values(1)
            END IF
        ELSE
            desc%fields(idx)%initial_condition%field_id = id
            desc%fields(idx)%initial_condition%distribution_kind = &
                desc%fields(idx)%distribution_kind
            desc%fields(idx)%initial_condition%region = desc%fields(idx)%region
        END IF
        desc%fields(idx)%valid = .TRUE.
        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Field_Define

    SUBROUTINE MD_Field_Set_Initial(desc, field_id, init_val, status)
        TYPE(MD_Field_Desc),   INTENT(INOUT) :: desc
        INTEGER(i4),           INTENT(IN)    :: field_id
        REAL(wp),              INTENT(IN)    :: init_val
        TYPE(ErrorStatusType), INTENT(OUT)   :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        DO i = 1, desc%n_fields
            IF (desc%fields(i)%cfg%id == field_id .AND. desc%fields(i)%valid) THEN
                desc%fields(i)%init_val = init_val
                desc%fields(i)%initial_condition%field_id = field_id
                desc%fields(i)%initial_condition%distribution_kind = &
                    MD_FIELD_DIST_UNIFORM
                desc%fields(i)%distribution_kind = MD_FIELD_DIST_UNIFORM
                desc%fields(i)%initial_condition%n_values = 1_i4
                IF (ALLOCATED(desc%fields(i)%initial_condition%values)) &
                    DEALLOCATE(desc%fields(i)%initial_condition%values)
                ALLOCATE(desc%fields(i)%initial_condition%values(1))
                desc%fields(i)%initial_condition%values(1) = init_val
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO
        status%status_code = IF_STATUS_INVALID
        status%message = "[MD_Field_Set_Initial]: field not found"
    END SUBROUTINE MD_Field_Set_Initial

    SUBROUTINE MD_Field_Set_InitCond(desc, field_id, initial, status)
        TYPE(MD_Field_Desc),    INTENT(INOUT) :: desc
        INTEGER(i4),            INTENT(IN)    :: field_id
        TYPE(MD_FieldInitCond), INTENT(IN)    :: initial
        TYPE(ErrorStatusType),  INTENT(OUT)   :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        DO i = 1, desc%n_fields
            IF (desc%fields(i)%cfg%id == field_id .AND. desc%fields(i)%valid) THEN
                desc%fields(i)%initial_condition = initial
                desc%fields(i)%initial_condition%field_id = field_id
                desc%fields(i)%distribution_kind = initial%distribution_kind
                desc%fields(i)%region = initial%region
                IF (ALLOCATED(initial%values) .AND. initial%n_values > 0) THEN
                    desc%fields(i)%init_val = initial%values(1)
                END IF
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO
        status%status_code = IF_STATUS_INVALID
        status%message = "[MD_Field_Set_InitCond]: field not found"
    END SUBROUTINE MD_Field_Set_InitCond

    SUBROUTINE MD_Field_Get_By_ID(desc, field_id, field, status)
        TYPE(MD_Field_Desc),   INTENT(IN)  :: desc
        INTEGER(i4),           INTENT(IN)  :: field_id
        TYPE(MD_FieldEntry),   INTENT(OUT) :: field
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        DO i = 1, desc%n_fields
            IF (desc%fields(i)%cfg%id == field_id .AND. desc%fields(i)%valid) THEN
                field = desc%fields(i)
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO
        status%status_code = IF_STATUS_INVALID
        status%message = "[MD_Field_Get_By_ID]: not found"
    END SUBROUTINE MD_Field_Get_By_ID

    SUBROUTINE MD_Field_Get_By_Name(desc, name, field, status)
        TYPE(MD_Field_Desc),   INTENT(IN)  :: desc
        CHARACTER(LEN=*),      INTENT(IN)  :: name
        TYPE(MD_FieldEntry),   INTENT(OUT) :: field
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        DO i = 1, desc%n_fields
            IF (TRIM(desc%fields(i)%name) == TRIM(name) .AND. &
                desc%fields(i)%valid) THEN
                field = desc%fields(i)
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO
        status%status_code = IF_STATUS_INVALID
        status%message = "[MD_Field_Get_By_Name]: not found"
    END SUBROUTINE MD_Field_Get_By_Name

    FUNCTION MD_Field_Get_Count(desc) RESULT(n)
        TYPE(MD_Field_Desc), INTENT(IN) :: desc
        INTEGER(i4) :: n
        n = desc%n_fields
    END FUNCTION MD_Field_Get_Count

    !--------------------------------------------------------------------------
    ! Nodal Field Methods
    !--------------------------------------------------------------------------
    SUBROUTINE nodal_init(this, name, ftype, ncomp, nnodes)
        CLASS(MD_NodalField), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: ftype, ncomp, nnodes
        this%name = TRIM(name)
        this%field_type = ftype
        this%num_components = ncomp
        this%num_nodes = nnodes
        ALLOCATE(this%values(ncomp, nnodes))
        ALLOCATE(this%old_values(ncomp, nnodes))
        ALLOCATE(this%increment(ncomp, nnodes))
        this%values = 0.0_wp
        this%old_values = 0.0_wp
        this%increment = 0.0_wp
    END SUBROUTINE nodal_init
    
    SUBROUTINE nodal_set_value(this, node_id, comp, val)
        CLASS(MD_NodalField), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node_id, comp
        REAL(wp), INTENT(IN) :: val
        IF (node_id >= 1 .AND. node_id <= this%num_nodes) THEN
            IF (comp >= 1 .AND. comp <= this%num_components) THEN
                this%values(comp, node_id) = val
            END IF
        END IF
    END SUBROUTINE nodal_set_value
    
    FUNCTION nodal_get_value(this, node_id, comp) RESULT(val)
        CLASS(MD_NodalField), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node_id, comp
        REAL(wp) :: val
        val = 0.0_wp
        IF (node_id >= 1 .AND. node_id <= this%num_nodes) THEN
            IF (comp >= 1 .AND. comp <= this%num_components) THEN
                val = this%values(comp, node_id)
            END IF
        END IF
    END FUNCTION nodal_get_value
    
    SUBROUTINE nodal_update(this, delta)
        CLASS(MD_NodalField), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: delta(:,:)
        this%values = this%values + delta
        this%increment = this%increment + delta
    END SUBROUTINE nodal_update
    
    SUBROUTINE nodal_store_old(this)
        CLASS(MD_NodalField), INTENT(INOUT) :: this
        this%old_values = this%values
        this%increment = 0.0_wp
    END SUBROUTINE nodal_store_old
    
    SUBROUTINE nodal_restore(this)
        CLASS(MD_NodalField), INTENT(INOUT) :: this
        this%values = this%old_values
        this%increment = 0.0_wp
    END SUBROUTINE nodal_restore
    
    SUBROUTINE nodal_destroy(this)
        CLASS(MD_NodalField), INTENT(INOUT) :: this
        IF (ALLOCATED(this%values)) DEALLOCATE(this%values)
        IF (ALLOCATED(this%old_values)) DEALLOCATE(this%old_values)
        IF (ALLOCATED(this%increment)) DEALLOCATE(this%increment)
    END SUBROUTINE nodal_destroy

    !--------------------------------------------------------------------------
    ! Element State Methods
    !--------------------------------------------------------------------------
    SUBROUTINE elemstate_init(this, elem_id, nip, nsdv, nstress)
        CLASS(MD_ElemIPData), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: elem_id, nip, nsdv, nstress
        
        this%elem_id = elem_id
        this%num_int_points = nip
        this%num_sdv = nsdv
        
        ALLOCATE(this%sdv(nsdv, nip), this%sdv_old(nsdv, nip))
        this%sdv = 0.0_wp
        this%sdv_old = 0.0_wp
        
        ALLOCATE(this%stress(nstress, nip), this%strain(nstress, nip))
        ALLOCATE(this%stress_old(nstress, nip), this%strain_old(nstress, nip))
        this%stress = 0.0_wp
        this%strain = 0.0_wp
        this%stress_old = 0.0_wp
        this%strain_old = 0.0_wp
    END SUBROUTINE elemstate_init
    
    SUBROUTINE elemstate_commit_all(this)
        CLASS(MD_ElemIPData), INTENT(INOUT) :: this
        
        this%sdv_old = this%sdv
        this%stress_old = this%stress
        this%strain_old = this%strain
    END SUBROUTINE elemstate_commit_all
    
    SUBROUTINE elemstate_revert_all(this)
        CLASS(MD_ElemIPData), INTENT(INOUT) :: this
        
        this%sdv = this%sdv_old
        this%stress = this%stress_old
        this%strain = this%strain_old
    END SUBROUTINE elemstate_revert_all
    
    SUBROUTINE elemstate_destroy(this)
        CLASS(MD_ElemIPData), INTENT(INOUT) :: this
        
        IF (ALLOCATED(this%sdv)) DEALLOCATE(this%sdv)
        IF (ALLOCATED(this%sdv_old)) DEALLOCATE(this%sdv_old)
        
        IF (ALLOCATED(this%stress)) DEALLOCATE(this%stress)
        IF (ALLOCATED(this%strain)) DEALLOCATE(this%strain)
        IF (ALLOCATED(this%stress_old)) DEALLOCATE(this%stress_old)
        IF (ALLOCATED(this%strain_old)) DEALLOCATE(this%strain_old)
    END SUBROUTINE elemstate_destroy

    !--------------------------------------------------------------------------
    ! Field State Manager Methods
    !--------------------------------------------------------------------------
    SUBROUTINE fsmgr_init(this, nnodes, nelems)
        CLASS(MD_FieldMgr_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nnodes, nelems
        
        this%num_nodes = nnodes
        this%num_elements = nelems
        this%num_fields = 0
        
        IF (ALLOCATED(this%fields)) DEALLOCATE(this%fields)
        ALLOCATE(this%fields(MD_FLD_MAX_FIELDS))
        
        IF (ALLOCATED(this%elem_states)) DEALLOCATE(this%elem_states)
        IF (nelems > 0) THEN
            ALLOCATE(this%elem_states(nelems))
        ELSE
            ! Even if nelems is 0, we might want to allocate it as size 0 
            ! or leave it unallocated? 
            ! Standard practice: allocate size 0 to avoid check later
            ALLOCATE(this%elem_states(0))
        END IF
    END SUBROUTINE fsmgr_init
    
    SUBROUTINE fsmgr_add_field(this, name, ftype, ncomp)
        CLASS(MD_FieldMgr_Type), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: ftype, ncomp
        IF (this%num_fields >= MD_FLD_MAX_FIELDS) RETURN
        this%num_fields = this%num_fields + 1
        CALL this%fields(this%num_fields)%init(name, ftype, ncomp, this%num_nodes)
    END SUBROUTINE fsmgr_add_field
    
    FUNCTION fsmgr_get_field(this, name) RESULT(ptr)
        CLASS(MD_FieldMgr_Type), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(MD_NodalField), POINTER :: ptr
        INTEGER(i4) :: i
        ptr => NULL()
        DO i = 1, this%num_fields
            IF (TRIM(this%fields(i)%name) == TRIM(name)) THEN
                ptr => this%fields(i)
                RETURN
            END IF
        END DO
    END FUNCTION fsmgr_get_field
    
    SUBROUTINE fsmgr_init_elem_states(this, nip_array, nsdv, nstress)
        CLASS(MD_FieldMgr_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nip_array(:), nsdv, nstress
        INTEGER(i4) :: i
        DO i = 1, this%num_elements
            CALL this%elem_states(i)%init(i, nip_array(i), nsdv, nstress)
        END DO
    END SUBROUTINE fsmgr_init_elem_states
    
    FUNCTION fsmgr_get_elem_state(this, elem_id) RESULT(ptr)
        CLASS(MD_FieldMgr_Type), INTENT(IN), TARGET :: this
        INTEGER(i4), INTENT(IN) :: elem_id
        TYPE(MD_ElemIPData), POINTER :: ptr
        ptr => NULL()
        IF (elem_id >= 1 .AND. elem_id <= this%num_elements) THEN
            ptr => this%elem_states(elem_id)
        END IF
    END FUNCTION fsmgr_get_elem_state
    
    SUBROUTINE fsmgr_commit(this)
        CLASS(MD_FieldMgr_Type), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        DO i = 1, this%num_fields
            CALL this%fields(i)%store_old()
        END DO
        DO i = 1, this%num_elements
            CALL this%elem_states(i)%commit_all()
        END DO
    END SUBROUTINE fsmgr_commit
    
    SUBROUTINE fsmgr_revert(this)
        CLASS(MD_FieldMgr_Type), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        DO i = 1, this%num_fields
            CALL this%fields(i)%restore()
        END DO
        DO i = 1, this%num_elements
            CALL this%elem_states(i)%revert_all()
        END DO
    END SUBROUTINE fsmgr_revert
    
    SUBROUTINE fsmgr_destroy(this)
        CLASS(MD_FieldMgr_Type), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        DO i = 1, this%num_fields
            CALL this%fields(i)%destroy()
        END DO
        DO i = 1, this%num_elements
            CALL this%elem_states(i)%destroy()
        END DO
        IF (ALLOCATED(this%fields)) DEALLOCATE(this%fields)
        IF (ALLOCATED(this%elem_states)) DEALLOCATE(this%elem_states)
    END SUBROUTINE fsmgr_destroy

END MODULE MD_Field_Mgr