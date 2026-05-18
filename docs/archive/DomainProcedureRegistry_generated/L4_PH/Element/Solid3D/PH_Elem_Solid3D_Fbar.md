# `PH_Elem_Solid3D_Fbar.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_Solid3D_Fbar.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Solid3D_Fbar`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Solid3D_Fbar`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Solid3D_Fbar`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_Solid3D_Fbar.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Fbar_Ctx` (lines 44–65)

```fortran
  TYPE, PUBLIC :: PH_Fbar_Ctx
    REAL(wp) :: Jbar = 1.0_wp             ! 体积平均Jacobian J̄
    REAL(wp) :: volume = 0.0_wp           ! 单元参考体积 V₀

    ! 各GP的det(F)
    REAL(wp), ALLOCATABLE :: det_F_gp(:)  ! [n_gp]
    ! 各GP的 w_i * det(J)
    REAL(wp), ALLOCATABLE :: wt_detJ(:)   ! [n_gp]

    ! 变形梯度
    REAL(wp), ALLOCATABLE :: F_gp(:,:,:)      ! F at GP [n_gp,3,3]
    REAL(wp), ALLOCATABLE :: F_bar_gp(:,:,:)  ! F̄ at GP [n_gp,3,3]

    ! B̄矩阵 (显式计算后存储)
    REAL(wp), ALLOCATABLE :: B_bar(:,:,:)     ! B̄ [n_gp,6,ndof]

    ! 体积平均 B_vol
    REAL(wp) :: B_vol_avg(PH_FBAR_NSTR, PH_FBAR_NDOF) = 0.0_wp

    INTEGER(i4) :: n_gp = 8_i4
    LOGICAL :: is_active = .FALSE.
  END TYPE PH_Fbar_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Fbar_Init` | 75 | `SUBROUTINE PH_Fbar_Init(ctx, n_gp, status)` |
| SUBROUTINE | `PH_Fbar_ComputeJbar` | 133 | `SUBROUTINE PH_Fbar_ComputeJbar(ctx, F_gp, weights, det_J_gp, status)` |
| SUBROUTINE | `PH_Fbar_ModifyF` | 185 | `SUBROUTINE PH_Fbar_ModifyF(ctx, status)` |
| SUBROUTINE | `PH_Fbar_ComputeBbar` | 237 | `SUBROUTINE PH_Fbar_ComputeBbar(ctx, B_gp, status)` |
| SUBROUTINE | `PH_Fbar_ComputeKe` | 324 | `SUBROUTINE PH_Fbar_ComputeKe(ctx, D_tan_gp, stress_gp, weights, det_J_gp, &` |
| SUBROUTINE | `PH_Fbar_ComputeFe` | 406 | `SUBROUTINE PH_Fbar_ComputeFe(ctx, stress_gp, weights, det_J_gp, &` |
| FUNCTION | `Det3x3_local` | 447 | `FUNCTION Det3x3_local(A) RESULT(det)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
