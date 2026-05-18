# `PH_Elem_Infinite.f90`

- **Source**: `L4_PH/Element/Infinite/PH_Elem_Infinite.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Infinite`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Infinite`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Infinite`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Infinite`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Infinite/PH_Elem_Infinite.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `InfiniteElemParams` (lines 43–49)

```fortran
  TYPE, PUBLIC :: InfiniteElemParams
    INTEGER(i4) :: decay_type = 1  ! 1=exponential, 2=polynomial, 3=rational
    REAL(wp) :: decay_rate = 1.0_wp
    REAL(wp) :: decay_power = 2.0_wp
    REAL(wp) :: reference_dista = 1.0_wp
    LOGICAL :: use_geometric_m = .TRUE.
  END TYPE InfiniteElemParams
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_Infinite_GetDecayParams` | 51 | `SUBROUTINE PH_Elem_Infinite_GetDecayParams(Mat, params)` |
| SUBROUTINE | `PH_Elem_Infinite_SetDecayParams` | 70 | `SUBROUTINE PH_Elem_Infinite_SetDecayParams(decay_type, decay_rate, decay_power, &` |
| FUNCTION | `PH_Elem_Infinite_GetDefaultParams` | 86 | `FUNCTION PH_Elem_Infinite_GetDefaultParams() RESULT(params)` |
| SUBROUTINE | `UF_Elem_Infinite_Calc` | 98 | `SUBROUTINE UF_Elem_Infinite_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UPPER_CASE` | 148 | `SUBROUTINE UPPER_CASE(str)` |
| SUBROUTINE | `UF_BuildIsotropic2D_PlaneStrain_Local` | 160 | `SUBROUTINE UF_BuildIsotropic2D_PlaneStrain_Local(Mat, D)` |
| SUBROUTINE | `UF_BuildIsotropic3D_Local` | 184 | `SUBROUTINE UF_BuildIsotropic3D_Local(Mat, D)` |
| FUNCTION | `UF_ComputeDecayFunction` | 211 | `FUNCTION UF_ComputeDecayFunction(xi, params) RESULT(decay)` |
| SUBROUTINE | `UF_ComputeInfiniteMapping` | 241 | `SUBROUTINE UF_ComputeInfiniteMapping(coords_ref, xi, x_mapped, detJ, params, status)` |
| SUBROUTINE | `UF_ComputeInfiniteShapeFunctions` | 294 | `SUBROUTINE UF_ComputeInfiniteShapeFunctions(coords_ref, xi, N, status, dNdxi)` |
| SUBROUTINE | `UF_ComputeBMatrix_Infinite2D` | 352 | `SUBROUTINE UF_ComputeBMatrix_Infinite2D(coords, N, dNdxi, detJ, B, params, status)` |
| SUBROUTINE | `UF_ComputeBMatrix_Infinite3D` | 401 | `SUBROUTINE UF_ComputeBMatrix_Infinite3D(coords, N, dNdxi, detJ, B, params, status)` |
| SUBROUTINE | `UF_Elem_Infinite2D_Calc` | 463 | `SUBROUTINE UF_Elem_Infinite2D_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UF_Elem_Infinite3D_Calc` | 615 | `SUBROUTINE UF_Elem_Infinite3D_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_Infinite_Material_Update_Decay_Routed` | 765 | `SUBROUTINE PH_Elem_Infinite_Material_Update_Decay_Routed(rt_ctx, mat_slot, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
