# `MD_Int_Def.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Int_SurfEntry_Desc` (lines 135–140)

```fortran
  TYPE :: MD_Int_SurfEntry_Desc
    INTEGER(i4)       :: id           = 0_i4           ! [in] Surface ID
    CHARACTER(LEN=64) :: name         = ""             ! [in] Surface name
    INTEGER(i4)       :: surface_type = 0_i4           ! [in] Surface type enum
    LOGICAL           :: valid        = .FALSE.        ! [out] Validity flag
  END TYPE MD_Int_SurfEntry_Desc
```

### `MD_Int_PairEntry_Desc` (lines 148–154)

```fortran
  TYPE :: MD_Int_PairEntry_Desc
    INTEGER(i4) :: pair_id      = 0_i4                 ! [in] Pair ID
    INTEGER(i4) :: master_id    = 0_i4                 ! [in] Master surface ID
    INTEGER(i4) :: slave_id     = 0_i4                 ! [in] Slave surface ID
    REAL(wp)    :: mu_friction  = 0.0_wp               ! [in] Friction coefficient
    LOGICAL     :: valid        = .FALSE.              ! [out] Validity flag
  END TYPE MD_Int_PairEntry_Desc
```

### `MD_Int_Fric_Algo` (lines 162–167)

```fortran
  TYPE :: MD_Int_Fric_Algo
    REAL(wp)    :: mu_static    = 0.0_wp               ! [in] Static friction coeff
    REAL(wp)    :: mu_kinetic   = 0.0_wp               ! [in] Kinetic friction coeff
    REAL(wp)    :: decay_coeff  = 0.0_wp               ! [in] Exponential decay coeff
    INTEGER(i4) :: model        = MD_INT_FRIC_COULOMB  ! [in] Friction model enum
  END TYPE MD_Int_Fric_Algo
```

### `MD_Int_Cohesion_Desc` (lines 175–180)

```fortran
  TYPE :: MD_Int_Cohesion_Desc
    REAL(wp) :: max_stress  = 0.0_wp                   ! [in] Maximum cohesive stress
    REAL(wp) :: max_disp    = 0.0_wp                   ! [in] Maximum separation disp
    REAL(wp) :: energy      = 0.0_wp                   ! [in] Fracture energy
    LOGICAL  :: is_active   = .FALSE.                  ! [in] Active flag
  END TYPE MD_Int_Cohesion_Desc
```

### `MD_Int_Damping_Algo` (lines 188–192)

```fortran
  TYPE :: MD_Int_Damping_Algo
    REAL(wp) :: viscous_coeff  = 0.0_wp                ! [in] Viscous damping coeff
    REAL(wp) :: critical_ratio = 0.0_wp                ! [in] Critical damping ratio
    LOGICAL  :: is_active      = .FALSE.               ! [in] Active flag
  END TYPE MD_Int_Damping_Algo
```

### `MD_Int_Property_Desc` (lines 200–208)

```fortran
  TYPE :: MD_Int_Property_Desc
    CHARACTER(LEN=64) :: name              = ""        ! [in] Property name
    INTEGER(i4)       :: id                = 0_i4      ! [in] Property ID
    CHARACTER(LEN=32) :: overclosure       = "HARD"    ! [in] HARD/SOFT/EXPONENTIAL
    REAL(wp)          :: clearance          = 0.0_wp    ! [in] Initial clearance
    REAL(wp)          :: stiffness_scale    = 1.0_wp    ! [in] Stiffness scale factor
    REAL(wp)          :: penalty_stiffness  = 1.0e6_wp  ! [in] Penalty stiffness
    TYPE(MD_Int_Fric_Algo) :: friction                 ! [in] Friction parameters
  END TYPE MD_Int_Property_Desc
```

### `MD_Int_PairDef_Desc` (lines 216–227)

```fortran
  TYPE :: MD_Int_PairDef_Desc
    INTEGER(i4)       :: pair_id             = 0_i4               ! [in] Pair ID
    CHARACTER(LEN=64) :: master_surface      = ""                 ! [in] Master surface name
    CHARACTER(LEN=64) :: slave_surface       = ""                 ! [in] Slave surface name
    CHARACTER(LEN=64) :: prop_name           = ""                 ! [in] Property name ref
    INTEGER(i4)       :: formulation         = MD_INT_FORM_SURFACE ! [in] Formulation enum
    REAL(wp)          :: adjust              = 0.0_wp             ! [in] Adjust tolerance
    LOGICAL           :: active_in_all_steps = .TRUE.             ! [in] Active-all flag
    INTEGER(i4)       :: step_ref            = 0_i4               ! [in] Step reference
    LOGICAL           :: small_sliding       = .FALSE.            ! [in] Small sliding flag
    INTEGER(i4), ALLOCATABLE :: step_refs(:)                      ! [in] Multi-step refs
  END TYPE MD_Int_PairDef_Desc
```

### `MD_Int_Union_Ctx` (lines 235–238)

```fortran
  TYPE :: MD_Int_Union_Ctx
    TYPE(MD_Int_PairDef_Desc), ALLOCATABLE :: contact_pairs(:)   ! [inout] Pair array
    INTEGER(i4)                            :: n_pairs = 0_i4     ! [inout] Count
  END TYPE MD_Int_Union_Ctx
```

### `MD_Int_SurfRef_Desc` (lines 246–248)

```fortran
  TYPE :: MD_Int_SurfRef_Desc
    CHARACTER(LEN=64) :: name = ""                                ! [in] Surface name
  END TYPE MD_Int_SurfRef_Desc
```

### `MD_Int_CtrlPair_Desc` (lines 256–264)

```fortran
  TYPE :: MD_Int_CtrlPair_Desc
    INTEGER(i4)              :: id            = 0_i4              ! [in] Pair ID
    CHARACTER(LEN=64)        :: name          = ""                ! [in] Pair name
    TYPE(MD_Int_SurfRef_Desc) :: masterSurface                    ! [in] Master surface ref
    TYPE(MD_Int_SurfRef_Desc) :: slaveSurface                     ! [in] Slave surface ref
    CHARACTER(LEN=64)        :: propertyName  = ""                ! [in] Property name
    LOGICAL                  :: small_sliding = .FALSE.           ! [in] Small sliding flag
    INTEGER(i4)              :: stepId        = 0_i4              ! [in] Step ID
  END TYPE MD_Int_CtrlPair_Desc
```

### `MD_Int_Ctrl_Ctx` (lines 272–277)

```fortran
  TYPE :: MD_Int_Ctrl_Ctx
    INTEGER(i4)                :: nPairs      = 0_i4                        ! [inout] Pair count
    TYPE(MD_Int_CtrlPair_Desc) :: pairs(MD_INT_MAX_CTRL_PAIRS)              ! [inout] Pair array
    INTEGER(i4)                :: nProperties = 0_i4                        ! [inout] Property count
    TYPE(MD_Int_Property_Desc) :: properties(MD_INT_MAX_CTRL_PROPS)         ! [inout] Property array
  END TYPE MD_Int_Ctrl_Ctx
```

### `MD_Int_Pair_Desc` (lines 285–292)

```fortran
  TYPE :: MD_Int_Pair_Desc
    CHARACTER(LEN=64) :: pair_name      = ""                      ! [in] Pair name
    INTEGER(i4)       :: pair_id        = 0_i4                    ! [in] Pair ID
    CHARACTER(LEN=64) :: slave_surface  = ""                      ! [in] Slave surface
    CHARACTER(LEN=64) :: master_surface = ""                      ! [in] Master surface
    INTEGER(i4)       :: contact_type   = MD_INT_CONTACT_S2S      ! [in] Contact type enum
    LOGICAL           :: is_active      = .TRUE.                  ! [in] Active flag
  END TYPE MD_Int_Pair_Desc
```

### `MD_Int_SurfInt_Desc` (lines 300–308)

```fortran
  TYPE :: MD_Int_SurfInt_Desc
    CHARACTER(LEN=64) :: interaction_name = ""                    ! [in] Interaction name
    INTEGER(i4)       :: interaction_id   = 0_i4                  ! [in] Interaction ID
    CHARACTER(LEN=64) :: paired_surfaces  = ""                    ! [in] Paired surface name
    CHARACTER(LEN=32) :: normal_behavior  = "HARD"                ! [in] Normal behavior
    REAL(wp)          :: normal_stiffness = 0.0_wp                ! [in] Normal stiffness
    CHARACTER(LEN=32) :: tangent_behavior = "FRICTIONLESS"        ! [in] Tangent behavior
    REAL(wp)          :: tangent_stiffness = 0.0_wp               ! [in] Tangent stiffness
  END TYPE MD_Int_SurfInt_Desc
```

### `MD_Int_FricModel_Desc` (lines 316–324)

```fortran
  TYPE :: MD_Int_FricModel_Desc
    CHARACTER(LEN=64) :: friction_name   = ""                     ! [in] Friction name
    INTEGER(i4)       :: friction_id     = 0_i4                   ! [in] Friction ID
    INTEGER(i4)       :: model_type      = MD_INT_FRIC_COULOMB    ! [in] Model type enum
    REAL(wp)          :: static_coeff    = 0.3_wp                 ! [in] Static friction coeff
    REAL(wp)          :: kinetic_coeff   = 0.2_wp                 ! [in] Kinetic friction coeff
    REAL(wp)          :: stick_slip_ratio = 1.0_wp                ! [in] Stick-slip ratio
    REAL(wp)          :: damping_coeff   = 0.0_wp                 ! [in] Damping coefficient
  END TYPE MD_Int_FricModel_Desc
```

### `MD_Int_Cfg_Id_Desc` (lines 331–337)

```fortran
  TYPE :: MD_Int_Cfg_Id_Desc
    CHARACTER(LEN=64) :: interaction_name = ""                    ! [in] Interaction name
    INTEGER(i4)       :: interaction_id   = 0_i4                  ! [in] Interaction ID
    INTEGER(i4)       :: contact_type     = MD_INT_CONTACT_S2S    ! [in] Contact type enum
    CHARACTER(LEN=64) :: slave_surface    = ""                    ! [in] Slave surface name
    CHARACTER(LEN=64) :: master_surface   = ""                    ! [in] Master surface name
  END TYPE MD_Int_Cfg_Id_Desc
```

### `MD_Int_Cfg_Container_Desc` (lines 339–346)

```fortran
  TYPE :: MD_Int_Cfg_Container_Desc
    INTEGER(i4) :: num_contact_pairs = 0_i4                       ! [inout] Pair count
    TYPE(MD_Int_Pair_Desc), ALLOCATABLE :: contact_pairs(:)       ! [inout] Pair array
    INTEGER(i4) :: num_surface_interactions = 0_i4                ! [inout] Interaction count
    TYPE(MD_Int_SurfInt_Desc), ALLOCATABLE :: surface_interactions(:) ! [inout] Interaction array
    INTEGER(i4) :: num_friction_models = 0_i4                     ! [inout] Model count
    TYPE(MD_Int_FricModel_Desc), ALLOCATABLE :: friction_models(:) ! [inout] Model array
  END TYPE MD_Int_Cfg_Container_Desc
```

### `MD_Int_Cfg_API_Desc` (lines 348–353)

```fortran
  TYPE :: MD_Int_Cfg_API_Desc
    INTEGER(i4) :: n_surfaces = 0_i4                              ! [inout] Surface count
    TYPE(MD_Int_SurfEntry_Desc) :: surfaces(MD_INT_MAX_SURFACES)  ! [inout] Surface entries
    INTEGER(i4) :: n_pairs = 0_i4                                 ! [inout] Pair count (v2)
    TYPE(MD_Int_PairEntry_Desc) :: pairs(MD_INT_MAX_PAIR_ENTRIES) ! [inout] Pair entries
  END TYPE MD_Int_Cfg_API_Desc
```

### `MD_Int_Desc` (lines 362–367)

```fortran
  TYPE :: MD_Int_Desc
    TYPE(MD_Int_Cfg_Id_Desc)        :: cfg_id
    TYPE(MD_Int_Cfg_Container_Desc) :: cfg_container
    TYPE(MD_Int_Cfg_API_Desc)       :: cfg_api
    CHARACTER(LEN=32) :: output_format = "ODB"                    ! [in] Output format
  END TYPE MD_Int_Desc
```

### `MD_Int_Itr_Whitelist_State` (lines 374–378)

```fortran
  TYPE :: MD_Int_Itr_Whitelist_State
    REAL(wp)    :: contact_pressure    = 0.0_wp                  ! [inout] WHITE-LIST 1/3
    REAL(wp)    :: slip_distance       = 0.0_wp                  ! [inout] WHITE-LIST 2/3
    INTEGER(i4) :: total_contact_points = 0_i4                   ! [inout] WHITE-LIST 3/3
  END TYPE MD_Int_Itr_Whitelist_State
```

### `MD_Int_Itr_PerPoint_State` (lines 380–384)

```fortran
  TYPE :: MD_Int_Itr_PerPoint_State
    REAL(wp), ALLOCATABLE :: normal_stress(:)                     ! [inout] Normal stress
    REAL(wp), ALLOCATABLE :: tangent_stress(:)                    ! [inout] Tangent stress
    REAL(wp), ALLOCATABLE :: slip_rate(:)                         ! [inout] Slip rate
  END TYPE MD_Int_Itr_PerPoint_State
```

### `MD_Int_State` (lines 391–398)

```fortran
  TYPE :: MD_Int_State
    LOGICAL     :: is_active           = .TRUE.                   ! [inout] Active flag
    INTEGER(i4) :: contact_status      = 0_i4                    ! [inout] 0=open,1=closed,2=sliding
    REAL(wp)    :: contact_area        = 0.0_wp                  ! [inout] Contact area
    TYPE(MD_Int_Itr_Whitelist_State)  :: itr_whitelist
    TYPE(MD_Int_Itr_PerPoint_State)   :: itr_perpoint
    TYPE(ErrorStatusType) :: status                               ! [out] Error status
  END TYPE MD_Int_State
```

### `MD_Int_Stp_Penalty_Algo` (lines 405–408)

```fortran
  TYPE :: MD_Int_Stp_Penalty_Algo
    LOGICAL     :: use_penalty          = .TRUE.                  ! [in] Use penalty method
    REAL(wp)    :: penalty_stiffness    = 1.0e6_wp                ! [in] Penalty stiffness
  END TYPE MD_Int_Stp_Penalty_Algo
```

### `MD_Int_Stp_Conv_Algo` (lines 410–412)

```fortran
  TYPE :: MD_Int_Stp_Conv_Algo
    REAL(wp)    :: convergence_tolerance = 1.0e-4_wp              ! [in] Convergence tol
  END TYPE MD_Int_Stp_Conv_Algo
```

### `MD_Int_Stp_FricDamp_Algo` (lines 414–418)

```fortran
  TYPE :: MD_Int_Stp_FricDamp_Algo
    LOGICAL     :: use_friction         = .TRUE.                  ! [in] Enable friction
    LOGICAL     :: use_damping          = .FALSE.                 ! [in] Enable damping
    REAL(wp)    :: damping_factor       = 0.1_wp                  ! [in] Damping factor
  END TYPE MD_Int_Stp_FricDamp_Algo
```

### `MD_Int_Algo` (lines 425–430)

```fortran
  TYPE :: MD_Int_Algo
    INTEGER(i4) :: algorithm_type       = MD_INT_ALGO_PENALTY     ! [in] Algorithm enum
    TYPE(MD_Int_Stp_Penalty_Algo)  :: stp_penalty
    TYPE(MD_Int_Stp_Conv_Algo)     :: stp_conv
    TYPE(MD_Int_Stp_FricDamp_Algo) :: stp_fricdamp
  END TYPE MD_Int_Algo
```

### `MD_Int_Lcl_IO_Ctx` (lines 437–442)

```fortran
  TYPE :: MD_Int_Lcl_IO_Ctx
    INTEGER(i4)       :: contact_ctx_id  = 0_i4                   ! [in] Context ID
    CHARACTER(LEN=256) :: contact_dir    = "./"                   ! [in] Working directory
    INTEGER(i4)       :: result_unit     = 0_i4                   ! [inout] Result file unit
    CHARACTER(LEN=256) :: result_filename = ""                    ! [in] Result filename
  END TYPE MD_Int_Lcl_IO_Ctx
```

### `MD_Int_Lcl_Work_Ctx` (lines 444–446)

```fortran
  TYPE :: MD_Int_Lcl_Work_Ctx
    REAL(wp), ALLOCATABLE :: work_array(:,:)                      ! [inout] Work array
  END TYPE MD_Int_Lcl_Work_Ctx
```

### `MD_Int_Ctx` (lines 453–456)

```fortran
  TYPE :: MD_Int_Ctx
    TYPE(MD_Int_Lcl_IO_Ctx)  :: lcl_io
    TYPE(MD_Int_Lcl_Work_Ctx) :: lcl_work
  END TYPE MD_Int_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Int_InitDesc` | 549 | `SUBROUTINE MD_Int_InitDesc(desc, name, contact_type, status)` |
| SUBROUTINE | `MD_Int_AddPair` | 589 | `SUBROUTINE MD_Int_AddPair(desc, pair_name, slave_surf, master_surf, &` |
| SUBROUTINE | `MD_Int_CtrlInit` | 632 | `SUBROUTINE MD_Int_CtrlInit(ctrl)` |
| SUBROUTINE | `MD_Int_CtrlFree` | 644 | `SUBROUTINE MD_Int_CtrlFree(ctrl)` |
| SUBROUTINE | `MD_Int_CtrlAddPair` | 656 | `SUBROUTINE MD_Int_CtrlAddPair(ctrl, pair)` |
| SUBROUTINE | `MD_Int_CtrlAddProp` | 670 | `SUBROUTINE MD_Int_CtrlAddProp(ctrl, property)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
