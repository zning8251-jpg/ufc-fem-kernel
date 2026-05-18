# WriteBack 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: WriteBack (状态写回接口)  
**Abbreviation**: WB (`MD_WB_*`, `MD_WriteBack_*`)  
**Version**: v3.1  
**Updated**: 2026-04-30  
**Status**: ✅ ACTIVE (P6 WriteBack 域柱)

### 报告侧：过程算法叙事（stub / archive）

- **入口（根 stub）**：[`WriteBack_Procedure_Algorithm.md`](../../../REPORTS/WriteBack_Procedure_Algorithm.md)；长文：[`archive/WriteBack_Procedure_Algorithm.md`](../../../REPORTS/archive/WriteBack_Procedure_Algorithm.md)。
- **Registry**：[Domain Procedure Registry](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)（与叙事无机器对账；优先级见该 README）。

---

## 1. 域职责定义

### 核心职责
L5_RT 求解完成后将计算结果写回 L3_MD 数据模型的**唯一**合法路径：白名单管理、域路由分派、写回守卫校验、写回操作执行。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 定义允许回写到 L3 的域与字段（白名单枚举） | 不做物理量计算（L4/L5） |
| 白名单校验（仅白名单内字段可写入 L3） | 不做求解器调度 |
| 域路由分派（Step/Amplitude/LoadBC/Mesh/Model/Interaction/Output） | 不做 L4 直接写 L3（须经 L5 转发） |
| NaN 检查与截断 | 不做文件 I/O |
| 写回操作执行（步末/检查点） | 不做关键字解析 |
| 映射注册（source→target field maps） | 不参与 Populate |

### SIO / `*_Arg`（本域偏好）
不强制每个过程使用 `*_Arg`。避免仅承载 `status` 的薄封装。层间边界与 L5 `_Proc` 仍以全仓库 SIO 硬约束为准。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — 白名单枚举、域分类 TYPE、写回映射
- **State**: Y — 与回写字段一致的运行时状态
- **Algo**: Y — 校验/路由逻辑（无单元积分）
- **Ctx**: Y — 回写操作上下文

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_WriteBack_Entry` | `MD_WB_Def` | field_path, domain_name, field_name, domain_id, is_active, requires_lock | 白名单条目 |
| `MD_WriteBack_Target` | `MD_WB_Def` | domain_id, entity_idx, field_slot | 写回目标索引 |
| `MD_WriteBack_Desc` | `MD_WB_Def` | n_maps, maps(:) | 写回映射注册表 |
| `MD_WBMapEntry` | `MD_WB_Def` | source/target/map_type/valid | source→target 字段映射 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_WriteBack_State` | `MD_WB_Def` | active, n_completed, n_failed, current_step | 写回进度状态 |

### 2.3 Algo 类型（算法配置）

| TYPE 名称 | 来源模块 | 说明 |
|-----------|----------|------|
| 校验/路由逻辑 | `MD_WB_Brg` | WB_Guard 白名单校验 + 域路由 |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_WriteBack_Ctx` | `MD_WB_Def` | step_idx, incr_idx, in_progress | 写回操作上下文 |
| `MD_WriteBack_AddEntry_Arg` | `MD_WBDomain` | SIO Arg 封装 | 添加白名单条目 |
| `MD_WriteBack_GetSummary_Arg` | `MD_WBDomain` | SIO Arg 封装 | 获取摘要 |

### 域分类常量（`WB_DOMAIN_*`）
`STEP=1`, `AMPLITUDE=2`, `LOADBC=3`, `MESH=4`, `MODEL=5`, `INTERACTION=6`, `OUTPUT=7`, `ASSEMBLY=8`, `CONSTRAINT=9`, `MATERIAL=10`, `SECTION=11`

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_WB_Def.f90` | `MD_WB_Def` | `_Def` | WriteBack_Entry/Target 类型 + WB_DOMAIN_* 常量 | ACTIVE |
| `MD_WB_Core.f90` | `MD_WB_Core` | `_Core` | MD_WriteBack_Core_Init/Finalize/Register_Map/Get_Map/Get_Count/Validate/Execute | ACTIVE |
| `MD_WB_Domain.f90` | `MD_WBDomain` | Domain | MD_WriteBack_WhiteListDomain: Init/Finalize/AddEntry/IsAllowed/GetSummary | ACTIVE |
| `MD_WB_Mgr.f90` | `MD_WBMgr` | `_Mgr` | Init_WriteBack_WhiteList/Register_WriteBack_Field/Is_WriteBack_Allowed/Finalize_WriteBack_WhiteList | ACTIVE |
| `MD_WB_Brg.f90` | `MD_WB_Brg` | `_Brg` | Init/Finalize_WriteBack_API + MD_WB_SetContainer + WB_Guard + MD_WB_Step/Amplitude/LoadBC/Mesh/Mesh_NodePos/NodeDisp/NodeVel/NodeAcc/ElemStress/Model/Interaction/Output | ACTIVE |

### 已删除模块
- ~~`MD_WriteBack.f90`~~ — 零调用模块（8KB，功能重复）

### 命名修正记录
| CONTRACT 原引用 | 实际文件 |
|-----------------|---------|
| `MD_WriteBack_API.f90` | `MD_WB_Brg.f90` |
| `MD_WriteBack_Mgr.f90` | `MD_WB_Mgr.f90` |
| `MD_WriteBack_Domain_Core.f90` | `MD_WB_Domain.f90` |
| `MD_WriteBack_Types.f90` | `MD_WB_Def.f90` |

---

## 4. 对外接口（公开 API）

### 白名单管理 (MD_WBMgr)
| 接口 | 功能 | 参数 |
|------|------|------|
| `Init_WriteBack_WhiteList` | 初始化白名单 | status |
| `Register_WriteBack_Field` | 注册允许写回的字段 | domain_id, field_name, status |
| `Is_WriteBack_Allowed` | 查询字段是否允许写回 | domain_id, field_name → LOGICAL |
| `Finalize_WriteBack_WhiteList` | 释放白名单 | status |

### 写回分派 (MD_WB_Brg — L5 调用入口)
| 接口 | 功能 |
|------|------|
| `Init_WriteBack_API` / `Finalize_WriteBack_API` | API 生命周期 |
| `MD_WB_SetContainer` | 设置 L3 容器指针（`TARGET`）；路由目标为 **`container%desc%*`** |
| `MD_WB_Step` | 写回 Step 状态（currentTime, currentInc, currentIter） |
| `MD_WB_Amplitude` | 写回幅值（idx, currentValue, currentTime, currentIndex） |
| `MD_WB_LoadBC` | 写回载荷/边界条件 |
| `MD_WB_Mesh` | 写回 Mesh（currentDOF） |
| `MD_WB_Mesh_NodePos/NodeDisp/NodeVel/NodeAcc` | 写回节点场量 |
| `MD_WB_Mesh_ElemStress` | 写回单元应力 |
| `MD_WB_Model` | 写回模型状态（isBuilt, build_timestamp） |
| `MD_WB_Interaction` | 写回接触状态（pair_idx, contactStatus, isActive） |
| `MD_WB_Output` | 写回输出状态（lastWrittenInc, lastWrittenTime, totalFrames） |

### Core 接口
| 接口 | 功能 |
|------|------|
| `MD_WriteBack_Core_Init` / `Finalize` | 四型初始化/释放 |
| `MD_WriteBack_Register_Map` | 注册 source→target 映射 |
| `MD_WriteBack_Get_Map` / `Get_Count` | 映射查询 |
| `MD_WriteBack_Validate` | 映射验证 |
| `MD_WriteBack_Execute` | 执行写回 |

---

## 5. 跨层数据流

```
L5_RT 求解完成（步末/检查点）
  → MD_WB_SetContainer(l3_container)  // L5 设置 L3 容器指针
  → MD_WB_Step/Mesh/Output/...       // 按域分派写回
    → WB_Guard(白名单校验)            // 校验字段是否允许
    → g_l3%desc%<domain>%WriteBack*(...) // 经 MD_L3_LayerContainer%desc 路由
```

### 逻辑链
`L5 Commit → RT_WBImpl → MD_WB_Brg (白名单守卫 + 域路由) → MD_L3_LayerContainer%desc%<domain>%WriteBack`

### 数据链
`L5 State(温) → WriteBack 白名单 → L3 Mesh/Material/Step/Output State(温)`

### 架构约束
- WriteBack 是 **唯一合法** 的 L3 步内变异路径
- L4 不直接写 L3，须经 L5 转发
- 写回时机仅在步末/检查点
- 白名单外字段写入尝试为 FATAL 级错误

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L5_RT/WriteBack | B(桥接) | L5 发起写回请求 |
| R2 | L4_PH/Bridge/WriteBack | B(桥接) | L4 State 经 L5 转发 |
| R3 | L3_MD/Element/Mesh | T(合同) | 写回目标：节点位移/坐标/速度/加速度/单元应力 |
| R4 | L3_MD/Material | T(合同) | 写回目标：应力/历史变量 |
| R5 | L3_MD/Model | S(消费) | 模型容器引用（isBuilt 等） |
| R6 | L3_MD/Output | T(合同) | 写回目标：lastWrittenInc/Time/Frames |
| R7 | L3_MD/Interaction | T(合同) | 写回目标：接触状态 |
| R8 | L3_MD/Analysis/Step | T(合同) | 写回目标：Step 时间/增量 |
| R9 | L1_IF/Error | U(USE) | 错误码定义 |

### 跨层域柱

| 层 | 模块 | 角色 |
|----|------|------|
| L3 | `MD_WB_Def.f90` | 白名单类型 / AUTHORITY |
| L3 | `MD_WB_Core.f90` | 映射管理 |
| L3 | `MD_WB_Domain.f90` | SIO 域逻辑 |
| L3 | `MD_WB_Mgr.f90` | 白名单管理器 |
| L3 | `MD_WB_Brg.f90` | L5→L3 分派桥接 |
| L4 | `PH_WB` | AUTHORITY for physics write-back |
| L5 | `RT_WB_Def` | AUTHORITY for runtime WB types |

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_WRITEBACK_xxx` (31400–31499) |
| 严重级 | WARNING: 写回字段值为 NaN(截断); ERROR: 写回目标域未初始化; FATAL: 白名单外字段写入尝试 |
| 传播规则 | 经 `status` 参数返回；FATAL 级上报后由 L5 决定是否 STOP |
| 恢复策略 | WARNING：日志+截断为零; ERROR：跳过该域写回 |

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 状态回写理论→白名单约束→数据一致性 |
| **逻辑链** | L5 Commit→RT_WBImpl→MD_WB_Brg(Guard+Route)→各目标域 State |
| **计算链** | L3 无计算；仅数据搬运 + 校验 |
| **数据链** | L5 State(温)→WriteBack 白名单→L3 Mesh/Material/Step/Output State(温) |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 仅白名单字段可写入 L3 | 硬 | WriteBack 网关校验 | — |
| WriteBack 为唯一合法 L3 步内变异路径 | 硬 | Code Review | — |
| 禁止 L4 直接写 L3（须经 L5 转发） | 硬 | Harness | H-DEP-03 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 写回时机仅在步末/检查点 | 软 | Code Review | — |

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.0 | 2026-04-26 | Domain Pillar v2.0 对齐；命名修正 |
| v3.1 | 2026-04-30 | P1 竖切：**`MD_WriteBack_Ctx`** 扁平字段（修 `ctx%inc%*` 笔误）；**`MD_WB_Brg`** / **`Init_WriteBack_API`** 统一走 **`md_layer%desc%writeback`** 与 **`g_l3%desc%<domain>`**；Core Init/Finalize 复位 **ctx/state** 计数 |
| v3.0 | 2026-04-28 | 标准化为 7 章节格式 |
