# 算法步规约：L4_PH / Material / Elas（各向同性线弹性）

> **类型**: 计算域黄金样板 | **版本**: v1.0 | **日期**: 2026-04-26
>
> **推演路径**: CONTRACT → 推演卡 → 算法步规约
>
> **关联**: [推演卡](DERIVATION_CARD_PH_Mat_Elas.md) · [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md)

---

## 一、最终目标（倒推起点）

| 交付物 | 消费者 | 说明 |
|--------|--------|------|
| `stress(6)` | L4_PH/Element → Fint 积分 | Voigt 应力向量 |
| `D_el(6,6)` | L4_PH/Element → Ke 积分 | 一致切线刚度阵 |
| `is_valid` | L5_RT/Material 路由 | 参数合法性标记 |

---

## 二、倒推数据树

```
stress(6)                ← D_el * strain
  └─ D_el(6,6)           ← Build from (lambda, G)
      ├─ lambda           ← E*nu / ((1+nu)(1-2nu))
      │   ├─ E            ← desc.E ← L3_MD/Material.props (Populate)
      │   └─ nu           ← desc.nu ← L3_MD/Material.props (Populate)
      └─ G                ← E / (2(1+nu))
          ├─ E            ← (同上)
          └─ nu           ← (同上)
  └─ strain(6)            ← 外部输入 (L4_PH/Element.Ctx → B*u)

is_valid                  ← (E > 0) ∧ (-1 < nu < 0.5)
  ├─ E                    ← (同上)
  └─ nu                   ← (同上)
```

---

## 三、正向算法步（拓扑排序）

### Step 0: Populate — L3→L4 数据桥接

**设计意图**: L3_MD/Material 是唯一真相源。L4 不直读 L3，通过 Populate/Bridge 单向提取所需参数到 L4 Desc slot。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| E (杨氏模量) | L3_MD/Material_Desc.props(1) | 外部 (用户输入/INP 解析) | 冷 |
| nu (泊松比) | L3_MD/Material_Desc.props(2) | 外部 (用户输入/INP 解析) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| desc.E | PH_Mat_Elas_Desc.E | Step 1, 2 | 冷 |
| desc.nu | PH_Mat_Elas_Desc.nu | Step 1, 2 | 冷 |

**算法核**:
```
desc.E  = l3_desc.props(1)
desc.nu = l3_desc.props(2)
```

**前置条件**: L3_MD/Material 已通过 Config Phase 完成材料卡注册
**后置保证**: desc.E, desc.nu 已填充，值与 L3 真相源一致
**Phase**: Populate
**复杂度**: O(1)
**过程**: `PH_Mat_Elas_Brg_FromL3Desc`

---

### Step 1: Validate_Props — 参数校验

**设计意图**: 在 Config Phase 早期拦截非法参数（E≤0、nu 超范围），避免后续热路径中出现 NaN/Inf。物理约束：E 是正定模量，nu 的热力学允许范围为 (-1, 0.5)（开区间）。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| E | 形参 props(1) 或 desc.E | Step 0 (Populate) | 冷 |
| nu | 形参 props(2) 或 desc.nu | Step 0 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| is_valid | 隐含 (status=0 ↔ valid) | Step 2 前置条件 | 冷 |

**算法核**:
```
IF (E <= 0.0_wp) THEN status = ERR_INVALID_E; RETURN
IF (nu <= -1.0_wp .OR. nu >= 0.5_wp) THEN status = ERR_INVALID_NU; RETURN
status = 0  ! valid
```

**前置条件**: E, nu 已从 L3 传入（Step 0 完成）
**后置保证**: status=0 当且仅当 E>0 ∧ -1<nu<0.5
**Phase**: Config
**复杂度**: O(1)
**过程**: `PH_Mat_Elas_Validate_Props`

---

### Step 2: Init_From_Props — 派生量计算

**设计意图**: 从原始参数 (E, nu) 计算一次性派生常数 (G, lambda, K_bulk, rho)，缓存到 Desc 中。避免在热路径中重复计算这些常数。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| E | desc.E | Step 0 (Populate) | 冷 |
| nu | desc.nu | Step 0 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| G (剪切模量) | desc.G | Step 3 (Build_D_el) | 冷 |
| lambda (Lamé 第一参数) | desc.lambda | Step 3 (Build_D_el) | 冷 |
| K_bulk (体积模量) | desc.K_bulk | 外部查询 | 冷 |
| is_valid | desc.is_valid | 外部路由判断 | 冷 |

**算法核**:
```
desc.G      = E / (2.0_wp * (1.0_wp + nu))
desc.lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
desc.K_bulk = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))
desc.is_valid = .TRUE.
```

**前置条件**: Step 1 通过 (status=0)，E>0 ∧ -1<nu<0.5
**后置保证**: G>0, lambda 有限, K_bulk>0, is_valid=.TRUE.
**Phase**: Config
**复杂度**: O(1)
**过程**: `PH_Mat_Elas_Init_From_Props`

---

### Step 3: Build_D_el — 构造弹性矩阵

**设计意图**: 构造 6×6 Voigt 格式弹性刚度矩阵 D_el，这是本域的**核心计算产物**。在线弹性中 D_el 不随应变变化，故可缓存。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| G | desc.G | Step 2 | 冷 |
| lambda | desc.lambda | Step 2 | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| D_el(6,6) | ctx.D_el | Step 4 (Compute_Stress), Step 5 (Compute_Tangent) | 热 |

**算法核**:
```
D_el = 0.0_wp
! 正应力分量
D_el(1,1) = lambda + 2*G; D_el(2,2) = lambda + 2*G; D_el(3,3) = lambda + 2*G
D_el(1,2) = lambda;       D_el(2,1) = lambda
D_el(1,3) = lambda;       D_el(3,1) = lambda
D_el(2,3) = lambda;       D_el(3,2) = lambda
! 剪应力分量
D_el(4,4) = G; D_el(5,5) = G; D_el(6,6) = G
```

**前置条件**: desc.G > 0, desc.lambda 已计算 (Step 2 完成)
**后置保证**: D_el 对称正定 (SPD)，det(D_el) > 0
**Phase**: Local (首次调用时构造，后续可缓存)
**复杂度**: O(36) — 填充 6×6 矩阵
**过程**: `PH_Mat_Elas_Build_D_el`

---

### Step 4: Compute_Stress — 应力更新

**设计意图**: 线弹性本构的**金线热路径**——在每个积分点、每次迭代调用。sigma = D_el * epsilon，无状态演化。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| D_el(6,6) | ctx.D_el | Step 3 (Build_D_el) | 热 |
| strain(6) | 形参 (外部输入) | 【跨域】L4_PH/Element.Ctx → B*u | 热 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| stress(6) | 形参 (外部输出) | 【跨域】L4_PH/Element → Fint/Fe 积分 | 热 |

**算法核**:
```
! Voigt 矩阵-向量乘法: sigma = D_el * epsilon
DO i = 1, 6
  stress(i) = 0.0_wp
  DO j = 1, 6
    stress(i) = stress(i) + D_el(i,j) * strain(j)
  END DO
END DO
```

**前置条件**: D_el 已构造 (Step 3), strain 由 Element 域计算提供
**后置保证**: stress(1:6) 已填充，满足 sigma = D_el * epsilon
**Phase**: Local (HOT_PATH)
**复杂度**: O(36) — 6×6 矩阵-向量乘法
**过程**: `PH_Mat_Elas_Compute_Stress`

---

### Step 5: Compute_Tangent — 一致切线

**设计意图**: 返回一致切线刚度阵 C_tan。对线弹性材料，C_tan ≡ D_el（恒等），故直接返回缓存的 D_el。对弹塑性等材料，此步需算法切线推导。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| D_el(6,6) | ctx.D_el | Step 3 (Build_D_el) | 热 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| tangent(6,6) | 形参 (外部输出) | 【跨域】L4_PH/Element → Ke = ∫B^T·C_tan·B | 热 |

**算法核**:
```
tangent(1:6,1:6) = D_el(1:6,1:6)   ! 线弹性: C_tan ≡ D_el
```

**前置条件**: D_el 已构造 (Step 3)
**后置保证**: tangent = D_el，对称正定
**Phase**: Local (HOT_PATH)
**复杂度**: O(36) — 6×6 拷贝
**过程**: `PH_Mat_Elas_Compute_Tangent`

---

### Step 6: Init_SDV — 状态变量初始化

**设计意图**: 线弹性无内变量（无塑性应变、无损伤变量等），此步为空操作。保留接口是因为 L5_RT/Material 统一对所有材料族调用 Init_SDV，接口一致性要求。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| nsdv | 形参 | L5_RT/Material 传入 | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| sdv(nsdv) | 形参 (外部) → 全零 | L5_RT/Material 状态管理 | 冷 |

**算法核**:
```
sdv(1:nsdv) = 0.0_wp   ! 线弹性: nsdv=0, 实际不执行
```

**前置条件**: nsdv ≥ 0
**后置保证**: sdv 全零初始化
**Phase**: Config
**复杂度**: O(1) (nsdv=0 for elastic)
**过程**: `PH_Mat_Elas_Init_SDV`

---

## 四、闭合性验证矩阵

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| desc.E | Step 0 (Populate) | Step 1, Step 2 | ✓ |
| desc.nu | Step 0 (Populate) | Step 1, Step 2 | ✓ |
| desc.G | Step 2 | Step 3 | ✓ |
| desc.lambda | Step 2 | Step 3 | ✓ |
| desc.K_bulk | Step 2 | 外部查询 | ✓ |
| desc.is_valid | Step 2 | 外部路由 | ✓ |
| ctx.D_el(6,6) | Step 3 | Step 4, Step 5 | ✓ |
| strain(6) | 外部 (Element) | Step 4 | ✓ (外部输入) |
| stress(6) | Step 4 | 外部 (Element) | ✓ (外部输出) |
| tangent(6,6) | Step 5 | 外部 (Element) | ✓ (外部输出) |
| sdv(:) | Step 6 | 外部 (RT_Material) | ✓ (外部输出) |
| status | Step 1 | Step 2 前置条件 | ✓ |

**结论**: 11 数据项全部闭合，无悬空生产、无无源消费、无环。

---

## 五、跨域数据流

```
L3_MD/Material ──(Populate)──→ PH_Mat_Elas_Desc (E, nu)
                                      ↓ Config
                               Validate → Init_From_Props (G, lambda)
                                      ↓ Local (per IP, per iter)
                               Build_D_el → ctx.D_el
                                      ↓
        strain ←── Element.Ctx ──→ Compute_Stress ──→ stress ──→ Element (Fint)
                                    ctx.D_el ──→ Compute_Tangent ──→ tangent ──→ Element (Ke)
```

---

## 六、测试断言（由前置/后置条件直接导出）

| 测试用例 | 断言 |
|---------|------|
| E=210e3, nu=0.3 → G=? | G ≈ 80769.23 (误差 < 1e-6) |
| E=-1 → Validate | status ≠ 0 |
| nu=0.5 → Validate | status ≠ 0 (不可压) |
| E=1, nu=0 → stress | stress = strain (D_el = diag(2G+lambda,…,G)) → G=0.5, lambda=0 |
| D_el 对称性 | D_el(i,j) = D_el(j,i) ∀ i,j |
| D_el 正定性 | x^T D_el x > 0 ∀ x≠0 |
| stress = D_el * strain | 线性关系精确 (FP 误差 < eps_mach * ||D_el|| * ||strain||) |
