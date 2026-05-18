# Bridge 域合同卡 (L4_PH/Bridge)

**Layer**: L4_PH (物理组件层)  
**Domain**: Bridge (层间数据适配/桥接)  
**Version**: v2.0  
**Updated**: 2026-04-28  
**Status**: ACTIVE  
**关联文档**:  
- L3 Bridge 索引: [`BRIDGE_INDEX.md`](../../L3_MD/Bridge/BRIDGE_INDEX.md)  
- L3 合同卡: [`L3_MD/Bridge/CONTRACT.md`](../../L3_MD/Bridge/CONTRACT.md)  
- L5 合同卡: [`L5_RT/Bridge/CONTRACT.md`](../../L5_RT/Bridge/CONTRACT.md)  
- Populate: [`CONTRACT_Populate_Layer.md`](CONTRACT_Populate_Layer.md)

---

## 一、职责边界

### 核心职责
- **定位**: UFC L4_PH 层 Bridge 域 — L4与L2/L3之间的层间数据适配通道
- **职责**: 在 Populate/Step-Init 完成 L4↔L3、L4↔L2 的查询与索引适配；承载 `PH_Brg_Domain`（UEL/UMAT/GPU 等注册元数据）
- **边界**: 仅做数据布局/索引/单位的适配层；不替代 L3 官方 `MD_*_PH_Brg`（真值见 `BRIDGE_INDEX.md`）
- **依赖**: L1 `IF_*`, L3 经官方 Brg 或 Populate 只读 API

### 禁止事项
- **禁止**持有全局 CSR — 组装由 L5 负责
- **禁止**做 NR 主循环 — 迭代编排由 L5 负责
- **禁止**内嵌单元弱式积分 — 已 G4 封堵 (`PH_Brg_ElementStiffAssembly` 返回 `IF_STATUS_INVALID`)
- **禁止**合同中出现未在 `BRIDGE_INDEX.md` 登记的模块名

---

## 二、文件清单 (6+子域文件)

| 子目录 | 文件 | MODULE | 后缀角色 | 状态 | 职责 |
|--------|------|--------|---------|------|------|
| `/` | `PH_Brg_Domain.f90` | `PH_BrgDomain` | Domain | **active** | 域容器 + UEL/UMAT/GPU 注册槽位 |
| `/` | `PH_Brg_L2.f90` | `PH_BrgL2` | `_Ops` | **active** | L4↔L2 数值接口 (连接性/坐标/Gauss点表) |
| `/` | `PH_Brg_L3.f90` | `PH_BrgL3` | `_Ops` | **active** | L4↔L3 查询封装 (幅值/材料响应/坐标) |
| `Output/` | (空) | — | — | 待建 | Bridge 输出子域 |
| `WriteBack/` | `PH_WB_Mgr.f90` | `PH_WB_Mgr` | `_Mgr` | **active** | WriteBack 管理器 |
| `WriteBack/` | `PH_WB_Init.f90` | `PH_WB_Init` | `_Init` | **active** | WriteBack 初始化 |
| `WriteBack/` | `PH_WB_Brg.f90` | `PH_WB_Brg` | `_Brg` | **active** | WriteBack 桥接 |

---

## 三、四类 TYPE 清单

### 3.1 Bridge 域 TYPE (源: `PH_Brg_Domain.f90`)

| 四型 | TYPE 名称 | 核心字段 | 说明 |
|------|-----------|----------|------|
| **Ctx** | `PH_Brg_Ctx` | step_idx, incr_idx, nRegisteredLibs, libTypes(MAX), libActive(MAX), nUEL, nUMAT | 跨层上下文快照；非热路径 |
| **State** | `PH_Brg_State` | totalCalls, failedCalls, lastErrorCode, totalBridgeTime, gpuTransferTime | 运行时统计；Bridge **不作为** State 真相源 |
| **Algo** | `PH_Brg_Params` | enableUEL, enableUMAT, enableGPU, enableExternal, gpuDeviceId, gpuAsyncTransfer | 配置参数；Bridge **不作为** Algo 真相源 |
| **Desc** | (Populate 后视图) | — | Bridge 不持有独立 Desc TYPE；经 Populate 写入各域 slot |

### 3.2 Arg 类型

| TYPE | 所属模块 | 用途 |
|------|---------|------|
| `PH_Brg_RegisterLib_Arg` | `PH_BrgDomain` | 注册外部库的 SIO 包 |
| `PH_Brg_GetSummary_Arg` | `PH_BrgDomain` | 获取摘要信息的 SIO 包 |
| `PH_Brg_GetElemConnectivity_Arg` | `PH_BrgL2` | L2 连接性查询包 |
| `PH_Brg_GetNodeCoords_Arg` | `PH_BrgL2` | L2 节点坐标查询包 |
| `PH_Brg_GetGauss_Pts1D/2D/3D_Arg` | `PH_BrgL2` | Gauss 点表查询包 |
| `PH_Brg_Elem_StiffAsm_Arg` | `PH_BrgL3` | 单元刚度装配包 (**已 G4 废弃**) |
| `PH_Brg_UpdateElemState_Arg` | `PH_BrgL3` | 单元状态更新包 |
| `PH_Brg_GetMatResp_Arg` | `PH_BrgL3` | 材料响应查询包 |

### 3.3 四型裁剪决策

- **Desc**: N — Bridge 不持有独立 Desc TYPE，经 Populate 后视图 (slot)
- **State**: Y (PH_Brg_State) — 仅运行时统计，不作为真相源
- **Algo**: Y (PH_Brg_Params) — 仅配置参数，不作为真相源
- **Ctx**: Y (PH_Brg_Ctx) — 跨层上下文快照

---

## 四、与邻层合同

| 对端 | 合同 / 代码 | 关系 |
|------|-------------|------|
| **L3 Bridge** | [`L3_MD/Bridge/CONTRACT.md`](../../L3_MD/Bridge/CONTRACT.md) | L3 为 **`MD_*_PH_Brg` / `*_RT_Brg`** **唯一宿主**；**禁止** L3 Core `USE` L4 |
| **索引真值** | [`BRIDGE_INDEX.md`](../../L3_MD/Bridge/BRIDGE_INDEX.md) | **新增/改名** 桥模块 **必须先登记** 再写合同表 |
| **Populate / Layer** | [`CONTRACT_Populate_Layer.md`](CONTRACT_Populate_Layer.md) | **`PH_L4_Init`**：**Material→…→Coupling→`bridge%Init`**；**无** 独立 `PH_L4_Populate_Bridge`；**`PH_Brg_SyncRtCouplingPool_FromPh`** 在 **`PH_L4_Populate_Coupling`** 末尾调用 |
| **L5 Bridge** | [`L5_RT/Bridge/CONTRACT.md`](../../L5_RT/Bridge/CONTRACT.md) | L5 **`RT_*_Brg`** 编排；L4 **`PH_Brg_Coupling_RT`** 仅 **PH→RT 池映射**（冷路径） |
| **Coupling** | [`CONTRACT_Coupling.md`](CONTRACT_Coupling.md) | Populate 后 **L4 `PH_CPL_*` → RT `COUPLING_*`**；枚举映射见 **`docs/UFC_Coupling_L3_PH_RT_Chain.md`** |

### L3→L4 官方 Bridge（须在 `BRIDGE_INDEX.md` 登记）

| `MODULE` | 路径（`L3_MD` 下） | 说明 |
|----------|-------------------|------|
| `MD_MatLibPH_Brg` | `Bridge/Bridge_L4/MD_MatLibPH_Brg.f90` | 材料 → PH slot / 路由（**热路径 LEGACY**，以 Populate 金线为准） |
| `MD_ElemPH_Brg` | `Bridge/Bridge_L4/MD_ElemPH_Brg.f90` | 单元 Desc → PH |
| `MD_LBCPH_Brg` | `Bridge/Bridge_L4/MD_LBCPH_Brg.f90` | 载荷/BC → PH |
| `MD_GeomPH_Brg` | `Bridge/Bridge_L4/MD_GeomPH_Brg.f90` | 几何 → PH ElemCtx |
| `MD_ContPH_Brg` | `Bridge/Bridge_L4/MD_ContPH_Brg.f90` | 接触参数 → PH |
| `MD_ConstraintPH_Brg` | `Bridge/Bridge_L4/MD_ConstraintPH_Brg.f90` | 约束 → PH |

> **约束 / 耦合**：当前 **无** `MD_Const_PH_Brg` / `MD_Cpl_PH_Brg` 模块时，由 **`PH_L4_Populate_Core`** 经 `MD_Const_*`、`MD_Cpl_*` 等 **只读 API** 填充 L4 slot；若日后引入专用 `*_PH_Brg`，须同步 **`BRIDGE_INDEX.md` + 本卡**。

### L4 本地 Bridge 模块（仓库现状）

| 功能集 | `MODULE` | 文件 | 说明 |
|--------|----------|------|------|
| L4↔L3 查询 / 薄组装 | `PH_Brg_L3` | `Bridge/PH_Brg_L3.f90` | 幅值 **`PH_Brg_GetAmplitudeValue_Idx`**、材料响应、节点坐标；**`PH_Brg_ElementStiffAssembly`** 已 **G4 封堵**（体返回 `IF_STATUS_INVALID`，须用 **`PH_Element_Domain%Compute_Ke`**） |
| L4↔L2 数值接口 | `PH_Brg_L2` | `Bridge/PH_Brg_L2.f90` | 连接性、节点坐标、**Gauss 点表**（`NM_*`） |
| 域聚合 | `PH_Brg_Domain` | `Bridge/PH_Brg_Domain_Core.f90` | **`g_ufc_global%ph_layer%bridge`**；UEL/UMAT/GPU **注册槽位**；**Init 最后 / Finalize 最先** |
| PH→RT 耦合池 | `PH_Brg_Coupling_RT` | `Bridge/PH_Brg_Coupling_RT.f90` | **`PH_Brg_SyncRtCouplingPool_FromPh`**（**no-op**，保留 Populate 调用点；L5 `RT_Coupling_Domain_Core` 已移除） |
| UMAT ABI | `PH_Mat_Defn_UMAT_Bridge`、`PH_Mat_Core_UMAT_Adapter`、`PH_UserSub_UMAT` 等 | `Material/USR/`、`Material/Shared/` | 归属 **[`CONTRACT_Material.md`](../Material/CONTRACT.md)**；占位 `PH_MatConstitutive_UMAT_Brg` **已删除** |

- **四型配置**（典型）：以 **Desc/Ctx 快照** 为主；Bridge **不** 作为 Algo/State 真相源。  

- **错误与 Arg**：**`PH_Brg_Domain`** 使用 **`PH_Brg_RegisterLib_Arg` / `PH_Brg_GetSummary_Arg` + `ErrorStatusType`**；**`PH_Brg_L2`/`PH_Brg_L3`** 各 `*_In`/`*_Out` 带 **`status`**；调用方须检查 **`STATUS_OK`**。  

- **依赖**：L1 `IF_*`；L3 经 **上表官方 Brg** 或 Populate 只读 API；**`PH_Brg_Coupling_RT`** **不** `USE` L5（MVP 无 RT 耦合池）。  
- **下游**：L4 各域 slot；L5 经 Asm / Runner；**无** `g_ufc_global%rt_layer%coupling`。  
- **热路径**：**否** — 与 Populate / Step-Init 同级冷路径（**`PH_Brg_GetAmplitudeValue_Idx`** 若在载荷循环中被频繁调用，仍应避免在其实现内扫全模型，见 LoadBC 合同）。  

- **门闩 G1–G4**：见 [`README.md`](README.md)；**G4（2026-03-27）**：**`PH_Brg_ElementStiffAssembly`** 已废弃为错误返回；新代码 **禁止** 复用该符号作为热路径。桥接收敛说明：[`Phase4_L3L4桥接_收敛说明.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/Phase4_L3L4桥接_收敛说明.md)。  

- **合同交叉引用**：L3 [`L3_MD/Bridge/CONTRACT.md`](../../L3_MD/Bridge/CONTRACT.md)；[`BRIDGE_INDEX.md`](../../L3_MD/Bridge/BRIDGE_INDEX.md)；Populate [`CONTRACT_Populate_Layer.md`](CONTRACT_Populate_Layer.md)；L5 [`L5_RT/Bridge/CONTRACT.md`](../../L5_RT/Bridge/CONTRACT.md)；Coupling [`CONTRACT_Coupling.md`](CONTRACT_Coupling.md)。  

### 算法细节与四链（审查）

| 链 | 内容（与实现一致） |
|----|---------------------|
| **理论** | **无** 连续介质本构或弱式；仅为 **数据布局/索引/单位** 的 **适配层**。 |
| **逻辑** | **官方 `MD_*_PH_Brg`**：L3 Desc → L4 可消费结构；**`PH_Brg_L3`**：幅值、几何等 **查询封装**，默认 **Populate 或冷路径**。 |
| **计算** | **O(1) 或 O(n)** 拷贝/映射；**禁止** 内嵌 **单元积分** 或 **NR 迭代**（**`PH_Brg_ElementStiffAssembly`** 已封堵，不再作为例外）。 |
| **数据** | 输出写入 **各域 slot** 或 **RT 池**；**真值表** 以 **`BRIDGE_INDEX.md`** 为准，**禁止** 合同中出现未登记模块名。 |

**审查注意**：若某过程既 **读 L3** 又 **含 B 阵/高斯循环**，应 **迁出 Bridge** 至 **Element/Material** 等域（G1）。

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 实现锚点（.f90）

| 合同项 | 绑定（路径 / 符号） |
|--------|---------------------|
| **L4↔L3** | `L4_PH/Bridge/PH_Brg_L3.f90`：`PH_Brg_GetAmplitudeValue_Idx`、`PH_Brg_GetMaterialResponse_Idx`、`PH_Brg_GetNodeCoords_Idx`、`PH_Brg_ElementStiffAssembly_Idx`（遗留）等 |
| **L4↔L2** | `L4_PH/Bridge/PH_Brg_L2.f90`：`PH_Brg_GetElemConnectivity_Idx`、`PH_Brg_GetGaussPoints1D/2D/3D` 等 |
| **Bridge 域** | `L4_PH/Bridge/PH_Brg_Domain_Core.f90`：**`PH_Brg_Domain`** — `%Init` / `%Finalize` / `%RegisterLib` / `%GetSummary` |
| **PH→RT 耦合** | `L4_PH/Bridge/PH_Brg_Coupling_RT.f90`：**`PH_Brg_SyncRtCouplingPool_FromPh`**（由 **`PH_L4_Populate_Coupling`** 调用）、**`PH_Brg_Map_PhCpl_To_RtCpl`** |
| **Layer 挂载点** | `PH_L4_LayerContainer_Core.f90`：**`PH_L4_LayerContainer%bridge`**，Init/Finalize 顺序见 **与邻层** 表 |

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L4_BRIDGE_xxx` (40100–40199) |
| 严重级 | WARNING: 映射字段缺失(降级); ERROR: L3 Brg 返回非 OK; FATAL: 类型不匹配 |
| 传播规则 | 各 Bridge 过程经 `status`/`ErrorStatusType` 返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 默认值; ERROR：中止 Populate 并上报 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Bridge | T(合同) | L3 官方 MD_*_PH_Brg 唯一宿主 |
| R2 | L4_PH/Element | S(消费) | Populate 后 slot 供 Element 使用 |
| R3 | L4_PH/Material | S(消费) | Populate 后 slot 供 Material 使用 |
| R4 | L4_PH/LoadBC | S(消费) | Populate 后 slot 供 LoadBC 使用 |
| R5 | L4_PH/Contact | S(消费) | Populate 后 slot 供 Contact 使用 |
| R6 | L5_RT/Bridge | B(桥接) | L5 侧桥接编排 |
| R7 | L1_IF/Error | U(USE) | 错误码定义 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Bridge 禁止内嵌单元积分(G1–G4) | 硬 | Code Review | G4 |
| Bridge 不作为 Algo/State 真相源 | 硬 | Code Review | — |
| O(1)/O(n) 映射，禁止 NR 迭代 | 硬 | Code Review | H-HOT-01 |
| 新增 PH_Brg_* 须先更新 BRIDGE_INDEX | 硬 | Harness | H-BRG-01 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | Populate 后视图(slot) | Bridge 不持有独立 Desc TYPE |
| 2 | State 定义 | N/A | Bridge 无状态 |
| 3 | Algo 定义 | N/A | Bridge 不执行算法 |
| 4 | Ctx 定义 | N/A | — |
| 5 | Init/Finalize | PH_Brg_Domain%Init/Finalize | 生命周期 |
| 6 | Query | PH_Brg_GetAmplitudeValue_Idx 等 | L3 查询封装 |
| 7 | Validate | 映射前参数校验 | 内嵌 |
| 8 | Populate | Bridge 本身即 Populate 管道 | 核心职责 |
| 9 | Bridge | PH_Brg_L3, PH_Brg_L2, PH_Brg_Domain | 自身即 Bridge |
| 10 | WriteBack | N/A | L4 Bridge 不参与写回 |
| 11 | Parse | N/A | 由 L3/L6 处理 |
| 12 | Compute | N/A | 禁止计算 |
| 13 | Error | ErrorStatusType + status | 见错误处理 |

---

*维护：新增 `PH_Brg_*` 或变更 L3 `MD_*_PH_Brg` 时，**先** 改 [`BRIDGE_INDEX.md`](../../L3_MD/Bridge/BRIDGE_INDEX.md)，**再** 更新本卡「官方 Bridge」表与 **§ 实现锚点**。*

---

## 验收标准

### 算法完整性

| 检查项 | 要求 | 当前状态 |
|--------|------|----------|
| L4↔L3 查询封装 | 幅值/材料响应/坐标查询完整 | **完成** — `PH_Brg_L3` 已实现 |
| L4↔L2 数值接口 | 连接性/坐标/Gauss点表 | **完成** — `PH_Brg_L2` 已实现 |
| 域容器 Init/Finalize | UEL/UMAT/GPU 注册槽位 | **完成** — `PH_Brg_Domain` 已实现 |
| PH→RT 耦合池映射 | Populate 调用点已保留 | **完成** (no-op) |
| G4 封堵执行 | `PH_Brg_ElementStiffAssembly` 返回错误 | **完成** |
| WriteBack 子域 | 写回管理器和桥接 | **完成** — 3个文件已实现 |

### 命名合规

| 检查项 | 要求 |
|--------|------|
| 文件命名 | `PH_Brg_{Function}.f90` 或 `PH_WB_{Function}.f90` |
| MODULE 命名 | `PH_Brg{Function}` 或 `PH_WB_{Function}` |
| 模块登记 | 新增模块须先在 `BRIDGE_INDEX.md` 登记 |

### 测试覆盖

| 检查项 | 要求 | 当前状态 |
|--------|------|----------|
| L3→L4 Populate 全链 | Desc 正确传递到各域 slot | **基础已建** |
| Bridge 错误传播 | 非 OK 状态正确上报 | **待建** |
| G4 封堵回归 | 废弃接口返回错误 | **待建** |

---

## 变更控制

| 规则 | 说明 |
|------|------|
| 新增 `PH_Brg_*` 模块 | 须先更新 `BRIDGE_INDEX.md`，再更新本卡官方 Bridge 表 |
| L3 `MD_*_PH_Brg` 变更 | 须同步更新 `BRIDGE_INDEX.md` + 本卡 |
| G4 封堵接口 | 禁止复用该符号作为热路径 |
| CONTRACT 版本 | 每次实质性变更须递增版本号并更新日期 |

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 早期 | 初始版合同卡 |
| v2.0 | 2026-04-28 | 完整扩充: 标准化版本头、职责边界、文件清单、四类 TYPE 清单 (Ctx/State/Algo/Desc裁剪)、Arg类型清单、验收标准、变更控制、版本历史 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `PH_Brg_Domain.f90` | `PH_BrgDomain` | `PH_Brg_Ctx`, `PH_Brg_State`, `PH_Brg_Params`, `PH_Brg_RegisterLib_Arg`, `PH_Brg_GetSummary_Arg`, `PH_Brg_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `RegisterLib` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `PH_Brg_Domain_Finalize` (SUB,PRV,Finalize); `PH_Brg_Domain_Init` (SUB,PRV,Init); `PH_Brg_Domain_RegisterLib` (SUB,PRV,Bridge); `PH_Brg_RegisterLib_Impl` (SUB,PRV,Bridge); `PH_Brg_Domain_GetSummary` (SUB,PRV,Query); `PH_Brg_GetSummary_Impl` (SUB,PRV,Query) |
| `PH_Brg_L2.f90` | `PH_BrgL2` | `PH_Brg_ElemId_Desc`, `PH_Brg_GetElemConnectivity_Arg`, `PH_Brg_GetNodeCoords_Arg`, `PH_Brg_GetGauss_Pts1D_Arg`, `PH_Brg_GetGauss_Pts2D_Arg`, `PH_Brg_GetGauss_Pts3D_Arg` | `PH_Brg_GetElemConnectivity` (SUB,PUB,Query); `PH_Brg_GetElemConnectivity_Idx` (SUB,PUB,Query); `PH_Brg_GetGaussPoints1D` (SUB,PUB,Query); `PH_Brg_GetGaussPoints2D` (SUB,PUB,Query); `PH_Brg_GetGaussPoints3D` (SUB,PUB,Query); `PH_Brg_GetNodeCoords` (SUB,PUB,Query); `PH_Brg_GetNodeCoords_Idx` (SUB,PUB,Query) |
| `PH_Brg_L3.f90` | `PH_BrgL3` | `PH_Brg_ElemStateUpdate_Desc`, `PH_Brg_MatId_Desc`, `PH_Brg_Elem_StiffAsm_Arg`, `PH_Brg_UpdateElemState_Arg`, `PH_Brg_GetMatResp_Arg` | `PH_Brg_ElementStiffAssembly` (SUB,PUB,Bridge); `PH_Brg_GetMaterialResponse` (SUB,PUB,Query); `PH_Brg_UpdateElementState` (SUB,PUB,Compute); `PH_Brg_GetMaterialResponse_Idx` (SUB,PUB,Query); `PH_Brg_UpdateElementState_Idx` (SUB,PUB,Compute); `PH_Brg_GetAmplitudeValue_Idx` (SUB,PUB,Query); `PH_Brg_GetNodeCoords_Idx` (SUB,PUB,Query); `PH_Brg_ElementStiffAssembly_Idx` (SUB,PUB,Bridge) |
