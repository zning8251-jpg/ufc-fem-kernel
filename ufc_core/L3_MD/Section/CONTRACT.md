# Section 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Section (截面类型定义与管理)  
 **Abbreviation**: `Sect`（R-10）；模块前缀 `MD_Sect_*`（推荐）  
**Version**: v3.3
**Updated**: 2026-05-05 (Phase 8: 锁定方案 B + 命名统一)  
**Status**: ✅ ACTIVE (L3-Only SSOT)

### 报告侧：过程算法叙事（stub / archive）

- **入口（根 stub）**：[`Section_Procedure_Algorithm.md`](../../../REPORTS/Section_Procedure_Algorithm.md)；长文：[`archive/Section_Procedure_Algorithm.md`](../../../REPORTS/archive/Section_Procedure_Algorithm.md)。
- **Registry**：[Domain Procedure Registry](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)（与叙事无机器对账；优先级见该 README）。

---

### 域柱正交维决策（方案 B — 锁定）

**Section 域采用方案 B（嵌入 Element），L4 无独立域。**

理由：
1. 截面是 M×E×S 正交第三轴，不是独立贯通柱；消费方主要是 Element 和 Material
2. Populate 一次性灌入足够：sect_id → 厚度/取向/nlayer/integ 等派生量在 Populate 阶段确定，步内只读
3. 防双主源（R-06）：若 L3 `MD_Sect_Desc`（SSOT）与 L4 `PH_Sect_Desc`（独立域）并存，容易导致 Populate 时序混乱

关键约束：
- 方案 B 已锁定：截面主挂载为嵌入 `PH_Elem_*` 方案
- L3 唯一 SSOT：`MD_Sect_Desc` 持有所有截面定义字段
- L4 消费方式：Populate 灌入单元缓存 + 只读 Accessor
- 禁止：`PH_Sect_*` 独立域、L4 持第二套截面 State

详见 [`L4_Gap_Domain_Decisions.md`](../../../REPORTS/archive/L4_Gap_Domain_Decisions.md) §4（冷归档全文）

---

## 1. 域职责定义

### 核心职责
截面类型与属性的 Desc 真相源：截面定义（Solid/Shell/Beam/Membrane/Truss/Cohesive/Gasket/Acoustic/Connector 共 9 族）、材料引用绑定、Material-Section-Element 正交兼容性校验、附加质量属性管理。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 截面 TYPE 定义与注册 | 不做形函数/积分点计算（L4_PH） |
| 材料引用索引（material_ref） | 不做本构求值 |
| M-S-E 三元组兼容性校验 | 不做刚度矩阵装配 |
| 厚度/方向/层数/积分规则存储 | 不做网格拓扑操作 |
| 点质量/非结构质量/转动惯量管理 | 不参与写回 |
| Legacy 同步（UF_SectionDef → MD_SectDesc） | — |

### SIO / `*_Arg`（本域偏好）
不强制每个过程使用 `*_Arg`。域容器的 Add/Get/Validate/GetSummary 已提供 Arg 封装。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — 截面 TYPE、材料引用索引（核心产出）
- **State**: Y(隐式) — `MD_Section_State`（active_sections, total_sections, total_section_area）
- **Algo**: Y — `SectionAlgo`（default_integration_rule）+ M-S-E 兼容性检查
- **Ctx**: Y — `MD_Section_Ctx`（current_section_idx）

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Sect_Base_Desc` | `MD_Sect_Def` | section_id, section_name, mat_id, mat_desc(ptr), thickness, orientation(3), offset, nlayer, integ_npts, integ_rule, section_family, section_type | 多态截面基类（TBP: InitBasic/InitComposite/AssociateMat/Validate/Nullify） |
| `MD_Sect_Registry` | `MD_Sect_Def` | sections(:), nsections, capacity | 截面注册表（TBP: Init/AddSection/GetSectIdx/FindByName/FindByMaterial/Clear） |
| `MD_SectDesc` | `MD_Sect_Def` | name, section_id, section_type, …, `valid` | 扁平 L3 截面行（**无**嵌套 `cfg`） |
| `MD_Section_Catalog_Desc` | `MD_Sect_Def` | `sections(MD_SECTION_MAX)`, `n_sections` | Core 侧定长注册表（与 `MD_Section_Domain%desc_array` 分工） |
| `UF_SectionDef` | `MD_SectLib` | Legacy 截面定义 | TBP: init/set_solid/set_shell/set_beam_*/set_membrane/set_truss/compute_beam_props |
| `PtMassDesc` | `MD_PropMass` | 点质量描述符 | 质量属性 |
| `NonStructMassDesc` | `MD_PropNonStructMass` | 非结构质量描述符 | 非结构质量 |
| `PtMassAltDesc` | `MD_PropPtMass` | 替代点质量描述符 | 替代定义 |
| `RotInertiaDesc` | `MD_PropRotInertia` | 转动惯量描述符 | TBP: GetInertiaMatrix/IsPositiveDefinite |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Section_State` | `MD_Sect_Def` | active_sections, total_sections, total_section_area | 域级截面统计状态 |

### 2.3 Algo 类型（算法配置）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `SectionAlgo` | `MD_Sect_Def` | default_integration_rule | 默认积分规则 |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Section_Ctx` | `MD_Sect_Def` | current_section_idx | 当前截面索引 |

### 域容器

| TYPE 名称 | 来源模块 | 说明 |
|-----------|----------|------|
| `MD_Section_Domain` | `MD_Sect_Def` | desc_array(:) + n_sections + capacity + algo；TBP: Init/Finalize/Add/Get/GetByName/Validate/GetSummary |

### SIO Arg 类型
`MD_Sect_Add_Arg`, `MD_Sect_Validate_Arg`, `MD_Sect_GetSummary_Arg`, `MD_Sect_Get_Arg`, `MD_Sect_GetByName_Arg`（**含** `desc` 命中时回填）

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_Sect_Def.f90` | `MD_Sect_Def` | `_Def` | 域级四型 + Registry + Arg + MD_Section_Domain TBPs + 截面家族/类型常量 | **AUTHORITY** |
| `MD_Sect_Compat.f90` | `MD_SectCompat` | `_Compat` | SECT_MAT_COMPAT(9,11)/SECT_ELEM_COMPAT(9,12) 兼容性矩阵 + SectCompat_Get_StressState | ACTIVE |
| `MD_Sect_Core.f90` | `MD_Sect_Core` | `_Core` | CRUD + Validate_Triple | ACTIVE |
| `MD_Sect_Mgr.f90` | `MD_Sect_Mgr` | `_Mgr` | Legacy 截面管理器 | ACTIVE |
| `MD_Sect_Lib.f90` | `MD_SectLib` | `_Lib` | UF_SectionDef + secdb_init/add/find/get/clear | ACTIVE |
| `MD_Sect_Brg.f90` | `MD_Sect_Brg` | `_Brg` | L3→L4 校验 + 应力态推导 | ACTIVE |
| `MD_Sect_Domain.f90` | `MD_SectDomain` | Domain | 域容器再导出 | ACTIVE |
| `MD_Sect_ionSync.f90` | `MD_SectionSync` | `_Sync` | MD_Section_SyncFromLegacy/PopulateLegacyFromDomain | ACTIVE |
| `MD_Sect_PropMass.f90` | `MD_PropMass` | `_Prop` | *MASS 关键字解析/验证 + PtMassManager | ACTIVE |
| `MD_Sect_PropNonStructMass.f90` | `MD_PropNonStructMass` | `_Prop` | *NONSTRUCTURAL MASS 关键字解析/验证 | ACTIVE |
| `MD_Sect_PropPtMass.f90` | `MD_PropPtMass` | `_Prop` | *POINT MASS 关键字解析/验证 | ACTIVE |
| `MD_Sect_PropRotInertia.f90` | `MD_PropRotInertia` | `_Prop` | *ROTARY INERTIA 关键字解析/验证 | ACTIVE |

### 已删除模块
- ~~`MD_Sect_Mgr.f90`~~ (旧版) — 零调用 Manager（58KB）
- ~~`MD_Section_API.f90`~~ — 零调用 API 封装层

---

## 4. 对外接口（公开 API）

### 域容器 (MD_Section_Domain TBP)
| 接口 | 功能 | 参数 |
|------|------|------|
| `Init` | 域初始化 | capacity, status |
| `Finalize` | 域释放 | status |
| `Add` | 添加截面 | MD_SectDesc, status |
| `Get` | 按索引获取截面 | idx, desc, status |
| `GetByName` | 按名称获取截面 | name, idx, found |
| `Validate` | 截面验证 | idx, status |
| `GetSummary` | 获取域摘要 | summary |

### 兼容性校验
| 接口 | 功能 |
|------|------|
| `SECT_MAT_COMPAT(9,11)` | Section Family × Material Family 兼容性矩阵 |
| `SECT_ELEM_COMPAT(9,12)` | Section Family × Element Family 兼容性矩阵 |
| `MD_Section_Validate_Triple` | M-S-E 三元组合法性校验 |
| `SectCompat_Get_StressState` | Section+Element → StressState → ntens |

### Bridge
| 接口 | 功能 |
|------|------|
| `MD_Section_Brg_Validate_Assignment` | Populate 阶段硬错误拦截 |
| `MD_Section_Brg_Get_StressState` | 桥接阶段派发 ntens |

### 索引查询
| 接口 | 功能 |
|------|------|
| `MD_Section_GetSection_Idx` | 按索引查询截面 |
| `MD_Section_GetSectionByName_Idx` | 按名称查询截面 |

---

## 5. 跨层数据流

```
INP (*SOLID SECTION/*SHELL SECTION/*BEAM SECTION/*MEMBRANE SECTION/...)
  → L6_AP / MD_KW_Mapper (map_solid_section/map_shell_section/map_beam_section)
  → MD_Section_Domain::Add (L3 冷存储)
  → MD_Sect_Compat::Validate_Triple (M-S-E 校验)
  → MD_Sect_Brg → L4 Populate (截面参数注入 L4 Element)
```

### 正交兼容性矩阵（三级校验）

| 级别 | 时机 | 内容 | 模块 |
|------|------|------|------|
| L1 家族级 | 编译期（PARAMETER） | 两张布尔表，族间粗筛 | `MD_SectCompat` |
| L2 模型级 | 运行时（Init 注册） | 特定材料模型的额外单元族限制 | `MD_SectCompat` 覆盖注册 |
| L3 应力态 | 查询时 | Section+Element → StressState → ntens | `SectCompat_Get_StressState` |

### 截面家族定义（9 族）

| ID | 家族 | 常量 | 对应单元族 |
|----|------|------|-----------|
| 1 | Solid | `SECT_FAM_SOLID` | Solid3D, Solid2D, Infinite |
| 2 | Shell | `SECT_FAM_SHELL` | Shell |
| 3 | Beam | `SECT_FAM_BEAM` | Beam |
| 4 | Membrane | `SECT_FAM_MEMBRANE` | Membrane |
| 5 | Truss | `SECT_FAM_TRUSS` | Truss |
| 6 | Cohesive | `SECT_FAM_COHESIVE` | Cohesive |
| 7 | Gasket | `SECT_FAM_GASKET` | Gasket |
| 8 | Acoustic | `SECT_FAM_ACOUSTIC` | Acoustic |
| 9 | Connector | `SECT_FAM_CONNECTOR` | Connector, Mass |

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Material | 上游 T+U | `material_ref` 索引引用 Material Desc |
| R2 | L3_MD/Element/Mesh | 上游 U | Element 通过 elset 绑定 Section |
| R3 | L4_PH/Element | 下游 T+B | Section Desc → L4 Populate 填入截面参数；**截面 L4 主挂载方案 B（嵌入 `PH_Elem_*`）** 写死于 Element CONTRACT §R2，独立 `PH_Sect_*` 仅作视图 |
| R4 | L3_MD/Section/SectCompat | 内部 U | 正交兼容性矩阵校验三元组合法性 |
| R5 | L3_MD/KeyWord | T(合同) | *SECTION 关键字解析写入 |
| R6 | L6_AP/Input | E(外部) | 截面命令解析来源 |
| R7 | L1_IF/Error | U(USE) | 错误码定义 |

### 错误处理

| 错误场景 | 处理方式 |
|----------|----------|
| 截面 ID 不存在 | 返回 `IF_STATUS_INVALID` |
| 材料引用 ID 无效 | 返回 `IF_STATUS_INVALID` |
| 厚度/宽度 ≤ 0 | 返回 `IF_STATUS_INVALID` |
| Section-Material 族不兼容 | 返回 `IF_STATUS_INVALID` / compat=1 |
| Section-Element 族不兼容 | 返回 `IF_STATUS_INVALID` / compat=2 |

所有公开过程通过 `ErrorStatusType` 返回状态。不使用 `STOP`。

**R-08 闭环**：截面冷真源为 **L3 `MD_Sect_Desc`（合并后）唯一 SSOT**；截面 Populate 经 `PH_L4_Populate_Element` 灌入单元缓存；热路径 **只读** Populate 派生量（厚度/取向/ntens）；`sect_id` / `MD_Sect_*` 与 Populate 读序须与 **`OnePager`** 及 **Element/Material Populate** 同一结论；截面主挂载 **方案 B 写死**，方案 A 仅作视图，**禁止**双主源。

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 截面属性（厚度/惯性矩/梁截面形状）映射 ABAQUS *SECTION 关键字参数 |
| **逻辑链** | KeyWord Parser→Section Desc→elem_section_ref→L4 Populate 消费截面参数 |
| **计算链** | 无（L3 仅存储截面 Desc） |
| **数据链** | Section Desc(冷)存储在 MD_SectDomain；与 Material 通过 material_ref 索引关联 |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 仅 Desc，不做形函数/积分 | 硬 | Code Review | — |
| 不使用 STOP | 硬 | Harness | H-ERR-01 |
| 材料引用必须有效 | 硬 | Validate | — |
| 非负厚度/几何参数 | 硬 | 物理约束校验 | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 测试覆盖率 | 软 | 待建 | — |

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.1 | 2026-04-26 | 对齐磁盘文件名；记录删除模块 |
| v3.2 | 2026-05-04 | **G5/G10 合同闭环**：R-08 截面横切闭环；R3 增方案 B 闭合说明 |
| v3.1 | 2026-04-30 | P1 竖切：删重复 `MD_Section_Desc`；`MD_SectDesc` 增 `valid`；域 Validate 用扁平 `section_type`；Populate 用 `MdSectType_To_UFSectionType` |
| v3.0 | 2026-04-28 | 标准化为 7 章节格式 |
