# `MD_Model_Tree.f90`

- **Source**: `L3_MD/Model/MD_Model_Tree.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Model_Tree`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Tree`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model_Tree`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_Tree.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_ModelTree_Traverse_Arg` (lines 1618–1622)

```fortran
  TYPE, PUBLIC :: MD_ModelTree_Traverse_Arg
    TYPE(ModelTree), POINTER          :: tree        ! [IN] tree to traverse
    CHARACTER(LEN=256)                :: result      ! [OUT] traversal result
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_ModelTree_Traverse_Arg
```

### `MD_ModelTree_QueryOptimize_Arg` (lines 1624–1628)

```fortran
  TYPE, PUBLIC :: MD_ModelTree_QueryOptimize_Arg
    TYPE(ModelTree), POINTER          :: tree        ! [IN] tree to optimize
    INTEGER(i4)                       :: opt_level   ! [IN] optimization level
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_ModelTree_QueryOptimize_Arg
```

### `MD_ModelTree_FindByPath_Arg` (lines 1630–1635)

```fortran
  TYPE, PUBLIC :: MD_ModelTree_FindByPath_Arg
    TYPE(ModelTree), POINTER          :: tree        ! [IN] tree
    CHARACTER(LEN=256)                :: path        ! [IN] path string
    CLASS(TreeNodeBase), POINTER      :: result      ! [OUT] found node
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_ModelTree_FindByPath_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ModelTree_Build_NameIndex` | 73 | `SUBROUTINE ModelTree_Build_NameIndex(tree, status)` |
| SUBROUTINE | `ModelTree_Build_PathIndex` | 84 | `SUBROUTINE ModelTree_Build_PathIndex(tree, status)` |
| SUBROUTINE | `ModelTree_Build_TypeIndex` | 97 | `SUBROUTINE ModelTree_Build_TypeIndex(tree, status)` |
| SUBROUTINE | `ModelTree_DFS_Recursive` | 110 | `RECURSIVE SUBROUTINE ModelTree_DFS_Recursive(tree, visitor_proc, depth, status)` |
| SUBROUTINE | `visitor_proc` | 113 | `SUBROUTINE visitor_proc(node_id, node_type, depth, status)` |
| SUBROUTINE | `MD_ModelTree_BFS_Traverse` | 143 | `SUBROUTINE MD_ModelTree_BFS_Traverse(tree, visitor_proc, status)` |
| SUBROUTINE | `visitor_proc` | 146 | `SUBROUTINE visitor_proc(node_id, node_type, depth, status)` |
| SUBROUTINE | `MD_ModelTree_BuildIndex` | 194 | `SUBROUTINE MD_ModelTree_BuildIndex(tree, index_type, status)` |
| SUBROUTINE | `MD_ModelTree_DFS_Traverse` | 224 | `SUBROUTINE MD_ModelTree_DFS_Traverse(tree, visitor_proc, status)` |
| SUBROUTINE | `visitor_proc` | 227 | `SUBROUTINE visitor_proc(node_id, node_type, depth, status)` |
| SUBROUTINE | `MD_ModelTree_FindByPath` | 248 | `SUBROUTINE MD_ModelTree_FindByPath(tree, path, obj_ptr, status)` |
| SUBROUTINE | `MD_ModelTree_FindByType` | 274 | `SUBROUTINE MD_ModelTree_FindByType(tree, obj_type, obj_list, nFound, status)` |
| SUBROUTINE | `MD_ModelTree_QueryOptimize` | 307 | `SUBROUTINE MD_ModelTree_QueryOptimize(tree, rebuild_index, status)` |
| SUBROUTINE | `ModelTree_AddAssembly` | 337 | `subroutine ModelTree_AddAssembly(this, assembly, status)` |
| SUBROUTINE | `ModelTree_AddChild` | 412 | `subroutine ModelTree_AddChild(this, child, status)` |
| SUBROUTINE | `ModelTree_AddInteraction` | 449 | `subroutine ModelTree_AddInteraction(this, interaction, status)` |
| SUBROUTINE | `ModelTree_AddLoadBC` | 524 | `subroutine ModelTree_AddLoadBC(this, loadbc, status)` |
| SUBROUTINE | `ModelTree_AddMaterial` | 599 | `subroutine ModelTree_AddMaterial(this, Mat, status)` |
| SUBROUTINE | `ModelTree_AddPart` | 677 | `subroutine ModelTree_AddPart(this, part, status)` |
| SUBROUTINE | `ModelTree_AddSection` | 711 | `subroutine ModelTree_AddSection(this, section, status)` |
| SUBROUTINE | `ModelTree_AddStep` | 786 | `subroutine ModelTree_AddStep(this, step, status)` |
| SUBROUTINE | `ModelTree_BeginBatch` | 807 | `subroutine ModelTree_BeginBatch(this, max_size)` |
| SUBROUTINE | `ModelTree_ClearAll` | 814 | `subroutine ModelTree_ClearAll(this, status)` |
| SUBROUTINE | `ModelTree_Deserialize` | 839 | `subroutine ModelTree_Deserialize(this, deserializer)` |
| SUBROUTINE | `ModelTree_DestroyTree` | 887 | `subroutine ModelTree_DestroyTree(this, status)` |
| SUBROUTINE | `ModelTree_EndBatch` | 918 | `subroutine ModelTree_EndBatch(this, rebuild_index, status)` |
| FUNCTION | `ModelTree_GetAmplitude` | 936 | `function ModelTree_GetAmplitude(this, id, name) result(amplitude_ptr)` |
| FUNCTION | `ModelTree_GetAssembly` | 960 | `function ModelTree_GetAssembly(this, id, name) result(assembly_ptr)` |
| FUNCTION | `ModelTree_GetByPath` | 984 | `function ModelTree_GetByPath(this, path_str) result(obj_ptr)` |
| FUNCTION | `ModelTree_GetChildByType` | 1085 | `function ModelTree_GetChildByType(this, node_type, id, name) result(obj_ptr)` |
| FUNCTION | `ModelTree_GetContainer` | 1113 | `function ModelTree_GetContainer(this, node_type) result(container_ptr)` |
| FUNCTION | `ModelTree_GetFullPath` | 1144 | `function ModelTree_GetFullPath(this) result(path_str)` |
| FUNCTION | `ModelTree_GetID` | 1159 | `function ModelTree_GetID(this) result(id)` |
| FUNCTION | `ModelTree_GetInteraction` | 1166 | `function ModelTree_GetInteraction(this, id, name) result(interaction_ptr)` |
| FUNCTION | `ModelTree_GetLoadBC` | 1190 | `function ModelTree_GetLoadBC(this, id, name) result(loadbc_ptr)` |
| FUNCTION | `ModelTree_GetMaterial` | 1214 | `function ModelTree_GetMaterial(this, id, name) result(material_ptr)` |
| FUNCTION | `ModelTree_GetMesh` | 1238 | `function ModelTree_GetMesh(this, id, name) result(mesh_ptr)` |
| FUNCTION | `ModelTree_GetName` | 1262 | `function ModelTree_GetName(this) result(name)` |
| FUNCTION | `ModelTree_GetNumMaterials` | 1268 | `function ModelTree_GetNumMaterials(this) result(count)` |
| FUNCTION | `ModelTree_GetNumParts` | 1278 | `function ModelTree_GetNumParts(this) result(count)` |
| FUNCTION | `ModelTree_GetNumSteps` | 1288 | `function ModelTree_GetNumSteps(this) result(count)` |
| FUNCTION | `ModelTree_GetParentID` | 1298 | `function ModelTree_GetParentID(this) result(pid)` |
| FUNCTION | `ModelTree_GetPart` | 1304 | `function ModelTree_GetPart(this, id, name) result(part_ptr)` |
| FUNCTION | `ModelTree_GetSection` | 1328 | `function ModelTree_GetSection(this, id, name) result(section_ptr)` |
| FUNCTION | `ModelTree_GetStep` | 1352 | `function ModelTree_GetStep(this, id, name) result(step_ptr)` |
| FUNCTION | `ModelTree_GetType` | 1376 | `function ModelTree_GetType(this) result(ntype)` |
| SUBROUTINE | `ModelTree_InitTree` | 1382 | `subroutine ModelTree_InitTree(this, initial_capacit, status)` |
| SUBROUTINE | `ModelTree_RebuildIndex` | 1471 | `subroutine ModelTree_RebuildIndex(this, status)` |
| SUBROUTINE | `ModelTree_RemoveChild` | 1492 | `subroutine ModelTree_RemoveChild(this, child_id, node_type, status)` |
| SUBROUTINE | `ModelTree_Serialize` | 1528 | `subroutine ModelTree_Serialize(this, serializer)` |
| SUBROUTINE | `ModelTree_ValidateTree` | 1571 | `subroutine ModelTree_ValidateTree(this, status)` |
| SUBROUTINE | `ModelTree_OptimizeLazyIndices` | 1597 | `SUBROUTINE ModelTree_OptimizeLazyIndices(tree, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 112–118 | `INTERFACE` |
| 145–151 | `INTERFACE` |
| 226–232 | `INTERFACE` |
