!===============================================================================
! MODULE: RT_Mesh_Sys
! LAYER:  L5_RT
! DOMAIN: Mesh
! ROLE:   Mgr — System-level mesh operations and cross-module coordination
! BRIEF:  Node/element numbering, part assembly, orphan mesh handling.
!         Unified mesh interface (merged from RT_Mesh).
!===============================================================================

module RT_Mesh_Sys
!> Status: PROGRESSIVE (partial implementation)
  !! Runtime Mesh System Layer
  !!
  !! Responsibilities:
  !!   - System-level mesh initialization
  !!   - Global mesh operations
  !!   - Cross-module mesh coordination
  !!   - Mesh system cfguration
  !!   - Unified mesh interface aggregation
  !!   - Element, Mat, and section management
  !!
  !! NOTE:
  !!   - This module provides external interfaces
  !!   - Uses RT_Mesh_Util, RT_Elem_Core, RT_Mat_Core, RT_Sect, RT_Mesh_Brg
  !!   - Merged functionality from RT_Mesh module

  
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4, i8
  use MD_Model_Mgr, only: UF_ModelVarContext
  USE MD_Elem_Mgr, only: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, only: MatProperties
  use RT_Base_Core, only: UF_Model
  use RT_Elem_Core, only: RT_Elem_InitReg, RT_Elem_CleanReg, &
                        RT_Elem_RegFam, RT_Elem_Comp, RT_Elem_GetFam, &
                        RT_ElemFamily, RT_ELEM_FAMILY, RT_ELEM_FAMILY, &
                        RT_ELEM_FAMILY, RT_ELEM_FAMILY, &
                        RT_ELEM_FAMILY, RT_ELEM_FAMILY, &
                        RT_ELEM_FAMILY, RT_ELEM_FAMILY, &
                        RT_ELEM_FAMILY, RT_ELEM_FAMILY, &
                        UF_Elem_Truss_Calc, UF_Elem_Beam_Calc, &
                        UF_Elem_S3_Calc, UF_Elem_S4_Calc, UF_Elem_S6_Calc, &
                        UF_Elem_S8_Calc, UF_Elem_S9_Calc, UF_Elem_Continuum_Calc, &
                        UF_Elem_Continuum2D_Calc, UF_Elem_Continuum3D_Calc, &
                        UF_Elem_Therm_Calc, Calc_Pore_Saturated, Calc_Pore_TwoPhase
  use RT_Mat_Core, only: RT_Mat_RegVars, RT_Mat_Init, RT_Mat_Clean
  use RT_Mesh_Brg, only: RT_Mesh_Brg, RT_Mesh_IDMap, RT_Mesh_BrgInit, &
                         RT_Mesh_BrgClean, RT_Mesh_BrgMapElemId, &
                         RT_Mesh_BrgMapMatId, RT_Mesh_BrgMapSectId, &
                         RT_Mesh_BrgMapNodeId, RT_Mesh_BrgGetElemCnt, &
                         RT_Mesh_BrgGetNodeCnt, RT_Mesh_BrgInitMats, &
                         RT_Mesh_BrgInitElems, RT_Mesh_BrgInitSects, &
                         g_meshBrg
  use RT_Mesh_Util, only: RT_Mesh_Valid, RT_MeshValid
  use RT_Sect, only: UF_RT_Section_PopulateLegacyDB, UF_RT_Section_GetDescriptor
  implicit none
  private

  ! ===================================================================
  ! Public Types
  ! ===================================================================
  public :: RT_MeshSystem
  public :: RT_Mesh_Cfg

  ! ===================================================================
  ! Public Procedures (System Level)
  ! ===================================================================
  public :: RT_Mesh_SysInit
  public :: RT_Mesh_SysClean
  public :: RT_Mesh_SysRegModel
  public :: RT_Mesh_SysGetStat
  public :: RT_Mesh_SysValid
  
  ! ===================================================================
  ! Public Procedures (Unified Mesh Interface)
  ! ===================================================================
  public :: RT_Mesh_Init
  public :: RT_Mesh_Clean
  public :: RT_Mesh_RegVars
  public :: RT_Mesh_InitElems
  public :: RT_Mesh_InitMats
  public :: RT_Mesh_InitSects
  public :: RT_Mesh_CompElem
  public :: RT_Mesh_GetElemCnt
  public :: RT_Mesh_GetNodeCnt
  public :: RT_Mesh_GetBrg

  ! ===================================================================
  ! Re-exported Types from Submodules
  ! ===================================================================
  public :: RT_ElemFamily
  public :: RT_Mesh_Brg
  public :: RT_Mesh_IDMap

  ! ===================================================================
  ! Re-exported Procedures from Submodules
  ! ===================================================================
  public :: RT_Elem_RegFam
  public :: RT_Elem_Comp
  public :: RT_Elem_GetFam
  public :: RT_Mat_RegVars
  public :: UF_RT_Section_PopulateLegacyDB
  public :: UF_RT_Section_GetDescriptor
  public :: UF_Elem_Truss_Calc
  public :: UF_Elem_Beam_Calc
  public :: UF_Elem_S3_Calc
  public :: UF_Elem_S4_Calc
  public :: UF_Elem_S6_Calc
  public :: UF_Elem_S8_Calc
  public :: UF_Elem_S9_Calc
  public :: UF_Elem_Continuum_Calc
  public :: UF_Elem_Continuum2D_Calc
  public :: UF_Elem_Continuum3D_Calc
  ! Thermal element Calc function
  public :: UF_Elem_Therm_Calc
  public :: Calc_Pore_Saturated
  public :: Calc_Pore_TwoPhase

  ! ===================================================================
  ! Re-exported Constants from Submodules
  ! ===================================================================
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY
  public :: RT_ELEM_FAMILY

  ! ===================================================================
  ! Mesh System Configuration Type
  ! ===================================================================
  type, public :: RT_Mesh_Cfg
    logical :: autoInitElems = .true.
    logical :: autoInitMats = .true.
    logical :: autoInitSects = .true.
    logical :: enableElemReg = .true.
    integer(i4) :: maxElemFam = 10_i4
  contains
    procedure, public :: Init => RT_Mesh_CfgInit
    procedure, public :: Valid => RT_Mesh_CfgValid
  end type RT_Mesh_Cfg

  ! ===================================================================
  ! Mesh System Type
  ! ===================================================================
  type, public :: RT_MeshSys
    logical :: inited = .false.
    type(RT_Mesh_Cfg) :: cfg
    type(ErrorStatusType) :: stat
  contains
    procedure, public :: Init => RT_Mesh_SysInitType
    procedure, public :: Clean => RT_Mesh_SysCleanType
    procedure, public :: RegVars => RT_Mesh_SysRegVarsType
    procedure, public :: InitElems => RT_Mesh_SysInitElemsType
    procedure, public :: InitMats => RT_Mesh_SysInitMatsType
    procedure, public :: InitSects => RT_Mesh_SysInitSectsType
    procedure, public :: CompElem => RT_Mesh_SysCompElemType
    procedure, public :: GetElemCnt => RT_Mesh_SysGetElemCntType
    procedure, public :: GetNodeCnt => RT_Mesh_SysGetNodeCntType
    procedure, public :: GetBrg => RT_Mesh_SysGetBrgType
    procedure, public :: GetStat => RT_Mesh_SysGetStatType
  end type RT_MeshSys

  ! ===================================================================
  ! Global Mesh System Instance
  ! ===================================================================
  type(RT_MeshSys), save, public :: g_meshSys

contains

  ! ===================================================================
  ! RT_Mesh_Mgr stubs (local; RT_Mesh_Core not yet implemented)
  ! ===================================================================
  subroutine RT_Mesh_MgrInit(maxMeshes, status)
    integer(i4), intent(in), optional :: maxMeshes
    type(ErrorStatusType), intent(out), optional :: status
    if (present(status)) call init_error_status(status)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Mesh_MgrInit

  subroutine RT_Mesh_MgrClean(status)
    type(ErrorStatusType), intent(out), optional :: status
    if (present(status)) call init_error_status(status)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Mesh_MgrClean

  subroutine RT_Mesh_MgrReg(model, status)
    type(UF_Model), intent(in) :: model
    type(ErrorStatusType), intent(out), optional :: status
    if (present(status)) call init_error_status(status)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_Mesh_MgrReg

  subroutine RT_Mesh_MgrGetStat(nMeshes, totalNodes, totalElems)
    integer(i4), intent(out), optional :: nMeshes
    integer(i4), intent(out), optional :: totalNodes
    integer(i4), intent(out), optional :: totalElems
    if (present(nMeshes)) nMeshes = 0
    if (present(totalNodes)) totalNodes = 0
    if (present(totalElems)) totalElems = 0
  end subroutine RT_Mesh_MgrGetStat

  ! ===================================================================
  ! RT_Mesh_Cfg Procedures
  ! ===================================================================
  subroutine RT_Mesh_CfgInit(this, autoInitElems, autoInitMats, &
                            autoInitSects, enableElemReg, maxElemFam)
    class(RT_Mesh_Cfg), intent(inout) :: this
    logical, intent(in), optional :: autoInitElems
    logical, intent(in), optional :: autoInitMats
    logical, intent(in), optional :: autoInitSects
    logical, intent(in), optional :: enableElemReg
    integer(i4), intent(in), optional :: maxElemFam

    if (present(autoInitElems)) then
      this%autoInitElems = autoInitElems
    end if

    if (present(autoInitMats)) then
      this%autoInitMats = autoInitMats
    end if

    if (present(autoInitSects)) then
      this%autoInitSects = autoInitSects
    end if

    if (present(enableElemReg)) then
      this%enableElemReg = enableElemReg
    end if

    if (present(maxElemFam)) then
      this%maxElemFam = maxElemFam
    end if
  end subroutine RT_Mesh_CfgInit

  function RT_Mesh_CfgValid(this) result(valid)
    class(RT_Mesh_Cfg), intent(in) :: this
    logical :: valid

    valid = (this%maxElemFam > 0_i4)
  end function RT_Mesh_CfgValid

  ! ===================================================================
  ! RT_MeshSys Procedures
  ! ===================================================================
  subroutine RT_Mesh_SysInitType(this, cfg, status)
    class(RT_MeshSys), intent(inout) :: this
    type(RT_Mesh_Cfg), intent(in), optional :: cfg
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (this%inited) then
      local_status%status_code = IF_STATUS_OK
      local_status%message = "Mesh system already initialized"
      if (present(status)) status = local_status
      return
    end if

    if (present(cfg)) then
      this%cfg = cfg
    else
      call this%cfg%Init()
    end if

    if (.not. this%cfg%Valid()) then
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Invalid mesh cfguration"
      this%stat = local_status
      if (present(status)) status = local_status
      return
    end if

    if (this%cfg%enableElemReg) then
      call RT_Elem_InitReg()
    end if

    call RT_Mesh_BrgInit(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      this%stat = local_status
      if (present(status)) status = local_status
      return
    end if

    this%inited = .true.
    local_status%status_code = IF_STATUS_OK
    local_status%message = "Mesh system initialized successfully"
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysInitType

  subroutine RT_Mesh_SysCleanType(this, status)
    class(RT_MeshSys), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (.not. this%inited) then
      local_status%status_code = IF_STATUS_OK
      local_status%message = "Mesh system not initialized"
      if (present(status)) status = local_status
      return
    end if

    call RT_Mesh_BrgClean(local_status)
    call RT_Mat_Clean()

    if (this%cfg%enableElemReg) then
      call RT_Elem_CleanReg()
    end if

    this%inited = .false.
    local_status%status_code = IF_STATUS_OK
    local_status%message = "Mesh system cleaned up successfully"
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysCleanType

  subroutine RT_Mesh_SysRegVarsType(this, model, varCtx, status)
    class(RT_MeshSys), intent(inout) :: this
    type(UF_Model), intent(inout) :: model
    type(UF_ModelVarContext), intent(inout) :: varCtx
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (.not. this%inited) then
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Mesh system not initialized"
      this%stat = local_status
      if (present(status)) status = local_status
      return
    end if

    call RT_Mesh_RegVars(model, varCtx)
    call RT_Mat_RegVars(model, varCtx)

    local_status%status_code = IF_STATUS_OK
    local_status%message = "Mesh variables registered successfully"
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysRegVarsType

  subroutine RT_Mesh_SysInitElemsType(this, status)
    class(RT_MeshSys), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (.not. this%inited) then
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Mesh system not initialized"
      if (present(status)) status = local_status
      return
    end if

    call RT_Mesh_BrgInitElems(local_status)
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysInitElemsType

  subroutine RT_Mesh_SysInitMatsType(this, status)
    class(RT_MeshSys), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (.not. this%inited) then
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Mesh system not initialized"
      if (present(status)) status = local_status
      return
    end if

    call RT_Mesh_BrgInitMats(local_status)
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysInitMatsType

  subroutine RT_Mesh_SysInitSectsType(this, status)
    class(RT_MeshSys), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (.not. this%inited) then
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Mesh system not initialized"
      if (present(status)) status = local_status
      return
    end if

    call RT_Mesh_BrgInitSects(local_status)
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysInitSectsType

  subroutine RT_Mesh_SysCompElemType(this, ElemType, Formul, Ctx, state_in, &
                                          Mat, state_out, flags, status)
    class(RT_MeshSys), intent(inout) :: this
    type(ElemType), intent(in) :: ElemType
    type(ElemFormul), intent(in) :: Formul
    type(ElemCtx), intent(in) :: Ctx
    type(ElemState), intent(in) :: state_in
    type(MatProperties), intent(in) :: Mat
    type(ElemState), intent(inout) :: state_out
    type(ElemFlags), intent(inout) :: flags
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (.not. this%inited) then
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Mesh system not initialized"
      if (present(status)) status = local_status
      return
    end if

    call RT_Elem_Comp(ElemType, Formul, Ctx, state_in, &
                        Mat, state_out, flags, local_status)
    this%stat = local_status
    if (present(status)) status = local_status
  end subroutine RT_Mesh_SysCompElemType

  function RT_Mesh_SysGetElemCntType(this) result(count)
    class(RT_MeshSys), intent(in) :: this
    integer(i4) :: count

    count = RT_Mesh_BrgGetElemCnt()
  end function RT_Mesh_SysGetElemCntType

  function RT_Mesh_SysGetNodeCntType(this) result(count)
    class(RT_MeshSys), intent(in) :: this
    integer(i4) :: count

    count = RT_Mesh_BrgGetNodeCnt()
  end function RT_Mesh_SysGetNodeCntType

  function RT_Mesh_SysGetBrgType(this) result(bridge)
    class(RT_MeshSys), intent(in) :: this
    type(RT_Mesh_Brg) :: bridge

    bridge = g_meshBrg
  end function RT_Mesh_SysGetBrgType

  function RT_Mesh_SysGetStatType(this) result(stat)
    class(RT_MeshSys), intent(in) :: this
    type(ErrorStatusType) :: stat

    stat = this%stat
  end function RT_Mesh_SysGetStatType

  ! ===================================================================
  ! System Level Procedures
  ! ===================================================================
  subroutine RT_MeshSys_Init(maxMeshes, status)
    integer(i4), intent(in), optional :: maxMeshes
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)

    call RT_Mesh_MgrInit(maxMeshes=maxMeshes, status=status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) return

    if (present(status)) then
      status%status_code = IF_STATUS_OK
    end if
  end subroutine RT_MeshSys_Init

  subroutine RT_MeshSys_Clean(status)
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)

    call RT_Mesh_MgrClean(status=status)

    if (present(status)) then
      status%status_code = IF_STATUS_OK
    end if
  end subroutine RT_MeshSys_Clean

  subroutine RT_MeshSys_RegModel(model, varCtx, status)
    type(UF_Model), intent(in) :: model
    type(UF_ModelVarContext), intent(inout) :: varCtx
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)

    call RT_Mesh_RegVars(model, varCtx)
    call RT_Mesh_MgrReg(model, status=status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) return

    if (present(status)) then
      status%status_code = IF_STATUS_OK
    end if
  end subroutine RT_MeshSys_RegModel

  subroutine RT_Mesh_SysGetStat(nMeshes, totalNodes, totalElems)
    integer(i4), intent(out), optional :: nMeshes
    integer(i4), intent(out), optional :: totalNodes
    integer(i4), intent(out), optional :: totalElems

    call RT_Mesh_MgrGetStat(nMeshes=nMeshes, totalNodes=totalNodes, totalElems=totalElems)
  end subroutine RT_Mesh_SysGetStat

  function RT_MeshSys_Valid(model, status) result(valid)
    type(UF_Model), intent(in) :: model
    type(ErrorStatusType), intent(out), optional :: status
    logical :: valid
    type(RT_MeshValid) :: validation

    if (present(status)) call init_error_status(status)

    call RT_Mesh_Valid(validation, status)
    valid = validation%isValid

    if (present(status) .and. valid) then
      status%status_code = IF_STATUS_OK
      status%message = "Mesh validation completed"
    end if
  end function RT_MeshSys_Valid

  ! ===================================================================
  ! Global Mesh System Procedures (Unified Interface)
  ! ===================================================================
  subroutine RT_Mesh_Init(cfg, status)
    type(RT_Mesh_Cfg), intent(in), optional :: cfg
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%Init(cfg, status)
  end subroutine RT_Mesh_Init

  subroutine RT_Mesh_Clean(status)
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%Clean(status)
  end subroutine RT_Mesh_Clean

  subroutine RT_Mesh_RegVars(model, varCtx, status)
    type(UF_Model), intent(inout) :: model
    type(UF_ModelVarContext), intent(inout) :: varCtx
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%RegVars(model, varCtx, status)
  end subroutine RT_Mesh_RegVars

  subroutine RT_Mesh_InitElems(status)
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%InitElems(status)
  end subroutine RT_Mesh_InitElems

  subroutine RT_Mesh_InitMats(status)
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%InitMats(status)
  end subroutine RT_Mesh_InitMats

  subroutine RT_Mesh_InitSects(status)
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%InitSects(status)
  end subroutine RT_Mesh_InitSects

  subroutine RT_Mesh_CompElem(ElemType, Formul, Ctx, state_in, &
                                   Mat, state_out, flags, status)
    type(ElemType), intent(in) :: ElemType
    type(ElemFormul), intent(in) :: Formul
    type(ElemCtx), intent(in) :: Ctx
    type(ElemState), intent(in) :: state_in
    type(MatProperties), intent(in) :: Mat
    type(ElemState), intent(inout) :: state_out
    type(ElemFlags), intent(inout) :: flags
    type(ErrorStatusType), intent(out), optional :: status

    call g_meshSys%CompElem(ElemType, Formul, Ctx, state_in, &
                                      Mat, state_out, flags, status)
  end subroutine RT_Mesh_CompElem

  function RT_Mesh_GetElemCnt() result(count)
    integer(i4) :: count

    count = g_meshSys%GetElemCnt()
  end function RT_Mesh_GetElemCnt

  function RT_Mesh_GetNodeCnt() result(count)
    integer(i4) :: count

    count = g_meshSys%GetNodeCnt()
  end function RT_Mesh_GetNodeCnt

  function RT_Mesh_GetBrg() result(bridge)
    type(RT_Mesh_Brg) :: bridge

    bridge = g_meshSys%GetBrg()
  end function RT_Mesh_GetBrg

end module RT_Mesh_Sys