# `AP_Base_Mgr.f90`

- **Source**: `L6_AP/AP_Base_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Base_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Base_Mgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Base`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `*(层直下，无中间子目录)*`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/_root/AP_Base_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Base_State` (lines 34–38)

```fortran
  TYPE, PUBLIC :: AP_Base_State
    LOGICAL     :: licenseValid    = .FALSE.
    REAL(wp)    :: startupTime     = 0.0_wp   ! wall-clock at app start
    INTEGER(i4) :: exitCode        = 0_i4
  END TYPE AP_Base_State
```

### `AP_Base_Ctrl` (lines 40–45)

```fortran
  TYPE, PUBLIC :: AP_Base_Ctrl
    CHARACTER(LEN=512) :: configFilePath  = ' '
    CHARACTER(LEN=512) :: licenseFilePath = ' '
    CHARACTER(LEN=512) :: workDir         = '.'
    LOGICAL            :: debugMode      = .FALSE.
  END TYPE AP_Base_Ctrl
```

### `AP_Base_Domain` (lines 47–57)

```fortran
  TYPE, PUBLIC :: AP_Base_Domain
    TYPE(AP_Base_State) :: state
    TYPE(AP_Base_Ctrl)  :: ctrl
    LOGICAL             :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => AP_Base_Domain_Init
    PROCEDURE :: Finalize => AP_Base_Domain_Finalize
    PROCEDURE :: ValidateLicense => AP_Base_Domain_ValidateLicense
    PROCEDURE :: LoadConfig => AP_Base_Domain_LoadConfig
    PROCEDURE :: GetSummary => AP_Base_Domain_GetSummary
  END TYPE AP_Base_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Base_Domain_Finalize` | 61 | `SUBROUTINE AP_Base_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Base_Domain_Init` | 68 | `SUBROUTINE AP_Base_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Base_Domain_ValidateLicense` | 85 | `SUBROUTINE AP_Base_Domain_ValidateLicense(this, licensePath, isValid, status)` |
| SUBROUTINE | `AP_Base_Domain_LoadConfig` | 125 | `SUBROUTINE AP_Base_Domain_LoadConfig(this, configPath, status)` |
| SUBROUTINE | `AP_Base_Domain_GetSummary` | 156 | `SUBROUTINE AP_Base_Domain_GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
