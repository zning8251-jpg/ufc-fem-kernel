# `MD_Elem_Validate.f90`

- **Source**: `L3_MD/Element/Elem/MD_Elem_Validate.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Elem_Validate`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Elem_Validate`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Elem_Validate`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Elem`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Elem/MD_Elem_Validate.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Elem_Validate_State` (lines 26–38)

```fortran
  TYPE, PUBLIC :: MD_Elem_Validate_State
    LOGICAL     :: is_valid      = .FALSE.    ! Overall validity
    INTEGER(i4) :: n_errors      = 0_i4       ! Error count
    INTEGER(i4) :: n_warnings    = 0_i4       ! Warning count
    !--- Detailed checks ---
    LOGICAL     :: desc_valid    = .FALSE.    ! Descriptor valid
    LOGICAL     :: conn_valid    = .FALSE.    ! Connectivity valid
    LOGICAL     :: mat_ref_valid = .FALSE.    ! Material reference valid
    LOGICAL     :: sect_ref_valid = .FALSE.   ! Section reference valid
    LOGICAL     :: mesh_ref_valid = .FALSE.   ! Mesh reference valid
    !--- Error messages ---
    CHARACTER(LEN=256) :: error_msg = ""      ! First error message
  END TYPE MD_Elem_Validate_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MD_Elem_Validate_Domain` | 56 | `FUNCTION MD_Elem_Validate_Domain(domain, result, status) RESULT(is_valid)` |
| FUNCTION | `MD_Elem_Validate_Conn` | 110 | `FUNCTION MD_Elem_Validate_Conn(domain, node_ids, status) RESULT(is_valid)` |
| FUNCTION | `MD_Elem_Validate_MatRef` | 138 | `FUNCTION MD_Elem_Validate_MatRef(domain, status) RESULT(is_valid)` |
| FUNCTION | `MD_Elem_Validate_SectRef` | 159 | `FUNCTION MD_Elem_Validate_SectRef(domain, status) RESULT(is_valid)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
