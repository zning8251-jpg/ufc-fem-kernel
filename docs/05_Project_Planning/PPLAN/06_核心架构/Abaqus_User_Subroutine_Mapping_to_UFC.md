# UFC 对 Abaqus 用户子程序的全景映射与架构分层

## 一、总体设计原则

### 1.0 核心设计决策（Key Design Decisions）

**文档目的**：本文档建立 UFC 架构对 Abaqus 全谱系用户子程序（79 个）的权威映射关系，作为以下工作的强制基准：
- ✅ UFC 子程序模板生成（PH_XXX_UMAT/PH_XXX_UEL/PH_XXX_Load 等）
- ✅ @templates 区开发
- ✅ 六层架构区迁移
- ✅ L3/L4/L5跨层数据传递设计

#### 关键架构决策

**1. 双层域体系**
- **L3_MD 模型域**（14 个）：Model/Part/Assembly/Mesh/Section/Material/Amplitude/LoadBC/Interaction/Constraint/Step/Output/Bridge/WriteBack
- **Abaqus 子程序域**（8 个）：Material/Element/Load/BC/Contact/Constraint/Field/Analysis
- **映射规则**：L3 多个域可能合并/拆分到 L4（如 LoadBC → Load+BC；Mesh → Element）

**2. Output 域的特殊性**
- **L3_MD**：有 `Output` 域（定义输出请求、变量管理）
- **L4_PH**：**没有**独立的 Output 计算域
- **L5_RT**：有 `RT_Output_Ctx`（负责从 L4 收集计算结果 → 传递给求解器）
- **设计理由**：Output 是"结果采集和传递"，不是"物理计算"

**3. Amplitude 域的独立性**
- **Abaqus 方案**：归入 Analysis（因为主要用于载荷/边界的时间控制）
- **UFC 方案**：**独立成域**，因为：
  - Amplitude 是**独立的数据对象**（时间 - 幅值曲线表）
  - 被多个域**共享引用**（Load/BC/Analysis Step）
  - 符合 UFC"数据与计算分离"原则

**4. Layer × Domain × Role 正交架构**
- **L3_MD** = "What"（模型是什么）：纯数据，无计算
- **L4_PH** = "How"（物理如何计算）：应力更新、刚度组装、接触迭代
- **L5_RT** = "When & Where"（何时何地执行）：时间步进、求解器调用

---

### 1.1 分层策略
```
L1_IF (Infrastructure)       ← 精度/错误/内存/IO/持久化/数值基础
L2_NM (Numerical Methods)    ← 线性代数/特征值/时间积分/求解器
L3_MD (Model Description)    ← Desc: 材料/单元/载荷/边界参数定义
L4_PH (Physics)              ← State/Algo/Ctx: 物理计算核心
L5_RT (Runtime)              ← Ctx: 运行时上下文、求解器集成、分析控制
L6_AP (Application)          ← AP: 用户应用层、前处理/后处理/可视化
```

**六层职责划分**：
- **L1_IF**: 基础设施层（精度定义、错误处理、内存管理、文件 IO）
- **L2_NM**: 数值方法层（线性方程组、特征值问题、时间积分算法）
- **L3_MD**: 模型数据层（What - 模型参数定义，只读快照）
- **L4_PH**: 物理计算层（How - 应力更新、刚度组装、接触迭代）
- **L5_RT**: 运行时层（When & Where - 时间步进、求解器调度、结果输出）
- **L6_AP**: 应用层（User Interface - 前处理、后处理、可视化）

### 1.2 域级划分（Domain）—— **双层域体系规范**

**重要设计决策**：UFC 架构包含**两套域体系**，需明确区分：

#### ① L3_MD 模型域（14 个）—— 模型数据组织
| 域名 | 职责 | 核心类型 |
|------|------|----------|
| **Model** | 模型顶层容器、版本管理 | MD_Model_Domain |
| **Part** | 部件几何、截面分配 | MD_Part_Domain |
| **Assembly** | 实例装配、变换矩阵 | MD_Assembly_Domain |
| **Mesh** | 节点坐标、单元连接 | MD_Mesh_Domain |
| **Section** | 截面属性、积分点 | MD_Section_Domain |
| **Material** | 材料参数库、本构路由 | MD_Material_Domain |
| **Amplitude** | 时间 - 幅值曲线 | MD_Amplitude_Domain |
| **LoadBC** | 载荷/边界条件定义 | MD_LoadBC_Domain |
| **Interaction** | 接触对、表面定义 | MD_Interaction_Domain |
| **Constraint** | MPC/Tie/刚体约束 | MD_Constraint_Domain |
| **Step** | 分析步配置、求解器参数 | MD_Step_Domain |
| **Output** | 输出请求、变量管理 | MD_Output_Domain |
| **Bridge** | L3→L4 跨层数据桥接 | MD_Bridge_Domain |
| **WriteBack** | 状态写回白名单管理 | MD_WriteBack_Domain |

#### ② Abaqus 子程序域（8 个）—— 物理计算契约
| 域名 | 对应 Abaqus 子程序 | L3 映射域 | L4 计算核心 |
|------|-------------------|-----------|-------------|
| **Material** | UMAT/VUMAT/UMATHT | Material 域 | PH_XXX_UMAT |
| **Element** | UEL/VUEL | Mesh 域 | PH_XXX_UEL |
| **Load** | DLOAD/VDLOAD/CLOAD | LoadBC 域 | PH_XXX_Load |
| **BC** | DISP/VDISP/UTEMP | LoadBC 域 | PH_XXX_BC |
| **Contact** | UINTER/VUINTER/UFRIC | Interaction 域 | PH_XXX_Contact |
| **Constraint** | MPC/UMESHMOTION | Constraint 域 | PH_XXX_MPC |
| **Field** | USDFLD/VUSDFLD/SDVINI | - | PH_XXX_Field |
| **Analysis** | UAMP/VUAMP/UEXTERNALDB | Amplitude/Step 域 | RT_XXX_UAmp |

#### ③ 为什么采用双层域体系？

**设计哲学**：
- **L3_MD** = "What"（模型是什么）：部件、网格、材料、载荷的定义
- **L4_PH** = "How"（物理如何计算）：应力更新、刚度组装、接触迭代
- **L5_RT** = "When & Where"（何时何地执行）：时间步进、求解器调用

**映射规则**：
1. L3_MD 的每个域**不一定**在 L4_PH 有独立对应
   - 例：L3 的 `Part/Assembly/Mesh` → L4 合并为 `Element` 域（UEL 只关心节点/单元信息）
   - 例：L3 的 `LoadBC` → L4 拆分为 `Load` + `BC`（计算逻辑不同）
   - 例：L3 的 `Interaction` → L4 映射为 `Contact` 域（接触计算）
   - 例：L3 的 `Step` → L5 映射为 `Analysis` 域（分析步控制）
   
2. L4_PH 的 8 个子程序域是对 Abaqus 用户接口的**直接映射**
   - 目的：让熟悉 Abaqus 的用户能快速定位到 UFC 对应模块
   - 本质：计算契约的封装接口

3. L3 多个域可能合并映射到 L4 一个域（如 LoadBC → Load+BC）

4. **Output 域的特殊性**：
   - L3_MD 有 `Output` 域（定义输出请求、变量管理）
   - L4_PH **没有**独立的 Output 计算域
   - L5_RT 有 `RT_Output_Ctx`（负责从 L4 收集计算结果 → 传递给求解器）
   - **设计理由**：Output 是"结果采集和传递"，不是"物理计算"

5. **Amplitude 域的独立性**：
   - Abaqus 将 Amplitude 归入 Analysis（因为主要用于载荷/边界的时间控制）
   - UFC 将 Amplitude **独立成域**，因为：
     * Amplitude 是**独立的数据对象**（时间 - 幅值曲线表）
     * 被多个域**共享引用**（Load/BC/Analysis Step）
     * 符合 UFC"数据与计算分离"原则
   - L3_MD: `MD_Amplitude_Desc`（幅值曲线参数）
   - L4_PH: `PH_Amp_Algo`（幅值插值算法，非计算域）
   - L5_RT: `RT_Amplitude_Ctx`（幅值曲线上下文）

#### 完整域集合（8 大域）
| 域名 | 对应 Abaqus 子程序族 | 跨层一致性说明 |
|------|---------------------|----------------|
| **Material** | UMAT/VUMAT/UMATHT/CREEP/UHARD/... | L3:本构参数 | L4:应力更新算法 | L5:求解器材料接口 |
| **Element** | UEL/VUEL/UELMAT | L3:单元拓扑 | L4:刚度组装 | L5:单元 - 求解器绑定 |
| **Load** | DLOAD/VDLOAD/CLOAD/FILM/HETVAL/... | L3:载荷定义 | L4:时空分布计算 | L5:载荷 API 适配 |
| **BC** | DISP/VDISP/UTEMP/UPOREP/... | L3:边界类型 | L4:位移/速度计算 | L5:边界 API 适配 |
| **Contact** | UINTER/VUINTER/UFRIC/VFRIC/GAPCON/... | L3:接触对参数 | L4:摩擦/压力算法 | L5:接触 API 适配 |
| **Constraint** | MPC/UMESHMOTION/RSURFU/... | L3:约束方程定义 | L4:约束施加算法 | L5:约束 API 适配 |
| **Field** | USDFLD/VUSDFLD/UFIELD/SDVINI/SIGINI/... | L3:场变量定义 | L4:场演化算法 | L5:场 API 适配 |
| **Analysis** | UAMP/VUAMP/UEXTERNALDB/URDFIL/... | L3:幅值曲线定义 | L4:幅值插值算法 | L5:分析控制接口 |

#### 为什么采用全域一致性？

**优势**：
1. **正交性**：Layer × Domain 形成完整矩阵，无缺失单元格
2. **可追溯性**：每个域在三层均有明确对应，便于调试和维护
3. **扩展性**：新增域时自动覆盖三层，避免技术债务
4. **对称美**：符合数学上的张量积结构，便于形式化验证

**职责差异示例**（以 Load 域为例）：
```
L3_MD/Load:
  TYPE MD_Load_Desc
    REAL(wp) :: magnitude     ! 载荷幅值
    INTEGER  :: load_type     ! 载荷类型（压力/体力/面力）
  END TYPE
  → 回答"是什么"（What）

L4_PH/Load:
  SUBROUTINE PH_XXX_DLOAD_API(...)
    ! 读取 MD_Load_Desc%magnitude
    ! 基于 coords/time 计算空间分布
    ! 返回 load_value = f(magnitude, coords, time)
  END SUBROUTINE
  → 回答"怎么算"（How）

L5_RT/Load:
  TYPE RT_Com_Ctx
    REAL(wp) :: time_current  ! 当前时间
    INTEGER  :: kstep         ! 步编号
  END TYPE
  INTERFACE
    CALL abq_apply_dload(load_value, elem_id, integ_pt)
  END INTERFACE
  → 回答"何时何地"（When & Where）
```

---

## 二、三维正交架构可视化

### 2.1 Layer × Domain × Role 立方体

#### ① UFC 完整域集合（14 核心域 + 8Abaqus 子程序域）

**重要说明**：UFC 架构包含两套域体系：
- **L3_MD 模型域**（14 个）：Model/Part/Assembly/Mesh/Section/Material/Amplitude/LoadBC/Interaction/Constraint/Step/Output/Bridge/WriteBack
- **Abaqus 子程序域**（8 个）：Material/Element/Load/BC/Contact/Constraint/Field/Analysis（映射到 L4_PH）

#### ② 两层域的映射关系

```
┌──────────────────────────────────────────────────────────────────┐
│  UFC L3_MD 模型域 (14)          →  Abaqus 子程序域 (8)            │
├──────────────────────────────────────────────────────────────────┤
│  Model (模型容器)              →  全局控制                        │
│  Part (部件)                   →  几何/截面分配                   │
│  Assembly (装配)               →  实例管理                        │
│  Mesh (网格)                   →  单元拓扑 (Element)             │
│  Section (截面)                →  材料 - 单元桥接                 │
│  Material (材料)               →  Material (UMAT/VUMAT)          │
│  Amplitude (幅值)              →  Analysis (UAMP)                │
│  LoadBC (载荷边界)             →  Load (DLOAD) + BC (DISP)       │
│  Interaction (相互作用)        →  Contact (UINTER)               │
│  Constraint (约束)             →  Constraint (MPC)               │
│  Step (分析步)                 →  Analysis (UEXTERNALDB)         │
│  Output (输出)                 →  Output (UVARM)                 │
│  Bridge (跨层桥接)             →  L3→L4 数据传递                  │
│  WriteBack (写回)              →  状态更新                        │
└──────────────────────────────────────────────────────────────────┘
```

#### ③ L3_MD × L4_PH × L5_RT 全域正交矩阵（修正版·v2）

```
                         UFC L3_MD 模型域 (14 domains)
      Modl | Part | Asmb | Mesh | Sect | Mat  | Amp  | LoadBC | Intc | Cons | Step | Out  | Brg  | Wbck
    ───────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────
L3_MD│ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc
     │ 模型 │ 部件 │ 装配 │ 网格 │ 截面 │ 材料 │ 幅值 │ 载边 │ 接触 │ 约束 │ 分析步│ 输出 │ 桥接 │ 写回 │
     │ What │ What │ What │ What │ What │ What │ What │ What │ What │ What │ What │ What │ What │ What │
     ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────
L4_PH│  ❌  │  ❌ │  ❌  │ Elem │ Sect │全功能│ Amp  │全功能│ Cont │ Cons │  ❌  │  ❌  │ Brg  │  ❌
     │      │      │      │ 单元 │ 截面 │ 材料 │ 幅值 │ 载边 │ 接触 │ 约束 │      │      │ 桥接 │      │
     │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │ How  │
     ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────
L5_RT│ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx
     │ 模型 │ 部件 │ 装配 │ 单元 │ 截面 │ 材料 │ 幅值 │ 载边 │ 接触 │ 约束 │ 分析 │ 输出 │ 桥接 │ 写回 │
     │ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│
     │When &│When &│When &│When &│When &│When &│When &│When &│When &│When &│When &│When &│When &│When &│
     │Where │Where │Where │Where │Where │Where │Where │Where │Where │Where │Where │Where │Where │Where │
    └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────
                          ↓        ↓        ↓        ↓        ↓        ↓       ↓        ↓
                        UEL    UMAT    DLOAD   DISP   UINTER   MPC   USDFLD  UAMP

图例说明：
- **Desc**: 参数定义（L3 主责）—— 回答"是什么"（What）
- **全功能**: State + Algo + Ctx（L4 主责，对应 Abaqus 子程序计算核心）—— 回答"怎么算"（How）
- **Ctx**: 运行时上下文（L5 主责）—— 回答"何时何地"（When & Where）
- **❌**: 该层不直接实现物理计算，仅通过其他域间接参与
- **Brg**: Bridge 跨层桥接（特殊域，负责 L3→L4 数据传递）
- **Sect**: Section 域在 L4 的截面中心化管理（非计算域）
- **Amp**: Amplitude 在 L4 的插值计算（非计算域）

**关键设计决策（修正）**：
1. **L3_MD** 是**模型数据层**，所有 14 个域都只承载 `Desc`（参数定义）
2. **L4_PH** 是**物理计算层**，但只实现与 Abaqus 子程序直接对应的 8 个域
   - `Mesh → Element`：网格数据转换为单元计算（UEL）
   - `LoadBC → Load + BC`：载荷和边界条件分别计算（DLOAD/DISP）
   - `Interaction → Contact`：接触算法（UINTER）
   - `Constraint → Constraint`：约束方程（MPC）
   - **`Output` 不在 L4 独立成域**：计算结果由 L4 直接传递给 L5 的 Output 模块
3. **L5_RT** 是**求解器适配层**，提供全局运行时上下文
   - **关键修正**：`Step` 在 L5 映射为 `RT_Analysis_Ctx`（分析步控制）
   - **关键修正**：`Output` 在 L5 有独立 `RT_Output_Ctx`，负责从 L4 收集计算结果

---

### L5_RT 层域级详细分类（14 个域完整清单）

**设计原则**：L5_RT 的每个域都承载 `Ctx`（Context，运行时上下文），负责"何时何地执行"

#### L5_RT 完整域集合（按执行引擎语义）

| 域名 | Ctx 类型 | 职责描述 | 对应 Abaqus 接口 | 调用时机 |
|------|---------|---------|----------------|----------|
| **Model_Ctx** | RT_Model_Ctx | 模型全局状态、版本管理 | - | 模型加载时 |
| **Part_Ctx** | RT_Part_Ctx | 部件实例上下文、几何变换 | - | 部件实例化时 |
| **Assembly_Ctx** | RT_Assembly_Ctx | 装配变换矩阵、实例定位 | - | 装配初始化时 |
| **Element_Ctx** | RT_Elem_Ctx | 单元刚度/质量阵、内力向量 | UEL/VUEL | 每个增量步、每个单元 |
| **Section_Ctx** | RT_Section_Ctx | 截面属性路由、积分点规则 | - | 截面查询时 |
| **Material_Ctx** | RT_Mat_Ctx | 历史变量管理、本构路由 | UMAT/VUMAT | 每个增量步、每个积分点 |
| **Amplitude_Ctx** | RT_Amp_Ctx | 幅值曲线插值、时间演化 | UAMP/VUAMP | 载荷/边界条件调用时 |
| **Load_Ctx** | RT_Load_Ctx | 积分点坐标、载荷施加时机 | DLOAD/VDLOAD | 每个积分点 |
| **BC_Ctx** | RT_BC_Ctx | 节点自由度、边界约束施加 | DISP/VDISP | 每个约束节点 |
| **Contact_Ctx** | RT_Contact_Ctx | 滑移量、接触压力、摩擦系数 | UINTER/VUINTER | 每个接触对、每次迭代 |
| **Constraint_Ctx** | RT_Constraint_Ctx | 拉格朗日乘子、约束方程残差 | MPC | 每个约束方程 |
| **Analysis_Ctx** | RT_Analysis_Ctx | 时间步进、收敛控制、外部数据库 | UEXTERNALDB | 分析步开始/结束 |
| **Output_Ctx** | RT_Output_Ctx | 结果采集、变量管理、ODB 写入 | UVARM | 每个增量步结束 |
| **Bridge_Ctx** | RT_Bridge_Ctx | L3→L4 数据桥接状态 | - | Populate 期/查询时 |
| **WriteBack_Ctx** | RT_WriteBack_Ctx | 状态写回白名单、反向更新 | - | 增量步结束后 |

---

#### L5_RT 各域的详细职责分解

##### 1. **Element_Ctx**（单元运行时上下文）

```fortran
TYPE :: RT_Elem_Ctx
  !-- 单元标识
  INTEGER(i4) :: elem_id        ! 单元编号
  INTEGER(i4) :: elem_type      ! 单元类型（C3D8/C3D20 等）
  INTEGER(i4) :: section_id     ! 截面号（枢纽）
  
  !-- 计算结果（从 L4 传递）
  REAL(wp), ALLOCATABLE :: stiffness(:,:)   ! 刚度矩阵 K_e
  REAL(wp), ALLOCATABLE :: mass(:,:)        ! 质量矩阵 M_e
  REAL(wp), ALLOCATABLE :: internal_force(:) ! 内力向量 F_int
  
  !-- 求解器绑定
  INTEGER(i4) :: equation_numbers(:)  ! 整体方程编号
  LOGICAL :: is_active                ! 是否激活（生死单元）
END TYPE
```

**职责**：
- ✅ 存储 L4 计算的单元矩阵（K_e, M_e, F_int）
- ✅ 管理单元与整体方程的映射（equation_numbers）
- ✅ 支持单元生死（is_active）
- ❌ **不包含**B 矩阵计算（这是 L4 的职责）

**调用时机**：
```
DO kstep = 1, nsteps           ! L5: 分析步循环
  DO kinc = 1, nincs           ! L5: 增量步循环
    DO elem = 1, nelements     ! L5: 单元循环
      CALL PH_XXX_UEL_API(...) ! L4: 计算 K_e, F_int
      RT_Elem_Ctx%stiffness = Ke
      RT_Elem_Ctx%internal_force = Fint
    END DO
    CALL AssembleGlobal()      ! L5: 组装总刚
  END DO
END DO
```

---

##### 2. **Material_Ctx**（材料运行时上下文）

```fortran
TYPE :: RT_Mat_Ctx
  !-- 材料标识
  INTEGER(i4) :: mat_id         ! 材料 ID（注册表）
  INTEGER(i4) :: mat_pt_idx     ! 材料点索引
  
  !-- 历史变量（解依赖）
  REAL(wp), ALLOCATABLE :: statev(:)     ! 状态变量数组（SVAR）
  REAL(wp) :: equivalent_plastic_strain  ! 等效塑性应变
  REAL(wp) :: damage_variable            ! 损伤变量
  
  !-- 计算结果（从 L4 传递）
  REAL(wp) :: stress(6)         ! 柯西应力
  REAL(wp) :: tangent(6,6)      ! 切线模量
  
  !-- 本构路由
  INTEGER(i4) :: constitutive_model  ! 本构模型 ID（101=线弹性，201=J2 塑性）
END TYPE
```

**职责**：
- ✅ 存储历史变量（statev）—— 这是 UMAT 的核心
- ✅ 管理本构模型路由（constitutive_model）
- ✅ 保存应力/切线模量计算结果
- ❌ **不包含**本构计算逻辑（这是 L4 的职责）

**调用时机**：
```
DO kinc = 1, nincs
  DO ip = 1, n_integration_points
    strain = ComputeStrain()          ! L4: 计算应变
    CALL PH_XXX_UMAT_API(...)         ! L4: 应力更新
    RT_Mat_Ctx%stress = stress_out    ! L5: 保存结果
    RT_Mat_Ctx%statev = statev_out    ! L5: 更新历史变量
  END DO
END DO
```

---

##### 3. **Analysis_Ctx**（分析控制上下文）

```fortran
TYPE :: RT_Analysis_Ctx
  !-- 时间控制
  REAL(wp) :: time_current      ! 当前时间（TIME(1)）
  REAL(wp) :: time_total        ! 总时间（TIME(2)）
  REAL(wp) :: dtime             ! 时间增量（DTIME）
  
  !-- 增量步控制
  INTEGER(i4) :: current_step   ! 当前分析步编号
  INTEGER(i4) :: current_inc    ! 当前增量步编号
  INTEGER(i4) :: max_incs       ! 最大增量步数
  
  !-- 收敛控制
  LOGICAL :: is_converged       ! 是否收敛
  REAL(wp) :: residual_norm     ! 残差范数
  REAL(wp) :: tolerance         ! 收敛容差
  INTEGER(i4) :: iteration_count! 迭代次数
  
  !-- 外部数据库
  LOGICAL :: external_db_connected
  CHARACTER(LEN=256) :: db_connection_string
END TYPE
```

**职责**：
- ✅ 管理时间步进（time_current, dtime）
- ✅ 控制收敛判据（is_converged, residual_norm）
- ✅ 管理外部数据库连接（UEXTERNALDB）
- ❌ **不包含**平衡方程求解（这是 L2_NM 的职责）

**调用时机**：
```
CALL UEXTERNALDB(LOP=0)  ! L5: 分析步开始，连接数据库

DO kinc = 1, max_incs
  CALL SolveEquilibrium()  ! L2: 求解 K*u = F
  
  IF (residual < tolerance) THEN
    is_converged = .TRUE.
    EXIT
  END IF
END DO

CALL UEXTERNALDB(LOP=3)  ! L5: 分析步结束，断开数据库
```

---

##### 4. **Output_Ctx**（输出管理上下文）

```fortran
TYPE :: RT_Output_Ctx
  !-- 输出请求
  CHARACTER(LEN=64) :: output_vars(:)   ! 输出变量列表 ["S","E","PEEQ"]
  REAL(wp) :: output_interval           ! 输出间隔
  INTEGER(i4) :: output_format          ! 1=ODB, 2=TXT, 3=CSV
  
  !-- 结果采集（从 L4 收集）
  REAL(wp), ALLOCATABLE :: stress_history(:,:,:)   ! 应力时程
  REAL(wp), ALLOCATABLE :: strain_history(:,:,:)   ! 应变时程
  REAL(wp), ALLOCATABLE :: reaction_forces(:,:)    ! 支反力
  
  !-- ODB 写入
  INTEGER(i4) :: odb_file_id
  LOGICAL :: is_writing
END TYPE
```

**职责**：
- ✅ 从 L4 收集计算结果（stress, strain, etc.）
- ✅ 管理输出频率和格式
- ✅ 写入 ODB 文件或 TXT 报告
- ❌ **不包含**物理计算（这是 L4 的职责）

**数据流**：
```
L4_PH/UMAT (应力) ─┐
L4_PH/UEL (刚度) ─┼→ L5_RT/Output_Ctx ─→ ODB 文件
L4_PH/Contact (力) ─┘
```

---

#### L5_RT 的特殊性：为什么需要 14 个域？

**问题**：L4 只有 8 个子程序域，为什么 L5 需要 14 个域？

**答案**：L5 是"执行引擎"，需要管理**整个模型的运行时状态**，而不仅仅是计算。

**对比**：
```
L4_PH (8 个子程序域):
  - Material (UMAT)    ← 只负责材料本构计算
  - Element (UEL)      ← 只负责单元刚度计算
  - Load (DLOAD)       ← 只负责载荷计算
  - ...

L5_RT (14 个运行时域):
  - Model_Ctx          ← 管理整个模型的全局状态
  - Assembly_Ctx       ← 管理装配变换（L4 不需要）
  - Analysis_Ctx       ← 管理时间步进（L4 不需要）
  - Output_Ctx         ← 管理结果输出（L4 不需要）
  - ... + Material_Ctx/Element_Ctx/Load_Ctx (对应 L4)
```

**设计哲学**：
- L4 专注"计算"（How）
- L5 负责"调度"（When & Where）+ "管理"（What's happening）

### 2.2 完整映射矩阵

### 2.2.1 Material 域（材料本构）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **UMAT** | Standard | L4_PH/Material/PH_XXX_UMAT | 机械本构（已完成✅） |
| **VUMAT** | Explicit | L4_PH/Material/PH_XXX_VUMAT | 显式机械本构 |
| **UMATHT** | Standard | L4_PH/Material/PH_XXX_UMATHT | 热本构 |
| **CREEP** | Standard | L4_PH/Material/PH_XXX_Creep | 蠕变行为 |
| **UHARD** | Standard | L4_PH/Material/PH_XXX_Hardening | 屈服硬化 |
| **UHYPEL** | Standard | L4_PH/Material/PH_XXX_Hypoelastic |  hypoelastic |
| **UHYPER** | Standard | L4_PH/Material/PH_XXX_Hyperelastic | 超弹性 |
| **VUHARD** | Explicit | L4_PH/Material/PH_XXX_VUHardening | 显式屈服硬化 |
| **VUANISOHYPER_INV** | Explicit | L4_PH/Material/PH_XXX_AnisoHyperInv | 各向异性超弹（不变量） |
| **VUANISOHYPER_STRAIN** | Explicit | L4_PH/Material/PH_XXX_AnisoHyperStrain | 各向异性超弹（Green 应变） |
| **VUEOS** | Explicit | L4_PH/Material/PH_XXX_EOS | 状态方程 |
| **VFABRIC** | Explicit | L4_PH/Material/PH_XXX_Fabric | 织物材料 |
| **VUVISCOSITY** | Explicit | L4_PH/Material/PH_XXX_Viscosity | 粘度模型 |
| **UMULLINS / VUMULLINS** | Both | L4_PH/Material/PH_XXX_Mullins | Mullins 效应损伤 |
| **UCREEPNETWORK / VUCREEPNETWORK** | Both | L4_PH/Material/PH_XXX_CreepNetwork | 并行流变框架蠕变 |
| **UTRS / VUTRS** | Both | L4_PH/Material/PH_XXX_TimeShift | 粘弹性时间平移函数 |
| **UANISOHYPER_INV** | Standard | L4_PH/Material/PH_XXX_AnisoHyperInv | 各向异性超弹 |
| **UANISOHYPER_STRAIN** | Standard | L4_PH/Material/PH_XXX_AnisoHyperStrain | 各向异性超弹（Green 应变） |

**L3_MD 对应类型定义：**
- `MD_Mat_Types.f90` - 基类（Desc/State/Algo）
- `MD_Mat_XXX.f90` - 具体材料模型扩展

**L4_PH 对应计算模板：**
- `PH_XXX_UMAT.f90` ✅ - 通用机械本构模板
- `PH_XXX_VUMAT.f90` - 显式版本
- `PH_XXX_Thermal.f90` - 热 - 力耦合本构

---

### 2.2.2 Element 域（单元行为）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **UEL** | Standard | L4_PH/Element/PH_XXX_UEL | 用户自定义单元（已完成✅） |
| **VUEL** | Explicit | L4_PH/Element/PH_XXX_VUEL | 显式用户单元 |
| **UELMAT** | Standard | L4_PH/Element/PH_XXX_UelMat | 访问 Abaqus 材料的 UEL |

**L3_MD 对应类型定义：**
- `MD_Elem_Types.f90` - 单元拓扑/属性描述

**L4_PH 对应计算模板：**
- `PH_XXX_UEL.f90` ✅ - 通用 UEL 模板
- `PH_XXX_VUEL.f90` - 显式版本

---

### 2.2.3 Load 域（载荷施加）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **DLOAD** | Standard | L4_PH/Load/PH_XXX_DLOAD | 分布载荷（压力/体力）✅ |
| **VDLOAD** | Explicit | L4_PH/Load/PH_XXX_VDLOAD | 显式分布载荷 |
| **CLOAD** | Standard | L4_PH/Load/PH_XXX_CLOAD | 集中力（节点力） |
| **VCLOAD** | Explicit | L4_PH/Load/PH_XXX_VCLOAD | 显式集中力 |
| **FILM** | Standard | L4_PH/Load/PH_XXX_Film | 对流换热系数 |
| **HETVAL** | Standard | L4_PH/Load/PH_XXX_Hetval | 内部热源生成 |
| **VDFLUX** | Explicit | L4_PH/Load/PH_XXX_VDFLUX | 显式热通量 |
| **DFLUX** | Standard | L4_PH/Load/PH_XXX_DFLUX | 热通量/质量扩散通量 |
| **UTRACLOAD** | Standard | L4_PH/Load/PH_XXX_TracLoad | 非均匀牵引载荷 |
| **UDECURRENT** | Standard | L4_PH/Load/PH_XXX_EddyCurrent | 涡电流密度 |
| **UDSECURRENT** | Standard | L4_PH/Load/PH_XXX_SurfaceCurrent | 表面电流密度 |

**L3_MD 对应类型定义：**
- `MD_Load_Types.f90` ✅ - 载荷参数定义

**L4_PH 对应计算模板：**
- `PH_XXX_Load.f90` ✅ - 通用载荷模板
- `PH_XXX_DLOAD.f90` - 分布载荷专用
- `PH_XXX_ThermalLoad.f90` - 热载荷专用

---

### 2.2.4 BC 域（边界条件）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **DISP** | Standard | L4_PH/BC/PH_XXX_DISP | 位移/速度/加速度边界✅ |
| **VDISP** | Explicit | L4_PH/BC/PH_XXX_VDISP | 显式位移边界 |
| **UDEMPOTENTIAL** | Standard | L4_PH/BC/PH_XXX_MagPotential | 磁矢量势边界 |
| **UPRESS** | Standard | L4_PH/BC/PH_XXX_PressureBC | 等效压力应力边界 |
| **UTEMP** | Standard | L4_PH/BC/PH_XXX_TempBC | 温度边界 |
| **UPOREP** | Standard | L4_PH/BC/PH_XXX_PorePressureBC | 初始孔隙压力 |
| **UMASFL** | Standard | L4_PH/BC/PH_XXX_MassFlowBC | 质量流率边界 |
| **SMACfdUserPressureBC** | CFD | L4_PH/BC/PH_XXX_CFD_PressureBC | CFD 压力边界 |
| **SMACfdUserVelocityBC** | CFD | L4_PH/BC/PH_XXX_CFD_VelocityBC | CFD 速度边界 |

**L3_MD 对应类型定义：**
- `MD_BC_Types.f90` ✅ - BC 参数定义

**L4_PH 对应计算模板：**
- `PH_XXX_BC.f90` ✅ - 通用 BC 模板
- `PH_XXX_DISP.f90` - 位移边界专用

---

### 2.2.5 Contact 域（接触相互作用）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **UINTER** | Standard | L4_PH/Contact/PH_XXX_UINTER | 全接触行为（法向 + 切向）✅ |
| **VUINTER** | Explicit | L4_PH/Contact/PH_XXX_VUINTER | 显式全接触 |
| **VUINTERACTION** | Explicit | L4_PH/Contact/PH_XXX_VUInteraction | 通用接触算法 |
| **UFRIC / VFRIC** | Both | L4_PH/Contact/PH_XXX_UFric | 摩擦系数定义✅ |
| **VFRIC_COEF / FRIC_COEF** | Both | L4_PH/Contact/PH_XXX_FricCoeff | 摩擦系数专用 |
| **UCOUL** | Standard | L4_PH/Contact/PH_XXX_UCoul | 库伦临界剪应力 |
| **GAPCON** | Standard | L4_PH/Contact/PH_XXX_GapCon | 间隙热传导 |
| **GAPELECTR** | Standard | L4_PH/Contact/PH_XXX_GapElectr | 间隙电传导 |
| **VGAPCON** | Explicit | L4_PH/Contact/PH_XXX_VGapCon | 显式间隙热传导 |

**L3_MD 对应类型定义：**
- `MD_Contact_Types.f90` ✅ - 接触对参数定义

**L4_PH 对应计算模板：**
- `PH_XXX_Contact.f90` ✅ - 通用接触模板
- `PH_XXX_Friction.f90` - 摩擦专用

---

### 2.2.6 Constraint 域（约束方程）

---

**专题讨论：Field 域的设计必要性** → 见章节 **6.3**

---

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **MPC** | Standard | L4_PH/Constraint/PH_XXX_MPC | 多点约束方程 |
| **UMESHMOTION** | Standard | L4_PH/Constraint/PH_XXX_MeshMotion | 自适应网格运动 |
| **UMOTION** | Standard | L4_PH/Constraint/PH_XXX_Motion | 空腔辐射/稳态输运运动 |
| **RSURFU** | Standard | L4_PH/Constraint/PH_XXX_RigidSurface | 刚性表面定义 |

**L3_MD 对应类型定义：**
- `MD_Constraint_Types.f90` - 约束参数定义（待创建）

**L4_PH 对应计算模板：**
- `PH_XXX_Constraint.f90` - 通用约束模板（待创建）

---

### 2.2.7 Field 域（场变量管理）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **USDFLD** | Standard | L4_PH/Field/PH_XXX_USDFLD | 重定义场变量 |
| **VUSDFLD** | Explicit | L4_PH/Field/PH_XXX_VUSDFLD | 显式场变量 |
| **UFIELD** | Standard | L4_PH/Field/PH_XXX_UField | 预定义场变量 |
| **VUFIELD** | Explicit | L4_PH/Field/PH_XXX_VUField | 显式预定义场 |
| **SDVINI** | Standard | L4_PH/Field/PH_XXX_SDVIni | 初始状态变量场 |
| **SIGINI** | Standard | L4_PH/Field/PH_XXX_SigIni | 初始应力场 |
| **HARDINI** | Standard | L4_PH/Field/PH_XXX_HardIni | 初始等效塑性应变 |
| **VOIDRI** | Standard | L4_PH/Field/PH_XXX_VoidRi | 初始孔隙比 |
| **ORIENT** | Standard | L4_PH/Field/PH_XXX_Orient | 材料方向/局部坐标系 |

**L3_MD 对应类型定义：**
- `MD_Field_Types.f90` - 场变量参数定义（待创建）

**L4_PH 对应计算模板：**
- `PH_XXX_Field.f90` - 通用场变量模板（待创建）

---

### 2.2.8 Analysis 域（分析控制）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **UAMP** | Standard | L5_RT/Analysis/RT_XXX_UAmp | 幅值曲线定义 |
| **VUAMP** | Explicit | L5_RT/Analysis/RT_XXX_VUAmp | 显式幅值曲线 |
| **UEXTERNALDB** | Standard | L5_RT/Analysis/RT_XXX_ExternalDB | 外部数据库管理 |
| **VEXTERNALDB** | Explicit | L5_RT/Analysis/RT_XXX_VExternalDB | 显式外部数据库 |
| **URDFIL** | Standard | L5_RT/Analysis/RT_XXX_ReadResults | 读取结果文件 |
| **UWAVE / VWAVE** | Both | L5_RT/Analysis/RT_XXX_Wave | 波浪运动学（Aqua） |
| **UCORR** | Standard | L5_RT/Analysis/RT_XXX_CrossCorr | 随机响应互相关 |
| **UPSD** | Standard | L5_RT/Analysis/RT_XXX_PSD | 随机响应功率谱密度 |

**L5_RT 对应类型定义：**
- `RT_Analysis_Types.f90` - 分析控制类型（待创建）

---

### 2.2.9 Special Domain（特殊功能）

| Abaqus 子程序 | Standard/Explicit | UFC Layer-Domain-Module | 功能描述 |
|--------------|------------------|------------------------|---------|
| **UVARM** | Standard | L5_RT/Output/RT_XXX_UVarm | 自定义单元输出变量 |
| **UGENS** | Standard | L4_PH/Special/PH_XXX_ShellGen | 壳截面行为 |
| **UFLUID** | Standard | L4_PH/Special/PH_XXX_FluidElem | 静水流体单元 |
| **UFLUIDCONNECTORLOSS** | Standard | L4_PH/Special/PH_XXX_FluidLoss | 流体管道连接损失 |
| **UFLUIDCONNECTORVALVE** | Standard | L4_PH/Special/PH_XXX_FluidValve | 流体阀门控制 |
| **UFLUIDPIPEFRICTION** | Standard | L4_PH/Special/PH_XXX_FluidPipeFric | 流体管摩擦 |
| **UFLUIDLEAKOFF** | Standard | L4_PH/Special/PH_XXX_FluidLeakoff | 孔隙压力粘聚力渗漏 |
| **VUFLUIDEXCH** | Explicit | L4_PH/Special/PH_XXX_VFluidExch | 流体交换质量流率 |
| **VUFLUIDEXCHEFFAREA** | Explicit | L4_PH/Special/PH_XXX_VFluidEffArea | 流体交换有效面积 |
| **VUCHARLENGTH** | Explicit | L4_PH/Special/PH_XXX_CharLength | 特征单元长度 |
| **UXFEMNONLOCALWEIGHT** | Standard | L4_PH/Special/PH_XXX_XFEMWeight | XFEM 裂纹扩展权重函数 |

---

## 三、跨层职责详解（以 Load 域为例）

### 3.1 L3_MD/Load：参数定义层

**核心类型**：
```fortran
MODULE MD_Load_Types
  TYPE, PUBLIC :: MD_Load_Base_Desc
    !-- 身份标识
    INTEGER(i4)       :: load_id   = 0
    INTEGER(i4)       :: load_family = 0  ! LOAD_FAMILY_XXX
    CHARACTER(LEN=64) :: load_name = ''
    
    !-- 载荷参数（What）
    REAL(wp) :: magnitude      = 0.0_wp  ! 幅值
    REAL(wp) :: scale_factor   = 1.0_wp  ! 缩放因子
    INTEGER  :: time_dependence = 0     ! 0=static, 1=time-dependent
    
    !-- 类型特定参数
    INTEGER :: load_type       ! P1NU/BXNU等
    INTEGER :: element_face    ! 作用面编号
  END TYPE
END MODULE
```

**职责**：
- ✅ 定义载荷的数学描述
- ✅ 提供参数验证接口（ValidateProps）
- ✅ 支持从 INP 文件初始化
- ❌ **不包含**时空分布计算逻辑

---

### 3.2 L4_PH/Load：物理计算层

**核心类型**：
```fortran
MODULE PH_Load_Types
  !-- 上下文（ driving inputs）
  TYPE, PUBLIC :: PH_Load_Base_Ctx
    REAL(wp) :: coords(3)        ! 积分点坐标
    REAL(wp) :: time_current     ! 当前时间
    REAL(wp) :: time_total       ! 总时间
    INTEGER  :: elem_id          ! 单元号
    INTEGER  :: integ_pt_id      ! 积分点号
  END TYPE
  
  !-- 算法控制
  TYPE, PUBLIC :: PH_Load_Base_Algo
    INTEGER :: max_iter = 10
    REAL(wp) :: tolerance = 1.0e-6_wp
  END TYPE
  
  !-- 状态历史
  TYPE, PUBLIC, EXTENDS(MD_Load_Base_State) :: PH_Mat_XXX_Load_State
    REAL(wp) :: accumulated = 0.0_wp  ! 累积量
    REAL(wp) :: ivar1 = 0.0_wp        ! 模型特定 ISV
  END TYPE
END MODULE
```

**计算核心**：
```fortran
MODULE PH_XXX_Load
CONTAINS
  SUBROUTINE PH_XXX_Load_API(MD_Load_Desc, PH_Load_Ctx, PH_Load_State, &
                              MD_Load_Algo, PH_Load_Algo, RT_Com_Ctx, &
                              load_value)
    !-- 输入
    TYPE(MD_Load_Base_Desc), INTENT(IN)  :: MD_Load_Desc
    TYPE(PH_Load_Base_Ctx),  INTENT(IN)  :: PH_Load_Ctx
    TYPE(PH_Load_State),     INTENT(INOUT):: PH_Load_State
    
    !-- 输出
    REAL(wp), INTENT(OUT) :: load_value
    
    !-- 计算逻辑（How）
    x = PH_Load_Ctx%coords(1)
    t = RT_Com_Ctx%time_step
    
    ! 空间分布函数
    spatial_factor = f(x, y, z)
    
    ! 时间演化函数
    time_factor = g(t)
    
    ! 最终载荷
    load_value = MD_Load_Desc%magnitude * &
                 MD_Load_Desc%scale_factor * &
                 spatial_factor * time_factor
    
    ! 更新历史
    PH_Load_State%accumulated = load_value
  END SUBROUTINE
END MODULE
```

**职责**：
- ✅ 实现时空分布计算
- ✅ 管理历史依赖变量（SVAR）
- ✅ 提供收敛判据
- ❌ **不直接调用**求解器 API

---

### 3.3 L5_RT/Load：求解器适配层

**核心类型**：
```fortran
MODULE RT_Com_Types
  TYPE, PUBLIC :: RT_Com_Base_Ctx
    REAL(wp) :: time_step      ! TIME(1)
    REAL(wp) :: time_total     ! TIME(2)
    REAL(wp) :: dtime          ! DTIME
    INTEGER  :: kstep          ! KSTEP
    INTEGER  :: kinc           ! KINC
    LOGICAL  :: nlgeom         ! NLGEOM flag
  END TYPE
END MODULE
```

**适配器模式**：
```fortran
MODULE RT_Load_Adapter
CONTAINS
  SUBROUTINE RT_Apply_DLOAD_To_Abaqus(load_value, elem_id, integ_pt)
    !-- 绑定到 Abaqus DLOAD 接口
    INTERFACE
      SUBROUTINE DLOAD(F, KSTEP, KINC, TIME, NOEL, NPT, ...)
    END INTERFACE
    
    F = load_value  ! 从 L4 计算结果传递
    NOEL = elem_id
    NPT = integ_pt
  END SUBROUTINE
END MODULE
```

**职责**：
- ✅ 提供时间/增量步信息
- ✅ 绑定到求解器原生 API
- ✅ 管理外部数据库交互
- ❌ **不包含**物理计算逻辑

---

## 四、实施路线图

### Phase 1: 核心域（已完成✅）
- [x] Material 域：`PH_XXX_UMAT.f90`
- [x] Element 域：`PH_XXX_UEL.f90`
- [x] Load 域：`PH_XXX_Load.f90`
- [x] BC 域：`PH_XXX_BC.f90`
- [x] Contact 域：`PH_XXX_Contact.f90`

### Phase 2: 扩展域（下一步）
- [ ] Constraint 域：`PH_XXX_MPC.f90`
- [ ] Field 域：`PH_XXX_USDFLD.f90`
- [ ] Analysis 域：`RT_XXX_UAmp.f90`

### Phase 3: 高级功能
- [ ] 显式版本（V 前缀系列）
- [ ] 多物理场耦合（热 - 力/流 - 固/电磁）
- [ ] 特殊单元（流体/管道/连接器）

---
- [x] Material 域：`PH_XXX_UMAT.f90`
- [x] Element 域：`PH_XXX_UEL.f90`
- [x] Load 域：`PH_XXX_Load.f90`
- [x] BC 域：`PH_XXX_BC.f90`
- [x] Contact 域：`PH_XXX_Contact.f90`

### Phase 2: 扩展域（下一步）
- [ ] Constraint 域：`PH_XXX_MPC.f90`
- [ ] Field 域：`PH_XXX_USDFLD.f90`
- [ ] Analysis 域：`RT_XXX_UAmp.f90`

### Phase 3: 高级功能
- [ ] 显式版本（V 前缀系列）
- [ ] 多物理场耦合（热 - 力/流 - 固/电磁）
- [ ] 特殊单元（流体/管道/连接器）

---

## 五、模板目录结构

```
UFC/ufc_core/docs/templates/
├── MD_Mat_Types.f90              ✅
├── PH_Mat_Types.f90              ✅
├── MD_Elem_Types.f90             ✅
├── PH_Elem_Types.f90             ✅
├── MD_Load_Types.f90             ✅
├── PH_Load_Types.f90             ✅
├── MD_BC_Types.f90               ✅
├── PH_BC_Types.f90               ✅
├── MD_Contact_Types.f90          ✅
├── PH_Contact_Types.f90          ✅
├── PH_XXX_UMAT.f90               ✅
├── PH_XXX_UEL.f90                ✅
├── PH_XXX_Load.f90               ✅
├── PH_XXX_BC.f90                 ✅
├── PH_XXX_Contact.f90            ✅
│
├── [待开发]
├── MD_Constraint_Types.f90       ⏳
├── PH_Constraint_Types.f90       ⏳
├── MD_Field_Types.f90            ⏳
├── PH_Field_Def.f90            ⏳
├── RT_Analysis_Types.f90         ⏳
└── PH_XXX_VUMAT.f90              ⏳ (显式版本)
```

---

## 六、关键设计决策

### 6.1 显式 vs 隐式分离
- **Standard 系列**：无 V 前缀，隐式积分格式
- **Explicit 系列**：V 前缀，显式中心差分格式
- **共用类型**：Desc/State 可复用，Algo/Ctx 分路径实现

### 6.2 状态变量（SVAR）支持
所有 State 类型必须包含：
```fortran
TYPE, PUBLIC, EXTENDS(MD_XXX_Base_State) :: PH_XXX_State
  REAL(wp), ALLOCATABLE :: statev(:)  ! 解依赖状态变量
  REAL(wp) :: accumulated = 0.0_wp    ! 累积量
  ! ... 模型特定 ISVs
END TYPE
```

### 6.3 接口契约一致性
所有计算子程序遵循统一签名：
```fortran
SUBROUTINE PH_XXX_API(MD_Desc, PH_Ctx, PH_State, MD_Algo, PH_Algo, RT_Ctx, output_value)
```

---

## 七、下一步行动

1. **优先级排序**：根据项目需求选择 Top 5 高频子程序
   - MPC（约束方程）
   - USDFLD（场变量）
   - UAMP（幅值曲线）
   - UVARM（自定义输出）
   - VUMAT（显式材料）

2. **模板细化**：为每个子程序创建专用模板（类似 PH_XXX_UMAT.f90）

3. **实例验证**：选择 1-2 个典型算例进行端到端验证

4. **文档化**：将本映射表同步至 UFC 官方文档体系

---

**文档版本**: v1.0  
**创建日期**: 2026-03-28  
**维护者**: UFC Architecture Team
