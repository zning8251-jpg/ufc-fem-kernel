# 截面域过程算法 Procedure — L3 正交维（最简）三维度全景

**文档性质**：与 `Section_L3L4L5_four_type_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理 Section 域的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/Section/`（L3 Algo — `MD_Sect_Algo` 仅 1 字段）。

**报告 ID**：`REP-SECT-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的主/辅架构图解，而是以 **过程算法** 为核心视角。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| Section 域 **三维度过程算法**：空间（积分规则）、时间（无独立时间算法）、动作（无独立动作算法） | 具体 **截面积分** 公式推导 |
| L3 **Algo TYPE** 详述 | 非截面域的过程算法（见各域 Procedure 文档） |
| **正交维设计决策** 解释 | **M-S-E 三元 Populate** 细节（见 Material/Element Procedure 文档） |
| **无独立 Pipeline** 的原因 | **9族×17类型** 枚举（见四型合订本 §3.5） |

---

## 1. 三维度过程算法框架（Section 域解读）

### 1.1 空间维度

Section 域的空间维度关注 **默认积分规则 / M-S-E 三元桥接**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **默认积分规则** | 截面→Element 积分阶数建议 | `MD_Sect_Algo%default_integration_rule` |
| **M-S-E 桥接** | 截面→材料(ntens/应力态) + 截面→单元(厚度/取向) | `PH_L4_Populate_Material` / `PH_L4_Populate_Element` |
| **应力态传递** | 截面类型→ntens/ndi/nshr | `SectCompat_Get_StressState` |

### 1.2 时间维度

Section 域 **无独立时间维度算法**。

**设计决策**：截面参数在 Populate 后只读，不参与步/增量/迭代状态机。时间维度由 Element/Material 域管理。

### 1.3 动作维度

Section 域 **无独立动作维度算法**。

**设计决策**：截面不执行独立的计算动作（如本构更新/力计算/施加），仅作为 **M-S-E 三元桥接** 的只读参数源。

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 Algo TYPE（冷路径，Section 主场）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `MD_Sect_Algo` | default_integration_rule (1 字段) | 空间 |

**关键观察**：`MD_Sect_Algo` 仅有 `default_integration_rule` 一个字段——这是所有域中最简的 Algo TYPE。

### 2.2 L4 Algo TYPE

Section 域 **无 L4 域目录**（正交维：仅 L3 存在域目录）。

### 2.3 L5 Algo TYPE（运行期 Populate 级算法控制）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_Sect_Stp_Ctl_Algo` | compat_check_mode / validate_on_populate / integration_rule_override / missing_section_policy | 时间 | ✅ **P3 DONE** |
| `RT_Sect_Algo` | stp_ctl(`RT_Sect_Stp_Ctl_Algo`) | 时间 |

**说明**：P3 补全后，L5 截面侧引入 `RT_Sect_Stp_Ctl_Algo` 管控**Populate 级算法控制**（M-S-E 兼容性校验模式/积分规则冲突解决/Section 缺失策略/Populate 校验与缓存），与 L3 `MD_Sect_Algo`（空间维度：default_integration_rule）形成正交维的双层对齐。`RT_Sect_Stp_Ctl_Algo` 不涉及本构/单元算法参数（由 L4 `PH_Elem_Algo` 管控）。截面为正交维，无热路径计算，L5 Algo 仅服务于 Populate 冷路径策略控制。

---

## 3. Procedure Pointer 架构

Section 域 **无 Procedure Pointer**。

**设计决策**：正交维不需要可插拔算法——截面参数是只读的、静态的。

---

## 4. 无独立 Pipeline（正交维设计决策）

### 4.1 Section 在全局管线中的角色

```text
Populate 冷路径（Section 参与）:
  L3 冷存储: MD_Sect_Desc / MD_Sect_Algo
    │
    ├── PH_L4_Populate_Material: sect_id → ntens/应力态 → PH_Mat_Desc
    │   └── Algo 消费: MD_Sect_Algo%default_integration_rule (影响积分点数)
    │
    ├── PH_L4_Populate_Element:  sect_id → 厚度/取向 → PH_Elem_Desc
    │   └── Algo 消费: MD_Sect_Algo%default_integration_rule (建议积分阶数)
    │
    └── MD_SectCompat::Validate_Triple (M-S-E 三元兼容性校验)
        └── 确保截面/材料/单元三者参数一致
```

### 4.2 热路径（Section 不参与）

```text
全局迭代环:
  Itr Assemble → Element→Material→Contact→LoadBC → K/F
                    ↑ Section 不在此热路径中
  Itr Solve     → K·du = F → du
  Itr Update    → du → u
  Itr Check     → 收敛判断
```

**Section 完全不在热路径中**——它仅在 Populate 冷路径中被消费，之后以只读方式嵌入 Element/Material 的 Desc 中。

---

## 5. 跨域协作（Section 域视角）

### 5.1 M-S-E 三元 Populate（唯一协作模式）

| 协作域 | Populate 操作 | Section 域角色 |
|--------|-------------|---------------|
| Material | sect_id → ntens/应力态 | 提供 `ntens`/`ndi`/`nshr` / `section_type` |
| Element | sect_id → 厚度/取向 | 提供 `thickness`/`orientation` / `integration_rule` |
| Compat | M-S-E 三元校验 | 协调 Material+Section+Element 参数一致性 |

### 5.2 防双写约束

- Section 的 `sect_id` 与 Element 的 `props` 不应同时写入同一字段
- Material 的 `ntens` 只由 Section Populate 写入一次
- 详见 `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` §14.5

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| P3 | ~~Algo 仅 1 字段~~ | ~~`MD_Sect_Algo%default_integration_rule`~~ | ~~保持最简设计~~ → 引入 `RT_Sect_Stp_Ctl_Algo`(M-S-E兼容/积分规则/查询) | ✅ **DONE** |
| — | 无 Pipeline / PTR | 正交维设计决策 | 保持现状 |

**完备性评级**：✅ **正交维 Populate 级算法控制已补全**（空间: L3 integration_rule, 时间: L5 Stp_Ctl_Algo; 动作: 无独立动作——截面不参与热路径计算）

---

## 7. 设计原则（Section 域特化）

1. **正交维无独立算法**：截面参数在 Populate 后只读，不参与运行时计算。
2. **M-S-E 三元桥接唯一职责**：Section 的过程算法角色仅限于 Populate 冷路径中的参数桥接。
3. **default_integration_rule 为建议值**：最终积分阶数由 Element `Stp_Ctl_Algo%integration_order` 决定，Section 仅提供建议。
4. **防双写约束**：Section `sect_id` 与 Element `props` 不可同时写入同一字段。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `Section_L3L4L5_four_type_synthesis.md` | 四型合订本；§3.5 主/辅架构图解 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.3 | 过程算法全景合订（根 stub）；本文为 Section 域专域扩展 |
| `L3_MD/Section/CONTRACT.md` | L3 合同卡；Algo TYPE 字段级真源 |
| [Material_Procedure_Algorithm.md](../Material_Procedure_Algorithm.md) | Material Procedure；M-S-E Populate 中 Section→Material |
| [Element_Procedure_Algorithm.md](../Element_Procedure_Algorithm.md) | Element Procedure；M-S-E Populate 中 Section→Element |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/Section_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/Section_Procedure_Algorithm.md` 为 stub。四型合订本：`Section_L3L4L5_four_type_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
