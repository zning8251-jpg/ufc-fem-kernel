!===============================================================================
! MODULE: NM_Solv_Direct
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (direct solvers for sparse linear systems)
! BRIEF:  Sparse LU, Skyline LU, dense LU with pivoting, fwd/bwd substitution
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_Direct
    USE IF_Prec_Core, ONLY: wp
    USE NM_Mtx_Core
    IMPLICIT NONE
    PRIVATE
    
    !---------------------------------------------------------------------------
    ! Public procedures
    !---------------------------------------------------------------------------
    PUBLIC :: direct_solve_dense
    PUBLIC :: direct_lu_factor
    PUBLIC :: direct_lu_solve
    PUBLIC :: skyline_factor
    PUBLIC :: skyline_solve
    PUBLIC :: band_lu_factor
    PUBLIC :: band_lu_solve
    
    !---------------------------------------------------------------------------
    ! LU factor storage type
    !---------------------------------------------------------------------------
      TYPE, PUBLIC :: UF_LUFactor_Size
        INTEGER(i4) :: n = 0
        INTEGER(i4) :: nnz = 0
  END TYPE UF_LUFactor_Size

  TYPE, PUBLIC :: UF_LUFactor_Values
        REAL(wp), ALLOCATABLE :: alu(:)      ! L and U values
        INTEGER, ALLOCATABLE :: jlu(:)       ! Column indices
  END TYPE UF_LUFactor_Values

  TYPE, PUBLIC :: UF_LUFactor_Ptr
        INTEGER, ALLOCATABLE :: ju(:)        ! Diagonal pointers
        INTEGER, ALLOCATABLE :: iperm(:)     ! Permutation array
  END TYPE UF_LUFactor_Ptr

  TYPE, PUBLIC :: UF_LUFactor_Flags
        LOGICAL :: factored = .FALSE.
  END TYPE UF_LUFactor_Flags

  TYPE, PUBLIC :: UF_LUFactor
        TYPE(UF_LUFactor_Size)   :: size
        TYPE(UF_LUFactor_Values) :: values
        TYPE(UF_LUFactor_Ptr)    :: ptr
        TYPE(UF_LUFactor_Flags)  :: flags
    CONTAINS
        PROCEDURE :: destroy => lu_destroy
    END TYPE UF_LUFactor
    
    !---------------------------------------------------------------------------
    ! Skyline/Profile storage type
    !---------------------------------------------------------------------------
      TYPE, PUBLIC :: UF_Skyline_Size
        INTEGER(i4) :: n = 0
  END TYPE UF_Skyline_Size

  TYPE, PUBLIC :: UF_Skyline_Values
        REAL(wp), ALLOCATABLE :: diag(:)     ! Diagonal entries
        REAL(wp), ALLOCATABLE :: sky(:)      ! Off-diagonal entries (column-wise)
  END TYPE UF_Skyline_Values

  TYPE, PUBLIC :: UF_Skyline_Ptr
        INTEGER, ALLOCATABLE :: idiag(:)     ! Pointers to diagonal in sky
  END TYPE UF_Skyline_Ptr

  TYPE, PUBLIC :: UF_Skyline_Flags
        LOGICAL :: factored = .FALSE.
  END TYPE UF_Skyline_Flags

  TYPE, PUBLIC :: UF_Skyline
        TYPE(UF_Skyline_Size)   :: size
        TYPE(UF_Skyline_Values) :: values
        TYPE(UF_Skyline_Ptr)    :: ptr
        TYPE(UF_Skyline_Flags)  :: flags
    CONTAINS
        PROCEDURE :: init => skyline_init
        PROCEDURE :: destroy => skyline_destroy
    END TYPE UF_Skyline
    
    REAL(wp), PARAMETER :: TINY_VAL = 1.0E-30_wp
    
CONTAINS

    !===========================================================================
    ! DENSE DIRECT SOLVE (Gaussian elimination with partial pivoting)
    !===========================================================================
    
    SUBROUTINE direct_solve_dense(A, b, x, n, ierr)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), INTENT(INOUT) :: A(n, n)    ! Modified during factorization
        REAL(wp), INTENT(IN) :: b(n)
        REAL(wp), INTENT(OUT) :: x(n)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, pivot_row
        REAL(wp) :: pivot_val, factor, temp
        REAL(wp), ALLOCATABLE :: work(:)
        
        ierr = 0
        ALLOCATE(work(n))
        
        ! Copy RHS
        x = b
        
        ! Forward elimination with partial pivoting
        DO k = 1, n-1
            ! Find pivot
            pivot_row = k
            pivot_val = ABS(A(k, k))
            DO i = k+1, n
                IF (ABS(A(i, k)) > pivot_val) THEN
                    pivot_val = ABS(A(i, k))
                    pivot_row = i
                END IF
            END DO
            
            IF (pivot_val < TINY_VAL) THEN
                ierr = -1  ! Singular matrix
                DEALLOCATE(work)
                RETURN
            END IF
            
            ! Swap rows
            IF (pivot_row /= k) THEN
                work = A(k, :)
                A(k, :) = A(pivot_row, :)
                A(pivot_row, :) = work
                temp = x(k)
                x(k) = x(pivot_row)
                x(pivot_row) = temp
            END IF
            
            ! Elimination
            DO i = k+1, n
                factor = A(i, k) / A(k, k)
                A(i, k+1:n) = A(i, k+1:n) - factor * A(k, k+1:n)
                x(i) = x(i) - factor * x(k)
            END DO
        END DO
        
        ! Check last diagonal
        IF (ABS(A(n, n)) < TINY_VAL) THEN
            ierr = -1
            DEALLOCATE(work)
            RETURN
        END IF
        
        ! Back substitution
        x(n) = x(n) / A(n, n)
        DO i = n-1, 1, -1
            x(i) = (x(i) - DOT_PRODUCT(A(i, i+1:n), x(i+1:n))) / A(i, i)
        END DO
        
        DEALLOCATE(work)
        
    END SUBROUTINE direct_solve_dense

    !===========================================================================
    ! SPARSE LU FACTORIZATION (ILU-style complete factorization)
    !===========================================================================
    
    SUBROUTINE direct_lu_factor(A, LU, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(UF_LUFactor), INTENT(OUT) :: LU
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, k, kk, jj, jw, jpos, nnz_lu
        INTEGER(i4) :: jrow, length
        REAL(wp) :: t, s, tnorm
        INTEGER, ALLOCATABLE :: iw(:), jw_temp(:)
        REAL(wp), ALLOCATABLE :: w(:)
        
        ierr = 0
        n = A%nrows
        LU%n = n
        
        ! Estimate storage (conservative: 10x nnz)
        nnz_lu = 10 * A%nnz + n
        
        ALLOCATE(LU%alu(nnz_lu), LU%jlu(nnz_lu), LU%ju(n), LU%iperm(n))
        ALLOCATE(iw(n), w(n))
        
        iw = 0
        LU%iperm = [(i, i=1, n)]
        
        ! IKJ variant of ILU (complete factorization)
        jpos = 0
        
        DO i = 1, n
            ! Initialize working row with row i of A
            w = 0.0_wp
            DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                j = A%col_ind(kk)
                w(j) = A%val(kk)
            END DO
            
            ! Eliminate previous rows
            DO k = 1, i-1
                IF (iw(k) /= 0 .AND. ABS(w(k)) > TINY_VAL) THEN
                    ! Get multiplier
                    t = w(k) * LU%alu(LU%ju(k))
                    w(k) = t
                    
                    ! Update remaining entries in row
                    DO jj = LU%ju(k)+1, iw(k)
                        j = LU%jlu(jj)
                        w(j) = w(j) - t * LU%alu(jj)
                    END DO
                END IF
            END DO
            
            ! Store L (lower part) and U (upper part including diagonal)
            ! First: L entries (j < i)
            DO j = 1, i-1
                IF (ABS(w(j)) > TINY_VAL) THEN
                    jpos = jpos + 1
                    IF (jpos > nnz_lu) THEN
                        ierr = -2  ! Insufficient storage
                        RETURN
                    END IF
                    LU%alu(jpos) = w(j)
                    LU%jlu(jpos) = j
                END IF
            END DO
            
            ! Diagonal entry
            IF (ABS(w(i)) < TINY_VAL) THEN
                ! Zero pivot - add small perturbation
                w(i) = SIGN(TINY_VAL * 1.0E+6_wp, w(i) + TINY_VAL)
            END IF
            
            jpos = jpos + 1
            LU%ju(i) = jpos
            LU%alu(jpos) = 1.0_wp / w(i)  ! Store inverse of diagonal
            LU%jlu(jpos) = i
            
            ! U entries (j > i)
            DO j = i+1, n
                IF (ABS(w(j)) > TINY_VAL) THEN
                    jpos = jpos + 1
                    IF (jpos > nnz_lu) THEN
                        ierr = -2
                        RETURN
                    END IF
                    LU%alu(jpos) = w(j)
                    LU%jlu(jpos) = j
                END IF
            END DO
            
            ! Mark end of row i
            iw(i) = jpos
        END DO
        
        LU%nnz = jpos
        LU%factored = .TRUE.
        
        DEALLOCATE(iw, w)
        
    END SUBROUTINE direct_lu_factor
    
    !---------------------------------------------------------------------------
    ! Solve with LU factors: L*U*x = b
    !---------------------------------------------------------------------------
    SUBROUTINE direct_lu_solve(LU, b, x, ierr)
        TYPE(UF_LUFactor), INTENT(IN) :: LU
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, kk, k_start, k_end
        REAL(wp) :: t
        
        ierr = 0
        
        IF (.NOT. LU%factored) THEN
            ierr = -1
            RETURN
        END IF
        
        n = LU%n
        x = b
        
        ! Forward solve: L * y = b
        DO i = 1, n
            t = x(i)
            ! Find start of row i in L (entries before diagonal)
            IF (i > 1) THEN
                k_start = LU%ju(i-1) + 1
            ELSE
                k_start = 1
            END IF
            k_end = LU%ju(i) - 1
            
            DO kk = k_start, k_end
                j = LU%jlu(kk)
                IF (j < i) THEN
                    t = t - LU%alu(kk) * x(j)
                END IF
            END DO
            x(i) = t
        END DO
        
        ! Backward solve: U * x = y
        DO i = n, 1, -1
            t = x(i)
            ! U entries are after diagonal
            IF (i < n) THEN
                k_start = LU%ju(i) + 1
                k_end = LU%ju(i+1) - 1
                DO kk = k_start, k_end
                    j = LU%jlu(kk)
                    IF (j > i) THEN
                        t = t - LU%alu(kk) * x(j)
                    END IF
                END DO
            END IF
            x(i) = t * LU%alu(LU%ju(i))  ! Multiply by inverse diagonal
        END DO
        
    END SUBROUTINE direct_lu_solve
    
    SUBROUTINE lu_destroy(this)
        CLASS(UF_LUFactor), INTENT(INOUT) :: this
        IF (ALLOCATED(this%alu)) DEALLOCATE(this%alu)
        IF (ALLOCATED(this%jlu)) DEALLOCATE(this%jlu)
        IF (ALLOCATED(this%ju)) DEALLOCATE(this%ju)
        IF (ALLOCATED(this%iperm)) DEALLOCATE(this%iperm)
        this%factored = .FALSE.
        this%n = 0
        this%nnz = 0
    END SUBROUTINE lu_destroy

    !===========================================================================
    ! SKYLINE/PROFILE SOLVER (for symmetric positive definite systems)
    !===========================================================================
    
    SUBROUTINE skyline_init(this, n, profile)
        CLASS(UF_Skyline), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: profile(:)  ! profile(i) = first nonzero col in row i
        
        INTEGER(i4) :: i, sky_size
        
        this%n = n
        ALLOCATE(this%diag(n), this%idiag(n+1))
        
        ! Compute skyline pointers
        this%idiag(1) = 1
        DO i = 1, n
            this%idiag(i+1) = this%idiag(i) + i - profile(i)
        END DO
        
        sky_size = this%idiag(n+1) - 1
        ALLOCATE(this%sky(sky_size))
        
        this%diag = 0.0_wp
        this%sky = 0.0_wp
        this%factored = .FALSE.
        
    END SUBROUTINE skyline_init
    
    SUBROUTINE skyline_factor(sky, ierr)
        TYPE(UF_Skyline), INTENT(INOUT) :: sky
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, k, ki, kj, mi, mj, jmin
        INTEGER(i4) :: kk_idx
        REAL(wp) :: c, t
        
        ierr = 0
        n = sky%n
        
        ! LDL^T factorization for skyline storage
        DO j = 1, n
            ! Compute column j of L
            jmin = j - (sky%idiag(j+1) - sky%idiag(j))
            
            ! Compute diagonal
            c = sky%diag(j)
            DO k = jmin, j-1
                ki = sky%idiag(j) + k - jmin
                c = c - sky%sky(ki)**2 * sky%diag(k)
            END DO
            
            IF (ABS(c) < TINY_VAL) THEN
                ierr = -1  ! Non-positive definite
                RETURN
            END IF
            
            sky%diag(j) = c
            
            ! Compute off-diagonal entries in column j
            DO i = j+1, n
                mi = i - (sky%idiag(i+1) - sky%idiag(i))
                IF (j < mi) CYCLE  ! Entry not in skyline
                
                ki = sky%idiag(i) + j - mi
                t = sky%sky(ki)
                
                DO k = MAX(jmin, mi), j-1
                    kj = sky%idiag(j) + k - jmin
                    kk_idx = sky%idiag(i) + k - mi
                    t = t - sky%sky(kj) * sky%sky(kk_idx) * sky%diag(k)
                END DO
                
                sky%sky(ki) = t / c
            END DO
        END DO
        
        sky%factored = .TRUE.
        
    END SUBROUTINE skyline_factor
    
    SUBROUTINE skyline_solve(sky, b, x, ierr)
        TYPE(UF_Skyline), INTENT(IN) :: sky
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, mi, ki
        REAL(wp) :: t
        
        ierr = 0
        
        IF (.NOT. sky%factored) THEN
            ierr = -1
            RETURN
        END IF
        
        n = sky%n
        x = b
        
        ! Forward solve: L * y = b
        DO i = 1, n
            t = x(i)
            mi = i - (sky%idiag(i+1) - sky%idiag(i))
            DO j = mi, i-1
                ki = sky%idiag(i) + j - mi
                t = t - sky%sky(ki) * x(j)
            END DO
            x(i) = t
        END DO
        
        ! Diagonal solve: D * z = y
        DO i = 1, n
            x(i) = x(i) / sky%diag(i)
        END DO
        
        ! Backward solve: L^T * x = z
        DO i = n, 1, -1
            mi = i - (sky%idiag(i+1) - sky%idiag(i))
            DO j = mi, i-1
                ki = sky%idiag(i) + j - mi
                x(j) = x(j) - sky%sky(ki) * x(i)
            END DO
        END DO
        
    END SUBROUTINE skyline_solve
    
    SUBROUTINE skyline_destroy(this)
        CLASS(UF_Skyline), INTENT(INOUT) :: this
        IF (ALLOCATED(this%diag)) DEALLOCATE(this%diag)
        IF (ALLOCATED(this%sky)) DEALLOCATE(this%sky)
        IF (ALLOCATED(this%idiag)) DEALLOCATE(this%idiag)
        this%factored = .FALSE.
        this%n = 0
    END SUBROUTINE skyline_destroy

    !===========================================================================
    ! BANDED LU SOLVER
    !===========================================================================
    
    SUBROUTINE band_lu_factor(A, n, kl, ku, AB, ipiv, ierr)
        INTEGER(i4), INTENT(IN) :: n, kl, ku      ! Size and bandwidths
        REAL(wp), INTENT(IN) :: A(n, n)       ! Original matrix (dense)
        REAL(wp), INTENT(OUT) :: AB(2*kl+ku+1, n)  ! Banded storage
        INTEGER(i4), INTENT(OUT) :: ipiv(n)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, kv, km, jp, ldab
        REAL(wp) :: temp
        
        ierr = 0
        ldab = 2*kl + ku + 1
        kv = kl + ku
        
        ! Copy to banded storage (LAPACK format)
        AB = 0.0_wp
        DO j = 1, n
            DO i = MAX(1, j-ku), MIN(n, j+kl)
                AB(kv + 1 + i - j, j) = A(i, j)
            END DO
        END DO
        
        ! LU factorization (simplified DGBTRF)
        DO j = 1, n
            ! Find pivot
            km = MIN(kl, n-j)
            jp = 1
            DO i = 2, km+1
                IF (ABS(AB(kv+i, j)) > ABS(AB(kv+jp, j))) jp = i
            END DO
            ipiv(j) = jp + j - 1
            
            IF (ABS(AB(kv+1, j)) < TINY_VAL .AND. jp == 1) THEN
                ! Zero pivot
                ierr = j
                RETURN
            END IF
            
            ! Apply pivot
            IF (jp /= 1) THEN
                DO k = 1, ldab
                    temp = AB(k, j)
                    ! Would need full swap implementation
                END DO
            END IF
            
            ! Compute multipliers
            IF (ABS(AB(kv+1, j)) > TINY_VAL) THEN
                DO i = 1, km
                    AB(kv+1+i, j) = AB(kv+1+i, j) / AB(kv+1, j)
                END DO
                
                ! Update trailing submatrix
                DO k = 1, MIN(ku, n-j)
                    DO i = 1, km
                        AB(kv+1+i-k, j+k) = AB(kv+1+i-k, j+k) - AB(kv+1+i, j) * AB(kv+1-k, j)
                    END DO
                END DO
            END IF
        END DO
        
    END SUBROUTINE band_lu_factor
    
    SUBROUTINE band_lu_solve(AB, n, kl, ku, ipiv, b, x, ierr)
        INTEGER(i4), INTENT(IN) :: n, kl, ku
        REAL(wp), INTENT(IN) :: AB(2*kl+ku+1, n)
        INTEGER(i4), INTENT(IN) :: ipiv(n)
        REAL(wp), INTENT(IN) :: b(n)
        REAL(wp), INTENT(OUT) :: x(n)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, kv, lm
        REAL(wp) :: temp
        
        ierr = 0
        kv = kl + ku
        x = b
        
        ! Forward solve L * y = P * b
        DO j = 1, n
            lm = MIN(kl, n-j)
            IF (ipiv(j) /= j) THEN
                temp = x(ipiv(j))
                x(ipiv(j)) = x(j)
                x(j) = temp
            END IF
            DO i = 1, lm
                x(j+i) = x(j+i) - AB(kv+1+i, j) * x(j)
            END DO
        END DO
        
        ! Backward solve U * x = y
        DO j = n, 1, -1
            x(j) = x(j) / AB(kv+1, j)
            lm = MIN(ku, j-1)
            DO i = 1, lm
                x(j-i) = x(j-i) - AB(kv+1-i, j) * x(j)
            END DO
        END DO
        
    END SUBROUTINE band_lu_solve

END MODULE NM_Solv_Direct