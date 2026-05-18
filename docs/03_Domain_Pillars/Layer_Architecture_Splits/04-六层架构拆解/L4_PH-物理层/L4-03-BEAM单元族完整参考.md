# L4-PH-Element-BEAM: BEAM 梁单元族完整参考

## 1. 概述

BEAM 梁单元族用于模拟细长结构的力学行为，支持 2D/3D、线性/非线性、热 - 力耦合等多种物理场。

### 1.1 单元分类体系

```
BEAM 梁单元族
├── 2D 梁 (平面问题)
│   ├── B21: 2 节点 Euler-Bernoulli (6 DOF)
│   ├── B21H: 2 节点混合公式 (待实现)
│   ├── B22: 3 节点二次插值 (9 DOF) ✅ 新增
│   ├── B22H: 3 节点混合公式 (待实现)
│   ├── B23: 2 节点 Timoshenko (6 DOF)
│   └── B21T: 2 节点热 - 力耦合 (8 DOF)
├── 3D 梁 (空间问题)
│   ├── B31: 2 节点 Euler-Bernoulli (12 DOF)
│   ├── B31H: 2 节点混合公式 (待实现)
│   ├── B31OS: 2 节点开口截面 (待实现)
│   ├── B32: 3 节点二次插值 (18 DOF) ✅ 新增
│   ├── B32H: 3 节点混合公式 (待实现)
│   ├── B32OS: 3 节点开口截面 (待实现)
│   ├── B33: 2 节点 Timoshenko (12 DOF)
│   └── B33 扩展系列
│       ├── B33NL: 几何非线性 (大转动)
│       ├── B33S: Timoshenko 剪切
│       ├── B33T: 热 - 力耦合
│       └── B33P: 塑性纤维积分
└── B31/B32 扩展系列
    ├── B31TNL: 大转动几何非线性 ✅ 新增
    ├── B31TS: Timoshenko 剪切变形 ✅ 新增
    ├── B31TP: 塑性纤维积分 ✅ 新增
    ├── B32NL: 3D 大转动 ✅ 新增
    ├── B32S: 3D Timoshenko 剪切 ✅ 新增
    ├── B32T: 3D 热 - 力耦合 ✅ 新增
    └── B32P: 3D 塑性纤维 ✅ 新增
```

### 1.2 命名规则


| 前缀  | 含义           | 节点数 | 维度  | DOF   |
| --- | ------------ | --- | --- | ----- |
| B2X | 2D Beam      | 2/3 | 2D  | 6/9   |
| B3X | 3D Beam      | 2/3 | 3D  | 12/18 |
| T   | Thermal      | -   | -   | +2/+3 |
| NL  | Nonlinear    | -   | -   | 相同    |
| S   | Shear        | -   | -   | 相同    |
| P   | Plastic      | -   | -   | 相同    |
| H   | Hybrid       | -   | -   | 相同    |
| OS  | Open Section | -   | -   | 相同    |


---

## 2. 单元详细规格

### 2.1 B21 - 2 节点 2D Euler-Bernoulli 梁

**文件**: `PH_Elem_B21_Core.f90`

**技术规格**:

- **DOF**: 6 (u_x, u_y, θ_z per node × 2)
- **形函数**: 线性插值
- **理论**: Euler-Bernoulli (忽略剪切变形)
- **应用**: 细长梁 (L/h > 10)

**核心接口**:

```fortran
CALL UF_Elem_B21_Calc(coords, E, nu, A, I, Ke, Rint, status)
```

**质量矩阵**:

- 一致质量：`M_cons = ρAL/420 * [...]`
- 集中质量：`M_lump = ρAL/2 * diag(1,1,0,1,1,0)`

---

### 2.2 B22 - 3 节点 2D 二次梁 ✅

**文件**: `PH_Elem_B22_Core.f90`

**技术规格**:

- **DOF**: 9 (u_x, u_y, θ_z per node × 3)
- **形函数**: 二次 Lagrange 插值
  - N1 = -ξ(1-ξ)/2 (角节点)
  - N2 = ξ(1+ξ)/2 (角节点)
  - N3 = (1-ξ²) (中点节点)
- **积分**: 2 点 Gauss
- **应用**: 弯曲主导问题，需要更高精度

**核心接口**:

```fortran
CALL UF_Elem_B22_Calc(coords, E, nu, A, I, Ke, Rint, status)
```

**刚度矩阵特性**:

- 尺寸：9×9
- 对称正定
- 包含轴向 + 弯曲耦合

---

### 2.3 B23 - 2 节点 2D Timoshenko 梁

**文件**: `PH_Elem_B23_Core.f90`

**技术规格**:

- **DOF**: 6 (u_x, u_y, θ_z per node × 2)
- **理论**: Timoshenko (包含横向剪切)
- **剪切修正因子**: k = 5/6 (矩形截面)
- **应用**: 中等厚度梁 (L/h ≈ 5-10)

---

### 2.4 B31 - 2 节点 3D Euler-Bernoulli 梁

**文件**: `PH_Elem_B31_Core.f90`

**技术规格**:

- **DOF**: 12 (u_x, u_y, u_z, θ_x, θ_y, θ_z per node × 2)
- **形函数**: 线性插值
- **理论**: Euler-Bernoulli 3D
- **应用**: 空间框架结构

---

### 2.5 B32 - 3 节点 3D 二次梁 ✅

**文件**: `PH_Elem_B32_Core.f90`

**技术规格**:

- **DOF**: 18 (6 DOF × 3 nodes)
- **形函数**: 二次 Lagrange (3D 扩展)
- **积分**: 3 点 Gauss (考虑扭转)
- **应用**: 复杂空间弯曲

---

### 2.6 B33 - 2 节点 3D Timoshenko 梁

**文件**: `PH_Elem_B33_Core.f90`

**技术规格**:

- **DOF**: 12 (6 DOF × 2 nodes)
- **理论**: Timoshenko 3D
- **剪切修正**: k_y = k_z = 5/6
- **应用**: 厚梁、复合材料梁

---

## 3. 高级扩展单元

### 3.1 B31T 系列 - 热 - 力耦合 ✅

#### B31T (标准)

- **DOF**: 14 (12 机械 + 2 温度)
- **耦合**: 轴向热膨胀 `ε_th = αΔT`
- **应用**: 热应力分析

#### B31TNL (大转动) ✅

- **DOF**: 14
- **理论**: Corotational formulation
- **切线刚度**: `K_t = K_mat + K_geo + K_corot`
- **应用**: 大转动热 - 机耦合

#### B31TS (剪切) ✅

- **DOF**: 14
- **理论**: Timoshenko + Thermal
- **应用**: 厚梁热应力

#### B31TP (塑性) ✅

- **DOF**: 14
- **理论**: Fiber discretization + J2 plasticity
- **应用**: 极限承载力分析

---

### 3.2 B32 系列 - 3 节点扩展 ✅

#### B32NL (大转动) ✅

- **DOF**: 18
- **理论**: 3D Corotational
- **应用**: 空间大变形

#### B32S (剪切) ✅

- **DOF**: 18
- **理论**: Timoshenko 3D (二次)
- **应用**: 厚梁高阶理论

#### B32T (热 - 力) ✅

- **DOF**: 21 (18 机械 + 3 温度)
- **耦合**: 3D 热膨胀
- **应用**: 空间热应力

#### B32P (塑性) ✅

- **DOF**: 18
- **理论**: 纤维模型 + 塑性
- **应用**: 非线性极限分析

---

## 4. 未来变体 (Phase 3+)

### 4.1 混合公式 (H 变体)

**待实现**: B21H, B22H, B31H, B32H

**特点**:

- 混合插值 (位移 + 应力独立插值)
- 避免剪切自锁
- 适用于极薄梁

### 4.2 开口截面 (OS 变体)

**待实现**: B31OS, B32OS

**特点**:

- 翘曲自由度 (7 DOF/node)
- Vlasov 薄壁杆件理论
- 约束扭转

### 4.3 管道梁 (Pipe 变体)

**待实现**: B31PIPE, B32PIPE

**特点**:

- 内外压载荷
- 环向应力
- 流固耦合

---

## 5. 统一接口调用

### 5.1 Dispatch 机制

```fortran
USE PH_Elem_Beam_Defn, ONLY: UF_Elem_Beam_Calc

CALL UF_Elem_Beam_Calc(ename, elem_type, formul, ctx, state_in, &
                       mat, state_out, flags)
```

**自动识别**:

- `'B21'` → B21 (6 DOF)
- `'B22'` → B22 (9 DOF)
- `'B31TNL'` → B31TNL (14 DOF)
- `'B32T'` → B32T (21 DOF)

### 5.2 输入参数规范

```fortran
TYPE(ElemCalcIn) :: in
  in%elem_type  ! 单元类型码
  in%formul     ! 公式选项
  in%ctx        ! 单元上下文 (坐标等)
  in%state_in   ! 输入状态
  in%mat        ! 材料参数

TYPE(ElemCalcOut) :: out
  out%state_out ! 输出状态 (内力等)
  out%flags     ! 状态标志
  out%status    ! 错误状态
```

---

## 6. 测试验证

### 6.1 单元测试套件

**文件**: `PH_Elem_BEAM_Tests.f90`

**测试覆盖**:

- ✅ B21/B22/B23 基本刚度
- ✅ B31/B32/B33 基本刚度
- ✅ B31T 热 - 力耦合
- ✅ B31TNL 几何非线性
- ✅ B31TS 剪切变形
- ✅ B32NL/B32S/B32T 扩展

### 6.2 运行测试

```fortran
PROGRAM Run_BEAM_Tests
  USE PH_Elem_BEAM_Tests, ONLY: Run_All_BEAM_Tests
  
  CALL Run_All_BEAM_Tests()
END PROGRAM
```

**预期输出**:

```
==============================================
BEAM Element Family - Comprehensive Test Suite
==============================================

--- B21 Basic Tests ---
  PASS: B21 stiffness formation

--- B22 Basic Tests ---
  PASS: B22 stiffness formation (9x9)

...

TEST SUMMARY
==============================================
  Total tests run:       16
  Tests passed:          16
  Tests failed:           0
  Success rate:         100.00 %
==============================================
```

---

## 7. 与商业软件对比

### 7.1 ABAQUS 对标


| UFC 单元 | ABAQUS 等效 | DOF | 理论                 |
| ------ | --------- | --- | ------------------ |
| B21    | B21       | 6   | Euler-Bernoulli    |
| B22    | B22       | 9   | Quadratic          |
| B23    | B23       | 6   | Timoshenko         |
| B31    | B31       | 12  | Euler-Bernoulli 3D |
| B32    | B32       | 18  | Quadratic 3D       |
| B33    | B33       | 12  | Timoshenko 3D      |
| B31T   | B31T      | 14  | Thermo-mechanical  |
| B31TNL | B31       | 14  | NLGEOM=YES         |


### 7.2 ANSYS 对标


| UFC 单元 | ANSYS 等效     | 备注               |
| ------ | ------------ | ---------------- |
| B21    | BEAM3        | 2D elastic       |
| B31    | BEAM4        | 3D elastic       |
| B31T   | LINK33+BEAM4 | Thermal-stress   |
| B31TNL | BEAM4+NLGEOM | Large deflection |


---

## 8. 实施状态总览


| 单元     | 核心实现 | 统一接口 | 测试  | 文档  | 状态       |
| ------ | ---- | ---- | --- | --- | -------- |
| B21    | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B22    | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B23    | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B31    | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B32    | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B33    | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B31T   | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B31TNL | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B31TS  | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B31TP  | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B32NL  | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B32S   | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B32T   | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B32P   | ✅    | ✅    | ✅   | ✅   | COMPLETE |
| B21H   | ❌    | ❌    | ❌   | ❌   | TODO     |
| B31OS  | ❌    | ❌    | ❌   | ❌   | TODO     |


---

## 9. 参考文献

1. Bathe, K.J. (2014). *Finite Element Procedures*. MIT Press.
2. Zienkiewicz, O.C. et al. (2005). *The Finite Element Method for Solid and Structural Mechanics*. Elsevier.
3. ABAQUS Analysis User's Manual. Dassault Systèmes.
4. ANSYS Mechanical APDL Theory Reference. ANSYS Inc.

---

**最后更新**: 2026-04-01  
**维护者**: UFC Core Team  
**版本**: v1.0