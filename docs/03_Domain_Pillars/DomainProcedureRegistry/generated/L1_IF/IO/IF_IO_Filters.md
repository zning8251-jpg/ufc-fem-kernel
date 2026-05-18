# `IF_IO_Filters.f90`

- **Source**: `L1_IF/IO/IF_IO_Filters.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_IO_Filters`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Filters`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_Filters`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Filters.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_IO_Filter_Options` (lines 33–37)

```fortran
    TYPE, PUBLIC :: IF_IO_Filter_Options
        INTEGER(i4) :: default_format_type   = 0_i4
        INTEGER(i4) :: default_compress_type = 0_i4
        INTEGER(i4) :: default_encrypt_type  = 0_i4
    END TYPE IF_IO_Filter_Options
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_IO_Filter_Proc` | 43 | `SUBROUTINE IF_IO_Filter_Proc(input, input_size, output, output_size, io_flags, status)` |
| SUBROUTINE | `IF_IO_Filter_Identity` | 64 | `SUBROUTINE IF_IO_Filter_Identity(input, input_size, output, output_size, io_flags, status)` |
| SUBROUTINE | `IF_IO_Filter_Init_Options` | 92 | `SUBROUTINE IF_IO_Filter_Init_Options(options)` |
| SUBROUTINE | `IF_IO_Filter_Set_Default_Options` | 106 | `SUBROUTINE IF_IO_Filter_Set_Default_Options(options, format_type, compress_type, encrypt_type, status)` |
| SUBROUTINE | `IF_IO_Filter_XOR_Read` | 129 | `SUBROUTINE IF_IO_Filter_XOR_Read(input, input_size, output, output_size, io_flags, status)` |
| SUBROUTINE | `IF_IO_Filter_XOR_Write` | 170 | `SUBROUTINE IF_IO_Filter_XOR_Write(input, input_size, output, output_size, io_flags, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
