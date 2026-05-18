# Element域四链贯通设计文档

**层**: L3_MD / L4_PH / L5_RT  
**域**: Element (单元域)  
**状态**: v5.1 Draft  
**日期**: 2026-04-13  

---

## 1. 概述

单元域是UFC架构中**计算量最大**的核心域，负责将材料本构响应映射到离散空间，形成刚度/质量/阻尼矩阵与残力向量。本设计通过**四链贯通**实现从理论定义到运行时调度的端到端闭环。

---

## 2. 四链定义

### 2.1 理论链 (Theory Chain)

**路径**: ABAQUS手册 → UFC理论定义 → Fortran实现

| 层级 | 理论内容 | 文件 |
|------|---------|------|
| 外部参考 | ABAQUS Element Guide | 外部 |
| UFC映射 | MD_Elem_XXX_Desc 定义 | `L3_MD/Element/*/` |
| 实现 | PH_Elem_XXX_Core.f90 | `L4_PH/Element/*/` |

**贯通逻辑**:
```
ABAQUS C3D8定义
  → MD_Elem_Solid3D_Desc (n_ip_default=8, geom_kind=SOLID_3D)
    → PH_Elem_C3D8_Calc (B-bar公式实现)
      → RT_Elem_Kernel_Compute (L5调度)
```

### 2.2 逻辑链 (Logic Chain)

**路径**: Mesh引用 → Element绑定 → Assembly闭环

| 环节 | 职责 | 模块 |
|------|------|------|
| Mesh层 | nElem, conn(:,:), elem_type_id(:) | MD_Mesh_Types |
| 绑定 | elem_type_id → MD_Elem_Desc | MD_Elem_PH_Elem_Binding |
| 实例化 | PH_Elem_Ctx 数组分配 | L5_RT/Mesh |
| 计算 | Ke/Fe/Me/Ce | PH_Elem_Calc_Wrapper |
| 装配 | 全局K/F/M组装 | L5_RT/Assembly |

**数据流**:
```fortran
! L3: 注册
CALL MD_Element_RegisterSolid3D(status)

! L4: 绑定
bind_id = MD_Elem_GetBindingId(elem_type_id)
module_name = MD_Elem_GetPHModuleName(elem_type_id)

! L5: 调度
CALL RT_Elem_Compute_Ke(args, status)
```

### 2.3 计算链 (Computation Chain)

**路径**: 形函数 → 本构 → 数值积分 → 矩阵输出

```
高斯点循环 (nIP)
  ├─ 形函数 N(ξ) 与导数 dN/dX
  ├─ 应变-位移矩阵 B
  ├─ 本构矩阵 D (材料响应)
  ├─ 刚度贡献: Ke += B^T * D * B * detJ * w
  ├─ 残力贡献: Fe += B^T * σ * detJ * w
  └─ 质量贡献: Me += ρ * N^T * N * detJ * w (可选)
```

**实现映射**:
| 计算阶段 | L3_MD | L4_PH | L5_RT |
|---------|-------|-------|-------|
| 形函数 | MD_Elem_XXX_Desc%n_ip | PH_Elem_ShapeFunc | RT_Elem_IP_Loop |
| 本构 | MD_Material_XXX_Desc | PH_Mat_UMAT | RT_Material_Cache |
| 积分 | desc%ip_scheme | PH_Elem_GaussQuad | - |
| 矩阵输出 | - | PH_Elem_Calc_Wrapper | RT_Elem_Kernel_Proc |

### 2.4 数据链 (Data Chain)

**路径**: 注册 → 初始化 → 热路径计算 → 状态更新

```
L3_MD (冷路径)
  ├─ MD_Elem_XXX_Desc (只读)
  ├─ MD_Elem_XXX_StateInit (初始值)
  └─ MD_Elem_PH_Elem_Binding (绑定关系)
      ↓
L4_PH (热路径)
  ├─ PH_Elem_Desc (L3拷贝)
  ├─ PH_Elem_Ctx (积分点缓存)
  ├─ PH_Elem_State (Ke/Fe/Me/Ce输出)
  └─ PH_Elem_Algo (计算策略)
      ↓
L5_RT (运行时)
  ├─ RT_Elem_Ctx (网格实例)
  ├─ RT_Elem_State (全局DOF映射)
  └─ RT_Elem_Cache (内存池管理)
```

---

## 3. 12族单元矩阵特性

### 3.1 矩阵维度与计算类型

| 单元族 | nDOF范围 | Ke | Fe | Me | Ce | 特殊 |
|--------|----------|----|----|----|----|------|
| Solid3D | 24~300 | ✅ | ✅ | ✅ | ✅ | B-bar/选择积分 |
| Shell | 30~300 | ✅ | ✅ | ✅ | ✅ | 厚度方向积分 |
| Beam | 12~84 | ✅ | ✅ | ✅ | ✅ | Timoshenko/共旋 |
| Truss | 6~24 | ✅ | ✅ | ⚠️ | ⚠️ | 仅轴向 |
| Solid2D | 8~18 | ✅ | ✅ | ✅ | ✅ | 平面应变/应力 |
| Infinite | 可变 | ✅ | ✅ | ❌ | ❌ | 无限元映射 |
| Cohesive | 24~72 | ✅ | ✅ | ❌ | ❌ | 牵引-分离 |
| Spring | 2~6 | ✅ | ✅ | ❌ | ❌ | 零长度 |
| Dashpot | 2~6 | ❌ | ✅ | ❌ | ✅ | 仅阻尼 |
| Mass | 3~30 | ❌ | ❌ | ✅ | ❌ | 集中/一致质量 |
| Gasket | 16~48 | ✅ | ✅ | ❌ | ❌ | 垫片非线性 |
| Surface | 可变 | ❌ | ✅ | ❌ | ❌ | 表面载荷 |

### 3.2 矩阵计算路径选择

```fortran
SELECT CASE (calc_mode)
CASE (1)  ! 线性分析
  CALL PH_Elem_Calc_Ke_Linear(desc, ctx, args)
  CALL PH_Elem_Calc_Fe_Linear(desc, ctx, args)
CASE (2)  ! 非线性 Total Lagrangian
  CALL PH_Elem_Calc_Ke_NL_TL(desc, ctx, args)
  CALL PH_Elem_Calc_Fe_NL_TL(desc, ctx, args)
CASE (3)  ! 非线性 Updated Lagrangian
  CALL PH_Elem_Calc_Ke_NL_UL(desc, ctx, args)
  CALL PH_Elem_Calc_Fe_NL_UL(desc, ctx, args)
END SELECT
```

---

## 4. 关键接口设计

### 4.1 计算封装统一接口

```fortran
TYPE :: PH_Elem_Calc_Args
  ! 输入
  REAL(wp), ALLOCATABLE :: coords_ref(:,:)  ! 参考坐标
  REAL(wp), ALLOCATABLE :: disp(:,:)        ! 位移
  REAL(wp), ALLOCATABLE :: props(:)         ! 材料参数
  INTEGER(i4) :: calc_mode = 1_i4           ! 1=线性, 2=NL-TL, 3=NL-UL
  LOGICAL :: compute_stiffness = .TRUE.
  LOGICAL :: compute_force = .TRUE.
  LOGICAL :: compute_mass = .FALSE.
  LOGICAL :: compute_damping = .FALSE.
  LOGICAL :: nlgeom = .FALSE.
  REAL(wp) :: time = 0.0_wp
  REAL(wp) :: dTime = 1.0_wp
  
  ! 输出
  REAL(wp), ALLOCATABLE :: Ke(:,:)  ! 刚度矩阵
  REAL(wp), ALLOCATABLE :: Fe(:)    ! 残力向量
  REAL(wp), ALLOCATABLE :: Me(:,:)  ! 质量矩阵
  REAL(wp), ALLOCATABLE :: Ce(:,:)  ! 阻尼矩阵
  REAL(wp), ALLOCATABLE :: svars(:,:)  ! 状态变量
  REAL(wp) :: energy_internal = 0.0_wp
  REAL(wp) :: energy_kinetic = 0.0_wp
  REAL(wp) :: stable_dt = 0.0_wp
END TYPE
```

### 4.2 L3↔L4绑定路由

```fortran
! 通过elem_type_id获取L4模块
bind_id = MD_Elem_GetBindingId(elem_type_id)
module_name = MD_Elem_GetPHModuleName(elem_type_id)

! 校验兼容性
is_valid = MD_Elem_ValidateBinding(bind_id, module_name)

! 调用计算
CALL PH_Elem_Calc_All(desc, state, algo, ctx, args, status)
```

---

## 5. 内存管理策略

### 5.1 矩阵存储

| 层级 | 存储方式 | 说明 |
|------|---------|------|
| L3_MD | 静态Desc | 只读元数据 |
| L4_PH | 动态State | Ke/Fe/Me/Ce按需分配 |
| L5_RT | 内存池 | 大规模批量分配 |

### 5.2 积分点缓存

```fortran
TYPE :: PH_Elem_Ctx
  REAL(wp), ALLOCATABLE :: gauss_xi(:,:)    ! 高斯点坐标
  REAL(wp), ALLOCATABLE :: gauss_w(:)       ! 高斯权重
  REAL(wp), ALLOCATABLE :: det_J(:)         ! Jacobian行列式
  REAL(wp), ALLOCATABLE :: shape_N(:,:)     ! 形函数
  REAL(wp), ALLOCATABLE :: shape_dN(:,:,:)  ! 形函数导数
  REAL(wp), ALLOCATABLE :: B_matrix(:,:,:)  ! 应变矩阵
  REAL(wp), ALLOCATABLE :: stress_ip(:,:)   ! 积分点应力
  REAL(wp), ALLOCATABLE :: strain_ip(:,:)   ! 积分点应变
END TYPE
```

---

## 6. 错误处理

### 6.1 计算错误分类

| 错误类型 | 代码 | 处理策略 |
|---------|------|---------|
| 负Jacobian | ERR_NEG_JAC | 建议缩减时间步 |
| 材料失效 | ERR_MAT_FAIL | 标记单元删除 |
| 数值奇异 | ERR_SINGULAR | 添加数值阻尼 |
| 内存不足 | ERR_OOM | 触发内存回收 |

### 6.2 状态传播

```fortran
TYPE :: PH_Elem_State
  LOGICAL :: failed = .FALSE.
  LOGICAL :: suggest_cutback = .FALSE.
  LOGICAL :: requires_reasse = .TRUE.
  REAL(wp) :: stable_dt = 0.0_wp
  TYPE(ErrorStatusType) :: status
END TYPE
```

---

## 7. 性能优化

### 7.1 热路径优化

- **向量化**: 积分点循环使用SIMD指令
- **缓存友好**: 连续内存访问模式
- **避免分支**: calc_mode在调用前确定

### 7.2 矩阵存储优化

| 矩阵 | 对称性 | 存储策略 |
|------|--------|---------|
| Ke (弹性) | 对称 | 上三角打包 |
| Ke (几何) | 对称 | 上三角打包 |
| Me (一致) | 对称 | 上三角打包 |
| Me (集中) | 对角 | 一维数组 |
| Ce (Rayleigh) | 对称 | 由M/K组合 |

---

## 8. 验证策略

### 8.1 Patch Test

| 测试 | 单元族 | 预期 |
|------|--------|------|
| 常应变 | Solid3D | 精确解 |
| 常曲率 | Shell | 精确解 |
| 常轴力 | Beam/Truss | 精确解 |

### 8.2 基准测试

- **NAFEMS**: 标准验证案例
- **ABAQUS对比**: 相同模型结果对比
- **收敛性**: h-refinement收敛率

---

## 9. 文件清单

### L3_MD层 (16文件)
```
L3_MD/Element/
├── MD_Element_Core.f90              # 总控
├── MD_Elem_Types.f90                # 四大类TYPE
├── MD_Elem_PH_Elem_Binding.f90      # L3↔L4绑定
├── Solid3D/MD_Elem_Solid3D_Core.f90
├── Shell/MD_Elem_Shell_Core.f90
├── Beam/MD_Elem_Beam_Core.f90
├── Truss/MD_Elem_Truss_Core.f90
├── Solid2D/MD_Elem_Solid2D_Core.f90
├── Infinite/MD_Elem_Infinite_Core.f90
├── Cohesive/MD_Elem_Cohesive_Core.f90
├── Spring/MD_Elem_Spring_Core.f90
├── Dashpot/MD_Elem_Dashpot_Core.f90
├── Mass/MD_Elem_Mass_Core.f90
├── Gasket/MD_Elem_Gasket_Core.f90
├── Surface/MD_Elem_Surface_Core.f90
└── Element/MD_Elem_Calc_Types.f90   # 计算TYPE定义
```

### L4_PH层 (核心文件)
```
L4_PH/Element/
├── PH_Elem_Types.f90                # 四大类TYPE
├── PH_Elem_Calc_Wrapper.f90         # 计算封装
├── PH_Element_Domain_Core.f90       # 域总控
├── SLD3D/PH_Elem_C3D8_Core.f90
├── SHELL/PH_Elem_S4_Core.f90
├── BEAM/PH_Elem_B31_Core.f90
└── ... (12族对应模块)
```

---

## 10. 附录

### 10.1 动力学方程

```
M·ü + C·u̇ + K·u = F

其中:
  M = Σ Me  (全局质量矩阵)
  C = Σ Ce  (全局阻尼矩阵)
  K = Σ Ke  (全局刚度矩阵)
  F = Σ Fe  (全局残力向量)
```

### 10.2 符号约定

| 符号 | 含义 | 维度 |
|------|------|------|
| Ke | 单元刚度矩阵 | nDOF×nDOF |
| Fe | 单元残力向量 | nDOF |
| Me | 单元质量矩阵 | nDOF×nDOF |
| Ce | 单元阻尼矩阵 | nDOF×nDOF |
| nNode | 单元节点数 | - |
| nDim | 空间维度 | - |
| nDOF | 单元自由度 = nNode×nDim | - |
| nIP | 积分点数 | - |

---

**文档维护**: 随L3_MD/L4_PH/L5_RT代码同步更新  
**下次审查**: 编译验证后更新状态至v5.1 Release
