# `PH_Elem_Thermal_Def.f90`

- **Source**: `L4_PH/Element/Thermal/PH_Elem_Thermal_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Thermal_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Thermal_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Thermal`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Thermal/PH_Elem_Thermal_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Therm_Args` (lines 24–37)

```fortran
  TYPE :: PH_Elem_Therm_Args
    !-- Input: Element topology
    INTEGER(i4)           :: elem_type = 0_i4          ! [IN]  Element type code
    TYPE(PH_Elem_Ctx)     :: ctx                       ! [INOUT] Element context

    !-- Input: Material models
    CLASS(*), POINTER     :: mat_models(:) => NULL()   ! [IN]  Material models array

    !-- Output: Thermal matrices (optional)
    REAL(wp), ALLOCATABLE :: Kt(:,:)                   ! [OUT] Conductivity matrix
    REAL(wp), ALLOCATABLE :: Ct(:,:)                   ! [OUT] Heat capacity matrix
    REAL(wp), ALLOCATABLE :: Ft(:)                     ! [OUT] Heat flux vector

  END TYPE PH_Elem_Therm_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Elem_Therm_Calc` | 45 | `SUBROUTINE UF_Elem_Therm_Calc(args, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
