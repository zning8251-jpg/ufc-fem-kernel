# `PH_LoadBC_Def.f90`

- **Source**: `L4_PH/LoadBC/PH_LoadBC_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_LoadBC_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_LoadBC_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_LoadBC`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_LoadBC_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_LoadBC_Desc` (lines 35–47)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Desc
    INTEGER(i4) :: load_type     = 0          ! LOAD_* enum
    INTEGER(i4) :: ndof          = 0          ! total DOF count
    INTEGER(i4) :: nn            = 0          ! number of element nodes
    INTEGER(i4) :: ndof_per_node = 3          ! DOF per node
    INTEGER(i4) :: dof_dir       = 1          ! DOF direction for distributed load
    INTEGER(i4) :: dof           = 0          ! target DOF for concentrated/Dirichlet
    REAL(wp)    :: value         = 0.0_wp     ! load/BC value
    REAL(wp)    :: amp_factor    = 1.0_wp     ! amplitude factor
    REAL(wp)    :: pressure      = 0.0_wp     ! pressure value
    REAL(wp)    :: rho           = 0.0_wp     ! density for gravity
    REAL(wp)    :: big_num       = 1.0E20_wp  ! penalty number for Dirichlet
  END TYPE PH_LoadBC_Desc
```

### `PH_LoadBC_Ctx` (lines 52–62)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Ctx
    REAL(wp) :: Fe(192)      = 0.0_wp   ! element force vector (max 8 nodes * 24 DOF)
    REAL(wp) :: N_shape(27)  = 0.0_wp   ! shape functions at integration point
    REAL(wp) :: normal(3)    = 0.0_wp   ! surface normal
    REAL(wp) :: body_force(3)= 0.0_wp   ! body force vector
    REAL(wp) :: g_vec(3)     = 0.0_wp   ! gravity vector
    REAL(wp) :: D_mat(6,6)   = 0.0_wp   ! material stiffness for thermal
    REAL(wp) :: eps_th(6)    = 0.0_wp   ! thermal strain
    REAL(wp) :: area         = 0.0_wp   ! element face area
    REAL(wp) :: volume       = 0.0_wp   ! element volume
  END TYPE PH_LoadBC_Ctx
```

### `PH_LoadBC_State` (lines 67–73)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_State
    LOGICAL     :: loads_applied = .FALSE.
    LOGICAL     :: bcs_applied   = .FALSE.
    INTEGER(i4) :: n_active_loads = 0
    INTEGER(i4) :: n_active_bcs   = 0
    INTEGER(i4) :: current_step   = 0
  END TYPE PH_LoadBC_State
```

### `PH_LoadBC_Algo` (lines 79–86)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Algo
    TYPE(PH_Ldbc_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] step-level control
    INTEGER(i4) :: bc_method       = 1_i4    ! 1=Penalty, 2=Lagrange, 3=Elimination (legacy, use stp_ctl%bc_method)
    REAL(wp)    :: penalty_param   = 1.0E12_wp ! legacy, use stp_ctl%penalty_param
    INTEGER(i4) :: quad_order      = 2_i4    ! Gauss quadrature order for loads (legacy, use stp_ctl%quad_order)
    LOGICAL     :: use_follower    = .FALSE. ! follower (pressure) loads (legacy, use stp_ctl%use_follower)
    LOGICAL     :: use_amplitude   = .TRUE.  ! amplitude curve interpolation (legacy, use stp_ctl%use_amplitude)
  END TYPE PH_LoadBC_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
