# `AP_Out_PostProcDataAnal.f90`

- **Source**: `L6_AP/Output/AP_Out_PostProcDataAnal.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Out_PostProcDataAnal`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Out_PostProcDataAnal`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Out_PostProcDataAnal`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_Out_PostProcDataAnal.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `DataAnalysisManagerType` (lines 33–82)

```fortran
    TYPE :: DataAnalysisManagerType
        !  
        CHARACTER(LEN=256) :: odb_file = ""                  ! ODB 
        CHARACTER(LEN=256) :: job_name = ""                 !  
        LOGICAL :: database_opened = .FALSE.                !  
        
        !  
        TYPE(AvailableDataType) :: available_data           !  
        INTEGER(i4) :: num_steps = 0                     !  
        INTEGER(i4) :: num_frames = 0                     !  
        INTEGER(i4) :: num_field_outputs = 0              !  output 
        INTEGER(i4) :: num_history_outputs = 0           !  output 
        
        !  
        INTEGER(i4) :: active_step = 1                   !  
        INTEGER(i4) :: active_frame = 1                  !  
        CHARACTER(LEN=50) :: active_field = ""               !  
        
        !  
        TYPE(PathDataType), ALLOCATABLE :: paths(:)          !  
        INTEGER(i4) :: num_paths = 0                      !  
        
        !  
        TYPE(HistoryDataType), ALLOCATABLE :: history_data(:) !  
        INTEGER(i4) :: num_history_points = 0             !  
        
        !  
        TYPE(StatisticsType) :: field_statistics            !  
        TYPE(StatisticsType) :: history_statistics          !  
        
        ! XY 
        TYPE(XYPlotType), ALLOCATABLE :: xy_plots(:)        ! XY 
        INTEGER(i4) :: num_xy_plots = 0                  ! XY 
        
        !  
        TYPE(AnalysisConfigType) :: analysis_config         !  
        
        ! status 
        LOGICAL :: analysis_initialized = .FALSE.           !  init
        
    CONTAINS
        PROCEDURE :: Init
        PROCEDURE :: LoadResults
        PROCEDURE :: ExtractPath
        PROCEDURE :: ExtractHistory
        PROCEDURE :: CalculateStatistics
        PROCEDURE :: PerformXYPlot
        PROCEDURE :: GenerateReport
        PROCEDURE :: ExportData
    END TYPE DataAnalysisManagerType
```

### `AvailableDataType` (lines 85–91)

```fortran
    TYPE :: AvailableDataType
        CHARACTER(LEN=50), ALLOCATABLE :: field_variables(:)  !  
        CHARACTER(LEN=50), ALLOCATABLE :: history_variables(:) !  
        INTEGER(i4), ALLOCATABLE :: step_numbers(:)       !  
        CHARACTER(LEN=100), ALLOCATABLE :: step_names(:)      !  
        REAL(wp), ALLOCATABLE :: step_times(:)           !  time 
    END TYPE AvailableDataType
```

### `PathDataType` (lines 94–104)

```fortran
    TYPE :: PathDataType
        CHARACTER(LEN=100) :: path_name = ""                 !  
        CHARACTER(LEN=20) :: path_type = ""                   !  
        INTEGER(i4) :: num_points = 0                     !  
        REAL(wp), ALLOCATABLE :: coordinates(:,:)         !  
        REAL(wp), ALLOCATABLE :: distances(:)            !  
        REAL(wp), ALLOCATABLE :: values(:,:)             !  value
        CHARACTER(LEN=50) :: variable_name = ""              !  
        INTEGER(i4) :: step_number = 0                    !  
        REAL(wp) :: step_time = 0.0d0                   !  time
    END TYPE PathDataType
```

### `HistoryDataType` (lines 107–115)

```fortran
    TYPE :: HistoryDataType
        CHARACTER(LEN=100) :: point_name = ""                !  
        INTEGER(i4) :: point_id = 0                       !  ID
        CHARACTER(LEN=20) :: point_type = ""                  !   (NODE/INTEGRATION_POINT)
        CHARACTER(LEN=50) :: variable_name = ""               !  
        INTEGER(i4) :: num_components = 0                 !  
        REAL(wp), ALLOCATABLE :: times(:)                ! time
        REAL(wp), ALLOCATABLE :: values(:,:)              !  value
    END TYPE HistoryDataType
```

### `StatisticsType` (lines 118–127)

```fortran
    TYPE :: StatisticsType
        REAL(wp) :: min_value = 0.0d0                    !  value
        REAL(wp) :: max_value = 0.0d0                    !  value
        REAL(wp) :: mean_value = 0.0d0                   !  value
        REAL(wp) :: std_deviation = 0.0d0               !  
        REAL(wp) :: variance = 0.0d0                     !  
        REAL(wp) :: median = 0.0d0                      !  
        INTEGER(i4) :: num_samples = 0                   !  
        REAL(wp), ALLOCATABLE :: percentiles(:)          !  
    END TYPE StatisticsType
```

### `XYPlotType` (lines 130–142)

```fortran
    TYPE :: XYPlotType
        CHARACTER(LEN=100) :: plot_title = ""                !  
        CHARACTER(LEN=50) :: x_variable = ""                 ! X 
        CHARACTER(LEN=50) :: y_variable = ""                 ! Y 
        CHARACTER(LEN(50), ALLOCATABLE :: legend(:)          !  
        INTEGER(i4) :: num_curves = 0                    !  
        REAL(wp), ALLOCATABLE :: x_data(:,:)             ! X  (ncurves, npoints)
        REAL(wp), ALLOCATABLE :: y_data(:,:)             ! Y  (ncurves, npoints)
        CHARACTER(LEN=20), ALLOCATABLE :: line_styles(:)     !  
        CHARACTER(LEN=20), ALLOCATABLE :: colors(:)          !  
        LOGICAL :: show_grid = .TRUE.                        !  
        LOGICAL :: show_legend = .TRUE.                      !  
    END TYPE XYPlotType
```

### `AnalysisConfigType` (lines 145–152)

```fortran
    TYPE :: AnalysisConfigType
        LOGICAL :: auto_statistics = .TRUE.                 !  
        LOGICAL :: auto_correlation = .FALSE.                !  
        INTEGER(i4) :: num_percentiles = 9                !  
        REAL(wp), ALLOCATABLE :: percentile_values(:)    !  value
        CHARACTER(LEN=20) :: interpolation_method = "LINEAR" !  value 
        REAL(wp) :: tolerance = 1.0d-6                   !  
    END TYPE AnalysisConfigType
```

### `ReportConfigType` (lines 155–163)

```fortran
    TYPE :: ReportConfigType
        CHARACTER(LEN=256) :: report_file = ""              !  
        CHARACTER(LEN=20) :: report_format = "HTML"          !   (HTML/PDF/TEXT)
        LOGICAL :: include_statistics = .TRUE.               !  
        LOGICAL :: include_plots = .TRUE.                    !  
        LOGICAL :: include_summary = .TRUE.                  !  
        CHARACTER(LEN=100) :: title = ""                     !  
        CHARACTER(LEN=500) :: description = ""                !  description
    END TYPE ReportConfigType
```

### `ExportConfigType` (lines 166–173)

```fortran
    TYPE :: ExportConfigType
        CHARACTER(LEN=256) :: export_file = ""               !  
        CHARACTER(LEN=20) :: export_format = "CSV"           !   (CSV/EXCEL/MATLAB)
        LOGICAL :: include_headers = .TRUE.                  !  
        CHARACTER(LEN=20) :: delimiter = ","                 !  
        LOGICAL :: scientific_notation = .FALSE.             !  
        INTEGER(i4) :: precision = 6                       ! tolerance
    END TYPE ExportConfigType
```

### `PathDefinitionType` (lines 857–862)

```fortran
    TYPE :: PathDefinitionType
        CHARACTER(LEN=20) :: path_type = ""
        REAL(wp), ALLOCATABLE :: start_point(:)
        REAL(wp), ALLOCATABLE :: end_point(:)
        INTEGER(i4) :: num_points = 0
    END TYPE PathDefinitionType
```

### `PointSpecificationType` (lines 864–868)

```fortran
    TYPE :: PointSpecificationType
        CHARACTER(LEN=20) :: point_type = ""
        INTEGER(i4) :: point_id = 0
        CHARACTER(LEN=100) :: point_name = ""
    END TYPE PointSpecificationType
```

### `XYPlotConfigType` (lines 870–876)

```fortran
    TYPE :: XYPlotConfigType
        CHARACTER(LEN=50) :: plot_title = ""
        CHARACTER(LEN(20), ALLOCATABLE :: line_styles(:)
        CHARACTER(LEN(20), ALLOCATABLE :: colors(:)
        LOGICAL :: show_grid = .TRUE.
        LOGICAL :: show_legend = .TRUE.
    END TYPE XYPlotConfigType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_DataAnalysis_Init` | 178 | `SUBROUTINE AP_DataAnalysis_Init(this, config, status)` |
| SUBROUTINE | `AP_DataAnalysis_LoadResults` | 209 | `SUBROUTINE AP_DataAnalysis_LoadResults(this, odb_file, status)` |
| SUBROUTINE | `AP_DataAnalysis_ExtractPath` | 252 | `SUBROUTINE AP_DataAnalysis_ExtractPath(this, path_definition, variable_name, step_number, status)` |
| SUBROUTINE | `AP_Da_ExtractHistory` | 296 | `SUBROUTINE AP_Da_ExtractHistory(this, point_specification, variable_name, status)` |
| SUBROUTINE | `AP_Da_CalculateStatistics` | 339 | `SUBROUTINE AP_Da_CalculateStatistics(this, data_source, variable_name, status)` |
| SUBROUTINE | `AP_Da_PerformXYPlot` | 390 | `SUBROUTINE AP_Da_PerformXYPlot(this, x_source, y_source, plot_config, status)` |
| SUBROUTINE | `AP_Da_GenerateReport` | 419 | `SUBROUTINE AP_Da_GenerateReport(this, report_config, status)` |
| SUBROUTINE | `AP_DataAnalysis_ExportData` | 450 | `SUBROUTINE AP_DataAnalysis_ExportData(this, export_config, status)` |
| SUBROUTINE | `AP_InitializeAvailableData` | 481 | `SUBROUTINE AP_InitializeAvailableData(available_data)` |
| SUBROUTINE | `AP_InitializeStatistics` | 486 | `SUBROUTINE AP_InitializeStatistics(stats)` |
| SUBROUTINE | `AP_InitializePercentiles` | 497 | `SUBROUTINE AP_InitializePercentiles(percentiles, num_percentiles)` |
| FUNCTION | `AP_FileExists` | 508 | `FUNCTION AP_FileExists(filename) RESULT(exists)` |
| FUNCTION | `AP_GetJobName` | 515 | `FUNCTION AP_GetJobName(odb_file) RESULT(job_name)` |
| SUBROUTINE | `AP_OpenODBDatabase` | 528 | `SUBROUTINE AP_OpenODBDatabase(odb_file, status)` |
| SUBROUTINE | `AP_ReadAvailableData` | 535 | `SUBROUTINE AP_ReadAvailableData(available_data, status)` |
| SUBROUTINE | `AP_LoadStepInformation` | 542 | `SUBROUTINE AP_LoadStepInformation(this, step_number, status)` |
| SUBROUTINE | `AP_CreatePathPoints` | 551 | `SUBROUTINE AP_CreatePathPoints(path_definition, path_data, status)` |
| SUBROUTINE | `AP_ExtractVariableAlongPath` | 559 | `SUBROUTINE AP_ExtractVariableAlongPath(path_data, variable_name, step_number, status)` |
| SUBROUTINE | `AP_CreateHistoryData` | 568 | `SUBROUTINE AP_CreateHistoryData(point_spec, variable_name, history_data, status)` |
| SUBROUTINE | `AP_ExtractHistoryValues` | 577 | `SUBROUTINE AP_ExtractHistoryValues(history_data, status)` |
| SUBROUTINE | `AP_AddPathToArray` | 585 | `SUBROUTINE AP_AddPathToArray(paths, new_path, status)` |
| SUBROUTINE | `AP_AddHistoryToArray` | 604 | `SUBROUTINE AP_AddHistoryToArray(history_data, new_history, status)` |
| SUBROUTINE | `AP_ResizePathArray` | 623 | `SUBROUTINE AP_ResizePathArray(paths, new_size)` |
| SUBROUTINE | `AP_ResizeHistoryArray` | 646 | `SUBROUTINE AP_ResizeHistoryArray(history_data, new_size)` |
| SUBROUTINE | `AP_CalculateBasicStatistics` | 670 | `SUBROUTINE AP_CalculateBasicStatistics(data, stats, status)` |
| SUBROUTINE | `AP_CalculatePercentiles` | 709 | `SUBROUTINE AP_CalculatePercentiles(data, percentile_values, stats, status)` |
| SUBROUTINE | `AP_GenerateHTMLReport` | 730 | `SUBROUTINE AP_GenerateHTMLReport(this, report_config, status)` |
| SUBROUTINE | `AP_GeneratePDFReport` | 757 | `SUBROUTINE AP_GeneratePDFReport(this, report_config, status)` |
| SUBROUTINE | `AP_GenerateTextReport` | 765 | `SUBROUTINE AP_GenerateTextReport(this, report_config, status)` |
| SUBROUTINE | `AP_ExportCSV` | 792 | `SUBROUTINE AP_ExportCSV(this, export_config, status)` |
| SUBROUTINE | `AP_ExportExcel` | 800 | `SUBROUTINE AP_ExportExcel(this, export_config, status)` |
| SUBROUTINE | `AP_ExportMATLAB` | 808 | `SUBROUTINE AP_ExportMATLAB(this, export_config, status)` |
| FUNCTION | `AP_RealToString` | 817 | `FUNCTION AP_RealToString(value) RESULT(string)` |
| FUNCTION | `AP_IntToString` | 823 | `FUNCTION AP_IntToString(value) RESULT(string)` |
| FUNCTION | `REPEAT` | 829 | `FUNCTION REPEAT(char_string, count) RESULT(result)` |
| FUNCTION | `LEN_TRIM` | 841 | `FUNCTION LEN_TRIM(string) RESULT(length)` |
| FUNCTION | `AP_VariableExists` | 879 | `FUNCTION AP_VariableExists(available_data, variable_name) RESULT(exists)` |
| FUNCTION | `AP_HistoryVariableExists` | 886 | `FUNCTION AP_HistoryVariableExists(available_data, variable_name) RESULT(exists)` |
| SUBROUTINE | `AP_CollectFieldData` | 893 | `SUBROUTINE AP_CollectFieldData(this, variable_name, data, status)` |
| SUBROUTINE | `AP_CollectHistoryData` | 903 | `SUBROUTINE AP_CollectHistoryData(this, variable_name, data, status)` |
| SUBROUTINE | `AP_CollectPathData` | 913 | `SUBROUTINE AP_CollectPathData(this, variable_name, data, status)` |
| SUBROUTINE | `AP_CalculatePathStatistics` | 923 | `SUBROUTINE AP_CalculatePathStatistics(path_data, stats, status)` |
| SUBROUTINE | `AP_CalculateHistoryStatistic` | 931 | `SUBROUTINE AP_CalculateHistoryStatistic(history_data, stats, status)` |
| SUBROUTINE | `AP_CreateXYPlot` | 939 | `SUBROUTINE AP_CreateXYPlot(x_source, y_source, plot_config, xy_plot, status)` |
| SUBROUTINE | `AP_AddXYPlotToArray` | 949 | `SUBROUTINE AP_AddXYPlotToArray(xy_plots, new_plot, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
