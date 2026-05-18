# `RT_Asm_NLGeomEval.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_NLGeomEval.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_NLGeomEval`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_NLGeomEval`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_NLGeomEval`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_NLGeomEval.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_DefKin` (lines 107–118)

```fortran
  type :: RT_DefKin
    !! Deformation kinematics (renamed from UF_DeformationKinematics)
    
    real(wp) :: F(3, 3)                  ! Deformation gradient
    real(wp) :: F_inv(3, 3)              ! Inverse deformation gradient
    real(wp) :: detF                     ! Jacobian determinant
    real(wp) :: C(3, 3)                  ! Right Cauchy-Green tensor
    real(wp) :: b(3, 3)                  ! Left Cauchy-Green tensor (Finger tensor)
    real(wp) :: E(3, 3)                  ! Green-Lagrange strain
    real(wp) :: E_log(3, 3)              ! Logarithmic (Hencky) strain
    real(wp) :: epsilon(3, 3)            ! Almansi strain
  end type RT_DefKin
```

### `RT_LagrCfg` (lines 123–132)

```fortran
  type :: RT_LagrCfg
    !! Lagrangian configuration (renamed from UF_LagrangianConfig)
    
    integer(i4) :: formulation_typ  ! 1=Total Lagrangian, 2=Updated Lagrangian
    real(wp) :: coords_ref(64, 3)      ! Reference coordinates (n_nodes, 3)
    real(wp) :: coords_curr(64, 3)      ! Current coordinates (n_nodes, 3)
    real(wp) :: coords_prev(64, 3)      ! Previous coordinates (n_nodes, 3)
    real(wp) :: dN_dX(64, 3)            ! Shape function derivatives w.r.t. reference (n_nodes, 3)
    real(wp) :: dN_dx(64, 3)            ! Shape function derivatives w.r.t. current (n_nodes, 3)
  end type RT_LagrCfg
```

### `RT_RotSta` (lines 134–141)

```fortran
  type :: RT_RotSta
    !! Rotation state (renamed from UF_RotationState)
    
    real(wp) :: R(3, 3)               ! Rotation matrix
    real(wp) :: euler_angles(3)       ! Euler angles (ZYX convention)
    real(wp) :: quaternion(4)        ! Quaternion [w, x, y, z]
    real(wp) :: rotation_vector(3)    ! Rotation vector (axis-angle)
  end type RT_RotSta
```

### `RT_LinRes` (lines 143–150)

```fortran
  type :: RT_LinRes
    !! Linearization result (renamed from UF_LinearizationResult)
    
    real(wp), allocatable :: K_mat(:,:)    ! Mat stiffness matrix
    real(wp), allocatable :: K_geo(:,:)    ! Geometric stiffness matrix
    real(wp), allocatable :: K_total(:,:)  ! Total stiffness matrix
    real(wp), allocatable :: R_residual(:) ! Residual force vector
  end type RT_LinRes
```

### `RT_Asm_NLGeom_Eval_Args` (lines 155–181)

```fortran
  TYPE :: RT_Asm_NLGeom_Eval_Args
  ! Purpose: —�?  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Asm_NLGeom_Eval_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BuildBMatrix_TL` | 186 | `subroutine BuildBMatrix_TL(dN_dX, coords_curr, B_L, B_NL, G, status)` |
| SUBROUTINE | `BuildBMatrix_UL` | 217 | `subroutine BuildBMatrix_UL(dN_dx, coords_curr, B_L, B_NL, G, status)` |
| SUBROUTINE | `BuildGMatrix` | 248 | `subroutine BuildGMatrix(B_L, G, status)` |
| SUBROUTINE | `Calc_eigenvector_3x3` | 266 | `subroutine Calc_eigenvector_3x3(A, lambda, v)` |
| SUBROUTINE | `Co_Complete` | 310 | `subroutine Co_Complete(G, stress_matrix, K_geo, status)` |
| SUBROUTINE | `ComputeAlmansiStrain` | 348 | `subroutine ComputeAlmansiStrain(b, epsilon, status)` |
| SUBROUTINE | `ComputeEigenvalues3x3Sym` | 383 | `subroutine ComputeEigenvalues3x3Sym(A, lambda, V, status)` |
| SUBROUTINE | `ComputeGeometricStiffness_TL` | 437 | `subroutine ComputeGeometricStiffness_TL(G, S_voigt, K_geo, status)` |
| SUBROUTINE | `ComputeGeometricStiffness_UL` | 463 | `subroutine ComputeGeometricStiffness_UL(G, stress_voigt, K_geo, status)` |
| SUBROUTINE | `ComputeInverse3x3` | 472 | `subroutine ComputeInverse3x3(A, A_inv)` |
| SUBROUTINE | `ComputeMaterialStiffness_TL` | 501 | `subroutine ComputeMaterialStiffness_TL(B_L, B_NL, D_mat, K_mat, status)` |
| SUBROUTINE | `ComputeMaterialStiffness_UL` | 524 | `subroutine ComputeMaterialStiffness_UL(B_L, B_NL, D_mat, K_mat, status)` |
| SUBROUTINE | `ComputeRotationVector` | 533 | `subroutine ComputeRotationVector(R, rotation_vector, status)` |
| SUBROUTINE | `ComputeStressFromStrain_TL` | 563 | `subroutine ComputeStressFromStrain_TL(E, S, status)` |
| SUBROUTINE | `ComputeStressFromStrain_UL` | 594 | `subroutine ComputeStressFromStrain_UL(epsilon, sigma, status)` |
| SUBROUTINE | `GetMaterialTangentStiffness` | 603 | `subroutine GetMaterialTangentStiffness(D_mat, status)` |
| SUBROUTINE | `or_ei_3x3` | 635 | `subroutine or_ei_3x3(V)` |
| SUBROUTINE | `RT_Asm_Calc_B_Nonlin` | 668 | `subroutine RT_Asm_Calc_B_Nonlin(dN_dX, u, B_NL, status)` |
| SUBROUTINE | `RT_Asm_Calc_ConsistLin` | 753 | `subroutine RT_Asm_Calc_ConsistLin(B_L, B_NL, sigma, D_mat, K_mat, K_geo, status)` |
| SUBROUTINE | `RT_Asm_Calc_DefGrad` | 807 | `subroutine RT_Asm_Calc_DefGrad(coords_ref, coords_curr, dN_dX, F, detF, status)` |
| SUBROUTINE | `RT_Asm_Calc_GeomStiff` | 865 | `subroutine RT_Asm_Calc_GeomStiff(B, sigma, K_geo, status)` |
| SUBROUTINE | `RT_Asm_Calc_GreenLagStrain` | 910 | `subroutine RT_Asm_Calc_GreenLagStrain(F, E)` |
| SUBROUTINE | `RT_Asm_Calc_LargeRot` | 931 | `subroutine RT_Asm_Calc_LargeRot(F, R, U, status)` |
| SUBROUTINE | `RT_Asm_Calc_LogStrain` | 1008 | `subroutine RT_Asm_Calc_LogStrain(F, E_log, status)` |
| SUBROUTINE | `RT_Asm_Calc_RightCauchyGrn` | 1075 | `subroutine RT_Asm_Calc_RightCauchyGrn(F, C)` |
| SUBROUTINE | `RT_Asm_Calc_TotLagStrain` | 1094 | `subroutine RT_Asm_Calc_TotLagStrain(coords_initial, coords_curr, dN_dX, E, status)` |
| SUBROUTINE | `RT_Asm_Comp_UpdLagStrain` | 1112 | `subroutine RT_Asm_Comp_UpdLagStrain(coords_ref, coords_curr, dN_dx, E, status)` |
| SUBROUTINE | `RT_Asm_GeomStiff_Assem` | 1130 | `SUBROUTINE RT_Asm_GeomStiff_Assem(model, nDOF, stress_state, K_geo_csr, error)` |
| SUBROUTINE | `RT_Asm_GeomStiff_FromStress` | 1290 | `SUBROUTINE RT_Asm_GeomStiff_FromStress(model, nDOF, K_linear, u_current, &` |
| SUBROUTINE | `RT_Asm_Tr_St_PK2toCauchy` | 1326 | `subroutine RT_Asm_Tr_St_PK2toCauchy(S, F, sigma, status)` |
| SUBROUTINE | `RT_Asm_Trans_Stre_Cauchy2PK1` | 1404 | `subroutine RT_Asm_Trans_Stre_Cauchy2PK1(sigma, F, P, status)` |
| SUBROUTINE | `RT_Asm_Trans_Stre_Cauchy2PK2` | 1460 | `subroutine RT_Asm_Trans_Stre_Cauchy2PK2(sigma, F, S, status)` |
| SUBROUTINE | `RT_GeomNonlin_CompEulerAng` | 1542 | `subroutine RT_GeomNonlin_CompEulerAng(R, euler_angles, status)` |
| SUBROUTINE | `RT_GeomNonlin_CompJacobian` | 1578 | `subroutine RT_GeomNonlin_CompJacobian(F, J, J_inv, status)` |
| SUBROUTINE | `RT_GeomNonlin_CompKin` | 1606 | `subroutine RT_GeomNonlin_CompKin(coords_ref, coords_curr, dN_dX, &` |
| SUBROUTINE | `RT_GeomNonlin_CompQuat` | 1647 | `subroutine RT_GeomNonlin_CompQuat(R, quaternion, status)` |
| SUBROUTINE | `RT_GeomNonlin_CompRotMat` | 1700 | `subroutine RT_GeomNonlin_CompRotMat(F, rotation_state, status)` |
| SUBROUTINE | `RT_GeomNonlin_CompStrainMeas` | 1729 | `subroutine RT_GeomNonlin_CompStrainMeas(kinematics, strain_type, &` |
| SUBROUTINE | `RT_GeomNonlin_ConsistLin` | 1760 | `subroutine RT_GeomNonlin_ConsistLin(B_L, B_NL, sigma, D_mat, &` |
| SUBROUTINE | `RT_GeomNonlin_GeomElem_TL` | 1820 | `subroutine RT_GeomNonlin_GeomElem_TL(coords_ref, coords_curr, dN_dX, &` |
| SUBROUTINE | `RT_GeomNonlin_GeomElem_UL` | 1867 | `subroutine RT_GeomNonlin_GeomElem_UL(coords_prev, coords_curr, dN_dx, &` |
| SUBROUTINE | `RT_GeomNonlin_TotLag` | 1914 | `subroutine RT_GeomNonlin_TotLag(config, F, E, S, K_mat, K_geo, status, R_elem, D_tangent)` |
| SUBROUTINE | `RT_GeomNonlin_UpdateCfg` | 2003 | `subroutine RT_GeomNonlin_UpdateCfg(coords_old, u_increment, &` |
| SUBROUTINE | `RT_GeomNonlin_UpdLag` | 2035 | `subroutine RT_GeomNonlin_UpdLag(config, F, epsilon, sigma, K_mat, K_geo, status, R_elem, D_tangent)` |
| SUBROUTINE | `sort_eigenvalues_3x3` | 2122 | `subroutine sort_eigenvalues_3x3(lambda)` |
| SUBROUTINE | `TensorToVoigt` | 2143 | `subroutine TensorToVoigt(tensor, voigt)` |
| SUBROUTINE | `VoigtToTensor` | 2156 | `subroutine VoigtToTensor(voigt, tensor)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
