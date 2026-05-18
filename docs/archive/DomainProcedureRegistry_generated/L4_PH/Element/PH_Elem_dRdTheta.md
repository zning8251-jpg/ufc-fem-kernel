# `PH_Elem_dRdTheta.f90`

- **Source**: `L4_PH/Element/PH_Elem_dRdTheta.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_dRdTheta`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_dRdTheta`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_dRdTheta`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_dRdTheta.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_DiffPhys_Desc` (lines 26–31)

```fortran
  TYPE, PUBLIC :: PH_Elem_DiffPhys_Desc
    LOGICAL     :: enabled        = .FALSE.
    INTEGER(i4) :: grad_method    = PH_GRAD_NONE
    REAL(wp)    :: fd_perturbation = 1.0E-7_wp
    INTEGER(i4) :: n_theta        = 0
  END TYPE PH_Elem_DiffPhys_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_dRdTheta_Interface` | 37 | `SUBROUTINE PH_Elem_dRdTheta_Interface( &` |
| SUBROUTINE | `PH_Elem_dRdTheta_FD` | 59 | `SUBROUTINE PH_Elem_dRdTheta_FD( &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
