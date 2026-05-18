# `PH_UEL_Def.f90`

- **Source**: `L4_PH/Element/PH_UEL_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_UEL_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_UEL_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_UEL`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_UEL_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_UEL_Context` (lines 27–91)

```fortran
  TYPE, PUBLIC :: PH_UEL_Context
    !--- OUT: Results ---
    REAL(wp), ALLOCATABLE :: rhs(:,:)        ! rhs(ndofel, nrhs)
    REAL(wp), ALLOCATABLE :: amatrx(:,:)     ! amatrx(ndofel, ndofel)
    REAL(wp), ALLOCATABLE :: energy(:)       ! energy(8)

    !--- INOUT: State ---
    REAL(wp), ALLOCATABLE :: svars(:)        ! svars(nsvars)

    !--- IN: DOF / dimension scalars ---
    INTEGER(i4) :: ndofel   = 0_i4
    INTEGER(i4) :: nrhs     = 1_i4
    INTEGER(i4) :: nsvars   = 0_i4
    INTEGER(i4) :: nprops   = 0_i4
    INTEGER(i4) :: njprop   = 0_i4
    INTEGER(i4) :: nnode    = 0_i4
    INTEGER(i4) :: ndload   = 0_i4
    INTEGER(i4) :: mlvarx   = 0_i4
    INTEGER(i4) :: npredef  = 0_i4
    INTEGER(i4) :: nparam   = 0_i4

    !--- IN: Properties ---
    REAL(wp), ALLOCATABLE :: props(:)        ! props(nprops)
    INTEGER(i4), ALLOCATABLE :: jprops(:)    ! jprops(njprop)
    INTEGER(i4) :: jtype     = 0_i4

    !--- IN: Time / step ---
    REAL(wp), ALLOCATABLE :: time(:)         ! time(2)
    REAL(wp) :: dtime     = 0.0_wp
    INTEGER(i4) :: kstep   = 0_i4
    INTEGER(i4) :: kinc     = 0_i4

    !--- IN: Displacement / velocity / acceleration ---
    REAL(wp), ALLOCATABLE :: u(:)            ! u(ndofel)
    REAL(wp), ALLOCATABLE :: du(:)           ! du(ndofel)
    REAL(wp), ALLOCATABLE :: v(:)            ! v(ndofel)
    REAL(wp), ALLOCATABLE :: a(:)            ! a(ndofel)

    !--- IN: Coordinates ---
    REAL(wp), ALLOCATABLE :: coords(:,:)     ! coords(3, nnode)

    !--- IN: Load flags ---
    INTEGER(i4), ALLOCATABLE :: jdltyp(:)    ! jdltyp(ndload)
    INTEGER(i4), ALLOCATABLE :: lflags(:)    ! lflags(6)

    !--- IN: Predefined fields ---
    REAL(wp), ALLOCATABLE :: preload(:,:)    ! preload(npredef, nnode)

    !--- INOUT: Time increment control ---
    REAL(wp) :: pnewdt    = -1.0_wp

    !--- IN: Element identification ---
    REAL(wp) :: celent    = 0.0_wp
    INTEGER(i4) :: noel    = 0_i4
    INTEGER(i4) :: npt     = 0_i4
    INTEGER(i4) :: layer   = 0_i4
    INTEGER(i4) :: kspt    = 0_i4

    !--- IN: Parameters (extended UEL) ---
    REAL(wp), ALLOCATABLE :: params(:)       ! params(nparam)

  CONTAINS
    PROCEDURE, PUBLIC :: Init    => PH_UEL_Context_Init
    PROCEDURE, PUBLIC :: Cleanup => PH_UEL_Context_Clean
  END TYPE PH_UEL_Context
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_UEL_Intf` | 100 | `SUBROUTINE PH_UEL_Intf(ctx, status)` |
| SUBROUTINE | `PH_UEL_Context_Init` | 109 | `SUBROUTINE PH_UEL_Context_Init(this, ndofel, nrhs, nsvars, nprops, nnode, njprop)` |
| SUBROUTINE | `PH_UEL_Context_Clean` | 167 | `SUBROUTINE PH_UEL_Context_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
