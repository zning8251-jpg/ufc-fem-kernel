# `MD_Mesh_Elem.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Elem.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mesh_Elem`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Elem`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_Elem`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Elem.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IPState_Init` | 77 | `SUBROUTINE IPState_Init(this, n)` |
| SUBROUTINE | `IPState_RegLayout` | 85 | `SUBROUTINE IPState_RegLayout(this)` |
| SUBROUTINE | `IPState_Ensure` | 134 | `SUBROUTINE IPState_Ensure(this)` |
| SUBROUTINE | `MeshElemDesc_Init` | 147 | `SUBROUTINE MeshElemDesc_Init(this)` |
| SUBROUTINE | `MeshElemDesc_RegLayout` | 153 | `SUBROUTINE MeshElemDesc_RegLayout(this)` |
| SUBROUTINE | `MeshElemDesc_Ensure` | 176 | `SUBROUTINE MeshElemDesc_Ensure(this)` |
| SUBROUTINE | `MeshElemState_Init` | 189 | `SUBROUTINE MeshElemState_Init(this, n)` |
| SUBROUTINE | `MeshElemState_RegLayout` | 196 | `SUBROUTINE MeshElemState_RegLayout(this)` |
| SUBROUTINE | `MeshElemState_Ensure` | 255 | `SUBROUTINE MeshElemState_Ensure(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
