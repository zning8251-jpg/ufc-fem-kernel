# Field 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Field (场变量定义与管理)  
**Abbreviation**: Field (`MD_Field_*`)  
**Version**: v3.1  
**Updated**: 2026-04-30  
**Status**: ✅ ACTIVE (H2 半贯通模板域)

---

## 1. 域职责定义

### 核心职责
场变量的模型真源：定义、注册和管理场变量（温度场、孔隙压力场、浓度场、位移/速度/加速度场、电/磁势场、自定义场）的 Desc、初值、作用域和实体归属。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 场变量类型/实体/分布/Region 定义 | 不做热/渗流/扩散物理方程求解（L4_PH） |
| 节点场和积分点状态容器 | 不拥有 L5 输出结果 |
| 初值注册/查询（Define/Set_Initial/Set_InitCond） | 不在热路径回读 L3 |
| L3 侧场容器的提交/回滚 | 不重新定义 Field 真源（L5） |

### SIO / `*_Arg`（本域偏好）
Field 的 L3 域内 CRUD 过程参数少、边界清晰，不为仅承载 `status` 的过程建立 `*_Arg` 薄封装。跨层硬边界、L5 `_Proc` 或一次交互有多个一起演进字段时，才引入统一 `*_Arg`。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — 场变量注册表，记录类型、实体归属、分布、作用域和初始条件（核心产出）
- **State**: Y — L3 侧场容器与提交/回滚状态
- **Algo**: 无独立 L3 算法 TYPE — 算法归 L4 Field
- **Ctx**: Y — 当前 step/increment/time 等轻量上下文

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Field_Desc` | `MD_Field_Def` | entries(:), n_fields | 场变量注册表（最多 MD_FIELD_MAX=64） |
| `MD_FieldEntry` | `MD_Field_Def` | field_id, field_type, entity_type, distribution, name | 单条场变量记录 |
| `MD_FieldRegionRef` | `MD_Field_Def` | region_type, region_name, range_start/end, id_list(:), set_name | Region/Set 引用 |
| `MD_FieldInitCond` | `MD_Field_Def` | field_id, distribution, region, values(:), table_id, amp_name | 初始条件描述符 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Field_State` | `MD_Field_Def` | 分配/回滚状态 | L3 侧场状态 |
| `MD_NodalField` | `MD_Field_Mgr` | name, field_type, values(:,:), old_values(:,:), increment(:,:) | 节点场变量容器 |
| `MD_ElemIPData` | `MD_Field_Mgr` | 积分点状态数据 | 单元积分点场数据 |
| `MD_FieldMgr_Type` | `MD_Field_Mgr` | 场管理器 | 域级场容器 |
| `MD_NodeDisp` | `MD_Field_Mgr` | id, u_curr(3) | 节点位移（接触/桥接用） |

### 2.3 Algo 类型（算法配置）
无独立 L3 算法 TYPE。L3 只提供查询/注册过程。

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Field_Ctx` | `MD_Field_Def` | step/increment/time 等 | 轻量上下文 |

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_Field_Def.f90` | `MD_Field_Def` | `_Def` | 四型 TYPE 定义 + 枚举常量 | **AUTHORITY** |
| `MD_Field_Mgr.f90` | `MD_Field_Mgr` | `_Mgr` | Domain_Init/Finalize, Define, Set_Initial, Set_InitCond, Get_By_ID/Name/Count | ACTIVE (含原 Core CRUD) |

### 已删除模块
- ~~`MD_Field_Core.f90`~~ — 原 Desc CRUD 蓝图，已合并到 `MD_Field_Mgr.f90`
- ~~`MD_Field_Brg.f90`~~ — 空桥接骨架，无实际跨层契约

### 枚举常量

| 类别 | 常量 | 说明 |
|------|------|------|
| 场类型 | `MD_FIELD_DISPLACEMENT=1`, `VELOCITY=2`, `ACCELERATION=3`, `TEMPERATURE=11`, `PORE_PRESSURE=12`, `CONCENTRATION=13`, `ELECTRIC_POT=21`, `MAGNETIC_POT=22`, `USER=0` | 场变量分类 |
| 实体归属 | `MD_FIELD_ENTITY_NODE=1`, `ELEMENT=2`, `IP=3`, `SURFACE=4`, `SET=5` | 场定义位置 |
| 分布方式 | `MD_FIELD_DIST_UNIFORM=1`, `TABLE=2`, `ANALYTIC=3`, `BY_SET=4`, `BY_COORD=5` | 初值分布 |
| Region 引用 | `MD_FIELD_REGION_ALL=0`, `NAME=1`, `RANGE=2`, `ID_LIST=3`, `SET_NAME=4` | 作用域指定 |

---

## 4. 对外接口（公开 API）

| 接口 | 功能 | 参数 | 时相 |
|------|------|------|------|
| `MD_Field_Domain_Init` | 初始化 Desc/State/Ctx | status | Step/Model init |
| `MD_Field_Domain_Finalize` | 清空 Desc/State/Ctx | — | Finalize |
| `MD_Field_Define` | 注册场变量 | field_id, type, entity, name, status | Parse/Populate 前 |
| `MD_Field_Set_Initial` | 设置标量初值 | field_id, value, status | Parse/Init |
| `MD_Field_Set_InitCond` | 设置完整初始条件合同 | field_id, init_cond, status | Parse/Init |
| `MD_Field_Get_By_ID` | 按 ID 查询场定义 | field_id, entry, status | Query |
| `MD_Field_Get_By_Name` | 按名称查询场定义 | name, entry, status | Query |
| `MD_Field_Get_Count` | 查询 Field 数量 | count | Query |

---

## 5. 跨层数据流

```
L6_AP/Input initial conditions / KeyWord map_initial_conditions
  → MD_Field_Define + MD_Field_Set_InitCond (L3 注册)
  → PH_Field_Def / PH_Field_Ops (L4 Populate 构造计算工作区)
  → PH_Field_ShapeFunc / PH_Field_Compute* (L4 插值/外推)
  → L5_RT Assembly/Solver/Output (消费 Field 结果)
```

### L3/L4/L5 同步设计锚点

| 层 | Field 职责 | 禁止事项 |
|----|-----------|----------|
| L3_MD | 场 Desc/enums、节点场和积分点状态容器、初值注册/查询 | 不做热/渗流/扩散求解 |
| L4_PH | Populate 后的场计算 TYPE、插值/外推、温度/孔压/浓度内核 | 不回读 L3 热路径 |
| L5_RT | Assembly/Solver/Output 消费 Field 结果与请求 | 不重新定义 Field 真源 |

### 半柱分类
H2 Field：L3+L4 半贯通柱，L5 无独立 Field 目录（Field 操作分散在 Output/WriteBack/Assembly/StepDriver 域）。

### Def.f90 保留规则
`MD_Field_Def.f90` 独立存在的依据不是代码量，而是它承载可被多方引用的模型语义合同（Field 类型/实体/分布/Region/Set/初始条件枚举），被测试、Populate、Registry 与 L4 消费链共同引用。

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/KeyWord | T(合同) | *INITIAL CONDITIONS 解析写入 Field Desc |
| R2 | L3_MD/Model | S(消费) | 模型容器引用 |
| R3 | L4_PH/Field | B(桥接) | Populate 读取 MD_Field_Desc → PH_Field_Def |
| R4 | L5_RT/Output | B(桥接) | 输出消费 Field 请求 |
| R5 | L6_AP/Input | E(外部) | 命令路径初始条件写入 |
| R6 | L1_IF/Prec | U(USE) | wp/i4 精度定义 |

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 场变量物理量→枚举分类→初始条件→Populate |
| **逻辑链** | KeyWord/AP→Field Define→Set_InitCond→PH_Field Populate→Compute |
| **计算链** | L3 无计算；场计算在 L4 PH_Field_Compute* |
| **数据链** | INP→MD_Field_Desc(冷)→PH_Field_Def/Ops→L5 Assembly/Output |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| L3_MD 是 Field 定义真源 | 硬 | Code Review | — |
| L4_PH 在 Populate 后使用自身 TYPE，不在热路径回读 L3 | 硬 | Code Review | — |
| Field 类型枚举须覆盖温度/孔压/浓度/位移/速度/加速度 | 硬 | 单元测试 | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 旧 `field_mgr` 与新 `MD_Field_Desc` registry 单一真源 | 软 | Code Review | — |

### 后续按需集成任务
- `Field-Populate-01`：L4 Populate 明确读取 `MD_Field_Desc`（已具备最小 typed 入口）
- `Field-Parser-01`：KeyWord/Input 初始条件解析写入 `MD_Field_Def`
- `Field-Idx-01`：线性扫描→索引优化（当前 defer）
- `Field-Output-01`：Output 域负责稳定 Field 输出请求合同（不由 L3 Field 承载）

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.0 | 2026-04-27 | 模板域闭环验收；原 Core 归并到 Mgr，空 Brg 删除 |
| v3.0 | 2026-04-28 | 标准化为 7 章节格式 |
| v3.1 | 2026-04-30 | Pilot：`MD_Field_Mgr` 头注释标明 L3 冷数据 vs L4 `PH_Field_*` 内核边界；与 L4 Gauss API 收敛对齐 |
