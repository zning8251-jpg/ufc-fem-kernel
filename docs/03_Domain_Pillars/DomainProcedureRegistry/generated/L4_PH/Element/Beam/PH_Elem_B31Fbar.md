# `PH_Elem_B31Fbar.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31Fbar.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31Fbar`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31Fbar`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31Fbar`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31Fbar.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_Fbar_Desc_Type` (lines 28–47)

```fortran
TYPE :: B31_Fbar_Desc_Type
    ! F-bar control
    LOGICAL  :: fbar_active              ! F-bar method active
    LOGICAL  :: volumetric_coupling     ! Couple volumetric response
    REAL(wp) :: kappa                  ! Bulk modulus (for pressure computation)
    REAL(wp) :: J_limit                ! Jacobian limit for stability
    
    ! Section properties
    REAL(wp) :: A                      ! Cross-section area
    REAL(wp) :: Iy, Iz                ! Moments of inertia
    REAL(wp) :: J_tors                ! Torsional constant
    
    ! Material properties
    REAL(wp) :: E                      ! Young's modulus
    REAL(wp) :: nu                     ! Poisson's ratio
    REAL(wp) :: G                      ! Shear modulus
    
    ! Geometry
    REAL(wp) :: L                      ! Element length
END TYPE B31_Fbar_Desc_Type
```

### `B31_Fbar_State_Type` (lines 49–76)

```fortran
TYPE :: B31_Fbar_State_Type
    ! Configuration
    REAL(wp) :: coords_0(3, 2)          ! Initial coordinates
    REAL(wp) :: coords_t(3, 2)          ! Current coordinates
    
    ! Deformation measures
    REAL(wp) :: F_matrix(3, 3, 2)     ! Deformation gradient at nodes
    REAL(wp) :: F_dev(3, 3, 2)        ! Deviatoric part of F
    REAL(wp) :: J_det(2)               ! Jacobian det(F) at nodes
    
    ! F-bar strain measures
    REAL(wp) :: E_fbar_axial           ! F-bar axial strain
    REAL(wp) :: E_fbar_bend(2)        ! F-bar bending strain
    REAL(wp) :: gamma_fbar(2)          ! F-bar shear strain
    
    ! Stress measures
    REAL(wp) :: sigma_axial            ! Axial stress
    REAL(wp) :: sigma_bend(2)         ! Bending stress
    REAL(wp) :: tau_shear(2)           ! Shear stress
    REAL(wp) :: pressure               ! Hydrostatic pressure
    
    ! Volumetric response
    REAL(wp) :: p_vol                  ! Volumetric pressure
    REAL(wp) :: eps_vol                ! Volumetric strain
    
    ! Internal force
    REAL(wp) :: R_int(12)             ! Internal force vector
END TYPE B31_Fbar_State_Type
```

### `B31_Fbar_AlgoCtx_Type` (lines 78–100)

```fortran
TYPE :: B31_Fbar_AlgoCtx_Type
    ! Gauss integration
    INTEGER(i4) :: n_gauss
    REAL(wp) :: gauss_pts(3)
    REAL(wp) :: gauss_wts(3)
    
    ! Work arrays
    REAL(wp) :: B_fbar(6, 12)         ! F-bar strain-displacement matrix
    REAL(wp) :: D_fbar(6, 6)          ! F-bar constitutive matrix
    REAL(wp) :: D_dev(6, 6)           ! Deviatoric part of D
    REAL(wp) :: D_vol(6, 6)           ! Volumetric part of D
    REAL(wp) :: K_fbar(12, 12)        ! F-bar stiffness matrix
    
    ! Temporary matrices
    REAL(wp) :: temp33(3, 3)
    REAL(wp) :: F_avg(3, 3)           ! Average deformation gradient
    REAL(wp) :: C_dev(3, 3)           ! Deviatoric right Cauchy-Green
    REAL(wp) :: E_dev(3, 3)           ! Deviatoric Green-Lagrange
    
    ! Convergence
    INTEGER(i4) :: iteration
    LOGICAL  :: converged
END TYPE B31_Fbar_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_Fbar_Initialize` | 107 | `SUBROUTINE PH_Elem_B31_Fbar_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_DeformationGradient` | 181 | `SUBROUTINE PH_Elem_B31_Fbar_DeformationGradient(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_RodriguesFormula` | 287 | `SUBROUTINE PH_Elem_B31_Fbar_RodriguesFormula(v1, v2, R, status)` |
| SUBROUTINE | `PH_Elem_B31_Fbar_ComputeFbar` | 361 | `SUBROUTINE PH_Elem_B31_Fbar_ComputeFbar(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_Strain` | 432 | `SUBROUTINE PH_Elem_B31_Fbar_Strain(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_StressUpdate` | 508 | `SUBROUTINE PH_Elem_B31_Fbar_StressUpdate(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_ConstitutiveMatrix` | 597 | `SUBROUTINE PH_Elem_B31_Fbar_ConstitutiveMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_StiffnessMatrix` | 683 | `SUBROUTINE PH_Elem_B31_Fbar_StiffnessMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_Fbar_InternalForce` | 815 | `SUBROUTINE PH_Elem_B31_Fbar_InternalForce(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
