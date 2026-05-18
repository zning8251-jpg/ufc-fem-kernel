# `IF_Err_Brg.f90`

- **Source**: `L1_IF/Error/IF_Err_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Err_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Err_Brg`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Err`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Error`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Error/IF_Err_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `LogConfigType` (lines 119–122)

```fortran
    TYPE, PRIVATE :: LogConfigType
        INTEGER(i4) :: log_level = IF_LEVEL_INFO
        LOGICAL :: console_output = .TRUE.
    END TYPE LogConfigType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `init_error_status` | 141 | `SUBROUTINE init_error_status(status, status_code, message, source, line_number, thread_id, scene_id, enable_stack)` |
| SUBROUTINE | `error_set` | 185 | `SUBROUTINE error_set(code, message, source, status)` |
| SUBROUTINE | `error_clear` | 202 | `SUBROUTINE error_clear(status)` |
| SUBROUTINE | `err_api_write_log` | 218 | `SUBROUTINE err_api_write_log(level, module_name, message)` |
| SUBROUTINE | `log_debug` | 242 | `SUBROUTINE log_debug(module_name, message)` |
| SUBROUTINE | `log_info` | 247 | `SUBROUTINE log_info(module_name, message)` |
| SUBROUTINE | `log_warn` | 252 | `SUBROUTINE log_warn(module_name, message)` |
| SUBROUTINE | `log_error` | 257 | `SUBROUTINE log_error(module_name, message)` |
| SUBROUTINE | `log_fatal` | 262 | `SUBROUTINE log_fatal(module_name, message)` |
| SUBROUTINE | `set_log_level` | 268 | `SUBROUTINE set_log_level(level)` |
| SUBROUTINE | `set_console_output` | 278 | `SUBROUTINE set_console_output(enable)` |
| SUBROUTINE | `uf_set_error_status` | 287 | `SUBROUTINE uf_set_error_status(status, code, message)` |
| SUBROUTINE | `uf_set_error_log` | 294 | `SUBROUTINE uf_set_error_log(code, message, source)` |
| SUBROUTINE | `warn_deprecated` | 305 | `SUBROUTINE warn_deprecated(old_name, new_name, module_name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
