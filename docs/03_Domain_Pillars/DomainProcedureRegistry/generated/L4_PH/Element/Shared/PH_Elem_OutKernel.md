# `PH_Elem_OutKernel.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_OutKernel.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_OutKernel`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_OutKernel`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_OutKernel`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_OutKernel.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Elem_Out_Arg` (lines 24–29)

```fortran
  TYPE, PUBLIC :: Elem_Out_Arg
    INTEGER(i4) :: elem_type_id                   ! [IN]
    INTEGER(i4) :: n_nodes                   ! [IN]
    INTEGER(i4) :: n_ip                   ! [IN]
    INTEGER(i4) :: n_vars                   ! [IN]
  END TYPE Elem_Out_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Elem_Output_Collect` | 42 | `SUBROUTINE Elem_Output_Collect(in_data, out_data, status)` |
| SUBROUTINE | `Elem_Output_Extrap` | 77 | `SUBROUTINE Elem_Output_Extrap(in_data, extrap_mat, out_data, status)` |
| SUBROUTINE | `Elem_Output_StressStrain` | 100 | `SUBROUTINE Elem_Output_StressStrain(stress_voigt, stress_principal, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
