!===============================================================================
! MODULE: PH_Mat_hTensor
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Shared
! BRIEF:  Tensor operations for physics-layer constitutive computation.
!   W1: math-only — does not read **PH_Mat_Desc**; kernels (J2, Neo-Hookean, …) combine these ops with **desc%props**.
!===============================================================================
!
! These functions are used primarily in L4_PH layer for physical element computations.
! Theory:  Tensor operations: C = A·B (dot product), A:B = Σ_ij A_ij·B_ji (scalar product),
!          polar decomposition: F = R·U = V·R, Voigt notation: σ_ij (3×3) ?σ_α (6 components).
! Status:  CORE | Last verified: 2026-03-03
!
! Contents (A-Z):
!   Functions:
!     - PH_Math_Tensor_DotProduct - Tensor dot product
!     - PH_Math_Tensor_ScalarProduct - Tensor scalar product (double contraction)
!     - PH_Math_Tensor_DyadicProduct - Dyadic product of two vectors
!   Subroutines:
!     - PH_Math_Tensor_ComponentTransform - Covariant to contravariant transform
!     - PH_Math_Tensor_MetricTensor - Compute metric tensor from base vectors
!     - PH_Math_Tensor_Rotation - Rotate tensor by rotation matrix
!     - PH_Math_Tensor_Invariants - Compute tensor invariants (I1, I2, I3)
!     - PH_Math_Tensor_PolarDecomposition - Polar decomposition of deformation gradient
!     - PH_Math_Tensor_TensorToVoigt - Convert tensor to Voigt notation
!     - PH_Math_Tensor_VoigtToTensor - Convert Voigt notation to tensor
!===============================================================================

MODULE PH_Mat_hTensor
    USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, THIRD, EPS, TOLERANCE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Math_Util, ONLY: IF_Math_Mtx_Transpose, IF_Math_Mtx_Inverse, &
                            IF_Math_Mtx_Determinant, IF_Math_DotProduct
    USE NM_Mtx_Math, ONLY: NM_Math_Mtx_Eigenvalues
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Math_Tensor_DotProduct
    PUBLIC :: PH_Math_Tensor_ScalarProduct
    PUBLIC :: PH_Math_Tensor_DyadicProduct
    PUBLIC :: PH_Math_Tensor_ComponentTransform
    PUBLIC :: PH_Math_Tensor_MetricTensor
    PUBLIC :: PH_Math_Tensor_Rotation
    PUBLIC :: PH_Math_Tensor_Invariants
    PUBLIC :: PH_Math_Tensor_PolarDecomposition
    PUBLIC :: PH_Math_Tensor_TensorToVoigt
    PUBLIC :: PH_Math_Tensor_VoigtToTensor
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Math_Tensor_Args
  TYPE :: PH_Math_Tensor_Args
  ! Purpose: INTF-style argument bundle; see module header.
  ! Theory:
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
  END TYPE PH_Math_Tensor_Args


CONTAINS

    ! ==========================================================================
    ! TENSOR BASIC OPERATIONS
    ! ==========================================================================

    FUNCTION PH_Math_Tensor_DotProduct(A, B) RESULT(C)
        REAL(wp), INTENT(IN) :: A(3,3), B(3,3)
        REAL(wp) :: C(3,3)

        INTEGER(i4) :: i, j, k

        DO i = 1, 3
            DO j = 1, 3
                C(i,j) = ZERO
                DO k = 1, 3
                    C(i,j) = C(i,j) + A(i,k) * B(k,j)
                END DO
            END DO
        END DO
    END FUNCTION PH_Math_Tensor_DotProduct

    FUNCTION PH_Math_Tensor_ScalarProduct(A, B) RESULT(scalar)
        REAL(wp), INTENT(IN) :: A(3,3), B(3,3)
        REAL(wp) :: scalar

        INTEGER(i4) :: i, j

        ! Scalar product (double contraction): A : B = Σ_ij A_ij · B_ji
        scalar = ZERO
        DO i = 1, 3
            DO j = 1, 3
                scalar = scalar + A(i,j) * B(j,i)
            END DO
        END DO
    END FUNCTION PH_Math_Tensor_ScalarProduct

    FUNCTION PH_Math_Tensor_DyadicProduct(a, b) RESULT(tens)
        REAL(wp), INTENT(IN) :: a(3), b(3)
        REAL(wp) :: tens(3,3)

        INTEGER(i4) :: i, j

        DO i = 1, 3
            DO j = 1, 3
                tens(i,j) = a(i) * b(j)
            END DO
        END DO
    END FUNCTION PH_Math_Tensor_DyadicProduct

    ! ==========================================================================
    ! TENSOR TRANSFORMATIONS
    ! ==========================================================================

    SUBROUTINE PH_Math_Tensor_ComponentTransform(tensor_covariant, metric_tensor, &
                                                 tensor_contravariant, status)
        REAL(wp), INTENT(IN) :: tensor_covariant(3,3), metric_tensor(3,3)
        REAL(wp), INTENT(OUT) :: tensor_contravariant(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: ginv(3,3)
        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        ! Compute inverse of metric tensor
        CALL IF_Math_Mtx_Inverse(metric_tensor, ginv, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%message = 'PH_Math_Tensor_ComponentTransform: Failed to invert metric tensor'
            RETURN
        END IF

        ! Transform: T^ij = g^ik g^jl T_kl
        DO i = 1, 3
            DO j = 1, 3
                tensor_contravariant(i,j) = ZERO
                DO k = 1, 3
                    tensor_contravariant(i,j) = tensor_contravariant(i,j) + &
                        ginv(i,k) * tensor_covariant(k,j)
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_ComponentTransform

    SUBROUTINE PH_Math_Tensor_MetricTensor(base_vectors, metric_tensor, status)
        REAL(wp), INTENT(IN) :: base_vectors(3,3)
        REAL(wp), INTENT(OUT) :: metric_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! Metric tensor: g_ij = e_i · e_j
        DO i = 1, 3
            DO j = 1, 3
                metric_tensor(i,j) = IF_Math_DotProduct(base_vectors(:,i), base_vectors(:,j))
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_MetricTensor

    SUBROUTINE PH_Math_Tensor_Rotation(tensor, rotation, rotated_tensor, status)
        REAL(wp), INTENT(IN) :: tensor(3,3), rotation(3,3)
        REAL(wp), INTENT(OUT) :: rotated_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: tmp(3,3), Rt(3,3)

        CALL init_error_status(status)

        ! Rotated tensor: T' = R · T · R^T
        tmp = PH_Math_Tensor_DotProduct(rotation, tensor)
        Rt = IF_Math_Mtx_Transpose(rotation)
        rotated_tensor = PH_Math_Tensor_DotProduct(tmp, Rt)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_Rotation

    SUBROUTINE PH_Math_Tensor_Invariants(tensor, I1, I2, I3, status)
        REAL(wp), INTENT(IN) :: tensor(3,3)
        REAL(wp), INTENT(OUT) :: I1, I2, I3
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: T2(3,3)

        CALL init_error_status(status)

        ! First invariant: I ?= tr(T) = T₁₁ + T₂₂ + T₃₃
        I1 = tensor(1,1) + tensor(2,2) + tensor(3,3)

        ! Second invariant: I ?= ½[tr(T)² - tr(T²)]
        T2 = PH_Math_Tensor_DotProduct(tensor, tensor)
        I2 = HALF * (I1 * I1 - (T2(1,1) + T2(2,2) + T2(3,3)))

        ! Third invariant: I ?= det(T)
        CALL IF_Math_Mtx_Determinant(tensor, I3, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%message = 'PH_Math_Tensor_Invariants: Failed to compute determinant'
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_Invariants

    ! ==========================================================================
    ! TENSOR DECOMPOSITION
    ! ==========================================================================

    SUBROUTINE PH_Math_Tensor_PolarDecomposition(F, R, U, V, status)
        REAL(wp), INTENT(IN) :: F(3,3)
        REAL(wp), INTENT(OUT) :: R(3,3), U(3,3), V(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: C(3,3), Ft(3,3), tmp(3,3)
        REAL(wp) :: eigvals(3), eigvecs(3,3)
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Compute right Cauchy-Green tensor: C = F^T · F
        Ft = IF_Math_Mtx_Transpose(F)
        C = PH_Math_Tensor_DotProduct(Ft, F)

        ! Compute U from C: U = sqrt(C)
        ! Use eigenvalue decomposition: C = Q · Λ · Q^T
        ! Then U = Q · sqrt(Λ) · Q^T
        CALL NM_Math_Mtx_Eigenvalues(C, eigvals, eigvecs, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%message = 'PH_Math_Tensor_PolarDecomposition: Failed eigenvalue computation'
            RETURN
        END IF

        ! U = Q · diag(sqrt(λ_i)) · Q^T
        ! Build diagonal matrix with sqrt(eigenvalues)
        tmp = ZERO
        DO i = 1, 3
            IF (eigvals(i) < ZERO) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'PH_Math_Tensor_PolarDecomposition: Negative eigenvalue in C'
                RETURN
            END IF
            tmp(i,i) = SQRT(eigvals(i))
        END DO

        ! U = eigvecs · sqrt_diag · eigvecs^T
        U = PH_Math_Tensor_DotProduct(eigvecs, tmp)
        U = PH_Math_Tensor_DotProduct(U, IF_Math_Mtx_Transpose(eigvecs))

        ! R = F · U^(-1)
        CALL IF_Math_Mtx_Inverse(U, tmp, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%message = 'PH_Math_Tensor_PolarDecomposition: Failed to invert U'
            RETURN
        END IF
        R = PH_Math_Tensor_DotProduct(F, tmp)

        ! V = R · U · R^T
        tmp = PH_Math_Tensor_DotProduct(R, U)
        V = PH_Math_Tensor_DotProduct(tmp, IF_Math_Mtx_Transpose(R))

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_PolarDecomposition

    ! ==========================================================================
    ! VOIGT NOTATION CONVERSION
    ! ==========================================================================

    SUBROUTINE PH_Math_Tensor_TensorToVoigt(tensor, voigt, status)
        REAL(wp), INTENT(IN) :: tensor(3,3)
        REAL(wp), INTENT(OUT) :: voigt(6)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        voigt(1) = tensor(1,1)
        voigt(2) = tensor(2,2)
        voigt(3) = tensor(3,3)
        voigt(4) = tensor(1,2)  ! or tensor(2,1) for symmetric
        voigt(5) = tensor(1,3)  ! or tensor(3,1) for symmetric
        voigt(6) = tensor(2,3)  ! or tensor(3,2) for symmetric

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_TensorToVoigt

    SUBROUTINE PH_Math_Tensor_VoigtToTensor(voigt, tensor, status)
        REAL(wp), INTENT(IN) :: voigt(6)
        REAL(wp), INTENT(OUT) :: tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Voigt notation: [σ₁₁, σ₂₂, σ₃₃, τ₁₂, τ₁₃, τ₂₃]
        tensor(1,1) = voigt(1)
        tensor(2,2) = voigt(2)
        tensor(3,3) = voigt(3)
        tensor(1,2) = voigt(4)
        tensor(2,1) = voigt(4)
        tensor(1,3) = voigt(5)
        tensor(3,1) = voigt(5)
        tensor(2,3) = voigt(6)
        tensor(3,2) = voigt(6)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Math_Tensor_VoigtToTensor

END MODULE PH_Mat_hTensor
