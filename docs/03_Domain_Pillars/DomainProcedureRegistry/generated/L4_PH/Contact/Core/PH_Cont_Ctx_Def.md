# `PH_Cont_Ctx_Def.f90`

- **Source**: `L4_PH/Contact/Core/PH_Cont_Ctx_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_Ctx_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Ctx_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_Ctx`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Contact/Core`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Core/PH_Cont_Ctx_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ContactCtx` (lines 51–146)

```fortran
    TYPE, PUBLIC :: PH_ContactCtx
        ! ========== three-step indexing (L3→L5 ) ==========
        INTEGER(i4) :: step_idx = 0_i4   ! Step
        INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
        ! ========== Contact Pair Identification ==========
        INTEGER(i4) :: contact_pair_id = 0
        INTEGER(i4) :: slave_surface_id = 0
        INTEGER(i4) :: master_surface_id = 0
        CHARACTER(LEN=64) :: contact_algorithm = "Penalty"  ! Penalty, Lagrange, Augmented

        ! ========== Contact State and Geometry ==========
        INTEGER(i4) :: contact_state = 0  ! 0=separate, 1=contact, 2=sticking, 3=sliding, 4=welded
        REAL(wp) :: gap = ZERO
        REAL(wp) :: penetration = ZERO
        REAL(wp) :: previous_gap = ZERO
        REAL(wp), ALLOCATABLE :: normal_vector(:)    ! (3) - Unit normal
        REAL(wp), ALLOCATABLE :: tangent_vector1(:)  ! (3) - First tangent
        REAL(wp), ALLOCATABLE :: tangent_vector2(:)  ! (3) - Second tangent

        ! ========== Contact Forces and Tractions ==========
        REAL(wp), ALLOCATABLE :: normal_force(:)     ! (3) - Normal force vector
        REAL(wp), ALLOCATABLE :: friction_force(:)   ! (3) - Friction force vector
        REAL(wp) :: normal_force_magnitude = ZERO
        REAL(wp) :: friction_force_magnitude = ZERO
        REAL(wp), ALLOCATABLE :: contact_traction(:)  ! (3) - Total traction
        REAL(wp) :: contact_pressure = ZERO
        REAL(wp) :: shear_traction = ZERO

        ! ========== Contact Stiffness and Compliance ==========
        REAL(wp) :: penalty_parameter = 1.0e6_wp
        REAL(wp) :: adaptive_penalty_factor = 1.0_wp
        REAL(wp), ALLOCATABLE :: K_contact(:,:)      ! (3,3) - Contact stiffness matrix
        REAL(wp), ALLOCATABLE :: C_contact(:,:)      ! (3,3) - Contact compliance matrix
        REAL(wp) :: normal_stiffness = ZERO
        REAL(wp) :: tangential_stiffness = ZERO
        LOGICAL :: stiffness_adaptation = .TRUE.

        ! ========== Advanced Friction Model ==========
        INTEGER(i4) :: friction_model = 1  ! 1=Coulomb, 2=Tresca, 3=Rate-dependent
        REAL(wp) :: friction_coefficient = ZERO
        REAL(wp) :: static_friction_coeff = ZERO
        REAL(wp) :: dynamic_friction_coeff = ZERO
        REAL(wp), ALLOCATABLE :: slip_velocity(:)     ! (3) - Slip velocity
        REAL(wp) :: slip_magnitude = ZERO
        REAL(wp) :: accumulated_slip = ZERO
        REAL(wp) :: slip_rate = ZERO

        ! ========== Contact Area and Pressure Distribution ==========
        REAL(wp) :: contact_area = ZERO

        ! ========== Thermal Contact Parameters ==========
        LOGICAL :: thermal_contact_enabled = .FALSE.
        REAL(wp) :: thermal_contact_conductance = ZERO
        REAL(wp) :: thermal_gap_conductance = ZERO
        REAL(wp) :: heat_flux_contact = ZERO
        REAL(wp) :: interface_temperature = ZERO
        REAL(wp) :: temperature_dependence = ZERO

        ! ========== Dynamic Contact Parameters ==========
        LOGICAL :: dynamic_contact_enabled = .FALSE.
        REAL(wp) :: impact_velocity = ZERO
        REAL(wp) :: effective_mass = ZERO
        REAL(wp) :: contact_damping = ZERO
        REAL(wp) :: restitution_coefficient = ZERO

        ! ========== Convergence and Algorithm Ctrl ==========
        REAL(wp) :: residual_norm = ZERO
        REAL(wp) :: tolerance = 1.0e-6_wp
        REAL(wp) :: relative_tolerance = 1.0e-6_wp
        INTEGER(i4) :: iteration_count = 0
        INTEGER(i4) :: max_iterations = 50
        LOGICAL :: converged = .FALSE.
        REAL(wp) :: convergence_rate = ZERO
        CHARACTER(LEN=100) :: convergence_status = "Not Started"

        ! ========== Error Estimation and Quality Ctrl ==========
        REAL(wp) :: error_estimate = ZERO
        REAL(wp) :: error_bound = ZERO
        INTEGER(i4) :: error_indicator = 0
        LOGICAL :: quality_control_passed = .TRUE.

        ! ========== Flags and Status ==========
        LOGICAL :: is_initialized = .FALSE.
        LOGICAL :: is_active = .TRUE.
        LOGICAL :: requires_update = .TRUE.
        INTEGER(i4) :: contact_history_count = 0

        ! ========== AP-8 Warm-path buffers (pre-allocated in Init) ==========
        REAL(wp), ALLOCATABLE :: penetration_depth_buf(:)  ! (max_surfaces) penetration per face
        INTEGER(i4), ALLOCATABLE :: collision_ids_buf(:)   ! BVH_Query work buffer
        INTEGER(i4), ALLOCATABLE :: nearby_ids_buf(:)       ! SpatialHash_Query work buffer
        INTEGER(i4) :: max_penetration_buf = 0
        INTEGER(i4) :: max_collision_buf = 0
        INTEGER(i4) :: max_nearby_buf = 0

    END TYPE PH_ContactCtx
```

### `PH_Cont_Time_Desc` (lines 153–155)

```fortran
    TYPE, PUBLIC :: PH_Cont_Time_Desc
        REAL(wp) :: dt = 0.0_wp
    END TYPE PH_Cont_Time_Desc
```

### `PH_Cont_Ctx_Init_Arg` (lines 164–172)

```fortran
  TYPE, PUBLIC :: PH_Cont_Ctx_Init_Arg
    INTEGER(i4) :: contact_pair_id                   ! [IN]
    INTEGER(i4) :: slave_surface_id                   ! [IN]
    INTEGER(i4) :: master_surface_id                   ! [IN]
    REAL(wp) :: penalty_parameter                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    TYPE(PH_ContactCtx) :: ctx                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Init_Arg
```

### `PH_Cont_Ctx_Clear_Arg` (lines 178–181)

```fortran
  TYPE, PUBLIC :: PH_Cont_Ctx_Clear_Arg
    TYPE(PH_ContactCtx) :: ctx                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Clear_Arg
```

### `PH_Cont_Ctx_Copy_Arg` (lines 187–191)

```fortran
  TYPE, PUBLIC :: PH_Cont_Ctx_Copy_Arg
    TYPE(PH_ContactCtx) :: ctx_src                   ! [IN]
    TYPE(PH_ContactCtx) :: ctx_dst                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Copy_Arg
```

### `PH_Cont_Ctx_Valid_Arg` (lines 197–201)

```fortran
  TYPE, PUBLIC :: PH_Cont_Ctx_Valid_Arg
    TYPE(PH_ContactCtx) :: ctx                   ! [IN]
    LOGICAL :: is_valid                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Ctx_Valid_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Cont_Ctx_Init` | 211 | `SUBROUTINE PH_Cont_Ctx_Init(ctx, contact_pair_id, &` |
| SUBROUTINE | `PH_Cont_Ctx_Init_Structured` | 292 | `SUBROUTINE PH_Cont_Ctx_Init_Structured(arg)` |
| SUBROUTINE | `PH_Cont_Ctx_Clear` | 309 | `SUBROUTINE PH_Cont_Ctx_Clear(ctx, status)` |
| SUBROUTINE | `PH_Cont_Ctx_Clear_Structured` | 345 | `SUBROUTINE PH_Cont_Ctx_Clear_Structured(arg)` |
| SUBROUTINE | `PH_Cont_Ctx_Copy` | 360 | `SUBROUTINE PH_Cont_Ctx_Copy(ctx_src, ctx_dst, status)` |
| SUBROUTINE | `PH_Cont_Ctx_Copy_Structured` | 484 | `SUBROUTINE PH_Cont_Ctx_Copy_Structured(arg)` |
| FUNCTION | `PH_Cont_Ctx_Valid` | 497 | `FUNCTION PH_Cont_Ctx_Valid(ctx) RESULT(is_valid)` |
| SUBROUTINE | `PH_Cont_Ctx_Valid_Structured` | 538 | `SUBROUTINE PH_Cont_Ctx_Valid_Structured(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
