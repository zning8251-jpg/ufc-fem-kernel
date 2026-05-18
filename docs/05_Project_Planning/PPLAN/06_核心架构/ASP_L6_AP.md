# 算法步规约：L6_AP — 应用层（8 域）

> **版本**: v1.0 | **日期**: 2026-04-26
>
> L6 特征：最外层应用入口，Phase 集中在 Config/Step，面向用户的读入/作业/输出。

---

## Config（11 过程 — 数据域）

**核心意图**: 命令行解析、运行时参数管理

### 算法步序列

| Step | 过程 | 消费 | 生产 | 算法核 | Phase |
|------|------|------|------|--------|-------|
| 0 | `AP_Config_Core_Init` | — | config_desc | 分配键值对存储 | Config |
| 1 | `AP_Config_Parse_CommandLine` | argc, argv | config_desc.entries | 解析 --key=value | Config |
| 2 | `AP_Config_Set_Int` | key, value(i4) | entries(key)=value | 键值写入 | Config |
| 3 | `AP_Config_Set_Real` | key, value(wp) | entries(key)=value | 键值写入 | Config |
| 4 | `AP_Config_Set_String` | key, value(char) | entries(key)=value | 键值写入 | Config |
| 5 | `AP_Config_Get_Int` | key | result(i4) | 键值查询 | (any) |
| 6 | `AP_Config_Get_Real` | key | result(wp) | 键值查询 | (any) |
| 7 | `AP_Config_Get_String` | key | result(char) | 键值查询 | (any) |
| 8 | `AP_Config_Print` | config_desc | → stdout | 遍历打印 | (any) |
| 9 | `AP_Config_Core_Finalize` | config_desc | — | 释放 | Config |

**Parse_CommandLine 算法核**:
```
DO i = 1, argc
  IF (argv(i)(1:2) == '--') THEN
    pos = INDEX(argv(i), '=')
    key = argv(i)(3:pos-1); value = argv(i)(pos+1:)
    CALL Set_String(key, value)
  END IF
END DO
```

**跨域供数**: 配置参数 → L5_RT/StepDriver.Algo, L2_NM/Solver.Algo

---

## Input（8 过程 — 数据域）

**核心意图**: INP 文件读取与关键字处理

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `AP_Input_Core_Init` | — | input_state | Config |
| 1 | `AP_Input_Read_File` | filename | raw_lines(:) | Config |
| 2 | `AP_Input_Process_Keywords` | raw_lines | → L3_MD 各域 (via KeyWord parser) | Config |
| 3 | `AP_Input_Validate` | input_state | status | Config |

**Read_File 算法核**:
```
OPEN(UNIT=u, FILE=filename, STATUS='OLD')
DO WHILE (.NOT. EOF(u))
  READ(u, '(A)') line
  n_lines = n_lines + 1
  raw_lines(n_lines) = line
END DO
CLOSE(u)
```

**Process_Keywords 算法核**:
```
DO i = 1, n_lines
  CALL MD_KeyWord_Parse_Line(raw_lines(i), kw_state, status)
  IF (kw_state.is_keyword) THEN
    CALL MD_KeyWord_Match(kw_state.name, handler, status)
    CALL handler%process(kw_state, model, status)    ! → 写入 L3_MD
  ELSE
    CALL current_handler%process_data(raw_lines(i), model, status)
  END IF
END DO
```

**关键数据流**: INP 文件 → AP_Input → L3_MD/KeyWord → L3_MD 各域 (Model/Mesh/Material/…)

---

## Job（7 过程 — 编排域）

**核心意图**: 最高层编排入口——创建/运行/管理分析作业

### 算法步序列（详细五要素）

#### Step 0: Core_Init

**消费**: — | **生产**: job_desc(空) | **Phase**: Config

#### Step 1: Create

**消费 [IN]**: job_name, model_desc (from L3)
**生产 [OUT]**: job_desc.name, job_desc.model_ref, job_desc.status = CREATED

**算法核**: `job_desc = {name, model_ref, status=CREATED, start_time=0}`

#### Step 2: Run — 主入口

**设计意图**: 全分析流程的顶层循环——遍历所有分析步调用 L5 StepDriver。

**消费 [IN]**:
| 数据 | 来源 | 温度 |
|------|------|------|
| job_desc.model_ref | Step 1 | 冷 |
| n_steps | L3_MD/Model.Get_N_Steps | 冷 |

**生产 [OUT]**:
| 数据 | 消费者 | 温度 |
|------|--------|------|
| job_desc.status = COMPLETED/FAILED | Step 4 (Get_Status) | 温 |

**算法核**:
```
job_desc.status = RUNNING
DO step = 1, n_steps
  ! Populate L4/L5 from L3 for this step
  CALL Bridge_Populate_All(model, step, status)
  ! Run step via L5
  CALL RT_StepDriver_Run_Step(step_driver, ..., status)
  IF (status /= 0) THEN
    job_desc.status = FAILED; RETURN
  END IF
  ! WriteBack + Output
  CALL RT_WriteBack_Execute_All(...)
  CALL RT_Output_Write_Frame(...)
END DO
job_desc.status = COMPLETED
```

**前置条件**: L3_MD/Model.Validate_All 通过 (status=0)
**后置保证**: job_desc.status ∈ {COMPLETED, FAILED}
**Phase**: Step | **复杂度**: O(n_steps × StepDriver_cost)

#### Step 3: Abort

**消费**: job_desc | **生产**: job_desc.status = ABORTED
**Phase**: (any) | **复杂度**: O(1)

#### Step 4: Get_Status / Summary

**消费**: job_desc.status | **生产**: 返回值/格式化文本
**Phase**: (any)

### Job 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| job_desc | Step 1 (Create) | Step 2–4 | ✓ |
| model_ref | Step 1 | Step 2 (Run loop) | ✓ |
| job_status | Step 2/3 | Step 4, 外部 | ✓ |

---

## Output（10 过程 — 数据域）

**核心意图**: 后处理输出——报告、VTK 可视化

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `AP_Output_Core_Init` | — | output_desc | Config |
| 1 | `AP_Output_Write_Report` | analysis_results | → 报告文件 | Step |
| 2 | `AP_Output_Write_Summary_Table` | step_results(:) | → 摘要表 | Step |
| 3 | `AP_Output_Write_VTK_Header` | filename, title | → VTK 文件头 | Step |
| 4 | `AP_Output_Write_VTK_Nodes` | coords(ndim,n) | → VTK POINTS | Step |
| 5 | `AP_Output_Write_VTK_Cells` | conn, types | → VTK CELLS | Step |
| 6 | `AP_Output_Write_VTK_Point_Vector` | u(ndim,n) | → VTK VECTORS | Step |
| 7 | `AP_Output_Write_VTK_Point_Scalar` | field(n) | → VTK SCALARS | Step |
| 8 | `AP_Output_Write_VTK_Full` | 全部数据 | → 完整 VTK 文件 | Step |

**Write_VTK_Full 算法核**:
```
CALL Write_VTK_Header(...)
CALL Write_VTK_Nodes(coords, ...)
CALL Write_VTK_Cells(conn, ...)
CALL Write_VTK_Point_Vector('displacement', u, ...)
CALL Write_VTK_Point_Scalar('von_mises', vm, ...)
```

**数据来源**: L5_RT/WriteBack → L3_MD/Field → AP_Output

---

## Registry（10 过程 — 数据域）

**核心意图**: 应用级单元/材料注册表

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `AP_Registry_Core_Init` | — | registry_desc | Config |
| 1 | `AP_Registry_Register_Element` | elem_type, handler | elem_registry(+1) | Config |
| 2 | `AP_Registry_Register_Material` | mat_model, handler | mat_registry(+1) | Config |
| 3 | `AP_Registry_Lookup_Element` | elem_type | handler (or NULL) | (any) |
| 4 | `AP_Registry_Lookup_Material` | mat_model | handler (or NULL) | (any) |
| 5 | `AP_Registry_Get_Count` | — | n_elem_types, n_mat_models | (any) |
| 6 | `AP_Registry_Print` | registry | → stdout | (any) |

**关键数据流**: AP_Registry → L4_PH/Material (分发路由), L4_PH/Element (族选择)

---

## Solver（6 过程 — 编排域）

**核心意图**: 应用级求解器配置与步驱动入口

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 0 | `AP_Solver_Core_Init` | — | solver_desc | Config |
| 1 | `AP_Solver_Configure` | solver_type, params | solver_desc.config | Config |
| 2 | `AP_Solver_Get_Type` | solver_desc | type(枚举) | (any) |
| 3 | `AP_Solver_Run_Step` | step_id | → L5_RT/StepDriver | Step |
| 4 | `AP_Solver_Run_All_Steps` | n_steps | → L5_RT/StepDriver ×N | Step |

**Run_All_Steps 算法核**: `DO s=1,n_steps; CALL Run_Step(s); END DO`

---

## UI（8 过程 — 观测域）

**核心意图**: 用户界面输出

### 算法步序列

| Step | 过程 | 消费 | 生产 | Phase |
|------|------|------|------|-------|
| 1 | `AP_UI_Print_Banner` | version_info | → stdout (banner) | Config |
| 2 | `AP_UI_Print_Progress` | step_id, inc_id, time | → stdout (进度) | Step |
| 3 | `AP_UI_Print_Section` | title | → stdout (节标题) | (any) |
| 4 | `AP_UI_Print_Warning` | message | → stdout (⚠) | (any) |
| 5 | `AP_UI_Print_Error` | message | → stderr (✗) | (any) |
| 6 | `AP_UI_Print_Done` | elapsed_time | → stdout (✓) | Config |

**Print_Banner 算法核**:
```
WRITE(*,'(A)')  '================================================================'
WRITE(*,'(A)')  '    UFC - Unified FEM Core  v' // version
WRITE(*,'(A)')  '================================================================'
```

**数据流**: 纯输出型（观测不影响求解）。✓

---

## Bridge（桥接域 — 无 Core）

**核心意图**: L6↔L3/L4/L5 跨层桥接

| Bridge | 方向 | 算法核 |
|--------|------|--------|
| `AP_BrgL3` | L6→L3 | 将 Input 解析结果写入 L3 Model/Mesh/Material |
| `AP_BrgL4` | L6→L4 | 将注册表配置传递到 L4 元素/材料 slot |
| `AP_BrgL5` | L6→L5 | 将求解器配置传递到 L5 StepDriver/Solver |
| `AP_Mat_Brg` | L6→L3/L4 | 材料注册表→L3 材料卡→L4 slot |

**Phase**: Config | **模式**: 同 L3_MD/Bridge — 单向搬运。✓
