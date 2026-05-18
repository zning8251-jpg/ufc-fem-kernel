# 过程算法合订：三维度 × 八域 — L3/L4/L5 全景

**文档性质**：与八域合订本（Material/Element/Section/Contact/LoadBC/Output/WriteBack/Analysis）并列的 **过程算法全景合订**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理各域的过程算法（Algo TYPE + Procedure Pointer + Pipeline），补全"数据结构（四型TYPE）→ 过程算法"的完整功能模块定义。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**公式解读**：

- **数据结构侧**：以四型（Desc/State/Algo/Ctx）并列为域内主干，辅TYPE提供 depth-2 嵌套，`*_Arg` 提供层间结构化IO（跨 Harness/生成器/编排）
- **过程算法侧**：以空间维度（离散/积分/拓扑）、时间维度（Step/Increment/Iteration 状态机）、动作维度（Pipeline/Procedure Pointer）为三轴
- **两则关系**：数据结构的 `Algo TYPE` 同时是过程算法的策略容器（承载步控参数、Procedure Pointer、算法选择枚举 — 见 R-12）；`State` 是过程算法的结果产出写入面
- **意义**：任一域柱的功能完整性与稳定性，同时取决于四型数据结构的完备性和三维度算法路径的清晰性；评审时须同时对照域合订本（四型展开）和 `*_Procedure_Algorithm.md`（过程算法展开）

**代码真源**：`ufc_core/L3_MD/`（L3 Algo 定义）、`ufc_core/L4_PH/`（L4 Algo + Procedure Pointer + Pipeline）、`ufc_core/L5_RT/`（L5 编排 Algo + 金线）。

**报告 ID**：`REP-PROCEDURE-ALGORITHM`。

**与域合订本关系**：本文 **不重复** 各域合订本 §3.5 的四型图解，而是以 **过程算法** 为核心视角，交叉引用各合订本；各合订本的 Algo TYPE 字段描述以 .f90 / 合同为准。

---

## 0. 术语：三维度过程算法框架


| 术语                    | 含义              | UFC 映射                                                                  |
| --------------------- | --------------- | ----------------------------------------------------------------------- |
| **空间维度**              | 离散化、积分、拓扑映射     | Gauss 积分、形函数、单元拓扑、接触搜索、耦合场映射                                            |
| **时间维度**              | 步/增量/迭代状态机、时间积分 | Step→Inc→Itr 三步状态机、Newmark/HHT/α-Method、自动 dt、Cutback                   |
| **动作维度**              | 本构更新、力计算、施加、写出  | S-Pipeline、Uzawa Loop、K·x=f、Assemble→Apply、WB_Guard、Frame→Buffer→Writer |
| **Algo TYPE**         | 算法参数包（冷数据）      | `*_Stp_Ctl_Algo` / `*_Itr_Com_Algo` / `*_Inc_Evo_Algo`                  |
| **Procedure Pointer** | 可插拔算法入口         | `ABSTRACT INTERFACE` + `PROCEDURE(...), POINTER`                        |
| **Pipeline**          | 有序算法步骤链         | S1→S2→S3→S4 / Search→Detect→Force→Stiffness                             |


---

## Part A — 三维度过程算法全景观（跨域编排）

### A.1 时间维度：三步状态机→Solver→NR 跨域编排

**核心编排**：`RT_StepDriver`（L5 金线）驱动三步状态机，经 Solver 金线 `RT_Solv_Mgr` 调度 NR 迭代。

```text
RT_StepDriver (L5 GOLDEN-LINE)
  │ Step: IDLE → RUNNING → CONVERGED → COMPLETED
  │   ├── RT_Step_Brg (L3→L5 步参数灌入)
  │   ├── RT_Step_Algo (auto_dt / cutback / growth)
  │   │
  │   └── Increment: PREDICTING → ITERATING → CONVERGED → CUTBACK/FAILED
  │       ├── RT_Step_Ctx (dt_trial / inc_converged / work_vec)
  │       │
  │       └── Iteration: ASSEMBLING → SOLVING → UPDATING → CHECKING → CONVERGED/DIVERGED
  │           ├── RT_Solv_Mgr (K·x=f 金线)
  │           │   ├── RT_Asm (全局装配: Element→Material→Contact→LoadBC)
  │           │   ├── RT_Solv_Nonlin (NR 迭代: 残差/切线/线搜索)
  │           │   └── RT_Solv_NRState (TBP: Init/Reset/UpdateNorms)
  │           │
  │           ├── PH_Mat_Execute_Flow (S1→S4 本构管线)
  │           ├── PH_Cont_AlgorithmFramework (Search→Detect→Force→Stiffness)
  │           ├── PH_LoadBC_Domain%Assemble_Fext (载荷组装)
  │           └── RT_LoadBC_ApplyBCs (BC 施加)
  │
  ├── 步末触发: RT_Out_Mgr (Output)
  └── 步末触发: RT_WBDomain (WriteBack, LOP=2)
```

**时间维度跨域协作表**：


| 阶段                | Analysis(步驱动)      | Solver(求解)     | Element(单元) | Material(本构)         | Contact(接触)     | LoadBC(载荷)       |
| ----------------- | ------------------ | -------------- | ----------- | -------------------- | --------------- | ---------------- |
| **Step Init**     | RT_STEP_RUNNING    | —              | Populate    | Populate             | Populate        | Populate         |
| **Inc Predict**   | RT_INC_PREDICTING  | —              | Predict     | —                    | —               | Amp_GetFactor    |
| **Itr Assemble**  | RT_ITER_ASSEMBLING | RT_Asm         | Ke/Re计算     | S1_Fetch→S2_Dispatch | Search+Detect   | Assemble_Fext    |
| **Itr Solve**     | RT_ITER_SOLVING    | RT_Solv_Nonlin | —           | S3_StressUpdate      | Force+Stiffness | —                |
| **Itr Update**    | RT_ITER_UPDATING   | —              | Update u/du | S4_Tangent           | —               | —                |
| **Itr Check**     | RT_ITER_CHECKING   | Convergence    | —           | —                    | —               | CheckConvergence |
| **Inc Converged** | RT_INC_CONVERGED   | —              | —           | —                    | —               | —                |
| **Step End**      | RT_STEP_COMPLETED  | —              | —           | —                    | —               | WriteBack(LOP=2) |


### A.2 空间维度：M-S-E 三元 Populate 跨域编排

```text
L3 冷路径（模型定义 SSOT）
  │
  ├── MD_Sect_Desc (截面: thickness/orientation/mat_desc PTR/nlayer/integ)
  ├── MD_Mat_Desc (材料: family/props/stateVars 布局)
  ├── MD_Elem_Desc (单元: family/nnode/ndof/topology)
  │
  └── Populate 冷路径
      ├── PH_L4_Populate_Material (sect_id → ntens/应力态 → PH_Mat_Desc)
      ├── PH_L4_Populate_Element  (sect_id → 厚度/取向 → PH_Elem_Desc)
      ├── PH_L4_Populate_LoadBC   (amp_id → 载荷描述 → PH_LoadBC_Desc)
      ├── MD_Cont_PH_FillParams   (接触参数 → PH_Cont_Desc)
      └── MD_SectCompat::Validate_Triple (M-S-E 三元兼容性校验)
```

**空间维度跨域协作表**：


| 空间操作     | Material | Element                          | Section                      | Contact           | LoadBC                   |
| -------- | -------- | -------------------------------- | ---------------------------- | ----------------- | ------------------------ |
| **积分规则** | L4族级积分   | `Stp_Ctl_Algo%integration_order` | `MD_Sect_Algo%default_rule`  | —                 | —                        |
| **拓扑映射** | —        | `MD_Elem_Topology`               | —                            | Surface Pair      | Target Set               |
| **场映射**  | —        | `PH_Elem_MaterialRoute`          | `SectCompat_Get_StressState` | `MD_COUP_FIELD_`* | `MD_Load_Desc%load_type` |
| **离散化**  | 积分点应力    | Gauss 积分                         | 积分点数                         | 接触面离散             | 分布载荷积分                   |


### A.3 动作维度：四大管线

#### A.3.1 S-Pipeline（Material 本构管线）

```text
PH_Mat_Execute_Flow (L4 AUTHORITY)
  │ S1_FetchState: 取槽→PH_Mat_Desc+State+Ctx+Algo 联合准备
  │ S2_Dispatch:   族合法→SELECT TYPE → 族级配方入口
  │ S3_StressUpdate: 本构应力更新→PH_Mat_Lcl_Comp_State%stress
  │ S4_Tangent:    一致/连续切线→PH_Mat_Lcl_Comp_State%C_tan
  │
  └── Algo TYPE: PH_Mat_Stp_Ctl_Algo (tol_yield/max_iter) + constitutive 过程指针
```

#### A.3.2 Uzawa Loop（Contact 接触管线）

```text
PH_Cont_AlgorithmFramework (L4)
  │ Search:  BVH/Hash/CCD → 检测接触对
  │ Detect:  间隙/穿透判断 → 生成接触单元
  │ Force:   法向/切向力计算 → PH_Cont_Lcl_Pos/Lcl_Normal
  │ Stiffness: 接触刚度 → PH_Cont_Lcl_Stiff(24,24)
  │
  └── Algo TYPE: 3辅Algo (Constr_Iter/Tol/Solver + Friction + Search)
      + Procedure-as-Parameter: search_strategy PTR
```

#### A.3.3 K·x=f Pipeline（Solver 求解管线）

```text
RT_Solv_Mgr (L5 GOLDEN-LINE 277K)
  │ Assembly:    全局 K/F 装配 (Element + Contact + LoadBC)
  │ Factorize:   稀疏分解 (DIRECT/CG/GMRES/BICGSTAB)
  │ Solve:       线性求解 → du
  │ UpdateNorms: RT_Solv_NRState%UpdateNorms (res/disp/energy)
  │ Check:       收敛判断 → CONTINUING / CONVERGED / DIVERGED
  │
  └── Algo TYPE: RT_Solv_Itr_Algo + RT_Solv_NRState(TBP)
      NR策略: FULL / MODIFIED / INITIAL
      范数: L2 / LINF / L1
```

#### A.3.4 WB_Guard Pipeline（WriteBack 写回管线）

```text
RT_WBDomain (L5 GOLDEN-LINE)
  │ AttachBuffers: 绑定 L3 各域 State 容器
  │ WBImpl: 编排写回步骤
  │ MD_WB_Brg: 11 域分派 (经 WB_Guard 白名单校验)
  │ Audit: WriteBackAuditRecord (NaN 截断 + 审计)
  │
  └── Algo TYPE: RT_WB_Algo (写回策略)
      触发: 步末 / UEXTERNALDB LOP=2 / 检查点
```

---

## Part B — 八域过程算法分域详述

### B.1 Material 域（最完备范本）

**Algo TYPE 体系**：


| 层级    | Algo TYPE             | 三维度归属 | 核心字段                                              |
| ----- | --------------------- | ----- | ------------------------------------------------- |
| L3 族级 | `MD_Mat_<Fam>_Algo`   | 空间+动作 | integration_method / tangent_type / tolerance     |
| L4 域级 | `PH_Mat_Stp_Ctl_Algo` | 时间    | tol_yield / max_iter / nlgeom_flag                |
| L4 族级 | `PH_Mat_<Fam>_Algo`   | 动作    | return_mapping / cutting_plane / explicit         |
| L4 动作 | constitutive 过程指针     | 动作    | `ABSTRACT INTERFACE` → 族级配方绑定                     |
| L5    | `RT_Mat_Stp_Ctl_Algo` | 时间    | dispatch_mode / nan_check / sub_increment / retry |
| L5    | `RT_Mat_Algo`         | 时间    | stp_ctl(`RT_Mat_Stp_Ctl_Algo`)                    |


**Pipeline**：S1_FetchState → S2_Dispatch → S3_StressUpdate → S4_Tangent

**完备性评级**：✅ 三维度全覆盖（空间:族级积分, 时间:Stp_Ctl, 动作:S-Pipeline）

### B.2 Element 域

**Algo TYPE 体系**：


| 层级    | Algo TYPE                  | 三维度归属 | 核心字段                                        |
| ----- | -------------------------- | ----- | ------------------------------------------- |
| L3    | `MD_Elem_Stp_Ctl_Algo`     | 时间+空间 | integration_order / hourglass / nlgeom      |
| L3    | `MD_Elem_Stp_Dyn_Algo`     | 时间+空间 | reduced_integ / mass_type / rayleigh        |
| L3 族级 | `MD_Elem_<Fam>_Algo`       | 空间    | 族特有算法参数                                     |
| L4    | `PH_Elem_Stp_Ctl_Algo`     | 时间+空间 | integration_order / hourglass / nlgeom      |
| L4    | `PH_Elem_Stp_Ctl_Dyn_Algo` | 时间+空间 | reduced_integ / mass_type / rayleigh        |
| L4 动作 | integrator 过程指针            | 动作    | `ABSTRACT INTERFACE PH_Elem_Integrator_Ifc` |


**Pipeline**：RT_Elem_Dispatcher → integrator ptr → PH_Elem_*_Core(Ke/Re) → RT_Asm

**完备性评级**：✅ 三维度全覆盖（空间:族级积分+拓扑, 时间:Stp_Ctl+Dyn, 动作:integrator ptr）

### B.3 Section 域（正交维）

**Algo TYPE 体系**：


| 层级  | Algo TYPE             | 三维度归属 | 核心字段                                                                                          |
| --- | --------------------- | ----- | --------------------------------------------------------------------------------------------- |
| L3  | `MD_Sect_Algo`        | 空间    | default_integration_rule (1 字段)                                                               |
| L5  | `RT_Sec_Stp_Ctl_Algo` | 时间    | compat_check_mode / validate_on_populate / integration_rule_override / missing_section_policy |
| L5  | `RT_Sec_Algo`         | 时间    | stp_ctl(`RT_Sec_Stp_Ctl_Algo`)                                                                |


**Pipeline**：无独立热路径；截面参数嵌入 Element Populate → 只读消费。L5 `RT_Sec_Stp_Ctl_Algo` 管控 Populate 级策略（M-S-E 兼容/积分规则/查询）。

**完备性评级**：✅ 正交维 Populate 级算法控制已补全（空间: L3 integration_rule, 时间: L5 Stp_Ctl_Algo）

### B.4 Contact / Interaction 域

**Algo TYPE 体系**：


| 层级          | Algo TYPE                                   | 三维度归属    | 核心字段                                                          |
| ----------- | ------------------------------------------- | -------- | ------------------------------------------------------------- |
| L3          | `MD_Cont_Stp_Ctl_Algo`                      | 时间+空间+动作 | enforcement/penalty/search/friction/convergence/stabilization |
| L3          | `MD_Cont_Algo`                              | 时间+空间+动作 | stp_ctl(`MD_Cont_Stp_Ctl_Algo`) + legacy(`ContAlgo`)          |
| L3          | `MD_Int_AlgoCtrl_Algo`                      | 空间+动作    | algorithm_type / friction_model / penalty / tolerance         |
| L3          | `MD_Int_AlgoSpec_Algo`                      | 空间+动作    | method / searchAlgo / searchRadius / stabilization            |
| L3          | `MD_Int_FricParams_Algo`                    | 动作       | mu_static / mu_kinetic / tolerance / velocity_depend          |
| L4 Search   | `PH_Cont_Search_Desc_Algo`                  | 空间       | search_method / tolerance / max_candidates                    |
| L4 Constr   | `PH_Cont_Constr_Algo` (3辅: Iter/Tol/Solver) | 时间+动作    | n_aug_max / rho_aug / penalty / lagrange                      |
| L4 Friction | `PH_Cont_Friction_Algo`                     | 动作       | friction_model / rate / config                                |
| L4 动作       | `search_strategy` PTR                       | 空间+动作    | `ABSTRACT INTERFACE ContactSearchStrategy_Ifc`                |
| L5          | `RT_Contact_Algo`                           | 时间       | Uzawa: n_aug_max / rho_aug / search_frequency                 |


**Pipeline**：Search → Detect → Force → Stiffness → Uzawa AugLag

**完备性评级**：✅ P1 已补全（`MD_Cont_Stp_Ctl_Algo` 步级控制 + 3辅Algo + Procedure-as-Parameter，三维度全覆盖时间+空间+动作）

### B.5 LoadBC 域

**Algo TYPE 体系**：


| 层级  | Algo TYPE              | 三维度归属 | 核心字段                                                        |
| --- | ---------------------- | ----- | ----------------------------------------------------------- |
| L3  | `MD_Ldbc_Algo`    | 空间+动作 | 基类算法参数                                                      |
| L4  | `PH_Ldbc_Stp_Ctl_Algo` | 时间+动作 | bc_method/penalty/quad/follower/amplitude/conv_norm/cutback |
| L4  | `PH_LoadBC_Algo`       | 时间+动作 | stp_ctl(`PH_Ldbc_Stp_Ctl_Algo`) + legacy fields             |
| L5  | `RT_LoadBC_Algo`       | 时间    | cutback / adaptive_time / convergence_tol                   |


**Pipeline**：RT_LoadBC_ApplyLoads → PH_LoadBC_Domain%Assemble_Fext + RT_LoadBC_ApplyBCs → 全局 K/F

**完备性评级**：✅ P0 已补全（`PH_Ldbc_Stp_Ctl_Algo` 步级控制，三维度覆盖时间+动作）

### B.6 Output 域

**Algo TYPE 体系**：


| 层级  | Algo TYPE             | 三维度归属 | 核心字段                                                                  |
| --- | --------------------- | ----- | --------------------------------------------------------------------- |
| L5  | `RT_Out_Stp_Ctl_Algo` | 时间    | field/hist_freq_incr/time + trigger_type + force/suppress             |
| L5  | `RT_Out_Itr_Algo`     | 动作    | buffer_size + flush + compress + split + parallel_io                  |
| L5  | `RT_Out`（主 Algo）      | 时间+动作 | stp_ctl(`RT_Out_Stp_Ctl_Algo`) + itr_algo(`RT_Out_Itr_Algo`) + legacy |


**Pipeline**：CheckTrigger → PH_Out_Brg(坐标变换) → RT_Out_Frame(填充) → RT_Out_Buffer(批量) → RT_Writer_*(写出)

**完备性评级**：✅ P1 已补全（`RT_Out_Stp_Ctl_Algo` 步级频率/触发 + `RT_Out_Itr_Algo` 迭代级缓冲/压缩/IO，三维度覆盖时间+动作）

### B.7 WriteBack 域

**Algo TYPE 体系**：


| 层级  | Algo TYPE            | 三维度归属 | 核心字段                                                                           |
| --- | -------------------- | ----- | ------------------------------------------------------------------------------ |
| L5  | `RT_WB_Stp_Ctl_Algo` | 时间    | write_trigger + checkpoint + validate + checksum + force/suppress + nan_policy |
| L5  | `RT_WB_Itr_Algo`     | 动作    | buffer + compress + parallel + batch + audit                                   |
| L5  | `RT_WB_Algo`（主 Algo） | 时间+动作 | stp_ctl(`RT_WB_Stp_Ctl_Algo`) + itr_algo(`RT_WB_Itr_Algo`) + legacy            |


**Pipeline**：AttachBuffers → RT_WBImpl 编排 → MD_WB_Brg(11域分派经WB_Guard) → Audit

**完备性评级**：✅ P2 已补全（`RT_WB_Stp_Ctl_Algo` 步级触发/策略/验证 + `RT_WB_Itr_Algo` 迭代级缓冲/压缩/审计，三维度覆盖时间+动作）

### B.8 Analysis 域（半贯通复合柱）

**Algo TYPE 体系**：


| 层级          | Algo TYPE              | 三维度归属 | 核心字段                                            |
| ----------- | ---------------------- | ----- | ----------------------------------------------- |
| L3 Solver   | `MD_Solv_Itr_Com_Algo` | 时间+动作 | max_cutbacks / cutback_factor                   |
| L3 Coupling | `MD_Cpl_Stp_Ctl_Algo`  | 时间+动作 | relaxation_factor / use_aitken / subcycle_ratio |
| L5 Step     | `RT_Step_Stp_Ctl_Algo` | 时间    | auto_dt / target_iters / growth / cutback       |
| L5 Solver   | `RT_Solv_Itr_Algo`     | 时间+动作 | NR 策略 / 线性求解方法                                  |


**Pipeline**：三步状态机(Step→Inc→Itr) → RT_Solv_Mgr(K·x=f) → NR 迭代 → 收敛检查

**完备性评级**：✅ 半贯通复合柱（L3 四子域 Algo + L5 三步状态机/求解器 Algo，L4 无独立域为设计决策而非缺口）

---

## C. 过程算法缺口汇总与补全优先级


| 优先级    | 域         | 缺口                   | 补全方案                                                               |
| ------ | --------- | -------------------- | ------------------------------------------------------------------ |
| **P0** | LoadBC    | ~~L4 无统一 Algo TYPE~~ | ~~引入 `PH_Ldbc_Stp_Ctl_Algo~~`                                      |
| **P1** | Contact   | ~~L3 无 Algo TYPE~~   | ~~引入 `MD_Cont_Algo~~`                                              |
| **P1** | Output    | ~~无独立子 Algo TYPE~~   | ~~拆分 `RT_Out_Algo` 为 `Stp_Ctl_Algo`(频率/触发) + `Itr_Algo`(压缩/并行IO)~~ |
| **P2** | WriteBack | ~~无独立子 Algo TYPE~~   | ~~拆分 `RT_WB_Algo` 为 `Stp_Ctl_Algo`(写回策略) + `Itr_Algo`(审计/NaN截断)~~  |
| **P2** | Material  | ~~L5 无 Algo TYPE~~   | ~~评估是否需要 `RT_Mat_Algo~~` → 引入 `RT_Mat_Stp_Ctl_Algo`(分发/NaN/子增量)    |
| **P3** | Section   | ~~仅1字段 Algo~~        | ~~保持最简设计~~ → 引入 `RT_Sec_Stp_Ctl_Algo`(M-S-E兼容/积分规则/查询)             |


---

## D. 三维度过程算法设计原则

1. **Algo TYPE 三维度命名规则**：
  - 空间维度：`<Domain>_<SpatialOp>_Algo`（如 `MD_Cont_Search_Algo`）
  - 时间维度：`<Domain>_Stp_Ctl_Algo`（步控制）/ `<Domain>_Itr_Com_Algo`（迭代控制）
  - 动作维度：`<Domain>_<ActionOp>_Algo`（如 `PH_Cont_Constr_Algo`）+ 过程指针
2. **Procedure Pointer 三层模式**：
  - L3：仅定义 ABSTRACT INTERFACE（签名），不绑定实现
  - L4：绑定族级配方（如 `constitutive` 指针 → `PH_Mat_Plast_Execute`）
  - L5：编排层调用 L4 过程指针（如 `PH_Mat_Execute_Flow` 经 Dispatch 分派）
3. **Pipeline 可视化规则**：
  - 每域至少一张 Pipeline 流程图（text/mermaid）
  - Pipeline 中标注 Algo TYPE 消费点和 State 写入点
  - 跨域 Pipeline 标注域边界与 Populate 桥
4. **半贯通/全贯通域的 Algo 策略**：
  - 全贯通域（Material/Element/Contact/LoadBC）：L3+L4+L5 各层 Algo 独立定义
  - 半贯通域（Output/WriteBack/Analysis）：L5 Algo 为主，L4 无域时算法嵌入 L5
  - 正交维（Section）：无独立 Algo，消费 Element Algo 的积分规则

---

## E. 与域合订本交叉引用


| 域         | 四型合订本                                                             | 过程算法专域文档                           | 全景合订本文节     | 关系                           |
| --------- | ----------------------------------------------------------------- | ---------------------------------- | ----------- | ---------------------------- |
| Material  | `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` §3.5+§11 | [Material_Procedure_Algorithm.md](../Material_Procedure_Algorithm.md)（根 stub）  | B.1 + A.3.1 | S-Pipeline 详述见专域文档+四型合订本     |
| Element   | `Element_L3L4L5_four_type_UEL_discussion_synthesis.md` §3.5       | [Element_Procedure_Algorithm.md](../Element_Procedure_Algorithm.md)（根 stub）   | B.2         | integrator PTR 详述见专域文档+四型合订本 |
| Section   | `Section_L3L4L5_four_type_synthesis.md` §3.5                      | [Section_Procedure_Algorithm.md](../Section_Procedure_Algorithm.md)（根 stub）   | B.3         | 无独立过程算法，正交维设计决策              |
| Contact   | `Contact_L3L4L5_four_type_synthesis.md` §3.5                      | [Contact_Procedure_Algorithm.md](../Contact_Procedure_Algorithm.md)（根 stub）   | B.4 + A.3.2 | Uzawa Loop 详述见专域文档+四型合订本     |
| LoadBC    | `LoadBC_L3L4L5_four_type_synthesis.md` §3.5                       | [LoadBC_Procedure_Algorithm.md](../LoadBC_Procedure_Algorithm.md)（根 stub）    | B.5         | P0 补全详述见专域文档                 |
| Output    | `Output_L3L4L5_four_type_synthesis.md` §3.5                       | [Output_Procedure_Algorithm.md](../Output_Procedure_Algorithm.md)（根 stub）    | B.6         | Frame→Buffer→Writer 详述见专域文档  |
| WriteBack | `WriteBack_L3L4L5_four_type_synthesis.md` §3.5                    | [WriteBack_Procedure_Algorithm.md](../WriteBack_Procedure_Algorithm.md)（根 stub） | B.7 + A.3.4 | WB_Guard Pipeline 详述见专域文档    |
| Analysis  | `Analysis_L3L4L5_four_type_synthesis.md` §3.5                     | [Analysis_Procedure_Algorithm.md](../Analysis_Procedure_Algorithm.md)（根 stub）  | B.8 + A.1   | 三步状态机详述见专域文档+四型合订本           |


---

## F. 维护

- 新增域 Algo TYPE 时：**更新 Part B 对应域节** + 域合订本 §3.5 + CONTRACT.md。
- 新增 Pipeline 或 Procedure Pointer 时：**更新 Part A 对应管线图** + 域合订本。
- 三维度跨域编排变更时：**更新 A.1–A.3 跨域协作表** + Pillar §4.1。
- L4 LoadBC `PH_Ldbc_Stp_Ctl_Algo` 引入时：**更新 B.5 + C(P0→DONE)** + LoadBC 合订本。

---

*冷归档全文：`UFC/REPORTS/archive/Procedure_Algorithm_L3L4L5_synthesis.md`。入口 stub：`UFC/REPORTS/Procedure_Algorithm_L3L4L5_synthesis.md`。八域四型合订（根 stub）：`Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`、`Element_L3L4L5_four_type_UEL_discussion_synthesis.md`、`Section_L3L4L5_four_type_synthesis.md`、`Contact_L3L4L5_four_type_synthesis.md`、`LoadBC_L3L4L5_four_type_synthesis.md`、`Output_L3L4L5_four_type_synthesis.md`、`WriteBack_L3L4L5_four_type_synthesis.md`、`Analysis_L3L4L5_four_type_synthesis.md`。跨层模板：`Pillar_L3L4L5_CrossLayer_Design_Template.md`。一页填槽：`OnePager_FourKind_MasterAux_Nesting.md`。*