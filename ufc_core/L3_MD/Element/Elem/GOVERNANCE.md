# L3 Element 全量域治理台账

> 状态：ACTIVE | 创建：2026-04-28  
> 范围：`UFC/ufc_core/L3_MD/Element/Elem/`  
> 目标：收敛 L3 Element 为单元拓扑/连接/截面/族注册唯一真源；禁止在 L3 层计算刚度/应力/质量。

## 1. 域级守门人（Domain Guardian）

| 角色 | 说明 |
|------|------|
| **守门人** | Element 域 Owner（需指定） |
| **审查范围** | `L3_MD/Element/Elem/` 下所有 `.f90` 及 `CONTRACT.md` / `DOMAIN_PILLAR_CARD.md` |
| **审查触发** | 任何新增/修改 `.f90`、新增单元族子目录、CONTRACT 变更 |
| **合同冻结版本** | CONTRACT.md 当前版本为权威基线，变更须递增版本号 |

## 2. 文件冻结/活跃状态表

### 2.1 核心 .f90 文件

四型真源 **`MD_Elem_Def.f90`**（`MODULE MD_Elem_Def`）与本表同目录 **`L3_MD/Element/Elem/`**。

| 文件 | 模块 | 状态 | 职责 | 冻结规则 |
|------|------|------|------|----------|
| `MD_Elem_Def.f90` | `MD_Elem_Def` | **active** | 四型 + 族 Desc/Algo 等 TYPE 真源 | 不新增计算过程；TYPE 字段变更须同步 L4 Populate |
| `MD_Elem_Domain.f90` | `MD_Elem_Domain` | **active** | 单元域容器 TYPE | 不新增热路径入口 |
| `MD_Elem_Reg.f90` | `MD_Elem_Reg` | **active** | 单元族注册表 | 新增族须走族新增流程（§4） |
| `MD_Elem_Validate.f90` | `MD_Elem_Validate` | **active** | 单元参数校验 | 新增校验规则须对齐 L4 CONTRACT |
| `MD_Elem_PHBinding.f90` | `MD_Elem_PHBinding` | **active** | L3→L4 单元绑定映射 | 新增绑定须同步 L4 Populate |
| `MD_Elem_Populate.f90` | `MD_Elem_Populate` | **active** | L3 Desc → L4 Populate 入口 | 不新增 L3 层计算逻辑 |

### 2.2 族子目录

| 子目录 | 状态 | 说明 |
|--------|------|------|
| `Solid2D/` | **active** | CPE/CPS/CAX 族 L3 定义 |
| `Solid2Dt/` | **active** | 热耦合 2D 族 |
| `Solid3D/` | **active** | C3D 族 L3 定义 |
| `Solid3Dt/` | **active** | 热耦合 3D 族 |
| `Shell/` | **active** | 壳单元族 |
| `Beam/` | **active** | 梁单元族 |
| `Truss/` | **active** | 桁架族 |
| `Spring/` | **active** | 弹簧族 |
| `Dashpot/` | **active** | 阻尼器族 |
| `Mass/` | **active** | 质量族 |
| `Pipe/` | **active** | 管单元族 |
| `Acoustic/` | **active** | 声学族（空目录，待补） |
| `Cohesive/` | **active** | 黏聚族 |
| `Gasket/` | **active** | 垫片族 |
| `Membrane/` | **active** | 膜单元族（空目录，待补） |
| `Porous/` | **active** | 多孔介质族（空目录，待补） |
| `Infinite/` | **active** | 无限元族 |
| `Thermal/` | **active** | 热传导族（空目录，待补） |
| `Surface/` | **active** | 表面族 |
| `Special/` | **active** | 特殊单元族（空目录，待补） |
| `User/` | **active** | 用户单元族（空目录，待补） |

## 3. 变更审查规则

| 变更类型 | 审查要求 | 审查人 |
|----------|----------|--------|
| `MD_Elem_Def.f90` TYPE 字段变更 | **强制审查** — 须同步 L4 Populate 与 DOMAIN_PILLAR_CARD | 守门人 + L4 Element Owner |
| `MD_Elem_Reg.f90` 注册表扩展 | **强制审查** — 新族须走族新增 checklist（§4） | 守门人 |
| `MD_Elem_PHBinding.f90` 绑定变更 | **强制审查** — 须确认 L4 Populate 端已同步 | 守门人 + L4 Element Owner |
| `MD_Elem_Validate.f90` 校验规则 | 常规审查 | 守门人 |
| `MD_Elem_Populate.f90` Populate 逻辑 | **强制审查** — 禁止新增计算逻辑 | 守门人 |
| 族子目录新增 `.f90` | **强制审查** — 须走族新增流程 | 守门人 |
| `CONTRACT.md` 变更 | **强制审查** — 须递增版本号 | 守门人 |

## 4. 族新增流程（New Element Family Checklist）

新增单元族须按以下步骤执行：

- [ ] 1. 在 `MD_Elem_Def.f90` 中定义新族的 `ELEM_*` 类型常量
- [ ] 2. 在对应族子目录下创建 `MD_Elem_{FamilyName}.f90`
- [ ] 3. 在 `MD_Elem_Reg.f90` 中注册新族（`ELEM_*` → 节点数/维度/自由度映射）
- [ ] 4. 在 `MD_Elem_PHBinding.f90` 中新增 L3→L4 绑定条目
- [ ] 5. 在 `MD_Elem_Validate.f90` 中补充参数校验规则
- [ ] 6. 同步更新 `CONTRACT.md`（文件清单、族覆盖矩阵）
- [ ] 7. 同步更新 `DOMAIN_PILLAR_CARD.md`（§4 功能模块清单）
- [ ] 8. 通知 L4 Element Owner 在 L4 侧创建族计算内核与 Populate 落点
- [ ] 9. 在 `tests/` 中新增或扩展闭环测试覆盖新族
- [ ] 10. 更新本治理台账（§2 文件状态表）

## 5. 清旧资产处置规则

| 资产 | 当前状态 | 处置策略 |
|------|----------|----------|
| 空族子目录（Acoustic/Membrane/Porous/Thermal/Special/User） | 已创建但无 `.f90` | 保留目录结构，待各族 L3 定义落地时补充 |
| `MD_Elem_Reg.f90` legacy 注册路径 | 注册表已有 225 行 | 不批量重命名，逐步对齐 `element_registry_route_crosswalk.csv` |
| L3 层计算残留（若有） | 禁止 | L3 不得包含刚度/应力/质量计算；发现即清除 |

## 6. 验收门槛

- L3 Element 新增代码不得包含刚度、应力、质量矩阵计算过程。
- 新增族须完成族新增 checklist 全部步骤方可合入。
- `MD_Elem_Def.f90` TYPE 字段变更须证明 L4 Populate 端已同步。
- CONTRACT.md 变更须递增版本号并更新日期。
- 每个族须在 `DOMAIN_PILLAR_CARD.md` 的 §4 功能模块清单中登记。

## 7. 验证记录

| 检查 | 结果 | 说明 |
|------|------|------|
| 文件清单对账 | PASS | 6 个核心 .f90 + 20 个族子目录与 DOMAIN_PILLAR_CARD 一致 |
| CONTRACT 一致性 | PASS | CONTRACT.md 存在且与公开接口一致 |
| L3 计算禁令 | PASS | 未发现 L3 层刚度/应力/质量计算过程 |
