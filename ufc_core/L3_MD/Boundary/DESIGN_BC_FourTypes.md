# 四大功能集详细设计文档 — Boundary 域（模型层）

> **文档位置**: `L3_MD/Boundary/DESIGN_BC_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L3_MD/Boundary 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：边界条件定义、载荷定义、BC 索引管理、LoadBC 统一接口

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `bc_id` | INTEGER(i4) | 边界条件 ID | MD_BC_Desc |
| `bc_type` | INTEGER(i4) | BC 类型 | MD_BC_Desc |
| `region_id` | INTEGER(i4) | 作用区域 ID | MD_BC_Desc |
| `dof_constraint(:)` | INTEGER(i4), ALLOCATABLE | DOF 约束 | MD_BC_Desc |
| `load_magnitude` | REAL(wp) | 载荷幅值 | MD_Load_Desc |

**BC 类型枚举**：
- 1 = 位移约束 (Displacement)
- 2 = 速度约束 (Velocity)
- 3 = 加速度约束 (Acceleration)
- 4 = 力载荷 (Force)
- 5 = 压力载荷 (Pressure)

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `applied_value` | REAL(wp) | 已施加值 | MD_BC_State |
| `reaction_force(:)` | REAL(wp), ALLOCATABLE | 反力 | MD_BC_State |
| `is_active` | LOGICAL | 激活标志 | MD_BC_State |

**生命周期**：
- **写入阶段**：每次增量步更新
- **读取阶段**：增量步内复用
- **释放时机**：增量步结束

**内存策略**：
- 温数据，Step 级 ALLOCATE

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `amplitude_id` | INTEGER(i4) | 幅值曲线 ID | MD_LoadBC_Algo |
| `time_dependency` | LOGICAL | 时间依赖开关 | MD_LoadBC_Algo |
| `load_case` | INTEGER(i4) | 工况 | MD_LoadBC_Algo |

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁

**内存策略**：
- 冷数据，可 ALLOCATABLE

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `bc_apply_mode` | INTEGER(i4) | BC 施加模式 | MD_LoadBC_Ctx |
| `current_time` | REAL(wp) | 当前时间 | MD_LoadBC_Ctx |
| `increment_factor` | REAL(wp) | 增量因子 | MD_LoadBC_Ctx |

**生命周期**：
- **写入阶段**：每次 BC 应用入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回

**内存策略**：
- 热路径上下文，栈分配
- 64-byte 对齐

---

## 3. 载荷类型定义

### 3.1 MD_Load_Types

| 字段 | 类型 | 说明 |
|------|------|------|
| `load_id` | INTEGER(i4) | 载荷 ID |
| `load_type` | INTEGER(i4) | 载荷类型 |
| `direction(:)` | REAL(wp), ALLOCATABLE | 方向矢量 |
| `magnitude` | REAL(wp) | 幅值 |

---

## 4. 依赖关系

```
MD_Model (L3) → MD_BC_Desc (L3) → MD_BC_State (L3)
MD_Load_Desc (L3) → MD_LoadBC_Ctx (L3)
L4_PH/LoadBC (L4) → MD_LoadBC (L3)  [BC 应用]
L5_RT/LoadBC (L5) → MD_LoadBC (L3)  [运行时调度]
```

---

## 5. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含 BC/载荷定义 | ✅ | ID/类型/区域 |
| State 含反力追踪 | ✅ | 反应力 |
| Algo 含幅值曲线 | ✅ | 时间依赖 |
| Ctx 含施加模式 | ✅ | 时间/因子 |
| 工况支持 | ✅ | 多工况 |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本