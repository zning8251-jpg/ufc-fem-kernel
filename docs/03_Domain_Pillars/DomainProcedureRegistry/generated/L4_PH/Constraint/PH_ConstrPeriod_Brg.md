# `PH_ConstrPeriod_Brg.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrPeriod_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ConstrPeriod_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrPeriod_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrPeriod`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrPeriod_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constr_Period_Apply_Desc` (lines 37–40)

```fortran
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Desc
    TYPE(Node_Pair_Data), ALLOCATABLE :: node_pairs(:)  ! Periodic node pairs
    INTEGER(i4) :: num_pairs = 0_i4  ! Number of node pairs
  END TYPE PH_Constr_Period_Apply_Desc
```

### `PH_Constr_Period_Apply_Algo` (lines 43–47)

```fortran
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Algo
    REAL(wp) :: macro_strain(6) = ZERO  ! Macro strain ε̄ [εxx, εyy, εzz, γxy, γyz, γxz]
    LOGICAL :: impose_macro_strain = .FALSE.  ! Whether to impose macro strain
    INTEGER(i4) :: bc_type = 1_i4  ! 1=displacement periodicity, 2=mixed, 3=stress periodicity
  END TYPE PH_Constr_Period_Apply_Algo
```

### `PH_Constr_Period_Apply_Ctx` (lines 50–54)

```fortran
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Ctx
    REAL(wp) :: rve_size(3) = ZERO  ! RVE dimensions L = [Lx, Ly, Lz]
    REAL(wp) :: rve_origin(3) = ZERO  ! RVE origin coordinates
    REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! Node coordinates X  ?ℝ^(3×n_nodes)
  END TYPE PH_Constr_Period_Apply_Ctx
```

### `PH_Constr_Period_Apply_State` (lines 57–60)

```fortran
  TYPE, PUBLIC :: PH_Constr_Period_Apply_State
    REAL(wp), ALLOCATABLE :: displacement_jump(:,:)  ! Displacement jumps Δu  ?ℝ^(3×n_pairs)
    TYPE(Period_BC_State) :: bc_state  ! Periodic BC state (macro strain/stress)
  END TYPE PH_Constr_Period_Apply_State
```

### `PH_Constr_Period_Apply_Arg` (lines 63–69)

```fortran
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Arg
    TYPE(PH_Constr_Period_Apply_Desc) :: desc                   ! [IN]
    TYPE(PH_Constr_Period_Apply_Algo) :: algo                   ! [IN]
    TYPE(PH_Constr_Period_Apply_Ctx) :: ctx                   ! [IN]
    TYPE(PH_Constr_Period_Apply_State) :: state                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Period_Apply_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_Period_Apply` | 94 | `SUBROUTINE PH_Constr_Period_Apply(arg)` |
| SUBROUTINE | `PH_Constr_Period_Init` | 139 | `SUBROUTINE PH_Constr_Period_Init(params, state, status)` |
| SUBROUTINE | `PH_Constr_Period_BuildNodePairs` | 165 | `SUBROUTINE PH_Constr_Period_BuildNodePairs(params, node_coords, nNodes, node_pairs, status)` |
| SUBROUTINE | `PH_Constr_Period_ApplyDisplacement` | 302 | `SUBROUTINE PH_Constr_Period_ApplyDisplacement(params, node_pairs, num_pairs, &` |
| SUBROUTINE | `PH_Constr_Period_ComputeMacroStrain` | 378 | `SUBROUTINE PH_Constr_Period_ComputeMacroStrain(params, element_strains, element_volumes, &` |
| SUBROUTINE | `PH_Constr_Period_ComputeMacroStress` | 414 | `SUBROUTINE PH_Constr_Period_ComputeMacroStress(params, element_stresses, element_volumes, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
