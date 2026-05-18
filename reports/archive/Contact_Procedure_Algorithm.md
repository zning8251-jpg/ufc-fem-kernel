# 接触/交互域过程算法 Procedure — L3 / L4 / L5 三维度全景

**文档性质**：与 `Contact_L3L4L5_four_type_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理 Contact/Interaction 域的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/Interaction/`（L3 Algo）、`ufc_core/L4_PH/Contact/`（L4 Algo + search_strategy PTR + Uzawa Loop）、`ufc_core/L5_RT/Contact/`（L5 Algo + 编排）。

**报告 ID**：`REP-CONT-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的主/辅架构图解，而是以 **过程算法** 为核心视角。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| Contact/Interaction 域 **三维度过程算法**：空间（接触搜索/检测）、时间（AugLag迭代/cutback）、动作（Uzawa Loop） | 具体 **接触力公式** 推导 |
| L3/L4/L5 **Algo TYPE 体系** 逐层展开 | 非接触域的过程算法（见各域 Procedure 文档） |
| **search_strategy PTR** + **3辅Algo** 详述 | **FRIC/UINTER/VUINTER ABI** 映射（见四型合订本 §3.5） |
| **Uzawa Loop**（Search→Detect→Force→Stiffness） | **声热耦合接触** 细节（见 PH_ThermalCont_Def） |

---

## 1. 三维度过程算法框架（接触域解读）

### 1.1 空间维度

接触域的空间维度关注 **接触搜索 / 对检测 / 几何描述**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **接触搜索** | BVH/Hash/CCD → 检测接触对 | `PH_Cont_Search_Desc_Algo%search_method` / `search_strategy` PTR |
| **对检测** | 间隙/穿透判断 → 生成接触单元 | `PH_Cont_Search_Desc_Algo%tolerance` / `%max_candidates` |
| **几何描述** | 主面/从面 → 法向/间隙 | `PH_Cont_Lcl_Pos` / `PH_Cont_Lcl_Normal` |
| **热接触映射** | 温度场→热流 | `PH_Thermal_Cont_Algo` |

### 1.2 时间维度

接触域的时间维度关注 **AugLag 迭代 / 罚参数更新 / 收敛控制**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **AugLag 迭代控制** | n_aug_max / rho_aug | `PH_Cont_Constr_Algo_Iter%n_aug_max` / `%rho_aug` |
| **收敛容差** | 力容差/间隙容差 | `PH_Cont_Constr_Algo_Tol` |
| **约束求解** | 直接/迭代求解 | `PH_Cont_Constr_Algo_Solver` |
| **L5 Uzawa 控制** | n_aug_max / search_frequency | `RT_Contact_Algo` |

### 1.3 动作维度

接触域的动作维度关注 **Uzawa Loop 四步管线**。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **Search** | BVH/Hash/CCD → 检测接触对 | `PH_Cont_Lcl_Pos`（间隙/穿透） |
| **Detect** | 间隙/穿透判断 → 生成接触单元 | `PH_Cont_Lcl_Normal`（法向） |
| **Force** | 法向/切向力计算 | 全局 F（经 RT_Asm） |
| **Stiffness** | 接触刚度 → K_c | 全局 K（经 RT_Asm） |

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 Algo TYPE（冷路径，Interaction 目录）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `MD_Cont_Stp_Ctl_Algo` ✅ P1 DONE | enforcement_method/penalty_normal/tangent/lagrange_tol/max_aug_iter/rho_aug/search_strategy/friction_coeff/tolerance_gap/slip/stabilization | 时间+空间+动作 |
| `MD_Cont_Algo` ✅ P1 DONE | stp_ctl(`MD_Cont_Stp_Ctl_Algo`) + legacy(`ContAlgo`) | 时间+空间+动作 |
| `MD_Int_AlgoCtrl_Algo` | algorithm_type / friction_model / penalty_stiffne / tolerance_gap | 空间+动作 |
| `MD_Int_AlgoSpec_Algo` | method / searchAlgo / searchRadius / stabilization | 空间+动作 |
| `MD_Int_UF_AlgoSpec_Algo` | 用户函数接触算法规格 | 空间+动作 |
| `MD_Int_FricParams_Algo` | mu_static / mu_kinetic / tolerance / velocity_depend | 动作 |

### 2.2 L4 Algo TYPE（热路径，最丰富域）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `PH_Cont_Search_Desc_Algo` | search_method / tolerance / max_candidates | **空间** |
| `PH_Cont_Constr_Algo` (3辅: Iter/Tol/Solver) | n_aug_max / rho_aug / penalty / lagrange | **时间+动作** |
| `PH_Cont_Friction_Algo` (2辅: Rate/Config) | friction_model / rate / config | **动作** |
| `PH_Contact_Cfg_Algorithm` | 域级算法配置聚合 | 空间+时间+动作 |
| `PH_Thermal_Cont_Algo` | 热接触算法参数 | 空间+动作 |

### 2.3 L5 Algo TYPE（运行期）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_Contact_Algo` | n_aug_max / rho_aug / search_frequency | 时间+动作 |

---

## 3. Procedure Pointer 架构

### 3.1 search_strategy PTR（L4 核心可插拔算法入口）

```fortran
! PH_Cont_Def.f90
ABSTRACT INTERFACE
  SUBROUTINE ContactSearchStrategy_Ifc(...)
    ! 可插拔接触搜索策略
    ! BVH / Hash / CCD / User-defined
  END SUBROUTINE
END ABSTRACT INTERFACE

! 域容器内:
PROCEDURE(ContactSearchStrategy_Ifc), POINTER :: search_strategy => NULL()
```

### 3.2 Procedure-as-Parameter 模式

接触域采用 **Procedure-as-Parameter** 模式（区别于 Material 的 PTR-in-Algo 模式）：
- `search_strategy` PTR 直接嵌入域容器（`PH_Contact_Cfg_Algorithm` 或 Domain TYPE）
- 与 3辅Algo（Constr_Iter/Tol/Solver）配合，实现搜索策略可插拔 + 约束参数结构化

### 3.3 族级配方绑定

```text
search_strategy PTR 绑定路径:
  PH_Cont_Domain%search_strategy
    ├── BVH_Search          ← 层次包围盒搜索
    ├── Hash_Search         ← 空间哈希搜索
    ├── CCD_Search          ← 连续碰撞检测
    └── User_Defined_Search ← 用户自定义搜索
```

---

## 4. Uzawa Loop 管线（核心动作管线）

### 4.1 管线全景

```text
PH_Cont_AlgorithmFramework (L4 AUTHORITY)
  │
  ├── Search (空间维度)
  │   └── search_strategy PTR → BVH/Hash/CCD → 检测接触对
  │   └── Algo 消费: PH_Cont_Search_Desc_Algo%search_method / %tolerance / %max_candidates
  │   └── State 写入: PH_Cont_Lcl_Pos (间隙/穿透坐标)
  │
  ├── Detect (空间→动作过渡)
  │   └── 间隙/穿透判断 → 生成接触单元
  │   └── Algo 消费: PH_Cont_Search_Desc_Algo%tolerance
  │   └── State 写入: PH_Cont_Lcl_Normal (法向量)
  │
  ├── Force (动作维度)
  │   └── 法向力: F_n = penalty * gap  (Penalty)  或  λ (Lagrange)
  │   └── 切向力: F_t = friction_coeff * F_n      (Coulomb)
  │   └── Algo 消费: PH_Cont_Constr_Algo_Iter%rho_aug (AugLag 更新)
  │   └── Algo 消费: PH_Cont_Friction_Algo%friction_model / %rate / %config
  │   └── State 写入: 全局 F (经 RT_Asm)
  │
  ├── Stiffness (动作维度)
  │   └── K_c = ∂F/∂u → 接触刚度贡献
  │   └── State 写入: PH_Cont_Lcl_Stiff(24,24)
  │   └── State 写入: 全局 K (经 RT_Asm)
  │
  └── Uzawa AugLag Loop (时间维度, L5 编排)
      └── for aug = 1, n_aug_max
      │   ├── 求解 K·u = F (含接触力)
      │   ├── 更新 Lagrange 乘子: λ += rho * gap
      │   └── 收敛检查: gap < tolerance?
      └── Algo 消费: RT_Contact_Algo%n_aug_max / %rho_aug
```

---

## 5. 跨域协作（接触域视角）

### 5.1 空间维度协作

| 协作域 | 空间操作 | 接触域角色 |
|--------|----------|-----------|
| Element | 接触面与单元面关联 | 消费单元面节点信息 |
| LoadBC | 接触力→Fext 装配顺序 | 接触力→Fext→BC 施加 |

### 5.2 时间维度协作

| 时间阶段 | 接触域动作 | 协作域 |
|----------|-----------|--------|
| Step Init | Populate + 搜索初始化 | Analysis (步驱动) |
| Itr Assemble | Search + Detect + Force | Solver (K/F 装配) |
| Itr Solve | Stiffness → K_c | Solver (接触刚度贡献) |
| Uzawa Loop | AugLag 迭代 | Solver (外层迭代) |

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| ✅ DONE | ~~L3 Contact 无统一 Algo TYPE~~ | ~~引入 `MD_Cont_Algo`~~ | **P1 已补全** (2026-05-04) |
| — | L4 3辅Algo 字段粒度 | 当前足够 | 按需扩展 |
| — | search_strategy PTR 仅在 Domain 容器 | Procedure-as-Parameter 模式合理 | 保持现状 |

**完备性评级**：✅ **P1 已补全**（`MD_Cont_Stp_Ctl_Algo` + `MD_Cont_Algo` 统一聚合；L4 最丰富（3辅+Procedure-as-Parameter）；L5 Uzawa 控制完备）

---

## 7. 设计原则（接触域特化）

1. **Uzawa Loop 嵌套 NR**：外层 AugLag 迭代嵌套内层 NR 迭代；收敛判断需两层协调。
2. **Procedure-as-Parameter 模式**：search_strategy PTR 嵌入域容器（而非 Algo TYPE），与 3辅Algo 配合。
3. **搜索→检测→力→刚度 四步不变式**：不可跳步；Search 必须在 Detect 之前，Force 必须在 Stiffness 之前。
4. **L4 3辅Algo 分离关注**：Constr_Iter 管迭代、Constr_Tol 管容差、Constr_Solver 管求解方法；职责分离。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `Contact_L3L4L5_four_type_synthesis.md` | 四型合订本；§3.5 主/辅架构图解 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.4 + A.3.2 | 过程算法全景合订（根 stub）；本文为接触域专域扩展 |
| `L4_PH/Contact/CONTRACT.md` | L4 合同卡；Algo TYPE 字段级真源 |
| [LoadBC_Procedure_Algorithm.md](../LoadBC_Procedure_Algorithm.md) | LoadBC Procedure；接触力→Fext 装配顺序 |
| [Element_Procedure_Algorithm.md](../Element_Procedure_Algorithm.md) | Element Procedure；接触面与单元面关联 |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/Contact_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/Contact_Procedure_Algorithm.md` 为 stub。四型合订本：`Contact_L3L4L5_four_type_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
