# `PH_Elem_B31T.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31T.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31T`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31T`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31T`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31T.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31T_FormStiffMatrix` | 57 | `SUBROUTINE PH_Elem_B31T_FormStiffMatrix(coords3, E_young, nu, area, Iy, Iz, J_tors, &` |
| SUBROUTINE | `PH_Elem_B31T_FormIntForce` | 127 | `SUBROUTINE PH_Elem_B31T_FormIntForce(coords3, u14, E_young, nu, area, Iy, Iz, J_tors, &` |
| SUBROUTINE | `UF_Elem_B31T_Calc` | 167 | `SUBROUTINE UF_Elem_B31T_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_Elem_B31T_ConsMassMatrix` | 338 | `SUBROUTINE PH_Elem_B31T_ConsMassMatrix(coords3, rho, area, Me14, status)` |
| SUBROUTINE | `PH_Elem_B31T_LumpMassVector` | 402 | `SUBROUTINE PH_Elem_B31T_LumpMassVector(coords3, rho, area, M_lumped14, status)` |
| SUBROUTINE | `PH_Elem_B31T_FormDamping` | 457 | `SUBROUTINE PH_Elem_B31T_FormDamping(coords3, E_young, nu, area, Iy, Iz, J_tors, &` |
| SUBROUTINE | `PH_B31T_EnsureStorage14` | 522 | `SUBROUTINE PH_B31T_EnsureStorage14(state_out)` |
| SUBROUTINE | `PH_Elem_B31T_NL_TL` | 551 | `SUBROUTINE PH_Elem_B31T_NL_TL(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_Elem_B31T_NL_UL` | 717 | `SUBROUTINE PH_Elem_B31T_NL_UL(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_Elem_B31T_FillKutAxial` | 888 | `SUBROUTINE PH_Elem_B31T_FillKutAxial(coords3, E_young, area, alpha_cte, el_len, Ke14)` |
| SUBROUTINE | `PH_B31T_FormGeometricStiffness` | 1008 | `SUBROUTINE PH_B31T_FormGeometricStiffness(coords, axial_stress, area, K_geo)` |
| SUBROUTINE | `PH_B31T_ComputeInternalForce` | 1065 | `SUBROUTINE PH_B31T_ComputeInternalForce(coords, u, stress, area, Iy, Iz, J_tors, R_int)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
