# `PH_Mat_hTensor.f90`

- **Source**: `L4_PH/Material/Shared/PH_Mat_hTensor.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_hTensor`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_hTensor`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_hTensor`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Shared`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Shared/PH_Mat_hTensor.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Math_Tensor_Args` (lines 58–85)

```fortran
  TYPE :: PH_Math_Tensor_Args
  ! Purpose: INTF-style argument bundle; see module header.
  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE PH_Math_Tensor_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `PH_Math_Tensor_DotProduct` | 94 | `FUNCTION PH_Math_Tensor_DotProduct(A, B) RESULT(C)` |
| FUNCTION | `PH_Math_Tensor_ScalarProduct` | 110 | `FUNCTION PH_Math_Tensor_ScalarProduct(A, B) RESULT(scalar)` |
| FUNCTION | `PH_Math_Tensor_DyadicProduct` | 125 | `FUNCTION PH_Math_Tensor_DyadicProduct(a, b) RESULT(tens)` |
| SUBROUTINE | `PH_Math_Tensor_ComponentTransform` | 142 | `SUBROUTINE PH_Math_Tensor_ComponentTransform(tensor_covariant, metric_tensor, &` |
| SUBROUTINE | `PH_Math_Tensor_MetricTensor` | 174 | `SUBROUTINE PH_Math_Tensor_MetricTensor(base_vectors, metric_tensor, status)` |
| SUBROUTINE | `PH_Math_Tensor_Rotation` | 193 | `SUBROUTINE PH_Math_Tensor_Rotation(tensor, rotation, rotated_tensor, status)` |
| SUBROUTINE | `PH_Math_Tensor_Invariants` | 210 | `SUBROUTINE PH_Math_Tensor_Invariants(tensor, I1, I2, I3, status)` |
| SUBROUTINE | `PH_Math_Tensor_PolarDecomposition` | 240 | `SUBROUTINE PH_Math_Tensor_PolarDecomposition(F, R, U, V, status)` |
| SUBROUTINE | `PH_Math_Tensor_TensorToVoigt` | 299 | `SUBROUTINE PH_Math_Tensor_TensorToVoigt(tensor, voigt, status)` |
| SUBROUTINE | `PH_Math_Tensor_VoigtToTensor` | 316 | `SUBROUTINE PH_Math_Tensor_VoigtToTensor(voigt, tensor, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
