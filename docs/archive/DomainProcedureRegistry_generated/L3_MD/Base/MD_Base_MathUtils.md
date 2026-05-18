# `MD_Base_MathUtils.f90`

- **Source**: `L3_MD/Base/MD_Base_MathUtils.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Base_MathUtils`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_MathUtils`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_MathUtils`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_MathUtils.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Timer` (lines 215–227)

```fortran
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
```

### `Stopwatch` (lines 229–245)

```fortran
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
```

### `Date` (lines 247–262)

```fortran
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
```

### `Time` (lines 264–280)

```fortran
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
```

### `StringList` (lines 287–290)

```fortran
    TYPE, PRIVATE :: StringList
        CHARACTER(LEN=256), ALLOCATABLE :: strings(:)
        INTEGER(i4) :: count = 0_i4
    END TYPE StringList
```

### `StringTokenizer` (lines 292–295)

```fortran
    TYPE, PRIVATE :: StringTokenizer
        CHARACTER(LEN=256) :: str = ""
        CHARACTER(LEN=16) :: delimiter = " "
    END TYPE StringTokenizer
```

### `StringFormatter` (lines 297–299)

```fortran
    TYPE, PRIVATE :: StringFormatter
        CHARACTER(LEN=256) :: buffer = ""
    END TYPE StringFormatter
```

### `MathUtils` (lines 304–309)

```fortran
    TYPE :: MathUtils
        LOGICAL :: is_initialized = .FALSE.
    CONTAINS
        PROCEDURE :: Init => MathUtils_Init
        PROCEDURE :: Destroy => MathUtils_Destroy
    END TYPE MathUtils
```

### `GaussQuadrature` (lines 311–324)

```fortran
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
```

### `VecOps` (lines 326–339)

```fortran
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
```

### `SparseMatrixUtils` (lines 341–345)

```fortran
    TYPE :: SparseMatrixUtils
        LOGICAL :: is_initialized = .FALSE.
    CONTAINS
        PROCEDURE :: MatVec => Sparse_MatVec_Wrapper
    END TYPE SparseMatrixUtils
```

### `ArraySizeCache` (lines 350–356)

```fortran
    TYPE, PRIVATE :: ArraySizeCache
        CHARACTER(len=64) :: name = ""
        INTEGER(i4) :: cached_size = 0_i4
        INTEGER(i4) :: access_count = 0_i4
        INTEGER(i4) :: last_access_tim = 0_i4
        REAL(wp) :: growth_factor = 1.5_wp
    END TYPE ArraySizeCache
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `ToUpper` | 373 | `PURE FUNCTION ToUpper(str) RESULT(out)` |
| FUNCTION | `ToLower` | 386 | `PURE FUNCTION ToLower(str) RESULT(out)` |
| FUNCTION | `TrimStr` | 399 | `FUNCTION TrimStr(str) RESULT(out)` |
| SUBROUTINE | `SplitStr` | 418 | `SUBROUTINE SplitStr(str, delimiter, parts, n_parts)` |
| FUNCTION | `JoinStr` | 454 | `FUNCTION JoinStr(parts, delimiter) RESULT(str)` |
| FUNCTION | `StrToInt` | 473 | `FUNCTION StrToInt(str, status) RESULT(val)` |
| FUNCTION | `StrToReal` | 481 | `FUNCTION StrToReal(str, status) RESULT(val)` |
| FUNCTION | `IntToStr` | 490 | `FUNCTION IntToStr(val) RESULT(str)` |
| FUNCTION | `RealToStr` | 497 | `FUNCTION RealToStr(val, fmt) RESULT(str)` |
| FUNCTION | `StrContains` | 509 | `FUNCTION StrContains(str, substr) RESULT(found)` |
| FUNCTION | `StrStartsWith` | 516 | `FUNCTION StrStartsWith(str, prefix) RESULT(found)` |
| FUNCTION | `StrEndsWith` | 527 | `FUNCTION StrEndsWith(str, suffix) RESULT(found)` |
| FUNCTION | `StrReplace` | 541 | `FUNCTION StrReplace(str, old, new) RESULT(result)` |
| SUBROUTINE | `Timer_Start` | 569 | `SUBROUTINE Timer_Start(this)` |
| SUBROUTINE | `Timer_Stop` | 575 | `SUBROUTINE Timer_Stop(this)` |
| SUBROUTINE | `Timer_Reset` | 582 | `SUBROUTINE Timer_Reset(this)` |
| FUNCTION | `Timer_IsRunning` | 590 | `FUNCTION Timer_IsRunning(this) RESULT(running)` |
| FUNCTION | `Timer_GetElapsedTime` | 596 | `FUNCTION Timer_GetElapsedTime(this) RESULT(elapsed)` |
| FUNCTION | `Timer_GetElapsedSeconds` | 610 | `FUNCTION Timer_GetElapsedSeconds(this) RESULT(seconds)` |
| SUBROUTINE | `Stopwatch_Start` | 622 | `SUBROUTINE Stopwatch_Start(this)` |
| SUBROUTINE | `Stopwatch_Stop` | 632 | `SUBROUTINE Stopwatch_Stop(this)` |
| SUBROUTINE | `Stopwatch_Reset` | 643 | `SUBROUTINE Stopwatch_Reset(this)` |
| SUBROUTINE | `Stopwatch_Lap` | 652 | `SUBROUTINE Stopwatch_Lap(this)` |
| FUNCTION | `Stopwatch_IsRunning` | 666 | `FUNCTION Stopwatch_IsRunning(this) RESULT(running)` |
| FUNCTION | `Stopwatch_GetTotalTime` | 672 | `FUNCTION Stopwatch_GetTotalTime(this) RESULT(total)` |
| FUNCTION | `Stopwatch_GetLapTime` | 685 | `FUNCTION Stopwatch_GetLapTime(this) RESULT(lap)` |
| FUNCTION | `Stopwatch_GetLapCount` | 700 | `FUNCTION Stopwatch_GetLapCount(this) RESULT(count)` |
| FUNCTION | `Stopwatch_GetAverageLapTime` | 706 | `FUNCTION Stopwatch_GetAverageLapTime(this) RESULT(avg)` |
| SUBROUTINE | `Date_Init` | 719 | `SUBROUTINE Date_Init(this, year, month, day)` |
| SUBROUTINE | `Date_Set` | 727 | `SUBROUTINE Date_Set(this, year, month, day)` |
| SUBROUTINE | `Date_Get` | 735 | `SUBROUTINE Date_Get(this, year, month, day)` |
| FUNCTION | `DaysInMonth` | 744 | `PURE FUNCTION DaysInMonth(year, month) RESULT(days)` |
| FUNCTION | `Date_IsValid` | 758 | `FUNCTION Date_IsValid(this) RESULT(valid)` |
| SUBROUTINE | `Date_AddDays` | 770 | `SUBROUTINE Date_AddDays(this, days)` |
| SUBROUTINE | `Date_AddMonths` | 789 | `SUBROUTINE Date_AddMonths(this, months)` |
| SUBROUTINE | `Date_AddYears` | 811 | `SUBROUTINE Date_AddYears(this, years)` |
| FUNCTION | `Date_Difference` | 817 | `FUNCTION Date_Difference(this, other) RESULT(diff)` |
| FUNCTION | `Date_ToString` | 823 | `FUNCTION Date_ToString(this) RESULT(str)` |
| SUBROUTINE | `Date_FromString` | 829 | `SUBROUTINE Date_FromString(this, str)` |
| SUBROUTINE | `Time_Init` | 838 | `SUBROUTINE Time_Init(this, hour, minute, second, millisecond)` |
| SUBROUTINE | `Time_Set` | 848 | `SUBROUTINE Time_Set(this, hour, minute, second, millisecond)` |
| SUBROUTINE | `Time_Get` | 858 | `SUBROUTINE Time_Get(this, hour, minute, second, millisecond)` |
| FUNCTION | `Time_IsValid` | 868 | `FUNCTION Time_IsValid(this) RESULT(valid)` |
| SUBROUTINE | `Time_AddSeconds` | 877 | `SUBROUTINE Time_AddSeconds(this, seconds)` |
| SUBROUTINE | `Time_AddMinutes` | 895 | `SUBROUTINE Time_AddMinutes(this, minutes)` |
| SUBROUTINE | `Time_AddHours` | 913 | `SUBROUTINE Time_AddHours(this, hours)` |
| FUNCTION | `Time_Difference` | 923 | `FUNCTION Time_Difference(this, other) RESULT(diff)` |
| FUNCTION | `Time_ToString` | 929 | `FUNCTION Time_ToString(this) RESULT(str)` |
| SUBROUTINE | `Time_FromString` | 935 | `SUBROUTINE Time_FromString(this, str)` |
| SUBROUTINE | `SortInt` | 949 | `SUBROUTINE SortInt(a, n)` |
| SUBROUTINE | `SortReal` | 969 | `SUBROUTINE SortReal(a, n)` |
| SUBROUTINE | `UniqueInt` | 985 | `SUBROUTINE UniqueInt(a, n, unique_a, n_unique)` |
| SUBROUTINE | `UniqueReal` | 1006 | `SUBROUTINE UniqueReal(a, n, unique_a, n_unique, tol)` |
| FUNCTION | `FindInt` | 1034 | `FUNCTION FindInt(a, n, val) RESULT(idx)` |
| FUNCTION | `FindReal` | 1048 | `FUNCTION FindReal(a, n, val, tol) RESULT(idx)` |
| FUNCTION | `CountInt` | 1069 | `FUNCTION CountInt(a, n, val) RESULT(cnt)` |
| FUNCTION | `CountReal` | 1080 | `FUNCTION CountReal(a, n, val, tol) RESULT(cnt)` |
| FUNCTION | `SumInt` | 1098 | `FUNCTION SumInt(a, n) RESULT(s)` |
| FUNCTION | `SumReal` | 1105 | `FUNCTION SumReal(a, n) RESULT(s)` |
| FUNCTION | `MeanReal` | 1112 | `FUNCTION MeanReal(a, n) RESULT(m)` |
| FUNCTION | `StdDevReal` | 1123 | `FUNCTION StdDevReal(a, n) RESULT(sd)` |
| FUNCTION | `MinInt` | 1135 | `FUNCTION MinInt(a, n) RESULT(val)` |
| FUNCTION | `MinReal` | 1142 | `FUNCTION MinReal(a, n) RESULT(val)` |
| FUNCTION | `MaxInt` | 1149 | `FUNCTION MaxInt(a, n) RESULT(val)` |
| FUNCTION | `MaxReal` | 1156 | `FUNCTION MaxReal(a, n) RESULT(val)` |
| SUBROUTINE | `smart_allocate_1d` | 1168 | `SUBROUTINE smart_allocate_1d(arr, required_size, growth_factor, status)` |
| SUBROUTINE | `smart_allocate_2d` | 1210 | `SUBROUTINE smart_allocate_2d(arr, required_size1, required_size2, growth_factor, status)` |
| SUBROUTINE | `smart_allocate_int1d` | 1251 | `SUBROUTINE smart_allocate_int1d(arr, required_size, growth_factor, status)` |
| SUBROUTINE | `smart_allocate_int2d` | 1289 | `SUBROUTINE smart_allocate_int2d(arr, required_size1, required_size2, growth_factor, status)` |
| SUBROUTINE | `smart_grow_real_vector` | 1333 | `SUBROUTINE smart_grow_real_vector(arr, required_size, growth_factor, status)` |
| SUBROUTINE | `smart_grow_int_vector` | 1341 | `SUBROUTINE smart_grow_int_vector(arr, required_size, growth_factor, status)` |
| SUBROUTINE | `smart_grow_real_Mtx` | 1349 | `SUBROUTINE smart_grow_real_Mtx(arr, required_size1, required_size2, growth_factor, status)` |
| SUBROUTINE | `cache_array_size` | 1357 | `SUBROUTINE cache_array_size(name, size_val)` |
| FUNCTION | `get_cached_size` | 1406 | `FUNCTION get_cached_size(name, default_size) RESULT(cached_val)` |
| SUBROUTINE | `predictive_preallocate_real1d` | 1427 | `SUBROUTINE predictive_preallocate_real1d(arr, name, estimated_size, status)` |
| SUBROUTINE | `adaptive_growth_factor` | 1460 | `SUBROUTINE adaptive_growth_factor(name, actual_size, requested_size, new_factor)` |
| SUBROUTINE | `Array_Append_Int1D` | 1506 | `SUBROUTINE Array_Append_Int1D(array, n, val)` |
| SUBROUTINE | `Array_Append_Int2D` | 1523 | `SUBROUTINE Array_Append_Int2D(array, n1, n2, val)` |
| SUBROUTINE | `Array_Append_DP1D` | 1541 | `SUBROUTINE Array_Append_DP1D(array, n, val)` |
| SUBROUTINE | `Array_Append_DP2D` | 1558 | `SUBROUTINE Array_Append_DP2D(array, n1, n2, val)` |
| SUBROUTINE | `MathUtils_Init` | 1576 | `SUBROUTINE MathUtils_Init(this, status)` |
| SUBROUTINE | `MathUtils_Destroy` | 1583 | `SUBROUTINE MathUtils_Destroy(this, status)` |
| SUBROUTINE | `GaussQuadrature_Init` | 1590 | `SUBROUTINE GaussQuadrature_Init(this, element_type, npts, status)` |
| SUBROUTINE | `GaussQuadrature_Destroy` | 1602 | `SUBROUTINE GaussQuadrature_Destroy(this, status)` |
| SUBROUTINE | `GaussQuadrature_Setup` | 1611 | `SUBROUTINE GaussQuadrature_Setup(this, status)` |
| FUNCTION | `GaussQuadrature_GetPoints` | 1709 | `FUNCTION GaussQuadrature_GetPoints(this) RESULT(pts)` |
| FUNCTION | `GaussQuadrature_GetWeights` | 1715 | `FUNCTION GaussQuadrature_GetWeights(this) RESULT(wts)` |
| SUBROUTINE | `VecOps_Init` | 1721 | `SUBROUTINE VecOps_Init(this, size)` |
| SUBROUTINE | `VecOps_Destroy` | 1728 | `SUBROUTINE VecOps_Destroy(this)` |
| FUNCTION | `VecOps_Dot` | 1734 | `FUNCTION VecOps_Dot(this, a, b) RESULT(res)` |
| FUNCTION | `VecOps_Norm2` | 1741 | `FUNCTION VecOps_Norm2(this, a) RESULT(res)` |
| SUBROUTINE | `VecOps_Scale` | 1748 | `SUBROUTINE VecOps_Scale(this, a, x)` |
| SUBROUTINE | `VecOps_Axpy` | 1755 | `SUBROUTINE VecOps_Axpy(this, a, x, y)` |
| SUBROUTINE | `VecOps_Add` | 1762 | `SUBROUTINE VecOps_Add(this, x, y, z)` |
| SUBROUTINE | `VecOps_Subtract` | 1769 | `SUBROUTINE VecOps_Subtract(this, x, y, z)` |
| SUBROUTINE | `VecOps_Cross` | 1776 | `SUBROUTINE VecOps_Cross(this, a, b, c)` |
| SUBROUTINE | `Sparse_MatVec_Wrapper` | 1783 | `SUBROUTINE Sparse_MatVec_Wrapper(this, A, x, y)` |
| FUNCTION | `vec_dot` | 1790 | `FUNCTION vec_dot(a, b) RESULT(res)` |
| SUBROUTINE | `vec_axpy` | 1796 | `SUBROUTINE vec_axpy(a, x, y)` |
| FUNCTION | `vec_norm2` | 1802 | `FUNCTION vec_norm2(a) RESULT(res)` |
| SUBROUTINE | `vec_scale` | 1808 | `SUBROUTINE vec_scale(a, x)` |
| SUBROUTINE | `vec_copy` | 1814 | `SUBROUTINE vec_copy(x, y)` |
| SUBROUTINE | `vec_zero` | 1820 | `SUBROUTINE vec_zero(x)` |
| SUBROUTINE | `vec_add` | 1825 | `SUBROUTINE vec_add(x, y, z)` |
| SUBROUTINE | `vec_sub` | 1831 | `SUBROUTINE vec_sub(x, y, z)` |
| SUBROUTINE | `vec_cross_3d` | 1837 | `SUBROUTINE vec_cross_3d(a, b, c)` |
| SUBROUTINE | `mat_vec` | 1845 | `SUBROUTINE mat_vec(A, x, y)` |
| SUBROUTINE | `mat_mat` | 1851 | `SUBROUTINE mat_mat(A, B, C)` |
| SUBROUTINE | `mat_trans` | 1857 | `SUBROUTINE mat_trans(A, At)` |
| SUBROUTINE | `mat_inv_3x3` | 1863 | `SUBROUTINE mat_inv_3x3(A, Ainv, det)` |
| SUBROUTINE | `gauss_line` | 1887 | `SUBROUTINE gauss_line(n, xi, w)` |
| SUBROUTINE | `gauss_triangle` | 1909 | `SUBROUTINE gauss_triangle(n, xi, eta, w)` |
| SUBROUTINE | `gauss_quad` | 1930 | `SUBROUTINE gauss_quad(n, xi, eta, w)` |
| SUBROUTINE | `gauss_tetrahedron` | 1948 | `SUBROUTINE gauss_tetrahedron(n, xi, eta, zeta, w)` |
| SUBROUTINE | `gauss_hexahedron` | 2022 | `SUBROUTINE gauss_hexahedron(n, xi, eta, zeta, w)` |
| SUBROUTINE | `gauss_prism` | 2043 | `SUBROUTINE gauss_prism(n_tri, n_line, xi, eta, zeta, w)` |
| SUBROUTINE | `gauss_pyramid` | 2067 | `SUBROUTINE gauss_pyramid(n_quad, n_line, xi, eta, zeta, w)` |
| SUBROUTINE | `newton_raphson` | 2092 | `SUBROUTINE newton_raphson(f, df, x0, tol, max_iter, x, converged)` |
| FUNCTION | `f` | 2094 | `FUNCTION f(x) RESULT(val)` |
| FUNCTION | `df` | 2099 | `FUNCTION df(x) RESULT(val)` |
| SUBROUTINE | `bisection` | 2121 | `SUBROUTINE bisection(f, a, b, tol, max_iter, x, converged)` |
| FUNCTION | `f` | 2123 | `FUNCTION f(x) RESULT(val)` |
| SUBROUTINE | `secant` | 2164 | `SUBROUTINE secant(f, x0, x1, tol, max_iter, x, converged)` |
| FUNCTION | `f` | 2166 | `FUNCTION f(x) RESULT(val)` |
| SUBROUTINE | `newton_system` | 2203 | `SUBROUTINE newton_system(f, Jacobian, x0, tol, max_iter, x, converged)` |
| SUBROUTINE | `f` | 2205 | `SUBROUTINE f(x, fx)` |
| SUBROUTINE | `Jacobian` | 2210 | `SUBROUTINE Jacobian(x, Jx)` |
| SUBROUTINE | `gauss_seidel` | 2282 | `SUBROUTINE gauss_seidel(A, b, x0, tol, max_iter, x, iter, converged)` |
| SUBROUTINE | `jacobi_iter` | 2311 | `SUBROUTINE jacobi_iter(A, b, x0, tol, max_iter, x, iter, converged)` |
| SUBROUTINE | `interp_line` | 2345 | `SUBROUTINE interp_line(x_data, y_data, n, x, y, dy)` |
| SUBROUTINE | `lagrange_interp` | 2373 | `SUBROUTINE lagrange_interp(x_data, y_data, n, x, y)` |
| SUBROUTINE | `spline_interp` | 2390 | `SUBROUTINE spline_interp(x_data, y_data, n, x, y, dy, d2y)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 363–366 | `INTERFACE smart_allocate` |
| 2093–2104 | `INTERFACE` |
| 2122–2128 | `INTERFACE` |
| 2165–2171 | `INTERFACE` |
| 2204–2215 | `INTERFACE` |
