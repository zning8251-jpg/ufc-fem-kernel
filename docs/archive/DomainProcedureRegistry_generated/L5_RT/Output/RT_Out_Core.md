# `RT_Out_Core.f90`

- **Source**: `L5_RT/Output/RT_Out_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Out_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Output_Desc` (lines 32–38)

```fortran
  TYPE, PUBLIC :: RT_Output_Desc
    CHARACTER(LEN=256) :: file_path   = ''
    INTEGER(i4)        :: unit_num    = 10_i4
    INTEGER(i4)        :: output_freq = 1_i4
    INTEGER(i4)        :: output_format = 1_i4  ! 1=VTK
    LOGICAL            :: is_active   = .TRUE.
  END TYPE RT_Output_Desc
```

### `RT_Output_State` (lines 40–45)

```fortran
  TYPE, PUBLIC :: RT_Output_State
    INTEGER(i4) :: frame_count   = 0_i4
    INTEGER(i4) :: bytes_written = 0_i4
    REAL(wp)    :: total_written = 0.0_wp
    LOGICAL     :: is_open       = .FALSE.
  END TYPE RT_Output_State
```

### `RT_Output_Ctx` (lines 47–50)

```fortran
  TYPE, PUBLIC :: RT_Output_Ctx
    REAL(wp), POINTER :: write_buffer(:) => NULL()
    INTEGER(i4)       :: buf_size = 0_i4
  END TYPE RT_Output_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Output_Core_Init` | 63 | `SUBROUTINE RT_Output_Core_Init(desc, state, ctx, status)` |
| SUBROUTINE | `RT_Output_Core_Finalize` | 79 | `SUBROUTINE RT_Output_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `RT_Output_Open_File` | 95 | `SUBROUTINE RT_Output_Open_File(desc, state, status)` |
| SUBROUTINE | `RT_Output_Close_File` | 124 | `SUBROUTINE RT_Output_Close_File(state, status)` |
| SUBROUTINE | `RT_Output_Write_Frame` | 135 | `SUBROUTINE RT_Output_Write_Frame(desc, state, ctx, time, status)` |
| SUBROUTINE | `RT_Output_Write_Field` | 164 | `SUBROUTINE RT_Output_Write_Field(desc, state, ctx, field_name, &` |
| SUBROUTINE | `RT_Output_Write_History` | 206 | `SUBROUTINE RT_Output_Write_History(desc, state, time, value, label, status)` |
| SUBROUTINE | `RT_Output_Check_Frequency` | 232 | `SUBROUTINE RT_Output_Check_Frequency(desc, state, inc_num, should_write)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
