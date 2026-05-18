# `PH_Mat_UMAT_Brg.f90`

- **Source**: `L4_PH/Material/Contract/PH_Mat_UMAT_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_UMAT_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_UMAT_Brg`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_UMAT`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Contract/PH_Mat_UMAT_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_MAT_UMAT_MaterialClassifier` (lines 36–41)

```fortran
  TYPE, PUBLIC :: PH_MAT_UMAT_MaterialClassifier
    INTEGER(i4) :: material_id  ! Material ID: 1=VonMises, 2=NeoHookean, 3=Prony
    CHARACTER(LEN=50) :: mat_name  ! Material name
    INTEGER(i4) :: nprops_expected  ! Expected parameter count
    INTEGER(i4) :: nstatv_expected  ! Expected state variable count
  END TYPE PH_MAT_UMAT_MaterialClassifier
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_UMAT_AllocateStateVars` | 45 | `SUBROUTINE PH_UMAT_AllocateStateVars(mat_classifier, statev, nstatv, err_stat)` |
| SUBROUTINE | `PH_UMAT_Call_Enhanced` | 74 | `SUBROUTINE PH_UMAT_Call_Enhanced(stress_voigt, statev_in, ddsdde, &` |
| SUBROUTINE | `PH_UMAT_NeoHookean_Wrapper` | 163 | `SUBROUTINE PH_UMAT_NeoHookean_Wrapper(stress_voigt, statev_in, ddsdde, &` |
| SUBROUTINE | `PH_UMAT_Prony_Wrapper` | 217 | `SUBROUTINE PH_UMAT_Prony_Wrapper(stress_voigt, statev_in, ddsdde, &` |
| FUNCTION | `PH_UMAT_RetrieveMaterialClass` | 270 | `FUNCTION PH_UMAT_RetrieveMaterialClass(props, nprops) RESULT(classifier)` |
| SUBROUTINE | `PH_UMAT_ValidateProps` | 286 | `SUBROUTINE PH_UMAT_ValidateProps(mat_classifier, props, nprops, err_stat)` |
| SUBROUTINE | `PH_UMAT_VonMises_Wrapper` | 331 | `SUBROUTINE PH_UMAT_VonMises_Wrapper(stress_voigt, statev_in, ddsdde, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
