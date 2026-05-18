## Amplitude 域级合同卡（L3_MD）

- **层级**：L3_MD  
- **域名**：Amplitude（幅值 / 时间缩放因子 A(t)）  
- **缩写**：`MD_Amp_*`（建模与 API）；`MD_Amp_Slot_Desc` / `MD_Amp_Slot_Ctx`（**槽侧**建模容器，与域 MD_Amp_Domain 并行）  
- **职责**：维护载荷/边界等所用幅值曲线的 **建模真相**；提供 **纯数据 + 有界标量求值** A(t)（无数值 PDE、无全局方程求解）。L3 幅值模块 **禁止** `USE` L4_PH / L5_RT；调用方向为 L4/L5 → L3（L5 编排可 `USE` L3 与 `RT_Amp`）。
- **非职责**：不编排分析步；不解方程；谱/PSD/致动器等专用类型可占位或经别域扩展。

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、`**[AGENTS.md](../../../../../AGENTS.md)`** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 `**status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 四型（Desc / State / Algo / Ctx；`MD_Amp_Eval_*` 为 UAMP 侧）


| 四型        | 主要载体                                               | 说明                                                                                                                                  |
| --------- | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Desc**  | `MD_Amp_Desc`、`MD_Amp_Slot_Desc`、`MD_Amp_Ext_Desc` | 含 `tabular_extrapolate`（与 UF 对齐）；**原生** `smooth_*` / `ramp_t_end`（`AMP_SMOOTH`/`AMP_RAMP`）；调制 `mod_*`；tabular 段内 Hermite 用 `smooth` |
| **State** | `MD_Amp_State`                                     | `currentValue` / WriteBack 索引                                                                                                       |
| **Algo**  | `MD_Amp_Algo`、`MD_Amp_Eval_Algo`                   | 域内插值策略；`**MD_Amp_Eval_Algo`** 仅 **UAMP** 结构化入参                                                                                      |
| **Ctx**   | `MD_Amp_Eval_Ctx`                                  | UAMP：实例名、坐标、`step_idx` / `incr_idx`                                                                                                 |


---

### 模块与依赖（单向）


| 文件               | 作用                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MD_Amp_Def.f90` | `**MD_Amp_Def`**：四型与 `MD_Amp_Domain`、`**IF_Base_DP**` 注册 `**MD_Amp_Desc` 24 字段**；`**AMP_*` / `INTERP_*`**；**SIO `MD_Amp_*_Arg` + `MD_Amp_Apply_*_Arg`**（Principle #14）；`**MD_AmpShared_***`（TABULAR / SMOOTH / RAMP / MODULATED 标量内核，原独立模块已并入）；**不** `USE` `MD_Amp_Mgr`；`**MD_Amp_Idx`** 可仅 `USE` 本模块                                                                                                                                               |
| `MD_Amp_UF.f90`  | `**MD_Amp_UF**`：`**MD_Amp_Slot_Desc` / `MD_Amp_Slot_Ctx**`、`**MD_Amp_Ext_Desc**` 与 `**MD_Amp_FromExt***`（原 `**MD_Amplitude_Brg**` 并入）、`**ampdb_*` / TBP**（含 `**evaluate`**）、**UAMP** `**MD_Amp_Eval_*`**；`**USE MD_Amp_Def**`（**不** `USE` `MD_Amp_Mgr`）                                                                                                                                                                                             |
| `MD_Amp_Mgr.f90` | `**MD_Amp_Mgr`**：`**Amp_GetFactor**`、`**MD_Amp_GetFactor**`（按名）、`**amp_md_desc_dealloc_arrays**`、`**MD_Amp_Slot_To_MD_Desc**`、`**MD_Amp_SyncFromLegacy**` / `**MD_Amp_ResolveName**`（原 `**MD_AmplitudeSync_Algo**` 并入）；`**USE MD_Amp_UF**` / `**MD_Amp_Def**` / `**MD_L3Layer**` / `**MD_ModelLib**` 并 **再导出** `**MD_Amp_Slot_Desc`**、`**MD_Amp_Slot_Ctx**`、`**MD_Amp_MATH_PI**`、`**MD_Amp_Eval_***`、`***_Arg` / `Apply_***`；**不**依赖 `g_ufc_global` |
| `MD_Amp_Idx.f90` | `**MD_Amp_Idx`**：依赖 `g_ufc_global` 的按索引 `GetAmplitude` / `EvalAtTime` / `WriteBack`；数据路径为 `**g_ufc_global%md_layer%amplitude**`（与 `PH_BrgL3` 一致）                                                                                                                                                                                                                                                                                                    |


**L5 推荐求值入口**（编排侧，非 L3 模块）：`[RT_Amp.f90](../../../L5_RT/RT_Amp.f90)` 中 `**RT_Amp_FactorAt`** — 在 `g_ufc_global%IsReady()` 时调用 `**Amp_GetFactor(..., md_layer%amplitude)**`（域优先 + UF 回退，与上式同一实现）；未 Ready 时仅三参 `**Amp_GetFactor**`。

**依赖**：`IF_Prec_Core`、`IF_Err_Brg`；`**MD_Amp_Def` → `IF_Base_DP`**（`**MD_AmpShared_***` 与本模块同源）；`**MD_Amp_UF` → `MD_Amp_Def**`；`**MD_Amp_Mgr` → `MD_Amp_UF` + `MD_Amp_Def` + `MD_L3Layer` + `MD_ModelLib**`（与实现一致）。

---

### Eval 总线与 Harness（刻意不设 `Eval_Apply`）

- **解析型求值**（TABULAR / SMOOTH / RAMP / …）的调度真源仍只有两处：`**MD_Amp_Slot_Desc%evaluate`**（legacy 槽）与 `**MD_Amp_Domain%EvalAtTime**`（Populate 后域真源）；其中 **TABULAR / SMOOTH / RAMP / MODULATED** 的标量公式由 `**MD_Amp_Def`** 内 `**MD_AmpShared_***` 单路径实现。Harness 持有 `MD_Amp_Domain` 时，用 SIO `**MD_Amp_Apply_EvalAtTime_Arg**`（在 `**MD_Amp_Def**`）对接 TBP 即可。
- `**MD_Amp_Eval_Desc` / `Algo` / `Ctx` / `State` 与 `MD_Amp_Eval_In` / `Out**`：仅服务于 **UAMP 结构化回调**（`**Amp_User_IF_Structured`**）；**不是**第二条解析流水线，**不**增加公共过程 `**MD_Amp_Eval_Apply(in,out)`**，以免与上两处重复实现、过度包装。
- **需要统一观测/桩** 时：在 Harness 或 L5 编排层包一层私有过程即可，**不必**进 `MD_Amp_Mgr` 公共 API。

---

### 算法与类型对照（Eval）


| `amp_type`                            | `MD_Amp_Slot_Desc%evaluate`                                                                  | `MD_Amp_Domain%EvalAtTime`                                                                             |
| ------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| TABULAR                               | `**MD_AmpShared_TabularEval`**（UF 槽 **无** 段内 Hermite，`smooth=.FALSE.`）；`tabular_extrapolate` | 同上函数；域可读 `**MD_Amp_Desc%smooth`** 启用段内 Hermite；**退化时间对** `t_i≈t_{i+1}` 时 **不除零**，段内值取 **左端 `vd(i)`**   |
| SMOOTH                                | `**MD_AmpShared_SmoothStep**`                                                                | 同上                                                                                                     |
| RAMP                                  | `**MD_AmpShared_RampUnit**`                                                                  | 同上                                                                                                     |
| PERIODIC                              | 正弦 + 偏置（UF 闭式）                                                                               | Fourier 系数形式（**未**进 EvalShared）                                                                        |
| MODULATED                             | `**MD_AmpShared_Modulated`**（`MD_Amp_MATH_PI`）                                               | 同上（域用 `**ACOS(-1)**` 作 \pi）                                                                            |
| DECAY                                 | A_0 e^{-\lambda t}                                                                           | `decay_*` 等价映射（经 `MD_Amp_Slot_To_MD_Desc`）                                                             |
| USER                                  | 已注册 UAMP：回调；**未注册子程序**                                                                       | **域**：`amp_state%currentValue`（由 WriteBack / 求解侧更新）；**UF**：`evaluate` 返回 `**1.0_wp`**（中性因子，与占位/未知类型一致） |
| `AMP_SOLUTION_DEPENDENT` 等（谱/致动器/PSD） | `**1.0_wp**`（L3 占位）                                                                          | `**1.0_wp**` + `**IF_STATUS_OK**`（显式分支，**不**进 `DEFAULT`）                                               |
| 未知 `amp_type`（非上表任一 `AMP_*`）          | `**1.0_wp`**（无 `ErrorStatus`）                                                                | `**1.0_wp**` 且 `**IF_STATUS_INVALID**`（`SELECT CASE` 的 `DEFAULT`）                                      |


`**Amp_GetFactor**`：仅当域 `**EvalAtTime**` 返回 `**IF_STATUS_OK**` 时采用域 `**value**`；若域为 `**INVALID**`（未知类型）或占位失败，则回退 `**UF` 槽** `evaluate`；再不行则 `**1.0_wp`**。

---

### `MD_Amp_Ext_Desc`（API）

- `**amp_type**`：与 `MD_Amp_Def` 中 `AMP_*` 整型一致；`**MD_Amp_Ext_Desc` / KW** 侧 `**AMP_USER`** 未绑定子程序时应报错（见解析/API 合同）；**UF / 域求值**行为见上表 **USER** 行。  
- **TABULAR**：`time_points` / `amplitude_value` / `extrapolate`；`**smooth`** 暂不映射为多段 Hermite（UF tabular 仅为分段线性）。  
- **SMOOTH / RAMP / PERIODIC / DECAY / MODULATED**：使用对应标量字段（见 `**MD_Amp_UF`** 中 `**MD_Amp_Ext_Desc**`）。

---

### 验证

- **CTest**：`-DBUILD_TESTING=ON` 且存在 `ufc_core/Testing/test_amplitude.f90` 时注册 `Amplitude_UF_MD`；仓库内另有参考测试 `UFC/tests/test_amplitude.f90`（若 CMake 未接入则手动编译链接 `ufc_core`）。  
- Harness：命名扫描（与仓库 `MD_*` 约定可能不一致，见工具说明）。

---

**版本**：v2.19  
**最后更新**：2026-05-08  

**迁移说明**：DataPlatform `MD_Amp_Desc` 注册为 **24 字段**（在 v2.1 的 `mod_*` 之后又增加 `tabular_extrapolate`、`smooth_*×4`、`ramp_t_end`）；旧序列化需按新布局升级。  
**v2.4**：`MD_Amp_Def` 中 `**AMP_*` / `AMP_EQUALLY_SPACED`** 由默认整型改为 `**INTEGER(i4), PARAMETER**`（数值为 `*_i4`）；与 `MD_Amp_Slot_Desc%amp_type` / `MD_Amp_Desc%amp_type` 比较时类型一致，无需改语义常量取值。  
**v2.5**：**域 `EvalAtTime`** 对 `**AMP_SOLUTION_DEPENDENT` / `AMP_ACTUATOR` / `AMP_SPECTRUM` / `AMP_PSD**` 显式返回 `**1.0_wp` + `IF_STATUS_OK**`（与 UF `evaluate` 占位一致）；**未知类型**仍 `**1.0_wp` + `IF_STATUS_INVALID`**。上表与 `**Amp_GetFactor**` 采纳规则已对齐。  
**v2.6**：**UF `evaluate`**：USER 已标 `is_user_defined` 但未挂接子程序、或 `**amp_type=AMP_USER**` 且未走 UAMP 分支时，一律 `**1.0_wp**`；`**MD_Amp_Mgr**` 显式 `**PUBLIC**` 列出 `**MD_Amp_*_Arg**` 便于 `USE ... ONLY`。  
**v2.7**：`**MD_Amp_Mgr`** 增加 `**MD_Amp_Apply_Add_Arg**`、`**MD_Amp_Apply_Get_Arg**`、`**MD_Amp_Apply_EvalAtTime_Arg**`，完成 SIO `*_Arg` 与 `**MD_Amp_Domain**` TBP 的对接；模块头 **「设计意图」** 四段说明；**WriteBack** 仍由 `**MD_Amp_Idx`** 或调用方在 `**EvalAtTime**` OK 后显式调用。  
**v2.8**：`**MD_Amp_Apply_GetSummary_Arg`**；`**Amp_GetFactor**` 域分支与 `**Apply_EvalAtTime_Arg**` 对齐；`**MD_Amp_Slot_To_MD_Desc**` 显式 `**AMP_USER**` 与 `**AMP_SOLUTION_DEPENDENT` / `AMP_ACTUATOR` / `AMP_SPECTRUM` / `AMP_PSD**` 分支；SIO `*_Arg` 字段 **[IN]/[OUT]** 注释补全。  
**v2.9**：合同节 **「Eval 总线与 Harness」**：**不**引入公共 `**MD_Amp_Eval_Apply(in,out)`**；`**MD_Amp_Eval_***` 限定为 **UAMP** 契约；解析求值走 `**evaluate` / `EvalAtTime` / `Apply_EvalAtTime_Arg`**；`**MD_Amp_Mgr**` 模块头与源码注释与之一致。  
**v2.10**：`**MD_Amp_Mgr`** `CONTAINS` 按 UFC 习惯重排（**SIO `Apply_*`** 置顶 → `**MD_Amp_Slot_Ctx**` → `**MD_Amp_Slot_Desc**` 生命周期与 setter → `**Amp_GetFactor**` → 公共 UF→MD）；私有 `**amp_md_desc_dealloc_arrays**` 去重 `**MD_Amp_Slot_To_MD_Desc**` 中 `ALLOCATED` 清理；`**AMPDB_INIT_CAP_DEFAULT**` 命名默认容量。  
**v2.11**：`**MD_Amp_Slot_Desc` / `MD_Amp_Slot_Ctx`** 与 UF 侧 `**ampdb_*` / `evaluate**`、`**MD_Amp_Eval_***` 迁至 `**MD_Amp_UF**`（Def 与 Algo 分离）；`**MD_Amp_Mgr**` 仅保留 SIO、`**Amp_GetFactor**`、`**MD_Amp_Slot_To_MD_Desc**` 等；CMake `**_L3_TYPES_FIRST**` 保证 `**MD_Amp_Def**` 先于 `**MD_Amp_UF**` 编译。  
**v2.12**：**依赖收敛**：仅需要 `**UF_*` / `TIME_*`** 的 L3/L5/L6 模块优先 `**USE MD_Amp_UF**`；`**AMP_***` 优先 `**USE MD_Amp_Def**`；`**Amp_GetFactor` / `MD_Amp_Slot_To_MD_Desc**` 经 `**MD_Amp_Mgr**`（SIO `**Apply_***` 定义在 `**MD_Amp_Def**`，Algo 再导出）。`**MD_Amp_SyncFromLegacy**`：域内已有幅值槽时 **幂等返回**。`**MD_KWMapper`**：单一 `**map_amplitude**`，`**UF_ModelDef%add_amplitude**`（修正无效 `**amplitude_db**`）。  
**v2.13**：`**MD_Amp_*_Arg` + `MD_Amp_Apply_*_Arg`** 迁入 `**MD_Amp_Def**`（`**MD_Amp_Idx**` 仅 `USE Def`）；新增 `**MD_Amplitude_EvalShared**`，**域 `EvalAtTime`** 与 **UF `evaluate`** 共用 **TABULAR / SMOOTH / RAMP / MODULATED** 数值内核；`**MD_Amp_Mgr`** 再导出 SIO 符号以保持兼容。  
**v2.14**：**文件收敛为 4 个 `.f90`**：`**MD_AmpShared_***` 并入 `**MD_Amp_Def**`；`**MD_Amp_Ext_Desc` / `MD_Amp_FromExt***` 并入 `**MD_Amp_UF**`；`**MD_Amp_SyncFromLegacy` / `MD_Amp_ResolveName**` 并入 `**MD_Amp_Mgr**`（调用方 `USE MD_Amp_Mgr`）；删除 `**MD_Amplitude_EvalShared**`、`**MD_Amplitude_Brg**`、`**MD_AmplitudeSync_Algo**`；CMake `**_L3_TYPES_FIRST**` 仅保证 `**Def` → `UF**`。  
**v2.15**：**命名统一为 `MD_Amplitude_<后缀>.f90` + 同名 `MODULE`**：`MD_AmplitudeIdx_Brg` → `**MD_Amplitude_Idx**`（`MD_Amp_Idx.f90`）；`MD_Amplitude_UF_Def` → `**MD_Amplitude_UF**`（`MD_Amp_UF.f90`）；全仓库 `**USE MD_Amplitude_UF**`；CMake 类型优先序匹配新文件名。  
**v2.16**：`**MD_Amp_SyncFromLegacy`**：若 `**md_layer%l3Frozen**` 为真则 `**IF_STATUS_INVALID**`（不在 `**MD_Amp_Def**` 引用全局容器，避免环）；`**MD_Model_Brg` / `MD_ModelBuilder_Build**` 在 legacy→域 同步链入口对 `**l3Frozen**` 先行拒绝（与 Step/Solver 变异策略一致）。  
**v2.17**：`**MD_Amp_Apply_AddAmplitude_MDL(md_layer, arg)`**（`**MD_Amp_Mgr**`）：Harness/有 `**MD_L3_LayerContainer**` 上下文时 **优先** 于裸 `**MD_Amp_Apply_Add_Arg`**，内含 `**l3Frozen**` 与 `**md_layer%initialized**` 守卫后再转调域 TBP。  
**v2.18**：**符号缩写对齐**：域 TYPE `**MD_Amp_Domain`**；UAMP 结构化捆绑 `**MD_Amp_Eval_***`；管理过程 `**MD_Amp_Slot_To_MD_Desc**`、`**MD_Amp_SyncFromLegacy**`、`**MD_Amp_ResolveName**`、`**MD_Amp_Apply_AddAmplitude_MDL**`；索引 API `**MD_Amp_GetAmplitude_Idx**` / `**MD_Amp_EvalAtTime_Idx**`；CMake `**_L3_TYPES_FIRST**` 匹配 `**MD_Amp_Def.f90**` / `**MD_Amp_UF.f90**`。  
**v2.19**：**四型命名收敛（禁止 `UF_*` TYPE）**：原 `**UF_AmplitudeDef` / `UF_AmplitudeDB`** 重命名为 `**MD_Amp_Slot_Desc` / `MD_Amp_Slot_Ctx**`；`**UF_AMP_MATH_PI**` → `**MD_Amp_MATH_PI**`；外 `**Desc_Amplitude**` → `**MD_Amp_Ext_Desc**`；`**Amplitude_FromDesc***` → `**MD_Amp_FromExt***`；`**MD_Amp_UF_To_MD_Desc**` → `**MD_Amp_Slot_To_MD_Desc**`；`**UF_Amplitude_GetStatistics**` → `**MD_Amp_Slot_GetStatistics**`。全仓库 `USE`/合同同步；模块名 `**MD_Amp_UF**` 保留（实现文件角色 `_UF`）。

---

### L1_IF 基础设施集成 (v3.0)


| 设施         | 集成方式                                               | 说明                     |
| ---------- | -------------------------------------------------- | ---------------------- |
| **SymTbl** | `**MD_Amp_Domain%AddAmplitude`** 路径注册 `AMP:{name}` | 建模期 O(1) 命名查找          |
| **错误链**    | Bridge 出口 `UFC_Err_Wrap`                           | 见 L1_IF_INTEGRATION.md |


---

### 细粒度子程序清单


| 文件               | MODULE       | TYPE（PUBLIC）                                                                                                                                                                                                                                    | 过程 / TBP                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MD_Amp_Mgr.f90` | `MD_Amp_Mgr` | —                                                                                                                                                                                                                                               | `MD_Amp_Apply_AddAmplitude_MDL` (SUB,PUB,Mutate); `Amp_GetFactor` (FN,PUB,Query); `MD_Amp_GetFactor` (FN,PUB,Query); `amp_md_desc_dealloc_arrays` (SUB,PRV,—); `MD_Amp_Slot_To_MD_Desc` (SUB,PUB,—); `MD_Amp_SyncFromLegacy` (SUB,PUB,Populate); `MD_Amp_ResolveName` (FN,PUB,—)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `MD_Amp_Def.f90` | `MD_Amp_Def` | `MD_Amp_Tabular_Desc`, `MD_Amp_User_Desc`, `MD_Amp_Periodic_Desc`, `MD_Amp_Modulated_Desc`, `MD_Amp_Algo`, `MD_Amp_Desc`, `MD_Amp_State`, `MD_Amp_GetSummary_Arg`, `MD_Amp_Add_Arg`, `MD_Amp_Get_Arg`, `MD_Amp_EvalAtTime_Arg`, `MD_Amp_Domain` | `MD_Amp_Domain`：`**Init` / `Finalize` / `AddAmplitude` / `GetAmplitude` / `EvalAtTime` / `WriteBack` / `GetSummary`（均为 TBP）**；`MD_AmpShared_`*（FN,PUB）；`MD_Amp_DP_RegisterStructType` (SUB,PRV)；`MD_Amp_Apply_Add_Arg` / `MD_Amp_Apply_Get_Arg` / `MD_Amp_Apply_EvalAtTime_Arg` / `MD_Amp_Apply_GetSummary_Arg` (SUB,PUB)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `MD_Amp_Idx.f90` | `MD_Amp_Idx` | —                                                                                                                                                                                                                                               | `MD_Amp_GetAmplitude_Idx` (SUB,PUB,Query); `MD_Amp_EvalAtTime_Idx` (SUB,PUB,—)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `MD_Amp_UF.f90`  | `MD_Amp_UF`  | `MD_Amp_Eval_Desc`, `MD_Amp_Eval_Algo`, `MD_Amp_Eval_Ctx`, `MD_Amp_Eval_State`, `MD_Amp_Eval_In`, `MD_Amp_Eval_Out`, `MD_Amp_Ext_Desc`, `MD_Amp_Slot_Desc`, `MD_Amp_Slot_Ctx`                                                                   | `Amp_User_IF_Structured` (SUB,PRV,—); `Amp_User_IF` (SUB,PRV,—); `user_subroutine` (TBP,PRV,—); `user_subroutine_structured` (TBP,PRV,—); `init` (TBP,PRV,—); `add_point` (TBP,PRV,—); `set_tabular` (TBP,PRV,—); `set_smooth_step` (TBP,PRV,—); `set_periodic` (TBP,PRV,—); `set_modulated` (TBP,PRV,—); `set_ramp` (TBP,PRV,—); `load_from_file` (TBP,PRV,—); `set_user_subroutine` (TBP,PRV,—); `evaluate` (TBP,PRV,—); `clear` (TBP,PRV,—); `ampdb_add_amplitude` (SUB,PRV,Mutate); `ampdb_clear` (SUB,PRV,Mutate); `ampdb_evaluate` (FN,PRV,Compute); `ampdb_find_by_name` (FN,PRV,Query); `ampdb_get_amplitude` (FN,PRV,Query); `ampdb_init` (SUB,PRV,Init); `amplitude_init` (SUB,PRV,Init); `amplitude_add_point` (SUB,PRV,Mutate); `amplitude_clear` (SUB,PRV,Mutate); `amplitude_load_from_file` (SUB,PRV,Parse); `amplitude_set_periodic` (SUB,PRV,Mutate); `amplitude_set_ramp` (SUB,PRV,Mutate); `amplitude_set_modulated` (SUB,PRV,Mutate); `amplitude_set_smooth_step` (SUB,PRV,Mutate); `amplitude_set_tabular` (SUB,PRV,Mutate); `amplitude_set_user_sub` (SUB,PRV,Mutate); `amplitude_evaluate` (FN,PRV,Compute); `MD_Amp_FromExt` (SUB,PUB,—); `MD_Amp_FromExt_Def` (SUB,PUB,—); `MD_Amp_FromExt_DB` (SUB,PUB,—) |


---

### Partial Pillar v2.0 Update (H4c Amplitude)

> 更新日期: 2026-04-26

**半柱分类**: H4c Amplitude 是 L3 层唯一域 (Layer-Only + L5 融入)。


| 层   | 模块               | 角色                                      | 状态      |
| --- | ---------------- | --------------------------------------- | ------- |
| L3  | `MD_Amp_Def.f90` | **AUTHORITY** — 幅值曲线类型 + 标量求值核          | Phase B |
| L3  | `MD_Amp_Mgr.f90` | 域容器 + SIO Apply                         | ACTIVE  |
| L4  | (不存在)            | 幅值非单元级物理计算                              | —       |
| L5  | (不存在)            | 幅值经 `UF_AmpFactor` / `RT_StepDriver` 消费 | —       |


**L5 融入点**:

- `RT_Solv.f90::UF_AmpFactor` — 求值幅值曲线在当前时间的因子
- `RT_Step_Exec.f90` — 步驱动中的荷载因子计算

**跨层数据流**: `MD_Amp_Domain`(L3) -> 步级 Populate -> L5 AmpFactor(t) 查询

**架构文档**: `UFC_DOMAIN_PILLAR_ARCHITECTURE.md`