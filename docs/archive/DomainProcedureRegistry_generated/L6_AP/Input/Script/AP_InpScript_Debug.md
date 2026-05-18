# `AP_InpScript_Debug.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Debug.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_InpScript_Debug`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Debug`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_Debug`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Debug.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Cmd_DebugSetBrk_In` (lines 18–20)

```fortran
  TYPE, PUBLIC :: Cmd_DebugSetBrk_In
    INTEGER(i4) :: line_num
  END TYPE Cmd_DebugSetBrk_In
```

### `Cmd_DebugSetBrk_Out` (lines 22–24)

```fortran
  TYPE, PUBLIC :: Cmd_DebugSetBrk_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_DebugSetBrk_Out
```

### `Cmd_DebugShowVars_In` (lines 26–28)

```fortran
  TYPE, PUBLIC :: Cmd_DebugShowVars_In
    TYPE(CmdCtx) :: ctx
  END TYPE Cmd_DebugShowVars_In
```

### `Cmd_DebugShowVars_Out` (lines 30–32)

```fortran
  TYPE, PUBLIC :: Cmd_DebugShowVars_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_DebugShowVars_Out
```

### `CmdDebugger` (lines 37–47)

```fortran
  TYPE, PUBLIC :: CmdDebugger
    INTEGER(i4), ALLOCATABLE :: breakpoints(:)
    INTEGER(i4) :: num_breakpoints = 0
    LOGICAL :: enabled = .FALSE.
    LOGICAL :: verbose = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetBreakpoint
    PROCEDURE :: CheckBreakpoint
  END TYPE CmdDebugger
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Debug_Init` | 67 | `SUBROUTINE Debug_Init(this, enabled, verbose, status)` |
| SUBROUTINE | `Debug_SetBreakpoint` | 80 | `SUBROUTINE Debug_SetBreakpoint(this, line_num, status)` |
| FUNCTION | `Debug_CheckBreakpoint` | 89 | `FUNCTION Debug_CheckBreakpoint(this, line_num) RESULT(is_breakpoint)` |
| SUBROUTINE | `Cmd_DebugSetBrk_Structured` | 100 | `SUBROUTINE Cmd_DebugSetBrk_Structured(in, out)` |
| SUBROUTINE | `Cmd_DebugShowVars_Structured` | 108 | `SUBROUTINE Cmd_DebugShowVars_Structured(in, out)` |
| SUBROUTINE | `Cmd_DebugSetBrk` | 120 | `SUBROUTINE Cmd_DebugSetBrk(line_num, status)` |
| SUBROUTINE | `Cmd_DebugShowVars` | 132 | `SUBROUTINE Cmd_DebugShowVars(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
