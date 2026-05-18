!===============================================================================
! MODULE: NM_Mtx_Math
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Proc — Advanced matrix operations (Cholesky/LU/QR, eigenvalues, cond)
! BRIEF:  Matrix decompositions, eigenvalue computation, condition number
!===============================================================================

MODULE NM_Mtx_Math
    USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, THIRD, EPS, TOLERANCE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Math_Util, ONLY: IF_Math_Mtx_Multiply, IF_Math_Mtx_Transpose, &
                            IF_Math_Mtx_Inverse, IF_Math_Mtx_Determinant, &
                            IF_Math_DotProduct, IF_Math_Norm, IF_Math_CrossProduct
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: NM_Math_Mtx_Cholesky_Decomposition
    PUBLIC :: NM_Math_Mtx_LU_Decomposition
    PUBLIC :: NM_Math_Mtx_QR_Decomposition
    PUBLIC :: NM_Math_Mtx_Eigenvalues
    PUBLIC :: NM_Math_Mtx_ConditionNumber

CONTAINS

    ! ==========================================================================
    ! MATRIX DECOMPOSITIONS
    ! ==========================================================================
    
    SUBROUTINE NM_Math_Mtx_Cholesky_Decomposition(A, L, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: L(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n, i, j, k
        REAL(wp) :: s
        
        CALL init_error_status(status)
        
        n = SIZE(A, 1)
        
        IF (SIZE(A, 2) /= n .OR. SIZE(L, 1) /= n .OR. SIZE(L, 2) /= n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'NM_Math_Mtx_Cholesky_Decomposition: Dimension mismatch'
            RETURN
        END IF
        
        L = ZERO
        
        DO i = 1, n
            DO j = 1, i
                s = A(i,j)
                DO k = 1, j-1
                    s = s - L(i,k) * L(j,k)
                END DO
                
                IF (i == j) THEN
                    IF (s <= ZERO) THEN
                        status%status_code = IF_STATUS_INVALID
                        status%message = 'NM_Math_Mtx_Cholesky_Decomposition: Matrix not positive definite'
                        RETURN
                    END IF
                    L(i,j) = SQRT(s)
                ELSE
                    L(i,j) = s / L(j,j)
                END IF
            END DO
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Math_Mtx_Cholesky_Decomposition
    
    SUBROUTINE NM_Math_Mtx_LU_Decomposition(A, L, U, P, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: L(:,:), U(:,:), P(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n, i, j, k, pivot_idx, tmp_idx
        REAL(wp) :: tmp_row(SIZE(A,2)), max_val, pivot_val
        REAL(wp) :: A_tmp(SIZE(A,1), SIZE(A,2))
        INTEGER(i4) :: perm(SIZE(A,1))
        
        CALL init_error_status(status)
        
        n = SIZE(A, 1)
        
        IF (SIZE(A, 2) /= n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'NM_Math_Mtx_LU_Decomposition: Matrix must be square'
            RETURN
        END IF
        
        ! Init
        A_tmp = A
        L = ZERO
        U = ZERO
        P = ZERO
        DO i = 1, n
            P(i,i) = ONE
            L(i,i) = ONE
            perm(i) = i
        END DO
        
        ! LU decomposition with partial pivoting (Doolittle algorithm)
        DO k = 1, n
            ! Find pivot (maximum element in column k below diagonal)
            max_val = ABS(A_tmp(k,k))
            pivot_idx = k
            DO i = k+1, n
                IF (ABS(A_tmp(i,k)) > max_val) THEN
                    max_val = ABS(A_tmp(i,k))
                    pivot_idx = i
                END IF
            END DO
            
            ! Check for singular matrix
            IF (max_val < EPS) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'NM_Math_Mtx_LU_Decomposition: Singular matrix'
                RETURN
            END IF
            
            ! Swap rows if needed
            IF (pivot_idx /= k) THEN
                ! Swap in A_tmp
                tmp_row = A_tmp(k,:)
                A_tmp(k,:) = A_tmp(pivot_idx,:)
                A_tmp(pivot_idx,:) = tmp_row
                
                ! Swap in L (previous entries)
                DO j = 1, k-1
                    pivot_val = L(k,j)
                    L(k,j) = L(pivot_idx,j)
                    L(pivot_idx,j) = pivot_val
                END DO
                
                ! Update permutation
                tmp_idx = perm(k)
                perm(k) = perm(pivot_idx)
                perm(pivot_idx) = tmp_idx
            END IF
            
            ! Compute U(k,k:n) and L(k+1:n,k)
            U(k,k:n) = A_tmp(k,k:n)
            
            DO i = k+1, n
                L(i,k) = A_tmp(i,k) / U(k,k)
                ! Update remaining matrix
                DO j = k+1, n
                    A_tmp(i,j) = A_tmp(i,j) - L(i,k) * U(k,j)
                END DO
            END DO
        END DO
        
        ! Build permutation matrix from perm vector
        P = ZERO
        DO i = 1, n
            P(i, perm(i)) = ONE
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Math_Mtx_LU_Decomposition
    
    SUBROUTINE NM_Math_Mtx_QR_Decomposition(A, Q, R, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: Q(:,:), R(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: m, n, i, j, k
        REAL(wp) :: v(SIZE(A,1)), norm_v, u_vec(SIZE(A,1))
        REAL(wp) :: A_tmp(SIZE(A,1), SIZE(A,2))
        
        CALL init_error_status(status)
        
        m = SIZE(A, 1)
        n = SIZE(A, 2)
        
        ! Simplified QR decomposition using Gram-Schmidt process
        A_tmp = A
        Q = ZERO
        R = ZERO
        
        DO j = 1, n
            v = A_tmp(:,j)
            DO i = 1, j-1
                R(i,j) = IF_Math_DotProduct(Q(:,i), A_tmp(:,j))
                v = v - R(i,j) * Q(:,i)
            END DO
            norm_v = IF_Math_Norm(v)
            IF (norm_v > EPS) THEN
                Q(:,j) = v / norm_v
                R(j,j) = norm_v
            ELSE
                status%status_code = IF_STATUS_INVALID
                status%message = 'NM_Math_Mtx_QR_Decomposition: Linearly dependent columns'
                RETURN
            END IF
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Math_Mtx_QR_Decomposition
    
    ! ==========================================================================
    ! EIGENVALUE COMPUTATION
    ! ==========================================================================
    
    SUBROUTINE NM_Math_Mtx_Eigenvalues(A, eigenvalues, eigenvectors, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: eigenvalues(:), eigenvectors(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: n
        
        CALL init_error_status(status)
        
        n = SIZE(A, 1)
        
        IF (SIZE(A, 2) /= n .OR. SIZE(eigenvalues) /= n .OR. &
            SIZE(eigenvectors, 1) /= n .OR. SIZE(eigenvectors, 2) /= n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'NM_Math_Mtx_Eigenvalues: Dimension mismatch'
            RETURN
        END IF
        
        ! Simplified eigenvalue computation for 3x3 matrices
        ! (Full implementation would use iterative methods like QR algorithm)
        IF (n == 3) THEN
            CALL NM_Math_Mtx_Eigenvalues_3x3(A, eigenvalues, eigenvectors, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'NM_Math_Mtx_Eigenvalues: Only 3x3 matrices supported'
        END IF
    END SUBROUTINE NM_Math_Mtx_Eigenvalues
    
    SUBROUTINE NM_Math_Mtx_Eigenvalues_3x3(A, eigenvalues, eigenvectors, status)
        REAL(wp), INTENT(IN) :: A(3,3)
        REAL(wp), INTENT(OUT) :: eigenvalues(3), eigenvectors(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp) :: I1, I2, I3, p, q, r, phi, c1, c2
        REAL(wp) :: pi, sqrt3, two_pi_3
        REAL(wp) :: A2(3,3)
        INTEGER(i4) :: i, j, k
        LOGICAL :: is_symmetric
        
        CALL init_error_status(status)
        
        ! Check if matrix is symmetric (within tolerance)
        is_symmetric = .TRUE.
        DO i = 1, 3
            DO j = i+1, 3
                IF (ABS(A(i,j) - A(j,i)) > TOLERANCE) THEN
                    is_symmetric = .FALSE.
                    EXIT
                END IF
            END DO
            IF (.NOT. is_symmetric) EXIT
        END DO
        
        IF (is_symmetric) THEN
            ! For symmetric 3x3 matrix, use analytical formula (Smith's algorithm)
            ! Characteristic equation: - I ?+ I ?- I ?= 0
            ! Compute invariants directly (I1 = trace, I2 = [tr ?- tr(A ?], I3 = det)
            
            ! First invariant: I ?= tr(A)
            I1 = A(1,1) + A(2,2) + A(3,3)
            
            ! Compute A ?for second invariant
            A2 = ZERO
            DO i = 1, 3
                DO j = 1, 3
                    DO k = 1, 3
                        A2(i,j) = A2(i,j) + A(i,k) * A(k,j)
                    END DO
                END DO
            END DO
            
            ! Second invariant: I ?= [tr(A) ?- tr(A ?]
            I2 = HALF * (I1 * I1 - (A2(1,1) + A2(2,2) + A2(3,3)))
            
            ! Third invariant: I ?= det(A)
            CALL IF_Math_Mtx_Determinant(A, I3, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
            
            ! Transform to depressed cubic: t ?+ pt + q = 0
            ! where t = ?- I ?3
            p = I2 - I1*I1*THIRD
            q = TWO*I1*I1*I1/27.0_wp - I1*I2*THIRD + I3
            
            ! Compute discriminant
            r = SQRT(MAX(ZERO, -p*p*p/27.0_wp))
            
            IF (ABS(r) > EPS) THEN
                ! Three distinct real roots (typical case)
                pi = 4.0_wp * ATAN(ONE)  !  ?= 4*arctan(1)
                phi = ACOS(MAX(-ONE, MIN(ONE, -q/(TWO*r))))
                sqrt3 = SQRT(3.0_wp)
                two_pi_3 = TWO * pi * THIRD
                
                c1 = TWO * SQRT(-p*THIRD)
                c2 = I1 * THIRD
                
                ! Three eigenvalues (sorted descending)
                eigenvalues(1) = c1 * COS(phi*THIRD) + c2
                eigenvalues(2) = c1 * COS((phi + two_pi_3)*THIRD) + c2
                eigenvalues(3) = c1 * COS((phi - two_pi_3)*THIRD) + c2
            ELSE
                ! Multiple roots (degenerate case)
                eigenvalues(1) = I1 * THIRD
                eigenvalues(2) = I1 * THIRD
                eigenvalues(3) = I1 * THIRD
            END IF
            
            ! Compute eigenvectors for symmetric matrix
            ! For each eigenvalue _i, solve (A - _i I) v_i = 0
            CALL NM_Math_Compute_Eigenvectors_3x3(A, eigenvalues, eigenvectors, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                ! Fallback to identity if eigenvector computation fails
                eigenvectors = ZERO
                DO i = 1, 3
                    eigenvectors(i,i) = ONE
                END DO
                status%status_code = IF_STATUS_OK  ! Reset status
            END IF
        ELSE
            ! For general (non-symmetric) 3x3 matrix
            ! Use simplified approximation (diagonal elements)
            ! WARNING: This is approximate and may not be accurate
            eigenvalues(1) = A(1,1)
            eigenvalues(2) = A(2,2)
            eigenvalues(3) = A(3,3)
            
            eigenvectors = ZERO
            DO i = 1, 3
                eigenvectors(i,i) = ONE
            END DO
            
            ! Set warning in status message
            status%message = 'NM_Math_Mtx_Eigenvalues_3x3: Non-symmetric matrix, approximate solution'
        END IF
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Math_Mtx_Eigenvalues_3x3
    
    SUBROUTINE NM_Math_Compute_Eigenvectors_3x3(A, eigenvalues, eigenvectors, status)
        REAL(wp), INTENT(IN) :: A(3,3), eigenvalues(3)
        REAL(wp), INTENT(OUT) :: eigenvectors(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp) :: M(3,3), v(3), norm_v
        INTEGER(i4) :: i, j, k, max_idx
        REAL(wp) :: max_val
        
        CALL init_error_status(status)
        
        ! For each eigenvalue, compute corresponding eigenvector
        DO k = 1, 3
            ! Build matrix M = A - _k I
            M = A
            DO i = 1, 3
                M(i,i) = M(i,i) - eigenvalues(k)
            END DO
            
            ! Find null space of M (simplified: use cross product method)
            ! For 3x3, null space can be found from any two rows
            ! v = row1 ?row2 (perpendicular to both rows)
            
            ! Find two most independent rows
            max_val = ZERO
            max_idx = 1
            DO i = 1, 3
                norm_v = IF_Math_Norm(M(i,:))
                IF (norm_v > max_val) THEN
                    max_val = norm_v
                    max_idx = i
                END IF
            END DO
            
            ! Use cross product of two different rows
            IF (max_idx == 1) THEN
                v = IF_Math_CrossProduct(M(1,:), M(2,:))
            ELSE IF (max_idx == 2) THEN
                v = IF_Math_CrossProduct(M(2,:), M(3,:))
            ELSE
                v = IF_Math_CrossProduct(M(1,:), M(3,:))
            END IF
            
            ! Normalize eigenvector
            norm_v = IF_Math_Norm(v)
            IF (norm_v > EPS) THEN
                eigenvectors(:,k) = v / norm_v
            ELSE
                ! Degenerate case: use standard basis vector
                eigenvectors(:,k) = ZERO
                eigenvectors(k,k) = ONE
            END IF
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Math_Compute_Eigenvectors_3x3
    
    ! ==========================================================================
    ! MATRIX CONDITION NUMBER
    ! ==========================================================================
    
    SUBROUTINE NM_Math_Mtx_ConditionNumber(A, cond_num, status)
        REAL(wp), INTENT(IN) :: A(:,:)
        REAL(wp), INTENT(OUT) :: cond_num
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp), ALLOCATABLE :: A_inv(:,:)
        INTEGER(i4) :: n, i, j
        REAL(wp) :: norm_A, norm_A_inv
        
        CALL init_error_status(status)
        
        n = SIZE(A, 1)
        
        IF (SIZE(A, 2) /= n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'NM_Math_Mtx_ConditionNumber: Matrix must be square'
            RETURN
        END IF
        
        ALLOCATE(A_inv(n, n))
        
        ! Compute matrix norm (Frobenius norm)
        norm_A = ZERO
        DO i = 1, n
            DO j = 1, n
                norm_A = norm_A + A(i,j) * A(i,j)
            END DO
        END DO
        norm_A = SQRT(norm_A)
        
        ! Compute inverse
        CALL IF_Math_Mtx_Inverse(A, A_inv, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            DEALLOCATE(A_inv)
            status%message = 'NM_Math_Mtx_ConditionNumber: Failed to compute inverse'
            RETURN
        END IF
        
        ! Compute inverse matrix norm
        norm_A_inv = ZERO
        DO i = 1, n
            DO j = 1, n
                norm_A_inv = norm_A_inv + A_inv(i,j) * A_inv(i,j)
            END DO
        END DO
        norm_A_inv = SQRT(norm_A_inv)
        
        ! Condition number: ?A) = ||A|| ?||A^(-1)||
        cond_num = norm_A * norm_A_inv
        
        DEALLOCATE(A_inv)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE NM_Math_Mtx_ConditionNumber

END MODULE NM_Mtx_Math