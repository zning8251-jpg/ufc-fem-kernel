# `PH_Elem_B31TS.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31TS.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B31TS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31TS`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31TS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31TS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31TS_DefInit` | 75 | `SUBROUTINE PH_Elem_B31TS_DefInit(ElemDef, status)` |
| SUBROUTINE | `PH_Elem_B31TS_FormStiffMatrixWithShear` | 100 | `SUBROUTINE PH_Elem_B31TS_FormStiffMatrixWithShear(coords, props, Ke14)` |
| SUBROUTINE | `PH_Elem_B31TS_FormLocalStiffMat` | 227 | `SUBROUTINE PH_Elem_B31TS_FormLocalStiffMat(L, E, G, A, Iy, Iz, J_tors, kappa, Ke_loc)` |
| SUBROUTINE | `PH_Elem_B31TS_TransformStiffness` | 321 | `SUBROUTINE PH_Elem_B31TS_TransformStiffness(Ke_loc, R_global, Ke_glob)` |
| SUBROUTINE | `PH_Elem_B31TS_FormIntForce` | 353 | `SUBROUTINE PH_Elem_B31TS_FormIntForce(coords, props, u14, R14)` |
| SUBROUTINE | `PH_Elem_B31TS_ConsMassWithSection` | 372 | `SUBROUTINE PH_Elem_B31TS_ConsMassWithSection(coords, rho, area, Me14)` |
| SUBROUTINE | `PH_Elem_B31TS_LumpMassWithSection` | 380 | `SUBROUTINE PH_Elem_B31TS_LumpMassWithSection(coords, rho, area, M_lump14)` |
| SUBROUTINE | `UF_Elem_B31TS_Calc` | 391 | `SUBROUTINE UF_Elem_B31TS_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
