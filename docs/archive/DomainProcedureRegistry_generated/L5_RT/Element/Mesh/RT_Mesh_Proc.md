# `RT_Mesh_Proc.f90`

- **Source**: `L5_RT/Element/Mesh/RT_Mesh_Proc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Mesh_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mesh_Proc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mesh`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/Mesh/RT_Mesh_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mesh_Init_In` (lines 23–28)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Init_In
    TYPE(MD_Mesh_Registry), POINTER :: md_registry => NULL()
    INTEGER(i4) :: n_partitions = 1_i4
    LOGICAL :: use_parallel = .FALSE.
    TYPE(RT_Mesh_Base_Algo), OPTIONAL :: algo_default
  END TYPE RT_Mesh_Init_In
```

### `RT_Mesh_Init_Out` (lines 30–36)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Init_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: nnodes = 0_i4
    INTEGER(i4) :: nelems = 0_i4
    INTEGER(i4) :: total_dof = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Init_Out
```

### `RT_Mesh_Clean_In` (lines 39–42)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Clean_In
    LOGICAL :: full_cleanup = .TRUE.
    LOGICAL :: keep_numbering = .FALSE.
  END TYPE RT_Mesh_Clean_In
```

### `RT_Mesh_Clean_Out` (lines 44–47)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Clean_Out
    LOGICAL :: success = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Clean_Out
```

### `RT_Mesh_Numbering_In` (lines 50–53)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Numbering_In
    TYPE(RT_Mesh_NumberingAlgo) :: algo
    LOGICAL :: renumber_existing = .FALSE.
  END TYPE RT_Mesh_Numbering_In
```

### `RT_Mesh_Numbering_Out` (lines 55–61)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Numbering_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: total_active_dof = 0_i4
    INTEGER(i4) :: max_bandwidth = 0_i4
    REAL(wp) :: fill_ratio = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Numbering_Out
```

### `RT_Mesh_UpdateCoords_In` (lines 64–68)

```fortran
  TYPE, PUBLIC :: RT_Mesh_UpdateCoords_In
    REAL(wp), POINTER :: displ(:,:) => NULL()      ! [nnodes, 3]
    REAL(wp), POINTER :: velocity(:,:) => NULL()   ! [nnodes, 3]
    LOGICAL :: update_velocity = .FALSE.
  END TYPE RT_Mesh_UpdateCoords_In
```

### `RT_Mesh_UpdateCoords_Out` (lines 70–74)

```fortran
  TYPE, PUBLIC :: RT_Mesh_UpdateCoords_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: updated_nodes = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_UpdateCoords_Out
```

### `RT_Mesh_GetState_In` (lines 77–81)

```fortran
  TYPE, PUBLIC :: RT_Mesh_GetState_In
    INTEGER(i4) :: node_id = 0_i4         ! Query specific node
    INTEGER(i4) :: elem_id = 0_i4         ! Query specific element
    CHARACTER(LEN=64) :: field_name = ' ' ! Field to query
  END TYPE RT_Mesh_GetState_In
```

### `RT_Mesh_GetState_Out` (lines 83–88)

```fortran
  TYPE, PUBLIC :: RT_Mesh_GetState_Out
    REAL(wp), ALLOCATABLE :: values(:)    ! Queried field values
    INTEGER(i4) :: int_values(:)          ! Integer field values
    LOGICAL :: is_valid = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_GetState_Out
```

### `RT_Mesh_Assembly_In` (lines 91–96)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Assembly_In
    TYPE(RT_Mesh_AssemblyCtx) :: ctx
    REAL(wp), POINTER :: elem_matrix(:,:) => NULL()  ! Element matrix to assemble
    REAL(wp), POINTER :: elem_vector(:) => NULL()    ! Element vector to assemble
    INTEGER(i4) :: elem_id = 0_i4                    ! Element ID
  END TYPE RT_Mesh_Assembly_In
```

### `RT_Mesh_Assembly_Out` (lines 98–102)

```fortran
  TYPE, PUBLIC :: RT_Mesh_Assembly_Out
    LOGICAL :: success = .FALSE.
    INTEGER(i4) :: assembled_entries = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Mesh_Assembly_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Mesh_Init` | 148 | `SUBROUTINE RT_Mesh_Init(input, output)` |
| SUBROUTINE | `RT_Mesh_Clean` | 159 | `SUBROUTINE RT_Mesh_Clean(input, output)` |
| SUBROUTINE | `RT_Mesh_Numbering` | 170 | `SUBROUTINE RT_Mesh_Numbering(input, output)` |
| SUBROUTINE | `RT_Mesh_UpdateCoords` | 181 | `SUBROUTINE RT_Mesh_UpdateCoords(input, output)` |
| SUBROUTINE | `RT_Mesh_GetState` | 192 | `SUBROUTINE RT_Mesh_GetState(input, output)` |
| SUBROUTINE | `RT_Mesh_Assembly` | 203 | `SUBROUTINE RT_Mesh_Assembly(input, output)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 108–110 | `INTERFACE RT_Mesh_Init` |
| 112–114 | `INTERFACE RT_Mesh_Clean` |
| 116–118 | `INTERFACE RT_Mesh_Numbering` |
| 120–122 | `INTERFACE RT_Mesh_UpdateCoords` |
| 124–126 | `INTERFACE RT_Mesh_GetState` |
| 128–130 | `INTERFACE RT_Mesh_Assembly` |
