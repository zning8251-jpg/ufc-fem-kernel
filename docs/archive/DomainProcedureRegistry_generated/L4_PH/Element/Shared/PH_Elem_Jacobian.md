# `PH_Elem_Jacobian.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_Jacobian.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Jacobian`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Jacobian`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Jacobian`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_Jacobian.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_JacobianArgs` (lines 39–60)

```fortran
    TYPE :: PH_Elem_JacobianArgs
      ! ---- ----
      INTEGER(i4) :: dim     = 3_i4  !! 2 3
      INTEGER(i4) :: n_nodes = 0_i4  ! node count

      ! ---- POINTER ----
      REAL(wp), POINTER :: dN_dxi(:,:) => NULL()  !! (dim, n_nodes)
      REAL(wp), POINTER :: coords(:,:) => NULL()  !! (dim, n_nodes)

      ! ---- Jacobian ----
      REAL(wp) :: J_2D(2,2) = 0.0_wp    !! 2D Jacobian
      REAL(wp) :: J_3D(3,3) = 0.0_wp    !! 3D Jacobian
      REAL(wp) :: detJ      = 0.0_wp    !! Jacobian

      ! ---- Jacobian ----
      REAL(wp) :: J_inv_2D(2,2) = 0.0_wp  !! 2D Jacobian
      REAL(wp) :: J_inv_3D(3,3) = 0.0_wp  !! 3D Jacobian
      REAL(wp), POINTER :: dN_dx(:,:) => NULL()  !! (dim, n_nodes)

      ! ---- ----
      TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
    END TYPE PH_Elem_JacobianArgs
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ET_Jacobian_2D` | 71 | `SUBROUTINE ET_Jacobian_2D(dN_dxi, coords, n_nodes, J, detJ, status)` |
| SUBROUTINE | `ET_Jacobian_3D` | 123 | `SUBROUTINE ET_Jacobian_3D(dN_dxi, coords, n_nodes, J, detJ, status)` |
| FUNCTION | `ET_Jacobian_Det2D` | 178 | `FUNCTION ET_Jacobian_Det2D(J) RESULT(detJ)` |
| FUNCTION | `ET_Jacobian_Det3D` | 188 | `FUNCTION ET_Jacobian_Det3D(J) RESULT(detJ)` |
| SUBROUTINE | `ET_Jacobian_Inverse2D` | 202 | `SUBROUTINE ET_Jacobian_Inverse2D(J, detJ, J_inv, status)` |
| SUBROUTINE | `ET_Jacobian_Inverse3D` | 229 | `SUBROUTINE ET_Jacobian_Inverse3D(J, detJ, J_inv, status)` |
| SUBROUTINE | `ET_Jacobian_ShapeDerivatives` | 265 | `SUBROUTINE ET_Jacobian_ShapeDerivatives(dN_dxi, J_inv, dim, n_nodes, dN_dx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
