# `AP_InpScript_Alias.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Alias.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Alias`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Alias`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_Alias`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Alias.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AliasEntry` (lines 15–19)

```fortran
  TYPE, PUBLIC :: AliasEntry
    CHARACTER(LEN=16) :: name = ''
    TYPE(Cmd) :: cmd
    LOGICAL :: defined = .FALSE.
  END TYPE AliasEntry
```

### `CmdAliasMgr` (lines 21–30)

```fortran
  TYPE, PUBLIC :: CmdAliasMgr
    TYPE(AliasEntry), ALLOCATABLE :: aliases(:)
    INTEGER(i4) :: num_aliases = 0
    INTEGER(i4) :: max_aliases = 50
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Define
    PROCEDURE :: Resolve
  END TYPE CmdAliasMgr
```

### `Cmd_AliasDefine_In` (lines 34–37)

```fortran
  TYPE, PUBLIC :: Cmd_AliasDefine_In
    CHARACTER(LEN=16) :: name
    TYPE(Cmd) :: cmd
  END TYPE Cmd_AliasDefine_In
```

### `Cmd_AliasDefine_Out` (lines 39–41)

```fortran
  TYPE, PUBLIC :: Cmd_AliasDefine_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_AliasDefine_Out
```

### `Cmd_AliasResolve_In` (lines 43–45)

```fortran
  TYPE, PUBLIC :: Cmd_AliasResolve_In
    CHARACTER(LEN=16) :: name
  END TYPE Cmd_AliasResolve_In
```

### `Cmd_AliasResolve_Out` (lines 47–51)

```fortran
  TYPE, PUBLIC :: Cmd_AliasResolve_Out
    TYPE(Cmd) :: cmd
    LOGICAL :: found
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_AliasResolve_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Alias_Init` | 60 | `SUBROUTINE Alias_Init(this, status)` |
| SUBROUTINE | `Alias_Define` | 77 | `SUBROUTINE Alias_Define(this, name, cmd, status)` |
| SUBROUTINE | `Alias_Resolve` | 119 | `SUBROUTINE Alias_Resolve(this, name, cmd, found, status)` |
| SUBROUTINE | `Cmd_AliasDefine_Structured` | 148 | `SUBROUTINE Cmd_AliasDefine_Structured(in, out)` |
| SUBROUTINE | `Cmd_AliasResolve_Structured` | 156 | `SUBROUTINE Cmd_AliasResolve_Structured(in, out)` |
| SUBROUTINE | `Cmd_AliasDefine` | 164 | `SUBROUTINE Cmd_AliasDefine(name, cmd, status)` |
| SUBROUTINE | `Cmd_AliasResolve` | 178 | `SUBROUTINE Cmd_AliasResolve(name, cmd, found, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
