# `MD_Load_Def.f90`

- **Source**: `L3_MD/LoadBC/MD_Load_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Load_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Load_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Load`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/LoadBC/MD_Load_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Load_Desc` (lines 35–53)

```fortran
  TYPE, PUBLIC :: MD_Load_Desc
    INTEGER(i4)       :: load_id        = 0_i4
    INTEGER(i4)       :: load_family    = 0_i4
    CHARACTER(LEN=64) :: load_name      = ""
    LOGICAL           :: is_initialized = .FALSE.
    REAL(wp)          :: magnitude      = 0.0_wp
    REAL(wp)          :: scale_factor   = 1.0_wp
    INTEGER(i4)       :: time_dependence = 0_i4
    INTEGER(i4)       :: amplitude_id   = 0_i4
    INTEGER(i4)       :: load_type      = 0_i4
    INTEGER(i4)       :: element_face   = 0_i4
    INTEGER(i4)       :: node_id        = 0_i4
    INTEGER(i4)       :: dof_number     = 0_i4
    REAL(wp)          :: ambient_temp   = 0.0_wp
    REAL(wp)          :: film_coeff     = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => Load_Desc_Init
    PROCEDURE :: Reset  => Load_Desc_Reset
  END TYPE MD_Load_Desc
```

### `MD_Load_State` (lines 55–62)

```fortran
  TYPE, PUBLIC :: MD_Load_State
    REAL(wp) :: accumulated     = 0.0_wp
    REAL(wp) :: last_magnitude  = 0.0_wp
    REAL(wp) :: work_done       = 0.0_wp
    LOGICAL  :: converged    = .FALSE.
    INTEGER(i4) :: iterations   = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Load_State
```

### `MD_Load_Domain` (lines 64–73)

```fortran
  TYPE, PUBLIC :: MD_Load_Domain
    TYPE(MD_Load_Desc), ALLOCATABLE :: loads(:)
    INTEGER(i4)                     :: n_loads = 0_i4
    LOGICAL                         :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => Load_Domain_Init
    PROCEDURE :: Finalize => Load_Domain_Finalize
    PROCEDURE :: AddLoad  => Load_Domain_AddLoad
    PROCEDURE :: GetLoad  => Load_Domain_GetLoad
  END TYPE MD_Load_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Load_Desc_Init` | 77 | `SUBROUTINE Load_Desc_Init(this)` |
| SUBROUTINE | `Load_Desc_Reset` | 95 | `SUBROUTINE Load_Desc_Reset(this)` |
| SUBROUTINE | `Load_Domain_Init` | 100 | `SUBROUTINE Load_Domain_Init(this, status)` |
| SUBROUTINE | `Load_Domain_Finalize` | 109 | `SUBROUTINE Load_Domain_Finalize(this, status)` |
| SUBROUTINE | `Load_Domain_AddLoad` | 119 | `SUBROUTINE Load_Domain_AddLoad(this, load, status)` |
| SUBROUTINE | `Load_Domain_GetLoad` | 139 | `SUBROUTINE Load_Domain_GetLoad(this, idx, load, found)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
