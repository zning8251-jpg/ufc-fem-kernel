# `PH_ElemDomain_Ops.f90`

- **Source**: `L4_PH/Element/PH_ElemDomain_Ops.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ElemDomain_Ops`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ElemDomain_Ops`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ElemDomain`
- **第四段角色（四段式）**: `_Ops`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_ElemDomain_Ops.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Compute_Ke_Args` (lines 37–48)

```fortran
  TYPE, PUBLIC :: PH_Elem_Compute_Ke_Args
    INTEGER(i4) :: elem_idx
    INTEGER(i4) :: mat_pt_idx
    INTEGER(i4) :: ndofel
    INTEGER(i4) :: nstrs
    
    TYPE(PH_Elem_Ctx), INTENT(IN)    :: ctx
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    INTEGER(i4) :: status
  END TYPE PH_Elem_Compute_Ke_Args
```

### `PH_Elem_Compute_Fe_Args` (lines 54–72)

```fortran
  TYPE, PUBLIC :: PH_Elem_Compute_Fe_Args
    INTEGER(i4) :: elem_idx
    INTEGER(i4) :: mat_pt_idx
    INTEGER(i4) :: ndofel
    INTEGER(i4) :: nstrs
    
    TYPE(PH_Elem_Ctx), INTENT(IN)    :: ctx
    TYPE(PH_Elem_State), INTENT(INOUT) :: state
    
    ! 边界积分支持
    INTEGER(i4) :: integrate_boundary = 0_i4
    INTEGER(i4) :: face_id = 0_i4
    INTEGER(i4) :: edge_id = 0_i4
    REAL(wp), ALLOCATABLE :: traction(:)
    
    REAL(wp), ALLOCATABLE :: Fe(:,:)
    REAL(wp), ALLOCATABLE :: stress(:,:)
    INTEGER(i4) :: status
  END TYPE PH_Elem_Compute_Fe_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_ComputeStiffness` | 79 | `SUBROUTINE PH_Elem_ComputeStiffness(args)` |
| SUBROUTINE | `PH_Elem_ComputeInternalForce` | 108 | `SUBROUTINE PH_Elem_ComputeInternalForce(args)` |
| SUBROUTINE | `PH_Element_Ctan6_RotateCt_LabToRThetaZ` | 132 | `SUBROUTINE PH_Element_Ctan6_RotateCt_LabToRThetaZ(R, C_lab, C_rtz)` |
| SUBROUTINE | `PH_Element_StressVoigt6_ToPlane3_124` | 141 | `SUBROUTINE PH_Element_StressVoigt6_ToPlane3_124(sigma6, sigma3)` |
| SUBROUTINE | `PH_Element_StressVoigt6_ToCax4_1325` | 149 | `SUBROUTINE PH_Element_StressVoigt6_ToCax4_1325(sigma6, sigma4)` |
| SUBROUTINE | `PH_Element_TM_AssembleKe_Coupled` | 158 | `SUBROUTINE PH_Element_TM_AssembleKe_Coupled(elem_type_id, coords, props, Ke, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
