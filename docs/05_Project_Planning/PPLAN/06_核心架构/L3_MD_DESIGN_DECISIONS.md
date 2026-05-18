# L3_MD 层设计决策文档

> 状态: CORE | 创建: 2026-04-26 | 版本: v1.1
> 关联: UFC_DOMAIN_PILLAR_ARCHITECTURE.md (域柱架构), L4_PH_DESIGN_DECISIONS.md, L5_RT_DESIGN_DECISIONS.md

## 总论

L3_MD 是 UFC 有限元内核的**唯一真相源 (Single Source of Truth)**。其核心产出是 Desc（描述型数据结构），上层 L4_PH/L5_RT 通过 Bridge 只读消费 L3 数据。

```
功能层 = 数据结构(Desc/Ctx/State/Algo) + 过程(时相+动作)
L3 定位 = Desc 主导 + 生命周期管理 + 跨域引用维护
```

---

## 议题 1: 树形嵌套 vs 扁平兄弟域

### 决策: 扁平优先 + ModelTree 降级为 L6 建模辅助视图

| 组件 | 定位 | 使用者 |
|------|------|--------|
| `MD_L3_LayerContainer` | 运行时权威容器（14 域扁平聚合） | L4_PH, L5_RT, L0_Global |
| `ModelTree` (MD_ModelTree.f90) | L6 建模阶段语义组织工具 | L6_AP (INP Parser, UI) |

- `ModelTree` 不是 `md_layer` 的视图，而是并行的 ObjContainer 容器
- L4/L5 完全不依赖 `ModelTree`，运行时脊柱为 `g_ufc_global%md_layer`
- 建模阶段通过 Populate 冷路径将 ModelTree 内容写入 `md_layer`
- `MD_Mesh.f90` 中的旧 `ModelTree`/`ModelTreeNode` 类型标记为 LEGACY，不再扩展

### 清理项

- `Model/MD_Model_Brg.f90` 已重命名为 `MD_Model_DomBrg`（消除与 `Bridge_L5/MD_Model_Brg.f90` 的模块名冲突）
- `MD_Mesh.f90` 中的 ModelTree 代码标记为 REMOVED（历史遗留）

---

## 议题 2: 四型裁剪卡（按域）

L3 的裁剪原则: **Desc 必有，State 追踪生命周期，Algo/Ctx 按需**。

| 域 | Desc | State | Algo | Ctx | 裁剪理由 |
|----|------|-------|------|-----|---------|
| Model | Y | Y(构建状态) | - | - | 无算法性构建 |
| Part | Y | Y(赋值/验证) | - | - | 简单注册域 |
| Assembly | Y | Y | Y | Y | 有实例化/绑定逻辑 |
| Constraint | Y | Y | Y | Y | 有约束类型分发 |
| Mesh | Y | Y | Y | Y | 有拓扑构建逻辑 |
| Section | Y | Y(隐式) | Y | Y | 有材料绑定验证 |
| Material | Y | Y | Y | Y | 最完整域：注册/分发/本构路由 |
| Amplitude | Y(24 字段) | Y(4 字段) | Y | Y | 有评估算法 |
| LoadBC | Y | Y | Y | Y | 有查找/施加算法 |
| Interaction | Y | Y | Y | Y | 有接触对管理 |
| Step | Y(17 字段) | Y(分离自 Desc) | Y(StepAlgo) | Y | 有步进推演逻辑 |
| Solver | Y | -(占位) | -(占位) | -(占位) | 纯配置存转 |
| Output | Y | Y | Y | - | 有请求管理算法 |
| WriteBack | Y | Y | - | Y | 白名单域，无独立算法 |

"-" 表示当前无需求，不新增；"Y" 表示已有或应有。

---

## 议题 3: 合同/代码漂移修复

| 问题 | 修复状态 |
|------|---------|
| `MD_Part_Domain` TYPE 缺失 | **已修复**: 在 `MD_Part_Def.f90` 中补全 |
| `MD_Part_Get_Arg` / `GetPartByName_Arg` 缺失 | **已修复**: 同上 |
| `MD_Model_Brg` 模块名冲突 | **已修复**: 重命名为 `MD_Model_DomBrg` |
| `md_layer%keyword` 字段不存在 | **决策**: KeyWord 不加入容器（独立解析域）；需修正 `MD_KeyWordDomain.f90` 注释 |
| Interaction 双重类型栈 | **待清理**: `MD_Cont.f90` 为运行时权威，`MD_Int_Def.f90` 标记为 legacy |
| Model 双重 Desc | **待清理**: `MD_ModelDomain.f90` 为权威，`MD_Model_Def.f90` 为简化 legacy |
| `MD_Mesh.f90` 中旧 ModelTree | **标记**: REMOVED/LEGACY，不再扩展 |

---

## 议题 4: 生命周期阶段门 (Phase Gate)

### 阶段枚举

```fortran
MD_L3_PHASE_UNINIT    = 0  ! 未初始化
MD_L3_PHASE_INIT      = 1  ! Init 完成，域已分配
MD_L3_PHASE_POPULATED = 2  ! 所有域已填充（KeyWord/Legacy Populate 完成）
MD_L3_PHASE_BOUND     = 3  ! BindDomains 完成，跨域引用已建立
MD_L3_PHASE_VALIDATED = 4  ! ValidateBindings 通过，数据一致性已验证
MD_L3_PHASE_FROZEN    = 5  ! Freeze 完成，运行时只读
```

### 阶段推进

| 操作 | 前置阶段 | 推进到 |
|------|---------|--------|
| `Init(...)` | UNINIT | INIT |
| `MarkPopulated(...)` | >= INIT | POPULATED |
| `BindDomains(...)` | >= POPULATED | BOUND |
| `ValidateBindings(...)` | >= BOUND | VALIDATED |
| `Freeze(...)` | >= INIT | FROZEN |
| `Finalize()` | 任意 | UNINIT |

### 守卫规则

- FROZEN 之后，域的 `Add*`/`Set*` 方法应检查 `l3Frozen` 并拒绝
- 运行时只有 WriteBack 白名单路径可修改 L3 数据
- `phase` 字段已添加到 `MD_L3_LayerContainer`

---

## 议题 5: 跨域引用规范化

### 统一引用规范

| 引用类型 | 规范 | 命名约定 |
|---------|------|---------|
| 域间对象引用 | 整数 ID | `*_id` 后缀 (如 `material_id`, `section_id`) |
| 按名查找 | SymTbl 注册 + O(1) lookup | 键前缀 `MAT:`, `PART:`, `STEP:` 等 |
| ID 列表 | `ALLOCATABLE INTEGER(i4)` 数组 | `*_ids(:)` 后缀 |
| 热路径指针 | 仅在 Bridge 模块中使用 | L3 域内不使用指针引用 |
| 字符串名称 | 仅作为 SymTbl 键 | 运行时通过 ID 访问 |

### SymTbl 注册状态

| 域 | 注册键前缀 | 状态 |
|----|-----------|------|
| Material | `MAT:{name}` | 已实现 |
| Part | `PART:{name}` | 已实现 |
| Step | `STEP:{name}` | 已实现 |
| Amplitude | `AMP:{name}` | 已实现 |
| Assembly (NodeSet) | `NSET:{name}` | 已实现 |
| Assembly (ElemSet) | `ELSET:{name}` | 已实现 |
| Assembly (Surface) | `SURF:{name}` | 已实现 |
| Assembly (Instance) | `INST:{name}` | 已实现 |
| Section | `SECT:{name}` | 待实现 |
| Solver | `SOLVCFG:{name}` | 待实现 |
| Output | `OUTREQ:{name}` | 待实现 |
| Interaction | `CPAIR:{name}` | 待实现 |
| LoadBC (Load) | `LOAD:{name}` | 待实现 |
| LoadBC (BC) | `BC:{name}` | 待实现 |
| Constraint | `CONSTR:{name}` | 待实现 |

### BindDomains bug

`MD_L3_BindDomains` 中 `assembly_has_parts` 字段被错误覆盖为 `n_constraints`，需修复。

---

## 议题 6: Bridge 组织 -- 分散归域

### 决策: Bridge 文件分散到各域内

| 规则 | 说明 |
|------|------|
| 文件位置 | 各域内部，不集中到 `Bridge/` |
| 命名规范 | `MD_{Domain}_PH_Brg.f90` (→L4), `MD_{Domain}_RT_Brg.f90` (→L5) |
| 全局索引 | `BRIDGE_INDEX.md` 保留为注册索引 |
| 规范文档 | `Bridge/CONTRACT.md` 保留为跨层桥接规范 |

### 当前集中式 Bridge 迁移计划

| 集中式文件 | 目标域 |
|-----------|--------|
| `Bridge_L4/MD_MatLibPH_Brg.f90` | `Material/Bridge/` (已在域内) |
| `Bridge_L4/MD_ElemPH_Brg.f90` | `Elem/` |
| `Bridge_L4/MD_LBCPH_Brg.f90` | `Boundary/` |
| `Bridge_L4/MD_GeomPH_Brg.f90` | `Part/` 或 `Mesh/` |
| `Bridge_L4/MD_ContPH_Brg.f90` | `Interaction/` |
| `Bridge_L4/MD_ConstraintPH_Brg.f90` | `Constraint/` |

注: 本轮更新 `BRIDGE_INDEX.md` 索引但不物理移动文件（避免大规模编译链变动）。

---

## 议题 7: KeyWord Populate 通道

### 决策: 分散实现 + 统一完成信号

- 各域的 `*_Sync.f90` / `*_Populate.f90` 保持分散
- `KW_Mapper` 做全局关键字→域路由
- 新增 `MD_L3_LayerContainer%MarkPopulated()` 作为**阶段门信号**
- Populate 完成后设置 `phase = MD_L3_PHASE_POPULATED`

### 调用序列

```
L6_AP parse INP -> KW_Mapper -> 各域 Sync/Populate -> MarkPopulated()
-> BindDomains() -> ValidateBindings() -> Freeze()
```

---

## 议题 8: Desc 字段标准化

### 命名约定

| 字段类型 | 命名模式 | 示例 |
|---------|---------|------|
| 引用 ID | `{语义}_id` | `material_id`, `section_id` |
| 枚举类型 | `{语义}_type` | `amp_type`, `mat_type` |
| 计数 | `n_{语义}` | `n_parts`, `n_steps` |
| 字符串名称 | `{语义}_name` | `step_name` |
| 布尔标志 | `is_{语义}` 或 `{语义}_enabled` | `is_active` |
| 浮点参数 | 语义明确的名称 | `time_start`, `penalty_factor` |

### Desc 字段注册表

详见 [L3_MD_DESC_FIELD_REGISTRY.md](L3_MD_DESC_FIELD_REGISTRY.md)，包含:
- 全部权威 Desc TYPE 注册（含双重定义清理策略）
- ABAQUS 关键字覆盖度概要

### 各域 CONTRACT.md 增补

每个域的 CONTRACT.md 应包含:
1. **四型裁剪决策** 小节（明确有/无/占位） -- 已完成: Part, Section, Step, Material
2. **Desc 字段注册表**（字段名、类型、必填/可选、默认值）-- 全局注册表见上
3. **ABAQUS 关键字对应表**（已覆盖/未覆盖参数）-- 概要见上

---

## 实施文件清单

| Phase | 文件 | 变更 |
|-------|------|------|
| 0 | `L3_MD/Part/MD_Part_Def.f90` | 补全 `MD_Part_Domain`, `*_Arg` 类型 |
| 0 | `L3_MD/Model/MD_Model_Brg.f90` | 模块重命名为 `MD_Model_DomBrg` |
| 1 | `L3_MD/MD_L3Layer.f90` | 生命周期阶段枚举 + `MarkPopulated`/`GetPhase`/`IsFrozen` + 阶段推进 |
| 1 | `L3_MD/Part/CONTRACT.md` | 更新四型裁剪决策 |
| 2 | `L3_MD/MD_L3Layer.f90` | `BindDomains` bug 修复 (`assembly_has_parts` 覆写) |
| 2 | `L3_MD/Section/MD_Section_Core.f90` | Section SymTbl 注册 (`SECT:{name}`) |
| 2 | `L3_MD/Section/CONTRACT.md` | 四型裁剪决策更新 |
| 3 | `L3_MD/Bridge/BRIDGE_INDEX.md` | 域内分散 Bridge 注册表 (第5节) |
| 3 | `L3_MD/KeyWord/MD_KeyWordDomain.f90` | 修正容器路径注释 |
| 4 | `L3_MD/Model/MD_ModelTree.f90` | 架构定位文档化 (ARCHITECTURAL POSITIONING) |
| 4 | `L3_MD/Mesh/MD_Mesh.f90` | 旧 ModelTree LEGACY 标记 |
| 4 | `L3_MD/Model/MD_Model.f90` | MODULE/END MODULE 不匹配修复 + 头注释 |
| 5 | `L3_MD/Material/CONTRACT.md` | 四型裁剪决策 |
| 5 | `L3_MD/Analysis/Step/CONTRACT.md` | 四型裁剪决策 |
| - | `docs/05_Project_Planning/PPLAN/06_核心架构/L3_MD_DESIGN_DECISIONS.md` | 本文档 |
| - | `docs/05_Project_Planning/PPLAN/06_核心架构/L3_MD_DESC_FIELD_REGISTRY.md` | Desc 字段注册表 |

---

## 后续规划（本轮不实施）

- 物理移动 Bridge 文件到各域（需更新 CMakeLists / 编译脚本）
- 全部 14 域 CONTRACT.md 补充 Desc 字段注册表
- ABAQUS 关键字全覆盖度矩阵
- `MD_Mesh.f90` 中旧 ModelTree 代码清理
- Interaction 双重类型栈统一
