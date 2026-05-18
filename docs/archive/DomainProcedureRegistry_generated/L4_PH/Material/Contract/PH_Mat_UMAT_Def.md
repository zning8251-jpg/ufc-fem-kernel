# `PH_Mat_UMAT_Def.f90`

- **Source**: `L4_PH/Material/Contract/PH_Mat_UMAT_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_UMAT_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_UMAT_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_UMAT`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Contract/PH_Mat_UMAT_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_UMAT_Context` (lines 22–48)

```fortran
  TYPE, PUBLIC :: PH_UMAT_Context
    REAL(wp), ALLOCATABLE :: sigma(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: ddsdde(:,:)
    REAL(wp) :: sse, spd, scd, rpl
    REAL(wp), ALLOCATABLE :: ddsddt(:)
    REAL(wp), ALLOCATABLE :: drplde(:)
    REAL(wp) :: drpldt
    REAL(wp), ALLOCATABLE :: stran(:)
    REAL(wp), ALLOCATABLE :: dstran(:)
    REAL(wp), ALLOCATABLE :: time(:)
    REAL(wp) :: dtime, temp, dtemp
    REAL(wp), ALLOCATABLE :: predef(:)
    REAL(wp), ALLOCATABLE :: dpred(:)
    CHARACTER(LEN=80) :: cmname
    INTEGER(i4) :: ndi, nshr, ntens, nstatv, nprops
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: coords(:)
    REAL(wp), ALLOCATABLE :: drot(:,:)
    REAL(wp) :: pnewdt, celent
    REAL(wp), ALLOCATABLE :: dfgrd0(:,:)
    REAL(wp), ALLOCATABLE :: dfgrd1(:,:)
    INTEGER(i4) :: noel, npt, layer, kspt, kinc, kstep
  CONTAINS
    PROCEDURE, PUBLIC :: Init => PH_UMAT_Context_Init
    PROCEDURE, PUBLIC :: Cleanup => PH_UMAT_Context_Clean
  END TYPE PH_UMAT_Context
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_UMAT_Intf` | 57 | `SUBROUTINE PH_UMAT_Intf(ctx, status)` |
| SUBROUTINE | `PH_UMAT_Context_Init` | 66 | `SUBROUTINE PH_UMAT_Context_Init(this, ndi, nshr, nstatv, nprops)` |
| SUBROUTINE | `PH_UMAT_Context_Clean` | 124 | `SUBROUTINE PH_UMAT_Context_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
