# L4 Contact 同步治理台账

> 状态：ACTIVE | 创建：2026-04-28  
> 范围：`UFC/ufc_core/L4_PH/Contact/`  
> 目标：稳定 L4 Contact 作为接触力学物理计算引擎，维护搜索/检测/法向/摩擦/罚函数/显式/热接触/磨损核心；支撑 AI 插槽与 L5 调度协同。

## 1. 域级守门人（Domain Guardian）

| 角色 | 说明 |
|------|------|
| **守门人** | Contact 域 Owner（需指定） |
| **审查范围** | `L4_PH/Contact/` 下所有 `.f90` 及子目录、`CONTRACT.md` / `DESIGN_Cont_FourTypes.md` / `DESIGN_Contact_Domain.md` |
| **审查触发** | 搜索算法变更、摩擦模型变更、四型 TYPE 变更、AI 插槽变更、热路径文件变更 |
| **合同冻结版本** | CONTRACT.md v3.0 为权威基线，变更须递增版本号 |

## 2. 文件冻结/活跃状态表

### 2.1 核心 .f90 文件

| 文件 | 模块 | 状态 | 职责 | 冻结/热路径 |
|------|------|------|------|-------------|
| `PH_Cont_Def.f90` | `PH_Cont_Def` | **AUTHORITY** | 统一四型 TYPE 定义（Desc/State/Algo/Ctx + LEGACY） | TYPE 字段变更须同步 L3 Populate + L5 Dispatch；Types/ 副本已删除 |
| `PH_Cont_Core.f90` | `PH_Cont_Core` | **active** | 核心物理计算（Gap/Force/Stiffness） | **热路径核心**；变更须性能回归 |

### 2.2 子目录文件

| 子目录 | 文件 | 模块 | 状态 | 职责 |
|--------|------|------|------|------|
| `Domain/` | `PH_Cont_Domain.f90` | `PH_Cont_Domain` | **active** | 域级常量/枚举/容器 |
| `Core/` | `PH_Cont_Mgr.f90` | `PH_Cont_Mgr` | **active** | 算法框架 + 结构化 SIO |
| `Core/` | `PH_Cont_Brg.f90` | `PH_Cont_Brg` | **active** | L4 Bridge API |
| `Core/` | `PH_Cont_CSR.f90` | `PH_Cont_CSR` | **active** | CSR 格式接触刚度装配（**热路径**） |
| `Core/` | `PH_Cont_Ctx.f90` | `PH_Cont_Ctx` | **active** | 上下文管理 |
| `Search/` | `PH_Cont_Search.f90` | `PH_Cont_Search` | **active** | 搜索入口（SpatialHash/BBox） |
| `Search/` | `PH_ContSearch_Adv.f90` | `PH_ContSearchAdv` | **active** | 高级搜索（**热路径**） |
| `Search/` | `PH_Cont_BVHBuilder.f90` | `PH_Cont_BVHBuilder` | **active** | BVH 树构建（**热路径**） |
| `Search/` | `PH_Cont_BVHQuery.f90` | `PH_Cont_BVHQuery` | **active** | BVH 树查询（**热路径**） |
| `Search/` | `PH_Cont_CCD.f90` | `PH_Cont_CCD` | **active** | 连续碰撞检测 |
| `Friction/` | `PH_Cont_Friction.f90` | `PH_Cont_Friction` | **active** | 摩擦模型库（**热路径**） |
| `Explicit/` | `PH_Cont_Expl.f90` | `PH_Cont_Expl` | **active** | 显式动力学接触 |
| `Self/` | `PH_Cont_SelfContact.f90` | `PH_Cont_SelfContact` | **active** | 自接触检测/排斥 |
| `Thermal/` | `PH_ThermalCont_Def.f90` | `PH_ThermalCont_Def` | **active** | 热接触四型定义 |
| `Thermal/` | `PH_Cont_ThermoMech.f90` | `PH_Cont_ThermoMech` | **active** | 热-力耦合接触 |
| `Wear/` | `PH_Cont_WearEvolution.f90` | `PH_Cont_WearEvolution` | **active** | 磨损演化（Archard/能量法） |
| `AI/` | `PH_AI_ContactLaw.f90` | `PH_AI_ContactLaw` | **active** | AI 接触律代理（插槽 4） |
| `Types/` | — | — | **deprecated** | 目录已清空；TYPE AUTHORITY 已合并到根目录 `PH_Cont_Def.f90` |

## 3. 搜索算法变更特殊审查要求

搜索算法是 Contact 域最关键的热路径组件，变更须满足额外要求：

| 搜索文件 | 特殊审查要求 |
|----------|-------------|
| `PH_Cont_BVHBuilder.f90` | BVH 构建性能回归；须附大规模（>10K 对）基准测试 |
| `PH_Cont_BVHQuery.f90` | BVH 查询性能回归；须附遍历/点查询/候选收集基准 |
| `PH_ContSearch_Adv.f90` | 高级搜索路由变更须同步 L5 `RT_Cont_Search` 搜索频率策略 |
| `PH_Cont_Search.f90` | 搜索入口变更须同步 CONTRACT §六 搜索方法矩阵 |
| `PH_Cont_CCD.f90` | CCD TOI 计算精度回归；须附高速冲击验证 |

**搜索通用规则**：
- BVH 重建频率由 L5 控制，L4 仅执行查询
- 搜索方法选择须与 L5 Contract 对齐
- 新增搜索方法须在 CONTRACT §六 登记

## 4. AI 插槽变更规则

| 规则 | 说明 |
|------|------|
| **插槽编号** | 4 (AI_ContactLaw)，固定不可变 |
| **默认状态** | `enabled = .FALSE.`，零开销 |
| **接口冻结** | `AI_ContactLaw_Init/Predict/Finalize` 签名已冻结；扩展须新增接口而非修改 |
| **引擎依赖** | 仅 `L1_IF/AI_Runtime` (ONNX)；禁止引入其他 ML 框架依赖 |
| **变更审查** | **强制审查** — 须守门人 + AI Owner 双审 |
| **测试要求** | 须附 AI 路径开/关对比测试；关闭时须证明零开销 |
| **合同同步** | 变更须同步 `AI_Slot_Contract.md` §2.4 |

## 5. 变更审查规则

| 变更类型 | 审查要求 | 审查人 |
|----------|----------|--------|
| 四型 TYPE 字段变更 | **强制审查** — 须同步 L3 Populate + L5 Dispatch | 守门人 + L3/L5 Owner |
| 搜索算法文件变更 | **强制审查** — 须满足 §3 特殊要求 | 守门人 + 性能 Owner |
| 摩擦模型变更 | **强制审查** — 须同步 CONTRACT §七摩擦模型清单 | 守门人 |
| `PH_Cont_Core.f90` 热路径变更 | **强制审查** — 禁止新增 ALLOCATE | 守门人 + 性能 Owner |
| `PH_Cont_CSR.f90` 装配变更 | **强制审查** — CSR 格式变更影响全局 K/F | 守门人 |
| AI 插槽变更 | **强制审查** — 须满足 §4 规则 | 守门人 + AI Owner |
| `CONTRACT.md` 变更 | **强制审查** — 须递增版本号 | 守门人 |
| 枚举值变更 | **强制审查** — 须同步 L3/L5 CONTRACT | 守门人 |

## 6. 性能回归检查规则

| 检查项 | 基线 | 阈值 | 触发条件 |
|--------|------|------|----------|
| BVH 构建 (10K 对) | 当前基线 | 退化 ≤10% | Search/ 文件变更 |
| BVH 查询 (10K 对) | 当前基线 | 退化 ≤5% | Search/ 文件变更 |
| 间隙/穿透检测 | 当前基线 | 退化 ≤5% | PH_Cont_Core 变更 |
| 摩擦力计算 | 当前基线 | 退化 ≤5% | Friction/ 变更 |
| CSR 接触刚度装配 | 当前基线 | 退化 ≤5% | PH_Cont_CSR 变更 |
| Ctx 零 ALLOCATE | 无堆分配 | 0 次 ALLOCATE | 热路径任意变更 |
| CCD 精度 | 参考解 | TOI 误差 ≤1e-8 | PH_Cont_CCD 变更 |

## 7. 接触算法/模型新增流程

### 7.1 新增搜索方法内核

- [ ] 1. 在 `Search/` 子目录下创建 `PH_Cont_{Method}.f90`
- [ ] 2. 在 `PH_Cont_Search.f90` 中注册新搜索方法入口
- [ ] 3. 在 `PH_Cont_Domain.f90` 中新增搜索方法枚举常量
- [ ] 4. 同步更新 CONTRACT.md §六 搜索方法矩阵
- [ ] 5. 通知 L5 在 `RT_Cont_Search.f90` 中更新调度
- [ ] 6. 新增性能基准测试
- [ ] 7. 更新本治理台账

### 7.2 新增摩擦模型内核

- [ ] 1. 在 `PH_Cont_Friction.f90` 中实现新模型（或新增独立文件）
- [ ] 2. 在 `PH_Cont_Domain.f90` 中新增 `PH_FRIC_*` 枚举
- [ ] 3. 在 `PH_Cont_Friction.f90` 中新增 `PH_FRICT_*` 算法级枚举
- [ ] 4. 同步更新 CONTRACT.md §七 摩擦模型清单
- [ ] 5. 新增摩擦模型闭环测试
- [ ] 6. 更新本治理台账

## 8. 清旧资产处置

| 资产 | 当前状态 | 处置策略 |
|------|----------|----------|
| `Types/` 目录 | 已清空；TYPE 已合并到 `PH_Cont_Def.f90` | 保留空目录或删除 |
| LEGACY 四型（`PH_Contact_Desc/State/Algo/Ctx`） | 简化型，存在于 `PH_Cont_Def.f90` | 新代码 USE `PH_Cont_Def` AUTHORITY 四型；legacy 逐步收窄 |
| 枚举双轨（`PH_FRIC_*` vs `PH_FRICT_*`） | 域级 vs 算法级并行 | 保持双轨；CONTRACT 已澄清语义 |

## 9. 验收门槛

- L4 Contact 新增热路径禁止在搜索循环内 `USE L3_MD` 模块。
- 热路径 Ctx 禁止 `ALLOCATE`，须栈分配。
- 搜索算法变更须通过大规模性能回归。
- 摩擦模型变更须同步 CONTRACT 枚举清单。
- AI 插槽变更须证明关闭时零开销。
- CONTRACT.md 变更须递增版本号并更新日期。

## 10. 验证记录

| 检查 | 结果 | 说明 |
|------|------|------|
| 文件清单对账 | PASS | 18 个核心 .f90 与 CONTRACT §二文件清单一致 |
| CONTRACT 一致性 | PASS | CONTRACT.md v3.0 存在且与实现一致 |
| Types/ 去重 | PASS | Types/ 副本已删除，AUTHORITY 为根目录 `PH_Cont_Def.f90` |
| 热路径 L3 依赖扫描 | PASS | 未发现 L4 搜索/计算循环内 USE L3 |
| AI 插槽默认关闭 | PASS | `enabled = .FALSE.` 已确认 |
