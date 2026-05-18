# `IF_IO_Backup.f90`

- **Source**: `L1_IF/IO/Checkpoint/IF_IO_Backup.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_IO_Backup`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Backup`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_Backup`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO/Checkpoint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/Checkpoint/IF_IO_Backup.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `backup_data` | 57 | `SUBROUTINE backup_data(var_name, backup_id, status)` |
| SUBROUTINE | `bm_backup_struct` | 98 | `SUBROUTINE bm_backup_struct(var_name, struct_meta, file_path, status)` |
| SUBROUTINE | `bm_backup_unstruct` | 306 | `SUBROUTINE bm_backup_unstruct(var_name, unstruct_meta, file_path, status)` |
| SUBROUTINE | `bm_calculate_file_crc32` | 352 | `SUBROUTINE bm_calculate_file_crc32(file_path, crc32, status)` |
| SUBROUTINE | `bm_get_meta` | 409 | `SUBROUTINE bm_get_meta(var_name, struct_meta, unstruct_meta, status)` |
| SUBROUTINE | `bm_restore_struct` | 482 | `SUBROUTINE bm_restore_struct(var_name, struct_meta, file_path, status)` |
| SUBROUTINE | `bm_restore_unstruct` | 690 | `SUBROUTINE bm_restore_unstruct(var_name, unstruct_meta, file_path, status)` |
| SUBROUTINE | `restore_data` | 756 | `SUBROUTINE restore_data(var_name, backup_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
