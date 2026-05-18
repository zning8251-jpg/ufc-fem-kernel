# `PH_Elem_Mass2.f90`

- **Source**: `L4_PH/Element/PH_Elem_Mass2.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Mass2`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Mass2`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Mass2`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Mass2.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Mass_Algo` (lines 51–68)

```fortran
  TYPE, PUBLIC :: PH_Elem_Mass_Algo
    !! Mass computation parameters
    !! Groups: density, formulation options, numerical integration
    
    real(wp) :: density = 0.0_wp           ! Material density (ρ)
    integer(i4) :: mass_formulation = PH_ELEM_MASS_CONSIST
    logical :: incl_rot_inertia = .FALSE.  ! Include rotational DOF inertia
    real(wp) :: mass_scaling = 1.0_wp      ! Global mass scaling factor
    
    ! Numerical integration
    integer(i4) :: n_gauss_points = 0_i4
    real(wp), allocatable :: gauss_weights(:)
    real(wp), allocatable :: gauss_coords(:,:)
    
  CONTAINS
    PROCEDURE, PUBLIC :: Init => Algo_Init
    PROCEDURE, PUBLIC :: Valid => Algo_Valid
  END TYPE PH_Elem_Mass_Algo
```

### `PH_Elem_Mass_State` (lines 75–99)

```fortran
  TYPE, PUBLIC :: PH_Elem_Mass_State
    !! Computed mass matrix result
    !! Contains: element mass matrix, statistics, metadata
    
    integer(i4) :: n_elem_dofs = 0_i4
    integer(i4) :: mass_type = PH_ELEM_MASS_CONSIST
    real(wp), allocatable :: elem_mass(:,:)    ! Element mass matrix [n×n]
    real(wp), allocatable :: lumped_mass(:)    ! Lumped mass vector [n]
    
    ! Statistics
    real(wp) :: total_mass = 0.0_wp
    real(wp) :: max_diag_value = 0.0_wp
    real(wp) :: min_diag_value = 0.0_wp
    logical :: is_positive_definite = .FALSE.
    
    ! Metadata
    character(len=128) :: elem_type = ""
    integer(i4) :: n_nodes = 0_i4
    integer(i4) :: n_dof_per_node = 0_i4
    
  CONTAINS
    PROCEDURE, PUBLIC :: Init => State_Init
    PROCEDURE, PUBLIC :: Clear => State_Clear
    PROCEDURE, PUBLIC :: Print => State_Print
  END TYPE PH_Elem_Mass_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Algo_Init` | 107 | `SUBROUTINE Algo_Init(this, density, mass_formulation, &` |
| SUBROUTINE | `Algo_Valid` | 142 | `SUBROUTINE Algo_Valid(this, status)` |
| SUBROUTINE | `State_Init` | 174 | `SUBROUTINE State_Init(this, n_dofs, mass_type, status)` |
| SUBROUTINE | `State_Clear` | 196 | `SUBROUTINE State_Clear(this)` |
| SUBROUTINE | `State_Print` | 210 | `SUBROUTINE State_Print(this, status)` |
| SUBROUTINE | `PH_Elem_Mass_Consistent` | 234 | `SUBROUTINE PH_Elem_Mass_Consistent(coords, params, result, status)` |
| SUBROUTINE | `PH_Elem_Mass_Lumped` | 360 | `SUBROUTINE PH_Elem_Mass_Lumped(coords, params, result, status)` |
| SUBROUTINE | `PH_Elem_Mass_Hybrid` | 455 | `SUBROUTINE PH_Elem_Mass_Hybrid(coords, params, result, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
