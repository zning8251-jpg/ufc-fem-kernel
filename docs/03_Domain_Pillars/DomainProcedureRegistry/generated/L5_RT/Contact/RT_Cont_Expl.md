# `RT_Cont_Expl.f90`

- **Source**: `L5_RT/Contact/RT_Cont_Expl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Cont_Expl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_Expl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont_Expl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_Expl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Cont_Pair` (lines 53–61)

```fortran
  type, public :: RT_Cont_Pair
    integer(i4) :: master_surface = 0_i4
    integer(i4) :: slave_surface_i = 0_i4
    integer(i4) :: n_contacts = 0_i4
    integer(i4), allocatable :: contact_node_id(:)  ! Slave node IDs in contact
    real(wp), allocatable :: penetrations(:)          ! Penetration depths
    real(wp), allocatable :: contact_normals(:,:)     ! Contact normals (n_contacts, 3)
    logical :: is_active = .false.
  end type RT_Cont_Pair
```

### `RT_Cont_Expl_Cfg` (lines 66–89)

```fortran
  type, public :: RT_Cont_Expl_Cfg
    ! Contact search
    logical :: search_every_st = .true.   ! Search every time step
    real(wp) :: search_toleranc = 1.0e-6_wp ! Search tolerance
    
    ! Contact force
    real(wp) :: penalty_stiffne = 1.0e6_wp ! Penalty stiffness
    logical :: use_adaptive_pe = .false. ! Adaptive penalty
    real(wp) :: min_penalty = 1.0e4_wp      ! Minimum penalty
    real(wp) :: max_penalty = 1.0e8_wp      ! Maximum penalty
    
    ! Contact stabilization (Phase 8 E3.1: normal/tangential damping)
    logical :: use_damping = .false.        ! Use contact damping
    real(wp) :: damping_coeffic = 0.1_wp   ! Default (legacy) damping
    real(wp) :: damping_normal = 0.1_wp      ! E3.1: Normal direction damping
    real(wp) :: damping_tangent = 0.0_wp ! E3.1: Tangential damping (optional)
    ! E3.2: Superposition: .true. = add to Mat damping; .false. = replace in contact zone
    logical :: damping_add_to = .true.
    ! Phase 8 E4.1: Search frequency (search every search_interval steps; 1 = every step)
    integer(i4) :: search_interval = 1_i4
    
    ! Statistics
    logical :: track_statistic = .true.    ! Track contact statistics
  end type RT_Cont_Expl_Cfg
```

### `RT_Cont_Expl_State` (lines 94–114)

```fortran
  type, public :: RT_Cont_Expl_State
    ! Contact pairs
    integer(i4) :: nContPairs = 0_i4
    type(RT_Cont_Pair), allocatable :: contact_pairs(:)
    
    ! Contact forces
    real(wp), allocatable :: F_contact(:)  ! Contact forces (n_dofs)
    
    ! Contact energy (Phase 8 E2.1: energy monitoring)
    real(wp) :: E_contact = 0.0_wp         ! Contact energy
    real(wp) :: work_contact = 0.0_wp      ! Work done by contact forces (integral F·v dt)
    
    ! Statistics
    integer(i4) :: n_total_contact = 0_i4 ! Total contact points
    integer(i4) :: n_search_calls = 0_i4   ! Number of search calls
    real(wp) :: max_penetration = 0.0_wp   ! Maximum penetration
    ! Phase 8 E4: step counter for search interval
    integer(i4) :: step_count = 0_i4
    
    LOGICAL :: init = .false.
  end type RT_Cont_Expl_State
```

### `RT_Cont_Expl_Solv` (lines 119–133)

```fortran
  type, public :: RT_Cont_Expl_Solv
    type(RT_Cont_Expl_Cfg) :: config
    type(RT_Cont_Expl_State) :: state
    
    integer(i4) :: n_dofs = 0_i4            ! Number of DOFs
    
    LOGICAL :: init = .false.
  contains
    procedure :: Init
    procedure :: Search
    procedure :: ComputeForce
    procedure :: ComputeEnergy
    procedure :: GetStatistics
    procedure :: Cleanup
  end type RT_Cont_Expl_Solv
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_ContExpl_Solv_Init` | 145 | `subroutine RT_ContExpl_Solv_Init(this, n_dofs, config, status)` |
| SUBROUTINE | `RT_ContExpl_Solv_Search` | 186 | `subroutine RT_ContExpl_Solv_Search(this, coords, surfaces, status)` |
| SUBROUTINE | `RT_ContExpl_Solv_ComputeForce` | 340 | `subroutine RT_ContExpl_Solv_ComputeForce(this, coords, u, v, F_contact, status, dt)` |
| SUBROUTINE | `RT_ContExpl_Solv_CompEnergy` | 448 | `subroutine RT_ContExpl_Solv_CompEnergy(this, E_contact, status)` |
| SUBROUTINE | `RT_ContExpl_Solv_GetStats` | 471 | `subroutine RT_ContExpl_Solv_GetStats(this, n_contacts, max_penetration, n_searches)` |
| SUBROUTINE | `RT_ContExpl_CriticalTimeStep` | 487 | `subroutine RT_ContExpl_CriticalTimeStep(penalty_stiffness, mass_min, dt_crit, status)` |
| SUBROUTINE | `RT_ContExpl_GetEnergyStats` | 505 | `subroutine RT_ContExpl_GetEnergyStats(this, E_contact, work_contact, energy_error, status)` |
| SUBROUTINE | `RT_ContExpl_ShouldSearchThisStep` | 532 | `subroutine RT_ContExpl_ShouldSearchThisStep(this, do_search, status)` |
| SUBROUTINE | `RT_ContExpl_AdvanceStepCount` | 544 | `subroutine RT_ContExpl_AdvanceStepCount(this)` |
| SUBROUTINE | `RT_ContExpl_Solv_Cleanup` | 550 | `subroutine RT_ContExpl_Solv_Cleanup(this)` |
| SUBROUTINE | `RT_ContExpl_Init` | 586 | `subroutine RT_ContExpl_Init(solver, n_dofs, config, status)` |
| SUBROUTINE | `RT_ContExpl_Search` | 596 | `subroutine RT_ContExpl_Search(solver, coords, surfaces, status)` |
| SUBROUTINE | `RT_ContExpl_CompForce` | 606 | `subroutine RT_ContExpl_CompForce(solver, coords, u, v, F_contact, status, dt)` |
| SUBROUTINE | `RT_ContExpl_CompEnergy` | 619 | `subroutine RT_ContExpl_CompEnergy(solver, E_contact, status)` |
| SUBROUTINE | `RT_ContExpl_GetStat` | 628 | `subroutine RT_ContExpl_GetStat(solver, n_contacts, max_penetration, n_searches)` |
| SUBROUTINE | `RT_ContExpl_Clean` | 638 | `subroutine RT_ContExpl_Clean(solver)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
