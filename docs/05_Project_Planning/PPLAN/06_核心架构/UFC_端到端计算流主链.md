# UFC 端到端计算流主链

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_端到端计算流主链.md`
> **上位文档**：[UFC_架构设计总纲_深度整合版_v5.0.md](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)
> **版本**：v1.0
> **创建日期**：2026-04-25
> **状态**：ACTIVE — 经源码核查草拟，待用户评审确认歧义点 A/B 后作为后续所有域 CONTRACT.md 的锚点依据
> **⚠ 本文已整合至 → [UFC_权威端到端数据流总图.md](UFC_权威端到端数据流总图.md)**（唯一权威数据流参考）。本文保留作为计算流细节的辅助参考。
> **核查文件**：`RT_StepExec.f90`、`RT_AsmSolv.f90`、`RT_StepImpl.f90`、`RT_WBImpl.f90`、`AP_InpMgr.f90`、`AP_OutDomain.f90`

---

## 0. 文档用途

本文档是**驱动所有域边界划分和 CONTRACT.md 输入/输出合同的锚点图**。每个节点标注：

- **层/域归属**
- **数据角色**（`Desc`=只读冷数据 / `State`=可写温数据 / `Ctx`=步内临时热数据）
- **契约类型**（`T`=合同TYPE切片 / `B`=Bridge / `S`=SIO / `R`=Registry / `U`=USE直链 / `E`=外部边界）

---

## 1. 主链全图（静力隐式路径）

> 静力隐式（Static Implicit / Newton-Raphson）是核心主链，显式动力学和隐式动力学作为分支在 §2/§3 补充。

```mermaid
flowchart TD
    subgraph L6_in [L6_AP — 输入解析]
        A1["AP_InpMgr\n关键字文件读取\n(E: 外部.inp文件)"]
        A2["AP_InpCmdMgr / AP_InpKWBrg\n关键字路由与参数解析\n(R: KeyWord Registry)"]
        A3["AP_InpDomain\n节点/单元/材料/步骤建模命令\n(U→L3)"]
    end

    subgraph L3_build [L3_MD — 模型构建阶段 Write-Once]
        B1["MD_Mesh\n节点坐标/单元连接\n(Desc)"]
        B2["MD_Material\n材料参数 E/nu/rho\n(Desc)"]
        B3["MD_Section / MD_Part\n截面/部件定义\n(Desc)"]
        B4["MD_Assembly\nNodeSet/ElemSet/Surface\n(Desc)"]
        B5["MD_Analysis/Step\n分析步/时间/收敛准则\n(Desc)"]
        B6["MD_LoadBC / MD_Amplitude\n载荷边界/幅值曲线\n(Desc)"]
    end

    subgraph L5_step [L5_RT — Step调度]
        C1["RT_StepDriver_Execute\n步级调度入口\n(T: RT_StepDriver_Desc)"]
        C2["ph_layer%Init\n触发L4 Populate\n(B: L4侧主动拉)"]
        C3["RT_Asm_DofMap_Build\n自由度编号映射\n(T: RT_Sol_DofMap)"]
    end

    subgraph L4_pop [L4_PH — Populate Step开始一次]
        D1["PH_L4_LayerContainer%Init\n从L3只读切片拉取\n材料/单元/接触 Desc"]
        D2["PH_L4_Populate_Core\nPH_MapL3MatTypeToL4\n枚举映射+参数预算"]
    end

    subgraph L5_inc [L5_RT — 增量步循环]
        E1["LoadFactor lambda=t/T\n时间推进与截断控制\n(T: MD_TimeIncrementControl)"]
        E2["RT_Asm_GlobalLoad\n外载荷向量F_ext装配\n(B->L4_PH/LoadBC)"]
    end

    subgraph L5_iter [L5_RT — Newton-Raphson迭代]
        F1["RT_NLSolver_NewtonRaph\n非线性迭代控制 L5持有\n(T: MD_NonlinSolv)"]
        F4["PH_Cont_SearchPairs\nPH_Cont_CalculateGap\n接触对检测 迭代预处理\n(B: PH_Cont_Brg)"]
        F5["PH_Cont_ApplyConstraints\n接触约束修改K和R\n(B: PH_Cont_Brg)"]
        F2["RT_Asm_ComputeTangent\n全局切线刚度K组装\n-> PH_Element_Compute_Ke_Arg"]
        F3["RT_Asm_ComputeResidual\n全局残差R=F_int-F_ext\n-> PH_Element_Compute_Fe_Arg"]
    end

    subgraph L4_elem [L4_PH — 单元/材料计算]
        G1["PH_Element_Compute_Ke\nKe = BtDB dV\n(Ctx: 步内临时)"]
        G2["PH_Element_Compute_Fe\nFe_int = Bt sigma dV\n(Ctx: 步内临时)"]
        G3["PH_Mat_Constit_Eval\n本构积分 sigma=f(eps,state,algo)\n(Desc只读/State可写/Ctx临时)"]
    end

    subgraph L2_solv [L2_NM — 线性求解]
        H1["RT_SolvLin -> NM_SolvDir/NM_SolvIter\nK*du = -R\n(U: L5->L2符合单向依赖)"]
    end

    subgraph L5_conv [L5_RT — 收敛判断与状态提交]
        I1["MD_Conv_Check\nnorm_R/norm_F < tol\nAND/OR模式"]
        I2["收敛->增量提交\nRT_WBImpl -> MD_WB_Brg\n白名单写回L3_MD State"]
        I3["未收敛 iter=max\n截断因子0.25 最多10次"]
        I4["收敛->输出触发\nRT_Out_UnifMgr\n(B: RT_Out_Brg->L6)"]
    end

    subgraph L3_wb [L3_MD — 状态写回 白名单]
        J1["MD_Mesh State\n节点位移/坐标更新"]
        J2["MD_Material State\n应力/应变/历史变量"]
    end

    subgraph L6_out [L6_AP — 输出]
        K1["AP_OutDomain / AP_OutRT_Brg\nField Output\n(E: ODB/文件)"]
        K2["AP_OutFmt\nHistory Output\n(E: 文件)"]
    end

    A1 --> A2 --> A3
    A3 -->|"Desc建模"| B1
    A3 -->|"Desc建模"| B2
    A3 -->|"Desc建模"| B3
    A3 -->|"Desc建模"| B4
    A3 -->|"Desc建模"| B5
    A3 -->|"Desc建模"| B6

    B5 -->|"Step序列驱动"| C1
    C1 -->|"B: ph_layer%Init触发"| C2
    C2 -->|"B: L4侧主动拉取L3 Desc"| D1
    D1 --> D2
    C1 --> C3

    C1 -->|"进入增量循环"| E1
    E1 --> E2
    E2 -->|"进入NR迭代"| F1

    F1 --> F4 --> F5 --> F2
    F1 --> F2
    F2 -->|"单元刚度路由"| G1
    F1 --> F3
    F3 -->|"单元内力路由"| G2
    G1 --> G3
    G2 --> G3

    F2 -->|"K_global CSR"| H1
    F3 -->|"R_global"| H1
    H1 -->|"delta_u"| I1
    I1 -->|"收敛"| I2
    I1 -->|"未收敛 iter<max"| F1
    I1 -->|"未收敛 iter=max"| I3
    I3 -->|"截断重试"| E1
    I2 -->|"B: RT_WBImpl->MD_WB_Brg"| J1
    I2 -->|"B: RT_WBImpl->MD_WB_Brg"| J2
    I2 --> I4
    I4 -->|"B: AP_OutRT_Brg"| K1
    I4 -->|"B: AP_OutRT_Brg"| K2
```

---

## 2. 分支路径：显式动力学

```mermaid
flowchart LR
    SD["RT_StepDriver_Execute\nPROC_DYNAMIC_EXPLICIT"]
    EX["RT_DynExpl_Run\n中心差分法"]
    CFL["RT_Dyn_CFL_dt_central_diff\ndt <= 2/omega_max"]
    MK["RT_Asm_CSRMass_FromModel\n集中质量矩阵M对角"]
    CD["a_n = M_inv*(F_ext-F_int)\nu_n+1 = u_n + dt*v + 0.5*dt^2*a"]
    WB["RT_WBImpl\n写回位移/速度/加速度"]

    SD --> EX --> CFL --> MK --> CD --> WB
```

**特点**：无 Newton-Raphson 迭代；时间步受 CFL 条件约束；接触在每个时间步前处理。

---

## 3. 分支路径：隐式动力学

```mermaid
flowchart LR
    SD2["RT_StepDriver_Execute\nPROC_DYNAMIC_IMPLICIT"]
    IM["RT_DynImpl_Run\nNewmark-beta 或 HHT-alpha"]
    NR2["RT_NLSolver_NewtonRaph\n含M和C项的切线刚度"]
    WB2["RT_WBImpl\n写回位移/速度/加速度"]

    SD2 --> IM --> NR2 --> WB2
```

---

## 4. 数据角色与生命周期总表

| 数据 | TYPE角色 | 持有层 | 生命周期 | 写回规则 |
|------|----------|--------|----------|----------|
| 材料参数（E, nu, rho等） | `Desc`（冷） | L3_MD/Material | 模型级，全程驻留 | Write-Once，禁止修改 |
| 网格节点坐标（初始） | `Desc`（冷） | L3_MD/Mesh | 模型级 | Write-Once |
| 分析步定义 | `Desc`（冷） | L3_MD/Analysis/Step | 模型级 | Write-Once |
| 当前节点位移/坐标 | `State`（温） | L3_MD（白名单写回） | 增量步级 | 仅经 `RT_WBImpl->MD_WB_Brg` |
| 积分点应力/应变/历史 | `State`（温） | L3_MD（白名单写回） | 增量步级 | 仅经 `RT_WBImpl->MD_WB_Brg` |
| PH层材料/单元派生视图 | L4内部State | L4_PH（Populate） | Step级 | 不写回L3，由L5/WriteBack负责 |
| 单元刚度矩阵 Ke | `Ctx`（热） | L4_PH调用栈 | 迭代内，计算后丢弃 | 不保存 |
| 全局刚度矩阵 K_global | `Ctx`（热） | L5_RT/Assembly（CSR） | 迭代内 | 不保存到L3 |
| 残差向量 R | `Ctx`（热） | L5_RT/Assembly | 迭代内 | 不保存 |
| DOF映射 | `Algo`（冷） | L5_RT/Assembly | Step级 | 不写回 |
| 收敛准则参数 | `Algo`（冷） | L5_RT（来自L3 Step） | Step级 | 不写回 |
| NR迭代状态 | `Ctx`（热） | L5_RT/Solver（MD_SolverState） | 迭代内 | 不写回 |
| 时间步控制 | `Algo`+`State` | L5_RT | 增量步级 | 不写回 |

---

## 5. 三个歧义点的当前代码状态

### 歧义点 A：L4 Populate 方向（待确认）

**当前状态**（源码实证）：

- **主路径（L4侧拉，ACTIVE）**：`RT_StepExec.f90` line 372 中 `g_ufc_global%ph_layer%Init(step_number, ...)` 由 L5_RT 触发，L4 主动拉取 L3 Desc
- **遗留路径（L3侧推，待清理）**：`MD_MatLib_PH_Brg.f90`、`MD_Elem_PH_Brg.f90` 仍存在 L3 侧主动推函数
- **违规点**：`PH_Brg_ElementStiffAssembly`（旧版）直接写 L3 Mesh State（越权，联通契约文档已标注为 D-defect）

**待确认**：L4侧主动拉是否为最终目标形态？L3侧推路径是否在 Phase 4 完全删除？

### 歧义点 B：接触计算时序（待确认）

**当前状态**（源码实证）：

`RT_AsmSolv.f90` 中调用顺序：`PH_Cont_SearchPairs_API` -> `PH_Cont_DetectPenetration_API` -> `PH_Cont_CalculateGap_API` -> `PH_Cont_ApplyConstraints_API`。

这些调用在**组装残差/切线刚度之前**作为迭代预处理步，而非嵌入单元循环内。

**待确认**：迭代前预处理是否为设计意图？还是期望按单元级别内嵌组装循环？

### 歧义点 C：非线性迭代控制权（已清晰，无需确认）

**结论**：
- **增量步外层循环**：`RT_StepDriver_Execute`（L5_RT/StepDriver）持有
- **Newton 迭代内层循环**：`RT_NLSolver_NewtonRaph`（L5_RT/Solver）持有
- **Assembly**：无状态计算引擎，被 NLSolver 调用，不持有迭代控制权

此点可直接写入相关域 CONTRACT.md，无需等待确认。

---

## 6. 调用链层级依赖关系（静力隐式）

```
L6_AP/Input  --(E)--> L3_MD（建模，Write-Once）
L5_RT/StepDriver --(B)--> L4_PH%Init（Populate，L4侧主动拉）
L5_RT/StepDriver --(U)--> L5_RT/Solver（NLSolver，同层）
L5_RT/Solver --(U)--> L5_RT/Assembly（ComputeTangent/Residual，同层）
L5_RT/Assembly --(B)--> L4_PH/Element（Compute_Ke/Fe）
L4_PH/Element --(U)--> L4_PH/Material（Constit_Eval，同层）
L5_RT/Solver --(U)--> L2_NM/Solver（线性求解 KΔu=-R）
L5_RT/WriteBack --(B)--> L3_MD（白名单State写回，via MD_WB_Brg）
L5_RT/Output --(B)--> L6_AP/Output（Field/History）
```

**待清理警告**：`RT_AsmSolv.f90` 中存在旧版直接 USE L3_MD 模块（`MD_ModelLib`、`MD_FieldState` 等），应在 Phase 4 桥接修复时替换为 Bridge 调用。

---

## 7. 与后续工作的接口

1. **各域 CONTRACT.md 的「四链位置」小节** 引用本图节点（如"计算链：主链图 §1 G3 节点本构积分"）
2. **歧义点 A 确认后**：锁入 L3_MD/Bridge 和 L4_PH/Bridge 的 CONTRACT.md 依赖方向
3. **歧义点 B 确认后**：锁入 L4_PH/Contact 和 L5_RT/Assembly 的 CONTRACT.md 接触时序说明
4. **Phase 1 三级存储策略**：与本图 §4 数据角色表对齐，Ctx 列是约束设计热路径分配策略的依据
5. **Phase 2 全局域依赖图**：以本图 §6 调用链为边的来源，添加 55+ 域的完整覆盖

---

*文档创建：2026-04-25 | 核查依据：RT_StepExec.f90(line372) RT_AsmSolv.f90(line76-118) RT_WBImpl.f90 RT_StepImpl.f90*
