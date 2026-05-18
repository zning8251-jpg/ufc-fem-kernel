# `PH_Elem_ShapeFunc.f90`

- **Source**: `L4_PH/Element/PH_Elem_ShapeFunc.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_ShapeFunc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_ShapeFunc`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_ShapeFunc`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_ShapeFunc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ShapeFuncHandler` | 25 | `SUBROUTINE ShapeFuncHandler(xi, sf)` |
| SUBROUTINE | `ComputeShapeFunc` | 38 | `SUBROUTINE ComputeShapeFunc(elem_type_id, xi, sf)` |
| SUBROUTINE | `ComputeJacobian` | 125 | `SUBROUTINE ComputeJacobian(sf, coords)` |
| SUBROUTINE | `ComputeStrainDisplacementMatrix` | 189 | `SUBROUTINE ComputeStrainDisplacementMatrix(sf, ndofel, B_matrix)` |
| SUBROUTINE | `InvertMatrix` | 254 | `SUBROUTINE InvertMatrix(A, A_inv, n)` |
| SUBROUTINE | `ComputeShape_Hex8` | 316 | `SUBROUTINE ComputeShape_Hex8(xi, sf)` |
| SUBROUTINE | `ComputeShape_Tet4` | 378 | `SUBROUTINE ComputeShape_Tet4(xi, sf)` |
| SUBROUTINE | `ComputeShape_Quad4` | 409 | `SUBROUTINE ComputeShape_Quad4(xi, sf)` |
| SUBROUTINE | `ComputeShape_Tri3` | 442 | `SUBROUTINE ComputeShape_Tri3(xi, sf)` |
| SUBROUTINE | `ComputeShape_Line2` | 471 | `SUBROUTINE ComputeShape_Line2(xi, sf)` |
| SUBROUTINE | `ComputeShape_Hex20` | 497 | `SUBROUTINE ComputeShape_Hex20(xi, sf)` |
| SUBROUTINE | `ComputeShape_Tet10` | 614 | `SUBROUTINE ComputeShape_Tet10(xi, sf)` |
| SUBROUTINE | `ComputeShape_Wedge6` | 666 | `SUBROUTINE ComputeShape_Wedge6(xi, sf)` |
| SUBROUTINE | `ComputeShape_Wedge15` | 700 | `SUBROUTINE ComputeShape_Wedge15(xi, sf)` |
| SUBROUTINE | `ComputeShape_Quad8` | 801 | `SUBROUTINE ComputeShape_Quad8(xi, sf)` |
| SUBROUTINE | `ComputeShape_Tri6` | 845 | `SUBROUTINE ComputeShape_Tri6(xi, sf)` |
| SUBROUTINE | `ComputeShape_Hex27` | 884 | `SUBROUTINE ComputeShape_Hex27(xi, sf)` |
| SUBROUTINE | `ComputeShape_Line3` | 980 | `SUBROUTINE ComputeShape_Line3(xi, sf)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
