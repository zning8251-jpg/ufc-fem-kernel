# Boundary (LoadBC) 域推演卡 (Derivation Card)

**层级**: L3_MD | **域**: Load/Boundary/IC | **缩写**: LBC (`MD_LBC_*`) | **版本**: v1.0 | **日期**: 2026-04-26

---

## 〇、总览 — Boundary 域 f90 功能模块全图

### 现有文件清单 (7 个 .f90)

| # | 文件 | MODULE | 行数 | 状态 |
|---|------|--------|------|------|
| 1 | `MD_BC_Def.f90` | `MD_BC_Def` | 157 | **ACTIVE** — BC 四型基类 (Desc/State/Algo/Ctx) + 特化 |
| 2 | `MD_Load_Def.f90` | `MD_Load_Def` | 286 | **ACTIVE** — Load 四型基类 + 特化 + 域级 State/Algo/Ctx |
| 3 | `MD_LBC_Domain.f90` | `MD_LBC_Domain` | 553 | **ACTIVE** — 域容器 `MD_LoadBC_Domain` + Arg + TBP |
| 4 | `MD_LBC_Idx.f90` | `MD_LBC_Idx` | 205 | **ACTIVE** — 反循环 Idx API (L4/L5 消费) |
| 5 | `MD_LBC_Mgr.f90` | `MD_LBC_Mgr` | 6008 | **ACTIVE** — 主核：LoadDef/BCDef/Sync/Table/Distribute |
| 6 | `MD_LBC_Brg.f90` | `MD_LBC_Brg` | 926 | **ACTIVE** — L6 UF API 类型 (UF_BCDef 等 + TBP), 7+ 消费者 |
| 7 | `MD_BC_Core.f90` | `MD_BC_Core` | 167 | **DEAD** — USE 不存在的类型，零生产消费者 |

### 命名评估

生产轨道命名已基本规范：
- **BC 子域**: `MD_BC_Def` (类型定义)
- **Load 子域**: `MD_Load_Def` (类型定义)
- **域级**: `MD_LBC_*` (Domain/Idx/Mgr/Brg)

唯一命名问题：
1. `MD_LBC_Mgr.f90` 文件头注释写 `Module: MD_LBC`，实际 MODULE 名为 `MD_LBC_Mgr`
2. `LoadBCAlgo`/`LoadBCCtx` 类型名缺少 `MD_` 前缀 (仅内部使用)

### 死代码诊断 — MD_BC_Core.f90

```fortran
USE MD_BC_Def, ONLY: MD_Boundary_Desc, MD_BCEntry, MD_BC_MAX
```
`MD_BC_Def` 中不存在 `MD_Boundary_Desc`、`MD_BCEntry`、`MD_BC_MAX` 这三个符号。
这是与 Assembly 域 `MD_Asm_Def`+`MD_Asm_Core` 相同的"原型轨道"模式：
平坦固定数组类型，零生产消费者，仅被骨架测试引用。

### CONTRACT 漂移

| CONTRACT 声称 | 实际 |
|---------------|------|
| `MD_LBC.f90` — 主核 | 不存在，实际为 `MD_LBC_Mgr.f90` (MODULE `MD_LBC_Mgr`) |

---

## 一、推演路径 A→E

### A: CONTRACT → 意图

| 项目 | 说明 |
|------|------|
| **域名** | Load / Boundary / IC |
| **职责** | 载荷、边界、初值的 **Desc** 定义；**不做**施加算法 (L4/L5) |
| **四型** | Desc (LoadDef/BCDef/IC), State (活跃计数/误差), Algo (容量/映射), Ctx (占位) |
| **金线** | KeyWord → MD_LBC Desc 填充 → Step 激活 → Amp 标度 → L4 PH_LoadBC → L5 组装 |
| **热路径** | 否 — 建模期冷数据 |

### B: 四型裁剪

| 四型 | BC 子域 | Load 子域 | 域级 |
|------|---------|-----------|------|
| **Desc** | `MD_BC_Base_Desc` + DISP/UPOT/UTEMP/UMASFL | `MD_Load_Base_Desc` + DFLUX/FILM/HETVAL/UWAVE/DLOAD/Dist | `MD_Load_Desc`/`MD_BC_Desc`/`MD_IC_Desc` |
| **State** | `MD_BC_Base_State` | `MD_Load_Base_State` | `MD_LoadBC_State` |
| **Algo** | `MD_BC_Base_Algo` | `MD_Load_Base_Algo` | `MD_LoadBC_Algo` / `LoadBCAlgo` |
| **Ctx** | `MD_BC_Base_Ctx` | `MD_Load_Base_Ctx` | `MD_LoadBC_Ctx` / `LoadBCCtx` |

### C: 目标文件结构 (重构后)

| # | 文件 | MODULE | 后缀 | 内容 | 变更 |
|---|------|--------|------|------|------|
| 1 | `MD_BC_Def.f90` | `MD_BC_Def` | `_Def` | BC 四型基类 + 特化 | 保持 |
| 2 | `MD_Load_Def.f90` | `MD_Load_Def` | `_Def` | Load 四型基类 + 特化 | 保持 |
| 3 | `MD_LBC_Domain.f90` | `MD_LBC_Domain` | `_Domain` | 域容器 + Arg + TBP | 类型改名 |
| 4 | `MD_LBC_Idx.f90` | `MD_LBC_Idx` | `_Idx` | 反循环 Idx API | 保持 |
| 5 | `MD_LBC_Mgr.f90` | `MD_LBC_Mgr` | `_Mgr` | 主核 | 修头注释 |
| 6 | `MD_LBC_Brg.f90` | `MD_LBC_Brg` | `_Brg` | L6 UF API | 保持 |
| — | ~~`MD_BC_Core.f90`~~ | — | — | — | **删除** |

### D: 外部消费者影响矩阵

本次重构影响极小 — 无模块重命名，仅删除死文件和修复内部类型名。

---

## 二、Core 蓝图闭合校验

> `MD_BC_Core.f90` 已删除（编译不通过），但其定义的 **7 个过程**是域应具备的核心算法蓝图。
> 以下逐条校验：每条蓝图过程必须在生产代码中有对应实现，否则标记 **GAP**。

### 蓝图来源：已删除的 `MD_BC_Core.f90` (MODULE MD_BC_Core)

| # | 蓝图过程 | 签名语义 | 生产落地 | 状态 |
|---|----------|----------|----------|------|
| C1 | `MD_Boundary_Core_Init(desc, state, status)` | 初始化 BC 描述 + 状态 | `MD_LoadBC_Domain%Init` → `MD_LoadBC_Init` (`MD_LBC_Domain.f90`) | ✅ 覆盖 |
| C2 | `MD_Boundary_Core_Finalize(desc, state, status)` | 释放 BC 描述 + 状态 | `MD_LoadBC_Domain%Finalize` → `MD_LoadBC_Finalize` (`MD_LBC_Domain.f90`) | ✅ 覆盖 |
| C3 | `MD_Boundary_Add_Dirichlet(desc, node_id, dof, value, amp_id, status)` | 添加 Dirichlet BC 条目 | `MD_LoadBC_Domain%AddBC` → `MD_LoadBC_Domain_AddBC` (`MD_LBC_Domain.f90`) + `BCDef_Init_Structured` (`MD_LBC_Mgr.f90`) | ✅ 覆盖 (更丰富: 按 BC family 分类) |
| C4 | `MD_Boundary_Add_Neumann(desc, node_id, dof, value, amp_id, status)` | 添加 Neumann BC / 载荷条目 | `MD_LoadBC_Domain%AddLoad` → `MD_LoadBC_Domain_AddLoad` (`MD_LBC_Domain.f90`) + `LoadDef_Init_Structured` (`MD_LBC_Mgr.f90`) | ✅ 覆盖 (Neumann 在生产代码中归入 Load 子域) |
| C5 | `MD_Boundary_Get_By_Index(desc, idx, bc, status)` | 按索引查询 BC 条目 | `MD_LoadBC_Domain%GetBC(idx, arg)` → `MD_LoadBC_Domain_GetBC` + `MD_LoadBC_GetBC_Idx` (`MD_LBC_Idx.f90`) | ✅ 覆盖 |
| C6 | `MD_Boundary_Get_Count(desc) → n` | 获取 BC 计数 | `MD_LoadBC_Domain%n_bcs` 直接字段访问 + `GetSummary` | ✅ 覆盖 (字段级) |
| C7 | `MD_Boundary_Clear_Step(desc, status)` | 步切换时清除活跃 BC | `MD_LoadBC_Domain_SyncFromStep` (`MD_LBC_Mgr.f90` 内 `MD_LoadBC_Domain_SyncFromStep`) + `MD_LoadBC_Table_SyncFromStep` | ✅ 覆盖 (生产中为 Sync 语义，非简单 Clear) |

### 蓝图类型映射

| 蓝图原型类型 | 用途 | 生产对应 |
|--------------|------|----------|
| `MD_Boundary_Desc` (固定数组 `MD_BCEntry(MD_BC_MAX)`) | 平坦 BC 容器 | `MD_LoadBC_Domain` (可分配 `loads(:)` + `bcs(:)` + `initial_conds(:)`) |
| `MD_BCEntry` (bc_type/node_id/dof/value/amp_id/valid) | 单条 BC 记录 | `MD_BC_Desc` / `MD_Load_Desc` (`MD_LBC_Domain.f90`) — 按 Load/BC/IC 细分 |
| `MD_LoadBC_State` (计数 + 误差标志) | 运行时状态 | `MD_LoadBC_State` (`MD_Load_Def.f90`) — 保留且生产使用 |

**结论**: 7 条蓝图过程在生产代码中 **全部覆盖**，无功能缺失。蓝图已安全归档于此推演卡。

---

## 三、修复实施计划（已完成）

| 序号 | 修复项 | 类型 | 优先级 |
|------|--------|------|--------|
| F1 | 删除 `MD_BC_Core.f90` (死代码) | 删除 | P0 |
| F2 | `MD_LBC_Mgr.f90` 头注释 `MD_LBC` → `MD_LBC_Mgr` | 修头 | P0 |
| F3 | `LoadBCAlgo` → `MD_LBC_Algo`, `LoadBCCtx` → `MD_LBC_Ctx` | 类型改名 | P1 |
| F4 | CONTRACT.md 修正 (`MD_LBC.f90` → `MD_LBC_Mgr.f90`) | 文档 | P1 |
| F5 | 测试文件 `MD_BC_Test.f90` 改写 | 测试 | P2 |

---

## 四、版本历史

- v1.0 (2026-04-26) — 初始版本
