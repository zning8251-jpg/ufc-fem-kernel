!===============================================================================
! MODULE:  MD_Sect_Mgr
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Mgr
! BRIEF:   Section manager ?P0 Register/Query. Unified section management
!          linking elements to materials with geometric data.
!===============================================================================

MODULE MD_Sect_Mgr
!>>> UFC_L3_CONTRACT | Section/CONTRACT.md
!> Status: Production | Last verified: 2026-03-01
!> Theory: Section properties (area, inertia, thickness) | Ref: Hughes(2000) Ch.3
    USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                               IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, log_warning, log_error
    USE IF_Err_Brg, ONLY: IF_STATUS_NOT_FOUND
    USE IF_Prec_Core, ONLY: i4, i8, wp
    USE MD_Base_ObjModel, ONLY: DescBase, StateBase, CtxBase, Serializable, &
        CAT_DESC, CAT_STATE, CAT_CTX, uf_set_error_status, TreeSerializer, TreeDeserializer
    USE MD_Base_TreeIndex
    USE MD_Sect_Lib,  ONLY: UF_Section
    USE MD_Mat_Lib,   ONLY: UF_MaterialModel
    IMPLICIT NONE
    PRIVATE
    
    ! =========================================================================
    ! PRECISION: Using IF_Prec (wp, i4) ?project standard.
    ! Local SELECTED_*_KIND redefinitions removed (2026-04-26).
    ! =========================================================================

    ! =========================================================================
    ! UNIFIED Mat DESCRIPTOR - Core Innovation
    ! This structure bridges UEL (INTEGER type) and UMAT (CHARACTER cmname)
    ! =========================================================================
    TYPE, PUBLIC :: MatDesc
        ! === Mat identification (dual representation) ===
        INTEGER(i4)        :: type     = 0     ! Integer Mat code (for UEL)
        CHARACTER(LEN=80)  :: cmname      = ''    ! Character Mat name (for UMAT)
        
        ! === Deformation mode ===
        INTEGER(i4)        :: Formul = 0     ! 0=small, 1=TL, 2=UL
        
        ! === Section association ===
        INTEGER(i4)        :: section_id  = 0     ! Section ID for props
        
        ! === Element family (topo) ===
        INTEGER(i4)        :: element_family = 0     ! 0=unknown,1=continuum,2=truss,3=beam,4=shell,5=membrane
        
        ! === Tensor layout (sigma/strain components) ===
        INTEGER(i4)        :: dim         = 3     ! Geometric dimension (1,2,3)
        INTEGER(i4)        :: ndi         = 0     ! Number of direct sigma components
        INTEGER(i4)        :: nshr        = 0     ! Number of shear sigma components
        INTEGER(i4)        :: ntens       = 0     ! Total components in Voigt vector
        
        ! === Mat props cache (optional) ===
        INTEGER(i4)        :: nprops      = 0     ! Number of Mat properties
        REAL(wp)           :: props(200)  = 0.0_wp ! Mat props cache
        
        ! === Analysis type ===
        INTEGER(i4)        :: atype       = 4     ! 1=pstrain,2=pstress,3=axisym,4=3D
        
        ! === Validity flag ===
        LOGICAL            :: valid       = .FALSE.
    END TYPE MatDesc

    ! =========================================================================
    ! SECTION TYPE REGISTRY ENTRY
    ! Maps element family/dim/prefix to analysis type (atype)
    ! =========================================================================
    TYPE, PUBLIC :: SectTypeEntry
        INTEGER(i4)       :: family     = 0_i4
        INTEGER(i4)       :: dim        = 0_i4
        CHARACTER(LEN=16) :: elemPrefix = ""   !! e.g., 'CPE', 'CPS', 'CAX', 'C3D'
        INTEGER(i4)       :: atype      = 0_i4  !! atype in Section truth table
    END TYPE SectTypeEntry

    !---------------------------------------------------------------------------
    ! Public interface
    !---------------------------------------------------------------------------
    ! === Core unified interface ===
    PUBLIC :: UF_Section_GetDescriptor     ! THE unified query function
    PUBLIC :: UF_Section_RegisterFull      ! Full registration with all fields
    
    ! === Legacy compatibility ===
    PUBLIC :: UF_Section_Init
    PUBLIC :: UF_Section_Reg
    PUBLIC :: UF_Section_RegisterBatch
    PUBLIC :: UF_Section_GetMaterial
    PUBLIC :: UF_Section_GetFormulation
    PUBLIC :: UF_SECTION_GETC         ! Get character Mat name
    PUBLIC :: UF_Section_GetSectionID
    PUBLIC :: UF_Section_GetProps
    PUBLIC :: UF_Section_AddSection        ! Add section definition with props
    PUBLIC :: UF_Section_Clear
    PUBLIC :: UF_Section_IsInitialized
    PUBLIC :: UF_Section_GetCount
    
    ! === Mat name registration ===
    PUBLIC :: UF_Section_RegMatName  ! Reg type <-> cmname mapping
    PUBLIC :: UF_Section_GetMaterialName       ! Get cmname from type
    PUBLIC :: UF_Section_GetMaterialType       ! Get type from cmname

    ! === Section type registry ===
    PUBLIC :: UF_SectionTypeReg_InitDefaults
    PUBLIC :: UF_Section_RegisterAType
    PUBLIC :: UF_Section_SuggestATypeFromName
    PUBLIC :: UF_Section_SuggestATypeFromFamilyDim
    
    ! Deformation mode constants (exported for convenience)
    INTEGER(i4), PARAMETER, PUBLIC :: DEFORM_SMALL = 0   ! Small deformation
    INTEGER(i4), PARAMETER, PUBLIC :: DEFORM_TL    = 1   ! Total Lagrangian
    INTEGER(i4), PARAMETER, PUBLIC :: DEFORM_UL    = 2   ! Updated Lagrangian
    
    ! Element family constants (topo)
    INTEGER(i4), PARAMETER, PUBLIC :: ELEMENT_FAMILY   = 0
    INTEGER(i4), PARAMETER, PUBLIC :: ELEMENT_FAMILY = 1
    INTEGER(i4), PARAMETER, PUBLIC :: ELEMENT_FAMILY     = 2
    INTEGER(i4), PARAMETER, PUBLIC :: ELEMENT_FAMILY      = 3
    INTEGER(i4), PARAMETER, PUBLIC :: ELEMENT_FAMILY     = 4
    INTEGER(i4), PARAMETER, PUBLIC :: ELEMENT_FAMILY  = 5

    ! Analysis type constants
    INTEGER(i4), PARAMETER, PUBLIC :: ATYPE_PSTRAIN  = 1   ! Plane strain
    INTEGER(i4), PARAMETER, PUBLIC :: ATYPE_PSTRESS  = 2   ! Plane sigma
    INTEGER(i4), PARAMETER, PUBLIC :: ATYPE_AXISYM   = 3   ! Axisymmetric
    INTEGER(i4), PARAMETER, PUBLIC :: ATYPE_3D       = 4   ! 3D solid

    !---------------------------------------------------------------------------
    ! SECTION MODEL TYPES (from MD_Section_Type, merged)
    !---------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(DescBase) :: SectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=32) :: sectionType = ""
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => SectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => SectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => SectDesc_Init
    END TYPE SectDesc

    TYPE, PUBLIC, EXTENDS(StateBase) :: SectSta
        INTEGER(i4) :: id = 0_i4
        LOGICAL :: isActive = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => SectSta_RegLayout
        PROCEDURE, PUBLIC :: Ensure => SectSta_Ensure
        PROCEDURE, PUBLIC :: Init => SectSta_Init
    END TYPE SectSta

    TYPE, PUBLIC, EXTENDS(CtxBase) :: SectCtx
        INTEGER(i4) :: id = 0_i4
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => SectCtx_RegLayout
        PROCEDURE, PUBLIC :: Ensure => SectCtx_Ensure
        PROCEDURE, PUBLIC :: Init => SectCtx_Init
    END TYPE SectCtx

    TYPE, PUBLIC, EXTENDS(DescBase) :: SectAssignDesc
        INTEGER(i4)       :: id   = 0
        INTEGER(i4)       :: secId    = 0
        CHARACTER(len=64) :: region   = ""
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => SectAssignDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure    => SectAssignDesc_Ensure
        PROCEDURE, PUBLIC :: Init      => SectAssignDesc_Init
    END TYPE SectAssignDesc

    TYPE, PUBLIC, EXTENDS(DescBase) :: SolidSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=64) :: materialName = ""
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => SolidSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => SolidSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => SolidSectDesc_Init
        PROCEDURE, PUBLIC :: Valid => SolidSectDesc_Valid
    END TYPE SolidSectDesc

    TYPE, PUBLIC, EXTENDS(DescBase) :: ShellSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=64) :: materialName = ""
        REAL(wp) :: thickness = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => ShellSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => ShellSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => ShellSectDesc_Init
        PROCEDURE, PUBLIC :: Valid => ShellSectDesc_Valid
    END TYPE ShellSectDesc

    TYPE, PUBLIC, EXTENDS(DescBase) :: BeamSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=64) :: materialName = ""
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: I11 = 0.0_wp
        REAL(wp) :: I22 = 0.0_wp
        REAL(wp) :: I12 = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => BeamSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => BeamSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => BeamSectDesc_Init
        PROCEDURE, PUBLIC :: Valid => BeamSectDesc_Valid
    END TYPE BeamSectDesc

    !---------------------------------------------------------------------------
    ! Advanced Section Types (Phase C Tier 2)
    !---------------------------------------------------------------------------
    
    !! Cohesive Section Descriptor (interface damage)
    TYPE, PUBLIC, EXTENDS(DescBase) :: CohesiveSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=64) :: materialName = ""  ! Cohesive behavior Mat
        REAL(wp) :: thickness = 0.0_wp           ! Initial thickness
        CHARACTER(len=32) :: response = ""       ! TRACTION or CONTINUUM
        INTEGER(i4) :: nIntPts = 2_i4            ! Integration points through thickness
        REAL(wp) :: initialGap = 0.0_wp          ! Initial gap (for contact)
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => CohesiveSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => CohesiveSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => CohesiveSectDesc_Init
    END TYPE CohesiveSectDesc
    
    !! Gasket Section Descriptor (seal simulation)
    TYPE, PUBLIC, EXTENDS(DescBase) :: GasketSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=64) :: materialName = ""  ! Gasket behavior Mat
        REAL(wp) :: initialThickness = 0.0_wp   ! Initial gasket thickness
        REAL(wp) :: initialGap = 0.0_wp         ! Initial gap
        CHARACTER(len=32) :: nodal_thickness = "" ! "NO" or "YES"
        INTEGER(i4) :: nDirections = 3_i4        ! Number of thickness directions
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => GasketSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => GasketSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => GasketSectDesc_Init
    END TYPE GasketSectDesc
    
    !! Connector Section Descriptor (mechanical connection)
    TYPE, PUBLIC, EXTENDS(DescBase) :: ConnectorSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=32) :: connectorType = "" ! BEAM, HINGE, SLOT, etc.
        CHARACTER(len=64) :: behaviorName = ""  ! Connector behavior name
        REAL(wp) :: stiffness(6) = 0.0_wp       ! Stiffness in 6 DOFs
        REAL(wp) :: damping(6) = 0.0_wp         ! Damping in 6 DOFs
        LOGICAL :: rigid(6) = .FALSE.           ! Rigid flags for each DOF
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => ConnectorSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => ConnectorSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => ConnectorSectDesc_Init
    END TYPE ConnectorSectDesc
    
    !! Surface Section Descriptor (surface elements)
    TYPE, PUBLIC, EXTENDS(DescBase) :: SurfaceSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        REAL(wp) :: density = 0.0_wp             ! Surface density (mass per area)
        REAL(wp) :: thickness = 0.0_wp           ! Thickness (for visualization)
        CHARACTER(len=32) :: fluidBehavior = "" ! Fluid property name (if applicable)
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => SurfaceSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => SurfaceSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => SurfaceSectDesc_Init
    END TYPE SurfaceSectDesc
    
    !! Membrane Section Descriptor (thin film)
    TYPE, PUBLIC, EXTENDS(DescBase) :: MemSectDesc
        INTEGER(i4) :: id = 0_i4
        CHARACTER(len=64) :: name = ""
        CHARACTER(len=64) :: materialName = ""
        REAL(wp) :: thickness = 0.0_wp           ! Membrane thickness
        INTEGER(i4) :: nIntPts = 3_i4            ! Integration points
        LOGICAL :: noCompression = .FALSE.       ! No compression flag
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => MemSectDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure => MemSectDesc_Ensure
        PROCEDURE, PUBLIC :: Init => MemSectDesc_Init
    END TYPE MemSectDesc

    !---------------------------------------------------------------------------
    ! SectTree (from MD_Section_Tree, merged)
    !---------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(SectDesc) :: SectTree
        INTEGER(i4) :: node_id = 0_i4
        INTEGER(i4) :: parent_id = 0_i4
        LOGICAL :: is_active = .true.
        LOGICAL :: is_visible = .true.
        TYPE(IndexMgr) :: index_mgr
        TYPE(LazyIndexMgr) :: lazy_index
        TYPE(BatchOpMgr) :: batch_mgr
        TYPE(PathResolver) :: path_resolver
        LOGICAL :: tree_initialize = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: GetID => SectTree_GetID
        PROCEDURE, PUBLIC :: GetName => SectTree_GetName
        PROCEDURE, PUBLIC :: GetType => SectTree_GetType
        PROCEDURE, PUBLIC :: GetParentID => SectTree_GetParentID
        PROCEDURE, PUBLIC :: GetByPath => SectTree_GetByPath
        PROCEDURE, PUBLIC :: GetFullPath => SectTree_GetFullPath
        PROCEDURE, PUBLIC :: InitTree => SectTree_InitTree
        PROCEDURE, PUBLIC :: DestroyTree => SectTree_DestroyTree
        PROCEDURE, PUBLIC :: RebuildIndex => SectTree_RebuildIndex
        PROCEDURE, PUBLIC :: ValidateTree => SectTree_ValidateTree
        PROCEDURE, PUBLIC :: Serialize => SectTree_Serialize
        PROCEDURE, PUBLIC :: Deserialize => SectTree_Deserialize
        PROCEDURE, PUBLIC :: BeginBatch => SectTree_BeginBatch
        PROCEDURE, PUBLIC :: EndBatch => SectTree_EndBatch
    END TYPE SectTree

    !---------------------------------------------------------------------------
    ! Section Ops Types (from MD_Section_Ops, merged)
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_SectionProps
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: I11 = 0.0_wp
        REAL(wp) :: I22 = 0.0_wp
        REAL(wp) :: I12 = 0.0_wp
        REAL(wp) :: I33 = 0.0_wp
        REAL(wp) :: centroid(2) = 0.0_wp
        REAL(wp) :: principal_momen(2) = 0.0_wp
        REAL(wp) :: principal_angle = 0.0_wp
        REAL(wp) :: section_modulus(2) = 0.0_wp
        REAL(wp) :: gyration_radius(2) = 0.0_wp
    END TYPE MD_SectionProps

    TYPE, PUBLIC :: MD_SectionOrientation
        REAL(wp) :: angle = 0.0_wp
        REAL(wp) :: axis(3) = 0.0_wp
        LOGICAL :: defined = .false.
    END TYPE MD_SectionOrientation

    TYPE, PUBLIC :: MD_SectionCompLayer
        INTEGER(i4) :: id = 0
        REAL(wp) :: thickness = 0.0_wp
        REAL(wp) :: angle = 0.0_wp
        INTEGER(i4) :: integrationpoin = 3
    END TYPE MD_SectionCompLayer

    TYPE, PUBLIC :: MD_SectionCompositeProperties
        INTEGER(i4) :: numLayers = 0
        REAL(wp) :: totalThickness = 0.0_wp
        REAL(wp) :: ABD(6,6) = 0.0_wp
        REAL(wp) :: extensional_sti(3,3) = 0.0_wp
        REAL(wp) :: cpl_stiffness(3,3) = 0.0_wp
        REAL(wp) :: bending_stiffne(3,3) = 0.0_wp
    END TYPE MD_SectionCompositeProperties

    !---------------------------------------------------------------------------
    ! Section data structure
    !---------------------------------------------------------------------------
    TYPE :: UF_SECTION_DATA
        INTEGER(i4) :: section_id       = 0    ! Section ID
        INTEGER(i4) :: type          = 0    ! Mat type code
        INTEGER(i4) :: nprops           = 0    ! Number of section props
        REAL(wp)    :: props(50)        = 0.0_wp  ! Section props (thickness, etc.)
        CHARACTER(LEN=80) :: name       = ''   ! Section name
    END TYPE UF_SECTION_DATA
    
    !---------------------------------------------------------------------------
    ! Element-Section mapping entry
    !---------------------------------------------------------------------------
    TYPE :: UF_ELEM_SECTION_MAP
        INTEGER(i4) :: jelem            = 0    ! Element number
        INTEGER(i4) :: section_id       = 0    ! Associated section ID
        INTEGER(i4) :: type          = 0    ! Direct Mat type (for quick access)
    END TYPE UF_ELEM_SECTION_MAP
    
    !---------------------------------------------------------------------------
    ! Module variables - Global registry
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: MAX_SECTIONS = 1000
    INTEGER(i4), PARAMETER :: MAX_ELEMENTS1 = 1000000
    INTEGER(i4), PARAMETER :: maxMats = 200    ! Max registered Mat type
    INTEGER(i4), PARAMETER :: MAX_SECTION_TYP = 128_i4
    
    ! Direct Element -> property mapping (fastest lookup)
    INTEGER(i4), ALLOCATABLE, SAVE :: element_materia(:)      ! Mat type code
    INTEGER(i4), ALLOCATABLE, SAVE :: element_section(:)      ! Section ID
    INTEGER(i4), ALLOCATABLE, SAVE :: element_formula(:)  ! Deformation mode (0=small, 1=TL, 2=UL)
    CHARACTER(LEN=80), ALLOCATABLE, SAVE :: element_cmname(:) ! Mat name (CHARACTER for UMAT)
    INTEGER(i4), ALLOCATABLE, SAVE :: element_atype(:)        ! Analysis type (1-4)
    INTEGER(i4), ALLOCATABLE, SAVE :: element_family(:)       ! Element family (topo)
    INTEGER(i4), ALLOCATABLE, SAVE :: element_dim(:)          ! Geometric dimension (1,2,3)
    INTEGER(i4), ALLOCATABLE, SAVE :: element_ndi(:)          ! Number of direct sigma components
    INTEGER(i4), ALLOCATABLE, SAVE :: element_nshr(:)         ! Number of shear sigma components
    INTEGER(i4), ALLOCATABLE, SAVE :: element_ntens(:)        ! Stress/strain component count (NTENS)
    
    ! Mat type <-> Mat name mapping (global, not per-Element)
    INTEGER(i4), SAVE :: n_materials = 0
    INTEGER(i4), SAVE :: material_type_l(maxMats) = 0
    CHARACTER(LEN=80), SAVE :: mat_name_list(maxMats) = ''
    
    ! Section definitions
    TYPE(UF_SECTION_DATA), ALLOCATABLE, SAVE :: sections(:)
    INTEGER(i4), SAVE :: n_sections = 0
    
    ! Section type registry
    TYPE(SectTypeEntry), ALLOCATABLE, SAVE :: section_type_re(:)
    LOGICAL, SAVE :: section_type_in = .false.
    
    ! Registry state
    INTEGER(i4), SAVE :: max_elem_num = 0
    LOGICAL, SAVE :: init = .FALSE.
    
CONTAINS

    !=============================================================================
    !> @brief Initialize section registry (legacy interface)
    !! @details Allocates element-to-section mapping arrays
    !! @param[in] max_elements Maximum number of elements n_max ? ?(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE UF_Section_Init(max_elements)
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_elements
        
        INTEGER(i4) :: n_alloc
        
        ! Determine allocation size
        IF (PRESENT(max_elements)) THEN
            n_alloc = max_elements
        ELSE
            n_alloc = MAX_ELEMENTS1
        END IF
        
        ! Clear existing if already initialized
        IF (init) CALL UF_Section_Clear()
        
        ! Allocate arrays
        ALLOCATE(element_materia(n_alloc))
        ALLOCATE(element_section(n_alloc))
        ALLOCATE(element_formula(n_alloc))
        ALLOCATE(element_cmname(n_alloc))
        ALLOCATE(element_atype(n_alloc))
        ALLOCATE(element_family(n_alloc))
        ALLOCATE(element_dim(n_alloc))
        ALLOCATE(element_ndi(n_alloc))
        ALLOCATE(element_nshr(n_alloc))
        ALLOCATE(element_ntens(n_alloc))
        ALLOCATE(sections(MAX_SECTIONS))
        
        ! Init to zero/default
        element_materia = 0
        element_section = 0
        element_formula = DEFORM_SMALL  ! Default to small deformation
        element_cmname = ''
        element_atype = 4    ! Default to 3D
        element_family = ELEMENT_FAMILY
        element_dim    = 3
        element_ndi    = 0
        element_nshr   = 0
        element_ntens  = 0   ! Will be set by Section registry / Element family mapping
        n_sections = 0
        n_materials = 0
        max_elem_num = n_alloc
        init = .TRUE.
        
        ! Init section type registry
        CALL UF_SectionTypeReg_InitDefaults()
        
    END SUBROUTINE UF_Section_Init
    
    !=============================================================================
    !> @brief Register element with material type and formulation (legacy interface)
    !! @details Maps element jelem ? ?to material type and deformation mode
    !! Theory: Element-to-section mapping: jelem ?(type, section_id, Formul)
    !! @param[in] jelem Element number jelem ? ?
    !! @param[in] type Material type code ? ?
    !! @param[in] section_id Section ID ? ?(optional)
    !! @param[in] Formul Deformation mode ? ? 0=small, 1=TL, 2=UL (optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE UF_Section_Reg(jelem, type, section_id, Formul)
        INTEGER(i4), INTENT(IN) :: jelem
        INTEGER(i4), INTENT(IN) :: type
        INTEGER(i4), INTENT(IN), OPTIONAL :: section_id
        INTEGER(i4), INTENT(IN), OPTIONAL :: Formul
        
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=100) :: msg
        
        ! Auto-initialize if needed
        IF (.NOT. init) CALL UF_Section_Init()
        
        ! Bounds check
        IF (jelem < 1 .OR. jelem > max_elem_num) THEN
            CALL init_error_status(status)
            WRITE(msg,'(A,I0,A,I0)') 'UF_Section_Reg: Element ', jelem, &
                                       ' exceeds max ', max_elem_num
            CALL log_warning(TRIM(msg))
            RETURN
        END IF
        
        ! Store mapping
        element_materia(jelem) = type
        element_family(jelem)  = ELEMENT_FAMILY
        
        IF (PRESENT(section_id)) THEN
            element_section(jelem) = section_id
        ELSE
            element_section(jelem) = 0
        END IF
        
        IF (PRESENT(Formul)) THEN
            element_formula(jelem) = Formul
        ELSE
            element_formula(jelem) = DEFORM_SMALL
        END IF
        
    END SUBROUTINE UF_Section_Reg
    
    !===========================================================================
    ! Reg batch of elements with same Mat type
    ! Useful for Element sets (ELSET)
    !===========================================================================
    SUBROUTINE UF_Section_RegisterBatch(element_list, n_element, type, section_id, Formul)
        INTEGER(i4), INTENT(IN) :: element_list(:)
        INTEGER(i4), INTENT(IN) :: n_element
        INTEGER(i4), INTENT(IN) :: type
        INTEGER(i4), INTENT(IN), OPTIONAL :: section_id
        INTEGER(i4), INTENT(IN), OPTIONAL :: Formul
        
        INTEGER(i4) :: i, jelem, sec_id, form
        
        ! Auto-initialize if needed
        IF (.NOT. init) CALL UF_Section_Init()
        
        sec_id = 0
        form = DEFORM_SMALL
        IF (PRESENT(section_id)) sec_id = section_id
        IF (PRESENT(Formul)) form = Formul
        
        DO i = 1, n_element
            jelem = element_list(i)
            IF (jelem >= 1 .AND. jelem <= max_elem_num) THEN
                element_materia(jelem) = type
                element_section(jelem) = sec_id
                element_formula(jelem) = form
                element_family(jelem)  = ELEMENT_FAMILY
            END IF
        END DO
        
    END SUBROUTINE UF_Section_RegisterBatch
    
    !===========================================================================
    ! Full registration with all fields
    !===========================================================================
    SUBROUTINE UF_Section_RegisterFull(jelem, type, Formul, section_id, &
                                       atype, element_family, ntens, ndi, nshr)
        INTEGER(i4), INTENT(IN) :: jelem
        INTEGER(i4), INTENT(IN) :: type
        INTEGER(i4), INTENT(IN) :: Formul
        INTEGER(i4), INTENT(IN) :: section_id
        INTEGER(i4), INTENT(IN) :: atype
        INTEGER(i4), INTENT(IN) :: element_family
        INTEGER(i4), INTENT(IN) :: ntens
        INTEGER(i4), INTENT(IN) :: ndi
        INTEGER(i4), INTENT(IN) :: nshr
        
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=100) :: msg
        
        ! Auto-initialize if needed
        IF (.NOT. init) CALL UF_Section_Init()
        
        ! Bounds check
        IF (jelem < 1 .OR. jelem > max_elem_num) THEN
            CALL init_error_status(status)
            WRITE(msg,'(A,I0,A,I0)') 'UF_Section_RegisterFull: Element ', jelem, &
                                       ' exceeds max ', max_elem_num
            CALL log_warning(TRIM(msg))
            RETURN
        END IF
        
        ! Store all fields
        element_materia(jelem) = type
        element_section(jelem) = section_id
        element_formula(jelem) = Formul
        element_atype(jelem) = atype
        element_family(jelem) = element_family
        element_ntens(jelem) = ntens
        element_ndi(jelem) = ndi
        element_nshr(jelem) = nshr
        
        ! Infer dimension from family and atype if not set
        IF (element_dim(jelem) == 0) THEN
            SELECT CASE (atype)
            CASE (ATYPE_PSTRAIN, ATYPE_PSTRESS, ATYPE_AXISYM)
                element_dim(jelem) = 2
            CASE (ATYPE_3D)
                element_dim(jelem) = 3
            CASE DEFAULT
                element_dim(jelem) = 3
            END SELECT
        END IF
        
        ! Set cmname from type if registered
        CALL UF_Section_GetMaterialName(type, element_cmname(jelem))
        
    END SUBROUTINE UF_Section_RegisterFull
    
    !===========================================================================
    ! Get Mat type for an Element
    !===========================================================================
    FUNCTION UF_Section_GetMaterial(jelem) RESULT(type)
        INTEGER(i4), INTENT(IN) :: jelem
        INTEGER(i4) :: type
        
        ! Return 0 if not initialized or out of bounds
        IF (.NOT. init) THEN
            type = 0
            RETURN
        END IF
        
        IF (jelem < 1 .OR. jelem > max_elem_num) THEN
            type = 0
            RETURN
        END IF
        
        type = element_materia(jelem)
        
    END FUNCTION UF_Section_GetMaterial
    
    !===========================================================================
    ! Get Formul (deformation mode) for an Element
    !===========================================================================
    FUNCTION UF_Section_GetFormulation(jelem) RESULT(Formul)
        INTEGER(i4), INTENT(IN) :: jelem
        INTEGER(i4) :: Formul
        
        IF (.NOT. init) THEN
            Formul = DEFORM_SMALL
            RETURN
        END IF
        
        IF (jelem < 1 .OR. jelem > max_elem_num) THEN
            Formul = DEFORM_SMALL
            RETURN
        END IF
        
        Formul = element_formula(jelem)
        
    END FUNCTION UF_Section_GetFormulation
    
    !===========================================================================
    ! Get section ID for an Element
    !===========================================================================
    FUNCTION UF_Section_GetSectionID(jelem) RESULT(section_id)
        INTEGER(i4), INTENT(IN) :: jelem
        INTEGER(i4) :: section_id
        
        IF (.NOT. init) THEN
            section_id = 0
            RETURN
        END IF
        
        IF (jelem < 1 .OR. jelem > max_elem_num) THEN
            section_id = 0
            RETURN
        END IF
        
        section_id = element_section(jelem)
        
    END FUNCTION UF_Section_GetSectionID
    
    !===========================================================================
    ! Get section props (e.g., thickness for shells)
    !===========================================================================
    SUBROUTINE UF_Section_GetProps(section_id, props, nprops)
        INTEGER(i4), INTENT(IN) :: section_id
        REAL(wp), INTENT(OUT) :: props(:)
        INTEGER(i4), INTENT(OUT) :: nprops
        
        INTEGER(i4) :: i
        
        props = 0.0_wp
        nprops = 0
        
        IF (.NOT. init) RETURN
        IF (section_id < 1 .OR. section_id > n_sections) RETURN
        
        nprops = sections(section_id)%nprops
        DO i = 1, MIN(nprops, SIZE(props))
            props(i) = sections(section_id)%props(i)
        END DO
        
    END SUBROUTINE UF_Section_GetProps
    
    !===========================================================================
    ! Add a section definition
    !===========================================================================
    SUBROUTINE UF_Section_AddSection(type, props, nprops, name, section_id)
        INTEGER(i4), INTENT(IN) :: type
        REAL(wp), INTENT(IN) :: props(:)
        INTEGER(i4), INTENT(IN) :: nprops
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        INTEGER(i4), INTENT(OUT) :: section_id
        
        INTEGER(i4) :: i
        
        ! Auto-initialize if needed
        IF (.NOT. init) CALL UF_Section_Init()
        
        ! Check capacity
        IF (n_sections >= MAX_SECTIONS) THEN
            section_id = -1
            RETURN
        END IF
        
        ! Add new section
        n_sections = n_sections + 1
        section_id = n_sections
        
        sections(section_id)%section_id = section_id
        sections(section_id)%type = type
        sections(section_id)%nprops = MIN(nprops, 50)
        
        DO i = 1, sections(section_id)%nprops
            sections(section_id)%props(i) = props(i)
        END DO
        
        IF (PRESENT(name)) THEN
            sections(section_id)%name = name
        ELSE
            WRITE(sections(section_id)%name, '(A,I0)') 'SECTION-', section_id
        END IF
        
    END SUBROUTINE UF_Section_AddSection
    
    !===========================================================================
    ! Clear all registrations
    !===========================================================================
    SUBROUTINE UF_Section_Clear()
        
        IF (ALLOCATED(element_materia)) DEALLOCATE(element_materia)
        IF (ALLOCATED(element_section)) DEALLOCATE(element_section)
        IF (ALLOCATED(element_formula)) DEALLOCATE(element_formula)
        IF (ALLOCATED(element_cmname)) DEALLOCATE(element_cmname)
        IF (ALLOCATED(element_atype)) DEALLOCATE(element_atype)
        IF (ALLOCATED(element_family)) DEALLOCATE(element_family)
        IF (ALLOCATED(element_dim))    DEALLOCATE(element_dim)
        IF (ALLOCATED(element_ndi))    DEALLOCATE(element_ndi)
        IF (ALLOCATED(element_nshr))   DEALLOCATE(element_nshr)
        IF (ALLOCATED(element_ntens))  DEALLOCATE(element_ntens)
        IF (ALLOCATED(sections))    DEALLOCATE(sections)
        IF (ALLOCATED(section_type_re)) DEALLOCATE(section_type_re)
        
        n_sections = 0
        n_materials = 0
        max_elem_num = 0
        init = .FALSE.
        section_type_in = .FALSE.
        
    END SUBROUTINE UF_Section_Clear
    
    !===========================================================================
    ! Check if registry is initialized
    !===========================================================================
    FUNCTION UF_Section_IsInitialized() RESULT(initialized)
        LOGICAL :: initialized
        initialized = init
    END FUNCTION UF_Section_IsInitialized
    
    !===========================================================================
    ! Get number of registered sections
    !===========================================================================
    FUNCTION UF_Section_GetCount() RESULT(count)
        INTEGER(i4) :: count
        count = n_sections
    END FUNCTION UF_Section_GetCount
    
    !===========================================================================
    ! === NEW UNIFIED INTERFACE FUNCTIONS ===
    !===========================================================================
    
    !===========================================================================
    ! Reg Mat type <-> Mat name mapping
    ! This is a GLOBAL mapping, not per-Element
    !===========================================================================
    SUBROUTINE UF_Section_RegMatName(type, cmname)
        INTEGER(i4), INTENT(IN) :: type
        CHARACTER(LEN=*), INTENT(IN) :: cmname
        
        INTEGER(i4) :: i
        
        ! Check if already registered
        DO i = 1, n_materials
            IF (material_type_l(i) == type) THEN
                mat_name_list(i) = cmname
                RETURN
            END IF
        END DO
        
        ! Add new registration
        IF (n_materials < maxMats) THEN
            n_materials = n_materials + 1
            material_type_l(n_materials) = type
            mat_name_list(n_materials) = cmname
        END IF
        
    END SUBROUTINE UF_Section_RegMatName
    
    !===========================================================================
    ! Get cmname from type
    !===========================================================================
    SUBROUTINE UF_Section_GetMaterialName(type, cmname)
        INTEGER(i4), INTENT(IN) :: type
        CHARACTER(LEN=*), INTENT(OUT) :: cmname
        
        INTEGER(i4) :: i
        
        cmname = ''
        
        DO i = 1, n_materials
            IF (material_type_l(i) == type) THEN
                cmname = mat_name_list(i)
                RETURN
            END IF
        END DO
        
    END SUBROUTINE UF_Section_GetMaterialName
    
    !===========================================================================
    ! Get type from cmname
    !===========================================================================
    FUNCTION UF_Section_GetMaterialType(cmname) RESULT(type)
        CHARACTER(LEN=*), INTENT(IN) :: cmname
        INTEGER(i4) :: type
        
        INTEGER(i4) :: i
        
        type = 0
        
        DO i = 1, n_materials
            IF (TRIM(mat_name_list(i)) == TRIM(cmname)) THEN
                type = material_type_l(i)
                RETURN
            END IF
        END DO
        
    END FUNCTION UF_Section_GetMaterialType
    
    !===========================================================================
    ! Get cmname for an Element
    !===========================================================================
    SUBROUTINE UF_SECTION_GETC(jelem, cmname)
        INTEGER(i4), INTENT(IN) :: jelem
        CHARACTER(LEN=*), INTENT(OUT) :: cmname
        
        INTEGER(i4) :: type
        
        cmname = ''
        
        IF (.NOT. init) RETURN
        IF (jelem < 1 .OR. jelem > max_elem_num) RETURN
        
        type = element_materia(jelem)
        CALL UF_Section_GetMaterialName(type, cmname)
        
    END SUBROUTINE UF_SECTION_GETC
    
    !=============================================================================
    !> @brief Get complete material descriptor for element (unified query function)
    !! @details Retrieves unified MatDesc structure containing type, cmname, Formul, section_id
    !!   Theory: Unified descriptor bridges INTEGER type and CHARACTER cmname representations
    !! @param[in] jelem Element number jelem ? ?
    !! @return Material descriptor MatDesc with all properties
    !! @note This is the unified query function - replaces individual getter functions
    !=============================================================================
    FUNCTION UF_Section_GetDescriptor(jelem) RESULT(desc)
        INTEGER(i4), INTENT(IN) :: jelem
        TYPE(MatDesc) :: desc
        
        INTEGER(i4) :: section_id, i
        
        ! Init to defaults
        desc%type = 0
        desc%cmname = ''
        desc%Formul = DEFORM_SMALL
        desc%section_id = 0
        desc%element_family = ELEMENT_FAMILY
        desc%dim = 3
        desc%ndi = 0
        desc%nshr = 0
        desc%ntens = 0
        desc%nprops = 0
        desc%props = 0.0_wp
        desc%atype = ATYPE_3D
        desc%valid = .FALSE.
        
        ! Check if initialized
        IF (.NOT. init) RETURN
        
        ! Bounds check
        IF (jelem < 1 .OR. jelem > max_elem_num) RETURN
        
        ! Populate descriptor from registry
        desc%type = element_materia(jelem)
        desc%cmname = element_cmname(jelem)
        desc%Formul = element_formula(jelem)
        desc%section_id = element_section(jelem)
        desc%element_family = element_family(jelem)
        desc%dim = element_dim(jelem)
        desc%ndi = element_ndi(jelem)
        desc%nshr = element_nshr(jelem)
        desc%ntens = element_ntens(jelem)
        desc%atype = element_atype(jelem)
        
        ! Load section props if available
        section_id = element_section(jelem)
        IF (section_id > 0 .AND. section_id <= n_sections) THEN
            desc%nprops = sections(section_id)%nprops
            DO i = 1, MIN(desc%nprops, 200)
                desc%props(i) = sections(section_id)%props(i)
            END DO
        END IF
        
        ! Mark as valid if type is set
        IF (desc%type > 0) desc%valid = .TRUE.
        
    END FUNCTION UF_Section_GetDescriptor
    
    !===========================================================================
    ! === SECTION TYPE REGISTRY FUNCTIONS ===
    !===========================================================================
    
    !===========================================================================
    ! Init default mappings: CPE/CPS/CAX/C3D
    !===========================================================================
    SUBROUTINE UF_Se_InitDefaults()
        TYPE(ErrorStatusType) :: status
        
        IF (.NOT. section_type_in) THEN
            CALL UF_Section_RegisterAType(0_i4, 2_i4, 'CPE', ATYPE_PSTRAIN, status)  ! Plane Strain
            CALL UF_Section_RegisterAType(0_i4, 2_i4, 'CPS', ATYPE_PSTRESS, status)  ! Plane Stress
            CALL UF_Section_RegisterAType(0_i4, 2_i4, 'CAX', ATYPE_AXISYM, status)   ! Axisymmetric
            CALL UF_Section_RegisterAType(0_i4, 3_i4, 'C3D', ATYPE_3D, status)        ! 3D Solid
            
            section_type_in = .TRUE.
        END IF
        
    END SUBROUTINE UF_SectionTypeReg_InitDefaults
    
    !===========================================================================
    ! Reg a name -> atype mapping
    !   - family: Physics family (UF_Family_*), 0 for all
    !   - dim   : Spatial dimension (2/3), 0 for all
    !   - elemPrefix: Element name prefix (case-insensitive)
    !===========================================================================
    SUBROUTINE UF_Section_RegisterAType(family, dim, elemPrefix, atype, status)
        INTEGER(i4),       INTENT(IN)  :: family, dim, atype
        CHARACTER(LEN=*),  INTENT(IN)  :: elemPrefix
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(SectTypeEntry), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: n

        CALL init_error_status(status)

        IF (.NOT. ALLOCATED(section_type_re)) THEN
            ALLOCATE(section_type_re(0))
        END IF

        n = SIZE(section_type_re)
        ALLOCATE(tmp(n+1))
        IF (n > 0) tmp(1:n) = section_type_re

        tmp(n+1)%family     = family
        tmp(n+1)%dim        = dim
        tmp(n+1)%elemPrefix = to_upper(TRIM(elemPrefix))
        tmp(n+1)%atype      = atype

        CALL MOVE_ALLOC(tmp, section_type_re)

        status%status_code = IF_STATUS_OK

    END SUBROUTINE UF_Section_RegisterAType
    
    !===========================================================================
    ! Suggest atype based on family / dim / Element name
    !   - Priority: match entries with both family and dim
    !   - If family or dim is 0, it's a wildcard
    !   - Fallback by dim: 2D -> 1 (Plane Strain), 3D -> 4 (3D Solid)
    !===========================================================================
    SUBROUTINE UF_Se_SuggestATypeFromName(family, dim, elemName, atype)
        INTEGER(i4),      INTENT(IN)  :: family, dim
        CHARACTER(LEN=*), INTENT(IN)  :: elemName
        INTEGER(i4),      INTENT(OUT) :: atype

        CHARACTER(LEN=LEN(elemName)) :: name_up
        INTEGER(i4) :: i, fam_i, dim_i

        TYPE(ErrorStatusType) :: status

        ! Ensure default mappings are registered
        IF (.NOT. section_type_in) THEN
            CALL UF_SectionTypeReg_InitDefaults()
        END IF

        atype   = 0_i4
        name_up = to_upper(elemName)

        IF (.NOT. ALLOCATED(section_type_re)) THEN
            ! Fallback: no registry
            IF (dim == 3_i4) THEN
                atype = ATYPE_3D
            ELSE
                atype = ATYPE_PSTRAIN
            END IF
            RETURN
        END IF

        DO i = 1, SIZE(section_type_re)
            fam_i = section_type_re(i)%family
            dim_i = section_type_re(i)%dim

            IF (fam_i /= 0_i4 .AND. fam_i /= family) CYCLE
            IF (dim_i /= 0_i4 .AND. dim_i /= dim)    CYCLE

            IF (LEN_TRIM(section_type_re(i)%elemPrefix) > 0) THEN
                IF (LEN_TRIM(name_up) >= LEN_TRIM(section_type_re(i)%elemPrefix)) THEN
                    IF (name_up(1:LEN_TRIM(section_type_re(i)%elemPrefix)) == &
                        section_type_re(i)%elemPrefix) THEN
                        atype = section_type_re(i)%atype
                        RETURN
                    END IF
                END IF
            END IF
        END DO

        ! Fallback strategy when no match is found
        IF (dim == 3_i4) THEN
            atype = ATYPE_3D
        ELSE
            atype = ATYPE_PSTRAIN
        END IF

    END SUBROUTINE UF_Section_SuggestATypeFromName
    
    !===========================================================================
    ! Suggest atype based on family and dimension
    !===========================================================================
    SUBROUTINE UF_Se_SuggestATypeFromFamily(family, dim, atype)
        INTEGER(i4), INTENT(IN)  :: family, dim
        INTEGER(i4), INTENT(OUT) :: atype
        
        ! Default fallback
        atype = ATYPE_3D
        
        SELECT CASE (family)
        CASE (ELEMENT_FAMILY)
            SELECT CASE (dim)
            CASE (1)
                atype = ATYPE_PSTRAIN
            CASE (2)
                atype = ATYPE_PSTRAIN
            CASE (3)
                atype = ATYPE_3D
            CASE DEFAULT
                atype = ATYPE_3D
            END SELECT
            
        CASE (ELEMENT_FAMILY, ELEMENT_FAMILY)
            atype = ATYPE_PSTRESS
            
        CASE (ELEMENT_FAMILY, ELEMENT_FAMILY)
            atype = ATYPE_PSTRAIN
            
        CASE DEFAULT
            atype = ATYPE_3D
        END SELECT
        
    END SUBROUTINE UF_Section_SuggestATypeFromFamilyDim
    
    !===========================================================================
    ! Helper: Convert string to uppercase
    !===========================================================================
    FUNCTION to_upper(str) RESULT(upper_str)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=LEN(str)) :: upper_str
        
        INTEGER(i4) :: i, ic
        
        upper_str = str
        
        DO i = 1, LEN_TRIM(str)
            ic = IACHAR(str(i:i))
            IF (ic >= IACHAR('a') .AND. ic <= IACHAR('z')) THEN
                upper_str(i:i) = ACHAR(ic - 32)
            END IF
        END DO
        
    END FUNCTION to_upper

    !===========================================================================
    ! Section Type procedures (from MD_Section_Type, merged)
    !===========================================================================
    SUBROUTINE SectDesc_Init(this, id, name, sectionType)
        CLASS(SectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, sectionType
        this%category = CAT_DESC
        this%typeName = 'DESC::SECTION'
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(sectionType)) this%sectionType = sectionType
    END SUBROUTINE SectDesc_Init

    SUBROUTINE SectDesc_RegLayout(this)
        CLASS(SectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(3)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        fields(3)%field_name = 'sectionType'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 32
        fields(3)%offset_bytes = offset
        offset = offset + 32
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectDesc_RegLayout")
    END SUBROUTINE SectDesc_RegLayout

    SUBROUTINE SectDesc_Ensure(this)
        CLASS(SectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_SECTIONDESC_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectDesc_Ensure")
    END SUBROUTINE SectDesc_Ensure

    SUBROUTINE SectSta_Init(this, id)
        CLASS(SectSta), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        this%category = CAT_STATE
        IF (PRESENT(id)) this%cfg%id = id
    END SUBROUTINE SectSta_Init

    SUBROUTINE SectSta_RegLayout(this)
        CLASS(SectSta), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(2)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        fields(2)%field_name = 'isActive'
        fields(2)%data_type = IF_DATA_TYPE_INT
        fields(2)%offset_bytes = offset
        offset = offset + 4
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 2, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectSta_RegLayout")
    END SUBROUTINE SectSta_RegLayout

    SUBROUTINE SectSta_Ensure(this)
        CLASS(SectSta), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_SECTIONSTATE_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectSta_Ensure")
    END SUBROUTINE SectSta_Ensure

    SUBROUTINE SectCtx_Init(this, id)
        CLASS(SectCtx), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        this%category = CAT_CTX
        this%typeName = 'CTX::SECTION'
        IF (PRESENT(id)) this%cfg%id = id
    END SUBROUTINE SectCtx_Init

    SUBROUTINE SectCtx_RegLayout(this)
        CLASS(SectCtx), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(1)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 1, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectCtx_RegLayout")
    END SUBROUTINE SectCtx_RegLayout

    SUBROUTINE SectCtx_Ensure(this)
        CLASS(SectCtx), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_SECTIONCTX_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectCtx_Ensure")
    END SUBROUTINE SectCtx_Ensure

    SUBROUTINE SectAssignDesc_Init(this, id, secId, region)
        CLASS(SectAssignDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id, secId
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: region
        this%category = CAT_DESC
        this%typeName = 'DESC::SECTIONASSIGN'
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(secId)) this%secId = secId
        IF (PRESENT(region)) this%region = region
    END SUBROUTINE SectAssignDesc_Init

    SUBROUTINE SectAssignDesc_RegLayout(this)
        CLASS(SectAssignDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(3)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        fields(2)%field_name = 'secId'
        fields(2)%data_type = IF_DATA_TYPE_INT
        fields(2)%offset_bytes = offset
        offset = offset + 4
        fields(3)%field_name = 'region'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectAssignDesc_RegLayout")
    END SUBROUTINE SectAssignDesc_RegLayout

    SUBROUTINE SectAssignDesc_Ensure(this)
        CLASS(SectAssignDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0,A,I0)') 'UF_SECASSIGNDESC_P', this%cfg%id, '_S', this%secId
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SectAssignDesc_Ensure")
    END SUBROUTINE SectAssignDesc_Ensure

    SUBROUTINE SolidSectDesc_Init(this, id, name, materialName)
        CLASS(SolidSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialName
        this%category = CAT_DESC
        this%typeName = 'DESC::SOLIDSECTION'
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(materialName)) this%materialName = materialName
    END SUBROUTINE SolidSectDesc_Init

    SUBROUTINE SolidSectDesc_RegLayout(this)
        CLASS(SolidSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(3)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        fields(3)%field_name = 'materialName'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SolidSectDesc_RegLayout")
    END SUBROUTINE SolidSectDesc_RegLayout

    SUBROUTINE SolidSectDesc_Ensure(this)
        CLASS(SolidSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_SOLIDSECTIONDESC_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SolidSectDesc_Ensure")
    END SUBROUTINE SolidSectDesc_Ensure

    SUBROUTINE SolidSectDesc_Valid(this, status)
        !! Validate solid section data (UFC 3.3.1: MATERIAL defined, name non-empty)
        !! (UFC keyword manual 3.3.1)
        !! MATERIAL defined, name non-empty.
        !
        CLASS(SolidSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Name non-empty
        IF (LEN_TRIM(this%name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Solid section name must be non-empty"
            RETURN
        END IF
        
        ! Material name non-empty (MATERIAL must be defined)
        IF (LEN_TRIM(this%materialName) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Solid section Mat name must be defined"
            RETURN
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE SolidSectDesc_Valid

    SUBROUTINE ShellSectDesc_Init(this, id, name, materialName, thickness)
        CLASS(ShellSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialName
        REAL(wp), INTENT(IN), OPTIONAL :: thickness
        this%category = CAT_DESC
        this%typeName = 'DESC::SHELLSECTION'
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(materialName)) this%materialName = materialName
        IF (PRESENT(thickness)) this%thickness = thickness
    END SUBROUTINE ShellSectDesc_Init

    SUBROUTINE ShellSectDesc_RegLayout(this)
        CLASS(ShellSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(4)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        fields(3)%field_name = 'materialName'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        fields(4)%field_name = 'thickness'
        fields(4)%data_type = IF_DATA_TYPE_DP
        fields(4)%offset_bytes = offset
        offset = offset + 8
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 4, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ShellSectDesc_RegLayout")
    END SUBROUTINE ShellSectDesc_RegLayout

    SUBROUTINE ShellSectDesc_Ensure(this)
        CLASS(ShellSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_SHELLSECTIONDESC_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ShellSectDesc_Ensure")
    END SUBROUTINE ShellSectDesc_Ensure

    SUBROUTINE ShellSectDesc_Valid(this, status)
        !! Validate shell section (UFC 3.3.2)
        !! MATERIAL defined, thickness > 0, name non-empty.
        !
        !
        !
        CLASS(ShellSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Name non-empty
        IF (LEN_TRIM(this%name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Shell section name must be non-empty"
            RETURN
        END IF
        
        ! Material name non-empty (MATERIAL must be defined)
        IF (LEN_TRIM(this%materialName) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Shell section Mat name must be defined"
            RETURN
        END IF
        
        ! Thickness must be > 0
        IF (this%thickness <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,E15.6)') "Shell section thickness must be > 0, got: ", this%thickness
            RETURN
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE ShellSectDesc_Valid

    SUBROUTINE BeamSectDesc_Init(this, id, name, materialName, area, I11, I22, I12)
        CLASS(BeamSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialName
        REAL(wp), INTENT(IN), OPTIONAL :: area, I11, I22, I12
        this%category = CAT_DESC
        this%typeName = 'DESC::BEAMSECTION'
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(materialName)) this%materialName = materialName
        IF (PRESENT(area)) this%area = area
        IF (PRESENT(I11)) this%I11 = I11
        IF (PRESENT(I22)) this%I22 = I22
        IF (PRESENT(I12)) this%I12 = I12
    END SUBROUTINE BeamSectDesc_Init

    SUBROUTINE BeamSectDesc_RegLayout(this)
        CLASS(BeamSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(7)
        INTEGER(i4) :: offset
        CALL init_error_status(status)
        offset = 0
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        fields(3)%field_name = 'materialName'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        fields(4)%field_name = 'area'
        fields(4)%data_type = IF_DATA_TYPE_DP
        fields(4)%offset_bytes = offset
        offset = offset + 8
        fields(5)%field_name = 'I11'
        fields(5)%data_type = IF_DATA_TYPE_DP
        fields(5)%offset_bytes = offset
        offset = offset + 8
        fields(6)%field_name = 'I22'
        fields(6)%data_type = IF_DATA_TYPE_DP
        fields(6)%offset_bytes = offset
        offset = offset + 8
        fields(7)%field_name = 'I12'
        fields(7)%data_type = IF_DATA_TYPE_DP
        fields(7)%offset_bytes = offset
        offset = offset + 8
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 7, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "BeamSectDesc_RegLayout")
    END SUBROUTINE BeamSectDesc_RegLayout

    SUBROUTINE BeamSectDesc_Ensure(this)
        CLASS(BeamSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_BEAMSECTIONDESC_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "BeamSectDesc_Ensure")
    END SUBROUTINE BeamSectDesc_Ensure

    SUBROUTINE BeamSectDesc_Valid(this, status)
        !! Validate beam section (UFC 3.3.3)
        !! MATERIAL, area > 0, inertia > 0, name non-empty.
        !
        !
        !
        !
        !
        CLASS(BeamSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Name non-empty
        IF (LEN_TRIM(this%name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Beam section name must be non-empty"
            RETURN
        END IF
        
        ! Material name non-empty (MATERIAL must be defined)
        IF (LEN_TRIM(this%materialName) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Beam section Mat name must be defined"
            RETURN
        END IF
        
        ! Cross-section area must be > 0
        IF (this%area <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,E15.6)') "Beam section area must be > 0, got: ", this%area
            RETURN
        END IF
        
        ! Moment of inertia must be > 0
        IF (this%I11 <= 0.0_wp .OR. this%I22 <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,E15.6,A,E15.6)') "Beam section moments of inertia must be > 0, got I11=", &
                this%I11, ", I22=", this%I22
            RETURN
        END IF
        
        ! Inertia product consistency (I11*I22 - I12^2 >= 0 for positive-definite inertia tensor)
        IF (this%I11 * this%I22 - this%I12**2 < 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Beam section inertia tensor is not positive definite (I11*I22 - I12^2 < 0)"
            RETURN
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE BeamSectDesc_Valid

    !===========================================================================
    ! SectTree procedures (from MD_Section_Tree, merged)
    !===========================================================================
    FUNCTION SectTree_GetID(this) RESULT(id)
        CLASS(SectTree), INTENT(IN) :: this
        INTEGER(i4) :: id
        id = this%node_id
        IF (id == 0) id = this%cfg%id
    END FUNCTION SectTree_GetID

    FUNCTION SectTree_GetName(this) RESULT(name)
        CLASS(SectTree), INTENT(IN) :: this
        CHARACTER(len=64) :: name
        name = this%name
    END FUNCTION SectTree_GetName

    FUNCTION SectTree_GetType(this) RESULT(ntype)
        CLASS(SectTree), INTENT(IN) :: this
        INTEGER(i4) :: ntype
        ntype = NODE_TYPE_SECTI
    END FUNCTION SectTree_GetType

    FUNCTION SectTree_GetParentID(this) RESULT(pid)
        CLASS(SectTree), INTENT(IN) :: this
        INTEGER(i4) :: pid
        pid = this%parent_id
    END FUNCTION SectTree_GetParentID

    FUNCTION SectTree_GetByPath(this, path_str) RESULT(obj_ptr)
        CLASS(SectTree), INTENT(IN), TARGET :: this
        CHARACTER(len=*), INTENT(IN) :: path_str
        CLASS(TreeNodeBase), POINTER :: obj_ptr
        TYPE(PathComponents) :: components
        TYPE(ErrorStatusType) :: status
        obj_ptr => NULL()
        IF (.NOT. this%tree_initialize) RETURN
        CALL this%path_resolver%ParsePath(path_str, components, status)
        IF (components%GetCount() == 0) THEN
            obj_ptr => this
            RETURN
        END IF
        obj_ptr => this
    END FUNCTION SectTree_GetByPath

    FUNCTION SectTree_GetFullPath(this) RESULT(path_str)
        CLASS(SectTree), INTENT(IN) :: this
        CHARACTER(len=512) :: path_str
        CHARACTER(len=64) :: name
        name = this%GetName()
        IF (LEN_TRIM(name) > 0) THEN
            path_str = '/Section/' // TRIM(name)
        ELSE
            WRITE(path_str, '(A,I0)') '/Section/Sect_', this%GetID()
        END IF
    END FUNCTION SectTree_GetFullPath

    SUBROUTINE SectTree_InitTree(this, initial_capacit, status)
        CLASS(SectTree), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: initial_capacit
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%node_id = this%cfg%id
        this%tree_initialize = .TRUE.
        status%status_code = IF_STATUS_OK
    END SUBROUTINE SectTree_InitTree

    SUBROUTINE SectTree_DestroyTree(this, status)
        CLASS(SectTree), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%index_mgr%Destroy(status)
        this%tree_initialize = .FALSE.
        status%status_code = IF_STATUS_OK
    END SUBROUTINE SectTree_DestroyTree

    SUBROUTINE SectTree_RebuildIndex(this, status)
        CLASS(SectTree), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%tree_initialize) THEN
            status%status_code = IF_STATUS_INVALID
            RETURN
        END IF
        CALL this%index_mgr%Rebuild(status)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE SectTree_RebuildIndex

    SUBROUTINE SectTree_ValidateTree(this, status)
        CLASS(SectTree), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%tree_initialize) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Tree not initialized"
            RETURN
        END IF
        CALL this%index_mgr%Valid(status)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE SectTree_ValidateTree

    SUBROUTINE SectTree_Serialize(this, serializer)
        CLASS(SectTree), INTENT(IN) :: this
        CLASS(TreeSerializer), INTENT(INOUT) :: serializer
        TYPE(ErrorStatusType) :: status
        CALL serializer%BeginObject("SectTree", status)
        CALL serializer%WriteInt(this%cfg%id, status)
        CALL serializer%WriteString(this%name, status)
        CALL serializer%WriteString(this%sectionType, status)
        CALL serializer%WriteInt(this%node_id, status)
        CALL serializer%WriteInt(this%parent_id, status)
        CALL serializer%WriteBool(this%is_active, status)
        CALL serializer%WriteBool(this%is_visible, status)
        CALL serializer%EndObject(status)
    END SUBROUTINE SectTree_Serialize

    SUBROUTINE SectTree_Deserialize(this, deserializer)
        CLASS(SectTree), INTENT(INOUT) :: this
        CLASS(TreeDeserializer), INTENT(IN) :: deserializer
        TYPE(ErrorStatusType) :: status
        CHARACTER(len=256) :: obj_name
        obj_name = deserializer%BeginObject(status)
        this%cfg%id = deserializer%ReadInt(status)
        this%name = deserializer%ReadString(status)
        this%sectionType = deserializer%ReadString(status)
        this%node_id = deserializer%ReadInt(status)
        this%parent_id = deserializer%ReadInt(status)
        this%is_active = deserializer%ReadBool(status)
        this%is_visible = deserializer%ReadBool(status)
        IF (.NOT. this%tree_initialize) CALL this%InitTree(status=status)
        CALL this%RebuildIndex(status)
        CALL deserializer%EndObject(status)
    END SUBROUTINE SectTree_Deserialize

    SUBROUTINE SectTree_BeginBatch(this, max_size)
        CLASS(SectTree), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_size
        CALL this%batch_mgr%BeginBatch(max_size)
    END SUBROUTINE SectTree_BeginBatch

    SUBROUTINE SectTree_EndBatch(this, rebuild_index, status)
        CLASS(SectTree), INTENT(INOUT) :: this
        LOGICAL, INTENT(IN), OPTIONAL :: rebuild_index
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        TYPE(ErrorStatusType) :: local_status
        CALL this%batch_mgr%EndBatch(rebuild_index, local_status)
        IF (PRESENT(rebuild_index) .AND. rebuild_index) CALL this%RebuildIndex(local_status)
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE SectTree_EndBatch

    !===========================================================================
    ! Section Ops procedures (from MD_Section_Ops, merged)
    !===========================================================================
    SUBROUTINE MD_Section_ComputeProperties(section, props, status)
        TYPE(UF_Section), INTENT(IN) :: section
        TYPE(MD_SectionProps), INTENT(OUT) :: props
        INTEGER(i4), INTENT(OUT) :: status
        status = IF_STATUS_OK
        props%area = MD_Section_GetArea(section)
        CALL MD_Section_GetCentroid(section, props%centroid)
        CALL MD_Section_ComputeInertia(section, props%I11, props%I22, props%I12, props%I33, status)
        IF (status /= IF_STATUS_OK) RETURN
        CALL MD_Section_ComputeModulus(section, props%I11, props%I22, props%section_modulus)
        CALL MD_Section_ComputeGyrationRadius(section, props%area, props%I11, props%I22, props%gyration_radius)
        CALL MD_Section_GetPrincipalAxes(props%I11, props%I22, props%I12, props%principal_momen, props%principal_angle)
        status = IF_STATUS_OK
    END SUBROUTINE MD_Section_ComputeProperties

    SUBROUTINE MD_Section_ComputeInertia(section, I11, I22, I12, I33, status)
        TYPE(UF_Section), INTENT(IN) :: section
        REAL(wp), INTENT(OUT) :: I11, I22, I12, I33
        INTEGER(i4), INTENT(OUT) :: status
        status = IF_STATUS_OK
        I11 = section%I11
        I22 = section%I22
        I12 = section%I12
        I33 = I11 + I22
        IF (I11 < 0.0_wp .OR. I22 < 0.0_wp) THEN
            status = IF_STATUS_INVALID
            RETURN
        END IF
        status = IF_STATUS_OK
    END SUBROUTINE MD_Section_ComputeInertia

    SUBROUTINE MD_Section_ComputeModulus(section, I11, I22, modulus)
        TYPE(UF_Section), INTENT(IN) :: section
        REAL(wp), INTENT(IN) :: I11, I22
        REAL(wp), INTENT(OUT) :: modulus(2)
        REAL(wp) :: c1, c2
        c1 = section%thickness / 2.0_wp
        c2 = section%thickness / 2.0_wp
        IF (c1 > 1.0e-12_wp) THEN
            modulus(1) = I11 / c1
        ELSE
            modulus(1) = 0.0_wp
        END IF
        IF (c2 > 1.0e-12_wp) THEN
            modulus(2) = I22 / c2
        ELSE
            modulus(2) = 0.0_wp
        END IF
    END SUBROUTINE MD_Section_ComputeModulus

    SUBROUTINE MD_Se_ComputeGyrationRadius(section, area, I11, I22, radius)
        TYPE(UF_Section), INTENT(IN) :: section
        REAL(wp), INTENT(IN) :: area, I11, I22
        REAL(wp), INTENT(OUT) :: radius(2)
        IF (area > 1.0e-12_wp) THEN
            radius(1) = SQRT(I11 / area)
            radius(2) = SQRT(I22 / area)
        ELSE
            radius(1) = 0.0_wp
            radius(2) = 0.0_wp
        END IF
    END SUBROUTINE MD_Section_ComputeGyrationRadius

    FUNCTION MD_Section_GetArea(section) RESULT(area)
        TYPE(UF_Section), INTENT(IN) :: section
        REAL(wp) :: area
        area = section%area
        IF (area < 1.0e-12_wp) area = 0.0_wp
    END FUNCTION MD_Section_GetArea

    FUNCTION MD_Section_GetThickness(section) RESULT(thickness)
        TYPE(UF_Section), INTENT(IN) :: section
        REAL(wp) :: thickness
        thickness = section%thickness
        IF (thickness < 1.0e-12_wp) thickness = 0.0_wp
    END FUNCTION MD_Section_GetThickness

    FUNCTION MD_Section_GetSectionType(section) RESULT(sectionType)
        TYPE(UF_Section), INTENT(IN) :: section
        INTEGER(i4) :: sectionType
        sectionType = 0
        IF (TRIM(section%sectionType) == "SOLID") sectionType = 1
        IF (TRIM(section%sectionType) == "SHELL") sectionType = 2
        IF (TRIM(section%sectionType) == "BEAM") sectionType = 3
        IF (TRIM(section%sectionType) == "TRUSS") sectionType = 4
        IF (TRIM(section%sectionType) == "MEMBRANE") sectionType = 5
    END FUNCTION MD_Section_GetSectionType

    SUBROUTINE MD_Section_GetCentroid(section, centroid)
        TYPE(UF_Section), INTENT(IN) :: section
        REAL(wp), INTENT(OUT) :: centroid(2)
        centroid(1) = 0.0_wp
        centroid(2) = 0.0_wp
    END SUBROUTINE MD_Section_GetCentroid

    SUBROUTINE MD_Section_GetPrincipalAxes(I11, I22, I12, principal_momen, principal_angle)
        REAL(wp), INTENT(IN) :: I11, I22, I12
        REAL(wp), INTENT(OUT) :: principal_momen(2), principal_angle
        REAL(wp) :: avg, diff, angle
        avg = (I11 + I22) / 2.0_wp
        diff = (I11 - I22) / 2.0_wp
        principal_momen(1) = avg + SQRT(diff**2 + I12**2)
        principal_momen(2) = avg - SQRT(diff**2 + I12**2)
        IF (ABS(diff) > 1.0e-12_wp) THEN
            angle = ATAN2(I12, diff) / 2.0_wp
        ELSE
            angle = 0.0_wp
        END IF
        principal_angle = angle
    END SUBROUTINE MD_Section_GetPrincipalAxes

    SUBROUTINE MD_Section_Orientation_Init(orientation, angle, axis)
        TYPE(MD_SectionOrientation), INTENT(OUT) :: orientation
        REAL(wp), INTENT(IN) :: angle
        REAL(wp), INTENT(IN), OPTIONAL :: axis(3)
        orientation%angle = angle
        orientation%defined = .TRUE.
        IF (PRESENT(axis)) THEN
            orientation%axis = axis
        ELSE
            orientation%axis = (/0.0_wp, 0.0_wp, 1.0_wp/)
        END IF
    END SUBROUTINE MD_Section_Orientation_Init

    SUBROUTINE MD_Section_SetOrientation(section, orientation, status)
        TYPE(UF_Section), INTENT(INOUT) :: section
        TYPE(MD_SectionOrientation), INTENT(IN) :: orientation
        INTEGER(i4), INTENT(OUT) :: status
        status = IF_STATUS_OK
        IF (.NOT. orientation%defined) THEN
            status = IF_STATUS_INVALID
            RETURN
        END IF
        section%orientation%angle = orientation%angle
        section%orientation%axis = orientation%axis
        section%orientation%defined = .TRUE.
        status = IF_STATUS_OK
    END SUBROUTINE MD_Section_SetOrientation

    SUBROUTINE MD_Section_CompProps(layers, numLayers, thickness, props, status)
        TYPE(MD_SectionCompLayer), INTENT(IN) :: layers(:)
        INTEGER(i4), INTENT(IN) :: numLayers
        REAL(wp), INTENT(IN) :: thickness
        TYPE(MD_SectionCompositeProperties), INTENT(OUT) :: props
        INTEGER(i4), INTENT(OUT) :: status
        INTEGER(i4) :: i, j, k
        REAL(wp) :: z_bottom, z_top, z_mid, z_mid_ref
        REAL(wp) :: Q(3,3), D(3,3), B(3,3), A(3,3)
        REAL(wp) :: E1, E2, G12, nu12, nu21
        status = IF_STATUS_OK
        props%numLayers = numLayers
        props%totalThickness = thickness
        props%ABD = 0.0_wp
        z_bottom = -thickness / 2.0_wp
        z_mid_ref = 0.0_wp
        A = 0.0_wp
        B = 0.0_wp
        D = 0.0_wp
        DO i = 1, numLayers
            z_top = z_bottom + layers(i)%thickness
            z_mid = (z_top + z_bottom) / 2.0_wp
            E1 = 1.0_wp
            E2 = 1.0_wp
            G12 = 0.5_wp
            nu12 = 0.3_wp
            nu21 = nu12 * E2 / E1
            Q(1,1) = E1 / (1.0_wp - nu12 * nu21)
            Q(1,2) = nu12 * E2 / (1.0_wp - nu12 * nu21)
            Q(1,3) = 0.0_wp
            Q(2,1) = Q(1,2)
            Q(2,2) = E2 / (1.0_wp - nu12 * nu21)
            Q(2,3) = 0.0_wp
            Q(3,1) = 0.0_wp
            Q(3,2) = 0.0_wp
            Q(3,3) = G12
            DO j = 1, 3
                DO k = 1, 3
                    A(j,k) = A(j,k) + Q(j,k) * (z_top - z_bottom)
                    B(j,k) = B(j,k) + Q(j,k) * (z_top**2 - z_bottom**2) / 2.0_wp
                    D(j,k) = D(j,k) + Q(j,k) * (z_top**3 - z_bottom**3) / 3.0_wp
                END DO
            END DO
            z_bottom = z_top
        END DO
        props%extensional_sti = A
        props%cpl_stiffness = B
        props%bending_stiffne = D
        props%ABD(1:3,1:3) = A
        props%ABD(1:3,4:6) = B
        props%ABD(4:6,1:3) = B
        props%ABD(4:6,4:6) = D
        status = IF_STATUS_OK
    END SUBROUTINE MD_Section_CompProps

    SUBROUTINE MD_Section_ValidateGeometry(section, valid, status, errorMessage)
        TYPE(UF_Section), INTENT(IN) :: section
        LOGICAL, INTENT(OUT) :: valid
        INTEGER(i4), INTENT(OUT) :: status
        CHARACTER(len=256), INTENT(OUT) :: errorMessage
        status = IF_STATUS_OK
        valid = .TRUE.
        errorMessage = ""
        IF (section%area < 0.0_wp) THEN
            valid = .FALSE.
            status = -1
            errorMessage = "Section area is negative"
            RETURN
        END IF
        IF (section%thickness < 0.0_wp) THEN
            valid = .FALSE.
            status = -2
            errorMessage = "Section thickness is negative"
            RETURN
        END IF
        IF (section%I11 < 0.0_wp .OR. section%I22 < 0.0_wp) THEN
            valid = .FALSE.
            status = -3
            errorMessage = "Section moments of inertia are negative"
            RETURN
        END IF
        IF (section%I11 * section%I22 - section%I12**2 < 0.0_wp) THEN
            valid = .FALSE.
            status = -4
            errorMessage = "Section inertia tensor is not positive definite"
            RETURN
        END IF
        status = IF_STATUS_OK
    END SUBROUTINE MD_Section_ValidateGeometry

    !===========================================================================
    ! Advanced Section Type Implementation Procedures (Phase C Tier 2)
    !===========================================================================
    
    !---------------------------------------------------------------------------
    ! CohesiveSectDesc Implementation
    !---------------------------------------------------------------------------
    SUBROUTINE CohesiveSectDesc_Init(this, id, name, materialName, thickness, response, nIntPts, initialGap)
        CLASS(CohesiveSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id, nIntPts
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialName, response
        REAL(wp), INTENT(IN), OPTIONAL :: thickness, initialGap
        
        CALL this%CoreBase%Init(CAT_DESC, 'DESC::SECTION_COHESIVE')
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(materialName)) this%materialName = materialName
        IF (PRESENT(thickness)) this%thickness = thickness
        IF (PRESENT(response)) this%response = response
        IF (PRESENT(nIntPts)) this%nIntPts = nIntPts
        IF (PRESENT(initialGap)) this%initialGap = initialGap
    END SUBROUTINE CohesiveSectDesc_Init
    
    SUBROUTINE CohesiveSectDesc_RegLayout(this)
        CLASS(CohesiveSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(7)
        INTEGER(i4) :: offset
        
        CALL init_error_status(status)
        offset = 0
        
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        
        fields(3)%field_name = 'materialName'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        
        fields(4)%field_name = 'thickness'
        fields(4)%data_type = IF_DATA_TYPE_DP
        fields(4)%offset_bytes = offset
        offset = offset + 8
        
        fields(5)%field_name = 'response'
        fields(5)%data_type = IF_DATA_TYPE_CHAR
        fields(5)%elem_len = 32
        fields(5)%offset_bytes = offset
        offset = offset + 32
        
        fields(6)%field_name = 'nIntPts'
        fields(6)%data_type = IF_DATA_TYPE_INT
        fields(6)%offset_bytes = offset
        offset = offset + 4
        
        fields(7)%field_name = 'initialGap'
        fields(7)%data_type = IF_DATA_TYPE_DP
        fields(7)%offset_bytes = offset
        offset = offset + 8
        
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 7, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "CohesiveSectDesc_RegLayout")
    END SUBROUTINE CohesiveSectDesc_RegLayout
    
    SUBROUTINE CohesiveSectDesc_Ensure(this)
        CLASS(CohesiveSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_COHESIVESECT_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "CohesiveSectDesc_Ensure")
    END SUBROUTINE CohesiveSectDesc_Ensure
    
    !---------------------------------------------------------------------------
    ! GasketSectDesc Implementation
    !---------------------------------------------------------------------------
    SUBROUTINE GasketSectDesc_Init(this, id, name, materialName, initialThickness, initialGap, nodal_thickness, nDirections)
        CLASS(GasketSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id, nDirections
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialName, nodal_thickness
        REAL(wp), INTENT(IN), OPTIONAL :: initialThickness, initialGap
        
        CALL this%CoreBase%Init(CAT_DESC, 'DESC::SECTION_GASKET')
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(materialName)) this%materialName = materialName
        IF (PRESENT(initialThickness)) this%initialThickness = initialThickness
        IF (PRESENT(initialGap)) this%initialGap = initialGap
        IF (PRESENT(nodal_thickness)) this%nodal_thickness = nodal_thickness
        IF (PRESENT(nDirections)) this%nDirections = nDirections
    END SUBROUTINE GasketSectDesc_Init
    
    SUBROUTINE GasketSectDesc_RegLayout(this)
        CLASS(GasketSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(7)
        INTEGER(i4) :: offset
        
        CALL init_error_status(status)
        offset = 0
        
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        
        fields(3)%field_name = 'materialName'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        
        fields(4)%field_name = 'initialThickness'
        fields(4)%data_type = IF_DATA_TYPE_DP
        fields(4)%offset_bytes = offset
        offset = offset + 8
        
        fields(5)%field_name = 'initialGap'
        fields(5)%data_type = IF_DATA_TYPE_DP
        fields(5)%offset_bytes = offset
        offset = offset + 8
        
        fields(6)%field_name = 'nodal_thickness'
        fields(6)%data_type = IF_DATA_TYPE_CHAR
        fields(6)%elem_len = 32
        fields(6)%offset_bytes = offset
        offset = offset + 32
        
        fields(7)%field_name = 'nDirections'
        fields(7)%data_type = IF_DATA_TYPE_INT
        fields(7)%offset_bytes = offset
        offset = offset + 4
        
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 7, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "GasketSectDesc_RegLayout")
    END SUBROUTINE GasketSectDesc_RegLayout
    
    SUBROUTINE GasketSectDesc_Ensure(this)
        CLASS(GasketSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_GASKETSECT_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "GasketSectDesc_Ensure")
    END SUBROUTINE GasketSectDesc_Ensure
    
    !---------------------------------------------------------------------------
    ! ConnectorSectDesc Implementation
    !---------------------------------------------------------------------------
    SUBROUTINE ConnectorSectDesc_Init(this, id, name, connectorType, behaviorName)
        CLASS(ConnectorSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, connectorType, behaviorName
        
        CALL this%CoreBase%Init(CAT_DESC, 'DESC::SECTION_CONNECTOR')
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(connectorType)) this%connectorType = connectorType
        IF (PRESENT(behaviorName)) this%behaviorName = behaviorName
    END SUBROUTINE ConnectorSectDesc_Init
    
    SUBROUTINE ConnectorSectDesc_RegLayout(this)
        CLASS(ConnectorSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(4)
        INTEGER(i4) :: offset
        
        CALL init_error_status(status)
        offset = 0
        
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        
        fields(3)%field_name = 'connectorType'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 32
        fields(3)%offset_bytes = offset
        offset = offset + 32
        
        fields(4)%field_name = 'behaviorName'
        fields(4)%data_type = IF_DATA_TYPE_CHAR
        fields(4)%elem_len = 64
        fields(4)%offset_bytes = offset
        offset = offset + 64
        
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 4, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ConnectorSectDesc_RegLayout")
    END SUBROUTINE ConnectorSectDesc_RegLayout
    
    SUBROUTINE ConnectorSectDesc_Ensure(this)
        CLASS(ConnectorSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_CONNECTORSECT_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ConnectorSectDesc_Ensure")
    END SUBROUTINE ConnectorSectDesc_Ensure
    
    !---------------------------------------------------------------------------
    ! SurfaceSectDesc Implementation
    !---------------------------------------------------------------------------
    SUBROUTINE SurfaceSectDesc_Init(this, id, name, density, thickness, fluidBehavior)
        CLASS(SurfaceSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, fluidBehavior
        REAL(wp), INTENT(IN), OPTIONAL :: density, thickness
        
        CALL this%CoreBase%Init(CAT_DESC, 'DESC::SECTION_SURFACE')
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(density)) this%density = density
        IF (PRESENT(thickness)) this%thickness = thickness
        IF (PRESENT(fluidBehavior)) this%fluidBehavior = fluidBehavior
    END SUBROUTINE SurfaceSectDesc_Init
    
    SUBROUTINE SurfaceSectDesc_RegLayout(this)
        CLASS(SurfaceSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(5)
        INTEGER(i4) :: offset
        
        CALL init_error_status(status)
        offset = 0
        
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        
        fields(3)%field_name = 'density'
        fields(3)%data_type = IF_DATA_TYPE_DP
        fields(3)%offset_bytes = offset
        offset = offset + 8
        
        fields(4)%field_name = 'thickness'
        fields(4)%data_type = IF_DATA_TYPE_DP
        fields(4)%offset_bytes = offset
        offset = offset + 8
        
        fields(5)%field_name = 'fluidBehavior'
        fields(5)%data_type = IF_DATA_TYPE_CHAR
        fields(5)%elem_len = 32
        fields(5)%offset_bytes = offset
        offset = offset + 32
        
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SurfaceSectDesc_RegLayout")
    END SUBROUTINE SurfaceSectDesc_RegLayout
    
    SUBROUTINE SurfaceSectDesc_Ensure(this)
        CLASS(SurfaceSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_SURFACESECT_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "SurfaceSectDesc_Ensure")
    END SUBROUTINE SurfaceSectDesc_Ensure
    
    !---------------------------------------------------------------------------
    ! MemSectDesc Implementation
    !---------------------------------------------------------------------------
    SUBROUTINE MemSectDesc_Init(this, id, name, materialName, thickness, nIntPts, noCompression)
        CLASS(MemSectDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id, nIntPts
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialName
        REAL(wp), INTENT(IN), OPTIONAL :: thickness
        LOGICAL, INTENT(IN), OPTIONAL :: noCompression
        
        CALL this%CoreBase%Init(CAT_DESC, 'DESC::SECTION_MEMBRANE')
        IF (PRESENT(id)) this%cfg%id = id
        IF (PRESENT(name)) this%name = name
        IF (PRESENT(materialName)) this%materialName = materialName
        IF (PRESENT(thickness)) this%thickness = thickness
        IF (PRESENT(nIntPts)) this%nIntPts = nIntPts
        IF (PRESENT(noCompression)) this%noCompression = noCompression
    END SUBROUTINE MemSectDesc_Init
    
    SUBROUTINE MemSectDesc_RegLayout(this)
        CLASS(MemSectDesc), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        TYPE(StructFieldDesc) :: fields(6)
        INTEGER(i4) :: offset
        
        CALL init_error_status(status)
        offset = 0
        
        fields(1)%field_name = 'id'
        fields(1)%data_type = IF_DATA_TYPE_INT
        fields(1)%offset_bytes = offset
        offset = offset + 4
        
        fields(2)%field_name = 'name'
        fields(2)%data_type = IF_DATA_TYPE_CHAR
        fields(2)%elem_len = 64
        fields(2)%offset_bytes = offset
        offset = offset + 64
        
        fields(3)%field_name = 'materialName'
        fields(3)%data_type = IF_DATA_TYPE_CHAR
        fields(3)%elem_len = 64
        fields(3)%offset_bytes = offset
        offset = offset + 64
        
        fields(4)%field_name = 'thickness'
        fields(4)%data_type = IF_DATA_TYPE_DP
        fields(4)%offset_bytes = offset
        offset = offset + 8
        
        fields(5)%field_name = 'nIntPts'
        fields(5)%data_type = IF_DATA_TYPE_INT
        fields(5)%offset_bytes = offset
        offset = offset + 4
        
        fields(6)%field_name = 'noCompression'
        fields(6)%data_type = IF_DATA_TYPE_INT
        fields(6)%offset_bytes = offset
        offset = offset + 4
        
        CALL dp_register_struct_type(TRIM(this%typeName), fields, 6, status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MemSectDesc_RegLayout")
    END SUBROUTINE MemSectDesc_RegLayout
    
    SUBROUTINE MemSectDesc_Ensure(this)
        CLASS(MemSectDesc), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        
        CALL init_error_status(status)
        IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MEMBRANESECT_', this%cfg%id
        CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
        IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MemSectDesc_Ensure")
    END SUBROUTINE MemSectDesc_Ensure
    
    !===========================================================================
    ! EXTENDED SECTION API (scope 4500-4999)
    !===========================================================================
    
    !---------------------------------------------------------------------------
    ! Solid Section Extended API (scope 4500-4549)
    !---------------------------------------------------------------------------
    
    SUBROUTINE UF_So_GetStatistics(section, stats, status)
        TYPE(SolidSectDesc), INTENT(IN) :: section
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        WRITE(stats, '(A,I0,A,A,A,A)') &
            'Solid Section Statistics: id=', section%cfg%id, &
            ', name="', TRIM(section%name), &
            '", Mat="', TRIM(section%materialName), '"'
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_SolidSection_GetStatistics
    
    SUBROUTINE UF_So_ComputeVolume(section, element_volume, total_volume, status)
        TYPE(SolidSectDesc), INTENT(IN) :: section
        REAL(wp), INTENT(IN) :: element_volume
        REAL(wp), INTENT(OUT) :: total_volume
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! For solid sections, volume is simply the element volume
        total_volume = element_volume
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_SolidSection_ComputeVolume
    
    !---------------------------------------------------------------------------
    ! Shell Section Extended API (scope 4600-4649)
    !---------------------------------------------------------------------------
    
    SUBROUTINE UF_Sh_GetStatistics(section, stats, status)
        TYPE(ShellSectDesc), INTENT(IN) :: section
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        WRITE(stats, '(A,I0,A,A,A,A,A,ES12.5)') &
            'Shell Section Statistics: id=', section%cfg%id, &
            ', name="', TRIM(section%name), &
            '", Mat="', TRIM(section%materialName), &
            '", thickness=', section%thickness
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_ShellSection_GetStatistics
    
    SUBROUTINE UF_ShellSection_ComputeArea(section, element_area, total_area, status)
        TYPE(ShellSectDesc), INTENT(IN) :: section
        REAL(wp), INTENT(IN) :: element_area
        REAL(wp), INTENT(OUT) :: total_area
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! For shell sections, area is the element area
        total_area = element_area
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_ShellSection_ComputeArea
    
    SUBROUTINE UF_Sh_ComputeVolume(section, element_area, total_volume, status)
        TYPE(ShellSectDesc), INTENT(IN) :: section
        REAL(wp), INTENT(IN) :: element_area
        REAL(wp), INTENT(OUT) :: total_volume
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Volume = area * thickness
        total_volume = element_area * section%thickness
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_ShellSection_ComputeVolume
    
    !---------------------------------------------------------------------------
    ! Beam Section Extended API (scope 4700-4749)
    !---------------------------------------------------------------------------
    
    SUBROUTINE UF_BeamSection_GetStatistics(section, stats, status)
        TYPE(BeamSectDesc), INTENT(IN) :: section
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        WRITE(stats, '(A,I0,A,A,A,A,A,ES12.5,A,ES12.5,A,ES12.5)') &
            'Beam Section Statistics: id=', section%cfg%id, &
            ', name="', TRIM(section%name), &
            '", Mat="', TRIM(section%materialName), &
            '", area=', section%area, &
            ', I11=', section%I11, &
            ', I22=', section%I22
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_BeamSection_GetStatistics
    
    SUBROUTINE UF_Be_ComputeTorsionalConsta(section, J, status)
        TYPE(BeamSectDesc), INTENT(IN) :: section
        REAL(wp), INTENT(OUT) :: J
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Simplified: J = I11 + I22 (for circular sections)
        ! For general sections, this should be computed from geometry
        J = section%I11 + section%I22
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_BeamSection_ComputeTorsionalConstant
    
    SUBROUTINE UF_Be_ComputeShearArea(section, A_shear, status)
        TYPE(BeamSectDesc), INTENT(IN) :: section
        REAL(wp), INTENT(OUT) :: A_shear(2)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Simplified: shear area factors (typically 0.8-1.0 for rectangular sections)
        A_shear(1) = section%area * 0.833_wp  ! For direction 1
        A_shear(2) = section%area * 0.833_wp  ! For direction 2
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_BeamSection_ComputeShearArea
    
    !---------------------------------------------------------------------------
    ! Membrane Section Extended API (scope 4800-4849)
    !---------------------------------------------------------------------------
    
    SUBROUTINE UF_Me_GetStatistics(section, stats, status)
        TYPE(MemSectDesc), INTENT(IN) :: section
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        WRITE(stats, '(A,I0,A,A,A,A,A,ES12.5,A,I0,A,L1)') &
            'Membrane Section Statistics: id=', section%cfg%id, &
            ', name="', TRIM(section%name), &
            '", Mat="', TRIM(section%materialName), &
            '", thickness=', section%thickness, &
            ', nIntPts=', section%nIntPts, &
            ', noCompression=', section%noCompression
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_MembraneSection_GetStatistics
    
    SUBROUTINE UF_Me_ComputeArea(section, element_area, total_area, status)
        TYPE(MemSectDesc), INTENT(IN) :: section
        REAL(wp), INTENT(IN) :: element_area
        REAL(wp), INTENT(OUT) :: total_area
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! For membrane sections, area is the element area
        total_area = element_area
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_MembraneSection_ComputeArea
    
    !---------------------------------------------------------------------------
    ! Composite Section Extended API (task4900-4949)
    !---------------------------------------------------------------------------
    
    SUBROUTINE UF_Co_ComputeEffectiveProper(composite_props, n_layers, &
                                                                E_eff, nu_eff, G_eff, status)
        TYPE(MD_SectionCompositeProperties), INTENT(IN) :: composite_props
        INTEGER(i4), INTENT(IN) :: n_layers
        REAL(wp), INTENT(OUT) :: E_eff(3), nu_eff(3,3), G_eff(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4) :: i
        REAL(wp) :: total_thickness, layer_thickness
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        ! Compute total thickness
        total_thickness = 0.0_wp
        DO i = 1, n_layers
            total_thickness = total_thickness + composite_props%layers(i)%thickness
        END DO
        
        ! Compute effective properties using rule of mixtures (simplified)
        E_eff = 0.0_wp
        nu_eff = 0.0_wp
        G_eff = 0.0_wp
        
        DO i = 1, n_layers
            layer_thickness = composite_props%layers(i)%thickness
            IF (total_thickness > 1.0e-12_wp) THEN
                E_eff(1) = E_eff(1) + composite_props%layers(i)%E(1) * (layer_thickness / total_thickness)
                E_eff(2) = E_eff(2) + composite_props%layers(i)%E(2) * (layer_thickness / total_thickness)
                E_eff(3) = E_eff(3) + composite_props%layers(i)%E(3) * (layer_thickness / total_thickness)
                G_eff(1) = G_eff(1) + composite_props%layers(i)%G(1) * (layer_thickness / total_thickness)
                G_eff(2) = G_eff(2) + composite_props%layers(i)%G(2) * (layer_thickness / total_thickness)
                G_eff(3) = G_eff(3) + composite_props%layers(i)%G(3) * (layer_thickness / total_thickness)
            END IF
        END DO
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_CompositeSection_ComputeEffectiveProperties
    
    !---------------------------------------------------------------------------
    ! Section Library Management Extended API (task4950-4999)
    !---------------------------------------------------------------------------
    
    SUBROUTINE UF_Se_GetStatistics(section_tree, stats, status)
        TYPE(SectTree), INTENT(IN) :: section_tree
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4) :: n_sections
        
        IF (PRESENT(status)) CALL init_error_status(status)
        
        n_sections = section_tree%GetCount()
        
        WRITE(stats, '(A,I0,A,A)') &
            'Section Library Statistics: total_sections=', n_sections, &
            ', name="', TRIM(section_tree%name), '"'
        
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        
    END SUBROUTINE UF_SectionLibrary_GetStatistics
    
    SUBROUTINE UF_SectionLibrary_FindByType(section_tree, section_type, section_list, n_found, status)
        TYPE(SectTree), INTENT(IN) :: section_tree
        CHARACTER(LEN=*), INTENT(IN) :: section_type
        TYPE(SectDesc), ALLOCATABLE, INTENT(OUT) :: section_list(:)
        INTEGER(i4), INTENT(OUT) :: n_found
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        ! Simplified implementation - production should traverse tree
        n_found = 0
        IF (ALLOCATED(section_list)) DEALLOCATE(section_list)
        
        IF (PRESENT(status)) THEN
            CALL init_error_status(status)
            status%status_code = IF_STATUS_OK
        END IF
        
    END SUBROUTINE UF_SectionLibrary_FindByType

END module MD_Sect_Mgr