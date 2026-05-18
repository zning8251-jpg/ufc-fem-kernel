# `PH_Elem_B31OS.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31OS.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31OS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31OS`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31OS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31OS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Elem_B31OS_Calc` | 27 | `SUBROUTINE UF_Elem_B31OS_Calc(elem_name, elem_desc, elem_state, &` |
| SUBROUTINE | `UF_Elem_B31OS_Calc` | 42 | `SUBROUTINE UF_Elem_B31OS_Calc(elem_name, elem_desc, elem_state, &` |
| SUBROUTINE | `PH_Elem_B31OS_FormStiffMatrix` | 102 | `SUBROUTINE PH_Elem_B31OS_FormStiffMatrix(coords3, E_young, nu, &` |
| SUBROUTINE | `PH_Elem_B31OS_FormIntForce` | 174 | `SUBROUTINE PH_Elem_B31OS_FormIntForce(coords3, u_elem, &` |
| SUBROUTINE | `PH_Elem_B31OS_RecoverStress` | 234 | `SUBROUTINE PH_Elem_B31OS_RecoverStress(coords3, u_elem, &` |
| SUBROUTINE | `PH_Elem_B31OS_SectionProperties` | 307 | `SUBROUTINE PH_Elem_B31OS_SectionProperties(section_type, dims, &` |
| SUBROUTINE | `PH_Elem_B31OS_ConsMassMatrix` | 481 | `SUBROUTINE PH_Elem_B31OS_ConsMassMatrix(coords3, rho, area, Iy, Iz, &` |
| SUBROUTINE | `PH_Elem_B31OS_LumpMassVector` | 603 | `SUBROUTINE PH_Elem_B31OS_LumpMassVector(coords3, rho, area, Iy, Iz, &` |
| SUBROUTINE | `PH_Elem_B31OS_RayleighDamping` | 683 | `SUBROUTINE PH_Elem_B31OS_RayleighDamping(Ke14, Me14, alpha, beta, Ce14, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 26–35 | `INTERFACE` |
