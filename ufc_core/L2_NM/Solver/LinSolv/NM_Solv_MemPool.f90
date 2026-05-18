!===============================================================================
! MODULE: NM_Solv_MemPool
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Core (memory pool for Krylov/nonlinear solver scratch buffers)
! BRIEF:  Typed scratch-memory pools (UF_MemoryPool_t, UF_MatrixPool_t)
!
! Status: STUB | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_MemPool
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_MEM_ERROR, IF_STATUS_INVALID
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! Public types
    !---------------------------------------------------------------------------
    PUBLIC :: UF_MemoryPool_t
    PUBLIC :: UF_MatrixPool_t

    !---------------------------------------------------------------------------
    ! Public procedures
    !---------------------------------------------------------------------------
    PUBLIC :: MemPool_Init
    PUBLIC :: MemPool_Alloc
    PUBLIC :: MemPool_Free
    PUBLIC :: MemPool_Reset
    PUBLIC :: MemPool_Finalize

    !===========================================================================
    ! TYPE UF_MemoryPool_t
    ! Arena-based real vector pool for solver scratch vectors.
    !===========================================================================
    TYPE :: UF_MemoryPool_t
        LOGICAL                           :: initialized  = .FALSE.
        INTEGER(i4)                       :: capacity     = 0_i4    ! elements in buf
        INTEGER(i4)                       :: used         = 0_i4    ! HWM cursor
        REAL(wp), POINTER                 :: buf(:) => NULL()        ! backing buffer (POINTER for ptr=>buf(s:e))
    CONTAINS
        PROCEDURE :: Init     => MemPool_t_Init
        PROCEDURE :: Alloc    => MemPool_t_Alloc
        PROCEDURE :: AllocDP1D=> MemPool_t_AllocDP1D    ! alias for CoreMemPool compat
        PROCEDURE :: Free     => MemPool_t_Free
        PROCEDURE :: Reset    => MemPool_t_Reset
        PROCEDURE :: Finalize => MemPool_t_Finalize
    END TYPE UF_MemoryPool_t

    !===========================================================================
    ! TYPE UF_MatrixPool_t
    ! Arena-based real pool for dense matrix work space.
    ! Identical layout; kept separate for type-safety.
    !===========================================================================
    TYPE :: UF_MatrixPool_t
        LOGICAL                           :: initialized  = .FALSE.
        INTEGER(i4)                       :: capacity     = 0_i4
        INTEGER(i4)                       :: used         = 0_i4
        REAL(wp), POINTER                 :: buf(:) => NULL()        ! POINTER for ptr=>buf(s:e)
    CONTAINS
        PROCEDURE :: Init     => MatPool_t_Init
        PROCEDURE :: Alloc    => MatPool_t_Alloc
        PROCEDURE :: Free     => MatPool_t_Free
        PROCEDURE :: Reset    => MatPool_t_Reset
        PROCEDURE :: Finalize => MatPool_t_Finalize
    END TYPE UF_MatrixPool_t

CONTAINS

    !==========================================================================
    ! Standalone convenience wrappers (non-OOP call style)
    !==========================================================================

    SUBROUTINE MemPool_Init(pool, capacity, status)
        TYPE(UF_MemoryPool_t), INTENT(INOUT)  :: pool
        INTEGER(i4),           INTENT(IN)     :: capacity
        TYPE(ErrorStatusType), INTENT(OUT)    :: status
        CALL pool%Init(capacity, status)
    END SUBROUTINE MemPool_Init

    SUBROUTINE MemPool_Alloc(pool, n, ptr, status)
        TYPE(UF_MemoryPool_t), INTENT(INOUT)         :: pool
        INTEGER(i4),           INTENT(IN)            :: n
        REAL(wp),              POINTER, INTENT(OUT)  :: ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT)           :: status
        CALL pool%Alloc(n, ptr, status)
    END SUBROUTINE MemPool_Alloc

    SUBROUTINE MemPool_Free(pool, ptr)
        TYPE(UF_MemoryPool_t), INTENT(INOUT)       :: pool
        REAL(wp),              POINTER, INTENT(INOUT) :: ptr(:)
        CALL pool%Free(ptr)
    END SUBROUTINE MemPool_Free

    SUBROUTINE MemPool_Reset(pool)
        TYPE(UF_MemoryPool_t), INTENT(INOUT) :: pool
        CALL pool%Reset()
    END SUBROUTINE MemPool_Reset

    SUBROUTINE MemPool_Finalize(pool)
        TYPE(UF_MemoryPool_t), INTENT(INOUT) :: pool
        CALL pool%Finalize()
    END SUBROUTINE MemPool_Finalize

    !==========================================================================
    ! UF_MemoryPool_t bound procedures
    !==========================================================================

    SUBROUTINE MemPool_t_Init(this, capacity, status)
        CLASS(UF_MemoryPool_t), INTENT(INOUT) :: this
        INTEGER(i4),            INTENT(IN)    :: capacity
        TYPE(ErrorStatusType),  INTENT(OUT)   :: status
        INTEGER(i4) :: ierr
        CALL init_error_status(status)
        IF (this%initialized) CALL this%Finalize()
        ALLOCATE(this%buf(capacity), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'UF_MemoryPool_t%Init: ALLOCATE failed'
            RETURN
        END IF
        this%buf         = 0.0_wp
        this%capacity    = capacity
        this%used        = 0_i4
        this%initialized = .TRUE.
    END SUBROUTINE MemPool_t_Init

    SUBROUTINE MemPool_t_Alloc(this, n, ptr, status)
        CLASS(UF_MemoryPool_t), INTENT(INOUT)       :: this
        INTEGER(i4),            INTENT(IN)          :: n
        REAL(wp),               POINTER, INTENT(OUT):: ptr(:)
        TYPE(ErrorStatusType),  INTENT(OUT)         :: status
        INTEGER(i4) :: s, e
        CALL init_error_status(status)
        NULLIFY(ptr)
        IF (.NOT. this%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'UF_MemoryPool_t%Alloc: pool not initialised'
            RETURN
        END IF
        s = this%used + 1_i4
        e = this%used + n
        IF (e > this%capacity) THEN
            ! Fall back: let caller use ALLOCATE directly
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'UF_MemoryPool_t%Alloc: pool capacity exceeded'
            RETURN
        END IF
        ptr => this%buf(s:e)
        this%used = e
    END SUBROUTINE MemPool_t_Alloc

    ! AllocDP1D: named-key variant compatible with g_core_mem_pool interface
    SUBROUTINE MemPool_t_AllocDP1D(this, key, n, ptr, status)
        CLASS(UF_MemoryPool_t), INTENT(INOUT)        :: this
        CHARACTER(LEN=*),       INTENT(IN)           :: key
        INTEGER(i4),            INTENT(IN)           :: n
        REAL(wp),               POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType),  INTENT(OUT)          :: status
        ! key is ignored in arena pool �?just forward to Alloc
        CALL this%Alloc(n, ptr, status)
    END SUBROUTINE MemPool_t_AllocDP1D

    SUBROUTINE MemPool_t_Free(this, ptr)
        CLASS(UF_MemoryPool_t), INTENT(INOUT)      :: this
        REAL(wp),               POINTER, INTENT(INOUT) :: ptr(:)
        ! Arena pool: free is a no-op; Reset() wipes all
        NULLIFY(ptr)
    END SUBROUTINE MemPool_t_Free

    SUBROUTINE MemPool_t_Reset(this)
        CLASS(UF_MemoryPool_t), INTENT(INOUT) :: this
        this%used = 0_i4
    END SUBROUTINE MemPool_t_Reset

    SUBROUTINE MemPool_t_Finalize(this)
        CLASS(UF_MemoryPool_t), INTENT(INOUT) :: this
        IF (ASSOCIATED(this%buf)) DEALLOCATE(this%buf)
        this%capacity    = 0_i4
        this%used        = 0_i4
        this%initialized = .FALSE.
    END SUBROUTINE MemPool_t_Finalize

    !==========================================================================
    ! UF_MatrixPool_t bound procedures  (mirror of UF_MemoryPool_t)
    !==========================================================================

    SUBROUTINE MatPool_t_Init(this, capacity, status)
        CLASS(UF_MatrixPool_t), INTENT(INOUT) :: this
        INTEGER(i4),            INTENT(IN)    :: capacity
        TYPE(ErrorStatusType),  INTENT(OUT)   :: status
        INTEGER(i4) :: ierr
        CALL init_error_status(status)
        IF (this%initialized) CALL this%Finalize()
        ALLOCATE(this%buf(capacity), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'UF_MatrixPool_t%Init: ALLOCATE failed'
            RETURN
        END IF
        this%buf         = 0.0_wp
        this%capacity    = capacity
        this%used        = 0_i4
        this%initialized = .TRUE.
    END SUBROUTINE MatPool_t_Init

    SUBROUTINE MatPool_t_Alloc(this, n, ptr, status)
        CLASS(UF_MatrixPool_t), INTENT(INOUT)        :: this
        INTEGER(i4),            INTENT(IN)           :: n
        REAL(wp),               POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType),  INTENT(OUT)          :: status
        INTEGER(i4) :: s, e
        CALL init_error_status(status)
        NULLIFY(ptr)
        IF (.NOT. this%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'UF_MatrixPool_t%Alloc: pool not initialised'
            RETURN
        END IF
        s = this%used + 1_i4
        e = this%used + n
        IF (e > this%capacity) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'UF_MatrixPool_t%Alloc: pool capacity exceeded'
            RETURN
        END IF
        ptr => this%buf(s:e)
        this%used = e
    END SUBROUTINE MatPool_t_Alloc

    SUBROUTINE MatPool_t_Free(this, ptr)
        CLASS(UF_MatrixPool_t), INTENT(INOUT)      :: this
        REAL(wp),               POINTER, INTENT(INOUT) :: ptr(:)
        NULLIFY(ptr)
    END SUBROUTINE MatPool_t_Free

    SUBROUTINE MatPool_t_Reset(this)
        CLASS(UF_MatrixPool_t), INTENT(INOUT) :: this
        this%used = 0_i4
    END SUBROUTINE MatPool_t_Reset

    SUBROUTINE MatPool_t_Finalize(this)
        CLASS(UF_MatrixPool_t), INTENT(INOUT) :: this
        IF (ASSOCIATED(this%buf)) DEALLOCATE(this%buf)
        this%capacity    = 0_i4
        this%used        = 0_i4
        this%initialized = .FALSE.
    END SUBROUTINE MatPool_t_Finalize

END MODULE NM_Solv_MemPool