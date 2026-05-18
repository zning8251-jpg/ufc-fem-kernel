# `PH_Base_PhysicsUtils.f90`

- **Source**: `L4_PH/Element/Shared/PH_Base_PhysicsUtils.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Base_PhysicsUtils`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Base_PhysicsUtils`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Base_PhysicsUtils`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Base_PhysicsUtils.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_KinematicsArgs` (lines 67–101)

```fortran
    TYPE :: PH_KinematicsArgs
      ! ---- ----
      REAL(wp) :: F(3,3)    = 0.0_wp  !! F
      REAL(wp) :: J         = 1.0_wp  !! det(F)
      REAL(wp) :: W(3,3)    = 0.0_wp  ! spin / rate tensor workspace
      REAL(wp) :: D(3,3)    = 0.0_wp  ! material stiffness (elasticity) matrix ptr
      REAL(wp) :: dt        = 0.0_wp  ! time increment

      ! ---- / ----
      REAL(wp) :: P(3,3)    = 0.0_wp  !! PK
      REAL(wp) :: sigma(3,3)= 0.0_wp  !! Cauchy /
      REAL(wp) :: S(3,3)    = 0.0_wp  !! PK

      ! ---- ----
      REAL(wp) :: sigma_rate(3,3) = 0.0_wp   !! σ̇
      REAL(wp) :: sigma_dot_obj(3,3) = 0.0_wp  ! objective stress rate tensor

      ! ---- ----
      REAL(wp) :: phi_rate   = 0.0_wp        !! φ̇
      REAL(wp) :: velocity(3)= 0.0_wp        !! v
      REAL(wp) :: grad_phi(3)= 0.0_wp        !! ∇�?
      REAL(wp) :: Dphi_Dt    = 0.0_wp        !! Dφ/Dt

      ! ---- ----
      REAL(wp) :: d_epsilon(3,3) = 0.0_wp    !! Δε

      ! ---- ----
      LOGICAL :: compute_cauchy    = .FALSE.  !! Cauchy
      LOGICAL :: compute_pk2       = .FALSE.  !! PK
      LOGICAL :: compute_obj_rate  = .FALSE.! compute Jaumann / objective rate
      LOGICAL :: compute_material_deriv = .FALSE.! compute material time derivative

      ! ---- ----
      TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
    END TYPE PH_KinematicsArgs
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_AlmansiStrain_Calc` | 105 | `SUBROUTINE PH_AlmansiStrain_Calc(F, e, status)` |
| SUBROUTINE | `PH_CauchyGreen_Calc` | 151 | `SUBROUTINE PH_CauchyGreen_Calc(F, C, status)` |
| SUBROUTINE | `PH_CauchyStress_Calc` | 174 | `SUBROUTINE PH_CauchyStress_Calc(P, F, J, sigma, status)` |
| SUBROUTINE | `PH_DeformationGradient_Calc` | 211 | `SUBROUTINE PH_DeformationGradient_Calc(displacement_gradient, F, status)` |
| SUBROUTINE | `PH_DeformationRate_Calc` | 236 | `SUBROUTINE PH_DeformationRate_Calc(velocity_gradient, D, status)` |
| SUBROUTINE | `PH_GreenLagrangeStrain_Calc` | 256 | `SUBROUTINE PH_GreenLagrangeStrain_Calc(C, E, status)` |
| SUBROUTINE | `PH_Ma_Compute` | 280 | `SUBROUTINE PH_Ma_Compute(phi_rate, velocity, &` |
| SUBROUTINE | `PH_MassConservation_Check` | 295 | `SUBROUTINE PH_MassConservation_Check(density_old, density_new, volume_old, &` |
| SUBROUTINE | `PH_Mo_Check` | 321 | `SUBROUTINE PH_Mo_Check(momentum_old, momentum_new, &` |
| SUBROUTINE | `PH_Ob_Apply` | 347 | `SUBROUTINE PH_Ob_Apply(sigma_rate, W, sigma, &` |
| SUBROUTINE | `PH_PiolaKirchhoffStress_Calc` | 360 | `SUBROUTINE PH_PiolaKirchhoffStress_Calc(sigma, F, J, P, S, status)` |
| SUBROUTINE | `PH_PolarDecomposition_Calc` | 417 | `SUBROUTINE PH_PolarDecomposition_Calc(F, R, U, status)` |
| SUBROUTINE | `PH_RotationTensor_Calc` | 459 | `SUBROUTINE PH_RotationTensor_Calc(F, R, status)` |
| SUBROUTINE | `PH_Sort_Eigenvalues` | 473 | `SUBROUTINE PH_Sort_Eigenvalues(eigenvalues, eigenvectors)` |
| SUBROUTINE | `PH_Strain_Invariants` | 497 | `SUBROUTINE PH_Strain_Invariants(strain_tensor, I1, I2, I3)` |
| SUBROUTINE | `PH_Strain_Principal` | 507 | `SUBROUTINE PH_Strain_Principal(strain_tensor, principal_strains, &` |
| SUBROUTINE | `PH_Strain_TensorToVoigt` | 524 | `SUBROUTINE PH_Strain_TensorToVoigt(strain_tensor, strain_voigt, status)` |
| SUBROUTINE | `PH_Strain_VoigtToTensor` | 541 | `SUBROUTINE PH_Strain_VoigtToTensor(strain_voigt, strain_tensor, status)` |
| SUBROUTINE | `PH_StrainIncrement_Calc` | 563 | `SUBROUTINE PH_StrainIncrement_Calc(D, dt, d_epsilon, status)` |
| SUBROUTINE | `PH_Stress_Deviatoric` | 583 | `SUBROUTINE PH_Stress_Deviatoric(stress_tensor, deviatoric)` |
| SUBROUTINE | `PH_Stress_Invariants` | 598 | `SUBROUTINE PH_Stress_Invariants(stress_tensor, I1, I2, I3)` |
| SUBROUTINE | `PH_Stress_Principal` | 621 | `SUBROUTINE PH_Stress_Principal(stress_tensor, principal_stresses, &` |
| SUBROUTINE | `PH_Stress_TensorToVoigt` | 654 | `SUBROUTINE PH_Stress_TensorToVoigt(stress_tensor, stress_voigt, status)` |
| SUBROUTINE | `PH_Stress_VoigtToTensor` | 671 | `SUBROUTINE PH_Stress_VoigtToTensor(stress_voigt, stress_tensor, status)` |
| SUBROUTINE | `PH_StressRate_Calc` | 692 | `SUBROUTINE PH_StressRate_Calc(sigma_rate, W, sigma, sigma_dot, status)` |
| SUBROUTINE | `PH_Te_Co_Strain` | 733 | `SUBROUTINE PH_Te_Co_Strain(strain_voigt, strain_tensor, status)` |
| SUBROUTINE | `PH_Te_Co_Strain` | 742 | `SUBROUTINE PH_Te_Co_Strain(strain_tensor, strain_voigt, status)` |
| SUBROUTINE | `PH_Te_Co_Stress` | 751 | `SUBROUTINE PH_Te_Co_Stress(stress_voigt, stress_tensor, status)` |
| SUBROUTINE | `PH_Te_Co_Stress` | 760 | `SUBROUTINE PH_Te_Co_Stress(stress_tensor, stress_voigt, status)` |
| SUBROUTINE | `PH_Te_ComputePrincipalDirect` | 769 | `SUBROUTINE PH_Te_ComputePrincipalDirect(tensor, principal_directions, status)` |
| SUBROUTINE | `PH_Te_ComputePrincipalValues` | 783 | `SUBROUTINE PH_Te_ComputePrincipalValues(tensor, principal_values, status)` |
| SUBROUTINE | `PH_Tensor_ComputeInvariants` | 797 | `SUBROUTINE PH_Tensor_ComputeInvariants(tensor, I1, I2, I3, status)` |
| SUBROUTINE | `PH_Tensor_Rotate` | 811 | `SUBROUTINE PH_Tensor_Rotate(tensor, rotation, rotated_tensor, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
