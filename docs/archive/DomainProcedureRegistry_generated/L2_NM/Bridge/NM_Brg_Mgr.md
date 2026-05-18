# `NM_Brg_Mgr.f90`

- **Source**: `L2_NM/Bridge/NM_Brg_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Brg_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Brg_Mgr`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Brg`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Bridge/NM_Brg_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_Brg_ExtLibFlags_Desc` (lines 36–42)

```fortran
  TYPE, PUBLIC :: NM_Brg_ExtLibFlags_Desc
    LOGICAL :: hasMUMPS    = .FALSE.
    LOGICAL :: hasLAPACK   = .TRUE.    ! Typically always available
    LOGICAL :: hasCuSPARSE = .FALSE.
    LOGICAL :: hasAGMG     = .FALSE.
    LOGICAL :: hasSparsePak = .TRUE.
  END TYPE NM_Brg_ExtLibFlags_Desc
```

### `NM_ExtLibFlags` (lines 44–50)

```fortran
  TYPE, PUBLIC :: NM_ExtLibFlags
    LOGICAL :: hasMUMPS    = .FALSE.
    LOGICAL :: hasLAPACK   = .TRUE.
    LOGICAL :: hasCuSPARSE = .FALSE.
    LOGICAL :: hasAGMG     = .FALSE.
    LOGICAL :: hasSparsePak = .TRUE.
  END TYPE NM_ExtLibFlags
```

### `NM_Bridge_Domain` (lines 55–64)

```fortran
  TYPE, PUBLIC :: NM_Bridge_Domain
    TYPE(NM_Brg_ExtLibFlags_Desc) :: extLibs
    LOGICAL              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init              => NM_Brg_Init
    PROCEDURE :: Finalize          => NM_Brg_Finalize
    PROCEDURE :: CheckLibrary      => NM_Bridge_Domain_CheckLibrary
    PROCEDURE :: GetLibraryStatus  => NM_Brg_GetLibStatus
    PROCEDURE :: GetSummary        => NM_Brg_GetSummary
  END TYPE NM_Bridge_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Brg_Finalize` | 68 | `SUBROUTINE NM_Brg_Finalize(this)` |
| SUBROUTINE | `NM_Brg_Init` | 76 | `SUBROUTINE NM_Brg_Init(this, status)` |
| SUBROUTINE | `NM_Bridge_Domain_CheckLibrary` | 92 | `SUBROUTINE NM_Bridge_Domain_CheckLibrary(this, libName, isAvailable, status)` |
| SUBROUTINE | `NM_Brg_GetLibStatus` | 136 | `SUBROUTINE NM_Brg_GetLibStatus(this, libName, status)` |
| SUBROUTINE | `NM_Brg_GetSummary` | 168 | `SUBROUTINE NM_Brg_GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
