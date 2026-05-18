# `PH_MatPLM_LegacyFacadeUMATs.f90`

- **Source**: `L4_PH/Material/Dispatch/PH_MatPLM_LegacyFacadeUMATs.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_MatPLM_LegacyFacadeUMATs`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_MatPLM_LegacyFacadeUMATs`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_MatPLM_LegacyFacadeUMATs`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Dispatch/PH_MatPLM_LegacyFacadeUMATs.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `FGM_BuildDmgdStiffMat` | 28 | `subroutine FGM_BuildDmgdStiffMat(D_elastic, damage, damage_factor, ndim, nshr, ntens, analysis_type, D_damaged)` |
| SUBROUTINE | `FGM_BuildElasticStiffness` | 47 | `subroutine FGM_BuildElasticStiffness(PH_MAT_E, nu, K, G, ndim, nshr, ntens, analysis_type, D_elastic)` |
| SUBROUTINE | `FGM_BuildPlasticStiffMatGrad` | 102 | `subroutine FGM_BuildPlasticStiffMatGrad(D_elastic, plastic_multipl, gradient_parame, ndim, nshr, ntens, analysis_type, D_plastic)` |
| SUBROUTINE | `FGM_ComputeEffMatPropsGradie` | 119 | `subroutine FGM_ComputeEffMatPropsGradie(E_min, E_max, nu_min, nu_max, &` |
| SUBROUTINE | `FGM_ComputeEquivalentStress` | 158 | `subroutine FGM_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)` |
| SUBROUTINE | `FGM_ComputeGradientDmgVar` | 179 | `subroutine FGM_ComputeGradientDmgVar(stress, sigma_eqv, gradient_parame, &` |
| SUBROUTINE | `FGM_ComputeGradientEnergyDen` | 205 | `subroutine FGM_ComputeGradientEnergyDen(stress, strain_elastic, strain_plastic, &` |
| SUBROUTINE | `FGM_ComputeGradientParameter` | 218 | `subroutine FGM_ComputeGradientParameter(position, gradient_direct, gradient_length, &` |
| SUBROUTINE | `FGM_ComputePlasticMultiplier` | 256 | `subroutine FGM_ComputePlasticMultiplier(sigma_eqv, sigma_y, H, gradient_parame, temp_multiplier, dt, plastic_multipl)` |
| SUBROUTINE | `FGM_ComputePlasticStrainIncr` | 272 | `subroutine FGM_ComputePlasticStrainIncr(s_dev, plastic_multipl, ndim, nshr, ntens, analysis_type, dstra_plastic)` |
| SUBROUTINE | `FGM_ComputeStressInvariants` | 292 | `subroutine FGM_ComputeStressInvariants(stress, ndim, nshr, ntens, analysis_type, p, s_dev)` |
| SUBROUTINE | `FGM_ComputeTemperatureEffect` | 331 | `subroutine FGM_ComputeTemperatureEffect(temp, temperature_dependence_facto, temperature_effect_multiplie)` |
| SUBROUTINE | `FGM_ComputeThermalStrain` | 339 | `subroutine FGM_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| FUNCTION | `FGM_DetectAnalysisType` | 369 | `function FGM_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `FGM_RegularizeStiffMat` | 390 | `subroutine FGM_RegularizeStiffMat(D, ntens)` |
| SUBROUTINE | `U258_BuildElasticStiffness` | 406 | `subroutine U258_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)` |
| SUBROUTINE | `U258_ComputeEffMatPropsSmart` | 461 | `subroutine U258_ComputeEffMatPropsSmart(E_a, E_m, nu_a, nu_m, &` |
| SUBROUTINE | `U258_ComputeMagneticStress` | 476 | `subroutine U258_ComputeMagneticStress(B, H, ndim, nshr, ntens, analysis_type, stress_magnetic)` |
| SUBROUTINE | `U258_ComputeMagnetization` | 513 | `subroutine U258_ComputeMagnetization(B, H, mu_r, mu0, magnetization)` |
| SUBROUTINE | `U258_ComputePolarization` | 525 | `subroutine U258_ComputePolarization(D, E_field, epsilon_r, epsilon0, polarization)` |
| SUBROUTINE | `U258_ComputeThermalStrain` | 537 | `subroutine U258_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| FUNCTION | `U258_DetectAnalysisType` | 567 | `function U258_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U258_RegularizeStiffMat` | 588 | `subroutine U258_RegularizeStiffMat(D, ntens)` |
| SUBROUTINE | `U264_build_plastic_Stiff` | 603 | `subroutine U264_build_plastic_Stiff(PH_MAT_E, nu, phi, psi, p_trial, q_trial, &` |
| SUBROUTINE | `U264_BuildElasticStiffness` | 658 | `subroutine U264_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)` |
| SUBROUTINE | `U264_Calc_stress_invariants` | 720 | `subroutine U264_Calc_stress_invariants(stress, ndim, analysis_type, p, q, eta)` |
| SUBROUTINE | `U264_ComputeEffectiveStress` | 765 | `subroutine U264_ComputeEffectiveStress(stress, ndim, nshr, ntens, analysis_type, stress_effectiv)` |
| SUBROUTINE | `U264_ComputeThermalStrain` | 791 | `subroutine U264_ComputeThermalStrain(alpha, delta_temp, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| FUNCTION | `U264_DetectAnalysisType` | 813 | `function U264_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| FUNCTION | `U264_G_current_value` | 834 | `function U264_G_current_value(PH_MAT_E, nu) result(G)` |
| SUBROUTINE | `U264_RegularizeStiffMat` | 842 | `subroutine U264_RegularizeStiffMat(D, n)` |
| SUBROUTINE | `U264_UpdateElasticProperties` | 857 | `subroutine U264_UpdateElasticProperties(p_current, p0, E_ref, G0, m_comp, m_shear, E_current, G_current)` |
| SUBROUTINE | `U2_co_cr_st_state` | 870 | `subroutine U2_co_cr_st_state(p, phi, psi, c, R_f, p_critical, q_critical)` |
| SUBROUTINE | `U2_co_pl_st_increment` | 892 | `subroutine U2_co_pl_st_increment(delta_lambda, p_trial, q_trial, phi, psi, &` |
| SUBROUTINE | `U2_ComputeElectrostrictiveSt` | 941 | `subroutine U2_ComputeElectrostrictiveSt(alpha_ed, E_field, ndim, nshr, ntens, analysis_type, strain_ed)` |
| SUBROUTINE | `U2_ComputeMagnetostrictionSt` | 977 | `subroutine U2_ComputeMagnetostrictionSt(alpha_magnetost, B, H, ndim, nshr, ntens, analysis_type, strain_magnetos)` |
| SUBROUTINE | `U2_ComputePhaseTransformatio` | 1015 | `subroutine U2_ComputePhaseTransformatio(martensite_frac, temp, temp_old, dt, &` |
| SUBROUTINE | `U2_ComputePiezoelectricStrai` | 1047 | `subroutine U2_ComputePiezoelectricStrai(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, strain_piezoele)` |
| SUBROUTINE | `U2_ComputePiezoelectricStres` | 1066 | `subroutine U2_ComputePiezoelectricStres(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, stress_piezoele)` |
| SUBROUTINE | `U2_ComputeSmartMatEnergyDens` | 1085 | `subroutine U2_ComputeSmartMatEnergyDens(stress, strain_elastic, strain_transfor, &` |
| SUBROUTINE | `U2_ComputeTransformationStra` | 1105 | `subroutine U2_ComputeTransformationStra(martensite_frac, epsilon_L, ndim, nshr, ntens, analysis_type, strain_transfor)` |
| SUBROUTINE | `U2_ComputeTransformationStre` | 1135 | `subroutine U2_ComputeTransformationStre(strain_transfor, D_elastic, ndim, nshr, ntens, analysis_type, stress_transfor)` |
| SUBROUTINE | `U2_ge_re_mapping` | 1152 | `subroutine U2_ge_re_mapping(stress_trial, p_trial, q_trial, p_critical, q_critical, &` |
| SUBROUTINE | `UF_FGM_UMAT` | 1212 | `SUBROUTINE UF_FGM_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| FUNCTION | `FGM_detect_analysis_type` | 1634 | `function FGM_detect_analysis_type(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `FGM_Calc_gradient_Param` | 1655 | `subroutine FGM_Calc_gradient_Param(position, gradient_direct, gradient_length, &` |
| SUBROUTINE | `FGM_co_ef_mat_pr_gradient` | 1689 | `subroutine FGM_co_ef_mat_pr_gradient(E_min, E_max, nu_min, nu_max, &` |
| SUBROUTINE | `FGM_co_te_ef_multiplier` | 1732 | `subroutine FGM_co_te_ef_multiplier(temp, temperature_dependence_facto, temperature_effect_multiplie)` |
| SUBROUTINE | `FGM_Calc_thermal_strain` | 1740 | `subroutine FGM_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)` |
| SUBROUTINE | `FGM_build_elastic_Stiff` | 1764 | `subroutine FGM_build_elastic_Stiff(PH_MAT_E, nu, K, G, ndim, analysis_type, D_elastic)` |
| SUBROUTINE | `FGM_Calc_stress_invariants` | 1820 | `subroutine FGM_Calc_stress_invariants(stress, ndim, analysis_type, p, s_dev, p_out)` |
| SUBROUTINE | `FGM_Calc_equivalent_stress` | 1858 | `subroutine FGM_Calc_equivalent_stress(s_dev, ndim, analysis_type, sigma_eqv)` |
| SUBROUTINE | `FGM_co_pl_mu_gradient` | 1877 | `subroutine FGM_co_pl_mu_gradient(sigma_eqv, sigma_y, H, gradient_parame, temp_multiplier, dt, plastic_multipl)` |
| SUBROUTINE | `FGM_co_pl_st_in_gradient` | 1893 | `subroutine FGM_co_pl_st_in_gradient(s_dev, plastic_multipl, ndim, analysis_type, dstra_plastic)` |
| SUBROUTINE | `FGM_co_gr_da_var` | 1914 | `subroutine FGM_co_gr_da_var(stress, sigma_eqv, gradient_parame, interface_stren, interface_energ, damage_old, dt, damage, damage_rate, interface_damag)` |
| SUBROUTINE | `FGM_build_damaged_Stiff_Mtx` | 1938 | `subroutine FGM_build_damaged_Stiff_Mtx(D_elastic, damage, damage_factor, ndim, analysis_type, D_damaged)` |
| SUBROUTINE | `FGM_bu_pl_st_mtx_gradient` | 1956 | `subroutine FGM_bu_pl_st_mtx_gradient(D_elastic, plastic_multipl, gradient_parame, ndim, analysis_type, D_plastic)` |
| SUBROUTINE | `FGM_co_gr_en_density` | 1972 | `subroutine FGM_co_gr_en_density(stress, strain_elastic, strain_plastic, damage, damage_rate, interface_damag, dt, sse, spd, scd)` |
| SUBROUTINE | `FGM_regularize_Stiff_Mtx` | 1982 | `subroutine FGM_regularize_Stiff_Mtx(D)` |
| SUBROUTINE | `UF_Geotechnical_UMAT` | 1996 | `SUBROUTINE UF_Geotechnical_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_SmartMaterial_UMAT` | 2270 | `SUBROUTINE UF_SmartMaterial_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| FUNCTION | `U258_detect_analysis_type` | 2696 | `function U258_detect_analysis_type(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U2_co_ph_transformation` | 2717 | `subroutine U2_co_ph_transformation(martensite_frac, temp, temp_old, dt, sigma_ms, sigma_mf, sigma_as, sigma_af, T_ms, T_mf, T_as, T_af, epsilon_L, C_M, martensite_frac, phase_rate)` |
| SUBROUTINE | `U2_co_ef_mat_pr_smart` | 2746 | `subroutine U2_co_ef_mat_pr_smart(E_a, E_m, nu_a, nu_m, martensite_frac, alpha_thermal_a, alpha_thermal_m, E_effective, nu_effective, alpha_thermal_e)` |
| SUBROUTINE | `U2_co_tr_strain` | 2757 | `subroutine U2_co_tr_strain(martensite_frac, epsilon_L, ndim, analysis_type, strain_transfor)` |
| SUBROUTINE | `U2_co_pi_strain` | 2781 | `subroutine U2_co_pi_strain(alpha_piezoelec, E_field, ndim, analysis_type, strain_piezoele)` |
| SUBROUTINE | `U2_co_ma_strain` | 2818 | `subroutine U2_co_ma_strain(alpha_magnetost, B, H, ndim, analysis_type, strain_magnetos)` |
| SUBROUTINE | `U2_co_el_strain` | 2853 | `subroutine U2_co_el_strain(alpha_ed, E_field, ndim, analysis_type, strain_ed)` |
| SUBROUTINE | `U258_Calc_thermal_strain` | 2887 | `subroutine U258_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)` |
| SUBROUTINE | `U258_build_elastic_Stiff` | 2911 | `subroutine U258_build_elastic_Stiff(PH_MAT_E, nu, ndim, analysis_type, D_elastic)` |
| SUBROUTINE | `U2_co_tr_stress` | 2967 | `subroutine U2_co_tr_stress(strain_transfor, D_elastic, ndim, analysis_type, stress_transfor)` |
| SUBROUTINE | `U2_co_pi_stress` | 2983 | `subroutine U2_co_pi_stress(alpha_piezoelec, E_field, ndim, analysis_type, stress_piezoele)` |
| SUBROUTINE | `U258_Calc_magnetic_stress` | 2992 | `subroutine U258_Calc_magnetic_stress(B, H, ndim, analysis_type, stress_magnetic)` |
| SUBROUTINE | `U258_Calc_magnetization` | 3029 | `subroutine U258_Calc_magnetization(B, H, mu_r, mu0, magnetization)` |
| SUBROUTINE | `U258_Calc_polarization` | 3040 | `subroutine U258_Calc_polarization(D, E_field, epsilon_r, epsilon0, polarization)` |
| SUBROUTINE | `U2_co_sm_mat_en_density` | 3051 | `subroutine U2_co_sm_mat_en_density(stress, strain_elastic, strain_transfor, strain_piezoele, strain_magnetos, strain_ed, B, H, D, E_field, magnetization, polarization, phase_rate, dt, electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating)` |
| SUBROUTINE | `U258_regularize_Stiff_Mtx` | 3070 | `subroutine U258_regularize_Stiff_Mtx(D)` |
| SUBROUTINE | `U259_BuildDamagedStiffness` | 3089 | `subroutine U259_BuildDamagedStiffness(D_viscoelastic, damage_factor, damage_variable, &` |
| SUBROUTINE | `U259_BuildElasticStiffness` | 3110 | `subroutine U259_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D)` |
| SUBROUTINE | `U259_BuildViscoelasticStiff` | 3165 | `subroutine U259_BuildViscoelasticStiff(D_elastic, dt, n_prony, &` |
| SUBROUTINE | `U259_ComputeDamageVariable` | 3231 | `subroutine U259_ComputeDamageVariable(stress, sigma_eqv, sigma_critical, &` |
| SUBROUTINE | `U259_ComputeEquivalentStress` | 3252 | `subroutine U259_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)` |
| SUBROUTINE | `U259_ComputeStrainInvariants` | 3273 | `subroutine U259_ComputeStrainInvariants(strain, ndim, nshr, ntens, analysis_type, strain_vol, strain_dev)` |
| SUBROUTINE | `U259_ComputeStressInvariants` | 3312 | `subroutine U259_ComputeStressInvariants(stress, ndim, nshr, ntens, analysis_type, p, s_dev)` |
| SUBROUTINE | `U259_ComputeThermalStrain` | 3351 | `subroutine U259_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| FUNCTION | `U259_DetectAnalysisType` | 3381 | `function U259_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U259_RegularizeStiffMat` | 3402 | `subroutine U259_RegularizeStiffMat(D, ntens)` |
| SUBROUTINE | `U260_BuildElasticStiffness` | 3417 | `subroutine U260_BuildElasticStiffness(lambda, mu, ndim, nshr, ntens, analysis_type, D)` |
| SUBROUTINE | `U260_BuildViscoplasticStiff` | 3467 | `subroutine U260_BuildViscoplasticStiff(lambda, mu, H, eta, sigma_eqv, s_dev, delta_lambda, &` |
| SUBROUTINE | `U260_ComputeEquivalentStress` | 3498 | `subroutine U260_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)` |
| SUBROUTINE | `U260_ComputeStrainRate` | 3519 | `subroutine U260_ComputeStrainRate(dstra, dtime, strain_rate)` |
| SUBROUTINE | `U260_ComputeStressInvariants` | 3531 | `subroutine U260_ComputeStressInvariants(stress, ndim, nshr, ntens, analysis_type, p, s_dev)` |
| SUBROUTINE | `U260_ComputeThermalStrain` | 3570 | `subroutine U260_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| FUNCTION | `U260_DetectAnalysisType` | 3600 | `function U260_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U260_RegularizeStiffMat` | 3621 | `subroutine U260_RegularizeStiffMat(D, ntens)` |
| SUBROUTINE | `U261_BuildDamagedStiffness` | 3636 | `subroutine U261_BuildDamagedStiffness(D_elastic, damage_factor, damage_variable, &` |
| SUBROUTINE | `U261_BuildElasticStiffness` | 3662 | `subroutine U261_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D)` |
| SUBROUTINE | `U261_ComputeEquivalentStress` | 3717 | `subroutine U261_ComputeEquivalentStress(stress, ndim, nshr, ntens, analysis_type, sigma_eqv)` |
| SUBROUTINE | `U261_ComputeStressDeviator` | 3738 | `subroutine U261_ComputeStressDeviator(stress, ndim, nshr, ntens, analysis_type, s_dev)` |
| SUBROUTINE | `U261_ComputeThermalStrain` | 3780 | `subroutine U261_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| FUNCTION | `U261_DetectAnalysisType` | 3810 | `function U261_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U261_RegularizeStiffMat` | 3831 | `subroutine U261_RegularizeStiffMat(D, ntens)` |
| SUBROUTINE | `U262_BuildCoupledStiffness` | 3845 | `subroutine U262_BuildCoupledStiffness(D_elastic, alpha_piezo, alpha_mag, alpha_ed, Q_te, S_tm, &` |
| SUBROUTINE | `U262_BuildElasticStiffness` | 3886 | `subroutine U262_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)` |
| SUBROUTINE | `U262_ComputeCoupledEnergy` | 3950 | `subroutine U262_ComputeCoupledEnergy(B, H, D, E_field, J, dt, temp, temp_old, &` |
| SUBROUTINE | `U262_ComputeCurrentDensity` | 3965 | `subroutine U262_ComputeCurrentDensity(sigma_e, E_field, temp, temp_old, Q_te, J)` |
| SUBROUTINE | `U262_ComputeMagnetization` | 3980 | `subroutine U262_ComputeMagnetization(B, H, mu_r, mu0, magnetization)` |
| SUBROUTINE | `U262_ComputePolarization` | 3992 | `subroutine U262_ComputePolarization(D, E_field, epsilon_r, epsilon0, polarization)` |
| SUBROUTINE | `U262_ComputeThermalStrain` | 4004 | `subroutine U262_ComputeThermalStrain(alpha, delta_temp, ndim, nshr, ntens, analysis_type, strain_thermal)` |
| SUBROUTINE | `U262_ComputeThermalStress` | 4034 | `subroutine U262_ComputeThermalStress(D_elastic, strain_thermal, ndim, nshr, ntens, analysis_type, stress_thermal)` |
| FUNCTION | `U262_DetectAnalysisType` | 4051 | `function U262_DetectAnalysisType(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U262_RegularizeStiffMat` | 4074 | `subroutine U262_RegularizeStiffMat(D, n)` |
| SUBROUTINE | `U2_ComputeDmgVarWithScaleEff` | 4088 | `subroutine U2_ComputeDmgVarWithScaleEff(stress, sigma_critical, alpha_damage, &` |
| SUBROUTINE | `U2_ComputeElectromagneticStr` | 4123 | `subroutine U2_ComputeElectromagneticStr(B, H, J, ndim, nshr, ntens, analysis_type, stress_mag)` |
| SUBROUTINE | `U2_ComputeElectrostrictiveSt` | 4163 | `subroutine U2_ComputeElectrostrictiveSt(alpha_ed, E_field, ndim, nshr, ntens, analysis_type, strain_ed)` |
| SUBROUTINE | `U2_ComputeEquivalentStrainRa` | 4199 | `subroutine U2_ComputeEquivalentStrainRa(strain_rate, ndim, nshr, ntens, analysis_type, eps_eqv_rate)` |
| SUBROUTINE | `U2_ComputeMagnetostrictionSt` | 4220 | `subroutine U2_ComputeMagnetostrictionSt(alpha_mag, B, H, ndim, nshr, ntens, analysis_type, strain_mag)` |
| SUBROUTINE | `U2_ComputePiezoelectricStrai` | 4257 | `subroutine U2_ComputePiezoelectricStrai(alpha_piezo, E_field, ndim, nshr, ntens, analysis_type, strain_piezo)` |
| SUBROUTINE | `U2_ComputePiezoelectricStres` | 4276 | `subroutine U2_ComputePiezoelectricStres(alpha_piezo, E_field, ndim, nshr, ntens, analysis_type, stress_piezo)` |
| SUBROUTINE | `U2_ComputePlasticStrainIncr` | 4295 | `subroutine U2_ComputePlasticStrainIncr(stress, plastic_multipl, ndim, nshr, ntens, analysis_type, dstra_plastic)` |
| SUBROUTINE | `U2_ComputePlasticStrainIncrW` | 4318 | `subroutine U2_ComputePlasticStrainIncrW(stress, strain_plastic, &` |
| SUBROUTINE | `U2_ComputePronyViscoelasticS` | 4358 | `subroutine U2_ComputePronyViscoelasticS(dstra_elastic, dt, n_prony, &` |
| SUBROUTINE | `U2_ComputeStressTemperatureD` | 4419 | `subroutine U2_ComputeStressTemperatureD(alpha_thermal, PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, ddsddt)` |
| SUBROUTINE | `U2_ComputeTemperatureDepende` | 4438 | `subroutine U2_ComputeTemperatureDepende(temp, T_ref, Q_activation, R_gas, &` |
| SUBROUTINE | `U2_ComputeThermoelectricStra` | 4456 | `subroutine U2_ComputeThermoelectricStra(Q_te, delta_temp, E_field, ndim, nshr, ntens, analysis_type, strain_te)` |
| SUBROUTINE | `U2_ComputeThermomagneticStra` | 4492 | `subroutine U2_ComputeThermomagneticStra(S_tm, delta_temp, B, ndim, nshr, ntens, analysis_type, strain_tm)` |
| SUBROUTINE | `U2_ComputeViscoplasticStrain` | 4528 | `subroutine U2_ComputeViscoplasticStrain(delta_lambda, sigma_eqv, s_dev, &` |
| SUBROUTINE | `U2_ComputeViscoplasticStress` | 4546 | `subroutine U2_ComputeViscoplasticStress(stress_trial, delta_lambda, sigma_eqv, s_dev, &` |
| SUBROUTINE | `U2_ComputeViscosityCoefficie` | 4565 | `subroutine U2_ComputeViscosityCoefficie(sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0, eta)` |
| SUBROUTINE | `UF_MultiscaleDamage_UMAT` | 4583 | `SUBROUTINE UF_MultiscaleDamage_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_ThermoElectroMagnetoMechanical_UMAT` | 5033 | `SUBROUTINE UF_ThermoElectroMagnetoMechanical_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_ThermoViscoplastic_UMAT` | 5416 | `SUBROUTINE UF_ThermoViscoplastic_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| FUNCTION | `U260_detect_analysis_type` | 5675 | `function U260_detect_analysis_type(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U2_co_te_de_parameters` | 5696 | `subroutine U2_co_te_de_parameters(temp, T_ref, Q_activation, R_gas, &` |
| SUBROUTINE | `U260_build_elastic_Stiff` | 5728 | `subroutine U260_build_elastic_Stiff(lambda, mu, ndim, analysis_type, D)` |
| SUBROUTINE | `U260_regularize_Stiff_Mtx` | 5779 | `subroutine U260_regularize_Stiff_Mtx(D)` |
| SUBROUTINE | `U260_Calc_thermal_strain` | 5791 | `subroutine U260_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)` |
| SUBROUTINE | `U260_Calc_strain_rate` | 5815 | `subroutine U260_Calc_strain_rate(dstra, dtime, strain_rate)` |
| SUBROUTINE | `U2_co_eq_st_rate` | 5830 | `subroutine U2_co_eq_st_rate(strain_rate, ndim, analysis_type, eps_eqv_rate)` |
| SUBROUTINE | `U260_Calc_stress_invariants` | 5880 | `subroutine U260_Calc_stress_invariants(stress, ndim, analysis_type, sigma_eqv, s_dev, p)` |
| SUBROUTINE | `U2_co_vi_coefficient` | 5926 | `subroutine U2_co_vi_coefficient(sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0, eta)` |
| SUBROUTINE | `U2_co_vi_st_increment` | 5949 | `subroutine U2_co_vi_st_increment(delta_lambda, sigma_eqv, s_dev, &` |
| SUBROUTINE | `U2_co_vi_stress` | 5984 | `subroutine U2_co_vi_stress(stress_trial, delta_lambda, sigma_eqv, s_dev, &` |
| SUBROUTINE | `U2_bu_vi_stiff` | 6023 | `subroutine U2_bu_vi_stiff(lambda, mu, H, eta, sigma_eqv, s_dev, delta_lambda, &` |
| SUBROUTINE | `U2_co_st_te_derivative` | 6091 | `subroutine U2_co_st_te_derivative(alpha_thermal, PH_MAT_E, nu, ndim, analysis_type, ddsddt)` |
| SUBROUTINE | `UF_ViscoelasticDamage_UMAT` | 6128 | `SUBROUTINE UF_ViscoelasticDamage_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| FUNCTION | `U259_detect_analysis_type` | 6455 | `function U259_detect_analysis_type(ndim, nshr) result(analysis_type)` |
| SUBROUTINE | `U259_Calc_thermal_strain` | 6476 | `subroutine U259_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)` |
| SUBROUTINE | `U259_Calc_stress_invariants` | 6500 | `subroutine U259_Calc_stress_invariants(stress, ndim, analysis_type, p, s_dev, p_out)` |
| SUBROUTINE | `U259_Calc_equivalent_stress` | 6538 | `subroutine U259_Calc_equivalent_stress(s_dev, ndim, analysis_type, sigma_eqv)` |
| SUBROUTINE | `U259_build_elastic_Stiff` | 6557 | `subroutine U259_build_elastic_Stiff(PH_MAT_E, nu, ndim, analysis_type, D)` |
| SUBROUTINE | `U259_regularize_Stiff_Mtx` | 6613 | `subroutine U259_regularize_Stiff_Mtx(D)` |
| SUBROUTINE | `U2_co_pr_vi_stress` | 6625 | `subroutine U2_co_pr_vi_stress(dstra_elastic, dt, n_prony, &` |
| SUBROUTINE | `U259_Calc_strain_invariants` | 6696 | `subroutine U259_Calc_strain_invariants(strain, ndim, analysis_type, strain_vol, strain_dev, strain_vol_out)` |
| SUBROUTINE | `U259_Calc_damage_variable` | 6734 | `subroutine U259_Calc_damage_variable(stress, sigma_eqv, sigma_critical, &` |
| SUBROUTINE | `U2_bu_vi_stiff` | 6763 | `subroutine U2_bu_vi_stiff(D_elastic, dt, n_prony, &` |
| SUBROUTINE | `U259_build_damaged_Stiff` | 6822 | `subroutine U259_build_damaged_Stiff(D_viscoelastic, damage_factor, damage_variable, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
