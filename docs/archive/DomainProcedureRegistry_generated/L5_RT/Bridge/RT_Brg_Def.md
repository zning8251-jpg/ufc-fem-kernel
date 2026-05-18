# `RT_Brg_Def.f90`

- **Source**: `L5_RT/Bridge/RT_Brg_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Brg_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Brg_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Brg`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Bridge/RT_Brg_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mat_Stp_Ctl_BrgCtx` (lines 70–74)

```fortran
  TYPE, PUBLIC :: RT_Mat_Stp_Ctl_BrgCtx
    INTEGER(i4) :: mat_id     = 0_i4
    INTEGER(i4) :: mat_family = 0_i4
    INTEGER(i4) :: algo_id    = 0_i4
  END TYPE RT_Mat_Stp_Ctl_BrgCtx
```

### `RT_Mat_Lcl_Brg_Ctx` (lines 79–88)

```fortran
  TYPE, PUBLIC :: RT_Mat_Lcl_Brg_Ctx
    INTEGER(i4) :: integ_pt_id = 0_i4
    REAL(wp)    :: dtime       = 0.0_wp
    REAL(wp)    :: time_step   = 0.0_wp
    REAL(wp)    :: time_total  = 0.0_wp
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
  END TYPE RT_Mat_Lcl_Brg_Ctx
```

### `RT_Mat_Bridge_Ctx` (lines 93–111)

```fortran
  TYPE, PUBLIC :: RT_Mat_Bridge_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(RT_Mat_Stp_Ctl_BrgCtx) :: stp   ! Step control fields
    TYPE(RT_Mat_Lcl_Brg_Ctx)    :: lcl   ! Local bridge fields
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: mat_id       = 0_i4   ! DEPRECATED: use %stp%mat_id
    INTEGER(i4) :: mat_family   = 0_i4   ! DEPRECATED: use %stp%mat_family
    INTEGER(i4) :: integ_pt_id  = 0_i4   ! DEPRECATED: use %lcl%integ_pt_id
    INTEGER(i4) :: algo_id      = 0_i4   ! DEPRECATED: use %stp%algo_id
    REAL(wp) :: dtime           = 0.0_wp ! DEPRECATED: use %lcl%dtime
    REAL(wp) :: time_step       = 0.0_wp ! DEPRECATED: use %lcl%time_step
    REAL(wp) :: time_total      = 0.0_wp ! DEPRECATED: use %lcl%time_total
    INTEGER(i4) :: kstep        = 0_i4   ! DEPRECATED: use %lcl%kstep
    INTEGER(i4) :: kinc         = 0_i4   ! DEPRECATED: use %lcl%kinc
    INTEGER(i4) :: noel         = 0_i4   ! DEPRECATED: use %lcl%noel
    INTEGER(i4) :: npt          = 0_i4   ! DEPRECATED: use %lcl%npt
    ! [Phase:*|Verb:Ctl] bridge state -- bare field
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Mat_Bridge_Ctx
```

### `RT_Elem_Stp_Ctl_BrgCtx` (lines 120–124)

```fortran
  TYPE, PUBLIC :: RT_Elem_Stp_Ctl_BrgCtx
    INTEGER(i4) :: elem_id     = 0_i4
    INTEGER(i4) :: jtype       = 0_i4
    INTEGER(i4) :: elem_family = 0_i4
  END TYPE RT_Elem_Stp_Ctl_BrgCtx
```

### `RT_Elem_Lcl_Brg_Ctx` (lines 129–138)

```fortran
  TYPE, PUBLIC :: RT_Elem_Lcl_Brg_Ctx
    INTEGER(i4) :: lflags(5)   = 0_i4
    REAL(wp)    :: dtime       = 0.0_wp
    REAL(wp)    :: time_step   = 0.0_wp
    REAL(wp)    :: time_total  = 0.0_wp
    INTEGER(i4) :: kstep       = 0_i4
    INTEGER(i4) :: kinc        = 0_i4
    INTEGER(i4) :: nrhs        = 1_i4
    INTEGER(i4) :: isym        = 1_i4
  END TYPE RT_Elem_Lcl_Brg_Ctx
```

### `RT_Elem_Bridge_Ctx` (lines 143–161)

```fortran
  TYPE, PUBLIC :: RT_Elem_Bridge_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(RT_Elem_Stp_Ctl_BrgCtx) :: stp  ! Step control fields
    TYPE(RT_Elem_Lcl_Brg_Ctx)    :: lcl  ! Local bridge fields
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4) :: elem_id      = 0_i4   ! DEPRECATED: use %stp%elem_id
    INTEGER(i4) :: jtype        = 0_i4   ! DEPRECATED: use %stp%jtype
    INTEGER(i4) :: elem_family  = 0_i4   ! DEPRECATED: use %stp%elem_family
    INTEGER(i4) :: lflags(5)    = 0_i4   ! DEPRECATED: use %lcl%lflags
    REAL(wp) :: dtime           = 0.0_wp ! DEPRECATED: use %lcl%dtime
    REAL(wp) :: time_step       = 0.0_wp ! DEPRECATED: use %lcl%time_step
    REAL(wp) :: time_total      = 0.0_wp ! DEPRECATED: use %lcl%time_total
    INTEGER(i4) :: kstep        = 0_i4   ! DEPRECATED: use %lcl%kstep
    INTEGER(i4) :: kinc         = 0_i4   ! DEPRECATED: use %lcl%kinc
    INTEGER(i4) :: nrhs         = 1_i4   ! DEPRECATED: use %lcl%nrhs
    INTEGER(i4) :: isym         = 1_i4   ! DEPRECATED: use %lcl%isym
    ! [Phase:*|Verb:Ctl] bridge state -- bare field
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Elem_Bridge_Ctx
```

### `RT_Load_Bridge_Ctx` (lines 166–181)

```fortran
  TYPE, PUBLIC :: RT_Load_Bridge_Ctx
    INTEGER(i4) :: noel          = 0_i4
    INTEGER(i4) :: npt           = 0_i4
    INTEGER(i4) :: jltyp         = 0_i4
    INTEGER(i4) :: load_subrt    = 0_i4
    
    CHARACTER(LEN=80) :: sname   = ''
    CHARACTER(LEN=80) :: cmname  = ''
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    REAL(wp) :: amplitude  = 1.0_wp
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Load_Bridge_Ctx
```

### `RT_BC_Bridge_Ctx` (lines 186–200)

```fortran
  TYPE, PUBLIC :: RT_BC_Bridge_Ctx
    INTEGER(i4) :: node_id     = 0_i4
    INTEGER(i4) :: dof_id      = 0_i4
    INTEGER(i4) :: bc_subrt    = 0_i4
    
    CHARACTER(LEN=8) :: doflab = ''
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    
    INTEGER(i4) :: kstep    = 0_i4
    INTEGER(i4) :: kinc     = 0_i4
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_BC_Bridge_Ctx
```

### `RT_Contact_Bridge_Ctx` (lines 205–220)

```fortran
  TYPE, PUBLIC :: RT_Contact_Bridge_Ctx
    INTEGER(i4) :: surf_id     = 0_i4
    INTEGER(i4) :: contact_subrt = 0_i4
    
    REAL(wp) :: gap        = 0.0_wp
    REAL(wp) :: pressure   = 0.0_wp
    REAL(wp) :: coords(3)  = 0.0_wp
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Contact_Bridge_Ctx
```

### `RT_Fric_Bridge_Ctx` (lines 225–240)

```fortran
  TYPE, PUBLIC :: RT_Fric_Bridge_Ctx
    INTEGER(i4) :: surf_id     = 0_i4
    INTEGER(i4) :: fric_subrt  = 0_i4
    
    REAL(wp) :: pressure   = 0.0_wp
    REAL(wp) :: temp       = 0.0_wp
    REAL(wp) :: coords(3)  = 0.0_wp
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Fric_Bridge_Ctx
```

### `RT_Constr_Bridge_Ctx` (lines 245–259)

```fortran
  TYPE, PUBLIC :: RT_Constr_Bridge_Ctx
    INTEGER(i4) :: constr_id   = 0_i4
    INTEGER(i4) :: constr_subrt = 0_i4
    
    INTEGER(i4) :: nterms  = 0_i4
    INTEGER(i4) :: nblock  = 1_i4
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Constr_Bridge_Ctx
```

### `RT_Field_Bridge_Ctx` (lines 264–279)

```fortran
  TYPE, PUBLIC :: RT_Field_Bridge_Ctx
    INTEGER(i4) :: noel        = 0_i4
    INTEGER(i4) :: npt         = 0_i4
    INTEGER(i4) :: field_subrt = 0_i4
    
    INTEGER(i4) :: nfield  = 0_i4
    INTEGER(i4) :: nstatv  = 0_i4
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Field_Bridge_Ctx
```

### `RT_Analy_Bridge_Ctx` (lines 284–302)

```fortran
  TYPE, PUBLIC :: RT_Analy_Bridge_Ctx
    INTEGER(i4) :: lop           = -1_i4
    INTEGER(i4) :: analy_subrt   = 0_i4
    
    CHARACTER(LEN=80) :: ampname = ''
    
    INTEGER(i4) :: noel    = 0_i4
    INTEGER(i4) :: npt     = 0_i4
    INTEGER(i4) :: nblock  = 1_i4
    INTEGER(i4) :: nuvarm  = 0_i4
    
    REAL(wp) :: dtime      = 0.0_wp
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc    = 0_i4
    
    INTEGER(i4) :: bridge_state = RT_BRG_BRIDGE_IDLE
  END TYPE RT_Analy_Bridge_Ctx
```

### `RT_Mesh_Bridge_Ctx` (lines 307–315)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Bridge_Ctx
    INTEGER(i4)          :: bridge_status = 0_i4
    INTEGER(i4)          :: n_nodes       = 0_i4
    INTEGER(i4)          :: n_elems       = 0_i4
    INTEGER(i4)          :: n_dofs        = 0_i4
    REAL(wp),    POINTER :: coord(:,:)    => NULL()
    INTEGER(i4), POINTER :: connect(:,:)  => NULL()
    INTEGER(i4), POINTER :: dof_map(:,:)  => NULL()
  END TYPE RT_Mesh_Bridge_Ctx
```

### `RT_Step_Bridge_Ctx` (lines 320–330)

```fortran
  TYPE, PUBLIC :: RT_Step_Bridge_Ctx
    INTEGER(i4) :: bridge_status  = 0_i4
    INTEGER(i4) :: step_id        = 0_i4
    INTEGER(i4) :: proc_family    = 0_i4
    REAL(wp)    :: time_period    = 0.0_wp
    REAL(wp)    :: time_in_step   = 0.0_wp
    REAL(wp)    :: dt_current     = 0.0_wp
    REAL(wp)    :: dt_min         = 0.0_wp
    REAL(wp)    :: dt_max         = 0.0_wp
    INTEGER(i4) :: kinc           = 0_i4
  END TYPE RT_Step_Bridge_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Mat_Bridge_Sync_Aux_From_Deprecated` | 340 | `SUBROUTINE RT_Mat_Bridge_Sync_Aux_From_Deprecated(b)` |
| SUBROUTINE | `RT_Mat_Bridge_Sync_Deprecated_From_Aux` | 355 | `SUBROUTINE RT_Mat_Bridge_Sync_Deprecated_From_Aux(b)` |
| SUBROUTINE | `RT_Elem_Bridge_Sync_Aux_From_Deprecated` | 370 | `SUBROUTINE RT_Elem_Bridge_Sync_Aux_From_Deprecated(b)` |
| SUBROUTINE | `RT_Elem_Bridge_Sync_Deprecated_From_Aux` | 385 | `SUBROUTINE RT_Elem_Bridge_Sync_Deprecated_From_Aux(b)` |
| SUBROUTINE | `RT_Bridge_Init` | 401 | `SUBROUTINE RT_Bridge_Init(mat_brg, elem_brg, load_brg, bc_brg, cont_brg, &` |
| SUBROUTINE | `RT_Bridge_SetReady` | 448 | `SUBROUTINE RT_Bridge_SetReady(bridge_ctx)` |
| SUBROUTINE | `RT_Bridge_SetDone` | 454 | `SUBROUTINE RT_Bridge_SetDone(bridge_ctx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
