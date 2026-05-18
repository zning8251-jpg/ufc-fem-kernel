# `PH_Elem_B31UL.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31UL.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B31UL`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31UL`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31UL`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31UL.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_UL_Desc_Type` (lines 34–60)

```fortran
TYPE :: B31_UL_Desc_Type
    ! Geometric description
    REAL(wp) :: L₀                    ! Initial length (at t=0)
    REAL(wp) :: L_t                   ! Length at start of current step (t)
    REAL(wp) :: L_tdt                 ! Length at end of step (t+dt)
    REAL(wp) :: A                     ! Cross-section area
    REAL(wp) :: Iy, Iz               ! Second moments of area
    REAL(wp) :: J_tors               ! Torsional constant
    REAL(wp) :: I_warp               ! Warping constant (B31OS)
    
    ! Material properties
    REAL(wp) :: E                     ! Young's modulus
    REAL(wp) :: nu                    ! Poisson's ratio
    REAL(wp) :: G                     ! Shear modulus
    REAL(wp) :: rho                   ! Current density
    
    ! UL parameters
    INTEGER(i4) :: formulation_type     ! 2=UL (must be 2)
    LOGICAL  :: large_rotation       ! Large rotation analysis
    LOGICAL  :: large_strain        ! Large strain analysis
    LOGICAL  :: shear_deformable     ! Timoshenko beam
    LOGICAL  :: warping_active       ! B31OS warping DOF
    
    ! ADINAM compatibility
    REAL(wp) :: EPS1                 ! Previous step axial strain
    REAL(wp) :: EPS                  ! Current step axial strain
END TYPE B31_UL_Desc_Type
```

### `B31_UL_State_Type` (lines 62–93)

```fortran
TYPE :: B31_UL_State_Type
    ! Configuration at t (start of step)
    REAL(wp) :: coords_t(3, 2)       ! Nodal coords at time t
    REAL(wp) :: disp_t(6, 2)         ! Displacements at time t
    REAL(wp) :: rot_t(3, 2)          ! Rotations at time t
    
    ! Configuration at t+dt (end of step)
    REAL(wp) :: coords_tdt(3, 2)    ! Nodal coords at time t+dt
    REAL(wp) :: disp_tdt(6, 2)      ! Displacements at time t+dt
    REAL(wp) :: rot_tdt(3, 2)       ! Rotations at time t+dt
    
    ! Strain measures (Almansi strain for UL)
    REAL(wp) :: eps_axial            ! Axial strain ε₁₁
    REAL(wp) :: eps_bend_y(2)        ! Bending strain at nodes
    REAL(wp) :: eps_bend_z(2)        ! Bending strain at nodes
    REAL(wp) :: gamma_xy(2)          ! Shear strain γ₁₂
    REAL(wp) :: gamma_xz(2)          ! Shear strain γ₁₃
    
    ! Stress measures (Cauchy stress for UL)
    REAL(wp) :: sigma_axial          ! Axial Cauchy stress σ₁₁
    REAL(wp) :: sigma_bend_y(2)      ! Bending Cauchy stress
    REAL(wp) :: sigma_bend_z(2)      ! Bending Cauchy stress
    REAL(wp) :: tau_xy(2)            ! Shear Cauchy stress
    
    ! Internal force vector
    REAL(wp) :: R_int(12)            ! Internal force vector (12 DOF)
    
    ! Configuration metrics
    REAL(wp) :: XLN                   ! Current length (XLN in ADINAM)
    REAL(wp) :: XLT                   ! Previous length (XLT in ADINAM)
    REAL(wp) :: theta_inc(2)          ! Incremental rotation angles
END TYPE B31_UL_State_Type
```

### `B31_UL_Algo_Type` (lines 95–122)

```fortran
TYPE :: B31_UL_Algo_Type
    ! Integration parameters
    INTEGER(i4) :: n_gauss_axial        ! Gauss points in axial direction
    INTEGER(i4) :: n_gauss_shear        ! Gauss points in shear direction
    REAL(wp) :: gauss_pts(3)         ! Gauss point locations
    REAL(wp) :: gauss_wts(3)         ! Gauss point weights
    
    ! Gauss-Lobatto points (for ADINAM compatibility)
    REAL(wp) :: lobatto_pts(3)
    REAL(wp) :: lobatto_wts(3)
    
    ! Newton-Raphson parameters
    INTEGER(i4) :: max_iterations
    REAL(wp) :: tolerance_force
    REAL(wp) :: tolerance_disp
    INTEGER(i4) :: iteration_count       ! Current iteration count (ICOUNT in ADINAM)
    
    ! Solution method
    INTEGER(i4) :: solution_method       ! 1=full N-R, 2=modified N-R
    LOGICAL  :: adaptive_load
    INTEGER(i4) :: IREF                  ! Reference load flag (ADINAM)
    
    ! ADINAM compatibility
    INTEGER(i4) :: NST                    ! Storage per integration point
    INTEGER(i4) :: IB                     ! Stiffness matrix dimension
    INTEGER(i4) :: ITYPB                 ! Beam type: 0=2D, 1=3D
    INTEGER(i4) :: ISHEAR                ! Shear flag: 0=none, 1=Timoshenko
END TYPE B31_UL_Algo_Type
```

### `B31_UL_Ctx_Type` (lines 124–159)

```fortran
TYPE :: B31_UL_Ctx_Type
    ! Shape function matrices
    REAL(wp) :: B_mat(6, 16)         ! Linear strain-displacement (ADINAM B)
    REAL(wp) :: BNL1_mat(3, 16)      ! Nonlinear strain matrix (ADINAM BNL1)
    REAL(wp) :: BNL2_mat(2, 16)      ! Nonlinear strain matrix (ADINAM BNL2)
    REAL(wp) :: BNL3_mat(2, 16)      ! Nonlinear strain matrix (ADINAM BNL3)
    
    ! Constitutive matrix
    REAL(wp) :: D_mat(6, 6)          ! Material constitutive matrix
    
    ! Stiffness matrices
    REAL(wp) :: K_L(16, 16)          ! Linear stiffness
    REAL(wp) :: K_NL(16, 16)         ! Nonlinear (geometric) stiffness
    REAL(wp) :: K_total(16, 16)      ! Total stiffness
    REAL(wp) :: K_geom(16, 16)      ! Geometric stiffness from stress
    
    ! Work arrays
    REAL(wp) :: CBM(6, 16)           ! C · B product
    REAL(wp) :: SIG(3)               ! Stress vector [σ_r, τ_rs, τ_rt]
    REAL(wp) :: STRN(3)              ! Strain vector
    REAL(wp) :: EPSP(3)               ! Plastic strain (for elasto-plastic)
    
    ! Coordinate arrays
    REAL(wp) :: XOL, YOL, ZOL         ! Integration point local coords
    REAL(wp) :: XLT3, YOL2, ZOL2     ! Coordinate powers
    REAL(wp) :: YOL3, ZOL3
    
    ! Work vectors
    REAL(wp) :: du(12)                ! Displacement increment
    REAL(wp) :: dR(12)                ! Force residual
    REAL(wp) :: RE_vec(16)           ! Internal force vector
    
    ! Metrics
    LOGICAL  :: is_converged
    INTEGER(i4) :: integration_point
END TYPE B31_UL_Ctx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_UL_Initialize` | 166 | `SUBROUTINE PH_Elem_B31_UL_Initialize(desc, state, algo, status)` |
| SUBROUTINE | `PH_Elem_B31_UL_DeformationUpdate` | 231 | `SUBROUTINE PH_Elem_B31_UL_DeformationUpdate(&` |
| SUBROUTINE | `PH_Elem_B31_UL_ShapeFunctions` | 311 | `SUBROUTINE PH_Elem_B31_UL_ShapeFunctions(&` |
| SUBROUTINE | `PH_Elem_B31_UL_StiffnessMatrix` | 434 | `SUBROUTINE PH_Elem_B31_UL_StiffnessMatrix(&` |
| SUBROUTINE | `PH_Elem_B31_UL_InternalForce` | 556 | `SUBROUTINE PH_Elem_B31_UL_InternalForce(&` |
| SUBROUTINE | `PH_Elem_B31_UL_StressUpdate` | 650 | `SUBROUTINE PH_Elem_B31_UL_StressUpdate(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
