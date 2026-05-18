# `PH_Elem_LoadKernel.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_LoadKernel.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_LoadKernel`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_LoadKernel`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_LoadKernel`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_LoadKernel.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Elem_Load_Arg` (lines 19–21)

```fortran
  TYPE, PUBLIC :: Elem_Load_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE Elem_Load_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Compute_BodyForce` | 34 | `SUBROUTINE Compute_BodyForce(desc, in, out, status)` |
| SUBROUTINE | `Compute_SurfPressure` | 56 | `SUBROUTINE Compute_SurfPressure(desc, in, out, status)` |
| SUBROUTINE | `Compute_EdgePressure` | 77 | `SUBROUTINE Compute_EdgePressure(desc, in, out, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
