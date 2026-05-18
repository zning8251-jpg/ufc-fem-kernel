# `PH_Cont_BVHQuery.f90`

- **Source**: `L4_PH/Contact/Search/PH_Cont_BVHQuery.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_BVHQuery`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_BVHQuery`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_BVHQuery`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Search`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Search/PH_Cont_BVHQuery.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ContBVH_Traverse` | 37 | `SUBROUTINE PH_ContBVH_Traverse(root, query_bbox_min, query_bbox_max, &` |
| SUBROUTINE | `PH_ContBVH_QueryPoint` | 146 | `SUBROUTINE PH_ContBVH_QueryPoint(root, query_point, tolerance, &` |
| SUBROUTINE | `PH_ContBVH_QuerySegment` | 213 | `SUBROUTINE PH_ContBVH_QuerySegment(root, seg_coords, tolerance, &` |
| SUBROUTINE | `PH_ContBVH_CollectCandidates` | 288 | `SUBROUTINE PH_ContBVH_CollectCandidates(bvh_list, n_bvhs, query_coords, &` |
| FUNCTION | `BoxOverlap` | 350 | `FUNCTION BoxOverlap(min1, max1, min2, max2) RESULT(overlap)` |
| SUBROUTINE | `ComputeBBox` | 371 | `SUBROUTINE ComputeBBox(coords, bbox_min, bbox_max)` |
| FUNCTION | `PointToSegmentDistSq` | 401 | `FUNCTION PointToSegmentDistSq(point, coords, seg_nodes) RESULT(dist_sq)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
