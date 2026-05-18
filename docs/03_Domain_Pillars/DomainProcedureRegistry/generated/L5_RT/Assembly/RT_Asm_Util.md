# `RT_Asm_Util.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Util.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Asm_Util`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Util`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm`
- **第四段角色（四段式）**: `_Util`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Util.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Asm_ElemLoop_Info` (lines 40–53)

```fortran
  TYPE, PUBLIC :: RT_Asm_ElemLoop_Info
    INTEGER(i4) :: elem_id = 0
    INTEGER(i4) :: elem_type = 0
    INTEGER(i4) :: n_nodes = 0
    INTEGER(i4) :: n_dofs_per_node = 3  ! Default: 3 DOFs per node (x, y, z)
    INTEGER(i4) :: n_elem_dofs = 0
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! (nDim, n_nodes)
    REAL(wp) :: density = 0.0_wp
    CHARACTER(LEN=32) :: elem_name = ""
    INTEGER(i4) :: topology = UF_TOPO_Hex
    INTEGER(i4) :: nDim = 3
  END TYPE RT_Asm_ElemLoop_Info
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_CSR_FromCSR` | 57 | `SUBROUTINE RT_Asm_CSR_FromCSR(csr, rt_csr, error)` |
| SUBROUTINE | `RT_Asm_CSR_ToCSR` | 106 | `SUBROUTINE RT_Asm_CSR_ToCSR(rt_csr, csr, error)` |
| SUBROUTINE | `RT_Asm_GetElemCoords` | 174 | `SUBROUTINE RT_Asm_GetElemCoords(model, part_idx, elem_idx, nDim, coords, error)` |
| SUBROUTINE | `RT_Asm_GetElemDensity` | 244 | `SUBROUTINE RT_Asm_GetElemDensity(model, part_idx, elem_idx, density, error)` |
| SUBROUTINE | `RT_Asm_GetElemDOFs` | 299 | `SUBROUTINE RT_Asm_GetElemDOFs(model, part_idx, elem_idx, n_dofs_per_node, &` |
| SUBROUTINE | `RT_Asm_GetElemInfo` | 357 | `SUBROUTINE RT_Asm_GetElemInfo(model, part_idx, elem_idx, elem_info, error)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
