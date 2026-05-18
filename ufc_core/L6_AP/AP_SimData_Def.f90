!===============================================================================
! MODULE: AP_SimData_Def
! LAYER:  L6_AP
! DOMAIN: Root
! ROLE:   Def — aggregate root data structure
! BRIEF:  Root simulation data type aggregating L1-L6 context types.
!===============================================================================
! Root TYPE: AP_SimData_Type (renamed from AP_SimData_Def to avoid module clash)
! P0: AP_SimData_Init, AP_SimData_Free
!===============================================================================

MODULE AP_SimData_Def
  USE AP_Base_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE MD_Base_Def  ! L3_MD/Ctx/MD_Base_Def.f90 (P0 )
  USE NM_Base_Def
  USE PH_Base_Mgr
  USE RT_Types
  IMPLICIT NONE
  PRIVATE
  INTEGER(i4), PARAMETER :: slen = 64
  INTEGER(i4), PARAMETER :: plen = 256

  ! ---------------------------------------------------------------------------
  ! L1/UF types (leaf first, then composite)
  ! ---------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_GlobState_Type
    LOGICAL :: isInit = .FALSE.
    LOGICAL :: isRun = .FALSE.
    LOGICAL :: isConv = .FALSE.
    INTEGER(i4) :: exitCode = 0_i4
    CHARACTER(len=plen) :: errMsg = ""
  END TYPE UF_GlobState_Type

    TYPE, PUBLIC :: IF_CoreConfig_Type_App
    CHARACTER(len=slen) :: appName = "UniFieldCore"
    CHARACTER(len=16) :: version = "2.0.0"
  END TYPE IF_CoreConfig_Type_App

  TYPE, PUBLIC :: IF_CoreConfig_Type_Perf
    INTEGER(i4) :: maxThreads = 1_i4
  END TYPE IF_CoreConfig_Type_Perf

  TYPE, PUBLIC :: IF_CoreConfig_Type_Flags
    LOGICAL :: enGPU = .FALSE.
    LOGICAL :: enAI = .TRUE.
  END TYPE IF_CoreConfig_Type_Flags

  TYPE, PUBLIC :: IF_CoreConfig_Type_Time
    REAL(wp) :: startTime = 0.0_wp
  END TYPE IF_CoreConfig_Type_Time

  TYPE, PUBLIC :: IF_CoreConfig_Type
    TYPE(IF_CoreConfig_Type_App)   :: app
    TYPE(IF_CoreConfig_Type_Perf)  :: perf
    TYPE(IF_CoreConfig_Type_Flags) :: flags
    TYPE(IF_CoreConfig_Type_Time)  :: time
  END TYPE IF_CoreConfig_Type

    TYPE, PUBLIC :: IF_MemPool_Type_ID
    CHARACTER(len=32) :: name = ""
  END TYPE IF_MemPool_Type_ID

  TYPE, PUBLIC :: IF_MemPool_Type_Block
    INTEGER(i8) :: blockSize = 1024_i8
    INTEGER(i4) :: nBlocks = 100_i4
  END TYPE IF_MemPool_Type_Block

  TYPE, PUBLIC :: IF_MemPool_Type_Size
    INTEGER(i8) :: totSize = 0_i8
  END TYPE IF_MemPool_Type_Size

  TYPE, PUBLIC :: IF_MemPool_Type_Flags
    LOGICAL :: enCoalesce = .FALSE.
    LOGICAL :: isActive = .FALSE.
  END TYPE IF_MemPool_Type_Flags

  TYPE, PUBLIC :: IF_MemPool_Type
    TYPE(IF_MemPool_Type_ID)     :: id
    TYPE(IF_MemPool_Type_Block)  :: block
    TYPE(IF_MemPool_Type_Size)   :: size
    TYPE(IF_MemPool_Type_Flags)  :: flags
  END TYPE IF_MemPool_Type

  TYPE, PUBLIC :: IF_MemMgr_Type
    INTEGER(i8) :: totalAlloc = 0_i8
    INTEGER(i8) :: peakMem = 0_i8
    INTEGER(i4) :: nAllocs = 0_i4
    LOGICAL :: enMemPool = .TRUE.
    TYPE(IF_MemPool_Type), ALLOCATABLE :: MemPools(:)
  END TYPE IF_MemMgr_Type

  ! L1 component types (full definitions)
  TYPE, PUBLIC :: IF_ThreadMgr_Type
    INTEGER(i4) :: nThreads = 0_i4
    INTEGER(i4) :: maxThreads = 1_i4
    LOGICAL :: enParallel = .FALSE.
    INTEGER(i4) :: threadAffinity = 0_i4  ! 0=auto, 1=compact, 2=scatter
    LOGICAL :: enNested = .FALSE.
  END TYPE IF_ThreadMgr_Type
  
    TYPE, PUBLIC :: IF_ErrHdl_Type_Counts
    INTEGER(i4) :: lastCode = 0_i4
    INTEGER(i4) :: nErrors = 0_i4
    INTEGER(i4) :: nWarnings = 0_i4
  END TYPE IF_ErrHdl_Type_Counts

  TYPE, PUBLIC :: IF_ErrHdl_Type_Flags
    LOGICAL :: enStack = .TRUE.
  END TYPE IF_ErrHdl_Type_Flags

  TYPE, PUBLIC :: IF_ErrHdl_Type_Ctrl
    INTEGER(i4) :: maxStackDepth = 10_i4
  END TYPE IF_ErrHdl_Type_Ctrl

  TYPE, PUBLIC :: IF_ErrHdl_Type_IO
    CHARACTER(len=plen) :: logFile = ""
  END TYPE IF_ErrHdl_Type_IO

  TYPE, PUBLIC :: IF_ErrHdl_Type
    TYPE(IF_ErrHdl_Type_Counts) :: counts
    TYPE(IF_ErrHdl_Type_Flags)  :: flags
    TYPE(IF_ErrHdl_Type_Ctrl)   :: ctrl
    TYPE(IF_ErrHdl_Type_IO)     :: io
  END TYPE IF_ErrHdl_Type
  
    TYPE, PUBLIC :: IF_LogSys_Type_Flags
    LOGICAL :: enabled = .FALSE.
  END TYPE IF_LogSys_Type_Flags

  TYPE, PUBLIC :: IF_LogSys_Type_Ctrl
    INTEGER(i4) :: logLevel = 2_i4  ! 0=trace, 1=debug, 2=info, 3=warn, 4=error, 5=fatal
    INTEGER(i4) :: outputTarget = 1_i4  ! 1=stdout, 2=file, 3=buffer, 4=both
  END TYPE IF_LogSys_Type_Ctrl

  TYPE, PUBLIC :: IF_LogSys_Type_IO
    CHARACTER(len=plen) :: logFile = "ufc_run.log"
    LOGICAL :: appendMode = .FALSE.
  END TYPE IF_LogSys_Type_IO

  TYPE, PUBLIC :: IF_LogSys_Type_Format
    LOGICAL :: enTimestamp = .TRUE.
    LOGICAL :: enModule = .TRUE.
    LOGICAL :: enColorize = .FALSE.
  END TYPE IF_LogSys_Type_Format

  TYPE, PUBLIC :: IF_LogSys_Type
    TYPE(IF_LogSys_Type_Flags)  :: flags
    TYPE(IF_LogSys_Type_Ctrl)   :: ctrl
    TYPE(IF_LogSys_Type_IO)     :: io
    TYPE(IF_LogSys_Type_Format) :: format
  END TYPE IF_LogSys_Type
  
    TYPE, PUBLIC :: IF_FileSys_Type_Dirs
    CHARACTER(len=plen) :: workDir = ""
    CHARACTER(len=plen) :: inputDir = ""
    CHARACTER(len=plen) :: outputDir = ""
    CHARACTER(len=plen) :: tempDir = ""
  END TYPE IF_FileSys_Type_Dirs

  TYPE, PUBLIC :: IF_FileSys_Type_Flags
    LOGICAL :: enCreateDirs = .TRUE.
  END TYPE IF_FileSys_Type_Flags

  TYPE, PUBLIC :: IF_FileSys_Type_Ctrl
    INTEGER(i4) :: maxPathLen = 256_i4
  END TYPE IF_FileSys_Type_Ctrl

  TYPE, PUBLIC :: IF_FileSys_Type
    TYPE(IF_FileSys_Type_Dirs)  :: dirs
    TYPE(IF_FileSys_Type_Flags) :: flags
    TYPE(IF_FileSys_Type_Ctrl)  :: ctrl
  END TYPE IF_FileSys_Type

    TYPE, PUBLIC :: IF_KernCtrl_Type_Core
    TYPE(IF_CoreConfig_Type) :: CoreConfig
  END TYPE IF_KernCtrl_Type_Core

  TYPE, PUBLIC :: IF_KernCtrl_Type_Mem
    TYPE(IF_MemMgr_Type) :: MemMgr
  END TYPE IF_KernCtrl_Type_Mem

  TYPE, PUBLIC :: IF_KernCtrl_Type_Thread
    TYPE(IF_ThreadMgr_Type) :: ThreadMgr
  END TYPE IF_KernCtrl_Type_Thread

  TYPE, PUBLIC :: IF_KernCtrl_Type_Err
    TYPE(IF_ErrHdl_Type) :: ErrHdl
  END TYPE IF_KernCtrl_Type_Err

  TYPE, PUBLIC :: IF_KernCtrl_Type_Log
    TYPE(IF_LogSys_Type) :: LogSys
  END TYPE IF_KernCtrl_Type_Log

  TYPE, PUBLIC :: IF_KernCtrl_Type_FS
    TYPE(IF_FileSys_Type) :: FileSys
  END TYPE IF_KernCtrl_Type_FS

  TYPE, PUBLIC :: IF_KernCtrl_Type
    TYPE(IF_KernCtrl_Type_Core)   :: core
    TYPE(IF_KernCtrl_Type_Mem)    :: mem
    TYPE(IF_KernCtrl_Type_Thread) :: thread
    TYPE(IF_KernCtrl_Type_Err)    :: err
    TYPE(IF_KernCtrl_Type_Log)    :: log
    TYPE(IF_KernCtrl_Type_FS)     :: fs
  END TYPE IF_KernCtrl_Type

  ! L2～L6 types: see NM_Base_Def, MD_Base_Def, PH_Types, RT_Types, AP_Base_Def

  ! ---------------------------------------------------------------------------
  ! UF AI / Reflect / Plugin (design-time stubs)
  ! ---------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_AIConfig_Type
    LOGICAL :: enableAI = .TRUE.
    CHARACTER(len=32) :: aiModel = "Default"
    REAL(wp) :: learningRate = 0.001_wp
    INTEGER(i4) :: trainingEpochs = 100_i4
    LOGICAL :: enableGPU = .FALSE.
  END TYPE UF_AIConfig_Type

  TYPE, PUBLIC :: UF_AISolver_Type
    INTEGER(i4) :: strategy = 1_i4
    REAL(wp) :: performance = 0.0_wp
    INTEGER(i4) :: numIter = 0_i4
    LOGICAL :: isConverged = .FALSE.
  END TYPE UF_AISolver_Type

  TYPE, PUBLIC :: UF_AIMesh_Type
    INTEGER(i4) :: nAdaptLevels = 0_i4
  END TYPE UF_AIMesh_Type
  TYPE, PUBLIC :: UF_AIPredict_Type
    LOGICAL :: enabled = .FALSE.
  END TYPE UF_AIPredict_Type

  TYPE, PUBLIC :: UF_AIEnh_Type
    TYPE(UF_AIConfig_Type) :: AIConfig
    TYPE(UF_AISolver_Type) :: AISolver
    TYPE(UF_AIMesh_Type) :: AIMesh
    TYPE(UF_AIPredict_Type) :: AIPredict
  END TYPE UF_AIEnh_Type

    TYPE, PUBLIC :: UF_MemberInfo_Type_ID
    CHARACTER(len=64) :: memberName = ""
    CHARACTER(len=32) :: memberType = ""
  END TYPE UF_MemberInfo_Type_ID

  TYPE, PUBLIC :: UF_MemberInfo_Type_Layout
    INTEGER(i8) :: offset = 0_i8
    INTEGER(i8) :: size = 0_i8
  END TYPE UF_MemberInfo_Type_Layout

  TYPE, PUBLIC :: UF_MemberInfo_Type_Flags
    LOGICAL :: isPointer = .FALSE.
    LOGICAL :: isArray = .FALSE.
  END TYPE UF_MemberInfo_Type_Flags

  TYPE, PUBLIC :: UF_MemberInfo_Type_Dim
    INTEGER(i4) :: arrayDim = 0_i4
  END TYPE UF_MemberInfo_Type_Dim

  TYPE, PUBLIC :: UF_MemberInfo_Type
    TYPE(UF_MemberInfo_Type_ID)     :: id
    TYPE(UF_MemberInfo_Type_Layout) :: layout
    TYPE(UF_MemberInfo_Type_Flags)  :: flags
    TYPE(UF_MemberInfo_Type_Dim)    :: dim
  END TYPE UF_MemberInfo_Type

  TYPE, PUBLIC :: UF_ReflectInfo_Type
    CHARACTER(len=64) :: structName = ""
    INTEGER(i4) :: numMembers = 0_i4
    TYPE(UF_MemberInfo_Type), ALLOCATABLE :: members(:)
    INTEGER(i8) :: structSize = 0_i8
    CHARACTER(len=32) :: structType = ""
  END TYPE UF_ReflectInfo_Type

    TYPE, PUBLIC :: UF_RegEntry_Type_Path
    CHARACTER(len=128) :: fullPath = ""
  END TYPE UF_RegEntry_Type_Path

  TYPE, PUBLIC :: UF_RegEntry_Type_Meta
    CHARACTER(len=64) :: cat = ""
    CHARACTER(len=32) :: dataType = ""
  END TYPE UF_RegEntry_Type_Meta

  TYPE, PUBLIC :: UF_RegEntry_Type_Addr
    INTEGER(i8) :: addr = 0_i8
    INTEGER(i4) :: dim = 0_i4
  END TYPE UF_RegEntry_Type_Addr

  TYPE, PUBLIC :: UF_RegEntry_Type_Flags
    LOGICAL :: isPersist = .TRUE.
  END TYPE UF_RegEntry_Type_Flags

  TYPE, PUBLIC :: UF_RegEntry_Type_Desc
    CHARACTER(len=256) :: desc = ""
  END TYPE UF_RegEntry_Type_Desc

  TYPE, PUBLIC :: UF_RegEntry_Type
    TYPE(UF_RegEntry_Type_Path)  :: path
    TYPE(UF_RegEntry_Type_Meta)  :: meta
    TYPE(UF_RegEntry_Type_Addr)  :: addr
    TYPE(UF_RegEntry_Type_Flags) :: flags
    TYPE(UF_RegEntry_Type_Desc)  :: desc_info
  END TYPE UF_RegEntry_Type

  TYPE, PUBLIC :: UF_DataReg_Type
    INTEGER(i4) :: nRegs = 0_i4
    TYPE(UF_RegEntry_Type), ALLOCATABLE :: Entries(:)
    CHARACTER(len=plen) :: regPath = ""
    LOGICAL :: enAutoSave = .TRUE.
  END TYPE UF_DataReg_Type

  TYPE, PUBLIC :: UF_Plugin_Type
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=32) :: version = ""
    INTEGER(i4) :: apiVersion = 0_i4
  END TYPE UF_Plugin_Type

  ! ---------------------------------------------------------------------------
  ! Root: AP_SimData_Def
  ! ---------------------------------------------------------------------------
  TYPE, PUBLIC :: AP_SimData_Type
    !  control ?level ?
    TYPE(IF_KernCtrl_Type) :: KernCtrl      ! L1:  control
    TYPE(NM_NumCtrl_Type) :: NumCtrl        ! L2:  valuealgorithmcontrol
    TYPE(MD_ModelCtrl_Type) :: ModelCtrl    ! L3:  definitioncontrol
    TYPE(PH_PhysCtrl_Ctx) :: PhysCtrl      ! L4:  computationcontrol
    TYPE(RT_StateCtrl_Type) :: StateCtrl    ! L5:  statuscontrol
    TYPE(AP_AppCtrl_Ctx) :: AppCtrl        ! L6:  control
    
    ! AI purpose
    TYPE(UF_AIEnh_Type) :: AIEnh
    
    !  status
    TYPE(UF_GlobState_Type) :: GlobState
    
    !  control ?7 ?
    LOGICAL :: enDataFlow = .TRUE.          !  
    LOGICAL :: enContext = .TRUE.           !  Context 
    LOGICAL :: enBridge = .TRUE.            !  Bridge 
  END TYPE AP_SimData_Type

  ! ---------------------------------------------------------------------------
  ! Root init/free (minimal: release allocatable components)
  ! ---------------------------------------------------------------------------
  PUBLIC :: AP_SimData_Free
  PUBLIC :: AP_SimData_Init

CONTAINS

  ! ==========================================================================
  ! AP_SimData_Free: Free all allocated memory in simulation data structure
  ! ==========================================================================
  !> @brief Free all allocated memory
  !! @param[inout] sim Simulation data structure to free
  SUBROUTINE AP_SimData_Free(sim)
    TYPE(AP_SimData_Type), INTENT(INOUT) :: sim
    INTEGER(i4) :: i
    ! L1
    IF (ALLOCATED(sim%KernCtrl%MemMgr%MemPools)) DEALLOCATE(sim%KernCtrl%MemMgr%MemPools)
    ! L3 Mesh
    IF (ALLOCATED(sim%ModelCtrl%mesh%NodeTbl%coords)) DEALLOCATE(sim%ModelCtrl%mesh%NodeTbl%coords)
    IF (ALLOCATED(sim%ModelCtrl%mesh%NodeTbl%dofMap)) DEALLOCATE(sim%ModelCtrl%mesh%NodeTbl%dofMap)
    IF (ALLOCATED(sim%ModelCtrl%mesh%ElemTbl%elemId)) DEALLOCATE(sim%ModelCtrl%mesh%ElemTbl%elemId)
    IF (ALLOCATED(sim%ModelCtrl%mesh%ElemTbl%typeId)) DEALLOCATE(sim%ModelCtrl%mesh%ElemTbl%typeId)
    IF (ALLOCATED(sim%ModelCtrl%mesh%ElemTbl%conn)) DEALLOCATE(sim%ModelCtrl%mesh%ElemTbl%conn)
    IF (ALLOCATED(sim%ModelCtrl%mesh%ElemDefTbl%ElemDefs)) DEALLOCATE(sim%ModelCtrl%mesh%ElemDefTbl%ElemDefs)
    ! L3 Mat
    IF (ALLOCATED(sim%ModelCtrl%material%MatLib%MatDefs)) THEN
      DO i = 1, SIZE(sim%ModelCtrl%material%MatLib%MatDefs)
        IF (ALLOCATED(sim%ModelCtrl%material%MatLib%MatDefs(i)%props)) &
          DEALLOCATE(sim%ModelCtrl%material%MatLib%MatDefs(i)%props)
        IF (ALLOCATED(sim%ModelCtrl%material%MatLib%MatDefs(i)%stateNames)) &
          DEALLOCATE(sim%ModelCtrl%material%MatLib%MatDefs(i)%stateNames)
      END DO
      DEALLOCATE(sim%ModelCtrl%material%MatLib%MatDefs)
    END IF
    IF (ALLOCATED(sim%ModelCtrl%material%MatAssign%matIdOfElem)) &
      DEALLOCATE(sim%ModelCtrl%material%MatAssign%matIdOfElem)
    ! L3 Sect / Set / Amp / Step
    IF (ALLOCATED(sim%ModelCtrl%section%SectDefs)) DEALLOCATE(sim%ModelCtrl%section%SectDefs)
    IF (ALLOCATED(sim%ModelCtrl%sets%NodeSets)) THEN
      DO i = 1, SIZE(sim%ModelCtrl%sets%NodeSets)
        IF (ALLOCATED(sim%ModelCtrl%sets%NodeSets(i)%nodeId)) &
          DEALLOCATE(sim%ModelCtrl%sets%NodeSets(i)%nodeId)
      END DO
      DEALLOCATE(sim%ModelCtrl%sets%NodeSets)
    END IF
    IF (ALLOCATED(sim%ModelCtrl%sets%ElemSets)) THEN
      DO i = 1, SIZE(sim%ModelCtrl%sets%ElemSets)
        IF (ALLOCATED(sim%ModelCtrl%sets%ElemSets(i)%elemId)) &
          DEALLOCATE(sim%ModelCtrl%sets%ElemSets(i)%elemId)
      END DO
      DEALLOCATE(sim%ModelCtrl%sets%ElemSets)
    END IF
    IF (ALLOCATED(sim%ModelCtrl%amplitude%AmpDefs)) THEN
      DO i = 1, SIZE(sim%ModelCtrl%amplitude%AmpDefs)
        IF (ALLOCATED(sim%ModelCtrl%amplitude%AmpDefs(i)%time)) &
          DEALLOCATE(sim%ModelCtrl%amplitude%AmpDefs(i)%time)
        IF (ALLOCATED(sim%ModelCtrl%amplitude%AmpDefs(i)%value)) &
          DEALLOCATE(sim%ModelCtrl%amplitude%AmpDefs(i)%value)
      END DO
      DEALLOCATE(sim%ModelCtrl%amplitude%AmpDefs)
    END IF
    IF (ALLOCATED(sim%ModelCtrl%step%StepCfg)) DEALLOCATE(sim%ModelCtrl%step%StepCfg)
    ! L4 Phys
    IF (ALLOCATED(sim%PhysCtrl%PhysCfg%fieldNames)) DEALLOCATE(sim%PhysCtrl%PhysCfg%fieldNames)
    IF (ALLOCATED(sim%PhysCtrl%PhysCfg%fieldActive)) DEALLOCATE(sim%PhysCtrl%PhysCfg%fieldActive)
    IF (ALLOCATED(sim%PhysCtrl%FieldMgr%Fields)) THEN
      DO i = 1, SIZE(sim%PhysCtrl%FieldMgr%Fields)
        IF (ALLOCATED(sim%PhysCtrl%FieldMgr%Fields(i)%value)) DEALLOCATE(sim%PhysCtrl%FieldMgr%Fields(i)%value)
        IF (ALLOCATED(sim%PhysCtrl%FieldMgr%Fields(i)%grad)) DEALLOCATE(sim%PhysCtrl%FieldMgr%Fields(i)%grad)
      END DO
      DEALLOCATE(sim%PhysCtrl%FieldMgr%Fields)
    END IF
    IF (ALLOCATED(sim%PhysCtrl%FieldMgr%globField)) DEALLOCATE(sim%PhysCtrl%FieldMgr%globField)
    ! PH_ElemAlgCtrl / ConstitutiveCtrl / ContactCtrl allocatables (minimal set)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%gpW)) DEALLOCATE(sim%PhysCtrl%ElemAlg%gpW)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%gpLoc)) DEALLOCATE(sim%PhysCtrl%ElemAlg%gpLoc)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%B)) DEALLOCATE(sim%PhysCtrl%ElemAlg%B)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%J)) DEALLOCATE(sim%PhysCtrl%ElemAlg%J)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%detJ)) DEALLOCATE(sim%PhysCtrl%ElemAlg%detJ)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%F)) DEALLOCATE(sim%PhysCtrl%ElemAlg%F)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%x)) DEALLOCATE(sim%PhysCtrl%ElemAlg%x)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%X)) DEALLOCATE(sim%PhysCtrl%ElemAlg%X)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%dF_dt)) DEALLOCATE(sim%PhysCtrl%ElemAlg%dF_dt)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%L)) DEALLOCATE(sim%PhysCtrl%ElemAlg%L)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%D)) DEALLOCATE(sim%PhysCtrl%ElemAlg%D)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%N)) DEALLOCATE(sim%PhysCtrl%ElemAlg%N)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%dN_dxi)) DEALLOCATE(sim%PhysCtrl%ElemAlg%dN_dxi)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%xi)) DEALLOCATE(sim%PhysCtrl%ElemAlg%xi)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%eta)) DEALLOCATE(sim%PhysCtrl%ElemAlg%eta)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%zeta)) DEALLOCATE(sim%PhysCtrl%ElemAlg%zeta)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%K_elem)) DEALLOCATE(sim%PhysCtrl%ElemAlg%K_elem)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%x_membrane)) DEALLOCATE(sim%PhysCtrl%ElemAlg%x_membrane)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%x_bending)) DEALLOCATE(sim%PhysCtrl%ElemAlg%x_bending)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%B_membrane)) DEALLOCATE(sim%PhysCtrl%ElemAlg%B_membrane)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%B_bending)) DEALLOCATE(sim%PhysCtrl%ElemAlg%B_bending)
    IF (ALLOCATED(sim%PhysCtrl%ElemAlg%kappa)) DEALLOCATE(sim%PhysCtrl%ElemAlg%kappa)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%stress)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%stress)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%strain)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%strain)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%D)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%D)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%state)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%state)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%E)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%E)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%C)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%C)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%S)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%S)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%T)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%T)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%d_epsilon_dt)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%d_epsilon_dt)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%d_epsilon_pl)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%d_epsilon_pl)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%d_epsilon_creep)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%d_epsilon_creep)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%sigma_dot)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%sigma_dot)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%Jaumann_rate)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%Jaumann_rate)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%epsilon_pl)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%epsilon_pl)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%H)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%H)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%K_tan)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%K_tan)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%epsilon_vol)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%epsilon_vol)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%epsilon_dev)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%epsilon_dev)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%W)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%W)
    IF (ALLOCATED(sim%PhysCtrl%ConstitCtrl%epsilon_visc)) DEALLOCATE(sim%PhysCtrl%ConstitCtrl%epsilon_visc)
    IF (ALLOCATED(sim%PhysCtrl%ConstrCtrl%mpcId)) DEALLOCATE(sim%PhysCtrl%ConstrCtrl%mpcId)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%pairId)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%pairId)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%gap)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%gap)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%normal)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%normal)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%p_n)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%p_n)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%p_t)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%p_t)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%tau_fric)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%tau_fric)
    IF (ALLOCATED(sim%PhysCtrl%ContactCtrl%slip_rate)) DEALLOCATE(sim%PhysCtrl%ContactCtrl%slip_rate)
    ! L5 RT
    IF (ALLOCATED(sim%StateCtrl%LinSys%K)) DEALLOCATE(sim%StateCtrl%LinSys%K)
    IF (ALLOCATED(sim%StateCtrl%LinSys%R)) DEALLOCATE(sim%StateCtrl%LinSys%R)
    IF (ALLOCATED(sim%StateCtrl%LinSys%du)) DEALLOCATE(sim%StateCtrl%LinSys%du)
    IF (ALLOCATED(sim%StateCtrl%LinSys%M)) DEALLOCATE(sim%StateCtrl%LinSys%M)
    IF (ALLOCATED(sim%StateCtrl%LinSys%C)) DEALLOCATE(sim%StateCtrl%LinSys%C)
    IF (ALLOCATED(sim%StateCtrl%LinSys%lambda_eig)) DEALLOCATE(sim%StateCtrl%LinSys%lambda_eig)
    IF (ALLOCATED(sim%StateCtrl%LinSys%phi_eig)) DEALLOCATE(sim%StateCtrl%LinSys%phi_eig)
    IF (ALLOCATED(sim%StateCtrl%FieldState%u)) DEALLOCATE(sim%StateCtrl%FieldState%u)
    IF (ALLOCATED(sim%StateCtrl%FieldState%v)) DEALLOCATE(sim%StateCtrl%FieldState%v)
    IF (ALLOCATED(sim%StateCtrl%FieldState%a)) DEALLOCATE(sim%StateCtrl%FieldState%a)
    IF (ALLOCATED(sim%StateCtrl%FieldState%T)) DEALLOCATE(sim%StateCtrl%FieldState%T)
    IF (ALLOCATED(sim%StateCtrl%FieldState%p)) DEALLOCATE(sim%StateCtrl%FieldState%p)
    IF (ALLOCATED(sim%StateCtrl%FieldState%q)) DEALLOCATE(sim%StateCtrl%FieldState%q)
    IF (ALLOCATED(sim%StateCtrl%FieldState%rotation)) DEALLOCATE(sim%StateCtrl%FieldState%rotation)
    ! L6 AP
    IF (ALLOCATED(sim%AppCtrl%LoadMgr%LoadCases)) DEALLOCATE(sim%AppCtrl%LoadMgr%LoadCases)
    IF (ALLOCATED(sim%AppCtrl%BCCtrl%BCSets)) THEN
      DO i = 1, SIZE(sim%AppCtrl%BCCtrl%BCSets)
        IF (ALLOCATED(sim%AppCtrl%BCCtrl%BCSets(i)%nodeId)) &
          DEALLOCATE(sim%AppCtrl%BCCtrl%BCSets(i)%nodeId)
        IF (ALLOCATED(sim%AppCtrl%BCCtrl%BCSets(i)%dofId)) &
          DEALLOCATE(sim%AppCtrl%BCCtrl%BCSets(i)%dofId)
        IF (ALLOCATED(sim%AppCtrl%BCCtrl%BCSets(i)%value)) &
          DEALLOCATE(sim%AppCtrl%BCCtrl%BCSets(i)%value)
      END DO
      DEALLOCATE(sim%AppCtrl%BCCtrl%BCSets)
    END IF
  END SUBROUTINE AP_SimData_Free

  ! ==========================================================================
  ! AP_SimData_Init: Initialize simulation data structure to default state
  ! ==========================================================================
  !> @brief Initialize simulation data structure
  !! @param[inout] sim Simulation data structure to initialize
  SUBROUTINE AP_SimData_Init(sim)
    TYPE(AP_SimData_Type), INTENT(INOUT) :: sim

    ! Free any previously allocated memory first
    CALL AP_SimData_Free(sim)
    
    ! Initialize GlobState flags
    sim%GlobState%isInit = .TRUE.
    sim%GlobState%isRun = .FALSE.
    sim%GlobState%isConv = .FALSE.
    sim%GlobState%exitCode = 0_i4
    sim%GlobState%errMsg = ""
    
    ! Note: All other types have default initialization from type definitions
    ! Allocatable arrays remain unallocated until explicitly allocated
  END SUBROUTINE AP_SimData_Init

END MODULE AP_SimData_Def