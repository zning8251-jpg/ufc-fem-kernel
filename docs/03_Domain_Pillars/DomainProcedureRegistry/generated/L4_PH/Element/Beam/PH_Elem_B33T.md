# `PH_Elem_B33T.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B33T.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B33T`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B33T`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B33T`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B33T.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B33T_FormStiffMatrix` | 54 | `SUBROUTINE PH_Elem_B33T_FormStiffMatrix(coords3, E_young, nu, area, I_bend, &` |
| SUBROUTINE | `PH_Elem_B33T_FormIntForce` | 124 | `SUBROUTINE PH_Elem_B33T_FormIntForce(coords3, u8, E_young, nu, area, I_bend, &` |
| SUBROUTINE | `PH_Elem_B33T_ConsMassMatrix` | 162 | `SUBROUTINE PH_Elem_B33T_ConsMassMatrix(coords3, rho, area, Me8, status)` |
| SUBROUTINE | `PH_Elem_B33T_LumpMassVector` | 218 | `SUBROUTINE PH_Elem_B33T_LumpMassVector(coords3, rho, area, M_lumped8, status)` |
| SUBROUTINE | `UF_Elem_B33T_Calc` | 267 | `SUBROUTINE UF_Elem_B33T_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_B33T_EnsureStorage8` | 437 | `SUBROUTINE PH_B33T_EnsureStorage8(state_out)` |
| SUBROUTINE | `PH_Elem_B33T_FillKutAxial` | 466 | `SUBROUTINE PH_Elem_B33T_FillKutAxial(coords3, E_young, area, alpha_cte, el_len, Ke8)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
