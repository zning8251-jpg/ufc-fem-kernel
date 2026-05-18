!===============================================================================
! MODULE: IF_IO_Parser
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Impl — input parser for structured files (INP/JSON/XML)
! BRIEF:  Keyword reading, node/element line parsing, comment skipping.
!===============================================================================
MODULE IF_IO_Parser
    USE IF_IO_File, ONLY: IF_FileHandle, IF_IO_MODE_READ, IF_IO_FORMAT_TEXT
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACE (IF_ParserHandle is public via TYPE, PUBLIC)
    ! ==========================================================================
    PUBLIC :: IF_Parser_ReadKeyword
    PUBLIC :: IF_Parser_ParseNodeLine
    PUBLIC :: IF_Parser_ParseElemLine
    PUBLIC :: IF_Parser_SkipComments

    ! ==========================================================================
    ! PARSER HANDLE TYPE
    ! Category: State (State - parser runtime data)
    ! Purpose: Parser handle state containing file handle, format, and parsing state.
    ! Members:
    !   file_handle: File handle for input file
    !   format: Input format (INP, JSON, XML)
    !   line_number: Current line number
    ! ==========================================================================
    TYPE, PUBLIC :: IF_ParserHandle
        TYPE(IF_FileHandle) :: file_handle
        CHARACTER(LEN=32) :: format = ""
        INTEGER(i4) :: line_number = 0
    END TYPE IF_ParserHandle

CONTAINS

    !> @brief Read keyword from file
    !! @param[inout] handle Parser handle
    !! @param[out] keyword Keyword string
    !! @param[out] options Keyword options (allocatable)
    !! @param[out] nOptions Number of options
    !! @param[out] eof End of file flag
    !! @param[out] status Error status
    SUBROUTINE IF_Parser_ReadKeyword(handle, keyword, options, nOptions, eof, status)
        TYPE(IF_ParserHandle), INTENT(INOUT) :: handle
        CHARACTER(LEN=*), INTENT(OUT) :: keyword
        CHARACTER(LEN=*), ALLOCATABLE, INTENT(OUT) :: options(:)
        INTEGER(i4), INTENT(OUT) :: nOptions
        LOGICAL, INTENT(OUT) :: eof
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=512) :: line
        INTEGER(i4) :: ios, comma_pos

        CALL init_error_status(status)

        eof = .FALSE.
        keyword = ""
        nOptions = 0

        ! Read line
        CALL handle%file_handle%ReadTextLine(line, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (status%message == "End of file reached") THEN
                eof = .TRUE.
            END IF
            RETURN
        END IF

        handle%line_number = handle%line_number + 1

        ! Trim and check for keyword (starts with *)
        line = ADJUSTL(line)

        IF (line(1:1) /= '*') THEN
            keyword = ""
            RETURN
        END IF

        ! Extract keyword
        comma_pos = INDEX(line, ',')
        IF (comma_pos > 0) THEN
            keyword = line(2:comma_pos-1)
            ! Parse options after comma (Phase 2 implementation)
            ! Currently returns nOptions=0 as placeholder
            nOptions = 0
        ELSE
            keyword = line(2:LEN_TRIM(line))
            nOptions = 0
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Parser_ReadKeyword

    !> @brief Parse node line
    !! @param[in] line Input line
    !! @param[out] node_id Node ID
    !! @param[out] coords Node coordinates
    !! @param[out] status Error status
    SUBROUTINE IF_Parser_ParseNodeLine(line, node_id, coords, status)
        CHARACTER(LEN=*), INTENT(IN) :: line
        INTEGER(i4), INTENT(OUT) :: node_id
        REAL(wp), INTENT(OUT) :: coords(3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: ios

        CALL init_error_status(status)

        ! Parse: node_id, x, y, z
        READ(line, *, IOSTAT=ios) node_id, coords(1), coords(2), coords(3)

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Failed to parse node line"
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Parser_ParseNodeLine

    !> @brief Parse element line
    !! @param[in] line Input line
    !! @param[out] elem_id Element ID
    !! @param[out] node_ids Node IDs (allocatable)
    !! @param[out] nNodes Number of nodes
    !! @param[out] status Error status
    SUBROUTINE IF_Parser_ParseElemLine(line, elem_id, node_ids, nNodes, status)
        CHARACTER(LEN=*), INTENT(IN) :: line
        INTEGER(i4), INTENT(OUT) :: elem_id
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: node_ids(:)
        INTEGER(i4), INTENT(OUT) :: nNodes
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: ios, comma_count, i
        INTEGER(i4) :: temp_ids(100)

        CALL init_error_status(status)

        ! Parse: elem_id, node1, node2, ... (max 100 nodes)
        READ(line, *, IOSTAT=ios) elem_id, temp_ids

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Failed to parse element line"
            RETURN
        END IF

        ! Count actual nodes
        nNodes = 0
        DO i = 1, 100
            IF (temp_ids(i) /= 0) nNodes = nNodes + 1
        END DO

        ! Allocate and copy
        ALLOCATE(node_ids(nNodes))
        node_ids = temp_ids(1:nNodes)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Parser_ParseElemLine

    !> @brief Skip comment lines
    !! @param[in] line Input line
    !! @param[out] is_comment .TRUE. if line is a comment, .FALSE. otherwise
    SUBROUTINE IF_Parser_SkipComments(line, is_comment)
        CHARACTER(LEN=*), INTENT(IN) :: line
        LOGICAL, INTENT(OUT) :: is_comment

        CHARACTER(LEN=512) :: trimmed_line

        is_comment = .FALSE.

        trimmed_line = ADJUSTL(line)

        ! Check for empty line
        IF (LEN_TRIM(trimmed_line) == 0) THEN
            is_comment = .TRUE.
            RETURN
        END IF

        ! Check for comment (**)
        IF (trimmed_line(1:2) == '**') THEN
            is_comment = .TRUE.
            RETURN
        END IF
    END SUBROUTINE IF_Parser_SkipComments

END MODULE IF_IO_Parser