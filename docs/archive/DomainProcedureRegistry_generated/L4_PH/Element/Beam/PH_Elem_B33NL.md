# `PH_Elem_B33NL.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B33NL.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B33NL`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B33NL`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B33NL`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B33NL.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B33NL_DefInit` | 66 | `SUBROUTINE PH_Elem_B33NL_DefInit(ElemDef, status)` |
| SUBROUTINE | `PH_Elem_B33NL_ConsMassWithSection` | 91 | `SUBROUTINE PH_Elem_B33NL_ConsMassWithSection(coords, rho, area, Me)` |
| SUBROUTINE | `PH_Elem_B33NL_FormStiffMatrix` | 142 | `SUBROUTINE PH_Elem_B33NL_FormStiffMatrix(coords, E_young, nu, area, I_bend, Ke)` |
| SUBROUTINE | `PH_Elem_B33NL_FormStiffMatrixTan` | 231 | `SUBROUTINE PH_Elem_B33NL_FormStiffMatrixTan(coords_ref, u, E_young, nu, &` |
| SUBROUTINE | `PH_Elem_B33NL_FormIntForce` | 436 | `SUBROUTINE PH_Elem_B33NL_FormIntForce(coords_ref, u, E_young, nu, area, I_bend, Re)` |
| SUBROUTINE | `PH_Elem_B33NL_LumpMassWithSection` | 466 | `SUBROUTINE PH_Elem_B33NL_LumpMassWithSection(coords, rho, area, M_lumped)` |
| SUBROUTINE | `UF_Elem_B33NL_Calc` | 509 | `SUBROUTINE UF_Elem_B33NL_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
