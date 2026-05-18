!===============================================================================
! MODULE:  MD_Base_MathUtils
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Impl (mathematical utilities)
! BRIEF:   Math and core utilities: string ops, array ops, timing, vector/matrix
!          operations, Gauss quadrature, root finding, interpolation.
!===============================================================================
!   Unified mathematical utilities and core utilities module for model definition layer.
!   Merged from Utils_Core (constants, strings, arrays, Timer, Stopwatch, smart_allocate)
!   and Math_Mgr (vec_*, mat_*, gauss_*, newton_*, interp_line, Array_Append_*).
!   Provides string utilities, array operations, timing utilities, date/time utilities,
!   vector/matrix operations, Gauss quadrature, root finding algorithms, interpolation,
!   and smart memory allocation with growth strategies.
!
! Theory chain:
!   String utilities: Case conversion (ToUpper/ToLower), trimming, splitting/joining,
!   string-to-number conversion, pattern matching. Array utilities: Sorting (insertion
!   sort for small arrays), uniqueness, finding, counting, statistics (sum, mean, stddev,
!   min, max). Timing utilities: Timer (single measurement), Stopwatch (multiple laps,
!   accumulated time). Date/Time utilities: Date arithmetic, validation, string conversion.
!   Vector operations: Dot product, norm, scaling, axpy, addition/subtraction, cross product.
!   Matrix operations: Matrix-vector product, matrix-matrix product, transpose, 3x3 inverse.
!   Gauss quadrature: Numerical integration points and weights for line, triangle, quad,
!   tetrahedron, hexahedron, prism, pyramid. Root finding: Newton-Raphson, bisection, secant,
!   Newton system, Gauss-Seidel, Jacobi iteration. Interpolation: Linear, Lagrange, cubic spline.
!   Smart allocation: Growth factor strategy (1.5x default), predictive pre-allocation with
!   caching, adaptive growth factor based on utilization. Ref: Numerical methods, linear
!   algebra, numerical integration, root finding algorithms, interpolation theory.
!
! Logic chain:
!   String utilities: ToUpper/ToLower (case conversion) -> TrimStr (trimming) -> SplitStr/
!   JoinStr (splitting/joining) -> StrToInt/StrToReal/IntToStr/RealToStr (conversion) ->
!   StrContains/StrStartsWith/StrEndsWith/StrReplace (pattern matching). Array utilities:
!   SortInt/SortReal (sorting) -> UniqueInt/UniqueReal (uniqueness) -> FindInt/FindReal
!   (finding) -> CountInt/CountReal (counting) -> SumInt/SumReal/MeanReal/StdDevReal/MinInt/
!   MinReal/MaxInt/MaxReal (statistics). Timer: Start -> Stop -> GetElapsedTime/GetElapsedSeconds.
!   Stopwatch: Start -> Lap/Stop -> GetTotalTime/GetLapTime/GetLapCount/GetAverageLapTime.
!   Date/Time: Init/Set -> AddDays/AddMonths/AddYears/AddSeconds/AddMinutes/AddHours ->
!   ToString/FromString. Vector operations: vec_dot, vec_norm2, vec_scale, vec_axpy, vec_add,
!   vec_sub, vec_cross_3d. Matrix operations: mat_vec, mat_mat, mat_trans, mat_inv_3x3.
!   Gauss quadrature: gauss_line, gauss_triangle, gauss_quad, gauss_tetrahedron, gauss_hexahedron,
!   gauss_prism, gauss_pyramid. Root finding: newton_raphson, bisection, secant, newton_system,
!   gauss_seidel, jacobi_iter. Interpolation: interp_line, lagrange_interp, spline_interp.
!   Smart allocation: smart_allocate (1D/2D real/int) -> smart_grow_* (aliases) -> cache_array_size
!   -> get_cached_size -> predictive_preallocate_real1d -> adaptive_growth_factor. Dependency:
!   L3_MD Base -> L1 IF (Error API, Precision).
!
! Computation chain:
!   ToUpper: Loop through string -> Convert lowercase to uppercase using ASCII arithmetic.
!   SortInt: Insertion sort -> O(n^2) worst case, O(n) best case. UniqueInt: Sort array ->
!   Remove consecutive duplicates. FindInt: Linear search -> Return index or 0. SumInt:
!   Sum array elements. Timer_Start: SYSTEM_CLOCK(start_time) -> Set running flag. Timer_Stop:
!   SYSTEM_CLOCK(end_time) -> Calculate elapsed_time -> Clear running flag. Date_AddDays:
!   Add days -> Handle month/year overflow using DaysInMonth. vec_dot: dot_product(a, b).
!   vec_norm2: sqrt(dot_product(a, a)). mat_inv_3x3: Calculate determinant -> Compute inverse
!   using Cramer's rule. gauss_line: Select case (n) -> Set Gauss points and weights for n=1,2,3.
!   gauss_quad: Call gauss_line -> Form tensor product (n*n points). newton_raphson: Iterate
!   x = x - f(x)/df(x) until convergence. bisection: Iteratively bisect interval until convergence.
!   interp_line: Find interval -> Linear interpolation. spline_interp: Build cubic spline
!   coefficients -> Evaluate spline. smart_allocate: Check if allocated -> If not, allocate ->
!   If size insufficient, grow by factor (default 1.5x) -> Use MOVE_ALLOC for efficiency.
!   cache_array_size: Find entry in cache -> Update or add new entry -> LRU replacement if full.
!
! Data chain:
!   Input: String (for string utilities), arrays (for array utilities), timer/stopwatch
!   objects, date/time objects, vectors/matrices, Gauss quadrature parameters (n, element_type),
!   root finding parameters (x0, tol, max_iter), interpolation data (x_data, y_data, x),
!   allocation parameters (required_size, growth_factor). Output: Converted strings, sorted/
!   unique arrays, statistics (sum, mean, stddev, min, max), elapsed time, date/time objects,
!   vector/matrix results, Gauss points/weights, root finding results (x, converged),
!   interpolated values (y, dy, d2y), allocated arrays. State: Timer state (start_time,
!   end_time, elapsed_time, running), Stopwatch state (total_time, lap_time, start_time,
!   lap_count, running), Date/Time state (year, month, day, hour, minute, second, millisecond),
!   GaussQuadrature state (npts, dim, points, weights, init), VecOps state (size, init),
!   array size cache state (cached_size, access_count, growth_factor).
!
! Data structure:
!   Container path: Base (mathematical utilities).
!   - Desc: Timer (timer descriptor), Stopwatch (stopwatch descriptor), Date (date descriptor),
!   Time (time descriptor), GaussQuadrature (Gauss quadrature descriptor), VecOps (vector
!   operations descriptor), MathUtils (math utilities descriptor), SparseMatrixUtils (sparse
!   matrix utilities descriptor).
!   - Algo: String algorithms (ToUpper, ToLower, SplitStr, JoinStr), array algorithms (SortInt,
!   SortReal, UniqueInt, UniqueReal), vector algorithms (vec_dot, vec_norm2, vec_scale, vec_axpy),
!   matrix algorithms (mat_vec, mat_mat, mat_trans, mat_inv_3x3), Gauss quadrature algorithms
!   (gauss_line, gauss_triangle, gauss_quad, etc.), root finding algorithms (newton_raphson,
!   bisection, secant, newton_system, gauss_seidel, jacobi_iter), interpolation algorithms
!   (interp_line, lagrange_interp, spline_interp), smart allocation algorithms (smart_allocate,
!   cache_array_size, adaptive_growth_factor).
!   - Ctx: Timer (timing context), Stopwatch (stopwatch context), Date/Time (date/time context),
!   GaussQuadrature (Gauss quadrature context), VecOps (vector operations context), MathUtils
!   (math utilities context), SparseMatrixUtils (sparse matrix utilities context), ArraySizeCache
!   (array size cache context).
!   - State: Timer state (running, elapsed_time), Stopwatch state (running, total_time, lap_count),
!   Date/Time state (year, month, day, hour, minute, second), GaussQuadrature state (init),
!   VecOps state (init), array size cache state (cached_size, access_count).
!   Supporting types: ArraySizeCache (private, for predictive pre-allocation).
!
! Three-step mapping:
!   String/Array utilities: Step level (general utilities, used throughout).
!   Timer/Stopwatch: Step level (performance measurement).
!   Vector/Matrix operations: Step level (element evaluation, matrix operations).
!   Gauss quadrature: Step level (element integration setup).
!   Root finding: Step level (nonlinear solver operations).
!   Interpolation: Step level (data interpolation).
!   Smart allocation: Step level (dynamic array management).
!
! Contents (A-Z):
!   Constants: HALF, ONE, PI, SIXTH, THIRD, THREE, TWO, ZERO
!   Functions: CountInt, CountReal, Date_Difference, Date_IsValid, Date_ToString, DaysInMonth,
!     FindInt, FindReal, GaussQuadrature_GetPoints, GaussQuadrature_GetWeights, IntToStr,
!     JoinStr, MaxInt, MaxReal, MeanReal, MinInt, MinReal, RealToStr, StdDevReal, StrContains,
!     StrEndsWith, StrReplace, StrStartsWith, StrToInt, StrToReal, Stopwatch_GetAverageLapTime,
!     Stopwatch_GetLapCount, Stopwatch_GetLapTime, Stopwatch_GetTotalTime, Stopwatch_IsRunning,
!     SumInt, SumReal, Time_Difference, Time_IsValid, Time_ToString, Timer_GetElapsedSeconds,
!     Timer_GetElapsedTime, Timer_IsRunning, ToLower, ToUpper, TrimStr, VecOps_Cross, VecOps_Dot,
!     VecOps_Norm2
!   Subroutines: adaptive_growth_factor, Array_Append_DP1D, Array_Append_DP2D, Array_Append_Int1D,
!     Array_Append_Int2D, bisection, cache_array_size, Date_AddDays, Date_AddMonths, Date_AddYears,
!     Date_FromString, Date_Get, Date_Init, Date_Set, GaussQuadrature_Destroy, GaussQuadrature_Init,
!     GaussQuadrature_Setup, gauss_hexahedron, gauss_line, gauss_prism, gauss_pyramid, gauss_quad,
!     gauss_seidel, gauss_tetrahedron, gauss_triangle, get_cached_size, interp_line, jacobi_iter,
!     lagrange_interp, mat_inv_3x3, mat_mat, mat_trans, mat_vec, MathUtils_Destroy, MathUtils_Init,
!     newton_raphson, newton_system, predictive_preallocate_real1d, secant, smart_allocate,
!     smart_allocate_int1d, smart_allocate_int2d, smart_grow_int_vector, smart_grow_real_Mtx,
!     smart_grow_real_vector, SortInt, SortReal, spline_interp, SplitStr, Stopwatch_Lap,
!     Stopwatch_Reset, Stopwatch_Start, Stopwatch_Stop, Sparse_MatVec_Wrapper, Time_AddHours,
!     Time_AddMinutes, Time_AddSeconds, Time_FromString, Time_Get, Time_Init, Time_Set,
!     Timer_Reset, Timer_Start, Timer_Stop, UniqueInt, UniqueReal, vec_add, vec_axpy, vec_copy,
!     vec_cross_3d, vec_scale, vec_sub, vec_zero, VecOps_Add, VecOps_Axpy, VecOps_Cross,
!     VecOps_Destroy, VecOps_Init, VecOps_Scale, VecOps_Subtract
!
! Notes:
!   Merged module: Utils_Core + Math_Mgr. String utilities: Case conversion, trimming, splitting,
!   conversion, pattern matching. Array utilities: Sorting (insertion sort for small arrays),
!   uniqueness, finding, counting, statistics. Timer/Stopwatch: Single/multiple timing measurements.
!   Date/Time: Date arithmetic with leap year handling, time arithmetic with overflow handling.
!   Vector operations: BLAS-like operations (dot, norm, scale, axpy, add, sub, cross). Matrix
!   operations: Matrix-vector/matrix-matrix product, transpose, 3x3 inverse (Cramer's rule). Gauss
!   quadrature: Supports line (1-3 points), triangle (1,3 points), quad (n*n points), tetrahedron
!   (1,4,5 points), hexahedron (n*n*n points), prism (n_tri*n_line points), pyramid (n_quad*n_line
!   points). Root finding: Newton-Raphson (single equation), bisection, secant, Newton system (multiple
!   equations), Gauss-Seidel, Jacobi iteration. Interpolation: Linear, Lagrange polynomial, cubic
!   spline. Smart allocation: Growth factor strategy (default 1.5x), predictive pre-allocation with
!   caching (Scheme C), adaptive growth factor based on utilization. Note: predictive_preallocate_real1d
!   subroutine name mismatch (defined as pr_pr_real1d but called as predictive_preallocate_real1d).
!   Logic/Computation chain diagrams: see MD_Base_MathUtils_Core_Chains.md
!
! Status: CORE | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_MathUtils
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                            MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! PUBLIC constants (A-Z)
    PUBLIC :: HALF, ONE, PI, SIX, SIXTH, THIRD, THREE, TWO, ZERO
    REAL(wp), PARAMETER :: ZERO  = 0.0_wp
    REAL(wp), PARAMETER :: ONE   = 1.0_wp
    REAL(wp), PARAMETER :: HALF  = 0.5_wp
    REAL(wp), PARAMETER :: TWO   = 2.0_wp
    REAL(wp), PARAMETER :: THREE = 3.0_wp
    REAL(wp), PARAMETER :: SIX   = 6.0_wp
    REAL(wp), PARAMETER :: THIRD = ONE / 3.0_wp
    REAL(wp), PARAMETER :: SIXTH = ONE / 6.0_wp
    REAL(wp), PARAMETER :: PI    = 3.14159265358979323846_wp

    ! PUBLIC types (A-Z)
    PUBLIC :: Date, GaussQuadrature, MathUtils, SparseMatrixUtils, Stopwatch, Time, Timer, VecOps

    ! PUBLIC procedures (A-Z)
    PUBLIC :: adaptive_growth_factor, Array_Append_DP1D, Array_Append_DP2D, Array_Append_Int1D, Array_Append_Int2D
    PUBLIC :: bisection
    PUBLIC :: cache_array_size, CountInt, CountReal
    PUBLIC :: Date_AddDays, Date_AddMonths, Date_AddYears, Date_FromString, Date_Get, Date_Init, Date_Set
    PUBLIC :: FindInt, FindReal
    PUBLIC :: GaussQuadrature_Destroy, GaussQuadrature_Init, GaussQuadrature_Setup
    PUBLIC :: gauss_hexahedron, gauss_line, gauss_prism, gauss_pyramid, gauss_quad, gauss_seidel
    PUBLIC :: gauss_tetrahedron, gauss_triangle, get_cached_size
    PUBLIC :: interp_line, IntToStr
    PUBLIC :: jacobi_iter, JoinStr
    PUBLIC :: lagrange_interp
    PUBLIC :: mat_inv_3x3, mat_mat, mat_trans, mat_vec, MathUtils_Destroy, MathUtils_Init
    PUBLIC :: MaxInt, MaxReal, MeanReal, MinInt, MinReal
    PUBLIC :: newton_raphson, newton_system
    PUBLIC :: predictive_preallocate_real1d
    PUBLIC :: RealToStr
    PUBLIC :: secant, smart_allocate, smart_allocate_int1d, smart_allocate_int2d
    PUBLIC :: smart_grow_int_vector, smart_grow_real_Mtx, smart_grow_real_vector
    PUBLIC :: SortInt, SortReal, spline_interp, SplitStr
    PUBLIC :: Stopwatch_Lap, Stopwatch_Reset, Stopwatch_Start, Stopwatch_Stop
    PUBLIC :: Sparse_MatVec_Wrapper, StrContains, StrEndsWith, StrReplace, StrStartsWith
    PUBLIC :: StrToInt, StrToReal, SumInt, SumReal, StdDevReal
    PUBLIC :: Time_AddHours, Time_AddMinutes, Time_AddSeconds, Time_FromString, Time_Get, Time_Init, Time_Set
    PUBLIC :: Timer_Reset, Timer_Start, Timer_Stop, ToLower, ToUpper, TrimStr
    PUBLIC :: UniqueInt, UniqueReal
    PUBLIC :: vec_add, vec_axpy, vec_copy, vec_cross_3d, vec_dot, vec_norm2, vec_scale, vec_sub, vec_zero
    PUBLIC :: VecOps_Add, VecOps_Axpy, VecOps_Cross, VecOps_Destroy, VecOps_Init, VecOps_Scale, VecOps_Subtract

    ! ===================================================================
    ! Type Definitions
    ! ===================================================================

    TYPE :: Timer
        INTEGER(i8) :: start_time = 0_i8
        INTEGER(i8) :: end_time = 0_i8
        INTEGER(i8) :: elapsed_time = 0_i8
        LOGICAL :: running = .FALSE.
    CONTAINS
        PROCEDURE :: Start => Timer_Start
        PROCEDURE :: Stop => Timer_Stop
        PROCEDURE :: Reset => Timer_Reset
        PROCEDURE :: IsRunning => Timer_IsRunning
        PROCEDURE :: GetElapsedTime => Timer_GetElapsedTime
        PROCEDURE :: GetElapsedSeconds => Timer_GetElapsedSeconds
    END TYPE Timer

    TYPE :: Stopwatch
        INTEGER(i8) :: total_time = 0_i8    ! Total accumulated time in clock ticks
        INTEGER(i8) :: lap_time = 0_i8      ! Last lap time in clock ticks
        INTEGER(i8) :: start_time = 0_i8    ! Start time for current lap/measurement
        INTEGER(i4) :: lap_count = 0_i4     ! Number of laps recorded
        LOGICAL :: running = .FALSE.        ! Whether stopwatch is currently running
    CONTAINS
        PROCEDURE :: Start => Stopwatch_Start
        PROCEDURE :: Stop => Stopwatch_Stop
        PROCEDURE :: Reset => Stopwatch_Reset
        PROCEDURE :: Lap => Stopwatch_Lap
        PROCEDURE :: IsRunning => Stopwatch_IsRunning
        PROCEDURE :: GetTotalTime => Stopwatch_GetTotalTime
        PROCEDURE :: GetLapTime => Stopwatch_GetLapTime
        PROCEDURE :: GetLapCount => Stopwatch_GetLapCount
        PROCEDURE :: GetAverageLapTime => Stopwatch_GetAverageLapTime
    END TYPE Stopwatch

    TYPE :: Date
        INTEGER(i4) :: year = 0_i4
        INTEGER(i4) :: month = 0_i4
        INTEGER(i4) :: day = 0_i4
    CONTAINS
        PROCEDURE :: Init => Date_Init
        PROCEDURE :: Set => Date_Set
        PROCEDURE :: Get => Date_Get
        PROCEDURE :: IsValid => Date_IsValid
        PROCEDURE :: AddDays => Date_AddDays
        PROCEDURE :: AddMonths => Date_AddMonths
        PROCEDURE :: AddYears => Date_AddYears
        PROCEDURE :: Difference => Date_Difference
        PROCEDURE :: ToString => Date_ToString
        PROCEDURE :: FromString => Date_FromString
    END TYPE Date

    TYPE :: Time
        INTEGER(i4) :: hour = 0_i4
        INTEGER(i4) :: minute = 0_i4
        INTEGER(i4) :: second = 0_i4
        INTEGER(i4) :: millisecond = 0_i4
    CONTAINS
        PROCEDURE :: Init => Time_Init
        PROCEDURE :: Set => Time_Set
        PROCEDURE :: Get => Time_Get
        PROCEDURE :: IsValid => Time_IsValid
        PROCEDURE :: AddSeconds => Time_AddSeconds
        PROCEDURE :: AddMinutes => Time_AddMinutes
        PROCEDURE :: AddHours => Time_AddHours
        PROCEDURE :: Difference => Time_Difference
        PROCEDURE :: ToString => Time_ToString
        PROCEDURE :: FromString => Time_FromString
    END TYPE Time

    ! ===================================================================
    ! Placeholder Types (PRIVATE - not yet implemented)
    ! ===================================================================
    ! These types are placeholders and should be implemented in the future
    ! if string list/tokenization/formatting functionality is needed
    TYPE, PRIVATE :: StringList
        CHARACTER(LEN=256), ALLOCATABLE :: strings(:)
        INTEGER(i4) :: count = 0_i4
    END TYPE StringList

    TYPE, PRIVATE :: StringTokenizer
        CHARACTER(LEN=256) :: str = ""
        CHARACTER(LEN=16) :: delimiter = " "
    END TYPE StringTokenizer

    TYPE, PRIVATE :: StringFormatter
        CHARACTER(LEN=256) :: buffer = ""
    END TYPE StringFormatter

    ! ===================================================================
    ! Math Sys Types (from MD_Math_Mgr)
    ! ===================================================================
    TYPE :: MathUtils
        LOGICAL :: is_initialized = .FALSE.
    CONTAINS
        PROCEDURE :: Init => MathUtils_Init
        PROCEDURE :: Destroy => MathUtils_Destroy
    END TYPE MathUtils

    TYPE :: GaussQuadrature
        INTEGER(i4) :: npts = 1
        INTEGER(i4) :: dim = 1
        CHARACTER(LEN=16) :: element_type = "LINE"
        REAL(wp), ALLOCATABLE :: points(:,:)
        REAL(wp), ALLOCATABLE :: weights(:)
        LOGICAL :: is_initialized = .FALSE.
    CONTAINS
        PROCEDURE :: Init => GaussQuadrature_Init
        PROCEDURE :: Destroy => GaussQuadrature_Destroy
        PROCEDURE :: Setup => GaussQuadrature_Setup
        PROCEDURE :: GetPoints => GaussQuadrature_GetPoints
        PROCEDURE :: GetWeights => GaussQuadrature_GetWeights
    END TYPE GaussQuadrature

    TYPE :: VecOps
        INTEGER(i4) :: size = 0
        LOGICAL :: is_initialized = .FALSE.
    CONTAINS
        PROCEDURE :: Init => VecOps_Init
        PROCEDURE :: Destroy => VecOps_Destroy
        PROCEDURE :: Dot => VecOps_Dot
        PROCEDURE :: Norm2 => VecOps_Norm2
        PROCEDURE :: Scale => VecOps_Scale
        PROCEDURE :: Axpy => VecOps_Axpy
        PROCEDURE :: Add => VecOps_Add
        PROCEDURE :: Subtract => VecOps_Subtract
        PROCEDURE :: Cross => VecOps_Cross
    END TYPE VecOps

    TYPE :: SparseMatrixUtils
        LOGICAL :: is_initialized = .FALSE.
    CONTAINS
        PROCEDURE :: MatVec => Sparse_MatVec_Wrapper
    END TYPE SparseMatrixUtils

    ! ===================================================================
    ! Smart Cache Strategy (Scheme C) - module variables
    ! ===================================================================
    TYPE, PRIVATE :: ArraySizeCache
        CHARACTER(len=64) :: name = ""
        INTEGER(i4) :: cached_size = 0_i4
        INTEGER(i4) :: access_count = 0_i4
        INTEGER(i4) :: last_access_tim = 0_i4
        REAL(wp) :: growth_factor = 1.5_wp
    END TYPE ArraySizeCache

    TYPE(ArraySizeCache), ALLOCATABLE, PRIVATE, SAVE :: size_cache(:)
    INTEGER(i4), PRIVATE, SAVE :: cache_size = 0_i4
    INTEGER(i4), PRIVATE, PARAMETER :: MD_MODEL_MAX_CACHE_SIZE = 100_i4

    ! Generic interface for smart_allocate (1D and 2D real)
    INTERFACE smart_allocate
        MODULE PROCEDURE smart_allocate_1d
        MODULE PROCEDURE smart_allocate_2d
    END INTERFACE smart_allocate

CONTAINS

    ! ===================================================================
    ! String Utilities
    ! ===================================================================
    PURE FUNCTION ToUpper(str) RESULT(out)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=len(str)) :: out
        INTEGER(i4) :: i, ich
        out = str
        DO i = 1, len(str)
            ich = iachar(out(i:i))
            IF (ich >= iachar('a') .AND. ich <= iachar('z')) THEN
                out(i:i) = achar(ich - 32)
            END IF
        END DO
    END FUNCTION ToUpper

    PURE FUNCTION ToLower(str) RESULT(out)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=len(str)) :: out
        INTEGER(i4) :: i, ich
        out = str
        DO i = 1, len(str)
            ich = iachar(out(i:i))
            IF (ich >= iachar('A') .AND. ich <= iachar('Z')) THEN
                out(i:i) = achar(ich + 32)
            END IF
        END DO
    END FUNCTION ToLower

    FUNCTION TrimStr(str) RESULT(out)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=:), ALLOCATABLE :: out
        INTEGER(i4) :: i, j
        i = 1
        DO WHILE (i <= len(str) .AND. str(i:i) == ' ')
            i = i + 1
        END DO
        j = len(str)
        DO WHILE (j >= 1 .AND. str(j:j) == ' ')
            j = j - 1
        END DO
        IF (i > j) THEN
            out = ''
        ELSE
            out = str(i:j)
        END IF
    END FUNCTION TrimStr

    SUBROUTINE SplitStr(str, delimiter, parts, n_parts)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=*), INTENT(IN) :: delimiter
        CHARACTER(LEN=:), ALLOCATABLE, INTENT(OUT) :: parts(:)
        INTEGER(i4), INTENT(OUT) :: n_parts
        INTEGER(i4) :: i, j, k, len_delim
        CHARACTER(LEN=len(str)) :: temp
        len_delim = len(delimiter)
        n_parts = 0
        temp = str
        i = 1
        DO
            j = index(temp(i:), delimiter)
            IF (j == 0) EXIT
            n_parts = n_parts + 1
            i = i + j + len_delim - 1
        END DO
        n_parts = n_parts + 1
        ALLOCATE(character(len(str)) :: parts(n_parts))
        DO i = 1, n_parts
            parts(i) = REPEAT(' ', len(str))
        END DO
        i = 1
        k = 1
        DO
            j = index(temp(i:), delimiter)
            IF (j == 0) THEN
                parts(k) = temp(i:)
                EXIT
            END IF
            parts(k) = temp(i:i+j-2)
            k = k + 1
            i = i + j + len_delim - 1
        END DO
    END SUBROUTINE SplitStr

    FUNCTION JoinStr(parts, delimiter) RESULT(str)
        CHARACTER(LEN=*), INTENT(IN) :: parts(:)
        CHARACTER(LEN=*), INTENT(IN) :: delimiter
        CHARACTER(LEN=:), ALLOCATABLE :: str
        INTEGER(i4) :: i, n, total_len
        n = SIZE(parts)
        total_len = 0
        DO i = 1, n
            total_len = total_len + len_trim(parts(i))
        END DO
        total_len = total_len + (n - 1) * len(delimiter)
        ALLOCATE(CHARACTER(LEN=total_len) :: str)
        str = REPEAT(' ', total_len)
        DO i = 1, n
            IF (i > 1) str = trim(str) // delimiter
            str = trim(str) // trim(parts(i))
        END DO
    END FUNCTION JoinStr

    FUNCTION StrToInt(str, status) RESULT(val)
        CHARACTER(LEN=*), INTENT(IN) :: str
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status
        INTEGER(i4) :: val, ios
        READ(str, *, IOSTAT=ios) val
        IF (PRESENT(status)) status = ios
    END FUNCTION StrToInt

    FUNCTION StrToReal(str, status) RESULT(val)
        CHARACTER(LEN=*), INTENT(IN) :: str
        REAL(wp), INTENT(OUT), OPTIONAL :: status
        REAL(wp) :: val
        INTEGER(i4) :: ios
        READ(str, *, IOSTAT=ios) val
        IF (PRESENT(status)) status = ios
    END FUNCTION StrToReal

    FUNCTION IntToStr(val) RESULT(str)
        INTEGER(i4), INTENT(IN) :: val
        CHARACTER(LEN=20) :: str
        WRITE(str, '(I20)') val
        str = ADJUSTL(str)
    END FUNCTION IntToStr

    FUNCTION RealToStr(val, fmt) RESULT(str)
        REAL(wp), INTENT(IN) :: val
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: fmt
        CHARACTER(LEN=30) :: str
        IF (PRESENT(fmt)) THEN
            WRITE(str, fmt) val
        ELSE
            WRITE(str, '(E15.8)') val
        END IF
        str = ADJUSTL(str)
    END FUNCTION RealToStr

    FUNCTION StrContains(str, substr) RESULT(found)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=*), INTENT(IN) :: substr
        LOGICAL :: found
        found = (index(str, substr) > 0)
    END FUNCTION StrContains

    FUNCTION StrStartsWith(str, prefix) RESULT(found)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=*), INTENT(IN) :: prefix
        LOGICAL :: found
        IF (len(prefix) > len(str)) THEN
            found = .FALSE.
        ELSE
            found = (str(1:len(prefix)) == prefix)
        END IF
    END FUNCTION StrStartsWith

    FUNCTION StrEndsWith(str, suffix) RESULT(found)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=*), INTENT(IN) :: suffix
        LOGICAL :: found
        INTEGER(i4) :: n_str, n_suf
        n_str = len(str)
        n_suf = len(suffix)
        IF (n_suf > n_str) THEN
            found = .FALSE.
        ELSE
            found = (str(n_str-n_suf+1:n_str) == suffix)
        END IF
    END FUNCTION StrEndsWith

    FUNCTION StrReplace(str, old, new) RESULT(result)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=*), INTENT(IN) :: old
        CHARACTER(LEN=*), INTENT(IN) :: new
        CHARACTER(LEN=:), ALLOCATABLE :: result
        INTEGER(i4) :: i, j, len_old, len_new
        len_old = len(old)
        len_new = len(new)
        ALLOCATE(CHARACTER(LEN=len(str)*2) :: result)
        result = REPEAT(' ', len(str)*2)
        i = 1
        j = 1
        DO WHILE (i <= len(str))
            IF (str(i:i+len_old-1) == old) THEN
                result(j:j+len_new-1) = new
                j = j + len_new
                i = i + len_old
            ELSE
                result(j:j) = str(i:i)
                j = j + 1
                i = i + 1
            END IF
        END DO
    END FUNCTION StrReplace

    ! ===================================================================
    ! Timer Procedures
    ! ===================================================================
    SUBROUTINE Timer_Start(this)
        CLASS(Timer), INTENT(INOUT) :: this
        CALL SYSTEM_CLOCK(this%start_time)
        this%running = .TRUE.
    END SUBROUTINE Timer_Start

    SUBROUTINE Timer_Stop(this)
        CLASS(Timer), INTENT(INOUT) :: this
        CALL SYSTEM_CLOCK(this%end_time)
        this%elapsed_time = this%end_time - this%start_time
        this%running = .FALSE.
    END SUBROUTINE Timer_Stop

    SUBROUTINE Timer_Reset(this)
        CLASS(Timer), INTENT(INOUT) :: this
        this%start_time = 0
        this%end_time = 0
        this%elapsed_time = 0
        this%running = .FALSE.
    END SUBROUTINE Timer_Reset

    FUNCTION Timer_IsRunning(this) RESULT(running)
        CLASS(Timer), INTENT(IN) :: this
        LOGICAL :: running
        running = this%running
    END FUNCTION Timer_IsRunning

    FUNCTION Timer_GetElapsedTime(this) RESULT(elapsed)
        CLASS(Timer), INTENT(IN) :: this
        INTEGER(i8) :: elapsed
        INTEGER(i8) :: current_time
        IF (this%running) THEN
            ! Timer is running, calculate current elapsed time
            CALL SYSTEM_CLOCK(current_time)
            elapsed = current_time - this%start_time
        ELSE
            ! Timer is stopped, return stored elapsed time
            elapsed = this%elapsed_time
        END IF
    END FUNCTION Timer_GetElapsedTime

    FUNCTION Timer_GetElapsedSeconds(this) RESULT(seconds)
        CLASS(Timer), INTENT(IN) :: this
        REAL(wp) :: seconds
        INTEGER(i8) :: elapsed, rate
        elapsed = this%GetElapsedTime()
        CALL SYSTEM_CLOCK(COUNT_RATE=rate)
        seconds = REAL(elapsed, wp) / REAL(rate, wp)
    END FUNCTION Timer_GetElapsedSeconds

    ! ===================================================================
    ! Stopwatch Procedures
    ! ===================================================================
    SUBROUTINE Stopwatch_Start(this)
        CLASS(Stopwatch), INTENT(INOUT) :: this
        INTEGER(i8) :: t
        IF (.NOT. this%running) THEN
            CALL SYSTEM_CLOCK(t)
            this%start_time = t
            this%running = .TRUE.
        END IF
    END SUBROUTINE Stopwatch_Start

    SUBROUTINE Stopwatch_Stop(this)
        CLASS(Stopwatch), INTENT(INOUT) :: this
        INTEGER(i8) :: t, elapsed
        IF (this%running) THEN
            CALL SYSTEM_CLOCK(t)
            elapsed = t - this%start_time
            this%total_time = this%total_time + elapsed
            this%running = .FALSE.
        END IF
    END SUBROUTINE Stopwatch_Stop

    SUBROUTINE Stopwatch_Reset(this)
        CLASS(Stopwatch), INTENT(INOUT) :: this
        this%total_time = 0_i8
        this%lap_time = 0_i8
        this%start_time = 0_i8
        this%lap_count = 0_i4
        this%running = .FALSE.
    END SUBROUTINE Stopwatch_Reset

    SUBROUTINE Stopwatch_Lap(this)
        CLASS(Stopwatch), INTENT(INOUT) :: this
        INTEGER(i8) :: t, elapsed
        IF (this%running) THEN
            CALL SYSTEM_CLOCK(t)
            elapsed = t - this%start_time
            this%lap_time = elapsed
            this%total_time = this%total_time + elapsed
            this%lap_count = this%lap_count + 1_i4
            ! Reset start time for next lap
            this%start_time = t
        END IF
    END SUBROUTINE Stopwatch_Lap

    FUNCTION Stopwatch_IsRunning(this) RESULT(running)
        CLASS(Stopwatch), INTENT(IN) :: this
        LOGICAL :: running
        running = this%running
    END FUNCTION Stopwatch_IsRunning

    FUNCTION Stopwatch_GetTotalTime(this) RESULT(total)
        CLASS(Stopwatch), INTENT(IN) :: this
        INTEGER(i8) :: total
        INTEGER(i8) :: t, elapsed
        total = this%total_time
        IF (this%running) THEN
            ! Include current elapsed time if running
            CALL SYSTEM_CLOCK(t)
            elapsed = t - this%start_time
            total = total + elapsed
        END IF
    END FUNCTION Stopwatch_GetTotalTime

    FUNCTION Stopwatch_GetLapTime(this) RESULT(lap)
        CLASS(Stopwatch), INTENT(IN) :: this
        INTEGER(i8) :: lap
        INTEGER(i8) :: t, elapsed
        IF (this%running) THEN
            ! Return current lap time if running
            CALL SYSTEM_CLOCK(t)
            elapsed = t - this%start_time
            lap = elapsed
        ELSE
            ! Return last lap time if stopped
            lap = this%lap_time
        END IF
    END FUNCTION Stopwatch_GetLapTime

    FUNCTION Stopwatch_GetLapCount(this) RESULT(count)
        CLASS(Stopwatch), INTENT(IN) :: this
        INTEGER(i4) :: count
        count = this%lap_count
    END FUNCTION Stopwatch_GetLapCount

    FUNCTION Stopwatch_GetAverageLapTime(this) RESULT(avg)
        CLASS(Stopwatch), INTENT(IN) :: this
        REAL(wp) :: avg
        IF (this%lap_count > 0) THEN
            avg = REAL(this%total_time, wp) / REAL(this%lap_count, wp)
        ELSE
            avg = 0.0_wp
        END IF
    END FUNCTION Stopwatch_GetAverageLapTime

    ! ===================================================================
    ! Date Procedures
    ! ===================================================================
    SUBROUTINE Date_Init(this, year, month, day)
        CLASS(Date), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: year, month, day
        this%year = year
        this%month = month
        this%day = day
    END SUBROUTINE Date_Init

    SUBROUTINE Date_Set(this, year, month, day)
        CLASS(Date), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: year, month, day
        this%year = year
        this%month = month
        this%day = day
    END SUBROUTINE Date_Set

    SUBROUTINE Date_Get(this, year, month, day)
        CLASS(Date), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: year, month, day
        year = this%year
        month = this%month
        day = this%day
    END SUBROUTINE Date_Get

    ! Helper function to get number of days in a month
    PURE FUNCTION DaysInMonth(year, month) RESULT(days)
        INTEGER(i4), INTENT(IN) :: year, month
        INTEGER(i4) :: days
        LOGICAL :: is_leap
        INTEGER(i4), PARAMETER :: days_per_month(12) = &
            [31_i4, 28_i4, 31_i4, 30_i4, 31_i4, 30_i4, 31_i4, 31_i4, 30_i4, 31_i4, 30_i4, 31_i4]
        
        is_leap = (MOD(year, 4_i4) == 0_i4 .AND. MOD(year, 100_i4) /= 0_i4) .OR. &
                  (MOD(year, 400_i4) == 0_i4)
        
        days = days_per_month(month)
        IF (month == 2_i4 .AND. is_leap) days = 29_i4
    END FUNCTION DaysInMonth

    FUNCTION Date_IsValid(this) RESULT(valid)
        CLASS(Date), INTENT(IN) :: this
        LOGICAL :: valid
        INTEGER(i4) :: max_days
        IF (this%year <= 0_i4 .OR. this%month < 1_i4 .OR. this%month > 12_i4) THEN
            valid = .FALSE.
            RETURN
        END IF
        max_days = DaysInMonth(this%year, this%month)
        valid = (this%day >= 1_i4 .AND. this%day <= max_days)
    END FUNCTION Date_IsValid

    SUBROUTINE Date_AddDays(this, days)
        CLASS(Date), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: days
        INTEGER(i4) :: total_days, max_days
        total_days = this%day + days
        DO WHILE (total_days > 0_i4)
            max_days = DaysInMonth(this%year, this%month)
            IF (total_days <= max_days) EXIT
            total_days = total_days - max_days
            CALL this%AddMonths(1_i4)
        END DO
        DO WHILE (total_days < 1_i4)
            CALL this%AddMonths(-1_i4)
            max_days = DaysInMonth(this%year, this%month)
            total_days = total_days + max_days
        END DO
        this%day = total_days
    END SUBROUTINE Date_AddDays

    SUBROUTINE Date_AddMonths(this, months)
        CLASS(Date), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: months
        INTEGER(i4) :: total_months, yrs, mons, max_days
        total_months = this%month + months
        IF (total_months >= 1_i4 .AND. total_months <= 12_i4) THEN
            this%month = total_months
        ELSE
            yrs = (total_months - 1_i4) / 12_i4
            mons = MOD(total_months - 1_i4, 12_i4) + 1_i4
            IF (mons < 1_i4) THEN
                mons = mons + 12_i4
                yrs = yrs - 1_i4
            END IF
            this%year = this%year + yrs
            this%month = mons
        END IF
        ! Adjust day if it exceeds maximum days in new month
        max_days = DaysInMonth(this%year, this%month)
        IF (this%day > max_days) this%day = max_days
    END SUBROUTINE Date_AddMonths

    SUBROUTINE Date_AddYears(this, years)
        CLASS(Date), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: years
        this%year = this%year + years
    END SUBROUTINE Date_AddYears

    FUNCTION Date_Difference(this, other) RESULT(diff)
        CLASS(Date), INTENT(IN) :: this, other
        INTEGER(i4) :: diff
        diff = (this%year - other%year) * 365 + (this%month - other%month) * 30 + (this%day - other%day)
    END FUNCTION Date_Difference

    FUNCTION Date_ToString(this) RESULT(str)
        CLASS(Date), INTENT(IN) :: this
        CHARACTER(LEN=10) :: str
        WRITE(str, '(I4.4, "-", I2.2, "-", I2.2)') this%year, this%month, this%day
    END FUNCTION Date_ToString

    SUBROUTINE Date_FromString(this, str)
        CLASS(Date), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: str
        READ(str, '(I4, 1X, I2, 1X, I2)') this%year, this%month, this%day
    END SUBROUTINE Date_FromString

    ! ===================================================================
    ! Time Procedures
    ! ===================================================================
    SUBROUTINE Time_Init(this, hour, minute, second, millisecond)
        CLASS(Time), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: hour, minute, second
        INTEGER(i4), INTENT(IN), OPTIONAL :: millisecond
        this%hour = hour
        this%minute = minute
        this%second = second
        IF (PRESENT(millisecond)) this%millisecond = millisecond
    END SUBROUTINE Time_Init

    SUBROUTINE Time_Set(this, hour, minute, second, millisecond)
        CLASS(Time), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: hour, minute, second
        INTEGER(i4), INTENT(IN), OPTIONAL :: millisecond
        this%hour = hour
        this%minute = minute
        this%second = second
        IF (PRESENT(millisecond)) this%millisecond = millisecond
    END SUBROUTINE Time_Set

    SUBROUTINE Time_Get(this, hour, minute, second, millisecond)
        CLASS(Time), INTENT(IN) :: this
        INTEGER(i4), INTENT(OUT) :: hour, minute, second
        INTEGER(i4), INTENT(OUT), OPTIONAL :: millisecond
        hour = this%hour
        minute = this%minute
        second = this%second
        IF (PRESENT(millisecond)) millisecond = this%millisecond
    END SUBROUTINE Time_Get

    FUNCTION Time_IsValid(this) RESULT(valid)
        CLASS(Time), INTENT(IN) :: this
        LOGICAL :: valid
        valid = (this%hour >= 0_i4 .AND. this%hour <= 23_i4 .AND. &
                 this%minute >= 0_i4 .AND. this%minute <= 59_i4 .AND. &
                 this%second >= 0_i4 .AND. this%second <= 59_i4 .AND. &
                 this%millisecond >= 0_i4 .AND. this%millisecond <= 999_i4)
    END FUNCTION Time_IsValid

    SUBROUTINE Time_AddSeconds(this, seconds)
        CLASS(Time), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: seconds
        INTEGER(i4) :: total_seconds, mins, secs
        total_seconds = this%second + seconds
        IF (total_seconds >= 0_i4) THEN
            mins = total_seconds / 60_i4
            secs = MOD(total_seconds, 60_i4)
        ELSE
            ! Handle negative seconds
            mins = (total_seconds - 59_i4) / 60_i4
            secs = MOD(total_seconds, 60_i4)
            IF (secs < 0_i4) secs = secs + 60_i4
        END IF
        this%second = secs
        IF (mins /= 0_i4) CALL this%AddMinutes(mins)
    END SUBROUTINE Time_AddSeconds

    SUBROUTINE Time_AddMinutes(this, minutes)
        CLASS(Time), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: minutes
        INTEGER(i4) :: total_minutes, hrs, mins
        total_minutes = this%minute + minutes
        IF (total_minutes >= 0_i4) THEN
            hrs = total_minutes / 60_i4
            mins = MOD(total_minutes, 60_i4)
        ELSE
            ! Handle negative minutes
            hrs = (total_minutes - 59_i4) / 60_i4
            mins = MOD(total_minutes, 60_i4)
            IF (mins < 0_i4) mins = mins + 60_i4
        END IF
        this%minute = mins
        IF (hrs /= 0_i4) CALL this%AddHours(hrs)
    END SUBROUTINE Time_AddMinutes

    SUBROUTINE Time_AddHours(this, hours)
        CLASS(Time), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: hours
        INTEGER(i4) :: total_hours
        total_hours = this%hour + hours
        ! Handle overflow/underflow for 24-hour format (wraps around)
        this%hour = MOD(total_hours, 24_i4)
        IF (this%hour < 0_i4) this%hour = this%hour + 24_i4
    END SUBROUTINE Time_AddHours

    FUNCTION Time_Difference(this, other) RESULT(diff)
        CLASS(Time), INTENT(IN) :: this, other
        INTEGER(i4) :: diff
        diff = (this%hour - other%hour) * 3600 + (this%minute - other%minute) * 60 + (this%second - other%second)
    END FUNCTION Time_Difference

    FUNCTION Time_ToString(this) RESULT(str)
        CLASS(Time), INTENT(IN) :: this
        CHARACTER(LEN=12) :: str
        WRITE(str, '(I2.2, ":", I2.2, ":", I2.2, ".", I3.3)') this%hour, this%minute, this%second, this%millisecond
    END FUNCTION Time_ToString

    SUBROUTINE Time_FromString(this, str)
        CLASS(Time), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: str
        READ(str, '(I2, 1X, I2, 1X, I2, 1X, I3)') this%hour, this%minute, this%second, this%millisecond
    END SUBROUTINE Time_FromString

    ! ===================================================================
    ! Array Utilities
    ! ===================================================================
    ! SortInt: Insertion sort for integer arrays
    ! Algorithm: Insertion sort - O(n^2) worst case, O(n) best case
    ! Suitable for small arrays (< 50 elements) or nearly sorted data
    ! For larger arrays, consider using quicksort or heapsort
    ! ===================================================================
    SUBROUTINE SortInt(a, n)
        INTEGER(i4), INTENT(INOUT) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4) :: i, j, key
        DO i = 2, n
            key = a(i)
            j = i - 1
            DO WHILE (j >= 1 .AND. a(j) > key)
                a(j+1) = a(j)
                j = j - 1
            END DO
            a(j+1) = key
        END DO
    END SUBROUTINE SortInt

    ! SortReal: Insertion sort for real arrays
    ! Algorithm: Insertion sort - O(n^2) worst case, O(n) best case
    ! Suitable for small arrays (< 50 elements) or nearly sorted data
    ! For larger arrays, consider using quicksort or heapsort
    ! ===================================================================
    SUBROUTINE SortReal(a, n)
        REAL(wp), INTENT(INOUT) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4) :: i, j
        REAL(wp) :: key
        DO i = 2, n
            key = a(i)
            j = i - 1
            DO WHILE (j >= 1 .AND. a(j) > key)
                a(j+1) = a(j)
                j = j - 1
            END DO
            a(j+1) = key
        END DO
    END SUBROUTINE SortReal

    SUBROUTINE UniqueInt(a, n, unique_a, n_unique)
        INTEGER(i4), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(OUT) :: unique_a(:)
        INTEGER(i4), INTENT(OUT) :: n_unique
        INTEGER(i4) :: i
        INTEGER(i4), ALLOCATABLE :: temp(:)
        ALLOCATE(temp(n))
        temp = a
        CALL SortInt(temp, n)
        n_unique = 1
        unique_a(1) = temp(1)
        DO i = 2, n
            IF (temp(i) /= temp(i-1)) THEN
                n_unique = n_unique + 1
                unique_a(n_unique) = temp(i)
            END IF
        END DO
        DEALLOCATE(temp)
    END SUBROUTINE UniqueInt

    SUBROUTINE UniqueReal(a, n, unique_a, n_unique, tol)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), INTENT(OUT) :: unique_a(:)
        INTEGER(i4), INTENT(OUT) :: n_unique
        REAL(wp), INTENT(IN), OPTIONAL :: tol
        INTEGER(i4) :: i
        REAL(wp) :: tolerance
        REAL(wp), ALLOCATABLE :: temp(:)
        IF (PRESENT(tol)) THEN
            tolerance = tol
        ELSE
            tolerance = 1.0E-10_wp
        END IF
        ALLOCATE(temp(n))
        temp = a
        CALL SortReal(temp, n)
        n_unique = 1
        unique_a(1) = temp(1)
        DO i = 2, n
            IF (ABS(temp(i) - temp(i-1)) > tolerance) THEN
                n_unique = n_unique + 1
                unique_a(n_unique) = temp(i)
            END IF
        END DO
        DEALLOCATE(temp)
    END SUBROUTINE UniqueReal

    FUNCTION FindInt(a, n, val) RESULT(idx)
        INTEGER(i4), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: val
        INTEGER(i4) :: idx, i
        idx = 0
        DO i = 1, n
            IF (a(i) == val) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION FindInt

    FUNCTION FindReal(a, n, val, tol) RESULT(idx)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), INTENT(IN) :: val
        REAL(wp), INTENT(IN), OPTIONAL :: tol
        INTEGER(i4) :: idx, i
        REAL(wp) :: tolerance
        IF (PRESENT(tol)) THEN
            tolerance = tol
        ELSE
            tolerance = 1.0E-10_wp
        END IF
        idx = 0
        DO i = 1, n
            IF (ABS(a(i) - val) < tolerance) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION FindReal

    FUNCTION CountInt(a, n, val) RESULT(cnt)
        INTEGER(i4), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4), INTENT(IN) :: val
        INTEGER(i4) :: cnt, i
        cnt = 0
        DO i = 1, n
            IF (a(i) == val) cnt = cnt + 1
        END DO
    END FUNCTION CountInt

    FUNCTION CountReal(a, n, val, tol) RESULT(cnt)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp), INTENT(IN) :: val
        REAL(wp), INTENT(IN), OPTIONAL :: tol
        INTEGER(i4) :: cnt, i
        REAL(wp) :: tolerance
        IF (PRESENT(tol)) THEN
            tolerance = tol
        ELSE
            tolerance = 1.0E-10_wp
        END IF
        cnt = 0
        DO i = 1, n
            IF (ABS(a(i) - val) < tolerance) cnt = cnt + 1
        END DO
    END FUNCTION CountReal

    FUNCTION SumInt(a, n) RESULT(s)
        INTEGER(i4), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4) :: s
        s = sum(a(1:n))
    END FUNCTION SumInt

    FUNCTION SumReal(a, n) RESULT(s)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp) :: s
        s = sum(a(1:n))
    END FUNCTION SumReal

    FUNCTION MeanReal(a, n) RESULT(m)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp) :: m
        IF (n > 0) THEN
            m = sum(a(1:n)) / REAL(n, wp)
        ELSE
            m = 0.0_wp
        END IF
    END FUNCTION MeanReal

    FUNCTION StdDevReal(a, n) RESULT(sd)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp) :: sd, m
        IF (n > 1) THEN
            m = MeanReal(a, n)
            sd = sqrt(sum((a(1:n) - m)**2) / REAL(n-1, wp))
        ELSE
            sd = 0.0_wp
        END IF
    END FUNCTION StdDevReal

    FUNCTION MinInt(a, n) RESULT(val)
        INTEGER(i4), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4) :: val
        val = minval(a(1:n))
    END FUNCTION MinInt

    FUNCTION MinReal(a, n) RESULT(val)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp) :: val
        val = minval(a(1:n))
    END FUNCTION MinReal

    FUNCTION MaxInt(a, n) RESULT(val)
        INTEGER(i4), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        INTEGER(i4) :: val
        val = maxval(a(1:n))
    END FUNCTION MaxInt

    FUNCTION MaxReal(a, n) RESULT(val)
        REAL(wp), INTENT(IN) :: a(:)
        INTEGER(i4), INTENT(IN) :: n
        REAL(wp) :: val
        val = maxval(a(1:n))
    END FUNCTION MaxReal

  ! ===================================================================
  ! Smart Allocation Procedures (Scheme 3: Hybrid Strategy)
  ! For arrays with variable sizes, use intelligent growth strategy
  ! ===================================================================

  SUBROUTINE smart_allocate_1d(arr, required_size, growth_factor, status)
    !! Smart allocation for 1D real array with growth strategy
    !! Only reallocates if current size is insufficient
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: arr(:)
    INTEGER(i4), INTENT(IN) :: required_size
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: factor
    INTEGER(i4) :: new_size, current_size
    REAL(wp), ALLOCATABLE :: temp(:)

    CALL init_error_status(status)

    IF (required_size <= 0_i4) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "smart_allocate: required_size must be positive"
      RETURN
    END IF

    factor = 1.5_wp  ! Default growth factor
    IF (PRESENT(growth_factor)) factor = MAX(1.1_wp, growth_factor)

    IF (.NOT. ALLOCATED(arr)) THEN
      ! First allocation
      ALLOCATE(arr(required_size))
    ELSE
      current_size = SIZE(arr)
      IF (current_size < required_size) THEN
        ! Need to grow: use growth factor strategy
        new_size = MAX(INT(current_size * factor), required_size)
        ! Use MOVE_ALLOC for efficient reallocation
        ALLOCATE(temp(new_size))
        temp(1:current_size) = arr(1:current_size)
        temp(current_size+1:new_size) = 0.0_wp  ! Init new elements
        CALL MOVE_ALLOC(temp, arr)
      END IF
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE smart_allocate_1d

  SUBROUTINE smart_allocate_2d(arr, required_size1, required_size2, growth_factor, status)
    !! Smart allocation for 2D real array with growth strategy
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: arr(:,:)
    INTEGER(i4), INTENT(IN) :: required_size1, required_size2
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: factor
    INTEGER(i4) :: new_size1, new_size2, current_size1, current_size2
    REAL(wp), ALLOCATABLE :: temp(:,:)

    CALL init_error_status(status)

    IF (required_size1 <= 0_i4 .OR. required_size2 <= 0_i4) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "smart_allocate: sizes must be positive"
      RETURN
    END IF

    factor = 1.5_wp
    IF (PRESENT(growth_factor)) factor = MAX(1.1_wp, growth_factor)

    IF (.NOT. ALLOCATED(arr)) THEN
      ALLOCATE(arr(required_size1, required_size2))
    ELSE
      current_size1 = SIZE(arr, 1)
      current_size2 = SIZE(arr, 2)
      IF (current_size1 < required_size1 .OR. current_size2 < required_size2) THEN
        new_size1 = MAX(INT(current_size1 * factor), required_size1)
        new_size2 = MAX(INT(current_size2 * factor), required_size2)
        ALLOCATE(temp(new_size1, new_size2))
        temp(1:current_size1, 1:current_size2) = arr(1:current_size1, 1:current_size2)
        temp(current_size1+1:new_size1, :) = 0.0_wp
        temp(:, current_size2+1:new_size2) = 0.0_wp
        CALL MOVE_ALLOC(temp, arr)
      END IF
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE smart_allocate_2d

  SUBROUTINE smart_allocate_int1d(arr, required_size, growth_factor, status)
    !! Smart allocation for 1D integer array with growth strategy
    INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: arr(:)
    INTEGER(i4), INTENT(IN) :: required_size
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: factor
    INTEGER(i4) :: new_size, current_size
    INTEGER(i4), ALLOCATABLE :: temp(:)

    CALL init_error_status(status)

    IF (required_size <= 0_i4) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "smart_allocate_int1d: required_size must be positive"
      RETURN
    END IF

    factor = 1.5_wp
    IF (PRESENT(growth_factor)) factor = MAX(1.1_wp, growth_factor)

    IF (.NOT. ALLOCATED(arr)) THEN
      ALLOCATE(arr(required_size))
    ELSE
      current_size = SIZE(arr)
      IF (current_size < required_size) THEN
        new_size = MAX(INT(current_size * factor), required_size)
        ALLOCATE(temp(new_size))
        temp(1:current_size) = arr(1:current_size)
        temp(current_size+1:new_size) = 0_i4
        CALL MOVE_ALLOC(temp, arr)
      END IF
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE smart_allocate_int1d

  SUBROUTINE smart_allocate_int2d(arr, required_size1, required_size2, growth_factor, status)
    !! Smart allocation for 2D integer array with growth strategy
    INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: arr(:,:)
    INTEGER(i4), INTENT(IN) :: required_size1, required_size2
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: factor
    INTEGER(i4) :: new_size1, new_size2, current_size1, current_size2
    INTEGER(i4), ALLOCATABLE :: temp(:,:)

    CALL init_error_status(status)

    IF (required_size1 <= 0_i4 .OR. required_size2 <= 0_i4) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "smart_allocate_int2d: sizes must be positive"
      RETURN
    END IF

    factor = 1.5_wp
    IF (PRESENT(growth_factor)) factor = MAX(1.1_wp, growth_factor)

    IF (.NOT. ALLOCATED(arr)) THEN
      ALLOCATE(arr(required_size1, required_size2))
    ELSE
      current_size1 = SIZE(arr, 1)
      current_size2 = SIZE(arr, 2)
      IF (current_size1 < required_size1 .OR. current_size2 < required_size2) THEN
        new_size1 = MAX(INT(current_size1 * factor), required_size1)
        new_size2 = MAX(INT(current_size2 * factor), required_size2)
        ALLOCATE(temp(new_size1, new_size2))
        temp(1:current_size1, 1:current_size2) = arr(1:current_size1, 1:current_size2)
        temp(current_size1+1:new_size1, :) = 0_i4
        temp(:, current_size2+1:new_size2) = 0_i4
        CALL MOVE_ALLOC(temp, arr)
      END IF
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE smart_allocate_int2d

  ! ===================================================================
  ! Smart Grow (aliases for smart_allocate, used by UniFld/LoadBC)
  ! ===================================================================
  SUBROUTINE smart_grow_real_vector(arr, required_size, growth_factor, status)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: arr(:)
    INTEGER(i4), INTENT(IN) :: required_size
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL smart_allocate(arr, required_size, growth_factor, status)
  END SUBROUTINE smart_grow_real_vector

  SUBROUTINE smart_grow_int_vector(arr, required_size, growth_factor, status)
    INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: arr(:)
    INTEGER(i4), INTENT(IN) :: required_size
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL smart_allocate_int1d(arr, required_size, growth_factor, status)
  END SUBROUTINE smart_grow_int_vector

  SUBROUTINE smart_grow_real_Mtx(arr, required_size1, required_size2, growth_factor, status)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: arr(:,:)
    INTEGER(i4), INTENT(IN) :: required_size1, required_size2
    REAL(wp), INTENT(IN), OPTIONAL :: growth_factor
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL smart_allocate(arr, required_size1, required_size2, growth_factor, status)
  END SUBROUTINE smart_grow_real_Mtx

  SUBROUTINE cache_array_size(name, size_val)
    !! Cache array size for predictive pre-allocation (Scheme C)
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: size_val

    INTEGER(i4) :: i, idx
    TYPE(ArraySizeCache), ALLOCATABLE :: temp_cache(:)

    ! Find existing entry
    idx = 0
    IF (ALLOCATED(size_cache)) THEN
      DO i = 1, SIZE(size_cache)
        IF (size_cache(i)%name == name) THEN
          idx = i
          EXIT
        END IF
      END DO
    END IF

    IF (idx > 0) THEN
      ! Update existing entry
      size_cache(idx)%cached_size = size_val
      size_cache(idx)%access_count = size_cache(idx)%access_count + 1_i4
      size_cache(idx)%last_access_tim = size_cache(idx)%last_access_tim + 1_i4
    ELSE
      ! Add new entry
      IF (.NOT. ALLOCATED(size_cache)) THEN
        ALLOCATE(size_cache(MD_MODEL_MAX_CACHE_SIZE))
        cache_size = 0_i4
      END IF

      IF (cache_size < MD_MODEL_MAX_CACHE_SIZE) THEN
        cache_size = cache_size + 1_i4
        size_cache(cache_size)%name = name
        size_cache(cache_size)%cached_size = size_val
        size_cache(cache_size)%access_count = 1_i4
        size_cache(cache_size)%last_access_tim = 1_i4
        size_cache(cache_size)%growth_factor = 1.5_wp
      ELSE
        ! Cache full - replace least recently used
        idx = MINLOC(size_cache%last_access_tim, DIM=1)
        size_cache(idx)%name = name
        size_cache(idx)%cached_size = size_val
        size_cache(idx)%access_count = 1_i4
        size_cache(idx)%last_access_tim = MAXVAL(size_cache%last_access_tim) + 1_i4
      END IF
    END IF
  END SUBROUTINE cache_array_size

  FUNCTION get_cached_size(name, default_size) RESULT(cached_val)
    !! Get cached array size for predictive pre-allocation (Scheme C)
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: default_size
    INTEGER(i4) :: cached_val

    INTEGER(i4) :: i

    cached_val = default_size

    IF (ALLOCATED(size_cache)) THEN
      DO i = 1, SIZE(size_cache)
        IF (size_cache(i)%name == name .AND. size_cache(i)%cached_size > 0_i4) THEN
          cached_val = INT(size_cache(i)%cached_size * size_cache(i)%growth_factor)
          size_cache(i)%last_access_tim = size_cache(i)%last_access_tim + 1_i4
          EXIT
        END IF
      END DO
    END IF
  END FUNCTION get_cached_size

  SUBROUTINE predictive_preallocate_real1d(arr, name, estimated_size, status)
    !! Predictive pre-allocation using cached sizes (Scheme C)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: arr(:)
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: estimated_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: cached_size, prealloc_size

    CALL init_error_status(status)

    ! Get cached size if available
    cached_size = get_cached_size(name, estimated_size)
    
    ! Use maximum of estimated and cached size
    prealloc_size = MAX(estimated_size, cached_size)

    ! Pre-allocate with smart growth
    IF (.NOT. ALLOCATED(arr)) THEN
      ALLOCATE(arr(prealloc_size))
      arr = 0.0_wp
    ELSE IF (SIZE(arr) < prealloc_size) THEN
      CALL smart_grow_real_vector(arr, prealloc_size, growth_factor=1.5_wp, status=status)
    END IF

    ! Cache the actual size used
    IF (ALLOCATED(arr)) THEN
      CALL cache_array_size(name, SIZE(arr))
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE predictive_preallocate_real1d

  SUBROUTINE adaptive_growth_factor(name, actual_size, requested_size, new_factor)
    !! Adaptive growth factor based on usage patterns (Scheme C)
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: actual_size, requested_size
    REAL(wp), INTENT(OUT) :: new_factor

    INTEGER(i4) :: i, idx
    REAL(wp) :: utilization

    new_factor = 1.5_wp  ! Default

    IF (actual_size > 0_i4) THEN
      utilization = REAL(requested_size, wp) / REAL(actual_size, wp)
      
      ! Adjust growth factor based on utilization
      IF (utilization > 0.9_wp) THEN
        ! High utilization - increase growth factor
        new_factor = 2.0_wp
      ELSE IF (utilization < 0.5_wp) THEN
        ! Low utilization - decrease growth factor
        new_factor = 1.2_wp
      ELSE
        ! Moderate utilization - keep default
        new_factor = 1.5_wp
      END IF

      ! Update cache entry if exists
      IF (ALLOCATED(size_cache)) THEN
        idx = 0
        DO i = 1, SIZE(size_cache)
          IF (size_cache(i)%name == name) THEN
            idx = i
            EXIT
          END IF
        END DO
        
        IF (idx > 0) THEN
          size_cache(idx)%growth_factor = new_factor
        END IF
      END IF
    END IF
  END SUBROUTINE adaptive_growth_factor

  ! ===================================================================
  ! Math Module Procedures (from MD_Base_Math_Mgr)
  ! ===================================================================
  SUBROUTINE Array_Append_Int1D(array, n, val)
      INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: array(:)
      INTEGER(i4), INTENT(INOUT) :: n
      INTEGER(i4), INTENT(IN) :: val
      INTEGER(i4), ALLOCATABLE :: tmp(:)
      IF (.NOT. ALLOCATED(array)) THEN
          ALLOCATE(array(10))
          n = 0
      ELSE IF (n >= SIZE(array)) THEN
          ALLOCATE(tmp(SIZE(array)*2))
          tmp(1:n) = array(1:n)
          CALL MOVE_ALLOC(tmp, array)
      END IF
      n = n + 1
      array(n) = val
  END SUBROUTINE Array_Append_Int1D

  SUBROUTINE Array_Append_Int2D(array, n1, n2, val)
      INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: array(:,:)
      INTEGER(i4), INTENT(IN) :: n1
      INTEGER(i4), INTENT(INOUT) :: n2
      INTEGER(i4), INTENT(IN) :: val(n1)
      INTEGER(i4), ALLOCATABLE :: tmp(:,:)
      IF (.NOT. ALLOCATED(array)) THEN
          ALLOCATE(array(n1, 10))
          n2 = 0
      ELSE IF (n2 >= SIZE(array, 2)) THEN
          ALLOCATE(tmp(n1, SIZE(array, 2)*2))
          tmp(:, 1:n2) = array(:, 1:n2)
          CALL MOVE_ALLOC(tmp, array)
      END IF
      n2 = n2 + 1
      array(:, n2) = val
  END SUBROUTINE Array_Append_Int2D

  SUBROUTINE Array_Append_DP1D(array, n, val)
      REAL(wp), ALLOCATABLE, INTENT(INOUT) :: array(:)
      INTEGER(i4), INTENT(INOUT) :: n
      REAL(wp), INTENT(IN) :: val
      REAL(wp), ALLOCATABLE :: tmp(:)
      IF (.NOT. ALLOCATED(array)) THEN
          ALLOCATE(array(10))
          n = 0
      ELSE IF (n >= SIZE(array)) THEN
          ALLOCATE(tmp(SIZE(array)*2))
          tmp(1:n) = array(1:n)
          CALL MOVE_ALLOC(tmp, array)
      END IF
      n = n + 1
      array(n) = val
  END SUBROUTINE Array_Append_DP1D

  SUBROUTINE Array_Append_DP2D(array, n1, n2, val)
      REAL(wp), ALLOCATABLE, INTENT(INOUT) :: array(:,:)
      INTEGER(i4), INTENT(IN) :: n1
      INTEGER(i4), INTENT(INOUT) :: n2
      REAL(wp), INTENT(IN) :: val(n1)
      REAL(wp), ALLOCATABLE :: tmp(:,:)
      IF (.NOT. ALLOCATED(array)) THEN
          ALLOCATE(array(n1, 10))
          n2 = 0
      ELSE IF (n2 >= SIZE(array, 2)) THEN
          ALLOCATE(tmp(n1, SIZE(array, 2)*2))
          tmp(:, 1:n2) = array(:, 1:n2)
          CALL MOVE_ALLOC(tmp, array)
      END IF
      n2 = n2 + 1
      array(:, n2) = val
  END SUBROUTINE Array_Append_DP2D

  SUBROUTINE MathUtils_Init(this, status)
      CLASS(MathUtils), INTENT(INOUT) :: this
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      this%is_initialized = .TRUE.
  END SUBROUTINE MathUtils_Init

  SUBROUTINE MathUtils_Destroy(this, status)
      CLASS(MathUtils), INTENT(INOUT) :: this
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      this%is_initialized = .FALSE.
  END SUBROUTINE MathUtils_Destroy

  SUBROUTINE GaussQuadrature_Init(this, element_type, npts, status)
      CLASS(GaussQuadrature), INTENT(INOUT) :: this
      CHARACTER(LEN=*), INTENT(IN) :: element_type
      INTEGER(i4), INTENT(IN) :: npts
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      this%element_type = TRIM(element_type)
      this%npts = npts
      this%is_initialized = .TRUE.
      CALL this%Setup(status)
  END SUBROUTINE GaussQuadrature_Init

  SUBROUTINE GaussQuadrature_Destroy(this, status)
      CLASS(GaussQuadrature), INTENT(INOUT) :: this
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      CALL init_error_status(status)
      IF (ALLOCATED(this%points)) DEALLOCATE(this%points)
      IF (ALLOCATED(this%weights)) DEALLOCATE(this%weights)
      this%is_initialized = .FALSE.
  END SUBROUTINE GaussQuadrature_Destroy

  SUBROUTINE GaussQuadrature_Setup(this, status)
      CLASS(GaussQuadrature), INTENT(INOUT) :: this
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      INTEGER(i4) :: npts, dim, n_tri, n_line
      REAL(wp), ALLOCATABLE :: xi(:), eta(:), zeta(:), w(:)
      CALL init_error_status(status)
      npts = this%npts
      SELECT CASE (TRIM(this%element_type))
      CASE ('LINE')
          dim = 1
          this%dim = dim
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          ALLOCATE(xi(npts), w(npts))
          CALL gauss_line(npts, xi, w)
          this%points(:,1) = xi
          this%weights = w
      CASE ('TRI')
          dim = 2
          this%dim = dim
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          ALLOCATE(xi(npts), eta(npts), w(npts))
          CALL gauss_triangle(npts, xi, eta, w)
          this%points(:,1) = xi
          this%points(:,2) = eta
          this%weights = w
      CASE ('QUAD')
          dim = 2
          this%dim = dim
          npts = this%npts * this%npts
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          ALLOCATE(xi(npts), eta(npts), w(npts))
          CALL gauss_quad(this%npts, xi, eta, w)
          this%points(:,1) = xi
          this%points(:,2) = eta
          this%weights = w
          this%npts = npts
      CASE ('TETRA')
          dim = 3
          this%dim = dim
          ALLOCATE(xi(npts), eta(npts), zeta(npts), w(npts))
          CALL gauss_tetrahedron(npts, xi, eta, zeta, w)
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          this%points(:,1) = xi
          this%points(:,2) = eta
          this%points(:,3) = zeta
          this%weights = w
      CASE ('HEX')
          dim = 3
          this%dim = dim
          npts = this%npts * this%npts * this%npts
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          ALLOCATE(xi(npts), eta(npts), zeta(npts), w(npts))
          CALL gauss_hexahedron(this%npts, xi, eta, zeta, w)
          this%points(:,1) = xi
          this%points(:,2) = eta
          this%points(:,3) = zeta
          this%weights = w
          this%npts = npts
      CASE ('PRISM')
          dim = 3
          this%dim = dim
          n_tri = this%npts
          n_line = this%npts
          npts = n_tri * n_line
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          ALLOCATE(xi(npts), eta(npts), zeta(npts), w(npts))
          CALL gauss_prism(n_tri, n_line, xi, eta, zeta, w)
          this%points(:,1) = xi
          this%points(:,2) = eta
          this%points(:,3) = zeta
          this%weights = w
          this%npts = npts
      CASE ('PYRAMID')
          dim = 3
          this%dim = dim
          n_tri = this%npts
          n_line = this%npts
          npts = n_tri * n_tri * n_line
          ALLOCATE(this%points(npts, dim), this%weights(npts))
          ALLOCATE(xi(npts), eta(npts), zeta(npts), w(npts))
          CALL gauss_pyramid(n_tri, n_line, xi, eta, zeta, w)
          this%points(:,1) = xi
          this%points(:,2) = eta
          this%points(:,3) = zeta
          this%weights = w
          this%npts = npts
      CASE DEFAULT
          status%status_code = -1
          status%message = "Unsupported element type: " // TRIM(this%element_type)
          RETURN
      END SELECT
      IF (ALLOCATED(xi)) DEALLOCATE(xi)
      IF (ALLOCATED(eta)) DEALLOCATE(eta)
      IF (ALLOCATED(zeta)) DEALLOCATE(zeta)
      IF (ALLOCATED(w)) DEALLOCATE(w)
      status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE GaussQuadrature_Setup

  FUNCTION GaussQuadrature_GetPoints(this) RESULT(pts)
      CLASS(GaussQuadrature), INTENT(IN) :: this
      REAL(wp), ALLOCATABLE :: pts(:,:)
      IF (ALLOCATED(this%points)) pts = this%points
  END FUNCTION GaussQuadrature_GetPoints

  FUNCTION GaussQuadrature_GetWeights(this) RESULT(wts)
      CLASS(GaussQuadrature), INTENT(IN) :: this
      REAL(wp), ALLOCATABLE :: wts(:)
      IF (ALLOCATED(this%weights)) wts = this%weights
  END FUNCTION GaussQuadrature_GetWeights

  SUBROUTINE VecOps_Init(this, size)
      CLASS(VecOps), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: size
      this%size = size
      this%is_initialized = .TRUE.
  END SUBROUTINE VecOps_Init

  SUBROUTINE VecOps_Destroy(this)
      CLASS(VecOps), INTENT(INOUT) :: this
      this%size = 0
      this%is_initialized = .FALSE.
  END SUBROUTINE VecOps_Destroy

  FUNCTION VecOps_Dot(this, a, b) RESULT(res)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: a(:), b(:)
      REAL(wp) :: res
      res = vec_dot(a, b)
  END FUNCTION VecOps_Dot

  FUNCTION VecOps_Norm2(this, a) RESULT(res)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: a(:)
      REAL(wp) :: res
      res = vec_norm2(a)
  END FUNCTION VecOps_Norm2

  SUBROUTINE VecOps_Scale(this, a, x)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: a
      REAL(wp), INTENT(INOUT) :: x(:)
      CALL vec_scale(a, x)
  END SUBROUTINE VecOps_Scale

  SUBROUTINE VecOps_Axpy(this, a, x, y)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: a, x(:)
      REAL(wp), INTENT(INOUT) :: y(:)
      CALL vec_axpy(a, x, y)
  END SUBROUTINE VecOps_Axpy

  SUBROUTINE VecOps_Add(this, x, y, z)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: x(:), y(:)
      REAL(wp), INTENT(OUT) :: z(:)
      CALL vec_add(x, y, z)
  END SUBROUTINE VecOps_Add

  SUBROUTINE VecOps_Subtract(this, x, y, z)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: x(:), y(:)
      REAL(wp), INTENT(OUT) :: z(:)
      CALL vec_sub(x, y, z)
  END SUBROUTINE VecOps_Subtract

  SUBROUTINE VecOps_Cross(this, a, b, c)
      CLASS(VecOps), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: a(3), b(3)
      REAL(wp), INTENT(OUT) :: c(3)
      CALL vec_cross_3d(a, b, c)
  END SUBROUTINE VecOps_Cross

  SUBROUTINE Sparse_MatVec_Wrapper(this, A, x, y)
      CLASS(SparseMatrixUtils), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: A(:,:), x(:)
      REAL(wp), INTENT(OUT) :: y(:)
      CALL mat_vec(A, x, y)
  END SUBROUTINE Sparse_MatVec_Wrapper

  FUNCTION vec_dot(a, b) RESULT(res)
      REAL(wp), INTENT(IN) :: a(:), b(:)
      REAL(wp) :: res
      res = dot_product(a, b)
  END FUNCTION vec_dot

  SUBROUTINE vec_axpy(a, x, y)
      REAL(wp), INTENT(IN) :: a, x(:)
      REAL(wp), INTENT(INOUT) :: y(:)
      y = y + a * x
  END SUBROUTINE vec_axpy

  FUNCTION vec_norm2(a) RESULT(res)
      REAL(wp), INTENT(IN) :: a(:)
      REAL(wp) :: res
      res = sqrt(dot_product(a, a))
  END FUNCTION vec_norm2

  SUBROUTINE vec_scale(a, x)
      REAL(wp), INTENT(IN) :: a
      REAL(wp), INTENT(INOUT) :: x(:)
      x = a * x
  END SUBROUTINE vec_scale

  SUBROUTINE vec_copy(x, y)
      REAL(wp), INTENT(IN) :: x(:)
      REAL(wp), INTENT(OUT) :: y(:)
      y = x
  END SUBROUTINE vec_copy

  SUBROUTINE vec_zero(x)
      REAL(wp), INTENT(OUT) :: x(:)
      x = ZERO
  END SUBROUTINE vec_zero

  SUBROUTINE vec_add(x, y, z)
      REAL(wp), INTENT(IN) :: x(:), y(:)
      REAL(wp), INTENT(OUT) :: z(:)
      z = x + y
  END SUBROUTINE vec_add

  SUBROUTINE vec_sub(x, y, z)
      REAL(wp), INTENT(IN) :: x(:), y(:)
      REAL(wp), INTENT(OUT) :: z(:)
      z = x - y
  END SUBROUTINE vec_sub

  SUBROUTINE vec_cross_3d(a, b, c)
      REAL(wp), INTENT(IN) :: a(3), b(3)
      REAL(wp), INTENT(OUT) :: c(3)
      c(1) = a(2)*b(3) - a(3)*b(2)
      c(2) = a(3)*b(1) - a(1)*b(3)
      c(3) = a(1)*b(2) - a(2)*b(1)
  END SUBROUTINE vec_cross_3d

  SUBROUTINE mat_vec(A, x, y)
      REAL(wp), INTENT(IN) :: A(:,:), x(:)
      REAL(wp), INTENT(OUT) :: y(:)
      y = matmul(A, x)
  END SUBROUTINE mat_vec

  SUBROUTINE mat_mat(A, B, C)
      REAL(wp), INTENT(IN) :: A(:,:), B(:,:)
      REAL(wp), INTENT(OUT) :: C(:,:)
      C = matmul(A, B)
  END SUBROUTINE mat_mat

  SUBROUTINE mat_trans(A, At)
      REAL(wp), INTENT(IN) :: A(:,:)
      REAL(wp), INTENT(OUT) :: At(:,:)
      At = transpose(A)
  END SUBROUTINE mat_trans

  SUBROUTINE mat_inv_3x3(A, Ainv, det)
      REAL(wp), INTENT(IN) :: A(3,3)
      REAL(wp), INTENT(OUT) :: Ainv(3,3)
      REAL(wp), INTENT(OUT) :: det
      REAL(wp) :: det_inv
      det = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) - &
            A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) + &
            A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
      IF (ABS(det) > 1.0E-15_wp) THEN
          det_inv = ONE / det
          Ainv(1,1) = (A(2,2)*A(3,3) - A(2,3)*A(3,2)) * det_inv
          Ainv(1,2) = (A(1,3)*A(3,2) - A(1,2)*A(3,3)) * det_inv
          Ainv(1,3) = (A(1,2)*A(2,3) - A(1,3)*A(2,2)) * det_inv
          Ainv(2,1) = (A(2,3)*A(3,1) - A(2,1)*A(3,3)) * det_inv
          Ainv(2,2) = (A(1,1)*A(3,3) - A(1,3)*A(3,1)) * det_inv
          Ainv(2,3) = (A(1,3)*A(2,1) - A(1,1)*A(2,3)) * det_inv
          Ainv(3,1) = (A(2,1)*A(3,2) - A(2,2)*A(3,1)) * det_inv
          Ainv(3,2) = (A(1,2)*A(3,1) - A(1,1)*A(3,2)) * det_inv
          Ainv(3,3) = (A(1,1)*A(2,2) - A(1,2)*A(2,1)) * det_inv
      ELSE
          Ainv = ZERO
      END IF
  END SUBROUTINE mat_inv_3x3

  SUBROUTINE gauss_line(n, xi, w)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(OUT) :: xi(:), w(:)
      SELECT CASE (n)
      CASE (1)
          xi(1) = ZERO
          w(1) = TWO
      CASE (2)
          xi(1) = -1.0_wp/sqrt(3.0_wp)
          w(1) = ONE
          xi(2) =  1.0_wp/sqrt(3.0_wp)
          w(2) = ONE
      CASE (3)
          xi(1) = -sqrt(0.6_wp)
          w(1) = 5.0_wp/9.0_wp
          xi(2) =  ZERO
          w(2) = 8.0_wp/9.0_wp
          xi(3) =  sqrt(0.6_wp)
          w(3) = 5.0_wp/9.0_wp
      END SELECT
  END SUBROUTINE gauss_line

  SUBROUTINE gauss_triangle(n, xi, eta, w)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(OUT) :: xi(:), eta(:), w(:)
      SELECT CASE (n)
      CASE (1)
          xi(1) = THIRD
          eta(1) = THIRD
          w(1) = HALF
      CASE (3)
          xi(1) = HALF
          eta(1) = ZERO
          w(1) = SIXTH
          xi(2) = HALF
          eta(2) = HALF
          w(2) = SIXTH
          xi(3) = ZERO
          eta(3) = HALF
          w(3) = SIXTH
      END SELECT
  END SUBROUTINE gauss_triangle

  SUBROUTINE gauss_quad(n, xi, eta, w)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(OUT) :: xi(:), eta(:), w(:)
      REAL(wp), ALLOCATABLE :: g_xi(:), g_w(:)
      INTEGER(i4) :: i, j, k
      ALLOCATE(g_xi(n), g_w(n))
      CALL gauss_line(n, g_xi, g_w)
      k = 1
      DO i = 1, n
          DO j = 1, n
              xi(k) = g_xi(j)
              eta(k) = g_xi(i)
              w(k) = g_w(j) * g_w(i)
              k = k + 1
          END DO
      END DO
  END SUBROUTINE gauss_quad

  SUBROUTINE gauss_tetrahedron(n, xi, eta, zeta, w)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), w(:)
      REAL(wp), PARAMETER :: a = 0.1381966011250105_wp
      REAL(wp), PARAMETER :: b = 0.5854101966249685_wp
      REAL(wp), PARAMETER :: c = 0.1381966011250105_wp
      REAL(wp), PARAMETER :: d = 0.1381966011250105_wp
      REAL(wp), PARAMETER :: alpha_5pt = 0.1666666666666667_wp
      REAL(wp), PARAMETER :: beta_5pt = 0.5_wp
      REAL(wp), PARAMETER :: w_sym_5pt = 3.0_wp / 40.0_wp
      INTEGER(i4) :: i, j, k, idx
      REAL(wp) :: step
      SELECT CASE (n)
      CASE (1)
          xi(1) = 0.25_wp
          eta(1) = 0.25_wp
          zeta(1) = 0.25_wp
          w(1) = 1.0_wp / 6.0_wp
      CASE (4)
          xi(1) = a
          eta(1) = a
          zeta(1) = a
          w(1) = 1.0_wp / 24.0_wp
          xi(2) = b
          eta(2) = a
          zeta(2) = a
          w(2) = 1.0_wp / 24.0_wp
          xi(3) = a
          eta(3) = b
          zeta(3) = a
          w(3) = 1.0_wp / 24.0_wp
          xi(4) = a
          eta(4) = a
          zeta(4) = b
          w(4) = 1.0_wp / 24.0_wp
      CASE (5)
          xi(1) = 0.25_wp
          eta(1) = 0.25_wp
          zeta(1) = 0.25_wp
          w(1) = -2.0_wp / 15.0_wp
          xi(2) = alpha_5pt
          eta(2) = alpha_5pt
          zeta(2) = alpha_5pt
          w(2) = w_sym_5pt
          xi(3) = beta_5pt
          eta(3) = alpha_5pt
          zeta(3) = alpha_5pt
          w(3) = w_sym_5pt
          xi(4) = alpha_5pt
          eta(4) = beta_5pt
          zeta(4) = alpha_5pt
          w(4) = w_sym_5pt
          xi(5) = alpha_5pt
          eta(5) = alpha_5pt
          zeta(5) = beta_5pt
          w(5) = w_sym_5pt
      CASE DEFAULT
          idx = 1
          step = 1.0_wp / REAL(n, wp)
          DO i = 1, n
              DO j = 1, n - i + 1
                  DO k = 1, n - i - j + 1
                      IF (idx > SIZE(xi)) EXIT
                      xi(idx) = REAL(i, wp) * step
                      eta(idx) = REAL(j, wp) * step
                      zeta(idx) = REAL(k, wp) * step
                      w(idx) = step**3 / 6.0_wp
                      idx = idx + 1
                  END DO
              END DO
          END DO
      END SELECT
  END SUBROUTINE gauss_tetrahedron

  SUBROUTINE gauss_hexahedron(n, xi, eta, zeta, w)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), w(:)
      REAL(wp), ALLOCATABLE :: g_xi(:), g_w(:)
      INTEGER(i4) :: i, j, k, l
      ALLOCATE(g_xi(n), g_w(n))
      CALL gauss_line(n, g_xi, g_w)
      l = 1
      DO i = 1, n
          DO j = 1, n
              DO k = 1, n
                  xi(l) = g_xi(k)
                  eta(l) = g_xi(j)
                  zeta(l) = g_xi(i)
                  w(l) = g_w(k) * g_w(j) * g_w(i)
                  l = l + 1
              END DO
          END DO
      END DO
  END SUBROUTINE gauss_hexahedron

  SUBROUTINE gauss_prism(n_tri, n_line, xi, eta, zeta, w)
      INTEGER(i4), INTENT(IN) :: n_tri, n_line
      REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), w(:)
      REAL(wp), ALLOCATABLE :: tri_xi(:), tri_eta(:), tri_w(:)
      REAL(wp), ALLOCATABLE :: line_xi(:), line_w(:)
      INTEGER(i4) :: i, j, k
      ALLOCATE(tri_xi(n_tri), tri_eta(n_tri), tri_w(n_tri))
      ALLOCATE(line_xi(n_line), line_w(n_line))
      CALL gauss_triangle(n_tri, tri_xi, tri_eta, tri_w)
      CALL gauss_line(n_line, line_xi, line_w)
      k = 1
      DO i = 1, n_line
          DO j = 1, n_tri
              IF (k > SIZE(xi)) EXIT
              xi(k) = tri_xi(j)
              eta(k) = tri_eta(j)
              zeta(k) = line_xi(i)
              w(k) = tri_w(j) * line_w(i) * HALF
              k = k + 1
          END DO
      END DO
      DEALLOCATE(tri_xi, tri_eta, tri_w, line_xi, line_w)
  END SUBROUTINE gauss_prism

  SUBROUTINE gauss_pyramid(n_quad, n_line, xi, eta, zeta, w)
      INTEGER(i4), INTENT(IN) :: n_quad, n_line
      REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), w(:)
      REAL(wp), ALLOCATABLE :: quad_xi(:), quad_eta(:), quad_w(:)
      REAL(wp), ALLOCATABLE :: line_xi(:), line_w(:)
      INTEGER(i4) :: i, j, k, n_quad_pts
      n_quad_pts = n_quad * n_quad
      ALLOCATE(quad_xi(n_quad_pts), quad_eta(n_quad_pts), quad_w(n_quad_pts))
      ALLOCATE(line_xi(n_line), line_w(n_line))
      CALL gauss_quad(n_quad, quad_xi, quad_eta, quad_w)
      CALL gauss_line(n_line, line_xi, line_w)
      k = 1
      DO i = 1, n_line
          DO j = 1, n_quad_pts
              IF (k > SIZE(xi)) EXIT
              xi(k) = quad_xi(j) * (ONE - line_xi(i))
              eta(k) = quad_eta(j) * (ONE - line_xi(i))
              zeta(k) = line_xi(i)
              w(k) = quad_w(j) * line_w(i) * (ONE - line_xi(i))**2 / 3.0_wp
              k = k + 1
          END DO
      END DO
      DEALLOCATE(quad_xi, quad_eta, quad_w, line_xi, line_w)
  END SUBROUTINE gauss_pyramid

  SUBROUTINE newton_raphson(f, df, x0, tol, max_iter, x, converged)
      INTERFACE
          FUNCTION f(x) RESULT(val)
              USE IF_Prec_Core, ONLY: wp, i4, i8
              REAL(wp), INTENT(IN) :: x
              REAL(wp) :: val
          END FUNCTION f
          FUNCTION df(x) RESULT(val)
              USE IF_Prec_Core, ONLY: wp, i4, i8
              REAL(wp), INTENT(IN) :: x
              REAL(wp) :: val
          END FUNCTION df
      END INTERFACE
      REAL(wp), INTENT(IN) :: x0, tol
      INTEGER(i4), INTENT(IN) :: max_iter
      REAL(wp), INTENT(OUT) :: x
      LOGICAL, INTENT(OUT) :: converged
      INTEGER(i4) :: iter
      x = x0
      converged = .FALSE.
      DO iter = 1, max_iter
          IF (ABS(f(x)) < tol) THEN
              converged = .TRUE.
              RETURN
          END IF
          x = x - f(x) / df(x)
      END DO
  END SUBROUTINE newton_raphson

  SUBROUTINE bisection(f, a, b, tol, max_iter, x, converged)
      INTERFACE
          FUNCTION f(x) RESULT(val)
              USE IF_Prec_Core, ONLY: wp, i4, i8
              REAL(wp), INTENT(IN) :: x
              REAL(wp) :: val
          END FUNCTION f
      END INTERFACE
      REAL(wp), INTENT(IN) :: a, b, tol
      INTEGER(i4), INTENT(IN) :: max_iter
      REAL(wp), INTENT(OUT) :: x
      LOGICAL, INTENT(OUT) :: converged
      INTEGER(i4) :: iter
      REAL(wp) :: fa, fb, fc, c, a_loc, b_loc
      a_loc = a
      b_loc = b
      fa = f(a_loc)
      fb = f(b_loc)
      IF (fa * fb > ZERO) THEN
          converged = .FALSE.
          x = a_loc
          RETURN
      END IF
      converged = .FALSE.
      DO iter = 1, max_iter
          c = (a_loc + b_loc) / TWO
          fc = f(c)
          IF (ABS(fc) < tol .OR. (b_loc - a_loc) / TWO < tol) THEN
              converged = .TRUE.
              x = c
              RETURN
          END IF
          IF (fa * fc < ZERO) THEN
              b_loc = c
              fb = fc
          ELSE
              a_loc = c
              fa = fc
          END IF
      END DO
      x = (a_loc + b_loc) / TWO
  END SUBROUTINE bisection

  SUBROUTINE secant(f, x0, x1, tol, max_iter, x, converged)
      INTERFACE
          FUNCTION f(x) RESULT(val)
              USE IF_Prec_Core, ONLY: wp, i4, i8
              REAL(wp), INTENT(IN) :: x
              REAL(wp) :: val
          END FUNCTION f
      END INTERFACE
      REAL(wp), INTENT(IN) :: x0, x1, tol
      INTEGER(i4), INTENT(IN) :: max_iter
      REAL(wp), INTENT(OUT) :: x
      LOGICAL, INTENT(OUT) :: converged
      INTEGER(i4) :: iter
      REAL(wp) :: f0, f1, x_new, x0_loc, x1_loc
      x0_loc = x0
      x1_loc = x1
      f0 = f(x0_loc)
      f1 = f(x1_loc)
      converged = .FALSE.
      DO iter = 1, max_iter
          IF (ABS(f1) < tol) THEN
              converged = .TRUE.
              x = x1_loc
              RETURN
          END IF
          IF (ABS(x1_loc - x0_loc) < tol) THEN
              converged = .TRUE.
              x = x1_loc
              RETURN
          END IF
          x_new = x1_loc - f1 * (x1_loc - x0_loc) / (f1 - f0)
          x0_loc = x1_loc
          f0 = f1
          x1_loc = x_new
          f1 = f(x1_loc)
      END DO
      x = x1_loc
  END SUBROUTINE secant

  SUBROUTINE newton_system(f, Jacobian, x0, tol, max_iter, x, converged)
      INTERFACE
          SUBROUTINE f(x, fx)
              USE IF_Prec_Core, ONLY: wp, i4, i8
              REAL(wp), INTENT(IN) :: x(:)
              REAL(wp), INTENT(OUT) :: fx(:)
          END SUBROUTINE f
          SUBROUTINE Jacobian(x, Jx)
              USE IF_Prec_Core, ONLY: wp, i4, i8
              REAL(wp), INTENT(IN) :: x(:)
              REAL(wp), INTENT(OUT) :: Jx(:,:)
          END SUBROUTINE Jacobian
      END INTERFACE
      REAL(wp), INTENT(IN) :: x0(:), tol
      INTEGER(i4), INTENT(IN) :: max_iter
      REAL(wp), INTENT(OUT) :: x(:)
      LOGICAL, INTENT(OUT) :: converged
      INTEGER(i4) :: iter, n, i, jj
      REAL(wp), ALLOCATABLE :: fx(:), Jx(:,:), Jinv(:,:), delta(:)
      REAL(wp), ALLOCATABLE :: Jx_copy(:,:), fx_copy(:)
      REAL(wp) :: norm_f, factor
      n = SIZE(x0)
      ALLOCATE(fx(n), Jx(n,n), Jinv(n,n), delta(n))
      x = x0
      converged = .FALSE.
      DO iter = 1, max_iter
          CALL f(x, fx)
          norm_f = sqrt(dot_product(fx, fx))
          IF (norm_f < tol) THEN
              converged = .TRUE.
              DEALLOCATE(fx, Jx, Jinv, delta)
              RETURN
          END IF
          CALL Jacobian(x, Jx)
          IF (n == 3) THEN
              CALL mat_inv_3x3(Jx, Jinv, norm_f)
              IF (ABS(norm_f) < 1.0E-15_wp) THEN
                  converged = .FALSE.
                  DEALLOCATE(fx, Jx, Jinv, delta)
                  RETURN
              END IF
              delta = -matmul(Jinv, fx)
          ELSE
              ALLOCATE(Jx_copy(n,n), fx_copy(n))
              Jx_copy = Jx
              fx_copy = -fx
              DO i = 1, n-1
                  IF (ABS(Jx_copy(i,i)) < 1.0E-15_wp) THEN
                      converged = .FALSE.
                      DEALLOCATE(fx, Jx, Jinv, delta, Jx_copy, fx_copy)
                      RETURN
                  END IF
                  DO jj = i+1, n
                      IF (ABS(Jx_copy(jj,i)) > 1.0E-15_wp) THEN
                          factor = Jx_copy(jj,i) / Jx_copy(i,i)
                          Jx_copy(jj,i:n) = Jx_copy(jj,i:n) - factor * Jx_copy(i,i:n)
                          fx_copy(jj) = fx_copy(jj) - factor * fx_copy(i)
                      END IF
                  END DO
              END DO
              DO i = n, 1, -1
                  delta(i) = fx_copy(i)
                  DO jj = i+1, n
                      delta(i) = delta(i) - Jx_copy(i,jj) * delta(jj)
                  END DO
                  IF (ABS(Jx_copy(i,i)) < 1.0E-15_wp) THEN
                      converged = .FALSE.
                      DEALLOCATE(fx, Jx, Jinv, delta, Jx_copy, fx_copy)
                      RETURN
                  END IF
                  delta(i) = delta(i) / Jx_copy(i,i)
              END DO
              DEALLOCATE(Jx_copy, fx_copy)
          END IF
          x = x + delta
      END DO
      DEALLOCATE(fx, Jx, Jinv, delta)
  END SUBROUTINE newton_system

  SUBROUTINE gauss_seidel(A, b, x0, tol, max_iter, x, iter, converged)
      REAL(wp), INTENT(IN) :: A(:,:)
      REAL(wp), INTENT(IN) :: b(:)
      REAL(wp), INTENT(IN) :: x0(:)
      REAL(wp), INTENT(IN) :: tol
      INTEGER(i4), INTENT(IN) :: max_iter
      REAL(wp), INTENT(OUT) :: x(:)
      INTEGER(i4), INTENT(OUT) :: iter
      LOGICAL, INTENT(OUT) :: converged
      INTEGER(i4) :: n, i, j
      REAL(wp) :: sum_val
      n = SIZE(b)
      x = x0
      converged = .FALSE.
      DO iter = 1, max_iter
          DO i = 1, n
              sum_val = b(i)
              DO j = 1, n
                  IF (j /= i) sum_val = sum_val - A(i,j) * x(j)
              END DO
              x(i) = sum_val / A(i,i)
          END DO
          IF (maxval(abs(matmul(A, x) - b)) < tol) THEN
              converged = .TRUE.
              RETURN
          END IF
      END DO
  END SUBROUTINE gauss_seidel

  SUBROUTINE jacobi_iter(A, b, x0, tol, max_iter, x, iter, converged)
      REAL(wp), INTENT(IN) :: A(:,:)
      REAL(wp), INTENT(IN) :: b(:)
      REAL(wp), INTENT(IN) :: x0(:)
      REAL(wp), INTENT(IN) :: tol
      INTEGER(i4), INTENT(IN) :: max_iter
      REAL(wp), INTENT(OUT) :: x(:)
      INTEGER(i4), INTENT(OUT) :: iter
      LOGICAL, INTENT(OUT) :: converged
      INTEGER(i4) :: n, i, j
      REAL(wp), ALLOCATABLE :: x_old(:)
      REAL(wp) :: sum_val
      n = SIZE(b)
      ALLOCATE(x_old(n))
      x = x0
      converged = .FALSE.
      DO iter = 1, max_iter
          x_old = x
          DO i = 1, n
              sum_val = b(i)
              DO j = 1, n
                  IF (j /= i) sum_val = sum_val - A(i,j) * x_old(j)
              END DO
              x(i) = sum_val / A(i,i)
          END DO
          IF (maxval(abs(x - x_old)) < tol) THEN
              converged = .TRUE.
              DEALLOCATE(x_old)
              RETURN
          END IF
      END DO
      DEALLOCATE(x_old)
  END SUBROUTINE jacobi_iter

  SUBROUTINE interp_line(x_data, y_data, n, x, y, dy)
      REAL(wp), INTENT(IN) :: x_data(:), y_data(:)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(IN) :: x
      REAL(wp), INTENT(OUT) :: y
      REAL(wp), INTENT(OUT), OPTIONAL :: dy
      INTEGER(i4) :: i
      REAL(wp) :: t
      IF (x <= x_data(1)) THEN
          y = y_data(1)
          IF (PRESENT(dy)) dy = (y_data(2) - y_data(1)) / (x_data(2) - x_data(1))
          RETURN
      END IF
      IF (x >= x_data(n)) THEN
          y = y_data(n)
          IF (PRESENT(dy)) dy = (y_data(n) - y_data(n-1)) / (x_data(n) - x_data(n-1))
          RETURN
      END IF
      DO i = 1, n - 1
          IF (x >= x_data(i) .AND. x <= x_data(i+1)) THEN
              t = (x - x_data(i)) / (x_data(i+1) - x_data(i))
              y = (ONE - t) * y_data(i) + t * y_data(i+1)
              IF (PRESENT(dy)) dy = (y_data(i+1) - y_data(i)) / (x_data(i+1) - x_data(i))
              RETURN
          END IF
      END DO
  END SUBROUTINE interp_line

  SUBROUTINE lagrange_interp(x_data, y_data, n, x, y)
      REAL(wp), INTENT(IN) :: x_data(:), y_data(:)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(IN) :: x
      REAL(wp), INTENT(OUT) :: y
      INTEGER(i4) :: i, j
      REAL(wp) :: L
      y = ZERO
      DO i = 1, n
          L = ONE
          DO j = 1, n
              IF (j /= i) L = L * (x - x_data(j)) / (x_data(i) - x_data(j))
          END DO
          y = y + L * y_data(i)
      END DO
  END SUBROUTINE lagrange_interp

  SUBROUTINE spline_interp(x_data, y_data, n, x, y, dy, d2y)
      REAL(wp), INTENT(IN) :: x_data(:), y_data(:)
      INTEGER(i4), INTENT(IN) :: n
      REAL(wp), INTENT(IN) :: x
      REAL(wp), INTENT(OUT) :: y
      REAL(wp), INTENT(OUT), OPTIONAL :: dy, d2y
      INTEGER(i4) :: i, j, k
      REAL(wp) :: h, m, t
      REAL(wp), ALLOCATABLE :: a(:), b(:), c(:), d(:), h_arr(:)
      IF (n < 2) THEN
          y = ZERO
          IF (PRESENT(dy)) dy = ZERO
          IF (PRESENT(d2y)) d2y = ZERO
          RETURN
      END IF
      IF (x <= x_data(1)) THEN
          y = y_data(1)
          IF (PRESENT(dy)) dy = (y_data(2) - y_data(1)) / (x_data(2) - x_data(1))
          IF (PRESENT(d2y)) d2y = ZERO
          RETURN
      END IF
      IF (x >= x_data(n)) THEN
          y = y_data(n)
          IF (PRESENT(dy)) dy = (y_data(n) - y_data(n-1)) / (x_data(n) - x_data(n-1))
          IF (PRESENT(d2y)) d2y = ZERO
          RETURN
      END IF
      ALLOCATE(a(n), b(n), c(n), d(n), h_arr(n-1))
      DO i = 1, n-1
          h_arr(i) = x_data(i+1) - x_data(i)
      END DO
      a(1) = ZERO
      c(1) = ZERO
      DO i = 2, n-1
          a(i) = h_arr(i-1) / (h_arr(i-1) + h_arr(i))
          c(i) = h_arr(i) / (h_arr(i-1) + h_arr(i))
          b(i) = TWO
          d(i) = SIX * ((y_data(i+1) - y_data(i)) / h_arr(i) - &
                        (y_data(i) - y_data(i-1)) / h_arr(i-1)) / &
                        (h_arr(i-1) + h_arr(i))
      END DO
      a(n) = ZERO
      c(n) = ZERO
      DO k = 2, n-1
          DO i = 2, n-k
              m = a(i) / b(i-1)
              b(i) = b(i) - m * c(i-1)
              d(i) = d(i) - m * d(i-1)
          END DO
      END DO
      c(n) = d(n) / b(n)
      DO i = n-1, 2, -1
          c(i) = (d(i) - c(i) * c(i+1)) / b(i)
      END DO
      c(1) = ZERO
      c(n) = ZERO
      DO i = 1, n-1
          a(i) = y_data(i)
          b(i) = (y_data(i+1) - y_data(i)) / h_arr(i) - h_arr(i) * (c(i+1) + TWO * c(i)) / SIX
          d(i) = (c(i+1) - c(i)) / (SIX * h_arr(i))
      END DO
      DO i = 1, n-1
          IF (x >= x_data(i) .AND. x <= x_data(i+1)) THEN
              t = x - x_data(i)
              y = a(i) + b(i) * t + c(i) * t * t + d(i) * t * t * t
              IF (PRESENT(dy)) dy = b(i) + TWO * c(i) * t + THREE * d(i) * t * t
              IF (PRESENT(d2y)) d2y = TWO * c(i) + SIX * d(i) * t
              DEALLOCATE(a, b, c, d, h_arr)
              RETURN
          END IF
      END DO
      DEALLOCATE(a, b, c, d, h_arr)
  END SUBROUTINE spline_interp

END MODULE MD_Base_MathUtils