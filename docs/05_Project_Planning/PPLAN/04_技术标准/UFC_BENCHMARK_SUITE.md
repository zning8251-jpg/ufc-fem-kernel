# UFC 标准测试问题库

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 数值验证与基准测试  
> **上级参考**: UFC_TEST_STRATEGY.md（测试策略）

---

## 📋 文档说明

本文档定义 UFC 项目的标准测试问题库，包括：

- 问题描述
- 几何定义
- 材料参数
- 边界条件
- 参考解（解析解或 ABAQUS 结果）
- UFC 实现位置
- 验收标准

---

## 目录

1. [基础测试问题](#1-基础测试问题)
2. [NAFEMS 标准问题](#2-nafems-标准问题)
3. [ABAQUS 验证手册问题](#3-abaqus-验证手册问题)
4. [性能基准测试](#4-性能基准测试)
5. [测试数据管理](#5-测试数据管理)

---

## 1. 基础测试问题

### 1.1 Patch Test（常应变场测试）

**问题编号**: BENCHMARK_001  
**问题类型**: 单元精度验证  
**难度**: ⭐ 基础

#### 问题描述

验证单元能精确再现常应变场。这是有限元方法的基本要求。

#### 几何定义

**单元类型**: C3D8（8节点六面体）  
**几何**: 单位立方体（1×1×1）

```
节点坐标（8个节点）:
Node 1: (0, 0, 0)
Node 2: (1, 0, 0)
Node 3: (1, 1, 0)
Node 4: (0, 1, 0)
Node 5: (0, 0, 1)
Node 6: (1, 0, 1)
Node 7: (1, 1, 1)
Node 8: (0, 1, 1)
```

#### 材料参数

```fortran
E = 200.0e9_wp      ! 杨氏模量（Pa）
nu = 0.3_wp         ! 泊松比
density = 7850.0_wp ! 密度（kg/m³）
```

#### 边界条件

**位移边界条件**:

- 节点 1: u = (0, 0, 0)（固定）
- 节点 2: u = (1, 0, 0)（x方向位移 = 1）
- 节点 4: u = (0, 1, 0)（y方向位移 = 1）
- 节点 5: u = (0, 0, 1)（z方向位移 = 1）

**预期应变场**: 常应变场 ε = [1, 1, 1, 0, 0, 0]

#### 参考解

**解析解**:

- 所有内部节点位移应精确满足线性插值
- 单元内应力应为常数
- 单元内应变应为常数

#### UFC 实现位置

**测试文件**: `tests/Numerical/test_patch_test.f90`  
**参考实现**: `L2_NM/Valid/NM_Valid_Patch.f90`

#### 验收标准

- **位移误差**: < 1.0e-10（机器精度）
- **应力误差**: < 1.0e-10（机器精度）
- **应变误差**: < 1.0e-10（机器精度）

---

### 1.2 Cantilever Beam（悬臂梁）

**问题编号**: BENCHMARK_002  
**问题类型**: 弯曲问题  
**难度**: ⭐⭐ 中级

#### 问题描述

悬臂梁在自由端受集中力作用，验证弯曲变形和应力分布。

#### 几何定义

**尺寸**: L = 10 m（长度），h = 1 m（高度），b = 0.5 m（宽度）

```
几何模型:
     F
     ↓
  ┌─────┐
  │     │
  │     │  L = 10 m
  │     │
  └─────┘
  固定端
```

**网格**: 10×1×1（10个C3D8单元）

#### 材料参数

```fortran
E = 200.0e9_wp      ! 杨氏模量（Pa）
nu = 0.3_wp         ! 泊松比
density = 7850.0_wp ! 密度（kg/m³）
```

#### 边界条件

**固定端**（x = 0）:

- u = (0, 0, 0)（所有节点）

**载荷**（自由端，x = L）:

- F = 1000 N（y方向，向下）

#### 参考解

**解析解**（Euler-Bernoulli 梁理论）:

最大挠度（自由端）:

```
δ_max = FL³/(3EI) = 1000 × 10³ / (3 × 200e9 × I)
```

其中惯性矩:

```
I = bh³/12 = 0.5 × 1³ / 12 = 0.04167 m⁴
```

**ABAQUS 参考结果**:

- 最大挠度: δ_max = 0.04 m
- 最大应力（固定端）: σ_max = 24 MPa

#### UFC 实现位置

**测试文件**: `tests/Numerical/test_cantilever_beam.f90`  
**输入文件**: `tests/data/input/cantilever_beam.inp`  
**参考结果**: `tests/data/reference/cantilever_beam_abaqus.dat`

#### 验收标准

- **位移误差**: < 1%（相对于解析解）
- **应力误差**: < 2%（相对于解析解）
- **与 ABAQUS 对比**: 相对误差 < 1%

---

### 1.3 Cook's Membrane（Cook 膜）

**问题编号**: BENCHMARK_003  
**问题类型**: 弯曲问题  
**难度**: ⭐⭐⭐ 高级

#### 问题描述

经典的 Cook's Membrane 问题，用于验证单元在弯曲和剪切组合载荷下的性能。

#### 几何定义

**尺寸**: 

- 长度: L = 48 mm
- 高度: h = 44 mm（左端），H = 60 mm（右端）
- 厚度: t = 1 mm

```
几何模型:
    F
    ↓
  ┌─────┐
  │     │
  │     │
  └─────┘
  固定端
```

#### 材料参数

```fortran
E = 1.0_wp          ! 杨氏模量（归一化）
nu = 1/3_wp         ! 泊松比 = 1/3
density = 1.0_wp    ! 密度（归一化）
```

#### 边界条件

**固定端**（左端）:

- u = (0, 0)（所有节点）

**载荷**（右端）:

- F = 1.0 N（y方向，向上，均匀分布）

#### 参考解

**NAFEMS 参考解**:

- 右端上角点位移（y方向）: u_y = 23.96 mm

**ABAQUS 参考结果**:

- 右端上角点位移: u_y = 23.964 mm（C3D8单元）
- 右端上角点位移: u_y = 23.970 mm（C3D20单元）

#### UFC 实现位置

**测试文件**: `tests/Numerical/test_cooks_membrane.f90`  
**输入文件**: `tests/data/input/cooks_membrane.inp`  
**参考结果**: `tests/data/reference/cooks_membrane_nafems.dat`

#### 验收标准

- **位移误差**: < 1%（相对于 NAFEMS 参考解）
- **与 ABAQUS 对比**: 相对误差 < 0.5%

---

### 1.4 Elastic Wave Propagation（弹性波传播）

**问题编号**: BENCHMARK_004  
**问题类型**: 动力学问题  
**难度**: ⭐⭐⭐ 高级

#### 问题描述

验证时间积分算法在弹性波传播问题中的精度和稳定性。

#### 几何定义

**尺寸**: L = 10 m（一维杆）

```
几何模型:
  ────────────────────
  L = 10 m
```

**网格**: 100 个 C3D8 单元（一维排列）

#### 材料参数

```fortran
E = 200.0e9_wp      ! 杨氏模量（Pa）
nu = 0.3_wp         ! 泊松比
density = 7850.0_wp ! 密度（kg/m³）
```

#### 边界条件

**初始条件**:

- 位移: u(x, 0) = 0
- 速度: v(x, 0) = 0

**边界条件**:

- 左端（x = 0）: u(0, t) = sin(ωt)（简谐激励）
- 右端（x = L）: 自由端

#### 参考解

**解析解**（一维波动方程）:

波速:

```
c = √(E/ρ) = √(200e9 / 7850) = 5048 m/s
```

位移解:

```
u(x, t) = sin(ω(t - x/c))
```

#### UFC 实现位置

**测试文件**: `tests/Numerical/test_wave_propagation.f90`  
**输入文件**: `tests/data/input/wave_propagation.inp`

#### 验收标准

- **位移误差**: < 1%（相对于解析解）
- **能量守恒**: 总能量误差 < 0.1%
- **数值稳定性**: 无振荡或发散

---

## 2. NAFEMS 标准问题

### 2.1 NAFEMS LE1（线性弹性，悬臂梁）

**问题编号**: BENCHMARK_NAFEMS_LE1  
**问题类型**: NAFEMS 标准问题  
**难度**: ⭐⭐ 中级

#### 问题描述

NAFEMS 线性弹性标准问题 LE1：悬臂梁受端部载荷。

#### 几何定义

**尺寸**: L = 6 m，h = 0.8 m，b = 0.2 m

#### 材料参数

```fortran
E = 200.0e9_wp
nu = 0.3_wp
```

#### 边界条件

- 固定端: x = 0
- 载荷: F = 1000 N（y方向，自由端）

#### 参考解

**NAFEMS 参考值**:

- 自由端挠度: δ = 0.1083 m

#### 验收标准

- **位移误差**: < 0.5%（相对于 NAFEMS 参考值）

---

### 2.2 NAFEMS LE10（线性弹性，厚壁圆筒）

**问题编号**: BENCHMARK_NAFEMS_LE10  
**问题类型**: NAFEMS 标准问题  
**难度**: ⭐⭐⭐ 高级

#### 问题描述

NAFEMS 线性弹性标准问题 LE10：厚壁圆筒受内压。

#### 几何定义

**尺寸**: 

- 内径: r_i = 0.1 m
- 外径: r_o = 0.2 m
- 长度: L = 0.4 m

#### 材料参数

```fortran
E = 200.0e9_wp
nu = 0.3_wp
```

#### 边界条件

- 内压: p = 10 MPa
- 外压: p = 0

#### 参考解

**解析解**（Lame 解）:

径向应力:

```
σ_r(r) = (r_i²p_i)/(r_o² - r_i²) × (1 - r_o²/r²)
```

切向应力:

```
σ_θ(r) = (r_i²p_i)/(r_o² - r_i²) × (1 + r_o²/r²)
```

**NAFEMS 参考值**:

- 内壁切向应力: σ_θ(r_i) = 16.67 MPa

#### 验收标准

- **应力误差**: < 1%（相对于解析解）

---

## 3. ABAQUS 验证手册问题

### 3.1 ABAQUS 1.1.1（简单拉伸）

**问题编号**: BENCHMARK_ABAQUS_1_1_1  
**问题类型**: ABAQUS 验证手册  
**难度**: ⭐ 基础

#### 问题描述

ABAQUS 验证手册 1.1.1：简单拉伸问题。

#### 几何定义

**尺寸**: L = 10 m，A = 1 m²（横截面积）

#### 材料参数

```fortran
E = 200.0e9_wp
nu = 0.3_wp
```

#### 边界条件

- 固定端: x = 0，u = 0
- 载荷: F = 1000 N（x方向，x = L）

#### 参考解

**解析解**:

- 位移: u(L) = FL/(EA) = 1000 × 10 / (200e9 × 1) = 5.0e-8 m
- 应力: σ = F/A = 1000 / 1 = 1000 Pa

#### 验收标准

- **位移误差**: < 0.1%（相对于解析解）
- **应力误差**: < 0.1%（相对于解析解）

---

## 4. 性能基准测试

### 4.1 大规模问题（100万自由度）

**问题编号**: BENCHMARK_PERF_001  
**问题类型**: 性能基准  
**难度**: ⭐⭐⭐ 高级

#### 问题描述

测试大规模问题的求解性能。

#### 几何定义

**网格**: 100×100×100 = 1,000,000 个 C3D8 单元  
**自由度**: 约 3,000,000 DOF

#### 性能指标


| 指标       | 目标值    | 测量方法     |
| -------- | ------ | -------- |
| **求解时间** | < 60 秒 | 单线程      |
| **内存使用** | < 8 GB | Valgrind |
| **并行效率** | > 70%  | 8 线程     |


#### UFC 实现位置

**测试文件**: `tests/Performance/test_large_scale.f90`

---

## 5. 测试数据管理

### 5.1 测试数据目录结构

```
tests/
├── data/
│   ├── input/                    # 输入文件
│   │   ├── patch_test.inp
│   │   ├── cantilever_beam.inp
│   │   ├── cooks_membrane.inp
│   │   └── ...
│   ├── reference/                # 参考结果
│   │   ├── abaqus/
│   │   │   ├── cantilever_beam.dat
│   │   │   └── cooks_membrane.dat
│   │   ├── nafems/
│   │   │   ├── le1.dat
│   │   │   └── le10.dat
│   │   └── analytical/
│   │       ├── patch_test.dat
│   │       └── wave_propagation.dat
│   └── mesh/                     # 网格文件
│       ├── unit_cube.msh
│       └── cantilever.msh
```

### 5.2 测试数据版本控制

**策略**: 使用 Git LFS 管理大文件

```bash
# .gitattributes
*.dat filter=lfs diff=lfs merge=lfs -text
*.msh filter=lfs diff=lfs merge=lfs -text
*.odb filter=lfs diff=lfs merge=lfs -text
```

### 5.3 参考结果格式

**标准格式**: CSV（逗号分隔值）

**示例**: `cantilever_beam_abaqus.dat`

```csv
# ABAQUS Reference Results - Cantilever Beam
# Node_ID, Displacement_X, Displacement_Y, Displacement_Z, Stress_XX, Stress_YY, Stress_ZZ
1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
2, 5.0e-8, -4.0e-2, 0.0, 0.0, 24.0e6, 0.0
...
```

---

## 附录

### A.1 测试问题索引


| 问题编号                   | 名称               | 类型    | 难度  | 状态     |
| ---------------------- | ---------------- | ----- | --- | ------ |
| BENCHMARK_001          | Patch Test       | 单元精度  | ⭐   | ✅ 已实现  |
| BENCHMARK_002          | Cantilever Beam  | 弯曲    | ⭐⭐  | ✅ 已实现  |
| BENCHMARK_003          | Cook's Membrane  | 弯曲+剪切 | ⭐⭐⭐ | 🟡 待实现 |
| BENCHMARK_004          | Wave Propagation | 动力学   | ⭐⭐⭐ | 🟡 待实现 |
| BENCHMARK_NAFEMS_LE1   | NAFEMS LE1       | 标准问题  | ⭐⭐  | 🟡 待实现 |
| BENCHMARK_NAFEMS_LE10  | NAFEMS LE10      | 标准问题  | ⭐⭐⭐ | 🟡 待实现 |
| BENCHMARK_ABAQUS_1_1_1 | ABAQUS 1.1.1     | 验证手册  | ⭐   | 🟡 待实现 |


### A.2 相关文档

- `UFC_TEST_STRATEGY.md` - 测试策略
- `UFC_TEST_CASE_TEMPLATE.md` - 测试用例模板
- `UFC_API_REFERENCE.md` - API 参考手册

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队