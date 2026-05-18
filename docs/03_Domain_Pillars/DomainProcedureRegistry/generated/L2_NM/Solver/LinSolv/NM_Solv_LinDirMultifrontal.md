# `NM_Solv_LinDirMultifrontal.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinDirMultifrontal.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_LinDirMultifrontal`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinDirMultifrontal`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinDirMultifrontal`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinDirMultifrontal.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Elimination_Tree_Node_ID` (lines 20–23)

```fortran
  TYPE, PUBLIC :: Elimination_Tree_Node_ID
    INTEGER(i4) :: node_id                   !< nodeID
    INTEGER(i4) :: parent                    !<  nodeID
  END TYPE Elimination_Tree_Node_ID
```

### `Elimination_Tree_Node_Children` (lines 25–28)

```fortran
  TYPE, PUBLIC :: Elimination_Tree_Node_Children
    INTEGER, ALLOCATABLE :: children(:)  !<  node 
    INTEGER(i4) :: n_children                !<  node 
  END TYPE Elimination_Tree_Node_Children
```

### `Elimination_Tree_Node_Variables` (lines 30–33)

```fortran
  TYPE, PUBLIC :: Elimination_Tree_Node_Variables
    INTEGER, ALLOCATABLE :: variables(:) !<  node 
    INTEGER(i4) :: n_variables               !<  
  END TYPE Elimination_Tree_Node_Variables
```

### `Elimination_Tree_Node_Frontal` (lines 35–38)

```fortran
  TYPE, PUBLIC :: Elimination_Tree_Node_Frontal
    INTEGER(i4) :: frontal_size              !<  matrix 
    INTEGER, ALLOCATABLE :: frontal_vars(:)  !<  
  END TYPE Elimination_Tree_Node_Frontal
```

### `Elimination_Tree_Node` (lines 40–45)

```fortran
  TYPE, PUBLIC :: Elimination_Tree_Node
    TYPE(Elimination_Tree_Node_ID) :: id
    TYPE(Elimination_Tree_Node_Children) :: child
    TYPE(Elimination_Tree_Node_Variables) :: var
    TYPE(Elimination_Tree_Node_Frontal) :: frontal
  END TYPE Elimination_Tree_Node
```

### `Elimination_Tree` (lines 48–52)

```fortran
  TYPE, PUBLIC :: Elimination_Tree
    INTEGER(i4) :: n_nodes                   !< node
    TYPE(Elimination_Tree_Node), ALLOCATABLE :: nodes(:)  !< node 
    INTEGER(i4) :: root                      !<  nodeID
  END TYPE
```

### `Supernode_ID` (lines 55–57)

```fortran
  TYPE, PUBLIC :: Supernode_ID
    INTEGER(i4) :: supernode_id              !<  nodeID
  END TYPE Supernode_ID
```

### `Supernode_Dims` (lines 59–62)

```fortran
  TYPE, PUBLIC :: Supernode_Dims
    INTEGER(i4) :: n_cols                    !< Number of columns
    INTEGER(i4) :: n_rows_below              !<  Number of rows
  END TYPE Supernode_Dims
```

### `Supernode_Indices` (lines 64–67)

```fortran
  TYPE, PUBLIC :: Supernode_Indices
    INTEGER, ALLOCATABLE :: row_indices(:)  !<  
    INTEGER, ALLOCATABLE :: col_indices(:)  !<  
  END TYPE Supernode_Indices
```

### `Supernode_Values` (lines 69–71)

```fortran
  TYPE, PUBLIC :: Supernode_Values
    REAL(DP), ALLOCATABLE :: values(:,:)    !<  
  END TYPE Supernode_Values
```

### `Supernode` (lines 73–78)

```fortran
  TYPE, PUBLIC :: Supernode
    TYPE(Supernode_ID) :: id
    TYPE(Supernode_Dims) :: dims
    TYPE(Supernode_Indices) :: indices
    TYPE(Supernode_Values) :: vals
  END TYPE Supernode
```

### `Multifrontal_Factorization_Supernodes` (lines 81–84)

```fortran
  TYPE, PUBLIC :: Multifrontal_Factorization_Supernodes
    INTEGER(i4) :: n_supernodes              !<  node 
    TYPE(Supernode), ALLOCATABLE :: supernodes(:)  !<  node 
  END TYPE Multifrontal_Factorization_Supernodes
```

### `Multifrontal_Factorization_Tree` (lines 86–88)

```fortran
  TYPE, PUBLIC :: Multifrontal_Factorization_Tree
    TYPE(Elimination_Tree) :: elim_tree  !<  
  END TYPE Multifrontal_Factorization_Tree
```

### `Multifrontal_Factorization_Perm` (lines 90–92)

```fortran
  TYPE, PUBLIC :: Multifrontal_Factorization_Perm
    INTEGER, ALLOCATABLE :: perm(:)      !<  
  END TYPE Multifrontal_Factorization_Perm
```

### `Multifrontal_Factorization_InvPerm` (lines 94–96)

```fortran
  TYPE, PUBLIC :: Multifrontal_Factorization_InvPerm
    INTEGER, ALLOCATABLE :: inv_perm(:)  !<  
  END TYPE Multifrontal_Factorization_InvPerm
```

### `Multifrontal_Factorization_Status` (lines 98–100)

```fortran
  TYPE, PUBLIC :: Multifrontal_Factorization_Status
    LOGICAL :: is_factored               !< Factorization complete flag
  END TYPE Multifrontal_Factorization_Status
```

### `Multifrontal_Factorization` (lines 102–108)

```fortran
  TYPE, PUBLIC :: Multifrontal_Factorization
    TYPE(Multifrontal_Factorization_Supernodes) :: super
    TYPE(Multifrontal_Factorization_Tree) :: tree
    TYPE(Multifrontal_Factorization_Perm) :: perm
    TYPE(Multifrontal_Factorization_InvPerm) :: invperm
    TYPE(Multifrontal_Factorization_Status) :: status
  END TYPE Multifrontal_Factorization
```

### `Multifrontal_Params` (lines 111–117)

```fortran
  TYPE, PUBLIC :: Multifrontal_Params
    INTEGER(i4) :: ordering_method           !<  method: 1=AMD, 2=METIS, 3=NestedDissection
    INTEGER(i4) :: supernode_size            !<  node 
    REAL(DP) :: pivot_threshold          !< Pivot threshold
    LOGICAL :: use_parallel_frontal      !<  
    INTEGER(i4) :: max_frontal_size          !<  ( )
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Multifrontal_Init_Params` | 138 | `SUBROUTINE NM_Multifrontal_Init_Params(params)` |
| SUBROUTINE | `NM_AMD_Ordering` | 157 | `SUBROUTINE NM_AMD_Ordering(A, perm, status)` |
| SUBROUTINE | `NM_Nested_Dissection_Ordering` | 230 | `SUBROUTINE NM_Nested_Dissection_Ordering(A, perm, status)` |
| SUBROUTINE | `Recursive_Nested_Dissection` | 265 | `RECURSIVE SUBROUTINE Recursive_Nested_Dissection(A, start_node, end_node, &` |
| SUBROUTINE | `NM_ElimTree_Build` | 311 | `SUBROUTINE NM_ElimTree_Build(A, tree, status)` |
| SUBROUTINE | `NM_ElimTree_Destroy` | 397 | `SUBROUTINE NM_ElimTree_Destroy(tree)` |
| SUBROUTINE | `NM_Multifrontal_Symbolic_Factorize` | 425 | `SUBROUTINE NM_Multifrontal_Symbolic_Factorize(A, params, factor, status)` |
| SUBROUTINE | `NM_Multifrontal_Numeric_Factorize` | 489 | `SUBROUTINE NM_Multifrontal_Numeric_Factorize(A, params, factor, status)` |
| SUBROUTINE | `NM_Multifrontal_Solv` | 550 | `SUBROUTINE NM_Multifrontal_Solv(factor, b, x, status)` |
| SUBROUTINE | `NM_Multifrontal_Factorize_Destroy` | 608 | `SUBROUTINE NM_Multifrontal_Factorize_Destroy(factor)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
