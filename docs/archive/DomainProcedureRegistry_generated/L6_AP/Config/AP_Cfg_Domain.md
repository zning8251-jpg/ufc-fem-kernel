# `AP_Cfg_Domain.f90`

- **Source**: `L6_AP/Config/AP_Cfg_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Cfg_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Cfg_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Cfg_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Config`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Config/AP_Cfg_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_CfgMgr_Cfg_Paths` (lines 20–23)

```fortran
  TYPE, PUBLIC :: AP_CfgMgr_Cfg_Paths
    CHARACTER(LEN=256) :: configFile = ''
    CHARACTER(LEN=256) :: workDir    = ''
  END TYPE AP_CfgMgr_Cfg_Paths
```

### `AP_CfgMgr_Cfg_AI` (lines 25–30)

```fortran
  TYPE, PUBLIC :: AP_CfgMgr_Cfg_AI
    LOGICAL :: aiEnabled = .FALSE.
    CHARACTER(LEN=128) :: aiModelName = ''
    CHARACTER(LEN=256) :: aiModelPath = ''
    REAL(wp) :: aiConfidenceThreshold = 0.8_wp
  END TYPE AP_CfgMgr_Cfg_AI
```

### `AP_CfgMgr_Cfg_Resources` (lines 32–37)

```fortran
  TYPE, PUBLIC :: AP_CfgMgr_Cfg_Resources
    LOGICAL :: resourceLimitsEnabled = .FALSE.
    REAL(wp) :: maxCpuTime  = 0.0_wp    ! 0 = unlimited
    REAL(wp) :: maxDiskIO   = 0.0_wp    ! 0 = unlimited
    INTEGER(i4) :: maxThreads = 0_i4   ! 0 = auto
  END TYPE AP_CfgMgr_Cfg_Resources
```

### `AP_CfgMgr_Cfg_Audit` (lines 39–42)

```fortran
  TYPE, PUBLIC :: AP_CfgMgr_Cfg_Audit
    LOGICAL :: auditLogging = .TRUE.
    CHARACTER(LEN=256) :: auditLogPath = ''
  END TYPE AP_CfgMgr_Cfg_Audit
```

### `AP_CfgMgr_State` (lines 44–49)

```fortran
  TYPE, PUBLIC :: AP_CfgMgr_State
    TYPE(AP_CfgMgr_Cfg_Paths) :: paths
    TYPE(AP_CfgMgr_Cfg_AI) :: ai
    TYPE(AP_CfgMgr_Cfg_Resources) :: resources
    TYPE(AP_CfgMgr_Cfg_Audit) :: audit
  END TYPE AP_CfgMgr_State
```

### `AP_Config_Ctrl` (lines 51–55)

```fortran
  TYPE, PUBLIC :: AP_Config_Ctrl
    LOGICAL :: strictValidation = .TRUE.
    LOGICAL :: mergeOnLoad      = .FALSE.
    INTEGER(i4) :: maxVersionHistory = 100_i4
  END TYPE AP_Config_Ctrl
```

### `AP_Config_LoadConfig_Arg` (lines 58–61)

```fortran
  TYPE, PUBLIC :: AP_Config_LoadConfig_Arg
    CHARACTER(LEN=256)    :: filename = ''  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_LoadConfig_Arg
```

### `AP_Config_SetResourceLimit_Arg` (lines 63–68)

```fortran
  TYPE, PUBLIC :: AP_Config_SetResourceLimit_Arg
    REAL(wp)    :: maxCpuTime = 0.0_wp  ! (IN)
    REAL(wp)    :: maxDiskIO  = 0.0_wp  ! (IN)
    INTEGER(i4) :: maxThreads = 0_i4   ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_SetResourceLimit_Arg
```

### `AP_Config_RegisterModelConfig_Arg` (lines 70–74)

```fortran
  TYPE, PUBLIC :: AP_Config_RegisterModelConfig_Arg
    CHARACTER(LEN=128) :: modelName = ''  ! (IN)
    CHARACTER(LEN=256) :: modelPath = ''  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_RegisterModelConfig_Arg
```

### `AP_Config_GetSummary_Arg` (lines 76–79)

```fortran
  TYPE, PUBLIC :: AP_Config_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ''  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_GetSummary_Arg
```

### `AP_Config_Domain` (lines 81–92)

```fortran
  TYPE, PUBLIC :: AP_Config_Domain
    TYPE(AP_CfgMgr_State) :: state
    TYPE(AP_Config_Ctrl)  :: ctrl
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: LoadConfig
    PROCEDURE :: SetResourceLimit
    PROCEDURE :: RegisterModelConfig
    PROCEDURE :: GetSummary
  END TYPE AP_Config_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Config_Domain_Finalize` | 96 | `SUBROUTINE AP_Config_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Config_Domain_Init` | 103 | `SUBROUTINE AP_Config_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Config_Domain_LoadConfig` | 116 | `SUBROUTINE AP_Config_Domain_LoadConfig(this, arg)` |
| SUBROUTINE | `AP_Config_LoadConfig_Impl` | 122 | `SUBROUTINE AP_Config_LoadConfig_Impl(this, filename, status)` |
| SUBROUTINE | `AP_Config_Domain_SetResourceLimit` | 149 | `SUBROUTINE AP_Config_Domain_SetResourceLimit(this, arg)` |
| SUBROUTINE | `AP_Config_SetResourceLimit_Impl` | 156 | `SUBROUTINE AP_Config_SetResourceLimit_Impl(this, maxCpuTime, maxDiskIO, maxThreads, status)` |
| SUBROUTINE | `AP_Config_Domain_RegisterModelConfig` | 182 | `SUBROUTINE AP_Config_Domain_RegisterModelConfig(this, arg)` |
| SUBROUTINE | `AP_Config_RegisterModelConfig_Impl` | 188 | `SUBROUTINE AP_Config_RegisterModelConfig_Impl(this, modelName, modelPath, status)` |
| SUBROUTINE | `AP_Config_Domain_GetSummary` | 211 | `SUBROUTINE AP_Config_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `AP_Config_GetSummary_Impl` | 217 | `SUBROUTINE AP_Config_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
