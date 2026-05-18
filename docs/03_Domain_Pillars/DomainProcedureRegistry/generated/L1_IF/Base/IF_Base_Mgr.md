# `IF_Base_Mgr.f90`

- **Source**: `L1_IF/Base/IF_Base_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Base_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_SymEntry` (lines 33–37)

```fortran
  TYPE, PUBLIC :: IF_SymEntry
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4)       :: id   = 0_i4   ! registered integer id
    INTEGER(i4)       :: kind = 0_i4   ! IF_SYM_* enumeration
  END TYPE IF_SymEntry
```

### `IF_DeviceCaps` (lines 42–48)

```fortran
  TYPE, PUBLIC :: IF_DeviceCaps
    INTEGER(i4) :: nCPUCores    = 1_i4
    INTEGER(i4) :: nGPUDevices  = 0_i4
    LOGICAL     :: gpuAvailable = .FALSE.
    LOGICAL     :: mpiAvailable = .FALSE.
    LOGICAL     :: ompAvailable = .FALSE.
  END TYPE IF_DeviceCaps
```

### `IF_Base_Domain` (lines 53–66)

```fortran
  TYPE, PUBLIC :: IF_Base_Domain
    TYPE(IF_DeviceCaps)            :: deviceCaps
    TYPE(IF_SymEntry), ALLOCATABLE :: sym_table(:)
    INTEGER(i4)                    :: nEntries    = 0_i4
    INTEGER(i4)                    :: sym_cap     = 0_i4
    INTEGER(i4)                    :: nThreads    = 1_i4
    LOGICAL                        :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetCaps
    PROCEDURE :: RegisterSymbol
    PROCEDURE :: LookupSymbol
  END TYPE IF_Base_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 73 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `GetCaps` | 93 | `SUBROUTINE GetCaps(this, caps, status)` |
| SUBROUTINE | `Init` | 110 | `SUBROUTINE Init(this, nThreads, sym_capacity, status)` |
| SUBROUTINE | `LookupSymbol` | 159 | `SUBROUTINE LookupSymbol(this, name, id, status)` |
| SUBROUTINE | `RegisterSymbol` | 195 | `SUBROUTINE RegisterSymbol(this, name, id, kind, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
