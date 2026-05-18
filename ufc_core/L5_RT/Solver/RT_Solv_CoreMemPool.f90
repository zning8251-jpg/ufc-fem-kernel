!===============================================================================
! MODULE: RT_Solv_CoreMemPool
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Util (Memory)
! BRIEF:  Core memory pool for runtime solver scratch arrays
!===============================================================================
!
! Process�?
!   P0: Init / Finalize / Reset   [COLD_PATH]
!   P1: AllocDP1D / AllocInt1D    [HOT_PATH]
!   P0: Dealloc                   [COLD_PATH]
!
! Public API:
!   g_core_mem_pool              - MODULE-level singleton instance
!   CoreMemPool_AllocDP1D        - alloc REAL(wp) slice
!   CoreMemPool_AllocInt1D       - alloc INTEGER(i4) slice
!   CoreMemPool_Dealloc          - release named slot
!
! Status: STUB | Last verified: 2026-04-28
!===============================================================================

MODULE RT_Solv_CoreMemPool
    USE IF_Prec_Core,    ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_MEM_ERROR, IF_STATUS_INVALID, &
                          IF_STATUS_NOT_FOUND
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! Public: global singleton + standalone procedures
    !---------------------------------------------------------------------------
    PUBLIC :: g_core_mem_pool
    PUBLIC :: CoreMemPool_AllocDP1D
    PUBLIC :: CoreMemPool_AllocInt1D
    PUBLIC :: CoreMemPool_Dealloc

    !---------------------------------------------------------------------------
    ! Internal constants
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: CMP_MAX_SLOTS   = 512_i4    ! max named allocations
    INTEGER(i4), PARAMETER :: CMP_KEY_LEN     = 64_i4     ! max key length
    INTEGER(i4), PARAMETER :: CMP_KIND_REAL   = 1_i4
    INTEGER(i4), PARAMETER :: CMP_KIND_INT    = 2_i4

    !===========================================================================
    ! TYPE: CMP_Slot_t �?one named allocation entry
    !===========================================================================
    TYPE :: CMP_Slot_t
        LOGICAL                              :: active   = .FALSE.
        INTEGER(i4)                          :: kind     = 0_i4     ! REAL or INT
        CHARACTER(LEN=CMP_KEY_LEN)           :: key      = ''
        REAL(wp),    POINTER                 :: rptr(:)  => NULL()
        INTEGER(i4), POINTER                 :: iptr(:)  => NULL()
    END TYPE CMP_Slot_t

    !===========================================================================
    ! TYPE: UF_CoreMemPool_t �?the pool container (singleton)
    !===========================================================================
    TYPE :: UF_CoreMemPool_t
        LOGICAL                              :: initialized = .FALSE.
        INTEGER(i4)                          :: capacity    = 0_i4   ! max slots
        INTEGER(i4)                          :: used        = 0_i4   ! active slots
        TYPE(CMP_Slot_t), ALLOCATABLE        :: slots(:)
    CONTAINS
        PROCEDURE :: Init
        PROCEDURE :: AllocDP1D
        PROCEDURE :: AllocInt1D
        PROCEDURE :: Dealloc
        PROCEDURE :: Reset
        PROCEDURE :: Finalize
    END TYPE UF_CoreMemPool_t

    !---------------------------------------------------------------------------
    ! Module-level singleton
    !---------------------------------------------------------------------------
    TYPE(UF_CoreMemPool_t), SAVE :: g_core_mem_pool

CONTAINS

    !==========================================================================
    ! UF_CoreMemPool_t bound procedures
    !==========================================================================

    SUBROUTINE CMP_Init(this, capacity)
        CLASS(UF_CoreMemPool_t), INTENT(INOUT) :: this
        INTEGER(i4), OPTIONAL,   INTENT(IN)    :: capacity
        INTEGER(i4) :: ierr, cap
        cap = CMP_MAX_SLOTS
        IF (PRESENT(capacity)) cap = INT(capacity)
        IF (this%initialized) CALL this%Finalize()
        ALLOCATE(this%slots(cap), STAT=ierr)
        IF (ierr /= 0) RETURN
        this%capacity    = INT(cap, i4)
        this%used        = 0_i4
        this%initialized = .TRUE.
    END SUBROUTINE CMP_Init

    !--------------------------------------------------------------------------
    SUBROUTINE CMP_AllocDP1D(this, key, n, ptr, status)
        CLASS(UF_CoreMemPool_t), INTENT(INOUT)        :: this
        CHARACTER(LEN=*),        INTENT(IN)           :: key
        INTEGER(i4),             INTENT(IN)           :: n
        REAL(wp),                POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType),   INTENT(OUT)          :: status
        INTEGER(i4) :: slot
        INTEGER(i4)     :: ierr
        CALL init_error_status(status)
        NULLIFY(ptr)
        IF (.NOT. this%initialized) THEN
            ! Auto-init on first use with default capacity
            CALL this%Init()
            IF (.NOT. this%initialized) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = 'RT_CoreMemPool: auto-init failed'
                RETURN
            END IF
        END IF
        slot = cmp_find_or_new_slot(this, key, CMP_KIND_REAL)
        IF (slot <= 0_i4) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'RT_CoreMemPool: slot table full'
            RETURN
        END IF
        ! Release old allocation if slot was reused
        IF (ASSOCIATED(this%slots(slot)%rptr)) DEALLOCATE(this%slots(slot)%rptr)
        ALLOCATE(this%slots(slot)%rptr(n), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'RT_CoreMemPool: ALLOCATE failed for key='//TRIM(key)
            RETURN
        END IF
        this%slots(slot)%rptr = 0.0_wp
        ptr => this%slots(slot)%rptr
    END SUBROUTINE CMP_AllocDP1D

    !--------------------------------------------------------------------------
    SUBROUTINE CMP_AllocInt1D(this, key, n, ptr, status)
        CLASS(UF_CoreMemPool_t), INTENT(INOUT)           :: this
        CHARACTER(LEN=*),        INTENT(IN)              :: key
        INTEGER(i4),             INTENT(IN)              :: n
        INTEGER(i4),             POINTER, INTENT(OUT)    :: ptr(:)
        TYPE(ErrorStatusType),   INTENT(OUT)             :: status
        INTEGER(i4) :: slot
        INTEGER(i4)     :: ierr
        CALL init_error_status(status)
        NULLIFY(ptr)
        IF (.NOT. this%initialized) THEN
            CALL this%Init()
            IF (.NOT. this%initialized) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = 'RT_CoreMemPool: auto-init failed'
                RETURN
            END IF
        END IF
        slot = cmp_find_or_new_slot(this, key, CMP_KIND_INT)
        IF (slot <= 0_i4) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'RT_CoreMemPool: slot table full'
            RETURN
        END IF
        IF (ASSOCIATED(this%slots(slot)%iptr)) DEALLOCATE(this%slots(slot)%iptr)
        ALLOCATE(this%slots(slot)%iptr(n), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = 'RT_CoreMemPool: ALLOCATE failed for key='//TRIM(key)
            RETURN
        END IF
        this%slots(slot)%iptr = 0_i4
        ptr => this%slots(slot)%iptr
    END SUBROUTINE CMP_AllocInt1D

    !--------------------------------------------------------------------------
    SUBROUTINE CMP_Dealloc(this, key)
        CLASS(UF_CoreMemPool_t), INTENT(INOUT) :: this
        CHARACTER(LEN=*),        INTENT(IN)    :: key
        INTEGER(i4) :: i
        IF (.NOT. this%initialized) RETURN
        DO i = 1_i4, this%capacity
            IF (.NOT. this%slots(i)%active) CYCLE
            IF (TRIM(this%slots(i)%key) == TRIM(key)) THEN
                IF (ASSOCIATED(this%slots(i)%rptr)) DEALLOCATE(this%slots(i)%rptr)
                IF (ASSOCIATED(this%slots(i)%iptr)) DEALLOCATE(this%slots(i)%iptr)
                this%slots(i)%active = .FALSE.
                this%slots(i)%key    = ''
                this%used = MAX(0_i4, this%used - 1_i4)
                RETURN
            END IF
        END DO
        ! key not found: silently ignore (caller may call unconditionally)
    END SUBROUTINE CMP_Dealloc

    !--------------------------------------------------------------------------
    SUBROUTINE CMP_Reset(this)
        CLASS(UF_CoreMemPool_t), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        IF (.NOT. this%initialized) RETURN
        DO i = 1_i4, this%capacity
            IF (.NOT. this%slots(i)%active) CYCLE
            IF (ASSOCIATED(this%slots(i)%rptr)) DEALLOCATE(this%slots(i)%rptr)
            IF (ASSOCIATED(this%slots(i)%iptr)) DEALLOCATE(this%slots(i)%iptr)
            this%slots(i)%active = .FALSE.
            this%slots(i)%key    = ''
        END DO
        this%used = 0_i4
    END SUBROUTINE CMP_Reset

    !--------------------------------------------------------------------------
    SUBROUTINE CMP_Finalize(this)
        CLASS(UF_CoreMemPool_t), INTENT(INOUT) :: this
        CALL this%Reset()
        IF (ALLOCATED(this%slots)) DEALLOCATE(this%slots)
        this%capacity    = 0_i4
        this%initialized = .FALSE.
    END SUBROUTINE CMP_Finalize

    !==========================================================================
    ! Private helper: find existing slot by key, or allocate a new slot
    ! Returns slot index (1-based), or 0 on failure.
    !==========================================================================
    FUNCTION cmp_find_or_new_slot(pool, key, kind_flag) RESULT(idx)
        TYPE(UF_CoreMemPool_t), INTENT(INOUT) :: pool
        CHARACTER(LEN=*),       INTENT(IN)    :: key
        INTEGER(i4),            INTENT(IN)    :: kind_flag
        INTEGER(i4)                           :: idx, i, first_free
        idx        = 0_i4
        first_free = 0_i4
        DO i = 1_i4, pool%capacity
            IF (pool%slots(i)%active) THEN
                IF (TRIM(pool%slots(i)%key) == TRIM(key)) THEN
                    idx = i
                    RETURN
                END IF
            ELSE
                IF (first_free == 0_i4) first_free = i
            END IF
        END DO
        ! Not found: use first free slot
        IF (first_free > 0_i4) THEN
            idx = first_free
            pool%slots(idx)%active = .TRUE.
            pool%slots(idx)%key    = TRIM(key)
            pool%slots(idx)%kind   = kind_flag
            pool%used = pool%used + 1_i4
        END IF
    END FUNCTION cmp_find_or_new_slot

    !==========================================================================
    ! Standalone procedure aliases (modules that import by name, not via %)
    !==========================================================================

    SUBROUTINE CoreMemPool_AllocDP1D(key, n, ptr, status)
        CHARACTER(LEN=*),      INTENT(IN)           :: key
        INTEGER(i4),           INTENT(IN)           :: n
        REAL(wp),              POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT)          :: status
        CALL g_core_mem_pool%AllocDP1D(key, n, ptr, status)
    END SUBROUTINE CoreMemPool_AllocDP1D

    SUBROUTINE CoreMemPool_AllocInt1D(key, n, ptr, status)
        CHARACTER(LEN=*),      INTENT(IN)              :: key
        INTEGER(i4),           INTENT(IN)              :: n
        INTEGER(i4),           POINTER, INTENT(OUT)    :: ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT)             :: status
        CALL g_core_mem_pool%AllocInt1D(key, n, ptr, status)
    END SUBROUTINE CoreMemPool_AllocInt1D

    SUBROUTINE CoreMemPool_Dealloc(key)
        CHARACTER(LEN=*), INTENT(IN) :: key
        CALL g_core_mem_pool%Dealloc(key)
    END SUBROUTINE CoreMemPool_Dealloc

END MODULE RT_Solv_CoreMemPool