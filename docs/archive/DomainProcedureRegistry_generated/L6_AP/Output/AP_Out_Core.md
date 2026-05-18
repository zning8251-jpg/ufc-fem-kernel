# `AP_Out_Core.f90`

- **Source**: `L6_AP/Output/AP_Out_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Out_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Out_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Out`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_Out_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Output_Core_Init` | 34 | `SUBROUTINE AP_Output_Core_Init(desc, ctx, status)` |
| SUBROUTINE | `AP_Output_Core_Finalize` | 44 | `SUBROUTINE AP_Output_Core_Finalize(desc, ctx, status)` |
| SUBROUTINE | `AP_Output_Write_Report` | 57 | `SUBROUTINE AP_Output_Write_Report(desc, ctx, title, body, status)` |
| SUBROUTINE | `AP_Output_Write_Summary_Table` | 74 | `SUBROUTINE AP_Output_Write_Summary_Table(desc, ctx, n_rows, headers, values, status)` |
| SUBROUTINE | `AP_Output_Write_VTK_Header` | 97 | `SUBROUTINE AP_Output_Write_VTK_Header(desc, ctx, filename, n_nodes, n_elem, status)` |
| SUBROUTINE | `AP_Output_Write_VTK_Nodes` | 128 | `SUBROUTINE AP_Output_Write_VTK_Nodes(desc, ctx, n_nodes, ndim, coords, status)` |
| SUBROUTINE | `AP_Output_Write_VTK_Cells` | 152 | `SUBROUTINE AP_Output_Write_VTK_Cells(desc, ctx, n_elem, max_nn, conn, status)` |
| SUBROUTINE | `AP_Output_Write_VTK_Point_Vector` | 176 | `SUBROUTINE AP_Output_Write_VTK_Point_Vector(unit_num, field_name, &` |
| SUBROUTINE | `AP_Output_Write_VTK_Point_Scalar` | 202 | `SUBROUTINE AP_Output_Write_VTK_Point_Scalar(unit_num, field_name, &` |
| SUBROUTINE | `AP_Output_Write_VTK_Full` | 224 | `SUBROUTINE AP_Output_Write_VTK_Full(filename, n_nodes, n_elem, ndim, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
