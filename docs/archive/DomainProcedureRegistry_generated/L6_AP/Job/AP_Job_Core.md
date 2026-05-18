# `AP_Job_Core.f90`

- **Source**: `L6_AP/Job/AP_Job_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Job_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Job_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Job`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Job`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Job/AP_Job_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Job_Core_Init` | 33 | `SUBROUTINE AP_Job_Core_Init(desc, state, status)` |
| SUBROUTINE | `AP_Job_Core_Finalize` | 45 | `SUBROUTINE AP_Job_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `AP_Job_Create` | 60 | `SUBROUTINE AP_Job_Create(desc, job_name, input_file, job_type, status)` |
| SUBROUTINE | `AP_Job_Run` | 83 | `SUBROUTINE AP_Job_Run(desc, state, status)` |
| FUNCTION | `AP_Job_Get_Status` | 99 | `FUNCTION AP_Job_Get_Status(state) RESULT(s)` |
| SUBROUTINE | `AP_Job_Abort` | 108 | `SUBROUTINE AP_Job_Abort(state, status)` |
| SUBROUTINE | `AP_Job_Summary` | 120 | `SUBROUTINE AP_Job_Summary(desc, state, unit_num, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
