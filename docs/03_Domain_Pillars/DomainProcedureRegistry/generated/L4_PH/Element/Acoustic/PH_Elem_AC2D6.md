# `PH_Elem_AC2D6.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC2D6.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_AC2D6`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC2D6`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC2D6`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC2D6.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC2D6_UEL_Args` (lines 101–123)

```fortran
  TYPE, PUBLIC :: PH_AC2D6_UEL_Args
    !-- [IN] Flags for computation control
    LOGICAL     :: compute_amatrx = .TRUE.   ! Compute tangent stiffness matrix
    LOGICAL     :: compute_rhs    = .TRUE.   ! Compute residual vector
    
    !-- [IN] P3 dynamic analysis extensions
    LOGICAL     :: compute_mass   = .FALSE.  ! Mass matrix computation flag (P3)
    INTEGER(i4) :: mass_method    = 0_i4    ! 0=None, 1=Consistent, 2=Lumped(HRZ), 3=Lumped(RowSum), 4=Lumped(Uniform)
    LOGICAL     :: compute_damping = .FALSE. ! Damping matrix computation flag (P3)
    REAL(wp)    :: alpha_M        = 0.0_wp  ! Mass proportional damping coefficient [1/s]
    REAL(wp)    :: beta_K         = 0.0_wp  ! Stiffness proportional damping coefficient [s]
    
    !-- [IN] Step control (from RT_Com_Ctx%lflags)
    INTEGER(i4) :: lflags_kstep   = 0_i4
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
  END TYPE PH_AC2D6_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_AC2D6_UEL_API` | 188 | `SUBROUTINE PH_AC2D6_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `PH_AC2D6_UEL_Impl` | 219 | `SUBROUTINE PH_AC2D6_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `CPS6_Get_Gauss_Point` | 378 | `SUBROUTINE CPS6_Get_Gauss_Point(ip, xi, eta, w)` |
| SUBROUTINE | `CPS6_Shape_Functions` | 395 | `SUBROUTINE CPS6_Shape_Functions(xi, eta, N)` |
| SUBROUTINE | `CPS6_Shape_Functions_Derivatives` | 411 | `SUBROUTINE CPS6_Shape_Functions_Derivatives(xi, eta, dNdxi, dNdeta)` |
| SUBROUTINE | `CPS6_Jacobian` | 436 | `SUBROUTINE CPS6_Jacobian(coords, N, xi, eta, dNdX, detJ)` |
| SUBROUTINE | `AC2D6_B_Matrix` | 468 | `SUBROUTINE AC2D6_B_Matrix(dNdX, B)` |
| SUBROUTINE | `PH_Elem_AC2D6_GetMaterialProps` | 490 | `SUBROUTINE PH_Elem_AC2D6_GetMaterialProps(density, bulk_modulus, sound_speed)` |
| SUBROUTINE | `PH_Elem_AC2D6_GetMaterialProps_FromDesc` | 497 | `SUBROUTINE PH_Elem_AC2D6_GetMaterialProps_FromDesc(desc)` |
| SUBROUTINE | `PH_Elem_AC2D6_GetThickness` | 504 | `SUBROUTINE PH_Elem_AC2D6_GetThickness(thickness)` |
| SUBROUTINE | `PH_Elem_AC2D6_GetAcousticProps` | 509 | `SUBROUTINE PH_Elem_AC2D6_GetAcousticProps(acoustic_density, acoustic_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D6_SetSectionProps` | 517 | `SUBROUTINE PH_Elem_AC2D6_SetSectionProps(density, bulk_modulus, thickness)` |
| SUBROUTINE | `PH_Elem_AC2D6_SetSectionProps_FromDesc` | 521 | `SUBROUTINE PH_Elem_AC2D6_SetSectionProps_FromDesc(sect_desc)` |
| SUBROUTINE | `PH_Elem_AC2D6_ApplyEssentialBC` | 527 | `SUBROUTINE PH_Elem_AC2D6_ApplyEssentialBC(Ke, F_ext, constrained_nodes, prescribed_values)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormConstraintMatrix` | 549 | `SUBROUTINE PH_Elem_AC2D6_FormConstraintMatrix(constrained_nodes, C_matrix)` |
| SUBROUTINE | `PH_Elem_AC2D6_ApplyPenaltyBC` | 560 | `SUBROUTINE PH_Elem_AC2D6_ApplyPenaltyBC(Ke, F_ext, constrained_nodes, prescribed_values, penalty)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormAcousticImpedance` | 575 | `SUBROUTINE PH_Elem_AC2D6_FormAcousticImpedance(coords, impedance, face, K_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormRadiationCondition` | 606 | `SUBROUTINE PH_Elem_AC2D6_FormRadiationCondition(coords, radiation_coeff, face, K_radiation)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormStructureCoupling` | 614 | `SUBROUTINE PH_Elem_AC2D6_FormStructureCoupling(coords, coupling_coeff, face, K_coupling)` |
| SUBROUTINE | `PH_ELEM_AC2D6_CalcArea` | 623 | `SUBROUTINE PH_ELEM_AC2D6_CalcArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormPressureLoad` | 633 | `SUBROUTINE PH_Elem_AC2D6_FormPressureLoad(coords, pressure, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormSurfaceTraction` | 646 | `SUBROUTINE PH_Elem_AC2D6_FormSurfaceTraction(coords, traction, face, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormBodyForce` | 670 | `SUBROUTINE PH_Elem_AC2D6_FormBodyForce(coords, body_force, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D6_CalcAcousticIntensity` | 684 | `SUBROUTINE PH_Elem_AC2D6_CalcAcousticIntensity(coords, nodal_pressures, nodal_velocities, intensity)` |
| SUBROUTINE | `PH_Elem_AC2D6_CalcEnergy` | 698 | `SUBROUTINE PH_Elem_AC2D6_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC2D6_CalcPressure` | 717 | `SUBROUTINE PH_Elem_AC2D6_CalcPressure(coords, nodal_pressures, gauss_points, pressure_field)` |
| SUBROUTINE | `PH_ELEM_AC2D6_AreaInt` | 733 | `SUBROUTINE PH_ELEM_AC2D6_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_AC2D6_FormStiffMatrix` | 748 | `SUBROUTINE PH_Elem_AC2D6_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_AC2D6_ThermStrainVector` | 772 | `SUBROUTINE PH_Elem_AC2D6_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC2D6_ConsMass` | 778 | `SUBROUTINE PH_Elem_AC2D6_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC2D6_DefInit` | 801 | `SUBROUTINE PH_Elem_AC2D6_DefInit()` |
| SUBROUTINE | `PH_Elem_AC2D6_FormIntForce` | 804 | `SUBROUTINE PH_Elem_AC2D6_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_AC2D6_LumpMass` | 814 | `SUBROUTINE PH_Elem_AC2D6_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_AC2D6_NL_TL` | 827 | `SUBROUTINE PH_Elem_AC2D6_NL_TL(coords_ref, p_elem, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_AC2D6_NL_UL` | 852 | `SUBROUTINE PH_Elem_AC2D6_NL_UL(coords_prev, p_incr, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_AC2D6_Update_Speed_of_Sound` | 881 | `SUBROUTINE PH_Elem_AC2D6_Update_Speed_of_Sound(mat_desc, temperature, &` |
| SUBROUTINE | `PH_Elem_AC2D6_Setup_Thermo_Coupling` | 936 | `SUBROUTINE PH_Elem_AC2D6_Setup_Thermo_Coupling(mat_desc, T_field, status)` |
| FUNCTION | `PH_Elem_AC2D6_Biot_Compute_Stab_Param` | 986 | `FUNCTION PH_Elem_AC2D6_Biot_Compute_Stab_Param(wavenumber, flow_velocity, &` |
| SUBROUTINE | `PH_Elem_AC2D6_Biot_Stabilize_SlowWave` | 1030 | `SUBROUTINE PH_Elem_AC2D6_Biot_Stabilize_SlowWave(coords, mat_desc, &\       pressure_field, velocity_field, K_stab, F_stab, status)` |
| SUBROUTINE | `PH_Elem_AC2D6_PML_Update_State` | 1155 | `SUBROUTINE PH_Elem_AC2D6_PML_Update_State(pressure_current, pressure_prev, &` |
| SUBROUTINE | `PH_Elem_AC2D6_PML_Absorbing_Boundary` | 1237 | `SUBROUTINE PH_Elem_AC2D6_PML_Absorbing_Boundary(coords, mat_desc, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
