# `MD_Solv_Mgr.f90`

- **Source**: `L3_MD/Analysis/Solver/MD_Solv_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Solv_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Solv_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Solv`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Solver/MD_Solv_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Solver_Domain` (lines 62–73)

```fortran
  TYPE, PUBLIC :: MD_Solver_Domain
    TYPE(MD_Solver_Desc), ALLOCATABLE :: configs(:)
    INTEGER(i4)                        :: n_configs = 0_i4
    INTEGER(i4)                        :: capacity  = 0_i4
    LOGICAL                            :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddConfig
    PROCEDURE :: GetConfig
    PROCEDURE :: GetSummary
  END TYPE MD_Solver_Domain
```

### `MD_Solver_AddConfig_Arg` (lines 80–84)

```fortran
  TYPE, PUBLIC :: MD_Solver_AddConfig_Arg
    TYPE(MD_Solver_Desc)  :: desc       ! (IN)
    INTEGER(i4)           :: config_id = 0_i4  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_AddConfig_Arg
```

### `MD_Solver_GetConfig_Arg` (lines 91–95)

```fortran
  TYPE, PUBLIC :: MD_Solver_GetConfig_Arg
    INTEGER(i4)           :: config_id = 0_i4  ! (IN)
    TYPE(MD_Solver_Desc)  :: desc              ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_GetConfig_Arg
```

### `MD_Solver_GetSummary_Arg` (lines 102–105)

```fortran
  TYPE, PUBLIC :: MD_Solver_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_GetSummary_Arg
```

### `MD_Solver_GetConfigForStep_Arg` (lines 112–116)

```fortran
  TYPE, PUBLIC :: MD_Solver_GetConfigForStep_Arg
    INTEGER(i4)           :: step_idx = 0_i4  ! [IN]
    TYPE(MD_Solver_Desc)  :: desc            ! [OUT]
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Solver_GetConfigForStep_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 129 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 138 | `SUBROUTINE Init(this, initial_capacity, status)` |
| SUBROUTINE | `AddConfig` | 156 | `SUBROUTINE AddConfig(this, desc, config_id, status)` |
| SUBROUTINE | `GetConfig` | 207 | `SUBROUTINE GetConfig(this, config_id, desc, status)` |
| SUBROUTINE | `MD_Solver_Apply_GetConfig_Idx_Arg` | 226 | `SUBROUTINE MD_Solver_Apply_GetConfig_Idx_Arg(config_id, arg)` |
| SUBROUTINE | `MD_Solver_GetConfig_Idx` | 246 | `SUBROUTINE MD_Solver_GetConfig_Idx(config_id, arg, status)` |
| SUBROUTINE | `MD_Solver_Apply_AddConfig_Arg` | 258 | `SUBROUTINE MD_Solver_Apply_AddConfig_Arg(solv_dom, arg)` |
| SUBROUTINE | `MD_Solver_Apply_GetConfig_Arg` | 267 | `SUBROUTINE MD_Solver_Apply_GetConfig_Arg(solv_dom, arg)` |
| SUBROUTINE | `MD_Solver_Apply_GetSummary_Arg` | 275 | `SUBROUTINE MD_Solver_Apply_GetSummary_Arg(solv_dom, arg)` |
| SUBROUTINE | `MD_Solver_Apply_GetConfigForStep_Arg` | 282 | `SUBROUTINE MD_Solver_Apply_GetConfigForStep_Arg(solver_domain, step_domain, arg)` |
| SUBROUTINE | `MD_Solver_Apply_GetConfigForStep_Select_Arg` | 291 | `SUBROUTINE MD_Solver_Apply_GetConfigForStep_Select_Arg(arg)` |
| SUBROUTINE | `GetSummary` | 300 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `MD_Solver_Brg_GetConfigForStep` | 319 | `SUBROUTINE MD_Solver_Brg_GetConfigForStep(solver_domain, step_domain, step_idx, &` |
| SUBROUTINE | `MD_Solver_Brg_GetConfigForStep_Select` | 354 | `SUBROUTINE MD_Solver_Brg_GetConfigForStep_Select(step_idx, desc, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
