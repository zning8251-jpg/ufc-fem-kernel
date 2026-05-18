# Shell Domain Design

## 概述

Shell域用于实现壳单元，包括三角形壳、四边形壳及其各种变体。

## 域结构

```
Shell/
├── S3/                 # 3节点三角形壳
│   ├── PH_Element_S3.f90
│   └── CONTRACT.md
├── S4/                 # 4节点四边形壳
│   ├── PH_Element_S4.f90
│   └── CONTRACT.md
├── S4R/                # 4节点减缩积分壳
│   ├── PH_Element_S4R.f90
│   └── CONTRACT.md
├── S8/                 # 8节点四边形壳
│   ├── PH_Element_S8.f90
│   └── CONTRACT.md
├── S9R/                # 9节点减缩积分壳
│   ├── PH_Element_S9R.f90
│   └── CONTRACT.md
├── STRI3/              # 3节点三角形壳（小应变）
│   ├── PH_Element_STRI3.f90
│   └── CONTRACT.md
├── STRI65/             # 6节点三角形壳（小应变）
│   ├── PH_Element_STRI65.f90
│   └── CONTRACT.md
└── SC8R/               # 8节点连续壳
    ├── PH_Element_SC8R.f90
    └── CONTRACT.md
```

## 单元类型

### 1. S3 (3节点三角形壳)

- **功能**：3节点三角形壳单元，适用于复杂几何
- **参考**：Abaqus S3
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：3点积分
- **特点**：适应性强，适合复杂网格

### 2. S4 (4节点四边形壳)

- **功能**：4节点四边形壳单元，通用壳单元
- **参考**：Abaqus S4
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：4点积分
- **特点**：精度高，计算效率好

### 3. S4R (4节点减缩积分壳)

- **功能**：4节点减缩积分壳单元，计算效率高
- **参考**：Abaqus S4R
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：1点积分+沙漏控制
- **特点**：计算效率高，适合大规模分析

### 4. S8 (8节点四边形壳)

- **功能**：8节点二次壳单元，高精度
- **参考**：Abaqus S8
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：9点积分
- **特点**：高精度，适合弯曲主导问题

### 5. S9R (9节点减缩积分壳)

- **功能**：9节点减缩积分壳单元，二次精度
- **参考**：Abaqus S9R
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：4点积分+沙漏控制
- **特点**：二次精度，计算效率高

### 6. STRI3 (3节点三角形壳，小应变)

- **功能**：3节点小应变三角形壳单元
- **参考**：Abaqus STRI3
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：3点积分
- **特点**：小应变公式，适合薄壳

### 7. STRI65 (6节点三角形壳，小应变)

- **功能**：6节点小应变三角形壳单元
- **参考**：Abaqus STRI65
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：7点积分
- **特点**：二次精度，小应变公式

### 8. SC8R (8节点连续壳)

- **功能**：8节点连续壳单元，避免剪切闭锁
- **参考**：Abaqus SC8R
- **自由度**：每节点6自由度（u,v,w,θx,θy,θz）
- **积分**：8点积分
- **特点**：连续壳公式，避免剪切闭锁

## 命名规范

- 域名：Shell
- 单元名：S3, S4, S4R, S8, S9R, STRI3, STRI65, SC8R
- 算法文件：PH_Element_[Type].f90（三段式命名）
- 与Abaqus命名对齐

## 接口规范

```fortran
subroutine PH_Element_S3(elemData, meshData, dt)
  type(ElementData), intent(inout) :: elemData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: dt
end subroutine
```

## 通用功能

- 形函数计算
- 雅可比计算
- 应变-位移矩阵（B矩阵）
- 刚度矩阵组装
- 质量矩阵组装
- 残差向量计算
- 应力输出
- 沙漏控制（减缩积分单元）

## 测试计划

- 纯弯曲测试
- 扭转测试
- 剪切闭锁测试
- 膜闭锁测试
- 收敛性测试
- 大变形测试

## 参考文献

- Abaqus Analysis User's Manual - Shell Elements
- Belytschko, T., et al. - Nonlinear Finite Elements for Continua and Structures
- Bathe, K.J. - Finite Element Procedures
