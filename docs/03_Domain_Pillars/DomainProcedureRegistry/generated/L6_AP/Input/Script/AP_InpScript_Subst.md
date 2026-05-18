# `AP_InpScript_Subst.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Subst.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Subst`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Subst`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_Subst`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Subst.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Cmd_Subst_In` (lines 25–27)

```fortran
  type, public :: Cmd_Subst_In
    type(Cmd) :: cmd_in   ! Input command
  end type Cmd_Subst_In
```

### `Cmd_Subst_Out` (lines 29–32)

```fortran
  type, public :: Cmd_Subst_Out
    type(Cmd) :: cmd_out  ! Output command with substituted variables
    type(ErrorStatusType) :: status
  end type Cmd_Subst_Out
```

### `Cmd_SetVar_In` (lines 34–37)

```fortran
  type, public :: Cmd_SetVar_In
    character(len=32) :: var_name   ! Variable name
    real(wp)          :: var_value  ! Variable value
  end type Cmd_SetVar_In
```

### `Cmd_SetVar_Out` (lines 39–41)

```fortran
  type, public :: Cmd_SetVar_Out
    type(ErrorStatusType) :: status
  end type Cmd_SetVar_Out
```

### `Cmd_GetVar_In` (lines 43–45)

```fortran
  type, public :: Cmd_GetVar_In
    character(len=32) :: var_name  ! Variable name
  end type Cmd_GetVar_In
```

### `Cmd_GetVar_Out` (lines 47–51)

```fortran
  type, public :: Cmd_GetVar_Out
    real(wp)             :: var_value  ! Variable value
    logical              :: found      ! Whether variable was found
    type(ErrorStatusType) :: status
  end type Cmd_GetVar_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Subst_Structured` | 68 | `subroutine Cmd_Subst_Structured(ctx, in, out)` |
| SUBROUTINE | `Cmd_SetVar_Structured` | 186 | `subroutine Cmd_SetVar_Structured(ctx, in, out)` |
| SUBROUTINE | `Cmd_GetVar_Structured` | 275 | `subroutine Cmd_GetVar_Structured(ctx, in, out)` |
| SUBROUTINE | `Cmd_Subst` | 310 | `subroutine Cmd_Subst(cmd_in, ctx, cmd_out, status)` |
| SUBROUTINE | `Cmd_SetVar` | 326 | `subroutine Cmd_SetVar(ctx, var_name, var_value, status)` |
| FUNCTION | `Cmd_GetVar` | 342 | `function Cmd_GetVar(ctx, var_name, found) result(var_value)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
