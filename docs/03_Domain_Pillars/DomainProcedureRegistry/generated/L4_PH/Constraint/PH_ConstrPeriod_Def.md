# `PH_ConstrPeriod_Def.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrPeriod_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ConstrPeriod_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrPeriod_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrPeriod`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrPeriod_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Period_BC_Params` (lines 36–55)

```fortran
  TYPE :: Period_BC_Params
    ! RVE geometry
    REAL(wp) :: rve_size(3) = ZERO               ! RVE dimensions [Lx, Ly, Lz]
    REAL(wp) :: rve_origin(3) = ZERO             ! RVE origin coordinates
    
    ! Periodicity directions
    LOGICAL :: periodic_x = .FALSE.              ! X-direction periodicity
    LOGICAL :: periodic_y = .FALSE.              ! Y-direction periodicity
    LOGICAL :: periodic_z = .FALSE.              ! Z-direction periodicity
    
    ! Macro strain
    REAL(wp) :: macro_strain(6) = ZERO           ! Macro strain [εxx, εyy, εzz, γxy, γyz, γxz]
    LOGICAL :: impose_macro_strain = .FALSE.     ! Whether to impose macro strain
    
    ! BC type
    INTEGER(i4) :: bc_type = 1_i4                ! 1=displacement periodicity, 2=mixed, 3=stress periodicity
    
    ! Pairing tolerance
    REAL(wp) :: pairing_tolerance = 1.0e-6_wp    ! Node pairing tolerance
  END TYPE Period_BC_Params
```

### `Period_BC_State` (lines 60–66)

```fortran
  TYPE :: Period_BC_State
    INTEGER(i4) :: nNode_pairs = 0_i4            ! Number of node pairs
    REAL(wp) :: computed_macro_strain(6) = ZERO  ! Computed macro strain
    REAL(wp) :: computed_macro_stress(6) = ZERO  ! Computed macro stress
    REAL(wp) :: rve_volume = ZERO                ! RVE volume
    LOGICAL :: is_consistent = .TRUE.            ! Whether BC is consistent
  END TYPE Period_BC_State
```

### `Node_Pair_Data` (lines 71–79)

```fortran
  TYPE :: Node_Pair_Data
    INTEGER(i4) :: node_minus_id = 0_i4          ! Minus-side node ID
    INTEGER(i4) :: node_plus_id = 0_i4           ! Plus-side node ID
    INTEGER(i4) :: boundary_face = 0_i4          ! Boundary face ID (1=x-, 2=x+, 3=y-, ...)
    REAL(wp) :: coords_minus(3) = ZERO           ! Minus-side coordinates
    REAL(wp) :: coords_plus(3) = ZERO            ! Plus-side coordinates
    LOGICAL :: is_corner_node = .FALSE.          ! Whether corner node
    LOGICAL :: is_edge_node = .FALSE.            ! Whether edge node
  END TYPE Node_Pair_Data
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
