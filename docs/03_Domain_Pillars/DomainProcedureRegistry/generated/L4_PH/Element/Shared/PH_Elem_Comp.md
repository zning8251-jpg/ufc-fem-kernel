# `PH_Elem_Comp.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_Comp.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Comp`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Comp`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Comp`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_Comp.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Beam3DStiffArgs` (lines 50–71)

```fortran
  TYPE :: PH_Beam3DStiffArgs
    ! ---- ----
    REAL(wp) :: L       = 0.0_wp  !! (m)
    REAL(wp) :: A       = 0.0_wp  !! (m²)
    REAL(wp) :: Iy      = 0.0_wp  !! y (m�?
    REAL(wp) :: Iz      = 0.0_wp  !! z (m�?
    REAL(wp) :: J_tors  = 0.0_wp  !! (m�?

    ! ---- ----
    REAL(wp) :: E       = 0.0_wp  !! (Pa)
    REAL(wp) :: G       = 0.0_wp  !! (Pa)

    ! ---- ----
    REAL(wp) :: kappa_y = 5.0_wp/6.0_wp  !! y
    REAL(wp) :: kappa_z = 5.0_wp/6.0_wp  !! z

    ! ---- ----
    REAL(wp) :: Ke(12,12) = 0.0_wp  !! 12×12

    ! ---- ----
    TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
  END TYPE PH_Beam3DStiffArgs
```

### `CompLayerInfo` (lines 78–86)

```fortran
  TYPE, PUBLIC :: CompLayerInfo
    INTEGER(i4) :: layer_id = 0
    REAL(wp) :: thickness = 0.0_wp
    REAL(wp) :: fiber_angle = 0.0_wp  ! Fiber angle in degrees
    REAL(wp) :: z_bottom = 0.0_wp     ! Bottom z-coordinate in layer stack
    REAL(wp) :: z_top = 0.0_wp        ! Top z-coordinate in layer stack
    INTEGER(i4) :: material_id = 0    ! Mat ID for this layer
    REAL(wp), ALLOCATABLE :: material_props(:)  ! Mat properties
  END TYPE CompLayerInfo
```

### `CompMatInfo` (lines 91–98)

```fortran
  TYPE, PUBLIC :: CompMatInfo
    INTEGER(i4) :: n_layers = 0
    TYPE(CompLayerInfo), ALLOCATABLE :: layers(:)
    REAL(wp) :: total_thickness = 0.0_wp
    LOGICAL :: symmetric_layup = .false.  ! Whether layup is symmetric
    INTEGER(i4) :: integration_met = 1  ! 1=full, 2=reduced
    INTEGER(i4) :: n_integration_p = 5  ! Through-thickness integration points
  END TYPE CompMatInfo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Bu_3D` | 102 | `SUBROUTINE UF_Bu_3D(L, E, A, Iy, Iz, G, J_torsion, kappa_y, kappa_z, Ke, status)` |
| SUBROUTINE | `UF_BuildCompBeamStiff` | 213 | `SUBROUTINE UF_BuildCompBeamStiff(L, composite_info, Ke, status)` |
| SUBROUTINE | `UF_BuildCompShellStiff` | 325 | `SUBROUTINE UF_BuildCompShellStiff(composite_info, Dm, Db, Ds, status)` |
| SUBROUTINE | `UF_BuildOrthotropicQMatrix` | 455 | `SUBROUTINE UF_BuildOrthotropicQMatrix(E1, E2, nu12, G12, Q)` |
| SUBROUTINE | `UF_ComputeLayerStiffness` | 475 | `SUBROUTINE UF_ComputeLayerStiffness(layer_info, Q_matrix, status)` |
| SUBROUTINE | `UF_TransformLayerToGlobal` | 515 | `SUBROUTINE UF_TransformLayerToGlobal(fiber_angle, E_local, nu_local, G_local, &` |
| SUBROUTINE | `UF_TransformQMatrixToGlobal` | 554 | `SUBROUTINE UF_TransformQMatrixToGlobal(fiber_angle, Q_local, Q_global)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
