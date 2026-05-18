# UFC Harness Engineering 系统设计方案

> **设计日期**: 2026-03-23  
> **基于**: Harness Engineering 生产级 AI Agent Runtime 架构  
> **目标**: 文档管理、代码开发、算法落实、架构完善与打通

---

## 导读：生产级 Harness 定位与五层责任

### 整体定位

- **模型**：负责推理与决策（引擎）。
- **Harness**：负责让 Agent **持续、稳定完成**任务（执行环境、工具、控制、记忆与评估的一体化运行时）。
- **一句话**：模型决定「能做什么」，Harness 决定「能不能稳定做完」。

### 五层与 UFC 映射（与下文第二章架构图及第三～七章一致）

| 层 | 核心目标（摘要） |
|----|------------------|
| **Environment** | 受控工作空间：代码与文档仓库、构建与验证环境；默认**不直连生产**，风险隔离。 |
| **Tool** | 将复杂能力封装为**小而清晰、单职责**的接口，降低调用错误与时机错误。 |
| **Control** | 步数上限、超时、工具调用频率、阶段流转与异常处理，防止无限循环、资源耗尽与任务漂移。 |
| **Memory** | 外存中的任务状态、历史与关键决策；与**模型上下文窗口**分工，支持长流程与断点恢复。 |
| **Evaluation** | 对关键步骤与产出做自动验证；**不默认盲信模型输出**，失败时可反馈并驱动修正或重试。 |

### 模块关系（实现提示）

架构图**自上而下**表示**职责分层**。实际运行时允许 **Memory、Evaluation 与控制逻辑横向协作**（例如检查点写入、评估触发与调度并发或交错），**不必**实现为严格的单链流水线。

### 设计原则（摘要）

- **解耦**：状态与硬规则尽量由 Harness 管理，而非完全堆进 Prompt。
- **可控**：用代码与流程约束执行，而非依赖模型自觉。
- **简单**：工具接口越小、越单一，模型调用越稳定。
- **持久**：任务状态可落盘，支持恢复与回放。
- **可观测**：完整执行轨迹便于调试、审计与优化。

---

## 一、UFC 当前架构现状

### 1.1 层级结构
```
UFC/
├── ufc_core/          # 核心模块 (2316 文件, 307 目录)
├── PLAN/              # 文档中心 (324 文件)
├── build/             # 编译输出 (974 文件)
├── docs/              # 技术文档 (128 文件)
├── REPORTS/          # 报告输出 (65 文件)
├── scripts/           # 脚本工具
└── tools/             # 辅助工具
```

### 1.2 六层架构 (L1-L6)
- **L1_IF**: 接口层 (Base, Error, IO, Log, Memory, Persist, Precision)
- **L2_NM**: 数值算法层 (Base, Bridge, Eigen, LinearAlgebra, Solver, TimeIntegration)
- **L3_MD**: 模型数据层 (Assembly, Interaction, KeyWord, LoadBC, Material, Mesh, Model, Output, Part, Section, Step, WriteBack)
- **L4_PH**: 物理层次 (Brg, Constraint, Contact, Coupling, Element, LoadBC, Material)
- **L5_RT**: 运行时层 (Assembly, Bridge, Contact, Element, Logging, Output, Solver, Step)
- **L6_AP**: 应用层 (Base, Bridge, Input, Output, Solver, UI)

### 1.3 现有痛点
| 痛点 | 说明 |
|------|------|
| 文档分散 | PLAN 有 324 份文档，散布在各子目录 |
| 代码量大 | ufc_core 超过 2300 个文件 |
| 层级打通难 | L3/L4/L5 跨层调用复杂 |
| 算法落实慢 | 新算法缺少标准化落地图谱 |
| 架构完善难 | 50+ 示解文档待收敛为 10 章 |

---

## 二、UFC Harness 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                    UFC Harness Runtime System                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     Environment Layer                     │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ │  │
│  │  │ 代码仓库  │ │ 文档仓库  │ │ 构建环境 │ │ 验证环境   │ │  │
│  │  │ ufc_core │ │   PLAN   │ │  build/  │ │ verification│ │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                       Tool Layer                            │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌─────────┐  │  │
│  │  │代码生成│ │文档生成│ │编译构建│ │测试验证│ │命名检查│  │  │
│  │  │Tool   │ │Tool    │ │Tool    │ │Tool    │ │Tool    │  │  │
│  │  └────────┘ └────────┘ └────────┘ └────────┘ └─────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     Control Layer                           │  │
│  │  ┌────────────┐ ┌────────────┐ ┌─────────────────────────┐  │  │
│  │  │ 任务调度器 │ │ 流程控制器 │ │ 异常处理与恢复机制      │  │  │
│  │  │ TaskRunner │ │ PhaseCtrl  │ │ ErrorHandler & Recovery │  │  │
│  │  └────────────┘ └────────────┘ └─────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                      Memory Layer                           │  │
│  │  ┌────────────┐ ┌────────────┐ ┌─────────────────────────┐  │  │
│  │  │ 任务状态库 │ │ 历史轨迹库 │ │ 知识图谱库              │  │  │
│  │  │TaskState  │ │HistoryLog  │ │KnowledgeGraph           │  │  │
│  │  └────────────┘ └────────────┘ └─────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Evaluation Layer                         │  │
│  │  ┌────────────┐ ┌────────────┐ ┌─────────────────────────┐  │  │
│  │  │ 代码质量   │ │ 文档质量   │ │ 架构一致性              │  │  │
│  │  │ Evaluator │ │ Evaluator │ │ Evaluator               │  │  │
│  │  └────────────┘ └────────────┘ └─────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 五层核心模块详解

---

## 三、Environment Layer - UFC 环境层

### 3.1 职责
为 AI Agent 提供可工作的 UFC 世界，包括代码、文档、构建系统等。

### 3.2 核心组件

| 组件 | 说明 | 位置 |
|------|------|------|
| **CodeRepository** | ufc_core 源码仓库 | `d:\TEST7\UFC\ufc_core\` |
| **DocRepository** | PLAN 文档仓库 | `d:\TEST7\UFC\PLAN\` |
| **BuildSystem** | CMake/Fortran 编译环境 | `d:\TEST7\UFC\build\` |
| **VerificationEnv** | 验证用例环境 | `d:\TEST7\UFC\verification\` |
| **ReportSystem** | 输出报告系统 | `d:\TEST7\UFC\REPORTS\` |

### 3.3 接口设计

```fortran
! UFC_Environment_Module.f90
module ufc_harness_environment
    implicit none
    
    type :: UFC_Environment
        character(len=512) :: root_path
        character(len=512) :: code_repo_path
        character(len=512) :: doc_repo_path
        character(len=512) :: build_path
        logical :: is_initialized
    contains
        procedure :: init_environment
        procedure :: get_source_files
        procedure :: get_doc_files
        procedure :: get_build_status
    end type UFC_Environment

contains

    subroutine init_environment(this, root_path)
        class(UFC_Environment), intent(inout) :: this
        character(len=*), intent(in) :: root_path
        this%root_path = trim(root_path)
        this%code_repo_path = trim(root_path)//'\ufc_core'
        this%doc_repo_path = trim(root_path)//'\PLAN'
        this%build_path = trim(root_path)//'\build'
        this%is_initialized = .true.
    end subroutine init_environment

end module ufc_harness_environment
```

### 3.4 对应 UFC 现有模块
- **ufc_infra**: 基础设施层
- **ufc_config**: 配置管理

---

## 四、Tool Layer - 工具层

### 4.1 职责
封装 UFC 各种能力为简单、标准化的工具接口。

### 4.2 核心工具集

| 工具名称 | 功能说明 | 底层实现 |
|----------|----------|----------|
| **CodeGenerator** | 生成 Fortran 代码模板 | 基于 UFC_SUFFIX_MINIMAL_PLAN.md |
| **DocGenerator** | 生成文档模板 | 基于 PLAN 目录结构 |
| **BuildTool** | 执行 CMake/编译 | build/ 目录 |
| **TestRunner** | 运行验证用例 | verification/ 目录 |
| **NamingChecker** | 命名规范检查 | 基于 UFC_NAMING_STANDARD.md |
| **DependencyAnalyzer** | 分析模块依赖 | USE 语句解析 |
| **ArchValidator** | 验证架构一致性 | L1-L6 层级校验 |
| **ContractGenerator** | 生成合同卡 | 基于 UFC 合同卡模板 |

### 4.3 接口设计

```fortran
! UFC_Tool_Module.f90
module ufc_harness_tools
    implicit none
    
    ! 工具接口定义
    type, abstract :: UFC_Tool
        character(len=256) :: tool_name
        logical :: is_available
    contains
        procedure(tool_execute), deferred :: execute
        procedure(tool_validate), deferred :: validate
    end type UFC_Tool
    
    abstract interface
        subroutine tool_execute(tool, input_data, output_data, status)
            import UFC_Tool
            class(UFC_Tool), intent(inout) :: tool
            class(*), intent(in) :: input_data
            class(*), intent(out) :: output_data
            integer, intent(out) :: status
        end subroutine tool_execute
        
        subroutine tool_validate(tool, result, is_valid)
            import UFC_Tool
            class(UFC_Tool), intent(in) :: tool
            class(*), intent(in) :: result
            logical, intent(out) :: is_valid
        end subroutine tool_validate
    end interface

end module ufc_harness_tools
```

---

## 五、Control Layer - 控制层

### 5.1 职责
管理 Agent 执行流程，防止失控，确保任务按 UFC 流程执行。

### 5.2 核心组件

| 组件 | 说明 | 对应 UFC 流程 |
|------|------|---------------|
| **TaskScheduler** | 任务调度器 | Phase 1 → Phase 2 |
| **PhaseController** | 阶段控制器 | UFC 架构治理各阶段 |
| **FlowManager** | 流程管理器 | L3/L4/L5 打通流程 |
| **ErrorHandler** | 异常处理器 | 错误恢复机制 |
| **RecoveryManager** | 恢复管理器 | 任务续接与回滚 |

### 5.3 UFC 特定控制规则

```fortran
! UFC_Control_Module.f90
module ufc_harness_control
    implicit none
    
    ! UFC 阶段定义
    integer, parameter :: PHASE_INIT = 1
    integer, parameter :: PHASE_1 = 2    ! 文档审查 + 代码收敛
    integer, parameter :: PHASE_2 = 3    ! 核心模块开发
    integer, parameter :: PHASE_3 = 4   ! 集成测试
    integer, parameter :: PHASE_4 = 5   ! 生产交付
    
    ! 最大执行步数限制
    integer, parameter :: MAX_STEPS_PER_TASK = 100
    integer, parameter :: MAX_STEPS_PER_PHASE = 1000
    
    type :: UFC_TaskControl
        integer :: current_phase
        integer :: step_count
        integer :: max_steps
        logical :: is_running
        character(len=256) :: current_task
    contains
        procedure :: can_continue
        procedure :: check_phase_transition
        procedure :: handle_error
    end type UFC_TaskControl

contains

    logical function can_continue(this)
        class(UFC_TaskControl), intent(in) :: this
        can_continue = this%is_running .and. &
                       this%step_count < this%max_steps
    end function can_continue

end module ufc_harness_control
```

### 5.4 生产级控制补充（安全护栏与资源边界）

在 5.2、5.3 的阶段与步数约束之外，建议将下列能力**显式纳入控制层配置与实现**（与 Agent 运行时同源思路，便于与 UFC Phase / CI 对齐）：

| 能力 | 说明 | UFC 侧落点示例 |
|------|------|----------------|
| **最大执行步数** | 单任务 / 单阶段步数上限，防止死循环与无意义重复 | 与 `MAX_STEPS_*` 一致；可在 `harness_config` 或任务元数据中覆盖 |
| **任务与工具超时** | 单次调用或整段流程 wall-clock 上限，避免资源挂死 | 文档检查、编译、验证子进程统一超时策略 |
| **工具调用频率 / 配额** | 单位时间内调用次数或并发上限，防滥用与异常风暴 | 对重型工具（全量构建、全树扫描）单独限流 |
| **中断、重试与回滚** | 可取消、可重试步骤、失败回滚到检查点 | 与 Memory 层检查点及 RecoveryManager 配合 |
| **允许工具白名单 / 环境隔离** | 仅暴露约定工具集；默认工作区限于仓库或 CI 沙箱 | 与 Environment 层「不直连生产」一致 |

**原则**：控制策略尽量**数据驱动**（配置可审可改），并在日志中记录触发原因（步数耗尽、超时、限流），满足可观测要求。

---

## 六、Memory Layer - 记忆层

### 6.1 职责
解决长流程任务的记忆问题，支持任务状态持久化。

### 6.2 核心存储

| 存储类型 | 说明 | 数据结构 |
|----------|------|----------|
| **TaskStateDB** | 当前任务状态 | JSON/SQLite |
| **HistoryLog** | 历史执行轨迹 | 日志文件 |
| **KnowledgeGraph** | UFC 知识图谱 | 图数据库 |
| **ContractDB** | 合同卡状态库 | CSV/JSON |
| **PhaseProgress** | 阶段进度记录 | Markdown |

### 6.3 接口设计

```fortran
! UFC_Memory_Module.f90
module ufc_harness_memory
    implicit none
    
    type :: UFC_TaskState
        integer :: task_id
        character(len=256) :: task_name
        integer :: phase
        integer :: step
        character(len=512) :: goal
        character(len=2048) :: history
        logical :: is_completed
        character(len=256) :: checkpoint
    end type UFC_TaskState
    
    type :: UFC_MemorySystem
        type(UFC_TaskState), allocatable :: task_states(:)
        integer :: max_tasks
        integer :: current_task_count
    contains
        procedure :: save_state
        procedure :: load_state
        procedure :: get_task_history
        procedure :: create_checkpoint
        procedure :: restore_from_checkpoint
    end type UFC_MemorySystem

end module ufc_harness_memory
```

### 6.4 短期记忆与长期记忆分工（上下文注入）

| 类型 | 载体 | 用途 |
|------|------|------|
| **短期记忆** | 模型**当前上下文窗口** | 本轮推理、近期工具结果摘要、当前子目标 |
| **长期记忆** | **外部存储**（TaskStateDB、HistoryLog、ContractDB、检查点文件等） | 跨会话任务状态、完整轨迹、关键决策与可恢复快照 |

**工作方式**：

- 长期记忆**不全量**塞进上下文；由 Harness **按需检索、摘要、注入**（例如当前 Phase、未决合同缺口、上次失败原因），控制 token 与噪声。
- 与 **Control** 配合：检查点写入 / 恢复前，Memory 提供一致的状态视图；与 **Evaluation** 配合：保留评估结果与复现路径（日志、报告路径），便于「失败后重试」仍可追溯。

---

## 七、Evaluation Layer - 评估层

### 7.1 职责
自动验证任务结果质量，确保 UFC 架构一致性。

### 7.2 评估器集合

| 评估器 | 验证内容 | 验收标准 |
|--------|----------|----------|
| **CodeQualityEvaluator** | 代码质量 | 符合 UFC_NAMING_STANDARD.md |
| **DocQualityEvaluator** | 文档质量 | PLAN 目录结构规范 |
| **ArchConsistencyEvaluator** | 架构一致性 | L1-L6 层级调用链完整 |
| **ContractCompletenessEvaluator** | 合同卡完整性 | 所有域合同卡已定义 |
| **BuildSuccessEvaluator** | 编译成功 | build/ 无错误 |
| **TestPassEvaluator** | 验证通过 | verification/ 用例全过 |

### 7.3 接口设计

```fortran
! UFC_Evaluation_Module.f90
module ufc_harness_evaluation
    implicit none
    
    type, abstract :: UFC_Evaluator
        character(len=256) :: evaluator_name
        logical :: is_enabled
    contains
        procedure(eval_execute), deferred :: execute
        procedure(eval_get_score), deferred :: get_score
    end type UFC_Evaluator
    
    type :: UFC_EvaluationResult
        logical :: is_passed
        integer :: score
        character(len=1024) :: message
        character(len=512) :: details_file
    end type UFC_EvaluationResult

end module ufc_harness_evaluation
```

### 7.4 验证闭环与错误反馈（阻断错误传播）

评估层不仅产出「通过 / 不通过」，还应支撑 **Agent 控制环**：

1. **不默认接受模型输出**：对变更文件、构建结果、合同完整性等关键节点，在合并或进入下一阶段前必须经过约定 Evaluator（自动测试、规则校验、架构/文档检查等）。
2. **失败结构化反馈**：向控制层与（若适用）模型侧返回**可行动**信息：失败 Evaluator 名称、退出码、日志/报告路径、涉及路径列表，避免仅有一句自然语言描述。
3. **重试与修正策略**：由 **Control** 定义上限内的重试、回退到检查点或终止；Memory 记录每次评估结果，防止同一错误无改进地循环。
4. **可选高阶评审**：在规则与测试之外，可增加「模型评审」等辅助手段，但**不应替代**可重复的门禁（构建、测试、合同校验）。

**目标**：减少「一步错、步步错」；使错误在 Harness 边界被拦截，并具备可观测、可复现的修复路径。

---

## 八、UFC 特定工具集

### 8.1 代码开发工具

| 工具 | 功能 |
|------|------|
| **ModuleScaffold** | 生成模块脚手架 |
| **TypeGenerator** | 生成 TYPE 定义 |
| **InterfaceWrapper** | 生成接口包装 |
| **TestCaseGenerator** | 生成测试用例 |

### 8.2 文档管理工具

| 工具 | 功能 |
|------|------|
| **DocStructureChecker** | 检查 PLAN 目录结构 |
| **CrossRefValidator** | 验证文档交叉引用 |
| **NamingConventionValidator** | 验证命名规范一致性 |
| **RedundancyDetector** | 检测冗余文档 |

### 8.3 算法落地图谱工具

| 工具 | 功能 |
|------|------|
| **AlgoTracingTool** | 算法实现追踪 |
| **ContractLinker** | 合同卡与代码关联 |
| **L3L4L5Mapper** | 层级打通映射 |

---

## 九、实施路线图

### Phase 1: 基础设施搭建 (1-2 周)
```
Week 1:
├── Environment Layer 基础搭建
│   ├── 代码仓库接口
│   ├── 文档仓库接口
│   └── 构建系统接口
├── 定义核心数据类型
└── 建立日志系统

Week 2:
├── Tool Layer 基础工具集
│   ├── 代码生成工具
│   ├── 命名检查工具
│   └── 构建触发工具
└── Control Layer 框架
```

### Phase 2: 核心功能实现 (2-3 周)
```
Week 3:
├── Memory Layer 实现
│   ├── 任务状态存储
│   └── 历史轨迹记录
├── Evaluation Layer 基础评估器
│   ├── 命名规范评估
│   └── 文档结构评估
└── 与现有 PLAN 集成

Week 4:
├── 完整工具链测试
├── L3/L4/L5 打通流程验证
└── 合同卡生成工具开发
```

### Phase 3: 生产级优化 (1 周)
```
Week 5:
├── 错误处理与恢复机制
├── 性能优化
├── 可观测性增强 (日志/追踪)
└── 与 CI/CD 集成
```

---

## 十、关键设计原则

### 原则 1: 状态从 Agent 剥离
- 模型只负责当前推理
- 任务状态存储在系统数据库
- 避免上下文膨胀

### 原则 2: 规则写进系统
- UFC 命名规范 → 代码强制检查
- 架构一致性 → 自动校验
- 不依赖模型自觉遵守

### 原则 3: 工具接口简单
- 每个工具只完成一个明确任务
- 避免超级 API
- 降低调用错误率

### 原则 4: 状态持久化
- 支持任务恢复
- 支持执行回放
- 支持日志审计

### 原则 5: 完全可观测
- 完整记录推理过程
- 完整记录工具调用
- 完整记录状态变化

---

## 十一、文件位置规划

```
d:\TEST7\UFC\
├── ufc_harness/                    # ⭐ 新增：Harness 系统
│   ├── src/
│   │   ├── ufc_harness_environment.f90
│   │   ├── ufc_harness_tools.f90
│   │   ├── ufc_harness_control.f90
│   │   ├── ufc_harness_memory.f90
│   │   └── ufc_harness_evaluation.f90
│   ├── config/
│   │   └── harness_config.json
│   ├── tools/                      # 工具集
│   │   ├── naming_checker/
│   │   ├── doc_generator/
│   │   └── contract_generator/
│   ├── memory/                     # 状态存储
│   │   ├── task_states.db
│   │   ├── history/
│   │   └── checkpoints/
│   └── logs/                       # 执行日志
│
├── ufc_core/                        # 现有代码
├── PLAN/                            # 现有文档
└── ...
```

---

## 十二、总结

UFC Harness Engineering 系统将基于 **Harness Engineering** 的五层架构，为 UFC 提供：

1. **稳定运行环境** - 代码、文档、构建一体化
2. **标准化工具集** - 覆盖开发、文档、验证全流程
3. **流程控制** - Phase 1-4 阶段管理，防止失控
4. **记忆系统** - 长流程任务状态持久化
5. **质量评估** - 自动验证架构一致性

通过这套系统，UFC 将实现：
- **文档管理**: PLAN 目录结构自动校验
- **代码开发**: 标准化模块生成与验证
- **算法落地图谱**: L3/L4/L5 打通流程自动化
- **架构完善**: 50+ 文档 → 10 章结构化文档

---

*设计完成 | 等待下一步实施指令*