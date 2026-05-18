# `PH_MatEval.f90`

- **Source**: `L4_PH/Material/Dispatch/PH_MatEval.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_MatEval`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_MatEval`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_MatEval`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Dispatch/PH_MatEval.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_ElasticIsotropic_Eval_Arg` (lines 152–155)

```fortran
  TYPE, PUBLIC :: PH_Mat_ElasticIsotropic_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ElasticIsotropic_Eval_Arg
```

### `PH_Mat_ElasticOrthotropic_Eval_Arg` (lines 161–164)

```fortran
  TYPE, PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ElasticOrthotropic_Eval_Arg
```

### `PH_Mat_PlasticVonMises_Eval_Arg` (lines 170–174)

```fortran
  TYPE, PUBLIC :: PH_Mat_PlasticVonMises_Eval_Arg
    TYPE(MD_PlasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: equiv_plastic_strain  ! Equivalent plastic strain ε̄_p                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_PlasticVonMises_Eval_Arg
```

### `PH_Mat_PlasticHill_Eval_Arg` (lines 180–184)

```fortran
  TYPE, PUBLIC :: PH_Mat_PlasticHill_Eval_Arg
    TYPE(MD_PlasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: equiv_plastic_strain  ! Equivalent plastic strain ε̄_p                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_PlasticHill_Eval_Arg
```

### `PH_Mat_HyperelasticNeoHookean_Eval_Arg` (lines 190–193)

```fortran
  TYPE, PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval_Arg
    TYPE(MD_HyperElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_HyperelasticNeoHookean_Eval_Arg
```

### `PH_Mat_HyperelasticMooneyRivlin_Eval_Arg` (lines 199–202)

```fortran
  TYPE, PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
    TYPE(MD_HyperElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
```

### `PH_Mat_DamageDuctile_Eval_Arg` (lines 208–211)

```fortran
  TYPE, PUBLIC :: PH_Mat_DamageDuctile_Eval_Arg
    REAL(wp) :: damage  ! Damage variable D  ?[0,1]                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_DamageDuctile_Eval_Arg
```

### `PH_Mat_DamageBrittle_Eval_Arg` (lines 217–220)

```fortran
  TYPE, PUBLIC :: PH_Mat_DamageBrittle_Eval_Arg
    REAL(wp) :: damage  ! Damage variable D  ?[0,1]                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_DamageBrittle_Eval_Arg
```

### `PH_Mat_CreepNorton_Eval_Arg` (lines 226–230)

```fortran
  TYPE, PUBLIC :: PH_Mat_CreepNorton_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: temperature  ! Temperature T                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_CreepNorton_Eval_Arg
```

### `PH_Mat_ViscoelasticProny_Eval_Arg` (lines 236–241)

```fortran
  TYPE, PUBLIC :: PH_Mat_ViscoelasticProny_Eval_Arg
    TYPE(MD_PronyMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: time  ! Current time t                   ! [IN]
    REAL(wp) :: dtime  ! Time increment Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ViscoelasticProny_Eval_Arg
```

### `PH_Mat_ViscoelasticMaxwell_Eval_Arg` (lines 247–251)

```fortran
  TYPE, PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    REAL(wp) :: dtime  ! Time increment Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ViscoelasticMaxwell_Eval_Arg
```

### `PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg` (lines 257–260)

```fortran
  TYPE, PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
```

### `PH_Mat_CompositeLaminate_Eval_Arg` (lines 266–269)

```fortran
  TYPE, PUBLIC :: PH_Mat_CompositeLaminate_Eval_Arg
    INTEGER(i4) :: n_layers  ! Number of layers                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_CompositeLaminate_Eval_Arg
```

### `PH_Mat_CompositeFiberReinforced_Eval_Arg` (lines 275–278)

```fortran
  TYPE, PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval_Arg
    TYPE(MD_CompositeMatDesc) :: mat_desc                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_CompositeFiberReinforced_Eval_Arg
```

### `PH_Mat_UMATEnsureWorkspace_Arg` (lines 284–287)

```fortran
  TYPE, PUBLIC :: PH_Mat_UMATEnsureWorkspace_Arg
    INTEGER(i4) :: nstate_target  ! Minimum number of state variables required                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Mat_UMATEnsureWorkspace_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_CompositeFiberReinforced_Eval` | 292 | `SUBROUTINE PH_Mat_CompositeFiberReinforced_Eval(arg)` |
| SUBROUTINE | `PH_Mat_CompositeLaminate_Eval` | 326 | `SUBROUTINE PH_Mat_CompositeLaminate_Eval(arg)` |
| SUBROUTINE | `PH_Mat_CreepNorton_Eval` | 358 | `SUBROUTINE PH_Mat_CreepNorton_Eval(arg)` |
| SUBROUTINE | `PH_Mat_DamageBrittle_Eval` | 407 | `SUBROUTINE PH_Mat_DamageBrittle_Eval(arg)` |
| SUBROUTINE | `PH_Mat_DamageDuctile_Eval` | 426 | `SUBROUTINE PH_Mat_DamageDuctile_Eval(arg)` |
| SUBROUTINE | `PH_Mat_ElasticIsotropic_Eval` | 451 | `SUBROUTINE PH_Mat_ElasticIsotropic_Eval(arg)` |
| SUBROUTINE | `PH_Mat_ElasticOrthotropic_Eval` | 496 | `SUBROUTINE PH_Mat_ElasticOrthotropic_Eval(arg)` |
| SUBROUTINE | `PH_Mat_HyperelasticMooneyRivlin_Eval` | 564 | `SUBROUTINE PH_Mat_HyperelasticMooneyRivlin_Eval(arg)` |
| SUBROUTINE | `PH_Mat_HyperelasticNeoHookean_Eval` | 584 | `SUBROUTINE PH_Mat_HyperelasticNeoHookean_Eval(arg)` |
| SUBROUTINE | `PH_Mat_PlasticHill_Eval` | 603 | `SUBROUTINE PH_Mat_PlasticHill_Eval(arg)` |
| SUBROUTINE | `PH_Mat_PlasticVonMises_Eval` | 675 | `SUBROUTINE PH_Mat_PlasticVonMises_Eval(arg)` |
| SUBROUTINE | `PH_Mat_UMATEnsureWorkspace` | 743 | `SUBROUTINE PH_Mat_UMATEnsureWorkspace(arg)` |
| SUBROUTINE | `PH_Mat_ViscoelasticKelvinVoigt_Eval` | 760 | `SUBROUTINE PH_Mat_ViscoelasticKelvinVoigt_Eval(arg)` |
| SUBROUTINE | `PH_Mat_ViscoelasticMaxwell_Eval` | 778 | `SUBROUTINE PH_Mat_ViscoelasticMaxwell_Eval(arg)` |
| SUBROUTINE | `PH_Mat_ViscoelasticProny_Eval` | 803 | `SUBROUTINE PH_Mat_ViscoelasticProny_Eval(arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
