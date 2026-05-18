# `RT_Elem_Proc.f90`

- **Source**: `L5_RT/Element/RT_Elem_Proc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_Proc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Elem_Init_In` (lines 105–109)

```fortran
  TYPE, PUBLIC :: Elem_Init_In
    INTEGER(i4) :: elem_type_id = 0      ! Element type ID
    INTEGER(i4) :: sect_id = 0           ! Section ID
    INTEGER(i4) :: mat_id = 0            ! Material ID
  END TYPE Elem_Init_In
```

### `Elem_Init_Out` (lines 112–118)

```fortran
  TYPE, PUBLIC :: Elem_Init_Out
    TYPE(RT_Elem_Desc) :: desc
    TYPE(RT_Elem_Ctx) :: ctx
    TYPE(RT_Elem_State) :: state
    TYPE(RT_Elem_Algo) :: algo
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Init_Out
```

### `Elem_Ke_In` (lines 121–125)

```fortran
  TYPE, PUBLIC :: Elem_Ke_In
    REAL(wp), POINTER :: coords(:,:) => NULL()    ! [ndim, n_nodes]
    REAL(wp), POINTER :: u(:) => NULL()            ! [n_dof] displacement
    REAL(wp), POINTER :: du(:) => NULL()           ! [n_dof] displacement increment
  END TYPE Elem_Ke_In
```

### `Elem_Ke_Out` (lines 128–132)

```fortran
  TYPE, PUBLIC :: Elem_Ke_Out
    REAL(wp), ALLOCATABLE :: Ke(:,:)    ! [n_dof, n_dof]
    REAL(wp), ALLOCATABLE :: Fe(:)      ! [n_dof] residual
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Ke_Out
```

### `Elem_Fe_In` (lines 135–139)

```fortran
  TYPE, PUBLIC :: Elem_Fe_In
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp), POINTER :: u(:) => NULL()
    INTEGER(i4) :: load_case = 0        ! Load case
  END TYPE Elem_Fe_In
```

### `Elem_Fe_Out` (lines 142–145)

```fortran
  TYPE, PUBLIC :: Elem_Fe_Out
    REAL(wp), ALLOCATABLE :: Fe(:)    ! [n_dof]
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Fe_Out
```

### `Elem_Me_In` (lines 148–151)

```fortran
  TYPE, PUBLIC :: Elem_Me_In
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp) :: mass_density = 0.0_wp   ! Mass density
  END TYPE Elem_Me_In
```

### `Elem_Me_Out` (lines 154–157)

```fortran
  TYPE, PUBLIC :: Elem_Me_Out
    REAL(wp), ALLOCATABLE :: Me(:,:)    ! [n_dof, n_dof]
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Me_Out
```

### `Elem_Ce_In` (lines 160–164)

```fortran
  TYPE, PUBLIC :: Elem_Ce_In
    REAL(wp), POINTER :: coords(:,:) => NULL()
    REAL(wp) :: damping_alpha = 0.0_wp  ! Rayleigh alpha
    REAL(wp) :: damping_beta = 0.0_wp   ! Rayleigh beta
  END TYPE Elem_Ce_In
```

### `Elem_Ce_Out` (lines 167–170)

```fortran
  TYPE, PUBLIC :: Elem_Ce_Out
    REAL(wp), ALLOCATABLE :: Ce(:,:)    ! [n_dof, n_dof]
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Ce_Out
```

### `Elem_Out_In` (lines 173–176)

```fortran
  TYPE, PUBLIC :: Elem_Out_In
    INTEGER(i4) :: ip_mask = 0          ! Integration point mask
    INTEGER(i4) :: node_mask = 0        ! Node mask
  END TYPE Elem_Out_In
```

### `Elem_Out_Out` (lines 179–183)

```fortran
  TYPE, PUBLIC :: Elem_Out_Out
    REAL(wp), ALLOCATABLE :: svars(:)   ! State variables
    REAL(wp) :: energy(8) = 0.0_wp      ! Energy
    TYPE(ErrorStatusType) :: status
  END TYPE Elem_Out_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Elem_Init_Interface` | 25 | `SUBROUTINE Elem_Init_Interface(state, ctx, inp, out)` |
| SUBROUTINE | `Elem_ComputeKe_Interface` | 36 | `SUBROUTINE Elem_ComputeKe_Interface(state, ctx, inp, out)` |
| SUBROUTINE | `Elem_ComputeFe_Interface` | 47 | `SUBROUTINE Elem_ComputeFe_Interface(state, ctx, inp, out)` |
| SUBROUTINE | `Elem_ComputeMe_Interface` | 58 | `SUBROUTINE Elem_ComputeMe_Interface(state, ctx, inp, out)` |
| SUBROUTINE | `Elem_ComputeCe_Interface` | 69 | `SUBROUTINE Elem_ComputeCe_Interface(state, ctx, inp, out)` |
| SUBROUTINE | `Elem_CollectOutput_Interface` | 80 | `SUBROUTINE Elem_CollectOutput_Interface(state, ctx, inp, out)` |
| SUBROUTINE | `Elem_Finalize_Interface` | 91 | `SUBROUTINE Elem_Finalize_Interface(state, ctx, inp, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
