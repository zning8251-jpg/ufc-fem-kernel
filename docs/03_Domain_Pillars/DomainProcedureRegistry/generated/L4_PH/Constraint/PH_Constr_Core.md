# `PH_Constr_Core.f90`

- **Source**: `L4_PH/Constraint/PH_Constr_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Constr_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Constr_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Constr`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Constraint/PH_Constr_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Constr_IntCodeToStatus` | 39 | `SUBROUTINE PH_Constr_IntCodeToStatus(icode, err, tag)` |
| SUBROUTINE | `PH_Constraint_Core_Init` | 54 | `SUBROUTINE PH_Constraint_Core_Init(desc, state, algo, ctx, status)` |
| SUBROUTINE | `PH_Constraint_Core_Finalize` | 78 | `SUBROUTINE PH_Constraint_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `PH_Constraint_Build_MPC_Transform` | 101 | `SUBROUTINE PH_Constraint_Build_MPC_Transform(desc, ctx, status)` |
| SUBROUTINE | `PH_Constraint_Apply_Penalty` | 135 | `SUBROUTINE PH_Constraint_Apply_Penalty(desc, algo, K_local, F_local, status)` |
| SUBROUTINE | `PH_Constraint_Build_Lagrange` | 160 | `SUBROUTINE PH_Constraint_Build_Lagrange(desc, ctx, status)` |
| SUBROUTINE | `PH_Constraint_Compute_Reaction` | 180 | `SUBROUTINE PH_Constraint_Compute_Reaction(desc, forces, reaction, status)` |
| SUBROUTINE | `PH_Constraint_Check_Violation` | 199 | `SUBROUTINE PH_Constraint_Check_Violation(desc, u_vals, ctx, status)` |
| SUBROUTINE | `PH_Constraint_Apply` | 224 | `SUBROUTINE PH_Constraint_Apply(desc, algo, ctx, K_local, F_local, status)` |
| SUBROUTINE | `PH_Constraint_Release` | 297 | `SUBROUTINE PH_Constraint_Release(desc, algo, ctx, K_local, F_local, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
