## Monitor 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Monitor / 运行时监控与性能分析
- **缩写**：IF_Monitor (`IF_Monitor_*`)
- **职责**：提供性能计数器、时间测量、资源使用监控；支持性能剖析（profiling）与热点检测。
- **四型配置**：
  - **Desc**：计数器 TYPE、计时器句柄、性能指标结构。
  - **State**：当前计数值、累积时间、采样缓冲区。
  - **Ctx**：无。
  - **Algo**：高分辨率计时、滑动平均统计。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Counter | Counter_Create, Counter_Increment, Counter_Read | 事件计数 |
| Timer | Timer_Start, Timer_Stop, Timer_Elapsed | 高精度计时 |
| Profile | Profile_Begin, Profile_End, Profile_Report | 性能剖析 |
| Resource | Get_Memory_Usage, Get_CPU_Usage | 资源监控 |

- **依赖**：IF_Precision（数据类型）、IF_Log（日志输出）。
- **热路径**：**是** — 性能计数器在热路径中频繁调用。
- **实现锚点**：
  - `IF_Monitor_Types.f90` — 监控 TYPE 定义
    ```fortran
    TYPE :: PerformanceCounter
      CHARACTER(:), ALLOCATABLE :: name
      INTEGER(i8) :: count = 0_i8
      REAL(wp) :: accum_time = 0.0_wp
      INTEGER(i8) :: calls = 0_i8
    END TYPE PerformanceCounter
    
    TYPE :: HighResTimer
      INTEGER(i8) :: start_count
      INTEGER(i8) :: end_count
      INTEGER(i8) :: frequency
      REAL(wp) :: elapsed_seconds
    END TYPE HighResTimer
    ```
  - `IF_Monitor_Timer.f90` — 高精度计时
    ```fortran
    SUBROUTINE Timer_Start(timer)
      TYPE(HighResTimer), INTENT(OUT) :: timer
      
      ! 伪代码：读取 CPU 周期计数器
      ! 使用 SYSTEM_CLOCK 或 QueryPerformanceCounter
      CALL SYSTEM_CLOCK(count=timer%start_count, &
                       rate=timer%frequency)
    END SUBROUTINE Timer_Start
    
    FUNCTION Timer_Elapsed(timer) RESULT(seconds)
      TYPE(HighResTimer), INTENT(INOUT) :: timer
      REAL(wp) :: seconds
      
      ! 伪代码：计算经过时间
      ! seconds = (end_count - start_count) / frequency
      CALL SYSTEM_CLOCK(count=timer%end_count)
      seconds = REAL(timer%end_count - timer%start_count, wp) / &
                REAL(timer%frequency, wp)
      timer%elapsed_seconds = seconds
    END FUNCTION Timer_Elapsed
    ```
  - `IF_Monitor_Profile.f90` — 性能剖析
    ```fortran
    SUBROUTINE Profile_Begin(profile_name)
      CHARACTER(len=*), INTENT(IN) :: profile_name
      
      ! 伪代码：
      ! 1. 查找或创建性能计数器
      ! 2. 开始计时
      ! 3. 推入调用栈
      idx = find_or_create_counter(profile_name)
      counters(idx)%calls = counters(idx)%calls + 1
      CALL Timer_Start(counters(idx)%timer)
      CALL push_stack(idx)
    END SUBROUTINE Profile_Begin
    
    SUBROUTINE Profile_End()
      ! 伪代码：
      ! 1. 弹出栈顶索引
      ! 2. 停止计时并累加
      ! 3. 更新统计
      idx = pop_stack()
      CALL Timer_Stop(counters(idx)%timer)
      counters(idx)%accum_time = &
        counters(idx)%accum_time + counters(idx)%timer%elapsed
    END SUBROUTINE Profile_End
    
    SUBROUTINE Profile_Report()
      ! 伪代码：输出性能报告
      ! DO i = 1, counter_count
      !   avg_time = counters(i)%accum_time / counters(i)%calls
      !   WRITE(*,'(A,F12.6,A,I8)') counters(i)%name, &
      !         avg_time, ' ms (', counters(i)%calls, ' calls)'
      ! END DO
    END SUBROUTINE Profile_Report
    ```
  - `IF_Monitor_Resource.f90` — 资源监控

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L1_MONITOR_xxx` (10600–10699) |
| 严重级 | WARNING: 计数器溢出(可重置); ERROR: 计时器精度不足; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 重置计数器; ERROR：禁用该计数器 + 上报 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L2_NM/* | S(消费) | 数值方法层性能监控 |
| R2 | L3_MD/* | S(消费) | 模型数据层性能监控 |
| R3 | L4_PH/* | S(消费) | 有限元组件层性能监控 |
| R4 | L5_RT/* | S(消费) | 运行时层性能监控 |
| R5 | L6_AP/* | S(消费) | 应用层性能监控 |
| R6 | L1_IF/Error | U(USE) | 错误码定义 |
| R7 | L1_IF/Log | T(合同) | 性能报告输出 |
| R8 | L1_IF/Precision | U(USE) | 计时精度 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| Timer Start/Stop 须轻量(热路径可调用) | 硬 | Code Review | — |
| 性能报告须可禁用(Release 模式) | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | PerformanceCounter / HighResTimer TYPE | 监控指标描述 |
| 2 | State 定义 | 计数值 / 累积时间 / 采样缓冲区 | 运行时监控状态 |
| 3 | Algo 定义 | 高分辨率计时 / 滑动平均 | 统计算法 |
| 4 | Ctx 定义 | N/A | 无上下文 |
| 5 | Init/Finalize | Counter_Create / Profile_Report | 监控生命周期 |
| 6 | Query | Counter_Read / Timer_Elapsed | 性能数据查询 |
| 7 | Validate | 计数器溢出检查 | 内嵌 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | N/A | 最底层无桥接 |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 非计算域 |
| 13 | Error | status 参数返回 | 见错误处理 |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——性能监控基础设施 |
| 逻辑链 | Counter/Timer/Profile 三级监控，全层统一入口 |
| 计算链 | Timer Start/Stop 轻量调用可嵌入热路径 |
| 数据链 | 计数器累积 → Profile_Report 汇总输出 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Mon.f90` | `IF_Mon` | `IF_Monitor_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `IF_Monitor_GetDomain` (FN,PUB,Query); `IF_Monitor_Domain_Init` (SUB,PRV,Init); `IF_Monitor_Domain_Finalize` (SUB,PRV,Finalize); `Monitor_Init` (SUB,PUB,Init); `Monitor_Finalize` (SUB,PUB,Finalize); `CollectMetrics` (SUB,PUB,—); `RecordTrace` (SUB,PUB,—); `ExportTrace` (SUB,PUB,—); `StartSpan` (SUB,PUB,—); `EndSpan` (SUB,PUB,—); `ChainMonitor_Init` (SUB,PUB,Init); `ChainMonitor_Record` (SUB,PUB,—); `ChainMonitor_Report` (SUB,PUB,IO) |
| `IF_Mon_Mgr.f90` | `IF_Mon_Mgr` | — | `IF_Monitor_Mgr_GetLogState` (SUB,PUB,Query); `IF_Monitor_Mgr_Validate` (SUB,PUB,Validate) |
| `IF_Mon_Def.f90` | `IF_Mon_Def` | `LogState`, `MetricsState`, `TraceState`, `MonitorDesc`, `MonitorCtx`, `MonitorState` | — |
| `IF_Mon_Mgr.f90` | `IF_Mon_Mgr` | — | `IF_Monitor_Mgr_GetLogState` (SUB,PUB,Query); `IF_Monitor_Mgr_Validate` (SUB,PUB,Validate) |
