# `MD_KeyWord_Validator.f90`

- **Source**: `L3_MD/KeyWord/MD_KeyWord_Validator.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_KeyWord_Validator`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KeyWord_Validator`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KeyWord_Validator`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KeyWord_Validator.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ParameterSpec_Type` (lines 39–43)

```fortran
  TYPE :: ParameterSpec_Type
    CHARACTER(len=32)  :: param_name    ! Parameter name
    LOGICAL            :: is_required   ! Whether required
    CHARACTER(len=256) :: valid_values  ! Valid values (comma-separated, empty=any)
  END TYPE ParameterSpec_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Is_Valid_Keyword` | 75 | `SUBROUTINE MD_Is_Valid_Keyword(keyword, is_valid, status)` |
| SUBROUTINE | `MD_Validate_Required_Params` | 111 | `SUBROUTINE MD_Validate_Required_Params(keyword, param_count, status)` |
| SUBROUTINE | `MD_Validate_Parameter_Values` | 164 | `SUBROUTINE MD_Validate_Parameter_Values(keyword, param_name, param_value, status)` |
| SUBROUTINE | `UPPERCASE_STRING` | 202 | `SUBROUTINE UPPERCASE_STRING(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
