# Analysis域合同卡 (L3_MD/Analysis)

**Layer**: L3_MD (模型数据层)  
**Domain**: Analysis (分析步/幅值/求解器配置)  
**Version**: v2.3  
**Created**: 2026-04-17  
**Updated**: 2026-05-12  
**Status**: ✅ 正交设计已实施

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 报告侧：过程算法叙事（stub / archive）

- **入口（根 stub）**：[`Analysis_Procedure_Algorithm.md`](../../../REPORTS/Analysis_Procedure_Algorithm.md)；长文：[`archive/Analysis_Procedure_Algorithm.md`](../../../REPORTS/archive/Analysis_Procedure_Algorithm.md)。
- **Registry**：[Domain Procedure Registry](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)（与叙事无机器对账；优先级见该 README）。

### L4 无独立域决策（半贯通柱）

**Analysis 域在 L4 层无独立域目录。**  

理由：
1. **三步状态机编排核心在 L5**：`RT_StepDriver` + `RT_Solv_Mgr` 拥有 Step/Inc/Iter 状态机的唯一权威
2. **L4 物理核采用消费式调用**：Element/Material/Contact 等 L4 域以被动方式响应 StepDriver 调度信号，不需要独立编排
3. **L3/L5 边界已足够**：L3 定义分析步配置（`MD_Step_Mgr`），L5 执行编排（`RT_StepDriver` + `RT_Solv_Mgr`）

关键约束：
- 三步状态机真源：`RT_StepDriver_State`(L5) 唯一持有 step_status/inc_status/iter_status
- 求解器状态真源：`RT_Solv_NRState`(L5) 唯一持有收敛规范/迭代计数
- L3 配置走 Brg 灌入：`RT_Step_Brg` / `RT_Solv_Brg` 消费 L3 定义
- L4 不建 Analysis 四型：禁止 `PH_Step_*` / `PH_Solver_*` / `PH_Coupling_*` 独立域

详见 [`L4_Gap_Domain_Decisions.md`](../../../REPORTS/archive/L4_Gap_Domain_Decisions.md) §3（冷归档全文）

## 一、职责边界

### 核心职责
- **定位**: UFC L3_MD层Analysis域，分析步、幅值曲线、求解器配置的建模与管理
- **职责**: 分析步定义(Static/Dynamic/Heat等)、幅值曲线定义(Tabular/Smooth/Ramp等)、求解器参数配置
- **边界**: 仅提供分析建模数据；求解执行由L5_RT StepDriver域处理
- **依赖**: L3_MD/Model(模型树), L3_MD/Boundary(边界条件)

### 子域划分
| 子域 | 职责 | 合同卡 |
|------|------|--------|
| **Step** | 分析步定义(类型/时间/增量) | Step/CONTRACT.md |
| **Amplitude** | 幅值曲线定义与求值 | Amplitude/CONTRACT.md |
| **Solver** | 求解器参数配置 | Solver/CONTRACT.md |
| **AnalysisCompat** | 3D正交兼容矩阵(Solver×Coupling×Physics) | 本文 §十七 |

### Analysis 三子域统一标准（实现与合同对齐）

| 项目 | Step | Amplitude | Solver |
|------|------|-----------|--------|
| **精度** | `IF_Prec_Core`：`wp` / `i4` | 同左 | 同左 |
| **错误语义** | `ErrorStatusType`；成功路径须置 **`IF_STATUS_OK`** | 同左 | 同左 |
| **SIO** | 见各域 **SIO / `*_Arg`（本域偏好）** 与 **`AGENTS.md`** §5 | 同左 | 同左 |
| **核心源码（真源）** | `MODULE MD_Step_Def` / `MD_Step_Mgr` / `MD_Step_Proc` / `MD_Step_Sync`（**步域容器：`MODULE MD_Step_Mgr`**） | `MD_Amp_Def` / `MD_Amp_Mgr` / `MD_Amp_UF` / `MD_Amp_Idx` | `MD_Solv_Def` / **`MODULE MD_Solv_Mgr`** / `MD_Solv_Sync` |

---

## 二、文件清单（按子域；以各子目录源码为准）

### AnalysisCompat 子域（域级，**2** 个 L3 实现文件）

| 文件 | 职责 |
|------|------|
| `MD_Ana_Comp.f90` | **`MODULE MD_Ana_Comp`**：3D 正交兼容矩阵（常量 `AC_*`、`MD_Ana_Comp_Group_Desc`、`GROUP_MAT/ELEM_COMPAT`）+ 查询（`CheckTriple`/`ProcToGroup`/`PhysToGroup`）+ 桥接验证（`ValidateStep`/`FullCheck`） |
| `MD_Ana_Brg.f90` | **`MODULE MD_Ana_Brg`**：Analysis 子域 **注册表**（`MD_Ana_Brg_Register` / `Lookup` / `Iterate` / `Finalize`）；**`MD_Ana_Brg_InitCompat`** 冷入口转发 **`MD_Ana_Comp_Init`**；**单向** `USE MD_Ana_Comp, ONLY: MD_Ana_Comp_Init`（与 `MD_Ana_Comp` 头注释一致） |

#### 引用附录（**不计入**上表「实现文件」计数）

| 文件 | 职责 |
|------|------|
| `../../L1_IF/Base/RT_SolverType_Def.f90` | **`MODULE RT_SolverType_Def`**：8 个求解器路由常量 `RT_SOLVER_*`（**L1_IF** 真源；Analysis 域 **`USE`** 消费，非本目录实现） |

### Step子域（4 个实现文件 + 合同）
| 文件 | 职责 |
|------|------|
| `MD_Step_Def.f90` | **`MODULE MD_Step_Def`**：仅 **`MD_Step_State` / `MD_Step_Ctx`**（四型中的 State/Ctx）；**`MD_Step_Desc` / `MD_Step_Domain` / `StepAlgo`** 定义在 **`MD_Step_Mgr`** |
| `MD_Step_Mgr.f90` | **`MODULE MD_Step_Mgr`**：**`MD_Step_Domain`**、**`MD_Step_Desc`**、**`StepAlgo`**、TBP、SIO `MD_Step_*_Arg`、`WriteBack` / `AdvanceStep` 等（步域 **AUTHORITY**；原规划名 `MD_Step.f90` / `MODULE MD_Step` 已弃用） |
| `MD_Step_Proc.f90` | **`MODULE MD_Step_Proc`**：过程常量 **`PROC_*`**、`UF_Step*` / `UF_AnalysisStep` 等 |
| `MD_Step_Sync.f90` | **`MODULE MD_Step_Sync`**：**`MD_Step_SyncFromLegacy`**（legacy `step_mgr` → 域） |
| `Step/CONTRACT.md` | 域合同真源 |

### Amplitude子域 (4个实现文件 + 合同)
| 文件 | 职责 |
|------|------|
| MD_Amp_Def.f90 | 四型与 `MD_Amp_Domain`；`MD_Amp_Desc` DataPlatform；**SIO `*_Arg` + `Apply_*`**；**`MD_AmpShared_*`**（原 EvalShared）；不 USE `MD_Amp_Mgr` |
| MD_Amp_UF.f90 | **`MD_Amp_Slot_*`**、**`MD_Amp_Ext_Desc` / `MD_Amp_FromExt*`**（原 Brg）、**`evaluate`**、UAMP **`MD_Amp_Eval_*`**（详 Amplitude/CONTRACT.md v2.19） |
| MD_Amp_Mgr.f90 | **`Amp_GetFactor`**、**`MD_Amp_Slot_To_MD_Desc`**、**`MD_Amp_SyncFromLegacy`**（原 Sync）；再导出 **`MD_Amp_Slot_*` / `MD_Amp_MATH_PI`**、**SIO `*_Arg`/`Apply_*`** |
| MD_Amp_Idx.f90 | 依赖 `g_ufc_global` 的按索引 Get；**仅 `USE MD_Amp_Def`** |
| Amplitude/CONTRACT.md | 域合同真源 |

### Solver子域 (3个实现文件 + 合同)
| 文件 | 职责 |
|------|------|
| MD_Solv_Def.f90 | **`MODULE MD_Solv_Def`**：四型 + **`MD_Solver_Desc_*`** |
| MD_Solv_Mgr.f90 | **`MODULE MD_Solv_Mgr`**：`MD_Solver_Domain`、SIO、**`MD_Solver_Brg_GetConfigForStep*`**（原 **`MD_Solv_Brg`**） |
| MD_Solv_Sync.f90 | **`MODULE MD_Solv_Sync`**：**`MD_Solver_SyncFromStep`**（与 **`MD_Solv_Mgr` 分文件** 破 **`MD_L3Layer`↔`MD_Solv_Mgr` 环**） |
| Solver/CONTRACT.md | 域合同真源 |

---

## 三、四类TYPE映射

### Step子域
| Type种类 | TYPE名称 | 核心职责 |
|----------|----------|----------|
| **Desc** | MD_Step_Desc | 分析步描述符(step_type/time_period/n_increments) |
| **State** | MD_Step_State | 分析步状态(current_increment/current_time) |
| **Algo** | MD_Step | 分析步算法参数(solver_type/convergence_tol) |
| **Ctx** | MD_Step_Ctx | 分析步执行上下文(step_idx/incr_idx) |

### Amplitude子域
| Type种类 | TYPE名称 | 核心职责 |
|----------|----------|----------|
| **Desc** | MD_Amp_Desc | 幅值描述符(24字段,含tabular_extrapolate/smooth_*) |
| **State** | MD_Amp_State | 幅值状态(currentValue) |
| **Algo** | MD_Amp_Algo | 插值策略 |
| **Ctx** | MD_Amp_Eval_Ctx | 求值上下文(step_idx/incr_idx/time) |

### Solver子域
| Type种类 | TYPE名称 | 核心职责 |
|----------|----------|----------|
| **Desc** | MD_Solver_Desc | 求解器描述符（容差、迭代、稳定化等；见 `MD_Solv_Def`） |
| **Algo** | MD_Solver_Algo | 算法参数占位（Newton/回切等；与 Step 侧 `sol_ctrl` 并行建模） |
| **State** | MD_Solver_State | 运行时统计占位（迭代计数、收敛标记等） |
| **Ctx** | MD_Solver_Ctx | 瞬态上下文占位（范数缓冲、工作向量指针等） |

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | 分析步理论→时间积分方案→求解器选择 |
| **逻辑链** | Analysis↔Boundary(载荷幅值)↔L5_RT(步进驱动)闭环 |
| **计算链** | L3 无数值 PDE/无全局求解；Amplitude 子域允许 **有界 A(t) 标量求值**（与 `MD_Amp_Mgr` 一致） |
| **数据链** | MD_Step_Desc→L5_RT_StepDriver; MD_Amp_Desc→L4_PH（`PH_Brg_GetAmplitudeValue_Idx`）/L5_RT（`md_layer%amplitude%EvalAtTime` 或 `RT_Amp_FactorAt`） |

---

## 五、核心接口清单

### Step子域
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Step_Init | 初始化分析步域 | status |
| MD_Step_Register | 注册分析步 | step_desc, step_id, status |
| MD_Step_Query | 查询分析步 | step_id, step_desc, status |
| MD_Step_Validate | 验证分析步 | step_desc, status |

### Amplitude子域
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Amp_Init | 初始化幅值域 | status |
| MD_Amp_Register | 注册幅值曲线 | amp_desc, amp_id, status |
| MD_Amp_EvalAtTime | 求值A(t) | amp_id, time, value, status |
| MD_Amp_Slot_To_MD_Desc | 槽 Desc→域 Desc 映射 | slot_desc, md_desc, status |

### Solver子域
| 接口 | 功能 | 参数 |
|------|------|------|
| `MD_Solver_Domain%Init` / `%Finalize` | 求解器配置域生命周期 | `initial_capacity`, `status` |
| `MD_Solver_Domain%AddConfig` / `%GetConfig` | 增删查配置槽 | `desc`, `config_id`, `status` |
| `MD_Solver_GetConfig_Idx` | 经 `g_ufc_global` 按 `config_id` 取 Desc | `config_id`, `arg`, `status` |
| `MD_Solver_Brg_GetConfigForStep*` | 按步索引取与步绑定的配置（L5 选路） | 见 `MD_Solv` |
| **`MD_Solver_SyncFromStep`** | Step `sol_ctrl` → 域 + `solver_config_id` | `md_layer`, `status`（**`MODULE MD_Solv_Sync`**） |
| **`MD_Solver_Apply_*_Arg`**（`MD_Solv`） | 域 TBP 的 SIO 封装（Add/Get/Summary / Idx / Brg） | 见 `Solver/CONTRACT.md` 细粒度表 |
| **`MD_Solver_Desc_From_Algo`** / **`MD_Solver_Algo_From_Desc`** | Desc ↔ Algo 重叠字段互转 | `MD_Solv_Def` |

---

## 六、分析步类型枚举

```fortran
! 静态分析
INTEGER(i4), PARAMETER :: MD_STEP_STATIC_GENERAL = 1_i4
INTEGER(i4), PARAMETER :: MD_STEP_STATIC_RIKS = 2_i4      ! 弧长法

! 动力分析
INTEGER(i4), PARAMETER :: MD_STEP_DYNAMIC_IMPLICIT = 3_i4  ! 隐式动力
INTEGER(i4), PARAMETER :: MD_STEP_DYNAMIC_EXPLICIT = 4_i4  ! 显式动力

! 热分析
INTEGER(i4), PARAMETER :: MD_STEP_HEAT_TRANSFER = 5_i4

! 频率分析
INTEGER(i4), PARAMETER :: MD_STEP_FREQUENCY = 6_i4

! 屈曲分析
INTEGER(i4), PARAMETER :: MD_STEP_BUCKLE = 7_i4
```

---

## 七、幅值类型枚举

```fortran
! 幅值类型(与MD_Amp_Slot_Desc对齐)
INTEGER(i4), PARAMETER :: AMP_TABULAR = 1_i4       ! 表格幅值
INTEGER(i4), PARAMETER :: AMP_SMOOTH = 2_i4        ! 平滑阶跃
INTEGER(i4), PARAMETER :: AMP_RAMP = 3_i4          ! 斜坡幅值
INTEGER(i4), PARAMETER :: AMP_PERIODIC = 4_i4      ! 周期幅值
INTEGER(i4), PARAMETER :: AMP_MODULATED = 5_i4     ! 调制幅值
INTEGER(i4), PARAMETER :: AMP_DECAY = 6_i4         ! 指数衰减
INTEGER(i4), PARAMETER :: AMP_USER = 7_i4          ! 用户自定义
```

---

## 八、依赖关系

### 向上依赖(被谁使用)
- L5_RT/StepDriver: 分析步驱动
- L4_PH/LoadBC: 载荷幅值求值
- L3_MD/Boundary: 边界条件幅值引用

### 向下依赖(依赖谁)
- L3_MD/Model: 模型树管理
- L1_IF/Symbol: 分析步类型常量

---

## 九、命名规范验证

### 模块前缀
✅ `MD_Step_`, `MD_Amp_`, `MD_Solver_` - 符合L3_MD层命名规范

### 过程命名
✅ `MD_Step_Register` - 域+操作
✅ `MD_Amp_EvalAtTime` - 域+操作+参数
✅ `MD_Solver_Configure` - 域+操作

---

## 十、测试策略

### 单元级测试
- 分析步注册: 验证step_id唯一性
- 幅值求值: Tabular/Smooth/Ramp精度验证
- 求解器配置: 参数范围检查

### 集成级测试
- 分析步↔幅值: 边界条件幅值引用
- Analysis↔L5_RT: Populate数据传递

---

## 十一、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.1 | 2026-04-20 | 增加 §十二：商业参考对齐缺口登记，链接 `COMMERCIAL_PARITY_GAPS.md` |
| v1.0 | 2026-04-17 | 初始版本,创建Analysis域合同卡 |

---

## 十二、商业参考对齐（全关键字 / 全步类型）缺口

「与商业参考求解器输入语言及步进语义 **全集** 一致」超出当前 L3 合同闭包，且依赖 KeyWord、L5、L2 与 golden 验收矩阵。缺口按工作面拆分、可分批关闭的登记见：

- **[`COMMERCIAL_PARITY_GAPS.md`](COMMERCIAL_PARITY_GAPS.md)**

关闭某类缺口时，请同步更新该文件状态，并在 **§十一** 版本历史中摘要。

---

## 十三、错误处理

| 子域 | 错误场景 | 错误码 | 处理方式 |
|------|----------|--------|----------|
| Amplitude | 幅值 ID 越界 | — | 默认因子 1.0 |
| Amplitude | 时间数组长度不一致 | `IF_STATUS_INVALID` | 返回 status |
| Step | 步序号无效 | `IF_STATUS_INVALID` | 返回 status |
| Step | 时间增量 ≤ 0 | `IF_STATUS_INVALID` | 返回 status |
| Solver | 容差非正 / 迭代≤0 | `IF_STATUS_INVALID` | AddConfig 拒绝 |
| Solver | SyncFromStep 失败 | `IF_STATUS_INVALID` | 事务回滚 |

所有公开过程通过 `ErrorStatusType` 返回状态。不使用 `STOP`。

---

## 十四、域际关系（Analysis 顶层）

| 序号 | 关联域 | 相对本域 | 契约类型 | 主要接触面 | 备注 |
|------|--------|----------|----------|------------|------|
| R1 | L3_MD/Boundary | 下游 | T+U | Step 激活载荷/BC | Boundary 消费 Step 定义 |
| R2 | L3_MD/Material | 下游 | U | Step 关联材料行为 | |
| R3 | L5_RT/StepDriver | 下游 | T+B | Step Desc → L5 步驱动 | Bridge 路径 |
| R4 | L5_RT/Solver | 下游 | T+B | Solver Desc → L5 求解器 | 样板间 (Phase 1) |
| R5 | L3_MD/KeyWord | 上游 | U | 关键字解析填充 Step/Amplitude/Solver | |

---

## 十五、约束分级（Analysis 顶层）

| 约束 | 级别 | 说明 |
|------|------|------|
| L3 仅配置 Desc | **硬** | 不做时间积分/求解 |
| 不使用 STOP | **硬** | H-ERR-01 |
| 三子域均有 CONTRACT | **硬** | H-CON-01 |
| Amplitude 仅经 `Amp_GetFactor` 消费 | **硬** | 不手写旁路 |
| 测试覆盖率 | **软** | 待建 |

---

## 十六、十件套 v2.0 映射（Analysis 顶层聚合）

| 序号 | 逻辑件 | Amplitude | Step | Solver |
|------|--------|-----------|------|--------|
| 1 | Contract | `Amplitude/CONTRACT.md` | `Step/CONTRACT.md` | `Solver/CONTRACT.md` |
| 2 | Definition | `MD_Amp_Def.f90` | `MD_Step_Def.f90` | `MD_Solv_Def.f90` |
| 3 | Desc | `MD_Amp_Slot_Desc` | `AnalysisStep` | `MD_Solver_Desc` |
| 4 | State | 占位 | `StepStateData` | 占位 |
| 5 | Algo | N/A | N/A | `MD_Solver_Algo` |
| 6 | Ctx | N/A | N/A | 占位 |
| 7 | Main | `MD_Amp_Mgr.f90` | `MD_Step_Mgr.f90` | `MD_Solv_Mgr.f90` |
| 8 | Bridge | `MD_Amp_UF.f90` / `MD_Amp_Mgr` 再导出 | Bridge_L5 路径 | `MD_Solv_Mgr.f90` 内 Brg |
| 9 | Runtime Proc | N/A | N/A | N/A |
| 10 | Registry | N/A | `MD_Step_Proc.f90` | `MD_Solv_Mgr.f90`（Idx / GetConfig） |
| 11 | Populate | `MD_Amp_Mgr` / Sync 路径 | `MD_Step_Sync.f90` | `MD_Solv_Sync.f90` |
| 12 | Diagnostics | 待补 | 待补 | GetSummary |
| 13 | Test | Deferred | Deferred | Deferred |


---

### 细粒度子程序清单

> 本域暂无 .f90 文件（或全部归属子域 CONTRACT）。

---

## 十七、分析类型3D正交兼容矩阵

### 设计概述

分析类型通过 **3D 稀疏正交坐标系** `(Solver × Coupling × Physics)` 管理。理论空间 8×4×12 = 384 格，有效组合约 50-60 个。

### 维度定义

| 维度 | 数量 | 常量前缀 | 来源模块 |
|------|------|----------|----------|
| D1: Solver Engine | 8 | `RT_SOLVER_*` | `RT_SolverType_Def` (L1_IF) |
| D2: Coupling Strategy | 4 | `AC_COUP_*` | `MD_AnalysisCompat` |
| D3: Physics Field | 12 | `AC_PHYS_*` | `MD_AnalysisCompat` |

#### D1: 8-Engine Solver Routing

| ID | Constant | Engine | UMAT Interface |
|----|----------|--------|----------------|
| 1 | RT_SOLVER_IMPLICIT | Implicit structural NR | UMAT/UEL |
| 2 | RT_SOLVER_EXPLICIT | Central difference | VUMAT/VUEL |
| 3 | RT_SOLVER_CFD | Finite volume | — |
| 4 | RT_SOLVER_EMF | Electromagnetic | — |
| 5 | RT_SOLVER_THM | Pure thermal | UMATHT/HETVAL |
| 6 | RT_SOLVER_PMF | Pore mechanics | — |
| 7 | RT_SOLVER_DIF | Mass diffusion | — |
| 8 | RT_SOLVER_CPL | Multi-field coord | RT_MF_Coordinator |

#### D2: 4 Coupling Strategies

NONE(1), ONEWAY(2), STAGGERED(3), MONOLITHIC(4)

#### D3: 12 Physics Fields

1-6 single-field: Structure, Thermal, Frequency, Acoustic, EM, Fluid
7-10 coupled pairs: ThermalStruct, ElectroStruct, FluidStruct, FluidThermal
11-12 multi/other: MultiField, Special

### 物理组映射 (G1-G9)

| Group | 含义 | 对应 Physics |
|-------|------|-------------|
| G1 | Structural | Structure (non-PMF solver) |
| G2 | Thermal | Thermal |
| G3 | Frequency | Frequency |
| G4 | Acoustic | Acoustic |
| G5 | Electromagnetic | EM |
| G6 | Thermo-Mechanical | ThermalStruct |
| G7 | Multi-Field | ElectroStruct, FluidStruct, FluidThermal, MultiField |
| G8 | Geotechnical | Structure (PMF solver) |
| G9 | Special | Special, Fluid, etc. |

### 跨域桥接 (G1-G9 → Material-Section-Element)

`GROUP_MAT_COMPAT(9, 11)` 和 `GROUP_ELEM_COMPAT(9, 9)` 连接物理组到 Material Family (11类) 和 Element Category (9类，C3D/CPS/CAX/S/B/T/DC/AC/EM)，与 `MD_SectCompat` 的 Material-Section-Element 三维正交矩阵形成完整验证链。

### PROC → 分析组映射

`MD_Ana_Comp_ProcToGroup(proc_id)` 将 28+ PROC_* 常量映射到 `MD_Ana_Comp_Group_Desc`，包含 `(solver, coupling, physics, group)` 四元组。并行映射 `ProcToSolverType(proc_id)` 在 `MD_Step_Proc.f90` 中提供单一 PROC → RT_SOLVER_* 选路。

### 已弃用

- `MD_Analysis_GroupModule.f90`：5-solver 原型，已标注 DEPRECATED。新代码应使用 `MD_AnalysisCompat`。
- `PH_AnalysisRouterModule.f90`：已迁移为使用 `MD_AnalysisCompat`。

### 验证 API

| 接口 | 功能 | 位于 |
|------|------|------|
| `MD_Ana_Comp_CheckTriple` | 验证 (solver, coupling, physics) 是否合法 | `MD_Ana_Comp` |
| `MD_Ana_Comp_ProcToGroup` | PROC_* → `MD_Ana_Comp_Group_Desc` 全量映射 | `MD_Ana_Comp` |
| `MD_Ana_Comp_CheckGroupMat` | G1-G9 × Material Family 校验 | `MD_Ana_Comp` |
| `MD_Ana_Comp_CheckGroupElem` | G1-G9 × Element Category 校验 | `MD_Ana_Comp` |
| `MD_Ana_Comp_ValidateStep` | PROC → 3D triple 验证（含 ErrorStatusType） | `MD_Ana_Comp` |
| `MD_Ana_Comp_FullCheck` | 端到端：PROC + mat + elem 全链验证 | `MD_Ana_Comp` |

---

## 十八、版本历史（续）

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v2.0 | 2026-04-25 | 新增 §十七：分析类型3D正交兼容矩阵（8×4×12），含 G1-G9 物理组、Material/Element 跨域桥接、ProcToSolverType 映射、MD_AnalysisGroupModule 弃用 |
| v1.1 | 2026-04-20 | 增加 §十二：商业参考对齐缺口登记 |
| v1.0 | 2026-04-17 | 初始版本 |
