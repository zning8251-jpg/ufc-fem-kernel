## Job 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：Job / 作业调度与管理
- **缩写**：AP_Job (`AP_Job_*`)
- **职责**：提供求解作业定义、任务队列管理、并行资源分配；支持批量提交、优先级调度与断点续算。
- **四型配置**：
  - **Desc**：作业 TYPE、任务队列结构、资源描述符。
  - **State**：当前作业状态（排队/运行/完成）、CPU/内存使用率。
  - **Ctx**：无。
  - **Algo**：优先级队列、负载均衡、检查点保存/恢复。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Submit | Job_Create, Job_Submit, Job_Cancel | 作业提交 |
| Queue | Queue_Add, Queue_Remove, Queue_Peek | 队列管理 |
| Schedule | Schedule_FIFO, Schedule_Priority | 调度策略 |
| Checkpoint | Save_Checkpoint, Load_Checkpoint | 断点续算 |

- **依赖**：IF_Error（错误处理）、RT_Task（任务管理）。
- **热路径**：**否** — 作业调度在宏观时间尺度。
- **实现锚点**：
  - `AP_Job_Types.f90` — 作业 TYPE 定义
    ```fortran
    TYPE :: ComputeJob
      CHARACTER(:), ALLOCATABLE :: job_id
      CHARACTER(:), ALLOCATABLE :: job_name
      INTEGER(i4) :: priority = 0_i4       ! 优先级（0=最低）
      INTEGER(i4) :: status                ! 1=PENDING, 2=RUNNING, 3=DONE, 4=FAILED
      INTEGER(i4) :: num_cpus_requested = 1_i4
      INTEGER(i8) :: memory_requested = 0_i8  ! 字节
      CHARACTER(:), ALLOCATABLE :: input_file
      REAL(wp) :: submit_time
      REAL(wp) :: start_time
      REAL(wp) :: end_time
    END TYPE ComputeJob
    
    TYPE :: JobQueue
      TYPE(ComputeJob), ALLOCATABLE :: jobs(:)
      INTEGER(i4) :: head = 1_i4
      INTEGER(i4) :: tail = 1_i4
      INTEGER(i4) :: capacity = 100_i4
      INTEGER(i4) :: running_count = 0_i4
      INTEGER(i4) :: max_concurrent = 4_i4  ! 最大并发数
    END TYPE JobQueue
    ```
  - `AP_Job_Submit.f90` — 作业提交
    ```fortran
    SUBROUTINE Job_Submit(queue, job, job_id)
      TYPE(JobQueue), INTENT(INOUT) :: queue
      TYPE(ComputeJob), INTENT(INOUT) :: job
      CHARACTER(len=*), INTENT(OUT) :: job_id
      
      ! 伪代码：
      ! 1. 生成唯一 ID（时间戳 + 随机数）
      ! 2. 设置状态为 PENDING
      ! 3. 加入队列尾部
      
      job_id = generate_unique_job_id()
      job%job_id = job_id
      job%status = 1  ! PENDING
      job%submit_time = get_current_time()
      
      ! 扩容检查
      IF (queue%tail >= queue%capacity) &
        CALL Reallocate_Queue(queue)
      
      ! 入队
      queue%jobs(queue%tail) = job
      queue%tail = queue%tail + 1
    END SUBROUTINE Job_Submit
    
    FUNCTION Schedule_Next(queue) RESULT(job_ptr)
      TYPE(JobQueue), INTENT(INOUT) :: queue
      TYPE(ComputeJob), POINTER :: job_ptr
      
      ! 伪代码：优先级调度
      ! 1. 扫描队列，找到最高优先级作业
      ! 2. 若 CPU 资源足够，设置为 RUNNING
      ! 3. 返回指针（若无可用作业，返回 NULL）
      
      best_idx = -1
      best_priority = -1
      
      DO i = queue%head, queue%tail - 1
        IF (queue%jobs(i)%status == 1 .AND. &  ! PENDING
            queue%jobs(i)%priority > best_priority) THEN
          ! 检查资源
          IF (available_cpus >= queue%jobs(i)%num_cpus_requested) THEN
            best_idx = i
            best_priority = queue%jobs(i)%priority
          END IF
        END IF
      END DO
      
      IF (best_idx > 0) THEN
        job_ptr => queue%jobs(best_idx)
        job_ptr%status = 2  ! RUNNING
        job_ptr%start_time = get_current_time()
        queue%running_count = queue%running_count + 1
        
        ! 更新资源计数
        available_cpus = available_cpus - job_ptr%num_cpus_requested
      ELSE
        NULLIFY(job_ptr)
      END IF
    END FUNCTION Schedule_Next
    ```
  - `AP_Job_Checkpoint.f90` — 断点续算
    ```fortran
    SUBROUTINE Save_Checkpoint(job, state, file_path)
      TYPE(ComputeJob), INTENT(IN) :: job
      TYPE(SolverState), INTENT(IN) :: state
      CHARACTER(len=*), INTENT(IN) :: file_path
      
      ! 伪代码：保存求解器状态到文件
      ! OPEN(unit=20, file=file_path, form='unformatted')
      ! WRITE(20) job%job_id
      ! WRITE(20) state%time_step
      ! WRITE(20) state%displacements
      ! WRITE(20) state%velocities
      ! WRITE(20) state%accelerations
      ! CLOSE(20)
    END SUBROUTINE Save_Checkpoint
    
    SUBROUTINE Load_Checkpoint(job, state, file_path)
      ! 伪代码：从检查点恢复
      ! OPEN(unit=20, file=file_path, form='unformatted')
      ! READ(20) job_id_check
      ! READ(20) state%time_step
      ! READ(20) state%displacements
      ! ...
      ! CLOSE(20)
    END SUBROUTINE Load_Checkpoint
    ```
  - `AP_Job_Monitor.f90` — 作业监控

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_JOB_xxx`（60400–60499） |
| 严重级 | Warning / Error / Fatal（资源不足为 Error，作业崩溃为 Fatal） |
| 传播规则 | 作业执行错误附加 job_id 上下文后传播至上层调度器或用户 |
| 恢复策略 | 可恢复错误尝试检查点续算；不可恢复标记 FAILED + 释放资源 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L6_AP/Config | S(消费) | 消费 Config 提供的作业参数与资源限制 |
| 2 | L6_AP/Input | T(合同) | 正式依赖 Input 提供已解析的模型数据 |
| 3 | L6_AP/Output | T(合同) | 正式依赖 Output 执行结果写入 |
| 4 | L5_RT/StepDriver | B(桥接) | 桥接至 L5 StepDriver 执行实际求解步 |
| 5 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_Error） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 作业 ID 全局唯一 | 硬约束 | 运行时断言 | CI |
| 作业状态机转换合法（PENDING→RUNNING→DONE/FAILED） | 硬约束 | 单元测试 | CI |
| 检查点文件格式向后兼容 | 硬约束 | 版本化测试 | PR 合入 |
| 并发数不超过 max_concurrent | 软约束 | 集成测试 | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | ComputeJob | 作业描述（ID/名称/优先级/资源需求） |
| 2 | State | JobQueue + job%status | 队列状态与作业运行状态 |
| 3 | Algo | Schedule_FIFO / Schedule_Priority | 调度算法与检查点保存/恢复 |
| 4 | Ctx | 无 | 通过 g_ufc_global%ap_layer%jobCtx 访问 |
| 5 | Arg (SIO) | 无 | 作业管理不在热路径 |
| 6 | Proc | AP_Job_Submit/Checkpoint/Monitor.f90 | 作业管理过程模块 |
| 7 | Test | Job 单元测试 | 状态机转换 + 调度正确性 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无（消费 AP_Config） | 作业参数来自 Config 域 |
| 10 | Error | ERR_L6_JOB_xxx | 60400–60499 |
| 11 | Domain | AP_Job 域 | L6_AP/Job/ |
| 12 | Registry | 无 | 不注册为服务 |
| 13 | Doc | 本合同 + 作业生命周期说明 | 状态机与调度策略 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 作业调度理论→优先级队列→资源约束→检查点续算 |
| **逻辑链** | Job_Create→Job_Submit→Schedule→L5_RT StepDriver 执行→Complete/Fail |
| **计算链** | 无直接计算；Job 编排 L5_RT 执行实际求解 |
| **数据链** | ComputeJob 生命周期：Create→Queue→Run→Checkpoint→Complete |

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `AP_Job.f90` | `AP_Job` | `AP_Job_Opts`, `JobOpts`, `AP_Job_Summary`, `JobSummary`, `AP_Job_Ctx`, `JobCtx`, `AP_Job_InitDesc_In`, `AP_Job_InitDesc_Out`, `AP_Job_AttachMod_In`, `AP_Job_AttachMod_Out`, `AP_Job_AddStep_In`, `AP_Job_AddStep_Out`, `AP_Job_BindCtx_In`, `AP_Job_BindCtx_Out`, `AP_Job_SetOpts_In`, `AP_Job_SetOpts_Out`, `AP_Job_PrepEnv_In`, `AP_Job_PrepEnv_Out`, `AP_Job_Run_In`, `AP_Job_Run_Out`, `AP_Job_RunNext_In`, `AP_Job_RunNext_Out`, `AP_Job_SaveChk_In`, `AP_Job_SaveChk_Out`, `AP_Job_LoadChk_In`, `AP_Job_LoadChk_Out`, `AP_Job_TryRestart_In`, `AP_Job_TryRestart_Out`, `AP_Job_HandleFail_In`, `AP_Job_HandleFail_Out`, `AP_Job_Final_In`, `AP_Job_Final_Out`, `AP_Job_BuildSum_In`, `AP_Job_BuildSum_Out`, `AP_Job_QueryStat_In`, `AP_Job_QueryStat_Out`, `AP_Job_Unified_OptionsDefault_In`, `AP_Job_Unified_OptionsDefault_Out`, `AP_Job_Unified_OptionsValidate_In`, `AP_Job_Unified_OptionsValidate_Out`, `AP_Job_Unified_Cfg_In`, `AP_Job_Unified_Cfg_Out`, `AP_Job_Unified_Checkpoint_In`, `AP_Job_Unified_Checkpoint_Out`, `AP_Job_Unified_Execute_In`, `AP_Job_Unified_Execute_Out`, `AP_Job_Unified_Query_In`, `AP_Job_Unified_Query_Out`, `AP_Job_Unified_StatusReport_In`, `AP_Job_Unified_StatusReport_Out` | `AP_Job_StepRunner_Ifc` (SUB,PRV,—); `UF_Job_StepRunner_Ifc` (SUB,PRV,—); `StepRunner` (TBP,PRV,—); `StepRunner` (TBP,PRV,—); `stepRunner` (TBP,PRV,—); `step_runner` (TBP,PRV,—); `AP_Job_InitDesc_Structured` (SUB,PUB,Init); `AP_Job_AttachMod_Structured` (SUB,PUB,—); `AP_Job_AddStep_Structured` (SUB,PUB,Mutate); `AP_Job_BindCtx_Structured` (SUB,PUB,—); `AP_Job_SetOpts_Structured` (SUB,PUB,Mutate); `AP_Job_PrepEnv_Structured` (SUB,PUB,—); `AP_Job_Run_Structured` (SUB,PUB,—); `AP_Job_RunNext_Structured` (SUB,PUB,—); `AP_Job_SaveChk_Structured` (SUB,PUB,—); `AP_Job_LoadChk_Structured` (SUB,PUB,Parse); `AP_Job_TryRestart_Structured` (SUB,PUB,—); `AP_Job_HandleFail_Structured` (SUB,PUB,—); `AP_Job_Final_Structured` (SUB,PUB,—); `AP_Job_BuildSum_Structured` (SUB,PUB,Populate); `AP_Job_QueryStat_Structured` (SUB,PUB,Query); `AP_Job_Unified_OptionsDefault_Structured` (SUB,PUB,—); `AP_Job_Unified_OptionsValidate_Structured` (SUB,PUB,—); `AP_Job_Unified_Cfg_Structured` (SUB,PUB,—); `AP_Job_Unified_Checkpoint_Structured` (SUB,PUB,Validate); `AP_Job_Unified_Execute_Structured` (SUB,PUB,—); `AP_Job_Unified_Query_Structured` (SUB,PUB,Query); `AP_Job_Unified_StatusReport_Structured` (SUB,PUB,—); `AP_Job_AddStep` (SUB,PUB,Mutate); `AP_Job_AttachMod` (SUB,PUB,—); `AP_Job_BindCtx` (SUB,PUB,—); `AP_Job_BuildSum` (SUB,PUB,Populate); `AP_Job_Final` (SUB,PUB,—); `AP_Job_HandleFail` (SUB,PUB,—); `AP_Job_InitDesc` (SUB,PUB,Init); `AP_Job_LoadChk` (SUB,PUB,Parse); `AP_Job_PrepEnv` (SUB,PUB,—); `AP_Job_QueryStat` (SUB,PUB,Query); `AP_Job_Run` (SUB,PUB,—); `AP_Job_RunNext` (SUB,PUB,—); `AP_Job_SaveChk` (SUB,PUB,—); `AP_Job_SetOpts` (SUB,PUB,Mutate); `AP_Job_TryRestart` (SUB,PUB,—); `AP_Job_Un_OptionsDefault` (SUB,PRV,—); `AP_Job_Un_OptionsValidate` (SUB,PRV,—); `AP_Job_Unified_Cfg` (SUB,PUB,—); `AP_Job_Unified_Checkpoint` (SUB,PUB,Validate); `AP_Job_Unified_Execute` (SUB,PUB,—); `AP_Job_Unified_Query` (SUB,PUB,Query); `AP_Job_Unified_StatusReport` (SUB,PUB,—); `AP_Job_UnifiedCfg` (SUB,PUB,—); `AP_Job_UnifiedChkpt` (SUB,PUB,—); `AP_Job_UnifiedExecute` (SUB,PUB,—); `AP_Job_UnifiedOptsDef` (SUB,PUB,—); `AP_Job_UnifiedOptsValid` (SUB,PUB,—); `AP_Job_UnifiedQuery` (SUB,PUB,—); `AP_Job_UnifiedStatusReport` (SUB,PUB,—); `RT_Job_AddStep` (SUB,PUB,Mutate); `RT_Job_AttachMod` (SUB,PUB,—); `RT_Job_BindCtx` (SUB,PUB,—); `RT_Job_BuildSum` (SUB,PUB,Populate); `RT_Job_Final` (SUB,PUB,—); `RT_Job_HandleFail` (SUB,PUB,—); `RT_Job_InitDesc` (SUB,PUB,Init); `RT_Job_LoadChk` (SUB,PUB,Parse); `RT_Job_PrepEnv` (SUB,PUB,—); `RT_Job_QueryStat` (SUB,PUB,Query); `RT_Job_Run` (SUB,PUB,—); `RT_Job_RunNext` (SUB,PUB,—); `RT_Job_SaveChk` (SUB,PUB,—); `RT_Job_SetOpts` (SUB,PUB,Mutate); `RT_Job_TryRestart` (SUB,PUB,—) |
| `AP_Job_Domain.f90` | `AP_JobDomain` | `AP_Job_Metrics`, `AP_Job_State`, `AP_Job_Ctrl`, `AP_Job_Run_Arg`, `AP_Job_Pause_Arg`, `AP_Job_Abort_Arg`, `AP_Job_RollbackToStep_Arg`, `AP_Job_RecordResource_Arg`, `AP_Job_GetSummary_Arg`, `AP_JobDomain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `Run` (TBP,PRV,—); `Pause` (TBP,PRV,—); `Abort` (TBP,PRV,—); `RollbackToStep` (TBP,PRV,—); `RecordResource` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AP_Job_Domain_Finalize` (SUB,PRV,Finalize); `AP_Job_Domain_Init` (SUB,PRV,Init); `AP_Job_Domain_Run` (SUB,PRV,—); `AP_Job_Run_Impl` (SUB,PRV,—); `AP_Job_Domain_Pause` (SUB,PRV,—); `AP_Job_Pause_Impl` (SUB,PRV,—); `AP_Job_Domain_Abort` (SUB,PRV,—); `AP_Job_Abort_Impl` (SUB,PRV,—); `AP_Job_Domain_RollbackToStep` (SUB,PRV,—); `AP_Job_RollbackToStep_Impl` (SUB,PRV,—); `AP_Job_Domain_RecordResource` (SUB,PRV,—); `AP_Job_RecordResource_Impl` (SUB,PRV,—); `AP_Job_Domain_GetSummary` (SUB,PRV,Query); `AP_Job_GetSummary_Impl` (SUB,PRV,Query) |
| `AP_Job_Util.f90` | `AP_JobUtil` | — | `AP_Cmd_ExtractName` (FN,PUB,—); `AP_Cmd_ExtractNumericParams` (SUB,PUB,—); `AP_Cmd_ExtractOption` (FN,PUB,—); `AP_Cmd_ExtractStringParams` (FN,PUB,—); `AP_Cmd_FormatCommand` (FN,PUB,—); `AP_Cmd_ParseParameters` (SUB,PUB,Parse); `AP_Cmd_ValidateCommand` (SUB,PUB,Validate); `AP_CmdUtils_Unified_Cfg` (SUB,PUB,—); `AP_CmdUtils_Unified_Execute` (SUB,PUB,—); `AP_File_GetBasename` (FN,PUB,Query); `AP_File_GetExtension` (FN,PUB,Query); `AP_File_JoinPath` (FN,PUB,—); `AP_File_NormalizePath` (FN,PUB,—); `AP_File_IsAbsolutePath` (FN,PUB,Query); `AP_File_ReadLines` (SUB,PUB,Parse); `AP_File_WriteLines` (SUB,PUB,IO); `AP_File_Unified_Cfg` (SUB,PUB,—); `AP_File_Unified_Execute` (SUB,PUB,—) |
| `AP_Job_Ctx.f90` | — | — | — |
