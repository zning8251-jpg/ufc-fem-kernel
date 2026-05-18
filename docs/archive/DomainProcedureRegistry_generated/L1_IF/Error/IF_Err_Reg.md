# `IF_Err_Reg.f90`

- **Source**: `L1_IF/Error/IF_Err_Reg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Err_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Err_Reg`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Err`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `Error`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Error/IF_Err_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ErrorCodeEntry` (lines 84–90)

```fortran
  TYPE :: ErrorCodeEntry
    INTEGER(i4) :: code
    CHARACTER(LEN=64) :: name
    CHARACTER(LEN=256) :: description
    CHARACTER(LEN=8) :: layer
    LOGICAL :: is_registered
  END TYPE ErrorCodeEntry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init_ErrorCode_Registry` | 158 | `SUBROUTINE Init_ErrorCode_Registry(status)` |
| SUBROUTINE | `UFC_Register_Error_Code` | 186 | `SUBROUTINE UFC_Register_Error_Code(code, name, description, layer, status)` |
| FUNCTION | `UFC_Get_Error_Name` | 241 | `FUNCTION UFC_Get_Error_Name(code) RESULT(name)` |
| FUNCTION | `UFC_Is_Error_Code_Valid` | 279 | `FUNCTION UFC_Is_Error_Code_Valid(code, layer) RESULT(is_valid)` |
| SUBROUTINE | `Finalize_ErrorCode_Registry` | 309 | `SUBROUTINE Finalize_ErrorCode_Registry()` |
| SUBROUTINE | `Register_Predefined_Errors` | 321 | `SUBROUTINE Register_Predefined_Errors(status)` |
| FUNCTION | `ITOA` | 394 | `FUNCTION ITOA(i) RESULT(str)` |
| FUNCTION | `TO_UPPER` | 403 | `FUNCTION TO_UPPER(str) RESULT(upper_str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
