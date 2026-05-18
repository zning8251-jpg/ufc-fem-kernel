# `MD_Geom_Def.f90`

- **Source**: `L3_MD/Part/MD_Geom_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Geom_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Geom_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Geom`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Part`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Part/MD_Geom_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Geom_Node_Desc` (lines 22–26)

```fortran
  TYPE, PUBLIC :: MD_Geom_Node_Desc
    INTEGER(i4) :: node_id = 0_i4                            ! [in] node ID
    INTEGER(i4) :: n_dim   = 3_i4                            ! [in] spatial dimension {2,3}
    REAL(wp)    :: coords(3) = 0.0_wp                        ! [in] node coordinates
  END TYPE MD_Geom_Node_Desc
```

### `MD_Geom_Elem_Desc` (lines 34–44)

```fortran
  TYPE, PUBLIC :: MD_Geom_Elem_Desc
    INTEGER(i4)       :: elem_id    = 0_i4                   ! [in] element ID
    CHARACTER(LEN=16) :: elem_type  = ""                     ! [in] type string (C3D8, S4R, etc.)
    CHARACTER(LEN=8)  :: family     = ""                     ! [in] family (SOLID, SHELL, BEAM)
    INTEGER(i4)       :: n_nodes    = 0_i4                   ! [in] number of nodes
    INTEGER(i4)       :: n_dof      = 0_i4                   ! [in] number of DOFs
    INTEGER(i4)       :: n_gp       = 0_i4                   ! [in] number of Gauss points
    INTEGER(i4)       :: section_id = 0_i4                   ! [in] section ID
    INTEGER(i4)       :: mat_id     = 0_i4                   ! [in] material ID
    INTEGER(i4), ALLOCATABLE :: conn(:)                      ! [in] connectivity array
  END TYPE MD_Geom_Elem_Desc
```

### `MD_Geom_Ctx` (lines 52–57)

```fortran
  TYPE, PUBLIC :: MD_Geom_Ctx
    TYPE(MD_Geom_Node_Desc), ALLOCATABLE :: node_descs(:)    ! [inout] node descriptions
    TYPE(MD_Geom_Elem_Desc), ALLOCATABLE :: elem_descs(:)    ! [inout] element descriptions
    INTEGER(i4) :: n_nodes = 0_i4                            ! [inout] node count
    INTEGER(i4) :: n_elems = 0_i4                            ! [inout] element count
  END TYPE MD_Geom_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Geom_Ctx_Init` | 68 | `SUBROUTINE MD_Geom_Ctx_Init(geom_ctx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
