# UFC 推演卡总索引

> **版本**: v1.0 | **日期**: 2026-04-26
>
> **关联**: [UFC_PhaseVerb_过程双轴体系.md](UFC_PhaseVerb_过程双轴体系.md) · [DERIVATION_CARD_Template.md](../../templates/DERIVATION_CARD_Template.md)
>
> 覆盖 6 层 / 46 域 / 全部 `*_Core.f90` 过程

---

## 按层索引

### L1_IF — 基础设施层（8 域）

| 域 | 推演卡 | 过程数 | 域类型 | Phase 范围 |
|----|--------|--------|--------|-----------|
| Base | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#base) | 6 | 数据域 | Config |
| Precision | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#precision) | 7 | 数据域 | Config |
| Registry | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#registry) | 9 | 数据域 | Config |
| Monitor | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#monitor) | 7 | 观测域 | (any) |
| Log | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#log) | 9 | 观测域 | (any) |
| IO | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#io) | 8 | 数据域 | Config, Step |
| Memory | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#memory) | 7 | 数据域 | Config |
| Error | [L1_IF 综合卡](DERIVATION_CARD_L1_IF.md#error) | 7 | 数据域 | (any) |

### L2_NM — 数值方法层（5 域）

| 域 | 推演卡 | 过程数 | 域类型 | Phase 范围 |
|----|--------|--------|--------|-----------|
| **Solver** | [独立卡](DERIVATION_CARD_NM_Solver.md) | 14 | 计算域 | Config, Iteration |
| Base | [L2_NM 综合卡](DERIVATION_CARD_L2_NM.md#base) | 11 | 工具域 | (any) |
| Matrix | [L2_NM 综合卡](DERIVATION_CARD_L2_NM.md#matrix) | 8 | 数据域 | Config, Iteration |
| TimeInt | [L2_NM 综合卡](DERIVATION_CARD_L2_NM.md#timeint) | 7 | 计算域 | Increment |
| ExternalLibs | [L2_NM 综合卡](DERIVATION_CARD_L2_NM.md#externallibs) | 7 | 桥接域 | Config |

### L3_MD — 模型描述层（15 域）

| 域 | 推演卡 | 过程数 | 域类型 | Phase 范围 |
|----|--------|--------|--------|-----------|
| Model | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#model) | 10 | 数据域 | Config |
| Analysis | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#analysis) | 8 | 数据域 | Config |
| Mesh | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#mesh) | 9 | 数据域 | Config |
| Material | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#material) | 9 | 数据域 | Config |
| Section | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#section) | 8 | 数据域 | Config |
| Part | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#part) | 6 | 数据域 | Config |
| Assembly | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#assembly) | 7 | 数据域 | Config |
| Boundary | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#boundary) | 7 | 数据域 | Config |
| Constraint | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#constraint) | 8 | 数据域 | Config |
| Field | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#field) | 7 | 数据域 | Config |
| Interaction | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#interaction) | 8 | 数据域 | Config |
| KeyWord | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#keyword) | 9 | 数据域 | Config |
| Output | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#output) | 7 | 数据域 | Config |
| WriteBack | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#writeback) | 7 | 桥接域 | Step |
| Bridge | [L3_MD 综合卡](DERIVATION_CARD_L3_MD.md#bridge) | — | 桥接域 | Populate |

### L4_PH — 物理层（6 域）

| 域 | 推演卡 | 过程数 | 域类型 | Phase 范围 |
|----|--------|--------|--------|-----------|
| **Element** | [独立卡](DERIVATION_CARD_PH_Element.md) | 9 | 计算域 | Config, Local |
| **Material** | [独立卡](DERIVATION_CARD_PH_Material.md) | 6 | 分发域 | Config, Local |
| **Material/Elas** | [独立卡](DERIVATION_CARD_PH_Mat_Elas.md) | 7 | 计算域 | Config, Local |
| **LoadBC** | [独立卡](DERIVATION_CARD_PH_LoadBC.md) | 9 | 混合域 | Config, Iteration |
| **Constraint** | [独立卡](DERIVATION_CARD_PH_Constraint.md) | 7 | 计算域 | Config, Iteration |
| Contact | [L4_PH 补充卡](DERIVATION_CARD_L4_PH_Extra.md#contact) | 8 | 计算域 | Config, Iteration, Local |
| Field | [L4_PH 补充卡](DERIVATION_CARD_L4_PH_Extra.md#field) | 7 | 计算域 | Local |

### L5_RT — 运行时层（10 域）

| 域 | 推演卡 | 过程数 | 域类型 | Phase 范围 |
|----|--------|--------|--------|-----------|
| **StepDriver** | [独立卡](DERIVATION_CARD_RT_StepDriver.md) | 13 | 编排域 | Config–Iteration |
| Assembly | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#assembly) | 13 | 编排域 | Config, Iteration |
| Solver | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#solver) | 7 | 编排域 | Config, Iteration |
| Element | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#element) | 9 | 编排域 | Iteration, Local |
| Material | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#material) | 7 | 编排域 | Config, Local |
| LoadBC | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#loadbc) | 7 | 编排域 | Iteration |
| Contact | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#contact) | 7 | 编排域 | Iteration |
| Output | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#output) | 8 | 编排域 | Step |
| WriteBack | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#writeback) | 7 | 桥接域 | Step |
| Logging | [L5_RT 综合卡](DERIVATION_CARD_L5_RT.md#logging) | 8 | 观测域 | (any) |

### L6_AP — 应用层（8 域）

| 域 | 推演卡 | 过程数 | 域类型 | Phase 范围 |
|----|--------|--------|--------|-----------|
| Config | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#config) | 11 | 数据域 | Config |
| Input | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#input) | 8 | 数据域 | Config |
| Job | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#job) | 7 | 编排域 | Config, Step |
| Output | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#output) | 10 | 数据域 | Step |
| Registry | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#registry) | 10 | 数据域 | Config |
| Solver | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#solver) | 6 | 编排域 | Config, Step |
| UI | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#ui) | 8 | 观测域 | (any) |
| Bridge | [L6_AP 综合卡](DERIVATION_CARD_L6_AP.md#bridge) | — | 桥接域 | Populate |

---

## 统计

| 层 | 域数 | 过程总数 | 独立卡 | 综合卡 |
|----|------|---------|--------|--------|
| L1_IF | 8 | ~60 | 0 | 1 |
| L2_NM | 5 | ~47 | 1 | 1 |
| L3_MD | 15 | ~114 | 0 | 1 |
| L4_PH | 7 | ~53 | 5 | 1 |
| L5_RT | 10 | ~86 | 1 | 1 |
| L6_AP | 8 | ~60 | 0 | 1 |
| **合计** | **53** | **~420** | **7** | **6** |

## 域类型分布

| 域类型 | 数量 | 典型 Phase | 特征 |
|--------|------|-----------|------|
| 数据域 | 22 | Config | CRUD 动词为主，Init/Access 密集 |
| 计算域 | 11 | Local, Iteration | Compute 密集，HOT_PATH |
| 编排域 | 10 | Step–Iteration | Control 密集，状态机 |
| 桥接域 | 5 | Populate | Bridge 动词为主 |
| 观测域 | 3 | (any) | Access 为主，跨 Phase |
| 分发域 | 1 | Local | Control(Route) + Compute |
| 混合域 | 1 | Iteration | Compute + Assemble |
