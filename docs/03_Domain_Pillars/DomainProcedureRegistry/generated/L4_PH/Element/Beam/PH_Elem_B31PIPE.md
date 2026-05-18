# `PH_Elem_B31PIPE.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31PIPE.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31PIPE`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31PIPE`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31PIPE`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31PIPE.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31PIPE_FormStiffMatrix` | 54 | `SUBROUTINE PH_Elem_B31PIPE_FormStiffMatrix(coords3, E_young, nu, area, Iy, Iz, J_tors, &` |
| SUBROUTINE | `PH_Elem_B31PIPE_FormIntForce` | 92 | `SUBROUTINE PH_Elem_B31PIPE_FormIntForce(coords3, u14, D_mat, ip_stress, Rint14, status)` |
| SUBROUTINE | `PH_Elem_B31PIPE_PressureLoad` | 117 | `SUBROUTINE PH_Elem_B31PIPE_PressureLoad(coords3, p_inner, D_inner, t_wall, &` |
| SUBROUTINE | `PH_Elem_B31PIPE_ConsMassMatrix` | 177 | `SUBROUTINE PH_Elem_B31PIPE_ConsMassMatrix(coords3, rho, area, Me14, status)` |
| SUBROUTINE | `PH_Elem_B31PIPE_LumpMassVector` | 198 | `SUBROUTINE PH_Elem_B31PIPE_LumpMassVector(coords3, rho, area, M_lumped14, status)` |
| SUBROUTINE | `PH_Elem_B31PIPE_RecoverStress` | 221 | `SUBROUTINE PH_Elem_B31PIPE_RecoverStress(coords3, u14, p_inner, D_inner, t_wall, &` |
| SUBROUTINE | `UF_Elem_B31PIPE_Calc` | 266 | `SUBROUTINE UF_Elem_B31PIPE_Calc(elem_type, formul, ctx, state_in, mat, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
