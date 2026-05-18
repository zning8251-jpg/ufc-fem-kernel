# `RT_Out_Impl.f90`

- **Source**: `L5_RT/Output/RT_Out_Impl.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Out_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Out_Impl_Init` | 61 | `SUBROUTINE RT_Out_Impl_Init(input, output)` |
| SUBROUTINE | `RT_Out_Impl_Collect` | 106 | `SUBROUTINE RT_Out_Impl_Collect(input, output)` |
| SUBROUTINE | `RT_Out_Impl_CheckFreq` | 164 | `SUBROUTINE RT_Out_Impl_CheckFreq(input, output)` |
| SUBROUTINE | `RT_Out_Impl_Write` | 227 | `SUBROUTINE RT_Out_Impl_Write(input, output)` |
| FUNCTION | `ITOA` | 284 | `FUNCTION ITOA(i) RESULT(str)` |
| SUBROUTINE | `RT_Out_Impl_WriteScalar` | 295 | `SUBROUTINE RT_Out_Impl_WriteScalar(field_name, values, n_values, &` |
| SUBROUTINE | `RT_Out_Impl_WriteVector` | 334 | `SUBROUTINE RT_Out_Impl_WriteVector(field_name, values, n_values, ndim, &` |
| SUBROUTINE | `RT_Out_Impl_WriteTensor` | 370 | `SUBROUTINE RT_Out_Impl_WriteTensor(field_name, values, n_values, ncomp, &` |
| SUBROUTINE | `RT_Out_Impl_Finalize` | 406 | `SUBROUTINE RT_Out_Impl_Finalize(input, output)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
