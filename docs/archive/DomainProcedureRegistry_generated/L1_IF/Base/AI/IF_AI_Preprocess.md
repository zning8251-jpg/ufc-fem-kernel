# `IF_AI_Preprocess.f90`

- **Source**: `L1_IF/Base/AI/IF_AI_Preprocess.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_AI_Preprocess`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_AI_Preprocess`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_AI_Preprocess`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/AI/IF_AI_Preprocess.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_AI_NormalizationParams` (lines 21–27)

```fortran
  TYPE, PUBLIC :: IF_AI_NormalizationParams
    REAL(wp), ALLOCATABLE :: min_vals(:)    ! 最小值(Min-Max归一化)
    REAL(wp), ALLOCATABLE :: max_vals(:)    ! 最大值(Min-Max归一化)
    REAL(wp), ALLOCATABLE :: mean(:)        ! 均值(Z-Score标准化)
    REAL(wp), ALLOCATABLE :: std(:)         ! 标准差(Z-Score标准化)
    INTEGER(i4) :: method                   ! 方法: 1=Min-Max, 2=Z-Score
  END TYPE IF_AI_NormalizationParams
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_Preprocess_Normalize` | 43 | `SUBROUTINE IF_AI_Preprocess_Normalize(input, output, params, n, status)` |
| SUBROUTINE | `IF_AI_Preprocess_Denormalize` | 101 | `SUBROUTINE IF_AI_Preprocess_Denormalize(input, output, params, n, status)` |
| SUBROUTINE | `IF_AI_Preprocess_ExtractFeatures` | 151 | `SUBROUTINE IF_AI_Preprocess_ExtractFeatures(physical_inputs, features, &` |
| SUBROUTINE | `IF_AI_Preprocess_MapToPhysical` | 190 | `SUBROUTINE IF_AI_Preprocess_MapToPhysical(ai_outputs, physical_outputs, &` |
| SUBROUTINE | `IF_AI_Preprocess_ValidateInput` | 227 | `SUBROUTINE IF_AI_Preprocess_ValidateInput(data, n, is_valid, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
