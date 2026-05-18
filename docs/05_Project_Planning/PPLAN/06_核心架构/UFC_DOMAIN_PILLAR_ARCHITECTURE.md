# UFC 域柱架构设计 (Domain Pillar Architecture)

> 状态: CORE | 创建: 2026-04-26 | 版本: v3.0
> 关联: L3_MD_DESIGN_DECISIONS.md, L4_PH_DESIGN_DECISIONS.md, L5_RT_DESIGN_DECISIONS.md
> 关联: UFC_全局域依赖图.md, UFC_权威端到端数据流总图.md

---

## 一、核心洞察

### 1.1 计算核心三角

L3_MD、L4_PH、L5_RT 构成 UFC 有限元内核的**计算核心三角**，是一体设计的整体。

```
              L3_MD (定义)
             ╱   "是什么"    ╲
        Populate           WriteBack
           ↓                   ↑
     L4_PH (计算)    ←→    L5_RT (调度)
        "怎么算"    Compute    "何时做"
```

三层角色严格正交：

| 层 | 核心产出 | 四型偏好 | 类比 | ABAQUS 对应 |
|----|---------|---------|------|-----------|
| L3_MD | **数据定义** | Desc 主导 | 数据库 Schema | Model Data (inp 解析后) |
| L4_PH | **物理计算** | Algo 主导 | 算法引擎 | Element/Material Kernel |
| L5_RT | **运行调度** | Ctx/State 主导 | 调度器 | Step/NR/Assembly Driver |

### 1.2 域柱概念 (Domain Pillar)

**域柱**是贯穿 L3/L4/L5 的**同一物理概念的垂直投影**。
同一物理概念（如"材料"）在三层各有明确角色分工，
形成一根**柱状结构**，通过 Bridge/Populate/WriteBack 纵向连接。

```
┌──────────────────────────────────────────────────────────┐
│             Domain Pillar: Material                      │
├──────────┬──────────────┬────────────────────────────────┤
│  L3_MD   │    L4_PH     │           L5_RT                │
│ "定义者"  │   "计算者"    │          "调度者"               │
├──────────┼──────────────┼────────────────────────────────┤
│ 材料参数  │  本构计算     │ 材料类型路由/分发              │
│ (E,ν,σ_y)│ (Ctan,σ更新) │ (mat_type → L4 族)           │
│          │              │                                │
│ Desc ✓   │ Desc(冷缓存) │ Desc -(委托L3)                │
│ State ✓  │ State ✓      │ State -(委托L4)               │
│ Algo -   │ Algo ✓(灵魂) │ Algo -(委托L4)                │
│ Ctx -    │ Ctx ✓(IP区)  │ Ctx ✓(路由上下文)              │
├──────────┴──────────────┴────────────────────────────────┤
│ 数据流: L3.Desc → Populate → L4 缓存 → L5 路由          │
│         → L4 Compute_Ctan → L5 WriteBack → L3.State     │
└──────────────────────────────────────────────────────────┘
```

---

## 二、域柱分类

### 2.1 三类域柱

| 类型 | 定义 | 数量 | 特征 |
|------|------|------|------|
| **贯通柱 (Full Pillar)** | 跨 L3/L4/L5 三层 | 6 | FEM 计算核心血管 |
| **半贯通柱 (Partial Pillar)** | 跨 2 层 | 8 | 辅助/特化功能 (含 H7 DiffPhys) |
| **层专属 (Layer-Only)** | 仅 1 层 | 8+ | 层内自治 |

### 2.2 贯通柱一览 (Full Pillar × 6)

| # | 域柱名称 | L3 目录 | L4 目录 | L5 目录 | 命名映射 |
|---|---------|---------|---------|---------|---------|
| P1 | **Material** | `Material/` | `Material/` | `Material/` | MD_Mat ↔ PH_Mat ↔ RT_Mat |
| P2 | **Element** | `Elem/` | `Element/` | `Element/` | MD_Elem ↔ PH_Elem ↔ RT_Elem |
| P3 | **Contact** | `Interaction/` | `Contact/` | `Contact/` | MD_Interaction ↔ PH_Contact ↔ RT_Contact |
| P4 | **LoadBC** | `Boundary/` | `LoadBC/` | `LoadBC/` | MD_Boundary ↔ PH_LoadBC ↔ RT_LoadBC |
| P5 | **Output** | `Output/` | `Bridge/Output/` | `Output/` | MD_Output ↔ PH(bridge) ↔ RT_Output |
| P6 | **WriteBack** | `WriteBack/` | `Bridge/WriteBack/` | `WriteBack/` | MD_WB ↔ PH(bridge) ↔ RT_WB |

### 2.3 半贯通柱一览 (Partial Pillar × 7 + 基础设施域 × 1)

> v2.1 更新: H6 Coupling 从 Proto-Partial 升级为正式半贯通柱

| # | 域柱名称 | 涉及层 | 缺席层及融入点 | AUTHORITY 模块 |
|---|---------|--------|-------------|--------------|
| H1 | **Constraint** | L3 + L4 | L5: 融入 `RT_Asm_ApplyL3Constraints` | L3 `MD_Constraint_Def`, L4 `PH_Constraint_Def` |
| H2 | **Field** | L3 + L4 | L5: 分散于 Output/WriteBack/Assembly | L3 `MD_Field_Def`, L4 `PH_Field_Def` |
| H3 | **Assembly** | L3 + L5 | L4: 各域提供 Ke/Fe/Ce | L3 `MD_Assembly_Def`, L5 `RT_Asm_Def` |
| H4a | **Step** | L3 + L5 | L4: 步非物理计算概念 | L3 `MD_Step`, L5 `RT_StepDriver_Def` |
| H4b | **Solver** | L3 + L5 | L4: 求解器非单元级概念 | L3 `MD_Solv_Def`, L5 `RT_Solv_Def` |
| H4c | **Amplitude** | L3 only | L4/L5: 经 AmpFactor 消费 | L3 `MD_Amplitude_Def` |
| **H6** | **Coupling** | **L3 + L5** | **L4: 各域提供耦合贡献 (无独立目录)** | **L3 `MD_Cpl_Def`, L5 `RT_MF_Def`** |
| **H7** | **DiffPhys** | **L2 + L4** | **L3: theta 设计变量 (DEFERRED); L5: 无** | **L2 `NM_AIAdjointAlgo`, L4 `PH_Elem_dRdTheta`** |
| ~~H5~~ | **Bridge** | 基础设施域 | 非域柱 — 跨层数据传递机制 | 见 `BRIDGE_INDEX.md` |

### 2.5 AI 架构定位 (v3.0 新增)

> AI 在 UFC 中不是单一域柱，而是**三个正交关注面**的组合。

| 关注面 | 类型 | 涉及层 | 说明 |
|--------|------|--------|------|
| **A: 推理基础设施** | Infrastructure | L1_IF | `IF_AI_*` 封装 ONNX Runtime，类比 `IF_Mem`/`IF_Log`。6 个推理插槽的公共引擎。 |
| **B: 域级 AI 增强** | Domain Enhancement | L2/L4/L5 | 6 个插槽嵌入各自宿主域，是可选增强路径，不独立成域。 |
| **C: 可微分/伴随** | Partial Pillar (H7) | L2 + L4 | 插槽 7 伴随求解 + L4 `dR/dtheta`，跨两层成半柱。 |

**六推理插槽归属**:

| 插槽 | 宿主域 | 层 | 模块 | 功能 |
|------|--------|---|------|------|
| 1 AI_StepCtr | Step (H4a) | L5_RT | `RT_AIStepCtrAlgo` | 自适应步长控制 |
| 2 AI_ConvPredict | Solver (H4b) | L5_RT | `RT_AIConvPredictAlgo` | 收敛预测/早退 |
| 3 AI_MatInteg | Material (P1) | L4_PH | `PH_AI_MatInteg` | 本构代理 |
| 4 AI_ContactLaw | Contact (P3) | L4_PH | `NM_AIContactLawAlgo` | 接触律代理 |
| 5 AI_Precond | NM Solver | L2_NM | `NM_AIPrecondAlgo` | AI 预条件器 |
| 6 AI_SparseSolver | NM Solver | L2_NM | `NM_AISparseSolverAlgo` | AI 稀疏求解 |

**训练侧 (插槽 7)**:

| 插槽 | 归属 | 层 | 模块 | 功能 |
|------|------|---|------|------|
| 7 AI_AdjointSolver | DiffPhys (H7) | L2_NM | `NM_AIAdjointAlgo` | 离散伴随: Kᵀ·lambda = dJ/du |

**设计原则** (与总纲 §0.4 / §11 对齐):
1. 推理归 L1，训练不入核: `IF_AI_Runtime` 封装 ONNX，训练环在 L6_AP 或外部
2. 插槽归宿主域: 每个插槽是其宿主域的可选增强，不是独立域
3. 可微分独立成半柱: `dR/dtheta` + 伴随求解跨 L2/L4
4. 默认关闭: 所有 AI 增强默认 `.FALSE.` / `NULL()` procedure pointer
5. 三档渐进: 有限差分 → 手写切线/伴随 → AD 工具链 (Tapenade)
6. 单向依赖: AI/可微模块不得反向 USE L5_RT

### 2.4 层专属域 (Layer-Only)

> 注: StepDriver 和 Solver 在 v2.0 中升级为 H4a/H4b 半贯通柱（因 L3 也有对应 Step/Solver 定义域）。

| ID | 层 | 专属域 | AUTHORITY 模块 | 四型裁剪 | 诊断状态 (v2.1) |
|----|---|---------|--------------------|---------|----------------|
| S1 | L3 | **KeyWord** | `MD_KeyWord_Def` (四型齐全) | Desc+State+Algo+Ctx | CONTRACT v2.1 对齐 |
| S2 | L3 | **Model** | `MD_Model_Def` (Desc+State) | Desc+State; Algo/Ctx = N/A | 文件/模块名对调已标注 |
| S3 | L3 | **Part** | `MD_Part_Def` (Desc+State) | Desc+State; Algo/Ctx = N/A | CONTRACT v2.1 对齐 |
| S4 | L3 | **Section** | `MD_Sect_Def` (四型齐全) | Desc+State+Algo+Ctx | 精度修复 + CONTRACT v2.1 |
| S5 | L3 | **Mesh** | `MD_Mesh_Def` (Desc+State) | Desc+State; 子域 Element 是 P2 全柱 | 8 处 end module 修复; 双 MD_Elem_Def 解决 |
| S6 | L5 | **Logging** | `RT_Logging_Def` (Desc+State+Ctx) | Desc+State+Ctx; Algo = N/A | CONTRACT v2.1 对齐 |
| S7 | — | **Bridge** | 无四型 (基础设施域) | 跨层数据传递机制 | 文件计数 6+13 修正 |

---

## 三、域柱命名对齐 (方案 A: 逻辑对齐)

### 3.1 策略选择

**选定: 方案 A（保守渐进）** -- 不改现有代码命名，通过本文档建立权威映射表。

理由：
1. L3 使用 ABAQUS 输入模型术语（Interaction, Boundary）有其语义合理性
2. L4/L5 使用工程计算术语（Contact, LoadBC）面向内部实现
3. 改名的工程量和风险与收益不成比例
4. 保持代码稳定性，渐进式优化

### 3.2 权威命名映射表

| 域柱统一名 | L3_MD 前缀/目录 | L4_PH 前缀/目录 | L5_RT 前缀/目录 | 映射说明 |
|-----------|----------------|----------------|----------------|---------|
| **Material** | `MD_Mat_*` / `MD_Material_*` | `PH_Mat_*` / `PH_Mat_*` | `RT_Mat_*` | 完全对齐 |
| **Element** | `MD_Elem_*` (在 `Elem/`) | `PH_Elem_*` | `RT_Elem_*` | L3 嵌套在 Mesh 下 |
| **Contact** | `MD_Interaction_*` (目录: `Interaction/`) | `PH_Contact_*` / `PH_Cont_*` | `RT_Contact_*` / `RT_Cont_*` | **L3≠L4/L5**：Interaction vs Contact |
| **LoadBC** | `MD_Boundary_*` / `MD_LBC_*` (目录: `Boundary/`) | `PH_LoadBC_*` / `PH_BC_*` / `PH_Load_*` | `RT_LoadBC_*` / `RT_Ldbc_*` | **L3≠L4/L5**：Boundary vs LoadBC |
| **Output** | `MD_Output_*` / `MD_Out_*` | `PH_Out_*` (在 `Bridge/Output/`) | `RT_Output_*` / `RT_Out_*` | L4 挂在 Bridge 下 |
| **WriteBack** | `MD_WriteBack_*` / `MD_WB_*` | `PH_WB_*` (在 `Bridge/WriteBack/`) | `RT_WB_*` / `RT_WriteBack_*` | L4 挂在 Bridge 下 |
| **Constraint** (H1) | `MD_Constraint_*` | `PH_Constraint_*` | -(融入 RT_Asm/RT_Solv) | L5 无独立域 |
| **Field** (H2) | `MD_Field_*` | `PH_Field_*` | -(无) | L5 无独立域 |
| **Assembly** (H3) | `MD_Assem_*` / `MD_Assembly_*` | -(无) | `RT_Asm_*` | L4 无独立域 |
| **Step** (H4a) | `MD_Step_*` (在 `Analysis/Step/`) | -(无) | `RT_Step_*` / `RT_StepDriver_*` | L4 无独立域 |
| **Solver** (H4b) | `MD_Solver_*` (在 `Analysis/Solver/`) | -(无) | `RT_Solv_*` | L4 无独立域 |
| **Coupling** (H6) | **`MD_Cpl_*`** TYPE + **`MD_Cpl_*_Proc`**（在 `Analysis/Coupling/`） | -(无) | `RT_MF_*` (在 `Solver/Coupling/`) | **L3≠L5**: Coupling vs MF; L4 无独立域 |
| **DiffPhys** (H7) | -(DEFERRED) | `PH_Elem_dRdTheta_*` (在 `Element/`) | -(无) | L2 `NM_AIAdjoint*` (在 `Solver/AI/`) |
| **AI Infra** (基础设施) | -(无) | -(无) | -(无) | L1 `IF_AI_*` (在 `Base/AI/`)，横切所有层 |

### 3.3 不对齐项的语义解释

| 不对齐 | 原因 | 决定 |
|--------|------|------|
| L3 `Interaction` vs L4/L5 `Contact` | L3 面向 ABAQUS INP 语义（*CONTACT PAIR 属于 *INTERACTION）；L4/L5 面向计算内核的"接触力学"概念 | 保留差异，本文档为桥梁 |
| L3 `Boundary` vs L4/L5 `LoadBC` | L3 面向 INP 语义（*BOUNDARY, *CLOAD, *DLOAD）；L4/L5 用工程术语（Load & Boundary Conditions） | 保留差异，本文档为桥梁 |
| L3 `Elem/` vs L4/L5 `Element/` | L3 中 Element 是 Mesh 子域（网格→单元类型定义）；L4/L5 中 Element 独立为域（物理计算/调度） | 保留差异，层级语义不同 |

---

## 四、域柱四型裁剪跨层矩阵

### 4.1 每根域柱在三层的四型配置

```
✓ = 保留 (域内定义且使用)
△ = 委托 (引用其他层的定义)
- = 裁剪 (本层不需要)
```

| 域柱 | L3 Desc | L3 State | L3 Algo | L3 Ctx | L4 Desc | L4 State | L4 Algo | L4 Ctx | L5 Desc | L5 State | L5 Algo | L5 Ctx |
|------|---------|----------|---------|--------|---------|----------|---------|--------|---------|----------|---------|--------|
| **Material** | ✓ | ✓ | - | - | △L3 | ✓ | ✓ | ✓ | △L3 | △L4 | △L4 | ✓(路由) |
| **Element** | ✓ | ✓ | ✓ | - | △L3 | ✓ | ✓ | ✓ | ✓ | ✓ | - | ✓ |
| **Contact** | ✓ | - | - | - | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **LoadBC** | ✓ | - | - | - | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Output** | ✓ | - | - | - | -(bridge) | -(bridge) | - | - | ✓ | ✓ | - | ✓ |
| **WriteBack** | - | ✓ | - | ✓ | -(bridge) | -(bridge) | - | - | ✓ | ✓ | - | - |
| **Coupling** (H6) | ✓ | ✓ | ✓ | ✓ | -(分散) | -(分散) | -(分散) | -(分散) | ✓ | ✓ | ✓ | ✓ |

### 4.2 四型跨层角色变化规律

| 四型 | L3 角色 | L4 角色 | L5 角色 |
|------|--------|--------|--------|
| **Desc** | **核心产出** (SSOT，一次写入) | 冷缓存 (Populate 注入) | 配置参数 (步/求解器) |
| **State** | 辅助追踪 (冻结后只读) | **核心产出** (stress/SDV/应变) | **核心产出** (步/增量/迭代状态) |
| **Algo** | 不常用 (数据层少算法) | **灵魂** (本构/单元算法) | 控制策略 (NR/步切割/收敛) |
| **Ctx** | 不常用 (L3 少运行时) | **灵魂** (IP 工作区) | **灵魂** (运行时上下文) |

**规律**：Desc 从 L3→L5 逐渐"降温"；State 从 L3→L5 逐渐"升温"；Algo 和 Ctx 在 L4/L5 成为主角。

---

## 五、域柱合同 (Pillar Contract)

每根贯通柱的跨层数据流协议。

### P1: Material 域柱合同 (v2.0)

```
                L3_MD                  L4_PH                  L5_RT
           ┌────────────┐        ┌────────────┐        ┌────────────┐
           │MD_Mat_Desc │──Populate──→│PH_Mat_Params│        │RT_Mat_     │
           │  E, ν, σ_y │        │  + 族算法   │←─路由──│ Dispatch_  │
           │  (SSOT)    │        │  Compute_   │        │ Table      │
           │            │        │  Ctan(σ,ε)  │        │ + Ctx      │
           │MD_Mat_State│←──WriteBack──│PH_Mat_State│        │(mat_type   │
           │  σ,ε hist  │        │  σ_new, SDV │        │ →L4族)     │
           └────────────┘        └────────────┘        └────────────┘
```

| 阶段 | 方向 | 数据 | 载体 |
|------|------|------|------|
| Populate | L3 → L4 | 材料参数 (E, ν, σ_y, 硬化表) | `PH_L4_Populate_Material` |
| Table Build | L4 → L5 | mat_type + slot_idx | `RT_Mat_Brg_BuildTable` |
| Hot Path | L5 → L4 | mat_type 路由 + IP 上下文 | `RT_Mat_Dispatch_Ctx` → `PH_Mat_Update_Stress` |
| WriteBack | L5 → L3 | 更新后应力/SDV | `RT_WBDomain` → `RT_Mat_Brg_WriteBackHook` → L3 |

**MAT_* 族 ID 对齐 (v4.1)**:
- Authority (SSOT): `MD_Mat_BaseDef` (L3, 原 `Base/MD_Mat_Def.f90`, 值 101-1102)
- Mirror: `PH_MatReg` (L4, 编译独立镜像，值相同)
- Consumer: `RT_Mat_Dispatch_Table` (L5, 不透明整数，由 Bridge 填入)

**L3 类型统一 (v4.1)**:
- 简单类型 (`MD_Mat_Desc`, `MD_Mat_Ctx`): `MODULE MD_Mat_BaseDef` (原 Base/MD_Mat_Def.f90)
- 富类型 (`MD_Mat_Desc EXTENDS DescBase`, `MD_MatState`): `MODULE MD_Mat_Def` (Contract/)

**UMAT/VUMAT 路由**: L5 `RT_Mat_Dispatch_Ctx.is_user_sub` 标记 → L4 `PH_Mat_Reg_Get(MAT_USER_UMAT)` → `PH_UserSub_UMAT`

### P2: Element 域柱合同 (v2.0)

```
                L3_MD                  L4_PH                  L5_RT
           ┌────────────┐        ┌────────────┐        ┌────────────┐
           │MD_Elem_Desc│─Populate─→│PH_Elem_    │        │RT_Elem_    │
           │MD_Elem_Reg │        │ Base_Desc  │←─路由──│ Dispatcher │
           │(FAMILY_*,  │        │ Compute_Ke │        │ + Dispatch │
           │ ELEM_*)    │        │ Compute_Fe │        │ Table      │
           │            │        │            │        │ + WB_Brg   │
           │MD_FieldState│←WriteBack│PH_Elem_State│       │            │
           │  u, react  │        │ Ke,Fe,re   │        │RT_Elem_Def │
           └────────────┘        └────────────┘        └────────────┘
```

| 阶段 | 方向 | 数据 | 载体 |
|------|------|------|------|
| Populate | L3 → L4 | 节点坐标/连接/截面 | `MD_ElemPopulate` → `PH_L4Populate` |
| Table Build | L4 → L5 | family_id + kernel proc | `RT_ElemDispatcher.Register` |
| Hot Path | L5 → L4 | 单元循环: family_id 路由 | `RT_ElemDispatcher` → `PH_ElemCalcWrapper` |
| WriteBack | L5 → L3 | 应力/SDV/能量 | `RT_ElemWB_Brg.Filter` → `RT_WBDomain` |

**单元类型 ID 两级体系 (v2.0)**:
- 细粒度 `ELEM_*` / `PH_ELEM_*`: L3 `MD_Elem_Reg` = AUTHORITY, L4 `MD_Elem` = 扩展
- 族级 `PH_ELEM_FAMILY_*`: L4 `PH_ElemReg` = AUTHORITY (1-12)
- L5 不持有常量: 通过 `RT_Elem_Dispatch_Table` 间接消费

**L5 TYPE 统一 (v2.0)**:
- 权威定义: `RT_Elem_Def` (四型 + Dispatch Table)
- LEGACY wrapper: `RT_Element_Def` (re-exports, 向后兼容)
- 所有消费方统一 USE `RT_Elem_Def`

**L4 重复文件**: `PH_ElemShapeFunc.f90` 存在于 `Element/` 和 `Element/Shared/` 两处。
Root 版本 (SIO-refactored) 为首选; Shared 版本标记 LEGACY。

**Bridge 链**:
- L3→L4: `MD_ElemPopulate` + `MD_ElemPHElemBinding`
- L4→L5: `PH_ElemRT_Brg` (NL geom) + `PH_ElemOrientRT_Brg`
- L5→L4: `RT_ElemDispatch_Brg` (Ke/Fe/Me/Ce)
- L5→L3: `RT_ElemWB_Brg` (WriteBack NaN/energy hook)

### P3: Contact 域柱合同 (v2.0)

```
                L3_MD                  L4_PH                  L5_RT
           ┌────────────┐        ┌────────────┐        ┌────────────┐
           │MD_Interaction│─Populate─→│PH_Contact_ │        │RT_Contact_ │
           │  pair defs  │        │ Domain     │←─调度──│ Desc/State │
           │  surf refs  │        │ Penalty/   │        │ Search →   │
           │             │        │ Friction   │        │ Evaluate   │
           │             │        │ Gap calc   │        │ Assemble   │
           └─────────────┘        └────────────┘        └────────────┘
```

| 阶段 | 方向 | 数据 | 载体 |
|------|------|------|------|
| Populate | L3 → L4 | 接触对定义/表面引用 | `MD_Cont_PH_FillParams` |
| Hot Path | L5 → L4 | 搜索→穿透检测→接触力 | `RT_ContSolv` → `PH_Cont_*` |
| Assembly | L5 | 接触贡献装配到全局 K/F | `RT_Asm_ApplyContact` |
| WriteBack | L5 → diag | 接触状态摘要 | `RT_Contact_Brg_WriteBack` |

**L5 TYPE 统一 (v2.0)**:
- AUTHORITY: `RT_Cont_Def` (四型 Desc/Ctx/State/Algo + 常量 + bound procedures)
- LEGACY wrapper: `RT_Contact_Def` (re-exports Desc/State/Algo/Ctx)
- GOLD-LINE: `RT_ContSolv` (生产接触求解器 SIO 门面)

**L4 TYPE AUTHORITY (v2.0)**:
- AUTHORITY: `PH_Cont_Def` (PH_Cont_Def.f90, deduplicated)
- LEGACY MIRROR: `PH_Contact_Def` (SKELETON)
- MODULE 重命名: `PH_ContSearchAdvanced.f90` 从 `RT_ContSearch` 改为 `PH_ContSearchAdv`

**摩擦枚举**: `PH_FRIC_*` (域级分类, PH_ContDomain) vs `PH_FRICT_*` (算法级, PH_ContFriction)

**Bridge 链**:
- L3→L4: `MD_ContPH_Brg` (FillParams)
- L3→L5: `RT_Contact_Brg_FromL3` + `MD_ContRT_Brg` / `MD_Int_Brg`
- L5→L4: `RT_ContSolv` → `PH_Cont_*` (golden line)
- L5→diag: `RT_Contact_Brg_WriteBack`

**悬挂引用修复**: `MD_Model_Brg.f90` 中 USE RT_ContactSurface/RT_ContactTypes 已注释 (DANGLING-REF v2.0)

**已知 L3 问题**: MD_Interaction_Desc 双头定义; MD_Int.f90 含接触力学计算 (越界)

### P4: LoadBC 域柱合同 (v2.0)

```
                L3_MD                  L4_PH                  L5_RT
           ┌────────────┐        ┌────────────┐        ┌────────────┐
           │MD_Boundary_ │─Populate─→│PH_LoadBC_  │        │RT_LBC_Def  │
           │  LoadDef    │        │ Domain     │←─调度──│ (四型统一)  │
           │  BCDef      │        │ PH_BC_Apply│        │            │
           │  Amplitude  │        │ PH_Ldbc    │        │RT_LoadBC_  │
           │ (L3-only svc)│       │ (AUTHORITY │        │ Brg        │
           │             │        │  PH_LOAD_*)│        │ (路由/诊断) │
           └─────────────┘        └────────────┘        └────────────┘
```

| 阶段 | 方向 | 数据 | 载体 |
|------|------|------|------|
| Populate | L3 → L4 | 载荷/BC 定义 + 幅值曲线 | `MD_LBCPH_Brg` |
| L3 → L5 | Populate | n_loads, n_bcs, ndof_global | `RT_LoadBC_Brg_FromL3` |
| Hot Path | L5 → L4 | BC 应用到全局方程 | `RT_AsmSolv` → `PH_BC_Apply` |
| Assembly | L5 | 载荷向量装配 | `RT_Asm_GlobalLoad` |
| WriteBack | L5 → diag | 外力功/反力汇总（诊断，不改 L3 Desc） | `RT_LoadBC_Brg_WriteBack` |

**L5 TYPE 统一 (v2.0)**:
- AUTHORITY: `RT_LBC_Def` (四型 Desc/Ctx/State/Algo + 分析类型常量 + 生命周期过程)
- LEGACY wrapper: `RT_LoadBC_Def` (re-exports Desc/State/Ctx)
- 消费方统一 `USE RT_LBC_Def`

**L4 枚举对齐 (v2.0)**:
- AUTHORITY: `PH_Ldbc` 内 `PH_LOAD_*` (1-8) 与 `PH_BC_ELIMINATION/PENALTY/LAGRANGE`
- LEGACY MIRROR: `PH_LoadBC_Def` 内 `LOAD_*` (1-6), `PH_Load_Def` 内 `LOAD_TYPE_*` (1-6)

**Amplitude 域**: L3-only 服务 (`L3_MD/Analysis/Amplitude/`)，L4 经 `PH_Brg_GetAmplitudeValue_Idx` 消费，L5 不直读。

**约束子域**: `Tie/MPC/Coupling/RigidBody` 在 L5/LoadBC 标记为 SKELETON；待 L4 Constraint 域成熟后补全。

**Bridge 链**:
- L3→L4: `MD_LBCPH_Brg` (BuildStepLoads/BCs)
- L3→L5: `RT_LoadBC_Brg_FromL3` (Populate counts)
- L5→L4: routing via `RT_AsmSolv` golden line
- L5→diag: `RT_LoadBC_Brg_WriteBack` (post-converge diagnostics)

**Production Path Note**: `RT_AsmSolv` golden line directly uses L3 `MD_LBC` and L4 `PH_LoadBC_Domain`, bypassing `RT_LoadBC_Core` (LEGACY). Dangling `USE RT_Asm_LoadBC_Apply` in `RT_AsmGlobal.f90` has been commented out.

### P5: Output 域柱合同 (v2.0)

| 阶段 | 方向 | 数据 | 载体 |
|------|------|------|------|
| Config | L3 → L5 | 输出频率/变量列表/文件路径 | `MD_Output_Desc` (L3 AUTHORITY) |
| Transform | L5 → L4 | 坐标/张量变换参数 | `PH_Out` / `PH_Out_Brg` (L4 AUTHORITY) |
| Orchestrate | L5 内部 | 帧构建/频率检查/格式分发 | `RT_Out.f90` (Golden Path) |
| Write | L5 → 持久化 | 场变量/历程变量 | `RT_Out` → ODB/HDF5/VTK |

**L5 TYPE 统一 (v2.0)**:
- AUTHORITY: `RT_Out_Def.f90` — 丰富四型 (RT_Out_Base_Desc, RT_Out_FieldState, RT_Out_HistState, RT_Out, RT_Out_Ctx, RT_Out_Frame, RT_Out_Buffer, RT_Out_TriggerCtx)
- LEGACY: `RT_Output_Def.f90` — 最简三型 (RT_Output_Desc, RT_Output_State, RT_Output_Ctx)，仅供 `RT_Output_Core` (LEGACY/FACADE) 使用

**Bridge 链**:
- L3→L5: `MD_Out_Brg` (BuildFieldOutTasks/BuildHistOutTasks)
- L5 Bridge: `RT_Output_Brg` (FromL3/ToL4/CollectResults) — v2.0 从 SKELETON 扩展为 ACTIVE
- L5→L4: `PH_Out_Brg` (TransformCoords/TransformTensor/InterpolateField)

**命名修正 (v2.0)**:
- L4 CONTRACT 原引用 `PH_Output_API` → 实际为 `PH_Out` / `PH_Out_Brg`
- L5 CONTRACT 原引用 `RT_Out_Core.f90` → 实际为 `RT_Out.f90` (Golden Path)
- L3 Bridge `MD_UniFldRT_Brg` 域标签从 Output 修正为 Material

### P6: WriteBack 域柱合同 (v2.0)

| 阶段 | 方向 | 数据 | 载体 |
|------|------|------|------|
| Commit | L5 → L4 → L3 | 收敛后位移/应力/SDV | `RT_WBDomain` → `PH_WB_Brg` → `MD_WB_Brg` |
| Checkpoint | L5 → 持久化 | 全模型快照 | `RT_Bridge_Domain` |
| Validate | L3 白名单 | 写回授权检查 | `MD_WBMgr` / `MD_WBDomain` |

**L5 TYPE 统一 (v2.0)**:
- AUTHORITY: `RT_WB_Def.f90` — 丰富四型 (RT_WB_Base_Desc, RT_WB_ProgressState, RT_WB_BufferState, RT_WB_Algo, RT_WB_Ctx, RT_WB_TransformCtx)
- LEGACY: `RT_WriteBack_Def.f90` — 最简二型 (RT_WB_Desc, RT_WB_State)，仅供 `RT_WriteBack_Core` (LEGACY/FACADE) 使用

**Bridge 链**:
- L5 Bridge: `RT_WriteBack_Brg` (FromL5/ToL4/ToL3) — v2.0 从 SKELETON 扩展为 ACTIVE
- L5→L4: `PH_WB_Brg` (ApplyNodeDisp/ApplyElemStress)
- L5→L3: `MD_WB_Brg` (白名单网关 + 域级写回)

**已修复 (v2.0)**:
- `RT_WBDomain.f90` 头部 GOLDEN-LINE / Draft 冲突已清理
- `PH_WB_Brg` header 原引用 `PH_WB_Algo` → 修正为 `PH_WB`
- L3/L4 CONTRACT 命名漂移已修正

---

## 5b、半贯通柱合同 (Partial Pillar Contracts, v2.0)

> 更新: 2026-04-26 | 涵盖 H1-H4c + 基础设施域 H5

### H1: Constraint 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3 + L4 半贯通柱 |
| L3 AUTHORITY | `MD_Constraint_Def.f90` (Desc/State) |
| L4 AUTHORITY | `PH_Constraint_Def.f90` (3-type: Desc/Algo/Ctx) |
| L4 ACTIVE | `PH_Constraint_Core.f90` (MPC/Tie/Penalty/Lagrange 算法) |
| L5 缺席 | 约束贡献融入 `RT_AsmSolv::RT_Asm_ApplyL3Constraints` |
| 数据流 | `MD_ConstraintUnion`(L3) → `PH_L4_Populate_Constraint` → `PH_Constraint_Ctx`(L4) → `RT_Asm_ApplyL3Constraints`(L5) |

### H2: Field 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3 + L4 半贯通柱 |
| L3 AUTHORITY | `MD_Field_Def.f90` (Desc/State/Ctx) |
| L4 AUTHORITY | `PH_Field_Def.f90` (Desc/Ctx) |
| L5 缺席 | 场变量操作分散在 Output/WriteBack/Assembly/StepDriver 域 |
| 语义区分 | Field = 物理自由度场 (位移/温度); Output Field = 结果选择 |

### H3: Assembly 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3 + L5 半贯通柱 |
| L3 AUTHORITY | `MD_Assembly_Def.f90` (Part Instance/DOF schema) |
| L5 AUTHORITY | `RT_Asm_Def.f90` (全局 K/F 装配四型) |
| L5 GOLDEN-LINE | `RT_AsmSolv.f90` |
| L4 缺席 | L4 各域 (Element/Material/Contact/LoadBC) 提供局部 Ke/Fe/Ce — Assembly 语义分散 |
| 双重语义 | L3 Assembly = Part Instance (几何)；L5 Assembly = Global Matrix Assembly (数值) |

### H4a: Step 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3 + L5 半贯通柱 |
| L3 AUTHORITY | `MD_Step.f90` (步定义 Desc/StepAlgo/MD_Step_Domain) |
| L3 补充 | `MD_Step_Def.f90` (State/Ctx) |
| L5 AUTHORITY | `RT_StepDriver_Def.f90` (三级状态机四型) |
| L5 GOLDEN-LINE | `RT_StepExec.f90` |
| L4 缺席 | 步是编排概念 (何时计算)，非物理计算 (怎么计算) |
| 三级状态机 | Step (`RT_STEP_*`) → Increment (`RT_INC_*`) → Iteration (`RT_ITER_*`) |

### H4b: Solver 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3 + L5 半贯通柱 |
| L3 AUTHORITY | `MD_Solv_Def.f90` (求解器配置 Desc/Algo) |
| L5 AUTHORITY | `RT_Solv_Def.f90` (运行时求解器类型) |
| L5 GOLDEN-LINE | `RT_Solv.f90` + `RT_SolvNonlin.f90` |
| L4 缺席 | 求解器是方程组级概念 (全局 K·x=F)，L4 提供单元级贡献 |
| 数据流 | `MD_Solver_Desc`(L3) → `MD_Solver_Brg_GetConfigForStep` → L5 `RT_SolverSys_*` |

### H4c: Amplitude 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3-only (准半柱 — L5 间接消费) |
| L3 AUTHORITY | `MD_Amp_Def.f90` (幅值曲线类型 + 标量求值核) |
| L4/L5 缺席 | 幅值非单元级计算; 经 `UF_AmpFactor` / `RT_StepDriver` 间接消费 |
| 标量核 | `MD_AmpShared_TabularEval`, `SmoothStep`, `RampUnit`, `Modulated` |

### H6: Coupling (MultiField) 半柱合同

| 属性 | 值 |
|------|-----|
| 类型 | L3 + L5 半贯通柱 |
| L3 AUTHORITY | `MD_Cpl_Def.f90` (耦合对定义 SSOT / 策略选择) |
| L3 Core | `MD_Cpl_Core.f90` (`MD_Cpl_*_Proc`: Init/AddPair/Validate/GetConfig/Finalize/GetSummary/GetPair) |
| L5 AUTHORITY | `RT_MF_Def.f90` (运行时耦合四型系统 — 6场/4策略/10交换量) |
| L5 GOLDEN-LINE | `RT_MFCoordinator.f90` (4种策略循环: ONEWAY/STAG/PARTITER/MONO) |
| L5 Bridge | `RT_MF_Brg.f90` (L3→L5 Populate 通道) |
| L4 缺席 | 耦合是编排概念; L4 各域 (Material/Element/Field) 提供耦合贡献项 |
| 双重语义 | 多场耦合 (`*COUPLED TEMPERATURE-DISPLACEMENT`) vs 运动学耦合约束 (`*COUPLING`, H1 Constraint) |
| 数据流 | `MD_Cpl_Desc`(L3) → `RT_MF_Brg_Populate` → `RT_MF_Coupling_Desc`(L5) → `RT_MFCoordinator_Run` |
| StepDriver 集成 | `RT_STEPDRV_SEQ_COUPLED` 枚举触发耦合循环 |
| 目录位置 | L3: `Analysis/Coupling/`; L5: `Solver/Coupling/` (历史位置, 非Solver子域) |

### H5 → 基础设施域: Bridge

Bridge **不再**视为半贯通柱，重新分类为**基础设施域**。

| 属性 | 值 |
|------|-----|
| 分类 | 基础设施域 — 与 L1_IF SymTbl/DP/MemPool 同级 |
| 职责 | 跨层数据格式转换, 域间数据路由, Legacy 适配 |
| 权威索引 | `L3_MD/Bridge/BRIDGE_INDEX.md` |
| 已知命名异常 | `MD_Mesh_Brg.f90` 文件名 `MD_` 但 MODULE 名 `RT_Mesh_Brg` (跨前缀，不做修改) |

---

## 六、跨柱交互 (Cross-Pillar Interactions)

域柱之间并非独立，存在明确的交叉引用：

```
Element ──needs──→ Material    (每个单元引用材料 → 本构计算)
Element ──needs──→ Section     (每个单元引用截面 → 几何属性)
Contact ──needs──→ Element     (接触面需要单元的面几何)
LoadBC  ──needs──→ Assembly    (载荷需要节点集/单元集/面集)
Output  ──needs──→ Element     (场输出需要单元/节点数据)
WriteBack ─needs─→ Element     (回写需要 FieldState)
Coupling ─needs─→ Element     (耦合界面需要单元面几何 + 场求解器)
Coupling ─needs─→ StepDriver  (耦合循环嵌入增量步编排)
```

在 L5 运行时，这些交互通过 **Assembly 编排** 统一协调：

```
RT_StepExec (L5 金线)
  └─ RT_AsmSolv (Assembly 编排)
       ├─ Element loop   → PH_Elem_Compute_Ke  (L4 Element 域柱)
       │    └─ per IP    → PH_Mat_Compute_Ctan  (L4 Material 域柱)
       ├─ LoadBC apply   → PH_LoadBC            (L4 LoadBC 域柱)
       ├─ Contact apply  → PH_Cont_*            (L4 Contact 域柱)
       ├─ Constraint     → PH_Constraint        (L4 Constraint 半柱)
       └─ Field          → PH_Field             (L4 Field 半柱)
```

---

## 七、域柱与生命周期的关系

每根域柱在三层的生命周期阶段门互联：

```
L3 生命周期:  UNINIT → INIT → POPULATING → FROZEN
                                    ↓ (Populate)
L4 生命周期:  UNINIT → INIT → POPULATED → READY → COMPUTING → CONVERGED
                                    ↓ (调度)
L5 生命周期:  UNINIT → INIT → STEP_BEGIN → ASSEMBLING → SOLVING → CONVERGED → OUTPUT → STEP_END
```

**阶段门对齐**：
- L3 FROZEN 后，L4 才可 Populate
- L4 POPULATED → READY 后，L5 才可开始 ASSEMBLING
- L5 CONVERGED 后，才触发 WriteBack (L5 → L3) 和 Output (L5 → 持久化)

---

## 八、设计原则总结

### 8.1 域柱设计五原则

| # | 原则 | 说明 |
|---|------|------|
| 1 | **垂直正交** | 同一域柱内三层角色严格正交：定义/计算/调度 |
| 2 | **单向数据流** | Populate 下行 (L3→L4)，WriteBack 上行 (L5→L3)，无环 |
| 3 | **四型裁剪** | 每层根据角色保留必要的四型，不强制全覆盖 |
| 4 | **委托优先** | L5 不重复 L3 的 Desc，通过引用/委托获取 |
| 5 | **Bridge 为胶** | 跨层数据传递必须经过 Bridge 模块，禁止直接 `USE` 跨层内部 TYPE |

### 8.2 合规检查清单

新增域柱功能时：

- [ ] 确认域柱类型（贯通 / 半贯通 / 层专属）
- [ ] L3 侧是否有 Desc 定义 (SSOT)
- [ ] L4 侧是否有 Populate 入口 + 算法 Kernel
- [ ] L5 侧是否有调度路由 + WriteBack 出口
- [ ] Bridge 模块是否已建立跨层连接
- [ ] 四型裁剪是否遵循跨层矩阵 (§4.1)
- [ ] 命名是否已在映射表 (§3.2) 中登记
- [ ] 生命周期阶段门是否对齐 (§7)

---

## 附录 A: 域柱合同模板

```markdown
# Pillar Contract: {域柱名}

## 基本信息
- 域柱类型: 贯通 / 半贯通
- L3 目录: L3_MD/{dir}/
- L4 目录: L4_PH/{dir}/
- L5 目录: L5_RT/{dir}/

## 四型配置
| 层 | Desc | State | Algo | Ctx |
|----|------|-------|------|-----|
| L3 |      |       |      |     |
| L4 |      |       |      |     |
| L5 |      |       |      |     |

## 数据流
1. Populate (L3→L4): {描述}
2. Hot Path (L5→L4): {描述}
3. WriteBack (L5→L3): {描述}

## Bridge 模块
- L3→L4: {模块名}
- L4→L5: {模块名}
- L5→L3: {模块名}

## 共享枚举/常量
- {列举跨层共用的枚举}
```

---

## 附录 B: 从旧文档到域柱的映射

| 旧文档 | 域柱视角 |
|--------|---------|
| L3_MD_DESIGN_DECISIONS.md | 所有域柱的 L3 侧设计 |
| L4_PH_DESIGN_DECISIONS.md | 所有域柱的 L4 侧设计 |
| L5_RT_DESIGN_DECISIONS.md | 所有域柱的 L5 侧设计 |
| UFC_端到端数据流图.md | 域柱间的水平数据流 |
| UFC_全局域依赖图.md | 域柱间的依赖边 |
| 各域 CONTRACT.md | 单层单域的合同 → 应升级为域柱合同的一部分 |

---

## 附录 C: 变更记录

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-04-26 | 初版：6 全柱 + 7 半柱 + 层专属一览 |
| v2.0 | 2026-04-26 | 新增 H6 Coupling 半柱；Bridge 降级为基础设施域 |
| v2.1 | 2026-04-26 | 层专属域全景诊断: S1-S7 AUTHORITY 标注/CONTRACT 对齐/语法修复 |
| v3.0 | 2026-04-26 | AI 架构三关注面定位: 基础设施 + 域级增强(6插槽) + H7 DiffPhys 半柱; 命名映射新增 AI 行 |
