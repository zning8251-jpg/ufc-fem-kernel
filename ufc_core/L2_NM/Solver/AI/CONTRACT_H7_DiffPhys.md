# H7 DiffPhys Partial Pillar Contract

> **Pillar**: H7 DiffPhys (Differentiable Physics)
> **Type**: Partial Pillar (L2_NM + L4_PH, DEFERRED L3_MD)
> **Version**: v1.0
> **Created**: 2026-04-26
> **Status**: PLACEHOLDER (AI P0)

---

## 一、域柱定义

### 核心职责

H7 DiffPhys 是 UFC 可微分物理引擎的域柱骨架，提供 FEM 残差对设计变量的精确导数，使 AI 模型能利用物理梯度进行在线自适应更新。

### 三层分布

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L2_NM | `NM_AIAdjointAlgo` | 伴随求解: Kᵀ·lambda = dJ/du | STUB |
| L4_PH | `PH_Elem_dRdTheta` | 单元残差灵敏度: dR_e/dtheta | STUB |
| L3_MD | -(DEFERRED) | theta 设计变量定义 | 未创建 |

### 不属于 H7 的内容

- 6 个推理插槽 (1-6) — 归属各自宿主域 (Domain Enhancement)
- L1 IF_AI_Runtime — 横切基础设施
- 训练循环编排 — L6_AP 或外部 Python

---

## 二、数学公式

```
前向:   K · u = F          (残差 R = Ku - F)
伴随:   Kᵀ · lambda = dJ/du  (求解伴随变量 lambda)
梯度:   dJ/dtheta = -lambdaᵀ · (dR/dtheta)  (设计灵敏度)
```

其中:
- **theta**: 设计变量 (材料参数 E/nu/sigma_y, 拓扑密度, 几何形状)
- **J**: 目标函数 (柔度、应力约束、位移目标)
- **R**: FEM 残差向量
- **K**: 刚度矩阵

---

## 三、梯度策略三档

| 档位 | 方法 | 里程碑 | 精度 | 代价 |
|------|------|--------|------|------|
| Tier 1 | 有限差分 (FD) | AI P2 试点 | O(h) | n_theta 次前向求解 |
| Tier 2 | 手写解析切线/伴随 | AI P3 目标 | 精确 | 1 次转置求解 |
| Tier 3 | AD 工具链 (Tapenade) | 长期 | 精确 | 源码变换 |

---

## 四、四型裁剪

| 四型 | L2 (Adjoint) | L4 (dR/dtheta) | L3 (theta Def) |
|------|-------------|----------------|----------------|
| Desc | -(配置内嵌) | DiffPhys_Elem_Config | DEFERRED |
| State | -(性能指标内嵌) | - | DEFERRED |
| Algo | NM_AI_Adjoint_Type (主体) | PH_GRAD_* 枚举 | - |
| Ctx | -(单次调用) | - | - |

> 当前 STUB 阶段，四型未严格分离（单体 TYPE 足够）。实施 Tier 2/3 时应裁剪为标准四型。

---

## 五、跨柱交互

| 交互 | 方向 | 说明 |
|------|------|------|
| H7 → Element (P2) | L4 内部 | dR/dtheta 需要单元刚度/残差计算 |
| H7 → Material (P1) | L4 内部 | 材料切线模量的灵敏度 |
| H7 → NM Solver | L2 内部 | 转置求解共用 CSR 基础设施 |
| H7 ← L6_AP/外部 | 编排 | 训练循环调用 → 伴随求解 → 梯度回传 |

---

## 六、约束

| 约束 | 级别 | 说明 |
|------|------|------|
| 单向依赖: 不得反向 USE L5_RT | **硬** | 总纲 §11.4 铁律 |
| 默认关闭 | **硬** | enabled = .FALSE., 零运行时开销 |
| 梯度不入标准前向求解热路径 | **硬** | 仅训练/优化离线场景激活 |
| ONNX 不需要 | 信息 | 伴随求解是纯矩阵操作 |

---

## 七、文件清单

| 文件 | 层 | 状态 |
|------|---|------|
| `L2_NM/Solver/AI/NM_AIAdjointAlgo.f90` | L2 | STUB |
| `L4_PH/Element/PH_Elem_dRdTheta.f90` | L4 | STUB |
| `L2_NM/Solver/AI/CONTRACT_H7_DiffPhys.md` | 合同 | v1.0 |

---

*维护: 实施 Tier 2/3 时更新本合同，裁剪四型、补充 L3 theta 定义。*
