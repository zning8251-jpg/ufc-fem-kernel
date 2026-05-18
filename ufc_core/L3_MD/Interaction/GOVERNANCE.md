# L3 Contact (Interaction) 全量域治理台账

> 状态：ACTIVE | 创建：2026-04-28  
> 范围：`UFC/ufc_core/L3_MD/Interaction/`  
> 目标：收敛 L3 Interaction 为接触定义唯一真源（接触对/属性/摩擦模型参数/接触面/节点集）；禁止在 L3 层执行搜索或穿透计算。

## 1. 域级守门人（Domain Guardian）

| 角色 | 说明 |
|------|------|
| **守门人** | Contact 域 Owner（需指定） |
| **审查范围** | `L3_MD/Interaction/` 下所有 `.f90` 及 `CONTRACT.md` / `DOMAIN_PILLAR_CARD.md` |
| **审查触发** | 任何新增/修改 `.f90`、CONTRACT 变更、接触属性 TYPE 变更 |
| **合同冻结版本** | CONTRACT.md 当前版本为权威基线，变更须递增版本号 |

## 2. 文件冻结/活跃状态表

| 文件 | 模块 | 状态 | 职责 | 冻结规则 |
|------|------|------|------|----------|
| `MD_Int_Def.f90` | `MD_Int_Def` | **active** | 四型 TYPE：MD_IntDesc + 接触类型/属性常量 | 不新增搜索/穿透计算；TYPE 变更须同步 L4 Populate |
| `MD_Int_Core.f90` | `MD_Int_Core` | **active** | 接触域容器核心 | 不新增热路径入口 |
| `MD_Int_Ctx.f90` | `MD_Int_Ctx` | **active** | 接触上下文（接触面/节点集/配对） | 130KB 大文件；变更须谨慎审查 |
| `MD_Int_Mgr.f90` | `MD_Int_Mgr` | **active** | 管理器：生命周期管理 | 43KB；不新增计算逻辑 |
| `MD_Cont_Mgr.f90` | `MD_Cont_Mgr` | **active** | 接触管理器（legacy 扩展） | 不新增搜索/检测算法 |
| `MD_Int_API.f90` | `MD_Int_API` | **active/瘦身** | 公开接口 API | **239KB 过大**；评估拆分为功能子模块 |
| `Bridge_L5/MD_Int_Brg.f90` | `MD_Int_Brg` | **active** | L3→L5 接触桥（路径：`L3_MD/Bridge/Bridge_L5/`） | 不扩展桥接面；勿在 `L3_MD/Interaction/` 再建同名模块 |
| `MD_Int_Sync.f90` | `MD_Int_Sync` | **active** | L3 内同步 | — |
| `MD_Int_Parser.f90` | `MD_Int_Parser` | **active** | 接触输入解析 | — |
| `MD_Int_Mapper.f90` | `MD_Int_Mapper` | **active** | 接触映射 | — |
| `MD_Int_Connector.f90` | `MD_Int_Connector` | **active** | 连接器 | — |
| `MD_Hash_Table.f90` | `MD_Hash_Table` | **active** | 哈希表工具 | 通用工具；评估迁移到 Shared |

## 3. 变更审查规则

| 变更类型 | 审查要求 | 审查人 |
|----------|----------|--------|
| `MD_Int_Def.f90` TYPE 字段变更 | **强制审查** — 须同步 L4 Populate 与 DOMAIN_PILLAR_CARD | 守门人 + L4 Contact Owner |
| `MD_Int_API.f90` 接口变更 | **强制审查** — 239KB 大文件，影响面广 | 守门人 |
| `MD_Int_Ctx.f90` 上下文变更 | **强制审查** — 130KB 大文件，接触配对核心 | 守门人 |
| `MD_Int_Mgr.f90` 管理器变更 | 常规审查 | 守门人 |
| `Bridge_L5/MD_Int_Brg.f90` 桥接变更 | **强制审查** — 须确认 L4 Populate 端已同步 | 守门人 + L4 Contact Owner |
| `CONTRACT.md` 变更 | **强制审查** — 须递增版本号 | 守门人 |

## 4. 接触算法新增流程（New Contact Algorithm Checklist）

### 4.1 新增搜索方法

- [ ] 1. 确认搜索方法定位（L4 `PH_Cont_Search` 或 `Search/` 子目录）
- [ ] 2. 在 `MD_Int_Def.f90` 中定义搜索方法枚举常量（若需 L3 层配置）
- [ ] 3. 在 `MD_Int_Parser.f90` 中支持新搜索方法的输入解析
- [ ] 4. 同步更新 `CONTRACT.md` 搜索方法矩阵
- [ ] 5. 通知 L4 Contact Owner 在 L4 侧实现搜索内核
- [ ] 6. 通知 L5 Contact Owner 在 L5 侧更新搜索调度
- [ ] 7. 新增闭环测试覆盖新搜索方法
- [ ] 8. 更新本治理台账与 DOMAIN_PILLAR_CARD

### 4.2 新增摩擦模型

- [ ] 1. 在 `MD_Int_Def.f90` 中定义摩擦模型枚举常量
- [ ] 2. 在 `MD_Int_Parser.f90` 中支持新摩擦模型的输入解析
- [ ] 3. 在 `MD_Int_API.f90` 中提供摩擦参数查询接口（若需）
- [ ] 4. 同步更新 `CONTRACT.md` 摩擦模型清单
- [ ] 5. 通知 L4 Contact Owner 在 `PH_Cont_Friction.f90` 中实现摩擦内核
- [ ] 6. 新增闭环测试
- [ ] 7. 更新本治理台账

## 5. 清旧资产处置规则

| 资产 | 当前状态 | 处置策略 |
|------|----------|----------|
| `MD_Int_API.f90` (239KB) | **过大** | 评估拆分为 Query/Modify/Lifecycle 等功能子模块 |
| `MD_Int_Ctx.f90` (130KB) | 大文件 | 监控增长；评估抽出配对管理为独立模块 |
| `MD_Cont_Mgr.f90` (30KB) | legacy 扩展 | 评估与 `MD_Int_Mgr.f90` 职责合并/收敛 |
| `MD_Hash_Table.f90` | 通用工具 | 评估迁移到 `L2_LG/Shared/` 或 `L3_MD/Shared/` |
| L3 层搜索/计算残留（若有） | 禁止 | L3 不得包含搜索/穿透/力计算；发现即清除 |

## 6. 验收门槛

- L3 Interaction 新增代码不得包含接触搜索、穿透检测、法向力/摩擦力计算过程。
- 新增接触算法须完成对应 checklist（§4.1 或 §4.2）全部步骤。
- `MD_Int_Def.f90` TYPE 字段变更须证明 L4 Populate 端已同步。
- CONTRACT.md 变更须递增版本号并更新日期。
- `MD_Int_API.f90` 新增接口须评估瘦身可行性。

## 7. 验证记录

| 检查 | 结果 | 说明 |
|------|------|------|
| 文件清单对账 | PASS | 12 个 .f90 与 DOMAIN_PILLAR_CARD §4.1 一致 |
| CONTRACT 一致性 | PASS | CONTRACT.md 存在且与公开接口一致 |
| L3 计算禁令 | PASS | 未发现 L3 层搜索/穿透/力计算过程 |
| 大文件警告 | WARNING | `MD_Int_API.f90` (239KB)、`MD_Int_Ctx.f90` (130KB) 需瘦身 |
