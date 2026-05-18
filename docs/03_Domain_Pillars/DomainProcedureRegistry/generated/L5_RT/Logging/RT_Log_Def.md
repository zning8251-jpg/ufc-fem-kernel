# `RT_Log_Def.f90`

- **Source**: `L5_RT/Logging/RT_Log_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Log_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Log_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Log`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Logging`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Logging/RT_Log_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Log_Desc` (lines 27–34)

```fortran
  TYPE, PUBLIC :: RT_Log_Desc
    INTEGER(i4)        :: log_level   = RT_LOG_LEVEL_INFO
    INTEGER(i4)        :: log_unit    = 6_i4
    INTEGER(i4)        :: output_mode = RT_LOG_OUT_STDOUT
    CHARACTER(LEN=32)  :: prefix      = '[UFC] '
    CHARACTER(LEN=256) :: log_file    = ''
    LOGICAL            :: timestamp_enabled = .TRUE.
  END TYPE RT_Log_Desc
```

### `RT_Log_Ctx` (lines 36–42)

```fortran
  TYPE, PUBLIC :: RT_Log_Ctx
    CHARACTER(LEN=256) :: line_buffer  = ''
    CHARACTER(LEN=64)  :: module_name  = ''
    INTEGER(i4)        :: step_id      = 0_i4
    INTEGER(i4)        :: inc_num      = 0_i4
    INTEGER(i4)        :: buf_pos      = 0_i4
  END TYPE RT_Log_Ctx
```

### `RT_Logging_State` (lines 44–51)

```fortran
  TYPE, PUBLIC :: RT_Logging_State
    LOGICAL     :: active       = .FALSE.
    INTEGER(i4) :: n_messages   = 0_i4
    INTEGER(i4) :: n_warnings   = 0_i4
    INTEGER(i4) :: n_errors     = 0_i4
    INTEGER(i4) :: n_debug      = 0_i4
    INTEGER(i4) :: n_fatal      = 0_i4
  END TYPE RT_Logging_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
