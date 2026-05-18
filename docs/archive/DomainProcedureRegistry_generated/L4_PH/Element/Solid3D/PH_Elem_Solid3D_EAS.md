# `PH_Elem_Solid3D_EAS.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_Solid3D_EAS.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Solid3D_EAS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Solid3D_EAS`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Solid3D_EAS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_Solid3D_EAS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_EAS_Ctx` (lines 46–65)

```fortran
  TYPE, PUBLIC :: PH_EAS_Ctx
    INTEGER(i4) :: n_eas_modes = PH_EAS_NMODES  ! EAS增强模式数
    INTEGER(i4) :: n_gp        = 8_i4            ! Gauss点数
    INTEGER(i4) :: n_dof       = PH_EAS_NDOF     ! 单元自由度数

    ! 内部参数 α [n_eas_modes]
    REAL(wp) :: alpha(PH_EAS_NMODES) = 0.0_wp

    ! 增强模式矩阵 G/M at each GP: (n_gp, 6, n_eas_modes)
    REAL(wp), ALLOCATABLE :: G_matrix(:,:,:)

    ! 静态缩聚子矩阵
    REAL(wp) :: K_aa(PH_EAS_NMODES, PH_EAS_NMODES)  = 0.0_wp  ! K_αα [neas,neas]
    REAL(wp) :: K_da(PH_EAS_NDOF,   PH_EAS_NMODES)  = 0.0_wp  ! K_dα [ndof,neas]
    REAL(wp) :: K_ad(PH_EAS_NMODES, PH_EAS_NDOF)    = 0.0_wp  ! K_αd [neas,ndof]
    REAL(wp) :: h_alpha(PH_EAS_NMODES)               = 0.0_wp  ! h_α 残差

    LOGICAL :: is_active  = .FALSE.
    LOGICAL :: converged  = .FALSE.
  END TYPE PH_EAS_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_EAS_Init` | 75 | `SUBROUTINE PH_EAS_Init(ctx, n_gp, status)` |
| SUBROUTINE | `PH_EAS_BuildG` | 119 | `SUBROUTINE PH_EAS_BuildG(ctx, xi_gp, eta_gp, zeta_gp, det_J_gp, &` |
| SUBROUTINE | `PH_EAS_Condense` | 201 | `SUBROUTINE PH_EAS_Condense(ctx, K_dd, f_ext_minus_fint, &` |
| SUBROUTINE | `PH_EAS_UpdateAlpha` | 254 | `SUBROUTINE PH_EAS_UpdateAlpha(ctx, delta_d, stress_gp, D_tan_gp, &` |
| SUBROUTINE | `PH_EAS_ComputeKe` | 372 | `SUBROUTINE PH_EAS_ComputeKe(ctx, B_gp, D_tan_gp, stress_gp, &` |
| SUBROUTINE | `PH_EAS_ComputeFe` | 459 | `SUBROUTINE PH_EAS_ComputeFe(ctx, B_gp, stress_gp, weights, det_J_gp, &` |
| SUBROUTINE | `PH_EAS_InvertLU` | 502 | `SUBROUTINE PH_EAS_InvertLU(n, A, info)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
