# 输出域过程算法 Procedure — L5 为主的三维度全景

**文档性质**：与 `Output_L3L4L5_four_type_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理 Output 域的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/Output/`（L3 Algo）、`ufc_core/L5_RT/Output/`（L5 Algo + Frame/Buffer/Trigger 管线）。

**报告 ID**：`REP-OUT-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的主/辅架构图解，而是以 **过程算法** 为核心视角。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| Output 域 **三维度过程算法**：空间（场插值/坐标变换）、时间（触发/频率控制）、动作（Frame→Buffer→Writer 管线） | 具体 **输出格式** 编码细节 |
| L5 为主 **Algo TYPE 体系** | 非输出域的过程算法（见各域 Procedure 文档） |
| **CheckTrigger→Collect→Write** 管线 | **UVARM/VUVARM/URDFIL ABI** 映射（见四型合订本 §3.5） |
| **Frame/Buffer/TriggerCtx** 辅 TYPE 详述 | **Field/History 双轨** 选型逻辑（见四型合订本 §3.5） |

---

## 1. 三维度过程算法框架（Output 域解读）

### 1.1 空间维度

Output 域的空间维度关注 **场插值 / 坐标变换 / 区域选择**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **场插值** | IP 值→节点值（外推/平均） | `PH_Out_Brg`（L4 桥接，坐标变换） |
| **区域选择** | 全模型/节点集/单元集 | `RT_Out_Desc%set_id` |
| **坐标变换** | 局部坐标系→全局坐标系 | `PH_Out_Brg`（L4 桥接） |

### 1.2 时间维度

Output 域的时间维度关注 **触发控制 / 频率管理 / 步末写出**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **触发控制** | 步末/时间间隔/迭代 | `RT_Out_TriggerCtx` |
| **频率管理** | 每 N 步/每 T 时间 | `RT_Out%frequency` |
| **步末写出** | LOP=2 触发 | `RT_StepDriver` 步末回调 |
| **LOP 生命周期** | 0=开始/1=增量/2=步末/3=结束 | WriteBack LOP 映射 |

### 1.3 动作维度

Output 域的动作维度关注 **Frame→Buffer→Writer 三级管线**。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **CheckTrigger** | 检查输出触发条件 | — |
| **Collect** | 收集场/历程数据 → Frame | `RT_Out_Frame` |
| **Write** | Frame → Buffer → Writer → 文件 | `RT_Out_Buffer` → 文件系统 |

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 Algo TYPE（冷路径）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `MD_Out_AddField_Algo` | 字段添加算法参数 | 空间+动作 |

### 2.2 L4 Algo TYPE

Output 域 **无 L4 域目录**（半贯通域：L3+L5，L4 无域）。L4 仅有 `PH_Out_Brg` 桥接模块。

### 2.3 L5 Algo TYPE（运行期，Output 主场）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_Out_Stp_Ctl_Algo` | field/hist_freq_incr/time + trigger_type + force/suppress | 时间 | ✅ **P1 DONE** |
| `RT_Out_Itr_Algo` | buffer_size + flush + compress + split + parallel_io | 动作 | ✅ **P1 DONE** |
| `RT_Out`（主 Algo） | stp_ctl(`RT_Out_Stp_Ctl_Algo`) + itr_algo(`RT_Out_Itr_Algo`) + legacy flat fields | 时间+动作 |

**关键观察**：P1 补全后，`RT_Out` 主 TYPE 通过组合嵌入 `stp_ctl`（步级频率/触发控制）和 `itr_algo`（迭代级缓冲/压缩/IO控制），对齐 Material/LoadBC/Contact 各域的 `Stp_Ctl_Algo` 模式。原扁平字段保留为 legacy（带 deprecation 注释）。

---

## 3. Procedure Pointer 架构

Output 域当前 **无独立 Procedure Pointer**。

**设计决策**：Output 域的写出策略（Field/History/重启文件）由 `RT_Out` 内枚举和参数驱动，而非可插拔 PTR。原因：
- 输出格式有限（ODB/ASCII/HDF5），枚举足够
- 管线步骤固定（CheckTrigger→Collect→Write），不需要运行时替换

**未来扩展**：如需用户自定义输出格式，可引入 `RT_Out_Writer_Ifc` PTR。

---

## 4. Frame→Buffer→Writer 管线（核心动作管线）

### 4.1 管线全景

```text
RT_Out_Mgr (L5 金线)
  │
  ├── 1. CheckTrigger (时间维度)
  │   └── 检查: 步末? / 时间间隔? / 迭代?
  │   └── Algo 消费: RT_Out%frequency / RT_Out_TriggerCtx
  │
  ├── 2. PH_Out_Brg (L4 桥接, 空间维度)
  │   └── 坐标变换 / 场插值 (IP→节点)
  │   └── State 读取: 各域 State 容器
  │
  ├── 3. RT_Out_Frame (填充, 动作维度)
  │   └── Field 数据: 节点位移/应力/应变 → Frame
  │   └── History 数据: 能量/反力/接触力 → Frame
  │   └── State 写入: RT_Out_Frame
  │
  ├── 4. RT_Out_Buffer (批量, 动作维度)
  │   └── Frame → Buffer (批量写优化)
  │   └── Algo 消费: RT_Out%buffer_size
  │   └── State 写入: RT_Out_Buffer
  │
  └── 5. RT_Writer_* (写出, 动作维度)
      └── Buffer → 文件系统 (ODB/ASCII/HDF5)
      └── Algo 消费: RT_Out%compression / %parallel_io
```

### 4.2 SIO Arg 管线（L5 Procedure 模式）

```text
RT_Out_Proc.f90 定义了结构化 SIO Arg 管线:
  RT_Out_Init_In / RT_Out_Init_Out         ← 初始化
  RT_Out_Collect_In / RT_Out_Collect_Out   ← 收集
  RT_Out_Write_In / RT_Out_Write_Out       ← 写出
  RT_Out_CheckFreq_In / RT_Out_CheckFreq_Out ← 频率检查
  RT_Out_Finalize_In / RT_Out_Finalize_Out  ← 终结
```

---

## 5. 跨域协作（Output 域视角）

### 5.1 空间维度协作

| 协作域 | 空间操作 | Output 域角色 |
|--------|----------|--------------|
| Material | IP 应力/SDV → 输出 | 消费 Material State 中的 stress/stateVars |
| Element | 节点位移 → 输出 | 消费 Element State 中的 u |
| Contact | 接触力/间隙 → 输出 | 消费 Contact State 中的 forces/gap |
| LoadBC | 反力 → 输出 | 消费 LoadBC State 中的 reaction |

### 5.2 时间维度协作

| 时间阶段 | Output 域动作 | 协作域 |
|----------|--------------|--------|
| Step End | CheckTrigger + Collect + Write | Analysis (步末触发, LOP=2) |
| Increment End | History 数据收集 | Analysis (增量末) |
| Simulation End | Finalize + 关闭文件 | Analysis (仿真结束) |

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| P1 | ~~无独立子 Algo TYPE~~ | ~~Algo 参数内嵌于 `RT_Out` 主 TYPE~~ | ~~拆分 `RT_Out_Stp_Ctl_Algo`(频率/触发) + `RT_Out_Itr_Algo`(压缩/并行IO)~~ | ✅ **DONE**
| — | 无 Procedure Pointer | 枚举驱动足够 | 评估引入 `RT_Out_Writer_Ifc` PTR（用户自定义格式） |
| — | L4 无域目录 | 半贯通设计 | 保持 `PH_Out_Brg` 桥接模式 |

**完备性评级**：✅ **P1 已补全**（`RT_Out_Stp_Ctl_Algo` 步级频率/触发 + `RT_Out_Itr_Algo` 迭代级缓冲/压缩/IO，三维度覆盖时间+动作）；Frame→Buffer→Writer 管线完备

---

## 7. 设计原则（Output 域特化）

1. **CheckTrigger 先于 Collect**：触发检查必须在数据收集之前；未触发则跳过整条管线。
2. **Frame→Buffer→Writer 三级不变式**：Frame 收集单帧→Buffer 批量聚合→Writer 格式写出。
3. **Field/History 双轨并行**：场数据（节点/单元）与历程数据（标量/时间序列）独立管线。
4. **半贯通域 L4 无域**：Output 的 L4 仅有 `PH_Out_Brg` 桥接；空间操作（插值/变换）委托 L4。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `Output_L3L4L5_four_type_synthesis.md` | 四型合订本；§3.5 主/辅架构图解 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.6 | 过程算法全景合订（根 stub）；本文为 Output 域专域扩展 |
| `L5_RT/Output/CONTRACT.md` | L5 合同卡；Algo TYPE 字段级真源 |
| [Material_Procedure_Algorithm.md](../Material_Procedure_Algorithm.md) | Material Procedure；IP 应力/SDV 输出消费 |
| [WriteBack_Procedure_Algorithm.md](../WriteBack_Procedure_Algorithm.md) | WriteBack Procedure；LOP 生命周期对偶 |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/Output_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/Output_Procedure_Algorithm.md` 为 stub。四型合订本：`Output_L3L4L5_four_type_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
