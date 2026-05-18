# 四大功能集详细设计文档 — Contact 域

> **文档位置**: `L4_PH/Contact/DESIGN_Cont_FourTypes.md`
> **版本**: v2.0
> **最后更新**: 2026-04-28
> **关联规范**: `L3_MD/Interaction/DOMAIN_PILLAR_CARD.md`（域柱卡）

---

## 1. 概述

本文档定义 L4_PH/Contact 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：接触检测、接触约束求解、摩擦模型、接触力计算

**理论依据**：
- Karush-Kuhn-Tucker (KKT) 条件
- 罚函数法与增广拉格朗日法
- Coulomb 摩擦模型

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `constr%method` | INTEGER(i4) | 约束方法：1=Penalty, 2=Lagrange, 3=AugLag | PH_Cont_Constr_Desc |
| `constr%penalty_parameter` | REAL(wp) | 罚参数 | PH_Cont_Constr_Desc |
| `friction%model_type` | INTEGER(i4) | 摩擦模型：1=Coulomb, 2=Tresca, 3=Rate-dependent | PH_Cont_Friction_Desc |
| `friction%mu_static` | REAL(wp) | 静摩擦系数 | PH_Cont_Friction_Desc |
| `friction%mu_dynamic` | REAL(wp) | 动摩擦系数 | PH_Cont_Friction_Desc |
| `search%search_algorithm` | INTEGER(i4) | 搜索算法：1=Basic, 2=BVH, 3=Octree | PH_Cont_Search_Desc |
| `contact_pair_id` | INTEGER(i4) | 接触对 ID | PH_Cont_Desc |
| `slave_surface_id` | INTEGER(i4) | 从面 ID | PH_Cont_Desc |

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
| `contact_state` | INTEGER(i4) | 接触状态：0=分离, 1=接触, 2=粘结, 3=滑动 | PH_Cont_State |
| `geometry%gap` | REAL(wp) | 间隙 | PH_Cont_Geometry_State |
| `geometry%penetration` | REAL(wp) | 穿透量 | PH_Cont_Geometry_State |
| `force%normal_force(:)` | REAL(wp), ALLOCATABLE | 法向力矢量 | PH_Cont_Force_State |
| `force%friction_force(:)` | REAL(wp), ALLOCATABLE | 摩擦力矢量 | PH_Cont_Force_State |
| `stiffness%K_contact(:,:)` | REAL(wp), ALLOCATABLE | 接触刚度矩阵 | PH_Cont_Stiffness_State |
| `friction%slip_velocity(:)` | REAL(wp), ALLOCATABLE | 滑移速度 | PH_Cont_Friction_State |
| `convergence%residual_norm` | REAL(wp) | 残差范数 | PH_Cont_Convergence_State |
| `convergence%iteration_count` | INTEGER(i4) | 迭代计数 | PH_Cont_Convergence_State |

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
| `constr%max_iterations` | INTEGER(i4) | 最大迭代数 | PH_Cont_Constr_Algo |
| `constr%tolerance` | REAL(wp) | 收敛容差 | PH_Cont_Constr_Algo |
| `constr%optimization_strategy` | INTEGER(i4) | 优化策略：1=CG, 2=Newton, 3=Quasi-Newton | PH_Cont_Constr_Algo |
| `friction%decay_rate` | REAL(wp) | 摩擦衰减率 | PH_Cont_Friction_Algo |
| `friction%rate_dependency` | LOGICAL | 率相关开关 | PH_Cont_Friction_Algo |
| `ai_enabled` | LOGICAL | AI 接触律开关 | AI_ContactLaw_Algo |
| `ai_proxy_type` | INTEGER(i4) | AI 代理类型 | AI_ContactLaw_Algo |

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
| `slave_node_coords(:,:)` | REAL(wp) | 从节点坐标 | PH_Cont_Ctx |
| `master_node_coords(:,:)` | REAL(wp) | 主节点坐标 | PH_Cont_Ctx |
| `normal_vector(:)` | REAL(wp) | 法向矢量 | PH_Cont_Ctx |
| `tangent_vector1(:)` | REAL(wp) | 切向矢量 | PH_Cont_Ctx |
| `contactPressure` | REAL(wp) | 接触压力 | PH_Cont_Ctx |
| `gap_function` | REAL(wp) | 间隙函数值 | PH_Cont_Ctx |

**生命周期**：
- **写入阶段**：每次增量步入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回即释放

**内存策略**：
- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配，禁止堆分配

---

## 3. AI-ready 插槽集成

| 插槽编号 | 插槽名称 | 域级归属 | 四型职责 |
|----------|---------|---------|----------|
| ④ | AI_ContactLaw | Contact | Algo（接触律代理参数） |

**接口规范**：
- 文件：`AI_ContactLaw_Algo.f90`
- 支持神经网络代理接触力计算
- 批量推理接口

---

## 4. BVH 加速结构

**BVH 构建**：
- 文件：`PH_Cont_BVH_Builder.f90`
- 用于大规模接触对的高效搜索

**BVH 查询**：
- 文件：`PH_Cont_BVH_Query.f90`
- 空间查询接口

---

## 4.5 四型裁剪决策（三层统一视图）

| 层 | Desc | State | Algo | Ctx |
|----|------|-------|------|-----|
| L3 | RETAINED(`MD_IntDesc`) | TRIMMED | TRIMMED | RETAINED(`MD_Int_Ctx`) |
| L4 | DELEGATED->L3(via Populate) | RETAINED(`PH_Cont_State`) | RETAINED(`PH_Cont_Algo`) | RETAINED(`PH_Cont_Ctx`) |
| L5 | DELEGATED | DELEGATED->L4 | DELEGATED->L4 | RETAINED(`RT_Cont_Dispatch_Ctx`) |

---

## 5. 依赖关系

```text
MD_IntDesc(L3) + MD_Int_Ctx(L3) → PH_L4_Populate_Contact(L4)
PH_Cont_Def(L4) → PH_Cont_Domain(L4) → RT_Cont_Search(L5) → PH_Cont_BVH(L4)
RT_Cont_Core(L5) → PH_Cont_Core(L4 法向/摩擦) → PH_Cont_State(L4)
RT_Cont_Solv(L5) → 全局约束装配
```

---

## 6. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 字段完整 | PASS | 约束/摩擦/搜索三组件 |
| State 含几何/力/刚度 | PASS | 完整状态追踪 |
| Algo 含收敛控制 | PASS | 迭代控制参数 |
| Ctx 零 ALLOCATE | PASS | AP-8 热路径约束 |
| AI 插槽已部署 | PASS | AI_ContactLaw_Algo |
| BVH 加速支持 | PASS | BVH Builder/Query |
| 三层裁剪表对齐 | PASS | 与域柱卡 Section 3 一致 |
| 金线主链完整 | PASS | L3 IntDesc -> L4 Populate -> L5 Search -> L4 Detect |

---

**版本历史**：
- v2.0 (2026-04-28) - 对齐域柱卡v2统一模板，增加三层裁剪视图与依赖链更新
- v1.0 (2026-03-31) - 初始版本