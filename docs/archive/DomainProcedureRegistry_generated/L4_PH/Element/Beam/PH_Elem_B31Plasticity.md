# `PH_Elem_B31Plasticity.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31Plasticity.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_B31Plasticity`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31Plasticity`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31Plasticity`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31Plasticity.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_Plas_Mat_Desc_Type` (lines 28–47)

```fortran
TYPE :: B31_Plas_Mat_Desc_Type
  ! Elastic properties
  REAL(wp) :: E                     ! Young's modulus
  REAL(wp) :: nu                    ! Poisson's ratio
  REAL(wp) :: G                     ! Shear modulus
  REAL(wp) :: K_bulk                ! Bulk modulus
  
  ! Plastic properties
  REAL(wp) :: sigma_y0              ! Initial yield stress
  REAL(wp) :: H_iso                 ! Isotropic hardening modulus
  REAL(wp) :: H_kin                 ! Kinematic hardening modulus (optional)
  
  ! Hardening law parameters
  INTEGER(i4) :: hardening_type        ! 1=Linear, 2=Power-law, 3=Exponential
  REAL(wp) :: hardening_param(3)    ! Additional hardening params
  
  ! Integration control
  INTEGER(i4) :: n_fibers              ! Number of fibers through section
  REAL(wp) :: fiber_coords(:,:)     ! Fiber locations (y, z, area)
END TYPE B31_Plas_Mat_Desc_Type
```

### `B31_Plas_Mat_State_Type` (lines 49–69)

```fortran
TYPE :: B31_Plas_Mat_State_Type
  ! Stress state
  REAL(wp) :: sigma(6)              ! Cauchy stress vector (Voigt)
  REAL(wp) :: s_dev(6)              ! Deviatoric stress
  REAL(wp) :: alpha(6)              ! Back stress (kinematic hardening)
  
  ! Internal variables
  REAL(wp) :: eps_p_cum             ! Cumulative plastic strain
  REAL(wp) :: eps_p(6)              ! Plastic strain tensor
  REAL(wp) :: kappa                 ! Isotropic hardening variable
  
  ! Yield surface
  REAL(wp) :: f_yield               ! Yield function value
  REAL(wp) :: R_iso                 ! Isotropic hardening stress
  REAL(wp) :: sigma_eq              ! von Mises equivalent stress
  
  ! Section state (fiber model)
  REAL(wp) :: fiber_stress(:)       ! Stress at each fiber
  REAL(wp) :: fiber_strain(:)       ! Strain at each fiber
  REAL(wp) :: fiber_yield(:)        ! Yield status at fibers
END TYPE B31_Plas_Mat_State_Type
```

### `B31_Plas_Mat_AlgoCtx_Type` (lines 71–90)

```fortran
TYPE :: B31_Plas_Mat_AlgoCtx_Type
  ! Integration parameters
  REAL(wp) :: theta                 ! Newmark parameter (default 0.5)
  REAL(wp) :: dt                    ! Time increment
  
  ! Return mapping work arrays
  REAL(wp) :: D_elastic(6, 6)       ! Elastic stiffness matrix
  REAL(wp) :: N_flow(6)             ! Flow direction vector
  REAL(wp) :: D_tangent(6, 6)       ! Consistent tangent matrix
  
  ! Iteration variables
  INTEGER(i4) :: nr_iter               ! Newton-Raphson iterations
  REAL(wp) :: residual              ! Residual norm
  LOGICAL  :: converged             ! Convergence flag
  
  ! Section integration
  REAL(wp) :: N_axial               ! Axial force resultant
  REAL(wp) :: M_y, M_z              ! Bending moment resultants
  REAL(wp) :: T_tors                ! Torque resultant
END TYPE B31_Plas_Mat_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_Plas_Initialize` | 105 | `SUBROUTINE PH_Elem_B31_Plas_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_Plas_BuildElasticMatrix` | 198 | `SUBROUTINE PH_Elem_B31_Plas_BuildElasticMatrix(desc, D_elastic, status)` |
| FUNCTION | `PH_Elem_B31_Plas_J2YieldFunction` | 247 | `FUNCTION PH_Elem_B31_Plas_J2YieldFunction(&` |
| SUBROUTINE | `PH_Elem_B31_Plas_ReturnMapping` | 346 | `SUBROUTINE PH_Elem_B31_Plas_ReturnMapping(&` |
| SUBROUTINE | `PH_Elem_B31_Plas_ConsistentTangent` | 498 | `SUBROUTINE PH_Elem_B31_Plas_ConsistentTangent(&` |
| SUBROUTINE | `PH_Elem_B31_Plas_UpdateStress` | 562 | `SUBROUTINE PH_Elem_B31_Plas_UpdateStress(&` |
| SUBROUTINE | `PH_Elem_B31_Plas_SectionFiberModel` | 612 | `SUBROUTINE PH_Elem_B31_Plas_SectionFiberModel(&` |
| SUBROUTINE | `PH_Elem_B31_Plas_PlasticHinge` | 686 | `SUBROUTINE PH_Elem_B31_Plas_PlasticHinge(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
