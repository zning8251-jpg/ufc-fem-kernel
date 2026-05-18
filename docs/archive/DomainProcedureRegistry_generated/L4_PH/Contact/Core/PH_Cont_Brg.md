# `PH_Cont_Brg.f90`

- **Source**: `L4_PH/Contact/Core/PH_Cont_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Contact/Core`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Core/PH_Cont_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Cont_AlgorithmFramework_API` | 69 | `SUBROUTINE PH_Cont_AlgorithmFramework_API(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_ApplyConstraints_API` | 106 | `SUBROUTINE PH_Cont_ApplyConstraints_API(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_CalculateGap_API` | 143 | `SUBROUTINE PH_Cont_CalculateGap_API(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_CheckConvergence_API` | 174 | `SUBROUTINE PH_Cont_CheckConvergence_API(ctx, out)` |
| SUBROUTINE | `PH_Cont_ConvergenceCheck_API` | 192 | `SUBROUTINE PH_Cont_ConvergenceCheck_API(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_DetectPenetration_API` | 217 | `SUBROUTINE PH_Cont_DetectPenetration_API(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_Dynamic_Contact_API` | 244 | `SUBROUTINE PH_Cont_Dynamic_Contact_API(ctx, relative_velocity, contact_area, dt, status)` |
| SUBROUTINE | `PH_Cont_Dynamic_Contact_Structured` | 267 | `SUBROUTINE PH_Cont_Dynamic_Contact_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_Friction_Algo_API` | 303 | `SUBROUTINE PH_Cont_Friction_Algo_API(ctx, slip_velocity, slip_magnitude, dt, status)` |
| SUBROUTINE | `PH_Cont_Friction_Algo_Structured` | 326 | `SUBROUTINE PH_Cont_Friction_Algo_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_Penetration_Algo_API` | 357 | `SUBROUTINE PH_Cont_Penetration_Algo_API(ctx, slave_coords, master_coords, &` |
| SUBROUTINE | `PH_Cont_Penetration_Algo_Structured` | 388 | `SUBROUTINE PH_Cont_Penetration_Algo_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_SearchPairs_API` | 426 | `SUBROUTINE PH_Cont_SearchPairs_API(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_Thermal_Contact_API` | 469 | `SUBROUTINE PH_Cont_Thermal_Contact_API(ctx, temperature_slave, temperature_master, &` |
| SUBROUTINE | `PH_Cont_Thermal_Contact_Structured` | 493 | `SUBROUTINE PH_Cont_Thermal_Contact_Structured(ctx, in, out)` |
| SUBROUTINE | `PH_Cont_UpdateFriction_API` | 524 | `SUBROUTINE PH_Cont_UpdateFriction_API(ctx, in, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
