# `MD_Int_Mapper.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Mapper.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Mapper`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Mapper`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Mapper`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Mapper.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `SurfaceSetType` (lines 34–41)

```fortran
  TYPE, PUBLIC :: SurfaceSetType
    CHARACTER(len=64) :: surface_name
    INTEGER(i4) :: surface_id = 0
    INTEGER(i4) :: node_count = 0
    INTEGER(i4) :: element_count = 0
    INTEGER(i4), ALLOCATABLE :: node_indices(:)
    INTEGER(i4), ALLOCATABLE :: element_indices(:)
  END TYPE SurfaceSetType
```

### `InteractionMappingType` (lines 44–52)

```fortran
  TYPE, PUBLIC :: InteractionMappingType
    INTEGER(i4) :: pair_id = 0
    CHARACTER(len=64) :: pair_name
    INTEGER(i4) :: slave_node_count = 0
    INTEGER(i4) :: master_node_count = 0
    INTEGER(i4), ALLOCATABLE :: slave_nodes(:)
    INTEGER(i4), ALLOCATABLE :: master_nodes(:)
    LOGICAL :: is_valid = .FALSE.
  END TYPE InteractionMappingType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Allocate_InteractionArrays` | 127 | `SUBROUTINE MD_Allocate_InteractionArrays(desc, num_nodes, num_elements, status)` |
| SUBROUTINE | `MD_Map_InteractionToMesh` | 188 | `SUBROUTINE MD_Map_InteractionToMesh(desc, contact_type, surfaces, num_surfaces, status)` |
| SUBROUTINE | `MD_Build_InteractionMapping` | 250 | `SUBROUTINE MD_Build_InteractionMapping(desc, contact_pairs, num_pairs, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
