# `PH_Elem_AcousticTransientSolv.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AcousticTransientSolv.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_AcousticTransientSolv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AcousticTransientSolv`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AcousticTransientSolv`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AcousticTransientSolv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Acoustic_Newmark_Ctx` (lines 36–82)

```fortran
  TYPE, PUBLIC :: PH_Acoustic_Newmark_Ctx
    !! Context type for Newmark-β transient solver
    !! Stores time integration parameters and state
    
    !-- Time stepping parameters
    REAL(wp) :: dt           ! Time step size [s]
    REAL(wp) :: dt_min       ! Minimum allowed time step [s]
    REAL(wp) :: dt_max       ! Maximum allowed time step [s]
    REAL(wp) :: t_current    ! Current time [s]
    REAL(wp) :: t_end        ! End time [s]
    INTEGER(i4) :: n_steps   ! Number of time steps
    
    !-- Newmark parameters
    REAL(wp) :: gamma        ! γ parameter (default: 0.5)
    REAL(wp) :: beta         ! β parameter (default: 0.25)
    
    !-- Integration constants (pre-computed for efficiency)
    REAL(wp) :: c0, c1, c2, c3, c4, c5  ! Newmark constants
    
    !-- Adaptive time stepping control (P3-9)
    LOGICAL :: adaptive      ! .TRUE. for adaptive time stepping
    REAL(wp) :: tol_local    ! Local error tolerance (default: 1.0e-3)
    REAL(wp) :: safety       ! Safety factor (default: 0.9)
    REAL(wp) :: beta_adapt   ! Step size adjustment exponent (default: 0.2)
    REAL(wp) :: eta_max      ! Max step size ratio (default: 5.0)
    REAL(wp) :: eta_min      ! Min step size ratio (default: 0.2)
    
    !-- Rollback control (P3-12)
    INTEGER(i4) :: max_rollback   ! Max consecutive rejections (default: 5)
    REAL(wp) :: dt_emergency    ! Emergency minimum dt (fallback)
    
    !-- HHT-α parameters (P3-14)
    LOGICAL :: use_hht          ! .TRUE. to enable HHT-α method
    REAL(wp) :: alpha_hht       ! α parameter for HHT (default: 0.0 = Newmark)
    REAL(wp) :: rho_inf         ! Spectral radius at infinity (controls high-freq dissipation)
    
    !-- Thermo-acoustic coupling (P5-1)
    LOGICAL :: use_thermo_coupling  ! .TRUE. to enable temperature-dependent acoustics
    REAL(wp) :: T_ref             ! Reference temperature T₀ [K]
    REAL(wp) :: c0_ref            ! Reference sound speed c₀ at T₀ [m/s]
    REAL(wp), POINTER :: T_field(:) ! Pointer to temperature field [K] (from thermal solver)
    
    !-- Convergence control
    REAL(wp) :: tol_nr       ! Newton-Raphson tolerance
    INTEGER(i4) :: max_iter_nr ! Max NR iterations
    
  END TYPE PH_Acoustic_Newmark_Ctx
```

### `PH_Acoustic_Transient_State` (lines 87–127)

```fortran
  TYPE, PUBLIC :: PH_Acoustic_Transient_State
    !! State variables for transient analysis
    
    !-- Solution vectors at current time step
    REAL(wp), ALLOCATABLE :: p(:)      ! Pressure [Pa]
    REAL(wp), ALLOCATABLE :: dp(:)     ! Velocity ṗ [Pa/s]
    REAL(wp), ALLOCATABLE :: ddp(:)    ! Acceleration p̈ [Pa/s²]
    
    !-- Solution vectors at next time step (n+1)
    REAL(wp), ALLOCATABLE :: p_np1(:)
    REAL(wp), ALLOCATABLE :: dp_np1(:)
    REAL(wp), ALLOCATABLE :: ddp_np1(:)
    
    !-- Predictors (for predictor-corrector scheme)
    REAL(wp), ALLOCATABLE :: p_pred(:)
    REAL(wp), ALLOCATABLE :: dp_pred(:)
    
    !-- Error estimation vectors (P3-9 adaptive time stepping)
    REAL(wp), ALLOCATABLE :: p_low_order(:)   ! Lower order solution (for error est.)
    REAL(wp), ALLOCATABLE :: local_error(:)   ! Local truncation error estimate
    
    !-- Rollback state (P3-12 for rejected step handling)
    REAL(wp), ALLOCATABLE :: p_old(:)         ! Saved state at t_n
    REAL(wp), ALLOCATABLE :: dp_old(:)        ! Saved velocity at t_n
    REAL(wp), ALLOCATABLE :: ddp_old(:)       ! Saved acceleration at t_n
    INTEGER(i4) :: rollback_count = 0_i4      ! Consecutive rejection counter
    
    !-- Residual and tangent
    REAL(wp), ALLOCATABLE :: residual(:)
    REAL(wp), ALLOCATABLE :: tangent(:,:)
    
    !-- External force
    REAL(wp), ALLOCATABLE :: F_ext(:)
    
    !-- Status
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: current_step = 0_i4
    REAL(wp) :: current_time = 0.0_wp
    REAL(wp) :: last_error_norm = 0.0_wp  ! Error norm from previous step
    
  END TYPE PH_Acoustic_Transient_State
```

### `PH_Acoustic_Unified_Analysis_Ctx` (lines 999–1055)

```fortran
  TYPE, PUBLIC :: PH_Acoustic_Unified_Analysis_Ctx
    !! Unified context for both frequency and time domain acoustic analysis
    !!
    !! Design: Single interface for dual physics (P6-2)
    !!   - Frequency domain: Helmholtz equation (-ω²M + iωC + K)p = F
    !!   - Time domain: M·p̈ + C·ṗ + K·p = F(t)
    !!
    !! Shared data:
    !!   - Mass, Damping, Stiffness matrices
    !!   - Material properties (density, bulk modulus)
    !!   - Boundary conditions
    !!   - Thermo-acoustic coupling parameters
    !!
    !! Analysis-specific:
    !!   - Frequency: ω, n_freqs, complex arithmetic
    !!   - Time: dt, t_end, Newmark/HHT parameters
    
    !-- Common acoustic properties
    REAL(wp) :: density           ! ρ [kg/m³]
    REAL(wp) :: bulk_modulus      ! K [Pa]
    REAL(wp) :: sound_speed       ! c = √(K/ρ) [m/s]
    
    !-- Analysis type selector
    LOGICAL :: is_frequency_domain = .FALSE.  ! .TRUE.=freq, .FALSE.=time
    
    !-- Frequency domain parameters
    REAL(wp) :: omega             ! Angular frequency ω [rad/s]
    REAL(wp) :: frequency         ! Frequency f [Hz]
    INTEGER(i4) :: n_frequencies  ! Number of freq points for sweep
    REAL(wp), POINTER :: freq_array(:) => NULL() ! Frequency array [n_freqs]
    
    !-- Time domain parameters (embedded Newmark ctx)
    REAL(wp) :: dt                ! Time step [s]
    REAL(wp) :: t_end             ! End time [s]
    REAL(wp) :: gamma             ! Newmark γ
    REAL(wp) :: beta              ! Newmark β
    LOGICAL :: use_hht            ! HHT-α flag
    REAL(wp) :: rho_inf           ! Spectral radius
    
    !-- Thermo-acoustic coupling (shared)
    LOGICAL :: use_thermo_coupling
    REAL(wp) :: T_ref             ! Reference temperature [K]
    REAL(wp) :: c0_ref            ! Reference sound speed [m/s]
    REAL(wp), POINTER :: T_field(:) ! Temperature field [K]
    
    !-- Porous media (Biot theory) - shared
    LOGICAL :: use_porous_media
    REAL(wp) :: porosity          ! φ [0-1]
    REAL(wp) :: permeability      ! κ [m²]
    REAL(wp) :: tortuosity        ! τ
    
    !-- Absorbing boundary (PML/Sommerfeld) - shared
    LOGICAL :: use_pml            ! Perfectly Matched Layer
    LOGICAL :: use_sommerfeld     ! Sommerfeld radiation condition
    REAL(wp) :: pml_thickness     ! PML layer thickness [m]
    
  END TYPE PH_Acoustic_Unified_Analysis_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `sprintf` | 134 | `FUNCTION sprintf(fmt, var1, var2, var3, var4, var5) RESULT(str)` |
| SUBROUTINE | `GAUSSIAN_ELIMINATION` | 177 | `SUBROUTINE GAUSSIAN_ELIMINATION(A, b, x, info)` |
| SUBROUTINE | `Solve_Linear_System_LAPACK` | 225 | `SUBROUTINE Solve_Linear_System_LAPACK(A, b, x, status)` |
| SUBROUTINE | `PH_Acoustic_NewmarkBeta_Init` | 254 | `SUBROUTINE PH_Acoustic_NewmarkBeta_Init(ctx, dt, t_end, gamma_in, beta_in, &` |
| SUBROUTINE | `PH_Acoustic_Transient_State_Init` | 350 | `SUBROUTINE PH_Acoustic_Transient_State_Init(state, n_dof, status)` |
| SUBROUTINE | `PH_Acoustic_NewmarkBeta_SolveStep` | 392 | `SUBROUTINE PH_Acoustic_NewmarkBeta_SolveStep(ctx, state, Mass, Damping, Stiffness, &` |
| SUBROUTINE | `SOLVE_LINEAR_SYSTEM` | 561 | `SUBROUTINE SOLVE_LINEAR_SYSTEM(A, b, x, status)` |
| SUBROUTINE | `PH_Acoustic_Compute_Local_Error` | 591 | `SUBROUTINE PH_Acoustic_Compute_Local_Error(state, ctx, error_norm, eta)` |
| SUBROUTINE | `PH_Acoustic_Adapt_Time_Step` | 657 | `SUBROUTINE PH_Acoustic_Adapt_Time_Step(ctx, eta, accepted, dt_new, status)` |
| SUBROUTINE | `PH_Acoustic_Save_State` | 737 | `SUBROUTINE PH_Acoustic_Save_State(state)` |
| SUBROUTINE | `PH_Acoustic_Rollback_State` | 764 | `SUBROUTINE PH_Acoustic_Rollback_State(state, ctx, status)` |
| SUBROUTINE | `PH_Acoustic_Reset_Rollback_Counter` | 804 | `SUBROUTINE PH_Acoustic_Reset_Rollback_Counter(state)` |
| SUBROUTINE | `PH_Acoustic_HHT_Parameters` | 816 | `SUBROUTINE PH_Acoustic_HHT_Parameters(ctx, rho_inf_in)` |
| FUNCTION | `Get_HHT_Alpha` | 864 | `PURE FUNCTION Get_HHT_Alpha(ctx) RESULT(alpha_eff)` |
| SUBROUTINE | `PH_Acoustic_Update_Speed_of_Sound` | 882 | `SUBROUTINE PH_Acoustic_Update_Speed_of_Sound(ctx, bulk_modulus, density, c_current, status)` |
| SUBROUTINE | `PH_Acoustic_Setup_Thermo_Coupling` | 951 | `SUBROUTINE PH_Acoustic_Setup_Thermo_Coupling(ctx, c0_ref_in, T_ref_in, T_field_ptr, status)` |
| SUBROUTINE | `PH_Acoustic_Frequency_Domain_Solve` | 1060 | `SUBROUTINE PH_Acoustic_Frequency_Domain_Solve(ctx, Mass, Damping, Stiffness, &` |
| SUBROUTINE | `Solve_Complex_System_LAPACK` | 1124 | `SUBROUTINE Solve_Complex_System_LAPACK(A, b, x, n, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
