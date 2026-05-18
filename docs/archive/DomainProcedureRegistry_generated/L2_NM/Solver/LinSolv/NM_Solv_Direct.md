# `NM_Solv_Direct.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_Direct.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_Direct`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Direct`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Direct`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_Direct.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_LUFactor_Size` (lines 31–34)

```fortran
      TYPE, PUBLIC :: UF_LUFactor_Size
        INTEGER(i4) :: n = 0
        INTEGER(i4) :: nnz = 0
  END TYPE UF_LUFactor_Size
```

### `UF_LUFactor_Values` (lines 36–39)

```fortran
  TYPE, PUBLIC :: UF_LUFactor_Values
        REAL(wp), ALLOCATABLE :: alu(:)      ! L and U values
        INTEGER, ALLOCATABLE :: jlu(:)       ! Column indices
  END TYPE UF_LUFactor_Values
```

### `UF_LUFactor_Ptr` (lines 41–44)

```fortran
  TYPE, PUBLIC :: UF_LUFactor_Ptr
        INTEGER, ALLOCATABLE :: ju(:)        ! Diagonal pointers
        INTEGER, ALLOCATABLE :: iperm(:)     ! Permutation array
  END TYPE UF_LUFactor_Ptr
```

### `UF_LUFactor_Flags` (lines 46–48)

```fortran
  TYPE, PUBLIC :: UF_LUFactor_Flags
        LOGICAL :: factored = .FALSE.
  END TYPE UF_LUFactor_Flags
```

### `UF_LUFactor` (lines 50–57)

```fortran
  TYPE, PUBLIC :: UF_LUFactor
        TYPE(UF_LUFactor_Size)   :: size
        TYPE(UF_LUFactor_Values) :: values
        TYPE(UF_LUFactor_Ptr)    :: ptr
        TYPE(UF_LUFactor_Flags)  :: flags
    CONTAINS
        PROCEDURE :: destroy => lu_destroy
    END TYPE UF_LUFactor
```

### `UF_Skyline_Size` (lines 62–64)

```fortran
      TYPE, PUBLIC :: UF_Skyline_Size
        INTEGER(i4) :: n = 0
  END TYPE UF_Skyline_Size
```

### `UF_Skyline_Values` (lines 66–69)

```fortran
  TYPE, PUBLIC :: UF_Skyline_Values
        REAL(wp), ALLOCATABLE :: diag(:)     ! Diagonal entries
        REAL(wp), ALLOCATABLE :: sky(:)      ! Off-diagonal entries (column-wise)
  END TYPE UF_Skyline_Values
```

### `UF_Skyline_Ptr` (lines 71–73)

```fortran
  TYPE, PUBLIC :: UF_Skyline_Ptr
        INTEGER, ALLOCATABLE :: idiag(:)     ! Pointers to diagonal in sky
  END TYPE UF_Skyline_Ptr
```

### `UF_Skyline_Flags` (lines 75–77)

```fortran
  TYPE, PUBLIC :: UF_Skyline_Flags
        LOGICAL :: factored = .FALSE.
  END TYPE UF_Skyline_Flags
```

### `UF_Skyline` (lines 79–87)

```fortran
  TYPE, PUBLIC :: UF_Skyline
        TYPE(UF_Skyline_Size)   :: size
        TYPE(UF_Skyline_Values) :: values
        TYPE(UF_Skyline_Ptr)    :: ptr
        TYPE(UF_Skyline_Flags)  :: flags
    CONTAINS
        PROCEDURE :: init => skyline_init
        PROCEDURE :: destroy => skyline_destroy
    END TYPE UF_Skyline
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `direct_solve_dense` | 97 | `SUBROUTINE direct_solve_dense(A, b, x, n, ierr)` |
| SUBROUTINE | `direct_lu_factor` | 171 | `SUBROUTINE direct_lu_factor(A, LU, ierr)` |
| SUBROUTINE | `direct_lu_solve` | 273 | `SUBROUTINE direct_lu_solve(LU, b, x, ierr)` |
| SUBROUTINE | `lu_destroy` | 331 | `SUBROUTINE lu_destroy(this)` |
| SUBROUTINE | `skyline_init` | 346 | `SUBROUTINE skyline_init(this, n, profile)` |
| SUBROUTINE | `skyline_factor` | 371 | `SUBROUTINE skyline_factor(sky, ierr)` |
| SUBROUTINE | `skyline_solve` | 423 | `SUBROUTINE skyline_solve(sky, b, x, ierr)` |
| SUBROUTINE | `skyline_destroy` | 469 | `SUBROUTINE skyline_destroy(this)` |
| SUBROUTINE | `band_lu_factor` | 482 | `SUBROUTINE band_lu_factor(A, n, kl, ku, AB, ipiv, ierr)` |
| SUBROUTINE | `band_lu_solve` | 545 | `SUBROUTINE band_lu_solve(AB, n, kl, ku, ipiv, b, x, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
