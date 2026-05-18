# `AP_InpScript_Valid.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Valid.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Valid`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Valid`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript`
- **第四段角色（四段式）**: `_Valid`
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Valid.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Cmd_Valid_In` (lines 24–27)

```fortran
  type, public :: Cmd_Valid_In
    type(Cmd) :: cmd    ! Command to validate
    type(*) :: spec     ! Validation specification (placeholder, assumed-shape)
  end type Cmd_Valid_In
```

### `Cmd_Valid_Out` (lines 29–31)

```fortran
  type, public :: Cmd_Valid_Out
    type(ErrorStatusType) :: status
  end type Cmd_Valid_Out
```

### `Cmd_FormatError_In` (lines 33–36)

```fortran
  type, public :: Cmd_FormatError_In
    type(Cmd) :: cmd                      ! Command that caused error
    character(len=256) :: base_message    ! Base error message
  end type Cmd_FormatError_In
```

### `Cmd_FormatError_Out` (lines 38–40)

```fortran
  type, public :: Cmd_FormatError_Out
    character(len=512) :: formatted_message  ! Formatted error message
  end type Cmd_FormatError_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Valid_Structured` | 55 | `subroutine Cmd_Valid_Structured(in, out)` |
| SUBROUTINE | `Cmd_FormatError_Structured` | 80 | `subroutine Cmd_FormatError_Structured(in, out)` |
| SUBROUTINE | `Cmd_Valid` | 107 | `subroutine Cmd_Valid(cmd, spec, status)` |
| SUBROUTINE | `Cmd_FormatError` | 117 | `subroutine Cmd_FormatError(cmd, base_message, formatted_messa)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
