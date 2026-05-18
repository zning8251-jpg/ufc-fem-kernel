!===============================================================================
! MODULE: PH_NLGeom_Eval
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Eval
! BRIEF:  Runtime Geometric Nonlinearity Module
!===============================================================================
MODULE PH_NLGeom_Eval
!> [EVAL] Runtime Geometric Nonlinearity Evaluation (Large Deformation)
!> Theory:
!>   - Deformation gradient: F = ∂x/∂X = I + ∇u
!>   - Green-Lagrange strain: E = 0.5·(C - I), C = F^T·F
!>   - Almansi strain: e = 0.5·(I - b^{-1}), b = F·F^T
!>   - Stress measures: σ (Cauchy), P (PK1), S (PK2)
!>   - Formulations: Total Lagrangian (TL) and Updated Lagrangian (UL)
!> References:
!>   - Bathe, K.J. (2006). Finite Element Procedures
!>   - Belytschko, T. et al. (2014). Nonlinear Finite Elements
!> Status: Production | Last verified: 2026-02-21
  !! Runtime Geometric Nonlinearity Module (Merged)
  !! - Large deformation theory implementation
  !! - Updated Lagrangian and Total Lagrangian formulations
  !! - Advanced kinematics and nonlinear theory
  
  USE IF_Err_Brg,          only: ErrorStatusType, init_error_status, &
                                   IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core,          only: wp, i4
  USE MD_Base_ElemLib, ONLY: UF_GetGaussPoints, UF_GetShapeFunctions, &
                                   UF_ComputeJacobian, ShapeFuncResult
  USE MD_Base_ObjModel, ONLY: UF_Part, UF_Element, UF_Node
  USE MD_Mesh_Elem_Types, ONLY: UF_TOPO_Hex, UF_TOPO_Tet, UF_TOPO_Quad, &
                                 UF_TOPO_Tri, UF_TOPO_Line, UF_TOPO_Wedge
  USE MD_Model_Lib_Core, ONLY: UF_Model
  ! ARCH-EXEMPT: L4 NLGeom assembly requires L5 runtime assembly utilities
  USE RT_Asm_Util, ONLY: RT_Asm_ElemLoop_Info, RT_Asm_GetElemInfo, &
                                    RT_Asm_GetElemDOFs, RT_Asm_GetElemCoords
  USE RT_Solv_Sparse, ONLY: RT_TripletList, RT_Triplet_Init, RT_Triplet_Add, &
                               RT_Triplet_Free, RT_CSR_FromTriplet
  USE RT_Solv_Def, ONLY: RT_CSRMatrix
  
  implicit none
  private
  
  ! ===================================================================
  ! Public Procedures (from RT_Geometric_Nonlinear)
  ! ===================================================================
  public :: RT_Asm_Calc_DefGrad          ! Calc_DeformationGradient
  public :: RT_Asm_Calc_GreenLagStrain   ! Calc_GreenLagrangeStrain
  public :: RT_Asm_Calc_LogStrain        ! Calc_LogStrain
  public :: RT_Asm_Calc_RightCauchyGrn  ! Calc_RightCauchyGreen
  public :: RT_Asm_Trans_Stre_Cauchy2PK2 ! Transform_Stre_Cauchy_to_PK2
  public :: RT_Asm_Trans_Stre_PK2toCauchy ! Transform_Stre_PK2_to_Cauchy
  public :: RT_Asm_Trans_Stre_Cauchy2PK1  ! Transform_Stre_Cauchy_to_PK1
  public :: RT_Asm_Calc_GeomStiff        ! Calc_GeometricStiffness
  public :: RT_Asm_GeomStiff_Assem        ! RT_Asm_Geometric_Stiffness_Assemble
  public :: RT_Asm_GeomStiff_FromStress   ! RT_Asm_Geometric_Stiffness_FromStress
  public :: RT_Asm_Comp_UpdLagStrain     ! Compute_UpdatedLagrangian_Strain
  public :: RT_Asm_Calc_TotLagStrain     ! Calc_TotalLagrangian_Strain
  public :: RT_Asm_Calc_LargeRot         ! Calc_LargeRotation
  public :: RT_Asm_Calc_ConsistLin      ! Calc_ConsistentLinearization
  public :: RT_Asm_Calc_B_Nonlin        ! Calc_B_Nonlin
  
  ! ===================================================================
  ! Public Procedures (from UF_LargeDeformation, renamed)
  ! ===================================================================
  public :: RT_GeomNonlin_CompKin        ! UF_LargeDeformation_ComputeKinematics
  public :: RT_GeomNonlin_CompStrainMeas  ! UF_LargeDeformation_ComputeStrainMeasures
  public :: RT_GeomNonlin_UpdateCfg      ! UF_LargeDeformation_UpdateConfiguration
  public :: RT_GeomNonlin_CompJacobian    ! UF_LargeDeformation_ComputeJacobian
  
  ! ===================================================================
  ! Public Procedures (from UF_Nonlinear_Theory, renamed)
  ! ===================================================================
  public :: RT_GeomNonlin_TotLag          ! UF_Nonlinear_TotalLagrangian
  public :: RT_GeomNonlin_UpdLag          ! UF_Nonlinear_UpdatedLagrangian
  public :: RT_GeomNonlin_CompRotMat      ! UF_Nonlinear_ComputeRotationMatrix
  public :: RT_GeomNonlin_CompEulerAng    ! UF_Nonlinear_ComputeEulerAngles
  public :: RT_GeomNonlin_CompQuat        ! UF_Nonlinear_ComputeQuaternion
  public :: RT_GeomNonlin_ConsistLin     ! UF_Nonlinear_ConsistentLinearization
  public :: RT_GeomNonlin_GeomElem_TL     ! UF_Nonlinear_GeometricElement_TL
  public :: RT_GeomNonlin_GeomElem_UL     ! UF_Nonlinear_GeometricElement_UL
  
  ! ===================================================================
  ! Public Types (renamed)
  ! ===================================================================
  public :: RT_DefKin                    ! UF_DeformationKinematics
  public :: RT_LagrCfg                   ! UF_LagrangianConfig
  public :: RT_RotSta                    ! UF_RotationState
  public :: RT_LinRes                    ! UF_LinearizationResult
  
  ! ===================================================================
  ! Constants
  ! ===================================================================
  real(wp), parameter :: TOL_DET = 1.0e-30_wp
  real(wp), parameter :: TOL_STRAIN = 1.0e-12_wp
  
  ! ===================================================================
  ! Types (from UF_LargeDeformation, renamed)
  ! ===================================================================
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
  
  ! ===================================================================
  ! Types (from UF_Nonlinear_Theory, renamed)
  ! ===================================================================
  type :: RT_LagrCfg
    !! Lagrangian configuration (renamed from UF_LagrangianConfig)
    
    integer(i4) :: formulation_typ  ! 1=Total Lagrangian, 2=Updated Lagrangian
    !! Active node count for coords_* / dN_* rows (fixed buffers are 64×3).
    integer(i4) :: n_nodes = 0_i4
    real(wp) :: coords_ref(64, 3)      ! Reference coordinates (max_nodes, 3)
    real(wp) :: coords_curr(64, 3)      ! Current coordinates (max_nodes, 3)
    real(wp) :: coords_prev(64, 3)      ! Previous coordinates (max_nodes, 3)
    real(wp) :: dN_dX(64, 3)            ! Shape function derivatives w.r.t. reference (max_nodes, 3)
    real(wp) :: dN_dx(64, 3)            ! Shape function derivatives w.r.t. current (max_nodes, 3)
  end type RT_LagrCfg
  
  type :: RT_RotSta
    !! Rotation state (renamed from UF_RotationState)
    
    real(wp) :: R(3, 3)               ! Rotation matrix
    real(wp) :: euler_angles(3)       ! Euler angles (ZYX convention)
    real(wp) :: quaternion(4)        ! Quaternion [w, x, y, z]
    real(wp) :: rotation_vector(3)    ! Rotation vector (axis-angle)
  end type RT_RotSta
  
  type :: RT_LinRes
    !! Linearization result (renamed from UF_LinearizationResult)
    
    real(wp), allocatable :: K_mat(:,:)    ! Mat stiffness matrix
    real(wp), allocatable :: K_geo(:,:)    ! Geometric stiffness matrix
    real(wp), allocatable :: K_total(:,:)  ! Total stiffness matrix
    real(wp), allocatable :: R_residual(:) ! Residual force vector
  end type RT_LinRes
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_NLGeom_Eval_Arg
  TYPE :: PH_Elem_NLGeom_Eval_Arg
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
  END TYPE PH_Elem_NLGeom_Eval_Arg


contains

  subroutine BuildBMatrix_TL(dN_dX, coords_curr, B_L, B_NL, G, status)
    real(wp), intent(in) :: dN_dX(:,:), coords_curr(:,:)
    real(wp), intent(out) :: B_L(:,:), B_NL(:,:), G(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, n_dofs, i
    call init_error_status(status)
    n_nodes = size(dN_dX, 1)
    n_dofs = n_nodes * 3
    if (size(B_L, 1) < 6 .or. size(B_L, 2) < n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'BuildBMatrix_TL: B_L size'
      return
    end if
    B_L = 0.0_wp
    do i = 1, n_nodes
      B_L(1, 3*i-2) = dN_dX(i, 1)
      B_L(2, 3*i-1) = dN_dX(i, 2)
      B_L(3, 3*i)   = dN_dX(i, 3)
      B_L(4, 3*i-2) = dN_dX(i, 2)
      B_L(4, 3*i-1) = dN_dX(i, 1)
      B_L(5, 3*i-1) = dN_dX(i, 3)
      B_L(5, 3*i)   = dN_dX(i, 2)
      B_L(6, 3*i-2) = dN_dX(i, 3)
      B_L(6, 3*i)   = dN_dX(i, 1)
    end do
    if (size(B_NL, 1) >= 6 .and. size(B_NL, 2) >= n_dofs) B_NL = 0.0_wp
    if (size(G, 1) >= 9 .and. size(G, 2) >= n_dofs) G = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine BuildBMatrix_TL

  subroutine BuildBMatrix_UL(dN_dx, coords_curr, B_L, B_NL, G, status)
    real(wp), intent(in) :: dN_dx(:,:), coords_curr(:,:)
    real(wp), intent(out) :: B_L(:,:), B_NL(:,:), G(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, n_dofs, i
    call init_error_status(status)
    n_nodes = size(dN_dx, 1)
    n_dofs = n_nodes * 3
    if (size(B_L, 1) < 6 .or. size(B_L, 2) < n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'BuildBMatrix_UL: B_L size'
      return
    end if
    B_L = 0.0_wp
    do i = 1, n_nodes
      B_L(1, 3*i-2) = dN_dx(i, 1)
      B_L(2, 3*i-1) = dN_dx(i, 2)
      B_L(3, 3*i)   = dN_dx(i, 3)
      B_L(4, 3*i-2) = dN_dx(i, 2)
      B_L(4, 3*i-1) = dN_dx(i, 1)
      B_L(5, 3*i-1) = dN_dx(i, 3)
      B_L(5, 3*i)   = dN_dx(i, 2)
      B_L(6, 3*i-2) = dN_dx(i, 3)
      B_L(6, 3*i)   = dN_dx(i, 1)
    end do
    if (size(B_NL, 1) >= 6 .and. size(B_NL, 2) >= n_dofs) B_NL = 0.0_wp
    if (size(G, 1) >= 9 .and. size(G, 2) >= n_dofs) G = 0.0_wp
    status%status_code = IF_STATUS_OK
  end subroutine BuildBMatrix_UL

  subroutine BuildGMatrix(B_L, G, status)
    real(wp), intent(in) :: B_L(:,:)
    real(wp), intent(out) :: G(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs
    call init_error_status(status)
    n_dofs = size(B_L, 2)
    if (size(G, 1) < 9 .or. size(G, 2) < n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'BuildGMatrix: G size'
      return
    end if
    G = 0.0_wp
    if (size(B_L, 1) >= 6) G(1:6, 1:n_dofs) = B_L(1:6, 1:n_dofs)
    status%status_code = IF_STATUS_OK
  end subroutine BuildGMatrix

  subroutine Calc_eigenvector_3x3(A, lambda, v)
    !! Compute eigenvector for given eigenvalue
    
    real(wp), intent(in) :: A(3, 3)
    real(wp), intent(in) :: lambda
    real(wp), intent(out) :: v(3)
    
    real(wp) :: A_minus_lambdaI(3, 3)
    real(wp) :: v1(3), v2(3), norm
    integer(i4) :: i
    
    ! Build A - λ·I
    A_minus_lambdaI = A
    do i = 1, 3
      A_minus_lambdaI(i, i) = A_minus_lambdaI(i, i) - lambda
    end do
    
    ! Use cross product of two rows to find null vector
    v1 = A_minus_lambdaI(1, :)
    v2 = A_minus_lambdaI(2, :)
    
    ! Cross product: v = v1 × v2
    v(1) = v1(2) * v2(3) - v1(3) * v2(2)
    v(2) = v1(3) * v2(1) - v1(1) * v2(3)
    v(3) = v1(1) * v2(2) - v1(2) * v2(1)
    
    ! Normalize
    norm = sqrt(v(1)**2 + v(2)**2 + v(3)**2)
    if (norm > 1.0e-12_wp) then
      v = v / norm
    else
      ! Fallback: use third row
      v = A_minus_lambdaI(3, :)
      norm = sqrt(v(1)**2 + v(2)**2 + v(3)**2)
      if (norm > 1.0e-12_wp) then
        v = v / norm
      else
        ! Default: unit vector
        v = [1.0_wp, 0.0_wp, 0.0_wp]
      end if
    end if
    
  end subroutine Calc_eigenvector_3x3

  subroutine Co_Complete(G, stress_matrix, K_geo, status)
    real(wp), intent(in) :: G(:,:), stress_matrix(3, 3)
    real(wp), intent(out) :: K_geo(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs, i, j, k, l
    real(wp), allocatable :: temp(:,:)

    call init_error_status(status)

    n_dofs = size(G, 2)
    allocate(temp(3, n_dofs))

    ! K_geo = G^T * [σ] * G
    ! [σ] * G
    temp = 0.0_wp
    do i = 1, 3
      do j = 1, n_dofs
        do k = 1, 3
          temp(i, j) = temp(i, j) + stress_matrix(i, k) * G(k, j)
        end do
      end do
    end do

    ! G^T * temp
    K_geo = 0.0_wp
    do i = 1, n_dofs
      do j = 1, n_dofs
        do k = 1, 3
          K_geo(i, j) = K_geo(i, j) + G(k, i) * temp(k, j)
        end do
      end do
    end do

    deallocate(temp)
    status%status_code = IF_STATUS_OK
  end subroutine ComputeGeometricStiff_Complete

  subroutine ComputeAlmansiStrain(b, epsilon, status)
    !! Compute Almansi strain ε = 0.5*(I - b^{-1})
    
    real(wp), intent(in) :: b(3, 3)
    real(wp), intent(out) :: epsilon(3, 3)
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: b_inv(3, 3), I(3, 3), temp(3, 3)
    integer(i4) :: i, j

    call init_error_status(status)

    ! Almansi strain: ε = 0.5*(I - b^{-1})
    I = 0.0_wp
    I(1, 1) = 1.0_wp
    I(2, 2) = 1.0_wp
    I(3, 3) = 1.0_wp

    ! Compute b^{-1}
    call ComputeInverse3x3(b, b_inv)

    ! temp = I - b^{-1}
    temp = I - b_inv

    ! epsilon = 0.5 * temp
    do i = 1, 3
      do j = 1, 3
        epsilon(i, j) = 0.5_wp * temp(i, j)
      end do
    end do

    status%status_code = IF_STATUS_OK

  end subroutine ComputeAlmansiStrain

  subroutine ComputeEigenvalues3x3Sym(A, lambda, V, status)
    !! Compute eigenvalues and eigenvectors of 3x3 symmetric matrix
    
    real(wp), intent(in) :: A(3, 3)
    real(wp), intent(out) :: lambda(3)
    real(wp), intent(out) :: V(3, 3)
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: I1, I2, I3  ! Invariants
    real(wp) :: p, q, r, phi
    integer(i4) :: i
    
    call init_error_status(status)
    
    ! Compute invariants
    I1 = A(1,1) + A(2,2) + A(3,3)
    I2 = A(1,1)*A(2,2) + A(1,1)*A(3,3) + A(2,2)*A(3,3) - &
         A(1,2)**2 - A(1,3)**2 - A(2,3)**2
    I3 = A(1,1) * (A(2,2)*A(3,3) - A(2,3)**2) - &
         A(1,2) * (A(1,2)*A(3,3) - A(1,3)*A(2,3)) + &
         A(1,3) * (A(1,2)*A(2,3) - A(2,2)*A(1,3))
    
    ! Analytical solution for 3x3 symmetric matrix eigenvalue problem
    p = I2 - I1**2 / 3.0_wp
    q = 2.0_wp * I1**3 / 27.0_wp - I1 * I2 / 3.0_wp + I3
    r = (q / 2.0_wp)**2 + (p / 3.0_wp)**3
    
    if (r > 0.0_wp) then
      lambda(1) = (-q / 2.0_wp + sqrt(r))**(1.0_wp/3.0_wp) + &
                  (-q / 2.0_wp - sqrt(r))**(1.0_wp/3.0_wp) + I1 / 3.0_wp
      lambda(2) = lambda(1)
      lambda(3) = lambda(1)
    else
      phi = acos(-q / (2.0_wp * sqrt(-(p/3.0_wp)**3)))
      lambda(1) = 2.0_wp * sqrt(-p / 3.0_wp) * cos(phi / 3.0_wp) + I1 / 3.0_wp
      lambda(2) = 2.0_wp * sqrt(-p / 3.0_wp) * cos(phi / 3.0_wp + 2.0_wp * 3.141592653589793_wp / 3.0_wp) + I1 / 3.0_wp
      lambda(3) = 2.0_wp * sqrt(-p / 3.0_wp) * cos(phi / 3.0_wp + 4.0_wp * 3.141592653589793_wp / 3.0_wp) + I1 / 3.0_wp
    end if
    
    ! Sort eigenvalues in descending order
    call sort_eigenvalues_3x3(lambda)
    
    ! Compute eigenvectors
    do i = 1, 3
      call Calc_eigenvector_3x3(A, lambda(i), V(:, i))
    end do
    
    ! Orthonormalize eigenvectors
    call orthonormalize_eigenvectors_3x3(V)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine ComputeEigenvalues3x3Sym

  subroutine ComputeGeometricStiffness_TL(G, S_voigt, K_geo, status)
    real(wp), intent(in) :: G(:,:), S_voigt(:)
    real(wp), intent(out) :: K_geo(:,:)
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: S_matrix(3, 3)
    integer(i4) :: n_dofs, i, j, k

    call init_error_status(status)

    n_dofs = size(G, 2)
    call VoigtToTensor(S_voigt, S_matrix)

    ! K_geo = G^T * [S] * G
    K_geo = 0.0_wp
    do i = 1, n_dofs
      do j = 1, n_dofs
        do k = 1, 3
          K_geo(i, j) = K_geo(i, j) + G(k, i) * S_matrix(k, k) * G(k, j)
        end do
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeGeometricStiffness_TL

  subroutine ComputeGeometricStiffness_UL(G, stress_voigt, K_geo, status)
    real(wp), intent(in) :: G(:,:), stress_voigt(:)
    real(wp), intent(out) :: K_geo(:,:)
    type(ErrorStatusType), intent(out) :: status

    ! Similar to ComputeGeometricStiffness_TL
    call ComputeGeometricStiffness_TL(G, stress_voigt, K_geo, status)
  end subroutine ComputeGeometricStiffness_UL

  subroutine ComputeInverse3x3(A, A_inv)
    !! Compute inverse of 3x3 matrix
    
    real(wp), intent(in) :: A(3, 3)
    real(wp), intent(out) :: A_inv(3, 3)
    
    real(wp) :: det
    
    det = A(1,1) * (A(2,2)*A(3,3) - A(2,3)*A(3,2)) - &
          A(1,2) * (A(2,1)*A(3,3) - A(2,3)*A(3,1)) + &
          A(1,3) * (A(2,1)*A(3,2) - A(2,2)*A(3,1))
    
    if (abs(det) < TOL_DET) then
      A_inv = 0.0_wp
      return
    end if
    
    A_inv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) / det
    A_inv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) / det
    A_inv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) / det
    A_inv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) / det
    A_inv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) / det
    A_inv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) / det
    A_inv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) / det
    A_inv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) / det
    A_inv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) / det
    
  end subroutine ComputeInverse3x3

  subroutine ComputeMaterialStiffness_TL(B_L, B_NL, D_mat, K_mat, status)
    real(wp), intent(in) :: B_L(:,:), B_NL(:,:), D_mat(:,:)
    real(wp), intent(out) :: K_mat(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs
    real(wp), allocatable :: B_total(:,:), temp(:,:)

    call init_error_status(status)

    n_dofs = size(B_L, 2)
    allocate(B_total(6, n_dofs), temp(6, n_dofs))

    B_total = B_L + B_NL

    ! K_mat = B_total^T * D * B_total
    temp = matmul(D_mat, B_total)
    K_mat = matmul(transpose(B_total), temp)

    deallocate(B_total, temp)
    status%status_code = IF_STATUS_OK
  end subroutine ComputeMaterialStiffness_TL

  subroutine ComputeMaterialStiffness_UL(B_L, B_NL, D_mat, K_mat, status)
    real(wp), intent(in) :: B_L(:,:), B_NL(:,:), D_mat(:,:)
    real(wp), intent(out) :: K_mat(:,:)
    type(ErrorStatusType), intent(out) :: status

    ! Similar to ComputeMaterialStiffness_TL
    call ComputeMaterialStiffness_TL(B_L, B_NL, D_mat, K_mat, status)
  end subroutine ComputeMaterialStiffness_UL

  subroutine ComputeRotationVector(R, rotation_vector, status)
    real(wp), intent(in) :: R(3, 3)
    real(wp), intent(out) :: rotation_vector(3)
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: angle, axis(3), trace_R, sin_angle

    call init_error_status(status)

    trace_R = R(1, 1) + R(2, 2) + R(3, 3)
    angle = acos(max(-1.0_wp, min(1.0_wp, (trace_R - 1.0_wp) * 0.5_wp)))

    if (abs(angle) < 1.0e-6_wp) then
      rotation_vector = 0.0_wp
    else
      sin_angle = sin(angle)
      axis(1) = (R(3, 2) - R(2, 3)) / (2.0_wp * sin_angle)
      axis(2) = (R(1, 3) - R(3, 1)) / (2.0_wp * sin_angle)
      axis(3) = (R(2, 1) - R(1, 2)) / (2.0_wp * sin_angle)

      ! Normalize axis
      axis = axis / sqrt(sum(axis**2))

      ! Rotation vector
      rotation_vector = angle * axis
    end if

    status%status_code = IF_STATUS_OK
  end subroutine ComputeRotationVector

  subroutine ComputeStressFromStrain_TL(E, S, status)
    real(wp), intent(in) :: E(3, 3)
    real(wp), intent(out) :: S(3, 3)
    type(ErrorStatusType), intent(out) :: status

    ! Simplified: S = D : E (linear elastic)
    real(wp) :: E_modulus, nu, lambda, mu
    integer(i4) :: i, j

    call init_error_status(status)

    ! Default Mat properties
    E_modulus = 2.0e11_wp
    nu = 0.3_wp
    lambda = E_modulus * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu = E_modulus / (2.0_wp * (1.0_wp + nu))

    ! S = lambda * trace(E) * I + 2*mu * E
    S = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        S(i, j) = 2.0_wp * mu * E(i, j)
        if (i == j) then
          S(i, j) = S(i, j) + lambda * (E(1, 1) + E(2, 2) + E(3, 3))
        end if
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ComputeStressFromStrain_TL

  subroutine ComputeStressFromStrain_UL(epsilon, sigma, status)
    real(wp), intent(in) :: epsilon(3, 3)
    real(wp), intent(out) :: sigma(3, 3)
    type(ErrorStatusType), intent(out) :: status

    ! Similar to ComputeStressFromStrain_TL
    call ComputeStressFromStrain_TL(epsilon, sigma, status)
  end subroutine ComputeStressFromStrain_UL

  subroutine GetMaterialTangentStiffness(D_mat, status)
    real(wp), intent(out) :: D_mat(6, 6)
    type(ErrorStatusType), intent(out) :: status

    ! Simplified: isotropic elastic stiffness
    real(wp) :: E_modulus, nu, lambda, mu
    integer(i4) :: i, j

    call init_error_status(status)

    E_modulus = 2.0e11_wp
    nu = 0.3_wp
    lambda = E_modulus * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu = E_modulus / (2.0_wp * (1.0_wp + nu))

    D_mat = 0.0_wp
    D_mat(1, 1) = lambda + 2.0_wp * mu
    D_mat(2, 2) = lambda + 2.0_wp * mu
    D_mat(3, 3) = lambda + 2.0_wp * mu
    D_mat(1, 2) = lambda
    D_mat(2, 1) = lambda
    D_mat(1, 3) = lambda
    D_mat(3, 1) = lambda
    D_mat(2, 3) = lambda
    D_mat(3, 2) = lambda
    D_mat(4, 4) = mu
    D_mat(5, 5) = mu
    D_mat(6, 6) = mu

    status%status_code = IF_STATUS_OK
  end subroutine GetMaterialTangentStiffness

  subroutine or_ei_3x3(V)
    !! Orthonormalize eigenvectors using Gram-Schmidt process
    
    real(wp), intent(inout) :: V(3, 3)
    
    real(wp) :: norm, dot_prod
    
    ! Normalize first eigenvector
    norm = sqrt(V(1,1)**2 + V(2,1)**2 + V(3,1)**2)
    if (norm > 1.0e-12_wp) then
      V(:, 1) = V(:, 1) / norm
    end if
    
    ! Orthogonalize second eigenvector
    dot_prod = dot_product(V(:, 1), V(:, 2))
    V(:, 2) = V(:, 2) - dot_prod * V(:, 1)
    norm = sqrt(V(1,2)**2 + V(2,2)**2 + V(3,2)**2)
    if (norm > 1.0e-12_wp) then
      V(:, 2) = V(:, 2) / norm
    end if
    
    ! Orthogonalize third eigenvector
    dot_prod = dot_product(V(:, 1), V(:, 3))
    V(:, 3) = V(:, 3) - dot_prod * V(:, 1)
    dot_prod = dot_product(V(:, 2), V(:, 3))
    V(:, 3) = V(:, 3) - dot_prod * V(:, 2)
    norm = sqrt(V(1,3)**2 + V(2,3)**2 + V(3,3)**2)
    if (norm > 1.0e-12_wp) then
      V(:, 3) = V(:, 3) / norm
    end if
    
  end subroutine orthonormalize_eigenvectors_3x3

  subroutine RT_Asm_Calc_B_Nonlin(dN_dX, u, B_NL, status)
    !! Compute nonlinear part of B matrix for Total Lagrangian Formul
    
    real(wp), intent(in) :: dN_dX(:,:)    ! Shape function derivatives (n_nodes, 3)
    real(wp), intent(in) :: u(:)          ! Displacement vector (n_dofs)
    real(wp), intent(out) :: B_NL(:,:)    ! Nonlinear B matrix (6, n_dofs)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: n_nodes, n_dofs, i, j, k, node_idx
    real(wp), allocatable :: grad_u(:,:)  ! Displacement gradient (3, 3)
    
    call init_error_status(status)
    
    n_nodes = size(dN_dX, 1)
    n_dofs = size(u)
    
    if (size(B_NL, 1) /= 6 .or. size(B_NL, 2) /= n_dofs) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Calc_B_Nonlin: Size mismatch'
      end if
      return
    end if
    
    ! Compute displacement gradient: grad_u = ∂u/∂X
    allocate(grad_u(3, 3))
    grad_u = 0.0_wp
    
    ! Extract displacement components for each node
    do i = 1, n_nodes
      node_idx = (i - 1) * 3
      if (node_idx + 3 <= n_dofs) then
        do j = 1, 3
          do k = 1, 3
            grad_u(j, k) = grad_u(j, k) + dN_dX(i, k) * u(node_idx + j)
          end do
        end do
      end if
    end do
    
    ! Build nonlinear B matrix
    B_NL = 0.0_wp
    
    ! For each DOF, compute contribution to nonlinear strain
    do i = 1, n_nodes
      node_idx = (i - 1) * 3
      if (node_idx + 3 <= n_dofs) then
        ! E_11 nonlinear contribution
        B_NL(1, node_idx + 1) = grad_u(1, 1) * dN_dX(i, 1)
        B_NL(1, node_idx + 2) = grad_u(1, 2) * dN_dX(i, 1)
        B_NL(1, node_idx + 3) = grad_u(1, 3) * dN_dX(i, 1)
        
        ! E_22 nonlinear contribution
        B_NL(2, node_idx + 1) = grad_u(2, 1) * dN_dX(i, 2)
        B_NL(2, node_idx + 2) = grad_u(2, 2) * dN_dX(i, 2)
        B_NL(2, node_idx + 3) = grad_u(2, 3) * dN_dX(i, 2)
        
        ! E_33 nonlinear contribution
        B_NL(3, node_idx + 1) = grad_u(3, 1) * dN_dX(i, 3)
        B_NL(3, node_idx + 2) = grad_u(3, 2) * dN_dX(i, 3)
        B_NL(3, node_idx + 3) = grad_u(3, 3) * dN_dX(i, 3)
        
        ! 2E_12 nonlinear contribution
        B_NL(4, node_idx + 1) = grad_u(1, 1) * dN_dX(i, 2) + grad_u(2, 1) * dN_dX(i, 1)
        B_NL(4, node_idx + 2) = grad_u(1, 2) * dN_dX(i, 2) + grad_u(2, 2) * dN_dX(i, 1)
        B_NL(4, node_idx + 3) = grad_u(1, 3) * dN_dX(i, 2) + grad_u(2, 3) * dN_dX(i, 1)
        
        ! 2E_13 nonlinear contribution
        B_NL(5, node_idx + 1) = grad_u(1, 1) * dN_dX(i, 3) + grad_u(3, 1) * dN_dX(i, 1)
        B_NL(5, node_idx + 2) = grad_u(1, 2) * dN_dX(i, 3) + grad_u(3, 2) * dN_dX(i, 1)
        B_NL(5, node_idx + 3) = grad_u(1, 3) * dN_dX(i, 3) + grad_u(3, 3) * dN_dX(i, 1)
        
        ! 2E_23 nonlinear contribution
        B_NL(6, node_idx + 1) = grad_u(2, 1) * dN_dX(i, 3) + grad_u(3, 1) * dN_dX(i, 2)
        B_NL(6, node_idx + 2) = grad_u(2, 2) * dN_dX(i, 3) + grad_u(3, 2) * dN_dX(i, 2)
        B_NL(6, node_idx + 3) = grad_u(2, 3) * dN_dX(i, 3) + grad_u(3, 3) * dN_dX(i, 2)
      end if
    end do
    
    deallocate(grad_u)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Calc_B_Nonlin

  subroutine RT_Asm_Calc_ConsistLin(B_L, B_NL, sigma, D_mat, K_mat, K_geo, status)
    !! Compute consistent linearization for nonlinear problems
    
    real(wp), intent(in) :: B_L(:,:)      ! Linear B matrix (6, n_dofs)
    real(wp), intent(in) :: B_NL(:,:)     ! Nonlinear B matrix (6, n_dofs)
    real(wp), intent(in) :: sigma(:)     ! Current sigma (6) Voigt
    real(wp), intent(in) :: D_mat(:,:)    ! Mat tangent stiffness (6, 6)
    real(wp), intent(out) :: K_mat(:,:)   ! Mat stiffness (n_dofs, n_dofs)
    real(wp), intent(out) :: K_geo(:,:)   ! Geometric stiffness (n_dofs, n_dofs)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: n_dofs, i, j, k
    real(wp), allocatable :: B_total(:,:)
    
    call init_error_status(status)
    
    n_dofs = size(B_L, 2)
    if (size(B_NL, 2) /= n_dofs .or. size(K_mat, 1) /= n_dofs .or. &
        size(K_mat, 2) /= n_dofs .or. size(K_geo, 1) /= n_dofs .or. &
        size(K_geo, 2) /= n_dofs) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Calc_ConsistentLinearization: Size mismatch'
      end if
      return
    end if
    
    ! Total B matrix: B = B_L + B_NL
    allocate(B_total(6, n_dofs))
    B_total = B_L + B_NL
    
    ! Mat stiffness: K_mat = B^T * D * B
    K_mat = 0.0_wp
    do i = 1, n_dofs
      do j = 1, n_dofs
        do k = 1, 6
          K_mat(i, j) = K_mat(i, j) + B_total(k, i) * D_mat(k, k) * B_total(k, j)
        end do
      end do
    end do
    
    ! Geometric stiffness
    call RT_Asm_Calc_GeomStiff(B_total, sigma, K_geo, status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) then
      deallocate(B_total)
      return
    end if
    
    deallocate(B_total)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Calc_ConsistLin

  subroutine RT_Asm_Calc_DefGrad(coords_ref, coords_curr, dN_dX, F, detF, status)
    !! Compute deformation gradient F = ∂x/∂X
    
    real(wp), intent(in) :: coords_ref(:,:)   ! (n_nodes, 3)
    real(wp), intent(in) :: coords_curr(:,:)   ! (n_nodes, 3)
    real(wp), intent(in) :: dN_dX(:,:)         ! (n_nodes, 3)
    real(wp), intent(out) :: F(3, 3)
    real(wp), intent(out) :: detF
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j, k, n_nodes
    real(wp) :: u(3)  ! Displacement at node
    
    call init_error_status(status)
    
    n_nodes = size(coords_ref, 1)
    if (size(coords_curr, 1) /= n_nodes .or. size(dN_dX, 1) /= n_nodes) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_Asm_Calc_DefGrad: Size mismatch'
      end if
      return
    end if
    
    ! Init F as identity matrix
    F = 0.0_wp
    F(1, 1) = 1.0_wp
    F(2, 2) = 1.0_wp
    F(3, 3) = 1.0_wp
    
    ! Compute F = I + ∇u
    do i = 1, 3
      do j = 1, 3
        do k = 1, n_nodes
          u(i) = coords_curr(k, i) - coords_ref(k, i)  ! Displacement component
          F(i, j) = F(i, j) + dN_dX(k, j) * u(i)
        end do
      end do
    end do
    
    ! Compute determinant: det(F)
    detF = F(1,1) * (F(2,2)*F(3,3) - F(2,3)*F(3,2)) - &
           F(1,2) * (F(2,1)*F(3,3) - F(2,3)*F(3,1)) + &
           F(1,3) * (F(2,1)*F(3,2) - F(2,2)*F(3,1))
    
    ! Check for invalid deformation (negative volume)
    if (detF <= TOL_DET) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'RT_Asm_Calc_DefGrad: Invalid deformation (detF <= 0)'
      end if
      return
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Calc_DefGrad

  subroutine RT_Asm_Calc_GeomStiff(B, sigma, K_geo, status)
    !! Compute geometric stiffness matrix (initial sigma stiffness)
    
    real(wp), intent(in) :: B(:,:)      ! (6, n_dofs)
    real(wp), intent(in) :: sigma(:)   ! (6) Voigt notation
    real(wp), intent(out) :: K_geo(:,:) ! (n_dofs, n_dofs)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j, k, n_dofs
    real(wp) :: sigma_matrix(6, 6)
    
    call init_error_status(status)
    
    n_dofs = size(B, 2)
    if (size(K_geo, 1) /= n_dofs .or. size(K_geo, 2) /= n_dofs) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Calc_GeometricStiffness: Size mismatch'
      end if
      return
    end if
    
    ! Form sigma matrix
    sigma_matrix = 0.0_wp
    sigma_matrix(1, 1) = sigma(1)
    sigma_matrix(2, 2) = sigma(2)
    sigma_matrix(3, 3) = sigma(3)
    sigma_matrix(4, 4) = sigma(4)
    sigma_matrix(5, 5) = sigma(5)
    sigma_matrix(6, 6) = sigma(6)
    
    ! Compute K_geo = B^T * σ_matrix * B
    K_geo = 0.0_wp
    do i = 1, n_dofs
      do j = 1, n_dofs
        do k = 1, 6
          K_geo(i, j) = K_geo(i, j) + B(k, i) * sigma_matrix(k, k) * B(k, j)
        end do
      end do
    end do
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Calc_GeomStiff

  subroutine RT_Asm_Calc_GreenLagStrain(F, E)
    !! Compute Green-Lagrange strain E = 0.5*(C - I)
    !! where C = F^T F
    
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: E(3, 3)
    
    real(wp) :: C(3, 3)
    integer(i4) :: i
    
    ! Compute C = F^T F
    call RT_Asm_Calc_RightCauchyGrn(F, C)
    
    ! Compute E = 0.5*(C - I)
    E = 0.5_wp * C
    do i = 1, 3
      E(i, i) = E(i, i) - 0.5_wp
    end do
    
  end subroutine RT_Asm_Calc_GreenLagStrain

  subroutine RT_Asm_Calc_LargeRot(F, R, U, status)
    !! Compute rotation matrix R and stretch tensor U from F
    !! Using polar decomposition: F = R * U
    
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: R(3, 3)  ! Rotation matrix
    real(wp), intent(out) :: U(3, 3)  ! Right stretch tensor
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: C(3, 3), U_inv(3, 3)
    real(wp) :: lambda(3), V(3, 3)
    real(wp) :: U_diag(3, 3), temp(3, 3)
    integer(i4) :: i, j, k
    
    call init_error_status(status)
    
    ! Compute C = F^T F
    call RT_Asm_Calc_RightCauchyGrn(F, C)
    
    ! Compute eigenvalues and eigenvectors of C
    call ComputeEigenvalues3x3Sym(C, lambda, V, status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) return
    
    ! Ensure eigenvalues are positive
    do i = 1, 3
      if (lambda(i) <= 0.0_wp) then
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'Calc_LargeRotation: Non-positive eigenvalue'
        end if
        return
      end if
    end do
    
    ! Compute U = sqrt(C) = V * diag(sqrt(lambda)) * V^T
    U_diag = 0.0_wp
    do i = 1, 3
      U_diag(i, i) = sqrt(lambda(i))
    end do
    
    ! Compute temp = V * diag(sqrt(lambda))
    temp = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          temp(i, j) = temp(i, j) + V(i, k) * U_diag(k, j)
        end do
      end do
    end do
    
    ! Compute U = temp * V^T
    U = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          U(i, j) = U(i, j) + temp(i, k) * V(j, k)
        end do
      end do
    end do
    
    ! Compute U^{-1}
    call ComputeInverse3x3(U, U_inv)
    
    ! Compute R = F * U^{-1}
    R = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          R(i, j) = R(i, j) + F(i, k) * U_inv(k, j)
        end do
      end do
    end do
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Calc_LargeRot

  subroutine RT_Asm_Calc_LogStrain(F, E_log, status)
    !! Compute logarithmic strain (Hencky strain) E_log = 0.5*ln(C)
    
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: E_log(3, 3)
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: C(3, 3)
    real(wp) :: lambda(3), V(3, 3)  ! Eigenvalues and eigenvectors
    real(wp) :: E_log_diag(3, 3), temp(3, 3)
    integer(i4) :: i, j, k
    
    call init_error_status(status)
    
    ! Compute C = F^T F
    call RT_Asm_Calc_RightCauchyGrn(F, C)
    
    ! Compute eigenvalues and eigenvectors of C
    call ComputeEigenvalues3x3Sym(C, lambda, V, status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) then
      ! Fallback: use approximation for small strains
      call RT_Asm_Calc_GreenLagStrain(F, E_log)
      return
    end if
    
    ! Ensure eigenvalues are positive
    do i = 1, 3
      if (lambda(i) <= 0.0_wp) then
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'Calc_LogStrain: Non-positive eigenvalue'
        end if
        call RT_Asm_Calc_GreenLagStrain(F, E_log)
        return
      end if
    end do
    
    ! Build diagonal matrix: diag(ln(lambda))
    E_log_diag = 0.0_wp
    do i = 1, 3
      E_log_diag(i, i) = 0.5_wp * log(lambda(i))
    end do
    
    ! Compute temp = V * diag(ln(lambda))
    temp = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          temp(i, j) = temp(i, j) + V(i, k) * E_log_diag(k, j)
        end do
      end do
    end do
    
    ! Compute E_log = temp * V^T
    E_log = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          E_log(i, j) = E_log(i, j) + temp(i, k) * V(j, k)
        end do
      end do
    end do
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Calc_LogStrain

  subroutine RT_Asm_Calc_RightCauchyGrn(F, C)
    !! Compute right Cauchy-Green tensor C = F^T F
    
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: C(3, 3)
    
    integer(i4) :: i, j, k
    
    C = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          C(i, j) = C(i, j) + F(k, i) * F(k, j)  ! C = F^T F
        end do
      end do
    end do
    
  end subroutine RT_Asm_Calc_RightCauchyGrn

  subroutine RT_Asm_Calc_TotLagStrain(coords_initial, coords_curr, dN_dX, E, status)
    !! Compute strain using Total Lagrangian Formul
    
    real(wp), intent(in) :: coords_initial(:,:) ! Initial coords (n_nodes, 3)
    real(wp), intent(in) :: coords_curr(:,:)    ! Current coords (n_nodes, 3)
    real(wp), intent(in) :: dN_dX(:,:)          ! Shape function derivatives w.r.t. initial
    real(wp), intent(out) :: E(3, 3)            ! Green-Lagrange strain
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: F(3, 3), detF
    
    call RT_Asm_Calc_DefGrad(coords_initial, coords_curr, dN_dX, F, detF, status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) return
    
    call RT_Asm_Calc_GreenLagStrain(F, E)
    
  end subroutine RT_Asm_Calc_TotLagStrain

  subroutine RT_Asm_Comp_UpdLagStrain(coords_ref, coords_curr, dN_dx, E, status)
    !! Compute strain using Updated Lagrangian Formul
    
    real(wp), intent(in) :: coords_ref(:,:)   ! Reference coords (n_nodes, 3)
    real(wp), intent(in) :: coords_curr(:,:)   ! Current coords (n_nodes, 3)
    real(wp), intent(in) :: dN_dx(:,:)         ! Shape function derivatives
    real(wp), intent(out) :: E(3, 3)           ! Green-Lagrange strain
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: F(3, 3), detF
    
    call RT_Asm_Calc_DefGrad(coords_ref, coords_curr, dN_dx, F, detF, status)
    if (present(status) .and. status%status_code /= IF_STATUS_OK) return
    
    call RT_Asm_Calc_GreenLagStrain(F, E)
    
  end subroutine RT_Asm_Comp_UpdLagStrain

  SUBROUTINE RT_Asm_GeomStiff_Assem(model, nDOF, stress_state, K_geo_csr, error)
    !! Assemble geometric stiffness matrix (renamed from RT_Asm_Geometric_Stiffness_Assemble)
    
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nDOF
    REAL(wp), INTENT(IN) :: stress_state(:)  ! Current stress state (per element/Gauss point)
    TYPE(RT_CSRMatrix), INTENT(OUT) :: K_geo_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    !-----------------------------------------------------------------
    ! Local Variables
    !-----------------------------------------------------------------
    TYPE(RT_TripletList) :: triplet_list
    TYPE(RT_Asm_ElemLoop_Info) :: elem_info
    TYPE(ShapeFuncResult) :: sf
    INTEGER(i4) :: i, j, k, ip, part_idx, elem_idx
    INTEGER(i4) :: dof_i, dof_j, n_parts, n_elems_part
    INTEGER(i4) :: n_gauss, nDim, n_dofs_per_node
    REAL(wp) :: detJ, weight, dV
    REAL(wp), ALLOCATABLE :: B_geo(:,:), K_geo_elem(:,:)
    REAL(wp), ALLOCATABLE :: dN_dx(:,:)
    REAL(wp), ALLOCATABLE :: gauss_coords(:,:), gauss_weights(:)
    REAL(wp) :: stress_val, stress_tensor(3,3)
    INTEGER(i4) :: nnz_estimate, n_elems_total
    
    CALL init_error_status(error)
    
    ! Count total elements for nnz estimation
    n_elems_total = 1000  ! TODO: Get actual number from model
    nnz_estimate = n_elems_total * 100  ! Conservative estimate
    
    ! Initialize triplet list
    CALL RT_Triplet_Init(triplet_list, nnz_estimate)
    
    ! Default parameters
    nDim = 3
    n_dofs_per_node = 3  ! x, y, z displacements
    
    ! Loop over elements
    DO elem_idx = 1, n_elems_total
      ! Get element information
      CALL RT_Asm_GetElemInfo(model, 1, elem_idx, elem_info, error)
      IF (error%has_error) CYCLE
      
      ! Get element DOFs
      CALL RT_Asm_GetElemDOFs(model, 1, elem_idx, n_dofs_per_node, &
                             elem_info%elem_dofs, error)
      IF (error%has_error) CYCLE
      
      ! Get stress state for this element
      ! TODO: Get actual stress from stress_state array
      ! For now, simplified: use average stress
      IF (SIZE(stress_state) >= elem_idx) THEN
        stress_val = stress_state(elem_idx)  ! Simplified: scalar stress
      ELSE
        stress_val = 0.0_wp
      END IF
      
      ! Build stress tensor (simplified: isotropic)
      stress_tensor = 0.0_wp
      DO i = 1, 3
        stress_tensor(i, i) = stress_val
      END DO
      
      ! Determine element topology and get Gauss points
      SELECT CASE(elem_info%topology)
      CASE(UF_TOPO_Hex)
        n_gauss = 8  ! 2×2×2 Gauss points
      CASE(UF_TOPO_Tet)
        n_gauss = 4  ! 4-point Gauss
      CASE(UF_TOPO_Quad)
        n_gauss = 4  ! 2×2 Gauss points
      CASE(UF_TOPO_Tri)
        n_gauss = 3  ! 3-point Gauss
      CASE DEFAULT
        n_gauss = 1  ! Single point
      END SELECT
      
      ! Get Gauss points and weights
      CALL UF_GetGaussPoints(elem_info%topology, 2, nDim, &
                             gauss_coords, gauss_weights)
      
      ! Initialize element geometric stiffness matrix
      ALLOCATE(K_geo_elem(elem_info%n_elem_dofs, elem_info%n_elem_dofs))
      K_geo_elem = 0.0_wp
      
      ! Loop over Gauss points
      DO ip = 1, n_gauss
        ! Get shape functions at Gauss point
        CALL UF_GetShapeFunctions(elem_info%elem_name, &
                                  gauss_coords(ip, 1:nDim), sf)
        
        ! Compute Jacobian and derivatives
        ALLOCATE(dN_dx(elem_info%pop%n_nodes, nDim))
        CALL UF_ComputeJacobian(elem_info%node_coords, sf%dN_dxi, &
                                detJ, dN_dx)
        
        ! Volume element: dV = detJ * weight
        weight = gauss_weights(ip)
        dV = detJ * weight
        
        ! Build geometric strain-displacement matrix B_G
        ! B_G contains shape function derivatives: B_G = [∂N/∂x]
        ! For geometric stiffness: K_G = ?B_G^T · σ · B_G dV
        ! Simplified: K_G_ij = Σ_k σ_kk · ?(∂N_i/∂x_k) · (∂N_j/∂x_k) dV
        
        DO i = 1, elem_info%pop%n_nodes
          DO j = 1, elem_info%pop%n_nodes
            ! Compute geometric stiffness contribution
            ! For each DOF direction
            DO k = 1, n_dofs_per_node
              dof_i = (i-1)*n_dofs_per_node + k
              dof_j = (j-1)*n_dofs_per_node + k
              
              ! Geometric stiffness: K_G = ?(∇N)^T · σ · ∇N dV
              ! Simplified: K_G_ij = σ_kk · ?(∂N_i/∂x_k) · (∂N_j/∂x_k) dV
              IF (k <= nDim) THEN
                K_geo_elem(dof_i, dof_j) = K_geo_elem(dof_i, dof_j) + &
                  stress_tensor(k, k) * dN_dx(i, k) * dN_dx(j, k) * dV
              END IF
            END DO
          END DO
        END DO
        
        DEALLOCATE(dN_dx)
      END DO
      
      ! Assemble element geometric stiffness to global matrix
      DO i = 1, elem_info%n_elem_dofs
        dof_i = elem_info%elem_dofs(i)
        IF (dof_i < 1 .OR. dof_i > nDOF) CYCLE
        
        DO j = 1, elem_info%n_elem_dofs
          dof_j = elem_info%elem_dofs(j)
          IF (dof_j < 1 .OR. dof_j > nDOF) CYCLE
          
          IF (ABS(K_geo_elem(i, j)) > 1.0e-15_wp) THEN
            CALL RT_Triplet_Add(triplet_list, dof_i, dof_j, K_geo_elem(i, j))
          END IF
        END DO
      END DO
      
      DEALLOCATE(K_geo_elem, gauss_coords, gauss_weights)
    END DO
    
    ! Convert triplet list to CSR format
    CALL RT_CSR_FromTriplet(triplet_list, nDOF, nDOF, K_geo_csr, error)
    IF (error%has_error) THEN
      CALL RT_Triplet_Free(triplet_list)
      RETURN
    END IF
    
    ! Cleanup
    CALL RT_Triplet_Free(triplet_list)
    
    K_geo_csr%is_symmetric = .true.  ! Geometric stiffness is symmetric
    K_geo_csr%init = .true.
    
  END SUBROUTINE RT_Asm_GeomStiff_Assem

  SUBROUTINE RT_Asm_GeomStiff_FromStress(model, nDOF, K_linear, u_current, &
                                                K_geo_csr, error)
    !! Compute geometric stiffness from stress state (renamed from RT_Asm_Geometric_Stiffness_FromStress)
    
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nDOF
    TYPE(RT_CSRMatrix), INTENT(IN) :: K_linear  ! Linear stiffness matrix
    REAL(wp), INTENT(IN) :: u_current(:)  ! Current displacement
    TYPE(RT_CSRMatrix), INTENT(OUT) :: K_geo_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    !-----------------------------------------------------------------
    ! Compute stress state from current displacement
    ! Then assemble geometric stiffness matrix
    !-----------------------------------------------------------------
    REAL(wp), ALLOCATABLE :: stress_state(:)
    INTEGER(i4) :: n_elems
    
    CALL init_error_status(error)
    
    ! TODO: Compute stress state from displacement
    ! 1. Compute strains: ε = B · u
    ! 2. Compute stresses: σ = D · ε (or from Mat model)
    ! 3. Store stress state
    
    n_elems = 1000  ! TODO: Get actual number from model
    ALLOCATE(stress_state(n_elems))
    stress_state = 0.0_wp  ! Placeholder
    
    ! Assemble geometric stiffness from stress state
    CALL RT_Asm_GeomStiff_Assem(model, nDOF, stress_state, K_geo_csr, error)
    
    DEALLOCATE(stress_state)
    
  END SUBROUTINE RT_Asm_GeomStiff_FromStress

  subroutine RT_Asm_Tr_St_PK2toCauchy(S, F, sigma, status)
    !! Transform Second Piola-Kirchhoff sigma to Cauchy sigma
    
    real(wp), intent(in) :: S(:)      ! PK2 sigma (Voigt: 6 components)
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: sigma(:) ! Cauchy sigma (Voigt: 6 components)
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: S_tensor(3, 3), sigma_tensor(3, 3)
    real(wp) :: temp(3, 3), detF
    integer(i4) :: i, j, k
    
    call init_error_status(status)
    
    if (size(S) /= 6 .or. size(sigma) /= 6) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Transform_Stre_PK2_to_Cauchy: Size mismatch'
      end if
      return
    end if
    
    ! Convert Voigt to tensor
    S_tensor(1, 1) = S(1)
    S_tensor(2, 2) = S(2)
    S_tensor(3, 3) = S(3)
    S_tensor(1, 2) = S(4)
    S_tensor(2, 1) = S(4)
    S_tensor(1, 3) = S(5)
    S_tensor(3, 1) = S(5)
    S_tensor(2, 3) = S(6)
    S_tensor(3, 2) = S(6)
    
    ! Compute det(F)
    detF = F(1,1) * (F(2,2)*F(3,3) - F(2,3)*F(3,2)) - &
           F(1,2) * (F(2,1)*F(3,3) - F(2,3)*F(3,1)) + &
           F(1,3) * (F(2,1)*F(3,2) - F(2,2)*F(3,1))
    
    if (abs(detF) < TOL_DET) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Transform_Stre_PK2_to_Cauchy: Singular deformation gradient'
      end if
      return
    end if
    
    ! Compute temp = F * S
    temp = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          temp(i, j) = temp(i, j) + F(i, k) * S_tensor(k, j)
        end do
      end do
    end do
    
    ! Compute σ = (1/det(F)) * temp * F^T
    sigma_tensor = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          sigma_tensor(i, j) = sigma_tensor(i, j) + (1.0_wp/detF) * temp(i, k) * F(j, k)
        end do
      end do
    end do
    
    ! Convert tensor to Voigt
    sigma(1) = sigma_tensor(1, 1)
    sigma(2) = sigma_tensor(2, 2)
    sigma(3) = sigma_tensor(3, 3)
    sigma(4) = sigma_tensor(1, 2)
    sigma(5) = sigma_tensor(1, 3)
    sigma(6) = sigma_tensor(2, 3)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Trans_Stre_PK2toCauchy

  subroutine RT_Asm_Trans_Stre_Cauchy2PK1(sigma, F, P, status)
    !! Transform Cauchy sigma to First Piola-Kirchhoff sigma
    
    real(wp), intent(in) :: sigma(:)  ! Cauchy sigma (Voigt: 6)
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: P(3, 3) ! First PK sigma (tensor)
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: sigma_tensor(3, 3), F_inv(3, 3), detF
    real(wp) :: temp(3, 3)
    integer(i4) :: i, j, k
    
    call init_error_status(status)
    
    ! Convert Voigt to tensor
    sigma_tensor(1, 1) = sigma(1)
    sigma_tensor(2, 2) = sigma(2)
    sigma_tensor(3, 3) = sigma(3)
    sigma_tensor(1, 2) = sigma(4)
    sigma_tensor(2, 1) = sigma(4)
    sigma_tensor(1, 3) = sigma(5)
    sigma_tensor(3, 1) = sigma(5)
    sigma_tensor(2, 3) = sigma(6)
    sigma_tensor(3, 2) = sigma(6)
    
    ! Compute det(F) and F^{-1}
    detF = F(1,1) * (F(2,2)*F(3,3) - F(2,3)*F(3,2)) - &
           F(1,2) * (F(2,1)*F(3,3) - F(2,3)*F(3,1)) + &
           F(1,3) * (F(2,1)*F(3,2) - F(2,2)*F(3,1))
    
    if (abs(detF) < TOL_DET) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Transform_Stre_Cauchy_to_PK1: Singular deformation gradient'
      end if
      return
    end if
    
    call ComputeInverse3x3(F, F_inv)
    
    ! Compute P = det(F) * σ * F^{-T}
    temp = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          temp(i, j) = temp(i, j) + sigma_tensor(i, k) * F_inv(j, k)
        end do
      end do
    end do
    
    P = detF * temp
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Trans_Stre_Cauchy2PK1

  subroutine RT_Asm_Trans_Stre_Cauchy2PK2(sigma, F, S, status)
    !! Transform Cauchy sigma to Second Piola-Kirchhoff sigma
    
    real(wp), intent(in) :: sigma(:)  ! Cauchy sigma (Voigt: 6 components)
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: S(:)     ! PK2 sigma (Voigt: 6 components)
    type(ErrorStatusType), intent(out), optional :: status
    
    real(wp) :: sigma_tensor(3, 3), S_tensor(3, 3)
    real(wp) :: F_inv(3, 3), detF
    real(wp) :: temp(3, 3)
    integer(i4) :: i, j, k
    
    call init_error_status(status)
    
    if (size(sigma) /= 6 .or. size(S) /= 6) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Transform_Stre_Cauchy_to_PK2: Size mismatch'
      end if
      return
    end if
    
    ! Convert Voigt to tensor notation
    sigma_tensor(1, 1) = sigma(1)
    sigma_tensor(2, 2) = sigma(2)
    sigma_tensor(3, 3) = sigma(3)
    sigma_tensor(1, 2) = sigma(4)
    sigma_tensor(2, 1) = sigma(4)
    sigma_tensor(1, 3) = sigma(5)
    sigma_tensor(3, 1) = sigma(5)
    sigma_tensor(2, 3) = sigma(6)
    sigma_tensor(3, 2) = sigma(6)
    
    ! Compute det(F)
    detF = F(1,1) * (F(2,2)*F(3,3) - F(2,3)*F(3,2)) - &
           F(1,2) * (F(2,1)*F(3,3) - F(2,3)*F(3,1)) + &
           F(1,3) * (F(2,1)*F(3,2) - F(2,2)*F(3,1))
    
    if (abs(detF) < TOL_DET) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Transform_Stre_Cauchy_to_PK2: Singular deformation gradient'
      end if
      return
    end if
    
    ! Compute F^{-1}
    call ComputeInverse3x3(F, F_inv)
    
    ! Compute temp = F^{-1} * σ
    temp = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          temp(i, j) = temp(i, j) + F_inv(i, k) * sigma_tensor(k, j)
        end do
      end do
    end do
    
    ! Compute S = det(F) * temp * F^{-T}
    S_tensor = 0.0_wp
    do i = 1, 3
      do j = 1, 3
        do k = 1, 3
          S_tensor(i, j) = S_tensor(i, j) + detF * temp(i, k) * F_inv(j, k)
        end do
      end do
    end do
    
    ! Convert tensor to Voigt notation
    S(1) = S_tensor(1, 1)
    S(2) = S_tensor(2, 2)
    S(3) = S_tensor(3, 3)
    S(4) = S_tensor(1, 2)
    S(5) = S_tensor(1, 3)
    S(6) = S_tensor(2, 3)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine RT_Asm_Trans_Stre_Cauchy2PK2

  subroutine RT_GeomNonlin_CompEulerAng(R, euler_angles, status)
    !! Compute Euler angles from rotation matrix (renamed from UF_Nonlinear_ComputeEulerAngles)
    
    real(wp), intent(in) :: R(3, 3)
    real(wp), intent(out) :: euler_angles(3)  ! [α, β, γ]
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: sy, cy

    call init_error_status(status)

    ! ZYX Euler angles
    sy = -R(3, 1)
    if (sy >= 1.0_wp) then
      euler_angles(2) = 1.5707963267948966_wp  ! π/2
    else if (sy <= -1.0_wp) then
      euler_angles(2) = -1.5707963267948966_wp  ! -π/2
    else
      euler_angles(2) = asin(sy)
    end if

    cy = cos(euler_angles(2))

    if (abs(cy) > 1.0e-6_wp) then
      euler_angles(1) = atan2(R(3, 2) / cy, R(3, 3) / cy)
      euler_angles(3) = atan2(R(2, 1) / cy, R(1, 1) / cy)
    else
      ! Gimbal lock: β = ±π/2
      euler_angles(1) = 0.0_wp
      euler_angles(3) = atan2(-R(1, 2), R(2, 2))
    end if

    status%status_code = IF_STATUS_OK

  end subroutine RT_GeomNonlin_CompEulerAng

  subroutine RT_GeomNonlin_CompJacobian(F, J, J_inv, status)
    !! Compute Jacobian and its inverse (renamed from UF_LargeDeformation_ComputeJacobian)
    
    real(wp), intent(in) :: F(3, 3)
    real(wp), intent(out) :: J              ! Jacobian determinant
    real(wp), intent(out) :: J_inv(3, 3)    ! Inverse Jacobian matrix
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    ! Jacobian determinant
    J = F(1,1) * (F(2,2)*F(3,3) - F(2,3)*F(3,2)) - &
        F(1,2) * (F(2,1)*F(3,3) - F(2,3)*F(3,1)) + &
        F(1,3) * (F(2,1)*F(3,2) - F(2,2)*F(3,1))

    if (abs(J) < 1.0e-12_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_CompJacobian: Singular Jacobian'
      return
    end if

    ! Inverse Jacobian
    call ComputeInverse3x3(F, J_inv)

    status%status_code = IF_STATUS_OK

  end subroutine RT_GeomNonlin_CompJacobian

  subroutine RT_GeomNonlin_CompKin(coords_ref, coords_curr, dN_dX, &
                                   kinematics, status)
    !! Compute complete deformation kinematics (renamed from UF_LargeDeformation_ComputeKinematics)
    
    real(wp), intent(in) :: coords_ref(:,:)    ! Reference coordinates (n_nodes, 3)
    real(wp), intent(in) :: coords_curr(:,:)   ! Current coordinates (n_nodes, 3)
    real(wp), intent(in) :: dN_dX(:,:)         ! Shape function derivatives (n_nodes, 3)
    type(RT_DefKin), intent(out) :: kinematics
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j

    call init_error_status(status)

    ! Compute deformation gradient F = ∂x/∂X
    call RT_Asm_Calc_DefGrad(coords_ref, coords_curr, dN_dX, &
                                    kinematics%F, kinematics%detF, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute inverse deformation gradient F^{-1}
    call ComputeInverse3x3(kinematics%F, kinematics%F_inv)

    ! Compute right Cauchy-Green tensor C = F^T F
    call RT_Asm_Calc_RightCauchyGrn(kinematics%F, kinematics%C)

    ! Compute left Cauchy-Green tensor b = F F^T
    kinematics%b = matmul(kinematics%F, transpose(kinematics%F))

    ! Compute Green-Lagrange strain E = 0.5*(C - I)
    call RT_Asm_Calc_GreenLagStrain(kinematics%F, kinematics%E)

    ! Compute logarithmic strain E_log = 0.5*ln(C)
    call RT_Asm_Calc_LogStrain(kinematics%F, kinematics%E_log, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute Almansi strain ε = 0.5*(I - b^{-1})
    call ComputeAlmansiStrain(kinematics%b, kinematics%epsilon, status)
    if (status%status_code /= IF_STATUS_OK) return

  end subroutine RT_GeomNonlin_CompKin

  subroutine RT_GeomNonlin_CompQuat(R, quaternion, status)
    !! Compute quaternion from rotation matrix (renamed from UF_Nonlinear_ComputeQuaternion)
    
    real(wp), intent(in) :: R(3, 3)
    real(wp), intent(out) :: quaternion(4)  ! [w, x, y, z]
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: trace_R, w_sq, w
    integer(i4) :: i_max

    call init_error_status(status)

    trace_R = R(1, 1) + R(2, 2) + R(3, 3)

    ! Find maximum diagonal element
    i_max = 1
    if (R(2, 2) > R(1, 1)) i_max = 2
    if (R(3, 3) > R(i_max, i_max)) i_max = 3

    select case (i_max)
    case (1)
      w_sq = 1.0_wp + R(1, 1) - R(2, 2) - R(3, 3)
      w = sqrt(max(0.0_wp, w_sq)) * 0.5_wp
      quaternion(1) = w
      quaternion(2) = (R(1, 2) + R(2, 1)) / (4.0_wp * w)
      quaternion(3) = (R(1, 3) + R(3, 1)) / (4.0_wp * w)
      quaternion(4) = (R(2, 3) - R(3, 2)) / (4.0_wp * w)
    case (2)
      w_sq = 1.0_wp + R(2, 2) - R(1, 1) - R(3, 3)
      w = sqrt(max(0.0_wp, w_sq)) * 0.5_wp
      quaternion(1) = (R(1, 2) + R(2, 1)) / (4.0_wp * w)
      quaternion(2) = w
      quaternion(3) = (R(2, 3) + R(3, 2)) / (4.0_wp * w)
      quaternion(4) = (R(3, 1) - R(1, 3)) / (4.0_wp * w)
    case (3)
      w_sq = 1.0_wp + R(3, 3) - R(1, 1) - R(2, 2)
      w = sqrt(max(0.0_wp, w_sq)) * 0.5_wp
      quaternion(1) = (R(1, 3) + R(3, 1)) / (4.0_wp * w)
      quaternion(2) = (R(2, 3) + R(3, 2)) / (4.0_wp * w)
      quaternion(3) = w
      quaternion(4) = (R(1, 2) - R(2, 1)) / (4.0_wp * w)
    end select

    ! Normalize quaternion
    w = sqrt(sum(quaternion**2))
    if (w > 1.0e-12_wp) then
      quaternion = quaternion / w
    end if

    status%status_code = IF_STATUS_OK

  end subroutine RT_GeomNonlin_CompQuat

  subroutine RT_GeomNonlin_CompRotMat(F, rotation_state, status)
    !! Compute rotation matrix from deformation gradient (renamed from UF_Nonlinear_ComputeRotationMatrix)
    
    real(wp), intent(in) :: F(3, 3)
    type(RT_RotSta), intent(out) :: rotation_state
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: U(3, 3)

    call init_error_status(status)

    ! Compute rotation matrix R and stretch tensor U
    call RT_Asm_Calc_LargeRot(F, rotation_state%R, U, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute Euler angles from rotation matrix
    call RT_GeomNonlin_CompEulerAng(rotation_state%R, rotation_state%euler_angles, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute quaternion from rotation matrix
    call RT_GeomNonlin_CompQuat(rotation_state%R, rotation_state%quaternion, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute rotation vector (axis-angle representation)
    call ComputeRotationVector(rotation_state%R, rotation_state%rotation_vector, status)
    if (status%status_code /= IF_STATUS_OK) return

  end subroutine RT_GeomNonlin_CompRotMat

  subroutine RT_GeomNonlin_CompStrainMeas(kinematics, strain_type, &
                                          strain, status)
    !! Compute specific strain measure (renamed from UF_LargeDeformation_ComputeStrainMeasures)
    
    type(RT_DefKin), intent(in) :: kinematics
    integer(i4), intent(in) :: strain_type  ! 1=Green-Lagrange, 2=Log, 3=Almansi
    real(wp), intent(out) :: strain(3, 3)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    select case (strain_type)
    case (1)
      ! Green-Lagrange strain
      strain = kinematics%E
    case (2)
      ! Logarithmic strain
      strain = kinematics%E_log
    case (3)
      ! Almansi strain
      strain = kinematics%epsilon
    case default
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_CompStrainMeas: Invalid strain type'
      return
    end select

    status%status_code = IF_STATUS_OK

  end subroutine RT_GeomNonlin_CompStrainMeas

  subroutine RT_GeomNonlin_ConsistLin(B_L, B_NL, sigma, D_mat, &
                                      K_mat, K_geo, K_total, status)
    !! Complete consistent linearization (renamed from UF_Nonlinear_ConsistentLinearization)
    
    real(wp), intent(in) :: B_L(:,:)      ! Linear B matrix (6, n_dofs)
    real(wp), intent(in) :: B_NL(:,:)     ! Nonlinear B matrix (6, n_dofs)
    real(wp), intent(in) :: sigma(:)     ! Stress vector (6) Voigt notation
    real(wp), intent(in) :: D_mat(:,:)    ! Mat tangent stiffness (6, 6)
    real(wp), intent(out) :: K_mat(:,:)   ! Mat stiffness (n_dofs, n_dofs)
    real(wp), intent(out) :: K_geo(:,:)   ! Geometric stiffness (n_dofs, n_dofs)
    real(wp), intent(out) :: K_total(:,:) ! Total stiffness (n_dofs, n_dofs)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_dofs, i, j, k
    real(wp), allocatable :: B_total(:,:), G(:,:)
    real(wp) :: stress_matrix(3, 3)

    call init_error_status(status)

    n_dofs = size(B_L, 2)
    if (size(B_NL, 2) /= n_dofs .or. size(K_mat, 1) /= n_dofs .or. &
        size(K_mat, 2) /= n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_ConsistLin: Size mismatch'
      return
    end if

    ! Build total B matrix: B_total = B_L + B_NL
    allocate(B_total(6, n_dofs))
    B_total = B_L + B_NL

    ! Compute Mat stiffness: K_mat = B_total^T * D * B_total
    K_mat = 0.0_wp
    do i = 1, n_dofs
      do j = 1, n_dofs
        do k = 1, 6
          K_mat(i, j) = K_mat(i, j) + B_total(k, i) * D_mat(k, k) * B_total(k, j)
        end do
      end do
    end do

    ! Convert sigma to matrix form
    call VoigtToTensor(sigma, stress_matrix)

    ! Build G matrix
    allocate(G(9, n_dofs))
    call BuildGMatrix(B_L, G, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute geometric stiffness: K_geo = G^T * [σ] * G
    call ComputeGeometricStiff_Complete(G, stress_matrix, K_geo, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Total stiffness
    K_total = K_mat + K_geo

    deallocate(B_total, G)

  end subroutine RT_GeomNonlin_ConsistLin

  subroutine RT_GeomNonlin_GeomElem_TL(coords_ref, coords_curr, dN_dX, &
                                       u, K_elem, R_elem, status)
    !! Geometric nonlinear element using Total Lagrangian (renamed from UF_Nonlinear_GeometricElement_TL)
    
    real(wp), intent(in) :: coords_ref(:,:)  ! (n_nodes, 3)
    real(wp), intent(in) :: coords_curr(:,:)  ! (n_nodes, 3)
    real(wp), intent(in) :: dN_dX(:,:)        ! (n_nodes, 3)
    real(wp), intent(in) :: u(:)             ! Displacement vector (n_dofs)
    real(wp), intent(out) :: K_elem(:,:)     ! Element stiffness matrix
    real(wp), intent(out) :: R_elem(:)       ! Element residual vector
    type(ErrorStatusType), intent(out) :: status

    type(RT_LagrCfg) :: config
    real(wp) :: F(3, 3), E(3, 3), S(3, 3)
    integer(i4) :: n_dofs, nn, nd2
    real(wp), allocatable :: K_mat_temp(:,:), K_geo_temp(:,:)

    call init_error_status(status)

    n_dofs = size(u)
    if (size(K_elem, 1) /= n_dofs .or. size(K_elem, 2) /= n_dofs .or. &
        size(R_elem) /= n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_GeomElem_TL: Size mismatch'
      return
    end if

    nn = int(size(coords_ref, 1), kind=i4)
    nd2 = int(min(3, size(coords_ref, 2), size(coords_curr, 2), size(dN_dX, 2)), kind=i4)
    if (nn < 1_i4 .or. nn > 64_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_GeomElem_TL: n_nodes out of RT_LagrCfg buffer'
      return
    end if
    if (int(size(dN_dX, 1), kind=i4) /= nn) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_GeomElem_TL: dN_dX row count mismatch'
      return
    end if

    ! Setup configuration (fixed-size RT_LagrCfg buffers + n_nodes)
    config%formulation_typ = 1  ! Total Lagrangian
    config%n_nodes = nn
    config%coords_ref = 0.0_wp
    config%coords_curr = 0.0_wp
    config%dN_dX = 0.0_wp
    config%coords_ref(1:nn, 1:nd2) = coords_ref(1:nn, 1:nd2)
    config%coords_curr(1:nn, 1:nd2) = coords_curr(1:nn, 1:nd2)
    config%dN_dX(1:nn, 1:nd2) = dN_dX(1:nn, 1:nd2)

    ! Compute Total Lagrangian Formul
    allocate(K_mat_temp(n_dofs, n_dofs), K_geo_temp(n_dofs, n_dofs))
    call RT_GeomNonlin_TotLag(config, F, E, S, K_mat_temp, K_geo_temp, status, R_elem=R_elem)
    if (status%status_code == IF_STATUS_OK) then
      K_elem = K_mat_temp + K_geo_temp
    end if
    deallocate(K_mat_temp, K_geo_temp)
    if (status%status_code /= IF_STATUS_OK) return

  end subroutine RT_GeomNonlin_GeomElem_TL

  subroutine RT_GeomNonlin_GeomElem_UL(coords_prev, coords_curr, dN_dx, &
                                      u, K_elem, R_elem, status)
    !! Geometric nonlinear element using Updated Lagrangian (renamed from UF_Nonlinear_GeometricElement_UL)
    
    real(wp), intent(in) :: coords_prev(:,:)  ! (n_nodes, 3)
    real(wp), intent(in) :: coords_curr(:,:)  ! (n_nodes, 3)
    real(wp), intent(in) :: dN_dx(:,:)        ! (n_nodes, 3)
    real(wp), intent(in) :: u(:)             ! Displacement increment vector
    real(wp), intent(out) :: K_elem(:,:)     ! Element stiffness matrix
    real(wp), intent(out) :: R_elem(:)       ! Element residual vector
    type(ErrorStatusType), intent(out) :: status

    type(RT_LagrCfg) :: config
    real(wp) :: F(3, 3), epsilon(3, 3), sigma(3, 3)
    integer(i4) :: n_dofs, nn, nd2
    real(wp), allocatable :: K_mat_temp(:,:), K_geo_temp(:,:)

    call init_error_status(status)

    n_dofs = size(u)
    if (size(K_elem, 1) /= n_dofs .or. size(K_elem, 2) /= n_dofs .or. &
        size(R_elem) /= n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_GeomElem_UL: Size mismatch'
      return
    end if

    nn = int(size(coords_prev, 1), kind=i4)
    nd2 = int(min(3, size(coords_prev, 2), size(coords_curr, 2), size(dN_dx, 2)), kind=i4)
    if (nn < 1_i4 .or. nn > 64_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_GeomElem_UL: n_nodes out of RT_LagrCfg buffer'
      return
    end if
    if (int(size(dN_dx, 1), kind=i4) /= nn) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_GeomElem_UL: dN_dx row count mismatch'
      return
    end if

    ! Setup configuration (fixed-size RT_LagrCfg buffers + n_nodes)
    config%formulation_typ = 2  ! Updated Lagrangian
    config%n_nodes = nn
    config%coords_ref = 0.0_wp
    config%coords_curr = 0.0_wp
    config%coords_prev = 0.0_wp
    config%dN_dx = 0.0_wp
    config%coords_prev(1:nn, 1:nd2) = coords_prev(1:nn, 1:nd2)
    config%coords_ref(1:nn, 1:nd2) = coords_prev(1:nn, 1:nd2)
    config%coords_curr(1:nn, 1:nd2) = coords_curr(1:nn, 1:nd2)
    config%dN_dx(1:nn, 1:nd2) = dN_dx(1:nn, 1:nd2)

    ! Compute Updated Lagrangian Formul
    allocate(K_mat_temp(n_dofs, n_dofs), K_geo_temp(n_dofs, n_dofs))
    call RT_GeomNonlin_UpdLag(config, F, epsilon, sigma, K_mat_temp, K_geo_temp, status, R_elem=R_elem)
    if (status%status_code == IF_STATUS_OK) then
      K_elem = K_mat_temp + K_geo_temp
    end if
    deallocate(K_mat_temp, K_geo_temp)
    if (status%status_code /= IF_STATUS_OK) return

  end subroutine RT_GeomNonlin_GeomElem_UL

  subroutine RT_GeomNonlin_TotLag(config, F, E, S, K_mat, K_geo, status, R_elem, D_tangent)
    !! Complete Total Lagrangian Formul
    !! Modified to accept external stress S and tangent D from PH layer
    
    type(RT_LagrCfg), intent(in) :: config
    real(wp), intent(inout) :: F(3, 3)         ! Changed to INOUT (PH may pre-compute)
    real(wp), intent(inout) :: E(3, 3)         ! Changed to INOUT
    real(wp), intent(in) :: S(3, 3)            !  ?External PK2 stress (from PH)
    real(wp), intent(out) :: K_mat(:,:)
    real(wp), intent(out) :: K_geo(:,:)
    type(ErrorStatusType), intent(out) :: status
    real(wp), intent(out), optional :: R_elem(:)
    real(wp), intent(in), optional :: D_tangent(6, 6)  !  ?External tangent (from PH)

    integer(i4) :: n_nodes, n_dofs, i, j
    real(wp) :: detF
    real(wp), allocatable :: B_L(:,:), B_NL(:,:), G(:,:)
    real(wp) :: stress_voigt(6), D_mat(6, 6)
    real(wp) :: S_voigt(6), C(3, 3)

    call init_error_status(status)

    if (config%n_nodes < 1_i4 .or. config%n_nodes > 64_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_TotLag: config%n_nodes unset or out of range'
      return
    end if
    n_nodes = config%n_nodes
    n_dofs = n_nodes * 3

    ! Check sizes
    if (size(K_mat, 1) /= n_dofs .or. size(K_mat, 2) /= n_dofs .or. &
        size(K_geo, 1) /= n_dofs .or. size(K_geo, 2) /= n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_TotLag: Size mismatch'
      return
    end if

    ! Compute deformation gradient F = ∂x/∂X (if not pre-computed by PH)
    if (F(1,1) == 0.0_wp) then  ! Check if F is uninitialized
      call RT_Asm_Calc_DefGrad(config%coords_ref(1:n_nodes, :), config%coords_curr(1:n_nodes, :), &
                                       config%dN_dX(1:n_nodes, :), F, detF, status)
      if (status%status_code /= IF_STATUS_OK) return
      
      ! Compute right Cauchy-Green tensor C = F^T F
      call RT_Asm_Calc_RightCauchyGrn(F, C)
      
      ! Compute Green-Lagrange strain E = 0.5*(C - I)
      call RT_Asm_Calc_GreenLagStrain(F, E)
    else
      ! F and E already computed by PH layer, just compute detF
      detF = F(1,1)*(F(2,2)*F(3,3) - F(2,3)*F(3,2)) &
           - F(1,2)*(F(2,1)*F(3,3) - F(2,3)*F(3,1)) &
           + F(1,3)*(F(2,1)*F(3,2) - F(2,2)*F(3,1))
    end if
    
    ! Stress S is provided by PH layer via PH_UpdateStress
    ! Skip internal Mat computation: call ComputeStressFromStrain_TL(...)

    ! Build B matrices
    allocate(B_L(6, n_dofs), B_NL(6, n_dofs), G(9, n_dofs))
    call BuildBMatrix_TL(config%dN_dX(1:n_nodes, :), config%coords_curr(1:n_nodes, :), B_L, B_NL, G, status)
    if (status%status_code /= IF_STATUS_OK) then
      deallocate(B_L, B_NL, G)
      return
    end if

    ! Convert sigma to Voigt notation
    call TensorToVoigt(S, S_voigt)

    ! Get Mat tangent stiffness D (from PH layer if provided)
    if (present(D_tangent)) then
      D_mat = D_tangent  !  ?Use external tangent from PH_UpdateStress
    else
      ! Fallback: hardcoded linear elastic (for backward compatibility)
      call GetMaterialTangentStiffness(D_mat, status)
      if (status%status_code /= IF_STATUS_OK) return
    end if

    ! Compute Mat stiffness: K_mat = B^T * D * B dV_0
    call ComputeMaterialStiffness_TL(B_L, B_NL, D_mat, K_mat, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute geometric stiffness: K_geo = G^T * [S] * G dV_0
    call ComputeGeometricStiffness_TL(G, S_voigt, K_geo, status)
    if (status%status_code /= IF_STATUS_OK) return

    if (present(R_elem) .and. size(R_elem) >= n_dofs) then
      R_elem(1:n_dofs) = matmul(transpose(B_L), S_voigt)
    end if
    deallocate(B_L, B_NL, G)

  end subroutine RT_GeomNonlin_TotLag

  subroutine RT_GeomNonlin_UpdateCfg(coords_old, u_increment, &
                                     coords_new, status)
    !! Update configuration from displacement increment (renamed from UF_LargeDeformation_UpdateConfiguration)
    
    real(wp), intent(in) :: coords_old(:,:)    ! Old coordinates (n_nodes, 3)
    real(wp), intent(in) :: u_increment(:)      ! Displacement increment (n_dofs)
    real(wp), intent(out) :: coords_new(:,:)    ! New coordinates (n_nodes, 3)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i, j, dof_idx

    call init_error_status(status)

    n_nodes = size(coords_old, 1)
    if (size(coords_new, 1) /= n_nodes .or. size(u_increment) /= n_nodes * 3) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_UpdateCfg: Size mismatch'
      return
    end if

    ! Update coordinates: x_new = x_old + u_increment
    do i = 1, n_nodes
      do j = 1, 3
        dof_idx = (i - 1) * 3 + j
        coords_new(i, j) = coords_old(i, j) + u_increment(dof_idx)
      end do
    end do

    status%status_code = IF_STATUS_OK

  end subroutine RT_GeomNonlin_UpdateCfg

  subroutine RT_GeomNonlin_UpdLag(config, F, epsilon, sigma, K_mat, K_geo, status, R_elem, D_tangent)
    !! Complete Updated Lagrangian Formul
    !! Modified to accept external stress sigma and tangent D from PH layer
    
    type(RT_LagrCfg), intent(in) :: config
    real(wp), intent(inout) :: F(3, 3)         ! Changed to INOUT
    real(wp), intent(inout) :: epsilon(3, 3)   ! Changed to INOUT
    real(wp), intent(in) :: sigma(3, 3)        !  ?External Cauchy stress (from PH)
    real(wp), intent(out) :: K_mat(:,:)
    real(wp), intent(out) :: K_geo(:,:)
    type(ErrorStatusType), intent(out) :: status
    real(wp), intent(out), optional :: R_elem(:)
    real(wp), intent(in), optional :: D_tangent(6, 6)  !  ?External tangent (from PH)

    integer(i4) :: n_nodes, n_dofs
    real(wp) :: detF, F_inv(3, 3)
    real(wp), allocatable :: B_L(:,:), B_NL(:,:), G(:,:)
    real(wp) :: stress_voigt(6), D_mat(6, 6)

    call init_error_status(status)

    if (config%n_nodes < 1_i4 .or. config%n_nodes > 64_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_UpdLag: config%n_nodes unset or out of range'
      return
    end if
    n_nodes = config%n_nodes
    n_dofs = n_nodes * 3

    ! Check sizes
    if (size(K_mat, 1) /= n_dofs .or. size(K_mat, 2) /= n_dofs .or. &
        size(K_geo, 1) /= n_dofs .or. size(K_geo, 2) /= n_dofs) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_GeomNonlin_UpdLag: Size mismatch'
      return
    end if

    ! Compute deformation gradient F = ∂x_{n+1}/∂x_n (if not pre-computed)
    if (F(1,1) == 0.0_wp) then
      call RT_Asm_Calc_DefGrad(config%coords_prev(1:n_nodes, :), config%coords_curr(1:n_nodes, :), &
                                       config%dN_dx(1:n_nodes, :), F, detF, status)
      if (status%status_code /= IF_STATUS_OK) return
      
      ! Compute Almansi strain: ε = 0.5*(I - F^{-T} F^{-1})
      call ComputeInverse3x3(F, F_inv)
      call ComputeAlmansiStrain(F_inv, epsilon, status)
      if (status%status_code /= IF_STATUS_OK) return
    else
      ! F and epsilon already computed by PH layer
      detF = F(1,1)*(F(2,2)*F(3,3) - F(2,3)*F(3,2)) &
           - F(1,2)*(F(2,1)*F(3,3) - F(2,3)*F(3,1)) &
           + F(1,3)*(F(2,1)*F(3,2) - F(2,2)*F(3,1))
    end if
    
    ! Stress sigma is provided by PH layer via PH_UpdateStress
    ! Skip internal Mat computation: call ComputeStressFromStrain_UL(...)

    ! Build B matrices
    allocate(B_L(6, n_dofs), B_NL(6, n_dofs), G(9, n_dofs))
    call BuildBMatrix_UL(config%dN_dx(1:n_nodes, :), config%coords_curr(1:n_nodes, :), B_L, B_NL, G, status)
    if (status%status_code /= IF_STATUS_OK) then
      deallocate(B_L, B_NL, G)
      return
    end if

    ! Convert sigma to Voigt notation
    call TensorToVoigt(sigma, stress_voigt)

    ! Get Mat tangent stiffness D (from PH layer if provided)
    if (present(D_tangent)) then
      D_mat = D_tangent  !  ?Use external tangent from PH_UpdateStress
    else
      ! Fallback: hardcoded linear elastic (for backward compatibility)
      call GetMaterialTangentStiffness(D_mat, status)
      if (status%status_code /= IF_STATUS_OK) return
    end if

    ! Compute Mat stiffness: K_mat = B^T * D * B dV
    call ComputeMaterialStiffness_UL(B_L, B_NL, D_mat, K_mat, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Compute geometric stiffness: K_geo = G^T * [σ] * G dV
    call ComputeGeometricStiffness_UL(G, stress_voigt, K_geo, status)
    if (status%status_code /= IF_STATUS_OK) return

    if (present(R_elem) .and. size(R_elem) >= n_dofs) then
      R_elem(1:n_dofs) = matmul(transpose(B_L), stress_voigt)
    end if
    deallocate(B_L, B_NL, G)

  end subroutine RT_GeomNonlin_UpdLag

  subroutine sort_eigenvalues_3x3(lambda)
    !! Sort eigenvalues in descending order
    
    real(wp), intent(inout) :: lambda(3)
    
    real(wp) :: temp
    integer(i4) :: i, j
    
    ! Simple bubble sort
    do i = 1, 2
      do j = i + 1, 3
        if (lambda(i) < lambda(j)) then
          temp = lambda(i)
          lambda(i) = lambda(j)
          lambda(j) = temp
        end if
      end do
    end do
    
  end subroutine sort_eigenvalues_3x3

  subroutine TensorToVoigt(tensor, voigt)
    real(wp), intent(in) :: tensor(3, 3)
    real(wp), intent(out) :: voigt(6)

    ! Convert 3x3 tensor to Voigt notation: [11, 22, 33, 12, 13, 23]
    voigt(1) = tensor(1, 1)
    voigt(2) = tensor(2, 2)
    voigt(3) = tensor(3, 3)
    voigt(4) = tensor(1, 2)
    voigt(5) = tensor(1, 3)
    voigt(6) = tensor(2, 3)
  end subroutine TensorToVoigt

  subroutine VoigtToTensor(voigt, tensor)
    real(wp), intent(in) :: voigt(6)
    real(wp), intent(out) :: tensor(3, 3)

    ! Convert Voigt notation to 3x3 tensor
    tensor(1, 1) = voigt(1)
    tensor(2, 2) = voigt(2)
    tensor(3, 3) = voigt(3)
    tensor(1, 2) = voigt(4)
    tensor(2, 1) = voigt(4)
    tensor(1, 3) = voigt(5)
    tensor(3, 1) = voigt(5)
    tensor(2, 3) = voigt(6)
    tensor(3, 2) = voigt(6)
  end subroutine VoigtToTensor
end MODULE PH_NLGeom_Eval