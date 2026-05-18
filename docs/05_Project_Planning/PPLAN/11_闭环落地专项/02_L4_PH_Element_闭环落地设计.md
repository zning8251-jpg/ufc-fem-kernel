# 02. L4_PH_Element (结构化降维积分) 闭环落地设计与十件套固化

## 1. 业务职责与边界

`L4_PH_Element` 是有限元物理计算的“核心引擎”。在旧核时代，它常常深陷于全局模型的嵌套之中。在全新架构下，该域被重构为**纯净的、无副作用的降维积分器**。

其核心职责是：接受**已切片（Sliced）**的单元级别节点坐标、当前位移和场状态，执行高斯积分（计算雅可比、形函数导数、B矩阵），调用材料模型评估应力并更新内变量，最终装配出单体的局部刚度矩阵（$K_e$）与局部残余力向量（$R_{int}$）。

---

## 2. 域级合同卡 (Domain Contract)

`PH_ElemRT_Brg`（门面）对外暴露的统一单元计算接口：

```yaml
# 域级合同卡：L4_PH_Element
Interface: PH_Elem_Compute
Description: 计算给定单体单元的局部刚度矩阵与残余力。
Inputs:
  - elem_cfg (PH_ElemConfig, IN)       : 单元几何拓扑只读配置（如：Family_ID, 节点数，初始参考坐标 coords0）。
  - elem_state (UF_ElementState, INOUT): 单元级场变量状态，包含积分点级别的旧应变、旧应力及历史依赖状态（SDV）。
  - elem_ctx (PH_ElemContext, INOUT)   : 单元工作上下文。输入当前迭代位移增量 u_elem，输出计算得到的局部刚度 Ke 与局部内力 R_int。
  - mat_cfg (MD_Mat_Ctx, IN)           : 材料只读属性配置（传给下一级本构调用）。
Outputs:
  - status (ErrorStatusType, OUT)      : 单元计算状态（如：雅可比行列式为负导致的网格畸变错误）。
```

### 与下层域的联动契约：
- **材料评估请求**：在高斯积分循环内部，组装每个积分点的增量应变 $\Delta \varepsilon$，然后向 `L3_MD` 材料域发起调度：
  `CALL MD_Mat_Dispatch(mat_cfg, ndim, nshr, dStrain, sdv_old, sdv_new, stress_old, stress_new, D_tangent, status)`

---

## 3. 十件套 (Ten-Piece Set) 物理固化映射

单元族种类繁多（如 Solid, Shell, Beam），为保持整洁，基础十件套位于 `ufc_core/L4_PH/Element/Shared/`，各族具体实现分形于子目录。

| 模块名 | 对应十件套 | 核心内容 / 属性列表 |
|---|---|---|
| `PH_Elem_Def.f90` | _Def | 单元形状枚举（`HEX8`, `QUAD4`），积分规则方案常量。 |
| `PH_Elem_Desc.f90` | _Desc | `PH_ElemConfig`：包含 `coords0(3, MAX_NODE)`。完全脱离了全局的 `Mesh` 或 `Model`。 |
| `MD_FieldState.f90`（旧称 `MD_FieldState_Algo.f90`） | _State | (借用L3) `UF_ElementState`：承载各积分点的 `strain`, `stress`, `sdv`，以及它们的 `_old` 值。 |
| `PH_Elem_Ctx.f90` | _Ctx | `PH_ElemContext`：`u_elem(:)`（入参位移），`Ke(:,:)`，`R_int(:)`，`Ke_geo`，`Ke_mat`。工作在栈上，保证线程安全。 |
| `PH_ElemC3D8.f90`（旧称 `PH_ElemC3D8_Algo.f90`） | _Algo | (实体族分支) 纯函数实现 `PH_Elem_C3D8_NL_TL_Structured`，严禁在内部调用全局变量或进行 I/O 读写。 |
| `PH_ElemRT_Brg.f90` | _Brg | 闭环合同的物理承载者。提供 `PH_Elem_Compute`，对接外层。 |
| `PH_ElemReg.f90`（旧称 `PH_ElemReg_Algo.f90`） | _Reg | `PH_ELEM_FAMILY_SOLID_2D`, `PH_ELEM_FAMILY_SOLID_3D` 的路由表。处理如 `mat_cfg%nshr == 1` 时调用 CPS4 而不是 CPE4。 |
| `PH_Elem_Err.f90` | _Err | `ERR_NEGATIVE_JACOBIAN`, `ERR_UNSUPPORTED_ELEMENT_TYPE`。 |
| `PH_Elem_Util.f90` | _Util | 高斯积分点权重和坐标获取的帮助函数（如 `PH_Elem_C3D8_GaussPoints`）。 |
| `PH_Elem_Test.f90` | _Test | 针对单体单元的 Patch Test（分片测试），输入固定位移场，断言 $Ke$ 是否精确匹配解析解。 |

---

## 4. 核心逻辑流转 (Algorithm Flow)

以三维实体单元 `C3D8` 为例 (`PH_Elem_C3D8_NL_TL_Structured`)：

1. **预处理 (Preparation)**：
   - 清零当前上下文中的刚度与残力矩阵：`Ke_mat = 0`, `Ke_geo = 0`, `R_int = 0`。
   - 获取当前配置下的现时坐标：`coords_curr = coords_ref + u_elem`。
2. **积分点循环 (Gauss Point Loop)**：
   - 提取该积分点的局域坐标 $(\xi, \eta, \zeta)$ 及权重 $w_{gp}$。
   - **运动学推导**：
     - 计算形函数关于母单元的导数 $dN/d\xi$。
     - 计算参考构型下的雅可比矩阵 $J_{ref}$ 及其行列式。若 $|J| \le 0$，触发网格畸变异常。
     - 求解形函数关于参考坐标的导数 $dN/dX$。
     - 构造变形梯度张量 $F$ 和相关的应变度量（如 Green-Lagrange 应变 $E$ 的 Voigt 形式）。
   - **本构映射 (Constitutive Mapping)**：
     - 计算增量应变 $\Delta E = E - E_{old}$。
     - 调用 `MD_Mat_Dispatch` 获取由物理层计算的 $S_{new}$ (第二类 Piola-Kirchhoff 应力) 以及材料切线矩阵 $D_{ep}$。
     - 回写更新后的应变、应力和状态变量到 `elem_state`。
   - **组装局部矩阵 (Local Assembly)**：
     - 构造位移-应变关系矩阵 $B_u$ 及其几何刚度相关算子 $G$。
     - 累加材料刚度：`Ke_mat += B_u^T * D_ep * B_u * |J| * w_{gp}`
     - 累加几何刚度：`Ke_geo += G^T * S_{hat} * G * |J| * w_{gp}`
     - 累加内力向量：`R_int += B_u^T * S_{voigt} * |J| * w_{gp}`
3. **后处理 (Finalization)**：
   - `Ke = Ke_mat + Ke_geo`。
   - 返回更新完毕的 `elem_ctx`。

---

## 5. 待执行动作清单 (Action Items)

- [ ] 完成其他单元（如 Shell, Beam）向 `_Structured` 纯函数风格的迁移。
- [ ] 确保 `PH_ElemRT_Brg` 的分发逻辑覆盖所有已支持的 Element Family。
- [ ] 编写针对 `PH_Elem_CPS4` / `CPE4` 降维（平面应力/平面应变）状态下的测试用例。