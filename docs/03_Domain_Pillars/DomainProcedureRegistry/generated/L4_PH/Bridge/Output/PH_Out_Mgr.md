# `PH_Out_Mgr.f90`

- **Source**: `L4_PH/Bridge/Output/PH_Out_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Out_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Out_Mgr`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Out`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Bridge/Output/PH_Out_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Output_Params` (lines 60–67)

```fortran
  TYPE, PUBLIC :: PH_Output_Params
    INTEGER(i4) :: format_type = PH_OUTPUT_VTK
    INTEGER(i4) :: n_components = 3_i4        ! Number of field components
    INTEGER(i4) :: tensor_rank = 1_i4         ! 0=scalar, 1=vector, 2=tensor
    LOGICAL     :: write_binary = .FALSE.
    CHARACTER(LEN=256) :: field_name = ''
    CHARACTER(LEN=256) :: units = ''
  END TYPE PH_Output_Params
```

### `PH_Output_State` (lines 70–78)

```fortran
  TYPE, PUBLIC :: PH_Output_State
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    REAL(wp), ALLOCATABLE :: nodal_coords(:,:)    ! [3 × n_nodes]
    REAL(wp), ALLOCATABLE :: elem_connect(:,:)    ! [n_nodes_per_elem × n_elems]
    REAL(wp), ALLOCATABLE :: field_data(:,:)      ! [n_components × n_points]
    REAL(wp) :: time_value = 0.0_wp
    INTEGER(i4) :: step_number = 0_i4
  END TYPE PH_Output_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Output_CoordTransform` | 95 | `SUBROUTINE PH_Output_CoordTransform(coords_global, rotation_matrix, &` |
| SUBROUTINE | `PH_Output_TensorTransform` | 138 | `SUBROUTINE PH_Output_TensorTransform(tensor_voigt, tensor_full, direction, status)` |
| SUBROUTINE | `PH_Output_FieldInterpolate` | 178 | `SUBROUTINE PH_Output_FieldInterpolate(nodal_values, shape_funcs, &` |
| SUBROUTINE | `PH_Output_ExtractScalar` | 224 | `SUBROUTINE PH_Output_ExtractScalar(field_data, component_idx, scalar_value, status)` |
| SUBROUTINE | `PH_Output_ExtractVector` | 264 | `SUBROUTINE PH_Output_ExtractVector(field_data, vector_values, status)` |
| SUBROUTINE | `PH_Output_ExtractTensor` | 302 | `SUBROUTINE PH_Output_ExtractTensor(field_data, tensor_values, notation, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
