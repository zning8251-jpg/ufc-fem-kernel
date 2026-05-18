# L4_PH/Element 模块架构重构规划

**文档状态**：草稿——进行中  
**创建日期**：2026-03-31  
**| 最后更新：2026-04-02（更新：UFC Structured IO v2.0 规范 - 弃用 *_In/*_Out 对偶，改用 *_Args 统一结构）
**所属层**：L4_PH / Element 域  
**关联文件**：`UFC/ufc_core/L4_PH/Element/`

---

## 1. 背景与问题起源

### 1.1 讨论出发点

用户提出了一个架构优化设想：

> *既然单元大族（如 SLD2D）已经隐含了截面类型的分类，是否可以将六件套（Defn/Sect/Constraints/Contact/Loads/Out）按功能重组为 6 个大子程序，每个子程序覆盖整个大族的全部单元类型？其中 Constraints/Loads 按照 L5_RT/LoadBC 模板进行改造。*

该想法的核心驱动力是：发现族内各单元（如 CAX4/CAX8/CPS4/CPE4）之间的 Loads 和 Constraints 实现存在大量重复逻辑。

---

## 2. 现状分析

### 2.1 整体模块结构

`L4_PH/Element/` 目录当前按**单元大族**组织，共 13 个族：

| 族目录     | 文件数 | 描述                       |
|-----------|--------|----------------------------|
| SLD2D     | 13     | 2D 连续体（CAX/CPS/CPE，3/4/6/8节点） |
| SLD2DT    | 13     | 2D 热-力耦合连续体            |
| SLD3D     | 12     | 3D 连续体（C3D，4/5/6/8/10/13/15/20/27节点） |
| SLD3DT    | 8      | 3D 热-力耦合连续体            |
| POROUS    | 20     | 多孔介质（2D+3D，含 P 后缀）    |
| SHELL     | 13     | 壳单元（S3/S4/S6/S8/S9/DS系列） |
| BEAM      | 7      | 梁单元（B21/B23/B31/B32/B33） |
| TRUSS     | 4      | 桁架单元（T2D2/T3D2/T3D3）    |
| MEMBRANE  | 1      | 膜单元                       |
| ACOUSTIC  | 10     | 声学单元（AC2D/AC3D）         |
| Thermal   | 2      | 热传导单元                   |
| SPRING    | 3      | 弹簧单元                     |
| DASHPOT   | 3      | 阻尼单元                     |
| SPECIAL   | 12     | 特殊单元（刚体/黏结/垫片等）    |
| Shared/   | 17     | 公共工具（ShapeFunc/Jacobian/BMtx 等） |

**核心文件**：
- `PH_Element_Domain_Core.f90`：**4424 行**，L5_RT 唯一调用入口，汇聚所有族路由逻辑
- `PH_Elem_Reg_Core.f90`：注册表，elem_type → metadata（family, n_nodes, n_ip）
- `PH_Element_Structural_Facade.f90`：家族分类助手（3D体/2D体/壳梁桁/场类）

### 2.2 族内六件套分布（以 SLD2D 的 CAX4 为例）

每个 `PH_Elem_XXX_Core.f90` 文件内部均包含完整的六件套：

| 功能集     | CAX4 代表子程序                                    | 行数区间     |
|-----------|---------------------------------------------------|------------|
| **Defn**  | `PH_Elem_CAX4_DefInit`, `PH_Elem_CAX4_GaussPoints`, `ConstMatrix` | 411–491 |
| **Sect**  | `GetArea`, `GetVolume`, `GetCentroid`, `GetSectProps`  | 908–990 |
| **Constraints** | `ApplyConstraint`, `ApplyMPC`                   | 971–1001 |
| **Contact** | `FormContactContrib`, `FormContactEdgeCtr`          | 1002–1068 |
| **Loads** | `FormBodyForce`, `FormEdgePressure`, `FormNodalForce` | 1070–1160 |
| **Output** | `CollectIPVars`, `MapToNode`, `GetExtrapMat`, `EvalVonMises`, `EvalPrincStress`, `EvalStressInvar` | 1161–1253 |

**底层计算内核**：ShapeFunc / Jac / JacB / BMatrix / Strain / Stress / StiffMatrix / NL_TL / NL_UL（第 240–904 行）

---

## 3. 痛点识别

### 3.1 痛点 P1：Domain_Core 上帝文件（最高优先级）

**现象**：`PH_Element_Domain_Core.f90` 共 **4424 行**，USE 语句引用了超过 60 个族级模块，在一个文件中同时承担：
- 所有族的 Ke（刚度矩阵）路由
- 所有族的 Fe（力向量）路由
- 所有族的 Mass 路由
- L5_RT 对外金线接口
- 类型定义（Ctx/State/Params）

**根因**：调度职责（"分给哪个核"）与功能职责（"做什么"）混在一个文件，且随着单元族增加线性膨胀。

**影响**：
- 任何新增单元族都必须修改这个 4424 行的文件
- 编译依赖所有族模块，编译时间极长
- 可读性极差，调试困难

### 3.2 痛点 P2：族内 Constraints/Loads 重复逻辑

**现象**：SLD2D 族中 12 个单元文件（CAX3/4/6/8, CPS3/4/6/8, CPE3/4/6/8），每个文件都实现了如下结构几乎相同的子程序：

```fortran
! ApplyConstraint —— 12 个文件中逻辑完全一致，仅 NDOF 不同
SUBROUTINE PH_Elem_CAX4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)
  SELECT CASE (ctype)
    CASE (PH_ELEM_CTYPE_PENALTY_DOF)
      K_el(idof, idof) = K_el(idof, idof) + penalty
      F_el(idof) = F_el(idof) + penalty * val
    ...
  END SELECT
END SUBROUTINE
```

```fortran
! FormBodyForce —— CAX 系列与 CPS/CPE 系列差异仅在 TWOPI*r_pt 因子
! CAX4：dV = TWOPI * r_pt * detJ * w
! CPS4：dV = thickness * detJ * w（标量系数）
! CPE4：dV = 1.0 * detJ * w（平面应变单位厚度）
```

**根因**：六件套被设计为"每个单元独立实现"，没有提取族级公共内核层。

**影响**：
- 代码量虚高（12 倍重复）
- 修改一个载荷施加逻辑需要同步改 12 个文件
- 新增载荷类型（如旋转体力）需要在所有文件中逐一添加

### 3.3 痛点 P3：六件套中 Loads/Constraints 的物理层级混乱

**现象**：`PH_Elem_CAX4_FormBodyForce` 同时承担两个职责：
1. **物理计算**：高斯积分、N×b×TWOPI×r_pt×detJ×w（属于 L4_PH）
2. **载荷调度**：判断载荷类型（body force vs edge pressure）（本该属于 L5_RT）

**根因**：`L5_RT/LoadBC` 层目前只是 TODO 占位符（所有子程序无实际逻辑），迫使物理计算层吸收了调度职责。

**影响**：
- LoadBC 层和 Element 层职责边界模糊
- 无法复用载荷施加协议（不同族的载荷接口参数形状不统一）

### 3.4 痛点 P4：族内公共内核未沉淀到 Shared/

**现象**：`Shared/` 目录已有 ShapeFunc / Jacobian / BMtx 等工具，但 **Loads/Constraints/Output** 的通用逻辑没有被提取到 `Shared/`。

**根因**：模块是按"单元类型"粒度设计的，而非"功能"粒度。

---

## 4. 用户原始提案的可行性评估

### 4.1 原始提案：按六件套重组文件

```
提案方向：
  SLD2D/PH_Sld2D_Defn.f90        ← 所有单元的 Defn
  SLD2D/PH_Sld2D_Loads.f90       ← 所有单元的 Loads
  SLD2D/PH_Sld2D_Constraints.f90 ← 所有单元的 Constraints
  SLD2D/PH_Sld2D_Contact.f90     ← 所有单元的 Contact
  SLD2D/PH_Sld2D_Output.f90      ← 所有单元的 Output
  SLD2D/PH_Sld2D_Sect.f90        ← 所有单元的 Sect
```

### 4.2 评估结论

| 评估维度 | 结论 |
|---------|------|
| 消除重复 | 部分实现：把重复从"12个文件×N行"变成"1个文件×12个CASE分支" |
| 可维护性 | **下降**：SELECT CASE 内的族内差异仍然存在，且全部聚合在一个文件中 |
| 可扩展性 | **下降**：新增单元族需同时修改 6 个功能文件（vs 现在只加 1 个 Core 文件） |
| 性质判断 | **伪重组**：将差异从"文件级切分"下沉到"语句级 SELECT CASE"，本质未变 |
| 破坏范围 | 高：完全打乱现有按单元类型的组织体系 |

**结论**：原始提案不推荐执行。方向判断正确（Loads/Constraints 有重复，应当统一），但重组维度选错了。

---

## 5. 正确的解决思路

### 5.1 核心洞见：两条正交轴

Element 模块存在两个独立的组织维度：

```
维度A（纵向）：族路由轴
  "这个单元类型，用哪个物理内核？"
  → 现有按单元类型的文件组织解决了这个问题，应当保留

维度B（横向）：功能轴
  "Loads/Constraints/Output 的通用计算协议是什么？"
  → 当前没有独立的层次承载这个问题，导致重复
```

**解法**：不在维度A（文件组织）上动手，而是在维度B（功能层次）上新建一个「族级功能内核池」。

### 5.2 三层架构设计

```
第0层：注册与元数据（已有，保持不变）
  PH_Elem_Reg_Core.f90            ← elem_type → metadata（family, n_nodes, n_ip）
  PH_Element_Structural_Facade.f90 ← 家族分类助手

第1层：族级物理内核（已有，保持文件组织不变）
  SLD2D/PH_Elem_CAX4_Core.f90    ← 保留，但底层计算改为调用第2层内核
  SLD2D/PH_Elem_CPS4_Core.f90    ← 同上
  ...（12个文件）

第2层：族级功能内核池（新增，解决重复问题）   ← 核心新增点
  Shared/PH_Elem_Load_Kernel.f90   ← 体力/面力通用积分内核
  Shared/PH_Elem_BC_Kernel.f90     ← Constraint/MPC 通用逻辑
  Shared/PH_Elem_Out_Kernel.f90    ← IP变量收集/外推矩阵通用逻辑
  （已有的 ShapeFunc/Jac/BMtx 保持）

第3层：Domain 分发器（重构现有 4424 行）       ← 拆分现有上帝文件
  PH_Element_Domain_Core.f90      ← 精简为：仅保留对 L5_RT 的金线接口定义
  PH_Element_Ke_Dispatch.f90      ← 刚度矩阵族路由（从 Domain_Core 拆出）
  PH_Element_Fe_Dispatch.f90      ← 载荷/力向量族路由（从 Domain_Core 拆出）
  PH_Element_Out_Dispatch.f90     ← 输出后处理族路由（从 Domain_Core 拆出）
```

---

## 6. 详细解决方案

### 6.1 方案 S1：提取族级 Load_Kernel（优先级 P1，零破坏）

**目标**：提取 SLD2D 族所有单元 `FormBodyForce` / `FormEdgePressure` 的公共逻辑。

**核心洞见**：CAX/CPS/CPE 三类的差异**只在几何系数**：

```fortran
! CAX 类（轴对称）：
dV = TWOPI * r_pt * detJ * w       ! 体积微元含 2πr

! CPS 类（平面应力）：
dV = thickness * detJ * w          ! 厚度参数

! CPE 类（平面应变）：
dV = 1.0_wp * detJ * w             ! 单位厚度
```

**新建 `Shared/PH_Elem_Load_Kernel.f90`**：

```fortran
MODULE PH_Elem_Load_Kernel
  ! 族级载荷内核：体力/面力通用积分，接受几何系数参数
  USE IF_Prec, ONLY: wp, i4

  CONTAINS

  ! 通用体力积分（2D，n_node节点）
  ! geom_factor_func: 回调函数，给定 N(:) 和 coords，返回几何积分系数
  SUBROUTINE Sld2D_FormBodyForce_Generic(coords, b_vec, n_node, n_ip, &
                                          xi_arr, eta_arr, w_arr,     &
                                          geom_kind, geom_param,       &
                                          F_eq)
    INTEGER(i4), INTENT(IN) :: n_node, n_ip
    REAL(wp), INTENT(IN)    :: coords(2, n_node)
    REAL(wp), INTENT(IN)    :: b_vec(2)              ! (bx, by) or (br, bz)
    REAL(wp), INTENT(IN)    :: xi_arr(n_ip), eta_arr(n_ip), w_arr(n_ip)
    INTEGER(i4), INTENT(IN) :: geom_kind             ! 0=CPE, 1=CPS, 2=CAX
    REAL(wp), INTENT(IN)    :: geom_param            ! CPS:thickness, CAX:unused
    REAL(wp), INTENT(OUT)   :: F_eq(2*n_node)
    ! ... 通用 Gauss 积分循环，由 geom_kind 注入系数 ...
  END SUBROUTINE

  ! 通用边压力（2D，edge_id指定边号）
  SUBROUTINE Sld2D_FormEdgePressure_Generic(coords, p, edge_id, n_node, &
                                             geom_kind, geom_param, F_eq)
    ! ...
  END SUBROUTINE

END MODULE PH_Elem_Load_Kernel
```

**改造后各单元文件**（以 CAX4 为例）：

```fortran
SUBROUTINE PH_Elem_CAX4_FormBodyForce(coords, br, bz, F_eq)
  USE PH_Elem_Load_Kernel
  REAL(wp), INTENT(IN) :: coords(2,4), br, bz
  REAL(wp), INTENT(OUT) :: F_eq(8)
  REAL(wp) :: xi(4), eta(4), w(4)
  CALL PH_Elem_CAX4_GaussPoints(xi, eta, w)
  CALL Sld2D_FormBodyForce_Generic(coords, [br,bz], 4, 4, &
       xi, eta, w, geom_kind=2, geom_param=0.0_wp, F_eq=F_eq)
END SUBROUTINE
```

**效果**：12 个文件的 `FormBodyForce` 实现从"各自独立的 ~30 行"变成"各自 5 行 + 共享内核"。

---

### 6.2 方案 S2：提取族级 BC_Kernel（优先级 P1，零破坏）

**目标**：提取 `ApplyConstraint` / `ApplyMPC` 的公共逻辑。

**核心洞见**：`ApplyConstraint` 在 SLD2D 族中**完全相同**，差异只有 `ndof`（节点自由度数）。

```fortran
MODULE PH_Elem_BC_Kernel

  SUBROUTINE Sld_ApplyConstraint_Generic(ctype, idof, val, penalty, &
                                          ndof, K_el, F_el)
    INTEGER(i4), INTENT(IN) :: ctype, idof, ndof
    REAL(wp), INTENT(IN)    :: val, penalty
    REAL(wp), INTENT(INOUT) :: K_el(ndof, ndof), F_el(ndof)
    SELECT CASE (ctype)
      CASE (PH_ELEM_CTYPE_PENALTY_DOF)
        K_el(idof, idof) = K_el(idof, idof) + penalty
        F_el(idof) = F_el(idof) + penalty * val
      CASE (PH_ELEM_CTYPE_MPC_LINEAR)
        F_el(idof) = F_el(idof) + penalty * val
    END SELECT
  END SUBROUTINE

END MODULE PH_Elem_BC_Kernel
```

**效果**：12 个文件的 `ApplyConstraint` 直接委托给内核，各文件只需 3 行。

---

### 6.3 方案 S3：拆分 Domain_Core 上帝文件（优先级 P2，中等风险）

**目标**：将 4424 行的 `PH_Element_Domain_Core.f90` 按功能维度拆解。

**拆分策略**：

```
PH_Element_Domain_Core.f90（保留）
  → 仅保留：类型定义（Ctx/State/Params）+ L5_RT 金线接口声明
  → 目标行数：≤ 500 行

PH_Element_Ke_Dispatch.f90（新拆出）
  → 承载：Compute_Ke 的全部族路由 SELECT CASE 逻辑
  → 从 Domain_Core 第 ~800-2500 行迁移

PH_Element_Fe_Dispatch.f90（新拆出）
  → 承载：Compute_Fe（载荷向量）的全部族路由逻辑
  → 从 Domain_Core 第 ~2500-3800 行迁移

PH_Element_Out_Dispatch.f90（新拆出）
  → 承载：输出/后处理的族路由逻辑
  → 从 Domain_Core 第 ~3800-4424 行迁移
```

**接口设计原则**：
- `PH_Element_Domain_Core` 通过 `USE PH_Element_Ke_Dispatch` 等引入拆分模块
- 对外 PUBLIC 接口（`Compute_Ke`, `Compute_Fe`）保持不变
- L5_RT 调用方无感知

---

### 6.4 关于 L5_RT/LoadBC 层的职责厘清

**当前问题**：L5_RT/LoadBC 全是 TODO 占位符，导致载荷调度职责被迫下沉到 L4_PH 的族 Core 文件。

**正确的职责边界**：

```
L5_RT/LoadBC（调度层）：
  输入：全局载荷容器（load_id, amplitude_factor, bc_dofs[]）
  职责：遍历载荷集合，根据载荷类型 → 找到对应单元 → 调用 L4_PH 的载荷内核

L4_PH/Element/Shared/PH_Elem_Load_Kernel（物理计算层）：
  输入：单元坐标、载荷密度向量、几何类型参数
  职责：执行单元级高斯积分，计算等效节点力向量
```

**不应该**：在 `PH_Elem_CAX4_FormBodyForce` 内部判断载荷类型或访问全局载荷容器。

---

## 7. 执行路线图

### 7.1 优先级排序

| 步骤 | 行动 | 优先级 | 风险 | 预期收益 |
|------|------|--------|------|---------|
| S1 | 新建 `Shared/PH_Elem_Load_Kernel.f90` | **P1** | 低（新增文件，不改既有接口） | 消除 Loads 重复，为 RT_LoadBC 对接建立接口点 |
| S2 | 新建 `Shared/PH_Elem_BC_Kernel.f90` | **P1** | 低（同上） | 消除 Constraints 重复 |
| S3 | 将 SLD2D 各文件的 Loads/Constraints 委托到内核 | **P2** | 低（逐族渐进，可单独验证） | 实现族级统一，减少代码量约 70% |
| S4 | 拆分 `Domain_Core` 4424 行 | **P3** | 中（需保持接口不变） | 可维护性大幅提升，编译提速 |
| S5 | 充实 L5_RT/LoadBC，替换 TODO 为实际 L4_PH 调用 | **P4** | 低 | 厘清 L4/L5 职责边界 |

### 7.2 执行顺序建议

**阶段 1（零破坏，立即可执行）**：
- 执行 S1 + S2：在 `Shared/` 下新建两个内核文件
- 验证方法：gfortran 语法检查

**阶段 2（渐进改造）**：
- 执行 S3：以 SLD2D 为试点族，改造 CAX4 + CPS4 两个文件验证模式
- 验证方法：对比改造前后相同输入的输出向量

**阶段 3（架构整固）**：
- 执行 S4：拆分 Domain_Core，保持 PUBLIC 接口不变
- 验证方法：全量编译，L5_RT 调用路径不变

**阶段 4（层间对齐）**：
- 执行 S5：充实 L5_RT/LoadBC，建立与 L4_PH Load_Kernel 的正式对接

---

## 8. 关键决策记录

### 决策 D1：不按六件套重组文件
- **原因**：会破坏单元类型维度的组织完整性，SELECT CASE 膨胀至单个功能文件，新增单元族时需同时修改 6 个功能文件
- **替代方案**：提取族级内核到 `Shared/`，文件组织维度保持不变

### 决策 D2：Loads/Constraints 内核放在 Shared/ 而非独立域
- **原因**：Load_Kernel 属于跨族公共工具，不属于任何特定单元族；放在 `Shared/` 与 ShapeFunc/Jacobian 等工具保持一致
- **命名前缀**：`Sld2D_` 表示适用于 2D 实体族（可扩展为 Sld3D_）

### 决策 D3：Domain_Core 拆分方向按功能（Ke/Fe/Out）而非按族
- **原因**：按功能拆分后，Domain_Core 对 L5_RT 的接口不变；按族拆分则 L5_RT 需要感知族的存在，违反层间隔离原则

### 决策 D4：L5_RT/LoadBC 层应当充实而非删除
- **原因**：L5_RT 的职责是模型级载荷调度（遍历载荷集合、处理 amplitude、映射到单元），这个职责确实存在，只是当前实现为空壳；L4_PH 的 Load_Kernel 处理单元级物理积分，两者粒度不同，层次分离合理

### 决策 D5：Ce（阻尼矩阵）仅对专用单元有意义；Rayleigh 在 L5_RT 汇聚
- **原因**：连续体/壳/棁层单元的阻尼通过 Rayleigh 公式（C=αM+βK）在 L5_RT/Assembly 汇聚；只有 DASHPOT/SPRING 等专用单元在单元级定义 Ce，需纳入 `Mass_Dispatch` 路由

### 决策 D6：补充 `PH_Elem_Base_Desc` TYPE（当前缺失）
- **原因**：`PH_Elem_Types.f90` v4.0 只存 Ctx+State，单元元数据（族ID、节点数、DOF数、`geom_kind`）没有标准 TYPE 容器导致 Desc 信息分散在各族 Core 文件中为局部常量

### 决策 D7：重建 `PH_Elem_Base_Algo` TYPE（v4.0 删除后需补）
- **原因**：v4.0 删除 Algo 是因为将 Newmark 参数移至 RT 层，但单元级算法参数（积分阶次、hourglass控制、EAS/F-bar标志、结构阻尼参数）无处放置，导致它们散落在各处或硬编码

### 决策 D8：新建 `RT_Elem_Proc.f90`（Element 域 SIO-01）
- **原因**：`ufc-structured-io` 域推广矩阵显示 Element 域未开始；新建骨架文件把六参数规范级 L5_RT 调度接口标准化

---

## 9. 附录：族内差异度对照表

| 功能 | SLD2D 族内差异 | 差异本质 | 是否可提取共同内核 |
|------|--------------|---------|------------------|
| ApplyConstraint | 完全相同（仅 NDOF=8） | 无实质差异 | ✅ 立即可提取 |
| ApplyMPC | 完全相同 | 无实质差异 | ✅ 立即可提取 |
| FormBodyForce | CAX 有 TWOPI\*r_pt，CPS 有 thickness，CPE 为 1.0 | 几何系数差异 | ✅ 参数注入可提取 |
| FormEdgePressure | CAX 有轴对称面积修正，CPS/CPE 有平面坐标 | 几何计算差异 | ✅ geom_kind 参数可区分 |
| FormContactContrib | CAX 有 r_edge 参数，CPS/CPE 无 | 小差异 | ⚠️ 部分可提取 |
| CollectIPVars | 应力分量 4（CAX）vs 3（CPS/CPE） | 数据结构差异 | ⚠️ 需泛型设计 |
| GetArea/Volume | CAX 积分含 2πr，CPS/CPE 不含 | 积分公式差异 | ✅ geom_kind 参数可区分 |
| ShapeFunc/Jac/BMatrix | 已差异最小，B矩阵结构不同（4×8 vs 3×8） | 结构性差异 | 已在 Shared/ 有通用工具 |

---

## 10. Mass 与 Damp 的架构定位

### 10.1 问题：Mass 和 Damp 是否需要纳入重构？

现有代码中，与质量矩阵、阻尼矩阵相关的实现分散在三处：

| 文件 | 类型 | 当前状态 |
|------|------|----------|
| `PH_Mass_Core.f90` | 质量矩阵（Consistent/Lumped/Hybrid） | 独立模块，521 行，已存在 |
| `PH_Elem_ComplexStiff.f90` | 结构阻尼（K* = K·(1+2iη)） | 独立模块，92 行，已存在 |
| `DASHPOT/PH_Elem_DASHPOT2_Core.f90` | 粘性阻尼单元（Ce矩阵） | 族 Core 文件，435 行，已存在 |
| 各族 Core 文件 | `needDamp=.FALSE.` 接口占位 | TODO 占位符，未实现 |

### 10.2 Mass/Damp 的物理语义分层

```
动力学方程：M·ü + C·u̇ + K·u = F

三矩阵对应的职责归属：
┌─────────────────────────────────────────────────────────────┐
│  K（刚度）：L4_PH/Element 各族 FormStiffMatrix               │
│  M（质量）：L4_PH/Element/PH_Mass_Core（族无关通用积分）       │
│  C（阻尼）：                                                  │
│    ① 结构阻尼：L4_PH/Element/PH_Elem_ComplexStiff（K 的函数）│
│    ② 粘性阻尼：L4_PH/Element/DASHPOT/（专用单元族）           │
│    ③ Rayleigh阻尼：C = αM + βK（L5_RT 汇聚层计算，非单元级）  │
└─────────────────────────────────────────────────────────────┘
```

### 10.3 结论：纳入重构范围，但分不同优先级

| 矩阵 | 重构动作 | 优先级 |
|------|---------|--------|
| M（质量） | 纳入 Domain_Core 的 `PH_Element_Mass_Dispatch.f90` 拆分 | P3（与 Ke/Fe 同步拆分） |
| C（结构阻尼） | `PH_Elem_ComplexStiff` 保持独立，由 `Fe_Dispatch` 负责路由 | P3（路由层追加） |
| C（粘性阻尼） | DASHPOT 族 `FormDampMatrix` 纳入 `Ke_Dispatch` 路由 | P3 |
| C（Rayleigh） | 属于 L5_RT 层（C=αM+βK 在 Assembly 完成），不下沉到 L4 | 不纳入 |

**关键决策 D5**：单元级阻尼矩阵（Ce）仅对专用单元（DASHPOT/SPRING）有意义；连续体单元（SLD2D/SLD3D等）的阻尼由 Rayleigh 公式在 L5_RT/Assembly 层合成，不在 L4 单元级计算。因此，`PH_Element_Domain_Core` 的拆分新增 `Mass_Dispatch`，而 `Damp_Dispatch` 仅限于 DASHPOT/SPRING 族。

---

## 11. 架构正交矩阵全景图

### 11.1 族×功能集完整正交矩阵

```
族(FAMILY)       Ke    Fe_BF Fe_EP Fe_NF  Ce    Me    BC    Cont  Out
────────────────────────────────────────────────────────────────────────
SLD2D  CAX      ★    ★     ★     ★    —    ★     ★    ★     ★
       CPS      ★    ★     ★     ★    —    ★     ★    ★     ★
       CPE      ★    ★     ★     ★    —    ★     ★    ★     ★
SLD2DT CAX_T   ★    ★     ★     ★    —    ★     ★    —     ★
       CPS_T   ★    ★     ★     ★    —    ★     ★    —     ★
SLD3D  C3D      ★    ★     ★     ★    —    ★     ★    ★     ★
SLD3DT C3D_T   ★    ★     ★     ★    —    ★     ★    —     ★
PORUS  2D/3D   ★    ★     ★     ★    —    ★     ★    —     ★
SHELL  S3/S4   ★    ★     ★     ★    —    ★     ★    ★     ★
BEAM   B21-B33  ★    ★     ★     ★    —    ★     ★    —     ★
TRUSS  T2D2    ★    ★     —     ★    —    ★     ★    —     ★
MEMBR  M3D     ★    ★     ★     ★    —    ★     ★    —     ★
DASHP  DASH1/2  —    —     —     —   ★    —     ★    —     —
SPRIN  SPR1/2   ★    —     —     ★   —    —     ★    —     —
ACOUS  AC2D/3D  ★    ★     ★     —    —    ★     ★    —     ★
────────────────────────────────────────────────────────────────────────
共用内核层(Shared/)：
  Ke  = FormStiffMatrix   → 各族独立（结构差异大）
  Fe_BF = FormBodyForce   → ✅ Sld2D_FormBodyForce_Generic (geom_kind)
  Fe_EP = FormEdgePressure → ✅ Sld2D_FormEdgePressure_Generic
  Fe_NF = FormNodalForce  → ✅ 完全通用（与族无关）
  Ce  = FormDampMatrix    → 仅 DASHPOT 有意义
  Me  = ConsMass/LumpMass → ✅ PH_Mass_Core（已有通用积分）
  BC  = ApplyConstraint   → ✅ Sld_ApplyConstraint_Generic (ndof)
  Cont = FormContactContrib → ⚠️ 部分通用
  Out = CollectIPVars     → ⚠️ 需泛型设计

图例: ★=需要实现  —=不适用/不需要  ✅=可提取共用内核
```

### 11.2 拆分后 Domain_Core 文件组织图

```
                    L5_RT 调用入口
                         │
                         ▼
          ┌──────────────────────────┐
          │  PH_Element_Domain_Core  │  ← 保留（精简为 ≤500行）
          │  · 类型定义 Ctx/State    │    仅保留 PUBLIC 接口声明
          │  · L5_RT 金线接口        │    + USE 各 Dispatch 模块
          └──────┬─────────┬─────────┘
                 │         │
        ┌────────┘  ┌──────┘
        ▼           ▼
 ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
 │ Ke_Dispatch│ │ Fe_Dispatch│ │Mass_Dispatch│ │Out_Dispatch│
 │ ~800行     │ │ ~600行     │ │ ~400行     │ │ ~400行     │
 │ (从4424行  │ │            │ │            │ │            │
 │  拆出)     │ │            │ │            │ │            │
 └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
       │               │               │               │
       ▼               ▼               ▼               ▼
  各族 *_Core.f90 ←──── Shared/ 功能内核池 ────────────┘
  ·SLD2D/CAX4       · PH_Elem_Load_Kernel.f90  (体力/面力)
  ·SLD2D/CPS4       · PH_Elem_BC_Kernel.f90    (约束)
  ·SLD3D/C3D8       · PH_Elem_Out_Kernel.f90   (输出)
  ·SHELL/S4         · PH_Mass_Core.f90         (已有)
  ·BEAM/B31         · PH_Elem_ComplexStiff.f90 (已有)
  ·...              · ShapeFunc/Jac/BMtx       (已有)
```

---

## 12. 四大类 TYPE 完整设计（Desc/State/Algo/Ctx）

### 12.1 现状缺口分析

当前 `PH_Elem_Types.f90` 仅定义了两类：

| 类别 | 当前状态 | 问题 |
|------|---------|------|
| **Desc** | ❌ 不存在 | 单元元数据（族ID、节点数、自由度数）没有标准 TYPE 容器 |
| **State** | ✅ `PH_Elem_Base_State`（已有） | 包含 rhs/amatrx/svars/energy 等，设计完善 |
| **Algo** | ❌ v4.0 中被删除 | Newmark 参数被移至 RT 层，但单元级算法参数（积分阶次、hourglass控制）无处放置 |
| **Ctx** | ✅ `PH_Elem_Base_Ctx`（已有） | 包含 gauss_rule/shape_N 等热路径缓存，设计完善 |

### 12.2 补充 Desc TYPE 设计

`PH_Elem_Base_Desc` 存储**单元静态元数据**（冷路径，一次写入）：

```fortran
!-----------------------------------------------------------------------------
! DESC - Element Descriptor (静态元数据，冷路径，一次写入)
! 存储：族ID、节点数、DOF数、积分点数、几何类型标识
!-----------------------------------------------------------------------------
TYPE, PUBLIC :: PH_Elem_Base_Desc
  ! 基础标识
  INTEGER(i4) :: elem_type_id   = 0_i4   ! PH_ELEM_C3D8, PH_ELEM_CAX4, ...
  INTEGER(i4) :: family_id      = 0_i4   ! PH_ELEM_FAMILY_SLD2D, ...
  INTEGER(i4) :: n_nodes        = 0_i4   ! nodes per element
  INTEGER(i4) :: n_dof          = 0_i4   ! DOFs per element = n_nodes * dof_per_node
  INTEGER(i4) :: n_ip           = 0_i4   ! Gauss points
  INTEGER(i4) :: ndim           = 0_i4   ! spatial dimension (2 or 3)
  INTEGER(i4) :: dof_per_node   = 0_i4   ! DOFs per node
  ! 几何类型标识（横切 SLD2D 族的 geom_kind）
  INTEGER(i4) :: geom_kind      = 0_i4   ! 0=CPE,1=CPS,2=CAX,3=3D,4=shell...
  REAL(wp)    :: geom_param     = 0.0_wp ! CPS: thickness; CAX: unused
  ! 功能标志（位掩码）
  INTEGER(i4) :: has_mass       = 0_i4   ! 1=支持质量矩阵
  INTEGER(i4) :: has_damp       = 0_i4   ! 1=支持阻尼矩阵（仅DASHPOT等）
  INTEGER(i4) :: has_contact    = 0_i4   ! 1=支持接触贡献
  INTEGER(i4) :: has_thermal    = 0_i4   ! 1=热力耦合
  INTEGER(i4) :: has_pore       = 0_i4   ! 1=孔压耦合
  ! 非线性标志
  INTEGER(i4) :: nlgeom         = 0_i4   ! 0=线性, 1=TL, 2=UL
END TYPE PH_Elem_Base_Desc
```

### 12.3 补充 Algo TYPE 设计

`PH_Elem_Base_Algo` 存储**单元级算法参数**（Step级只读，非Newmark级框架参数）：

```fortran
!-----------------------------------------------------------------------------
! ALGO - Element Algorithm Parameters (Step级只读，不含Newmark参数)
! 注意：Newmark/HHT-α参数已在v4.0移至RT_Com_Base_Ctx，此处不重复
! 存储：积分策略、hourglass控制参数、稳定化参数
!-----------------------------------------------------------------------------
TYPE, PUBLIC :: PH_Elem_Base_Algo
  ! 积分阶次控制
  INTEGER(i4) :: ip_scheme      = 0_i4   ! 0=默认, 1=reduced, 2=full, 3=selectively_reduced
  INTEGER(i4) :: ip_override    = 0_i4   ! 0=自动按族, >0=强制积分点数
  ! Hourglass 控制（缩减积分必备）
  REAL(wp)    :: hourglass_coeff = 0.0_wp ! Flanagan-Belytschko 沙漏系数 κ
  INTEGER(i4) :: hourglass_type = 0_i4   ! 0=无, 1=stiffness, 2=viscous
  ! EAS/B-bar 增强参数
  INTEGER(i4) :: use_eas        = 0_i4   ! 1=启用 EAS (C3D8_EAS)
  INTEGER(i4) :: use_fbar       = 0_i4   ! 1=启用 F-bar (C3D8_FBar)
  ! 结构阻尼
  REAL(wp)    :: struct_damp_eta = 0.0_wp ! 复刚度阻尼因子 η
  ! Rayleigh 参数（L5_RT 汇聚层使用，此处仅做传递载体）
  REAL(wp)    :: rayleigh_alpha = 0.0_wp  ! 质量比例系数 α
  REAL(wp)    :: rayleigh_beta  = 0.0_wp  ! 刚度比例系数 β
END TYPE PH_Elem_Base_Algo
```

### 12.4 四大类与矩阵计算的对应关系

```
动力学方程: M·ü + C·u̇ + K·u = F

  Desc  ─── 提供 n_nodes, n_dof, n_ip, geom_kind → 决定矩阵尺寸和积分策略
  Algo  ─── 提供 ip_scheme, hourglass_coeff, rayleigh_α/β → 控制 Ke/Me/Ce 计算方式
  Ctx   ─── 提供 gauss_xi/w/detJ, shape_N/dN_dx → 热路径积分点缓存
  State ─── 存储 amatrx(Ke/Me/Ce), rhs(Fe), svars, energy → 输出结果
```

---

## 13. 结构体嵌套索引 + 扁平域存储设计

### 13.1 设计动机

Element 域的数据访问有两种需求：
1. **逻辑访问**（嵌套索引）：按单元ID → 获取该单元的完整 Desc/State
2. **批量计算**（扁平域存储）：对所有单元的某个字段执行向量化操作

两种需求如果只用一种模式，会产生矛盾：嵌套结构便于逻辑访问但不利于向量化；扁平数组利于向量化但不便于按单元索引。

### 13.2 双轨存储方案

```fortran
!-----------------------------------------------------------------------------
! PH_Elem_Domain_Container — Element域容器（结构体嵌套索引 + 扁平域存储双轨）
!-----------------------------------------------------------------------------
TYPE, PUBLIC :: PH_Elem_Domain_Container

  ! ── A. 扁平域存储（SoA: Structure of Arrays）── 批量向量化友好
  ! 所有单元的 Desc 字段展开为独立数组（按单元索引）
  INTEGER(i4), ALLOCATABLE :: elem_type_id(:)   ! [n_elem] 单元类型ID数组
  INTEGER(i4), ALLOCATABLE :: family_id(:)       ! [n_elem] 族ID数组
  INTEGER(i4), ALLOCATABLE :: n_dof_arr(:)       ! [n_elem] 每单元DOF数
  INTEGER(i4), ALLOCATABLE :: n_ip_arr(:)        ! [n_elem] 每单元积分点数
  INTEGER(i4), ALLOCATABLE :: geom_kind_arr(:)   ! [n_elem] 几何类型（横切SLD2D族）
  REAL(wp), ALLOCATABLE    :: geom_param_arr(:)  ! [n_elem] 几何系数（CPS厚度等）

  ! State 扁平域：Ke/Me/Fe 块存储（变长，需偏移表）
  REAL(wp), ALLOCATABLE :: Ke_flat(:)            ! 所有单元Ke连续存储
  REAL(wp), ALLOCATABLE :: Me_flat(:)            ! 所有单元Me连续存储
  REAL(wp), ALLOCATABLE :: Fe_flat(:)            ! 所有单元Fe连续存储
  INTEGER(i4), ALLOCATABLE :: ke_offset(:)       ! [n_elem+1] Ke在flat中的起始偏移
  INTEGER(i4), ALLOCATABLE :: fe_offset(:)       ! [n_elem+1] Fe偏移

  ! ── B. 嵌套索引（AoS: Array of Structures）── 逻辑访问友好
  ! 每单元完整的 Desc/State（按需访问，冷路径）
  TYPE(PH_Elem_Base_Desc),  ALLOCATABLE :: desc_arr(:)   ! [n_elem]
  TYPE(PH_Elem_Base_State), ALLOCATABLE :: state_arr(:)  ! [n_elem]

  ! ── C. 共享 Algo/Ctx（跨单元不变量）
  TYPE(PH_Elem_Base_Algo) :: algo               ! Step级算法参数（不随单元变化）
  TYPE(PH_Elem_Base_Ctx)  :: ctx                ! 热路径上下文（增量内共享）

  ! ── D. 容器元数据
  INTEGER(i4) :: n_elem = 0_i4                  ! 单元总数
  INTEGER(i4) :: max_ndof = 0_i4                ! 最大单元DOF数（预分配依据）
  LOGICAL     :: is_initialized = .FALSE.        ! 初始化标志

END TYPE PH_Elem_Domain_Container
```

### 13.3 热路径访问模式

```
热路径（Assembly循环内，按单元遍历）：
  DO i_elem = 1, n_elem
    ! 1. 从扁平域读取元数据（SoA，缓存友好）
    eid    = elem_type_id(i_elem)       ! 直接数组访问，无间接寻址
    ndof   = n_dof_arr(i_elem)
    gkind  = geom_kind_arr(i_elem)
    gpar   = geom_param_arr(i_elem)

    ! 2. 定位当前单元的 Ke/Fe 存储块
    ke_start = ke_offset(i_elem)
    ke_end   = ke_offset(i_elem+1) - 1
    Ke => Ke_flat(ke_start:ke_end)       ! 零拷贝指针指向，无ALLOCATE

    ! 3. 调用 Dispatch 路由
    CALL PH_Element_Ke_Dispatch(eid, coords, Ke, algo, ctx, status)
  END DO

冷路径（诊断/输出，按单元逻辑访问）：
  ASSOCIATE(d => desc_arr(i_elem))      ! 通过嵌套索引访问完整 Desc
    WRITE(*,*) 'elem', i_elem, 'family=', d%family_id, 'n_ip=', d%n_ip
  END ASSOCIATE
```

---

## 14. UFC Structured IO v2.0 规范（强制要求）

> **规范来源**：UFC Principle #14 - Structured IO v2.0  
> **核心原则**：**弃用 `*_In/*_Out` 对偶设计，改用统一的 `*_Args` 结构，通过 `[IN]/[OUT]` 注释区分方向**

### 14.0.1 旧规范（已废弃）

```fortran
! ❌ 已废弃：in/out 对偶设计
TYPE :: XXX_In
  ! 输入字段...
END TYPE XXX_In
TYPE :: XXX_Out
  ! 输出字段...
END TYPE XXX_Out
SUBROUTINE XXX_Structured(in, out)
  TYPE(XXX_In), INTENT(IN) :: in
  TYPE(XXX_Out), INTENT(OUT) :: out
```

### 14.0.2 新规范（强制）

```fortran
! ✅ 推荐：统一 *_Args 结构 + [IN]/[OUT] 注释
TYPE :: XXX_Args
  ! [IN] 输入字段（只读）
  ! [OUT] 输出字段（返回结果）
END TYPE XXX_Args

SUBROUTINE XXX_Proc(desc, state, algo, ctx, args)
  ! [IN]  desc    : 类型描述
  ! [IN]  state   : 状态
  ! [IN]  algo    : 算法参数
  ! [IN]  ctx     : 运行时上下文
  ! [IN/OUT] args : 统一参数结构（[IN]输入 + [OUT]输出）
```

### 14.0.3 五参签名（标准形式）

```fortran
SUBROUTINE <Feature>_<Op>_Proc(desc, state, algo, ctx, args)
  ! [IN]  desc  : 类型描述（描述性参数）
  ! [IN]  state : 状态变量（积分点状态）
  ! [IN]  algo  : 算法参数（迭代控制）
  ! [IN]  ctx   : 运行时上下文
  ! [IN/OUT] args : 统一参数结构（[IN]输入 + [OUT]输出）
```

---

## 14. SIO 接口规划（RT_Elem_Proc.f90）

### 14.1 当前状态

根据 `ufc-structured-io` 技能的域推广矩阵，Element 域目前是 **❌ 未开始** 状态，需要新建 `RT_Elem_Proc.f90`。

### 14.2 Element 域操作清单（v2.0 - *_Args 格式）

| 操作名 | 描述 | _Args 关键字段 |
|--------|------|----------------|
| `Init` | 初始化域容器，分配扁平存储 | `[IN] n_elem, mode, verbose` → `[OUT] initialized, status, message` |
| `PopulateDesc` | 从 L3 Mesh 填充 Desc 数组 | `[IN] mesh_ptr, reg_ptr` → `[OUT] n_populated, status` |
| `ComputeKe` | 计算单元刚度矩阵（调度到 L4 内核） | `[IN] elem_idx, nlgeom_flag` → `[OUT] Ke_updated, status` |
| `ComputeMe` | 计算单元质量矩阵 | `[IN] elem_idx, mass_type` → `[OUT] Me_updated, status` |
| `ComputeFe` | 计算单元载荷向量（体力+面力+节点力） | `[IN] elem_idx, load_flags` → `[OUT] Fe_updated, status` |
| `ComputeCe` | 计算单元阻尼矩阵（仅DASHPOT等专用单元） | `[IN] elem_idx, damp_type, damp_coeff` → `[OUT] Ce_updated, status` |
| `CollectOutput` | 收集积分点输出变量 | `[IN] elem_idx, out_var_ids` → `[OUT] ip_vars, status` |
| `Finalize` | 释放域容器内存 | `[IN] none` → `[OUT] status` |

### 14.3 SIO 骨架（RT_Elem_Proc.f90 片段 - v2.0）

```fortran
!===============================================================================
! Module: RT_Elem_Proc                                                   [v2.0]
! Layer: L5_RT - Runtime Layer
! Domain: Element
!
! UFC Principle #14 v2.0：五参规范 (desc, state, algo, ctx, args)
!     - 弃用 *_In/*_Out 对偶，改用 *_Args 统一结构
!===============================================================================
MODULE RT_Elem_Proc
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK, STATUS_ERROR
  ! 四大类 TYPE（来自 L4_PH 层，RT 层通过 Bridge 引用）
  USE PH_Elem_Types, ONLY: PH_Elem_Base_State, PH_Elem_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Elem_Init_Args
  PUBLIC :: RT_Elem_ComputeKe_Args
  PUBLIC :: RT_Elem_ComputeMe_Args
  PUBLIC :: RT_Elem_ComputeFe_Args
  PUBLIC :: RT_Elem_ComputeCe_Args
  PUBLIC :: RT_Elem_Init_Proc
  PUBLIC :: RT_Elem_ComputeKe_Proc

  !-------------------------------------------
  ! RT_Elem_Init_Args（统一参数结构）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_Init_Args
    ! [IN] 输入参数
    INTEGER(i4) :: n_elem   = 0_i4
    INTEGER(i4) :: mode     = 0_i4   ! 0=default, 1=flat-only, 2=nested-only
    LOGICAL     :: verbose  = .FALSE.
    ! [OUT] 输出参数
    LOGICAL            :: initialized = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Elem_Init_Args

  !-------------------------------------------
  ! RT_Elem_ComputeKe_Args（统一参数结构）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_ComputeKe_Args
    ! [IN] 输入参数
    INTEGER(i4) :: elem_idx    = 0_i4   ! 目标单元索引
    INTEGER(i4) :: nlgeom_flag = 0_i4   ! 0=linear, 1=TL, 2=UL
    ! [OUT] 输出参数
    LOGICAL     :: Ke_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_ComputeKe_Args

  !-------------------------------------------
  ! RT_Elem_ComputeMe_Args（含 Damp 路由标志）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_ComputeMe_Args
    ! [IN] 输入参数
    INTEGER(i4) :: elem_idx  = 0_i4
    INTEGER(i4) :: mass_type = 1_i4  ! 1=Consistent, 2=Lumped_rowsum, 4=HRZ
    ! [OUT] 输出参数
    LOGICAL     :: Me_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_ComputeMe_Args

  !-------------------------------------------
  ! RT_Elem_ComputeCe_Args（阻尼专用）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_ComputeCe_Args
    ! [IN] 输入参数
    INTEGER(i4) :: elem_idx   = 0_i4
    INTEGER(i4) :: damp_type  = 0_i4  ! 0=不计算; 1=viscous(DASHPOT); 2=complex_stiff
    REAL(wp)    :: damp_coeff = 0.0_wp! c 或 η
    ! [OUT] 输出参数
    LOGICAL     :: Ce_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_ComputeCe_Args

  !-------------------------------------------
  ! 抽象接口（五参规范）
  !-------------------------------------------
  ABSTRACT INTERFACE
    SUBROUTINE RT_Elem_Init_Proc(desc, state, algo, ctx, args)
      IMPORT :: wp, i4, PH_Elem_Base_State, PH_Elem_Base_Ctx, RT_Elem_Init_Args
      TYPE(PH_Elem_Base_State), INTENT(INOUT) :: state
      TYPE(PH_Elem_Base_Ctx),   INTENT(INOUT) :: ctx
      TYPE(RT_Elem_Init_Args),  INTENT(INOUT) :: args  ! [IN]输入 + [OUT]输出
    END SUBROUTINE

    SUBROUTINE RT_Elem_ComputeKe_Proc(desc, state, algo, ctx, args)
      IMPORT :: wp, i4, PH_Elem_Base_State, PH_Elem_Base_Ctx, RT_Elem_ComputeKe_Args
      TYPE(PH_Elem_Base_State),         INTENT(INOUT) :: state
      TYPE(PH_Elem_Base_Ctx),           INTENT(INOUT) :: ctx
      TYPE(RT_Elem_ComputeKe_Args), INTENT(INOUT) :: args  ! [IN]输入 + [OUT]输出
    END SUBROUTINE
  END INTERFACE

END MODULE RT_Elem_Proc
```

### 14.4 SIO 合规性自检清单（Element 域 - v2.0）

| 规则 | 状态 | 说明 |
|------|------|------|
| SIO-01 | ❌ 待建 | `RT_Elem_Proc.f90` 不存在 |
| SIO-02 | ✅ 规划中 | 8个操作均使用 *_Args 统一结构 |
| SIO-03 | 规划中 | 所有 *_Args 含 `ErrorStatusType::status` |
| SIO-04 | 规划中 | 2个 ABSTRACT INTERFACE 已设计（五参规范） |
| SIO-05 | ✅ | 弃用 *_In/*_Out 对偶，改用 [IN]/[OUT] 注释 |
| SIO-11 | ✅ | TYPE 体内无 INTENT（规范已遵守） |
| SIO-12 | 部分 | 待 Desc/Algo TYPE 完善后升级为完整五参 |
| SIO-13 | ✅ | *_Args 不内嵌四大类（规范已遵守） |
  ABSTRACT INTERFACE

## 14. SIO 六参数接口规划（RT_Elem_Proc.f90）

### 14.1 当前状态

根据 `ufc-structured-io` 技能的域推广矩阵，Element 域目前是 **❌ 未开始** 状态，需要新建 `RT_Elem_Proc.f90`。

### 14.2 Element 域操作清单（v2.0 - *_Args 格式）

| 操作名 | 描述 | _Args 关键字段 |
|--------|------|----------------|
| `Init` | 初始化域容器，分配扁平存储 | `[IN] n_elem, mode` → `[OUT] initialized, status` |
| `PopulateDesc` | 从 L3 Mesh 填充 Desc 数组 | `[IN] mesh_ptr, reg_ptr` → `[OUT] n_populated, status` |
| `ComputeKe` | 计算单元刚度矩阵（调度到 L4 内核） | `[IN] elem_idx, nlgeom_flag` → `[OUT] Ke_updated, status` |
| `ComputeMe` | 计算单元质量矩阵 | `[IN] elem_idx, mass_type` → `[OUT] Me_updated, status` |
| `ComputeFe` | 计算单元载荷向量（体力+面力+节点力） | `[IN] elem_idx, load_flags` → `[OUT] Fe_updated, status` |
| `ComputeCe` | 计算单元阻尼矩阵（仅DASHPOT等专用单元） | `[IN] elem_idx, damp_type, damp_coeff` → `[OUT] Ce_updated, status` |
| `CollectOutput` | 收集积分点输出变量 | `[IN] elem_idx, out_var_ids` → `[OUT] ip_vars, status` |
| `Finalize` | 释放域容器内存 | `[IN] none` → `[OUT] status` |

### 14.3 SIO 骨架（RT_Elem_Proc.f90 片段 - v2.0）

```fortran
!===============================================================================
! Module: RT_Elem_Proc                                                   [v2.0]
! Layer: L5_RT - Runtime Layer
! Domain: Element
!
! UFC Principle #14 v2.0：五参规范 (desc, state, algo, ctx, args)
!     - 弃用 *_In/*_Out 对偶，改用 *_Args 统一结构
!===============================================================================
MODULE RT_Elem_Proc
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK, STATUS_ERROR
  ! 四大类 TYPE（来自 L4_PH 层，RT 层通过 Bridge 引用）
  USE PH_Elem_Types, ONLY: PH_Elem_Base_State, PH_Elem_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Elem_Init_Args
  PUBLIC :: RT_Elem_ComputeKe_Args
  PUBLIC :: RT_Elem_ComputeMe_Args
  PUBLIC :: RT_Elem_ComputeFe_Args
  PUBLIC :: RT_Elem_ComputeCe_Args
  PUBLIC :: RT_Elem_Init_Proc
  PUBLIC :: RT_Elem_ComputeKe_Proc

  !-------------------------------------------
  ! RT_Elem_Init_Args（统一参数结构）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_Init_Args
    ! [IN] 输入参数
    INTEGER(i4) :: n_elem   = 0_i4
    INTEGER(i4) :: mode     = 0_i4   ! 0=default, 1=flat-only, 2=nested-only
    LOGICAL     :: verbose  = .FALSE.
    ! [OUT] 输出参数
    LOGICAL            :: initialized = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Elem_Init_Args

  !-------------------------------------------
  ! RT_Elem_ComputeKe_Args（统一参数结构）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_ComputeKe_Args
    ! [IN] 输入参数
    INTEGER(i4) :: elem_idx    = 0_i4   ! 目标单元索引
    INTEGER(i4) :: nlgeom_flag = 0_i4   ! 0=linear, 1=TL, 2=UL
    ! [OUT] 输出参数
    LOGICAL     :: Ke_updated  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_ComputeKe_Args

  !-------------------------------------------
  ! RT_Elem_ComputeMe_Args（含 Damp 路由标志）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_ComputeMe_Args
    ! [IN] 输入参数
    INTEGER(i4) :: elem_idx  = 0_i4
    INTEGER(i4) :: mass_type = 1_i4  ! 1=Consistent, 2=Lumped_rowsum, 4=HRZ
    ! [OUT] 输出参数
    LOGICAL     :: Me_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_ComputeMe_Args

  !-------------------------------------------
  ! RT_Elem_ComputeCe_Args（阻尼专用）
  !-------------------------------------------
  TYPE, PUBLIC :: RT_Elem_ComputeCe_Args
    ! [IN] 输入参数
    INTEGER(i4) :: elem_idx   = 0_i4
    INTEGER(i4) :: damp_type  = 0_i4  ! 0=不计算; 1=viscous(DASHPOT); 2=complex_stiff
    REAL(wp)    :: damp_coeff = 0.0_wp! c 或 η
    ! [OUT] 输出参数
    LOGICAL     :: Ce_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Elem_ComputeCe_Args

---

## 15. 完整一次性设计决策汇总（D1–D8）

| 决策编号 | 内容 | 影响范围 |
|---------|------|----------|
| D1 | 不按六件套重组文件，保留族路由文件组织 | SLD2D/SLD3D/SHELL等全部族 |
| D2 | Loads/Constraints 内核提取到 `Shared/` | 12个SLD2D文件优先，后推广到其他族 |
| D3 | Domain_Core 按功能拆分（Ke/Fe/Mass/Out Dispatch） | PH_Element_Domain_Core.f90 |
| D4 | L5_RT/LoadBC 充实而非删除，厘清与L4的职责边界 | RT_LoadBC_Proc.f90 |
| D5 | Ce（阻尼矩阵）仅对专用单元有效，Rayleigh在L5_RT汇聚 | PH_Element_Domain_Core拆分时追加Mass_Dispatch |
| D6 | 补充 `PH_Elem_Base_Desc` TYPE（现不存在） | PH_Elem_Types.f90 需新增 |
| D7 | 补充 `PH_Elem_Base_Algo` TYPE（v4.0删除后需重建） | PH_Elem_Types.f90 需新增 |
| D8 | 新建 `RT_Elem_Proc.f90`（SIO五参v2.0，Element域SIO-01） | L5_RT/Element/（目录待建） |

---

## 16. 实施路线图（更新版）
---

## 16. 实施路线图（更新版）

| 阶段 | 步骤 | 文件 | 风险 | 前提 |
|------|------|------|------|------|
| **阶段1** | S1: 新建 `PH_Elem_Load_Kernel.f90` | Shared/ 下新增 | 低 | 无 |
| **阶段1** | S2: 新建 `PH_Elem_BC_Kernel.f90` | Shared/ 下新增 | 低 | 无 |
| **阶段1** | D6: 在 `PH_Elem_Types.f90` 补充 `PH_Elem_Base_Desc` | 现有文件追加 | 低 | 无 |
| **阶段1** | D7: 在 `PH_Elem_Types.f90` 补充 `PH_Elem_Base_Algo` | 现有文件追加 | 低 | 无 |
| **阶段2** | S3: SLD2D 族 Loads/Constraints 委托到内核（CAX4+CPS4试点） | 2个Core文件改造 | 低 | S1+S2完成 |
| **阶段2** | D8: 新建 `RT_Elem_Proc.f90`（SIO五参v2.0） | L5_RT/新增 | 低 | D6+D7完成 |
| **阶段3** | S4: 拆分 Domain_Core → Ke/Fe/Mass/Out Dispatch | 重构4424行 | 中 | 阶段1完成 |
| **阶段4** | 全族 S3 推广（SLD3D/SHELL/BEAM/TRUSS等） | ~40个Core文件 | 低 | S3试点通过 |
| **阶段4** | S5: 充实 L5_RT/LoadBC | RT层 | 低 | D8完成 |

---

## 17. Element 域全子域清单与现状评估

### 17.4 SIO 合规性自检清单（Element 域 - v2.0）

| 规则 | 状态 | 说明 |
|------|------|------|
| SIO-01 | ❌ 待建 | `RT_Elem_Proc.f90` 不存在 |
| SIO-02 | ✅ 规划中 | 8个操作均使用 *_Args 统一结构 |
| SIO-03 | ✅ | 所有 *_Args 含 `ErrorStatusType::status` |
| SIO-04 | ✅ | 2个 ABSTRACT INTERFACE 已设计（五参规范） |
| SIO-05 | ✅ | **弃用 *_In/*_Out 对偶，改用 [IN]/[OUT] 注释** |
| SIO-11 | ✅ | TYPE 体内无 INTENT（规范已遵守） |
| SIO-12 | 部分 | 待 Desc/Algo TYPE 完善后升级为完整五参 |
| SIO-13 | ✅ | *_Args 不内嵌四大类（规范已遵守） |

---

## 15. 完整一次性设计决策汇总（D1–D8）

| 决策编号 | 内容 | 影响范围 |
|---------|------|----------|
| D1 | 不按六件套重组文件，保留族路由文件组织 | SLD2D/SLD3D/SHELL等全部族 |
| D2 | Loads/Constraints 内核提取到 `Shared/` | 12个SLD2D文件优先，后推广到其他族 |
| D3 | Domain_Core 按功能拆分（Ke/Fe/Mass/Out Dispatch） | PH_Element_Domain_Core.f90 |
| D4 | L5_RT/LoadBC 充实而非删除，厘清与L4的职责边界 | RT_LoadBC_Proc.f90 |
| D5 | Ce（阻尼矩阵）仅对专用单元有效，Rayleigh在L5_RT汇聚 | PH_Element_Domain_Core拆分时追加Mass_Dispatch |
| D6 | 补充 `PH_Elem_Base_Desc` TYPE（现不存在） | PH_Elem_Types.f90 需新增 |
| D7 | 补充 `PH_Elem_Base_Algo` TYPE（v4.0删除后需重建） | PH_Elem_Types.f90 需新增 |
| D8 | 新建 `RT_Elem_Proc.f90`（SIO五参v2.0，Element域SIO-01） | L5_RT/Element/（目录待建） |

---

## 16. 实施路线图（更新版）

| 阶段 | 步骤 | 文件 | 风险 | 前提 |
|------|------|------|------|------|
| **阶段1** | S1: 新建 `PH_Elem_Load_Kernel.f90` | Shared/ 下新增 | 低 | 无 |
| **阶段1** | S2: 新建 `PH_Elem_BC_Kernel.f90` | Shared/ 下新增 | 低 | 无 |
| **阶段1** | D6: 在 `PH_Elem_Types.f90` 补充 `PH_Elem_Base_Desc` | 现有文件追加 | 低 | 无 |
| **阶段1** | D7: 在 `PH_Elem_Types.f90` 补充 `PH_Elem_Base_Algo` | 现有文件追加 | 低 | 无 |
| **阶段2** | S3: SLD2D 族 Loads/Constraints 委托到内核（CAX4+CPS4试点） | 2个Core文件改造 | 低 | S1+S2完成 |
| **阶段2** | D8: 新建 `RT_Elem_Proc.f90`（SIO骨架） | L5_RT/新增 | 低 | D6+D7完成 |
| **阶段3** | S4: 拆分 Domain_Core → Ke/Fe/Mass/Out Dispatch | 重构4424行 | 中 | 阶段1完成 |
| **阶段4** | 全族 S3 推广（SLD3D/SHELL/BEAM/TRUSS等） | ~40个Core文件 | 低 | S3试点通过 |
| **阶段4** | S5: 充实 L5_RT/LoadBC | RT层 | 低 | D8完成 |

---

## 17. Element 域全子域清单与现状评估

### 17.0 子域划分依据

Element 域横跨 L4_PH（物理内核）和 L5_RT（运行时调度）两层，按**职责正交性**划分为 10 个子域。每个子域对应一组内聚文件，子域之间通过明确的 USE 依赖（单向）连接。

```
子域ID  子域名称           层       核心职责
────────────────────────────────────────────────────────────────────
SD-01  Registry          L4_PH    单元类型注册表：elem_type→元数据映射
SD-02  Types_L4          L4_PH    四大类TYPE（Ctx/State；Desc/Algo待补）
SD-03  Types_L5          L5_RT    四大类TYPE（RT_Elem_Desc/Ctx/State/Algo）
SD-04  GaussInt          L4_PH    高斯积分规则（1D/2D/3D+面/边）
SD-05  ShapeFunc         L4_PH    形函数 N(ξ)/∂N/∂x，100+ 单元类型
SD-06  Jacobian_BMtx     L4_PH    雅可比矩阵、B矩阵、几何非线性工具
SD-07  FamilyKernels     L4_PH    15个族的物理内核文件（Ke/Fe/Ce/Me/Out）
SD-08  Shared_Utils      L4_PH    跨族公共工具（Load/BC/Out内核，待建）
SD-09  Domain_Core       L4_PH    上帝文件，4424行路由总入口（待拆分）
SD-10  RT_Dispatcher     L5_RT    运行时调度层（Dispatcher/UEL桥接）
```

---

### 17.1 SD-01 注册子域（Registry）

**核心文件**：

| 文件 | 行数 | 状态 | 职责 |
|------|------|------|------|
| `PH_Elem_Reg_Core.f90` | 478 | ✅ 完善 | 单元注册表（450槽，8族ID，CONTAINS Add/Get/InitAll） |
| `PH_Element_Structural_Facade.f90` | ~200 | ✅ 存在 | 家族分类助手（3D体/2D体/壳梁桁/场类判断） |
| `MD_FieldState_Core.f90` | 存在 | ✅ 存在 | 场状态核心（L3→L4桥接） |

**关键常量**：
```
PH_ELEM_REG_MAX = 450        ! 最大注册槽
PH_ELEM_FAMILY_C3D   = 1     ! 3D连续体
PH_ELEM_FAMILY_CPE   = 2     ! 平面应变
PH_ELEM_FAMILY_CPS   = 3     ! 平面应力
PH_ELEM_FAMILY_CAX   = 4     ! 轴对称
PH_ELEM_FAMILY_S     = 5     ! 壳
PH_ELEM_FAMILY_B     = 6     ! 梁
PH_ELEM_FAMILY_T     = 7     ! 桁架
PH_ELEM_FAMILY_OTHER = 8     ! 声学/热/弹簧/DASHPOT/特殊
```

**注意**：注册表中的 `family_id`（8类）与 `RT_Elem_Dispatcher` 中的 `elem_family`（5类：Continuum/Shell/Beam/Truss/Special）**不对齐**，是 SD-01 与 SD-10 之间的已知接口差异，需在 D9 决策中明确。

**重构动作**：SD-01 自身稳定，无需改造；只需在 SD-03 RT层类型中确保族ID枚举对齐。

---

### 17.2 SD-02 L4层类型子域（Types_L4）

**核心文件**：

| 文件 | 行数 | 状态 | 说明 |
|------|------|------|------|
| `PH_Elem_Types.f90` | 116 | ⚠️ 不完整 | 仅有 Ctx + State（v4.0），Desc/Algo 缺失 |
| `PH_Elem_GaussInt.f90` | 259 | ✅ 完善 | GaussRule TYPE（含 CONTAINS 绑定，架构豁免） |
| `PH_Elem_Ctx.f90` | 506 | ✅ 独立模块 | 完整 Ctx 管理（Init/Clear/Copy/Valid + *_Args 统一结构） |

**缺口明细**：

```
TYPE 名称                  当前状态    目标状态
PH_Elem_Base_Ctx           ✅ PH_Elem_Types.f90 L116   → 保持
PH_Elem_Base_State         ✅ PH_Elem_Types.f90 L81    → 保持
PH_Elem_Base_Desc          ❌ 不存在                   → §12.2 设计，需新增
PH_Elem_Base_Algo          ❌ v4.0删除                 → §12.3 设计，需重建
PH_Elem_UEL_Ctx            ✅ 被RT_Elem_Types USE引用  → 需确认源文件
PH_Elem_UEL_State          ✅ 被RT_Elem_Types USE引用  → 需确认源文件
PH_Elem_VUEL_Ctx           ✅ 被RT_Elem_Types USE引用  → 需确认源文件
PH_Elem_VUEL_State         ✅ 被RT_Elem_Types USE引用  → 需确认源文件
```

**UEL/VUEL 类型来源确认**：`RT_Elem_Types.f90` 第28-30行 `USE PH_Elem_Types, ONLY: PH_Elem_UEL_Ctx, PH_Elem_UEL_State, PH_Elem_VUEL_Ctx, PH_Elem_VUEL_State`，而当前 `PH_Elem_Types.f90`（116行）中**并不包含**这些类型的定义——说明这些类型另有来源（可能在 `PH_Elem_Ctx.f90` 506行模块或其他独立文件），需单独追踪。

**重构动作**：
- **阶段1**（D6）：在 `PH_Elem_Types.f90` 追加 `PH_Elem_Base_Desc` TYPE
- **阶段1**（D7）：在 `PH_Elem_Types.f90` 追加 `PH_Elem_Base_Algo` TYPE
- 确认并文档化 UEL/VUEL 类型的实际源文件

---

### 17.3 SD-03 L5层类型子域（Types_L5）

**核心文件**（`L5_RT/Element/`）：

| 文件 | 行数 | 状态 | 说明 |
|------|------|------|------|
| `RT_Elem_Types.f90` | 325 | ✅ 完善 | 四大类 RT_Elem_Desc/Ctx/State/Algo 全定义 |
| `RT_Elem_UEL.f90` | 存在 | 存在 | UEL 桥接层 |
| `RT_Elem_Sect.f90` | 存在 | 存在 | 截面属性管理 |
| `CONTRACT.md` | 存在 | ✅ | 接口合同文档 |

**RT_Elem_Types.f90 四大类内容摘要**：

```
RT_Elem_Desc    ：elem_id/jtype/elem_family/nnode/ndofel/mcrd/nsvars/nprops/njprop
                  integ_scheme/integ_npts/nlgeom/use_bbar/use_eas（来自 MD 层 USE）
RT_Elem_Ctx     ：mat_ctx(PH_Elem_Base_Ctx组合)/coords/du/predef/adlmag/ddlmag
                  step_time/total_time/dtime/step_idx/incr_idx/iter_idx/analysis_type
RT_Elem_State   ：rhs/amatrx/svars/energy(8)/u/v/a/converged/iterations/residual_norm
RT_Elem_Algo    ：integ_rule/max_gp_stress/hg_control/hg_stiffness/use_bbar_method
                  use_eas_method/mass_lump/mass_scale_factor/max_newton_iter/newton_tol
                  output_stress/output_strain/output_energy
```

**关键发现 - 接口规格差异**：
```fortran
! 当前 RT_Elem_Types.f90 中定义的抽象接口（四参数）：
SUBROUTINE RT_Elem_Compute_Proc(desc, ctx, state, algo, status)  ! 5参数（含status）

! UFC SIO 规范要求的六参数签名：
SUBROUTINE Proc(desc, state, algo, ctx, inp, out)               ! 6参数
```

两者的差异分析见 §20。

**重构动作**：SD-03 结构良好，近期只需关注 §20 的接口迁移规划。

---

### 17.4 SD-04 高斯积分子域（GaussInt）

**核心文件**：

| 文件 | 位置 | 行数 | 状态 | 说明 |
|------|------|------|------|------|
| `PH_Elem_GaussInt.f90` | Element/ | 259 | ✅ 完善 | GaussRule TYPE，含 CONTAINS 绑定 |
| `Shared/PH_Elem_IntegPts.f90` | Shared/ | 存在 | ✅ 存在 | 三角/四面体积分点表 |

**GaussRule TYPE 方法一览**：
```
Init1D(order)          → 1D Gauss-Legendre（order=1/2/3）
Init2D(order)          → 2D 四边形（张量积）
Init3D(order)          → 3D 六面体（张量积）
GetFaceRule(face_id, order, face_gauss)  → 六面体面积分
GetEdgeRule(edge_id, order, edge_gauss)  → 四边形边积分
```

**架构注意**：`GaussRule` TYPE 含 `CONTAINS` 绑定过程，按规范需豁免审查（物理数值工具类，非数据传递类）。

**重构动作**：SD-04 稳定完善，无需改造；`Shared/PH_Elem_IntegPts.f90`（三角/四面体特殊积分点）与 `GaussInt` 互补，保持并存。

---

### 17.5 SD-05 形函数子域（ShapeFunc）

**核心文件**：

| 文件 | 位置 | 行数 | 状态 | 说明 |
|------|------|------|------|------|
| `PH_Elem_ShapeFunc.f90` | Element/（根目录） | 存在 | ✅ 存在 | 根目录版本（较新） |
| `Shared/PH_Elem_ShapeFunc.f90` | Shared/ | 存在 | ✅ 存在 | Shared版本 |

**注意**：根目录和 `Shared/` 下各有一个 `PH_Elem_ShapeFunc.f90`，存在**文件重叠**问题，需明确哪个是权威版本。

**形函数覆盖范围**（按族）：
```
SLD2D（CAX/CPS/CPE）：三角形N3/N6，四边形N4/N8
SLD3D（C3D）        ：四面体N4/N10，六面体N8/N20/N27，五面体N6/N15
SHELL              ：退化壳单元形函数
BEAM               ：Hermitian 梁形函数
TRUSS              ：线性 T2D2/T3D2
ACOUSTIC           ：声学单元（与SLD同参数空间）
```

**重构动作**：
- 明确根目录版本 vs Shared/ 版本的权威性（建议保留根目录版，将Shared/版废弃或变为转发USE）
- 无其他改造需求

---

### 17.6 SD-06 雅可比与B矩阵子域（Jacobian_BMtx）

**核心文件**：

| 文件 | 位置 | 行数 | 状态 | 说明 |
|------|------|------|------|------|
| `Shared/PH_Elem_Jacobian.f90` | Shared/ | 存在 | ✅ | 雅可比矩阵 J、det(J)、J^{-1} |
| `Shared/PH_Elem_JacobianB_Utils.f90` | Shared/ | 存在 | ✅ | 组合工具：J+B一体化计算 |
| `Shared/PH_Elem_BMtx.f90` | Shared/ | 存在 | ✅ | B矩阵（线性/NL_TL/NL_UL） |
| `PH_NLGeom_Eval.f90` | Element/ | 存在 | ✅ | 几何非线性评估（TL/UL框架） |

**B矩阵类型覆盖**：
```
B_lin   ：小变形线性 B 矩阵（[nstrain, ndof]）
B_NL_TL ：Total Lagrange 增量 B 矩阵
B_NL_UL ：Updated Lagrange 增量 B 矩阵
```

**重构动作**：SD-06 稳定，无需改造；`PH_NLGeom_Eval.f90` 是独立的非线性评估模块，与 B 矩阵协同工作，保持。

---

### 17.7 SD-07 族级物理内核子域（FamilyKernels）

共 15 个族目录，下表统计各族文件数量和功能覆盖完整度：

```
族目录      文件数  Ke  Fe_BF Fe_EP Ce   Me   BC   Cont Out  备注
──────────────────────────────────────────────────────────────────────
SLD2D       13    ★   ★     ★    —    ★    ★    ★    ★    CAX/CPS/CPE×3/4/6/8节点
SLD2DT      13    ★   ★     ★    —    ★    ★    —    ★    热力耦合SLD2D
SLD3D       12    ★   ★     ★    —    ★    ★    ★    ★    C3D4/6/8/10/13/15/20/27
SLD3DT       8    ★   ★     ★    —    ★    ★    —    ★    热力耦合SLD3D
POROUS      20    ★   ★     ★    —    ★    ★    —    ★    2D+3D多孔介质，含P后缀
SHELL       13    ★   ★     ★    —    ★    ★    ★    ★    S3/S4/S6/S8/S9+MITC
BEAM         7    ★   ★     ★    —    ★    ★    —    ★    B21/B23/B31/B32/B33
TRUSS        4    ★   ★     —    —    ★    ★    —    ★    T2D2/T3D2/T3D3
MEMBRANE     1    ★   ★     ★    —    ★    ★    —    ★    M3D系列（单文件）
ACOUSTIC    10    ★   ★     ★    —    ★    ★    —    ★    AC2D/AC3D各阶次
Thermal      2    ★   ★     ★    —    —    ★    —    ★    DC2D/DC3D热传导
SPRING       3    ★   —     —    —    —    ★    —    —    SPRING1/SPRING2
DASHPOT      3    —   —     —    ★    —    ★    —    —    DASHPOT1/DASHPOT2
SPECIAL     12    ±   —     —    —    —    ★    —    —    刚体/黏结/垫片（多为Defn）
INFINITE     1    ★   —     —    —    ★    —    —    ★    无限元（波动吸收边界）
──────────────────────────────────────────────────────────────────────
注：★=已实现  —=不适用  ±=部分实现
```

**各族特化文件清单**（SLD2D/SLD3D 代表性文件）：

```
SLD2D 族（13文件）：
  PH_Elem_CAX3/4/6/8_Core.f90     轴对称三角/四边形（4个）
  PH_Elem_CPS3/4/6/8_Core.f90     平面应力（4个）
  PH_Elem_CPE3/4/6/8_Core.f90     平面应变（4个）
  PH_Elem_Sld2D_Defn.f90          族定义汇总

SLD3D 族（12文件）：
  PH_Elem_C3D4/5/6/8_Core.f90     4/5/6/8节点六面体
  PH_Elem_C3D8_EAS.f90            增强假设应变
  PH_Elem_C3D8_FBar.f90           F-bar体积锁定消除
  PH_Elem_C3D10/13/15/20/27_Core.f90  高阶单元
  PH_Elem_Sld3D_Defn.f90          族定义汇总

SHELL 族（13文件）：
  PH_Elem_S3/S4/S4T/S6/S8/S8RT/S9_Core.f90
  PH_Elem_DS3/DS4/DS6/DS8_Core.f90
  PH_Elem_Shell_MITC.f90          MITC剪切锁定消除
  PH_Elem_Shell_Defn.f90
```

**重构动作**：SD-07 文件组织保持不变（决策D1）；改造方向是让各族 Core 文件的 Loads/BC 调用 SD-08 Shared 内核（阶段2起渐进推进）。

---

### 17.8 SD-08 公共工具内核子域（Shared_Utils）

**现有文件**（`Shared/` 目录，17个）：

| 文件 | 状态 | 职责 |
|------|------|------|
| `PH_Elem_ShapeFunc.f90` | ✅ | 形函数（见SD-05重叠问题） |
| `PH_Elem_Jacobian.f90` | ✅ | 雅可比（见SD-06） |
| `PH_Elem_JacobianB_Utils.f90` | ✅ | J+B组合工具 |
| `PH_Elem_BMtx.f90` | ✅ | B矩阵 |
| `PH_Elem_IntegPts.f90` | ✅ | 三角/四面体积分点表 |
| `PH_Elem_Common_Util.f90` | ✅ | 通用工具（材料坐标系等） |
| `PH_Elem_Utils.f90` | ✅ | 基础工具函数 |
| `PH_Elem_Mtx.f90` | ✅ | 矩阵运算工具 |
| `PH_Elem_Comp.f90` | ✅ | 组合运算 |
| `PH_Elem_Diff_Utils.f90` | ✅ | 微分工具 |
| `PH_Elem_Quality.f90` | ✅ | 单元质量检查 |
| `PH_Elem_Orient_RT_Brg.f90` | ✅ | 方向张量 RT桥接 |
| `PH_Elem_RT_Brg.f90` | ✅ | RT桥接通用 |
| `PH_Elem_Dispatch_C3D8.f90` | ✅ | C3D8专用调度 |
| `PH_Elem_Dispatch_Reg.f90` | ✅ | 调度注册表工具 |
| `PH_Physics_Utils.f90` | ✅ | 物理常数与工具 |
| `BATCH_CREATE_ALL.f90` | ⚠️ | 批量生成脚本（非生产代码，应移到 tools/） |

**待新建文件**（核心重构目标）：

| 文件 | 状态 | 来源决策 | 职责 |
|------|------|----------|------|
| `PH_Elem_Load_Kernel.f90` | ❌ 待新建 | D2/S1 | 体力/面力通用积分内核（geom_kind参数） |
| `PH_Elem_BC_Kernel.f90` | ❌ 待新建 | D2/S2 | Constraint/MPC通用逻辑（ndof参数化） |
| `PH_Elem_Out_Kernel.f90` | ❌ 待新建 | S4 | IP变量收集/外推矩阵通用逻辑 |

**重构动作**：
- **立即（阶段1）**：新建 `PH_Elem_Load_Kernel.f90` 和 `PH_Elem_BC_Kernel.f90`
- **阶段3**：新建 `PH_Elem_Out_Kernel.f90`
- 将 `BATCH_CREATE_ALL.f90` 移至 `UFC/tools/` 目录（不属于生产内核）

---

### 17.9 SD-09 Domain_Core 子域（上帝文件拆分目标）

**现有文件**：

| 文件 | 行数 | 状态 | 说明 |
|------|------|------|------|
| `PH_Element_Domain_Core.f90` | **4424** | ⚠️ 上帝文件 | 全量路由 + 接口定义，60+ USE引用 |
| `PH_Elem_ComplexStiff.f90` | 92 | ✅ 独立 | 结构阻尼 K*=K·(1+2iη) |
| `PH_Mass_Core.f90` | 521 | ✅ 独立 | 质量矩阵（Consistent/Lumped/HRZ） |
| `PH_Elem_Contm.f90` | 存在 | ✅ | 连续体单元调度（待确认是否与Domain_Core重复） |
| `PH_Elem_Contm_Core.f90` | 存在 | ✅ | 连续体核心 |
| `PH_Math_Tensor.f90` | 存在 | ✅ | 张量数学工具 |
| `PH_Physical_Constants.f90` | 存在 | ✅ | 物理常数 |
| `PH_Err_Code.f90` | 存在 | ✅ | 单元域错误码 |
| `PH_ShapeMechanicalField.f90` | 存在 | ✅ | 力学场形函数 |
| `PH_ShapeScalarField.f90` | 存在 | ✅ | 标量场形函数 |

**Domain_Core 拆分目标**（与 §11.2 一致）：

```
拆分后文件              估计行数   内容
PH_Element_Domain_Core  ≤500     精简：L5_RT金线接口 + USE各Dispatch模块
PH_Element_Ke_Dispatch  ~800     Compute_Ke全族路由（从~800-2500行迁移）
PH_Element_Fe_Dispatch  ~600     Compute_Fe（载荷向量）全族路由
PH_Element_Mass_Dispatch ~400    Mass全族路由（含PH_Mass_Core集成）
PH_Element_Out_Dispatch ~400     输出/后处理全族路由
```

**重构动作**：**阶段3**执行 S4 拆分，中等风险，需保持 PUBLIC 接口不变。

---

### 17.10 SD-10 RT调度子域（RT_Dispatcher）

**核心文件**（`L5_RT/Element/`，5个）：

| 文件 | 行数 | 状态 | 说明 |
|------|------|------|------|
| `RT_Elem_Types.f90` | 325 | ✅ 完善 | 四大类 + UEL/VUEL特化类型 + 抽象接口 |
| `RT_Elem_Dispatcher.f90` | 230 | ⚠️ 骨架 | 薄调度层（Wrapper均为错误返回，未对接L4） |
| `RT_Elem_UEL.f90` | 存在 | 存在 | UEL入口（Abaqus/Standard用户单元） |
| `RT_Elem_Sect.f90` | 存在 | 存在 | 截面属性查询 |
| `CONTRACT.md` | 存在 | ✅ | 接口合同文档 |

**RT_Elem_Dispatcher 当前状态**：
- `RT_Elem_Dispatcher_Init/Run/Register/GetCount`：框架已建立
- 实际 Wrapper（`PH_Continuum_Kernel_Wrapper` 等5个）均返回 `STATUS_ERROR` + 未实现消息
- 族ID映射表（5类：Continuum/Shell/Beam/Truss/Special）与 SD-01 的8族ID不完全对齐

**重构动作**：
- **阶段2**（D8）：新建 `RT_Elem_Proc.f90`（SIO六参数骨架）
- **阶段3**：将 Dispatcher Wrapper 对接 `PH_Element_Ke_Dispatch` 等拆分后的 L4 接口
- **阶段4**：对齐族ID枚举（8族 vs 5类，见 §20 接口对账）

---

### 17.11 子域现状一览表（综合评分）

```
子域ID  子域名称       完成度  急迫度  说明
──────────────────────────────────────────────────────────────────────
SD-01  Registry       ★★★★★  低    稳定，仅需族ID对齐
SD-02  Types_L4       ★★★☆☆  高    Desc/Algo 缺失（D6/D7）
SD-03  Types_L5       ★★★★☆  中    结构完整，接口规格需迁移到SIO六参数
SD-04  GaussInt       ★★★★★  低    完善，无需改造
SD-05  ShapeFunc      ★★★★☆  低    文件重叠问题需清理
SD-06  Jacobian_BMtx  ★★★★★  低    稳定
SD-07  FamilyKernels  ★★★★☆  中    物理内核完整；Loads/BC 等待内核化
SD-08  Shared_Utils   ★★★☆☆  高    Load/BC/Out 三个内核文件缺失（阶段1目标）
SD-09  Domain_Core    ★★☆☆☆  高    4424行上帝文件（阶段3拆分）
SD-10  RT_Dispatcher  ★★☆☆☆  中    骨架在，Wrapper 未实现，族ID不对齐
──────────────────────────────────────────────────────────────────────
★=完成度评分（5星满分）
```

---

## 18. 各子域改造行动表

### 18.1 阶段1：零破坏立即可执行（~1-2天）

| 行动ID | 子域 | 具体行动 | 文件 | 风险 |
|--------|------|---------|------|------|
| A1-01 | SD-02 | 在 `PH_Elem_Types.f90` 追加 `PH_Elem_Base_Desc` TYPE（§12.2设计） | 改现有文件 | 低 |
| A1-02 | SD-02 | 在 `PH_Elem_Types.f90` 追加 `PH_Elem_Base_Algo` TYPE（§12.3设计） | 改现有文件 | 低 |
| A1-03 | SD-08 | 新建 `Shared/PH_Elem_Load_Kernel.f90`（体力/面力通用积分） | 新建文件 | 零 |
| A1-04 | SD-08 | 新建 `Shared/PH_Elem_BC_Kernel.f90`（Constraint/MPC通用逻辑） | 新建文件 | 零 |
| A1-05 | SD-05 | 确认并清理 `ShapeFunc` 文件重叠（根目录版 vs Shared/版） | 清理 | 低 |
| A1-06 | SD-08 | 将 `BATCH_CREATE_ALL.f90` 从 Shared/ 移至 `UFC/tools/` | 移动文件 | 低 |

**验证方法**：`gfortran -std=f2003 -fsyntax-only` 检查所有修改文件。

### 18.2 阶段2：SIO骨架建立（~2-3天）

| 行动ID | 子域 | 具体行动 | 文件 | 前提 |
|--------|------|---------|------|------|
| A2-01 | SD-10 | 新建 `RT_Elem_Proc.f90`（SIO五参v2.0骨架，8个操作 *_Args + ABSTRACT INTERFACE） | 新建文件 | A1-01+A1-02 |
| A2-02 | SD-07 | SLD2D 试点：改造 CAX4 + CPS4 的 Loads/BC，委托给 SD-08 内核 | 2个文件 | A1-03+A1-04 |
| A2-03 | SD-02 | 追踪确认 `PH_Elem_UEL_Ctx/State/VUEL_Ctx/State` 实际源文件 | 只读调查 | — |

**验证方法**：对比 CAX4/CPS4 改造前后相同输入的 F_eq 输出向量。

### 18.3 阶段3：Domain_Core 拆分（~3-5天）

| 行动ID | 子域 | 具体行动 | 文件 | 前提 |
|--------|------|---------|------|------|
| A3-01 | SD-09 | 从 `Domain_Core` 拆出 `PH_Element_Ke_Dispatch.f90`（Ke路由） | 重构4424行 | 阶段1完成 |
| A3-02 | SD-09 | 从 `Domain_Core` 拆出 `PH_Element_Fe_Dispatch.f90`（Fe路由） | 重构 | A3-01 |
| A3-03 | SD-09 | 从 `Domain_Core` 拆出 `PH_Element_Mass_Dispatch.f90`（Mass路由） | 重构 | A3-01 |
| A3-04 | SD-09 | 从 `Domain_Core` 拆出 `PH_Element_Out_Dispatch.f90`（Output路由） | 重构 | A3-01 |
| A3-05 | SD-09 | 新建 `Shared/PH_Elem_Out_Kernel.f90`（IP变量收集/外推矩阵通用） | 新建文件 | — |
| A3-06 | SD-10 | 将 Dispatcher Wrapper 对接拆分后的 Dispatch 模块 | RT_Elem_Dispatcher.f90 | A3-01~04 |

**验证方法**：全量编译，L5_RT 调用路径不变（Public 接口不变）。

### 18.4 阶段4：全族推广（持续）

| 行动ID | 子域 | 具体行动 | 文件 | 前提 |
|--------|------|---------|------|------|
| A4-01 | SD-07 | 全族 Loads/BC 委托推广（SLD3D/SHELL/BEAM/TRUSS/POROUS 等~40个文件） | 渐进 | A2-02通过 |
| A4-02 | SD-10 | 对齐族ID枚举（8族 vs 5类，建立映射表） | RT层 | A3-06 |
| A4-03 | SD-10 | 充实 L5_RT/LoadBC，建立与 L4 Load_Kernel 的正式对接 | RT_LoadBC_Proc.f90 | A2-01 |
| A4-04 | SD-03 | 将 `RT_Elem_Compute_Proc` 迁移到 SIO 六参数签名（见 §20） | RT_Elem_Types.f90 | A2-01 |

---

## 19. 子域间依赖关系全景图

```
                         ┌────────────────────────────────────────────────┐
                         │            L3_MD 层（数据模型）                 │
                         │  MD_Elem_Core（PH_ELEM_*常量） MD_Elem_Types    │
                         │  MD_Elem_Base_Desc   MD_Elem_Base_Algo         │
                         └──────────────┬─────────────────────────────────┘
                                        │ USE（单向向上禁止）
                         ┌──────────────▼─────────────────────────────────────────────────────┐
                         │                    L4_PH 层                                         │
                         │                                                                     │
    ┌────────────────┐   │   SD-01 Registry          SD-04 GaussInt                           │
    │  IF_Prec       │   │   PH_Elem_Reg_Core.f90    PH_Elem_GaussInt.f90 ◄──────────┐        │
    │  IF_Err_API    │──►│                │                    ▲                      │        │
    └────────────────┘   │                │            ┌───────┘                      │        │
                         │   SD-02 Types_L4            │         SD-06 Jacobian_BMtx │        │
                         │   PH_Elem_Types.f90 ◄───────┘         Shared/PH_Elem_Jac │        │
                         │   ·PH_Elem_Base_Ctx          USE       Shared/PH_Elem_BMtx│        │
                         │   ·PH_Elem_Base_State ───────────────►SD-05 ShapeFunc     │        │
                         │   ·PH_Elem_Base_Desc(待建)            PH_Elem_ShapeFunc   │        │
                         │   ·PH_Elem_Base_Algo(待建)            Shared/IntegPts     │        │
                         │         │                                     │            │        │
                         │         │ USE                                 │ USE        │        │
                         │         ▼                                     ▼            │        │
                         │   SD-07 FamilyKernels ◄── SD-08 Shared_Utils              │        │
                         │   SLD2D/SLD3D/SHELL         PH_Elem_Load_Kernel(待建)◄───┘        │
                         │   BEAM/TRUSS/POROUS          PH_Elem_BC_Kernel(待建)              │
                         │   ACOUSTIC/Thermal/          PH_Elem_Out_Kernel(待建)             │
                         │   SPRING/DASHPOT/SPECIAL     PH_Mass_Core（现有）                 │
                         │         │                    PH_Elem_ComplexStiff（现有）           │
                         │         │                                                           │
                         │         │ USE                  SD-09 Domain_Core（待拆）           │
                         │         └──────────────────►  PH_Element_Domain_Core.f90          │
                         │                               ·Ke_Dispatch（拆出目标）              │
                         │                               ·Fe_Dispatch（拆出目标）              │
                         │                               ·Mass_Dispatch（拆出目标）            │
                         │                               ·Out_Dispatch（拆出目标）             │
                         └───────────────────────────────────┬───────────────────────────────┘
                                                             │ USE（L4→L5 单向）
                         ┌───────────────────────────────────▼───────────────────────────────┐
                         │                    L5_RT 层                                        │
                         │                                                                    │
                         │   SD-03 Types_L5                SD-10 RT_Dispatcher               │
                         │   RT_Elem_Types.f90             RT_Elem_Dispatcher.f90             │
                         │   ·RT_Elem_Desc                 ·Init/Run/Register/GetCount        │
                         │   ·RT_Elem_Ctx      ◄── USE ──  ·Wrapper（待对接L4）               │
                         │   ·RT_Elem_State                RT_Elem_UEL.f90（UEL入口）         │
                         │   ·RT_Elem_Algo                 RT_Elem_Sect.f90（截面查询）       │
                         │   ·RT_Elem_UEL_Ctx              RT_Elem_Proc.f90（待建SIO骨架）    │
                         │   ·RT_Elem_VUEL_Ctx                                                │
                         │         ▲                                                          │
                         │         │ USE                                                      │
                         │   来自 L4_PH:                                                      │
                         │   PH_Elem_Base_Ctx/State    MD_Elem_Base_Desc/Algo（来自L3）       │
                         └───────────────────────────────────────────────────────────────────┘

图例：
  ──► = USE 依赖（单向向上禁止，只能 L5 USE L4 USE L3）
  ◄── = 提供（被对方 USE）
  (待建) = 规划中尚未创建
  (待拆) = 需要从现有上帝文件拆出
```

**关键依赖路径（热路径）**：
```
L5_RT/Dispatcher → SD-09/Domain_Core → SD-07/FamilyKernels
                                      → SD-08/Shared_Utils
                                      → SD-06/Jacobian_BMtx
                                      → SD-05/ShapeFunc
                                      → SD-04/GaussInt
                                      → SD-02/Types_L4
```

---

## 20. L4↔L5 接口差异对账与迁移路径

### 20.1 两套接口的现状

**现有接口（RT_Elem_Types.f90 L54-62，四参数）**：
```fortran
SUBROUTINE RT_Elem_Compute_Proc(desc, ctx, state, algo, status)
  TYPE(RT_Elem_Desc),    INTENT(IN)    :: desc
  TYPE(RT_Elem_Ctx),     INTENT(IN)    :: ctx
  TYPE(RT_Elem_State),   INTENT(INOUT) :: state
  TYPE(RT_Elem_Algo),    INTENT(IN)    :: algo
  TYPE(ErrorStatusType), INTENT(OUT)   :: status
END SUBROUTINE
```

**SIO 五参规范 v2.0（UFC Principle #14 - 强制）**：
```fortran
! ✅ 新规范（强制）：统一 *_Args 结构 + [IN]/[OUT] 注释
TYPE :: XXX_Op_Args
  ! [IN] 输入字段（只读）
  ! [OUT] 输出字段（返回结果）
END TYPE XXX_Op_Args

SUBROUTINE Proc(desc, state, algo, ctx, args)
  ! [IN]  desc  : 类型描述
  ! [IN]  state : 状态变量
  ! [IN]  algo  : 算法参数
  ! [IN]  ctx   : 运行时上下文
  ! [IN/OUT] args : 统一参数结构（[IN]输入 + [OUT]输出）
END SUBROUTINE
```

### 20.2 差异对账表

| 维度 | 旧规范（inp/out） | 新规范（*_Args） | 差距 |
|------|------------------|-----------------|------|
| 参数数量 | 6（inp + out） | 5（统一 args） | -1 参数 |
| status 位置 | 内嵌于 `out%status` | 内嵌于 `args%status` | 无变化 |
| 操作特定IO | ~~每操作独立 _In/_Out TYPE~~ | 每操作独立 *_Args TYPE | 命名统一 |
| desc 的 INTENT | IN（只读） | INOUT（可更新） | 语义扩展 |
| 参数顺序 | desc/ctx/state/algo/inp/out | desc/state/algo/ctx/args | 重排 |
| 合规检查入口 | 无 SIO-XX 标注 | SIO-01~14 全套检查 | 需补充 |

### 20.3 迁移路径（三步法）

**步骤1（阶段2，D8）**：新建 `RT_Elem_Proc.f90` 作为 SIO 六参数的**新入口**
- 内部调用现有 `RT_Elem_Compute_Proc` 风格的接口
- 实现 SIO-01（文件存在）+ SIO-02（*_Args 统一结构）+ SIO-03（status在args）
- **不破坏**现有 `RT_Elem_Dispatcher`

**步骤2（阶段3）**：将 `RT_Elem_Dispatcher_Run` 升级为内部调用 `RT_Elem_Proc`
- Dispatcher 接受六参数调用，内部把 inp/out 适配成调度逻辑
- 保留 `RT_Elem_Compute_Proc` 接口供 `RT_Elem_Router_Entry` 的函数指针使用

**步骤3（阶段4）**：将 `RT_Elem_Router_Entry%compute` 指针类型从 `RT_Elem_Compute_Proc` 迁移到 SIO 六参数签名
- 此步骤影响所有注册了 `compute` 指针的调用方
- 可与族ID对齐（8族 vs 5类）一起进行

### 20.4 族ID对齐方案

**当前状态**：
- `PH_Elem_Reg_Core`（SD-01）：8族（C3D/CPE/CPS/CAX/S/B/T/OTHER）
- `RT_Elem_Dispatcher`（SD-10）：SELECT CASE 5类（Continuum/Shell/Beam/Truss/Special）

**建议对齐方案**：在 `RT_Elem_Dispatcher` 中建立映射表：
```
L4 族ID（8类）       → L5 调度类别（5类）
PH_ELEM_FAMILY_C3D  → Continuum
PH_ELEM_FAMILY_CPE  → Continuum
PH_ELEM_FAMILY_CPS  → Continuum
PH_ELEM_FAMILY_CAX  → Continuum
PH_ELEM_FAMILY_S    → Shell
PH_ELEM_FAMILY_B    → Beam
PH_ELEM_FAMILY_T    → Truss
PH_ELEM_FAMILY_OTHER → Special（包含声学/热/弹簧/DASHPOT/刚体等）
```

可在 RT 层新建一个纯函数 `PH_Reg_Family_To_RT_Class(family_id) → rt_class` 执行此映射，无需修改 L4 注册表的族ID体系。

### 20.5 决策 D9（新增）

**决策 D9：RT_Elem_Compute_Proc 迁移采用三步渐进法，维持向后兼容**
- **原因**：`RT_Elem_Router_Entry%compute` 函数指针在运行时动态绑定，一次性重构签名会破坏所有已注册的 L4 内核入口点；三步法中步骤1/2不影响已有代码，步骤3可作为独立阶段受控执行
- **风险控制**：步骤1新建文件（零破坏）；步骤2升级调度层（中风险，需全量测试）；步骤3修改函数指针类型（高风险，分族逐步迁移）

---

*文档最后更新**：补充 §17-§20，按子域展开 Element 域全景细节，包含子域清单/现状评估/改造行动表/依赖全景图/L4↔L5接口对账。

---

## 21. Element 域完整任务规划体系

> **阅读指引**
> - **总任务（MT）**：端到端目标，代表 Element 域达到生产就绪状态
> - **次级任务（ST）**：按子域/阶段拆分，可独立交付、可单独验收
> - **支线任务（BT）**：不阻塞主线、可并行推进的质量增强工作
> - **支点计划（PP）**：关键里程碑节点，每个支点对应一次可合入的完整状态

---

### 21.1 总任务（MT）

```
MT-ELEM
  目标：将 L4_PH/Element 域 + L5_RT/Element 调度层重构为
        符合 UFC 六层架构规范、SIO 六参数规范、四大类 TYPE 规范的
        可维护、可扩展、可测试的生产就绪状态

  完成判定：
    ✅ 四大类 TYPE 齐全（Desc/State/Algo/Ctx）且已合并进 PH_Elem_Types.f90
    ✅ Domain_Core 拆分为 ≤500 行核心 + 4 个 Dispatch 文件
    ✅ Shared/ 下三个内核文件（Load/BC/Out）已建立
    ✅ RT_Elem_Proc.f90 骨架已建立，SIO-01~13 合规
    ✅ RT_Elem_Dispatcher 所有 Wrapper 已对接 L4 Dispatch 接口
    ✅ 族ID对齐（SD-01 8族 ↔ SD-10 路由类别）
    ✅ 全量 gfortran -std=f2003 语法零错误
    ✅ SLD2D 族试点验证：改造前后输出向量数值一致
```

---

### 21.2 次级任务（ST）

次级任务按**四个阶段**组织，每个阶段可独立交付。

---

#### ST-1 阶段1：类型补全 + Shared 内核建立（零破坏）

| 任务ID | 任务名称 | 输入依赖 | 交付物 | 验收标准 |
|--------|---------|---------|--------|----------|
| **ST-1.1** | 补充 `PH_Elem_Base_Desc` TYPE | 无 | `PH_Elem_Types.f90`（追加） | 含 elem_type_id/family_id/n_nodes/n_dof/n_ip/ndim/dof_per_node/geom_kind/geom_param/has_mass/has_damp/nlgeom 等字段；语法零错误 |
| **ST-1.2** | 补充 `PH_Elem_Base_Algo` TYPE | 无 | `PH_Elem_Types.f90`（追加） | 含 ip_scheme/ip_override/hourglass_coeff/hourglass_type/use_eas/use_fbar/struct_damp_eta/rayleigh_alpha/rayleigh_beta 等字段；语法零错误 |
| **ST-1.3** | 新建 `PH_Elem_Load_Kernel.f90` | ST-1.1 | `Shared/PH_Elem_Load_Kernel.f90` | 包含 `Sld2D_FormBodyForce_Generic`（geom_kind 参数注入）+ `Sld2D_FormEdgePressure_Generic`；语法零错误 |
| **ST-1.4** | 新建 `PH_Elem_BC_Kernel.f90` | ST-1.1 | `Shared/PH_Elem_BC_Kernel.f90` | 包含 `Sld_ApplyConstraint_Generic`（ndof 参数化）+ `Sld_ApplyMPC_Generic`；语法零错误 |
| **ST-1.5** | 清理 `ShapeFunc` 文件重叠 | 无 | 确认根目录版为权威版，`Shared/` 版改为 USE 转发或删除 | 无重复模块名；全量编译不报重定义 |
| **ST-1.6** | 迁移 `BATCH_CREATE_ALL.f90` | 无 | 文件移至 `UFC/tools/`，Shared/ 下删除 | Shared/ 目录无非生产代码 |

**阶段1 验收门控**：执行 `gfortran -std=f2003 -fsyntax-only` 检查 ST-1.1~1.4 四个文件零错误。

---

#### ST-2 阶段2：SIO 骨架建立 + SLD2D 试点改造

| 任务ID | 任务名称 | 输入依赖 | 交付物 | 验收标准 |
|--------|---------|---------|--------|----------|
| **ST-2.1** | 新建 `RT_Elem_Proc.f90`（SIO 五参v2.0骨架） | ST-1.1 + ST-1.2 | `L5_RT/Element/RT_Elem_Proc.f90` | 8 操作（Init/PopulateDesc/ComputeKe/ComputeMe/ComputeFe/ComputeCe/CollectOutput/Finalize）均使用 *_Args 统一结构；ABSTRACT INTERFACE 五参签名；SIO-01~14 检查通过 |
| **ST-2.2** | SLD2D 试点：CAX4 委托 Load_Kernel | ST-1.3 | `SLD2D/PH_Elem_CAX4_Core.f90`（修改） | CAX4 的 FormBodyForce/FormEdgePressure 调用 Load_Kernel 内核；相同输入下 F_eq 数值一致（≤1e-12 误差） |
| **ST-2.3** | SLD2D 试点：CPS4 委托 Load_Kernel | ST-1.3 | `SLD2D/PH_Elem_CPS4_Core.f90`（修改） | 同 ST-2.2 验收标准 |
| **ST-2.4** | SLD2D 试点：CAX4/CPS4 委托 BC_Kernel | ST-1.4 | 2 个 Core 文件（修改） | ApplyConstraint/ApplyMPC 委托；相同输入下 K_el/F_el 数值一致 |
| **ST-2.5** | 追踪确认 UEL/VUEL 类型来源文件 | 无 | 文档标注（更新 §17.2） | 明确 `PH_Elem_UEL_Ctx/State/VUEL_Ctx/State` 定义所在文件路径 |

**阶段2 验收门控**：SLD2D 族 CAX4+CPS4 共4个文件改造，对比测试数值一致，RT_Elem_Proc.f90 SIO-01 通过。

---

#### ST-3 阶段3：Domain_Core 拆分（中等风险）

| 任务ID | 任务名称 | 输入依赖 | 交付物 | 验收标准 |
|--------|---------|---------|--------|----------|
| **ST-3.1** | 拆出 `PH_Element_Ke_Dispatch.f90` | 阶段1完成 | 新建文件，含全族 Ke 路由 SELECT CASE | Domain_Core 中 Ke 路由行数迁移完毕；对外 `Compute_Ke` PUBLIC 接口不变；全量编译通过 |
| **ST-3.2** | 拆出 `PH_Element_Fe_Dispatch.f90` | ST-3.1 | 新建文件，含全族 Fe 路由 | 同 ST-3.1 标准，`Compute_Fe` 接口不变 |
| **ST-3.3** | 拆出 `PH_Element_Mass_Dispatch.f90` | ST-3.1 | 新建文件，含 Mass + DASHPOT Ce 路由，集成 PH_Mass_Core | `Compute_Me`/`Compute_Ce` 接口不变 |
| **ST-3.4** | 拆出 `PH_Element_Out_Dispatch.f90` | ST-3.1 | 新建文件，含全族 Output 路由 | `Collect_Output` 接口不变 |
| **ST-3.5** | 精简 `PH_Element_Domain_Core.f90` | ST-3.1~3.4 | Domain_Core 精简至 ≤500 行 | 仅保留：L5_RT 金线接口声明 + USE 各 Dispatch 模块；无族级路由逻辑残留 |
| **ST-3.6** | 新建 `Shared/PH_Elem_Out_Kernel.f90` | 无 | IP变量收集/外推矩阵通用逻辑 | 语法零错误；CollectIPVars 通用接口可供 Out_Dispatch 调用 |
| **ST-3.7** | 对接 RT Dispatcher Wrapper | ST-3.1~3.5 | `RT_Elem_Dispatcher.f90`（修改） | 5 个 Wrapper 不再返回 STATUS_ERROR；转而调用对应 Dispatch 模块 |

**阶段3 验收门控**：全量编译通过；L5_RT 所有调用路径行为不变（PUBLIC 接口零修改）；Domain_Core 行数 ≤500。

---

#### ST-4 阶段4：全族推广 + 接口对齐（持续）

| 任务ID | 任务名称 | 输入依赖 | 交付物 | 验收标准 |
|--------|---------|---------|--------|----------|
| **ST-4.1** | SLD3D 族 Load/BC 委托推广 | 阶段2完成 | ~11 个 C3D Core 文件改造 | 同 ST-2.2 数值一致标准 |
| **ST-4.2** | SHELL 族 Load/BC 委托推广 | 阶段2完成 | ~9 个 Shell Core 文件改造 | 同上 |
| **ST-4.3** | BEAM/TRUSS/MEMBRANE 推广 | 阶段2完成 | ~12 个 Core 文件改造 | 同上 |
| **ST-4.4** | POROUS/ACOUSTIC/Thermal 推广 | 阶段2完成 | ~32 个 Core 文件改造 | 同上 |
| **ST-4.5** | 族ID 对齐（8族↔5路由类 映射表） | ST-3.7 | `RT_Elem_Dispatcher.f90`（修改），新增 `PH_Reg_Family_To_RT_Class` 函数 | SELECT CASE 与 PH_ELEM_FAMILY_* 8个常量完全对齐 |
| **ST-4.6** | RT_Elem_Compute_Proc 迁移步骤1（建立 RT_Elem_Proc.f90 入口） | ST-2.1 + ST-3.7 | RT_Elem_Proc.f90 实现 Init/ComputeKe 两个操作 | 两个操作调用链可跑通（E2E 不崩溃） |
| **ST-4.7** | 充实 L5_RT/LoadBC，建立 L4 Load_Kernel 正式对接 | ST-1.3 + ST-2.1 | `RT_LoadBC_Proc.f90`（修改/新建） | LoadBC 层调用 Load_Kernel 内核；不再为空壳 |

**阶段4 验收门控**：所有族 Core 文件 Loads/BC 均已委托内核；族ID 映射完整；RT_Elem_Proc.f90 有2个可运行操作。

---

### 21.3 支线任务（BT）

支线任务**不阻塞主线**，可与主线任务并行进行，目标是提升质量、可测试性和可观测性。

---

#### BT-A 类型体系质量增强

| 任务ID | 任务名称 | 关联主线 | 说明 |
|--------|---------|---------|------|
| **BT-A1** | 为 `PH_Elem_Base_Desc` 补充初始化子程序 `PH_Elem_Desc_Init` | ST-1.1 | 从注册表 `PH_Elem_Reg_Entry` 填充 Desc 字段，建立 Registry→Desc 的正式通道 |
| **BT-A2** | 为 `PH_Elem_Base_Algo` 补充默认值初始化 `PH_Elem_Algo_Default` | ST-1.2 | 按族ID设置合理默认值（ip_scheme 全积分/缩减积分等）;
| **BT-A3** | `PH_Elem_Domain_Container` TYPE 实现（双轨存储容器） | ST-3.5 | 实现 §13.2 设计；扁平域初始化/填充/释放子程序 |
| **BT-A4** | 确认并文档化 UEL/VUEL 类型的实际源文件 | ST-2.5 | 更新 §17.2 及 CONTRACT.md |

---

#### BT-B 验证与测试

| 任务ID | 任务名称 | 关联主线 | 说明 |
|--------|---------|---------|------|
| **BT-B1** | CAX4 Patch Test（体力/面力验证） | ST-2.2 | 均匀应力状态下等效节点力精确性（解析解对比） |
| **BT-B2** | CPS4/CPE4 Patch Test | ST-2.3 | 平面应力/应变单元载荷向量精度验证 |
| **BT-B3** | C3D8 Ke 矩阵特征值检验 | ST-4.1 | Ke 正半定性（6个零特征值对应刚体模态）;
| **BT-B4** | Domain_Core 拆分前后输出一致性测试 | ST-3.5 | 相同输入，拆分前后 Compute_Ke/Fe 输出数值一致（≤1e-12） |
| **BT-B5** | SIO RT_Elem_Proc.f90 接口合规检查 | ST-2.1 | 执行 `ufc-structured-io` 技能 SIO-01~14 完整检查清单 |

---

#### BT-C 文档与合同

| 任务ID | 任务名称 | 关联主线 | 说明 |
|--------|---------|---------|------|
| **BT-C1** | 更新 `L4_PH/Element/CONTRACT.md` | ST-1.1~1.2 | 补充 Desc/Algo TYPE 字段说明；更新四大类完整状态 |
| **BT-C2** | 更新 `L5_RT/Element/CONTRACT.md` | ST-2.1 | 补充 RT_Elem_Proc.f90 的 SIO 接口合同 |
| **BT-C3** | 规划文档最终更新（本文档） | 阶段4完成 | 将文档状态从"进行中"改为"已完成"，补充实际实施结果 |
| **BT-C4** | 创建 Element 域测试用例索引 | BT-B1~B5 | 列出已有/规划测试，关联测试文件路径与验收标准 |

---

#### BT-D 工具与脚本

| 任务ID | 任务名称 | 关联主线 | 说明 |
|--------|---------|---------|------|
| **BT-D1** | 迁移 `BATCH_CREATE_ALL.f90` 至 `UFC/tools/` | ST-1.6 | 同时更新 tools/ 下的 README |
| **BT-D2** | 编写 `Shared/` 目录扫描脚本 | ST-1.5 | 检测根目录与 Shared/ 之间模块名重叠，防止回归 |
| **BT-D3** | 构建单元 Ke/Me 尺寸校验脚本 | BT-B3 | 根据 Reg 表中 n_nodes/n_dof 自动校验矩阵维度 |

---

### 21.4 支点计划（PP）

每个支点是一个**可合入主干的完整状态**，支点之间可独立回滚。

```
PP-0  【起点】当前状态
      - Domain_Core 4424行上帝文件
      - PH_Elem_Types.f90 仅有 Ctx + State
      - RT_Elem_Dispatcher Wrapper 全为 STATUS_ERROR
      - RT_Elem_Proc.f90 不存在
      - Shared/ 无 Load/BC/Out 三个内核文件

        ─────── 执行 ST-1.1 ~ ST-1.6 ───────

PP-1  【阶段1完成】类型补全 + Shared 内核就绪
      交付物清单：
        ✅ PH_Elem_Types.f90 含四大类（Desc/State/Algo/Ctx）
        ✅ Shared/PH_Elem_Load_Kernel.f90（新建）
        ✅ Shared/PH_Elem_BC_Kernel.f90（新建）
        ✅ ShapeFunc 重叠清理
        ✅ BATCH_CREATE_ALL.f90 迁移
      质量门控：gfortran 语法零错误（4个文件）
      可并行：BT-A1、BT-A2、BT-C1

        ─────── 执行 ST-2.1 ~ ST-2.5 ───────

PP-2  【阶段2完成】SIO骨架 + 试点验证
      交付物清单：
        ✅ L5_RT/Element/RT_Elem_Proc.f90（新建，SIO-01通过）
        ✅ SLD2D CAX4 + CPS4 委托 Load/BC 内核（4个文件）
        ✅ UEL/VUEL 类型来源已文档化
      质量门控：试点数值一致性（≤1e-12），SIO-01~13 通过
      可并行：BT-B1、BT-B2、BT-B5

        ─────── 执行 ST-3.1 ~ ST-3.7 ───────

PP-3  【阶段3完成】Domain_Core 拆分 + RT调度对接
      交付物清单：
        ✅ PH_Element_Domain_Core.f90 ≤500行
        ✅ PH_Element_Ke/Fe/Mass/Out_Dispatch.f90（4个新建）
        ✅ Shared/PH_Elem_Out_Kernel.f90（新建）
        ✅ RT_Elem_Dispatcher 所有 Wrapper 对接 L4 Dispatch 接口
      质量门控：全量编译通过，Domain_Core 拆分前后 E2E 一致性
      可并行：BT-A3、BT-B4、BT-C2

        ─────── 执行 ST-4.1 ~ ST-4.7 ───────

PP-4  【阶段4完成 = MT-ELEM 达成】全族推广 + 接口完整
      交付物清单：
        ✅ 全族（~55个Core文件）Loads/BC 已委托内核
        ✅ 族ID映射完整（8族↔路由类，PH_Reg_Family_To_RT_Class）
        ✅ RT_Elem_Proc.f90 Init + ComputeKe 两操作可运行
        ✅ L5_RT/LoadBC 充实，不再为空壳
      质量门控：MT-ELEM 完成判定全部 ✅
      可并行：BT-B3、BT-C3、BT-C4、BT-D2、BT-D3
```

---

### 21.5 工作量估算与优先级矩阵

```
任务类    任务数  估算工作量    优先级  阻塞风险
────────────────────────────────────────────────────────────────
ST-1      6项    0.5天         P0      阻塞 ST-2~4
ST-2      5项    0.5天         P1      阻塞 ST-4
ST-3      7项    2~3天         P1      阻塞 ST-4 中的推广
ST-4      7项    4~6天         P2      渐进推广，可批量
BT-A      4项    1~2天         P2      不阻塞
BT-B      5项    2~3天         P2      不阻塞，提升信心
BT-C      4项    0.5天         P3      不阻塞
BT-D      3项    0.5天         P3      不阻塞
────────────────────────────────────────────────────────────────
合计      41项   ~10~16天（含验证）
```

**执行顺序约束**：
```
ST-1（全部）→ ST-2（全部）→ ST-3（全部）→ ST-4（可拆分批次）
                                               ↗
                              BT-* 均可随时并行穿插
```

---

### 21.6 每个次级任务的单文件变更清单

> 此表是执行时的文件级操作指引，防止遗漏与误改。

```
任务ID   操作    文件路径（相对 ufc_core/）
─────────────────────────────────────────────────────────────────────────────
ST-1.1  改       L4_PH/Element/PH_Elem_Types.f90
ST-1.2  改       L4_PH/Element/PH_Elem_Types.f90
ST-1.3  新建     L4_PH/Element/Shared/PH_Elem_Load_Kernel.f90
ST-1.4  新建     L4_PH/Element/Shared/PH_Elem_BC_Kernel.f90
ST-1.5  删/改    L4_PH/Element/Shared/PH_Elem_ShapeFunc.f90（改为USE转发）
ST-1.6  移动     L4_PH/Element/Shared/BATCH_CREATE_ALL.f90 → tools/

ST-2.1  新建     L5_RT/Element/RT_Elem_Proc.f90
ST-2.2  改       L4_PH/Element/SLD2D/PH_Elem_CAX4_Core.f90
ST-2.3  改       L4_PH/Element/SLD2D/PH_Elem_CPS4_Core.f90
ST-2.4  改       L4_PH/Element/SLD2D/PH_Elem_CAX4_Core.f90（BC部分）
                 L4_PH/Element/SLD2D/PH_Elem_CPS4_Core.f90（BC部分）
ST-2.5  只读     确认 PH_Elem_UEL_Ctx 定义位置，更新文档

ST-3.1  新建     L4_PH/Element/PH_Element_Ke_Dispatch.f90
                 改 L4_PH/Element/PH_Element_Domain_Core.f90（迁移Ke路由）
ST-3.2  新建     L4_PH/Element/PH_Element_Fe_Dispatch.f90
                 改 PH_Element_Domain_Core.f90
ST-3.3  新建     L4_PH/Element/PH_Element_Mass_Dispatch.f90
                 改 PH_Element_Domain_Core.f90
ST-3.4  新建     L4_PH/Element/PH_Element_Out_Dispatch.f90
                 改 PH_Element_Domain_Core.f90
ST-3.5  改       L4_PH/Element/PH_Element_Domain_Core.f90（精简至≤500行）
ST-3.6  新建     L4_PH/Element/Shared/PH_Elem_Out_Kernel.f90
ST-3.7  改       L5_RT/Element/RT_Elem_Dispatcher.f90

ST-4.1  改(11)  L4_PH/Element/SLD3D/PH_Elem_C3D*.f90（各自BC/Loads部分）
ST-4.2  改(9)   L4_PH/Element/SHELL/PH_Elem_S*.f90
ST-4.3  改(12)  L4_PH/Element/BEAM+TRUSS+MEMBRANE 相关 Core 文件
ST-4.4  改(32)  L4_PH/Element/POROUS+ACOUSTIC+Thermal 相关 Core 文件
ST-4.5  改       L5_RT/Element/RT_Elem_Dispatcher.f90（新增映射函数）
                 L5_RT/Element/RT_Elem_Types.f90（若需调整 router_entry）
ST-4.6  改       L5_RT/Element/RT_Elem_Proc.f90（实现 Init+ComputeKe）
ST-4.7  改       L5_RT/LoadBC/RT_LoadBC_Proc.f90（充实 L4 对接逻辑）
─────────────────────────────────────────────────────────────────────────────
新建文件合计：8个
修改文件合计：~70个（其中~55个为族Core文件批量改造）
```

---

### 21.7 风险登记册

| 风险ID | 风险描述 | 概率 | 影响 | 缓解措施 |
|--------|---------|------|------|----------|
| R-01 | Domain_Core 拆分后 L5_RT 调用路径断裂 | 中 | 高 | ST-3 每个子任务拆分后立即全量编译；PUBLIC 接口不变原则 |
| R-02 | 族Core文件改造引入数值误差 | 低 | 高 | ST-2 试点的数值一致性验证（≤1e-12）作为模式确立后推广 |
| R-03 | ShapeFunc 文件重叠导致模块重定义 | 低 | 中 | ST-1.5 优先执行；增加 BT-D2 回归扫描脚本 |
| R-04 | UEL/VUEL 类型来源不明导致 ST-2.1 阻塞 | 中 | 中 | ST-2.5（只读调查）与 ST-2.1 并行，RT_Elem_Proc 骨架先用 IMPORT 占位 |
| R-05 | POROUS/SLD2DT/SLD3DT 热力耦合族的 Load_Kernel 扩展 | 中 | 低 | 在 ST-4.4 中扩展 Load_Kernel，对 geom_kind 增加热耦合标志位；主线不阻塞 |
| R-06 | RT_Elem_Compute_Proc 四参数→六参数迁移破坏已注册内核 | 高 | 高 | 遵循 §20.3 三步渐进法；步骤3（修改指针类型）列为 ST-4 最后一步且单独验收 |

---

## 22. 执行级操作手册（完整设计方案 v2.0）

> **本节目的**：在 §21 任务体系的基础上，提供**文件级精确操作指引**：
> 1. 全族文件精确清单（含 PIPE/INFINITE/MEMBRANE/SPECIAL 六族补充）
> 2. ST-1 ~ ST-4 各子任务的**逐步执行说明**（可直接照章执行）
> 3. 修正后的工作量统计表

---

### 22.1 全族文件精确清单（2026-03-30 最新目录状态）

```
族目录      Core文件数  Defn文件  合计  归属ST-4
────────────────────────────────────────────────────────────────────────────
SLD2D       12          1(Sld2D_Defn)    13   试点（ST-2）
SLD2DT      12          1(Sld2DT_Defn)   13   ST-4.1（热力耦合）
SLD3D       11+2EAS      1(Sld3D_Defn)   14   ST-4.1
SLD3DT       7          1(Sld3DT_Defn)    8   ST-4.1（热力耦合）
POROUS      19          1(Porous_Core)   20   ST-4.4
SHELL       11+1MITC    1(Shell_Defn)    13   ST-4.2
BEAM         6          1(Beam_Defn)      7   ST-4.3
TRUSS        3          1(Truss_Defn)     4   ST-4.3
MEMBRANE     1(Core)    0                 1   ST-4.3
ACOUSTIC     9          1(Acoustic_Defn) 10   ST-4.4
Thermal      1(HeatTransfer) 1(Therm_Defn) 2  ST-4.4
SPRING       2          1(Spring_Defn)    3   ST-4.3（轻量）
DASHPOT      2          1(Dash_Defn)      3   ST-4.3（轻量）
PIPE         1(Pipe_Core) 0                1   ST-4.3
INFINITE     1(Infinite_Core) 0            1   ST-4.4（特殊）
SPECIAL     11+1Mass    0                12   ST-4.3（刚/黏/垫片）
────────────────────────────────────────────────────────────────────────────
合计（族Core）  ~109个 Core/Defn 文件（含 Shared/17 = 总约126个）
试点（ST-2）    4个（CAX4/CPS4 Loads + BC，共2组）
ST-4 目标总量  ~85个 Core 文件的 Loads/BC 部分委托改造
```

**重要修正（对比 §21.5）**：
- §21.5 估算 ST-4 改造 ~55个Core文件；经完整目录核算应为 **~85个**
- 新增族：PIPE(1)+INFINITE(1)+MEMBRANE(1)+SPECIAL(12)= +15个文件进入 ST-4 范围
- SPECIAL 族的 Loads/BC 与刚体/黏结/垫片行为差异大，建议**ST-4.3内单独处理**

---

### 22.2 ST-1 逐步执行指令（零破坏，立即可执行）

#### 22.2.1 ST-1.1：在 PH_Elem_Types.f90 追加 PH_Elem_Base_Desc

**文件**：`ufc_core/L4_PH/Element/PH_Elem_Types.f90`

**操作**：在 `END MODULE PH_Elem_Types` 之前插入以下 TYPE 定义：

```fortran
  !---------------------------------------------------------------------------
  ! DESC - Element Type Descriptor（冷路径静态元数据, v5.0 ST-1.1）
  ! 由注册表初始化，整个计算过程只读
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Base_Desc
    !-- 标识
    INTEGER(i4) :: elem_type_id    = 0    ! MD层单元类型ID（如 PH_ELEM_C3D8=10）
    INTEGER(i4) :: family_id       = 0    ! 族ID（PH_ELEM_FAMILY_C3D/CPE/CPS等）
    !-- 拓扑
    INTEGER(i4) :: n_nodes         = 0    ! 节点数
    INTEGER(i4) :: n_dof           = 0    ! 单元总自由度 = n_nodes * dof_per_node
    INTEGER(i4) :: dof_per_node    = 0    ! 每节点自由度（纯力学=3D:3,2D:2）
    INTEGER(i4) :: ndim            = 0    ! 空间维度（2 或 3）
    INTEGER(i4) :: n_ip            = 0    ! 积分点数（默认全积分）
    !-- 几何类型
    INTEGER(i4) :: geom_kind       = 0    ! 几何类型：0=各向同性 1=轴对称 2=平面应力 3=平面应变
    REAL(wp)    :: geom_param      = 0.0_wp  ! 几何参数（如轴对称厚度）
    !-- 物理能力标志
    LOGICAL :: has_mass            = .FALSE. ! 支持质量矩阵
    LOGICAL :: has_damp            = .FALSE. ! 支持阻尼矩阵
    LOGICAL :: has_thermal         = .FALSE. ! 热-力耦合单元
    LOGICAL :: has_porous          = .FALSE. ! 多孔介质单元
    LOGICAL :: nlgeom              = .FALSE. ! 几何非线性
  END TYPE PH_Elem_Base_Desc
```

#### 22.2.2 ST-1.2：在 PH_Elem_Types.f90 追加 PH_Elem_Base_Algo

**操作**：紧跟 PH_Elem_Base_Desc TYPE 之后插入：

```fortran
  !---------------------------------------------------------------------------
  ! ALGO - Element Algorithm Parameters（Step级只读算法配置, v5.0 ST-1.2）
  ! 由 Step 级控制器填写，不随积分点变化
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Base_Algo
    !-- 积分方案
    INTEGER(i4) :: ip_scheme       = 0    ! 0=全积分 1=缩减积分 2=用户指定
    INTEGER(i4) :: ip_override     = 0    ! 用户指定积分点数（0=使用默认）
    !-- 沙漏控制
    REAL(wp)    :: hourglass_coeff = 0.05_wp  ! 沙漏控制系数（缩减积分时生效）
    INTEGER(i4) :: hourglass_type  = 0    ! 0=无 1=刚度型 2=粘性型
    !-- 增强假设应变/F-Bar
    LOGICAL :: use_eas             = .FALSE. ! 增强假设应变（EAS方法）
    LOGICAL :: use_fbar            = .FALSE. ! F-Bar体积锁死消除
    !-- 阻尼参数
    REAL(wp)    :: struct_damp_eta = 0.0_wp  ! 结构阻尼系数 η
    REAL(wp)    :: rayleigh_alpha  = 0.0_wp  ! Rayleigh 质量阻尼系数 α
    REAL(wp)    :: rayleigh_beta   = 0.0_wp  ! Rayleigh 刚度阻尼系数 β
    !-- 质量配置
    INTEGER(i4) :: mass_type       = 0    ! 0=一致质量矩阵 1=集中质量矩阵
  END TYPE PH_Elem_Base_Algo
```

**验收**：`gfortran -std=f2003 -fsyntax-only PH_Elem_Types.f90` 零错误。

---

#### 22.2.3 ST-1.3：新建 Shared/PH_Elem_Load_Kernel.f90

**文件**：`ufc_core/L4_PH/Element/Shared/PH_Elem_Load_Kernel.f90`（新建）

**模块骨架**（含4个通用积分子程序占位）：

```fortran
!==============================================================================
! Module: PH_Elem_Load_Kernel
! Layer:  L4_PH / Element / Shared
! Purpose: 跨族通用载荷积分内核（体力/面力/边力）
!          被各族 Core 文件的 FormBodyForce / FormEdgePressure 委托调用
! Params injected: geom_kind（几何类型）, ndim, n_nodes
!==============================================================================
MODULE PH_Elem_Load_Kernel
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, STATUS_OK
  USE PH_Elem_Types, ONLY: PH_Elem_Base_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Sld2D_FormBodyForce_Generic
  PUBLIC :: Sld2D_FormEdgePressure_Generic
  PUBLIC :: Sld3D_FormBodyForce_Generic
  PUBLIC :: Sld3D_FormSurfPressure_Generic

CONTAINS

  SUBROUTINE Sld2D_FormBodyForce_Generic(desc, coords, bforce, Fe, status)
    TYPE(PH_Elem_Base_Desc), INTENT(IN)  :: desc
    REAL(wp), INTENT(IN)  :: coords(:,:)   ! [ndim, n_nodes]
    REAL(wp), INTENT(IN)  :: bforce(:)     ! [ndim] 体力向量
    REAL(wp), INTENT(OUT) :: Fe(:)         ! [n_dof] 等效节点力
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Fe = 0.0_wp
    CALL init_error_status(status, STATUS_OK)
  END SUBROUTINE Sld2D_FormBodyForce_Generic

  SUBROUTINE Sld2D_FormEdgePressure_Generic(desc, coords, edge_id, pressure, Fe, status)
    TYPE(PH_Elem_Base_Desc), INTENT(IN)  :: desc
    REAL(wp), INTENT(IN)  :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: edge_id
    REAL(wp), INTENT(IN)  :: pressure
    REAL(wp), INTENT(OUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Fe = 0.0_wp
    CALL init_error_status(status, STATUS_OK)
  END SUBROUTINE Sld2D_FormEdgePressure_Generic

  SUBROUTINE Sld3D_FormBodyForce_Generic(desc, coords, bforce, Fe, status)
    TYPE(PH_Elem_Base_Desc), INTENT(IN)  :: desc
    REAL(wp), INTENT(IN)  :: coords(:,:)
    REAL(wp), INTENT(IN)  :: bforce(:)
    REAL(wp), INTENT(OUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Fe = 0.0_wp
    CALL init_error_status(status, STATUS_OK)
  END SUBROUTINE Sld3D_FormBodyForce_Generic

  SUBROUTINE Sld3D_FormSurfPressure_Generic(desc, coords, face_id, pressure, Fe, status)
    TYPE(PH_Elem_Base_Desc), INTENT(IN)  :: desc
    REAL(wp), INTENT(IN)  :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN)  :: pressure
    REAL(wp), INTENT(OUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    Fe = 0.0_wp
    CALL init_error_status(status, STATUS_OK)
  END SUBROUTINE Sld3D_FormSurfPressure_Generic

END MODULE PH_Elem_Load_Kernel
```

---

#### 22.2.4 ST-1.4：新建 Shared/PH_Elem_BC_Kernel.f90

**文件**：`ufc_core/L4_PH/Element/Shared/PH_Elem_BC_Kernel.f90`（新建）

```fortran
!==============================================================================
! Module: PH_Elem_BC_Kernel
! Layer:  L4_PH / Element / Shared
! Purpose: 跨族通用约束/MPC内核
!          被各族 Core 文件的 ApplyConstraint / ApplyMPC 委托调用
!==============================================================================
MODULE PH_Elem_BC_Kernel
  USE IF_Prec,    ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, STATUS_OK
  USE PH_Elem_Types, ONLY: PH_Elem_Base_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Sld_ApplyConstraint_Generic
  PUBLIC :: Sld_ApplyMPC_Generic

CONTAINS

  SUBROUTINE Sld_ApplyConstraint_Generic(desc, bc_dof, bc_val, Ke, Fe, status)
    TYPE(PH_Elem_Base_Desc), INTENT(IN)    :: desc
    INTEGER(i4), INTENT(IN) :: bc_dof(:)   ! 受约束自由度编号列表
    REAL(wp),    INTENT(IN) :: bc_val(:)   ! 对应约束值
    REAL(wp),    INTENT(INOUT) :: Ke(:,:)  ! [n_dof, n_dof]
    REAL(wp),    INTENT(INOUT) :: Fe(:)    ! [n_dof]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, STATUS_OK)
  END SUBROUTINE Sld_ApplyConstraint_Generic

  SUBROUTINE Sld_ApplyMPC_Generic(desc, mpc_coeff, mpc_rhs, Ke, Fe, status)
    TYPE(PH_Elem_Base_Desc), INTENT(IN)    :: desc
    REAL(wp),    INTENT(IN)    :: mpc_coeff(:,:)  ! MPC 系数矩阵
    REAL(wp),    INTENT(IN)    :: mpc_rhs(:)      ! MPC 右端项
    REAL(wp),    INTENT(INOUT) :: Ke(:,:)
    REAL(wp),    INTENT(INOUT) :: Fe(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status, STATUS_OK)
  END SUBROUTINE Sld_ApplyMPC_Generic

END MODULE PH_Elem_BC_Kernel
```

---

#### 22.2.5 ST-1.5：ShapeFunc 文件重叠清理

**现状**：存在两个版本：
- `L4_PH/Element/PH_Elem_ShapeFunc.f90`（根目录版，权威）
- `L4_PH/Element/Shared/PH_Elem_ShapeFunc.f90`（Shared版）

**操作步骤**：
```
1. 检查两个文件的模块名是否相同（gfortran 会报 MODULE redefinition）
2. 若模块名相同：Shared/ 版改为纯 USE 转发（USE PH_Elem_ShapeFunc, ONLY: ...）
3. 若模块名不同：检查调用方，统一为根目录版名称
4. 全量编译确认无 MODULE redefinition 错误
```

---

#### 22.2.6 ST-1.6：迁移 BATCH_CREATE_ALL.f90

**操作**：
```
将 ufc_core/L4_PH/Element/Shared/BATCH_CREATE_ALL.f90
移至 UFC/tools/elem_batch_create.f90
（或 UFC/tools/elem/BATCH_CREATE_ALL.f90）
```

---

### 22.3 ST-4 全族分批文件清单（精确到文件）

#### 22.3.1 ST-4.1：SLD3D/SLD2DT/SLD3DT 族（热力+纯力3D）

```
── SLD3D（纯力3D连续体）──────────────────────────────────────────────────
PH_Elem_C3D4_Core.f90     改Loads/BC → 委托 Load_Kernel/BC_Kernel
PH_Elem_C3D5_Core.f90
PH_Elem_C3D6_Core.f90
PH_Elem_C3D8_Core.f90
PH_Elem_C3D8_EAS.f90      * 仅改 Loads/BC；EAS增强应变部分不动
PH_Elem_C3D8_FBar.f90     * 仅改 Loads/BC；F-Bar部分不动
PH_Elem_C3D10_Core.f90
PH_Elem_C3D13_Core.f90
PH_Elem_C3D15_Core.f90
PH_Elem_C3D20_Core.f90
PH_Elem_C3D27_Core.f90
小计: 11个文件

── SLD2DT（2D热力耦合）─────────────────────────────────────────────────
PH_Elem_CAX3T_Core.f90 ... PH_Elem_CPS8T_Core.f90（共12个）
注：Load_Kernel 需新增 thermal_dof 注入支持
小计: 12个文件

── SLD3DT（3D热力耦合）─────────────────────────────────────────────────
PH_Elem_C3D4T_Core.f90 ... PH_Elem_C3D27T_Core.f90（共7个）
小计: 7个文件

ST-4.1 合计: 30个文件
```

#### 22.3.2 ST-4.2：SHELL 族（9种型号）

```
PH_Elem_S3_Core.f90
PH_Elem_S4_Core.f90
PH_Elem_S4T_Core.f90      * 含热力耦合字段
PH_Elem_S6_Core.f90
PH_Elem_S8_Core.f90
PH_Elem_S8RT_Core.f90     * 缩减积分+扭转
PH_Elem_S9_Core.f90
PH_Elem_DS3_Core.f90
PH_Elem_DS4_Core.f90
PH_Elem_DS6_Core.f90
PH_Elem_DS8_Core.f90
PH_Elem_Shell_MITC.f90    * 仅改 Loads/BC；MITC剪切锁定部分不动
ST-4.2 合计: 12个文件
```

#### 22.3.3 ST-4.3：BEAM/TRUSS/MEMBRANE/PIPE/SPRING/DASHPOT/SPECIAL

```
── BEAM ─────────────────────────────────────────────────────────────────
PH_Elem_B21T_Core.f90 / B23_Core / B31_Core / B31T_Core / B32_Core / B33_Core
小计: 6个文件

── TRUSS ────────────────────────────────────────────────────────────────
PH_Elem_T2D2_Core.f90 / T3D2_Core / T3D3_Core
小计: 3个文件

── MEMBRANE / PIPE ──────────────────────────────────────────────────────
PH_Elem_Membrane_Core.f90 / Pipe_Core（确认是否有Loads/BC，按需委托）
小计: 2个文件

── SPRING（轻量）────────────────────────────────────────────────────────
PH_Elem_SPRING1_Core.f90 / SPRING2_Core（只改BC；体力不适用）
小计: 2个文件

── DASHPOT（轻量）───────────────────────────────────────────────────────
PH_Elem_DASHPOT1_Core.f90 / DASHPOT2_Core（只改BC；体力不适用）
小计: 2个文件

── SPECIAL（刚/黏/垫片/质量）───────────────────────────────────────────
PH_Elem_COH2D4_Defn.f90   * 黏结单元：Loads 为牵引力，单独扩展Load_Kernel
PH_Elem_COH3D6_Defn.f90
PH_Elem_COH3D8_Defn.f90
PH_Elem_GK2D2_Defn.f90    * 垫片单元
PH_Elem_GK3D4_Defn.f90
PH_Elem_Mass.f90           * 集中质量：无 Loads/BC，跳过
PH_Elem_R2D2_Defn.f90     * 刚体单元：无独立 Loads/BC，跳过
PH_Elem_R3D3_Defn.f90     * 跳过
PH_Elem_R3D4_Defn.f90     * 跳过
小计: 9个文件（其中4个实际委托，5个跳过）

ST-4.3 合计: 24个文件（实际委托~15个）
```

#### 22.3.4 ST-4.4：POROUS/ACOUSTIC/Thermal/INFINITE

```
── POROUS（多孔介质，19个）─────────────────────────────────────────────
PH_Elem_C3D4P/C3D6P/C3D8P/C3D10P/C3D15P/C3D20P/C3D27P_Core.f90（7个）
PH_Elem_CAX3P/CAX4P/CAX6P/CAX8P_Core.f90（4个）
PH_Elem_CPE3P/CPE4P/CPE6P/CPE8P_Core.f90（4个）
PH_Elem_CPS3P/CPS4P/CPS6P/CPS8P_Core.f90（4个）
注：孔压 dof 需在 Load_Kernel 扩展（ST-4.4内完成v1.3）
小计: 19个文件

── ACOUSTIC（声学，9个）────────────────────────────────────────────────
PH_Elem_AC2D4/AC2D6/AC2D8_Core.f90（3个2D声学）
PH_Elem_AC3D4/AC3D6/AC3D8/AC3D10/AC3D15/AC3D20_Core.f90（6个3D声学）
注：声学载荷为声压；Load_Kernel 需新增声学压力载荷分支
小计: 9个文件

── Thermal（热传导，1个）───────────────────────────────────────────────
PH_Elem_HeatTransfer.f90
注：热通量/对流边界条件；Load_Kernel 需新增热边界分支
小计: 1个文件

── INFINITE（无限元，1个）──────────────────────────────────────────────
PH_Elem_Infinite_Core.f90
注：确认是否有 Loads/BC 逻辑，可能为跳过
小计: 1个文件

ST-4.4 合计: 30个文件
```

---

### 22.4 修正后的工作量统计表

```
任务类    任务数  改造文件数         估算工作量    优先级  阻塞风险
──────────────────────────────────────────────────────────────────────────
ST-1      6项    4改+2移/新         0.5天         P0      阻塞 ST-2~4
ST-2      5项    2新+4改            1天           P1      阻塞 ST-4
ST-3      7项    4新+1精简+1对接    3~5天         P1      阻塞 ST-4批量
ST-4.1    3批    30个               3~5天         P2      可拆批次
ST-4.2    1批    12个               1~2天         P2      可拆批次
ST-4.3    1批    24个（~15有效）    1~2天         P2      可拆批次
ST-4.4    1批    30个               2~4天         P2      可拆批次
ST-4.5    1项    1改                0.5天         P2      族ID对齐
ST-4.6    1项    1实现              0.5天         P2      依赖ST-2.1
ST-4.7    1项    1改/新             0.5天         P2      依赖ST-1.3
──────────────────────────────────────────────────────────────────────────
BT-*      16项   辅助性             2~4天         P2/P3   不阻塞
──────────────────────────────────────────────────────────────────────────
合计       ~47项  ~107个有效文件    ~16~26天（含验证）
```

**说明**：相比 §21.5 的估算（41项/~55文件/~10~16天），修正后：
- 任务数：+6（ST-4.4新增 POROUS/ACOUSTIC/Thermal 单独统计）
- 改造文件数：~55 → ~107（+PIPE/INFINITE/MEMBRANE/SPECIAL等族）
- 工作量：~10~16天 → ~16~26天（主要增量在 ST-4.4 多孔+声学族）

---

### 22.5 Load_Kernel 扩展路径（因多族需求而衍生）

```
Load_Kernel v1.0（ST-1.3建立）
  支持：SLD2D（平面/轴对称）体力 + 边压
  函数：Sld2D_FormBodyForce_Generic, Sld2D_FormEdgePressure_Generic

Load_Kernel v1.1（ST-2.2~2.3 试点验证后扩展）
  新增：Sld3D 体力 + 面压
  函数：Sld3D_FormBodyForce_Generic, Sld3D_FormSurfPressure_Generic

Load_Kernel v1.2（ST-4.1 热力耦合族扩展）
  新增：热-力耦合族的双场（位移+温度）等效节点力
  函数：SldT_FormBodyForce_Generic（ndof_mech + ndof_therm 参数注入）

Load_Kernel v1.3（ST-4.4 多孔+声学扩展）
  新增：多孔介质孔压等效力 + 声学声压载荷 + 热传导热通量
  函数：Porous_FormFluidBodyForce_Generic
          Acoustic_FormPressureLoad_Generic
          Thermal_FormHeatFlux_Generic

Load_Kernel v1.4（ST-4.3 梁/壳扩展）
  新增：线分布力（梁）+ 面外压力（壳）
  函数：Beam_FormDistributedLoad_Generic
          Shell_FormPressure_Generic
```

---

### 22.6 首批直接可执行动作清单（当前立即可开始）

```
优先级  动作ID     操作          文件                                预计时间
──────────────────────────────────────────────────────────────────────────────
★★★★★  EX-01   追加TYPE定义   PH_Elem_Types.f90（ST-1.1+ST-1.2）  30分钟
★★★★★  EX-02   新建文件      Shared/PH_Elem_Load_Kernel.f90       20分钟
★★★★★  EX-03   新建文件      Shared/PH_Elem_BC_Kernel.f90         15分钟
★★★★☆  EX-04   检查重叠      gfortran检查两个ShapeFunc模块名       10分钟
★★★★☆  EX-05   移动文件      BATCH_CREATE_ALL.f90→tools/          5分钟
──────────────────────────────────────────────────────────────────────────────
合计（PP-0→PP-1）                                                  ~80分钟
```

**EX-01~EX-03 完成后**即达到 PP-1 支点，可安全合入。后续所有 ST-2~4 任务均以此为基础。

---

*§22 最后更新*：2026-03-30，补充全族文件精确清单（含PIPE/INFINITE/MEMBRANE/SPECIAL六族），修正工作量估算（~107有效文件/~16~26天）。

