!===============================================================================
! MODULE: IF_Math_Util
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Proc — core math utilities (vector/matrix ops, numerical safety)
! BRIEF:  Basic math: dot, cross, norm, clamp, lerp, sign; 3x3 matrix
!         ops (det, inv, mul, transpose); safe divide/log/sqrt.
!         Advanced ops in L2_NM; tensor ops in L4_PH.
!===============================================================================

MODULE IF_Math_Util
    USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, THIRD, EPS, TOLERANCE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE, INTRINSIC :: ieee_arithmetic, ONLY: ieee_is_nan, ieee_is_finite
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACES (Alphabetical Order)
    ! ==========================================================================
    PUBLIC :: IF_Math_Clamp
    PUBLIC :: IF_Math_CrossProduct
    PUBLIC :: IF_Math_DotProduct
    PUBLIC :: IF_Math_IsEqual
    PUBLIC :: IF_Math_IsFinite
    PUBLIC :: IF_Math_IsInf
    PUBLIC :: IF_Math_IsNaN
    PUBLIC :: IF_Math_IsZero
    PUBLIC :: IF_Math_Lerp
    PUBLIC :: IF_Math_Mtx_Determinant
    PUBLIC :: IF_Math_Mtx_Inverse
    PUBLIC :: IF_Math_Mtx_Multiply
    PUBLIC :: IF_Math_Mtx_Transpose
    PUBLIC :: IF_Math_Normalize
    PUBLIC :: IF_Math_Norm
    PUBLIC :: IF_Math_SafeDivide
    PUBLIC :: IF_Math_SafeLog
    PUBLIC :: IF_Math_SafeSqrt
    PUBLIC :: IF_Math_Sign
    
CONTAINS

    ! ==========================================================================
    ! BASIC MATH FUNCTIONS
    ! ==========================================================================
    
    FUNCTION IF_Math_Clamp(x, min_val, max_val) RESULT(clamped)
        REAL(wp), INTENT(IN) :: x, min_val, max_val
        REAL(wp) :: clamped
        clamped = MAX(min_val, MIN(max_val, x))
    END FUNCTION IF_Math_Clamp
    
    FUNCTION IF_Math_CrossProduct(a, b) RESULT(cross)
        REAL(wp), INTENT(IN) :: a(3), b(3)
        REAL(wp) :: cross(3)
        
        cross(1) = a(2) * b(3) - a(3) * b(2)
        cross(2) = a(3) * b(1) - a(1) * b(3)
        cross(3) = a(1) * b(2) - a(2) * b(1)
    END FUNCTION IF_Math_CrossProduct
    
    FUNCTION IF_Math_DotProduct(a, b) RESULT(dot)
        REAL(wp), INTENT(IN) :: a(:), b(:)
        REAL(wp) :: dot
        
        INTEGER(i4) :: i, n
        
        n = SIZE(a)
        IF (SIZE(b) /= n) THEN
            dot = 0.0_wp
            RETURN
        END IF
        
        dot = ZERO
        DO i = 1, n
            dot = dot + a(i) * b(i)
        END DO
    END FUNCTION IF_Math_DotProduct
    
    FUNCTION IF_Math_IsEqual(a, b, tolerance) RESULT(is_equal)
        REAL(wp), INTENT(IN) :: a, b
        REAL(wp), INTENT(IN), OPTIONAL :: tolerance
        LOGICAL :: is_equal
        
        REAL(wp) :: tol
        
        IF (PRESENT(tolerance)) THEN
            tol = tolerance
        ELSE
            tol = TOLERANCE
        END IF
        
        is_equal = (ABS(a - b) <= tol)
    END FUNCTION IF_Math_IsEqual
    
    FUNCTION IF_Math_IsFinite(x) RESULT(is_finite)
        REAL(wp), INTENT(IN) :: x
        LOGICAL :: is_finite
        is_finite = ieee_is_finite(x)
    END FUNCTION IF_Math_IsFinite
    
    FUNCTION IF_Math_IsInf(x) RESULT(is_inf)
        REAL(wp), INTENT(IN) :: x
        LOGICAL :: is_inf
        is_inf = (.NOT. ieee_is_finite(x)) .AND. (.NOT. ieee_is_nan(x))
    END FUNCTION IF_Math_IsInf
    
    FUNCTION IF_Math_IsNaN(x) RESULT(is_nan)
        REAL(wp), INTENT(IN) :: x
        LOGICAL :: is_nan
        is_nan = ieee_is_nan(x)
    END FUNCTION IF_Math_IsNaN
    
    FUNCTION IF_Math_IsZero(x, tolerance) RESULT(is_zero)
        REAL(wp), INTENT(IN) :: x
        REAL(wp), INTENT(IN), OPTIONAL :: tolerance
        LOGICAL :: is_zero
        
        REAL(wp) :: tol
        
        IF (PRESENT(tolerance)) THEN
            tol = tolerance
        ELSE
            tol = EPS
        END IF
        
        is_zero = (ABS(x) <= tol)
    END FUNCTION IF_Math_IsZero
    
    FUNCTION IF_Math_Lerp(a, b, t) RESULT(lerped)
        REAL(wp), INTENT(IN) :: a, b, t
        REAL(wp) :: lerped
        lerped = a + t * (b - a)
    END FUNCTION IF_Math_Lerp
    
    FUNCTION IF_Math_Norm(vec) RESULT(norm_val)
        REAL(wp), INTENT(IN) :: vec(:)
        REAL(wp) :: norm_val
        
        INTEGER(i4) :: i, n
        
        n = SIZE(vec)
        norm_val = ZERO
        DO i = 1, n
            norm_val = norm_val + vec(i) * vec(i)
        END DO
        norm_val = SQRT(norm_val)
    END FUNCTION IF_Math_Norm
    
    FUNCTION IF_Math_Sign(x) RESULT(sign_val)
        REAL(wp), INTENT(IN) :: x
        INTEGER(i4) :: sign_val
        
        IF (x > ZERO) THEN
            sign_val = 1_i4
        ELSE IF (x < ZERO) THEN
            sign_val = -1_i4
        ELSE
            sign_val = 0_i4
        END IF
    END FUNCTION IF_Math_Sign

    ! ==========================================================================
    ! BASIC MATRIX OPERATIONS
    ! ==========================================================================

    SUBROUTINE IF_Math_Mtx_Determinant(A, det, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: det
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n
        
        CALL init_error_status(status)
        
        n = SIZE(A, 1)
        
        IF (SIZE(A, 2) /= n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_Mtx_Determinant: Matrix must be square'
            RETURN
        END IF
        
        IF (n == 3) THEN
            CALL IF_Math_Mtx_Determinant_3x3(A, det, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_Mtx_Determinant: Only 3x3 matrices supported'
        END IF
    END SUBROUTINE IF_Math_Mtx_Determinant

    SUBROUTINE IF_Math_Mtx_Determinant_3x3(A, det, status)
        REAL(wp), INTENT(IN) :: A(3,3)
        REAL(wp), INTENT(OUT) :: det
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Determinant: det(A) = A₁₁(A₂₂A₃₃ - A₂₃A₃₂) - A₁₂(A₂₁A₃₃ - A₂₃A₃₁) + A₁₃(A₂₁A₃₂ - A₂₂A₃₁)
        det = A(1,1) * (A(2,2) * A(3,3) - A(2,3) * A(3,2)) - &
              A(1,2) * (A(2,1) * A(3,3) - A(2,3) * A(3,1)) + &
              A(1,3) * (A(2,1) * A(3,2) - A(2,2) * A(3,1))
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_Mtx_Determinant_3x3

    SUBROUTINE IF_Math_Mtx_Inverse(A, A_inverse, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: A_inverse(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n, i
        REAL(wp) :: L(3,3), U(3,3), P(3,3)
        REAL(wp) :: I_mtx(3,3), tmp(3,3)
        
        CALL init_error_status(status)
        
        n = SIZE(A, 1)
        
        IF (SIZE(A, 2) /= n .OR. SIZE(A_inverse, 1) /= n .OR. SIZE(A_inverse, 2) /= n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_Mtx_Inverse: Matrix must be square'
            RETURN
        END IF
        
        ! For 3x3 matrices, use direct formula
        IF (n == 3) THEN
            CALL IF_Math_Mtx_Inverse_3x3(A, A_inverse, status)
            RETURN
        END IF
        
        ! For general matrices, use LU decomposition
        ! (Simplified - full implementation would handle all sizes)
        status%status_code = IF_STATUS_INVALID
        status%message = 'IF_Math_Mtx_Inverse: Only 3x3 matrices supported'
    END SUBROUTINE IF_Math_Mtx_Inverse

    SUBROUTINE IF_Math_Mtx_Inverse_3x3(A, A_inverse, status)
        REAL(wp), INTENT(IN) :: A(3,3)
        REAL(wp), INTENT(OUT) :: A_inverse(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp) :: det, inv_det
        REAL(wp) :: cof(3,3)
        
        CALL init_error_status(status)
        
        ! Compute determinant
        CALL IF_Math_Mtx_Determinant_3x3(A, det, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        IF (ABS(det) < EPS) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_Mtx_Inverse_3x3: Singular matrix'
            RETURN
        END IF
        
        inv_det = ONE / det
        
        ! Compute cofactor matrix
        cof(1,1) = A(2,2) * A(3,3) - A(2,3) * A(3,2)
        cof(1,2) = -(A(2,1) * A(3,3) - A(2,3) * A(3,1))
        cof(1,3) = A(2,1) * A(3,2) - A(2,2) * A(3,1)
        cof(2,1) = -(A(1,2) * A(3,3) - A(1,3) * A(3,2))
        cof(2,2) = A(1,1) * A(3,3) - A(1,3) * A(3,1)
        cof(2,3) = -(A(1,1) * A(3,2) - A(1,2) * A(3,1))
        cof(3,1) = A(1,2) * A(2,3) - A(1,3) * A(2,2)
        cof(3,2) = -(A(1,1) * A(2,3) - A(1,3) * A(2,1))
        cof(3,3) = A(1,1) * A(2,2) - A(1,2) * A(2,1)
        
        ! A^(-1) = (1/det) * cof^T
        A_inverse = IF_Math_Mtx_Transpose(cof)
        A_inverse = A_inverse * inv_det
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_Mtx_Inverse_3x3

    SUBROUTINE IF_Math_Mtx_Multiply(A, B, C, status)
        REAL(wp), INTENT(IN) :: A(:,:), B(:,:)
        REAL(wp), INTENT(OUT) :: C(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: m, n, p, i, j, k
        
        CALL init_error_status(status)
        
        m = SIZE(A, 1)
        n = SIZE(A, 2)
        p = SIZE(B, 2)
        
        IF (SIZE(B, 1) /= n .OR. SIZE(C, 1) /= m .OR. SIZE(C, 2) /= p) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_Mtx_Multiply: Dimension mismatch'
            RETURN
        END IF
        
        C = ZERO
        DO i = 1, m
            DO j = 1, p
                DO k = 1, n
                    C(i,j) = C(i,j) + A(i,k) * B(k,j)
                END DO
            END DO
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_Mtx_Multiply

    FUNCTION IF_Math_Mtx_Transpose(A) RESULT(At)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp) :: At(SIZE(A,2), SIZE(A,1))
        
        INTEGER(i4) :: i, j
        
        DO i = 1, SIZE(A, 1)
            DO j = 1, SIZE(A, 2)
                At(j,i) = A(i,j)
            END DO
        END DO
    END FUNCTION IF_Math_Mtx_Transpose

    SUBROUTINE IF_Math_Normalize(vec, status)
        REAL(wp), INTENT(INOUT) :: vec(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp) :: norm
        
        CALL init_error_status(status)
        
        norm = IF_Math_Norm(vec)
        IF (IF_Math_IsZero(norm)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_Normalize: Zero vector'
            RETURN
        END IF
        
        vec = vec / norm
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_Normalize

    SUBROUTINE IF_Math_SafeDivide(numerator, denominator, result, status)
        REAL(wp), INTENT(IN) :: numerator, denominator
        REAL(wp), INTENT(OUT) :: result
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        IF (IF_Math_IsZero(denominator)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_SafeDivide: Division by zero'
            result = 0.0_wp
            RETURN
        END IF
        
        result = numerator / denominator
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_SafeDivide

    SUBROUTINE IF_Math_SafeLog(x, result, status)
        REAL(wp), INTENT(IN) :: x
        REAL(wp), INTENT(OUT) :: result
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        IF (x <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_SafeLog: Non-positive value'
            result = 0.0_wp
            RETURN
        END IF
        
        result = LOG(x)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_SafeLog

    SUBROUTINE IF_Math_SafeSqrt(x, result, status)
        REAL(wp), INTENT(IN) :: x
        REAL(wp), INTENT(OUT) :: result
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        IF (x < 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'IF_Math_SafeSqrt: Negative value'
            result = 0.0_wp
            RETURN
        END IF
        
        result = SQRT(x)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Math_SafeSqrt

END MODULE IF_Math_Util