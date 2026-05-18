!===================================================================
! MODULE:  MD_KW_MemPool
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Impl
! BRIEF:   Memory pool management for keyword parsing.
!          Provides efficient alloc/free for real and integer arrays.
!===================================================================
MODULE MD_KW_MemPool
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    INTEGER(i4), PARAMETER, PUBLIC :: DEFAULT_POOL_SIZE = 100000
    INTEGER(i4), PARAMETER, PUBLIC :: DEFAULT_CHUNK_SIZE = 1000

    ! Memory pool for real values
    TYPE, PUBLIC :: RealMemoryPool
        REAL(wp), ALLOCATABLE :: pool(:)
        INTEGER(i4) :: poolSize = DEFAULT_POOL_SIZE
        INTEGER(i4) :: currentIndex = 0
        INTEGER(i4) :: allocatedCount = 0
        LOGICAL :: initialized = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => RealMemoryPool_Init
        PROCEDURE, PUBLIC :: Allocate => RealMemoryPool_Allocate
        PROCEDURE, PUBLIC :: Reset => RealMemoryPool_Reset
        PROCEDURE, PUBLIC :: GetStats => RealMemoryPool_GetStats
    END TYPE RealMemoryPool

    ! Memory pool for integer values
    TYPE, PUBLIC :: IntMemoryPool
        INTEGER(i4), ALLOCATABLE :: pool(:)
        INTEGER(i4) :: poolSize = DEFAULT_POOL_SIZE
        INTEGER(i4) :: currentIndex = 0
        INTEGER(i4) :: allocatedCount = 0
        LOGICAL :: initialized = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => IntMemoryPool_Init
        PROCEDURE, PUBLIC :: Allocate => IntMemoryPool_Allocate
        PROCEDURE, PUBLIC :: Reset => IntMemoryPool_Reset
        PROCEDURE, PUBLIC :: GetStats => IntMemoryPool_GetStats
    END TYPE IntMemoryPool

    ! Combined memory pool manager
    TYPE, PUBLIC :: MemPoolManager
        TYPE(RealMemoryPool) :: realPool
        TYPE(IntMemoryPool) :: intPool
        LOGICAL :: enabled = .TRUE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => MemPoolManager_Init
        PROCEDURE, PUBLIC :: Reset => MemPoolManager_Reset
        PROCEDURE, PUBLIC :: GetStats => MemPoolManager_GetStats
    END TYPE MemPoolManager

    PUBLIC :: RealMemoryPool, IntMemoryPool, MemPoolManager

CONTAINS

    SUBROUTINE RealMemoryPool_Init(this, poolSize, status)
        CLASS(RealMemoryPool), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: poolSize
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        IF (PRESENT(poolSize)) THEN
            this%poolSize = poolSize
        END IF
        
        IF (.NOT. ALLOCATED(this%pool)) THEN
            ALLOCATE(this%pool(this%poolSize))
        END IF
        
        this%currentIndex = 0
        this%allocatedCount = 0
        this%initialized = .TRUE.
    END SUBROUTINE RealMemoryPool_Init

    ! ==========================================================================
    ! Allocate memory from pool (with automatic expansion)
    ! Algorithm: If pool exhausted, expand by doubling size
    ! ==========================================================================
    FUNCTION RealMemoryPool_Allocate(this, size, status) RESULT(ptr)
        CLASS(RealMemoryPool), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        REAL(wp), POINTER :: ptr(:)
        
        INTEGER(i4) :: start_idx, new_size, old_size, ios
        REAL(wp), ALLOCATABLE :: temp_pool(:)
        
        CALL init_error_status(status)
        NULLIFY(ptr)
        
        IF (.NOT. this%initialized) THEN
            CALL this%Init(status=status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
        
        IF (this%currentIndex + size > this%poolSize) THEN
            ! Pool exhausted: try to expand pool
            ! Expansion strategy: double the pool size
            new_size = MAX(this%poolSize * 2, this%currentIndex + size)
            old_size = this%poolSize
            
            ! Allocate temporary pool
            ALLOCATE(temp_pool(new_size), stat=ios)
            IF (ios == 0) THEN
                ! Copy existing data
                temp_pool(1:old_size) = this%pool(1:old_size)
                ! Move allocation
                CALL MOVE_ALLOC(temp_pool, this%pool)
                this%poolSize = new_size
            ELSE
                ! Expansion failed, allocate separately
                ALLOCATE(ptr(size), stat=ios)
                IF (ios == 0) THEN
                    this%allocatedCount = this%allocatedCount + 1
                ELSE
                    status%status_code = IF_STATUS_INVALID
                    status%message = "RealMemoryPool: Failed to allocate memory"
                END IF
                RETURN
            END IF
        END IF
        
        ! Allocate from pool
        start_idx = this%currentIndex + 1
        this%currentIndex = this%currentIndex + size
        ptr => this%pool(start_idx:this%currentIndex)
        status%status_code = IF_STATUS_OK
    END FUNCTION RealMemoryPool_Allocate

    SUBROUTINE RealMemoryPool_Reset(this)
        CLASS(RealMemoryPool), INTENT(INOUT) :: this
        
        this%currentIndex = 0
        this%allocatedCount = 0
    END SUBROUTINE RealMemoryPool_Reset

    SUBROUTINE RealMemoryPool_GetStats(this, used, total, allocated)
        CLASS(RealMemoryPool), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: used, total, allocated
        
        used = this%currentIndex
        total = this%poolSize
        allocated = this%allocatedCount
    END SUBROUTINE RealMemoryPool_GetStats

    SUBROUTINE IntMemoryPool_Init(this, poolSize, status)
        CLASS(IntMemoryPool), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: poolSize
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        IF (PRESENT(poolSize)) THEN
            this%poolSize = poolSize
        END IF
        
        IF (.NOT. ALLOCATED(this%pool)) THEN
            ALLOCATE(this%pool(this%poolSize))
        END IF
        
        this%currentIndex = 0
        this%allocatedCount = 0
        this%initialized = .TRUE.
    END SUBROUTINE IntMemoryPool_Init

    ! ==========================================================================
    ! Allocate memory from pool (with automatic expansion)
    ! Algorithm: If pool exhausted, expand by doubling size
    ! ==========================================================================
    FUNCTION IntMemoryPool_Allocate(this, size, status) RESULT(ptr)
        CLASS(IntMemoryPool), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4), POINTER :: ptr(:)
        
        INTEGER(i4) :: start_idx, new_size, old_size, ios
        INTEGER(i4), ALLOCATABLE :: temp_pool(:)
        
        CALL init_error_status(status)
        NULLIFY(ptr)
        
        IF (.NOT. this%initialized) THEN
            CALL this%Init(status=status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
        
        IF (this%currentIndex + size > this%poolSize) THEN
            ! Pool exhausted: try to expand pool
            ! Expansion strategy: double the pool size
            new_size = MAX(this%poolSize * 2, this%currentIndex + size)
            old_size = this%poolSize
            
            ! Allocate temporary pool
            ALLOCATE(temp_pool(new_size), stat=ios)
            IF (ios == 0) THEN
                ! Copy existing data
                temp_pool(1:old_size) = this%pool(1:old_size)
                ! Move allocation
                CALL MOVE_ALLOC(temp_pool, this%pool)
                this%poolSize = new_size
            ELSE
                ! Expansion failed, allocate separately
                ALLOCATE(ptr(size), stat=ios)
                IF (ios == 0) THEN
                    this%allocatedCount = this%allocatedCount + 1
                ELSE
                    status%status_code = IF_STATUS_INVALID
                    status%message = "IntMemoryPool: Failed to allocate memory"
                END IF
                RETURN
            END IF
        END IF
        
        ! Allocate from pool
        start_idx = this%currentIndex + 1
        this%currentIndex = this%currentIndex + size
        ptr => this%pool(start_idx:this%currentIndex)
        status%status_code = IF_STATUS_OK
    END FUNCTION IntMemoryPool_Allocate

    SUBROUTINE IntMemoryPool_Reset(this)
        CLASS(IntMemoryPool), INTENT(INOUT) :: this
        
        this%currentIndex = 0
        this%allocatedCount = 0
    END SUBROUTINE IntMemoryPool_Reset

    SUBROUTINE IntMemoryPool_GetStats(this, used, total, allocated)
        CLASS(IntMemoryPool), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: used, total, allocated
        
        used = this%currentIndex
        total = this%poolSize
        allocated = this%allocatedCount
    END SUBROUTINE IntMemoryPool_GetStats

    SUBROUTINE MemPoolManager_Init(this, realPoolSize, intPoolSize, status)
        CLASS(MemPoolManager), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: realPoolSize
        INTEGER(i4), INTENT(IN), OPTIONAL :: intPoolSize
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        CALL this%realPool%Init(poolSize=realPoolSize, status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        CALL this%intPool%Init(poolSize=intPoolSize, status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        this%enabled = .TRUE.
    END SUBROUTINE MemPoolManager_Init

    SUBROUTINE MemPoolManager_Reset(this)
        CLASS(MemPoolManager), INTENT(INOUT) :: this
        
        CALL this%realPool%Reset()
        CALL this%intPool%Reset()
    END SUBROUTINE MemPoolManager_Reset

    SUBROUTINE MemPoolManager_GetStats(this, realUsed, realTotal, realAlloc, &
                                          intUsed, intTotal, intAlloc)
        CLASS(MemPoolManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: realUsed, realTotal, realAlloc
        INTEGER(i4), INTENT(OUT) :: intUsed, intTotal, intAlloc
        
        CALL this%realPool%GetStats(realUsed, realTotal, realAlloc)
        CALL this%intPool%GetStats(intUsed, intTotal, intAlloc)
    END SUBROUTINE MemPoolManager_GetStats

END MODULE MD_KW_MemPool
