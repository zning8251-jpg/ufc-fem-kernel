# `PH_Mat_Core_Types.f90`

- **Source**: `L4_PH/Material/PH_Mat_Core_Types.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Core_Types`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Core_Types`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Core`
- **第四段角色（四段式）**: `_Types`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_Core_Types.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MatPoint_In` (lines 15–21)

```fortran
  TYPE :: MatPoint_In
    REAL(wp), ALLOCATABLE :: props(:)      ! Material properties
    REAL(wp) :: strain_inc(6) = 0.0_wp     ! Strain increment (Voigt)
    REAL(wp) :: sigma_old(6)  = 0.0_wp     ! Old stress (Voigt)
    INTEGER(i4) :: ntens = 6_i4            ! Number of tensor components
    REAL(wp), ALLOCATABLE :: statev(:)     ! State variables
  END TYPE MatPoint_In
```

### `MatPoint_Out` (lines 26–32)

```fortran
  TYPE :: MatPoint_Out
    REAL(wp) :: stress(6)   = 0.0_wp       ! Updated stress (Voigt)
    REAL(wp) :: ddsdde(6,6) = 0.0_wp       ! Material tangent (Voigt)
    REAL(wp) :: pnewdt      = 1.0_wp       ! Time step suggestion
    REAL(wp), ALLOCATABLE :: statev(:)     ! Updated state variables
    TYPE(ErrorStatusType) :: status        ! Error status
  END TYPE MatPoint_Out
```

### `MatInit_In` (lines 37–40)

```fortran
  TYPE :: MatInit_In
    REAL(wp), ALLOCATABLE :: props(:)      ! Material properties
    INTEGER(i4) :: nStatev = 0_i4          ! Number of state variables
  END TYPE MatInit_In
```

### `MatInit_Out` (lines 45–48)

```fortran
  TYPE :: MatInit_Out
    REAL(wp), ALLOCATABLE :: statev(:)     ! Initialized state variables
    TYPE(ErrorStatusType) :: status        ! Error status
  END TYPE MatInit_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
