# UFC 统一命名方案：层级-域级-功能三级体系

> **已整合至 `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md`，本文冻结 (2026-04-26)。**

> **版本**: v1.0
> **创建日期**: 2026-04-24
> **状态**: 初稿待审查
> **核心使命**: 建立基于层级-域级-功能三级体系的统一命名规范，覆盖TYPE、MODULE、子程序、变量等所有命名场景
> **文档地位**: REPORTS 侧命名 **总则**（三级体系与四场景）；细则与后缀穷尽表见 **命名规范与接口标准 v2.0**；仓库检查入口见 **PPLAN `UFC_命名规范_v3.0.md`**。

---

## 文档元数据

| 属性               | 值                                                                     |
| ------------------ | ---------------------------------------------------------------------- |
| **规范简称** | UFC_Naming_Unified_v1                                                  |
| **上位文档** | `docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`（或当前 v5.x） |
| **相关文档** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md`；`docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md`；`UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md`；`UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md`；`UFC/REPORTS/UFC_过程命名规范_v1.0.md`；`UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md` |
| **核心公式** | **层级前缀 + 域级缩写 + 功能名称 + [场景后缀]**（`[场景后缀]` 新码主模块可省略，见 §3.2 / §3.5） |

---

## 〇、REPORTS 命名文档套件（交叉索引）

| 文档 | 路径 | 职责 |
|------|------|------|
| **本文（统一命名方案）** | `UFC/REPORTS/UFC_统一命名方案_层级域级功能三级体系_v1.0.md` | 三级体系总则；四场景；**默认无 `_Ops`** 与存量双轨 |
| **命名与接口标准 v2** | `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` | 层缀/域缩/铁律；**§3.2 后缀闭集（A–H）** |
| **过程命名规范** | `UFC/REPORTS/UFC_过程命名规范_v1.0.md` | 子程序动词与对内/对外过程名 |
| **功能模块清单** | `UFC/REPORTS/UFC_域级模块详细设计_功能模块清单_v1.0.md` | 分层模块枚举与后缀角色列 |
| **主责正交矩阵** | `docs/05_Project_Planning/PPLAN/06_核心架构/UFC_数据四型×过程四型_主责正交矩阵.md` | 四型字面禁作文件名；ProcKind |
| **PPLAN 命名规范** | `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md` | 仓库既有检查入口 |
| **域级模块规范** | `UFC/REPORTS/UFC_架构设计总纲_域级模块规范_v1.0.md` | 域级目录与 SIO |

**阅读顺序**：本文 → 命名与接口 v2 → 过程命名规范 → 功能模块清单（查表）。

---

## 一、核心公式

### 1.1 统一命名公式

```
层级前缀 + 域级缩写 + 功能名称 + 场景后缀
```

### 1.2 四大命名场景

| 场景                       | 后缀类型     | 公式                               | 示例                                                 |
| -------------------------- | ------------ | ---------------------------------- | ---------------------------------------------------- |
| **1. TYPE定义**      | 四型后缀     | `{层}_{域}_{功能}_{四型}`        | `PH_Mat_Elastic_Desc`                              |
| **2. MODULE/文件名** | 角色后缀或无 | `{层}_{域}_{功能}[{角色}]`       | `PH_Mat_Elastic.f90` 或 `PH_Mat_Elastic_Def.f90` |
| **3. 子程序**        | 动词+具体    | `{层}_{域}_{功能}_{动词}_{具体}` | `PH_Mat_Elastic_Compute_Stress`                    |
| **4. 其他命名**      | 按场景       | 见下文                             | -                                                    |

**场景完整性说明**：

- 当前定义的4个场景覆盖了UFC项目95%以上的命名需求
- 如有特殊场景（如宏定义、模块变量、接口类型等），可按层级-域级-功能三级体系扩展
- 新增场景需遵循统一命名公式，并在本文档中补充

---

## 二、场景1：TYPE定义（四型后缀）

### 2.1 命名公式

```
{层}_{域}_{功能}_{四型}
```

### 2.2 四型后缀规范

| 四型  | 后缀       | 用途              | 示例                     | 承载MODULE    |
| ----- | ---------- | ----------------- | ------------------------ | ------------- |
| Desc  | `_Desc`  | 静态描述/只读配置 | `PH_Mat_Elastic_Desc`  | `*_Def.f90` |
| State | `_State` | 运行时状态        | `PH_Mat_Elastic_State` | `*_Def.f90` |
| Algo  | `_Algo`  | 算法描述符        | `PH_Mat_Elastic_Algo`  | `*_Def.f90` |
| Ctx   | `_Ctx`   | 上下文/控制       | `PH_Mat_Elastic_Ctx`   | `*_Def.f90` |

### 2.3 四型后缀约束

- **仅用于TYPE**：四型后缀**仅用于TYPE定义**，禁止出现在MODULE/文件名上
- **承载位置**：四型TYPE统一定义在 `*_Def.f90` 模块中
- **命名一致性**：同一域内四型TYPE命名风格统一

### 2.4 TYPE定义示例

```fortran
! 在 PH_Mat_Elastic_Def.f90 中
type :: PH_Mat_Elastic_Desc
  real(wp) :: young_modulus
  real(wp) :: poisson_ratio
end type

type :: PH_Mat_Elastic_State
  real(wp) :: stress(6)
  real(wp) :: strain(6)
end type

type :: PH_Mat_Elastic_Algo
  integer :: integration_scheme
end type

type :: PH_Mat_Elastic_Ctx
  real(wp) :: temperature
  logical :: plane_stress
end type
```

---

## 三、场景2：MODULE/文件名（角色后缀双轨制）

> **中间架构层对齐说明（十件套 v2.0）**：`PPLAN/11_闭环落地专项` 的十件套在当前版本按“逻辑职责”解释；文件命名以本节三段式为准。换言之，`_Algo` 是 TYPE/职责概念，主算法文件优先 `{层}_{域}_{功能}.f90`，而非 `*_Algo.f90`。

### 3.1 命名公式

```
{层}_{域}_{功能}[{角色}]
```

**语义三段式（非「下划线必须恰好两段」）**：

- MODULE/文件名必须能解析为 **`{层}_{域}_{功能}[{角色}]`**：`层` 为六层前缀；`域` 为域缩；`功能` 为可检索的功能名或 **已登记的紧凑功能 Token**（可含大小写混排，如 `BrgL3`）；`角色` 为可选专用后缀（`_Def`/`_Brg`/`_Proc`…）或 **存量 `_Ops`**。
- **禁止「层缀 + 单泛词」两段式**（如 `PH_Idx.f90`、`PH_Reg.f90`）：`Idx`/`Reg` 等若单独出现在功能位且未与域缩组合，**无法**唯一定位域语义，易与 TYPE 四型或角色后缀混淆。
- **允许「层缀 + 紧凑功能 Token」**：若 Token 在域契约中登记为完整功能名（等价于「域_功能」压缩），则 **不** 视为禁止的两段式，例如 `PH_BrgL3.f90`（`BrgL3` = Bridge→L3 的登记名）。
- 角色后缀可选；**新码主模块默认无后缀**（见 §3.2）；**L5/SIO 形态保留 `_Proc`**。

**命名长度控制**：

- 总长度建议不超过 **30字符**（不含.f90扩展名）
- 功能位建议不超过 **10字符**
- 角色后缀建议不超过 **6字符**
- 过长的功能位应使用缩写（如Orchestration→Orch，Experience→Exp）
- 缩写应在域级契约文档中定义

### 3.2 新代码推荐（默认无后缀）

| 模块类型     | 命名                          | 示例                        | 说明                     |
| ------------ | ----------------------------- | --------------------------- | ------------------------ |
| 默认计算模块 | `{层}_{域}_{功能}.f90`      | `PH_Mat_Elastic.f90`      | 主计算模块无后缀         |
| 类型定义     | `{层}_{域}_{功能}_Def.f90`  | `PH_Mat_Elastic_Def.f90`  | 承载四型TYPE             |
| 桥接模块     | `{层}_{域}_{功能}_Brg.f90`  | `PH_Bridge_L3_Brg.f90`    | 跨层桥接                 |
| 索引模块     | `{层}_{域}_{功能}_Idx.f90`  | `PH_DOF_Idx.f90`          | 索引管理（Idx作为功能）  |
| 注册模块     | `{层}_{域}_{功能}_Reg.f90`  | `PH_Elem_Reg.f90`         | 注册管理（Reg作为角色）  |
| 映射模块     | `{层}_{域}_{功能}_Map.f90`  | `MD_KW_Map.f90`           | 映射转换（Map作为功能）  |
| 管理器       | `{层}_{域}_{功能}_Mgr.f90`  | `IF_Device_Mgr.f90`       | 管理器（Mgr作为角色）    |
| 外部接口     | `{层}_{域}_{功能}_API.f90`  | `IF_StructFormat_API.f90` | 外部接口（API作为角色）  |
| 控制逻辑     | `{层}_{域}_{功能}_Ctrl.f90` | `RT_Cont_Ctrl.f90`        | 控制逻辑（Ctrl作为角色） |
| SIO过程      | `{层}_{域}_{功能}_Proc.f90` | `RT_Solv_Proc.f90`        | SIO过程（Proc作为角色）  |

**命名约束**（与 §3.1 语义三段式一致）：

- **禁止**「层缀 + 单泛词」两段式；**允许**登记过的紧凑功能 Token（见 §3.1）。
- **层级不重复**：层级前缀已包含层级信息，功能位不应重复层级（如 `PH_L4Idx` → `PH_DOF_Idx`）。
- **功能位可辨**：优先 `{层}_{域}_{功能}` 三分字符界；若压缩 Token，须在域 `CONTRACT.md` 释义。

### 3.3 存量代码保留

| 模块类型 | 命名                         | 示例                               |
| -------- | ---------------------------- | ---------------------------------- |
| 过程主体 | `{层}_{域}_{功能}_Ops.f90` | `PH_Mat_Elastic_Ops.f90`（保留） |

### 3.4 专用后缀闭集（生产代码专用）

> **长表说明**：自 `_Fact` 起多为 **设计模式 / 基础设施类词汇后缀**，作 **命名词汇表与启发**，**非**要求每域各建一对应文件。**生产默认** 优先 **§3.2** 与下表 **至 `_Proc` 行** 的专用后缀；与仓库逐条对拍及 **A–H 组闭集** 见 `UFC/REPORTS/UFC_命名规范与接口标准_v2.0.md` §3.2。

| 后缀                | 用途           | 示例                            | 说明                             |
| ------------------- | -------------- | ------------------------------- | -------------------------------- |
| `_Def`            | TYPE定义       | `PH_Mat_Elastic_Def.f90`      | 承载四型TYPE                     |
| `_Brg`            | 层间桥接       | `PH_Bridge_L3_Brg.f90`        | 跨层适配与数据变换               |
| `_Idx`            | 索引管理       | `PH_DOF_Idx.f90`              | DOF编号、稀疏图、邻接结构        |
| `_Reg`            | 注册管理       | `PH_Elem_Reg.f90`             | 静态注册表、元数据               |
| `_Map`            | 映射转换       | `MD_KW_Map.f90`               | 关键字→内部ID、语义映射         |
| `_Mgr`            | 管理器         | `IF_Device_Mgr.f90`           | 聚合、对外统一入口               |
| `_API`            | 外部接口       | `IF_StructFormat_API.f90`     | Harness/FFI边界封装              |
| `_Ctrl`           | 控制逻辑       | `RT_Cont_Ctrl.f90`            | 控制流、驱动逻辑（可选）         |
| `_Proc`           | SIO过程单元    | `RT_Solv_Proc.f90`            | L5/SIO/Harness形态必需           |
| `_Core`           | 核心实现       | `PH_Mat_Reg_Core.f90`         | 核心算法实现                     |
| `_Eval`           | 求值计算       | `PH_NLGeom_Eval.f90`          | 求值计算入口                     |
| `_Impl`           | 实现专页       | `RT_Step_Impl.f90`            | 实现专页（与入口/策略配对）      |
| `_Exec`           | 执行专页       | `RT_Step_Exec.f90`            | 执行专页（与编排/驱动配对）      |
| `_Loc`            | 局部算子       | `PH_Elem_Loc.f90`             | 局部算子独占（单元/IP级）        |
| `_Glb`            | 全局归约       | `RT_Asm_Glb.f90`              | 全局归约独占（装配级）           |
| `_Asm`            | 装配流水线     | `RT_Asm_Assembly.f90`         | 装配流水线                       |
| `_Sym`            | 符号管理       | `MD_KW_Sym.f90`               | 符号与名字空间                   |
| `_Lib`            | 库函数集       | `MD_Model_Lib.f90`            | 库函数集（静态查表/本构库）      |
| `_Strat`          | 策略选择       | `RT_Solv_Strat.f90`           | 策略选择（求解器/本构分支）      |
| `_Solv`           | 求解内核       | `RT_Solv_Solver.f90`          | 求解内核（迭代解/线搜索）        |
| `_Step`           | 增量控制       | `RT_Step_Step.f90`            | 增量控制（时间步/载荷增量）      |
| `_Run`            | 运行快照       | `RT_Step_Run.f90`             | 运行快照袋（计数/阶段ID）        |
| `_Pop`            | Populate专页   | `PH_Pop_Populate.f90`         | L4 Populate专页                  |
| `_Wb`             | Write-back专页 | `RT_Wb_Writeback.f90`         | Write-back专页                   |
| `_Wsp`            | Workspace      | `RT_Wsp_Workspace.f90`        | Workspace（scratch/缓冲池）      |
| `_Env`            | Environment    | `RT_Env_Environment.f90`      | Environment（MPI/设备/线程拓扑） |
| `_Sync`           | 同步镜像       | `RT_Sync_Sync.f90`            | 双域/双缓冲镜像                  |
| `_Orc`            | 小编排壳       | `RT_Orc_Orchestrator.f90`     | 小编排壳（域内调度）             |
| `_Drv`            | Driver         | `RT_Drv_Driver.f90`           | Driver（步进/作业外壳）          |
| `_Diag`           | 诊断/探针      | `RT_Diag_Diagnostic.f90`      | 诊断/探针（计数/计时）           |
| `_Util`           | 工具函数集     | `NM_Base_Util.f90`            | 工具函数集                       |
| `_Base`           | 基础类         | `NM_Matrix_Base.f90`          | 基础类/抽象基类                  |
| `_Fact`           | 工厂           | `PH_Mat_Fact.f90`             | 工厂模式                         |
| `_Builder`        | 构建器         | `PH_Mat_Builder.f90`          | 构建器模式                       |
| `_Adapter`        | 适配器         | `PH_Bridge_Adapter.f90`       | 适配器模式                       |
| `_Decorator`      | 装饰器         | `PH_Mat_Decorator.f90`        | 装饰器模式                       |
| `_Proxy`          | 代理           | `PH_Mat_Proxy.f90`            | 代理模式                         |
| `_Observer`       | 观察者         | `RT_Step_Observer.f90`        | 观察者模式                       |
| `_Visitor`        | 访问者         | `PH_Elem_Visitor.f90`         | 访问者模式                       |
| `_Iterator`       | 迭代器         | `MD_Mesh_Iterator.f90`        | 迭代器模式                       |
| `_State`          | 状态机         | `RT_Step_State.f90`           | 状态机模式                       |
| `_Command`        | 命令           | `RT_Step_Command.f90`         | 命令模式                         |
| `_Event`          | 事件           | `RT_Step_Event.f90`           | 事件处理                         |
| `_Handler`        | 处理器         | `IF_Err_Handler.f90`          | 异常处理器                       |
| `_Filter`         | 过滤器         | `PH_Field_Filter.f90`         | 数据过滤器                       |
| `_Parser`         | 解析器         | `MD_KW_Parser.f90`            | 数据解析器                       |
| `_Formatter`      | 格式化器       | `IF_IO_Formatter.f90`         | 数据格式化器                     |
| `_Validator`      | 验证器         | `PH_Mat_Validator.f90`        | 数据验证器                       |
| `_Converter`      | 转换器         | `PH_Field_Converter.f90`      | 数据转换器                       |
| `_Generator`      | 生成器         | `MD_Mesh_Generator.f90`       | 数据生成器                       |
| `_Sampler`        | 采样器         | `PH_Field_Sampler.f90`        | 数据采样器                       |
| `_Interpolator`   | 插值器         | `PH_Field_Interpolator.f90`   | 数据插值器                       |
| `_Extrapolator`   | 外推器         | `PH_Field_Extrapolator.f90`   | 数据外推器                       |
| `_Integrator`     | 积分器         | `RT_Time_Integrator.f90`      | 时间积分器                       |
| `_Differentiator` | 微分器         | `PH_Field_Differentiator.f90` | 空间微分器                       |
| `_Normalizer`     | 归一化器       | `PH_Field_Normalizer.f90`     | 数据归一化器                     |
| `_Scaler`         | 缩放器         | `PH_Field_Scaler.f90`         | 数据缩放器                       |
| `_Transformer`    | 变换器         | `PH_Geom_Transformer.f90`     | 几何变换器                       |
| `_Projector`      | 投影器         | `PH_Field_Projector.f90`      | 投影器                           |
| `_Reconstructor`  | 重构器         | `PH_Field_Reconstructor.f90`  | 数据重构器                       |
| `_Decomposer`     | 分解器         | `NM_Matrix_Decomposer.f90`    | 矩阵分解器                       |
| `_Factorizer`     | 因式分解器     | `NM_Matrix_Factorizer.f90`    | 矩阵因式分解器                   |
| `_Solver`         | 求解器         | `RT_Solv_Solver.f90`          | 求解器（通用）                   |
| `_Estimator`      | 估计器         | `RT_Step_Estimator.f90`       | 参数估计器                       |
| `_Predictor`      | 预测器         | `RT_Step_Predictor.f90`       | 预测器                           |
| `_Corrector`      | 校正器         | `RT_Step_Corrector.f90`       | 校正器                           |
| `_Updater`        | 更新器         | `PH_Mat_Updater.f90`          | 状态更新器                       |
| `_Refiner`        | 细化器         | `MD_Mesh_Refiner.f90`         | 网格细化器                       |
| `_Coarsener`      | 粗化器         | `MD_Mesh_Coarsener.f90`       | 网格粗化器                       |
| `_Partitioner`    | 分区器         | `MD_Mesh_Partitioner.f90`     | 网格分区器                       |
| `_Balancer`       | 负载均衡器     | `RT_Asm_Balancer.f90`         | 负载均衡器                       |
| `_Scheduler`      | 调度器         | `RT_Step_Scheduler.f90`       | 任务调度器                       |
| `_Dispatcher`     | 分发器         | `PH_Elem_Dispatcher.f90`      | 任务分发器                       |
| `_Collector`      | 收集器         | `RT_Asm_Collector.f90`        | 数据收集器                       |
| `_Aggregator`     | 聚合器         | `RT_Asm_Aggregator.f90`       | 数据聚合器                       |
| `_Accumulator`    | 累加器         | `RT_Asm_Accumulator.f90`      | 数据累加器                       |
| `_Reducer`        | 归约器         | `RT_Asm_Reducer.f90`          | 数据归约器                       |
| `_Broadcaster`    | 广播器         | `RT_Asm_Broadcaster.f90`      | 数据广播器                       |
| `_Scatterer`      | 散布器         | `RT_Asm_Scatterer.f90`        | 数据散布器                       |
| `_Gatherer`       | 收集器         | `RT_Asm_Gatherer.f90`         | 数据收集器                       |
| `_Barrier`        | 屏障           | `RT_Step_Barrier.f90`         | 同步屏障                         |
| `_Lock`           | 锁             | `RT_Asm_Lock.f90`             | 锁机制                           |
| `_Semaphore`      | 信号量         | `RT_Asm_Semaphore.f90`        | 信号量                           |
| `_Mutex`          | 互斥锁         | `RT_Asm_Mutex.f90`            | 互斥锁                           |
| `_Condition`      | 条件变量       | `RT_Asm_Condition.f90`        | 条件变量                         |
| `_RWLock`         | 读写锁         | `RT_Asm_RWLock.f90`           | 读写锁                           |
| `_SpinLock`       | 自旋锁         | `RT_Asm_SpinLock.f90`         | 自旋锁                           |
| `_Atomic`         | 原子操作       | `RT_Asm_Atomic.f90`           | 原子操作                         |
| `_Cache`          | 缓存           | `IF_Mem_Cache.f90`            | 缓存机制                         |
| `_Buffer`         | 缓冲区         | `IF_IO_Buffer.f90`            | 缓冲区                           |
| `_Pool`           | 池             | `IF_Mem_Pool.f90`             | 对象池/线程池                    |
| `_Queue`          | 队列           | `RT_Task_Queue.f90`           | 任务队列                         |
| `_Stack`          | 栈             | `RT_Task_Stack.f90`           | 任务栈                           |
| `_Heap`           | 堆             | `RT_Task_Heap.f90`            | 任务堆                           |
| `_Priority`       | 优先级         | `RT_Task_Priority.f90`        | 优先级队列                       |
| `_FIFO`           | 先进先出       | `RT_Task_FIFO.f90`            | FIFO队列                         |
| `_LIFO`           | 后进先出       | `RT_Task_LIFO.f90`            | LIFO栈                           |
| `_Ring`           | 环形缓冲       | `IF_IO_Ring.f90`              | 环形缓冲区                       |
| `_Circular`       | 循环           | `RT_Step_Circular.f90`        | 循环缓冲                         |
| `_Double`         | 双缓冲         | `RT_Asm_Double.f90`           | 双缓冲                           |
| `_Triple`         | 三缓冲         | `RT_Asm_Triple.f90`           | 三缓冲                           |

**后缀使用原则**：

- 优先使用专用后缀闭集中的后缀
- 新增后缀需符合后缀语义，避免与现有后缀冲突
- 后缀应简洁明确，避免过长或模糊的后缀
- **§3.4 长表行数 ≠ 生产必建模块数**：默认闭集以 **§3.2 + 本节表首专用后缀** 为准；超长枚举仅防命名碰撞时的参考
- **仅用于生产代码**：此闭集仅用于生产代码，测试/演示代码使用单独的后缀集合
- **设计模式后缀**：设计模式相关后缀（`_Fact`/`_Builder`/`_Adapter`等）仅在明确使用该模式时使用
- **并发后缀**：并发相关后缀（`_Lock`/`_Mutex`/`_Atomic`等）仅在并发场景使用

### 3.5 后缀双轨制原则

1. **新代码/新域推荐原则**：默认主计算文件无后缀；专用后缀仅在有明确非默认角色时出现
2. **存量代码保留**：现有 `*_Ops.f90` 长期保留，不强制批量改名
3. **增量代码鼓励**：新域或新拆分文件鼓励使用无后缀格式
4. **域内约定**：各域可在 `CONTRACT.md` 中声明「本域主模块无 `_Ops` 后缀」

### 3.6 十件套 v2.0 命名映射（防冲突口径）

为避免与旧十件套文档（`_Algo.f90`、`_Desc.f90` 等文件示例）冲突，命名解释统一如下：

| 十件套逻辑件 | 命名落地（本规范） | 备注 |
|---|---|---|
| Def / 四型定义 | `*_Def.f90` | 四型 TYPE（`*_Desc/State/Algo/Ctx`）优先集中在 Def |
| Main Algorithm | `{层}_{域}_{功能}.f90` | 主模块默认无 `_Ops` / `_Algo` |
| Bridge | `*_Brg.f90` | 跨层防腐与上下文切片 |
| Proc (SIO) | `*_Proc.f90` | L5/SIO/Harness 入口保留 |
| Registry / Index / Map | `*_Reg.f90` / `*_Idx.f90` / `*_Map.f90` | 角色明确才使用后缀 |

参考：`docs/05_Project_Planning/PPLAN/11_闭环落地专项/05_中间架构层新版总纲_全景套件v3.0.md`。
5. **Ops后缀使用原则**：
   - **优先使用专用后缀**：有明确角色时优先使用专用后缀（`_Def`/`_Brg`/`_Idx`/`_Reg`/`_Map`/`_Mgr`/`_API`/`_Ctrl`/`_Proc`）
   - **Ops作为兜底**：仅在无法归入专用后缀时使用 `_Ops` 后缀
   - **逐步替换**：在域级打通过程中，逐步将存量 `*_Ops.f90` 替换为专用后缀或无后缀
   - **避免大量使用**：新代码应尽量避免大量使用 `_Ops` 后缀，提升命名可读性

### 3.6 测试/演示代码后缀集合

**使用范围**：以下后缀仅用于测试、演示、教程等非生产代码，禁止在生产代码中使用

| 后缀          | 用途     | 示例                            | 说明                         |
| ------------- | -------- | ------------------------------- | ---------------------------- |
| `_Test`     | 单元测试 | `PH_Mat_Elastic_Test.f90`     | 单元测试模块                 |
| `_Mock`     | 模拟对象 | `PH_Mat_Elastic_Mock.f90`     | 模拟对象（用于测试）         |
| `_Stub`     | 桩模块   | `PH_Mat_Elastic_Stub.f90`     | 桩模块（接口占位，用于测试） |
| `_Demo`     | 演示     | `PH_Mat_Elastic_Demo.f90`     | 演示模块                     |
| `_Example`  | 示例     | `PH_Mat_Elastic_Example.f90`  | 示例模块                     |
| `_Tutorial` | 教程     | `PH_Mat_Elastic_Tutorial.f90` | 教程模块                     |

**使用原则**：

- **仅用于非生产代码**：测试/演示代码目录（如 `tests/`、`examples/`、`tutorials/`）
- **禁止混入生产代码**：生产代码目录（`ufc_core/`）禁止使用这些后缀
- **命名遵循三段式**：测试/演示代码也必须遵循 `{层}_{域}_{功能}[{角色}]` 三段式
- **与生产代码对应**：测试模块命名应与被测生产模块对应，便于查找

### 3.7 跨层桥接模块命名规则

**命名公式**：`{层}_{域}_{功能}_Brg.f90`

**规则说明**：

- **域级为Bridge**：跨层桥接模块的域级统一使用 `Bridge`
- **功能位标明目标层**：功能位标明桥接的目标层（如 `L3`、`L4`、`L5`）
- **示例**：
  - `PH_Bridge_L3_Brg.f90`：L4层桥接到L3层
  - `RT_Bridge_L4_Brg.f90`：L5层桥接到L4层
  - `MD_Bridge_L2_Brg.f90`：L3层桥接到L2层

**与 §3.1 一致（禁止「层缀+单泛词」；允许登记紧凑 Token）**：

- **推荐（新码）**：显式三分界 `PH_Bridge_L3_Brg.f90`（域=`Bridge`，功能=`L3`，角色=`Brg`），可读性最好。
- **允许（存量或契约登记）**：`PH_BrgL3.f90` 等 **紧凑功能 Token**（`BrgL3` 在域 `CONTRACT.md` 释义），与 §3.1「层缀 + 紧凑功能 Token」同条。
- **禁止**：`PH_Brg.f90`、`PH_L3.f90` 等 **语义不完整** 或无法唯一定位桥接对象的命名。

### 3.8 索引模块命名规则

**命名公式**：`{层}_{域}_{功能}_Idx.f90`

**规则说明**：

- **域级为索引对象**：索引模块的域级标明索引的对象（如 `DOF`、`Node`、`Elem`）
- **功能位为Idx**：索引模块的功能位统一使用 `Idx`
- **示例**：
  - `PH_DOF_Idx.f90`：DOF索引管理
  - `PH_Node_Idx.f90`：节点索引管理
  - `PH_Elem_Idx.f90`：单元索引管理

**禁止「层缀 + 单泛词」**（见 §3.1）：

- 禁止 `PH_Idx.f90`（`Idx` 单独作功能位、无索引对象域语义）。
- **必须** 带索引对象域，如 `PH_DOF_Idx.f90`、`PH_Node_Idx.f90`。

### 3.9 复合角色处理

对于同时表达多个角色的文件，遵循以下原则：

- **禁止复合后缀**：禁止使用多个后缀（如 `PH_DOF_Idx_Brg.f90`）
- **优先选择主角色**：选择最核心的角色作为后缀
- **合成到功能位**：复合角色信息合成到功能位（如 `PH_DOFIdx_Brg.f90` → `PH_DOFIdx_Brg.f90`）
- **域内约定**：在 `CONTRACT.md` 中明确角色优先级规则

**示例**：

- 索引+桥接：`PH_DOFIdx_Brg.f90`（功能位合成，后缀为主角色）
- 注册+管理：`PH_ElemReg_Mgr.f90`（功能位合成，后缀为主角色）

### 3.10 迁移策略

1. **不强制改名**：存量 `*_Ops.f90` 可保留
2. **域内迁移**：在域级打通过程中逐步统一到新风格
3. **新代码优先**：新拆分文件优先使用无后缀格式
4. **工具支持**：命名检查器同时支持新旧两种格式

---

## 四、场景3：子程序命名（动词+具体）

### 4.1 命名公式

```
{层}_{域}_{功能}_{动词}_{具体}
```

### 4.2 标准动词集合

| 动词             | 用途     | 示例                                 |
| ---------------- | -------- | ------------------------------------ |
| `Init`         | 初始化   | `PH_Mat_Elastic_Init`              |
| `Compute`      | 计算     | `PH_Mat_Elastic_Compute_Stress`    |
| `Update`       | 更新     | `PH_Mat_Elastic_Update_State`      |
| `Validate`     | 验证     | `PH_Mat_Elastic_Validate`          |
| `Finalize`     | 终结     | `PH_Mat_Elastic_Finalize`          |
| `Get`          | 获取     | `PH_Mat_Elastic_Get_Property`      |
| `Set`          | 设置     | `PH_Mat_Elastic_Set_Property`      |
| `Check`        | 检查     | `PH_Mat_Elastic_Check_Convergence` |
| `Build`        | 构建     | `RT_Asm_Build_DofMap`              |
| `Solve`        | 求解     | `RT_Solv_Solve_Linear`             |
| `Dispatch`     | 分发     | `PH_Elem_Dispatch_Ke`              |
| `Register`     | 注册     | `MD_Mat_Register`                  |
| `Lookup`       | 查找     | `MD_Mat_Lookup`                    |
| `Assemble`     | 装配     | `RT_Asm_Assemble_Global`           |
| `Reduce`       | 归约     | `RT_Asm_Reduce_Global`             |
| `Evaluate`     | 求值     | `PH_Mat_Elastic_Evaluate`          |
| `Allocate`     | 分配     | `IF_Mem_Allocate_Chunk`            |
| `Deallocate`   | 释放     | `IF_Mem_Deallocate_Chunk`          |
| `Read`         | 读取     | `IF_IO_File_Read`                  |
| `Write`        | 写入     | `IF_IO_File_Write`                 |
| `Open`         | 打开     | `IF_IO_File_Open`                  |
| `Close`        | 关闭     | `IF_IO_File_Close`                 |
| `Create`       | 创建     | `IF_IO_File_Create`                |
| `Destroy`      | 销毁     | `IF_Mem_Destroy_Chunk`             |
| `Copy`         | 复制     | `IF_Mem_Copy_Chunk`                |
| `Move`         | 移动     | `IF_Mem_Move_Chunk`                |
| `Resize`       | 调整大小 | `IF_Mem_Resize_Chunk`              |
| `Reset`        | 重置     | `PH_Mat_Elastic_Reset`             |
| `Clear`        | 清除     | `RT_Asm_Clear_Global`              |
| `Push`         | 压入     | `RT_Stack_Push`                    |
| `Pop`          | 弹出     | `RT_Stack_Pop`                     |
| `Insert`       | 插入     | `MD_Mesh_Insert_Node`              |
| `Remove`       | 移除     | `MD_Mesh_Remove_Node`              |
| `Find`         | 查找     | `MD_Mesh_Find_Node`                |
| `Sort`         | 排序     | `RT_Asm_Sort_DofMap`               |
| `Merge`        | 合并     | `RT_Asm_Merge_Global`              |
| `Split`        | 分割     | `RT_Asm_Split_Global`              |
| `Transform`    | 变换     | `PH_Field_Transform`               |
| `Convert`      | 转换     | `PH_Field_Convert`                 |
| `Map`          | 映射     | `MD_KW_Map_Value`                  |
| `Apply`        | 应用     | `PH_Mat_Elastic_Apply`             |
| `Process`      | 处理     | `RT_Step_Process`                  |
| `Execute`      | 执行     | `RT_Step_Execute`                  |
| `Run`          | 运行     | `RT_Step_Run`                      |
| `Start`        | 启动     | `RT_Step_Start`                    |
| `Stop`         | 停止     | `RT_Step_Stop`                     |
| `Pause`        | 暂停     | `RT_Step_Pause`                    |
| `Resume`       | 恢复     | `RT_Step_Resume`                   |
| `Abort`        | 中止     | `RT_Step_Abort`                    |
| `Connect`      | 连接     | `PH_Brg_Connect`                   |
| `Disconnect`   | 断开     | `PH_Brg_Disconnect`                |
| `Bind`         | 绑定     | `PH_Brg_Bind`                      |
| `Unbind`       | 解绑     | `PH_Brg_Unbind`                    |
| `Link`         | 链接     | `PH_Brg_Link`                      |
| `Unlink`       | 解链     | `PH_Brg_Unlink`                    |
| `Load`         | 加载     | `MD_Model_Load`                    |
| `Save`         | 保存     | `MD_Model_Save`                    |
| `Import`       | 导入     | `MD_Model_Import`                  |
| `Export`       | 导出     | `MD_Model_Export`                  |
| `Parse`        | 解析     | `MD_KW_Parse`                      |
| `Serialize`    | 序列化   | `MD_Model_Serialize`               |
| `Deserialize`  | 反序列化 | `MD_Model_Deserialize`             |
| `Encode`       | 编码     | `IF_IO_Encode`                     |
| `Decode`       | 解码     | `IF_IO_Decode`                     |
| `Compress`     | 压缩     | `IF_IO_Compress`                   |
| `Decompress`   | 解压     | `IF_IO_Decompress`                 |
| `Encrypt`      | 加密     | `IF_IO_Encrypt`                    |
| `Decrypt`      | 解密     | `IF_IO_Decrypt`                    |
| `Hash`         | 哈希     | `IF_IO_Hash`                       |
| `Sign`         | 签名     | `IF_IO_Sign`                       |
| `Verify`       | 验证签名 | `IF_IO_Verify`                     |
| `Authenticate` | 认证     | `IF_IO_Authenticate`               |
| `Authorize`    | 授权     | `IF_IO_Authorize`                  |
| `Login`        | 登录     | `IF_IO_Login`                      |
| `Logout`       | 登出     | `IF_IO_Logout`                     |
| `Lock`         | 锁定     | `RT_Asm_Lock`                      |
| `Unlock`       | 解锁     | `RT_Asm_Unlock`                    |
| `Acquire`      | 获取     | `RT_Asm_Acquire`                   |
| `Release`      | 释放     | `RT_Asm_Release`                   |
| `Wait`         | 等待     | `RT_Step_Wait`                     |
| `Notify`       | 通知     | `RT_Step_Notify`                   |
| `Signal`       | 信号     | `RT_Step_Signal`                   |
| `Broadcast`    | 广播     | `RT_Step_Broadcast`                |
| `Gather`       | 收集     | `RT_Asm_Gather`                    |
| `Scatter`      | 散布     | `RT_Asm_Scatter`                   |
| `AllReduce`    | 全归约   | `RT_Asm_AllReduce`                 |
| `Barrier`      | 屏障     | `RT_Step_Barrier`                  |
| `Sync`         | 同步     | `RT_Step_Sync`                     |
| `Async`        | 异步     | `RT_Step_Async`                    |

**动词使用原则**：

- 优先使用标准动词集合中的动词
- 新增动词需符合动词语义，避免与现有动词冲突
- 动词应简洁明确，避免过长或模糊的动词

### 4.3 子程序命名示例

| 场景         | 子程序名                             | 说明             |
| ------------ | ------------------------------------ | ---------------- |
| 初始化       | `PH_Mat_Elastic_Init`              | 初始化弹性材料   |
| 计算应力     | `PH_Mat_Elastic_Compute_Stress`    | 计算应力         |
| 计算切线模量 | `PH_Mat_Elastic_Compute_Tangent`   | 计算切线模量     |
| 更新状态     | `PH_Mat_Elastic_Update_State`      | 更新材料状态     |
| 验证输入     | `PH_Mat_Elastic_Validate`          | 验证输入参数     |
| 获取属性     | `PH_Mat_Elastic_Get_Property`      | 获取材料属性     |
| 设置属性     | `PH_Mat_Elastic_Set_Property`      | 设置材料属性     |
| 检查收敛     | `PH_Mat_Elastic_Check_Convergence` | 检查收敛性       |
| 构建DOF映射  | `RT_Asm_Build_DofMap`              | 构建自由度映射   |
| 求解线性系统 | `RT_Solv_Solve_Linear`             | 求解线性系统     |
| 装配全局     | `RT_Asm_Assemble_Global`           | 装配全局矩阵     |
| 分发计算     | `PH_Elem_Dispatch_Ke`              | 分发单元刚度计算 |
| 注册材料     | `MD_Mat_Register`                  | 注册材料类型     |
| 查找材料     | `MD_Mat_Lookup`                    | 查找材料类型     |
| 分配内存     | `IF_Mem_Allocate_Chunk`            | 分配内存块       |
| 释放内存     | `IF_Mem_Deallocate_Chunk`          | 释放内存块       |
| 归约全局     | `RT_Asm_Reduce_Global`             | 全局归约         |

### 4.4 子程序命名约束

- **动词优先**：子程序名必须包含标准动词
- **具体描述**：动词后必须跟具体操作对象或属性
- **层级前缀**：所有子程序必须以层级前缀开头
- **域级缩写**：子程序名必须包含域级缩写
- **功能名称**：子程序名必须包含功能名称
- **PascalCase**：子程序名使用PascalCase风格

---

## 五、场景4：其他命名

### 5.1 变量命名

| 变量类型 | 命名风格                           | 示例                                   |
| -------- | ---------------------------------- | -------------------------------------- |
| 局部变量 | `snake_case`                     | `stress_tensor`, `strain_energy`   |
| 四型实例 | 简写缩写                           | `desc`, `state`, `algo`, `ctx` |
| 参数     | `snake_case` 或 `UPPER_SNAKE`  | `max_iter`, `MAX_ITER`             |
| 全局常量 | `UPPER_SNAKE`                    | `PI`, `TOLERANCE`                  |
| 数组变量 | `snake_case` + `_array` 或复数 | `stress_array`, `stresses`         |
| 指针变量 | `snake_case` + `_ptr`          | `data_ptr`                           |
| 循环变量 | 单字母或简短                       | `i`, `j`, `k`, `idx`           |

### 5.2 常量命名

| 常量类型   | 命名风格        | 示例                        |
| ---------- | --------------- | --------------------------- |
| 物理常量   | `UPPER_SNAKE` | `PI`, `GRAVITY`         |
| 数值常量   | `UPPER_SNAKE` | `TOLERANCE`, `MAX_ITER` |
| 字符串常量 | `UPPER_SNAKE` | `DEFAULT_FILE_NAME`       |
| 布尔常量   | `UPPER_SNAKE` | `TRUE`, `FALSE`         |

### 5.3 接口参数命名（SIO Arg Bundle）

| 参数类型     | 命名风格   | 示例        | 说明                                        |
| ------------ | ---------- | ----------- | ------------------------------------------- |
| 输入参数     | `{功能}` | `Elastic` | 通过 `intent(in)` 注释表明输入属性        |
| 输出参数     | `{功能}` | `Elastic` | 通过 `intent(out)` 注释表明输出属性       |
| 输入输出参数 | `{功能}` | `Elastic` | 通过 `intent(inout)` 注释表明输入输出属性 |

**命名原则**：

- 参数命名不使用 `_In`/`_Out`/`_InOut` 后缀
- 通过 Fortran 的 `intent()` 属性明确参数方向
- 参数命名应简洁，避免冗余后缀

### 5.4 枚举命名

| 枚举类型 | 命名风格                  | 示例                                           |
| -------- | ------------------------- | ---------------------------------------------- |
| 枚举类型 | `{层}_{域}_{功能}_Enum` | `PH_Mat_Elastic_Enum`                        |
| 枚举值   | `UPPER_SNAKE`           | `ELASTIC_ISOTROPIC`, `ELASTIC_ORTHOTROPIC` |

### 5.5 宏定义命名

| 宏类型   | 命名风格        | 示例                                     |
| -------- | --------------- | ---------------------------------------- |
| 编译开关 | `UPPER_SNAKE` | `ENABLE_DEBUG`, `USE_MPI`            |
| 常量宏   | `UPPER_SNAKE` | `MAX_ITERATIONS`, `TOLERANCE`        |
| 条件编译 | `UPPER_SNAKE` | `IF_DEBUG`, `IF_RELEASE`             |
| 平台相关 | `UPPER_SNAKE` | `PLATFORM_LINUX`, `PLATFORM_WINDOWS` |

**命名原则**：

- 宏定义使用 `UPPER_SNAKE` 风格
- 宏名应简洁明确，避免过长
- 宏名应包含前缀以避免冲突（如 `UFC_` 前缀）

### 5.6 模块变量命名

| 变量类型       | 命名风格                 | 示例                            |
| -------------- | ------------------------ | ------------------------------- |
| 模块级私有变量 | `snake_case` + `_m`  | `max_iter_m`, `tolerance_m` |
| 模块级公共变量 | `snake_case` + `_g`  | `global_config_g`             |
| 模块级常量     | `UPPER_SNAKE` + `_M` | `MAX_ITER_M`, `TOLERANCE_M` |
| 模块级参数     | `snake_case` + `_p`  | `precision_p`                 |

**命名原则**：

- 模块级变量使用后缀区分作用域（`_m`私有、`_g`公共、`_M`常量、`_p`参数）
- 避免使用全局变量，优先使用模块封装
- 模块级变量应在模块文档中说明其用途

### 5.7 接口命名

| 接口类型 | 命名风格                       | 示例                         |
| -------- | ------------------------------ | ---------------------------- |
| 抽象接口 | `{层}_{域}_{功能}_Interface` | `PH_Mat_Elastic_Interface` |
| 过程指针 | `{层}_{域}_{功能}_ProcPtr`   | `PH_Mat_Elastic_ProcPtr`   |

### 5.8 函数指针命名

| 指针类型     | 命名风格             | 示例                       |
| ------------ | -------------------- | -------------------------- |
| 计算函数指针 | `{功能}_FuncPtr`   | `Compute_Stress_FuncPtr` |
| 回调函数指针 | `{功能}_Callback`  | `Update_State_Callback`  |
| 事件处理器   | `{功能}_Handler`   | `Error_Handler`          |
| 谓词函数     | `{功能}_Predicate` | `Is_Converged_Predicate` |

### 5.9 回调函数命名

| 回调类型   | 命名风格               | 示例                 |
| ---------- | ---------------------- | -------------------- |
| 初始化回调 | `On_{功能}_Init`     | `On_Material_Init` |
| 更新回调   | `On_{功能}_Update`   | `On_State_Update`  |
| 错误回调   | `On_{功能}_Error`    | `On_Compute_Error` |
| 完成回调   | `On_{功能}_Complete` | `On_Step_Complete` |

### 5.10 配置文件命名

| 文件类型 | 命名风格        | 示例              |
| -------- | --------------- | ----------------- |
| 配置文件 | `{功能}.conf` | `solver.conf`   |
| JSON配置 | `{功能}.json` | `material.json` |
| YAML配置 | `{功能}.yaml` | `mesh.yaml`     |
| INI配置  | `{功能}.ini`  | `output.ini`    |

### 5.11 数据文件命名

| 文件类型 | 命名风格               | 示例                        |
| -------- | ---------------------- | --------------------------- |
| 输入文件 | `{功能}_{描述}.inp`  | `model_cantilever.inp`    |
| 输出文件 | `{功能}_{描述}.out`  | `result_displacement.out` |
| 数据文件 | `{功能}_{描述}.dat`  | `field_stress.dat`        |
| 网格文件 | `{功能}_{描述}.mesh` | `mesh_refined.mesh`       |

### 5.12 脚本文件命名

| 脚本类型   | 命名风格       | 示例                  |
| ---------- | -------------- | --------------------- |
| Python脚本 | `{功能}.py`  | `run_simulation.py` |
| Shell脚本  | `{功能}.sh`  | `setup_env.sh`      |
| 批处理脚本 | `{功能}.bat` | `run_test.bat`      |
| Makefile   | `Makefile`   | `Makefile`          |

### 5.13 文档文件命名

| 文档类型     | 命名风格        | 示例              |
| ------------ | --------------- | ----------------- |
| Markdown文档 | `{功能}.md`   | `README.md`     |
| PDF文档      | `{功能}.pdf`  | `manual.pdf`    |
| HTML文档     | `{功能}.html` | `api.html`      |
| 文本文档     | `{功能}.txt`  | `changelog.txt` |

### 5.14 测试文件命名

| 测试类型 | 命名风格                        | 示例                            |
| -------- | ------------------------------- | ------------------------------- |
| 单元测试 | `test_{功能}.f90`             | `test_material.f90`           |
| 集成测试 | `test_{功能}_integration.f90` | `test_solver_integration.f90` |
| 性能测试 | `test_{功能}_perf.f90`        | `test_assembly_perf.f90`      |
| 回归测试 | `test_{功能}_regression.f90`  | `test_contact_regression.f90` |

### 5.15 示例文件命名

| 示例类型 | 命名风格                | 示例                    |
| -------- | ----------------------- | ----------------------- |
| 示例代码 | `example_{功能}.f90`  | `example_elastic.f90` |
| 演示代码 | `demo_{功能}.f90`     | `demo_contact.f90`    |
| 教程代码 | `tutorial_{功能}.f90` | `tutorial_mesh.f90`   |

---

## 六、命名冲突处理规则

### 6.1 命名冲突场景

| 冲突场景       | 示例                                                 | 处理规则                   |
| -------------- | ---------------------------------------------------- | -------------------------- |
| 同层同名不同域 | `PH_Mat_Elastic.f90` vs `PH_Field_Elastic.f90`   | 允许，域级区分             |
| 跨层同名同域   | `PH_Mat_Elastic.f90` vs `MD_Mat_Elastic.f90`     | 允许，层级区分             |
| 同层同域同名   | `PH_Mat_Elastic.f90` vs `PH_Mat_Elastic_Def.f90` | 允许，后缀区分             |
| 子程序名冲突   | `PH_Mat_Elastic_Compute_Stress` 在多个模块中       | 通过 `USE` 语句限定      |
| 变量名冲突     | 局部变量与模块变量同名                               | 局部变量优先，避免命名冲突 |

### 6.2 冲突处理原则

1. **层级优先**：跨层同名通过层级前缀区分
2. **域级区分**：同层同名通过域级缩写区分
3. **后缀区分**：同层同域同名通过后缀区分
4. **作用域限定**：子程序冲突通过 `USE` 语句限定
5. **避免冲突**：命名时应尽量避免可能的冲突

### 6.3 冲突预防措施

- **命名前检查**：在命名前检查是否已存在相同命名
- **使用工具**：使用命名检查工具自动检测冲突
- **域内约定**：在 `CONTRACT.md` 中明确命名约定
- **文档记录**：在模块文档中记录命名依赖关系

---

## 七、命名检查工具规范

### 7.1 工具功能要求

| 功能           | 说明                            | 优先级 |
| -------------- | ------------------------------- | ------ |
| 三段式检查     | 检查MODULE/文件名是否遵循三段式 | 高     |
| 后缀检查       | 检查后缀是否在专用后缀闭集中    | 高     |
| 层级重复检查   | 检查功能位是否重复层级信息      | 高     |
| 四型后缀检查   | 检查四型后缀是否仅用于TYPE      | 高     |
| 命名冲突检查   | 检查是否存在命名冲突            | 中     |
| 子程序命名检查 | 检查子程序名是否包含标准动词    | 中     |
| 变量命名检查   | 检查变量命名风格                | 低     |

### 7.2 工具使用规范

1. **CI集成**：命名检查工具应集成到CI流程
2. **提交前检查**：代码提交前必须通过命名检查
3. **域级检查**：域级打通时进行全域命名检查
4. **定期检查**：定期进行全仓库命名检查
5. **报告生成**：生成命名检查报告，记录问题

### 7.3 工具配置

| 配置项      | 说明               | 默认值                    |
| ----------- | ------------------ | ------------------------- |
| 检查模式    | 严格/宽松          | 严格                      |
| 紧凑 Token | `PH_<Token>` 无显式域段时是否通过 | 仅当 Token 在域契约白名单（§3.1） |
| 允许Ops后缀 | 是否允许Ops后缀    | 是（存量代码）            |
| 检查目录    | 检查的目录列表     | `ufc_core/`             |
| 排除目录    | 排除的目录列表     | `tests/`, `examples/` |

---

## 八、命名迁移最佳实践

### 8.1 迁移策略

1. **分阶段迁移**：按域级分阶段进行迁移
2. **优先新代码**：新代码优先使用新命名规范
3. **逐步替换**：存量代码逐步替换为专用后缀
4. **保持兼容**：迁移过程中保持向后兼容
5. **文档同步**：迁移后同步更新文档

### 8.2 迁移步骤

| 步骤        | 说明                         | 责任人 |
| ----------- | ---------------------------- | ------ |
| 1. 命名检查 | 使用命名检查工具检查当前命名 | 开发者 |
| 2. 制定计划 | 制定域级命名迁移计划         | 架构师 |
| 3. 修改命名 | 按计划修改MODULE/文件名      | 开发者 |
| 4. 更新引用 | 更新所有引用该MODULE的代码   | 开发者 |
| 5. 测试验证 | 运行测试验证迁移正确性       | 开发者 |
| 6. 文档更新 | 更新相关文档                 | 开发者 |
| 7. 代码审查 | 进行代码审查                 | 审查者 |

### 8.3 迁移注意事项

- **避免大规模改名**：避免一次性大规模改名
- **保持功能不变**：迁移过程中保持功能不变
- **测试覆盖**：确保测试覆盖所有改动的代码
- **回滚准备**：准备回滚方案，以防迁移失败
- **团队沟通**：迁移前与团队充分沟通

---

## 九、命名规范版本管理策略

### 9.1 版本号规则

命名规范文档采用 `v{主版本}.{次版本}` 格式：

- **主版本**：重大变更，不兼容旧版本
- **次版本**：小变更，兼容旧版本

### 9.2 版本发布流程

| 阶段 | 说明                 | 责任人 |
| ---- | -------------------- | ------ |
| 草稿 | 初稿，供团队审查     | 架构师 |
| 审查 | 团队审查，收集反馈   | 团队   |
| 修订 | 根据反馈修订         | 架构师 |
| 发布 | 正式发布，更新版本号 | 架构师 |
| 培训 | 团队培训，讲解变更   | 架构师 |

### 9.3 版本兼容性

- **向后兼容**：次版本更新应保持向后兼容
- **迁移指南**：主版本更新应提供迁移指南
- **过渡期**：主版本更新后设置过渡期
- **工具支持**：命名检查工具支持多版本规范

### 9.4 版本记录

在文档中记录版本变更：

- 变更日期
- 变更内容
- 变更原因
- 影响范围

---

## 十、完整示例

### 10.1 示例域：L4_PH/Material/Elas/

#### TYPE定义（在 `PH_Mat_Elastic_Def.f90` 中）

```fortran
module PH_Mat_Elastic_Def
  use IF_Prec_Algo, only: wp
  implicit none
  private
  public :: PH_Mat_Elastic_Desc
  public :: PH_Mat_Elastic_State
  public :: PH_Mat_Elastic_Algo
  public :: PH_Mat_Elastic_Ctx

  type :: PH_Mat_Elastic_Desc
    real(wp) :: young_modulus
    real(wp) :: poisson_ratio
  end type

  type :: PH_Mat_Elastic_State
    real(wp) :: stress(6)
    real(wp) :: strain(6)
  end type

  type :: PH_Mat_Elastic_Algo
    integer :: integration_scheme
  end type

  type :: PH_Mat_Elastic_Ctx
    real(wp) :: temperature
    logical :: plane_stress
  end type

end module PH_Mat_Elastic_Def
```

#### MODULE/文件名

| 文件名                     | MODULE名               | 说明                     |
| -------------------------- | ---------------------- | ------------------------ |
| `PH_Mat_Elastic.f90`     | `PH_Mat_Elastic`     | 主计算模块（新代码推荐） |
| `PH_Mat_Elastic_Def.f90` | `PH_Mat_Elastic_Def` | 类型定义模块             |
| `PH_Mat_Elastic_Ops.f90` | `PH_Mat_Elastic_Ops` | 存量保留                 |

#### 子程序命名（在 `PH_Mat_Elastic.f90` 中）

```fortran
module PH_Mat_Elastic
  use PH_Mat_Elastic_Def
  implicit none
  private
  public :: PH_Mat_Elastic_Init
  public :: PH_Mat_Elastic_Compute_Stress
  public :: PH_Mat_Elastic_Compute_Tangent
  public :: PH_Mat_Elastic_Update_State
  public :: PH_Mat_Elastic_Validate
  public :: PH_Mat_Elastic_Finalize

contains

  subroutine PH_Mat_Elastic_Init(desc, state, algo, ctx, status)
    type(PH_Mat_Elastic_Desc), intent(in) :: desc
    type(PH_Mat_Elastic_State), intent(out) :: state
    type(PH_Mat_Elastic_Algo), intent(in) :: algo
    type(PH_Mat_Elastic_Ctx), intent(in) :: ctx
    integer, intent(out) :: status
    ! 实现省略
  end subroutine

  subroutine PH_Mat_Elastic_Compute_Stress(desc, state, algo, ctx, status)
    type(PH_Mat_Elastic_Desc), intent(in) :: desc
    type(PH_Mat_Elastic_State), intent(inout) :: state
    type(PH_Mat_Elastic_Algo), intent(in) :: algo
    type(PH_Mat_Elastic_Ctx), intent(in) :: ctx
    integer, intent(out) :: status
    ! 实现省略
  end subroutine

  subroutine PH_Mat_Elastic_Compute_Tangent(desc, state, algo, ctx, status)
    type(PH_Mat_Elastic_Desc), intent(in) :: desc
    type(PH_Mat_Elastic_State), intent(in) :: state
    type(PH_Mat_Elastic_Algo), intent(in) :: algo
    type(PH_Mat_Elastic_Ctx), intent(in) :: ctx
    integer, intent(out) :: status
    ! 实现省略
  end subroutine

  subroutine PH_Mat_Elastic_Update_State(desc, state, algo, ctx, status)
    type(PH_Mat_Elastic_Desc), intent(in) :: desc
    type(PH_Mat_Elastic_State), intent(inout) :: state
    type(PH_Mat_Elastic_Algo), intent(in) :: algo
    type(PH_Mat_Elastic_Ctx), intent(in) :: ctx
    integer, intent(out) :: status
    ! 实现省略
  end subroutine

  subroutine PH_Mat_Elastic_Validate(desc, state, algo, ctx, status)
    type(PH_Mat_Elastic_Desc), intent(in) :: desc
    type(PH_Mat_Elastic_State), intent(in) :: state
    type(PH_Mat_Elastic_Algo), intent(in) :: algo
    type(PH_Mat_Elastic_Ctx), intent(in) :: ctx
    integer, intent(out) :: status
    ! 实现省略
  end subroutine

  subroutine PH_Mat_Elastic_Finalize(desc, state, algo, ctx, status)
    type(PH_Mat_Elastic_Desc), intent(in) :: desc
    type(PH_Mat_Elastic_State), intent(inout) :: state
    type(PH_Mat_Elastic_Algo), intent(in) :: algo
    type(PH_Mat_Elastic_Ctx), intent(in) :: ctx
    integer, intent(out) :: status
    ! 实现省略
  end subroutine

end module PH_Mat_Elastic
```

---

## 七、命名一致性检查清单

### 7.1 TYPE定义检查

- [ ] 所有TYPE使用四型后缀（`_Desc`/`_State`/`_Algo`/`_Ctx`）
- [ ] 四型后缀仅用于TYPE，不用于MODULE/文件名
- [ ] 四型TYPE统一定义在 `*_Def.f90` 模块中
- [ ] 同一域内四型TYPE命名风格统一

### 7.2 MODULE/文件名检查

- [ ] 所有MODULE/文件名遵循层级-域级-功能三级体系
- [ ] 新代码默认无后缀，专用后缀仅用于明确非默认角色
- [ ] 存量 `*_Ops.f90` 可保留，不强制改名
- [ ] 复合角色处理遵循域内约定

### 7.3 子程序命名检查

- [ ] 所有子程序使用动词+具体命名
- [ ] 子程序名包含标准动词集合中的动词
- [ ] 子程序名包含层级前缀、域级缩写、功能名称
- [ ] 子程序名使用PascalCase风格

### 7.4 变量命名检查

- [ ] 局部变量使用 `snake_case`
- [ ] 四型实例使用简写缩写（`desc`, `state`, `algo`, `ctx`）
- [ ] 全局常量使用 `UPPER_SNAKE`
- [ ] 命名在域内保持一致

---

## 八、层级前缀与域级缩写

### 8.1 层级前缀（强制，6个）

| 层级  | 层缀    | 全称              | 示例                               |
| ----- | ------- | ----------------- | ---------------------------------- |
| L1_IF | `IF_` | Infrastructure    | `IF_Log_Def`、`IF_Mem_Chunk`   |
| L2_NM | `NM_` | Numerical Methods | `NM_Matrix`（预留）              |
| L3_MD | `MD_` | Model Data        | `MD_Mesh`、`MD_Out_Def`        |
| L4_PH | `PH_` | Physics           | `PH_ElemContm`、`PH_Field_Cpl` |
| L5_RT | `RT_` | Runtime           | `RT_SolvProc`、`RT_Step_Def`   |
| L6_AP | `AP_` | Application       | `AP_Config`（预留）              |

### 8.2 域级缩写（常见，非穷举）

| 域缩                 | 全称                    | 出现层   | 仓库实例                             |
| -------------------- | ----------------------- | -------- | ------------------------------------ |
| **材料类**     |                         |          |                                      |
| `Mat`              | Material                | L3/L4/L5 | `MD_Mat_*`、`PH_Mat_*`           |
| `Elas`             | Elastic                 | L3/L4    | `PH_Mat_Elas_*`                    |
| `Plast`            | Plastic                 | L3/L4    | `PH_Mat_Plast_*`                   |
| `Hyper`            | Hyperelastic            | L3/L4    | `PH_Mat_Hyper_*`                   |
| `Visco`            | Viscoelastic            | L3/L4    | `PH_Mat_Visco_*`                   |
| `Creep`            | Creep                   | L3/L4    | `PH_Mat_Creep_*`                   |
| `Damage`           | Damage                  | L3/L4    | `PH_Mat_Damage_*`                  |
| `Foam`             | Foam                    | L3/L4    | `PH_Mat_Foam_*`                    |
| **单元类**     |                         |          |                                      |
| `Elem`             | Element                 | L3/L4/L5 | `MD_Elem_*`、`PH_Elem*_*`        |
| `Contm`            | Continuum               | L4       | `PH_ElemContm`                     |
| `Sld3D`            | Solid 3D                | L4       | `PH_ElemSld3D*`                    |
| `Shell`            | Shell                   | L4       | `PH_ElemShell*`                    |
| `Beam`             | Beam                    | L4       | `PH_ElemBeam*`                     |
| `Truss`            | Truss                   | L4       | `PH_ElemTruss*`                    |
| `Mass`             | Mass                    | L4       | `PH_ElemMass*`                     |
| `Spring`           | Spring                  | L4       | `PH_ElemSpring*`                   |
| `Damper`           | Damper                  | L4       | `PH_ElemDamper*`                   |
| **网格类**     |                         |          |                                      |
| `Mesh`             | Mesh                    | L3       | `MD_Mesh_*`                        |
| `Node`             | Node                    | L3       | `MD_Node_*`                        |
| `Edge`             | Edge                    | L3       | `MD_Edge_*`                        |
| `Face`             | Face                    | L3       | `MD_Face_*`                        |
| `Part`             | Part                    | L3       | `MD_Part_*`                        |
| `Section`          | Section                 | L3       | `MD_Section_*`                     |
| **求解器类**   |                         |          |                                      |
| `Solv`             | Solver                  | L2/L5    | `RT_Solv*`                         |
| `Linear`           | Linear Solver           | L2/L5    | `RT_SolvLinear*`                   |
| `NonLinear`        | Nonlinear Solver        | L2/L5    | `RT_SolvNonLinear*`                |
| `Eigen`            | Eigenvalue Solver       | L2/L5    | `RT_SolvEigen*`                    |
| `Transient`        | Transient Solver        | L2/L5    | `RT_SolvTransient*`                |
| **步进类**     |                         |          |                                      |
| `Step`             | Step Driver             | L5       | `RT_Step*`                         |
| `Static`           | Static Step             | L5       | `RT_StepStatic*`                   |
| `Dynamic`          | Dynamic Step            | L5       | `RT_StepDynamic*`                  |
| `Implicit`         | Implicit Step           | L5       | `RT_StepImplicit*`                 |
| `Explicit`         | Explicit Step           | L5       | `RT_StepExplicit*`                 |
| **接触类**     |                         |          |                                      |
| `Cont`             | Contact                 | L3/L4/L5 | `PH_Cont_*`                        |
| `Pair`             | Contact Pair            | L3/L4    | `PH_ContPair*`                     |
| `Surf`             | Surface                 | L3/L4    | `PH_ContSurf*`                     |
| **场类**       |                         |          |                                      |
| `Field`            | Field                   | L3/L4    | `PH_Field_*`                       |
| `Disp`             | Displacement            | L3/L4    | `PH_FieldDisp*`                    |
| `Stress`           | Stress                  | L3/L4    | `PH_FieldStress*`                  |
| `Strain`           | Strain                  | L3/L4    | `PH_FieldStrain*`                  |
| `Temp`             | Temperature             | L3/L4    | `PH_FieldTemp*`                    |
| **载荷类**     |                         |          |                                      |
| `Load`             | Load                    | L3/L4    | `PH_Load_*`                        |
| `BC`               | Boundary Condition      | L3/L4    | `PH_BC_*`                          |
| `LBC`              | Load/Boundary Condition | L3/L4    | `PH_Ldbc_*`                        |
| `Pres`             | Prescribed              | L3/L4    | `PH_Pres_*`                        |
| **输出类**     |                         |          |                                      |
| `Out`              | Output                  | L3       | `MD_Out_*`                         |
| `FieldOut`         | Field Output            | L3       | `MD_FieldOut*`                     |
| `Hist`             | History Output          | L3       | `MD_Hist*`                         |
| **其他**       |                         |          |                                      |
| `WB`               | WriteBack               | L5       | `RT_WB_*`                          |
| `Amp`              | Amplitude               | L5       | `RT_Amp*`                          |
| `DOF`              | Degree of Freedom       | L3       | `MD_DOF_*`                         |
| `Bridge`           | Bridge                  | L3/L4/L5 | `PH_Bridge_*`、`RT_Bridge_*`     |
| **基础设施**   |                         |          |                                      |
| `Log`              | Logging                 | L1       | `IF_Log_*`                         |
| `Mem`              | Memory                  | L1       | `IF_Mem_*`                         |
| `IO`               | Input/Output            | L1       | `IF_IO_*`                          |
| `Mon`              | Monitor                 | L1       | `IF_Mon_*`                         |
| `Prec`             | Precision               | L1       | `IF_Prec_*`                        |
| `Err`              | Error                   | L1       | `IF_Err_*`                         |
| `Timer`            | Timer                   | L1       | `IF_Timer_*`                       |
| `Thread`           | Thread                  | L1       | `IF_Thread_*`                      |
| `MPI`              | MPI                     | L1       | `IF_MPI_*`                         |
| `Device`           | Device                  | L1       | `IF_Device_*`                      |
| `Config`           | Configuration           | L1       | `IF_Config_*`                      |
| `Util`             | Utility                 | L1       | `IF_Util_*`                        |
| **几何类**     |                         |          |                                      |
| `Geom`             | Geometry                | L3/L4    | `MD_Geom_*`、`PH_Geom_*`         |
| `Curve`            | Curve                   | L3/L4    | `MD_Curve_*`、`PH_Curve_*`       |
| `Surf`             | Surface                 | L3/L4    | `MD_Surf_*`、`PH_Surf_*`         |
| `Solid`            | Solid                   | L3/L4    | `MD_Solid_*`、`PH_Solid_*`       |
| `Body`             | Body                    | L3/L4    | `MD_Body_*`、`PH_Body_*`         |
| **变换类**     |                         |          |                                      |
| `Trans`            | Transformation          | L3/L4    | `MD_Trans_*`、`PH_Trans_*`       |
| `Rot`              | Rotation                | L3/L4    | `MD_Rot_*`、`PH_Rot_*`           |
| `Scale`            | Scale                   | L3/L4    | `MD_Scale_*`、`PH_Scale_*`       |
| `Transl`           | Translation             | L3/L4    | `MD_Transl_*`、`PH_Transl_*`     |
| **数值方法类** |                         |          |                                      |
| `Matrix`           | Matrix                  | L2       | `NM_Matrix_*`                      |
| `Vector`           | Vector                  | L2       | `NM_Vector_*`                      |
| `Tensor`           | Tensor                  | L2       | `NM_Tensor_*`                      |
| `Sparse`           | Sparse                  | L2       | `NM_Sparse_*`                      |
| `Dense`            | Dense                   | L2       | `NM_Dense_*`                       |
| `Iter`             | Iterative               | L2       | `NM_Iter_*`                        |
| `Direct`           | Direct                  | L2       | `NM_Direct_*`                      |
| `Precond`          | Preconditioner          | L2       | `NM_Precond_*`                     |
| **时间积分类** |                         |          |                                      |
| `Integ`            | Integration             | L2/L5    | `NM_Integ_*`、`RT_Integ_*`       |
| `Time`             | Time                    | L2/L5    | `NM_Time_*`、`RT_Time_*`         |
| **优化类**     |                         |          |                                      |
| `Opt`              | Optimization            | L2       | `NM_Opt_*`                         |
| `Grad`             | Gradient                | L2       | `NM_Grad_*`                        |
| `Hess`             | Hessian                 | L2       | `NM_Hess_*`                        |
| `Conv`             | Convergence             | L2       | `NM_Conv_*`                        |
| **插值类**     |                         |          |                                      |
| `Interp`           | Interpolation           | L2/L3    | `NM_Interp_*`、`MD_Interp_*`     |
| `Spline`           | Spline                  | L2/L3    | `NM_Spline_*`、`MD_Spline_*`     |
| `Approx`           | Approximation           | L2/L3    | `NM_Approx_*`、`MD_Approx_*`     |
| **数据结构类** |                         |          |                                      |
| `List`             | List                    | L1/L2    | `IF_List_*`、`NM_List_*`         |
| `Stack`            | Stack                   | L1/L2    | `IF_Stack_*`、`NM_Stack_*`       |
| `Queue`            | Queue                   | L1/L2    | `IF_Queue_*`、`NM_Queue_*`       |
| `Tree`             | Tree                    | L1/L2    | `IF_Tree_*`、`NM_Tree_*`         |
| `Graph`            | Graph                   | L1/L2    | `IF_Graph_*`、`NM_Graph_*`       |
| `Hash`             | Hash                    | L1/L2    | `IF_Hash_*`、`NM_Hash_*`         |
| **并行计算类** |                         |          |                                      |
| `Parallel`         | Parallel                | L1/L2    | `IF_Parallel_*`、`NM_Parallel_*` |
| `Distrib`          | Distributed             | L1/L2    | `IF_Distrib_*`、`NM_Distrib_*`   |
| `Task`             | Task                    | L1/L2    | `IF_Task_*`、`NM_Task_*`         |
| **文件系统类** |                         |          |                                      |
| `File`             | File                    | L1       | `IF_File_*`                        |
| `Dir`              | Directory               | L1       | `IF_Dir_*`                         |
| `Path`             | Path                    | L1       | `IF_Path_*`                        |
| **网络类**     |                         |          |                                      |
| `Net`              | Network                 | L1       | `IF_Net_*`                         |
| `Socket`           | Socket                  | L1       | `IF_Socket_*`                      |
| **安全类**     |                         |          |                                      |
| `Sec`              | Security                | L1       | `IF_Sec_*`                         |
| `Auth`             | Authentication          | L1       | `IF_Auth_*`                        |
| **日志类**     |                         |          |                                      |
| `Trace`            | Tracing                 | L1       | `IF_Trace_*`                       |
| `Debug`            | Debug                   | L1       | `IF_Debug_*`                       |
| **性能类**     |                         |          |                                      |
| `Perf`             | Performance             | L1       | `IF_Perf_*`                        |
| `Prof`             | Profiling               | L1       | `IF_Prof_*`                        |
| `Stat`             | Statistics              | L1       | `IF_Stat_*`                        |
| **可视化类**   |                         |          |                                      |
| `Vis`              | Visualization           | L1/L6    | `IF_Vis_*`、`AP_Vis_*`           |
| `Plot`             | Plotting                | L1/L6    | `IF_Plot_*`、`AP_Plot_*`         |
| `Render`           | Rendering               | L1/L6    | `IF_Render_*`、`AP_Render_*`     |
| **用户界面类** |                         |          |                                      |
| `UI`               | User Interface          | L1/L6    | `IF_UI_*`、`AP_UI_*`             |
| `GUI`              | Graphical UI            | L1/L6    | `IF_GUI_*`、`AP_GUI_*`           |
| `CLI`              | Command Line            | L1/L6    | `IF_CLI_*`、`AP_CLI_*`           |
| **数据库类**   |                         |          |                                      |
| `DB`               | Database                | L1       | `IF_DB_*`                          |
| **序列化类**   |                         |          |                                      |
| `Serial`           | Serialization           | L1       | `IF_Serial_*`                      |
| `JSON`             | JSON                    | L1       | `IF_JSON_*`                        |
| `XML`              | XML                     | L1       | `IF_XML_*`                         |
| `Binary`           | Binary                  | L1       | `IF_Binary_*`                      |
| **压缩类**     |                         |          |                                      |
| `Compress`         | Compression             | L1       | `IF_Compress_*`                    |
| `Archive`          | Archive                 | L1       | `IF_Archive_*`                     |
| **国际化类**   |                         |          |                                      |
| `I18N`             | Internationalization    | L1       | `IF_I18N_*`                        |
| `Locale`           | Locale                  | L1       | `IF_Locale_*`                      |
| **配置类**     |                         |          |                                      |
| `Conf`             | Configuration           | L1       | `IF_Conf_*`                        |
| `Setting`          | Setting                 | L1       | `IF_Setting_*`                     |
| `Option`           | Option                  | L1       | `IF_Option_*`                      |
| **插件类**     |                         |          |                                      |
| `Plugin`           | Plugin                  | L1/L6    | `IF_Plugin_*`、`AP_Plugin_*`     |
| `Ext`              | Extension               | L1/L6    | `IF_Ext_*`、`AP_Ext_*`           |
| **脚本类**     |                         |          |                                      |
| `Script`           | Script                  | L1/L6    | `IF_Script_*`、`AP_Script_*`     |
| `Macro`            | Macro                   | L1/L6    | `IF_Macro_*`、`AP_Macro_*`       |

---

## 十一、待补充细节

以下内容已全部补充完成：

- [X] 扩充标准动词集合（已扩充至82个）
- [X] 扩充专用后缀闭集（已扩充至70+个生产代码专用，包含设计模式、数据处理、并发等类别）
- [X] 补充更多域级缩写（已扩充至100+个，按22个类别分组）
- [X] 补充更多命名场景（宏定义、模块变量、函数指针、回调、配置文件、数据文件、脚本文件、文档文件、测试文件、示例文件等）
- [X] 补充命名冲突处理规则
- [X] 补充命名检查工具规范
- [X] 补充命名迁移最佳实践
- [X] 补充命名规范版本管理策略

---

## 十二、层级-域级-功能详细解析

### 12.1 L1_IF — 基础设施层

| 域级                | 子域       | 功能分类 | 命名示例                                          |
| ------------------- | ---------- | -------- | ------------------------------------------------- |
| **Base**      | AI         | AI基础   | `IF_AI_Def.f90`, `IF_AI_Algo.f90`             |
|                     | Parallel   | 并行基础 | `IF_Parallel_Def.f90`, `IF_Parallel_Util.f90` |
|                     | Symbol     | 符号处理 | `IF_Symbol_Def.f90`, `IF_Symbol_Map.f90`      |
| **Error**     | -          | 错误处理 | `IF_Err_Def.f90`, `IF_Err_Handler.f90`        |
| **IO**        | Checkpoint | 检查点   | `IF_IO_Checkpoint.f90`, `IF_IO_Restore.f90`   |
|                     | -          | 通用IO   | `IF_IO_File.f90`, `IF_IO_Stream.f90`          |
| **Log**       | -          | 日志     | `IF_Log_Def.f90`, `IF_Log_Output.f90`         |
| **Memory**    | -          | 内存管理 | `IF_Mem_Alloc.f90`, `IF_Mem_Pool.f90`         |
| **Monitor**   | -          | 监控     | `IF_Mon_Def.f90`, `IF_Mon_Perf.f90`           |
| **Precision** | -          | 精度     | `IF_Prec_Def.f90`, `IF_Prec_Conv.f90`         |
| **Registry**  | -          | 注册表   | `IF_Reg_Def.f90`, `IF_Reg_Lookup.f90`         |

### 12.2 L2_NM — 数值方法层

| 域级                   | 子域       | 功能分类   | 命名示例                                               |
| ---------------------- | ---------- | ---------- | ------------------------------------------------------ |
| **Base**         | BVH        | BVH结构    | `NM_BVH_Def.f90`, `NM_BVH_Build.f90`               |
| **Bridge**       | -          | 桥接       | `NM_Bridge_L1.f90`, `NM_Bridge_L3.f90`             |
| **ExternalLibs** | -          | 第三方库   | `NM_Ext_LAPACK.f90`, `NM_Ext_BLAS.f90`             |
| **Matrix**       | -          | 矩阵       | `NM_Matrix_Def.f90`, `NM_Matrix_Ops.f90`           |
| **Solver**       | AI         | AI求解器   | `NM_SolvAI_Def.f90`, `NM_SolvAI_Train.f90`         |
|                        | Conv       | 收敛性     | `NM_SolvConv_Def.f90`, `NM_SolvConv_Check.f90`     |
|                        | Coupling   | 耦合求解   | `NM_SolvCoup_Def.f90`, `NM_SolvCoup_Solve.f90`     |
|                        | LinSolv    | 线性求解   | `NM_SolvLin_Def.f90`, `NM_SolvLin_Solve.f90`       |
|                        | NonlinSolv | 非线性求解 | `NM_SolvNonLin_Def.f90`, `NM_SolvNonLin_Solve.f90` |
|                        | Parallel   | 并行求解   | `NM_SolvPar_Def.f90`, `NM_SolvPar_Sync.f90`        |
| **TimeInt**      | -          | 时间积分   | `NM_TimeInt_Def.f90`, `NM_TimeInt_Step.f90`        |

### 12.3 L3_MD — 模型数据层

| 域级                  | 子域      | 功能分类   | 命名示例                                            |
| --------------------- | --------- | ---------- | --------------------------------------------------- |
| **Analysis**    | Amplitude | 幅值       | `MD_Amp_Def.f90`, `MD_Amp_Eval.f90`             |
|                       | Solver    | 求解器配置 | `MD_Solv_Def.f90`, `MD_Solv_Conf.f90`           |
|                       | Step      | 步进配置   | `MD_Step_Def.f90`, `MD_Step_Conf.f90`           |
| **Assembly**    | -         | 装配       | `MD_Assem_Def.f90`, `MD_Assem_Build.f90`        |
| **Boundary**    | -         | 边界       | `MD_Boundary_Def.f90`, `MD_Boundary_Apply.f90`  |
| **Bridge**      | Bridge_L4 | L4桥接     | `MD_Bridge_L4.f90`, `MD_Bridge_L4_Brg.f90`      |
|                       | Bridge_L5 | L5桥接     | `MD_Bridge_L5.f90`, `MD_Bridge_L5_Brg.f90`      |
| **Constraint**  | -         | 约束       | `MD_Const_Def.f90`, `MD_Const_Apply.f90`        |
| **Field**       | -         | 场         | `MD_Field_Def.f90`, `MD_Field_Interp.f90`       |
| **Interaction** | -         | 交互       | `MD_Inter_Def.f90`, `MD_Inter_Eval.f90`         |
| **KeyWord**     | -         | 关键字     | `MD_KW_Def.f90`, `MD_KW_Parser.f90`             |
| **Material**    | Acoustic  | 声学材料   | `MD_MatAcoust_Def.f90`, `MD_MatAcoust_Eval.f90` |
|                       | Base      | 材料基类   | `MD_MatBase_Def.f90`, `MD_MatBase_Util.f90`     |
|                       | Bridge    | 材料桥接   | `MD_MatBridge.f90`, `MD_MatBridge_Brg.f90`      |
|                       | Composite | 复合材料   | `MD_MatComp_Def.f90`, `MD_MatComp_Eval.f90`     |
|                       | Contract  | 材料契约   | `MD_MatCont_Def.f90`, `MD_MatCont_Check.f90`    |
|                       | Creep     | 蠕变       | `MD_MatCreep_Def.f90`, `MD_MatCreep_Eval.f90`   |
|                       | Damage    | 损伤       | `MD_MatDmg_Def.f90`, `MD_MatDmg_Eval.f90`       |
|                       | Dispatch  | 材料分发   | `MD_MatDisp.f90`, `MD_MatDisp_Reg.f90`          |
|                       | Domain    | 材料域     | `MD_MatDom_Def.f90`, `MD_MatDom_Mgr.f90`        |
|                       | Elas      | 弹性       | `MD_MatElas_Def.f90`, `MD_MatElas_Eval.f90`     |
|                       | Geo       | 几何材料   | `MD_MatGeo_Def.f90`, `MD_MatGeo_Eval.f90`       |
|                       | HyperElas | 超弹性     | `MD_MatHyper_Def.f90`, `MD_MatHyper_Eval.f90`   |
|                       | Plast     | 塑性       | `MD_MatPlast_Def.f90`, `MD_MatPlast_Eval.f90`   |
|                       | Registry  | 材料注册   | `MD_MatReg.f90`, `MD_MatReg_Lookup.f90`         |
|                       | Shared    | 共享材料   | `MD_MatShare_Def.f90`, `MD_MatShare_Util.f90`   |
|                       | Thermal   | 热材料     | `MD_MatTherm_Def.f90`, `MD_MatTherm_Eval.f90`   |
|                       | User      | 用户材料   | `MD_MatUser_Def.f90`, `MD_MatUser_Eval.f90`     |
|                       | Viscoelas | 粘弹性     | `MD_MatVisco_Def.f90`, `MD_MatVisco_Eval.f90`   |
| **Mesh**        | Element   | 单元网格   | `MD_MeshElem_Def.f90`, `MD_MeshElem_Build.f90`  |
|                       | -         | 通用网格   | `MD_Mesh_Def.f90`, `MD_Mesh_Gen.f90`            |
| **Model**       | -         | 模型       | `MD_Model_Def.f90`, `MD_Model_Load.f90`         |
| **Output**      | -         | 输出       | `MD_Out_Def.f90`, `MD_Out_Write.f90`            |
| **Part**        | -         | 部件       | `MD_Part_Def.f90`, `MD_Part_Mgr.f90`            |
| **Section**     | -         | 截面       | `MD_Section_Def.f90`, `MD_Section_Eval.f90`     |
| **WriteBack**   | -         | 写回       | `MD_WB_Def.f90`, `MD_WB_Write.f90`              |

### 12.4 L4_PH — 物理计算层

| 域级                 | 子域      | 功能分类     | 命名示例                                                |
| -------------------- | --------- | ------------ | ------------------------------------------------------- |
| **Bridge**     | Output    | 输出桥接     | `PH_BridgeOut.f90`, `PH_BridgeOut_Brg.f90`          |
|                      | WriteBack | 写回桥接     | `PH_BridgeWB.f90`, `PH_BridgeWB_Brg.f90`            |
| **Constraint** | -         | 约束         | `PH_Const_Def.f90`, `PH_Const_Apply.f90`            |
| **Contact**    | AI        | AI接触       | `PH_ContAI_Def.f90`, `PH_ContAI_Solve.f90`          |
|                      | Core      | 接触核心     | `PH_ContCore_Def.f90`, `PH_ContCore_Eval.f90`       |
|                      | Domain    | 接触域       | `PH_ContDom_Def.f90`, `PH_ContDom_Mgr.f90`          |
|                      | Explicit  | 显式接触     | `PH_ContExpl_Def.f90`, `PH_ContExpl_Solve.f90`      |
|                      | Friction  | 摩擦         | `PH_ContFric_Def.f90`, `PH_ContFric_Eval.f90`       |
|                      | Search    | 接触搜索     | `PH_ContSearch_Def.f90`, `PH_ContSearch_Find.f90`   |
|                      | Self      | 自接触       | `PH_ContSelf_Def.f90`, `PH_ContSelf_Eval.f90`       |
|                      | Thermal   | 热接触       | `PH_ContTherm_Def.f90`, `PH_ContTherm_Eval.f90`     |
|                      | Types     | 接触类型     | `PH_ContType_Def.f90`, `PH_ContType_Util.f90`       |
|                      | Wear      | 磨损         | `PH_ContWear_Def.f90`, `PH_ContWear_Eval.f90`       |
| **Element**    | Acoustic  | 声学单元     | `PH_ElemAcoust_Def.f90`, `PH_ElemAcoust_Eval.f90`   |
|                      | Beam      | 梁单元       | `PH_ElemBeam_Def.f90`, `PH_ElemBeam_Eval.f90`       |
|                      | Cohesive  | 内聚单元     | `PH_ElemCohes_Def.f90`, `PH_ElemCohes_Eval.f90`     |
|                      | Dashpot   | 阻尼器       | `PH_ElemDashpot_Def.f90`, `PH_ElemDashpot_Eval.f90` |
|                      | Gasket    | 垫片         | `PH_ElemGasket_Def.f90`, `PH_ElemGasket_Eval.f90`   |
|                      | Infinite  | 无限单元     | `PH_ElemInf_Def.f90`, `PH_ElemInf_Eval.f90`         |
|                      | Mass      | 质量单元     | `PH_ElemMass_Def.f90`, `PH_ElemMass_Eval.f90`       |
|                      | Membrane  | 膜单元       | `PH_ElemMembr_Def.f90`, `PH_ElemMembr_Eval.f90`     |
|                      | Pipe      | 管单元       | `PH_ElemPipe_Def.f90`, `PH_ElemPipe_Eval.f90`       |
|                      | Porous    | 多孔单元     | `PH_ElemPorous_Def.f90`, `PH_ElemPorous_Eval.f90`   |
|                      | Shared    | 共享单元     | `PH_ElemShare_Def.f90`, `PH_ElemShare_Util.f90`     |
|                      | Shell     | 壳单元       | `PH_ElemShell_Def.f90`, `PH_ElemShell_Eval.f90`     |
|                      | Solid2D   | 2D实体       | `PH_ElemSld2D_Def.f90`, `PH_ElemSld2D_Eval.f90`     |
|                      | Solid2Dt  | 2D实体(温度) | `PH_ElemSld2Dt_Def.f90`, `PH_ElemSld2Dt_Eval.f90`   |
|                      | Solid3D   | 3D实体       | `PH_ElemSld3D_Def.f90`, `PH_ElemSld3D_Eval.f90`     |
|                      | Solid3Dt  | 3D实体(温度) | `PH_ElemSld3Dt_Def.f90`, `PH_ElemSld3Dt_Eval.f90`   |
|                      | Special   | 特殊单元     | `PH_ElemSpec_Def.f90`, `PH_ElemSpec_Eval.f90`       |
|                      | Spring    | 弹簧单元     | `PH_ElemSpring_Def.f90`, `PH_ElemSpring_Eval.f90`   |
|                      | Surface   | 表面单元     | `PH_ElemSurf_Def.f90`, `PH_ElemSurf_Eval.f90`       |
|                      | Thermal   | 热单元       | `PH_ElemTherm_Def.f90`, `PH_ElemTherm_Eval.f90`     |
|                      | Truss     | 桁架单元     | `PH_ElemTruss_Def.f90`, `PH_ElemTruss_Eval.f90`     |
|                      | User      | 用户单元     | `PH_ElemUser_Def.f90`, `PH_ElemUser_Eval.f90`       |
| **Field**      | -         | 场           | `PH_Field_Def.f90`, `PH_Field_Interp.f90`           |
| **LoadBC**     | -         | 载荷边界     | `PH_LoadBC_Def.f90`, `PH_LoadBC_Apply.f90`          |
| **Material**   | Acoustic  | 声学材料     | `PH_MatAcoust_Def.f90`, `PH_MatAcoust_Eval.f90`     |
|                      | Base      | 材料基类     | `PH_MatBase_Def.f90`, `PH_MatBase_Util.f90`         |
|                      | Bridge    | 材料桥接     | `PH_MatBridge.f90`, `PH_MatBridge_Brg.f90`          |
|                      | Composite | 复合材料     | `PH_MatComp_Def.f90`, `PH_MatComp_Eval.f90`         |
|                      | Contract  | 材料契约     | `PH_MatCont_Def.f90`, `PH_MatCont_Check.f90`        |
|                      | Creep     | 蠕变         | `PH_MatCreep_Def.f90`, `PH_MatCreep_Eval.f90`       |
|                      | Damage    | 损伤         | `PH_MatDmg_Def.f90`, `PH_MatDmg_Eval.f90`           |
|                      | Dispatch  | 材料分发     | `PH_MatDisp.f90`, `PH_MatDisp_Reg.f90`              |
|                      | Domain    | 材料域       | `PH_MatDom_Def.f90`, `PH_MatDom_Mgr.f90`            |
|                      | Elas      | 弹性         | `PH_MatElas_Def.f90`, `PH_MatElas_Eval.f90`         |
|                      | Geo       | 几何材料     | `PH_MatGeo_Def.f90`, `PH_MatGeo_Eval.f90`           |
|                      | HyperElas | 超弹性       | `PH_MatHyper_Def.f90`, `PH_MatHyper_Eval.f90`       |
|                      | Plast     | 塑性         | `PH_MatPlast_Def.f90`, `PH_MatPlast_Eval.f90`       |
|                      | Registry  | 材料注册     | `PH_MatReg.f90`, `PH_MatReg_Lookup.f90`             |
|                      | Shared    | 共享材料     | `PH_MatShare_Def.f90`, `PH_MatShare_Util.f90`       |
|                      | Thermal   | 热材料       | `PH_MatTherm_Def.f90`, `PH_MatTherm_Eval.f90`       |
|                      | User      | 用户材料     | `PH_MatUser_Def.f90`, `PH_MatUser_Eval.f90`         |
|                      | Viscoelas | 粘弹性       | `PH_MatVisco_Def.f90`, `PH_MatVisco_Eval.f90`       |

### 12.5 L5_RT — 运行时层

| 域级                 | 子域     | 功能分类 | 命名示例                                           |
| -------------------- | -------- | -------- | -------------------------------------------------- |
| **Assembly**   | -        | 装配     | `RT_Assem_Def.f90`, `RT_Assem_Build.f90`       |
| **Bridge**     | Shared   | 共享桥接 | `RT_BridgeShare.f90`, `RT_BridgeShare_Brg.f90` |
| **Contact**    | -        | 接触     | `RT_Cont_Def.f90`, `RT_Cont_Solve.f90`         |
| **Element**    | Mesh     | 网格单元 | `RT_ElemMesh_Def.f90`, `RT_ElemMesh_Eval.f90`  |
| **LoadBC**     | -        | 载荷边界 | `RT_LoadBC_Def.f90`, `RT_LoadBC_Apply.f90`     |
| **Logging**    | -        | 日志     | `RT_Log_Def.f90`, `RT_Log_Output.f90`          |
| **Material**   | -        | 材料     | `RT_Mat_Def.f90`, `RT_Mat_Eval.f90`            |
| **Output**     | -        | 输出     | `RT_Out_Def.f90`, `RT_Out_Write.f90`           |
| **Solver**     | Coupling | 耦合求解 | `RT_SolvCoup_Def.f90`, `RT_SolvCoup_Solve.f90` |
| **StepDriver** | -        | 步进驱动 | `RT_StepDrv_Def.f90`, `RT_StepDrv_Run.f90`     |
| **WriteBack**  | -        | 写回     | `RT_WB_Def.f90`, `RT_WB_Write.f90`             |

### 12.6 L6_AP — 应用层

| 域级               | 子域    | 功能分类 | 命名示例                                           |
| ------------------ | ------- | -------- | -------------------------------------------------- |
| **Bridge**   | -       | 桥接     | `AP_Bridge.f90`, `AP_Bridge_Brg.f90`           |
| **Config**   | -       | 配置     | `AP_Config_Def.f90`, `AP_Config_Load.f90`      |
| **Input**    | Command | 命令输入 | `AP_InCmd_Def.f90`, `AP_InCmd_Parse.f90`       |
|                    | Parser  | 解析器   | `AP_InParser_Def.f90`, `AP_InParser_Parse.f90` |
|                    | Script  | 脚本     | `AP_InScript_Def.f90`, `AP_InScript_Run.f90`   |
| **Job**      | -       | 作业     | `AP_Job_Def.f90`, `AP_Job_Run.f90`             |
| **Output**   | -       | 输出     | `AP_Out_Def.f90`, `AP_Out_Write.f90`           |
| **Registry** | -       | 注册表   | `AP_Reg_Def.f90`, `AP_Reg_Lookup.f90`          |
| **Solver**   | -       | 求解器   | `AP_Solv_Def.f90`, `AP_Solv_Run.f90`           |
| **UI**       | -       | 用户界面 | `AP_UI_Def.f90`, `AP_UI_Run.f90`               |

---

## 十三、UFC作为最小子集的向上兼容性建议

### 13.1 层级扩展兼容性

| 扩展方向 | 建议层级 | 命名前缀 | 说明                        |
| -------- | -------- | -------- | --------------------------- |
| 向下扩展 | L0_HW    | `HW_`  | 硬件抽象层（GPU/FPGA/ASIC） |

**命名兼容性**：

- 新层级前缀不与现有层级冲突
- 遵循 `{新层级}_{域}_{功能}[{角色}]` 三段式
- 保持与现有层级的桥接能力

**注意**：云计算、AI/ML、可视化等功能应作为L6_AP层的域级扩展，而非独立层级。层级应按抽象层次划分，而非功能域划分。

### 13.2 域级扩展兼容性

| 扩展类别                  | 建议域级      | 命名示例                    | 说明                       |
| ------------------------- | ------------- | --------------------------- | -------------------------- |
| **多物理场**        | `EM`        | `PH_EM_Field.f90`         | 电磁场                     |
|                           | `CFD`       | `PH_CFD_Flow.f90`         | 计算流体力学               |
|                           | `Acoust`    | `PH_Acoust_Wave.f90`      | 声学                       |
|                           | `Thermal`   | `PH_Therm_Heat.f90`       | 热传导                     |
| **多尺度**          | `Micro`     | `PH_Micro_Crystal.f90`    | 微观尺度                   |
|                           | `Macro`     | `PH_Macro_Struct.f90`     | 宏观尺度                   |
|                           | `Multi`     | `PH_Multi_Scale.f90`      | 多尺度耦合                 |
| **多体动力学**      | `MBD`       | `PH_MBD_Joint.f90`        | 多体动力学                 |
| **优化**            | `Opt`       | `PH_Opt_Topology.f90`     | 拓扑优化                   |
|                           | `Design`    | `PH_Design_Var.f90`       | 设计变量                   |
| **不确定性**        | `UQ`        | `PH_UQ_Random.f90`        | 不确定性量化               |
|                           | `Stoch`     | `PH_Stoch_Proc.f90`       | 随机过程                   |
| **数字孪生**        | `DT`        | `PH_DT_Model.f90`         | 数字孪生                   |
|                           | `Digital`   | `PH_Digital_Twin.f90`     | 数字化                     |
| **L6_AP应用层扩展** |               |                             |                            |
| **云计算**          | `Cloud`     | `AP_Cloud_Deploy.f90`     | 云计算部署                 |
|                           | `Container` | `AP_Container_Docker.f90` | 容器化                     |
|                           | `K8s`       | `AP_K8s_Orch.f90`         | Kubernetes编排（Orch简化） |
| **AI/ML**           | `AI`        | `AP_AI_Train.f90`         | AI训练                     |
|                           | `ML`        | `AP_ML_Infer.f90`         | 机器学习推理               |
|                           | `DL`        | `AP_DL_Model.f90`         | 深度学习                   |
| **可视化**          | `Viz`       | `AP_Viz_Render.f90`       | 可视化渲染                 |
|                           | `VR`        | `AP_VR_Exp.f90`           | 虚拟现实（Exp简化）        |
|                           | `AR`        | `AP_AR_Overlay.f90`       | 增强现实                   |

**命名兼容性**：

- 新域级缩写不与现有域级冲突
- 遵循域级缩写规范（2-6字符）
- 保持域级语义清晰

### 13.3 功能扩展兼容性

| 扩展方向           | 建议功能     | 命名示例                 | 说明       |
| ------------------ | ------------ | ------------------------ | ---------- |
| **AI集成**   | `Train`    | `PH_Mat_Train.f90`     | 模型训练   |
|                    | `Infer`    | `PH_Mat_Infer.f90`     | 模型推理   |
|                    | `Learn`    | `PH_Mat_Learn.f90`     | 机器学习   |
| **实时计算** | `RealTime` | `RT_Step_RealTime.f90` | 实时计算   |
|                    | `Online`   | `RT_Step_Online.f90`   | 在线计算   |
| **高性能**   | `GPU`      | `PH_Elem_GPU.f90`      | GPU加速    |
|                    | `Vector`   | `PH_Elem_Vector.f90`   | 向量化     |
| **异构计算** | `FPGA`     | `PH_Elem_FPGA.f90`     | FPGA加速   |
|                    | `ASIC`     | `PH_Elem_ASIC.f90`     | ASIC加速   |
| **分布式**   | `Distrib`  | `RT_Solv_Distrib.f90`  | 分布式求解 |
|                    | `Cluster`  | `RT_Solv_Cluster.f90`  | 集群计算   |
| **边缘计算** | `Edge`     | `RT_Step_Edge.f90`     | 边缘计算   |
|                    | `IoT`      | `RT_Step_IoT.f90`      | 物联网     |

**命名兼容性**：

- 新功能位不与现有功能冲突
- 遵循功能位命名规范
- 保持功能语义清晰

### 13.4 后缀扩展兼容性

| 扩展类别         | 建议后缀       | 命名示例                  | 说明       |
| ---------------- | -------------- | ------------------------- | ---------- |
| **AI/ML**  | `_Train`     | `PH_Mat_Train.f90`      | 训练       |
|                  | `_Infer`     | `PH_Mat_Infer.f90`      | 推理       |
|                  | `_Learn`     | `PH_Mat_Learn.f90`      | 学习       |
|                  | `_Model`     | `PH_Mat_Model.f90`      | 模型       |
| **实时**   | `_RT`        | `RT_Step_RT.f90`        | 实时       |
|                  | `_Online`    | `RT_Step_Online.f90`    | 在线       |
| **高性能** | `_GPU`       | `PH_Elem_GPU.f90`       | GPU        |
|                  | `_Vector`    | `PH_Elem_Vector.f90`    | 向量化     |
| **分布式** | `_Dist`      | `RT_Solv_Dist.f90`      | 分布式     |
|                  | `_Cluster`   | `RT_Solv_Cluster.f90`   | 集群       |
| **云原生** | `_Cloud`     | `RT_Step_Cloud.f90`     | 云端       |
|                  | `_Container` | `RT_Step_Container.f90` | 容器       |
|                  | `_K8s`       | `RT_Step_K8s.f90`       | Kubernetes |
| **区块链** | `_Chain`     | `RT_Step_Chain.f90`     | 区块链     |
|                  | `_Ledger`    | `RT_Step_Ledger.f90`    | 账本       |

**命名兼容性**：

- 新后缀不与现有后缀冲突
- 遵循后缀闭集规范
- 保持后缀语义清晰

### 13.5 数据类型扩展兼容性

| 扩展方向         | 建议类型     | 命名示例                 | 说明     |
| ---------------- | ------------ | ------------------------ | -------- |
| **复数**   | `_Complex` | `PH_Field_Complex.f90` | 复数场   |
| **四元数** | `_Quat`    | `PH_Geom_Quat.f90`     | 四元数   |
| **张量**   | `_Tensor`  | `PH_Field_Tensor.f90`  | 张量场   |
| **稀疏**   | `_Sparse`  | `NM_Matrix_Sparse.f90` | 稀疏矩阵 |
| **块稀疏** | `_BSR`     | `NM_Matrix_BSR.f90`    | 块稀疏   |
| **图**     | `_Graph`   | `MD_Mesh_Graph.f90`    | 图结构   |
| **树**     | `_Tree`    | `MD_Mesh_Tree.f90`     | 树结构   |
| **网格**   | `_Mesh`    | `MD_Mesh_Mesh.f90`     | 网格结构 |

### 13.6 接口扩展兼容性

| 扩展方向             | 建议接口  | 命名示例                   | 说明       |
| -------------------- | --------- | -------------------------- | ---------- |
| **C接口**      | `_C`    | `PH_Mat_Elastic_C.f90`   | C接口      |
| **C++接口**    | `_CPP`  | `PH_Mat_Elastic_CPP.f90` | C++接口    |
| **Python接口** | `_Py`   | `PH_Mat_Elastic_Py.f90`  | Python接口 |
| **Julia接口**  | `_Jl`   | `PH_Mat_Elastic_Jl.f90`  | Julia接口  |
| **Rust接口**   | `_Rs`   | `PH_Mat_Elastic_Rs.f90`  | Rust接口   |
| **Go接口**     | `_Go`   | `PH_Mat_Elastic_Go.f90`  | Go接口     |
| **REST API**   | `_REST` | `AP_Solv_REST.f90`       | REST API   |
| **gRPC**       | `_GRPC` | `AP_Solv_GRPC.f90`       | gRPC       |
| **WebSocket**  | `_WS`   | `AP_Solv_WS.f90`         | WebSocket  |

### 13.7 平台扩展兼容性

| 扩展方向           | 建议平台     | 命名示例              | 说明        |
| ------------------ | ------------ | --------------------- | ----------- |
| **Linux**    | `_Linux`   | `IF_IO_Linux.f90`   | Linux平台   |
| **Windows**  | `_Win`     | `IF_IO_Win.f90`     | Windows平台 |
| **macOS**    | `_Mac`     | `IF_IO_Mac.f90`     | macOS平台   |
| **Android**  | `_Android` | `AP_UI_Android.f90` | Android平台 |
| **iOS**      | `_iOS`     | `AP_UI_iOS.f90`     | iOS平台     |
| **Web**      | `_Web`     | `AP_UI_Web.f90`     | Web平台     |
| **Embedded** | `_Emb`     | `RT_Step_Emb.f90`   | 嵌入式      |

### 13.8 向上兼容性原则

1. **命名一致性**：新扩展遵循现有命名规范
2. **向后兼容**：新扩展不破坏现有接口
3. **渐进式扩展**：支持渐进式功能扩展
4. **模块化设计**：新扩展以模块形式集成
5. **可配置性**：支持编译时/运行时配置
6. **性能优先**：扩展不影响核心性能
7. **测试覆盖**：扩展需有完整测试覆盖
8. **文档同步**：扩展需同步更新文档

### 13.9 扩展检查清单

- [ ] 新层级前缀不与现有层级冲突
- [ ] 新域级缩写不与现有域级冲突
- [ ] 新功能位不与现有功能冲突
- [ ] 新后缀不与现有后缀冲突
- [ ] 新类型遵循四型命名规范
- [ ] 新接口遵循接口命名规范
- [ ] 新平台遵循平台命名规范
- [ ] 扩展有完整测试覆盖
- [ ] 扩展有完整文档
- [ ] 扩展通过命名检查工具验证

---

## 十四、工程化命名简称表

### 14.1 通用功能缩写

| 全称            | 简称        | 示例                    |
| --------------- | ----------- | ----------------------- |
| Orchestration   | Orch        | `AP_K8s_Orch.f90`     |
| Experience      | Exp         | `AP_VR_Exp.f90`       |
| Configuration   | Config/Conf | `AP_Config.f90`       |
| Deployment      | Deploy      | `AP_Cloud_Deploy.f90` |
| Management      | Mgmt/Mgr    | `IF_Device_Mgr.f90`   |
| Administration  | Admin       | `AP_Admin.f90`        |
| Monitoring      | Mon         | `IF_Mon.f90`          |
| Logging         | Log         | `IF_Log.f90`          |
| Tracing         | Trace       | `IF_Trace.f90`        |
| Debugging       | Debug       | `IF_Debug.f90`        |
| Testing         | Test        | `test_material.f90`   |
| Validation      | Valid       | `PH_Mat_Valid.f90`    |
| Verification    | Verif       | `PH_Mat_Verif.f90`    |
| Optimization    | Opt         | `PH_Opt.f90`          |
| Simulation      | Sim         | `AP_Sim.f90`          |
| Analysis        | Anal        | `AP_Anal.f90`         |
| Calculation     | Calc        | `NM_Calc.f90`         |
| Computation     | Comp        | `NM_Comp.f90`         |
| Evaluation      | Eval        | `PH_Mat_Eval.f90`     |
| Estimation      | Est         | `RT_Step_Est.f90`     |
| Prediction      | Pred        | `RT_Step_Pred.f90`    |
| Correction      | Corr        | `RT_Step_Corr.f90`    |
| Initialization  | Init        | `PH_Mat_Init.f90`     |
| Finalization    | Fin         | `PH_Mat_Fin.f90`      |
| Termination     | Term        | `RT_Step_Term.f90`    |
| Cleanup         | Clean       | `RT_Step_Clean.f90`   |
| Synchronization | Sync        | `RT_Sync.f90`         |
| Communication   | Comm        | `RT_Comm.f90`         |
| Distribution    | Dist        | `RT_Dist.f90`         |
| Aggregation     | Aggr        | `RT_Aggr.f90`         |
| Accumulation    | Accum       | `RT_Accum.f90`        |
| Reduction       | Red         | `RT_Red.f90`          |
| Transformation  | Trans       | `PH_Trans.f90`        |
| Conversion      | Conv        | `PH_Conv.f90`         |
| Translation     | Transl      | `PH_Transl.f90`       |
| Rotation        | Rot         | `PH_Rot.f90`          |
| Scaling         | Scale       | `PH_Scale.f90`        |
| Projection      | Proj        | `PH_Proj.f90`         |
| Interpolation   | Interp      | `PH_Interp.f90`       |
| Extrapolation   | Extr        | `PH_Extr.f90`         |
| Approximation   | Approx      | `PH_Approx.f90`       |
| Integration     | Integ       | `NM_Integ.f90`        |
| Differentiation | Diff        | `NM_Diff.f90`         |
| Normalization   | Norm        | `PH_Norm.f90`         |
| Standardization | Std         | `PH_Std.f90`          |
| Regularization  | Reg         | `PH_Reg.f90`          |
| Decomposition   | Decomp      | `NM_Decomp.f90`       |
| Factorization   | Fact        | `NM_Fact.f90`         |
| Reconstruction  | Recon       | `PH_Recon.f90`        |
| Refinement      | Ref         | `MD_Mesh_Ref.f90`     |
| Coarsening      | Coarse      | `MD_Mesh_Coarse.f90`  |
| Partitioning    | Part        | `MD_Mesh_Part.f90`    |
| Balancing       | Bal         | `RT_Bal.f90`          |
| Scheduling      | Sched       | `RT_Sched.f90`        |
| Dispatching     | Disp        | `RT_Disp.f90`         |
| Collection      | Coll        | `RT_Coll.f90`         |
| Broadcasting    | Broad       | `RT_Broad.f90`        |
| Scattering      | Scatter     | `RT_Scatter.f90`      |
| Gathering       | Gather      | `RT_Gather.f90`       |
| Barrier         | Barrier     | `RT_Barrier.f90`      |
| Locking         | Lock        | `RT_Lock.f90`         |
| Semaphore       | Sem         | `RT_Sem.f90`          |
| Mutex           | Mutex       | `RT_Mutex.f90`        |
| Condition       | Cond        | `RT_Cond.f90`         |
| Caching         | Cache       | `IF_Cache.f90`        |
| Buffering       | Buffer      | `IF_Buffer.f90`       |
| Pooling         | Pool        | `IF_Pool.f90`         |
| Queuing         | Queue       | `RT_Queue.f90`        |
| Stacking        | Stack       | `RT_Stack.f90`        |
| Heaping         | Heap        | `RT_Heap.f90`         |
| Prioritization  | Prio        | `RT_Prio.f90`         |
| Ringing         | Ring        | `IF_Ring.f90`         |
| Circling        | Circ        | `RT_Circ.f90`         |
| Doubling        | Double      | `RT_Double.f90`       |
| Tripling        | Triple      | `RT_Triple.f90`       |

### 14.2 云计算相关缩写

| 全称                    | 简称      | 示例                 |
| ----------------------- | --------- | -------------------- |
| Container               | Cont      | `AP_Cont.f90`      |
| Docker                  | Docker    | `AP_Docker.f90`    |
| Kubernetes              | K8s       | `AP_K8s.f90`       |
| Orchestration           | Orch      | `AP_Orch.f90`      |
| Deployment              | Deploy    | `AP_Deploy.f90`    |
| Service                 | Svc       | `AP_Svc.f90`       |
| Ingress                 | Ingress   | `AP_Ingress.f90`   |
| Egress                  | Egress    | `AP_Egress.f90`    |
| LoadBalancer            | LB        | `AP_LB.f90`        |
| AutoScaling             | AutoScale | `AP_AutoScale.f90` |
| Cluster                 | Cluster   | `AP_Cluster.f90`   |
| Node                    | Node      | `AP_Node.f90`      |
| Pod                     | Pod       | `AP_Pod.f90`       |
| Namespace               | NS        | `AP_NS.f90`        |
| ConfigMap               | CM        | `AP_CM.f90`        |
| Secret                  | Secret    | `AP_Secret.f90`    |
| Volume                  | Vol       | `AP_Vol.f90`       |
| PersistentVolume        | PV        | `AP_PV.f90`        |
| PersistentVolumeClaim   | PVC       | `AP_PVC.f90`       |
| StorageClass            | SC        | `AP_SC.f90`        |
| StatefulSet             | STS       | `AP_STS.f90`       |
| DaemonSet               | DS        | `AP_DS.f90`        |
| ReplicaSet              | RS        | `AP_RS.f90`        |
| Deployment              | Deploy    | `AP_Deploy.f90`    |
| Job                     | Job       | `AP_Job.f90`       |
| CronJob                 | CJ        | `AP_CJ.f90`        |
| HorizontalPodAutoscaler | HPA       | `AP_HPA.f90`       |
| VerticalPodAutoscaler   | VPA       | `AP_VPA.f90`       |
| ClusterAutoscaler       | CA        | `AP_CA.f90`        |

### 14.3 AI/ML相关缩写

| 全称                       | 简称       | 示例                  |
| -------------------------- | ---------- | --------------------- |
| ArtificialIntelligence     | AI         | `AP_AI.f90`         |
| MachineLearning            | ML         | `AP_ML.f90`         |
| DeepLearning               | DL         | `AP_DL.f90`         |
| NeuralNetwork              | NN         | `AP_NN.f90`         |
| ConvolutionalNeuralNetwork | CNN        | `AP_CNN.f90`        |
| RecurrentNeuralNetwork     | RNN        | `AP_RNN.f90`        |
| Transformer                | Trans      | `AP_Trans.f90`      |
| Attention                  | Attn       | `AP_Attn.f90`       |
| Training                   | Train      | `AP_Train.f90`      |
| Inference                  | Infer      | `AP_Infer.f90`      |
| Learning                   | Learn      | `AP_Learn.f90`      |
| Model                      | Model      | `AP_Model.f90`      |
| Dataset                    | Data       | `AP_Data.f90`       |
| Feature                    | Feat       | `AP_Feat.f90`       |
| Label                      | Label      | `AP_Label.f90`      |
| Loss                       | Loss       | `AP_Loss.f90`       |
| Optimizer                  | Opt        | `AP_Opt.f90`        |
| Gradient                   | Grad       | `AP_Grad.f90`       |
| Backpropagation            | Backprop   | `AP_Backprop.f90`   |
| ForwardPropagation         | FwdProp    | `AP_FwdProp.f90`    |
| Epoch                      | Epoch      | `AP_Epoch.f90`      |
| Batch                      | Batch      | `AP_Batch.f90`      |
| Validation                 | Valid      | `AP_Valid.f90`      |
| Test                       | Test       | `AP_Test.f90`       |
| Hyperparameter             | Hyper      | `AP_Hyper.f90`      |
| Regularization             | Reg        | `AP_Reg.f90`        |
| Dropout                    | Dropout    | `AP_Dropout.f90`    |
| BatchNormalization         | BN         | `AP_BN.f90`         |
| LayerNormalization         | LN         | `AP_LN.f90`         |
| Activation                 | Act        | `AP_Act.f90`        |
| Pooling                    | Pool       | `AP_Pool.f90`       |
| Convolution                | Conv       | `AP_Conv.f90`       |
| Deconvolution              | Deconv     | `AP_Deconv.f90`     |
| Upsampling                 | Upsample   | `AP_Upsample.f90`   |
| Downsampling               | Downsample | `AP_Downsample.f90` |
| Embedding                  | Embed      | `AP_Embed.f90`      |
| Tokenization               | Token      | `AP_Token.f90`      |
| Vocabulary                 | Vocab      | `AP_Vocab.f90`      |
| Sequence                   | Seq        | `AP_Seq.f90`        |
| TimeSeries                 | TS         | `AP_TS.f90`         |
| ReinforcementLearning      | RL         | `AP_RL.f90`         |
| TransferLearning           | TL         | `AP_TL.f90`         |
| FederatedLearning          | FL         | `AP_FL.f90`         |

### 14.4 可视化相关缩写

| 全称             | 简称     | 示例                |
| ---------------- | -------- | ------------------- |
| Visualization    | Viz      | `AP_Viz.f90`      |
| Rendering        | Render   | `AP_Render.f90`   |
| VirtualReality   | VR       | `AP_VR.f90`       |
| AugmentedReality | AR       | `AP_AR.f90`       |
| MixedReality     | MR       | `AP_MR.f90`       |
| ExtendedReality  | XR       | `AP_XR.f90`       |
| ThreeDimensional | 3D       | `AP_3D.f90`       |
| TwoDimensional   | 2D       | `AP_2D.f90`       |
| Graphics         | Graph    | `AP_Graph.f90`    |
| Animation        | Anim     | `AP_Anim.f90`     |
| Simulation       | Sim      | `AP_Sim.f90`      |
| Scene            | Scene    | `AP_Scene.f90`    |
| Camera           | Camera   | `AP_Camera.f90`   |
| Lighting         | Light    | `AP_Light.f90`    |
| Shading          | Shade    | `AP_Shade.f90`    |
| Texture          | Tex      | `AP_Tex.f90`      |
| Material         | Mat      | `AP_Mat.f90`      |
| Mesh             | Mesh     | `AP_Mesh.f90`     |
| Model            | Model    | `AP_Model.f90`    |
| Geometry         | Geom     | `AP_Geom.f90`     |
| Vertex           | Vert     | `AP_Vert.f90`     |
| Fragment         | Frag     | `AP_Frag.f90`     |
| Shader           | Shader   | `AP_Shader.f90`   |
| Pipeline         | Pipe     | `AP_Pipe.f90`     |
| Framebuffer      | FB       | `AP_FB.f90`       |
| Renderbuffer     | RB       | `AP_RB.f90`       |
| Texture          | Tex      | `AP_Tex.f90`      |
| Sampler          | Samp     | `AP_Samp.f90`     |
| Uniform          | Uni      | `AP_Uni.f90`      |
| Attribute        | Attr     | `AP_Attr.f90`     |
| Buffer           | Buf      | `AP_Buf.f90`      |
| Array            | Arr      | `AP_Arr.f90`      |
| Image            | Img      | `AP_Img.f90`      |
| Video            | Video    | `AP_Video.f90`    |
| Audio            | Audio    | `AP_Audio.f90`    |
| Haptic           | Haptic   | `AP_Haptic.f90`   |
| Interaction      | Interact | `AP_Interact.f90` |
| Navigation       | Nav      | `AP_Nav.f90`      |
| Tracking         | Track    | `AP_Track.f90`    |
| Calibration      | Calib    | `AP_Calib.f90`    |
| Projection       | Proj     | `AP_Proj.f90`     |
| Viewport         | Viewport | `AP_Viewport.f90` |
| Clipping         | Clip     | `AP_Clip.f90`     |
| Culling          | Cull     | `AP_Cull.f90`     |
| Occlusion        | Occ      | `AP_Occ.f90`      |
| Shadow           | Shadow   | `AP_Shadow.f90`   |
| Reflection       | Reflect  | `AP_Reflect.f90`  |
| Refraction       | Refract  | `AP_Refract.f90`  |

### 14.5 网络相关缩写

| 全称         | 简称    | 示例               |
| ------------ | ------- | ------------------ |
| Network      | Net     | `IF_Net.f90`     |
| Socket       | Socket  | `IF_Socket.f90`  |
| Protocol     | Proto   | `IF_Proto.f90`   |
| Transmission | Trans   | `IF_Trans.f90`   |
| Reception    | Recv    | `IF_Recv.f90`    |
| Connection   | Conn    | `IF_Conn.f90`    |
| Session      | Sess    | `IF_Sess.f90`    |
| Stream       | Stream  | `IF_Stream.f90`  |
| Packet       | Packet  | `IF_Packet.f90`  |
| Frame        | Frame   | `IF_Frame.f90`   |
| Segment      | Seg     | `IF_Seg.f90`     |
| Datagram     | Dgram   | `IF_Dgram.f90`   |
| Address      | Addr    | `IF_Addr.f90`    |
| Port         | Port    | `IF_Port.f90`    |
| Host         | Host    | `IF_Host.f90`    |
| Client       | Client  | `IF_Client.f90`  |
| Server       | Server  | `IF_Server.f90`  |
| Proxy        | Proxy   | `IF_Proxy.f90`   |
| Gateway      | Gateway | `IF_Gateway.f90` |
| Router       | Router  | `IF_Router.f90`  |
| Switch       | Switch  | `IF_Switch.f90`  |
| Firewall     | FW      | `IF_FW.f90`      |
| LoadBalancer | LB      | `IF_LB.f90`      |
| DNS          | DNS     | `IF_DNS.f90`     |
| DHCP         | DHCP    | `IF_DHCP.f90`    |
| HTTP         | HTTP    | `IF_HTTP.f90`    |
| HTTPS        | HTTPS   | `IF_HTTPS.f90`   |
| FTP          | FTP     | `IF_FTP.f90`     |
| SFTP         | SFTP    | `IF_SFTP.f90`    |
| SSH          | SSH     | `IF_SSH.f90`     |
| TLS          | TLS     | `IF_TLS.f90`     |
| SSL          | SSL     | `IF_SSL.f90`     |
| WebSocket    | WS      | `IF_WS.f90`      |
| REST         | REST    | `IF_REST.f90`    |
| gRPC         | gRPC    | `IF_gRPC.f90`    |
| GraphQL      | GraphQL | `IF_GraphQL.f90` |
| API          | API     | `IF_API.f90`     |
| SDK          | SDK     | `IF_SDK.f90`     |
| Library      | Lib     | `IF_Lib.f90`     |
| Framework    | FW      | `IF_FW.f90`      |

### 14.6 数据处理相关缩写

| 全称        | 简称      | 示例                 |
| ----------- | --------- | -------------------- |
| Database    | DB        | `IF_DB.f90`        |
| Table       | Table     | `IF_Table.f90`     |
| Record      | Rec       | `IF_Rec.f90`       |
| Field       | Field     | `IF_Field.f90`     |
| Column      | Col       | `IF_Col.f90`       |
| Row         | Row       | `IF_Row.f90`       |
| Index       | Idx       | `IF_Idx.f90`       |
| Key         | Key       | `IF_Key.f90`       |
| Value       | Val       | `IF_Val.f90`       |
| Query       | Query     | `IF_Query.f90`     |
| Transaction | Trans     | `IF_Trans.f90`     |
| Commit      | Commit    | `IF_Commit.f90`    |
| Rollback    | Rollback  | `IF_Rollback.f90`  |
| Lock        | Lock      | `IF_Lock.f90`      |
| Unlock      | Unlock    | `IF_Unlock.f90`    |
| Cursor      | Cursor    | `IF_Cursor.f90`    |
| Statement   | Stmt      | `IF_Stmt.f90`      |
| Result      | Res       | `IF_Res.f90`       |
| Connection  | Conn      | `IF_Conn.f90`      |
| Pool        | Pool      | `IF_Pool.f90`      |
| Cache       | Cache     | `IF_Cache.f90`     |
| Buffer      | Buffer    | `IF_Buffer.f90`    |
| Queue       | Queue     | `IF_Queue.f90`     |
| Stream      | Stream    | `IF_Stream.f90`    |
| Batch       | Batch     | `IF_Batch.f90`     |
| Chunk       | Chunk     | `IF_Chunk.f90`     |
| Page        | Page      | `IF_Page.f90`      |
| Offset      | Offset    | `IF_Offset.f90`    |
| Limit       | Limit     | `IF_Limit.f90`     |
| Sort        | Sort      | `IF_Sort.f90`      |
| Filter      | Filter    | `IF_Filter.f90`    |
| Map         | Map       | `IF_Map.f90`       |
| Reduce      | Reduce    | `IF_Reduce.f90`    |
| Fold        | Fold      | `IF_Fold.f90`      |
| Aggregate   | Aggr      | `IF_Aggr.f90`      |
| Group       | Group     | `IF_Group.f90`     |
| Join        | Join      | `IF_Join.f90`      |
| Union       | Union     | `IF_Union.f90`     |
| Intersect   | Intersect | `IF_Intersect.f90` |
| Difference  | Diff      | `IF_Diff.f90`      |
| Projection  | Proj      | `IF_Proj.f90`      |
| Selection   | Sel       | `IF_Sel.f90`       |

### 14.7 系统相关缩写

| 全称            | 简称       | 示例                  |
| --------------- | ---------- | --------------------- |
| OperatingSystem | OS         | `IF_OS.f90`         |
| Kernel          | Kernel     | `IF_Kernel.f90`     |
| Driver          | Driver     | `IF_Driver.f90`     |
| Device          | Device     | `IF_Device.f90`     |
| Interrupt       | IRQ        | `IF_IRQ.f90`        |
| Exception       | Exception  | `IF_Exception.f90`  |
| Error           | Error      | `IF_Error.f90`      |
| Warning         | Warn       | `IF_Warn.f90`       |
| Info            | Info       | `IF_Info.f90`       |
| Debug           | Debug      | `IF_Debug.f90`      |
| Trace           | Trace      | `IF_Trace.f90`      |
| Log             | Log        | `IF_Log.f90`        |
| Audit           | Audit      | `IF_Audit.f90`      |
| Security        | Sec        | `IF_Sec.f90`        |
| Authentication  | Auth       | `IF_Auth.f90`       |
| Authorization   | Author     | `IF_Author.f90`     |
| Encryption      | Encrypt    | `IF_Encrypt.f90`    |
| Decryption      | Decrypt    | `IF_Decrypt.f90`    |
| Hash            | Hash       | `IF_Hash.f90`       |
| Signature       | Sign       | `IF_Sign.f90`       |
| Certificate     | Cert       | `IF_Cert.f90`       |
| Key             | Key        | `IF_Key.f90`        |
| Token           | Token      | `IF_Token.f90`      |
| Session         | Session    | `IF_Session.f90`    |
| Cookie          | Cookie     | `IF_Cookie.f90`     |
| Cache           | Cache      | `IF_Cache.f90`      |
| Memory          | Mem        | `IF_Mem.f90`        |
| Disk            | Disk       | `IF_Disk.f90`       |
| File            | File       | `IF_File.f90`       |
| Directory       | Dir        | `IF_Dir.f90`        |
| Path            | Path       | `IF_Path.f90`       |
| Link            | Link       | `IF_Link.f90`       |
| Mount           | Mount      | `IF_Mount.f90`      |
| Unmount         | Umount     | `IF_Umount.f90`     |
| Format          | Format     | `IF_Format.f90`     |
| Partition       | Part       | `IF_Part.f90`       |
| Volume          | Vol        | `IF_Vol.f90`        |
| Snapshot        | Snap       | `IF_Snap.f90`       |
| Backup          | Backup     | `IF_Backup.f90`     |
| Restore         | Restore    | `IF_Restore.f90`    |
| Archive         | Archive    | `IF_Archive.f90`    |
| Compress        | Compress   | `IF_Compress.f90`   |
| Decompress      | Decompress | `IF_Decompress.f90` |
| Extract         | Extract    | `IF_Extract.f90`    |

### 14.8 并发相关缩写

| 全称            | 简称       | 示例                  |
| --------------- | ---------- | --------------------- |
| Thread          | Thread     | `IF_Thread.f90`     |
| Process         | Proc       | `IF_Proc.f90`       |
| Task            | Task       | `IF_Task.f90`       |
| Job             | Job        | `IF_Job.f90`        |
| Worker          | Worker     | `IF_Worker.f90`     |
| Executor        | Exec       | `IF_Exec.f90`       |
| Scheduler       | Sched      | `IF_Sched.f90`      |
| Dispatcher      | Disp       | `IF_Disp.f90`       |
| Queue           | Queue      | `IF_Queue.f90`      |
| Pool            | Pool       | `IF_Pool.f90`       |
| Future          | Future     | `IF_Future.f90`     |
| Promise         | Promise    | `IF_Promise.f90`    |
| Async           | Async      | `IF_Async.f90`      |
| Await           | Await      | `IF_Await.f90`      |
| Mutex           | Mutex      | `IF_Mutex.f90`      |
| Semaphore       | Sem        | `IF_Sem.f90`        |
| Barrier         | Barrier    | `IF_Barrier.f90`    |
| Condition       | Cond       | `IF_Cond.f90`       |
| Lock            | Lock       | `IF_Lock.f90`       |
| ReadWriteLock   | RWLock     | `IF_RWLock.f90`     |
| SpinLock        | SpinLock   | `IF_SpinLock.f90`   |
| Atomic          | Atomic     | `IF_Atomic.f90`     |
| Volatile        | Volatile   | `IF_Volatile.f90`   |
| MemoryBarrier   | MemBar     | `IF_MemBar.f90`     |
| CacheCoherence  | CacheCo    | `IF_CacheCo.f90`    |
| Deadlock        | Deadlock   | `IF_Deadlock.f90`   |
| Livelock        | Livelock   | `IF_Livelock.f90`   |
| Starvation      | Starvation | `IF_Starvation.f90` |
| RaceCondition   | Race       | `IF_Race.f90`       |
| CriticalSection | CritSec    | `IF_CritSec.f90`    |

### 14.9 性能相关缩写

| 全称            | 简称       | 示例                  |
| --------------- | ---------- | --------------------- |
| Performance     | Perf       | `IF_Perf.f90`       |
| Latency         | Latency    | `IF_Latency.f90`    |
| Throughput      | Throughput | `IF_Throughput.f90` |
| Bandwidth       | BW         | `IF_BW.f90`         |
| Capacity        | Cap        | `IF_Cap.f90`        |
| Utilization     | Util       | `IF_Util.f90`       |
| Saturation      | Sat        | `IF_Sat.f90`        |
| Bottleneck      | Bottleneck | `IF_Bottleneck.f90` |
| Hotspot         | Hotspot    | `IF_Hotspot.f90`    |
| Profiling       | Prof       | `IF_Prof.f90`       |
| Tracing         | Trace      | `IF_Trace.f90`      |
| Sampling        | Sample     | `IF_Sample.f90`     |
| Instrumentation | Instr      | `IF_Instr.f90`      |
| Benchmark       | Bench      | `IF_Bench.f90`      |
| Metric          | Metric     | `IF_Metric.f90`     |
| Counter         | Counter    | `IF_Counter.f90`    |
| Gauge           | Gauge      | `IF_Gauge.f90`      |
| Histogram       | Hist       | `IF_Hist.f90`       |
| Summary         | Summary    | `IF_Summary.f90`    |
| Percentile      | Pct        | `IF_Pct.f90`        |
| Average         | Avg        | `IF_Avg.f90`        |
| Median          | Median     | `IF_Median.f90`     |
| Percentile      | Pct        | `IF_Pct.f90`        |
| Rate            | Rate       | `IF_Rate.f90`       |
| Ratio           | Ratio      | `IF_Ratio.f90`      |
| Frequency       | Freq       | `IF_Freq.f90`       |
| Duration        | Dur        | `IF_Dur.f90`        |
| Interval        | Intv       | `IF_Intv.f90`       |
| Timeout         | Timeout    | `IF_Timeout.f90`    |
| Retry           | Retry      | `IF_Retry.f90`      |
| Backoff         | Backoff    | `IF_Backoff.f90`    |
| CircuitBreaker  | CB         | `IF_CB.f90`         |
| RateLimiter     | RL         | `IF_RL.f90`         |
| Throttling      | Throttle   | `IF_Throttle.f90`   |

### 14.10 国际化相关缩写

| 全称                 | 简称    | 示例               |
| -------------------- | ------- | ------------------ |
| Internationalization | I18N    | `IF_I18N.f90`    |
| Localization         | L10N    | `IF_L10N.f90`    |
| Translation          | Trans   | `IF_Trans.f90`   |
| Locale               | Locale  | `IF_Locale.f90`  |
| Language             | Lang    | `IF_Lang.f90`    |
| Region               | Region  | `IF_Region.f90`  |
| TimeZone             | TZ      | `IF_TZ.f90`      |
| Currency             | Curr    | `IF_Curr.f90`    |
| NumberFormat         | NumFmt  | `IF_NumFmt.f90`  |
| DateFormat           | DateFmt | `IF_DateFmt.f90` |
| TimeFormat           | TimeFmt | `IF_TimeFmt.f90` |
| Calendar             | Cal     | `IF_Cal.f90`     |
| Collation            | Coll    | `IF_Coll.f90`    |
| CharacterSet         | CharSet | `IF_CharSet.f90` |
| Encoding             | Enc     | `IF_Enc.f90`     |
| Unicode              | Unicode | `IF_Unicode.f90` |
| UTF8                 | UTF8    | `IF_UTF8.f90`    |
| UTF16                | UTF16   | `IF_UTF16.f90`   |
| UTF32                | UTF32   | `IF_UTF32.f90`   |
| ASCII                | ASCII   | `IF_ASCII.f90`   |

---

*文档完成时间：2026-04-24*
*最后修订：2026-04-24（命名文档套件；§3.1/§3.7/§3.8 两段式语义一致；§3.4 长表说明；§7.3 工具配置；`_Balancer` 修正）*
*版本：v1.0*
*状态：初稿待审查*
