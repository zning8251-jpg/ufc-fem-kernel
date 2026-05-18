# `AP_SimData_Def.f90`

- **Source**: `L6_AP/AP_SimData_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_SimData_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_SimData_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_SimData`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/_root/AP_SimData_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_GlobState_Type` (lines 27–33)

```fortran
  TYPE, PUBLIC :: UF_GlobState_Type
    LOGICAL :: isInit = .FALSE.
    LOGICAL :: isRun = .FALSE.
    LOGICAL :: isConv = .FALSE.
    INTEGER(i4) :: exitCode = 0_i4
    CHARACTER(len=plen) :: errMsg = ""
  END TYPE UF_GlobState_Type
```

### `IF_CoreConfig_Type_App` (lines 35–38)

```fortran
    TYPE, PUBLIC :: IF_CoreConfig_Type_App
    CHARACTER(len=slen) :: appName = "UniFieldCore"
    CHARACTER(len=16) :: version = "2.0.0"
  END TYPE IF_CoreConfig_Type_App
```

### `IF_CoreConfig_Type_Perf` (lines 40–42)

```fortran
  TYPE, PUBLIC :: IF_CoreConfig_Type_Perf
    INTEGER(i4) :: maxThreads = 1_i4
  END TYPE IF_CoreConfig_Type_Perf
```

### `IF_CoreConfig_Type_Flags` (lines 44–47)

```fortran
  TYPE, PUBLIC :: IF_CoreConfig_Type_Flags
    LOGICAL :: enGPU = .FALSE.
    LOGICAL :: enAI = .TRUE.
  END TYPE IF_CoreConfig_Type_Flags
```

### `IF_CoreConfig_Type_Time` (lines 49–51)

```fortran
  TYPE, PUBLIC :: IF_CoreConfig_Type_Time
    REAL(wp) :: startTime = 0.0_wp
  END TYPE IF_CoreConfig_Type_Time
```

### `IF_CoreConfig_Type` (lines 53–58)

```fortran
  TYPE, PUBLIC :: IF_CoreConfig_Type
    TYPE(IF_CoreConfig_Type_App)   :: app
    TYPE(IF_CoreConfig_Type_Perf)  :: perf
    TYPE(IF_CoreConfig_Type_Flags) :: flags
    TYPE(IF_CoreConfig_Type_Time)  :: time
  END TYPE IF_CoreConfig_Type
```

### `IF_MemPool_Type_ID` (lines 60–62)

```fortran
    TYPE, PUBLIC :: IF_MemPool_Type_ID
    CHARACTER(len=32) :: name = ""
  END TYPE IF_MemPool_Type_ID
```

### `IF_MemPool_Type_Block` (lines 64–67)

```fortran
  TYPE, PUBLIC :: IF_MemPool_Type_Block
    INTEGER(i8) :: blockSize = 1024_i8
    INTEGER(i4) :: nBlocks = 100_i4
  END TYPE IF_MemPool_Type_Block
```

### `IF_MemPool_Type_Size` (lines 69–71)

```fortran
  TYPE, PUBLIC :: IF_MemPool_Type_Size
    INTEGER(i8) :: totSize = 0_i8
  END TYPE IF_MemPool_Type_Size
```

### `IF_MemPool_Type_Flags` (lines 73–76)

```fortran
  TYPE, PUBLIC :: IF_MemPool_Type_Flags
    LOGICAL :: enCoalesce = .FALSE.
    LOGICAL :: isActive = .FALSE.
  END TYPE IF_MemPool_Type_Flags
```

### `IF_MemPool_Type` (lines 78–83)

```fortran
  TYPE, PUBLIC :: IF_MemPool_Type
    TYPE(IF_MemPool_Type_ID)     :: id
    TYPE(IF_MemPool_Type_Block)  :: block
    TYPE(IF_MemPool_Type_Size)   :: size
    TYPE(IF_MemPool_Type_Flags)  :: flags
  END TYPE IF_MemPool_Type
```

### `IF_MemMgr_Type` (lines 85–91)

```fortran
  TYPE, PUBLIC :: IF_MemMgr_Type
    INTEGER(i8) :: totalAlloc = 0_i8
    INTEGER(i8) :: peakMem = 0_i8
    INTEGER(i4) :: nAllocs = 0_i4
    LOGICAL :: enMemPool = .TRUE.
    TYPE(IF_MemPool_Type), ALLOCATABLE :: MemPools(:)
  END TYPE IF_MemMgr_Type
```

### `IF_ThreadMgr_Type` (lines 94–100)

```fortran
  TYPE, PUBLIC :: IF_ThreadMgr_Type
    INTEGER(i4) :: nThreads = 0_i4
    INTEGER(i4) :: maxThreads = 1_i4
    LOGICAL :: enParallel = .FALSE.
    INTEGER(i4) :: threadAffinity = 0_i4  ! 0=auto, 1=compact, 2=scatter
    LOGICAL :: enNested = .FALSE.
  END TYPE IF_ThreadMgr_Type
```

### `IF_ErrHdl_Type_Counts` (lines 102–106)

```fortran
    TYPE, PUBLIC :: IF_ErrHdl_Type_Counts
    INTEGER(i4) :: lastCode = 0_i4
    INTEGER(i4) :: nErrors = 0_i4
    INTEGER(i4) :: nWarnings = 0_i4
  END TYPE IF_ErrHdl_Type_Counts
```

### `IF_ErrHdl_Type_Flags` (lines 108–110)

```fortran
  TYPE, PUBLIC :: IF_ErrHdl_Type_Flags
    LOGICAL :: enStack = .TRUE.
  END TYPE IF_ErrHdl_Type_Flags
```

### `IF_ErrHdl_Type_Ctrl` (lines 112–114)

```fortran
  TYPE, PUBLIC :: IF_ErrHdl_Type_Ctrl
    INTEGER(i4) :: maxStackDepth = 10_i4
  END TYPE IF_ErrHdl_Type_Ctrl
```

### `IF_ErrHdl_Type_IO` (lines 116–118)

```fortran
  TYPE, PUBLIC :: IF_ErrHdl_Type_IO
    CHARACTER(len=plen) :: logFile = ""
  END TYPE IF_ErrHdl_Type_IO
```

### `IF_ErrHdl_Type` (lines 120–125)

```fortran
  TYPE, PUBLIC :: IF_ErrHdl_Type
    TYPE(IF_ErrHdl_Type_Counts) :: counts
    TYPE(IF_ErrHdl_Type_Flags)  :: flags
    TYPE(IF_ErrHdl_Type_Ctrl)   :: ctrl
    TYPE(IF_ErrHdl_Type_IO)     :: io
  END TYPE IF_ErrHdl_Type
```

### `IF_LogSys_Type_Flags` (lines 127–129)

```fortran
    TYPE, PUBLIC :: IF_LogSys_Type_Flags
    LOGICAL :: enabled = .FALSE.
  END TYPE IF_LogSys_Type_Flags
```

### `IF_LogSys_Type_Ctrl` (lines 131–134)

```fortran
  TYPE, PUBLIC :: IF_LogSys_Type_Ctrl
    INTEGER(i4) :: logLevel = 2_i4  ! 0=trace, 1=debug, 2=info, 3=warn, 4=error, 5=fatal
    INTEGER(i4) :: outputTarget = 1_i4  ! 1=stdout, 2=file, 3=buffer, 4=both
  END TYPE IF_LogSys_Type_Ctrl
```

### `IF_LogSys_Type_IO` (lines 136–139)

```fortran
  TYPE, PUBLIC :: IF_LogSys_Type_IO
    CHARACTER(len=plen) :: logFile = "ufc_run.log"
    LOGICAL :: appendMode = .FALSE.
  END TYPE IF_LogSys_Type_IO
```

### `IF_LogSys_Type_Format` (lines 141–145)

```fortran
  TYPE, PUBLIC :: IF_LogSys_Type_Format
    LOGICAL :: enTimestamp = .TRUE.
    LOGICAL :: enModule = .TRUE.
    LOGICAL :: enColorize = .FALSE.
  END TYPE IF_LogSys_Type_Format
```

### `IF_LogSys_Type` (lines 147–152)

```fortran
  TYPE, PUBLIC :: IF_LogSys_Type
    TYPE(IF_LogSys_Type_Flags)  :: flags
    TYPE(IF_LogSys_Type_Ctrl)   :: ctrl
    TYPE(IF_LogSys_Type_IO)     :: io
    TYPE(IF_LogSys_Type_Format) :: format
  END TYPE IF_LogSys_Type
```

### `IF_FileSys_Type_Dirs` (lines 154–159)

```fortran
    TYPE, PUBLIC :: IF_FileSys_Type_Dirs
    CHARACTER(len=plen) :: workDir = ""
    CHARACTER(len=plen) :: inputDir = ""
    CHARACTER(len=plen) :: outputDir = ""
    CHARACTER(len=plen) :: tempDir = ""
  END TYPE IF_FileSys_Type_Dirs
```

### `IF_FileSys_Type_Flags` (lines 161–163)

```fortran
  TYPE, PUBLIC :: IF_FileSys_Type_Flags
    LOGICAL :: enCreateDirs = .TRUE.
  END TYPE IF_FileSys_Type_Flags
```

### `IF_FileSys_Type_Ctrl` (lines 165–167)

```fortran
  TYPE, PUBLIC :: IF_FileSys_Type_Ctrl
    INTEGER(i4) :: maxPathLen = 256_i4
  END TYPE IF_FileSys_Type_Ctrl
```

### `IF_FileSys_Type` (lines 169–173)

```fortran
  TYPE, PUBLIC :: IF_FileSys_Type
    TYPE(IF_FileSys_Type_Dirs)  :: dirs
    TYPE(IF_FileSys_Type_Flags) :: flags
    TYPE(IF_FileSys_Type_Ctrl)  :: ctrl
  END TYPE IF_FileSys_Type
```

### `IF_KernCtrl_Type_Core` (lines 175–177)

```fortran
    TYPE, PUBLIC :: IF_KernCtrl_Type_Core
    TYPE(IF_CoreConfig_Type) :: CoreConfig
  END TYPE IF_KernCtrl_Type_Core
```

### `IF_KernCtrl_Type_Mem` (lines 179–181)

```fortran
  TYPE, PUBLIC :: IF_KernCtrl_Type_Mem
    TYPE(IF_MemMgr_Type) :: MemMgr
  END TYPE IF_KernCtrl_Type_Mem
```

### `IF_KernCtrl_Type_Thread` (lines 183–185)

```fortran
  TYPE, PUBLIC :: IF_KernCtrl_Type_Thread
    TYPE(IF_ThreadMgr_Type) :: ThreadMgr
  END TYPE IF_KernCtrl_Type_Thread
```

### `IF_KernCtrl_Type_Err` (lines 187–189)

```fortran
  TYPE, PUBLIC :: IF_KernCtrl_Type_Err
    TYPE(IF_ErrHdl_Type) :: ErrHdl
  END TYPE IF_KernCtrl_Type_Err
```

### `IF_KernCtrl_Type_Log` (lines 191–193)

```fortran
  TYPE, PUBLIC :: IF_KernCtrl_Type_Log
    TYPE(IF_LogSys_Type) :: LogSys
  END TYPE IF_KernCtrl_Type_Log
```

### `IF_KernCtrl_Type_FS` (lines 195–197)

```fortran
  TYPE, PUBLIC :: IF_KernCtrl_Type_FS
    TYPE(IF_FileSys_Type) :: FileSys
  END TYPE IF_KernCtrl_Type_FS
```

### `IF_KernCtrl_Type` (lines 199–206)

```fortran
  TYPE, PUBLIC :: IF_KernCtrl_Type
    TYPE(IF_KernCtrl_Type_Core)   :: core
    TYPE(IF_KernCtrl_Type_Mem)    :: mem
    TYPE(IF_KernCtrl_Type_Thread) :: thread
    TYPE(IF_KernCtrl_Type_Err)    :: err
    TYPE(IF_KernCtrl_Type_Log)    :: log
    TYPE(IF_KernCtrl_Type_FS)     :: fs
  END TYPE IF_KernCtrl_Type
```

### `UF_AIConfig_Type` (lines 213–219)

```fortran
  TYPE, PUBLIC :: UF_AIConfig_Type
    LOGICAL :: enableAI = .TRUE.
    CHARACTER(len=32) :: aiModel = "Default"
    REAL(wp) :: learningRate = 0.001_wp
    INTEGER(i4) :: trainingEpochs = 100_i4
    LOGICAL :: enableGPU = .FALSE.
  END TYPE UF_AIConfig_Type
```

### `UF_AISolver_Type` (lines 221–226)

```fortran
  TYPE, PUBLIC :: UF_AISolver_Type
    INTEGER(i4) :: strategy = 1_i4
    REAL(wp) :: performance = 0.0_wp
    INTEGER(i4) :: numIter = 0_i4
    LOGICAL :: isConverged = .FALSE.
  END TYPE UF_AISolver_Type
```

### `UF_AIMesh_Type` (lines 228–230)

```fortran
  TYPE, PUBLIC :: UF_AIMesh_Type
    INTEGER(i4) :: nAdaptLevels = 0_i4
  END TYPE UF_AIMesh_Type
```

### `UF_AIPredict_Type` (lines 231–233)

```fortran
  TYPE, PUBLIC :: UF_AIPredict_Type
    LOGICAL :: enabled = .FALSE.
  END TYPE UF_AIPredict_Type
```

### `UF_AIEnh_Type` (lines 235–240)

```fortran
  TYPE, PUBLIC :: UF_AIEnh_Type
    TYPE(UF_AIConfig_Type) :: AIConfig
    TYPE(UF_AISolver_Type) :: AISolver
    TYPE(UF_AIMesh_Type) :: AIMesh
    TYPE(UF_AIPredict_Type) :: AIPredict
  END TYPE UF_AIEnh_Type
```

### `UF_MemberInfo_Type_ID` (lines 242–245)

```fortran
    TYPE, PUBLIC :: UF_MemberInfo_Type_ID
    CHARACTER(len=64) :: memberName = ""
    CHARACTER(len=32) :: memberType = ""
  END TYPE UF_MemberInfo_Type_ID
```

### `UF_MemberInfo_Type_Layout` (lines 247–250)

```fortran
  TYPE, PUBLIC :: UF_MemberInfo_Type_Layout
    INTEGER(i8) :: offset = 0_i8
    INTEGER(i8) :: size = 0_i8
  END TYPE UF_MemberInfo_Type_Layout
```

### `UF_MemberInfo_Type_Flags` (lines 252–255)

```fortran
  TYPE, PUBLIC :: UF_MemberInfo_Type_Flags
    LOGICAL :: isPointer = .FALSE.
    LOGICAL :: isArray = .FALSE.
  END TYPE UF_MemberInfo_Type_Flags
```

### `UF_MemberInfo_Type_Dim` (lines 257–259)

```fortran
  TYPE, PUBLIC :: UF_MemberInfo_Type_Dim
    INTEGER(i4) :: arrayDim = 0_i4
  END TYPE UF_MemberInfo_Type_Dim
```

### `UF_MemberInfo_Type` (lines 261–266)

```fortran
  TYPE, PUBLIC :: UF_MemberInfo_Type
    TYPE(UF_MemberInfo_Type_ID)     :: id
    TYPE(UF_MemberInfo_Type_Layout) :: layout
    TYPE(UF_MemberInfo_Type_Flags)  :: flags
    TYPE(UF_MemberInfo_Type_Dim)    :: dim
  END TYPE UF_MemberInfo_Type
```

### `UF_ReflectInfo_Type` (lines 268–274)

```fortran
  TYPE, PUBLIC :: UF_ReflectInfo_Type
    CHARACTER(len=64) :: structName = ""
    INTEGER(i4) :: numMembers = 0_i4
    TYPE(UF_MemberInfo_Type), ALLOCATABLE :: members(:)
    INTEGER(i8) :: structSize = 0_i8
    CHARACTER(len=32) :: structType = ""
  END TYPE UF_ReflectInfo_Type
```

### `UF_RegEntry_Type_Path` (lines 276–278)

```fortran
    TYPE, PUBLIC :: UF_RegEntry_Type_Path
    CHARACTER(len=128) :: fullPath = ""
  END TYPE UF_RegEntry_Type_Path
```

### `UF_RegEntry_Type_Meta` (lines 280–283)

```fortran
  TYPE, PUBLIC :: UF_RegEntry_Type_Meta
    CHARACTER(len=64) :: cat = ""
    CHARACTER(len=32) :: dataType = ""
  END TYPE UF_RegEntry_Type_Meta
```

### `UF_RegEntry_Type_Addr` (lines 285–288)

```fortran
  TYPE, PUBLIC :: UF_RegEntry_Type_Addr
    INTEGER(i8) :: addr = 0_i8
    INTEGER(i4) :: dim = 0_i4
  END TYPE UF_RegEntry_Type_Addr
```

### `UF_RegEntry_Type_Flags` (lines 290–292)

```fortran
  TYPE, PUBLIC :: UF_RegEntry_Type_Flags
    LOGICAL :: isPersist = .TRUE.
  END TYPE UF_RegEntry_Type_Flags
```

### `UF_RegEntry_Type_Desc` (lines 294–296)

```fortran
  TYPE, PUBLIC :: UF_RegEntry_Type_Desc
    CHARACTER(len=256) :: desc = ""
  END TYPE UF_RegEntry_Type_Desc
```

### `UF_RegEntry_Type` (lines 298–304)

```fortran
  TYPE, PUBLIC :: UF_RegEntry_Type
    TYPE(UF_RegEntry_Type_Path)  :: path
    TYPE(UF_RegEntry_Type_Meta)  :: meta
    TYPE(UF_RegEntry_Type_Addr)  :: addr
    TYPE(UF_RegEntry_Type_Flags) :: flags
    TYPE(UF_RegEntry_Type_Desc)  :: desc_info
  END TYPE UF_RegEntry_Type
```

### `UF_DataReg_Type` (lines 306–311)

```fortran
  TYPE, PUBLIC :: UF_DataReg_Type
    INTEGER(i4) :: nRegs = 0_i4
    TYPE(UF_RegEntry_Type), ALLOCATABLE :: Entries(:)
    CHARACTER(len=plen) :: regPath = ""
    LOGICAL :: enAutoSave = .TRUE.
  END TYPE UF_DataReg_Type
```

### `UF_Plugin_Type` (lines 313–317)

```fortran
  TYPE, PUBLIC :: UF_Plugin_Type
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=32) :: version = ""
    INTEGER(i4) :: apiVersion = 0_i4
  END TYPE UF_Plugin_Type
```

### `AP_SimData_Type` (lines 322–341)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_SimData_Free` | 356 | `SUBROUTINE AP_SimData_Free(sim)` |
| SUBROUTINE | `AP_SimData_Init` | 503 | `SUBROUTINE AP_SimData_Init(sim)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
