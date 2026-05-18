# `MD_Mat_Hyper_Def.f90`

- **Source**: `L3_MD/Material/Hyper/MD_Mat_Hyper_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Hyper_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Hyper_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Hyper`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Hyper`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Hyper/MD_Mat_Hyper_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Hyper_Cfg_Init_Desc` (lines 41–47)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_Cfg_Init_Desc
    INTEGER(i4) :: family_type    = MD_MAT_FAMILY_HYPERELASTIC
    INTEGER(i4) :: sub_type       = MD_MAT_HE_SUB_NEOHOOKEAN
    INTEGER(i4) :: property_flags = MD_MAT_PROP_NONE
    INTEGER(i4) :: num_constants  = 0_i4
    INTEGER(i4) :: dependencies   = 0_i4
  END TYPE MD_Mat_Hyper_Cfg_Init_Desc
```

### `MD_Mat_Hyper_Pop_Vld_Desc` (lines 53–55)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Hyper_Pop_Vld_Desc
```

### `MD_Mat_Hyper_Stp_Evo_Ctx` (lines 61–64)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_Stp_Evo_Ctx
    REAL(wp) :: deformation_gradient(3,3) = 0.0_wp
    REAL(wp) :: J = 1.0_wp
  END TYPE MD_Mat_Hyper_Stp_Evo_Ctx
```

### `MD_Mat_Hyper_State` (lines 94–100)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_State
    REAL(wp) :: J = 1.0_wp
  CONTAINS
    PROCEDURE :: Init => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean => State_Clean
  END TYPE MD_Mat_Hyper_State
```

### `MD_Mat_Hyper_Algo` (lines 105–110)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_Algo
    INTEGER(i4) :: formulation = 1  ! 1=neo-Hookean, 2=Mooney-Rivlin, 3=Ogden, etc.
  CONTAINS
    PROCEDURE :: Init => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Hyper_Algo
```

### `MD_Mat_Hyper_Ctx` (lines 115–120)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_Ctx
    TYPE(MD_Mat_Hyper_Stp_Evo_Ctx) :: stp
    REAL(wp) :: stress(6) = 0.0_wp
  CONTAINS
    PROCEDURE :: Init => Ctx_Init
  END TYPE MD_Mat_Hyper_Ctx
```

### `MD_Mat_Hyper_Reg_Arg` (lines 337–350)

```fortran
  TYPE, PUBLIC :: MD_Mat_Hyper_Reg_Arg
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
  END TYPE MD_Mat_Hyper_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 129 | `SUBROUTINE Desc_Init(desc, sub_type, num_constants, &` |
| SUBROUTINE | `Desc_Validate` | 166 | `SUBROUTINE Desc_Validate(desc, status)` |
| SUBROUTINE | `MD_Mat_Hyper_ComputeDerived` | 186 | `SUBROUTINE MD_Mat_Hyper_ComputeDerived(desc, status)` |
| SUBROUTINE | `MD_Mat_Hyper_Clean` | 216 | `SUBROUTINE MD_Mat_Hyper_Clean(desc, status)` |
| SUBROUTINE | `State_Init` | 245 | `SUBROUTINE State_Init(state, status)` |
| SUBROUTINE | `State_Update` | 260 | `SUBROUTINE State_Update(state, J, status)` |
| SUBROUTINE | `State_Clean` | 276 | `SUBROUTINE State_Clean(state, status)` |
| SUBROUTINE | `Algo_Init` | 291 | `SUBROUTINE Algo_Init(algo, status)` |
| SUBROUTINE | `Algo_Config` | 306 | `SUBROUTINE Algo_Config(algo, formulation, status)` |
| SUBROUTINE | `Ctx_Init` | 322 | `SUBROUTINE Ctx_Init(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
