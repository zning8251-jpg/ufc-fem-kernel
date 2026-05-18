# `PH_Elem_GaussInt.f90`

- **Source**: `L4_PH/Element/PH_Elem_GaussInt.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_GaussInt`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_GaussInt`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_GaussInt`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_GaussInt.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_GaussInt_Desc` (lines 23–37)

```fortran
  TYPE, PUBLIC :: PH_Elem_GaussInt_Desc
    INTEGER(i4) :: dim = 0              ! Dimension (1, 2, or 3)
    INTEGER(i4) :: order = 0            ! Integration order
    INTEGER(i4) :: n_points = 0         ! Number of Gauss points
    
    REAL(wp), ALLOCATABLE :: xi(:,:)    ! Gauss point coordinates [n_points, dim]
    REAL(wp), ALLOCATABLE :: w(:)       ! Gauss point weights [n_points]
    
  CONTAINS
    PROCEDURE, PASS(this) :: Init1D => InitGauss1D
    PROCEDURE, PASS(this) :: Init2D => InitGauss2D_Quad
    PROCEDURE, PASS(this) :: Init3D => InitGauss3D_Hex
    PROCEDURE, PASS(this) :: GetFaceRule => GetHexFaceGauss
    PROCEDURE, PASS(this) :: GetEdgeRule => GetQuadEdgeGauss
  END TYPE PH_Elem_GaussInt_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `InitGauss1D` | 47 | `SUBROUTINE InitGauss1D(this, order)` |
| SUBROUTINE | `InitGauss2D_Quad` | 86 | `SUBROUTINE InitGauss2D_Quad(this, order)` |
| SUBROUTINE | `InitGauss3D_Hex` | 118 | `SUBROUTINE InitGauss3D_Hex(this, order)` |
| SUBROUTINE | `GetHexFaceGauss` | 152 | `SUBROUTINE GetHexFaceGauss(this, face_id, order, face_gauss)` |
| SUBROUTINE | `GetQuadEdgeGauss` | 206 | `SUBROUTINE GetQuadEdgeGauss(this, edge_id, order, edge_gauss)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
