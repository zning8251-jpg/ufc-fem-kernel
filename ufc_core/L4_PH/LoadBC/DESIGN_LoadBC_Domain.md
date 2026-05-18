# LoadBC Domain Design

## 概述

LoadBC域用于实现完整的载荷和边界条件类型，包括各种载荷类型和约束类型。

## 域结构

```
LoadBC/
├── Load/                # 载荷域
│   ├── ConcentratedLoad/ # 集中载荷
│   │   ├── PH_Load_Concentrated.f90
│   │   └── CONTRACT.md
│   ├── DistributedLoad/  # 分布载荷
│   │   ├── PH_Load_Distributed.f90
│   │   └── CONTRACT.md
│   ├── PressureLoad/     # 压力载荷
│   │   ├── PH_Load_Pressure.f90
│   │   └── CONTRACT.md
│   ├── GravityLoad/      # 重力载荷
│   │   ├── PH_Load_Gravity.f90
│   │   └── CONTRACT.md
│   ├── CentrifugalLoad/  # 离心载荷
│   │   ├── PH_Load_Centrifugal.f90
│   │   └── CONTRACT.md
│   ├── ThermalLoad/      # 热载荷
│   │   ├── PH_Load_Thermal.f90
│   │   └── CONTRACT.md
│   ├── FluidLoad/        # 流体载荷
│   │   ├── PH_Load_Fluid.f90
│   │   └── CONTRACT.md
│   ├── InertiaLoad/      # 惯性载荷
│   │   ├── PH_Load_Inertia.f90
│   │   └── CONTRACT.md
│   └── FollowerLoad/     # 随动载荷
│       ├── PH_Load_Follower.f90
│       └── CONTRACT.md
└── Constraint/          # 约束域
    ├── DisplacementBC/   # 位移边界条件
    │   ├── PH_BC_Displacement.f90
    │   └── CONTRACT.md
    ├── RotationBC/       # 旋转边界条件
    │   ├── PH_BC_Rotation.f90
    │   └── CONTRACT.md
    ├── VelocityBC/       # 速度边界条件
    │   ├── PH_BC_Velocity.f90
    │   └── CONTRACT.md
    ├── AccelerationBC/   # 加速度边界条件
    │   ├── PH_BC_Acceleration.f90
    │   └── CONTRACT.md
    ├── TemperatureBC/    # 温度边界条件
    │   ├── PH_BC_Temperature.f90
    │   └── CONTRACT.md
    ├── ElectricBC/       # 电场边界条件
    │   ├── PH_BC_Electric.f90
    │   └── CONTRACT.md
    ├── MagneticBC/       # 磁场边界条件
    │   ├── PH_BC_Magnetic.f90
    │   └── CONTRACT.md
    ├── EquationBC/       # 方程约束
    │   ├── PH_BC_Equation.f90
    │   └── CONTRACT.md
    ├── TieConstraint/    # 耦合约束
    │   ├── PH_BC_Tie.f90
    │   └── CONTRACT.md
    ├── CouplingConstraint/ # 耦合约束
    │   ├── PH_BC_Coupling.f90
    │   └── CONTRACT.md
    ├── MPC/              # 多点约束
    │   ├── PH_BC_MPC.f90
    │   └── CONTRACT.md
    └── RigidBody/        # 刚体约束
        ├── PH_BC_RigidBody.f90
        └── CONTRACT.md
```

## 载荷类型

### 1. ConcentratedLoad (集中载荷)

- **功能**：节点集中载荷
- **参考**：Abaqus *Cload
- **参数**：
  - 载荷大小
  - 载荷方向
  - 载荷随时间变化
- **应用**：点载荷、节点力

### 2. DistributedLoad (分布载荷)

- **功能**：表面或边分布载荷
- **参考**：Abaqus *Dload
- **参数**：
  - 载荷密度
  - 载荷方向
  - 载荷分布函数
- **应用**：表面力、边载荷

### 3. PressureLoad (压力载荷)

- **功能**：表面压力载荷
- **参考**：Abaqus *Dsload
- **参数**：
  - 压力大小
  - 压力方向
  - 压力随时间变化
- **应用**：流体压力、气压

### 4. GravityLoad (重力载荷)

- **功能**：重力载荷
- **参考**：Abaqus *Gravity
- **参数**：
  - 重力加速度
  - 重力方向
  - 材料密度
- **应用**：自重、重力影响

### 5. CentrifugalLoad (离心载荷)

- **功能**：旋转离心载荷
- **参考**：Abaqus *Centrifugal
- **参数**：
  - 旋转速度
  - 旋转轴
  - 材料密度
- **应用**：旋转部件

### 6. ThermalLoad (热载荷)

- **功能**：温度载荷
- **参考**：Abaqus *Temperature
- **参数**：
  - 温度场
  - 热膨胀系数
  - 参考温度
- **应用**：热应力、热变形

### 7. FluidLoad (流体载荷)

- **功能**：流体载荷
- **参考**：Abaqus *Fluid Cavity
- **参数**：
  - 流体压力
  - 流体密度
  - 流体体积
- **应用**：流体压力、液压

### 8. InertiaLoad (惯性载荷)

- **功能**：惯性载荷
- **参考**：Abaqus *Rotational Inertia
- **参数**：
  - 质量矩阵
  - 加速度
  - 旋转速度
- **应用**：动力惯性

### 9. FollowerLoad (随动载荷)

- **功能**：随动载荷（载荷方向随变形变化）
- **参考**：Abaqus *Follower Force
- **参数**：
  - 载荷大小
  - 载荷方向（随变形更新）
- **应用**：大变形跟随载荷

## 约束类型

### 1. DisplacementBC (位移边界条件)

- **功能**：位移约束
- **参考**：Abaqus *Boundary
- **参数**：
  - 位移值
  - 约束自由度
  - 随时间变化
- **应用**：固定支座、位移控制

### 2. RotationBC (旋转边界条件)

- **功能**：旋转约束
- **参考**：Abaqus *Boundary (Rotation)
- **参数**：
  - 旋转角度
  - 旋转轴
  - 随时间变化
- **应用**：旋转约束

### 3. VelocityBC (速度边界条件)

- **功能**：速度约束
- **参考**：Abaqus *Boundary (Velocity)
- **参数**：
  - 速度值
  - 约束自由度
  - 随时间变化
- **应用**：动力速度控制

### 4. AccelerationBC (加速度边界条件)

- **功能**：加速度约束
- **参考**：Abaqus *Boundary (Acceleration)
- **参数**：
  - 加速度值
  - 约束自由度
  - 随时间变化
- **应用**：地震加速度

### 5. TemperatureBC (温度边界条件)

- **功能**：温度约束
- **参考**：Abaqus *Boundary (Temperature)
- **参数**：
  - 温度值
  - 随时间变化
- **应用**：温度边界

### 6. ElectricBC (电场边界条件)

- **功能**：电场约束
- **参考**：Abaqus *Boundary (Electric)
- **参数**：
  - 电势值
  - 随时间变化
- **应用**：静电分析

### 7. MagneticBC (磁场边界条件)

- **功能**：磁场约束
- **参考**：Abaqus *Boundary (Magnetic)
- **参数**：
  - 磁势值
  - 随时间变化
- **应用**：磁分析

### 8. EquationBC (方程约束)

- **功能**：线性方程约束
- **参考**：Abaqus *Equation
- **参数**：
  - 方程系数
  - 方程常数
- **应用**：多点线性约束

### 9. TieConstraint (耦合约束)

- **功能**：刚性耦合约束
- **参考**：Abaqus *Tie
- **参数**：
  - 主面
  - 从面
  - 容差
- **应用**：面面耦合

### 10. CouplingConstraint (耦合约束)

- **功能**：运动耦合约束
- **参考**：Abaqus *Coupling
- **参数**：
  - 参考点
  - 耦合节点
  - 耦合类型
- **应用**：运动耦合

### 11. MPC (多点约束)

- **功能**：多点约束
- **参考**：Abaqus *MPC
- **参数**：
  - 约束类型
  - 约束节点
  - 约束系数
- **应用**：复杂约束

### 12. RigidBody (刚体约束)

- **功能**：刚体约束
- **参考**：Abaqus *Rigid Body
- **参数**：
  - 参考点
  - 刚体节点
  - 刚体质量
- **应用**：刚体运动

## 命名规范

- 域名：LoadBC
- 子域名：Load, Constraint
- 载荷类型：ConcentratedLoad, DistributedLoad, PressureLoad等
- 约束类型：DisplacementBC, RotationBC, VelocityBC等
- 算法文件：PH_Load_[Type].f90, PH_BC_[Type].f90（三段式命名）
- 参数命名：loadMagnitude, loadDirection, displacementValue, rotationAngle, velocityValue

## 接口规范

```fortran
subroutine PH_Load_Concentrated(loadData, meshData, time)
  type(LoadData), intent(inout) :: loadData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: time
end subroutine

subroutine PH_BC_Displacement(bcData, meshData, time)
  type(BCData), intent(inout) :: bcData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: time
end subroutine
```

## 通用功能

- 载荷应用
- 载荷随时间变化
- 载荷方向更新（随动载荷）
- 约束应用
- 约束随时间变化
- 约束方程组装
- 载荷向量计算
- 约束矩阵计算

## 测试计划

- 集中载荷测试
- 压力载荷测试
- 重力载荷测试
- 位移约束测试
- 速度约束测试
- 加速度约束测试
- 随动载荷测试
- 多点约束测试
- 刚体约束测试

## 参考文献

- Abaqus Analysis User's Manual - Loads and Boundary Conditions
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis
- Bathe, K.J. - Finite Element Procedures
