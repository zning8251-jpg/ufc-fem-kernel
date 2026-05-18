# Output 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: Output (结果输出管理)  
**Prefix**: `RT_Out_*`, `RT_Writer_*`  
**Version**: v1.1  
**Created**: 2026-04-28  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 Output 域，运行时结果输出编排与文件写入
- **职责**:
  - 场输出 (Field Output): 节点/单元/积分点变量按增量步写入
  - 历史输出 (History Output): 特定位置时间序列数据记录
  - Restart 输出: 重启文件序列化/反序列化，支持作业续算
  - 多格式写入: VTK / HDF5 / ODB 格式适配
  - 输出频率触发: 按增量步/时间/步末/分析末触发
  - 缓冲式 I/O: 批量写入以最小化系统调用

### 非职责
- 不定义输出变量语义（L3 `MD_Output` 定义输出请求 schema）
- 不执行坐标/张量变换（L4 `PH_Out` 域处理物理层变换）
- 不执行求解计算（L5 Solver/Assembly 产出结果）
- 不管理运行时状态更新（WriteBack 域负责）

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Out_Base_Desc` | `RT_Out_Def` | runtime_id, output_label, md_registry(PTR), field_req(PTR), hist_req(PTR), output_format, output_directory, file_prefix, is_active, is_initialized | 运行时输出描述符，聚合 L3 输出请求与运行时元数据。Populate 后只读 |

### 2.2 State

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Out_FieldState` | `RT_Out_Def` | n_frames_written, ... | 场输出执行状态，跟踪帧写入进度 |
| `RT_Out_HistState` | `RT_Out_Def` | ... | 历史输出执行状态 |

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Out_Stp_Ctl_Algo` | `RT_Out_Aux_Def` | field_freq_incr, field_freq_time, hist_freq_incr, hist_freq_time, trigger_type, trigger_at_step_end, trigger_at_analysis_end, force_field_write, force_hist_write, suppress_all_output | 步级输出频率/触发控制（P1 补全，[Phase:Stp|Verb:Ctl]） |
| `RT_Out_Itr_Algo` | `RT_Out_Aux_Def` | use_field_buffer, use_hist_buffer, field_buffer_size, hist_buffer_size, flush_frequency, compress_output, split_by_step, max_file_size_mb, use_parallel_io, io_comm_rank, io_comm_size | 迭代级缓冲/压缩/IO控制（P1 补全，[Phase:Itr|Verb:Com]） |
| `RT_Out` | `RT_Out_Def` | stp_ctl(`RT_Out_Stp_Ctl_Algo`) + itr_algo(`RT_Out_Itr_Algo`) + legacy flat fields | 输出算法控制参数（嵌入子 Algo + legacy 兼容） |

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Out_Ctx` | `RT_Out_Def` | step_id, incr_id, total_time, is_step_end, is_analysis_end, n_nodes, n_elements | 每次调用的输出上下文 |
| `RT_Out_Frame` | `RT_Out_Def` | ... | 单增量步输出帧缓冲 |
| `RT_Out_Buffer` | `RT_Out_Def` | ... | 批量写入循环缓冲 |
| `RT_Out_TriggerCtx` | `RT_Out_Def` | ... | 输出触发判定上下文 |

**权威 TYPE 模块**: `RT_Out_Def.f90` (ACTIVE, AUTHORITY) / `RT_Out_Aux_Def.f90` (ACTIVE, AUX-DEF for P1 sub-Algo)

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `RT_Out_Aux_Def.f90` | `RT_Out_Aux_Def` | `_Aux_Def` (辅Algo定义) | RT_Out_Stp_Ctl_Algo + RT_Out_Itr_Algo | **ACTIVE** (P1 GAP-FILL) |
| `RT_Out_Def.f90` | `RT_Out_Def` | `_Def` (TYPE定义) | 四型定义 + 格式/触发/位置常量 | **ACTIVE** (AUTHORITY) |
| `RT_Out_Mgr.f90` | `RT_Out_Mgr` | `_Mgr` (域管理器) | Init/Inc/BuildFrame/WriteFrame 生产编排 | **ACTIVE** (GOLDEN-LINE) |
| `RT_Out_Core.f90` | `RT_Out_Core` | `_Core` (核心实现) | RT_Output_Core_Init/Finalize/Open/Close/WriteFrame/WriteField/WriteHistory | **LEGACY** (FACADE) |
| `RT_Out_Proc.f90` | `RT_OutProc` | `_Proc` (SIO过程) | Init_In/Out, Collect_In/Out, Write_In/Out, CheckFreq_In/Out, Finalize_In/Out | **ACTIVE** (SIO) |
| `RT_Out_Impl.f90` | `RT_Out_Impl` | `_Impl` (实现逻辑) | RT_Out_Impl_Init/Collect/CheckFreq/Write/Finalize | **ACTIVE** |
| `RT_Out_Brg.f90` | `RT_Out_Brg` | `_Brg` (桥接) | RT_Output_Brg_FromL3/ToL4/CollectResults | **ACTIVE** |
| `RT_Out_Restart.f90` | `RT_OutRestart` | 特化 | RT_Out_RestartSave/RestartRestore | **ACTIVE** |
| `RT_Writer_HDF5.f90` | `RT_WriterHDF5` | 特化(Writer) | RT_Writer_HDF5_Init/WriteFrame/Close | **ACTIVE** |
| `RT_Writer_ODB.f90` | `RT_WriterODB` | 特化(Writer) | RT_Writer_ODB_Init/WriteFrame/Close/WriteModelInfo | **ACTIVE** |

---

## 4. 对外接口（公开 API）

### 生命周期接口

| 子程序 | 模块 | 签名概要 | 说明 |
|--------|------|----------|------|
| `RT_Out_Impl_Init` | `RT_Out_Impl` | `(input, output)` | 初始化输出系统（验证、缓冲预分配） |
| `RT_Out_Impl_Finalize` | `RT_Out_Impl` | `(input, output)` | 关闭输出系统 |

### 数据收集接口

| 子程序 | 模块 | 签名概要 | 说明 |
|--------|------|----------|------|
| `RT_Out_Impl_Collect` | `RT_Out_Impl` | `(input, output)` | 收集场/历史数据 |
| `RT_Output_Brg_CollectResults` | `RT_Out_Brg` | `(step_id, incr_id, time, ctx, status)` | 从求解器状态收集结果 |

### 写入接口

| 子程序 | 模块 | 签名概要 | 说明 |
|--------|------|----------|------|
| `RT_Out_Impl_Write` | `RT_Out_Impl` | `(input, output)` | 执行缓冲写入 |
| `RT_Out_Impl_CheckFreq` | `RT_Out_Impl` | `(input, output)` | 检查是否达到输出频率 |

### Bridge 接口

| 子程序 | 模块 | 签名概要 | 说明 |
|--------|------|----------|------|
| `RT_Output_Brg_FromL3` | `RT_Out_Brg` | `(n_field_reqs, n_hist_reqs, desc, status)` | 从 L3 拉取输出请求配置 |
| `RT_Output_Brg_ToL4` | `RT_Out_Brg` | `(ctx, n_nodes, n_elements, status)` | 推送变换参数到 L4 |

### Restart 接口

| 子程序 | 模块 | 签名概要 | 说明 |
|--------|------|----------|------|
| `RT_Out_RestartSave` | `RT_OutRestart` | `(restart_data, filename, status)` | 保存重启数据 |
| `RT_Out_RestartRestore` | `RT_OutRestart` | `(restart_data, filename, status)` | 恢复重启数据 |

### Writer 接口

| 子程序 | 模块 | 签名概要 | 说明 |
|--------|------|----------|------|
| `RT_Writer_HDF5_Init/WriteFrame/Close` | `RT_WriterHDF5` | — | HDF5 格式写入 |
| `RT_Writer_ODB_Init/WriteFrame/Close/WriteModelInfo` | `RT_WriterODB` | — | ABAQUS ODB 格式写入 |

---

## 5. 跨层数据流

### 输出请求流（冷路径，Populate）
```
L3_MD/Output (MD_Output_Registry, MD_FieldOut_Desc, MD_HistOut_Desc)
  → RT_Output_Brg_FromL3()                         ← L3→L5 配置拉取
    → RT_Out_Base_Desc (runtime_id, output_format)  ← L5 Populate 后只读
```

### 结果收集流（温/热路径，步末/增量末）
```
L5_RT/Solver (u, sigma, stateVars)
  → RT_Output_Brg_CollectResults()   ← 收集计算结果到 Ctx
    → RT_Out_Impl_Collect()          ← 按请求提取场/历史变量
      → RT_Out_Impl_CheckFreq()      ← 判定是否需要写出
        → RT_Out_Impl_Write()        ← 格式路由 → Writer
          → RT_Writer_HDF5/ODB/VTK   ← 实际文件 I/O
```

### 物理变换流
```
L5_RT/Output (raw computation data)
  → RT_Output_Brg_ToL4()            ← 推送到 L4
    → L4_PH/Output (坐标变换/张量旋转)  ← 物理层处理
      → 返回 L5 写入
```

### 单向依赖
- **消费**: L3_MD/Output (输出请求 Desc)、L3_MD/Analysis/Step (步定义)
- **消费**: L5_RT/Solver (求解结果)、L5_RT/WriteBack (回写状态)
- **委托**: L4_PH (坐标/张量变换)
- **使用**: L1_IF (IF_Prec_Core, IF_Err_Brg, IF_IO_File, IF_Mem_Mgr)

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Output | S (消费) | 输出请求 schema（MD_Output_Registry, MD_FieldOut_Desc, MD_HistOut_Desc） |
| R2 | L3_MD/Analysis/Step | S (消费) | 步定义与 Restart 数据（MD_RestartData, MD_OutCfg, MD_OutReq） |
| R3 | L4_PH/Output | B (桥接) | 物理层坐标/张量变换 |
| R4 | L5_RT/Solver | S (消费) | 求解结果（位移/应力/状态变量） |
| R5 | L5_RT/WriteBack | S (消费) | 回写后状态数据 |
| R6 | L5_RT/StepDriver | S (被调度) | StepDriver 在步末/增量末触发输出 |
| R7 | L1_IF/IO | U (基础设施) | IF_IO_File 文件句柄、IF_Mem_Mgr 内存管理 |
| R8 | L1_IF/Error | U (基础设施) | ErrorStatusType 错误传播 |

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 热路径零 L3（输出收集不直读 L3 Desc） | **硬** | 代码审查 + 静态分析 | CI |
| 不使用 STOP | **硬** | grep 扫描 | CI |
| Writer 模块可插拔（HDF5/ODB/VTK） | **硬** | 接口一致性测试 | PR |
| 缓冲式 I/O（减少系统调用） | **硬** | 性能测试 | 待建 |
| SIO Arg 封装遵循 Principle #14 | **硬** | 代码审查 | PR |
| 测试覆盖率 ≥ 80% | **软** | 覆盖率报告 | 待建 |

### 错误处理

| 错误码范围 | 错误场景 | 严重级 | 传播规则 | 恢复策略 |
|------------|----------|--------|----------|----------|
| ERR_L5_OUTPUT_50600 | 输出文件创建失败 | ERROR | 返回 status | 降级到 ASCII 或跳过 |
| ERR_L5_OUTPUT_50601 | 写入帧数据失败 | ERROR | 返回 status | 截断并记录警告 |
| ERR_L5_OUTPUT_50602 | Restart 文件读取失败 | ERROR | 返回 status | 终止恢复 |
| ERR_L5_OUTPUT_50603 | 输出请求引用无效变量 | WARNING | 返回 status | 跳过该请求 |
| ERR_L5_OUTPUT_50604 | HDF5/ODB 库未链接 | WARNING | 返回 status | 回退到 VTK/ASCII |

不使用 `STOP`；错误通过 `ErrorStatusType` 沿调用链传播。错误码范围：**50600–50699**。

### SIO / `*_Arg`（本域偏好）

与 Principle #14 一致：`RT_Out_Proc` 提供完整的 SIO `*_In`/`*_Out` Arg 封装（Init/Collect/Write/CheckFreq/Finalize 五组）。Writer 模块（HDF5/ODB）为独立功能单元，使用标量参数接口。

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 四型定义完整 | RT_Out_Def 包含 Desc/State/Algo/Ctx 四类 TYPE | ✅ 已实现 |
| A2 | 场输出可写入 | Field 数据可写入 VTK/HDF5/ODB 至少一种格式 | ✅ 已实现 |
| A3 | 历史输出可记录 | History 时间序列数据可按请求频率记录 | ✅ 已实现 |
| A4 | Restart 可序列化 | RestartSave/Restore 可正确序列化/反序列化状态 | ✅ 已实现 |
| A5 | Bridge 链完整 | FromL3/ToL4/CollectResults 三向桥接就绪 | ✅ 已实现 |
| A6 | SIO Proc 完整 | 5 组 _In/_Out 结构化接口已定义 | ✅ 已实现 |
| A7 | 错误传播一致 | 所有公开 API 返回 ErrorStatusType，不使用 STOP | ✅ 已实现 |
| A8 | 输出格式可扩展 | RT_OUT_FMT_* 常量支持 VTK/HDF5/ODB/ASCII 四种 | ✅ 已实现 |
| A9 | 单元测试覆盖 | 核心路径有测试覆盖 | 待补全 |
| A10 | 热路径零 L3 | 步内输出收集不直读 L3 模型数据 | ✅ 已实现 |

### 四链说明

| 链 | 本域可核对说明 |
|----|---------------|
| **理论链** | 输出系统无自有理论；职责为将计算结果忠实写入持久化介质 |
| **逻辑链** | StepDriver(步末) → Output(CheckFreq→Collect→Write) → Writer(HDF5/ODB/VTK) → 文件系统 |
| **计算链** | 无 PDE 求解；帧组装 O(N_nodes + N_elements)；写入 I/O 密集 |
| **数据链** | L3 OutputReq(冷) → Populate → L5 Desc(冷) → Solver 结果(热) → Frame(温) → 文件(冷) |
