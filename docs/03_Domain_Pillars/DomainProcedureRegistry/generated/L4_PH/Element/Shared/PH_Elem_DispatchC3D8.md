# `PH_Elem_DispatchC3D8.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_DispatchC3D8.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_DispatchC3D8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_DispatchC3D8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_DispatchC3D8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_DispatchC3D8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_C3D8_Data` (lines 34–43)

```fortran
  TYPE :: PH_Elem_C3D8_Data
    INTEGER(i4) :: elem_id
    INTEGER(i4) :: n_nodes = 8
    INTEGER(i4) :: n_dofs_per_node = 3
    REAL(wp) :: coords(8, 3)  ! Node coordinates
    REAL(wp) :: material_props(10)  ! Mat properties
    REAL(wp) :: section_props(5)    ! Section properties
    LOGICAL :: nl_geom = .FALSE.
    LOGICAL :: thermal_coupling = .FALSE.
  END TYPE PH_Elem_C3D8_Data
```

### `PH_Elem_C3D8_Output_Data` (lines 45–51)

```fortran
  TYPE :: PH_Elem_C3D8_Output_Data
    INTEGER(i4) :: n_output_points = 8
    REAL(wp) :: stresses(8, 6)     ! S11, S22, S33, S12, S13, S23
    REAL(wp) :: strains(8, 6)     ! E11, E22, E33, E12, E13, E23
    REAL(wp) :: displacements(24)  ! Nodal displacements
    REAL(wp) :: forces(24)         ! Nodal forces
  END TYPE PH_Elem_C3D8_Output_Data
```

### `PH_Elem_Shared_Args` (lines 57–93)

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
| SUBROUTINE | `PH_El_C3_ApplyConstraints` | 98 | `SUBROUTINE PH_El_C3_ApplyConstraints(elem_data, bc_nodes, bc_dofs, bc_values, Ke_reduced)` |
| SUBROUTINE | `PH_El_C3_AssembleForceVector` | 110 | `SUBROUTINE PH_El_C3_AssembleForceVector(elem_data, u, R_int)` |
| SUBROUTINE | `PH_El_C3_FormCoupledStiffMat` | 120 | `SUBROUTINE PH_El_C3_FormCoupledStiffMat(elem_data, D_mech, D_thermal, alpha, Ke_coupled)` |
| SUBROUTINE | `PH_Elem_C3D8_ApplyContact` | 131 | `SUBROUTINE PH_Elem_C3D8_ApplyContact(elem_data, contact_surf, penalty, K_contact)` |
| SUBROUTINE | `PH_Elem_C3D8_FormStiffMatrix` | 142 | `SUBROUTINE PH_Elem_C3D8_FormStiffMatrix(elem_data, D_matrix, Ke)` |
| SUBROUTINE | `PH_Elem_C3D8_GenerateOutput` | 152 | `SUBROUTINE PH_Elem_C3D8_GenerateOutput(elem_data, u, output_data)` |
| SUBROUTINE | `PH_Elem_C3D8_ProcessSection` | 162 | `SUBROUTINE PH_Elem_C3D8_ProcessSection(elem_data, Ke_section)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
