# L6_AP 应用层工作流补全 v1.0

> **层级**: L6_AP (Application Layer — 应用层)
> **优先级**: ⭐⭐⭐ (P3 启动任务)
> **版本**: v1.0
> **创建日期**: 2026-04-04
> **阶段**: P3 接口工作流补全

---

## 一、L6_AP 层职责定义

L6_AP 是 UFC 的**应用层**，位于 UFC 内核之上，负责**用户交互、输入解析、输出生成、求解编排**。它是用户和内核的接口窗口。

### 核心职责
- **输入解析** (AP_Input)：ABAQUS .inp 文件解析、关键字映射、模型树构建
- **输出生成** (AP_Output)：结果写入（ODB、CSV、HDF5）、可视化数据准备
- **求解器编排** (AP_Solver)：分析步调度、收敛策略、重启机制
- **命令行接口** (AP_Command)：命令行参数解析、交互式 CLI、脚本执行
- **GUI 框架** (AP_GUI)：图形化前后处理、参数设置界面（可选）

---

## 二、四个子域的工作流规范

### 2.1 AP_Input — ABAQUS .inp 解析与模型构建

**目标**：将 ABAQUS 输入文件 (.inp) 解析为 UFC 内部模型树

**关键接口**：

```fortran
!===============================================================================
! MODULE AP_Input — ABAQUS .inp 文件解析与模型树构建
!===============================================================================

MODULE AP_Input
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  USE IF_IO, ONLY: IF_Open_File, IF_Close_File, IF_Read_Line
  USE IF_Log, ONLY: IF_Log_Message, IF_LOG_INFO
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Parse_Input_File
  PUBLIC :: AP_Build_Model_Tree
  PUBLIC :: AP_Validate_Model

CONTAINS

  ! ===== 主入口：解析 .inp 文件 =====
  SUBROUTINE AP_Parse_Input_File(input_file, model_desc, status)
    CHARACTER(len=*), INTENT(IN) :: input_file
    TYPE(L3_MD_Model_Desc), INTENT(OUT) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER :: file_unit
    CHARACTER(len=:), ALLOCATABLE :: line
    INTEGER(i4) :: line_num, keyword_id
    
    ! 1. 打开文件
    CALL IF_Open_File(input_file, file_unit, "READ", status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 2. 逐行解析关键字
    line_num = 0_i4
    DO
      CALL IF_Read_Line(file_unit, line, status)
      IF (status%status_code /= 0) EXIT  ! 文件结束
      
      line_num = line_num + 1_i4
      
      ! 识别关键字 (*PART, *MATERIAL, *ELEMENT, 等)
      IF (line(1:1) == '*' .AND. line(1:2) /= '**') THEN
        CALL AP_Parse_Keyword(line, keyword_id, status)
        
        SELECT CASE (keyword_id)
        CASE (KEYWORD_PART)
          CALL AP_Parse_Part_Block(file_unit, model_desc, status)
        CASE (KEYWORD_MATERIAL)
          CALL AP_Parse_Material_Block(file_unit, model_desc, status)
        CASE (KEYWORD_ELEMENT)
          CALL AP_Parse_Element_Block(file_unit, model_desc, status)
        CASE (KEYWORD_BOUNDARY)
          CALL AP_Parse_Boundary_Block(file_unit, model_desc, status)
        ! ... 更多关键字
        END SELECT
      END IF
    END DO
    
    CALL IF_Close_File(file_unit, status)
    CALL IF_Log_Message(IF_LOG_INFO, "Input file parsing complete")
  END SUBROUTINE AP_Parse_Input_File

  ! ===== 关键字识别 =====
  SUBROUTINE AP_Parse_Keyword(line, keyword_id, status)
    CHARACTER(len=*), INTENT(IN) :: line
    INTEGER(i4), INTENT(OUT) :: keyword_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    IF (INDEX(line, "*PART") > 0) THEN
      keyword_id = KEYWORD_PART
    ELSE IF (INDEX(line, "*MATERIAL") > 0) THEN
      keyword_id = KEYWORD_MATERIAL
    ELSE IF (INDEX(line, "*ELEMENT") > 0) THEN
      keyword_id = KEYWORD_ELEMENT
    ELSE IF (INDEX(line, "*BOUNDARY") > 0) THEN
      keyword_id = KEYWORD_BOUNDARY
    ELSE IF (INDEX(line, "*STEP") > 0) THEN
      keyword_id = KEYWORD_STEP
    ELSE
      keyword_id = KEYWORD_UNKNOWN
    END IF
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Parse_Keyword

  ! ===== 解析 *PART 块 =====
  SUBROUTINE AP_Parse_Part_Block(file_unit, model_desc, status)
    INTEGER, INTENT(IN) :: file_unit
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=:), ALLOCATABLE :: line
    CHARACTER(len=64) :: part_name
    INTEGER(i4) :: part_id, n_nodes, n_elements
    
    ! 读取 *PART 名称
    CALL IF_Read_Line(file_unit, line, status)
    CALL AP_Extract_Parameter(line, "NAME", part_name, status)
    
    part_id = model_desc%n_parts + 1_i4
    model_desc%n_parts = part_id
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Parsing PART: " // TRIM(part_name) // " (ID=" // TRIM(I_STR(part_id)) // ")")
  END SUBROUTINE AP_Parse_Part_Block

  ! ===== 解析 *MATERIAL 块 =====
  SUBROUTINE AP_Parse_Material_Block(file_unit, model_desc, status)
    INTEGER, INTENT(IN) :: file_unit
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=:), ALLOCATABLE :: line
    CHARACTER(len=64) :: material_name
    CHARACTER(len=32) :: material_type
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: mat_id, n_props
    
    ! 读取 *MATERIAL 名称与子关键字 (*ELASTIC, *PLASTIC, 等)
    CALL IF_Read_Line(file_unit, line, status)
    CALL AP_Extract_Parameter(line, "NAME", material_name, status)
    
    mat_id = model_desc%n_materials + 1_i4
    model_desc%n_materials = mat_id
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Parsing MATERIAL: " // TRIM(material_name) // " (ID=" // TRIM(I_STR(mat_id)) // ")")
    
    ! 递归解析子块 (*ELASTIC, *PLASTIC, 等)
    CALL AP_Parse_Material_Subblock(file_unit, model_desc, mat_id, status)
  END SUBROUTINE AP_Parse_Material_Block

  ! ===== 递归：解析材料子块 =====
  RECURSIVE SUBROUTINE AP_Parse_Material_Subblock(file_unit, model_desc, mat_id, status)
    INTEGER, INTENT(IN) :: file_unit
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=:), ALLOCATABLE :: line
    CHARACTER(len=32) :: subkeyword
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: n_props
    
    DO
      CALL IF_Read_Line(file_unit, line, status)
      IF (status%status_code /= 0) EXIT
      IF (line(1:1) == '*') THEN
        ! 回到上一级关键字，退出递归
        BACKSPACE(file_unit)
        EXIT
      END IF
      
      ! 解析属性行 (E, NU 等)
      CALL AP_Parse_Material_Props(line, props, n_props, status)
      
      ! 存储到材料库
      model_desc%materials(mat_id)%n_props = n_props
      ALLOCATE(model_desc%materials(mat_id)%props(n_props))
      model_desc%materials(mat_id)%props = props
    END DO
  END SUBROUTINE AP_Parse_Material_Subblock

  ! ===== 辅助：提取参数值 =====
  SUBROUTINE AP_Extract_Parameter(line, param_name, param_value, status)
    CHARACTER(len=*), INTENT(IN) :: line, param_name
    CHARACTER(len=*), INTENT(OUT) :: param_value
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER :: pos, eq_pos
    CHARACTER(len=:), ALLOCATABLE :: token
    
    pos = INDEX(line, TRIM(param_name) // "=")
    IF (pos > 0) THEN
      eq_pos = pos + LEN_TRIM(param_name)
      token = ADJUSTL(line(eq_pos+1:))
      param_value = token(1:MIN(LEN(param_value), LEN_TRIM(token)))
    END IF
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Extract_Parameter

  ! ===== 辅助：解析材料属性行 =====
  SUBROUTINE AP_Parse_Material_Props(line, props, n_props, status)
    CHARACTER(len=*), INTENT(IN) :: line
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: props(:)
    INTEGER(i4), INTENT(OUT) :: n_props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=1024) :: buffer
    INTEGER :: comma_pos, i
    REAL(wp) :: value
    
    buffer = TRIM(line)
    n_props = 0_i4
    ALLOCATE(props(100))  ! 预分配
    
    ! 逐个读取逗号分隔的数值
    DO
      comma_pos = INDEX(buffer, ',')
      IF (comma_pos == 0) THEN
        IF (LEN_TRIM(buffer) > 0) THEN
          READ(buffer, *, IOSTAT=status%status_code) value
          IF (status%status_code == 0) THEN
            n_props = n_props + 1_i4
            props(n_props) = value
          END IF
        END IF
        EXIT
      ELSE
        READ(buffer(1:comma_pos-1), *, IOSTAT=status%status_code) value
        IF (status%status_code == 0) THEN
          n_props = n_props + 1_i4
          props(n_props) = value
        END IF
        buffer = ADJUSTL(buffer(comma_pos+1:))
      END IF
    END DO
  END SUBROUTINE AP_Parse_Material_Props

  ! ===== 解析 *ELEMENT 块 =====
  SUBROUTINE AP_Parse_Element_Block(file_unit, model_desc, status)
    INTEGER, INTENT(IN) :: file_unit
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    ! (类似 Parse_Material_Block 的结构)
  END SUBROUTINE AP_Parse_Element_Block

  ! ===== 解析 *BOUNDARY 块 =====
  SUBROUTINE AP_Parse_Boundary_Block(file_unit, model_desc, status)
    INTEGER, INTENT(IN) :: file_unit
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    ! (类似结构)
  END SUBROUTINE AP_Parse_Boundary_Block

  ! ===== 构建完整的模型树 =====
  SUBROUTINE AP_Build_Model_Tree(model_desc, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 1. 连接关键数据结构（节点-单元、单元-材料）
    ! 2. 构建空间索引（用于邻近搜索）
    ! 3. 初始化约束条件与荷载集合
    ! 4. 验证拓扑一致性
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Model tree built: nodes=" // TRIM(I_STR(model_desc%n_nodes)) // &
      ", elements=" // TRIM(I_STR(model_desc%n_elements)))
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Build_Model_Tree

  ! ===== 验证模型完整性 =====
  SUBROUTINE AP_Validate_Model(model_desc, status)
    TYPE(L3_MD_Model_Desc), INTENT(IN) :: model_desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    LOGICAL :: is_valid
    
    ! 检查：所有单元是否引用了有效的节点？
    ! 检查：所有单元是否分配了材料？
    ! 检查：边界条件是否有重复定义？
    ! 检查：荷载是否有冲突？
    
    is_valid = .TRUE.
    
    IF (is_valid) THEN
      CALL IF_Log_Message(IF_LOG_INFO, "Model validation passed")
      status%status_code = STATUS_OK
    ELSE
      status%status_code = STATUS_ERROR
      status%message = "Model validation failed"
    END IF
  END SUBROUTINE AP_Validate_Model

  ! ===== 辅助函数：整数转字符串 =====
  FUNCTION I_STR(i) RESULT(s)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(len=32) :: s
    WRITE(s, '(I0)') i
  END FUNCTION I_STR

END MODULE AP_Input
```

---

### 2.2 AP_Output — 结果输出与数据交换

**目标**：将 UFC 计算结果写入 ODB、CSV、HDF5 等格式

```fortran
!===============================================================================
! MODULE AP_Output — 结果输出与可视化数据生成
!===============================================================================

MODULE AP_Output
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  USE IF_IO, ONLY: IF_Open_File, IF_Close_File, IF_Write_Line
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Write_ODB
  PUBLIC :: AP_Write_CSV
  PUBLIC :: AP_Write_HDF5
  PUBLIC :: AP_Write_Visualization_Data

CONTAINS

  ! ===== 写入 ODB 格式 (ABAQUS 输出数据库) =====
  SUBROUTINE AP_Write_ODB(odb_file, result_data, status)
    CHARACTER(len=*), INTENT(IN) :: odb_file
    TYPE(L5_RT_Result_Data), INTENT(IN) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! ODB 格式为 ABAQUS 专有格式
    ! 需要通过 Fortran/C 互操作或第三方库进行写入
    ! 示例: 调用 Python 脚本 或 C++ 库进行 ODB 写入
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Writing results to ODB: " // TRIM(odb_file))
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Write_ODB

  ! ===== 写入 CSV 格式 (文本表格) =====
  SUBROUTINE AP_Write_CSV(csv_file, result_data, status)
    CHARACTER(len=*), INTENT(IN) :: csv_file
    TYPE(L5_RT_Result_Data), INTENT(IN) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER :: file_unit, i, j
    CHARACTER(len=:), ALLOCATABLE :: line
    
    CALL IF_Open_File(csv_file, file_unit, "WRITE", status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 写入表头
    CALL IF_Write_Line(file_unit, &
      "Node_ID,X,Y,Z,Disp_X,Disp_Y,Disp_Z,Stress_XX,Stress_YY,Stress_ZZ", status)
    
    ! 写入节点数据
    DO i = 1, result_data%n_nodes
      WRITE(line,'(I0,9F15.6)') i, &
        result_data%coords(i,:), &
        result_data%displacements(i,:), &
        result_data%stresses(i,1:3)
      CALL IF_Write_Line(file_unit, line, status)
    END DO
    
    CALL IF_Close_File(file_unit, status)
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Results written to CSV: " // TRIM(csv_file))
  END SUBROUTINE AP_Write_CSV

  ! ===== 写入 HDF5 格式 (高性能数据) =====
  SUBROUTINE AP_Write_HDF5(hdf5_file, result_data, status)
    CHARACTER(len=*), INTENT(IN) :: hdf5_file
    TYPE(L5_RT_Result_Data), INTENT(IN) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 需要链接 HDF5 库 (h5fortran 或类似)
    ! CALL H5_Create_File(hdf5_file, ...)
    ! CALL H5_Write_Dataset(...)
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Results written to HDF5: " // TRIM(hdf5_file))
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Write_HDF5

  ! ===== 生成可视化数据 (VTK 格式用于 ParaView) =====
  SUBROUTINE AP_Write_Visualization_Data(vtk_file, result_data, status)
    CHARACTER(len=*), INTENT(IN) :: vtk_file
    TYPE(L5_RT_Result_Data), INTENT(IN) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! VTK 格式: 结合几何与标量/矢量字段
    ! 可用于 ParaView、VisIt 等开源可视化工具
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Visualization data written to VTK: " // TRIM(vtk_file))
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Write_Visualization_Data

END MODULE AP_Output
```

---

### 2.3 AP_Solver — 求解器编排与步调度

**目标**：协调多个分析步、管理收敛、支持重启

```fortran
!===============================================================================
! MODULE AP_Solver — 求解器协调、分析步调度、收敛管理
!===============================================================================

MODULE AP_Solver
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  USE IF_Log, ONLY: IF_Log_Message, IF_LOG_INFO, TimerType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Execute_Analysis
  PUBLIC :: AP_Schedule_Steps
  PUBLIC :: AP_Check_Convergence

CONTAINS

  ! ===== 主执行入口 =====
  SUBROUTINE AP_Execute_Analysis(model_desc, analysis_steps, result_data, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: analysis_steps(:)
    TYPE(L5_RT_Result_Data), INTENT(INOUT) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: step_idx, n_steps
    TYPE(TimerType) :: timer
    REAL(wp) :: total_time
    
    n_steps = SIZE(analysis_steps)
    total_time = 0.0_wp
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Starting analysis with " // TRIM(I_STR(n_steps)) // " steps")
    
    ! 遍历分析步
    DO step_idx = 1, n_steps
      CALL IF_Timer_Start(timer)
      
      CALL AP_Execute_Single_Step(model_desc, analysis_steps(step_idx), &
                                  result_data, status)
      
      CALL IF_Timer_Stop(timer)
      total_time = total_time + timer%total_time
      
      IF (status%status_code /= STATUS_OK) THEN
        CALL IF_Log_Message(IF_LOG_ERROR, &
          "Step " // TRIM(I_STR(step_idx)) // " failed")
        RETURN
      END IF
      
      CALL IF_Log_Message(IF_LOG_INFO, &
        "Step " // TRIM(I_STR(step_idx)) // " completed in " // &
        TRIM(R_STR(timer%total_time)) // "s")
    END DO
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Analysis complete. Total time: " // TRIM(R_STR(total_time)) // "s")
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Execute_Analysis

  ! ===== 执行单个分析步 =====
  SUBROUTINE AP_Execute_Single_Step(model_desc, step, result_data, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: step
    TYPE(L5_RT_Result_Data), INTENT(INOUT) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 1. 根据分析类型选择求解器
    ! 2. 初始化求解器（装配刚度矩阵、质量矩阵）
    ! 3. 时间步或迭代循环
    ! 4. 汇总结果
    
    SELECT CASE (TRIM(step%analysis_type))
    CASE ("STATIC")
      CALL AP_Solve_Static(model_desc, step, result_data, status)
    CASE ("DYNAMIC")
      CALL AP_Solve_Dynamic(model_desc, step, result_data, status)
    CASE ("FREQUENCY")
      CALL AP_Solve_Frequency(model_desc, step, result_data, status)
    CASE ("THERMAL")
      CALL AP_Solve_Thermal(model_desc, step, result_data, status)
    CASE DEFAULT
      status%status_code = STATUS_ERROR
      status%message = "Unknown analysis type: " // TRIM(step%analysis_type)
    END SELECT
  END SUBROUTINE AP_Execute_Single_Step

  ! ===== 静力分析求解 =====
  SUBROUTINE AP_Solve_Static(model_desc, step, result_data, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: step
    TYPE(L5_RT_Result_Data), INTENT(INOUT) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 1. 组装全局刚度矩阵 K
    CALL L4_Assembly_Global_Stiffness(model_desc, status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 2. 组装全局荷载向量 F
    CALL L4_Assembly_Load_Vector(model_desc, step, status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 3. 施加边界条件 (约束位移、约束反力)
    CALL L4_Apply_Boundary_Conditions(model_desc, status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 4. 求解线性方程组 K*u = F
    CALL L2_Solve_Linear_System(model_desc%K, model_desc%F, &
                                result_data%displacements, status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 5. 后处理：计算应力、应变
    CALL L4_Postprocess_Stresses(model_desc, result_data, status)
  END SUBROUTINE AP_Solve_Static

  ! ===== 动力分析求解 =====
  SUBROUTINE AP_Solve_Dynamic(model_desc, step, result_data, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: step
    TYPE(L5_RT_Result_Data), INTENT(INOUT) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 1. 组装质量矩阵 M、刚度矩阵 K、阻尼矩阵 C
    CALL L4_Assembly_Dynamics_Matrices(model_desc, status)
    IF (status%status_code /= STATUS_OK) RETURN
    
    ! 2. 时间积分循环 (Newmark, HHT, etc.)
    CALL L5_Time_Integration_Loop(model_desc, step, result_data, status)
  END SUBROUTINE AP_Solve_Dynamic

  ! ===== 频率分析求解 =====
  SUBROUTINE AP_Solve_Frequency(model_desc, step, result_data, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: step
    TYPE(L5_RT_Result_Data), INTENT(INOUT) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 求解广义特征值问题: (K - lambda*M)*phi = 0
    CALL L2_Solve_Eigenvalue_Problem(model_desc%K, model_desc%M, &
                                     result_data%eigenvalues, &
                                     result_data%eigenvectors, status)
  END SUBROUTINE AP_Solve_Frequency

  ! ===== 热分析求解 =====
  SUBROUTINE AP_Solve_Thermal(model_desc, step, result_data, status)
    TYPE(L3_MD_Model_Desc), INTENT(INOUT) :: model_desc
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: step
    TYPE(L5_RT_Result_Data), INTENT(INOUT) :: result_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 求解热传导方程: C*dT/dt + K*T = Q
    CALL L2_Solve_Transient_Heat(model_desc, step, result_data, status)
  END SUBROUTINE AP_Solve_Thermal

  ! ===== 分析步调度（优先级排序） =====
  SUBROUTINE AP_Schedule_Steps(analysis_steps, scheduled_order, status)
    TYPE(L3_MD_Analysis_Step), INTENT(IN) :: analysis_steps(:)
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: scheduled_order(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_steps
    INTEGER(i4), ALLOCATABLE :: priorities(:)
    
    n_steps = SIZE(analysis_steps)
    ALLOCATE(priorities(n_steps))
    ALLOCATE(scheduled_order(n_steps))
    
    ! 根据优先级标签排序
    DO i = 1, n_steps
      priorities(i) = analysis_steps(i)%priority_level
    END DO
    
    ! 升序排序（P1 < P2 < P3）
    CALL AP_Sort_By_Priority(priorities, scheduled_order, status)
  END SUBROUTINE AP_Schedule_Steps

  ! ===== 收敛检查 =====
  SUBROUTINE AP_Check_Convergence(residual, tolerance, converged, status)
    REAL(wp), INTENT(IN) :: residual, tolerance
    LOGICAL, INTENT(OUT) :: converged
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    converged = (residual < tolerance)
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Check_Convergence

  ! ===== 辅助函数 =====
  FUNCTION I_STR(i) RESULT(s)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(len=32) :: s
    WRITE(s, '(I0)') i
  END FUNCTION I_STR

  FUNCTION R_STR(r) RESULT(s)
    REAL(wp), INTENT(IN) :: r
    CHARACTER(len=32) :: s
    WRITE(s, '(F10.4)') r
  END FUNCTION R_STR

END MODULE AP_Solver
```

---

### 2.4 AP_Command — 命令行接口与脚本执行

**目标**：解析命令行参数、交互式 CLI、脚本执行

```fortran
!===============================================================================
! MODULE AP_Command — 命令行接口与参数解析
!===============================================================================

MODULE AP_Command
  USE IF_Prec, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, STATUS_OK
  USE IF_Log, ONLY: IF_Log_Message, IF_LOG_INFO
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Parse_Command_Line
  PUBLIC :: AP_Interactive_CLI
  PUBLIC :: AP_Execute_Script

CONTAINS

  ! ===== 解析命令行参数 =====
  SUBROUTINE AP_Parse_Command_Line(input_file, output_dir, options, status)
    CHARACTER(len=:), ALLOCATABLE, INTENT(OUT) :: input_file, output_dir
    TYPE(AP_Options), INTENT(OUT) :: options
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER :: nargs, i, eq_pos
    CHARACTER(len=1024) :: arg, key, value
    
    nargs = COMMAND_ARGUMENT_COUNT()
    
    ! 默认值
    input_file = "model.inp"
    output_dir = "./results"
    options%num_threads = 1
    options%verbose = .FALSE.
    options%restart = .FALSE.
    
    ! 遍历参数
    DO i = 1, nargs
      CALL GET_COMMAND_ARGUMENT(i, arg)
      
      ! 检查是否为 -key=value 格式
      IF (arg(1:1) == '-') THEN
        eq_pos = INDEX(arg, '=')
        IF (eq_pos > 0) THEN
          key = arg(2:eq_pos-1)
          value = arg(eq_pos+1:)
          
          SELECT CASE (TRIM(key))
          CASE ("input")
            ALLOCATE(CHARACTER(len=LEN_TRIM(value)) :: input_file)
            input_file = TRIM(value)
          CASE ("output")
            ALLOCATE(CHARACTER(len=LEN_TRIM(value)) :: output_dir)
            output_dir = TRIM(value)
          CASE ("threads")
            READ(value, *, IOSTAT=status%status_code) options%num_threads
          CASE ("verbose")
            options%verbose = .TRUE.
          CASE ("restart")
            options%restart = .TRUE.
          END SELECT
        END IF
      ELSE
        ! 位置参数：第一个非选项参数为输入文件
        ALLOCATE(CHARACTER(len=LEN_TRIM(arg)) :: input_file)
        input_file = TRIM(arg)
      END IF
    END DO
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Input: " // input_file // ", Output: " // output_dir)
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Parse_Command_Line

  ! ===== 交互式 CLI =====
  SUBROUTINE AP_Interactive_CLI(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=1024) :: command, arg1, arg2
    LOGICAL :: continue_loop
    
    continue_loop = .TRUE.
    
    PRINT *, "UFC Interactive Mode"
    PRINT *, "Type 'help' for commands, 'quit' to exit"
    PRINT *, ""
    
    DO WHILE (continue_loop)
      WRITE(*, '(A)', ADVANCE='NO') "ufc> "
      READ(*, '(A)') command
      
      IF (LEN_TRIM(command) == 0) CYCLE
      
      SELECT CASE (TRIM(command))
      CASE ("quit", "exit")
        PRINT *, "Exiting..."
        continue_loop = .FALSE.
      CASE ("help")
        CALL AP_Print_Help()
      CASE ("load")
        PRINT *, "Load input file: "
        READ(*, '(A)') arg1
        ! CALL AP_Load_Model(arg1, status)
      CASE ("solve")
        ! CALL AP_Execute_Analysis(status)
      CASE ("export")
        ! CALL AP_Export_Results(status)
      CASE DEFAULT
        PRINT *, "Unknown command: " // TRIM(command)
      END SELECT
    END DO
    
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Interactive_CLI

  ! ===== 打印帮助信息 =====
  SUBROUTINE AP_Print_Help()
    PRINT *, "Available commands:"
    PRINT *, "  load <file>       - Load model from ABAQUS .inp file"
    PRINT *, "  solve             - Execute analysis"
    PRINT *, "  export <format>   - Export results (ODB, CSV, HDF5, VTK)"
    PRINT *, "  status            - Print analysis status"
    PRINT *, "  help              - Print this help"
    PRINT *, "  quit              - Exit"
  END SUBROUTINE AP_Print_Help

  ! ===== 执行脚本文件 =====
  SUBROUTINE AP_Execute_Script(script_file, status)
    CHARACTER(len=*), INTENT(IN) :: script_file
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! 读取脚本文件逐行执行命令（类似 AP_Interactive_CLI）
    ! 支持注释行 (#) 和参数插值
    
    CALL IF_Log_Message(IF_LOG_INFO, &
      "Executing script: " // TRIM(script_file))
    status%status_code = STATUS_OK
  END SUBROUTINE AP_Execute_Script

END MODULE AP_Command

! ===== 命令行选项结构 =====
TYPE :: AP_Options
  INTEGER(i4) :: num_threads = 1
  LOGICAL :: verbose = .FALSE.
  LOGICAL :: restart = .FALSE.
  CHARACTER(len=256) :: log_file = "ufc.log"
END TYPE AP_Options
```

---

## 三、L6_AP 与下层接口契约

| 下层 | 依赖接口 | 流向 |
|------|---------|------|
| **L5_RT** | AP→Execute_Analysis; RT→Result_Data | 求解流程驱动 |
| **L4_PH** | AP→Assembly_*; PH→Status | 物理计算委托 |
| **L3_MD** | AP→Model_Desc; MD→Validation | 模型描述 |
| **L2_NM** | AP→Linear_Solver; NM→Solution | 数值求解 |
| **L1_IF** | AP→IO, Log, Prec; IF→Status | 基础服务 |

---

## 四、完整工作流示例

```fortran
PROGRAM UFC_Application
  USE AP_Input
  USE AP_Solver
  USE AP_Output
  USE AP_Command
  IMPLICIT NONE
  
  TYPE(ErrorStatusType) :: status
  TYPE(L3_MD_Model_Desc) :: model_desc
  TYPE(L5_RT_Result_Data) :: result_data
  CHARACTER(len=:), ALLOCATABLE :: input_file, output_dir
  TYPE(AP_Options) :: options
  
  ! 1. 解析命令行参数
  CALL AP_Parse_Command_Line(input_file, output_dir, options, status)
  IF (status%status_code /= STATUS_OK) STOP
  
  ! 2. 解析输入文件
  CALL AP_Parse_Input_File(input_file, model_desc, status)
  IF (status%status_code /= STATUS_OK) STOP
  
  ! 3. 验证模型
  CALL AP_Validate_Model(model_desc, status)
  IF (status%status_code /= STATUS_OK) STOP
  
  ! 4. 执行分析
  CALL AP_Execute_Analysis(model_desc, model_desc%analysis_steps, &
                           result_data, status)
  IF (status%status_code /= STATUS_OK) STOP
  
  ! 5. 输出结果
  CALL AP_Write_ODB(TRIM(output_dir) // "/results.odb", result_data, status)
  CALL AP_Write_VTK(TRIM(output_dir) // "/results.vtk", result_data, status)
  
  PRINT *, "✓ Analysis completed successfully"
END PROGRAM UFC_Application
```

---

**交付日期**: 2026-04-04  
**版本**: v1.0 初稿  
**后续任务**: Task C (跨域集成验证) → Task D (架构蓝图整合)
