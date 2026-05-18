# WriteBack 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: WriteBack (状态变量回写与数据映射)  
**Prefix**: `RT_WB_*`, `RT_WriteBack_*`  
**Version**: v2.1  
**Created**: 2026-04-26  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 WriteBack 域，计算结果→模型树的回写与状态管理
- **职责**:
  - 位移回写：节点位移/坐标更新 (NodePos/NodeDisp)
  - 应力/应变回写：Gauss 点→单元/节点映射 (ElemStress/ElemStrain)
  - 状态变量回写：塑性应变/损伤等 SDV (ElemEplas/GPStateVar)
  - 反力/能量汇总
  - Checkpoint/Restart：状态序列化、Checksum 验证、回滚
  - 白名单审计：仅允许注册目标接收回写
  - 与 Output 协调保存

### 非职责
- 不定义输出格式（L6 AP）
- 不直接写文件（Output/Writers）
- 不执行物理计算（L4_PH）

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_WB_Base_Desc` | `RT_WB_Def` | 回写变量列表、映射规则、汇总策略 | TBP: Init/SetOutputFields/SetScope |

### 2.2 State

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `CheckpointStatus` | `RT_WBDomain` | ... | Checkpoint 状态 |
| `WriteBackAuditRecord` | `RT_WBDomain` | ... | 审计记录 |

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_WB_Stp_Ctl_Algo` | `RT_WB_Aux_Def` | write_trigger, trigger_at_step_end, trigger_at_analysis_end, save_checkpoint_on_write, checkpoint_interval, validate_before_write, checksum_enabled, force_write_back, suppress_all_wb, nan_policy | 步级写回触发/策略/验证控制（P2 补全，[Phase:Stp|Verb:Ctl]） |
| `RT_WB_Itr_Algo` | `RT_WB_Aux_Def` | use_node_buffering, use_elem_buffering, node/elem_buffer_capacity, compress_output, compression_level, use_parallel_write, n_write_threads, batch_small_writes, batch_threshold, audit_enabled, detailed_audit, max_audit_records | 迭代级缓冲/压缩/审计控制（P2 补全，[Phase:Itr|Verb:Com]） |
| `RT_WB_Algo` | `RT_WB_Def` | stp_ctl(`RT_WB_Stp_Ctl_Algo`) + itr_algo(`RT_WB_Itr_Algo`) + legacy flat fields | 写回算法控制参数（嵌入子 Algo + legacy 兼容） |

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `WriteBackCtx` | `RT_WBDomain` | 回写上下文、内存池、并行分区 | 含 Buffer attach/clear/flush |

**权威 TYPE 模块**: `RT_WB_Def.f90` (ACTIVE, AUTHORITY) / `RT_WB_Aux_Def.f90` (ACTIVE, AUX-DEF for P2 sub-Algo)
**金线域逻辑**: `RT_WB_Domain.f90` (ACTIVE, GOLDEN-LINE)

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `RT_WB_Aux_Def.f90` | `RT_WB_Aux_Def` | `_Aux_Def` (辅Algo定义) | RT_WB_Stp_Ctl_Algo + RT_WB_Itr_Algo | **ACTIVE** (P2 GAP-FILL) |
| `RT_WB_Def.f90` | `RT_WB_Def` | `_Def` (TYPE) | RT_WB_Base_Desc(TBP), WBProgress/WBBuffer/WBAlgo/WBCtx/WBTransform 辅助 | **ACTIVE** (AUTHORITY) |
| `RT_WB_Domain.f90` | `RT_WBDomain` | Domain 容器 | RT_WriteBack_Domain(TBP: Init/Finalize), WriteState/SaveCheckpoint/LoadCheckpoint/RollbackToCheckpoint/ValidateWriteBack/AuditWriteBack + NodePos/NodeDisp/ElemStress/ElemStrain/ElemEplas/NodeAccel/GPStateVar/CurrentTime | **ACTIVE** (GOLDEN-LINE) |
| `RT_WB_Impl.f90` | `RT_WBImpl` | `_Impl` | RT_WB_Impl_Init/NodePos/NodeDisp/ElemStress/Checkpoint + ComputePrincipalStresses/VonMises | **ACTIVE** |
| `RT_WB_Proc.f90` | `RT_WBProc` | `_Proc` (SIO) | 5 组 _In/_Out (Init/NodePos/NodeDisp/ElemStress/Checkpoint) | **ACTIVE** |
| `RT_WB_Brg.f90` | `RT_WriteBack_Brg` | `_Brg` (桥接) | FromL5/ToL4/ToL3 桥接 | **ACTIVE** |
| `RT_WB_Core.f90` | — | `_Core` | LEGACY/FACADE | **LEGACY** |

---

## 4. 对外接口（公开 API）

### 回写接口

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `RT_WriteBack_NodePos` | `RT_WBDomain` | 节点坐标回写 |
| `RT_WriteBack_NodeDisp` / `_Batch` | `RT_WBDomain` | 节点位移回写（单/批量） |
| `RT_WriteBack_ElemStress` | `RT_WBDomain` | 单元应力回写 |
| `RT_WriteBack_ElemStrain` | `RT_WBDomain` | 单元应变回写 |
| `RT_WriteBack_ElemEplas` | `RT_WBDomain` | 塑性应变回写 |
| `RT_WriteBack_NodeAccel` | `RT_WBDomain` | 节点加速度回写 |
| `RT_WriteBack_GPStateVar` | `RT_WBDomain` | GP 状态变量回写 |
| `RT_WriteBack_CurrentTime` | `RT_WBDomain` | 当前时间回写 |

### Checkpoint 接口

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `SaveCheckpoint` / `_WithSolution` | `RT_WBDomain` | 保存 Checkpoint |
| `LoadCheckpoint` | `RT_WBDomain` | 加载 Checkpoint |
| `RollbackToCheckpoint` | `RT_WBDomain` | 回滚到 Checkpoint |
| `ValidateWriteBack` | `RT_WBDomain` | 回写一致性验证 |
| `AuditWriteBack` | `RT_WBDomain` | 审计回写记录 |

---

## 5. 跨层数据流

### 回写数据流
```
L5_RT/Solver (u, sigma, stateVars)  ← 求解结果
  → RT_WriteBack_Domain (步末触发)
    → RT_WriteBack_NodeDisp/ElemStress/GPStateVar  ← 变量映射
      → L4 Bridge/WriteBack                        ← L4 桥接
        → L3_MD/WriteBack (模型树状态更新)          ← 受体
```

### Checkpoint 数据流
```
RT_WriteBack_Domain
  → SaveCheckpoint(状态序列化 + Checksum)
  → LoadCheckpoint(反序列化 + 验证)
  → RollbackToCheckpoint(回滚到保存点)
```

### 热路径约束
- 回写仅在增量步末调用（低频，非热路径高频）
- 不直读 L3 Desc

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L5_RT/StepDriver | S (上游) | 步末触发回写 |
| R2 | L5_RT/Solver | S (上游) | u/sigma 结果来源 |
| R3 | L3_MD/WriteBack | T+B (下游) | 回写到 L3 State |
| R4 | L4_PH/Bridge/WriteBack | T+B (下游) | L4 桥接 |
| R5 | L5_RT/Output | S (同层) | 与 Output 协调保存 |

### 约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| 不使用 STOP | **硬** | H-ERR-01 |
| 步末调用（非热路径高频） | **硬** | 低频调用 |
| 回写一致性（数据不丢失） | **硬** | ValidateWriteBack |
| 白名单审计 | **硬** | 仅注册目标可接收 |
| 测试覆盖率 | **软** | 待建 |

### 错误处理

| 错误场景 | 错误码 | 处理方式 |
|----------|--------|----------|
| 回写目标索引越界 | `IF_STATUS_INVALID` | 返回 status |
| 变量映射不匹配 | `IF_STATUS_ERROR` | 返回 status |
| Checkpoint 校验失败 | `IF_STATUS_ERROR` | 返回 status |

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 四型定义完整 | RT_WB_Def (AUTHORITY) | ✅ 已实现 |
| A2 | 节点回写 | NodePos/NodeDisp/NodeAccel 可用 | ✅ 已实现 |
| A3 | 单元回写 | ElemStress/ElemStrain/ElemEplas 可用 | ✅ 已实现 |
| A4 | GP 状态变量 | GPStateVar 回写可用 | ✅ 已实现 |
| A5 | Checkpoint | Save/Load/Rollback + Checksum 验证 | ✅ 已实现 |
| A6 | 审计机制 | 白名单 + AuditWriteBack | ✅ 已实现 |
| A7 | Bridge 扩展 | FromL5/ToL4/ToL3 已从 SKELETON 扩展为 ACTIVE | ✅ 已实现 |
| A8 | SIO Proc | 5 组 _In/_Out 接口 | ✅ 已实现 |
| A9 | 错误传播 | ErrorStatusType，不使用 STOP | ✅ 已实现 |
| A10 | 主应力/VonMises | ComputePrincipalStresses/VonMises 可用 | ✅ 已实现 |
