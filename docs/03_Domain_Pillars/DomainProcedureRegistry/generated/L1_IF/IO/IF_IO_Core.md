# `IF_IO_Core.f90`

- **Source**: `L1_IF/IO/IF_IO_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_IO_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Core`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_IO_Core_Init` | 27 | `SUBROUTINE IF_IO_Core_Init(desc, ctx, status)` |
| SUBROUTINE | `IF_IO_Core_Finalize` | 38 | `SUBROUTINE IF_IO_Core_Finalize(desc, ctx, status)` |
| SUBROUTINE | `IF_IO_Open` | 53 | `SUBROUTINE IF_IO_Open(desc, ctx, filename, unit_num, status)` |
| SUBROUTINE | `IF_IO_Close` | 78 | `SUBROUTINE IF_IO_Close(ctx, status)` |
| SUBROUTINE | `IF_IO_Write_Real_Array` | 97 | `SUBROUTINE IF_IO_Write_Real_Array(ctx, n, arr, status)` |
| SUBROUTINE | `IF_IO_Read_Real_Array` | 118 | `SUBROUTINE IF_IO_Read_Real_Array(ctx, n, arr, status)` |
| SUBROUTINE | `IF_IO_Read_Checkpoint` | 139 | `SUBROUTINE IF_IO_Read_Checkpoint(ctx, step_id, time, status)` |
| SUBROUTINE | `IF_IO_File_Exists` | 150 | `SUBROUTINE IF_IO_File_Exists(filename, exists)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
