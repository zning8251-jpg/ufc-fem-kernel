# Bridge 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: Bridge (L3-L4-L5 桥接协调)  
**Prefix**: `RT_Brg_*`  
**Version**: v2.1  
**Created**: 2026-04-26  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 Bridge 域，L3 模型数据↔L4 物理计算↔L5 运行时之间的桥接与路由
- **职责**:
  - Populate 编排：L3→L4 各域 Populate 调用路由
  - Slot 分发：L3 模型数据写入 L4 物理域 slot
  - 版本对齐：L3/L4/L5 之间版本兼容检查
  - 多域桥接上下文管理（Material/Element/Load/BC/Contact/Friction/Constraint/Field/Analysis/Mesh/Step）
  - 域生命周期管理（Init/SyncStepIncr/Finalize）

### 非职责
- 不执行实际物理计算（L4 负责）
- 不管理运行时计算状态（各 L5 域自行管理）
- Bridge 自身无状态（无持久 State/Algo/Ctx 实例）

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| (域级桥接 Ctx) | `RT_Brg_Def` | 各域桥接映射表、路由规则 | 作为配置使用 |

### 2.2 State
- **N/A** — Bridge 无状态

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| (内嵌) | — | 路由策略(直接/间接/降级) | 内嵌于 Core 过程 |

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Mat_Bridge_Ctx` | `RT_Brg_Def` | ... | 材料桥接上下文 |
| `RT_Elem_Bridge_Ctx` | `RT_Brg_Def` | ... | 单元桥接上下文 |
| `RT_Load_Bridge_Ctx` | `RT_Brg_Def` | ... | 载荷桥接上下文 |
| `RT_BC_Bridge_Ctx` | `RT_Brg_Def` | ... | BC 桥接上下文 |
| `RT_Contact_Bridge_Ctx` | `RT_Brg_Def` | ... | 接触桥接上下文 |
| `RT_Fric_Bridge_Ctx` | `RT_Brg_Def` | ... | 摩擦桥接上下文 |
| `RT_Constr_Bridge_Ctx` | `RT_Brg_Def` | ... | 约束桥接上下文 |
| `RT_Field_Bridge_Ctx` | `RT_Brg_Def` | ... | 场桥接上下文 |
| `RT_Analy_Bridge_Ctx` | `RT_Brg_Def` | ... | 分析桥接上下文 |
| `RT_Mesh_Bridge_Ctx` | `RT_Brg_Def` | ... | 网格桥接上下文 |
| `RT_Step_Bridge_Ctx` | `RT_Brg_Def` | ... | 步桥接上下文 |
| `RT_Bridge_Ctx` | `RT_Brg` | ... | 总桥接上下文 |
| `RT_Bridge_Domain` | `RT_Brg` | ... | 域级桥接容器(TBP: Init/SyncStepIncr/Finalize/GetSummary) |

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `RT_Brg_Def.f90` | `RT_Brg_Def` | `_Def` (TYPE) | 11 个域级 Bridge Ctx TYPE + `RT_Bridge_Init`（末尾对 Mat/Elem 调用 `Sync_Aux`）/ `RT_Mat_*`·`RT_Elem_*` 镜像同步 + SetReady/SetDone | **ACTIVE** |
| `RT_Asm_Brg.f90` | `RT_Asm_Brg` | Assembly Brg | `RT_Asm_Brg_ApplyMatBridge_Flat_IP` / `ApplyElemBridge_Flat_IP`（扁平赋值 + `Sync_Aux`）；`RT_Asm_Brg_Sync*Mirror` 薄封装 | **ACTIVE** |
| `RT_Brg_Mgr.f90` | `RT_Brg` | Domain 容器 | RT_Bridge_Domain(TBP: Init/SyncStepIncr/Finalize/GetSummary) + RT_Bridge_GetSummary_Impl | **ACTIVE** |
| `Shared/` | — | 共享 | 跨域共享桥接工具 | **ACTIVE** |

---

## 4. 对外接口（公开 API）

### 域级生命周期

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `RT_Bridge_Domain_Init` | `RT_Brg` | 桥接域初始化 |
| `RT_Bridge_Domain_SyncStepIncr` | `RT_Brg` | 步/增量同步 |
| `RT_Bridge_Domain_Finalize` | `RT_Brg` | 桥接域清理 |
| `RT_Bridge_Domain_GetSummary` | `RT_Brg` | 摘要/诊断 |

### Populate 控制

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `RT_Bridge_Init` | `RT_Brg_Def` | 桥接初始化 |
| `RT_Bridge_SetReady` | `RT_Brg_Def` | 标记就绪 |
| `RT_Bridge_SetDone` | `RT_Brg_Def` | 标记完成 |
| `RT_Mat_Bridge_Sync_Aux_From_Deprecated` 等 | `RT_Brg_Def` | 仅写扁平字段后，将镜像复制到 `%stp`/`%lcl`（或反向 `Sync_Deprecated_From_Aux`） |
| `RT_Asm_Brg_ApplyMatBridge_Flat_IP` / `RT_Asm_Brg_ApplyElemBridge_Flat_IP` | `RT_Asm_Brg` | 装配层推荐入口：**先写** `RT_*_Bridge_Ctx%stp` / `%lcl` **真源**，再 **`Sync_Deprecated_From_Aux`** 镜像 UMAT/UEL 风格平场（`ufc-layer-l3-l4-l5-pilot` §15.5） |
| `RT_Asm_Brg_ElemMatPtIdx` | `RT_Asm_Brg` | 从 `g_ufc_global%ph_layer%element%elem_to_mat_map` 解析 `mat_pt_idx`（供 `RT_Asm_GlobalStiffness` 填 `ke_arg`） |

### 4.1 主辅 TYPE 与 `*_Arg` 对照（Mat / Elem Bridge）

| 主 TYPE | 辅 TYPE（Depth 2） | 平场 DEPRECATED | 装配侧 SIO / 入口 |
|---------|-------------------|-----------------|-------------------|
| `RT_Mat_Bridge_Ctx` | `RT_Mat_Stp_Ctl_BrgCtx`（`%stp`）、`RT_Mat_Lcl_Brg_Ctx`（`%lcl`） | `mat_id`、`mat_family` 等与 `%stp/%lcl` 镜像 | `RT_Asm_Brg_ApplyMatBridge_Flat_IP` → 先 `%stp/%lcl` 再 `Sync_Deprecated_From_Aux` |
| `RT_Elem_Bridge_Ctx` | `RT_Elem_Stp_Ctl_BrgCtx`、`RT_Elem_Lcl_Brg_Ctx` | `elem_id`、`lflags` 等镜像 | `RT_Asm_Brg_ApplyElemBridge_Flat_IP` 同上 |

**去废弃（Step4）**：须满足 §12.3（主分支 N≥5 绿构建或发布窗口）后，再删除 `RT_*_Bridge_Ctx` 上 DEPRECATED 平场成员；删除前 grep 确认无直接 `%mat_id` 等访问。

---

## 5. 跨层数据流

### Populate 编排流（冷路径）
```
L3_MD (各域 *_Desc 真源)
  → RT_Bridge_Init()          ← 桥接初始化
    → L4_PH Populate          ← 各域 slot 填充
      → RT_Bridge_SetReady()  ← 标记就绪
```

### 逻辑链
```
L3_MD (Desc真源) → Bridge (路由/版本适配) → L4_PH (Populate填充) → L5 各域消费
```

### 四链说明

| 链 | 说明 |
|----|------|
| **理论链** | 桥接模式无自有理论；职责为 L3 模型数据→L4 物理域的忠实传递与版本对齐 |
| **逻辑链** | L3_MD (Desc真源) → Bridge (路由/版本适配) → L4_PH (Populate填充) → L5 各域消费 |
| **计算链** | 无计算；仅执行 slot 分发与类型映射，O(N_domains) 冷路径 |
| **数据链** | L3 `*_Desc`(冷) → Bridge 路由 → L4 `*_Domain` slot(冷→热转换点) |

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Bridge | T (类型消费) | 消费 L3 侧桥接 Desc，Populate 数据源 |
| R2 | L4_PH/Bridge | T (类型消费) | 路由到 L4 侧 Populate，填充物理域 slot |
| R3 | L5_RT/Assembly | S (同层服务) | 为 Assembly 提供 slot 输入 |
| R4 | L5_RT/Solver | S (同层服务) | 为 Solver 提供路由后的域配置 |
| R5 | L1_IF | U (基础设施) | IF_Prec_Core/IF_IO_API |

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 热路径零 L3（Populate 后不直读 L3） | **硬** | 代码审查 + 静态分析 | CI |
| 不使用 STOP | **硬** | grep 扫描 | CI |
| Bridge 无状态（不持有 State/Algo/Ctx 实例） | **硬** | 架构审查 | PR |
| slot 分发须版本对齐 | **硬** | 单元测试 | CI |

### 错误处理

| 错误码范围 | 错误场景 | 严重级 | 恢复策略 |
|------------|----------|--------|----------|
| ERR_L5_BRIDGE_50100 | Populate 路由目标未注册 | ERROR | 跳过 + 警告 |
| ERR_L5_BRIDGE_50101 | L3→L4 版本不兼容 | ERROR | 降级或终止 |
| ERR_L5_BRIDGE_50102 | slot 分发失败 | ERROR | 终止 Populate |
| ERR_L5_BRIDGE_50103 | 类型注册表溢出 | WARNING | 忽略多余 |

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 11 域桥接 Ctx | RT_Brg_Def 包含 Mat/Elem/Load/BC/Contact/Fric/Constr/Field/Analy/Mesh/Step | ✅ 已实现 |
| A2 | Domain 容器 | RT_Bridge_Domain TBP 完整 | ✅ 已实现 |
| A3 | 生命周期管理 | Init/SyncStepIncr/Finalize | ✅ 已实现 |
| A4 | Populate 控制 | Init/SetReady/SetDone | ✅ 已实现 |
| A5 | 无状态设计 | Bridge 不持有持久状态 | ✅ 已实现 |
| A6 | 错误传播 | ErrorStatusType，不使用 STOP | ✅ 已实现 |
| A7 | 版本对齐 | slot 分发前版本检查 | ✅ 已实现 |
| A8 | 单元测试 | 待建 | 待补全 |
