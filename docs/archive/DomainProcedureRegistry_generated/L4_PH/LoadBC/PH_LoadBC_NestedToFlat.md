# `PH_LoadBC_NestedToFlat.f90`

- **Source**: `L4_PH/LoadBC/PH_LoadBC_NestedToFlat.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_LoadBC_NestedToFlat`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_LoadBC_NestedToFlat`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_LoadBC_NestedToFlat`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_LoadBC_NestedToFlat.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_L4_Populate_Load` | 44 | `SUBROUTINE PH_L4_Populate_Load(md_ctrl, step_time, amp_curves, ph_load_ctrl)` |
| SUBROUTINE | `PH_L4_Populate_BC` | 107 | `SUBROUTINE PH_L4_Populate_BC(md_ctrl, step_time, amp_curves, ph_bc_ctrl)` |
| FUNCTION | `PH_InterpolateAmpCurve` | 171 | `FUNCTION PH_InterpolateAmpCurve(ampName, time, amp_curves) RESULT(amp_factor)` |
| SUBROUTINE | `PH_L4_WriteBack_BC` | 244 | `SUBROUTINE PH_L4_WriteBack_BC(md_ctrl, ph_bc_ctrl, writeback_mask, reaction_forces)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
