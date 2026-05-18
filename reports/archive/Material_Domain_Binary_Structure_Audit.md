# Material域二元结构审计报告

> **版本**: v1.0  
> **日期**: 2026-05-11  
> **关联文档**: [Material_Domain_Binary_Structure_Template.md](./Material_Domain_Binary_Structure_Template.md)  
> **标杆参考**: `ufc_core/L4_PH/Material/Elas/PH_Mat_Elas_Def.f90`, `PH_Mat_Elas_Eval.f90`

---

## 1. 概述

### 1.1 二元结构定义

Material域采用**二元结构**（Binary Structure）组织所有模块：

| 元 | 定义 | 文件后缀 | 职责边界 |
|----|------|----------|----------|
| **数据结构元** (Data Structure) | TYPE定义、枚举常量、参数声明 | `*_Def`, `*_Aux_Def`, `*_Enum`, `*_KernelDefn` | 零过程逻辑，纯声明 |
| **过程算法元** (Process Algorithm) | 子程序/函数实现 | `*_Eval`, `*_Core`, `*_Brg`, `*_Dsp`, `*_Reg`, `*_Populate` | 依赖数据结构元，实现业务 |

### 1.2 审计范围

| 维度 | 数量 | 说明 |
|------|------|------|
| f90模块总数 | 69 | 含域级12 + 族级57 |
| 族(Family) | 11 | Elas/Plast/Geo/Damage/Hyper/Creep/Composite/Thermal/Acoustic/Viscoelas/User |
| 域级文件 | 12 | Material/ 根目录直接文件 |
| Dispatch文件夹 | 6 | Legacy/Staging过渡文件 |

### 1.3 审计结论

- **命名合规率**: 96% (66/69)
- **四型完备率**: 100% (11/11族全具备 Desc/State/Algo/Ctx + Args)
- **P0 Blocker**: 1项 (LegacyFacadeUMATs.f90, 229KB)
- **需重命名**: 1项 (PH_Mat_Dispatch.f90 → PH_Mat_Dsp.f90)
- **需标注DEPRECATED**: 1项 (PH_Mat_Core_Types.f90)
- **歧义待决**: 1项 (PH_Mat_Interp_Core.f90 的 `_Core` 后缀)

---

## 2. 域级文件审计表

| # | 文件名 | 二元归属 | 目标后缀 | 当前合规 | 备注 |
|---|--------|----------|----------|----------|------|
| 1 | `PH_Mat_Def.f90` | 数据结构 | `*_Def` | ✓ | 再导出枢纽，聚合所有族Def |
| 2 | `PH_Mat_Aux_Def.f90` | 数据结构 | `*_Aux_Def` | ✓ | Phase×Verb辅助TYPE集合 |
| 3 | `PH_Mat_Domain_Core.f90` | 混合 | `*_Domain` | ⚠ | 含`_Core`后缀，但语义为"域核心定义"非"计算内核" |
| 4 | `PH_Mat_Core.f90` | 过程算法 | `*_Core` | ✓ | S1-S4执行流（Init→Populate→Dispatch→WriteBack） |
| 5 | `PH_Mat_Core_Types.f90` | 数据结构 | **DEPRECATED** | ✗ | Legacy `MatPoint_In`/`MatPoint_Out`，已被SIO Args替代 |
| 6 | `PH_Mat_Enum.f90` | 数据结构 | `*_Enum` | ✓ | 枚举常量（族ID、子类型ID） |
| 7 | `PH_Mat_Dispatch.f90` | 过程算法 | `*_Dsp` | ✗ | **需重命名** → `PH_Mat_Dsp.f90` |
| 8 | `PH_Mat_Interp_Core.f90` | 过程算法 | `*_Interp` 或 `*_Util` | ⚠ | `_Core`后缀歧义：实为插值工具，非族级内核 |
| 9 | `PH_Mat_KernelDefn.f90` | 数据结构 | `*_KernelDefn` | ✓ | 抽象基类/接口定义 |
| 10 | `PH_Mat_Reg.f90` | 过程算法 | `*_Reg` | ✓ | 注册表/工厂模式 |
| 11 | `PH_L4_L3MatContract.f90` | 过程算法 | `*_Brg` 或 `*_Contract` | ✓ | L3→L4映射桥接 |
| 12 | `PH_L4_Populate.f90` | 过程算法 | `*_Populate` | ✓ | 冷路径：L3数据填充到L4 TYPE |

### 不合规项汇总

| 文件 | 问题 | 修复方案 | 优先级 |
|------|------|----------|--------|
| `PH_Mat_Dispatch.f90` | 后缀应为`_Dsp` | `git mv` 重命名 | P1 |
| `PH_Mat_Interp_Core.f90` | `_Core`后缀歧义 | 改为`PH_Mat_Interp.f90`或`PH_Mat_Interp_Util.f90` | P2 |
| `PH_Mat_Core_Types.f90` | 已废弃TYPE残留 | 头部标注`!! DEPRECATED`，设置删除时间线 | P1 |

---

## 3. 族级差异矩阵

| 族 | `_Def` | `_Eval` | `_Core` | `_Brg` | `_Proc` | 模型`_Core` | 四型完备 | 3D命名 | SIO签名 |
|----|--------|---------|---------|--------|---------|-------------|----------|--------|---------|
| **Elas** | ✓ | ✓ | ✓ | ✓ | - | - | ✓ | ✓ | ✓ |
| **Plast** | ✓ | ✓ | ✓ | ✗缺 | - | 5个 | ✓ | ✓ | ✓ |
| **Geo** | ✓ | ✓ | ✗缺 | ✗缺 | ✓(DP) | 4个 | ✓ | ✓ | ✓ |
| **Damage** | ✓ | ✓ | ✗缺 | ✗缺 | - | 2个 | ✓ | ✓ | ✓ |
| **Hyper** | ✓ | ✓ | ✓ | ✗缺 | - | - | ✓ | ✓ | ✓ |
| **Creep** | ✓ | ✓ | ✓ | ✗缺 | - | - | ✓ | ✓ | ✓ |
| **Composite** | ✓ | ✓ | ✗缺 | ✗缺 | - | 2个 | ✓ | ✓ | ✓ |
| **Thermal** | ✓ | ✓ | ✗缺 | ✗缺 | - | 1个 | ✓ | ✓ | ✓ |
| **Acoustic** | ✓ | ✓ | ✗缺 | ✗缺 | - | 1个 | ✓ | ✓ | ✓ |
| **Viscoelas** | ✓ | ✓ | ✓ | ✗缺 | - | - | ✓ | ✓ | ✓ |
| **User** | ✓ | ✓ | ✗缺 | ✗缺 | - | - | ✓ | ✓ | ✓ |

### 矩阵解读

- **`_Def` + `_Eval`**: 全族100%覆盖，为最小必备文件集
- **`_Core`**: 仅5族有（Elas/Plast/Hyper/Creep/Viscoelas），其余族算法直接内联Eval或分散到模型_Core
- **`_Brg`**: 仅Elas族具备族级Brg，其余通过域级`PH_Mat_Core`的S2间接桥接
- **模型`_Core`**: Plast最多(5个)，Geo次之(4个)，体现模型复杂度
- **`_Proc`**: 仅Geo的DP模型使用，为L3→L4签名适配薄层

---

## 4. Dispatch文件夹审计

### 文件清单

| # | 文件名 | 大小 | 角色 | 状态 | 处置方案 |
|---|--------|------|------|------|----------|
| 1 | `PH_MatPLM_LegacyFacadeUMATs.f90` | 229KB | 全UMAT Legacy入口 | **FROZEN** | P0 Blocker，等L5路由切换后移除 |
| 2 | `PH_MatEval.f90` | 31.9KB | 域级Eval旧版 | **STAGING** | 随族级Eval完善逐步削减 |
| 3 | `PH_MatPLMEval.f90` | 57.4KB | 塑性大类Eval旧版 | **STAGING** | 拆分到Plast/Geo各族Eval |
| 4 | `PH_MatPLM_Kernels.f90` | 13.0KB | 塑性子核 | Legacy | 合并到各族`_Core`或模型`_Core` |
| 5 | `PH_MatPLM_PlastCall.f90` | 7.0KB | 塑性Call入口 | Legacy | 合并到`PH_Mat_Plast_Core.f90` |
| 6 | `PH_MatELA_ElasCall.f90` | 2.0KB | 弹性Call入口 | Legacy | 已被`PH_Mat_Elas_Eval`替代，待删 |

### 状态定义

| 状态 | 含义 | 操作约束 |
|------|------|----------|
| **FROZEN** | 不改动、不删除 | 仅允许添加`!! DEPRECATED`注释 |
| **STAGING** | 过渡态，允许渐进削减 | 每次削减需同步测试 |
| **Legacy** | 旧代码，待合并/移除 | 需确认无外部引用后操作 |

---

## 5. 优先级建议

### P0 — 阻塞项（必须在Phase 2前解决）

| 项目 | 说明 | 影响 |
|------|------|------|
| `LegacyFacadeUMATs.f90` FROZEN标记 | 229KB文件标记FROZEN，确保无人误修改 | 阻塞L5路由切换 |
| `PH_Mat_Core_Types.f90` DEPRECATED | 标注废弃，避免新代码引用 | 阻塞SIO统一 |

### P1 — 命名规范对齐（Phase 2 Sprint 1）

| 项目 | 说明 | 工作量 |
|------|------|--------|
| `PH_Mat_Dispatch.f90` → `PH_Mat_Dsp.f90` | git mv + 全仓USE更新 | 0.5d |
| Plast族补`_Brg` | 高频L5路由，需族级桥接 | 1d |
| Geo族补`_Core` | 当前DP_Proc直连，缺统一内核 | 1.5d |

### P2 — 完善项（Phase 2 Sprint 2-3）

| 项目 | 说明 | 工作量 |
|------|------|--------|
| `PH_Mat_Interp_Core.f90` 消歧义 | 改名为`*_Interp.f90` | 0.5d |
| Damage/Composite/Thermal/Acoustic/User 补`_Core` | 多模型族需统一内核 | 每族1d |
| `PH_Mat_Domain_Core.f90` 头部注释 | 标注`ROLE: Domain-Def`消歧义 | 0.1d |
| Dispatch文件夹 Legacy文件清理 | 逐步合并到族级文件 | 5d |

---

## 附录A: Elas族标杆结构

```
Material/Elas/
├── PH_Mat_Elas_Def.f90   (320行) -- [数据结构] 四型TYPE + Args + TBP
├── PH_Mat_Elas_Eval.f90  (146行) -- [过程算法] 3D入口(IP_Incr_Eval/Update)
├── PH_Mat_Elas_Core.f90  (10.9KB) -- [过程算法] 计算内核(Build/Compute/Update)
└── PH_Mat_Elas_Brg.f90   (2.3KB)  -- [过程算法] L5桥接适配器
```

**Elas标杆特征**:
1. Def文件：主TYPE(Desc/State/Algo/Ctx) + 辅TYPE(Cfg_Init_Desc, Pop_Vld_Desc, Inc_Evo_Ctx) + Args + TBP实现
2. Eval文件：3D命名(`PH_Mat_Elas_IP_Incr_Eval`)，6参数SIO签名`(desc, state, algo, ctx, args, status)`
3. Core文件：纯计算子程序，无TYPE定义
4. Brg文件：薄桥接层，L4→L5签名转换

---

*END OF REPORT*
