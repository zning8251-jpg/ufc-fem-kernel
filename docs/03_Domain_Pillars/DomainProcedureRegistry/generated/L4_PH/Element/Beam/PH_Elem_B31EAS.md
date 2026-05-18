# `PH_Elem_B31EAS.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31EAS.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31EAS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31EAS`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31EAS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31EAS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_EAS_Desc_Type` (lines 36–56)

```fortran
TYPE :: B31_EAS_Desc_Type
    ! EAS control
    LOGICAL  :: eas_active             ! EAS method active
    INTEGER(i4) :: n_alpha               ! Number of enhanced parameters
    INTEGER(i4) :: alpha_types(3)         ! Type of enhancement per parameter
    
    ! Section properties
    REAL(wp) :: A                      ! Cross-section area
    REAL(wp) :: Iy, Iz                ! Moments of inertia
    REAL(wp) :: J_tors                ! Torsional constant
    REAL(wp) :: S_shear_y, S_shear_z  ! Shear areas
    
    ! Material properties
    REAL(wp) :: E                      ! Young's modulus
    REAL(wp) :: nu                     ! Poisson's ratio
    REAL(wp) :: G                      ! Shear modulus
    
    ! Geometry
    REAL(wp) :: L                      ! Element length
    REAL(wp) :: thickness_ratio        ! L/h ratio for locking detection
END TYPE B31_EAS_Desc_Type
```

### `B31_EAS_State_Type` (lines 58–79)

```fortran
TYPE :: B31_EAS_State_Type
    ! Configuration
    REAL(wp) :: coords(3, 2)          ! Nodal coordinates
    REAL(wp) :: disp(12)              ! Nodal displacements
    
    ! Standard strains
    REAL(wp) :: eps_std(6)            ! Standard strain components
    REAL(wp) :: kappa_std(2)         ! Standard curvatures
    
    ! Enhanced strains
    REAL(wp) :: eps_enh(6)            ! Enhanced strain components
    REAL(wp) :: kappa_enh(2)         ! Enhanced curvatures
    
    ! Enhanced parameters
    REAL(wp) :: alpha(N_ALPHA_TOTAL) ! Internal enhanced parameters
    
    ! Stresses (from enhanced strains)
    REAL(wp) :: sigma(6)              ! Stress components
    
    ! Internal force
    REAL(wp) :: R_int(12)             ! Internal force vector
END TYPE B31_EAS_State_Type
```

### `B31_EAS_AlgoCtx_Type` (lines 81–113)

```fortran
TYPE :: B31_EAS_AlgoCtx_Type
    ! Gauss integration
    INTEGER(i4) :: n_gauss
    REAL(wp) :: gauss_pts(3)
    REAL(wp) :: gauss_wts(3)
    
    ! Enhanced strain matrix M (maps α to strain)
    REAL(wp) :: M_matrix(6, N_ALPHA_TOTAL)
    
    ! Standard B matrix (strain-displacement)
    REAL(wp) :: B_std(6, 12)
    
    ! Condensation matrices
    REAL(wp) :: K_UU(12, 12)         ! Standard part of stiffness
    REAL(wp) :: K_Ualpha(12, N_ALPHA_TOTAL)
    REAL(wp) :: K_alphaU(N_ALPHA_TOTAL, 12)
    REAL(wp) :: K_alpha(N_ALPHA_TOTAL, N_ALPHA_TOTAL)
    
    ! Enhanced stiffness (after condensation)
    REAL(wp) :: K_eff(12, 12)
    
    ! Constitutive matrix
    REAL(wp) :: D_mat(6, 6)
    
    ! Work arrays
    REAL(wp) :: temp12(12)
    REAL(wp) :: temp6(6)
    REAL(wp) :: temp33(N_ALPHA_TOTAL, N_ALPHA_TOTAL)
    
    ! Convergence
    INTEGER(i4) :: iteration
    LOGICAL  :: converged
END TYPE B31_EAS_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_EAS_Initialize` | 120 | `SUBROUTINE PH_Elem_B31_EAS_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_EAS_BuildMMatrix` | 221 | `SUBROUTINE PH_Elem_B31_EAS_BuildMMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_EAS_BuildDMatrix` | 262 | `SUBROUTINE PH_Elem_B31_EAS_BuildDMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_EAS_EnhancedStrain` | 314 | `SUBROUTINE PH_Elem_B31_EAS_EnhancedStrain(&` |
| SUBROUTINE | `PH_Elem_B31_EAS_ComputeAlpha` | 430 | `SUBROUTINE PH_Elem_B31_EAS_ComputeAlpha(&` |
| SUBROUTINE | `L2_SolveLinearSystem` | 598 | `SUBROUTINE L2_SolveLinearSystem(A, b, x, n, singular, status)` |
| SUBROUTINE | `PH_Elem_B31_EAS_Condensation` | 669 | `SUBROUTINE PH_Elem_B31_EAS_Condensation(&` |
| SUBROUTINE | `L2_InvertMatrix` | 747 | `SUBROUTINE L2_InvertMatrix(A, A_inv, n, singular, status)` |
| SUBROUTINE | `PH_Elem_B31_EAS_StiffnessMatrix` | 823 | `SUBROUTINE PH_Elem_B31_EAS_StiffnessMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_EAS_InternalForce` | 930 | `SUBROUTINE PH_Elem_B31_EAS_InternalForce(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
