# 载荷/边界条件域过程算法 Procedure — L3 / L4 / L5 三维度全景

**文档性质**：与 `LoadBC_L3L4L5_four_type_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理 LoadBC 域的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/LoadBC/`（canonical；`Boundary/` 为 legacy 旧位置）、`ufc_core/L4_PH/LoadBC/`（严格 `PH_Load_*` / `PH_BC_*` 双柱）、`ufc_core/L5_RT/LoadBC/`（运行期 `RT_Load_*` / `RT_BC_*` 双柱；仍由 `RT_LoadBC_Proc` / `RT_LoadBC_ConstApply` / `RT_LoadBC_Core` 等 LoadBC umbrella/support 文件统一消费或兼容承接）。

**报告 ID**：`REP-LOADBC-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的主/辅架构图解，而是以 **过程算法** 为核心视角，重点描述 split 之后的 Load / BC 双管线。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| LoadBC 域 **三维度过程算法**：空间（载荷离散/投影）、时间（幅值/步控/cutback）、动作（Load Assemble + BC Apply 双管线） | 具体载荷积分公式推导 |
| L3/L4/L5 **canonical split**：L3 `MD_Load_*` / `MD_BC_*`，L4 `PH_Load_*` / `PH_BC_*`，L5 `RT_Load_*` / `RT_BC_*` | Constraint 域 Tie/MPC/Coupling 的完整施加算法 |
| Load/BC 双柱与 runtime LoadBC 编排之间的关系 | `ULOAD` / `DLOAD` 完整 ABI 封装细节 |
| 与 Analysis / Assembly / Element 的协作顺序 | 各种 BC enforcement 公式证明 |

---

## 1. 三维度过程算法框架（LoadBC 域解读）

### 1.1 空间维度

LoadBC 域的空间维度关注 **载荷离散、面/体积分与 BC 目标自由度映射**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **分布载荷积分** | 面载/边载/体载的积分规则选择 | `PH_Load_Stp_Ctl_Algo` + `PH_Load_Ctx` |
| **节点投影** | 面载/压力 → 等效节点力 | `PH_Load_LoadIntegration_Type` / `PH_Load_SurfaceTraction_Type` |
| **体力离散** | Gravity / body force → 体积积分 | `PH_Load_Core.f90` |
| **BC 目标映射** | 节点集 / DOF 区间 / prescribed value | `MD_BC_Desc` → `PH_BC_Ctx` |

### 1.2 时间维度

LoadBC 域的时间维度关注 **幅值、步级激活、cutback 与施加策略**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **幅值引用** | `amplitude_id` / time_dependence | `MD_Load_Desc`、`MD_BC_Desc` |
| **运行期步控** | current_step / incr / iter | `RT_Load_Ctx`、`RT_BC_Ctx` |
| **cutback / 自适应** | max_cutbacks / cutback_factor / convergence_tol | `RT_Load_Impl_Algo`、`RT_BC_Impl_Algo` |
| **BC 施加策略** | apply_mode / penalty / ramp / lagrange | `MD_BC_Algo`、`PH_BC_Stp_Ctl_Algo` |

### 1.3 动作维度

LoadBC 域的动作维度聚焦于 **Load Assemble** 与 **BC Apply** 两条运行期金线。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **Assemble Loads** | `CLOAD` / `DLOAD` / `GRAVITY` / thermal-like source → `F_ext` | 全局载荷向量（经 `RT_Asm_*`） |
| **Apply BCs** | Dirichlet / elimination / penalty / reaction handling | 全局 `K/F` 或 CSR 扩展 |
| **Compute Reactions** | 反力恢复与约束反馈 | `RT_BC_ReactionForce.f90` |

---

## 2. L3 / L4 / L5 控制载体

### 2.1 L3 冷路径（canonical split）

L3 在 split 之后并不是“Load 和 BC 完全对称”的四型：

- **Load 侧 canonical**：`MD_Load_Desc` / `MD_Load_State` / `MD_Load_Domain`
- **BC 侧 canonical**：`MD_BC_Desc` / `MD_BC_State` / `MD_BC_Algo` / `MD_BC_Domain`
- **legacy mixed compatibility**：`MD_LBC_Def.f90` 仍保留混合 `MD_LBC_Algo` / `MD_LBC_Ctx` 等旧载体，不再作为新口径

| 载体 | 核心字段 | 三维度归属 |
|------|----------|-----------|
| `MD_Load_Desc` | `magnitude` / `scale_factor` / `time_dependence` / `amplitude_id` / `load_type` | 空间 + 时间 |
| `MD_BC_Algo` | `apply_mode` / `penalty_factor` / `ramp_fraction` / `use_ramp` / `lagrange_multiplier` | 时间 + 动作 |
| `MD_LBC_Algo`（legacy） | 旧混合控制载体 | 兼容层，不作为 canonical |

### 2.2 L4 热路径（严格 Load / BC 双柱）

| 载体 | 核心字段/角色 | 三维度归属 |
|------|---------------|-----------|
| `PH_Load_Stp_Ctl_Algo` | 载荷积分/跟随载/投影等步级控制 | 空间 + 时间 + 动作 |
| `PH_BC_Stp_Ctl_Algo` | BC enforcement / method / cache control | 时间 + 动作 |
| `PH_Load_Ctx` | 当前积分方式、计数与载荷装配上下文 | 空间 + 动作 |
| `PH_BC_Ctx` | 当前 BC 方法与施加上下文 | 动作 |

### 2.3 L5 运行期（runtime split）

L5 代码层已经拆为 `RT_Load_*` / `RT_BC_*` 两柱；`LoadBC` 仅作为编排语义保留，并由少量 umbrella/support 文件承接统一入口与兼容逻辑。

| 载体 | 核心字段 | 三维度归属 |
|------|----------|-----------|
| `RT_Load_Algo` | `dispatch_strategy` | 动作 |
| `RT_Load_Impl_Algo` | `max_cutbacks` / `auto_cutback_enabled` / `cutback_factor` / `min_load_increment` | 时间 + 动作 |
| `RT_BC_Algo` | `dispatch_strategy` | 动作 |
| `RT_BC_Impl_Algo` | `max_cutbacks` / `auto_cutback_enabled` / `cutback_factor` / `load_convergence_tol` | 时间 + 动作 |

补充说明：

- `RT_LoadBC_Proc`：保留为 runtime umbrella 的 SIO facade 入口。
- `RT_LoadBC_ConstApply`：承担 Tie / MPC / Coupling / RigidBody 的 penalty/CSR 约束施加桥。
- `RT_LoadBC_Core`：旧 facade，现更接近兼容层而非 canonical 主实现。

---

## 3. Procedure Pointer 架构

LoadBC 当前 **无独立 Procedure Pointer 主架构**。

**设计决策**：

- 载荷与 BC 的策略数量有限，当前更适合 **枚举 + split module** 的结构，而不是 `Material` / `Element` 那样的可插拔 `PTR`
- 将来若引入用户自定义载荷核，应优先在 **`PH_Load_*`** 一侧扩展，而不是继续沿用 `PH_Ldbc_*` 旧命名

---

## 4. Load / BC 双管线

### 4.1 载荷组装管线（Load Assemble）

```text
L3 cold source
  MD_Load_Desc / MD_Load_State
    │
    ├── Populate / Bridge
    │   └── L4 slot: PH_Load_* + PH_Load_Ctx
    │
    └── L5 runtime
        RT_Load_Desc / RT_Load_State / RT_Load_Algo / RT_Load_Impl_Algo
          │
          ├── RT_Load_Brg
          ├── RT_Load_Impl
          └── PH_Load_Core
               ├── concentrated load
               ├── distributed / pressure load
               ├── gravity / body force
               └── thermal-like source term
                    ↓
                 global F_ext (via RT_Asm_*)
```

### 4.2 边界条件施加管线（BC Apply）

```text
L3 cold source
  MD_BC_Desc / MD_BC_State / MD_BC_Algo
    │
    ├── Populate / Bridge
    │   └── L4 slot: PH_BC_* + PH_BC_Ctx
    │
    └── L5 runtime
        RT_BC_Desc / RT_BC_State / RT_BC_Algo / RT_BC_Impl_Algo
          │
          ├── RT_BC_Brg
          ├── RT_BC_Impl
          ├── PH_BC_Core
          └── RT_BC_ReactionForce
               ├── penalty / elimination application
               ├── CSR / dense constraint handling
               └── reaction recovery
                    ↓
                 global K / F modification
```

### 4.3 关键观察

1. **Load 与 BC 已在代码层拆分**，不应再把 `PH_LoadBC_Domain` / `RT_LoadBC_Algo` 当作 canonical 运行期主类型。
2. **LoadBC** 在今天更像是“编排 umbrella”，并具体落在 `RT_LoadBC_Proc` / `RT_LoadBC_ConstApply` / `RT_LoadBC_Core` 等支持文件上，而不是一个仍保留混合四型定义的实现桶。
3. **L3 仍有 legacy mixed 兼容层**，但不应再反向主导 REPORTS 叙事。

---

## 5. 跨域协作（LoadBC 域视角）

### 5.1 空间维度协作

| 协作域 | 空间操作 | LoadBC 域角色 |
|--------|----------|--------------|
| Element | 面/边/体积分所需几何量 | 消费面积、法向、积分点与装配位置 |
| Contact | 接触力与外载顺序协调 | 共享 `F_ext` / 约束施加次序 |
| Material | 热载 / 材料相关源项 | 通过 L4 核消费材料侧参数 |

### 5.2 时间维度协作

| 时间阶段 | LoadBC 域动作 | 协作域 |
|----------|--------------|--------|
| Step Init | Populate + 激活计划建立 | Analysis / StepDriver |
| Inc / Itr | 载荷施加、BC 施加、cutback 判断 | Solver / Assembly |
| Post Solve | Reaction / diagnostics | WriteBack / Output |

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| P0 | REPORTS 旧 mixed 叙事 | 本文之前仍以 `PH_Ldbc_*` / `PH_LoadBC_*` 为中心 | 已切到 canonical split |
| P1 | L5 合同仍保留 umbrella `RT_LoadBC_*` 叙事 | 与当前 `RT_Load_*` / `RT_BC_*` 文件名不完全一致 | 后续收敛 `L5_RT/LoadBC/CONTRACT.md` |
| P1 | legacy mixed 文件仍在仓 | `MD_LBC_Def.f90`、旧 `Boundary/` 语义仍可见 | 保留兼容，但不再作为文档主口径 |
| P1 | 用户载荷 ABI wrapper 仍不完整 | 未见独立 `RT_DLOAD_*` / `RT_ULOAD_*` | 如确需用户载荷扩展，再在 split 结构上补 |

**完备性评级**：⚠️ **主叙事已收敛到 split canonical**，但运行期 umbrella 合同与部分 legacy 兼容层仍待进一步对齐。

---

## 7. 设计原则（LoadBC 域特化）

1. **Load 与 BC 分而治之**：载荷组装与边界条件施加是两条不同的运行时金线，不再混写为单一 `Ldbc` 核。
2. **L3 允许不完全对称**：Load 侧以 `Desc/State/Domain` 为主，BC 侧已有显式 `Algo`；不强行为了对称而反引入混合主卡。
3. **runtime split 优先于 umbrella 命名**：实际 `RT_Load_*` / `RT_BC_*` 文件与类型，应优先于历史 `RT_LoadBC_*` 叙事。
4. **legacy 只做兼容，不做新真源**：`Boundary/`、`MD_LBC_Def.f90`、旧 `PH_Ldbc_*` 语义只用于迁移说明，不应继续扩写。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `LoadBC_L3L4L5_four_type_synthesis.md` | 四型合订本；四型结构与 split canonical 互补 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.5 | 过程算法全景合订（根 stub）；本文为 LoadBC 域专域扩展 |
| `L3_MD/LoadBC/CONTRACT.md` | L3 canonical split 真源 |
| `L4_PH/LoadBC/CONTRACT.md` | L4 `PH_Load_*` / `PH_BC_*` 双柱真源 |
| `L5_RT/LoadBC/CONTRACT.md` | L5 umbrella 编排合同；仍需继续向 runtime split 叙事收敛 |
| [Analysis_Procedure_Algorithm.md](../Analysis_Procedure_Algorithm.md) | Analysis Procedure；步驱动 / cutback 协作 |
| [Contact_Procedure_Algorithm.md](../Contact_Procedure_Algorithm.md) | Contact Procedure；接触力 → 外载 / 约束顺序 |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/LoadBC_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/LoadBC_Procedure_Algorithm.md` 为 stub。四型合订本：`LoadBC_L3L4L5_four_type_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
