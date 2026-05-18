# `MD_Int_Friction.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Friction.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Friction`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Friction`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Friction`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Friction.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cont_ApplyFriction` | 85 | `SUBROUTINE Cont_ApplyFriction(contact_node, relative_veloci, control, &` |
| SUBROUTINE | `Cont_Friction_bond_debond` | 119 | `SUBROUTINE Cont_Friction_bond_debond(node, fric_params, F_n, k_t, &` |
| FUNCTION | `Cont_Friction_check_slip_condition` | 157 | `PURE FUNCTION Cont_Friction_check_slip_condition(trial_t, F_n, mu) RESULT(is_slip)` |
| SUBROUTINE | `Co_Fr_Co_force` | 165 | `SUBROUTINE Co_Fr_Co_force(node, fric_params, F_n, dt, F_t, new_state)` |
| SUBROUTINE | `Co_Fr_Co_fo_2d` | 212 | `SUBROUTINE Co_Fr_Co_fo_2d(slip_y, slip_z, tangent, normal, &` |
| SUBROUTINE | `Co_Fr_Co_fo_3d` | 239 | `SUBROUTINE Co_Fr_Co_fo_3d(slip, tangent1, tangent2, normal, &` |
| SUBROUTINE | `Co_Fr_Co_sl_direction` | 264 | `SUBROUTINE Co_Fr_Co_sl_direction(slip, tangent, normal, slip_dir, slip_mag)` |
| SUBROUTINE | `Co_Fr_Co_Stiff` | 278 | `SUBROUTINE Co_Fr_Co_Stiff(node, fric_params, F_n, k_n, k_t, K_fric, dim)` |
| SUBROUTINE | `Co_Fr_co_damping` | 305 | `SUBROUTINE Co_Fr_co_damping(v_normal, v_tangent, normal, tangent, &` |
| SUBROUTINE | `Cont_Friction_COULOM` | 325 | `SUBROUTINE Cont_Friction_COULOM(fric_params, normal_pressure, tangential_trac, &` |
| FUNCTION | `Cont_Friction_critical_damping` | 354 | `FUNCTION Cont_Friction_critical_damping(mass, stiffness) RESULT(c_crit)` |
| SUBROUTINE | `Co_Fr_Ev_coulomb` | 360 | `SUBROUTINE Co_Fr_Ev_coulomb(node, mu, F_n, F_t, new_state)` |
| SUBROUTINE | `Co_Fr_Ev_st_slip` | 378 | `SUBROUTINE Co_Fr_Ev_st_slip(node, mu_s, mu_k, tol, F_n, F_t, new_state)` |
| SUBROUTINE | `Co_Fr_Ev_ve_dep` | 416 | `SUBROUTINE Co_Fr_Ev_ve_dep(node, fric_params, F_n, dt, F_t, new_state)` |
| SUBROUTINE | `Co_Fr_pr_dependent` | 444 | `SUBROUTINE Co_Fr_pr_dependent(fric_params, p_n, mu_eff)` |
| SUBROUTINE | `Co_Fr_set_da_ratio` | 460 | `SUBROUTINE Co_Fr_set_da_ratio(eps_n, eps_t, mass, xi, c_n, c_t)` |
| SUBROUTINE | `Cont_Friction_STICK` | 470 | `SUBROUTINE Cont_Friction_STICK(fric_params, normal_pressure, tangential_trac, &` |
| SUBROUTINE | `Co_Fr_up_state` | 504 | `SUBROUTINE Co_Fr_up_state(fric_params, normal_pressure, tangential_trac, &` |
| SUBROUTINE | `Co_Fr_ve_dependent` | 528 | `SUBROUTINE Co_Fr_ve_dependent(fric_params, normal_pressure, tangential_trac, &` |
| SUBROUTINE | `UF_Fr_ComputeFrictionForce` | 561 | `SUBROUTINE UF_Fr_ComputeFrictionForce(normal_force, mu, &` |
| SUBROUTINE | `UF_Fr_GetStatistics` | 579 | `SUBROUTINE UF_Fr_GetStatistics(friction_type, mu, stats, status)` |
| SUBROUTINE | `UF_Co_ComputeFrictionForce` | 600 | `SUBROUTINE UF_Co_ComputeFrictionForce(normal_force, friction_coeff, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 33–35 | `INTERFACE Cont_Friction_Compute_force` |
| 38–40 | `INTERFACE Cont_Friction_Compute_force_2d` |
| 43–45 | `INTERFACE Cont_Friction_Compute_force_3d` |
| 48–50 | `INTERFACE Cont_Friction_Compute_Stiff` |
| 53–55 | `INTERFACE Cont_Friction_Compute_slip_direction` |
| 58–60 | `INTERFACE Cont_Friction_velocity_dependent` |
| 63–65 | `INTERFACE Cont_Friction_update_state` |
| 68–70 | `INTERFACE Cont_Friction_pressure_dependent` |
| 73–75 | `INTERFACE Cont_Friction_contact_damping` |
| 78–80 | `INTERFACE Cont_Friction_set_damping_ratio` |
