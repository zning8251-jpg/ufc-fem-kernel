# `PH_Ldbc_SurfaceTraction.f90`

- **Source**: `L4_PH/LoadBC/PH_Ldbc_SurfaceTraction.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Ldbc_SurfaceTraction`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Ldbc_SurfaceTraction`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Ldbc_SurfaceTraction`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_Ldbc_SurfaceTraction.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_SurfLoad_Data` (lines 65–73)

```fortran
  TYPE, PUBLIC :: PH_SurfLoad_Data
    INTEGER(i4) :: face_type = SLOAD_FACE_QUAD4    ! Face element type
    INTEGER(i4) :: face_nodes(MAX_FACE_NODES) = 0  ! Face node IDs (local)
    INTEGER(i4) :: n_face_nodes = 4_i4             ! Actual face node count
    REAL(wp)    :: traction(3) = 0.0_wp            ! Traction vector [N/m^2]
    REAL(wp)    :: pressure    = 0.0_wp            ! Pressure scalar [Pa]
    LOGICAL     :: is_follower = .FALSE.           ! Follower load flag
    INTEGER(i4) :: n_gp_face  = 4_i4              ! # Gauss points on face (2×2)
  END TYPE PH_SurfLoad_Data
```

### `PH_BodyForce_Data` (lines 78–83)

```fortran
  TYPE, PUBLIC :: PH_BodyForce_Data
    REAL(wp) :: body_force(3) = 0.0_wp    ! Body force vector [N/m^3]
    REAL(wp) :: density       = 0.0_wp    ! Material density [kg/m^3]
    REAL(wp) :: gravity(3)    = 0.0_wp    ! Gravity vector [m/s^2]
    INTEGER(i4) :: n_gp_vol  = 8_i4      ! # Gauss points in volume (2×2×2)
  END TYPE PH_BodyForce_Data
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_SurfLoad_Init` | 90 | `SUBROUTINE PH_SurfLoad_Init(status)` |
| SUBROUTINE | `PH_SurfLoad_Traction` | 104 | `SUBROUTINE PH_SurfLoad_Traction(face_coords, n_face_nodes, traction, &` |
| SUBROUTINE | `PH_SurfLoad_Pressure` | 161 | `SUBROUTINE PH_SurfLoad_Pressure(face_coords, n_face_nodes, pressure, &` |
| SUBROUTINE | `PH_SurfLoad_FollowerPressure` | 211 | `SUBROUTINE PH_SurfLoad_FollowerPressure(face_coords_current, n_face_nodes, pressure, &` |
| SUBROUTINE | `PH_SurfLoad_BodyForce` | 304 | `SUBROUTINE PH_SurfLoad_BodyForce(elem_coords, npe, body_vec, &` |
| SUBROUTINE | `PH_SurfLoad_Concentrated` | 350 | `SUBROUTINE PH_SurfLoad_Concentrated(F_ext, node_id, dof_dir, force_mag, &` |
| SUBROUTINE | `PH_SurfLoad_ComputeAll` | 382 | `SUBROUTINE PH_SurfLoad_ComputeAll(status)` |
| SUBROUTINE | `EvalFaceShape` | 405 | `SUBROUTINE EvalFaceShape(xi, eta, n_nodes, N, dNdxi, dNdeta)` |
| SUBROUTINE | `EvalVolumeShape` | 485 | `SUBROUTINE EvalVolumeShape(xi, eta, zeta, npe, N, dNdxi)` |
| SUBROUTINE | `ComputeJacobian3D` | 541 | `SUBROUTINE ComputeJacobian3D(coords, dNdxi, npe, J, detJ)` |
| SUBROUTINE | `GetGaussPoint2D` | 567 | `SUBROUTINE GetGaussPoint2D(igp, n_gp, xi, eta, w)` |
| SUBROUTINE | `GetGaussPoint3D` | 605 | `SUBROUTINE GetGaussPoint3D(igp, n_gp, xi, eta, zeta, w)` |
| SUBROUTINE | `Cross3` | 647 | `PURE SUBROUTINE Cross3(a, b, c)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
