# `AP_Inp_Def.f90`

- **Source**: `L6_AP/Input/AP_Inp_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Input`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/AP_Inp_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ParsedKeywordEntry` (lines 48–54)

```fortran
  TYPE, PUBLIC :: ParsedKeywordEntry
    INTEGER(i4) :: keyword_id    = 0_i4   ! Index into MD_KWReg or local id
    INTEGER(i4) :: line_number   = 0_i4
    CHARACTER(LEN=32) :: name    = ' '
    INTEGER(i4) :: category      = 0_i4   ! KW_CAT_* from L3
    LOGICAL     :: has_data      = .FALSE.
  END TYPE ParsedKeywordEntry
```

### `ParsedCommandEntry` (lines 62–72)

```fortran
  TYPE, PUBLIC :: ParsedCommandEntry
    INTEGER(i4) :: id            = 0_i4   ! = Cmd%cfg%id  (formerly cmd_id)
    INTEGER(i4) :: cmd_id        = 0_i4   ! @deprecated alias for id
    INTEGER(i4) :: keyword_idx   = 0_i4   ! Index into parsed_keywords(:)
    INTEGER(i4) :: line          = 0_i4   ! = Cmd%line (formerly line_number)
    INTEGER(i4) :: line_number   = 0_i4   ! @deprecated alias for line
    CHARACTER(LEN=16)  :: name     = ' '
    CHARACTER(LEN=64)  :: opt      = ' '
    REAL(wp)    :: params(3)      = 0.0_wp
    CHARACTER(LEN=256) :: param_str = ' '
  END TYPE ParsedCommandEntry
```

### `AP_Inp_AddKW_Arg` (lines 102–108)

```fortran
  TYPE :: AP_Inp_AddKW_Arg
    INTEGER(i4)       :: keyword_id  = 0_i4
    INTEGER(i4)       :: line_number = 0_i4
    CHARACTER(LEN=32) :: name        = ' '
    INTEGER(i4)       :: category    = 0_i4
    LOGICAL           :: has_data    = .FALSE.
  END TYPE AP_Inp_AddKW_Arg
```

### `AP_Inp_AddCmd_Arg` (lines 114–122)

```fortran
  TYPE :: AP_Inp_AddCmd_Arg
    INTEGER(i4)        :: cmd_id      = 0_i4
    INTEGER(i4)        :: keyword_idx = 0_i4
    INTEGER(i4)        :: line_number = 0_i4
    CHARACTER(LEN=16)  :: name        = ' '
    CHARACTER(LEN=64)  :: opt         = ' '
    REAL(wp)           :: params(3)   = 0.0_wp
    CHARACTER(LEN=256) :: param_str   = ' '
  END TYPE AP_Inp_AddCmd_Arg
```

### `Cmd` (lines 127–134)

```fortran
  TYPE :: Cmd
    CHARACTER(len=16) :: name = ''        ! Command name
    INTEGER(i4)       :: id = 0           ! Command ID
    CHARACTER(len=64) :: opt = ''         ! Option string
    REAL(wp)          :: params(3) = 0.0_wp ! Numeric parameters
    CHARACTER(len=256):: param_str = ''   ! String parameters
    INTEGER(i4)       :: line = 0         ! Line number
  END TYPE Cmd
```

### `CmdMacroDef` (lines 141–147)

```fortran
  TYPE :: CmdMacroDef
    CHARACTER(len=32)  :: name = ''
    INTEGER(i4)        :: num_params = 0
    CHARACTER(len=16)  :: param_names(8) = ''
    CHARACTER(len=256) :: body = ''          ! Raw macro body or reference key
    LOGICAL            :: defined = .false.
  END TYPE CmdMacroDef
```

### `CmdMacroCtx` (lines 152–157)

```fortran
  TYPE :: CmdMacroCtx
    INTEGER(i4) :: call_depth    = 0
    INTEGER(i4) :: max_depth     = 16
    INTEGER(i4) :: current_macro = 0
    INTEGER(i4) :: current_line  = 0
  END TYPE CmdMacroCtx
```

### `CmdCtx` (lines 162–203)

```fortran
  TYPE :: CmdCtx
    ! Model references (use generic pointer with deferred type)
    ! Note: Using CLASS(*) for polymorphic pointer requires ALLOCATABLE
    ! For now, use a simple workaround with generic storage
    INTEGER(i4) :: model_ptr = 0_i4  ! Placeholder for model reference ID
    INTEGER(i4) :: solver_ptr = 0_i4 ! Placeholder for solver reference ID
    INTEGER(i4) :: job_ptr = 0_i4    ! Placeholder for job reference ID
    INTEGER(i4) :: current_part_ptr = 0_i4 ! Placeholder for part reference ID

    ! State
    INTEGER(i4) :: step_id = 0
    INTEGER(i4) :: inc_id = 0
    INTEGER(i4) :: iter_id = 0

    ! Mode
    LOGICAL :: interactive = .false.
    LOGICAL :: verbose = .true.

    ! Ctrl flow stacks
    INTEGER(i4), ALLOCATABLE :: loop_stack(:)
    INTEGER(i4), ALLOCATABLE :: loop_max_stack(:)
    INTEGER(i4), ALLOCATABLE :: loop_start_stac(:)
    INTEGER(i4) :: loop_depth = 0
    INTEGER(i4), ALLOCATABLE :: if_stack(:)
    INTEGER(i4) :: if_depth = 0
    LOGICAL, ALLOCATABLE :: if_cond_stack(:)
    LOGICAL, ALLOCATABLE :: else_exec_stack(:)
    INTEGER(i4) :: break_level = 0
    INTEGER(i4) :: continue_level = 0
    INTEGER(i4) :: jump_target = 0

    ! Variables (unified memory: pointer + id)
    REAL(wp), POINTER :: vars(:) => null()
    INTEGER(i4) :: vars_id = -1
    CHARACTER(len=32), ALLOCATABLE :: var_names(:)

    ! Macro execution context (5.2 skeleton)
    TYPE(CmdMacroCtx) :: macro

    ! Error
    TYPE(ErrorStatusType) :: last_error
  END TYPE CmdCtx
```

### `CmdHandler` (lines 210–217)

```fortran
  TYPE :: CmdHandler
    CHARACTER(len=16) :: name = ''
    INTEGER(i4) :: id = 0
    CHARACTER(len=128) :: desc = ''
    LOGICAL :: registered = .false.
    ! Note: Actual handler procedure is stored in AP_Cmd_Domain%handlers
    ! and invoked via command ID lookup
  END TYPE CmdHandler
```

### `HistoryEntry` (lines 222–226)

```fortran
  TYPE :: HistoryEntry
    TYPE(Cmd) :: cmd
    INTEGER(i4) :: timestamp = 0
    CHARACTER(len=256) :: source = ''
  END TYPE HistoryEntry
```

### `CommandDesc` (lines 231–241)

```fortran
  TYPE :: CommandDesc
    CHARACTER(len=16)  :: name = ''
    CHARACTER(len=256) :: category = ''
    CHARACTER(len=256) :: description = ''
    CHARACTER(len=256) :: syntax = ''
    CHARACTER(len=256) :: params = ''         ! Short param summary (display)
    CHARACTER(len=512) :: parameters = ''    ! Full parameter specification
    CHARACTER(len=512) :: examples = ''     ! Usage examples
    LOGICAL            :: is_hidden       = .false.
    LOGICAL            :: is_experimental = .false.
  END TYPE CommandDesc
```

### `CommandLogEntry` (lines 246–251)

```fortran
  TYPE :: CommandLogEntry
    TYPE(Cmd)          :: cmd
    CHARACTER(len=64)  :: source   = ''
    CHARACTER(len=64)  :: user     = ''
    INTEGER(i4)        :: timestamp = 0
  END TYPE CommandLogEntry
```

### `Proc` (lines 256–262)

```fortran
  TYPE :: Proc
    CHARACTER(len=32) :: name = ''
    CHARACTER(len=16) :: params(3) = ''
    TYPE(Cmd), ALLOCATABLE :: cmds(:)
    INTEGER(i4) :: num_cmds = 0
    LOGICAL :: defined = .false.
  END TYPE Proc
```

### `CmdList` (lines 267–272)

```fortran
  TYPE :: CmdList
    INTEGER(i4), ALLOCATABLE :: cmd_ids(:)   ! Indices into g_cmd_domain%commands
    INTEGER(i4) :: num_cmds = 0
    INTEGER(i4) :: idx = 0
    LOGICAL :: init = .false.
  END TYPE CmdList
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
