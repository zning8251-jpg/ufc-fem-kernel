# `PH_Elem_B31TP.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31TP.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B31TP`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31TP`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31TP`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31TP.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `FiberState` (lines 64–72)

```fortran
  TYPE, PUBLIC :: FiberState
    REAL(wp) :: y_pos      ! Fiber y-coordinate (section centroid)
    REAL(wp) :: z_pos      ! Fiber z-coordinate
    REAL(wp) :: area       ! Fiber area
    REAL(wp) :: strain     ! Axial strain at fiber
    REAL(wp) :: stress     ! Axial stress
    REAL(wp) :: eps_pl     ! Equivalent plastic strain
    LOGICAL  :: is_yielded ! Yielding flag
  END TYPE FiberState
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31TP_DefInit` | 92 | `SUBROUTINE PH_Elem_B31TP_DefInit(ElemDef, status)` |
| SUBROUTINE | `PH_Elem_B31TP_InitFibers` | 114 | `SUBROUTINE PH_Elem_B31TP_InitFibers(props, fibers, status)` |
| SUBROUTINE | `PH_Elem_B31TP_FormStiffMatrixTan` | 165 | `SUBROUTINE PH_Elem_B31TP_FormStiffMatrixTan(coords, props, u14, fibers, Ke14)` |
| SUBROUTINE | `PH_Elem_B31TP_FormElasticStiffMat` | 262 | `SUBROUTINE PH_Elem_B31TP_FormElasticStiffMat(L, E, A, Iy, Iz, Ke)` |
| SUBROUTINE | `PH_Elem_B31TP_UpdateFiberStress` | 291 | `SUBROUTINE PH_Elem_B31TP_UpdateFiberStress(fiber, dstrain, props, status)` |
| SUBROUTINE | `PH_Elem_B31TP_FormIntForce` | 348 | `SUBROUTINE PH_Elem_B31TP_FormIntForce(coords, props, u14, fibers, R14)` |
| SUBROUTINE | `PH_Elem_B31TP_ConsMass` | 370 | `SUBROUTINE PH_Elem_B31TP_ConsMass(coords, rho, area, Me14)` |
| SUBROUTINE | `PH_Elem_B31TP_LumpMass` | 378 | `SUBROUTINE PH_Elem_B31TP_LumpMass(coords, rho, area, M_lump14)` |
| SUBROUTINE | `UF_Elem_B31TP_Calc` | 389 | `SUBROUTINE UF_Elem_B31TP_Calc(elem_type, formul, ctx, state_in, mat_props, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
