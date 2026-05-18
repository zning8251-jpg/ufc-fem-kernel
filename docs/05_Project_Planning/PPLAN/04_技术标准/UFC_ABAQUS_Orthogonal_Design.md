# UFC-ABAQUS 正交架构对接技术文档

> **版本**: v1.0  
> **状态**: 技术讨论稿  
> **创建日期**: 2026-04-04  
> **目标**: 以 ABAQUS 为蓝本，完整解析其四维正交设计，将 ABAQUS 无缝嵌入 UFC 内核

---

## 1. 引言：为什么需要正交设计

### 1.1 有限元框架的核心挑战

传统有限元框架面临的核心问题是 **组合爆炸**：

```
问题规模 = O(求解器) × O(分析步) × O(单元) × O(材料)
        = 9 × 30 × 50 × 100+
        = 1,350,000+ 理论组合
```


| 维度   | 典型数量   | ABAQUS 实际支持                       |
| ---- | ------ | --------------------------------- |
| 求解器  | 5 种    | Standard/Explicit/CFD/EM/Acoustic |
| 分析步  | 30+ 种  | STATIC/DYNAMIC/HEAT/COUPLED 等     |
| 单元家族 | 50+ 种  | C3D/S4/S8R/B31 等                  |
| 材料模型 | 100+ 种 | Elastic/Plastic/Hyperelastic 等    |


**关键洞察**：尽管理论组合数巨大，但可用组合受物理约束限制，实际有效组合远小于理论值。

### 1.2 ABAQUS 的正交设计智慧

ABAQUS 经过数十年发展，演化出一套 **隐式正交设计**：

```
┌─────────────────────────────────────────────────────────────┐
│                    ABAQUS 架构分层                           │
├─────────────────────────────────────────────────────────────┤
│  用户层：*STEP, *MATERIAL, *ELEMENT, *BOUNDARY            │
│                                                             │
│  求解器层：Standard / Explicit / CFD                        │
│    ↓           ↓           ↓                               │
│  分析步层：PROC_*    PROC_*     PROC_*                      │
│    ↓           ↓           ↓                               │
│  单元层：Element Family（自动选择）                          │
│    ↓           ↓           ↓                               │
│  材料层：UMAT/VUMAT/UEL/VUEL（自动路由）                   │
└─────────────────────────────────────────────────────────────┘
```

**ABAQUS 的核心策略**：

1. **自动组合路由**：根据用户输入自动选择正确的求解器-分析步-单元-材料组合
2. **禁止矩阵预定义**：明确定义非法组合，在输入阶段拒绝
3. **统一的用户接口**：用户只需指定分析步和材料，底层自动完成路由

### 1.3 UFC 的设计目标

将 ABAQUS 的正交设计智慧 **显式化**、**规范化**、**可编程化**：

```fortran
! UFC 显式正交路由（对比 ABAQUS 的隐式路由）
CALL RT_SD_Router(ctx, &
  D1_solver  = RT_SOLVER_IMPLICIT, &
  D2_proc    = PROC_STATIC, &
  D3_elem    = ELMTYPE_SLD, &
  D4_phys    = PHYSYTYPE_ELASTIC)
```

---

## 2. 新增：物理场维度分组（第二层分类）

### 2.0 核心洞察

在 **第一层正交设计**（时间×方法→分析步×12种）基础上，新增 **第二层分组**（按物理场特性）：

```
分析类型 = 分析步（12种）+ 物理场分组（9组）
        = 33 种用户可见分析类型（不含 UMAT 参数化）
```

**第二层的价值**：

- 指导 L4_PH 材料调用链（哪些材料族允许？）
- 约束 L5_RT 单元选择（哪些单元兼容？）
- 驱动求解策略（耦合/单向/强/弱？）

### 2.0.1 ABAQUS 分析类型总量统计

```
┌─────────────────────────────────────────────────┐
│  ABAQUS 官方分析类型 = 33 种                     │
├─────────────────────────────────────────────────┤
│  结构单场      9 种  （G1）                      │
│  纯热         1 种  （G2）                      │
│  频域         4 种  （G3）                      │
│  声学         1 种  （G4）                      │
│  电磁         1 种  （G5）                      │
│  热-结构双场   2 种  （G6）                      │
│  多场耦合      3 种  （G7）                      │
│  岩土土力学    2 种  （G8）                      │
│  其他特殊      5 种  （G9）                      │
└─────────────────────────────────────────────────┘
```

### 2.0.2 物理场分组的决策树

```
ABQAUS 分析类型 (proc_id)
  ↓
  ├─→ 涉及结构/位移 DOF?
  │    ├─ YES → 与其他场耦合?
  │    │          ├─ NO → G1（结构单场）
  │    │          ├─ YES (T) → G6（热-力）
  │    │          └─ YES (T,E) → G7（多场）
  │    └─ NO → 涉及热/电/声?
  │            ├─ T only → G2（纯热）
  │            ├─ E only → G5（电磁）
  │            ├─ A only → G4（声学）
  │            └─ T+E or more → G7（多场）
  └─→ 特殊情况?
       ├─ 岩土相关 → G8
       ├─ 频域谱分析 → G3
       └─ 蠕变/扩散等 → G9
```

### 2.0.3 跨越第一层到第二层的映射


| 第一层维度                | 组合数 | 第二层物理场 | 分组数 | 具体分析类型    |
| -------------------- | --- | ------ | --- | --------- |
| Time×Method          | 12  | 结构力学   | 1   | 9个PROC_*  |
| (STATIC×IMPLICIT)    | 1   | 热传导    | 1   | 1个PROC_*  |
| (TRANSIENT×IMPLICIT) | 1   | 多场耦合   | 3   | 3个PROC_*  |
| (TRANSIENT×EXPLICIT) | 1   | 频域分析   | 4   | 4个PROC_*  |
| （其他）                 | 8   | 特殊域    | -   | 11个PROC_* |


**关键发现**：33 = 9(G1) + 1(G2) + 4(G3) + 1(G4) + 1(G5) + 2(G6) + 3(G7) + 2(G8) + 5(G9)

### 2.0.4 材料族与物理场分组的对应表

```
物理场分组  允许的材料族        禁止的材料族      典型调用
───────────────────────────────────────────────────
G1-结构    01-08(力学)        09-11           L4_Mat_Mechanics()
G2-纯热    09(热)            01-08,10-11     L4_Mat_Thermal()
G3-频域    01(弹性+阻尼)       其他            L4_Mat_Stiffness_Damping()
G4-声学    族特定(声阻抗)      力学材料         L4_Mat_Acoustic()
G5-电磁    族特定(导电率)      力学材料         L4_Mat_Electromagnetic()
G6-热力    01-08+09(热膨胀)    10-11           L4_Mat_Mechanics + Thermal()
G7-多场    01-08+电磁+热      不兼容组合        L4_Mat_Coupled_TES()
G8-岩土    03(岩土塑性)       标准材料         L4_Mat_Geotechnical()
G9-其他    视具体分析         视具体分析        L4_Mat_Special_Dispatch()
```

### 2.0.5 参考文档

**新增配套文档**：`[UFC_Analysis_GroupedClassification_ByPhysicalField.md](./UFC_Analysis_GroupedClassification_ByPhysicalField.md)`

- G1-G9 详细分类
- 单元约束矩阵（表 4.2）
- 材料调用决策表（表 4.1）
- 实施建议和代码改造方案

---

## 3. ABAQUS 架构深度解析

### 3.1 求解器类型（Solver Engine）

ABAQUS 拥有三大独立求解器，**完全正交隔离**：

```
┌─────────────────────────────────────────────────────────────┐
│                    ABAQUS 求解器体系                          │
├─────────────────────────────────────────────────────────────┤
│  Abaqus/Standard    │ Abaqus/Explicit  │ Abaqus/CFD        │
│  ─────────────────  │ ────────────────  │ ────────────────  │
│  隐式积分           │ 显式中心差分       │ 有限体积法         │
│  UMAT/UEL          │ VUMAT/VUEL        │ 原生 CFD          │
│  非线性收敛         │ 无需收敛           │ 压力速度耦合       │
│  适合静态/准静态    │ 适合冲击/动态      │ 流体仿真           │
└─────────────────────────────────────────────────────────────┘
```

#### 3.1.1 Standard vs Explicit 对比矩阵


| 特征   | Abaqus/Standard   | Abaqus/Explicit      |
| ---- | ----------------- | -------------------- |
| 积分方法 | 隐式 Newmark        | 显式中心差分               |
| 收敛性  | 需要牛顿迭代收敛          | 无需收敛                 |
| 时间步  | 无限制（自动控制）         | 受 CFL 条件限制           |
| 材料接口 | UMAT, UEL, HETVAL | VUMAT, VUEL, VHETVAL |
| 热边界  | FILM, DFLUX       | VFILM, VDFLUX        |
| 接触算法 | 罚函数/拉格朗日          | 通用接触/侵蚀              |
| 适用场景 | 静态/准静态/非线性        | 冲击/高速/短暂事件           |


#### 3.1.2 UFC 求解器枚举（对应 ABAQUS）

```fortran
! RT_SolverType — UFC 求解器类型枚举
! 与 ABAQUS 一一对应
INTEGER(i4), PARAMETER :: RT_SOLVER_UNKNOWN    = 0_i4  ! 未初始化
INTEGER(i4), PARAMETER :: RT_SOLVER_IMPLICIT  = 1_i4  ! Abaqus/Standard
INTEGER(i4), PARAMETER :: RT_SOLVER_EXPLICIT  = 2_i4  ! Abaqus/Explicit
INTEGER(i4), PARAMETER :: RT_SOLVER_CFD       = 3_i4  ! Abaqus/CFD
INTEGER(i4), PARAMETER :: RT_SOLVER_EMF       = 4_i4  ! Abaqus/EM (Electromagnetic)
INTEGER(i4), PARAMETER :: RT_SOLVER_THERMAL   = 5_i4  ! Abaqus/Standard (热专用)
INTEGER(i4), PARAMETER :: RT_SOLVER_PMF       = 6_i4  ! Poromechanics (渗流)
INTEGER(i4), PARAMETER :: RT_SOLVER_DIF       = 7_i4  ! Diffusion (扩散)
INTEGER(i4), PARAMETER :: RT_SOLVER_CPL       = 8_i4  ! 多场耦合 (COUPLED_*)
```

### 3.2 分析步类型（Procedure Type）

ABAQUS 的分析步类型是 **第二维正交**，与求解器类型存在映射关系：

```
┌─────────────────────────────────────────────────────────────┐
│                    ABAQUS 分析步分类                          │
├─────────────────────────────────────────────────────────────┤
│  General (通用)    │ Linear Perturbation │ Complex Frequency │
│  ────────────────  │ ─────────────────  │ ──────────────── │
│  STATIC           │ BUCKLE             │ COMPLEX FREQ     │
│  DYNAMIC          │ MODAL              │ RANDOM RESPONSE  │
│  VISCO            │ FREQUENCY          │ RESPONSE SPECT   │
│  HEAT TRANSFER    │ SUBSPACE PROJECTION│                  │
│  COUPLED TEMP-DISP│ DYNAMIC IMPACT     │                  │
└─────────────────────────────────────────────────────────────┘
```

#### 3.2.1 PROC_* 完整枚举表


| PROC_ID | PROC_NAME                   | 求解器 | 说明              |
| ------- | --------------------------- | --- | --------------- |
| 1       | PROC_STATIC                 | STD | 通用静态（非线性）       |
| 2       | PROC_STATIC_RIKS            | STD | 弧长法（屈曲/后屈曲）     |
| 3       | PROC_STATIC_PERTURBATION    | STD | 线性扰动            |
| 4       | PROC_VISCO                  | STD | 蠕变/黏弹性准静态       |
| 10      | PROC_DYNAMIC_IMPLICIT       | STD | 隐式直接积分          |
| 11      | PROC_DYNAMIC_EXPLICIT       | EXP | 显式中心差分          |
| 12      | PROC_DYNAMIC_SUBSPACE       | STD | 子空间隐式           |
| 13      | PROC_MODAL_DYNAMIC          | STD | 模态动力学           |
| 14      | PROC_DYNAMIC_CTD_EXPLICIT   | EXP | 耦合温度-位移显式       |
| 20      | PROC_FREQUENCY              | STD | 频率（特征值）         |
| 21      | PROC_MODAL                  | STD | 模态（振型提取）        |
| 22      | PROC_BUCKLE                 | STD | 屈曲（特征值）         |
| 23      | PROC_RANDOM_RESPONSE        | STD | 随机响应            |
| 24      | PROC_RESPONSE_SPECTRUM      | STD | 反应谱             |
| 25      | PROC_COMPLEX_FREQUENCY      | STD | 复频率             |
| 26      | PROC_SSED                   | STD | 稳态动力学           |
| 30      | PROC_HEAT_TRANSFER          | THM | 热传导（稳态/瞬态）      |
| 31      | PROC_COUPLED_TEMP_DIFFUSION | CPL | 热-扩散耦合          |
| 40      | PROC_COUPLED_TES            | CFD | 温度-位移-应变耦合      |
| 41      | PROC_COUPLED_TEM_DYNAMIC    | CPL | 温度-位移耦合（动态）     |
| 42      | PROC_COUPLED_THERM_ELEC     | CPL | 热-电耦合           |
| 43      | PROC_PIEZOELECTRIC          | CPL | 压电耦合            |
| 44      | PROC_ELECTROMAGNETIC        | EMF | 电磁              |
| 45      | PROC_ACOUSTIC               | CPL | 声学              |
| 50      | PROC_SOIL                   | STD | 土（Geotechnical） |
| 51      | PROC_SOIL_EFFECTIVE         | STD | 有效应力            |
| 60      | PROC_SUBSTRUCTURE           | STD | 子结构             |
| 61      | PROC_SS_TRANSPORT           | DIF | 稳态传输            |


#### 3.2.2 PROC_* 与求解器映射矩阵

```
          │ STD  │ EXP  │ THM  │ CFD  │ EMF  │ CPL  │
──────────┼──────┼──────┼──────┼──────┼──────┼──────┤
PROC_STATIC│  ✓   │  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │
PROC_DYN_EXP│  ✗   │  ✓   │  ✗   │  ✗   │  ✗   │  ✗   │
PROC_HEAT   │  ✗   │  ✗   │  ✓   │  ✗   │  ✗   │  ✗   │
PROC_COUPLED│  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │  ✓   │
PROC_EMAG   │  ✗   │  ✗   │  ✗   │  ✗   │  ✓   │  ✗   │
```

### 2.3 单元家族（Element Family）

ABAQUS 的单元是 **第三维正交**，通过 Element Family 进行分类：

```
┌─────────────────────────────────────────────────────────────┐
│                    ABAQUS 单元家族                           │
├─────────────────────────────────────────────────────────────┤
│  Continuum Elements (连续体)    │ Structural Elements        │
│  ─────────────────────────────  │ ─────────────────────────│
│  C3D8 (8节点六面体)             │ S4 (4节点壳)              │
│  C3D20 (20节点六面体)           │ S8R (8节点壳)             │
│  C3D4 (4节点四面体)             │ B31 (2节点梁)             │
│  C3D6 (6节点楔形体)             │ T3D2 (2节点桁架)          │
│  CGAX (轴对称)                  │ SPRING (弹簧)             │
└─────────────────────────────────────────────────────────────┘
```

#### 2.3.1 UFC 单元类型枚举（对应 ABAQUS）

```fortran
! ElemType — UFC 单元类型枚举
! 与 ABAQUS Element Family 对应
INTEGER(i4), PARAMETER :: ELMTYPE_UNKNOWN   = 0_i4
INTEGER(i4), PARAMETER :: ELMTYPE_SLD       = 1_i4  ! Solid (实体): C3D*
INTEGER(i4), PARAMETER :: ELMTYPE_SHL       = 2_i4  ! Shell (壳): S*, ST*
INTEGER(i4), PARAMETER :: ELMTYPE_BM        = 3_i4  ! Beam (梁): B*, P*
INTEGER(i4), PARAMETER :: ELMTYPE_TRS       = 4_i4  ! Truss (桁架): T3D*
INTEGER(i4), PARAMETER :: ELMTYPE_MIX       = 5_i4  ! Mixed (混合): C3D8RH*
INTEGER(i4), PARAMETER :: ELMTYPE_CPL       = 6_i4  ! Coupled (耦合): FCAX*
INTEGER(i4), PARAMETER :: ELMTYPE_SPR       = 7_i4  ! Spring (弹簧)
INTEGER(i4), PARAMETER :: ELMTYPE_RBE       = 8_i4  ! Rigid Body (刚体)
INTEGER(i4), PARAMETER :: ELMTYPE_MPC       = 9_i4  ! MPC (多点约束)
```

#### 2.3.2 单元类型与求解器兼容性

```
          │ STD  │ EXP  │ THM  │ CFD  │ EMF  │ CPL  │
──────────┼──────┼──────┼──────┼──────┼──────┼──────┤
ELMTYPE_SLD│  ✓   │  ✓   │  ✓   │  ✓   │  ✓   │  ✓   │
ELMTYPE_SHL│  ✓   │  ✓   │  ✓   │  ✓   │  ✓   │  ✓   │
ELMTYPE_BM │  ✓   │  ✓   │  ✗   │  ✗   │  ✗   │  ✗   │
ELMTYPE_TRS│  ✓   │  ✓   │  ✗   │  ✗   │  ✗   │  ✗   │
ELMTYPE_MIX│  ✓   │  ✓   │  ✗   │  ✗   │  ✗   │  ✗   │
```

### 2.4 材料模型（Material Model）

ABAQUS 的材料是 **第四维正交**，通过用户子程序接口实现：

```
┌─────────────────────────────────────────────────────────────┐
│                    ABAQUS 材料模型分类                        │
├─────────────────────────────────────────────────────────────┤
│  Mechanical           │ Thermal           │ Other            │
│  ────────────────────  │ ─────────────────  │ ──────────────  │
│  *ELASTIC            │ *CONDUCTIVITY     │ *FLUID PROPS     │
│  *PLASTIC            │ *HEAT GENERATION  │ *ELECTROMAGNETIC│
│  *HYPERELASTIC       │ *FILM             │ *ACOUSTIC        │
│  *VISCOELASTIC       │ *HEAT FLUX       │ *POROUS          │
│  *CREEP              │                   │                  │
│  *DAMAGE             │                   │                  │
└─────────────────────────────────────────────────────────────┘
```

#### 2.4.1 UFC 物理类型枚举（对应 ABAQUS）

```fortran
! PhysType — UFC 物理类型枚举
! 与 ABAQUS 材料模型对应
INTEGER(i4), PARAMETER :: PHYSYTYPE_UNKNOWN      = 0_i4
INTEGER(i4), PARAMETER :: PHYSYTYPE_ELASTIC      = 1_i4  ! *ELASTIC
INTEGER(i4), PARAMETER :: PHYSYTYPE_PLASTIC      = 2_i4  ! *PLASTIC, *YIELD
INTEGER(i4), PARAMETER :: PHYSYTYPE_HYPERELASTIC = 3_i4  ! *HYPERELASTIC
INTEGER(i4), PARAMETER :: PHYSYTYPE_VISCOELASTIC = 4_i4  ! *VISCOELASTIC
INTEGER(i4), PARAMETER :: PHYSYTYPE_CREEP        = 5_i4  ! *CREEP
INTEGER(i4), PARAMETER :: PHYSYTYPE_DAMAGE       = 6_i4  ! *DAMAGE, *BRITTLE
INTEGER(i4), PARAMETER :: PHYSYTYPE_THERMAL       = 7_i4  ! *CONDUCTIVITY
INTEGER(i4), PARAMETER :: PHYSYTYPE_FLUID        = 8_i4  ! *FLUID
INTEGER(i4), PARAMETER :: PHYSYTYPE_EMF          = 9_i4  ! *ELECTROMAGNETIC
INTEGER(i4), PARAMETER :: PHYSYTYPE_ACOUSTIC     = 10_i4 ! *ACOUSTIC
INTEGER(i4), PARAMETER :: PHYSYTYPE_POROUS       = 11_i4 ! *POROUS
```

### 2.5 用户子程序体系（User Subroutines）

ABAQUS 的用户子程序是 **四维正交的交汇点**：

```
┌─────────────────────────────────────────────────────────────┐
│                    ABAQUS 用户子程序                         │
├─────────────────────────────────────────────────────────────┤
│  材料本构 (UMAT/VUMAT)     │ 热边界 (HETVAL/FILM)          │
│  ─────────────────────────  │ ─────────────────────────────│
│  UMAT (隐式)               │ HETVAL (体热源)               │
│  VUMAT (显式)              │ FILM (对流换热)               │
│  UHYPER (超弹性)           │ DFLUX (分布热通量)            │
│  UEL/VUEL (自定义单元)      │ VFILM/VDFLUX (显式)           │
├─────────────────────────────────────────────────────────────┤
│  接触 (FRIC/GAPCON)        │ 其他                          │
│  ─────────────────────────  │ ─────────────────────────────│
│  UINTER (接触面)           │ UEXTERNALDB (外部数据库)       │
│  FRIC (摩擦模型)           │ URDFIL (结果输出)             │
│  GAPCON (间隙传导)         │ UFIELD (用户场变量)           │
│  UFLUID (流体渗流)         │ UAMP (用户幅值)               │
└─────────────────────────────────────────────────────────────┘
```

#### 2.5.1 子程序与求解器禁止矩阵

```fortran
! 子程序与求解器兼容性矩阵
!
!            │ STD  │ EXP  │
! ───────────┼──────┼──────┤
! UMAT       │  ✓   │  ✗   │  ← 隐式材料本构
! VUMAT      │  ✗   │  ✓   │  ← 显式材料本构
! UEL        │  ✓   │  ✗   │  ← 隐式自定义单元
! VUEL       │  ✗   │  ✓   │  ← 显式自定义单元
! HETVAL     │  ✓   │  ✗   │  ← 隐式体热源
! VHETVAL    │  ✗   │  ✓   │  ← 显式体热源
! FILM       │  ✓   │  ✗   │  ← 隐式对流
! VFILM      │  ✗   │  ✓   │  ← 显式对流
! DFLUX      │  ✓   │  ✓   │  ← 分布热通量（通用）
! VDFLUX     │  ✗   │  ✓   │  ← 显式分布热通量
```

---

## 3. UFC 正交设计方案

### 3.1 四维正交架构

UFC 将 ABAQUS 的隐式正交设计 **显式化**：

```
┌─────────────────────────────────────────────────────────────┐
│                    UFC 四维正交架构                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   D1 (求解器)  ───────────────────────────────────────────▶│
│   RT_SolverType     STD / EXP / CFD / EMF / THM / CPL     │
│         │                                                   │
│         ▼                                                   │
│   D2 (分析步)  ───────────────────────────────────────────▶│
│   PROC_*          STATIC / DYNAMIC / HEAT / COUPLED        │
│         │                                                   │
│         ▼                                                   │
│   D3 (单元)     ───────────────────────────────────────────▶│
│   ElemType        SLD / SHL / BM / TRS / MIX              │
│         │                                                   │
│         ▼                                                   │
│   D4 (物理)     ───────────────────────────────────────────▶│
│   PhysType        ELASTIC / PLASTIC / HYPER / CREEP        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    RT_SD_Router (路由层)                    │
│   根据四维坐标，自动分发到正确的处理单元                      │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 组合数对比


| 方案         | 理论组合数      | 实际组件数 | 说明    |
| ---------- | ---------- | ----- | ----- |
| 笛卡尔积（传统）   | 1,350,000+ | 全部需实现 | 组合爆炸  |
| ABAQUS（隐式） | 1,350,000+ | ~500  | 自动路由  |
| UFC（显式）    | 1,350,000+ | 145   | 正交+校验 |


**UFC 优势**：

1. 组合数从 145 个独立组件管理
2. 每增加一个新维度，只需添加 O(n) 个组件，而非 O(n×m)
3. 显式校验在输入阶段拒绝非法组合

### 3.3 四维配置结构

```fortran
! RT_NDim_Config — 四维正交配置
TYPE, PUBLIC :: RT_NDim_Config
  ! --- D1: 求解器类型 ---
  INTEGER(i4) :: solver_type  = RT_SOLVER_UNKNOWN

  ! --- D2: 分析步类型 ---
  INTEGER(i4) :: proc_type    = PROC_STATIC

  ! --- D3: 单元类型 ---
  INTEGER(i4) :: elem_type    = ELMTYPE_SLD

  ! --- D4: 物理类型 ---
  INTEGER(i4) :: phys_type    = PHYSYTYPE_ELASTIC

  ! --- 可选扩展维度 ---
  INTEGER(i4) :: load_type    = RT_LOAD_UNKNOWN    ! D5: 载荷类型
  INTEGER(i4) :: bc_type      = RT_BC_UNKNOWN      ! D6: 边界条件
  INTEGER(i4) :: coupling_type = RT_COUPLING_NONE    ! D7: 耦合类型

CONTAINS
  PROCEDURE :: Validate       => RT_NDim_Config_Validate
  PROCEDURE :: ToString       => RT_NDim_Config_ToString
  PROCEDURE :: GetHash        => RT_NDim_Config_GetHash
  PROCEDURE :: FromABAQUS     => RT_NDim_Config_FromABAQUS
END TYPE RT_NDim_Config
```

### 3.4 组合校验函数

```fortran
! RT_Comb_Validate — 四维组合合法性校验
!
! 输入：四维坐标
! 返回：.TRUE. = 合法组合，.FALSE. = 非法组合
!
FUNCTION RT_Comb_Validate(solver_type, proc_type, elem_type, phys_type) &
    RESULT(is_valid)
  INTEGER(i4), INTENT(IN) :: solver_type, proc_type, elem_type, phys_type
  LOGICAL :: is_valid

  is_valid = .FALSE.

  ! --- D1×D2: 求解器 × 分析步 ---
  IF (.NOT. RT_SolverProc_Valid(solver_type, proc_type)) THEN
    CALL RT_Warning("Invalid D1×D2: Solver-Proc combination")
    RETURN
  END IF

  ! --- D2×D3: 分析步 × 单元 ---
  IF (.NOT. RT_ProcElem_Valid(proc_type, elem_type)) THEN
    CALL RT_Warning("Invalid D2×D3: Proc-Elem combination")
    RETURN
  END IF

  ! --- D3×D4: 单元 × 物理 ---
  IF (.NOT. RT_ElemPhys_Valid(elem_type, phys_type)) THEN
    CALL RT_Warning("Invalid D3×D4: Elem-Phys combination")
    RETURN
  END IF

  ! --- D1×D4: 求解器 × 物理 ---
  IF (.NOT. RT_SolverPhys_Valid(solver_type, phys_type)) THEN
    CALL RT_Warning("Invalid D1×D4: Solver-Phys combination")
    RETURN
  END IF

  is_valid = .TRUE.

END FUNCTION RT_Comb_Validate
```

---

## 4. ABAQUS 无缝对接实现

### 4.1 输入解析：INP → UFC Config

ABAQUS 的输入文件（INP）包含所有四维信息：

```fortran
! RT_ABAQUS_Parser — INP 文件解析
!
! 从 INP 文件提取四维配置
!
SUBROUTINE RT_ABAQUS_Parser(inp_file, config, status)
  CHARACTER(LEN=*), INTENT(IN) :: inp_file
  TYPE(RT_NDim_Config), INTENT(OUT) :: config
  TYPE(ErrorStatusType), INTENT(OUT) :: status

  ! --- 解析分析步 → D2 ---
  CALL ParseSTEP(inp_file, config%proc_type)

  ! --- 解析单元 → D3 ---
  CALL ParseELEMENT(inp_file, config%elem_type)

  ! --- 解析材料 → D4 ---
  CALL ParseMATERIAL(inp_file, config%phys_type)

  ! --- 解析求解器 → D1 (推断) ---
  config%solver_type = RT_Infer_SolverType(config%proc_type)

  ! --- 校验四维组合 ---
  IF (.NOT. RT_Comb_Validate(config%solver_type, config%proc_type, &
                               config%elem_type, config%phys_type)) THEN
    status%code = IF_STATUS_ERROR
    RETURN
  END IF

END SUBROUTINE RT_ABAQUS_Parser
```

### 4.2 子程序映射表

UFC 的每个用户子程序都映射到唯一的四维坐标：


| UFC 子程序                     | D1      | D2      | D3  | D4      | ABAQUS 接口    |
| --------------------------- | ------- | ------- | --- | ------- | ------------ |
| `PH_Mat_Str_Elastic_UMAT`   | STD     | STATIC  | SLD | ELASTIC | UMAT         |
| `PH_Mat_Str_Plastic_UMAT`   | STD     | STATIC  | SLD | PLASTIC | UMAT         |
| `PH_Mat_Str_Hyper_UMAT`     | STD     | STATIC  | SLD | HYPER   | UHYPER       |
| `PH_Mat_Str_Creep_UMAT`     | STD     | VISCO   | SLD | CREEP   | UCREEP       |
| `PH_Elem_Sld_UEL`           | STD     | STATIC  | SLD | -       | UEL          |
| `PH_Mat_Str_Elastic_VUMAT`  | EXP     | DYN_EXP | SLD | ELASTIC | VUMAT        |
| `PH_Mat_Str_Plastic_VUMAT`  | EXP     | DYN_EXP | SLD | PLASTIC | VUMAT        |
| `PH_Elem_Sld_VUEL`          | EXP     | DYN_EXP | SLD | -       | VUEL         |
| `PH_Mat_Thm_HeatGen_HETVAL` | STD     | HEAT    | SLD | THERMAL | HETVAL       |
| `PH_Mat_Thm_Film_FILM`      | STD     | HEAT    | SLD | THERMAL | FILM         |
| `PH_Mat_Thm_Flux_DFLUX`     | STD/EXP | HEAT    | SLD | THERMAL | DFLUX/VDFLUX |
| `PH_Cont_Fric_FRIC`         | STD     | STATIC  | -   | CONTACT | FRIC         |
| `PH_Cont_Gap_GAPCON`        | STD     | STATIC  | -   | CONTACT | GAPCON       |


### 4.3 路由分发实现

```fortran
! RT_SD_Router — 四维正交路由
!
! 根据四维配置，将计算分发到正确的处理单元
!
SUBROUTINE RT_SD_Router(ctx, config)
  TYPE(RT_SD_Ctx), INTENT(INOUT) :: ctx
  TYPE(RT_NDim_Config), INTENT(IN) :: config

  ! --- D1 维度路由：选择求解引擎 ---
  SELECT CASE (config%solver_type)

  CASE (RT_SOLVER_IMPLICIT)
    CALL RT_SD_RunImplicit(ctx, config)

  CASE (RT_SOLVER_EXPLICIT)
    CALL RT_SD_RunExplicit(ctx, config)

  CASE (RT_SOLVER_THERMAL)
    CALL RT_SD_RunThermal(ctx, config)

  CASE (RT_SOLVER_CPL)
    CALL RT_SD_RunCoupled(ctx, config)

  CASE DEFAULT
    CALL RT_Error("Unsupported solver type")
  END SELECT

END SUBROUTINE RT_SD_Router

! RT_SD_RunImplicit — 隐式求解器路由
SUBROUTINE RT_SD_RunImplicit(ctx, config)
  TYPE(RT_SD_Ctx), INTENT(INOUT) :: ctx
  TYPE(RT_NDim_Config), INTENT(IN) :: config

  ! --- D2 维度路由：选择分析步处理 ---
  SELECT CASE (config%proc_type)

  CASE (PROC_STATIC)
    CALL RT_SD_RunStatic(ctx, config)

  CASE (PROC_VISCO)
    CALL RT_SD_RunVisco(ctx, config)

  CASE (PROC_DYNAMIC_IMPLICIT)
    CALL RT_SD_RunDynamicImplicit(ctx, config)

  CASE DEFAULT
    CALL RT_Error("Unsupported procedure for implicit solver")
  END SELECT

END SUBROUTINE RT_SD_RunImplicit

! RT_SD_RunStatic — 静态分析步路由
SUBROUTINE RT_SD_RunStatic(ctx, config)
  TYPE(RT_SD_Ctx), INTENT(INOUT) :: ctx
  TYPE(RT_NDim_Config), INTENT(IN) :: config

  ! --- D3×D4 维度路由：选择单元-材料处理 ---
  SELECT CASE (config%elem_type)

  CASE (ELMTYPE_SLD)
    SELECT CASE (config%phys_type)
    CASE (PHYSYTYPE_ELASTIC)
      CALL PH_Mat_Str_Elastic_UMAT(ctx)
    CASE (PHYSYTYPE_PLASTIC)
      CALL PH_Mat_Str_Plastic_UMAT(ctx)
    CASE (PHYSYTYPE_HYPERELASTIC)
      CALL PH_Mat_Str_Hyper_UHYPER(ctx)
    CASE (PHYSYTYPE_CREEP)
      CALL PH_Mat_Str_Creep_UCREEP(ctx)
    CASE DEFAULT
      CALL RT_Error("Unsupported phys type for Solid")
    END SELECT

  CASE (ELMTYPE_SHL)
    CALL RT_SD_RunStatic_Shell(ctx, config)

  CASE (ELMTYPE_BM)
    CALL RT_SD_RunStatic_Beam(ctx, config)

  CASE DEFAULT
    CALL RT_Error("Unsupported elem type for STATIC")
  END SELECT

END SUBROUTINE RT_SD_RunStatic
```

### 4.4 VOIGT 约定与数据传递

ABAQUS 使用 Voigt 记号作为标准数据格式：

```fortran
! Voigt 约定（与 ABAQUS 完全一致）
!
! 索引映射：
!   1 → 11 (σ11, ε11)
!   2 → 22 (σ22, ε22)
!   3 → 33 (σ33, ε33)
!   4 → 12 (σ12, ε12 = γ12)
!   5 → 13 (σ13, ε13 = γ13)
!   6 → 23 (σ23, ε23 = γ23)
!
! 重要：Voigt 应变 = γ/2（工程应变的一半）
!

INTEGER(i4), PARAMETER :: NTENS_3D = 6   ! 三维应力/应变分量数
INTEGER(i4), PARAMETER :: NTENS_2D = 3   ! 二维平面应力/应变

! Voigt 索引常量
INTEGER(i4), PARAMETER :: V11 = 1
INTEGER(i4), PARAMETER :: V22 = 2
INTEGER(i4), PARAMETER :: V33 = 3
INTEGER(i4), PARAMETER :: V12 = 4
INTEGER(i4), PARAMETER :: V13 = 5
INTEGER(i4), PARAMETER :: V23 = 6
```

---

## 5. 完整对接示例

### 5.1 示例：静态弹性分析

**ABAQUS 输入**：

```inp
*STEP
*STATIC
1.0, 1.0
*BOUNDARY
Set-1, ENCASTRE
*CLOAD
Set-2, 2, 10.0
*ELASTIC
200000, 0.3
*SOLID SECTION
Material=Steel, Elset=Part-1
```

**UFC 四维配置推导**：


| 维度          | 来源               | 值                    | 说明           |
| ----------- | ---------------- | -------------------- | ------------ |
| D1 (solver) | 推断               | `RT_SOLVER_IMPLICIT` | STATIC → STD |
| D2 (proc)   | `*STATIC`        | `PROC_STATIC`        | 静态分析         |
| D3 (elem)   | `*SOLID SECTION` | `ELMTYPE_SLD`        | 实体单元         |
| D4 (phys)   | `*ELASTIC`       | `PHYSYTYPE_ELASTIC`  | 线弹性          |


**UFC 路由**：

```
RT_SD_Router
  └─ RT_SOLVER_IMPLICIT → RT_SD_RunImplicit
       └─ PROC_STATIC → RT_SD_RunStatic
            └─ ELMTYPE_SLD + PHYSYTYPE_ELASTIC → PH_Mat_Str_Elastic_UMAT
```

### 5.2 示例：显式弹塑性分析

**ABAQUS 输入**：

```inp
*STEP
* DYNAMIC, EXPLICIT
, 1.0
*BOUNDARY
Set-1, ENCASTRE
*VELOCITY
Set-2, 2, 5.0
*PLASTIC
300.0, 0.0
200.0, 0.1
*SOLID SECTION
Material=Steel, Elset=Part-1
```

**UFC 四维配置推导**：


| 维度          | 来源                   | 值                       | 说明                      |
| ----------- | -------------------- | ----------------------- | ----------------------- |
| D1 (solver) | 推断                   | `RT_SOLVER_EXPLICIT`    | DYNAMIC, EXPLICIT → EXP |
| D2 (proc)   | `*DYNAMIC, EXPLICIT` | `PROC_DYNAMIC_EXPLICIT` | 显式动态                    |
| D3 (elem)   | `*SOLID SECTION`     | `ELMTYPE_SLD`           | 实体单元                    |
| D4 (phys)   | `*PLASTIC`           | `PHYSYTYPE_PLASTIC`     | 塑性                      |


**UFC 路由**：

```
RT_SD_Router
  └─ RT_SOLVER_EXPLICIT → RT_SD_RunExplicit
       └─ PROC_DYNAMIC_EXPLICIT → RT_SD_RunDynamicExplicit
            └─ ELMTYPE_SLD + PHYSYTYPE_PLASTIC → PH_Mat_Str_Plastic_VUMAT
```

### 5.3 示例：热传导分析

**ABAQUS 输入**：

```inp
*STEP
*HEAT TRANSFER, STEADY-STATE
*BOUNDARY
Set-1, 11, 11, 100.0
*BOUNDARY
Set-2, 11, 11, 20.0
*FILM
Set-3, F1, 10.0, 20.0
*CONDUCTIVITY
50.0
*SOLID SECTION
Material=Alu, Elset=Part-1
```

**UFC 四维配置推导**：


| 维度          | 来源               | 值                    | 说明                  |
| ----------- | ---------------- | -------------------- | ------------------- |
| D1 (solver) | 推断               | `RT_SOLVER_THERMAL`  | HEAT TRANSFER → THM |
| D2 (proc)   | `*HEAT TRANSFER` | `PROC_HEAT_TRANSFER` | 热传导                 |
| D3 (elem)   | `*SOLID SECTION` | `ELMTYPE_SLD`        | 实体单元                |
| D4 (phys)   | `*CONDUCTIVITY`  | `PHYSYTYPE_THERMAL`  | 热传导                 |


**UFC 路由**：

```
RT_SD_Router
  └─ RT_SOLVER_THERMAL → RT_SD_RunThermal
       └─ PROC_HEAT_TRANSFER → RT_SD_RunHeatTransfer
            └─ ELMTYPE_SLD + PHYSYTYPE_THERMAL → PH_Mat_Thm_Conduction
                 ├─ FILM → PH_Mat_Thm_Film
                 └─ HETVAL (可选) → PH_Mat_Thm_HeatGen
```

---

## 6. 附录

### 附录 A：完整禁止组合矩阵


| D1\D2 | STATIC | DYN_EXP | DYN_IMP | HEAT | COUPLED | EMAG |
| ----- | ------ | ------- | ------- | ---- | ------- | ---- |
| STD   | ✅      | ❌       | ✅       | ❌    | ❌       | ❌    |
| EXP   | ❌      | ✅       | ❌       | ❌    | ❌       | ❌    |
| THM   | ❌      | ❌       | ❌       | ✅    | ❌       | ❌    |
| CFD   | ❌      | ❌       | ❌       | ❌    | ✅       | ❌    |
| EMF   | ❌      | ❌       | ❌       | ❌    | ❌       | ✅    |
| CPL   | ❌      | ❌       | ❌       | ❌    | ✅       | ❌    |


### 附录 B：ABAQUS 求解器-子程序映射


| ABAQUS 求解器 | 隐式子程序                | 显式子程序                  |
| ---------- | -------------------- | ---------------------- |
| Standard   | UMAT, UEL, UELMAT    | -                      |
| Standard   | HETVAL, FILM, DFLUX  | -                      |
| Standard   | UINTER, FRIC, GAPCON | -                      |
| Explicit   | -                    | VUMAT, VUEL            |
| Explicit   | -                    | VHETVAL, VFILM, VDFLUX |
| CFD        | 原生                   | 原生                     |


### 附录 C：术语对照表


| UFC 术语                 | ABAQUS 术语           | 说明    |
| ---------------------- | ------------------- | ----- |
| RT_SOLVER_IMPLICIT     | Abaqus/Standard     | 隐式求解器 |
| RT_SOLVER_EXPLICIT     | Abaqus/Explicit     | 显式求解器 |
| RT_SOLVER_THERMAL      | Abaqus/Standard (热) | 热求解器  |
| PROC_STATIC            | *STATIC             | 静态分析步 |
| PROC_DYNAMIC_EXPLICIT  | *DYNAMIC, EXPLICIT  | 显式动态  |
| ELMTYPE_SLD            | C3D*, CGAX          | 实体单元  |
| ELMTYPE_SHL            | S*, ST*             | 壳单元   |
| PHYSYTYPE_ELASTIC      | *ELASTIC            | 线弹性   |
| PHYSYTYPE_PLASTIC      | *PLASTIC            | 塑性    |
| PHYSYTYPE_HYPERELASTIC | *HYPERELASTIC       | 超弹性   |
| PHYSYTYPE_THERMAL      | *CONDUCTIVITY       | 热传导   |


---

## 7. 最佳方案：UFC 正交路由最佳实践

### 7.1 推荐架构模式

UFC 推荐采用 **三层路由架构**：

```
┌─────────────────────────────────────────────────────────────┐
│                    第一层：D1 路由（求解器）                  │
│  RT_SD_Router ──────────────────────────────────────────▶│
│  根据 RT_SolverType 分发到 STD/EXP/CFD/THM 引擎           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    第二层：D2 路由（分析步）                  │
│  RT_SD_Run[Implicit/Explicit/Thermal] ──────────────────▶│
│  根据 PROC_* 分发到 STATIC/DYNAMIC/HEAT 等处理器           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    第三层：D3×D4 路由（单元×材料）            │
│  RT_Elem_Mat_Router ────────────────────────────────────▶│
│  根据 ElemType × PhysType 分发到具体实现                   │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 最佳路由实现模板

```fortran
! RT_SD_Router — 最佳路由实现（推荐）
!
! 设计原则：
! 1. 单一入口，所有维度统一路由
! 2. 短路评估，提前返回非法组合
! 3. 路由信息可追溯（写入日志）
!
SUBROUTINE RT_SD_Router(ctx, config, status)
  TYPE(RT_SD_Ctx), INTENT(INOUT) :: ctx
  TYPE(RT_NDim_Config), INTENT(IN) :: config
  TYPE(ErrorStatusType), INTENT(OUT) :: status

  ! --- 组合校验（短路评估）---
  IF (.NOT. RT_Comb_Validate(config)) THEN
    status%code = IF_STATUS_ERROR
    status%message = "Invalid dimension combination: " // &
                     RT_NDim_Config_ToString(config)
    CALL RT_Error(status%message)
    RETURN
  END IF

  ! --- D1 路由：求解器选择 ---
  SELECT CASE (config%solver_type)
  CASE (RT_SOLVER_IMPLICIT)
    CALL RT_SD_RunImplicit(ctx, config, status)
  CASE (RT_SOLVER_EXPLICIT)
    CALL RT_SD_RunExplicit(ctx, config, status)
  CASE (RT_SOLVER_THERMAL)
    CALL RT_SD_RunThermal(ctx, config, status)
  CASE (RT_SOLVER_CFD)
    CALL RT_SD_RunCFD(ctx, config, status)
  CASE (RT_SOLVER_CPL)
    CALL RT_SD_RunCoupled(ctx, config, status)
  CASE DEFAULT
    status%code = IF_STATUS_ERROR
    status%message = "Unsupported solver type"
    RETURN
  END SELECT

  status%code = IF_STATUS_OK

END SUBROUTINE RT_SD_Router

! RT_SD_RunImplicit — 隐式求解器最佳实现
SUBROUTINE RT_SD_RunImplicit(ctx, config, status)
  TYPE(RT_SD_Ctx), INTENT(INOUT) :: ctx
  TYPE(RT_NDim_Config), INTENT(IN) :: config
  TYPE(ErrorStatusType), INTENT(OUT) :: status

  ! --- 牛顿迭代循环 ---
  DO iter = 1, config%max_iter
    ! 装配残差
    CALL RT_Asm_Residual(ctx)

    ! 检查收敛
    IF (RT_Check_Convergence(ctx)) THEN
      status%code = IF_STATUS_OK
      RETURN
    END IF

    ! --- D2 路由：分析步特定处理 ---
    SELECT CASE (config%proc_type)
    CASE (PROC_STATIC, PROC_STATIC_RIKS, PROC_VISCO)
      CALL RT_SD_SolveNonlinear(ctx, config, status)
    CASE (PROC_DYNAMIC_IMPLICIT)
      CALL RT_SD_SolveDynamicImplicit(ctx, config, status)
    CASE (PROC_MODAL, PROC_FREQUENCY, PROC_BUCKLE)
      CALL RT_SD_SolveEigenvalue(ctx, config, status)
    CASE DEFAULT
      status%code = IF_STATUS_ERROR
      RETURN
    END SELECT
  END DO

  ! 未收敛
  status%code = IF_STATUS_NOT_CONVERGED

END SUBROUTINE RT_SD_RunImplicit

! RT_Elem_Mat_Router — 单元×材料最佳路由
SUBROUTINE RT_Elem_Mat_Router(ctx, config, status)
  TYPE(RT_SD_Ctx), INTENT(INOUT) :: ctx
  TYPE(RT_NDim_Config), INTENT(IN) :: config
  TYPE(ErrorStatusType), INTENT(OUT) :: status

  ! --- 短路校验 ---
  IF (.NOT. RT_ElemPhys_Valid(config%elem_type, config%phys_type)) THEN
    status%code = IF_STATUS_ERROR
    RETURN
  END IF

  ! --- 二维路由：ELMTYPE × PHYSYTPE ---
  SELECT CASE (config%elem_type)

  CASE (ELMTYPE_SLD)
    SELECT CASE (config%phys_type)
    CASE (PHYSYTYPE_ELASTIC)
      CALL PH_Mat_Str_Elastic_UMAT(ctx)
    CASE (PHYSYTYPE_PLASTIC)
      CALL PH_Mat_Str_Plastic_UMAT(ctx)
    CASE (PHYSYTYPE_HYPERELASTIC)
      CALL PH_Mat_Str_Hyper_UHYPER(ctx)
    CASE (PHYSYTYPE_VISCOELASTIC)
      CALL PH_Mat_Str_Viscoelastic_UMAT(ctx)
    CASE (PHYSYTYPE_CREEP)
      CALL PH_Mat_Str_Creep_UCREEP(ctx)
    CASE (PHYSYTYPE_DAMAGE)
      CALL PH_Mat_Str_Damage_UMAT(ctx)
    CASE DEFAULT
      status%code = IF_STATUS_ERROR
      RETURN
    END SELECT

  CASE (ELMTYPE_SHL)
    SELECT CASE (config%phys_type)
    CASE (PHYSYTYPE_ELASTIC)
      CALL PH_Mat_Str_Elastic_UMAT_Shell(ctx)
    CASE (PHYSYTYPE_PLASTIC)
      CALL PH_Mat_Str_Plastic_UMAT_Shell(ctx)
    CASE (PHYSYTYPE_HYPERELASTIC)
      CALL PH_Mat_Str_Hyper_UMAT_Shell(ctx)
    CASE DEFAULT
      status%code = IF_STATUS_ERROR
      RETURN
    END SELECT

  CASE (ELMTYPE_BM)
    SELECT CASE (config%phys_type)
    CASE (PHYSYTYPE_ELASTIC)
      CALL PH_Mat_Str_Elastic_UMAT_Beam(ctx)
    CASE (PHYSYTYPE_PLASTIC)
      CALL PH_Mat_Str_Plastic_UMAT_Beam(ctx)
    CASE DEFAULT
      status%code = IF_STATUS_ERROR
      RETURN
    END SELECT

  CASE (ELMTYPE_TRS)
    CALL PH_Mat_Str_Truss_UMAT(ctx)

  CASE DEFAULT
    status%code = IF_STATUS_ERROR
    RETURN
  END SELECT

  status%code = IF_STATUS_OK

END SUBROUTINE RT_Elem_Mat_Router
```

### 7.3 性能优化策略

#### 7.3.1 路由缓存

```fortran
! RT_NDim_Cache — 路由结果缓存
!
! 避免重复路由查询，提升高频场景性能
!
TYPE, PRIVATE :: RT_NDim_Cache
  TYPE(RT_NDim_Config) :: key
  INTEGER(i4) :: handler_id
  LOGICAL :: valid
CONTAINS
  PROCEDURE :: Get => RT_NDim_Cache_Get
  PROCEDURE :: Put => RT_NDim_Cache_Put
  PROCEDURE :: Invalidate => RT_NDim_Cache_Invalidate
END TYPE RT_NDim_Cache

! 缓存查找（O(1) 哈希）
FUNCTION RT_NDim_Cache_Get(cache, config) RESULT(handler_id)
  TYPE(RT_NDim_Cache), INTENT(INOUT) :: cache
  TYPE(RT_NDim_Config), INTENT(IN) :: config
  INTEGER(i4) :: handler_id

  ! 计算配置哈希
  INTEGER(i8) :: hash = RT_NDim_Config_GetHash(config)

  ! 查找缓存
  IF (cache%valid .AND. hash == cache%key%hash) THEN
    handler_id = cache%handler_id
  ELSE
    handler_id = -1  ! 未命中
  END IF
END FUNCTION RT_NDim_Cache_Get
```

#### 7.3.2 预计算路由表

```fortran
! RT_RouteTable — 预计算路由表
!
! 在初始化阶段预计算所有合法组合的路由目标
! 将 O(n) 路由查找优化为 O(1) 表查询
!
TYPE, PUBLIC :: RT_RouteTable
  ! 路由表：solver × proc × elem × phys → handler_id
  INTEGER(i4) :: table(0:8, 0:100, 0:9, 0:15)
  LOGICAL :: valid_combinations(0:8, 0:100, 0:9, 0:15)

CONTAINS
  PROCEDURE :: Init => RT_RouteTable_Init
  PROCEDURE :: Lookup => RT_RouteTable_Lookup
  PROCEDURE :: IsValid => RT_RouteTable_IsValid
END TYPE RT_RouteTable

! 预计算所有合法组合
SUBROUTINE RT_RouteTable_Init(table)
  TYPE(RT_RouteTable), INTENT(OUT) :: table
  INTEGER(i4) :: s, p, e, m

  DO s = 0, 8
    DO p = 0, 100
      DO e = 0, 9
        DO m = 0, 15
          IF (RT_Comb_Validate(s, p, e, m)) THEN
            table%valid_combinations(s, p, e, m) = .TRUE.
            table%table(s, p, e, m) = RT_Assign_Handler(s, p, e, m)
          ELSE
            table%valid_combinations(s, p, e, m) = .FALSE.
          END IF
        END DO
      END DO
    END DO
  END DO
END SUBROUTINE RT_RouteTable_Init

! O(1) 路由查找
FUNCTION RT_RouteTable_Lookup(table, config) RESULT(handler_id)
  TYPE(RT_RouteTable), INTENT(IN) :: table
  TYPE(RT_NDim_Config), INTENT(IN) :: config
  INTEGER(i4) :: handler_id

  handler_id = table%table(config%solver_type, config%proc_type, &
                           config%elem_type, config%phys_type)
END FUNCTION RT_RouteTable_Lookup
```

### 7.4 扩展性设计

#### 7.4.1 新增维度模板

```fortran
! 添加新维度 D8（时间离散格式）的模板

! 1. 定义枚举
INTEGER(i4), PARAMETER :: TIMEFMT_UNKNOWN = 0_i4
INTEGER(i4), PARAMETER :: TIMEFMT_IMPLICIT = 1_i4  ! Newmark-β
INTEGER(i4), PARAMETER :: TIMEFMT_EXPLICIT = 2_i4  ! 中心差分
INTEGER(i4), PARAMETER :: TIMEFMT_HHT = 3_i4       ! HHT-α
INTEGER(i4), PARAMETER :: TIMEFMT_WBP = 4_i4       ! WBZ-θ

! 2. 扩展配置结构
TYPE, PUBLIC :: RT_NDim_Config
  ! ... 原有字段 ...
  INTEGER(i4) :: timefmt_type = TIMEFMT_UNKNOWN  ! D8: 时间格式

! 3. 添加校验函数
FUNCTION RT_TimefmtSolver_Valid(timefmt, solver) RESULT(valid)
  INTEGER(i4), INTENT(IN) :: timefmt, solver
  LOGICAL :: valid

  valid = .FALSE.
  SELECT CASE (solver)
  CASE (RT_SOLVER_IMPLICIT)
    valid = (timefmt /= TIMEFMT_EXPLICIT)  ! 隐式不用显式时间格式
  CASE (RT_SOLVER_EXPLICIT)
    valid = (timefmt == TIMEFMT_EXPLICIT .OR. &
             timefmt == TIMEFMT_HHT)        ! 显式可用中心差分或 HHT
  END SELECT
END FUNCTION RT_TimefmtSolver_Valid

! 4. 更新路由函数
SUBROUTINE RT_SD_Router_WithTimefmt(ctx, config, status)
  ! ... D1-D4 路由 ...

  ! 新增 D8 路由
  SELECT CASE (config%timefmt_type)
  CASE (TIMEFMT_IMPLICIT)
    CALL RT_Time_Integrate_Newmark(ctx)
  CASE (TIMEFMT_EXPLICIT)
    CALL RT_Time_Integrate_CentralDiff(ctx)
  CASE (TIMEFMT_HHT)
    CALL RT_Time_Integrate_HHT(ctx)
  END SELECT
END SUBROUTINE RT_SD_Router_WithTimefmt
```

### 7.5 完整代码生成模板

```fortran
! RT_NDim_Config — 完整实现
MODULE RT_NDim_Config_Module
  USE IF_Prec
  IMPLICIT NONE
  PRIVATE

  ! 导出公共类型
  PUBLIC :: RT_NDim_Config

  ! 求解器枚举
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_SOLVER_UNKNOWN   = 0, &
    RT_SOLVER_IMPLICIT  = 1, &
    RT_SOLVER_EXPLICIT  = 2, &
    RT_SOLVER_CFD       = 3, &
    RT_SOLVER_EMF       = 4, &
    RT_SOLVER_THERMAL   = 5, &
    RT_SOLVER_PMF       = 6, &
    RT_SOLVER_DIF       = 7, &
    RT_SOLVER_CPL       = 8

  ! 分析步枚举（部分）
  INTEGER(i4), PARAMETER, PUBLIC :: &
    PROC_STATIC         = 1, &
    PROC_STATIC_RIKS    = 2, &
    PROC_VISCO          = 4, &
    PROC_DYNAMIC_IMPLICIT = 10, &
    PROC_DYNAMIC_EXPLICIT = 11, &
    PROC_HEAT_TRANSFER  = 30

  ! 单元类型枚举
  INTEGER(i4), PARAMETER, PUBLIC :: &
    ELMTYPE_UNKNOWN    = 0, &
    ELMTYPE_SLD       = 1, &
    ELMTYPE_SHL       = 2, &
    ELMTYPE_BM        = 3, &
    ELMTYPE_TRS       = 4

  ! 物理类型枚举
  INTEGER(i4), PARAMETER, PUBLIC :: &
    PHYSYTYPE_UNKNOWN      = 0, &
    PHYSYTYPE_ELASTIC      = 1, &
    PHYSYTYPE_PLASTIC      = 2, &
    PHYSYTYPE_HYPERELASTIC = 3, &
    PHYSYTYPE_VISCOELASTIC = 4, &
    PHYSYTYPE_CREEP        = 5, &
    PHYSYTYPE_DAMAGE       = 6

  ! 四维配置类型
  TYPE, PUBLIC :: RT_NDim_Config
    INTEGER(i4) :: solver_type = RT_SOLVER_UNKNOWN
    INTEGER(i4) :: proc_type   = PROC_STATIC
    INTEGER(i4) :: elem_type   = ELMTYPE_SLD
    INTEGER(i4) :: phys_type   = PHYSYTYPE_ELASTIC
  CONTAINS
    PROCEDURE :: Validate => RT_NDim_Config_Validate
    PROCEDURE :: ToString => RT_NDim_Config_ToString
    PROCEDURE :: GetHash  => RT_NDim_Config_GetHash
    PROCEDURE :: FromABAQUS => RT_NDim_Config_FromABAQUS
  END TYPE RT_NDim_Config

CONTAINS

  FUNCTION RT_NDim_Config_Validate(config) RESULT(is_valid)
    CLASS(RT_NDim_Config), INTENT(IN) :: config
    LOGICAL :: is_valid

    is_valid = RT_Comb_Validate(config%solver_type, config%proc_type, &
                                 config%elem_type, config%phys_type)
  END FUNCTION RT_NDim_Config_Validate

  FUNCTION RT_NDim_Config_ToString(config) RESULT(str)
    CLASS(RT_NDim_Config), INTENT(IN) :: config
    CHARACTER(LEN=128) :: str

    WRITE(str, '(A,I1,A,I3,A,I1,A,I1)') &
      "[", config%solver_type, ",", config%proc_type, &
      ",", config%elem_type, ",", config%phys_type, "]"
  END FUNCTION RT_NDim_Config_ToString

  FUNCTION RT_NDim_Config_GetHash(config) RESULT(hash)
    CLASS(RT_NDim_Config), INTENT(IN) :: config
    INTEGER(i8) :: hash

    hash = config%solver_type * 1000 + &
           config%proc_type   * 100  + &
           config%elem_type  * 10   + &
           config%phys_type
  END FUNCTION RT_NDim_Config_GetHash

  SUBROUTINE RT_NDim_Config_FromABAQUS(config, inp_data)
    CLASS(RT_NDim_Config), INTENT(OUT) :: config
    TYPE(InpParseData), INTENT(IN) :: inp_data

    ! 从 INP 数据推断四维配置
    config%proc_type = RT_Infer_ProcType(inp_data%step_card)
    config%solver_type = RT_Infer_SolverType(config%proc_type)
    config%elem_type = RT_Infer_ElemType(inp_data%element_type)
    config%phys_type = RT_Infer_PhysType(inp_data%material_card)
  END SUBROUTINE RT_NDim_Config_FromABAQUS

END MODULE RT_NDim_Config_Module
```

### 7.6 检查清单

新增分析步/单元/材料时，务必执行以下检查：


| 检查项      | 说明              | 通过标准         |
| -------- | --------------- | ------------ |
| D1×D2 校验 | 新 PROC 与求解器的兼容性 | 见 §2.2.2     |
| D2×D3 校验 | 新单元与分析步的兼容性     | 见 §2.3.2     |
| D3×D4 校验 | 新材料与单元的兼容性      | 见 §2.4       |
| D1×D4 校验 | 新材料与求解器的兼容性     | 见 §6.3       |
| 子程序映射    | 新组合是否有对应子程序     | 已实现或标记为 STUB |
| 单元测试     | 新组合是否通过单元测试     | 100% 通过      |
| 文档更新     | 术语对照表是否同步更新     | 已更新          |


---

## 8. 四维正交矩阵完整设计

> **核心理念**：底层四维驱动上层 PROC 和求解器类型，而非相反。  
> **倒向思维**：material × element × time × method 推导出有效的分析类型和求解器路由

### 8.1 四维维度的精确定义与数据统计

#### 8.1.1 Material Dimension（材料维度）

ABAQUS 的材料模型按物理类型分为 **11 个大族**，共 **54-65 种**（根据版本而定）：


| 序号  | 材料族                 | ABAQUS 关键字         | 典型模型                                               | UFC 代号    | 数量        |
| --- | ------------------- | ------------------ | -------------------------------------------------- | --------- | --------- |
| 1   | 弹性（Elastic）         | `*ELASTIC`         | Linear Elastic, Orthotropic, Engineering Constants | MAT_ELA_* | 6-8       |
| 2   | 塑性（Plastic）         | `*PLASTIC`         | von Mises, Hill, Drucker-Prager                    | MAT_PLA_* | 8-10      |
| 3   | 超弹性（Hyperelastic）   | `*HYPERELASTIC`    | Neo-Hooke, Mooney-Rivlin, Ogden, Yeoh, Marlow      | MAT_HYP_* | 8-10      |
| 4   | 粘弹性（Viscoelastic）   | `*VISCOELASTIC`    | Prony级数, Power-law                                 | MAT_VIS_* | 5-7       |
| 5   | 蠕变（Creep）           | `*CREEP`           | 功率律, 显式蠕变                                          | MAT_CRP_* | 4-6       |
| 6   | 损伤（Damage）          | `*DAMAGE`          | Ductile, Brittle Cracking, XFEM                    | MAT_DMG_* | 6-8       |
| 7   | 热（Thermal）          | `*CONDUCTIVITY`    | 导热系数, 比热                                           | MAT_THM_* | 3-5       |
| 8   | 电磁（Electromagnetic） | `*ELECTROMAGNETIC` | 导电率, 介电常数                                          | MAT_EMF_* | 3-4       |
| 9   | 声学（Acoustic）        | `*ACOUSTIC_MEDIUM` | 声阻抗, 频散                                            | MAT_ACU_* | 2-3       |
| 10  | 多孔（Porous）          | `*PERMEABILITY`    | 孔隙流, 多孔介质                                          | MAT_POR_* | 2-3       |
| 11  | 流体（Fluid）           | `*FLUID_PROPS`     | 粘度, 密度                                             | MAT_FLD_* | 2-3       |
|     |                     |                    | **合计**                                             |           | **54-65** |


**说明**：

- 各族可能因 ABAQUS 版本差异而有增减（如新增损伤模型）
- UFC 内部建议使用 `material_family_idx` × `material_subtype_idx` 的两层索引
- 可用位掩码表示多物理场耦合材料

#### 8.1.2 Element Dimension（单元维度）

ABAQUS 的单元分为 **12 个大族**，共 **377-433 个变体**（含精度、积分方式、节点配置）：


| 序号  | 单元族                 | ABAQUS 基础类型         | UFC 代号 | 基础种数    | 变体数   | 总数          |
| --- | ------------------- | ------------------- | ------ | ------- | ----- | ----------- |
| 1   | 连续体（Continuum）      | C3D4, C3D8, C3D20 等 | SLD    | 15-20   | 30-40 | 45-60       |
| 2   | 壳（Shell）            | S3, S4, S8R 等       | SHL    | 10-15   | 15-20 | 25-35       |
| 3   | 梁（Beam）             | B21, B31, B32 等     | BM     | 5-8     | 2-4   | 8-12        |
| 4   | 桁架（Truss）           | T3D2, T3D3 等        | TRS    | 2-3     | 1-2   | 3-5         |
| 5   | 刚体（Rigid）           | R3D3, R3D4 等        | RBE    | 2-3     | -     | 2-3         |
| 6   | 弹簧（Spring）          | SPRING1, SPRING2 等  | SPR    | 2-3     | 1-2   | 3-5         |
| 7   | 质量（Mass）            | MASS 等              | MASS   | 1-2     | -     | 1-2         |
| 8   | 界面（Interface）       | COD2D, CIN3D8 等     | INT    | 10-15   | 3-5   | 15-20       |
| 9   | 耦合（Coupled）         | C3D8RP, C3D8T 等     | CPL    | 15-20   | 5-10  | 20-30       |
| 10  | 声学（Acoustic）        | AC2D3, AC3D4 等      | ACU    | 5-8     | 2-3   | 8-12        |
| 11  | 电磁（Electromagnetic） | EM3D8, EMAXIAL 等    | EMF    | 5-8     | 2-3   | 8-12        |
| 12  | 用户定义（User-defined）  | UEL/VUEL 框架         | UDC    | 可扩展     | 可扩展   | 可扩展         |
|     |                     |                     | **合计** | 100-150 | 60-90 | **377-433** |


**说明**：

- 基础种数：不同节点配置、阶数的单元类型
- 变体数：不同的积分方式（完全积分、简化积分、混合法）
- 轴对称变体（CGAX*）计入总数
- UFC 使用 `elem_family_idx` × `elem_precision_idx` × `elem_integration_idx` 的三层索引

#### 8.1.3 TimeType Dimension（时间特性维度）

UFC 定义的时间特性维度有 **6-7 种**：

```fortran
! TimeType 维度枚举
INTEGER(i4), PARAMETER :: &
  TT_STATIC          = 1, &  ! 静态分析
  TT_TRANSIENT       = 2, &  ! 瞬态分析（显式或隐式）
  TT_STEADY_STATE    = 3, &  ! 稳态分析（非线性稳定）
  TT_MODAL           = 4, &  ! 模态分析（特征值问题）
  TT_FREQUENCY       = 5, &  ! 频率响应分析（复值）
  TT_BUCKLING        = 6, &  ! 屈曲分析（特征值）
  TT_THERMAL_STEADY  = 7     ! 热稳态分析
```

**特性**：

- **STATIC**：无时间依赖，仅需解一次线性/非线性系统
- **TRANSIENT**：显式时间推进，需逐步积分（通常与 EXPLICIT 耦合）
- **STEADY_STATE**：时间依赖但已达到稳定状态，寻找周期解
- **MODAL**：求解特征频率和模态形（线性特征值问题）
- **FREQUENCY**：频域激励响应，求解复值位移或加速度
- **BUCKLING**：几何非线性特征值问题，求临界载荷
- **THERMAL_STEADY**：温度不随时间变化，仅热传导

#### 8.1.4 SolverMethod Dimension（求解方法维度）

UFC 定义的求解方法维度有 **4 种**：

```fortran
! SolverMethod 维度枚举
INTEGER(i4), PARAMETER :: &
  SM_IMPLICIT        = 1, &  ! 隐式积分（Newmark, Newmark-beta 等）
  SM_EXPLICIT        = 2, &  ! 显式中心差分（Central Difference）
  SM_CFD             = 3, &  ! 流体求解（有限体积法）
  SM_ACOUSTIC        = 4     ! 声学求解（特殊处理）
```

**特性**：

- **IMPLICIT**：适合准静态、缓变、需要大时间步的问题；用于 Abaqus/Standard
- **EXPLICIT**：适合冲击、接触、大变形问题；用于 Abaqus/Explicit
- **CFD**：适合流体动力学、燃烧、多相流；用于 Abaqus/CFD
- **ACOUSTIC**：适合声学、噪音、吸音材料；通常为频域求解

---

### 8.2 理论组合与禁止矩阵

#### 8.2.1 理论组合数计算

**基础数据**：

- Material：M = 60（取中值）
- Element：E = 400（取中值）
- TimeType：T = 6
- SolverMethod：V = 4

**理论组合数**：

```
理论组合 = M × E × T × V = 60 × 400 × 6 × 4 = 576,000
```

#### 8.2.2 主要禁止规则

**规则1：TimeType × SolverMethod 的兼容性**

```
              │ IMPLICIT │ EXPLICIT │ CFD │ ACOUSTIC │
──────────────┼──────────┼──────────┼─────┼──────────┤
STATIC        │    ✓     │    ✗     │  ✗  │    ✗     │
TRANSIENT     │    ✓     │    ✓     │  ✓  │    ✓     │
STEADY_STATE  │    ✓     │    ✗     │  ✓  │    ✗     │
MODAL         │    ✓     │    ✗     │  ✗  │    ✗     │
FREQUENCY     │    ✓     │    ✗     │  ✗  │    ✓     │
BUCKLING      │    ✓     │    ✗     │  ✗  │    ✗     │
THERMAL_STEADY│    ✓     │    ✗     │  ✗  │    ✗     │
```

**禁止规则数**：14 个禁止组合

**规则2：Material × TimeType 的兼容性**

```
材料类型        │ STATIC │ TRANSIENT │ STEADY │ MODAL │ FREQ │ THERMAL │
────────────────┼────────┼───────────┼────────┼───────┼──────┼─────────┤
ELASTIC         │   ✓    │     ✓     │   ✓    │   ✓   │  ✓   │    ✗    │
PLASTIC         │   ✓    │     ✓     │   ✗    │   ✗   │  ✗   │    ✗    │
HYPERELASTIC    │   ✓    │     ✓     │   ✗    │   ✗   │  ✗   │    ✗    │
CREEP           │   ✓    │     ✓     │   ✓    │   ✗   │  ✗   │    ✗    │
THERMAL         │   ✗    │     ✓     │   ✓    │   ✗   │  ✗   │    ✓    │
FLUID           │   ✗    │     ✓     │   ✓    │   ✗   │  ✗   │    ✗    │
ACOUSTIC        │   ✗    │     ✗     │   ✗    │   ✓   │  ✓   │    ✗    │
```

**禁止规则数**：约 25-30 个禁止组合

**规则3：Element × Material 的兼容性**

```
单元类型        │ STRUCTURAL │ THERMAL │ FLUID │ ACOUSTIC │ EM   │
────────────────┼────────────┼─────────┼───────┼──────────┼──────┤
SLD (Solid)     │     ✓      │    ✓    │   ✓   │    ✗     │  ✓   │
SHL (Shell)     │     ✓      │    ✓    │   ✗   │    ✗     │  ✓   │
BM (Beam)       │     ✓      │    ✗    │   ✗   │    ✗     │  ✗   │
TRS (Truss)     │     ✓      │    ✗    │   ✗   │    ✗     │  ✗   │
CPL (Coupled)   │     ✓      │    ✓    │   ✓   │    ✗     │  ✓   │
ACU (Acoustic)  │     ✗      │    ✗    │   ✗   │    ✓     │  ✗   │
EMF (EM)        │     ✗      │    ✗    │   ✗   │    ✗     │  ✓   │
```

**禁止规则数**：约 20-25 个禁止组合

#### 8.2.3 有效组合估计

**禁止规则总数**：≈ 60-80 个

**禁止组合占比**：

```
粗略估计：禁止占理论 ≈ 99.8%（因为大多数时间、方法、材料、单元组合无意义）
```

**有效组合数**：

```
有效 = 理论 - 禁止
     = 576,000 - 500,000+
     ≈ 5,000 - 50,000（保守估计）
     
更现实的估计（考虑实际工业应用）：
     ≈ 500 - 5,000 个常用组合
```

---

### 8.3 倒向思维设计：从四维推导求解器

#### 8.3.1 倒向思维流程

```
用户输入 INP 文件
    ↓
解析四维参数
  Material ← *MATERIAL 卡片
  Element  ← *ELEMENT 卡片
  TimeType ← *STEP 卡片类型推断
  Method   ← 用户指定或自动推断
    ↓
调用禁止检查 (ForbiddenMatrix)
  验证 (Material, Element, TimeType, Method) 的合法性
    ↓ (有效)
推导 PROC_* 类型
  (TimeType, Method) → PROC_*
  例如 (TRANSIENT, IMPLICIT) → PROC_DYNAMIC_IMPLICIT
    ↓
推导求解器类型
  (PROC_*, Material, Element) → Solver
  例如 (PROC_DYNAMIC_IMPLICIT, STRUCTURAL, SLD) → RT_SOLVER_IMPLICIT
    ↓
构建路由表并调度执行
```

#### 8.3.2 TimeType × Method → PROC_* 映射表

```fortran
! 二维路由表：TimeType × Method → PROC_*
INTEGER(i4), PARAMETER :: PROC_ROUTING(7, 4) = RESHAPE([
  !  IMPLICIT │ EXPLICIT │ CFD │ ACOUSTIC  
  !───────────┼──────────┼─────┼──────────
  PROC_STATIC,         0,     0,         0, &  ! STATIC
  PROC_DYNAMICS,  PROC_EXPLICIT_DYN, PROC_CFD_TRANSIENT, PROC_ACOUSTIC_TRANSIENT, &  ! TRANSIENT
  PROC_STEADY,    0,     PROC_CFD_STEADY,         0, &  ! STEADY_STATE
  PROC_MODAL,     0,     0,     PROC_ACOUSTIC_MODAL, &  ! MODAL
  PROC_FREQUENCY, 0,     0,     PROC_ACOUSTIC_FREQ, &  ! FREQUENCY
  PROC_BUCKLE,    0,     0,         0, &  ! BUCKLING
  PROC_HEAT_STEADY, 0,   0,         0 &  ! THERMAL_STEADY
  ], SHAPE(PROC_ROUTING))
```

#### 8.3.3 PROC_* × Material/Element → Solver 映射表

**关键决策逻辑**：

```fortran
FUNCTION RT_Infer_Solver(proc, material, element) RESULT(solver)
  INTEGER(i4), INTENT(IN) :: proc, material, element
  INTEGER(i4) :: solver
  
  SELECT CASE (proc)
    CASE (PROC_STATIC)
      ! 静态分析
      IF (material_is_structural(material) .AND. elem_is_structural(element)) THEN
        solver = RT_SOLVER_IMPLICIT  ! Abaqus/Standard Static
      ELSE IF (material_is_thermal(material)) THEN
        solver = RT_SOLVER_IMPLICIT  ! Abaqus/Standard Thermal Steady
      ELSE
        solver = RT_SOLVER_UNKNOWN   ! 不支持
      END IF
      
    CASE (PROC_DYNAMICS)
      ! 动态分析（隐式）
      IF (material_is_structural(material)) THEN
        solver = RT_SOLVER_IMPLICIT  ! Abaqus/Standard Implicit Dynamic
      ELSE
        solver = RT_SOLVER_UNKNOWN
      END IF
      
    CASE (PROC_EXPLICIT_DYN)
      ! 显式动态
      IF (material_is_structural(material)) THEN
        solver = RT_SOLVER_EXPLICIT  ! Abaqus/Explicit
      ELSE
        solver = RT_SOLVER_UNKNOWN
      END IF
      
    CASE (PROC_CFD_TRANSIENT, PROC_CFD_STEADY)
      ! CFD 分析
      IF (material_is_fluid(material) .AND. elem_is_cfd(element)) THEN
        solver = RT_SOLVER_CFD       ! Abaqus/CFD
      ELSE
        solver = RT_SOLVER_UNKNOWN
      END IF
      
    CASE (PROC_ACOUSTIC_MODAL, PROC_ACOUSTIC_FREQ, PROC_ACOUSTIC_TRANSIENT)
      ! 声学分析
      IF (material_is_acoustic(material) .AND. elem_is_acoustic(element)) THEN
        solver = RT_SOLVER_ACOUSTIC  ! 声学求解器
      ELSE
        solver = RT_SOLVER_UNKNOWN
      END IF
      
    CASE DEFAULT
      solver = RT_SOLVER_UNKNOWN
  END SELECT
END FUNCTION RT_Infer_Solver
```

---

### 8.4 完整的四维正交矩阵表（主要组合示例）

下表展示了 **有效的核心组合**（共代表约 50-100 个常用工程应用）：


| 序号  | Material        | Element    | TimeType     | Method   | PROC_*               | Solver   | 应用示例   |
| --- | --------------- | ---------- | ------------ | -------- | -------------------- | -------- | ------ |
| 1   | ELASTIC         | SLD        | STATIC       | IMPLICIT | PROC_STATIC          | Implicit | 静力分析   |
| 2   | ELASTIC+PLASTIC | SLD        | TRANSIENT    | IMPLICIT | PROC_DYNAMICS        | Implicit | 隐式动力分析 |
| 3   | HYPERELASTIC    | SLD        | TRANSIENT    | EXPLICIT | PROC_EXPLICIT_DYN    | Explicit | 橡胶冲击   |
| 4   | ELASTIC         | SLD        | MODAL        | IMPLICIT | PROC_MODAL           | Implicit | 模态分析   |
| 5   | ELASTIC         | SLD        | FREQUENCY    | IMPLICIT | PROC_FREQUENCY       | Implicit | 频率响应   |
| 6   | THERMAL         | SLD        | STEADY_STATE | IMPLICIT | PROC_HEAT_STEADY     | Implicit | 热稳态    |
| 7   | ELASTIC+THERMAL | CPL        | TRANSIENT    | IMPLICIT | PROC_COUPLED_THERMAL | Implicit | 热-结构耦合 |
| 8   | ELASTIC+POROUS  | CPL        | TRANSIENT    | IMPLICIT | PROC_COUPLED_POROUS  | Implicit | 孔压耦合   |
| 9   | FLUID           | FLUID_ELEM | STEADY_STATE | CFD      | PROC_CFD_STEADY      | CFD      | 流体稳态   |
| 10  | FLUID           | FLUID_ELEM | TRANSIENT    | CFD      | PROC_CFD_TRANSIENT   | CFD      | 流体瞬态   |
| 11  | ACOUSTIC        | ACU        | MODAL        | IMPLICIT | PROC_ACOUSTIC_MODAL  | Acoustic | 声学模态   |
| 12  | ACOUSTIC        | ACU        | FREQUENCY    | IMPLICIT | PROC_ACOUSTIC_FREQ   | Acoustic | 声学响应   |
| 13  | ELASTIC         | SLD        | BUCKLING     | IMPLICIT | PROC_BUCKLE          | Implicit | 屈曲分析   |
| 14  | ELASTIC+CREEP   | SLD        | TRANSIENT    | IMPLICIT | PROC_CREEP_DYNAMIC   | Implicit | 蠕变动力   |
| 15  | DAMAGE          | SLD        | TRANSIENT    | EXPLICIT | PROC_EXPLICIT_DAMAGE | Explicit | 损伤脆断   |


**说明**：

- 上表仅代表常用工程应用的 15-20 个代表组合
- 完整矩阵包含数千个可能的组合，但其中 99.8% 为禁止或非常规应用
- 实际 UFC 路由系统应维护一个禁止矩阵，而非列举所有有效组合

---

### 8.5 路由算法设计

#### 8.5.1 三层路由架构

```
┌──────────────────────────────────────────────────┐
│         L5_RT 路由层（Runtime Routing）           │
├──────────────────────────────────────────────────┤
│                                                  │
│  L1: 四维参数验证与规范化                         │
│      Material, Element, TimeType, Method         │
│                          ↓                       │
│  L2: 禁止矩阵快速查询                             │
│      若发现禁止组合 → 返回错误                    │
│                          ↓                       │
│  L3: PROC_* 推导与求解器选择                     │
│      (TimeType, Method) → PROC_*                 │
│      (PROC_*, Material, Element) → Solver        │
│                          ↓                       │
│  L4: 子程序路由与分发                             │
│      Solver × (Material, Element) → Implementation│
│                                                  │
└──────────────────────────────────────────────────┘
```

#### 8.5.2 伪代码框架

```fortran
MODULE RT_Orthogonal_Router
  USE IF_MPI_Base
  USE NM_LinAlg
  USE MD_Material
  USE MD_Element
  USE MD_Step
  USE PH_Implementations
  IMPLICIT NONE
  
CONTAINS

  ! ═══════════════════════════════════════════════════════════
  ! 主路由函数：从四维参数推导求解器并执行
  ! ═══════════════════════════════════════════════════════════
  SUBROUTINE RT_Route_4D_Config(config, status)
    TYPE(RT_4DConfig), INTENT(IN)  :: config
    TYPE(RT_Status), INTENT(OUT) :: status
    
    ! 第一层：验证四维参数
    IF (.NOT. RT_Validate_4D(config)) THEN
      status%code = RT_ERR_INVALID_CONFIG
      RETURN
    END IF
    
    ! 第二层：查询禁止矩阵
    IF (RT_Is_Forbidden(config%material, config%element, &
                        config%time_type, config%method)) THEN
      status%code = RT_ERR_FORBIDDEN_COMBINATION
      RETURN
    END IF
    
    ! 第三层：推导 PROC_* 和求解器
    config%proc_type   = RT_Infer_ProcType(config%time_type, config%method)
    config%solver_type = RT_Infer_SolverType(config%proc_type, &
                                             config%material, config%element)
    
    ! 第四层：分发执行
    SELECT CASE (config%solver_type)
      CASE (RT_SOLVER_IMPLICIT)
        CALL RT_Execute_Implicit(config, status)
      CASE (RT_SOLVER_EXPLICIT)
        CALL RT_Execute_Explicit(config, status)
      CASE (RT_SOLVER_CFD)
        CALL RT_Execute_CFD(config, status)
      CASE (RT_SOLVER_ACOUSTIC)
        CALL RT_Execute_Acoustic(config, status)
      CASE DEFAULT
        status%code = RT_ERR_SOLVER_NOT_SUPPORTED
    END SELECT
  END SUBROUTINE RT_Route_4D_Config
  
  ! ─────────────────────────────────────────────────────────
  ! 禁止矩阵快速查询（O(1) 哈希查找）
  ! ─────────────────────────────────────────────────────────
  FUNCTION RT_Is_Forbidden(mat, elem, ttype, method) RESULT(forbidden)
    INTEGER(i4), INTENT(IN) :: mat, elem, ttype, method
    LOGICAL :: forbidden
    INTEGER(i8) :: hash
    
    ! 构造 hash 值
    hash = INT(mat, i8) * 1000000_i8 + &
           INT(elem, i8) * 10000_i8 + &
           INT(ttype, i8) * 100_i8 + &
           INT(method, i8)
    
    ! 查询预计算的禁止表
    forbidden = ANY(forbidden_hash_table(:) == hash)
  END FUNCTION RT_Is_Forbidden
  
  ! ─────────────────────────────────────────────────────────
  ! 时间类型 × 方法 → PROC_* 映射
  ! ─────────────────────────────────────────────────────────
  FUNCTION RT_Infer_ProcType(ttype, method) RESULT(proc)
    INTEGER(i4), INTENT(IN) :: ttype, method
    INTEGER(i4) :: proc
    
    SELECT CASE (ttype * 100 + method)  ! 编码为唯一整数
      CASE (100 + 1)
        proc = PROC_STATIC
      CASE (200 + 1)
        proc = PROC_DYNAMICS
      CASE (200 + 2)
        proc = PROC_EXPLICIT_DYN
      ! ... 更多映射
      CASE DEFAULT
        proc = PROC_UNKNOWN
    END SELECT
  END FUNCTION RT_Infer_ProcType
  
END MODULE RT_Orthogonal_Router
```

#### 8.5.3 禁止矩阵预计算

```fortran
MODULE RT_Forbidden_Matrix
  IMPLICIT NONE
  PRIVATE
  
  ! 预计算的禁止组合 hash 表（在程序初始化时构建）
  INTEGER(i8), ALLOCATABLE, PUBLIC :: forbidden_hash_table(:)
  INTEGER(i4), PUBLIC :: n_forbidden = 0
  
CONTAINS

  SUBROUTINE RT_Build_Forbidden_Matrix()
    ! 根据 8.2.2 中的规则构建禁止矩阵
    ! 共 60-80 条规则，编码为 hash 值
    
    ALLOCATE(forbidden_hash_table(80))
    n_forbidden = 0
    
    ! 规则1：禁止 (STATIC, EXPLICIT) 组合
    CALL RT_Add_Forbidden(1, *, 1, 2)  ! (STATIC=1, *, *, EXPLICIT=2)
    
    ! 规则2：禁止 (THERMAL_MAT, STATIC) 组合
    CALL RT_Add_Forbidden(7, *, 1, *)  ! (THERMAL_MAT=7, *, STATIC=1, *)
    
    ! ... 更多规则
  END SUBROUTINE RT_Build_Forbidden_Matrix
  
  SUBROUTINE RT_Add_Forbidden(mat, elem, ttype, method)
    ! 添加一条禁止规则到表中
  END SUBROUTINE RT_Add_Forbidden
  
END MODULE RT_Forbidden_Matrix
```

---

### 8.6 实施检查清单

实施四维正交设计时，必须完成以下检查：


| 检查项                     | 说明                                   | 完成标记 |
| ----------------------- | ------------------------------------ | ---- |
| **D1: TimeType 枚举**     | 确认所有 TimeType 已定义                    | ☐    |
| **D2: SolverMethod 枚举** | 确认所有 SolverMethod 已定义                | ☐    |
| **D3: 禁止矩阵**            | 列举所有 60-80 条禁止规则                     | ☐    |
| *D4: PROC_ 推导表**        | TimeType × Method → PROC_* 的完整映射     | ☐    |
| **D5: 求解器选择表**          | PROC_* × Material × Element → Solver | ☐    |
| **D6: 路由算法**            | 实现四层路由架构（验证、禁止检查、推导、分发）              | ☐    |
| **D7: 哈希缓存**            | 禁止矩阵预计算并缓存为 hash 表（O(1) 查询）          | ☐    |
| **D8: 单元测试**            | 每条禁止规则、每个有效组合都有测试用例                  | ☐    |
| **D9: 文档同步**            | 将路由逻辑记录到 UFC_命名规范_v3.0.md 附录         | ☐    |
| **D10: 性能基准**           | 路由查询应 <100us（O(1) 哈希查询）              | ☐    |


---

**文档结束**

*本文档完整阐述了 ABAQUS 的四维正交架构，以及 UFC 从底层四维推导上层求解器类型的设计原理。*