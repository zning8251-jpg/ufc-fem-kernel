# `PH_Elem_Porous.f90`

- **Source**: `L4_PH/Element/Porous/PH_Elem_Porous.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Porous`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Porous`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Porous`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Porous`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Porous/PH_Elem_Porous.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Porous_Args` (lines 42–86)

```fortran
  TYPE :: PH_Elem_Porous_Args
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
  REAL(wp)              :: k_hyd       = 0.0_wp  ! hydraulic permeability scale
  REAL(wp)              :: alpha_b     = 1.0_wp ! Biot
  REAL(wp), POINTER     :: u_struct(:) => NULL()  ! packed structural displacement ptr
  REAL(wp), POINTER     :: p_pore(:)   => NULL()  ! nodal pore pressure ptr
  REAL(wp), POINTER     :: Kuu(:,:)    => NULL()  ! displacement-displacement block ptr
  REAL(wp), POINTER     :: Kpp(:,:)    => NULL()  ! pressure-pressure block ptr
  REAL(wp), POINTER     :: Kup(:,:)    => NULL()  ! displacement-pressure coupling block ptr
  REAL(wp), POINTER     :: ip_pore(:)  => NULL()  ! IP pore pressure ptr
  END TYPE PH_Elem_Porous_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Elem_Porous_Calc` | 95 | `SUBROUTINE UF_Elem_Porous_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UPPER_CASE` | 136 | `SUBROUTINE UPPER_CASE(str)` |
| SUBROUTINE | `PH_Elem_Porous_Material_Update_TwoPhase_Routed` | 146 | `SUBROUTINE PH_Elem_Porous_Material_Update_TwoPhase_Routed(rt_ctx, mat_slot, &` |
| SUBROUTINE | `Calc_Pore_Saturated` | 175 | `subroutine Calc_Pore_Saturated(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PoreSat_IpCoeffs` | 277 | `subroutine PoreSat_IpCoeffs(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)` |
| SUBROUTINE | `Calc_Pore_TwoPhase` | 299 | `subroutine Calc_Pore_TwoPhase(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PoreTwo_IpCoeffs` | 447 | `subroutine PoreTwo_IpCoeffs(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)` |
| SUBROUTINE | `eval_saturation_and_kr` | 473 | `subroutine eval_saturation_and_kr(p, intModel, alpha_vg, n_vg, m_vg, l_mualem, &` |
| SUBROUTINE | `UF_Init_Pore_Saturated` | 544 | `subroutine UF_Init_Pore_Saturated(Element, name)` |
| SUBROUTINE | `UF_Init_Pore_TwoPhase` | 563 | `subroutine UF_Init_Pore_TwoPhase(Element, name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
