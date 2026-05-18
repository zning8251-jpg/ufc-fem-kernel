# `RT_Mat_Visco_Def.f90`

- **Source**: `L5_RT/Material/RT_Mat_Visco_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Mat_Visco_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mat_Visco_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mat_Visco`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Material/RT_Mat_Visco_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mat_Visco_Desc` (lines 15–22)

```fortran
  TYPE, PUBLIC :: RT_Mat_Visco_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE :: Init => Desc_Init
    PROCEDURE :: Clean => Desc_Clean
  END TYPE
```

### `RT_Mat_Visco_State` (lines 25–31)

```fortran
  TYPE, PUBLIC :: RT_Mat_Visco_State
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Clean => State_Clean
  END TYPE
```

### `RT_Mat_Visco_Algo` (lines 34–38)

```fortran
  TYPE, PUBLIC :: RT_Mat_Visco_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
  CONTAINS
    PROCEDURE :: Init => Algo_Init
  END TYPE
```

### `RT_Mat_Visco_Ctx` (lines 41–48)

```fortran
  TYPE, PUBLIC :: RT_Mat_Visco_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE
```

### `RT_Mat_Visco_Dispatch_Arg` (lines 51–69)

```fortran
  TYPE, PUBLIC :: RT_Mat_Visco_Dispatch_Arg
    ! [IN] fields
    INTEGER(i4) :: mat_id      ! [IN]  material ID
    INTEGER(i4) :: ip_index    ! [IN]  integration point index
    INTEGER(i4) :: elem_id     ! [IN]  element ID
    REAL(wp)    :: strain(6)   ! [IN]  total strain
    REAL(wp)    :: dstrain(6)  ! [IN]  strain increment
    REAL(wp)    :: temperature ! [IN]  temperature
    REAL(wp)    :: dtemp      ! [IN]  temperature increment
    REAL(wp)    :: F(3,3)     ! [IN]  deformation gradient (for Hyper)

    ! [OUT] fields
    REAL(wp)    :: stress(6)   ! [OUT] updated stress
    REAL(wp)    :: ddsdde(6,6) ! [OUT] tangent stiffness

    ! [OUT] status
    INTEGER(i4)        :: status_code  ! [OUT] exit status
    CHARACTER(len=256) :: message      ! [OUT] status message
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 74 | `SUBROUTINE Desc_Init(this, mat_id, l4_slot)` |
| SUBROUTINE | `Desc_Clean` | 80 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 85 | `SUBROUTINE State_Init(this, num_ips)` |
| SUBROUTINE | `State_Clean` | 91 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `Algo_Init` | 96 | `SUBROUTINE Algo_Init(this)` |
| SUBROUTINE | `Ctx_Init` | 101 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_Clean` | 106 | `SUBROUTINE Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
