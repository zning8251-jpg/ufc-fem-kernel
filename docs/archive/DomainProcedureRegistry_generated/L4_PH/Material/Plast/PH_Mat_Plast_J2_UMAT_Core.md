# `PH_Mat_Plast_J2_UMAT_Core.f90`

- **Source**: `L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Plast_J2_UMAT_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Plast_J2_UMAT_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Plast_J2_UMAT`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `PLM_J2_Yield_Stress_iso` | 107 | `PURE FUNCTION PLM_J2_Yield_Stress_iso(desc, peeq) RESULT(sigy)` |
| FUNCTION | `PLM_J2_Hardening_Tangent_iso` | 124 | `PURE FUNCTION PLM_J2_Hardening_Tangent_iso(desc, peeq) RESULT(h_iso)` |
| SUBROUTINE | `PLM_J2_Back_Stress_Update` | 142 | `PURE SUBROUTINE PLM_J2_Back_Stress_Update(desc, delta_gamma, n_dir, alpha)` |
| SUBROUTINE | `PLM_J2_Build_D_el` | 156 | `SUBROUTINE PLM_J2_Build_D_el(desc, D)` |
| SUBROUTINE | `Assem_Stress_From_Deviatoric` | 165 | `PURE SUBROUTINE Assem_Stress_From_Deviatoric(stress_trial, s_dev, sigma)` |
| SUBROUTINE | `PLM_J2_Assem_Dev` | 177 | `SUBROUTINE PLM_J2_Assem_Dev(stress_trial, s_dev, sigma, ntens)` |
| SUBROUTINE | `PLM_J2_EP_Tangent` | 192 | `SUBROUTINE PLM_J2_EP_Tangent(desc, sigma6, ntens, plastic_step, peeq_tan, Dout)` |
| SUBROUTINE | `PH_Mat_PLM_J2_UMAT_API` | 238 | `SUBROUTINE PH_Mat_PLM_J2_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &` |
| SUBROUTINE | `MD_Mat_PLM_J2_Desc_Validate` | 342 | `SUBROUTINE MD_Mat_PLM_J2_Desc_Validate(self, nprops, props, st)` |
| SUBROUTINE | `MD_Mat_PLM_J2_Desc_Init` | 360 | `SUBROUTINE MD_Mat_PLM_J2_Desc_Init(self, nprops, props, st)` |
| SUBROUTINE | `J2_InitStateVars` | 402 | `SUBROUTINE J2_InitStateVars(min_in, mout_out)` |
| SUBROUTINE | `PH_Mat_PLM_J2_UpdateStress` | 442 | `SUBROUTINE PH_Mat_PLM_J2_UpdateStress(in, out)` |
| SUBROUTINE | `PH_Mat_PLM_J2_UMAT` | 525 | `SUBROUTINE PH_Mat_PLM_J2_UMAT(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
