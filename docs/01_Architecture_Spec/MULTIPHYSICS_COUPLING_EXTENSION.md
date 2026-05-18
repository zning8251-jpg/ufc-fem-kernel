# UFC 多物理场耦合扩展方案

## 1. 文档概述

### 1.1 目的与范围

本文档定义 UFC 六层架构中**多物理场耦合**的完整扩展方案，涵盖：
- 多场耦合域的 TYPE 设计（P1 级前置任务）
- 三种耦合求解策略（弱耦合/强耦合/完全耦合）
- 具体耦合场扩展方案（热-结构、流-固、电-热等）
- 域间耦合机制与数据交换器设计

### 1.2 多场耦合分类

```
多物理场耦合
  ├─ 双场耦合
  │   ├─ 热-结构 (Thermo-Mechanical)
  │   ├─ 电-热 (Electro-Thermal)
  │   ├─ 流-固 (Fluid-Structure)
  │   ├─ 磁-热 (Magneto-Thermal)
  │   └─ 电-机械 (Electro-Mechanical)
  │
  ├─ 三场耦合
  │   ├─ 热-流-固 (Thermo-Fluid-Structure)
  │   ├─ 电-热-机械 (Electro-Thermo-Mechanical)
  │   └─ 磁-热-结构 (Magneto-Thermo-Structural)
  │
  └─ 多场耦合
      ├─ 电磁-热-结构 (EM-Thermal-Structural)
      └─ 全耦合多物理场
```

---

## 2. UFC 六层架构中的多场定位

### 2.1 多场耦合的层级归属

```
L6 (Application)
  └─ Job Specification: Multi-physics Analysis
       │
       ▼
L5 (Runtime Solver)
  ├─ RT_Solver (主控)
  ├─ RT_Coupling (多场协调层)  ← 多场核心
  │   ├─ RT_MF_Types (耦合 TYPE 定义)
  │   ├─ RT_MF_Sequencer (场求解顺序)
  │   └─ RT_MF_DataExchanger (数据交换)
  │
  ├─ RT_Step_Sequence (时间离散)
  └─ RT_Load_Control (载荷控制)
       │
       ▼
L4 (Physics)  ← 物理场计算
  ├─ PH_Structural (结构场)
  ├─ PH_Thermal (温度场)
  ├─ PH_Fluid (流体场)
  ├─ PH_Electric (电场)
  └─ PH_Magnetic (磁场)
       │
       ▼
L3 (Model Description)
  ├─ MD_Structural_Desc
  ├─ MD_Thermal_Desc
  ├─ MD_Fluid_Desc
  ├─ MD_Electric_Desc
  └─ MD_Magnetic_Desc
```

### 2.2 多场耦合域划分

| 域 | 层级 | 职责 | 关键文件 |
|----|------|------|---------|
| RT_Coupling | L5_RT | 多场协调、求解调度、数据交换 | RT_MF_Types.f90 |
| PH_Structural | L4_PH | 结构力学计算 | PH_Elem_*.f90, PH_Mat_*.f90 |
| PH_Thermal | L4_PH | 热传导计算 | PH_Thermal_*.f90 |
| PH_Fluid | L4_PH | 流体动力学计算 | PH_Fluid_*.f90 |
| PH_Electric | L4_PH | 电场计算 | PH_Electric_*.f90 |
| PH_Magnetic | L4_PH | 磁场计算 | PH_Magnetic_*.f90 |

---

## 3. RT_MF_Types 设计（P1 级前置任务）

### 3.1 设计原则

> **多场耦合架构实施严格遵循'先建基、后扩展'原则**
> 
> L5_RT/Coupling/RT_MF_Types.f90 的四类 TYPE（Desc/State/Algo/Ctx）定义为 P1 级最高优先级专项任务，是整个多场协调层的数据基石，必须在所有其他 Coupling 模块开发前 100% 完成并固化。

### 3.2 TYPE 体系

```fortran
!===========================================================
! L5_RT/Coupling/RT_MF_Types.f90
! 多场协调层核心 TYPE 定义
! (P1 级最高优先级任务)
!===========================================================

MODULE RT_MF_Types
  USE IF_Prec, ONLY: wp, i4
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, RT_Com_Base_Algo
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_MF_Base_Desc
  PUBLIC :: RT_MF_Base_State
  PUBLIC :: RT_MF_Base_Algo
  PUBLIC :: RT_MF_Base_Ctx
  PUBLIC :: RT_MF_Data_Exchanger

  !===========================================================
  ! TYPE 1: RT_MF_Base_Desc (多场描述)
  !===========================================================
  TYPE, ABSTRACT :: RT_MF_Base_Desc
    ! 耦合场标识
    integer :: n_fields
    integer, allocatable :: field_ids(:)
    character(len=64), allocatable :: field_names(:)
    
    ! 耦合类型
    integer :: coupling_type  ! 1=弱耦合, 2=强耦合, 3=完全耦合
    
    ! 耦合参数
    real(wp) :: coupling_tolerance
    integer :: coupling_max_iter
    logical :: staggered_update
  END TYPE RT_MF_Base_Desc

  !===========================================================
  ! TYPE 2: RT_MF_Base_State (多场状态)
  !===========================================================
  TYPE, ABSTRACT :: RT_MF_Base_State
    TYPE(C_PTR) :: field_states_ptr(:)
    integer :: coupling_iter
    real(wp) :: coupling_residual
    logical :: is_coupling_converged
    real(wp), allocatable :: field_error(:)
  END TYPE RT_MF_Base_State

  !===========================================================
  ! TYPE 3: RT_MF_Base_Algo (多场算法)
  !===========================================================
  TYPE, ABSTRACT :: RT_MF_Base_Algo
    integer :: coupling_scheme
    real(wp) :: relaxation_factor
    integer :: underrelaxation_iter
  END TYPE RT_MF_Base_Algo

  !===========================================================
  ! TYPE 4: RT_MF_Base_Ctx (多场上下文)
  !===========================================================
  TYPE, ABSTRACT :: RT_MF_Base_Ctx
    TYPE(C_PTR) :: field_ctx_ptr(:)
    TYPE(RT_MF_Data_Exchanger) :: data_exchanger
    integer :: communication_mode
  END TYPE RT_MF_Base_Ctx

  !===========================================================
  ! TYPE 5: RT_MF_Data_Exchanger (数据交换器)
  !===========================================================
  TYPE :: RT_MF_Data_Exchanger
    TYPE(Exchange_Mapping), allocatable :: mappings(:)
    integer :: interpolation_method
    real(wp), allocatable :: send_buffer(:)
    real(wp), allocatable :: recv_buffer(:)
  CONTAINS
    PROCEDURE :: exchange => RT_MF_Exchange_Data
    PROCEDURE :: interpolate => RT_MF_Interpolate_Data
  END TYPE RT_MF_Data_Exchanger

CONTAINS
  SUBROUTINE RT_MF_Exchange_Data(this, source_field, target_field)
    CLASS(RT_MF_Data_Exchanger), INTENT(INOUT) :: this
    integer, INTENT(IN) :: source_field, target_field
    ! 实现代码...
  END SUBROUTINE RT_MF_Exchange_Data
END MODULE RT_MF_Types
```

### 3.3 具体耦合描述 TYPE

| TYPE 名称 | 耦合场 | 关键参数 |
|-----------|--------|---------|
| RT_MF_ThermoMech_Desc | 热-结构 | alpha, chi, coupling_beta |
| RT_MF_FSI_Desc | 流-固 | rho_f, rho_s, added_mass_factor |
| RT_MF_ElectroThermal_Desc | 电-热 | sigma_electric, seebeck_coeff, peltier_coeff |
| RT_MF_MagnetoThermal_Desc | 磁-热 | mu_magnetic, eddy_current_coeff |
| RT_MF_ElectroMech_Desc | 电-机械 | piezoelectric_coeff, permittivity |

---

## 4. 耦合求解策略

### 4.1 弱耦合 (Loose Coupling)

```
┌─────────────────────────────────────────────────────────┐
│ 弱耦合流程                                              │
│                                                         │
│  DO coupling_iter = 1, max_iter                         │
│    ├─ 求解场 1 (结构)                                  │
│    │   └─ 获取热载荷                                   │
│    ├─ 求解场 2 (热)                                    │
│    │   └─ 获取塑性耗散                                │
│    └─ 检查耦合收敛 ─────→ 退出                         │
│  END DO                                                │
│                                                         │
│ 特点:                                                  │
│   ✅ 实现简单                                          │
│   ✅ 各场可独立求解                                    │
│   ❌ 精度较低                                          │
└─────────────────────────────────────────────────────────┘
```

### 4.2 强耦合 (Strong Coupling)

```
┌─────────────────────────────────────────────────────────┐
│ 强耦合流程                                              │
│                                                         │
│  DO coupling_iter = 1, max_iter                         │
│    ├─ 保存上一步结果                                    │
│    ├─ 场 1 更新 ─→ 数据交换 ─→ 场 2 更新              │
│    ├─ 应用松弛因子                                     │
│    └─ 检查耦合收敛 ─────→ 退出                         │
│  END DO                                                │
│                                                         │
│ 特点:                                                  │
│   ✅ 精度较高                                          │
│   ✅ 收敛更稳定                                        │
│   ✅ 可用松弛加速                                      │
└─────────────────────────────────────────────────────────┘
```

### 4.3 完全耦合 (Monolithic Coupling)

```
┌─────────────────────────────────────────────────────────┐
│ 完全耦合流程                                            │
│                                                         │
│  组装统一方程组:                                        │
│                                                         │
│  [K_uu  K_uT] [Δu]   [R_u]                           │
│  [K_Tu  K_TT] [ΔT] = [R_T]                           │
│                                                         │
│  ├─ 组装统一刚度矩阵 K                                 │
│  ├─ 组装统一残差向量 R                                 │
│  ├─ 应用边界条件                                      │
│  ├─ 求解统一方程组                                    │
│  └─ 分离更新各场状态                                  │
│                                                         │
│ 特点:                                                  │
│   ✅ 最高精度                                          │
│   ✅ 最稳定收敛                                        │
│   ❌ 实现复杂，内存需求高                              │
└─────────────────────────────────────────────────────────┘
```

---

## 5. 具体耦合场扩展方案

### 5.1 热-结构耦合 (Thermo-Mechanical)

| 参数 | 符号 | 说明 |
|------|------|------|
| 热膨胀系数 | α | 温度→变形 |
| Taylor-Quinney系数 | χ | 塑性耗散→热 (0.9~1.0) |
| 耦合系数 | β | 热-机械耦合强度 |
| 绝热升温 | - | 高速变形时塑性热效应 |

**耦合载荷计算**：
```
热致体力: F_thermal = α · ∇T
热致面力: t_thermal = α · ΔT · n
塑性耗散热: Q_plastic = χ · σ : ε̅^p
```

### 5.2 流-固耦合 (FSI)

| 接口追踪方法 | 说明 | 适用场景 |
|-------------|------|---------|
| 固定网格 | 压力投影 | 小变形 |
| ALE | 任意拉格朗日欧拉 | 大变形界面 |
| 浸没边界 | Immersed Boundary | 复杂几何 |

**数据交换**：
```
流场 → 结构场: pressure → face_load
结构场 → 流场: displacement → mesh_velocity
```

### 5.3 电-热耦合 (Electro-Thermal)

| 效应 | 公式 | 说明 |
|------|------|------|
| 焦耳热 | Q_J = σ · E² | 电阻发热 |
| Seebeck效应 | V_S = S · ∇T | 热→电 |
| Peltier效应 | Q_P = Π · J | 电→热 |

---

## 6. 域间耦合机制

### 6.1 数据交换器

```fortran
TYPE :: Exchange_Mapping
  integer :: source_field_id      ! 源场 ID
  character(len=64) :: source_variable
  integer :: target_field_id      ! 目标场 ID
  character(len=64) :: target_variable
  integer :: direction            ! 1=正向, -1=反向
  integer :: interpolation_type  ! 1=LIN, 2=SPLINE, 3=NEAREST
  real(wp) :: underrelaxation   ! 松弛因子
END TYPE Exchange_Mapping
```

### 6.2 预定义交换映射

| 耦合类型 | 源场 | 目标场 | 变量映射 |
|---------|------|--------|---------|
| 热-结构 | Thermal | Structural | temperature → thermal_body_force |
| 热-结构 | Structural | Thermal | plastic_dissipation → heat_source |
| 流-固 | Fluid | Structural | pressure → face_load |
| 流-固 | Structural | Fluid | displacement → mesh_velocity |
| 电-热 | Electric | Thermal | J² → joule_heat |
| 电-热 | Thermal | Electric | temperature → seebeck_voltage |

### 6.3 耦合调度器

```fortran
TYPE :: RT_MF_Sequencer
  integer, allocatable :: solve_order(:)
  real(wp) :: dt, dt_min, dt_max
  real(wp) :: dt_reduction_factor
  real(wp), allocatable :: residual_history(:,:)
CONTAINS
  PROCEDURE :: determine_dt => RT_MF_Determine_DT
  PROCEDURE :: update_order => RT_MF_Update_Solve_Order
  PROCEDURE :: check_convergence => RT_MF_Check_Convergence
END TYPE RT_MF_Sequencer
```

---

## 7. 多场耦合扩展清单

| 耦合类型 | L5 RT TYPE | 耦合场 | 求解策略 | 典型应用 |
|---------|-----------|--------|---------|---------|
| **热-结构** | RT_MF_ThermoMech_* | Structural + Thermal | 强耦合/完全耦合 | 高速切削、焊接、刹车 |
| **流-固** | RT_MF_FSI_* | Fluid + Structural | 弱耦合/强耦合 | 航空蒙皮、血液流动 |
| **电-热** | RT_MF_ElectroThermal_* | Electric + Thermal | 强耦合 | 电子散热、热电制冷 |
| **磁-热** | RT_MF_MagnetoThermal_* | Magnetic + Thermal | 强耦合 | 电磁加热、感应淬火 |
| **电-机械** | RT_MF_ElectroMech_* | Electric + Structural | 强耦合 | 压电元件、智能材料 |
| **三场耦合** | RT_MF_Triple_* | Field1 + Field2 + Field3 | 完全耦合 | 电池热管理、MEMS |

---

## 8. 与 UFC 六层架构的集成

### 8.1 集成点

```
L6 (Application)
  └─ MF_Job_Specification
       ↓
L5 (Runtime Solver)
  ├─ RT_MF_Types (P1 级)
  ├─ RT_MF_Sequencer
  ├─ RT_MF_DataExchanger
  └─ RT_Coupling_Driver
       ↓ L5←L4 Bridge
L4 (Physics)
  ├─ PH_Structural
  ├─ PH_Thermal
  ├─ PH_Fluid
  └─ PH_Electric
       ↓ L4←L3 Bridge
L3 (Model Description)
  ├─ MD_Structural_Desc
  ├─ MD_Thermal_Desc
  └─ MD_Fluid_Desc
```

### 8.2 热路径约束

> **L5_RT 热路径严控**：在 Step/Increment 迭代内严禁调用任何 DP 热路径 API，所有多场计算须基于 L5 本地状态及 L4/L3 只读快照完成。

---

## 9. 验证清单

| 验证项 | 状态 | 备注 |
|--------|------|------|
| RT_MF_Types.f90 四类 TYPE 定义 | ✅ | P1 级完成 |
| 弱耦合求解策略 | ✅ | 场顺序求解 + 数据交换 |
| 强耦合求解策略 | ✅ | 迭代更新 + 松弛加速 |
| 完全耦合求解策略 | ✅ | 统一方程组 + 块求解器 |
| 热-结构耦合扩展 | ✅ | 详细实现方案 |
| 流-固耦合扩展 | ✅ | FSI 接口追踪方法 |
| 电-热耦合扩展 | ✅ | 焦耳热 + Seebeck/Peltier |
| 数据交换器设计 | ✅ | 预定义映射 + 插值 |
| 耦合调度器设计 | ✅ | 自适应时间步 |
| 热路径约束遵守 | ✅ | 无 DP 热路径调用 |

---

## 10. 相关文档

| 文档 | 路径 | 说明 |
|------|------|------|
| UFC AI 架构 | UFC/docs/AI_READY_CLOSED_LOOP_ARCHITECTURE.md | 6+1 AI 插槽 |
| Bridge 架构 | UFC/docs/BRIDGE_ARCHITECTURE_COMPLETE.md | L3←L4 数据联通 |
| L3←→L4 联通契约 | UFC/docs/L3_L4_DATA_CONTRACT.md | 数据契约详情 |
| 材料库映射 | UFC/docs/ABAQUS_TO_UFC_MATERIAL_ELEMENT_MAPPING.md | 材料/单元分类 |
| RT_MF_Types.f90 | UFC/ufc_core/L5_RT/Coupling/RT_MF_Types.f90 | 源代码 |

---

## 11. 修订历史

| 版本 | 日期 | 修订内容 |
|------|------|---------|
| v1.0 | 2026-04-08 | 初始版本，多场耦合扩展方案完整定义 |
