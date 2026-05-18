# `PH_Brg_L2.f90`

- **Source**: `L4_PH/Bridge/PH_Brg_L2.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Brg_L2`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Brg_L2`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Brg_L2`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/PH_Brg_L2.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Brg_ElemId_Desc` (lines 35–37)

```fortran
  TYPE, PUBLIC :: PH_Brg_ElemId_Desc
    INTEGER(i4) :: elem_id = 0
  END TYPE PH_Brg_ElemId_Desc
```

### `PH_Brg_GetElemConnectivity_Arg` (lines 39–45)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetElemConnectivity_Arg
    TYPE(MD_Geom_Ctx) :: geom_ctx                   ! [IN]
    INTEGER(i4) :: elem_id                          ! [IN]
    INTEGER(i4), ALLOCATABLE :: conn(:)             ! [OUT]
    INTEGER(i4) :: n_nodes                          ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetElemConnectivity_Arg
```

### `PH_Brg_GetNodeCoords_Arg` (lines 47–51)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetNodeCoords_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx                   ! [IN]
    REAL(wp), ALLOCATABLE :: coords(:,:)              ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetNodeCoords_Arg
```

### `PH_Brg_GetGauss_Pts1D_Arg` (lines 53–58)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetGauss_Pts1D_Arg
    INTEGER(i4) :: n_gp                             ! [IN]
    REAL(wp), ALLOCATABLE :: xi(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)             ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetGauss_Pts1D_Arg
```

### `PH_Brg_GetGauss_Pts2D_Arg` (lines 60–65)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetGauss_Pts2D_Arg
    INTEGER(i4) :: n_gp_per_dim                     ! [IN]
    REAL(wp), ALLOCATABLE :: xi(:,:)                ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)             ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetGauss_Pts2D_Arg
```

### `PH_Brg_GetGauss_Pts3D_Arg` (lines 67–72)

```fortran
  TYPE, PUBLIC :: PH_Brg_GetGauss_Pts3D_Arg
    INTEGER(i4) :: n_gp_per_dim                     ! [IN]
    REAL(wp), ALLOCATABLE :: xi(:,:)                ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)             ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetGauss_Pts3D_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Brg_GetElemConnectivity` | 76 | `SUBROUTINE PH_Brg_GetElemConnectivity(arg)` |
| SUBROUTINE | `PH_Brg_GetElemConnectivity_Idx` | 100 | `SUBROUTINE PH_Brg_GetElemConnectivity_Idx(elem_idx, arg, status)` |
| SUBROUTINE | `PH_Brg_GetGaussPoints1D` | 133 | `SUBROUTINE PH_Brg_GetGaussPoints1D(arg)` |
| SUBROUTINE | `PH_Brg_GetGaussPoints2D` | 155 | `SUBROUTINE PH_Brg_GetGaussPoints2D(arg)` |
| SUBROUTINE | `PH_Brg_GetGaussPoints3D` | 179 | `SUBROUTINE PH_Brg_GetGaussPoints3D(arg)` |
| SUBROUTINE | `PH_Brg_GetNodeCoords` | 203 | `SUBROUTINE PH_Brg_GetNodeCoords(arg)` |
| SUBROUTINE | `PH_Brg_GetNodeCoords_Idx` | 224 | `SUBROUTINE PH_Brg_GetNodeCoords_Idx(elem_idx, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
