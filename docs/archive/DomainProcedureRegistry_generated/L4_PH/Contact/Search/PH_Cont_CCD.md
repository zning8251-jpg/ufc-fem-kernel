# `PH_Cont_CCD.f90`

- **Source**: `L4_PH/Contact/Search/PH_Cont_CCD.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_CCD`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_CCD`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_CCD`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Search`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Search/PH_Cont_CCD.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ContCCD_Trajectory` (lines 48–57)

```fortran
  TYPE :: PH_ContCCD_Trajectory
    ! Quadratic trajectory: x(t) = x0 + v0*t + 0.5*a*t^2
    REAL(wp) :: x0(3)      ! Initial position
    REAL(wp) :: v0(3)      ! Initial velocity
    REAL(wp) :: a(3)       ! Acceleration (constant)
    REAL(wp) :: dt         ! Time step
  CONTAINS
    PROCEDURE :: Position => Trajectory_Position
    PROCEDURE :: Velocity => Trajectory_Velocity
  END TYPE PH_ContCCD_Trajectory
```

### `PH_ContCCD_SweptVolume` (lines 59–65)

```fortran
  TYPE :: PH_ContCCD_SweptVolume
    ! Bounding volume swept along trajectory
    REAL(wp) :: bbox_min(3)  ! Swept bounding box min
    REAL(wp) :: bbox_max(3)  ! Swept bounding box max
    REAL(wp) :: radius       ! Sphere radius (if applicable)
    LOGICAL :: is_valid      ! Volume validity flag
  END TYPE PH_ContCCD_SweptVolume
```

### `PH_ContCCD_TOIResult` (lines 67–75)

```fortran
  TYPE :: PH_ContCCD_TOIResult
    ! Time of Impact result
    REAL(wp) :: toi          ! Time of impact [0, dt]
    REAL(wp) :: gap          ! Gap at TOI
    REAL(wp) :: normal(3)    ! Contact normal at TOI
    REAL(wp) :: point(3)     ! Contact point at TOI
    LOGICAL :: impacted      ! Impact detected flag
    INTEGER(i4) :: iterations ! Newton iterations used
  END TYPE PH_ContCCD_TOIResult
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `Trajectory_Position` | 83 | `FUNCTION Trajectory_Position(this, t) RESULT(x)` |
| FUNCTION | `Trajectory_Velocity` | 91 | `FUNCTION Trajectory_Velocity(this, t) RESULT(v)` |
| SUBROUTINE | `PH_ContCCD_ComputeTOI` | 103 | `SUBROUTINE PH_ContCCD_ComputeTOI(traj1, traj2, radius1, radius2, &` |
| SUBROUTINE | `PH_ContCCD_SweptSphere` | 180 | `SUBROUTINE PH_ContCCD_SweptSphere(center0, center1, radius, volume, status)` |
| SUBROUTINE | `PH_ContCCD_ConservativeAdvancement` | 207 | `SUBROUTINE PH_ContCCD_ConservativeAdvancement(dist, vel_rel, dt_max, &` |
| SUBROUTINE | `PH_ContCCD_BinarySearch` | 233 | `SUBROUTINE PH_ContCCD_BinarySearch(traj1, traj2, radius1, radius2, &` |
| SUBROUTINE | `PH_ContCCD_NewtonRaphson` | 282 | `SUBROUTINE PH_ContCCD_NewtonRaphson(traj1, traj2, radius1, radius2, &` |
| SUBROUTINE | `PH_ContCCD_Detect_EdgeEdge` | 339 | `SUBROUTINE PH_ContCCD_Detect_EdgeEdge(edge1_p0, edge1_p1, edge2_p0, edge2_p1, &` |
| SUBROUTINE | `PH_ContCCD_Detect_PointTriangle` | 436 | `SUBROUTINE PH_ContCCD_Detect_PointTriangle(point, tri1, tri2, tri3, &` |
| FUNCTION | `TripleProduct` | 533 | `PURE FUNCTION TripleProduct(a, b, c) RESULT(tp)` |
| SUBROUTINE | `BisectCubicRoot` | 542 | `SUBROUTINE BisectCubicRoot(a0, a1, b0, b1, d0, d1, t_lo, t_hi, tol, t_root)` |
| SUBROUTINE | `BisectTripleRoot` | 567 | `SUBROUTINE BisectTripleRoot(d0, d1, e10, e11, e20, e21, t_lo, t_hi, tol, t_root)` |
| SUBROUTINE | `EvaluateGap` | 592 | `SUBROUTINE EvaluateGap(traj1, traj2, radius1, radius2, t, gap)` |
| SUBROUTINE | `EvaluateGapAndDeriv` | 611 | `SUBROUTINE EvaluateGapAndDeriv(traj1, traj2, radius1, radius2, t, gap, deriv)` |
| SUBROUTINE | `ComputeContactData` | 643 | `PURE SUBROUTINE ComputeContactData(traj1, traj2, t, normal, point)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
