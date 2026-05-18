# `RT_Mat_Core.f90`

- **Source**: `L5_RT/Material/RT_Mat_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Mat_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mat_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mat`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Material/RT_Mat_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Mat_Init_Table` | 41 | `SUBROUTINE RT_Mat_Init_Table(table, status)` |
| SUBROUTINE | `RT_Mat_Finalize_Table` | 63 | `SUBROUTINE RT_Mat_Finalize_Table(table, status)` |
| SUBROUTINE | `RT_Mat_Register_Route` | 85 | `SUBROUTINE RT_Mat_Register_Route(table, mat_type, mat_id, mat_pt_idx, &` |
| SUBROUTINE | `RT_Mat_Get_Route` | 122 | `SUBROUTINE RT_Mat_Get_Route(table, mat_id, ctx, status)` |
| SUBROUTINE | `RT_Mat_Dispatch_Stress` | 159 | `SUBROUTINE RT_Mat_Dispatch_Stress(ctx, status, material_dom)` |
| SUBROUTINE | `RT_Mat_Dispatch_Tangent` | 214 | `SUBROUTINE RT_Mat_Dispatch_Tangent(ctx, status, material_dom)` |
| SUBROUTINE | `RT_Mat_Get_Table_Summary` | 254 | `SUBROUTINE RT_Mat_Get_Table_Summary(table, n_active, n_user)` |
| SUBROUTINE | `RT_Mat_Swap_State` | 276 | `SUBROUTINE RT_Mat_Swap_State(table, n_ip, stress_old, stress_new, &` |
| SUBROUTINE | `RT_Mat_Cache_State` | 328 | `SUBROUTINE RT_Mat_Cache_State(n_ip, stress_src, sdv_src, &` |
| SUBROUTINE | `RT_Mat_Restore_Cache` | 368 | `SUBROUTINE RT_Mat_Restore_Cache(n_ip, stress_cache, sdv_cache, &` |
| SUBROUTINE | `RT_Mat_Checkpoint` | 394 | `SUBROUTINE RT_Mat_Checkpoint(table, n_ip, stress, sdv, &` |
| SUBROUTINE | `RT_Mat_Restore_Checkpoint` | 440 | `SUBROUTINE RT_Mat_Restore_Checkpoint(chk_stress, chk_sdv, n_ip, &` |
| SUBROUTINE | `RT_Mat_Alloc_StateVars` | 460 | `SUBROUTINE RT_Mat_Alloc_StateVars(n_comp, n_sdv, n_ip, &` |
| SUBROUTINE | `RT_Mat_Dealloc_StateVars` | 497 | `SUBROUTINE RT_Mat_Dealloc_StateVars(stress, sdv, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
