# UFC L3_MD 理论手册

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: L3_MD 模型数据层理论参考  
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档提供 L3_MD（Model Domain Layer）的理论参考，包括：

- ABAQUS 模型树理论
- 几何建模理论（节点、单元、表面）
- 材料定义理论（弹性、塑性、超弹性）
- 截面定义理论
- 载荷与边界条件理论
- 约束与接触定义理论
- 关键字解析理论

---

## 目录

1. [L3_MD 层概述](#1-l3_md-层概述)
2. [ABAQUS 模型树理论](#2-abaqus-模型树理论)
3. [几何建模理论](#3-几何建模理论)
4. [材料定义理论](#4-材料定义理论)
5. [截面定义理论](#5-截面定义理论)
6. [载荷与边界条件理论](#6-载荷与边界条件理论)
7. [约束与接触定义理论](#7-约束与接触定义理论)
8. [关键字解析理论](#8-关键字解析理论)
9. [参考文献](#9-参考文献)

---

## 1. L3_MD 层概述

### 1.1 层级定位

**L3_MD = 模型数据层（Model Domain Layer）**

**核心职责**:

- 几何建模（节点、单元、表面、刚体）
- 材料定义和材料库
- 截面定义
- 载荷和边界条件定义
- 约束定义
- 接触定义
- 关键字解析和模型树管理

**关键约束**:

- **纯数据，无计算**: L3_MD 只定义数据，不执行计算
- **只读 Desc**: L3_MD 的 Desc 字段在 inp 解析后冻结，只读访问
- **禁止算法**: 禁止本构 UMAT 实现、接触算法、约束施加、求解器、I/O

**依赖约束**:

- ✅ 允许 USE: L2_NM, L1_IF
- ❌ 禁止 USE: L4-L6（通过 Bridge 域桥接）

### 1.2 数据温度

**Desc 类型**: 极冷数据（进程级，inp 解析后冻结）

**State 类型**: 冷数据（Job 级，Step 间可更新）

---

## 2. ABAQUS 模型树理论

### 2.1 模型树结构

**ABAQUS 模型树**:

```
mdb (Model Database)
├── models['Model-1']
│   ├── parts['Part-1']
│   │   ├── nodes
│   │   ├── elements
│   │   ├── surfaces
│   │   └── sets
│   ├── rootAssembly
│   │   ├── instances['Instance-1']
│   │   ├── sets
│   │   └── surfaces
│   ├── materials['Steel']
│   ├── sections['Section-1']
│   ├── steps['Step-1']
│   │   ├── loadBCs
│   │   ├── constraints
│   │   └── interactions
│   └── ...
```

### 2.2 路径解析

**ABAQUS 路径格式**:

```
mdb.models['Model-1'].parts['Part-1'].mesh.nodes
```

**路径组件**:

- `mdb`: 根节点
- `models['Model-1']`: 模型节点
- `parts['Part-1']`: 部件节点
- `mesh.nodes`: 数据节点

**路径解析算法**:

1. 分割路径（按 `.` 分割）
2. 解析节点名（`models`, `parts` 等）
3. 解析索引（`['Model-1']`）
4. 递归访问嵌套结构

---

## 3. 几何建模理论

### 3.1 节点（Node）

**节点定义**:

```
Node = (ID, X, Y, Z)
```

**节点集（Node Set）**:

```
NodeSet = {Node₁, Node₂, ..., Nodeₙ}
```

**节点命名**:

- 全局唯一 ID
- 可选的名称（Set）

### 3.2 单元（Element）

**单元定义**:

```
Element = (ID, Connectivity, Type)
```

其中:

- `ID`: 单元编号
- `Connectivity`: 节点连接关系 `[n₁, n₂, ..., nₘ]`
- `Type`: 单元类型（C3D8, C3D20, S4 等）

**常用单元类型**:


| 类型    | 名称      | 节点数 | 维度  |
| ----- | ------- | --- | --- |
| C3D8  | 8节点六面体  | 8   | 3D  |
| C3D20 | 20节点六面体 | 20  | 3D  |
| C3D4  | 4节点四面体  | 4   | 3D  |
| S4    | 4节点壳单元  | 4   | 2D  |
| B31   | 2节点梁单元  | 2   | 1D  |


**单元集（Element Set）**:

```
ElementSet = {Element₁, Element₂, ..., Elementₙ}
```

### 3.3 表面（Surface）

**表面定义**:

```
Surface = (Name, Type, Definition)
```

**表面类型**:

- **Element Face**: 单元面集合
- **Node Set**: 节点集合（用于接触）
- **Analytical**: 解析表面（圆柱、球等）

**表面命名**:

- 全局唯一名称
- 用于载荷、边界条件、接触定义

### 3.4 部件（Part）

**部件定义**:

```
Part = (Name, Nodes, Elements, Surfaces, Sets)
```

**部件特征**:

- 独立的几何实体
- 可被多个实例引用
- 支持参数化建模

### 3.5 装配（Assembly）

**装配定义**:

```
Assembly = (Instances, Sets, Surfaces)
```

**实例（Instance）**:

```
Instance = (Name, Part, Transform)
```

其中 `Transform` 包含:

- 平移向量 `(tx, ty, tz)`
- 旋转矩阵 `R`

---

## 4. 材料定义理论

### 4.1 弹性材料

**线弹性材料参数**:

```
Material = {
  E: 杨氏模量 (Young's Modulus)
  ν: 泊松比 (Poisson's Ratio)
  ρ: 密度 (Density)
}
```

**各向同性弹性本构**:

```
σ = D ε
```

其中 `D` 是弹性矩阵（见 L4_PH 理论手册）。

### 4.2 塑性材料（J2 塑性）

**Von Mises 塑性参数**:

```
Material = {
  E: 杨氏模量
  ν: 泊松比
  σᵧ: 初始屈服应力
  H: 硬化模量
  n: 硬化指数 (可选)
}
```

**屈服准则**:

```
f(σ, σᵧ) = √(3J₂) - σᵧ = 0
```

### 4.3 超弹性材料

**Neo-Hookean 参数**:

```
Material = {
  C₁₀: 材料常数
  D₁: 体积模量参数
}
```

**应变能函数**:

```
W = C₁₀(I₁ - 3) + (1/D₁)(J - 1)²
```

### 4.4 材料库（Material Library）

**材料库结构**:

```
MaterialLibrary = {
  'Steel': Material₁,
  'Aluminum': Material₂,
  ...
}
```

**材料分配**:

```
MaterialAssignment = {
  ElementSet → Material
}
```

---

## 5. 截面定义理论

### 5.1 实体截面（Solid Section）

**定义**:

```
SolidSection = {
  Name: 'Section-1',
  Material: 'Steel',
  Thickness: 1.0  (可选，用于壳单元)
}
```

### 5.2 壳截面（Shell Section）

**定义**:

```
ShellSection = {
  Name: 'Shell-1',
  Material: 'Steel',
  Thickness: 0.01,
  IntegrationPoints: 5  (沿厚度方向的积分点数)
}
```

### 5.3 梁截面（Beam Section）

**定义**:

```
BeamSection = {
  Name: 'Beam-1',
  Material: 'Steel',
  Profile: 'Rectangular',  (或 'Circular', 'I-Section' 等)
  Dimensions: [width, height]  (或 [radius] 等)
}
```

---

## 6. 载荷与边界条件理论

### 6.1 边界条件（Boundary Condition）

**位移边界条件**:

```
BC = {
  Type: 'Displacement',
  Region: NodeSet,
  DOF: [1, 2, 3],  (x, y, z 方向)
  Value: [0.0, 0.0, 0.0]  (固定)
}
```

**速度边界条件**:

```
BC = {
  Type: 'Velocity',
  Region: NodeSet,
  DOF: [1],
  Value: 1.0  (m/s)
}
```

### 6.2 载荷（Load）

**集中力**:

```
Load = {
  Type: 'Concentrated Force',
  Region: NodeSet,
  DOF: [2],  (y 方向)
  Magnitude: 1000.0  (N)
}
```

**分布载荷**:

```
Load = {
  Type: 'Pressure',
  Region: Surface,
  Magnitude: 1.0e6  (Pa)
}
```

**体积力**:

```
Load = {
  Type: 'Body Force',
  Region: ElementSet,
  Direction: [0, -9.81, 0],  (重力，m/s²)
  Magnitude: ρ  (密度，kg/m³)
}
```

### 6.3 幅值（Amplitude）

**幅值定义**:

```
Amplitude = {
  Name: 'Amp-1',
  Type: 'Tabular',
  Time: [0.0, 1.0, 2.0],
  Value: [0.0, 1.0, 0.0]
}
```

**幅值类型**:

- **Tabular**: 表格数据
- **Smooth Step**: 平滑阶跃
- **Periodic**: 周期函数
- **Decay**: 衰减函数

---

## 7. 约束与接触定义理论

### 7.1 多点约束（MPC）

**MPC 定义**:

```
MPC = {
  Type: 'Equation',
  DOF: [1, 2, 3],  (自由度)
  Coefficients: [c₁, c₂, ..., cₙ],
  RHS: d
}
```

**约束方程**:

```
Σᵢ cᵢ uᵢ = d
```

**MPC 类型**:

- **Equation**: 一般方程约束
- **Rigid Body**: 刚体约束
- **Coupling**: 耦合约束

### 7.2 接触对（Contact Pair）

**接触对定义**:

```
ContactPair = {
  MasterSurface: 'Master-Surf',
  SlaveSurface: 'Slave-Surf',
  InteractionProperty: 'Friction-1',
  Type: 'Surface-to-Surface'
}
```

**接触类型**:

- **Surface-to-Surface**: 面-面接触
- **Node-to-Surface**: 点-面接触
- **Self-Contact**: 自接触

### 7.3 摩擦定义

**摩擦参数**:

```
Friction = {
  Type: 'Coulomb',
  μ: 0.3  (摩擦系数)
}
```

**Coulomb 摩擦**:

```
fₜ = μ fₙ
```

其中:

- `fₜ`: 切向摩擦力
- `fₙ`: 法向接触力
- `μ`: 摩擦系数

---

## 8. 关键字解析理论

### 8.1 ABAQUS 关键字格式

**关键字结构**:

```
*KEYWORD, PARAM1=value1, PARAM2=value2
data_line_1
data_line_2
...
```

**示例**:

```
*MATERIAL, NAME=Steel
*ELASTIC
200.0e9, 0.3
*DENSITY
7850.0
```

### 8.2 关键字分类

**模型定义关键字**:

- `*PART`: 部件定义
- `*ASSEMBLY`: 装配定义
- `*NODE`: 节点定义
- `*ELEMENT`: 单元定义

**材料关键字**:

- `*MATERIAL`: 材料定义
- `*ELASTIC`: 弹性参数
- `*PLASTIC`: 塑性参数

**载荷关键字**:

- `*BOUNDARY`: 边界条件
- `*CLOAD`: 集中力
- `*DLOAD`: 分布载荷

**Step 关键字**:

- `*STEP`: Step 定义
- `*STATIC`: 静力分析
- `*DYNAMIC`: 动力分析

### 8.3 关键字解析算法

**解析流程**:

1. **词法分析**: 识别关键字、参数、数据行
2. **语法分析**: 构建抽象语法树（AST）
3. **语义分析**: 验证参数合法性、构建模型树
4. **模型构建**: 创建 L3_MD 数据结构

---

## 9. 参考文献

### 9.1 ABAQUS 文档

1. **Dassault Systèmes** (2023). *ABAQUS Analysis User's Guide*. Providence, RI: Dassault Systèmes Simulia Corp.
2. **Dassault Systèmes** (2023). *ABAQUS Keywords Reference Guide*. Providence, RI: Dassault Systèmes Simulia Corp.

### 9.2 有限元建模

1. **Bathe, K. J.** (2014). *Finite Element Procedures*. Watertown, MA: Klaus-Jürgen Bathe.
2. **Zienkiewicz, O. C., & Taylor, R. L.** (2005). *The Finite Element Method*. Oxford: Butterworth-Heinemann.

### 9.3 材料本构

1. **Simo, J. C., & Hughes, T. J. R.** (1998). *Computational Inelasticity*. New York: Springer.
2. **Bonet, J., & Wood, R. D.** (2008). *Nonlinear Continuum Mechanics for Finite Element Analysis*. Cambridge: Cambridge University Press.

---

## 附录

### A.1 符号表


| 符号         | 含义                    |
| ---------- | --------------------- |
| `mdb`      | 模型数据库（Model Database） |
| `Part`     | 部件                    |
| `Assembly` | 装配                    |
| `Instance` | 实例                    |
| `Node`     | 节点                    |
| `Element`  | 单元                    |
| `Surface`  | 表面                    |
| `Set`      | 集合                    |
| `Material` | 材料                    |
| `Section`  | 截面                    |
| `BC`       | 边界条件                  |
| `Load`     | 载荷                    |
| `MPC`      | 多点约束                  |
| `Contact`  | 接触                    |


### A.2 相关文档

- `UFC_L3_MD_架构设计规范.md` - L3_MD 架构规范
- `UFC_API_REFERENCE.md` - API 参考手册
- `UFC_架构设计总纲_六层四类四链三步三级两图一体.md` - 架构总纲

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队