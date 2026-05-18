# L3_MD 模型数据层 — 完整域级拆解 v1.0

> **层级**: L3_MD (Model Data Layer)  
> **版本**: v1.0  
> **层级职责**: 模型定义、材料库、单元库、网格、约束、边界条件  
> **域级总数**: 12 个  
> **子域总数**: 17 个  
> **功能模块总数**: 100+ 个  
> **命名前缀**: `MD_` (Model Data)

---

## 📋 L3_MD 层拓扑结构

```
L3_MD (模型数据层)
│
├─ Analysis ⭐ NEW — 分析类型与正交坐标
├─ Material — 材料库（11 族 50+ 种）
├─ Element — 单元库（3D/2D/1D/特殊）
├─ Mesh — 网格管理
├─ Assembly — 总体模型装配
├─ Boundary — 边界条件（固定/对称/周期）
├─ Constraint — 约束条件（MPC/RBE）
├─ Interaction — 接触与相互作用
├─ Field — 场变量管理
├─ Output — 输出定义
├─ Model — 完整模型对象
└─ Bridge — 与 L4_PH 连接
```

---

## 🎯 一、十二个域级完整拆解

### 1.1 域级 1: **Analysis** ⭐ NEW — 分析类型与正交坐标

**职责**: 分析类型定义、正交坐标映射、约束矩阵

**子域** (5 个):
- **Group_Solvers** — 5 种求解器配置
- **Group_Physics** — 12 种物理场分组
- **Group_Coupling** — 4 种耦合策略
- **Mapping** — Group_ID 映射表
- **Validation** — 约束校验

**功能模块** (8 个):
```
MD_Analysis_Desc.f90       — 分析类型定义
MD_Analysis_Group_Desc.f90 — Group_ID 映射表 (1-based API)
MD_Analysis_Group_Factory.f90 — Group_ID 转换工厂
MD_Analysis_Solver_Config.f90 — 5 种求解器配置 (Standard/Explicit/Eigenvalue/Frequency/CFD)
MD_Analysis_Physics_Desc.f90 — 12 种物理场分组
MD_Analysis_Coupling_Desc.f90 — 4 种耦合策略 (Weak/Strong/FSI/THM/EMF)
MD_Analysis_Validator.f90  — 约束矩阵校验
MD_Analysis_Group_Ctx.f90  — Analysis 上下文
```

### 1.2 域级 2: **Material** — 材料库

**职责**: 11 族 50+ 种材料模型定义

**子域** (4 个):
- **Elastic** — 3 种弹性 (Isotropic/Orthotropic/Anisotropic)
- **Plastic** — 12 种塑性 (J2/Barlat/Hill/等)
- **HyperElastic** — 10 种超弹性 (NeoHookean/MooneyRivlin/等)
- **Advanced** — 20+ 种高级 (Viscoelastic/Creep/Damage/Thermal/等)

**功能模块** (50+ 个):
```
MD_Mat_Desc.f90           — 材料卡参数表
MD_Mat_Factory.f90        — 材料生成工厂
MD_Mat_Elastic_Iso.f90    — 各向同性弹性
MD_Mat_Elastic_Ortho.f90  — 正交弹性
MD_Mat_Elastic_Aniso.f90  — 各向异性弹性
MD_Mat_Plastic_J2Iso.f90  — J2 等向强化塑性
... (40+ 个材料模块)
MD_Mat_Ctx.f90            — 材料上下文
```

### 1.3 域级 3: **Element** — 单元库

**职责**: 3D/2D/1D 单元定义

**子域** (3 个):
- **3D** — 八面体、四面体、六面体
- **2D** — 三角形、四边形、壳单元
- **1D** — 梁、桁架、接触对

**功能模块** (36+ 个):
```
MD_Elem_Desc.f90          — 单元元数据
MD_Elem_3D_C3D8.f90       — 8 节点六面体
MD_Elem_3D_C3D4.f90       — 4 节点四面体
MD_Elem_2D_CPS3.f90       — 3 节点平面应力三角
MD_Elem_2D_CPS4.f90       — 4 节点平面应力四边
... (30+ 个单元模块)
MD_Elem_Ctx.f90           — 单元上下文
```

### 1.4 域级 4: **Mesh** — 网格管理

**职责**: 节点、单元、拓扑、重新划分

**子域** (2 个):
- **Topology** — 节点-单元关系、邻接表
- **Adaptive** — 网格自适应、细化/粗化

**功能模块** (8 个):
```
MD_Mesh_Desc.f90          — 网格元数据
MD_Mesh_Nodes.f90         — 节点坐标管理
MD_Mesh_Elements.f90      — 单元连接表
MD_Mesh_Topology.f90      — 拓扑关系
MD_Mesh_Adapt.f90         — 自适应细化
MD_Mesh_Refine.f90        — 网格细化
MD_Mesh_Partition.f90     — 网格分割 (并行)
MD_Mesh_Ctx.f90           — 网格上下文
```

### 1.5 域级 5: **Assembly** — 总体装配

**职责**: 全局自由度编号、模型装配

**功能模块** (4 个):
```
MD_Assem_Desc.f90         — 装配配置
MD_Assem_DOF.f90          — 全局 DOF 编号
MD_Assem_Model.f90        — 模型装配
MD_Assem_Ctx.f90          — 装配上下文
```

### 1.6 域级 6: **Boundary** — 边界条件

**职责**: 固定支撑、对称、周期边界

**子域** (3 个):
- **Fixed** — 固定约束
- **Symmetry** — 对称边界
- **Periodic** — 周期边界

**功能模块** (6 个):
```
MD_BC_Desc.f90            — BC 参数
MD_BC_Fixed.f90           — 固定支撑
MD_BC_Symmetry.f90        — 对称条件
MD_BC_Periodic.f90        — 周期条件
MD_BC_Apply.f90           — BC 应用
MD_BC_Ctx.f90             — BC 上下文
```

### 1.7 域级 7: **Constraint** — 约束条件

**职责**: 多点约束 (MPC)、刚体单元 (RBE)

**子域** (2 个):
- **MPC** — 多点约束方程
- **RBE** — 刚体单元

**功能模块** (4 个):
```
MD_Const_Desc.f90         — 约束定义
MD_Const_MPC.f90          — MPC 处理
MD_Const_RBE.f90          — RBE 实现
MD_Const_Ctx.f90          — 约束上下文
```

### 1.8 域级 8: **Interaction** — 接触与相互作用

**职责**: 接触对、摩擦、表面相互作用

**子域** (2 个):
- **Contact** — 接触对定义
- **Friction** — 摩擦模型

**功能模块** (4 个):
```
MD_Int_Desc.f90           — 相互作用定义
MD_Int_Contact.f90        — 接触对
MD_Int_Friction.f90       — 摩擦
MD_Int_Ctx.f90            — 相互作用上下文
```

### 1.9 域级 9: **Field** — 场变量管理

**职责**: 初始条件、场变量定义

**功能模块** (3 个):
```
MD_Field_Desc.f90         — 场变量元数据
MD_Field_Initial.f90      — 初始条件
MD_Field_Ctx.f90          — 场变量上下文
```

### 1.10 域级 10: **Output** — 输出定义

**职责**: 场输出、历史输出、ODB 定义

**子域** (2 个):
- **FieldOutput** — 场变量输出
- **HistoryOutput** — 历史输出

**功能模块** (4 个):
```
MD_Out_Desc.f90           — 输出配置
MD_Out_Field.f90          — 场输出定义
MD_Out_History.f90        — 历史输出
MD_Out_Ctx.f90            — 输出上下文
```

### 1.11 域级 11: **Model** — 完整模型

**职责**: 模型总体、模型生命周期管理

**功能模块** (3 个):
```
MD_Model_Desc.f90         — 模型结构
MD_Model_Build.f90        — 模型构建
MD_Model_Ctx.f90          — 模型上下文
```

### 1.12 域级 12: **Bridge** — 与 L4_PH 连接

**职责**: 模型数据 → 物理计算的映射

**功能模块** (2 个):
```
MD_Bridge_L4.f90          — MD→PH 数据转换
MD_Bridge_Ctx.f90         — 桥接上下文
```

---

## 📊 二、L3_MD 层模块统计

| 序号 | 域级 | 子域数 | 模块数 | 关键功能 | 优先级 |
|------|------|--------|--------|----------|--------|
| 1 | Analysis | 5 | 8 | 分析类型+正交坐标 ⭐ | ⭐⭐⭐ |
| 2 | Material | 4 | 50+ | 材料库 | ⭐⭐⭐ |
| 3 | Element | 3 | 36+ | 单元库 | ⭐⭐⭐ |
| 4 | Mesh | 2 | 8 | 网格管理 | ⭐⭐ |
| 5 | Assembly | 0 | 4 | 全局装配 | ⭐⭐ |
| 6 | Boundary | 3 | 6 | 边界条件 | ⭐⭐ |
| 7 | Constraint | 2 | 4 | 约束条件 | ⭐⭐ |
| 8 | Interaction | 2 | 4 | 接触相互作用 | ⭐⭐ |
| 9 | Field | 0 | 3 | 场变量 | ⭐⭐ |
| 10 | Output | 2 | 4 | 输出定义 | ⭐⭐ |
| 11 | Model | 0 | 3 | 模型总体 | ⭐⭐ |
| 12 | Bridge | 0 | 2 | 层间连接 | ⭐⭐ |
| **合计** | | **17** | **100+** | | |

---

## 🔗 三、命名规范与约束

**层前缀**: `MD_`

**子域前缀示例**:
- Analysis → MD_Analysis_*
- Material → MD_Mat_*
- Element → MD_Elem_*
- Mesh → MD_Mesh_*
- Assembly → MD_Assem_*
- Boundary → MD_BC_*
- Constraint → MD_Const_*
- Interaction → MD_Int_*
- Field → MD_Field_*
- Output → MD_Out_*
- Model → MD_Model_*
- Bridge → MD_Bridge_*

**特殊约束**:
1. Analysis 域级的 Group_ID 必须 1-based（面向用户 API），内部实现时 0-based
2. Material 50+ 个模块按族分组存储
3. Element 36+ 个模块需映射到 ABAQUS 单元库
4. 所有四型必须贯通

---

## ✅ 交付清单

- ✅ 12 个域级、17 个子域、100+ 个模块的完整设计
- ✅ Analysis 域级新增，正交坐标映射已规范化
- ✅ Material/Element 完整清单
- ✅ 命名规范统一

**下一步**: 阶段 2.4 — L4_PH 层完整拆解
