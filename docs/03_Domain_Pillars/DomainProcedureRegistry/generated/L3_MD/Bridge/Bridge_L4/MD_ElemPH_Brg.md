# `MD_ElemPH_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L4/MD_ElemPH_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_ElemPH_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_ElemPH_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_ElemPH`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L4`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L4/MD_ElemPH_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_PH_Elem_GetElemCtx_Arg` (lines 26–28)

```fortran
  TYPE, PUBLIC :: MD_PH_Elem_GetElemCtx_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx
  END TYPE MD_PH_Elem_GetElemCtx_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_PH_Elem_GetElemCtx_Idx` | 47 | `SUBROUTINE MD_PH_Elem_GetElemCtx_Idx(elem_idx, arg, status)` |
| SUBROUTINE | `MD_PH_Elem_CalcContinuum2D` | 62 | `SUBROUTINE MD_PH_Elem_CalcContinuum2D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |
| SUBROUTINE | `MD_PH_Elem_CalcContinuum3D` | 82 | `SUBROUTINE MD_PH_Elem_CalcContinuum3D(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |
| SUBROUTINE | `MD_PH_Elem_CalcPoroSaturated` | 102 | `SUBROUTINE MD_PH_Elem_CalcPoroSaturated(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |
| SUBROUTINE | `MD_PH_Elem_CalcPoroTwoPhase` | 122 | `SUBROUTINE MD_PH_Elem_CalcPoroTwoPhase(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |
| SUBROUTINE | `MD_PH_Elem_CalcThermal` | 142 | `SUBROUTINE MD_PH_Elem_CalcThermal(ElemType, Formul, Ctx, state_in, Mat, state_out, flags, status)` |
| SUBROUTINE | `MD_PH_Elem_CalcTHM` | 164 | `SUBROUTINE MD_PH_Elem_CalcTHM(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |
| SUBROUTINE | `MD_PH_Elem_CalcPoro` | 184 | `SUBROUTINE MD_PH_Elem_CalcPoro(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |
| SUBROUTINE | `MD_PH_Elem_CalcThm` | 204 | `SUBROUTINE MD_PH_Elem_CalcThm(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
