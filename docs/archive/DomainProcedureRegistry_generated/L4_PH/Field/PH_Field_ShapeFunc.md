# `PH_Field_ShapeFunc.f90`

- **Source**: `L4_PH/Field/PH_Field_ShapeFunc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Field_ShapeFunc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_ShapeFunc`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field_ShapeFunc`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_ShapeFunc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Field_ShapeFunc_Arg` (lines 40–44)

```fortran
  TYPE, PUBLIC :: PH_Field_ShapeFunc_Arg
    REAL(wp), ALLOCATABLE :: N(:)        ! [OUT] Shape functions [npe]
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:) ! [OUT] dN/dxi [3, npe]
    TYPE(ErrorStatusType) :: status     ! [OUT]
  END TYPE PH_Field_ShapeFunc_Arg
```

### `PH_Field_Gradient_Arg` (lines 47–51)

```fortran
  TYPE, PUBLIC :: PH_Field_Gradient_Arg
    REAL(wp), ALLOCATABLE :: dN_dx(:,:) ! [OUT] dN/dx [3, npe]
    REAL(wp) :: detJ = 0.0_wp           ! [OUT] Jacobian determinant
    TYPE(ErrorStatusType) :: status     ! [OUT]
  END TYPE PH_Field_Gradient_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Field_GetShapeFunctions` | 67 | `SUBROUTINE PH_Field_GetShapeFunctions(elem_type, xi, eta, zeta, npe, arg)` |
| SUBROUTINE | `PH_Field_GetShapeFunctionGradient` | 103 | `SUBROUTINE PH_Field_GetShapeFunctionGradient(coords, xi, eta, zeta, npe, arg)` |
| SUBROUTINE | `PH_Field_ComputeJacobian` | 171 | `SUBROUTINE PH_Field_ComputeJacobian(coords, dN_dxi, npe, J, detJ, status)` |
| SUBROUTINE | `PH_Field_ShapeFunc_C3D8` | 235 | `SUBROUTINE PH_Field_ShapeFunc_C3D8(xi, eta, zeta, N, dN_dxi, status)` |
| SUBROUTINE | `PH_Field_InverseJacobian3D` | 264 | `SUBROUTINE PH_Field_InverseJacobian3D(J, detJ, J_inv, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
