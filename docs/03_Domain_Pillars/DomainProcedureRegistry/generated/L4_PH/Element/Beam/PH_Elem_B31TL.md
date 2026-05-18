# `PH_Elem_B31TL.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31TL.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31TL`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31TL`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31TL`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31TL.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_TL_Desc_Type` (lines 34–52)

```fortran
TYPE :: B31_TL_Desc_Type
    ! Geometric description
    REAL(wp) :: L₀                    ! Initial length
    REAL(wp) :: A                     ! Cross-section area
    REAL(wp) :: Iy, Iz               ! Second moments of area
    REAL(wp) :: J_tors               ! Torsional constant
    REAL(wp) :: I_warp               ! Warping constant (B31OS)
    
    ! Material properties (reference config)
    REAL(wp) :: E                     ! Young's modulus
    REAL(wp) :: nu                    ! Poisson's ratio
    REAL(wp) :: G                     ! Shear modulus E/(2(1+ν))
    REAL(wp) :: rho₀                  ! Reference density
    
    ! NL parameters
    INTEGER(i4) :: formulation_type     ! 0=linear, 1=UL, 2=TL
    LOGICAL  :: large_rotation       ! Flag for large rotation analysis
    LOGICAL  :: shear_deformable     ! Timoshenko vs Euler-Bernoulli
END TYPE B31_TL_Desc_Type
```

### `B31_TL_State_Type` (lines 54–84)

```fortran
TYPE :: B31_TL_State_Type
    ! Reference configuration variables
    REAL(wp) :: coords₀(3, 2)        ! Initial nodal coordinates [x₁,y₁,z₁; x₂,y₂,z₂]
    REAL(wp) :: disp₀(6, 2)          ! Previous step displacements (for UL compatibility)
    
    ! Current configuration variables
    REAL(wp) :: coordsₜ(3, 2)        ! Current nodal coordinates
    REAL(wp) :: dispₜ(6, 2)          ! Current displacements
    REAL(wp) :: rotₜ(3, 2)           ! Current rotations
    
    ! Strain measures (Green-Lagrange for TL)
    REAL(wp) :: E_axial              ! Axial strain E₁₁
    REAL(wp) :: E_bend_y(2)          ! Bending strain about y-axis (at nodes)
    REAL(wp) :: E_bend_z(2)          ! Bending strain about z-axis (at nodes)
    REAL(wp) :: gamma_xy(2)          ! Shear strain γ₁₂
    REAL(wp) :: gamma_xz(2)          ! Shear strain γ₁₃
    
    ! Stress measures (PK2 for TL)
    REAL(wp) :: S_axial              ! Axial PK2 stress
    REAL(wp) :: S_bend_y(2)          ! Bending PK2 stress
    REAL(wp) :: S_bend_z(2)          ! Bending PK2 stress
    REAL(wp) :: tau_xy(2)            ! Shear PK2 stress
    
    ! Internal force vector
    REAL(wp) :: R_int(12)            ! Internal force vector (12 DOF)
    
    ! Configuration metrics
    REAL(wp) :: Lₜ                    ! Current length
    REAL(wp) :: J_det                 ! Jacobian determinant
    REAL(wp) :: theta_total(2)       ! Total rotation angles at nodes
END TYPE B31_TL_State_Type
```

### `B31_TL_Algo_Type` (lines 86–101)

```fortran
TYPE :: B31_TL_Algo_Type
    ! Integration parameters
    INTEGER(i4) :: n_gauss_axial        ! Gauss points in axial direction
    INTEGER(i4) :: n_gauss_shear        ! Gauss points in shear direction
    REAL(wp) :: gauss_pts(3)         ! Gauss point locations
    REAL(wp) :: gauss_wts(3)         ! Gauss point weights
    
    ! Newton-Raphson parameters
    INTEGER(i4) :: max_iterations
    REAL(wp) :: tolerance_force
    REAL(wp) :: tolerance_disp
    
    ! Solution method
    INTEGER(i4) :: solution_method       ! 1=full Newton, 2=modified Newton
    LOGICAL  :: adaptive_load         ! Adaptive load stepping
END TYPE B31_TL_Algo_Type
```

### `B31_TL_Ctx_Type` (lines 103–127)

```fortran
TYPE :: B31_TL_Ctx_Type
    ! Temporary work arrays
    REAL(wp) :: B_linear(6, 12)       ! Linear strain-displacement matrix
    REAL(wp) :: B_NL(6, 12, 12)      ! Nonlinear strain-displacement matrix
    REAL(wp) :: D_mat(6, 6)           ! Constitutive matrix
    REAL(wp) :: K_L(12, 12)          ! Linear stiffness matrix
    REAL(wp) :: K_NL(12, 12)         ! Nonlinear (geometric) stiffness
    REAL(wp) :: K_total(12, 12)      ! Total stiffness matrix
    REAL(wp) :: G_matrix(6, 12, 12)  ! Geometric stiffness matrix
    REAL(wp) :: F_deform(3, 3)       ! Deformation gradient
    
    ! Coordinate transformations
    REAL(wp) :: T_local(6, 6)       ! Local transformation matrix
    REAL(wp) :: Q_rotation(3, 3)     ! Rotation tensor
    
    ! Work vectors
    REAL(wp) :: strain_inc(6)        ! Strain increment
    REAL(wp) :: stress_inc(6)        ! Stress increment
    REAL(wp) :: dU(12)               ! Displacement increment
    REAL(wp) :: dR(12)               ! Force residual
    
    ! Metrics
    REAL(wp) :: axial_strain_ref      ! Reference axial strain for current step
    LOGICAL  :: is_converged         ! Convergence flag
END TYPE B31_TL_Ctx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_TL_Initialize` | 136 | `SUBROUTINE PH_Elem_B31_TL_Initialize(desc, state, algo, status)` |
| SUBROUTINE | `PH_Elem_B31_TL_StiffnessMatrix` | 188 | `SUBROUTINE PH_Elem_B31_TL_StiffnessMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_TL_InternalForce` | 371 | `SUBROUTINE PH_Elem_B31_TL_InternalForce(&` |
| SUBROUTINE | `PH_Elem_B31_TL_StressUpdate` | 468 | `SUBROUTINE PH_Elem_B31_TL_StressUpdate(&` |
| SUBROUTINE | `PH_Elem_B31_TL_ConfigurationUpdate` | 554 | `SUBROUTINE PH_Elem_B31_TL_ConfigurationUpdate(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
