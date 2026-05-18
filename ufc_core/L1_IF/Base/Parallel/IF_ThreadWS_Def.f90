!===============================================================================
! MODULE: IF_ThreadWS_Def
! LAYER:  L1_IF
! DOMAIN: Parallel
! ROLE:   Def — thread workspace TYPEs and constants
! BRIEF:  ThreadWorkspace / ThreadWS / ArrayInfo; MAX_THREADS, MAX_ARRAYS.
!         3-level memory model: Global Pool -> Thread Slice -> Local Arrays.
!===============================================================================
MODULE IF_ThreadWS_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: ThreadWS, ThreadWorkspace, ThreadWS_ArrayInfo
  PUBLIC :: MAX_THREADS, MAX_ARRAYS_PER_THREAD, MAX_ARRAY_NAME_LEN
  
  !> Maximum number of threads supported
  INTEGER(i4), PARAMETER :: MAX_THREADS = 64
  
  !> Maximum number of arrays per thread workspace
  INTEGER(i4), PARAMETER :: MAX_ARRAYS_PER_THREAD = 32
  
  !> Maximum length of array name identifier
  INTEGER(i4), PARAMETER :: MAX_ARRAY_NAME_LEN = 64
  
  !> Array metadata for dynamic workspace allocation
  TYPE :: ThreadWS_ArrayInfo
    CHARACTER(LEN=MAX_ARRAY_NAME_LEN) :: name = ''
    INTEGER(i4) :: array_type = 0       ! 1=REAL(wp), 2=INTEGER(i4), 3=LOGICAL
    INTEGER(i4) :: array_rank = 0       ! 1 or 2
    INTEGER(i4) :: size1 = 0            ! First dimension size
    INTEGER(i4) :: size2 = 0            ! Second dimension size (for rank=2)
    LOGICAL :: allocated = .FALSE.
  END TYPE ThreadWS_ArrayInfo
  
  !> Per-thread private workspace
  TYPE :: ThreadWorkspace
    INTEGER(i4) :: thread_id = 0
    LOGICAL :: initialized = .FALSE.
    
    ! Real arrays (1D and 2D)
    REAL(wp), ALLOCATABLE :: real_arrays_1d(:,:)
    REAL(wp), ALLOCATABLE :: real_arrays_2d(:,:,:)
    
    ! Integer arrays (1D and 2D)
    INTEGER(i4), ALLOCATABLE :: int_arrays_1d(:,:)
    INTEGER(i4), ALLOCATABLE :: int_arrays_2d(:,:,:)
    
    ! Logical arrays (1D only)
    LOGICAL, ALLOCATABLE :: logical_arrays_1d(:,:)
    
    ! Array metadata registry
    TYPE(ThreadWS_ArrayInfo) :: array_info(MAX_ARRAYS_PER_THREAD)
    INTEGER(i4) :: n_arrays = 0
    
  CONTAINS
    PROCEDURE, PASS(this) :: Initialize => ThreadWS_InitializeWorkspace
    PROCEDURE, PASS(this) :: Destroy => ThreadWS_DestroyWorkspace
    PROCEDURE, PASS(this) :: GetReal1D => ThreadWS_GetReal1D
    PROCEDURE, PASS(this) :: GetReal2D => ThreadWS_GetReal2D
    PROCEDURE, PASS(this) :: GetInt1D => ThreadWS_GetInt1D
    PROCEDURE, PASS(this) :: GetInt2D => ThreadWS_GetInt2D
    PROCEDURE, PASS(this) :: HasArray => ThreadWS_HasArray
  END TYPE ThreadWorkspace
  
  !> Global thread workspace manager
  TYPE :: ThreadWS
    INTEGER(i4) :: n_threads = 1
    INTEGER(i4) :: current_thread_id = 0
    LOGICAL :: initialized = .FALSE.
    TYPE(ThreadWorkspace) :: threads(MAX_THREADS)
  END TYPE ThreadWS
  
CONTAINS

  !====================================================================
  ! Type-bound procedures implementation
  !====================================================================
  
  SUBROUTINE ThreadWS_InitializeWorkspace(this, thread_id, n_real_1d, n_real_2d, &
                                          n_int_1d, n_int_2d, n_logical_1d, &
                                          max_size_1d, max_size_2d, status)
    !! Initialize thread workspace with pre-allocated arrays
    CLASS(ThreadWorkspace), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: thread_id
    INTEGER(i4), INTENT(IN) :: n_real_1d, n_real_2d
    INTEGER(i4), INTENT(IN) :: n_int_1d, n_int_2d, n_logical_1d
    INTEGER(i4), INTENT(IN) :: max_size_1d, max_size_2d
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    status = 0
    this%thread_id = thread_id
    
    ! Allocate real arrays
    IF (n_real_1d > 0 .AND. max_size_1d > 0) THEN
      ALLOCATE(this%real_arrays_1d(max_size_1d, n_real_1d), STAT=status)
      IF (status /= 0) RETURN
      this%real_arrays_1d = 0.0_wp
    END IF
    
    IF (n_real_2d > 0 .AND. max_size_2d > 0) THEN
      ALLOCATE(this%real_arrays_2d(max_size_2d, max_size_2d, n_real_2d), STAT=status)
      IF (status /= 0) RETURN
      this%real_arrays_2d = 0.0_wp
    END IF
    
    ! Allocate integer arrays
    IF (n_int_1d > 0 .AND. max_size_1d > 0) THEN
      ALLOCATE(this%int_arrays_1d(max_size_1d, n_int_1d), STAT=status)
      IF (status /= 0) RETURN
      this%int_arrays_1d = 0_i4
    END IF
    
    IF (n_int_2d > 0 .AND. max_size_2d > 0) THEN
      ALLOCATE(this%int_arrays_2d(max_size_2d, max_size_2d, n_int_2d), STAT=status)
      IF (status /= 0) RETURN
      this%int_arrays_2d = 0_i4
    END IF
    
    ! Allocate logical arrays
    IF (n_logical_1d > 0 .AND. max_size_1d > 0) THEN
      ALLOCATE(this%logical_arrays_1d(max_size_1d, n_logical_1d), STAT=status)
      IF (status /= 0) RETURN
      this%logical_arrays_1d = .FALSE.
    END IF
    
    this%n_arrays = n_real_1d + n_real_2d + n_int_1d + n_int_2d + n_logical_1d
    this%initialized = .TRUE.
    
  END SUBROUTINE ThreadWS_InitializeWorkspace
  
  SUBROUTINE ThreadWS_DestroyWorkspace(this)
    !! Deallocate all workspace arrays
    CLASS(ThreadWorkspace), INTENT(INOUT) :: this
    
    IF (ALLOCATED(this%real_arrays_1d)) DEALLOCATE(this%real_arrays_1d)
    IF (ALLOCATED(this%real_arrays_2d)) DEALLOCATE(this%real_arrays_2d)
    IF (ALLOCATED(this%int_arrays_1d)) DEALLOCATE(this%int_arrays_1d)
    IF (ALLOCATED(this%int_arrays_2d)) DEALLOCATE(this%int_arrays_2d)
    IF (ALLOCATED(this%logical_arrays_1d)) DEALLOCATE(this%logical_arrays_1d)
    
    this%initialized = .FALSE.
    this%n_arrays = 0
    
  END SUBROUTINE ThreadWS_DestroyWorkspace
  
  SUBROUTINE ThreadWS_GetReal1D(this, array_index, slice_out, status)
    CLASS(ThreadWorkspace), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: array_index
    REAL(wp), INTENT(OUT) :: slice_out(:)
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: n_copy

    IF (.NOT. this%initialized) THEN
      status = -1
      slice_out = 0.0_wp
      RETURN
    END IF

    IF (.NOT. ALLOCATED(this%real_arrays_1d)) THEN
      status = -3
      slice_out = 0.0_wp
      RETURN
    END IF

    IF (array_index < 1 .OR. array_index > SIZE(this%real_arrays_1d, 2)) THEN
      status = -2
      slice_out = 0.0_wp
      RETURN
    END IF

    n_copy = MIN(SIZE(slice_out), SIZE(this%real_arrays_1d, 1))
    slice_out(1:n_copy) = this%real_arrays_1d(1:n_copy, array_index)
    status = 0

  END SUBROUTINE ThreadWS_GetReal1D

  SUBROUTINE ThreadWS_GetReal2D(this, array_index, slice_out, status)
    CLASS(ThreadWorkspace), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: array_index
    REAL(wp), INTENT(OUT) :: slice_out(:,:)
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: n1, n2

    IF (.NOT. this%initialized) THEN
      status = -1
      slice_out = 0.0_wp
      RETURN
    END IF

    IF (.NOT. ALLOCATED(this%real_arrays_2d)) THEN
      status = -3
      slice_out = 0.0_wp
      RETURN
    END IF

    IF (array_index < 1 .OR. array_index > SIZE(this%real_arrays_2d, 3)) THEN
      status = -2
      slice_out = 0.0_wp
      RETURN
    END IF

    n1 = MIN(SIZE(slice_out, 1), SIZE(this%real_arrays_2d, 1))
    n2 = MIN(SIZE(slice_out, 2), SIZE(this%real_arrays_2d, 2))
    slice_out(1:n1, 1:n2) = this%real_arrays_2d(1:n1, 1:n2, array_index)
    status = 0

  END SUBROUTINE ThreadWS_GetReal2D

  SUBROUTINE ThreadWS_GetInt1D(this, array_index, slice_out, status)
    CLASS(ThreadWorkspace), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: array_index
    INTEGER(i4), INTENT(OUT) :: slice_out(:)
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: n_copy

    IF (.NOT. this%initialized) THEN
      status = -1
      slice_out = 0_i4
      RETURN
    END IF

    IF (.NOT. ALLOCATED(this%int_arrays_1d)) THEN
      status = -3
      slice_out = 0_i4
      RETURN
    END IF

    IF (array_index < 1 .OR. array_index > SIZE(this%int_arrays_1d, 2)) THEN
      status = -2
      slice_out = 0_i4
      RETURN
    END IF

    n_copy = MIN(SIZE(slice_out), SIZE(this%int_arrays_1d, 1))
    slice_out(1:n_copy) = this%int_arrays_1d(1:n_copy, array_index)
    status = 0

  END SUBROUTINE ThreadWS_GetInt1D

  SUBROUTINE ThreadWS_GetInt2D(this, array_index, slice_out, status)
    CLASS(ThreadWorkspace), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: array_index
    INTEGER(i4), INTENT(OUT) :: slice_out(:,:)
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: n1, n2

    IF (.NOT. this%initialized) THEN
      status = -1
      slice_out = 0_i4
      RETURN
    END IF

    IF (.NOT. ALLOCATED(this%int_arrays_2d)) THEN
      status = -3
      slice_out = 0_i4
      RETURN
    END IF

    IF (array_index < 1 .OR. array_index > SIZE(this%int_arrays_2d, 3)) THEN
      status = -2
      slice_out = 0_i4
      RETURN
    END IF

    n1 = MIN(SIZE(slice_out, 1), SIZE(this%int_arrays_2d, 1))
    n2 = MIN(SIZE(slice_out, 2), SIZE(this%int_arrays_2d, 2))
    slice_out(1:n1, 1:n2) = this%int_arrays_2d(1:n1, 1:n2, array_index)
    status = 0

  END SUBROUTINE ThreadWS_GetInt2D
  
  FUNCTION ThreadWS_HasArray(this, array_name, status) RESULT(has_array)
    !! Check if array with given name exists in workspace
    CLASS(ThreadWorkspace), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: array_name
    INTEGER(i4), INTENT(OUT) :: status
    LOGICAL :: has_array
    
    INTEGER(i4) :: i
    
    has_array = .FALSE.
    status = 0
    
    DO i = 1, this%n_arrays
      IF (TRIM(this%array_info(i)%name) == TRIM(array_name)) THEN
        has_array = .TRUE.
        RETURN
      END IF
    END DO
    
  END FUNCTION ThreadWS_HasArray
  
END MODULE IF_ThreadWS_Def
