# Section 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: Section (截面正交维)  
**Prefix**: `RT_Sect_*`  
**Version**: v1.0  
**Created**: 2026-05-04  
**Status**: ACTIVE — 正交维算法控制层

### v1.0（2026-05-04）— P3 缺口补全

- **新增** `RT_Sect_Stp_Ctl_Algo`：步级截面 Populate/校验/查询算法控制。
- **新增** `RT_Sec_Algo`：主 Algo TYPE 嵌入 `stp_ctl`。
- **设计定位**：截面为正交维，L5 仅管控 Populate 级策略，不参与热路径计算。

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 Section 域，正交维算法控制层
- **职责**:
  - 持有 `RT_Sect_Stp_Ctl_Algo`（步级 Populate/校验/查询策略）
  - 管理 M-S-E 兼容性校验模式（strict/relaxed/skip）
  - 控制积分规则冲突解决策略（L3默认/Element覆盖/Fatal）
  - 管理 Section 缺失策略（error/default/skip）
  - 控制 Populate 校验与缓存策略

### 非职责
- 不存储截面参数（Desc = L3 `MD_Sect_Desc` SSOT）
- 不执行截面计算（无热路径）
- 不持有截面状态（State = L3 `MD_Section_State`）
- 不做本构/单元计算（由 Material/Element 域负责）
- 不替代 `RT_Elem_Sect`（单元侧截面桥接仍归 Element 域）

---

## 2. 四类 TYPE 清单

### 2.1 Desc
- **(委托)** — L5 不持有 Desc，引用 L3 `MD_Sect_Desc`（经 Populate → L4 `PH_Elem_Desc`）

### 2.2 State
- **(委托)** — 截面状态由 L3 `MD_Section_State` 持有

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Sect_Stp_Ctl_Algo` | `RT_Sec_Aux_Def` | compat_check_mode, validate_on_populate, integration_rule_override, allow_integration_conflict, allow_missing_material, missing_section_policy, section_cache_enabled, force_repopulate, suppress_compat_check | 步级校验/Populate/查询控制（P3 补全，[Phase:Stp|Verb:Ctl]） |
| `RT_Sec_Algo` | `RT_Sec_Def` | stp_ctl(`RT_Sect_Stp_Ctl_Algo`) | L5 截面算法控制参数（正交维的 Populate 级 Algo） |

**注意**：`RT_Sect_Stp_Ctl_Algo` 管控 L5 Populate 策略（M-S-E 兼容/积分规则/查询），不涉及本构/单元算法参数（由 L3 `MD_Sect_Algo` / L4 `PH_Elem_Algo` 管控）。

### 2.4 Ctx
- **(委托)** — 截面上下文由 L3 `MD_Sect_Ctx` 持有

L5/Section 保留**调度 Algo**，Desc/State/Ctx 全部委托给 L3。

**权威 TYPE 模块**: `RT_Sec_Def.f90` (ACTIVE) / `RT_Sec_Aux_Def.f90` (ACTIVE, AUX-DEF for P3 sub-Algo)

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `RT_Sec_Aux_Def.f90` | `RT_Sec_Aux_Def` | `_Aux_Def` (辅Algo定义) | RT_Sect_Stp_Ctl_Algo | **ACTIVE** (P3 GAP-FILL) |
| `RT_Sec_Def.f90` | `RT_Sec_Def` | `_Def` (TYPE) | RT_Sect_Algo | **ACTIVE** (P3 GAP-FILL) |

**关联模块**（非本目录）：
| 文件 | MODULE | 目录 | 说明 |
|------|--------|------|------|
| `RT_Elem_Sect.f90` | `RT_Elem_Sect` | `L5_RT/Element/` | 单元侧截面桥接（Init/Populate/GetMatDesc） |

---

## 4. 对外接口（公开 API）

### 常量（RT_Sec_Aux_Def）

| 常量名 | 值 | 说明 |
|--------|---|------|
| `RT_SEC_COMPAT_STRICT` | 0 | M-S-E 不匹配时终止 |
| `RT_SEC_COMPAT_RELAXED` | 1 | M-S-E 不匹配时警告 |
| `RT_SEC_COMPAT_SKIP` | 2 | 跳过 M-S-E 校验 |
| `RT_SEC_IRULE_USE_L3` | 0 | 使用 L3 default_integration_rule |
| `RT_SEC_IRULE_USE_ELEM` | 1 | Element 覆盖优先 |
| `RT_SEC_IRULE_FATAL` | 2 | 冲突时 Fatal |
| `RT_SEC_MISSING_ERROR` | 0 | section_id 缺失时报错 |
| `RT_SEC_MISSING_DEFAULT` | 1 | 返回默认 Solid 截面 |
| `RT_SEC_MISSING_SKIP` | 2 | 跳过该单元 |

---

## 5. 跨层数据流

### Populate 数据流
```
L3_MD/Section (MD_Sect_Desc, SSOT)
  → RT_Elem_Sect_Populate (L3→L5 Registry bridge)
    → RT_Sect_Stp_Ctl_Algo 控制:
       - validate_on_populate: 是否校验
       - compat_check_mode: M-S-E 校验严格度
       - force_repopulate: 是否强制重填充
```

### 查询数据流
```
Element Loop → RT_Elem_Sect_GetMatDesc
  → RT_Sect_Stp_Ctl_Algo 控制:
     - missing_section_policy: section_id 不存在时的行为
     - section_cache_enabled: 是否缓存查询
```

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Section | S (数据来源) | Desc 经 Populate |
| R2 | L5_RT/Element | S (消费侧) | RT_Elem_Sect 消费 Section 数据 |
| R3 | L5_RT/Material | S (M-S-E 协作) | compat_check_mode 控制兼容性校验 |
| R4 | L4_PH/Element | S (下游) | Populate 参数注入 |

### 约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| 不存储截面参数 | **硬** | SSOT 在 L3 |
| 不参与热路径计算 | **硬** | 截面仅 Populate 冷路径 |
| 不替代 RT_Elem_Sect | **硬** | 单元侧桥接仍归 Element 域 |
| compat_check_mode 仅影响 L5 | **软** | L3 SectCompat 自有校验逻辑 |

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 正交维设计 | L5 不存储 Desc/State，仅持有 Algo | ✅ 已实现 |
| A2 | Stp_Ctl_Algo | RT_Sect_Stp_Ctl_Algo 覆盖 Populate/校验/查询 | ✅ 已实现 |
| A3 | 常量定义 | 9 个策略常量已定义 | ✅ 已实现 |
| A4 | 与 RT_Elem_Sect 分界 | Algo 控制在本域，桥接在 Element 域 | ✅ 已实现 |
