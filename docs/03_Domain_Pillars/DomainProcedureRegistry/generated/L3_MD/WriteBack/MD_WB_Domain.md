# `MD_WB_Domain.f90`

- **Source**: `L3_MD/WriteBack/MD_WB_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_WB_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_WB_Domain`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_WB_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/WriteBack/MD_WB_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_WriteBack_AddEntry_Arg` (lines 38–45)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_AddEntry_Arg
    CHARACTER(LEN=64) :: domain_name  = ""      ! (IN)
    CHARACTER(LEN=64) :: field_name   = ""      ! (IN)
    INTEGER(i4)       :: domain_id    = 0_i4    ! (IN)
    LOGICAL           :: is_active    = .TRUE.  ! (IN)
    LOGICAL           :: requires_lock = .FALSE. ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_WriteBack_AddEntry_Arg
```

### `MD_WriteBack_GetSummary_Arg` (lines 47–50)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_WriteBack_GetSummary_Arg
```

### `MD_WriteBack_WhiteListDomain` (lines 55–66)

```fortran
  TYPE, PUBLIC :: MD_WriteBack_WhiteListDomain
    TYPE(MD_WriteBack_Entry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: n_entries = 0_i4
    INTEGER(i4) :: capacity  = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_WriteBack_Domain_Init
    PROCEDURE :: Finalize => MD_WriteBack_Domain_Finalize
    PROCEDURE :: AddEntry => MD_WriteBack_Domain_AddEntry
    PROCEDURE :: IsAllowed => MD_WriteBack_Domain_IsAllowed
    PROCEDURE :: GetSummary => MD_WriteBack_Domain_GetSummary
  END TYPE MD_WriteBack_WhiteListDomain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_WriteBack_Domain_Init` | 70 | `SUBROUTINE MD_WriteBack_Domain_Init(this, initial_capacity, status)` |
| SUBROUTINE | `MD_WriteBack_Domain_Finalize` | 84 | `SUBROUTINE MD_WriteBack_Domain_Finalize(this)` |
| SUBROUTINE | `MD_WriteBack_Domain_AddEntry` | 93 | `SUBROUTINE MD_WriteBack_Domain_AddEntry(this, domain_name, field_name, &` |
| FUNCTION | `MD_WriteBack_Domain_IsAllowed` | 137 | `FUNCTION MD_WriteBack_Domain_IsAllowed(this, domain_name, field_name) RESULT(is_allowed)` |
| SUBROUTINE | `MD_WriteBack_Domain_GetSummary` | 161 | `SUBROUTINE MD_WriteBack_Domain_GetSummary(this, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
