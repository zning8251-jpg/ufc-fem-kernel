# `IF_Reg_Ops.f90`

- **Source**: `L1_IF/Registry/IF_Reg_Ops.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Reg_Ops`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Reg_Ops`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Reg`
- **第四段角色（四段式）**: `_Ops`
- **源码子路径（层下目录，不含文件名）**: `Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Registry/IF_Reg_Ops.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Reg_State_Init` | 57 | `SUBROUTINE IF_Reg_State_Init(status)` |
| SUBROUTINE | `IF_Reg_State_GetRegistryStatus` | 93 | `SUBROUTINE IF_Reg_State_GetRegistryStatus(state, status)` |
| SUBROUTINE | `IF_Reg_State_GetComponentCount` | 121 | `SUBROUTINE IF_Reg_State_GetComponentCount(comp_type, count, status)` |
| SUBROUTINE | `IF_Reg_State_GetSolverCount` | 162 | `SUBROUTINE IF_Reg_State_GetSolverCount(solver_type, count, status)` |
| SUBROUTINE | `IF_Reg_State_GetPluginCount` | 196 | `SUBROUTINE IF_Reg_State_GetPluginCount(plugin_type, count, status)` |
| SUBROUTINE | `IF_Reg_State_GetCacheStats` | 230 | `SUBROUTINE IF_Reg_State_GetCacheStats(n_queries, n_hits, n_misses, hit_rate, status)` |
| SUBROUTINE | `IF_Reg_State_CheckComponentHealth` | 272 | `SUBROUTINE IF_Reg_State_CheckComponentHealth(is_healthy, n_degraded, status)` |
| SUBROUTINE | `IF_Reg_State_ClearCache` | 309 | `SUBROUTINE IF_Reg_State_ClearCache(status)` |
| SUBROUTINE | `IF_Reg_State_PrintSummary` | 339 | `SUBROUTINE IF_Reg_State_PrintSummary(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
