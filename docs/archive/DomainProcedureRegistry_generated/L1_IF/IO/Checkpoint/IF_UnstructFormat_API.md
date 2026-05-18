# `IF_UnstructFormat_API.f90`

- **Source**: `L1_IF/IO/Checkpoint/IF_UnstructFormat_API.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_UnstructFormat_API`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_UnstructFormat_API`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_UnstructFormat`
- **第四段角色（四段式）**: `_API`
- **源码子路径（层下目录，不含文件名）**: `IO/Checkpoint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/Checkpoint/IF_UnstructFormat_API.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ufa_get_unstruct_meta_by_var` | 34 | `SUBROUTINE ufa_get_unstruct_meta_by_var(var_name, meta, status)` |
| SUBROUTINE | `ufm_load_unstruct_csv` | 54 | `SUBROUTINE ufm_load_unstruct_csv(var_name, file_path, status, loaded_id_opt)` |
| SUBROUTINE | `ufm_load_unstruct_dat` | 92 | `SUBROUTINE ufm_load_unstruct_dat(var_name, file_path, status, loaded_id_opt)` |
| SUBROUTINE | `ufm_load_unstruct_inp` | 130 | `SUBROUTINE ufm_load_unstruct_inp(var_name, file_path, status, loaded_id_opt)` |
| SUBROUTINE | `ufm_write_unstruct_csv` | 168 | `SUBROUTINE ufm_write_unstruct_csv(var_name, file_path, status)` |
| SUBROUTINE | `ufm_write_unstruct_dat` | 197 | `SUBROUTINE ufm_write_unstruct_dat(var_name, file_path, status)` |
| SUBROUTINE | `ufm_write_unstruct_inp` | 226 | `SUBROUTINE ufm_write_unstruct_inp(var_name, file_path, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
