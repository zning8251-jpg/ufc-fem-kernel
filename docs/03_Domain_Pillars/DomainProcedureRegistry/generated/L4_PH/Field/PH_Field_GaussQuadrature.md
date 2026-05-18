# `PH_Field_GaussQuadrature.f90`

- **Source**: `L4_PH/Field/PH_Field_GaussQuadrature.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Field_GaussQuadrature`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_GaussQuadrature`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field_GaussQuadrature`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_GaussQuadrature.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Field_GaussPt_Arg` (lines 48–57)

```fortran
  TYPE, PUBLIC :: PH_Field_GaussPt_Arg
    INTEGER(i4) :: rule_type = 0_i4                 ! [IN] 1=1D, 2=2D_Quad, 3=2D_Tri, 4=3D_Hex, 5=3D_Tet
    INTEGER(i4) :: order = 2_i4                     ! [IN]
    INTEGER(i4) :: n_ip = 0_i4                      ! [OUT]
    REAL(wp), ALLOCATABLE :: xi(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: eta(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: zeta(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)              ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Field_GaussPt_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Field_GetGaussPoints` | 69 | `SUBROUTINE PH_Field_GetGaussPoints(rule_type, order, out)` |
| SUBROUTINE | `PH_Field_EnsureGaussAlloc` | 127 | `SUBROUTINE PH_Field_EnsureGaussAlloc(out, n_ip)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
