# 二元结构改造推广指南

> **版本**: v1.0  
> **日期**: 2026-05-11  
> **关联文档**:  
> - [Material_Domain_Binary_Structure_Audit.md](./Material_Domain_Binary_Structure_Audit.md) — 审计报告  
> - [Material_Domain_Binary_Structure_Template.md](./Material_Domain_Binary_Structure_Template.md) — 模板规范  
> - [Material_Domain_Reform_Log.md](./Material_Domain_Reform_Log.md) — 改造日志

---

## 1. Material域改造经验总结

### 1.1 改造范围与工作量统计

| 指标 | 数量 | 说明 |
|------|------|------|
| 审计模块总数 | 69 | 域级12 + 族级57 |
| 覆盖族数 | 11 | Elas/Plast/Geo/Damage/Hyper/Creep/Composite/Thermal/Acoustic/Viscoelas/User |
| **新增文件** | 4 | Geo_Core + Damage_Core + Comp_Core + Mat_Dsp |
| **修改文件** | 1 | PH_Mat_Core.f90 (USE引用更新) |
| **重命名** | 1 | PH_Mat_Dispatch → PH_Mat_Dsp |
| 命名合规率 | 96% | 66/69 合规 |
| 四型覆盖率 | 100% | 11/11族全覆盖 Desc/State/Algo/Ctx + Args |
| 后缀闭集定义 | 12种 | 封闭后缀集合 |

### 1.2 关键决策回顾

| 决策 | 选项 | 最终选择 | 理由 |
|------|------|----------|------|
| `_Brg` 创建策略 | 每族必备 vs 按需 | **按需** | 仅Elas直连L5，其余通过域级S2间接桥接 |
| `_Proc` 定位 | 必选 vs 可选 | **可选** | 仅Geo等有复杂L3→L4映射时才需要 |
| `_Core` 创建策略 | 全族必备 vs 多模型必选 | **多模型必选** | 单模型族(User)无需独立Core |
| Dispatch桩函数模式 | 直接调用 vs delegate桩 | **delegate桩** | 避免修改Eval层现有工作代码 |
| 旧文件处置 | 删除 vs 保留标记 | **保留 + DEPRECATED** | 向后兼容 + CI门禁渐进 |
| MODULE名 vs 过程名 | 同步改 vs 仅改MODULE | **仅改MODULE** | 最小化下游影响 |

### 1.3 遇到的问题与解决方案

| 问题 | 根因 | 解决方案 | 耗时 |
|------|------|----------|------|
| 族级Core签名不统一 | Plast族5模型有3种签名模式共存 | 新Core使用delegate桩包装，不改现有模型Core签名 | 0.5d |
| `_Core`后缀歧义 | `Domain_Core`的`_Core`含义≠族级`_Core` | 头部注释标注`ROLE: Domain-Def`消歧义 | 0.1d |
| Dead USE残留 | 重命名后旧USE未清理 | 全仓grep + 统一更新 | 0.3d |
| Legacy UMAT签名不兼容 | 229KB LegacyFacadeUMATs 不可改 | FROZEN标记 + 等L5全切 | — |
| DP_Core 与 DruckerPrager_Core 功能重叠疑问 | 审查发现互补关系(SIO核心+Legacy facade) | 均保留，Core统一分发 | 0.2d |

### 1.4 核心教训

> **TYPE体系映射是主要难点**：当统一Core需要调用不同模型Core时，各模型Core的输入TYPE(Desc/State)可能来自不同体系（SIO typed vs Legacy UMAT arrays vs 自定义local TYPE）。delegate桩模式通过"包而不改"策略绕过了这个难题，但并未根本解决。后续需在Phase 3统一各模型签名到`(desc, state, algo, ctx, status)`五参数形式。

---

## 2. 通用二元结构改造方法论 (SOP)

### 阶段总览

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ 1.盘点  │───→│ 2.差异  │───→│ 3.模板  │───→│ 4.增量  │───→│ 5.验证  │───→│ 6.文档  │
│         │    │  分析   │    │  设计   │    │  改造   │    │  闭环   │    │  同步   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### 阶段1: 盘点

**目标**: 建立域内所有f90模块的全景视图

**步骤**:
1. 列出域目录(L4_PH/<Domain>/)下所有`.f90`文件
2. 对每个文件标注：
   - 文件大小（识别巨文件 > 50KB）
   - MODULE名
   - 主要包含内容：TYPE定义 / SUBROUTINE/FUNCTION / 混合
3. 生成分类统计表：
   - 数据结构文件数
   - 过程算法文件数
   - 混合文件数（需拆分）
4. 识别子族/子目录结构

**产出**: `<Domain>_Domain_Binary_Structure_Audit.md` 的第1-2节

### 阶段2: 差异分析

**目标**: 对照后缀规范表，标注现状与目标的差距

**步骤**:
1. 将12种后缀规范适配到本域（域前缀替换：`PH_Mat_` → `PH_<Dom>_`）
2. 对每个现有文件标注：
   - 当前后缀是否在闭集内
   - 是否需要重命名
   - 是否需要拆分（巨文件 > 50KB）
3. 识别缺失项：
   - 域级必选文件是否齐备（Def/Core/Dsp/Reg/Enum）
   - 族级必备文件是否齐备（Def/Eval）
4. 生成差异矩阵

**产出**: 差异矩阵表 + 不合规项清单

### 阶段3: 模板设计

**目标**: 针对本域特性，定义域级和族级文件标准集

**步骤**:
1. 确定本域的"族"粒度（类比Material的11族）
2. 定义域级文件标准集（参照Material的12个域级文件）
3. 定义族级最小必备集 / 标准集 / 完整集
4. 选定标杆族（最完善的族作为参考实现）
5. 定义本域特有后缀（如有必要，但尽量复用12种通用后缀）

**产出**: `<Domain>_Domain_Binary_Structure_Template.md`

### 阶段4: 增量改造

**目标**: 以族为单位，按优先级逐个改造

**原则**:
- **标杆先行**: 先完善标杆族到100%合规
- **由简到繁**: 单模型族 → 多模型族
- **桩函数模式**: 新增统一Core时用delegate桩，不改现有实现签名
- **最小变更**: 能不动的不动，只做必要新增和重命名

**步骤**:
1. 选择本轮目标族
2. 创建缺失文件（Def/Eval/Core）
3. 执行重命名（git mv + USE更新）
4. 更新域级注册（Reg/Dsp/Populate）

### 阶段5: 验证闭环

**目标**: 每族改造后确保无回归

**检查清单**:
- [ ] 语法检查: 所有新增/修改文件无编译错误
- [ ] 引用检查: `USE`语句无dead引用、无循环依赖
- [ ] CONTRACT验证: CI脚本 `check_contracts.py` 通过
- [ ] 命名检查: CI脚本 `check_naming.py` 通过
- [ ] 功能验证: `ufc_harness` 相关测试用例通过

### 阶段6: 文档同步

**目标**: 保持文档与代码一致

**更新清单**:
- [ ] `CONTRACT.md` 版本号递增 + 更新文件清单
- [ ] `GOVERNANCE.md` 更新域规模统计
- [ ] 本文档（推广指南）更新各域状态

---

## 3. 其余5域差异化策略

### 3.1 域规模总览

| 域 | L4_PH文件数 | L4_PH子目录数 | L5_RT文件数 | 特征 |
|----|------------|--------------|------------|------|
| **Element** | ~36(根)+180(子族) | 20 | 14 | 超大域，按单元类型分族 |
| **Contact** | ~2(根)+20(子模块) | 10 | 9 | 中型域，功能模块化分层 |
| **LoadBC** | 13 | 0 | 13 | 中型域，Load+BC双子系统 |
| **Output** | 0 | 0 | 0* | 空域（待建） |
| **WriteBack** | 2 | 0 | 8 | 小型域，L5为主 |
| **Material** ✓ | 69 | 12 | 27 | 已完成改造 |

*注: L5_RT目录列表显示Output有12项，但直接访问为空，需确认是否已迁移。

---

### 3.2 Element域

#### 当前规模

| 类别 | 子族 | 文件数 | 最大文件 |
|------|------|--------|----------|
| 根级域文件 | — | 36 | PH_ElemContm_Ops.f90 (**136KB**) |
| Beam | B21/B22/B23/B31/B32/B33系列 | 34 | PH_Elem_B31.f90 (49KB) |
| Shell | S3/S4/S6/S8/S9/DS系列 | 14 | PH_Elem_S4.f90 (58KB) |
| Solid3D | C3D4/C3D6/C3D8/C3D10/C3D15/C3D20/C3D27 | 14 | PH_Elem_C3D8.f90 (**111KB**) |
| Solid2D | — | 13 | — |
| Solid2Dt | — | 13 | — |
| Solid3Dt | — | 8 | — |
| Porous | 耦合孔隙元素 | 20 | PH_Elem_C3D8P.f90 (35KB) |
| Shared | 跨族共享工具 | 24 | PH_Elem_Quality.f90 (56KB) |
| Special | Cohesive/Gasket/Rigid/Mass | 13 | — |
| Acoustic | — | 12 | — |
| Thermal | — | 5 | — |
| Dashpot/Truss/Spring/Pipe/Infinite | — | 12 | — |
| **合计** | | **~218** | |

#### 与Material域的异同

| 维度 | Material域 | Element域 | 影响 |
|------|-----------|-----------|------|
| 族粒度 | 材料类型(Elas/Plast等) | 单元拓扑(Beam/Shell/Solid等) | 族数相近但文件数差10倍 |
| 族内模型 | 少量(1-5模型/族) | 大量(Beam有33个变体) | 不能每模型建一个Core |
| 数据结构 | 四型(Desc/State/Algo/Ctx) | 已有Def(Beam_Def/Shell_Def等) | 基础较好 |
| 巨文件 | 229KB(Legacy, FROZEN) | **136KB**(PH_ElemContm_Ops, **活跃**) | 必须拆分 |
| 过程算法 | SIO签名基本统一 | 混杂(旧式长参数列表 + TYPE) | 签名统一工作量大 |
| 共享层 | Shared/(跨族工具) | Shared/(24文件) | 类似 |

#### 二元结构适配建议

**重点处置: PH_ElemContm_Ops.f90 (136KB)**

这是活跃代码（非Legacy FROZEN），必须拆分：
- 按功能拆分为：`PH_Elem_Stiff_Eval.f90`(刚度)、`PH_Elem_Mass_Eval.f90`(质量)、`PH_Elem_Force_Eval.f90`(内力)、`PH_Elem_Thermal_Eval.f90`(热)
- 每个拆分文件 < 40KB

**域级文件标准**:
- `PH_Elem_Def.f90` ✓ 已有
- `PH_Elem_Core.f90` ✓ 已有
- `PH_Elem_Eval.f90` ✓ 已有
- `PH_Elem_Reg.f90` ✓ 已有
- 需补: `PH_Elem_Dsp.f90`(从FeDispatch/KeDispatch合并)、`PH_Elem_Enum.f90`

**族级标准**: 每族最小集 = `<Type>_Def.f90` + 各型号实现文件
- 已有Def: Beam_Def ✓, Shell_Def ✓, Sld3D_Def ✓
- 各型号文件(B31/S4/C3D8等)视为"模型_Core"等价物

#### 预估工作量

| 项目 | 工作量 |
|------|--------|
| 盘点+审计 | 3d |
| PH_ElemContm_Ops.f90 拆分 | 5d |
| 域级文件补全(Dsp/Enum) | 1d |
| 族级Def补全(缺失族) | 2d |
| 验证+文档 | 2d |
| **合计** | **~13d** |

---

### 3.3 Contact域

#### 当前规模

| 类别 | 文件数 | 关键文件 |
|------|--------|----------|
| 域根级 | 2 | PH_Cont_Core.f90(9.5KB), PH_Cont_Def.f90(56KB) |
| Core/ | 9 | PH_Cont_Mgr.f90(**92KB**), NTS_Eval(41KB), CSR(23KB) |
| Search/ | 5 | ContSearch_Adv(**48KB**), BVH系列 |
| Friction/ | 2 | PH_Cont_Friction.f90(14KB) |
| Thermal/ | 2 | ThermoMech(13KB), ThermalCont_Def(19KB) |
| AI/ | 1 | AI插槽占位 |
| Domain/Explicit/Self/Wear | 各1 | 子功能模块 |
| **合计** | **~25** | |

#### 子模块结构

```
Contact/
├── [域级] PH_Cont_Core.f90 + PH_Cont_Def.f90
├── Core/       — 核心算法(NTS投影、罚函数、ALM、管理器)
├── Search/     — 接触搜索(BVH树、CCD连续碰撞)
├── Friction/   — 摩擦模型
├── Thermal/    — 热接触
├── AI/         — AI增强接触(占位)
├── Domain/     — 域级操作
├── Explicit/   — 显式动力学接触
├── Self/       — 自接触
└── Wear/       — 磨损模型
```

#### 二元结构适配建议

**关键处置: PH_Cont_Mgr.f90 (92KB)**
- 职责过重：包含接触对管理、初始化、更新、输出等
- 建议拆分为: `PH_Cont_Mgr_Init.f90` + `PH_Cont_Mgr_Update.f90` + `PH_Cont_Mgr_IO.f90`

**族的映射**: Contact域的"族"对应子模块(NTS/Penalty/ALM/Friction/Thermal)，而非Material的材料类型

**域级文件现状**:
- `PH_Cont_Def.f90` ✓ (但56KB偏大，可能需拆出Aux_Def)
- `PH_Cont_Core.f90` ✓
- 需补: `PH_Cont_Enum.f90`、`PH_Cont_Dsp.f90`、`PH_Cont_Reg.f90`

#### 预估工作量

| 项目 | 工作量 |
|------|--------|
| 盘点+审计 | 1d |
| PH_Cont_Mgr.f90 拆分 | 3d |
| PH_Cont_Def.f90 拆出Aux_Def | 1d |
| 域级文件补全 | 1d |
| 验证+文档 | 1d |
| **合计** | **~7d** |

---

### 3.4 LoadBC域

#### 当前规模

| 子系统 | 文件数 | 关键文件 |
|--------|--------|----------|
| Load子系统 | 5 | PH_Load_Mgr.f90(**44KB**), Load_Def(12KB), Load_Core(7KB) |
| BC子系统 | 6 | PH_BC_Mgr.f90(14KB), BC_Def(8KB), BC_Brg(11KB) |
| 设计文档 | 2 | DESIGN_LoadBC_Domain, DESIGN_LoadBC_HotPath |
| CONTRACT | 1 | CONTRACT.md |
| **f90合计** | **11** | |

#### 双子系统结构

```
LoadBC/
├── [Load] PH_Load_Def.f90        -- 数据结构
├── [Load] PH_Load_Aux_Def.f90    -- 辅TYPE
├── [Load] PH_Load_Core.f90       -- 过程算法
├── [Load] PH_Load_Mgr.f90        -- 管理器(44KB, 需拆分)
├── [Load] PH_Load_NestedToFlat.f90 -- 格式转换
├── [BC]   PH_BC_Def.f90          -- 数据结构
├── [BC]   PH_BC_Aux_Def.f90      -- 辅TYPE
├── [BC]   PH_BC_Core.f90         -- 过程算法
├── [BC]   PH_BC_Brg.f90          -- 桥接层
├── [BC]   PH_BC_Mgr.f90          -- 管理器
├── [BC]   PH_BC_FlatToNested.f90 -- 格式转换
└── [BC]   PH_BC_NestedToFlat.f90 -- 格式转换
```

#### 二元结构适配建议

**关键处置: PH_Load_Mgr.f90 (44KB)**
- 可拆分为: `PH_Load_Mgr_Init.f90`(冷路径) + `PH_Load_Mgr_Apply.f90`(热路径) + `PH_Load_Mgr_Update.f90`(步间更新)

**特殊考量**: LoadBC是"双子系统"域，Load和BC各自有独立Def/Core/Mgr体系
- 不按Material的族模式处理，而是将Load和BC视为两个平行子域
- 域级需要一个统一Dispatch/Core来协调Load+BC

**域级文件补全建议**:
- 需补: `PH_LoadBC_Dsp.f90`(统一入口) 或 `PH_LoadBC_Core.f90`
- 现有BC_Brg ✓ 已存在

#### 预估工作量

| 项目 | 工作量 |
|------|--------|
| 盘点+审计 | 0.5d |
| PH_Load_Mgr.f90 拆分 | 2d |
| 域级统一入口创建 | 1d |
| 命名规范对齐 | 0.5d |
| 验证+文档 | 0.5d |
| **合计** | **~4.5d** |

---

### 3.5 Output域

#### 当前状态

| 层 | 文件数 | 状态 |
|----|--------|------|
| L4_PH/Output | 0 | **完全空** |
| L5_RT/Output | 0* | **待确认** |

*注: 上级目录列表显示12项，但直接访问为空。可能存在索引不一致或已迁移。

#### 二元结构适配建议

**Output域为"待建"域**，改造策略为"从零设计"：
1. 按二元结构模板直接创建域级标准文件集
2. 无Legacy负担，可直接采用最佳实践
3. 参考Material模板定义Output的四型TYPE：
   - `PH_Out_Desc`: 输出配置(哪些变量、频率、格式)
   - `PH_Out_State`: 输出缓冲区状态
   - `PH_Out_Algo`: 输出算法参数(插值/外推方法)
   - `PH_Out_Ctx`: 当前步输出工作区

**族定义建议**: 按输出对象分族(NodeOutput/ElemOutput/ContactOutput/HistoryOutput)

#### 预估工作量

| 项目 | 工作量 |
|------|--------|
| 需求分析+模板设计 | 1d |
| 域级文件创建 | 1d |
| 族级文件创建(4族×2文件) | 2d |
| 验证+文档 | 0.5d |
| **合计** | **~4.5d** |

---

### 3.6 WriteBack域

#### 当前规模

| 层 | 文件 | 大小 |
|----|------|------|
| L4_PH | `PH_WB_Core.f90` | 6.2KB |
| L4_PH | `PH_WB_Def.f90` | 6.6KB |
| L5_RT | `RT_WB_Domain.f90` | **59KB** |
| L5_RT | `RT_WB_Def.f90` | 22KB |
| L5_RT | `RT_WB_Impl.f90` | 12KB |
| L5_RT | `RT_WB_Core.f90` | 7.5KB |
| L5_RT | `RT_WB_Proc.f90` | 9KB |
| L5_RT | `RT_WB_Brg.f90` | 3.6KB |
| L5_RT | `RT_WB_Aux_Def.f90` | 4.1KB |

#### 二元结构适配建议

**L4_PH层已基本合规**: 2文件(Def+Core)符合最小必备集

**L5_RT层需处理**: RT_WB_Domain.f90 (59KB)是主要改造对象
- 建议拆分为按WriteBack目标分的子模块

**域级文件补全**:
- L4需补: `PH_WB_Enum.f90`(如有枚举) 或保持当前最小集
- L5的Def/Core/Brg/Proc结构已较完善

**WriteBack与Output的关系**:
- WriteBack负责"写回"数据到全局数据结构
- Output负责"输出"数据到外部文件
- 二者互补，应在CONTRACT中明确边界

#### 预估工作量

| 项目 | 工作量 |
|------|--------|
| 盘点+审计 | 0.3d |
| RT_WB_Domain.f90 评估(是否需拆分) | 0.5d |
| L4补全(如需) | 0.5d |
| 验证+文档 | 0.3d |
| **合计** | **~1.5d** |

---

## 4. 推荐改造优先级

### 4.1 优先级排序

| 优先级 | 域 | 工作量 | 理由 |
|--------|-----|--------|------|
| ✅ 已完成 | **Material** | — | 标杆域，模板来源 |
| **P1** | **WriteBack** | 1.5d | 最小域，快速验证SOP可复用性；L4已基本合规 |
| **P2** | **LoadBC** | 4.5d | 中等规模，结构清晰(双子系统)；有明确拆分目标(Load_Mgr 44KB) |
| **P3** | **Output** | 4.5d | 从零设计无Legacy负担；可直接按最佳模板创建 |
| **P4** | **Contact** | 7d | 中型域+巨文件(Mgr 92KB)；功能模块化已较好 |
| **P5** | **Element** | 13d | 超大域(218文件)；巨文件(136KB活跃代码)拆分风险最高 |

### 4.2 排序依据

```
                        高 ─┐
                            │  WriteBack ★ (快速验证SOP)
          收益/风险比        │  LoadBC ★★ (结构清晰+中等规模)
                            │  Output ★★★ (从零设计)
                            │  Contact ★★★★ (巨文件拆分)
                        低 ─┤  Element ★★★★★ (超大规模+高风险)
                            └──────────────────────────────────
                             小 ← 工作量 → 大
```

**核心策略**:
1. **快速验证** — WriteBack作为最小测试床，验证SOP各阶段是否可执行
2. **渐进扩大** — LoadBC/Output为中等域，积累经验
3. **攻克难点** — Contact的巨文件拆分积累"活跃代码拆分"经验
4. **最后大战** — Element域规模最大、风险最高，留到团队经验最丰富时执行

### 4.3 里程碑规划

| 里程碑 | 域 | 目标日期 | 交付物 |
|--------|-----|----------|--------|
| M1 | WriteBack | +2d | 审计报告 + 模板 + 改造完成 |
| M2 | LoadBC | +7d | Load_Mgr拆分 + 域级统一入口 |
| M3 | Output | +12d | 全新域结构创建 |
| M4 | Contact | +19d | Mgr拆分 + Def瘦身 |
| M5 | Element | +32d | ElemContm_Ops拆分 + 族级Def补全 |

---

## 附录A: 后缀规范通用化映射

| 通用后缀 | Material | Element | Contact | LoadBC | Output | WriteBack |
|----------|----------|---------|---------|--------|--------|-----------|
| `*_Def` | PH_Mat_*_Def | PH_Elem_*_Def | PH_Cont_*_Def | PH_Load/BC_Def | PH_Out_Def | PH_WB_Def |
| `*_Aux_Def` | PH_Mat_Aux_Def | PH_Elem_Aux_Def | PH_Cont_Ctx_Def | PH_*_Aux_Def | PH_Out_Aux_Def | RT_WB_Aux_Def |
| `*_Eval` | PH_Mat_*_Eval | PH_Elem_Eval | PH_Cont_NTS_Eval | — | — | — |
| `*_Core` | PH_Mat_*_Core | PH_Elem_Core | PH_Cont_Core | PH_Load/BC_Core | PH_Out_Core | PH_WB_Core |
| `*_Dsp` | PH_Mat_Dsp | PH_Elem_*Dispatch | — | — | — | — |
| `*_Reg` | PH_Mat_Reg | PH_Elem_Reg | — | — | — | — |
| `*_Brg` | PH_Mat_*_Brg | PH_ElemRT_Brg | PH_Cont_Brg | PH_BC_Brg | — | RT_WB_Brg |
| `*_Mgr` | — | — | PH_Cont_Mgr | PH_Load/BC_Mgr | — | — |

## 附录B: 巨文件处置策略

| 文件 | 大小 | 域 | 状态 | 策略 |
|------|------|-----|------|------|
| `LegacyFacadeUMATs.f90` | 229KB | Material | FROZEN | 不动，等L5全切后移除 |
| `PH_ElemContm_Ops.f90` | 136KB | Element | **活跃** | 按功能拆分为4个文件 |
| `PH_Elem_C3D8.f90` | 111KB | Element | 活跃 | 评估是否需要拆分(变体合并) |
| `PH_Cont_Mgr.f90` | 92KB | Contact | 活跃 | 按生命周期阶段拆分为3个文件 |
| `PH_NLGeom_Eval.f90` | 75KB | Element | 活跃 | 按几何类型拆分 |
| `RT_WB_Domain.f90` | 59KB | WriteBack | 活跃 | 评估拆分必要性 |
| `PH_Elem_S4.f90` | 58KB | Element | 活跃 | 保留(单元实现完整体) |
| `PH_Cont_Def.f90` | 56KB | Contact | 活跃 | 拆出Aux_Def |
| `RT_Cont_Search.f90` | 48KB | Contact | 活跃 | 已在Search/子目录，可保留 |
| `PH_Load_Mgr.f90` | 44KB | LoadBC | 活跃 | 按冷/热路径拆分为3个文件 |

**拆分阈值**: > 50KB的活跃文件建议拆分，> 30KB的需评估

---

*END OF GUIDE*
