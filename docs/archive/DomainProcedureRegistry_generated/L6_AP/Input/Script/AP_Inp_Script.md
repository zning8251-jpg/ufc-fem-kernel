# `AP_Inp_Script.f90`

- **Source**: `L6_AP/Input/Script/AP_Inp_Script.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_Script`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Script`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Script`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_Inp_Script.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Cmd_HistoryAdd_In` (lines 142–145)

```fortran
  type, public :: Cmd_HistoryAdd_In
    type(Cmd)                   :: cmd
    character(len=256), optional :: source
  end type Cmd_HistoryAdd_In
```

### `Cmd_HistoryAdd_Out` (lines 146–148)

```fortran
  type, public :: Cmd_HistoryAdd_Out
    type(ErrorStatusType) :: status
  end type Cmd_HistoryAdd_Out
```

### `Cmd_HistoryGet_In` (lines 150–152)

```fortran
  type, public :: Cmd_HistoryGet_In
    integer(i4) :: index
  end type Cmd_HistoryGet_In
```

### `Cmd_HistoryGet_Out` (lines 153–156)

```fortran
  type, public :: Cmd_HistoryGet_Out
    type(Cmd) :: cmd
    type(ErrorStatusType) :: status
  end type Cmd_HistoryGet_Out
```

### `Cmd_HistoryClear_Out` (lines 158–160)

```fortran
  type, public :: Cmd_HistoryClear_Out
    type(ErrorStatusType) :: status
  end type Cmd_HistoryClear_Out
```

### `Cmd_HistoryInit_In` (lines 162–164)

```fortran
  type, public :: Cmd_HistoryInit_In
    integer(i4), optional :: max_entries
  end type Cmd_HistoryInit_In
```

### `Cmd_HistoryInit_Out` (lines 165–167)

```fortran
  type, public :: Cmd_HistoryInit_Out
    type(ErrorStatusType) :: status
  end type Cmd_HistoryInit_Out
```

### `Cmd_LabelRegister_In` (lines 170–172)

```fortran
  type, public :: Cmd_LabelRegister_In
    type(CmdList) :: cmd_list
  end type Cmd_LabelRegister_In
```

### `Cmd_LabelRegister_Out` (lines 173–175)

```fortran
  type, public :: Cmd_LabelRegister_Out
    type(ErrorStatusType) :: status
  end type Cmd_LabelRegister_Out
```

### `Cmd_LabelResolve_In` (lines 176–178)

```fortran
  type, public :: Cmd_LabelResolve_In
    character(len=32) :: name
  end type Cmd_LabelResolve_In
```

### `Cmd_LabelResolve_Out` (lines 179–182)

```fortran
  type, public :: Cmd_LabelResolve_Out
    integer(i4) :: idx
    type(ErrorStatusType) :: status
  end type Cmd_LabelResolve_Out
```

### `Cmd_Exec_In` (lines 185–187)

```fortran
  type, public :: Cmd_Exec_In
    type(Cmd) :: cmd
  end type Cmd_Exec_In
```

### `Cmd_Exec_Out` (lines 188–190)

```fortran
  type, public :: Cmd_Exec_Out
    type(ErrorStatusType) :: status
  end type Cmd_Exec_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Exec` | 208 | `subroutine Cmd_Exec(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_HistoryInit` | 239 | `subroutine Cmd_HistoryInit(max_entries, status)` |
| SUBROUTINE | `Cmd_HistoryAdd` | 247 | `subroutine Cmd_HistoryAdd(cmd, source, status)` |
| SUBROUTINE | `Cmd_HistoryAddEntry` | 260 | `subroutine Cmd_HistoryAddEntry(entry, status)` |
| SUBROUTINE | `Cmd_HistoryGet` | 266 | `subroutine Cmd_HistoryGet(index, cmd, status)` |
| SUBROUTINE | `Cmd_HistoryClear` | 286 | `subroutine Cmd_HistoryClear(status)` |
| SUBROUTINE | `Cmd_LabelRegister` | 298 | `subroutine Cmd_LabelRegister(cmd_list, status)` |
| FUNCTION | `Cmd_LabelResolve` | 309 | `function Cmd_LabelResolve(name) result(idx)` |
| SUBROUTINE | `LabelGetCmd` | 316 | `subroutine LabelGetCmd(cmd_list, i, cmd, found)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
