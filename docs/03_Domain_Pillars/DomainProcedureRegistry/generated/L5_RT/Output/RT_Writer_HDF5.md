# `RT_Writer_HDF5.f90`

- **Source**: `L5_RT/Output/RT_Writer_HDF5.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Writer_HDF5`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Writer_HDF5`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Writer_HDF5`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Writer_HDF5.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Writer_HDF5_Init` | 43 | `SUBROUTINE RT_Writer_HDF5_Init(filename, file_id, status)` |
| SUBROUTINE | `RT_Writer_HDF5_WriteFrame` | 92 | `SUBROUTINE RT_Writer_HDF5_WriteFrame(file_id, step_id, inc_id, time, &` |
| SUBROUTINE | `RT_Writer_HDF5_Close` | 204 | `SUBROUTINE RT_Writer_HDF5_Close(file_id, status)` |
| FUNCTION | `RT_Writer_HDF5_IsAvailable` | 233 | `FUNCTION RT_Writer_HDF5_IsAvailable() RESULT(available)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
