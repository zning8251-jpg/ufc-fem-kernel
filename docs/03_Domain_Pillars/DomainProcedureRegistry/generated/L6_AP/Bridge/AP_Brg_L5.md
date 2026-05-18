# `AP_Brg_L5.f90`

- **Source**: `L6_AP/Bridge/AP_Brg_L5.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Brg_L5`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Brg_L5`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Brg_L5`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Bridge/AP_Brg_L5.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Brg_AP_Configure_Solver_ToCtx` | 66 | `SUBROUTINE Brg_AP_Configure_Solver_ToCtx(ctx, solver_cfg, status)` |
| SUBROUTINE | `Brg_AP_Configure_Solver` | 123 | `SUBROUTINE Brg_AP_Configure_Solver(solver_cfg, job_name, ierr)` |
| SUBROUTINE | `Brg_AP_SetJobCtx_InContainer` | 138 | `SUBROUTINE Brg_AP_SetJobCtx_InContainer(ctx)` |
| SUBROUTINE | `Brg_AP_SetRTDrvCtx` | 149 | `SUBROUTINE Brg_AP_SetRTDrvCtx(ctx)` |
| SUBROUTINE | `Brg_AP_StepRunner_RT` | 164 | `SUBROUTINE Brg_AP_StepRunner_RT(descJob, stateModel, stepIndex, opts, ierr)` |
| SUBROUTINE | `Brg_AP_Get_Job_Status_FromCtx` | 199 | `SUBROUTINE Brg_AP_Get_Job_Status_FromCtx(ctx, status_code, message, status)` |
| SUBROUTINE | `Brg_AP_Get_Job_Status` | 233 | `SUBROUTINE Brg_AP_Get_Job_Status(job_name, status_code, message, ierr)` |
| SUBROUTINE | `Brg_AP_Query_Runtime_State_FromField` | 244 | `SUBROUTINE Brg_AP_Query_Runtime_State_FromField(field_state, query_type, result, status)` |
| SUBROUTINE | `Brg_AP_Query_Runtime_State` | 315 | `SUBROUTINE Brg_AP_Query_Runtime_State(query_type, result, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
