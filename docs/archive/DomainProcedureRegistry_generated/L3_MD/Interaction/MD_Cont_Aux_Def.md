# `MD_Cont_Aux_Def.f90`

- **Source**: `L3_MD/Interaction/MD_Cont_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Cont_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Cont_Aux_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Cont_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Cont_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Cont_Stp_Ctl_Algo` (lines 46–77)

```fortran
  TYPE, PUBLIC :: MD_Cont_Stp_Ctl_Algo
    ! --- Enforcement method ---
    INTEGER(i4) :: enforcement_method = MD_CONT_ENFORCE_PENALTY  ! PH_LDBC_BC_* aligned
    INTEGER(i4) :: sliding_type      = MD_CONT_SLIDE_SMALL       ! Small / Finite

    ! --- Penalty parameters ---
    REAL(wp)    :: penalty_normal    = 1.0E6_wp    ! Normal penalty stiffness
    REAL(wp)    :: penalty_tangent   = 1.0E5_wp    ! Tangent penalty stiffness
    REAL(wp)    :: penalty_scale     = 1.0_wp      ! Penalty scale factor
    LOGICAL     :: auto_penalty      = .TRUE.      ! Automatic penalty calculation

    ! --- Augmented Lagrange parameters ---
    REAL(wp)    :: lagrange_tol      = 1.0E-8_wp   ! Lagrange multiplier convergence
    INTEGER(i4) :: max_aug_iter      = 20_i4       ! Max AugLag iterations per step
    REAL(wp)    :: rho_aug           = 1.0_wp      ! AugLag update factor

    ! --- Search parameters ---
    INTEGER(i4) :: search_strategy   = MD_CONT_SEARCH_BVH    ! Search algorithm
    REAL(wp)    :: search_radius     = 0.0_wp                ! Contact detection radius
    INTEGER(i4) :: max_search_iter   = 10_i4                 ! Max search iterations
    LOGICAL     :: adjust_midplane   = .FALSE.               ! Adjust midplane for shells

    ! --- Friction switch ---
    LOGICAL     :: include_friction  = .TRUE.                ! Include friction flag
    REAL(wp)    :: friction_coeff    = 0.3_wp                ! Coulomb friction coeff
    REAL(wp)    :: tolerance_gap     = 1.0E-6_wp             ! Gap tolerance
    REAL(wp)    :: tolerance_slip    = 1.0E-8_wp             ! Slip tolerance

    ! --- Stabilization ---
    LOGICAL     :: use_stabilization = .FALSE.               ! Contact stabilization
    REAL(wp)    :: stab_factor       = 0.0_wp                ! Stabilization factor
  END TYPE MD_Cont_Stp_Ctl_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
