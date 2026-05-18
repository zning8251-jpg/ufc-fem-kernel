# `PH_Cont_NTS_Eval.f90`

- **Source**: `L4_PH/Contact/Core/PH_Cont_NTS_Eval.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_NTS_Eval`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_NTS_Eval`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_NTS`
- **第四段角色（四段式）**: `_Eval`
- **源码子路径（层下目录，不含文件名）**: `Contact/Core`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Core/PH_Cont_NTS_Eval.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_NTS_Pair` (lines 63–77)

```fortran
  TYPE, PUBLIC :: PH_NTS_Pair
    INTEGER(i4) :: slave_node              ! Slave node global ID
    INTEGER(i4) :: master_face(NTS_MAX_FACE_NODES) ! Master face node IDs
    INTEGER(i4) :: n_master_nodes = 4_i4   ! Actual master face node count (4 or 8)
    REAL(wp)    :: xi(2) = 0.0_wp          ! Projected natural coordinates (xi, eta)
    REAL(wp)    :: gap_n = 0.0_wp          ! Normal gap (>0: open, <=0: penetration)
    REAL(wp)    :: gap_t(2) = 0.0_wp       ! Tangential slip increments
    REAL(wp)    :: normal(3) = 0.0_wp      ! Contact normal at projection point
    REAL(wp)    :: force_n = 0.0_wp        ! Normal contact force
    REAL(wp)    :: force_t(2) = 0.0_wp     ! Tangential friction force
    REAL(wp)    :: force_t_prev(2) = 0.0_wp ! Previous step tangential force (for return map)
    LOGICAL     :: active  = .FALSE.       ! Pair active flag
    LOGICAL     :: sliding = .FALSE.       ! Sliding (TRUE) / stick (FALSE) state
    INTEGER(i4) :: status  = NTS_STATUS_OPEN ! Contact status enum
  END TYPE PH_NTS_Pair
```

### `PH_NTS_Cfg_Penalty` (lines 83–86)

```fortran
  TYPE, PUBLIC :: PH_NTS_Cfg_Penalty
    REAL(wp) :: eps_n     = 1.0E6_wp       ! Normal penalty parameter [N/m^3]
    REAL(wp) :: eps_t     = 1.0E5_wp       ! Tangential penalty parameter [N/m^3]
  END TYPE PH_NTS_Cfg_Penalty
```

### `PH_NTS_Cfg_Friction` (lines 88–90)

```fortran
  TYPE, PUBLIC :: PH_NTS_Cfg_Friction
    REAL(wp) :: mu        = 0.3_wp         ! Friction coefficient (Coulomb)
  END TYPE PH_NTS_Cfg_Friction
```

### `PH_NTS_Cfg_Proj` (lines 92–95)

```fortran
  TYPE, PUBLIC :: PH_NTS_Cfg_Proj
    REAL(wp) :: tol_proj  = 1.0E-10_wp     ! Projection convergence tolerance
    INTEGER(i4) :: max_iter_proj = 20_i4   ! Projection max NR iterations
  END TYPE PH_NTS_Cfg_Proj
```

### `PH_NTS_Cfg_Adapt` (lines 97–101)

```fortran
  TYPE, PUBLIC :: PH_NTS_Cfg_Adapt
    REAL(wp) :: gap_tol   = 1.0E-6_wp      ! Max allowed penetration for penalty adjust
    REAL(wp) :: beta_grow = 5.0_wp         ! Penalty increase factor when penetration too large
    REAL(wp) :: gamma_cut = 2.0_wp         ! Penalty decrease factor on convergence difficulty
  END TYPE PH_NTS_Cfg_Adapt
```

### `PH_NTS_Props` (lines 103–109)

```fortran
  TYPE, PUBLIC :: PH_NTS_Props
    TYPE(PH_NTS_Cfg_Penalty) :: penalty
    TYPE(PH_NTS_Cfg_Friction) :: friction
    TYPE(PH_NTS_Cfg_Proj)    :: proj
    TYPE(PH_NTS_Cfg_Adapt)   :: adapt
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_NTS_Props
```

### `PH_Cont_NTS_Eval_Arg` (lines 115–123)

```fortran
  TYPE, PUBLIC :: PH_Cont_NTS_Eval_Arg
    ! --- IN ---
    REAL(wp) :: master_coords(3, NTS_MAX_FACE_NODES) = 0.0_wp  ! [IN] Master face coords
    REAL(wp) :: x_slave(3) = 0.0_wp                            ! [IN] Slave node position
    ! --- OUT ---
    REAL(wp), ALLOCATABLE :: f_nodal(:)             ! [OUT] Equivalent nodal forces
    REAL(wp), ALLOCATABLE :: K_contact(:,:)         ! [OUT] Contact stiffness
    INTEGER(i4) :: n_dof = 0_i4                     ! [OUT] DOF count
  END TYPE PH_Cont_NTS_Eval_Arg
```

### `PH_Cont_NTS_Search_Arg` (lines 129–139)

```fortran
  TYPE, PUBLIC :: PH_Cont_NTS_Search_Arg
    ! --- IN ---
    REAL(wp), ALLOCATABLE :: slave_nodes(:,:)        ! [IN] Slave node coords (3, n_slaves)
    INTEGER(i4) :: n_slaves = 0_i4                   ! [IN] Number of slave nodes
    REAL(wp), ALLOCATABLE :: master_coords(:,:,:)    ! [IN] Master face coords (3, max, n_faces)
    INTEGER(i4) :: n_master_faces = 0_i4             ! [IN] Number of master faces
    INTEGER(i4) :: max_candidates = 0_i4             ! [IN] Max capacity
    ! --- OUT ---
    TYPE(PH_NTS_Pair), ALLOCATABLE :: candidate_pairs(:) ! [OUT] Candidate pairs
    INTEGER(i4) :: n_candidates = 0_i4               ! [OUT] Number found
  END TYPE PH_Cont_NTS_Search_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_NTS_ProjectNode` | 155 | `SUBROUTINE PH_NTS_ProjectNode(x_slave, master_coords, n_master_nodes, &` |
| SUBROUTINE | `PH_NTS_ComputeGap` | 257 | `SUBROUTINE PH_NTS_ComputeGap(x_slave, master_coords, n_master_nodes, &` |
| SUBROUTINE | `PH_NTS_PenaltyForce` | 324 | `SUBROUTINE PH_NTS_PenaltyForce(pair, props, f_nodal, n_dof, status)` |
| SUBROUTINE | `PH_NTS_FrictionReturn` | 385 | `SUBROUTINE PH_NTS_FrictionReturn(pair, props, delta_g_t, status)` |
| SUBROUTINE | `PH_NTS_ContactStiffness` | 433 | `SUBROUTINE PH_NTS_ContactStiffness(pair, props, K_contact, n_dof, status)` |
| SUBROUTINE | `PH_NTS_EvalPair` | 562 | `SUBROUTINE PH_NTS_EvalPair(pair, props, master_coords, x_slave, &` |
| SUBROUTINE | `PH_NTS_SearchBVH` | 632 | `SUBROUTINE PH_NTS_SearchBVH(slave_nodes, n_slaves, master_coords, n_master_faces, &` |
| SUBROUTINE | `EvalFaceShapeFunc` | 731 | `SUBROUTINE EvalFaceShapeFunc(xi, eta, n_nodes, N, dN_dxi, dN_deta)` |
| SUBROUTINE | `Cross3` | 839 | `PURE SUBROUTINE Cross3(a, b, c)` |
| SUBROUTINE | `BuildTangentBasis` | 855 | `PURE SUBROUTINE BuildTangentBasis(n, t1, t2)` |
| SUBROUTINE | `AddFrictionNodalForces` | 892 | `SUBROUTINE AddFrictionNodalForces(pair, f_nodal)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
