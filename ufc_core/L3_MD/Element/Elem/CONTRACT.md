# Element域合同卡 (L3_MD/Element)

**Layer**: L3_MD (模型数据层)  
**Domain**: Element (单元定义)  
**Version**: v2.0
**Created**: 2026-04-17
**Updated**: 2026-04-30 (P2 W2 嵌套辅 TYPE 重构 + DEPRECATED 清理)
**Status**: ✅ ACTIVE

**实现与命名（2026-04）**：`Elem/` 下单元族注册、Populate/Validate、L3↔PH 绑定等 **MODULE** 已按 [CONVENTIONS.md](../../../../docs/03_Domain_Pillars/DomainProcedureRegistry/CONVENTIONS.md) §1.2 使用 **`_Ops`** 后缀（例：`MD_ElemDomain` 内含四型 **`TYPE :: MD_ElemDomain_Algo`**，勿与旧 MODULE 名混淆）。**设计意图 + `manifest.json`**：`UFC/docs/03_Domain_Pillars/DomainProcedureRegistry/design/L3_MD/Mesh/`。

---

### 报告侧：过程算法叙事（stub / archive）

- **入口（根 stub）**：[`Element_Procedure_Algorithm.md`](../../../../REPORTS/Element_Procedure_Algorithm.md)；长文：[`archive/Element_Procedure_Algorithm.md`](../../../../REPORTS/archive/Element_Procedure_Algorithm.md)。
- **Registry**：[Domain Procedure Registry](../../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)（与叙事无机器对账；优先级见该 README）。

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、职责边界

### 核心职责
- **定位**: UFC L3_MD层Element域，单元参数的注册与管理，作为L4_PH层物理计算的冷路径数据源
- **职责**: 单元类型定义、单元拓扑、节点连接、自由度分配、单元验证、Populate到L4_PH
- **边界**: 仅提供单元参数定义与管理；单元物理计算(刚度矩阵/应力恢复)由L4_PH Element域处理
- **依赖**: L3_MD/Model(模型树), L3_MD/Element/Mesh(网格), L3_MD/Section(截面属性)

### 与L4_PH Element域的关系
| L3_MD Element域 | L4_PH Element域 | 关系 |
|-----------------|-----------------|------|
| MD_Elem_Types.f90 | PH_Elem_Types.f90 | 类型定义→物理扩展 |
| MD_Element_Core.f90 | PH_Elem_*_Core.f90 | 单元管理→物理计算 |
| MD_Elem_*_Desc | PH_Elem_*_State | 描述符(只读)→状态(读写) |
| MD_Element_Populate.f90 | PH_Elem_*_Populate | Populate源→Populate目标 |

---

## 二、文件清单 (15个核心文件 + 14个子目录)

### 核心文件 (6个)

*注: 实际文件名与 v1.0 合同有差异，以下为 2026-04-26 校正后的映射:*

| 实际文件 | 行数 | 合同 v1.0 名 | 职责 |
|----------|------|-------------|------|
| MD_Elem_Reg.f90 | ~626 | MD_Element_Core.f90 | 注册表 + 族注册 (AUTHORITY: FAMILY_*/ELEM_*) |
| MD_Elem_Domain.f90 | ~167 | MD_Element_Domain.f90 | 域管理(Init/Finalize/Register/GetDesc) |
| MD_Elem_Def.f90 | ~361 | MD_Elem_Types.f90 | 四型定义(Base_Desc/State/Algo/Ctx + 族特化)；**路径** `L3_MD/Element/Elem/MD_Elem_Def.f90` |
| MD_Elem_Populate.f90 | ~216 | MD_Element_Populate.f90 | Populate接口(L3→L4数据传递) |
| MD_Elem_Validate.f90 | ~195 | MD_Element_Validate.f90 | 验证(连接/材料/截面) |
| MD_Elem_PHBinding.f90 | ~233 | MD_Elem_PH_Elem_Binding.f90 | L3↔L4单元绑定映射 |

### 单元族子目录 (14个)
| 子目录 | 单元类型 | 文件数 | 说明 |
|--------|----------|--------|------|
| Beam/ | B31/B32/B33/B31OS/B31H | 1+ | 梁单元族 |
| Shell/ | S4/S4R/S8R/S3 | 1+ | 壳单元族 |
| Solid3D/ | C3D8/C3D20/C3D4/C3D10 | 1+ | 3D实体单元 |
| Solid2D/ | CPE4/CPE8/CPS4/CPS8 | 1+ | 2D实体单元 |
| Truss/ | T2D2/T3D2 | 1+ | 桁架单元 |
| Spring/ | SPRINGA/SPRING1 | 1+ | 弹簧单元 |
| Mass/ | MASS | 1+ | 质量单元 |
| Dashpot/ | DASHPOTA | 1+ | 阻尼器单元 |
| Cohesive/ | COH2D4/COH3D8 | 1+ | 内聚单元 |
| Gasket/ | GK3D8/GK2D4 | 1+ | 垫片单元 |
| Infinite/ | CIN3D8/CIN2D4 | 1+ | 无限元 |
| Surface/ | SFM3D3/SFM3D4 | 1+ | 表面单元 |
| SurfaceEmissive/ | SF3D8 | 1+ | 表面辐射单元 |

---

## 三、四类TYPE映射

### 根TYPE定义 (MD_Elem_Types.f90)

| Type种类 | TYPE名称 | 核心职责 | 字段示例 |
|----------|----------|----------|----------|
| **Desc** | MD_Elem_Desc | 单元描述符(只读配置) | elem_type, n_nodes, n_dofs, topology |
| **Desc** | MD_ElemTopology_Desc | 单元拓扑描述 | node_conn, face_def, edge_def |
| **Desc** | MD_ElemDOF_Desc | 单元自由度分配 | dof_per_node, total_dofs, dof_map |
| **State** | MD_Elem_State | 单元运行时状态 | elem_id, mat_id, section_id |
| **Algo** | MD_Elem_Algo | 单元算法参数 | integration_rule, hourglass_ctrl |
| **Ctx** | MD_Elem_Ctx | 单元执行上下文 | step_idx, incr_idx, gp_idx |

### 单元族TYPE示例 (Beam单元)
```fortran
TYPE :: MD_Elem_B31_Desc
  INTEGER(i4) :: elem_id              ! 单元ID
  INTEGER(i4) :: node_ids(2)          ! 节点连接(2节点)
  INTEGER(i4) :: dof_per_node         ! 每节点自由度数(6或7)
  INTEGER(i4) :: section_id           ! 截面属性ID
  INTEGER(i4) :: material_id          ! 材料ID
  REAL(wp) :: orientation(3)          ! 截面方向向量
  LOGICAL :: include_shear            ! 是否包含剪切变形
  LOGICAL :: include_warping          ! 是否包含翘曲自由度
END TYPE MD_Elem_B31_Desc
```

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | ABAQUS单元关键字→MD_Elem_*_Desc→PH_Elem_*_Core计算 |
| **逻辑链** | INPUT解析→MD_Element_Registry→L4_PH单元分发→Populate |
| **计算链** | 无(L3仅管理参数,不执行计算) |
| **数据链** | MD_Elem_*_Desc(MD)→Populate→PH_Elem_*_State(PH) |

---

## 五、L3_MD ↔ L4_PH 单元绑定映射

### 绑定常量定义 (MD_Elem_PH_Elem_Binding.f90)
```fortran
! Beam单元绑定
INTEGER(i4), PARAMETER :: MD_ELEM_B31_BIND = 1001_i4
INTEGER(i4), PARAMETER :: MD_ELEM_B32_BIND = 1002_i4

! Shell单元绑定
INTEGER(i4), PARAMETER :: MD_ELEM_S4_BIND = 2001_i4
INTEGER(i4), PARAMETER :: MD_ELEM_S4R_BIND = 2002_i4

! Solid3D单元绑定
INTEGER(i4), PARAMETER :: MD_ELEM_C3D8_BIND = 3001_i4
INTEGER(i4), PARAMETER :: MD_ELEM_C3D20_BIND = 3002_i4
```

### Populate流程
```
1. L3_MD创建MD_Elem_Desc(解析INP关键字)
2. 验证单元参数(MD_Element_Validate)
3. 注册到全局单元列表(MD_Element_Core)
4. L5_RT调用MD_Element_Populate
5. Populate复制MD_Elem_Desc→PH_Elem_State
6. L4_PH使用PH_Elem_State执行物理计算
```

---

## 六、核心接口清单

### 单元管理 (MD_Element_Core.f90)
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Elem_Domain_Init | 初始化单元域 | status |
| MD_Elem_Domain_Finalize | 释放单元域 | status |
| MD_Elem_Register | 注册单元 | elem_desc, elem_id, status |
| MD_Elem_Query | 查询单元 | elem_id, elem_desc, status |
| MD_Elem_GetCount | 获取单元总数 | count |

### 单元验证 (MD_Element_Validate.f90)
| 接口 | 功能 | 检查项 |
|------|------|--------|
| MD_Elem_ValidateTopology | 验证拓扑 | 节点连接/节点ID有效性 |
| MD_Elem_ValidateDOF | 验证自由度 | 自由度数量/分配 |
| MD_Elem_ValidateMaterial | 验证材料 | 材料ID存在性 |
| MD_Elem_ValidateSection | 验证截面 | 截面ID存在性 |

### Populate接口 (MD_Element_Populate.f90)
| 接口 | 功能 | 说明 |
|------|------|------|
| MD_Elem_Populate_All | Populate所有单元 | 批量Populate到L4 |
| MD_Elem_Populate_One | Populate单个单元 | 按需Populate |

---

## 七、依赖关系

### 向上依赖(被谁使用)
- L5_RT/Element: 单元运行时调度
- L4_PH/Element: 单元物理计算(通过Populate)
- L3_MD/Model: 模型树管理

### 向下依赖(依赖谁)
- L3_MD/Element/Mesh: 节点坐标/网格拓扑
- L3_MD/Section: 截面属性
- L3_MD/Material: 材料参数
- L1_IF/Symbol: 单元类型常量

---

## 八、命名规范验证

### 模块前缀
✅ `MD_Elem_` - 符合L3_MD层命名规范

### 过程命名
✅ `MD_Elem_Register` - 域+操作
✅ `MD_Elem_ValidateTopology` - 域+验证类型
✅ `MD_Elem_Populate_All` - 域+操作+范围

---

## 九、单元族分类统计

### 按维度分类
| 维度 | 单元族 | 单元数 | 总自由度数 |
|------|--------|--------|------------|
| 1D | Beam/Truss/Spring/Dashpot | ~20 | 6-7 DOF/节点 |
| 2D | Shell/Solid2D/Cohesive2D | ~30 | 3-6 DOF/节点 |
| 3D | Solid3D/Beam3D/Cohesive3D | ~40 | 3-6 DOF/节点 |

### 按物理场分类
| 物理场 | 单元族 | 说明 |
|--------|--------|------|
| 结构 | Beam/Shell/Solid/Truss | 位移自由度 |
| 热 | 热单元 | 温度自由度 |
| 声 | Acoustic单元 | 压力自由度 |
| 耦合 | 热-力耦合单元 | 位移+温度 |

---

## 十、测试策略

### 单元级测试
- 单元注册: 验证单元ID唯一性
- 单元查询: 验证返回正确性
- 单元验证: 拓扑/自由度/材料/截面

### 集成级测试
- Populate测试: L3→L4数据传递正确性
- 绑定测试: MD_Elem_*↔PH_Elem_*映射

### 性能测试
- 大规模模型: 100万元素注册/查询性能
- Populate性能: 批量Populate耗时

---

## 十一、技术债

### 待解决
- ⚠️ 单元族子目录结构不统一(部分子目录为空)
- ⚠️ MD_Elem_PH_Elem_Binding.f90绑定常量需完善
- ⚠️ Populate接口需与L4_PH对齐

---

## 十二、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-04-17 | 初始版本,创建Element域合同卡 |
| v1.1 | 2026-04-26 | Element Domain Pillar 对齐 |
| v2.0 | 2026-04-30 | P2 W2 重构: MD_Elem_Base_Desc/Algo 引入嵌套辅TYPE(Depth 2 cap), 删除DEPRECATED平场字段, 字段访问路径全面迁移至嵌套路径 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `Beam/MD_ElemBeam.f90` | `MD_ElemBeam` | — | `MD_Elem_Beam_Register` (SUB,PUB,—); `MD_Elem_Beam_RegisterType` (SUB,PRV,—); `MD_Elem_Beam_GetDesc` (FN,PUB,Query) |
| `Cohesive/MD_ElemCohesive.f90` | `MD_ElemCohesive` | — | `MD_Elem_Cohesive_Register` (SUB,PUB,—); `MD_Elem_Cohesive_RegisterType` (SUB,PRV,—); `MD_Elem_Cohesive_GetDesc` (FN,PUB,Query) |
| `Dashpot/MD_ElemDashpot.f90` | `MD_ElemDashpot` | — | `MD_Elem_Dashpot_Register` (SUB,PUB,—); `MD_Elem_Dashpot_RegisterType` (SUB,PRV,—); `MD_Elem_Dashpot_GetDesc` (FN,PUB,Query) |
| `Gasket/MD_ElemGasket.f90` | `MD_ElemGasket` | — | `MD_Elem_Gasket_Register` (SUB,PUB,—); `MD_Elem_Gasket_RegisterType` (SUB,PRV,—); `MD_Elem_Gasket_GetDesc` (FN,PUB,Query) |
| `Infinite/MD_ElemInfinite.f90` | `MD_ElemInfinite` | — | `MD_Elem_Infinite_Register` (SUB,PUB,—); `MD_Elem_Infinite_RegisterType` (SUB,PRV,—); `MD_Elem_Infinite_GetDesc` (FN,PUB,Query) |
| `MD_Elem_Domain.f90` | `MD_ElemDomain` | `MD_ElemDomain_Algo` | `MD_Element_Domain_Init` (SUB,PUB,Init); `MD_Element_Domain_Register` (SUB,PUB,—); `MD_Element_Domain_GetDesc` (FN,PUB,Query); `MD_Element_Domain_Finalize` (SUB,PUB,Finalize) |
| `MD_Elem_PHBinding.f90` | `MD_Elem_PHBinding` | — | `MD_Elem_Brg_GetBindingId` (FN,PUB,Query); `MD_Elem_Brg_GetPHModule` (FN,PUB,Query); `MD_Elem_Brg_Validate` (FN,PUB,Validate); `MD_Elem_Brg_GetTable` (SUB,PUB,Query) |
| `MD_Elem_Family.f90` | `MD_Elem_Family` | — | `ElemTypeToFamily` (FN,PUB,—) |
| `MD_Elem_InpMap.f90` | `MD_Elem_InpMap` | — | `MD_Elem_MapAbqTypeString` (SUB,PUB,Populate) |
| `MD_Elem_Mgr.f90` | `MD_Elem_Mgr` | `ElemType`, `ElemFormul`, … | *(单元类型/配方目录 — 冷路径；详见源码)* |
| `MD_Elem_UEL_Def.f90` | `MD_Elem_UEL_Def` | `MD_Elem_UEL_Desc` | `Init` / `Reset` (TBP); `UEL_Elem_Desc_Init` / `UEL_Elem_Desc_Reset` — **≠** `MD_Elem_Base_Desc` |
| `MD_Elem_Populate.f90` | `MD_ElemPopulate` | `MD_Elem_Populate_Arg` | `MD_Element_Populate_Domain` (SUB,PUB,Populate); `MD_Element_ParseConnectivity` (SUB,PUB,Parse); `MD_Element_ValidateInput` (FN,PUB,Validate) |
| `MD_Elem_Validate.f90` | `MD_ElemValidate` | `MD_Elem_Validate_Result` | `MD_Element_Validate_Domain` (FN,PUB,Validate); `MD_Element_CheckConnectivity` (FN,PUB,Validate); `MD_Element_CheckMaterialRef` (FN,PUB,Validate); `MD_Element_CheckSectionRef` (FN,PUB,Validate) |
| `MD_Elem_Def.f90` | `MD_Elem_Def` | `MD_Elem_Base_Desc`, `MD_Elem_Base_Algo`, `MD_Elem_Base_Ctx`, `MD_Elem_Base_State`, `MD_Elem_Solid3D_Desc`, `MD_Elem_Shell_Desc`, `MD_Elem_Beam_Desc`, `MD_Elem_Truss_Desc`, `MD_Elem_Solid2D_Desc`, `MD_Elem_Infinite_Desc`, `MD_Elem_Cohesive_Desc`, `MD_Elem_Spring_Desc`, `MD_Elem_Dashpot_Desc`, `MD_Elem_Mass_Desc`, `MD_Elem_Gasket_Desc`, `MD_Elem_Surface_Desc`, `MD_Elem_Solid3D_Algo`, `MD_Elem_Shell_Algo`, `MD_Elem_Beam_Algo`, `MD_Elem_Truss_Algo`, `MD_Elem_Cohesive_Algo`, `MD_Elem_Mass_Algo` | — |
| `MD_Elem_Reg.f90` | `MD_Elem_Reg` | — | `MD_Element_InitRegistry` (SUB,PUB,Init); `MD_Element_RegisterType` (SUB,PUB,—); `MD_Element_GetDescById` (FN,PUB,Query); `MD_Element_GetDescByFamily` (FN,PUB,Query); `MD_Element_ValidateType` (FN,PUB,Validate); `MD_Element_FinalizeRegistry` (SUB,PUB,Finalize); `MD_Element_RegisterAllFamilies` (SUB,PUB,—); `MD_Element_RegisterSolid3D` (SUB,PUB,—); `MD_Element_RegisterShell` (SUB,PUB,—); `MD_Element_RegisterBeam` (SUB,PUB,—); `MD_Element_RegisterTruss` (SUB,PUB,—); `MD_Element_RegisterSolid2D` (SUB,PUB,—); `MD_Element_RegisterInfinite` (SUB,PUB,—); `MD_Element_RegisterCohesive` (SUB,PUB,—); `MD_Element_RegisterSpring` (SUB,PUB,—); `MD_Element_RegisterDashpot` (SUB,PUB,—); `MD_Element_RegisterMass` (SUB,PUB,—); `MD_Element_RegisterGasket` (SUB,PUB,—); `MD_Element_RegisterSurface` (SUB,PUB,—); `MD_Element_RegisterFamily` (SUB,PUB,—); `MD_Element_GetFamilyDesc` (FN,PUB,Query) |
| `Mass/MD_ElemMass.f90` | `MD_ElemMass` | — | `MD_Elem_Mass_Register` (SUB,PUB,—); `MD_Elem_Mass_RegisterType` (SUB,PRV,—); `MD_Elem_Mass_GetDesc` (FN,PUB,Query) |
| `Shell/MD_ElemShell.f90` | `MD_ElemShell` | — | `MD_Elem_Shell_Register` (SUB,PUB,—); `MD_Elem_Shell_RegisterType` (SUB,PRV,—); `MD_Elem_Shell_GetDesc` (FN,PUB,Query) |
| `Solid2D/MD_ElemSld2D.f90` | `MD_ElemSld2D` | — | `MD_Elem_Solid2D_Register` (SUB,PUB,—); `MD_Elem_Solid2D_RegisterType` (SUB,PRV,—); `MD_Elem_Solid2D_GetDesc` (FN,PUB,Query) |
| `Solid3D/MD_ElemSld3D.f90` | `MD_ElemSld3D` | — | `MD_Elem_Solid3D_Register` (SUB,PUB,—); `MD_Elem_Solid3D_RegisterType` (SUB,PRV,—); `MD_Elem_Solid3D_GetDesc` (FN,PUB,Query) |
| `Spring/MD_ElemSpring.f90` | `MD_ElemSpring` | — | `MD_Elem_Spring_Register` (SUB,PUB,—); `MD_Elem_Spring_RegisterType` (SUB,PRV,—); `MD_Elem_Spring_GetDesc` (FN,PUB,Query) |
| `Surface/MD_ElemSurface.f90` | `MD_ElemSurface` | — | `MD_Elem_Surface_Register` (SUB,PUB,—); `MD_Elem_Surface_RegisterType` (SUB,PRV,—); `MD_Elem_Surface_GetDesc` (FN,PUB,Query) |
| `Truss/MD_ElemTruss.f90` | `MD_ElemTruss` | — | `MD_Elem_Truss_Register` (SUB,PUB,—); `MD_Elem_Truss_RegisterType` (SUB,PRV,—); `MD_Elem_Truss_GetDesc` (FN,PUB,Query) |
