# `IF_ThreadWS_Brg.f90`

- **Source**: `L1_IF/Base/Parallel/IF_ThreadWS_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_ThreadWS_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_ThreadWS_Brg`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_ThreadWS`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Base/Parallel`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/Parallel/IF_ThreadWS_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ThreadWS_AllocLocal` | 58 | `SUBROUTINE ThreadWS_AllocLocal(thread_ws, thread_id, array_name, &` |
| SUBROUTINE | `ThreadWS_FreeLocal` | 72 | `SUBROUTINE ThreadWS_FreeLocal(thread_ws, thread_id, array_name, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
