# `AP_InpScript_Reg.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Reg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Reg`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CmdReg` (lines 32–43)

```fortran
  TYPE, public :: CmdReg
    TYPE(CmdHandler), ALLOCATABLE :: handlers(:)
    INTEGER(i4) :: num_cmds = 0
    INTEGER(i4) :: max_cmds = MAX_REGISTRY
    INTEGER(i4) :: next_id  = 1
    LOGICAL     :: init     = .false.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reg
    PROCEDURE :: Find
    PROCEDURE :: Exec
  END TYPE CmdReg
```

### `Cmd_Init_In` (lines 48–50)

```fortran
  type, public :: Cmd_Init_In
    integer(i4), optional :: max_commands
  end type Cmd_Init_In
```

### `Cmd_Init_Out` (lines 52–54)

```fortran
  type, public :: Cmd_Init_Out
    type(ErrorStatusType) :: status
  end type Cmd_Init_Out
```

### `Cmd_Reg_In` (lines 56–60)

```fortran
  type, public :: Cmd_Reg_In
    character(len=16) :: name
    procedure(CmdHandlerProc), pointer :: handler
    character(len=128), optional :: description
  end type Cmd_Reg_In
```

### `Cmd_Reg_Out` (lines 62–64)

```fortran
  type, public :: Cmd_Reg_Out
    type(ErrorStatusType) :: status
  end type Cmd_Reg_Out
```

### `Cmd_Find_In` (lines 66–68)

```fortran
  type, public :: Cmd_Find_In
    character(len=16) :: name
  end type Cmd_Find_In
```

### `Cmd_Find_Out` (lines 70–73)

```fortran
  type, public :: Cmd_Find_Out
    integer(i4) :: idx
    type(ErrorStatusType) :: status
  end type Cmd_Find_Out
```

### `Cmd_RegisterDesc_In` (lines 75–78)

```fortran
  type, public :: Cmd_RegisterDesc_In
    type(CommandDesc) :: desc
    procedure(CmdHandlerProc), pointer :: handler
  end type Cmd_RegisterDesc_In
```

### `Cmd_RegisterDesc_Out` (lines 80–82)

```fortran
  type, public :: Cmd_RegisterDesc_Out
    type(ErrorStatusType) :: status
  end type Cmd_RegisterDesc_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Init_Structured` | 101 | `subroutine Cmd_Init_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_Reg_Structured` | 115 | `subroutine Cmd_Reg_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_Find_Structured` | 136 | `subroutine Cmd_Find_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_RegisterDesc_Structured` | 154 | `subroutine Cmd_RegisterDesc_Structured(domain, in, out)` |
| SUBROUTINE | `Reg_Init` | 175 | `subroutine Reg_Init(this, max_commands, status)` |
| SUBROUTINE | `Reg_Reg` | 202 | `subroutine Reg_Reg(this, name, handler, description, status)` |
| FUNCTION | `Reg_Find` | 261 | `function Reg_Find(this, name) result(idx)` |
| SUBROUTINE | `Reg_Exec` | 281 | `subroutine Reg_Exec(this, cmd, ctx, alias_mgr, status)` |
| SUBROUTINE | `Cmd_Init` | 317 | `subroutine Cmd_Init(domain, max_commands, status)` |
| SUBROUTINE | `Cmd_Reg` | 329 | `subroutine Cmd_Reg(domain, name, handler, description, status)` |
| FUNCTION | `Cmd_Find` | 345 | `function Cmd_Find(domain, name) result(idx)` |
| SUBROUTINE | `Cmd_RegisterDesc` | 357 | `subroutine Cmd_RegisterDesc(domain, desc, handler, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
