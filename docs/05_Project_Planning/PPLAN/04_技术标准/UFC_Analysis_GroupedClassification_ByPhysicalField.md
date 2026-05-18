# UFC 分析类型按物理场分组分类规范

> **版本**: v2.0  
> **创建日期**: 2026-04-04  
> **核心观点**: 在正交设计基础上，新增"物理场维度"作为第二层分类，对应材料调用、单元类型约束  
> **分析类型总数**: **33 种**（Standard + Explicit + CFD + Acoustic + EM + Coupled）

---

## 一、引言：从正交设计升级到场基分组

### 1.1 前置知识：正交架构

```
分析步 = Time × Method  （12 种）
分析类型 = 分析步 + 物理场  （33 种）
```

**原来的维度**（4D 正交）：

- D1: 求解器（4-5 种）
- D2: 分析步（12 种）
- D3: 单元族（14 种）
- D4: 材料族（11 种）

**新增维度**（物理场分组）：

- 层级0：单场 vs 多场
- 层级1：与结构相关 vs 无关
- 层级2：场数量（单/双/三/多）
- 映射：→ 材料调用链、单元约束、求解策略

---

## 二、ABAQUS 分析类型精确统计

### 2.1 总量统计

```
┌──────────────────────────────────────────────────────────────────┐
│  分析类型总数 = 33 种                                             │
├──────────────────────────────────────────────────────────────────┤
│  结构单场      9 种  （STATIC/DYNAMIC/MODAL/FREQUENCY/BUCKLE）   │
│  纯热分析      1 种  （HEAT_TRANSFER）                            │
│  频域分析      4 种  （MODAL_DYNAMIC/RANDOM_RESPONSE/等）        │
│  声学单场      1 种  （ACOUSTIC）                                 │
│  电磁单场      1 种  （ELECTROMAGNETIC）                          │
│  热-结构双场   2 种  （COUPLED_TEMP_DISP/DYN_CTD_EXPLICIT）      │
│  三场及以上    3 种  （COUPLED_THERMAL_ELEC/TES/PIEZO）          │
│  岩土土力学    2 种  （GEOSTATIC/SOILS）                          │
│  其他特殊      5 种  （VISCO/ANNEAL/MASS_DIFFUSION/等）          │
└──────────────────────────────────────────────────────────────────┘

说明：包括 Standard/Explicit/CFD/Acoustic/EM 所有官方求解器
不含：用户 UMAT/VUMAT/UEL（属于参数化扩展，不计入基础类型数）
```

---

## 三、按物理场维度的 9 组分类

### G1：结构单场（力学单独） — 9 种

**特征**：

- 仅涉及位移/速度/加速度等力学 DOF
- 不含热/电/磁等其他物理场
- 可以是线性或非线性


| #   | 分析类型    | PROC_ID | ABAQUS 关键词               | 时间特性 | 求解器 | 材料约束      |
| --- | ------- | ------- | ------------------------ | ---- | --- | --------- |
| 1   | 静力非线性   | 1       | `*STATIC`                | 准静态  | STD | 力学+塑性/损伤  |
| 2   | Riks弧长法 | 2       | `*STATIC, RIKS`          | 准静态  | STD | 力学+弹性（切线） |
| 3   | 动力隐式    | 11      | `*DYNAMIC`               | 瞬态   | STD | 力学+惯性     |
| 4   | 动力显式    | 12      | `*DYNAMIC, EXPLICIT`     | 瞬态   | EXP | 力学（显式格式）  |
| 5   | 模态分析    | 21      | `*FREQUENCY`             | 无时间  | STD | 线性弹性      |
| 6   | 频率响应    | 22      | `*FREQUENCY`             | 频域   | STD | 弹性+阻尼     |
| 7   | 屈曲分析    | 23      | `*BUCKLE`                | 无时间  | STD | 预应力弹性     |
| 8   | 稳态动力学   | 24      | `*STEADY STATE DYNAMICS` | 频域   | STD | 弹性+阻尼     |
| 9   | 复频率     | 29      | `*COMPLEX FREQUENCY`     | 频域   | STD | 复数阻尼矩阵    |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Mechanics(sigma, D_tang, sdv_history)  ! 族01-08 力学材料
! 不调用：热、电磁、声学材料
```

**L5_RT 求解器选择**：

```
RT_SOLVER_IMPLICIT (STD) 或 RT_SOLVER_EXPLICIT (EXP)
```

**单元约束**：

```
允许：C3D、CPS、CAX、S（壳）、B（梁）、T（桁架）
禁止：DC（热单元）、AC（声学单元）、EM（电磁单元）
```

---

### G2：纯热分析（无结构） — 1 种

**特征**：

- 只有温度场 DOF，无位移
- 热传导方程主导
- 不含力学/电磁耦合


| #   | 分析类型 | PROC_ID | ABAQUS 关键词       | 时间特性  | 求解器 | 材料约束  |
| --- | ---- | ------- | ---------------- | ----- | --- | ----- |
| 1   | 热传导  | 31      | `*HEAT TRANSFER` | 稳态/瞬态 | THM | 热导+比热 |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Thermal(k_cond, cp, rho)  ! 族09 热材料
! 不调用：力学、电磁材料
```

**单元约束**：

```
允许：DC（热传导单元）、标量场单元
禁止：C3D（结构）、S（壳）、EM（电磁）
```

---

### G3：频域分析（频率扫描，无时间推进） — 4 种

**特征**：

- 在频率域求解，不含时间推进
- 线性响应占主导
- 可含阻尼


| #   | 分析类型  | PROC_ID | ABAQUS 关键词                | 求解方法   | 求解器 | 材料约束    |
| --- | ----- | ------- | ------------------------- | ------ | --- | ------- |
| 1   | 模态动力学 | 25      | `*MODAL DYNAMIC`          | 模态叠加   | STD | 线性弹性+阻尼 |
| 2   | 随机响应  | 27      | `*RANDOM RESPONSE`        | PSD 积分 | STD | 线性弹性+阻尼 |
| 3   | 反应谱   | 28      | `*RESPONSE SPECTRUM`      | 谱组合    | STD | 线性弹性    |
| 4   | 稳态传输  | 62      | `*STEADY STATE TRANSPORT` | 频率迭代   | STD | 扩散系数    |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Stiffness_Damping(E, nu, zeta)  ! 频域用参数
! 不更新 SDV（状态无关变量）
```

---

### G4：声学单场（波传播） — 1 种

**特征**：

- 声压/粒子速度作为基本未知数
- Helmholtz 方程主导
- 流体介质


| #   | 分析类型 | PROC_ID | ABAQUS 关键词  | 时间特性 | 求解器 | 材料约束   |
| --- | ---- | ------- | ----------- | ---- | --- | ------ |
| 1   | 声学   | 81      | `*ACOUSTIC` | 频域   | ACU | 声阻抗+声速 |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Acoustic(rho, c_sound)  ! 族10 声学材料
```

**单元约束**：

```
允许：AC（声学单元）
禁止：C3D（结构）、DC（热）、EM（电磁）
```

---

### G5：电磁单场 — 1 种

**特征**：

- 电位/磁通量作为基本未知数
- Maxwell 方程主导
- 独立求解器（Abaqus/EM）


| #   | 分析类型 | PROC_ID | ABAQUS 关键词         | 时间特性  | 求解器 | 材料约束     |
| --- | ---- | ------- | ------------------ | ----- | --- | -------- |
| 1   | 电磁   | 71      | `*ELECTROMAGNETIC` | 瞬态/稳态 | EMF | 导电率+介电常数 |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Electromagnetic(sigma_e, epsilon_r)  ! 族特定 EM 材料
```

---

### G6：热-结构双场耦合 — 2 种

**特征**：

- 温度→热膨胀应变→力学应力
- 力学做功→焦耳热→温度
- 弱耦合（交错法）或强耦合（单块）


| #   | 分析类型        | PROC_ID | ABAQUS 关键词                          | 时间特性 | 耦合策略      | 求解器 | 材料约束   |
| --- | ----------- | ------- | ----------------------------------- | ---- | --------- | --- | ------ |
| 1   | 热-力耦合       | 32      | `*COUPLED TEMPERATURE-DISPLACEMENT` | 瞬态   | Staggered | STD | 力学+热膨胀 |
| 2   | 动力热-力耦合（显式） | 34      | `*DYNAMIC, CTD`                     | 瞬态   | 显式推进      | EXP | 力学+热膨胀 |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Mechanics(sigma, D_tang, alpha_T)   ! 力学+热膨胀
CALL L4_PH_Material_Thermal(k, cp)                       ! 热参数
! 耦合项：σ_thermal = C : α·ΔT
```

**单元约束**：

```
允许：C3D、CPS、CAX、S（含热-力耦合）
禁止：纯热单元 DC、纯声学单元 AC
```

---

### G7：热-电-结构三场及以上耦合 — 3 种

**特征**：

- 三个或更多物理场同时耦合
- 耦合矩阵阶数高（3×3 Block 或以上）
- 强耦合，需迭代收敛


| #   | 分析类型   | PROC_ID | ABAQUS 关键词                               | 耦合场   | 时间特性  | 求解器 | 耦合策略                 |
| --- | ------ | ------- | ---------------------------------------- | ----- | ----- | --- | -------------------- |
| 1   | 热-电耦合  | 33      | `*COUPLED THERMAL-ELECTRICAL`            | T-E   | 瞬态    | STD | Staggered            |
| 2   | 热-电-结构 | 35      | `*COUPLED THERMAL-ELECTRICAL-STRUCTURAL` | T-E-U | 瞬态    | STD | Staggered/Monolithic |
| 3   | 压电     | 51      | `*PIEZOELECTRIC`                         | E-U   | 瞬态/稳态 | STD | Monolithic           |


**L4_PH 调用链**（以 G7-2 为例）：

```fortran
! 电场方程：∇·(σ_e ∇V) = 0
CALL L4_PH_Material_Electromagnetic_Conductivity(sigma_e)

! 热场方程：ρ c_p ∂T/∂t = ∇·(k ∇T) + Q_joule
CALL L4_PH_Material_Thermal(k, cp)
! 焦耳热源：Q_joule = J²/σ_e = |∇V|²·σ_e

! 力学方程：∇·σ + b = 0
CALL L4_PH_Material_Mechanics_With_Thermal(E, alpha_T)
! 热膨胀：ε_thermal = α·(T - T_ref)·I
```

---

### G8：岩土/土力学（力学变体） — 2 种

**特征**：

- 有效应力原理
- 孔隙流体耦合（可选）
- 渗流方程（非线性）


| #   | 分析类型      | PROC_ID | ABAQUS 关键词   | 时间特性 | 求解器 | 材料约束    |
| --- | --------- | ------- | ------------ | ---- | --- | ------- |
| 1   | 地应力（初始平衡） | 41      | `*GEOSTATIC` | 准静态  | STD | 岩土塑性材料  |
| 2   | 土力学（渗流耦合） | 42      | `*SOILS`     | 瞬态   | STD | 岩土+孔压耦合 |


**L4_PH 调用链**：

```fortran
CALL L4_PH_Material_Geomechanics(DP/MC/CAM/Concrete)  ! 族03 岩土材料
! 孔压效应：σ'eff = σ_total - u·I
```

**单元约束**：

```
允许：C3D、CAX（岩土专用）
特殊：孔隙单元（含压力 DOF）
```

---

### G9：其他特殊分析 — 5 种

**特征**：

- 特定时间相关或工况机制
- 通常是上述分类的变体或扩展


| #      | 分析类型  | PROC_ID | ABAQUS 关键词               | 时间特性   | 求解器 | 材料约束     |
| ------ | ----- | ------- | ------------------------ | ------ | --- | -------- |
| 1      | 蠕变    | 43      | `*VISCO`                 | 准静态/瞬态 | STD | 族06 蠕变材料 |
| 2      | 退火热处理 | 44      | `*ANNEAL`                | 准静态    | STD | 热-力+路径相关 |
| 3      | 质量扩散  | 61      | `*MASS DIFFUSION`        | 瞬态/稳态  | STD | 扩散系数     |
| 4      | 子结构   | 91      | `*SUBSTRUCTURE`          | 通用     | STD | 线性约化     |
| （前面已列） | 稳态响应  | 24      | `*STEADY STATE DYNAMICS` | 频域     | STD | 线性弹性     |


---

## 四、物理场分组对 L4_PH 的约束规则

### 4.1 材料调用决策表

```fortran
INTERFACE
  SUBROUTINE L4_PH_Material_Dispatcher( &
    group_id, proc_id, mat_id, elem_type, &
    sigma, D_tang, sdv_history, args_in)
  
    INTEGER :: group_id  ! G1-G9
    INTEGER :: proc_id   ! PROC_*
    INTEGER :: mat_id    ! 材料 ID
    INTEGER :: elem_type ! 单元类型
    
    ! 决策逻辑
    SELECT CASE(group_id)
    
    CASE(G1_STRUCTURAL)  ! 结构单场
      CALL L4_PH_Mat_Mechanics_Dispatch(mat_id, ...)
      ! 允许族：01-08（力学）
      ! 禁止族：09-11（热/声/电）
    
    CASE(G2_THERMAL_ONLY)  ! 纯热
      CALL L4_PH_Mat_Thermal_Dispatch(mat_id, ...)
      ! 允许族：09（热）
      ! 禁止族：01-08, 10-11
    
    CASE(G6_THERMO_MECHANICAL)  ! 热-力耦合
      CALL L4_PH_Mat_Mechanics_With_Thermal(mat_id, ...)
      ! 允许族：01-08 + 09（热膨胀）
      
    CASE(G7_MULTI_FIELD)  ! 三场及以上
      CALL L4_PH_Mat_Coupled_TES(mat_id, ...)
      ! 允许族：01-08（力学）+ 特定电磁材料
    
    END SELECT
    
  END SUBROUTINE
END INTERFACE
```

### 4.2 单元类型约束矩阵

```
       │ C3D  │  S   │  B   │  T   │  DC  │  AC  │  EM  │
───────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤
G1-结构│  ✓   │  ✓   │  ✓   │  ✓   │  ✗   │  ✗   │  ✗   │
G2-热 │  ✗   │  ✗   │  ✗   │  ✗   │  ✓   │  ✗   │  ✗   │
G3-频域│  ✓   │  ✓   │  ✓   │  ✓   │  ✗   │  ✗   │  ✗   │
G4-声学│  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │  ✓   │  ✗   │
G5-电磁│  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │  ✓   │
G6-热力│  ✓   │  ✓   │  ✗   │  ✗   │  ◐   │  ✗   │  ✗   │
G7-多场│  ✓   │  ✓   │  ✗   │  ✗   │  ◐   │  ✗   │  ◐   │
G8-岩土│  ✓   │  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │  ✗   │
G9-其他│  ✓   │  ✓   │  ✓   │  ✓   │  ◐   │  ◐   │  ◐   │

说明：✓ 完全支持，◐ 部分支持（带约束），✗ 不支持
```

---

## 五、与现有正交设计框架的集成

### 5.1 新旧维度对应

```
原始 4D 正交：
  D1_Solver(5种) × D2_AnalysisStep(12种) × D3_Element(14种) × D4_Material(11种)

↓ 升级为 5D 架构 ↓

新 5D 架构：
  D1_Solver × D2_AnalysisStep × D3_PhysicalField(9组) × D4_Element × D5_Material
  
其中 D3_PhysicalField(G1-G9) 定义了 D2/D4 的合法组合空间
```

### 5.2 约束规则嵌入位置

```
L3_MD/Analysis:  定义 analysis_group_id (G1-G9)
                 ├─ MD_Analysis_Desc
                 └─ validate_group_element_compatibility()

L4_PH:          根据 group_id 路由材料调用
                 ├─ L4_PH_Material_Dispatcher()
                 └─ per-group 材料内核集合

L5_RT:          编译期或运行期检查
                 ├─ RT_AnalysisStep_Config.group_id
                 └─ Assert: (group_id, proc_id, elem_type, mat_id) 四元组合法
```

---

## 六、扩展性规划

### 6.1 新增求解器对 G1-G9 的影响

```
如果未来增加求解器（如 Poromechanics/Multiphase）：

新求解器 + 新的 PROC_*（新 ID）
  ↓
可能创建新的 G10（多孔多相）
  ↓
新约束规则自动遵循上述模板
```

### 6.2 材料族扩展

```
若族12（新族）被定义：
  ↓
需明确其对应的物理场属性（是否耦合？）
  ↓
更新 4.2 单元约束矩阵
```

---

## 七、实施建议

### 7.1 代码改造

**L3_MD/Analysis 模块**：

```fortran
TYPE :: MD_Analysis_Desc
  INTEGER :: proc_id              ! PROC_*
  INTEGER :: analysis_group_id    ! G1-G9 新增
  CHARACTER(len=32) :: group_name ! "Structural Single-Field" 等
END TYPE
```

**L4_PH 路由器**：

```fortran
! 新增入口
SUBROUTINE L4_PH_Init_With_Group(group_id)
  ! 预装该组所有允许的材料内核
  ! 禁用该组不允许的材料族
END SUBROUTINE
```

**L5_RT 校验**：

```fortran
! 运行时检查
CALL Assert_AnalysisGroup_Compatible( &
  group_id=G6, proc_id=32, elem_type=C3D, mat_id=201, &
  err_msg="Thermal-Mechanical analysis requires Elastic or Plastic material")
```

### 7.2 文档更新

- 更新 [`UFC_ABAQUS_Orthogonal_Design.md`] 第 2.2 节，新增 G1-G9 表格
- 在 [`L4_PH Analysis` 模块文档] 中添加 4.1、4.2 约束规则
- 生成快速参考 Cheat Sheet（一页纸 G1-G9 决策树）

### 7.3 测试策略

- 为每个 G_i 组创建至少 2 个回归用例
- 测试约束违反时的错误处理（如 G2 + C3D 应拒绝）
- 测试跨组切换时的初始化正确性

---

## 附录 A：快速参考

### A.1 用户查询流程

```
用户问题：我要做热-结构耦合分析，应该用什么材料？

查询 →
  1. PROC_ID = 32 (COUPLED_TEMP_DISP)
  2. Group = G6 (Thermo-Mechanical)
  3. 允许的材料族 = 01-08 + 09(热膨胀)
  4. 禁止的材料族 = 10(声学), 11(EM)
  5. 推荐：族01弹性 + 族09热膨胀
```

### A.2 PROC_ID → Group_ID 映射表（完整）


| PROC_ID                  | Group_ID | 分析类型名             |
| ------------------------ | -------- | ----------------- |
| 1,2,11,12,21,22,23,24,29 | G1       | Structural        |
| 31                       | G2       | Thermal Only      |
| 25,27,28,62              | G3       | Frequency Domain  |
| 81                       | G4       | Acoustic          |
| 71                       | G5       | Electromagnetic   |
| 32,34                    | G6       | Thermo-Mechanical |
| 33,35,51                 | G7       | Multi-Field       |
| 41,42                    | G8       | Geotechnical      |
| 43,44,61,91              | G9       | Other Special     |


---

## 附录 B：术语释义

- **Physical Field**: 物理场，指一类独立的物理现象（力学、热、电等）
- **Single-Field**: 单场，只涉及一类物理场的分析
- **Coupled Analysis**: 耦合分析，多个物理场通过控制方程相互作用
- **Analysis Group (G_i)**: 按物理场特性分组的分析类型集合

---

## 参考资源

1. **ABAQUS 官方**：*Analysis User's Manual* v2023, Chapters 2-11
2. **UFC 正交设计**：[`UFC_ABAQUS_Orthogonal_Design.md`] 第 2-8 节
3. **关键技术文档**：[`UFC_MultiField_Architecture.md`] 耦合场架构设计

---

**文档维护**：L4_PH 架构工作组  
**最后更新**：2026-04-04  
**下一步**：集成到 [`UFC_ABAQUS_Orthogonal_Design.md`] 作为第 3 章