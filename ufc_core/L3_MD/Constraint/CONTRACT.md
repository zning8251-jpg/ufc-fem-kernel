# Constraint 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Constraint (约束关系管理)  
**Abbreviation**: Constr (`MD_Constr_*`)  
**Version**: v3.2  
**Updated**: 2026-05-05  
**Status**: ✅ ACTIVE

---

## 1. 域职责定义

### 核心职责
约束类型与连接关系的 Desc 真相源：MPC 多点约束、Tie 约束、Coupling 耦合约束（kinematic/distributing）、Rigid Body 刚体约束（RBE2/RBE3）。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 定义约束类型描述符（Tie/MPC/Coupling/Rigid） | 不做约束方程数值装配（L4/L5） |
| 存储约束参数（节点、DOF、系数、表面引用） | 不做接触搜索与投影 |
| 提供白名单写入接口（Add*）和只读查询（Get*） | 不做约束力/Lagrange 乘子计算 |
| 约束一致性验证（ValidateAll） | 不做 *BOUNDARY/*INITIAL CONDITIONS（属 LoadBC 域） |
| Legacy 同步（UF_* → MD_ConstraintUnion） | 不修改网格拓扑 |

### SIO / `*_Arg`（本域偏好）
与 Principle #14 一致：不强制每个过程使用 `*_Arg`。避免仅承载 `status` 的薄封装。层间边界与 L5 `_Proc` 仍以全仓库 SIO 硬约束为准。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — 约束描述符，最丰富（4 富类型 + Union 容器）
- **State**: Y — `MD_Constraint_State` 监控占位（活跃数/误差）
- **Algo**: Y — `MD_Constr_Algo` 默认施加方式/罚刚度（建模期写入、求解期只读）
- **Ctx**: Y — `MD_Constr_Ctx` 操作期瞬态

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `TieConstraintDef` | `MD_Constr_Def` | tie_id, name, slave_surface, master_surface, adjust, position_tolerance | Tie 约束描述符 |
| `MPCConstraintDef` | `MD_Constr_Def` | mpc_id, mpc_type, n_terms, node_ids(:), dof_ids(:), coefficients(:), equation_rhs | MPC 多点约束描述符 |
| `CplConstraintDef` | `MD_Constr_Def` | cpl_id, cpl_type, ref_node, n_coupled, coupled_nodes(:), constrain_dof | Coupling 约束描述符 |
| `RigidBodyDef` | `MD_Constr_Def` | rigid_id, rbe_kind, ref_node, n_tied, tied_nodes(:), tied_weights(:) | 刚体约束描述符（RBE2/RBE3） |
| `EmbeddedRegionDef` | `MD_Constr_Def` | embed_id, host_set, embedded_set, use_rounding, embedded_elem_ids(:), host_elem_ids(:), host_coeffs(:,:) | 嵌入区域约束（P0 新增 2026-05-05） |
| `MD_ConstraintUnion` | `MD_Constr_Def` | tie(:), mpc(:), cpl(:), rigid(:), embedded(:) | 5 类约束的联合容器 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Constraint_State` | `MD_Constr_Def` | 活跃数、误差等监控占位 | 当前域外无强依赖 |

### 2.3 Algo 类型（算法配置）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Constr_Algo` | `MD_Constr_Mgr` | 默认施加方式、罚刚度 | 建模期写入、求解期只读 |
| `MD_Constraint_Algo` | `MD_Constr_Def` | 全局默认占位 | 扩展占位类型 |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Constr_Ctx` | `MD_Constr_Mgr` | 操作期瞬态 | 域容器操作上下文 |
| `MD_Constraint_Ctx` | `MD_Constr_Def` | 扩展占位 | 预留扩展 |

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_Constr_Def.f90` | `MD_Constr_Def` | `_Def` | 4 富类型 Init/Valid/Cleanup/AddTerm/SetDOFs (12 过程) | **AUTHORITY** |
| `MD_Constr_Mgr.f90` | `MD_Constr_Mgr` | `_Mgr` | `MD_Constraint_Domain` 容器：Init/Finalize/AddTie/AddMPC/AddCpl/AddRigid/GetTie/GetMPC/GetCpl/GetRigid/ValidateAll/SyncFromUnion/GetSummary | ACTIVE |
| `MD_Constr_Brg.f90` | `MD_Constr_Brg` | `_Brg` | MD_TieConstraint_TryResolveSurfaces, MD_CplConstraint_TryResolveSurfaceOrElset, MD_RigidBody_TryResolveFromAssembly | ACTIVE |
| `MD_Constr_Prop.f90` | `MD_Constr_Prop` | `_Prop` | UF_ContactPropertyDB: init/add_property/find_by_name/find_by_id/get_property/clear | ACTIVE |
| `MD_Constr_Sync.f90` | `MD_Constr_Sync` | `_Sync` | MD_Constraint_SyncFromLegacy | ACTIVE |

### 已删除模块（精简）
- ~~`MD_Constraint_API.f90`~~ — 零调用 API 封装层
- ~~`MD_Const_Idx_API.f90`~~ — 零调用 Idx API
- ~~`MD_Constr_Core.f90`~~ — 死代码（7 过程操作扁平类型）
- ~~`MD_Constr_PairDef.f90`~~ — 死代码（接触对 Desc）

---

## 4. 对外接口（公开 API）

### Init / Finalize
| 接口 | 功能 | 参数 |
|------|------|------|
| `MD_Constraint_Domain%Init` | 域容器初始化 | capacity, status |
| `MD_Constraint_Domain%Finalize` | 域容器释放 | — |

### Mutate（建模期）
| 接口 | 功能 | 参数 |
|------|------|------|
| `AddTie` / `AddTieRaw` | 添加 Tie 约束 | TieConstraintDef, status |
| `AddMPC` / `AddMPCRaw` | 添加 MPC 约束 | MPCConstraintDef, status |
| `AddCpl` / `AddCplRaw` | 添加 Coupling 约束 | CplConstraintDef, status |
| `AddRigid` / `AddRigidRaw` | 添加 Rigid Body | RigidBodyDef, status |

### Query（只读）
| 接口 | 功能 | 参数 |
|------|------|------|
| `GetTie` / `GetMPC` / `GetCpl` / `GetRigid` | 按类型查询约束 | index, result, status |
| `GetSummary` | 获取域摘要 | summary_str |
| `ValidateAll` | 约束一致性验证 | status |

### Bridge（表面解析）
| 接口 | 功能 |
|------|------|
| `MD_TieConstraint_TryResolveSurfaces` | Tie 表面→节点列表解析 |
| `MD_CplConstraint_TryResolveSurfaceOrElset` | Coupling 表面/elset 解析 |
| `MD_RigidBody_TryResolveFromAssembly` | Rigid Body 从装配体解析 |

---

## 5. 跨层数据流

```
INP (*EQUATION/*TIE/*COUPLING/*RIGID BODY)
  → L6_AP / MD_KW_Mapper (map_equation / map_*_constraint)
  → MD_Constr_Mgr::Add* → MD_ConstraintUnion (L3 冷存储)
  → PH_L4_Populate_Constraint (L4 约束注册)
  → PH_Constraint_Ctx (L4 约束施加类型)
  → RT_Asm_ApplyL3Constraints (L5 罚装配)
```

### L3/L4/L5 同步设计锚点

| 层 | 角色 | 交付物 | 禁止 |
|----|------|--------|------|
| L3_MD | 约束 Desc 真源 | `MD_Constr_Def` / `MD_Constr_Mgr` / `MD_Constr_Brg` | 组装约束方程、求解接触 Jacobian |
| L4_PH | 约束数值施加 | `PH_L4_Populate_Constraint`→`PH_Constraint_Core` | 在积分点热路径反复扫描 L3 |
| L5_RT | 约束罚装配 | `RT_Asm_ApplyL3Constraints` 消费 L4 约束 | 复制持久约束 Desc 真源 |

### 半柱分类
H1 Constraint：L3+L4 半贯通柱，L5 无独立 Constraint 目录（约束贡献在 L5 Assembly 域的 `RT_Asm_ApplyL3Constraints` 中消费）。

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Element/Mesh | S(消费) | 节点/表面/集合名解析 |
| R2 | L3_MD/Assembly | S(消费) | 装配体引用(表面定位) |
| R3 | L3_MD/Interaction | T(合同) | 接触约束共享 constraint_union |
| R4 | L4_PH/Constraint | B(桥接) | Desc → L4 约束数值装配 |
| R5 | L5_RT/Assembly | B(桥接) | RT_Asm_ApplyL3Constraints 消费 |
| R6 | L6_AP/Input | E(外部) | *EQUATION/*TIE/*COUPLING 解析 |
| R7 | L1_IF/Error | U(USE) | 错误码定义 |

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_CONSTRAINT_xxx` (31100–31199) |
| 严重级 | WARNING: 约束参考节点未找到; ERROR: MPC 方程系数全零; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | MPC/Tie/Coupling 理论→约束方程系数→L4/L5 罚装配 |
| **逻辑链** | KeyWord→Constraint Desc→Validate→PH_Populate→L5 Apply |
| **计算链** | L3 无计算；罚矩阵/Lagrange 乘子在 L4/L5 |
| **数据链** | INP→MD_ConstraintUnion(冷)→L4 Populate→L5 RT_Asm_ApplyL3Constraints |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Constraint Desc 为 Write-Once | 硬 | Code Review | — |
| 禁止在本域做约束方程数值装配 | 硬 | Code Review | — |
| MPC 方程 node/dof 引用须在 Mesh 中存在 | 硬 | Validate 校验 | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 新增约束类型须更新 P7 子表 | 软 | Code Review | — |

### 常量清单
- 约束类别：`CONSTRAINT_TIE=1`/`CONSTRAINT_MPC=2`/`CONSTRAINT_COUPLING=3`/`CONSTRAINT_RIGID=4`/`CONSTRAINT_EMBEDDED=5`
- MPC 子类型：`MPC_TYPE_GENERAL/BEAM/LINK/PIN`
- Coupling 类型：`COUPLING_TYPE_KINEMATIC/DISTRIBUTING`
- Rigid Body 种类：`RBE_TYPE_RBE2/RBE3`
- DOF 位掩码：`DOF_UX/UY/UZ/RX/RY/RZ/DOF_ALL`

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.5 | 2026-04-26 | 去除宿主上下文重复命名；字段精简 |
| v3.0 | 2026-04-28 | 标准化为 7 章节格式 |
| v3.1 | 2026-04-30 | Pilot：删除 `MD_Constraint_Assemble_Matrix`/`Apply`/`Release` 占位（零调用）；装配/施加以 L4_PH/L5_RT 为准 |
