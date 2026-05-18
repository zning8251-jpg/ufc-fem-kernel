!===============================================================================
! MODULE:  MD_Model_Lib_Core
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Impl (core library implementation)
! BRIEF:   P0 Library: Core model definition type (UF_ModelDef) and operations.
!          v2.2 — UF_ModelVarContext + Context_Model extracted to MD_Model_VarCtx.
!          Extracted from legacy MD_Model_Lib module (facade removed v3.1.4).
!===============================================================================
! Theory:
!   Model definition includes:
!   - Geometry: Node coords X(ndim,nnode), element connectivity conn(max_nodes,nelem)
!   - Materials: E, nu, rho; constitutive sigma = f(epsilon, params)
!   - Sections: Thickness t, area A, moments of inertia I, torsional constant J
!   - Loads/BCs: Concentrated loads F_i = f_i, distributed loads F = ?N^T?t dS
!   - DOF management: DOF mapping eqn = f(node_id, dof_local), equation numbering
!   - Field state: Displacement u(ndof), stress sigma(nstress), strain epsilon(nstrain)
! References:
!   - Zienkiewicz, O.C. & Taylor, R.L. (2005). The Finite Element Method, 6th ed.
! Status: Phase B | Last verified: 2026-03-11
!
! Contents:
!   Types:
!     - UF_ModelDef: Model definition type (Desc category)
!     - MD_Model_Init_In/Out: Structured initialization interface
!     - MD_Model_AddPart_In/Out: Structured add part interface
!     - MD_Model_AddMaterial_In/Out: Structured add material interface
!     - MD_Model_ApplyBC_In/Out: Structured apply boundary conditions interface
!     - MD_Model_ApplyLoads_In/Out: Structured apply loads interface
!   Subroutines:
!     - model_initialize: Initialize model definition (legacy interface)
!     - model_add_part: Add part to model (legacy interface)
!     - model_get_part: Get part by name (legacy interface)
!     - model_add_material: Add material to model (legacy interface)
!     - model_get_material: Get material by name (legacy interface)
!     - model_add_section: Add section to model (legacy interface)
!     - model_get_section: Get section by name (legacy interface)
!     - model_add_amplitude: Add amplitude to model (legacy interface)
!     - model_get_amplitude: Get amplitude by name (legacy interface)
!     - model_apply_boundary_conditions: Apply boundary conditions (legacy interface)
!     - model_apply_structural_loads: Apply structural loads (legacy interface)
!     - model_prepare_analysis: Prepare model for analysis (legacy interface)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Lib | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

MODULE MD_Model_Lib_Core
!> [CORE] Core model definition type and operations
!> Theory: X(ndim,nnode), conn(max_nodes,nelem), eqn=f(node_id,dof_local), F=integral(N^T*t dS)
!> Status: CORE | Last verified: 2026-02-28

    USE IF_Err_Brg, ONLY: log_error, ErrorStatusType, init_error_status, MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
    USE MD_Asm_Sync
    USE MD_Constr_Prop, ONLY: UF_ContactPropertyDB
    USE MD_DOF_Mgr, ONLY: UF_DOFLabelMapType, UF_DOFLabelMap_Init, UF_DOFLabelMap_Register, &
                          UF_DOFLabelMap_GetSlot
    USE MD_DOF_Impl
    USE MD_Field_Mgr
    USE MD_LBC_Brg, ONLY: BC_DISPLACEMENT, BC_ENCASTRE, BC_PINNED, &
                           BC_XSYMM, BC_YSYMM, BC_ZSYMM
    USE MD_Mat_Lib, ONLY: UF_MaterialDef, UF_MaterialDB
    USE MD_Part_Mgr, ONLY: UF_PartDef
    USE MD_Sect_Lib, ONLY: UF_SectionDef, UF_SectionDBType
    USE MD_Sets_Mgr, ONLY: UF_NodeSet
    USE MD_Step_Proc
    USE MD_Model_Def, ONLY: MD_Model_Desc, MD_Model_Ctx, MD_Model_State, MD_Model_Algo
    USE MD_Base_Enums, ONLY: MD_MODEL_UF_JOB_STATUS_U, MD_MODEL_UF_JOB_STATUS_S, MD_MODEL_UF_JOB_STATUS_N, MD_MODEL_UF_JOB_STATUS_E
    USE MD_Base_ObjModel, ONLY: UF_Model, UF_Node, UF_Element, UF_Part, UF_Instance, UF_Assem, &
        UF_Description, UF_NodeSet, UF_ElemSet, UF_SurfSet, UF_ModelDesc, UF_NodeHdl, UF_ElemHdl, UF_SetHdl, UF_SurfHdl, &
        ModelSys => UF_ModelSys
    ! VarCtx re-exports
    USE MD_Model_VarCtx, ONLY: UF_ModelVarContext, Context_Model, Context_Model_State
    USE MD_Model_VarCtx, ONLY: UF_ModelVar_ClearCurrentContext, UF_ModelVarContext_RegisterScalar
    USE MD_Model_VarCtx, ONLY: UF_ModelVar_InitContext, UF_ModelVar_RegisterField, UF_ModelVar_SetCurrentContext
    USE MD_Model_VarCtx, ONLY: GetCurrentContext, GetReal1D
    USE MD_Model_VarCtx, ONLY: MV_GetContextOrUseCurrent, MV_GetCurrentContext, MV_GetReal1D
    USE MD_Model_VarCtx, ONLY: Context_Model_EnsureStorage
    IMPLICIT NONE
    PRIVATE
    
    PUBLIC :: UF_ModelDef, MD_MODEL_MODEL_DEFINED
    PUBLIC :: MD_Model_Desc, MD_Model_Ctx, MD_Model_State, MD_Model_Algo
    PUBLIC :: MD_Model_Init_In, MD_Model_Init_Out
    PUBLIC :: MD_Model_AddPart_In, MD_Model_AddPart_Out
    PUBLIC :: MD_Model_AddMaterial_In, MD_Model_AddMaterial_Out
    PUBLIC :: MD_Model_ApplyBC_In, MD_Model_ApplyBC_Out
    PUBLIC :: MD_Model_ApplyLoads_In, MD_Model_ApplyLoads_Out
    PUBLIC :: MD_Model_Init_Desc, MD_Model_Init_Algo, MD_Model_Init_Ctx, MD_Model_Init_State
    ! Merged from MD_ModelUtils
    PUBLIC :: MD_Model_Valid
    PUBLIC :: MD_Model_Compare
    PUBLIC :: MD_Model_GetStatistics
    PUBLIC :: MD_Model_CheckConsistency
    PUBLIC :: MD_Model_GetElementCount
    PUBLIC :: MD_Model_GetNodeCount
    PUBLIC :: MD_Model_GetMaterialCount
    PUBLIC :: MD_Theory_Query
    PUBLIC :: MD_Theory_Describe
    PUBLIC :: MD_Theory_GetNumModules
    PUBLIC :: MD_Theory_QueryByIndex
    PUBLIC :: MD_Theory_ExportList
    ! API (merged from MD_Model_API)
    PUBLIC :: Desc_Model
    PUBLIC :: Model_FromDesc
    PUBLIC :: Model_FromDesc_Control
    PUBLIC :: Model_FromDesc_State
    ! Merged from MD_Core: re-exports and runtime context
    PUBLIC :: UF_Model, UF_Node, UF_Element, UF_Part, UF_Instance, UF_Assem
    PUBLIC :: UF_Description, UF_NodeSet, UF_ElemSet, UF_SurfSet, UF_ModelDesc
    PUBLIC :: UF_NodeHdl, UF_ElemHdl, UF_SetHdl, UF_SurfHdl
    PUBLIC :: UF_ModelSys, UF_AnalysisStep
    PUBLIC :: MD_MODEL_UF_JOBSTATUS_Success, MD_MODEL_UF_JOBSTATUS_NonConvergence, MD_MODEL_UF_JOBSTATUS_InputError, MD_MODEL_UF_JOBSTATUS_InternalError, MD_MODEL_UF_JOBSTATUS_UserAbort
    PUBLIC :: UF_StepType_Static, UF_StepType_ImplicitDynamic, UF_StepType_ExplicitDynamic, UF_StepType_Modal
    
    INTEGER(i4), PARAMETER :: MD_MODEL_MODEL_DEFINED = 1
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOBSTATUS_Success = MD_MODEL_UF_JOB_STATUS_S
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOBSTATUS_NonConvergence = MD_MODEL_UF_JOB_STATUS_N
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOBSTATUS_InputError = MD_MODEL_UF_JOB_STATUS_E
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOBSTATUS_InternalError = 4_i4
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOBSTATUS_UserAbort = 5_i4
    INTEGER(i4), PARAMETER :: UF_StepType_Static = MD_MODEL_STEP_STATIC
    INTEGER(i4), PARAMETER :: UF_StepType_ImplicitDynamic = MD_MODEL_STEP_IMPLICIT_D
    INTEGER(i4), PARAMETER :: UF_StepType_ExplicitDynamic = MD_MODEL_STEP_EXPLICIT_D
    INTEGER(i4), PARAMETER :: UF_StepType_Modal = PROC_MODAL
    
    !> @brief Desc_Model - external description type for Model (API)
    TYPE, PUBLIC :: Desc_Model
        INTEGER(i4) :: model_id = 0_i4
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=128) :: description = ""
        INTEGER(i4) :: dimension = 3_i4
    END TYPE Desc_Model

    ! [VarCtx types moved to MD_Model_VarCtx]
    
    !=============================================================================
    ! FOUR-CATEGORY TYPE SYSTEM: Desc/Algo/Ctx/State
    !=============================================================================
    
    !> @brief Descriptor for model initialization
    TYPE, PUBLIC :: MD_Model_Init_Desc
      CHARACTER(LEN=64) :: name = ""  ! Model name
      CHARACTER(LEN=256) :: input_file = ""  ! Input file path
      INTEGER(i4) :: dimension = 3  ! Spatial dimension ??{2, 3}
    END TYPE MD_Model_Init_Desc
    
    !> @brief Algorithm parameters for model initialization
    TYPE, PUBLIC :: MD_Model_Init_Algo
      LOGICAL :: initialize_dof_mgr = .TRUE.  ! Initialize DOF manager
      LOGICAL :: initialize_field_mgr = .TRUE.  ! Initialize field state manager
      INTEGER(i4) :: max_dof_per_node = 6  ! Max DOFs per node
    END TYPE MD_Model_Init_Algo
    
    !> @brief Context for model initialization
    TYPE, PUBLIC :: MD_Model_Init_Ctx
      LOGICAL :: verbose = .FALSE.  ! Verbose output flag
      INTEGER(i4) :: log_level = 0_i4  ! Logging level (0=silent, 1=info, 2=debug)
    END TYPE MD_Model_Init_Ctx
    
    !> @brief State for model initialization
    TYPE, PUBLIC :: MD_Model_Init_State
      LOGICAL :: initialized = .FALSE.  ! Initialization success status
      INTEGER(i4) :: num_parts = 0_i4  ! Number of parts initialized
      INTEGER(i4) :: num_materials = 0_i4  ! Number of materials initialized
    END TYPE MD_Model_Init_State
    
    !> @brief Input structure for model initialization
    TYPE, PUBLIC :: MD_Model_Init_In
      TYPE(MD_Model_Init_Desc) :: desc
      TYPE(MD_Model_Init_Algo) :: algo
      TYPE(MD_Model_Init_Ctx) :: ctx
      TYPE(MD_Model_Init_State) :: state
    END TYPE MD_Model_Init_In
    
    !> @brief Output structure for model initialization
    TYPE, PUBLIC :: MD_Model_Init_Out
      TYPE(MD_Model_Init_State) :: state
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_Init_Out
    
    !> @brief Input structure for adding part to model
    TYPE, PUBLIC :: MD_Model_AddPart_In
      TYPE(UF_PartDef) :: part  ! Part definition to add
    END TYPE MD_Model_AddPart_In
    
    !> @brief Output structure for adding part to model
    TYPE, PUBLIC :: MD_Model_AddPart_Out
      INTEGER(i4) :: part_id = 0  ! Assigned part ID
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_AddPart_Out
    
    !> @brief Input structure for adding material to model
    TYPE, PUBLIC :: MD_Model_AddMaterial_In
      TYPE(UF_MaterialDef) :: material  ! Material definition to add
    END TYPE MD_Model_AddMaterial_In
    
    !> @brief Output structure for adding material to model
    TYPE, PUBLIC :: MD_Model_AddMaterial_Out
      INTEGER(i4) :: material_id = 0  ! Assigned material ID
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_AddMaterial_Out
    
    !> @brief Input structure for applying boundary conditions
    TYPE, PUBLIC :: MD_Model_ApplyBC_In
      INTEGER(i4) :: step_index = 0  ! Step index
      REAL(wp) :: time = 0.0_wp  ! Current time t
    END TYPE MD_Model_ApplyBC_In
    
    !> @brief Output structure for applying boundary conditions
    TYPE, PUBLIC :: MD_Model_ApplyBC_Out
      INTEGER(i4) :: num_bcs_applied = 0  ! Number of BCs applied
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_ApplyBC_Out
    
    !> @brief Input structure for applying structural loads
    TYPE, PUBLIC :: MD_Model_ApplyLoads_In
      INTEGER(i4) :: step_index = 0  ! Step index
      REAL(wp) :: time = 0.0_wp  ! Current time t
      REAL(wp), ALLOCATABLE :: F_ext(:)  ! External force F_ext(ndof), will be modified
    END TYPE MD_Model_ApplyLoads_In
    
    !> @brief Output structure for applying structural loads
    TYPE, PUBLIC :: MD_Model_ApplyLoads_Out
      INTEGER(i4) :: num_loads_applied = 0  ! Number of loads applied
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Model_ApplyLoads_Out
    
    !=============================================================================
    ! MODEL DEFINITION TYPE
    !=============================================================================
    
    !> @brief Model definition type (Desc category)
    !! Theory: Complete finite element model definition including geometry, materials, sections, loads, BCs
    TYPE :: UF_ModelDef
        CHARACTER(LEN=64) :: name = "Model-1"
        CHARACTER(LEN=256) :: input_file = ""
        INTEGER(i4) :: dimension = 3
        TYPE(UF_AssemblyDef) :: assembly
        TYPE(UF_MaterialDB) :: material_db
        TYPE(UF_SectionDBType) :: section_db
        TYPE(UF_ContactPropertyDB) :: contact_db
        TYPE(UF_StepManager) :: step_mgr

        TYPE(MD_FieldMgr_Type) :: field_mgr
        TYPE(UF_DOFManagerType), POINTER :: dof_mgr => NULL()  ! DOF manager: eqn = f(node_id, dof_local)
        TYPE(UF_DOFLabelMapType) :: dof_label_map  ! DOF label map: label ??slot (1..MAX_DOF_PER_NODE)
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: amplitudes(:)

        INTEGER(i4) :: num_amplitudes = 0
        
        TYPE(UF_PartDef), ALLOCATABLE :: parts(:)

        INTEGER(i4) :: num_parts = 0
        INTEGER(i4), ALLOCATABLE :: part_ids(:)  ! Index tree: part IDs for Domain lookup (Phase C)
    CONTAINS
        PROCEDURE :: initialize => model_initialize
        PROCEDURE :: add_part => model_add_part
        PROCEDURE :: get_part => model_get_part
        PROCEDURE :: add_material => model_add_material
        PROCEDURE :: get_material => model_get_material
        PROCEDURE :: add_section => model_add_section
        PROCEDURE :: get_section => model_get_section
        PROCEDURE :: add_amplitude => model_add_amplitude
        PROCEDURE :: get_amplitude => model_get_amplitude
        PROCEDURE :: apply_boundary_conditions => model_apply_boundary_conditions
        PROCEDURE :: apply_structural_loads => model_apply_structural_loads
        PROCEDURE :: prepare_analysis => model_prepare_analysis
    END TYPE UF_ModelDef

CONTAINS

    !=============================================================================
    ! Add Part to Model (legacy interface)
    ! Theory: Adds part definition to model parts array
    !=============================================================================
    !> @brief Add part to model (legacy interface)
    !! @details Adds part definition to model parts array
    !! @param[inout] this Model definition
    !! @param[in] part Part definition to add
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_add_part(this, part)
        CLASS(UF_ModelDef), INTENT(INOUT) :: this
        TYPE(UF_PartDef), INTENT(IN) :: part
        TYPE(UF_PartDef), ALLOCATABLE :: temp(:)
        
        IF (.NOT. ALLOCATED(this%parts)) THEN
            ALLOCATE(this%parts(10))
            this%num_parts = 0
        END IF
        
        IF (this%num_parts >= SIZE(this%parts)) THEN
            ALLOCATE(temp(SIZE(this%parts)*2))
            temp(1:this%num_parts) = this%parts
            CALL MOVE_ALLOC(temp, this%parts)
        END IF
        
        this%num_parts = this%num_parts + 1
        this%parts(this%num_parts) = part
        this%parts(this%num_parts)%cfg%id = this%num_parts
    END SUBROUTINE model_add_part

    !> @brief Get part by name (legacy interface)
    !! @details Returns pointer to part definition by name
    !! @param[in] this Model definition
    !! @param[in] name Part name
    !! @return Pointer to part definition (or NULL if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    FUNCTION model_get_part(this, name) RESULT(ptr)
        CLASS(UF_ModelDef), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_PartDef), POINTER :: ptr
        INTEGER(i4) :: i
        
        ptr => NULL()
        IF (.NOT. ALLOCATED(this%parts)) RETURN
        
        DO i = 1, this%num_parts
            IF (TRIM(this%parts(i)%name) == TRIM(name)) THEN
                ptr => this%parts(i)
                RETURN
            END IF
        END DO
    END FUNCTION model_get_part

    !=============================================================================
    ! Initialize Model Definition (legacy interface)
    ! Theory: Initialize model with name, DOF mapping eqn = f(node_id, dof_local), and component databases
    !=============================================================================
    !> @brief Initialize model definition (legacy interface)
    !! @details Initializes model with name and component databases
    !!   Theory: Sets up DOF label map (default: label=j ??slot=j), initializes material/section/contact databases
    !! @param[inout] this Model definition (will be initialized)
    !! @param[in] name Model name
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_initialize(this, name)
        CLASS(UF_ModelDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: j, ierr

        this%name = name
        NULLIFY(this%dof_mgr)
        CALL this%material_db%init()
        CALL this%contact_db%init()
        CALL this%field_mgr%init(0, 0) ! Will be resized after assembly

        IF (ALLOCATED(this%amplitudes)) DEALLOCATE(this%amplitudes)
        this%num_amplitudes = 0
        IF (ALLOCATED(this%parts)) DEALLOCATE(this%parts)
        this%num_parts = 0
        CALL this%assembly%init()
        CALL this%step_mgr%init()

        ! DOF label map: default label=j ??slot=j for DOF mapping eqn = f(node_id, dof_local)
        CALL UF_DOFLabelMap_Init(this%dof_label_map, MAX_DOF_PER_NODE)
        DO j = 1, MAX_DOF_PER_NODE
            ierr = 0
            CALL UF_DOFLabelMap_Register(this%dof_label_map, label=j, slot=j, ierr=ierr)
        END DO
    END SUBROUTINE model_initialize


    !> @brief Add material to model (legacy interface)
    !! @details Adds material definition to model material database
    !! @param[inout] this Model definition
    !! @param[in] mat Material definition to add
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_add_material(this, mat)
        CLASS(UF_ModelDef), INTENT(INOUT) :: this
        TYPE(UF_MaterialDef), INTENT(IN) :: mat
        INTEGER(i4) :: idx
        INTEGER(i4) :: keep_id

        idx = this%material_db%find_by_name(TRIM(mat%name))
        IF (idx > 0) THEN
            keep_id = this%material_db%materials(idx)%cfg%id
            this%material_db%materials(idx) = mat
            this%material_db%materials(idx)%cfg%id = keep_id
        ELSE
            CALL this%material_db%add_material(mat)
        END IF
    END SUBROUTINE model_add_material

    !> @brief Get material by name (legacy interface)
    !! @details Returns pointer to material definition by name
    !! @param[in] this Model definition
    !! @param[in] name Material name
    !! @return Pointer to material definition (or NULL if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    FUNCTION model_get_material(this, name) RESULT(ptr)
        CLASS(UF_ModelDef), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_MaterialDef), POINTER :: ptr
        INTEGER(i4) :: idx

        NULLIFY(ptr)
        idx = this%material_db%find_by_name(TRIM(name))
        IF (idx > 0) ptr => this%material_db%materials(idx)
    END FUNCTION model_get_material

    !> @brief Add section to model (legacy interface)
    !! @details Adds section definition to model section database
    !! @param[inout] this Model definition
    !! @param[in] sec Section definition to add
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_add_section(this, sec)
        CLASS(UF_ModelDef), INTENT(INOUT) :: this
        TYPE(UF_SectionDef), INTENT(IN) :: sec
        CALL this%section_db%add_section(sec)
    END SUBROUTINE model_add_section

    !> @brief Get section by name (legacy interface)
    !! @details Returns pointer to section definition by name
    !! @param[in] this Model definition
    !! @param[in] name Section name
    !! @return Pointer to section definition (or NULL if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    FUNCTION model_get_section(this, name) RESULT(ptr)
        CLASS(UF_ModelDef), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(UF_SectionDef), POINTER :: ptr
        INTEGER(i4) :: idx

        NULLIFY(ptr)
        idx = this%section_db%find_by_name(TRIM(name))
        IF (idx > 0) ptr => this%section_db%sections(idx)
    END FUNCTION model_get_section

    !> @brief Add amplitude to model (legacy interface)
    !! @details Adds amplitude definition to model amplitudes array
    !! @param[inout] this Model definition
    !! @param[in] amp Amplitude definition to add
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_add_amplitude(this, amp)
        CLASS(UF_ModelDef), INTENT(INOUT) :: this
        TYPE(MD_Amp_Slot_Desc), INTENT(IN) :: amp
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: temp(:)
        
        IF (.NOT. ALLOCATED(this%amplitudes)) THEN
            ALLOCATE(this%amplitudes(10))
            this%num_amplitudes = 0
        END IF
        
        IF (this%num_amplitudes >= SIZE(this%amplitudes)) THEN
            ALLOCATE(temp(SIZE(this%amplitudes)*2))
            temp(1:this%num_amplitudes) = this%amplitudes
            CALL MOVE_ALLOC(temp, this%amplitudes)
        END IF
        
        this%num_amplitudes = this%num_amplitudes + 1
        this%amplitudes(this%num_amplitudes) = amp
    END SUBROUTINE model_add_amplitude

    !> @brief Get amplitude by name (legacy interface)
    !! @details Returns pointer to amplitude definition by name
    !! @param[in] this Model definition
    !! @param[in] name Amplitude name
    !! @return Pointer to amplitude definition (or NULL if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    FUNCTION model_get_amplitude(this, name) RESULT(ptr)
        CLASS(UF_ModelDef), INTENT(IN), TARGET :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(MD_Amp_Slot_Desc), POINTER :: ptr
        INTEGER(i4) :: i
        
        ptr => NULL()
        IF (.NOT. ALLOCATED(this%amplitudes)) RETURN
        
        DO i = 1, this%num_amplitudes
            IF (TRIM(this%amplitudes(i)%name) == TRIM(name)) THEN
                ptr => this%amplitudes(i)
                RETURN
            END IF
        END DO
    END FUNCTION model_get_amplitude

    !=============================================================================
    ! Apply Boundary Conditions (legacy interface)
    ! Theory: Applies boundary conditions u_i = u_0 or u_i = 0 to DOF manager
    !=============================================================================
    !> @brief Apply boundary conditions for a given step (legacy interface)
    !! @details Applies boundary conditions from step definition to DOF manager
    !!   Theory: Prescribes DOF values u_i = u_0 or fixes DOFs u_i = 0 using DOF mapping eqn = f(node_id, dof_local)
    !! @param[inout] this Model definition
    !! @param[in] step_index Step index
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_apply_boundary_conditions(this, step_index)
        CLASS(UF_ModelDef), INTENT(INOUT), TARGET :: this
        INTEGER(i4), INTENT(IN) :: step_index
        
        TYPE(UF_StepDef), POINTER :: step_ptr
        TYPE(UF_BCDef), POINTER :: bc
        INTEGER(i4) :: i, j, k, node_id, dof
        INTEGER(i4) :: label, slot, ierr
        REAL(wp) :: val, time_val, amp_val

        LOGICAL :: found_set, match
        TYPE(MD_Amp_Slot_Desc), POINTER :: amp_ptr
        CHARACTER(LEN=256) :: region, set_name
        INTEGER(i4) :: len_region, len_set
        
        IF (step_index < 1 .OR. step_index > this%step_mgr%num_steps) RETURN
        step_ptr => this%step_mgr%get_step(step_index)
        time_val = step_ptr%current_time
        
        DO i = 1, step_ptr%loadbc%num_bcs
            bc => step_ptr%loadbc%bcs(i)
            IF (.NOT. bc%is_active) CYCLE
            
            IF (bc%bc_type /= BC_DISPLACEMENT .AND. &
                bc%bc_type /= BC_ENCASTRE .AND. &
                bc%bc_type /= BC_PINNED .AND. &
                bc%bc_type /= BC_XSYMM .AND. &
                bc%bc_type /= BC_YSYMM .AND. &
                bc%bc_type /= BC_ZSYMM) CYCLE
            
            amp_val = 1.0_wp
            IF (LEN_TRIM(bc%amplitude_name) > 0) THEN
                 amp_ptr => this%get_amplitude(bc%amplitude_name)
                 IF (ASSOCIATED(amp_ptr)) THEN
                      amp_val = amp_ptr%evaluate(time_val)
                 END IF
            END IF
            val = bc%magnitude * amp_val
            
            IF (bc%node_id > 0 .AND. bc%region_type == 0) THEN
                node_id = bc%node_id
                    SELECT CASE (bc%bc_type)
                CASE (BC_DISPLACEMENT)
                    ! Apply displacement BC: u_i = u_0 for DOFs (bc%dof_first..bc%dof_last)
                    ! Use DOF label map to convert label ??slot, then prescribe via DOFManager
                    DO label = bc%dof_first, bc%dof_last
                        slot = 0
                        CALL UF_DOFLabelMap_GetSlot(this%dof_label_map, label, slot)
                        IF (slot <= 0) CYCLE
                        CALL this%dof_mgr%prescribe_dof(node_id, slot, val)
                    END DO

                CASE (BC_ENCASTRE)
                    DO dof = 1, 6
                        CALL this%dof_mgr%fix_dof(node_id, dof)
                    END DO
                CASE (BC_PINNED)
                    DO dof = 1, 3
                        CALL this%dof_mgr%fix_dof(node_id, dof)
                    END DO
                CASE (BC_XSYMM)
                    CALL this%dof_mgr%fix_dof(node_id, 1)
                    CALL this%dof_mgr%fix_dof(node_id, 5)
                    CALL this%dof_mgr%fix_dof(node_id, 6)
                CASE (BC_YSYMM)
                    CALL this%dof_mgr%fix_dof(node_id, 2)
                    CALL this%dof_mgr%fix_dof(node_id, 4)
                    CALL this%dof_mgr%fix_dof(node_id, 6)
                CASE (BC_ZSYMM)
                    CALL this%dof_mgr%fix_dof(node_id, 3)
                    CALL this%dof_mgr%fix_dof(node_id, 4)
                    CALL this%dof_mgr%fix_dof(node_id, 5)
                END SELECT
                CYCLE
            END IF
            
            region = TRIM(bc%region_name)
            len_region = LEN_TRIM(region)
            IF (len_region <= 0) CYCLE
            
            found_set = .FALSE.
            DO j = 1, this%assembly%num_node_sets
                set_name = TRIM(this%assembly%node_sets(j)%name)
                len_set = LEN_TRIM(set_name)
                match = .FALSE.
                IF (len_set == len_region) THEN
                    IF (set_name(1:len_set) == region(1:len_region)) match = .TRUE.
                ELSEIF (len_set > len_region + 1) THEN
                    IF (set_name(len_set-len_region+1:len_set) == region(1:len_region) .AND. &
                        set_name(len_set-len_region:len_set-len_region) == ".") THEN
                        match = .TRUE.
                    END IF
                END IF
                IF (.NOT. match) CYCLE
                
                found_set = .TRUE.
                DO k = 1, this%assembly%node_sets(j)%num_nodes
                    node_id = this%assembly%node_sets(j)%node_ids(k)
                    
                    SELECT CASE (bc%bc_type)
                    CASE (BC_DISPLACEMENT)
                        ! Apply node displacement BC: u_i = u_0, use DOFLabelMap to convert label ??slot
                        DO label = bc%dof_first, bc%dof_last
                            slot = 0
                            CALL UF_DOFLabelMap_GetSlot(this%dof_label_map, label, slot)
                            IF (slot <= 0) CYCLE
                            CALL this%dof_mgr%prescribe_dof(node_id, slot, val)
                        END DO

                    CASE (BC_ENCASTRE)
                        DO dof = 1, 6
                            CALL this%dof_mgr%fix_dof(node_id, dof)
                        END DO
                    CASE (BC_PINNED)
                        DO dof = 1, 3
                            CALL this%dof_mgr%fix_dof(node_id, dof)
                        END DO
                    CASE (BC_XSYMM)
                        CALL this%dof_mgr%fix_dof(node_id, 1)
                        CALL this%dof_mgr%fix_dof(node_id, 5)
                        CALL this%dof_mgr%fix_dof(node_id, 6)
                    CASE (BC_YSYMM)
                        CALL this%dof_mgr%fix_dof(node_id, 2)
                        CALL this%dof_mgr%fix_dof(node_id, 4)
                        CALL this%dof_mgr%fix_dof(node_id, 6)
                    CASE (BC_ZSYMM)
                        CALL this%dof_mgr%fix_dof(node_id, 3)
                        CALL this%dof_mgr%fix_dof(node_id, 4)
                        CALL this%dof_mgr%fix_dof(node_id, 5)
                    END SELECT
                END DO
            END DO
            
            IF (.NOT. found_set) CYCLE
        END DO
        
    END SUBROUTINE model_apply_boundary_conditions

    !=============================================================================
    ! Apply Structural Loads (legacy interface)
    ! Theory: Applies concentrated loads F_i = f_i to global force vector F_ext
    !=============================================================================
    !> @brief Apply structural loads (CLOAD) to global force vector (legacy interface)
    !! @details Applies concentrated loads from step definition to global force vector
    !!   Theory: F_ext(eqn) = F_ext(eqn) + f_i?A(t), where eqn = f(node_id, dof_local), A(t) is amplitude
    !! @param[inout] this Model definition
    !! @param[in] step_index Step index
    !! @param[inout] F_ext External force F_ext(ndof), will be modified
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_apply_structural_loads(this, step_index, F_ext)
        CLASS(UF_ModelDef), INTENT(INOUT), TARGET :: this
        INTEGER(i4), INTENT(IN) :: step_index
        REAL(wp), INTENT(INOUT) :: F_ext(:)
        
        TYPE(UF_StepDef), POINTER :: step_ptr
        TYPE(UF_CLoadDef), POINTER :: cload
        INTEGER(i4) :: i, j, k, node_id, dof, eq
        REAL(wp) :: val, time_val, amp_val
        LOGICAL :: found_set, match
        TYPE(MD_Amp_Slot_Desc), POINTER :: amp_ptr
        TYPE(UF_NodalDOF), POINTER :: ndof_ptr
        CHARACTER(LEN=256) :: region, set_name
        INTEGER(i4) :: len_region, len_set
        
        IF (step_index < 1 .OR. step_index > this%step_mgr%num_steps) RETURN
        step_ptr => this%step_mgr%get_step(step_index)
        time_val = step_ptr%current_time
        
        DO i = 1, step_ptr%loadbc%num_cloads
            cload => step_ptr%loadbc%cloads(i)
            IF (.NOT. cload%is_active) CYCLE
            
            amp_val = 1.0_wp
            IF (LEN_TRIM(cload%amplitude_name) > 0) THEN
                 amp_ptr => this%get_amplitude(cload%amplitude_name)
                 IF (ASSOCIATED(amp_ptr)) THEN
                      amp_val = amp_ptr%evaluate(time_val)
                 END IF
            END IF
            
            val = cload%magnitude * amp_val
            
            IF (cload%node_id > 0 .AND. LEN_TRIM(cload%nset_name) == 0) THEN
                node_id = cload%node_id
                dof = cload%dof
                ndof_ptr => this%dof_mgr%get_nodal_dof(node_id)
                IF (ASSOCIATED(ndof_ptr)) THEN
                    eq = ndof_ptr%get_eqn(dof)
                    IF (eq > 0) THEN
                         F_ext(eq) = F_ext(eq) + val
                    END IF
                END IF
                CYCLE
            END IF
            
            region = TRIM(cload%nset_name)
            len_region = LEN_TRIM(region)
            IF (len_region <= 0) CYCLE
            
            found_set = .FALSE.
            DO j = 1, this%assembly%num_node_sets
                set_name = TRIM(this%assembly%node_sets(j)%name)
                len_set = LEN_TRIM(set_name)
                match = .FALSE.
                IF (len_set == len_region) THEN
                    IF (set_name(1:len_set) == region(1:len_region)) match = .TRUE.
                ELSEIF (len_set > len_region + 1) THEN
                    IF (set_name(len_set-len_region+1:len_set) == region(1:len_region) .AND. &
                        set_name(len_set-len_region:len_set-len_region) == ".") THEN
                        match = .TRUE.
                    END IF
                END IF
                IF (.NOT. match) CYCLE
                
                found_set = .TRUE.
                DO k = 1, this%assembly%node_sets(j)%num_nodes
                    node_id = this%assembly%node_sets(j)%node_ids(k)
                    dof = cload%dof
                    
                    ndof_ptr => this%dof_mgr%get_nodal_dof(node_id)
                    IF (ASSOCIATED(ndof_ptr)) THEN
                        eq = ndof_ptr%get_eqn(dof)
                        IF (eq > 0) THEN
                             F_ext(eq) = F_ext(eq) + val
                        END IF
                    END IF
                END DO
            END DO
        END DO
    END SUBROUTINE model_apply_structural_loads

    !=============================================================================
    ! Prepare Model for Analysis (legacy interface)
    ! Theory: Initializes DOF manager and field state manager for analysis
    !=============================================================================
    !> @brief Prepare model for analysis (legacy interface)
    !! @details Initializes DOF manager (eqn = f(node_id, dof_local)) and field state manager
    !!   Theory: For 3D solid elements (e.g., C3D8), 3 translational DOFs per node (UX, UY, UZ)
    !! @param[inout] this Model definition
    !! @note Legacy interface - parameters should be encapsulated in structured types
    SUBROUTINE model_prepare_analysis(this)
        CLASS(UF_ModelDef), INTENT(INOUT) :: this
        
        IF (ASSOCIATED(this%dof_mgr)) DEALLOCATE(this%dof_mgr)
        ALLOCATE(this%dof_mgr)
        ! For 3D solid elements like C3D8 we only need 3 translational DOFs per node
        CALL this%dof_mgr%init(this%assembly%total_nodes, 3)
        CALL this%dof_mgr%number_equations()
        
        CALL this%field_mgr%init(this%assembly%total_nodes, 0)
    END SUBROUTINE model_prepare_analysis

    !=============================================================================
    ! Model Utilities (merged from MD_ModelUtils)
    ! Theory: Model validation, comparison, statistics, and theory query
    !=============================================================================

    SUBROUTINE MD_Model_CheckConsistency(model, is_consistent, status)
        TYPE(MD_Model_Desc), INTENT(IN) :: model
        LOGICAL, INTENT(OUT) :: is_consistent
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        is_consistent = .TRUE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE MD_Model_CheckConsistency

    SUBROUTINE MD_Model_Compare(model1, model2, are_equal, status)
        USE MD_Model_Def, ONLY: MD_Model_Desc
        TYPE(MD_Model_Desc), INTENT(IN) :: model1, model2
        LOGICAL, INTENT(OUT) :: are_equal
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        are_equal = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE MD_Model_Compare

    FUNCTION MD_Model_GetElementCount(model, status) RESULT(count)
        TYPE(MD_Model_Desc), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: count

        CALL init_error_status(status)
        count = 0
        status%status_code = MD_MODEL_STATUS_OK
    END FUNCTION MD_Model_GetElementCount

    FUNCTION MD_Model_GetMaterialCount(model, status) RESULT(count)
        TYPE(MD_Model_Desc), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: count

        CALL init_error_status(status)
        count = 0
        status%status_code = MD_MODEL_STATUS_OK
    END FUNCTION MD_Model_GetMaterialCount

    FUNCTION MD_Model_GetNodeCount(model, status) RESULT(count)
        TYPE(MD_Model_Desc), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: count

        CALL init_error_status(status)
        count = 0
        status%status_code = MD_MODEL_STATUS_OK
    END FUNCTION MD_Model_GetNodeCount

    SUBROUTINE MD_Model_GetStatistics(model, nElems, nNodes, nMats, status)
        TYPE(MD_Model_Desc), INTENT(IN) :: model
        INTEGER(i4), INTENT(OUT) :: nElems, nNodes, nMats
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        nElems = MD_Model_GetElementCount(model, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        nNodes = MD_Model_GetNodeCount(model, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        nMats  = MD_Model_GetMaterialCount(model, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE MD_Model_GetStatistics

    SUBROUTINE MD_Model_Valid(model, status)
        TYPE(MD_Model_Desc), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE MD_Model_Valid

    SUBROUTINE MD_Theory_ExportList(unit, status)
        !! Write list of model theory modules (name | description) to unit.
        INTEGER(i4), INTENT(IN) :: unit
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i, n
        CHARACTER(LEN=128) :: name, desc

        IF (PRESENT(status)) CALL init_error_status(status)
        CALL MD_Theory_GetNumModules(n)
        DO i = 1, n
            CALL MD_Theory_QueryByIndex(i, name, desc, status)
            IF (PRESENT(status) .AND. status%status_code /= MD_MODEL_STATUS_OK) RETURN
            WRITE(unit, '(A,1X,"|",1X,A)') TRIM(name), TRIM(desc)
        END DO
    END SUBROUTINE MD_Theory_ExportList

    SUBROUTINE MD_Theory_GetNumModules(num_modules)
        !! Return number of registered model theory modules.
        INTEGER(i4), INTENT(OUT) :: num_modules
        num_modules = 5_i4
    END SUBROUTINE MD_Theory_GetNumModules

    SUBROUTINE MD_Theory_QueryByIndex(index, theory_name, description, status)
        !! Query model theory module by index (1 to GetNumModules).
        INTEGER(i4), INTENT(IN) :: index
        CHARACTER(LEN=*), INTENT(OUT) :: theory_name
        CHARACTER(LEN=*), INTENT(OUT) :: description
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)
        theory_name = ''
        description = ''
        CALL MD_Theory_Query(index, theory_name, status=status)
        IF (PRESENT(status) .AND. status%status_code /= MD_MODEL_STATUS_OK) RETURN
        CALL MD_Theory_Describe(index, description, status)
    END SUBROUTINE MD_Theory_QueryByIndex

    SUBROUTINE MD_Theory_Describe(module_id, description, status)
        !! Describe model theory module (short text).
        INTEGER(i4), INTENT(IN) :: module_id
        CHARACTER(LEN=*), INTENT(OUT) :: description
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)
        description = ''
        SELECT CASE (module_id)
        CASE (1)
            description = 'Model description (parts, materials, sections)'
        CASE (2)
            description = 'Model state (solution state)'
        CASE (3)
            description = 'Assembly (instances, constraints)'
        CASE (4)
            description = 'Step description (analysis type, BC)'
        CASE (5)
            description = 'Load and boundary conditions'
        CASE DEFAULT
            description = 'Unknown model theory module'
            IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_INVALID
        END SELECT
    END SUBROUTINE MD_Theory_Describe

    SUBROUTINE MD_Theory_Query(module_id, theory_name, layer, status)
        !! Query model theory module by id.
        INTEGER(i4), INTENT(IN) :: module_id
        CHARACTER(LEN=*), INTENT(OUT) :: theory_name
        CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: layer
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)
        theory_name = ''
        IF (PRESENT(layer)) layer = 'L3_MD'
        SELECT CASE (module_id)
        CASE (1)
            theory_name = 'MD_Model_Description'
        CASE (2)
            theory_name = 'MD_Model_State'
        CASE (3)
            theory_name = 'MD_Assembly'
        CASE (4)
            theory_name = 'MD_Step_Description'
        CASE (5)
            theory_name = 'MD_LoadBC'
        CASE DEFAULT
            theory_name = 'MD_Theory_Unknown'
            IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_INVALID
        END SELECT
    END SUBROUTINE MD_Theory_Query

    !=============================================================================
    ! Model API (merged from MD_Model_API)
    !=============================================================================
    SUBROUTINE Model_FromDesc(desc_model, md_model, status)
        TYPE(Desc_Model), INTENT(IN), TARGET :: desc_model
        TYPE(MD_Model_Desc), INTENT(INOUT) :: md_model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(MD_Model_Ctx) :: ctrl
        CALL init_error_status(status)
        IF (ASSOCIATED(md_model%desc)) THEN
            CALL md_model%desc%Init(id=desc_model%model_id, name=desc_model%name, &
                description=desc_model%cfg%description, dimensionality="3D")
        END IF
        CALL Model_FromDesc_Control(desc_model, ctrl, status)
    END SUBROUTINE Model_FromDesc

    SUBROUTINE Model_FromDesc_Control(desc_model, md_control, status)
        TYPE(Desc_Model), INTENT(IN) :: desc_model
        TYPE(MD_Model_Ctx), INTENT(OUT) :: md_control
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL md_control%Init()
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Model_FromDesc_Control

    SUBROUTINE Model_FromDesc_State(desc_model, md_state, status)
        TYPE(Desc_Model), INTENT(IN) :: desc_model
        TYPE(MD_Model_State), INTENT(OUT) :: md_state
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL md_state%Init()
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Model_FromDesc_State

    ! [VarCtx procedures moved to MD_Model_VarCtx]

    ! [VarCtx procedures moved to MD_Model_VarCtx]

END MODULE MD_Model_Lib_Core
