# `PH_Elem_B33P.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B33P.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B33P`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B33P`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B33P`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B33P.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `FiberState` (lines 55–61)

```fortran
  TYPE, PUBLIC :: FiberState
    REAL(wp) :: strain          ! Current axial strain
    REAL(wp) :: stress          ! Current axial stress
    REAL(wp) :: eps_plastic     ! Accumulated plastic strain
    REAL(wp) :: eps_yield       ! Current yield strain (with hardening)
    LOGICAL  :: is_yielding     ! .TRUE. if currently yielding
  END TYPE FiberState
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B33P_DefInit` | 82 | `SUBROUTINE PH_Elem_B33P_DefInit(ElemDef, status)` |
| SUBROUTINE | `PH_Elem_B33P_ConsMassWithSection` | 107 | `SUBROUTINE PH_Elem_B33P_ConsMassWithSection(coords, rho, area, Me)` |
| SUBROUTINE | `PH_Elem_B33P_FormStiffMatrix` | 158 | `SUBROUTINE PH_Elem_B33P_FormStiffMatrix(coords, E_young, nu, area, I_bend, Ke)` |
| SUBROUTINE | `PH_Elem_B33P_IntegrateSection` | 247 | `SUBROUTINE PH_Elem_B33P_IntegrateSection(eps_axial, kappa, E_young, sigma_y, H, &` |
| SUBROUTINE | `PH_Elem_B33P_FormTangentMatrix` | 354 | `SUBROUTINE PH_Elem_B33P_FormTangentMatrix(coords_ref, u, E_young, nu, &` |
| SUBROUTINE | `PH_Elem_B33P_FormIntForce` | 485 | `SUBROUTINE PH_Elem_B33P_FormIntForce(coords_ref, u, E_young, nu, area, I_bend, &` |
| SUBROUTINE | `PH_Elem_B33P_LumpMassWithSection` | 522 | `SUBROUTINE PH_Elem_B33P_LumpMassWithSection(coords, rho, area, M_lumped)` |
| SUBROUTINE | `UF_Elem_B33P_Calc` | 565 | `SUBROUTINE UF_Elem_B33P_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
