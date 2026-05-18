# UFC 后分析类型扩充 — 架构完善总章程 v1.0

> **文档位置**: `docs/05_Project_Planning/PPLAN/06_核心架构/`  
> **创建日期**: 2026-04-04  
> **版本**: v1.0（Post-AnalysisType-Expansion 架构补齐规划）  
> **上位文档**: [UFC_架构设计总纲_深度整合版_v5.0.md](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)、[域级划分规范](../../六层架构拆分/00-总纲/00-域级划分规范.md)  
> **核心论题**: 分析类型正交设计扩充后，旧架构是否完善 + L3/L4/L5 域级联合体系补全  
> **阅读对象**: 架构师、核心开发者、整体系统设计参与者

---

## 📋 文档元数据

| 属性 | 值 |
|------|-----|
| **文档用途** | 架构完善规划 + 执行路线图 + 验收清单 |
| **主要问题** | 分析类型(AnalysisType_Group)扩充后，六层架构是否已完全适配？L3/L4/L5 域级架构是否拆分清晰？ |
| **核心输出** | 5 大改造阶段 + 22 个具体域级完善任务 + 跨层联通契约验收清单 |
| **预期工时** | 第 1-2 阶段：2-3 周；第 3-5 阶段：4-6 周（共 2 个月） |
| **风险评估** | 中等（涉及 L3-L4-L5 跨层重构，需严控单向依赖） |
| **版本演进** | v1.0 → v1.1（初稿后修订） → v2.0（全量实施完成） |

---

## 🎯 零、现状分析与核心诊断

### 0.1 分析类型扩充带来的新约束

**之前（v5.0 架构总纲）**：
```
L3_MD ← 模型层（材料/单元/网格）
  └─ PROC_* 枚举定义分析步类型（1-91 个，ABAQUS对标）
  └─ 仅支持 1-based 编号

L4_PH ← 物理层（单元/材料/接触）
  └─ 硬编码关键：SOLVER × COUPLING × PHYSICS
  └─ 缺乏正交维度的显式管理

L5_RT ← 运行时层（求解器调度）
  └─ RT_SolverType 枚举已定义（8 类）
  └─ 但与 PROC_* 映射逻辑分散
```

**现在（Post-AnalysisType-Expansion）**：
```
L3_MD ← 新增 Analysis_Group 域
  ├─ MD_Analysis_Group_DESC TYPE（包含三维正交坐标）
  ├─ PROC_ID ↔ (Solver, Coupling, Physics) 双向映射
  ├─ 1-based 对外 API + 0-based 对内实现
  ├─ 约束矩阵(0:4, 0:3, 0:11) = 50 个有效坐标
  └─ 多求解器标记(requires_auxiliary_solver)

L4_PH ← 新增 Analysis_Router 模块
  ├─ route_analysis_group() 验证组合合法性
  ├─ check_auxiliary_solver_requirement() 多求解器识别
  ├─ enable_processor_by_solver() 处理器启用分发
  └─ L3 MD_Analysis_Group_DESC 解析与路由

L5_RT ← 现有 RT_SolverType 需升级
  ├─ 应对标 L3_MD Analysis_Group（五维标准化）
  ├─ 补全 PROC_* → (Solver, Coupling, Physics) 完整映射
  ├─ 实现求解器路由工厂(RT_Analysis_Factory)
  └─ 多场耦合协调器(RT_MF_Coordinator)
```

### 0.2 尚未完善的层级-域级体系

**当前 L3_MD 域级覆盖情况**（源于 `00-域级划分规范.md`）：
```
✅ 已实施域级（完整或部分）：
  - Analysis ← NEW: 新增 Analysis_Group (60%完成)
  - Assembly ← 装配定义 (50%)
  - Boundary ← 边界/载荷 (70%)
  - Material ← 材料库 (70%)
  - Mesh ← 网格管理 (80%)
  - Model ← 模型容器 (60%)
  - Output ← 输出管理 (50%)
  - KeyWord ← 关键字解析 (40%)
  
⚠️   不完整或缺陷域级：
  - Bridge ← L3↔L4/L5 桥接（职责混乱，需清理）
  - Constraint ← 约束定义（缺乏完整TYPE系统）
  - Field ← 场变量（仅框架）
  - Interaction ← 相互作用（接触、摩擦等，仅框架）
  - Section ← 截面定义（缺乏通用展开）
  - WriteBack ← 回写管理（对标不清）
  - Part ← 部件定义（缺乏组织原则）

❌ 完全缺失域级（待规划）：
  - StepDriver ← 分析步驱动（属 L5，现在 L3 缺）
```

**当前 L4_PH 域级覆盖情况**：
```
✅ 已实施域级：
  - Element ← 单元计算 (70%)
  - Material ← 材料本构 (60%)
  - LoadBC ← 载荷边界条件 (50%)
  
⚠️  不完整：
  - Contact ← 接触算法（缺乏完整TYPE + 路由）
  - Constraint ← 约束施加（与 L3 重复定义）
  - Output ← 字段提取（缺乏类型系统）
  - WriteBack ← 状态回写（缺乏完整规范）
  - Field ← 字段定义（仅框架）
  
❌ 完全缺失：
  - (无) — 主要域级已覆盖，缺的是完整性
```

**当前 L5_RT 域级覆盖情况**：
```
✅ 已实施域级：
  - Solver ← 线性/非线性求解 (40%)
  - Material ← 材料计算驱动 (30%)
  - Element ← 单元计算调度 (20%)
  
⚠️  不完整或缺乏清晰设计：
  - Assembly ← 全局组装 (30%)
  - Contact ← 接触力计算 (20%)
  - LoadBC ← 载荷施加 (20%)
  - Output ← 字段输出控制 (20%)
  - StepDriver ← 分析步驱动（层次不清）
  - Coupling ← 多场耦合协调（仅 stub）
  
❌ 完全缺失或 AI-ready 专属：
  - (AI插槽 ① ② ③ ④ ⑤ ⑥ ⑦ 对应的运行时基础设施)
```

### 0.3 架构完善的三个关键缺口

**缺口 1：L3_MD Analysis_Group 与 L4_PH/L5_RT 的打通**
- ❌ L3 MD_Analysis_Group_DESC 的约束矩阵与 L5 RT_SolverType 的映射**尚未闭环**
- ❌ L4 route_analysis_group() 的输出（active_solvers, auxiliary_solver_id）**未被 L5 消费**
- ❌ 多求解器耦合路由（如 FSI）的 L5_RT::RT_MF_Coordinator **完全缺失**

**缺口 2：四类型(Desc/State/Algo/Ctx) 的不规范落地**
- ⚠️  L3_MD 各域级缺乏统一的四型拆分规范
  - Material/Element/Mesh 混杂 Desc + Algo
  - State 定义分散，缺乏统一的回写契约
- ⚠️  L4_PH 热路径设计与四型的映射**不明确**
  - 哪些 Algo 应进热路径？Ctx 如何零 ALLOCATE？
- ⚠️  L5_RT 的 Algo/Ctx 设计**缺乏规范**
  - RT_StepDriver 中 Algo 配置与 Ctx 绑定关系不清

**缺口 3：跨层 Bridge 与契约的混乱**
- 🔴 **两套并行桥接**
  - L3 侧：MD_MatLib_PH_Brg、MD_Elem_PH_Brg、MD_Geom_PH_Brg（主动推）
  - L4 侧：UF_Brg_L4_TO_L3_MD（主动拉）
  - 职责重叠，验证规则不一致
- 🔴 **L4 与 L5 的桥接**
  - RT_Asm_GlobalStiffness 直接调 PH_Element_Compute_Ke（未经 Bridge）
  - 数据接口契约不明确（特别是多材料点、材料分发）
- 🔴 **L3 与 L5 的桥接**
  - RT_WriteBack 写回 L3_MD 状态时，无对应的**验收规则**
  - WB_TARGET 白名单管理分散

---

## 🏗️ 一、五大改造阶段规划

### 阶段 I：L3_MD Analysis_Group 域完善（当前 60% → 100%）
**目标**: 使 Analysis 域成为 PROC_ID 与三维坐标的权威枢纽  
**工期**: 1.5 周

| 任务编号 | 任务名称 | 输出 | 验收标准 |
|----------|---------|------|---------|
| **I-01** | 补全 PROC_ID 映射表(1-91) | MD_Analysis_Group_Module.f90 扩充至 91 个PROC | 100% PROC 有映射；gfortran -std=f2003 无错 |
| **I-02** | 设计多求解器标记体系 | MD_Analysis_Auxiliary_Solver_Type | 定义 FSI/THM/EMF 的多求解器需求枚举 |
| **I-03** | 实现 1-based ↔ 0-based 转换工厂 | MD_Analysis_Group_Factory_Proc | 双向转换函数 + 单元测试 |
| **I-04** | 约束矩阵缓存层 | MD_Analysis_Compatibility_Cache | 矩阵预计算 + 运行时快速查询 |
| **I-05** | 编写 Analysis 域完整设计文档 | 150 行文档，含类型系统 + 算法说明 + 使用示例 | 文档审查通过 |

### 阶段 II：L4_PH Analysis_Router 与 Analysis 域联动（40% → 100%）
**目标**: 使 L4_PH 成为验证与路由的执行层  
**工期**: 1 周

| 任务编号 | 任务名称 | 输出 | 验收标准 |
|----------|---------|------|---------|
| **II-01** | 补全 route_analysis_group() 实现 | L4_PH_Analysis_Router_Module.f90 扩充 | 支持所有 50 个有效坐标组合 |
| **II-02** | 实现多求解器启用分发 | PH_Processor_Enable_Dispatch() | 激活对应的 L4 子域（Material/Element/Contact） |
| **II-03** | L4 ↔ L3 约束矩阵验证接口 | PH_Route_ValidateGroupID() | 每次路由时调用，无额外性能开销 |
| **II-04** | 热路径隔离：Populate 时预填充 | PH_L4_Populate_Core.f90 扩充 | 分析类型相关的 C_tan/props 预算进 slot_pool |
| **II-05** | 编写 L4_PH Analysis 域设计文档 | 120 行文档 | 含实现框架 + 接口契约 + 案例 |

### 阶段 III：L5_RT 求解器路由与工厂完善（40% → 100%）
**目标**: 使 L5_RT 成为分析类型的最终调度枢纽，并支持多场耦合  
**工期**: 2 周

| 任务编号 | 任务名称 | 输出 | 验收标准 |
|----------|---------|------|---------|
| **III-01** | 升级 RT_SolverType → RT_AnalysisType（五维标准化） | RT_AnalysisType_v5.f90 | 与 L3 MD_Analysis_Group 对标；5×4×12 映射完整 |
| **III-02** | 实现求解器工厂(RT_Analysis_Factory) | RT_Analysis_Factory_Core.f90 | 根据 (Solver, Coupling, Physics) 创建对应求解器类 |
| **III-03** | 多场耦合协调器(RT_MF_Coordinator) | RT_MF_Coordinator_Core.f90 | 支持 FSI/THM/EMF 的多求解器协调 + 能量稳定性检查 |
| **III-04** | 升级 RT_StepDriver | RT_StepDriver_Core.f90 修订 | 显式调用 L4_PH_Analysis_Router，传递 Analysis_Group_DESC |
| **III-05** | 编写 L5_RT Analysis 域设计文档 | 180 行文档 | 含三步状态机 + 路由算法 + 多场耦合设计 |

### 阶段 IV：四型拆分与跨层契约规范化（现状 50% → 100%）
**目标**: 在 L3/L4/L5 全域推行统一的 Desc/State/Algo/Ctx 拆分规范  
**工期**: 2.5 周

| 任务编号 | 任务名称 | 输出 | 验收标准 |
|----------|---------|------|---------|
| **IV-01** | L3_MD 全域四型审计与规范化 | 审计报告 + 改造计划 | 所有 15 个域级的 4 个功能集清晰分离 |
| **IV-02** | L3_MD 各域实现四型拆分(第 1 批) | MD_*_Desc.f90/State/Algo/Ctx 模板化 | Material/Mesh/Model/Analysis 4 个域级完成 |
| **IV-03** | L3_MD 各域实现四型拆分(第 2 批) | 剩余 11 个域级 | Boundary/Constraint/Field/Interaction 等完成 |
| **IV-04** | L4_PH/L5_RT 四型规范对齐 | L4_PH/L5_RT 四型设计审查文档 | 热路径 Ctx 零 ALLOCATE；Algo 与 Analysis 类型绑定 |
| **IV-05** | L3-L4 跨层契约文档 | L3_MD_L4_PH_Cross_Contract_v2.md | 修订之前的联通契约，加入 Analysis_Group 约束 |
| **IV-06** | L4-L5 跨层契约文档 | L4_PH_L5_RT_Cross_Contract.md | 新增，定义数据接口、生命周期、验收规则 |

### 阶段 V：集成验证与 AI-ready 插槽基础设施（现状 0% → 50%）
**目标**: 构建支持未来 AI 插槽的基础设施，完成端-端验证  
**工期**: 2 周

| 任务编号 | 任务名称 | 输出 | 验收标准 |
|----------|---------|------|---------|
| **V-01** | AI-ready 插槽基础设施设计 | 70 行文档 | 明确 7 个插槽的 L*/Domain 归属 + 四型职责 |
| **V-02** | L3_MD 插槽预留位(Desc/Algo) | MD_Analysis_Group 新增 AI_slots | 预留但不激活，保留扩展接口 |
| **V-03** | 端-端集成测试框架 | Tests/integration/test_AnalysisType_E2E.f90 | 验证 L3→L4→L5 完整链路；50 个有效坐标都有测试 |
| **V-04** | 性能基准测试 | Tests/benchmark/bench_Analysis_Dispatch.f90 | 路由分发性能 <100ns/call |
| **V-05** | 文档齐全 | 2 个新增总纲文档 + 更新 v5.0 总纲 | 所有新增/修改的模块都有 CONTRACT.md + 设计文档 |

---

## 🔗 二、三个核心跨层契约的建立

### 2.1 L3_MD ↔ L4_PH 契约升级

**当前状态**（见 `L3_MD_L4_PH_联通契约与缺陷分析.md`）：
- ✅ 材料数据通过 MD_Mat_GetDesc_Idx() 推送给 L4
- ✅ 几何数据通过 MD_Geom_PH_Brg 推送给 L4
- ✅ 热路径优化：Compute_Ke/Compute_Fe 已从 slot_pool 读数

**新增约束**（AnalysisType 驱动）：
```fortran
! ============================================================================
! 新约束 D7：Analysis_Group 驱动的处理器启用与约束验证
! ============================================================================

! L3_MD 提供
TYPE(MD_Analysis_Group_DESC), INTENT(IN) :: analysis_group
  ! 包含：solver_1based, coupling_1based, physics_1based
  ! 包含：约束矩阵引用 + 多求解器标记

! L4_PH 消费
SUBROUTINE PH_Route_By_AnalysisGroup(group_desc, processor_config, error)
  ! Step 1: 验证组合合法性 via 约束矩阵
  CALL PH_Validate_Group_Combination(group_desc, valid)
  IF (.NOT. valid) error = PH_ERR_INVALID_GROUP
  
  ! Step 2: 启用对应处理器
  ! - solver_1based=1 ⟹ enable Material/Element/Contact 标准求解路径
  ! - solver_1based=4 ⟹ enable EMF 材料与单元
  
  ! Step 3：识别多求解器需求
  IF (group_desc%requires_auxiliary_solver) THEN
    processor_config%auxiliary_solver_type = group_desc%auxiliary_solver_id
  END IF
END SUBROUTINE

! 验收规则（L3 ⊢ L4）
! ✅ 约束矩阵：0-based 三维索引
! ✅ PROC_ID → (Solver, Coupling, Physics) 映射 100% 覆盖
! ✅ 多求解器标记准确率 100%
```

### 2.2 L4_PH ↔ L5_RT 契约定义

**当前状态**（不完整）：
- ✅ Compute_Ke/Compute_Fe 已被 L5 调用
- ❌ Analysis 级别的路由与约束未传递

**新增约束**（AnalysisType 驱动）：
```fortran
! ============================================================================
! 新约束 D8：L4 Analysis_Router 输出 → L5 求解器创建
! ============================================================================

! L4_PH 输出（via L4_PH_Analysis_Router）
TYPE(PH_Route_Output) :: route_output
  route_output%valid_group_id = .TRUE.
  route_output%active_solvers(1:5) = [1, 0, 0, 0, 0]  ! 激活求解器列表
  route_output%auxiliary_solver_id = 0                 ! 无辅助求解器
  route_output%processor_enable_flags = ...            ! Material/Element/Contact 启用状态

! L5_RT 消费
SUBROUTINE RT_Analysis_CreateSolver(route_output, analysis_group_desc, solver, error)
  ! 根据 route_output 的 active_solvers 选择求解器类型
  solver_type = RT_Infer_SolverType_From_AnalysisGroup(analysis_group_desc)
  
  SELECT CASE (solver_type)
  CASE (RT_SOLVER_IMPLICIT)
    ALLOCATE(RT_Static_Implicit_Solver :: solver)
  CASE (RT_SOLVER_EXPLICIT)
    ALLOCATE(RT_Dynamic_Explicit_Solver :: solver)
  ! ... 其他 6 类
  END SELECT
  
  ! 如有多求解器，创建协调器
  IF (route_output%auxiliary_solver_id > 0) THEN
    ALLOCATE(RT_MF_Coordinator :: mf_coor)
    CALL mf_coor%AddSolver(solver)
    CALL mf_coor%AddSolver(RT_Create_Auxiliary_Solver(route_output%auxiliary_solver_id))
  END IF
END SUBROUTINE

! 验收规则（L4 ⊢ L5）
! ✅ 求解器类型推断准确率 100%（对标 50 有效坐标）
! ✅ 多求解器协调激活准确率 100%
! ✅ 对应求解器的 Algo/Ctx 配置与 Analysis_Group 一致
```

### 2.3 L5_RT ↔ L3_MD 回写契约定义

**当前状态**（分散）：
- ✅ RT_WriteBack_NodePos（更新 L3 节点位置）
- ⚠️  WB_TARGET 白名单管理分散在各 Solver 中

**新增约束**（AnalysisType 驱动）：
```fortran
! ============================================================================
! 新约束 D9：Analysis_Group 驱动的回写策略
! ============================================================================

! L5_RT WriteBack 选择
! 基于 analysis_group_desc 中的 physics_1based：
!   physics_1based = 1 (Structure)  → WriteBack: Displacement, Stress, Strain
!   physics_1based = 2 (Thermal)    → WriteBack: Temperature, HeatFlux
!   physics_1based = 9 (FluidStruct)→ WriteBack: Displacement + Pressure
!   physics_1based = 12 (Special)   → WriteBack: 用户自定义

! 验收规则（L5 ⊢ L3）
! ✅ 针对每个 Physics 类型有明确的 WB_TARGET 清单
! ✅ 不存在越界写 L3（L5 写回范围 = 提前定义的白名单）
! ✅ 状态回写的有效性检查（确保 Rollback 可行）
```

---

## 📊 三、域级完善详情表

### 3.1 L3_MD 完善详情

| 域级 | 当前状态 | 四型规范 | 改造任务 | 预期工期 | 风险 |
|------|---------|---------|---------|---------|------|
| **Analysis** | 60% | Desc/Algo | I-01~I-05 | 1.5w | 低 |
| **Assembly** | 50% | Desc/State | IV-03 | 0.5w | 低 |
| **Boundary** | 70% | Desc/State/Algo | IV-03 | 0.5w | 低 |
| **Bridge** | 30% | 混乱 | **IV-02（清理）** | 1w | 中 |
| **Constraint** | 40% | 缺乏完整TYPE | IV-03 | 0.5w | 中 |
| **Element** | 60% | Desc/Algo | IV-02 | 0.5w | 低 |
| **Field** | 20% | Algo | IV-03 | 0.5w | 低 |
| **Interaction** | 30% | 缺 Desc/State/Algo 拆分 | IV-03 | 1w | 中 |
| **KeyWord** | 40% | Algo | IV-03 | 1w | 低 |
| **Material** | 70% | Desc/State | IV-02 | 0.5w | 低 |
| **Mesh** | 80% | Desc/State | IV-02 | 0.5w | 低 |
| **Model** | 60% | Desc/State/Ctx | IV-02 | 0.5w | 低 |
| **Output** | 50% | Desc/Algo | IV-03 | 0.5w | 低 |
| **Part** | 50% | Desc | IV-03 | 0.5w | 低 |
| **Section** | 50% | Desc | IV-03 | 0.5w | 低 |
| **WriteBack** | 40% | Algo/Ctx | IV-02 | 1w | 中 |

**关键改造**：
- ✅ **I-01~I-05**: Analysis 域从 60% 升至 100%（新增 Analysis_Group 完整支持）
- 🔴 **Bridge 清理**: 职责重定义（L3 → L4 vs L4 → L3）
- 🔴 **Constraint/Interaction 重构**: 补充缺失的 State/Algo 定义

### 3.2 L4_PH 完善详情

| 域级 | 当前状态 | 四型规范 | 改造任务 | 预期工期 | 风险 |
|------|---------|---------|---------|---------|------|
| **Analysis** | **NEW** | Desc/Algo/Ctx | II-01~II-05 | 1w | 中 |
| **Contact** | 20% | 缺乏 TYPE 系统 | IV-04 | 1w | 高 |
| **Constraint** | 30% | 缺 State/Algo | IV-04 | 0.5w | 中 |
| **Element** | 70% | Desc/Algo/Ctx | IV-04 | 0.5w | 低 |
| **Field** | 10% | 仅框架 | IV-04 | 0.5w | 低 |
| **LoadBC** | 50% | Desc/Algo | IV-04 | 0.5w | 低 |
| **Material** | 60% | Desc/State/Algo/Ctx | IV-04 | 0.5w | 低 |
| **Output** | 20% | Algo | IV-04 | 0.5w | 低 |
| **WriteBack** | 30% | Algo/Ctx | IV-04 | 0.5w | 低 |

**关键改造**：
- ✅ **II-01~II-05**: 新增 Analysis 域（路由、处理器启用、多求解器支持）
- 🔴 **Contact 重构**: 补充完整 TYPE 系统 + 约束映射
- 🔴 **热路径优化**: 确保四型在 Ctx 层零 ALLOCATE

### 3.3 L5_RT 完善详情

| 域级 | 当前状态 | 四型规范 | 改造任务 | 预期工期 | 风险 |
|------|---------|---------|---------|---------|------|
| **Assembly** | 30% | Algo/Ctx | III-04 | 0.5w | 中 |
| **Contact** | 20% | 缺乏明确设计 | III-04 | 0.5w | 中 |
| **Coupling** | **0%** | 多场耦合协调器 | III-03 | 1w | 高 |
| **Element** | 20% | Ctx | III-04 | 0.5w | 低 |
| **LoadBC** | 20% | Algo/Ctx | III-04 | 0.5w | 低 |
| **Material** | 30% | Algo/Ctx | III-04 | 0.5w | 低 |
| **Mesh** | 30% | Ctx | III-04 | 0.5w | 低 |
| **Output** | 20% | Algo/Ctx | III-04 | 0.5w | 低 |
| **Solver** | 40% | Desc/Algo/State/Ctx | III-01~III-03 | 1.5w | 中 |
| **StepDriver** | 40% | Algo/Ctx | III-04 | 1w | 中 |

**关键改造**：
- ✅ **III-01**: 升级 RT_SolverType → RT_AnalysisType（五维标准化）
- ✅ **III-02**: 工厂模式完善（创建正确的求解器类）
- 🔴 **III-03**: 多场耦合协调器（FSI/THM/EMF）完全新增
- 🔴 **Coupling 域新建**: 从 0% 到 50%（支持协调器与能量稳定性）

---

## ✅ 四、验收清单与关键指标

### 4.1 功能验收清单

| 验收项 | 标准 | 验证方法 |
|--------|------|---------|
| **分析类型映射完整性** | 50 个有效坐标 100% 实现 | 单元测试：MD_Analysis_Group 映射表 |
| **路由准确性** | PROC_ID → (S,C,P) 无错 | gfortran 编译 + 单元测试 50 个用例 |
| **多求解器支持** | FSI/THM/EMF 正确识别 | 集成测试：L3→L4→L5 完整链路 |
| **四型拆分规范** | 所有新增/改造的 TYPE 都有 Desc/State/Algo/Ctx | 代码审查 |
| **热路径性能** | 路由分发 <100ns/call | 基准测试 |
| **单向依赖** | 无反向依赖违规 | 编译检查 + 代码审查 |
| **AI-ready 预留** | 7 个插槽预留位 + 扩展接口 | 设计审查 |

### 4.2 代码质量指标

| 指标 | 目标 | 验证工具 |
|------|------|---------|
| **编译错误率** | 0 | gfortran -std=f2003 -Wall |
| **编译警告率** | <5 | gfortran 同上 |
| **单元测试覆盖率** | >80%（新增/改造模块） | 集成测试框架 |
| **跨层接口文档完整度** | 100% | 每个 CONTRACT.md 审查 |
| **架构一致性** | 所有改造都对标 v5.0 总纲 | 架构审查 |

### 4.3 文档交付清单

| 文档 | 行数 | 部分输出位置 |
|------|------|-------------|
| I. Analysis 域设计 | 150 | `docs/05_Project_Planning/PPLAN/06_核心架构/01_正交设计_AnalysisType_Group/03_实现指导/` |
| II. L4_PH Analysis 域设计 | 120 | `docs/05_Project_Planning/PPLAN/03_实施规划/04_L4_PH_Analysis_域设计.md` |
| III. L5_RT Analysis 域设计 | 180 | `docs/05_Project_Planning/PPLAN/03_实施规划/05_L5_RT_Analysis_域设计.md` |
| IV. L3-L4 跨层契约 v2.0 | 200 | `docs/05_Project_Planning/PPLAN/05_实施指南/L3_MD_L4_PH_联通契约与缺陷分析_v2.0.md` |
| V. L4-L5 跨层契约 | 180 | `docs/05_Project_Planning/PPLAN/05_实施指南/L4_PH_L5_RT_跨层契约与集成.md` |
| VI. 四型规范 v2.0 | 150 | `docs/六层架构拆分/00-总纲/00-四型拆分规范_v2.0.md` |
| VII. v5.0 总纲修订 | 100 | 更新 `docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.1.md` |
| **合计** | **~1100** | |

---

## 🗓️ 五、执行路线图与时间安排

### 5.1 完整甘特图

```
Q2 2026 (Apr - Jun)
├─ Week 1-2 (Apr 7-18)    ← 当前位置
│  ├─ I-01: PROC 映射补全 (3d)
│  ├─ I-02: 多求解器标记体系 (2d)
│  ├─ I-03: 转换工厂 (2d)
│  └─ I-04,05: 缓存 + 文档 (3d)
│
├─ Week 2-3 (Apr 21-May 2)
│  ├─ II-01~02: L4_PH 路由完善 (4d)
│  ├─ II-03~04: 热路径优化 (3d)
│  └─ II-05: 文档 (2d)
│
├─ Week 4-6 (May 5-23)
│  ├─ III-01: RT_AnalysisType 升级 (3d)
│  ├─ III-02: 工厂完善 (3d)
│  ├─ III-03: 多场耦合协调器 (4d) ← 最高风险
│  ├─ III-04: StepDriver 升级 (3d)
│  └─ III-05: 文档 (2d)
│
├─ Week 6-8 (May 26-Jun 6)  ← 最密集
│  ├─ IV-01: L3 审计 (2d)
│  ├─ IV-02: L3 第 1 批拆分 (5d)
│  ├─ IV-03: L3 第 2 批拆分 (5d)
│  ├─ IV-04: L4/L5 对齐 (4d)
│  ├─ IV-05~06: 契约文档 (3d)
│  └─ CI/CD 集成 (2d)
│
└─ Week 8-10 (Jun 9-20)
   ├─ V-01~02: AI-ready 基础设施 (2d)
   ├─ V-03: E2E 测试框架 (4d)
   ├─ V-04: 性能基准 (2d)
   ├─ V-05: 文档齐全 (2d)
   └─ 最终验收 (3d)
```

### 5.2 里程碑

| 里程碑 | 日期 | 验收标准 |
|--------|------|---------|
| **M1: L3_MD Analysis 域完成** | 2026-04-18 | I-01~I-05 通过 + gfortran 0 errors |
| **M2: L4_PH 路由升级完成** | 2026-05-02 | II-01~II-05 通过 |
| **M3: L5_RT 多场耦合架构完成** | 2026-05-23 | III-01~III-05 通过；多求解器路由功能验证 |
| **M4: 四型拆分全域完成** | 2026-06-06 | IV-01~IV-06 全部通过 |
| **M5: 端-端集成验收** | 2026-06-20 | V-01~V-05 完成；所有验收指标绿色 |

---

## 🎓 六、关键设计原则与禁区

### 6.1 必须遵守的铁律

```fortran
! 1. 单向依赖不可违反
L3_USES(无)
L4_USES(L3, L2, L1)
L5_USES(L4, L3, L2, L1)
! ✅ L3→L4 转发数据可以，L4→L3 反向依赖严禁

! 2. Analysis_Group 是 L3 的权威
TYPE(MD_Analysis_Group_DESC) -- 唯一真相来源
L4 读取 + 验证
L5 读取 + 路由
! ❌ 禁止 L4/L5 独立定义 Analysis 相关的 TYPE

! 3. 约束矩阵是唯一验证来源
COMPATIBILITY_MATRIX(0:4, 0:3, 0:11) -- 每次路由时查表
! ❌ 禁止在代码中硬编码「哪个组合合法」

! 4. 热路径 Ctx 零 ALLOCATE
PH_Mat_Ctx / PH_Element_Ctx / RT_Elem_Ctrl
  ! 所有数组必须是 ALLOCATABLE 或静态大小
  ! Allocate/Deallocate 仅在 Init/Finalize 时
! ❌ 禁止在 Compute_Ke/Compute_Fe 等热路径中 ALLOCATE

! 5. AI 插槽预留，不激活
MD_Analysis_Group_DESC%ai_slots(:) -- 预留但全置 0
! ❌ 禁止在核心路由中调用 AI 路径
```

### 6.2 高风险区域与缓解措施

| 高风险区域 | 风险描述 | 缓解措施 |
|-----------|---------|---------|
| **III-03: RT_MF_Coordinator** | 多求解器协调逻辑复杂；能量稳定性难以保证 | • 先设计完整状态机 + 子步回退机制<br>• FSI 案例（钢-水耦合）验证<br>• 单元测试覆盖 ≥90% |
| **IV-01~IV-03: 全域四型拆分** | 涉及 26 个域级 × 4 类型 = 104 个 MODULE 改造；容易遗漏或一致性错误 | • 自动化 linter（检查命名规范）<br>• 代码生成模板<br>• 逐域级严格审查 |
| **Bridge 清理** | 两套并行桥接职责不清；改造时容易引入反向依赖 | • 先绘制完整依赖图<br>• 显式定义职责分界线<br>• 编译检查反向依赖 |
| **CI/CD 适配** | CMakeLists.txt 与新增 MODULE 同步；新增测试框架 | • 编写 module_dependency_checker.py<br>• 自动化预提交检查<br>• 每次改造后编译全套 |

### 6.3 禁止的架构反模式

```fortran
❌ 反模式 1: L4 绕过 L3_Analysis_Group 直接定义路由
  IF (solver_type == 1 .AND. coupling_type == 2) THEN  ! 硬编码
    ! ... 这是反模式！应该查表
  END IF

❌ 反模式 2: Analysis 逻辑分散在多个 MODULE
  MD_Analysis_Group（定义）
  PH_Analysis_Router（验证）
  RT_Analysis_Factory（创建）
  --> 应该有统一的设计文档 + 契约定义

❌ 反模式 3: Ctx 在热路径中 ALLOCATE
  DO iElem = 1, nElems
    ALLOCATE(elem_ctx%temp_buffer)  ! 反模式
    CALL Compute_Ke(elem_ctx)
    DEALLOCATE(elem_ctx%temp_buffer)
  END DO

✅ 正确做法: 初始化时 ALLOCATE（Step-Init）
  CALL RT_Step_Init
    DO iElem = 1, nElems
      ALLOCATE(elem_ctx%temp_buffer)  ! 仅初始化时
    END DO
```

---

## 📚 七、相关参考文档（学习路径）

### 第 1 阶段：理论基础
1. [UFC_架构设计总纲_深度整合版_v5.0.md](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md) §1-2（六层 + 四大洞察）
2. [域级划分规范](../../六层架构拆分/00-总纲/00-域级划分规范.md)（四型定义 + 功能集规范）
3. [UFC_ABAQUS_Orthogonal_Design.md](../04_技术标准/UFC_ABAQUS_Orthogonal_Design.md)§1-3（正交维度）

### 第 2 阶段：当前实施状态
4. [L3_MD_L4_PH_联通契约与缺陷分析.md](../05_实施指南/L3_MD_L4_PH_联通契约与缺陷分析.md)（现有桥接结构）
5. [UFC_三维坐标_快速参考表_v2.0.md](01_正交设计_AnalysisType_Group/04_快速参考/)（AnalysisType 基础）
6. [L3_MD_Group转换函数设计_1based_vs_0based.md](L3_MD_Group转换函数设计_1based_vs_0based.md)（编码规则）

### 第 3 阶段：新增改造方案
7. [UFC_后分析类型扩充_架构完善总章程_v1.0.md](UFC_后分析类型扩充_架构完善总章程_v1.0.md) ← **本文**
8. （待生成）04_L4_PH_Analysis_域设计.md
9. （待生成）05_L5_RT_Analysis_域设计.md
10. （待生成）L4_PH_L5_RT_跨层契约与集成.md

### 第 4 阶段：标准与规范
11. [UFC_命名规范标准.md](../../六层架构拆分/00-总纲/00-命名规范标准.md)§6（求解器类型枚举）
12. [ufc-solver-router SKILL](../../skills/ufc-solver-router/SKILL.md)（求解器路由手册）
13. [ufc-structured-io SKILL](../../skills/ufc-structured-io/SKILL.md)（SIO 规范）

---

## 🎯 八、总结与行动项

### 目标陈述

**通过五大阶段的系统改造，实现**：

1. ✅ **完整的正交坐标系统贯通** (L3 → L4 → L5)
2. ✅ **统一的四型拆分规范** (Desc/State/Algo/Ctx 在全域一致)
3. ✅ **清晰的跨层契约** (L3-L4、L4-L5、L5-L3 回写)
4. ✅ **多求解器协调能力** (FSI/THM/EMF)
5. ✅ **AI-ready 的基础设施预留** (7 个插槽预留位)

### 立即行动项（Next 1-2 周）

| 序号 | 行动 | 所有者 | 截止日期 |
|------|------|--------|---------|
| 1 | **启动 I 阶段**：PROC 映射表补全至 91 | @dev-core | 2026-04-11 |
| 2 | **审查本章程**：架构师签字 | @arch | 2026-04-09 |
| 3 | **建立 CI 检查**：编译 + 反向依赖扫描 | @devops | 2026-04-10 |
| 4 | **编写 Module 模板**：四型拆分样板 | @dev-core | 2026-04-12 |
| 5 | **建立集成测试框架**：L3-L4-L5 E2E | @qa | 2026-04-15 |
| 6 | **启动 II 阶段**：L4 Analysis_Router 补全 | @dev-phys | 2026-04-18 |

---

## 附录：快速导航表

| 问题 | 查阅位置 |
|------|---------|
| **分析类型有多少个？** | §0.1（50 个有效坐标） |
| **为什么需要三维正交坐标？** | v5.0 总纲 §1.2（洞察 3） + ABAQUS_Orthogonal_Design |
| **如何在 L3 定义新的分析类型？** | I-01~I-03（PROC 映射 + 转换工厂） |
| **L4 如何路由新的分析类型？** | II-01~II-04（路由验证 + 处理器启用） |
| **L5 如何创建对应的求解器？** | III-01~III-03（工厂 + 多场耦合） |
| **四型拆分的原则是什么？** | 域级划分规范 §0.2 + IV 阶段详情 |
| **什么是热路径？** | v5.0 总纲 §0.2（洞察 1）+ L3_MD_L4_PH 联通契约 §2.5 |
| **如何集成多个求解器？** | III-03（RT_MF_Coordinator） |
| **AI-ready 是什么意思？** | v5.0 总纲 §11 + V-01 |
| **全域改造需要多长时间？** | §5.1（甘特图 + 10 周）|
| **风险最高的改造是什么？** | §6.2（III-03: 多场耦合协调器） |

---

**文档版本演进**：
- v1.0 (2026-04-04)：初版完成，等待架构师审查与签字
- v1.1 (待定)：融合审查反馈后发布
- v2.0 (2026-06-20)：全量实施完成后最终版

**最后更新**：2026-04-04  
**下一次审查**：2026-04-09（架构师签字）  
**执行开始**：2026-04-11（M1 启动）
