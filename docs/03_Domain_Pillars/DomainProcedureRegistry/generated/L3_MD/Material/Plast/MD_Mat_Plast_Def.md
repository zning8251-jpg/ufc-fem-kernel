# `MD_Mat_Plast_Def.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Plast_Cfg_Init_Desc` (lines 67–74)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_Cfg_Init_Desc
    INTEGER(i4) :: family_type     = MD_MAT_FAMILY_PLASTIC
    INTEGER(i4) :: sub_type        = MD_MAT_PLAST_SUB_J2_ISO
    INTEGER(i4) :: property_flags  = MD_MAT_PROP_NONE
    INTEGER(i4) :: num_constants   = 0_i4
    INTEGER(i4) :: dependencies    = 0_i4
    INTEGER(i4) :: hardening_type  = 1_i4
  END TYPE MD_Mat_Plast_Cfg_Init_Desc
```

### `MD_Mat_Plast_Pop_Vld_Desc` (lines 80–82)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Plast_Pop_Vld_Desc
```

### `MD_Mat_Plast_Stp_Evo_Ctx` (lines 88–90)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE MD_Mat_Plast_Stp_Evo_Ctx
```

### `MD_Mat_Plast_State` (lines 148–168)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_State
    REAL(wp) :: stress(6) = 0.0_wp           ! Stress tensor (Voigt notation)
    REAL(wp) :: strain(6) = 0.0_wp           ! Total strain tensor
    REAL(wp) :: elastic_strain(6) = 0.0_wp   ! Elastic strain
    REAL(wp) :: plastic_strain(6) = 0.0_wp   ! Plastic strain
    REAL(wp) :: equiv_plastic_strain = 0.0_wp ! Equivalent plastic strain

    ! Internal state variables
    REAL(wp) :: backstress(6) = 0.0_wp       ! Backstress (kinematic hardening)
    REAL(wp) :: alpha_iso = 0.0_wp           ! Isotropic hardening variable
    REAL(wp) :: void_fraction = 0.0_wp       ! Void fraction (for GTN)

    ! State tracking
    LOGICAL :: is_plastic = .FALSE.          ! Whether material is yielding
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean => State_Clean
  END TYPE MD_Mat_Plast_State
```

### `MD_Mat_Plast_Algo` (lines 174–184)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_Algo
    INTEGER(i4) :: integration_method = 1    ! 1=return mapping, 2=cutting plane
    INTEGER(i4) :: tangent_type = 1          ! 1=consistent, 2=continuum
    INTEGER(i4) :: max_iterations = 50       ! Max iterations for return mapping
    REAL(wp) :: tolerance = 1.0e-8_wp        ! Convergence tolerance
    LOGICAL :: use_numerical_tangent = .FALSE.
    REAL(wp) :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Plast_Algo
```

### `MD_Mat_Plast_Ctx` (lines 190–211)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_Ctx
    ! Nested step evolution context
    TYPE(MD_Mat_Plast_Stp_Evo_Ctx) :: stp

    ! Workspace for elastic stiffness
    REAL(wp) :: D_el(6,6) = 0.0_wp           ! Elastic stiffness matrix

    ! Workspace for plastic computation
    REAL(wp) :: stress_trial(6) = 0.0_wp     ! Trial stress
    REAL(wp) :: strain_inc(6) = 0.0_wp       ! Strain increment
    REAL(wp) :: delta_lambda = 0.0_wp        ! Plastic multiplier increment
    REAL(wp) :: yield_function = 0.0_wp      ! Yield function value

    ! Field variable interpolation
    REAL(wp) :: field_var = 0.0_wp           ! Field variable

    ! Iteration tracking
    INTEGER(i4) :: num_iterations = 0
    LOGICAL :: converged = .FALSE.
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
  END TYPE MD_Mat_Plast_Ctx
```

### `MD_Mat_Plast_Reg_Arg` (lines 587–600)

```fortran
  TYPE, PUBLIC :: MD_Mat_Plast_Reg_Arg
    ! [IN] properties
    INTEGER(i4) :: sub_type         ! [IN]  sub-type ID
    INTEGER(i4) :: nprops           ! [IN]  number of properties
    REAL(wp)    :: E                ! [IN]  Young's modulus
    REAL(wp)    :: nu               ! [IN]  Poisson ratio
    REAL(wp), ALLOCATABLE :: props(:) ! [IN]  material properties array
    INTEGER(i4) :: dependencies     ! [IN]  temp/field dependencies

    ! [OUT] results
    INTEGER(i4) :: mat_id           ! [OUT] assigned material ID
    INTEGER(i4) :: status_code      ! [OUT] exit status
    CHARACTER(len=256) :: message   ! [OUT] status message
  END TYPE MD_Mat_Plast_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 244 | `SUBROUTINE Desc_Init(desc, sub_type, num_constants, &` |
| SUBROUTINE | `Desc_Validate` | 284 | `SUBROUTINE Desc_Validate(desc, status)` |
| SUBROUTINE | `Desc_ComputeDerived` | 337 | `SUBROUTINE Desc_ComputeDerived(desc, status)` |
| SUBROUTINE | `Desc_Clean` | 362 | `SUBROUTINE Desc_Clean(desc, status)` |
| SUBROUTINE | `State_Init` | 405 | `SUBROUTINE State_Init(state, status)` |
| SUBROUTINE | `State_Update` | 431 | `SUBROUTINE State_Update(state, stress, strain, eps_pl, &` |
| SUBROUTINE | `State_Clean` | 457 | `SUBROUTINE State_Clean(state, status)` |
| SUBROUTINE | `Algo_Init` | 483 | `SUBROUTINE Algo_Init(algo, status)` |
| SUBROUTINE | `Algo_Config` | 503 | `SUBROUTINE Algo_Config(algo, integration_method, tangent_type, &` |
| SUBROUTINE | `Ctx_Init` | 527 | `SUBROUTINE Ctx_Init(ctx, status)` |
| FUNCTION | `MD_Mat_Plast_Get_SubType_Name` | 550 | `FUNCTION MD_Mat_Plast_Get_SubType_Name(sub_type) RESULT(name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
