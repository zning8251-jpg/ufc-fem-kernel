## Solver 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：Solver / 应用层求解器
- **缩写**：AP_Solver (`AP_Solver_*`)
- **职责**：提供高层求解器接口、求解流程编排、作业生命周期管理、并行控制与资源监控；**委托AP_Job_Core执行实际求解**，不直接实现静力/动力分析算法。
- **架构模式**：**委托架构**（Solver域专注编排，Job域负责执行，L5_RT负责计算）
- **四型配置**：
  - **Desc**：求解器控制参数（OpenMP线程数/内存限制/干运行开关）。
  - **State**：作业阶段、步数统计、三阶段时间统计、峰值内存。
  - **Ctx**：无（通过g_ufc_global%ap_layer%jobCtx访问作业上下文）。
  - **Algo**：三阶段生命周期管理（Pre→Solve→Post）+ 时间统计 + 干运行/数据检查模式。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Lifecycle | Init, Finalize | 求解器域生命周期管理 |
| Orchestration | RunJob | 运行求解作业（委托AP_Job_Core） |
| Parallelism | SetOMPThreads | 设置OpenMP线程数 |
| Query | GetSummary | 查询作业状态/时间/内存 |

- **依赖**：AP_Job_Core（作业执行）、UFC_GlobalContainer_Core（全局容器）。
- **热路径**：**否** — Solver域仅做编排，实际热路径在L5_RT执行。
- **实现锚点**：
  - `AP_Solv_Domain.f90` — 求解器域（230行，2TYPE+3Arg+1Domain+5TBP）
    ```fortran
    ! 作业阶段枚举(6)
    INTEGER(i4), PARAMETER :: AP_JOB_NOT_STARTED = 0_i4
    INTEGER(i4), PARAMETER :: AP_JOB_PREPROCESS  = 1_i4
    INTEGER(i4), PARAMETER :: AP_JOB_SOLVING     = 2_i4
    INTEGER(i4), PARAMETER :: AP_JOB_POSTPROCESS = 3_i4
    INTEGER(i4), PARAMETER :: AP_JOB_COMPLETE    = 4_i4
    INTEGER(i4), PARAMETER :: AP_JOB_FAILED      = 5_i4
    
    TYPE :: AP_Solver_State
      INTEGER(i4) :: jobPhase        = AP_JOB_NOT_STARTED
      INTEGER(i4) :: totalSteps      = 0_i4
      INTEGER(i4) :: completedSteps  = 0_i4
      INTEGER(i4) :: currentStepId   = 0_i4
      INTEGER(i4) :: currentIncrIdx  = 0_i4
      REAL(wp)    :: totalJobTime    = 0.0_wp
      REAL(wp)    :: preProcessTime  = 0.0_wp
      REAL(wp)    :: solveTime       = 0.0_wp
      REAL(wp)    :: postProcessTime = 0.0_wp
      REAL(wp)    :: peakMemoryMB   = 0.0_wp
    END TYPE AP_Solver_State
    
    TYPE :: AP_Solver_Ctrl
      INTEGER(i4) :: nOMPThreads    = 0_i4     ! 0 = env default (OMP_NUM_THREADS)
      REAL(wp)    :: memoryLimitMB  = 0.0_wp   ! 0 = unlimited
      LOGICAL     :: dryRun         = .FALSE.  ! parse only, no solve
      LOGICAL     :: dataCheck      = .FALSE.  ! validate model only
    END TYPE AP_Solver_Ctrl
    
    ! RunJob三阶段实现
    SUBROUTINE AP_Solver_RunJob_Impl(this, status)
      ! Phase 1: Preprocessing
      CALL CPU_TIME(t_start)
      this%state%jobPhase = AP_JOB_PREPROCESS
      
      ! Dry-run mode: parse only, skip solve
      IF (this%ctrl%dryRun) THEN
        CALL CPU_TIME(t_end)
        this%state%preProcessTime = t_end - t_start
        this%state%jobPhase = AP_JOB_COMPLETE
        status%message = "Dry-run mode: parsing completed, solve skipped"
        RETURN
      END IF
      
      ! Data-check mode: validate model only
      IF (this%ctrl%dataCheck) THEN
        ! TODO: Add model validation logic
        CALL CPU_TIME(t_end)
        this%state%preProcessTime = t_end - t_start
        this%state%jobPhase = AP_JOB_COMPLETE
        RETURN
      END IF
      
      ! Phase 2: Solving (delegate to AP_Job_Core)
      CALL CPU_TIME(t_start)
      this%state%jobPhase = AP_JOB_SOLVING
      
      IF (g_ufc_global%IsReady() .AND. ASSOCIATED(g_ufc_global%ap_layer%jobCtx)) THEN
        CALL AP_Job_Run_Structured(g_ufc_global%ap_layer%jobCtx, run_in, run_out)
        CALL AP_Job_BuildSum_Structured(g_ufc_global%ap_layer%jobCtx, sum_in, sum_out)
        ! Sync summary to solver state
        this%state%completedSteps = sum_out%summary%nStepsCompleted
        this%state%totalSteps     = sum_out%summary%nStepsTotal
      END IF
      CALL CPU_TIME(t_end)
      this%state%solveTime = t_end - t_start
      
      ! Phase 3: Postprocessing
      CALL CPU_TIME(t_start)
      this%state%jobPhase = AP_JOB_POSTPROCESS
      ! TODO: Write output files, generate reports
      CALL CPU_TIME(t_end)
      this%state%postProcessTime = t_end - t_start
      
      ! Finalize
      this%state%totalJobTime = preProcessTime + solveTime + postProcessTime
      this%state%peakMemoryMB = 0.0_wp  ! TODO: Integrate memory monitoring
    END SUBROUTINE AP_Solver_RunJob_Impl
    ```

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_SOLVER_xxx`（60700–60799） |
| 严重级 | Warning / Error / Fatal（求解发散为 Error，全局容器未初始化为 Fatal） |
| 传播规则 | 求解编排错误附加阶段（Pre/Solve/Post）上下文后传播至 Job |
| 恢复策略 | 干运行/数据检查模式安全返回；求解失败标记 AP_JOB_FAILED + 释放资源 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L5_RT/StepDriver | B(桥接) | 桥接至 L5 StepDriver 驱动实际求解步 |
| 2 | L5_RT/Solver | B(桥接) | 桥接至 L5 NR 求解器执行非线性迭代 |
| 3 | L6_AP/Config | S(消费) | 消费 Config 提供的求解器控制参数 |
| 4 | L6_AP/Job | S(消费) | 消费 Job 提供的作业上下文（jobCtx） |
| 5 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_Error） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 三阶段生命周期顺序（Pre→Solve→Post） | 硬约束 | 状态机断言 | CI |
| g_ufc_global 初始化后才可调用 RunJob | 硬约束 | 运行时检查 | CI |
| 委托 AP_Job_Core 而非直接调用 L5 | 硬约束 | 代码审查 | PR 合入 |
| 时间统计精度（CPU_TIME） | 软约束 | 集成测试 | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | AP_Solver_Ctrl | 求解器控制参数（线程/内存/干运行） |
| 2 | State | AP_Solver_State | 作业阶段/步数/时间/内存统计 |
| 3 | Algo | RunJob 三阶段 | Pre→Solve→Post 生命周期管理 |
| 4 | Ctx | 无（通过 g_ufc_global 访问） | 全局容器中的 jobCtx |
| 5 | Arg (SIO) | 无 | 编排层不在热路径 |
| 6 | Proc | AP_Solv_Domain.f90 | 求解器域模块（230 行） |
| 7 | Test | Solver 单元测试 | 状态机 + 干运行模式 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无（消费 AP_Config） | 控制参数来自 Config 域 |
| 10 | Error | ERR_L6_SOLVER_xxx | 60700–60799 |
| 11 | Domain | AP_Solver 域 | L6_AP/Solver/ |
| 12 | Registry | 无 | 不注册为服务 |
| 13 | Doc | 本合同 + 委托架构说明 | 三阶段生命周期与委托模式 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 求解器编排理论→三阶段生命周期→委托架构（Solver 编排 / Job 执行 / L5 计算） |
| **逻辑链** | RunJob→Pre(parse)→Solve(委托 AP_Job_Core→L5_RT)→Post(输出)→Complete |
| **计算链** | 无直接计算；Solver 域仅做编排，实际计算在 L5_RT |
| **数据链** | AP_Solver_Ctrl→AP_Solver_State→Job summary 同步 |

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v2.0（2026-04-13，对齐实际委托架构）  
**最后更新**：2026-04-13  
**状态**：✅ 已对齐实际实现


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `AP_Solv_Domain.f90` | `AP_SolvDomain` | `AP_Solver_State`, `AP_Solver_Ctrl`, `AP_Solver_RunJob_Arg`, `AP_Solver_SetOMPThreads_Arg`, `AP_Solver_GetSummary_Arg`, `AP_Solver_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `RunJob` (TBP,PRV,—); `SetOMPThreads` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AP_Solver_Domain_Finalize` (SUB,PRV,Finalize); `AP_Solver_Domain_Init` (SUB,PRV,Init); `AP_Solver_Domain_RunJob` (SUB,PRV,Compute); `AP_Solver_RunJob_Impl` (SUB,PRV,Compute); `AP_Solver_Domain_SetOMPThreads` (SUB,PRV,Compute); `AP_Solver_SetOMPThreads_Impl` (SUB,PRV,Compute); `AP_Solver_Domain_GetSummary` (SUB,PRV,Compute); `AP_Solver_GetSummary_Impl` (SUB,PRV,Compute) |
