# Material 域合同卡 (L4_PH/Material)

**Layer**: L4_PH（物理组件层）  
**Domain**: Material（本构点计算与材料槽）  
**Version**: v1.1  
**Updated**: 2026-05-14  
**Status**: ACTIVE  

**关联文档**：

- L3 合同卡（Desc 真源）：[`L3_MD/Material/CONTRACT.md`](../../L3_MD/Material/CONTRACT.md)  
- L4 四型设计：[`DESIGN_Mat_FourTypes.md`](./DESIGN_Mat_FourTypes.md)  
- 治理台账：[`GOVERNANCE.md`](./GOVERNANCE.md)  
- 本构内核叙事：[`DESIGN_Mat_ConstitutiveKernels.md`](./DESIGN_Mat_ConstitutiveKernels.md)  
- 形式对齐自检（P2 材料侧）：[`UFC/docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md`](../../../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md)  
- UMAT 讨论合订：[`UFC/REPORTS/Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`](../../../REPORTS/Material_L3L4L5_four_type_UMAT_discussion_synthesis.md)  
- 材料过程算法（根 stub）：[`Material_Procedure_Algorithm.md`](../../../REPORTS/Material_Procedure_Algorithm.md)  
- **主轴与波次**：[`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md)  
- **域级验收 / 里程碑**：[`docs/05_Project_Planning/PPLAN/11_闭环落地专项/06_域级落地验收表_CodeReview与里程碑.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/06_域级落地验收表_CodeReview与里程碑.md) · [`07_L3L4L5_二元结构合同完备里程碑.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/07_L3L4L5_二元结构合同完备里程碑.md)  

---

## 一、职责边界

### 核心职责

- **定位**：UFC **L4_PH/Material** — 积分点本构更新、切线与应力输出、材料槽（slot）生命周期内的 **步内热路径真源**（与 L3 `MD_Mat_Desc` 正交：L3 持 Desc，L4 持运行期 slot）。  
- **职责**：按 **`cfg%matModel`** / 族枚举（`PH_MAT_*`）路由到 `PH_Mat_*` 内核；维护 **`PH_Mat_Domain%slot_pool`** 与 **`PH_Mat_*_Idx`** API；与 L5 **`RT_Mat_Dispatch_*`** 及单元侧 **`PH_Elem_MaterialRoute`**（`PH_Elem_*_Material_Update_Routed`）对齐。  
- **边界**：不持有网格拓扑、不做全局 CSR 组装；**不**在 IP 热路径内遍历 L3 材料库 — 经 **`PH_L4_Populate_Material`** 写入 slot 后只读消费（见 `GOVERNANCE.md` §2）。  
- **依赖**：L3 `MD_Mat_*`（Populate 源）、L1 `IF_Prec` / `IF_Err_*`；L5 侧材料表构建见 **`RT_Mat_*`**（本卡互链，非本域实现）。  

### 禁止事项

- **禁止**在热路径新增对 L3 `MD_MatRT_Brg` / 巨型网格结构的未备案 `USE`（迁移矩阵见 `GOVERNANCE.md` §6–§7）。  
- **禁止**把 L3 富 `MD_Mat_Desc` 缓存进 slot 作为 Writable SSOT 的「第二主源」— Populate 切片写入后，步内以 **L4 slot** 为准。  
- **禁止**在 **`PH_Mat_Domain_Core`** 内堆叠具体本构算法 — 算法在 `Elas/`、`Plast/`、`Geo/` 等子目录；Domain 模块只管容器与 API。  

---

## 二、文件与模块锚点（摘要）

> 完整磁盘真源与冻结规则见 [`GOVERNANCE.md`](./GOVERNANCE.md) §1–§2。Registry：`docs/03_Domain_Pillars/DomainProcedureRegistry/design/L4_PH/Material/manifest.json`。

| 分组 | 代表文件 | 角色 |
|------|-----------|------|
| Domain / slot | `PH_Mat_Domain_Core.f90` | **`PH_Mat_Domain`**、**`PH_Mat_Slot`** 数组 **`slot_pool`**、**`PH_Mat_Ctx` / `PH_Mat_State`**、`PH_Mat_*_Idx` |
| Populate | **`MODULE PH_L4_Populate`**，`PH_L4_Populate.f90`：`PH_L4_Populate_Material`（L3 registry → L4 slot 冷路径） | 经 **`MD_Mat_Registry_Access_Desc`** 取 L3 `MD_Mat_Desc` → **`PH_Mat_AllocSlot_Idx`** → 填 **`desc%cfg`** / **`desc%props`** → **`PH_L4_Alloc_State_ForFamily`** |
| Registry / dispatch | `PH_Mat_Reg.f90`、`PH_Mat_Dsp.f90`（族分派守卫；过程名仍 `PH_Mat_Dispatch_*`）、`Dispatch/PH_MatEval*.f90` | 兼容注册与求值门面 |
| Contract 子树 | `Contract/PH_Mat_*.f90` | 本构点状态、props、UMAT 上下文与桥 |
| 族内核 | `Elas/`、`Plast/`、`Geo/`、`Damage/`、`Composite/`、`Hyper/`、`Creep/`、`Viscoelas/`、`Thermal/`、`Acoustic/` 等 | 具体本构积分 |

### Legacy `PH_MatEval` aggregate（staging · wave5-mateval-arg）

> **门面**：`Dispatch/PH_MatEval.f90` 仅 re-export + `PH_Mat_UMATEnsureWorkspace`；**实现真源**见下表。  
> **C2**：按族迁出 **完成**（PR-A Elas/Plast + PR-B 其余族）。

| Eval 入口 | Arg TYPE | C2 真源 | 备注 |
|-----------|----------|---------|------|
| `PH_Mat_ElasticIsotropic_Eval` | `PH_Mat_ElasticIsotropic_Eval_Arg` | `Elas/PH_Mat_Elas_PointEval.f90` | Hooke D·ε |
| `PH_Mat_ElasticOrthotropic_Eval` | `PH_Mat_ElasticOrthotropic_Eval_Arg` | `Elas/PH_Mat_Elas_PointEval.f90` | ortho: `strain`/`sigma`/`D_matrix` |
| `PH_Mat_PlasticVonMises_Eval` | `PH_Mat_PlasticVonMises_Eval_Arg` | `Plast/PH_Mat_Plast_PointEval.f90` | J2 point |
| `PH_Mat_PlasticHill_Eval` | `PH_Mat_PlasticHill_Eval_Arg` | `Plast/PH_Mat_Plast_PointEval.f90` | Hill48 |
| `PH_Mat_HyperelasticNeoHookean_Eval` | `PH_Mat_HyperelasticNeoHookean_Eval_Arg` | `Hyper/PH_Mat_Hyper_PointEval.f90` | stub |
| `PH_Mat_HyperelasticMooneyRivlin_Eval` | `PH_Mat_HyperelasticMooneyRivlin_Eval_Arg` | `Hyper/PH_Mat_Hyper_PointEval.f90` | stub |
| `PH_Mat_DamageDuctile_Eval` | `PH_Mat_DamageDuctile_Eval_Arg` | `Damage/PH_Mat_Damage_PointEval.f90` | (1-D) degrade |
| `PH_Mat_DamageBrittle_Eval` | `PH_Mat_DamageBrittle_Eval_Arg` | `Damage/PH_Mat_Damage_PointEval.f90` | → ductile |
| `PH_Mat_CreepNorton_Eval` | `PH_Mat_CreepNorton_Eval_Arg` | `Creep/PH_Mat_Creep_PointEval.f90` | Norton |
| `PH_Mat_ViscoelasticProny_Eval` | `PH_Mat_ViscoelasticProny_Eval_Arg` | `Viscoelas/PH_Mat_Visco_PointEval.f90` | Prony |
| `PH_Mat_ViscoelasticMaxwell_Eval` | `PH_Mat_ViscoelasticMaxwell_Eval_Arg` | `Viscoelas/PH_Mat_Visco_PointEval.f90` | Maxwell |
| `PH_Mat_ViscoelasticKelvinVoigt_Eval` | `PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg` | `Viscoelas/PH_Mat_Visco_PointEval.f90` | K-V |
| `PH_Mat_CompositeLaminate_Eval` | `PH_Mat_CompositeLaminate_Eval_Arg` | `Composite/PH_Mat_Comp_PointEval.f90` | laminate avg |
| `PH_Mat_CompositeFiberReinforced_Eval` | `PH_Mat_CompositeFiberReinforced_Eval_Arg` | `Composite/PH_Mat_Comp_PointEval.f90` | ROM → iso |
| `PH_Mat_UMATEnsureWorkspace` | `PH_Mat_UMATEnsureWorkspace_Arg` | `Dispatch/PH_MatEval.f90` | workspace stub |

### Crystal UMAT（mat_id 266 · `PH_Mat_Plast_Crystal_Core`）

> **W1b**：**1-slip Schmid**（`nprops < 19`）— \(\tau = P:\sigma\)，率无关返回。  
> **W2a**：**N=2 双滑移 + 2×2 潜硬化**（`nprops ≥ 19`）— Gauss–Seidel 耦合返回；一致切线 W2a 为 **弹性 \(D\)**（见 plan W2）。  
> **W1a iso-surrogate**（#12）：**DEPRECATED**。

| 模式 | 触发 | `nprops_min` | `nstatev_min` |
|------|------|--------------|---------------|
| W1b | `nprops < 19` | 4 | 7 |
| W2a | `nprops ≥ 19` | 19 | 8 |

| 项 | 约定 |
|----|------|
| 入口 | `UF_CrystalPlasticity_UMAT(UF_CrystalPlasticity_UMAT_Arg)` |
| PLM | `PH_MatPLMEval` CASE `266`（Arg 打包，wave5 #6） |
| `props(1:4)` | `E`, `nu`, `tau_c0`, `H11` |
| `props(5:7)` / `(8:10)` | 系1 `s`, `m`（W1b：`nprops<9` 默认 `s=[0,0,1]`, `m=[1,0,0]`） |
| `props(11:13)` / `(14:16)` | 系2 `s`, `m`（仅 W2a） |
| `props(17:19)` | `H12`, `H21`, `H22`（仅 W2a） |
| W1b `statev` | `(1)=gamma`, `(2:7)=eps_p` |
| W2a `statev` | `(1:2)=gamma^{(1:2)}`, `(3:8)=eps_p` |
| 参考算例 | **W2-REF-01** — [`plan/changes/p1-material-crystal-w2-multislip/design.md`](../../../plan/changes/p1-material-crystal-w2-multislip/design.md) §6 |
| 错误 | `nprops`/`nstatev` 不足或 `s`/`m` 零长 → `IF_STATUS_INVALID` |

---

## 三、层域坐标（A7）

| 项 | 值 |
|----|-----|
| **Layer** | `L4_PH` |
| **Domain 路径** | `ufc_core/L4_PH/Material` |
| **功能集 / 子域** | 本构 kernel；`Contract/`；`Dispatch/`；各向族子目录（见上表） |

---

## 四、域际关系（A6 · 子表）

| 序号 | 关联域（层/域路径） | 相对本域（上游 / 下游） | 契约类型 | 主要接触面（TYPE / MODULE / 合同小节） | 备注 |
|------|---------------------|-------------------------|----------|------------------------------------------|------|
| R1 | `L3_MD/Material` | 上游 | **T** + **U** | `MD_Mat_Desc`；**`MD_Mat_Registry_Access_Desc`**；**`PH_L4_Populate_Material`** | Desc 真源在 L3；Populate 仅冷路径读 registry |
| R2 | `L4_PH/Element` | 下游 | **T** + **U** | **`mat_pt_idx`**；直接读 **`PH_Mat_Domain%slot_pool(mat_pt_idx)`** 或 SIO **`PH_Mat_GetCtx_Idx`** / **`PH_Mat_GetState_Idx`**；族 **`PH_Elem_*_Material_Update_Routed`** | 热路径经 **`PH_Elem_MaterialRoute`** 组装 **`RT_Mat_Dispatch_Ctx`** 后调 **`RT_Mat_Dispatch_Stress`** |
| R3 | `L5_RT/Material` | 下游 | **B** + **S** | [`L5_RT/Material/CONTRACT.md`](../../L5_RT/Material/CONTRACT.md)：`RT_Mat_Brg_BuildTable_FromMaterial`、`RT_Mat_Dispatch_Stress` → **`PH_Mat_Execute_Flow`** | L5 仅存路由元数据（**`RT_Mat_Dispatch_Table`**），不复制 L4 Desc/IP State |
| R4 | `L4_PH/Bridge` | 上游 / 工具 | **B** | `PH_Brg_*` 冷路径；**禁止**热路径绕 slot | 见 `L4_PH/Bridge/CONTRACT.md` UMAT 行互链本卡 |

---

## 五、内外边界与 Bridge（A8）

- **对内**：四型与字段语义以 [`DESIGN_Mat_FourTypes.md`](./DESIGN_Mat_FourTypes.md) 与 **`PH_Mat_Domain_Core`** / **`PH_Mat_Def`** 为准；**对外**公开 API 与实现同名同版本。  
- **跨层**：仅经 **Populate**、**`RT_Mat_Dispatch_Ctx`**、**单元 Material route** 与已列 Bridge；不新增未在 A6 子表备案的越层 `USE`。  
- **UMAT / 用户子程序**：ABI 与适配模块归属 `Contract/`、`Material/USR/` 等；与 **`L4_PH/Bridge/CONTRACT.md`**「UMAT ABI」行交叉索引。  

---

## 六、RT 六参（A9）

- **本域立场**：L4_PH/Material **不**定义 L5 `*_Proc` 六参签名的权威表；材料路由当前以 **`RT_Mat_Dispatch_Ctx`**（定义于 **`IF_Mat_Dispatch_Def`**，L1 共享）+ 可选 **`PH_Mat_Domain`** 实参为主；与 **`RT_Com_Base_Ctx`** 正交及未来六参 **`_Proc` 收口** 以 **[`L5_RT/Material/CONTRACT.md`](../../L5_RT/Material/CONTRACT.md)** 与 **`docs/02_Developer_Guide/UFC_数据结构与结构体规范.md`** §4.4、§5.4 为裁决。  
- **本域热路径**：以 **`PH_Mat_Domain%slot_pool(mat_pt_idx)%ctx` / `%state`**（应力与切线在 **`state%comp%stress`**、**`state%comp%C_tan`**；内变量在 **`state%evo%stateVars*`**）为积分点真源；调用方负责合法 **`mat_pt_idx`**（Populate 分配槽位 + Section/Element map）。  

---

## 七、横切契约与可观测（A10）

- **版本 / 稳定字段**：slot 内 `props`/`statev` 布局变更须与 `GOVERNANCE.md`「Slot contract hardening」计划及数据契约技能对齐；重大变更走合同版本 bump。  
- **可观测**：错误与状态经 **`IF_Err_*` / `ErrorStatusType`** 返回；**因果**信息仅作 trace/diag 元数据，`chain_hint` 仍落四链闭集（见 `fem-kernel-observability` 与数据规范 §5.6）。  

---

### SIO / `*_Arg`（本域偏好，A5）

与 **Principle #14**、**[`AGENTS.md`](../../../AGENTS.md)** 仓库规则 §5 一致：**不**强制本域每个过程都包 `*_Arg`。**避免**仅承载 `status` 的薄 Arg。**保留** 当一次交互有 **≥2** 个协同演化字段或 Harness/生成器消费时。层间硬边界仍以 L5 **`_Proc`** 与 Harness SIO 为准。

---

## 八、算法细节与四链 + 因果（A4）

| 链 | 内容（与实现一致，可审查） |
|----|----------------------------|
| **理论** | 各向族本构：弹性 Hooke、塑性返回映射、损伤、蠕变/粘弹、超弹势能、多孔两相等；输出 **Cauchy/Kirchhoff** 与算法一致切线（Voigt 约定与族内核一致）。 |
| **逻辑** | **`desc%cfg%matModel`**（族 **`PH_MAT_*`**）/ **`PH_Mat_Desc_Effective_Model`** → **`PH_Mat_Reg`** / PLM dispatch → 族 **`PH_Mat_*_Core`**；UMAT 走 `Contract` + adapter；**禁止** IP 内未缓存 L3 全库扫描。 |
| **计算** | 积分点级：`stress`、`ddsdde`（或等效切线）、内变量更新；热路径 **零分配** 策略见 Domain Ctx 设计。 |
| **数据** | **`PH_Mat_Domain%slot_pool(:)`**（**`PH_Mat_Slot`**）：**`desc%cfg`**（`matId`、`matModel`）、**`desc%props`**；**`state%comp`** / **`state%evo`**；**`ctx`** 嵌套辅 TYPE。与 Element 侧 **`mat_pt_idx`** 对齐；Populate 与步内字段分界见 `DESIGN_Mat_FourTypes.md`。 |

**因果说明（trace 级）**：**(trigger)** 单元 IP 经 **`PH_Elem_MaterialRoute`** 调用 **`RT_Mat_Dispatch_Stress`**（传入 **`RT_Mat_Dispatch_Ctx`** 与 **`PH_Mat_Domain`**），或直接读 slot 的 legacy/测试路径；**(upstream)** L3 **`MD_Mat_Desc`** 经 **`MD_Mat_Registry_Access_Desc`** + **`PH_L4_Populate_Material`** 写入 **`slot_pool(idx)`** 并置 **`active`**；**(downstream)** **`PH_Mat_Execute_Flow`** 更新 **`PH_Mat_State`**，应力/切线回到单元或 L5 装配。  

---

## 九、验证与 Harness（A11）

合入本域或改 slot/路由时，PR 描述须声明已执行（至少）：

```text
python ufc_harness/run_harness.py doc-structure
python ufc_harness/run_harness.py plan-checks
python ufc_harness/run_harness.py guardian
```

可选（命名 / 冗长卫生线，与里程碑 C 轴互链时写入 PR）：

```text
python ufc_harness/uhc.py code naming_checker
python tools/scan_verbose_identifiers.py
```

构建与单测与 **`.github/workflows/ufc-ci.yml`** 对齐时（仓库根含 `UFC/` 目录）：`cmake -B build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON UFC/ufc_core` → `cmake --build build -j 2` → `cd build; ctest --output-on-failure -j 2`；命名门禁见同 workflow **`naming-check`** job（`python scripts/ci/check_naming.py UFC/ufc_core …`）。  

---

## 十、Phase4 与闭环链位置

本域为 **材料竖切** 与 **Populate → slot → dispatch** 金线的 **L4 落点**；与 **Phase4** 表中 **Material / Element / Assembly** 行互链，顺序真源：[`Phase4_核心闭环链_验收追踪.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/Phase4_核心闭环链_验收追踪.md)。桥接收敛：[`Phase4_L3L4桥接_收敛说明.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/Phase4_L3L4桥接_收敛说明.md)。  

---

*维护：若新增带 `CONTRACT.md` 的子域桶，须同步 `07` 里程碑表；本卡条款与 `GOVERNANCE.md` 冲突时以 **先修订本卡 + GOVERNANCE** 再改代码为原则。*
