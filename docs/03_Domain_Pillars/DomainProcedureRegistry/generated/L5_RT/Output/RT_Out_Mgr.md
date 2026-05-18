# `RT_Out_Mgr.f90`

- **Source**: `L5_RT/Output/RT_Out_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Out_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Mgr`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Out_Frame` (lines 113–162)

```fortran
  type, public :: RT_Out_Frame
    !! Output frame for single increment
    
    ! Meta information
    integer(i4) :: stepId = 0_i4
    integer(i4) :: incId = 0_i4
    real(wp) :: time = 0.0_wp
    real(wp) :: dt = 0.0_wp
    
    ! Mesh information
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nElems = 0_i4
    integer(i4) :: nDofs = 0_i4
    
    ! Node data (continuous memory layout)
    real(wp), allocatable :: nodeCoords(:,:)      ! (3, nNodes)
    real(wp), allocatable :: nodeDisp(:,:) ! (3, nNodes)
    real(wp), allocatable :: nodeVel(:,:)    ! (3, nNodes)
    real(wp), allocatable :: nodeAccel(:,:) ! (3, nNodes)
    real(wp), allocatable :: nodeTemp(:)    ! (nNodes)
    real(wp), allocatable :: nodePress(:)       ! (nNodes)
    
    ! Element data
    integer(i4), allocatable :: elemConn(:,:) ! (max_nodes_per_elem, nElems)
    integer(i4), allocatable :: elemTypes(:)          ! (nElems)
    real(wp), allocatable :: elemStress(:,:)        ! (6, nElems) Voigt notation
    real(wp), allocatable :: elemStrain(:,:)         ! (6, nElems)
    real(wp), allocatable :: elemEnerg(:)          ! (nElems)
    
    ! Field variables (generic storage)
    integer(i4) :: nFldVars = 0_i4
    character(len=64), allocatable :: fldVarNames(:)
    real(wp), allocatable :: fldVarData(:,:)  ! (nNodes or nElems, nFldVars)
    
    ! Status flags
    logical :: hasDisp = .false.
    logical :: hasVel = .false.
    logical :: hasAccel = .false.
    logical :: hasTemp = .false.
    logical :: hasPress = .false.
    logical :: hasStress = .false.
    logical :: hasStrain = .false.
    logical :: inited = .false.
  
  contains
    procedure, public :: Init => RT_Out_FrameInit
    procedure, public :: AllocateNode => RT_Out_FrameAllocNode
    procedure, public :: AllocateElem => RT_Out_FrameAllocElem
    procedure, public :: Cleanup => RT_Out_FrameCleanup
  end type RT_Out_Frame
```

### `RT_Out_Core_Args` (lines 168–194)

```fortran
  TYPE :: RT_Out_Core_Args
  ! Purpose: Core element argument container for output system
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Out_Core_Args
```

### `RT_Out_Cfg` (lines 199–235)

```fortran
  type, public :: RT_Out_Cfg
    !! Configuration for output system
    
    ! Output frequencies
    integer(i4) :: fldFreq = 1_i4
    integer(i4) :: histFreq = 1_i4
    integer(i4) :: restartFreq = 10_i4
    
    ! Output format
    integer(i4) :: format = RT_OUT_FMT_VTK
    character(len=256) :: outDir = "./"
    character(len=64) :: filePrefix = "output"
    
    ! Field output requests
    integer(i4) :: nFldReqs = 0_i4
    type(FldOutReq), allocatable :: fldReqs(:)
    
    ! History output requests
    integer(i4) :: nHistReqs = 0_i4
    type(HistOutReq), allocatable :: histReqs(:)
    
    ! Performance options
    logical :: useBuf = .true.
    logical :: useComp = .false.
    integer(i4) :: bufSize = BUF_SIZE
    logical :: writeBin = .true.
    
    ! Output control
    logical :: outInit = .true.
    logical :: outFinal = .true.
    real(wp) :: timeIntv = 0.0_wp
    
  contains
    procedure, public :: Init => RT_Out_CfgInit
    procedure, public :: AddFieldRequest => RT_Out_CfgAddFldReq
    procedure, public :: AddHistoryRequest => RT_Out_CfgAddHistReq
  end type RT_Out_Cfg
```

### `RT_Out_State` (lines 240–257)

```fortran
  type, public :: RT_Out_State
    !! State tracking for output system
    
    integer(i4) :: lastFldOutInc = 0_i4
    integer(i4) :: lastHistOutInc = 0_i4
    integer(i4) :: lastRestartOutInc = 0_i4
    real(wp) :: lastFldOutTime = 0.0_wp
    real(wp) :: lastHistOutTime = 0.0_wp
    
    integer(i4) :: totalFramesWr = 0_i4
    integer(i4) :: totalHistPts = 0_i4
    
    logical :: inited = .false.
    
  contains
    procedure, public :: Init => RT_Out_StateInit
    procedure, public :: Reset => RT_Out_StateReset
  end type RT_Out_State
```

### `RT_Out_Buf` (lines 262–278)

```fortran
  type, public :: RT_Out_Buf
    !! Buffer for batched write operations
    
    integer(i4) :: capacity = BUF_SIZE
    integer(i4) :: size = 0_i4
    real(wp), allocatable :: data(:)
    integer(i4), allocatable :: indices(:)
    
    logical :: full = .false.
    
  contains
    procedure, public :: Init => RT_Out_BufInit
    procedure, public :: Add => RT_Out_BufAdd
    procedure, public :: Flush => RT_Out_BufFlush
    procedure, public :: Clear => RT_Out_BufClear
    procedure, public :: Cleanup => RT_Out_BufCleanup
  end type RT_Out_Buf
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Out_FrameInit` | 286 | `subroutine RT_Out_FrameInit(this, nNodes, nElems)` |
| SUBROUTINE | `RT_Out_FrameAllocNode` | 301 | `subroutine RT_Out_FrameAllocNode(this, nNodes)` |
| SUBROUTINE | `RT_Out_FrameAllocElem` | 312 | `subroutine RT_Out_FrameAllocElem(this, nElems)` |
| SUBROUTINE | `RT_Out_FrameCleanup` | 323 | `subroutine RT_Out_FrameCleanup(this)` |
| SUBROUTINE | `RT_Out_CfgInit` | 351 | `subroutine RT_Out_CfgInit(this, fldFreq, histFreq, format)` |
| SUBROUTINE | `RT_Out_CfgAddFldReq` | 367 | `subroutine RT_Out_CfgAddFldReq(this, fldReq, stat)` |
| SUBROUTINE | `RT_Out_CfgAddHistReq` | 402 | `subroutine RT_Out_CfgAddHistReq(this, histReq, stat)` |
| SUBROUTINE | `RT_Out_StateInit` | 440 | `subroutine RT_Out_StateInit(this)` |
| SUBROUTINE | `RT_Out_StateReset` | 455 | `subroutine RT_Out_StateReset(this)` |
| SUBROUTINE | `RT_Out_BufInit` | 467 | `subroutine RT_Out_BufInit(this, capacity)` |
| SUBROUTINE | `RT_Out_BufAdd` | 487 | `subroutine RT_Out_BufAdd(this, value, index)` |
| SUBROUTINE | `RT_Out_BufFlush` | 506 | `subroutine RT_Out_BufFlush(this)` |
| SUBROUTINE | `RT_Out_BufClear` | 540 | `subroutine RT_Out_BufClear(this)` |
| SUBROUTINE | `RT_Out_BufCleanup` | 549 | `subroutine RT_Out_BufCleanup(this)` |
| SUBROUTINE | `RT_Out_Init` | 564 | `subroutine RT_Out_Init(cfg, outState, stat)` |
| SUBROUTINE | `RT_Out_Inc` | 586 | `subroutine RT_Out_Inc(stepId, incId, time, cfg, outState, outFrame, stat)` |
| SUBROUTINE | `RT_Out_BuildFrame` | 645 | `subroutine RT_Out_BuildFrame(job, stepId, incId, time, needFld, needHist, &` |
| SUBROUTINE | `RT_Out_WriteFrame` | 696 | `subroutine RT_Out_WriteFrame(outFrame, cfg, outState, stat)` |
| SUBROUTINE | `RT_Out_ChkFreq` | 740 | `subroutine RT_Out_ChkFreq(stepId, incId, time, cfg, outState, &` |
| SUBROUTINE | `RT_Out_Finalize` | 783 | `subroutine RT_Out_Finalize(outState, stat)` |
| SUBROUTINE | `RT_Out_WriteVTK` | 804 | `subroutine RT_Out_WriteVTK(out_frame, filename, status)` |
| SUBROUTINE | `RT_Out_WriteHDF5` | 839 | `subroutine RT_Out_WriteHDF5(outFrame, filename, stat)` |
| SUBROUTINE | `RT_Out_WriteODB` | 861 | `subroutine RT_Out_WriteODB(outFrame, filename, stat)` |
| SUBROUTINE | `RT_Out_UnifMgr` | 888 | `subroutine RT_Out_UnifMgr(model, stepId, incId, time, cfg, &` |
| SUBROUTINE | `RT_Out_CfgAddFldOut` | 913 | `SUBROUTINE RT_Out_CfgAddFldOut(cfg, outReq, stat)` |
| SUBROUTINE | `RT_Out_CfgAddHistOut` | 980 | `SUBROUTINE RT_Out_CfgAddHistOut(cfg, outReq, stat)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
