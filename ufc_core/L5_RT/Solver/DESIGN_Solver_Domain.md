# Solver Domain Design

## 概述

Solver域用于实现各种求解器算法，包括动态求解器、模态求解器、特征值求解器等完整求解器类型。

## 域结构

```
Solver/
├── ImplicitDynamic/     # 隐式动力求解器
│   ├── RT_Solv_ImplDyn_Newmark.f90
│   ├── RT_Solv_ImplDyn_HHT.f90
│   ├── RT_Solv_ImplDyn_BDF.f90
│   └── CONTRACT.md
├── ExplicitDynamic/     # 显式动力求解器
│   ├── RT_Solv_ExplDyn_CentralDiff.f90
│   ├── RT_Solv_ExplDyn_VelocityVerlet.f90
│   └── CONTRACT.md
├── Modal/               # 模态求解器
│   ├── RT_Solv_Modal_Lanczos.f90
│   ├── RT_Solv_Modal_Subspace.f90
│   ├── RT_Solv_Modal_BlockLanczos.f90
│   └── CONTRACT.md
├── EigenSolver/         # 特征值求解器
│   ├── RT_Solv_Eigen_QR.f90
│   ├── RT_Solv_Eigen_Arnoldi.f90
│   ├── RT_Solv_Eigen_JacobiDavidson.f90
│   └── CONTRACT.md
├── Substructure/        # 子结构求解器
│   ├── RT_Solv_Substructure_CMS.f90
│   ├── RT_Solv_Substructure_CraigBampton.f90
│   └── CONTRACT.md
├── FrequencyDomain/     # 频域求解器
│   ├── RT_Solv_Freq_Harmonic.f90
│   ├── RT_Solv_Freq_RandomResponse.f90
│   └── CONTRACT.md
└── ResponseSpectrum/    # 响应谱求解器
    ├── RT_Solv_Spectrum_Linear.f90
    ├── RT_Solv_Spectrum_Nonlinear.f90
    └── CONTRACT.md
```

## 求解器类型

### 1. ImplicitDynamic (隐式动力求解器)

- **功能**：隐式时间积分动力求解器
- **参考**：Abaqus Implicit Dynamic
- **方法**：
  - Newmark方法（Newmark Method）
  - Hilber-Hughes-Taylor方法（HHT Method）
  - BDF方法（Backward Differentiation Formula）
- **参数**：
  - 时间步长 dt
  - 阻尼参数 α, β, γ
  - 数值阻尼参数
- **特点**：无条件稳定，适用于中等频率问题

### 2. ExplicitDynamic (显式动力求解器)

- **功能**：显式时间积分动力求解器
- **参考**：Abaqus Explicit Dynamic
- **方法**：
  - 中心差分法（Central Difference Method）
  - 速度Verlet法（Velocity Verlet Method）
- **参数**：
  - 时间步长 dt
  - 质量缩放参数
  - 人工粘性参数
- **特点**：条件稳定，适用于高频和冲击问题

### 3. Modal (模态求解器)

- **功能**：模态分析求解器，计算固有频率和模态
- **参考**：Abaqus Frequency
- **方法**：
  - Lanczos方法（Lanczos Algorithm）
  - 子空间迭代法（Subspace Iteration）
  - 块Lanczos方法（Block Lanczos）
- **参数**：
  - 频率范围
  - 模态数量
  - 收敛容差
- **特点**：高效计算低频模态

### 4. EigenSolver (特征值求解器)

- **功能**：广义特征值问题求解器
- **参考**：Abaqus Eigenvalue Extraction
- **方法**：
  - QR分解法（QR Algorithm）
  - Arnoldi方法（Arnoldi Algorithm）
  - Jacobi-Davidson方法（Jacobi-Davidson Algorithm）
- **参数**：
  - 特征值数量
  - 收敛容差
  - 最大迭代次数
- **特点**：求解大规模特征值问题

### 5. Substructure (子结构求解器)

- **功能**：子结构分析求解器（CMS）
- **参考**：Abaqus Substructure
- **方法**：
  - Craig-Bampton方法（Craig-Bampton CMS）
  - 固定界面模态法
  - 自由界面模态法
- **参数**：
  - 固定模态数量
  - 约束模态数量
  - 界面节点
- **特点**：适用于大规模系统降阶

### 6. FrequencyDomain (频域求解器)

- **功能**：频域分析求解器
- **参考**：Abaqus Steady-State Dynamics
- **方法**：
  - 谐波响应分析（Harmonic Response）
  - 随机响应分析（Random Response）
- **参数**：
  - 频率范围
  - 频率步长
  - 载荷谱
- **特点**：适用于周期性激励问题

### 7. ResponseSpectrum (响应谱求解器)

- **功能**：响应谱分析求解器
- **参考**：Abaqus Response Spectrum
- **方法**：
  - 线性响应谱（Linear Response Spectrum）
  - 非线性响应谱（Nonlinear Response Spectrum）
- **参数**：
  - 响应谱曲线
  - 模态组合方法
  - 阻尼比
- **特点**：适用于地震响应分析

## 命名规范

- 域名：Solver
- 子域名：ImplicitDynamic, ExplicitDynamic, Modal, EigenSolver, Substructure, FrequencyDomain, ResponseSpectrum
- 算法文件：RT_Solv_[Type]_[Method].f90（三段式命名）
- 参数命名：timeStep, dampingParam, frequencyRange, eigenValueCount, convergenceTolerance

## 接口规范

```fortran
subroutine RT_Solv_ImplDyn_Newmark(solverData, meshData, dt)
  type(SolverData), intent(inout) :: solverData
  type(MeshData), intent(in) :: meshData
  real(8), intent(in) :: dt
end subroutine
```

## 通用功能

- 刚度矩阵组装
- 质量矩阵组装
- 阻尼矩阵组装
- 时间积分
- 迭代求解
- 收敛判定
- 结果输出
- 重启动功能

## 求解器参数

- 时间步长（Time Step）
- 阻尼参数（Damping Parameters）
- 收敛容差（Convergence Tolerance）
- 最大迭代次数（Maximum Iterations）
- 数值阻尼（Numerical Damping）

## 测试计划

- 隐式动力测试
- 显式动力测试
- 模态分析测试
- 特征值求解测试
- 子结构测试
- 频域分析测试
- 响应谱测试
- 收敛性测试

## 参考文献

- Abaqus Analysis User's Manual - Solvers
- Bathe, K.J. - Finite Element Procedures
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis
- Hughes, T.J.R. - The Finite Element Method: Linear Static and Dynamic Finite Element Analysis
