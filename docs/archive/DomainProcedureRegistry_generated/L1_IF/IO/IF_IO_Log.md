# `IF_IO_Log.f90`

- **Source**: `L1_IF/IO/IF_IO_Log.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_IO_Log`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Log`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_Log`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Log.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Log_Core_Init` | 32 | `SUBROUTINE IF_Log_Core_Init(log_file_path, log_level, success)` |
| SUBROUTINE | `IF_Log_Core_Shutdown` | 54 | `SUBROUTINE IF_Log_Core_Shutdown()` |
| SUBROUTINE | `IF_Log_Core_SetLevel` | 60 | `SUBROUTINE IF_Log_Core_SetLevel(log_level)` |
| SUBROUTINE | `IF_Log_Core_Debug` | 69 | `SUBROUTINE IF_Log_Core_Debug(message)` |
| SUBROUTINE | `IF_Log_Core_Info` | 76 | `SUBROUTINE IF_Log_Core_Info(message)` |
| SUBROUTINE | `IF_Log_Core_Warning` | 83 | `SUBROUTINE IF_Log_Core_Warning(message)` |
| SUBROUTINE | `IF_Log_Core_Error` | 90 | `SUBROUTINE IF_Log_Core_Error(message)` |
| SUBROUTINE | `IF_Log_Core_Fatal` | 97 | `SUBROUTINE IF_Log_Core_Fatal(message)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
