# `MD_Elem_Domain.f90`

- **Source**: `L3_MD/Element/Elem/MD_Elem_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Elem_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Elem_Domain`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Elem_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Elem`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Elem/MD_Elem_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Elem_Domain_Algo` (lines 25–35)

```fortran
  TYPE, PUBLIC :: MD_Elem_Domain_Algo
    !--- Four-class TYPE nested structure ---
    TYPE(MD_Elem_Desc)  :: desc           ! [1] Cold path — registry data
    TYPE(MD_Elem_State) :: state          ! [2] Hot path  — model aggregations
    TYPE(MD_Elem_Algo)   :: algo           ! [3] Step cfg  — algorithm params
    TYPE(MD_Elem_Ctx)   :: ctx            ! [4] Hot path  — model metadata
    !--- Domain metadata ---
    INTEGER(i4) :: domain_id      = 0_i4      ! Domain identifier
    INTEGER(i4) :: n_elements     = 0_i4      ! Element count in domain
    LOGICAL     :: is_initialized = .FALSE.    ! Initialization flag
  END TYPE MD_Elem_Domain_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Elem_Domain_Init` | 53 | `SUBROUTINE MD_Elem_Domain_Init(domain, elem_type_id, family_id, status)` |
| SUBROUTINE | `MD_Elem_Domain_Register` | 85 | `SUBROUTINE MD_Elem_Domain_Register(domain, registry_entry, status)` |
| FUNCTION | `MD_Elem_Domain_GetDesc` | 120 | `FUNCTION MD_Elem_Domain_GetDesc(domain) RESULT(desc_out)` |
| SUBROUTINE | `MD_Elem_Domain_Finalize` | 132 | `SUBROUTINE MD_Elem_Domain_Finalize(domain, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
