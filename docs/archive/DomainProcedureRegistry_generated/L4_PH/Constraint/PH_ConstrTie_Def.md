# `PH_ConstrTie_Def.f90`

- **Source**: `L4_PH/Constraint/PH_ConstrTie_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_ConstrTie_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ConstrTie_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ConstrTie`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_ConstrTie_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Tie_Constraint_Params` (lines 39–61)

```fortran
  TYPE :: Tie_Constraint_Params
    ! Constraint type
    INTEGER(i4) :: constraint_type = 1_i4       ! 1=node-to-surface, 2=surface-to-surface
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY  ! PH_CONS_* (PH_ConstraintDomain_Algo)
    
    ! Pairing tolerance
    REAL(wp) :: position_tolerance = 1.0e-6_wp  ! Position tolerance (m)
    LOGICAL :: adjust_initially = .FALSE.       ! Adjust positions initially
    
    ! Adaptive weighting
    LOGICAL :: use_adaptive_weight = .FALSE.    ! Enable adaptive weighting
    REAL(wp) :: weight_distance_scale = 1.0_wp  ! Distance scaling factor
    
    ! Penalty stiffness
    REAL(wp) :: penalty_stiffness = 1.0e12_wp   ! Penalty stiffness (N/m)
    
    ! Rotation tying
    LOGICAL :: tie_rotations = .FALSE.          ! Tie rotational DOFs (shell elements)
    
    ! Search parameters
    REAL(wp) :: search_radius = 1.0_wp          ! Search radius (m)
    INTEGER(i4) :: max_search_iterations = 10_i4 ! Max search iterations
  END TYPE Tie_Constraint_Params
```

### `Tie_Constraint_State` (lines 66–73)

```fortran
  TYPE :: Tie_Constraint_State
    INTEGER(i4) :: num_tied_nodes = 0_i4        ! Number of tied nodes
    REAL(wp) :: max_violation = ZERO            ! Maximum violation (m)
    REAL(wp) :: avg_violation = ZERO            ! Average violation (m)
    REAL(wp) :: constraint_force = ZERO         ! Constraint force (N)
    LOGICAL :: is_satisfied = .TRUE.            ! Whether constraints satisfied
    INTEGER(i4) :: num_violations = 0_i4        ! Number of violated nodes
  END TYPE Tie_Constraint_State
```

### `Tie_Node_Pair` (lines 78–88)

```fortran
  TYPE :: Tie_Node_Pair
    INTEGER(i4) :: slave_node_id = 0_i4                   ! Slave node ID
    INTEGER(i4) :: master_element_id = 0_i4               ! Master element ID
    INTEGER(i4) :: num_master_nodes = 0_i4                ! Number of master nodes
    INTEGER(i4), ALLOCATABLE :: master_node_ids(:)        ! Master node IDs
    REAL(wp) :: local_coords(3) = ZERO                    ! Local coordinates (xi, eta, zeta)
    REAL(wp), ALLOCATABLE :: shape_functions(:)           ! Shape function values
    REAL(wp) :: weight_factor = ONE                       ! Weighting factor
    REAL(wp) :: initial_distance = ZERO                   ! Initial distance (m)
    LOGICAL :: is_active = .FALSE.                        ! Whether pair is active
  END TYPE Tie_Node_Pair
```

### `Tie_Surface_Pair` (lines 93–98)

```fortran
  TYPE :: Tie_Surface_Pair
    CHARACTER(LEN=64) :: master_surface_name = ""
    CHARACTER(LEN=64) :: slave_surface_name = ""
    INTEGER(i4) :: num_pairs = 0_i4                       ! Number of node pairs
    TYPE(Tie_Node_Pair), ALLOCATABLE :: node_pairs(:)     ! Node pairings
  END TYPE Tie_Surface_Pair
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
