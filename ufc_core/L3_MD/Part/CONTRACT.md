# Part 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Part (零件管理)  
**Abbreviation**: Part (`MD_Part_*`, `MD_Sets_*`, `MD_Geom_*`)  
**Version**: v3.1  
**Updated**: 2026-04-30  
**Status**: ✅ ACTIVE (L3-Only S3 域)

---

## 1. 域职责定义

### 核心职责
部件、集合、几何类型的 Desc 真相源：零件注册与管理、零件级数据容器（Part→Section→Material 绑定）、节点/单元/表面集合操作、几何类型定义。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 零件注册/查询/克隆 | 不做单元计算（L4_PH） |
| Section→Material 绑定验证 | 不做网格拓扑操作（Mesh 域） |
| 节点/单元/表面集合管理（Set 操作） | 不做装配体实例化逻辑（Assembly 域） |
| 几何类型定义（Node/Elem Desc, Geom Ctx） | 不做本构求值 |
| Legacy 同步（`UF_PartDef` → `MD_Part_Desc` 注册表 + `MD_Part_Append_To_Domain`） | 不参与写回 |

### SIO / `*_Arg`（本域偏好）
不强制每个过程使用 `*_Arg`。Part 的 Get 查询已提供 `MD_Part_Get_Arg`/`MD_Part_GetByName_Arg` 两种 Arg 封装。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — Part、Set、Geom TYPE（核心产出）
- **State**: Y — `MD_Part_State`（sections_assigned, materials_bound, validated, n_unassigned）
- **Algo**: 无 — Part 域无算法性构建（简单注册/查询域）
- **Ctx**: 无 — Part 本体无 `MD_Part_Ctx`；`MD_Sets_Ctx` 是 Sets 子功能的操作上下文

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_PartEntry` | `MD_Part_Def` | id, name, section_id, valid | 单条零件记录 |
| `MD_Part_Desc` | `MD_Part_Def` | parts(MD_PART_MAX), n_parts | 零件注册表 |
| `MD_Node_Desc` | `MD_Geom_Def` | 节点几何描述符 | 节点坐标/属性 |
| `MD_Elem_Desc` | `MD_Geom_Def` | 单元几何描述符 | 单元类型/连接关系 |
| `UF_NodeSet` | `MD_Sets` | 节点集合 | TBP: init/add_node/add_range/contains |
| `MD_NodeSet` | `MD_Sets_Ctx` | 节点集合（扩展） | TBP: AddNode/RemoveNode/Contains/Sort/Union/Intersect/Difference |
| `MD_SurfFacet` | `MD_Sets_Ctx` | 表面面片 | 表面几何数据 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Part_State` | `MD_Part_Def` | sections_assigned, materials_bound, validated, n_unassigned | 零件级绑定/验证状态 |

### 2.3 Algo 类型（算法配置）
N/A — Part 域无算法性构建。

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Geom_Ctx` | `MD_Geom_Def` | 几何操作上下文 | 几何查询/变换上下文 |

> 注：`MD_Sets_Ctx` 是 Sets 子功能的操作上下文，非 Part 域级 Ctx。

### 域容器

| TYPE 名称 | 来源模块 | 说明 |
|-----------|----------|------|
| `MD_Part_Domain` | `MD_Part_Def` | desc + state + n_parts + initialized；TBP: Init/Finalize/GetSummary |

### SIO Arg 类型

| TYPE 名称 | 说明 |
|-----------|------|
| `MD_Part_Get_Arg` | [OUT] desc: MD_PartEntry |
| `MD_Part_GetByName_Arg` | [OUT] desc + part_idx |

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_Part_Def.f90` | `MD_Part_Def` | `_Def` | MD_Part_Domain: Init/Finalize/GetSummary + Desc/State/Arg 类型 | **AUTHORITY** |
| `MD_Part_Core.f90` | `MD_Part_Core` | `_Core` | Init/Add/Get/Assign/Validate | ACTIVE |
| `MD_Part_Mgr.f90` | `MD_Part_Mgr` | `_Mgr` | MD_Part_GetPart_Idx/GetPartByName_Idx | ACTIVE |
| `MD_Part_Sync.f90` | `MD_PartSync` | `_Sync` | MD_Part_SyncFromLegacy/GetFromDomain/GetFromDomainByName | ACTIVE |
| `MD_Part_Brg.f90` | `MD_Part_Brg` | `_Brg` | 域桥（待补） | **SKELETON** |
| `MD_Geom_Def.f90` | `MD_Geom_Def` | `_Def` | MD_Geom_Ctx_Init + Node/Elem Desc | ACTIVE |
| `MD_Sets_Ctx.f90` | `MD_Sets_Ctx` | `_Ctx` | NodeSet/ElemSet/Surface: Add/Remove/Contains/Sort/Union/Intersect/Difference + MD_SetBoundingBox_Calc/SetDistance_Calc/SetGenerateBy*/SetOverlap_Check/SetSymmetry_Detect | ACTIVE |
| `MD_Sets_Mgr.f90` | `MD_Sets_Mgr` | `_Mgr` | Sets 管理器 | ACTIVE |

### 已删除模块（精简）
- ~~`MD_Inst_Mgr.f90`~~ — 零调用 Instance Manager（58KB）
- ~~`MD_Sets_Mgr.f90`~~ (旧版) — 零调用 Sets Manager（53KB）
- ~~`MD_Part_Mgr.f90`~~ (旧版) — 零调用 Part Manager（37KB）
- ~~`MD_Sets_API.f90`~~ — 零调用 API 封装层
- ~~`MD_Part_API.f90`~~ — 零调用 API 封装层

---

## 4. 对外接口（公开 API）

### 域容器 (MD_Part_Domain TBP)
| 接口 | 功能 | 参数 |
|------|------|------|
| `Init` | 域初始化 | capacity, status |
| `Finalize` | 域释放 | — |
| `GetSummary` | 获取域摘要 | summary |

### Part 操作
| 接口 | 功能 | 来源 |
|------|------|------|
| `MD_Part_GetPart_Idx` | 按索引查询零件 | `MD_Part_Mgr` |
| `MD_Part_GetPartByName_Idx` | 按名称查询零件 | `MD_Part_Mgr` |
| `MD_Part_SyncFromLegacy` | Legacy→Domain 同步 | `MD_PartSync` |
| `MD_Part_GetFromDomain` / `GetFromDomainByName` | 单条 `MD_Part_Entry_Desc` 查询 | `MD_PartSync` |

### 几何与集合
| 接口 | 功能 |
|------|------|
| `MD_Geom_Ctx_Init` | 几何上下文初始化 |
| `MD_SetBoundingBox_Calc` | 包围盒计算 |
| `MD_SetDistance_Calc` | 集合距离计算 |
| `MD_SetGenerateByBox/Cylinder/Plane/Sphere/Surface` | 几何生成集合 |
| `MD_SetOverlap_Check` | 集合重叠检查 |
| `MD_SetSymmetry_Detect` | 对称性检测 |

---

## 5. 跨层数据流

```
INP (*PART/*INSTANCE/*NSET/*ELSET/*SURFACE)
  → L6_AP / MD_KW_Mapper (map_part/map_instance/map_nset/map_elset/map_surface)
  → MD_Part_Core::Add / MD_Sets::nodeset_init/add_node / surface_init/add_facet
  → MD_Part_Desc (L3 冷存储)
  → MD_Geom_PH_Brg → L4 ElemCtx (几何注入)
```

### L3-Only 域柱
Part 是 L3-Only 域（Layer-Only S3），仅用于零件注册和 Section 绑定。L4 通过 Populate 消费几何数据。

### L1_IF 基础设施集成

| 设施 | 集成方式 | 说明 |
|------|---------|------|
| **SymTbl** | `MD_Part_Add` 注册 `PART:{name}` | 建模期 O(1) 命名查找 |
| **错误链** | Bridge 出口 `UFC_Err_Wrap` | 见 L1_IF_INTEGRATION.md |

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Model | T(合同) | Part 属于 Model 树 |
| R2 | L3_MD/Element/Mesh | T(合同) | Part 拥有 Mesh |
| R3 | L3_MD/Section | T(合同) | Part 拥有 Section |
| R4 | L3_MD/Assembly | S(消费) | Assembly 实例化 Part |
| R5 | L4_PH (经 Populate) | B(桥接) | 几何 → L4 ElemCtx |
| R6 | L6_AP/Input | E(外部) | *PART 解析来源 |
| R7 | L1_IF/Error | U(USE) | 错误码定义 |

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_PART_xxx` (31300–31399) |
| 严重级 | WARNING: Part 无关联 Mesh; ERROR: Part 名重复; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 部件→实例→装配体→全局坐标 |
| **逻辑链** | Model→Part→Mesh/Section→Assembly→Populate |
| **计算链** | L3 无计算 |
| **数据链** | INP→MD_Part_Desc(冷)→MD_GeomPH_Brg→L4 ElemCtx |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Part Desc 为 Write-Once | 硬 | Code Review | — |
| Part 名唯一性 | 硬 | Init 校验 | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| Part 必须关联至少一个 Mesh | 软 | Validate | — |

### 常量
- `MD_PART_MAX = 256` — 最大零件数
- `MD_PART_NAME_LEN = 64` — 零件名最大长度

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.1 | 2026-04-26 | 对齐磁盘文件名；记录删除模块 |
| v3.1 | 2026-04-30 | P1 竖切：`MD_Part_Entry_Desc` 扁平 `id`（修 `cfg%id` 笔误）；`UF_PartDef`/`MAX_PART_NAME` 回归 `MD_Part_Def`+`MD_Part_Mgr`；`MD_Part_Sync` 用 `md_layer%desc%part`+`MD_Part_Append_To_Domain`；Get* 返回单条 entry；L3 补 `initialized`/`l3Frozen` 与 `validate_part_refs_` 对齐 `desc%parts` |
| v3.0 | 2026-04-28 | 标准化为 7 章节格式 |
