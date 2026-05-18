# `MD_Elem_Populate.f90`

- **Source**: `L3_MD/Element/Elem/MD_Elem_Populate.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Elem_Populate`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Elem_Populate`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Elem_Populate`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Elem`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Elem/MD_Elem_Populate.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Elem_Populate_Arg` (lines 26–39)

```fortran
  TYPE, PUBLIC :: MD_Elem_Populate_Arg
    !--- Input data (IN) ---
    INTEGER(i4) :: elem_type_id    = 0_i4     ! Element type ID
    INTEGER(i4) :: sect_id         = 0_i4     ! Section ID
    INTEGER(i4) :: mat_id          = 0_i4     ! Material ID
    !--- Instance data (INOUT) ---
    INTEGER(i4), ALLOCATABLE :: elem_ids(:)   ! Element IDs [n_elems]
    INTEGER(i4), ALLOCATABLE :: conn_table(:,:) ! Connectivity [n_nodes, n_elems]
    INTEGER(i4), ALLOCATABLE :: node_ids(:)   ! Node IDs [n_nodes_total]
    !--- Metadata (OUT) ---
    INTEGER(i4) :: n_elements       = 0_i4    ! Number of elements
    INTEGER(i4) :: n_nodes_per_elem = 0_i4    ! Nodes per element
    LOGICAL     :: is_valid         = .FALSE.  ! Validation flag
  END TYPE MD_Elem_Populate_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Elem_Populate_Domain` | 56 | `SUBROUTINE MD_Elem_Populate_Domain(domain, args, status)` |
| SUBROUTINE | `MD_Elem_Populate_ParseConn` | 96 | `SUBROUTINE MD_Elem_Populate_ParseConn(args, conn_data, status)` |
| FUNCTION | `MD_Elem_Populate_Validate` | 138 | `FUNCTION MD_Elem_Populate_Validate(args, expected_n_nodes, status) RESULT(is_valid)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
