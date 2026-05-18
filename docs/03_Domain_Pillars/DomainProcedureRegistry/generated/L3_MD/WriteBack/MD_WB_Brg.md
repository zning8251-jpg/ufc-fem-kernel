# `MD_WB_Brg.f90`

- **Source**: `L3_MD/WriteBack/MD_WB_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_WB_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_WB_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_WB`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/WriteBack/MD_WB_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init_WriteBack_API` | 71 | `SUBROUTINE Init_WriteBack_API(status)` |
| SUBROUTINE | `Finalize_WriteBack_API` | 91 | `SUBROUTINE Finalize_WriteBack_API()` |
| SUBROUTINE | `MD_WB_SetContainer` | 109 | `SUBROUTINE MD_WB_SetContainer(container, status)` |
| SUBROUTINE | `WB_Guard` | 126 | `SUBROUTINE WB_Guard(domain_name, field_name, status)` |
| SUBROUTINE | `MD_WB_Step` | 170 | `SUBROUTINE MD_WB_Step(step_idx, currentTime, currentInc, is_complete, status)` |
| SUBROUTINE | `MD_WB_Amplitude` | 190 | `SUBROUTINE MD_WB_Amplitude(idx, currentValue, currentTime, currentIndex, status, step_idx, incr_idx)` |
| SUBROUTINE | `MD_WB_LoadBC` | 218 | `SUBROUTINE MD_WB_LoadBC(load_idx, bc_idx, load_scale, load_active, &` |
| SUBROUTINE | `MD_WB_Mesh` | 244 | `SUBROUTINE MD_WB_Mesh(n_assembled, status)` |
| SUBROUTINE | `MD_WB_Mesh_NodePos` | 259 | `SUBROUTINE MD_WB_Mesh_NodePos(node_idx, new_coords, status)` |
| SUBROUTINE | `MD_WB_Mesh_NodeDisp` | 275 | `SUBROUTINE MD_WB_Mesh_NodeDisp(node_idx, new_disp, status)` |
| SUBROUTINE | `MD_WB_Mesh_NodeVel` | 288 | `SUBROUTINE MD_WB_Mesh_NodeVel(node_idx, new_vel, status)` |
| SUBROUTINE | `MD_WB_Mesh_NodeAcc` | 301 | `SUBROUTINE MD_WB_Mesh_NodeAcc(node_idx, new_acc, status)` |
| SUBROUTINE | `MD_WB_Mesh_ElemStress` | 315 | `SUBROUTINE MD_WB_Mesh_ElemStress(elem_idx, ip_idx, sigma, status)` |
| SUBROUTINE | `MD_WB_Model` | 334 | `SUBROUTINE MD_WB_Model(isBuilt, build_timestamp, status)` |
| SUBROUTINE | `MD_WB_Interaction` | 352 | `SUBROUTINE MD_WB_Interaction(pair_idx, contact_status, isActive, status, step_idx, incr_idx)` |
| SUBROUTINE | `MD_WB_Output` | 380 | `SUBROUTINE MD_WB_Output(lastWrittenInc, lastWrittenTime, totalFrames, status, step_idx, incr_idx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
