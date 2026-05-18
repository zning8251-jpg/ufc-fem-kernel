# `PH_WB_Brg.f90`

- **Source**: `L4_PH/Bridge/WriteBack/PH_WB_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_WB_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_WB_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_WB`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/WriteBack/PH_WB_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_WriteBack_ApplyNodeDisp` | 35 | `SUBROUTINE PH_WriteBack_ApplyNodeDisp(node_idx, disp, status)` |
| SUBROUTINE | `PH_WriteBack_ApplyNodeVel` | 47 | `SUBROUTINE PH_WriteBack_ApplyNodeVel(node_idx, vel, status)` |
| SUBROUTINE | `PH_WriteBack_ApplyNodeAccel` | 59 | `SUBROUTINE PH_WriteBack_ApplyNodeAccel(node_idx, accel, status)` |
| SUBROUTINE | `PH_WriteBack_ApplyNodePos` | 71 | `SUBROUTINE PH_WriteBack_ApplyNodePos(node_idx, coords, status)` |
| SUBROUTINE | `PH_WriteBack_ApplyElemStress` | 87 | `SUBROUTINE PH_WriteBack_ApplyElemStress(elem_idx, ip_idx, stress, status)` |
| SUBROUTINE | `PH_WriteBack_ApplyElemStrain` | 100 | `SUBROUTINE PH_WriteBack_ApplyElemStrain(elem_idx, ip_idx, strain, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
