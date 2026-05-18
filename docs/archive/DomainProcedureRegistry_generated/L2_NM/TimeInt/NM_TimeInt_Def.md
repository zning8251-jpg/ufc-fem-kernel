# `NM_TimeInt_Def.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_TimeInt_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_Def`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_TimeInt_Desc` (lines 30–32)

```fortran
  TYPE :: NM_TimeInt_Desc
    INTEGER(i4) :: ndof = 0
  END TYPE NM_TimeInt_Desc
```

### `NM_TimeInt_State` (lines 37–45)

```fortran
  TYPE :: NM_TimeInt_State
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dt   = 0.0_wp
    REAL(wp), POINTER :: u(:)      => NULL()
    REAL(wp), POINTER :: v(:)      => NULL()
    REAL(wp), POINTER :: a(:)      => NULL()
    REAL(wp), POINTER :: u_pred(:) => NULL()
    REAL(wp), POINTER :: v_pred(:) => NULL()
  END TYPE NM_TimeInt_State
```

### `NM_TimeInt_Ctx` (lines 50–55)

```fortran
  TYPE :: NM_TimeInt_Ctx
    REAL(wp)    :: dt_current  = 0.0_wp
    REAL(wp)    :: dt_previous = 0.0_wp
    REAL(wp)    :: t_current   = 0.0_wp
    INTEGER(i4) :: substep     = 0
  END TYPE NM_TimeInt_Ctx
```

### `NM_TInt_Step_Arg` (lines 60–67)

```fortran
  TYPE, PUBLIC :: NM_TInt_Step_Arg
    REAL(wp) :: dt       = 0.0_wp    ! [IN]  time step size
    REAL(wp) :: beta     = 0.25_wp   ! [IN]  Newmark beta
    REAL(wp) :: gamma    = 0.5_wp    ! [IN]  Newmark gamma
    REAL(wp) :: alpha_hht= 0.0_wp    ! [IN]  HHT alpha parameter
    INTEGER(i4) :: ndof  = 0         ! [IN]  number of DOFs
    TYPE(ErrorStatusType) :: status   ! [OUT]
  END TYPE NM_TInt_Step_Arg
```

### `NM_TimeInt_Algo` (lines 87–94)

```fortran
  TYPE :: NM_TimeInt_Algo
    INTEGER(i4) :: method    = NM_TINT_NEWMARK
    REAL(wp)    :: beta      = 0.25_wp
    REAL(wp)    :: gamma     = 0.5_wp
    REAL(wp)    :: alpha_hht = 0.0_wp
    ! --- Phase 6B: Procedure-as-Parameter time integration strategy pointer ---
    PROCEDURE(NM_TInt_Scheme_Ifc), POINTER, NOPASS :: scheme_strategy => NULL()
  END TYPE NM_TimeInt_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_TInt_Scheme_Ifc` | 75 | `SUBROUTINE NM_TInt_Scheme_Ifc(algo, state, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
