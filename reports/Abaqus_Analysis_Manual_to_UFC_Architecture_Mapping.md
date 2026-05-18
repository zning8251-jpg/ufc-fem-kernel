# Abaqus Analysis Manual(ANALYSIS_1-5) UFC Architecture Mapping
**Document**: Extracted from D:\TEST7\Manual\ANALYSIS_1-5.pdf (Abaqus 2016 Analysis User Guide 5 volumes)
**Report ID**: REP-ABAQUS-MANUAL-MAP

**SSOT**：手册对齐与域柱长期维护以 `docs/03_Domain_Pillars/Abaqus_Manual_Alignment/README.md` 及 `DomainProcedureRegistry` 为准；本文件保留 PDF 抽取映射与过程基线。去重策略见 [`SSOT_AND_DEDUP_POLICY.md`](SSOT_AND_DEDUP_POLICY.md)。

---
## 1. ANALYSIS_1: Introduction, Spatial Modeling, Execution, Output
**894 pages**: Part I (Ch.1-3) + Part II (Ch.4-5)
### 1.1 Data Structures
| Abaqus | UFC Layer | UFC Domain | Four-Type ||---|---|---|---|| Model | L3_MD | Assembly/ | MD_Mdl_Desc || Part | L3_MD | Assembly/Part/ | MD_Part_Desc || Instance | L3_MD | Assembly/ | MD_Inst_Desc || Node | L3_MD | Mesh/Node/ | MD_Node_Desc(S0) || Element | L3_MD | Elem/ | MD_Elem_Desc(S0) || Surface | L3_MD | Interaction/Surface/ | MD_Surf_Desc || Orientation | L3_MD | Section/ | MD_Sect_Desc%orientation || Section | L3_MD | Section/(SSOT) | MD_Sect_Desc || Output request | L3_MD | Output/ | MD_FieldOut_Desc || Field/History output | L3_MD | Output/ | MD_FieldOut/HistOut || Results/ODB file | L5_RT | Output/ | RT_Writer_* |
### 1.2 Core Algorithms
- Model assembly Populate: PH_L4_Populate_Element/Material/LoadBC
- Output trigger: RT_Out_Mgr step-state-machine driven

---
## 2. ANALYSIS_2: Analysis Procedures, Solution, Control
**1529 pages**: Part III (Ch.6-7) + Part IV (Ch.8-20)
### 2.1 Procedure Types (Ch.6)
| Procedure | UFC Domain ||---|---|| Static general | StepDriver/ + Solver/ || Linear perturbation | StepDriver/ + Solver/ || Eigenvalue buckling | Solver/(L2_NM) || Implicit dynamic(Newmark/HHT) | StepDriver/ + Solver/ || Explicit dynamic | StepDriver/ + Solver/(explicit) || Natural frequency(Lanczos) | Solver/(L2_NM) || Heat transfer / Thermal-stress | StepDriver/ + Solver/Coupling/ || Coupled pore fluid flow | StepDriver/ + Solver/Coupling/ |
### 2.2 NR Iteration (Ch.7.1)
Standard nonlinear solve flow:
1. Predict: K0*du = F_ext - F_int0
2. Assemble: K(du)*du = F_ext - F_int(du)
3. Convergence: force norm + disp norm + energy norm
4. Converged -> next increment / step done
5. Not converged -> Cutback
6. Exceeded -> FAILED
**UFC**: RT_Solv_Mgr golden line (Assembly-Factorize-Solve-UpdateNorms-Check)

### 2.3 Auto Incrementation (Ch.7.2.2)
- n_iters < target_iters: dt *= growth_factor
- n_iters > threshold: dt *= cutback_factor
- Diverged: dt *= 0.25, restart
- n_cutbacks > max: FAILED
**UFC**: RT_Step_Stp_Ctl_Algo matches precisely

### 2.4 Analysis Techniques (Part IV)
- Restart(Ch.9.1): RT_WB_Restart + WriteBack Checkpoint
- Substructuring(Ch.10.1): under development
- XFEM(Ch.10.7): L4_PH/Element/ special element
- ALE(Ch.12.2): L5_RT remesh
- Co-simulation(Ch.17): MD_Cpl_Desc extension
- User subroutines(Ch.18): PH_UMAT_* / PH_UEL_*

---
## 3. ANALYSIS_3: Materials
**707 pages**: Part V Materials (Ch.21-26)
### 3.1 Material Families
| Family | L3 (Desc) | L4 (Algo) ||---|---|---|| Elastic: Linear | MD_Mat_Elastic_Desc | PH_Mat_Elastic_Algo || Elastic: Orthotropic | MD_Mat_Ortho_Desc | PH_Mat_Ortho_Algo || Hyper: Mooney-Rivlin | MD_Mat_Hyper_MR_Desc | PH_Mat_Hyper_MR_Algo || Hyper: Ogden | MD_Mat_Hyper_Ogden_Desc | PH_Mat_Hyper_Ogden_Algo || Hyper: Neo-Hooke | MD_Mat_Hyper_NH_Desc | PH_Mat_Hyper_NH_Algo || Viscoelastic(Prony) | MD_Mat_Visco_Desc | PH_Mat_Visco_Algo || Plastic: Mises | MD_Mat_Plast_Mises_Desc | PH_Mat_Plast_Mises_Algo || Plastic: Hill | MD_Mat_Plast_Hill_Desc | PH_Mat_Plast_Hill_Algo || Plastic: Johnson-Cook | MD_Mat_Plast_JC_Desc | PH_Mat_Plast_JC_Algo || Plastic: Drucker-Prager | MD_Mat_Plast_DP_Desc | PH_Mat_Plast_DP_Algo || Plastic: Mohr-Coulomb | MD_Mat_Plast_MC_Desc | PH_Mat_Plast_MC_Algo || Plastic: Cam-Clay | MD_Mat_Plast_CC_Desc | PH_Mat_Plast_CC_Algo || Concrete damaged plasticity | MD_Mat_ConcDP_Desc | PH_Mat_ConcDP_Algo || Damage: Ductile | MD_Mat_Dam_Ductile_Desc | PH_Mat_Dam_Ductile_Algo || UMAT | MD_Mat_User_Desc | PH_UMAT_Context(ABI_Flat) |
### 3.2 IP State Mapping
| Abaqus field | UFC location ||---|---|| STRESS(Voigt) | PH_Mat_State%comp%stress(ntens) || DDSDDE(Jacobian) | PH_Mat_State%comp%C_tan || STATEV | PH_Mat_State%evo%stateVars || DSTRAN | PH_Mat_Ctx%lcl%dstrain || PROPS | PH_Mat_Desc%props(:) || TEMP/DTEMP | PH_Mat_Ctx%lcl%temperature |
### 3.3 S-Pipeline
S1: FetchState -> S2: Dispatch(SELECT TYPE) -> S3: StressUpdate -> S4: Tangent
- Elastic: sigma = D * epsilon
- Plastic: Radial Return Mapping
- Hyperelastic: F -> W -> Kirchhoff stress
- Viscoelastic: Prony series recursion
- Damage: effective stress -> damage var -> nominal stress

---
## 4. ANALYSIS_4: Elements
**1166 pages**: Part VI Elements (Ch.27-34)
### 4.1 Element Families
| Family | L4_PH module ||---|---|| Continuum 2D | PH_Elem_CPE4 / CAX4 || Continuum 3D | PH_Elem_C3D8 / C3D20 || Shell | PH_Elem_S4 / S8R || Beam | PH_Elem_B31 / B32 || Truss | PH_Elem_T2D2 || Membrane | PH_Elem_M3D4 || Cohesive | PH_Elem_COH* || Spring/Dashpot | PH_Elem_Spring/Dashpot || UEL | PH_UEL_Context |
### 4.2 Element Data Four-Type
| Concept | UFC location | Role ||---|---|---|| Node coords | PH_Elem_Ctx%lcl%coords | Ctx input || u/du | PH_Elem_Ctx%lcl%u/du | Ctx input || Shape fn N | PH_Elem_Algo integrator PTR | Algo || Ke | PH_Elem_State | State output || Re | PH_Elem_State | State output || Integration | PH_Elem_Stp_Ctl_Algo | Algo control |
### 4.3 Element Integration Core
1. Shape fn at xi_i
2. Jacobian J = dx/dxi
3. B matrix
4. Strain eps = B*u
5. Material: sigma, C_tan = Mat_Update(eps, deps, hist)
6. ke += int(B^T*C_tan*B*|J|*w_i)
7. re += int(B^T*sigma*|J|*w_i)
8. Global assembly

Reduced integration: fewer GP -> hourglass control
Hybrid: pressure DOF for incompressible

---
## 5. ANALYSIS_5: Prescribed Conditions, Constraints, Interactions
**962 pages**: Part VII
### 5.1 Prescribed Conditions
| Keyword | UFC domain ||---|---|| *BOUNDARY | LoadBC/(P4) || *CLOAD | LoadBC/ || *DLOAD | LoadBC/ || *AMPLITUDE | Analysis/Amplitude/(11 types) || *INITIAL CONDITIONS | LoadBC/ || *TEMPERATURE | LoadBC/ |
### 5.2 Constraints
| Type | UFC location ||---|---|| Tie | Interaction/Constraint/ || MPC(Beam/Link/Tie/Slider) | Interaction/Constraint/ || Rigid body | Interaction/Constraint/ || Coupling(Kinematic/Distributing) | Interaction/Constraint/ || Equation | Interaction/Constraint/ || Embedded region | Interaction/Constraint/ |
### 5.3 Contact Interactions
| Type | UFC domain(P3) ||---|---|| Surface-to-surface | Contact/ || Self-contact | Contact/ || General contact(Explicit) | Contact/ || Contact property | Interaction/ || Friction(Coulomb) | PH_Cont_Friction_Model |
### 5.4 Contact Algorithm
1. Search: Bucket/Grid -> candidates
2. Detect: gap>0 no contact / overclosure>0 contact
3. Force: Penalty / Lagrange / Augmented Lagrange(Uzawa)
4. Stiffness: symmetric / asymmetric(with friction)
5. Friction: Coulomb / stick-slip
**UFC**: PH_Cont_AlgorithmFramework + RT_Cont_AugLagSolv

---
## 6. Cross-Volume Data Flow
### 6.1 Lifecycle Flow
`	ext
[Cold S0-S1] Model def & Populate (A1+A3+A4+A5)
  L6_AP: INP -> L3_MD: SSOT
    -> Assembly/Part/Instance     <- A1 Ch.2.10
    -> Mesh/Node+Element           <- A1 Ch.2.1-2.2
    -> Section/Orientation         <- A1 Ch.2.2.5
    -> Material                    <- A3 Ch.21-26
    -> LoadBC/Amplitude            <- A5
    -> Output                      <- A1 Ch.4
  -> L3->L4 Populate              <- A2 Ch.7

[Hot S2-S4] Solve (A2+A4+A5)
  L5 StepDriver: Step->Inc->Iter <- A2 Ch.7.1
  L5 Solver:
    Assembly: Ele(Material)+Contact+LoadBC
    Factorize -> Solve -> Check  <- A2 Ch.7.2

[WriteBack W1-W2] (A1+A2)
  Output: Frame->Buffer->Writer  <- A1 Ch.4
  WriteBack: WB_Guard->11domain   <- A2 Ch.9
`

---
## 7. UFC Architecture Gap Analysis
### 7.1 Gap Priorities
| Pri | Gap | Current | Suggestion ||---|---|---|---|| P0 | Constraint domain | scattered | Reference Contact P3 || P1 | Element formula variants | partial enum | Add H/I/R || P1 | NR convergence strategy | 3 strategies | Adaptive strategies || P2 | Shape function library | inlined | Extract ShapeFunc_Library || P2 | Hourglass control | %hourglass reserved | Add both methods Algo || P2 | Multi-field coupling | basic | Subcycling/staggered || P3 | Analysis type enum | partial | Extend to 15+ types |
### 7.2 New Domain Candidates
| Domain | Scope | Reference ||---|---|---|| Constraint | Tie/MPC/Coupling/Equation | Contact P3 || Adaptivity | ALE/Adaptive remesh/Mesh-to-mesh | half pillar || Substructure | Substruct/Submodel/Matrix gen | L3+L5 |
---
Path: UFC/REPORTS/Abaqus_Analysis_Manual_to_UFC_Architecture_Mapping.md
Generated: 2026-05-05, v1.0

---
## 8. 缺口修复记录 (按优先级 P0-P1-P2) — 2026-05-05
本节记录了根据 §7 缺口分析按优先级完成的补全与修复。

### 8.1 P0 完成 — Constraint 域 Embedded Region 补全
| 子项 | 状态 | 变更描述 |
|------|------|----------|
| **L3 类型 EmbeddedRegionDef** | ✅ 已实现 | MD_Constr_Def.f90: 新增 MD_CONSTR_EMBEDDED=5 常量, EmbeddedRegionDef 类型 (embed_id, host_set, embedded_set, use_rounding, embedded_elem_ids, host_elem_ids, host_coeffs), P0 生命周期 Init/Valid/Cleanup |
| **MD_ConstraintUnion 扩展** | ✅ 已实现 | 新增 embedded(:) 数组 + 
_embedded 计数, 统一容器从 4-型升级为 5-型 |
| **L4 PH_ConstrEmbedded_Def.f90** | ✅ 已实现 | EmbeddedRegion_Params (Desc), EmbeddedRegion_State (State), EmbeddedRegion_Brg_Ctx (Ctx) 四型定义 + P0 生命周期 |
| **L4 PH_Constr_Embedded.f90** | ✅ 已实现 | 核心算法: SearchHostElem, TestPointInElem, ComputeWeights, AssemblePenalty, AssembleLagrange, CheckViolation, FindNearestHost |
| **L4 PH_ConstrEmbedded_Brg.f90** | ✅ 已实现 | Bridge 施加入口: Embedded_Init, BuildNodePairs, ApplyConstraint, Apply, CheckViolation |
| **L3 CONTRACT.md 更新** | ✅ 已实现 | 常量表、Desc 表、Union 容器同步 v3.1→v3.2 |

### 8.2 P1 完成 — 枚举常量系统化

#### 单元公式变体 (MD_Elem_Def.f90 + PH_Elem_Aux_Def.f90)
| 枚举族 | 常量 | 说明 |
|--------|------|------|
| **MD_ELEM_FORM_*** (7值) | DISP=0, HYBRID=1, INCOMPAT=2, REDUCED=3, SELECTIVE=4, FBAR=5, ASSUMED_STRAIN=6 | 单元公式变体选择 |
| **MD_ELEM_HG_*** (5值) | NONE=0, STIFFNESS=1, VISCOUS=2, ENHANCED=3, RELAXED=4 | 沙漏控制方法 |
| **MD_ELEM_MASS_*** (3值) | CONSISTENT=1, LUMPED=2, HRZ=3 | 质量矩阵类型 |
| **MD_ELEM_INTEG_*** (4值) | FULL=0, REDUCED=1, USER=2, SELECTIVE=3 | 积分方案 |
| **PH_ELEM_*** 镜像 | 同上 | L4 侧完全镜像 L3 枚举值 |

#### 材料族枚举 (MD_Mat_Def.f90)
| 常量 | 映射族 | 说明 |
|------|--------|------|
| MD_MAT_FAM_ELAS=1 ~ MD_MAT_FAM_USER=11 | 11 族 | 全面覆盖弹性/塑性/超弹/黏弹/蠕变/损伤/热/声/地质/复合/用户 |
| MD_MAT_INTEG_BE/MP/CRANK/EXPL | 4 值 | 本构积分方案: 后向欧拉/中点/克兰克-尼科尔森/前向欧拉 |

#### NR 收敛策略 (RT_Solv_Def.f90)
| 常量 | 说明 |
|------|------|
| RT_SOLV_CONV_DISP/FORCE/ENERGY/MIXED | 收敛准则类型 |
| RT_SOLV_AUTO_DT_*_DEFAULT (6 常量) | auto-dt 默认参数: growth_factor=1.25, cutback_factor=0.25, expand_factor=1.50, target_iters=8, growth_threshold=12 |
| RT_KXF_STAGE_ASSEMBLE/FACTORIZE/SOLVE/UPDATENORMS/CHECK | K.x=f 流水线阶段枚举 |
| RT_STEP_TYPE_STATIC_GENERAL ~ RT_STEP_TYPE_SUBSPACE (10 值) | 分析步类型枚举 |

### 8.3 P2 完成 — 模块化与策略扩展

#### 形函数库 (PH_Elem_ShapeFunc_Library.f90)
- ✅ 13 个形函数评估子程序 (Hex8/20/27, Quad4/8/9, Tet4/10, Tri3/6, Wedge6/15, Line2/3)
- ✅ 高层分发: SF_Eval_N_and_dN, SF_Eval_ByTopology (含雅可比计算)
- ✅ 3x3 矩阵求逆工具: SF_Inverse3x3
- **架构意义**: 将形函数计算从特化单元内核中提取为独立模块, 支撑 Embedded 搜索、接触投影、约束配对等跨域需求

#### 沙漏控制
- ✅ L3 MD_Elem_Stp_Ctl_Algo 已有 hourglass_type + hourglass_coeff 字段
- ✅ L4 PH_Elem_Stp_Ctl_Algo 已有 hourglass_control + hourglass_coeff 字段
- ✅ 枚举常量 MD_ELEM_HG_* / PH_ELEM_HG_* 提供 NONE/STIFFNESS/VISCOUS/ENHANCED/RELAXED 五型
- 实现状态: 枚举已定义, 具体算法实现在后续热路径迭代中接入

#### 多场耦合子循环策略 (MD_Cpl_Def.f90)
- ✅ MD_Cpl_Stp_Ctl_Algo 扩展: 新增 subcycle_adaptive, subcycle_min_dt, stagger_strategy(sequential/parallel/block), use_predictor, predict_type(zero/linear/extrapolation), 
relaxation_min/max, Aitken_init
- ✅ 与现有 MD_COUP_STRAT_* (ONEWAY/STAG/PARTITER/MONO) 形成完整的耦合策略矩阵

### 8.4 补全摘要
| 优先级 | 总计 | 文件变更 | 新增文件 |
|--------|------|----------|----------|
| P0 | 1 项 | MD_Constr_Def.f90 + CONTRACT.md | PH_ConstrEmbedded_Def.f90, PH_Constr_Embedded.f90, PH_ConstrEmbedded_Brg.f90 |
| P1 | 3 项 | MD_Elem_Def.f90, PH_Elem_Aux_Def.f90, MD_Mat_Def.f90, RT_Solv_Def.f90 | — |
| P2 | 3 项 | MD_Cpl_Def.f90 | PH_Elem_ShapeFunc_Library.f90 |
| **合计** | **7 项** | **8 文件修改** + **4 文件新增** | |

### 8.5 遗留缺口 (P3+ / 后续)
以下缺口因优先级低于 P2 未在本轮修复:
1. **L5 独立 Constraint 目录**: 半柱 H1 设计是刻意的 (L3+L4 半贯通), L5 由 RT_Asm_ApplyL3Constraints 消费, 不增设独立目录
2. **RBE2/RBE3 专用 Bridge 文件**: 当前 Rigid Body 表面解析由 MD_Constr_Brg.f90 统一处理, 后续如需分离可新建
3. **Equation 关键字独立模块**: 当前 *EQUATION 解析流入 MPCConstraintDef, 语义上足够
4. **Contact NTS (55%) / STS / Mortar 补全**: 属于 Contact 域持续迭代范畴
5. **ABI_Flat 类型 (PH_UEL_Context 等)**: 设计已完成, 待热路径实现时落地
