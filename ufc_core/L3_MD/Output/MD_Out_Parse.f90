!======================================================================
! Module: MD_OutParse
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Parser
! Purpose: Output parser for OutRequest, OutVariable, OutFrequency, OutFormat.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================

MODULE MD_Out_Parse
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    ! --- OutRequest ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: OutRequestProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: outputType = 1
        INTEGER(i4) :: frequency = 1
        REAL(wp) :: timeInterval = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => OutRequestProperties_Init
        PROCEDURE, PUBLIC :: Valid => OutRequestProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => OutRequestProperties_Clear
    END TYPE OutRequestProperties

    ! --- OutVariable ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: OutVariableProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64), ALLOCATABLE :: variables(:)
        INTEGER(i4) :: numVariables = 0
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => OutVariableProperties_Init
        PROCEDURE, PUBLIC :: Valid => OutVariableProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => OutVariableProperties_Clear
    END TYPE OutVariableProperties

    ! --- OutFrequency ---
    TYPE, PUBLIC, EXTENDS(DescBase) :: OutFrequencyProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: frequency = 1
        REAL(wp) :: timeInterval = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => OutFrequencyProperties_Init
        PROCEDURE, PUBLIC :: Valid => OutFrequencyProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => OutFrequencyProperties_Clear
    END TYPE OutFrequencyProperties

    ! --- OutFormat ---
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_ODB  = 1
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_CSV  = 2
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_VTK  = 3
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_HDF5 = 4
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_JSON = 5
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_TXT  = 6
    TYPE, PUBLIC, EXTENDS(DescBase) :: OutFormatProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: formatType = FORMAT_ODB
        CHARACTER(LEN=64) :: formatName = ""
        CHARACTER(LEN=256) :: outputFile = ""
        LOGICAL :: binary = .TRUE.
        LOGICAL :: compressed = .FALSE.
        INTEGER(i4) :: precision = 6
        CHARACTER(LEN=64) :: delimiter = ","
        LOGICAL :: includeHistory = .TRUE.
        LOGICAL :: includeField = .TRUE.
        INTEGER(i4) :: vtkFormat = 1
        INTEGER(i4) :: chunkSize = 1024
        LOGICAL :: useCompression = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init             => OutFormatProperties_Init
        PROCEDURE, PUBLIC :: Valid           => OutFormatProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear           => OutFormatProperties_Clear
        PROCEDURE, PUBLIC :: GetFileExtension => OutFormatProperties_GetFileExtension
    END TYPE OutFormatProperties

    ! --- OutFilter ---
    INTEGER(i4), PARAMETER, PUBLIC :: FILTER_TYPE_VALUE     = 1
    INTEGER(i4), PARAMETER, PUBLIC :: FILTER_TYPE_VARIABLE  = 2
    INTEGER(i4), PARAMETER, PUBLIC :: FILTER_TYPE_REGION    = 3
    INTEGER(i4), PARAMETER, PUBLIC :: FILTER_TYPE_THRESHOLD = 4
    TYPE, PUBLIC, EXTENDS(DescBase) :: OutFilterProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: filterType = FILTER_TYPE_VALUE
        REAL(wp) :: minValue = 0.0_wp
        REAL(wp) :: maxValue = 0.0_wp
        INTEGER(i4) :: numVariables = 0
        CHARACTER(LEN=64), ALLOCATABLE :: variables(:)
        LOGICAL :: includeVariables = .TRUE.
        INTEGER(i4) :: numRegions = 0
        CHARACTER(LEN=64), ALLOCATABLE :: nodeSets(:)
        CHARACTER(LEN=64), ALLOCATABLE :: elementSets(:)
        CHARACTER(LEN=64), ALLOCATABLE :: surfaces(:)
        REAL(wp) :: thresholdValue = 0.0_wp
        INTEGER(i4) :: thresholdOperator = 1
    CONTAINS
        PROCEDURE, PUBLIC :: Init            => OutFilterProperties_Init
        PROCEDURE, PUBLIC :: Valid          => OutFilterProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear          => OutFilterProperties_Clear
        PROCEDURE, PUBLIC :: AddVariable     => OutFilterProperties_AddVariable
        PROCEDURE, PUBLIC :: AddNodeSet      => OutFilterProperties_AddNodeSet
        PROCEDURE, PUBLIC :: AddElementSet   => OutFilterProperties_AddElementSet
        PROCEDURE, PUBLIC :: AddSurface      => OutFilterProperties_AddSurface
        PROCEDURE, PUBLIC :: MatchesVariable => OutFilterProperties_MatchesVariable
        PROCEDURE, PUBLIC :: MatchesRegion   => OutFilterProperties_MatchesRegion
        PROCEDURE, PUBLIC :: MatchesValue    => OutFilterProperties_MatchesValue
    END TYPE OutFilterProperties

    ! --- Public exports ---
    PUBLIC :: OutRequestProperties, OutVariableProperties, OutFrequencyProperties
    PUBLIC :: OutFormatProperties, OutFilterProperties
    PUBLIC :: Parse_OUTPUT_REQUEST_Keyword, Parse_OUTPUT_VARIABLE_Keyword
    PUBLIC :: Parse_OUTPUT_FREQUENCY_Keyword, Validate_OUTPUT_FREQUENCY_Keyword
    PUBLIC :: Parse_OUTPUT_FORMAT_Keyword, Valid_OUTPUT_FORMAT_Keyword
    PUBLIC :: Parse_OUTPUT_FILTER_Keyword, Valid_OUTPUT_FILTER_Keyword
    PUBLIC :: MD_Output_OutputRequest_Unified_Parse, MD_Output_OutputRequest_Unified_Configure
    PUBLIC :: MD_Output_OutputVariable_Unified_Parse, MD_Output_OutputVariable_Unified_Configure
    PUBLIC :: MD_Output_OutputFrequency_Unified_Parse, MD_Output_OutputFrequency_Unified_Configure
    PUBLIC :: MD_Output_OutputFormat_Unified_Parse, MD_Output_OutputFormat_Unified_Configure
    PUBLIC :: MD_Output_OutputFilter_Unified_Parse, MD_Output_OutputFilter_Unified_Configure
    PUBLIC :: UF_FieldOutput_GetStatistics, UF_FieldOutput_ShouldOutput
    PUBLIC :: UF_HistoryOutput_GetStatistics, UF_HistoryOutput_ShouldOutput

CONTAINS

    !=========================================================================
    ! Helper: get param value from AST
    !=========================================================================
    SUBROUTINE md_out_get_param_value(ast_node, param_name, param_value)
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
    END SUBROUTINE md_out_get_param_value

    !=========================================================================
    ! OutRequest
    !=========================================================================
    SUBROUTINE OutRequestProperties_Init(this, name, status)
        CLASS(OutRequestProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%outputType = 1
        this%frequency = 1
        this%timeInterval = 0.0_wp
    END SUBROUTINE OutRequestProperties_Init

    FUNCTION OutRequestProperties_Valid_Fn(this) RESULT(ok)
        CLASS(OutRequestProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION OutRequestProperties_Valid_Fn

    SUBROUTINE OutRequestProperties_Clear(this)
        CLASS(OutRequestProperties), INTENT(INOUT) :: this
        this%name = ""
        this%outputType = 1
        this%frequency = 1
        this%timeInterval = 0.0_wp
    END SUBROUTINE OutRequestProperties_Clear

    SUBROUTINE UF_FieldOutput_GetStatistics(output_req, stats, status)
        TYPE(OutRequestProperties), INTENT(IN) :: output_req
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        WRITE(stats, '(A,A,A,I0,A,ES12.5)') &
            'Field Output Statistics: name="', TRIM(output_req%name), &
            '", frequency=', output_req%frequency, ', timeInterval=', output_req%timeInterval
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE UF_FieldOutput_GetStatistics

    SUBROUTINE UF_FieldOutput_ShouldOutput(output_req, current_time, time_step, should_output, status)
        TYPE(OutRequestProperties), INTENT(IN) :: output_req
        REAL(wp), INTENT(IN) :: current_time, time_step
        LOGICAL, INTENT(OUT) :: should_output
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        IF (output_req%timeInterval > 1.0e-12_wp) THEN
            should_output = (MOD(current_time, output_req%timeInterval) < time_step)
        ELSE
            should_output = (MOD(INT(current_time / time_step), output_req%frequency) == 0)
        END IF
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE UF_FieldOutput_ShouldOutput

    SUBROUTINE UF_HistoryOutput_GetStatistics(output_req, stats, status)
        TYPE(OutRequestProperties), INTENT(IN) :: output_req
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        WRITE(stats, '(A,A,A,I0,A,ES12.5)') &
            'History Output Statistics: name="', TRIM(output_req%name), &
            '", frequency=', output_req%frequency, ', timeInterval=', output_req%timeInterval
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE UF_HistoryOutput_GetStatistics

    SUBROUTINE UF_HistoryOutput_ShouldOutput(output_req, current_time, time_step, should_output, status)
        TYPE(OutRequestProperties), INTENT(IN) :: output_req
        REAL(wp), INTENT(IN) :: current_time, time_step
        LOGICAL, INTENT(OUT) :: should_output
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        IF (output_req%timeInterval > 1.0e-12_wp) THEN
            should_output = (MOD(current_time, output_req%timeInterval) < time_step)
        ELSE
            should_output = (MOD(INT(current_time / time_step), output_req%frequency) == 0)
        END IF
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    END SUBROUTINE UF_HistoryOutput_ShouldOutput

    SUBROUTINE MD_Output_OutputRequest_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputRequest_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_OutputRequest_Unified_Configure

    SUBROUTINE MD_Output_OutputRequest_Unified_Parse(out_type, ast_node, outputRequest, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutRequestProperties), INTENT(OUT) :: outputRequest
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'OUTPUT_REQUEST' .OR. TRIM(out_type) == 'OUTPUT REQUEST') THEN
            CALL Parse_OUTPUT_REQUEST_Keyword(ast_node, outputRequest, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputRequest_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_OutputRequest_Unified_Parse

    SUBROUTINE Parse_OUTPUT_REQUEST_Keyword(ast_node, outputRequest, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutRequestProperties), INTENT(OUT) :: outputRequest
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL outputRequest%Init(TRIM(name), status)
        IF (.NOT. outputRequest%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output request validation failed"
        END IF
    END SUBROUTINE Parse_OUTPUT_REQUEST_Keyword

    !=========================================================================
    ! OutVariable
    !=========================================================================
    SUBROUTINE OutVariableProperties_Init(this, name, status)
        CLASS(OutVariableProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%numVariables = 0
    END SUBROUTINE OutVariableProperties_Init

    FUNCTION OutVariableProperties_Valid_Fn(this) RESULT(ok)
        CLASS(OutVariableProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
    END FUNCTION OutVariableProperties_Valid_Fn

    SUBROUTINE OutVariableProperties_Clear(this)
        CLASS(OutVariableProperties), INTENT(INOUT) :: this
        this%name = ""
        this%numVariables = 0
        IF (ALLOCATED(this%variables)) DEALLOCATE(this%variables)
    END SUBROUTINE OutVariableProperties_Clear

    SUBROUTINE MD_Output_OutputVariable_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputVariable_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_OutputVariable_Unified_Configure

    SUBROUTINE MD_Output_OutputVariable_Unified_Parse(out_type, ast_node, outputVariable, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutVariableProperties), INTENT(OUT) :: outputVariable
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'OUTPUT_VARIABLE' .OR. TRIM(out_type) == 'OUTPUT VARIABLE') THEN
            CALL Parse_OUTPUT_VARIABLE_Keyword(ast_node, outputVariable, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputVariable_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_OutputVariable_Unified_Parse

    SUBROUTINE Parse_OUTPUT_VARIABLE_Keyword(ast_node, outputVariable, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutVariableProperties), INTENT(OUT) :: outputVariable
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL outputVariable%Init(TRIM(name), status)
        IF (.NOT. outputVariable%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output variable validation failed"
        END IF
    END SUBROUTINE Parse_OUTPUT_VARIABLE_Keyword

    !=========================================================================
    ! OutFrequency
    !=========================================================================
    SUBROUTINE OutFrequencyProperties_Init(this, name, status)
        CLASS(OutFrequencyProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%frequency = 1
        this%timeInterval = 0.0_wp
    END SUBROUTINE OutFrequencyProperties_Init

    FUNCTION OutFrequencyProperties_Valid_Fn(this) RESULT(ok)
        CLASS(OutFrequencyProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%frequency <= 0) ok = .FALSE.
        IF (this%timeInterval < 0.0_wp) ok = .FALSE.
    END FUNCTION OutFrequencyProperties_Valid_Fn

    SUBROUTINE OutFrequencyProperties_Clear(this)
        CLASS(OutFrequencyProperties), INTENT(INOUT) :: this
        this%name = ""
        this%frequency = 1
        this%timeInterval = 0.0_wp
    END SUBROUTINE OutFrequencyProperties_Clear

    SUBROUTINE MD_Output_OutputFrequency_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputFrequency_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_OutputFrequency_Unified_Configure

    SUBROUTINE MD_Output_OutputFrequency_Unified_Parse(out_type, ast_node, outputFrequency, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFrequencyProperties), INTENT(OUT) :: outputFrequency
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'OUTPUT_FREQUENCY' .OR. TRIM(out_type) == 'OUTPUT FREQUENCY') THEN
            CALL Parse_OUTPUT_FREQUENCY_Keyword(ast_node, outputFrequency, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputFrequency_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_OutputFrequency_Unified_Parse

    SUBROUTINE Parse_OUTPUT_FREQUENCY_Keyword(ast_node, outputFrequency, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFrequencyProperties), INTENT(OUT) :: outputFrequency
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL outputFrequency%Init(TRIM(name), status)
        IF (ast_node%data_line_count > 0 .AND. ALLOCATED(ast_node%data_lines) .AND. &
            ast_node%data_lines(1)%col_count >= 1) THEN
            outputFrequency%frequency = INT(ast_node%data_lines(1)%real_values(1))
        END IF
        IF (.NOT. outputFrequency%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output frequency validation failed"
        END IF
    END SUBROUTINE Parse_OUTPUT_FREQUENCY_Keyword

    SUBROUTINE Validate_OUTPUT_FREQUENCY_Keyword(outputFrequency, status)
        TYPE(OutFrequencyProperties), INTENT(IN) :: outputFrequency
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. outputFrequency%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output frequency validation failed"
        END IF
    END SUBROUTINE Validate_OUTPUT_FREQUENCY_Keyword

    !=========================================================================
    ! OutFormat
    !=========================================================================
    SUBROUTINE OutFormatProperties_Init(this, name, status)
        CLASS(OutFormatProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%formatType = FORMAT_ODB
        this%formatName = ""
        this%outputFile = ""
        this%binary = .TRUE.
        this%compressed = .FALSE.
        this%precision = 6
        this%delimiter = ","
        this%includeHistory = .TRUE.
        this%includeField = .TRUE.
        this%vtkFormat = 1
        this%chunkSize = 1024
        this%useCompression = .FALSE.
    END SUBROUTINE OutFormatProperties_Init

    FUNCTION OutFormatProperties_Valid_Fn(this) RESULT(ok)
        CLASS(OutFormatProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%formatType < FORMAT_ODB .OR. this%formatType > FORMAT_TXT) ok = .FALSE.
        IF (this%precision < 0 .OR. this%precision > 15) ok = .FALSE.
    END FUNCTION OutFormatProperties_Valid_Fn

    SUBROUTINE OutFormatProperties_Clear(this)
        CLASS(OutFormatProperties), INTENT(INOUT) :: this
        this%name = ""
        this%formatType = FORMAT_ODB
        this%formatName = ""
        this%outputFile = ""
        this%binary = .TRUE.
        this%compressed = .FALSE.
        this%precision = 6
        this%delimiter = ","
        this%includeHistory = .TRUE.
        this%includeField = .TRUE.
        this%vtkFormat = 1
        this%chunkSize = 1024
        this%useCompression = .FALSE.
    END SUBROUTINE OutFormatProperties_Clear

    FUNCTION OutFormatProperties_GetFileExtension(this) RESULT(ext)
        CLASS(OutFormatProperties), INTENT(IN) :: this
        CHARACTER(LEN=8) :: ext
        SELECT CASE (this%formatType)
        CASE (FORMAT_ODB);  ext = ".odb"
        CASE (FORMAT_CSV);  ext = ".csv"
        CASE (FORMAT_VTK);  ext = ".vtk"
        CASE (FORMAT_HDF5); ext = ".h5"
        CASE (FORMAT_JSON); ext = ".json"
        CASE (FORMAT_TXT);  ext = ".txt"
        CASE DEFAULT;       ext = ".dat"
        END SELECT
    END FUNCTION OutFormatProperties_GetFileExtension

    SUBROUTINE MD_Output_OutputFormat_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputFormat_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_OutputFormat_Unified_Configure

    SUBROUTINE MD_Output_OutputFormat_Unified_Parse(out_type, ast_node, outputFormat, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFormatProperties), INTENT(OUT) :: outputFormat
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: format_str, binary_str, compressed_str
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'OUTPUT_FORMAT' .OR. TRIM(out_type) == 'OUTPUT FORMAT') THEN
            CALL Parse_OUTPUT_FORMAT_Keyword(ast_node, outputFormat, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputFormat_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_OutputFormat_Unified_Parse

    SUBROUTINE Parse_OUTPUT_FORMAT_Keyword(ast_node, outputFormat, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFormatProperties), INTENT(OUT) :: outputFormat
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: format_str, binary_str, compressed_str
        CALL init_error_status(status)
        CALL outputFormat%Init(TRIM(name), status)
        CALL md_out_get_param_value(ast_node, "TYPE", format_str)
        IF (LEN_TRIM(format_str) > 0) THEN
            SELECT CASE (TRIM(format_str))
            CASE ("ODB", "OUTPUT_DATABASE");   outputFormat%formatType = FORMAT_ODB
            CASE ("CSV", "COMMA_SEPARATED");   outputFormat%formatType = FORMAT_CSV
            CASE ("VTK", "VISUALIZATION_TOOLKIT"); outputFormat%formatType = FORMAT_VTK
            CASE ("HDF5", "HDF");              outputFormat%formatType = FORMAT_HDF5
            CASE ("JSON");                     outputFormat%formatType = FORMAT_JSON
            CASE ("TXT", "TEXT");              outputFormat%formatType = FORMAT_TXT
            END SELECT
        END IF
        CALL md_out_get_param_value(ast_node, "NAME", format_str)
        IF (LEN_TRIM(format_str) > 0) outputFormat%formatName = TRIM(format_str)
        CALL md_out_get_param_value(ast_node, "FILE", format_str)
        IF (LEN_TRIM(format_str) > 0) outputFormat%outputFile = TRIM(format_str)
        CALL md_out_get_param_value(ast_node, "BINARY", binary_str)
        IF (LEN_TRIM(binary_str) > 0) THEN
            IF (TRIM(binary_str) == "NO" .OR. TRIM(binary_str) == "FALSE") outputFormat%binary = .FALSE.
        END IF
        CALL md_out_get_param_value(ast_node, "COMPRESSED", compressed_str)
        IF (LEN_TRIM(compressed_str) > 0) THEN
            IF (TRIM(compressed_str) == "YES" .OR. TRIM(compressed_str) == "TRUE") outputFormat%compressed = .TRUE.
        END IF
        IF (ast_node%data_line_count > 0 .AND. ALLOCATED(ast_node%data_lines) .AND. &
            ast_node%data_lines(1)%col_count >= 1) &
            outputFormat%precision = INT(ast_node%data_lines(1)%real_values(1))
        IF (.NOT. outputFormat%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output format validation failed"
        END IF
    END SUBROUTINE Parse_OUTPUT_FORMAT_Keyword

    SUBROUTINE Valid_OUTPUT_FORMAT_Keyword(outputFormat, status)
        TYPE(OutFormatProperties), INTENT(IN) :: outputFormat
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. outputFormat%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output format validation failed"
        END IF
    END SUBROUTINE Valid_OUTPUT_FORMAT_Keyword

    !=========================================================================
    ! OutFilter
    !=========================================================================
    SUBROUTINE OutFilterProperties_Init(this, name, status)
        CLASS(OutFilterProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%name = TRIM(name)
        this%filterType = FILTER_TYPE_VALUE
        this%minValue = 0.0_wp
        this%maxValue = 0.0_wp
        this%numVariables = 0
        this%includeVariables = .TRUE.
        this%numRegions = 0
        this%thresholdValue = 0.0_wp
        this%thresholdOperator = 1
        IF (ALLOCATED(this%variables))   DEALLOCATE(this%variables)
        IF (ALLOCATED(this%nodeSets))    DEALLOCATE(this%nodeSets)
        IF (ALLOCATED(this%elementSets)) DEALLOCATE(this%elementSets)
        IF (ALLOCATED(this%surfaces))    DEALLOCATE(this%surfaces)
    END SUBROUTINE OutFilterProperties_Init

    FUNCTION OutFilterProperties_Valid_Fn(this) RESULT(ok)
        CLASS(OutFilterProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%filterType == FILTER_TYPE_VALUE) THEN
            IF (this%maxValue < this%minValue) ok = .FALSE.
        END IF
        IF (this%filterType == FILTER_TYPE_VARIABLE .AND. this%numVariables == 0) ok = .FALSE.
        IF (this%filterType == FILTER_TYPE_REGION .AND. this%numRegions == 0) ok = .FALSE.
    END FUNCTION OutFilterProperties_Valid_Fn

    SUBROUTINE OutFilterProperties_Clear(this)
        CLASS(OutFilterProperties), INTENT(INOUT) :: this
        this%name = ""
        this%filterType = FILTER_TYPE_VALUE
        this%minValue = 0.0_wp
        this%maxValue = 0.0_wp
        this%numVariables = 0
        this%includeVariables = .TRUE.
        this%numRegions = 0
        this%thresholdValue = 0.0_wp
        this%thresholdOperator = 1
        IF (ALLOCATED(this%variables))   DEALLOCATE(this%variables)
        IF (ALLOCATED(this%nodeSets))    DEALLOCATE(this%nodeSets)
        IF (ALLOCATED(this%elementSets)) DEALLOCATE(this%elementSets)
        IF (ALLOCATED(this%surfaces))    DEALLOCATE(this%surfaces)
    END SUBROUTINE OutFilterProperties_Clear

    SUBROUTINE OutFilterProperties_AddVariable(this, variableName, status)
        CLASS(OutFilterProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: variableName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=64), ALLOCATABLE :: temp_vars(:)
        INTEGER(i4) :: i
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%variables)) THEN
            this%numVariables = 1
            ALLOCATE(this%variables(1))
            this%variables(1) = TRIM(variableName)
        ELSE
            this%numVariables = this%numVariables + 1
            ALLOCATE(temp_vars(this%numVariables))
            DO i = 1, this%numVariables - 1
                temp_vars(i) = this%variables(i)
            END DO
            temp_vars(this%numVariables) = TRIM(variableName)
            CALL MOVE_ALLOC(temp_vars, this%variables)
        END IF
        IF (this%filterType == FILTER_TYPE_VALUE) this%filterType = FILTER_TYPE_VARIABLE
    END SUBROUTINE OutFilterProperties_AddVariable

    SUBROUTINE OutFilterProperties_AddNodeSet(this, nodeSetName, status)
        CLASS(OutFilterProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: nodeSetName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=64), ALLOCATABLE :: temp_sets(:)
        INTEGER(i4) :: i
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%nodeSets)) THEN
            ALLOCATE(this%nodeSets(1))
            this%nodeSets(1) = TRIM(nodeSetName)
            this%numRegions = this%numRegions + 1
        ELSE
            ALLOCATE(temp_sets(SIZE(this%nodeSets) + 1))
            DO i = 1, SIZE(this%nodeSets)
                temp_sets(i) = this%nodeSets(i)
            END DO
            temp_sets(SIZE(this%nodeSets) + 1) = TRIM(nodeSetName)
            CALL MOVE_ALLOC(temp_sets, this%nodeSets)
            this%numRegions = this%numRegions + 1
        END IF
        IF (this%filterType == FILTER_TYPE_VALUE) this%filterType = FILTER_TYPE_REGION
    END SUBROUTINE OutFilterProperties_AddNodeSet

    SUBROUTINE OutFilterProperties_AddElementSet(this, elementSetName, status)
        CLASS(OutFilterProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: elementSetName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=64), ALLOCATABLE :: temp_sets(:)
        INTEGER(i4) :: i
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%elementSets)) THEN
            ALLOCATE(this%elementSets(1))
            this%elementSets(1) = TRIM(elementSetName)
            this%numRegions = this%numRegions + 1
        ELSE
            ALLOCATE(temp_sets(SIZE(this%elementSets) + 1))
            DO i = 1, SIZE(this%elementSets)
                temp_sets(i) = this%elementSets(i)
            END DO
            temp_sets(SIZE(this%elementSets) + 1) = TRIM(elementSetName)
            CALL MOVE_ALLOC(temp_sets, this%elementSets)
            this%numRegions = this%numRegions + 1
        END IF
        IF (this%filterType == FILTER_TYPE_VALUE) this%filterType = FILTER_TYPE_REGION
    END SUBROUTINE OutFilterProperties_AddElementSet

    SUBROUTINE OutFilterProperties_AddSurface(this, surfaceName, status)
        CLASS(OutFilterProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: surfaceName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=64), ALLOCATABLE :: temp_surfs(:)
        INTEGER(i4) :: i
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%surfaces)) THEN
            ALLOCATE(this%surfaces(1))
            this%surfaces(1) = TRIM(surfaceName)
            this%numRegions = this%numRegions + 1
        ELSE
            ALLOCATE(temp_surfs(SIZE(this%surfaces) + 1))
            DO i = 1, SIZE(this%surfaces)
                temp_surfs(i) = this%surfaces(i)
            END DO
            temp_surfs(SIZE(this%surfaces) + 1) = TRIM(surfaceName)
            CALL MOVE_ALLOC(temp_surfs, this%surfaces)
            this%numRegions = this%numRegions + 1
        END IF
        IF (this%filterType == FILTER_TYPE_VALUE) this%filterType = FILTER_TYPE_REGION
    END SUBROUTINE OutFilterProperties_AddSurface

    FUNCTION OutFilterProperties_MatchesVariable(this, variableName) RESULT(matches)
        CLASS(OutFilterProperties), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: variableName
        LOGICAL :: matches
        INTEGER(i4) :: i
        matches = .FALSE.
        IF (this%filterType == FILTER_TYPE_VARIABLE .AND. ALLOCATED(this%variables)) THEN
            DO i = 1, this%numVariables
                IF (TRIM(this%variables(i)) == TRIM(variableName)) THEN
                    matches = .TRUE.
                    IF (.NOT. this%includeVariables) matches = .FALSE.
                    RETURN
                END IF
            END DO
            IF (this%includeVariables) matches = .FALSE.
        ELSE
            matches = .TRUE.
        END IF
    END FUNCTION OutFilterProperties_MatchesVariable

    FUNCTION OutFilterProperties_MatchesRegion(this, nodeSetName, elementSetName, surfaceName) RESULT(matches)
        CLASS(OutFilterProperties), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: nodeSetName, elementSetName, surfaceName
        LOGICAL :: matches
        INTEGER(i4) :: i
        matches = .FALSE.
        IF (this%filterType == FILTER_TYPE_REGION) THEN
            IF (PRESENT(nodeSetName) .AND. ALLOCATED(this%nodeSets)) THEN
                DO i = 1, SIZE(this%nodeSets)
                    IF (TRIM(this%nodeSets(i)) == TRIM(nodeSetName)) THEN
                        matches = .TRUE.; RETURN
                    END IF
                END DO
            END IF
            IF (PRESENT(elementSetName) .AND. ALLOCATED(this%elementSets)) THEN
                DO i = 1, SIZE(this%elementSets)
                    IF (TRIM(this%elementSets(i)) == TRIM(elementSetName)) THEN
                        matches = .TRUE.; RETURN
                    END IF
                END DO
            END IF
            IF (PRESENT(surfaceName) .AND. ALLOCATED(this%surfaces)) THEN
                DO i = 1, SIZE(this%surfaces)
                    IF (TRIM(this%surfaces(i)) == TRIM(surfaceName)) THEN
                        matches = .TRUE.; RETURN
                    END IF
                END DO
            END IF
        ELSE
            matches = .TRUE.
        END IF
    END FUNCTION OutFilterProperties_MatchesRegion

    FUNCTION OutFilterProperties_MatchesValue(this, value) RESULT(matches)
        CLASS(OutFilterProperties), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: value
        LOGICAL :: matches
        matches = .TRUE.
        IF (this%filterType == FILTER_TYPE_VALUE) THEN
            matches = (value >= this%minValue .AND. value <= this%maxValue)
        ELSE IF (this%filterType == FILTER_TYPE_THRESHOLD) THEN
            SELECT CASE (this%thresholdOperator)
            CASE (1); matches = (value >= this%thresholdValue)
            CASE (2); matches = (value >  this%thresholdValue)
            CASE (3); matches = (value <= this%thresholdValue)
            CASE (4); matches = (value <  this%thresholdValue)
            CASE DEFAULT; matches = .TRUE.
            END SELECT
        END IF
    END FUNCTION OutFilterProperties_MatchesValue

    SUBROUTINE MD_Output_OutputFilter_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputFilter_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Output_OutputFilter_Unified_Configure

    SUBROUTINE MD_Output_OutputFilter_Unified_Parse(out_type, ast_node, outputFilter, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: out_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFilterProperties), INTENT(OUT) :: outputFilter
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(out_type) == 'OUTPUT_FILTER' .OR. TRIM(out_type) == 'OUTPUT FILTER') THEN
            CALL Parse_OUTPUT_FILTER_Keyword(ast_node, outputFilter, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Output_OutputFilter_Unified_Parse: unsupported out_type ' // TRIM(out_type)
        END IF
    END SUBROUTINE MD_Output_OutputFilter_Unified_Parse

    SUBROUTINE Parse_OUTPUT_FILTER_Keyword(ast_node, outputFilter, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFilterProperties), INTENT(OUT) :: outputFilter
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: filter_type_str, include_str
        CALL init_error_status(status)
        CALL outputFilter%Init(TRIM(name), status)
        CALL md_out_get_param_value(ast_node, "TYPE", filter_type_str)
        IF (LEN_TRIM(filter_type_str) > 0) THEN
            SELECT CASE (TRIM(filter_type_str))
            CASE ("VALUE", "VALUE_RANGE");      outputFilter%filterType = FILTER_TYPE_VALUE
            CASE ("VARIABLE", "VARIABLE_NAME"); outputFilter%filterType = FILTER_TYPE_VARIABLE
            CASE ("REGION", "REGION_BASED");    outputFilter%filterType = FILTER_TYPE_REGION
            CASE ("THRESHOLD");                 outputFilter%filterType = FILTER_TYPE_THRESHOLD
            END SELECT
        END IF
        CALL md_out_get_param_value(ast_node, "INCLUDE", include_str)
        IF (LEN_TRIM(include_str) > 0) THEN
            IF (TRIM(include_str) == "NO" .OR. TRIM(include_str) == "FALSE") &
                outputFilter%includeVariables = .FALSE.
        END IF
        IF (ast_node%data_line_count > 0 .AND. ALLOCATED(ast_node%data_lines)) THEN
            SELECT CASE (outputFilter%filterType)
            CASE (FILTER_TYPE_VALUE)
                IF (ast_node%data_lines(1)%col_count >= 2) THEN
                    outputFilter%minValue = ast_node%data_lines(1)%real_values(1)
                    outputFilter%maxValue = ast_node%data_lines(1)%real_values(2)
                END IF
            CASE (FILTER_TYPE_VARIABLE)
                CALL parse_variable_list(ast_node, outputFilter, status)
            CASE (FILTER_TYPE_REGION)
                CALL parse_region_list(ast_node, outputFilter, status)
            CASE (FILTER_TYPE_THRESHOLD)
                CALL parse_threshold(ast_node, outputFilter, status)
            END SELECT
        END IF
        IF (.NOT. outputFilter%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output filter validation failed"
        END IF
    END SUBROUTINE Parse_OUTPUT_FILTER_Keyword

    SUBROUTINE parse_region_list(ast_node, outputFilter, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFilterProperties), INTENT(INOUT) :: outputFilter
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        CHARACTER(LEN=64) :: region_name, region_type
        CALL init_error_status(status)
        DO i = 1, ast_node%data_line_count
            IF (ast_node%data_lines(i)%col_count >= 2) THEN
                region_type = ""
                region_name = ""
                IF (ast_node%data_lines(i)%col_count >= 1) &
                    region_type = TRIM(ast_node%data_lines(i)%values(1))
                IF (ast_node%data_lines(i)%col_count >= 2) &
                    region_name = TRIM(ast_node%data_lines(i)%values(2))
                SELECT CASE (TRIM(region_type))
                CASE ("NSET", "NODE_SET");    CALL outputFilter%AddNodeSet(region_name, status)
                CASE ("ELSET", "ELEMENT_SET"); CALL outputFilter%AddElementSet(region_name, status)
                CASE ("SURFACE", "SURF");     CALL outputFilter%AddSurface(region_name, status)
                END SELECT
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END IF
        END DO
    END SUBROUTINE parse_region_list

    SUBROUTINE parse_threshold(ast_node, outputFilter, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFilterProperties), INTENT(INOUT) :: outputFilter
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: operator_str
        CALL init_error_status(status)
        IF (ast_node%data_line_count > 0 .AND. ALLOCATED(ast_node%data_lines) .AND. &
            ast_node%data_lines(1)%col_count >= 1) THEN
            outputFilter%thresholdValue = ast_node%data_lines(1)%real_values(1)
            IF (ast_node%data_lines(1)%col_count >= 1) THEN
                operator_str = TRIM(ast_node%data_lines(1)%values(1))
                SELECT CASE (TRIM(operator_str))
                CASE (">=", "GE"); outputFilter%thresholdOperator = 1
                CASE (">",  "GT"); outputFilter%thresholdOperator = 2
                CASE ("<=", "LE"); outputFilter%thresholdOperator = 3
                CASE ("<",  "LT"); outputFilter%thresholdOperator = 4
                END SELECT
            END IF
        END IF
    END SUBROUTINE parse_threshold

    SUBROUTINE parse_variable_list(ast_node, outputFilter, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(OutFilterProperties), INTENT(INOUT) :: outputFilter
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j
        CHARACTER(LEN=64) :: var_name
        CALL init_error_status(status)
        DO i = 1, ast_node%data_line_count
            IF (ast_node%data_lines(i)%col_count > 0) THEN
                DO j = 1, ast_node%data_lines(i)%col_count
                    IF (j <= 32) THEN
                        var_name = TRIM(ast_node%data_lines(i)%values(j))
                        IF (LEN_TRIM(var_name) > 0) THEN
                            CALL outputFilter%AddVariable(var_name, status)
                            IF (status%status_code /= IF_STATUS_OK) RETURN
                        END IF
                    END IF
                END DO
            END IF
        END DO
    END SUBROUTINE parse_variable_list

    SUBROUTINE Valid_OUTPUT_FILTER_Keyword(outputFilter, status)
        TYPE(OutFilterProperties), INTENT(IN) :: outputFilter
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. outputFilter%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Output filter validation failed"
        END IF
    END SUBROUTINE Valid_OUTPUT_FILTER_Keyword

END MODULE MD_Out_Parse