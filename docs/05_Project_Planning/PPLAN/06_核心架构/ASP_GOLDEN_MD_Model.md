# 算法步规约：L3_MD / Model（顶层模型树）

> **类型**: 数据域黄金样板 | **版本**: v1.0 | **日期**: 2026-04-26
>
> **推演路径**: CONTRACT → 推演卡 → 算法步规约
>
> **关联**: [推演卡](DERIVATION_CARD_L3_MD.md#model) · [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md)

---

## 一、最终目标（倒推起点）

| 交付物 | 消费者 | 说明 |
|--------|--------|------|
| model_desc (含完整 Part/Step 注册表) | L3_MD/Bridge → L4/L5 Populate | 模型树结构完备 |
| is_valid (全模型校验通过) | L6_AP/Job 启动前置条件 | 确保可提交求解 |
| n_dim, n_parts, n_steps (元数据) | 多层消费 | 基本几何/分析维度 |

---

## 二、倒推数据树

```
is_valid (全模型校验通过)
  └─ Validate_All
      ├─ parts 全部合法   ← 每个 Part 已指派 Section
      ├─ steps 全部合法   ← 每个 Step 有时间窗
      └─ model 基本完备   ← n_dim > 0, name 非空

model_desc.parts(:)
  └─ Register_Part ← 外部 (INP 解析/L6 调用) 注册
      └─ MD_Part_Desc ← 外部 (用户配置)

model_desc.steps(:)
  └─ Register_Step ← 外部 (INP 解析/L6 调用) 注册
      └─ MD_Analysis_Step_Desc ← 外部 (用户配置)
```

---

## 三、正向算法步（拓扑排序）

### Step 0: Core_Init — 模型树初始化

**设计意图**: 分配模型描述器 Desc，零初始化所有字段。数据域的 Init 是"空容器就绪"，后续通过 CRUD 操作填充。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| (无) | — | — | — |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| model_desc (空) | MD_Model_Desc | Step 1–4 | 冷 |

**算法核**:
```
model_desc = MD_Model_Desc()     ! 零初始化
model_desc.n_parts = 0
model_desc.n_steps = 0
model_desc.n_dim = 0
model_desc.name = ''
```

**前置条件**: 无
**后置保证**: model_desc 已分配，所有计数器为零
**Phase**: Config
**复杂度**: O(1)
**过程**: `MD_Model_Core_Init`

---

### Step 1: Set_Name — 设置模型名称

**设计意图**: 为模型树赋予唯一名称（用于日志、输出文件名、Job ID 关联）。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| name | 形参 (外部) | 外部 (INP *HEADING / L6_AP) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| model_desc.name | desc | Step 5 (Validate), Step 6 (Summary) | 冷 |

**算法核**:
```
model_desc.name = name
```

**前置条件**: Step 0 完成
**后置保证**: model_desc.name 非空
**Phase**: Config
**复杂度**: O(1)
**过程**: `MD_Model_Set_Name`

---

### Step 2: Register_Part — 注册部件

**设计意图**: 将部件 ID 注册到模型树的 parts 列表。可多次调用（每次注册一个 Part）。数据域的 CRUD 典型操作。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| part_id | 形参 (外部) | 外部 (INP *PART / L6_AP) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| model_desc.parts(n) | desc | Step 5 (Validate), Step 8 (Get_N_Parts) | 冷 |
| model_desc.n_parts (+1) | desc | Step 5, 8 | 冷 |

**算法核**:
```
model_desc.n_parts = model_desc.n_parts + 1
model_desc.parts(model_desc.n_parts) = part_id
```

**前置条件**: Step 0 完成, n_parts < MAX_PARTS
**后置保证**: parts(n_parts) = part_id, n_parts 递增
**Phase**: Config
**复杂度**: O(1)
**过程**: `MD_Model_Register_Part`

---

### Step 3: Register_Step — 注册分析步

**设计意图**: 将分析步 ID 注册到模型树的 steps 列表。与 Register_Part 对称。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| step_id | 形参 (外部) | 外部 (INP *STEP / L6_AP) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| model_desc.steps(n) | desc | Step 5 (Validate), Step 9 (Get_N_Steps) | 冷 |
| model_desc.n_steps (+1) | desc | Step 5, 9 | 冷 |

**算法核**:
```
model_desc.n_steps = model_desc.n_steps + 1
model_desc.steps(model_desc.n_steps) = step_id
```

**前置条件**: Step 0 完成, n_steps < MAX_STEPS
**后置保证**: steps(n_steps) = step_id, n_steps 递增
**Phase**: Config
**复杂度**: O(1)
**过程**: `MD_Model_Register_Step`

---

### Step 4: Set_NDim — 设定分析维度（隐含于 Init 或单独）

**设计意图**: 设定空间维度 (2D/3D)。影响所有下游 Voigt 向量长度、B 阵形状。

**消费 [IN]**: n_dim (形参, 外部)
**生产 [OUT]**: model_desc.n_dim
**算法核**: `model_desc.n_dim = n_dim`
**Phase**: Config | **复杂度**: O(1)

---

### Step 5: Validate_All — 全模型校验

**设计意图**: 在 Config Phase 结束、进入 Populate 之前，校验模型树完备性。这是**数据域的闸门**——校验不通过则不允许求解。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| model_desc.name | desc | Step 1 | 冷 |
| model_desc.n_parts | desc | Step 2 (累积) | 冷 |
| model_desc.n_steps | desc | Step 3 (累积) | 冷 |
| model_desc.n_dim | desc | Step 4 | 冷 |
| parts(:) 每个 Part 的 Section 指派 | desc | 外部 (MD_Part/Section) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| is_valid | status | L6_AP/Job 前置条件 | 冷 |
| error_details | status.message | L6_AP/UI 报告 | 冷 |

**算法核**:
```
IF (LEN_TRIM(model_desc.name) == 0) status = ERR_NO_NAME; RETURN
IF (model_desc.n_dim < 2 .OR. model_desc.n_dim > 3) status = ERR_NDIM; RETURN
IF (model_desc.n_parts == 0) status = ERR_NO_PARTS; RETURN
IF (model_desc.n_steps == 0) status = ERR_NO_STEPS; RETURN
! 遍历检查每个 Part 是否有 Section
DO i = 1, model_desc.n_parts
  IF (.NOT. Part_Has_Section(model_desc.parts(i))) status = ERR_PART_NO_SECT; RETURN
END DO
status = 0  ! valid
```

**前置条件**: Step 1–4 完成，所有子域 (Material, Section, Mesh, …) 已注册
**后置保证**: status=0 当且仅当模型树完备
**Phase**: Config
**复杂度**: O(n_parts + n_steps)
**过程**: `MD_Model_Validate_All`

---

### Step 6–9: 查询接口

| Step | 过程 | 消费 | 生产 | 算法核 |
|------|------|------|------|--------|
| 6 | `MD_Model_Summary` | model_desc 全部字段 | 格式化文本 | WRITE to stdout |
| 7 | `MD_Model_Get_NDim` | model_desc.n_dim | 返回值 i4 | `result = model_desc.n_dim` |
| 8 | `MD_Model_Get_N_Parts` | model_desc.n_parts | 返回值 i4 | `result = model_desc.n_parts` |
| 9 | `MD_Model_Get_N_Steps` | model_desc.n_steps | 返回值 i4 | `result = model_desc.n_steps` |

**Phase**: (any) | **复杂度**: O(1) | **温度**: 冷

---

### Step 10: Core_Finalize — 模型树清理

**设计意图**: 释放模型树占用的内存（动态数组）。

**消费 [IN]**: model_desc (待释放)
**生产 [OUT]**: (无 — 资源释放)
**算法核**: `DEALLOCATE(model_desc.parts, model_desc.steps)`
**Phase**: Config | **复杂度**: O(1)
**过程**: `MD_Model_Core_Finalize`

---

## 四、闭合性验证矩阵

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| model_desc (空容器) | Step 0 | Step 1–10 | ✓ |
| model_desc.name | Step 1 | Step 5, 6 | ✓ |
| model_desc.parts(:) | Step 2 (累积) | Step 5, 8, Bridge | ✓ |
| model_desc.n_parts | Step 2 (累积) | Step 5, 8 | ✓ |
| model_desc.steps(:) | Step 3 (累积) | Step 5, 9, Bridge | ✓ |
| model_desc.n_steps | Step 3 (累积) | Step 5, 9 | ✓ |
| model_desc.n_dim | Step 4 | Step 5, 7, Bridge | ✓ |
| is_valid | Step 5 | 外部 (L6_AP/Job) | ✓ |

**结论**: 8 数据项全部闭合。

---

## 五、数据域典型模式总结

数据域的算法步规约遵循固定模式：

```
Init (空容器) → CRUD 操作 (Add/Set/Get) → Validate (闸门) → Finalize (释放)
```

| 模式阶段 | Phase | Verb | 说明 |
|---------|-------|------|------|
| 创建容器 | Config | Init | 分配、零初始化 |
| 填充数据 | Config | Access(Add/Set) | 来自外部输入（INP/API） |
| 校验闸门 | Config | Validate | 完备性/一致性检查 |
| 对外供数据 | (any) | Access(Get/Find) | 只读查询，不改状态 |
| 释放资源 | Config | Init(Fin) | DEALLOCATE |

此模式适用于 L3_MD 全部 13 个数据域（Model/Analysis/Mesh/Material/Section/Part/Assembly/Boundary/Constraint/Field/Interaction/KeyWord/Output）。
