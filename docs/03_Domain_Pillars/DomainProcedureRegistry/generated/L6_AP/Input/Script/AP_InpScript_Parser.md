# `AP_InpScript_Parser.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Parser.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Parser`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Parser`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_Parser`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Parser.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CmdParser` (lines 32–37)

```fortran
  TYPE, public :: CmdParser
    LOGICAL               :: case_sensitive = .false.
    LOGICAL               :: strip_comments = .true.
    CHARACTER(len=1)      :: comment_char   = '!'
    LOGICAL               :: init           = .false.
  END TYPE CmdParser
```

### `Cmd_ParseLine_In` (lines 42–44)

```fortran
  type, public :: Cmd_ParseLine_In
    character(len=MAX_LINE_LEN) :: line
  end type Cmd_ParseLine_In
```

### `Cmd_ParseLine_Out` (lines 46–49)

```fortran
  type, public :: Cmd_ParseLine_Out
    type(Cmd) :: cmd
    type(ErrorStatusType) :: status
  end type Cmd_ParseLine_Out
```

### `Cmd_ParseFile_In` (lines 51–53)

```fortran
  type, public :: Cmd_ParseFile_In
    character(len=256) :: filename
  end type Cmd_ParseFile_In
```

### `Cmd_ParseFile_Out` (lines 55–58)

```fortran
  type, public :: Cmd_ParseFile_Out
    type(CmdList) :: cmd_list
    type(ErrorStatusType) :: status
  end type Cmd_ParseFile_Out
```

### `Cmd_ParseString_In` (lines 60–62)

```fortran
  type, public :: Cmd_ParseString_In
    character(len=MAX_LINE_LEN) :: str
  end type Cmd_ParseString_In
```

### `Cmd_ParseString_Out` (lines 64–67)

```fortran
  type, public :: Cmd_ParseString_Out
    type(CmdList) :: cmd_list
    type(ErrorStatusType) :: status
  end type Cmd_ParseString_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_ParseLine_Structured` | 93 | `subroutine Cmd_ParseLine_Structured(in, out)` |
| SUBROUTINE | `Cmd_ParseFile_Structured` | 255 | `subroutine Cmd_ParseFile_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_ParseString_Structured` | 347 | `subroutine Cmd_ParseString_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_ExpandMacros` | 465 | `subroutine Cmd_ExpandMacros(cmd_list, status)` |
| SUBROUTINE | `Cmd_ParseKeyValue` | 475 | `subroutine Cmd_ParseKeyValue(param_str, key, value, found, status)` |
| SUBROUTINE | `Cmd_ParseArray` | 535 | `subroutine Cmd_ParseArray(param_str, array, n_elements, status)` |
| SUBROUTINE | `Cmd_ParseLine` | 600 | `subroutine Cmd_ParseLine(line, cmd, status)` |
| SUBROUTINE | `Cmd_ParseFile` | 613 | `subroutine Cmd_ParseFile(domain, filename, cmd_list, status)` |
| SUBROUTINE | `Cmd_ParseString` | 627 | `subroutine Cmd_ParseString(domain, str, cmd_list, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
