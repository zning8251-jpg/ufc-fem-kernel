# `PH_BC_Mgr.f90`

- **Source**: `L4_PH/LoadBC/PH_BC_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_BC_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_BC_Mgr`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_BC`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_BC_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_BC_Ctx` (lines 26–39)

```fortran
  TYPE, PUBLIC :: PH_BC_Ctx
    INTEGER(i4) :: enforcement_method = PH_BC_BC_PENALTY
    REAL(wp)    :: penalty_factor = 1.0e30_wp
    LOGICAL     :: use_reduced_integration = .FALSE.
    INTEGER(i4) :: n_bcs_applied = 0_i4
    INTEGER(i4) :: n_dofs_constrained = 0_i4
    INTEGER(i4), ALLOCATABLE :: constrained_dofs(:)
    REAL(wp),    ALLOCATABLE :: prescribed_values(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Init => PH_BC_Ctx_Init
    PROCEDURE, PUBLIC :: Clear => PH_BC_Ctx_Clear
    PROCEDURE, PUBLIC :: SetMethod => PH_BC_Ctx_SetMethod
    PROCEDURE, PUBLIC :: GetMethod => PH_BC_Ctx_GetMethod
  END TYPE PH_BC_Ctx
```

### `PH_BC_Ctx_Init_Arg` (lines 42–45)

```fortran
  TYPE, PUBLIC :: PH_BC_Ctx_Init_Arg
    TYPE(PH_BC_Ctx) :: ctx                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_BC_Ctx_Init_Arg
```

### `PH_BC_Ctx_SetMethod_Arg` (lines 49–53)

```fortran
  TYPE, PUBLIC :: PH_BC_Ctx_SetMethod_Arg
    TYPE(PH_BC_Ctx) :: ctx                   ! [INOUT]
    INTEGER(i4) :: method                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_BC_Ctx_SetMethod_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_BC_Ctx_Init` | 71 | `SUBROUTINE PH_BC_Ctx_Init(this, method, penalty_factor)` |
| SUBROUTINE | `PH_BC_Ctx_Init_Structured` | 83 | `SUBROUTINE PH_BC_Ctx_Init_Structured(arg)` |
| SUBROUTINE | `PH_BC_Ctx_Clear` | 90 | `SUBROUTINE PH_BC_Ctx_Clear(this)` |
| SUBROUTINE | `PH_BC_Ctx_SetMethod` | 98 | `SUBROUTINE PH_BC_Ctx_SetMethod(this, method, penalty_factor)` |
| SUBROUTINE | `PH_BC_Ctx_SetMethod_Structured` | 106 | `SUBROUTINE PH_BC_Ctx_SetMethod_Structured(arg)` |
| FUNCTION | `PH_BC_Ctx_GetMethod` | 114 | `FUNCTION PH_BC_Ctx_GetMethod(this) RESULT(method)` |
| SUBROUTINE | `BCM_Apply_Dense` | 124 | `SUBROUTINE BCM_Apply_Dense(ctrl, sys, status)` |
| SUBROUTINE | `BCM_Apply_Lagrange_Dense` | 149 | `SUBROUTINE BCM_Apply_Lagrange_Dense(ctrl, sys_aug, status)` |
| SUBROUTINE | `BCM_Apply_Sparse` | 180 | `SUBROUTINE BCM_Apply_Sparse(K_csr, R, dof_indices, prescribed_values, &` |
| SUBROUTINE | `BCM_Elimination_Dense` | 212 | `SUBROUTINE BCM_Elimination_Dense(ctrl, sys, status)` |
| SUBROUTINE | `BCM_InsertDiagonal_CSR` | 242 | `SUBROUTINE BCM_InsertDiagonal_CSR(K_csr, row_index, diag_value, status)` |
| SUBROUTINE | `BCM_Penalty_Dense` | 317 | `SUBROUTINE BCM_Penalty_Dense(ctrl, sys, status)` |
| SUBROUTINE | `BCM_Penalty_Sparse` | 347 | `SUBROUTINE BCM_Penalty_Sparse(K_csr, R, dof_indices, prescribed_values, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
