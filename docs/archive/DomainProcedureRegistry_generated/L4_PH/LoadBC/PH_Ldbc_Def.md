# `PH_Ldbc_Def.f90`

- **Source**: `L4_PH/LoadBC/PH_Ldbc_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Ldbc_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Ldbc_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Ldbc`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Ldbc_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Ldbc_Enforcement_Type` (lines 29–34)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Enforcement_Type
    INTEGER(i4) :: method = PH_LBC_BC_PENALTY
    REAL(wp) :: penalty_param = 1.0e12_wp      ! penalty α (Penalty)
    LOGICAL :: use_adaptive_penalty = .FALSE.  ! adaptive scaling
    REAL(wp) :: lagrange_tol = 1.0e-10_wp      ! Lagrange convergence tol
  END TYPE PH_Ldbc_Enforcement_Type
```

### `PH_Ldbc_Cache_Type` (lines 37–44)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Cache_Type
    INTEGER(i4) :: bcId = 0_i4
    INTEGER(i4) :: nodeId = 0_i4
    INTEGER(i4) :: dof = 0_i4
    REAL(wp) :: value = 0.0_wp
    REAL(wp) :: current_time = 0.0_wp
    REAL(wp) :: amp_factor = 1.0_wp
  END TYPE PH_Ldbc_Cache_Type
```

### `PH_Ldbc_Ctrl_Type` (lines 47–60)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Ctrl_Type
    TYPE(PH_Ldbc_Enforcement_Type) :: enforcement
    INTEGER(i4) :: nConstrainedDOFs = 0_i4
    INTEGER(i4), ALLOCATABLE :: constrained_dof_ids(:)
    REAL(wp), ALLOCATABLE :: bc_values(:)
    INTEGER(i4) :: nConstraints = 0_i4
    REAL(wp), ALLOCATABLE :: constraint_matrix(:,:)
    REAL(wp), ALLOCATABLE :: constraint_rhs(:)
    INTEGER(i4) :: nTotalDOFs = 0_i4
    REAL(wp), ALLOCATABLE :: bc_vector(:)
    LOGICAL, ALLOCATABLE :: is_constrained(:)
    INTEGER(i4) :: nActiveBCs = 0_i4
    TYPE(PH_Ldbc_Cache_Type), ALLOCATABLE :: bc_cache(:)
  END TYPE PH_Ldbc_Ctrl_Type
```

### `PH_Ldbc_InitPar_Type` (lines 63–65)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_InitPar_Type
    INTEGER(i4) :: nTotalDOFs = 0_i4
  END TYPE PH_Ldbc_InitPar_Type
```

### `PH_Ldbc_MethodPar_Type` (lines 68–71)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_MethodPar_Type
    INTEGER(i4) :: method = PH_LBC_BC_PENALTY
    REAL(wp) :: penalty_param = 1.0e12_wp
  END TYPE PH_Ldbc_MethodPar_Type
```

### `PH_Ldbc_System_Type` (lines 74–77)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_System_Type
    REAL(wp), ALLOCATABLE :: K(:,:)
    REAL(wp), ALLOCATABLE :: R(:)
  END TYPE PH_Ldbc_System_Type
```

### `PH_Ldbc_SystemAug_Type` (lines 80–83)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_SystemAug_Type
    REAL(wp), ALLOCATABLE :: K_aug(:,:)
    REAL(wp), ALLOCATABLE :: R_aug(:)
  END TYPE PH_Ldbc_SystemAug_Type
```

### `PH_Ldbc_ApplyBCsIn_Type` (lines 86–89)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_ApplyBCsIn_Type
    INTEGER(i4) :: nBCs = 0_i4
    TYPE(PH_Ldbc_Cache_Type), ALLOCATABLE :: bc_cache(:)
  END TYPE PH_Ldbc_ApplyBCsIn_Type
```

### `PH_Ldbc_Dirichlet_Desc` (lines 92–96)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Dirichlet_Desc
    INTEGER(i4) :: n_dofs = 0_i4
    INTEGER(i4), ALLOCATABLE :: dof_indices(:)
    REAL(wp),    ALLOCATABLE :: prescribed_values(:)
  END TYPE PH_Ldbc_Dirichlet_Desc
```

### `PH_Ldbc_Neumann_Desc` (lines 99–103)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Neumann_Desc
    INTEGER(i4) :: n_dofs = 0_i4
    INTEGER(i4), ALLOCATABLE :: dof_indices(:)
    REAL(wp),    ALLOCATABLE :: values(:)
  END TYPE PH_Ldbc_Neumann_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_LdbcCtrl_Init_Scalar` | 125 | `SUBROUTINE PH_LdbcCtrl_Init_Scalar(ctrl, nTotalDOFs)` |
| SUBROUTINE | `PH_LdbcCtrl_Init_Par` | 140 | `SUBROUTINE PH_LdbcCtrl_Init_Par(ctrl, init_par)` |
| SUBROUTINE | `PH_LdbcCtrl_Free` | 149 | `SUBROUTINE PH_LdbcCtrl_Free(ctrl)` |
| SUBROUTINE | `PH_LdbcCtrl_SetMethod_Scalar` | 165 | `SUBROUTINE PH_LdbcCtrl_SetMethod_Scalar(ctrl, method, penalty_param)` |
| SUBROUTINE | `PH_LdbcCtrl_SetMethod_Par` | 173 | `SUBROUTINE PH_LdbcCtrl_SetMethod_Par(ctrl, method_par)` |
| SUBROUTINE | `PH_LdbcCtrl_ApplyBCs` | 182 | `SUBROUTINE PH_LdbcCtrl_ApplyBCs(ctrl, in_par)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 113–115 | `INTERFACE PH_LdbcCtrl_Init` |
| 116–118 | `INTERFACE PH_LdbcCtrl_SetMethod` |
