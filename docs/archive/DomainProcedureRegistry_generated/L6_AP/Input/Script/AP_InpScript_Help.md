# `AP_InpScript_Help.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Help.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_InpScript_Help`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Help`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_Help`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Help.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Cmd_HelpShow_In` (lines 25–27)

```fortran
  type, public :: Cmd_HelpShow_In
    character(len=16), optional :: cmd_name  ! Command name (optional, shows all if absent)
  end type Cmd_HelpShow_In
```

### `Cmd_HelpShow_Out` (lines 29–31)

```fortran
  type, public :: Cmd_HelpShow_Out
    type(ErrorStatusType) :: status
  end type Cmd_HelpShow_Out
```

### `Cmd_HelpSearch_In` (lines 33–35)

```fortran
  type, public :: Cmd_HelpSearch_In
    character(len=64) :: keyword  ! Search keyword
  end type Cmd_HelpSearch_In
```

### `Cmd_HelpSearch_Out` (lines 37–39)

```fortran
  type, public :: Cmd_HelpSearch_Out
    type(ErrorStatusType) :: status
  end type Cmd_HelpSearch_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_HelpShow_Structured` | 54 | `subroutine Cmd_HelpShow_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_HelpSearch_Structured` | 80 | `subroutine Cmd_HelpSearch_Structured(domain, in, out)` |
| SUBROUTINE | `Cmd_HelpShow` | 107 | `subroutine Cmd_HelpShow(cmd_name, status)` |
| SUBROUTINE | `Cmd_HelpSearch` | 121 | `subroutine Cmd_HelpSearch(keyword, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
