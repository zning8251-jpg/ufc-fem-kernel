# `NM_LinAlg_Domain.f90`

- **Source**: `L2_NM/Matrix/NM_LinAlg_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_LinAlg_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_LinAlg_Domain`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_LinAlg_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_LinAlg_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_SparseConfig` (lines 26–30)

```fortran
  TYPE, PUBLIC :: NM_SparseConfig
    INTEGER(i4) :: defaultFmt  = NM_FMT_CSR
    LOGICAL     :: enSymStore  = .FALSE.    ! Symmetric half-storage
    LOGICAL     :: enReorder   = .TRUE.     ! AMD/RCM reordering
  END TYPE NM_SparseConfig
```

### `NM_LinAlg_Domain` (lines 35–44)

```fortran
  TYPE, PUBLIC :: NM_LinAlg_Domain
    TYPE(NM_SparseConfig) :: sparseConfig
    LOGICAL               :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init        => NM_Mtx_LinAlg_Init
    PROCEDURE :: Finalize    => NM_Mtx_LinAlg_Finalize
    PROCEDURE :: SetFormat   => NM_Mtx_LinAlg_SetFormat
    PROCEDURE :: MatVec      => NM_LinAlg_Domain_MatVec
    PROCEDURE :: GetSummary  => NM_Mtx_LinAlg_GetSummary
  END TYPE NM_LinAlg_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Mtx_LinAlg_Finalize` | 48 | `SUBROUTINE NM_Mtx_LinAlg_Finalize(this)` |
| SUBROUTINE | `NM_Mtx_LinAlg_Init` | 57 | `SUBROUTINE NM_Mtx_LinAlg_Init(this, status)` |
| SUBROUTINE | `NM_Mtx_LinAlg_SetFormat` | 70 | `SUBROUTINE NM_Mtx_LinAlg_SetFormat(this, format, status)` |
| SUBROUTINE | `NM_LinAlg_Domain_MatVec` | 93 | `SUBROUTINE NM_LinAlg_Domain_MatVec(this, A, x, y, status)` |
| SUBROUTINE | `NM_Mtx_LinAlg_GetSummary` | 127 | `SUBROUTINE NM_Mtx_LinAlg_GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
