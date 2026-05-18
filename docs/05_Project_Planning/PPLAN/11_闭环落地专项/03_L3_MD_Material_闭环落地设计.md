# 03. L3_MD_Material (弹塑性本构回归) 闭环落地设计与十件套固化

## 1. 业务职责与边界

`L3_MD_Material` 是 UFC 求解器物理保真度（Fidelity）的核心支撑。在全新的闭环架构中，该域彻底摒弃了原来与单元类型硬绑定的代码，转化为一个**通用且自适应维度的高性能本构计算器**。

其核心职责是：接受从高斯积分点传入的增量应变 ($\Delta \varepsilon$)、上一增量步的应力 ($\sigma_n$) 及历史状态变量 ($SDV_n$)，执行局部积分（如弹性的直接更新，或塑性的径向回归/Return Mapping），并返回当前步的应力 ($\sigma_{n+1}$)、更新后的状态变量 ($SDV_{n+1}$) 以及用于组装全局牛顿切线的算法一致切线模量 ($D_{ep}$)。

---

## 2. 域级合同卡 (Domain Contract)

`MD_MatRT_Brg`（材料调度门面）提供给 L4_PH_Element 域的唯一入口：

```yaml
# 域级合同卡：L3_MD_Material
Interface: MD_Mat_Dispatch
Description: 统一的材料本构调度与评估门面，自适应 2D/3D 降维计算。
Inputs:
  - mat_cfg (MD_Mat_Ctx, IN)      : 包含材料物理常量（如 E, nu, 屈服应力等只读配置）。
  - ndim (INTEGER, IN)            : 空间自由度维度（2 或 3）。
  - nshr (INTEGER, IN)            : 剪切分量数（1 或 3）。用于配合 ndim 决定 Voigt 表示的长度。
  - dStrain (REAL Array, IN)      : 给定积分点传入的应变增量（通常为 Voigt 格式）。
  - state_old (REAL Array, IN)    : 积分点历史状态变量（如上一级的等效塑性应变 peeq）。
  - stress_old (REAL Array, IN)   : 上一增量步的应力向量。
Outputs:
  - state_new (REAL Array, OUT)   : 本次径向回归计算后的历史状态变量更新。
  - stress_new (REAL Array, OUT)  : 本次计算得到的当前应力向量。
  - D_tangent (REAL Matrix, OUT)  : 一致切线模量矩阵（Consistent Tangent Modulus）。
  - status (ErrorStatusType, OUT) : 材料计算异常（如无法收敛或超弹性材料的参数错误）。
```

---

## 3. 十件套 (Ten-Piece Set) 物理固化映射

基础的类型定义放置在 `ufc_core/L3_MD/Material/Base/` 中，具体的本构算法实现在各自的独立模块内进行：

| 模块名 | 对应十件套 | 核心内容 / 属性列表 |
|---|---|---|
| `MD_Mat_Def.f90` | _Def | 定义本构类型的全局枚举，如 `MAT_ELAS_ISO`, `MAT_PLAST_J2_ISO`。 |
| `MD_Mat_Desc.f90` | _Desc | （位于L3基类）提供描述属性的内存布局；材料卡的 JSON 解析映射。 |
| `MD_Mat_State.f90` | _State | （通常被合并入 `MD_FieldState_Algo` 处理）定义如 `peeq` 等状态的具体位置索引。 |
| `MD_Mat_Ctx.f90` | _Ctx | `MD_Mat_Ctx` 复合结构：融合 `MD_Mat_Desc`，包含弹性和塑性的配置常量 `mat_cfg%elastic%E`, `mat_cfg%plastic%yield_stress_0`。 |
| `MD_Mat_J2.f90`（旧称 `MD_Mat_J2_Algo.f90`） | _Algo | (实体弹塑性分支) 提供严格纯函数的本构算法：`J2_Plasticity_Eval` 等。 |
| `MD_MatRT_Brg.f90` | _Brg | **本域防腐门面**。承载 `MD_Mat_Dispatch` 合同接口。 |
| `MD_Mat_Reg.f90` | _Reg | 材料字典。依据模型建立时的输入将不同元素的材料 ID 分发给对应的本构算法。 |
| `MD_Mat_Err.f90` | _Err | 本构求解失败异常枚举，如 `ERR_YIELD_SURFACE_NON_CONVERGENCE`。 |
| `MD_Mat_Util.f90` | _Util | 张量代数工具，如 Voigt 与张量形式相互转换，不变量计算（$J_2$, $p$ 等）。 |
| `MD_Mat_Test.f90` | _Test | 单点积分测试（Single-Point Test），独立调用 `MD_Mat_Dispatch`，输入纯拉伸应变驱动，验证应力-应变曲线。 |

---

## 4. 核心逻辑流转 (Algorithm Flow)

以经典 $J_2$ 弹塑性本构（冯·米塞斯屈服准则 + 等向强化）为例，`J2_Plasticity_Eval` 内的流转逻辑如下：

1. **输入准备与拆解 (Input Decomposition)**：
   - 根据输入 `ndim` 和 `nshr`（例如 2D 时的 $nv = 3$，3D 时的 $nv = 6$），拆解旧应力与应变增量。
   - 提取体应变增量（Volumetric）与偏应变增量（Deviatoric）。
2. **弹性预测步 (Elastic Predictor)**：
   - 假定增量步内完全无塑性流动，计算**试探应力（Trial Stress）**：$S^{trial} = S_n + D^{el} \Delta \varepsilon$。
   - 提取试探应力的静水压力 $p^{trial}$ 和偏应力张量 $devS^{trial}$。
   - 计算 $J_2$ 不变量并计算等效 Mises 应力 $q^{trial} = \sqrt{3 J_2}$。
3. **屈服判定与径向回归 (Return Mapping)**：
   - 计算当前试探应力与屈服面的距离函数：$f^{trial} = q^{trial} - (\sigma_{y0} + H \cdot \varepsilon_p^{eq})$。
   - **弹性阶段**：若 $f^{trial} \le 0$，则处于弹性域。更新应力 $\sigma_{n+1} = S^{trial}$，状态变量保持不变，返回纯弹性切线 $D_{ep} = D^{el}$。
   - **塑性阶段**：若 $f^{trial} > 0$，激活塑性流动。
     - 计算塑性乘子增量 $\Delta \lambda = \frac{f^{trial}}{3G + H}$。
     - 更新等效塑性应变：$\varepsilon_p^{eq} = \varepsilon_p^{eq} + \Delta \lambda$。
     - 径向拉回偏应力：利用缩放因子 $\beta = 1 - \frac{3G \Delta \lambda}{q^{trial}}$ 进行回归，$\sigma_{n+1} = p^{trial} \mathbf{I} + \beta \cdot devS^{trial}$。
4. **算法切线模量推导 (Algorithmic Tangent Modulus)**：
   - 为确保在全局牛顿迭代（Newton-Raphson）中保持二阶收敛速率（Quadratic Convergence），必须组装出连续介质的一致切线模量 $D_{ep}$。
   - 计算连续体切线：$D_{ep} = K (\mathbf{I} \otimes \mathbf{I}) + 2G \beta (\mathbf{I}_{dev}) - 2G \gamma (\mathbf{n} \otimes \mathbf{n})$，并装配为矩阵返回。

---

## 5. 待执行动作清单 (Action Items)

- [ ] 完成 `J2_Plasticity_Eval` 中真正的连续体一致切线（Consistent Tangent）组装（目前架构中使用了简化弹性切线保底）。
- [ ] 为该模块引入自动微分（AD）伴随矩阵占位，以便向 AI-Ready 闭环平滑演进。
- [ ] 确保在平面应力（Plane Stress）情况下，通过特定的局部 Newton 迭代去强制面外应力为零的回归映射得到正确处理。