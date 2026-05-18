# `PH_Elem_B31Cont.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31Cont.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31Cont`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31Cont`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31Cont`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31Cont.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `B31_Cont_Cfg_Penalty` (lines 32–38)

```fortran
TYPE :: B31_Cont_Cfg_Penalty
  REAL(wp) :: eps_n           = 0.0_wp  ! Normal penalty parameter
  REAL(wp) :: eps_t           = 0.0_wp  ! Tangential penalty parameter
  REAL(wp) :: mu_friction     = 0.0_wp  ! Friction coefficient
  REAL(wp) :: tol_gap         = 0.0_wp  ! Gap tolerance for detection
  REAL(wp) :: tol_penetration = 0.0_wp  ! Max allowed penetration
END TYPE B31_Cont_Cfg_Penalty
```

### `B31_Cont_Cfg_Pair` (lines 40–44)

```fortran
TYPE :: B31_Cont_Cfg_Pair
  INTEGER(i4) :: contact_type   = 1       ! 1=Beam-Beam, 2=Beam-Surface
  LOGICAL  :: friction_active = .FALSE. ! Friction flag
  INTEGER(i4) :: algorithm_type = 1       ! 1=Penalty, 2=Augmented Lagrangian
END TYPE B31_Cont_Cfg_Pair
```

### `B31_Cont_Cfg_Geom` (lines 46–50)

```fortran
TYPE :: B31_Cont_Cfg_Geom
  REAL(wp) :: beam1_radius         = 0.0_wp  ! Beam 1 radius
  REAL(wp) :: beam2_radius         = 0.0_wp  ! Beam 2 radius
  REAL(wp) :: master_surf_normal(3) = 0.0_wp ! Master surface normal
END TYPE B31_Cont_Cfg_Geom
```

### `B31_Cont_Det_Contact` (lines 52–56)

```fortran
TYPE :: B31_Cont_Det_Contact
  LOGICAL  :: in_contact   = .FALSE.     ! Contact active flag
  REAL(wp) :: gap_distance = 1.0e10_wp   ! Current gap distance
  REAL(wp) :: penetration  = 0.0_wp      ! Penetration depth
END TYPE B31_Cont_Det_Contact
```

### `B31_Cont_Det_Closest` (lines 58–63)

```fortran
TYPE :: B31_Cont_Det_Closest
  REAL(wp) :: x_c1(3) = 0.0_wp  ! Closest point on beam 1
  REAL(wp) :: x_c2(3) = 0.0_wp  ! Closest point on beam 2
  REAL(wp) :: xi_c1   = 0.0_wp  ! Convective coordinate on beam 1
  REAL(wp) :: xi_c2   = 0.0_wp  ! Convective coordinate on beam 2
END TYPE B31_Cont_Det_Closest
```

### `B31_Cont_Itr_Force` (lines 65–69)

```fortran
TYPE :: B31_Cont_Itr_Force
  REAL(wp) :: F_normal(3)  = 0.0_wp  ! Normal contact force
  REAL(wp) :: F_tangent(3) = 0.0_wp  ! Tangential friction force
  REAL(wp) :: F_total(3)   = 0.0_wp  ! Total contact force
END TYPE B31_Cont_Itr_Force
```

### `B31_Cont_Itr_Lagrange` (lines 71–74)

```fortran
TYPE :: B31_Cont_Itr_Lagrange
  REAL(wp) :: lambda_n    = 0.0_wp     ! Normal Lagrange multiplier
  REAL(wp) :: lambda_t(3) = 0.0_wp     ! Tangential Lagrange multipliers
END TYPE B31_Cont_Itr_Lagrange
```

### `B31_Cont_Itr_Friction` (lines 76–79)

```fortran
TYPE :: B31_Cont_Itr_Friction
  LOGICAL  :: sticking             = .TRUE.  ! Sticking vs sliding
  REAL(wp) :: slip_displacement(3) = 0.0_wp  ! Cumulative slip displacement
END TYPE B31_Cont_Itr_Friction
```

### `B31_Cont_Lcl_Vectors` (lines 81–85)

```fortran
TYPE :: B31_Cont_Lcl_Vectors
  REAL(wp) :: n_vec(3) = 0.0_wp  ! Contact normal vector
  REAL(wp) :: t_vec(3) = 0.0_wp  ! Tangent vector (sliding direction)
  REAL(wp) :: s_vec(3) = 0.0_wp  ! Second tangent (binormal)
END TYPE B31_Cont_Lcl_Vectors
```

### `B31_Cont_Lcl_Quad` (lines 87–90)

```fortran
TYPE :: B31_Cont_Lcl_Quad
  INTEGER(i4) :: n_contact_pts = 1                ! Number of contact integration points
  REAL(wp), ALLOCATABLE :: contact_weights(:)  ! Integration weights
END TYPE B31_Cont_Lcl_Quad
```

### `B31_Cont_Lcl_Iter` (lines 92–96)

```fortran
TYPE :: B31_Cont_Lcl_Iter
  INTEGER(i4) :: nl_iter       = 0       ! Nonlinear iterations
  REAL(wp) :: residual_norm = 0.0_wp  ! Residual norm
  LOGICAL  :: converged     = .FALSE. ! Convergence flag
END TYPE B31_Cont_Lcl_Iter
```

### `B31_Cont_Lcl_Algo` (lines 98–101)

```fortran
TYPE :: B31_Cont_Lcl_Algo
  REAL(wp) :: aug_lag_factor      = 10.0_wp  ! Augmentation factor for AL
  INTEGER(i4) :: max_AL_iterations   = 20       ! Max AL iterations
END TYPE B31_Cont_Lcl_Algo
```

### `B31_Cont_Lcl_Temp` (lines 103–106)

```fortran
TYPE :: B31_Cont_Lcl_Temp
  REAL(wp) :: temp3(3)   = 0.0_wp  ! Temporary vector
  REAL(wp) :: dN_dxi(3)  = 0.0_wp  ! Shape function derivative
END TYPE B31_Cont_Lcl_Temp
```

### `B31_Cont_Desc_Type` (lines 112–117)

```fortran
TYPE :: B31_Cont_Desc_Type
  TYPE(B31_Cont_Cfg_Penalty) :: cfg_penalty
  TYPE(B31_Cont_Cfg_Pair)    :: cfg_pair
  TYPE(B31_Cont_Cfg_Geom)    :: cfg_geom
  ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
END TYPE B31_Cont_Desc_Type
```

### `B31_Cont_State_Type` (lines 119–126)

```fortran
TYPE :: B31_Cont_State_Type
  TYPE(B31_Cont_Det_Contact)   :: det_contact
  TYPE(B31_Cont_Det_Closest)   :: det_closest
  TYPE(B31_Cont_Itr_Force)     :: itr_force
  TYPE(B31_Cont_Itr_Lagrange)  :: itr_lagrange
  TYPE(B31_Cont_Itr_Friction)  :: itr_friction
  ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
END TYPE B31_Cont_State_Type
```

### `B31_Cont_AlgoCtx_Type` (lines 128–135)

```fortran
TYPE :: B31_Cont_AlgoCtx_Type
  TYPE(B31_Cont_Lcl_Vectors) :: lcl_vectors
  TYPE(B31_Cont_Lcl_Quad)    :: lcl_quad
  TYPE(B31_Cont_Lcl_Iter)    :: lcl_iter
  TYPE(B31_Cont_Lcl_Algo)    :: lcl_algo
  TYPE(B31_Cont_Lcl_Temp)    :: lcl_temp
  ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
END TYPE B31_Cont_AlgoCtx_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_Cont_Initialize` | 151 | `SUBROUTINE PH_Elem_B31_Cont_Initialize(&` |
| SUBROUTINE | `PH_Elem_B31_Cont_BeamToBeamDetection` | 230 | `SUBROUTINE PH_Elem_B31_Cont_BeamToBeamDetection(&` |
| SUBROUTINE | `PH_Elem_B31_Cont_ClosestPointProjection` | 320 | `SUBROUTINE PH_Elem_B31_Cont_ClosestPointProjection(&` |
| SUBROUTINE | `PH_Elem_B31_Cont_PenaltyForce` | 448 | `SUBROUTINE PH_Elem_B31_Cont_PenaltyForce(&` |
| SUBROUTINE | `PH_Elem_B31_Cont_AugmentedLagrangian` | 499 | `SUBROUTINE PH_Elem_B31_Cont_AugmentedLagrangian(&` |
| SUBROUTINE | `PH_Elem_B31_Cont_CoulombFriction` | 550 | `SUBROUTINE PH_Elem_B31_Cont_CoulombFriction(&` |
| SUBROUTINE | `PH_Elem_B31_Cont_ContactStiffness` | 652 | `SUBROUTINE PH_Elem_B31_Cont_ContactStiffness(&` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
