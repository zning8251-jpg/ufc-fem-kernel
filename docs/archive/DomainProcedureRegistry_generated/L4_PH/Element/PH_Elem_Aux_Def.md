# `PH_Elem_Aux_Def.f90`

- **Source**: `L4_PH/Element/PH_Elem_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Aux_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Cfg_Init_Desc` (lines 84–89)

```fortran
  TYPE, PUBLIC :: PH_Elem_Cfg_Init_Desc
    INTEGER(i4) :: elem_type_id = 0_i4  ! MD_ELEM_C3D8 etc.
    INTEGER(i4) :: family_id    = 0_i4  ! PH_ELEM_FAMILY_*
    INTEGER(i4) :: ndim         = 0_i4  ! spatial dimension
    INTEGER(i4) :: section_type = 0_i4  ! section type from L3
  END TYPE PH_Elem_Cfg_Init_Desc
```

### `PH_Elem_Pop_Vld_Desc` (lines 98–104)

```fortran
  TYPE, PUBLIC :: PH_Elem_Pop_Vld_Desc
    INTEGER(i4) :: n_nodes       = 0_i4
    INTEGER(i4) :: n_dof         = 0_i4
    INTEGER(i4) :: dof_per_node  = 0_i4
    INTEGER(i4) :: n_integration = 0_i4
    INTEGER(i4) :: n_elements    = 0_i4
  END TYPE PH_Elem_Pop_Vld_Desc
```

### `PH_Elem_Inc_Evo_Ctx` (lines 117–120)

```fortran
  TYPE, PUBLIC :: PH_Elem_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Elem_Inc_Evo_Ctx
```

### `PH_Elem_Itr_Asm_Ctx` (lines 129–134)

```fortran
  TYPE, PUBLIC :: PH_Elem_Itr_Asm_Ctx
    INTEGER(i4) :: current_ip   = 0_i4
    INTEGER(i4) :: current_elem = 0_i4
    REAL(wp)    :: det_J        = 0.0_wp
    REAL(wp)    :: weight       = 0.0_wp
  END TYPE PH_Elem_Itr_Asm_Ctx
```

### `PH_Elem_Lcl_Comp_Ctx` (lines 144–149)

```fortran
  TYPE, PUBLIC :: PH_Elem_Lcl_Comp_Ctx
    REAL(wp), ALLOCATABLE :: u_elem(:)   ! (n_dof) total displacement
    REAL(wp), ALLOCATABLE :: du_elem(:)  ! (n_dof) displacement increment
    REAL(wp), ALLOCATABLE :: dN_dX(:,:)  ! (ndim,n_node) shape func derivatives
    REAL(wp), ALLOCATABLE :: J_mat(:,:)  ! (ndim,ndim) Jacobian matrix
  END TYPE PH_Elem_Lcl_Comp_Ctx
```

### `PH_Elem_Lcl_Evo_Ctx` (lines 159–164)

```fortran
  TYPE, PUBLIC :: PH_Elem_Lcl_Evo_Ctx
    REAL(wp), ALLOCATABLE :: Ke_mat(:,:)  ! material stiffness
    REAL(wp), ALLOCATABLE :: Ke_geo(:,:)  ! geometric stiffness
    REAL(wp), ALLOCATABLE :: Ke(:,:)      ! total stiffness
    REAL(wp), ALLOCATABLE :: R_int(:)     ! internal force
  END TYPE PH_Elem_Lcl_Evo_Ctx
```

### `PH_Elem_Stp_Evo_State` (lines 177–183)

```fortran
  TYPE, PUBLIC :: PH_Elem_Stp_Evo_State
    LOGICAL     :: initialized     = .FALSE.
    LOGICAL     :: stiffness_built = .FALSE.
    INTEGER(i4) :: n_active_elems  = 0_i4
    INTEGER(i4) :: current_step    = 0_i4
    INTEGER(i4) :: n_converged     = 0_i4
  END TYPE PH_Elem_Stp_Evo_State
```

### `PH_Elem_Itr_Acc_State` (lines 195–202)

```fortran
  TYPE, PUBLIC :: PH_Elem_Itr_Acc_State
    REAL(wp), ALLOCATABLE :: rhs(:,:)      ! (ndofel, nrhs) residual / RHS
    REAL(wp), ALLOCATABLE :: amatrx(:,:)   ! (ndofel, ndofel) stiffness matrix
    REAL(wp), ALLOCATABLE :: svars(:)      ! (nsvars) solution-dependent state vars
    REAL(wp)              :: energy(8) = 0.0_wp  ! UEL energy output (always 8)
    REAL(wp), ALLOCATABLE :: mass(:,:)    ! (ndofel, ndofel) mass matrix
    REAL(wp), ALLOCATABLE :: damping(:,:)  ! (ndofel, ndofel) damping matrix (Rayleigh)
  END TYPE PH_Elem_Itr_Acc_State
```

### `PH_Elem_Stp_Ctl_Algo` (lines 215–220)

```fortran
  TYPE, PUBLIC :: PH_Elem_Stp_Ctl_Algo
    INTEGER(i4) :: integration_order = 2_i4
    INTEGER(i4) :: hourglass_control = 0_i4    ! 0=none, 1=viscous, 2=stiffness
    REAL(wp)    :: hourglass_coeff   = 0.0_wp
    LOGICAL     :: nlgeom            = .FALSE.
  END TYPE PH_Elem_Stp_Ctl_Algo
```

### `PH_Elem_Stp_Ctl_Dyn_Algo` (lines 229–234)

```fortran
  TYPE, PUBLIC :: PH_Elem_Stp_Ctl_Dyn_Algo
    LOGICAL     :: reduced_integ  = .FALSE.
    INTEGER(i4) :: mass_type      = 1_i4   ! 1=consistent, 2=lumped
    REAL(wp)    :: alpha_rayleigh = 0.0_wp
    REAL(wp)    :: beta_rayleigh  = 0.0_wp
  END TYPE PH_Elem_Stp_Ctl_Dyn_Algo
```

### `PH_Elem_Itr_Asm_ArgHub` (lines 249–251)

```fortran
  TYPE, PUBLIC :: PH_Elem_Itr_Asm_ArgHub
    INTEGER(i4) :: hub_tag = 0_i4  ! 0=uninit; nonzero marks active aggregation
  END TYPE PH_Elem_Itr_Asm_ArgHub
```

### `PH_Elem_Lcl_Comp_ArgHub` (lines 259–261)

```fortran
  TYPE, PUBLIC :: PH_Elem_Lcl_Comp_ArgHub
    INTEGER(i4) :: hub_tag = 0_i4  ! 0=uninit; nonzero marks active aggregation
  END TYPE PH_Elem_Lcl_Comp_ArgHub
```

### `PH_Elem_Lcl_Brg_ArgHub` (lines 269–271)

```fortran
  TYPE, PUBLIC :: PH_Elem_Lcl_Brg_ArgHub
    INTEGER(i4) :: hub_tag = 0_i4  ! 0=uninit; nonzero marks active aggregation
  END TYPE PH_Elem_Lcl_Brg_ArgHub
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
