# `PH_Elem_B33.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B33.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B33`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B33`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B33`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B33.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_El_B33_ThermStrainVector` | 56 | `SUBROUTINE PH_El_B33_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_B33_ConsMass` | 62 | `SUBROUTINE PH_Elem_B33_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_B33_DefInit` | 69 | `SUBROUTINE PH_Elem_B33_DefInit()` |
| SUBROUTINE | `PH_Elem_B33_FormIntForce` | 72 | `SUBROUTINE PH_Elem_B33_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_B33_FormStiffMatrix` | 82 | `SUBROUTINE PH_Elem_B33_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_B33_LumpMass` | 139 | `SUBROUTINE PH_Elem_B33_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `UF_Elem_B33_Calc` | 149 | `SUBROUTINE UF_Elem_B33_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
