!===============================================================================
! MODULE: IF_Mem_Core
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Core — named memory pools using arena (high-water mark) allocation
! BRIEF:  CreatePool / AllocFromPool / ResetPool / DestroyPool [P0/P1];
!         workspace manager, aggregate statistics, usage reporting.
!===============================================================================
!
! Theory chain:
!   Arena allocator pattern:
!     - Pre-allocate a contiguous REAL(wp) backing buffer per named pool
!       (one system ALLOCATE call at analysis start, never in hot path).
!     - Satisfy requests by bumping a cursor (used_elems) ?O(1), no
!       system malloc, no fragmentation.
!     - Reset entire arena in O(1) via used_elems = 0 (pool wipe).
!
!   Why REAL(wp) backing buffer (not BYTE / INTEGER(i1)):
!     All hot-path consumers (L4_PH Gauss loop, L5_RT increment scratch)
!     need wp-aligned contiguous slices.  Returning
!       pool_rt(slot)%buf(start : start+n-1)
!     provides a guaranteed-aligned contiguous array with no copy and no
!     C_LOC/C_F_POINTER acrobatics required.
!
! Logic chain:
!   Job start   : Init(maxPools) ?CreatePool("PH_ELEM_WS", 3600) ?N
!   L4_PH inner : AllocFromPool ?buf(s:e) ?element computation ?ResetPool
!   L5_RT incr  : AllocFromPool("RT_INC_WS") ?ResetPool per increment
!   Job end     : PrintReport ?Finalize
!
! Computation chain:
!   CreatePool   : ALLOCATE buf(cap_elems); used_elems = 0        O(cap)
!   AllocFromPool: start = used_elems+1; used_elems += n          O(nPools)
!   ResetPool    : used_elems = 0                                 O(1)
!   FindPool     : sequential scan pool_descs(1:nPools)%name      O(nPools)
!   PrintReport  : utilization% = 100*peak_elems/cap_elems per pool
!
! Data chain:
!   Container path: g_ufc_global%if_layer%memory
!   pool_descs(:) ?configuration written once at CreatePool (Desc)
!   pool_rt(:)    ?runtime state: buf + HWM cursor + stats
!   stats         ?aggregate across all pools
!   Lifecycle     : Process-level (Job-scoped); pools live for entire run
!
! Level 1: (slot_pool, elem_coords_cache) Step/Incr
!
! Contents:
!   Types:
!     IF_MemPool_Desc     ?pool configuration (name, cap_elems)
!     IF_MemPool_Runtime  ?per-pool runtime (buf + HWM cursor + counts)
!     IF_MemStats         ?aggregate statistics
!     IF_Memory_Domain    ?domain container
!   Subroutines (A-Z):
!     IF_Memory_AllocFromPool
!     IF_Memory_CreatePool
!     IF_Memory_Domain_Finalize
!     IF_Memory_Domain_Init
!     IF_Memory_GetStats
!     IF_Memory_PrintReport
!     IF_Memory_ResetPool
!   Private helpers:
!     IF_FindPool         ?linear search: pool_name ?slot index
!
! Design outline: ?? ?2.2??2.6a?L1_IF Memory ??????.5 / ?????
! USE contract (?????7.3): ?L1?? L2?L6?
! WriteBack contract (?????7.2): L1 ?WriteBack?
! Status: Phase B (pool operations implemented)
! Last verified: 2026-03-06
! Theory: N/A
! Status: Draft
!======================================================================
MODULE IF_Mem_Core
  USE IF_Prec_Core,    ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! IF_MemPool_Desc ?pool configuration (written once at CreatePool)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_MemPool_Desc
    CHARACTER(LEN=32) :: name      = ""
    INTEGER(i8)       :: cap_elems = 0_i8   ! capacity in REAL(wp) elements
    LOGICAL           :: isActive  = .FALSE.
  END TYPE IF_MemPool_Desc

  !--------------------------------------------------------------------
  ! IF_MemPool_Runtime ?per-pool runtime state
  !
  ! Allocation protocol (bump-pointer / high-water mark):
  !   AllocFromPool:
  !     start_idx  = used_elems + 1
  !     used_elems = used_elems + n_requested       (O(1), no malloc)
  !     caller holds buf(start_idx : start_idx+n-1) ?a contiguous slice
  !   ResetPool:
  !     used_elems = 0                              (O(1), arena wipe)
  !     buf contents are NOT zeroed; caller must not read stale data.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_MemPool_Runtime
    REAL(wp), ALLOCATABLE :: buf(:)          ! backing REAL(wp) store
    INTEGER(i4)           :: cap_elems   = 0_i4   ! mirror of Desc (i4 for hot path)
    INTEGER(i4)           :: used_elems  = 0_i4   ! HWM cursor
    INTEGER(i4)           :: peak_elems  = 0_i4   ! max used_elems seen
    INTEGER(i4)           :: n_allocs    = 0_i4   ! cumulative AllocFromPool calls
    LOGICAL               :: isActive    = .FALSE.
  END TYPE IF_MemPool_Runtime

  !--------------------------------------------------------------------
  ! IF_MemStats ?aggregate statistics across all pools
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_MemStats
    INTEGER(i8) :: totalAllocBytes = 0_i8   ! sum of all backing-buffer bytes
    INTEGER(i8) :: peakMem         = 0_i8   ! peak aggregate used bytes
    INTEGER(i4) :: nAllocs         = 0_i4   ! cumulative AllocFromPool calls
    INTEGER(i4) :: nResets         = 0_i4   ! cumulative ResetPool calls
    INTEGER(i4) :: nPools          = 0_i4   ! active pool count
  END TYPE IF_MemStats

  !--------------------------------------------------------------------
  ! IF_Memory_Domain ?domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Memory_Domain
    TYPE(IF_MemStats)                     :: stats
    TYPE(IF_MemPool_Desc),    ALLOCATABLE :: pool_descs(:)   ! config
    TYPE(IF_MemPool_Runtime), ALLOCATABLE :: pool_rt(:)      ! runtime
    INTEGER(i4) :: maxPools    = 16_i4
    INTEGER(i4) :: nPools      = 0_i4
    LOGICAL     :: enMemPool   = .TRUE.
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: CreatePool
    PROCEDURE :: AllocFromPool
    PROCEDURE :: AllocFromPoolById
    PROCEDURE :: ResetPool
    PROCEDURE :: GetStats
    PROCEDURE :: PrintReport
  END TYPE IF_Memory_Domain

CONTAINS

  !====================================================================
  ! IF_FindPool (private) ?locate slot index by pool name
  !
  ! Computation chain:
  !   Sequential scan of pool_descs(1:nPools)%name (TRIM comparison).
  !   n_pools <= maxPools <= 64 in typical FE job ?scan cost negligible;
  !   no hash table needed.  Returns 0 if not found.
  !====================================================================
  PURE FUNCTION IF_FindPool(this, pool_name) RESULT(idx)
    TYPE(IF_Memory_Domain), INTENT(IN) :: this
    CHARACTER(LEN=*),       INTENT(IN) :: pool_name
    INTEGER(i4)                        :: idx
    INTEGER(i4) :: i

    idx = 0_i4
    DO i = 1, this%nPools
      IF (TRIM(this%pool_descs(i)%name) == TRIM(pool_name)) THEN
        idx = i; RETURN
      END IF
    END DO
  END FUNCTION IF_FindPool

  !====================================================================
  ! IF_Memory_Domain_Init ?initialise domain, pre-size pool arrays
  !====================================================================
  SUBROUTINE Init(this, maxPools, enMemPool, status)
    CLASS(IF_Memory_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: maxPools
    LOGICAL,                 INTENT(IN)    :: enMemPool
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    this%maxPools  = MAX(1_i4, maxPools)
    this%enMemPool = enMemPool
    this%nPools    = 0_i4
    ALLOCATE(this%pool_descs(this%maxPools))
    ALLOCATE(this%pool_rt(this%maxPools))
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE Init

  !====================================================================
  ! IF_Memory_Domain_Finalize ?release all pool buffers, reset stats
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(IF_Memory_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i

    IF (.NOT. this%initialized) RETURN

    DO i = 1, this%nPools
      IF (ALLOCATED(this%pool_rt(i)%buf)) DEALLOCATE(this%pool_rt(i)%buf)
      this%pool_rt(i)%isActive   = .FALSE.
      this%pool_rt(i)%used_elems = 0_i4
      this%pool_rt(i)%peak_elems = 0_i4
      this%pool_rt(i)%n_allocs   = 0_i4
    END DO

    IF (ALLOCATED(this%pool_descs)) DEALLOCATE(this%pool_descs)
    IF (ALLOCATED(this%pool_rt))    DEALLOCATE(this%pool_rt)

    this%nPools                = 0_i4
    this%stats%totalAllocBytes = 0_i8
    this%stats%peakMem         = 0_i8
    this%stats%nAllocs         = 0_i4
    this%stats%nResets         = 0_i4
    this%stats%nPools          = 0_i4
    this%initialized           = .FALSE.

  END SUBROUTINE Finalize

  !====================================================================
  ! IF_Memory_CreatePool ?register and back-allocate a named pool
  !
  ! Computation chain:
  !   1. Guards: domain initialised | enMemPool | no duplicate name |
  !              slot available | cap_elems > 0
  !   2. Claim next slot; write Desc (name, cap_elems, isActive=T)
  !   3. ALLOCATE pool_rt(slot)%buf(cap_elems)  ?ONE system malloc
  !      Zero-initialise buf for alignment safety.
  !   4. Init Runtime: used_elems=0, peak_elems=0, n_allocs=0
  !   5. stats%totalAllocBytes += cap_elems * 8  (8 bytes per REAL(wp))
  !      stats%nPools = nPools
  !
  ! This subroutine is called once per pool at analysis initialisation.
  ! It MUST NOT be called during the Gauss-point loop or increment loop.
  !
  ! Example (element workspace pool for 60-dof elements):
  !   CALL mem%CreatePool("PH_ELEM_WS", 3600_i4, status)
  !   ! Reserves 3600 wp-elements = 28.8 KB for K_e, F_e scratch
  !====================================================================
  SUBROUTINE CreatePool(this, pool_name, cap_elems, status)
    CLASS(IF_Memory_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: pool_name
    INTEGER(i4),             INTENT(IN)    :: cap_elems
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4) :: slot

    CALL init_error_status(status)

    IF (.NOT. this%initialized .OR. .NOT. this%enMemPool) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (IF_FindPool(this, pool_name) > 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN   ! duplicate name
    END IF
    IF (this%nPools >= this%maxPools .OR. cap_elems < 1) THEN
      status%status_code = IF_STATUS_INVALID; RETURN   ! no slot or bad size
    END IF

    ! --- Claim slot and write Desc ---
    this%nPools = this%nPools + 1_i4
    slot        = this%nPools
    this%pool_descs(slot)%name      = pool_name
    this%pool_descs(slot)%cap_elems = INT(cap_elems, i8)
    this%pool_descs(slot)%isActive  = .TRUE.

    ! --- Single system ALLOCATE for the backing buffer ---
    ALLOCATE(this%pool_rt(slot)%buf(cap_elems))
    this%pool_rt(slot)%buf       = 0.0_wp   ! zero-init for alignment safety
    this%pool_rt(slot)%cap_elems  = cap_elems
    this%pool_rt(slot)%used_elems = 0_i4
    this%pool_rt(slot)%peak_elems = 0_i4
    this%pool_rt(slot)%n_allocs   = 0_i4
    this%pool_rt(slot)%isActive   = .TRUE.

    ! --- Aggregate stats: 8 bytes per REAL(wp) element ---
    this%stats%totalAllocBytes = this%stats%totalAllocBytes + &
                                 INT(cap_elems, i8) * 8_i8
    this%stats%nPools          = this%nPools
    status%status_code         = IF_STATUS_OK

  END SUBROUTINE CreatePool

  !====================================================================
  ! IF_Memory_AllocFromPool ?arena bump-pointer allocation (hot path)
  !
  ! Computation chain:
  !   1. IF_FindPool(pool_name) ?slot         O(nPools) ?cache slot!
  !   2. Guard: pool active, n_elems > 0,
  !             remaining = cap_elems - used_elems >= n_elems
  !   3. start_idx  = used_elems + 1            O(1), no malloc
  !      used_elems += n_elems
  !      peak_elems  = MAX(peak_elems, used_elems)
  !   4. pool_slot [OUT] = slot                 for caller to cache
  !
  ! Caller accesses the slice:
  !   mem%pool_rt(pool_slot)%buf(start_idx : start_idx + n_elems - 1)
  ! which is a contiguous REAL(wp) array with guaranteed wp alignment.
  !
  ! Hot-path guidance:
  !   To avoid the O(nPools) name scan inside the Gauss loop, callers
  !   should call AllocFromPool ONCE before the element loop, cache the
  !   returned pool_slot and start_idx, then call ResetPool after each
  !   element (or after the full element loop, depending on scope).
  !====================================================================
  SUBROUTINE AllocFromPool(this, pool_name, n_elems, &
                                     start_idx, pool_slot, status)
    CLASS(IF_Memory_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: pool_name
    INTEGER(i4),             INTENT(IN)    :: n_elems
    INTEGER(i4),             INTENT(OUT)   :: start_idx
    INTEGER(i4),             INTENT(OUT)   :: pool_slot
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4) :: slot, remaining

    CALL init_error_status(status)
    start_idx = 0_i4; pool_slot = 0_i4

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    slot = IF_FindPool(this, pool_name)
    IF (slot == 0 .OR. .NOT. this%pool_rt(slot)%isActive) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    remaining = this%pool_rt(slot)%cap_elems - this%pool_rt(slot)%used_elems
    IF (n_elems < 1 .OR. n_elems > remaining) THEN
      status%status_code = IF_STATUS_INVALID; RETURN   ! pool exhausted
    END IF

    ! --- Bump HWM cursor: O(1), no system call ---
    start_idx  = this%pool_rt(slot)%used_elems + 1_i4
    this%pool_rt(slot)%used_elems = this%pool_rt(slot)%used_elems + n_elems
    this%pool_rt(slot)%peak_elems = MAX(this%pool_rt(slot)%peak_elems, &
                                        this%pool_rt(slot)%used_elems)
    this%pool_rt(slot)%n_allocs   = this%pool_rt(slot)%n_allocs + 1_i4

    ! --- Aggregate ---
    this%stats%nAllocs = this%stats%nAllocs + 1_i4
    pool_slot          = slot
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AllocFromPool

  !====================================================================
  ! IF_Memory_AllocFromPoolById - hot-path allocation by pool index (O(1))
  !   Caller caches pool_idx from AllocFromPool or CreatePool; avoids name scan.
  !====================================================================
  SUBROUTINE AllocFromPoolById(this, pool_idx, n_elems, start_idx, status)
    CLASS(IF_Memory_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: pool_idx
    INTEGER(i4),             INTENT(IN)    :: n_elems
    INTEGER(i4),             INTENT(OUT)   :: start_idx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4) :: slot, remaining

    CALL init_error_status(status)
    start_idx = 0_i4

    IF (.NOT. this%initialized .OR. pool_idx < 1 .OR. pool_idx > this%nPools) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    slot = pool_idx
    IF (.NOT. this%pool_rt(slot)%isActive) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    remaining = this%pool_rt(slot)%cap_elems - this%pool_rt(slot)%used_elems
    IF (n_elems < 1 .OR. n_elems > remaining) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    start_idx  = this%pool_rt(slot)%used_elems + 1_i4
    this%pool_rt(slot)%used_elems = this%pool_rt(slot)%used_elems + n_elems
    this%pool_rt(slot)%peak_elems = MAX(this%pool_rt(slot)%peak_elems, &
                                        this%pool_rt(slot)%used_elems)
    this%pool_rt(slot)%n_allocs   = this%pool_rt(slot)%n_allocs + 1_i4
    this%stats%nAllocs = this%stats%nAllocs + 1_i4
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AllocFromPoolById

  !====================================================================
  ! IF_Memory_ResetPool ?arena wipe: reset HWM cursor to 0   (O(1))
  !
  ! Computation chain:
  !   pool_rt(slot)%used_elems = 0
  !   All previously allocated slices are logically freed in O(1).
  !   The backing buffer is reused from position 1 on the next Alloc.
  !   buf(:) contents are NOT zeroed ?callers must not read stale data.
  !
  ! Typical usage pattern:
  !   (per-element or per-increment boundary)
  !   CALL mem%ResetPool("PH_ELEM_WS", status)
  !   Wipes the element workspace after processing each element; the
  !   next element call finds used_elems == 0 and reuses from start.
  !====================================================================
  SUBROUTINE ResetPool(this, pool_name, status)
    CLASS(IF_Memory_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: pool_name
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4) :: slot

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    slot = IF_FindPool(this, pool_name)
    IF (slot == 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%pool_rt(slot)%used_elems = 0_i4   ! arena wipe ?O(1)
    this%stats%nResets             = this%stats%nResets + 1_i4
    status%status_code             = IF_STATUS_OK

  END SUBROUTINE ResetPool

  !====================================================================
  ! IF_Memory_GetStats ?return snapshot of aggregate statistics
  !====================================================================
  SUBROUTINE GetStats(this, stats_out)
    CLASS(IF_Memory_Domain), INTENT(IN)  :: this
    TYPE(IF_MemStats),       INTENT(OUT) :: stats_out

    stats_out = this%stats

  END SUBROUTINE GetStats

  !====================================================================
  ! IF_Memory_PrintReport ?print per-pool usage summary to Fortran unit
  !
  ! Computation chain:
  !   For each active pool i in 1..nPools:
  !     util_pct = 100.0 * peak_elems / cap_elems
  !   Prints a tabular report: name | cap | peak | util% | n_allocs
  !
  ! Call at analysis end (e.g. unit=6 for stdout) to verify pool sizing.
  ! Oversized pools (util% << 50) should be shrunk; exhausted pools
  ! (util% == 100 + IF_STATUS_INVALID from Alloc) must be enlarged.
  !====================================================================
  SUBROUTINE PrintReport(this, unit)
    CLASS(IF_Memory_Domain), INTENT(IN) :: this
    INTEGER(i4),             INTENT(IN) :: unit
    INTEGER(i4) :: i
    REAL(wp)    :: util_pct

    WRITE(unit,'(A)') "========================================================"
    WRITE(unit,'(A)') "  IF_Memory_Domain Pool Report"
    WRITE(unit,'(A)') "========================================================"
    WRITE(unit,'(A,I4)')   "  Active pools      : ", this%nPools
    WRITE(unit,'(A,I12)')  "  Total alloc (B)   : ", this%stats%totalAllocBytes
    WRITE(unit,'(A,I10)')  "  Cumul AllocCalls  : ", this%stats%nAllocs
    WRITE(unit,'(A,I10)')  "  Cumul ResetCalls  : ", this%stats%nResets
    WRITE(unit,'(A)') "--------------------------------------------------------"
    WRITE(unit,'(A)') "  Name                    Cap(el) Peak(el) Util%  NAlloc"
    WRITE(unit,'(A)') "  ----------------------- ------- -------- ------ ------"
    DO i = 1, this%nPools
      IF (.NOT. this%pool_rt(i)%isActive) CYCLE
      IF (this%pool_rt(i)%cap_elems > 0) THEN
        util_pct = 100.0_wp * REAL(this%pool_rt(i)%peak_elems, wp) / &
                              REAL(this%pool_rt(i)%cap_elems,  wp)
      ELSE
        util_pct = 0.0_wp
      END IF
      WRITE(unit,'(2X,A24,I8,I9,F7.1,I7)') &
        ADJUSTL(this%pool_descs(i)%name), &
        this%pool_rt(i)%cap_elems,        &
        this%pool_rt(i)%peak_elems,        &
        util_pct,                          &
        this%pool_rt(i)%n_allocs
    END DO
    WRITE(unit,'(A)') "========================================================"

  END SUBROUTINE PrintReport

END MODULE IF_Mem_Core