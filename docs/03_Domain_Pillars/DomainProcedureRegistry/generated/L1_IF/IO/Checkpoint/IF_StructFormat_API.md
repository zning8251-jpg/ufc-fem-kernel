# `IF_StructFormat_API.f90`

- **Source**: `L1_IF/IO/Checkpoint/IF_StructFormat_API.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_StructFormat_API`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_StructFormat_API`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_StructFormat`
- **第四段角色（四段式）**: `_API`
- **源码子路径（层下目录，不含文件名）**: `IO/Checkpoint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/Checkpoint/IF_StructFormat_API.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `sfa_get_struct_meta_by_var` | 48 | `SUBROUTINE sfa_get_struct_meta_by_var(var_name, meta, status)` |
| SUBROUTINE | `sfa_read_struct_txt_like` | 115 | `SUBROUTINE sfa_read_struct_txt_like(var_name, file_path, caller_tag, status)` |
| SUBROUTINE | `sfa_write_struct_csv` | 161 | `SUBROUTINE sfa_write_struct_csv(var_name, file_path, status)` |
| SUBROUTINE | `sfa_write_struct_dat` | 362 | `SUBROUTINE sfa_write_struct_dat(var_name, file_path, status)` |
| SUBROUTINE | `sfa_write_struct_inp` | 575 | `SUBROUTINE sfa_write_struct_inp(var_name, file_path, status)` |
| SUBROUTINE | `sfa_write_struct_txt_like` | 806 | `SUBROUTINE sfa_write_struct_txt_like(var_name, file_path, caller_tag, status)` |
| SUBROUTINE | `sfm_read_struct_csv` | 860 | `SUBROUTINE sfm_read_struct_csv(var_name, file_path, status)` |
| SUBROUTINE | `sfm_read_struct_dat` | 869 | `SUBROUTINE sfm_read_struct_dat(var_name, file_path, status)` |
| SUBROUTINE | `sfm_read_struct_inp` | 877 | `SUBROUTINE sfm_read_struct_inp(var_name, file_path, status)` |
| SUBROUTINE | `sfm_write_struct_csv` | 886 | `SUBROUTINE sfm_write_struct_csv(var_name, file_path, status)` |
| SUBROUTINE | `sfm_write_struct_dat` | 894 | `SUBROUTINE sfm_write_struct_dat(var_name, file_path, status)` |
| SUBROUTINE | `sfm_write_struct_inp` | 902 | `SUBROUTINE sfm_write_struct_inp(var_name, file_path, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
