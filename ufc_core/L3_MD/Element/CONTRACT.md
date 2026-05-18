# Element 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Element (单元定义)  
**Version**: v1.0  
**Updated**: 2026-05-07 (`Mesh/` 与 `Elem/` 并列于 `L3_MD/Element/`；`MD_Elem_Def.f90` 位于 `Elem/`)  
**Status**: ✅ Initial complete

---

## 域职责定义

### 核心职责（一句话）

L3 元素域是 **单元类型定义与注册的 SSOT**：持有 Desc（族/拓扑/参数）、State（注册态）、Algo（步控策略）、Ctx（域上下文）。**不做** 单元积分（L4 负责）和运行时路由（L5 负责）。

### 目录布局（Phase 4 + Mesh 子域）

- **四型真源**：`L3_MD/Element/Elem/MD_Elem_Def.f90` — `MODULE MD_Elem_Def`（四型 + 族 Desc/Algo 等，**唯一** Def 源文件）
- **Mesh 子域**：`L3_MD/Element/Mesh/` — 节点/单元实例/拓扑/DOF/面（见该目录 `CONTRACT.md`）
- **单元实现**：`L3_MD/Element/Elem/` — 族注册、Populate/Validate、`MD_Elem_Domain` 等（`USE MD_Elem_Def`）
- **命名对齐**：类型无 `_Base_` 后缀（已满足 R-09）
- **族级文件**（Spring/Sld3D/Sld2D/Shell/Mass/Truss/Surface/Beam/Cohesive/Gasket/Infinite/Dashpot）：位于 `Elem/` 各子目录

### 四型配置（自 `MD_Elem_Def.f90`）

| TYPE | 角色 |
|------|------|
| `MD_Elem_Desc` | 单元定义（id/topo/geom/flags 嵌套辅TYPE） |
| `MD_Elem_State` | 注册状态 |
| `MD_Elem_Algo` | 步控 + 动力策略（`Stp_Ctl_Algo`/`Stp_Ctl_Dyn_Algo`） |
| `MD_Elem_Ctx` | 域上下文 |
| `MD_Elem_Domain` | 域容器 |
| `MD_Elem_Reg` | 域注册表 |
| 族级 `*_Desc` | 12 族专用描述符 |

### L3 / L4 / L5 边界

| 层 | 职责 | 典型模块 |
|----|------|---------|
| L3 | SSOT（单元类型/拓扑/参数定义） | `MD_Elem_Def`, `MD_Elem_Reg`, `MD_Elem_Domain` |
| L4 | 物理计算（Ke/Re 积分） | `PH_Elem_*`（216 文件），`PH_UEL_Def` |
| L5 | 路由编排（Dispatcher） | `RT_Elem_Dispatcher`, `RT_Elem_Stp_Ctl_Algo` |

### 命名规范（R-09/R-10）

- **无 `_Base_` 后缀**：`MD_Elem_Desc`（非 `MD_Elem_Base_Desc`）
- **域缩**：`Elem`（无 `Element` 长名在模块前缀中）
- **辅TYPE**：`Cfg_Id_Desc`, `Cfg_Topo_Desc`, `Stp_Ctl_Algo`, `Stp_Ctl_Dyn_Algo`

### SIO / `*_Arg`（本域偏好）

本域遵循 Principle #14。**保留** `*_Arg` 当一次交互有 ≥2 个会一起演进的字段，或明确被 Harness/生成器/跨层编排消费。**避免**仅承载 `status` 的薄 Arg。

### Cross-references

- **域柱**: P2 Element（全贯通柱 L3/L4/L5）
- **L4 合同**: `L4_PH/Element/CONTRACT.md` (v2.2, UEL-A/B + U1–U4)
- **L5 合同**: `L5_RT/Element/CONTRACT.md`
- **子域合同**: `L3_MD/Element/Elem/CONTRACT.md`（`Elem/` 含 `MD_Elem_Def.f90` 与其它 Populate/族实现）
- **域柱架构**: `UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §P2
