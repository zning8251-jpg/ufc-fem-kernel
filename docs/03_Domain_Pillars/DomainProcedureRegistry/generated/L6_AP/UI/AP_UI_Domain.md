# `AP_UI_Domain.f90`

- **Source**: `L6_AP/UI/AP_UI_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_UI_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_UI_State` (lines 27–33)

```fortran
  TYPE, PUBLIC :: AP_UI_State
    INTEGER(i4) :: mode              = AP_UI_BATCH
    INTEGER(i4) :: nRegisteredCmds   = 0_i4
    INTEGER(i4) :: nExecutedCmds     = 0_i4
    INTEGER(i4) :: nFailedCmds       = 0_i4
    LOGICAL     :: sessionActive     = .FALSE.
  END TYPE AP_UI_State
```

### `AP_UI_Ctrl` (lines 35–41)

```fortran
  TYPE, PUBLIC :: AP_UI_Ctrl
    INTEGER(i4) :: defaultMode    = AP_UI_BATCH
    LOGICAL     :: echoCommands   = .FALSE.
    LOGICAL     :: colorOutput    = .FALSE.
    LOGICAL     :: progressBar    = .TRUE.
    INTEGER(i4) :: historySize    = 100_i4
  END TYPE AP_UI_Ctrl
```

### `AP_UI_RegisterCommand_Arg` (lines 44–47)

```fortran
  TYPE, PUBLIC :: AP_UI_RegisterCommand_Arg
    CHARACTER(LEN=128)    :: cmdName = ""  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_UI_RegisterCommand_Arg
```

### `AP_UI_ExecuteCommand_Arg` (lines 49–52)

```fortran
  TYPE, PUBLIC :: AP_UI_ExecuteCommand_Arg
    CHARACTER(LEN=512)    :: cmdLine = ""  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_UI_ExecuteCommand_Arg
```

### `AP_UI_GetSummary_Arg` (lines 54–57)

```fortran
  TYPE, PUBLIC :: AP_UI_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_UI_GetSummary_Arg
```

### `AP_UIDomain` (lines 59–78)

```fortran
  TYPE, PUBLIC :: AP_UIDomain
    TYPE(AP_UI_State) :: state
    TYPE(AP_UI_Ctrl)  :: ctrl
    ! Flat domain storage (index tree + flat)
    TYPE(CommandHistoryEntry), ALLOCATABLE :: command_history(:)
    TYPE(UITreeNodeEntry),     ALLOCATABLE :: ui_tree_nodes(:)
    INTEGER(i4) :: n_history = 0_i4
    INTEGER(i4) :: n_nodes   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterCommand
    PROCEDURE :: ExecuteCommand
    PROCEDURE :: GetSummary
    PROCEDURE :: AddCommandHistory
    PROCEDURE :: AddTreeNode
    PROCEDURE :: GetHistoryById
    PROCEDURE :: GetNodeById
  END TYPE AP_UIDomain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_UI_Domain_Finalize` | 82 | `SUBROUTINE AP_UI_Domain_Finalize(this)` |
| SUBROUTINE | `AP_UI_Domain_Init` | 100 | `SUBROUTINE AP_UI_Domain_Init(this, status)` |
| SUBROUTINE | `AP_UI_Domain_RegisterCommand` | 113 | `SUBROUTINE AP_UI_Domain_RegisterCommand(this, arg)` |
| SUBROUTINE | `AP_UI_RegisterCommand_Impl` | 119 | `SUBROUTINE AP_UI_RegisterCommand_Impl(this, cmdName, status)` |
| SUBROUTINE | `AP_UI_Domain_ExecuteCommand` | 152 | `SUBROUTINE AP_UI_Domain_ExecuteCommand(this, arg)` |
| SUBROUTINE | `AP_UI_ExecuteCommand_Impl` | 158 | `SUBROUTINE AP_UI_ExecuteCommand_Impl(this, cmdLine, status)` |
| SUBROUTINE | `AP_UI_Domain_GetSummary` | 199 | `SUBROUTINE AP_UI_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `AP_UI_GetSummary_Impl` | 205 | `SUBROUTINE AP_UI_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `AP_UI_Domain_AddCommandHistory` | 235 | `SUBROUTINE AP_UI_Domain_AddCommandHistory(this, entry, history_id, status)` |
| SUBROUTINE | `AP_UI_Domain_AddTreeNode` | 274 | `SUBROUTINE AP_UI_Domain_AddTreeNode(this, entry, node_id, status)` |
| SUBROUTINE | `AP_UI_Domain_GetHistoryById` | 313 | `SUBROUTINE AP_UI_Domain_GetHistoryById(this, idx, entry, found)` |
| SUBROUTINE | `AP_UI_Domain_GetNodeById` | 330 | `SUBROUTINE AP_UI_Domain_GetNodeById(this, idx, entry, found)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
