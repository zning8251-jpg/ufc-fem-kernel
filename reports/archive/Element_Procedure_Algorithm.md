# 单元域过程算法 Procedure — L3 / L4 / L5 三维度全景

**文档性质**：与 `Element_L3L4L5_four_type_UEL_discussion_synthesis.md`（四型合订本）并列的 **过程算法专域文档**；以 **空间维度 × 时间维度 × 动作维度** 三轴框架，系统性梳理单元域的过程算法。

**核心公式**：**完整功能模块 = 数据结构（四型TYPE：Desc/State/Algo/Ctx + Args）+ 过程算法（空间维度 + 时间维度 + 动作维度）**

**代码真源**：`ufc_core/L3_MD/Element/Elem/`（L3 Algo）、`ufc_core/L4_PH/Element/`（L4 Algo + integrator PTR + Shape Func Algo）、`ufc_core/L5_RT/Element/`（L5 Dispatch + Algo）。

**报告 ID**：`REP-ELEM-PROCEDURE`。

**与四型合订本关系**：本文 **不重复** 四型合订本 §3.5 的主/辅架构图解，而是以 **过程算法** 为核心视角；四型合订本 §6 integrator PTR 详述与本文 §3 互补。

---

## 0. 文档目的与范围

| 涵盖 | 不涵盖 |
|------|--------|
| 单元域 **三维度过程算法**：空间（Gauss积分/形函数/拓扑）、时间（步控制/动力学）、动作（integrator PTR） | 具体 **单元刚度矩阵** 公式推导 |
| L3/L4/L5 **Algo TYPE 体系** 逐层展开 | 非单元域的过程算法（见各域 Procedure 文档） |
| **integrator 过程指针** 架构与族级配方绑定 | **UEL ABI 参数映射**（见四型合订本 appendix C） |
| **Ke/Re 计算管线** 与 Algo 消费点 | **材料本构** S-Pipeline 细节（见 Material Procedure 文档） |

---

## 1. 三维度过程算法框架（单元域解读）

### 1.1 空间维度

单元域的空间维度关注 **Gauss 积分 / 形函数 / 拓扑映射**。

| 空间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **Gauss 积分阶数** | 全积分/减缩积分选择 | `PH_Elem_Stp_Ctl_Algo%integration_order` |
| **形函数计算** | N(ξ)/dN_dξ(ξ) → dN_dx | `PH_Elem_C3D20_ShapeFunc_Algo` / `PH_Elem_ShapeFunc` |
| **拓扑映射** | 单元类型→节点数/DOF/面定义 | `MD_Elem_Topology` |
| **Jacobi 变换** | 参考元→物理元映射 | `PH_Elem_C3D20_JacB_Algo` |
| **质量矩阵** | 一致/集中质量 | `PH_Elem_Mass_Algo` / `PH_Elem_Stp_Ctl_Dyn_Algo%mass_type` |

### 1.2 时间维度

单元域的时间维度关注 **步级控制 / 动力学参数 / 沙漏控制**。

| 时间操作 | 映射 | 代码落点 |
|----------|------|---------|
| **步级积分控制** | integration_order / hourglass / nlgeom | `PH_Elem_Stp_Ctl_Algo` |
| **动力学参数** | reduced_integ / mass_type / Rayleigh | `PH_Elem_Stp_Ctl_Dyn_Algo` |
| **沙漏控制** | viscous(1) / stiffness(2) / none(0) | `PH_Elem_Stp_Ctl_Algo%hourglass_control` |
| **NLGeom 标志** | 几何非线性开关 | `PH_Elem_Stp_Ctl_Algo%nlgeom` |

### 1.3 动作维度

单元域的动作维度关注 **integrator 可插拔算法入口**。

| 动作步骤 | 含义 | 写入点 |
|----------|------|--------|
| **Dispatch** | 族分类→选择 integrator 实现 | —（路由分发） |
| **Integrate** | 遍历 Gauss 点 → 调用 Material S-Pipeline | — |
| **Ke 计算** | 组装单元刚度矩阵 | 全局 K（经 RT_Asm） |
| **Re 计算** | 组装单元残差向量 | 全局 F（经 RT_Asm） |

---

## 2. L3 / L4 / L5 Algo TYPE 体系

### 2.1 L3 Algo TYPE（冷路径）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `MD_Elem_Stp_Ctl_Algo` | integration_order / hourglass_control / hourglass_coeff / nlgeom | 时间+空间 |
| `MD_Elem_Stp_Dyn_Algo` | reduced_integ / mass_type / alpha_rayleigh / beta_rayleigh | 时间+空间 |
| `MD_Elem_Algo` | stp_ctl(`MD_Elem_Stp_Ctl_Algo`) + stp_dyn(`MD_Elem_Stp_Dyn_Algo`) | 时间+空间 |
| `MD_Elem_Solid3D_Algo` | Solid3D 特有参数 | 空间 |
| `MD_Elem_Domain_Algo` | 域级算法参数 | 空间 |

### 2.2 L4 Algo TYPE（热路径）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `PH_Elem_Stp_Ctl_Algo` | integration_order / hourglass_control / hourglass_coeff / nlgeom | 时间+空间 |
| `PH_Elem_Stp_Ctl_Dyn_Algo` | reduced_integ / mass_type / alpha_rayleigh / beta_rayleigh | 时间+空间 |
| `PH_Elem_C3D20_ShapeFunc_Algo` | 形函数计算参数 | 空间 |
| `PH_Elem_C3D20_JacB_Algo` | Jacobi 变换参数 | 空间 |
| `PH_Elem_Mass_Algo` | 质量矩阵算法参数 | 空间+时间 |
| `PH_Elem_Algo` | integrator PTR + stp_ctl 嵌入 | **动作+时间+空间** |

### 2.3 L5 Algo TYPE（运行期）

| Algo TYPE | 核心字段 | 三维度归属 |
|-----------|----------|-----------|
| `RT_Elem_Algo` | 单元调度算法参数 | 时间+动作 |

---

## 3. Procedure Pointer 架构

### 3.1 integrator 过程指针（L4 核心可插拔算法入口）

```fortran
! PH_Elem_Def.f90 (AUTHORITY)
ABSTRACT INTERFACE
  SUBROUTINE PH_Elem_Integrator_Ifc(desc, state, ctx, algo, Ke, Re, status)
    IMPORT :: PH_Elem_Desc, PH_Elem_State, PH_Elem_Ctx, PH_Elem_Algo, &
             ErrorStatusType
    IMPLICIT NONE
    TYPE(PH_Elem_Desc),    INTENT(IN)    :: desc
    TYPE(PH_Elem_State),   INTENT(INOUT) :: state
    TYPE(PH_Elem_Ctx),     INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Algo),    INTENT(IN)    :: algo
    REAL(wp),              INTENT(OUT)   :: Ke(:,:)
    REAL(wp),              INTENT(OUT)   :: Re(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
  END SUBROUTINE
END ABSTRACT INTERFACE

! PH_Elem_Algo 内嵌:
PROCEDURE(PH_Elem_Integrator_Ifc), POINTER, NOPASS :: integrator => NULL()
```

### 3.2 族级配方绑定

```text
integrator PTR 绑定路径:
  PH_Elem_Algo%integrator
    ├── PH_Elem_C3D8_Core       ← Hex8 线性六面体
    ├── PH_Elem_C3D20_Core      ← Hex20 二次六面体
    ├── PH_Elem_C3D27_Core      ← Hex27 完全积分六面体
    ├── PH_Elem_Tet4_Core       ← Tet4 线性四面体
    ├── PH_Elem_Tet10_Core      ← Tet10 二次四面体
    ├── PH_Elem_Shell_Core      ← Shell 单元
    ├── PH_Elem_Beam_Core       ← Beam 单元
    └── PH_UEL_Execute          ← UEL 用户子程序桥接
```

### 3.3 辅助 Procedure Pointer

| 接口 | 用途 | 代码落点 |
|------|------|---------|
| `PH_Elem_ShapeFunc_Ifc` | 可插拔形函数计算 | `PH_Elem_ShapeFunc.f90` |
| `PH_Elem_dRdTheta_Ifc` | 残差灵敏度 | `PH_Elem_dRdTheta.f90` |
| `PH_UEL_Ifc` | UEL 用户子程序入口 | `PH_UEL_Def.f90` |

---

## 4. Ke/Re 计算管线（核心动作管线）

### 4.1 管线全景

```text
RT_Elem_Dispatcher (L5 金线)
  │
  ├── 1. 取 Element 槽: PH_Elem_Desc + State + Ctx + Algo
  │   └── Algo 消费: PH_Elem_Stp_Ctl_Algo%integration_order
  │   └── Algo 消费: PH_Elem_Stp_Ctl_Algo%nlgeom (几何非线性开关)
  │
  ├── 2. Dispatch: integrator PTR → 族级实现
  │   └── Algo 消费: PH_Elem_Algo%integrator PTR (可插拔算法选择)
  │
  ├── 3. Integrate (族级实现内部):
  │   ├── 3a. 遍历 Gauss 点
  │   │   ├── 形函数 N/dN_dξ → dN_dx (J^{-1} 变换)
  │   │   ├── B 矩阵组装 (应变-位移)
  │   │   └── 调用 Material S-Pipeline (S1→S4)
  │   │       └── S3: σ → 内力贡献
  │   │       └── S4: C_tan → 刚度贡献
  │   │
  │   ├── 3b. 沙漏力计算 (如启用)
  │   │   └── Algo 消费: PH_Elem_Stp_Ctl_Algo%hourglass_control
  │   │
  │   └── 3c. 质量矩阵 (动力学)
  │       └── Algo 消费: PH_Elem_Stp_Ctl_Dyn_Algo%mass_type
  │
  ├── 4. Ke 组装: ∫ B^T C_tan B dΩ + 沙漏 + 几何刚度
  │   └── 写入: 全局 K (经 RT_Asm)
  │
  └── 5. Re 组装: ∫ B^T σ dΩ - F_ext
      └── 写入: 全局 F (经 RT_Asm)
```

---

## 5. 跨域协作（单元域视角）

### 5.1 空间维度协作：M-S-E 三元

| 协作域 | 空间操作 | 单元域角色 |
|--------|----------|-----------|
| Material | IP 本构调用 | 每个 Gauss 点调用 S-Pipeline |
| Section | Populate 输入源 | 接收厚度/取向/ntens → PH_Elem_Desc |
| Contact | 接触面与单元面关联 | 提供面节点信息给 Contact Search |
| LoadBC | 分布载荷面 | 提供面面积/法向给 Load Assemble |

### 5.2 时间维度协作：迭代环中的单元更新

| 时间阶段 | 单元域动作 | 协作域 |
|----------|-----------|--------|
| Step Init | Populate + 初始化 | Analysis (步驱动) |
| Itr Assemble | integrator → Ke/Re | Material (S-Pipeline), Solver (装配) |
| Itr Update | 更新 u/du | Solver (位移更新) |

---

## 6. 缺口分析与对策

| 优先级 | 缺口 | 现状 | 对策 |
|--------|------|------|------|
| — | L3 族级 Algo 粒度不足 | 部分族级 Algo 仅有通用字段 | 按需在 L3 族级 Def 中扩展 |
| — | L5 RT_Elem_Algo 较简 | 当前仅含基础调度参数 | 随求解器增强按需扩展 |

**完备性评级**：✅ **三维度全覆盖**（空间: 族级积分+形函数+拓扑, 时间: Stp_Ctl+Dyn, 动作: integrator PTR）

---

## 7. 设计原则（单元域特化）

1. **integrator PTR 单入口**：所有族级单元经 `PH_Elem_Algo%integrator` 单指针进入，SELECT TYPE 在 Dispatch 内完成。
2. **Gauss 点 → Material S-Pipeline 调用不变式**：每个 Gauss 点必须完整执行 S1→S4，不可跳步。
3. **L4 Stp_Ctl 管步+Dyn 管动力学**：静态/准静态用 `PH_Elem_Stp_Ctl_Algo`；动力学追加 `PH_Elem_Stp_Ctl_Dyn_Algo`。
4. **沙漏控制与积分策略解耦**：沙漏控制字段在 `Stp_Ctl_Algo` 中独立管理，与 `integration_order` 无硬编码关联。

---

## 8. 交叉引用

| 关联文档 | 关系 |
|---------|------|
| `Element_L3L4L5_four_type_UEL_discussion_synthesis.md` | 四型合订本；§3.5 主/辅架构图解、§6 integrator PTR 详述 |
| [`Procedure_Algorithm_L3L4L5_synthesis.md`](../Procedure_Algorithm_L3L4L5_synthesis.md) B.2 | 过程算法全景合订（根 stub）；本文为单元域专域扩展 |
| `L4_PH/Element/CONTRACT.md` | L4 合同卡；Algo TYPE 字段级真源 |
| [Material_Procedure_Algorithm.md](../Material_Procedure_Algorithm.md) | Material Procedure；S-Pipeline 被单元调用 |
| [Section_Procedure_Algorithm.md](../Section_Procedure_Algorithm.md) | Section Procedure；M-S-E Populate 协作 |

---

*冷数据：正文已迁至 `UFC/REPORTS/archive/Element_Procedure_Algorithm.md`；根目录 `UFC/REPORTS/Element_Procedure_Algorithm.md` 为 stub。四型合订本：`Element_L3L4L5_four_type_UEL_discussion_synthesis.md`（根 stub）。全景合订：`Procedure_Algorithm_L3L4L5_synthesis.md`（根 stub）。*
