# 四大功能集详细设计文档 — Field 域（物理计算层）

> **文档位置**: `L4_PH/Field/DESIGN_Field_FourTypes.md`
> **版本**: v2.0
> **最后更新**: 2026-04-28
> **关联规范**: `L3_MD/Field/DOMAIN_PILLAR_CARD.md`（域柱卡）

---

## 1. 概述

本文档定义 L4_PH/Field 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：场物理计算（温度场/孔压场/浓度场）、高斯积分/形函数支持、多物理场耦合贡献

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `field_id` | INTEGER(i4) | 场变量 ID | PH_Field_Desc |
| `field_type` | INTEGER(i4) | 场类型码(温度/孔压/浓度) | PH_Field_Desc |
| `n_nodes` | INTEGER(i4) | 相关节点数 | PH_Field_Desc |
| `initial_temp` | REAL(wp) | 初始温度 | PH_Temperature_Desc |
| `conductivity` | REAL(wp) | 导热系数 | PH_Temperature_Desc |
| `specific_heat` | REAL(wp) | 比热容 | PH_Temperature_Desc |
| `initial_pressure` | REAL(wp) | 初始孔压 | PH_PorePressure_Desc |
| `permeability` | REAL(wp) | 渗透系数 | PH_PorePressure_Desc |
| `initial_conc` | REAL(wp) | 初始浓度 | PH_Concentration_Desc |
| `diffusivity` | REAL(wp) | 扩散系数 | PH_Concentration_Desc |

**生命周期**：
- **写入阶段**：Populate 时从 L3 MD_FieldDesc 映射
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- Populate 后只读，不进入热路径

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `values(:)` | REAL(wp), ALLOCATABLE | 节点场值 | PH_Field_State |
| `gradients(:,:)` | REAL(wp), ALLOCATABLE | 积分点梯度 | PH_Field_State |
| `flux(:,:)` | REAL(wp), ALLOCATABLE | 通量(热/渗/扩散) | PH_Field_State |
| `previous_values(:)` | REAL(wp), ALLOCATABLE | 上一步场值(Rollback) | PH_Field_State |
| `step_num` | INTEGER(i4) | 当前步号 | PH_Field_State |
| `inc_num` | INTEGER(i4) | 当前增量步号 | PH_Field_State |

**生命周期**：
- **写入阶段**：每次增量步/迭代更新
- **读取阶段**：增量步内多迭代复用
- **释放时机**：增量步结束时

**内存策略**：
- 温数据，Step 级 ALLOCATE
- 高频读写，进入热路径
- 需 Rollback 机制支持

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `time_integ_scheme` | INTEGER(i4) | 时间积分格式(显式/隐式) | PH_Field_Algo |
| `max_iter` | INTEGER(i4) | 最大迭代数 | PH_Field_Algo |
| `tol` | REAL(wp) | 收敛容差 | PH_Field_Algo |
| `theta` | REAL(wp) | θ 参数(Crank-Nicolson) | PH_Temperature_Algo |
| `lumped_capacity` | LOGICAL | 集中容量矩阵开关 | PH_Temperature_Algo |
| `compressibility` | REAL(wp) | 流体压缩系数 | PH_PorePressure_Algo |
| `reaction_rate` | REAL(wp) | 反应速率系数 | PH_Concentration_Algo |

**生命周期**：
- **写入阶段**：分析步初始化
- **读取阶段**：迭代内只读
- **释放时机**：分析步结束

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 迭代内只读，跨步复用

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `coords(:,:)` | REAL(wp) | 积分点/节点坐标 | PH_Field_Ctx |
| `shape_val(:)` | REAL(wp) | 形函数值 | PH_Field_Ctx |
| `shape_grad(:,:)` | REAL(wp) | 形函数梯度 | PH_Field_Ctx |
| `jacobian` | REAL(wp) | Jacobian 行列式 | PH_Field_Ctx |
| `weight` | REAL(wp) | 高斯积分权重 | PH_Field_Ctx |
| `elem_type` | INTEGER(i4) | 单元类型码 | PH_Field_Ctx |
| `n_ip` | INTEGER(i4) | 积分点数 | PH_Field_Ctx |

**生命周期**：
- **写入阶段**：每次场计算入口
- **读取阶段**：单次 Compute 调用内
- **释放时机**：调用返回即释放

**内存策略**：
- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配，禁止堆分配

---

## 3. AI-ready 插槽集成

| 插槽编号 | 插槽名称 | 域级归属 | 四型职责 |
|----------|---------|---------|----------|
| (预留) | AI_FieldPredict | Field | Algo（场预测参数）+ Ctx（历史缓冲） |

**接口规范**：
- 当前未激活，预留场演化预测插槽
- 未来可支持 AI 加速温度场/耦合场预测

---

## 4. 四型裁剪决策（三层统一视图）

| 层 | Desc | State | Algo | Ctx |
|----|------|-------|------|-----|
| L3 | RETAINED(`MD_FieldDesc`) | RETAINED(`MD_FieldState`) | TRIMMED | TRIMMED |
| L4 | DELEGATED->L3(via Populate) | RETAINED(`PH_Field_State`) | RETAINED(`PH_Field_Algo`) | RETAINED(`PH_Field_Ctx`) |
| L5 | DELEGATED | DELEGATED->L4 | DELEGATED->L4 | DELEGATED->L4 |

**裁剪说明**：
- L3 只保留场定义(Desc)和场值真源(State)，Algo/Ctx由L4负责
- L4 Desc委托L3(经Populate映射)，State/Algo/Ctx均保留为计算载体
- L5 无独立Field域(H2半柱)，全部委托给L4，通过Assembly/Solver/Output消费

---

## 5. 依赖关系

```text
MD_FieldDesc(L3) → PH_L4_Populate_Field → PH_Field_Desc/State/Algo(L4)
PH_Field_Desc(L4) → PH_Field_Ops → PH_Field_Ctx(L4)
PH_Field_Ctx(L4) → PH_Field_ComputeTemp/ComputePore/ComputeConc(L4)
PH_Field_ShapeFunc(L4) → PH_Field_ComputeTemp/ComputePore/ComputeConc(L4)
PH_Field_GaussQuadrature(L4) → PH_Field_ComputeTemp/ComputePore/ComputeConc(L4)
PH_Field_State/Ctx(L4) → L5_RT Assembly/Solver/Output (消费点)
```

---

## 6. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 字段完整 | PASS | 通用 + 温度/孔压/浓度三专属 |
| State 含 Rollback | PASS | previous_values 支持增量步回退 |
| Algo 含时间积分 | PASS | 显式/隐式/θ参数 |
| Ctx 零 ALLOCATE | PASS | AP-8 热路径约束 |
| 64-byte 对齐 | PASS | Ctx 类型 |
| 三层裁剪表对齐 | PASS | 与域柱卡 Section 3 一致 |
| L3 Algo/Ctx TRIMMED | PASS | 场算法参数由 L4 独立持有 |
| 金线主链完整 | PASS | L3 Desc -> L4 Populate -> L4 Ops -> Compute* -> L5 消费 |

---

**版本历史**：
- v2.0 (2026-04-28) - 新建，对齐域柱卡v2统一模板，含三层裁剪视图与完整依赖链
