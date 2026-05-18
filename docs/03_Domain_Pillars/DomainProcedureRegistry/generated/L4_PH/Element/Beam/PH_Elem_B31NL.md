# `PH_Elem_B31NL.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31NL.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31NL`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31NL`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31NL`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31NL.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_NL_Config_Type` (lines 45–73)

```fortran
TYPE :: B31_NL_Config_Type
    ! Formulation control
    INTEGER(i4) :: formulation             ! 0=linear, 2=UL, 3=TL
    LOGICAL  :: large_rotation          ! Large rotation analysis
    LOGICAL  :: large_strain           ! Large strain analysis
    LOGICAL  :: shear_deformable        ! Timoshenko beam
    LOGICAL  :: warping_active          ! B31OS warping DOF
    
    ! Element configuration
    INTEGER(i4) :: n_nodes                ! Number of nodes (2 for B31)
    INTEGER(i4) :: n_dof_per_node          ! DOF per node (6 for 3D beam)
    INTEGER(i4) :: total_dof               ! Total element DOF
    
    ! Section properties
    REAL(wp) :: A                       ! Area
    REAL(wp) :: Iy, Iz                  ! Moments of inertia
    REAL(wp) :: J_tors                  ! Torsional constant
    REAL(wp) :: I_warp                  ! Warping constant
    
    ! Material properties
    REAL(wp) :: E                       ! Young's modulus
    REAL(wp) :: nu                      ! Poisson's ratio
    REAL(wp) :: G                       ! Shear modulus
    
    ! Geometry
    REAL(wp) :: L_initial               ! Initial length
    REAL(wp) :: L_current               ! Current length
    REAL(wp) :: orientation(3)           ! Beam axis orientation
END TYPE B31_NL_Config_Type
```

### `B31_NL_State_Type` (lines 75–98)

```fortran
TYPE :: B31_NL_State_Type
    ! Displacement fields
    REAL(wp) :: disp_history(12, 2)     ! Displacement history [current, previous]
    REAL(wp) :: rot_history(12, 2)      ! Rotation history
    
    ! Strain measures
    REAL(wp) :: eps_axial               ! Axial strain
    REAL(wp) :: eps_bend(2)            ! Bending strains
    REAL(wp) :: gamma_shear(2)         ! Shear strains
    
    ! Stress measures
    REAL(wp) :: sigma_axial             ! Axial stress
    REAL(wp) :: sigma_bend(2)          ! Bending stresses
    REAL(wp) :: tau_shear(2)           ! Shear stresses
    
    ! Internal force
    REAL(wp) :: R_int(12)              ! Internal force vector
    
    ! Configuration metrics
    REAL(wp) :: current_length
    REAL(wp) :: axial_strain_ref       ! Reference strain for step
    REAL(wp) :: total_rotation(2)      ! Total rotation at nodes
    REAL(wp) :: incremental_rotation(2)! Incremental rotation
END TYPE B31_NL_State_Type
```

### `B31_NL_AlgoCtx_Type` (lines 100–140)

```fortran
TYPE :: B31_NL_AlgoCtx_Type
    ! Iteration control
    INTEGER(i4) :: iteration               ! Current Newton iteration
    INTEGER(i4) :: max_iterations
    INTEGER(i4) :: total_iterations       ! Total iterations in step
    LOGICAL  :: converged
    
    ! Convergence metrics
    REAL(wp) :: residual_norm
    REAL(wp) :: displacement_norm
    REAL(wp) :: energy_norm
    REAL(wp) :: tolerance_force
    REAL(wp) :: tolerance_disp
    REAL(wp) :: tolerance_energy
    
    ! System matrices
    REAL(wp) :: K_matrix(12, 12)       ! Stiffness matrix
    REAL(wp) :: M_matrix(12, 12)       ! Mass matrix
    REAL(wp) :: C_matrix(12, 12)       ! Damping matrix
    
    ! Vectors
    REAL(wp) :: R_ext(12)              ! External force
    REAL(wp) :: R_int(12)               ! Internal force
    REAL(wp) :: R_residual(12)         ! Residual R = R_ext - R_int
    REAL(wp) :: du(12)                 ! Displacement increment
    REAL(wp) :: dU_iter(12)           ! Iteration displacement
    
    ! Tangent matrix work arrays
    REAL(wp) :: K_material(12, 12)     ! Material stiffness
    REAL(wp) :: K_geometric(12, 12)    ! Geometric stiffness
    REAL(wp) :: K_initial_stress(12,12)! Initial stress stiffness
    
    ! Coordinate transformation
    REAL(wp) :: T_transform(12, 12)    ! Local-global transform
    REAL(wp) :: Q_rotation(3, 3)       ! Rotation tensor
    
    ! Line search
    LOGICAL  :: line_search_active
    REAL(wp) :: line_search_factor
    INTEGER(i4) :: line_search_max_iter
END TYPE B31_NL_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_NL_Initialize` | 152 | `SUBROUTINE PH_Elem_B31_NL_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_NL_SetFormulation` | 238 | `SUBROUTINE PH_Elem_B31_NL_SetFormulation(&` |
| SUBROUTINE | `PH_Elem_B31_NL_CoordTransform` | 284 | `SUBROUTINE PH_Elem_B31_NL_CoordTransform(&` |
| SUBROUTINE | `PH_Elem_B31_NL_ComputeSystem` | 380 | `SUBROUTINE PH_Elem_B31_NL_ComputeSystem(&` |
| SUBROUTINE | `PH_Elem_B31_NL_NewtonRaphson` | 546 | `SUBROUTINE PH_Elem_B31_NL_NewtonRaphson(&` |
| SUBROUTINE | `PH_Elem_B31_NL_ConvergenceCheck` | 648 | `SUBROUTINE PH_Elem_B31_NL_ConvergenceCheck(&` |
| FUNCTION | `PH_Elem_B31_NL_GetResidual` | 698 | `FUNCTION PH_Elem_B31_NL_GetResidual(algo_ctx) RESULT(R_residual)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
