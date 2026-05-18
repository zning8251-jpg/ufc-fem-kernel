# UFC 过程双轴体系：Phase x Verb

> **版本**: v1.0 | **日期**: 2026-04-26
>
> **上位文档**: [UFC_架构设计总纲_深度整合版_v5.0.md](UFC_架构设计总纲_深度整合版_v5.0.md)（四类 TYPE）
>
> **对等文档**: [UFC_四型裁剪矩阵.md](UFC_四型裁剪矩阵.md)（数据载体分类）
>
> **本文定位**: 数据载体有四类 TYPE（Desc/State/Algo/Ctx），过程载体有 Phase x Verb 双轴。二者通过温度轴天然耦合，共同构成 UFC 功能模块的完整认知框架。

---

## 一、设计哲学

### 功能模块 = 数据载体 + 过程载体

```
功能模块 (Module)
  ├── 数据载体：四类 TYPE（Desc / State / Algo / Ctx）
  │   └── 分类依据：数据的内在物理属性（可变性 x 存活期）
  │
  └── 过程载体：Phase x Verb 双轴
      └── 分类依据：过程的执行时机（Phase）x 操作类型（Verb）
```

### 为什么不用"过程四型"

曾尝试与数据四型对称地定义"过程四型"(Cval/Kern/Redu/Drv)。经分析发现：

- **数据是名词**（静态结构）→ 天然可正交分类 → 四类 TYPE 互斥、穷尽、客观
- **过程是动词**（动态行为）→ 天然混合 → 强制四格分类导致：大量"主+辅"混合标签、需排除规则、降级为事后审计标签

**结论**：过程分类改用**两个真正正交的轴**——Phase（何时）x Verb（做什么），取代单一的四格分类。

Cval/Kern/Redu/Drv 不废弃，降级为**可选审计标签**（`@ProcKind` 注释），用于 registry/CI 描述"主数据流责任"。日常设计不以其为起点。

---

## 二、轴一：Phase（时相）— 6 级

与 L5_RT 三步状态机（分析步-增量步-迭代步）精确对齐：

```
分析 (Config, Populate)
  └── 分析步 Step           ← 三步状态机 第1层
        └── 增量步 Increment     ← 三步状态机 第2层
              └── 迭代步 Iteration  ← 三步状态机 第3层
                    └── 局部 Local     ← 最内层内核
```

| Phase | 中文 | 温度 | 执行频率 | 写入数据 | 典型操作 |
|-------|------|------|---------|---------|---------|
| **Config** | 配置 | 冷 | 1 次/分析 | Desc | 解析输入、建模型树、校验参数 |
| **Populate** | 预填 | 冷 | 1 次/分析或步 | L4/L5 槽位 | Bridge L3→L4/L5、分配、指针连接 |
| **Step** | 分析步 | 温 | ~10–100 次 | State(步级) | Begin/End Step、输出、步级状态提交 |
| **Increment** | 增量步 | 温热 | ~100–10K 次 | State(增量级) | Begin/End Incr、时间推进、载荷因子、切回 |
| **Iteration** | 迭代步 | 热 | ~1K–100K 次 | Ctx | 装配 K/F、求解 K·du=R、收敛检查 |
| **Local** | 局部 | 最热 | 百万级 | Ctx + State(IP) | 单元 Ke/Fe、积分点本构、形函数/B 阵 |

### Phase 与数据温度的天然耦合

```
Config    → 主要写 Desc           (冷)
Populate  → 读 Desc → 填 L4/L5   (冷)
Step      → 主要写 State(步级)    (温)
Increment → 写 State(增量级)      (温热)
Iteration → 主要写 Ctx            (热)
Local     → 读 Desc+Algo, 写 Ctx+State(IP) (最热)
```

### Phase 退化规则

不同分析类型可能使某些 Phase 退化/跳过，但不会出现新 Phase：

| 分析类型 | 退化说明 |
|---------|---------|
| 显式动力学 | Iteration 退化为单次（无 Newton 迭代） |
| 特征值分析 | Step 退化为单步，Iteration = 特征值迭代 |
| 静力分析 | Increment 可能为单增量 |
| 频率响应 | Step 按频率循环，Iteration = 复数求解 |

---

## 三、轴二：Verb（功能动词）— 8 族

| Verb 族 | 含义 | 子动词 | 典型 Phase |
|---------|------|--------|-----------|
| **Init** | 生命周期 | Init, Finalize, Reset, Allocate, Deallocate | Config, Step |
| **Validate** | 合法性校验 | Validate, Guard, Assert | Config, Populate |
| **Compute** | 核心计算 | Compute, Build, Evaluate, Integrate, Interpolate, Transform, Solve | Local, Iteration |
| **Evolve** | 状态演化 | Update, Commit, Revert, Advance, Increment | Step, Increment |
| **Assemble** | 归约/聚合 | Assemble, Reduce, Accumulate, Apply, Impose | Iteration |
| **Access** | 数据存取 | Get, Set, Add, Remove, Find, Count, Log | 任意 |
| **Control** | 流程判断 | Begin, End, Route, Select, Dispatch, Check, Loop | Step, Increment, Iteration |
| **Bridge** | 跨层映射 | Bridge, Populate, WriteBack, Pack, Unpack, Map | Populate, Step, Iteration(耦合) |

### Verb 推荐用词与避免用词

| Verb 族 | 推荐动词 | 避免（歧义风险） |
|---------|---------|-----------------|
| Init | Init, Finalize, Reset | Create, Destroy |
| Validate | Validate, Guard | Check（与 Control 冲突） |
| Compute | Compute, Build, Evaluate, Integrate, Interpolate, Transform, Solve | Calc, Do, Run |
| Evolve | Update, Commit, Revert, Advance | Modify, Change |
| Assemble | Assemble, Reduce, Apply, Impose | Collect, Gather |
| Access | Get, Set, Add, Remove, Find, Count | Fetch, Put, Insert |
| Control | Begin, End, Route, Select, Check, Loop | Start, Stop |
| Bridge | Bridge, Populate, WriteBack, Pack, Unpack, Map | Transfer, Move |

---

## 四、48 格覆盖矩阵

| Phase \ Verb | Init | Validate | Compute | Evolve | Assemble | Access | Control | Bridge |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Config** | **Y** | **Y** | **Y** | - | - | **Y** | - | - |
| **Populate** | **Y** | y | y | - | - | - | - | **Y** |
| **Step** | **Y** | - | y | **Y** | - | **Y** | **Y** | **Y** |
| **Increment** | y | - | y | **Y** | - | **Y** | **Y** | - |
| **Iteration** | - | - | **Y** | **Y** | **Y** | - | **Y** | y |
| **Local** | - | - | **Y** | **Y** | y | y | - | - |

**Y** = 常见组合，**y** = 少见但合法，**-** = 不自然组合。

约 29/48 格有实际 FEM 过程，19 格空白代表不自然组合（如 Config x Assemble、Local x Control）。空白恰证明两轴正交。

---

## 五、完整性验证（6 层 / 50+ 域 / 1000+ 模块）

48 格是**过程类别**（分类系统），不是过程数量上限。每格可容纳无限个具体过程。

### 逐层验证

| 层 | 域数 | 主要 Phase x Verb 格子 | 全覆盖？ |
|----|------|----------------------|---------|
| **L1_IF** | ~10 | Config x Init/Access | 是 |
| **L2_NM** | ~8 | (any) x Compute, Iteration x Compute(Solve) | 是 |
| **L3_MD** | ~12(17 子域) | Config x Access/Validate, Step x Bridge(WriteBack) | 是 |
| **L4_PH** | ~10 | Config x Validate/Init, Local x Compute/Evolve, Iteration x Assemble | 是 |
| **L5_RT** | ~8 | Step/Increment/Iteration x Control/Evolve, Iteration x Assemble | 是 |
| **L6_AP** | ~4 | Config x Init/Control(Route), Step x Control(Loop) | 是 |

### 极端场景验证

| 场景 | Phase x Verb | 覆盖？ |
|------|-------------|--------|
| 显式动力学（无 Newton） | Iteration 退化为单次，Local x Compute 不变 | 是 |
| 特征值分析（无时间步） | Step 退化为单步，Iteration = 特征值迭代 | 是 |
| 频率响应（复数运算） | Iteration x Compute(Solve) 用复数版 | 是 |
| 热-力耦合 | Iteration x Bridge（场间交换） | 是 |
| 自适应网格 | Step x Compute(Refine) + Step x Bridge(Map) | 是 |
| XFEM 裂纹扩展 | Increment x Evolve(Propagate) + Populate x Compute(Enrich) | 是 |
| 并行负载均衡 | Step x Compute(Partition) | 是 |
| 重启续算 | Config x Bridge(Populate) 读重启文件 | 是 |
| UMAT 用户材料 | Local x Compute（外部接口不改分类） | 是 |
| 损伤/失效检查 | Local x Evolve(Update)（判断是演化的一部分） | 是 |

**结论**：规模增长只增加格内过程数量，不增加新格。48 类别稳定。

---

## 六、过程命名规范

### 规则 P1：过程名公式

```
{Layer}_{Domain}[_{Feature}]_{Verb}[_{Object}]
```

- **Layer**：IF / NM / MD / PH / RT / AP
- **Domain**：域级缩写（Mat / Elem / Step / Asm / Solv / ...）
- **Feature**：子域（可选，如 Elas / Plas / C3D8）
- **Verb**：8 族中的具体动词
- **Object**：操作目标（可选，如 Stress / Props / By_ID）
- 全名 ≤ 31 字符（Fortran 2003 限制）

### 规则 P2：Phase 注释标注

Phase 不进过程名（Verb 已暗示 Phase），以标准注释标注：

```fortran
!---------------------------------------------------------------------------
! Phase: Local | Verb: Compute | HOT_PATH O(36)
!---------------------------------------------------------------------------
SUBROUTINE PH_Mat_Elas_Compute_Stress(ctx, strain, stress, status)
```

标注格式：`! Phase: {Phase} | Verb: {Verb}[({SubVerb})] | {COLD_PATH|HOT_PATH} [O(?)]`

### 规则 P3：Init/Finalize 使用 Core 中缀

```
{L}_{D}_Core_Init       — 域级初始化
{L}_{D}_Core_Finalize    — 域级清理
```

### 规则 P4：Bridge 过程标注方向

```
{L}_{D}_Brg_From{Source}   — 从上游层接收
{L}_{D}_Brg_To{Target}     — 向下游层输出
```

### 规则 P5：Verb 与 Phase 的对照速查

| 命名中的动词 | Verb 族 | 典型 Phase | 示例 |
|-------------|---------|-----------|------|
| Init / Finalize | Init | Config | `MD_Mat_Core_Init` |
| Validate | Validate | Config | `PH_Mat_Elas_Validate_Props` |
| Compute / Build / Evaluate | Compute | Local | `PH_Mat_Elas_Compute_Stress` |
| Solve | Compute | Iteration | `NM_Solver_Solve` |
| Update / Commit / Revert | Evolve | Step/Increment | `RT_Step_Commit_State` |
| Advance | Evolve | Increment | `RT_StepDriver_Advance_Time` |
| Assemble / Apply / Impose | Assemble | Iteration | `RT_Asm_Assemble_Ke` |
| Get / Set / Add / Find | Access | (any) | `MD_Material_Get_By_ID` |
| Begin / End | Control | Step/Increment | `RT_StepDriver_Begin_Step` |
| Check | Control | Iteration | `RT_Solver_Check_Convergence` |
| Route / Select | Control | Increment | `RT_StepDriver_Cutback` |
| Loop | Control | Step/Iteration | `RT_StepDriver_Run_Step` |
| Bridge / Populate | Bridge | Populate | `PH_Mat_Elas_Brg_FromL3Desc` |
| WriteBack | Bridge | Step | `MD_WriteBack_Execute` |

---

## 七、与 UFC 其他体系的关系

| UFC 体系 | 回答的问题 | 与 Phase x Verb 的关系 |
|---------|-----------|----------------------|
| **六层** (L1–L6) | 在哪里、依赖朝哪边 | 正交：Layer 管边界，Phase x Verb 管过程内部 |
| **四类 TYPE** | 袋里装什么 | 耦合：Phase 与数据温度共享温度轴 |
| **四链** | 跨域/跨层贯通 | 四链是路径，Phase x Verb 是单过程微观定位 |
| **SIO / *_Arg** | 签名形态 | 不替代：SIO 管参数形态，Phase x Verb 管操作分类 |
| **ProcKind** (Cval/Kern/Redu/Drv) | 主数据流责任 | 降级：ProcKind 为可选审计标签，Phase x Verb 为设计驱动力 |
| **三步状态机** | 求解器嵌套结构 | 对齐：Step/Increment/Iteration 精确对应三层嵌套 |
| **CONTRACT.md** | 域做什么 | 输入：从 CONTRACT 推演意图 → 映射到 Phase x Verb |

---

## 八、验收清单

- [ ] 新过程名符合 `{L}_{D}[_{F}]_{Verb}[_{Object}]` 公式
- [ ] 每个过程头部有 Phase 注释标注
- [ ] HOT_PATH / COLD_PATH 标注与 Phase 一致（Local/Iteration = HOT，Config/Populate = COLD）
- [ ] Verb 选词优先使用推荐列表（避免歧义词）
- [ ] 域级 CONTRACT.md 中过程清单注明 Phase x Verb 归属
