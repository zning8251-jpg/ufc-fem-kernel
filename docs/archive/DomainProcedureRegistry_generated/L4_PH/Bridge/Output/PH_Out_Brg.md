# `PH_Out_Brg.f90`

- **Source**: `L4_PH/Bridge/Output/PH_Out_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Out_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Out_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Out`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/Output/PH_Out_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Output_TransformCoords` | 49 | `SUBROUTINE PH_Output_TransformCoords(coords_global, rotation_matrix, &` |
| SUBROUTINE | `PH_Output_TransformTensor` | 68 | `SUBROUTINE PH_Output_TransformTensor(tensor_voigt, tensor_full, direction, status)` |
| SUBROUTINE | `PH_Output_InterpolateField` | 85 | `SUBROUTINE PH_Output_InterpolateField(nodal_values, shape_funcs, &` |
| SUBROUTINE | `PH_Output_GetScalar` | 104 | `SUBROUTINE PH_Output_GetScalar(field_data, component_idx, scalar_value, status)` |
| SUBROUTINE | `PH_Output_GetVector` | 121 | `SUBROUTINE PH_Output_GetVector(field_data, vector_values, status)` |
| SUBROUTINE | `PH_Output_GetTensor` | 136 | `SUBROUTINE PH_Output_GetTensor(field_data, tensor_values, notation, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
