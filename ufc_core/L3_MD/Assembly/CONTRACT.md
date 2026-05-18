## Asm（Assembly）域级合同卡

- **层级**：L3_MD
- **域名**：Assembly / 装配与实例
- **缩写**：Asm（`MD_Asm_*`）
- **职责**：装配体、实例变换、部件实例化 **Desc**；**不**做全局矩阵装配（L5 Assembly）。
- **四型配置**：
  - **Desc**：装配 TYPE、实例列表。
  - **State**：约束监控 (`MD_Asm_State`)。
  - **Algo**：容差/策略 (`MD_Asm_Algo`)。
  - **Ctx**：变换缓存 (`MD_Asm_Ctx`)。
- **核心模块**（与 `L3_MD/Assembly/` 源码一致）：
  - `MD_Asm_Mgr.f90` — **`MODULE MD_Asm_Mgr`**：`MD_Assembly_Domain` 容器、`MD_Instance_Desc`/`MD_SetDef`/`MD_SurfaceDef`/`MD_ConstraintDef` Desc、`MD_Asm_Algo`/`MD_Asm_State`/`MD_Asm_Ctx`、Idx API、`g_ufc_global` 委托（约束/接触）、SIO `*_Arg` 类型
  - `MD_Asm_Inst.f90` — **`MODULE MD_Asm_Inst`**：UF 侧实例 `UF_InstanceDef` + 变换 TBP
  - `MD_Asm_Sync.f90` — **`MODULE MD_Asm_Sync`**：Legacy **`UF_AssemblyDef`** + **`MD_Assembly_SyncFromLegacy`** / **`MD_Assembly_MirrorUFConstraintToDomain`**
  - ~~`MD_Asm_Brg.f90`~~ — 已删除：空壳零消费者，L3→L5 桥接由 `Bridge_L5/MD_AssemRT_Brg.f90` 承担
- **已删除模块**（精简）：
  - ~~`MD_Asm_Def.f90`~~ — 平坦原型类型（`MD_InstanceEntry`/`MD_Assembly_Desc`），与 `MD_Asm_Mgr` 重复，零生产消费
  - ~~`MD_Asm_Core.f90`~~ — 原型过程，仅被自身和骨架测试引用
  - ~~`MD_Assem_Domain.f90`~~ — 薄门面 re-export，消费者已迁移至 `MD_Asm_Mgr`
  - ~~`MD_Assem_Mgr.f90`~~ — 已重命名为 `MD_Asm_Mgr.f90`
  - ~~`MD_Assem_Instance.f90`~~ — 已重命名为 `MD_Asm_Inst.f90`
  - ~~`MD_Assem_Legacy.f90`~~ — 已重命名为 `MD_Asm_Sync.f90`
  - ~~`MD_Assembly_API.f90`~~、~~`MD_Instance_API.f90`~~、~~`MD_Assem_Types.f90`~~ 等 — 早期已删除
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Init | Init | 容器初始化 |
| Finalize | Finalize | 释放 |
| Query | Get* / Get*ByName / GetSummary | 按索引/名称/摘要查询 |
| Mutate | AddInstance / AddNodeSet / AddElemSet / AddSurface / AddConstraint(+子类) / AddContactPair | 建模期写入 |
| Idx | MD_Assembly_Get*_Idx (7个) | g_ufc_global 委托查询 |
| Sync | SyncFromLegacy | UF→Domain 同步 |
| Mirror | MirrorUFConstraintToDomain | UF 约束镜像 |

- **金线调用序（与 `MD_Model_Brg` / `MD_ModelBuilder` 一致）**：在 **`g_ufc_global%IsReady()` 为真** 时，于 **`MD_LoadBC_SyncFromLegacy` 之后、`MD_Constraint_SyncFromLegacy` 之前** 调用 **`MD_Assembly_SyncFromLegacy(UF_ModelDef%assembly, md_layer, status)`**，将 **UF** 侧实例/集合/面及简式 **`UF_Constraint`** 灌入 **`md_layer%assembly`**。

- **依赖**：Part、Mesh。
- **Bridge**：**`MD_AssemRT_Brg`**（`L3_MD/Bridge/Bridge_L5/MD_AssemRT_Brg.f90`，`MODULE MD_AssemRT_Brg`）。
- **热路径**：**否**。

- **对端 L4 Populate**：层顺序与桥接约定见 [`../../L4_PH/Bridge/CONTRACT.md`](../../L4_PH/Bridge/CONTRACT.md)；装配相关表面解析见 **`PH_L4Populate_Algo.f90`**（如 **`PH_L4_Populate_Contact`** 与 **`MD_Assembly_GetSurfaceByName_Idx`**）。**全局 CSR 组装在 L5**（非本域）。

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 与跨层灵敏度契约的衔接

本域 **不** 做 **L5 级全局矩阵/残差装配**；灵敏度下 **全局 R**、**单元 R 块** 载体见 [`../contracts/CONTRACT_R_Theta_FourKind.md`](../contracts/CONTRACT_R_Theta_FourKind.md) §2、§5。

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_ASSEMBLY_xxx` (31000–31099) |
| 严重级 | WARNING: 实例变换矩阵为单位阵(可能合法); ERROR: 实例引用 Part 不存在; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：日志；ERROR：中止同步并上报 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Part | S(消费) | 实例引用 Part 定义 |
| R2 | L3_MD/Element/Mesh | S(消费) | 全局坐标/连通依赖 Mesh |
| R3 | L3_MD/Constraint | T(合同) | 约束引用装配体集/面 |
| R4 | L3_MD/Interaction | T(合同) | 接触引用装配体表面 |
| R5 | L5_RT/Assembly | B(桥接) | 经 MD_AssemRT_Brg 映射 |
| R6 | L4_PH/Populate | B(桥接) | 表面解析经 Assembly API |
| R7 | L1_IF/Error | U(USE) | 错误码定义 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Assembly Desc 为 Write-Once，建模后只读 | 硬 | Code Review | — |
| 禁止在本域做全局矩阵 CSR 装配 | 硬 | Code Review | — |
| L3→L5 须经 MD_AssemRT_Brg | 硬 | Harness | H-DEP-03 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 实例 ID 唯一性 | 软 | Init 校验 | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | MD_Assembly_Domain (装配TYPE/实例列表) | 装配描述 |
| 2 | State 定义 | MD_Asm_State | 约束监控 |
| 3 | Algo 定义 | MD_Asm_Algo (容差/策略) | — |
| 4 | Ctx 定义 | MD_Asm_Ctx (变换缓存) | — |
| 5 | Init/Finalize | Init/Finalize TBP | 域容器初始化/释放 |
| 6 | Query | Get*/Get*ByName | 只读查询 |
| 7 | Validate | 实例/集合一致性 | 内嵌于 Sync |
| 8 | Populate | 经 Bridge → L5 Assembly | MD_AssemRT_Brg |
| 9 | Bridge | MD_Asm_Brg / MD_AssemRT_Brg | L5 桥接 |
| 10 | WriteBack | N/A | 装配级不参与写回 |
| 11 | Parse | 经 KeyWord *ASSEMBLY/*INSTANCE | — |
| 12 | Compute | N/A | L3 无计算 |
| 13 | Error | status 参数返回 | 见错误处理 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 装配体理论→部件实例化→全局坐标变换 |
| **逻辑链** | Model→Part→Assembly→Mesh(全局连通)→L5 DofMap |
| **计算链** | L3 无计算；全局 CSR 装配在 L5_RT/Assembly |
| **数据链** | INP→MD_Assembly_Domain(冷)→MD_AssemRT_Brg→L5 DofMap |

---

### Partial Pillar v2.0 Update (H3 Assembly)

> 更新日期: 2026-04-26

**半柱分类**: H3 Assembly 是 L3+L5 半贯通柱，L4 无独立 Assembly 目录。

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L3 | `MD_Asm_Mgr.f90` | **AUTHORITY** — 域容器 + 四型 + Idx API | ACTIVE |
| L3 | `MD_Asm_Inst.f90` | UF Instance + 变换 TBP | ACTIVE |
| L3 | `MD_Asm_Sync.f90` | Legacy UF + SyncFromLegacy | ACTIVE |
| L3 | ~~`MD_Asm_Brg.f90`~~ | 已删除（空壳，桥接由 `MD_AssemRT_Brg` 承担） | DELETED |
| L4 | (不存在) | L4 域提供 Ke/Fe/Ce — Assembly 语义分散 | — |
| L5 | `RT_Asm_Def.f90` | **AUTHORITY** — 全局 K/F 装配四型 | ACTIVE |
| L5 | `RT_Asm_Solv.f90` | **GOLDEN-LINE** — 生产装配 hub | ACTIVE |
| L5 | `RT_Asm_Core.f90` | FACADE — 补充散射操作 | FACADE |
| L5 | `RT_Asm_Brg.f90` | ACTIVE — L3→L5 Populate | ACTIVE |

**L4 缺席说明**: Assembly 在 L4 无独立目录，因为 L4 的 Element/Material/Contact/LoadBC 域各自提供局部 Ke/Fe/Ce/Fe_bc 贡献，L5 Assembly 汇聚这些贡献到全局系统。这是**设计意图**而非遗漏。

**双重 Assembly 语义**:
- L3 Assembly = 部件实例化 (Part Instance)，管理几何装配和 DOF 编号
- L5 Assembly = 全局矩阵装配 (Global K/F Assembly)，汇聚单元贡献

**跨层数据流**: `MD_Assembly_Domain` → `MD_AssemRT_Brg` → `RT_Asm_Desc`（DOF 映射）→ `RT_AsmSolv`（全局 K/F 装配）

---

### L1_IF 基础设施集成 (v3.0)

| 设施 | 集成方式 | 说明 |
|------|---------|------|
| **SymTbl** | `AddNodeSet` 注册 `NSET:{name}` | 建模期 O(1) 查找 |
| **SymTbl** | `AddElemSet` 注册 `ELSET:{name}` | 建模期 O(1) 查找 |
| **SymTbl** | `AddSurface` 注册 `SURF:{name}` | 建模期 O(1) 查找 |
| **SymTbl** | `AddInstance` 注册 `INST:{name}` | 建模期 O(1) 查找 |
| **错误链** | Bridge 出口 `UFC_Err_Wrap` | 见 L1_IF_INTEGRATION.md |

---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_Asm_Mgr.f90` | `MD_Asm_Mgr` | `MD_Instance_Desc`, `MD_SetDef`, `MD_SurfaceDef`, `MD_ConstraintDef`, `MD_Asm_Algo`, `MD_Asm_State`, `MD_Asm_Ctx`, `MD_Assembly_Domain`, `MD_Assembly_Get*_Arg` (7个) | Init, Finalize, Add*(8个), Get*(14个+_Idx 7个), GetSummary, ReleaseConstraintUnion, ReleaseInteractionUnion |
| `MD_Asm_Inst.f90` | `MD_Asm_Inst` | `UF_InstanceDef` | init, bind_part, set_translation, set_rotation, set_rotation_from_points, transform_point, get_global_node_id, get_global_elem_id, get_node_coords, get_local_node_index |
| `MD_Asm_Sync.f90` | `MD_Asm_Sync` | `UF_AssemblyDef`, `UF_Constraint`, `MD_Assembly_AddInstance_Arg`, `MD_Asm_GetInstance_Arg`, `MD_Asm_GetSummary_Arg` | MD_Assembly_SyncFromLegacy, MD_Assembly_MirrorUFConstraintToDomain; UF_Instance_To_MD_Instance, UF_NodeSet/ElemSet/Surface/Constraint_To_MD_* |
| ~~`MD_Asm_Brg.f90`~~ | — | — | 已删除 — 空壳，桥接由 `Bridge_L5/MD_AssemRT_Brg.f90` 承担 |

---

### 版本历史

- v2.0 (2026-04-26) — 全域重构：统一 `MD_Asm_*` 三段式命名，删除原型轨道和门面
- v1.0 (2026-04-20) — 初始版本
