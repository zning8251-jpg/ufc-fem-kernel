# `PH_Elem_Utils.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_Utils.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Utils`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Utils`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Utils`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_Utils.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ElemQualityArgs` (lines 42–72)

```fortran
    TYPE :: PH_ElemQualityArgs
      ! ---- POINTER ----
      REAL(wp), POINTER :: coords_old(:,:) => NULL()  !! (dim,nnode)
      REAL(wp), POINTER :: coords_new(:,:) => NULL()  !! (dim,nnode)
      REAL(wp), POINTER :: coords(:,:)     => NULL()  !! (dim,nnode)

      ! ---- ----
      INTEGER(i4) :: n_gauss = 2_i4  ! Gauss point count

      ! ---- ----
      REAL(wp) :: density_old = 0.0_wp  !! ρ₀
      REAL(wp) :: density_new = 0.0_wp  !! ρ

      ! ---- ----
      REAL(wp) :: volume     = 0.0_wp  ! element volume (integrated)
      REAL(wp) :: mass       = 0.0_wp  ! element mass
      REAL(wp) :: mass_error = 0.0_wp  ! mass-balance error metric

      ! ---- ----
      LOGICAL  :: mass_conserved = .FALSE.! mass conservation flag
      REAL(wp) :: aspect_ratio   = 0.0_wp  ! element aspect ratio metric
      REAL(wp) :: skewness       = 0.0_wp  ! element skewness metric
      REAL(wp) :: distortion     = 0.0_wp  ! element distortion metric

      ! ---- Jacobian ----
      REAL(wp), POINTER :: jacobian(:,:)   => NULL()  !! Jacobian
      REAL(wp)           :: jacobian_det   = 0.0_wp   !! Jacobian

      ! ---- ----
      TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
    END TYPE PH_ElemQualityArgs
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_El_CheckMassConservation` | 76 | `SUBROUTINE PH_El_CheckMassConservation(coords_old, coords_new, &` |
| SUBROUTINE | `PH_El_ComputeVolumeExtended` | 121 | `SUBROUTINE PH_El_ComputeVolumeExtended(coords, n_gauss, volume, &` |
| SUBROUTINE | `PH_Elem_CheckQuality` | 149 | `SUBROUTINE PH_Elem_CheckQuality(coords, quality_metrics, is_good, status)` |
| SUBROUTINE | `PH_Elem_ComputeJacobian` | 181 | `SUBROUTINE PH_Elem_ComputeJacobian(coords, dN_dxi, jacobian, jacobian_det, status)` |
| SUBROUTINE | `PH_Elem_ComputeMass` | 237 | `SUBROUTINE PH_Elem_ComputeMass(coords, density, n_gauss, mass, status)` |
| SUBROUTINE | `PH_Elem_ComputeVolume` | 262 | `SUBROUTINE PH_Elem_ComputeVolume(coords, n_gauss, volume, status)` |
| SUBROUTINE | `PH_Elem_GetCornerIndices2D` | 320 | `SUBROUTINE PH_Elem_GetCornerIndices2D(n_nodes, corner_ids, n_corner, status)` |
| SUBROUTINE | `PH_Elem_GetCornerIndices3D` | 350 | `SUBROUTINE PH_Elem_GetCornerIndices3D(n_nodes, corner_ids, n_corner, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
