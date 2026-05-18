# `NM_Base_Core.f90`

- **Source**: `L2_NM/Base/NM_Base_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Base_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Base_Core`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Base`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Base/NM_Base_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_Base_Domain` (lines 61–70)

```fortran
  TYPE, PUBLIC :: NM_Base_Domain
    INTEGER(i4) :: verboseLevel = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init              => NM_Base_Init
    PROCEDURE :: Finalize          => NM_Base_Finalize
    PROCEDURE :: SetVerboseLevel   => NM_Base_SetVerbose
    PROCEDURE :: GetErrorCodeDesc  => NM_Base_GetErrorCodeDesc
    PROCEDURE :: GetSummary        => NM_Base_GetSummary
  END TYPE NM_Base_Domain
```

### `NM_Base_Finalize_Arg` (lines 79–82)

```fortran
  TYPE :: NM_Base_Finalize_Arg
    ! [IN] this     - Domain instance to finalize
    CLASS(NM_Base_Domain), POINTER :: this
  END TYPE NM_Base_Finalize_Arg
```

### `NM_Base_Init_Arg` (lines 87–92)

```fortran
  TYPE :: NM_Base_Init_Arg
    ! [IN]  this     - Domain instance to initialize
    ! [OUT] status   - Error status (IF_STATUS_OK on success)
    CLASS(NM_Base_Domain), POINTER :: this
    TYPE(ErrorStatusType)         :: status
  END TYPE NM_Base_Init_Arg
```

### `NM_Base_SetVerbose_Arg` (lines 97–104)

```fortran
  TYPE :: NM_Base_SetVerbose_Arg
    ! [IN]  this   - Domain instance
    ! [IN]  level  - Verbose level (0-3)
    ! [OUT] status - Error status
    CLASS(NM_Base_Domain), POINTER :: this
    INTEGER(i4) :: level
    TYPE(ErrorStatusType) :: status
  END TYPE NM_Base_SetVerbose_Arg
```

### `NM_Base_GetErrDesc_Arg` (lines 109–116)

```fortran
  TYPE :: NM_Base_GetErrDesc_Arg
    ! [IN]  this        - Domain instance
    ! [IN]  errorCode   - Error code to describe
    ! [OUT] description - Description string (LEN=128)
    CLASS(NM_Base_Domain), POINTER :: this
    INTEGER(i4)                  :: errorCode
    CHARACTER(LEN=128)           :: description
  END TYPE NM_Base_GetErrDesc_Arg
```

### `NM_Base_GetSummary_Arg` (lines 121–128)

```fortran
  TYPE :: NM_Base_GetSummary_Arg
    ! [IN]  this     - Domain instance
    ! [OUT] summary  - Summary string (LEN=512)
    ! [OUT] status   - Error status
    CLASS(NM_Base_Domain), POINTER :: this
    CHARACTER(LEN=512)           :: summary
    TYPE(ErrorStatusType)       :: status
  END TYPE NM_Base_GetSummary_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Base_Finalize` | 135 | `SUBROUTINE NM_Base_Finalize(this)` |
| SUBROUTINE | `NM_Base_Finalize_Proc` | 147 | `SUBROUTINE NM_Base_Finalize_Proc(arg)` |
| SUBROUTINE | `NM_Base_Init` | 159 | `SUBROUTINE NM_Base_Init(this, status)` |
| SUBROUTINE | `NM_Base_Init_Proc` | 174 | `SUBROUTINE NM_Base_Init_Proc(arg)` |
| SUBROUTINE | `NM_Base_SetVerbose` | 187 | `SUBROUTINE NM_Base_SetVerbose(this, level, status)` |
| SUBROUTINE | `NM_Base_SetVerbose_Proc` | 211 | `SUBROUTINE NM_Base_SetVerbose_Proc(arg)` |
| FUNCTION | `NM_Base_GetErrorCodeDesc` | 231 | `FUNCTION NM_Base_GetErrorCodeDesc(this, errorCode) RESULT(description)` |
| SUBROUTINE | `NM_Base_GetErrorCodeDesc_Proc` | 270 | `SUBROUTINE NM_Base_GetErrorCodeDesc_Proc(arg)` |
| SUBROUTINE | `NM_Base_GetSummary` | 305 | `SUBROUTINE NM_Base_GetSummary(this, summary, status)` |
| SUBROUTINE | `NM_Base_GetSummary_Proc` | 331 | `SUBROUTINE NM_Base_GetSummary_Proc(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
