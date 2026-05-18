# Checkpoint/Restart 统一流程

> **版本**: v1.0 | **日期**: 2026-04-26

---

## 一、问题：碎片化现状

| 位置 | 实现 | 状态 |
|------|------|------|
| L6 `AP_Job_SaveChk/LoadChk` | 文本格式 checkpoint | 部分实现 |
| L5 `RT_WB_Impl_Checkpoint` | 占位 stub | 未实现 |
| L3 `MD_RestartData` | 占位 stub | 未实现 |
| L1 `IF_IO_Read_Checkpoint` | 占位 stub | 未实现 |
| L1 `dp_save/dp_load` | 定义存在 | 无调用者 |

**问题**: 各层独立设计 checkpoint 接口但互不调用，无法实现完整的状态保存/恢复。

---

## 二、统一 Checkpoint 写出流

```
L5 StepDriver (每步末或按 STORAGE:CHECKPOINT_INTERVAL 配置)
  |
  +-> [S1] Checkpoint_Conditional 判定
  |     条件: step_complete OR (incr % interval == 0)
  |
  +-> [S2] StorageMgr 快照 WARM 池
  |     - 快照 P3 (WARM_VECTOR): stress_n, u_n, SDV 等
  |     - 快照 P7 (WARM_STRUCT): elem_state 等
  |     - 写入 SpillFile (临时二进制)
  |
  +-> [S3] L3 Model 序列化动态域
  |     - 通过 dp_save 序列化 SymTbl 注册的数据:
  |       MAT:*, NSET:*, ELSET:*, STEP:* 等
  |     - 写入 checkpoint 数据块
  |
  +-> [S4] L5 Solver 状态保存
  |     - Krylov 子空间向量 -> P9 (IO_BUFFER)
  |     - 收敛历史 (residual norms)
  |     - 当前 stepId, incrId, wallClock
  |
  +-> [S5] L1 IO 统一写出
        - 合并 S2-S4 的数据块
        - 写出 checkpoint 文件 (二进制格式)
        - 文件路径: workDir/jobName.chk
```

---

## 三、统一 Restart 恢复流

```
L6 AP_Job_LoadChk (作业启动时检测 .chk 文件)
  |
  +-> [R1] L1 IO 读取 checkpoint 文件
  |     - 解析文件头, 验证版本兼容性
  |     - 按数据块分发到各层
  |
  +-> [R2] StorageMgr 恢复 WARM 池数据
  |     - 从 SpillFile 块恢复 P3/P7 数据
  |     - 重建池元数据 (size, offset, ref_count)
  |
  +-> [R3] L3 Model dp_load 恢复动态域
  |     - 重建 SymTbl 注册 (MAT:*, NSET:* 等)
  |     - 恢复域计数和数据
  |
  +-> [R4] L5 Solver 恢复求解器状态
  |     - 恢复 Krylov 向量
  |     - 恢复 stepId, incrId, wallClock
  |     - 设置 restart 标志
  |
  +-> [R5] 从恢复点继续计算
        - L5 StepDriver 从 saved_stepId/incrId 继续
```

---

## 四、dp_save / dp_load 接入点

### 4.1 dp_save 调用点 (Checkpoint 写出)

```fortran
! 在 L3 Bridge 中 (MD_Model_Brg)
CALL dp_save("checkpoint", "MAT", DP_FORMAT_BINARY, status)
CALL dp_save("checkpoint", "NSET", DP_FORMAT_BINARY, status)
CALL dp_save("checkpoint", "STEP", DP_FORMAT_BINARY, status)
```

### 4.2 dp_load 调用点 (Restart 恢复)

```fortran
! 在 L6 Job Init 中 (AP_BrgL3)
CALL dp_load("checkpoint", "MAT", DP_FORMAT_BINARY, status)
CALL dp_load("checkpoint", "NSET", DP_FORMAT_BINARY, status)
CALL dp_load("checkpoint", "STEP", DP_FORMAT_BINARY, status)
```

---

## 五、跨层协调时序

```
                Checkpoint 写出                    Restart 恢复
                ──────────────                    ────────────
L6_AP           [触发 conditional]                 [检测 .chk -> 启动恢复]
                      |                                  |
L5_RT           [S1: 判定] -> [S4: Solver save]   [R4: Solver restore]
                      |                                  |
L3_MD           [S3: dp_save 动态域]               [R3: dp_load 动态域]
                      |                                  |
L1_IF/Memory    [S2: WARM 池快照]                  [R2: WARM 池恢复]
                      |                                  |
L1_IF/IO        [S5: 统一写出 .chk]               [R1: 读取解析 .chk]
```

---

## 六、错误恢复

| 错误 | 处理 |
|------|------|
| Checkpoint 写出失败 | WARNING + 继续计算（不中断），下次增量重试 |
| Checkpoint 文件损坏 | 提示错误，尝试上一个有效 checkpoint |
| Restart 恢复失败 | FATAL，无法继续，需要用户介入 |
| 版本不兼容 | ERROR + 提示版本信息，建议重新运算 |
