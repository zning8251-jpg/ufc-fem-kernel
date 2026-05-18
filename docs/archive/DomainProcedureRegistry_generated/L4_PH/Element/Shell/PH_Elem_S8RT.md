# `PH_Elem_S8RT.f90`

- **Source**: `L4_PH/Element/Shell/PH_Elem_S8RT.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_S8RT`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_S8RT`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_S8RT`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shell`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shell/PH_Elem_S8RT.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_S8RT_FormStiffMatrix` | 34 | `SUBROUTINE PH_Elem_S8RT_FormStiffMatrix(coords3, E_young, nu, k_thermal, Ke56, status)` |
| SUBROUTINE | `PH_Elem_S8RT_FormIntForce` | 60 | `SUBROUTINE PH_Elem_S8RT_FormIntForce(coords3, u56, E_young, nu, k_thermal, R56, status)` |
| SUBROUTINE | `UF_Elem_S8RT_Calc` | 79 | `SUBROUTINE UF_Elem_S8RT_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_S8RT_EnsureStorage56` | 168 | `SUBROUTINE PH_S8RT_EnsureStorage56(state_out)` |
| SUBROUTINE | `PH_Elem_S8RT_Material_Update_Membrane_Routed` | 184 | `SUBROUTINE PH_Elem_S8RT_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_S8RT_Material_Update_Thermal_Routed` | 201 | `SUBROUTINE PH_Elem_S8RT_Material_Update_Thermal_Routed(rt_ctx, mat_slot, temp_gradient, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
