# `PH_Mat_KernelDefn.f90`

- **Source**: `L4_PH/Material/PH_Mat_KernelDefn.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_KernelDefn`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_KernelDefn`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_KernelDefn`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_KernelDefn.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Update_Arg` (lines 18–29)

```fortran
  TYPE, PUBLIC :: PH_Mat_Update_Arg
    INTEGER(i4) :: ntens = 6_i4
    INTEGER(i4) :: mat_model_id = 0_i4
    REAL(wp)    :: dt    = 0.0_wp
    REAL(wp)    :: strain_n(6)  = 0.0_wp
    REAL(wp)    :: dstrain(6)   = 0.0_wp
    REAL(wp)    :: stress_new(6) = 0.0_wp
    REAL(wp)    :: D_tang(6, 6) = 0.0_wp
    REAL(wp), POINTER :: props(:)   => NULL()
    REAL(wp), POINTER :: sdv_n(:)   => NULL()
    REAL(wp), ALLOCATABLE :: sdv_tr(:)
  END TYPE PH_Mat_Update_Arg
```

### `PH_Mat_KernelBase` (lines 31–37)

```fortran
  TYPE, ABSTRACT, PUBLIC :: PH_Mat_KernelBase
    INTEGER(i4) :: n_sdv = 0_i4
  CONTAINS
    PROCEDURE(PH_Mat_UpdateStress_Ifc), DEFERRED :: UpdateStress
    PROCEDURE(PH_Mat_ComputeCTM_Ifc), DEFERRED :: ComputeCTM
    PROCEDURE(PH_Mat_InitSDV_Ifc), DEFERRED :: InitSDV
  END TYPE PH_Mat_KernelBase
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_UpdateStress_Ifc` | 40 | `SUBROUTINE PH_Mat_UpdateStress_Ifc(this, uarg, istat)` |
| SUBROUTINE | `PH_Mat_ComputeCTM_Ifc` | 46 | `SUBROUTINE PH_Mat_ComputeCTM_Ifc(this, uarg, istat)` |
| SUBROUTINE | `PH_Mat_InitSDV_Ifc` | 52 | `SUBROUTINE PH_Mat_InitSDV_Ifc(this, sdv, nsdv, istat)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
