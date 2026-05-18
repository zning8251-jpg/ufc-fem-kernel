# `PH_Elem_B33S.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B33S.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B33S`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B33S`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B33S`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B33S.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B33S_DefInit` | 67 | `SUBROUTINE PH_Elem_B33S_DefInit(ElemDef, status)` |
| SUBROUTINE | `PH_Elem_B33S_ConsMassWithSection` | 92 | `SUBROUTINE PH_Elem_B33S_ConsMassWithSection(coords, rho, area, Me)` |
| SUBROUTINE | `PH_Elem_B33S_FormStiffMatrix` | 146 | `SUBROUTINE PH_Elem_B33S_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_B33S_FormStiffMatrixWithSection` | 173 | `SUBROUTINE PH_Elem_B33S_FormStiffMatrixWithSection(coords, E_young, nu, area, I_bend, Ke)` |
| SUBROUTINE | `PH_Elem_B33S_FormStiffMatrixWithShear` | 198 | `SUBROUTINE PH_Elem_B33S_FormStiffMatrixWithShear(coords, E_young, nu, area, I_bend, kappa_shear, Ke)` |
| SUBROUTINE | `PH_Elem_B33S_FormIntForce` | 336 | `SUBROUTINE PH_Elem_B33S_FormIntForce(coords, u, E_young, nu, Re)` |
| SUBROUTINE | `PH_Elem_B33S_LumpMassWithSection` | 360 | `SUBROUTINE PH_Elem_B33S_LumpMassWithSection(coords, rho, area, M_lumped)` |
| SUBROUTINE | `UF_Elem_B33S_Calc` | 403 | `SUBROUTINE UF_Elem_B33S_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
