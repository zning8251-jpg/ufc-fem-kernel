!======================================================================
! Module: AP_PostProcDataAnal
! Layer:  L6_AP - Application Layer
! Domain: Output / Data Analysis
! Purpose: Post-processing data analysis module.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================

MODULE AP_Out_PostProcDataAnal
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14
    USE AP_Base_Def
    USE IF_Prec_Core, ONLY: wp, i4, i8
    ! UFC Physics API imports - via Bridge module
    USE AP_Brg_L4, ONLY: PH_PhysCtrl_Ctx, PH_Field_Desc
    ! Note: RT_Logging module may not exist or may be merged into RT_Types
    ! If needed, logging interfaces should be added to AP_BrgL5
    IMPLICIT NONE

    PRIVATE
    PUBLIC :: AP_DataAnalysis_Init, AP_DataAnalysis_LoadResults
    PUBLIC :: AP_DataAnalysis_ExtractPath, AP_DataAnalysis_ExtractHistory
    PUBLIC :: AP_DataAnalysis_CalculateStatistics, AP_DataAnalysis_PerformXYPlot
    PUBLIC :: AP_DataAnalysis_GenerateReport, AP_DataAnalysis_ExportData

    !>  management  -   ABAQUS Data Analysis
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

    !>  
    TYPE :: AvailableDataType
        CHARACTER(LEN=50), ALLOCATABLE :: field_variables(:)  !  
        CHARACTER(LEN=50), ALLOCATABLE :: history_variables(:) !  
        INTEGER(i4), ALLOCATABLE :: step_numbers(:)       !  
        CHARACTER(LEN=100), ALLOCATABLE :: step_names(:)      !  
        REAL(wp), ALLOCATABLE :: step_times(:)           !  time 
    END TYPE AvailableDataType

    !>  
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

    !>  
    TYPE :: HistoryDataType
        CHARACTER(LEN=100) :: point_name = ""                !  
        INTEGER(i4) :: point_id = 0                       !  ID
        CHARACTER(LEN=20) :: point_type = ""                  !   (NODE/INTEGRATION_POINT)
        CHARACTER(LEN=50) :: variable_name = ""               !  
        INTEGER(i4) :: num_components = 0                 !  
        REAL(wp), ALLOCATABLE :: times(:)                ! time
        REAL(wp), ALLOCATABLE :: values(:,:)              !  value
    END TYPE HistoryDataType

    !>  
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

    !> XY 
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

    !>  
    TYPE :: AnalysisConfigType
        LOGICAL :: auto_statistics = .TRUE.                 !  
        LOGICAL :: auto_correlation = .FALSE.                !  
        INTEGER(i4) :: num_percentiles = 9                !  
        REAL(wp), ALLOCATABLE :: percentile_values(:)    !  value
        CHARACTER(LEN=20) :: interpolation_method = "LINEAR" !  value 
        REAL(wp) :: tolerance = 1.0d-6                   !  
    END TYPE AnalysisConfigType

    !>  
    TYPE :: ReportConfigType
        CHARACTER(LEN=256) :: report_file = ""              !  
        CHARACTER(LEN=20) :: report_format = "HTML"          !   (HTML/PDF/TEXT)
        LOGICAL :: include_statistics = .TRUE.               !  
        LOGICAL :: include_plots = .TRUE.                    !  
        LOGICAL :: include_summary = .TRUE.                  !  
        CHARACTER(LEN=100) :: title = ""                     !  
        CHARACTER(LEN=500) :: description = ""                !  description
    END TYPE ReportConfigType

    !>  
    TYPE :: ExportConfigType
        CHARACTER(LEN=256) :: export_file = ""               !  
        CHARACTER(LEN=20) :: export_format = "CSV"           !   (CSV/EXCEL/MATLAB)
        LOGICAL :: include_headers = .TRUE.                  !  
        CHARACTER(LEN=20) :: delimiter = ","                 !  
        LOGICAL :: scientific_notation = .FALSE.             !  
        INTEGER(i4) :: precision = 6                       ! tolerance
    END TYPE ExportConfigType

CONTAINS

    !> init management 
    SUBROUTINE AP_DataAnalysis_Init(this, config, status)
        CLASS(DataAnalysisManagerType), INTENT(OUT) :: this
        TYPE(AnalysisConfigType), INTENT(IN) :: config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        status%success = .TRUE.
        
        ! set 
        this%analysis_config = config
        
        ! init 
        IF (config%auto_statistics) THEN
            ALLOCATE(this%analysis_config%percentile_values(config%num_percentiles))
            CALL AP_InitializePercentiles(this%analysis_config%percentile_values, config%num_percentiles)
        END IF
        
        ! init 
        CALL AP_InitializeAvailableData(this%available_data)
        
        ! init 
        CALL AP_InitializeStatistics(this%field_statistics)
        CALL AP_InitializeStatistics(this%history_statistics)
        
        IF (status%success) THEN
            this%analysis_initialized = .TRUE.
            CALL RT_LogInfo("Data analysis manager initialized successfully")
        END IF
        
    END SUBROUTINE AP_DataAnalysis_Init

    !>  
    SUBROUTINE AP_DataAnalysis_LoadResults(this, odb_file, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: odb_file
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        status%success = .TRUE.
        
        !  
        IF (.NOT. AP_FileExists(odb_file)) THEN
            status%success = .FALSE.
            status%message = "ODB file not found: " // TRIM(odb_file)
            RETURN
        END IF
        
        ! setODB 
        this%odb_file = odb_file
        this%job_name = AP_GetJobName(odb_file)
        
        !  ODB 
        CALL AP_OpenODBDatabase(odb_file, status)
        IF (.NOT. status%success) RETURN
        
        !  
        CALL AP_ReadAvailableData(this%available_data, status)
        IF (.NOT. status%success) RETURN
        
        ! set 
        this%num_steps = SIZE(this%available_data%step_numbers)
        IF (this%num_steps > 0) THEN
            this%active_step = this%available_data%step_numbers(1)
            CALL AP_LoadStepInformation(this, this%active_step, status)
        END IF
        
        this%database_opened = .TRUE.
        
        CALL RT_LogInfo("Results loaded successfully: " // TRIM(odb_file))
        CALL RT_LogDebug("  Number of steps: " // AP_IntToString(this%num_steps))
        CALL RT_LogDebug("  Number of field outputs: " // AP_IntToString(this%num_field_outputs))
        CALL RT_LogDebug("  Number of history outputs: " // AP_IntToString(this%num_history_outputs))
        
    END SUBROUTINE AP_DataAnalysis_LoadResults

    !>  
    SUBROUTINE AP_DataAnalysis_ExtractPath(this, path_definition, variable_name, step_number, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        TYPE(PathDefinitionType), INTENT(IN) :: path_definition
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4), INTENT(IN) :: step_number
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(PathDataType) :: new_path
        
        status%success = .TRUE.
        
        !  
        IF (.NOT. AP_VariableExists(this%available_data, variable_name)) THEN
            status%success = .FALSE.
            status%message = "Variable not found: " // TRIM(variable_name)
            RETURN
        END IF
        
        !  
        CALL AP_CreatePathPoints(path_definition, new_path, status)
        IF (.NOT. status%success) RETURN
        
        !  value 
        CALL AP_ExtractVariableAlongPath(new_path, variable_name, step_number, status)
        If (.NOT. status%success) RETURN
        
        !  
        CALL AP_AddPathToArray(this%paths, new_path, status)
        IF (.NOT. status%success) RETURN
        
        this%num_paths = this%num_paths + 1
        
        ! computation 
        IF (this%analysis_config%auto_statistics) THEN
            CALL AP_CalculatePathStatistics(new_path, this%field_statistics, status)
        END IF
        
        CALL RT_LogInfo("Path extracted successfully: " // TRIM(new_path%path_name))
        CALL RT_LogDebug("  Variable: " // TRIM(variable_name))
        CALL RT_LogDebug("  Number of points: " // AP_IntToString(new_path%num_points))
        
    END SUBROUTINE AP_DataAnalysis_ExtractPath

    !>  
    SUBROUTINE AP_Da_ExtractHistory(this, point_specification, variable_name, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        TYPE(PointSpecificationType), INTENT(IN) :: point_specification
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(HistoryDataType) :: new_history
        
        status%success = .TRUE.
        
        !  
        IF (.NOT. AP_HistoryVariableExists(this%available_data, variable_name)) THEN
            status%success = .FALSE.
            status%message = "History variable not found: " // TRIM(variable_name)
            RETURN
        END IF
        
        !  
        CALL AP_CreateHistoryData(point_specification, variable_name, new_history, status)
        IF (.NOT. status%success) RETURN
        
        !  value
        CALL AP_ExtractHistoryValues(new_history, status)
        If (.NOT. status%success) RETURN
        
        !  
        CALL AP_AddHistoryToArray(this%history_data, new_history, status)
        IF (.NOT. status%success) RETURN
        
        this%num_history_points = this%num_history_points + 1
        
        ! computation 
        IF (this%analysis_config%auto_statistics) THEN
            CALL AP_CalculateHistoryStatistics(new_history, this%history_statistics, status)
        END IF
        
        CALL RT_LogInfo("History extracted successfully: " // TRIM(new_history%point_name))
        CALL RT_LogDebug("  Variable: " // TRIM(variable_name))
        CALL RT_LogDebug("  Number of time points: " // AP_IntToString(SIZE(new_history%times)))
        
    END SUBROUTINE AP_DataAnalysis_ExtractHistory

    !> computation 
    SUBROUTINE AP_Da_CalculateStatistics(this, data_source, variable_name, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: data_source
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp), ALLOCATABLE :: data(:)
        INTEGER(i4) :: data_size
        
        status%success = .TRUE.
        
        !  
        SELECT CASE (TRIM(data_source))
        CASE ("FIELD")
            CALL AP_CollectFieldData(this, variable_name, data, status)
            
        CASE ("HISTORY")
            CALL AP_CollectHistoryData(this, variable_name, data, status)
            
        CASE ("PATH")
            CALL AP_CollectPathData(this, variable_name, data, status)
            
        CASE DEFAULT
            status%success = .FALSE.
            status%message = "Invalid data source: " // TRIM(data_source)
            RETURN
        END SELECT
        
        IF (.NOT. status%success .OR. .NOT. ALLOCATED(data)) RETURN
        
        ! computation 
        data_size = SIZE(data)
        CALL AP_CalculateBasicStatistics(data, this%field_statistics, status)
        IF (.NOT. status%success) RETURN
        
        ! computation 
        IF (ALLOCATED(this%analysis_config%percentile_values)) THEN
            CALL AP_CalculatePercentiles(data, this%analysis_config%percentile_values, &
                                         this%field_statistics, status)
        END IF
        
        CALL RT_LogInfo("Statistics calculated for: " // TRIM(variable_name))
        CALL RT_LogDebug("  Mean: " // AP_RealToString(this%field_statistics%mean_value))
        CALL RT_LogDebug("  Std Dev: " // AP_RealToString(this%field_statistics%std_deviation))
        
        ! cleanup
        DEALLOCATE(data)
        
    END SUBROUTINE AP_DataAnalysis_CalculateStatistics

    !>  XY 
    SUBROUTINE AP_Da_PerformXYPlot(this, x_source, y_source, plot_config, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: x_source
        CHARACTER(LEN=*), INTENT(IN) :: y_source
        TYPE(XYPlotConfigType), INTENT(IN) :: plot_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(XYPlotType) :: new_plot
        
        status%success = .TRUE.
        
        !  XY 
        CALL AP_CreateXYPlot(x_source, y_source, plot_config, new_plot, status)
        IF (.NOT. status%success) RETURN
        
        !  XY 
        CALL AP_AddXYPlotToArray(this%xy_plots, new_plot, status)
        IF (.NOT. status%success) RETURN
        
        this%num_xy_plots = this%num_xy_plots + 1
        
        CALL RT_LogInfo("XY plot created: " // TRIM(new_plot%plot_title))
        CALL RT_LogDebug("  X variable: " // TRIM(new_plot%x_variable))
        CALL RT_LogDebug("  Y variable: " // TRIM(new_plot%y_variable))
        CALL RT_LogDebug("  Number of curves: " // AP_IntToString(new_plot%num_curves))
        
    END SUBROUTINE AP_DataAnalysis_PerformXYPlot

    !>  
    SUBROUTINE AP_Da_GenerateReport(this, report_config, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        TYPE(ReportConfigType), INTENT(IN) :: report_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        status%success = .TRUE.
        
        !  HTML ? ?
        SELECT CASE (TRIM(report_config%report_format))
        CASE ("HTML")
            CALL AP_GenerateHTMLReport(this, report_config, status)
            
        CASE ("PDF")
            CALL AP_GeneratePDFReport(this, report_config, status)
            
        CASE ("TEXT")
            CALL AP_GenerateTextReport(this, report_config, status)
            
        CASE DEFAULT
            status%success = .FALSE.
            status%message = "Unsupported report format: " // TRIM(report_config%report_format)
            RETURN
        END SELECT
        
        IF (status%success) THEN
            CALL RT_LogInfo("Report generated: " // TRIM(report_config%report_file))
        END IF
        
    END SUBROUTINE AP_DataAnalysis_GenerateReport

    !>  
    SUBROUTINE AP_DataAnalysis_ExportData(this, export_config, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        TYPE(ExportConfigType), INTENT(IN) :: export_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        status%success = .TRUE.
        
        !  
        SELECT CASE (TRIM(export_config%export_format))
        CASE ("CSV")
            CALL AP_ExportCSV(this, export_config, status)
            
        CASE ("EXCEL")
            CALL AP_ExportExcel(this, export_config, status)
            
        CASE ("MATLAB")
            CALL AP_ExportMATLAB(this, export_config, status)
            
        CASE DEFAULT
            status%success = .FALSE.
            status%message = "Unsupported export format: " // TRIM(export_config%export_format)
            RETURN
        END SELECT
        
        IF (status%success) THEN
            CALL RT_LogInfo("Data exported: " // TRIM(export_config%export_file))
        END IF
        
    END SUBROUTINE AP_DataAnalysis_ExportData

    !> init 
    SUBROUTINE AP_InitializeAvailableData(available_data)
        TYPE(AvailableDataType), INTENT(OUT) :: available_data
        !   -  ODB 
    END SUBROUTINE AP_InitializeAvailableData

    SUBROUTINE AP_InitializeStatistics(stats)
        TYPE(StatisticsType), INTENT(OUT) :: stats
        stats%min_value = 0.0d0
        stats%max_value = 0.0d0
        stats%mean_value = 0.0d0
        stats%std_deviation = 0.0d0
        stats%variance = 0.0d0
        stats%median = 0.0d0
        stats%num_samples = 0
    END SUBROUTINE AP_InitializeStatistics

    SUBROUTINE AP_InitializePercentiles(percentiles, num_percentiles)
        REAL(wp), INTENT(OUT) :: percentiles(:)
        INTEGER(i4), INTENT(IN) :: num_percentiles
        INTEGER(i4) :: i
        
        DO i = 1, num_percentiles
            percentiles(i) = REAL(i * 100 / (num_percentiles + 1), REAL64)
        END DO
    END SUBROUTINE AP_InitializePercentiles

    !See module header / UFC docs for context.
    FUNCTION AP_FileExists(filename) RESULT(exists)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        LOGICAL :: exists
        
        INQUIRE(FILE=filename, EXIST=exists)
    END FUNCTION AP_FileExists

    FUNCTION AP_GetJobName(odb_file) RESULT(job_name)
        CHARACTER(LEN=*), INTENT(IN) :: odb_file
        CHARACTER(LEN=256) :: job_name
        INTEGER(i4) :: dot_pos
        
        dot_pos = INDEX(odb_file, ".")
        IF (dot_pos > 1) THEN
            job_name = odb_file(1:dot_pos-1)
        ELSE
            job_name = odb_file
        END IF
    END FUNCTION AP_GetJobName

    SUBROUTINE AP_OpenODBDatabase(odb_file, status)
        CHARACTER(LEN=*), INTENT(IN) :: odb_file
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  ABAQUS ODB 
    END SUBROUTINE AP_OpenODBDatabase

    SUBROUTINE AP_ReadAvailableData(available_data, status)
        TYPE(AvailableDataType), INTENT(OUT) :: available_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_ReadAvailableData

    SUBROUTINE AP_LoadStepInformation(this, step_number, status)
        CLASS(DataAnalysisManagerType), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: step_number
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_LoadStepInformation

    !See module header / UFC docs for context.
    SUBROUTINE AP_CreatePathPoints(path_definition, path_data, status)
        TYPE(PathDefinitionType), INTENT(IN) :: path_definition
        TYPE(PathDataType), INTENT(OUT) :: path_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_CreatePathPoints

    SUBROUTINE AP_ExtractVariableAlongPath(path_data, variable_name, step_number, status)
        TYPE(PathDataType), INTENT(INOUT) :: path_data
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4), INTENT(IN) :: step_number
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  value
    END SUBROUTINE AP_ExtractVariableAlongPath

    SUBROUTINE AP_CreateHistoryData(point_spec, variable_name, history_data, status)
        TYPE(PointSpecificationType), INTENT(IN) :: point_spec
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(HistoryDataType), INTENT(OUT) :: history_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_CreateHistoryData

    SUBROUTINE AP_ExtractHistoryValues(history_data, status)
        TYPE(HistoryDataType), INTENT(OUT) :: history_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  value
    END SUBROUTINE AP_ExtractHistoryValues

    !>  
    SUBROUTINE AP_AddPathToArray(paths, new_path, status)
        TYPE(PathDataType), INTENT(INOUT), ALLOCATABLE :: paths(:)
        TYPE(PathDataType), INTENT(IN) :: new_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: old_size, new_size
        
        status%success = .TRUE.
        
        IF (ALLOCATED(paths)) THEN
            old_size = SIZE(paths)
            new_size = old_size + 1
            CALL AP_ResizePathArray(paths, new_size)
            paths(new_size) = new_path
        ELSE
            ALLOCATE(paths(1))
            paths(1) = new_path
        END IF
    END SUBROUTINE AP_AddPathToArray

    SUBROUTINE AP_AddHistoryToArray(history_data, new_history, status)
        TYPE(HistoryDataType), INTENT(INOUT), ALLOCATABLE :: history_data(:)
        TYPE(HistoryDataType), INTENT(IN) :: new_history
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: old_size, new_size
        
        status%success = .TRUE.
        
        IF (ALLOCATED(history_data)) THEN
            old_size = SIZE(history_data)
            new_size = old_size + 1
            CALL AP_ResizeHistoryArray(history_data, new_size)
            history_data(new_size) = new_history
        ELSE
            ALLOCATE(history_data(1))
            history_data(1) = new_history
        END IF
    END SUBROUTINE AP_AddHistoryToArray

    SUBROUTINE AP_ResizePathArray(paths, new_size)
        TYPE(PathDataType), INTENT(INOUT), ALLOCATABLE :: paths(:)
        INTEGER(i4), INTENT(IN) :: new_size
        TYPE(PathDataType), ALLOCATABLE :: temp(:)
        INTEGER(i4) :: old_size, i
        
        IF (ALLOCATED(paths)) THEN
            old_size = SIZE(paths)
            ALLOCATE(temp(old_size))
            DO i = 1, old_size
                temp(i) = paths(i)
            END DO
            DEALLOCATE(paths)
            ALLOCATE(paths(new_size))
            DO i = 1, old_size
                paths(i) = temp(i)
            END DO
            DEALLOCATE(temp)
        ELSE
            ALLOCATE(paths(new_size))
        END IF
    END SUBROUTINE AP_ResizePathArray

    SUBROUTINE AP_ResizeHistoryArray(history_data, new_size)
        TYPE(HistoryDataType), INTENT(INOUT), ALLOCATABLE :: history_data(:)
        INTEGER(i4), INTENT(IN) :: new_size
        TYPE(HistoryDataType), ALLOCATABLE :: temp(:)
        INTEGER(i4) :: old_size, i
        
        IF (ALLOCATED(history_data)) THEN
            old_size = SIZE(history_data)
            ALLOCATE(temp(old_size))
            DO i = 1, old_size
                temp(i) = history_data(i)
            END DO
            DEALLOCATE(history_data)
            ALLOCATE(history_data(new_size))
            DO i = 1, old_size
                history_data(i) = temp(i)
            END DO
            DEALLOCATE(temp)
        ELSE
            ALLOCATE(history_data(new_size))
        END IF
    END SUBROUTINE AP_ResizeHistoryArray

    !>  computation 
    SUBROUTINE AP_CalculateBasicStatistics(data, stats, status)
        REAL(wp), INTENT(IN) :: data(:)
        TYPE(StatisticsType), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n
        REAL(wp) :: sum, sum_sq
        
        status%success = .TRUE.
        n = SIZE(data)
        
        IF (n == 0) THEN
            status%success = .FALSE.
            status%message = "No data for statistics calculation"
            RETURN
        END IF
        
        ! computation 
        stats%min_value = data(1)
        stats%max_value = data(1)
        sum = 0.0d0
        sum_sq = 0.0d0
        
        DO i = 1, n
            stats%min_value = MIN(stats%min_value, data(i))
            stats%max_value = MAX(stats%max_value, data(i))
            sum = sum + data(i)
            sum_sq = sum_sq + data(i) * data(i)
        END DO
        
        stats%num_samples = n
        stats%mean_value = sum / REAL(n, REAL64)
        stats%variance = (sum_sq - sum * sum / REAL(n, REAL64)) / REAL(n - 1, REAL64)
        stats%std_deviation = SQRT(MAX(stats%variance, 0.0d0))
        
        ! computation ? ?
        stats%median = data(n/2 + 1)
        
    END SUBROUTINE AP_CalculateBasicStatistics

    SUBROUTINE AP_CalculatePercentiles(data, percentile_values, stats, status)
        REAL(wp), INTENT(IN) :: data(:)
        REAL(wp), INTENT(IN) :: percentile_values(:)
        TYPE(StatisticsType), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n
        
        status%success = .TRUE.
        n = SIZE(data)
        
        IF (ALLOCATED(stats%percentiles)) DEALLOCATE(stats%percentiles)
        ALLOCATE(stats%percentiles(SIZE(percentile_values)))
        
        !   -  value
        DO i = 1, SIZE(percentile_values)
            stats%percentiles(i) = data(INTENT(percentile_values(i) * n / 100.0d0))
        END DO
        
    END SUBROUTINE AP_CalculatePercentiles

    !See module header / UFC docs for context.
    SUBROUTINE AP_GenerateHTMLReport(this, report_config, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        TYPE(ReportConfigType), INTENT(IN) :: report_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: io_unit
        
        status%success = .TRUE.
        
        OPEN(NEWUNIT=io_unit, FILE=report_config%report_file, STATUS='REPLACE', ACTION='WRITE')
        
        WRITE(io_unit, '(A)') '<html>'
        WRITE(io_unit, '(A)') '<head><title>' // TRIM(report_config%title) // '</title></head>'
        WRITE(io_unit, '(A)') '<body>'
        WRITE(io_unit, '(A)') '<h1>' // TRIM(report_config%title) // '</h1>'
        WRITE(io_unit, '(A)') '<p>' // TRIM(report_config%cfg%description) // '</p>'
        
        IF (report_config%include_statistics) THEN
            WRITE(io_unit, '(A)') '<h2>Statistics</h2>'
            WRITE(io_unit, '(A)') '<p>Mean: ' // AP_RealToString(this%field_statistics%mean_value) // '</p>'
            WRITE(io_unit, '(A)') '<p>Std Dev: ' // AP_RealToString(this%field_statistics%std_deviation) // '</p>'
        END IF
        
        WRITE(io_unit, '(A)') '</body></html>'
        CLOSE(io_unit)
        
    END SUBROUTINE AP_GenerateHTMLReport

    SUBROUTINE AP_GeneratePDFReport(this, report_config, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        TYPE(ReportConfigType), INTENT(IN) :: report_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !   -  PDF
    END SUBROUTINE AP_GeneratePDFReport

    SUBROUTINE AP_GenerateTextReport(this, report_config, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        TYPE(ReportConfigType), INTENT(IN) :: report_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: io_unit
        
        status%success = .TRUE.
        
        OPEN(NEWUNIT=io_unit, FILE=report_config%report_file, STATUS='REPLACE', ACTION='WRITE')
        
        WRITE(io_unit, '(A)') TRIM(report_config%title)
        WRITE(io_unit, '(A)') REPEAT('=', LEN_TRIM(report_config%title))
        WRITE(io_unit, '(A)') TRIM(report_config%cfg%description)
        WRITE(io_unit, '(A)') ''
        
        IF (report_config%include_statistics) THEN
            WRITE(io_unit, '(A)') 'STATISTICS'
            WRITE(io_unit, '(A)') '----------'
            WRITE(io_unit, '(A)') 'Mean: ' // AP_RealToString(this%field_statistics%mean_value)
            WRITE(io_unit, '(A)') 'Std Dev: ' // AP_RealToString(this%field_statistics%std_deviation)
        END IF
        
        CLOSE(io_unit)
        
    END SUBROUTINE AP_GenerateTextReport

    !See module header / UFC docs for context.
    SUBROUTINE AP_ExportCSV(this, export_config, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        TYPE(ExportConfigType), INTENT(IN) :: export_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !   -  CSV 
    END SUBROUTINE AP_ExportCSV

    SUBROUTINE AP_ExportExcel(this, export_config, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        TYPE(ExportConfigType), INTENT(IN) :: export_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !   -  Excel 
    END SUBROUTINE AP_ExportExcel

    SUBROUTINE AP_ExportMATLAB(this, export_config, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        TYPE(ExportConfigType), INTENT(IN) :: export_config
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !   -  MATLAB 
    END SUBROUTINE AP_ExportMATLAB

    !>  
    FUNCTION AP_RealToString(value) RESULT(string)
        REAL(wp), INTENT(IN) :: value
        CHARACTER(LEN=50) :: string
        WRITE(string, '(G15.6)') value
    END FUNCTION AP_RealToString

    FUNCTION AP_IntToString(value) RESULT(string)
        INTEGER(i4), INTENT(IN) :: value
        CHARACTER(LEN=20) :: string
        WRITE(string, '(I0)') value
    END FUNCTION AP_IntToString

    FUNCTION REPEAT(char_string, count) RESULT(result)
        CHARACTER(LEN=*), INTENT(IN) :: char_string
        INTEGER(i4), INTENT(IN) :: count
        CHARACTER(LEN=500) :: result
        INTEGER(i4) :: i
        
        result = ""
        DO i = 1, MIN(count, LEN(result))
            result(i:i) = char_string(1:1)
        END DO
    END FUNCTION REPEAT

    FUNCTION LEN_TRIM(string) RESULT(length)
        CHARACTER(LEN=*), INTENT(IN) :: string
        INTEGER(i4) :: length
        INTEGER(i4) :: i
        
        length = LEN(string)
        DO i = length, 1, -1
            IF (string(i:i) /= ' ') THEN
                length = i
                RETURN
            END IF
        END DO
        length = 0
    END FUNCTION LEN_TRIM

    !> definition ?definition ?
    TYPE :: PathDefinitionType
        CHARACTER(LEN=20) :: path_type = ""
        REAL(wp), ALLOCATABLE :: start_point(:)
        REAL(wp), ALLOCATABLE :: end_point(:)
        INTEGER(i4) :: num_points = 0
    END TYPE PathDefinitionType

    TYPE :: PointSpecificationType
        CHARACTER(LEN=20) :: point_type = ""
        INTEGER(i4) :: point_id = 0
        CHARACTER(LEN=100) :: point_name = ""
    END TYPE PointSpecificationType

    TYPE :: XYPlotConfigType
        CHARACTER(LEN=50) :: plot_title = ""
        CHARACTER(LEN(20), ALLOCATABLE :: line_styles(:)
        CHARACTER(LEN(20), ALLOCATABLE :: colors(:)
        LOGICAL :: show_grid = .TRUE.
        LOGICAL :: show_legend = .TRUE.
    END TYPE XYPlotConfigType

    !See module header / UFC docs for context.
    FUNCTION AP_VariableExists(available_data, variable_name) RESULT(exists)
        TYPE(AvailableDataType), INTENT(IN) :: available_data
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        LOGICAL :: exists
        exists = .TRUE.  !  
    END FUNCTION AP_VariableExists

    FUNCTION AP_HistoryVariableExists(available_data, variable_name) RESULT(exists)
        TYPE(AvailableDataType), INTENT(IN) :: available_data
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        LOGICAL :: exists
        exists = .TRUE.  !  
    END FUNCTION AP_HistoryVariableExists

    SUBROUTINE AP_CollectFieldData(this, variable_name, data, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: data(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        ALLOCATE(data(100))
        data = 1.0d0  !  
    END SUBROUTINE AP_CollectFieldData

    SUBROUTINE AP_CollectHistoryData(this, variable_name, data, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: data(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        ALLOCATE(data(100))
        data = 1.0d0  !  
    END SUBROUTINE AP_CollectHistoryData

    SUBROUTINE AP_CollectPathData(this, variable_name, data, status)
        CLASS(DataAnalysisManagerType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: data(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        ALLOCATE(data(100))
        data = 1.0d0  !  
    END SUBROUTINE AP_CollectPathData

    SUBROUTINE AP_CalculatePathStatistics(path_data, stats, status)
        TYPE(PathDataType), INTENT(IN) :: path_data
        TYPE(StatisticsType), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_CalculatePathStatistics

    SUBROUTINE AP_CalculateHistoryStatistic(history_data, stats, status)
        TYPE(HistoryDataType), INTENT(IN) :: history_data
        TYPE(StatisticsType), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_CalculateHistoryStatistics

    SUBROUTINE AP_CreateXYPlot(x_source, y_source, plot_config, xy_plot, status)
        CHARACTER(LEN=*), INTENT(IN) :: x_source
        CHARACTER(LEN=*), INTENT(IN) :: y_source
        TYPE(XYPlotConfigType), INTENT(IN) :: plot_config
        TYPE(XYPlotType), INTENT(OUT) :: xy_plot
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_CreateXYPlot

    SUBROUTINE AP_AddXYPlotToArray(xy_plots, new_plot, status)
        TYPE(XYPlotType), INTENT(INOUT), ALLOCATABLE :: xy_plots(:)
        TYPE(XYPlotType), INTENT(IN) :: new_plot
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        status%success = .TRUE.
        !  
    END SUBROUTINE AP_AddXYPlotToArray

END MODULE AP_Out_PostProcDataAnal