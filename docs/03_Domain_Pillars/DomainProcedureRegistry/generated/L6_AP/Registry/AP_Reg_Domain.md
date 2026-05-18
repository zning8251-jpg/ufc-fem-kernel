# `AP_Reg_Domain.f90`

- **Source**: `L6_AP/Registry/AP_Reg_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Reg_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Reg_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Reg_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Registry/AP_Reg_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Registry_ModelEntry` (lines 18–25)

```fortran
  TYPE, PUBLIC :: AP_Registry_ModelEntry
    INTEGER(i8)     :: modelId   = 0_i8
    CHARACTER(LEN=128) :: modelName = ''
    CHARACTER(LEN=64)  :: modelType = ''
    CHARACTER(LEN=32)  :: version   = '1.0.0'
    LOGICAL            :: active    = .TRUE.
    REAL(wp)           :: lastScore = 0.0_wp
  END TYPE AP_Registry_ModelEntry
```

### `AP_Registry_State` (lines 27–31)

```fortran
  TYPE, PUBLIC :: AP_Registry_State
    INTEGER(i4) :: nModels     = 0_i4
    INTEGER(i4) :: nAuditLogs  = 0_i4
    LOGICAL     :: auditEnabled = .TRUE.
  END TYPE AP_Registry_State
```

### `AP_Registry_Ctrl` (lines 33–37)

```fortran
  TYPE, PUBLIC :: AP_Registry_Ctrl
    LOGICAL     :: degradationCheck = .TRUE.
    REAL(wp)    :: degradationThreshold = 0.1_wp
    INTEGER(i4) :: maxVersionHistory    = 100_i4
  END TYPE AP_Registry_Ctrl
```

### `AP_Registry_RegisterModel_Arg` (lines 40–45)

```fortran
  TYPE, PUBLIC :: AP_Registry_RegisterModel_Arg
    CHARACTER(LEN=128) :: modelName = ''  ! (IN)
    CHARACTER(LEN=64)  :: modelType = ''  ! (IN)
    INTEGER(i8)     :: modelId   = 0_i8  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Registry_RegisterModel_Arg
```

### `AP_Registry_CheckDegradation_Arg` (lines 47–51)

```fortran
  TYPE, PUBLIC :: AP_Registry_CheckDegradation_Arg
    INTEGER(i8) :: modelId     = 0_i8  ! (IN)
    LOGICAL        :: isDegraded  = .FALSE.  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Registry_CheckDegradation_Arg
```

### `AP_Registry_GetSummary_Arg` (lines 53–56)

```fortran
  TYPE, PUBLIC :: AP_Registry_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ''  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Registry_GetSummary_Arg
```

### `AP_Registry_Domain` (lines 58–69)

```fortran
  TYPE, PUBLIC :: AP_Registry_Domain
    TYPE(AP_Registry_State) :: state
    TYPE(AP_Registry_Ctrl)  :: ctrl
    TYPE(AP_Registry_ModelEntry) :: models(AP_REG_MAX_MODELS)
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterModel
    PROCEDURE :: CheckDegradation
    PROCEDURE :: GetSummary
  END TYPE AP_Registry_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Registry_Domain_Finalize` | 73 | `SUBROUTINE AP_Registry_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Registry_Domain_Init` | 80 | `SUBROUTINE AP_Registry_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Registry_Domain_RegisterModel` | 93 | `SUBROUTINE AP_Registry_Domain_RegisterModel(this, arg)` |
| SUBROUTINE | `AP_Registry_RegisterModel_Impl` | 100 | `SUBROUTINE AP_Registry_RegisterModel_Impl(this, modelName, modelType, modelId, status)` |
| SUBROUTINE | `AP_Registry_Domain_CheckDegradation` | 138 | `SUBROUTINE AP_Registry_Domain_CheckDegradation(this, arg)` |
| SUBROUTINE | `AP_Registry_CheckDegradation_Impl` | 144 | `SUBROUTINE AP_Registry_CheckDegradation_Impl(this, modelId, isDegraded, status)` |
| SUBROUTINE | `AP_Registry_Domain_GetSummary` | 170 | `SUBROUTINE AP_Registry_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `AP_Registry_GetSummary_Impl` | 176 | `SUBROUTINE AP_Registry_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
