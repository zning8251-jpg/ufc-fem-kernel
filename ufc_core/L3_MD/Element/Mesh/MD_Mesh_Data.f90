!===============================================================================
! MODULE:  MD_Mesh_Data
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Core mesh data structures â€?P0 Get/Set: MeshData, MeshDesc,
!          MeshState, MeshCtx containers.
!===============================================================================
!
! Contents:
!   Types:
!     - MeshData: Core mesh data container
!     - MeshDesc: Mesh descriptor (Desc category)
!     - MeshState: Mesh state (State category)
!     - MeshCtx: Mesh context (Ctx category)
!   Subroutines:
!     - MeshData: Init, Clean, GetNodeCoords, SetNodeCoords, GetElementConnectivity, SetElementConnectivity, GetElementNodes, Valid
!     - MeshDesc: Init, RegLayout, Ensure
!     - MeshState: Init, RegLayout, Ensure
!     - MeshCtx: Init, RegLayout, Ensure
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Mesh_Data
  USE IF_Prec_Core,        only: wp, i4, i8
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, StateBase, StateBase_Init, CtxBase, CtxBase_Init, &
       CAT_DESC, CAT_STATE, CAT_CTX
  USE IF_Err_Brg, ONLY: uf_set_error
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
       IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR

  implicit none

  private

  ! Max nodes per element (assembly uses 27; supports C3D20, C3D27, etc.)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_NODES_PER_ELEM = 27_i4

  !=============================================================================
  ! Mesh Data Type
  !=============================================================================
  type, public :: MeshData
    integer(i8)                          :: nNodes        = 0_i8
    integer(i8)                          :: nElems        = 0_i8
    integer(i4)                          :: spatial_dim   = 3_i4
    real(wp),              allocatable   :: node_coords(:,:)
    integer(i8),           allocatable   :: element_connect(:,:)
    ! Per-element UFC code MD_MESH_ELEM_* (MD_Elem_Algo); consumed by PH_L4_Populate_Element -> elem_type_cache
    integer(i4),           allocatable   :: element_types(:)
    ! 1-based index into L3 section_db / section%desc_array; filled by Mesh_Sync_PopulateElemSectionRef
    integer(i4),           allocatable   :: elem_section_ref(:)
    integer(i8),           allocatable   :: node_sets(:,:)
    integer(i8),           allocatable   :: element_sets(:,:)
    LOGICAL :: initialized = .false.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: GetNodeCoords
    procedure :: SetNodeCoords
    procedure :: GetElementConnectivity
    procedure :: SetElementConnectivity
    procedure :: GetElementNodes
    procedure :: Valid
  end type MeshData

  !=============================================================================
  ! Mesh Type Definitions (Desc/State/Ctx)
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: MeshDesc
    INTEGER(i4) :: meshId = 0_i4
    INTEGER(i4) :: id = 0_i4
    CHARACTER(len=64) :: elementFamily = ""
    CHARACTER(len=64) :: ElemFormul = ""
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nElems = 0_i4
    ! Surface/Set definitions for Interaction domain binding
    INTEGER(i4) :: n_surfaces = 0_i4
    CHARACTER(len=64), ALLOCATABLE :: surface_names(:)  ! Surface names for contact
    INTEGER(i4) :: n_node_sets = 0_i4
    CHARACTER(len=64), ALLOCATABLE :: node_set_names(:)  ! Node set names
    INTEGER(i4) :: n_elem_sets = 0_i4
    CHARACTER(len=64), ALLOCATABLE :: elem_set_names(:)  ! Element set names
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MeshDesc_Init
  END TYPE MeshDesc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MeshState
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nElems = 0_i4
    LOGICAL :: isActive = .false.
    INTEGER(i4) :: nAssembled = 0_i4      ! [???] ?????WriteBack ??
    INTEGER(i4) :: step_idx = 0_i4       ! Step ??
    INTEGER(i4) :: incr_idx = 0_i4       ! ???????
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshState_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshState_Ensure
    PROCEDURE, PUBLIC :: Init => MeshState_Init
  END TYPE MeshState

  TYPE, PUBLIC, EXTENDS(CtxBase) :: MeshCtx
    INTEGER(i4) :: meshId = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MeshCtx_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MeshCtx_Ensure
    PROCEDURE, PUBLIC :: Init => MeshCtx_Init
  END TYPE MeshCtx

contains

  !=============================================================================
  ! MeshData Procedures
  !=============================================================================
  subroutine Init(this, nNodes, nElems, spatial_dim, status, max_nodes_per_elem)
    class(MeshData),        intent(inout) :: this
    integer(i8),             intent(in)    :: nNodes
    integer(i8),             intent(in)    :: nElems
    integer(i4),             intent(in)    :: spatial_dim
    type(ErrorStatusType),   intent(out)   :: status
    integer(i4),             intent(in), optional :: max_nodes_per_elem

    integer(i4) :: max_npe

    call init_error_status(status)

    this%nNodes = nNodes
    this%nElems = nElems
    this%spatial_dim = spatial_dim

    max_npe = MD_MESH_MAX_NODES_PER_ELEM
    if (present(max_nodes_per_elem)) max_npe = max(8_i4, min(max_nodes_per_elem, MD_MESH_MAX_NODES_PER_ELEM))

    if (nNodes > 0_i8) then
      allocate(this%node_coords(spatial_dim, nNodes))
      this%node_coords(:,:) = 0.0_wp
    end if

    if (nElems > 0_i8) then
      allocate(this%element_connect(max_npe, nElems))
      this%element_connect(:,:) = 0_i8
      allocate(this%element_types(nElems))
      this%element_types(:) = 0_i4
      allocate(this%elem_section_ref(nElems))
      this%elem_section_ref(:) = 0_i4
    end if

    this%initialized = .true.
    status%status_code = IF_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    class(MeshData), intent(inout) :: this

    if (allocated(this%node_coords)) deallocate(this%node_coords)
    if (allocated(this%element_connect)) deallocate(this%element_connect)
    if (allocated(this%element_types)) deallocate(this%element_types)
    if (allocated(this%elem_section_ref)) deallocate(this%elem_section_ref)
    if (allocated(this%node_sets)) deallocate(this%node_sets)
    if (allocated(this%element_sets)) deallocate(this%element_sets)

    this%nNodes = 0_i8
    this%nElems = 0_i8
    this%spatial_dim = 3_i4
    this%initialized = .false.
  end subroutine Clean

  subroutine GetNodeCoords(this, node_id, coords, status)
    class(MeshData),      intent(in)  :: this
    integer(i8),           intent(in)  :: node_id
    real(wp),              intent(out) :: coords(:)
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (node_id < 1_i8 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    coords(1:this%spatial_dim) = this%node_coords(1:this%spatial_dim, node_id)
    status%status_code = IF_STATUS_OK
  end subroutine GetNodeCoords

  subroutine SetNodeCoords(this, node_id, coords, status)
    class(MeshData),      intent(inout) :: this
    integer(i8),           intent(in)    :: node_id
    real(wp),              intent(in)    :: coords(:)
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (node_id < 1_i8 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    this%node_coords(1:this%spatial_dim, node_id) = coords(1:this%spatial_dim)
    status%status_code = IF_STATUS_OK
  end subroutine SetNodeCoords

  subroutine GetElementConnectivity(this, element_id, conn, status)
    class(MeshData),      intent(in)  :: this
    integer(i8),           intent(in)  :: element_id
    integer(i8),           intent(out) :: conn(:)
    type(ErrorStatusType),  intent(out) :: status

    integer(i4) :: nrows, ncopy, i

    call init_error_status(status)

    if (element_id < 1_i8 .or. element_id > this%nElems) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid Element ID"
      return
    end if

    nrows = int(size(this%element_connect, 1), i4)
    ncopy = min(size(conn), nrows)
    conn(1:ncopy) = this%element_connect(1:ncopy, element_id)
    do i = ncopy + 1, size(conn)
      conn(i) = 0_i8
    end do
    status%status_code = IF_STATUS_OK
  end subroutine GetElementConnectivity

  subroutine SetElementConnectivity(this, element_id, conn, status)
    class(MeshData),      intent(inout) :: this
    integer(i8),           intent(in)    :: element_id
    integer(i8),           intent(in)    :: conn(:)
    type(ErrorStatusType),  intent(out)   :: status

    integer(i4) :: nrows, ncopy

    call init_error_status(status)

    if (element_id < 1_i8 .or. element_id > this%nElems) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid Element ID"
      return
    end if

    nrows = int(size(this%element_connect, 1), i4)
    ncopy = min(size(conn), nrows)
    this%element_connect(1:ncopy, element_id) = conn(1:ncopy)
    status%status_code = IF_STATUS_OK
  end subroutine SetElementConnectivity

  subroutine GetElementNodes(this, element_id, node_coords, status)
    class(MeshData),      intent(in)  :: this
    integer(i8),           intent(in)  :: element_id
    real(wp),              intent(out) :: node_coords(:,:)
    type(ErrorStatusType),  intent(out) :: status

    integer(i8) :: conn(MD_MESH_MAX_NODES_PER_ELEM)
    integer(i4) :: i, nNodes, max_npe

    call init_error_status(status)

    max_npe = int(size(this%element_connect, 1), i4)
    call this%GetElementConnectivity(element_id, conn(1:max_npe), status)
    if (status%status_code /= IF_STATUS_OK) return

    nNodes = 0_i4
    do i = 1, max_npe
      if (conn(i) > 0_i8) then
        nNodes = nNodes + 1_i4
        if (nNodes <= size(node_coords, 2)) then
          node_coords(1:this%spatial_dim, nNodes) = &
            this%node_coords(1:this%spatial_dim, conn(i))
        end if
      end if
    end do

    ! Zero out remaining columns if output array is larger than actual nodes
    if (nNodes < size(node_coords, 2)) then
      do i = nNodes + 1, size(node_coords, 2)
        node_coords(1:this%spatial_dim, i) = 0.0_wp
      end do
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetElementNodes

  subroutine Valid(this, status)
    class(MeshData),      intent(in)  :: this
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "MeshData not initialized"
      return
    end if

    if (this%nNodes < 0_i8) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of nodes"
      return
    end if

    if (this%nElems < 0_i8) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of elements"
      return
    end if

    if (this%spatial_dim < 2_i4 .or. this%spatial_dim > 3_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid spatial dimension"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Valid

  !=============================================================================
  ! MeshDesc Procedures
  !=============================================================================
  SUBROUTINE MeshDesc_Init(this)
    CLASS(MeshDesc), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    CALL this%SetTypeName('DESC::MESH')
  END SUBROUTINE MeshDesc_Init

  SUBROUTINE MeshDesc_RegLayout(this)
    CLASS(MeshDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(7)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'meshId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'id'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'elementFamily'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 64
    fields(4)%offset_bytes = offset
    offset = offset + 64
    fields(5)%field_name = 'ElemFormul'
    fields(5)%data_type = IF_DATA_TYPE_CHAR
    fields(5)%elem_len = 64
    fields(5)%offset_bytes = offset
    offset = offset + 64
    fields(6)%field_name = 'nNodes'; fields(6)%data_type = IF_DATA_TYPE_INT; fields(6)%offset_bytes = offset; offset = offset + 4
    fields(7)%field_name = 'nElems'; fields(7)%data_type = IF_DATA_TYPE_INT; fields(7)%offset_bytes = offset; offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%TypeName()), fields, 7, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshDesc_RegLayout")
  END SUBROUTINE MeshDesc_RegLayout

  SUBROUTINE MeshDesc_Ensure(this)
    CLASS(MeshDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CHARACTER(len=64) :: vn
    CALL init_error_status(status)
    IF (LEN_TRIM(this%VarName()) == 0) THEN
      WRITE(vn, '(A,I0)') 'UF_MESHDESC_', this%meshId
      CALL this%SetVarName(TRIM(vn))
    END IF
    CALL dp_create_struct_array(TRIM(this%VarName()), [1,0,0,0], TRIM(this%TypeName()), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshDesc_Ensure")
  END SUBROUTINE MeshDesc_Ensure

  !=============================================================================
  ! MeshState Procedures
  !=============================================================================
  SUBROUTINE MeshState_Init(this, n)
    CLASS(MeshState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    CALL StateBase_Init(this, n)
    this%algo_category = CAT_STATE
  END SUBROUTINE MeshState_Init

  SUBROUTINE MeshState_RegLayout(this)
    CLASS(MeshState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'nNodes'; fields(1)%data_type = IF_DATA_TYPE_INT; fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'nElems'; fields(2)%data_type = IF_DATA_TYPE_INT; fields(2)%offset_bytes = offset; offset = offset + 4
    fields(3)%field_name = 'isActive'; fields(3)%data_type = IF_DATA_TYPE_INT; fields(3)%offset_bytes = offset; offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%TypeName()), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshState_RegLayout")
  END SUBROUTINE MeshState_RegLayout

  SUBROUTINE MeshState_Ensure(this)
    CLASS(MeshState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%VarName()) == 0) CALL this%SetVarName('UF_MESHSTATE')
    CALL dp_create_struct_array(TRIM(this%VarName()), [1,0,0,0], TRIM(this%TypeName()), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshState_Ensure")
  END SUBROUTINE MeshState_Ensure

  !=============================================================================
  ! MeshCtx Procedures
  !=============================================================================
  SUBROUTINE MeshCtx_Init(this)
    CLASS(MeshCtx), INTENT(INOUT) :: this
    CALL CtxBase_Init(this)
    CALL this%SetTypeName('CTX::MESH')
  END SUBROUTINE MeshCtx_Init

  SUBROUTINE MeshCtx_RegLayout(this)
    CLASS(MeshCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(1)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'meshId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%TypeName()), fields, 1, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshCtx_RegLayout")
  END SUBROUTINE MeshCtx_RegLayout

  SUBROUTINE MeshCtx_Ensure(this)
    CLASS(MeshCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CHARACTER(len=64) :: vn
    CALL init_error_status(status)
    IF (LEN_TRIM(this%VarName()) == 0) THEN
      WRITE(vn, '(A,I0)') 'UF_MESHCTX_', this%meshId
      CALL this%SetVarName(TRIM(vn))
    END IF
    CALL dp_create_struct_array(TRIM(this%VarName()), [1,0,0,0], TRIM(this%TypeName()), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshCtx_Ensure")
  END SUBROUTINE MeshCtx_Ensure

END MODULE MD_Mesh_Data
