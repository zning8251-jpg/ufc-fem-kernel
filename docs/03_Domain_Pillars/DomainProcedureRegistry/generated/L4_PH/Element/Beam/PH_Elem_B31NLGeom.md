# `PH_Elem_B31NLGeom.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31NLGeom.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31NLGeom`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31NLGeom`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31NLGeom`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31NLGeom.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_NL_Geom_Desc_Type` (lines 29–48)

```fortran
TYPE :: B31_NL_Geom_Desc_Type
  ! Material properties
  REAL(wp) :: E                     ! Young's modulus
  REAL(wp) :: nu                    ! Poisson's ratio
  REAL(wp) :: G                     ! Shear modulus
  
  ! Section properties
  REAL(wp) :: A                     ! Cross-section area
  REAL(wp) :: Iy, Iz               ! Moments of inertia
  REAL(wp) :: J_tors               ! Torsional constant
  
  ! Geometry
  REAL(wp) :: L₀                    ! Initial length
  REAL(wp) :: n_vec(3)              ! Initial axis direction
  
  ! Nonlinear control
  LOGICAL  :: nlgeom_active         ! Large deformation flag
  INTEGER(i4) :: stress_measure        ! 1=PK2, 2=Cauchy, 3=Biot
  REAL(wp) :: tol_energy            ! Energy tolerance for check
END TYPE B31_NL_Geom_Desc_Type
```

### `B31_NL_Geom_State_Type` (lines 50–80)

```fortran
TYPE :: B31_NL_Geom_State_Type
  ! Configuration
  REAL(wp) :: coords₀(3, 2)         ! Initial coordinates
  REAL(wp) :: coordsₜ(3, 2)         ! Current coordinates
  REAL(wp) :: disp₁₂(12)            ! Nodal displacements
  
  ! Rotation measures
  REAL(wp) :: R_matrix(3, 3, 2)     ! Nodal rotation matrices
  REAL(wp) :: theta_vec(3, 2)       ! Finite rotation vectors
  REAL(wp) :: co_rot_matrix(3, 3)   ! Co-rotational frame
  
  ! Strain measures (Green-Lagrange)
  REAL(wp) :: E_axial               ! Axial strain (finite)
  REAL(wp) :: kappa_y(2), kappa_z(2) ! Curvatures at nodes
  REAL(wp) :: gamma_shear(2)        ! Shear strain
  
  ! Stress measures (2nd Piola-Kirchhoff)
  REAL(wp) :: S_axial               ! Axial PK2 stress
  REAL(wp) :: M_y(2), M_z(2)        ! Bending moments
  REAL(wp) :: T_tors                ! Torque
  
  ! Internal variables
  REAL(wp) :: int_force(12)         ! Internal force vector
  REAL(wp) :: tangent_stiff(12, 12) ! Tangent stiffness matrix
  REAL(wp) :: geo_stiff(12, 12)     ! Geometric stiffness
  
  ! Energy quantities
  REAL(wp) :: strain_energy         ! Total strain energy
  REAL(wp) :: work_done             ! External work
  REAL(wp) :: kinetic_energy        ! Kinetic energy (for dynamics)
END TYPE B31_NL_Geom_State_Type
```

### `B31_NL_Geom_AlgoCtx_Type` (lines 82–104)

```fortran
TYPE :: B31_NL_Geom_AlgoCtx_Type
  ! Integration
  INTEGER(i4) :: n_gauss
  REAL(wp) :: gauss_pts(3)
  REAL(wp) :: gauss_wts(3)
  
  ! Work arrays
  REAL(wp) :: B_linear(6, 12)       ! Linear strain-displacement
  REAL(wp) :: B_nl(6, 12)           ! Nonlinear B matrix
  REAL(wp) :: G_matrix(3, 12)       ! Geometric stiffness operator
  REAL(wp) :: D_mat(6, 6)           ! Constitutive matrix
  
  ! Temporary matrices
  REAL(wp) :: temp33(3, 3)
  REAL(wp) :: R_avg(3, 3)           ! Average rotation
  REAL(wp) :: F_def(3, 3)           ! Deformation gradient (pure)
  REAL(wp) :: U_stretch(3, 3)       ! Stretch tensor
  
  ! Convergence
  INTEGER(i4) :: nr_iteration
  LOGICAL  :: converged
  REAL(wp) :: energy_norm
END TYPE B31_NL_Geom_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_NL_Initialize` | 111 | `SUBROUTINE PH_Elem_B31_NL_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_NL_CorotationalFrame` | 183 | `SUBROUTINE PH_Elem_B31_NL_CorotationalFrame(&` |
| FUNCTION | `CROSS_PRODUCT` | 311 | `FUNCTION CROSS_PRODUCT(a, b) RESULT(c)` |
| SUBROUTINE | `PH_Elem_B31_NL_GreenLagrangeStrain` | 332 | `SUBROUTINE PH_Elem_B31_NL_GreenLagrangeStrain(&` |
| SUBROUTINE | `PH_Elem_B31_NL_GeometricStiffness` | 411 | `SUBROUTINE PH_Elem_B31_NL_GeometricStiffness(&` |
| SUBROUTINE | `PH_Elem_B31_NL_TangentStiffness` | 502 | `SUBROUTINE PH_Elem_B31_NL_TangentStiffness(&` |
| SUBROUTINE | `PH_Elem_B31_NL_InternalForce` | 541 | `SUBROUTINE PH_Elem_B31_NL_InternalForce(&` |
| SUBROUTINE | `PH_Elem_B31_NL_RotationUpdate` | 601 | `SUBROUTINE PH_Elem_B31_NL_RotationUpdate(&` |
| SUBROUTINE | `PH_Elem_B31_NL_EnergyCheck` | 670 | `SUBROUTINE PH_Elem_B31_NL_EnergyCheck(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
