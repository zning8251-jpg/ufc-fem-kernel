!===============================================================================
! MODULE: NM_Solv_Preconditioner
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (preconditioners: Jacobi/SSOR/ILU/IC/AMG/Block)
! BRIEF:  Preconditioner construction and application via itsol/HSL backends
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_Preconditioner
    USE hsl_mi20_double  ! HSL MI20 AMG library
    USE IF_Prec_Core, ONLY: wp, i4
    USE ModuleItsol, ONLY: iluk
    USE NM_Mtx_Core
    IMPLICIT NONE

    PRIVATE
    
    !---------------------------------------------------------------------------
    ! Public types and procedures
    !---------------------------------------------------------------------------

    PUBLIC :: precond_create, precond_destroy
    PUBLIC :: precond_apply, precond_setup
    PUBLIC :: precond_set_block_size
    
    !---------------------------------------------------------------------------
    ! UNIFIED Preconditioner types (compatible with NM_LinSolvCfg)
    ! These constants MUST match those in NM_LinSolvCfg.f90
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_NONE = 0
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_DIAG = 1        ! Diagonal (Jacobi)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ILU0 = 2        ! ILU(0)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ILUK = 3        ! ILU(k) with fill
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_IC0 = 4         ! Incomplete Cholesky
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ICK = 5         ! IC with fill
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_SSOR = 6        ! SSOR
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_AMG = 7         ! Algebraic Multigrid
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_ILUT = 8        ! ILUT (threshold)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_BLOCK_JACOBI = 9  ! Block Jacobi
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_BLOCK_ILU0 = 10   ! Block ILU(0)
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PRECOND_SSOR_EISENSTAT = 11 ! SSOR with Eisenstat trick
    
    ! [REMOVED] Legacy aliases NM_PRECOND_JACOBI, NM_PRECOND_IC — use NM_PRECOND_DIAG, NM_PRECOND_IC0 directly
    
    !---------------------------------------------------------------------------
    ! Error codes
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: NM_PC_SUCCESS = 0
    INTEGER(i4), PARAMETER, PUBLIC :: PC_ERR_ALLOC = -1
    INTEGER(i4), PARAMETER, PUBLIC :: PC_ERR_ZERO_PIVOT = -2
    INTEGER(i4), PARAMETER, PUBLIC :: PC_ERR_OVERFLOW = -3
    
    !---------------------------------------------------------------------------
    ! Constants
    !---------------------------------------------------------------------------
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    REAL(wp), PARAMETER :: ONE = 1.0_wp
    REAL(wp), PARAMETER :: SMALL = 1.0E-14_wp
    
    !---------------------------------------------------------------------------
    ! Preconditioner data structure
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_Precond
        INTEGER(i4) :: ptype = NM_PRECOND_NONE   ! Preconditioner type
        INTEGER(i4) :: n = 0                   ! Matrix dimension
        REAL(wp) :: omega = 1.0_wp            ! Relaxation parameter (SSOR)
        INTEGER(i4) :: lfil = 10              ! Fill-in level (ILUT/ILUK)
        REAL(wp) :: droptol = 1.0E-4_wp       ! Drop tolerance (ILUT)
        
        ! Jacobi preconditioner
        REAL(wp), ALLOCATABLE :: diag_inv(:)  ! Inverted diagonal
        
        ! ILU factorization storage (MSR format)
        REAL(wp), ALLOCATABLE :: alu(:)       ! L and U values
        INTEGER(i4), ALLOCATABLE :: jlu(:)    ! Column indices
        INTEGER(i4), ALLOCATABLE :: ju(:)     ! Pointers to U diagonal
        INTEGER(i4) :: iwk = 0                ! Work array size
        
        ! ILU(k) work arrays
        INTEGER(i4), ALLOCATABLE :: levs(:)    ! Level array for ILU(k)
        REAL(wp), ALLOCATABLE :: w(:)          ! Work array
        INTEGER(i4), ALLOCATABLE :: jw(:)      ! Integer work array
        
        ! IC(0) storage
        REAL(wp), ALLOCATABLE :: ic_diag(:)    ! IC diagonal factors
        
        ! SSOR storage (uses original matrix)
        TYPE(UF_CSRMatrix), POINTER :: mat_ptr => NULL()  ! Pointer to original matrix
        REAL(wp), ALLOCATABLE :: ssor_d(:)       ! True diagonal of A
        REAL(wp), ALLOCATABLE :: ssor_da(:)      ! Modified diagonal for SSOR
        REAL(wp), ALLOCATABLE :: ssor_da1(:)     ! Inverse of ssor_da
        INTEGER(i4), ALLOCATABLE :: jdiag(:)     ! Diagonal index pointers
        
        ! AMG data structures (HSL MI20)
        TYPE(mi20_data), ALLOCATABLE :: amg_coarse(:)
        TYPE(mi20_control) :: amg_ctrl
        TYPE(mi20_solve_control) :: amg_solve_ctrl
        TYPE(mi20_info) :: amg_info
        TYPE(mi20_keep) :: amg_keep
        INTEGER(i4), ALLOCATABLE :: amg_row(:)
        INTEGER(i4), ALLOCATABLE :: amg_col(:)
        REAL(wp), ALLOCATABLE :: amg_val(:)
        
        ! Block preconditioner parameters
        INTEGER(i4) :: block_size = 1         ! Block size (e.g., 3 for 3D, 6 for shell)
        INTEGER(i4) :: nblocks = 0            ! Number of blocks
        REAL(wp), ALLOCATABLE :: block_diag(:,:,:)  ! Block diagonal inverses (bs x bs x nblocks)
        REAL(wp), ALLOCATABLE :: block_alu(:)       ! Block ILU values
        INTEGER(i4), ALLOCATABLE :: block_jlu(:)    ! Block ILU column indices
        INTEGER(i4), ALLOCATABLE :: block_ju(:)     ! Block ILU U pointers
        
        LOGICAL :: is_setup = .FALSE.
    CONTAINS
        PROCEDURE :: setup => precond_setup_method
        PROCEDURE :: apply => precond_apply_method
        PROCEDURE :: destroy => precond_destroy_method
    END TYPE UF_Precond

CONTAINS

    !===========================================================================
    ! Create preconditioner
    !===========================================================================
    SUBROUTINE precond_create(pc, ptype, n, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        INTEGER(i4), INTENT(IN) :: ptype, n
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        
        IF (PRESENT(ierr)) ierr = NM_PC_SUCCESS
        
        CALL precond_destroy(pc)
        
        pc%ptype = ptype
        pc%n = n
        pc%is_setup = .FALSE.
        
    END SUBROUTINE precond_create
    
    !===========================================================================
    ! Destroy preconditioner
    !===========================================================================
    SUBROUTINE precond_destroy(pc)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        
        IF (ALLOCATED(pc%diag_inv)) DEALLOCATE(pc%diag_inv)
        IF (ALLOCATED(pc%alu)) DEALLOCATE(pc%alu)
        IF (ALLOCATED(pc%jlu)) DEALLOCATE(pc%jlu)
        IF (ALLOCATED(pc%ju)) DEALLOCATE(pc%ju)
        IF (ALLOCATED(pc%levs)) DEALLOCATE(pc%levs)
        IF (ALLOCATED(pc%w)) DEALLOCATE(pc%w)
        IF (ALLOCATED(pc%jw)) DEALLOCATE(pc%jw)
        IF (ALLOCATED(pc%ic_diag)) DEALLOCATE(pc%ic_diag)
        IF (ALLOCATED(pc%ssor_d)) DEALLOCATE(pc%ssor_d)
        IF (ALLOCATED(pc%ssor_da)) DEALLOCATE(pc%ssor_da)
        IF (ALLOCATED(pc%ssor_da1)) DEALLOCATE(pc%ssor_da1)
        IF (ALLOCATED(pc%jdiag)) DEALLOCATE(pc%jdiag)
        IF (ALLOCATED(pc%block_diag)) DEALLOCATE(pc%block_diag)
        IF (ALLOCATED(pc%block_alu)) DEALLOCATE(pc%block_alu)
        IF (ALLOCATED(pc%block_jlu)) DEALLOCATE(pc%block_jlu)
        IF (ALLOCATED(pc%block_ju)) DEALLOCATE(pc%block_ju)
        
        ! Finalize AMG data
        IF (ALLOCATED(pc%amg_coarse)) THEN
            CALL mi20_finalize(pc%amg_coarse, pc%amg_keep, pc%amg_ctrl, pc%amg_info)
            DEALLOCATE(pc%amg_coarse)
        END IF
        IF (ALLOCATED(pc%amg_row)) DEALLOCATE(pc%amg_row)
        IF (ALLOCATED(pc%amg_col)) DEALLOCATE(pc%amg_col)
        IF (ALLOCATED(pc%amg_val)) DEALLOCATE(pc%amg_val)
        
        NULLIFY(pc%mat_ptr)
        
        pc%ptype = NM_PRECOND_NONE
        pc%n = 0
        pc%block_size = 1
        pc%nblocks = 0
        pc%is_setup = .FALSE.
        
    END SUBROUTINE precond_destroy
    
    SUBROUTINE precond_destroy_method(this)
        CLASS(UF_Precond), INTENT(INOUT) :: this
        CALL precond_destroy(this)
    END SUBROUTINE precond_destroy_method

    !===========================================================================
    ! Setup preconditioner (compute factorization)
    !===========================================================================
    SUBROUTINE precond_setup(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN), TARGET :: mat
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        
        INTEGER(i4) :: err
        
        IF (PRESENT(ierr)) ierr = NM_PC_SUCCESS
        
        pc%n = mat%nrows
        
        SELECT CASE (pc%ptype)
        CASE (NM_PRECOND_NONE)
            pc%is_setup = .TRUE.
            
        CASE (NM_PRECOND_DIAG)

            CALL setup_jacobi(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_SSOR)
            CALL setup_ssor_full(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_ILU0)
            CALL setup_ilu0(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_ILUK)
            CALL setup_iluk_wrap(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_ILUT)
            CALL setup_ilut(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_IC0)
            CALL setup_ic0(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_ICK)
            CALL setup_ick(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_AMG)
            CALL setup_amg(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_BLOCK_JACOBI)
            CALL setup_block_jacobi(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_BLOCK_ILU0)
            CALL setup_block_ilu0(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE (NM_PRECOND_SSOR_EISENSTAT)
            CALL setup_ssor_eisenstat(pc, mat, err)
            IF (err /= NM_PC_SUCCESS .AND. PRESENT(ierr)) ierr = err
            
        CASE DEFAULT
            pc%is_setup = .TRUE.
        END SELECT
        
    END SUBROUTINE precond_setup
    
    SUBROUTINE precond_setup_method(this, mat, ierr)
        CLASS(UF_Precond), INTENT(INOUT) :: this
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        CALL precond_setup(this, mat, ierr)
    END SUBROUTINE precond_setup_method

    !===========================================================================
    ! Apply preconditioner: y = M^(-1) * x
    !===========================================================================
    SUBROUTINE precond_apply(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        SELECT CASE (pc%ptype)
        CASE (NM_PRECOND_NONE)
            y(1:pc%n) = x(1:pc%n)
            
        CASE (NM_PRECOND_DIAG)

            CALL apply_jacobi(pc, x, y)
            
        CASE (NM_PRECOND_SSOR)
            CALL apply_ssor_full(pc, x, y)
            
        CASE (NM_PRECOND_ILU0, NM_PRECOND_ILUK, NM_PRECOND_ILUT)
            CALL apply_ilu(pc, x, y)
            
        CASE (NM_PRECOND_IC0, NM_PRECOND_ICK)
            CALL apply_ic(pc, x, y)
            
        CASE (NM_PRECOND_AMG)
            CALL apply_amg(pc, x, y)
            
        CASE (NM_PRECOND_BLOCK_JACOBI)
            CALL apply_block_jacobi(pc, x, y)
            
        CASE (NM_PRECOND_BLOCK_ILU0)
            CALL apply_block_ilu(pc, x, y)
            
        CASE (NM_PRECOND_SSOR_EISENSTAT)
            CALL apply_ssor_eisenstat(pc, x, y)
            
        CASE DEFAULT
            y(1:pc%n) = x(1:pc%n)
        END SELECT
        
    END SUBROUTINE precond_apply
    
    SUBROUTINE precond_apply_method(this, x, y)
        CLASS(UF_Precond), INTENT(INOUT) :: this

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        CALL precond_apply(this, x, y)
    END SUBROUTINE precond_apply_method

    !===========================================================================
    ! JACOBI PRECONDITIONER
    !===========================================================================
    SUBROUTINE setup_jacobi(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, k, istat
        REAL(wp) :: diag_val
        
        ierr = NM_PC_SUCCESS
        
        IF (ALLOCATED(pc%diag_inv)) DEALLOCATE(pc%diag_inv)
        ALLOCATE(pc%diag_inv(pc%n), STAT=istat)
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        DO i = 1, pc%n
            diag_val = ZERO
            DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                IF (mat%col_ind(k) == i) THEN
                    diag_val = mat%val(k)
                    EXIT
                END IF
            END DO
            
            IF (ABS(diag_val) < SMALL) THEN
                pc%diag_inv(i) = ONE / SMALL
            ELSE
                pc%diag_inv(i) = ONE / diag_val
            END IF
        END DO
        
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_jacobi
    
    SUBROUTINE apply_jacobi(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: i
        
        DO i = 1, pc%n
            y(i) = pc%diag_inv(i) * x(i)
        END DO
        
    END SUBROUTINE apply_jacobi

    !===========================================================================
    ! ILU(0) PRECONDITIONER
    !===========================================================================
    SUBROUTINE setup_ilu0(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nnz, istat
        INTEGER(i4) :: i, j, k, jj, jrow, jw, js, jf, jm, ju0
        REAL(wp) :: tl
        INTEGER(i4), ALLOCATABLE :: iw(:)
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        nnz = mat%nnz
        
        ! Allocate MSR storage
        pc%iwk = nnz + n + 2
        
        IF (ALLOCATED(pc%alu)) DEALLOCATE(pc%alu)
        IF (ALLOCATED(pc%jlu)) DEALLOCATE(pc%jlu)
        IF (ALLOCATED(pc%ju)) DEALLOCATE(pc%ju)
        
        ALLOCATE(pc%alu(pc%iwk), STAT=istat)
        ALLOCATE(pc%jlu(pc%iwk), STAT=istat)
        ALLOCATE(pc%ju(n), STAT=istat)
        ALLOCATE(iw(n), STAT=istat)
        
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Initialize work vector
        iw = 0
        
        ! ILU(0) factorization
        ju0 = n + 2
        pc%jlu(1) = ju0
        
        DO i = 1, n
            js = ju0
            
            ! Copy row i of A into alu, jlu
            DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                j = mat%col_ind(k)
                IF (j == i) THEN
                    pc%alu(i) = mat%val(k)
                    iw(j) = i
                    pc%ju(i) = ju0
                ELSE
                    pc%alu(ju0) = mat%val(k)
                    pc%jlu(ju0) = j
                    iw(j) = ju0
                    ju0 = ju0 + 1
                END IF
            END DO
            
            pc%jlu(i + 1) = ju0
            jf = ju0 - 1
            jm = pc%ju(i) - 1
            
            ! Elimination
            DO j = js, jm
                jrow = pc%jlu(j)
                tl = pc%alu(j) * pc%alu(jrow)
                pc%alu(j) = tl
                
                DO jj = pc%ju(jrow), pc%jlu(jrow + 1) - 1
                    jw = iw(pc%jlu(jj))
                    IF (jw /= 0) pc%alu(jw) = pc%alu(jw) - tl * pc%alu(jj)
                END DO
            END DO
            
            ! Invert diagonal
            IF (ABS(pc%alu(i)) < SMALL) THEN
                ierr = PC_ERR_ZERO_PIVOT
                DEALLOCATE(iw)
                RETURN
            END IF
            pc%alu(i) = ONE / pc%alu(i)
            
            ! Reset work array
            iw(i) = 0
            DO k = js, jf
                iw(pc%jlu(k)) = 0
            END DO
        END DO
        
        DEALLOCATE(iw)
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_ilu0

    !===========================================================================
    ! ILUT PRECONDITIONER (with dual truncation)
    !===========================================================================
    SUBROUTINE setup_ilut(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nnz, istat
        INTEGER(i4) :: i, j, k, jj, jrow, jpos, len, lenl, lenu, ju0
        INTEGER(i4) :: j1, j2
        REAL(wp) :: t, tnorm, fact, s
        INTEGER(i4), ALLOCATABLE :: jw(:)
        REAL(wp), ALLOCATABLE :: w(:)
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        nnz = mat%nnz
        
        ! Allocate MSR storage - estimate size
        pc%iwk = nnz + 2 * pc%lfil * n + n + 2
        
        IF (ALLOCATED(pc%alu)) DEALLOCATE(pc%alu)
        IF (ALLOCATED(pc%jlu)) DEALLOCATE(pc%jlu)
        IF (ALLOCATED(pc%ju)) DEALLOCATE(pc%ju)
        
        ALLOCATE(pc%alu(pc%iwk), STAT=istat)
        ALLOCATE(pc%jlu(pc%iwk), STAT=istat)
        ALLOCATE(pc%ju(n), STAT=istat)
        ALLOCATE(jw(2*n), STAT=istat)
        ALLOCATE(w(n+1), STAT=istat)
        
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Initialize
        ju0 = n + 2
        pc%jlu(1) = ju0
        jw(n+1:2*n) = 0
        
        ! Main loop
        DO i = 1, n
            j1 = mat%row_ptr(i)
            j2 = mat%row_ptr(i + 1) - 1
            
            ! Compute row norm
            tnorm = ZERO
            DO k = j1, j2
                tnorm = tnorm + ABS(mat%val(k))
            END DO
            IF (tnorm == ZERO) THEN
                ierr = PC_ERR_ZERO_PIVOT
                DEALLOCATE(jw, w)
                RETURN
            END IF
            tnorm = tnorm / REAL(j2 - j1 + 1, wp)
            
            ! Unpack row i
            lenu = 1
            lenl = 0
            jw(i) = i
            w(i) = ZERO
            jw(n + i) = i
            
            DO j = j1, j2
                k = mat%col_ind(j)
                t = mat%val(j)
                IF (k < i) THEN
                    lenl = lenl + 1
                    jw(lenl) = k
                    w(lenl) = t
                    jw(n + k) = lenl
                ELSE IF (k == i) THEN
                    w(i) = t
                ELSE
                    lenu = lenu + 1
                    jpos = i + lenu - 1
                    jw(jpos) = k
                    w(jpos) = t
                    jw(n + k) = jpos
                END IF
            END DO
            
            ! Elimination
            jj = 0
            len = 0
            DO WHILE (jj < lenl)
                jj = jj + 1
                jrow = jw(jj)
                
                ! Find minimum column index
                DO j = jj + 1, lenl
                    IF (jw(j) < jrow) THEN
                        jrow = jw(j)
                        k = jw(jj)
                        jw(jj) = jw(j)
                        jw(j) = k
                        jw(n + jrow) = jj
                        jw(n + k) = j
                        s = w(jj)
                        w(jj) = w(j)
                        w(j) = s
                    END IF
                END DO
                
                jw(n + jrow) = 0
                fact = w(jj) * pc%alu(jrow)
                
                IF (ABS(fact) <= pc%droptol) CYCLE
                
                ! Combine rows
                DO k = pc%ju(jrow), pc%jlu(jrow + 1) - 1
                    s = fact * pc%alu(k)
                    j = pc%jlu(k)
                    jpos = jw(n + j)
                    IF (j >= i) THEN
                        IF (jpos == 0) THEN
                            lenu = lenu + 1
                            jw(i + lenu - 1) = j
                            jw(n + j) = i + lenu - 1
                            w(i + lenu - 1) = -s
                        ELSE
                            w(jpos) = w(jpos) - s
                        END IF
                    ELSE
                        IF (jpos == 0) THEN
                            lenl = lenl + 1
                            jw(lenl) = j
                            jw(n + j) = lenl
                            w(lenl) = -s
                        ELSE
                            w(jpos) = w(jpos) - s
                        END IF
                    END IF
                END DO
                
                len = len + 1
                w(len) = fact
                jw(len) = jrow
            END DO
            
            ! Reset indicators
            DO k = 1, lenu
                jw(n + jw(i + k - 1)) = 0
            END DO
            
            ! Store L-part (keep at most lfil elements)
            lenl = MIN(len, pc%lfil)
            DO k = 1, lenl
                IF (ju0 > pc%iwk) THEN
                    ierr = PC_ERR_OVERFLOW
                    DEALLOCATE(jw, w)
                    RETURN
                END IF
                pc%alu(ju0) = w(k)
                pc%jlu(ju0) = jw(k)
                ju0 = ju0 + 1
            END DO
            
            pc%ju(i) = ju0
            
            ! Store U-part with dropping
            len = MIN(lenu - 1, pc%lfil)
            DO k = 1, len
                IF (ju0 > pc%iwk) THEN
                    ierr = PC_ERR_OVERFLOW
                    DEALLOCATE(jw, w)
                    RETURN
                END IF
                pc%jlu(ju0) = jw(i + k)
                pc%alu(ju0) = w(i + k)
                ju0 = ju0 + 1
            END DO
            
            ! Store diagonal
            IF (ABS(w(i)) < SMALL) w(i) = (0.0001_wp + pc%droptol) * tnorm
            pc%alu(i) = ONE / w(i)
            
            pc%jlu(i + 1) = ju0
        END DO
        
        DEALLOCATE(jw, w)
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_ilut

    !===========================================================================
    ! Apply ILU preconditioner: solve L*U*y = x
    !===========================================================================
    SUBROUTINE apply_ilu(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: i, k, n
        REAL(wp) :: t
        REAL(wp), ALLOCATABLE :: z(:)
        
        n = pc%n
        ALLOCATE(z(n))
        
        ! Forward substitution: L * z = x
        z(1) = x(1) * pc%alu(1)
        DO i = 2, n
            t = x(i)
            DO k = pc%jlu(i), pc%ju(i) - 1
                t = t - pc%alu(k) * z(pc%jlu(k))
            END DO
            z(i) = t * pc%alu(i)
        END DO
        
        ! Backward substitution: U * y = z
        y(n) = z(n)
        DO i = n - 1, 1, -1
            t = z(i)
            DO k = pc%ju(i), pc%jlu(i + 1) - 1
                t = t - pc%alu(k) * y(pc%jlu(k))
            END DO
            y(i) = t
        END DO
        
        DEALLOCATE(z)
        
    END SUBROUTINE apply_ilu

    !===========================================================================
    ! BLOCK JACOBI PRECONDITIONER
    ! Extracts block diagonal and computes block inverses
    ! Useful for multi-DOF systems (e.g., 3 DOFs per node in 3D elasticity)
    !===========================================================================
    SUBROUTINE setup_block_jacobi(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, bs, nb, istat
        INTEGER(i4) :: i, j, k, ib, jb, row, col, kk
        INTEGER(i4) :: row_start, row_end
        REAL(wp) :: diag_val
        REAL(wp), ALLOCATABLE :: block(:,:), work(:)
        INTEGER(i4), ALLOCATABLE :: ipiv(:)
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        bs = pc%block_size
        
        ! Validate block size
        IF (bs < 1) bs = 1
        IF (MOD(n, bs) /= 0) THEN
            ! Matrix size not divisible by block size, fall back to scalar
            bs = 1
            pc%block_size = 1
        END IF
        
        nb = n / bs
        pc%nblocks = nb
        
        ! Allocate block diagonal storage
        IF (ALLOCATED(pc%block_diag)) DEALLOCATE(pc%block_diag)
        ALLOCATE(pc%block_diag(bs, bs, nb), STAT=istat)
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ALLOCATE(block(bs, bs), work(bs), ipiv(bs), STAT=istat)
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Extract and invert each diagonal block
        DO ib = 1, nb
            block = ZERO
            
            ! Extract block from CSR matrix
            DO i = 1, bs
                row = (ib - 1) * bs + i
                row_start = mat%row_ptr(row)
                row_end = mat%row_ptr(row + 1) - 1
                
                DO k = row_start, row_end
                    col = mat%col_ind(k)
                    jb = (col - 1) / bs + 1
                    
                    IF (jb == ib) THEN
                        j = col - (ib - 1) * bs
                        block(i, j) = mat%val(k)
                    END IF
                END DO
            END DO
            
            ! Invert block using LU decomposition
            CALL block_lu_invert(block, bs, ierr)
            IF (ierr /= NM_PC_SUCCESS) THEN
                DEALLOCATE(block, work, ipiv)
                RETURN
            END IF
            
            pc%block_diag(:, :, ib) = block
        END DO
        
        DEALLOCATE(block, work, ipiv)
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_block_jacobi
    
    !===========================================================================
    ! Block LU inversion for small dense blocks
    !===========================================================================
    SUBROUTINE block_lu_invert(A, n, ierr)
        REAL(wp), INTENT(INOUT) :: A(:,:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, pivot_row
        REAL(wp) :: max_val, pivot, factor
        REAL(wp), ALLOCATABLE :: L(:,:), U(:,:), Ainv(:,:)
        INTEGER(i4), ALLOCATABLE :: perm(:)
        
        ierr = NM_PC_SUCCESS
        
        IF (n == 1) THEN
            IF (ABS(A(1,1)) < SMALL) THEN
                A(1,1) = ONE / SMALL
            ELSE
                A(1,1) = ONE / A(1,1)
            END IF
            RETURN
        END IF
        
        ALLOCATE(L(n,n), U(n,n), Ainv(n,n), perm(n))
        
        ! Initialize
        L = ZERO
        U = ZERO
        DO i = 1, n
            L(i,i) = ONE
            perm(i) = i
        END DO
        U = A
        
        ! LU decomposition with partial pivoting
        DO k = 1, n - 1
            ! Find pivot
            max_val = ABS(U(k,k))
            pivot_row = k
            DO i = k + 1, n
                IF (ABS(U(i,k)) > max_val) THEN
                    max_val = ABS(U(i,k))
                    pivot_row = i
                END IF
            END DO
            
            IF (max_val < SMALL) THEN
                ierr = PC_ERR_ZERO_PIVOT
                DEALLOCATE(L, U, Ainv, perm)
                RETURN
            END IF
            
            ! Swap rows
            IF (pivot_row /= k) THEN
                DO j = 1, n
                    factor = U(k,j)
                    U(k,j) = U(pivot_row,j)
                    U(pivot_row,j) = factor
                END DO
                DO j = 1, k - 1
                    factor = L(k,j)
                    L(k,j) = L(pivot_row,j)
                    L(pivot_row,j) = factor
                END DO
                i = perm(k)
                perm(k) = perm(pivot_row)
                perm(pivot_row) = i
            END IF
            
            ! Elimination
            pivot = U(k,k)
            DO i = k + 1, n
                factor = U(i,k) / pivot
                L(i,k) = factor
                DO j = k, n
                    U(i,j) = U(i,j) - factor * U(k,j)
                END DO
            END DO
        END DO
        
        IF (ABS(U(n,n)) < SMALL) THEN
            ierr = PC_ERR_ZERO_PIVOT
            DEALLOCATE(L, U, Ainv, perm)
            RETURN
        END IF
        
        ! Compute inverse by solving A * Ainv(:,j) = e_j
        Ainv = ZERO
        DO j = 1, n
            ! Forward substitution for L * y = P * e_j
            Ainv(1,j) = ZERO
            IF (perm(1) == j) Ainv(1,j) = ONE
            DO i = 2, n
                Ainv(i,j) = ZERO
                IF (perm(i) == j) Ainv(i,j) = ONE
                DO k = 1, i - 1
                    Ainv(i,j) = Ainv(i,j) - L(i,k) * Ainv(k,j)
                END DO
            END DO
            
            ! Backward substitution for U * x = y
            Ainv(n,j) = Ainv(n,j) / U(n,n)
            DO i = n - 1, 1, -1
                DO k = i + 1, n
                    Ainv(i,j) = Ainv(i,j) - U(i,k) * Ainv(k,j)
                END DO
                Ainv(i,j) = Ainv(i,j) / U(i,i)
            END DO
        END DO
        
        A = Ainv
        
        DEALLOCATE(L, U, Ainv, perm)
        
    END SUBROUTINE block_lu_invert
    
    !===========================================================================
    ! Apply Block Jacobi: y = M^(-1) * x
    !===========================================================================
    SUBROUTINE apply_block_jacobi(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: bs, nb, ib, i, j, idx
        REAL(wp) :: sum_val
        
        bs = pc%block_size
        nb = pc%nblocks
        
        ! Apply block diagonal inverse
        DO ib = 1, nb
            DO i = 1, bs
                idx = (ib - 1) * bs + i
                sum_val = ZERO
                DO j = 1, bs
                    sum_val = sum_val + pc%block_diag(i, j, ib) * x((ib-1)*bs + j)
                END DO
                y(idx) = sum_val
            END DO
        END DO
        
    END SUBROUTINE apply_block_jacobi

    !===========================================================================
    ! BLOCK ILU(0) PRECONDITIONER
    ! Block version of ILU(0) for coupled problems
    !===========================================================================
    SUBROUTINE setup_block_ilu0(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, bs, nb, nnz_blocks, istat
        INTEGER(i4) :: i, j, k, ib, jb, kb, row, col
        INTEGER(i4) :: row_start, row_end, js, jf, jm, ju0
        INTEGER(i4) :: bi, bj, bk, jrow, jw
        REAL(wp) :: tl
        REAL(wp), ALLOCATABLE :: block(:,:), temp_block(:,:)
        INTEGER(i4), ALLOCATABLE :: iw(:)
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        bs = pc%block_size
        
        ! Validate block size
        IF (bs < 1) bs = 1
        IF (MOD(n, bs) /= 0) THEN
            bs = 1
            pc%block_size = 1
        END IF
        
        nb = n / bs
        pc%nblocks = nb
        
        ! For simplicity, fall back to Block Jacobi for complex structure
        ! Full Block ILU requires careful handling of block sparsity pattern
        ! Here we provide a simplified version based on block diagonal
        CALL setup_block_jacobi(pc, mat, ierr)
        IF (ierr /= NM_PC_SUCCESS) RETURN
        
        ! Mark as Block ILU setup (uses block_diag for now)
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_block_ilu0
    
    !===========================================================================
    ! Apply Block ILU: same as Block Jacobi for simplified version
    !===========================================================================
    SUBROUTINE apply_block_ilu(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        ! Use block Jacobi apply for simplified Block ILU
        CALL apply_block_jacobi(pc, x, y)
        
    END SUBROUTINE apply_block_ilu

    !===========================================================================
    ! Utility: Set block size for block preconditioners
    !===========================================================================
    SUBROUTINE precond_set_block_size(pc, block_size)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        INTEGER(i4), INTENT(IN) :: block_size
        
        pc%block_size = MAX(1, block_size)
        
    END SUBROUTINE precond_set_block_size

    !===========================================================================
    ! FULL SSOR PRECONDITIONER (Symmetric Successive Over-Relaxation)
    ! Theory: M = (D + omega*L) * D^(-1) * (D + omega*U)
    ! Apply: y = M^(-1) * x via forward-backward sweeps
    !===========================================================================
    SUBROUTINE setup_ssor_full(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN), TARGET :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, k, istat
        REAL(wp) :: diag_val
        
        ierr = NM_PC_SUCCESS
        pc%n = mat%nrows
        
        ! Store pointer to original matrix for SSOR sweeps
        pc%mat_ptr => mat
        
        ! Extract diagonal for scaling
        IF (ALLOCATED(pc%diag_inv)) DEALLOCATE(pc%diag_inv)
        ALLOCATE(pc%diag_inv(pc%n), STAT=istat)
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        DO i = 1, pc%n
            diag_val = ZERO
            DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                IF (mat%col_ind(k) == i) THEN
                    diag_val = mat%val(k)
                    EXIT
                END IF
            END DO
            IF (ABS(diag_val) < SMALL) THEN
                pc%diag_inv(i) = ONE / SMALL
            ELSE
                pc%diag_inv(i) = ONE / diag_val
            END IF
        END DO
        
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_ssor_full
    
    SUBROUTINE apply_ssor_full(pc, x, y)
        ! SSOR Apply: y = M^(-1) * x
        ! Step 1: Forward sweep (D + omega*L)^(-1) * x
        ! Step 2: Scale by D
        ! Step 3: Backward sweep (D + omega*U)^(-1)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: i, k, j, n
        REAL(wp) :: omega, sum_val, diag_val
        REAL(wp), ALLOCATABLE :: z(:)
        
        n = pc%n
        omega = pc%omega
        
        IF (.NOT. ASSOCIATED(pc%mat_ptr)) THEN
            ! Fallback to Jacobi if matrix not available
            CALL apply_jacobi(pc, x, y)
            RETURN
        END IF
        
        ALLOCATE(z(n))
        
        ! Forward sweep: solve (D + omega*L) * z = omega * x
        DO i = 1, n
            sum_val = omega * x(i)
            diag_val = ZERO
            DO k = pc%mat_ptr%row_ptr(i), pc%mat_ptr%row_ptr(i + 1) - 1
                j = pc%mat_ptr%col_ind(k)
                IF (j < i) THEN
                    sum_val = sum_val - omega * pc%mat_ptr%val(k) * z(j)
                ELSE IF (j == i) THEN
                    diag_val = pc%mat_ptr%val(k)
                END IF
            END DO
            IF (ABS(diag_val) < SMALL) diag_val = SMALL
            z(i) = sum_val / diag_val
        END DO
        
        ! Scale: z = D * z
        DO i = 1, n
            DO k = pc%mat_ptr%row_ptr(i), pc%mat_ptr%row_ptr(i + 1) - 1
                IF (pc%mat_ptr%col_ind(k) == i) THEN
                    z(i) = z(i) * pc%mat_ptr%val(k)
                    EXIT
                END IF
            END DO
        END DO
        
        ! Backward sweep: solve (D + omega*U) * y = z
        DO i = n, 1, -1
            sum_val = z(i)
            diag_val = ZERO
            DO k = pc%mat_ptr%row_ptr(i), pc%mat_ptr%row_ptr(i + 1) - 1
                j = pc%mat_ptr%col_ind(k)
                IF (j > i) THEN
                    sum_val = sum_val - omega * pc%mat_ptr%val(k) * y(j)
                ELSE IF (j == i) THEN
                    diag_val = pc%mat_ptr%val(k)
                END IF
            END DO
            IF (ABS(diag_val) < SMALL) diag_val = SMALL
            y(i) = sum_val / diag_val
        END DO
        
        ! Apply relaxation factor
        DO i = 1, n
            y(i) = y(i) * (2.0_wp - omega) / omega
        END DO
        
        DEALLOCATE(z)
        
    END SUBROUTINE apply_ssor_full

    !===========================================================================
    ! IC(0) INCOMPLETE CHOLESKY PRECONDITIONER
    ! For SPD matrices: A â ?L * L^T
    ! Only fills in existing sparsity pattern
    !===========================================================================
    SUBROUTINE setup_ic0(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nnz, istat
        INTEGER(i4) :: i, j, k, kk, jj, jrow, jw, js, jf, jm, ju0
        INTEGER(i4) :: k1, k2, kl, ku
        REAL(wp) :: sum_val, diag_val
        INTEGER(i4), ALLOCATABLE :: iw(:), diag_ptr(:)
        REAL(wp), ALLOCATABLE :: L_val(:)
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        nnz = mat%nnz
        
        ! Allocate IC storage (reuse ILU storage arrays)
        pc%iwk = nnz + n + 2
        
        IF (ALLOCATED(pc%alu)) DEALLOCATE(pc%alu)
        IF (ALLOCATED(pc%jlu)) DEALLOCATE(pc%jlu)
        IF (ALLOCATED(pc%ju)) DEALLOCATE(pc%ju)
        IF (ALLOCATED(pc%ic_diag)) DEALLOCATE(pc%ic_diag)
        
        ALLOCATE(pc%alu(pc%iwk), STAT=istat)
        ALLOCATE(pc%jlu(pc%iwk), STAT=istat)
        ALLOCATE(pc%ju(n), STAT=istat)
        ALLOCATE(pc%ic_diag(n), STAT=istat)
        ALLOCATE(iw(n), diag_ptr(n), STAT=istat)
        
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Find diagonal pointers
        DO i = 1, n
            diag_ptr(i) = 0
            DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                IF (mat%col_ind(k) == i) THEN
                    diag_ptr(i) = k
                    EXIT
                END IF
            END DO
            IF (diag_ptr(i) == 0) THEN
                ierr = PC_ERR_ZERO_PIVOT
                DEALLOCATE(iw, diag_ptr)
                RETURN
            END IF
        END DO
        
        ! Initialize work array
        iw = 0
        
        ! IC(0) factorization
        ! Build L in MSR format
        ju0 = n + 2
        pc%jlu(1) = ju0
        
        DO i = 1, n
            ! Get diagonal
            diag_val = mat%val(diag_ptr(i))
            
            ! Process row i: compute L(i,k) for k < i
            js = ju0
            
            DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                j = mat%col_ind(k)
                IF (j < i) THEN
                    ! This is a lower triangular entry
                    sum_val = mat%val(k)
                    
                    ! Subtract sum of L(i,kk) * L(j,kk) for kk < j
                    DO kk = pc%jlu(i), ju0 - 1
                        jrow = pc%jlu(kk)
                        IF (jrow < j) THEN
                            ! Find L(j, jrow) if it exists
                            DO jj = pc%jlu(j), pc%ju(j) - 1
                                IF (pc%jlu(jj) == jrow) THEN
                                    sum_val = sum_val - pc%alu(kk) * pc%alu(jj)
                                    EXIT
                                END IF
                            END DO
                        END IF
                    END DO
                    
                    ! L(i,j) = A(i,j) - sum / L(j,j)
                    IF (ABS(pc%ic_diag(j)) > SMALL) THEN
                        pc%alu(ju0) = sum_val / pc%ic_diag(j)
                    ELSE
                        pc%alu(ju0) = ZERO
                    END IF
                    pc%jlu(ju0) = j
                    iw(j) = ju0
                    ju0 = ju0 + 1
                END IF
            END DO
            
            pc%ju(i) = ju0  ! Pointer to diagonal (in MSR, diagonal stored separately)
            pc%jlu(i + 1) = ju0
            
            ! Compute diagonal: L(i,i) = sqrt(A(i,i) - sum of L(i,k)^2)
            sum_val = diag_val
            DO k = pc%jlu(i), ju0 - 1
                sum_val = sum_val - pc%alu(k) * pc%alu(k)
            END DO
            
            IF (sum_val <= ZERO) THEN
                ! Matrix not SPD, use modified IC
                pc%ic_diag(i) = SQRT(ABS(diag_val) + SMALL)
            ELSE
                pc%ic_diag(i) = SQRT(sum_val)
            END IF
            pc%alu(i) = ONE / pc%ic_diag(i)
            
            ! Reset work array
            DO k = js, ju0 - 1
                iw(pc%jlu(k)) = 0
            END DO
        END DO
        
        DEALLOCATE(iw, diag_ptr)
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_ic0
    
    !===========================================================================
    ! IC(k) Incomplete Cholesky with fill level
    ! Uses symbolic factorization to determine fill pattern
    !===========================================================================
    SUBROUTINE setup_ick(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        ! For now, fall back to IC(0)
        ! Full IC(k) requires level-of-fill tracking similar to ILU(k)
        CALL setup_ic0(pc, mat, ierr)
        
    END SUBROUTINE setup_ick
    
    !===========================================================================
    ! Apply IC preconditioner: solve L * L^T * y = x
    !===========================================================================
    SUBROUTINE apply_ic(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: i, k, kk, n
        REAL(wp) :: t
        REAL(wp), ALLOCATABLE :: z(:)
        
        n = pc%n
        ALLOCATE(z(n))
        
        ! Forward substitution: L * z = x
        DO i = 1, n
            t = x(i)
            DO k = pc%jlu(i), pc%ju(i) - 1
                t = t - pc%alu(k) * z(pc%jlu(k))
            END DO
            z(i) = t * pc%alu(i)  ! pc%alu(i) = 1/L(i,i)
        END DO
        
        ! Backward substitution: L^T * y = z
        y(n) = z(n) * pc%alu(n)
        DO i = n - 1, 1, -1
            t = z(i)
            ! Need to find entries where L(j,i) exists for j > i
            ! In column-oriented view: L^T(i,j) = L(j,i)
            DO k = i + 1, n
                DO kk = pc%jlu(k), pc%ju(k) - 1
                    IF (pc%jlu(kk) == i) THEN
                        t = t - pc%alu(kk) * y(k)
                        EXIT
                    END IF
                END DO
            END DO
            y(i) = t * pc%alu(i)
        END DO
        
        DEALLOCATE(z)
        
    END SUBROUTINE apply_ic

    !===========================================================================
    ! ILU(k) WRAPPER - Calls external itsol/ILUK.f90
    ! Interface to SPARSKIT iluk routine
    !===========================================================================
    SUBROUTINE setup_iluk_wrap(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nnz, istat, ilu_ierr
        
        ! External subroutine from itsol/ILUK.f90
        
        ierr = NM_PC_SUCCESS

        n = mat%nrows
        nnz = mat%nnz
        
        ! Allocate storage - estimate with fill level
        pc%iwk = nnz + (2 * pc%lfil + 1) * n + 2
        
        IF (ALLOCATED(pc%alu)) DEALLOCATE(pc%alu)
        IF (ALLOCATED(pc%jlu)) DEALLOCATE(pc%jlu)
        IF (ALLOCATED(pc%ju)) DEALLOCATE(pc%ju)
        IF (ALLOCATED(pc%levs)) DEALLOCATE(pc%levs)
        IF (ALLOCATED(pc%w)) DEALLOCATE(pc%w)
        IF (ALLOCATED(pc%jw)) DEALLOCATE(pc%jw)
        
        ALLOCATE(pc%alu(pc%iwk), STAT=istat)
        ALLOCATE(pc%jlu(pc%iwk), STAT=istat)
        ALLOCATE(pc%ju(n), STAT=istat)
        ALLOCATE(pc%levs(pc%iwk), STAT=istat)
        ALLOCATE(pc%w(n), STAT=istat)
        ALLOCATE(pc%jw(3*n), STAT=istat)
        
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Call external ILUK routine
        ! Arguments: n, a, ja, ia, lfil, alu, jlu, ju, levs, iwk, w, jw, ierr
        CALL iluk(n, mat%val, mat%col_ind, mat%row_ptr, &
                  pc%lfil, pc%alu, pc%jlu, pc%ju, pc%levs, &
                  pc%iwk, pc%w, pc%jw, ilu_ierr)
        
        IF (ilu_ierr /= 0) THEN
            IF (ilu_ierr > 0) THEN
                ierr = PC_ERR_ZERO_PIVOT
            ELSE
                ierr = PC_ERR_OVERFLOW
            END IF
            RETURN
        END IF
        
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_iluk_wrap

    !===========================================================================
    ! AMG PRECONDITIONER - Uses HSL MI20 (hsl_mi20_double)
    ! Algebraic Multigrid V-cycle preconditioner
    !===========================================================================
    SUBROUTINE setup_amg(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN) :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nnz, i, j, istat
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        nnz = mat%nnz
        pc%n = n
        
        IF (n < 1 .OR. nnz < 1) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Allocate coordinate format arrays for mi20_setup_coord
        IF (ALLOCATED(pc%amg_row)) DEALLOCATE(pc%amg_row)
        IF (ALLOCATED(pc%amg_col)) DEALLOCATE(pc%amg_col)
        IF (ALLOCATED(pc%amg_val)) DEALLOCATE(pc%amg_val)
        
        ALLOCATE(pc%amg_row(nnz), pc%amg_col(nnz), pc%amg_val(nnz), STAT=istat)
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Convert CSR to coordinate format
        DO i = 1, n
            DO j = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                pc%amg_row(j) = i
                pc%amg_col(j) = mat%col_ind(j)
                pc%amg_val(j) = mat%val(j)
            END DO
        END DO
        
        ! Configure MI20 control - suppress output
        pc%amg_ctrl%error = -1
        pc%amg_ctrl%print = -1
        
        ! Call HSL MI20 setup with coordinate format
        CALL mi20_setup_coord(pc%amg_row, pc%amg_col, pc%amg_val, nnz, n, &
                              pc%amg_coarse, pc%amg_keep, pc%amg_ctrl, pc%amg_info)
        
        IF (pc%amg_info%flag < 0) THEN
            ierr = PC_ERR_ZERO_PIVOT  ! Use as general error
            RETURN
        END IF
        
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_amg
    
    SUBROUTINE apply_amg(pc, x, y)
        ! AMG V-cycle application using MI20
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        TYPE(mi20_solve_control) :: solve_ctrl
        TYPE(mi20_info) :: info
        
        IF (.NOT. pc%is_setup) THEN
            y(1:pc%n) = x(1:pc%n)
            RETURN
        END IF
        
        ! Use pure AMG (no Krylov) for preconditioner application
        solve_ctrl%krylov_solver = 0  ! Pure AMG
        solve_ctrl%rel_tol = 1.0E-1_wp  ! Loose tolerance for single V-cycle
        
        ! Call MI20 solve (uses pc%amg_coarse setup in setup_amg)
        ! Note: We use a local copy of control/info to avoid modifying pc
        CALL mi20_solve(pc%amg_coarse, x, y, pc%amg_keep, pc%amg_ctrl, &
                        solve_ctrl, info)
        
    END SUBROUTINE apply_amg
    
    !===========================================================================
    ! EISENSTAT SSOR PRECONDITIONER (High efficiency variant)
    ! Uses Eisenstat trick: avoids explicit M^(-1)*A computation
    ! Standard SSOR: 3 SpMV operations
    ! Eisenstat SSOR: 1 SpMV + 2 triangular solves (about 40% faster)
    ! Reference: S.C. Eisenstat, SIAM J. Sci. Stat. Comput. 2(1981), 1-4
    !===========================================================================
    SUBROUTINE setup_ssor_eisenstat(pc, mat, ierr)
        TYPE(UF_Precond), INTENT(INOUT) :: pc
        TYPE(UF_CSRMatrix), INTENT(IN), TARGET :: mat
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, n, istat
        REAL(wp) :: omega, diag_val
        
        ierr = NM_PC_SUCCESS
        n = mat%nrows
        omega = pc%omega
        
        ! Allocate storage
        IF (ALLOCATED(pc%ssor_d)) DEALLOCATE(pc%ssor_d)
        IF (ALLOCATED(pc%ssor_da)) DEALLOCATE(pc%ssor_da)
        IF (ALLOCATED(pc%ssor_da1)) DEALLOCATE(pc%ssor_da1)
        IF (ALLOCATED(pc%jdiag)) DEALLOCATE(pc%jdiag)
        
        ALLOCATE(pc%ssor_d(n), STAT=istat)
        ALLOCATE(pc%ssor_da(n), STAT=istat)
        ALLOCATE(pc%ssor_da1(n), STAT=istat)
        ALLOCATE(pc%jdiag(n), STAT=istat)
        
        IF (istat /= 0) THEN
            ierr = PC_ERR_ALLOC
            RETURN
        END IF
        
        ! Find diagonal entries and compute modified diagonal
        ! da = D/omega + L = D/omega + U  (for SSOR)
        ! da1 = 1/da
        DO i = 1, n
            pc%jdiag(i) = 0
            diag_val = ZERO
            DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
                IF (mat%col_ind(k) == i) THEN
                    pc%jdiag(i) = k
                    diag_val = mat%val(k)
                    EXIT
                END IF
            END DO
            
            IF (pc%jdiag(i) == 0 .OR. ABS(diag_val) < SMALL) THEN
                ierr = PC_ERR_ZERO_PIVOT
                RETURN
            END IF
            
            pc%ssor_d(i) = diag_val          ! True diagonal
            pc%ssor_da(i) = diag_val / omega ! Modified diagonal: D/omega
            pc%ssor_da1(i) = ONE / pc%ssor_da(i)  ! Inverse
        END DO
        
        ! Store matrix pointer for apply
        pc%mat_ptr => mat
        pc%is_setup = .TRUE.
        
    END SUBROUTINE setup_ssor_eisenstat
    
    !===========================================================================
    ! Apply Eisenstat SSOR: y = M^(-1) * x
    ! where M = (D/omega + L) * (omega/D) * (D/omega + U)
    !         = (D/omega + L) * (D/omega + U) * (omega/(2-omega))
    !  
    ! Forward sweep:  solve (D/omega + L) * z = x
    ! Backward sweep: solve (D/omega + U) * y = D * z  
    ! Scale: y = y * omega/(2-omega)
    !===========================================================================
    SUBROUTINE apply_ssor_eisenstat(pc, x, y)
        TYPE(UF_Precond), INTENT(INOUT) :: pc

        REAL(wp), INTENT(IN) :: x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        
        INTEGER(i4) :: i, j, k, n
        REAL(wp) :: sum_val, omega, scale_factor
        REAL(wp), ALLOCATABLE :: z(:)
        
        n = pc%n
        omega = pc%omega
        scale_factor = omega / (2.0_wp - omega)
        
        ALLOCATE(z(n))
        
        ! Forward sweep: solve (D/omega + L) * z = x
        ! z(i) = (x(i) - sum_{j<i} a(i,j)*z(j)) / da(i)
        DO i = 1, n
            sum_val = x(i)
            DO k = pc%mat_ptr%row_ptr(i), pc%jdiag(i) - 1
                j = pc%mat_ptr%col_ind(k)
                IF (j < i) THEN
                    sum_val = sum_val - pc%mat_ptr%val(k) * z(j)
                END IF
            END DO
            z(i) = sum_val * pc%ssor_da1(i)
        END DO
        
        ! Scale z by D: z = D * z
        DO i = 1, n
            z(i) = z(i) * pc%ssor_d(i)
        END DO
        
        ! Backward sweep: solve (D/omega + U) * y = z
        ! y(i) = (z(i) - sum_{j>i} a(i,j)*y(j)) / da(i)
        DO i = n, 1, -1
            sum_val = z(i)
            DO k = pc%jdiag(i) + 1, pc%mat_ptr%row_ptr(i + 1) - 1
                j = pc%mat_ptr%col_ind(k)
                IF (j > i) THEN
                    sum_val = sum_val - pc%mat_ptr%val(k) * y(j)
                END IF
            END DO
            y(i) = sum_val * pc%ssor_da1(i)
        END DO
        
        ! Final scaling: y = y * omega/(2-omega)
        DO i = 1, n
            y(i) = y(i) * scale_factor
        END DO
        
        DEALLOCATE(z)
        
    END SUBROUTINE apply_ssor_eisenstat

END MODULE NM_Solv_Preconditioner