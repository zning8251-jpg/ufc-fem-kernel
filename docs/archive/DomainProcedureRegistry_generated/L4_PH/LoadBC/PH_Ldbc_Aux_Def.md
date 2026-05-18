# `PH_Ldbc_Aux_Def.f90`

- **Source**: `L4_PH/LoadBC/PH_Ldbc_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Ldbc_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Ldbc_Aux_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Ldbc_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Ldbc_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Ldbc_Stp_Ctl_Algo` (lines 41–66)

```fortran
  TYPE, PUBLIC :: PH_Ldbc_Stp_Ctl_Algo
    ! --- BC enforcement ---
    INTEGER(i4) :: bc_method       = PH_LDBC_BC_PENALTY    ! Enforcement method (PH_LDBC_BC_*)
    REAL(wp)    :: penalty_param   = 1.0E12_wp             ! Penalty stiffness multiplier
    REAL(wp)    :: lagrange_tol    = 1.0E-8_wp             ! Lagrange multiplier convergence

    ! --- Load quadrature ---
    INTEGER(i4) :: quad_order      = PH_LDBC_QUAD_GAUSS_2  ! Gauss quadrature order
    LOGICAL     :: use_follower    = .FALSE.               ! Follower (pressure) loads
    LOGICAL     :: use_nodal_proj  = .TRUE.                ! Project distributed loads to nodes

    ! --- Amplitude ---
    LOGICAL     :: use_amplitude   = .TRUE.                ! Amplitude curve interpolation
    INTEGER(i4) :: amp_interp      = 1_i4                  ! 1=linear, 2=smooth, 3=step

    ! --- Convergence ---
    REAL(wp)    :: load_tol        = 1.0E-6_wp             ! Force residual tolerance
    REAL(wp)    :: disp_tol        = 1.0E-6_wp             ! Displacement tolerance
    INTEGER(i4) :: conv_norm       = PH_LDBC_NORM_L2       ! Convergence norm type

    ! --- Cutback / adaptive ---
    LOGICAL     :: auto_cutback    = .TRUE.                ! Automatic step cutback on divergence
    INTEGER(i4) :: max_cutbacks    = 5_i4                  ! Max cutbacks per increment
    REAL(wp)    :: cutback_factor  = 0.25_wp               ! dt reduction factor on cutback
    REAL(wp)    :: growth_factor   = 1.5_wp                ! dt increase factor on convergence
  END TYPE PH_Ldbc_Stp_Ctl_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
