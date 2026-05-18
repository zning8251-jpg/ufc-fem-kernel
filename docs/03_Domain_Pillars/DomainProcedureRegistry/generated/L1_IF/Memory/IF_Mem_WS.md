# `IF_Mem_WS.f90`

- **Source**: `L1_IF/Memory/IF_Mem_WS.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Mem_WS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_WS`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_WS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_WS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Workspace` (lines 48–58)

```fortran
    TYPE, PUBLIC :: Workspace
        INTEGER(i4) :: id = 0_i4                    ! Workspace ID
        CHARACTER(len=64) :: name = ""              ! Workspace name
        INTEGER(i8) :: size = 0_i8                  ! Workspace size in bytes
        REAL(wp), POINTER :: data(:) => NULL()      ! Workspace data
        LOGICAL :: init = .FALSE.                   ! Initialization flag
        INTEGER(i8) :: timestamp = 0_i8             ! Creation timestamp
        INTEGER(i4) :: ref_count = 0_i4             ! Reference count
        INTEGER(i4) :: reuse_count = 0_i4           ! Reuse count (task350-399)
        LOGICAL :: is_reusable = .TRUE.             ! Can be reused
    END TYPE Workspace
```

### `WorkspaceState` (lines 63–69)

```fortran
    TYPE, PUBLIC :: WorkspaceState
        INTEGER(i4) :: id = 0_i4
        INTEGER(i8) :: size = 0_i8
        INTEGER(i8) :: timestamp = 0_i8
        LOGICAL :: is_active = .FALSE.
        LOGICAL :: is_persistent = .FALSE.
    END TYPE WorkspaceState
```

### `WorkspaceManager` (lines 74–80)

```fortran
    TYPE, PUBLIC :: WorkspaceManager
        TYPE(Workspace), ALLOCATABLE :: workspaces(:)
        INTEGER(i4) :: num_workspaces = 0_i4
        INTEGER(i4) :: max_workspaces = 100_i4
        INTEGER(i4) :: next_id = 1_i4
        LOGICAL :: init = .FALSE.
    END TYPE WorkspaceManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `StructWS_Proc` | 100 | `SUBROUTINE StructWS_Proc(nDOF, Ke, Re, Me, Ce, B)` |
| SUBROUTINE | `MultiFieldWS_Proc` | 107 | `SUBROUTINE MultiFieldWS_Proc(nDOF, Ke, Re, Me, Ce)` |
| SUBROUTINE | `StructBmWS_Proc` | 113 | `SUBROUTINE StructBmWS_Proc(nDOF, mB)` |
| SUBROUTINE | `StructBmWS_Proc_2` | 118 | `SUBROUTINE StructBmWS_Proc_2(nDOF, B, mB)` |
| SUBROUTINE | `PoroCapacityWS_Proc` | 124 | `SUBROUTINE PoroCapacityWS_Proc(nDOF, Spp)` |
| SUBROUTINE | `ThermalCapacityWS_Proc` | 129 | `SUBROUTINE ThermalCapacityWS_Proc(nDOF, Ctt)` |
| SUBROUTINE | `IF_WS_Mgr_Init` | 152 | `SUBROUTINE IF_WS_Mgr_Init(max_workspaces, status)` |
| SUBROUTINE | `IF_WS_Create` | 180 | `SUBROUTINE IF_WS_Create(name, size, ws_id, status)` |
| SUBROUTINE | `IF_WS_Destroy` | 250 | `SUBROUTINE IF_WS_Destroy(ws_id, status)` |
| SUBROUTINE | `IF_WS_Get` | 291 | `SUBROUTINE IF_WS_Get(ws_id, ws, status)` |
| SUBROUTINE | `IF_WS_Resize` | 315 | `SUBROUTINE IF_WS_Resize(ws_id, new_size, status)` |
| SUBROUTINE | `IF_WS_Clear` | 369 | `SUBROUTINE IF_WS_Clear(ws_id, status)` |
| SUBROUTINE | `IF_WS_Save` | 395 | `SUBROUTINE IF_WS_Save(ws_id, filename, status)` |
| SUBROUTINE | `IF_WS_Load` | 433 | `SUBROUTINE IF_WS_Load(filename, ws_id, status)` |
| SUBROUTINE | `IF_WS_GetState` | 470 | `SUBROUTINE IF_WS_GetState(ws_id, state, status)` |
| SUBROUTINE | `IF_WS_SetState` | 499 | `SUBROUTINE IF_WS_SetState(ws_id, state, status)` |
| FUNCTION | `IF_WS_FindById` | 524 | `FUNCTION IF_WS_FindById(ws_id) RESULT(idx)` |
| SUBROUTINE | `IF_WS_Reuse` | 550 | `SUBROUTINE IF_WS_Reuse(name, min_size, ws_id, reused, status)` |
| SUBROUTINE | `IF_WS_EstimateSize` | 590 | `SUBROUTINE IF_WS_EstimateSize(n_nodes, n_elements, n_dof_per_node, estimated_size)` |
| SUBROUTINE | `IF_WS_GetStatistics` | 610 | `SUBROUTINE IF_WS_GetStatistics(total_workspaces, total_size, reused_count, status)` |
| SUBROUTINE | `IF_WS_Compact` | 637 | `SUBROUTINE IF_WS_Compact(freed_count, status)` |
| SUBROUTINE | `IF_WS_GetReuseCount` | 665 | `SUBROUTINE IF_WS_GetReuseCount(ws_id, reuse_count, status)` |
| SUBROUTINE | `RT_Elem_WS_RegStruct` | 691 | `SUBROUTINE RT_Elem_WS_RegStruct(proc)` |
| SUBROUTINE | `RT_Elem_WS_RegMultiField` | 698 | `SUBROUTINE RT_Elem_WS_RegMultiField(proc)` |
| SUBROUTINE | `RT_Elem_WS_RegStructBm` | 705 | `SUBROUTINE RT_Elem_WS_RegStructBm(proc)` |
| SUBROUTINE | `RT_Elem_WS_RegStructBm_2` | 712 | `SUBROUTINE RT_Elem_WS_RegStructBm_2(proc)` |
| SUBROUTINE | `RT_Elem_WS_RegPoroCapacity` | 719 | `SUBROUTINE RT_Elem_WS_RegPoroCapacity(proc)` |
| SUBROUTINE | `RT_Elem_WS_RegThermCapacity` | 726 | `SUBROUTINE RT_Elem_WS_RegThermCapacity(proc)` |
| SUBROUTINE | `RT_Elem_WS_GetStruct` | 742 | `SUBROUTINE RT_Elem_WS_GetStruct(nDOF, Ke, Re, Me, Ce, B)` |
| SUBROUTINE | `RT_Elem_WS_GetMultiField` | 761 | `SUBROUTINE RT_Elem_WS_GetMultiField(nDOF, Ke, Re, Me, Ce)` |
| SUBROUTINE | `RT_Elem_WS_GetStructBm` | 776 | `SUBROUTINE RT_Elem_WS_GetStructBm(nDOF, mB)` |
| SUBROUTINE | `RT_Elem_WS_GetStructBm_2` | 791 | `SUBROUTINE RT_Elem_WS_GetStructBm_2(nDOF, B, mB)` |
| SUBROUTINE | `RT_Elem_WS_GetPoroCapacity` | 806 | `SUBROUTINE RT_Elem_WS_GetPoroCapacity(nDOF, Spp)` |
| SUBROUTINE | `RT_Elem_WS_GetThermCapacity` | 820 | `SUBROUTINE RT_Elem_WS_GetThermCapacity(nDOF, Ctt)` |
| SUBROUTINE | `GetStructWS` | 838 | `SUBROUTINE GetStructWS(nDOF, Ke, Re, Me, Ce, B)` |
| SUBROUTINE | `IF_WS_Alloc_SolverVec` | 857 | `SUBROUTINE IF_WS_Alloc_SolverVec(n, name, ptr, id, status)` |
| SUBROUTINE | `IF_WS_Free_SolverVec` | 870 | `SUBROUTINE IF_WS_Free_SolverVec(id, status)` |
| SUBROUTINE | `IF_WS_Get_NL_DeltaWorkspace` | 881 | `SUBROUTINE IF_WS_Get_NL_DeltaWorkspace(ndof, delta_ws)` |
| SUBROUTINE | `IF_WS_Get_Linear_Workspace` | 896 | `SUBROUTINE IF_WS_Get_Linear_Workspace(n, work, ipiv)` |
| SUBROUTINE | `IF_WS_Finalize` | 915 | `SUBROUTINE IF_WS_Finalize()` |
| SUBROUTINE | `UF_WS_Get_NL_DeltaWorkspace` | 921 | `SUBROUTINE UF_WS_Get_NL_DeltaWorkspace(ndof, delta_ws)` |
| SUBROUTINE | `UF_WS_Get_Lin_Workspace` | 927 | `SUBROUTINE UF_WS_Get_Lin_Workspace(n, work, ipiv)` |
| SUBROUTINE | `UF_WS_Get_Linear_Workspace` | 934 | `SUBROUTINE UF_WS_Get_Linear_Workspace(n, work, ipiv)` |
| SUBROUTINE | `UF_WS_Finalize` | 941 | `SUBROUTINE UF_WS_Finalize()` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
