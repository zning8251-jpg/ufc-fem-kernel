# `PH_ConstrEmbedded_Def.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrEmbedded_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_ConstrEmbedded_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrEmbedded_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrEmbedded`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrEmbedded_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Embedded_Host_Elem` (lines 42–49)

```fortran
  TYPE, PUBLIC :: Embedded_Host_Elem
    INTEGER(i4) :: host_elem_id    = 0_i4     ! Global host element ID
    INTEGER(i4) :: n_embedded      = 0_i4     ! # embedded nodes in this element
    INTEGER(i4), ALLOCATABLE :: embedded_node_ids(:)
    REAL(wp),    ALLOCATABLE :: N_at_embedded(:,:)  ! (n_embedded, n_host_nodes)
    REAL(wp)    :: host_det_J      = 0.0_wp   ! Jacobian determinant at embed pt
    LOGICAL     :: found_host      = .FALSE.  ! Host element found in search
  END TYPE Embedded_Host_Elem
```

### `Embedded_Node_Constraint` (lines 56–64)

```fortran
  TYPE, PUBLIC :: Embedded_Node_Constraint
    INTEGER(i4) :: embedded_node_id  = 0_i4
    INTEGER(i4) :: host_elem_id      = 0_i4
    INTEGER(i4) :: n_host_nodes      = 0_i4
    REAL(wp), ALLOCATABLE :: N_host(:)     ! (n_host_nodes) shape func values
    REAL(wp), ALLOCATABLE :: xi_nat(:)     ! (ndim) natural coords in host elem
    REAL(wp)              :: gap_tol       = 1.0e-6_wp
    LOGICAL               :: is_inside     = .FALSE.
  END TYPE Embedded_Node_Constraint
```

### `EmbeddedRegion_Params` (lines 71–84)

```fortran
  TYPE, PUBLIC :: EmbeddedRegion_Params
    INTEGER(i4) :: region_id         = 0_i4
    CHARACTER(LEN=64) :: name        = ""
    CHARACTER(LEN=64) :: host_set    = ""
    CHARACTER(LEN=64) :: embedded_set = ""
    LOGICAL           :: use_rounding = .TRUE.
    INTEGER(i4)       :: n_embedded_nodes = 0_i4
    INTEGER(i4)       :: n_host_elems     = 0_i4
    TYPE(Embedded_Node_Constraint), ALLOCATABLE :: constraints(:)
    TYPE(Embedded_Host_Elem),       ALLOCATABLE :: host_elems(:)
    REAL(wp)          :: tol_abs = 1.0e-8_wp     ! Absolute constraint tolerance
    REAL(wp)          :: penalty_scale = 1.0e12_wp ! Penalty factor for embedding
    INTEGER(i4)       :: enforcement = 1_i4        ! 1=penalty, 2=Lagrange, 3=elimination
  END TYPE EmbeddedRegion_Params
```

### `EmbeddedRegion_State` (lines 91–97)

```fortran
  TYPE, PUBLIC :: EmbeddedRegion_State
    LOGICAL     :: initialized     = .FALSE.
    LOGICAL     :: paired          = .FALSE.
    INTEGER(i4) :: n_active_nodes  = 0_i4
    INTEGER(i4) :: n_violations    = 0_i4
    REAL(wp)    :: max_violation   = 0.0_wp
  END TYPE EmbeddedRegion_State
```

### `EmbeddedRegion_Brg_Ctx` (lines 104–107)

```fortran
  TYPE, PUBLIC :: EmbeddedRegion_Brg_Ctx
    INTEGER(i4) :: src_region_id = 0_i4
    LOGICAL     :: populate_done = .FALSE.
  END TYPE EmbeddedRegion_Brg_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `EmbeddedRegion_Params_Init` | 114 | `SUBROUTINE EmbeddedRegion_Params_Init(params, region_id, &` |
| FUNCTION | `EmbeddedRegion_Params_Valid` | 141 | `FUNCTION EmbeddedRegion_Params_Valid(params) RESULT(ok)` |
| SUBROUTINE | `EmbeddedRegion_Params_Cleanup` | 149 | `SUBROUTINE EmbeddedRegion_Params_Cleanup(params, status)` |
| SUBROUTINE | `EmbeddedRegion_State_Init` | 181 | `SUBROUTINE EmbeddedRegion_State_Init(state)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
