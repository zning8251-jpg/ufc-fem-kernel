# `RT_Mat_Elas_Def.f90`

- **Source**: `L5_RT/Material/RT_Mat_Elas_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Mat_Elas_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mat_Elas_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mat_Elas`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Material/RT_Mat_Elas_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mat_Elas_Desc` (lines 22–30)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_Desc
    INTEGER(i4) :: mat_id          = 0_i4   ! Material ID (from L3)
    INTEGER(i4) :: sub_type        = 0_i4   ! Elastic sub-type (ISO/ORTHO/etc.)
    INTEGER(i4) :: l4_slot_index   = 0_i4   ! Index into L4 slot pool
    LOGICAL     :: is_active       = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => Desc_Init
    PROCEDURE :: Clean  => Desc_Clean
  END TYPE RT_Mat_Elas_Desc
```

### `RT_Mat_Elas_State` (lines 35–41)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_State
    INTEGER(i4) :: num_ips         = 0_i4   ! Number of integration points
    LOGICAL     :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Clean  => State_Clean
  END TYPE RT_Mat_Elas_State
```

### `RT_Mat_Elas_Algo` (lines 46–50)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4  ! 0=standard, 1=vectorized
  CONTAINS
    PROCEDURE :: Init => Algo_Init
  END TYPE RT_Mat_Elas_Algo
```

### `RT_Mat_Elas_Ctx` (lines 55–62)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_Ctx
    INTEGER(i4) :: current_step    = 0_i4
    INTEGER(i4) :: current_incr    = 0_i4
    INTEGER(i4) :: current_iter    = 0_i4
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE RT_Mat_Elas_Ctx
```

### `RT_Mat_Elas_Route_Entry` (lines 67–71)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_Route_Entry
    INTEGER(i4) :: mat_id        = 0_i4
    INTEGER(i4) :: sub_type      = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
  END TYPE RT_Mat_Elas_Route_Entry
```

### `RT_Mat_Elas_Dispatch_Table` (lines 76–83)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_Dispatch_Table
    TYPE(RT_Mat_Elas_Route_Entry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: num_entries = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init  => Dispatch_Table_Init
    PROCEDURE :: Clean => Dispatch_Table_Clean
  END TYPE RT_Mat_Elas_Dispatch_Table
```

### `RT_Mat_Elas_Dispatch_Arg` (lines 88–105)

```fortran
  TYPE, PUBLIC :: RT_Mat_Elas_Dispatch_Arg
    ! [IN] fields
    INTEGER(i4) :: mat_id           ! [IN]  material ID to dispatch
    INTEGER(i4) :: ip_index         ! [IN]  integration point index
    INTEGER(i4) :: elem_id          ! [IN]  element ID
    REAL(wp)    :: strain(6)        ! [IN]  total strain
    REAL(wp)    :: dstrain(6)       ! [IN]  strain increment
    REAL(wp)    :: temperature      ! [IN]  temperature
    REAL(wp)    :: dtemp            ! [IN]  temperature increment

    ! [OUT] fields
    REAL(wp)    :: stress(6)        ! [OUT] updated stress
    REAL(wp)    :: ddsdde(6,6)      ! [OUT] tangent stiffness

    ! [OUT] status
    INTEGER(i4)           :: status_code ! [OUT] exit status
    CHARACTER(len=256)    :: message     ! [OUT] status message
  END TYPE RT_Mat_Elas_Dispatch_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 117 | `SUBROUTINE Desc_Init(this, mat_id, sub_type, l4_slot)` |
| SUBROUTINE | `Desc_Clean` | 128 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 133 | `SUBROUTINE State_Init(this, num_ips)` |
| SUBROUTINE | `State_Clean` | 140 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `Algo_Init` | 146 | `SUBROUTINE Algo_Init(this)` |
| SUBROUTINE | `Ctx_Init` | 151 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_Clean` | 158 | `SUBROUTINE Ctx_Clean(this)` |
| SUBROUTINE | `Dispatch_Table_Init` | 162 | `SUBROUTINE Dispatch_Table_Init(this, max_entries, status)` |
| SUBROUTINE | `Dispatch_Table_Clean` | 174 | `SUBROUTINE Dispatch_Table_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
