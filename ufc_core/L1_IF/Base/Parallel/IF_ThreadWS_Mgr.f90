!===============================================================================
! MODULE: IF_ThreadWS_Mgr
! LAYER:  L1_IF
! DOMAIN: Parallel
! ROLE:   Mgr — core thread workspace management and parallel primitives
! BRIEF:  Init/Destroy workspace pool, GetLocalArray, AtomicAdd, Critical sections.
!         Auto thread-ID detection in OpenMP parallel regions.
!===============================================================================
MODULE IF_ThreadWS_Mgr
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, error_set
  USE IF_ThreadWS_Def, ONLY: ThreadWS, ThreadWorkspace, MAX_THREADS, &
                               MAX_ARRAYS_PER_THREAD, MAX_ARRAY_NAME_LEN
  IMPLICIT NONE
  
  PRIVATE
  
  ! Public API
  PUBLIC :: IF_ThreadWS_Init, IF_ThreadWS_Destroy
  PUBLIC :: IF_ThreadWS_GetLocalArray, IF_ThreadWS_AggregateReal1D
  PUBLIC :: IF_ThreadWS_RegisterArray, IF_ThreadWS_ResetAll
  PUBLIC :: IF_ThreadWS_AtomicAdd, IF_ThreadWS_AtomicAddInt, &
                         IF_ThreadWS_EnterCritical, IF_ThreadWS_ExitCritical
  PUBLIC :: IF_ThreadWS_SetCurrentThread, IF_ThreadWS_GetCurrentThread
  
  ! Critical section lock type
  INTEGER(i4), PARAMETER :: CRITICAL_LOCK_SIZE = 8
  TYPE, PUBLIC :: ThreadWSCriticalSection
    INTEGER(i4) :: lock_data(CRITICAL_LOCK_SIZE) = 0
    LOGICAL :: initialized = .FALSE.
  END TYPE ThreadWSCriticalSection
  
CONTAINS

  !====================================================================
  ! Initialization and Destruction
  !====================================================================
  
  SUBROUTINE IF_ThreadWS_Init(thread_ws, n_threads, n_real_1d, n_real_2d, &
                              n_int_1d, n_int_2d, n_logical_1d, &
                              max_size_1d, max_size_2d, status)
    !! Initialize thread workspace manager with pre-allocated arrays
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: n_threads
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_real_1d, n_real_2d
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_int_1d, n_int_2d, n_logical_1d
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_size_1d, max_size_2d
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, local_status
    INTEGER(i4) :: nr1, nr2, ni1, ni2, nl1, ms1, ms2
    
    status = 0
    local_status = 0
    
    ! Validate thread count
    IF (n_threads < 1 .OR. n_threads > MAX_THREADS) THEN
      status = -1
      RETURN
    END IF
    
    ! Set default values for optional parameters
    nr1 = MERGE(n_real_1d, 0_i4, PRESENT(n_real_1d))
    nr2 = MERGE(n_real_2d, 0_i4, PRESENT(n_real_2d))
    ni1 = MERGE(n_int_1d, 0_i4, PRESENT(n_int_1d))
    ni2 = MERGE(n_int_2d, 0_i4, PRESENT(n_int_2d))
    nl1 = MERGE(n_logical_1d, 0_i4, PRESENT(n_logical_1d))
    ms1 = MERGE(max_size_1d, 1000_i4, PRESENT(max_size_1d))
    ms2 = MERGE(max_size_2d, 100_i4, PRESENT(max_size_2d))
    
    ! Initialize each thread workspace
    DO i = 1, n_threads
      CALL thread_ws%threads(i)%Initialize(i, nr1, nr2, ni1, ni2, nl1, ms1, ms2, local_status)
      
      IF (local_status /= 0) THEN
        status = -2
        ! Cleanup already initialized threads
        DO j = 1, i - 1
          CALL thread_ws%threads(j)%Destroy()
        END DO
        RETURN
      END IF
    END DO
    
    thread_ws%n_threads = n_threads
    thread_ws%current_thread_id = 0
    thread_ws%initialized = .TRUE.
    
  END SUBROUTINE IF_ThreadWS_Init
  
  SUBROUTINE IF_ThreadWS_Destroy(thread_ws)
    !! Destroy all thread workspaces and free memory
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4) :: i
    
    IF (.NOT. thread_ws%initialized) RETURN
    
    ! Destroy each thread workspace
    DO i = 1, thread_ws%n_threads
      CALL thread_ws%threads(i)%Destroy()
    END DO
    
    thread_ws%n_threads = 0
    thread_ws%current_thread_id = 0
    thread_ws%initialized = .FALSE.
    
  END SUBROUTINE IF_ThreadWS_Destroy
  
  !====================================================================
  ! Workspace Access
  !====================================================================
  
  FUNCTION IF_ThreadWS_GetLocalArray(thread_ws, thread_id, array_name, status) RESULT(ptr)
    TYPE(ThreadWS), INTENT(INOUT), TARGET :: thread_ws
    INTEGER(i4), INTENT(IN) :: thread_id
    CHARACTER(LEN=*), INTENT(IN) :: array_name
    INTEGER(i4), INTENT(OUT) :: status
    REAL(wp), POINTER :: ptr(:)

    INTEGER(i4) :: i, slot
    TYPE(ThreadWorkspace), POINTER :: tw

    ptr => NULL()
    status = 0

    IF (.NOT. thread_ws%initialized) THEN
      status = -1
      RETURN
    END IF

    IF (thread_id < 1 .OR. thread_id > thread_ws%n_threads) THEN
      status = -2
      RETURN
    END IF

    tw => thread_ws%threads(thread_id)
    IF (.NOT. tw%initialized) THEN
      status = -3
      RETURN
    END IF

    slot = 0
    DO i = 1, tw%n_arrays
      IF (TRIM(tw%array_info(i)%name) == TRIM(array_name)) THEN
        slot = i
        EXIT
      END IF
    END DO

    IF (slot == 0) THEN
      status = -4
      RETURN
    END IF

    IF (tw%array_info(slot)%array_type /= 1 .OR. &
        tw%array_info(slot)%array_rank /= 1) THEN
      status = -5
      RETURN
    END IF

    IF (.NOT. ALLOCATED(tw%real_arrays_1d)) THEN
      status = -6
      RETURN
    END IF

    ptr => tw%real_arrays_1d(:, slot)
    status = 0

  END FUNCTION IF_ThreadWS_GetLocalArray

  SUBROUTINE IF_ThreadWS_AggregateReal1D(thread_ws, array_index, global_array, &
                                         operation, status)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: array_index
    REAL(wp), INTENT(INOUT) :: global_array(:)
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: operation
    INTEGER(i4), INTENT(OUT) :: status

    CHARACTER(LEN=32) :: op
    INTEGER(i4) :: t, n_copy

    status = 0
    op = 'ADD'
    IF (PRESENT(operation)) op = TRIM(ADJUSTL(operation))

    IF (.NOT. thread_ws%initialized) THEN
      status = -1
      RETURN
    END IF

    DO t = 1, thread_ws%n_threads
      IF (.NOT. thread_ws%threads(t)%initialized) CYCLE
      IF (.NOT. ALLOCATED(thread_ws%threads(t)%real_arrays_1d)) CYCLE
      IF (array_index < 1 .OR. &
          array_index > SIZE(thread_ws%threads(t)%real_arrays_1d, 2)) THEN
        status = -2
        RETURN
      END IF

      n_copy = MIN(SIZE(global_array), &
                   SIZE(thread_ws%threads(t)%real_arrays_1d, 1))

      SELECT CASE (TRIM(op))
      CASE ('ADD')
        global_array(1:n_copy) = global_array(1:n_copy) + &
          thread_ws%threads(t)%real_arrays_1d(1:n_copy, array_index)
      CASE ('MAX')
        global_array(1:n_copy) = MAX(global_array(1:n_copy), &
          thread_ws%threads(t)%real_arrays_1d(1:n_copy, array_index))
      CASE ('MIN')
        global_array(1:n_copy) = MIN(global_array(1:n_copy), &
          thread_ws%threads(t)%real_arrays_1d(1:n_copy, array_index))
      CASE DEFAULT
        global_array(1:n_copy) = global_array(1:n_copy) + &
          thread_ws%threads(t)%real_arrays_1d(1:n_copy, array_index)
      END SELECT
    END DO

    status = 0

  END SUBROUTINE IF_ThreadWS_AggregateReal1D

  SUBROUTINE IF_ThreadWS_RegisterArray(thread_ws, name, array_type, &
                                       array_rank, size1, size2, status)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    CHARACTER(LEN=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: array_type
    INTEGER(i4), INTENT(IN) :: array_rank
    INTEGER(i4), INTENT(IN) :: size1
    INTEGER(i4), INTENT(IN), OPTIONAL :: size2
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: t, slot

    status = 0

    IF (.NOT. thread_ws%initialized) THEN
      status = -1
      RETURN
    END IF

    DO t = 1, thread_ws%n_threads
      IF (.NOT. thread_ws%threads(t)%initialized) CYCLE

      slot = thread_ws%threads(t)%n_arrays + 1
      IF (slot > MAX_ARRAYS_PER_THREAD) THEN
        status = -2
        RETURN
      END IF

      thread_ws%threads(t)%array_info(slot)%name = TRIM(name)
      thread_ws%threads(t)%array_info(slot)%array_type = array_type
      thread_ws%threads(t)%array_info(slot)%array_rank = array_rank
      thread_ws%threads(t)%array_info(slot)%size1 = size1
      IF (PRESENT(size2)) THEN
        thread_ws%threads(t)%array_info(slot)%size2 = size2
      END IF
      thread_ws%threads(t)%array_info(slot)%allocated = .TRUE.
      thread_ws%threads(t)%n_arrays = slot
    END DO

    status = 0

  END SUBROUTINE IF_ThreadWS_RegisterArray

  SUBROUTINE IF_ThreadWS_ResetAll(thread_ws, status)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: t

    status = 0

    IF (.NOT. thread_ws%initialized) THEN
      status = -1
      RETURN
    END IF

    DO t = 1, thread_ws%n_threads
      IF (.NOT. thread_ws%threads(t)%initialized) CYCLE
      IF (ALLOCATED(thread_ws%threads(t)%real_arrays_1d)) &
        thread_ws%threads(t)%real_arrays_1d = 0.0_wp
      IF (ALLOCATED(thread_ws%threads(t)%real_arrays_2d)) &
        thread_ws%threads(t)%real_arrays_2d = 0.0_wp
      IF (ALLOCATED(thread_ws%threads(t)%int_arrays_1d)) &
        thread_ws%threads(t)%int_arrays_1d = 0_i4
      IF (ALLOCATED(thread_ws%threads(t)%int_arrays_2d)) &
        thread_ws%threads(t)%int_arrays_2d = 0_i4
      IF (ALLOCATED(thread_ws%threads(t)%logical_arrays_1d)) &
        thread_ws%threads(t)%logical_arrays_1d = .FALSE.
    END DO

    status = 0

  END SUBROUTINE IF_ThreadWS_ResetAll
  
  !====================================================================
  ! Parallel Primitives
  !====================================================================
  
  SUBROUTINE IF_ThreadWS_AtomicAdd(value, increment)
    !! Thread-safe atomic addition (wrapper for OpenMP ATOMIC)
    REAL(wp), INTENT(INOUT) :: value
    REAL(wp), INTENT(IN) :: increment
    
    !$OMP ATOMIC
    value = value + increment
    
  END SUBROUTINE IF_ThreadWS_AtomicAdd
  
  SUBROUTINE IF_ThreadWS_AtomicAddInt(ivalue, increment)
    !! Thread-safe atomic integer addition
    INTEGER(i4), INTENT(INOUT) :: ivalue
    INTEGER(i4), INTENT(IN) :: increment
    
    !$OMP ATOMIC
    ivalue = ivalue + increment
    
  END SUBROUTINE IF_ThreadWS_AtomicAddInt
  
  SUBROUTINE IF_ThreadWS_EnterCritical(lock)
    !! Enter critical section (mutex lock)
    TYPE(ThreadWSCriticalSection), INTENT(INOUT) :: lock
    
    !$OMP CRITICAL(IF_ThreadWS_Critical)
    lock%initialized = .TRUE.
    
  END SUBROUTINE IF_ThreadWS_EnterCritical
  
  SUBROUTINE IF_ThreadWS_ExitCritical(lock)
    !! Exit critical section (mutex unlock)
    TYPE(ThreadWSCriticalSection), INTENT(INOUT) :: lock
    
    !$OMP END CRITICAL(IF_ThreadWS_Critical)
    
  END SUBROUTINE IF_ThreadWS_ExitCritical
  
  !====================================================================
  ! Thread Management Utilities
  !====================================================================
  
  SUBROUTINE IF_ThreadWS_SetCurrentThread(thread_ws, thread_id, status)
    !! Set current thread ID (called automatically in OpenMP parallel regions)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(IN) :: thread_id
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    
    IF (.NOT. thread_ws%initialized) THEN
      status = -1
      RETURN
    END IF
    
    IF (thread_id < 1 .OR. thread_id > thread_ws%n_threads) THEN
      status = -2
      RETURN
    END IF
    
    thread_ws%current_thread_id = thread_id
    
  END SUBROUTINE IF_ThreadWS_SetCurrentThread
  
  FUNCTION IF_ThreadWS_GetCurrentThread(thread_ws, status) RESULT(thread_id)
    !! Get current thread ID
    TYPE(ThreadWS), INTENT(IN) :: thread_ws
    INTEGER(i4), INTENT(OUT) :: status
    INTEGER(i4) :: thread_id
    
    status = 0
    
    IF (.NOT. thread_ws%initialized) THEN
      status = -1
      thread_id = 0
      RETURN
    END IF
    
    thread_id = thread_ws%current_thread_id
    
  END FUNCTION IF_ThreadWS_GetCurrentThread
  
  !====================================================================
  ! Helper Functions
  !====================================================================
  
  FUNCTION ITOCHAR(i) RESULT(str)
    !! Convert integer to string
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(LEN=8) :: str
    WRITE(str, '(I8)') i
    
  END FUNCTION ITOCHAR
  
END MODULE IF_ThreadWS_Mgr