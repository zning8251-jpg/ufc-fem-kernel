# `PH_Elem_B31H.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31H.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31H`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31H`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31H`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31H.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Elem_B31H_Calc` | 28 | `SUBROUTINE UF_Elem_B31H_Calc(elem_name, elem_desc, elem_state, &` |
| SUBROUTINE | `UF_Elem_B31H_Calc` | 43 | `SUBROUTINE UF_Elem_B31H_Calc(elem_name, elem_desc, elem_state, &` |
| SUBROUTINE | `PH_Elem_B31H_FormStiffMatrix` | 102 | `SUBROUTINE PH_Elem_B31H_FormStiffMatrix(coords3, E_young, nu, &` |
| SUBROUTINE | `PH_Elem_B31H_FormIntForce` | 292 | `SUBROUTINE PH_Elem_B31H_FormIntForce(coords3, u_elem, &` |
| SUBROUTINE | `PH_Elem_B31H_RecoverStress` | 365 | `SUBROUTINE PH_Elem_B31H_RecoverStress(coords3, u_elem, &` |
| SUBROUTINE | `PH_Elem_B31H_AssumedStrainField` | 427 | `SUBROUTINE PH_Elem_B31H_AssumedStrainField(coords3, epsilon_direct, epsilon_assumed, status)` |
| SUBROUTINE | `PH_Elem_B31H_IndependentStressField` | 468 | `SUBROUTINE PH_Elem_B31H_IndependentStressField(E_young, nu, epsilon_assumed, sigma_indep, status)` |
| SUBROUTINE | `PH_Elem_B31H_ConsMassMatrix` | 512 | `SUBROUTINE PH_Elem_B31H_ConsMassMatrix(coords3, rho, area, Iy, Iz, Me12, status)` |
| SUBROUTINE | `PH_Elem_B31H_LumpMassVector` | 610 | `SUBROUTINE PH_Elem_B31H_LumpMassVector(coords3, rho, area, Iy, Iz, M_lumped12, status)` |
| SUBROUTINE | `PH_Elem_B31H_RayleighDamping` | 682 | `SUBROUTINE PH_Elem_B31H_RayleighDamping(Ke12, Me12, alpha, beta, Ce12, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 27–36 | `INTERFACE` |
