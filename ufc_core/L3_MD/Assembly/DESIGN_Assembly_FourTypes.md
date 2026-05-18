# 四大功能集详细设计文档 — Assembly 域（模型层）

> **文档位置**: `L3_MD/Assembly/DESIGN_Assembly_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L3_MD/Assembly 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：装配实例管理、装配层次结构、实例间依赖、同步机制

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `instance_id` | INTEGER(i4) | 装配实例 ID | MD_Assem_Desc |
| `instance_type` | INTEGER(i4) | 实例类型 | MD_Assem_Desc |
| `instance_name` | CHARACTER(LEN=128) | 实例名称 | MD_Assem_Desc |
| `part_ids(:)` | INTEGER(i4), ALLOCATABLE | 部件 ID 列表 | MD_Assem_Desc |
| `n_elements` | INTEGER(i4) | 单元总数 | MD_Assem_Desc |
| `n_nodes` | INTEGER(i4) | 节点总数 | MD_Assem_Desc |

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 步内只读

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `element_count` | INTEGER(i4) | 当前单元数 | MD_Assem_State |
| `node_count` | INTEGER(i4) | 当前节点数 | MD_Assem_State |
| `dof_count` | INTEGER(i4) | DOF 总数 | MD_Assem_State |
| `is_assembled` | LOGICAL | 装配完成标志 | MD_Assem_State |

**生命周期**：
- **写入阶段**：模型建立后更新
- **读取阶段**：装配过程复用
- **释放时机**：模型重置

**内存策略**：
- 温数据，按需 ALLOCATE

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `assembly_strategy` | INTEGER(i4) | 装配策略 | MD_Assem |
| `parallel_enabled` | LOGICAL | 并行开关 | MD_Assem |
| `sync_mode` | INTEGER(i4) | 同步模式 | MD_Assem_Legacy |

**装配策略枚举**：
- 1 = 串行装配 (Serial)
- 2 = 并行装配 (Parallel)
- 3 = 分块装配 (Block)

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：装配过程只读
- **释放时机**：模型销毁

**内存策略**：
- 冷数据，可 ALLOCATABLE

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `current_part_id` | INTEGER(i4) | 当前部件 ID | MD_Assem_Ctx |
| `current_element_id` | INTEGER(i4) | 当前单元 ID | MD_Assem_Ctx |
| `local_to_global_map(:)` | INTEGER(i4), ALLOCATABLE | 局部到全局映射 | MD_Assem_Ctx |

**生命周期**：
- **写入阶段**：每次装配调用入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回

**内存策略**：
- 热路径上下文，栈分配
- 64-byte 对齐

---

## 3. 实例管理

### 3.1 MD_Instance

| 字段 | 类型 | 说明 |
|------|------|------|
| `instance_id` | INTEGER(i4) | 实例 ID |
| `parent_id` | INTEGER(i4) | 父实例 ID |
| `children_ids(:)` | INTEGER(i4), ALLOCATABLE | 子实例列表 |

---

## 4. 依赖关系

```
MD_Part_Desc (L3) → MD_Assem_Desc (L3)
MD_Model (L3) → MD_Assem (L3) → MD_Assem_State
L5_RT/Assembly (L5) → MD_Assembly (L3)  [装配调度]
```

---

## 5. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含实例配置 | ✅ | ID/类型/部件 |
| State 含计数 | ✅ | 单元/节点/DOF |
| Algo 含装配策略 | ✅ | 串行/并行/分块 |
| Ctx 含映射 | ✅ | 局部到全局 |
| 实例层次支持 | ✅ | 父子关系 |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本