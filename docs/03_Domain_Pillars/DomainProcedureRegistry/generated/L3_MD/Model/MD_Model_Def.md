# `MD_Model_Def.f90`

- **Source**: `L3_MD/Model/MD_Model_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Model_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Model_Cfg_Init_Desc` (lines 39–43)

```fortran
  TYPE, PUBLIC :: MD_Model_Cfg_Init_Desc
    INTEGER(i4) :: analysis_type = MD_MODEL_ANALYSIS_STATIC   ! analysis type code
    INTEGER(i4) :: sub_type      = 0                           ! model sub-type
    INTEGER(i4) :: property_flags = 0                          ! property control flags
  END TYPE MD_Model_Cfg_Init_Desc
```

### `MD_Model_Pop_Vld_Desc` (lines 50–52)

```fortran
  TYPE, PUBLIC :: MD_Model_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.  ! .TRUE. after successful population
  END TYPE MD_Model_Pop_Vld_Desc
```

### `MD_Model_Desc` (lines 65–91)

```fortran
  TYPE, PUBLIC :: MD_Model_Desc
    !-- Nested auxiliary descriptors
    TYPE(MD_Model_Cfg_Init_Desc) :: cfg
    TYPE(MD_Model_Pop_Vld_Desc) :: pop

    !-- Model identity
    CHARACTER(LEN=256) :: model_name  = ""       ! model name identifier
    INTEGER(i4)        :: spatial_dim = 3         ! spatial dimension {2,3}

    !-- Sub-domain counts
    INTEGER(i4) :: n_parts        = 0             ! registered part count
    INTEGER(i4) :: n_steps        = 0             ! registered step count
    INTEGER(i4) :: n_materials    = 0             ! material count
    INTEGER(i4) :: n_sections     = 0             ! section count
    INTEGER(i4) :: n_loadbcs      = 0             ! load/BC count
    INTEGER(i4) :: n_amplitudes   = 0             ! amplitude count
    INTEGER(i4) :: n_interactions = 0             ! interaction count
    INTEGER(i4) :: n_outputs      = 0             ! output count

    !-- ID registries (fixed-length, for simple P0 tracking)
    INTEGER(i4) :: part_ids(256) = 0              ! part ID registry
    INTEGER(i4) :: step_ids(100) = 0              ! step ID registry
  CONTAINS
    PROCEDURE, PASS :: Init  => MD_Model_Desc_Init
    PROCEDURE, PASS :: Valid => MD_Model_Desc_Valid
    PROCEDURE, PASS :: Clean => MD_Model_Desc_Clean
  END TYPE MD_Model_Desc
```

### `MD_Model_Ctx` (lines 99–105)

```fortran
  TYPE, PUBLIC :: MD_Model_Ctx
    INTEGER(i4)        :: parse_unit   = 0          ! active file unit during parse
    INTEGER(i4)        :: current_line = 0          ! current input line number
    CHARACTER(LEN=256) :: source_file  = ""         ! source input file path
    LOGICAL            :: echo_input   = .FALSE.    ! echo parsed input flag
    LOGICAL            :: strict_mode  = .TRUE.     ! strict validation mode
  END TYPE MD_Model_Ctx
```

### `MD_Model_State` (lines 113–120)

```fortran
  TYPE, PUBLIC :: MD_Model_State
    LOGICAL     :: parsed      = .FALSE.  ! input parsing completed
    LOGICAL     :: populated   = .FALSE.  ! data population completed
    LOGICAL     :: validated   = .FALSE.  ! validation passed
    INTEGER(i4) :: n_warnings  = 0        ! accumulated warning count
    INTEGER(i4) :: n_errors    = 0        ! accumulated error count
    INTEGER(i4) :: build_phase = 0        ! current build phase index
  END TYPE MD_Model_State
```

### `MD_Model_Algo` (lines 128–133)

```fortran
  TYPE, PUBLIC :: MD_Model_Algo
    INTEGER(i4) :: renumber_strategy = 0  ! node renumbering: 0=none,1=RCM,2=Metis
    INTEGER(i4) :: partition_method  = 0  ! domain decomp: 0=none,1=greedy,2=metis
    LOGICAL     :: auto_contact      = .FALSE.  ! auto-detect contact pairs
    LOGICAL     :: adaptive_mesh     = .FALSE.  ! adaptive mesh refinement
  END TYPE MD_Model_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Model_Desc_Init` | 141 | `SUBROUTINE MD_Model_Desc_Init(this)` |
| SUBROUTINE | `MD_Model_Desc_Valid` | 161 | `SUBROUTINE MD_Model_Desc_Valid(this)` |
| SUBROUTINE | `MD_Model_Desc_Clean` | 166 | `SUBROUTINE MD_Model_Desc_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
