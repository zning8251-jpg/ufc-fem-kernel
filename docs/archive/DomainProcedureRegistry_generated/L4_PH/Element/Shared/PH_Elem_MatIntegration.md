# `PH_Elem_MatIntegration.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_MatIntegration.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_MatIntegration`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_MatIntegration`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_MatIntegration`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_MatIntegration.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Integration_Args` (lines 21–50)

```fortran
  TYPE, PUBLIC :: PH_Mat_Integration_Args
    !-- Input: strain measures
    REAL(wp), ALLOCATABLE :: strain(:)        ! Strain increment [n_strain]
    REAL(wp), ALLOCATABLE :: dtime            ! Time increment
    
    !-- Input: material parameters (from L3_MD via L4_PH)
    REAL(wp), ALLOCATABLE :: props(:)         ! Material properties
    INTEGER(i4), ALLOCATABLE :: nprops        ! Number of props
    
    !-- Input/Output: state variables
    REAL(wp), ALLOCATABLE :: statev_in(:)     ! State vars at start of incr
    REAL(wp), ALLOCATABLE :: statev_out(:)    ! State vars at end of incr
    INTEGER(i4), ALLOCATABLE :: nstatev       ! Number of state vars
    
    !-- Output: stress and tangent
    REAL(wp), ALLOCATABLE :: stress(:)        ! Updated stress [n_strain]
    REAL(wp), ALLOCATABLE :: ddsdde(:,:)      ! Material tangent [n_strain, n_strain]
    
    !-- Output: energy and diagnostics
    REAL(wp) :: sse = 0.0_wp                  ! Strain energy density
    REAL(wp) :: spd = 0.0_wp                  ! Plastic dissipation
    REAL(wp) :: rpl = 0.0_wp                  ! Creep energy
    
    !-- Metadata
    INTEGER(i4) :: ndim = 3                   ! Spatial dimension
    INTEGER(i4) :: nstrain = 6                ! Strain components (6 for 3D)
    LOGICAL :: is_linear = .FALSE.            ! Linear material flag
    LOGICAL :: is_valid = .FALSE.             ! Validation flag
    
  END TYPE PH_Mat_Integration_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Update_Stress_Tangent` | 66 | `SUBROUTINE PH_Update_Stress_Tangent(args, status)` |
| SUBROUTINE | `PH_Compute_Strain_Energy` | 98 | `SUBROUTINE PH_Compute_Strain_Energy(args, status)` |
| SUBROUTINE | `PH_Init_Material_State` | 126 | `SUBROUTINE PH_Init_Material_State(args, nstatev_in, status)` |
| SUBROUTINE | `PH_Linear_Elastic_Update` | 155 | `SUBROUTINE PH_Linear_Elastic_Update(args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
