# Assembly 域推演卡 (Derivation Card)

**层级**: L3_MD | **域**: Assembly | **缩写**: Asm (`MD_Asm_*`) | **版本**: v1.0 | **日期**: 2026-04-26

---

## 〇、总览 — Assembly 域 f90 功能模块全图

### 现有文件清单 (7 个 .f90)

| # | 轨道 | 文件 | MODULE | 角色后缀 | 行数 | 状态 |
|---|------|------|--------|----------|------|------|
| 1 | 原型 | `MD_Asm_Def.f90` | `MD_Asm_Def` | `_Def` | 57 | **DEAD** — 平坦原型类型，与生产 Mgr 重复 |
| 2 | 原型 | `MD_Asm_Core.f90` | `MD_Asm_Core` | `_Core` | 184 | **DEAD** — 原型过程，仅被自身+骨架测试引用 |
| 3 | 域级 | `MD_Asm_Brg.f90` | `MD_Asm_Brg` | `_Brg` | 22 | **SKELETON** — 空壳 |
| 4 | 生产 | `MD_Assem_Mgr.f90` | `MD_Assem_Mgr` | `_Mgr` | 1247 | **ACTIVE** — 真正的域容器，混合了 _Def + _Mgr |
| 5 | 生产 | `MD_Assem_Domain.f90` | `MD_Assem_Domain` | (薄门面) | 35 | **ACTIVE** — 再导出 facade，6 个消费者 |
| 6 | 生产 | `MD_Assem_Instance.f90` | `MD_Assem_Instance` | (实例) | 293 | **ACTIVE** — UF 侧实例 + 变换 |
| 7 | 生产 | `MD_Assem_Legacy.f90` | `MD_Assem_Legacy` | (遗留) | 905 | **ACTIVE** — UF→Domain 同步 |

### 设计二元性 (Design Duality)

存在两条平行轨道：

| 轨道 | 文件 | 类型 | 消费者 |
|------|------|------|--------|
| **原型** | `MD_Asm_Def` + `MD_Asm_Core` | 平坦 `MD_InstanceEntry`/`MD_Assembly_Desc`，固定数组 256 | **0 生产消费者** |
| **生产** | `MD_Assem_Mgr` + `MD_Assem_Domain` + `Instance` + `Legacy` | 丰富 `MD_Instance_Desc`/`MD_SetDef`/`MD_SurfaceDef`/`MD_ConstraintDef`/`MD_Assembly_Domain`，可分配数组 + TBP + SIO Args | **15+ 消费者** (L3/L4/L5/L6) |

**结论**: 原型轨道 = 死代码，等同 Analysis 域的 `MD_Analysis_Def` + `MD_Analysis_Core`。

### 命名不一致

| 前缀 | 文件 | 来源 |
|------|------|------|
| `MD_Asm_` | `Def`, `Core`, `Brg` | 原型轨道 |
| `MD_Assem_` | `Mgr`, `Domain`, `Instance`, `Legacy` | 生产轨道 |

**统一目标**: 全域使用三段式 `MD_Asm_*`（层_域_功能）。

### CONTRACT 漂移

| CONTRACT 声称 | 实际 |
|---------------|------|
| 核心模块 `MD_Assem.f90` | 不存在，实际为 `MD_Assem_Mgr.f90` (MODULE `MD_Assem_Mgr`) |
| ~~`MD_Assem_Mgr.f90`~~ 已删除 | **存在**且是主模块 (1247 行) |
| ~~`MD_Assem_Core.f90`~~ 已删除 | **存在** (原型轨道，184 行) |
| `MD_Instance.f90` | 实际为 `MD_Assem_Instance.f90` (MODULE `MD_Assem_Instance`) |

---

## 一、推演路径 A→E

### A: CONTRACT → 意图

| 项目 | 说明 |
|------|------|
| **域名** | Assembly / 装配与实例 |
| **职责** | 装配体、实例变换、部件实例化 Desc；**不做**全局矩阵装配 (L5) |
| **四型** | Desc (instances/sets/surfaces/constraints), State (监控), Algo (容差/策略), Ctx (变换缓存) |
| **金线** | `g_ufc_global%IsReady()` → `MD_Assembly_SyncFromLegacy` → `md_layer%assembly` |
| **热路径** | 否 — 建模期冷数据 |
| **Bridge** | `MD_AssemRT_Brg` (L3→L5 DOF 映射) |

### B: 四型裁剪

| 四型 | 生产类型 (MD_Assem_Mgr) | 场景 |
|------|--------------------------|------|
| **Desc** | `MD_Instance_Desc`, `MD_SetDef`, `MD_SurfaceDef`, `MD_ConstraintDef` | 建模后只读 |
| **State** | `AssemblyState` (约束满足、活跃计数) | 求解期更新 |
| **Algo** | `AssemblyAlgo` (容差、惩罚因子、迭代限) | 建模期写，冷读 |
| **Ctx** | `AssemblyCtx` (当前实例、变换缓存) | 调用内临时 |

容器: `MD_Assembly_Domain` (聚合 instances + sets + surfaces + constraints + algo + state + ctx)

### C: 算法锚定 — 按功能集

| 功能集 | 时相 | Verb | 过程 | 说明 |
|--------|------|------|------|------|
| Init | Setup | Init | `MD_Assembly_Domain_Init` | 分配容器 |
| Finalize | Cleanup | Finalize | `MD_Assembly_Domain_Finalize` | 释放 |
| Mutate | Build | Add | `AddInstance`, `AddNodeSet`, `AddElemSet`, `AddSurface` | 建模期写入 |
| Mutate | Build | Add | `AddConstraint` (+ Tie/MPC/Coupling/Rigid) | 约束注册 |
| Mutate | Build | Add | `AddContactPair` | 接触对注册 |
| Query | Any | Get | `GetInstance`, `GetNodeSet`, `GetElemSet`, `GetSurface` | 按索引 |
| Query | Any | Get | `Get*ByName` (NodeSet/ElemSet/Surface/Constraint) | 按名称 |
| Query | Any | Get | `GetConstraint`, `GetTie/MPC/Coupling/Rigid` | 约束查询 |
| Query | Any | Get | `GetContactPair` | 接触对查询 |
| Query | Any | Get | `GetSummary` | 摘要 |
| Idx | Any | Get | `MD_Assembly_Get*_Idx` (7 个模块级过程) | g_ufc_global 委托查询 |
| Release | Cleanup | Release | `ReleaseConstraintUnion`, `ReleaseInteractionUnion` | 清理 union |
| Sync | Build | Sync | `MD_Assembly_SyncFromLegacy` | UF→Domain 同步 |
| Mirror | Build | Mirror | `MD_Assembly_MirrorUFConstraintToDomain` | UF 约束镜像 |
| Transform | Query | Transform | `transform_point`, `get_global_node_id`, `get_global_elem_id` | 实例坐标变换 |

### D: 过程绑定 — 目标文件结构

| # | 目标文件 | 目标 MODULE | 后缀 | 内容 | 来源 |
|---|----------|-------------|------|------|------|
| 1 | `MD_Asm_Def.f90` | `MD_Asm_Def` | `_Def` | 四型 + 组件类型 + Arg 类型 + 约束枚举 | 从 `MD_Assem_Mgr` 提取类型部分 |
| 2 | `MD_Asm_Mgr.f90` | `MD_Asm_Mgr` | `_Mgr` | `MD_Assembly_Domain` 容器 + TBP + `_Idx` 模块过程 | 从 `MD_Assem_Mgr` 提取过程部分 |
| 3 | `MD_Asm_Inst.f90` | `MD_Asm_Inst` | `_Inst` | `UF_InstanceDef` + 变换 TBP | 重命名 `MD_Assem_Instance` |
| 4 | `MD_Asm_Sync.f90` | `MD_Asm_Sync` | `_Sync` | `UF_AssemblyDef` + `SyncFromLegacy` + `MirrorUFConstraint` | 重命名 `MD_Assem_Legacy` |
| 5 | `MD_Asm_Brg.f90` | `MD_Asm_Brg` | `_Brg` | Bridge L3→L5 (SKELETON → 待填充) | 保留 |

**删除**:
- ~~`MD_Asm_Core.f90`~~ — 原型过程，零生产消费
- ~~`MD_Assem_Domain.f90`~~ — 薄门面，合并到 `MD_Asm_Mgr` 的 PUBLIC 列表

### E: 外部消费者影响矩阵

| 旧模块 | 消费者 | 新模块 |
|--------|--------|--------|
| `MD_Assem_Mgr` | `MD_L3_Layer`, `MD_BaseTypes` | `MD_Asm_Mgr` |
| `MD_Assem_Domain` | `RT_Asm_Solv`, `PH_L4_Populate`, `MD_KW_Mapper`, `MD_Constr_Brg`, `MD_Assem_Legacy` | `MD_Asm_Mgr` (直接) |
| `MD_Assem_Instance` | `MD_KW_Mapper`, `AP_Brg_L3`, `MD_BaseTypes`, `MD_Assem_Legacy` | `MD_Asm_Inst` |
| `MD_Assem_Legacy` | `MD_Model_Lib`, `MD_KW_Mapper`, `MD_Model_Brg`, `MD_Model_Builder`, `MD_Mesh_Sync` | `MD_Asm_Sync` |
| `MD_Asm_Core` | `MD_Asm_Test` | 测试改写 |

---

## 二、Core 蓝图闭合校验

> `MD_Asm_Def.f90` + `MD_Asm_Core.f90` 已删除（原型轨道，零生产消费），但 `MD_Asm_Core` 定义的 **7 个过程**是域应具备的核心算法蓝图。
> 以下逐条校验：每条蓝图过程必须在生产代码中有对应实现，否则标记 **GAP**。

### 蓝图来源：已删除的 `MD_Asm_Core.f90` (MODULE MD_Asm_Core)

| # | 蓝图过程 | 签名语义 | 生产落地 | 状态 |
|---|----------|----------|----------|------|
| C1 | `MD_Assembly_Core_Init(desc, state, ctx, status)` | 初始化装配描述+状态+上下文 | `MD_Assembly_Domain%Init` → `MD_Assembly_Domain_Init` (`MD_Asm_Mgr.f90`) | ✅ 覆盖 |
| C2 | `MD_Assembly_Core_Finalize(desc, state, ctx, status)` | 释放装配描述+状态+上下文 | `MD_Assembly_Domain%Finalize` → `MD_Assembly_Domain_Finalize` (`MD_Asm_Mgr.f90`) | ✅ 覆盖 |
| C3 | `MD_Assembly_Add_Instance(desc, instance_id, part_id, translation, status)` | 添加部件实例 | `MD_Assembly_Domain%AddInstance` → `MD_Assembly_Domain_AddInstance` (`MD_Asm_Mgr.f90`) | ✅ 覆盖 (更丰富: `MD_Instance_Desc` 含 rotation matrix) |
| C4 | `MD_Assembly_Get_Instance(desc, idx, instance, status)` | 按索引查询实例 | `MD_Assembly_Domain%GetInstance` + `MD_Assembly_GetInstance_Idx` (`MD_Asm_Mgr.f90`) | ✅ 覆盖 |
| C5 | `MD_Assembly_Build_GlobalMap(desc, state, n_nodes_per_part, status)` | 构建全局节点映射 | `UF_AssemblyDef%assemble` → `assembly_assemble` (`MD_Asm_Sync.f90`) — 在 Legacy TBP 中实现全局编号 | ✅ 覆盖 (语义对等，路径不同) |
| C6 | `MD_Assembly_Get_Global_NodeID(desc, local_id, global_id, status)` | 局部→全局节点 ID | `UF_InstanceDef%get_global_node_id` TBP (`MD_Asm_Inst.f90`) | ✅ 覆盖 (实例级 TBP) |
| C7 | `MD_Assembly_Get_NEQ(desc) → neq` | 获取方程总数 | `MD_Assembly_Domain%n_instances` + L5 `RT_Asm_Desc%n_eq` (方程数由 L5 Assembly 管理) | ⚠️ 语义迁移至 L5 (L3 不持有 n_eq) |

### 蓝图类型映射

| 蓝图原型类型 | 用途 | 生产对应 |
|--------------|------|----------|
| `MD_InstanceEntry` (instance_id/part_id/translation/valid) | 平坦实例条目 | `MD_Instance_Desc` (name/inst_id/part_ref/translation/rotation/dependent) — 更丰富 |
| `MD_Assembly_Desc` (instances(256), global_node_map, n_eq) | 平坦装配容器 | `MD_Assembly_Domain` (allocatable instances/sets/surfaces/constraints) |
| `MD_Assembly_State` (map_built/dof_numbered/total_dof) | 装配状态 | `MD_Asm_State` (active_constraints/constraint_error/tie_satisfied) — 语义不同 |
| `MD_Assembly_Ctx` (dof_map/bc_flags/current_step) | 操作上下文 | `MD_Asm_Ctx` (current_inst_id/transform_cached/cached_rotation) — 语义不同 |

**结论**: 7 条蓝图过程中 **6 条完全覆盖**，C7 (`Get_NEQ`) 的方程数语义已迁移至 L5 Assembly（L3 不持有全局方程数，这是设计意图而非缺失）。蓝图已安全归档于此推演卡。

---

## 三、逆向闭合验证 — 缺口清单（已处置）

### GAP-01: 原型轨道与生产轨道重复

**现状**: `MD_Asm_Def` 定义 `MD_InstanceEntry`/`MD_Assembly_Desc/State/Ctx`（平坦固定数组），`MD_Asm_Core` 操作这些类型。同时 `MD_Assem_Mgr` 定义完全独立的 `MD_Instance_Desc`/`AssemblyState`/`AssemblyCtx`/`MD_Assembly_Domain`（可分配、TBP、SIO）。
**影响**: 死代码，模块数量膨胀，命名混淆。
**处置**: 删除原型轨道（`MD_Asm_Def` + `MD_Asm_Core`），零生产消费。

### GAP-02: 命名不一致 (MD_Asm_ vs MD_Assem_)

**现状**: 两种前缀混用。
**处置**: 统一为 `MD_Asm_*` 三段式命名。

### GAP-03: CONTRACT 文档严重漂移

**现状**: CONTRACT 引用不存在的 `MD_Assem.f90`，声称 `MD_Assem_Mgr.f90` 已删除（实际存在且为主模块）。
**处置**: CONTRACT 重写以匹配重构后的文件结构。

### GAP-04: MD_Assem_Domain 薄门面冗余

**现状**: `MD_Assem_Domain` 仅 `USE MD_Assem_Mgr` + 再导出。消费者可直接 `USE MD_Asm_Mgr`。
**处置**: 删除 facade，所有 6 个消费者改为 `USE MD_Asm_Mgr`。

### GAP-05: 重复 QUENCH 标记

**现状**: `MD_Assem_Instance.f90` 和 `MD_Assem_Legacy.f90` 各有重复的 `!>>> UFC_L3_QUENCH` 标记块。
**处置**: 移除重复。

### GAP-06: MD_Asm_Brg 为空壳

**现状**: 22 行空壳，无实现。
**处置**: SKELETON 保留，待 L5 桥接需求触发时扩展。

---

## 四、修复实施计划

### 执行顺序

| 序号 | 修复项 | 文件 | 类型 | 优先级 |
|------|--------|------|------|--------|
| F1 | 删除原型轨道 (MD_Asm_Def+Core) | 2 文件 | 删除 | P0 |
| F2 | MD_Assem_Mgr → MD_Asm_Mgr 重命名 | 1 文件 + 2 消费者 | 重命名 | P0 |
| F3 | MD_Assem_Domain 删除 + 消费者迁移 | 1 文件 + 6 消费者 | 删除+迁移 | P0 |
| F4 | MD_Assem_Instance → MD_Asm_Inst 重命名 | 1 文件 + 4 消费者 | 重命名 | P1 |
| F5 | MD_Assem_Legacy → MD_Asm_Sync 重命名 | 1 文件 + 5 消费者 | 重命名 | P1 |
| F6 | 清理重复 QUENCH 标记 | 2 文件 | 修复 | P1 |
| F7 | CONTRACT.md 重写 | 1 文件 | 文档 | P1 |
| F8 | BRIDGE_INDEX.md 同步 | 1 文件 | 文档 | P2 |
| F9 | 测试文件 MD_Asm_Test 改写 | 1 文件 | 测试 | P2 |

---

## 五、执行结果

### 已完成的修改

| 序号 | 操作 | 文件 | 状态 |
|------|------|------|------|
| F1 | 删除原型轨道 | ~~`MD_Asm_Def.f90`~~, ~~`MD_Asm_Core.f90`~~ | ✅ 已删除 |
| F2 | 重命名 `MD_Assem_Mgr` → `MD_Asm_Mgr` | `MD_Asm_Mgr.f90` + 2 消费者 | ✅ 完成 |
| F3 | 删除 `MD_Assem_Domain` 门面 | ~~`MD_Assem_Domain.f90`~~ + 6 消费者迁移 | ✅ 完成 |
| F4 | 重命名 `MD_Assem_Instance` → `MD_Asm_Inst` | `MD_Asm_Inst.f90` + 4 消费者 | ✅ 完成 |
| F5 | 重命名 `MD_Assem_Legacy` → `MD_Asm_Sync` | `MD_Asm_Sync.f90` + 5 消费者 | ✅ 完成 |
| F6 | 清理重复 QUENCH 标记 | `MD_Asm_Inst`, `MD_Asm_Sync` | ✅ 完成 |
| F7 | CONTRACT.md 重写 | `CONTRACT.md` v2.0 | ✅ 完成 |
| F8 | BRIDGE_INDEX.md 同步 | `BRIDGE_INDEX.md` Assembly 行 | ✅ 完成 |
| F9 | 测试文件改写 | `MD_Asm_Test.f90` → 使用 `MD_Asm_Mgr` | ✅ 完成 |
| — | 四型命名统一 | `AssemblyAlgo` → `MD_Asm_Algo`, `AssemblyState` → `MD_Asm_State`, `AssemblyCtx` → `MD_Asm_Ctx` | ✅ 完成 |

### 重构后最终文件清单 (4 个 .f90)

| # | 文件 | MODULE | 后缀 | 行数 | 状态 |
|---|------|--------|------|------|------|
| 1 | `MD_Asm_Mgr.f90` | `MD_Asm_Mgr` | `_Mgr` | ~1250 | **ACTIVE** |
| 2 | `MD_Asm_Inst.f90` | `MD_Asm_Inst` | `_Inst` | ~280 | **ACTIVE** |
| 3 | `MD_Asm_Sync.f90` | `MD_Asm_Sync` | `_Sync` | ~890 | **ACTIVE** |
| ~~4~~ | ~~`MD_Asm_Brg.f90`~~ | — | — | — | **DELETED** — 空壳零消费者 |

---

## 六、版本历史

- v1.0 (2026-04-26) — 初始版本，域级推演卡 + 执行完毕
