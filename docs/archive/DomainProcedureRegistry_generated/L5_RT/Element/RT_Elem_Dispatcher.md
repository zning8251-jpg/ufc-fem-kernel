# `RT_Elem_Dispatcher.f90`

- **Source**: `L5_RT/Element/RT_Elem_Dispatcher.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_Dispatcher`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_Dispatcher`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem_Dispatcher`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_Dispatcher.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Elem_Dispatcher_Init` | 40 | `SUBROUTINE RT_Elem_Dispatcher_Init(router_table, max_families, status)` |
| SUBROUTINE | `RT_Elem_Dispatcher_Run` | 73 | `SUBROUTINE RT_Elem_Dispatcher_Run(state, ctx, router_table, status)` |
| SUBROUTINE | `RT_Elem_Dispatcher_Register` | 117 | `SUBROUTINE RT_Elem_Dispatcher_Register(router_table, family_id, compute_proc, status)` |
| FUNCTION | `RT_Elem_Dispatcher_GetCount` | 162 | `FUNCTION RT_Elem_Dispatcher_GetCount(router_table) RESULT(count)` |
| SUBROUTINE | `RT_Elem_Dispatcher_Unregister` | 171 | `SUBROUTINE RT_Elem_Dispatcher_Unregister(router_table, family_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
