# `IF_Base_Def.f90`

- **Source**: `L1_IF/Base/IF_Base_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Base_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Base_Desc` (lines 17–21)

```fortran
  TYPE, PUBLIC :: IF_Base_Desc
    INTEGER(i4)        :: ndim          = 3       ! spatial dimensions
    INTEGER(i4)        :: analysis_type = 0       ! 0=static, 1=dynamic, 2=thermal
    CHARACTER(LEN=128) :: version       = "UFC v1.0"
  END TYPE IF_Base_Desc
```

### `IF_Base_Call_Ctx` (lines 26–29)

```fortran
  TYPE, PUBLIC :: IF_Base_Call_Ctx
    INTEGER(i4) :: caller_layer = 0_i4   ! originating layer (1..6)
    INTEGER(i4) :: call_phase   = 0_i4   ! P0..P3 phase tag
  END TYPE IF_Base_Call_Ctx
```

### `IF_Base_State` (lines 34–38)

```fortran
  TYPE, PUBLIC :: IF_Base_State
    LOGICAL     :: initialized   = .FALSE.
    INTEGER(i4) :: current_step  = 0_i4
    INTEGER(i4) :: current_incr  = 0_i4
  END TYPE IF_Base_State
```

### `IF_Base_Algo` (lines 43–46)

```fortran
  TYPE, PUBLIC :: IF_Base_Algo
    INTEGER(i4) :: sym_capacity  = 256_i4  ! initial symbol-table capacity
    INTEGER(i4) :: n_threads     = 1_i4    ! requested thread count
  END TYPE IF_Base_Algo
```

### `IF_SymEntry` (lines 51–55)

```fortran
  TYPE, PUBLIC :: IF_SymEntry
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4)       :: id   = 0_i4   ! registered integer id
    INTEGER(i4)       :: kind = 0_i4   ! IF_SYM_* enumeration
  END TYPE IF_SymEntry
```

### `IF_DeviceCaps` (lines 60–66)

```fortran
  TYPE, PUBLIC :: IF_DeviceCaps
    INTEGER(i4) :: nCPUCores    = 1_i4
    INTEGER(i4) :: nGPUDevices  = 0_i4
    LOGICAL     :: gpuAvailable = .FALSE.
    LOGICAL     :: mpiAvailable = .FALSE.
    LOGICAL     :: ompAvailable = .FALSE.
  END TYPE IF_DeviceCaps
```

### `BaseCtx` (lines 71–83)

```fortran
  TYPE, PUBLIC :: BaseCtx
    INTEGER(i4) :: ctx_id   = 0_i4
    INTEGER(i4) :: ctx_level = 0_i4   ! Layer level (1..6)
    LOGICAL     :: is_active = .FALSE.
    TYPE(ErrorStatusType) :: err_status
  CONTAINS
    PROCEDURE, PUBLIC :: Init     => BaseCtx_Init
    PROCEDURE, PUBLIC :: Cleanup  => BaseCtx_Cleanup
    PROCEDURE, PUBLIC :: ClearStatus => BaseCtx_ClearStatus
    PROCEDURE, PUBLIC :: SetStatus   => BaseCtx_SetStatus
    PROCEDURE, PUBLIC :: IsOK       => BaseCtx_IsOK
    PROCEDURE, PUBLIC :: IsError    => BaseCtx_IsError
  END TYPE BaseCtx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BaseCtx_Init` | 87 | `SUBROUTINE BaseCtx_Init(this, ctx_level)` |
| SUBROUTINE | `BaseCtx_Cleanup` | 98 | `SUBROUTINE BaseCtx_Cleanup(this)` |
| SUBROUTINE | `BaseCtx_ClearStatus` | 107 | `SUBROUTINE BaseCtx_ClearStatus(this)` |
| SUBROUTINE | `BaseCtx_SetStatus` | 112 | `SUBROUTINE BaseCtx_SetStatus(this, status)` |
| FUNCTION | `BaseCtx_IsOK` | 118 | `FUNCTION BaseCtx_IsOK(this) RESULT(ok)` |
| FUNCTION | `BaseCtx_IsError` | 124 | `FUNCTION BaseCtx_IsError(this) RESULT(is_err)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
