# `PH_WB_Core.f90`

- **Source**: `L4_PH/WriteBack/PH_WB_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_WB_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_WB_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_WB`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/WriteBack/PH_WB_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_WB_PrepareNodeDisp` | 33 | `SUBROUTINE PH_WB_PrepareNodeDisp(node_idx, disp, buffer, buf_pos, status)` |
| SUBROUTINE | `PH_WB_PrepareNodeVel` | 57 | `SUBROUTINE PH_WB_PrepareNodeVel(node_idx, vel, buffer, buf_pos, status)` |
| SUBROUTINE | `PH_WB_PrepareNodeAccel` | 81 | `SUBROUTINE PH_WB_PrepareNodeAccel(node_idx, accel, buffer, buf_pos, status)` |
| SUBROUTINE | `PH_WB_PrepareElemStress` | 105 | `SUBROUTINE PH_WB_PrepareElemStress(elem_idx, stress_voigt, buffer, buf_pos, status)` |
| SUBROUTINE | `PH_WB_PrepareElemStrain` | 131 | `SUBROUTINE PH_WB_PrepareElemStrain(elem_idx, strain_voigt, buffer, buf_pos, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
