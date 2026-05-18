# `PH_Elem_BMtx.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_BMtx.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_BMtx`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_BMtx`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_BMtx`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_BMtx.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Shared_Args` (lines 35–71)

```fortran
  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ET_BMatrix_2D_Plane` | 76 | `SUBROUTINE ET_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `ET_BMatrix_3D_Continuum` | 84 | `SUBROUTINE ET_BMatrix_3D_Continuum(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `ET_BMatrix_Axisymmetric` | 92 | `SUBROUTINE ET_BMatrix_Axisymmetric(dN_dx, N, r, n_nodes, B, status)` |
| SUBROUTINE | `ET_BMatrix_Shell` | 100 | `SUBROUTINE ET_BMatrix_Shell(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `PH_El_BM_2D_Pl_Strain` | 108 | `SUBROUTINE PH_El_BM_2D_Pl_Strain(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `PH_El_BM_2D_Pl_Stress` | 119 | `SUBROUTINE PH_El_BM_2D_Pl_Stress(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `PH_Elem_BMatrix_2D_Plane` | 130 | `SUBROUTINE PH_Elem_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `PH_Elem_BMatrix_3D_Continuum` | 174 | `SUBROUTINE PH_Elem_BMatrix_3D_Continuum(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `PH_Elem_BMatrix_Axisymmetric` | 236 | `SUBROUTINE PH_Elem_BMatrix_Axisymmetric(dN_dx, N, r, n_nodes, B, status)` |
| SUBROUTINE | `PH_Elem_BMatrix_Derivative` | 300 | `SUBROUTINE PH_Elem_BMatrix_Derivative(dN_dx, d2N_dx2, n_nodes, dB_dx, status)` |
| SUBROUTINE | `PH_Elem_BMatrix_Shell` | 374 | `SUBROUTINE PH_Elem_BMatrix_Shell(dN_dx, n_nodes, B, status)` |
| SUBROUTINE | `PH_Elem_BMatrix_Shell_MITC` | 417 | `SUBROUTINE PH_Elem_BMatrix_Shell_MITC(dN_dx, N, n_nodes, B, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
