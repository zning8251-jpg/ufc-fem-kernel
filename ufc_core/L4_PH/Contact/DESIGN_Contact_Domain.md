# Contact Domain Design

## 概述
Contact域用于实现接触算法，包括面面接触、点面接触、自接触、摩擦接触等完整接触算法。

## 域结构
```
Contact/
├── SurfaceToSurface/    # 面面接触
│   ├── PH_Contact_SurfaceToSurface.f90
│   ├── PH_Contact_SurfaceToSurfacePenalty.f90
│   ├── PH_Contact_SurfaceToSurfaceLagrange.f90
│   └── CONTRACT.md
├── NodeToSurface/       # 点面接触
│   ├── PH_Contact_NodeToSurface.f90
│   ├── PH_Contact_NodeToSurfacePenalty.f90
│   ├── PH_Contact_NodeToSurfaceLagrange.f90
│   └── CONTRACT.md
├── SelfContact/         # 自接触
│   ├── PH_Contact_Self.f90
│   ├── PH_Contact_SelfPenalty.f90
│   └── CONTRACT.md
├── Friction/            # 摩擦接触
│   ├── PH_Contact_FrictionCoulomb.f90
│   ├── PH_Contact_FrictionPenalty.f90
│   ├── PH_Contact_FrictionExponential.f90
│   └── CONTRACT.md
├── FiniteSliding/       # 有限滑动
│   ├── PH_Contact_FiniteSliding.f90
│   └── CONTRACT.md
├── SmallSliding/        # 小滑动
│   ├── PH_Contact_SmallSliding.f90
│   └── CONTRACT.md
├── Search/              # 接触搜索
│   ├── PH_Contact_SearchGlobal.f90
│   ├── PH_Contact_SearchLocal.f90
│   ├── PH_Contact_SearchBBox.f90
│   └── CONTRACT.md
└── Thermal/             # 热接触
    ├── PH_Contact_Thermal.f90
    ├── PH_Contact_ThermalConduction.f90
    └── CONTRACT.md
```

## 接触类型

### 1. SurfaceToSurface (面面接触)
- **功能**：面面接触算法，适用于大变形问题
- **参考**：Abaqus Surface-to-Surface Contact
- **方法**：
  - 罚函数法（Penalty Method）
  - 拉格朗日乘子法（Lagrange Multiplier）
  - 增广拉格朗日法（Augmented Lagrangian）
- **特点**：精度高，适用于大变形和复杂几何

### 2. NodeToSurface (点面接触)
- **功能**：点面接触算法，适用于节点到面的接触
- **参考**：Abaqus Node-to-Surface Contact
- **方法**：
  - 罚函数法
  - 拉格朗日乘子法
- **特点**：计算效率高，适用于简单接触

### 3. SelfContact (自接触)
- **功能**：自接触算法，适用于单面接触问题
- **参考**：Abaqus Self Contact
- **方法**：
  - 罚函数法
  - 基于曲率的检测
- **特点**：适用于折叠、卷曲等自接触问题

### 4. Friction (摩擦接触)
- **功能**：摩擦接触算法，考虑摩擦效应
- **参考**：Abaqus Friction Contact
- **模型**：
  - 库仑摩擦（Coulomb Friction）
  - 罚函数摩擦（Penalty Friction）
  - 指数摩擦（Exponential Friction）
  - 粘性摩擦（Viscous Friction）
- **参数**：
  - 摩擦系数 μ
  - 粘性系数 η
  - 摩擦硬化参数

### 5. FiniteSliding (有限滑动)
- **功能**：有限滑动接触算法，适用于大滑动
- **参考**：Abaqus Finite Sliding
- **方法**：
  - 基于路径的跟踪
  - 动态接触检测
- **特点**：适用于大滑动问题

### 6. SmallSliding (小滑动)
- **功能**：小滑动接触算法，适用于小变形
- **参考**：Abaqus Small Sliding
- **方法**：
  - 基于初始构型的检测
  - 静态接触对
- **特点**：计算效率高，适用于小变形

### 7. Search (接触搜索)
- **功能**：接触搜索算法，检测接触对
- **参考**：Abaqus Contact Search
- **方法**：
  - 全局搜索（Global Search）
  - 局部搜索（Local Search）
  - 包围盒搜索（BBox Search）
- **特点**：高效的接触检测算法

### 8. Thermal (热接触)
- **功能**：热接触算法，考虑热传导
- **参考**：Abaqus Thermal Contact
- **方法**：
  - 热传导接触
  - 热阻接触
- **参数**：
  - 热导率 k
  - 热阻 R
  - 热容 C

## 命名规范
- 域名：Contact
- 子域名：SurfaceToSurface, NodeToSurface, SelfContact, Friction, FiniteSliding, SmallSliding, Search, Thermal
- 算法文件：PH_Contact_[Type].f90（三段式命名）
- 参数命名：contactStiffness, frictionCoeff, thermalConductivity, penetrationTolerance

## 接口规范
```fortran
subroutine PH_Contact_SurfaceToSurface(contactData, meshData, dt)
  type(ContactData), intent(inout) :: contactData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: dt
end subroutine
```

## 接触参数
- 罚刚度（Penalty Stiffness）
- 摩擦系数（Friction Coefficient）
- 穿透容差（Penetration Tolerance）
- 接触容差（Contact Tolerance）
- 热导率（Thermal Conductivity）
- 热阻（Thermal Resistance）

## 通用功能
- 接触检测
- 穿透计算
- 接触力计算
- 摩擦力计算
- 接触刚度矩阵组装
- 接触残差向量计算
- 接触状态更新
- 热流计算（热接触）

## 接触状态
- 开（Open）
- 闭（Closed）
- 滑动（Sliding）
- 粘滞（Sticking）

## 测试计划
- 球体碰撞测试
- 板块接触测试
- 自接触测试
- 摩擦测试
- 热接触测试
- 大滑动测试
- 收敛性测试

## 参考文献
- Abaqus Analysis User's Manual - Contact
- Wriggers, P. - Computational Contact Mechanics
- Laursen, T.A. - Computational Contact and Impact Mechanics
- Zavarise, G., and Wriggers, P. - Contact Mechanics
