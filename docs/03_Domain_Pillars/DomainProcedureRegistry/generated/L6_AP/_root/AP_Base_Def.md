# `AP_Base_Def.f90`

- **Source**: `L6_AP/AP_Base_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Base_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Base_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Base`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/_root/AP_Base_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_SolveCfg_Desc_Method` (lines 18–21)

```fortran
    TYPE, PUBLIC :: AP_SolveCfg_Desc_Method
    CHARACTER(len=32) :: analysis = "STATIC"
    CHARACTER(len=32) :: solution = "DEFAULT"
  END TYPE AP_SolveCfg_Desc_Method
```

### `AP_SolveCfg_Desc_Flags` (lines 23–27)

```fortran
  TYPE, PUBLIC :: AP_SolveCfg_Desc_Flags
    LOGICAL :: enLargeDef = .FALSE.
    LOGICAL :: enContact = .FALSE.
    LOGICAL :: enNLGeom = .FALSE.
  END TYPE AP_SolveCfg_Desc_Flags
```

### `AP_SolveCfg_Desc_Time` (lines 29–32)

```fortran
  TYPE, PUBLIC :: AP_SolveCfg_Desc_Time
    REAL(wp) :: totalTime = 0.0_wp
    REAL(wp) :: dt = 0.0_wp
  END TYPE AP_SolveCfg_Desc_Time
```

### `AP_SolveCfg_Desc_Ctrl` (lines 34–36)

```fortran
  TYPE, PUBLIC :: AP_SolveCfg_Desc_Ctrl
    INTEGER(i4) :: nSteps = 1_i4
  END TYPE AP_SolveCfg_Desc_Ctrl
```

### `AP_SolveCfg_Desc` (lines 38–43)

```fortran
  TYPE, PUBLIC :: AP_SolveCfg_Desc
    TYPE(AP_SolveCfg_Desc_Method) :: method
    TYPE(AP_SolveCfg_Desc_Flags)  :: flags
    TYPE(AP_SolveCfg_Desc_Time)   :: time
    TYPE(AP_SolveCfg_Desc_Ctrl)   :: ctrl
  END TYPE AP_SolveCfg_Desc
```

### `AP_LoadCase_Desc_ID` (lines 45–48)

```fortran
    TYPE, PUBLIC :: AP_LoadCase_Desc_ID
    INTEGER(i4) :: caseId = 0_i4
    CHARACTER(len=64) :: name = ""
  END TYPE AP_LoadCase_Desc_ID
```

### `AP_LoadCase_Desc_Type` (lines 50–53)

```fortran
  TYPE, PUBLIC :: AP_LoadCase_Desc_Type
    REAL(wp) :: mag = 0.0_wp
    CHARACTER(len=32) :: type = ""
  END TYPE AP_LoadCase_Desc_Type
```

### `AP_LoadCase_Desc_Target` (lines 55–57)

```fortran
  TYPE, PUBLIC :: AP_LoadCase_Desc_Target
    INTEGER(i4) :: tgtSet = 0_i4
  END TYPE AP_LoadCase_Desc_Target
```

### `AP_LoadCase_Desc_Time` (lines 59–62)

```fortran
  TYPE, PUBLIC :: AP_LoadCase_Desc_Time
    REAL(wp) :: tStart = 0.0_wp
    REAL(wp) :: tEnd = 0.0_wp
  END TYPE AP_LoadCase_Desc_Time
```

### `AP_LoadCase_Desc` (lines 64–69)

```fortran
  TYPE, PUBLIC :: AP_LoadCase_Desc
    TYPE(AP_LoadCase_Desc_ID)     :: id
    TYPE(AP_LoadCase_Desc_Type)   :: ltype
    TYPE(AP_LoadCase_Desc_Target) :: target
    TYPE(AP_LoadCase_Desc_Time)   :: time
  END TYPE AP_LoadCase_Desc
```

### `AP_LoadMgr_State` (lines 71–74)

```fortran
  TYPE, PUBLIC :: AP_LoadMgr_State
    INTEGER(i4) :: nLoadCases = 0_i4
    TYPE(AP_LoadCase_Desc), ALLOCATABLE :: LoadCases(:)
  END TYPE AP_LoadMgr_State
```

### `AP_BCSet_Desc_ID` (lines 76–79)

```fortran
    TYPE, PUBLIC :: AP_BCSet_Desc_ID
    INTEGER(i4) :: setId = 0_i4
    CHARACTER(len=64) :: name = ""
  END TYPE AP_BCSet_Desc_ID
```

### `AP_BCSet_Desc_Nodes` (lines 81–84)

```fortran
  TYPE, PUBLIC :: AP_BCSet_Desc_Nodes
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4), ALLOCATABLE :: nodeId(:)
  END TYPE AP_BCSet_Desc_Nodes
```

### `AP_BCSet_Desc_Dofs` (lines 86–89)

```fortran
  TYPE, PUBLIC :: AP_BCSet_Desc_Dofs
    INTEGER(i4) :: nDof = 0_i4
    INTEGER(i4), ALLOCATABLE :: dofId(:)
  END TYPE AP_BCSet_Desc_Dofs
```

### `AP_BCSet_Desc_Values` (lines 91–93)

```fortran
  TYPE, PUBLIC :: AP_BCSet_Desc_Values
    REAL(wp), ALLOCATABLE :: value(:)
  END TYPE AP_BCSet_Desc_Values
```

### `AP_BCSet_Desc` (lines 95–100)

```fortran
  TYPE, PUBLIC :: AP_BCSet_Desc
    TYPE(AP_BCSet_Desc_ID)     :: id
    TYPE(AP_BCSet_Desc_Nodes)  :: nodes
    TYPE(AP_BCSet_Desc_Dofs)   :: dofs
    TYPE(AP_BCSet_Desc_Values) :: values
  END TYPE AP_BCSet_Desc
```

### `AP_BCCtrl_State` (lines 102–105)

```fortran
  TYPE, PUBLIC :: AP_BCCtrl_State
    INTEGER(i4) :: nBCSets = 0_i4
    TYPE(AP_BCSet_Desc), ALLOCATABLE :: BCSets(:)
  END TYPE AP_BCCtrl_State
```

### `AP_OutCtrl_Desc` (lines 107–110)

```fortran
  TYPE, PUBLIC :: AP_OutCtrl_Desc
    INTEGER(i4) :: nField = 0_i4
    INTEGER(i4) :: nHist = 0_i4
  END TYPE AP_OutCtrl_Desc
```

### `AP_JobCtrl_Desc` (lines 112–115)

```fortran
  TYPE, PUBLIC :: AP_JobCtrl_Desc
    CHARACTER(len=64) :: jobName = ""
    CHARACTER(len=128) :: workDir = ""
  END TYPE AP_JobCtrl_Desc
```

### `AP_AppCtrl_Ctx` (lines 117–123)

```fortran
  TYPE, PUBLIC :: AP_AppCtrl_Ctx
    TYPE(AP_SolveCfg_Desc) :: SolveCfg
    TYPE(AP_LoadMgr_State) :: LoadMgr
    TYPE(AP_BCCtrl_State)  :: BCCtrl
    TYPE(AP_OutCtrl_Desc)  :: OutCtrl
    TYPE(AP_JobCtrl_Desc)  :: JobCtrl
  END TYPE AP_AppCtrl_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
