# Beam Domain Design

## 概述
Beam域用于实现梁单元，包括线性梁、二次梁及其各种变体。

## 域结构
```
Beam/
├── B21/                # 2节点线性梁（2D）
│   ├── PH_Element_B21.f90
│   └── CONTRACT.md
├── B22/                # 2节点二次梁（2D）
│   ├── PH_Element_B22.f90
│   └── CONTRACT.md
├── B31/                # 3节点线性梁（3D）
│   ├── PH_Element_B31.f90
│   └── CONTRACT.md
├── B32/                # 3节点二次梁（3D）
│   ├── PH_Element_B32.f90
│   └── CONTRACT.md
├── B31H/               # 3节点混合梁（3D）
│   ├── PH_Element_B31H.f90
│   └── CONTRACT.md
├── PIPE31/             # 3节点管单元（3D）
│   ├── PH_Element_PIPE31.f90
│   └── CONTRACT.md
└── PIPE32/             # 3节点管单元（3D，二次）
    ├── PH_Element_PIPE32.f90
    └── CONTRACT.md
```

## 单元类型

### 1. B21 (2节点线性梁，2D)
- **功能**：2节点线性梁单元，2D平面问题
- **参考**：Abaqus B21
- **自由度**：每节点3自由度（u,v,θz）
- **积分**：2点积分
- **特点**：适用于2D框架分析

### 2. B22 (2节点二次梁，2D)
- **功能**：2节点二次梁单元，2D平面问题
- **参考**：Abaqus B22
- **自由度**：每节点3自由度（u,v,θz）
- **积分**：3点积分
- **特点**：二次精度，适用于弯曲主导问题

### 3. B31 (3节点线性梁，3D)
- **功能**：3节点线性梁单元，3D空间问题
- **参考**：Abaqus B31
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：2点积分
- **特点**：适用于3D框架分析

### 4. B32 (3节点二次梁，3D)
- **功能**：3节点二次梁单元，3D空间问题
- **参考**：Abaqus B32
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：3点积分
- **特点**：二次精度，适用于复杂弯曲

### 5. B31H (3节点混合梁，3D)
- **功能**：3节点混合梁单元，避免剪切闭锁
- **参考**：Abaqus B31H
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：2点积分+混合公式
- **特点**：混合公式，避免剪切闭锁

### 6. PIPE31 (3节点管单元，3D)
- **功能**：3节点管单元，考虑管截面几何
- **参考**：Abaqus PIPE31
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：2点积分
- **特点**：适用于管道分析

### 7. PIPE32 (3节点管单元，3D，二次)
- **功能**：3节点管单元，二次精度
- **参考**：Abaqus PIPE32
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：3点积分
- **特点**：二次精度，适用于复杂管道

## 命名规范
- 域名：Beam
- 单元名：B21, B22, B31, B32, B31H, PIPE31, PIPE32
- 算法文件：PH_Element_[Type].f90（三段式命名）
- 与Abaqus命名对齐

## 接口规范
```fortran
subroutine PH_Element_B31(elemData, meshData, dt)
  type(ElementData), intent(inout) :: elemData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: dt
end subroutine
```

## 截面类型
- 矩形截面
- 圆形截面
- I型截面
- 管截面
- 任意截面（通过截面属性定义）

## 通用功能
- 形函数计算
- 雅可比计算
- 应变-位移矩阵（B矩阵）
- 刚度矩阵组装
- 质量矩阵组装
- 残差向量计算
- 应力输出
- 截面力计算
- 剪切闭锁控制（混合单元）

## 局部坐标系
- 参考节点类型
- 参考向量定义
- 局部基向量计算
- 坐标变换矩阵

## 测试计划
- 纯弯曲测试
- 扭转测试
- 剪切变形测试
- 轴向变形测试
- 大变形测试
- 管道压力测试（PIPE单元）

## 参考文献
- Abaqus Analysis User's Manual - Beam Elements
- Simo, J.C., and Vu-Quoc, L. (1986). "A three-dimensional finite-strain rod model"
- Crisfield, M.A. - Non-Linear Finite Element Analysis of Solids and Structures
