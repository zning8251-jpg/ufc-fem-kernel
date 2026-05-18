# `PH_ConstrTie_Brg.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrTie_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_ConstrTie_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrTie_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrTie`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrTie_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_Tie_Apply_Desc` (lines 46–48)

```fortran
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Desc
    TYPE(Tie_Surface_Pair) :: surface_pair  ! Surface pair definition
  END TYPE PH_Constr_Tie_Apply_Desc
```

### `PH_Constr_Tie_Apply_Algo` (lines 52–57)

```fortran
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Algo
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY
    REAL(wp) :: penalty_stiffness = 1.0e12_wp  ! Penalty stiffness ?? (N/m)
    REAL(wp) :: position_tolerance = 1.0e-6_wp  ! Position tolerance (m)
    LOGICAL :: use_adaptive_weight = .FALSE.  ! Use adaptive weighting
  END TYPE PH_Constr_Tie_Apply_Algo
```

### `PH_Constr_Tie_Apply_Ctx` (lines 60–63)

```fortran
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Ctx
    REAL(wp), ALLOCATABLE :: slave_displacements(:,:)  ! Slave displacements u_slave  ??^(3??n_slave)
    REAL(wp), ALLOCATABLE :: master_displacements(:,:)  ! Master displacements u_master  ??^(3??n_master)
  END TYPE PH_Constr_Tie_Apply_Ctx
```

### `PH_Constr_Tie_Apply_State` (lines 66–69)

```fortran
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_State
    REAL(wp), ALLOCATABLE :: constraint_forces(:,:)  ! Constraint forces F_constraint  ??^(3??n_slave)
    TYPE(Tie_Constraint_State) :: violation_state  ! Constraint violation state
  END TYPE PH_Constr_Tie_Apply_State
```

### `PH_Constr_Tie_Apply_Arg` (lines 72–78)

```fortran
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Arg
    TYPE(PH_Constr_Tie_Apply_Desc) :: desc                   ! [IN]
    TYPE(PH_Constr_Tie_Apply_Algo) :: algo                   ! [IN]
    TYPE(PH_Constr_Tie_Apply_Ctx) :: ctx                   ! [IN]
    TYPE(PH_Constr_Tie_Apply_State) :: state                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Tie_Apply_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_Tie_Apply` | 106 | `SUBROUTINE PH_Constr_Tie_Apply(arg)` |
| SUBROUTINE | `PH_Constr_Tie_Init` | 156 | `SUBROUTINE PH_Constr_Tie_Init(params, state)` |
| SUBROUTINE | `PH_Constr_Tie_BuildNodePairs` | 179 | `SUBROUTINE PH_Constr_Tie_BuildNodePairs(params, slave_coords, master_surface_coords, &` |
| SUBROUTINE | `PH_Constr_Tie_CalcWeights` | 222 | `SUBROUTINE PH_Constr_Tie_CalcWeights(params, surface_pair)` |
| SUBROUTINE | `PH_Constr_Tie_ApplyConstraint` | 241 | `SUBROUTINE PH_Constr_Tie_ApplyConstraint(params, surface_pair, slave_displacements, &` |
| SUBROUTINE | `PH_Constr_Tie_CheckViolation` | 298 | `SUBROUTINE PH_Constr_Tie_CheckViolation(params, surface_pair, slave_coords, &` |
| SUBROUTINE | `PH_Constr_Tie_Opt` | 366 | `SUBROUTINE PH_Constr_Tie_Opt(surface_pair, params, status)` |
| SUBROUTINE | `PH_Constr_Tie_ComputeViolation` | 397 | `SUBROUTINE PH_Constr_Tie_ComputeViolation(node_pair, u_slave, u_master, violation, status)` |
| SUBROUTINE | `PH_Constr_Tie_UpdateWeights` | 414 | `SUBROUTINE PH_Constr_Tie_UpdateWeights(node_pair, params, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
