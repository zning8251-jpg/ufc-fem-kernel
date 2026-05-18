# 算法步规约：L5_RT / StepDriver（步级编排）

> **类型**: 编排域黄金样板 | **版本**: v1.0 | **日期**: 2026-04-26
>
> **推演路径**: CONTRACT → 推演卡 → 算法步规约
>
> **关联**: [推演卡](DERIVATION_CARD_RT_StepDriver.md) · [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md)

---

## 一、最终目标（倒推起点）

| 交付物 | 消费者 | 说明 |
|--------|--------|------|
| `u(:)` 收敛位移场 | L5_RT/WriteBack, L5_RT/Output | 步结束时的收敛解 |
| `state.step_status = COMPLETED` | L6_AP/Job 循环终止 | 步完成标记 |
| `state.time_current = desc.time_end` | 时间推进保证 | 步结束时间匹配 |

---

## 二、倒推数据树

```
u(:) 收敛位移场
  └─ NR_Increment 迭代收敛
      ├─ Assemble_K, Assemble_F  ← 【跨域】RT_Assembly
      ├─ Solve_Linear             ← 【跨域】RT_Solver / NM_Solver
      ├─ Check_Convergence        ← RT_Solver
      └─ dt_trial (时间增量)
          └─ Begin_Increment 设定
              └─ algo.auto_dt, state.dt, desc.dt_max

step_status = COMPLETED
  └─ Check_Step_Complete
      ├─ state.time_current >= desc.time_end
      └─ time_current
          └─ Advance_Time
              └─ dt_trial
                  └─ (同上)

time_current = time_end
  └─ 增量循环正常终结
      ├─ Begin_Step 初始化 time_current = desc.time_start
      └─ 增量循环中 Advance_Time 逐步推进
```

---

## 三、正向算法步（拓扑排序）

### Step 0: Core_Init — 四型数据初始化

**设计意图**: 分配并零初始化四型数据结构 (Desc, State, Algo, Ctx)。这是编排域唯一需要的一次性分配。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| (无外部输入) | — | — | — |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| desc (零初始) | RT_StepDriver_Desc | Step 2 (Populate) | 冷 |
| state (零初始) | RT_StepDriver_State | Step 3+ | 冷 |
| algo (零初始) | RT_StepDriver_Algo | Step 2 (Populate) | 冷 |
| ctx (零初始) | RT_StepDriver_Ctx | Step 4+ | 温 |

**算法核**:
```
desc  = RT_StepDriver_Desc()     ! 零初始化
state = RT_StepDriver_State()
algo  = RT_StepDriver_Algo()
ctx   = RT_StepDriver_Ctx()
state.step_status = STEP_NOT_STARTED
```

**前置条件**: 无
**后置保证**: 四型对象已分配，state.step_status = STEP_NOT_STARTED
**Phase**: Config
**复杂度**: O(1)
**过程**: `RT_StepDriver_Core_Init`

---

### Step 1: Populate — L3/L6 数据灌入

**设计意图**: 从 L3_MD/Analysis.Step 和 L6_AP/Config 提取步配置（时间窗、增量限制）和算法参数（自适应策略）。编排域不直读 L3。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| time_start, time_end | L3_MD/Analysis_Step_Desc | 外部 (INP 配置) | 冷 |
| dt_init, dt_min, dt_max | L3_MD/Analysis_Step_Desc | 外部 (INP 配置) | 冷 |
| max_inc, max_cutbacks | L3_MD/Analysis_Step_Desc | 外部 (INP 配置) | 冷 |
| cutback_factor, growth_factor | L6_AP/Config 或 L3 | 外部 | 冷 |
| auto_dt, target_iters | L6_AP/Config 或 L3 | 外部 | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| desc.time_start/end | desc | Step 3, 9 | 冷 |
| desc.dt_init/min/max | desc | Step 5, 8 | 冷 |
| desc.max_inc/max_cutbacks | desc | Step 5, 8 | 冷 |
| algo.cutback_factor | algo | Step 8 | 冷 |
| algo.growth_factor | algo | Step 6 | 冷 |
| algo.auto_dt, target_iters | algo | Step 6, 12 | 冷 |

**算法核**:
```
desc.time_start = l3_step.time_start; desc.time_end = l3_step.time_end
desc.dt_init = l3_step.dt_init; desc.dt_min = l3_step.dt_min; desc.dt_max = l3_step.dt_max
desc.max_inc = l3_step.max_inc; desc.max_cutbacks = l3_step.max_cutbacks
algo.cutback_factor = config.cutback_factor  ! 默认 0.5
algo.growth_factor  = config.growth_factor   ! 默认 1.5
algo.auto_dt = config.auto_dt; algo.target_iters = config.target_iters
```

**前置条件**: L3_MD/Analysis 已完成 Config Phase
**后置保证**: desc 和 algo 字段全部有效
**Phase**: Populate
**复杂度**: O(1)
**过程**: Bridge 模块 (L3→L5)

---

### Step 3: Begin_Step — 步开始

**设计意图**: 步级状态机的入口点。重置增量计数器，设定初始时间增量，标记步为"进行中"。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| desc.time_start | desc | Step 1 (Populate) | 冷 |
| desc.dt_init | desc | Step 1 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| state.time_current | state | Step 7, 9, 10 | 温 |
| state.dt | state | Step 5 | 温 |
| state.inc_num | state | Step 5 | 温 |
| state.n_cutbacks | state | Step 8 | 温 |
| state.step_status | state | Step 4, 9 | 温 |

**算法核**:
```
state.time_current = desc.time_start
state.dt = desc.dt_init
state.inc_num = 0
state.n_cutbacks = 0
state.total_iters = 0
state.step_status = STEP_IN_PROGRESS
ctx.inc_converged = .FALSE.
```

**前置条件**: Step 0, 1 完成; state.step_status = STEP_NOT_STARTED 或上一步已 End_Step
**后置保证**: state.time_current = desc.time_start, state.step_status = STEP_IN_PROGRESS
**Phase**: Step
**复杂度**: O(1)
**过程**: `RT_StepDriver_Begin_Step`

---

### Step 4: End_Step — 步结束

**设计意图**: 步级状态机的出口点。标记步完成，可触发 WriteBack/Output。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| state.step_status | state | Step 3 (Begin_Step) | 温 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| state.step_status = COMPLETED | state | 外部 (L6_AP/Job) | 温 |

**算法核**:
```
state.step_status = STEP_COMPLETED
```

**前置条件**: Check_Step_Complete 返回 .TRUE.
**后置保证**: state.step_status = STEP_COMPLETED
**Phase**: Step
**复杂度**: O(1)
**过程**: `RT_StepDriver_End_Step`

---

### Step 5: Begin_Increment — 增量开始

**设计意图**: 增量级状态机入口。递增 inc_num，截断 dt 使得不超过 time_end，设定增量试探时间。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| state.inc_num | state | Step 3 或上一轮 Step 6 | 温 |
| state.dt | state | Step 3 或 Step 8 (Cutback) | 温 |
| state.time_current | state | Step 3 或 Step 7 | 温 |
| desc.time_end | desc | Step 1 (Populate) | 冷 |
| desc.max_inc | desc | Step 1 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| state.inc_num (+1) | state | Step 6, 外部日志 | 温 |
| ctx.dt_trial | ctx | Step 7, 12 | 热 |
| ctx.time_at_inc_start | ctx | Step 8 (Cutback 回退) | 热 |
| ctx.inc_converged | ctx (.FALSE.) | Step 6, 12 | 热 |

**算法核**:
```
state.inc_num = state.inc_num + 1
ctx.time_at_inc_start = state.time_current
ctx.dt_trial = MIN(state.dt, desc.time_end - state.time_current)
IF (ctx.dt_trial < desc.dt_min) ctx.dt_trial = desc.dt_min
ctx.inc_converged = .FALSE.
ctx.inc_iters = 0
```

**前置条件**: state.step_status = STEP_IN_PROGRESS, inc_num < max_inc
**后置保证**: ctx.dt_trial > 0, ctx.dt_trial ≤ desc.time_end - time_current
**Phase**: Increment
**复杂度**: O(1)
**过程**: `RT_StepDriver_Begin_Increment`

---

### Step 6: End_Increment — 增量结束（分叉）

**设计意图**: 增量级状态机出口。根据收敛结果选择推进（Advance）或切回（Cutback）。这是编排域的**关键决策点**。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| ctx.inc_converged | ctx | Step 12 (NR_Increment) | 热 |
| desc.max_cutbacks | desc | Step 1 (Populate) | 冷 |
| state.n_cutbacks | state | Step 3 或 Step 8 | 温 |
| algo.growth_factor | algo | Step 1 (Populate) | 冷 |
| algo.auto_dt | algo | Step 1 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| → 调用 Step 7 (Advance) 或 Step 8 (Cutback) | — | — | — |
| state.dt (可能自适应增长) | state | 下一轮 Step 5 | 温 |

**算法核**:
```
IF (ctx.inc_converged) THEN
  CALL Advance_Time(state, ctx, status)           ! Step 7
  IF (algo.auto_dt) THEN
    state.dt = MIN(state.dt * algo.growth_factor, desc.dt_max)
  END IF
ELSE
  IF (state.n_cutbacks >= desc.max_cutbacks) THEN
    state.step_status = STEP_FAILED; RETURN
  END IF
  CALL Cutback(desc, state, algo, ctx, status)    ! Step 8
END IF
```

**前置条件**: NR_Increment 已执行 (Step 12)
**后置保证**: 若收敛则 time_current 推进；若不收敛则 dt 缩小或 step 失败
**Phase**: Increment
**复杂度**: O(1)
**过程**: `RT_StepDriver_End_Increment`

---

### Step 7: Advance_Time — 时间推进

**设计意图**: 增量收敛后，将 time_current 推进 dt_trial。这是状态不可逆的提交点。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| ctx.dt_trial | ctx | Step 5 | 热 |
| state.time_current | state | Step 3 或上一轮 Step 7 | 温 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| state.time_current (+=dt_trial) | state | Step 9, 10, 下一轮 Step 5 | 温 |

**算法核**:
```
state.time_current = state.time_current + ctx.dt_trial
```

**前置条件**: ctx.inc_converged = .TRUE.
**后置保证**: state.time_current = old_time + dt_trial, time_current ≤ desc.time_end + eps
**Phase**: Increment
**复杂度**: O(1)
**过程**: `RT_StepDriver_Advance_Time`

---

### Step 8: Cutback — 切回/重试

**设计意图**: 增量不收敛时，缩小时间步长，回退状态到增量开始时刻，准备重试。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| algo.cutback_factor | algo | Step 1 (Populate) | 冷 |
| state.dt | state | Step 3 或上一轮 Step 6 | 温 |
| ctx.time_at_inc_start | ctx | Step 5 | 热 |
| desc.dt_min | desc | Step 1 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| state.dt (*= cutback_factor) | state | 下一轮 Step 5 | 温 |
| state.n_cutbacks (+1) | state | Step 6 (max_cutbacks 检查) | 温 |
| state.time_current (回退) | state | 下一轮 Step 5 | 温 |

**算法核**:
```
state.dt = state.dt * algo.cutback_factor
IF (state.dt < desc.dt_min) state.dt = desc.dt_min
state.n_cutbacks = state.n_cutbacks + 1
state.time_current = ctx.time_at_inc_start     ! 回退到增量开始时刻
! 外部还需调用 RT_Material_Restore_State 回退材料态
```

**前置条件**: ctx.inc_converged = .FALSE., n_cutbacks < max_cutbacks
**后置保证**: state.dt 已缩小，time_current 已回退，n_cutbacks 已递增
**Phase**: Increment
**复杂度**: O(1)
**过程**: `RT_StepDriver_Cutback`

---

### Step 9: Check_Step_Complete — 步完成检查

**设计意图**: 判断当前步是否已到达 time_end（容差内）。控制增量循环的终止条件。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| state.time_current | state | Step 7 | 温 |
| desc.time_end | desc | Step 1 (Populate) | 冷 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| is_complete (LOGICAL) | 返回值 | Step 13 (Run_Step) 循环条件 | 温 |

**算法核**:
```
is_complete = (state.time_current >= desc.time_end - eps_tol)
```

**前置条件**: state.time_current 已更新
**后置保证**: 返回值正确反映 time_current vs time_end
**Phase**: Step
**复杂度**: O(1)
**过程**: `RT_StepDriver_Check_Step_Complete`

---

### Step 10–11: Get_Current_Time / Get_DT — 查询接口

**设计意图**: 只读访问器，供外部域（LoadBC 幅值求值、Output 时间戳）查询当前时间和 dt。

**消费 [IN]**: `state.time_current` 或 `state.dt`
**生产 [OUT]**: 返回值 REAL(wp)
**算法核**: `result = state.time_current` / `result = state.dt`
**Phase**: (any)
**复杂度**: O(1)
**过程**: `RT_StepDriver_Get_Current_Time` / `RT_StepDriver_Get_DT`

---

### Step 12: NR_Increment — Newton-Raphson 迭代循环

**设计意图**: 增量级核心——执行 Newton-Raphson 迭代直到收敛或达最大迭代数。这是编排域的**主热路径**，在此调用 L5 Assembly + L2 Solver。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| n_dof | 形参 | L5_RT/Assembly 提供 | 冷 |
| u(:), du(:) | 形参 | 外部位移场 | 热 |
| nr_tol | 形参 | L6/Algo 配置 | 冷 |
| nr_maxiter | 形参 | L6/Algo 配置 | 冷 |
| callbacks | 形参 | L5 Assembly+Solve 回调 | — |
| ctx.dt_trial | ctx | Step 5 | 热 |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| ctx.inc_converged | ctx | Step 6 (End_Increment) | 热 |
| ctx.inc_iters | ctx | 外部日志 | 热 |
| u(:) (updated) | 形参 | 外部 (L5_RT/WriteBack) | 热 |
| du(:) (converged) | 形参 | 外部 | 热 |

**算法核**:
```
DO iter = 1, nr_maxiter
  ! 1. 装配 K, F（通过 callback → RT_Assembly）
  CALL callbacks%assemble(u, K, F, status)
  ! 2. 求解 K * du = -R（通过 callback → RT_Solver → NM_Solver）
  CALL callbacks%solve(K, F, du, status)
  ! 3. 更新 u = u + du
  u = u + du
  ! 4. 收敛检查
  rnorm = NORM2(F)
  IF (rnorm < nr_tol) THEN
    ctx.inc_converged = .TRUE.; ctx.inc_iters = iter; RETURN
  END IF
END DO
ctx.inc_converged = .FALSE.; ctx.inc_iters = nr_maxiter
```

**前置条件**: Step 5 已完成，u(:) 已初始化
**后置保证**: ctx.inc_converged 标志正确，u(:) 为最新迭代解
**Phase**: Iteration (HOT_PATH)
**复杂度**: O(nr_maxiter × n_dof) — 每迭代含 Assembly O(n_elem) + Solve O(nnz)
**过程**: `RT_StepDriver_NR_Increment`

---

### Step 13: Run_Step — 完整步驱动

**设计意图**: 顶层编排入口——组合 Begin_Step → 增量循环 { Begin_Inc → NR → End_Inc } → End_Step。

**消费 [IN]**:
| 数据 | 来源 TYPE.field | 生产者 | 温度 |
|------|----------------|--------|------|
| (同 Step 3–12 所有输入) | — | — | — |

**生产 [OUT]**:
| 数据 | 目标 TYPE.field | 消费者 | 温度 |
|------|----------------|--------|------|
| state.step_status | state | 外部 (L6_AP/Job) | 温 |
| u(:) 最终收敛解 | 形参 | 外部 (WriteBack, Output) | 温 |

**算法核**:
```
CALL Begin_Step(desc, state, ctx, status)
DO WHILE (.NOT. Check_Step_Complete(desc, state))
  IF (state.inc_num >= desc.max_inc) THEN step_status = FAILED; EXIT
  CALL Begin_Increment(desc, state, ctx, status)
  CALL NR_Increment(desc, state, algo, ctx, n_dof, u, du, callbacks, ...)
  CALL End_Increment(desc, state, algo, ctx, ctx.inc_converged, status)
  IF (state.step_status == STEP_FAILED) EXIT
END DO
IF (state.step_status /= STEP_FAILED) CALL End_Step(state, status)
```

**前置条件**: Step 0, 1 完成
**后置保证**: step_status ∈ {COMPLETED, FAILED}
**Phase**: Step (HOT_PATH)
**复杂度**: O(n_inc × n_iter × n_dof)
**过程**: `RT_StepDriver_Run_Step`

---

## 四、闭合性验证矩阵

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| desc.time_start/end | Step 1 (Populate) | Step 3, 5, 9 | ✓ |
| desc.dt_init/min/max | Step 1 (Populate) | Step 3, 5, 8 | ✓ |
| desc.max_inc/max_cutbacks | Step 1 (Populate) | Step 5, 6 | ✓ |
| algo.cutback/growth_factor | Step 1 (Populate) | Step 6, 8 | ✓ |
| algo.auto_dt | Step 1 (Populate) | Step 6 | ✓ |
| state.time_current | Step 3→Step 7 递进 | Step 5, 9, 10 | ✓ |
| state.dt | Step 3→Step 6/8 演化 | Step 5, 11 | ✓ |
| state.inc_num | Step 3→Step 5 递增 | Step 5, 13 | ✓ |
| state.n_cutbacks | Step 3→Step 8 递增 | Step 6 | ✓ |
| state.step_status | Step 3→Step 4 | Step 4, 9, 13 | ✓ |
| ctx.dt_trial | Step 5 | Step 7, 12 | ✓ |
| ctx.time_at_inc_start | Step 5 | Step 8 | ✓ |
| ctx.inc_converged | Step 12 | Step 6 | ✓ |
| ctx.inc_iters | Step 12 | 外部日志 | ✓ |
| u(:) | 外部初始/Step 12 | Step 12, 外部 | ✓ |

**结论**: 15 数据项全部闭合。

---

## 五、状态机视图

```
          ┌──────────────────────────────────────────────┐
          │               Run_Step (S13)                 │
          │  ┌─────────┐                    ┌──────────┐ │
   ──────→│  │Begin_Step│──────────────────→│ End_Step │──────→
          │  │  (S3)    │                    │   (S4)   │ │
          │  └────┬─────┘                    └────▲─────┘ │
          │       ↓                               │       │
          │  ┌────────────── INC LOOP ───────────┐│       │
          │  │  ┌───────────┐                    ││       │
          │  │  │Begin_Inc  │                    ││       │
          │  │  │   (S5)    │                    ││       │
          │  │  └─────┬─────┘                    ││       │
          │  │        ↓                          ││       │
          │  │  ┌───────────┐                    ││       │
          │  │  │NR_Increment│                   ││       │
          │  │  │   (S12)    │                   ││       │
          │  │  └─────┬─────┘                    ││       │
          │  │        ↓                          ││       │
          │  │  ┌───────────┐   converged?       ││       │
          │  │  │End_Inc(S6)│───┬─ YES ──→ Adv(S7)──→Check(S9)─┤
          │  │  └───────────┘   │                ││       │
          │  │                  └─ NO ──→ Cutback(S8)──→↑ │
          │  └───────────────────────────────────┘│       │
          └──────────────────────────────────────────────┘
```
