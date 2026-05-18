# Membrane Domain Design

## 概述
Membrane域用于实现膜单元，包括三角形膜、四边形膜及其各种变体。

## 域结构
```
Membrane/
├── M3D3/               # 3节点膜（3D）
│   ├── PH_Element_M3D3.f90
│   └── CONTRACT.md
├── M3D4/               # 4节点膜（3D）
│   ├── PH_Element_M3D4.f90
│   └── CONTRACT.md
├── M3D4R/              # 4节点减缩积分膜（3D）
│   ├── PH_Element_M3D4R.f90
│   └── CONTRACT.md
└── M3D6/               # 6节点膜（3D）
    ├── PH_Element_M3D6.f90
    └── CONTRACT.md
```

## 单元类型

### 1. M3D3 (3节点膜，3D)
- **功能**：3节点三角形膜单元，适用于复杂几何
- **参考**：Abaqus M3D3
- **自由度**：每节点3自由度（u,v,w）
- **积分**：3点积分
- **特点**：适应性强，适合复杂网格，仅承受膜内力

### 2. M3D4 (4节点膜，3D)
- **功能**：4节点四边形膜单元，通用膜单元
- **参考**：Abaqus M3D4
- **自由度**：每节点3自由度（u,v,w）
- **积分**：4点积分
- **特点**：精度高，计算效率好

### 3. M3D4R (4节点减缩积分膜，3D)
- **功能**：4节点减缩积分膜单元，计算效率高
- **参考**：Abaqus M3D4R
- **自由度**：每节点3自由度（u,v,w）
- **积分**：1点积分+沙漏控制
- **特点**：计算效率高，适合大规模分析

### 4. M3D6 (6节点膜，3D)
- **功能**：6节点二次膜单元，高精度
- **参考**：Abaqus M3D6
- **自由度**：每节点3自由度（u,v,w）
- **积分**：7点积分
- **特点**：二次精度，适合应变梯度大的区域

## 命名规范
- 域名：Membrane
- 单元名：M3D3, M3D4, M3D4R, M3D6
- 算法文件：PH_Element_[Type].f90（三段式命名）
- 与Abaqus命名对齐

## 接口规范
```fortran
subroutine PH_Element_M3D3(elemData, meshData, dt)
  type(ElementData), intent(inout) :: elemData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: dt
end subroutine
```

## 膜单元特点
- 仅承受膜内应力，无弯曲刚度
- 适用于薄膜、布料、气囊等结构
- 支持大变形和几何非线性
- 支持材料非线性

## 通用功能
- 形函数计算
- 雅可比计算
- 应变-位移矩阵（B矩阵）
- 刚度矩阵组装
- 质量矩阵组装
- 残差向量计算
- 应力输出
- 沙漏控制（减缩积分单元）
- 大变形处理

## 应用场景
- 薄膜结构（帐篷、气囊）
- 布料模拟
- 生物膜
- 薄膜压力容器
- 橡胶膜

## 测试计划
- 单轴拉伸测试
- 双轴拉伸测试
- 剪切测试
- 大变形测试
- 压力加载测试
- 收敛性测试

## 参考文献
- Abaqus Analysis User's Manual - Membrane Elements
- Bonet, J., and Wood, R.D. - Nonlinear Continuum Mechanics for Finite Element Analysis
- Belytschko, T., et al. - Nonlinear Finite Elements for Continua and Structures
