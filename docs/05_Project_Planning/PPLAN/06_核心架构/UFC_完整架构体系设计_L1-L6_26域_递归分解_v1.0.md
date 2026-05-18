# UFC 完整架构体系设计 — 层级-域级-子域-功能模块递归分解体系 v1.0

> **文档位置**: `docs/05_Project_Planning/PPLAN/06_核心架构/`  
> **创建日期**: 2026-04-04  
> **版本**: v1.0 (阶段 1 架构顶层设计 + 完整递归分解框架)  
> **核心目标**: 从 6 层架构 → 26 个域级 → N 个子域 → M 个功能模块 的完整递归体系  
> **上位文档**: [UFC_架构设计总纲_深度整合版_v5.0.md](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)、[域级划分规范_v3.0.md](../../六层架构拆分/00-总纲/00-域级划分规范.md)  
> **依据决策**: 场基二级分组 + 时间-方法维度正交 + 1-based 外部 API

---

## 📋 文档元数据

| 属性 | 值 |
|------|-----|
| **规范简称** | UFC_L1-L6_26Dom_RcrsDecmp_v1.0 |
| **层级** | L1_IF, L2_NM, L3_MD, L4_PH, L5_RT, L6_AP |
| **域级总数** | 26 个 |
| **预期子域数** | ~80-100 个 |
| **功能模块数** | ~200-300 个 (与 .f90 文件对应) |
| **递归深度** | 层 → 域 → 子域 → 功能模块 (4 级) |
| **四型规范应用** | 每个功能模块均有 Desc/State/Algo/Ctx 定义规范 |

---

## 🎯 零、架构设计决策基础

### 0.1 三大决策源

**决策源 1: 场基二级分组** ⭐  
```
第一维（场性）：
  ├─ 结构相关 (STR: Structure/Thermal/Acoustic/EM/Fluid)
  └─ 无关 (无此分类)

第二维（场数）：
  ├─ 单场 (Structure, Thermal, Acoustic, EM, Fluid 各自独立)
  └─ 多场 (STR×STR, STR×Thermal, STR×Acoustic, ...)

结果：15 种物理场组合
```

**决策源 2: 时间-方法正交维度** ⭐  
```
time × method 笛卡尔积：
  time = {静态, 瞬态/隐式, 显式(显式), 特征值, 频域} ← ABAQUS *STEP 类型
  method = {Newton-Raphson (NR), 中心差分 (CD), 特殊求解器}

但标准化为：
  求解范式 = (time × method) 绑定对：
    ├─ Implicit (隐式 NR) → time=瞬态或静态 + method=NR
    ├─ Explicit (显式 CD) → time=显式 + method=CD
    ├─ Eigenvalue → time=特征值 + method=QR/Lanczos
    └─ Frequency → time=频域 + method=频率分析

→ 对应 5 个求解器类型（不是 time 或 method 单独）
```

**决策源 3: 三维正交坐标体系** ⭐  
```
Group_ID = [Solver(1-5)] × [Coupling(1-4)] × [Physics(1-12)]
  = 5 × 4 × 12 = 240 理论坐标
  ≈ 50 有效坐标（通过兼容性矩阵约束）

外部 API: 1-based [1,5] × [1,4] × [1,12]
内部实现: 0-based [0,4] × [0,3] × [0,11]
```

### 0.2 目录结构设计原则

**原则 1: 层级-域级-子域的严格递归**
```
UFC/ufc_core/
├── L1_IF/
│   ├── Base/
│   ├── Error/
│   └── ... (每个目录 = 1 个域)
│       ├── _Desc.f90      (该域的数据定义)
│       ├── _State.f90     (该域的状态变量)
│       ├── _Algo.f90      (该域的算法参数)
│       ├── _Ctx.f90       (该域的上下文)
│       └── /SubDomains/   (子域目录，可选)
│           ├── sub1/
│           └── sub2/
```

**原则 2: 目录命名规范**
```
层级: L[1-6]_XX (L1_IF, L2_NM, L3_MD, L4_PH, L5_RT, L6_AP)
域级: CamelCase (Material, Element, Mesh, Assembly, ...)
子域: CamelCase_SubXX 或 Desc (如 Material/Elastic, Material/Plastic)
```

**原则 3: 四型模块命名规范**
```
*_Desc.f90  → TYPE *_Desc (模型描述, 配置, 仅读)
*_State.f90 → TYPE *_State (状态变量, 增量步级读写)
*_Algo.f90  → TYPE *_Algo (算法参数, 步级配置)
*_Ctx.f90   → TYPE *_Ctx (计算上下文, 热路径, 零 ALLOCATE)
```

---

## 🏗️ 一、六层架构完整递归分解

### § 1.1 L1_IF: 基础设施层（Infrastructure Layer）

**层级职责**: 精度控制、内存管理、错误处理、日志系统、IO

**子目录与域级映射**:

```
L1_IF/
├── Base/                           [域] Base — 基础类型与工具
│   ├── IF_Precision_Desc.f90      [四型] Desc: 精度定义
│   ├── IF_Precision_Ctx.f90       [四型] Ctx: 精度上下文
│   ├── IF_Base_Utility.f90        [四型] —: 工具函数
│   └── IF_DeviceManager.f90       [四型] —: 设备管理
│
├── Error/                          [域] Error — 错误体系
│   ├── IF_Error_Desc.f90          [四型] Desc: 错误码定义表
│   ├── IF_Error_State.f90         [四型] State: 错误状态
│   ├── IF_Error_Handler.f90       [四型] Algo: 错误处理逻辑
│   └── IF_Error_Ctx.f90           [四型] Ctx: 错误上下文
│
├── IO/                             [域] IO — 输入输出
│   ├── IF_IO_Desc.f90             [四型] Desc: IO 配置
│   ├── IF_IO_State.f90            [四型] State: IO 状态
│   ├── IF_IO_Reader.f90           [四型] Algo: 读取逻辑
│   ├── IF_IO_Writer.f90           [四型] Algo: 写入逻辑
│   └── IF_IO_Ctx.f90              [四型] Ctx: IO 上下文
│
├── Log/                            [域] Log — 日志系统
│   ├── IF_Log_Desc.f90            [四型] Desc: 日志配置
│   ├── IF_Log_Algo.f90            [四型] Algo: 日志记录逻辑
│   └── IF_Log_Ctx.f90             [四型] Ctx: 日志上下文
│
├── Memory/                         [域] Memory — 内存管理
│   ├── IF_Mem_Desc.f90            [四型] Desc: 内存池配置
│   ├── IF_Mem_Allocator.f90       [四型] Algo: 分配策略
│   └── IF_Mem_Ctx.f90             [四型] Ctx: 内存上下文
│
└── Monitor/                        [域] Monitor — 性能监控
    ├── IF_Mon_Desc.f90            [四型] Desc: 监控指标定义
    ├── IF_Mon_State.f90           [四型] State: 监控状态
    └── IF_Mon_Ctx.f90             [四型] Ctx: 监控上下文
```

**域级清单** (L1_IF):
| 序号 | 域级 | 职责 | 子域数 | 预期模块数 |
|------|------|------|--------|-----------|
| 1 | Base | 基础类型、精度、工具 | 0 | 4 |
| 2 | Error | 错误码、异常处理 | 0 | 4 |
| 3 | IO | 文件 IO、检查点 | 0 | 5 |
| 4 | Log | 日志记录、诊断 | 0 | 3 |
| 5 | Memory | 内存管理、内存池 | 0 | 3 |
| 6 | Monitor | 性能监控、计时 | 0 | 3 |

---

### § 1.2 L2_NM: 数值算法层（Numerical Method Layer）

**层级职责**: 线性求解、时间积分、非线性迭代、矩阵运算

**子目录与域级映射**:

```
L2_NM/
├── Base/                           [域] Base — 基础数值工具
│   ├── NM_Base_Desc.f90           [四型] Desc: 数值类型定义
│   ├── NM_Base_Algo.f90           [四型] Algo: 基础操作
│   └── NM_Base_Ctx.f90            [四型] Ctx: 基础上下文
│
├── Matrix/                         [域] Matrix — 矩阵运算
│   ├── NM_Matrix_Desc.f90         [四型] Desc: 矩阵格式定义
│   ├── NM_Matrix_State.f90        [四型] State: 矩阵状态
│   ├── /Dense/
│   │   └── NM_Dense_*.f90         [子域] 稠密矩阵实现
│   ├── /Sparse/
│   │   ├── NM_Sparse_CSR.f90      [子域] 压缩稀疏行格式
│   │   └── NM_Sparse_Triplet.f90  [子域] Triplet 格式
│   └── NM_Matrix_Ctx.f90          [四型] Ctx: 矩阵上下文
│
├── Solver/                         [域] Solver — 求解器 ⭐
│   ├── NM_Solver_Desc.f90         [四型] Desc: 求解器配置
│   ├── NM_Solver_State.f90        [四型] State: 求解状态
│   ├── /Linear/                   [子域] 线性求解
│   │   ├── NM_LU_Factorize.f90
│   │   ├── NM_Gaussian_Elim.f90
│   │   ├── NM_CG.f90              (共轭梯度)
│   │   ├── NM_GMRES.f90           (广义最小残差)
│   │   └── /External/             (外部库桥接)
│   │       ├── NM_Bridge_MUMPS.f90
│   │       └── NM_Bridge_LAPACK.f90
│   ├── /Nonlinear/                [子域] 非线性迭代
│   │   ├── NM_Newton_Raphson.f90  (NR)
│   │   ├── NM_Modified_NR.f90     (修正 NR)
│   │   ├── NM_Quasi_Newton.f90    (拟牛顿)
│   │   └── NM_LineSearch.f90      (线搜索)
│   ├── /Eigenvalue/               [子域] 特征值求解
│   │   ├── NM_QR_Algo.f90
│   │   └── NM_Lanczos.f90
│   └── NM_Solver_Ctx.f90          [四型] Ctx: 求解上下文
│
├── TimeInt/                        [域] TimeInt — 时间积分 ⭐
│   ├── NM_TimeInt_Desc.f90        [四型] Desc: 积分配置
│   ├── NM_TimeInt_State.f90       [四型] State: 积分状态
│   ├── /Implicit/                 [子域] 隐式积分
│   │   ├── NM_Newmark_Implicit.f90
│   │   ├── NM_HHT_Alpha.f90
│   │   ├── NM_Generalized_Alpha.f90
│   │   └── NM_Theta_Method.f90
│   ├── /Explicit/                 [子域] 显式积分
│   │   ├── NM_Newmark_Explicit.f90 (中心差分)
│   │   ├── NM_RK4.f90
│   │   └── NM_Leapfrog.f90
│   ├── /Adaptive/                 [子域] 自适应时步
│   │   ├── NM_Cutback.f90         (回退机制)
│   │   └── NM_StepSize_Control.f90
│   └── NM_TimeInt_Ctx.f90         [四型] Ctx: 时间积分上下文
│
└── Bridge/                         [域] Bridge — 外部库桥接
    ├── NM_Bridge_Desc.f90         [四型] Desc: 桥接配置
    ├── NM_Bridge_BLAS.f90         [四型] Algo: BLAS 包装
    ├── NM_Bridge_LAPACK.f90       [四型] Algo: LAPACK 包装
    └── NM_Bridge_Ctx.f90          [四型] Ctx: 桥接上下文
```

**域级清单** (L2_NM):
| 序号 | 域级 | 子域数 | 预期模块数 |
|------|------|--------|-----------|
| 1 | Base | 0 | 3 |
| 2 | Matrix | 2 | 8 |
| 3 | Solver | 4 | 15 |
| 4 | TimeInt | 4 | 12 |
| 5 | Bridge | 0 | 4 |
| **合计** | | 10 | 42 |

---

### § 1.3 L3_MD: 模型数据层（Model Data Layer）⭐ 核心存储层

**层级职责**: 材料定义、网格管理、部件装配、模型树、分析步管理

**子目录与域级映射**:

```
L3_MD/
├── Analysis/                       [域] Analysis — 分析步与正交坐标 ⭐ NEW
│   ├── MD_Analysis_Group_Desc.f90     [四型] Desc: Group_ID, 约束矩阵
│   ├── MD_Analysis_Group_Factory.f90  [四型] Algo: 转换工厂
│   ├── /Group_Solvers/                [子域] 五种求解器特定配置
│   │   ├── MD_Analysis_Standard.f90   (Implicit NR)
│   │   ├── MD_Analysis_Explicit.f90   (Explicit CD)
│   │   ├── MD_Analysis_Eigenvalue.f90
│   │   ├── MD_Analysis_Frequency.f90
│   │   └── MD_Analysis_CFD.f90
│   └── MD_Analysis_Group_Ctx.f90      [四型] Ctx: Analysis 上下文
│
├── Material/                       [域] Material — 材料库
│   ├── MD_Mat_Desc.f90            [四型] Desc: 材料卡参数表
│   ├── /Elastic/                  [子域] 弹性材料（11 种）
│   │   ├── MD_Ela_Isotropic.f90
│   │   ├── MD_Ela_Orthotropic.f90
│   │   └── ... (11 个模块)
│   ├── /Plastic/                  [子域] 塑性材料（15 种）
│   │   ├── MD_Pls_J2Isotropic.f90
│   │   ├── MD_Pls_Kinematic.f90
│   │   └── ... (15 个模块)
│   ├── /HyperElastic/             [子域] 超弹性（10 种）
│   ├── /Thermal/                  [子域] 热性质（5 种）
│   └── MD_Mat_Ctx.f90             [四型] Ctx: 材料上下文
│
├── Element/                        [域] Element — 单元定义
│   ├── MD_Elem_Desc.f90           [四型] Desc: 单元类型、节点数
│   ├── /Continuum/                [子域] 连续体单元
│   │   ├── MD_C3D8.f90            (8 节点六面体)
│   │   ├── MD_C3D20.f90           (20 节点六面体)
│   │   └── ... (8 个模块)
│   ├── /Shell/                    [子域] 壳单元
│   │   ├── MD_S4R.f90             (4 节点壳)
│   │   └── ... (4 个模块)
│   ├── /Beam/                     [子域] 梁单元
│   │   └── ... (6 个模块)
│   └── MD_Elem_Ctx.f90            [四型] Ctx: 单元上下文
│
├── Mesh/                           [域] Mesh — 网格管理
│   ├── MD_Mesh_Desc.f90           [四型] Desc: 网格配置
│   ├── MD_Mesh_State.f90          [四型] State: 网格状态
│   ├── /Connectivity/             [子域] 连接性管理
│   │   ├── MD_Node_List.f90
│   │   ├── MD_Elem_Connectivity.f90
│   │   └── MD_DOF_Map.f90
│   ├── /Partitioning/             [子域] 网格分割
│   │   └── MD_Mesh_Partition.f90
│   └── MD_Mesh_Ctx.f90            [四型] Ctx: 网格上下文
│
├── Assembly/                       [域] Assembly — 装配定义
│   ├── MD_Assem_Desc.f90          [四型] Desc: 装配配置
│   ├── MD_Part_Assem.f90          [四型] —: 部件装配
│   └── MD_Assem_Ctx.f90           [四型] Ctx: 装配上下文
│
├── Boundary/                       [域] Boundary — 边界条件与载荷
│   ├── MD_BC_Desc.f90             [四型] Desc: BC 定义
│   ├── /Displacement/             [子域] 位移 BC
│   │   └── MD_BC_Disp.f90
│   ├── /Velocity/                 [子域] 速度 BC
│   │   └── MD_BC_Velocity.f90
│   ├── /Load/                     [子域] 载荷
│   │   ├── MD_Load_Point.f90      (点载荷)
│   │   ├── MD_Load_Distributed.f90 (分布载荷)
│   │   └── MD_Load_Pressure.f90   (压力)
│   └── MD_Boundary_Ctx.f90        [四型] Ctx: 边界上下文
│
├── Constraint/                     [域] Constraint — 约束定义
│   ├── MD_Const_Desc.f90          [四型] Desc: 约束类型
│   ├── /Tie/                      [子域] TIE 约束
│   │   └── MD_Const_Tie.f90
│   ├── /Coupling/                 [子域] 耦合约束
│   │   └── MD_Const_Coupling.f90
│   └── MD_Const_Ctx.f90           [四型] Ctx: 约束上下文
│
├── Interaction/                    [域] Interaction — 相互作用（接触、摩擦）
│   ├── MD_Inter_Desc.f90          [四型] Desc: 相互作用定义
│   ├── /Contact/                  [子域] 接触定义
│   │   ├── MD_Contact_Pair.f90
│   │   └── MD_Contact_Algorithm.f90
│   ├── /Friction/                 [子域] 摩擦模型
│   │   ├── MD_Friction_Coulomb.f90
│   │   └── MD_Friction_Penalty.f90
│   └── MD_Inter_Ctx.f90           [四型] Ctx: 相互作用上下文
│
├── Field/                          [域] Field — 场变量定义
│   ├── MD_Field_Desc.f90          [四型] Desc: 场变量定义
│   ├── MD_Field_State.f90         [四型] State: 场变量状态
│   └── MD_Field_Ctx.f90           [四型] Ctx: 场变量上下文
│
├── Output/                         [域] Output — 输出定义
│   ├── MD_Out_Desc.f90            [四型] Desc: 输出字段定义
│   ├── /FieldOutput/              [子域] 场输出
│   │   └── MD_Out_FieldOutput.f90
│   ├── /HistoryOutput/            [子域] 历史输出
│   │   └── MD_Out_HistoryOutput.f90
│   └── MD_Out_Ctx.f90             [四型] Ctx: 输出上下文
│
├── Model/                          [域] Model — 模型容器 (根级)
│   ├── MD_Model_Desc.f90          [四型] Desc: 模型定义
│   ├── MD_Model_State.f90         [四型] State: 模型状态
│   ├── MD_Model_Assemble.f90      [四型] Algo: 模型装配
│   └── MD_Model_Ctx.f90           [四型] Ctx: 模型上下文
│
└── Bridge/                         [域] Bridge — L3→L4/L5 桥接
    ├── MD_L3_To_L4_Material.f90
    ├── MD_L3_To_L4_Mesh.f90
    └── MD_L3_To_L5_State.f90
```

**域级清单** (L3_MD):
| 序号 | 域级 | 子域数 | 预期模块数 | 优先级 |
|------|------|--------|-----------|--------|
| 1 | Analysis | 1 | 7 | ⭐⭐⭐ |
| 2 | Material | 4 | 40+ | ⭐⭐⭐ |
| 3 | Element | 3 | 18 | ⭐⭐⭐ |
| 4 | Mesh | 2 | 5 | ⭐⭐ |
| 5 | Assembly | 0 | 3 | ⭐⭐ |
| 6 | Boundary | 3 | 6 | ⭐⭐ |
| 7 | Constraint | 2 | 3 | ⭐ |
| 8 | Interaction | 2 | 5 | ⭐ |
| 9 | Field | 0 | 3 | ⭐ |
| 10 | Output | 2 | 3 | ⭐ |
| 11 | Model | 0 | 4 | ⭐⭐ |
| 12 | Bridge | 0 | 3 | ⭐ |
| **合计** | | 17 | 100+ | |

---

### § 1.4 L4_PH: 物理层（Physics Layer）⭐ 计算核心

**层级职责**: 单元计算、材料本构、接触算法、载荷施加

**子目录与域级映射**:

```
L4_PH/
├── Material/                       [域] Material — 本构积分 ⭐ 最复杂
│   ├── PH_Mat_Desc.f90            [四型] Desc: 材料状态变量定义
│   ├── PH_Mat_State.f90           [四型] State: SDV, 应力, 内变量
│   ├── /Elastic/                  [子域] 弹性本构（11 个算法）
│   │   ├── PH_Ela_Isotropic_UMAT.f90
│   │   ├── PH_Ela_Orthotropic_UMAT.f90
│   │   └── ... (11 个)
│   ├── /Plastic/                  [子域] 塑性本构（15 个算法）
│   │   ├── PH_Pls_J2_UMAT.f90
│   │   └── ... (15 个)
│   ├── /HyperElastic/             [子域] 超弹性本构（10 个算法）
│   ├── /Thermal/                  [子域] 热性质本构
│   │   ├── PH_Thm_Conductivity.f90
│   │   ├── PH_Thm_SpecificHeat.f90
│   │   └── PH_Thm_Expansion.f90
│   ├── /Composite/                [子域] 复合材料本构
│   ├── /DimensionAdapter/         [子域] 维度适配 (3D→2D/Shell/Beam)
│   │   └── PH_Util_DimAdapter.f90
│   └── PH_Mat_Ctx.f90             [四型] Ctx: 材料上下文
│
├── Element/                        [域] Element — 单元计算
│   ├── PH_Elem_Desc.f90           [四型] Desc: 单元类型参数
│   ├── /Continuum/                [子域] 连续体单元（C3D8, C3D20 等）
│   │   ├── PH_C3D8_Stiffness.f90
│   │   ├── PH_C3D8_InternalForce.f90
│   │   └── ... (8 个单元 × 2 = 16 模块)
│   ├── /Shell/                    [子域] 壳单元
│   │   ├── PH_S4R_Stiffness.f90
│   │   └── ... (4 × 2 = 8 模块)
│   ├── /Beam/                     [子域] 梁单元
│   │   └── ... (6 × 2 = 12 模块)
│   └── PH_Elem_Ctx.f90            [四型] Ctx: 单元上下文
│
├── Contact/                        [域] Contact — 接触算法
│   ├── PH_Contact_Desc.f90        [四型] Desc: 接触对参数
│   ├── /Penalty/                  [子域] 惩罚法
│   │   └── PH_Contact_Penalty.f90
│   ├── /Lagrange/                 [子域] Lagrange 乘子法
│   │   └── PH_Contact_Lagrange.f90
│   ├── /Augmented/                [子域] 增强 Lagrange 法
│   │   └── PH_Contact_Augmented.f90
│   └── PH_Contact_Ctx.f90         [四型] Ctx: 接触上下文
│
├── LoadBC/                         [域] LoadBC — 载荷与 BC 施加
│   ├── PH_LoadBC_Desc.f90         [四型] Desc: 载荷 BC 配置
│   ├── /Displacement/             [子域] 位移施加
│   │   └── PH_Load_Disp.f90
│   ├── /Force/                    [子域] 力施加
│   │   ├── PH_Load_Point.f90
│   │   ├── PH_Load_Distributed.f90
│   │   └── PH_Load_Pressure.f90
│   ├── /Thermal/                  [子域] 热边界条件
│   │   ├── PH_Thm_Film.f90        (对流)
│   │   ├── PH_Thm_Flux.f90        (热通量)
│   │   └── PH_Thm_Radiation.f90   (辐射)
│   └── PH_LoadBC_Ctx.f90          [四型] Ctx: 载荷上下文
│
├── Constraint/                     [域] Constraint — 约束施加
│   ├── PH_Const_Desc.f90          [四型] Desc: 约束配置
│   ├── /Tie/                      [子域] TIE 约束
│   │   └── PH_Const_Tie_Apply.f90
│   ├── /Coupling/                 [子域] 耦合约束
│   │   └── PH_Const_Coupling_Apply.f90
│   └── PH_Const_Ctx.f90           [四型] Ctx: 约束上下文
│
├── Output/                         [域] Output — 字段提取
│   ├── PH_Out_Desc.f90            [四型] Desc: 输出字段定义
│   ├── /StressStrain/             [子域] 应力应变输出
│   │   └── PH_Out_StressStrain.f90
│   ├── /InternalVar/              [子域] 内变量输出
│   │   └── PH_Out_InternalVar.f90
│   └── PH_Out_Ctx.f90             [四型] Ctx: 输出上下文
│
├── Bridge/                         [域] Bridge — L3↔L5 桥接
│   ├── PH_L4_To_L3_Mat_Bridge.f90
│   ├── PH_L4_To_L3_Elem_Bridge.f90
│   ├── PH_L4_To_L5_Assem_Bridge.f90
│   └── PH_L4_Analysis_Router.f90  (新增: Analysis_Group 路由)
│
└── WriteBack/                      [域] WriteBack — 状态回写
    ├── PH_WriteBack_Desc.f90      [四型] Desc: 回写配置
    └── PH_WriteBack_Impl.f90      [四型] Algo: 回写逻辑
```

**域级清单** (L4_PH):
| 序号 | 域级 | 子域数 | 预期模块数 | 优先级 |
|------|------|--------|-----------|--------|
| 1 | Material | 6 | 50+ | ⭐⭐⭐ |
| 2 | Element | 3 | 36 | ⭐⭐⭐ |
| 3 | Contact | 3 | 4 | ⭐⭐ |
| 4 | LoadBC | 3 | 6 | ⭐⭐ |
| 5 | Constraint | 2 | 3 | ⭐ |
| 6 | Output | 2 | 3 | ⭐ |
| 7 | Bridge | 0 | 4 | ⭐⭐ |
| 8 | WriteBack | 0 | 2 | ⭐ |
| **合计** | | 19 | 108 | |

---

### § 1.5 L5_RT: 运行时层（Runtime Layer）⭐ 调度控制

**层级职责**: 求解器调度、作业管理、步骤控制、全局状态

**子目录与域级映射**:

```
L5_RT/
├── Analysis/                       [域] Analysis — 分析步驱动 ⭐
│   ├── RT_Analysis_Desc.f90       [四型] Desc: 分析配置
│   ├── RT_Analysis_Algo.f90       [四型] Algo: 分析算法
│   ├── /Solver_Standard/          [子域] Standard 隐式求解器
│   │   ├── RT_Static_Implicit.f90
│   │   ├── RT_Dynamic_Implicit.f90
│   │   └── RT_StepControl_Implicit.f90
│   ├── /Solver_Explicit/          [子域] Explicit 显式求解器
│   │   ├── RT_Dynamic_Explicit.f90
│   │   └── RT_StepControl_Explicit.f90
│   ├── /Solver_Eigenvalue/        [子域] 特征值求解
│   │   ├── RT_Modal.f90
│   │   ├── RT_Buckle.f90
│   │   └── RT_Frequency.f90
│   ├── /StepDriver/               [子域] 步驱动（三步状态机）
│   │   ├── RT_Step_Init.f90       (分析步初始化)
│   │   ├── RT_Incr_Loop.f90       (增量循环)
│   │   ├── RT_Iter_Loop.f90       (迭代循环)
│   │   └── RT_Convergence_Check.f90
│   └── RT_Analysis_Ctx.f90        [四型] Ctx: 分析上下文
│
├── Assembly/                       [域] Assembly — 全局组装
│   ├── RT_Assem_Desc.f90          [四型] Desc: 组装配置
│   ├── RT_Assem_Algo.f90          [四型] Algo: 组装算法
│   ├── /GlobalStiffness/          [子域] 全局刚度矩阵
│   │   ├── RT_Assem_Ke_Assembly.f90
│   │   └── RT_CSR_Assembly.f90    (CSR 格式)
│   ├── /InternalForce/            [子域] 内力计算
│   │   └── RT_Assem_Fe_Assembly.f90
│   ├── /SparsityPattern/          [子域] 稀疏模式
│   │   ├── RT_Sparsity_Compute.f90
│   │   └── RT_Sparsity_Reuse.f90
│   └── RT_Assem_Ctx.f90           [四型] Ctx: 组装上下文
│
├── Material/                       [域] Material — 材料积分驱动
│   ├── RT_Mat_Desc.f90            [四型] Desc: 材料驱动配置
│   ├── RT_Mat_Algo.f90            [四型] Algo: 材料驱动算法
│   ├── /IntegrationLoop/          [子域] 材料点积分循环
│   │   └── RT_Mat_Integration_Loop.f90
│   ├── /LocalIteration/           [子域] 本地非线性迭代
│   │   ├── RT_Mat_ReturnMapping.f90
│   │   └── RT_Mat_LocalNR.f90
│   └── RT_Mat_Ctx.f90             [四型] Ctx: 材料驱动上下文
│
├── Element/                        [域] Element — 单元计算驱动
│   ├── RT_Elem_Desc.f90           [四型] Desc: 单元驱动配置
│   ├── RT_Elem_Algo.f90           [四型] Algo: 单元驱动算法
│   ├── /ElementLoop/              [子域] 单元循环
│   │   ├── RT_Elem_Loop_Ke.f90
│   │   └── RT_Elem_Loop_Fe.f90
│   └── RT_Elem_Ctx.f90            [四型] Ctx: 单元驱动上下文
│
├── Coupling/                       [域] Coupling — 多场耦合协调 ⭐ NEW
│   ├── RT_MF_Desc.f90             [四型] Desc: 多场耦合配置
│   ├── RT_MF_Algo.f90             [四型] Algo: 协调算法
│   ├── /Coordinator/              [子域] 总协调器
│   │   ├── RT_MF_Coordinator.f90  (FSI/THM/EMF 通用协调)
│   │   └── RT_MF_Strategy.f90     (三大耦合策略)
│   ├── /FSI/                      [子域] 流固耦合
│   │   ├── RT_FSI_StrongCoupling.f90
│   │   └── RT_FSI_WeakCoupling.f90
│   ├── /Thermal/                  [子域] 热耦合
│   │   ├── RT_THM_Coupled.f90
│   │   └── RT_Thermal_Transfer.f90
│   └── RT_Coupling_Ctx.f90        [四型] Ctx: 耦合上下文
│
├── Solver/                         [域] Solver — 线性求解驱动
│   ├── RT_Solv_Desc.f90           [四型] Desc: 求解器配置
│   ├── RT_Solv_Algo.f90           [四型] Algo: 求解算法
│   ├── /LinearSolve/              [子域] 线性求解
│   │   ├── RT_Solv_Direct.f90     (直接法)
│   │   └── RT_Solv_Iterative.f90  (迭代法)
│   ├── /NonlinearIteration/       [子域] 非线性迭代
│   │   └── RT_Solv_NR_Iteration.f90
│   └── RT_Solv_Ctx.f90            [四型] Ctx: 求解上下文
│
├── Contact/                        [域] Contact — 接触计算驱动
│   ├── RT_Contact_Desc.f90        [四型] Desc: 接触驱动配置
│   ├── RT_Contact_Algo.f90        [四型] Algo: 接触计算算法
│   ├── /ContactSearch/            [子域] 接触搜索
│   │   └── RT_Contact_Search.f90
│   ├── /ForceCalculation/         [子域] 接触力计算
│   │   └── RT_Contact_Force.f90
│   └── RT_Contact_Ctx.f90         [四型] Ctx: 接触上下文
│
├── LoadBC/                         [域] LoadBC — 载荷时间曲线
│   ├── RT_LoadBC_Desc.f90         [四型] Desc: 载荷时间历程
│   ├── /AmplitudeFactor/          [子域] 幅值因子
│   │   └── RT_LoadBC_Amplitude.f90
│   └── RT_LoadBC_Ctx.f90          [四型] Ctx: 载荷上下文
│
├── Output/                         [域] Output — 输出控制
│   ├── RT_Out_Desc.f90            [四型] Desc: 输出配置
│   ├── RT_Out_Algo.f90            [四型] Algo: 输出算法
│   ├── /FieldOutput/              [子域] 场输出
│   │   └── RT_Out_FieldOutput.f90
│   ├── /HistoryOutput/            [子域] 历史输出
│   │   └── RT_Out_HistoryOutput.f90
│   └── RT_Out_Ctx.f90             [四型] Ctx: 输出上下文
│
├── WriteBack/                      [域] WriteBack — 状态回写
│   ├── RT_WriteBack_Desc.f90      [四型] Desc: 回写配置
│   ├── RT_WriteBack_Algo.f90      [四型] Algo: 回写算法
│   ├── /NodeState/                [子域] 节点状态回写
│   │   ├── RT_WriteBack_Disp.f90
│   │   └── RT_WriteBack_Vel.f90
│   ├── /ElementState/             [子域] 单元状态回写
│   │   └── RT_WriteBack_ElemStress.f90
│   └── RT_WriteBack_Ctx.f90       [四型] Ctx: 回写上下文
│
└── Mesh/                           [域] Mesh — 网格更新与通信
    ├── RT_Mesh_Desc.f90           [四型] Desc: 网格配置
    ├── /MeshUpdate/               [子域] 网格更新
    │   └── RT_Mesh_Update.f90
    └── RT_Mesh_Ctx.f90            [四型] Ctx: 网格上下文
```

**域级清单** (L5_RT):
| 序号 | 域级 | 子域数 | 预期模块数 | 优先级 |
|------|------|--------|-----------|--------|
| 1 | Analysis | 4 | 8 | ⭐⭐⭐ |
| 2 | Assembly | 3 | 6 | ⭐⭐⭐ |
| 3 | Material | 2 | 5 | ⭐⭐⭐ |
| 4 | Element | 1 | 3 | ⭐⭐ |
| 5 | Coupling | 3 | 7 | ⭐⭐⭐ NEW |
| 6 | Solver | 2 | 4 | ⭐⭐ |
| 7 | Contact | 2 | 3 | ⭐ |
| 8 | LoadBC | 1 | 2 | ⭐ |
| 9 | Output | 2 | 3 | ⭐ |
| 10 | WriteBack | 2 | 4 | ⭐ |
| 11 | Mesh | 1 | 2 | ⭐ |
| **合计** | | 23 | 47 | |

---

### § 1.6 L6_AP: 应用层（Application Layer）

**层级职责**: 命令解析、脚本 API、图形界面、前后处理

**子目录与域级映射**:

```
L6_AP/
├── Input/                          [域] Input — 输入解析
│   ├── AP_Input_Desc.f90          [四型] Desc: 输入配置
│   ├── /INPParser/                [子域] ABAQUS .inp 解析
│   │   ├── AP_INP_Lexer.f90
│   │   ├── AP_INP_Parser.f90
│   │   └── AP_INP_Validator.f90
│   ├── /Preprocessor/             [子域] 前处理
│   │   └── AP_Preproc.f90
│   └── AP_Input_Ctx.f90           [四型] Ctx: 输入上下文
│
├── Output/                         [域] Output — 输出后处理
│   ├── AP_Output_Desc.f90         [四型] Desc: 输出配置
│   ├── /ODB/                      [子域] ODB 输出
│   │   ├── AP_ODB_Write.f90
│   │   └── AP_ODB_Format.f90
│   ├── /Postproc/                 [子域] 后处理
│   │   └── AP_Postproc.f90
│   └── AP_Output_Ctx.f90          [四型] Ctx: 输出上下文
│
├── Solver/                         [域] Solver — 求解器接口
│   ├── AP_Solver_Desc.f90         [四型] Desc: 求解器配置
│   ├── /Standard/                 [子域] Standard 接口
│   │   └── AP_Standard_Interface.f90
│   ├── /Explicit/                 [子域] Explicit 接口
│   │   └── AP_Explicit_Interface.f90
│   └── AP_Solver_Ctx.f90          [四型] Ctx: 求解器上下文
│
├── Command/                        [域] Command — 命令行接口
│   ├── AP_Cmd_Desc.f90            [四型] Desc: 命令定义
│   ├── /CommandParser/            [子域] 命令解析
│   │   └── AP_Cmd_Parser.f90
│   └── AP_Cmd_Ctx.f90             [四型] Ctx: 命令上下文
│
└── GUI/                            [域] GUI — 图形界面 (可选)
    ├── AP_GUI_Desc.f90            [四型] Desc: GUI 配置
    └── AP_GUI_Ctx.f90             [四型] Ctx: GUI 上下文
```

**域级清单** (L6_AP):
| 序号 | 域级 | 子域数 | 预期模块数 | 优先级 |
|------|------|--------|-----------|--------|
| 1 | Input | 2 | 6 | ⭐⭐ |
| 2 | Output | 2 | 4 | ⭐⭐ |
| 3 | Solver | 2 | 3 | ⭐ |
| 4 | Command | 1 | 2 | ⭐ |
| 5 | GUI | 0 | 2 | ☆ |
| **合计** | | 7 | 17 | |

---

## 📊 二、完整架构体系统计

### § 2.1 层级-域级总览表

| 层级 | 英文名 | 域级数 | 子域数 | 预期模块数 | 优先级 | 状态 |
|------|--------|--------|--------|-----------|--------|------|
| **L1** | Infrastructure | 6 | 0 | 22 | ⭐⭐ | 基础 |
| **L2** | Numerical | 5 | 10 | 42 | ⭐⭐⭐ | 核心 |
| **L3** | Model Data | 12 | 17 | 100+ | ⭐⭐⭐ | 核心 |
| **L4** | Physics | 8 | 19 | 108 | ⭐⭐⭐ | 核心 |
| **L5** | Runtime | 11 | 23 | 47 | ⭐⭐⭐ | 核心 |
| **L6** | Application | 5 | 7 | 17 | ⭐⭐ | 应用 |
| **合计** | | **47** | **76** | **336+** | | |

### § 2.2 优先级分布

```
⭐⭐⭐ 最高优先级 (立即实施)
  ├─ L2_NM (数值算法基础)
  ├─ L3_MD (模型数据 + Analysis_Group ⭐ 新)
  ├─ L4_PH (物理计算 + Material 本构)
  └─ L5_RT (运行时调度 + Coupling 耦合 ⭐ 新)

⭐⭐ 高优先级 (分阶段实施)
  ├─ L1_IF (基础设施)
  ├─ L3_MD 的 Mesh/Assembly/Model
  ├─ L4_PH 的 Contact/LoadBC
  ├─ L5_RT 的 Material/Element/Solver
  └─ L6_AP 的 Input/Output

⭐ 标准优先级 (可并行实施)
  ├─ L3_MD 的 Constraint/Interaction/Field/Bridge
  ├─ L4_PH 的 Constraint/Output/WriteBack
  ├─ L5_RT 的 Contact/LoadBC/Output/WriteBack/Mesh
  └─ L6_AP 的 Solver/Command

☆ 低优先级 (可选/第二阶段)
  └─ L6_AP 的 GUI
```

---

## 📁 三、完整目录树结构

```
UFC/ufc_core/
├── L1_IF/                          [6 个域级]
│   ├── Base/                       → 4 个模块
│   ├── Error/                      → 4 个模块
│   ├── IO/                         → 5 个模块
│   ├── Log/                        → 3 个模块
│   ├── Memory/                     → 3 个模块
│   └── Monitor/                    → 3 个模块
│
├── L2_NM/                          [5 个域级, 10 个子域]
│   ├── Base/                       → 3 个模块
│   ├── Matrix/
│   │   ├── Dense/                 → 2-3 个模块
│   │   ├── Sparse/                → 2-3 个模块
│   │   └── (4 个顶层模块)
│   ├── Solver/
│   │   ├── Linear/                → 5-6 个模块
│   │   ├── Nonlinear/             → 4-5 个模块
│   │   ├── Eigenvalue/            → 2 个模块
│   │   └── (4 个顶层模块)
│   ├── TimeInt/
│   │   ├── Implicit/              → 4 个模块
│   │   ├── Explicit/              → 3 个模块
│   │   ├── Adaptive/              → 2 个模块
│   │   └── (4 个顶层模块)
│   └── Bridge/                     → 4 个模块
│
├── L3_MD/                          [12 个域级, 17 个子域]
│   ├── Analysis/ ⭐ NEW
│   │   ├── Group_Solvers/         → 5 个模块 (Standard/Explicit/...)
│   │   └── (2 个顶层模块)
│   ├── Material/
│   │   ├── Elastic/               → 11 个模块
│   │   ├── Plastic/               → 15 个模块
│   │   ├── HyperElastic/          → 10 个模块
│   │   ├── Thermal/               → 5 个模块
│   │   ├── Composite/             → 5 个模块
│   │   └── (5 个顶层模块)
│   ├── Element/
│   │   ├── Continuum/             → 8 个模块
│   │   ├── Shell/                 → 4 个模块
│   │   ├── Beam/                  → 6 个模块
│   │   └── (3 个顶层模块)
│   ├── Mesh/
│   │   ├── Connectivity/          → 3 个模块
│   │   ├── Partitioning/          → 1 个模块
│   │   └── (3 个顶层模块)
│   ├── Assembly/                  → 3 个模块
│   ├── Boundary/
│   │   ├── Displacement/          → 1 个模块
│   │   ├── Velocity/              → 1 个模块
│   │   ├── Load/                  → 3 个模块
│   │   └── (1 个顶层模块)
│   ├── Constraint/
│   │   ├── Tie/                   → 1 个模块
│   │   ├── Coupling/              → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── Interaction/
│   │   ├── Contact/               → 2 个模块
│   │   ├── Friction/              → 2 个模块
│   │   └── (1 个顶层模块)
│   ├── Field/                     → 3 个模块
│   ├── Output/
│   │   ├── FieldOutput/           → 1 个模块
│   │   ├── HistoryOutput/         → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── Model/                     → 4 个模块
│   └── Bridge/                    → 3 个模块
│
├── L4_PH/                          [8 个域级, 19 个子域]
│   ├── Material/
│   │   ├── Elastic/               → 11 个模块 (UMAT)
│   │   ├── Plastic/               → 15 个模块 (UMAT)
│   │   ├── HyperElastic/          → 10 个模块 (UHYPER)
│   │   ├── Thermal/               → 3 个模块
│   │   ├── Composite/             → 5 个模块
│   │   ├── DimensionAdapter/      → 1 个模块 ⭐
│   │   └── (5 个顶层模块)
│   ├── Element/
│   │   ├── Continuum/             → 16 个模块 (8 单元 × 2: Ke, Fe)
│   │   ├── Shell/                 → 8 个模块
│   │   ├── Beam/                  → 12 个模块
│   │   └── (3 个顶层模块)
│   ├── Contact/
│   │   ├── Penalty/               → 1 个模块
│   │   ├── Lagrange/              → 1 个模块
│   │   ├── Augmented/             → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── LoadBC/
│   │   ├── Displacement/          → 1 个模块
│   │   ├── Force/                 → 3 个模块
│   │   ├── Thermal/               → 3 个模块
│   │   └── (1 个顶层模块)
│   ├── Constraint/
│   │   ├── Tie/                   → 1 个模块
│   │   ├── Coupling/              → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── Output/
│   │   ├── StressStrain/          → 1 个模块
│   │   ├── InternalVar/           → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── Bridge/                    → 4 个模块
│   └── WriteBack/                 → 2 个模块
│
├── L5_RT/                          [11 个域级, 23 个子域]
│   ├── Analysis/
│   │   ├── Solver_Standard/       → 3 个模块
│   │   ├── Solver_Explicit/       → 2 个模块
│   │   ├── Solver_Eigenvalue/     → 3 个模块
│   │   ├── StepDriver/            → 4 个模块
│   │   └── (1 个顶层模块)
│   ├── Assembly/
│   │   ├── GlobalStiffness/       → 2 个模块
│   │   ├── InternalForce/         → 1 个模块
│   │   ├── SparsityPattern/       → 2 个模块
│   │   └── (1 个顶层模块)
│   ├── Material/
│   │   ├── IntegrationLoop/       → 1 个模块
│   │   ├── LocalIteration/        → 2 个模块
│   │   └── (1 个顶层模块)
│   ├── Element/
│   │   ├── ElementLoop/           → 2 个模块
│   │   └── (1 个顶层模块)
│   ├── Coupling/ ⭐ NEW
│   │   ├── Coordinator/           → 2 个模块 (总协调器 + 策略)
│   │   ├── FSI/                   → 2 个模块
│   │   ├── Thermal/               → 2 个模块
│   │   └── (1 个顶层模块)
│   ├── Solver/
│   │   ├── LinearSolve/           → 2 个模块
│   │   ├── NonlinearIteration/    → 1 个模块
│   │   └── (2 个顶层模块)
│   ├── Contact/
│   │   ├── ContactSearch/         → 1 个模块
│   │   ├── ForceCalculation/      → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── LoadBC/
│   │   ├── AmplitudeFactor/       → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── Output/
│   │   ├── FieldOutput/           → 1 个模块
│   │   ├── HistoryOutput/         → 1 个模块
│   │   └── (1 个顶层模块)
│   ├── WriteBack/
│   │   