# `IF_Mat_Dispatch_Def.f90`

- **Source**: `L1_IF/Base/IF_Mat_Dispatch_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mat_Dispatch_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mat_Dispatch_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mat_Dispatch`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Mat_Dispatch_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mat_Dispatch_Ctx` (lines 29–35)

```fortran
  TYPE, PUBLIC :: RT_Mat_Dispatch_Ctx
    INTEGER(i4) :: mat_type    = 0_i4   ! 11-family marker PH_MAT_* (1..11) when from L4 slot; registry mat_id 101.. elsewhere
    INTEGER(i4) :: mat_id      = 0_i4   ! L3 material ID (for diagnostics)
    INTEGER(i4) :: mat_pt_idx  = 0_i4   ! L4 slot_pool index (assigned by Populate)
    LOGICAL     :: is_user_sub = .FALSE. ! True if UMAT/VUMAT
    INTEGER(i4) :: route_status = 0_i4  ! IF_MAT_ROUTE_* after last dispatch
  END TYPE RT_Mat_Dispatch_Ctx
```

### `RT_Mat_Route_Entry` (lines 42–48)

```fortran
  TYPE, PUBLIC :: RT_Mat_Route_Entry
    INTEGER(i4) :: mat_type   = 0_i4
    INTEGER(i4) :: mat_id     = 0_i4
    INTEGER(i4) :: mat_pt_idx = 0_i4
    LOGICAL     :: is_user    = .FALSE.
    LOGICAL     :: active     = .FALSE.
  END TYPE RT_Mat_Route_Entry
```

### `RT_Mat_Dispatch_Table` (lines 50–54)

```fortran
  TYPE, PUBLIC :: RT_Mat_Dispatch_Table
    TYPE(RT_Mat_Route_Entry) :: entries(IF_MAT_TABLE_MAX)
    INTEGER(i4)              :: n_entries = 0_i4
    LOGICAL                  :: initialized = .FALSE.
  END TYPE RT_Mat_Dispatch_Table
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
