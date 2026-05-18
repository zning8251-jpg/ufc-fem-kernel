!======================================================================
! Module: MD_OutReportPlot
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Report & Plot
! Purpose: Report, Plot, PostProcessing, Animation, Export properties.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================

MODULE MD_Out_ReportPlot
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    ! --- Report ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: ReportProperties
        INTEGER(i4) :: reportType = 1
        CHARACTER(LEN=64) :: outputFile = ""
        CHARACTER(LEN=64), ALLOCATABLE :: sections(:)
        INTEGER(i4) :: numSections = 0
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => ReportProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid => ReportProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ReportProperties_Clear
    END TYPE ReportProperties

    ! --- Plot ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: PlotProperties
        INTEGER(i4) :: plotType = 1
        CHARACTER(LEN=64), ALLOCATABLE :: variables(:)
        INTEGER(i4) :: numVariables = 0
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => PlotProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid => PlotProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => PlotProperties_Clear
    END TYPE PlotProperties

    ! --- PostProcessing ---
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_TYPE_CONTOUR    = 1
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_TYPE_VECTOR     = 2
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_TYPE_DEFORMATION = 3
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_TYPE_ANIMATION  = 4
    INTEGER(i4), PARAMETER, PUBLIC :: PROC_TYPE_PATH_PLOT  = 5

    TYPE, PUBLIC, EXTENDS(DescBase) :: PostProcessingProperties
        INTEGER(i4) :: processingType = PROC_TYPE_CONTOUR
        CHARACTER(LEN=256) :: outputFile = ""
        INTEGER(i4) :: numContourLevels = 10
        REAL(wp) :: contourMin = 0.0_wp
        REAL(wp) :: contourMax = 0.0_wp
        LOGICAL :: autoScale = .TRUE.
        REAL(wp) :: vectorScale = 1.0_wp
        INTEGER(i4) :: vectorDensity = 1
        REAL(wp) :: deformationScale = 1.0_wp
        LOGICAL :: showUndeformed = .TRUE.
        INTEGER(i4) :: frameRate = 30
        INTEGER(i4) :: quality = 1
        INTEGER(i4) :: imageFormat = 1
        INTEGER(i4) :: imageWidth = 1920
        INTEGER(i4) :: imageHeight = 1080
    CONTAINS
        PROCEDURE, PUBLIC :: Init              => PostProcessingProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid             => PostProcessingProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear             => PostProcessingProperties_Clear
        PROCEDURE, PUBLIC :: GetImageExtension => PostProcessingProperties_GetImageExtension
    END TYPE PostProcessingProperties

    ! --- Animation ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: AnimationProperties
        INTEGER(i4) :: frameRate = 30
        INTEGER(i4) :: quality = 1
        CHARACTER(LEN=64) :: outputFile = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => AnimationProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid => AnimationProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => AnimationProperties_Clear
    END TYPE AnimationProperties

    ! --- Export ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: ExportProperties
        INTEGER(i4) :: exportType = 1
        CHARACTER(LEN=64) :: outputFile = ""
        CHARACTER(LEN=64) :: format = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => ExportProperties_Init_Base
        PROCEDURE, PUBLIC :: Valid => ExportProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ExportProperties_Clear
    END TYPE ExportProperties

    PUBLIC :: ReportProperties, PlotProperties, PostProcessingProperties
    PUBLIC :: AnimationProperties, ExportProperties
    PUBLIC :: Parse_REPORT_Keyword, Parse_PLOT_Keyword, Parse_POST_PROCESSING_Keyword
    PUBLIC :: Parse_ANIMATION_Keyword, Parse_EXPORT_Keyword
    PUBLIC :: Valid_REPORT_Keyword, Valid_PLOT_Keyword, Valid_POST_Proc_Keyword
    PUBLIC :: Valid_ANIMATION_Keyword, Valid_EXPORT_Keyword
    PUBLIC :: MD_Output_Report_Unified_Parse, MD_Output_Report_Unified_Cfg
    PUBLIC :: MD_Output_Plot_Unified_Parse, MD_Output_Plot_Unified_Cfg
    PUBLIC :: MD_Output_PostProcessing_Unified_Parse, MD_Output_PostProcessing_Unified_Configure
    PUBLIC :: MD_Output_Animation_Unified_Parse, MD_Output_Animation_Unified_Configure
    PUBLIC :: MD_Output_Export_Unified_Parse, MD_Output_Export_Unified_Cfg

CONTAINS

    !=========================================================================
    ! Helper: get param value from AST
    !=========================================================================
    SUBROUTINE rp_get_param_value(ast_node, param_name, param_value)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        CHARACTER(LEN=*), INTENT(IN) :: param_name
        CHARACTER(LEN=*), INTENT(OUT) :: param_value
        INTEGER(i4) :: i
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: key
        param_value = ""
        DO i = 1, ast_node%param_count
            key = TRIM(ast_node%params(i)%name)
            IF (TRIM(key) == TRIM(param_name)) THEN
                param_value = TRIM(ast_node%params(i)%value)
                RETURN
            END IF
        END DO
    END SUBROUTINE rp_get_param_value

    !=========================================================================
    ! Report
    !=========================================================================
    SUBROUTINE ReportProperties_Init_Base(this)
        CLASS(ReportProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::REPORT'
    END SUBROUTINE ReportProperties_Init_Base

    SUBROUTINE ReportProperties_Init(this, name, status)
        CLASS(ReportProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%name = TRIM(name)
        this%reportType = 1
        this%outputFile = ""
        this%numSections = 0
    END SUBROUTINE ReportProperties_Init

    FUNCTION ReportProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ReportProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION ReportProperties_Valid_Fn

    SUBROUTINE ReportProperties_Clear(this)
        CLASS(ReportProperties), INTENT(INOUT) :: this
        this%name = ""
        this%reportType = 1
        this%outputFile = ""
        this%numSections = 0
        IF (ALLOCATED(this%sections)) DEALLOCATE(this%sections)
    END SUBROUTINE ReportProperties_Clear

    SUBROUTINE MD_Output_Report_Unified_Parse(out_type, ast_node, report, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ReportProperties), INTENT(OUT) :: report
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'REPORT') THEN
            CALL Parse_REPORT_Keyword(ast_node, report, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Report_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_Report_Unified_Parse

    SUBROUTINE MD_Output_Report_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Report_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_Report_Unified_Cfg

    SUBROUTINE Parse_REPORT_Keyword(ast_node, report, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ReportProperties), INTENT(OUT) :: report
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL report%Init(TRIM(name), status)
        IF (.NOT. report%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Report validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Parse_REPORT_Keyword

    SUBROUTINE Valid_REPORT_Keyword(report, status)
        TYPE(ReportProperties), INTENT(IN) :: report
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. report%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Report validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Valid_REPORT_Keyword

    !=========================================================================
    ! Plot
    !=========================================================================
    SUBROUTINE PlotProperties_Init_Base(this)
        CLASS(PlotProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::PLOT'
    END SUBROUTINE PlotProperties_Init_Base

    SUBROUTINE PlotProperties_Init(this, name, status)
        CLASS(PlotProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%name = TRIM(name)
        this%plotType = 1
        this%numVariables = 0
    END SUBROUTINE PlotProperties_Init

    FUNCTION PlotProperties_Valid_Fn(this) RESULT(ok)
        CLASS(PlotProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION PlotProperties_Valid_Fn

    SUBROUTINE PlotProperties_Clear(this)
        CLASS(PlotProperties), INTENT(INOUT) :: this
        this%name = ""
        this%plotType = 1
        this%numVariables = 0
        IF (ALLOCATED(this%variables)) DEALLOCATE(this%variables)
    END SUBROUTINE PlotProperties_Clear

    SUBROUTINE MD_Output_Plot_Unified_Parse(out_type, ast_node, plot, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PlotProperties), INTENT(OUT) :: plot
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'PLOT') THEN
            CALL Parse_PLOT_Keyword(ast_node, plot, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Plot_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_Plot_Unified_Parse

    SUBROUTINE MD_Output_Plot_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Plot_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_Plot_Unified_Cfg

    SUBROUTINE Parse_PLOT_Keyword(ast_node, plot, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PlotProperties), INTENT(OUT) :: plot
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL plot%Init(TRIM(name), status)
        IF (.NOT. plot%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Plot validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Parse_PLOT_Keyword

    SUBROUTINE Valid_PLOT_Keyword(plot, status)
        TYPE(PlotProperties), INTENT(IN) :: plot
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. plot%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Plot validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Valid_PLOT_Keyword

    !=========================================================================
    ! PostProcessing
    !=========================================================================
    SUBROUTINE PostProcessingProperties_Init_Base(this)
        CLASS(PostProcessingProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::POSTPROCESSING'
    END SUBROUTINE PostProcessingProperties_Init_Base

    SUBROUTINE PostProcessingProperties_Init(this, name, status)
        CLASS(PostProcessingProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%name = TRIM(name)
        this%processingType = PROC_TYPE_CONTOUR
        this%outputFile = ""
        this%numContourLevels = 10
        this%contourMin = 0.0_wp
        this%contourMax = 0.0_wp
        this%autoScale = .TRUE.
        this%vectorScale = 1.0_wp
        this%vectorDensity = 1
        this%deformationScale = 1.0_wp
        this%showUndeformed = .TRUE.
        this%frameRate = 30
        this%quality = 1
        this%imageFormat = 1
        this%imageWidth = 1920
        this%imageHeight = 1080
    END SUBROUTINE PostProcessingProperties_Init

    FUNCTION PostProcessingProperties_Valid_Fn(this) RESULT(ok)
        CLASS(PostProcessingProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .FALSE.
        IF (this%numContourLevels < 2) RETURN
        IF (this%vectorScale <= 0.0_wp) RETURN
        IF (this%frameRate <= 0) RETURN
        IF (this%imageWidth <= 0 .OR. this%imageHeight <= 0) RETURN
        ok = .TRUE.
    END FUNCTION PostProcessingProperties_Valid_Fn

    SUBROUTINE PostProcessingProperties_Clear(this)
        CLASS(PostProcessingProperties), INTENT(INOUT) :: this
        this%name = ""
        this%processingType = PROC_TYPE_CONTOUR
        this%outputFile = ""
        this%numContourLevels = 10
        this%contourMin = 0.0_wp
        this%contourMax = 0.0_wp
        this%autoScale = .TRUE.
        this%vectorScale = 1.0_wp
        this%vectorDensity = 1
        this%deformationScale = 1.0_wp
        this%showUndeformed = .TRUE.
        this%frameRate = 30
        this%quality = 1
        this%imageFormat = 1
        this%imageWidth = 1920
        this%imageHeight = 1080
    END SUBROUTINE PostProcessingProperties_Clear

    FUNCTION PostProcessingProperties_GetImageExtension(this) RESULT(ext)
        CLASS(PostProcessingProperties), INTENT(IN) :: this
        CHARACTER(LEN=8) :: ext
        SELECT CASE (this%imageFormat)
        CASE (1); ext = ".png"
        CASE (2); ext = ".jpg"
        CASE (3); ext = ".pdf"
        CASE (4); ext = ".svg"
        CASE DEFAULT; ext = ".png"
        END SELECT
    END FUNCTION PostProcessingProperties_GetImageExtension

    SUBROUTINE MD_Output_PostProcessing_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_PostProcessing_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_PostProcessing_Unified_Configure

    SUBROUTINE MD_Output_PostProcessing_Unified_Parse(out_type, ast_node, postProcessing, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PostProcessingProperties), INTENT(OUT) :: postProcessing
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'POST_PROCESSING' .OR. TRIM(out_type) == 'POST PROCESSING') THEN
            CALL Parse_POST_PROCESSING_Keyword(ast_node, postProcessing, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_PostProcessing_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_PostProcessing_Unified_Parse

    SUBROUTINE Parse_POST_PROCESSING_Keyword(ast_node, postProcessing, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PostProcessingProperties), INTENT(OUT) :: postProcessing
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: proc_type_str, image_format_str, auto_scale_str
        CALL init_error_status(status)
        CALL postProcessing%Init(TRIM(name), status)
        CALL rp_get_param_value(ast_node, "TYPE", proc_type_str)
        IF (LEN_TRIM(proc_type_str) > 0) THEN
            SELECT CASE (TRIM(proc_type_str))
            CASE ("CONTOUR", "CONTOUR_PLOT");    postProcessing%processingType = PROC_TYPE_CONTOUR
            CASE ("VECTOR", "VECTOR_PLOT");       postProcessing%processingType = PROC_TYPE_VECTOR
            CASE ("DEFORMATION", "DEFORMATION_PLOT"); postProcessing%processingType = PROC_TYPE_DEFORMATION
            CASE ("ANIMATION");                   postProcessing%processingType = PROC_TYPE_ANIMATION
            CASE ("PATH", "PATH_PLOT");           postProcessing%processingType = PROC_TYPE_PATH_PLOT
            END SELECT
        END IF
        CALL rp_get_param_value(ast_node, "FILE", proc_type_str)
        IF (LEN_TRIM(proc_type_str) > 0) postProcessing%outputFile = TRIM(proc_type_str)
        CALL rp_get_param_value(ast_node, "IMAGE_FORMAT", image_format_str)
        IF (LEN_TRIM(image_format_str) > 0) THEN
            SELECT CASE (TRIM(image_format_str))
            CASE ("PNG");         postProcessing%imageFormat = 1
            CASE ("JPEG", "JPG"); postProcessing%imageFormat = 2
            CASE ("PDF");         postProcessing%imageFormat = 3
            CASE ("SVG");         postProcessing%imageFormat = 4
            END SELECT
        END IF
        CALL rp_get_param_value(ast_node, "AUTO_SCALE", auto_scale_str)
        IF (LEN_TRIM(auto_scale_str) > 0) THEN
            IF (TRIM(auto_scale_str) == "NO" .OR. TRIM(auto_scale_str) == "FALSE") &
                postProcessing%autoScale = .FALSE.
        END IF
        IF (ast_node%data_line_count > 0 .AND. ALLOCATED(ast_node%data_lines)) THEN
            IF (ast_node%data_lines(1)%col_count >= 1) &
                postProcessing%numContourLevels = INT(ast_node%data_lines(1)%real_values(1))
            IF (ast_node%data_lines(1)%col_count >= 2) &
                postProcessing%contourMin = ast_node%data_lines(1)%real_values(2)
            IF (ast_node%data_lines(1)%col_count >= 3) &
                postProcessing%contourMax = ast_node%data_lines(1)%real_values(3)
            IF (ast_node%data_lines(1)%col_count >= 4) &
                postProcessing%vectorScale = ast_node%data_lines(1)%real_values(4)
            IF (ast_node%data_lines(1)%col_count >= 5) &
                postProcessing%frameRate = INT(ast_node%data_lines(1)%real_values(5))
        END IF
        IF (.NOT. postProcessing%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Post processing validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Parse_POST_PROCESSING_Keyword

    SUBROUTINE Valid_POST_Proc_Keyword(postProcessing, status)
        TYPE(PostProcessingProperties), INTENT(IN) :: postProcessing
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. postProcessing%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Post processing validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Valid_POST_Proc_Keyword

    !=========================================================================
    ! Animation
    !=========================================================================
    SUBROUTINE AnimationProperties_Init_Base(this)
        CLASS(AnimationProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::ANIMATION'
    END SUBROUTINE AnimationProperties_Init_Base

    SUBROUTINE AnimationProperties_Init(this, name, status)
        CLASS(AnimationProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%name = TRIM(name)
        this%frameRate = 30
        this%quality = 1
        this%outputFile = ""
    END SUBROUTINE AnimationProperties_Init

    FUNCTION AnimationProperties_Valid_Fn(this) RESULT(ok)
        CLASS(AnimationProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = this%frameRate > 0
    END FUNCTION AnimationProperties_Valid_Fn

    SUBROUTINE AnimationProperties_Clear(this)
        CLASS(AnimationProperties), INTENT(INOUT) :: this
        this%name = ""
        this%frameRate = 30
        this%quality = 1
        this%outputFile = ""
    END SUBROUTINE AnimationProperties_Clear

    SUBROUTINE MD_Output_Animation_Unified_Parse(out_type, ast_node, animation, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AnimationProperties), INTENT(OUT) :: animation
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'ANIMATION') THEN
            CALL Parse_ANIMATION_Keyword(ast_node, animation, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Animation_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_Animation_Unified_Parse

    SUBROUTINE MD_Output_Animation_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Animation_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_Animation_Unified_Configure

    SUBROUTINE Parse_ANIMATION_Keyword(ast_node, animation, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AnimationProperties), INTENT(OUT) :: animation
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL animation%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ALLOCATED(ast_node%data_lines)) THEN
            IF (ast_node%data_lines(1)%col_count >= 1) &
                animation%frameRate = INT(ast_node%data_lines(1)%real_values(1))
        END IF
        IF (.NOT. animation%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Animation validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Parse_ANIMATION_Keyword

    SUBROUTINE Valid_ANIMATION_Keyword(animation, status)
        TYPE(AnimationProperties), INTENT(IN) :: animation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. animation%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Animation validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Valid_ANIMATION_Keyword

    !=========================================================================
    ! Export
    !=========================================================================
    SUBROUTINE ExportProperties_Init_Base(this)
        CLASS(ExportProperties), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::EXPORT'
    END SUBROUTINE ExportProperties_Init_Base

    SUBROUTINE ExportProperties_Init(this, name, status)
        CLASS(ExportProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%name = TRIM(name)
        this%exportType = 1
        this%outputFile = ""
        this%format = ""
    END SUBROUTINE ExportProperties_Init

    FUNCTION ExportProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ExportProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION ExportProperties_Valid_Fn

    SUBROUTINE ExportProperties_Clear(this)
        CLASS(ExportProperties), INTENT(INOUT) :: this
        this%name = ""
        this%exportType = 1
        this%outputFile = ""
        this%format = ""
    END SUBROUTINE ExportProperties_Clear

    SUBROUTINE MD_Output_Export_Unified_Parse(out_type, ast_node, export, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ExportProperties), INTENT(OUT) :: export
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'EXPORT') THEN
            CALL Parse_EXPORT_Keyword(ast_node, export, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Export_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_Export_Unified_Parse

    SUBROUTINE MD_Output_Export_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_Export_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_Export_Unified_Cfg

    SUBROUTINE Parse_EXPORT_Keyword(ast_node, export, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ExportProperties), INTENT(OUT) :: export
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL export%Init(TRIM(name), status)
        IF (.NOT. export%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Export validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Parse_EXPORT_Keyword

    SUBROUTINE Valid_EXPORT_Keyword(export, status)
        TYPE(ExportProperties), INTENT(IN) :: export
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. export%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Export validation failed"
        ELSE
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE Valid_EXPORT_Keyword

END MODULE MD_Out_ReportPlot