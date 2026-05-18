# UFC 全层全域权威清单矩阵

> **版本**: v1.0 | **日期**: 2026-04-25
> **真源**: 以 `UFC/ufc_core/` 物理目录为准，本文为其结构化索引。
> **关联**: [UFC_ufc_core_目录权威分类.md](UFC_ufc_core_目录权威分类.md) · [十件套 v2.0](../11_闭环落地专项/05_中间架构层新版总纲_全景套件v3.0.md) · [域级落地验收表](../11_闭环落地专项/06_域级落地验收表_CodeReview与里程碑.md)

---

## 一、矩阵说明

本表以 **Layer x Domain** 为骨架，对 UFC 全部六层、所有域级桶进行统一盘点：

| 列 | 含义 |
|----|------|
| **域** | `ufc_core/<Layer>/<Domain>/` 目录名 |
| **子域** | 域下一级子目录（子域 / 功能分区） |
| **跨层映射** | 该域在其他层的对应域（同名或功能对等） |
| **CONTRACT** | 是否有 `CONTRACT.md`（Y / N） |
| **f90 数** | 该域（含子域）`.f90` 文件总数 |
| **域类型** | 基础设施 / 数据 / 计算 / 编排 / 桥接 |

---

## 二、L1_IF — 基础设施层（8 域）

| 域 | 子域 | 跨层映射 | CONTRACT | f90 | 域类型 |
|----|------|----------|----------|-----|--------|
| **Base** | AI, Parallel, Symbol | — | Y（域+3子域各1） | 27 | 基础设施 |
| **Error** | — | — | Y | 7 | 基础设施 |
| **IO** | Checkpoint | — | Y | 15 | 基础设施 |
| **Log** | — | L5_RT/Logging（消费方） | Y | 5 | 基础设施 |
| **Memory** | — | — | Y | 11 | 基础设施 |
| **Monitor** | — | — | Y | 6 | 基础设施 |
| **Precision** | — | — | Y | 4 | 基础设施 |
| **Registry** | — | L6_AP/Registry（上层注册中心） | Y | 5 | 基础设施 |

**L1 小结**: 8 域全部有 CONTRACT，共 83 f90（含层根 IF_L1Layer.f90）。L1 不含四型，提供 wp/i4/ErrorCode/内存池/日志等基座。

---

## 三、L2_NM — 数值计算层（6 域）

| 域 | 子域 | 跨层映射 | CONTRACT | f90 | 域类型 |
|----|------|----------|----------|-----|--------|
| **Base** | BVH | — | Y（域+BVH 各1） | 27 | 基础设施 |
| **Bridge** | — | — | **N** | 5 | 桥接 |
| **ExternalLibs** | — | — | Y | 14 | 基础设施 |
| **Matrix** | — | — | Y | 14 | 计算 |
| **Solver** | AI, Conv, Coupling, LinSolv, NonlinSolv, Parallel | L3_MD/Analysis/Solver, L5_RT/Solver | Y（域+LinSolv+NonlinSolv） | 56 | 计算 |
| **TimeInt** | — | L5_RT/StepDriver（步骤调度消费方） | Y | 15 | 计算 |

**L2 小结**: 6 域，仅 Bridge 缺 CONTRACT，共 105 f90。L2 是纯数值工具层。

---

## 四、L3_MD — 模型数据层（15 域含 Bridge）

| 域 | 子域 | 跨层映射 | CONTRACT | f90 | 域类型 |
|----|------|----------|----------|-----|--------|
| **Analysis** | Amplitude, Solver, Step | L5_RT/StepDriver（Step 运行态） | Y（域+3子域各1） | 14 | 数据 |
| **Assembly** | — | L5_RT/Assembly（运行组装） | Y | 8 | 数据 |
| **Boundary** | — | L4_PH/LoadBC（物理施加） | Y | 8 | 数据 |
| **Bridge** | Bridge_L4, Bridge_L5 | — | Y | 5 | 桥接 |
| **Constraint** | — | L4_PH/Constraint（物理约束） | Y | 9 | 数据 |
| **Field** | — | L4_PH/Field（场变量物理） | Y | 4 | 数据 |
| **Interaction** | — | L4_PH/Contact（物理接触） | Y | 18 | 数据 |
| **KeyWord** | — | L6_AP/Input/Parser（解析消费） | Y | 18 | 数据 |
| **Material** | 20 子族（Elas/Plast/HyperElas/Damage/Creep/Viscoelas/Thermal/Acoustic/Composite/Concrete/Foam/Geo/User 等 + Base/Bridge/Contract/Dispatch/Domain/Registry/Shared） | L4_PH/Material, L5_RT/Material | Y | 200 | 数据 |
| **Mesh** | Element（21 子族） | L4_PH/Element, L5_RT/Element | Y（域+Element 各1） | 37 | 数据 |
| **Model** | — | — | Y | 24 | 数据 |
| **Output** | — | L4_PH/Bridge/Output, L5_RT/Output | Y | 21 | 数据 |
| **Part** | — | — | Y | 9 | 数据 |
| **Section** | — | — | Y | 12 | 数据 |
| **WriteBack** | — | L4_PH/Bridge/WriteBack, L5_RT/WriteBack | Y | 6 | 数据 |

**L3 小结**: 15 域全部有 CONTRACT，共 370 f90。L3 是 SSOT（唯一真相源）。

### L3_MD/Mesh/Element 子族清单（21 族）

Acoustic, Beam, Cohesive, Dashpot, Gasket, Infinite, Mass, Membrane, Pipe, Porous, Shell, Solid2D, Solid2Dt, Solid3D, Solid3Dt, Special, Spring, Surface, Thermal, Truss, User

### L3_MD/Material 子族清单（20 子目录）

Acoustic, Base, Bridge, Composite, Concrete, Contract, Creep, Damage, Dispatch, Domain, Elas, Foam, Geo, HyperElas, Plast, Registry, Shared, Thermal, User, Viscoelas

---

## 五、L4_PH — 物理层（7 域含 Bridge）

| 域 | 子域 | 跨层映射 | CONTRACT | f90 | 域类型 |
|----|------|----------|----------|-----|--------|
| **Bridge** | Output, WriteBack | — | Y（域+2子域各1） | 5 | 桥接 |
| **Constraint** | — | L3_MD/Constraint, L5_RT（运行约束施加） | Y | 9 | 计算 |
| **Contact** | AI, Core, Domain, Explicit, Friction, Search, Self, Thermal, Types, Wear | L3_MD/Interaction, L5_RT/Contact | Y | 20 | 计算 |
| **Element** | 22 子族（与 L3 对齐 + Shared） | L3_MD/Mesh/Element, L5_RT/Element | Y | 203 | 计算 |
| **Field** | — | L3_MD/Field | Y | 4 | 计算 |
| **LoadBC** | — | L3_MD/Boundary, L5_RT/LoadBC | Y | 11 | 计算 |
| **Material** | 18 子族（与 L3 对齐，无 Concrete/Foam） | L3_MD/Material, L5_RT/Material | Y | 200 | 计算 |

**L4 小结**: 7 域全部有 CONTRACT，共 285 f90。L4 是热路径核心。

---

## 六、L5_RT — 运行时层（11 域含 Bridge）

| 域 | 子域 | 跨层映射 | CONTRACT | f90 | 域类型 |
|----|------|----------|----------|-----|--------|
| **Assembly** | — | L3_MD/Assembly | Y | 8 | 编排 |
| **Bridge** | Shared | — | Y（域+Shared 各1） | 5 | 桥接 |
| **Contact** | — | L3_MD/Interaction, L4_PH/Contact | Y | 20 | 编排 |
| **Element** | Mesh | L3_MD/Mesh, L4_PH/Element | Y（域+Mesh 各1） | 203 | 编排 |
| **LoadBC** | — | L3_MD/Boundary, L4_PH/LoadBC | Y | 11 | 编排 |
| **Logging** | — | L1_IF/Log（基座） | Y | 5 | 编排 |
| **Material** | — | L3_MD/Material, L4_PH/Material | **N**（0 f90，尚未实现） | 200 | 编排 |
| **Output** | — | L3_MD/Output, L4_PH/Bridge/Output | Y | 21 | 编排 |
| **Solver** | Coupling | L2_NM/Solver, L3_MD/Analysis/Solver | Y（域+Coupling 各1） | 56 | 编排 |
| **StepDriver** | — | L3_MD/Analysis/Step | Y | 9 | 编排 |
| **WriteBack** | — | L3_MD/WriteBack, L4_PH/Bridge/WriteBack | Y | 6 | 编排 |

**L5 小结**: 11 域，仅 Material 缺 CONTRACT（且 0 f90），共 82 f90。

---

## 七、L6_AP — 应用层（8 域含 Bridge）

| 域 | 子域 | 跨层映射 | CONTRACT | f90 | 域类型 |
|----|------|----------|----------|-----|--------|
| **Bridge** | — | — | Y | 5 | 桥接 |
| **Config** | — | — | Y | 6 | 编排 |
| **Input** | Command, Parser, Script | L3_MD/KeyWord（关键字模型） | Y | 37 | 编排 |
| **Job** | — | — | Y | 8 | 编排 |
| **Output** | — | L5_RT/Output | Y | 21 | 编排 |
| **Registry** | — | L1_IF/Registry（基座） | Y | 5 | 编排 |
| **Solver** | — | L5_RT/Solver | Y | 56 | 编排 |
| **UI** | — | — | Y | 10 | 编排 |

**L6 小结**: 8 域全部有 CONTRACT，共 60 f90。L6 仅依赖 L5_RT。

---

## 八、跨层域映射总表

| 功能域 | L1_IF | L2_NM | L3_MD | L4_PH | L5_RT | L6_AP |
|--------|-------|-------|-------|-------|-------|-------|
| Material | — | — | Material (Desc/SSOT) | Material (Compute) | Material (Dispatch) | — |
| Element/Mesh | — | — | Mesh/Element (Topo) | Element (Ke/Fe) | Element (Loop) | — |
| Contact | — | — | Interaction (Desc) | Contact (Mechanics) | Contact (Search+Assem) | — |
| Constraint | — | — | Constraint (Desc) | Constraint (Penalty/MPC) | — | — |
| LoadBC | — | — | Boundary (Desc) | LoadBC (Apply) | LoadBC (Assem) | — |
| Field | — | — | Field (Desc) | Field (Interpolate) | — | — |
| Output | — | — | Output (Desc) | Bridge/Output | Output (Write) | Output (Format) |
| WriteBack | — | — | WriteBack (受体) | Bridge/WriteBack | WriteBack (发起) | — |
| Solver | — | Solver (LinSolv等) | Analysis/Solver (Config) | — | Solver (Dispatch) | Solver (Entry) |
| Step | — | TimeInt (积分) | Analysis/Step (Desc) | — | StepDriver (SM) | — |
| Assembly | — | — | Assembly (Desc) | — | Assembly (K/F/U) | — |
| KeyWord/Input | — | — | KeyWord (Parse) | — | — | Input (INP) |
| Bridge | — | Bridge | Bridge (L4/L5) | Bridge (Out/WB) | Bridge (Shared) | Bridge |
| Log | Log | — | — | — | Logging | — |
| Registry | Registry | — | — | — | — | Registry |
| Error | Error | — | — | — | — | — |
| Memory | Memory | — | — | — | — | — |
| IO | IO/Checkpoint | — | — | — | — | — |
| Precision | Precision | — | — | — | — | — |
| Model/Part/Section | — | — | Model, Part, Section | — | — | — |
| Job/Config/UI | — | — | — | — | — | Job, Config, UI |

---

## 九、CONTRACT.md 覆盖状态汇总

| 层 | 域总数 | 有 CONTRACT | 缺 CONTRACT | 覆盖率 |
|----|--------|-------------|-------------|--------|
| L1_IF | 8 | 8 | 0 | 100% |
| L2_NM | 6 | 5 | 1 (Bridge) | 83% |
| L3_MD | 15 | 15 | 0 | 100% |
| L4_PH | 7 | 7 | 0 | 100% |
| L5_RT | 11 | 10 | 1 (Material) | 91% |
| L6_AP | 8 | 8 | 0 | 100% |
| **合计** | **55** | **53** | **2** | **96%** |

**缺口**: L2_NM/Bridge（桥接域），L5_RT/Material（0 f90，尚未实现）

---

## 十、全库代码规模

| 层 | f90 文件数 | 占比 |
|----|-----------|------|
| L1_IF | 64 | 6.5% |
| L2_NM | 106 | 10.9% |
| L3_MD | 373 | 38.4% |
| L4_PH | 292 | 30.1% |
| L5_RT | 87 | 9.0% |
| L6_AP | 64 | 6.6% |
| **合计** | **~1100** (含层根) | — |

L3_MD + L4_PH 占 ~68%，是内核主体。

---

## 十一、域类型分类汇总

| 域类型 | 定义 | 数量 |
|--------|------|------|
| **基础设施域** | 精度、内存、日志等基座能力，无四型 | 10 |
| **数据域** | 以 Desc 为主体的 SSOT 存储 | 14 |
| **计算域** | 热路径核心，Ke/Fe/Ctan 等 | 9 |
| **编排域** | 步骤控制、组装调度、作业管理 | 17 |
| **桥接域** | 跨层防腐适配 | 5 |

---

## 十二、维护

- 目录树变更时同步更新本文及 [UFC_ufc_core_目录权威分类.md](UFC_ufc_core_目录权威分类.md)
- 新增域须同步创建 `CONTRACT.md` 并在本矩阵登记
- 校验命令：`Get-ChildItem -Path UFC/ufc_core -Recurse -Filter CONTRACT.md`

*最后更新: 2026-04-25（Phase 0 对齐：Error 域 f90 计数 4→5, Interaction/Bridge 域计数修正, L1 总计 62→64）*