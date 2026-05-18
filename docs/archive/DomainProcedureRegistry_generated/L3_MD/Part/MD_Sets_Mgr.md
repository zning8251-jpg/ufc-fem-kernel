# `MD_Sets_Mgr.f90`

- **Source**: `L3_MD/Part/MD_Sets_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Sets_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sets_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sets`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Part`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Part/MD_Sets_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_NodeSet` (lines 20–31)

```fortran
    TYPE :: UF_NodeSet
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4), ALLOCATABLE :: node_ids(:)
        LOGICAL :: is_generate = .FALSE.
        INTEGER(i4) :: gen_first = 0, gen_last = 0, gen_incr = 1
    CONTAINS
        PROCEDURE :: init => nodeset_init
        PROCEDURE :: add_node => nodeset_add_node
        PROCEDURE :: add_range => nodeset_add_range
        PROCEDURE :: contains => nodeset_contains
    END TYPE UF_NodeSet
```

### `UF_ElemSet` (lines 33–44)

```fortran
    TYPE :: UF_ElemSet
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: num_elems = 0
        INTEGER(i4), ALLOCATABLE :: elem_ids(:)
        LOGICAL :: is_generate = .FALSE.
        INTEGER(i4) :: gen_first = 0, gen_last = 0, gen_incr = 1
    CONTAINS
        PROCEDURE :: init => elemset_init
        PROCEDURE :: add_elem => elemset_add_elem
        PROCEDURE :: add_range => elemset_add_range
        PROCEDURE :: contains => elemset_contains
    END TYPE UF_ElemSet
```

### `UF_SurfaceFacet` (lines 46–51)

```fortran
    TYPE :: UF_SurfaceFacet
        INTEGER(i4) :: elem_id = 0
        INTEGER(i4) :: face_id = 0
        REAL(wp) :: area = 0.0_wp
        REAL(wp) :: normal(3) = 0.0_wp
    END TYPE UF_SurfaceFacet
```

### `UF_Surface` (lines 53–62)

```fortran
    TYPE :: UF_Surface
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: surface_type = SURF_TYPE_ELEMENT
        INTEGER(i4) :: num_facets = 0
        TYPE(UF_SurfaceFacet), ALLOCATABLE :: facets(:)
        REAL(wp) :: total_area = 0.0_wp
    CONTAINS
        PROCEDURE :: init => surface_init
        PROCEDURE :: add_facet => surface_add_facet
    END TYPE UF_Surface
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `nodeset_init` | 73 | `SUBROUTINE nodeset_init(this, name, capacity)` |
| SUBROUTINE | `nodeset_add_node` | 92 | `SUBROUTINE nodeset_add_node(this, node_id)` |
| SUBROUTINE | `nodeset_add_range` | 112 | `SUBROUTINE nodeset_add_range(this, first, last, incr)` |
| FUNCTION | `nodeset_contains` | 133 | `FUNCTION nodeset_contains(this, node_id) RESULT(found)` |
| SUBROUTINE | `elemset_init` | 155 | `SUBROUTINE elemset_init(this, name, capacity)` |
| SUBROUTINE | `elemset_add_elem` | 174 | `SUBROUTINE elemset_add_elem(this, elem_id)` |
| SUBROUTINE | `elemset_add_range` | 194 | `SUBROUTINE elemset_add_range(this, first, last, incr)` |
| FUNCTION | `elemset_contains` | 215 | `FUNCTION elemset_contains(this, elem_id) RESULT(found)` |
| SUBROUTINE | `surface_init` | 238 | `SUBROUTINE surface_init(this, name, surf_type, capacity)` |
| SUBROUTINE | `surface_add_facet` | 258 | `SUBROUTINE surface_add_facet(this, elem_id, face_id)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
