# 战术四：AI遥测探针与热切换微内核钩子 (天眼)

> **文档位置**：`docs/05_Project_Planning/PPLAN/13_架构护城河合击战术/04_Tactic_AI_Telemetry_Hooks_智能化接管战术.md`

## 1. 战术意图

我们反复强调 UFC 是一个 **“AI-Ready”** 的内核。如果只是让 AI 帮我们写代码，那太低级了。真正的 AI-Ready 是在软件运行时，能够让外部大模型或 Python 代理（Agent）**感知计算状态，并动态干预求解轨迹**（例如遭遇强软化爆炸时，AI 决策切换到 L-BFGS 或弧长法）。这就是 UFC 的“天眼”。

## 2. 核心武器一：运行时遥测总线 (Telemetry Bus)

不能再让求解器只往屏幕终端疯狂打印 `Iteration 1... Residual 1e4`。
- **实施策略**：在 `L5_RT` 的 `StepDriver` 与 `Solver` 之间，安插一个名为 `RT_Telemetry` 的轻量化探针池。
- **收集什么**：
  - 每一步牛顿迭代的能量范数、残差范数收敛速率 ($|R_{i+1}| / |R_i|$).
  - CSR 矩阵的条件数估算（Condition Number Estimation）.
  - 当前由于材料进入塑性（Yielding）导致的刚度骤降比.
- **输出**：通过 `AP_Monitor` 模块（见全域推演矩阵 L6），将这些结构化数值转化为 JSON 或共享内存（Shared Memory），抛给外层监控程序。

## 3. 核心武器二：策略热切换钩子 (Hot-Switch Hooks)

有了遥测，就必须有干预手段。
- **机制**：通过在 `_Ctx` 运行时上下文中预留**“策略函数指针”**或**“干预枚举锁”**。
- 如果 Python 侧（AI 判定）发现牛顿法连续震荡 3 次（典型的病态软化表征），AI 可以通过 `L6_AP` 门面调用 `UFC_Hook_SetStrategy(SOLVER_LBFGS)`。
- 底层 `RT_StepDriver` 在下一个迭代步查到标志位被外部改变，立刻丢弃旧切线矩阵，平滑切换入拟牛顿或 ARC-CW 算法栈。

## 4. 落地路径

1. 设计标准的遥测数据报文格式（Telemetry Schema）。
2. 在 `RT_StepDriver_Run` 的大循环中，硬性植入 `CALL RT_Telemetry_Broadcast(state)`。
3. 提供 C ABI 钩子函数供外部直接阻断执行（Block）、修改时间步（Cut Step）或调参（Tune Parameters）。