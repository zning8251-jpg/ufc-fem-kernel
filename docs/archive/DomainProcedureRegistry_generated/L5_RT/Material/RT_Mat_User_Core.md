# `RT_Mat_User_Core.f90`

- **Source**: `L5_RT/Material/RT_Mat_User_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Mat_User_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mat_User_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mat_User`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Material/RT_Mat_User_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Mat_User_Dispatch_Run` | 41 | `SUBROUTINE RT_Mat_User_Dispatch_Run(desc, state, algo, ctx, args, status)` |
| SUBROUTINE | `RT_Mat_User_Init_Dispatch_Table` | 61 | `SUBROUTINE RT_Mat_User_Init_Dispatch_Table(max_entries, status)` |
| SUBROUTINE | `RT_Mat_User_Build_Table_From_L4` | 75 | `SUBROUTINE RT_Mat_User_Build_Table_From_L4(l4_mat_ids, l4_sub_types, &` |
| SUBROUTINE | `RT_Mat_User_Dispatch` | 100 | `SUBROUTINE RT_Mat_User_Dispatch(mat_id, ip_index, strain, stress, ddsdde, status)` |
| SUBROUTINE | `RT_Mat_User_Commit_State` | 136 | `SUBROUTINE RT_Mat_User_Commit_State(mat_id, ip_index, status)` |
| SUBROUTINE | `RT_Mat_User_Rollback_State` | 143 | `SUBROUTINE RT_Mat_User_Rollback_State(mat_id, ip_index, status)` |
| SUBROUTINE | `RT_Mat_User_Assemble_UMAT_Context` | 161 | `SUBROUTINE RT_Mat_User_Assemble_UMAT_Context( &` |
| SUBROUTINE | `RT_Mat_User_Call_Enhanced_From_Context` | 252 | `SUBROUTINE RT_Mat_User_Call_Enhanced_From_Context(ctx, mat_classifier, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
