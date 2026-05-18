## UI 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：UI / 用户界面
- **缩写**：AP_UI (`AP_UI_*`)
- **职责**：提供命令行界面 (CLI)、图形界面 (GUI) 框架、交互式建模工具；支持参数输入、模型可视化、结果后处理。
- **四型配置**：
  - **Desc**：窗口 TYPE、控件句柄、事件回调接口。
  - **State**：当前激活窗口、选中对象、交互模式。
  - **Ctx**：无。
  - **Algo**：事件循环、消息分发、数据绑定。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| CLI | Parse_Args, Run_Command, Show_Help | 命令行解析 |
| GUI | Create_Window, Add_Widget, Run_Event_Loop | 图形界面 |
| Viewer | Render_Mesh, Render_Contour, Render_Deformation | 模型/结果渲染 |
| Interact | Select_Node, Pick_Element, Measure_Distance | 交互操作 |

- **依赖**：IF_IO（输入输出）、AP_Output（结果导出）。
- **热路径**：**否** — UI 主要在前后处理阶段。
- **实现锚点**：
  - `AP_UI_Types.f90` — UI TYPE 定义
    ```fortran
    TYPE :: CommandLineArg
      CHARACTER(:), ALLOCATABLE :: flag      ! --input, --output
      CHARACTER(:), ALLOCATABLE :: value
      LOGICAL :: is_present = .FALSE.
    END TYPE CommandLineArg
    
    TYPE :: UIWindow
      CHARACTER(:), ALLOCATABLE :: title
      INTEGER(i4) :: width = 800_i4
      INTEGER(i4) :: height = 600_i4
      TYPE(UIWidget), ALLOCATABLE :: widgets(:)
      INTEGER(i4) :: num_widgets = 0_i4
      LOGICAL :: is_open = .TRUE.
    END TYPE UIWindow
    
    TYPE :: UIWidget
      CHARACTER(:), ALLOCATABLE :: name
      INTEGER(i4) :: widget_type  ! 1=BUTTON, 2=LABEL, 3=INPUT, 4=PLOT
      REAL(wp) :: x, y, w, h      ! 位置和尺寸
      PROCEDURE(Widget_Callback), NOPASS, POINTER :: callback => NULL()
    END TYPE UIWidget
    
    TYPE :: Viewer3D
      TYPE(Camera) :: camera
      REAL(wp) :: zoom = 1.0_wp
      REAL(wp) :: rotation_x = 0.0_wp
      REAL(wp) :: rotation_y = 0.0_wp
      LOGICAL :: show_axes = .TRUE.
      LOGICAL :: show_grid = .TRUE.
    END TYPE Viewer3D
    ```
  - `AP_UI_CLI.f90` — 命令行界面
    ```fortran
    SUBROUTINE Parse_Command_Line(args, argc, parsed_args)
      TYPE(CommandLineArg), ALLOCATABLE, INTENT(OUT) :: args(:)
      INTEGER(i4), INTENT(IN) :: argc
      INTEGER(i4), INTENT(OUT) :: parsed_args
      
      ! 伪代码：解析 argv[]
      ! DO i = 1, argc
      !   arg = GETARG(i)
      !   
      !   IF (arg(1:2) == '--') THEN
      !     ! 长选项
      !     eq_pos = INDEX(arg, '=')
      !     IF (eq_pos > 0) THEN
      !       flag = arg(3:eq_pos-1)
      !       value = arg(eq_pos+1:)
      !     ELSE
      !       flag = arg(3:)
      !       value = GETARG(i+1)  ! 下一个参数是值
      !       i = i + 1
      !     END IF
      !     
      !     ! 存入数组
      !     CALL Add_Argument(args, flag, value)
      !   ELSE IF (arg(1:1) == '-') THEN
      !     ! 短选项
      !     CALL Add_Argument(args, arg(2:), GETARG(i+1))
      !     i = i + 1
      !   ELSE
      !     ! 位置参数（输入文件）
      !     input_file = arg
      !   END IF
      ! END DO
      
      parsed_args = SIZE(args)
    END SUBROUTINE Parse_Command_Line
    
    FUNCTION Get_Argument(args, flag) RESULT(value)
      TYPE(CommandLineArg), INTENT(IN) :: args(:)
      CHARACTER(len=*), INTENT(IN) :: flag
      CHARACTER(:), ALLOCATABLE :: value
      
      ! 伪代码：查找指定 flag 的值
      DO i = 1, SIZE(args)
        IF (args(i)%flag == flag) THEN
          value = args(i)%value
          RETURN
        END IF
      END DO
      
      value = ''  ! 未找到
    END FUNCTION Get_Argument
    
    ! 使用示例：
    ! ./ufc_solver --input=model.bdf --output=results.vtk --threads=4
    ```
  - `AP_UI_GUI.f90` — 图形界面（以 ImGui 为例）
    ```fortran
    SUBROUTINE Run_Main_Window(viewer, model)
      TYPE(Viewer3D), INTENT(INOUT) :: viewer
      TYPE(ModelData), INTENT(IN) :: model
      
      ! 伪代码：ImGui 主循环
      ! DO WHILE (.TRUE.)
      !   ! 1. 开始帧
      !   CALL igNewFrame()
      !   
      !   ! 2. 菜单栏
      !   IF (igBeginMainMenuBar()) THEN
      !     IF (igBeginMenu("File", .TRUE.)) THEN
      !       IF (igMenuItem("Open...")) CALL Open_File_Dialog()
      !       IF (igMenuItem("Exit")) EXIT
      !       CALL igEndMenu()
      !     END IF
      !     
      !     IF (igBeginMenu("View", .TRUE.)) THEN
      !       igCheckbox("Show Axes", viewer%show_axes)
      !       igCheckbox("Show Grid", viewer%show_grid)
      !       CALL igEndMenu()
      !     END IF
      !     
      !     CALL igEndMainMenuBar()
      !   END IF
      !   
      !   ! 3. 3D 视图窗口
      !   igSetNextWindowSize(igVec2(800, 600), ImGuiCond_FirstUseEver)
      !   IF (igBegin("3D Viewer", viewer%is_open, &
      !               ImGuiWindowFlags_None)) THEN
      !     ! 获取窗口大小
      !     avail_size = igGetContentRegionAvail()
      !     
      !     ! 渲染模型（调用 OpenGL/DirectX）
      !     CALL Render_Model_OpenGL(model, viewer%camera, &
      !                              avail_size.x, avail_size.y)
      !   END IF
      !   igEnd()
      !   
      !   ! 4. 属性面板
      !   IF (igBegin("Properties", .TRUE., &
      !               ImGuiWindowFlags_AlwaysAutoResize)) THEN
      !     igInputFloat3("Camera Position", viewer%camera%position)
      !     igSliderFloat("Zoom", viewer%zoom, 0.1_wp, 10.0_wp)
      !   END IF
      !   igEnd()
      !   
      !   ! 5. 渲染
      !   CALL igRender()
      !   
      !   ! 6. 处理输入（鼠标/键盘）
      !   CALL Process_Input_Events(viewer)
      ! END DO
    END SUBROUTINE Run_Main_Window
    ```
  - `AP_UI_Viewer.f90` — 3D 查看器
    ```fortran
    SUBROUTINE Render_Model_OpenGL(model, camera, width, height)
      TYPE(ModelData), INTENT(IN) :: model
      TYPE(Camera), INTENT(IN) :: camera
      REAL(wp), INTENT(IN) :: width, height
      
      ! 伪代码：OpenGL 渲染流程
      ! 1. 设置视口
      ! glViewport(0, 0, INT(width), INT(height))
      ! 
      ! 2. 清除缓冲区
      ! glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
      ! 
      ! 3. 设置投影矩阵
      ! proj = Perspective_Camera(camera%fov, width/height, &
      !                           camera%near, camera%far)
      ! view = LookAt(camera%eye, camera%target, camera%up)
      ! 
      ! 4. 绘制网格
      ! IF (viewer%show_grid) THEN
      !   CALL Draw_Grid(10, 1.0_wp)
      ! END IF
      ! 
      ! 5. 绘制坐标轴
      ! IF (viewer%show_axes) THEN
      !   CALL Draw_Axes(5.0_wp)
      ! END IF
      ! 
      ! 6. 绘制有限元模型
      ! glBindVertexArray(model%vao)
      ! glDrawElements(GL_LINES, model%num_indices, &
      !                GL_UNSIGNED_INT, 0_C_INTPTR)
      ! 
      ! 7. 绘制云图（如需要）
      ! IF (show_contour) THEN
      !   CALL_Draw_Contour(model%displacements, color_map)
      ! END IF
    END SUBROUTINE Render_Model_OpenGL
    ```
  - `AP_UI_Interact.f90` — 交互操作（拾取、测量等）

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_UI_xxx`（60800–60899） |
| 严重级 | Warning / Error（渲染失败为 Warning，事件循环崩溃为 Error） |
| 传播规则 | UI 错误记录日志并显示用户友好消息，不向下层传播 |
| 恢复策略 | 渲染错误降级至线框模式 + Warning；CLI 解析错误显示帮助信息 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L6_AP/Job | S(消费) | 消费 Job 提供的作业状态用于进度显示 |
| 2 | L6_AP/Output | S(消费) | 消费 Output 数据用于结果可视化 |
| 3 | L5_RT/StepDriver | B(桥接) | 通过 status callbacks 桥接步驱动进度 |
| 4 | L1_IF/Log | U(USE) | Fortran USE 日志模块（IF_Log） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| CLI 参数解析与帮助信息一致 | 硬约束 | 单元测试 | CI |
| 进度回调不阻塞求解器主线程 | 硬约束 | 集成测试 | CI |
| GUI 渲染帧率 ≥ 30fps（交互模式） | 软约束 | 性能测试 | Nightly |
| 跨平台 UI 兼容（Linux/Windows） | 软约束 | 跨平台 CI | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | CommandLineArg / UIWindow / UIWidget | CLI 参数与 GUI 控件描述 |
| 2 | State | Viewer3D + 交互模式/选中对象 | 视图状态与用户交互状态 |
| 3 | Algo | 事件循环 / 消息分发 / 数据绑定 | GUI 事件处理与渲染 |
| 4 | Ctx | 无 | UI 无持久运行时上下文 |
| 5 | Arg (SIO) | 无 | UI 不在热路径 |
| 6 | Proc | AP_UI_CLI/GUI/Viewer/Interact.f90 | UI 过程模块 |
| 7 | Test | UI 单元测试 | CLI 解析 + 事件分发正确性 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无（消费 AP_Config） | UI 选项来自 Config 域 |
| 10 | Error | ERR_L6_UI_xxx | 60800–60899 |
| 11 | Domain | AP_UI 域 | L6_AP/UI/ |
| 12 | Registry | 无 | 不注册为服务 |
| 13 | Doc | 本合同 + 交互说明 | CLI/GUI 使用指南 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 用户交互理论→事件驱动架构→MVC 模式 |
| **逻辑链** | 用户输入→CLI/GUI 解析→Job/Output 调用→结果渲染/进度显示 |
| **计算链** | 无 FEM 计算；3D 渲染使用 OpenGL/ImGui |
| **数据链** | 用户命令→CommandLineArg→Job 参数；L4 State→FieldData→可视化 |

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
| `AP_UI.f90` | `AP_UI` | `AP_UI_Init_In`, `AP_UI_Init_Out`, `AP_UI_Progress_Init_In`, `AP_UI_Progress_Init_Out`, `AP_UI_Progress_Update_In`, `AP_UI_Progress_Update_Out`, `AP_UI_Print_In`, `AP_UI_Print_Out`, `AP_UI_Ctrl_Type` | `Init` (TBP,PRV,—); `Cleanup` (TBP,PRV,—); `SetMode` (TBP,PRV,—); `SetVerbose` (TBP,PRV,—); `cmd_callback` (SUB,PRV,—); `AP_UI_Init_Structured` (SUB,PRV,Init); `AP_UI_Progress_Init_Structured` (SUB,PRV,Init); `AP_UI_Progress_Update_Structured` (SUB,PRV,Compute); `AP_UI_Print_Structured` (SUB,PRV,IO); `AP_UI_Ctrl_Init` (SUB,PRV,Init); `AP_UI_Ctrl_Cleanup` (SUB,PRV,Finalize); `AP_UI_Ctrl_SetMode` (SUB,PRV,Mutate); `AP_UI_Ctrl_SetVerbose` (SUB,PRV,Mutate); `AP_UI_Progress_Init` (SUB,PUB,Init); `AP_UI_Progress_Update` (SUB,PUB,Compute); `AP_UI_Progress_Finish` (SUB,PUB,—); `AP_UI_Progress_SetDescription` (SUB,PRV,Mutate); `AP_UI_Command_Init` (SUB,PRV,Init); `AP_UI_Command_Cleanup` (SUB,PRV,Finalize); `AP_UI_Command_AddArg` (SUB,PRV,Mutate); `AP_UI_Command_Execute` (SUB,PRV,—); `AP_UI_Init` (SUB,PUB,Init); `AP_UI_Cleanup` (SUB,PUB,Finalize); `AP_UI_Print` (SUB,PUB,IO); `AP_UI_PrintInfo` (SUB,PUB,IO); `AP_UI_PrintWarning` (SUB,PUB,IO); `AP_UI_PrintError` (SUB,PUB,IO); `AP_UI_PrintSuccess` (SUB,PUB,IO); `AP_UI_PrintHeader` (SUB,PUB,IO); `AP_UI_PrintTable` (SUB,PUB,IO); `AP_UI_ReadLine` (SUB,PUB,Parse); `AP_UI_Confirm` (FN,PUB,—); `AP_UI_IsInteractive` (FN,PUB,Query); `AP_UI_GetTerminalWidth` (FN,PUB,Query); `AP_UI_GetMode` (FN,PUB,Query) |
| `AP_UI_Domain.f90` | `AP_UIDomain` | `AP_UI_State`, `AP_UI_Ctrl`, `AP_UI_RegisterCommand_Arg`, `AP_UI_ExecuteCommand_Arg`, `AP_UI_GetSummary_Arg`, `AP_UIDomain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `RegisterCommand` (TBP,PRV,—); `ExecuteCommand` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AddCommandHistory` (TBP,PRV,—); `AddTreeNode` (TBP,PRV,—); `GetHistoryById` (TBP,PRV,—); `GetNodeById` (TBP,PRV,—); `AP_UI_Domain_Finalize` (SUB,PRV,Finalize); `AP_UI_Domain_Init` (SUB,PRV,Init); `AP_UI_Domain_RegisterCommand` (SUB,PRV,—); `AP_UI_RegisterCommand_Impl` (SUB,PRV,—); `AP_UI_Domain_ExecuteCommand` (SUB,PRV,—); `AP_UI_ExecuteCommand_Impl` (SUB,PRV,—); `AP_UI_Domain_GetSummary` (SUB,PRV,Query); `AP_UI_GetSummary_Impl` (SUB,PRV,Query); `AP_UI_Domain_AddCommandHistory` (SUB,PRV,Mutate); `AP_UI_Domain_AddTreeNode` (SUB,PRV,Mutate); `AP_UI_Domain_GetHistoryById` (SUB,PRV,Query); `AP_UI_Domain_GetNodeById` (SUB,PRV,Query) |
| `AP_UIINP.f90` | `AP_UI_INP_Core` | `INPGenerator` | — |
| `AP_UI_JobMgr.f90` | `AP_UIJobMgr` | `UIJob`, `RT_JobMgr` | `Init` (TBP,PRV,—); `CreateJob` (TBP,PRV,—); `SubmitJob` (TBP,PRV,—); `GetJobStatus` (TBP,PRV,—); `CancelJob` (TBP,PRV,—); `GetJobLog` (TBP,PRV,—); `MonitorJob` (TBP,PRV,—); `GetJob` (TBP,PRV,—); `GetJobByName` (TBP,PRV,—); `UpdateJobProgress` (TBP,PRV,—); `RT_JobMgr_Init` (SUB,PRV,Init); `RT_JobMgr_Create` (SUB,PUB,Init); `RT_JobMgr_Submit` (SUB,PUB,—); `RT_JobMgr_GetStat` (FN,PUB,Query); `RT_JobMgr_Cancel` (SUB,PUB,—); `RT_JobMgr_GetLog` (FN,PUB,Query); `RT_JobMgr_Mon` (SUB,PRV,—); `RT_JobMgr_Get` (FN,PRV,Query); `RT_JobMgr_GetByName` (FN,PRV,Query); `RT_JobMgr_UpdateProg` (SUB,PRV,Compute); `ParseLogFileProgress` (SUB,PRV,—) |
| `AP_UI_ModelMgr.f90` | `AP_UIModelMgr` | `ValidRes`, `ValidMgr` | `Init` (TBP,PRV,—); `ValidateModel` (TBP,PRV,—); `ValidateNode` (TBP,PRV,—); `CheckDependencies` (TBP,PRV,—); `GetValidationReport` (TBP,PRV,—); `ValidatePart` (TBP,PRV,—); `ValidateMaterial` (TBP,PRV,—); `ValidateSection` (TBP,PRV,—); `ValidateStep` (TBP,PRV,—); `ValidateLoadBC` (TBP,PRV,—); `ValidMgr_Init` (SUB,PRV,Init); `ValidMgr_ValidModel` (SUB,PUB,Validate); `ValidMgr_ValidNode` (SUB,PUB,Validate); `ValidMgr_ChkDep` (SUB,PUB,—); `ValidMgr_GetRpt` (FN,PUB,Query); `ValidMgr_ValidatePart` (SUB,PRV,Validate); `ValidMgr_ValidateMaterial` (SUB,PRV,Validate); `ValidMgr_ValidateSection` (SUB,PRV,Validate); `ValidMgr_ValidateStep` (SUB,PRV,Validate); `ValidMgr_ValidateLoadBC` (SUB,PRV,Validate); `AddError` (SUB,PRV,—); `AddWarning` (SUB,PRV,—); `PropertyMgr_Init` (SUB,PRV,Init); `PropertyMgr_GetForm` (FN,PUB,Query); `PropertyMgr_GetFieldValue` (FN,PUB,Query); `PropertyMgr_SetFieldValue` (SUB,PUB,Mutate); `PropertyMgr_ValidateForm` (FN,PUB,Validate); `PropertyMgr_ApplyChanges` (SUB,PUB,—); `PropMgr_CreateFormForNodeType` (SUB,PRV,Init) |
| `AP_UI_TreeMgr.f90` | `AP_UITreeMgr` | `TreeMgr` | `Init` (TBP,PRV,—); `CreateNode` (TBP,PRV,—); `DeleteNode` (TBP,PRV,—); `RenameNode` (TBP,PRV,—); `GetNodeData` (TBP,PRV,—); `SetNodeData` (TBP,PRV,—); `GetChildren` (TBP,PRV,—); `MoveNode` (TBP,PRV,—); `GetNodePath` (TBP,PRV,—); `FindNodeByName` (TBP,PRV,—); `ValidateNode` (TBP,PRV,—); `TreeMgr_Init` (SUB,PRV,Init); `TreeMgr_CreateNode` (SUB,PUB,Init); `CreatePartNode` (SUB,PRV,—); `CreateMaterialNode` (SUB,PRV,—); `CreateSectionNode` (SUB,PRV,—); `CreateStepNode` (SUB,PRV,—); `TreeMgr_DeleteNode` (SUB,PUB,Mutate); `TreeMgr_RenameNode` (SUB,PUB,—); `TreeMgr_GetNodeData` (FN,PUB,Query); `TreeMgr_SetNodeData` (SUB,PUB,Mutate); `TreeMgr_GetChildren` (SUB,PUB,Query); `TreeMgr_MoveNode` (SUB,PUB,—); `TreeMgr_GetNodePath` (FN,PUB,Query); `TreeMgr_FindNodeByName` (FN,PUB,Query); `TreeMgr_ValidateNode` (FN,PRV,Validate) |
| `AP_UI_Def.f90` | `AP_UI_Def` | `CommandHistoryEntry`, `UITreeNodeEntry` | — |
