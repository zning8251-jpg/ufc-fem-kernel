# `PH_Mat_Hyper_Def.f90`

- **Source**: `L4_PH/Material/Hyper/PH_Mat_Hyper_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Hyper_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Hyper_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Hyper`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Hyper`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Hyper/PH_Mat_Hyper_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Hyper_Cfg_Init_Desc` (lines 22–26)

```fortran
  TYPE :: PH_Mat_Hyper_Cfg_Init_Desc
    INTEGER(i4) :: family_type = 0
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: property_flags = 0
  END TYPE PH_Mat_Hyper_Cfg_Init_Desc
```

### `PH_Mat_Hyper_Pop_Vld_Desc` (lines 28–30)

```fortran
  TYPE :: PH_Mat_Hyper_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Hyper_Pop_Vld_Desc
```

### `PH_Mat_Hyper_Inc_Evo_Ctx` (lines 32–36)

```fortran
  TYPE :: PH_Mat_Hyper_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
    ! TYPE-003: field-variable vector aliases caller/workspace buffer (not ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: field_var => NULL()
  END TYPE PH_Mat_Hyper_Inc_Evo_Ctx
```

### `PH_Mat_Hyper_Desc` (lines 42–71)

```fortran
  TYPE :: PH_Mat_Hyper_Desc
    TYPE(PH_Mat_Hyper_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Hyper_Pop_Vld_Desc) :: pop
    REAL(wp) :: C10 = 0.0_wp, C01 = 0.0_wp, D1 = 0.0_wp
    INTEGER(i4) :: num_ogden_terms = 0
    REAL(wp), ALLOCATABLE :: mu_ogden(:), alpha_ogden(:), D_ogden(:)

    ! Yeoh model (404)
    REAL(wp) :: C20 = 0.0_wp            ! Yeoh 2nd order coeff
    REAL(wp) :: C30 = 0.0_wp            ! Yeoh 3rd order coeff

    ! Arruda-Boyce model (405)
    REAL(wp) :: mu_ab = 0.0_wp          ! Arruda-Boyce shear modulus
    REAL(wp) :: lambda_L = 0.0_wp       ! Arruda-Boyce locking stretch
    INTEGER(i4) :: n_ab_terms = 5_i4    ! Arruda-Boyce series terms

    ! Hyperfoam model (406)
    REAL(wp) :: mu_i(5) = 0.0_wp        ! Hyperfoam shear moduli
    REAL(wp) :: alpha_i(5) = 0.0_wp     ! Hyperfoam exponents
    REAL(wp) :: beta_i(5) = 0.0_wp      ! Hyperfoam Poisson ratios

    ! Mullins effect (407)
    REAL(wp) :: r_mullins = 0.0_wp      ! Mullins damage parameter
    REAL(wp) :: beta_mullins = 0.0_wp   ! Mullins evolution rate
    REAL(wp) :: eta_max = 1.0_wp        ! Mullins maximum damage
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Hyper_Desc
```

### `PH_Mat_Hyper_State` (lines 73–83)

```fortran
  TYPE :: PH_Mat_Hyper_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: F(3,3) = 0.0_wp, C(3,3) = 0.0_wp
    REAL(wp) :: I1 = 0.0_wp, I2 = 0.0_wp, I3 = 0.0_wp, J = 1.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Hyper_State
```

### `PH_Mat_Hyper_Algo` (lines 85–91)

```fortran
  TYPE :: PH_Mat_Hyper_Algo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Hyper_Algo
```

### `PH_Mat_Hyper_Ctx` (lines 93–100)

```fortran
  TYPE :: PH_Mat_Hyper_Ctx
    TYPE(PH_Mat_Hyper_Inc_Evo_Ctx) :: inc
    REAL(wp) :: F_trial(3,3) = 0.0_wp, S(3,3) = 0.0_wp
    REAL(wp) :: dW_dI1 = 0.0_wp, dW_dI2 = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Hyper_Ctx
```

### `PH_Mat_Hyper_Eval_Arg` (lines 102–111)

```fortran
  TYPE :: PH_Mat_Hyper_Eval_Arg
    REAL(wp) :: F(3,3)              ! [IN] Deformation gradient
    REAL(wp) :: dt                  ! [IN] Time increment
    REAL(wp) :: temperature         ! [IN] Current temperature
    REAL(wp), ALLOCATABLE :: statev(:)  ! [INOUT] state variables array
    REAL(wp) :: stress(6)           ! [OUT] Cauchy stress (Voigt)
    REAL(wp) :: ddsdde(6,6)         ! [OUT] Tangent stiffness
    INTEGER(i4) :: status_code      ! [OUT] Completion status code
    CHARACTER(len=256) :: message   ! [OUT] Status message
  END TYPE PH_Mat_Hyper_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 125 | `SUBROUTINE Desc_Init(self)` |
| SUBROUTINE | `Desc_Valid` | 155 | `SUBROUTINE Desc_Valid(self)` |
| SUBROUTINE | `Desc_Clean` | 160 | `SUBROUTINE Desc_Clean(self)` |
| SUBROUTINE | `State_Init` | 194 | `SUBROUTINE State_Init(self)` |
| SUBROUTINE | `State_Update` | 208 | `SUBROUTINE State_Update(self)` |
| SUBROUTINE | `State_Clean` | 214 | `SUBROUTINE State_Clean(self)` |
| SUBROUTINE | `Algo_Init` | 232 | `SUBROUTINE Algo_Init(self)` |
| SUBROUTINE | `Algo_Config` | 238 | `SUBROUTINE Algo_Config(self)` |
| SUBROUTINE | `Ctx_Init` | 248 | `SUBROUTINE Ctx_Init(self)` |
| SUBROUTINE | `Ctx_Clean` | 258 | `SUBROUTINE Ctx_Clean(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
