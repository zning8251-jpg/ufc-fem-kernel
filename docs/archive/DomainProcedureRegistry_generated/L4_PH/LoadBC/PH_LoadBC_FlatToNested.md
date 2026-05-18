# `PH_LoadBC_FlatToNested.f90`

- **Source**: `L4_PH/LoadBC/PH_LoadBC_FlatToNested.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_LoadBC_FlatToNested`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_LoadBC_FlatToNested`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_LoadBC_FlatToNested`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_LoadBC_FlatToNested.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_WriteBack_Mask_Type` (lines 33–38)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_Mask_Type
    LOGICAL, ALLOCATABLE :: bc_mutable(:)        ! Per-BC mutability flag
    LOGICAL :: allow_magnitude_change = .TRUE.   ! Can modify magnitude?
    LOGICAL :: allow_isFixed_change = .TRUE.     ! Can toggle isFixed?
    LOGICAL :: allow_type_change = .FALSE.       ! Can change BC type? (usually NO)
  END TYPE PH_WriteBack_Mask_Type
```

### `PH_WriteBack_Status_Type` (lines 45–50)

```fortran
  TYPE, PUBLIC :: PH_WriteBack_Status_Type
    INTEGER(i4) :: n_modified = 0_i4             ! Number of modified BCs
    INTEGER(i4) :: n_released = 0_i4             ! Number of released BCs
    LOGICAL :: writeback_success = .TRUE.        ! Overall success flag
    CHARACTER(len=slen) :: last_operation = ""   ! Last operation description
  END TYPE PH_WriteBack_Status_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_L4_Create_WriteBack_Mask` | 76 | `SUBROUTINE PH_L4_Create_WriteBack_Mask(md_ctrl, mask, release_threshold)` |
| SUBROUTINE | `PH_L4_WriteBack_BC_From_Cache` | 131 | `SUBROUTINE PH_L4_WriteBack_BC_From_Cache(md_ctrl, ph_bc_ctrl, mask, &` |
| SUBROUTINE | `PH_L4_Release_Failed_BC` | 226 | `SUBROUTINE PH_L4_Release_Failed_BC(md_ctrl, bc_index, mask, status)` |
| FUNCTION | `PH_L4_Validate_WriteBack` | 273 | `FUNCTION PH_L4_Validate_WriteBack(md_ctrl, mask, status) RESULT(is_valid)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
