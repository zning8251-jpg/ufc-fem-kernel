# `MD_Mesh_Node.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Node.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mesh_Node`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Node`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_Node`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Node.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MeshNodeDesc_Init` | 55 | `SUBROUTINE MeshNodeDesc_Init(this, id, coords)` |
| SUBROUTINE | `MeshNodeDesc_RegLayout` | 64 | `SUBROUTINE MeshNodeDesc_RegLayout(this)` |
| SUBROUTINE | `MeshNodeDesc_Ensure` | 83 | `SUBROUTINE MeshNodeDesc_Ensure(this)` |
| SUBROUTINE | `MeshNodeState_Init` | 95 | `SUBROUTINE MeshNodeState_Init(this, id, coords, disp, vel, acc)` |
| SUBROUTINE | `MeshNodeState_RegLayout` | 107 | `SUBROUTINE MeshNodeState_RegLayout(this)` |
| SUBROUTINE | `MeshNodeState_Ensure` | 160 | `SUBROUTINE MeshNodeState_Ensure(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
