# `PH_Elem_B31Dynamics.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31Dynamics.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B31Dynamics`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31Dynamics`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31Dynamics`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31Dynamics.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_Dyn_Desc_Type` (lines 28–55)

```fortran
TYPE :: B31_Dyn_Desc_Type
  ! Time integration parameters
  REAL(wp) :: dt                       ! Time step size
  REAL(wp) :: t_total                  ! Total analysis time
  INTEGER(i4) :: n_steps                  ! Number of time steps
  
  ! Newmark parameters
  REAL(wp) :: beta                     ! Newmark β parameter (default 1/4)
  REAL(wp) :: gamma                    ! Newmark γ parameter (default 1/2)
  
  ! HHT-α parameters
  REAL(wp) :: alpha_hht                ! HHT-α parameter (default -0.1 to 0)
  REAL(wp) :: rho_inf                  ! Spectral radius at infinity
  
  ! Damping parameters
  INTEGER(i4) :: damping_type             ! 1=Rayleigh, 2=Modal, 3=Caughey
  REAL(wp) :: zeta_1                   ! Damping ratio for mode 1
  REAL(wp) :: zeta_2                   ! Damping ratio for mode 2
  REAL(wp) :: mass_prop                ! Mass-proportional damping (α_R)
  REAL(wp) :: stiffness_prop           ! Stiffness-proportional damping (β_R)
  
  ! Modal analysis
  INTEGER(i4) :: n_modes_requested        ! Number of modes for superposition
  REAL(wp) :: freq_cutoff              ! Frequency cutoff for truncation
  
  ! Algorithm selection
  CHARACTER(len=16) :: method          ! 'NEWMARK', 'HHT', 'EXPLICIT'
END TYPE B31_Dyn_Desc_Type
```

### `B31_Dyn_State_Type` (lines 57–93)

```fortran
TYPE :: B31_Dyn_State_Type
  ! Time variables
  REAL(wp) :: time_current             ! Current time
  REAL(wp) :: time_prev                ! Previous time
  REAL(wp) :: dt_current               ! Current time step
  
  ! Displacement state
  REAL(wp) :: u_n(:)                   ! Displacement at time t_n
  REAL(wp) :: u_np1(:)                 ! Displacement at time t_{n+1}
  REAL(wp) :: u_nm1(:)                 ! Displacement at time t_{n-1}
  
  ! Velocity state
  REAL(wp) :: v_n(:)                   ! Velocity at time t_n
  REAL(wp) :: v_np1(:)                 ! Velocity at time t_{n+1}
  REAL(wp) :: a_n(:)                   ! Acceleration at time t_n
  REAL(wp) :: a_np1(:)                 ! Acceleration at time t_{n+1}
  
  ! Modal coordinates
  REAL(wp), ALLOCATABLE :: q_n(:)      ! Modal displacements
  REAL(wp), ALLOCATABLE :: q_dot_n(:)  ! Modal velocities
  REAL(wp), ALLOCATABLE :: q_ddot_n(:) ! Modal accelerations
  
  ! Natural frequencies and modes
  REAL(wp), ALLOCATABLE :: omega_n(:)  ! Natural frequencies ω_i
  REAL(wp), ALLOCATABLE :: phi_modes(:,:,:) ! Mode shapes
  
  ! Response history
  REAL(wp), ALLOCATABLE :: disp_history(:,:)  ! (time, DOF)
  REAL(wp), ALLOCATABLE :: vel_history(:,:)   ! (time, DOF)
  REAL(wp), ALLOCATABLE :: accel_history(:,:) ! (time, DOF)
  
  ! Energy quantities
  REAL(wp) :: kinetic_energy           ! Kinetic energy
  REAL(wp) :: strain_energy            ! Strain energy
  REAL(wp) :: work_external            ! Work by external forces
  REAL(wp) :: energy_dissipated        ! Dissipated energy
END TYPE B31_Dyn_State_Type
```

### `B31_Dyn_AlgoCtx_Type` (lines 95–131)

```fortran
TYPE :: B31_Dyn_AlgoCtx_Type
  ! Effective stiffness matrices
  REAL(wp) :: K_eff(:,:)               ! Effective stiffness matrix
  REAL(wp) :: K_dyn(:,:)               ! Dynamic stiffness (K + c1*M + c2*C)
  REAL(wp) :: M_matrix(:,:)            ! Mass matrix
  REAL(wp) :: C_matrix(:,:)            ! Damping matrix
  
  ! Load vectors
  REAL(wp) :: F_ext_n(:)               ! External load at t_n
  REAL(wp) :: F_ext_np1(:)             ! External load at t_{n+1}
  REAL(wp) :: F_int(:)                 ! Internal force vector
  REAL(wp) :: F_eff(:)                 ! Effective load vector
  
  ! Integration constants
  REAL(wp) :: c0, c1, c2, c3           ! Newmark constants
  REAL(wp) :: c4, c5, c6, c7           ! Additional constants
  REAL(wp) :: alpha_m, alpha_f         ! HHT-α parameters
  
  ! Iteration variables
  INTEGER(i4) :: nr_iter                  ! Newton-Raphson iterations
  REAL(wp) :: residual_norm            ! Residual norm
  LOGICAL  :: converged                ! Convergence flag
  
  ! Modal workspace
  REAL(wp) :: modal_force(:)           ! Modal force vector
  REAL(wp) :: modal_damping(:)         ! Modal damping ratios
  REAL(wp) :: participation_factors(:) ! Modal participation factors
  
  ! Temporary arrays
  REAL(wp) :: temp_n(:)                ! Temporary vector
  REAL(wp) :: temp_m(:,:)              ! Temporary matrix
  
  ! Statistics
  INTEGER(i4) :: total_steps              ! Completed steps
  INTEGER(i4) :: failed_steps             ! Failed steps
  REAL(wp) :: cpu_time                 ! CPU time
END TYPE B31_Dyn_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_Dyn_Initialize` | 146 | `SUBROUTINE PH_Elem_B31_Dyn_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_NewmarkBeta` | 257 | `SUBROUTINE PH_Elem_B31_Dyn_NewmarkBeta(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_HHTAlpha` | 383 | `SUBROUTINE PH_Elem_B31_Dyn_HHTAlpha(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_ModalSuperposition` | 463 | `SUBROUTINE PH_Elem_B31_Dyn_ModalSuperposition(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_TransientResponse` | 572 | `SUBROUTINE PH_Elem_B31_Dyn_TransientResponse(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_ComputeEigenfrequencies` | 643 | `SUBROUTINE PH_Elem_B31_Dyn_ComputeEigenfrequencies(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_RayleighDamping` | 704 | `SUBROUTINE PH_Elem_B31_Dyn_RayleighDamping(&` |
| SUBROUTINE | `PH_Elem_B31_Dyn_SolveLinearSystem` | 750 | `SUBROUTINE PH_Elem_B31_Dyn_SolveLinearSystem(A, b, x, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
