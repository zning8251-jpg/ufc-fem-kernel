# `PH_LoadBC_Core.f90`

- **Source**: `L4_PH/LoadBC/PH_LoadBC_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_LoadBC_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_LoadBC_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_LoadBC`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_LoadBC_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_LoadBC_Core_Init` | 30 | `SUBROUTINE PH_LoadBC_Core_Init(desc, state, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Core_Finalize` | 56 | `SUBROUTINE PH_LoadBC_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Concentrated_Force` | 83 | `SUBROUTINE PH_LoadBC_Concentrated_Force(desc, F_vec, status)` |
| SUBROUTINE | `PH_LoadBC_Distributed_Load` | 98 | `SUBROUTINE PH_LoadBC_Distributed_Load(desc, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Pressure_Load` | 117 | `SUBROUTINE PH_LoadBC_Pressure_Load(desc, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Body_Force` | 138 | `SUBROUTINE PH_LoadBC_Body_Force(desc, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Gravity_Load` | 159 | `SUBROUTINE PH_LoadBC_Gravity_Load(desc, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Thermal_Load` | 171 | `SUBROUTINE PH_LoadBC_Thermal_Load(desc, ctx, status)` |
| SUBROUTINE | `PH_LoadBC_Apply_Dirichlet` | 201 | `SUBROUTINE PH_LoadBC_Apply_Dirichlet(desc, K, F, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
