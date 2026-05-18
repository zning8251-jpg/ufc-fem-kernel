# `PH_Cont_WearEvolution.f90`

- **Source**: `L4_PH/Contact/Wear/PH_Cont_WearEvolution.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_WearEvolution`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_WearEvolution`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_WearEvolution`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Wear`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Wear/PH_Cont_WearEvolution.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ContWE_WearLaw` (lines 40–50)

```fortran
  TYPE :: PH_ContWE_WearLaw
    ! Wear model parameters
    INTEGER(i4) :: law_type        ! 1=Archard, 2=Energy, 3=Modified
    REAL(wp) :: wear_coeff         ! Wear coefficient k_w or k_e
    REAL(wp) :: hardness           ! Material hardness H
    REAL(wp) :: exponent           ! Exponent for modified laws
    REAL(wp) :: threshold_pressure ! Pressure threshold for wear onset
    CHARACTER(LEN=32) :: name      ! Law name
  CONTAINS
    PROCEDURE :: ComputeRate => WearLaw_ComputeRate
  END TYPE PH_ContWE_WearLaw
```

### `PH_ContWE_FrictionEvolution` (lines 52–61)

```fortran
  TYPE :: PH_ContWE_FrictionEvolution
    ! Friction coefficient evolution model
    INTEGER(i4) :: evol_type       ! 1=Exponential decay, 2=Linear, 3=Sigmoid
    REAL(wp) :: mu_initial         ! Initial friction coefficient μ_0
    REAL(wp) :: mu_residual        ! Residual friction after wear μ_res
    REAL(wp) :: decay_rate         ! Decay rate α
    REAL(wp) :: critical_wear      ! Critical wear depth for transition
  CONTAINS
    PROCEDURE :: Evaluate => FrictionEval
  END TYPE PH_ContWE_FrictionEvolution
```

### `PH_ContWE_WearState` (lines 63–73)

```fortran
  TYPE :: PH_ContWE_WearState
    ! Wear state at a contact point
    INTEGER(i4) :: point_id
    REAL(wp) :: wear_depth         ! Accumulated wear depth h_w
    REAL(wp) :: wear_rate          ! Current wear rate dh/dt
    REAL(wp) :: friction_current   ! Current friction coefficient
    REAL(wp) :: dissipated_energy  ! Total dissipated energy
    REAL(wp) :: sliding_distance   ! Total sliding distance
    LOGICAL :: is_active           ! Wear active flag
    REAL(wp) :: last_update_time   ! Time of last update
  END TYPE PH_ContWE_WearState
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `WearLaw_ComputeRate` | 81 | `FUNCTION WearLaw_ComputeRate(this, pressure, slip_speed, temp) RESULT(dh_dt)` |
| SUBROUTINE | `PH_ContWE_ArchardWear` | 116 | `SUBROUTINE PH_ContWE_ArchardWear(state, law, pressure, slip_speed, dt, status)` |
| SUBROUTINE | `PH_ContWE_EnergyBasedWear` | 155 | `SUBROUTINE PH_ContWE_EnergyBasedWear(state, law, tangential_force, &` |
| FUNCTION | `FrictionEval` | 192 | `FUNCTION FrictionEval(this, wear_depth) RESULT(mu)` |
| SUBROUTINE | `PH_ContWE_UpdateFrictionCoeff` | 220 | `SUBROUTINE PH_ContWE_UpdateFrictionCoeff(state, friction_model, status)` |
| SUBROUTINE | `PH_ContWE_ThirdBodyEffect` | 238 | `SUBROUTINE PH_ContWE_ThirdBodyEffect(state, debris_thickness, &` |
| SUBROUTINE | `PH_ContWE_ComputeWearDepth` | 267 | `SUBROUTINE PH_ContWE_ComputeWearDepth(states, n_states, law, pressures, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
