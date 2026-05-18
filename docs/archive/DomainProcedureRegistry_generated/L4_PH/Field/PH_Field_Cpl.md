# `PH_Field_Cpl.f90`

- **Source**: `L4_PH/Field/PH_Field_Cpl.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Field_Cpl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_Cpl`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field_Cpl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_Cpl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Acoustic_StiffnessContrib` | 40 | `SUBROUTINE PH_Acoustic_StiffnessContrib(dNdx, rho_inv, detJ, weight, npe, K_e, mesh_st)` |
| SUBROUTINE | `PH_ElectroMag_StiffnessContrib` | 73 | `SUBROUTINE PH_ElectroMag_StiffnessContrib(dNdx, mu_inv, detJ, weight, npe, K_e, mesh_st)` |
| SUBROUTINE | `PH_SSTrans_ConvectiveContrib` | 106 | `SUBROUTINE PH_SSTrans_ConvectiveContrib(N, dNdx, v, detJ, weight, npe, K_conv_e, mesh_st)` |
| SUBROUTINE | `PH_Piezo_CouplingContrib` | 137 | `SUBROUTINE PH_Piezo_CouplingContrib(B_u, dNdx, d_piezo, detJ, weight, K_ue_e, mesh_st)` |
| SUBROUTINE | `PH_Field_Cpl_ThermoMech` | 181 | `SUBROUTINE PH_Field_Cpl_ThermoMech(T_gp, T_ref, alpha, ndim, &` |
| SUBROUTINE | `PH_Field_Cpl_HydroMech` | 228 | `SUBROUTINE PH_Field_Cpl_HydroMech(sigma_total, pore_p, biot_alpha, &` |
| SUBROUTINE | `PH_Field_Cpl_MassDiffusion` | 269 | `SUBROUTINE PH_Field_Cpl_MassDiffusion(grad_c, D_coeff, ndim, flux, status)` |
| SUBROUTINE | `PH_Field_Cpl_Apply` | 322 | `SUBROUTINE PH_Field_Cpl_Apply(cpl_type, scalar_field, ref_value, coeff, &` |
| SUBROUTINE | `PH_Field_Cpl_Update` | 387 | `SUBROUTINE PH_Field_Cpl_Update(n_ip, ndim, dt, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
