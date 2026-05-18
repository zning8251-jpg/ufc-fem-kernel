# ABAQUS 分析类型精确映射与UFC Group对应

> **版本**: v1.0  
> **日期**: 2026-04-04  
> **目标**: 所有33种分析类型与ABAQUS编号、UFC Group、材料约束、单元约束的精确对应表

---

## 1. 分析类型总体统计

### 1.1 按求解器分类

| 求解器 | 类型数 | PROC范围 | 特性 |
|-------|--------|---------|------|
| **Standard (隐式)** | 26 | 1,2,11,21-29,31-35,41-44,51,61,62,81,91 | 静力/瞬态/频域 |
| **Explicit (显式)** | 1 | 12 | 瞬态显式 |
| **CFD** | 1 | 95 | 流体动力学 |
| **Acoustic** | 1 | 81 | 声学 |
| **EM** | 1 | 71 | 电磁 |
| **其他特殊** | 3 | 43,91,待定 | 特殊耦合/分析 |
| **总计** | **33** | — | — |

### 1.2 按物理场维度分类（G1-G9）

```
总数: 33 种
├─ G1 (结构单场)      9 种  → PROC: 1,2,11,12,21,22,23,24,29
├─ G2 (纯热分析)      1 种  → PROC: 31
├─ G3 (频域分析)      4 种  → PROC: 25,27,28,62
├─ G4 (声学单场)      1 种  → PROC: 81
├─ G5 (电磁单场)      1 种  → PROC: 71
├─ G6 (热-结构双场)   2 种  → PROC: 32,34
├─ G7 (三场及以上)    3 种  → PROC: 33,35,51
├─ G8 (岩土土力学)    2 种  → PROC: 41,42
└─ G9 (其他特殊)      5 种  → PROC: 43,44,61,91,其他
```

---

## 2. 详细分析类型列表（按PROC_ID排序）

### 2.1 G1 — 结构单场（9种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 1 | 静力非线性 | 1 | `*STATIC` | STD | 准静态 | 力学+塑性/损伤 | C3D,CPS,CAX,S,B,T |
| 2 | Riks弧长法 | 2 | `*STATIC, RIKS` | STD | 准静态 | 力学(切线非线性) | C3D,CPS,CAX,S,B,T |
| 3 | 动力隐式 | 11 | `*DYNAMIC` | STD | 瞬态 | 力学+惯性 | C3D,CPS,CAX,S,B,T |
| 4 | 动力显式 | 12 | `*DYNAMIC, EXPLICIT` | EXP | 瞬态 | 力学(显式格式) | C3D,CPS,CAX,S,B,T |
| 5 | 模态分析 | 21 | `*FREQUENCY` | STD | 无时间 | 线性弹性 | C3D,CPS,CAX,S,B,T |
| 6 | 频率响应 | 22 | `*FREQUENCY, TYPE=STEADY STATE` | STD | 频域 | 弹性+阻尼 | C3D,CPS,CAX,S,B,T |
| 7 | 屈曲分析 | 23 | `*BUCKLE` | STD | 无时间 | 预应力弹性 | C3D,CPS,CAX,S,B,T |
| 8 | 稳态动力学 | 24 | `*STEADY STATE DYNAMICS` | STD | 频域 | 弹性+阻尼 | C3D,CPS,CAX,S,B,T |
| 9 | 复频率 | 29 | `*COMPLEX FREQUENCY` | STD | 频域 | 复数阻尼 | C3D,CPS,CAX,S,B,T |

**L4_PH调用链**: `L4_PH_Material_Mechanics()` (族01-08)  
**L5_RT求解器**: `RT_Solver_Standard` 或 `RT_Solver_Explicit`

---

### 2.2 G2 — 纯热分析（1种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 10 | 瞬态热分析 | 31 | `*HEAT TRANSFER` | STD | 瞬态 | 热材料(导热) | DC,CAX |

**L4_PH调用链**: `L4_PH_Material_Thermal()` (族09)  
**L5_RT求解器**: `RT_Solver_Standard` (热求解器)

---

### 2.3 G3 — 频域分析（4种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 11 | 随机响应 | 25 | `*RANDOM RESPONSE` | STD | 频域 | 弹性+阻尼 | C3D,CPS,CAX,S,B,T |
| 12 | 复特征值 | 27 | `*COMPLEX EIGENVALUE` | STD | 频域 | 弹性+复阻尼 | C3D,CPS,CAX,S,B,T |
| 13 | 参数激励 | 28 | `*PARAMETRIC RESONANCE` | STD | 频域 | 弹性+非线性阻尼 | C3D,CPS,CAX,S,B,T |
| 14 | 求解频应 | 62 | `*FREQUENCY, TYPE=LANCZOS` | STD | 频域 | 弹性+阻尼 | C3D,CPS,CAX,S,B,T |

**L4_PH调用链**: `L4_PH_Material_Mechanics()` (族01-08) + 阻尼模型  
**L5_RT求解器**: `RT_Solver_Frequency`

---

### 2.4 G4 — 声学单场（1种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 15 | 声学分析 | 81 | `*ACOUSTIC` | ACOU | 瞬态/频域 | 声学材料(族10) | AC,CAX |

**L4_PH调用链**: `L4_PH_Material_Acoustic()` (族10)  
**L5_RT求解器**: `RT_Solver_Acoustic`

---

### 2.5 G5 — 电磁单场（1种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 16 | 电磁分析 | 71 | `*ELECTROMAGNETIC` | EM | 瞬态/频域 | EM材料(族11) | EM,CAX |

**L4_PH调用链**: `L4_PH_Material_EM()` (族11)  
**L5_RT求解器**: `RT_Solver_EM`

---

### 2.6 G6 — 热-结构双场（2种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 | 耦合策略 |
|----|---------|---------|------------|--------|---------|---------|---------|---------|
| 17 | 耦合温位移(STD) | 32 | `*COUPLED TEMP-DISP` | STD | 瞬态 | 力学+热膨胀 | C3D,CPS,CAX,S,B,T,DC | 弱耦合 |
| 18 | 耦合温位移(EXP) | 34 | `*COUPLED TEMP-DISP, EXPLICIT` | EXP | 瞬态 | 力学+热膨胀 | C3D,CPS,CAX,S,B,T,DC | 显式耦合 |

**L4_PH调用链**: `L4_PH_Material_Mechanics()` + `L4_PH_Material_Thermal()`  
**L5_RT求解器**: `RT_Solver_Coupled_Thermo_Mech`  
**耦合迭代**: Gauss-Seidel (弱耦合) 或 显式分步

---

### 2.7 G7 — 三场及以上（3种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 | 耦合策略 |
|----|---------|---------|------------|--------|---------|---------|---------|---------|
| 19 | 热-电-结构三场 | 33 | `*COUPLED THERMAL-ELECTRIC-STRUCTURAL` | STD | 瞬态 | 力学+热+电 | C3D,CPS,CAX,S,B,T,DC,EM | 强耦合 |
| 20 | 电-结构双场 | 35 | `*COUPLED ELECTRIC-STRUCTURAL` | STD | 瞬态 | 力学+压电 | C3D,CPS,CAX,S,B,T,EM | 强耦合 |
| 21 | 多场耦合(通用) | 51 | `*COUPLED FIELDS, TYPE=GENERAL` | STD | 瞬态 | 力学+热+流体 | C3D,CPS,CAX,S,B,T,DC | 用户定义 |

**L4_PH调用链**: 多个材料域按优先级顺序  
**L5_RT求解器**: `RT_Solver_Coupled_MultiField`  
**耦合迭代**: Newton-Raphson (强耦合)

---

### 2.8 G8 — 岩土土力学（2种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 22 | 地基沉降(孔压) | 41 | `*GEOSTATIC` | STD | 准静态 | 岩土(族03)+孔压 | C3D,CPS,CAX |
| 23 | 土体动力学 | 42 | `*SOILS, TYPE=CONSOLIDATION` | STD | 瞬态 | 岩土+渗透+变形 | C3D,CPS,CAX |

**L4_PH调用链**: `L4_PH_Material_Geomaterial()` (族03)  
**L5_RT求解器**: `RT_Solver_Geomechanics`

---

### 2.9 G9 — 其他特殊（5种）

| # | 分析类型 | PROC_ID | ABAQUS关键词 | 求解器 | 时间特性 | 材料约束 | 单元约束 |
|----|---------|---------|------------|--------|---------|---------|---------|
| 24 | 粘性阻尼 | 43 | `*VISCO` | STD | 瞬态 | 力学+粘性 | C3D,CPS,CAX,S,B,T |
| 25 | 退火分析 | 44 | `*ANNEALING` | STD | 瞬态 | 热+冶金 | DC,CAX |
| 26 | 质量扩散 | 61 | `*MASS DIFFUSION` | STD | 瞬态 | 扩散材料 | C3D,CPS,CAX,DC |
| 27 | 流体分析 | 95 | `*CFD` | CFD | 瞬态/频域 | 流体材料 | 网格适配 |
| 28 | 用户分析 | 91 | `*USER ANALYSIS` | STD | 用户定义 | 用户定义(族11) | 用户定义 |

**L4_PH调用链**: 根据分析类型选择  
**L5_RT求解器**: 根据分析类型选择  

---

## 3. 材料族与Group约束矩阵

### 3.1 材料族定义（族01-11）

| 族ID | 名称 | 描述 | 允许Group |
|------|------|------|---------|
| 01 | Elastic | 线性/非线性弹性 | G1,G3,G6,G7,G8,G9 |
| 02 | Plastic | 弹塑性(J2/Hill/...) | G1,G3,G6,G7,G8,G9 |
| 03 | Geomaterial | Mohr-Coulomb/DP/CDP | G1,G8,G9 |
| 04 | HyperElastic | NeoHookean/Ogden | G1,G3,G6,G7,G8,G9 |
| 05 | Viscoelastic | 粘弹性/Prony级数 | G1,G3,G6,G7,G8,G9 |
| 06 | Creep | 蠕变(幂律/Norton) | G1,G3,G6,G7,G8,G9 |
| 07 | Damage | 损伤(CDM/GTN) | G1,G3,G6,G7,G8,G9 |
| 08 | Composite | 复合材料(CLT/Hashin) | G1,G3,G6,G7,G8,G9 |
| 09 | Thermal | 导热/热容 | G2,G6,G7,G9 |
| 10 | Acoustic | 声学声速/衰减 | G4,G7,G9 |
| 11 | EM | 电磁/压电 | G5,G7,G9 |

### 3.2 Group → 允许材料族（点阵）

```
       Fam01 Fam02 Fam03 Fam04 Fam05 Fam06 Fam07 Fam08 Fam09 Fam10 Fam11
G1  :   ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     —     —     —
G2  :   —     —     —     —     —     —     —     —     ✓     —     —
G3  :   ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     —     —     —
G4  :   —     —     —     —     —     —     —     —     —     ✓     —
G5  :   —     —     —     —     —     —     —     —     —     —     ✓
G6  :   ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     —     —
G7  :   ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓
G8  :   ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     —     —     —
G9  :   ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓     ✓
```

---

## 4. 单元类型与Group约束矩阵

### 4.1 单元类型分类

| 代码 | 名称 | 维度 | 允许Group |
|-----|------|------|---------|
| C3D | 3D 实心 | 3D | G1-G9 |
| CPS | 平面应力 | 2D | G1-G9 |
| CAX | 轴对称 | 2D | G1-G9 |
| S | 壳单元 | 3D-2D | G1,G3,G6,G7,G8,G9 |
| B | 梁单元 | 1D | G1,G3,G6,G7,G8,G9 |
| T | 桁架 | 1D | G1,G3,G6,G7,G8,G9 |
| DC | 热单元 | 2D/3D | G2,G6,G7,G9 |
| AC | 声学单元 | 2D/3D | G4,G7,G9 |
| EM | 电磁单元 | 3D | G5,G7,G9 |

### 4.2 Group → 允许单元类型（点阵）

```
      C3D CPS CAX  S   B   T  DC  AC  EM
G1 :   ✓   ✓   ✓   ✓   ✓   ✓   —   —   —
G2 :   —   —   ✓   —   —   —   ✓   —   —
G3 :   ✓   ✓   ✓   ✓   ✓   ✓   —   —   —
G4 :   —   —   ✓   —   —   —   —   ✓   —
G5 :   —   —   ✓   —   —   —   —   —   ✓
G6 :   ✓   ✓   ✓   ✓   ✓   ✓   ✓   —   —
G7 :   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓
G8 :   ✓   ✓   ✓   —   —   —   —   —   —
G9 :   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓
```

---

## 5. UFC代码改造指引

### 5.1 L3_MD 层：添加group_id字段

**文件**: `L3_MD/Analysis/MD_Analysis_Types.f90`

```fortran
TYPE, PUBLIC :: MD_Analy_Base_Desc
  ! ... existing fields ...
  INTEGER(i4) :: analysis_proc = 1_i4    ! PROC_ID (1-91)
  
  ! NEW: Group classification
  INTEGER(i4) :: group_id = 0_i4         ! G1-G9
  LOGICAL     :: group_validated = .FALSE.
END TYPE
```

**验证规则**:
- PROC_ID必须在1-91范围内
- PROC_ID必须映射到有效Group (G1-G9)
- Group不能为0 (未初始化)

### 5.2 L4_PH 层：创建Group-aware路由器

**文件**: `L4_PH/Control/PH_Analysis_Group_Router.f90`

```fortran
TYPE :: PH_AnalyGroup_Router
  INTEGER(i4) :: group_id
  LOGICAL :: enable_mechanics, enable_thermal, enable_acoustic, enable_em
  INTEGER(i4) :: coupling_strategy
END TYPE
```

**路由策略**:
- **One-shot**: G1,G2,G3,G4,G5,G8 → 单次材料调用
- **Weak coupling**: G6 → Gauss-Seidel迭代(热→力→热...)
- **Strong coupling**: G7 → Newton-Raphson迭代(所有字段)
- **One-way**: G9 → 按定义的顺序

### 5.3 L5_RT 层：约束校验与冲突检测

**文件**: `L5_RT/Analysis/RT_AnalysisGroup_Validator.f90`

```fortran
CALL Assert_Group_Materials_Compatible(group_desc, mat_families)
CALL Assert_Group_Elements_Compatible(group_desc, elem_types)
CALL Assert_Coupling_Strategy_Feasible(group_desc, router)
```

**约束列表**:
1. 材料族不在允许列表 → ERR_MATFAMILY_FORBIDDEN
2. 单元类型不允许 → ERR_ELEMTYPE_FORBIDDEN
3. 耦合策略不可行 → ERR_COUPLING_UNSUPPORTED
4. 材料-单元不一致 → ERR_MATELEM_INCOHERENT

---

## 6. CI/CD 门禁规则

### 6.1 analysis_type_checker.sh

```bash
#!/bin/bash
# Check script for analysis type consistency

# Rule 1: PROC_ID must be in [1,91]
grep -r "analysis_proc\s*=" UFC/ufc_core | \
  awk -F'=' '{print $NF}' | \
  awk '{if ($1 < 1 || $1 > 91) print "ERROR: PROC_ID out of range: "$1}'

# Rule 2: If PROC_ID set, group_id must be initialized
# Rule 3: Material families must match group constraints
# Rule 4: Element types must match group constraints
```

### 6.2 集成到 .pre-commit-config.yaml

```yaml
- repo: local
  hooks:
    - id: analysis-type-checker
      name: Check analysis type constraints
      entry: ./UFC/scripts/analysis_type_checker.sh
      language: script
      files: \.f90$
      stages: [commit]
```

---

## 7. 快速参考表

### 7.1 按PROC_ID查询Group

```
PROC_ID  Group   类型名称
1        G1      静力非线性
2        G1      Riks弧长法
11       G1      动力隐式
12       G1      动力显式
21       G1      模态分析
22       G1      频率响应
23       G1      屈曲分析
24       G1      稳态动力学
25       G3      随机响应
27       G3      复特征值
28       G3      参数激励
29       G1      复频率
31       G2      瞬态热分析
32       G6      耦合温位移(STD)
33       G7      热-电-结构三场
34       G6      耦合温位移(EXP)
35       G7      电-结构双场
41       G8      地基沉降
42       G8      土体动力学
43       G9      粘性阻尼
44       G9      退火分析
51       G7      多场耦合
61       G9      质量扩散
62       G3      求解频应
71       G5      电磁分析
81       G4      声学分析
91       G9      用户分析
95       G9      CFD分析
```

### 7.2 按Group查询PROC_ID

```
G1: 1,2,11,12,21,22,23,24,29
G2: 31
G3: 25,27,28,62
G4: 81
G5: 71
G6: 32,34
G7: 33,35,51
G8: 41,42
G9: 43,44,61,91,95
```

---

## 附录A: 迁移检查清单

- [ ] 所有MD_Analy_Base_Desc变量添加group_id字段
- [ ] 所有PROC_ID初始化时同步设置group_id
- [ ] 创建L4_PH_Analysis_Group_Router模块
- [ ] 为每个分析类型编写单元测试(G1-G9各2个)
- [ ] 集成CI/CD门禁规则到构建流水线
- [ ] 更新用户文档说明新的Group约束
- [ ] 性能基准测试(weak coupling vs strong coupling)

