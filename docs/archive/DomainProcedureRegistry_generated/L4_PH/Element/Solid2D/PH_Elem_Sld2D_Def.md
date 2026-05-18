# `PH_Elem_Sld2D_Def.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_Sld2D_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Sld2D_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Sld2D_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Sld2D`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_Sld2D_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld2D_Calc_Arg` (lines 51–60)

```fortran
  TYPE, PUBLIC :: PH_Elem_Sld2D_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Sld2D_Calc_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Sld2D_Calc` | 80 | `SUBROUTINE PH_Elem_Sld2D_Calc(arg)` |
| SUBROUTINE | `PH_Elem_Sld2D_Calc_Structured` | 142 | `SUBROUTINE PH_Elem_Sld2D_Calc_Structured(arg)` |
| SUBROUTINE | `UF_Elem_Sld2D_Calc` | 155 | `SUBROUTINE UF_Elem_Sld2D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `RecoverStress_Sld2D` | 188 | `SUBROUTINE RecoverStress_Sld2D(ipStates, sf, nodeStress, nNode, ntens)` |
| SUBROUTINE | `Calc_CPE4` | 239 | `SUBROUTINE Calc_CPE4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `Calc_CPS4` | 256 | `SUBROUTINE Calc_CPS4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `Calc_CAX4` | 273 | `SUBROUTINE Calc_CAX4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `UPPER_CASE` | 289 | `SUBROUTINE UPPER_CASE(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
