# `NM_BVH_Brg.f90`

- **Source**: `L2_NM/Base/BVH/NM_BVH_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_BVH_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_BVH_Brg`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_BVH`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Base/BVH`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Base/BVH/NM_BVH_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_BVH_Create` | 79 | `SUBROUTINE NM_BVH_Create(bvh, n_objects, max_depth, min_leaf_size, &` |
| SUBROUTINE | `BVH_Create_Simple` | 94 | `SUBROUTINE BVH_Create_Simple(bvh, n_objects, status)` |
| SUBROUTINE | `NM_BVH_Destroy` | 103 | `SUBROUTINE NM_BVH_Destroy(bvh)` |
| SUBROUTINE | `BVH_Build_Str` | 115 | `SUBROUTINE BVH_Build_Str(bvh, object_boxes, strategy, status)` |
| SUBROUTINE | `BVH_RayCast_Simple` | 143 | `SUBROUTINE BVH_RayCast_Simple(bvh, ray_origin, ray_direction, max_distance, &` |
| SUBROUTINE | `BVH_FindNearest_Simple` | 158 | `SUBROUTINE BVH_FindNearest_Simple(bvh, point, nearest_object, distance, status)` |
| FUNCTION | `NM_BVH_IsBuilt` | 173 | `FUNCTION NM_BVH_IsBuilt(bvh) RESULT(built)` |
| SUBROUTINE | `BVH_Rebuild_Wrap` | 182 | `SUBROUTINE BVH_Rebuild_Wrap(bvh, new_object_boxes, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 45–47 | `INTERFACE BVH_Create` |
| 49–51 | `INTERFACE BVH_Build` |
| 53–55 | `INTERFACE BVH_RayCast` |
| 57–59 | `INTERFACE BVH_FindNearest` |
| 61–63 | `INTERFACE BVH_Destroy` |
| 65–67 | `INTERFACE BVH_Rebuild` |
| 69–71 | `INTERFACE BVH_IsBuilt` |
