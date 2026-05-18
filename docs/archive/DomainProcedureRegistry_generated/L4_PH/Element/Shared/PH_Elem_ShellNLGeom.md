# `PH_Elem_ShellNLGeom.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_ShellNLGeom.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_ShellNLGeom`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_ShellNLGeom`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_ShellNLGeom`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_ShellNLGeom.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Shell_NL_Args` (lines 32–67)

```fortran
  TYPE, PUBLIC :: PH_Shell_NL_Args
    !-- Input: Shell kinematics
    REAL(wp), ALLOCATABLE :: coords_ref(:,:)    ! Reference mid-surface [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: coords_cur(:,:)    ! Current mid-surface [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: director_ref(:,:)  ! Reference director [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: director_cur(:,:)  ! Current director [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)      ! Shape func derivs [n_nodes, dim, n_ip]
    
    !-- Input: Integration point info
    REAL(wp) :: zeta = 0.0_wp                  ! Through-thickness coordinate (-1 to 1)
    REAL(wp) :: thickness = 1.0_wp              ! Shell thickness
    INTEGER(i4) :: layer_id = 1                 ! Layer number
    
    !-- Output: Strain measures (shell-specific)
    REAL(wp), ALLOCATABLE :: E_membrane(:)      ! Membrane Green-Lagrange strain [5]
    REAL(wp), ALLOCATABLE :: E_bending(:)       ! Bending Green-Lagrange strain [5]
    REAL(wp), ALLOCATABLE :: gamma_shear(:)     ! Transverse shear strain [2]
    
    !-- Output: Deformation measures
    REAL(wp) :: F_mid(3, 3)                     ! Mid-surface deformation gradient
    REAL(wp) :: F_layer(3, 3)                   ! Layer-wise deformation gradient
    REAL(wp) :: detF = 1.0_wp                   ! Jacobian J = det(F)
    
    !-- Output: Stress measures
    REAL(wp), ALLOCATABLE :: N_stress(:)        ! Membrane stress resultant [5]
    REAL(wp), ALLOCATABLE :: M_stress(:)        ! Bending moment resultant [5]
    REAL(wp), ALLOCATABLE :: Q_shear(:)         ! Transverse shear force [2]
    
    !-- Metadata
    INTEGER(i4) :: ndim = 3                     ! Spatial dimension (always 3D for shells)
    INTEGER(i4) :: nl_geom_type = SHELL_NL_NONE ! TL/UL/None
    LOGICAL :: mitc_enabled = .TRUE.            ! MITC shear treatment
    LOGICAL :: fbar_enabled = .FALSE.           ! F-bar stabilization
    LOGICAL :: is_valid = .FALSE.               ! Validation flag
    
  END TYPE PH_Shell_NL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Shell_Compute_Deformation_ThroughThickness` | 86 | `SUBROUTINE PH_Shell_Compute_Deformation_ThroughThickness(args, status)` |
| SUBROUTINE | `PH_Shell_Compute_Green_Lagrange_Strain` | 139 | `SUBROUTINE PH_Shell_Compute_Green_Lagrange_Strain(args, status)` |
| SUBROUTINE | `PH_Shell_Compute_Almansi_Strain` | 177 | `SUBROUTINE PH_Shell_Compute_Almansi_Strain(args, status)` |
| SUBROUTINE | `PH_Shell_Compute_Membrane_Bending_Strain` | 218 | `SUBROUTINE PH_Shell_Compute_Membrane_Bending_Strain(args, status)` |
| SUBROUTINE | `PH_Shell_Apply_FBar_Stabilization` | 243 | `SUBROUTINE PH_Shell_Apply_FBar_Stabilization(args, status)` |
| SUBROUTINE | `PH_Shell_Compute_Stress_Resultants` | 269 | `SUBROUTINE PH_Shell_Compute_Stress_Resultants(args, sigma_cauchy, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
