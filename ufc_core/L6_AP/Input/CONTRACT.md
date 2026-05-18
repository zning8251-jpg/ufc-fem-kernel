## Input 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：Input / 用户输入处理
- **缩写**：AP_Input (`AP_Input_*`)
- **职责**：提供有限元模型输入解析、网格/材料/边界条件读取；支持 Nastran/Abaqus/ANSYS格式导入。
- **四型配置**：
  - **Desc**：输入卡片 TYPE、单元类型表、材料库结构。
  - **State**：当前解析状态、已读入节点/单元计数。
  - **Ctx**：无。
  - **Algo**：词法分析、语法解析、数据验证。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Mesh | Read_Nodes, Read_Elements, Read_Sets | 网格导入 |
| Material | Read_Material, Assign_Material | 材料定义 |
| BC | Read_Boundary_Conditions, Read_Loads | 边界条件 |
| Convert | Import_Nastran, Import_Abaqus | 格式转换 |

- **依赖**：IF_IO（文件读写）、L3_MD（模型数据）。
- **热路径**：**否** — 输入处理仅在预处理阶段。
- **Field initial condition 规则**：`Cmd_InitialConditions` / `Cmd_PredefinedField` 只负责命令参数解析与上下文校验；持久模型写入应经 `AP_Brg_L3` 调用 L3 Field 合同（`MD_Field_Define` / `MD_Field_Set_InitCond`）或 KeyWord 域共用 helper，避免在 L6_AP 形成第二套 Field 真源。
- **实现锚点**：
  - `AP_Input_Types.f90` — 输入数据结构
    ```fortran
    TYPE :: NodeInput
      INTEGER(i4) :: node_id
      REAL(wp) :: x, y, z
      INTEGER(i4) :: dof_mask  ! 位掩码：1=UX, 2=UY, 4=UZ, 8=RX, ...
    END TYPE NodeInput
    
    TYPE :: ElementInput
      INTEGER(i4) :: elem_id
      INTEGER(i4) :: elem_type  ! 1=BAR, 2=BEAM, 11=QUAD4, 21=HEX8
      INTEGER(i4) :: material_id
      INTEGER(i4), ALLOCATABLE :: connectivity(:)
      REAL(wp) :: properties(10)  ! 截面属性（面积、惯性矩等）
    END TYPE ElementInput
    
    TYPE :: ModelInput
      TYPE(NodeInput), ALLOCATABLE :: nodes(:)
      TYPE(ElementInput), ALLOCATABLE :: elements(:)
      INTEGER(i4) :: num_nodes = 0_i4
      INTEGER(i4) :: num_elements = 0_i4
    END TYPE ModelInput
    ```
  - `AP_Input_Mesh.f90` — 网格读取
    ```fortran
    SUBROUTINE Read_Nodes_BDF(input, file_path, iostat)
      TYPE(ModelInput), INTENT(INOUT) :: input
      CHARACTER(len=*), INTENT(IN) :: file_path
      INTEGER(i4), INTENT(OUT) :: iostat
      
      ! Nastran BDF 格式：GRID, ID, , X, Y, Z
      ! 伪代码：
      ! 1. 打开文件，查找 GRID 卡片
      ! 2. 解析字段（逗号分隔）
      ! 3. 存入 nodes 数组
      
      OPEN(unit=10, file=file_path, status='old', iostat=iostat)
      IF (iostat /= 0) RETURN
      
      DO WHILE (.TRUE.)
        READ(10, '(A)', iostat=iostat) line
        IF (iostat /= 0) EXIT
        
        ! 跳过注释和空行
        IF (line(1:1) == '$' .OR. TRIM(line) == '') CYCLE
        
        ! 识别 GRID 卡片
        IF (line(1:4) == 'GRID') THEN
          ! 解析字段（固定宽度或逗号分隔）
          READ(line(9:16), *) node_id
          READ(line(25:33), *) x
          READ(line(33:41), *) y
          READ(line(41:49), *) z
          
          ! 扩容并添加
          IF (input%num_nodes >= SIZE(input%nodes)) &
            CALL Reallocate_Nodes(input)
          
          input%num_nodes = input%num_nodes + 1
          idx = input%num_nodes
          input%nodes(idx)%node_id = node_id
          input%nodes(idx)%x = x
          input%nodes(idx)%y = y
          input%nodes(idx)%z = z
        END IF
      END DO
      
      CLOSE(10)
    END SUBROUTINE Read_Nodes_BDF
    
    SUBROUTINE Read_Elements_BDF(input, file_path, iostat)
      ! CBEAM, CBAR, CHEXA, CTETRA 解析
      ! 伪代码：类似节点读取，额外解析：
      ! - 单元类型映射（CBEAM -> elem_type=2）
      ! - 连接性（G1, G2, G3, G4）
      ! - 材料 ID（MID 字段）
      ! - 截面属性（PID 字段）
    END SUBROUTINE Read_Elements_BDF
    ```
  - `AP_Input_Material.f90` — 材料定义
    ```fortran
    SUBROUTINE Read_Material_MAT1(input, mat_id, E, nu, rho)
      ! Nastran MAT1 卡片：MAT1, MID, E, G, NU, RHO, ...
      ! 伪代码：
      ! 1. 查找 MAT1 卡片
      ! 2. 提取 E（杨氏模量）、NU（泊松比）、RHO（密度）
      ! 3. 存入材料库
      ! MAT1, 1, 2.1E11, , 0.3, 7850.
    END SUBROUTINE Read_Material_MAT1
    ```
  - `AP_Input_BC.f90` — 边界条件与载荷
  - `AP_Input_Convert.f90` — 格式转换器（BDF/INP/CDB）

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_INPUT_xxx`（60300–60399） |
| 严重级 | Warning / Error / Fatal（文件不存在为 Fatal，语法错误为 Error） |
| 传播规则 | 解析错误附加行号/文件名上下文后传播至 Job 调用方 |
| 恢复策略 | 未知关键字跳过 + Warning；必需参数缺失返回 Error；文件不可读返回 Fatal |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L3_MD/KeyWord | T(合同) | 关键字解析结果正式写入 L3 关键字注册表 |
| 2 | L3_MD/Element/Mesh | B(桥接) | 桥接网格数据（节点/单元）至 L3 Mesh 域 |
| 3 | L3_MD/Material | B(桥接) | 桥接材料定义至 L3 Material 域 |
| 4 | L3_MD/Boundary | B(桥接) | 桥接边界条件至 L3 Boundary 域 |
| 5 | L3_MD/Analysis | B(桥接) | 桥接分析步定义至 L3 Analysis 域 |
| 6 | L3_MD/Interaction | B(桥接) | 桥接接触对定义至 L3 Interaction 域 |
| 7 | L6_AP/Config | S(消费) | 消费 Config 提供的解析选项与格式设置 |
| 8 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_IO） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| INP/BDF 格式解析覆盖标准关键字集 | 硬约束 | 关键字测试套件 | PR 合入 |
| 解析结果与 L3_MD 类型签名一致 | 硬约束 | 编译期 + 集成测试 | CI |
| 错误消息包含文件名与行号 | 硬约束 | 单元测试 | CI |
| 多格式自动检测（BDF/INP/CDB） | 软约束 | 集成测试 | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | NodeInput / ElementInput / ModelInput | 输入数据结构定义 |
| 2 | State | 解析状态（已读节点/单元计数） | 当前解析进度 |
| 3 | Algo | 词法分析 / 语法解析 / 数据验证 | BDF/INP/CDB 解析器 |
| 4 | Ctx | 无 | 预处理阶段无运行时上下文 |
| 5 | Arg (SIO) | 无 | 预处理阶段，不需要 *_Arg |
| 6 | Proc | AP_Input_Mesh/Material/BC/Convert.f90 | 解析过程模块 |
| 7 | Test | Input 单元测试 | 多格式解析正确性 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无（消费 AP_Config） | 解析选项来自 Config 域 |
| 10 | Error | ERR_L6_INPUT_xxx | 60300–60399 |
| 11 | Domain | AP_Input 域 | L6_AP/Input/ |
| 12 | Registry | 无 | 不注册为服务 |
| 13 | Doc | 本合同 + 格式规范 | 支持格式说明 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | ABAQUS/Nastran 输入格式规范→关键字语法树→L3 模型类型映射 |
| **逻辑链** | INP/BDF 文件→词法/语法解析→分派至 L3 Mesh/Material/BC/Analysis/Interaction |
| **计算链** | 无直接计算；坐标变换与单位转换在解析阶段完成 |
| **数据链** | 文件字符流→NodeInput/ElementInput→L3_MD Desc 类型→模型树 |

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
| `AP_Inp_Mgr.f90` | `AP_InpMgr` | — | `AP_Input_Mgr_Init` (SUB,PUB,Init); `AP_Input_Mgr_AddKeyword` (SUB,PUB,Mutate); `AP_Input_Mgr_AddCommand` (SUB,PUB,Mutate); `AP_Input_Mgr_GetKeyword` (SUB,PUB,Query); `AP_Input_Mgr_GetCmd` (SUB,PUB,Query); `AP_Input_Mgr_GetKeywordCount` (FN,PUB,Query); `AP_Input_Mgr_GetCmdCount` (FN,PUB,Query) |
| `AP_Inp_Def.f90` | `AP_Inp_Def` | `ParsedKeywordEntry`, `ParsedCommandEntry` | — |
| `Command/AP_InpCmdMgr.f90` | `AP_InpCmdMgr` | — | `AP_Cmd_Mgr_Init` (SUB,PUB,Init); `AP_Cmd_Mgr_Finalize` (SUB,PUB,Finalize); `AP_Cmd_Mgr_AddCommand` (SUB,PUB,Mutate); `AP_Cmd_Mgr_AddHandler` (SUB,PUB,Mutate); `AP_Cmd_Mgr_AddHistory` (SUB,PUB,Mutate); `AP_Cmd_Mgr_GetCommand` (SUB,PUB,Query); `AP_Cmd_Mgr_GetHandler` (SUB,PUB,Query); `AP_Cmd_Mgr_GetHandlerByName` (SUB,PUB,Query); `AP_Cmd_Mgr_GetHistory` (SUB,PUB,Query); `AP_Cmd_Mgr_GetCommandCount` (FN,PUB,Query); `AP_Cmd_Mgr_GetHandlerCount` (FN,PUB,Query); `AP_Cmd_Mgr_GetHistoryCount` (FN,PUB,Query) |
| `Command/AP_InpDomain.f90` | `AP_InpDomain` | `AP_Cmd_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `AddCommand` (TBP,PRV,—); `AddHandler` (TBP,PRV,—); `AddHistory` (TBP,PRV,—); `GetCommandById` (TBP,PRV,—); `GetHandlerById` (TBP,PRV,—); `GetHandlerByName` (TBP,PRV,—); `GetHandlerIndexByName` (TBP,PRV,—); `GetHistoryById` (TBP,PRV,—); `ClearHistory` (TBP,PRV,—); `ClearCommands` (TBP,PRV,—); `AP_Cmd_Domain_Finalize` (SUB,PRV,Finalize); `AP_Cmd_Domain_Init` (SUB,PRV,Init); `AP_Cmd_Domain_AddCommand` (SUB,PRV,Mutate); `AP_Cmd_Domain_AddHandler` (SUB,PRV,Mutate); `AP_Cmd_Domain_AddHistory` (SUB,PRV,Mutate); `AP_Cmd_Domain_GetCommandById` (SUB,PRV,Query); `AP_Cmd_Domain_GetHandlerById` (SUB,PRV,Query); `AP_Cmd_Domain_GetHandlerByName` (SUB,PRV,Query); `AP_Cmd_Domain_GetHistoryById` (SUB,PRV,Query); `AP_Cmd_Domain_GetHandlerIndexByName` (SUB,PRV,Query); `AP_Cmd_Domain_ClearHistory` (SUB,PRV,Mutate); `AP_Cmd_Domain_ClearCommands` (SUB,PRV,Mutate) |
| `Command/AP_InpInit.f90` | `AP_InpInit` | — | `Cmd_InitialConditions` (SUB,PUB,Init); `Cmd_PredefinedField` (SUB,PUB,—); `Cmd_Restart` (SUB,PUB,—); `UF_Cmd_Init_RegAll` (SUB,PUB,Init) |
| `Command/AP_InpInitCore.f90` | `AP_InpInitCore` | — | `Cmd_GeostaticStress` (SUB,PRV,—); `Cmd_InitialState` (SUB,PRV,Init); `Cmd_InitialTemperature` (SUB,PRV,Init); `Cmd_PredefinedField` (SUB,PRV,—); `UF_Cmd_Initial_RegAll` (SUB,PUB,Init) |
| `Command/AP_InpMat.f90` | `AP_InpMat` | — | `Cmd_Creep` (SUB,PRV,—); `Cmd_Damping` (SUB,PRV,—); `Cmd_Elastic` (SUB,PRV,—); `Cmd_Hyperelastic` (SUB,PRV,—); `Cmd_Plastic` (SUB,PRV,—); `Cmd_UserMaterial` (SUB,PRV,—); `Cmd_Viscoelastic` (SUB,PRV,—); `ParseMaterialParams` (SUB,PUB,—); `UF_Cmd_Mat_RegAll` (SUB,PUB,—) |
| `Command/AP_InpMemMgr.f90` | `AP_InpMemMgr` | — | `AP_Cmd_MemMgr_Init` (SUB,PUB,Init); `AP_Cmd_MemMgr_Shutdown` (SUB,PUB,—); `AP_Cmd_MemMgr_Alloc` (SUB,PUB,—); `AP_Cmd_MemMgr_Free` (SUB,PRV,Finalize); `AP_Cmd_MemMgr_Stats` (SUB,PRV,—); `cmd_pool_init` (SUB,PUB,Init); `cmd_pool_shutdown` (SUB,PUB,—); `cmd_pool_alloc` (SUB,PUB,—); `cmd_pool_free` (SUB,PUB,Finalize); `cmd_pool_stats` (SUB,PUB,—) |
| `Command/AP_InpMesh.f90` | `AP_InpMesh` | — | `Cmd_Elem` (SUB,PUB,—); `Cmd_Elgen` (SUB,PUB,—); `Cmd_Elset` (SUB,PUB,—); `Cmd_Ngen` (SUB,PUB,—); `Cmd_Node` (SUB,PUB,—); `Cmd_Nset` (SUB,PUB,—); `Cmd_Orientation` (SUB,PUB,—); `Cmd_Surface` (SUB,PUB,—); `map_Elem_type` (SUB,PRV,—) |
| `Command/AP_InpSect.f90` | `AP_InpSect` | — | `Cmd_CohesiveSection` (SUB,PRV,—); `Cmd_Layer` (SUB,PRV,—); `Cmd_MembraneSection` (SUB,PRV,—); `Cmd_Section` (SUB,PRV,—); `Cmd_SectionAssign` (SUB,PRV,—); `Cmd_SectionControls` (SUB,PRV,—); `UF_Cmd_Sect_RegAll` (SUB,PUB,—) |
| `Command/AP_InpStep.f90` | `AP_InpStep` | — | `Cmd_Buckling` (SUB,PRV,—); `Cmd_CoupledTempDisp` (SUB,PRV,—); `Cmd_Dynamic` (SUB,PRV,—); `Cmd_Explicit` (SUB,PRV,—); `Cmd_Frequency` (SUB,PRV,—); `Cmd_HeatTransfer` (SUB,PRV,—); `Cmd_Modal` (SUB,PRV,—); `Cmd_Static` (SUB,PRV,—); `Cmd_Step` (SUB,PRV,—); `UF_Cmd_Step_RegAll` (SUB,PUB,—) |
| `Command/AP_Inp_Def.f90` | `AP_Inp_Def` | `Cmd`, `UF_Command`, `CmdMacroDef`, `CmdMacroCtx`, `CmdCtx`, `UF_CommandCtx`, `CmdHandler`, `HistoryEntry`, `CommandDesc`, `CommandLogEntry`, `Proc`, `UF_Procedure`, `CmdList`, `UF_CommandList` | — |
| `Parser/AP_Inp.f90` | `AP_Inp` | `AP_Input_State`, `AP_Input_Ctrl`, `AP_Input_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `ParseKeyword` (TBP,PRV,—); `ValidateSyntax` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AddParsedKeyword` (TBP,PRV,—); `AddParsedCommand` (TBP,PRV,—); `GetKeywordById` (TBP,PRV,—); `GetCmdById` (TBP,PRV,—); `AP_Input_Domain_Finalize` (SUB,PRV,Finalize); `AP_Input_Domain_Init` (SUB,PRV,Init); `AP_Input_Domain_ParseKeyword` (SUB,PRV,Parse); `AP_Input_Domain_ValidateSyntax` (SUB,PRV,Validate); `AP_Input_Domain_GetSummary` (SUB,PRV,Query); `AP_Input_Domain_AddParsedKeyword` (SUB,PRV,Mutate); `AP_Input_Domain_AddParsedCommand` (SUB,PRV,Mutate); `AP_Input_Domain_GetKeywordById` (SUB,PRV,Query); `AP_Input_Domain_GetCmdById` (SUB,PRV,Query) |
| `Parser/AP_InpDomain.f90` | `AP_Inp` | `AP_Input_State`, `AP_Input_Ctrl`, `AP_Input_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `ParseKeyword` (TBP,PRV,—); `ValidateSyntax` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AddParsedKeyword` (TBP,PRV,—); `AddParsedCommand` (TBP,PRV,—); `GetKeywordById` (TBP,PRV,—); `GetCmdById` (TBP,PRV,—); `AP_Input_Domain_Finalize` (SUB,PRV,Finalize); `AP_Input_Domain_Init` (SUB,PRV,Init); `AP_Input_Domain_ParseKeyword` (SUB,PRV,Parse); `AP_Input_Domain_ValidateSyntax` (SUB,PRV,Validate); `AP_Input_Domain_GetSummary` (SUB,PRV,Query); `AP_Input_Domain_AddParsedKeyword` (SUB,PRV,Mutate); `AP_Input_Domain_AddParsedCommand` (SUB,PRV,Mutate); `AP_Input_Domain_GetKeywordById` (SUB,PRV,Query); `AP_Input_Domain_GetCmdById` (SUB,PRV,Query) |
| `Parser/AP_InpKWBrg.f90` | `AP_InpKWBrg` | — | `UF_Cmd_KWBrg_Init` (SUB,PUB,Init); `UF_Cmd_KWBrg_RegAddMetadata` (SUB,PUB,—); `UF_Cmd_KWBrg_Sync` (SUB,PUB,Populate); `UF_Cmd_KWBrg_ConvKw2CmdName` (FN,PRV,—); `UF_Cmd_KWBrg_BldSyntax` (SUB,PRV,—); `UF_Cmd_KWBrg_BldParams` (SUB,PRV,—); `UF_Cmd_KWBrg_BldExample` (SUB,PRV,—); `UF_Cmd_KWBrg_GetCmdName` (FN,PRV,Query); `UF_Cmd_KWBrg_ConvKw` (SUB,PUB,—) |
| `Parser/AP_InpParam.f90` | `AP_InpParam` | — | `ParseArray` (SUB,PUB,—); `ParseKeyValue` (SUB,PUB,—); `ParseKeyValueInt` (SUB,PUB,—); `PARSEKEYVALUERE` (SUB,PUB,—); `ParseKeyValueStr` (SUB,PUB,—); `ParseQuotedString` (SUB,PUB,—); `SplitString` (SUB,PUB,—) |
| `Parser/AP_InpParserUtil.f90` | `AP_InpParserUtil` | — | `AP_Pa_Un_Execute` (SUB,PRV,—); `AP_Parse_ExtractQuotedString` (SUB,PUB,Parse); `AP_Parse_NormalizeLine` (FN,PUB,Parse); `AP_Parse_RemoveComments` (FN,PUB,Mutate); `AP_Parse_SplitTokens` (SUB,PUB,Parse); `AP_Parse_TrimWhitespace` (FN,PUB,Parse); `AP_ParserUtils_Unified_Cfg` (SUB,PUB,Parse) |
| `Parser/AP_ParserInclude.f90` | `AP_ParserInclude` | `AP_Parser_Include_Props` | `Init` (TBP,PRV,—); `Valid` (TBP,PRV,—); `Clear` (TBP,PRV,—); `AP_Parser_Include_Init` (SUB,PRV,Init); `AP_Parser_Include_Valid` (SUB,PRV,Validate); `AP_Parser_Include_Clear` (SUB,PRV,Mutate); `AP_Parser_Include_Parse` (SUB,PUB,Parse); `get_param_value` (SUB,PRV,—); `Parse_INCLUDE_Keyword` (SUB,PUB,—); `AP_Parser_UnifiedParse` (SUB,PUB,Parse); `AP_Parser_Unified_Parse` (SUB,PUB,Parse); `AP_Parser_UnifiedCfg` (SUB,PUB,Parse); `AP_Parser_Unified_Cfg` (SUB,PUB,Parse); `AP_Parser_Include_ValidKw` (SUB,PUB,Validate); `Valid_INCLUDE_Keyword` (SUB,PUB,—) |
| `Parser/AP_ParserUtil.f90` | `AP_ParserUtil` | — | `AP_Pa_Un_Execute` (SUB,PRV,—); `AP_Parse_ExtractQuotedString` (SUB,PUB,Parse); `AP_Parse_NormalizeLine` (FN,PUB,Parse); `AP_Parse_RemoveComments` (FN,PUB,Mutate); `AP_Parse_SplitTokens` (SUB,PUB,Parse); `AP_Parse_TrimWhitespace` (FN,PUB,Parse); `AP_ParserUtils_Unified_Cfg` (SUB,PUB,Parse) |
| `Script/AP_InpScript.f90` | `AP_InpScript` | `Cmd_HistoryAdd_In`, `Cmd_HistoryAdd_Out`, `Cmd_HistoryGet_In`, `Cmd_HistoryGet_Out`, `Cmd_HistoryClear_Out`, `Cmd_HistoryInit_In`, `Cmd_HistoryInit_Out`, `Cmd_LabelRegister_In`, `Cmd_LabelRegister_Out`, `Cmd_LabelResolve_In`, `Cmd_LabelResolve_Out`, `Cmd_Exec_In`, `Cmd_Exec_Out` | `Cmd_Exec` (SUB,PUB,—); `Cmd_HistoryInit` (SUB,PUB,—); `Cmd_HistoryAdd` (SUB,PUB,—); `Cmd_HistoryAddEntry` (SUB,PUB,—); `Cmd_HistoryGet` (SUB,PUB,—); `Cmd_HistoryClear` (SUB,PUB,—); `Cmd_LabelRegister` (SUB,PUB,—); `Cmd_LabelResolve` (FN,PUB,—); `LabelGetCmd` (SUB,PRV,—) |
| `Script/AP_InpScriptAlias.f90` | `AP_InpScriptAlias` | `AliasEntry`, `CmdAliasMgr` | `Init` (TBP,PRV,—); `Define` (TBP,PRV,—); `Resolve` (TBP,PRV,—); `Alias_Init` (SUB,PRV,Init); `Alias_Define` (SUB,PRV,—); `Alias_Resolve` (SUB,PRV,—); `Cmd_AliasDefine_Structured` (SUB,PUB,—); `Cmd_AliasResolve_Structured` (SUB,PUB,—); `Cmd_AliasDefine` (SUB,PUB,—); `Cmd_AliasResolve` (SUB,PUB,—) |
| `Script/AP_InpScriptDebug.f90` | `AP_InpScriptDebug` | `Cmd_DebugSetBrk_In`, `Cmd_DebugSetBrk_Out`, `Cmd_DebugShowVars_In`, `Cmd_DebugShowVars_Out`, `CmdDebugger` | `Init` (TBP,PRV,—); `SetBreakpoint` (TBP,PRV,—); `CheckBreakpoint` (TBP,PRV,—); `Debug_Init` (SUB,PRV,Init); `Debug_SetBreakpoint` (SUB,PRV,Mutate); `Debug_CheckBreakpoint` (FN,PRV,Validate); `Cmd_DebugSetBrk_Structured` (SUB,PUB,—); `Cmd_DebugShowVars_Structured` (SUB,PUB,—); `Cmd_DebugSetBrk` (SUB,PUB,—); `Cmd_DebugShowVars` (SUB,PUB,—) |
| `Script/AP_InpScriptExecutor.f90` | `AP_InpScriptExecutor` | `CmdExec` | `Exec` (TBP,PRV,—); `ExecList` (TBP,PRV,—); `CmdList_GetCmd` (SUB,PUB,Query); `Cmd_InitStacks` (SUB,PUB,Init); `EvaluateCondition` (SUB,PUB,—); `Cmd_ExecList` (SUB,PUB,—); `Exec_Exec` (SUB,PRV,—); `Exec_ExecList` (SUB,PRV,—) |
| `Script/AP_InpScriptHelp.f90` | `AP_InpScriptHelp` | `Cmd_HelpShow_In`, `Cmd_HelpShow_Out`, `Cmd_HelpSearch_In`, `Cmd_HelpSearch_Out` | `Cmd_HelpShow_Structured` (SUB,PUB,—); `Cmd_HelpSearch_Structured` (SUB,PUB,—); `Cmd_HelpShow` (SUB,PUB,—); `Cmd_HelpSearch` (SUB,PUB,—) |
| `Script/AP_InpScriptHistory.f90` | `AP_InpScriptHistory` | `CmdHistory` | `Init` (TBP,PRV,—); `Add` (TBP,PRV,—); `Get` (TBP,PRV,—); `Clear` (TBP,PRV,—); `Hist_Init` (SUB,PRV,Init); `Hist_Add` (SUB,PRV,Mutate); `Hist_Get` (SUB,PRV,Query); `Hist_Clear` (SUB,PRV,Mutate) |
| `Script/AP_InpScriptLabel.f90` | `AP_InpScriptLabel` | `LabelEntry`, `CmdLabelMgr` | `GetCmdByIndex_Proc` (SUB,PRV,—); `Init` (TBP,PRV,—); `Reg` (TBP,PRV,—); `Resolve` (TBP,PRV,—); `Label_Init` (SUB,PRV,Init); `Label_Reg` (SUB,PRV,—); `Label_Resolve` (FN,PRV,—) |
| `Script/AP_InpScriptLogger.f90` | `AP_InpScriptLogger` | `Cmd_Log_In`, `Cmd_Log_Out`, `Cmd_LogError_In`, `Cmd_LogError_Out`, `Cmd_SetLogLevel_In`, `Cmd_SetLogLevel_Out`, `CmdLogger` | `Init` (TBP,PRV,—); `Log` (TBP,PRV,—); `LogError` (TBP,PRV,—); `SetLevel` (TBP,PRV,—); `Log_Init` (SUB,PRV,Init); `Log_Log` (SUB,PRV,IO); `Log_LogError` (SUB,PRV,IO); `Log_SetLevel` (SUB,PRV,Mutate); `Cmd_Log_Structured` (SUB,PUB,IO); `Cmd_LogError_Structured` (SUB,PUB,IO); `Cmd_SetLogLevel_Structured` (SUB,PUB,Mutate); `Cmd_Log` (SUB,PUB,IO); `Cmd_LogError` (SUB,PUB,IO); `Cmd_SetLogLevel` (SUB,PUB,Mutate) |
| `Script/AP_InpScriptParser.f90` | `AP_InpScriptParser` | `CmdParser`, `Cmd_ParseLine_In`, `Cmd_ParseLine_Out`, `Cmd_ParseFile_In`, `Cmd_ParseFile_Out`, `Cmd_ParseString_In`, `Cmd_ParseString_Out` | `Cmd_ParseLine_Structured` (SUB,PUB,Parse); `Cmd_ParseFile_Structured` (SUB,PUB,Parse); `Cmd_ParseString_Structured` (SUB,PUB,Parse); `Cmd_ExpandMacros` (SUB,PUB,—); `Cmd_ParseKeyValue` (SUB,PUB,Parse); `Cmd_ParseArray` (SUB,PUB,Parse); `Cmd_ParseLine` (SUB,PUB,Parse); `Cmd_ParseFile` (SUB,PUB,Parse); `Cmd_ParseString` (SUB,PUB,Parse) |
| `Script/AP_InpScriptProc.f90` | `AP_InpScriptProc` | `CmdProcMgr` | `GetCmdByIndex_Proc` (SUB,PRV,—); `Init` (TBP,PRV,—); `Define` (TBP,PRV,—); `Load` (TBP,PRV,—); `Save` (TBP,PRV,—); `Exec` (TBP,PRV,—); `Find` (TBP,PRV,—); `Proc_Init` (SUB,PRV,Init); `Proc_Define` (SUB,PRV,—); `Proc_Load` (SUB,PRV,Parse); `Proc_Save` (SUB,PRV,—); `Proc_Exec` (SUB,PRV,—); `Proc_Find` (FN,PRV,Query); `Cmd_ProcDefine_Structured` (SUB,PUB,—); `Cmd_ProcLoad_Structured` (SUB,PUB,—); `Cmd_ProcSave_Structured` (SUB,PUB,—); `Cmd_ProcExec_Structured` (SUB,PUB,—); `Cmd_ProcDefine` (SUB,PUB,—); `Cmd_ProcLoad` (SUB,PUB,—); `Cmd_ProcSave` (SUB,PUB,—); `Cmd_ProcExec` (SUB,PUB,—) |
| `Script/AP_InpScriptReg.f90` | `AP_InpScriptReg` | `CmdReg` | `Init` (TBP,PRV,—); `Reg` (TBP,PRV,—); `Find` (TBP,PRV,—); `Exec` (TBP,PRV,—); `Cmd_Init_Structured` (SUB,PUB,Init); `Cmd_Reg_Structured` (SUB,PUB,—); `Cmd_Find_Structured` (SUB,PUB,Query); `Cmd_RegisterDesc_Structured` (SUB,PUB,—); `Reg_Init` (SUB,PRV,Init); `Reg_Reg` (SUB,PRV,—); `Reg_Find` (FN,PRV,Query); `Reg_Exec` (SUB,PRV,—); `Cmd_Init` (SUB,PUB,Init); `Cmd_Reg` (SUB,PUB,—); `Cmd_Find` (FN,PUB,Query); `Cmd_RegisterDesc` (SUB,PUB,—) |
| `Script/AP_InpScriptSubst.f90` | `AP_InpScriptSubst` | `Cmd_Subst_In`, `Cmd_Subst_Out`, `Cmd_SetVar_In`, `Cmd_SetVar_Out`, `Cmd_GetVar_In`, `Cmd_GetVar_Out` | `Cmd_Subst_Structured` (SUB,PUB,—); `Cmd_SetVar_Structured` (SUB,PUB,Mutate); `Cmd_GetVar_Structured` (SUB,PUB,Query); `Cmd_Subst` (SUB,PUB,—); `Cmd_SetVar` (SUB,PUB,Mutate); `Cmd_GetVar` (FN,PUB,Query) |
| `Script/AP_InpScriptUFC.f90` | `AP_InpScriptUFC` | — | `UF_Cmd_UFC_RegAll` (SUB,PUB,—); `Cmd_Init` (SUB,PRV,Init); `Cmd_Tangent` (SUB,PRV,—); `Cmd_Form` (SUB,PRV,—); `Cmd_Solv` (SUB,PRV,—); `Cmd_Iterate` (SUB,PRV,—); `Cmd_Displacement` (SUB,PRV,—); `Cmd_Plot` (SUB,PRV,—); `Cmd_Step` (SUB,PRV,—); `Cmd_Increment` (SUB,PRV,—); `Cmd_Part` (SUB,PRV,—); `Cmd_Mat` (SUB,PRV,—); `Cmd_Load` (SUB,PRV,Parse); `Cmd_BC` (SUB,PRV,—); `Cmd_Run` (SUB,PRV,—); `Cmd_Stop` (SUB,PRV,—); `Cmd_Jump` (SUB,PRV,—); `Cmd_Break` (SUB,PRV,—); `Cmd_Continue` (SUB,PRV,—); `Cmd_History` (SUB,PRV,—); `Cmd_Help` (SUB,PRV,—); `Cmd_Debug` (SUB,PRV,—); `Cmd_Label` (SUB,PRV,—); `Cmd_Echo` (SUB,PRV,—); `Cmd_Set` (SUB,PRV,Mutate); `Cmd_Alias` (SUB,PRV,—) |
| `Script/AP_InpScriptUser.f90` | `AP_InpScriptUser` | — | `Cmd_UserElement` (SUB,PUB,—); `Cmd_UserMaterial` (SUB,PUB,—); `UF_Cmd_User_RegAll` (SUB,PUB,—) |
| `Script/AP_InpScriptValid.f90` | `AP_InpScriptValid` | `Cmd_Valid_In`, `Cmd_Valid_Out`, `Cmd_FormatError_In`, `Cmd_FormatError_Out` | `Cmd_Valid_Structured` (SUB,PUB,Validate); `Cmd_FormatError_Structured` (SUB,PUB,—); `Cmd_Valid` (SUB,PUB,Validate); `Cmd_FormatError` (SUB,PUB,—) |
| `Script/AP_InpScript_Brg.f90` | `AP_InpScript_Brg` | — | `UF_Cmd_Init` (SUB,PUB,Init); `UF_Cmd_ExecFile` (SUB,PUB,—); `UF_Cmd_ExecString` (SUB,PUB,—); `UF_Cmd_SetCtx` (SUB,PUB,Mutate); `UF_Cmd_GetCtx` (SUB,PUB,Query); `UF_CmdCtx_ConvToOld` (SUB,PRV,—); `ConvertCtx_ToOld` (SUB,PRV,—); `UF_CmdCtx_ConvToNew` (SUB,PRV,—); `ConvertCtx_ToNew` (SUB,PRV,—); `UF_CmdSys_Init` (SUB,PUB,Init); `UF_CmdSys_ExecFile` (SUB,PUB,—); `UF_CmdSys_ExecStr` (SUB,PUB,—); `UF_CmdSys_SetCtx` (SUB,PUB,Mutate); `UF_CmdSys_GetCtx` (SUB,PUB,Query); `UF_CommandSystem_Initialize` (SUB,PUB,Init); `UF_CommandSystem_ExecuteFile` (SUB,PUB,—); `UF_Co_ExecuteString` (SUB,PRV,—); `UF_CommandSystem_SetContext` (SUB,PUB,Mutate); `UF_CommandSystem_GetContext` (SUB,PUB,Query); `AP_Cmd_Unified_Execute` (SUB,PUB,—); `AP_Cmd_Unified_Cfg` (SUB,PUB,—); `AP_App_Unified_Run` (SUB,PUB,—); `AP_App_Unified_Cfg` (SUB,PUB,—) |
