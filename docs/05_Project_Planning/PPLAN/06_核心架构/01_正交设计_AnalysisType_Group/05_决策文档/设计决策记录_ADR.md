# 设计决策记录 (ADR) - 三维正交坐标系统

**版本**: v1.0  
**日期**: 2026-04-04  
**状态**: 记录决策过程  
**作者**: UFC架构设计组  

---

## 📋 目录

1. [ADR-001: 1-based编号体系](#adr-001-1-based编号体系)
2. [ADR-002: Physics维度扩展到12类](#adr-002-physics维度扩展到12类)
3. [ADR-003: Geo不单独占Physics](#adr-003-geo不单独占physics)
4. [ADR-004: 多求解器耦合通过Harness编排](#adr-004-多求解器耦合通过harness编排)
5. [ADR-005: 三维正交性坚持](#adr-005-三维正交性坚持)

---

## ADR-001: 1-based编号体系

### 背景

原设计采用0-based编号([0-4][0-3][0-10])，与ABAQUS PROC编号([1-91])的对应关系不直观，导致：
- 用户认知困难
- 文档编写混淆(0-based vs 1-based切换)
- PROC映射精度验证困难

### 决策

**采用双层API架构**：
- **外部API** (用户层)：1-based编号 [1-5][1-4][1-12]
- **内部实现** (计算层)：0-based索引 [0-4][0-3][0-11]
- **转换函数** (L3_MD)：`internal_index = external_1based - 1`

### 理由

1. **对齐工程习惯**
   - ABAQUS PROC编号从1开始
   - 工程师直观认知偏好1-based
   - 用户文档与源代码编号对齐

2. **性能无损**
   - 转换函数仅在L3_MD层执行一次
   - 后续所有计算使用0-based(高效的矩阵访问)
   - 无额外计算开销

3. **可验证性提升**
   - PROC-to-Group映射表使用1-based，可直接核对
   - 约束矩阵索引清晰，避免off-by-one错误

### 实施

```fortran
! L3_MD层：一次性转换
solver_idx = solver_1based - 1
coupling_idx = coupling_1based - 1
physics_idx = physics_1based - 1

! L4_PH/L5_RT：使用0-based索引
IF (COMPAT_MATRIX(solver_idx, coupling_idx, physics_idx) == 1) THEN ...
```

### 相关文档

- `01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md`
- `03_实现指导/L3_MD_Group_DESC_类型定义_实现.md`

---

## ADR-002: Physics维度扩展到12类

### 背景

原Physics维度(10类)无法表示**Fluid**作为独立基本物理场，导致：
- CFD求解器无法编码(需要Fluid物理场)
- FluidStruct(FSI)耦合无法表示(无Fluid物理场)
- 坐标空间语义模糊

```
原: [4][*][*] = CFD处理? → 处理什么?
改: [5][*][6] = CFD处理Fluid → 清晰
```

### 决策

**扩展Physics维度到12类(1-based编号)**：

```
第一组(1-6): 基本单场
  1=Structure, 2=Thermal, 3=Frequency, 4=Acoustic, 5=EM, 6=Fluid

第二组(7-10): 双场耦合
  7=ThermalStruct, 8=ElectroStruct, 9=FluidStruct, 10=FluidThermal

第三组(11-12): 高阶与特殊
  11=MultiField, 12=Special
```

### 理由

1. **完整物理覆盖**
   - 覆盖ABAQUS全部求解器(STD/EXP/ACO/EM/CFD)
   - 覆盖ABAQUS全部耦合类型(热-结构/电-结构/流-结构/流-热/多场)

2. **坐标空间优化**
   - 从200增长到240(+20%)
   - 实际有效坐标数从~35增加到~45
   - 稀疏率从82.5%降低到81.25%(可接受)

3. **物理直观性**
   - 每个Physics代表明确的物理问题
   - 正交性保持不变
   - 易于工程师理解

4. **扩展性**
   - Fluid物理场独立，便于未来集成其他CFD求解器
   - 双场耦合明确分类，便于添加新的耦合类型

### 验证

```
[5][1][6] = CFD + OneShot + Fluid              ✅ 新增有效坐标
[5][4][9] = CFD + Strong + FluidStruct(FSI)    ✅ 新增有效坐标
[1][3][7] = STD + Weak + ThermalStruct         ✅ 原有有效坐标保持
```

### 相关文档

- `01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md`
- `02_核心映射表/ABAQUS_PROC_到_Group_ID_完整映射.md`

---

## ADR-003: Geo不单独占Physics

### 背景

在原G1-G9分组中，Geo是独立的分析类型。但从物理本质看：
- Geo的求解算法与Structure完全相同(都用Standard)
- Geo的差异在于**本构模型**(Mohr-Coulomb等)和**工况**(初始应力/施工阶段)
- Geo占用一个Physics类型不经济

### 决策

**Geo不单独占Physics，通过Material族+Analysis标记实现**

```
改前: Geo = Physics的一个类型 (浪费Physics维度)
改后: Geo = Material_Family + Analysis标记
```

### 实施

```fortran
! L3_MD层
TYPE :: MD_Analysis_Geo_DESC
  TYPE(MD_Analysis_Group_DESC) :: base_group  ! 使用[1][1][1]或[1][3][1]
  INTEGER :: material_family_id = GEO_FAMILY  ! 岩土材料族
  LOGICAL :: has_initial_stress               ! 工况标记
  LOGICAL :: has_construction_stage           ! 施工阶段标记
END TYPE

! 识别逻辑
IF (physics_1based == 1 .AND. material_family_id == GEO_FAMILY) THEN
  CALL setup_geo_analysis(...)  ! 启用岩土特殊处理
END IF
```

### 理由

1. **经济性**
   - Physics=1(Structure)已能完整表示Geo分析
   - 无需额外占用Physics维度

2. **正交性保持**
   - Material族与Physics维度正交
   - Geo作为应用领域而非基本物理场

3. **扩展性**
   - 便于添加其他材料特定分析(如复合材料、高分子等)
   - 不需修改三维坐标系统

### 相关文档

- `01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md`

---

## ADR-004: 多求解器耦合通过Harness编排

### 背景

某些分析问题需要多个求解器协同：
- FluidStruct(FSI)：CFD + Standard
- FluidThermal：CFD + Thermal
- 多场耦合：多个求解器交互

如何在三维坐标系统中表示这种跨求解器耦合？

### 决策

**多求解器耦合通过L4_PH识别 + L5_RT Harness编排**

```
Layer 3 (MD): Group_DESC标记physics_1based=9(FluidStruct)
             ↓
Layer 4 (PH): 识别需要CFD+STD两个求解器
             CALL enable_auxiliary_solver(SOLVER_STANDARD)
             ↓
Layer 5 (RT): Harness实现耦合算法
             DO iter=1, n_strong_iter
               CALL CFD_solver%step()
               CALL data_transfer(fluid → struct)
               CALL STD_solver%step()
               CALL data_transfer(struct → fluid)
             END DO
```

### 实施

```fortran
! L3_MD层：Group_DESC中的标记
TYPE :: MD_Analysis_Group_DESC
  LOGICAL :: requires_auxiliary_solver
  INTEGER :: auxiliary_solver_id
END TYPE

! L4_PH层：识别与启用
IF (group%physics_1based == 9 .AND. group%solver_1based == 5) THEN
  group%requires_auxiliary_solver = .TRUE.
  group%auxiliary_solver_id = SOLVER_STANDARD
  CALL enable_auxiliary_solver(SOLVER_STANDARD)
END IF

! L5_RT层：执行耦合
CALL harness_strong_coupling(CFD_solver, STD_solver, ...)
```

### 理由

1. **架构清晰**
   - L3_MD只负责数据描述(不编排)
   - L4_PH负责识别与路由(不算法)
   - L5_RT负责执行与迭代(不定义)
   - 职责清晰分离

2. **扩展性强**
   - 添加新的多求解器组合只需:
     - 在L3_MD添加新Physics或标记
     - 在L4_PH添加识别规则
     - 在L5_RT添加耦合算法
   - 无需修改三维坐标系统

3. **可验证**
   - 耦合算法单独测试
   - 各层接口清晰

### 相关文档

- `03_实现指导/L3_MD_Group_DESC_类型定义_实现.md`

---

## ADR-005: 三维正交性坚持

### 背景

设计三维坐标系统时，面临多个维度选择：
- Solver/Coupling/Physics 是否互不嵌套?
- 是否允许某个维度的值依赖其他维度?
- 如何处理特殊情况?

### 决策

**严格坚持三维正交性，禁止嵌套**

```
原型 (错误): 
  Solver_Coupling组合 = {(STD,OneShot), (STD,OneWay), (EXP,OneShot), ...}
  导致Solver和Coupling不独立

改进 (正确):
  Solver = {1,2,3,4,5}              (独立)
  Coupling = {1,2,3,4}              (独立)
  Physics = {1,2,...,12}            (独立)
  通过约束矩阵(0:4, 0:3, 0:11)管理有效组合
```

### 实施

```fortran
! 约束矩阵：通过查表管理有效组合
IF (COMPATIBILITY_MATRIX(solver_idx, coupling_idx, physics_idx) == 1) THEN
  ! 有效组合
ELSE
  ! 非法组合，报错
END IF
```

### 理由

1. **设计优雅**
   - 三个维度完全独立，易理解
   - 任何两个维度的新组合(第三维不变)可自动产生新坐标
   - 扩展时无需改动其他维度

2. **约束管理清晰**
   - 所有约束显式记录在COMPATIBILITY_MATRIX中
   - 禁止在维度定义中隐含约束
   - 便于维护和文档化

3. **可扩展**
   - 添加新Solver：扩展维度1，初始化第5行约束矩阵
   - 添加新Physics：扩展维度3，初始化所有行的新列
   - 无需重新设计系统

### 示例

```
添加新Solver (RTM - 树脂转移模塑):
  新维度: Solver=6 (RTM)
  初始化: COMPATIBILITY_MATRIX(5, :, :) = [...] (仅支持部分组合)
  无需修改Coupling/Physics维度

添加新Physics (复合材料):
  新维度: Physics=13 (Composite)
  初始化: 所有行的第13列 = [...]
  无需修改Solver/Coupling维度
```

### 相关文档

- `01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md`

---

## 决策总结

| 决策 | 关键点 | 优势 |
|-----|-------|------|
| ADR-001 | 双层API(1-based外/0-based内) | 工程直观性 + 计算效率 |
| ADR-002 | Physics扩展到12类,含Fluid | 完整物理覆盖 + CFD支持 |
| ADR-003 | Geo通过Material族实现 | 经济性 + 扩展灵活性 |
| ADR-004 | 多求解器通过Harness编排 | 架构清晰 + 易于扩展 |
| ADR-005 | 严格三维正交性 | 设计优雅 + 高度可扩展 |

---

## 相关文档

- 📍 顶层设计：`01_顶层设计/UFC_正交维度_Solver_Coupling_Physics_定义.md`
- 📍 核心映射表：`02_核心映射表/ABAQUS_PROC_到_Group_ID_完整映射.md`
- 📍 实现指导：`03_实现指导/L3_MD_Group_DESC_类型定义_实现.md`
- 📍 快速参考：`04_快速参考/三维坐标_快速参考表_v2.0.md`
