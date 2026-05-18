!======================================================================
! Module: MD_Out_Def
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Context
! Purpose: Output context types for unified output interface.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Out_Def
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md
!> [CORE] Core output API system for unified output interface
!> Theory: Field output (? ??^n_stress, ? ??^n_strain, u ??^n_dof), History output (t_i, y_i)
!> Status: Production | Last verified: 2026-03-06

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Mem_Mgr, only: UF_Mem_AllocInt1D, UF_Mem_FreeInt1D, IF_MEM_DOMAIN_CMD
  USE IF_Prec_Core, only: i4, i8, wp
  USE MD_Base_ObjModel, only: DescBase, StateBase, CtxBase, CAT_DESC, CAT_STATE, CAT_CTX, uf_set_error_status
  use MD_OutDP_Brg, only: dp_create_dp_ar, dp_get_real2D, dp_register_var, &
                              STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, &
                              StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                              DATA_TYPE_STRUCT, IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR, dp_get_struct_ptr
  use MD_TypeSystem, only: State_Node => UF_NodeState

  implicit none
  private

  ! ===================================================================
  ! Output Constants (ABAQUS compatible, from MD_Out_Type)
  ! ===================================================================
  integer(i4), parameter, public :: OUT_LOC_NODE = 1_i4
  integer(i4), parameter, public :: OUT_LOC_ELEM_IN = 2_i4
  integer(i4), parameter, public :: OUT_LOC_ELEM_CENTROID = 3_i4
  integer(i4), parameter, public :: OUT_LOC_ELEM_SURFACE = 4_i4
  integer(i4), parameter, public :: OUT_LOC_GLOBAL = 5_i4
  integer(i4), parameter, public :: OUT_FREQ_INCREMENT = 1_i4
  integer(i4), parameter, public :: OUT_FREQ_TIME_INTERVAL = 2_i4
  integer(i4), parameter, public :: OUT_FREQ_TIME_MARKS = 3_i4
  integer(i4), parameter, public :: OUT_REGION_ALL = 0_i4
  integer(i4), parameter, public :: OUT_REGION_NSET = 1_i4
  integer(i4), parameter, public :: OUT_REGION_ELSET = 2_i4
  integer(i4), parameter, public :: OUT_REGION_SURF = 3_i4
  integer(i4), parameter, public :: OUT_VAR_U = 1_i4
  integer(i4), parameter, public :: OUT_VAR_V = 2_i4
  integer(i4), parameter, public :: OUT_VAR_A = 3_i4
  integer(i4), parameter, public :: OUT_VAR_RF = 4_i4
  integer(i4), parameter, public :: OUT_VAR_CF = 5_i4
  integer(i4), parameter, public :: OUT_VAR_TEMP = 6_i4
  integer(i4), parameter, public :: OUT_VAR_S = 11_i4
  integer(i4), parameter, public :: OUT_VAR_E = 12_i4
  integer(i4), parameter, public :: OUT_VAR_PE = 13_i4
  integer(i4), parameter, public :: OUT_VAR_EE = 14_i4
  integer(i4), parameter, public :: OUT_VAR_PEEQ = 15_i4
  integer(i4), parameter, public :: OUT_VAR_MISES = 16_i4
  integer(i4), parameter, public :: OUT_VAR_POR = 17_i4
  integer(i4), parameter, public :: OUT_VAR_HFL = 18_i4
  integer(i4), parameter, public :: OUT_VAR_VFL = 19_i4
  integer(i4), parameter, public :: OUT_VAR_CONC = 20_i4
  integer(i4), parameter, public :: OUT_VAR_ALLIE = 21_i4
  integer(i4), parameter, public :: OUT_VAR_ALLKE = 22_i4
  integer(i4), parameter, public :: OUT_VAR_ALLPD = 23_i4
  integer(i4), parameter, public :: OUT_VAR_ALLSE = 24_i4
  integer(i4), parameter, public :: OUT_FMT_VTK = 1_i4
  integer(i4), parameter, public :: OUT_FMT_HDF5 = 2_i4
  integer(i4), parameter, public :: OUT_FMT_CSV = 3_i4
  integer(i4), parameter, public :: OUT_FMT_ODB = 4_i4
  integer(i4), parameter, public :: OUT_FMT_TXT = 5_i4
  integer(i4), parameter, public :: OUT_RANK_SCALAR = 0_i4
  integer(i4), parameter, public :: OUT_RANK_VECTOR = 1_i4
  integer(i4), parameter, public :: OUT_RANK_TENSOR = 2_i4

  public :: OutDesc, OutSta, OutCtx, FldOutDesc, HistOutDesc
  public :: OutVarDesc, FldOutReq, HistOutReq, OutFrame, OutField
  public :: OUT_LOC_NODE, OUT_LOC_ELEM_IN, OUT_LOC_ELEM_CENTROID, OUT_LOC_ELEM_SURFACE, OUT_LOC_GLOBAL
  public :: OUT_FREQ_INCREMENT, OUT_FREQ_TIME_INTERVAL, OUT_FREQ_TIME_MARKS
  public :: OUT_REGION_ALL, OUT_REGION_NSET, OUT_REGION_ELSET, OUT_REGION_SURF
  public :: OUT_VAR_U, OUT_VAR_V, OUT_VAR_A, OUT_VAR_RF, OUT_VAR_CF, OUT_VAR_TEMP
  public :: OUT_VAR_S, OUT_VAR_E, OUT_VAR_PE, OUT_VAR_EE, OUT_VAR_PEEQ, OUT_VAR_MISES
  public :: OUT_VAR_POR, OUT_VAR_HFL, OUT_VAR_VFL, OUT_VAR_CONC
  public :: OUT_VAR_ALLIE, OUT_VAR_ALLKE, OUT_VAR_ALLPD, OUT_VAR_ALLSE
  public :: OUT_FMT_VTK, OUT_FMT_HDF5, OUT_FMT_CSV, OUT_FMT_ODB, OUT_FMT_TXT
  public :: OUT_RANK_SCALAR, OUT_RANK_VECTOR, OUT_RANK_TENSOR
  public :: MD_Out_Desc, MD_Out_State, MD_Out_Ctx, MD_Out_Arg

  type, public, extends(DescBase) :: OutDesc
    integer(i4) :: outputId = 0_i4
    character(len=64) :: name = ""
    character(len=32) :: outputType = ""
  contains
    procedure, public :: RegLayout => OutDesc_RegLayout
    procedure, public :: Ensure => OutDesc_Ensure
    procedure, public :: Init => OutDesc_Init
    procedure, public :: Valid => OutDesc_Valid
  end type OutDesc

  type, public, extends(StateBase) :: OutSta
    integer(i4) :: outputId = 0_i4
    logical :: isActive = .false.
  contains
    procedure, public :: RegLayout => OutSta_RegLayout
    procedure, public :: Ensure => OutSta_Ensure
    procedure, public :: Init => OutSta_Init
  end type OutSta

  type, public, extends(CtxBase) :: OutCtx
    integer(i4) :: outputId = 0_i4
  contains
    procedure, public :: RegLayout => OutCtx_RegLayout
    procedure, public :: Ensure => OutCtx_Ensure
    procedure, public :: Init => OutCtx_Init
  end type OutCtx

  type, public, extends(DescBase) :: FldOutDesc
    integer(i4) :: outputId = 0_i4
    character(len=64) :: name = ""
    integer(i4) :: frequency = 1_i4
    character(len=32) :: frequencyType = ""
  contains
    procedure, public :: RegLayout => FieldOutDesc_RegLayout
    procedure, public :: Ensure => FieldOutDesc_Ensure
    procedure, public :: Init => FieldOutDesc_Init
    procedure, public :: Valid => FldOutDesc_Valid
  end type FldOutDesc

  type, public, extends(DescBase) :: HistOutDesc
    integer(i4) :: outputId = 0_i4
    character(len=64) :: name = ""
    integer(i4) :: frequency = 1_i4
    character(len=32) :: frequencyType = ""
  contains
    procedure, public :: RegLayout => HistoryOutDesc_RegLayout
    procedure, public :: Ensure => HistoryOutDesc_Ensure
    procedure, public :: Init => HistoryOutDesc_Init
    procedure, public :: Valid => HistOutDesc_Valid
  end type HistOutDesc

  type, public :: OutVarDesc
    integer(i4) :: var_id = 0_i4
    character(len=16) :: var_name = ''
    character(len=64) :: var_description = ''
    integer(i4) :: location = OUT_LOC_NODE
    integer(i4) :: rank = OUT_RANK_SCALAR
    integer(i4) :: n_components = 1_i4
    logical :: is_tensor = .false.
    logical :: is_vector = .false.
    logical :: is_scalar = .true.
    logical :: support_field = .true.
    logical :: support_history = .true.
  end type OutVarDesc

  type, public :: FldOutReq
    character(len=64) :: name = ''
    character(len=64) :: region_name = ''
    integer(i4) :: region_type = OUT_REGION_ALL
    integer(i4) :: position = OUT_LOC_NODE
    integer(i4) :: frequency = 1_i4
    integer(i4) :: frequency_type = OUT_FREQ_INCREMENT
    real(wp) :: time_interval = 0.0_wp
    integer(i4) :: num_time_marks = 0_i4
    real(wp), allocatable :: time_marks(:)
    integer(i4) :: nVars = 0_i4
    integer(i4), pointer :: variables(:) => null()
    integer(i4) :: variables_id = -1_i4
    logical :: is_active = .true.
    integer(i4) :: step_id = 0_i4
  contains
    procedure, public :: Init => FldOutReq_Init
    procedure, public :: AddVariable => FldOutReq_AddVariable
    procedure, public :: ShouldOutput => FldOutReq_ShouldOutput
    procedure, public :: Clear => FldOutReq_Clear
  end type FldOutReq

  type, public :: HistOutReq
    character(len=64) :: name = ''
    character(len=64) :: region_name = ''
    integer(i4) :: region_type = OUT_REGION_ALL
    integer(i4) :: frequency = 1_i4
    integer(i4) :: frequency_type = OUT_FREQ_INCREMENT
    real(wp) :: time_interval = 0.0_wp
    integer(i4) :: num_time_marks = 0_i4
    real(wp), allocatable :: time_marks(:)
    integer(i4) :: nVars = 0_i4
    integer(i4), pointer :: variables(:) => null()
    integer(i4) :: variables_id = -1_i4
    logical :: is_active = .true.
    integer(i4) :: step_id = 0_i4
  contains
    procedure, public :: Init => HistOutReq_Init
    procedure, public :: AddVariable => HistOutReq_AddVariable
    procedure, public :: ShouldOutput => HistOutReq_ShouldOutput
    procedure, public :: Clear => HistOutReq_Clear
  end type HistOutReq

  type, public :: OutField
    character(len=32) :: var_name = ''
    integer(i4) :: var_id = 0_i4
    integer(i4) :: location = OUT_LOC_NODE
    integer(i4) :: n_components = 0_i4
    integer(i4) :: n_points = 0_i4
    integer(i4), allocatable :: point_ids(:)
    integer(i4), allocatable :: sub_point_ids(:)
    real(wp), allocatable :: data(:,:)
  end type OutField

  type, public :: OutFrame
    integer(i4) :: step_id = 0_i4
    integer(i4) :: increment_id = 0_i4
    real(wp) :: time = 0.0_wp
    integer(i4) :: num_fields = 0_i4
    type(OutField), allocatable :: fields(:)
  end type OutFrame

  public :: RT_REGION_NODES
  public :: RT_REGION_ELEMS
  public :: RT_REGION_SURFACE
  public :: RT_HVAR_U
  public :: RT_HVAR_RF
  public :: RT_HVAR_ALLIE
  public :: RT_HistVarDesc
  public :: RT_HistReq
  public :: RT_StepHistCfg
  public :: g_stepHistCfgs
  public :: RT_Out_BindInput
  public :: RT_Out_UpdInput
  public :: RT_Out_RecordHist
  public :: RT_Out_RecordField
  public :: RT_Out_RecordAll
  public :: RT_Out_RecordNodeSetHist
  ! RT_Out_AppendMonitorsCSV, RT_Out_WriteVTK_Cell, RT_Out_WriteVTK_Both, RT_Out_UpdPvd
  ! L5 field/history file writers: use RT_Out frame path when integrated
  public :: RT_Out_PEEQ_DP
  public :: RT_EnsureModelStateHistory
  public :: RT_UpdateModelStateHistory
  public :: RT_EnsureNodeSetHistoryU
  public :: RT_UpdateNodeSetHistoryU
  public :: RT_EnsureNodeSetHistoryMeta
  public :: RT_UpdateNodeSetHistoryMeta
  public :: RT_BuildNodeSetHistoryRegionCatalog
  public :: RT_BuildHistoryNodeSetRegionLinks
  public :: RT_DumpStepHistoryConfig
  public :: RT_EnsureElsetHistoryScalar
  public :: RT_UpdateElsetHistoryScalar
  public :: RT_BuildElsetHistoryRegionCatalog
  public :: RT_BuildElsetHistoryRegionLinks
  public :: HistRegionCatalogEntry
  public :: HistNodeSetRegionLink
  public :: StepHistConfigEntry
  public :: ElsetHistScalarEntry
  public :: NodeSetHistMetaRecord
  public :: RT_Out_RecordScalarVariable
  public :: RT_Out_RecordVectorVariable
  public :: RT_Out_RecordFieldFrame
  public :: RT_Out_RecordHistoryFrame
  public :: RT_Out_ShouldOutputField
  public :: RT_Out_ShouldOutputHistory

  integer(i4), parameter, public :: RT_REGION_NODES = 1_i4
  integer(i4), parameter, public :: RT_REGION_ELEMS = 2_i4
  integer(i4), parameter, public :: RT_REGION_SURFACE = 3_i4

  integer(i4), parameter, public :: RT_HVAR_U = 1_i4
  integer(i4), parameter, public :: RT_HVAR_RF = 2_i4
  integer(i4), parameter, public :: RT_HVAR_ALLIE = 3_i4

  type, public :: RT_HistVarDesc
    integer(i4) :: kind = 0_i4
    character(len=32) :: name = ''
    integer(i4) :: location = 0_i4
    logical :: is_vector = .false.
  end type RT_HistVarDesc

  type, public :: RT_HistReq
    logical :: active = .false.
    integer(i4) :: region_type = 0_i4
    character(len=64) :: region_name = ''
    integer(i4) :: num_vars = 0_i4
    type(RT_HistVarDesc), allocatable :: vars(:)
  end type RT_HistReq

  type, public :: RT_StepHistCfg
    integer(i4) :: step_id = 0_i4
    integer(i4) :: num_history = 0_i4
    type(RT_HistReq), allocatable :: histories(:)
  end type RT_StepHistCfg

  type(RT_StepHistCfg), allocatable, save, public :: g_stepHistCfgs(:)
  
  ! Field and History output requests (per step)
  type(FldOutReq), allocatable, save, public :: g_fieldOutputs(:)
  type(HistOutReq), allocatable, save, public :: g_historyOutput(:)

  integer(i4), parameter, public :: NODESET_HISTORY = 64_i4

  type, public :: NodeSetHistMetaRecord
    integer(i4) :: nodeSetId
    character(len=NODESET_HISTORY) :: region_name
  end type NodeSetHistMetaRecord

  type, public :: HistRegionCatalogEntry
    integer(i4) :: nodeSetId
    character(len=NODESET_HISTORY) :: region_name
    character(len=32) :: category
    character(len=32) :: region_kind
    character(len=64) :: source_var
  end type HistRegionCatalogEntry

  type, public :: HistNodeSetRegionLink
    integer(i4) :: id
    integer(i4) :: histIndex
    integer(i4) :: catalogIndex
  end type HistNodeSetRegionLink

  type, public :: StepHistConfigEntry
    integer(i4) :: id
    integer(i4) :: histIndex
    integer(i4) :: varIndex
    integer(i4) :: region_type
    integer(i4) :: location
    integer(i4) :: is_vector
    character(len=NODESET_HISTORY) :: region_name
    character(len=32) :: name
  end type StepHistConfigEntry

  type, public :: ElsetHistScalarEntry
    integer(i4) :: id
    integer(i4) :: histIndex
    integer(i4) :: varIndex
    real(wp) :: value
  end type ElsetHistScalarEntry

contains

  subroutine RT_Out_BindInput(modelDef)
    type(*), intent(inout) :: modelDef

    if (.not. allocated(g_stepHistCfgs)) then
      allocate(g_stepHistCfgs(0))
    end if
  end subroutine RT_Out_BindInput

  subroutine RT_Out_UpdInput(modelDef)
    type(*), intent(inout) :: modelDef

    integer(i4) :: i, nSteps

    if (.not. allocated(g_stepHistCfgs)) then
      allocate(g_stepHistCfgs(0))
    end if

    nSteps = size(g_stepHistCfgs)
    do i = 1, nSteps
      if (allocated(g_stepHistCfgs(i)%histories)) then
        if (.not. allocated(g_stepHistCfgs(i)%histories(1)%vars)) then
          allocate(g_stepHistCfgs(i)%histories(1)%vars(0))
        end if
      end if
    end do
  end subroutine RT_Out_UpdInput

  subroutine RT_Out_RecordHist(id, incId, time)
    integer(i4), intent(in) :: id
    integer(i4), intent(in) :: incId
    real(wp), intent(in) :: time

    integer(i4) :: i, nHist, j, nVars

    if (.not. allocated(g_stepHistCfgs)) return
    if (id < 1 .or. id > size(g_stepHistCfgs)) return

    nHist = 0_i4
    if (allocated(g_stepHistCfgs(id)%histories)) then
      nHist = size(g_stepHistCfgs(id)%histories)
    end if

    do i = 1, nHist
      if (g_stepHistCfgs(id)%histories(i)%active) then
        nVars = g_stepHistCfgs(id)%histories(i)%num_vars
        if (allocated(g_stepHistCfgs(id)%histories(i)%vars)) then
          do j = 1, nVars
            if (g_stepHistCfgs(id)%histories(i)%vars(j)%is_vector) then
              call RT_Out_RecordVectorVariable(id, i, j, incId, time)
            else
              call RT_Out_RecordScalarVariable(id, i, j, incId, time)
            end if
          end do
        end if
      end if
    end do
  end subroutine RT_Out_RecordHist

  subroutine RT_Out_RecordField(id, incId, time)
    integer(i4), intent(in) :: id
    integer(i4), intent(in) :: incId
    real(wp), intent(in) :: time

    integer(i4) :: i, nFields

    if (.not. allocated(g_stepHistCfgs)) return
    if (id < 1 .or. id > size(g_stepHistCfgs)) return

    nFields = 0_i4
    do i = 1, size(g_stepHistCfgs(id)%histories)
      if (g_stepHistCfgs(id)%histories(i)%active) then
        nFields = nFields + 1_i4
      end if
    end do
  end subroutine RT_Out_RecordField

  subroutine RT_Out_RecordAll(id)
    integer(i4), intent(in) :: id

    integer(i4) :: i, nHist, j, nVars

    if (.not. allocated(g_stepHistCfgs)) return
    if (id < 1 .or. id > size(g_stepHistCfgs)) return

    nHist = 0_i4
    if (allocated(g_stepHistCfgs(id)%histories)) then
      nHist = size(g_stepHistCfgs(id)%histories)
    end if

    do i = 1, nHist
      if (g_stepHistCfgs(id)%histories(i)%active) then
        nVars = g_stepHistCfgs(id)%histories(i)%num_vars
        if (allocated(g_stepHistCfgs(id)%histories(i)%vars)) then
          do j = 1, nVars
            if (g_stepHistCfgs(id)%histories(i)%vars(j)%is_vector) then
              call RT_Out_RecordVectorVariable(id, i, j, 0_i4, 0.0_wp)
            else
              call RT_Out_RecordScalarVariable(id, i, j, 0_i4, 0.0_wp)
            end if
          end do
        end if
      end if
    end do
  end subroutine RT_Out_RecordAll

  subroutine RT_Out_RecordNodeSetHist(id, incId, time)
    integer(i4), intent(in) :: id
    integer(i4), intent(in) :: incId
    real(wp), intent(in) :: time

    integer(i4) :: i, nHist, j, nVars

    if (.not. allocated(g_stepHistCfgs)) return
    if (id < 1 .or. id > size(g_stepHistCfgs)) return

    nHist = 0_i4
    if (allocated(g_stepHistCfgs(id)%histories)) then
      nHist = size(g_stepHistCfgs(id)%histories)
    end if

    do i = 1, nHist
      if (g_stepHistCfgs(id)%histories(i)%active .and. &
          g_stepHistCfgs(id)%histories(i)%region_type == RT_REGION_NODES) then
        nVars = g_stepHistCfgs(id)%histories(i)%num_vars
        if (allocated(g_stepHistCfgs(id)%histories(i)%vars)) then
          do j = 1, nVars
            if (g_stepHistCfgs(id)%histories(i)%vars(j)%is_vector) then
              call RT_Out_RecordVectorVariable(id, i, j, incId, time)
            else
              call RT_Out_RecordScalarVariable(id, i, j, incId, time)
            end if
          end do
        end if
      end if
    end do
  end subroutine RT_Out_RecordNodeSetHist

  subroutine RT_Out_PEEQ_DP(id)
    integer(i4), intent(in) :: id

    integer(i4) :: dims(4)
    type(ErrorStatusType) :: dp_status

    call init_error_status(dp_status)

    dims = [1_i4, 1_i4, 0_i4, 0_i4]
    call dp_create_dp_ar('PEEQ_OUTPUT', dims, dp_status)
    if (dp_status%status_code == IF_STATUS_OK) then
      call dp_register_var('OUTPUT', 'PEEQ', 'PEEQ_OUTPUT', &
                                STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, dp_status)
    end if
  end subroutine RT_Out_PEEQ_DP

  subroutine RT_EnsureModelStateHistory(nSteps, status)
    integer(i4), intent(in) :: nSteps
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: dims(4)

    call init_error_status(status)

    if (nSteps <= 0_i4) then
      status%status_code = IF_STATUS_OK
      return
    end if

    dims = [8_i4, nSteps, 0_i4, 0_i4]
    call dp_create_dp_ar('MODEL_STATE_HISTORY', dims, status)
    if (status%status_code == IF_STATUS_OK) then
      call dp_register_var('HISTORY', 'MODEL', 'MODEL_STATE_HISTORY', &
                                STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, status)
    end if
  end subroutine RT_EnsureModelStateHistory

  subroutine RT_UpdateModelStateHistory(id, values)
    integer(i4), intent(in) :: id
    real(wp), intent(in) :: values(8)

    real(wp), pointer :: dp_hist(:,:)
    type(ErrorStatusType) :: dp_status

    call init_error_status(dp_status)

    dp_hist => dp_get_real2D('MODEL_STATE_HISTORY', dp_status)
    if (dp_status%status_code == IF_STATUS_OK .and. associated(dp_hist)) then
      if (id >= 1 .and. id <= size(dp_hist, 2)) then
        dp_hist(:, id) = values
      end if
    end if
  end subroutine RT_UpdateModelStateHistory

  subroutine RT_EnsureNodeSetHistoryU(nSteps, nodeSetIds, status)
    integer(i4), intent(in) :: nSteps
    integer(i4), intent(in) :: nodeSetIds(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, dims(4)
    character(len=128) :: varName

    call init_error_status(status)

    do i = 1, size(nodeSetIds)
      write(varName,'(A,I0)') 'NODESET_HISTORY_U_', nodeSetIds(i)
      dims = [3_i4, nSteps, 0_i4, 0_i4]
      call dp_create_dp_ar(trim(varName), dims, status)
      if (status%status_code /= IF_STATUS_OK) return
    end do
  end subroutine RT_EnsureNodeSetHistoryU

  subroutine RT_UpdateNodeSetHistoryU(id, nodeSetId, uAvg, uMax, uMin)
    integer(i4), intent(in) :: id
    integer(i4), intent(in) :: nodeSetId
    real(wp), intent(in) :: uAvg, uMax, uMin

    real(wp), pointer :: dp_hist(:,:)
    type(ErrorStatusType) :: dp_status
    character(len=128) :: varName

    call init_error_status(dp_status)

    write(varName,'(A,I0)') 'NODESET_HISTORY_U_', nodeSetId
    dp_hist => dp_get_real2D(trim(varName), dp_status)
    if (dp_status%status_code == IF_STATUS_OK .and. associated(dp_hist)) then
      if (id >= 1 .and. id <= size(dp_hist, 2)) then
        dp_hist(1, id) = uAvg
        dp_hist(2, id) = uMax
        dp_hist(3, id) = uMin
      end if
    end if
  end subroutine RT_UpdateNodeSetHistoryU

  subroutine RT_EnsureNodeSetHistoryMeta(nSteps, nodeSetIds, status)
    integer(i4), intent(in) :: nSteps
    integer(i4), intent(in) :: nodeSetIds(:)
    type(ErrorStatusType), intent(out) :: status

    type(StructFieldDesc) :: fields(2)
    integer(i4) :: dims(4)

    call init_error_status(status)

    fields(1)%name = 'nodeSetId'
    fields(1)%type = IF_DATA_TYPE_INT
    fields(1)%offset = 0_i4

    fields(2)%name = 'region_name'
    fields(2)%type = IF_DATA_TYPE_CHAR
    fields(2)%offset = 4_i4
    fields(2)%length = NODESET_HISTORY

    call dp_register_struct_type('NodeSetHistMetaRecord', fields, status)
    if (status%status_code /= IF_STATUS_OK) return

    dims = [size(nodeSetIds), 1_i4, 0_i4, 0_i4]
    call dp_create_struct_array('NODESET_HISTORY_META', 'NodeSetHistMetaRecord', dims, status)
  end subroutine RT_EnsureNodeSetHistoryMeta

  subroutine RT_UpdateNodeSetHistoryMeta(nodeSetId, regionName)
    integer(i4), intent(in) :: nodeSetId
    character(len=*), intent(in) :: regionName

    class(*), pointer :: any_ptr
    type(NodeSetHistMetaRecord), pointer :: meta(:)
    type(ErrorStatusType) :: dp_status
    integer(i4) :: i, n

    call init_error_status(dp_status)

    !  DataPlatform  node 
    call dp_get_struct_ptr('NODESET_HISTORY_META', any_ptr, dp_status)
    if (dp_status%status_code /= IF_STATUS_OK) return

    select type(p => any_ptr)
    type is (NodeSetHistMetaRecord)
      meta => p
    class default
      return
    end select

    if (.not. associated(meta)) return

    n = size(meta)
    do i = 1, n
      if (meta(i)%nodeSetId == nodeSetId) then
        meta(i)%region_name = trim(regionName)
        return
      end if
    end do
  end subroutine RT_UpdateNodeSetHistoryMeta

  subroutine RT_BuildNodeSetHistoryRegion(catalog, nEntries)
    type(HistRegionCatalogEntry), allocatable, intent(out) :: catalog(:)
    integer(i4), intent(in) :: nEntries

    if (allocated(catalog)) deallocate(catalog)
    allocate(catalog(nEntries))
  end subroutine RT_BuildNodeSetHistoryRegionCatalog

  subroutine RT_BuildHistoryNodeSetRegion(links, nLinks)
    type(HistNodeSetRegionLink), allocatable, intent(out) :: links(:)
    integer(i4), intent(in) :: nLinks

    if (allocated(links)) deallocate(links)
    allocate(links(nLinks))
  end subroutine RT_BuildHistoryNodeSetRegionLinks

  subroutine RT_DumpStepHistoryConfig(configs, nSteps)
    type(StepHistConfigEntry), intent(in) :: configs(:)
    integer(i4), intent(in) :: nSteps

    integer(i4) :: i, unitNo, ios

    open(newunit=unitNo, file='step_history_config.txt', status='replace', action='write', iostat=ios)
    if (ios /= 0_i4) return

    write(unitNo,'(A)') 'Step History Configuration'
    write(unitNo,'(A)') '==========================='
    write(unitNo,'(A,I0)') 'Number of steps: ', nSteps
    write(unitNo,'(A,I0)') 'Number of configs: ', size(configs)
    write(unitNo,'(A)') ''

    do i = 1, size(configs)
      write(unitNo,'(A,I0)') 'Config ', i
      write(unitNo,'(A,I0)') '  Step ID: ', configs(i)%cfg%id
      write(unitNo,'(A,I0)') '  History Index: ', configs(i)%histIndex
      write(unitNo,'(A,I0)') '  Variable Index: ', configs(i)%varIndex
      write(unitNo,'(A,I0)') '  Region Type: ', configs(i)%region_type
      write(unitNo,'(A,I0)') '  Location: ', configs(i)%location
      write(unitNo,'(A,L1)') '  Is Vector: ', configs(i)%is_vector
      write(unitNo,'(A,A)') '  Region Name: ', trim(configs(i)%region_name)
      write(unitNo,'(A,A)') '  Variable Name: ', trim(configs(i)%name)
      write(unitNo,'(A)') ''
    end do

    close(unitNo)
  end subroutine RT_DumpStepHistoryConfig

  subroutine RT_EnsureElsetHistoryScalar(nEntries, status)
    integer(i4), intent(in) :: nEntries
    type(ErrorStatusType), intent(out) :: status

    type(StructFieldDesc) :: fields(4)
    integer(i4) :: dims(4)

    call init_error_status(status)

    fields(1)%name = 'id'
    fields(1)%type = IF_DATA_TYPE_INT
    fields(1)%offset = 0_i4

    fields(2)%name = 'histIndex'
    fields(2)%type = IF_DATA_TYPE_INT
    fields(2)%offset = 4_i4

    fields(3)%name = 'varIndex'
    fields(3)%type = IF_DATA_TYPE_INT
    fields(3)%offset = 8_i4

    fields(4)%name = 'value'
    fields(4)%type = IF_DATA_TYPE_DP
    fields(4)%offset = 12_i4

    call dp_register_struct_type('ElsetHistScalarEntry', fields, status)
    if (status%status_code /= IF_STATUS_OK) return

    dims = [nEntries, 1_i4, 0_i4, 0_i4]
    call dp_create_struct_array('ELSET_HISTORY_SCALAR', 'ElsetHistScalarEntry', dims, status)
  end subroutine RT_EnsureElsetHistoryScalar

  subroutine RT_UpdateElsetHistoryScalar(id, histIndex, varIndex, value)
    integer(i4), intent(in) :: id
    integer(i4), intent(in) :: histIndex
    integer(i4), intent(in) :: varIndex
    real(wp), intent(in) :: value

    class(*), pointer :: any_ptr
    type(ElsetHistScalarEntry), pointer :: entries(:)
    type(ErrorStatusType) :: dp_status
    integer(i4) :: i, n

    call init_error_status(dp_status)

    !  DataPlatform  element 
    call dp_get_struct_ptr('ELSET_HISTORY_SCALAR', any_ptr, dp_status)
    if (dp_status%status_code /= IF_STATUS_OK) return

    select type(p => any_ptr)
    type is (ElsetHistScalarEntry)
      entries => p
    class default
      return
    end select

    if (.not. associated(entries)) return

    n = size(entries)
    do i = 1, n
      if (entries(i)%cfg%id == id .and. &
          entries(i)%histIndex == histIndex .and. &
          entries(i)%varIndex == varIndex) then
        entries(i)%value = value
        return
      end if
    end do
  end subroutine RT_UpdateElsetHistoryScalar

  subroutine RT_BuildElsetHistoryRegionCa(catalog, nEntries)
    type(HistRegionCatalogEntry), allocatable, intent(out) :: catalog(:)
    integer(i4), intent(in) :: nEntries

    if (allocated(catalog)) deallocate(catalog)
    allocate(catalog(nEntries))
  end subroutine RT_BuildElsetHistoryRegionCatalog

  subroutine RT_BuildElsetHistoryRegionLi(links, nLinks)
    type(HistNodeSetRegionLink), allocatable, intent(out) :: links(:)
    integer(i4), intent(in) :: nLinks

    if (allocated(links)) deallocate(links)
    allocate(links(nLinks))
  end subroutine RT_BuildElsetHistoryRegionLinks
  
  ! ===================================================================
  ! Record Scalar Variable (History Output)
  ! ===================================================================
  
  subroutine RT_Out_RecordScalarVariable(step_id, hist_id, var_id, inc_id, time)
    integer(i4), intent(in) :: step_id, hist_id, var_id, inc_id
    real(wp), intent(in) :: time
    
    integer(i4) :: dims(4)
    type(ErrorStatusType) :: dp_status
    character(len=128) :: var_name
    real(wp), pointer :: dp_data(:,:)
    
    call init_error_status(dp_status)
    
    !  See module header / UFC docs for context.
    write(var_name,'(A,I0,A,I0,A,I0)') 'HIST_SCALAR_S', step_id, '_H', hist_id, '_V', var_id
    
    ! get DataPlatform ?1 time ?2
    dp_data => dp_get_real2D(trim(var_name), dp_status)
    if (.not. associated(dp_data)) then
      dims = [2_i4, max(inc_id, 1000_i4), 0_i4, 0_i4]
      call dp_create_dp_ar(trim(var_name), dims, dp_status)
      if (dp_status%status_code == IF_STATUS_OK) then
        call dp_register_var('HISTORY', trim(var_name), trim(var_name), &
                                  STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, dp_status)
      end if
      !  See module header / UFC docs for context.
      dp_data => dp_get_real2D(trim(var_name), dp_status)
    end if
    
    !  time ?value
    if (associated(dp_data)) then
      if (inc_id >= 1_i4 .and. inc_id <= size(dp_data, 2)) then
        dp_data(1, inc_id) = time
      end if
    end if
  end subroutine RT_Out_RecordScalarVariable
  
  ! ===================================================================
  ! Record Vector Variable (History Output)
  ! ===================================================================
  
  subroutine RT_Out_RecordVectorVariable(step_id, hist_id, var_id, inc_id, time)
    integer(i4), intent(in) :: step_id, hist_id, var_id, inc_id
    real(wp), intent(in) :: time
    
    integer(i4) :: dims(4)
    type(ErrorStatusType) :: dp_status
    character(len=128) :: var_name
    real(wp), pointer :: dp_data(:,:)
    
    call init_error_status(dp_status)
    
    !  vector 
    write(var_name,'(A,I0,A,I0,A,I0)') 'HIST_VECTOR_S', step_id, '_H', hist_id, '_V', var_id
    
    ! get DataPlatform ?1 time ?2~4 3
    dp_data => dp_get_real2D(trim(var_name), dp_status)
    if (.not. associated(dp_data)) then
      dims = [4_i4, max(inc_id, 1000_i4), 0_i4, 0_i4]
      call dp_create_dp_ar(trim(var_name), dims, dp_status)
      if (dp_status%status_code == IF_STATUS_OK) then
        call dp_register_var('HISTORY', trim(var_name), trim(var_name), &
                                  STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_DP, dp_status)
      end if
      dp_data => dp_get_real2D(trim(var_name), dp_status)
    end if
    
    !  time ?value Runtime output
    if (associated(dp_data)) then
      if (inc_id >= 1_i4 .and. inc_id <= size(dp_data, 2)) then
        dp_data(1, inc_id) = time
      end if
    end if
  end subroutine RT_Out_RecordVectorVariable
  
  ! ===================================================================
  ! Record Field Output Frame
  ! ===================================================================
  
  subroutine RT_Out_RecordFieldFrame(step_id, increment_id, time, frame, status)
    integer(i4), intent(in) :: step_id, increment_id
    real(wp), intent(in) :: time
    type(OutFrame), intent(in) :: frame
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i_field
    
    call init_error_status(status)
    
    ! Record each field in the frame
    if (allocated(frame%fields)) then
      do i_field = 1, frame%num_fields
        !! Step 1: get ? ? ? ?
        !! Step 2:  frame%fields(i_field) DataPlatform 
        !! Step 3:  DataPlatform 
        !! Step 4:  outputtime 
        !  ?Runtime OutputWriter
        !  output ??TK/HDF5/ODB ?Writer
        continue  !  Runtime 
      end do
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine RT_Out_RecordFieldFrame
  
  ! ===================================================================
  ! Record History Output Frame
  ! ===================================================================
  
  subroutine RT_Out_RecordHistoryFrame(step_id, increment_id, time, var_id, values, status)
    integer(i4), intent(in) :: step_id, increment_id
    real(wp), intent(in) :: time
    integer(i4), intent(in) :: var_id
    real(wp), intent(in) :: values(:)
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n_comp
    
    call init_error_status(status)
    
    n_comp = size(values)
    if (n_comp == 1_i4) then
      call RT_Out_RecordScalarVariable(step_id, 0_i4, var_id, increment_id, time)
    else
      call RT_Out_RecordVectorVariable(step_id, 0_i4, var_id, increment_id, time)
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine RT_Out_RecordHistoryFrame
  
  ! ===================================================================
  ! Check if Field Output Should be Written
  ! ===================================================================
  
  function RT_Out_ShouldOutputField(field_req, increment_id, time, last_output_tim) result(should_output)
    type(FldOutReq), intent(in) :: field_req
    integer(i4), intent(in) :: increment_id
    real(wp), intent(in) :: time
    real(wp), intent(in), optional :: last_output_tim
    logical :: should_output
    
    should_output = field_req%ShouldOutput(increment_id, time, last_output_tim)
  end function RT_Out_ShouldOutputField
  
  ! ===================================================================
  ! Check if History Output Should be Written
  ! ===================================================================
  
  function RT_Out_ShouldOutputHistory(hist_req, increment_id, time, last_output_tim) result(should_output)
    type(HistOutReq), intent(in) :: hist_req
    integer(i4), intent(in) :: increment_id
    real(wp), intent(in) :: time
    real(wp), intent(in), optional :: last_output_tim
    logical :: should_output
    
    should_output = hist_req%ShouldOutput(increment_id, time, last_output_tim)
  end function RT_Out_ShouldOutputHistory

  ! ===================================================================
  ! OutDesc / OutSta / OutCtx / FldOutDesc / HistOutDesc procedures (from MD_Out_Type)
  ! ===================================================================

  subroutine OutDesc_Init(this, outputId, name, outputType)
    class(OutDesc), intent(inout) :: this
    integer(i4), intent(in), optional :: outputId
    character(len=*), intent(in), optional :: name, outputType
    call this%CoreBase%Init(CAT_DESC, 'DESC::OUTPUT')
    if (present(outputId)) this%outputId = outputId
    if (present(name)) this%name = name
    if (present(outputType)) this%outputType = outputType
  end subroutine OutDesc_Init

  subroutine OutDesc_RegLayout(this)
    class(OutDesc), intent(in) :: this
    type(ErrorStatusType) :: status
    type(StructFieldDesc) :: fields(3)
    integer(i4) :: offset
    call init_error_status(status)
    offset = 0
    fields(1)%field_name = 'outputId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'outputType'
    fields(3)%data_type = IF_DATA_TYPE_CHAR
    fields(3)%elem_len = 32
    fields(3)%offset_bytes = offset
    offset = offset + 32
    call dp_register_struct_type(trim(this%typeName), fields, 3, status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "OutDesc_RegLayout")
  end subroutine OutDesc_RegLayout

  subroutine OutDesc_Ensure(this)
    class(OutDesc), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    if (len_trim(this%varName) == 0) write(this%varName, '(A,I0)') 'UF_OUTPUTDESC_', this%outputId
    call dp_create_struct_array(trim(this%varName), [1,0,0,0], trim(this%typeName), status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "OutDesc_Ensure")
  end subroutine OutDesc_Ensure

  subroutine OutDesc_Valid(this, status)
    !!  output 
    !! UFC ?md ?.1 ?
    !! 1. output 
    !! 2. output ??IELD HISTORY ?
    class(OutDesc), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    !  
    if (len_trim(this%name) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Output name must be non-empty"
      return
    end if
    
    !  output 
    if (len_trim(this%outputType) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Output type must be specified (FIELD or HISTORY)"
      return
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine OutDesc_Valid

  subroutine OutSta_Init(this, outputId)
    class(OutSta), intent(inout) :: this
    integer(i4), intent(in), optional :: outputId
    this%category = CAT_STATE
    if (present(outputId)) this%outputId = outputId
  end subroutine OutSta_Init

  subroutine OutSta_RegLayout(this)
    class(OutSta), intent(in) :: this
    type(ErrorStatusType) :: status
    type(StructFieldDesc) :: fields(2)
    integer(i4) :: offset
    call init_error_status(status)
    offset = 0
    fields(1)%field_name = 'outputId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'isActive'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    call dp_register_struct_type(trim(this%typeName), fields, 2, status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "OutSta_RegLayout")
  end subroutine OutSta_RegLayout

  subroutine OutSta_Ensure(this)
    class(OutSta), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    if (len_trim(this%varName) == 0) write(this%varName, '(A,I0)') 'UF_OUTPUTSTATE_', this%outputId
    call dp_create_struct_array(trim(this%varName), [1,0,0,0], trim(this%typeName), status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "OutSta_Ensure")
  end subroutine OutSta_Ensure

  subroutine OutCtx_Init(this, outputId)
    class(OutCtx), intent(inout) :: this
    integer(i4), intent(in), optional :: outputId
    call this%CoreBase%Init(CAT_CTX, 'CTX::OUTPUT')
    if (present(outputId)) this%outputId = outputId
  end subroutine OutCtx_Init

  subroutine OutCtx_RegLayout(this)
    class(OutCtx), intent(in) :: this
    type(ErrorStatusType) :: status
    type(StructFieldDesc) :: fields(1)
    integer(i4) :: offset
    call init_error_status(status)
    offset = 0
    fields(1)%field_name = 'outputId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    call dp_register_struct_type(trim(this%typeName), fields, 1, status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "OutCtx_RegLayout")
  end subroutine OutCtx_RegLayout

  subroutine OutCtx_Ensure(this)
    class(OutCtx), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    if (len_trim(this%varName) == 0) write(this%varName, '(A,I0)') 'UF_OUTPUTCTX_', this%outputId
    call dp_create_struct_array(trim(this%varName), [1,0,0,0], trim(this%typeName), status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "OutCtx_Ensure")
  end subroutine OutCtx_Ensure

  subroutine FieldOutDesc_Init(this, outputId, name, frequency, frequencyType)
    class(FldOutDesc), intent(inout) :: this
    integer(i4), intent(in), optional :: outputId, frequency
    character(len=*), intent(in), optional :: name, frequencyType
    call this%CoreBase%Init(CAT_DESC, 'DESC::FIELDOUTPUT')
    if (present(outputId)) this%outputId = outputId
    if (present(name)) this%name = name
    if (present(frequency)) this%frequency = frequency
    if (present(frequencyType)) this%frequencyType = frequencyType
  end subroutine FieldOutDesc_Init

  subroutine FieldOutDesc_RegLayout(this)
    class(FldOutDesc), intent(in) :: this
    type(ErrorStatusType) :: status
    type(StructFieldDesc) :: fields(4)
    integer(i4) :: offset
    call init_error_status(status)
    offset = 0
    fields(1)%field_name = 'outputId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'frequency'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'frequencyType'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 32
    fields(4)%offset_bytes = offset
    offset = offset + 32
    call dp_register_struct_type(trim(this%typeName), fields, 4, status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "FieldOutDesc_RegLayout")
  end subroutine FieldOutDesc_RegLayout

  subroutine FieldOutDesc_Ensure(this)
    class(FldOutDesc), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    if (len_trim(this%varName) == 0) write(this%varName, '(A,I0)') 'UF_FIELDOUTPUTDESC_', this%outputId
    call dp_create_struct_array(trim(this%varName), [1,0,0,0], trim(this%typeName), status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "FieldOutDesc_Ensure")
  end subroutine FieldOutDesc_Ensure

  subroutine FldOutDesc_Valid(this, status)
    !! output ?
    !! UFC ?md ?.1 ?
    !! 1. output 
    !! 2. output  >= 0
    class(FldOutDesc), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    !  
    if (len_trim(this%name) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Field output name must be non-empty"
      return
    end if
    
    !  output  >= 0
    if (this%frequency < 0) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A,I0)') "Field output frequency must be >= 0, got: ", this%frequency
      return
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine FldOutDesc_Valid

  subroutine HistoryOutDesc_Init(this, outputId, name, frequency, frequencyType)
    class(HistOutDesc), intent(inout) :: this
    integer(i4), intent(in), optional :: outputId, frequency
    character(len=*), intent(in), optional :: name, frequencyType
    call this%CoreBase%Init(CAT_DESC, 'DESC::HISTORYOUTPUT')
    if (present(outputId)) this%outputId = outputId
    if (present(name)) this%name = name
    if (present(frequency)) this%frequency = frequency
    if (present(frequencyType)) this%frequencyType = frequencyType
  end subroutine HistoryOutDesc_Init

  subroutine HistoryOutDesc_RegLayout(this)
    class(HistOutDesc), intent(in) :: this
    type(ErrorStatusType) :: status
    type(StructFieldDesc) :: fields(4)
    integer(i4) :: offset
    call init_error_status(status)
    offset = 0
    fields(1)%field_name = 'outputId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'frequency'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'frequencyType'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 32
    fields(4)%offset_bytes = offset
    offset = offset + 32
    call dp_register_struct_type(trim(this%typeName), fields, 4, status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "HistoryOutDesc_RegLayout")
  end subroutine HistoryOutDesc_RegLayout

  subroutine HistoryOutDesc_Ensure(this)
    class(HistOutDesc), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    if (len_trim(this%varName) == 0) write(this%varName, '(A,I0)') 'UF_HISTORYOUTPUTDESC_', this%outputId
    call dp_create_struct_array(trim(this%varName), [1,0,0,0], trim(this%typeName), status)
    if (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "HistoryOutDesc_Ensure")
  end subroutine HistoryOutDesc_Ensure

  subroutine HistOutDesc_Valid(this, status)
    !!  output 
    !! UFC ?md ?.1 ?
    !! 1. output 
    !! 2. output  >= 0
    class(HistOutDesc), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    !  
    if (len_trim(this%name) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "History output name must be non-empty"
      return
    end if
    
    !  output  >= 0
    if (this%frequency < 0) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A,I0)') "History output frequency must be >= 0, got: ", this%frequency
      return
    end if
    
    status%status_code = IF_STATUS_OK
  end subroutine HistOutDesc_Valid
  end subroutine HistoryOutDesc_Ensure

  subroutine FldOutReq_Init(this, name, region_name, region_type, position, frequency, frequency_type)
    class(FldOutReq), intent(inout) :: this
    character(len=*), intent(in), optional :: name, region_name
    integer(i4), intent(in), optional :: region_type, position, frequency, frequency_type
    call this%Clear()
    if (present(name)) this%name = name
    if (present(region_name)) this%region_name = region_name
    if (present(region_type)) this%region_type = region_type
    if (present(position)) this%position = position
    if (present(frequency)) this%frequency = frequency
    if (present(frequency_type)) this%frequency_type = frequency_type
    this%is_active = .true.
  end subroutine FldOutReq_Init

  subroutine FldOutReq_AddVariable(this, var_id)
    class(FldOutReq), intent(inout) :: this
    integer(i4), intent(in) :: var_id
    integer(i4), pointer :: new_vars(:) => null()
    integer(i4) :: new_id, n, cap
    type(ErrorStatusType) :: alloc_status
    if (.not. associated(this%variables)) then
      call init_error_status(alloc_status)
      call UF_Mem_AllocInt1D(IF_MEM_DOMAIN_CMD, 0, 10_i4, 'FldOutReq_variables', this%variables, this%variables_id, alloc_status)
      if (alloc_status%status_code == IF_STATUS_OK) this%variables = 0_i4
      if (alloc_status%status_code /= IF_STATUS_OK) return
    end if
    n = this%nVars
    if (n >= size(this%variables)) then
      cap = size(this%variables) + 10_i4
      call init_error_status(alloc_status)
      call UF_Mem_AllocInt1D(IF_MEM_DOMAIN_CMD, 0, cap, 'FldOutReq_variables_new', new_vars, new_id, alloc_status)
      if (alloc_status%status_code /= IF_STATUS_OK) return
      new_vars(1:n) = this%variables(1:n)
      new_vars(n+1:cap) = 0_i4
      call UF_Mem_FreeInt1D(this%variables_id, alloc_status)
      this%variables => new_vars
      this%variables_id = new_id
    end if
    n = n + 1_i4
    this%variables(n) = var_id
    this%nVars = n
  end subroutine FldOutReq_AddVariable

  function FldOutReq_ShouldOutput(this, increment_id, time, last_output_tim) result(should_output)
    class(FldOutReq), intent(in) :: this
    integer(i4), intent(in) :: increment_id
    real(wp), intent(in) :: time
    real(wp), intent(in), optional :: last_output_tim
    logical :: should_output
    real(wp) :: last_time
    integer(i4) :: i
    should_output = .false.
    if (.not. this%is_active) return
    select case (this%frequency_type)
    case (OUT_FREQ_INCREMENT)
      should_output = (mod(increment_id, this%frequency) == 0_i4)
    case (OUT_FREQ_TIME_INTERVAL)
      last_time = 0.0_wp
      if (present(last_output_tim)) last_time = last_output_tim
      should_output = (time - last_time >= this%time_interval)
    case (OUT_FREQ_TIME_MARKS)
      if (allocated(this%time_marks)) then
        do i = 1, this%num_time_marks
          if (abs(time - this%time_marks(i)) < 1.0e-10_wp) then
            should_output = .true.
            return
          end if
        end do
      end if
    end select
  end function FldOutReq_ShouldOutput

  subroutine FldOutReq_Clear(this)
    class(FldOutReq), intent(inout) :: this
    type(ErrorStatusType) :: free_status
    this%name = ''
    this%region_name = ''
    this%region_type = OUT_REGION_ALL
    this%position = OUT_LOC_NODE
    this%frequency = 1_i4
    this%frequency_type = OUT_FREQ_INCREMENT
    this%time_interval = 0.0_wp
    this%num_time_marks = 0_i4
    this%nVars = 0_i4
    this%is_active = .true.
    this%step_id = 0_i4
    if (allocated(this%time_marks)) deallocate(this%time_marks)
    if (this%variables_id >= 0) then
      call init_error_status(free_status)
      call UF_Mem_FreeInt1D(this%variables_id, free_status)
      this%variables_id = -1_i4
      nullify(this%variables)
    end if
  end subroutine FldOutReq_Clear

  subroutine HistOutReq_Init(this, name, region_name, region_type, frequency, frequency_type)
    class(HistOutReq), intent(inout) :: this
    character(len=*), intent(in), optional :: name, region_name
    integer(i4), intent(in), optional :: region_type, frequency, frequency_type
    call this%Clear()
    if (present(name)) this%name = name
    if (present(region_name)) this%region_name = region_name
    if (present(region_type)) this%region_type = region_type
    if (present(frequency)) this%frequency = frequency
    if (present(frequency_type)) this%frequency_type = frequency_type
    this%is_active = .true.
  end subroutine HistOutReq_Init

  subroutine HistOutReq_AddVariable(this, var_id)
    class(HistOutReq), intent(inout) :: this
    integer(i4), intent(in) :: var_id
    integer(i4), pointer :: new_vars(:) => null()
    integer(i4) :: new_id, n, cap
    type(ErrorStatusType) :: alloc_status
    if (.not. associated(this%variables)) then
      call init_error_status(alloc_status)
      call UF_Mem_AllocInt1D(IF_MEM_DOMAIN_CMD, 0, 10_i4, 'HistOutReq_variables', this%variables, this%variables_id, alloc_status)
      if (alloc_status%status_code == IF_STATUS_OK) this%variables = 0_i4
      if (alloc_status%status_code /= IF_STATUS_OK) return
    end if
    n = this%nVars
    if (n >= size(this%variables)) then
      cap = size(this%variables) + 10_i4
      call init_error_status(alloc_status)
      call UF_Mem_AllocInt1D(IF_MEM_DOMAIN_CMD, 0, cap, 'HistOutReq_variables_new', new_vars, new_id, alloc_status)
      if (alloc_status%status_code /= IF_STATUS_OK) return
      new_vars(1:n) = this%variables(1:n)
      new_vars(n+1:cap) = 0_i4
      call UF_Mem_FreeInt1D(this%variables_id, alloc_status)
      this%variables => new_vars
      this%variables_id = new_id
    end if
    n = n + 1_i4
    this%variables(n) = var_id
    this%nVars = n
  end subroutine HistOutReq_AddVariable

  function HistOutReq_ShouldOutput(this, increment_id, time, last_output_tim) result(should_output)
    class(HistOutReq), intent(in) :: this
    integer(i4), intent(in) :: increment_id
    real(wp), intent(in) :: time
    real(wp), intent(in), optional :: last_output_tim
    logical :: should_output
    real(wp) :: last_time
    integer(i4) :: i
    should_output = .false.
    if (.not. this%is_active) return
    select case (this%frequency_type)
    case (OUT_FREQ_INCREMENT)
      should_output = (mod(increment_id, this%frequency) == 0_i4)
    case (OUT_FREQ_TIME_INTERVAL)
      last_time = 0.0_wp
      if (present(last_output_tim)) last_time = last_output_tim
      should_output = (time - last_time >= this%time_interval)
    case (OUT_FREQ_TIME_MARKS)
      if (allocated(this%time_marks)) then
        do i = 1, this%num_time_marks
          if (abs(time - this%time_marks(i)) < 1.0e-10_wp) then
            should_output = .true.
            return
          end if
        end do
      end if
    end select
  end function HistOutReq_ShouldOutput

  subroutine HistOutReq_Clear(this)
    class(HistOutReq), intent(inout) :: this
    type(ErrorStatusType) :: free_status
    this%name = ''
    this%region_name = ''
    this%region_type = OUT_REGION_ALL
    this%frequency = 1_i4
    this%frequency_type = OUT_FREQ_INCREMENT
    this%time_interval = 0.0_wp
    this%num_time_marks = 0_i4
    this%nVars = 0_i4
    this%is_active = .true.
    this%step_id = 0_i4
    if (allocated(this%time_marks)) deallocate(this%time_marks)
    if (this%variables_id >= 0) then
      call init_error_status(free_status)
      call UF_Mem_FreeInt1D(this%variables_id, free_status)
      this%variables_id = -1_i4
      nullify(this%variables)
    end if
  end subroutine HistOutReq_Clear

!===============================================================================
! Canonical 4-type aliases for Output domain
! These wrap the legacy types to conform to the 4-type naming convention.
!===============================================================================

! TYPE aliases
TYPE, PUBLIC :: MD_Out_Desc
  TYPE(OutDesc), POINTER :: inner => NULL()
END TYPE MD_Out_Desc

TYPE, PUBLIC :: MD_Out_State
  TYPE(OutSta), POINTER :: inner => NULL()
END TYPE MD_Out_State

TYPE, PUBLIC :: MD_Out_Ctx
  TYPE(OutCtx), POINTER :: inner => NULL()
END TYPE MD_Out_Ctx

! No separate Algo type (Output doesn't need algorithm params at L3)

! SIO Arg bundle
TYPE, PUBLIC :: MD_Out_Arg
  ! [IN] output requests
  TYPE(MD_Out_Desc) :: desc             ! [IN]  output descriptor
  TYPE(MD_Out_State) :: state           ! [INOUT] output state
  TYPE(MD_Out_Ctx) :: ctx               ! [INOUT] output context

  ! [IN] field data to output
  INTEGER(i4) :: n_field_vars           ! [IN]  number of field variables
  REAL(wp), ALLOCATABLE :: field_data(:,:) ! [IN]  field data array

  ! [OUT] result
  INTEGER(i4) :: n_frames_written       ! [OUT] number of frames written
  INTEGER(i4) :: status_code            ! [OUT] exit status
  CHARACTER(len=256) :: message         ! [OUT] status message
END TYPE MD_Out_Arg

end MODULE MD_Out_Def