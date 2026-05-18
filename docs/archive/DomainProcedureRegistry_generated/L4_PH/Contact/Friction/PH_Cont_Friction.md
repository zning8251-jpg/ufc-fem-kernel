# `PH_Cont_Friction.f90`

- **Source**: `L4_PH/Contact/Friction/PH_Cont_Friction.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_Friction`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Friction`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_Friction`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Friction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Friction/PH_Cont_Friction.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Cont_FrictModel` (lines 32–40)

```fortran
  TYPE, PUBLIC :: PH_Cont_FrictModel
    INTEGER(i4) :: model_type = PH_FRICT_COULOMB
    REAL(wp)    :: mu_static  = 0.3_wp       ! Static friction coef
    REAL(wp)    :: mu_kinetic = 0.2_wp       ! Kinetic friction coef
    REAL(wp)    :: critical_slip = 1.0e-6_wp ! Critical slip distance
    REAL(wp)    :: velocity_scale  = 1.0e-3_wp ! Velocity scale parameter
    REAL(wp)    :: pressure_ref    = 1.0_wp    ! Reference pressure
    REAL(wp)    :: pressure_exponent = 0.0_wp  ! Pressure exponent
  END TYPE PH_Cont_FrictModel
```

### `PH_Cont_FrictState` (lines 43–50)

```fortran
  TYPE, PUBLIC :: PH_Cont_FrictState
    REAL(wp) :: normal_force    = 0.0_wp
    REAL(wp) :: tangent_vel(3)  = [0.0_wp, 0.0_wp, 0.0_wp]
    REAL(wp) :: slip_distance   = 0.0_wp
    REAL(wp) :: friction_force(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    LOGICAL  :: is_sticking     = .TRUE.
    LOGICAL  :: is_sliding      = .FALSE.
  END TYPE PH_Cont_FrictState
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ContFric_Coulomb` | 67 | `SUBROUTINE PH_ContFric_Coulomb(frict_model, frict_state, normal_force, &` |
| SUBROUTINE | `PH_ContFric_StickSlip` | 122 | `SUBROUTINE PH_ContFric_StickSlip(frict_model, frict_state, normal_force, &` |
| SUBROUTINE | `PH_ContFric_Regularized` | 179 | `SUBROUTINE PH_ContFric_Regularized(frict_model, frict_state, normal_force, &` |
| SUBROUTINE | `PH_ContFric_VelocityDep` | 226 | `SUBROUTINE PH_ContFric_VelocityDep(frict_model, frict_state, normal_force, &` |
| SUBROUTINE | `PH_ContFric_PressureDep` | 276 | `SUBROUTINE PH_ContFric_PressureDep(frict_model, frict_state, normal_force, &` |
| SUBROUTINE | `PH_ContFric_TangentStiff` | 325 | `SUBROUTINE PH_ContFric_TangentStiff(frict_model, frict_state, normal_force, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
