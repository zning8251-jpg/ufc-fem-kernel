# `RT_Asm_Global.f90`

- **Source**: `L5_RT/Assembly/RT_Asm_Global.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Asm_Global`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Asm_Global`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Asm_Global`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Assembly/RT_Asm_Global.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CSR_Matrix` (lines 105–112)

```fortran
  TYPE :: CSR_Matrix
    INTEGER(i4) :: n_rows = 0
    INTEGER(i4) :: n_cols = 0
    INTEGER(i4) :: nnz = 0
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)   ! Length: n_rows + 1
    INTEGER(i4), ALLOCATABLE :: col_ind(:)   ! Length: nnz
    REAL(wp), ALLOCATABLE :: values(:)       ! Length: nnz
  END TYPE CSR_Matrix
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Asm_Global_Init` | 124 | `SUBROUTINE RT_Asm_Global_Init(n_dof_global, n_elements, K_global, R_global, status)` |
| SUBROUTINE | `RT_Asm_Globalble_NL` | 173 | `SUBROUTINE RT_Asm_Globalble_NL(elem_type_id, elem_node_ids, &` |
| SUBROUTINE | `CSR_AddEntry` | 240 | `SUBROUTINE CSR_AddEntry(matrix, row, col, value, status)` |
| SUBROUTINE | `RT_Asm_Global_ApplyBC_Sparse` | 270 | `SUBROUTINE RT_Asm_Global_ApplyBC_Sparse(K_global, R_global, bc_dofs, bc_values, &` |
| SUBROUTINE | `RT_Asm_BuildGlobSys_Sparse` | 332 | `SUBROUTINE RT_Asm_BuildGlobSys_Sparse(K_csr, F_global, &` |
| SUBROUTINE | `RT_Asm_AssemElems_Sparse` | 414 | `SUBROUTINE RT_Asm_AssemElems_Sparse(K_csr, elem_K, elem_dofs, n_dof, nnz_estimate, status)` |
| SUBROUTINE | `RT_Asm_ApplyBC_Sparse` | 445 | `SUBROUTINE RT_Asm_ApplyBC_Sparse(K_csr, F_global, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
