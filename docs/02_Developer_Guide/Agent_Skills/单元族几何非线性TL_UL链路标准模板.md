# 单元族几何非线性 TL/UL 链路标准模板

> **文档位置**：`UFC/docs/skills/单元族几何非线性TL_UL链路标准模板.md`
> **版本**：v1.0 | **日期**：2026-04-15
> **引用来源**：
> - [99-域级深度建模Skill规范(补充).md §4](../六层架构拆分/00-总纲/99-域级深度建模Skill规范(补充).md) — 权威 TL/UL Skill 规范
> - [archive/TL_UL_BEAM_Phase1_Audit.md](../archive/TL_UL_BEAM_Phase1_Audit.md) — BEAM 族 Phase 1 审计报告
> - [UFC_架构设计总纲 附录 G.3/H](../archive/PLAN_History/99_归档库/01_历史版本文档/UFC_架构设计总纲_六层四类四链三步三级两图一体.md) — TL/UL 适配模式
> **被引用于**：[00-知识体系与设计框架总览.md](../00-知识体系与设计框架总览.md)、[UFC架构设计文档指导手册.md](../UFC架构设计文档指导手册.md)

---

## 一、概述

### 1.1 TL / UL 方法简介

**几何非线性**分析分为两类格式，均基于连续介质力学的虚功方程：

| 格式 | 全称 | 参考构型 | 应力度量 | 应变度量 | 适用场景 |
| ---- | ---- | -------- | -------- | -------- | -------- |
| **TL** | Total Lagrangian（全拉格朗日） | 初始构型 Ω₀ | PK2（Second Piola-Kirchhoff） | Green-Lagrange（E） | 大转动、小应变（梁/壳）|
| **UL** | Updated Lagrangian（更新拉格朗日） | 当前构型 Ωₜ | Cauchy（真实应力 σ） | Almansi（或速度应变 d） | 大应变（金属塑性、橡胶） |

**TL 虚功方程**（参考构型 Ω₀）：
```
∫_{Ω₀} S : δE dV₀ = ∫_{Ω₀} ρ₀ b · δu dV₀ + ∫_{Γ₀} t̄ · δu dA₀
其中：S = PK2 应力；E = ½(FᵀF − I)（Green-Lagrange 应变）；F = I + ∇₀u
```

**UL 虚功方程**（当前构型 Ωₜ）：
```
∫_{Ωₜ} σ : δε dVₜ = ∫_{Ωₜ} ρ b · δu dVₜ + ∫_{Γₜ} t̄ · δu dAₜ
其中：σ = Cauchy 应力；ε = Almansi 应变
```

**应力度量转换**（TL ↔ UL）：
```
PK2 → Cauchy：σ = J⁻¹ F·S·Fᵀ
Cauchy → PK2：S = J F⁻¹·σ·F⁻ᵀ
其中 J = det(F)
```

**工程选用建议**：
- 小转动小应变：TL = UL（线性退化）
- 大转动小应变：**TL 更优**（共旋框架，梁/壳首选）
- 大应变（塑性/超弹性）：**UL 更优**（当前构型物理意义明确）

---

## 二、六层架构与域族上下文

### 2.1 三层职责划分

UFC 六层架构中，TL/UL 几何非线性横跨三层：

```
L3_MD（模型定义层）
  └─ ElementType / ElemFormulation / MaterialPropertyDef — 描述拓扑、插值阶次、TL/UL 开关
       ↓ Brg（只读传递）
L4_PH（物理层）
  └─ PH_Elem_<Family>_TLUL_Core — 单元族物理内核（B矩阵、本构调用、刚度/残差计算）
  └─ PH_Mat_* — 本构更新（PH_UpdateStress / PH_GetTangent）
       ↓ 返回 K_elem / R_elem
L5_RT（运行时层）
  └─ UF_Elem_<Family>_Calc — 统一调度入口（构造参数、调用 L4_PH、写回状态）
  └─ RT_Asm_NLGeom_Eval — 几何刚度矩阵 K_geo 构造与装配
```

### 2.2 严格包含约束

对任意单元族 D，TYPE 集合须满足：

```
T₃(D) ⊂ T₄(D) ⊂ T₅(D)
```

- L4/L5 的 `State_Type` 和 `GeomCtrl_Type` 必须**真超集**地包含 L3_MD 的描述类型，不得反转依赖。
- TL/UL 适配层中 **禁止** L3_MD 直接依赖 L4_PH / L5_RT。

---

## 三、单元族链路模板

### 3.1 L4_PH 统一入口签名（*_TLUL_Core）

```fortran
!----------------------------------------------------------------------
!> Unified TL/UL core for element family <Family>.
!>
!> Computation chain (4-step template):
!>   1. Configuration  : build F, N, dN/dξ, J from x_ref + u_n + u_inc
!>   2. State          : update strain ε / E; call PH_UpdateStress → σ / D
!>   3. B-matrix       : assemble B (TL: Green-Lagrange; UL: Almansi)
!>   4. Accumulate     : Kₑ += Bᵀ D B det(J) w;  Fₑ += Bᵀ σ det(J) w
!----------------------------------------------------------------------
SUBROUTINE PH_Elem_<Family>_TLUL_Core(elem_type, mat_prop, ctrl, &
                                      n_node, n_dof_per_node,    &
                                      x_ref, u_n, u_inc,         &
                                      state_in, K_elem, R_elem,  &
                                      state_out, ierr)
  USE IF_Prec,         ONLY: wp, i4
  USE MD_Elem_Types,   ONLY: ElementType
  USE MD_Mat_Types,    ONLY: MaterialPropertyDef
  IMPLICIT NONE

  TYPE(ElementType),          INTENT(IN)    :: elem_type
  TYPE(MaterialPropertyDef),  INTENT(IN)    :: mat_prop
  TYPE(PH_<Family>GeomCtrl),  INTENT(IN)    :: ctrl
  INTEGER(i4),                INTENT(IN)    :: n_node, n_dof_per_node
  REAL(wp),                   INTENT(IN)    :: x_ref(:,:)    ! [IN]  参考构型坐标
  REAL(wp),                   INTENT(IN)    :: u_n(:,:)      ! [IN]  上一步总位移
  REAL(wp),                   INTENT(IN)    :: u_inc(:,:)    ! [IN]  本步增量位移
  TYPE(PH_<Family>State),     INTENT(IN)    :: state_in      ! [IN]  积分点状态（旧）
  REAL(wp),                   INTENT(OUT)   :: K_elem(:,:)   ! [OUT] 单元切线刚度
  REAL(wp),                   INTENT(OUT)   :: R_elem(:)     ! [OUT] 单元内力残差
  TYPE(PH_<Family>State),     INTENT(OUT)   :: state_out     ! [OUT] 积分点状态（新）
  INTEGER(i4),                INTENT(OUT)   :: ierr          ! [OUT] 错误码 0=OK
END SUBROUTINE
```

### 3.2 L5_RT 统一调度签名（UF_Elem_*_Calc）

```fortran
!----------------------------------------------------------------------
!> RT-level dispatch for element family <Family>.
!> Logic chain:
!>   L5_RT: construct x_ref, u_n, u_inc, ctrl, mat_prop
!>   L4_PH: PH_Elem_<Family>_TLUL_Core → K_elem / R_elem
!>   L5_RT: scatter Kₑ/Fₑ into global K/F via RT_Asm_*
!----------------------------------------------------------------------
SUBROUTINE UF_Elem_<Family>_Calc(elementType, formulation, context, &
                                  state_in, material, state_out,     &
                                  flags)
  USE IF_Prec,         ONLY: wp, i4
  USE MD_Elem_Types,   ONLY: ElementType, ElemFormulation
  USE RT_Context_Types, ONLY: ElementContext, ElementFlags
  USE PH_Mat_Types,    ONLY: MaterialProperties
  IMPLICIT NONE

  TYPE(ElementType),         INTENT(IN)    :: elementType
  TYPE(ElemFormulation),     INTENT(IN)    :: formulation
  TYPE(ElementContext),      INTENT(IN)    :: context
  TYPE(elementState),        INTENT(IN)    :: state_in
  TYPE(MaterialProperties),  INTENT(IN)    :: material
  TYPE(elementState),        INTENT(INOUT) :: state_out
  TYPE(ElementFlags),        INTENT(INOUT) :: flags
END SUBROUTINE
```

### 3.3 材料属性映射（标准调用）

```fortran
! 在 UF_Elem_<Family>_Calc 中构造 mat_prop，禁止直接传裸数组
CALL UF_MatProp_Init(mat_prop,                              &
                     mat_id    = material%id,               &
                     num_props = SIZE(material%props%props), &
                     props     = material%props%props,      &
                     err_stat  = ierr)
```

---

## 四、几何非线性处理

### 4.1 四步过程模板

每个 Gauss 点循环内，严格遵循以下四步：

```
步骤 1 — Configuration（配置）
  ├─ 计算变形梯度 F = I + ∇₀u
  ├─ 形函数 N(ξ) 与梯度 ∂N/∂ξ（形函数库接口）
  └─ Jacobian J, det(J)

步骤 2 — State（状态更新）
  ├─ TL: E = ½(FᵀF − I)；strain_inc = E − E_old
  ├─ UL: ε = ½(I − F⁻ᵀF⁻¹)（Almansi）
  ├─ 调用本构：CALL PH_UpdateStress(mat_prop, mat_state, mat_ss, ierr)
  └─ 输出：σ（或 S），切线模量 D = ∂σ/∂ε

步骤 3 — B-matrix（B 矩阵构造）
  ├─ TL: B_TL 对应 Green-Lagrange 应变，含线性项 B_L 与非线性项 B_NL
  └─ UL: B_UL 对应 Almansi 应变（在当前构型下构造）

步骤 4 — Accumulate（刚度/残差累加）
  ├─ 材料刚度：K_mat += Bᵀ D B det(J) w_gp
  ├─ 几何刚度：K_geo += Gᵀ σ G det(J) w_gp（委托 RT_Asm_NLGeom_Eval）
  ├─ K_elem   += K_mat + K_geo
  ├─ R_elem   += Bᵀ σ det(J) w_gp
  └─ 写回状态：state_out%mat_state(igp) ← 新 MatPointState/MatPointStressStrain
```

### 4.2 刚度矩阵结构

切线刚度矩阵分解（以 3D 单元为例）：

```
K_tangent = K_mat + K_geo
  K_mat = ∫ Bᵀ D B dV₀         （材料刚度，B = 线性化应变矩阵）
  K_geo = ∫ Gᵀ σ G dV₀          （几何刚度，G = 形函数梯度矩阵，σ = 应力阵）
```

梁单元共旋框架下的切线刚度：

```
K_tangent = K_mat + K_geo + K_corot
  K_mat   = ∫ Bᵀ C B dV         （材料刚度）
  K_geo   = ∫ σ : ∇Nᵀ ∇N dV     （应力刚化）
  K_corot = ∂R/∂θ 项             （大转动耦合）
```

### 4.3 通用状态 TYPE 约定

所有 TL/UL 单元族的 `<Family>State_Type` **必须复用**以下材料状态类型（禁止平行定义）：

```fortran
! 来自 PH_MatConstitutive_Types 模块
TYPE, PUBLIC :: MatPointState
  INTEGER(i4) :: mat_id
  INTEGER(i4) :: num_statev
  REAL(wp), ALLOCATABLE :: statev(:), statev_old(:)
  REAL(wp) :: temperature, temperature_old
  REAL(wp) :: time_step, total_time
  LOGICAL  :: is_initialized
END TYPE

TYPE, PUBLIC :: MatPointStressStrain
  REAL(wp) :: strain(6), strain_inc(6), strain_old(6)
  REAL(wp) :: sigma(6),  stress_old(6)
  REAL(wp) :: tangent(6,6)
END TYPE
```

---

## 五、代码模板（Fortran 骨架示例）

### 5.1 GeomCtrl_Type 与 State_Type 骨架

```fortran
MODULE PH_Elem_<Family>_Types
  USE IF_Prec,              ONLY: wp, i4
  USE PH_MatConstitutive_Types, ONLY: MatPointState, MatPointStressStrain
  IMPLICIT NONE
  PRIVATE

  !-- 几何控制（Gauss 点配置 + TL/UL 开关）
  TYPE, PUBLIC :: PH_<Family>GeomCtrl
    INTEGER(i4) :: geom_mode    = 0   ! 1=TL, 2=UL, 0=linear
    INTEGER(i4) :: n_gauss      = 0   ! Gauss 点数
    REAL(wp), ALLOCATABLE :: xi(:,:)  ! Gauss 点坐标 (n_gauss × n_dim)
    REAL(wp), ALLOCATABLE :: w(:)     ! 积分权重 (n_gauss)
  END TYPE

  !-- 积分点状态（持有材料状态 + 几何辅助量）
  TYPE, PUBLIC :: PH_<Family>State
    TYPE(MatPointState),      ALLOCATABLE :: mat_state(:)  ! (n_gauss)
    TYPE(MatPointStressStrain), ALLOCATABLE :: mat_ss(:)   ! (n_gauss)
    ! 可选：几何辅助量
    REAL(wp), ALLOCATABLE :: F_def(:,:,:)  ! 变形梯度 (3,3,n_gauss) [TL/UL]
  END TYPE

END MODULE
```

### 5.2 TLUL_Core 内部骨架

```fortran
SUBROUTINE PH_Elem_<Family>_TLUL_Core(elem_type, mat_prop, ctrl, &
                                       n_node, n_dof_per_node,   &
                                       x_ref, u_n, u_inc,        &
                                       state_in, K_elem, R_elem, &
                                       state_out, ierr)
  IMPLICIT NONE
  ! ... 参数声明（见 3.1 节）...

  INTEGER(i4) :: igp
  REAL(wp)    :: N(n_node), dN_dxi(n_node, SIZE(x_ref,1))
  REAL(wp)    :: J_mat(SIZE(x_ref,1), SIZE(x_ref,1)), detJ
  REAL(wp)    :: B(6, n_node * n_dof_per_node)     ! strain-disp matrix
  REAL(wp)    :: G(9, n_node * n_dof_per_node)     ! geom stiff kernel

  K_elem = 0.0_wp
  R_elem = 0.0_wp
  ierr   = 0

  DO igp = 1, ctrl%n_gauss

    !-- Step 1: Configuration
    CALL PH_Elem_ShapeFun(n_node, ctrl%xi(igp,:), N, dN_dxi)
    CALL PH_Elem_Jacobian(x_ref, dN_dxi, J_mat, detJ)
    IF (detJ <= 0.0_wp) THEN; ierr = -1; RETURN; END IF

    !-- Step 2: State (strain + constitutive)
    ! ... construct u_loc from u_n / u_inc ...
    ! ... compute E (TL) or d (UL) from F ...
    CALL PH_UpdateStress(mat_prop, state_out%mat_state(igp), &
                         state_out%mat_ss(igp), ierr)
    IF (ierr /= 0) RETURN

    !-- Step 3: B-matrix
    ! ... assemble B according to ctrl%geom_mode ...

    !-- Step 4: Accumulate
    K_elem = K_elem + MATMUL(TRANSPOSE(B), MATMUL(state_out%mat_ss(igp)%tangent, B)) &
             * detJ * ctrl%w(igp)
    R_elem = R_elem + MATMUL(TRANSPOSE(B), state_out%mat_ss(igp)%sigma) &
             * detJ * ctrl%w(igp)
    ! Geometric stiffness delegated to RT_Asm_NLGeom_Eval

  END DO

END SUBROUTINE
```

### 5.3 geom_mode 路由示例（UF_Elem 层）

```fortran
SUBROUTINE PH_Elem_<Family>_Dispatch(formulation, ctrl, ierr)
  INTEGER(i4), INTENT(IN)    :: formulation   ! 1=TL, 2=UL
  TYPE(PH_<Family>GeomCtrl), INTENT(OUT) :: ctrl
  INTEGER(i4), INTENT(OUT)   :: ierr

  ctrl%geom_mode = formulation  ! 1=TL, 2=UL
  SELECT CASE (formulation)
    CASE (1)   ! Total Lagrangian
      ctrl%n_gauss = 8        ! e.g. C3D8: 2×2×2
    CASE (2)   ! Updated Lagrangian
      ctrl%n_gauss = 8
    CASE DEFAULT
      ierr = -1; RETURN
  END SELECT
  ierr = 0
END SUBROUTINE
```

---

## 六、与现有单元族的映射

### 6.1 BEAM 族（B3xNL 系列）

| 单元 | 当前状态 | DOF | 理论框架 | TL/UL 状态 |
| ---- | -------- | --- | -------- | ---------- |
| B31TNL | 生产就绪 | 14 | 共旋公式 + 热耦合 | ⏳ 规划中（TL 为主） |
| B32NL  | 生产就绪 | 18 | 共旋公式（3节点） | ⏳ 规划中 |
| B33NL  | 生产就绪 | 12 | 共旋 + Timoshenko | ⏳ 规划中 |
| B21NL  | ❌ 缺失   | 6  | 2D 共旋 | 待实现 |
| B22NL  | ❌ 缺失   | 9  | 2D 二次插值 | 待实现 |

**BEAM 族 TL/UL 对应的交付物**（参考 TL_UL_BEAM_Phase1_Audit.md §1.4）：
- `PH_Elem_B31_TL_Core.f90` — PK2 应力 + Green-Lagrange 应变
- `PH_Elem_B31_UL_Core.f90` — Cauchy 应力 + 当前构型积分

### 6.2 SHELL 族（S4 系列）

| 单元 | 当前状态 | L4_PH 模块 | TL/UL 状态 |
| ---- | -------- | ----------- | ---------- |
| S4   | 已实现   | PH_Elem_Shell_TLUL_Core | ✅ 范式已定义（见 99-Skill §4.5） |
| S3   | 已实现   | PH_Elem_S3_Definition   | ✅ 同 S4 家族 |

- `GeomCtrl_Type`：`PH_ShellGeomCtrl_Type`（含 geom_mode + 2×2 Gauss 点 ξ/η + 权重）
- `State_Type`：`PH_ShellState_Type`（积分点 MatPointState/MatPointStressStrain + 几何辅助量）

### 6.3 SLD3D 族（C3D8 系列）

| 单元 | 当前状态 | L4_PH 模块 | TL/UL 状态 |
| ---- | -------- | ----------- | ---------- |
| C3D8   | 已实现   | PH_Elem_Sld3D_TLUL_Core | ⏳ 规划中（见 99-Skill §4.6） |
| C3D8R  | 已实现（F-bar） | PH_Elem_C3D8_Core | ✅ F-bar 已实现 |

- `GeomCtrl_Type`：`PH_Sld3DGeomCtrl_Type`（2×2×2 Gauss 点 ξ/η/ζ + 权重）
- `State_Type`：`PH_Sld3DState_Type`（8 个积分点 × MatPointState/MatPointStressStrain + 变形梯度 F）

---

## 七、TL/UL 适配层通用检查清单

### 接口与类型

- [ ] 是否为该单元族定义了 `PH_Elem_<Family>_TLUL_Core` 与 `UF_Elem_<Family>_Calc`？
- [ ] `GeomCtrl_Type` / `State_Type` 满足 L4/L5 严格包含 L3 的 TYPE 约束？
- [ ] 统一使用 `MatPointState` / `MatPointStressStrain` 持有材料状态，未引入平行结构？
- [ ] 材料属性通过 `UF_MatProp_Init` 构造 `MaterialPropertyDef`，未直接传裸数组？

### 过程与算法

- [ ] 遵循"配置 → 状态 → B矩阵 → 刚度/残差"四步模板？
- [ ] B 矩阵与 Gauss 积分与单元理论章节一致（见 `01-理论基础/`）？
- [ ] 几何刚度委托给 `RT_Asm_NLGeom_Eval` 或等价工具，未在 L4_PH 内重复实现？
- [ ] `det(J)` 守卫检查（≤ 0 时返回错误码）？

### 跨层与依赖

- [ ] L5_RT 只通过 `UF_Elem_<Family>_Calc` 接入，不直接调用 L4_PH 内部子过程？
- [ ] `00-域级划分规范.md` 中补充了该单元族的 L3_MD → L4_PH → L5_RT 链路说明？
- [ ] 依赖方向无反转（L3_MD 不依赖 L4_PH，L4_PH 不依赖 L5_RT）？

### 注释与文档

- [ ] 模块头注释含 Theory chain / Computation chain（见 [UFC_流程图与注释规范_英文Unicode.md](../UFC_流程图与注释规范_英文Unicode.md) §四）？
- [ ] 新增单元族已在本文档第六章补充映射表条目？

---

## 八、相关文档索引

| 文档 | 路径 | 说明 |
| ---- | ---- | ---- |
| 域级深度建模Skill规范（TL/UL §4） | [六层架构拆分/00-总纲/99-域级深度建模Skill规范(补充).md](../六层架构拆分/00-总纲/99-域级深度建模Skill规范(补充).md) | 权威 Skill；本文档据此整理 |
| BEAM 族 Phase 1 审计报告 | [archive/TL_UL_BEAM_Phase1_Audit.md](../archive/TL_UL_BEAM_Phase1_Audit.md) | TL/UL 理论公式 + 差距分析 + 实施路线 |
| Element 四链贯通设计 | [PPLAN/06_核心架构/Element_四链贯通设计.md](../PPLAN/06_核心架构/Element_四链贯通设计.md) | calc_mode 路由（1=线性/2=NL-TL/3=NL-UL）|
| UFC 流程图与注释规范 | [UFC_流程图与注释规范_英文Unicode.md](../UFC_流程图与注释规范_英文Unicode.md) | 英文注释 + Unicode 符号 + 流程图模板 |
| 命名与数据结构规范 | [UFC_命名与数据结构规范.md](../UFC_命名与数据结构规范.md) | 四场景命名契约 |
| RT_Asm_NLGeom 几何刚度 | [PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md §RT_Asm](../PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md) | TL/UL 格式位移-应变关系 + K_geo |

---

*版本：v1.0 | 整理自：99-域级深度建模Skill规范(补充).md §4 + TL_UL_BEAM_Phase1_Audit.md + UFC架构设计总纲 附录 G.3*
