# `MD_Part_Def.f90`

- **Source**: `L3_MD/Part/MD_Part_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Part_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Part_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Part`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Part`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Part/MD_Part_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_PartCfg` (lines 27–30)

```fortran
  TYPE, PUBLIC :: UF_PartCfg
    INTEGER(i4) :: id   = 0_i4
    INTEGER(i4) :: ndim = 3_i4
  END TYPE UF_PartCfg
```

### `UF_PartDef` (lines 32–37)

```fortran
  TYPE, PUBLIC :: UF_PartDef
    CHARACTER(LEN=MD_PART_NAME_LEN) :: name = ""
    TYPE(UF_PartCfg)               :: cfg
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nElems = 0_i4
  END TYPE UF_PartDef
```

### `MD_Part_Entry_Desc` (lines 44–49)

```fortran
  TYPE, PUBLIC :: MD_Part_Entry_Desc
    INTEGER(i4)                     :: id         = 0        ! [in] part ID
    CHARACTER(LEN=MD_PART_NAME_LEN) :: name       = ""       ! [in] part name
    INTEGER(i4)                     :: section_id = 0        ! [in] bound section ID
    LOGICAL                         :: valid      = .FALSE.  ! [in] entry validity
  END TYPE MD_Part_Entry_Desc
```

### `MD_Part_Desc` (lines 57–60)

```fortran
  TYPE, PUBLIC :: MD_Part_Desc
    TYPE(MD_Part_Entry_Desc) :: parts(MD_PART_MAX)           ! [in] part entries
    INTEGER(i4)              :: n_parts = 0                  ! [in] count of entries
  END TYPE MD_Part_Desc
```

### `MD_Part_State` (lines 68–73)

```fortran
  TYPE, PUBLIC :: MD_Part_State
    LOGICAL     :: sections_assigned = .FALSE.               ! [inout] all parts have sections
    LOGICAL     :: materials_bound   = .FALSE.               ! [inout] all sections have materials
    LOGICAL     :: validated         = .FALSE.               ! [inout] domain passed validation
    INTEGER(i4) :: n_unassigned      = 0                     ! [out]   count of unassigned parts
  END TYPE MD_Part_State
```

### `MD_Part_Domain` (lines 81–90)

```fortran
  TYPE, PUBLIC :: MD_Part_Domain
    TYPE(MD_Part_Desc)  :: desc                              ! [inout] part definitions
    TYPE(MD_Part_State) :: state                             ! [inout] runtime state
    INTEGER(i4)         :: n_parts     = 0                   ! [inout] active part count
    LOGICAL             :: initialized = .FALSE.             ! [inout] lifecycle flag
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetSummary
  END TYPE MD_Part_Domain
```

### `MD_Part_Get_Arg` (lines 98–100)

```fortran
  TYPE, PUBLIC :: MD_Part_Get_Arg
    TYPE(MD_Part_Entry_Desc) :: desc                         ! [out] retrieved part entry
  END TYPE MD_Part_Get_Arg
```

### `MD_Part_GetByName_Arg` (lines 108–112)

```fortran
  TYPE, PUBLIC :: MD_Part_GetByName_Arg
    TYPE(MD_Part_Entry_Desc) :: desc                         ! [out] retrieved part entry
    INTEGER(i4)              :: part_idx = 0                 ! [out] matched index
    LOGICAL                  :: found    = .FALSE.           ! [out] whether name was found
  END TYPE MD_Part_GetByName_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 121 | `SUBROUTINE Init(this, capacity, status)` |
| SUBROUTINE | `Finalize` | 153 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `GetSummary` | 168 | `SUBROUTINE GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
