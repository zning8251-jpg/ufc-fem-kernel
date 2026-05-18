# `L3_MD` / `Mesh` 设计意图（域桶）

> **域桶**：`ufc_core/L3_MD/Mesh/`（含 `Elem/<族>/` 子域）。  
> **验收向**：本 INTENT + 子域 [`CONTRACT.md`](../../../../../ufc_core/L3_MD/Elem/CONTRACT.md) + [`CONVENTIONS.md`](../../../CONVENTIONS.md) §1.1–§1.2。

## 1. 问题与目标

- **问题**：遗留 **`MODULE …_Algo`** 与四型中 **`TYPE …_Algo`** 同名易混；与「过程体用 `_Ops`」总规范不一致。
- **目标**：`Mesh/` 根与 `Elem/` 子树内 **编译单元（MODULE）** 统一为 **`…_Ops`**；**四型** 仍保留 **`TYPE …_Algo`** 命名（如 `TYPE(MD_ElemDomain_Algo)`）。
- **相关**：`L4_PH/Element` 域桶 **`PH_*_Algo` MODULE → `PH_*_Ops`** 已与工具脚本收敛；见 [`design/L4_PH/Element/INTENT.md`](../../L4_PH/Element/INTENT.md)。本域桶 **Mesh** 根 + **Element** 子树已完成。

## 2. `Mesh/` 根目录目标 MODULE（已实现，2026-04）

| 源码路径 | MODULE |
|----------|--------|
| `L3_MD/Mesh/MD_Mesh.f90` | `MD_Mesh` |
| `L3_MD/Mesh/MD_MeshDomain.f90` | `MD_MeshDomain`（修正原 `MD_MeshDomain_Algo.f90` 内误声明为 `MODULE MD_Mesh_Algo` 的重复名） |
| `L3_MD/Mesh/MD_Elem.f90` | `MD_Elem` |
| `L3_MD/Mesh/MD_MeshData.f90` 等 | `MD_MeshData`、`MD_MeshElem`、`MD_MeshNode`、`MD_MeshMgr`、`MD_MeshGlobalNum`、`MD_MeshSync`、`MD_Node`、`MD_DOF`、`MD_DOFMgr`、`MD_ElemFamily`、`MD_ElemInpMap` |

## 3. `Mesh/Element` 目标 MODULE 名（已实现，2026-04）

| 源码路径（相对 `ufc_core`） | 目标 MODULE（= 文件名 stem） | 备注 |
|-----------------------------|------------------------------|------|
| `L3_MD/Elem/MD_Elem_Def.f90` | `MD_Elem_Def` | `_Def`，保持 |
| `L3_MD/Elem/MD_ElemDomain.f90` | `MD_ElemDomain` | 内含 **`TYPE :: MD_ElemDomain_Algo`** |
| `L3_MD/Elem/MD_Elem_Reg.f90` | `MD_Elem_Reg` | 由旧数字尾巴模块迁移而来的单元注册表 |
| `L3_MD/Elem/MD_ElemPopulate.f90` | `MD_ElemPopulate` | |
| `L3_MD/Elem/MD_ElemValidate.f90` | `MD_ElemValidate` | |
| `L3_MD/Element/Elem/MD_Elem_PHBinding.f90` | `MD_Elem_PHBinding` | |
| `L3_MD/Elem/<族>/MD_Elem<Family>_Ops.f90` | 同左 stem（Beam/Shell/…） | 族级占位注册 |

## 4. 与 `generated/` / 推断清单

- 跑 `python UFC/tools/domain_procedure_registry_scan.py` 后，`generated/L3_MD/Mesh/...` **镜像**源码树。  
- [`UFC_层级域级f90文件推断清单_v2.0.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md) 中 ASCII 图 **`MD_Elem_XXX_Algo`** 行表示 **四型数据语义**；**MODULE 实现名** 以本表 `_Ops` 为准。

## 5. 姊妹域（L4 Element）

- **`L4_PH/Element`**：`design/L4_PH/Element/INTENT.md` + `manifest.json` 已就位；迁移后例行 `domain_procedure_registry_scan.py` → `domain_procedure_registry_align.py` → 构建。

## 6. 参考

- [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) §5.1  
- [`UFC_命名与数据结构规范.md`](../../../../UFC_命名与数据结构规范.md) §3.2
