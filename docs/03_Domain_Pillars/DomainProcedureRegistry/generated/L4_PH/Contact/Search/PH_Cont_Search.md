# `PH_Cont_Search.f90`

- **Source**: `L4_PH/Contact/Search/PH_Cont_Search.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_Search`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Search`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_Search`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Search`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Search/PH_Cont_Search.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ContSearch_Candidate` (lines 39–45)

```fortran
  TYPE :: PH_ContSearch_Candidate
    ! Narrow-phase candidate pair
    INTEGER(i4) :: slave_id
    INTEGER(i4) :: master_id
    REAL(wp) :: distance
    LOGICAL :: is_potential
  END TYPE PH_ContSearch_Candidate
```

### `PH_ContSearch_Result` (lines 47–54)

```fortran
  TYPE :: PH_ContSearch_Result
    ! Search result container
    INTEGER(i4) :: n_candidates
    INTEGER(i4) :: n_contacts
    TYPE(PH_ContSearch_Candidate), ALLOCATABLE :: candidates(:)
    INTEGER(i4), ALLOCATABLE :: contact_pairs(:,:)
    LOGICAL :: search_completed = .FALSE.
  END TYPE PH_ContSearch_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Cont_SearchPairs` | 62 | `SUBROUTINE PH_Cont_SearchPairs(slave_coords, master_coords, &` |
| SUBROUTINE | `PH_Cont_SpatialHash` | 131 | `SUBROUTINE PH_Cont_SpatialHash(coords, cell_size, hash_table, status)` |
| SUBROUTINE | `PH_Cont_BoundingBox` | 155 | `SUBROUTINE PH_Cont_BoundingBox(coords, bbox_min, bbox_max, status)` |
| SUBROUTINE | `PH_Cont_Pair_Identify` | 184 | `SUBROUTINE PH_Cont_Pair_Identify(candidates, n_cand, pairs, n_pairs, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
