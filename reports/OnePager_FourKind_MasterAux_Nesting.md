# One-pager: Four kinds (master/aux), total/partial, parallel/nesting (draft)

**Path**: `UFC/REPORTS/OnePager_FourKind_MasterAux_Nesting.md`  
**Role**: Does **not** replace per-domain `CONTRACT.md`. Use for **Material / Element / Section / Contact / LoadBC / Output / WriteBack** reviews: fill one truth per cell, aligned with **`Pillar_L3L4L5_CrossLayer_Design_Template.md`** and domain synthesis REPORTS.

---

## 1. Structure (total / partial / parallel / nest)

**Parallel (four masters)**: One runtime instance holds **`desc`, `ctx`, `state`, `algo` as four sibling members**. No **fifth top-level pillar** as co-equal master.

**Nest (aux)**: Under each master, **Depth-2+ aux `TYPE`** (e.g. `…_Lcl_Comp_State`, `…_Inc_Evo_Ctx`). Aux **must not** be promoted to a fifth top-level master.

**The `algo` master -- structural slot vs. algorithm container**:

- As a **structural slot**, `algo` is the fourth sibling in the master quadruplet (subject to all R-01--R-08 rules on nesting, SSOT).
- As an **algorithm container**, `algo` holds **step/iteration control parameters** (tolerance, cutback, frequency), **Procedure Pointer(s)** to replaceable implementations (Material `constitutive` PTR, Element `integrator` PTR, Contact `search_strategy` PTR), and/or **enum-driven dispatch keys** (LoadBC `bc_method`, Solver NR strategy).
- **Consequence for this document**: Every domain's `algo` row in the fill-in tables must list both **structural aux types** and **algorithm semantics** (what they control, which pipeline they feed). See **`Procedure_Algorithm_L3L4L5_synthesis.md`** xc2xa7A (Algo TYPE and the four pipelines) and xc2xa7E (design principle: Algo as structural + algorithmic dual) for further detail.
- Per-domain procedure/algorithm zoom: `*_Procedure_Algorithm.md` xc2xa72 (Algo TYPE fields), xc2xa73 (Procedure Pointer), xc2xa74 (pipeline).

**Total / partial**: **Total** = single hub (`PH_Mat_Slot`, `PH_Elem_Domain`, etc. per contract); boundaries pass **hub + index**. **Partial** = in-procedure **`ASSOCIATE` / narrow `*_Arg`** to aux leaves; avoid leaking deep chains across layers.

**Parallel to four kinds (not a fifth kind)**: **ABI Mirror** (code `PH_UMAT_Context` / target `PH_UEL_Context`; doc **`PH_*_Mirror`**) and **`*_Arg` bundles** are **not** the four-kind **`Ctx`**; they serve **external subroutine ABI / Harness / multi-field evolution**.

```
  Hub (Slot / Domain)
  ├── desc  ─┬─ aux …
  ├── ctx   ─┼─ aux …
  ├── state ─┼─ aux …
  └── algo  ─┴─ aux …

  Parallel (contract):  Mirror (UMAT/UEL ABI)   *_Arg (layer / harness)
```

---

## 2. Hard rules (reject in review if violated)

| ID | Rule |
|----|------|
| **R-01** | **Only one set of four masters** at top level: `desc, ctx, state, algo`. **No** promoting an aux block as a **fifth co-equal master** truth source. |
| **R-02** | **Aux nests only**: Prefer new semantics under an **existing master + aux `TYPE`**. New master semantics need **contract change + naming audit**. |
| **R-03** | **Total / partial**: Hot boundaries prefer **`hub + index`**. **No** permanent **30+ flat-parameter** APIs at L4/L5 mirroring UMAT/UEL lists (except user hook surfaces). |
| **R-04** | **Mirror != Ctx**: In docs/reviews use **`PH_*_Mirror`**; **no** ambiguous "Context" for both **four-kind `Ctx`** and **ABI flat bundle** without qualifier. |
| **R-05** | **L5 does not own step-inner large-array SSOT** (Voigt stress, full RHS, etc.) unless contract states **tiny** metadata; same as Pillar invariants. |
| **R-06** | **No dual SSOT**: e.g. **L3 full four-kind** and **L4 slot full four-kind** both as **step-inner co-writers** (same pattern as Material **§8.1c** / Section intro). |
| **R-07** | **SIO**: `*_Arg` at Harness/layer boundaries per **`AGENTS.md` Principle #14**; **no** thin `Arg` that only wraps `status`. |
| **R-08** | **Section cross-cut**: `sect_id` / `MD_Sect*` and **Populate read order** must match **this table + `Section_…` + Element/Material Populate**; **primary mount** (embed in `PH_Elem_*` vs standalone `PH_Sect_*`) is **one** contract choice; the other is **view**. |

---

## 3. Fill-in tables

**How to fill**: Each cell: **one SSOT sentence** + optional `TYPE` / module; **step-inner write owner** must **cite a contract subsection**.

### 3.1 Material / Element / Section（✅已填）

| Row | **Material** | **Element** | **Section (orthogonal)** |
|-----|----------------|---------------|----------------------------|
| **Hub** | `PH_Mat_Slot`(L4槽) / `RT_Mat_Core`(L5路由); **Pillar §4.1** | `PH_Elem_Domain`(L4配方域) / `RT_Elem_Dispatcher`(L5调度); **Pillar §4.1** | `MD_Sect_Domain`(L3冷真源, 无L4独立域); **Pillar §4.1** |
| **`desc` + aux** | `PH_Mat_Desc` + **3辅**：`Cfg_Init_Desc`(配置) / `Pop_Vld_Desc`(校验) + `props(:)`; L3: `MD_Mat_Desc`/**族** `MD_Mat_<Fam>_Desc`/`MD_Mat_User_Desc`(EXTENDS); **合订本 §2.5.1** | `PH_Elem_Desc` + **辅** `Cfg_Init_Desc`; L3: `MD_Elem_Desc` + `MD_Elem_UEL_Desc`(SSOT: ndofel/nprops/props/jtype); **合订本 §3.5.1** | `MD_Sect_Desc`(SSOT: section_id+`mat_desc` PTR+厚度/取向/层数/积分+9族×17类型+5 TBP) + `MD_Sect_Registry`(6 TBP) + `MD_Sect_Catalog_Desc`(256); L4无独立(Populate灌入`PH_Elem_Desc`); **合订本 §3.5.1** |
| **`ctx` + aux** | `PH_Mat_Ctx` + **2辅**：`Inc_Evo_Ctx`(步/增量/`dt`) / `Lcl_Comp_Ctx`(`dstrain`/`temperature`/等效应变速率); **合订本 §2.5.1** | `PH_Elem_Ctx` + **辅** `Lcl_Comp_Ctx`(`u/du`/形函数/`J`); L3: `MD_Elem_Ctx (原 MD_Elem_Ctx 已去Base)`; **合订本 §3.5.1** | `MD_Sect_Ctx`(`current_section_idx`查询); L4: 嵌入`PH_Elem_Ctx`为主挂载(方案B); **合订本 §3.5.2** |
| **`state` + aux** | `PH_Mat_State` + **2辅**：`Lcl_Comp_State`(`stress`/`C_tan`) / `Lcl_Evo_State`(`stateVars`/`stateVars_n`); **合订本 §2.5.1** | `PH_Elem_State`(收敛标志/计数; `rhs/amatrx`落位见合同U0) + **辅** `Lcl_Comp_State`; L3: `MD_Elem_State (原 MD_Elem_State 已去Base)`; **合订本 §3.5.1** | `MD_Sect_State`(域统计: active_sections+total_section_area); L4: 步内力学态不在截面域持主份(**TRIMMED/派生**); **合订本 §3.5.1** |
| **`algo` + aux** | `PH_Mat_Algo` + **2辅**：`Stp_Ctl_Algo`(步控) / `constitutive`过程指针; 族级 `PH_Mat_<Fam>_Algo`; L5: `RT_Mat_Algo`(**1辅**：`Stp_Ctl_Algo`(分发/NaN/子增量 P2补全)); **合订本 §2.5.1** | `PH_Elem_Algo` + **2辅**：`Stp_Ctl_Algo`(静) / `Stp_Ctl_Dyn_Algo`(动); 积分子/沙漏; L3: `MD_Elem_Algo (原 MD_Elem_Algo 已去Base)`; **合订本 §3.5.1** | `MD_Sect_Algo`(default_integration_rule冷侧); L4: **DELEGATED**至`PH_Elem_Algo`(方案B); L5: `RT_Sec_Algo`(**1辅**：`Stp_Ctl_Algo`(M-S-E兼容/积分规则/查询 P3补全)); **合订本 §3.5.2** |
| **ABI Mirror** | `PH_UMAT_Context`(**文档名 ABI_Flat**, ≠`PH_Mat_Ctx`); 见附录G.0; **合订本 §2.5.5** | `PH_UEL_Context`(**文档名 ABI_Flat**, ≠`PH_Elem_Ctx`); 与UMAT对偶; 见附录C.0; **合订本 §3.5.5** | (无); celent/厚度来自截面+单元联合, 不引入第三ABI; **合订本 §3.5.5** |
| **`*_Arg` bundle** | `PH_Mat_Update_Arg`(热路径核); `PH_Mat_Eval_Arg`(`ArgIn`/`ArgOut`); `RT_Mat_Dispatch_Ctx`(跨层路由); **合订本 §2.5.4** | `PH_Elem_<Verb>_Arg`; `PH_Elem_Core_*_Arg`; UEL专用 `PH_UEL_*_Arg`; **合订本 §3.5.4** | `MD_Sect_Add/Validate/Get/GetByName/GetSummary_Arg`(5种SIO); **合订本 §3.5.4** |
| **Populate** | `PH_L4_Populate_Material`(`MD_Mat_Registry_Access_Desc`+SELECT TYPE族感知+`PH_L4_Alloc_State_ForFamily`); **合订本 §2.5.6** | `PH_L4_Populate_Element`(合同); `MD_Elem_Populate`+`MD_ElemPH_Brg`(冷数据/桥); **合订本 §3.5.6** | `MD_Sect_Brg`(L3→L4校验/应力态桥)+`MD_SectCompat::Validate_Triple`(M-S-E)+`MD_Sect_Brg_Get_StressState`(`ntens`派发); **合订本 §3.5.6 mermaid** |
| **Dispatch (hot)** | `RT_Mat_Dispatch_Stress`→`PH_Mat_Execute_Flow`(S1取槽→S2族合法→S3应力更新→S4切线→写回槽); **合订本 §2.5.2** | `RT_Elem_Dispatcher`/`RT_Elem_*Proc`; 各`PH_Elem_*`配方; `PH_Elem_MaterialRoute`; UEL: `RT_Elem_UEL_API`; **合订本 §3.5.2** | (无独立热路径); 截面参数嵌入单元Populate→配方只读消费(`GetThickness`/`SetSectionProps`); L5: `RT_Elem_Sect`(门面/探针); **合订本 §3.5.3** |
| **Write owner** | L4槽`state%comp%stress`+`state%evo%stateVars`步内权威; UMAT形参仅调用期视图(附录F); **Pillar §4.1** | L4配方`PH_Elem_*`步内权威; `rhs/amatrx`落位见合同U0; L5不复制Voigt级大数组; **Pillar §4.1** | L3 `MD_Sect_*`冷真源(步内只读); L4嵌入单元配方(方案B)步内只读派生; **防双主源**(禁L3+L4+嵌入三SSOT并列); **Pillar §4.1** |
| **Join keys** | `mat_id`/`mat_pt_idx` + `mat_model_id`(族路由) + `sub_type`; **合订本 §2.5.6** | `elem_type_id`/`family_id` + `sect_id`(截面轴M-S-E) + `mat_id`(材料路由); **合订本 §3.5.6** | `sect_id` + `mat_id` + `elem_type_id`(**M-S-E联合键**, `SectCompat_Get_StressState`); **合订本 §3.5.6 mermaid** |
| **Prohibitions** | 禁双四型(§8.1c); 禁`E=>props(1)`指针别名; `PH_UMAT_Context`≠`PH_Mat_Ctx`; SDV双写须用`DualWrite`; **合订本 §2.5.5**; **Pillar §4.1** | 禁`PH_Elem_UEL_Desc`等第二套槽四型; 禁`PH_ElemUEL_Context`(与UMAT不对称); `PH_UEL_Context`≠`PH_Elem_Ctx`; **合订本 §3.5.5**; **Pillar §4.1** | 禁L3+L4+嵌入三主源并列SSOT(**§5**); celent/厚度与UEL重叠时须合同定优先序(防双写); 截面不引入独立ABI(**§3.5.5**); **Pillar §4.1** |

### 3.2 Contact / LoadBC（全贯通柱 ✅已填）

| Row | **Contact (P3)** | **LoadBC (P4)** |
|-----|-------------------|-----------------|
| **Hub** | `PH_Cont_Domain`(L4) / `RT_Cont_Solv`(L5金线) | `PH_LoadBC_Domain`(L4金线TBP) / `RT_Ldbc_Impl`(L5) |
| **`desc` + aux** | `PH_Cont_Desc` + **3辅**：`Constr`(config+penalty) / `Friction`(model+coeff+physical) / `Search`(algo+params) + 2cfg; L5: `RT_Contact_Desc`(DELEGATED→L3索引) | `PH_LoadBC_Desc`(**扁平**：load_type+ndof+value+amp+pressure+big_num); L5: `RT_LoadBC_Desc`(DELEGATED→L3，步调度窗+amp_id) |
| **`ctx` + aux** | `PH_Cont_Ctx` + **3辅**：`Lcl_Pos`(x_slave/master) / `Lcl_Normal`(normal) / `Lcl_Stiff`(K_contact(24,24)); L5: `RT_Contact_Ctx`(栈标量：pair_idx+gap+normal+tangent+shape) | `PH_LoadBC_Ctx`(**扁平**：Fe(192)+N_shape(27)+normal+area+volume); L5: `RT_LoadBC_Ctx`(POINTER：F_global+u_prescribed+bc_flags) |
| **`state` + aux** | `PH_Cont_State` + **6辅**：Geometry / Force / Stiffness / Friction / Convergence / Itr_Quick; L5: `RT_Contact_State`(pair_active+status+Uzawa_lambda) | `PH_LoadBC_State`(**扁平**5字段：applied+n_active+current_step); L5: `RT_LoadBC_State`(applied+cutback+iterations+work+amp) |
| **`algo` + aux** | `PH_Cont_Algo` + **3辅**：Constr(iter+tol+solver) / Friction(rate+config) / Stp_Method + **Procedure-as-Parameter** `search_strategy` PTR; L5: `RT_Contact_Algo`(Uzawa: n_aug_max+rho_aug+search_frequency) | `PH_LoadBC_Algo`(**扁平**：bc_method+penalty+quad+follower); L5: `RT_LoadBC_Algo`(cutback+adaptive_time+convergence_tol) |
| **ABI Mirror** | `PH_Contact_InterfaceCtx/State`; VUINTER/UINTER/GAPCON/GAPUNIT; **合订本 §3.5.5**（FRIC/FRIC_COEF/UINTER/VUINTER/VFRIC/GAPCON原型+映射+选型表） | `PH_ULOAD_Context`+`PH_DLOAD_Context`(**ABI_Flat**, ≠`PH_LoadBC_Ctx`); ULOAD/DLOAD用户载荷入口; 见合订本 §3.5.7/§3.5.8; 后续可引入 `PH_Ldbc_Stp_Ctl_Algo` |
| **`*_Arg` bundle** | `MD_Int_ContactArgs` | `RT_Ldbc_Proc`(SIO 16types/8组) |
| **Populate** | `MD_Cont_PH_FillParams_FromMD`(L3→L4); `RT_Contact_Brg_FromL3`(L3→L5) | `PH_L4_Populate_LoadBC`(L3→L4); `MD_LoadBC_PH_Brg`(BuildStep*Idx) |
| **Dispatch (hot)** | `RT_Cont_Solv`→搜索→检测→力→刚度; `PH_Cont_AlgorithmFramework` | `RT_LoadBC_ApplyLoads`→`%Assemble_Fext`; `RT_LoadBC_ApplyBCs`→全局K/F |
| **Write owner** | L5 `RT_Cont_Solv`编排; L4 `PH_Cont_Core`计算 (合同 §3.2) | L5 `RT_Ldbc_Impl`编排; L4 `PH_LoadBC_Domain%Assemble_Fext` (合同 §3.2) |
| **Join keys** | contact_pair_id + slave/master_surface_id | loadbc_id + dof_index + step_sched + amp_id |
| **Prohibitions** | L4不持Desc真源; L4不编排迭代; L5不计算力; 双名Cont/Contact等价 | 扁平四型(暂不嵌套); Constraint分界(*TIE/*MPC不属LoadBC) |

### 3.3 Output / WriteBack（半贯通柱 ✅已填）

| Row | **Output (P5)** | **WriteBack (P6)** |
|-----|------------------|---------------------|
| **Hub** | `RT_Out_Mgr`(L5 GOLDEN-LINE) | `RT_WriteBack_Domain`(L5 GOLDEN-LINE 9TBP) |
| **`desc` + aux** | `RT_Out_Desc`(PTR→L3 Registry/FieldReq/HistReq); L3 `MD_Out_Def`(SSOT: Registry+FieldOut_Desc+HistOut_Desc+枚举) | `RT_WB_Desc`(frequency+trigger+字段开关+scope+local_coords); L3 `MD_WriteBack_Desc`(SSOT: 白名单+WB_DOMAIN_11常量+映射) |
| **`ctx` + aux** | `RT_Out_Ctx`(扁平：step/incr/time+flags) | `RT_WB_Ctx`(**全POINTER预分配**：u/v/a/stress/strain/rf_buffer+elem/node_ptr; **禁ALLOCATABLE**) |
| **`state` + aux** | **双State**：`RT_Out_FieldState`(帧计数+触发+CheckTrigger TBP) / `RT_Out_HistState`(数据点+buffer+AddPoint TBP); **辅** `RT_Out_Frame`(节点/单元ALLOCATABLE容器) / `RT_Out_Buffer`(循环Push/Pop/Flush) / `RT_Out_TriggerCtx` | **双State**：`RT_WB_ProgressState`(写回计数+计时+成功/失败) / `RT_WB_BufferState`(缓冲+flush+分配跟踪); **辅** `RT_WB_TransformCtx`(rot_matrix+coord_sys) / `CheckpointStatus`(id+step+time+checksum+u(:)) / `WriteBackAuditRecord`(record_id+operation+checksum) |
| **`algo` + aux** | `RT_Out`(**2辅**：`Stp_Ctl_Algo`(步级频率/触发, P1补全) / `Itr_Algo`(迭代级缓冲/压缩/IO, P1补全); Init/SetFrequency TBP) | `RT_WB_Algo`(**2辅**：`Stp_Ctl_Algo`(步级触发/策略/验证, P2补全) / `Itr_Algo`(迭代级缓冲/压缩/审计, P2补全); Init/SetBufferStrategy TBP) |
| **ABI Mirror** | `PH_UVARM_Context`(ABI_Flat, ≠`RT_Out_Ctx`); UVARM/VUVARM/URDFIL/UHISTR/USDFLD; **合订本 §3.5.7**（原型+映射+Field/History双轨选型表） | `PH_UEXTDB_Context`(ABI_Flat, ≠`RT_WB_Ctx`); UEXTERNALDB/STATEV/PUTVRM; **合订本 §3.5.7**（三级写回选型表+LOP生命周期映射） |
| **`*_Arg` bundle** | `RT_Out_Proc`(SIO 5组) | `RT_WBProc`(SIO 5组) |
| **Populate** | L3 `MD_Out_*`注册/解析→L5 **PTR引用**（不经Populate金线） | **不参与Populate**（反方向L5→L3）; WB-01唯一合法L3步内变异路径 |
| **Dispatch (hot)** | `RT_Out_Mgr`→`FieldState%CheckTrigger`→`PH_Out_Brg`→`RT_Out_Frame`填充→`RT_Out_Buffer`批量→`RT_Writer_*` | `RT_WB_Ctx%AttachBuffers`→`RT_WBImpl`编排→`MD_WB_Brg`11域分派(经**WB_Guard**)→L3各域 |
| **Write owner** | L5 `RT_Out_Mgr`编排; **不写回L3**（与WriteBack分界, §8） | L5→L3唯一合法路径(WB-01); 白名单外FATAL(WB-03); `MD_WB_Brg`WB_Guard校验(合同§3) |
| **Join keys** | output_label + md_registry PTR + output_format | WB_DOMAIN_* 11域常量 + operation_type + field_type |
| **Prohibitions** | 不写回L3; L4无独立域(半柱); Frame ALLOCATABLE(非热路径) | L4禁止直写L3(WB-02); 热路径禁ALLOCATABLE; 白名单外FATAL; WriteBack先于Output |

### 3.4 Analysis（半贯通复合柱 ✅已填）

| Row | **Analysis (Step/Amplitude/Solver/Coupling)** |
|-----|---------------------------------------------|
| **Hub** | `RT_StepDriver`(L5 步驱动金线) + `RT_Solv_Mgr`(L5 求解器金线) |
| **`desc` + aux** | **Step**: `RT_Step_Desc`(inc+itr辅) / `RT_StepDriver_Desc`(旧版); L3: `MD_Step_Mgr`(步真源); **Amplitude**: `MD_Amp_Desc`(11类型统一+Tab/Periodic/Decay/Modulated/Smooth/Ramp分支+Cfg/Itr View辅); L5无独立域; **Solver**: `RT_Solv_Desc`(cfg+itr_cache辅, PTR→L3); L3: `MD_Solver_Desc`(cfg+itr+stp辅)+Stub `MD_LinearSolver_Desc`/`MD_NR_Algo`/`MD_Precond_Desc`; **Coupling**: `MD_Cpl_Desc`(n_pairs+PairDef数组+ctl辅); L5经Solver消纳; **合订本 §3.5.1–3.5.4** |
| **`ctx` + aux** | **Step**: `RT_Step_Ctx`(inc+itr辅: Itr_Ctrl/Residual/Metrics + work_vec POINTER + pool_slot); L3: `MD_Step_Ctx`(inc+itr辅: Newmark/HHT参数); **Solver**: `MD_Solver_Ctx`(itr辅+work_vec/rhs POINTER); L5: NRState含TBP; **合订本 §3.5.1–3.5.3** |
| **`state` + aux** | **Step**: `RT_Step_State`(inc+stp辅: step_status/n_cutbacks/total_iters); L3: `MD_Step_State`(inc+stp辅); **Solver**: `RT_Solv_NRState`(stp+itr辅: Ctrl/Norms/Refs/Flags + TBP:Init/Reset/UpdateNorms); `RT_Solv_Linear_Stp/Itr_State`(辅); L3: `MD_Solver_State`(stp+itr辅); **合订本 §3.5.1–3.5.3** |
| **`algo` + aux** | **Step**: `RT_Step_Algo`(stp辅: auto_dt/target_iters/growth/cutback); `RT_StepDriver_Algo`(tol+strat); L3: `MD_Solver_Algo`(itr辅含cutback); **Amplitude**: `MD_Amp_Algo`(interpolation_method); **Coupling**: `MD_Cpl_Algo`(stp辅: relaxation/aitken/subcycle); **合订本 §3.5.1–3.5.4** |
| **ABI Mirror** | （无独立ABI）; UEXTERNALDB LOP生命周期映射见WriteBack §3.5.7a; UAMP/VUAMP在`MD_Amp_User_Desc`覆盖; **合订本 §4** |
| **`*_Arg` bundle** | `MD_Amp_Add/Get/EvalAtTime/GetSummary_Arg`(4种SIO); `MD_Amp_Apply_*_Arg`(4种); `MD_Step_*`无独立Arg(步参数经Brg灌入) |
| **Populate** | `RT_Step_Brg`(L3→L5步参数); `RT_Solv_Brg`(L3→L5求解器参数); 幅值不经Populate(L3求值`Amp_GetFactor`); 耦合经`MD_Cpl_Pop_Brg_Ctx`; **合订本 §3.1** |
| **Dispatch (hot)** | `RT_StepDriver`三步状态机(Step→Inc→Iter)→`RT_Solv_Mgr`(K·x=f)→NR迭代→收敛检查→Cutback/步完成; 触发Output/WriteBack; **合订本 §3.2** |
| **Write owner** | L5 `RT_StepDriver_State`步/增量/迭代状态唯一真源; L5 `RT_Solv_NRState`求解器状态唯一真源(含TBP); L3配置步内只读; **合订本 §3.5.8** |
| **Join keys** | step_idx + solver_config_id + amp_id + pair_id + strategy(MD_COUP_STRAT_*) |
| **Prohibitions** | L4无独立Analysis域(禁建PH_Step_*/PH_Solver_*四型); L5不复制L3配置(PTR引用); 三步状态机唯一权威; Desc↔Algo转换有界; 幅值求值在L3; **合订本 §3.5.8** |

---

## 4. Cross-references

- **Material**: `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` **§2.5**（四型主/辅架构图解: L3/L4/L5全景+3辅Desc+2辅State+2辅Ctx+2辅Algo+mermaid）+ appendix **F/G**, **§10.14**; `PH_UMAT_*`, **`PH_Mat_Slot`**; **Pillar §4.1**.  
- **Element**: `Element_L3L4L5_four_type_UEL_discussion_synthesis.md` **§3.5**（四型主/辅架构图解: L3/L4/L5全景+2辅Desc+4辅Ctx+2辅State+2辅Algo+ABI对偶+mermaid）+ appendix **C**, **§6**; `PH_UEL_*`, **`PH_Elem_Domain`**; **`L4_PH/Element/CONTRACT.md` U0**; **Pillar §4.1**.  
- **Section**: `Section_L3L4L5_four_type_synthesis.md` **§3.5**（L3四型全景+9族×17类型+M-S-E数据流mermaid+防双主源+无ABI Mirror）+ **§9 S0**（`sect_id`）; no silent double-write with UEL `props` (Material **§14.5**); **Pillar §4.1** Section行.  
- **Contact**: `Contact_L3L4L5_four_type_synthesis.md` **§3.5**（6辅State+3辅Desc+3辅Algo+3辅Ctx+Procedure-as-Parameter+ABI镜像+FRIC/UINTER/VUINTER/GAPCON原型+映射+选型表+mermaid）; `PH_Cont_*`, `RT_Contact_*`; **MD_Cont_Stp_Ctl_Algo P1补全**; **Pillar §4.1**.  
- **LoadBC**: `LoadBC_L3L4L5_four_type_synthesis.md` **§3.5**（扁平四型+`PH_Ldbc_Stp_Ctl_Algo` P0补全+ULOAD §3.5.7+DLOAD §3.5.8 ABI镜像对偶+mermaid）; `PH_LoadBC_*`, `RT_LoadBC_*`; **Pillar §4.1**.  
- **Output**: `Output_L3L4L5_four_type_synthesis.md` **§3.5**（双State+Frame/Buffer/TriggerCtx辅+PTR引用L3+UVARM/VUVARM/URDFIL/UHISTR/USDFLD ABI镜像对偶+Field/History双轨选型表+mermaid）; `RT_Out_*`, `PH_Out_Brg`; **Pillar §4.1**.  
- **WriteBack**: `WriteBack_L3L4L5_four_type_synthesis.md` **§3.5**（双State+全POINTER+白名单守卫+检查点+审计+UEXTERNALDB/STATEV/PUTVRM三级写回ABI镜像+LOP生命周期映射+mermaid）; `RT_WB_*`, `MD_WB_Brg`; **Pillar §4.1**.
- **Analysis**: `Analysis_L3L4L5_four_type_synthesis.md` **§3.5**（四子域Step/Amplitude/Solver/Coupling分节+三步状态机+PTR引用L3+LOP生命周期对偶+防双写约束+mermaid）; `RT_StepDriver_*`, `RT_Solv_*`, `MD_Step_*`, `MD_Amp_*`, `MD_Solv_*`, `MD_Cpl_*`; **Pillar §4.1**.
- **Procedure Algorithm** (全景合订): `Procedure_Algorithm_L3L4L5_synthesis.md`（三维度×八域过程算法全景：空间/时间/动作维度+四大管线S-Pipeline/Uzawa/K·x=f/WB_Guard+跨域编排+缺口优先级+设计原则）。
- **Procedure Algorithm** (域级专域): `Material_Procedure_Algorithm.md`（S-Pipeline+12族级Algo+constitutive PTR）、`Element_Procedure_Algorithm.md`（integrator PTR+Ke/Re管线）、`LoadBC_Procedure_Algorithm.md`（PH_Ldbc_Stp_Ctl_Algo P0补全+Assemble→Apply双管线）、`Contact_Procedure_Algorithm.md`（MD_Cont_Stp_Ctl_Algo P1补全+Uzawa Loop+search_strategy PTR+3辅Algo）、`Output_Procedure_Algorithm.md`（Frame→Buffer→Writer管线）、`WriteBack_Procedure_Algorithm.md`（WB_Guard+11域分派+审计）、`Analysis_Procedure_Algorithm.md`（三步状态机+K·x=f管线）、`Section_Procedure_Algorithm.md`（正交维最简+M-S-E桥接）。
- **Pillar**: `Pillar_L3L4L5_CrossLayer_Design_Template.md` **§4.1**.

**Version**: v1.4 — Section P3 缺口补全: `RT_Sec_Stp_Ctl_Algo`(步级M-S-E兼容/积分规则/查询控制); 十八文档全覆盖 (2026-05-04).

