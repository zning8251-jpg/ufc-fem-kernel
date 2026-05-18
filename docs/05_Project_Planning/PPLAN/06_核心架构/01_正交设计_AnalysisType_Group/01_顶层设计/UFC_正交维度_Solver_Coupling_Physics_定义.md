# UFC正交维度定义 - Solver/Coupling/Physics完整规范

**版本**: v1.0  
**日期**: 2026-04-04  
**状态**: 核心设计文档  
**作者**: UFC架构设计组  

---

## 📋 目录

1. [设计原理](#设计原理)
2. [三维坐标编码体系](#三维坐标编码体系)
3. [Solver维度](#solver维度求解器类型)
4. [Coupling维度](#coupling维度求解算法耦合策略)
5. [Physics维度](#physics维度物理表象)

---

## 设计原理

### 核心思想

UFC的三维正交Group编码体系基于以下设计哲学：

```
Group_ID = [Solver] + [Coupling] + [Physics]
         = [求解器范式] + [求解算法] + [物理表象]
```

**三个维度的职责完全独立**：

| 维度 | 职责 | 枚举类型 | 含义 |
|-----|------|--------|------|
| **Solver** | 时间积分范式 | 离散值 | Standard/Explicit/Acoustic/EM/CFD |
| **Coupling** | 多场求解策略 | 离散值 | OneShot/OneWay/Weak/Strong |
| **Physics** | 问题的物理表象 | 离散值 | Structure/Thermal/Frequency/... |

**正交性要求**：
- ✅ 三个维度互不嵌套
- ✅ 任意组合可以产生新的有效坐标（通过约束矩阵管理）
- ✅ 扩展新的物理场或求解器时，无需修改其他维度

### ABAQUS对标

UFC的三维设计完全覆盖ABAQUS求解器生态：

| ABAQUS模块 | UFC Solver | UFC Physics | UFC Coupling |
|-----------|-----------|------------|-------------|
| Standard (隐式) | 1 | 1-8,11,12 | 1-4 |
| Explicit (显式) | 2 | 1 | 1 |
| Acoustic | 3 | 4 | 1 |
| Electromagnetic | 4 | 5 | 1 |
| CFD | 5 | 6,9,10 | 1,3,4 |

---

## 三维坐标编码体系

### 完整坐标系统

```
Group_ID_3D = Solver × 100 + Coupling × 10 + Physics
            = [1-5] × 100 + [1-4] × 10 + [1-12]

内部实现：转换为0-based索引
Internal_Index = (Solver-1) × 100 + (Coupling-1) × 10 + (Physics-1)
               = [0-4] × 100 + [0-3] × 10 + [0-11]
```

**设计意义**：
- 外部API采用1-based编号，符合用户直观认知
- 内部实现转换为0-based，便于矩阵索引和高效运算
- 转换由L3_MD层的转换函数自动完成，用户无需关注

---

## Solver维度（求解器类型）

### 外部API编号 (1-based)

| ID | 名称 | 时间积分 | 主要求解对象 | 约束 |
|----|------|--------|----------|------|
| **1** | **Standard** | 隐式 | 准静态/瞬态(隐式) | 支持所有Physics(受约束) |
| **2** | **Explicit** | 显式 | 瞬态(显式) | 仅Physics=1(Structure) |
| **3** | **Acoustic** | 特殊 | 声学波传播 | 仅Physics=4 |
| **4** | **Electromagnetic** | 特殊 | 电磁场 | 仅Physics=5 |
| **5** | **CFD** | 特殊 | 流体力学 | 仅Physics=6,9,10 |

### 内部实现索引 (0-based)

通过转换函数转为[0-4]

**转换规则**：
```fortran
solver_internal = solver_external - 1
! solver_external=1 → solver_internal=0 (Standard)
! solver_external=5 → solver_internal=4 (CFD)
```

---

## Coupling维度（求解算法/耦合策略）

### 外部API编号 (1-based)

| ID | 名称 | 含义 | 应用场景 | 迭代特性 |
|----|------|------|--------|--------|
| **1** | **OneShot** | 单次求解 | 单物理场或无耦合 | 无迭代 |
| **2** | **OneWay** | 单向传递 | 弱单向耦合 | 单向迭代 |
| **3** | **Weak** | 弱耦合 | 松耦合多场 | 松耦合迭代 |
| **4** | **Strong** | 强耦合 | 紧耦合多场 | 紧耦合完全迭代 |

### 内部实现索引 (0-based)

通过转换函数转为[0-3]

**转换规则**：
```fortran
coupling_internal = coupling_external - 1
! coupling_external=1 → coupling_internal=0 (OneShot)
! coupling_external=4 → coupling_internal=3 (Strong)
```

### 耦合算法框架

```fortran
! OneShot (Coupling=1/内部0)
DO step = 1, n_steps
  solver%execute(analysis_group)
END DO

! OneWay (Coupling=2/内部1)
DO step = 1, n_steps
  field_A%compute()
  field_B%compute(field_A)  ! 单向依赖
END DO

! Weak (Coupling=3/内部2)
DO step = 1, n_steps
  DO iter = 1, n_weak_iter
    field_A%compute_provisional()
    field_B%compute(field_A)
    exchange_boundary(field_A, field_B)
  END DO
END DO

! Strong (Coupling=4/内部3)
DO step = 1, n_steps
  DO iter = 1, n_strong_iter
    DO sub_iter = 1, n_sub_iter
      field_A%compute()
      field_B%compute(field_A)
      residual = check_convergence()
      IF (residual < tol) EXIT
    END DO
    exchange_boundary(field_A, field_B)
  END DO
END DO
```

---

## Physics维度（物理表象）

### 第一组：基本单场（6类）

基本单场代表ABAQUS的基础求解能力，各自独立对应一类求解器。

#### 外部API编号 (1-based)

| ID | 名称 | 含义 | ABAQUS对标 | 主求解器 | 特点 |
|----|------|------|----------|--------|------|
| **1** | **Structure** | 结构力学/固体力学 | ABAQUS/Standard + Explicit | STD/EXP | 包含准静态、动力学、岩土 |
| **2** | **Thermal** | 热传导分析 | ABAQUS/Standard热求解器 | STD | 传导、对流、辐射 |
| **3** | **Frequency** | 频域分析(含模态) | ABAQUS Modal/Steady-state | STD | 固有频率、谐波响应 |
| **4** | **Acoustic** | 声学传播 | ABAQUS/Acoustic | ACO | 声压、声强 |
| **5** | **EM** | 电磁场分析 | ABAQUS/Electromagnetic | EM | 静电、磁场、涡流 |
| **6** | **Fluid** | 流体力学(CFD) | ABAQUS/CFD | CFD | 单相流、不可压/可压 |

#### 内部实现索引 (0-based)

通过转换函数转为[0-5]

---

### 第二组：双场耦合（4类）

双场耦合代表ABAQUS中的多场耦合分析类型。这些不是独立物理场，而是两个基本场的组合。

#### 外部API编号 (1-based)

| ID | 名称 | 组成 | PROC范围 | 推荐Coupling | 耦合紧密度 | 特点 |
|----|------|------|---------|------------|----------|------|
| **7** | **ThermalStruct** | 热+结构 | 32,34 | **Weak(3)** | 松耦合 | 温度缓变、结构变形小 |
| **8** | **ElectroStruct** | 电+结构 | 35 | **Strong(4)** | 紧耦合 | 压电效应、快速响应 |
| **9** | **FluidStruct** | 流体+结构(FSI) | - | **Strong(4)** | 紧耦合 | 流体-结构相互作用 |
| **10** | **FluidThermal** | 流体+热 | - | **Weak(3)** | 松耦合 | 对流换热、温度分层 |

#### 内部实现索引 (0-based)

通过转换函数转为[6-9]

**耦合特性矩阵**：

```
双场类型      耦合类型   时间尺度特性        推荐策略    可覆盖范围
─────────────────────────────────────────────────────────────
ThermalStruct  异步     热缓变/结构快速  Weak优先    [1][3][7]
ElectroStruct  同步     压电同步响应     Strong必需  [1][4][8]
FluidStruct    同步     流固互作用快速   Strong必需  [5][4][9]
FluidThermal   异步     热分层缓变      Weak优先    [5][3][10]
```

---

### 第三组：高阶耦合与特殊（2类）

#### 外部API编号 (1-based)

| ID | 名称 | 含义 | 场数 | PROC范围 | 推荐Coupling | 说明 |
|----|------|------|-----|---------|------------|------|
| **11** | **MultiField** | 三场及以上耦合 | 3+ | 33,51 | **Strong(4)** | 热-电-结构或其他三场组合 |
| **12** | **Special** | 特殊/其他分析 | 可变 | - | 可变 | 预留扩展空间 |

#### 内部实现索引 (0-based)

通过转换函数转为[10-11]

---

## 坐标空间规模

| 方案 | Solver | Coupling | Physics | 理论空间 | 增长 | 实际使用 | 编号方式 |
|-----|--------|----------|---------|--------|------|--------|----------|
| 原方案 | 5(0-4) | 4(0-3) | 10(0-9) | **200** | - | ~35 | 0-based |
| **新方案** | 5(1-5) | 4(1-4) | **12(1-12)** | **240** | **+20%** | ~45 | **1-based**✨ |

**增长分析**：
- 新增40个坐标位
- 增长率为20%（可接受）
- 实际使用坐标数增加~10个（用于CFD耦合）

---

## 设计优势总结

✅ **完整性** - 覆盖ABAQUS全部求解器生态  
✅ **正交性** - 三维度完全独立，无嵌套  
✅ **可扩展性** - 新增Physics/Solver无需修改其他维度  
✅ **直观性** - 1-based编号符合工程习惯  
✅ **对标性** - 与ABAQUS PROC编号一致  
✅ **高效性** - 内层0-based编号便于矩阵运算  

---

**相关文档**：
- 📍 核心映射表：`02_核心映射表/ABAQUS_PROC_到_Group_ID_完整映射.md`
- 📍 实现指导：`03_实现指导/L3_MD_Group_DESC_类型定义_实现.md`
