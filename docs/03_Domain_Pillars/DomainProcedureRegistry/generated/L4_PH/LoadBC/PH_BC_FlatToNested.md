# `PH_BC_FlatToNested.f90`

- **Source**: `L4_PH/LoadBC/PH_BC_FlatToNested.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_BC_FlatToNested`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_BC_FlatToNested`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_BC_FlatToNested`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_BC_FlatToNested.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_WriteBack_Mask_Type` (lines 15–20)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_Mask_Type
    LOGICAL, ALLOCATABLE :: bc_mutable(:)
    LOGICAL :: allow_magnitude_change = .TRUE.
    LOGICAL :: allow_isFixed_change = .TRUE.
    LOGICAL :: allow_type_change = .FALSE.
  END TYPE
```

### `PH_WriteBack_Status_Type` (lines 22–27)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_Status_Type
    INTEGER(i4) :: n_modified = 0_i4
    INTEGER(i4) :: n_released = 0_i4
    LOGICAL :: writeback_success = .TRUE.
    CHARACTER(len=slen) :: last_operation = ""
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_BC_Create_WriteBack_Mask` | 36 | `SUBROUTINE PH_BC_Create_WriteBack_Mask(n_bcs, mask)` |
| SUBROUTINE | `PH_BC_WriteBack_From_Cache` | 48 | `SUBROUTINE PH_BC_WriteBack_From_Cache(mask, status)` |
| SUBROUTINE | `PH_BC_Release_Failed` | 58 | `SUBROUTINE PH_BC_Release_Failed(bc_index, mask, status)` |
| FUNCTION | `PH_BC_Validate_WriteBack` | 67 | `FUNCTION PH_BC_Validate_WriteBack(mask, n_bcs, status) RESULT(is_valid)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
