# `RT_Asm_Brg.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Brg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_Brg_SyncMatBridgeMirror` | 69 | `SUBROUTINE RT_Asm_Brg_SyncMatBridgeMirror(mat_brg)` |
| SUBROUTINE | `RT_Asm_Brg_SyncElemBridgeMirror` | 74 | `SUBROUTINE RT_Asm_Brg_SyncElemBridgeMirror(elem_brg)` |
| SUBROUTINE | `RT_Asm_Brg_ApplyMatBridge_Flat_IP` | 79 | `SUBROUTINE RT_Asm_Brg_ApplyMatBridge_Flat_IP(mat_brg, mat_id, mat_family, algo_id, &` |
| SUBROUTINE | `RT_Asm_Brg_ApplyElemBridge_Flat_IP` | 100 | `SUBROUTINE RT_Asm_Brg_ApplyElemBridge_Flat_IP(elem_brg, elem_id, jtype, elem_family, &` |
| SUBROUTINE | `RT_Asm_Brg_FromL3Model` | 127 | `SUBROUTINE RT_Asm_Brg_FromL3Model(n_nodes, n_elems, n_dof_per_node, &` |
| SUBROUTINE | `RT_Asm_Brg_BuildElemDofMap` | 151 | `SUBROUTINE RT_Asm_Brg_BuildElemDofMap(elem_conn, n_nodes_elem, ndim, &` |
| SUBROUTINE | `RT_Asm_Brg_AllocGlobalSystem` | 179 | `SUBROUTINE RT_Asm_Brg_AllocGlobalSystem(n_dof_total, state, &` |
| SUBROUTINE | `RT_Asm_Brg_FreeGlobalSystem` | 203 | `SUBROUTINE RT_Asm_Brg_FreeGlobalSystem(state, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
