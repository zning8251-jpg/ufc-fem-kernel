# `PH_Elem_CommonUtil.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_CommonUtil.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CommonUtil`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CommonUtil`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CommonUtil`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_CommonUtil.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_ExtractResults_Arg` (lines 52–59)

```fortran
  TYPE, PUBLIC :: PH_Elem_ExtractResults_Arg
    TYPE(ElemState) :: state_out  ! Element output state (State)                   ! [IN]
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    REAL(wp) :: max_stress  ! Maximum stress magnitude                   ! [OUT]
    REAL(wp) :: max_strain  ! Maximum strain magnitude                   ! [OUT]
    REAL(wp) :: von_mises_stress  ! Maximum Von Mises stress _vm                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_ExtractResults_Arg
```

### `PH_Elem_ValidateInput_Arg` (lines 65–70)

```fortran
  TYPE, PUBLIC :: PH_Elem_ValidateInput_Arg
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    TYPE(ElemCtx) :: ctx  ! Element context (Ctx)                   ! [IN]
    TYPE(MatProperties) :: mat  ! Material properties (Desc)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_ValidateInput_Arg
```

### `PH_Elem_ComputeEnergy_Arg` (lines 76–83)

```fortran
  TYPE, PUBLIC :: PH_Elem_ComputeEnergy_Arg
    TYPE(ElemState) :: state_out  ! Element output state (State)                   ! [IN]
    TYPE(ElemType) :: elem_type  ! Element type descriptor (Desc)                   ! [IN]
    REAL(wp) :: strain_energy  ! Strain energy U                   ! [OUT]
    REAL(wp) :: kinetic_energy  ! Kinetic energy T                   ! [OUT]
    REAL(wp) :: total_energy  ! Total energy E = U + T                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_ComputeEnergy_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_ComputeEnergy` | 88 | `SUBROUTINE PH_Elem_ComputeEnergy(in, out)` |
| SUBROUTINE | `PH_Elem_ComputeEnergy_Structured` | 135 | `SUBROUTINE PH_Elem_ComputeEnergy_Structured(arg)` |
| SUBROUTINE | `PH_Elem_ExtractResults` | 143 | `SUBROUTINE PH_Elem_ExtractResults(arg)` |
| SUBROUTINE | `PH_Elem_ExtractResults_Structured` | 203 | `SUBROUTINE PH_Elem_ExtractResults_Structured(arg)` |
| SUBROUTINE | `PH_Elem_ValidateInput` | 211 | `SUBROUTINE PH_Elem_ValidateInput(arg)` |
| SUBROUTINE | `UF_BatchComputeElements` | 299 | `SUBROUTINE UF_BatchComputeElements(elementTypes, contexts, materials, &` |
| FUNCTION | `UF_CheckElementConvergence` | 361 | `FUNCTION UF_CheckElementConvergence(state_old, state_new, &` |
| SUBROUTINE | `UF_ComputeElementEnergy` | 392 | `SUBROUTINE UF_ComputeElementEnergy(state_out, ElemType, &` |
| SUBROUTINE | `UF_Elem_ComputeWithQualityCheck` | 418 | `SUBROUTINE UF_Elem_ComputeWithQualityCheck(ElemType, Formul, Ctx, &` |
| SUBROUTINE | `UF_ExtractElementResults` | 451 | `SUBROUTINE UF_ExtractElementResults(state_out, ElemType, &` |
| SUBROUTINE | `UF_ValidateElementInput` | 481 | `SUBROUTINE UF_ValidateElementInput(ElemType, Ctx, Mat, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
