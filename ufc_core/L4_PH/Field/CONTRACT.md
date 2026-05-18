# Field 域级合同卡 (L4_PH)

**Layer**: L4_PH (物理计算层)  
**Domain**: Field (场变量物理计算)  
**Prefix**: `PH_Field_*`  
**Version**: v2.1  
**Created**: 2026-04-27  
**Updated**: 2026-04-30  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L4_PH 层 Field 域，承接 L3 Field 真源与 Material/Mesh 数据，提供温度、孔压、浓度等物理场的计算内核
- **职责**:
  - 温度场计算：显式/隐式求解与热传导矩阵/源/边界过程
  - 孔隙压力场计算：显式/隐式求解与渗流矩阵/源/边界过程
  - 浓度场计算：显式/隐式求解与扩散/反应/源/边界过程
  - 通用场操作：GP→Node 外推、场量插值、梯度、不变量计算
  - 形函数/高斯积分支持
  - 多物理耦合贡献项（Field 对 Element/Assembly 的贡献矩阵）

### 非职责
- 不拥有模型真源（L3 `MD_Field_Def` 是 Field 变量注册权威）
- 不复制 L3 的 Field 类型/实体/分布/Region 语义
- 不做全局组装（L5 `RT_Asm_*` 处理）
- 不管理运行时编排（L5 StepDriver/Solver 负责）

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Field_Desc` | `PH_Field_Def` | nn, nip, ndim, n_comp, n_nodes | 通用场描述符（Populate 后只读） |
| `PH_Temperature_Desc` | `PH_Field_Def` | ... | 温度场专属描述 |
| `PH_PorePressure_Desc` | `PH_Field_Def` | ... | 孔隙压力场专属描述 |
| `PH_Concentration_Desc` | `PH_Field_Def` | ... | 浓度场专属描述 |

### 2.2 State

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Field_State` | `PH_Field_Def` | ... | 跨步持久状态与当前 step/increment |

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Field_Algo` | `PH_Field_Def` | ... | 时间积分、容差、迭代参数 |
| `PH_Temperature_Algo` | `PH_Field_Def` | ... | 温度场专属算法参数 |
| `PH_PorePressure_Algo` | `PH_Field_Def` | ... | 孔隙压力场专属算法参数 |
| `PH_Concentration_Algo` | `PH_Field_Def` | ... | 浓度场专属算法参数 |

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Field_Ctx` | `PH_Field_Def` | N_shape(27), dN_dx(3,27), E_mat(27,27), ip_vals(6,27), nodal_vals(6,27), grad(3), stress_voigt(6), I1, J2, J3 | IP/节点插值、梯度、不变量与全局平均工作区 |

**权威 TYPE 模块**: `PH_Field_Def.f90` (ACTIVE, AUTHORITY)

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `PH_Field_Def.f90` | `PH_Field_Def` | `_Def` (TYPE定义) | 通用四型 + 温度/孔压/浓度专属 Desc/Algo/Arg/In/Out | **ACTIVE** (AUTHORITY) |
| `PH_Field_Ops.f90` | `PH_Field_Ops` | `_Ops` (操作集) | 通用插值、外推、节点平均、梯度、应力不变量 | **ACTIVE** |
| `PH_Field_ComputeTemp.f90` | `PH_Field_ComputeTemp` | 特化(Compute) | 温度场显式/隐式求解，热传导矩阵/源/边界 | **ACTIVE** |
| `PH_Field_ComputePore.f90` | `PH_Field_ComputePore` | 特化(Compute) | 孔隙压力显式/隐式求解，渗流矩阵/源/边界 | **ACTIVE** |
| `PH_Field_ComputeConc.f90` | `PH_Field_ComputeConc` | 特化(Compute) | 浓度显式/隐式求解，扩散/反应/源/边界 | **ACTIVE** |
| `PH_Field_GaussQuadrature.f90` | `PH_Field_GaussQuadrature` | 特化(Support) | `PH_Field_GetGaussPoints` + `PH_FIELD_GAUSS_RULE_*`（统一规则码） | **ACTIVE** |
| `PH_Field_ShapeFunc.f90` | `PH_Field_ShapeFunc` | 特化(Support) | 形函数/梯度/Jacobian | **ACTIVE** |
| `PH_Field_Cpl.f90` | `PH_Field_Cpl` | 特化(Coupling) | 多物理 Field 对 Element/Assembly 的贡献矩阵 | **ACTIVE** |
| `PH_Field_Interpolate.f90` | `PH_Field_Interpolate` | 特化(Support) | 场量插值 | **ACTIVE** |

命名决策：`PH_Field_Ops.f90` 由旧 `PH_Field_Core.f90` 收敛而来。`PH_Field_ShapeFunc.f90` 是域内支持模块，不承担跨层桥接。`PH_Field_Cpl.f90` 使用 `Cpl` (Coupling) 避免与 Constraint 域 MPC 冲突。

---

## 4. 对外接口（公开 API）

### Populate 入口
| 子程序 | 模块 | 说明 |
|--------|------|------|
| `PH_L4_Populate_Field` | `PH_L4_Populate` | L3→L4 Field 冷路径入口。签名: `(md_field_desc, ph_field_desc, ph_field_state, ph_field_algo, stepId, status)` |

### 通用操作 (PH_Field_Ops)
| 子程序 | 说明 |
|--------|------|
| 插值 | IP值→节点值 外推 |
| 节点平均 | 全局节点平均 |
| 梯度计算 | 场梯度 |
| 不变量计算 | I1, J2, J3 应力不变量 |

### 高斯积分 (`PH_Field_GaussQuadrature`)
| 符号 | 说明 |
|------|------|
| `PH_Field_GetGaussPoints(rule_type, order, out)` | 唯一过程入口；`out` 为 `PH_Field_GaussPt_Arg` |
| `PH_FIELD_GAUSS_RULE_1D` … `PH_FIELD_GAUSS_RULE_3D_TET` | 与 `rule_type` 对应的命名常量（典型：体 Hex=`PH_FIELD_GAUSS_RULE_3D_HEX`，面 Quad=`PH_FIELD_GAUSS_RULE_2D_QUAD`） |

### 温度计算 (PH_Field_ComputeTemp)
| 子程序 | 说明 |
|--------|------|
| 显式/隐式温度求解 | 输入: `PH_Temperature_Desc/Algo/Arg` → 输出: temperature, heat_flux |

### 孔压计算 (PH_Field_ComputePore)
| 子程序 | 说明 |
|--------|------|
| 显式/隐式孔压求解 | 输入: `PH_PorePressure_Desc/Algo/In/Out` → 输出: pressure, velocity |

### 浓度计算 (PH_Field_ComputeConc)
| 子程序 | 说明 |
|--------|------|
| 显式/隐式浓度求解 | 输入: `PH_Concentration_Desc/Algo/In/Out` → 输出: concentration, flux |

### SIO / `*_Arg`（本域偏好）
温度计算现有 `PH_Temperature_Arg` 统一承载输入/输出场。孔压和浓度使用 `In/Out` 对偶。与 Principle #14 一致，不强制每个过程都使用 `*_Arg`。

---

## 5. 跨层数据流

### Populate 数据流（冷路径）
```
L3_MD/Field (MD_Field_Desc, MD_FieldEntry, MD_FieldInitCond)
  → PH_L4_Populate_Field()
    → PH_Field_Desc / PH_Field_State / PH_Field_Algo  ← L4 Populate 后只读
```

### 计算数据流（热路径）
```
PH_Field_Desc + PH_Field_Ctx  ← 每元素输入
  → PH_Field_Ops (插值/外推/梯度/不变量)
  → PH_Field_ComputeTemp/Pore/Conc  ← 场专属计算
    → temperature / pressure / concentration  ← 计算输出
```

### L5 消费流
```
L4 Field results
  → L5_RT/Assembly (残量/刚度贡献)
  → L5_RT/Solver (耦合场)
  → L5_RT/Output (输出请求)
```

### 跨层硬约束
- L3 Field 定义、类型枚举、实体归属、分布和 Region/Set 合同不被 L4 修改
- L4 Field 热路径不直接遍历 L3 容器
- 初始值数组仍由 L3 Field 持有，直到出现真实 L4 Field cache 需求

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Field | S (消费) | Field Desc 真源，经 Populate 只读获取 |
| R2 | L3_MD/Material | S (消费) | 材料热传导/渗流/扩散参数 |
| R3 | L3_MD/Element/Mesh | S (消费) | 网格拓扑、坐标、单元信息 |
| R4 | L4_PH/Element | T (合同) | 共享形函数、Jacobian、积分点 |
| R5 | L5_RT/Assembly | B (桥接) | 场贡献矩阵 → 全局刚度/残量 |
| R6 | L5_RT/Solver | B (桥接) | 耦合场数据 |
| R7 | L5_RT/Output | S (被消费) | 场输出请求的数据源 |
| R8 | L1_IF/Precision | U (USE) | IF_Prec_Core (wp, i4) |

### 约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| 热路径零 L3（Compute 不直读 L3 容器） | **硬** | H-HOT-01 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | **硬** | H-ERR-01 |
| 不使用 STOP | **硬** | 错误通过 ErrorStatusType 传播 |
| PH_Field_Def 是 L4 Field TYPE 唯一权威 | **硬** | 统一四型 |
| 暂不新增 PH_Field_Proc | **硬** | 无真实编排需求时禁止薄 Proc |

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 四型定义完整 | PH_Field_Def 包含通用 + 专属四型 | ✅ 已实现 |
| A2 | 温度场计算可用 | ComputeTemp 支持显式/隐式求解 | ✅ 已实现 |
| A3 | 孔压场计算可用 | ComputePore 支持显式/隐式求解 | ✅ 已实现 |
| A4 | 浓度场计算可用 | ComputeConc 支持显式/隐式求解 | ✅ 已实现 |
| A5 | 通用操作完整 | Ops 支持插值/外推/梯度/不变量 | ✅ 已实现 |
| A6 | 形函数/高斯积分 | ShapeFunc + GaussQuadrature 支持 | ✅ 已实现 |
| A7 | 耦合贡献 | Cpl 提供 Element/Assembly 贡献矩阵 | ✅ 已实现 |
| A8 | Populate 入口 | PH_L4_Populate_Field 可填充 L4 四型 | ✅ 已实现 |
| A9 | 错误传播 | 所有公开 API 使用 ErrorStatusType | ✅ 已实现 |
| A10 | PH_Field_Brg 清理 | 纯转调门面无消费者时已删除 | ✅ 已清理 |

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v2.0 | 2026-04-27 | 初版 v2 结构 |
| v2.1 | 2026-04-30 | Pilot：`PH_Field_GaussQuadrature` 去掉 Volume/Surface/Edge 薄封装；公开 `PH_FIELD_GAUSS_RULE_*` |
