# `L3_MD` / `Field` 设计意图（模板域）

> **域桶**：`ufc_core/L3_MD/Field/`  
> **合同**：`ufc_core/L3_MD/Field/CONTRACT.md`  
> **域柱卡**：`ufc_core/L3_MD/Field/DOMAIN_PILLAR_CARD.md`

## 1. 目标

Field 作为 L3/L4/L5 同步设计的首个模板域，L3 侧只保留 Field 定义真源和管理器入口：

- `MD_Field_Def.f90`：Field 类型/实体/分布/Region/Set/初始条件合同，及 `MD_Field_Desc`、`MD_Field_State`、`MD_Field_Ctx`、`MD_FieldEntry`。
- `MD_Field_Mgr.f90`：节点场、积分点状态、Field 管理器，以及原 `MD_Field_Core` 的有效注册/查询过程。

## 2. 当前模块集合

| 模块 | 角色 | 说明 |
|---|---|---|
| `MD_Field_Def.f90` | `Def` | L3 Field 模型语义合同与 Desc/State/Ctx 权威 |
| `MD_Field_Mgr.f90` | `Mgr` | L3 Field 容器和 CRUD API |

## 3. 旧资产决策

| 旧文件 | 决策 |
|---|---|
| `MD_Field_Core.f90` | 有效 CRUD 过程合并进 `MD_Field_Mgr.f90` 后删除 |
| `MD_Field_Brg.f90` | 空桥接骨架，删除 |

## 4. L3/L4/L5 同步锚点

`L3_MD/Field` 是 Field Desc 与模型语义真源；`L4_PH/Field` 在 Populate/Step init 后使用自身 TYPE 承载计算；`L5_RT` 的 Assembly/Solver/Output 只是消费者，不新增 Field 真源。

## 5. 模板域验收

本域作为 H2 Field 半柱的 L3 侧模板，验收以 `MD_Field_Def.f90` / `MD_Field_Mgr.f90` 两文件为准：`Def` 承载模型语义合同，`Mgr` 承载容器与 CRUD；旧 `Core` / `Brg` 不再出现在 manifest 或 generated registry 中。

## 6. Registry 约束

`manifest.json` 只列当前源码目标文件。生成目录漂移由 `domain_procedure_registry_scan.py` 与 `domain_procedure_registry_align.py` 处理。
