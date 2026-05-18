# L5_RT 运行时协调层 — 完整域级拆解 v1.0

> **层级**: L5_RT (Runtime Coordination Layer)  
> **版本**: v1.0  
> **层级职责**: 求解步驱动、多场耦合协调、实时监控、数据流调度  
> **域级总数**: 11 个  
> **子域总数**: 23 个  
> **功能模块总数**: 47 个  
> **命名前缀**: `RT_` (Runtime)

---

## 📋 L5_RT 层拓扑结构

```
L5_RT (运行时协调层)
│
├─ Analysis — 求解步与分析类型管理
├─ Assembly — 运行时装配与 DOF 管理
├─ Material — 材料库管理与缓存
├─ Element — 单元库管理与批量计算
├─ Coupling ⭐ NEW — 多场耦合协调 (FSI/THM/EMF)
├─ Solver — 求解器调度与步长控制
├─ Contact — 接触检测与力更新
├─ LoadBC — 载荷时间历程应用
├─ Output — 实时输出管理
├─ WriteBack — ODB/检查点写入
└─ Mesh — 网格自适应与重分区
```

---

## 🎯 一、十一个域级完整拆解

### 1.1 域级 1: **Analysis** — 求解步驱动

**职责**: 求解步调度、时间步长控制、分析类型路由

**子域** (4 个):
- **StepDriver** — 求解步主驱动
- **StepSequence** — 步序列与优先级
- **StepValidator** — 步级约束校验
- **GroupRouter** — 分析类型路由

**功能模块** (8 个):
```
RT_Analysis_Desc.f90      — 分析配置
RT_StepDriver.f90         — 求解步驱动
RT_StepDriver_Ctx.f90     — 步驱动上下文
RT_StepSequence.f90       — 步序列管理
RT_AnalysisGroup_Validator.f90 — 约束校验 (新增，阶段3)
RT_GroupRouter.f90        — Group_ID 路由
RT_TimeStep_Adapt.f90     — 自适应步长
RT_Analysis_Ctx.f90       — Analysis 上下文
```

### 1.2 域级 2: **Assembly** — 运行时装配

**职责**: 全局 DOF、增量步自由度更新

**子域** (3 个):
- **GlobalDOF** — 全局 DOF 编号
- **IncrementalStep** — 增量步管理
- **DOFUpdate** — DOF 更新

**功能模块** (6 个):
```
RT_Assem_Desc.f90         — 装配配置
RT_Assem_GlobalDOF.f90    — 全局 DOF
RT_Assem_Incr.f90         — 增量步
RT_Assem_DOFUpdate.f90    — DOF 更新
RT_Assem_Active.f90       — 活跃 DOF 管理
RT_Assem_Ctx.f90          — 装配上下文
```

### 1.3 域级 3: **Material** — 材料库运行时

**职责**: 材料参数预加载、状态缓存、性能优化

**子域** (2 个):
- **LibraryCache** — 材料库缓存
- **StateUpdate** — 状态更新

**功能模块** (5 个):
```
RT_Mat_Desc.f90           — 材料配置
RT_Mat_LibCache.f90       — 材料库缓存
RT_Mat_StateUpdate.f90    — 状态更新
RT_Mat_HardnessEvol.f90   — 硬化演化缓存
RT_Mat_Ctx.f90            — 材料运行时上下文
```

### 1.4 域级 4: **Element** — 单元库运行时

**职责**: 单元批量计算调度、GPU 优化

**子域** (1 个):
- **BatchCompute** — 批量计算

**功能模块** (3 个):
```
RT_Elem_Desc.f90          — 单元配置
RT_Elem_BatchCompute.f90  — 批量计算调度
RT_Elem_Ctx.f90           — 单元运行时上下文
```

### 1.5 域级 5: **Coupling** ⭐ NEW — 多场耦合协调

**职责**: FSI/THM/EMF 多场耦合算法、迭代策略、收敛控制

**子域** (3 个):
- **Coordinator** — 多场总协调器
- **Strategy** — 耦合策略 (Weak/Strong/Staggered)
- **Convergence** — 耦合收敛判据

**功能模块** (7 个):
```
RT_MF_Desc.f90            — 多场配置
RT_MF_Types.f90           — 多场 TYPE 定义 (已实现，见阶段1 mem)
RT_MF_Coordinator.f90     — 多场总协调器
RT_MF_Strategy_Weak.f90   — 弱耦合策略
RT_MF_Strategy_Strong.f90 — 强耦合策略
RT_MF_Strategy_FSI.f90    — FSI 特定策略
RT_MF_Convergence.f90 + Ctx — 收敛判据
```

**特殊结构** (来自阶段1):
```
TYPE RT_MF_Desc              ! 多场描述
  INTEGER :: coupling_id      ! 耦合 ID (1-4)
  LOGICAL :: enable_fsi, enable_thm, enable_emf
END TYPE

TYPE RT_MF_State             ! 多场状态
  REAL(wp), ALLOCATABLE :: struct_stress(:)
  REAL(wp), ALLOCATABLE :: thermal_temp(:)
  INTEGER :: iteration_count
END TYPE

TYPE RT_MF_Algo              ! 多场算法
  INTEGER :: strategy_type   ! 1=Weak, 2=Strong, 3=Staggered
  REAL(wp) :: relax_factor
END TYPE

TYPE RT_MF_Ctx               ! 多场上下文
  REAL(wp) :: residual_tol
  INTEGER :: max_iterations
END TYPE
```

### 1.6 域级 6: **Solver** — 求解器协调

**职责**: 线性/非线性求解器的调用与收敛控制

**子域** (2 个):
- **Linear** — 线性求解器调用
- **Nonlinear** — 非线性求解器协调

**功能模块** (4 个):
```
RT_Solv_Desc.f90          — 求解器配置
RT_Solv_Linear.f90        — 线性求解器调用
RT_Solv_Nonlinear.f90     — 非线性迭代协调
RT_Solv_Ctx.f90           — 求解器上下文
```

### 1.7 域级 7: **Contact** — 接触管理

**职责**: 接触对搜索、力更新、反复迭代

**子域** (2 个):
- **Search** — 接触对搜索
- **ForceUpdate** — 力更新

**功能模块** (3 个):
```
RT_Cont_Desc.f90          — 接触配置
RT_Cont_Search.f90        — 接触搜索
RT_Cont_Ctx.f90           — 接触上下文
```

### 1.8 域级 8: **LoadBC** — 载荷应用

**职责**: 时间历程载荷应用、边界条件实时管理

**功能模块** (2 个):
```
RT_Load_Desc.f90          — 载荷配置
RT_Load_Ctx.f90           — 载荷上下文
```

### 1.9 域级 9: **Output** — 实时输出

**职责**: 增量步输出、历史输出收集

**子域** (2 个):
- **FrameOutput** — 单步输出
- **HistoryAccum** — 历史累积

**功能模块** (3 个):
```
RT_Out_Desc.f90           — 输出配置
RT_Out_Frame.f90          — 单步输出
RT_Out_Ctx.f90            — 输出上下文
```

### 1.10 域级 10: **WriteBack** — 检查点与ODB回写

**职责**: 检查点保存、ODB 增量写入、恢复

**子域** (2 个):
- **Checkpoint** — 检查点管理
- **ODBWrite** — ODB 写入

**功能模块** (4 个):
```
RT_WB_Desc.f90            — 回写配置
RT_WB_Checkpoint.f90      — 检查点保存/恢复
RT_WB_ODB.f90             — ODB 增量写入
RT_WB_Ctx.f90             — 回写上下文
```

### 1.11 域级 11: **Mesh** — 运行时网格

**职责**: 自适应细化、网格重分区、并行负载均衡

**子域** (1 个):
- **Adaptive** — 自适应细化

**功能模块** (2 个):
```
RT_Mesh_Desc.f90          — 网格配置
RT_Mesh_Ctx.f90           — 网格上下文
```

---

## 📊 二、L5_RT 层模块统计

| 序号 | 域级 | 子域数 | 模块数 | 关键功能 | 优先级 |
|------|------|--------|--------|----------|--------|
| 1 | Analysis | 4 | 8 | 求解步驱动 | ⭐⭐⭐ |
| 2 | Assembly | 3 | 6 | 运行时装配 | ⭐⭐⭐ |
| 3 | Material | 2 | 5 | 材料缓存 | ⭐⭐ |
| 4 | Element | 1 | 3 | 单元计算调度 | ⭐⭐ |
| 5 | Coupling | 3 | 7 | 多场耦合 ⭐ NEW | ⭐⭐⭐ |
| 6 | Solver | 2 | 4 | 求解器协调 | ⭐⭐⭐ |
| 7 | Contact | 2 | 3 | 接触管理 | ⭐⭐ |
| 8 | LoadBC | 0 | 2 | 载荷应用 | ⭐⭐ |
| 9 | Output | 2 | 3 | 实时输出 | ⭐⭐ |
| 10 | WriteBack | 2 | 4 | 检查点/ODB | ⭐⭐ |
| 11 | Mesh | 1 | 2 | 运行时网格 | ⭐ |
| **合计** | | **23** | **47** | | |

---

## 🔗 三、命名规范与耦合架构

**层前缀**: `RT_`

**子域前缀示例**:
- Analysis → RT_Analysis_*, RT_StepDriver_*
- Assembly → RT_Assem_*
- Material → RT_Mat_*
- Element → RT_Elem_*
- Coupling → RT_MF_* (Multi-Field，新增)
- Solver → RT_Solv_*
- Contact → RT_Cont_*
- LoadBC → RT_Load_*
- Output → RT_Out_*
- WriteBack → RT_WB_*
- Mesh → RT_Mesh_*

**多场耦合架构关键**:
1. RT_MF_Types.f90 定义 Desc/State/Algo/Ctx 四类 TYPE（阶段1已完成）
2. RT_MF_Coordinator.f90 主协调器（阶段2.5 待实现）
3. 三种耦合策略分别实现（Weak/Strong/FSI）
4. 收敛判据与迭代控制由 RT_MF_Convergence.f90 统一管理

---

## ✅ 交付清单

- ✅ 11 个域级、23 个子域、47 个模块的完整设计
- ✅ Coupling 域级新增，多场耦合架构已规范化
- ✅ RT_MF_Types.f90 已在阶段1实现，四型完整
- ✅ 命名规范统一，与 L4_PH 接口定义清晰

**下一步**: 阶段 2.6 — L6_AP 应用层完整拆解
