# 材料域过程算法 Procedure — L3 / L4 / L5 三维度全景

**文档性质**：与 `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理材料域的过程算法（Algo TYPE + Procedure Pointer + Pipeline），补全"数据结构（四型TYPE）→ 过程算法"的完整功能模块定义。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/Material/`（L3 族级 Algo）、`ufc_core/L4_PH/Material/`（L4 Algo + constitutive PTR + S-Pipeline）、`ufc_core/L5_RT/Material/`（L5 Dispatch Ctx）。

**报告 ID**：`REP-MAT-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §2.5 的主/辅架构图解，而是以 **过程算法** 为核心视角；四型合订本 §11 S-Pipeline 详述与本文 §4 互补。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| 材料域 **三维度过程算法**：空间（族级积分/离散）、时间（步控制/子增量）、动作（S-Pipeline） | 具体 **本构公式** 推导 |
| L3/L4/L5 **Algo TYPE 体系** 逐层展开 | 非材料域的过程算法（见各域 Procedure 文档） |
| **constitutive 过程指针** 架构与族级配方绑定 | **UMAT ABI 参数映射**（见四型合订本 §7–§10） |
| **S-Pipeline**（S1→S4）流程与 Algo 消费点 | **截面/单元** Populate 细节（见 Section/Element Procedure 文档） |

---

## 1. 三维度过程算法框架（材料域解读）

### 1.1 空间维度

材料域的空间维度关注 **积分点（IP）上的离散化与应力态定义**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **应力态定义** | ntens/ndi/nshr 由 Section→Material Populate | `PH_Mat_Cfg_Init_Desc%ntens` |
| **积分方法选择** | 全积分/减缩积分/子区域积分 | `MD_Mat_<Fam>_Algo%integration_method` |
| **本构空间离散** | 单 IP 应力/应变 → 多 IP 积分（经 Element） | `PH_Mat_Lcl_Comp_State%stress(ntens)` |

### 1.2 时间维度

材料域的时间维度关注 **步级控制 / 子增量 / 局部 NR 迭代**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **步级算法控制** | 容差/最大迭代/积分方案 | `PH_Mat_Stp_Ctl_Algo` |
| **子增量** | 大应变步切分为子步 | `PH_Mat_Stp_Ctl_Algo%max_iter` / 族级 `sub_inc` |
| **增量演化** | stateVars(n)→stateVars(n+1) | `PH_Mat_Lcl_Evo_State%stateVars_n → stateVars` |
| **时间积分方案** | BE(1) / MP(2) | `PH_Mat_Stp_Ctl_Algo%integ_scheme` |

### 1.3 动作维度

材料域的动作维度关注 **本构更新四步管线 S-Pipeline**。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **S1_FetchState** | 取槽→Desc+State+Ctx+Algo 联合准备 | —（读取为主） |
| **S2_Dispatch** | 族合法→SELECT TYPE→族级配方入口 | —（路由分发） |
| **S3_StressUpdate** | 本构应力更新 | `PH_Mat_Lcl_Comp_State%stress` |
| **S4_Tangent** | 一致/连续切线计算 | `PH_Mat_Lcl_Comp_State%C_tan` |

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 族级 Algo TYPE（冷路径，模型定义 SSOT）

| 族 | Algo TYPE | 核心字段 | 三维度归属 |
|----|-----------|----------|-----------|
| Base | `MD_Mat_Algo` | 基类算法参数 | 空间+动作 |
| Elas | `MD_Mat_Elas_Algo` | integration_method / tangent_type | 空间+动作 |
| Plast | `MD_Mat_Plast_Algo` | return_mapping_type / cutting_plane_tol | 动作 |
| Creep | `MD_Mat_Creep_Algo` | creep_law / integration_scheme | 时间+动作 |
| Visco | `MD_Mat_Visco_Algo` | prony_terms / relaxation_scheme | 时间+动作 |
| Hyper | (族级 Def 在 L4) | — | — |
| Damage | `MD_Mat_Damage_Algo` | damage_model / degradation_scheme | 动作 |
| Thermal | `MD_Mat_Therm_Algo` | thermal_conduct_scheme / specific_heat | 空间+动作 |
| Acoustic | `MD_Mat_Acou_Algo` | wave_speed_method / impedance | 空间 |
| Geo | `MD_Mat_Geo_Algo` | K0_method / consolidation_scheme | 空间+动作 |
| Comp | `MD_Mat_Comp_Algo` | lamina_scheme / failure_criterion | 空间+动作 |
| User | `MD_Mat_User_Algo` | user_subroutine_id / nprops / nsdv | 动作 |

**设计特点**：L3 族级 Algo 侧重 **空间+动作**，定义积分方法/本构策略等模型级决策。

### 2.2 L4 域级 + 族级 Algo TYPE（热路径，物理实现）

| 层级 | Algo TYPE | 核心字段 | 三维度归属 |
|------|-----------|----------|-----------|
| 域级 | `PH_Mat_Stp_Ctl_Algo` | tol_yield / max_iter / integ_scheme / tol_residual | **时间** |
| 域级 | `PH_Mat_Algo` | 基类算法 | 空间+动作 |
| 域级 | `PH_Mat_Algo` | constitutive PTR + stp_ctl 嵌入 | **动作+时间** |
| 族级 | `PH_Mat_Elas_Algo` | tangent_type / plane_stress_flag | 动作 |
| 族级 | `PH_Mat_Plast_Algo` | return_mapping / cutting_plane_tol | 动作 |
| 族级 | `PH_Mat_Creep_Algo` | creep_scheme / integration_method | 时间+动作 |
| 族级 | `PH_Mat_Visco_Algo` | prony_scheme / relaxation | 时间+动作 |
| 族级 | `PH_Mat_Hyper_Algo` | strain_energy / compressibility | 空间+动作 |
| 族级 | `PH_Mat_Damage_Algo` | damage_model / degradation | 动作 |
| 族级 | `PH_Mat_Therm_Algo` | thermal_scheme / conductivity | 空间+动作 |
| 族级 | `PH_Mat_Acou_Algo` | wave_speed / impedance | 空间 |
| 族级 | `PH_Mat_Geo_Algo` | K0 / consolidation | 空间+动作 |
| 族级 | `PH_Mat_Comp_Algo` | lamina / failure | 空间+动作 |
| 族级 | `PH_Mat_User_Algo` | user_sub / nprops / nsdv | 动作 |

### 2.3 L5 Algo TYPE（运行期路由）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_Mat_Stp_Ctl_Algo` | dispatch_mode / nan_check / sub_increment / retry | 时间 | ✅ **P2 DONE** |
| `RT_Mat_Algo` | stp_ctl(`RT_Mat_Stp_Ctl_Algo`) | 时间 |

**说明**：P2 补全后，L5 材料侧引入 `RT_Mat_Stp_Ctl_Algo` 管控**分发级**算法控制（路由模式/NaN检测策略/子增量/重试），与 L4 `PH_Mat_Stp_Ctl_Algo`（本构级步控制）形成双层 Stp_Ctl 对齐。`RT_Mat_Stp_Ctl_Algo` 不涉及本构算法参数（由 L4 `PH_Mat_Algo` / `PH_Mat_<Fam>_Algo` 管控）。

---

## 3. Procedure Pointer 架构

### 3.1 constitutive 过程指针（L4 核心可插拔算法入口）

```fortran
! PH_Mat_Domain_Core.f90 (AUTHORITY)
ABSTRACT INTERFACE
  SUBROUTINE PH_Mat_Constitutive_Ifc(desc, state, ctx, algo, status)
    IMPORT :: PH_Mat_Desc, PH_Mat_State, PH_Mat_Ctx, PH_Mat_Algo, ErrorStatusType
    IMPLICIT NONE
    TYPE(PH_Mat_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Algo),   INTENT(IN)    :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status
  END SUBROUTINE
END ABSTRACT INTERFACE

! PH_Mat_Algo 内嵌:
PROCEDURE(PH_Mat_Constitutive_Ifc), POINTER, NOPASS :: constitutive => NULL()
```

### 3.2 族级配方绑定（L4 → L5 分派路径）

```text
constitutive PTR 绑定路径:
  PH_Mat_Algo%constitutive
    ├── PH_Mat_Elas_Execute      ← Elas 族
    ├── PH_Mat_Plast_Execute     ← Plast 族 (return_mapping + cutting_plane)
    ├── PH_Mat_Creep_Execute     ← Creep 族
    ├── PH_Mat_Visco_Execute     ← Visco 族
    ├── PH_Mat_Hyper_Execute     ← Hyper 族
    ├── PH_Mat_Damage_Execute    ← Damage 族
    ├── PH_Mat_Therm_Execute     ← Thermal 族
    ├── PH_Mat_Acou_Execute      ← Acoustic 族
    ├── PH_Mat_Geo_Execute       ← Geo 族
    ├── PH_Mat_Comp_Execute      ← Comp 族
    └── PH_Mat_User_Execute      ← User 族 (UMAT bridge)
```

### 3.3 Procedure Pointer 三层模式（材料域实例）

| 层 | 角色 | 代码落点 |
|----|------|---------|
| L3 | 仅定义签名（ABSTRACT INTERFACE），不绑定实现 | —（材料域 L3 无独立 Interface） |
| L4 | 绑定族级配方（constitutive → PH_Mat_<Fam>_Execute） | `PH_Mat_Domain_Core.f90` |
| L5 | 编排层调用 L4 过程指针（经 Dispatch 分派） | `RT_Mat_Dispatch_Stress` → `PH_Mat_Execute_Flow` |

---

## 4. S-Pipeline 流程（核心动作管线）

### 4.1 管线全景

```text
PH_Mat_Execute_Flow (L4 AUTHORITY, 金线)
  │
  ├── S1_FetchState
  │   └── 取槽: PH_Mat_Desc + PH_Mat_State + PH_Mat_Ctx + PH_Mat_Algo 联合准备
  │   └── Algo 消费: PH_Mat_Stp_Ctl_Algo%tol_yield, %max_iter
  │   └── State 读取: PH_Mat_Lcl_Evo_State%stateVars_n
  │
  ├── S2_Dispatch
  │   └── 族合法: SELECT TYPE → 族级配方入口
  │   └── Algo 消费: PH_Mat_Algo%constitutive PTR (可插拔算法选择)
  │
  ├── S3_StressUpdate
  │   └── 本构应力更新: dstrain → σ(n+1)
  │   └── State 写入: PH_Mat_Lcl_Comp_State%stress(ntens)
  │   └── Algo 消费: PH_Mat_Stp_Ctl_Algo%integ_scheme (BE/MP)
  │
  └── S4_Tangent
      └── 一致/连续切线: ∂σ/∂ε → C_tan
      └── State 写入: PH_Mat_Lcl_Comp_State%C_tan(ntens,ntens)
      └── Algo 消费: MD_Mat_<Fam>_Algo%tangent_type (CONSISTENT/CONTINUOUS)
```

### 4.2 各族 S-Pipeline 特化

| 族 | S2 分派入口 | S3 特化 | S4 特化 |
|----|------------|---------|---------|
| Elas | `PH_Mat_Elas_Execute` | 弹性胡克定律 | 解析切线 = D_mat |
| Plast | `PH_Mat_Plast_Execute` | 回映算法(return_mapping) | 一致切线(consistent) |
| Creep | `PH_Mat_Creep_Execute` | 蠕变积分(BE/MP) | 蠕变切线 |
| Visco | `PH_Mat_Visco_Execute` | Prony 级数松弛 | 粘弹性切线 |
| Hyper | `PH_Mat_Hyper_Execute` | 超弹性应变能 | 一致切线 |
| Damage | `PH_Mat_Damage_Execute` | 损伤演化+退化 | 退化切线 |
| Thermal | `PH_Mat_Therm_Execute` | 热传导+热应变 | 热切线 |
| Acoustic | `PH_Mat_Acou_Execute` | 声波本构 | 声学阻抗矩阵 |
| Geo | `PH_Mat_Geo_Execute` | K₀/固结 | 地质切线 |
| Comp | `PH_Mat_Comp_Execute` | 层合板理论 | 层合切线 |
| User | `PH_Mat_User_Execute` | UMAT 桥接 | UMAT DDSDDE |

---

## 5. 跨域协作（材料域视角）

### 5.1 空间维度协作：M-S-E 三元 Populate

```text
Section (截面)
  → PH_L4_Populate_Material: sect_id → ntens/应力态 → PH_Mat_Desc
  → PH_L4_Populate_Element:  sect_id → 厚度/取向 → PH_Elem_Desc
  → MD_SectCompat::Validate_Triple (M-S-E 三元兼容性校验)
```

| 协作域 | 空间操作 | 材料域角色 |
|--------|----------|-----------|
| Section | Populate 输入源 | 提供 `ntens`/应力态给 Section 校验 |
| Element | 积分点遍历调用 | Element 遍历 Gauss 点，每个 IP 调用 S-Pipeline |
| Contact | 接触面法向力 | 不直接协作；经 Assembly 间接消费 |

### 5.2 时间维度协作：迭代环中的材料更新

| 时间阶段 | 材料域动作 | 协作域 |
|----------|-----------|--------|
| Step Init | Populate + 初始化 stateVars | Analysis (步驱动) |
| Inc Predict | — | — |
| Itr Assemble | S1_Fetch + S2_Dispatch | Element (Ke/Re 调用链) |
| Itr Solve | S3_StressUpdate | Solver (需要 C_tan) |
| Itr Update | S4_Tangent | Element (切线刚度) |
| Itr Check | — | Solver (收敛判断) |

### 5.3 动作维度协作：S-Pipeline 在全局求解中的位置

```text
RT_Solv_Mgr (K·x=f 金线)
  ├── RT_Asm (全局装配)
  │   └── Element: 遍历 IP → PH_Mat_Execute_Flow (S1→S4)
  │       └── S3: σ → 内力 Re
  │       └── S4: C_tan → 单元刚度 Ke
  │
  └── RT_Solv_Nonlin (NR 迭代)
      └── Ke/Re → 全局 K/F → 求解 du
```

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| P2 | ~~L5 无独立 Algo TYPE~~ | ~~`RT_Mat_Dispatch_Ctx` 透传 L4 Algo~~ | ~~评估引入 `RT_Mat_Stp_Ctl_Algo`~~ | ✅ **DONE**
| — | 12 族级 Algo 部分字段粒度不足 | 部分族 Algo 仅有 2-3 字段 | 按需在族级 Def 中扩展 |

**完备性评级**：✅ **三维度全覆盖**（空间: 族级积分, 时间: Stp_Ctl_Algo, 动作: S-Pipeline + constitutive PTR）

---

## 7. 设计原则（材料域特化）

1. **S-Pipeline 四步不变式**：S1→S2→S3→S4 顺序不可跳步；S1 必须在 S2 之前，S3 必须在 S4 之前。
2. **constitutive PTR 单入口**：所有族级本构经 `PH_Mat_Algo%constitutive` 单指针进入，SELECT TYPE 在 S2 内完成。
3. **族级 Algo 不跨族引用**：`PH_Mat_Plast_Algo` 不引用 `PH_Mat_Creep_Algo`；跨族耦合（如塑性+蠕变）通过复合族（Creep+Plast）独立定义。
4. **L4 Stp_Ctl 管步、族级 Algo 管算法**：`PH_Mat_Stp_Ctl_Algo` 控制步级参数（容差/迭代上限），族级 Algo 控制本构算法策略。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` | 四型合订本；§2.5 主/辅架构图解、§11 S-Pipeline 详述 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.1 + A.3.1 | 过程算法全景合订（根 stub）；本文为材料域专域扩展 |
| `L4_PH/Material/CONTRACT.md` | L4 合同卡；Algo TYPE 字段级真源 |
| `L3_MD/Material/CONTRACT.md` | L3 合同卡；族级 Algo 字段级真源 |
| [Section_Procedure_Algorithm.md](../Section_Procedure_Algorithm.md) | Section Procedure；M-S-E Populate 协作 |
| [Element_Procedure_Algorithm.md](../Element_Procedure_Algorithm.md) | Element Procedure；IP 遍历→S-Pipeline 调用链 |

---

*冷归档全文：`UFC/REPORTS/archive/Material_Procedure_Algorithm.md`。入口 stub：`UFC/REPORTS/Material_Procedure_Algorithm.md`。四型合订（根 stub）：`UFC/REPORTS/Material_L3L4L5_four_type_UMAT_discussion_synthesis.md`。全景合订（根 stub）：`UFC/REPORTS/Procedure_Algorithm_L3L4L5_synthesis.md`。*

