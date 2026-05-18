# `PH_Elem_Acoustic_Def.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_Acoustic_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Acoustic_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Acoustic_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Acoustic`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_Acoustic_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Acoustic_Args` (lines 60–96)

```fortran
  TYPE :: PH_Elem_Acoustic_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! [IN]  nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! [IN]  DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! [IN]  integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! [IN]  load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! [IN]  constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! [IN]  face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! [IN]  local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! [IN]  parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp  ! [IN]  parametric coordinate eta
  REAL(wp)              :: zeta        = 0.0_wp  ! [IN]  parametric coordinate zeta
  REAL(wp)              :: detJ        = 0.0_wp ! [INOUT] Jacobian determinant
  REAL(wp)              :: penalty     = 0.0_wp  ! [IN]  penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! [IN]  prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! [IN]  grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! [IN]  grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! [IN]  grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! [IN]  nodal coordinates (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! [IN]  element displacement vector
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! [IN]  material stiffness (elasticity) matrix
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! [OUT] element stiffness matrix
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! [OUT] equivalent nodal force
  REAL(wp), POINTER     :: N(:)        => NULL()  ! [OUT] shape-function matrix
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! [OUT] shape-function spatial derivatives
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! [OUT] strain-displacement operator
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! [OUT] geometric stiffness contribution
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! [OUT] internal residual
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! [OUT] IP stress pack
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! [OUT] IP strain pack
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! [OUT] IP equivalent plastic strain
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! [OUT] output variable mask / ids
  END TYPE PH_Elem_Acoustic_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Elem_Acoustic_Calc` | 120 | `SUBROUTINE UF_Elem_Acoustic_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UPPER_CASE` | 260 | `SUBROUTINE UPPER_CASE(str)` |
| SUBROUTINE | `PH_Elem_Acoustic_Material_Update_Routed` | 270 | `SUBROUTINE PH_Elem_Acoustic_Material_Update_Routed(rt_ctx, mat_slot, density, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
