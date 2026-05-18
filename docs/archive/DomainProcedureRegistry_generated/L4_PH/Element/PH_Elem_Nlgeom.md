# `PH_Elem_Nlgeom.f90`

- **Source**: `L4_PH/Element/PH_Elem_Nlgeom.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Nlgeom`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Nlgeom`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Nlgeom`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_Nlgeom.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Nlgeom_Args` (lines 29–53)

```fortran
  TYPE, PUBLIC :: PH_Nlgeom_Args
    !-- Input: kinematics
    REAL(wp), ALLOCATABLE :: coords_ref(:,:)  ! Reference coords [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: coords_cur(:,:)  ! Current coords [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:,:)    ! Shape func derivs [n_nodes, dim, n_ip]
    
    !-- Output: strain measures
    REAL(wp), ALLOCATABLE :: E_gl(:)          ! Green-Lagrange strain [6/n_strain]
    REAL(wp), ALLOCATABLE :: e_alm(:)         ! Almansi strain [6/n_strain]
    
    !-- Output: deformation measures
    REAL(wp), ALLOCATABLE :: F(:,:)           ! Deformation gradient [dim, dim]
    REAL(wp), ALLOCATABLE :: Finv(:,:)        ! Inverse F [dim, dim]
    REAL(wp) :: detF = 1.0_wp                 ! Jacobian J = det(F)
    
    !-- Output: stress measures
    REAL(wp), ALLOCATABLE :: S_pk2(:)         ! 2nd Piola-Kirchhoff [6/n_strain]
    REAL(wp), ALLOCATABLE :: sigma_cauchy(:)  ! Cauchy stress [6/n_strain]
    
    !-- Metadata
    INTEGER(i4) :: ndim = 3                   ! Spatial dimension
    INTEGER(i4) :: nlgeom_type = PH_ELEM_NLGEOM_NONE  ! TL/UL/None
    LOGICAL :: is_valid = .FALSE.             ! Validation flag
    
  END TYPE PH_Nlgeom_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Compute_Deformation_Gradient` | 71 | `SUBROUTINE PH_Compute_Deformation_Gradient(args, status)` |
| SUBROUTINE | `PH_Compute_Green_Lagrange_Strain` | 143 | `SUBROUTINE PH_Compute_Green_Lagrange_Strain(args, status)` |
| SUBROUTINE | `PH_Compute_Almansi_Strain` | 181 | `SUBROUTINE PH_Compute_Almansi_Strain(args, status)` |
| SUBROUTINE | `PH_Compute_B_Matrix_NL` | 220 | `SUBROUTINE PH_Compute_B_Matrix_NL(args, B_matrix, status)` |
| SUBROUTINE | `PH_Transform_Stress_PK2_to_Cauchy` | 275 | `SUBROUTINE PH_Transform_Stress_PK2_to_Cauchy(args, status)` |
| SUBROUTINE | `PH_Transform_Stress_Cauchy_to_PK2` | 322 | `SUBROUTINE PH_Transform_Stress_Cauchy_to_PK2(args, status)` |
| SUBROUTINE | `PH_Invert_Matrix_2x2_or_3x3` | 368 | `SUBROUTINE PH_Invert_Matrix_2x2_or_3x3(A, Ainv, ndim, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
