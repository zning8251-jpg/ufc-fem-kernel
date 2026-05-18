# `RT_Mesh_Impl.f90`

- **Source**: `L5_RT/Element/Mesh/RT_Mesh_Impl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Mesh_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mesh_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mesh_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/Mesh/RT_Mesh_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Mesh_Impl_Init` | 36 | `SUBROUTINE RT_Mesh_Impl_Init(input, output)` |
| SUBROUTINE | `RT_Mesh_Impl_Clean` | 83 | `SUBROUTINE RT_Mesh_Impl_Clean(input, output)` |
| SUBROUTINE | `RT_Mesh_Impl_Numbering` | 111 | `SUBROUTINE RT_Mesh_Impl_Numbering(input, output)` |
| SUBROUTINE | `RT_Mesh_Impl_UpdateCoords` | 155 | `SUBROUTINE RT_Mesh_Impl_UpdateCoords(input, output)` |
| SUBROUTINE | `RT_Mesh_Impl_GetState` | 204 | `SUBROUTINE RT_Mesh_Impl_GetState(input, output)` |
| SUBROUTINE | `RT_Mesh_Impl_Assembly` | 245 | `SUBROUTINE RT_Mesh_Impl_Assembly(input, output)` |
| SUBROUTINE | `InitializeCoordsFromMD` | 281 | `SUBROUTINE InitializeCoordsFromMD(md_registry, coords)` |
| FUNCTION | `FindNodeIndex` | 291 | `FUNCTION FindNodeIndex(node_id) RESULT(idx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
