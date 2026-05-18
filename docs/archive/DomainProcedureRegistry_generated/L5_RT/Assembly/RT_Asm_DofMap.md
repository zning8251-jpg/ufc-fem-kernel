# `RT_Asm_DofMap.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_DofMap.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_DofMap`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_DofMap`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_DofMap`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_DofMap.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `FindNodeInPart` | 70 | `function FindNodeInPart(part_local, nid) result(node_ptr)` |
| SUBROUTINE | `FreeDofMap` | 86 | `subroutine FreeDofMap(map)` |
| SUBROUTINE | `MarkPartNodes` | 137 | `subroutine MarkPartNodes(part, map)` |
| SUBROUTINE | `RT_Asm_DofMap_BuildFromMesh` | 172 | `subroutine RT_Asm_DofMap_BuildFromMesh(dofMap)` |
| SUBROUTINE | `RT_Asm_DofMap_Build` | 251 | `subroutine RT_Asm_DofMap_Build(model, dofMap)` |
| SUBROUTINE | `AssignEqFieldIds` | 574 | `subroutine AssignEqFieldIds(model, map)` |
| SUBROUTINE | `AssignPartEqFields` | 592 | `subroutine AssignPartEqFields(part, map)` |
| SUBROUTINE | `RT_Asm_DofMap_Unified_Cfg` | 679 | `subroutine RT_Asm_DofMap_Unified_Cfg(model, field_types, dof_map, status)` |
| SUBROUTINE | `RT_Asm_DofMap_Unified_Manage` | 719 | `subroutine RT_Asm_DofMap_Unified_Manage(model, dof_map, operation, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
