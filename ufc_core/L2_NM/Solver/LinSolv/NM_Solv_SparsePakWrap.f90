!===============================================================================
! MODULE: NM_Solv_SparsePakWrap
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Brg (CSR wrapper for SparsePak direct solver)
! BRIEF:  CSR-to-SparsePak conversion, RCM/QMD/ND reordering, Cholesky factor
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_SparsePakWrap
    USE IF_Prec_Core, ONLY: wp, i4
    USE NM_Mtx_Core
    IMPLICIT NONE
    PRIVATE
    
    !---------------------------------------------------------------------------
    ! Public procedures
    !---------------------------------------------------------------------------
    PUBLIC :: spk_solve_csr              ! One-shot direct solve
    PUBLIC :: spk_symbolic_csr           ! Symbolic factorization (structure)
    PUBLIC :: spk_numeric_csr            ! Numeric factorization (values)
    PUBLIC :: spk_solve_factored         ! Solve with existing factorization
    PUBLIC :: spk_cleanup                ! Release SparsePak handle
    PUBLIC :: spk_reorder_csr            ! Get reordering permutation
    PUBLIC :: spk_get_reorder_name       ! Get reordering algorithm name
    
    PUBLIC :: UF_SparsePakHandle         ! Opaque handle type
    PUBLIC :: NM_SPK_REORDER_RCM, NM_SPK_REORDER_QMD, NM_SPK_REORDER_ND
    PUBLIC :: NM_SPK_SUCCESS, NM_SPK_ERR_ALLOC, NM_SPK_ERR_SINGULAR, NM_SPK_ERR_NOT_SPD
    
    !---------------------------------------------------------------------------
    ! Constants
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: NM_SPK_SUCCESS = 0
    INTEGER(i4), PARAMETER :: NM_SPK_ERR_ALLOC = -1
    INTEGER(i4), PARAMETER :: NM_SPK_ERR_SINGULAR = -2
    INTEGER(i4), PARAMETER :: NM_SPK_ERR_NOT_SPD = -3
    INTEGER(i4), PARAMETER :: NM_SPK_ERR_SIZE = -4
    INTEGER(i4), PARAMETER :: NM_SPK_ERR_NOT_INIT = -5
    
    ! Reordering algorithms
    INTEGER(i4), PARAMETER :: NM_SPK_REORDER_RCM = 1   ! Reverse Cuthill-McKee
    INTEGER(i4), PARAMETER :: NM_SPK_REORDER_QMD = 2   ! Quotient Minimum Degree
    INTEGER(i4), PARAMETER :: NM_SPK_REORDER_ND  = 3   ! Nested Dissection
    
    ! Internal parameters
    INTEGER(i4), PARAMETER :: NM_MAX_DENSE_SIZE = 2000  ! Dense fallback threshold
    
    !---------------------------------------------------------------------------
    ! SparsePak Handle - Stores factorization state for reuse
    !---------------------------------------------------------------------------
    TYPE :: UF_SparsePakHandle
        LOGICAL :: initialized = .FALSE.
        LOGICAL :: symbolic_done = .FALSE.
        LOGICAL :: numeric_done = .FALSE.
        INTEGER(i4) :: n = 0                        ! Matrix dimension
        INTEGER(i4) :: nnz = 0                      ! Non-zeros
        INTEGER(i4) :: reorder_type = NM_SPK_REORDER_RCM
        
        ! Permutation vectors
        INTEGER(i4), ALLOCATABLE :: perm(:)         ! Forward permutation
        INTEGER(i4), ALLOCATABLE :: perm_inv(:)     ! Inverse permutation
        
        ! CSR structure (reordered)
        INTEGER(i4), ALLOCATABLE :: row_ptr(:)      ! Reordered row pointers
        INTEGER(i4), ALLOCATABLE :: col_ind(:)      ! Reordered column indices
        
        ! Cholesky factor storage (envelope/skyline format)
        REAL(wp), ALLOCATABLE :: diag(:)            ! Diagonal elements
        REAL(wp), ALLOCATABLE :: env(:)             ! Envelope (lower triangle)
        INTEGER(i4), ALLOCATABLE :: xenv(:)         ! Envelope index
        INTEGER(i4) :: env_size = 0                 ! Envelope size
        
        ! General sparse factor (for ND/QMD)
        REAL(wp), ALLOCATABLE :: xlnz(:)            ! Factor values
        INTEGER(i4), ALLOCATABLE :: ixlnz(:)        ! Factor column pointers
        INTEGER(i4), ALLOCATABLE :: nzsub(:)        ! Row subscripts
        INTEGER(i4), ALLOCATABLE :: xnzsub(:)       ! Subscript pointers
        INTEGER(i4) :: nofnz = 0                    ! Number of factor nonzeros
        
        ! Statistics
        INTEGER(i4) :: fill_in = 0                  ! Fill-in count
        REAL(wp) :: factor_time = 0.0_wp
    CONTAINS
        PROCEDURE :: cleanup => handle_cleanup
    END TYPE UF_SparsePakHandle

CONTAINS

    !===========================================================================
    ! ONE-SHOT DIRECT SOLVE
    ! Solves Ax = b directly without factorization reuse
    !===========================================================================
    SUBROUTINE spk_solve_csr(A, b, x, reorder_type, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        INTEGER(i4), INTENT(IN), OPTIONAL :: reorder_type
        INTEGER(i4), INTENT(OUT) :: ierr
        
        TYPE(UF_SparsePakHandle) :: handle
        INTEGER(i4) :: reorder_alg
        
        ierr = NM_SPK_SUCCESS
        
        ! Set reordering algorithm
        IF (PRESENT(reorder_type)) THEN
            reorder_alg = reorder_type
        ELSE
            reorder_alg = NM_SPK_REORDER_RCM  ! Default
        END IF
        
        ! Perform symbolic factorization
        CALL spk_symbolic_csr(A, handle, reorder_alg, ierr)
        IF (ierr /= NM_SPK_SUCCESS) RETURN
        
        ! Perform numeric factorization
        CALL spk_numeric_csr(A, handle, ierr)
        IF (ierr /= NM_SPK_SUCCESS) THEN
            CALL handle%cleanup()
            RETURN
        END IF
        
        ! Solve
        CALL spk_solve_factored(handle, b, x, ierr)
        
        ! Cleanup
        CALL handle%cleanup()
        
    END SUBROUTINE spk_solve_csr
    
    !===========================================================================
    ! SYMBOLIC FACTORIZATION
    ! Analyzes matrix structure and determines fill-in pattern
    !===========================================================================
    SUBROUTINE spk_symbolic_csr(A, handle, reorder_type, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(UF_SparsePakHandle), INTENT(INOUT) :: handle
        INTEGER(i4), INTENT(IN) :: reorder_type
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, nnz, i, j, k, kk, row, col
        INTEGER(i4) :: istat, env_size, iband
        INTEGER(i4), ALLOCATABLE :: adj_row(:), adj(:)
        INTEGER(i4), ALLOCATABLE :: marker(:), deg(:)
        
        ierr = NM_SPK_SUCCESS
        n = A%nrows
        nnz = A%nnz
        
        ! Cleanup previous factorization
        CALL handle%cleanup()
        
        handle%n = n
        handle%nnz = nnz
        handle%reorder_type = reorder_type
        
        ! Allocate permutation vectors
        ALLOCATE(handle%perm(n), handle%perm_inv(n), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_SPK_ERR_ALLOC
            RETURN
        END IF
        
        ! Build symmetric adjacency structure from CSR
        ! For SPD matrix, assume symmetric structure
        CALL build_adjacency(A, adj_row, adj, ierr)
        IF (ierr /= NM_SPK_SUCCESS) RETURN
        
        ! Initialize permutation to identity
        DO i = 1, n
            handle%perm(i) = i
            handle%perm_inv(i) = i
        END DO
        
        ! Apply reordering algorithm
        ALLOCATE(marker(n), deg(n), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_SPK_ERR_ALLOC
            RETURN
        END IF
        marker = 1
        deg = 0
        
        SELECT CASE (reorder_type)
        CASE (NM_SPK_REORDER_RCM)
            CALL apply_rcm(n, adj_row, adj, marker, handle%perm, ierr)
            
        CASE (NM_SPK_REORDER_QMD)
            CALL apply_qmd(n, adj_row, adj, marker, deg, handle%perm, ierr)
            
        CASE (NM_SPK_REORDER_ND)
            CALL apply_nd(n, adj_row, adj, marker, handle%perm, ierr)
            
        CASE DEFAULT
            ! Use RCM by default
            CALL apply_rcm(n, adj_row, adj, marker, handle%perm, ierr)
        END SELECT
        
        IF (ierr /= NM_SPK_SUCCESS) THEN
            DEALLOCATE(marker, deg)
            RETURN
        END IF
        
        ! Compute inverse permutation
        DO i = 1, n
            handle%perm_inv(handle%perm(i)) = i
        END DO
        
        ! Compute envelope structure for Cholesky
        CALL compute_envelope(n, adj_row, adj, handle%perm, handle%perm_inv, &
                             handle%xenv, env_size, iband, ierr)
        IF (ierr /= NM_SPK_SUCCESS) THEN
            DEALLOCATE(marker, deg)
            RETURN
        END IF
        
        handle%env_size = env_size
        
        ! Allocate factor storage
        ALLOCATE(handle%diag(n), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_SPK_ERR_ALLOC
            DEALLOCATE(marker, deg)
            RETURN
        END IF
        
        IF (env_size > 0) THEN
            ALLOCATE(handle%env(env_size), STAT=istat)
            IF (istat /= 0) THEN
                ierr = NM_SPK_ERR_ALLOC
                DEALLOCATE(marker, deg)
                RETURN
            END IF
            handle%env = 0.0_wp
        END IF
        
        handle%diag = 0.0_wp
        handle%symbolic_done = .TRUE.
        handle%initialized = .TRUE.
        
        ! Store fill-in statistics
        handle%fill_in = env_size
        
        DEALLOCATE(adj_row, adj, marker, deg)
        
    END SUBROUTINE spk_symbolic_csr
    
    !===========================================================================
    ! NUMERIC FACTORIZATION
    ! Computes Cholesky factors L such that A = L * L^T
    !===========================================================================
    SUBROUTINE spk_numeric_csr(A, handle, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        TYPE(UF_SparsePakHandle), INTENT(INOUT) :: handle
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, k, kk, row, col
        INTEGER(i4) :: ip, jp, ifirst, ixenv, iband, jstop
        REAL(wp) :: val, temp, aij
        
        ierr = NM_SPK_SUCCESS
        
        IF (.NOT. handle%symbolic_done) THEN
            ierr = NM_SPK_ERR_NOT_INIT
            RETURN
        END IF
        
        n = handle%n
        
        ! Clear factor storage
        handle%diag = 0.0_wp
        IF (ALLOCATED(handle%env)) handle%env = 0.0_wp
        
        ! Load matrix values into envelope storage (with permutation)
        DO i = 1, n
            ip = handle%perm_inv(i)  ! Permuted row
            
            DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                j = A%col_ind(kk)
                jp = handle%perm_inv(j)  ! Permuted column
                val = A%val(kk)
                
                IF (ip == jp) THEN
                    ! Diagonal element
                    handle%diag(ip) = handle%diag(ip) + val
                ELSE IF (ip > jp) THEN
                    ! Lower triangle - store in envelope
                    CALL add_to_envelope(handle, ip, jp, val)
                ELSE
                    ! Upper triangle - for symmetric matrix, add to lower
                    CALL add_to_envelope(handle, jp, ip, val)
                END IF
            END DO
        END DO
        
        ! Perform Cholesky factorization (envelope method)
        CALL envelope_cholesky(n, handle%xenv, handle%diag, handle%env, ierr)
        IF (ierr /= NM_SPK_SUCCESS) RETURN
        
        handle%numeric_done = .TRUE.
        
    END SUBROUTINE spk_numeric_csr
    
    !===========================================================================
    ! SOLVE WITH EXISTING FACTORIZATION
    ! Solves Lx = b, then L^T y = x
    !===========================================================================
    SUBROUTINE spk_solve_factored(handle, b, x, ierr)
        TYPE(UF_SparsePakHandle), INTENT(IN) :: handle
        REAL(wp), INTENT(IN) :: b(:)
        REAL(wp), INTENT(OUT) :: x(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i
        REAL(wp), ALLOCATABLE :: rhs(:)
        
        ierr = NM_SPK_SUCCESS
        
        IF (.NOT. handle%numeric_done) THEN
            ierr = NM_SPK_ERR_NOT_INIT
            RETURN
        END IF
        
        n = handle%n
        
        ! Allocate work array and apply forward permutation
        ALLOCATE(rhs(n))
        DO i = 1, n
            rhs(handle%perm_inv(i)) = b(i)
        END DO
        
        ! Forward substitution: L * y = b (solve for y)
        CALL envelope_forward_solve(n, handle%xenv, handle%diag, handle%env, rhs)
        
        ! Backward substitution: L^T * x = y (solve for x)
        CALL envelope_backward_solve(n, handle%xenv, handle%diag, handle%env, rhs)
        
        ! Apply inverse permutation
        DO i = 1, n
            x(i) = rhs(handle%perm_inv(i))
        END DO
        
        DEALLOCATE(rhs)
        
    END SUBROUTINE spk_solve_factored
    
    !===========================================================================
    ! CLEANUP HANDLE
    !===========================================================================
    SUBROUTINE spk_cleanup(handle)
        TYPE(UF_SparsePakHandle), INTENT(INOUT) :: handle
        CALL handle%cleanup()
    END SUBROUTINE spk_cleanup
    
    SUBROUTINE handle_cleanup(this)
        CLASS(UF_SparsePakHandle), INTENT(INOUT) :: this
        
        IF (ALLOCATED(this%perm)) DEALLOCATE(this%perm)
        IF (ALLOCATED(this%perm_inv)) DEALLOCATE(this%perm_inv)
        IF (ALLOCATED(this%row_ptr)) DEALLOCATE(this%row_ptr)
        IF (ALLOCATED(this%col_ind)) DEALLOCATE(this%col_ind)
        IF (ALLOCATED(this%diag)) DEALLOCATE(this%diag)
        IF (ALLOCATED(this%env)) DEALLOCATE(this%env)
        IF (ALLOCATED(this%xenv)) DEALLOCATE(this%xenv)
        IF (ALLOCATED(this%xlnz)) DEALLOCATE(this%xlnz)
        IF (ALLOCATED(this%ixlnz)) DEALLOCATE(this%ixlnz)
        IF (ALLOCATED(this%nzsub)) DEALLOCATE(this%nzsub)
        IF (ALLOCATED(this%xnzsub)) DEALLOCATE(this%xnzsub)
        
        this%initialized = .FALSE.
        this%symbolic_done = .FALSE.
        this%numeric_done = .FALSE.
        this%n = 0
        this%nnz = 0
        this%env_size = 0
        this%nofnz = 0
        this%fill_in = 0
        this%factor_time = 0.0_wp
        
    END SUBROUTINE handle_cleanup
    
    !===========================================================================
    ! GET REORDERING PERMUTATION
    !===========================================================================
    SUBROUTINE spk_reorder_csr(A, reorder_type, perm, perm_inv, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        INTEGER(i4), INTENT(IN) :: reorder_type
        INTEGER(i4), INTENT(OUT) :: perm(:), perm_inv(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        TYPE(UF_SparsePakHandle) :: handle
        INTEGER(i4) :: i
        
        CALL spk_symbolic_csr(A, handle, reorder_type, ierr)
        IF (ierr /= NM_SPK_SUCCESS) RETURN
        
        DO i = 1, handle%n
            perm(i) = handle%perm(i)
            perm_inv(i) = handle%perm_inv(i)
        END DO
        
        CALL handle%cleanup()
        
    END SUBROUTINE spk_reorder_csr
    
    !===========================================================================
    ! GET REORDERING ALGORITHM NAME
    !===========================================================================
    FUNCTION spk_get_reorder_name(reorder_type) RESULT(name)
        INTEGER(i4), INTENT(IN) :: reorder_type
        CHARACTER(LEN=32) :: name
        
        SELECT CASE (reorder_type)
        CASE (NM_SPK_REORDER_RCM)
            name = 'Reverse Cuthill-McKee'
        CASE (NM_SPK_REORDER_QMD)
            name = 'Quotient Minimum Degree'
        CASE (NM_SPK_REORDER_ND)
            name = 'Nested Dissection'
        CASE DEFAULT
            name = 'Unknown'
        END SELECT
        
    END FUNCTION spk_get_reorder_name

    !===========================================================================
    !                        INTERNAL HELPER ROUTINES
    !===========================================================================
    
    !---------------------------------------------------------------------------
    ! Build symmetric adjacency structure from CSR matrix
    !---------------------------------------------------------------------------
    SUBROUTINE build_adjacency(A, adj_row, adj, ierr)
        TYPE(UF_CSRMatrix), INTENT(IN) :: A
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: adj_row(:), adj(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: n, i, j, k, kk, nnz_sym
        INTEGER(i4), ALLOCATABLE :: count(:)
        INTEGER(i4) :: istat
        
        ierr = NM_SPK_SUCCESS
        n = A%nrows
        
        ! Count symmetric entries per row (excluding diagonal)
        ALLOCATE(count(n), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_SPK_ERR_ALLOC
            RETURN
        END IF
        count = 0
        
        DO i = 1, n
            DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                j = A%col_ind(kk)
                IF (i /= j) THEN
                    count(i) = count(i) + 1
                    count(j) = count(j) + 1  ! Symmetric entry
                END IF
            END DO
        END DO
        
        nnz_sym = SUM(count)
        
        ! Allocate adjacency arrays
        ALLOCATE(adj_row(n+1), adj(nnz_sym), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_SPK_ERR_ALLOC
            DEALLOCATE(count)
            RETURN
        END IF
        
        ! Build row pointers
        adj_row(1) = 1
        DO i = 1, n
            adj_row(i+1) = adj_row(i) + count(i)
        END DO
        
        ! Fill adjacency list
        count = 0
        DO i = 1, n
            DO kk = A%row_ptr(i), A%row_ptr(i+1) - 1
                j = A%col_ind(kk)
                IF (i /= j) THEN
                    ! Add to row i
                    k = adj_row(i) + count(i)
                    adj(k) = j
                    count(i) = count(i) + 1
                    
                    ! Add to row j (symmetric)
                    k = adj_row(j) + count(j)
                    adj(k) = i
                    count(j) = count(j) + 1
                END IF
            END DO
        END DO
        
        DEALLOCATE(count)
        
    END SUBROUTINE build_adjacency
    
    !---------------------------------------------------------------------------
    ! Apply Reverse Cuthill-McKee reordering
    !---------------------------------------------------------------------------
    SUBROUTINE apply_rcm(n, adj_row, adj, mask, perm, ierr)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: adj_row(:), adj(:)
        INTEGER(i4), INTENT(INOUT) :: mask(:)
        INTEGER(i4), INTENT(OUT) :: perm(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, root, nlvl, ccsize
        INTEGER(i4) :: lbegin, lvlend, lvsize, nbr, node
        INTEGER(i4) :: jstrt, jstop, mindeg, ndeg
        INTEGER(i4), ALLOCATABLE :: deg(:), ls(:)
        
        ierr = NM_SPK_SUCCESS
        
        ALLOCATE(deg(n), ls(n))
        
        ! Initialize mask
        mask = 1
        
        ! Find node with minimum degree as starting node
        mindeg = n + 1
        root = 1
        DO i = 1, n
            ndeg = adj_row(i+1) - adj_row(i)
            IF (ndeg < mindeg) THEN
                mindeg = ndeg
                root = i
            END IF
        END DO
        
        ! Generate level structure starting from root
        mask(root) = 0
        ls(1) = root
        lvlend = 0
        ccsize = 1
        
        DO
            lbegin = lvlend + 1
            lvlend = ccsize
            
            ! Process current level
            DO i = lbegin, lvlend
                node = ls(i)
                jstrt = adj_row(node)
                jstop = adj_row(node+1) - 1
                
                DO j = jstrt, jstop
                    nbr = adj(j)
                    IF (mask(nbr) /= 0) THEN
                        ccsize = ccsize + 1
                        ls(ccsize) = nbr
                        mask(nbr) = 0
                    END IF
                END DO
            END DO
            
            lvsize = ccsize - lvlend
            IF (lvsize == 0) EXIT
        END DO
        
        ! Reverse the ordering (RCM)
        DO i = 1, ccsize
            perm(i) = ls(ccsize - i + 1)
        END DO
        
        ! Handle disconnected components
        DO i = 1, n
            IF (mask(i) /= 0) THEN
                ccsize = ccsize + 1
                perm(ccsize) = i
            END IF
        END DO
        
        DEALLOCATE(deg, ls)
        
    END SUBROUTINE apply_rcm
    
    !---------------------------------------------------------------------------
    ! Apply Quotient Minimum Degree reordering (simplified)
    !---------------------------------------------------------------------------
    SUBROUTINE apply_qmd(n, adj_row, adj, mask, deg, perm, ierr)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: adj_row(:), adj(:)
        INTEGER(i4), INTENT(INOUT) :: mask(:)
        INTEGER(i4), INTENT(INOUT) :: deg(:)
        INTEGER(i4), INTENT(OUT) :: perm(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, num, node, mindeg, minnode
        INTEGER(i4) :: jstrt, jstop, nbr
        
        ierr = NM_SPK_SUCCESS
        
        ! Initialize degree
        DO i = 1, n
            deg(i) = adj_row(i+1) - adj_row(i)
            mask(i) = 1
        END DO
        
        ! Simple minimum degree ordering
        num = 0
        DO WHILE (num < n)
            ! Find node with minimum degree
            mindeg = n + 1
            minnode = 0
            DO i = 1, n
                IF (mask(i) /= 0 .AND. deg(i) < mindeg) THEN
                    mindeg = deg(i)
                    minnode = i
                END IF
            END DO
            
            IF (minnode == 0) EXIT
            
            ! Add to permutation
            num = num + 1
            perm(num) = minnode
            mask(minnode) = 0
            
            ! Update degrees of neighbors
            jstrt = adj_row(minnode)
            jstop = adj_row(minnode+1) - 1
            DO j = jstrt, jstop
                nbr = adj(j)
                IF (mask(nbr) /= 0) THEN
                    deg(nbr) = deg(nbr) - 1
                    IF (deg(nbr) < 0) deg(nbr) = 0
                END IF
            END DO
        END DO
        
    END SUBROUTINE apply_qmd
    
    !---------------------------------------------------------------------------
    ! Apply Nested Dissection reordering (simplified)
    !---------------------------------------------------------------------------
    SUBROUTINE apply_nd(n, adj_row, adj, mask, perm, ierr)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: adj_row(:), adj(:)
        INTEGER(i4), INTENT(INOUT) :: mask(:)
        INTEGER(i4), INTENT(OUT) :: perm(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        ! For simplicity, use RCM as fallback
        ! Full ND implementation would recursively partition the graph
        CALL apply_rcm(n, adj_row, adj, mask, perm, ierr)
        
    END SUBROUTINE apply_nd
    
    !---------------------------------------------------------------------------
    ! Compute envelope structure
    !---------------------------------------------------------------------------
    SUBROUTINE compute_envelope(n, adj_row, adj, perm, perm_inv, xenv, &
                                env_size, iband, ierr)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: adj_row(:), adj(:)
        INTEGER(i4), INTENT(IN) :: perm(:), perm_inv(:)
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: xenv(:)
        INTEGER(i4), INTENT(OUT) :: env_size, iband
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, j, k, iperm, nabor, ifirst, jband
        INTEGER(i4) :: jstrt, jstop, istat
        
        ierr = NM_SPK_SUCCESS
        
        ALLOCATE(xenv(n+1), STAT=istat)
        IF (istat /= 0) THEN
            ierr = NM_SPK_ERR_ALLOC
            RETURN
        END IF
        
        iband = 0
        env_size = 1
        
        DO i = 1, n
            xenv(i) = env_size
            iperm = perm(i)  ! Original node
            
            jstrt = adj_row(iperm)
            jstop = adj_row(iperm+1) - 1
            
            IF (jstrt > jstop) CYCLE
            
            ifirst = i
            DO j = jstrt, jstop
                nabor = adj(j)
                nabor = perm_inv(nabor)  ! Permuted neighbor
                ifirst = MIN(ifirst, nabor)
            END DO
            
            jband = i - ifirst
            env_size = env_size + jband
            iband = MAX(iband, jband)
        END DO
        
        xenv(n+1) = env_size
        env_size = env_size - 1
        
    END SUBROUTINE compute_envelope
    
    !---------------------------------------------------------------------------
    ! Add value to envelope storage
    !---------------------------------------------------------------------------
    SUBROUTINE add_to_envelope(handle, i, j, val)
        TYPE(UF_SparsePakHandle), INTENT(INOUT) :: handle
        INTEGER(i4), INTENT(IN) :: i, j
        REAL(wp), INTENT(IN) :: val
        
        INTEGER(i4) :: k
        
        ! Compute envelope position
        k = handle%xenv(i+1) - i + j
        
        IF (k >= handle%xenv(i) .AND. k < handle%xenv(i+1)) THEN
            handle%env(k) = handle%env(k) + val
        END IF
        
    END SUBROUTINE add_to_envelope
    
    !---------------------------------------------------------------------------
    ! Envelope Cholesky factorization (A = L * L^T)
    !---------------------------------------------------------------------------
    SUBROUTINE envelope_cholesky(n, xenv, diag, env, ierr)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: xenv(:)
        REAL(wp), INTENT(INOUT) :: diag(:)
        REAL(wp), INTENT(INOUT) :: env(:)
        INTEGER(i4), INTENT(OUT) :: ierr
        
        INTEGER(i4) :: i, iband, ifirst, ixenv, j, jstop
        REAL(wp) :: temp
        REAL(wp), PARAMETER :: TOL = 1.0E-15_wp
        
        ierr = NM_SPK_SUCCESS
        
        ! Check first diagonal
        IF (diag(1) <= TOL) THEN
            ierr = NM_SPK_ERR_NOT_SPD
            RETURN
        END IF
        diag(1) = SQRT(diag(1))
        
        ! Factorize row by row
        DO i = 2, n
            ixenv = xenv(i)
            iband = xenv(i+1) - ixenv
            temp = diag(i)
            
            IF (iband /= 0) THEN
                ifirst = i - iband
                
                ! Solve for L(i, ifirst:i-1)
                CALL envelope_forward_solve_partial(iband, xenv(ifirst:), &
                    diag(ifirst:), env(ixenv:))
                
                ! Update diagonal: diag(i) -= sum(L(i,j)^2)
                jstop = xenv(i+1) - 1
                DO j = ixenv, jstop
                    temp = temp - env(j)**2
                END DO
            END IF
            
            ! Check positive definiteness
            IF (temp <= TOL) THEN
                ierr = NM_SPK_ERR_NOT_SPD
                RETURN
            END IF
            diag(i) = SQRT(temp)
        END DO
        
    END SUBROUTINE envelope_cholesky
    
    !---------------------------------------------------------------------------
    ! Partial forward solve for Cholesky factorization
    !---------------------------------------------------------------------------
    SUBROUTINE envelope_forward_solve_partial(iband, xenv, diag, env)
        INTEGER(i4), INTENT(IN) :: iband
        INTEGER(i4), INTENT(IN) :: xenv(:)
        REAL(wp), INTENT(IN) :: diag(:)
        REAL(wp), INTENT(INOUT) :: env(:)
        
        INTEGER(i4) :: i, j, jband, jfirst, k, kk
        REAL(wp) :: temp
        
        DO j = 1, iband
            jband = xenv(j+1) - xenv(j)
            IF (jband == 0) CYCLE
            
            jfirst = j - jband
            temp = 0.0_wp
            
            ! Accumulate inner product
            DO k = MAX(1, jfirst), j-1
                kk = xenv(j+1) - j + k
                IF (kk >= xenv(j) .AND. k <= iband) THEN
                    temp = temp + env(kk) * env(k)
                END IF
            END DO
            
            env(j) = (env(j) - temp) / diag(j)
        END DO
        
    END SUBROUTINE envelope_forward_solve_partial
    
    !---------------------------------------------------------------------------
    ! Forward substitution: Solve L*x = b
    !---------------------------------------------------------------------------
    SUBROUTINE envelope_forward_solve(n, xenv, diag, env, rhs)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: xenv(:)
        REAL(wp), INTENT(IN) :: diag(:), env(:)
        REAL(wp), INTENT(INOUT) :: rhs(:)
        
        INTEGER(i4) :: i, j, iband, ifirst, k
        REAL(wp) :: temp
        
        rhs(1) = rhs(1) / diag(1)
        
        DO i = 2, n
            iband = xenv(i+1) - xenv(i)
            IF (iband /= 0) THEN
                ifirst = i - iband
                temp = 0.0_wp
                k = xenv(i)
                DO j = ifirst, i-1
                    temp = temp + env(k) * rhs(j)
                    k = k + 1
                END DO
                rhs(i) = rhs(i) - temp
            END IF
            rhs(i) = rhs(i) / diag(i)
        END DO
        
    END SUBROUTINE envelope_forward_solve
    
    !---------------------------------------------------------------------------
    ! Backward substitution: Solve L^T*x = b
    !---------------------------------------------------------------------------
    SUBROUTINE envelope_backward_solve(n, xenv, diag, env, rhs)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: xenv(:)
        REAL(wp), INTENT(IN) :: diag(:), env(:)
        REAL(wp), INTENT(INOUT) :: rhs(:)
        
        INTEGER(i4) :: i, j, iband, ifirst, k
        REAL(wp) :: temp
        
        rhs(n) = rhs(n) / diag(n)
        
        DO i = n-1, 1, -1
            rhs(i) = rhs(i) / diag(i)
            
            ! Scatter to previous rows
            iband = xenv(i+1+1) - xenv(i+1)
            IF (iband /= 0) THEN
                ifirst = (i+1) - iband
                k = xenv(i+1)
                DO j = ifirst, i
                    rhs(j) = rhs(j) - env(k) * rhs(i+1)
                    k = k + 1
                END DO
            END IF
        END DO
        
    END SUBROUTINE envelope_backward_solve

END MODULE NM_Solv_SparsePakWrap