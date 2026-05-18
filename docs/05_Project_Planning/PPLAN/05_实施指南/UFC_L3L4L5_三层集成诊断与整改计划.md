# UFC L3_MD / L4_PH / L5_RT 三层集成诊断与整改计划

> **版本**：v1.0  
> **创建日期**：2026-03-27  
> **作者**：架构分析（基于代码扫描）  
> **上位文档**：[L3_MD_L4_PH_联通契约与缺陷分析.md](L3_MD_L4_PH_联通契约与缺陷分析.md)（v1.14，已修复 D1–D6）  
> **热路径审计基准**：[M0_L4L5_热路径违规USE_audit.md](../03_实施规划/域分级重构/M0_L4L5_热路径违规USE_audit.md)  
> **状态**：🔴 诊断完成，整改计划待实施

---

## 0. 背景与目的

本文档在 `L3_MD_L4_PH_联通契约与缺陷分析.md`（D1–D6 已全部修复，I-01~I-13 部分已实施）的基础上，
针对 **L3_MD、L4_PH、L5_RT 三层整体联通视角**，记录新一轮系统性扫描发现的 **7 大集成缺陷（G1–G7）**，
并制定分阶段整改计划（N0–N3）。

### 已有文档中已解决的问题（本文不重复）

| 类别 | 状态 |
|------|------|
| P0 缺陷 D1–D6（含 Bridge 反向注入、白名单乱写、合同缺失等） | ✅ 全部修复（2026-03-11） |
| I-03 Bridge CONTRACT.md 补全 | ✅ 已实施 |
| I-04 L3 只读 Get API 门禁注释 | ✅ 已实施 |
| I-05 Populate 参数注入 slot_pool | ✅ 已实施（Populate 函数签名已改） |
| I-11 WriteBack CONTRACT.md 双层对齐 | ✅ 已实施 |
| G-1~G-5 质量门禁 | ✅ 全部 PASS（AP-8 Contact 待审查） |

---

## 1. 三层设计意图 vs 实际状态落差

### 1.1 期望架构（设计意图）

```
L3_MD  ←→  L4_PH  ←→  L5_RT
 只读       Populate      热路径
 Desc       slot_pool     零L3
 State      冷路径        白名单
            Bridge        WriteBack
```

**核心约束**：
- **热路径零 L3**：L4/L5 迭代×单元×积分点路径禁止直接读 L3；
- **Bridge 单向**：`MD_*_PH_Brg`（L3 侧） 和 `RT_*_MD_Brg`（L5 侧）是唯一合法跨层入口；
- **Populate 隔离**：Step-Init 冷路径从 L3 只读，填充 L4 slot_pool，热路径只消费 slot；
- **WriteBack 白名单**：L5→L3 唯一写路径经 `RT_WriteBack_Domain`，L3 侧由 `MD_WriteBack_Domain` 管理。

### 1.2 实际状态（扫描发现）

| 层 | 预期 | 实际 |
|----|------|------|
| L4_PH Populate | 参数注入 L3 数据源 | **直接 `USE g_ufc_global` 全局容器**（G1） |
| L5_RT StepDriver | 通过 Brg 或 Populate 缓存 | **直接 `USE MD_*` 约 10+ 模块**（G2） |
| L5_RT WriteBack | 单一白名单网关 | **L5 整数白名单 ≠ L3 字符串白名单，Init 反向注入**（G3） |
| L4_PH Bridge | 仅类型映射与生命周期 | **残留单元积分逻辑 `PH_Brg_ElementStiffAssembly`**（G4） |
| L5_RT StepDriver | 统一 Runner 编排协议 | **20+ Runner 各自为政，无统一接口**（G5） |
| L5_RT Contact | 由 L4 Contact Populate 供给 | **L5 装配绕过 L4 直读 L3 Contact 类型**（G6） |
| StepDriver Output/WriteBack | Driver 有明确触发点 | **触发时序散落，缺统一协调点**（G7） |

---

## 2. 七大集成缺陷（G1–G7）详细诊断

### G1：Populate 全局容器强依赖（P1 级）

**症状**：`PH_L4_Populate_Core.f90` 中每个 Populate 子程序顶部均有：

```fortran
USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
```

并在函数体内直接读取：

```fortran
n_l3_mats = g_ufc_global%md_layer%material%n_materials
CALL MD_Mat_GetDesc_Idx(mat_idx, arg_mat, status)
```

**问题**：
- Populate 函数无法在不存在全局容器的单测环境中调用；
- 全局容器是隐式依赖，调用方无法注入 Mock L3；
- 与已有 I-05 改进（"参数注入 slot_pool"）的签名方向相悖——签名改了，但数据源仍是全局。

**根因**：`UFC_GlobalContainer_Core` 作为"隐形单例"被所有层穿透使用，违反了 Populate 模式的初衷。

**代码定位**：
- `UFC/ufc_core/L4_PH/PH_L4_Populate_Core.f90`，第 1 行 USE 声明及后续 ~60+ 处全局容器读取

**修复方向**：将 Populate 签名改为显式接收 `md_layer_ptr`（或等价只读接口句柄），全局容器仅在最顶层装配点（`L6_AP` 或 `L5_RT` 调度入口）解包一次。

---

### G2：L5 热路径直接 USE L3（P0 级——热路径零 L3 违规）

**症状**：`L5_RT/StepDriver/Core/RT_Driver_Core.f90` 模块头（第 44–80 行）：

```fortran
MODULE RT_Driver_Core
  use MD_Base_State_API, only: GlobalState, NodeState, ElemState
  use MD_Model_Core, only: MD_Model_Domain, MD_Model_GetJobType
  USE MD_Model_Types, only: Model, Job
  use MD_Mesh_Core, only: MD_Mesh_Domain, MD_Mesh_GetElemConnect_Idx, &
                           MD_Mesh_GetNodeCoord_Idx, MD_Mesh_GetBCNodeIdx
  use MD_Step_Process_Core, only: MD_Step_Proc_Domain, ...
  ! ... 共约 10–12 个 MD_* 模块直接 USE
```

**问题**：
- StepDriver 是 L5 热路径的编排核心，每次 Increment/Iteration 均经过此模块；
- 直接 `USE MD_*` 导致 L5 热路径在每步都携带 L3 类型指针，违反「热路径零 L3」原则；
- 无法通过仅替换 L4 层来隔离 L3 更改（修改 MD 类型即影响 RT_Driver）。

**根因**：StepDriver 在历史上由 L3 模型驱动层逐步演化，未经 Populate/Brg 抽象就直接扩展到热路径。

**代码定位**：
- `UFC/ufc_core/L5_RT/StepDriver/Core/RT_Driver_Core.f90`，第 44–80 行（约 10+ 条 `use MD_*`）
- 疑似同样问题：`RT_StepDriver_Core.f90`、`RT_Asm_Solv.f90`（已在 M0 文档记录）

**修复方向**：
1. 短期（N1）：将 `RT_Driver_Core` 中的 `MD_*` 类型引用替换为 L5 本地 TYPE 定义（`RT_StepCtx`、`RT_MeshSnapshot` 等）；
2. 长期（N3）：通过 `RT_StepDrv_MD_Brg` 统一提供步驱动所需 L3 数据快照，由 Populate 阶段填充。

---

### G3：WriteBack 双重白名单 + Init 反向注入（P1 级）

**症状 A——双重白名单**：

L5 侧（`RT_WriteBack_Domain_Core.f90`，第 41–44 行）：
```fortran
INTEGER, PARAMETER :: RT_WB_TARGET_L3_NODE_COORD = 1
INTEGER, PARAMETER :: RT_WB_TARGET_L3_NODE_DISP  = 2
INTEGER, PARAMETER :: RT_WB_TARGET_L3_STRESS      = 3
INTEGER, PARAMETER :: RT_WB_TARGET_L3_STRAIN       = 4
```

L3 侧（`MD_WriteBack_Domain_Core.f90`）：
```fortran
CALL MD_WriteBack_WhiteListDomain(field_name_str, is_allowed)  ! 字符串查找
```

两套白名单**独立维护、互不同步**：L5 用整数常量决定"写哪里"，L3 用字符串字典决定"允许写"——整数-字符串映射关系没有统一注册表。

**症状 B——Init 反向注入**：

`RT_WriteBack_Domain_Core.f90`，`RT_WriteBack_Domain_Init`（约第 214 行）：
```fortran
CALL MD_WB_SetContainer(g_ufc_global%md_layer, status)
```

L5 的 Init 函数主动向 L3 注入容器，**方向完全倒置**（应由 L3 初始化时向上暴露句柄，而非 L5 向 L3 推送）。

**问题**：
- 双白名单使"谁能写入"的决策权分散，运行时白名单不一致无法被静态检测；
- L5 Init 反向注入破坏了层级单向依赖（L5 不应修改 L3 内部状态容器）。

**代码定位**：
- `UFC/ufc_core/L5_RT/WriteBack/RT_WriteBack_Domain_Core.f90`，第 41–44 行（整数白名单）、第 214 行附近（`MD_WB_SetContainer` 调用）
- `UFC/ufc_core/L3_MD/WriteBack/MD_WriteBack_Domain_Core.f90`（字符串白名单逻辑）

**修复方向**：
- 建立统一 `WB_TargetMap`（整数→字符串映射表），在 L4 Bridge 或独立 WriteBack Gateway 模块中集中管理；
- L5 Init 改为从 `g_ufc_global` 读取 L3 层句柄（只读获取），不再调用 L3 Set 函数。

---

### G4：Bridge 残留计算逻辑（P2 级）

**症状**：`L4_PH/Bridge/` 目录下存在 `PH_Brg_ElementStiffAssembly` 子程序，包含单元刚度装配的计算逻辑。

**问题**：Bridge 模块的设计契约（`CONTRACT.md`）明确规定：
> Bridge 只承载类型映射与生命周期（分配/释放），不承载计算逻辑。

计算逻辑混入 Bridge 导致：
- 依赖关系混乱：Compute 域的调用者会错误地以为可以通过 Bridge 路径执行装配；
- 职责边界模糊：Bridge 测试与 Element 装配测试交叉，维护成本高。

**代码定位**：
- `UFC/ufc_core/L4_PH/Bridge/`，`PH_Brg_ElementStiffAssembly` 及相关子程序

**修复方向**：将 Bridge 内的装配逻辑迁移至 `L4_PH/Element/Assembly/` 对应子程序，Bridge 仅保留 `PH_Brg_GetL3Handle`、`PH_Brg_AllocSlot` 等生命周期/句柄函数。

---

### G5：Runner 体系无统一编排协议（P2 级）

**症状**：`L5_RT/StepDriver/` 下约 20+ 个 Runner（`*_Runner.f90`），每个 Runner 内部独立调用 Populate / Assemble / Solve / WriteBack / Output 序列，无公共接口约束。

典型表现：
- 部分 Runner 在 Assemble 前未调用 Populate（依赖上一步缓存残留）；
- Output 触发时序在不同 Runner 中不一致（有些在 Converge 后，有些在 Iteration 内）；
- WriteBack 的调用位置在各 Runner 中各不相同（G7 的来源之一）。

**问题**：
- 20+ Runner 形成 20+ 套微型状态机，任意一处出错均难以定位；
- 新增物理过程（如接触-热耦合）需要复制一套 Runner，逻辑重复率极高；
- 无法在 StepDriver 级别做统一的 Populate/WriteBack 门禁检查。

**根因**：Runner 是按物理过程逐步叠加的，缺少统一的 `IRunner` 接口或 Protocol 约束。

**代码定位**：
- `UFC/ufc_core/L5_RT/StepDriver/` 下所有 `*_Runner.f90`
- `UFC/ufc_core/L5_RT/StepDriver/Core/RT_Driver_Core.f90`（Runner 注册/分发逻辑）

**修复方向**（详见第 4 节 Runner 统一协议设计）：
定义 `RT_IRunner` 抽象接口，要求所有 Runner 实现：
```fortran
PROCEDURE(RT_Runner_Populate_I),  POINTER :: Populate  => NULL()
PROCEDURE(RT_Runner_Assemble_I),  POINTER :: Assemble  => NULL()
PROCEDURE(RT_Runner_Solve_I),     POINTER :: Solve      => NULL()
PROCEDURE(RT_Runner_WriteBack_I), POINTER :: WriteBack => NULL()
PROCEDURE(RT_Runner_Output_I),    POINTER :: Output    => NULL()
```

---

### G6：Contact 域类型在 L4/L5 分裂（P2 级）

**症状**：L5 装配（`L5_RT/Physics/Assembly/` 或 `L5_RT/Contact/`）中直接 `USE MD_Contact_*` 或 `USE MD_Cont_*` 类型，绕过 L4 Contact 的 Populate 路径。

**问题**：
- Contact 力/刚度装配需要接触对几何（GAP、法向量、面积），这些数据在 L4_PH 层已经有 Populate 路径（`PH_L4_Populate_Contact`），但 L5 的 Contact 路径另起炉灶读 L3；
- 形成 L3→L4→L5 与 L3→L5 两条并行的数据流，更新一处时另一条不同步；
- 在 M0 文档中已标注为"AP-8 Contact 待审查"，本次确认为实质性分裂问题。

**代码定位**：
- `UFC/ufc_core/L5_RT/Contact/`、`L5_RT/Physics/Assembly/` 中对 `MD_Cont_*` / `MD_Contact_*` 的直接 USE

**修复方向**：统一 Contact 数据流经 L4 Populate → L4 slot → L5 热路径，废弃 L5 直读 L3 Contact 路径。

---

### G7：Output / WriteBack 触发点在 StepDriver 缺失协调点（P2 级）

**症状**：检查 `RT_Driver_Core.f90` 和各 Runner 后，发现：
- Output（场输出）的触发逻辑分散在不同 Runner 内，没有统一的 `OutputGateway.Flush()` 调用点；
- WriteBack 触发同样分散（参见 G5），部分 Runner 在求解完成后立即 WriteBack，部分在 Converge 判断之后；
- `RT_WriteBack_Domain` 和 `RT_Output_Domain` 之间没有顺序保证（若 Output 在 WriteBack 之前，会输出未更新的 L3 数据）。

**问题**：Output 在 WriteBack 之前触发 → 输出数据不一致（L5 已收敛，但 L3 尚未更新）。

**代码定位**：
- `UFC/ufc_core/L5_RT/StepDriver/Core/RT_Driver_Core.f90`（主驱动调用序列）
- 各 `*_Runner.f90`（Output/WriteBack 调用位置）

**修复方向**：在 Driver 主循环末尾增加统一的"后处理门"（Post-Iteration Gate）：
```
[Converge] → WriteBack Gate → Output Gate → [Next Increment]
```
所有 Runner 的 Output/WriteBack 均通过 Gate 统一触发，不在 Runner 内部单独调用。

---

## 3. 根因分类与缺陷映射表

| 根因 | 描述 | 涉及缺陷 |
|------|------|----------|
| **A. 全局容器穿透** | `g_ufc_global` 被所有层直接读写，Populate 隔离形同虚设 | G1、G3-B |
| **B. 热路径 L3 直连** | L5 热路径直接 `USE MD_*`，Brg 仅覆盖少数路径 | G2、G6 |
| **C. 职责边界模糊** | Bridge 承载计算逻辑，Runner 承载协议管理 | G4、G5 |
| **D. 白名单分散** | WriteBack 决策权分散在 L5 整数常量与 L3 字符串字典 | G3-A、G7 |

---

## 4. 与已有缺陷/改进项的衔接对照

| 本文缺陷 | 已有条目 | 关系说明 |
|----------|----------|----------|
| G1（Populate 全局容器） | I-05（已实施：签名改为参数注入） | I-05 改了签名但未改数据源，G1 是 I-05 的**未完成部分** |
| G2（L5 热路径 USE L3） | M0 文档 §3 StepDriver 条目 | M0 已记录为技术债，G2 是 M0 的**确认与升级**（从灰区→违规） |
| G3-A（双白名单） | I-11（已实施：双层 CONTRACT.md 对齐） | I-11 对齐了文档，但整数-字符串映射代码未统一，G3-A 是**代码侧遗留** |
| G3-B（Init 反向注入） | D2（已修复：Bridge 反向注入） | D2 修复的是 Bridge 层，G3-B 是**WriteBack Init 同类问题** |
| G4（Bridge 残留逻辑） | I-06（待实施：DOFMap 独立 TYPE） | 独立但相关：G4 需先清理 Bridge 计算逻辑，为 I-06 的 TYPE 重构腾空间 |
| G5（Runner 无协议） | M0 §4 M3 建议（StepDriver PROC↔Runner 映射表） | M0-M3 的**具体实施路径**，G5 给出了接口设计方向 |
| G6（Contact 分裂） | M0 §3 AP-8（待审查） | G6 是 AP-8 的**诊断确认**，由"待审查"升级为"已确认缺陷" |
| G7（Output/WriteBack 无协调点） | G5 关联（Runner 分散）、I-11（WB CONTRACT） | G7 是 G5 的**运行时后果**，需配合 Runner 统一协议一起修复 |

**已有改进项状态影响**（须同步更新 `L3_MD_L4_PH_联通契约与缺陷分析.md`）：
- I-05：由"已实施"修订为"**部分实施**"（签名改完，数据源未改）
- M0 StepDriver 条目：由"灰区"升级为"**P0 违规**"（G2）
- AP-8 Contact：由"待审查"确认为"**G6 已确认缺陷**"

---

## 5. 分阶段整改计划（N0–N3）

### N0：防守性加固（1–2 天，不改现有逻辑，只增加门禁）

| 编号 | 任务 | 文件 | 验收 |
|------|------|------|------|
| N0-1 | 在 `RT_WriteBack_Domain_Init` 中删除 `MD_WB_SetContainer` 反向注入，改为从 `g_ufc_global%md_layer` 读取句柄 | `RT_WriteBack_Domain_Core.f90` | 编译通过，WriteBack 功能测试不回归 |
| N0-2 | 在 CI 中增加 G-6 门禁：`L5_RT/Contact/` 内禁止 `USE MD_Cont_*`（除 Bridge 白名单） | `.github/workflows/` 或等价 | CI 拦截新增违规 |
| N0-3 | 在 `PH_L4_Populate_Core.f90` 顶部添加 `! DEBT: G1 全局容器依赖，计划 N1 改为参数注入` 标注 | `PH_L4_Populate_Core.f90` | 代码可追溯 |

### N1：关键路径解耦（1–2 周，P0/P1 级缺陷）

| 编号 | 任务 | 目标文件 | 依赖 | 验收 |
|------|------|----------|------|------|
| N1-1 | **G1 修复**：为 Populate 函数增加 `md_src` 只读句柄参数，调用侧从 `g_ufc_global` 解包传入 | `PH_L4_Populate_Core.f90`，各 Runner 调用点 | N0-3 | Populate 单测可脱离全局容器运行 |
| N1-2 | **G2 修复（阶段一）**：`RT_Driver_Core` 中 `MD_Base_State_API`、`MD_Mesh_Core` 引用迁移至 `RT_StepCtx` 本地 TYPE | `RT_Driver_Core.f90`，新增 `RT_StepCtx_Core.f90` | — | `RT_Driver_Core` 中 `USE MD_*` 数量从 10+ 降至 ≤3 |
| N1-3 | **G3-A 修复**：建立 `WB_TargetMap` 整数→字符串映射表，放入 `L4_PH/WriteBack/PH_WB_TargetMap.f90` | 新文件，`RT_WriteBack_Domain_Core.f90` 引用 | N0-1 | L5 白名单整数常量通过 TargetMap 查字符串，与 L3 白名单对齐测试通过 |

### N2：结构性清理（2–4 周，P2 级缺陷）

| 编号 | 任务 | 目标文件 | 依赖 | 验收 |
|------|------|----------|------|------|
| N2-1 | **G4 修复**：将 `PH_Brg_ElementStiffAssembly` 迁移至 `L4_PH/Element/Assembly/PH_Elem_Stiff_Core.f90` | Bridge/ → Element/Assembly/ | N1-1 | Bridge CONTRACT.md 计算逻辑为零，迁移后装配测试通过 |
| N2-2 | **G5 修复**：定义 `RT_IRunner` 抽象 TYPE，现有 Runner 逐步实现（优先 Static/Implicit 两个主 Runner） | 新建 `RT_IRunner_Core.f90`，各 `*_Runner.f90` | N1-2 | 至少 2 个 Runner 实现 `RT_IRunner`，Populate/WriteBack 调用通过接口路由 |
| N2-3 | **G6 修复**：统一 Contact 数据流经 L4 Populate，删除 L5 直读 L3 Contact 路径 | `L5_RT/Contact/`，`L4_PH/Populate/Contact/` | N1-1 | `rg 'USE MD_Cont_' L5_RT/Contact` 输出为空（除 Bridge） |
| N2-4 | **G7 修复**：在 `RT_Driver_Core` 主循环末尾添加 Post-Iteration Gate，禁止 Runner 内单独调用 Output/WriteBack | `RT_Driver_Core.f90`，各 `*_Runner.f90` | N2-2 | Output 调用点全部在 WriteBack Gate 之后（grep 验证） |

### N3：长期架构对齐（P3，配合 M3/M4/M5 里程碑）

| 编号 | 任务 | 说明 |
|------|------|------|
| N3-1 | **G2 完全消除**：`RT_Driver_Core` 及所有 StepDriver 子模块中 `USE MD_*` 数量归零（仅余 Bridge 白名单） | 需要 `RT_StepDrv_MD_Brg` 覆盖所有步驱动所需 L3 数据 |
| N3-2 | **Populate 快照化**：引入 `L4_StepSnapshot` TYPE，在 Step-Init 冷路径一次性快照 L3 Desc/State，热路径只读快照 | 对应 I-02（Amplitude 预缓存）的架构推广 |
| N3-3 | **全局容器最小化**：`g_ufc_global` 仅在 L6_AP 组装点存在，L3/L4/L5 层间传递均为显式句柄 | 最终状态：全局容器引用计数为 L6 层唯一 |
| N3-4 | **Runner 完全协议化**：所有 20+ Runner 实现 `RT_IRunner`，Driver 只调用接口不直接调用 Runner 内部函数 | 配合 M3 里程碑（StepDriver PROC↔Runner 映射表） |

---

## 6. Runner 统一协议设计方案（G5 详解）

### 6.1 当前问题

```
RT_Driver_Core
├── Static_Runner.f90      → 自行调用 Populate/Assemble/Solve/WriteBack
├── Implicit_Runner.f90    → 自行调用 Populate/NL_Assemble/NL_Solve/WriteBack/Output
├── Contact_Runner.f90     → 自行调用 Populate/Contact_Assemble/Solve/WriteBack
├── Thermal_Runner.f90     → ...
└── (17 more)              → 每个都是独立状态机
```

### 6.2 目标设计

```fortran
! 新建：RT_IRunner_Core.f90
TYPE, ABSTRACT :: RT_IRunner
  CHARACTER(LEN=64) :: runner_name
CONTAINS
  PROCEDURE(RT_Runner_Populate_I),  DEFERRED :: DoPopulate
  PROCEDURE(RT_Runner_Assemble_I),  DEFERRED :: DoAssemble
  PROCEDURE(RT_Runner_Solve_I),     DEFERRED :: DoSolve
  PROCEDURE(RT_Runner_Check_I),     DEFERRED :: DoConvergeCheck
  ! WriteBack 和 Output 不在 Runner 内实现，由 Driver Gate 统一触发
END TYPE RT_IRunner
```

### 6.3 Driver 主循环修订

```fortran
! RT_Driver_Core.f90 主循环（伪代码）
DO inc = 1, n_increments
  CALL g_runner%DoPopulate(step_ctx, status)    ! Runner 接口
  DO iter = 1, max_iters
    CALL g_runner%DoAssemble(step_ctx, status)
    CALL g_runner%DoSolve(step_ctx, status)
    CALL g_runner%DoConvergeCheck(converged, status)
    IF (converged) EXIT
  END DO
  ! Post-Iteration Gate（G7 修复点）
  CALL RT_WriteBack_Gate(step_ctx, status)       ! 统一 WriteBack
  CALL RT_Output_Gate(step_ctx, status)          ! 统一 Output（WriteBack 之后）
END DO
```

### 6.4 迁移策略

- **阶段一（N2-2）**：仅 `Static_Runner` 和 `Implicit_Runner` 实现 `RT_IRunner`；
- **阶段二（N3-4）**：其余 Runner 逐步迁移，以"新增 Runner 必须实现 `RT_IRunner`"作为 CI 门禁；
- **过渡期**：未迁移的 Runner 包装为 `RT_LegacyRunner_Adapter` 实现 `RT_IRunner` 接口（外覆）。

---

## 7. WriteBack 统一网关设计方案（G3 详解）

### 7.1 当前问题

```
L5_RT WriteBack        L3_MD WriteBack
整数白名单              字符串白名单
RT_WB_TARGET_* = 1/2/3  MD_WriteBack_WhiteList("node_coord")
         ↕（无统一映射）
```

### 7.2 目标设计

新建 `L4_PH/WriteBack/PH_WB_TargetMap.f90`：

```fortran
MODULE PH_WB_TargetMap
  ! 唯一注册表：整数常量 ← 字符串 的双向映射
  INTEGER, PARAMETER :: WB_NODE_COORD = 1
  INTEGER, PARAMETER :: WB_NODE_DISP  = 2
  INTEGER, PARAMETER :: WB_STRESS     = 3
  INTEGER, PARAMETER :: WB_STRAIN     = 4

  CHARACTER(LEN=32), PARAMETER :: WB_NAME(4) = [ &
    "MD_NODE_COORD   ", &
    "MD_NODE_DISP    ", &
    "MD_ELEM_STRESS  ", &
    "MD_ELEM_STRAIN  "  ]

CONTAINS
  FUNCTION PH_WB_GetName(target_id) RESULT(name)
    ! 通过整数 ID 获取 L3 字符串键
  END FUNCTION

  FUNCTION PH_WB_GetId(name) RESULT(target_id)
    ! 通过字符串获取整数 ID（L3 校验用）
  END FUNCTION
END MODULE PH_WB_TargetMap
```

### 7.3 调用关系修订

```
L5 RT_WriteBack_Gate
  → CALL PH_WB_GetName(RT_WB_TARGET_L3_NODE_COORD)  → "MD_NODE_COORD"
  → CALL MD_WriteBack_WhiteListDomain("MD_NODE_COORD", allowed)
  → IF allowed: 执行写入
```

---

## 8. 扩展质量门禁（G8–G14）

在现有 G-1~G-5 门禁基础上新增：

| 门禁 ID | 检查内容 | 对应缺陷 | 实施阶段 |
|---------|----------|----------|----------|
| G-6 | `L5_RT/Contact/` 中禁止 `USE MD_Cont_*`（除 Bridge/ 白名单） | G6 | N0-2 |
| G-7 | `PH_L4_Populate_Core.f90` 中禁止直接引用 `g_ufc_global`（改为参数） | G1 | N1-1 完成后 |
| G-8 | `RT_Driver_Core.f90` 中 `USE MD_*` 数量不超过 3 条（阶段门） | G2 | N1-2 完成后 |
| G-9 | Bridge 目录（`L4_PH/Bridge/`、`L5_RT/Bridge/`）内禁止 CONTAINS 计算子程序 | G4 | N2-1 完成后 |
| G-10 | `RT_WriteBack_Domain_Init` 中禁止调用 `MD_WB_SetContainer` | G3-B | N0-1 完成后 |
| G-11 | Output 调用点必须在 WriteBack 调用点之后（grep 顺序检查） | G7 | N2-4 完成后 |
| G-12 | 新增 Runner 必须实现 `RT_IRunner` 接口（编译时 DEFERRED 检查） | G5 | N2-2 完成后 |

---

## 9. 验收与状态追踪

| 阶段 | 核心指标 | 验收方式 |
|------|----------|----------|
| N0 完成 | G-6/G-10 门禁通过 CI | CI 绿灯 |
| N1 完成 | Populate 单测可不依赖全局容器；`RT_Driver_Core` USE MD_* ≤3 | 单测 + grep |
| N2 完成 | G-7~G-12 门禁全部加入 CI 并通过；Contact 数据流统一 | CI + 功能回归 |
| N3 完成 | `g_ufc_global` 引用仅余 L6_AP；`USE MD_*` 在 L5 热路径为零 | grep 扫描为空 |

---

## 10. 参考文档

| 文档 | 路径 |
|------|------|
| L3↔L4 联通契约（含 D1–D6、I-01~I-13） | [`06_实施指南/L3_MD_L4_PH_联通契约与缺陷分析.md`](L3_MD_L4_PH_联通契约与缺陷分析.md) |
| 热路径 USE 审计基准（M0） | [`04_实施路线与任务规划/域分级重构/M0_L4L5_热路径违规USE_audit.md`](../03_实施规划/域分级重构/M0_L4L5_热路径违规USE_audit.md) |
| HYPLAS 淬炼方案（热路径零L3 依据） | [`04_实施路线与任务规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md`](../03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md) |
| 架构总纲 v5.0 | [`01_架构总纲与设计哲学/UFC_架构设计总纲_深度整合版_v5.0.md`](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md) |
| PLAN 导航入口 | [`PLAN/README.md`](../README.md) |

---

*维护规则：每完成一个 N 阶段任务后，更新本文件对应小节状态（🔴→🟡→✅），并同步更新 `L3_MD_L4_PH_联通契约与缺陷分析.md` 中的 I-05/AP-8 状态。*
