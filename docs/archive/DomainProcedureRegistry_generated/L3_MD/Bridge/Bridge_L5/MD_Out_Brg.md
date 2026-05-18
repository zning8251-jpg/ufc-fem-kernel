# `MD_Out_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L5/MD_Out_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Out_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L5`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L5/MD_Out_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Out_Brg_BuildFieldOutTasks` | 40 | `SUBROUTINE MD_Out_Brg_BuildFieldOutTasks(ctx)` |
| SUBROUTINE | `MD_Out_Brg_BuildFieldOutTasks_FromDomain` | 61 | `SUBROUTINE MD_Out_Brg_BuildFieldOutTasks_FromDomain(output_domain, step_domain, &` |
| SUBROUTINE | `MD_Out_Brg_BuildFieldOutTasks_Select` | 104 | `SUBROUTINE MD_Out_Brg_BuildFieldOutTasks_Select(ctx, step_idx, status)` |
| SUBROUTINE | `MD_Out_Brg_BuildHistOutTasks` | 141 | `SUBROUTINE MD_Out_Brg_BuildHistOutTasks(ctx)` |
| SUBROUTINE | `MD_Out_Brg_BuildHistOutTasks_FromDomain` | 162 | `SUBROUTINE MD_Out_Brg_BuildHistOutTasks_FromDomain(output_domain, step_domain, &` |
| SUBROUTINE | `MD_Out_Brg_BuildHistOutTasks_Select` | 205 | `SUBROUTINE MD_Out_Brg_BuildHistOutTasks_Select(ctx, step_idx, status)` |
| SUBROUTINE | `MD_Out_Brg_ShouldOutput` | 242 | `SUBROUTINE MD_Out_Brg_ShouldOutput(ctx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
