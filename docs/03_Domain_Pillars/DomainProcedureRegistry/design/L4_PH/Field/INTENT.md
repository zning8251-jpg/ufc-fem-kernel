# `L4_PH` / `Field` 设计意图（模板域）

> **域桶**：`ufc_core/L4_PH/Field/`  
> **合同**：`ufc_core/L4_PH/Field/CONTRACT.md`

## 1. 目标

`L4_PH/Field` 承接 L3 Field 真源，负责 Field 通用操作和温度/孔压/浓度计算。它是物理计算层，不拥有模型定义，不复制 L3 的类型/实体/分布/Region 语义合同，也不新增 L5 调度职责。

## 2. 当前模块集合

| 模块 | 角色 | 说明 |
|---|---|---|
| `PH_Field_Def.f90` | `Def` | L4 Field 通用四型和温度/孔压/浓度专属 TYPE |
| `PH_Field_Ops.f90` | `Ops` | 插值、外推、节点平均、梯度、不变量 |
| `PH_Field_ComputeTemp.f90` | Compute | 温度场求解/装配/边界 |
| `PH_Field_ComputePore.f90` | Compute | 孔隙压力求解/装配/边界 |
| `PH_Field_ComputeConc.f90` | Compute | 浓度求解/装配/边界 |
| `PH_Field_GaussQuadrature.f90` | Support | 高斯点支持 |
| `PH_Field_ShapeFunc.f90` | Support | 形函数、梯度、Jacobian 支持；域内支持模块，不使用 `_Brg` |
| `PH_Field_Cpl.f90` | Coupling | 多物理贡献 |

## 3. 旧资产决策

| 旧文件 | 决策 |
|---|---|
| `PH_Field_Brg.f90` | 纯转调门面，无消费者，删除 |
| stale `PH_Field_Types.f90` / `PH_Field_API.f90` 文档引用 | 改为 `PH_Field_Def.f90` 与实际 Compute 文件 |

## 4. L5 消费锚点

现阶段不创建 `L5_RT/Field` 域。Field 消费分散在 `L5_RT/Assembly`、`L5_RT/Solver/Coupling`、`L5_RT/Output`，后续若要收敛，先以合同变更方式定义 `L5_RT/Field` 边界。

## 5. 模板域验收

本域作为 H2 Field 半柱的 L4 侧模板，验收以 `Def` / `Ops` / `Compute*` / `Support` / `Cpl` 五类角色为准：不恢复旧 `Core` 命名，不新增薄 `Brg` 或薄 `Proc`，L5 消费点只在合同中记录。

## 6. Registry 约束

`manifest.json` 必须列实际存在的源文件名；禁止保留 `PH_FieldCompute*`、`PH_FieldShapeFunc_Brg`、`PH_Field_MultiPhysContrib` 这类旧 stem。
