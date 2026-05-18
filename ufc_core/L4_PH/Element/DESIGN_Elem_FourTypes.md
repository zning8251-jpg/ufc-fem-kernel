# 四大功能集详细设计文档 — Element 域

> **文档位置**: `L4_PH/Element/DESIGN_Elem_FourTypes.md`
> **版本**: v2.0
> **最后更新**: 2026-04-28
> **关联规范**: `L3_MD/Element/Elem/DOMAIN_PILLAR_CARD.md`（域柱卡）

---

## 1. 概述

本文档定义 L4_PH/Element 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：单元计算、刚度矩阵、单元残差、质量矩阵、形状函数、积分点管理

**设计说明（v4.0）**：
- PH_Elem_Base_Algo 已移除（Newmark/HHT 参数属于框架级配置）
- PH_Elem_Base_Ctx 内嵌 PH_Mat_Base_Ctx（避免重复）
- 仅保留 Ctx 和 State 两类活跃类型

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `elem_type_id` | INTEGER(i4) | 单元类型 ID（MD_ELEM_C3D8 等） | PH_Elem_Base_Ctx |
| `n_integration` | INTEGER(i4) | 积分点数量 | PH_Elem_Base_Ctx |
| `gauss_rule` | TYPE(GaussRule) | 高斯积分规则 | PH_Elem_Base_Ctx |
| `section_type` | INTEGER(i4) | 截面类型 | MD_Elem_Desc |
| `section_props(:)` | REAL(wp), ALLOCATABLE | 截面参数 | MD_Elem_Desc |

**生命周期**：
- **写入阶段**：模型建立时（MD 层）
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 步内只读，不进入热路径

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `rhs(:,:)` | REAL(wp), ALLOCATABLE | 残差矢量 [ndofel, nrhs] | PH_Elem_Base_State |
| `amatrx(:,:)` | REAL(wp), ALLOCATABLE | 刚度矩阵 [ndofel, ndofel] | PH_Elem_Base_State |
| `svars(:)` | REAL(wp), ALLOCATABLE | 状态变量 [nsvars] | PH_Elem_Base_State |
| `energy(8)` | REAL(wp) | 能量矢量（8分量） | PH_Elem_Base_State |
| `u(:)` | REAL(wp), ALLOCATABLE | 当前位移 | PH_Elem_Base_State |
| `v(:)` | REAL(wp), ALLOCATABLE | 当前速度 | PH_Elem_Base_State |
| `a(:)` | REAL(wp), ALLOCATABLE | 当前加速度 | PH_Elem_Base_State |

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

**说明**：v4.0 起 Element 域不再包含 Algo 类型，时间积分参数移至 RT_Com_Base_Ctx

**外部依赖**：
- 时间积分参数由 L5_RT/Solver 提供
- Newmark/HHT-α 参数通过框架注入

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `mat_ctx` | TYPE(PH_Mat_Base_Ctx) | 内嵌材料上下文 | PH_Elem_Base_Ctx |
| `coords(:,:)` | REAL(wp), ALLOCATABLE | [ndim, nnode] 当前构型坐标 | PH_Elem_Base_Ctx |
| `du(:,:)` | REAL(wp), ALLOCATABLE | [nnode, ndof] 位移增量 | PH_Elem_Base_Ctx |
| `predef(:,:,:)` | REAL(wp), ALLOCATABLE | [nnode, npredef, nrhs] 预定义场 | PH_Elem_Base_Ctx |
| `gauss_xi(:,:)` | REAL(wp), ALLOCATABLE | [n_points, dim] 自然坐标 | PH_Elem_Base_Ctx |
| `gauss_w(:)` | REAL(wp), ALLOCATABLE | [n_points] 积分权重 | PH_Elem_Base_Ctx |
| `gauss_detJ(:)` | REAL(wp), ALLOCATABLE | [n_points] Jacobian 行列式 | PH_Elem_Base_Ctx |
| `shape_N(:,:)` | REAL(wp), ALLOCATABLE | [n_points, nnode] 形函数 | PH_Elem_Base_Ctx |
| `shape_dN_dx(:,:,:)` | REAL(wp), ALLOCATABLE | [n_points, nnode, dim] 形函数梯度 | PH_Elem_Base_Ctx |

**生命周期**：
- **写入阶段**：每次增量步入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回即释放

**内存策略**：
- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配，禁止堆分配

---

## 3. 可微分物理引擎接口

| 接口名称 | 层级归属 | 职责 |
|----------|---------|------|
| `PH_Element_Compute_dR_dtheta` | L4_PH/Element | ∂R/∂θ 计算接口 |

**接口定义**：在 ABSTRACT INTERFACE 文件中声明（仅签名，无实现）

---

## 4. 单元族支持

| 单元族 | 路径 | 状态 |
|--------|------|------|
| SLD2D/SLD3D | `L4_PH/Element/SLD2D/` | 生产级 |
| SLD2DT/SLD3DT | `L4_PH/Element/SLD2DT/` | 生产级 |
| SHELL | `L4_PH/Element/SHELL/` | 生产级 |
| BEAM | `L4_PH/Element/BEAM/` | 开发中 |
| SPRING | `L4_PH/Element/SPRING/` | 生产级 |
| DASHPOT | `L4_PH/Element/DASHPOT/` | 开发中 |
| ACOUSTIC | `L4_PH/Element/ACOUSTIC/` | 开发中 |

---

## 4.5 四型裁剪决策（三层统一视图）

| 层 | Desc | State | Algo | Ctx |
|----|------|-------|------|-----|
| L3 | RETAINED(`MD_ElemDesc`) | TRIMMED | TRIMMED | TRIMMED |
| L4 | DELEGATED->L3(via Populate) | RETAINED(`PH_Elem_Base_State`) | TRIMMED(由L5注入) | RETAINED(`PH_Elem_Base_Ctx`) |
| L5 | DELEGATED | DELEGATED->L4 | DELEGATED->L4/Solver | RETAINED(`RT_Elem_Dispatch_Ctx`) |

---

## 5. 依赖关系

```text
MD_ElemDesc(L3) + MD_Elem_PHBinding(L3) → PH_L4_Populate_Element(L4)
PH_Elem_Base_Ctx(L4) 内嵌 PH_Mat_Base_Ctx(L4)
PH_Elem_Domain(L4) → RT_Elem_Dispatcher(L5) → PH_ElemContm_Ops/PH_Elem_{tribe}(L4)
RT_TimeInt_Algo(L5/Solver) → PH_Elem_Base_Ctx(L4) [时间积分参数注入]
```

---

## 6. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含单元类型配置 | PASS | 积分点、Gauss 规则 |
| State 含 UEL 输出 | PASS | RHS/AMATRX/SVARS/ENERGY |
| Ctx 含材料上下文内嵌 | PASS | PH_Mat_Base_Ctx |
| Ctx 含积分点缓存 | PASS | gauss_xi, gauss_w, shape_N |
| dR/dTheta 接口预留 | PASS | 可微分物理引擎 |
| 多单元族支持 | PASS | SLD/SHELL/BEAM 等 |
| 三层裁剪表对齐 | PASS | 与域柱卡 Section 3 一致 |
| 金线主链完整 | PASS | L3 Desc -> L4 Populate -> L5 Dispatch -> L4 Kernel |

---

**版本历史**：
- v2.0 (2026-04-28) - 对齐域柱卡v2统一模板，增加三层裁剪视图与依赖链更新
- v1.0 (2026-03-31) - 初始版本