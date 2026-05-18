# `PH_Field_Interpolate.f90`

- **Source**: `L4_PH/Field/PH_Field_Interpolate.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Field_Interpolate`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_Interpolate`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field_Interpolate`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_Interpolate.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Field_NodeToGP` | 67 | `SUBROUTINE PH_Field_NodeToGP(T_nodal, N_shape, npe, T_gp, status)` |
| SUBROUTINE | `PH_Field_GradAtGP` | 94 | `SUBROUTINE PH_Field_GradAtGP(T_nodal, dNdx, npe, ndim, gradT, status)` |
| SUBROUTINE | `PH_Field_GPToNode` | 127 | `SUBROUTINE PH_Field_GPToNode(T_gp, ngp, npe, extrap_matrix, T_nodal, status)` |
| SUBROUTINE | `PH_Field_BuildExtrapC3D8` | 158 | `SUBROUTINE PH_Field_BuildExtrapC3D8(E_mat, status)` |
| SUBROUTINE | `PH_Field_ThermalStrain` | 197 | `SUBROUTINE PH_Field_ThermalStrain(T_gp, T_ref, alpha, ndim, eps_th, status)` |
| SUBROUTINE | `PH_Field_ThermalStrain_Aniso` | 247 | `SUBROUTINE PH_Field_ThermalStrain_Aniso(T_gp, T_ref, alpha_vec, ndim, eps_th, status)` |
| SUBROUTINE | `PH_Field_EffStress` | 294 | `SUBROUTINE PH_Field_EffStress(sigma_total, pore_p, biot_alpha, sigma_eff, status)` |
| SUBROUTINE | `PH_Field_FickFlux` | 331 | `SUBROUTINE PH_Field_FickFlux(grad_c, D_coeff, ndim, flux, status)` |
| SUBROUTINE | `PH_Field_FickFlux_Aniso` | 367 | `SUBROUTINE PH_Field_FickFlux_Aniso(grad_c, D_tensor, ndim, flux, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
