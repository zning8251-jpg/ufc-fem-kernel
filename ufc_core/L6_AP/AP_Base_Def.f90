!===============================================================================
! MODULE: AP_Base_Def
! LAYER:  L6_AP
! DOMAIN: Base
! ROLE:   Def — type definitions
! BRIEF:  L6 application-layer base type definitions (Desc/State/Algo).
!===============================================================================
! Types: AP_SolveCfg_Desc, AP_LoadCase_Desc, AP_LoadMgr_State,
!        AP_BCSet_Desc, AP_BCCtrl_State, AP_OutCtrl_Desc,
!        AP_JobCtrl_Desc, AP_AppCtrl_Ctx
!===============================================================================

MODULE AP_Base_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

    TYPE, PUBLIC :: AP_SolveCfg_Desc_Method
    CHARACTER(len=32) :: analysis = "STATIC"
    CHARACTER(len=32) :: solution = "DEFAULT"
  END TYPE AP_SolveCfg_Desc_Method

  TYPE, PUBLIC :: AP_SolveCfg_Desc_Flags
    LOGICAL :: enLargeDef = .FALSE.
    LOGICAL :: enContact = .FALSE.
    LOGICAL :: enNLGeom = .FALSE.
  END TYPE AP_SolveCfg_Desc_Flags

  TYPE, PUBLIC :: AP_SolveCfg_Desc_Time
    REAL(wp) :: totalTime = 0.0_wp
    REAL(wp) :: dt = 0.0_wp
  END TYPE AP_SolveCfg_Desc_Time

  TYPE, PUBLIC :: AP_SolveCfg_Desc_Ctrl
    INTEGER(i4) :: nSteps = 1_i4
  END TYPE AP_SolveCfg_Desc_Ctrl

  TYPE, PUBLIC :: AP_SolveCfg_Desc
    TYPE(AP_SolveCfg_Desc_Method) :: method
    TYPE(AP_SolveCfg_Desc_Flags)  :: flags
    TYPE(AP_SolveCfg_Desc_Time)   :: time
    TYPE(AP_SolveCfg_Desc_Ctrl)   :: ctrl
  END TYPE AP_SolveCfg_Desc

    TYPE, PUBLIC :: AP_LoadCase_Desc_ID
    INTEGER(i4) :: caseId = 0_i4
    CHARACTER(len=64) :: name = ""
  END TYPE AP_LoadCase_Desc_ID

  TYPE, PUBLIC :: AP_LoadCase_Desc_Type
    REAL(wp) :: mag = 0.0_wp
    CHARACTER(len=32) :: type = ""
  END TYPE AP_LoadCase_Desc_Type

  TYPE, PUBLIC :: AP_LoadCase_Desc_Target
    INTEGER(i4) :: tgtSet = 0_i4
  END TYPE AP_LoadCase_Desc_Target

  TYPE, PUBLIC :: AP_LoadCase_Desc_Time
    REAL(wp) :: tStart = 0.0_wp
    REAL(wp) :: tEnd = 0.0_wp
  END TYPE AP_LoadCase_Desc_Time

  TYPE, PUBLIC :: AP_LoadCase_Desc
    TYPE(AP_LoadCase_Desc_ID)     :: id
    TYPE(AP_LoadCase_Desc_Type)   :: ltype
    TYPE(AP_LoadCase_Desc_Target) :: target
    TYPE(AP_LoadCase_Desc_Time)   :: time
  END TYPE AP_LoadCase_Desc

  TYPE, PUBLIC :: AP_LoadMgr_State
    INTEGER(i4) :: nLoadCases = 0_i4
    TYPE(AP_LoadCase_Desc), ALLOCATABLE :: LoadCases(:)
  END TYPE AP_LoadMgr_State

    TYPE, PUBLIC :: AP_BCSet_Desc_ID
    INTEGER(i4) :: setId = 0_i4
    CHARACTER(len=64) :: name = ""
  END TYPE AP_BCSet_Desc_ID

  TYPE, PUBLIC :: AP_BCSet_Desc_Nodes
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4), ALLOCATABLE :: nodeId(:)
  END TYPE AP_BCSet_Desc_Nodes

  TYPE, PUBLIC :: AP_BCSet_Desc_Dofs
    INTEGER(i4) :: nDof = 0_i4
    INTEGER(i4), ALLOCATABLE :: dofId(:)
  END TYPE AP_BCSet_Desc_Dofs

  TYPE, PUBLIC :: AP_BCSet_Desc_Values
    REAL(wp), ALLOCATABLE :: value(:)
  END TYPE AP_BCSet_Desc_Values

  TYPE, PUBLIC :: AP_BCSet_Desc
    TYPE(AP_BCSet_Desc_ID)     :: id
    TYPE(AP_BCSet_Desc_Nodes)  :: nodes
    TYPE(AP_BCSet_Desc_Dofs)   :: dofs
    TYPE(AP_BCSet_Desc_Values) :: values
  END TYPE AP_BCSet_Desc

  TYPE, PUBLIC :: AP_BCCtrl_State
    INTEGER(i4) :: nBCSets = 0_i4
    TYPE(AP_BCSet_Desc), ALLOCATABLE :: BCSets(:)
  END TYPE AP_BCCtrl_State

  TYPE, PUBLIC :: AP_OutCtrl_Desc
    INTEGER(i4) :: nField = 0_i4
    INTEGER(i4) :: nHist = 0_i4
  END TYPE AP_OutCtrl_Desc

  TYPE, PUBLIC :: AP_JobCtrl_Desc
    CHARACTER(len=64) :: jobName = ""
    CHARACTER(len=128) :: workDir = ""
  END TYPE AP_JobCtrl_Desc

  TYPE, PUBLIC :: AP_AppCtrl_Ctx
    TYPE(AP_SolveCfg_Desc) :: SolveCfg
    TYPE(AP_LoadMgr_State) :: LoadMgr
    TYPE(AP_BCCtrl_State)  :: BCCtrl
    TYPE(AP_OutCtrl_Desc)  :: OutCtrl
    TYPE(AP_JobCtrl_Desc)  :: JobCtrl
  END TYPE AP_AppCtrl_Ctx

END MODULE AP_Base_Def