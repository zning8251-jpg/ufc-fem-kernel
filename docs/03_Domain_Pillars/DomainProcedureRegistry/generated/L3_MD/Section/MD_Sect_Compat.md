# `MD_Sect_Compat.f90`

- **Source**: `L3_MD/Section/MD_Sect_Compat.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Sect_Compat`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_Compat`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect_Compat`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_Compat.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ModelOverrideEntry` (lines 133–137)

```fortran
  TYPE :: ModelOverrideEntry
    INTEGER(i4) :: mat_type          ! specific material model ID (e.g. 212)
    INTEGER(i4) :: n_allowed_elem    ! number of allowed element families
    INTEGER(i4) :: allowed_elem(6)   ! up to 6 allowed element families
  END TYPE ModelOverrideEntry
```

### `ModelOverrideRegistry` (lines 139–142)

```fortran
  TYPE :: ModelOverrideRegistry
    INTEGER(i4) :: n_entries = 0_i4
    TYPE(ModelOverrideEntry) :: entries(MAX_MODEL_OVERRIDES)
  END TYPE ModelOverrideRegistry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MatTypeToFamily` | 163 | `PURE FUNCTION MatTypeToFamily(mat_type) RESULT(fam)` |
| SUBROUTINE | `MD_SectCompat_Init` | 198 | `SUBROUTINE MD_SectCompat_Init()` |
| FUNCTION | `MD_SectCompat_Check_SectMat` | 224 | `PURE FUNCTION MD_SectCompat_Check_SectMat(sect_fam, mat_fam) RESULT(ok)` |
| FUNCTION | `MD_SectCompat_Check_SectElem` | 238 | `PURE FUNCTION MD_SectCompat_Check_SectElem(sect_fam, elem_fam) RESULT(ok)` |
| SUBROUTINE | `MD_SectCompat_Check_Triple` | 257 | `SUBROUTINE MD_SectCompat_Check_Triple(sect_fam, mat_fam, elem_fam, &` |
| FUNCTION | `SectCompat_Get_StressState` | 306 | `PURE FUNCTION SectCompat_Get_StressState(sect_fam, elem_fam) RESULT(ss)` |
| SUBROUTINE | `SectCompat_Register_Model_Override` | 350 | `SUBROUTINE SectCompat_Register_Model_Override(mat_type, allowed_elem, n_elem)` |
| FUNCTION | `SectCompat_Check_Model_Override` | 371 | `FUNCTION SectCompat_Check_Model_Override(mat_type, elem_fam) RESULT(ok)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
