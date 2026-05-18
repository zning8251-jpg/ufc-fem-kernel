!===============================================================================
! MODULE:  MD_DOF_Mgr
! LAYER:   L3_MD
! DOMAIN:  Mesh / DOF
! ROLE:    _Mgr
! BRIEF:   DOF manager — DOF management and global numbering for FE mesh.
! **W2**：全局 **DOF 编号** / 约束与 **`MD_Elem_*`** 拓扑衔接；下行装配 **`RT_Elem_*`** 须与本模块口径一致（见 **Mesh/CONTRACT**）。
!===============================================================================

MODULE MD_DOF_Mgr
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
!> Status: CORE
!> Theory: (TODO) | Last verified: 2026-02-14
  !! UniField-Core DOF Module -   (Core | Mgr | API | Brg)
  !! Merged: MD_DOF_Type per UFC_SUFFIX_MINIMAL_PLAN
  !!
  !! Design: DataPlatform types (MD_DOFDesc/Sta/Ctx, MD_NodalDOFDesc/Sta) + runtime DOF system

  USE IF_Base_DP,      only: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
       IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
  USE IF_Err_Brg,         only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, uf_set_error_status
  USE IF_Prec_Core,        only: i4, i8, wp
  USE MD_Base_ObjModel, only: UF_CoreObjectBase, DescBase, StateBase, CtxBase, &
       CAT_DESC, CAT_STATE, CAT_CTX, RT_Model, UF_DOF_U1, UF_DOF_U2, UF_DOF_U3, UF_DOF_TEMP, UF_DOF_POR

  implicit none
  private

  ! Constants (declare first, then public list)
  integer(i4), parameter :: MD_MESH_MAX_DOF_PER_NOD = 16_i4
  integer(i4), parameter :: MD_MESH_DOF_INACTIVE = 0_i4
  integer(i4), parameter :: MD_MESH_DOF_FREE = 1_i4
  integer(i4), parameter :: MD_MESH_DOF_FIXED = 2_i4
  integer(i4), parameter :: MD_MESH_DOF_PRESCRIBED = 3_i4
  integer(i4), parameter :: MD_MESH_DOF_SLAVE = 4_i4
  integer(i4), parameter :: MD_MESH_DOF_LAGRANGE = 5_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_U1 = 1_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_U2 = 2_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_U3 = 3_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_U4 = 4_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_U5 = 5_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_U6 = 6_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_T1 = 7_i4
  integer(i4), parameter :: MD_MESH_DOF_LBL_P1 = 8_i4
  integer(i4), parameter :: MD_MESH_DOF_VAL_DISP = 1_i4
  integer(i4), parameter :: MD_MESH_DOF_VAL_VEL  = 2_i4
  integer(i4), parameter :: MD_MESH_DOF_VAL_ACC  = 3_i4

  ! Types from former MD_DOF_Type (DataPlatform registration)
  public :: MD_DOFDesc, MD_DOFSta, MD_DOFCtx
  public :: MD_NodalDOFDesc, MD_NodalDOFSta
  public :: MD_DOF
  public :: MD_NodalDOF
  public :: MD_DOFMap
  public :: MD_MESH_MAX_DOF_PER_NOD
  public :: MD_MESH_DOF_LBL_U1, MD_MESH_DOF_LBL_U2, MD_MESH_DOF_LBL_U3
  public :: MD_MESH_DOF_LBL_U4, MD_MESH_DOF_LBL_U5, MD_MESH_DOF_LBL_U6
  public :: MD_MESH_DOF_LBL_T1, MD_MESH_DOF_LBL_P1
  public :: MD_MESH_DOF_VAL_DISP, MD_MESH_DOF_VAL_VEL, MD_MESH_DOF_VAL_ACC
  ! Merged from MD_DOF_LabelMap (2026-03-09)
  public :: UF_DOFLabelMapType, UF_DOFLabelMap_Init, UF_DOFLabelMap_Register
  public :: UF_DOFLabelMap_GetSlot, UF_DOFLabelMap_GetLabel

  !---------------------------------------------------------------------------
  ! UF_DOFLabelMapType: Map user-defined DOF labels to internal slots 1..maxSlots
  !---------------------------------------------------------------------------
  type, public :: UF_DOFLabelMapType
    integer(i4) :: maxSlots = 0_i4
    integer(i4), allocatable :: label_of_slot(:)
  end type UF_DOFLabelMapType

  !=============================================================================
  ! Types from former MD_DOF_Type (DataPlatform registration)
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_DOFDesc
    INTEGER(i4) :: dofId = 0_i4
    INTEGER(i4) :: numNodes = 0_i4
    INTEGER(i4) :: numTotalDOF = 0_i4
    INTEGER(i4) :: numFreeDOF = 0_i4
    INTEGER(i4) :: numFixedDOF = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_DOFDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_DOFDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_DOFDesc_Init
    PROCEDURE, PUBLIC :: Configure => MD_DOFDesc_Configure
  END TYPE MD_DOFDesc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_DOFSta
    INTEGER(i4) :: dofId = 0_i4
    INTEGER(i4) :: currentEqn = 0_i4
    LOGICAL :: isNumbered = .false.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_DOFSta_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_DOFSta_Ensure
    PROCEDURE, PUBLIC :: Init => MD_DOFSta_Init
  END TYPE MD_DOFSta

  TYPE, PUBLIC, EXTENDS(CtxBase) :: MD_DOFCtx
    INTEGER(i4) :: dofId = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_DOFCtx_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_DOFCtx_Ensure
    PROCEDURE, PUBLIC :: Init => MD_DOFCtx_Init
    PROCEDURE, PUBLIC :: Configure => MD_DOFCtx_Configure
  END TYPE MD_DOFCtx

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_NodalDOFDesc
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: numDOF = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_NodalDOFDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_NodalDOFDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_NodalDOFDesc_Init
    PROCEDURE, PUBLIC :: Configure => MD_NodalDOFDesc_Configure
  END TYPE MD_NodalDOFDesc

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_NodalDOFSta
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: dofStatus(16) = 0_i4
    INTEGER(i4) :: eqnNumber(16) = 0_i4
    REAL(wp) :: prescribedValue(16) = 0.0_wp
    REAL(wp) :: reaction(16) = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_NodalDOFSta_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_NodalDOFSta_Ensure
    PROCEDURE, PUBLIC :: Init => MD_NodalDOFSta_Init
  END TYPE MD_NodalDOFSta

  !=============================================================================
  ! Runtime DOF types
  !=============================================================================
  type, public, extends(UF_CoreObjectBase) :: MD_NodalDOF
    integer(i4) :: node_id = 0_i4
    integer(i4) :: nDof = 0_i4
    integer(i4) :: dof_status(MD_MESH_MAX_DOF_PER_NOD) = MD_MESH_DOF_INACTIVE
    integer(i4) :: eqn_number(MD_MESH_MAX_DOF_PER_NOD) = 0_i4
    real(wp) :: prescribed_value(MD_MESH_MAX_DOF_PER_NOD) = 0.0_wp
    real(wp) :: reaction(MD_MESH_MAX_DOF_PER_NOD) = 0.0_wp
    logical :: initialized = .false.
  contains
    procedure :: Setup => MD_NodalDOF_Setup
    procedure :: Activate
    procedure :: Fix
    procedure :: Prescribe
    procedure :: GetEqn
    procedure :: IsFree
    procedure :: GetStatus
    procedure :: GetPrescribedValue
    procedure :: GetReaction
    procedure :: SetReaction
  end type MD_NodalDOF

  type, public :: MD_DOFMap
    integer(i4) :: nNode = 0_i4
    integer(i4) :: maxDpn = 0_i4
    integer(i4), pointer :: ndof(:) => null()
    integer(i4), pointer :: eq(:,:) => null()
    logical :: initialized = .false.
  contains
    procedure :: Init => MD_DOFMap_Init
    procedure :: Free => MD_DOFMap_Free
    procedure :: SetNdof
    procedure :: MakeEq
    procedure :: GetEq
    procedure :: NodeRng
    procedure :: NEq
  end type MD_DOFMap

  type, public, extends(UF_CoreObjectBase) :: MD_DOF
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: num_total_dof = 0_i4
    integer(i4) :: num_free_dof = 0_i4
    integer(i4) :: num_fixed_dof = 0_i4
    integer(i4) :: num_prescribed = 0_i4
    type(MD_NodalDOF), allocatable :: nodal_dofs(:)
    type(MD_DOFMap) :: map_core
    integer(i4), allocatable :: dof_to_node(:)
    integer(i4), allocatable :: dof_to_local(:)
    real(wp), allocatable :: displacement(:)
    real(wp), allocatable :: velocity(:)
    real(wp), allocatable :: acceleration(:)
    integer(i4), allocatable :: label_to_slot(:)
    integer(i4), allocatable :: slot_to_label(:)
    integer(i4) :: num_slots = 0_i4
    logical :: initialized = .false.
  contains
    procedure :: Setup => MD_DOF_Setup
    procedure :: Free => MD_DOF_Free
    procedure :: ActivateDOFs
    procedure :: FixDOF
    procedure :: PrescribeDOF
    procedure :: NumberEquations
    procedure :: GetNodalDOF
    procedure :: GetElementDOFs
    procedure :: AssembleVector
    procedure :: ScatterSolution
    procedure :: GetDisplacement
    procedure :: SetDisplacement
    procedure :: SetVelocity
    procedure :: GetAcceleration
    procedure :: SetAcceleration
    procedure :: GetDOFValue
    procedure :: SetDOFValue
    procedure :: GetDOFStatus
    procedure :: InitLabelMap
    procedure :: RegisterLabel
    procedure :: GetSlotFromLabel
    procedure :: GetLabelFromSlot
    procedure :: HasLabel
    procedure :: GetNumLabels
    procedure :: ActivateByLabel
    procedure :: FixByLabel
    procedure :: PrescribeByLabel
    procedure :: GetEqnByLabel
    procedure :: IsFreeByLabel
    procedure :: GetDOFValueByLabel
    procedure :: SetDOFValueByLabel
  end type MD_DOF

contains

  !=============================================================================
  ! Procedures from former MD_DOF_Type (DataPlatform registration)
  !=============================================================================
  SUBROUTINE MD_DOFDesc_Init(this)
    CLASS(MD_DOFDesc), INTENT(INOUT) :: this
    this%algo_category = CAT_DESC
    this%algo_type_name = 'DESC::DOF'
    this%is_init = .TRUE.
  END SUBROUTINE MD_DOFDesc_Init

  SUBROUTINE MD_DOFDesc_Configure(this, dofId, name, numNodes, numTotalDOF, numFreeDOF, numFixedDOF)
    CLASS(MD_DOFDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofId, numNodes, numTotalDOF, numFreeDOF, numFixedDOF
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name
    IF (PRESENT(dofId)) this%dofId = dofId
    IF (PRESENT(name)) this%name = TRIM(name)
    IF (PRESENT(numNodes)) this%numNodes = numNodes
    IF (PRESENT(numTotalDOF)) this%numTotalDOF = numTotalDOF
    IF (PRESENT(numFreeDOF)) this%numFreeDOF = numFreeDOF
    IF (PRESENT(numFixedDOF)) this%numFixedDOF = numFixedDOF
  END SUBROUTINE MD_DOFDesc_Configure

  SUBROUTINE MD_DOFDesc_RegLayout(this)
    CLASS(MD_DOFDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(6)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'dofId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'numNodes'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'numTotalDOF'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'numFreeDOF'
    fields(5)%data_type = IF_DATA_TYPE_INT
    fields(5)%offset_bytes = offset
    offset = offset + 4
    fields(6)%field_name = 'numFixedDOF'
    fields(6)%data_type = IF_DATA_TYPE_INT
    fields(6)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%algo_type_name), fields, 6, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DOFDesc_RegLayout")
  END SUBROUTINE MD_DOFDesc_RegLayout

  SUBROUTINE MD_DOFDesc_Ensure(this)
    CLASS(MD_DOFDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%algo_var_name) == 0) WRITE(this%algo_var_name, '(A,I0)') 'UF_DOFDESC_', this%dofId
    CALL dp_create_struct_array(TRIM(this%algo_var_name), [1,0,0,0], TRIM(this%algo_type_name), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DOFDesc_Ensure")
  END SUBROUTINE MD_DOFDesc_Ensure

  SUBROUTINE MD_DOFSta_Init(this, n)
    CLASS(MD_DOFSta), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    this%algo_category = CAT_STATE
    this%algo_type_name = 'STATE::DOF'
    this%is_init = .TRUE.
    IF (PRESENT(n)) this%dofId = n
  END SUBROUTINE MD_DOFSta_Init

  SUBROUTINE MD_DOFSta_RegLayout(this)
    CLASS(MD_DOFSta), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'dofId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'currentEqn'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'isNumbered'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%algo_type_name), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DOFSta_RegLayout")
  END SUBROUTINE MD_DOFSta_RegLayout

  SUBROUTINE MD_DOFSta_Ensure(this)
    CLASS(MD_DOFSta), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%algo_var_name) == 0) WRITE(this%algo_var_name, '(A,I0)') 'UF_DOFSTATE_', this%dofId
    CALL dp_create_struct_array(TRIM(this%algo_var_name), [1,0,0,0], TRIM(this%algo_type_name), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DOFSta_Ensure")
  END SUBROUTINE MD_DOFSta_Ensure

  SUBROUTINE MD_DOFCtx_Init(this)
    CLASS(MD_DOFCtx), INTENT(INOUT) :: this
    this%algo_category = CAT_CTX
    this%algo_type_name = 'CTX::DOF'
    this%is_init = .TRUE.
  END SUBROUTINE MD_DOFCtx_Init

  SUBROUTINE MD_DOFCtx_Configure(this, dofId)
    CLASS(MD_DOFCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofId
    IF (PRESENT(dofId)) this%dofId = dofId
  END SUBROUTINE MD_DOFCtx_Configure

  SUBROUTINE MD_DOFCtx_RegLayout(this)
    CLASS(MD_DOFCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(1)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'dofId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%algo_type_name), fields, 1, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DOFCtx_RegLayout")
  END SUBROUTINE MD_DOFCtx_RegLayout

  SUBROUTINE MD_DOFCtx_Ensure(this)
    CLASS(MD_DOFCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%algo_var_name) == 0) WRITE(this%algo_var_name, '(A,I0)') 'UF_DOFCTX_', this%dofId
    CALL dp_create_struct_array(TRIM(this%algo_var_name), [1,0,0,0], TRIM(this%algo_type_name), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DOFCtx_Ensure")
  END SUBROUTINE MD_DOFCtx_Ensure

  SUBROUTINE MD_NodalDOFDesc_Init(this)
    CLASS(MD_NodalDOFDesc), INTENT(INOUT) :: this
    this%algo_category = CAT_DESC
    this%algo_type_name = 'DESC::NODALDOF'
    this%is_init = .TRUE.
  END SUBROUTINE MD_NodalDOFDesc_Init

  SUBROUTINE MD_NodalDOFDesc_Configure(this, id, numDOF)
    CLASS(MD_NodalDOFDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, numDOF
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(numDOF)) this%numDOF = numDOF
  END SUBROUTINE MD_NodalDOFDesc_Configure

  SUBROUTINE MD_NodalDOFDesc_RegLayout(this)
    CLASS(MD_NodalDOFDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(2)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'numDOF'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%algo_type_name), fields, 2, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_NodalDOFDesc_RegLayout")
  END SUBROUTINE MD_NodalDOFDesc_RegLayout

  SUBROUTINE MD_NodalDOFDesc_Ensure(this)
    CLASS(MD_NodalDOFDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%algo_var_name) == 0) WRITE(this%algo_var_name, '(A,I0)') 'UF_NODALDOFDESC_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%algo_var_name), [1,0,0,0], TRIM(this%algo_type_name), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_NodalDOFDesc_Ensure")
  END SUBROUTINE MD_NodalDOFDesc_Ensure

  SUBROUTINE MD_NodalDOFSta_Init(this, n)
    CLASS(MD_NodalDOFSta), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    this%algo_category = CAT_STATE
    this%algo_type_name = 'STATE::NODALDOF'
    this%is_init = .TRUE.
    IF (PRESENT(n)) this%cfg%id = n
  END SUBROUTINE MD_NodalDOFSta_Init

  SUBROUTINE MD_NodalDOFSta_RegLayout(this)
    CLASS(MD_NodalDOFSta), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'dofStatus'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'eqnNumber'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 64
    fields(4)%field_name = 'prescribedValue'
    fields(4)%data_type = IF_DATA_TYPE_DP
    fields(4)%offset_bytes = offset
    offset = offset + 128
    fields(5)%field_name = 'reaction'
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%offset_bytes = offset
    offset = offset + 128
    CALL dp_register_struct_type(TRIM(this%algo_type_name), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_NodalDOFSta_RegLayout")
  END SUBROUTINE MD_NodalDOFSta_RegLayout

  SUBROUTINE MD_NodalDOFSta_Ensure(this)
    CLASS(MD_NodalDOFSta), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%algo_var_name) == 0) WRITE(this%algo_var_name, '(A,I0)') 'UF_NODALDOFSTATE_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%algo_var_name), [1,0,0,0], TRIM(this%algo_type_name), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_NodalDOFSta_Ensure")
  END SUBROUTINE MD_NodalDOFSta_Ensure

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_Init
  ! Function: Setup nodal DOF (node_id, nDof)
  !-----------------------------------------------------------------------------
  subroutine MD_NodalDOF_Setup(this, node_id, nDof)
    class(MD_NodalDOF), intent(out) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: nDof

    this%algo_category = CAT_STATE
    this%algo_type_name = "MD_NodalDOF"
    this%algo_var_name = "nodaldof"

    this%node_id = node_id
    this%nDof = min(nDof, MD_MESH_MAX_DOF_PER_NOD)
    this%dof_status = MD_MESH_DOF_INACTIVE
    this%dof_status(1:this%nDof) = MD_MESH_DOF_FREE
    this%eqn_number = 0_i4
    this%prescribed_value = 0.0_wp
    this%reaction = 0.0_wp

    this%initialized = .true.
  end subroutine MD_NodalDOF_Setup

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_Activate
  ! Function: Activate DOF
  !-----------------------------------------------------------------------------
  subroutine Activate(this, dof)
    class(MD_NodalDOF), intent(inout) :: this
    integer(i4), intent(in) :: dof

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "NodalDof is not initialized", "NodalDof_Activate")
      return
    end if

    if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
      if (this%dof_status(dof) == MD_MESH_DOF_INACTIVE) then
        this%dof_status(dof) = MD_MESH_DOF_FREE
        this%nDof = max(this%nDof, dof)
      end if
    end if
  end subroutine Activate

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_Fix
  ! Function: Fix DOF
  !-----------------------------------------------------------------------------
  subroutine Fix(this, dof)
    class(MD_NodalDOF), intent(inout) :: this
    integer(i4), intent(in) :: dof

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "NodalDof is not initialized", "NodalDof_Fix")
      return
    end if

    if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
      this%dof_status(dof) = MD_MESH_DOF_FIXED
      this%prescribed_value(dof) = 0.0_wp
    end if
  end subroutine Fix

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_Prescribe
  ! Function: Prescribe DOF value
  !-----------------------------------------------------------------------------
  subroutine Prescribe(this, dof, value)
    class(MD_NodalDOF), intent(inout) :: this
    integer(i4), intent(in) :: dof
    real(wp), intent(in) :: value

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "NodalDof is not initialized", "NodalDof_Prescribe")
      return
    end if

    if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
      this%dof_status(dof) = MD_MESH_DOF_PRESCRIBED
      this%prescribed_value(dof) = value
    end if
  end subroutine Prescribe

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_GetEqn
  ! Function: Get equation number
  !-----------------------------------------------------------------------------
  function GetEqn(this, dof) result(eqn)
    class(MD_NodalDOF), intent(in) :: this
    integer(i4), intent(in) :: dof
    integer(i4) :: eqn

    eqn = 0_i4

    if (this%initialized) then
      if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
        eqn = this%eqn_number(dof)
      end if
    end if
  end function GetEqn

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_IsFree
  ! Function: Check if DOF is free
  !-----------------------------------------------------------------------------
  function IsFree(this, dof) result(is_free)
    class(MD_NodalDOF), intent(in) :: this
    integer(i4), intent(in) :: dof
    logical :: is_free

    is_free = .false.

    if (this%initialized) then
      if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
        is_free = (this%dof_status(dof) == MD_MESH_DOF_FREE)
      end if
    end if
  end function IsFree

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_GetStatus
  ! Function: Get DOF status
  !-----------------------------------------------------------------------------
  function GetStatus(this, dof) result(status_val)
    class(MD_NodalDOF), intent(in) :: this
    integer(i4), intent(in) :: dof
    integer(i4) :: status_val

    status_val = MD_MESH_DOF_INACTIVE

    if (this%initialized) then
      if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
        status_val = this%dof_status(dof)
      end if
    end if
  end function GetStatus

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_GetPrescribedValue
  ! Function: Get prescribed value
  !-----------------------------------------------------------------------------
  function GetPrescribedValue(this, dof) result(value)
    class(MD_NodalDOF), intent(in) :: this
    integer(i4), intent(in) :: dof
    real(wp) :: value

    value = 0.0_wp

    if (this%initialized) then
      if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
        value = this%prescribed_value(dof)
      end if
    end if
  end function GetPrescribedValue

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_GetReaction
  ! Function: Get reaction force
  !-----------------------------------------------------------------------------
  function GetReaction(this, dof) result(reaction)
    class(MD_NodalDOF), intent(in) :: this
    integer(i4), intent(in) :: dof
    real(wp) :: reaction

    reaction = 0.0_wp

    if (this%initialized) then
      if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
        reaction = this%reaction(dof)
      end if
    end if
  end function GetReaction

  !-----------------------------------------------------------------------------
  ! Original name: NodalDof_SetReaction
  ! Function: Set reaction force
  !-----------------------------------------------------------------------------
  subroutine SetReaction(this, dof, reaction)
    class(MD_NodalDOF), intent(inout) :: this
    integer(i4), intent(in) :: dof
    real(wp), intent(in) :: reaction

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "NodalDof is not initialized", "NodalDof_SetReaction")
      return
    end if

    if (dof >= 1 .and. dof <= MD_MESH_MAX_DOF_PER_NOD) then
      this%reaction(dof) = reaction
    end if
  end subroutine SetReaction

  !-----------------------------------------------------------------------------
  ! Function: Setup DOF system
  !-----------------------------------------------------------------------------
  subroutine MD_DOF_Setup(this, nNodes, dof_per_node)
    class(MD_DOF), intent(out) :: this
    integer(i4), intent(in) :: nNodes
    integer(i4), intent(in) :: dof_per_node
    integer(i4) :: i

    this%algo_category = CAT_STATE
    this%algo_type_name = "MD_DOF"
    this%algo_var_name = "dof"

    this%nNodes = nNodes
    this%num_total_dof = 0_i4
    this%num_free_dof = 0_i4
    this%num_fixed_dof = 0_i4
    this%num_prescribed = 0_i4

    allocate(this%nodal_dofs(nNodes))
    do i = 1, nNodes
      call this%nodal_dofs(i)%Setup(i, dof_per_node)
    end do

    call this%map_core%Init(nNodes, dof_per_node)

    this%initialized = .true.
  end subroutine MD_DOF_Setup

  !-----------------------------------------------------------------------------
  ! Original name: Dof_Free
  ! Function: Free DOF system
  !-----------------------------------------------------------------------------
  subroutine MD_DOF_Free(this)
    class(MD_DOF), intent(inout) :: this

    if (allocated(this%nodal_dofs)) deallocate(this%nodal_dofs)
    if (allocated(this%dof_to_node)) deallocate(this%dof_to_node)
    if (allocated(this%dof_to_local)) deallocate(this%dof_to_local)
    if (allocated(this%displacement)) deallocate(this%displacement)
    if (allocated(this%velocity)) deallocate(this%velocity)
    if (allocated(this%acceleration)) deallocate(this%acceleration)

    call this%map_core%Free()

    this%nNodes = 0_i4
    this%num_total_dof = 0_i4
    this%num_free_dof = 0_i4
    this%num_fixed_dof = 0_i4
    this%num_prescribed = 0_i4
    this%initialized = .false.
  end subroutine MD_DOF_Free

  !-----------------------------------------------------------------------------
  ! Original name: Dof_ActivateDOFs
  ! Function: Activate DOFs
  !-----------------------------------------------------------------------------
  subroutine ActivateDOFs(this, node_id, dof_list, nDof)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof_list(:)
    integer(i4), intent(in) :: nDof
    integer(i4) :: i

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_ActivateDOFs")
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid node ID", "Dof_ActivateDOFs")
      return
    end if

    do i = 1, nDof
      call this%nodal_dofs(node_id)%Activate(dof_list(i))
    end do
  end subroutine ActivateDOFs

  !-----------------------------------------------------------------------------
  ! Original name: Dof_FixDOF
  ! Function: Fix DOF
  !-----------------------------------------------------------------------------
  subroutine FixDOF(this, node_id, dof)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_FixDOF")
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid node ID", "Dof_FixDOF")
      return
    end if

    call this%nodal_dofs(node_id)%Fix(dof)
  end subroutine FixDOF

  !-----------------------------------------------------------------------------
  ! Original name: Dof_PrescribeDOF
  ! Function: Prescribe DOF value
  !-----------------------------------------------------------------------------
  subroutine PrescribeDOF(this, node_id, dof, value)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof
    real(wp), intent(in) :: value

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_PrescribeDOF")
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid node ID", "Dof_PrescribeDOF")
      return
    end if

    call this%nodal_dofs(node_id)%Prescribe(dof, value)
  end subroutine PrescribeDOF

  !-----------------------------------------------------------------------------
  ! Original name: Dof_NumberEquations
  ! Function: Number equations
  !-----------------------------------------------------------------------------
  subroutine NumberEquations(this)
    class(MD_DOF), intent(inout) :: this
    integer(i4) :: i, j, eqn

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_NumberEquations")
      return
    end if

    this%num_total_dof = 0_i4
    this%num_free_dof = 0_i4
    this%num_fixed_dof = 0_i4
    this%num_prescribed = 0_i4

    do i = 1, this%nNodes
      do j = 1, MD_MESH_MAX_DOF_PER_NOD
        if (this%nodal_dofs(i)%dof_status(j) /= MD_MESH_DOF_INACTIVE) then
          this%num_total_dof = this%num_total_dof + 1_i4

          if (this%nodal_dofs(i)%dof_status(j) == MD_MESH_DOF_FREE) then
            this%num_free_dof = this%num_free_dof + 1_i4
            eqn = this%num_free_dof
            this%nodal_dofs(i)%eqn_number(j) = eqn
          else if (this%nodal_dofs(i)%dof_status(j) == MD_MESH_DOF_FIXED) then
            this%num_fixed_dof = this%num_fixed_dof + 1_i4
            this%nodal_dofs(i)%eqn_number(j) = 0_i4
          else if (this%nodal_dofs(i)%dof_status(j) == MD_MESH_DOF_PRESCRIBED) then
            this%num_prescribed = this%num_prescribed + 1_i4
            this%nodal_dofs(i)%eqn_number(j) = 0_i4
          end if
        end if
      end do
    end do

    if (allocated(this%dof_to_node)) deallocate(this%dof_to_node)
    if (allocated(this%dof_to_local)) deallocate(this%dof_to_local)

    allocate(this%dof_to_node(this%num_free_dof))
    allocate(this%dof_to_local(this%num_free_dof))

    eqn = 0
    do i = 1, this%nNodes
      do j = 1, MD_MESH_MAX_DOF_PER_NOD
        if (this%nodal_dofs(i)%dof_status(j) == MD_MESH_DOF_FREE) then
          eqn = eqn + 1_i4
          this%dof_to_node(eqn) = i
          this%dof_to_local(eqn) = j
        end if
      end do
    end do

    if (allocated(this%displacement)) deallocate(this%displacement)
    if (allocated(this%velocity)) deallocate(this%velocity)
    if (allocated(this%acceleration)) deallocate(this%acceleration)

    allocate(this%displacement(this%num_free_dof))
    allocate(this%velocity(this%num_free_dof))
    allocate(this%acceleration(this%num_free_dof))

    this%displacement = 0.0_wp
    this%velocity = 0.0_wp
    this%acceleration = 0.0_wp

    call this%map_core%MakeEq(0_i4)
  end subroutine NumberEquations

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetNodalDOF
  ! Function: Get nodal DOF
  !-----------------------------------------------------------------------------
  function GetNodalDOF(this, node_id) result(nodal_dof_ptr)
    class(MD_DOF), intent(in), target :: this
    integer(i4), intent(in) :: node_id
    type(MD_NodalDOF), pointer :: nodal_dof_ptr

    nodal_dof_ptr => null()

    if (this%initialized) then
      if (node_id >= 1 .and. node_id <= this%nNodes) then
        nodal_dof_ptr => this%nodal_dofs(node_id)
      end if
    end if
  end function GetNodalDOF

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetElementDOFs
  ! Function: Get element DOFs
  !-----------------------------------------------------------------------------
  subroutine GetElementDOFs(this, node_ids, dof_labels, eqn_numbers)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_ids(:)
    integer(i4), intent(in) :: dof_labels(:)
    integer(i4), intent(out) :: eqn_numbers(:)
    integer(i4) :: i, node_id, dof_label

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_GetElementDOFs")
      return
    end if

    do i = 1, size(node_ids)
      node_id = node_ids(i)
      dof_label = dof_labels(i)

      if (node_id >= 1 .and. node_id <= this%nNodes) then
        eqn_numbers(i) = this%nodal_dofs(node_id)%GetEqn(dof_label)
      else
        eqn_numbers(i) = 0_i4
      end if
    end do
  end subroutine GetElementDOFs

  !-----------------------------------------------------------------------------
  ! Original name: Dof_AssembleVector
  ! Function: Assemble vector
  !-----------------------------------------------------------------------------
  subroutine AssembleVector(this, node_id, dof_label, value, vector)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof_label
    real(wp), intent(in) :: value
    real(wp), intent(inout) :: vector(:)
    integer(i4) :: eqn

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_AssembleVector")
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid node ID", "Dof_AssembleVector")
      return
    end if

    eqn = this%nodal_dofs(node_id)%GetEqn(dof_label)

    if (eqn > 0 .and. eqn <= size(vector)) then
      vector(eqn) = vector(eqn) + value
    end if
  end subroutine AssembleVector

  !-----------------------------------------------------------------------------
  ! Original name: Dof_ScatterSolution
  ! Function: Scatter solution
  !-----------------------------------------------------------------------------
  subroutine ScatterSolution(this, solution)
    class(MD_DOF), intent(inout) :: this
    real(wp), intent(in) :: solution(:)

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_ScatterSolution")
      return
    end if

    if (size(solution) /= this%num_free_dof) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Solution vector size mismatch", "Dof_ScatterSolution")
      return
    end if

    this%displacement = solution
  end subroutine ScatterSolution

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetDisplacement
  ! Function: Get displacement
  !-----------------------------------------------------------------------------
  function GetDisplacement(this, eqn) result(value)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: eqn
    real(wp) :: value

    value = 0.0_wp

    if (this%initialized) then
      if (eqn >= 1 .and. eqn <= this%num_free_dof) then
        value = this%displacement(eqn)
      end if
    end if
  end function GetDisplacement

  !-----------------------------------------------------------------------------
  ! Original name: Dof_SetDisplacement
  ! Function: Set displacement
  !-----------------------------------------------------------------------------
  subroutine SetDisplacement(this, eqn, value)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: eqn
    real(wp), intent(in) :: value

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_SetDisplacement")
      return
    end if

    if (eqn >= 1 .and. eqn <= this%num_free_dof) then
      this%displacement(eqn) = value
    end if
  end subroutine SetDisplacement

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetVelocity
  ! Function: Get velocity
  !-----------------------------------------------------------------------------
  function GetVelocity(this, eqn) result(value)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: eqn
    real(wp) :: value

    value = 0.0_wp

    if (this%initialized) then
      if (eqn >= 1 .and. eqn <= this%num_free_dof) then
        value = this%velocity(eqn)
      end if
    end if
  end function GetVelocity

  !-----------------------------------------------------------------------------
  ! Original name: Dof_SetVelocity
  ! Function: Set velocity
  !-----------------------------------------------------------------------------
  subroutine SetVelocity(this, eqn, value)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: eqn
    real(wp), intent(in) :: value

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_SetVelocity")
      return
    end if

    if (eqn >= 1 .and. eqn <= this%num_free_dof) then
      this%velocity(eqn) = value
    end if
  end subroutine SetVelocity

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetAcceleration
  ! Function: Get acceleration
  !-----------------------------------------------------------------------------
  function GetAcceleration(this, eqn) result(value)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: eqn
    real(wp) :: value

    value = 0.0_wp

    if (this%initialized) then
      if (eqn >= 1 .and. eqn <= this%num_free_dof) then
        value = this%acceleration(eqn)
      end if
    end if
  end function GetAcceleration

  !-----------------------------------------------------------------------------
  ! Original name: Dof_SetAcceleration
  ! Function: Set acceleration
  !-----------------------------------------------------------------------------
  subroutine SetAcceleration(this, eqn, value)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: eqn
    real(wp), intent(in) :: value

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_SetAcceleration")
      return
    end if

    if (eqn >= 1 .and. eqn <= this%num_free_dof) then
      this%acceleration(eqn) = value
    end if
  end subroutine SetAcceleration

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetDOFValue
  ! Function: Get DOF value
  !-----------------------------------------------------------------------------
  function GetDOFValue(this, node_id, dof_label) result(value)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof_label
    integer(i4) :: eqn
    real(wp) :: value

    value = 0.0_wp

    if (this%initialized) then
      if (node_id >= 1 .and. node_id <= this%nNodes) then
        if (dof_label >= 1 .and. dof_label <= MD_MESH_MAX_DOF_PER_NOD) then
          eqn = this%nodal_dofs(node_id)%GetEqn(dof_label)
          if (eqn > 0 .and. eqn <= this%num_free_dof) then
            value = this%displacement(eqn)
          else if (this%nodal_dofs(node_id)%dof_status(dof_label) == MD_MESH_DOF_PRESCRIBED) then
            value = this%nodal_dofs(node_id)%prescribed_value(dof_label)
          end if
        end if
      end if
    end if
  end function GetDOFValue

  !-----------------------------------------------------------------------------
  ! Original name: Dof_SetDOFValue
  ! Function: Set DOF value
  !-----------------------------------------------------------------------------
  subroutine SetDOFValue(this, node_id, dof_label, value)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof_label
    real(wp), intent(in) :: value
    integer(i4) :: eqn

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Dof is not initialized", "Dof_SetDOFValue")
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid node ID", "Dof_SetDOFValue")
      return
    end if

    if (dof_label < 1 .or. dof_label > MD_MESH_MAX_DOF_PER_NOD) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid DOF label", "Dof_SetDOFValue")
      return
    end if

    eqn = this%nodal_dofs(node_id)%GetEqn(dof_label)

    if (eqn > 0 .and. eqn <= this%num_free_dof) then
      this%displacement(eqn) = value
    else if (this%nodal_dofs(node_id)%dof_status(dof_label) == MD_MESH_DOF_PRESCRIBED) then
      this%nodal_dofs(node_id)%prescribed_value(dof_label) = value
    end if
  end subroutine SetDOFValue

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetDOFStatus
  ! Function: Get DOF status
  !-----------------------------------------------------------------------------
  function GetDOFStatus(this, node_id, dof_label) result(status_val)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: dof_label
    integer(i4) :: status_val

    status_val = MD_MESH_DOF_INACTIVE

    if (this%initialized) then
      if (node_id >= 1 .and. node_id <= this%nNodes) then
        if (dof_label >= 1 .and. dof_label <= MD_MESH_MAX_DOF_PER_NOD) then
          status_val = this%nodal_dofs(node_id)%dof_status(dof_label)
        end if
      end if
    end if
  end function GetDOFStatus

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_Init
  ! Function: Init DOF map
  !-----------------------------------------------------------------------------
  subroutine MD_DOFMap_Init(this, nNode, maxDpn)
    class(MD_DOFMap), intent(out) :: this
    integer(i4), intent(in) :: nNode
    integer(i4), intent(in) :: maxDpn

    if (nNode < 0 .or. maxDpn < 0) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Invalid dimensions for DofMap", "DofMap_Init")
      return
    end if

    this%nNode = nNode
    this%maxDpn = maxDpn

    if (nNode > 0 .and. maxDpn > 0) then
      allocate(this%ndof(nNode))
      allocate(this%eq(nNode, maxDpn))
      this%ndof = 0_i4
      this%eq = 0_i4
    end if

    this%initialized = .true.
  end subroutine MD_DOFMap_Init

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_Free
  ! Function: Free DOF map
  !-----------------------------------------------------------------------------
  subroutine MD_DOFMap_Free(this)
    class(MD_DOFMap), intent(inout) :: this

    if (associated(this%ndof)) deallocate(this%ndof)
    if (associated(this%eq)) deallocate(this%eq)

    this%nNode = 0_i4
    this%maxDpn = 0_i4
    this%initialized = .false.
  end subroutine MD_DOFMap_Free

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_SetNdof
  ! Function: Set number of DOFs
  !-----------------------------------------------------------------------------
  subroutine SetNdof(this, node, nd)
    class(MD_DOFMap), intent(inout) :: this
    integer(i4), intent(in) :: node
    integer(i4), intent(in) :: nd

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "DofMap is not initialized", "DofMap_SetNdof")
      return
    end if

    if (node < 1 .or. node > this%nNode) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Node index is out of range", "DofMap_SetNdof")
      return
    end if

    if (nd < 0 .or. nd > this%maxDpn) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Number of DOFs is out of range", "DofMap_SetNdof")
      return
    end if

    if (associated(this%ndof)) then
      this%ndof(node) = nd
    end if
  end subroutine SetNdof

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_MakeEq
  ! Function: Make equation numbers
  !-----------------------------------------------------------------------------
  subroutine MakeEq(this, eq0)
    class(MD_DOFMap), intent(inout) :: this
    integer(i4), intent(in) :: eq0
    integer(i4) :: n, s, e

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "DofMap is not initialized", "DofMap_MakeEq")
      return
    end if

    if (.not. associated(this%ndof) .or. .not. associated(this%eq)) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "DofMap arrays are not allocated", "DofMap_MakeEq")
      return
    end if

    e = eq0
    do n = 1, this%nNode
      do s = 1, this%ndof(n)
        e = e + 1_i4
        if (s <= this%maxDpn) then
          this%eq(n, s) = e
        end if
      end do
    end do
  end subroutine MakeEq

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_GetEq
  ! Function: Get equation number
  !-----------------------------------------------------------------------------
  function GetEq(this, node, slot) result(eq)
    class(MD_DOFMap), intent(in) :: this
    integer(i4), intent(in) :: node
    integer(i4), intent(in) :: slot
    integer(i4) :: eq

    eq = 0_i4

    if (.not. this%initialized) return
    if (.not. associated(this%eq)) return

    if (node >= 1 .and. node <= this%nNode) then
      if (slot >= 1 .and. slot <= this%maxDpn) then
        eq = this%eq(node, slot)
      end if
    end if
  end function GetEq

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_NodeRng
  ! Function: Get node equation range
  !-----------------------------------------------------------------------------
  subroutine NodeRng(this, node, e1, e2)
    class(MD_DOFMap), intent(in) :: this
    integer(i4), intent(in) :: node
    integer(i4), intent(out) :: e1
    integer(i4), intent(out) :: e2

    e1 = 0_i4
    e2 = 0_i4

    if (.not. this%initialized) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "DofMap is not initialized", "DofMap_NodeRng")
      return
    end if

    if (.not. associated(this%ndof) .or. .not. associated(this%eq)) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "DofMap arrays are not allocated", "DofMap_NodeRng")
      return
    end if

    if (node < 1 .or. node > this%nNode) then
      CALL uf_set_error_status(IF_STATUS_INVALID, "Node index is out of range", "DofMap_NodeRng")
      return
    end if

    if (this%ndof(node) > 0) then
      e1 = this%eq(node, 1)
      e2 = this%eq(node, this%ndof(node))
    end if
  end subroutine NodeRng

  !-----------------------------------------------------------------------------
  ! Original name: DofMap_NEq
  ! Function: Get number of equations
  !-----------------------------------------------------------------------------
  function NEq(this) result(n_eq)
    class(MD_DOFMap), intent(in) :: this
    integer(i4) :: n_eq

    n_eq = 0_i4

    if (.not. this%initialized) return
    if (.not. associated(this%ndof)) return

    n_eq = sum(this%ndof)
  end function NEq

  !-----------------------------------------------------------------------------
  ! Original name: Dof_InitLabelMap
  ! Function: Init label map
  !-----------------------------------------------------------------------------
  subroutine InitLabelMap(this, num_slots, status)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: num_slots
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    this%num_slots = max(num_slots, 0_i4)

    if (this%num_slots > 0_i4) then
      allocate(this%label_to_slot(MD_MESH_MAX_DOF_PER_NOD))
      allocate(this%slot_to_label(this%num_slots))
      this%label_to_slot = 0_i4
      this%slot_to_label = 0_i4
    end if

    status%status_code = IF_STATUS_OK
  end subroutine InitLabelMap

  !-----------------------------------------------------------------------------
  ! Original name: Dof_RegisterLabel
  ! Function: Reg label
  !-----------------------------------------------------------------------------
  subroutine RegisterLabel(this, label, slot, status)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: label
    integer(i4), intent(inout) :: slot
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label is out of valid range"
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    if (this%label_to_slot(label) > 0_i4) then
      slot = this%label_to_slot(label)
      status%status_code = IF_STATUS_OK
      return
    end if

    if (slot < 1_i4 .or. slot > this%num_slots) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Slot is out of range"
      return
    end if

    if (this%slot_to_label(slot) == 0_i4) then
      this%label_to_slot(label) = slot
      this%slot_to_label(slot) = label
    else if (this%slot_to_label(slot) /= label) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Slot is already occupied by a different label"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RegisterLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetSlotFromLabel
  ! Function: Get slot from label
  !-----------------------------------------------------------------------------
  subroutine GetSlotFromLabel(this, label, slot, status)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: label
    integer(i4), intent(out) :: slot
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    slot = 0_i4

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label is out of valid range"
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    slot = this%label_to_slot(label)

    status%status_code = IF_STATUS_OK
  end subroutine GetSlotFromLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetLabelFromSlot
  ! Function: Get label from slot
  !-----------------------------------------------------------------------------
  subroutine GetLabelFromSlot(this, slot, label_out, status)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: slot
    integer(i4), intent(out) :: label_out
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    label_out = 0_i4

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (.not. allocated(this%slot_to_label)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    if (slot >= 1 .and. slot <= this%num_slots) then
      label_out = this%slot_to_label(slot)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetLabelFromSlot

  !-----------------------------------------------------------------------------
  ! Original name: Dof_HasLabel
  ! Function: Check if label exists
  !-----------------------------------------------------------------------------
  function HasLabel(this, label) result(has_label)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: label
    logical :: has_label

    has_label = .false.

    if (this%initialized) then
      if (label >= 1 .and. label <= MD_MESH_MAX_DOF_PER_NOD) then
        if (allocated(this%label_to_slot)) then
          has_label = (this%label_to_slot(label) > 0_i4)
        end if
      end if
    end if
  end function HasLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetNumLabels
  ! Function: Get number of labels
  !-----------------------------------------------------------------------------
  function GetNumLabels(this) result(num_labels)
    class(MD_DOF), intent(in) :: this
    integer(i4) :: num_labels
    integer(i4) :: i

    num_labels = 0_i4

    if (this%initialized) then
      if (allocated(this%label_to_slot)) then
        do i = 1, MD_MESH_MAX_DOF_PER_NOD
          if (this%label_to_slot(i) > 0_i4) then
            num_labels = num_labels + 1_i4
          end if
        end do
      end if
    end if
  end function GetNumLabels

  !-----------------------------------------------------------------------------
  ! Original name: Dof_ActivateByLabel
  ! Function: Activate DOFs by label
  !-----------------------------------------------------------------------------
  subroutine ActivateByLabel(this, node_id, label_list, num_labels, status)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label_list(:)
    integer(i4), intent(in) :: num_labels
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, slot
    integer(i4) :: dof_list(MD_MESH_MAX_DOF_PER_NOD)

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    do i = 1, num_labels
      if (label_list(i) >= 1 .and. label_list(i) <= MD_MESH_MAX_DOF_PER_NOD) then
        slot = this%label_to_slot(label_list(i))
        if (slot > 0_i4) then
          dof_list(i) = slot
        else
          dof_list(i) = label_list(i)
        end if
      else
        dof_list(i) = label_list(i)
      end if
    end do

    call this%ActivateDOFs(node_id, dof_list, num_labels)

    status%status_code = IF_STATUS_OK
  end subroutine ActivateByLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_FixByLabel
  ! Function: Fix DOF by label
  !-----------------------------------------------------------------------------
  subroutine FixByLabel(this, node_id, label, status)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: slot

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label is out of valid range"
      return
    end if

    slot = this%label_to_slot(label)

    if (slot > 0_i4) then
      call this%FixDOF(node_id, slot)
    else
      call this%FixDOF(node_id, label)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine FixByLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_PrescribeByLabel
  ! Function: Prescribe DOF by label
  !-----------------------------------------------------------------------------
  subroutine PrescribeByLabel(this, node_id, label, value, status)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label
    real(wp), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: slot

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label is out of valid range"
      return
    end if

    slot = this%label_to_slot(label)

    if (slot > 0_i4) then
      call this%PrescribeDOF(node_id, slot, value)
    else
      call this%PrescribeDOF(node_id, label, value)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine PrescribeByLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetEqnByLabel
  ! Function: Get equation number by label
  !-----------------------------------------------------------------------------
  function GetEqnByLabel(this, node_id, label) result(eqn)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label
    integer(i4) :: eqn

    integer(i4) :: slot
    type(MD_NodalDOF), pointer :: nodal_dof_ptr

    eqn = 0_i4

    if (.not. this%initialized) then
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      return
    end if

    slot = this%label_to_slot(label)

    if (slot > 0_i4) then
      nodal_dof_ptr => this%GetNodalDOF(node_id)
      if (associated(nodal_dof_ptr)) then
        eqn = nodal_dof_ptr%GetEqn(slot)
      end if
    end if
  end function GetEqnByLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_IsFreeByLabel
  ! Function: Check if DOF is free by label
  !-----------------------------------------------------------------------------
  function IsFreeByLabel(this, node_id, label) result(is_free)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label
    logical :: is_free

    integer(i4) :: slot
    type(MD_NodalDOF), pointer :: nodal_dof_ptr

    is_free = .false.

    if (.not. this%initialized) then
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      return
    end if

    slot = this%label_to_slot(label)

    if (slot > 0_i4) then
      nodal_dof_ptr => this%GetNodalDOF(node_id)
      if (associated(nodal_dof_ptr)) then
        is_free = nodal_dof_ptr%IsFree(slot)
      end if
    end if
  end function IsFreeByLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_GetDOFValueByLabel
  ! Function: Get DOF value by label
  ! value_type: MD_MESH_DOF_VAL_DISP=1, MD_MESH_DOF_VAL_VEL=2, MD_MESH_DOF_VAL_ACC=3
  !-----------------------------------------------------------------------------
  function GetDOFValueByLabel(this, node_id, label, value_type) result(value)
    class(MD_DOF), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label
    integer(i4), intent(in) :: value_type
    real(wp) :: value

    integer(i4) :: slot, eqn
    type(MD_NodalDOF), pointer :: nd => null()

    value = 0.0_wp

    if (.not. this%initialized) return
    if (.not. allocated(this%label_to_slot)) return
    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) return

    slot = this%label_to_slot(label)
    if (slot <= 0_i4) return

    nd => this%GetNodalDOF(node_id)
    if (.not. associated(nd)) return

    eqn = nd%GetEqn(slot)
    if (eqn > 0_i4 .and. eqn <= this%num_free_dof) then
      select case (value_type)
      case (MD_MESH_DOF_VAL_DISP)
        value = this%displacement(eqn)
      case (MD_MESH_DOF_VAL_VEL)
        value = this%velocity(eqn)
      case (MD_MESH_DOF_VAL_ACC)
        value = this%acceleration(eqn)
      case default
        value = this%displacement(eqn)
      end select
    else if (value_type == MD_MESH_DOF_VAL_DISP) then
      value = this%GetDOFValue(node_id, slot)
    end if
  end function GetDOFValueByLabel

  !-----------------------------------------------------------------------------
  ! Original name: Dof_SetDOFValueByLabel
  ! Function: Set DOF value by label
  ! value_type: MD_MESH_DOF_VAL_DISP=1, MD_MESH_DOF_VAL_VEL=2, MD_MESH_DOF_VAL_ACC=3
  !-----------------------------------------------------------------------------
  subroutine SetDOFValueByLabel(this, node_id, label, value_type, value, status)
    class(MD_DOF), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    integer(i4), intent(in) :: label
    integer(i4), intent(in) :: value_type
    real(wp), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: slot, eqn
    type(MD_NodalDOF), pointer :: nd => null()

    call init_error_status(status)

    if (.not. this%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "DOF is not initialized"
      return
    end if

    if (node_id < 1 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    if (.not. allocated(this%label_to_slot)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label map is not initialized"
      return
    end if

    if (label < 1 .or. label > MD_MESH_MAX_DOF_PER_NOD) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Label is out of valid range"
      return
    end if

    slot = this%label_to_slot(label)
    if (slot <= 0_i4) slot = label

    nd => this%GetNodalDOF(node_id)
    if (.not. associated(nd)) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node"
      return
    end if

    eqn = nd%GetEqn(slot)
    if (eqn > 0_i4 .and. eqn <= this%num_free_dof) then
      select case (value_type)
      case (MD_MESH_DOF_VAL_DISP)
        this%displacement(eqn) = value
      case (MD_MESH_DOF_VAL_VEL)
        this%velocity(eqn) = value
      case (MD_MESH_DOF_VAL_ACC)
        this%acceleration(eqn) = value
      case default
        this%displacement(eqn) = value
      end select
    else
      if (value_type == MD_MESH_DOF_VAL_DISP) call this%SetDOFValue(node_id, slot, value)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine SetDOFValueByLabel

  !=============================================================================
  ! UF_DOFLabelMap_* (merged from MD_DOF_LabelMap 2026-03-09)
  ! Map user-defined DOF labels to internal slots 1..maxSlots
  !=============================================================================
  subroutine UF_DOFLabelMap_Init(map, maxSlots)
    type(UF_DOFLabelMapType), intent(inout) :: map
    integer(i4), intent(in) :: maxSlots

    if (allocated(map%label_of_slot)) deallocate(map%label_of_slot)
    if (maxSlots > 0_i4) then
      allocate(map%label_of_slot(maxSlots))
      map%label_of_slot = 0_i4
      map%maxSlots = maxSlots
    else
      map%maxSlots = 0_i4
    end if
  end subroutine UF_DOFLabelMap_Init

  subroutine UF_DOFLabelMap_Register(map, label, slot, ierr)
    type(UF_DOFLabelMapType), intent(inout) :: map
    integer(i4), intent(in) :: label
    integer(i4), intent(inout) :: slot
    integer(i4), intent(out) :: ierr
    integer(i4) :: j

    ierr = 0_i4
    if (.not. allocated(map%label_of_slot)) then
      ierr = 1_i4
      return
    end if
    do j = 1, map%maxSlots
      if (map%label_of_slot(j) == label) then
        slot = j
        return
      end if
    end do
    if (slot < 1_i4 .or. slot > map%maxSlots) then
      ierr = 2_i4
      return
    end if
    if (map%label_of_slot(slot) == 0_i4 .or. map%label_of_slot(slot) == label) then
      map%label_of_slot(slot) = label
    else
      ierr = 3_i4
    end if
  end subroutine UF_DOFLabelMap_Register

  subroutine UF_DOFLabelMap_GetSlot(map, label, slot)
    type(UF_DOFLabelMapType), intent(in) :: map
    integer(i4), intent(in) :: label
    integer(i4), intent(out) :: slot
    integer(i4) :: j

    slot = 0_i4
    if (.not. allocated(map%label_of_slot)) return
    do j = 1, map%maxSlots
      if (map%label_of_slot(j) == label) then
        slot = j
        return
      end if
    end do
  end subroutine UF_DOFLabelMap_GetSlot

  subroutine UF_DOFLabelMap_GetLabel(map, slot, labelOut)
    type(UF_DOFLabelMapType), intent(in) :: map
    integer(i4), intent(in) :: slot
    integer(i4), intent(out) :: labelOut

    labelOut = 0_i4
    if (.not. allocated(map%label_of_slot)) return
    if (slot < 1_i4 .or. slot > map%maxSlots) return
    labelOut = map%label_of_slot(slot)
  end subroutine UF_DOFLabelMap_GetLabel

END MODULE MD_DOF_Mgr
