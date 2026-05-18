# `MD_Constr_Brg.f90`

- **Source**: `L3_MD/Constraint/MD_Constr_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Constr_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Constr_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Constr`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Constraint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Constraint/MD_Constr_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `push_unique` | 44 | `SUBROUTINE push_unique(list, n, nid, overflow)` |
| SUBROUTINE | `sort_nodes` | 64 | `SUBROUTINE sort_nodes(a, n)` |
| SUBROUTINE | `MD_SurfaceDef_CollectNodes` | 80 | `SUBROUTINE MD_SurfaceDef_CollectNodes(elem_ids, n_faces, nodes, nn, status)` |
| SUBROUTINE | `MD_ElemSet_CollectNodes` | 123 | `SUBROUTINE MD_ElemSet_CollectNodes(member_elems, n_mem, nodes, nn, status)` |
| SUBROUTINE | `MD_TieConstraint_TryResolveSurfaces` | 169 | `SUBROUTINE MD_TieConstraint_TryResolveSurfaces(tie, status)` |
| SUBROUTINE | `MD_CplConstraint_TryResolveSurfaceOrElset` | 283 | `SUBROUTINE MD_CplConstraint_TryResolveSurfaceOrElset(cpl, status)` |
| SUBROUTINE | `MD_RigidBody_TryResolveFromAssembly` | 352 | `SUBROUTINE MD_RigidBody_TryResolveFromAssembly(rbd, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
