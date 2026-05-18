# `NM_TimeInt_BEAM.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_BEAM.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_TimeInt_BEAM`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_BEAM`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_BEAM`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_BEAM.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `TimeInt_BEAM_Desc_Type` (lines 37–67)

```fortran
TYPE :: TimeInt_BEAM_Desc_Type
    ! Method selection (ADINAM IOPE)
    INTEGER(i4) :: method                 ! 1=Wilson, 2=Newmark, 3=CD, 4=HHT
    
    ! Time step parameters
    REAL(wp) :: dt                     ! Time step size
    REAL(wp) :: dt_initial            ! Initial time step
    REAL(wp) :: t_current             ! Current time
    REAL(wp) :: t_end                 ! End time
    INTEGER(i4) :: step_number           ! Current step number
    INTEGER(i4) :: max_steps             ! Maximum number of steps
    
    ! Wilson-θ parameters
    REAL(wp) :: theta                  ! Wilson parameter (default 1.4)
    
    ! Newmark parameters
    REAL(wp) :: beta                   ! Newmark β parameter
    REAL(wp) :: gamma                 ! Newmark γ parameter
    
    ! HHT-α parameters
    REAL(wp) :: alpha                 ! HHT α parameter (-1/3 <= α <= 0)
    
    ! Rayleigh damping
    REAL(wp) :: alpha_R               ! Mass-proportional damping α
    REAL(wp) :: beta_R                ! Stiffness-proportional damping β
    
    ! Convergence control
    INTEGER(i4) :: max_iterations
    REAL(wp) :: tolerance
    LOGICAL  :: adaptive_dt           ! Adaptive time stepping
END TYPE TimeInt_BEAM_Desc_Type
```

### `TimeInt_BEAM_State_Type` (lines 69–96)

```fortran
TYPE :: TimeInt_BEAM_State_Type
    ! Displacement, velocity, acceleration at time t
    REAL(wp) :: u_t(12)               ! Displacement
    REAL(wp) :: v_t(12)               ! Velocity
    REAL(wp) :: a_t(12)               ! Acceleration
    
    ! Quantities at time t+dt
    REAL(wp) :: u_tdt(12)             ! Displacement
    REAL(wp) :: v_tdt(12)             ! Velocity
    REAL(wp) :: a_tdt(12)             ! Acceleration
    
    ! Effective quantities for solving
    REAL(wp) :: u_eff(12)             ! Effective displacement
    REAL(wp) :: v_eff(12)             ! Effective velocity
    REAL(wp) :: a_eff(12)             ! Effective acceleration
    
    ! Residual quantities
    REAL(wp) :: R_ext(12)             ! External force
    REAL(wp) :: R_int(12)             ! Internal force
    REAL(wp) :: R_damp(12)            ! Damping force
    REAL(wp) :: R_inertia(12)         ! Inertia force
    REAL(wp) :: R_residual(12)        ! Total residual
    
    ! Energy metrics
    REAL(wp) :: kinetic_energy
    REAL(wp) :: potential_energy
    REAL(wp) :: total_energy
END TYPE TimeInt_BEAM_State_Type
```

### `TimeInt_BEAM_Algo_Type` (lines 98–121)

```fortran
TYPE :: TimeInt_BEAM_Algo_Type
    ! Integration constants (computed from dt and method parameters)
    ! Wilson-θ constants
    REAL(wp) :: a₀, a₁, a₂, a₃, a₄, a₅, a₆, a₇, a₈
    
    ! Newmark constants
    REAL(wp) :: b₀, b₁, b₂, b₃, b₄, b₅, b₆, b₇
    
    ! HHT constants
    REAL(wp) :: h₀, h₁, h₂, h₃, h₄
    
    ! Mass matrix related
    REAL(wp) :: mass_eff(12, 12)      ! Effective mass for solution
    LOGICAL  :: mass_lumped            ! Use lumped mass
    
    ! Damping matrix related
    REAL(wp) :: alpha_damp             ! Rayleigh α coefficient
    REAL(wp) :: beta_damp              ! Rayleigh β coefficient
    
    ! Iteration state
    INTEGER(i4) :: iteration
    LOGICAL  :: converged
    REAL(wp) :: residual_norm
END TYPE TimeInt_BEAM_Algo_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `L2_NM_TimeInt_BEAM_Init` | 140 | `SUBROUTINE L2_NM_TimeInt_BEAM_Init(&` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_UpdateConstants` | 292 | `SUBROUTINE L2_NM_TimeInt_BEAM_UpdateConstants(&` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_Predict` | 354 | `SUBROUTINE L2_NM_TimeInt_BEAM_Predict(&` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_Correct` | 403 | `SUBROUTINE L2_NM_TimeInt_BEAM_Correct(&` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness` | 471 | `SUBROUTINE L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness(&` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_GetAcceleration` | 519 | `SUBROUTINE L2_NM_TimeInt_BEAM_GetAcceleration(&` |
| FUNCTION | `L2_NM_TimeInt_BEAM_GetVelocity` | 566 | `FUNCTION L2_NM_TimeInt_BEAM_GetVelocity(desc, algo, state, a_new) RESULT(v_new)` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_ComputeDampingForce` | 604 | `SUBROUTINE L2_NM_TimeInt_BEAM_ComputeDampingForce(&` |
| SUBROUTINE | `L2_NM_TimeInt_BEAM_Advance` | 631 | `SUBROUTINE L2_NM_TimeInt_BEAM_Advance(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
