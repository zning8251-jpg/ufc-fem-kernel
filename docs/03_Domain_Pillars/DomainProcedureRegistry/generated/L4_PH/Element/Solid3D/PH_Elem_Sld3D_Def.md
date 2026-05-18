# `PH_Elem_Sld3D_Def.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_Sld3D_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Sld3D_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Sld3D_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Sld3D`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_Sld3D_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld3D_Calc_Arg` (lines 51–60)

```fortran
  TYPE, PUBLIC :: PH_Elem_Sld3D_Calc_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemFormul) :: formul  ! Formulation parameters (Algo)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(ElemState) :: state_in  ! Input element state (State)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ElemState) :: state_out  ! Output element state (State)                   ! [OUT]
    TYPE(ElemFlags) :: flags  ! Element flags and status (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_Sld3D_Calc_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Sld3D_Calc` | 88 | `SUBROUTINE PH_Elem_Sld3D_Calc(arg)` |
| SUBROUTINE | `PH_Elem_Sld3D_Calc_Structured` | 159 | `SUBROUTINE PH_Elem_Sld3D_Calc_Structured(arg)` |
| SUBROUTINE | `UF_Elem_Sld3D_Calc` | 172 | `SUBROUTINE UF_Elem_Sld3D_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `Calc_C3D8` | 199 | `SUBROUTINE Calc_C3D8(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `Calc_C3D4` | 216 | `SUBROUTINE Calc_C3D4(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `Calc_C3D8R` | 233 | `SUBROUTINE Calc_C3D8R(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `RecoverStress_Sld3D` | 256 | `SUBROUTINE RecoverStress_Sld3D(ipStates, sf, nodeStress, nNode, ntens)` |
| SUBROUTINE | `UPPER_CASE` | 305 | `SUBROUTINE UPPER_CASE(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
