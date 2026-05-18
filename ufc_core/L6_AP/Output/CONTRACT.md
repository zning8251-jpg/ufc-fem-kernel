## Output 域级合同卡（L6_AP）

- **层级**：L6_AP
- **域名**：Output / 结果输出管理
- **缩写**：AP_Output (`AP_Output_*`)
- **职责**：提供计算结果写入、可视化数据导出、报告生成；支持 VTK/XDMF/CSV格式与自定义后处理。
- **四型配置**：
  - **Desc**：输出文件句柄、数据块结构、图例配置。
  - **State**：当前输出步、累积文件大小。
  - **Ctx**：无。
  - **Algo**：二进制压缩、增量写入、数据插值。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Write | Write_VTK, Write_XDMF, Write_CSV | 多格式导出 |
| Field | Write_Displacement, Write_Stress | 场变量输出 |
| Report | Generate_Summary, Generate_Log | 报告生成 |
| Extract | Extract_Reaction, Extract_Frequency | 结果提取 |

- **依赖**：IF_IO（文件读写）、L3_MD（模型数据）。
- **热路径**：**否** — 输出通常在求解完成后执行（除非要求每步输出）。
- **实现锚点**：
  - `AP_Output_Types.f90` — 输出 TYPE 定义
    ```fortran
    TYPE :: OutputConfig
      CHARACTER(:), ALLOCATABLE :: output_dir
      CHARACTER(:), ALLOCATABLE :: base_name
      INTEGER(i4) :: format_type     ! 1=VTK, 2=XDMF, 3=CSV
      INTEGER(i4) :: precision       ! 单精度/双精度
      LOGICAL :: compress = .TRUE.   ! 是否压缩
      INTEGER(i4) :: output_freq     ! 输出频率（每 N 步）
    END TYPE OutputConfig
    
    TYPE :: FieldData
      CHARACTER(:), ALLOCATABLE :: field_name
      INTEGER(i4) :: field_type      ! 1=SCALAR, 2=VECTOR, 3=TENSOR
      INTEGER(i4) :: num_points
      REAL(wp), ALLOCATABLE :: data(:,:)  ! (num_components, num_points)
    END TYPE FieldData
    ```
  - `AP_Output_VTK.f90` — VTK 格式导出
    ```fortran
    SUBROUTINE Write_VTK_Unstructured(config, mesh, fields, time_step)
      TYPE(OutputConfig), INTENT(IN) :: config
      TYPE(MeshModel), INTENT(IN) :: mesh
      TYPE(FieldData), INTENT(IN) :: fields(:)
      INTEGER(i4), INTENT(IN) :: time_step
      
      ! 伪代码：
      ! 1. 打开 VTK 文件（二进制或 ASCII）
      ! 2. 写入网格（POINTS + CELLS）
      ! 3. 写入场变量（POINT_DATA）
      
      file_name = TRIM(config%output_dir) // '/' // &
                  TRIM(config%base_name) // '_' // &
                  TRIM(itoa(time_step)) // '.vtk'
      
      OPEN(unit=30, file=file_name, form='unformatted', &
           access='stream', convert='big_endian')
      
      ! 写入文件头
      WRITE(30) '# vtk DataFile Version 3.0'
      WRITE(30) 'UFC Output'
      WRITE(30) 'BINARY'
      WRITE(30) 'DATASET UNSTRUCTURED_GRID'
      
      ! 写入节点坐标
      WRITE(30) 'POINTS ', mesh%num_nodes, ' double'
      DO i = 1, mesh%num_nodes
        WRITE(30) REAL(mesh%nodes(i)%x, 8), &
                  REAL(mesh%nodes(i)%y, 8), &
                  REAL(mesh%nodes(i)%z, 8)
      END DO
      
      ! 写入单元连接性
      WRITE(30) 'CELLS ', mesh%num_elements, &
                mesh%total_connectivity_size * 2
      DO i = 1, mesh%num_elements
        ! VTK 格式：n_nodes, node1, node2, ...
        WRITE(30) SIZE(mesh%elements(i)%connectivity)
        WRITE(30) mesh%elements(i)%connectivity - 1  ! VTK 从 0 开始
      END DO
      
      ! 写入场变量
      WRITE(30) 'POINT_DATA ', mesh%num_nodes
      DO j = 1, SIZE(fields)
        WRITE(30) 'SCALARS ', TRIM(fields(j)%field_name), ' double'
        WRITE(30) 'LOOKUP_TABLE default'
        DO i = 1, mesh%num_nodes
          WRITE(30) fields(j)%data(1, i)
        END DO
      END DO
      
      CLOSE(30)
    END SUBROUTINE Write_VTK_Unstructured
    ```
  - `AP_Output_XDMF.f90` — XDMF/HDF5导出
    ```fortran
    SUBROUTINE Write_XDMF_HDF5(config, mesh, fields, time_step, time_value)
      ! 伪代码：
      ! 1. 创建 HDF5 文件（使用 HDF5 Fortran API）
      ! 2. 写入数据集（/Mesh/Nodes, /Mesh/Elements, /Fields/Displacement）
      ! 3. 生成 XDMF 描述文件（XML格式，指向 HDF5 数据）
      
      ! HDF5 写入示例
      CALL H5Fcreate(file_name, H5F_ACC_TRUNC, file_id, ierr)
      CALL H5Screate_simple(2, dims, space_id)
      CALL H5Dcreate(file_id, 'Displacement', H5T_NATIVE_DOUBLE, &
                     space_id, dset_id)
      CALL H5Dwrite(dset_id, H5T_NATIVE_DOUBLE, &
                    H5S_ALL, H5S_ALL, fields(1)%data)
      CALL H5Dclose(dset_id)
      CALL H5Fclose(file_id)
      
      ! XDMF XML 生成
      WRITE(xdmf_unit, '(A)') '<?xml version="1.0" ?>'
      WRITE(xdmf_unit, '(A)') '<Xdmf>'
      WRITE(xdmf_unit, '(A)') '  <Domain>'
      WRITE(xdmf_unit, '(A)') '    <Grid Name="Mesh">'
      WRITE(xdmf_unit, '(A,I0,A)') '      <Time Value="'//&
                                   TRIM(rtoa(time_value))//'"/>'
      WRITE(xdmf_unit, '(A)') '      <Attribute Name="Displacement">'
      WRITE(xdmf_unit, '(A)') '        <DataItem ItemType="HyperSlab">'
      WRITE(xdmf_unit, '(A)') '          dataset.hdf:/Fields/Displacement'
      WRITE(xdmf_unit, '(A)') '        </DataItem>'
      WRITE(xdmf_unit, '(A)') '      </Attribute>'
      WRITE(xdmf_unit, '(A)') '    </Grid>'
      WRITE(xdmf_unit, '(A)') '  </Domain>'
      WRITE(xdmf_unit, '(A)') '</Xdmf>'
    END SUBROUTINE Write_XDMF_HDF5
    ```
  - `AP_Output_Report.f90` — 报告生成
  - `AP_Output_Extract.f90` — 结果提取（反力、频率等）

---


### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_OUTPUT_xxx`（60500–60599） |
| 严重级 | Warning / Error（磁盘空间不足为 Error，格式不支持为 Warning） |
| 传播规则 | 写入错误附加文件路径/步号上下文后传播至 Job 调用方 |
| 恢复策略 | 单步写入失败跳过 + Warning 继续后续步；文件创建失败返回 Error |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L3_MD/Output | S(消费) | 通过 Bridge 消费 L3 输出定义（Field/History Output） |
| 2 | L5_RT/Output | B(桥接) | 桥接至 L5 输出系统获取运行时数据 |
| 3 | L4_PH | S(消费) | 消费 L4 物理层 state data（应力/应变/位移等） |
| 4 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_IO） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| VTK/XDMF 文件格式合规性 | 硬约束 | 外部校验工具 + 集成测试 | PR 合入 |
| 场变量名称与 L3 Output 定义一致 | 硬约束 | 集成测试 | CI |
| 二进制/ASCII 模式可切换 | 硬约束 | 单元测试 | CI |
| HDF5 数据集布局与 XDMF schema 一致 | 软约束 | 集成测试 | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | OutputConfig | 输出配置（目录/格式/精度/频率） |
| 2 | State | FieldData + 当前输出步/文件大小 | 场变量数据与写入状态 |
| 3 | Algo | 二进制压缩 / 增量写入 / 数据插值 | VTK/XDMF/CSV 写入算法 |
| 4 | Ctx | 无 | 步结束时触发，无持久上下文 |
| 5 | Arg (SIO) | 无 | 输出阶段不在热路径 |
| 6 | Proc | AP_Output_VTK/XDMF/Report/Extract.f90 | 输出过程模块 |
| 7 | Test | Output 单元测试 | 格式合规性 + 数据完整性 |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无（消费 AP_Config） | 输出选项来自 Config 域 |
| 10 | Error | ERR_L6_OUTPUT_xxx | 60500–60599 |
| 11 | Domain | AP_Output 域 | L6_AP/Output/ |
| 12 | Registry | 无 | 不注册为服务 |
| 13 | Doc | 本合同 + 格式规范 | VTK/XDMF/CSV 格式说明 |

---

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 场变量定义→输出格式规范→可视化数据模型 |
| **逻辑链** | L3 Output 定义→L5 运行时数据收集→AP_Output 写入文件 |
| **计算链** | 数据插值/压缩/格式转换（非 FEM 计算） |
| **数据链** | L4 State data→FieldData→VTK/XDMF/CSV 文件 |

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
| `AP_Out_Domain.f90` | `AP_OutDomain` | `AP_Output_State`, `AP_Output_Ctrl`, `AP_Output_OpenODB_Arg`, `AP_Output_WriteFrame_Arg`, `AP_Output_GetSummary_Arg`, `AP_Output_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `OpenODB` (TBP,PRV,—); `WriteFrame` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `AddOutputRequest` (TBP,PRV,—); `AddFrame` (TBP,PRV,—); `GetRequestById` (TBP,PRV,—); `GetFrameById` (TBP,PRV,—); `GetRequestCount` (TBP,PRV,—); `GetFrameCount` (TBP,PRV,—); `AP_Output_Domain_Finalize` (SUB,PRV,Finalize); `AP_Output_Domain_Init` (SUB,PRV,Init); `AP_Output_Domain_OpenODB` (SUB,PRV,IO); `AP_Output_OpenODB_Impl` (SUB,PRV,IO); `AP_Output_Domain_WriteFrame` (SUB,PRV,IO); `AP_Output_WriteFrame_Impl` (SUB,PRV,IO); `AP_Output_Domain_GetSummary` (SUB,PRV,Query); `AP_Output_GetSummary_Impl` (SUB,PRV,Query); `AP_Output_Domain_AddOutputRequest` (SUB,PRV,Mutate); `AP_Output_Domain_AddFrame` (SUB,PRV,Mutate); `AP_Output_Domain_GetRequestById` (SUB,PRV,Query); `AP_Output_Domain_GetFrameById` (SUB,PRV,Query); `AP_Output_Domain_GetRequestCount` (FN,PRV,Query); `AP_Output_Domain_GetFrameCount` (FN,PRV,Query) |
| `AP_Out_Fmt.f90` | `AP_OutFmt` | `AP_Output_Format_Props` | `Init` (TBP,PRV,—); `Valid` (TBP,PRV,—); `Clear` (TBP,PRV,—); `Valid_USER_OUTPUT_Keyword` (SUB,PUB,IO); `AP_Output_Format_Init` (SUB,PRV,Init); `AP_Output_Format_Valid` (SUB,PRV,Validate); `AP_Output_Format_Clear` (SUB,PRV,Mutate); `AP_Output_Format_Parse` (SUB,PUB,Parse); `Parse_FILE_FORMAT_Keyword` (SUB,PUB,—); `AP_Output_Format_UnifiedParse` (SUB,PUB,IO); `AP_Output_Format_Unified_Parse` (SUB,PUB,Parse); `AP_Out_Format_UnifiedCfg_Impl` (SUB,PRV,—); `AP_Output_Format_UnifiedCfg` (SUB,PUB,IO); `AP_Output_Format_Unified_Cfg` (SUB,PUB,IO); `AP_Output_Format_ValidKw` (SUB,PUB,Validate); `Valid_FILE_FORMAT_Keyword` (SUB,PUB,—); `AP_Output_NodeFile_Init` (SUB,PRV,Init); `AP_Output_NodeFile_Valid` (SUB,PRV,Validate); `AP_Output_NodeFile_Clear` (SUB,PRV,Mutate); `AP_Output_NodeFile_Parse` (SUB,PUB,Parse); `Parse_NODE_FILE_Keyword` (SUB,PUB,—); `AP_Output_NodeFile_UnifiedParse` (SUB,PUB,IO); `AP_Output_NodeFile_Unified_Parse` (SUB,PUB,Parse); `AP_Output_NodeFile_UnifiedCfg` (SUB,PUB,IO); `AP_Output_NodeFile_Unified_Configure` (SUB,PUB,IO); `AP_Output_NodeFile_ValidKw` (SUB,PUB,Validate); `Valid_NODE_FILE_Keyword` (SUB,PUB,—); `AP_Output_ElFile_Init` (SUB,PRV,Init); `AP_Output_ElFile_Valid` (SUB,PRV,Validate); `AP_Output_ElFile_Clear` (SUB,PRV,Mutate); `AP_Output_ElFile_Parse` (SUB,PUB,Parse); `Parse_EL_FILE_Keyword` (SUB,PUB,—); `AP_Output_ElFile_UnifiedParse` (SUB,PUB,IO); `AP_Output_Unified_Parse` (SUB,PUB,Parse); `AP_Output_ElFile_UnifiedCfg` (SUB,PUB,IO); `AP_Output_Unified_Cfg` (SUB,PUB,IO); `AP_Output_ElFile_ValidKw` (SUB,PUB,Validate); `Valid_EL_FILE_Keyword` (SUB,PUB,—); `AP_Output_Preprint_Init` (SUB,PRV,Init); `AP_Output_Preprint_Valid` (SUB,PRV,Validate); `AP_Output_Preprint_Clear` (SUB,PRV,Mutate); `get_param_value` (SUB,PRV,—); `AP_Output_Preprint_Parse` (SUB,PUB,Parse); `Parse_PREPRINT_Keyword` (SUB,PUB,—); `AP_Output_Preprint_UnifiedParse` (SUB,PUB,IO); `AP_Output_Preprint_Unified_Parse` (SUB,PUB,Parse); `AP_Output_Preprint_UnifiedCfg` (SUB,PUB,IO); `AP_Output_Preprint_Unified_Configure` (SUB,PUB,IO); `AP_Output_Preprint_ValidKw` (SUB,PUB,Validate); `Valid_PREPRINT_Keyword` (SUB,PUB,—) |
| `AP_OutRT_Brg.f90` | `AP_OutRT_Brg` | — | `AP_Out_SyncToRT` (SUB,PUB,Populate); `AP_Out_EntryToFldReq` (SUB,PUB,—); `AP_Out_EntryToHistReq` (SUB,PUB,—); `AP_Out_ParseVariableStr` (SUB,PRV,Parse); `VarNameToId` (FN,PRV,—); `ToUpper` (SUB,PRV,—) |
| `AP_Out_Def.f90` | `AP_Out_Def` | `OutputRequestEntry`, `FrameEntry` | — |
| `AP_PostProcDataAnal.f90` | `AP_PostProcDataAnal` | `DataAnalysisManagerType` | `Init` (TBP,PRV,—); `LoadResults` (TBP,PRV,—); `ExtractPath` (TBP,PRV,—); `ExtractHistory` (TBP,PRV,—); `CalculateStatistics` (TBP,PRV,—); `PerformXYPlot` (TBP,PRV,—); `GenerateReport` (TBP,PRV,—); `ExportData` (TBP,PRV,—); `AP_DataAnalysis_Init` (SUB,PUB,Init); `AP_DataAnalysis_LoadResults` (SUB,PUB,Parse); `AP_DataAnalysis_ExtractPath` (SUB,PUB,—); `AP_Da_ExtractHistory` (SUB,PRV,—); `AP_Da_CalculateStatistics` (SUB,PRV,Compute); `AP_Da_PerformXYPlot` (SUB,PRV,—); `AP_Da_GenerateReport` (SUB,PRV,—); `AP_DataAnalysis_ExportData` (SUB,PUB,—); `AP_InitializeAvailableData` (SUB,PRV,Init); `AP_InitializeStatistics` (SUB,PRV,Init); `AP_InitializePercentiles` (SUB,PRV,Init); `AP_FileExists` (FN,PRV,—); `AP_GetJobName` (FN,PRV,Query); `AP_OpenODBDatabase` (SUB,PRV,—); `AP_ReadAvailableData` (SUB,PRV,Parse); `AP_LoadStepInformation` (SUB,PRV,Parse); `AP_CreatePathPoints` (SUB,PRV,Init); `AP_ExtractVariableAlongPath` (SUB,PRV,—); `AP_CreateHistoryData` (SUB,PRV,Init); `AP_ExtractHistoryValues` (SUB,PRV,—); `AP_AddPathToArray` (SUB,PRV,Mutate); `AP_AddHistoryToArray` (SUB,PRV,Mutate); `AP_ResizePathArray` (SUB,PRV,—); `AP_ResizeHistoryArray` (SUB,PRV,—); `AP_CalculateBasicStatistics` (SUB,PRV,Compute); `AP_CalculatePercentiles` (SUB,PRV,Compute); `AP_GenerateHTMLReport` (SUB,PRV,—); `AP_GeneratePDFReport` (SUB,PRV,—); `AP_GenerateTextReport` (SUB,PRV,—); `AP_ExportCSV` (SUB,PRV,—); `AP_ExportExcel` (SUB,PRV,—); `AP_ExportMATLAB` (SUB,PRV,—); `AP_RealToString` (FN,PRV,—); `AP_IntToString` (FN,PRV,—); `REPEAT` (FN,PRV,—); `LEN_TRIM` (FN,PRV,—); `AP_VariableExists` (FN,PRV,—); `AP_HistoryVariableExists` (FN,PRV,—); `AP_CollectFieldData` (SUB,PRV,—); `AP_CollectHistoryData` (SUB,PRV,—); `AP_CollectPathData` (SUB,PRV,—); `AP_CalculatePathStatistics` (SUB,PRV,Compute); `AP_CalculateHistoryStatistic` (SUB,PRV,Compute); `AP_CreateXYPlot` (SUB,PRV,Init); `AP_AddXYPlotToArray` (SUB,PRV,Mutate) |
| `AP_PostProcVisual.f90` | `AP_PostProcVisual` | `VisualizationManagerType` | `Init` (TBP,PRV,—); `CreateViewport` (TBP,PRV,—); `PlotField` (TBP,PRV,—); `PlotContour` (TBP,PRV,—); `PlotVector` (TBP,PRV,—); `PlotDeformedShape` (TBP,PRV,—); `CreateAnimation` (TBP,PRV,—); `ExportResults` (TBP,PRV,—); `AP_Visualization_Init` (SUB,PUB,Init); `AP_Vi_CreateViewport` (SUB,PRV,Init); `AP_Visualization_PlotField` (SUB,PUB,—); `AP_Visualization_PlotContour` (SUB,PUB,—); `AP_Visualization_PlotVector` (SUB,PUB,—); `AP_Vi_PlotDeformedShape` (SUB,PRV,—); `AP_Vi_CreateAnimation` (SUB,PRV,Init); `AP_Vi_ExportResults` (SUB,PRV,—); `AP_InitializeViewports` (SUB,PRV,Init); `AP_ExpandViewportArray` (SUB,PRV,—); `AP_CalculateFieldRange` (SUB,PRV,Compute); `AP_SetContourLevels` (SUB,PRV,Mutate); `AP_InitializePlotConfig` (SUB,PRV,Init); `AP_InitializeContourConfig` (SUB,PRV,Init); `AP_InitializeVectorConfig` (SUB,PRV,Init); `AP_InitializeDeformedConfig` (SUB,PRV,Init); `AP_GenerateFieldPlot` (SUB,PRV,—); `AP_GenerateContourPlot` (SUB,PRV,—); `AP_GenerateVectorPlot` (SUB,PRV,—); `AP_GenerateDeformedPlot` (SUB,PRV,—); `AP_GenerateAnimationFrame` (SUB,PRV,—); `AP_CompileAnimation` (SUB,PRV,—); `AP_ExportViewport` (SUB,PRV,—); `AP_IntToString` (FN,PRV,—); `AP_RealToString` (FN,PRV,—) |
