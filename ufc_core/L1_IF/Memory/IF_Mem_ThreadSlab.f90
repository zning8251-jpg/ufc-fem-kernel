!===============================================================================
! MODULE: IF_Mem_ThreadSlab
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — thread-local slab allocator for hot paths (Gauss loops)
! BRIEF:  O(1) alloc via pointer bump, O(1) reset. Pre-allocated per-thread
!         slabs, zero fragmentation. < 50 ns alloc, < 10 ns reset.
!===============================================================================
!
! Logic Chain (Mermaid):
! ```mermaid
! flowchart TB
! A[ThreadSlab_Init] --> B[ SLAB_SIZE ]
! B --> C[Gauss ]
!     C --> D[ThreadSlab_Reset]
!     D --> E[ThreadSlab_Alloc]
! E --> F[ ]
! F --> G{ ?}
! G -->| | E
! G -->| | H[ ]
! ```
!
! Contents (A-Z):
!   Types:
!     - ThreadSlab (per-thread memory slab)
!     - ThreadSlabRegistry (global slab manager)
!   Subroutines:
!     - ThreadSlab_Init, ThreadSlab_Finalize
!     - ThreadSlab_Reset, ThreadSlab_Alloc
!     - ThreadSlab_GetUsage, ThreadSlab_Report
!   Functions:
!     - ThreadSlab_GetThreadID (get current thread ID)
!===============================================================================

MODULE IF_Mem_ThreadSlab
  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: INT8, OUTPUT_UNIT
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Public Interface
  !---------------------------------------------------------------------------
  PUBLIC :: ThreadSlab, ThreadSlabRegistry
  PUBLIC :: IF_SLAB_SIZE_DEFAULT, IF_MAX_THREADS
  PUBLIC :: ThreadSlab_Init, ThreadSlab_Finalize
  PUBLIC :: ThreadSlab_Reset, ThreadSlab_Alloc, ThreadSlab_AllocAligned
  PUBLIC :: ThreadSlab_GetUsage, ThreadSlab_Report

  !---------------------------------------------------------------------------
  ! Constants
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: IF_SLAB_SIZE_DEFAULT = 1048576  ! 1 MB per thread
  INTEGER(i4), PARAMETER :: IF_MAX_THREADS = 64
  INTEGER(i4), PARAMETER :: IF_ALIGNMENT = 64  ! Cache line alignment

  !---------------------------------------------------------------------------
  ! Types
  !---------------------------------------------------------------------------

  !> Per-thread memory slab
  TYPE :: ThreadSlab
    INTEGER(INT8), ALLOCATABLE :: memory(:)  ! Slab memory
    INTEGER(i8)             :: offset = 0  ! Current allocation offset
    INTEGER(i8)             :: size = 0    ! Total slab size
    INTEGER(i4) :: thread_id = 0
    LOGICAL                    :: active = .FALSE.
  CONTAINS
    PROCEDURE :: init
    PROCEDURE :: reset
    PROCEDURE :: alloc
    PROCEDURE :: usage
  END TYPE ThreadSlab

  !> Global slab registry
  TYPE :: ThreadSlabRegistry
    TYPE(ThreadSlab) :: slabs(IF_MAX_THREADS)
    INTEGER(i4) :: n_threads = 0
    LOGICAL          :: initialized = .FALSE.
  END TYPE ThreadSlabRegistry

  !---------------------------------------------------------------------------
  ! Module Variables
  !---------------------------------------------------------------------------
  TYPE(ThreadSlabRegistry), SAVE, PROTECTED :: g_slab_registry

CONTAINS

  !=============================================================================
  ! Initialization
  !=============================================================================

  !> Initialize thread slabs for all threads
  SUBROUTINE ThreadSlab_Init(n_threads, slab_size)
    INTEGER(i4), INTENT(IN) :: n_threads
    INTEGER(i8), INTENT(IN), OPTIONAL :: slab_size
    
    INTEGER(i4) :: i
    INTEGER(i8) :: sz
    
    IF (g_slab_registry%initialized) RETURN
    
    sz = IF_SLAB_SIZE_DEFAULT
    IF (PRESENT(slab_size)) sz = slab_size
    
    g_slab_registry%n_threads = MIN(n_threads, IF_MAX_THREADS)
    
    DO i = 1, g_slab_registry%n_threads
      CALL g_slab_registry%slabs(i)%init(i, sz)
    END DO
    
    g_slab_registry%initialized = .TRUE.
    
  END SUBROUTINE ThreadSlab_Init

  !> Initialize a single slab (type-bound)
  SUBROUTINE init(this, thread_id, size)
    CLASS(ThreadSlab), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: thread_id
    INTEGER(i8), INTENT(IN) :: size
    
    IF (this%active) RETURN  ! Already initialized
    
    ALLOCATE(this%memory(size))
    this%size = size
    this%offset = 0
    this%thread_id = thread_id
    this%active = .TRUE.
    
  END SUBROUTINE init

  !> Finalize all thread slabs
  SUBROUTINE ThreadSlab_Finalize()
    INTEGER(i4) :: i
    
    DO i = 1, g_slab_registry%n_threads
      IF (ALLOCATED(g_slab_registry%slabs(i)%memory)) THEN
        DEALLOCATE(g_slab_registry%slabs(i)%memory)
      END IF
      g_slab_registry%slabs(i)%active = .FALSE.
    END DO
    
    g_slab_registry%initialized = .FALSE.
    g_slab_registry%n_threads = 0
    
  END SUBROUTINE ThreadSlab_Finalize

  !=============================================================================
  ! Allocation Operations
  !=============================================================================

  !> Reset slab offset (type-bound) - Call at start of Gauss loop
  SUBROUTINE reset(this)
    CLASS(ThreadSlab), INTENT(INOUT) :: this
    this%offset = 0
  END SUBROUTINE reset

  !> Reset slab by thread ID
  SUBROUTINE ThreadSlab_Reset(thread_id)
    INTEGER(i4), INTENT(IN) :: thread_id
    
    IF (thread_id < 1 .OR. thread_id > g_slab_registry%n_threads) RETURN
    g_slab_registry%slabs(thread_id)%offset = 0
    
  END SUBROUTINE ThreadSlab_Reset

  !> Allocate from slab (type-bound) - Returns pointer to INT8 array
  SUBROUTINE alloc(this, size, ptr, success)
    CLASS(ThreadSlab), INTENT(INOUT) :: this
    INTEGER(i8), INTENT(IN) :: size
    INTEGER(INT8), POINTER, INTENT(OUT) :: ptr(:)
    LOGICAL, INTENT(OUT) :: success
    
    INTEGER(i8) :: new_offset
    
    success = .FALSE.
    NULLIFY(ptr)
    
    IF (.NOT. this%active) RETURN
    
    new_offset = this%offset + size
    IF (new_offset > this%size) RETURN  ! Out of memory
    
    ! Pointer to slab memory region
    ptr(1:size) => this%memory(this%offset+1:new_offset)
    this%offset = new_offset
    success = .TRUE.
    
  END SUBROUTINE alloc

  !> Allocate from slab by thread ID
  SUBROUTINE ThreadSlab_Alloc(thread_id, size, ptr, success)
    INTEGER(i4), INTENT(IN) :: thread_id
    INTEGER(i8), INTENT(IN) :: size
    INTEGER(INT8), POINTER, INTENT(OUT) :: ptr(:)
    LOGICAL, INTENT(OUT) :: success
    
    success = .FALSE.
    NULLIFY(ptr)
    
    IF (thread_id < 1 .OR. thread_id > g_slab_registry%n_threads) RETURN
    CALL g_slab_registry%slabs(thread_id)%alloc(size, ptr, success)
    
  END SUBROUTINE ThreadSlab_Alloc

  !> Allocate with alignment (cache-line aligned)
  SUBROUTINE ThreadSlab_AllocAligned(thread_id, size, ptr, success)
    INTEGER(i4), INTENT(IN) :: thread_id
    INTEGER(i8), INTENT(IN) :: size
    INTEGER(INT8), POINTER, INTENT(OUT) :: ptr(:)
    LOGICAL, INTENT(OUT) :: success
    
    INTEGER(i8) :: aligned_offset, new_offset, padding
    TYPE(ThreadSlab), POINTER :: slab
    
    success = .FALSE.
    NULLIFY(ptr)
    
    IF (thread_id < 1 .OR. thread_id > g_slab_registry%n_threads) RETURN
    
    slab => g_slab_registry%slabs(thread_id)
    IF (.NOT. slab%active) RETURN
    
    ! Calculate aligned offset
    aligned_offset = slab%offset
    padding = MOD(IF_ALIGNMENT - MOD(aligned_offset, IF_ALIGNMENT), IF_ALIGNMENT)
    aligned_offset = aligned_offset + padding
    
    new_offset = aligned_offset + size
    IF (new_offset > slab%size) RETURN
    
    ptr(1:size) => slab%memory(aligned_offset+1:new_offset)
    slab%offset = new_offset
    success = .TRUE.
    
  END SUBROUTINE ThreadSlab_AllocAligned

  !=============================================================================
  ! Query and Reporting
  !=============================================================================

  !> Get slab usage (type-bound)
  FUNCTION usage(this) RESULT(usage)
    CLASS(ThreadSlab), INTENT(IN) :: this
    REAL(wp) :: usage
    
    IF (this%size == 0) THEN
      usage = 0.0_wp
    ELSE
      usage = REAL(this%offset, wp) / REAL(this%size, wp) * 100.0_wp
    END IF
    
  END FUNCTION usage

  !> Get usage by thread ID
  FUNCTION ThreadSlab_GetUsage(thread_id) RESULT(usage)
    INTEGER(i4), INTENT(IN) :: thread_id
    REAL(wp) :: usage
    
    usage = 0.0_wp
    IF (thread_id < 1 .OR. thread_id > g_slab_registry%n_threads) RETURN
    usage = g_slab_registry%slabs(thread_id)%usage()
    
  END FUNCTION ThreadSlab_GetUsage

  !> Print slab usage report
  SUBROUTINE ThreadSlab_Report(unit)
    INTEGER, INTENT(IN), OPTIONAL :: unit
    
    INTEGER(i4) :: u, i
    REAL(wp) :: usage
    
    u = OUTPUT_UNIT
    IF (PRESENT(unit)) u = unit
    
    IF (.NOT. g_slab_registry%initialized) THEN
      WRITE(u, '(A)') '[ThreadSlab] Not initialized'
      RETURN
    END IF
    
    WRITE(u, '(/,A)') '========== ThreadSlab Usage Report =========='
    WRITE(u, '(A,I0)') 'Number of threads: ', g_slab_registry%n_threads
    WRITE(u, '(A)') '----------------------------------------------'
    WRITE(u, '(A)') 'Thread    Slab Size(KB)    Used(KB)    Usage(%)'
    WRITE(u, '(A)') '----------------------------------------------'
    
    DO i = 1, g_slab_registry%n_threads
      usage = g_slab_registry%slabs(i)%usage()
      WRITE(u, '(I6,I12,I12,F12.1)') &
        i, &
        g_slab_registry%slabs(i)%size / 1024, &
        g_slab_registry%slabs(i)%offset / 1024, &
        usage
    END DO
    
    WRITE(u, '(A)') '=============================================='
    
  END SUBROUTINE ThreadSlab_Report

END MODULE IF_Mem_ThreadSlab