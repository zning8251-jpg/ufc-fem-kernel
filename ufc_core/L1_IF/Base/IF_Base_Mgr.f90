!===============================================================================
! MODULE: IF_Base_Mgr
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Mgr — domain container with symbol table + device caps
! BRIEF:  IF_Base_Domain container managing symbol registry and device
!         capability detection (nThreads, GPU/MPI flags).
! Status: CORE | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Base_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
#if defined(UFC_HAVE_MPI)
  USE mpi_f08,    ONLY: MPI_Initialized
#endif
  IMPLICIT NONE
  PRIVATE

  !-- IF_Base_* constants (symbol kinds) [P0] ----------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_GENERIC  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_PART     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_MATERIAL = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_SECTION  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_SET      = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_SURFACE  = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_STEP     = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_BASE_SYM_AMPLITUDE = 7_i4

  !--------------------------------------------------------------------
  ! IF_SymEntry ??single symbol table entry
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_SymEntry
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4)       :: id   = 0_i4   ! registered integer id
    INTEGER(i4)       :: kind = 0_i4   ! IF_SYM_* enumeration
  END TYPE IF_SymEntry

  !--------------------------------------------------------------------
  ! IF_DeviceCaps ??device capability descriptor (set-once at Init)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_DeviceCaps
    INTEGER(i4) :: nCPUCores    = 1_i4
    INTEGER(i4) :: nGPUDevices  = 0_i4
    LOGICAL     :: gpuAvailable = .FALSE.
    LOGICAL     :: mpiAvailable = .FALSE.
    LOGICAL     :: ompAvailable = .FALSE.
  END TYPE IF_DeviceCaps

  !--------------------------------------------------------------------
  ! IF_Base_Domain ??domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Base_Domain
    TYPE(IF_DeviceCaps)            :: deviceCaps
    TYPE(IF_SymEntry), ALLOCATABLE :: sym_table(:)
    INTEGER(i4)                    :: nEntries    = 0_i4
    INTEGER(i4)                    :: sym_cap     = 0_i4
    INTEGER(i4)                    :: nThreads    = 1_i4
    LOGICAL                        :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetCaps
    PROCEDURE :: RegisterSymbol
    PROCEDURE :: LookupSymbol
  END TYPE IF_Base_Domain

CONTAINS

  !====================================================================
  ! IF_Base_Finalize ??release symbol table, reset caps
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(IF_Base_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%sym_table)) DEALLOCATE(this%sym_table)
    this%nEntries                = 0_i4
    this%sym_cap                 = 0_i4
    this%nThreads                = 1_i4
    this%deviceCaps%nCPUCores    = 1_i4
    this%deviceCaps%nGPUDevices  = 0_i4
    this%deviceCaps%gpuAvailable = .FALSE.
    this%deviceCaps%mpiAvailable = .FALSE.
    this%deviceCaps%ompAvailable = .FALSE.
    this%initialized             = .FALSE.

  END SUBROUTINE Finalize

  !====================================================================
  ! IF_Base_GetCaps ??read-only copy of device capabilities
  !====================================================================
  SUBROUTINE GetCaps(this, caps, status)
    CLASS(IF_Base_Domain), INTENT(IN)  :: this
    TYPE(IF_DeviceCaps),   INTENT(OUT) :: caps
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    caps = this%deviceCaps
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetCaps

  !====================================================================
  ! IF_Base_Init ??initialise base domain, detect device caps
  !====================================================================
  SUBROUTINE Init(this, nThreads, sym_capacity, status)
    CLASS(IF_Base_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: nThreads
    INTEGER(i4),           INTENT(IN)    :: sym_capacity
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    this%nThreads = MAX(1_i4, nThreads)
    this%sym_cap  = MAX(64_i4, sym_capacity)
    ALLOCATE(this%sym_table(this%sym_cap))
    this%nEntries = 0_i4

    ! Device capability detection (static, set-once at job start)
    this%deviceCaps%nCPUCores    = this%nThreads
    this%deviceCaps%ompAvailable = (this%nThreads > 1_i4)
#if defined(UFC_HAVE_MPI)
    ! MPI probe when built with -DUFC_HAVE_MPI
    BLOCK
      LOGICAL :: mpi_flag
      INTEGER(i4) :: mpi_ierr
      CALL MPI_Initialized(mpi_flag, mpi_ierr)
      this%deviceCaps%mpiAvailable = (mpi_ierr == 0 .AND. mpi_flag)
    END BLOCK
#else
    this%deviceCaps%mpiAvailable = .FALSE.
#endif
#if defined(UFC_HAVE_CUDA)
    ! GPU probe when built with -DUFC_HAVE_CUDA (stub: would call cudaGetDeviceCount)
    this%deviceCaps%gpuAvailable = .FALSE.  ! TODO: wire cudaRuntime probe
#else
    this%deviceCaps%gpuAvailable = .FALSE.
#endif

    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE Init

  !====================================================================
  ! IF_Base_LookupSym ??find id by name in symbol table
  !
  ! Computation chain:
  !   Sequential TRIM scan of sym_table(1:nEntries)%name   O(nEntries)
  !   Returns IF_STATUS_INVALID + id=0 if name not found.
  !   Used by L3_MD domain parsers to resolve cross-domain references
  !   (e.g. section_ref, amp_ref) by name rather than by hardcoded id.
  !====================================================================
  SUBROUTINE LookupSymbol(this, name, id, status)
    CLASS(IF_Base_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),      INTENT(IN)  :: name
    INTEGER(i4),           INTENT(OUT) :: id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    id = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    DO i = 1, this%nEntries
      IF (TRIM(this%sym_table(i)%name) == TRIM(name)) THEN
        id = this%sym_table(i)%id
        status%status_code = IF_STATUS_OK; RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID   ! not found

  END SUBROUTINE LookupSymbol

  !====================================================================
  ! IF_Base_RegSym ??append (name, id, kind) to table
  !
  ! Computation chain:
  !   1. Guard: domain initialized, name non-empty
  !   2. Duplicate check: call LookupSymbol ??error if name exists
  !   3. Grow table if nEntries == sym_cap: MOVE_ALLOC to 2*sym_cap
  !   4. Append entry; nEntries++
  !   O(nEntries) for duplicate scan; O(1) amortised for growth.
  !
  ! Called by L6_AP immediately after each named object is parsed.
  ! All cross-domain name references are resolved post-parse via
  ! LookupSymbol rather than repeated string compares at solve time.
  !====================================================================
  SUBROUTINE RegisterSymbol(this, name, id, kind, status)
    CLASS(IF_Base_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),      INTENT(IN)    :: name
    INTEGER(i4),           INTENT(IN)    :: id
    INTEGER(i4),           INTENT(IN)    :: kind
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(IF_SymEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap, dummy_id

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. LEN_TRIM(name) == 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    ! Duplicate check
    CALL this%LookupSymbol(name, dummy_id, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      status%status_code = IF_STATUS_INVALID; RETURN   ! duplicate name
    END IF
    CALL init_error_status(status)

    ! Grow table if at capacity
    IF (this%nEntries >= this%sym_cap) THEN
      new_cap = this%sym_cap * 2_i4
      ALLOCATE(tmp(new_cap))
      tmp(1:this%nEntries) = this%sym_table(1:this%nEntries)
      CALL MOVE_ALLOC(tmp, this%sym_table)
      this%sym_cap = new_cap
    END IF

    this%nEntries = this%nEntries + 1_i4
    this%sym_table(this%nEntries)%name = TRIM(name)
    this%sym_table(this%nEntries)%id   = id
    this%sym_table(this%nEntries)%kind = kind
    status%status_code = IF_STATUS_OK

  END SUBROUTINE RegisterSymbol

END MODULE IF_Base_Mgr