# `RT_Asm_DofMapUtils.f90`

- **Source**: `L5_RT/Solver/RT_Asm_DofMapUtils.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_DofMapUtils`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_DofMapUtils`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_DofMapUtils`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Asm_DofMapUtils.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `UF_GetEqId` | 28 | `PURE FUNCTION UF_GetEqId(dofMap, node_id, dof_local) RESULT(eq_id)` |
| FUNCTION | `UF_GetEqIdByDofType` | 47 | `FUNCTION UF_GetEqIdByDofType(model, dofMap, node_id, dof_type) RESULT(eq_id)` |
| FUNCTION | `RT_GetEqId` | 60 | `PURE FUNCTION RT_GetEqId(dofMap, node_id, dof_local) RESULT(eq_id)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
