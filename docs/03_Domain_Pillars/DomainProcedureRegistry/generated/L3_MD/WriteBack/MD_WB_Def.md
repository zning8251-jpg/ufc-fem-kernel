# `MD_WB_Def.f90`

- **Source**: `L3_MD/WriteBack/MD_WB_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_WB_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_WB_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_WB`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/WriteBack/MD_WB_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_WriteBack_Entry` (lines 68–75)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_Entry
    CHARACTER(LEN=128) :: field_path   = ""
    CHARACTER(LEN=32)  :: domain_name  = ""
    CHARACTER(LEN=64)  :: field_name   = ""
    INTEGER(i4)        :: domain_id    = 0_i4
    LOGICAL            :: is_active    = .FALSE.
    LOGICAL            :: requires_lock = .FALSE.
  END TYPE MD_WriteBack_Entry
```

### `MD_WriteBack_Target` (lines 80–84)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_Target
    INTEGER(i4) :: domain_id   = 0_i4
    INTEGER(i4) :: entity_idx  = 0_i4
    INTEGER(i4) :: field_slot  = 0_i4   ! slot in flat domain
  END TYPE MD_WriteBack_Target
```

### `MD_WBMapEntry` (lines 89–94)

```fortran
  TYPE, PUBLIC :: MD_WBMapEntry
    INTEGER(i4) :: source_field_id = 0_i4
    INTEGER(i4) :: target_field_id = 0_i4
    INTEGER(i4) :: map_type        = 0_i4
    LOGICAL     :: valid           = .FALSE.
  END TYPE MD_WBMapEntry
```

### `MD_WriteBack_Desc` (lines 99–102)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_Desc
    INTEGER(i4)        :: n_maps = 0_i4
    TYPE(MD_WBMapEntry) :: maps(MD_WB_MAX_MAPS)
  END TYPE MD_WriteBack_Desc
```

### `MD_WriteBack_State` (lines 107–112)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_State
    LOGICAL     :: active       = .FALSE.
    INTEGER(i4) :: n_completed  = 0_i4
    INTEGER(i4) :: n_failed     = 0_i4
    INTEGER(i4) :: current_step = 0_i4
  END TYPE MD_WriteBack_State
```

### `MD_WriteBack_Ctx` (lines 117–121)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_Ctx
    INTEGER(i4) :: step_idx    = 0_i4
    INTEGER(i4) :: incr_idx    = 0_i4
    LOGICAL     :: in_progress = .FALSE.
  END TYPE MD_WriteBack_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
