# `PH_ThermalCont_Def.f90`

- **Source**: `L4_PH/Contact/Thermal/PH_ThermalCont_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ThermalCont_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ThermalCont_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ThermalCont`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Contact/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Thermal/PH_ThermalCont_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Thermal_Cont_Desc` (lines 37–82)

```fortran
  TYPE, PUBLIC :: PH_Thermal_Cont_Desc
    !-- Thermal contact flag
    LOGICAL :: thermal_contact_enabled = .FALSE.   ! Enable thermal coupling
    
    !-- Thermal contact conductance model
    INTEGER(i4) :: conductance_model = PH_THERM_CONT_COND_GAP
    
    !-- Conductance parameters
    REAL(wp) :: conductance_constant = 1000.0_wp   ! Constant conductance (W/m²·K)
    REAL(wp) :: conductance_gap_ref = 1.0e-6_wp    ! Reference gap (m)
    REAL(wp) :: conductance_exponent = 2.0_wp      ! Gap exponent
    
    !-- Gap conductance table (for table lookup)
    INTEGER(i4) :: n_table_points = 0_i4
    REAL(wp), ALLOCATABLE :: table_gaps(:)         ! Gap values
    REAL(wp), ALLOCATABLE :: table_conductance(:)  ! Conductance values
    
    !-- Friction heat generation
    LOGICAL :: friction_heat_enabled = .TRUE.      ! Enable frictional heating
    REAL(wp) :: heat_partition_coef = 0.5_wp       ! Heat partition to master (0~1)
    
    !-- Temperature-dependent friction
    INTEGER(i4) :: friction_temp_model = PH_FRICTION_TEMP_LINEAR
    REAL(wp) :: friction_ref_temp = 300.0_wp       ! Reference temperature (K)
    REAL(wp) :: friction_temp_coef = -0.001_wp     ! Temp coefficient (1/K)
    REAL(wp) :: friction_min_temp = 200.0_wp       ! Min friction temperature
    REAL(wp) :: friction_max_temp = 800.0_wp       ! Max friction temperature
    
    !-- Temperature table for friction (for table lookup)
    INTEGER(i4) :: n_friction_table_points = 0_i4
    REAL(wp), ALLOCATABLE :: friction_temp_table(:)    ! Temperature points
    REAL(wp), ALLOCATABLE :: friction_coef_table(:)    ! Friction coef values
    
    !-- Radiation (optional)
    LOGICAL :: radiation_enabled = .FALSE.
    REAL(wp) :: emissivity_master = 0.9_wp
    REAL(wp) :: emissivity_slave = 0.9_wp
    REAL(wp) :: ambient_temp = 300.0_wp
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_Desc_Init
    PROCEDURE :: Set_Conductance => PH_Thermal_Cont_Desc_SetConductance
    PROCEDURE :: Set_FrictionTemp => PH_Thermal_Cont_Desc_SetFrictionTemp
    
  END TYPE PH_Thermal_Cont_Desc
```

### `PH_Thermal_Cont_State` (lines 88–124)

```fortran
  TYPE, PUBLIC :: PH_Thermal_Cont_State
    !-- Temperature field
    REAL(wp), ALLOCATABLE :: temp_master(:)        ! Master surface temperatures
    REAL(wp), ALLOCATABLE :: temp_slave(:)         ! Slave surface temperatures
    REAL(wp), ALLOCATABLE :: temp_jump(:)          ! Temperature jump across interface
    
    !-- Heat flux
    REAL(wp), ALLOCATABLE :: heat_flux_normal(:)   ! Normal heat flux (W/m²)
    REAL(wp), ALLOCATABLE :: heat_flux_friction(:) ! Frictional heat generation
    REAL(wp), ALLOCATABLE :: heat_flux_total(:)    ! Total heat flux
    
    !-- Contact conductance (current state)
    REAL(wp), ALLOCATABLE :: conductance(:)        ! Current conductance per node
    
    !-- Gap distance (for conductance calculation)
    REAL(wp), ALLOCATABLE :: gap_distance(:)       ! Current gap per node
    
    !-- Friction heat partition
    REAL(wp), ALLOCATABLE :: heat_to_master(:)     ! Heat fraction to master
    REAL(wp), ALLOCATABLE :: heat_to_slave(:)      ! Heat fraction to slave
    
    !-- State variables
    INTEGER(i4) :: n_nodes = 0_i4
    LOGICAL :: initialized = .FALSE.
    
    !-- Statistics
    REAL(wp) :: total_heat_generation = 0.0_wp     ! Total frictional heat
    REAL(wp) :: max_temperature = 0.0_wp           ! Max temperature in step
    REAL(wp) :: avg_conductance = 0.0_wp           ! Average conductance
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_State_Init
    PROCEDURE :: Update_Temperature => PH_Thermal_Cont_State_UpdateTemp
    PROCEDURE :: Compute_HeatFlux => PH_Thermal_Cont_State_ComputeHeatFlux
    
  END TYPE PH_Thermal_Cont_State
```

### `PH_Thermal_Cont_Algo` (lines 130–160)

```fortran
  TYPE, PUBLIC :: PH_Thermal_Cont_Algo
    !-- Thermal time integration
    REAL(wp) :: thermal_time_integrator = 1_i4     ! 1=Forward Euler, 2=Crank-Nicolson
    REAL(wp) :: theta_factor = 0.5_wp              ! CN factor (0.5 = trapezoidal)
    
    !-- Conductance linearization
    LOGICAL :: linearize_conductance = .TRUE.      ! Tangent stiffness
    REAL(wp) :: conductance_tolerance = 1.0e-6_wp  ! Linearization tolerance
    
    !-- Friction heat smoothing
    LOGICAL :: smooth_friction_heat = .TRUE.       ! Time smoothing
    REAL(wp) :: smoothing_factor = 0.1_wp          ! Exponential smoothing
    
    !-- Temperature update
    INTEGER(i4) :: temp_update_scheme = 1_i4       ! 1=Explicit, 2=Semi-implicit
    REAL(wp) :: temp_relaxation = 0.8_wp           ! Relaxation factor
    
    !-- Convergence criteria
    REAL(wp) :: temp_residual_tolerance = 1.0e-4_wp ! Temperature residual
    INTEGER(i4) :: max_thermal_iterations = 50_i4  ! Max thermal iterations
    
    !-- Performance tuning
    LOGICAL :: adaptive_conductance = .TRUE.       ! Auto-tune conductance
    REAL(wp) :: conductance_scale_factor = 1.0_wp  ! Global scaling
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_Algo_Init
    PROCEDURE :: Set_TimeIntegrator => PH_Thermal_Cont_Algo_SetTimeIntegrator
    
  END TYPE PH_Thermal_Cont_Algo
```

### `PH_ThermalCont_Inc_Evo_Ctx` (lines 173–176)

```fortran
  TYPE, PUBLIC :: PH_ThermalCont_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_ThermalCont_Inc_Evo_Ctx
```

### `PH_Thermal_Cont_Ctx` (lines 178–212)

```fortran
  TYPE, PUBLIC :: PH_Thermal_Cont_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_ThermalCont_Inc_Evo_Ctx) :: inc  ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: step_idx = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4) :: incr_idx = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4) :: iter_idx = 0_i4
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dt = 0.0_wp
    REAL(wp) :: current_temp_ref = 0.0_wp
    
    !-- Temporary buffers (pre-allocated, no dynamic allocation)
    REAL(wp), POINTER :: temp_buffer_master(:) => NULL()
    REAL(wp), POINTER :: temp_buffer_slave(:) => NULL()
    REAL(wp), POINTER :: flux_buffer(:) => NULL()
    
    !-- Working arrays pointers
    REAL(wp), POINTER :: work1(:) => NULL()
    REAL(wp), POINTER :: work2(:) => NULL()
    INTEGER(i4), POINTER :: iwork1(:) => NULL()
    
    !-- Flags
    LOGICAL :: first_call = .TRUE.
    LOGICAL :: need_recompute = .FALSE.
    LOGICAL :: converged = .FALSE.
    
    !-- Debug output
    INTEGER(i4) :: print_level = 0_i4              ! 0=None, 1=Summary, 2=Full
    
  CONTAINS
    
    PROCEDURE :: Init => PH_Thermal_Cont_Ctx_Init
    PROCEDURE :: Set_Buffers => PH_Thermal_Cont_Ctx_SetBuffers
    
  END TYPE PH_Thermal_Cont_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Thermal_Cont_Desc_Init` | 219 | `SUBROUTINE PH_Thermal_Cont_Desc_Init(this, status)` |
| SUBROUTINE | `PH_Thermal_Cont_Desc_SetConductance` | 253 | `SUBROUTINE PH_Thermal_Cont_Desc_SetConductance(this, model, cond_const, &` |
| SUBROUTINE | `PH_Thermal_Cont_Desc_SetFrictionTemp` | 274 | `SUBROUTINE PH_Thermal_Cont_Desc_SetFrictionTemp(this, model, ref_temp, &` |
| SUBROUTINE | `PH_Thermal_Cont_State_Init` | 293 | `SUBROUTINE PH_Thermal_Cont_State_Init(this, n_nodes, status)` |
| SUBROUTINE | `PH_Thermal_Cont_State_UpdateTemp` | 343 | `SUBROUTINE PH_Thermal_Cont_State_UpdateTemp(this, temp_master, temp_slave, status)` |
| SUBROUTINE | `PH_Thermal_Cont_State_ComputeHeatFlux` | 374 | `SUBROUTINE PH_Thermal_Cont_State_ComputeHeatFlux(this, status)` |
| SUBROUTINE | `PH_Thermal_Cont_Algo_Init` | 400 | `SUBROUTINE PH_Thermal_Cont_Algo_Init(this, status)` |
| SUBROUTINE | `PH_Thermal_Cont_Algo_SetTimeIntegrator` | 426 | `SUBROUTINE PH_Thermal_Cont_Algo_SetTimeIntegrator(this, scheme, theta, status)` |
| SUBROUTINE | `PH_Thermal_Cont_Ctx_Init` | 449 | `SUBROUTINE PH_Thermal_Cont_Ctx_Init(this, status)` |
| SUBROUTINE | `PH_Thermal_Cont_Ctx_SetBuffers` | 483 | `SUBROUTINE PH_Thermal_Cont_Ctx_SetBuffers(this, temp_m, temp_s, flux, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
