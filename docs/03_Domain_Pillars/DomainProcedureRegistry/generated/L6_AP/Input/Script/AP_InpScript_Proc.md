# `AP_InpScript_Proc.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Proc.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Proc`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CmdProcMgr` (lines 35–48)

```fortran
  TYPE, PUBLIC :: CmdProcMgr
    TYPE(Proc), ALLOCATABLE :: procs(:)
    INTEGER(i4) :: num_procs = 0
    INTEGER(i4) :: max_procs = 100
    CHARACTER(LEN=256) :: proc_dir = './procedures'
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Define
    PROCEDURE :: Load
    PROCEDURE :: Save
    PROCEDURE :: Exec
    PROCEDURE :: Find
  END TYPE CmdProcMgr
```

### `Cmd_ProcDefine_In` (lines 53–56)

```fortran
  TYPE, PUBLIC :: Cmd_ProcDefine_In
    CHARACTER(LEN=32) :: name
    TYPE(CmdList) :: cmd_list
  END TYPE Cmd_ProcDefine_In
```

### `Cmd_ProcDefine_Out` (lines 58–60)

```fortran
  TYPE, PUBLIC :: Cmd_ProcDefine_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcDefine_Out
```

### `Cmd_ProcLoad_In` (lines 62–64)

```fortran
  TYPE, PUBLIC :: Cmd_ProcLoad_In
    CHARACTER(LEN=256) :: filename
  END TYPE Cmd_ProcLoad_In
```

### `Cmd_ProcLoad_Out` (lines 66–68)

```fortran
  TYPE, PUBLIC :: Cmd_ProcLoad_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcLoad_Out
```

### `Cmd_ProcSave_In` (lines 70–73)

```fortran
  TYPE, PUBLIC :: Cmd_ProcSave_In
    CHARACTER(LEN=32) :: name
    CHARACTER(LEN=256) :: filename
  END TYPE Cmd_ProcSave_In
```

### `Cmd_ProcSave_Out` (lines 75–77)

```fortran
  TYPE, PUBLIC :: Cmd_ProcSave_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcSave_Out
```

### `Cmd_ProcExec_In` (lines 79–83)

```fortran
  TYPE, PUBLIC :: Cmd_ProcExec_In
    CHARACTER(LEN=32) :: name
    REAL(wp), ALLOCATABLE :: param_values(:)
    TYPE(CmdCtx) :: ctx
  END TYPE Cmd_ProcExec_In
```

### `Cmd_ProcExec_Out` (lines 85–87)

```fortran
  TYPE, PUBLIC :: Cmd_ProcExec_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcExec_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `GetCmdByIndex_Proc` | 26 | `SUBROUTINE GetCmdByIndex_Proc(cmd_list, idx, cmd, found)` |
| SUBROUTINE | `Proc_Init` | 100 | `SUBROUTINE Proc_Init(this, max_procs, status)` |
| SUBROUTINE | `Proc_Define` | 121 | `SUBROUTINE Proc_Define(this, name, cmd_list, status, get_cmd)` |
| SUBROUTINE | `Proc_Load` | 177 | `SUBROUTINE Proc_Load(this, filename, status)` |
| SUBROUTINE | `Proc_Save` | 274 | `SUBROUTINE Proc_Save(this, name, filename, status)` |
| SUBROUTINE | `Proc_Exec` | 320 | `SUBROUTINE Proc_Exec(this, name, param_values, ctx, status)` |
| FUNCTION | `Proc_Find` | 385 | `FUNCTION Proc_Find(this, name) RESULT(idx)` |
| SUBROUTINE | `Cmd_ProcDefine_Structured` | 405 | `SUBROUTINE Cmd_ProcDefine_Structured(in, out)` |
| SUBROUTINE | `Cmd_ProcLoad_Structured` | 413 | `SUBROUTINE Cmd_ProcLoad_Structured(in, out)` |
| SUBROUTINE | `Cmd_ProcSave_Structured` | 421 | `SUBROUTINE Cmd_ProcSave_Structured(in, out)` |
| SUBROUTINE | `Cmd_ProcExec_Structured` | 429 | `SUBROUTINE Cmd_ProcExec_Structured(in, out)` |
| SUBROUTINE | `Cmd_ProcDefine` | 444 | `SUBROUTINE Cmd_ProcDefine(name, cmd_list, status)` |
| SUBROUTINE | `Cmd_ProcLoad` | 458 | `SUBROUTINE Cmd_ProcLoad(filename, status)` |
| SUBROUTINE | `Cmd_ProcSave` | 470 | `SUBROUTINE Cmd_ProcSave(name, filename, status)` |
| SUBROUTINE | `Cmd_ProcExec` | 484 | `SUBROUTINE Cmd_ProcExec(name, param_values, ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
