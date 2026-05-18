# 四大功能集详细设计文档 — Field 域（模型层）

> **文档位置**: `L3_MD/Field/DESIGN_Field_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L3_MD/Field 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：场变量定义（温度、孔压、浓度、位移）、插值方法、梯度计算

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `field_id` | INTEGER(i4) | 场变量 ID | MD_Field_Base_Desc |
| `field_type` | INTEGER(i4) | 场类型 | MD_Field_Base_Desc |
| `initial_value` | REAL(wp) | 初始值 | MD_Field_Base_Desc |
| `field_label` | CHARACTER(LEN=64) | 场标签 | MD_Field_Base_Desc |

**字段类型枚举**：
- 1 = 温度场 (Temperature)
- 2 = 孔压场 (PorePressure)
- 3 = 浓度场 (Concentration)
- 4 = 位移场 (Displacement)

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 步内只读，不进入热路径

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `values(:)` | REAL(wp), ALLOCATABLE | 场值数组 | MD_Field_Base_State |
| `gradients(:,:)` | REAL(wp), ALLOCATABLE | 梯度数组 | MD_Field_Base_State |
| `previous_values(:)` | REAL(wp), ALLOCATABLE | 上一步场值 | MD_Field_State |

**生命周期**：
- **写入阶段**：每次增量步更新
- **读取阶段**：增量步内复用
- **释放时机**：增量步结束时

**内存策略**：
- 温数据，Step 级 ALLOCATE
- 高频读写，进入热路径

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `interpolation_method` | INTEGER(i4) | 插值方法 | MD_Field_Base_Algo |
| `use_gradient` | LOGICAL | 梯度计算开关 | MD_Field_Base_Algo |
| `extrapolation` | LOGICAL | 外推开关 | MD_Field_Algo |

**插值方法枚举**：
- 1 = 线性 (Linear)
- 2 = 二次 (Quadratic)
- 3 = 拉格朗日 (Lagrangian)
- 4 = Hermite

**生命周期**：
- **写入阶段**：模型建立时
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 跨步复用

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `coord_system` | INTEGER(i4) | 坐标系类型 | MD_Field_Ctx |
| `time_current` | REAL(wp) | 当前时间 | MD_Field_Ctx |
| `integration_point` | INTEGER(i4) | 积分点索引 | MD_Field_Ctx |

**生命周期**：
- **写入阶段**：每次场计算入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回

**内存策略**：
- 热路径上下文，栈分配
- 64-byte 对齐

---

## 3. 场类型定义

### 3.1 温度场 (MD_Field_Temperature_Desc)

| 字段 | 类型 | 说明 |
|------|------|------|
| `field_id` | INTEGER(i4) | 温度场 ID |
| `initial_temp` | REAL(wp) | 初始温度 |
| `boundary_type` | INTEGER(i4) | 边界类型 |

### 3.2 孔压场 (MD_Field_PorePressure_Desc)

| 字段 | 类型 | 说明 |
|------|------|------|
| `field_id` | INTEGER(i4) | 孔压场 ID |
| `initial_pressure` | REAL(wp) | 初始孔压 |
| ` compressibility` | REAL(wp) | 压缩系数 |

### 3.3 位移场 (MD_Field_Displacement_Desc)

| 字段 | 类型 | 说明 |
|------|------|------|
| `field_id` | INTEGER(i4) | 位移场 ID |
| `coord_system` | INTEGER(i4) | 坐标系 |

---

## 4. 依赖关系

```
MD_Model_Desc (L3) → MD_Field_Desc (L3) → MD_Field_State (L3)
MD_Field_Algo (L3) → MD_Field_Ctx (L3)
L4_PH/Field (L4) → MD_Field_State (L3)  [场演化]
L4_PH/Element (L4) → MD_Field_Ctx (L3)  [积分点场值]
```

---

## 5. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含场定义 | ✅ | ID/类型/初始值 |
| State 含梯度和历史 | ✅ | 增量步追踪 |
| Algo 含插值方法 | ✅ | 线性/二次/Hermite |
| Ctx 上下文 | ✅ | 坐标系/时间 |
| 多场类型支持 | ✅ | 温度/孔压/位移 |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本