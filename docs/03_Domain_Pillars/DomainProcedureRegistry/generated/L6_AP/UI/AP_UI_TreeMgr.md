# `AP_UI_TreeMgr.f90`

- **Source**: `L6_AP/UI/AP_UI_TreeMgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_UI_TreeMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_TreeMgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI_TreeMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_TreeMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_UI_TreeMgr_Type` (lines 42–57)

```fortran
  type, public :: AP_UI_TreeMgr_Type
    type(ModelTree), pointer :: model_tree => null()  ! Model tree pointer
    LOGICAL :: init = .false.                          ! Initialization flag
  contains
    procedure, public :: Init => AP_UI_TreeMgr_Init
    procedure, public :: CreateNode => AP_UI_TreeMgr_CreateNode
    procedure, public :: DeleteNode => AP_UI_TreeMgr_DeleteNode
    procedure, public :: RenameNode => AP_UI_TreeMgr_RenameNode
    procedure, public :: GetNodeData => AP_UI_TreeMgr_GetNodeData
    procedure, public :: SetNodeData => AP_UI_TreeMgr_SetNodeData
    procedure, public :: GetChildren => AP_UI_TreeMgr_GetChildren
    procedure, public :: MoveNode => AP_UI_TreeMgr_MoveNode
    procedure, public :: GetNodePath => AP_UI_TreeMgr_GetNodePath
    procedure, public :: FindNodeByName => AP_UI_TreeMgr_FindNodeByName
    procedure, public :: ValidateNode => AP_UI_TreeMgr_ValidateNode
  end type AP_UI_TreeMgr_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `TreeMgr_Init` | 87 | `subroutine TreeMgr_Init(this, model_tree, status)` |
| SUBROUTINE | `TreeMgr_CreateNode` | 111 | `subroutine TreeMgr_CreateNode(this, parent_id, node_type, name, node_id, status)` |
| SUBROUTINE | `CreatePartNode` | 182 | `subroutine CreatePartNode(ctrl, name, obj_ptr, status)` |
| SUBROUTINE | `CreateMaterialNode` | 197 | `subroutine CreateMaterialNode(ctrl, name, obj_ptr, status)` |
| SUBROUTINE | `CreateSectionNode` | 212 | `subroutine CreateSectionNode(ctrl, name, obj_ptr, status)` |
| SUBROUTINE | `CreateStepNode` | 227 | `subroutine CreateStepNode(ctrl, name, obj_ptr, status)` |
| SUBROUTINE | `TreeMgr_DeleteNode` | 256 | `subroutine TreeMgr_DeleteNode(this, node_id, status)` |
| SUBROUTINE | `TreeMgr_RenameNode` | 356 | `subroutine TreeMgr_RenameNode(this, node_id, new_name, status)` |
| FUNCTION | `TreeMgr_GetNodeData` | 393 | `function TreeMgr_GetNodeData(this, node_id, status) result(obj_ptr)` |
| SUBROUTINE | `TreeMgr_SetNodeData` | 477 | `subroutine TreeMgr_SetNodeData(this, node_id, obj_ptr, status)` |
| SUBROUTINE | `TreeMgr_GetChildren` | 595 | `subroutine TreeMgr_GetChildren(this, parent_id, child_ids, status)` |
| SUBROUTINE | `TreeMgr_MoveNode` | 633 | `subroutine TreeMgr_MoveNode(this, node_id, new_parent_id, status)` |
| FUNCTION | `TreeMgr_GetNodePath` | 687 | `function TreeMgr_GetNodePath(this, node_id) result(path)` |
| FUNCTION | `TreeMgr_FindNodeByName` | 741 | `function TreeMgr_FindNodeByName(this, name, node_type) result(node_id)` |
| FUNCTION | `TreeMgr_ValidateNode` | 772 | `function TreeMgr_ValidateNode(this, node_id) result(is_valid)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
