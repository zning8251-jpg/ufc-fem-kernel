# `MD_Elem_UEL_Def.f90`

- **Source**: `L3_MD/Element/Elem/MD_Elem_UEL_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Elem_UEL_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Elem_UEL_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Elem_UEL`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Elem`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Elem/MD_Elem_UEL_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Elem_UEL_Desc` (lines 32–50)

```fortran
  TYPE, PUBLIC :: MD_Elem_UEL_Desc
    INTEGER(i4) :: ndofel = 0
    INTEGER(i4) :: nsvars  = 0
    INTEGER(i4) :: nnode   = 0
    INTEGER(i4) :: mcrd    = 3
    INTEGER(i4) :: jtype   = 0
    INTEGER(i4) :: nprops = 0
    REAL(wp), ALLOCATABLE    :: props(:)
    INTEGER(i4) :: npredf  = 0
    INTEGER(i4) :: mdload = 0
    INTEGER(i4), ALLOCATABLE :: jdltyp(:,:)
    INTEGER(i4) :: njprop = 0
    INTEGER(i4), ALLOCATABLE :: jprops(:)
    INTEGER(i4) :: integ_npts = 0_i4
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => UEL_Elem_Desc_Init
    PROCEDURE :: Reset  => UEL_Elem_Desc_Reset
  END TYPE MD_Elem_UEL_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UEL_Elem_Desc_Init` | 54 | `SUBROUTINE UEL_Elem_Desc_Init(self, nprops_in, njprop_in, npredf_in, mdload_in, ncols_jdl)` |
| SUBROUTINE | `UEL_Elem_Desc_Reset` | 85 | `SUBROUTINE UEL_Elem_Desc_Reset(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
