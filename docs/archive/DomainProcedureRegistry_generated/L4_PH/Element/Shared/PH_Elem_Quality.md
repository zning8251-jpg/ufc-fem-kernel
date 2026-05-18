# `PH_Elem_Quality.f90`

- **Source**: `L4_PH/Element/Shared/PH_Elem_Quality.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Quality`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Quality`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Quality`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shared/PH_Elem_Quality.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ElemQualMetrics` (lines 69–88)

```fortran
  TYPE, PUBLIC :: ElemQualMetrics
    REAL(wp) :: jacobian_min = 0.0_wp
    REAL(wp) :: jacobian_max = 0.0_wp
    REAL(wp) :: jacobian_avg = 0.0_wp
    REAL(wp) :: aspect_ratio = 1.0_wp
    REAL(wp) :: skewness = 0.0_wp
    REAL(wp) :: orthogonality = 1.0_wp
    REAL(wp) :: volume = 0.0_wp
    REAL(wp) :: quality_score = 1.0_wp
    REAL(wp) :: warpage = 0.0_wp  ! Warpage metric (for shells/quads)
    REAL(wp) :: taper = 0.0_wp  ! Taper metric (for quads)
    REAL(wp) :: twist = 0.0_wp  ! Twist metric (for quads)
    REAL(wp) :: distortion = 0.0_wp  ! Distortion metric
    REAL(wp) :: min_angle = 0.0_wp  ! Minimum angle (for triangles/tets)
    REAL(wp) :: max_angle = 0.0_wp  ! Maximum angle (for triangles/tets)
    REAL(wp) :: edge_ratio = 1.0_wp  ! Edge length ratio
    LOGICAL :: is_valid = .true.
    LOGICAL :: is_inverted = .false.
    LOGICAL :: is_degenerate = .false.
  END TYPE ElemQualMetrics
```

### `PH_Elem_Shared_Args` (lines 94–130)

```fortran
  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `REAL_TO_STRING` | 135 | `FUNCTION REAL_TO_STRING(val) RESULT(str)` |
| SUBROUTINE | `UF_ComputeHexahedronSkewness` | 146 | `SUBROUTINE UF_ComputeHexahedronSkewness(coords, skewness, status)` |
| SUBROUTINE | `UF_ComputeQuadrilateralSkewn` | 176 | `SUBROUTINE UF_ComputeQuadrilateralSkewn(coords, skewness, status)` |
| SUBROUTINE | `UF_ComputeTetrahedronSkewnes` | 248 | `SUBROUTINE UF_ComputeTetrahedronSkewnes(coords, skewness, status)` |
| SUBROUTINE | `UF_ComputeTriangleSkewness` | 283 | `SUBROUTINE UF_ComputeTriangleSkewness(coords, skewness, status)` |
| SUBROUTINE | `UF_Element_CheckQuality_3DPyramid` | 338 | `SUBROUTINE UF_Element_CheckQuality_3DPyramid(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_El_GenerateAutoFixSuggest` | 360 | `SUBROUTINE UF_El_GenerateAutoFixSuggest(ElemType, Ctx, metrics, suggestions, status)` |
| SUBROUTINE | `UF_El_GenerateQualityReport` | 494 | `SUBROUTINE UF_El_GenerateQualityReport(ElemType, Ctx, metrics, report, status)` |
| SUBROUTINE | `UF_El_GenerateVisualizationD` | 576 | `SUBROUTINE UF_El_GenerateVisualizationD(ElemType, Ctx, metrics, viz_data, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality` | 643 | `SUBROUTINE UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_2DQuad` | 763 | `SUBROUTINE UF_Elem_CheckQuality_2DQuad(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_2DTri` | 785 | `SUBROUTINE UF_Elem_CheckQuality_2DTri(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_3DHex` | 807 | `SUBROUTINE UF_Elem_CheckQuality_3DHex(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_3DTet` | 829 | `SUBROUTINE UF_Elem_CheckQuality_3DTet(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_3DWedge` | 851 | `SUBROUTINE UF_Elem_CheckQuality_3DWedge(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_Batch` | 873 | `SUBROUTINE UF_Elem_CheckQuality_Batch(elementTypes, contexts, metrics_array, &` |
| SUBROUTINE | `UF_Elem_CheckQuality_Beam` | 912 | `SUBROUTINE UF_Elem_CheckQuality_Beam(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_CheckQuality_Shell` | 936 | `SUBROUTINE UF_Elem_CheckQuality_Shell(ElemType, Ctx, metrics, status)` |
| SUBROUTINE | `UF_Elem_ComputeAspectRatio` | 959 | `SUBROUTINE UF_Elem_ComputeAspectRatio(ElemType, Ctx, aspect_ratio, status)` |
| SUBROUTINE | `UF_Elem_ComputeDistortion` | 1013 | `SUBROUTINE UF_Elem_ComputeDistortion(ElemType, Ctx, distortion, status)` |
| SUBROUTINE | `UF_Elem_ComputeJacobian` | 1046 | `SUBROUTINE UF_Elem_ComputeJacobian(ElemType, Ctx, detJ, status)` |
| SUBROUTINE | `UF_Elem_ComputeJacobianAtIP` | 1077 | `SUBROUTINE UF_Elem_ComputeJacobianAtIP(ElemType, Ctx, xi, detJ, status)` |
| FUNCTION | `UF_Elem_ComputeQualityScore` | 1173 | `FUNCTION UF_Elem_ComputeQualityScore(metrics) RESULT(score)` |
| SUBROUTINE | `UF_Elem_ComputeSkewness` | 1284 | `SUBROUTINE UF_Elem_ComputeSkewness(ElemType, Ctx, skewness, status)` |
| SUBROUTINE | `UF_Elem_ComputeTaper` | 1343 | `SUBROUTINE UF_Elem_ComputeTaper(ElemType, Ctx, taper, status)` |
| SUBROUTINE | `UF_Elem_ComputeTwist` | 1408 | `SUBROUTINE UF_Elem_ComputeTwist(ElemType, Ctx, twist, status)` |
| SUBROUTINE | `UF_Elem_ComputeVolume` | 1466 | `SUBROUTINE UF_Elem_ComputeVolume(ElemType, Ctx, volume, status)` |
| SUBROUTINE | `UF_Elem_ComputeWarpage` | 1508 | `SUBROUTINE UF_Elem_ComputeWarpage(ElemType, Ctx, warpage, status)` |
| SUBROUTINE | `UF_Elem_ValidateGeometry` | 1579 | `SUBROUTINE UF_Elem_ValidateGeometry(ElemType, Ctx, is_valid, status)` |
| SUBROUTINE | `UF_GetElementEdgeConnectivit` | 1597 | `SUBROUTINE UF_GetElementEdgeConnectivit(ElemType, edge_conn, nEdges)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
