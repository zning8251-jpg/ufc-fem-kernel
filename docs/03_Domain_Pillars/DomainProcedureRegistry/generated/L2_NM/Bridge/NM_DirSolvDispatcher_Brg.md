# `NM_DirSolvDispatcher_Brg.f90`

- **Source**: `L2_NM/Bridge/NM_DirSolvDispatcher_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_DirSolvDispatcher_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_DirSolvDispatcher_Brg`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_DirSolvDispatcher`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Bridge/NM_DirSolvDispatcher_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_Direct_Solv_SparsePak_Arg` (lines 37–47)

```fortran
  TYPE :: NM_Direct_Solv_SparsePak_Arg
    INTEGER(i4) :: nrows = 0_i4             ! [IN]  Number of rows
    INTEGER(i4) :: ncols = 0_i4             ! [IN]  Number of columns
    INTEGER(i4) :: nnz   = 0_i4             ! [IN]  Number of non-zeros
    INTEGER(i4), POINTER :: row_ptr(:) => NULL()  ! [IN]  CSR row pointer (nrows+1)
    INTEGER(i4), POINTER :: col_ind(:) => NULL()  ! [IN]  CSR column index (nnz)
    REAL(wp), POINTER    :: values(:)  => NULL()  ! [IN]  CSR values (nnz)
    REAL(wp), POINTER    :: b(:)       => NULL()  ! [IN]  Right-hand side vector
    REAL(wp), POINTER    :: x(:)       => NULL()  ! [OUT] Solution vector
    INTEGER(i4)          :: reorder_type = -1_i4  ! [IN]  Reorder type (-1=default RCM)
  END TYPE NM_Direct_Solv_SparsePak_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Direct_Solv_SparsePak` | 57 | `SUBROUTINE NM_Direct_Solv_SparsePak(arg, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
