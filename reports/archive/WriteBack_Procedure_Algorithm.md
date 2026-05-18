# 写回域过程算法 Procedure — L5 为主的三维度全景

**文档性质**：与 `WriteBack_L3L4L5_four_type_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理 WriteBack 域的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L5_RT/WriteBack/`（L5 Algo + WB_Guard 管线）、`ufc_core/L3_MD/WriteBack/`（L3 Bridge）。

**报告 ID**：`REP-WB-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的主/辅架构图解，而是以 **过程算法** 为核心视角。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| WriteBack 域 **三维度过程算法**：空间（11域分派）、时间（LOP生命周期）、动作（WB_Guard 管线） | 具体 **写回格式** 编码细节 |
| L5 为主 **Algo TYPE 体系** | 非写回域的过程算法（见各域 Procedure 文档） |
| **WB_Guard 白名单 + 审计** 详述 | **UEXTERNALDB/STATEV/PUTVRM ABI** 映射（见四型合订本 §3.5） |
| **AttachBuffers→WBImpl→Brg→Audit** 管线 | **检查点/重启** 细节 |

---

## 1. 三维度过程算法框架（WriteBack 域解读）

### 1.1 空间维度

WriteBack 域的空间维度关注 **11域分派 / 白名单守卫 / 数据路由**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **11域分派** | MD_WB_Brg→各域 State 写回 | `MD_WB_Brg` |
| **白名单守卫** | 只允许已注册字段写回 | `WB_Guard` 白名单校验 |
| **数据路由** | 写回目标→State 容器 | `RT_WBDomain%AttachBuffers` |

### 1.2 时间维度

WriteBack 域的时间维度关注 **LOP 生命周期 / 步末触发 / 检查点**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **LOP=0** | 仿真开始 (UEXTERNALDB) | `RT_WBDomain` |
| **LOP=1** | 增量步中 | — |
| **LOP=2** | 步末 (STATEV/PUTVRM) | `RT_StepDriver` 步末回调 |
| **LOP=3** | 仿真结束 (UEXTERNALDB) | `RT_WBDomain` |

### 1.3 动作维度

WriteBack 域的动作维度关注 **AttachBuffers→WBImpl→Brg→Audit 四步管线**。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **AttachBuffers** | 绑定 L3 各域 State 容器 | — |
| **WBImpl** | 编排写回步骤 | 各域 State 容器 |
| **MD_WB_Brg** | 11域分派 (经 WB_Guard 白名单校验) | 各域 State |
| **Audit** | NaN 截断 + 审计记录 | `WriteBackAuditRecord` |

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 Algo TYPE

WriteBack 域 **无 L3 Algo TYPE**（L3 仅有 `MD_WB_Brg` 桥接模块）。

### 2.2 L4 Algo TYPE

WriteBack 域 **无 L4 域目录**（半贯通域：L3+L5，L4 无域）。

### 2.3 L5 Algo TYPE（运行期，WriteBack 主场）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_WB_Stp_Ctl_Algo` | write_trigger + checkpoint + validate + checksum + force/suppress + nan_policy | 时间 | ✅ **P2 DONE** |
| `RT_WB_Itr_Algo` | buffer + compress + parallel + batch + audit | 动作 | ✅ **P2 DONE** |
| `RT_WB_Algo`（主 Algo） | stp_ctl(`RT_WB_Stp_Ctl_Algo`) + itr_algo(`RT_WB_Itr_Algo`) + legacy flat fields | 时间+动作 |

**关键观察**：P2 补全后，`RT_WB_Algo` 主 TYPE 通过组合嵌入 `stp_ctl`（步级触发/策略/验证控制）和 `itr_algo`（迭代级缓冲/压缩/审计控制），对齐 Output 域 `RT_Out_Stp_Ctl_Algo` + `RT_Out_Itr_Algo` 模式。原扁平字段保留为 legacy（带 deprecation 注释）。

---

## 3. Procedure Pointer 架构

WriteBack 域当前 **无独立 Procedure Pointer**。

**设计决策**：WriteBack 的分派策略由 `MD_WB_Brg` 硬编码 11 域分派路径，而非可插拔 PTR。原因：
- 写回目标域固定（11 域），不会运行时增减
- 白名单守卫 (`WB_Guard`) 替代了 PTR 的灵活性需求

**未来扩展**：如需用户自定义写回目标，可引入 `RT_WB_Target_Ifc` PTR。

---

## 4. WB_Guard 管线（核心动作管线）

### 4.1 管线全景

```text
RT_WBDomain (L5 金线)
  │
  ├── 1. AttachBuffers (空间维度)
  │   └── 绑定 L3 各域 State 容器
  │   └── 消费: Material/Element/Contact/LoadBC/... State 容器引用
  │
  ├── 2. WBImpl 编排 (动作维度)
  │   └── 编排写回步骤: 按域顺序 / 按 LOP 触发
  │   └── Algo 消费: RT_WB_Algo%use_node_buffering / %use_elem_buffering
  │
  ├── 3. MD_WB_Brg 11域分派 (空间+动作维度)
  │   └── 经 WB_Guard 白名单校验
  │   │   ├── 检查: 字段是否在白名单中?
  │   │   └── 拒绝: 非法写回 → 错误状态
  │   │
  │   └── 分派路径 (11域):
  │       ├── Material: stateVars 写回
  │       ├── Element: u/du 写回
  │       ├── Section: 截面参数写回
  │       ├── Contact: 接触状态写回
  │       ├── LoadBC: 载荷/BC 状态写回
  │       ├── Output: 输出帧写回
  │       ├── Solver: 求解器状态写回
  │       ├── Step: 步状态写回
  │       ├── Amplitude: 幅值写回
  │       ├── Mesh: 网格状态写回
  │       └── Model: 模型状态写回
  │
  └── 4. Audit (动作维度, 安全守卫)
      └── NaN 截断: 写回值 → NaN 检查 → 截断为 0.0 / 报警
      └── 审计记录: WriteBackAuditRecord (谁/何时/写了什么)
      └── State 写入: WriteBackAuditRecord
```

---

## 5. 跨域协作（WriteBack 域视角）

### 5.1 空间维度协作

| 协作域 | 空间操作 | WriteBack 域角色 |
|--------|----------|-----------------|
| Material | stateVars 写回 | 写入 Material L3 State |
| Element | u/du 写回 | 写入 Element L3 State |
| Contact | 接触状态写回 | 写入 Contact L3 State |
| LoadBC | 载荷/BC 状态写回 | 写入 LoadBC L3 State |
| Output | 输出帧写回 | 与 Output LOP 生命周期对偶 |

### 5.2 时间维度协作

| 时间阶段 | WriteBack 域动作 | 协作域 |
|----------|-----------------|--------|
| LOP=0 | UEXTERNALDB 写回 | Analysis (仿真开始) |
| LOP=2 | STATEV/PUTVRM 写回 | Analysis (步末) |
| LOP=3 | UEXTERNALDB 写回 | Analysis (仿真结束) |
| 检查点 | 全域 State 写回 | Analysis (检查点触发) |

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| P2 | ~~无独立子 Algo TYPE~~ | ~~`RT_WB_Algo` 未拆分~~ | ~~拆分 `RT_WB_Stp_Ctl_Algo`(写回策略/LOP) + `RT_WB_Itr_Algo`(审计/NaN截断)~~ | ✅ **DONE**
| — | 无 Procedure Pointer | 11域硬编码分派 | 保持现状（域数量固定） |
| — | L4 无域目录 | 半贯通设计 | 保持 `MD_WB_Brg` 桥接模式 |

**完备性评级**：✅ **P2 已补全**（`RT_WB_Stp_Ctl_Algo` 步级触发/策略/验证 + `RT_WB_Itr_Algo` 迭代级缓冲/压缩/审计，三维度覆盖时间+动作）；WB_Guard 白名单+审计管线完备

---

## 7. 设计原则（WriteBack 域特化）

1. **WB_Guard 先于 Brg**：白名单校验必须在分派写回之前；非法写回直接拒绝。
2. **NaN 截断不变式**：每个写回值必须经 NaN 检查；NaN → 截断 + 审计记录。
3. **LOP 生命周期对偶**：WriteBack LOP 与 Output/UEXTERNALDB LOP 对齐。
4. **11域分派固定顺序**：Material→Element→Section→Contact→LoadBC→Output→Solver→Step→Amplitude→Mesh→Model。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `WriteBack_L3L4L5_four_type_synthesis.md` | 四型合订本；§3.5 主/辅架构图解 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.7 + A.3.4 | 过程算法全景合订（根 stub）；本文为 WriteBack 域专域扩展 |
| `L5_RT/WriteBack/CONTRACT.md` | L5 合同卡；Algo TYPE 字段级真源 |
| [Output_Procedure_Algorithm.md](../Output_Procedure_Algorithm.md) | Output Procedure；LOP 生命周期对偶 |
| [Analysis_Procedure_Algorithm.md](../Analysis_Procedure_Algorithm.md) | Analysis Procedure；步末/检查点触发 |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/WriteBack_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/WriteBack_Procedure_Algorithm.md` 为 stub。四型合订本：`WriteBack_L3L4L5_four_type_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
