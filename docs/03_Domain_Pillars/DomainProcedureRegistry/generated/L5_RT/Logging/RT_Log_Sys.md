# `RT_Log_Sys.f90`

- **Source**: `L5_RT/Logging/RT_Log_Sys.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Log_Sys`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Log_Sys`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Log`
- **第四段角色（四段式）**: `_Sys`
- **源码子路径（层下目录，不含文件名）**: `Logging`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Logging/RT_Log_Sys.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_LogConfig` (lines 74–83)

```fortran
    TYPE, PUBLIC :: RT_LogConfig
        INTEGER(i4) :: log_level = LOG_LEVEL_INFO
        INTEGER(i4) :: output_target = LOG_OUTPUT_STDOUT
        CHARACTER(LEN=256) :: log_file = "ufc_run.log"
        LOGICAL :: append_mode = .FALSE.
        LOGICAL :: include_timestamp = .TRUE.
        LOGICAL :: include_level = .TRUE.
        LOGICAL :: include_module = .TRUE.
        LOGICAL :: colorize_output = .FALSE.
    END TYPE RT_LogConfig
```

### `RT_Logger` (lines 92–94)

```fortran
    TYPE, PUBLIC :: RT_Logger
        TYPE(RT_LogConfig) :: config
    END TYPE RT_Logger
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `map_output_target` | 105 | `PURE FUNCTION map_output_target(rt_out) RESULT(if_out)` |
| SUBROUTINE | `rt_config_to_if_config` | 127 | `SUBROUTINE rt_config_to_if_config(rt_cfg, if_cfg)` |
| SUBROUTINE | `RT_Log_Init` | 146 | `SUBROUTINE RT_Log_Init(config, status)` |
| SUBROUTINE | `RT_Log_Debug` | 167 | `SUBROUTINE RT_Log_Debug(message, module_name, function_name)` |
| SUBROUTINE | `RT_Log_Info` | 179 | `SUBROUTINE RT_Log_Info(message, module_name, function_name)` |
| SUBROUTINE | `RT_Log_Warn` | 191 | `SUBROUTINE RT_Log_Warn(message, module_name, function_name)` |
| SUBROUTINE | `RT_Log_Error` | 203 | `SUBROUTINE RT_Log_Error(message, module_name, function_name)` |
| SUBROUTINE | `RT_Log_Fatal` | 215 | `SUBROUTINE RT_Log_Fatal(message, module_name, function_name)` |
| SUBROUTINE | `RT_Log_Finalize` | 224 | `SUBROUTINE RT_Log_Finalize()` |
| SUBROUTINE | `RT_Log_Unified_Manage` | 236 | `SUBROUTINE RT_Log_Unified_Manage(logger, level, message, module_name, status)` |
| SUBROUTINE | `RT_Log_Unified_Cfg` | 293 | `SUBROUTINE RT_Log_Unified_Cfg(log_level, output_target, log_file, logger, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
