# 分析步域过程算法 Procedure — L3+L5 半贯通三维度全景

**文档性质**：与 `Analysis_L3L4L5_four_type_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理 Analysis 域（Step/Amplitude/Solver/Coupling 四子域）的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/Analysis/`（L3 Step/Solver/Coupling Algo）、`ufc_core/L5_RT/StepDriver/`（L5 三步状态机 + Stp_Ctl_Algo）、`ufc_core/L5_RT/Solver/`（L5 K·x=f 金线 + Itr_Algo）。

**报告 ID**：`REP-ANALYSIS-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的四子域分节图解，而是以 **过程算法** 为核心视角。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| Analysis 域 **三维度过程算法**：空间（耦合场映射）、时间（三步状态机/自动dt）、动作（K·x=f 管线） | 具体 **线性求解器** 算法推导 |
| L3+L5 **Algo TYPE 体系**（半贯通：L4 无域） | 非分析步域的过程算法（见各域 Procedure 文档） |
| **三步状态机**（Step→Inc→Itr）详述 | **Amplitude 插值** 公式推导 |
| **K·x=f 管线**（Assembly→Factorize→Solve→Check） | **多场耦合** 迭代算法推导 |

---

## 1. 三维度过程算法框架（Analysis 域解读）

### 1.1 空间维度

Analysis 域的空间维度关注 **耦合场映射 / 多场协同**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **多场耦合映射** | 位移场↔温度场↔声场 | `MD_Cpl_Stp_Ctl_Algo%relaxation_factor` |
| **场间数据传递** | 结构→热→声→结构 | `RT_MF_Coupling_Algo` |
| **子循环比** | 各场时间步比 | `MD_Cpl_Stp_Ctl_Algo%subcycle_ratio` |

### 1.2 时间维度

Analysis 域的时间维度关注 **三步状态机 / 自动dt / Cutback / NR 迭代控制**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **三步状态机** | Step→Inc→Itr 三级状态 | `RT_STEP_*` / `RT_INC_*` / `RT_ITER_*` 常量 |
| **自动dt** | auto_dt / growth / cutback | `RT_Step_Stp_Ctl_Algo%auto_dt` / `%growth_factor` / `%cutback_factor` |
| **目标迭代** | target_iters / growth_threshold | `RT_Step_Stp_Ctl_Algo%target_iters` |
| **NR 迭代** | max_iter / tol / NR 策略 | `RT_Solv_Itr_Algo` |
| **Cutback** | max_cutbacks / cutback_factor | `MD_Solv_Itr_Com_Algo%max_cutbacks` |

### 1.3 动作维度

Analysis 域的动作维度关注 **K·x=f 管线**。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **Assembly** | 全局 K/F 装配 | 全局 K/F 矩阵 |
| **Factorize** | 稀疏分解 | 分解因子 |
| **Solve** | 线性求解 → du | 位移增量 |
| **UpdateNorms** | 残差/位移/能量范数 | `RT_Solv_NRState` |
| **Check** | 收敛判断 | CONTINUING / CONVERGED / DIVERGED |

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 Algo TYPE（冷路径）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `MD_Solv_Itr_Com_Algo` | max_cutbacks / cutback_factor | 时间+动作 |
| `MD_Cpl_Stp_Ctl_Algo` | relaxation_factor / use_aitken / subcycle_ratio | 时间+动作 |

### 2.2 L4 Algo TYPE

Analysis 域 **无 L4 域目录**（半贯通复合柱：L3+L5，L4 无域）。

### 2.3 L5 Algo TYPE（运行期，Analysis 主场）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_StepDriver_Algo` | tol(R/F/E) / strat(max_iter/line_search/conv_mode) | 时间+动作 |
| `RT_Step_Stp_Ctl_Algo` | auto_dt / target_iters / growth_threshold / growth_factor / cutback_factor | **时间** |
| `RT_Step_Algo` | stp(`RT_Step_Stp_Ctl_Algo`) | 时间 |
| `RT_StepDrv_Algo` | 步驱动算法 | 时间 |
| `RT_Solv_Itr_Algo` | NR 策略 / 线性求解方法 / 范数类型 | 时间+动作 |
| `RT_Asm_Algo` | 装配算法参数 | 动作 |
| `RT_MF_Coupling_Algo` | 多场耦合算法参数 | 空间+时间+动作 |

---

## 3. Procedure Pointer 架构

Analysis 域当前 **无独立 Procedure Pointer**。

**设计决策**：Analysis 域的求解策略由 `RT_Solv_Itr_Algo` 参数枚举驱动（NR 策略: FULL/MODIFIED/INITIAL；线性求解: DIRECT/CG/GMRES/BICGSTAB），而非可插拔 PTR。

**关键区别**：Analysis 域的 TBP 模式（如 `RT_Solv_NRState%UpdateNorms`）替代了 PTR 的灵活性需求——State TBP 封装了收敛判断逻辑。

---

## 4. 三步状态机 + K·x=f 管线（核心动作管线）

### 4.1 三步状态机（时间维度核心）

```text
RT_StepDriver (L5 GOLDEN-LINE)
  │ Step: IDLE → RUNNING → CONVERGED → COMPLETED
  │   ├── RT_Step_Brg (L3→L5 步参数灌入)
  │   ├── RT_Step_Stp_Ctl_Algo (auto_dt / cutback / growth)
  │   │
  │   └── Increment: PREDICTING → ITERATING → CONVERGED → CUTBACK/FAILED
  │       ├── RT_Step_Inc_Evo_Ctx (dt_trial / inc_converged)
  │       │
  │       └── Iteration: ASSEMBLING → SOLVING → UPDATING → CHECKING → CONVERGED/DIVERGED
  │           ├── Itr Assemble: RT_Asm (全局 K/F 装配)
  │           ├── Itr Solve:    RT_Solv_Nonlin (NR 迭代)
  │           ├── Itr Update:   位移更新 du → u
  │           └── Itr Check:    RT_Solv_NRState%UpdateNorms → 收敛判断
```

### 4.2 K·x=f 管线（动作维度核心）

```text
RT_Solv_Mgr (L5 GOLDEN-LINE)
  │
  ├── 1. Assembly (装配)
  │   └── RT_Asm: Element→Material→Contact→LoadBC → 全局 K/F
  │   └── Algo 消费: RT_Asm_Algo (装配策略)
  │
  ├── 2. Factorize (分解)
  │   └── 稀疏分解: DIRECT / ITERATIVE
  │   └── Algo 消费: RT_Solv_Itr_Algo%linear_method
  │
  ├── 3. Solve (求解)
  │   └── 线性求解: K·du = F → du
  │   └── 方法: DIRECT / CG / GMRES / BICGSTAB
  │
  ├── 4. UpdateNorms (范数更新)
  │   └── RT_Solv_NRState%UpdateNorms: res/disp/energy
  │   └── Algo 消费: RT_Solv_Itr_Algo%norm_type (L2/LINF/L1)
  │
  └── 5. Check (收敛判断)
      └── CONTINUING / CONVERGED / DIVERGED
      └── NR 策略: FULL / MODIFIED / INITIAL
      └── Algo 消费: RT_Solv_Itr_Algo%nr_strategy
```

### 4.3 自动 dt 与 Cutback（时间维度核心）

```text
RT_Step_Stp_Ctl_Algo (步级控制)
  │ auto_dt = .TRUE.:
  │   ├── if (n_iters < target_iters * growth_threshold):
  │   │   └── dt *= growth_factor (1.25)
  │   └── if DIVERGED:
  │       └── dt *= cutback_factor (0.5)
  │       └── if (n_cutbacks > max_cutbacks): FAIL
  │
  └── auto_dt = .FALSE.:
      └── 固定 dt (用户指定)
```

---

## 5. 跨域协作（Analysis 域视角）

### 5.1 时间维度协作：Analysis 驱动全局

| 时间阶段 | Analysis 动作 | 协作域响应 |
|----------|--------------|-----------|
| Step Init | RT_STEP_RUNNING | Material/Element/Contact/LoadBC: Populate |
| Inc Predict | RT_INC_PREDICTING | LoadBC: Amp_GetFactor; Element: Predict |
| Itr Assemble | RT_ITER_ASSEMBLING | Element: Ke/Re; Material: S1→S4; Contact: Search+Detect; LoadBC: Assemble_Fext |
| Itr Solve | RT_ITER_SOLVING | Material: S3_StressUpdate; Contact: Force+Stiffness |
| Itr Update | RT_ITER_UPDATING | Element: Update u/du; Material: S4_Tangent |
| Itr Check | RT_ITER_CHECKING | LoadBC: CheckConvergence |
| Step End | RT_STEP_COMPLETED | Output: Collect+Write; WriteBack: LOP=2 |

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| — | L4 无域 | 半贯通设计决策 | 保持 L3+L5 半贯通模式 |
| — | L5 Algo TYPE 已完备 | 多个独立子 Algo | 无需额外补全 |
| — | 无 Procedure Pointer | 参数枚举 + TBP 替代 | 保持现状 |

**完备性评级**：✅ **半贯通域 L3+L5 Algo 完备**（时间: Stp_Ctl_Algo + Itr_Algo, 动作: K·x=f 管线, 空间: Cpl_Stp_Ctl_Algo + MF_Coupling_Algo）

---

## 7. 设计原则（Analysis 域特化）

1. **三步状态机不可跳级**：Step→Inc→Itr 严格层级；Inc 不直接进入 Itr Assemble（必须经 Predict）。
2. **auto_dt 与 cutback 协调**：`RT_Step_Stp_Ctl_Algo` 管自动 dt；`MD_Solv_Itr_Com_Algo` 管 cutback 参数——两者必须对齐。
3. **NR 策略由 RT_Solv_Itr_Algo 驱动**：FULL/MODIFIED/INITIAL 三选一，不可运行时切换。
4. **半贯通域 L4 无域**：Analysis 的 L3 定义模型参数，L5 编排运行流程，L4 无物理计算层。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `Analysis_L3L4L5_four_type_synthesis.md` | 四型合订本；§3.5 四子域分节图解 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.8 + A.1 | 过程算法全景合订（根 stub）；本文为 Analysis 域专域扩展 |
| `L5_RT/StepDriver/CONTRACT.md` | L5 合同卡；Step Algo 字段级真源 |
| `L5_RT/Solver/CONTRACT.md` | L5 合同卡；Solver Algo 字段级真源 |
| [Material_Procedure_Algorithm.md](../Material_Procedure_Algorithm.md) | Material Procedure；S-Pipeline 在 Itr 环中的调用 |
| [Element_Procedure_Algorithm.md](../Element_Procedure_Algorithm.md) | Element Procedure；Ke/Re 在 Assembly 中的调用 |
| [LoadBC_Procedure_Algorithm.md](../LoadBC_Procedure_Algorithm.md) | LoadBC Procedure；Fext 装配顺序 |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/Analysis_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/Analysis_Procedure_Algorithm.md` 为 stub。四型合订本：`Analysis_L3L4L5_four_type_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
