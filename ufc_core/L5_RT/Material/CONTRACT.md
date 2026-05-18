# Material 调度域合同卡 (L5_RT/Material)

**Layer**: L5_RT（运行时层）  
**Domain**: Material（材料路由表 + 调度入口，**不**承载本构积分公式）  
**Version**: v1.0  
**Updated**: 2026-05-14  
**Status**: ACTIVE  

**关联文档**：

- L4 本构与槽真源：[`L4_PH/Material/CONTRACT.md`](../../L4_PH/Material/CONTRACT.md)  
- 跨层共享 TYPE（**`RT_Mat_Dispatch_Ctx` / `RT_Mat_Dispatch_Table`** 真源模块）：[`L1_IF/Base/IF_Mat_Dispatch_Def.f90`](../../L1_IF/Base/IF_Mat_Dispatch_Def.f90)  
- L5 薄封装与常量别名：[`RT_Mat_Def.f90`](./RT_Mat_Def.f90)  
- 装配金线（消费应力/刚度）：[`L5_RT/Assembly/CONTRACT.md`](../Assembly/CONTRACT.md)  
- 数据规范（RT 六参、正交）：[`docs/02_Developer_Guide/UFC_数据结构与结构体规范.md`](../../../docs/02_Developer_Guide/UFC_数据结构与结构体规范.md)  
- **主轴与波次**：[`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_二元结构主轴与波次路线图.md)  
- **域级验收 / 里程碑**：[`06_域级落地验收表_CodeReview与里程碑.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/06_域级落地验收表_CodeReview与里程碑.md) · [`07_L3L4L5_二元结构合同完备里程碑.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/07_L3L4L5_二元结构合同完备里程碑.md)  

---

## 一、职责边界

### 核心职责

- **定位**：在 **L4 `PH_Mat_Domain%slot_pool`** 已 Populate 的前提下，维护 **`RT_Mat_Dispatch_Table`**，并在单元/装配热路径中提供 **`RT_Mat_Dispatch_Stress` / `RT_Mat_Dispatch_Tangent`** 等 **纯路由** 入口（**`RT_Mat_Core`**：校验 **`mat_pt_idx`** / **`mat_type`**，在传入 **`material_dom`** 时委托 **`PH_Mat_Execute_Flow` / `PH_Mat_Execute_Tangent_Flow`**）。  
- **职责**：**`RT_Mat_Brg_BuildTable_FromMaterial`** — 从已激活槽扫描 **`PH_Mat_Desc_Effective_Model`**、**`desc%cfg%matId`**，写入路由表（**`RT_Mat_Brg.f90`** 头注释金线：`L3 Desc → L4 slot_pool → L5 table`，L5 **不**保存材料 Desc 或 IP State）。  
- **边界**：**不**实现具体 **`D`**、塑性返回等；族向 **`RT_Mat_*_Core`** 文件为 L5 侧 **def/kernel 辅助**，本构数值仍以 **L4 `PH_Mat_*`** 为权威。  
- **依赖**：L1 **`IF_Mat_Dispatch_Def`**；L4 **`PH_Mat_Domain`**、**`PH_Mat_Core`**（**`PH_Mat_Desc_Effective_Model`**、**`PH_Mat_Execute_*`**）。  

### 禁止事项

- **禁止**在 L5 热路径保存 **L3 `MD_Mat_Desc` 富拷贝** 作为 Writable SSOT（与 L4 合同、`GOVERNANCE` 一致）。  
- **禁止**绕过 **`RT_Mat_Dispatch_Table`** / **`RT_Mat_Dispatch_Ctx`** 在未备案路径上发明第二套路由状态机。  

---

## 二、模块与 TYPE 锚点（实现一致）

| 模块 / 文件 | 角色 |
|-------------|------|
| **`IF_Mat_Dispatch_Def`** | **`RT_Mat_Dispatch_Ctx`**（`mat_type`、`mat_id`、`mat_pt_idx`、`is_user_sub`、`route_status`）、**`RT_Mat_Dispatch_Table`** / **`RT_Mat_Route_Entry`**、**`IF_MAT_TABLE_MAX`**（默认 **128** 槽位上限） |
| **`RT_Mat_Def`** | 对 IF 类型的 **PUBLIC 再导出**；**`RT_MAT_*`** 与 **`IF_MAT_*`** 别名；**`RT_Mat_Algo`**（步级调度控制，**非**本构参数） |
| **`RT_Mat_Core`** | **`RT_Mat_Init_Table` / `Finalize_Table`**；**`RT_Mat_Register_Route`**；**`RT_Mat_Get_Route`**；**`RT_Mat_Dispatch_Stress` / `Dispatch_Tangent`**（可选 **`PH_Mat_Domain`** 目标）；状态缓存/检查点辅助过程 |
| **`RT_Mat_Brg`** | **`RT_Mat_Brg_BuildTable`**（批量注册）；**`RT_Mat_Brg_BuildTable_FromMaterial`**；**`RT_Mat_Brg_MakeCtx`**；**`RT_Mat_Brg_WriteBackHook`**（写回前 NaN 守卫等） |
| **`RT_Mat_*_Def` / `RT_Mat_*_Core`** | 各族 L5 侧 **def/core** 片段（与 L4 族内核配套，非本卡逐文件展开） |

---

## 三、层域坐标（A7）

| 项 | 值 |
|----|-----|
| **Layer** | `L5_RT` |
| **Domain 路径** | `ufc_core/L5_RT/Material` |
| **功能集** | 路由表、**`RT_Mat_Dispatch_*`**、Bridge 表构建与 **WriteBackHook** |

---

## 四、域际关系（A6 · 子表）

| 序号 | 关联域 | 相对本域 | 契约类型 | 主要接触面 | 备注 |
|------|--------|----------|----------|------------|------|
| R1 | `L4_PH/Material` | 上游 | **T** + **B** | **`PH_Mat_Domain`**、**`PH_L4_Populate_Material`** 之后槽 | 表项 **`mat_pt_idx`** 指向 **`slot_pool`** |
| R2 | `L4_PH/Element` | 上游/协同 | **S** + **U** | **`PH_Elem_MaterialRoute`**：`RT_Mat_Dispatch_Ctx` + **`RT_Mat_Dispatch_Stress`** | 单元组装 **`rt_ctx`** |
| R3 | `L5_RT/Assembly` | 下游 | **U** | 全局 **`K`/`F`** 装配消费单元输出 | 见 Assembly 合同金线 |
| R4 | `L5_RT/WriteBack` | 下游/钩子 | **B** | **`RT_Mat_Brg_WriteBackHook`** | 收敛后写回前过滤 |

---

## 五、内外边界与 Bridge（A8）

- **对外 API**：以 **`RT_Mat_Core` / `RT_Mat_Brg` / `RT_Mat_Def`** 的 **`PUBLIC`** 过程与 TYPE 为准；跨层仅经 **`PH_Mat_Domain`** + **`IF_Mat_Dispatch_Def`** 闭包。  
- **与 L4 对齐**：**`entries%mat_type`** 与 **`PH_Mat_Desc_Effective_Model(desc)`** 一致（**`RT_Mat_Core` / `RT_Mat_Brg`** 头注释 **W1**）。  

---

## 六、RT 六参与 SIO（A9 / A5）

- **当前事实**：**`RT_Mat_Dispatch_Stress(ctx, status, material_dom)`**（及 Tangent 对称）以 **`RT_Mat_Dispatch_Ctx`** + **`ErrorStatusType`** 为 SIO 主面；**未**在形参表展开 **`RT_Com_Base_Ctx`**。单元路径在调用前填充 **`ctx%mat_type` / `mat_id` / `mat_pt_idx`**。  
- **演进**：若材料入口升级为标准 **六参 `_Proc`**，须同步修订 **本卡**、**`IF_Mat_Dispatch_Def`** 与调用方（**`PH_Elem_MaterialRoute`** / **`RT_Asm_*`**），并与 **`UFC_数据结构与结构体规范.md`** §4.4–§5.4 对齐。  

---

## 七、横切与可观测（A10）

- **`route_status`**：取 **`IF_MAT_ROUTE_*` / `RT_MAT_ROUTE_*`**，与 **`status%status_code`** 联合用于诊断。  
- **因果元数据**：仅作 trace；**不**引入「第五链」合同用语。  

---

## 八、四链 + 因果（A4）

| 链 | 内容 |
|----|------|
| **理论** | 无独立弱式；本域不在连续介质意义上「积分本构」。 |
| **逻辑** | **`mat_id` / `mat_type` / `mat_pt_idx`** → 表查找 → **`PH_Mat_Execute_*`** 或校验失败路径。 |
| **计算** | 边界检查、**`route_status`** 赋值；有 **`material_dom`** 时调用 L4 **`PH_Mat_Execute_Flow`**。 |
| **数据** | **`RT_Mat_Dispatch_Table%entries`**；**`RT_Mat_Dispatch_Ctx`** 在调用间传递。 |

**因果说明**：**(trigger)** 单元 IP 或装配子步请求应力更新；**(upstream)** **`RT_Mat_Brg_BuildTable_FromMaterial`**（或等价注册）已根据 L4 激活槽填充表；**(downstream)** L4 更新 **`PH_Mat_State`**，再回到单元 **Ke/Fe** 或残差管道。  

---

## 九、验证与 Harness（A11）

PR 须声明已执行（与 CI 对齐，仓库根为含 **`UFC/`** 的 monorepo 根时路径按 CI 原样）：

```text
python UFC/ufc_harness/run_harness.py doc-structure
python UFC/ufc_harness/run_harness.py plan-checks
python UFC/ufc_harness/run_harness.py guardian
```

**CI（`.github/workflows/ufc-ci.yml`）摘要**（材料相关变更建议本地复现）：

```text
python scripts/ci/check_naming.py UFC/ufc_core --report naming_report.json
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON UFC/ufc_core
cmake --build build -j 2
cd build && ctest --output-on-failure -j 2
```

材料调度 smoke（CI 高优先级子集示例）：

```text
cd build && ctest -R "UMAT_ElasticIso|UMAT_PlasticJ2" --output-on-failure -V
```

可选：`python UFC/ufc_harness/uhc.py code naming_checker`、`python UFC/tools/scan_verbose_identifiers.py`。  

---

## 十、Phase4 位置

与 **Phase4** 材料竖切、**Populate → slot → L5 table → dispatch** 同序；真源：[`Phase4_核心闭环链_验收追踪.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/Phase4_核心闭环链_验收追踪.md)。  

---

*维护：本卡仅描述 **L5_RT/Material** 路由子系统；L4 本构细节变更须先更新 [`L4_PH/Material/CONTRACT.md`](../../L4_PH/Material/CONTRACT.md)。*
