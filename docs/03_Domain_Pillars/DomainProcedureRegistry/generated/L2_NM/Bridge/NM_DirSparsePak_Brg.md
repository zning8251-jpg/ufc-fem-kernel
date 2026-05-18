# `NM_DirSparsePak_Brg.f90`

- **Source**: `L2_NM/Bridge/NM_DirSparsePak_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_DirSparsePak_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_DirSparsePak_Brg`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_DirSparsePak`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Bridge/NM_DirSparsePak_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_SparsePak_Handle` (lines 39–41)

```fortran
  TYPE, PUBLIC :: NM_SparsePak_Handle
    TYPE(UF_SparsePakHandle) :: uf_handle
  END TYPE NM_SparsePak_Handle
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_SparsePak_Solv` | 48 | `SUBROUTINE NM_SparsePak_Solv(A, b, x, ierr, reorder_type)` |
| SUBROUTINE | `NM_SparsePak_Symbolic` | 65 | `SUBROUTINE NM_SparsePak_Symbolic(A, handle, reorder_type, ierr)` |
| SUBROUTINE | `NM_SparsePak_Numeric` | 77 | `SUBROUTINE NM_SparsePak_Numeric(A, handle, ierr)` |
| SUBROUTINE | `NM_SparsePak_Solv_Factored` | 88 | `SUBROUTINE NM_SparsePak_Solv_Factored(handle, b, x, ierr)` |
| SUBROUTINE | `NM_SparsePak_Cleanup` | 100 | `SUBROUTINE NM_SparsePak_Cleanup(handle)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
