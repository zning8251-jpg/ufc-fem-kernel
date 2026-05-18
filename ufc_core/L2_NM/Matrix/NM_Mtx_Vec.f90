!===============================================================================
! MODULE: NM_Mtx_Vec
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Core — BLAS Level-1 vector operations, norms, statistics, utilities
! BRIEF:  Vector ops (axpy, scal, copy, dot, nrm2), norms, statistics, fill
!===============================================================================

MODULE NM_Mtx_Vec
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! BLAS Level 1 Operations
  !=============================================================================
  PUBLIC :: NM_Vec_Copy       ! y = x
  PUBLIC :: NM_Vec_Swap       ! x <-> y
  PUBLIC :: NM_Vec_Scal       ! x = alpha * x
  PUBLIC :: NM_Vec_Axpy       ! y = alpha * x + y
  PUBLIC :: NM_Vec_Dot        ! dot = x^T * y
  PUBLIC :: NM_Vec_Nrm2       ! nrm2 = ||x||_2
  PUBLIC :: NM_Vec_Asum       ! asum = ||x||_1
  PUBLIC :: NM_Vec_Iamax      ! iamax = index of max|x_i|

  !=============================================================================
  ! Extended Vector Operations
  !=============================================================================
  PUBLIC :: NM_Vec_Add        ! z = x + y
  PUBLIC :: NM_Vec_Sub        ! z = x - y
  PUBLIC :: NM_Vec_Mul        ! z = x .* y (element-wise)
  PUBLIC :: NM_Vec_Div        ! z = x ./ y (element-wise)
  PUBLIC :: NM_Vec_NormInf    ! norm_inf = ||x||_inf
  PUBLIC :: NM_Vec_Normalize  ! x = x / ||x||_2

  !=============================================================================
  ! Vector Utilities (incl. merged from NM_Vec_Ops_Core, NM_VectorOperations)
  !=============================================================================
  PUBLIC :: NM_Vec_CrossProduct  ! cross = a x b (3D only)
  PUBLIC :: NM_Vec_Diff          ! max |x_i - y_i|
  PUBLIC :: NM_Vec_Fill       ! x = value
  PUBLIC :: NM_Vec_Invert     ! x = -x
  PUBLIC :: NM_Vec_Zero       ! x = 0
  PUBLIC :: NM_Vec_Linspace   ! x = linspace(start, end, n)
  PUBLIC :: NM_Vec_Sum        ! sum = sum(x)
  PUBLIC :: NM_Vec_Mean       ! mean = sum(x) / n
  PUBLIC :: NM_Vec_Variance   ! var = sum((x - mean)^2) / n
  PUBLIC :: NM_Vec_Min        ! min_val = min(x)
  PUBLIC :: NM_Vec_Max        ! max_val = max(x)

  !=============================================================================
  ! SIO Arg Bundle Structures (Principle #14: 5-tuple with [IN]/[OUT])
  !=============================================================================

  !--------------------------------------------------------------------
  ! Vec_Add_Arg: z = x + y
  !--------------------------------------------------------------------
  TYPE :: Vec_Add_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - First input vector
    !> [IN]  y   - Second input vector
    !> [OUT] z   - Output vector (x + y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Add_Arg

  !--------------------------------------------------------------------
  ! Vec_Axpy_Arg: y = alpha * x + y
  !--------------------------------------------------------------------
  TYPE :: Vec_Axpy_Arg
    !> [IN]  n     - Vector dimension
    !> [IN]  alpha - Scalar multiplier
    !> [IN]  x     - Input vector
    !> [INOUT] y   - Output vector (alpha*x + y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: alpha
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Axpy_Arg

  !--------------------------------------------------------------------
  ! Vec_Copy_Arg: y = x
  !--------------------------------------------------------------------
  TYPE :: Vec_Copy_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - Input vector
    !> [OUT] y   - Output vector (copy of x)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Copy_Arg

  !--------------------------------------------------------------------
  ! Vec_Div_Arg: z = x ./ y (element-wise divide)
  !--------------------------------------------------------------------
  TYPE :: Vec_Div_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - Numerator vector
    !> [IN]  y   - Denominator vector
    !> [OUT] z   - Output vector (x / y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Div_Arg

  !--------------------------------------------------------------------
  ! Vec_Fill_Arg: x = value
  !--------------------------------------------------------------------
  TYPE :: Vec_Fill_Arg
    !> [IN]  n     - Vector dimension
    !> [IN]  value - Fill value
    !> [OUT] x     - Output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: value
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Fill_Arg

  !--------------------------------------------------------------------
  ! Vec_Scal_Arg: x = alpha * x
  !--------------------------------------------------------------------
  TYPE :: Vec_Scal_Arg
    !> [IN]  n     - Vector dimension
    !> [IN]  alpha - Scalar multiplier
    !> [INOUT] x   - Input/output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: alpha
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Scal_Arg

  !--------------------------------------------------------------------
  ! Vec_Sub_Arg: z = x - y
  !--------------------------------------------------------------------
  TYPE :: Vec_Sub_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - First input vector
    !> [IN]  y   - Second input vector
    !> [OUT] z   - Output vector (x - y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Sub_Arg

  !--------------------------------------------------------------------
  ! Vec_Swap_Arg: x <-> y
  !--------------------------------------------------------------------
  TYPE :: Vec_Swap_Arg
    !> [IN]  n   - Vector dimension
    !> [INOUT] x  - First vector (swapped with y)
    !> [INOUT] y  - Second vector (swapped with x)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Swap_Arg

  !--------------------------------------------------------------------
  ! Vec_Normalize_Arg: x = x / ||x||_2
  !--------------------------------------------------------------------
  TYPE :: Vec_Normalize_Arg
    !> [IN]  n   - Vector dimension
    !> [INOUT] x - Input/output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Normalize_Arg

  !--------------------------------------------------------------------
  ! Vec_Invert_Arg: x = -x
  !--------------------------------------------------------------------
  TYPE :: Vec_Invert_Arg
    !> [IN]  n   - Vector dimension
    !> [INOUT] x - Input/output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Invert_Arg

  !--------------------------------------------------------------------
  ! Vec_Zero_Arg: x = 0
  !--------------------------------------------------------------------
  TYPE :: Vec_Zero_Arg
    !> [IN]  n   - Vector dimension
    !> [OUT] x   - Output vector (zeroed)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Zero_Arg

  !--------------------------------------------------------------------
  ! Vec_Linspace_Arg: x = linspace(start, end, n)
  !--------------------------------------------------------------------
  TYPE :: Vec_Linspace_Arg
    !> [IN]  n       - Vector dimension
    !> [IN]  x_start - Start value
    !> [IN]  x_end   - End value
    !> [OUT] x       - Output vector
    !> [OUT] status  - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: x_start
    REAL(wp)                :: x_end
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Linspace_Arg

  !--------------------------------------------------------------------
  ! Vec_Mul_Arg: z = x .* y (element-wise multiply)
  !--------------------------------------------------------------------
  TYPE :: Vec_Mul_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - First input vector
    !> [IN]  y   - Second input vector
    !> [OUT] z   - Output vector (x * y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Mul_Arg

CONTAINS

  !=============================================================================
  ! SIO-Compliant Procedure Wrappers
  !=============================================================================

  !--------------------------------------------------------------------
  ! NM_Vec_Add_Proc: z = x + y (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Add_Proc(arg)
    TYPE(Vec_Add_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%z = arg%x + arg%y
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Add_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Axpy_Proc: y = alpha * x + y (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Axpy_Proc(arg)
    TYPE(Vec_Axpy_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%y = arg%alpha * arg%x + arg%y
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Axpy_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Copy_Proc: y = x (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Copy_Proc(arg)
    TYPE(Vec_Copy_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%y = arg%x
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Copy_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Div_Proc: z = x ./ y (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Div_Proc(arg)
    TYPE(Vec_Div_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    DO i = 1, arg%n
      IF (ABS(arg%y(i)) < EPSILON(1.0_wp)) THEN
        arg%status%status_code = IF_STATUS_INVALID
        arg%status%message = "Division by zero"
        RETURN
      END IF
      arg%z(i) = arg%x(i) / arg%y(i)
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Div_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Fill_Proc: x = value (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Fill_Proc(arg)
    TYPE(Vec_Fill_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%x = arg%value
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Fill_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Scal_Proc: x = alpha * x (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Scal_Proc(arg)
    TYPE(Vec_Scal_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%x = arg%alpha * arg%x
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Scal_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Sub_Proc: z = x - y (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Sub_Proc(arg)
    TYPE(Vec_Sub_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%z = arg%x - arg%y
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Sub_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Swap_Proc: x <-> y (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Swap_Proc(arg)
    TYPE(Vec_Swap_Arg), INTENT(INOUT) :: arg
    REAL(wp), ALLOCATABLE :: temp(:)
    CALL init_error_status(arg%status)
    ALLOCATE(temp(arg%n))
    temp = arg%x
    arg%x = arg%y
    arg%y = temp
    DEALLOCATE(temp)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Swap_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Normalize_Proc: x = x / ||x||_2 (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Normalize_Proc(arg)
    TYPE(Vec_Normalize_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: norm
    CALL init_error_status(arg%status)
    norm = SQRT(DOT_PRODUCT(arg%x, arg%x))
    IF (norm < EPSILON(1.0_wp)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Cannot normalize zero vector"
      RETURN
    END IF
    arg%x = arg%x / norm
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Normalize_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Invert_Proc: x = -x (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Invert_Proc(arg)
    TYPE(Vec_Invert_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%x = -arg%x
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Invert_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Zero_Proc: x = 0 (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Zero_Proc(arg)
    TYPE(Vec_Zero_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%x = 0.0_wp
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Zero_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Linspace_Proc: x = linspace(start, end, n) (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Linspace_Proc(arg)
    TYPE(Vec_Linspace_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    REAL(wp) :: dx
    CALL init_error_status(arg%status)
    IF (arg%n <= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "n must be positive"
      RETURN
    END IF
    IF (arg%n == 1) THEN
      arg%x(1) = arg%x_start
    ELSE
      dx = (arg%x_end - arg%x_start) / REAL(arg%n - 1, wp)
      DO i = 1, arg%n
        arg%x(i) = arg%x_start + REAL(i - 1, wp) * dx
      END DO
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Linspace_Proc

  !--------------------------------------------------------------------
  ! NM_Vec_Mul_Proc: z = x .* y (SIO wrapper)
  !--------------------------------------------------------------------
  SUBROUTINE NM_Vec_Mul_Proc(arg)
    TYPE(Vec_Mul_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%z = arg%x * arg%y
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Mul_Proc

  !=============================================================================
  ! Original Subroutines (INTENT-based, kept for backward compatibility)
  !=============================================================================

  SUBROUTINE NM_Vec_Add(n, x, y, z, status)
    !> [IN]  n - Vector dimension
    !> [IN]  x - First input vector
    !> [IN]  y - Second input vector
    !> [OUT] z - Output vector (x + y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n), y(n)
    REAL(wp), INTENT(OUT) :: z(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    z = x + y
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Add

  FUNCTION NM_Vec_Asum(n, x) RESULT(asum)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] asum - ||x||_1 (sum of absolute values)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: asum

    asum = SUM(ABS(x))
  END FUNCTION NM_Vec_Asum

  SUBROUTINE NM_Vec_Axpy(n, alpha, x, y, status)
    !> [IN]    n     - Vector dimension
    !> [IN]    alpha - Scalar multiplier
    !> [IN]    x     - Input vector
    !> [INOUT] y     - Output vector (alpha*x + y)
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alpha
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp), INTENT(INOUT) :: y(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    y = alpha * x + y
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Axpy

  SUBROUTINE NM_Vec_Copy(n, x, y, status)
    !> [IN]  n - Vector dimension
    !> [IN]  x - Input vector
    !> [OUT] y - Output vector (copy of x)
    !> [OUT] status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp), INTENT(OUT) :: y(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    y = x
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Copy

  SUBROUTINE NM_Vec_Div(n, x, y, z, status)
    !> [IN]  n - Vector dimension
    !> [IN]  x - Numerator vector
    !> [IN]  y - Denominator vector
    !> [OUT] z - Output vector (x / y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n), y(n)
    REAL(wp), INTENT(OUT) :: z(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i

    IF (PRESENT(status)) CALL init_error_status(status)

    DO i = 1, n
      IF (ABS(y(i)) < EPSILON(1.0_wp)) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "Division by zero"
        END IF
        RETURN
      END IF
      z(i) = x(i) / y(i)
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Div

  FUNCTION NM_Vec_Dot(n, x, y) RESULT(res)
    !> [IN] n - Vector dimension
    !> [IN] x - First input vector
    !> [IN] y - Second input vector
    !> [OUT] res - Dot product x^T * y
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n), y(n)
    REAL(wp) :: res
    res = DOT_PRODUCT(x, y)
  END FUNCTION NM_Vec_Dot

  FUNCTION NM_Vec_CrossProduct(a, b) RESULT(cross)
    !> [IN] a - First 3D vector
    !> [IN] b - Second 3D vector
    !> [OUT] cross - Cross product a x b
    REAL(wp), INTENT(IN) :: a(3), b(3)
    REAL(wp) :: cross(3)
    cross(1) = a(2) * b(3) - a(3) * b(2)
    cross(2) = a(3) * b(1) - a(1) * b(3)
    cross(3) = a(1) * b(2) - a(2) * b(1)
  END FUNCTION NM_Vec_CrossProduct

  FUNCTION NM_Vec_Diff(n, x, y) RESULT(diff)
    !> [IN] n - Vector dimension
    !> [IN] x - First input vector
    !> [IN] y - Second input vector
    !> [OUT] diff - max|x_i - y_i|
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n), y(n)
    REAL(wp) :: diff
    IF (n <= 0) THEN
      diff = 0.0_wp
    ELSE
      diff = MAXVAL(ABS(x - y))
    END IF
  END FUNCTION NM_Vec_Diff

  SUBROUTINE NM_Vec_Fill(n, value, x, status)
    !> [IN]    n     - Vector dimension
    !> [IN]    value - Fill value
    !> [OUT]   x     - Output vector
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: value
    REAL(wp), INTENT(OUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    x = value
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Fill

  FUNCTION NM_Vec_Iamax(n, x) RESULT(imax)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] imax - Index of max|x_i|
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    INTEGER(i4) :: imax

    imax = MAXLOC(ABS(x), DIM=1)
  END FUNCTION NM_Vec_Iamax

  SUBROUTINE NM_Vec_Invert(n, x, status)
    !> [IN]    n - Vector dimension
    !> [INOUT] x - Input/output vector
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(INOUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    x = -x
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Invert

  SUBROUTINE NM_Vec_Linspace(n, x_start, x_end, x, status)
    !> [IN]    n       - Vector dimension
    !> [IN]    x_start - Start value
    !> [IN]    x_end   - End value
    !> [OUT]   x       - Output vector
    !> [OUT]   status  - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x_start, x_end
    REAL(wp), INTENT(OUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i
    REAL(wp) :: dx

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (n <= 0) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "n must be positive"
      END IF
      RETURN
    END IF

    IF (n == 1) THEN
      x(1) = x_start
    ELSE
      dx = (x_end - x_start) / REAL(n - 1, wp)
      DO i = 1, n
        x(i) = x_start + REAL(i - 1, wp) * dx
      END DO
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Linspace

  FUNCTION NM_Vec_Max(n, x) RESULT(max_val)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] max_val - max(x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: max_val

    max_val = MAXVAL(x)
  END FUNCTION NM_Vec_Max

  FUNCTION NM_Vec_Mean(n, x) RESULT(mean_val)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] mean_val - sum(x) / n
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: mean_val

    IF (n > 0) THEN
      mean_val = SUM(x) / REAL(n, wp)
    ELSE
      mean_val = 0.0_wp
    END IF
  END FUNCTION NM_Vec_Mean

  FUNCTION NM_Vec_Min(n, x) RESULT(min_val)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] min_val - min(x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: min_val

    min_val = MINVAL(x)
  END FUNCTION NM_Vec_Min

  SUBROUTINE NM_Vec_Mul(n, x, y, z, status)
    !> [IN]  n - Vector dimension
    !> [IN]  x - First input vector
    !> [IN]  y - Second input vector
    !> [OUT] z - Output vector (x * y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n), y(n)
    REAL(wp), INTENT(OUT) :: z(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    z = x * y
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Mul

  SUBROUTINE NM_Vec_Normalize(n, x, status)
    !> [IN]    n - Vector dimension
    !> [INOUT] x - Input/output vector
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(INOUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    REAL(wp) :: norm

    IF (PRESENT(status)) CALL init_error_status(status)

    norm = SQRT(DOT_PRODUCT(x, x))

    IF (norm < EPSILON(1.0_wp)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Cannot normalize zero vector"
      END IF
      RETURN
    END IF

    x = x / norm
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Normalize

  FUNCTION NM_Vec_NormInf(n, x) RESULT(norm_inf)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] norm_inf - ||x||_inf
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: norm_inf

    norm_inf = MAXVAL(ABS(x))
  END FUNCTION NM_Vec_NormInf

  FUNCTION NM_Vec_Nrm2(n, x) RESULT(norm2)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] norm2 - ||x||_2
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: norm2

    norm2 = SQRT(DOT_PRODUCT(x, x))
  END FUNCTION NM_Vec_Nrm2

  SUBROUTINE NM_Vec_Scal(n, alpha, x, status)
    !> [IN]    n     - Vector dimension
    !> [IN]    alpha - Scalar multiplier
    !> [INOUT] x     - Input/output vector
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alpha
    REAL(wp), INTENT(INOUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    x = alpha * x
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Scal

  SUBROUTINE NM_Vec_Sub(n, x, y, z, status)
    !> [IN]  n - Vector dimension
    !> [IN]  x - First input vector
    !> [IN]  y - Second input vector
    !> [OUT] z - Output vector (x - y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n), y(n)
    REAL(wp), INTENT(OUT) :: z(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    z = x - y
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Sub

  FUNCTION NM_Vec_Sum(n, x) RESULT(sum_val)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] sum_val - sum(x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: sum_val

    sum_val = SUM(x)
  END FUNCTION NM_Vec_Sum

  SUBROUTINE NM_Vec_Swap(n, x, y, status)
    !> [IN]    n - Vector dimension
    !> [INOUT] x - First vector (swapped with y)
    !> [INOUT] y - Second vector (swapped with x)
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(INOUT) :: x(n), y(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    REAL(wp) :: temp(n)

    IF (PRESENT(status)) CALL init_error_status(status)
    temp = x
    x = y
    y = temp
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Swap

  SUBROUTINE NM_Vec_Zero(n, x, status)
    !> [IN]    n - Vector dimension
    !> [OUT]   x - Output vector (zeroed)
    !> [OUT]   status - Error status (optional)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(OUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    x = 0.0_wp
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Vec_Zero

  FUNCTION NM_Vec_Variance(n, x) RESULT(variance)
    !> [IN] n - Vector dimension
    !> [IN] x - Input vector
    !> [OUT] variance - sum((x - mean)^2) / n
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp) :: variance

    REAL(wp) :: mean_val

    IF (n > 0) THEN
      mean_val = SUM(x) / REAL(n, wp)
      variance = SUM((x - mean_val)**2) / REAL(n, wp)
    ELSE
      variance = 0.0_wp
    END IF
  END FUNCTION NM_Vec_Variance

END MODULE NM_Mtx_Vec