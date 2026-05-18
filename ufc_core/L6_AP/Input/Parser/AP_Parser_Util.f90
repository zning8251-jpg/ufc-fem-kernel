!===============================================================================
! MODULE: AP_Parser_Util
! LAYER:  L6_AP
! DOMAIN: Input/Parser
! ROLE:   Util — parser utilities (line parsing, token extraction)
! BRIEF:  Parser utilities (line parsing, token extraction, comments).
!
! Process phases:
!   P1: ParseLine / ExtractTokens / StripComments / NormalizeKeyword
!===============================================================================
MODULE AP_Parser_Util
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE
    
    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: AP_Parse_RemoveComments
    PUBLIC :: AP_Parse_TrimWhitespace
    PUBLIC :: AP_Parse_SplitTokens
    PUBLIC :: AP_Parse_ExtractQuotedString
    PUBLIC :: AP_Parse_IsEmptyLine
    PUBLIC :: AP_Parse_NormalizeLine
    ! Extended API (task13700-13799)
    PUBLIC :: AP_ParserUtils_Unified_Execute
    PUBLIC :: AP_ParserUtils_Unified_Cfg
    
CONTAINS

    SUBROUTINE AP_Pa_Un_Execute(operation, line, result_line, status)
        !! Unified parser utils: NORMALIZE, REMOVE_COMMENTS, TRIM -> line in, result_line out.
        !! Task: 13700-13749
        CHARACTER(LEN=*), INTENT(IN) :: operation
        CHARACTER(LEN=*), INTENT(IN) :: line
        CHARACTER(LEN=*), INTENT(OUT) :: result_line
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        IF (TRIM(operation) == 'NORMALIZE' .OR. TRIM(operation) == 'normalize') THEN
            result_line = AP_Parse_NormalizeLine(line)
        ELSE IF (TRIM(operation) == 'REMOVE_COMMENTS' .OR. TRIM(operation) == 'remove_comments') THEN
            result_line = AP_Parse_RemoveComments(line)
        ELSE IF (TRIM(operation) == 'TRIM' .OR. TRIM(operation) == 'trim') THEN
            result_line = AP_Parse_TrimWhitespace(line)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_ParserUtils_Unified_Execute: unsupported operation ' // TRIM(operation)
            result_line = ''
        END IF
    END SUBROUTINE AP_ParserUtils_Unified_Execute

    SUBROUTINE AP_Parse_ExtractQuotedString(line, quote_char, quoted_str, found)
        CHARACTER(len=*), INTENT(IN) :: line
        CHARACTER(len=1), INTENT(IN), OPTIONAL :: quote_char
        CHARACTER(len=*), INTENT(OUT) :: quoted_str
        LOGICAL, INTENT(OUT) :: found
        
        INTEGER(i4) :: first_quote, second_quote
        CHARACTER(len=1) :: qc
        
        IF (PRESENT(quote_char)) THEN
            qc = quote_char
        ELSE
            qc = '"'
        END IF
        
        found = .FALSE.
        quoted_str = ""
        
        first_quote = INDEX(line, qc)
        IF (first_quote > 0) THEN
            second_quote = INDEX(line(first_quote+1:), qc)
            IF (second_quote > 0) THEN
                second_quote = second_quote + first_quote
                quoted_str = line(first_quote+1:second_quote-1)
                found = .TRUE.
            END IF
        END IF
    END SUBROUTINE AP_Parse_ExtractQuotedString

    FUNCTION AP_Parse_NormalizeLine(line) RESULT(normalized_line)
        CHARACTER(len=*), INTENT(IN) :: line
        CHARACTER(len=LEN(line)) :: normalized_line
        
        normalized_line = AP_Parse_RemoveComments(line)
        normalized_line = AP_Parse_TrimWhitespace(normalized_line)
    END FUNCTION AP_Parse_NormalizeLine

    FUNCTION AP_Parse_RemoveComments(line, comment_char) RESULT(clean_line)
        CHARACTER(len=*), INTENT(IN) :: line
        CHARACTER(len=1), INTENT(IN), OPTIONAL :: comment_char
        CHARACTER(len=LEN(line)) :: clean_line
        
        INTEGER(i4) :: comment_pos
        CHARACTER(len=1) :: cc
        
        IF (PRESENT(comment_char)) THEN
            cc = comment_char
        ELSE
            cc = '!'
        END IF
        
        comment_pos = INDEX(line, cc)
        IF (comment_pos > 0) THEN
            clean_line = line(1:comment_pos-1)
        ELSE
            clean_line = line
        END IF
    END FUNCTION AP_Parse_RemoveComments

    SUBROUTINE AP_Parse_SplitTokens(line, tokens, num_tokens, status)
        CHARACTER(len=*), INTENT(IN) :: line
        CHARACTER(len=*), INTENT(OUT) :: tokens(:)
        INTEGER(i4), INTENT(OUT) :: num_tokens
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: i, start_pos, space_pos, max_tokens
        CHARACTER(len=LEN(line)) :: remaining_line
        
        CALL init_error_status(status)
        
        max_tokens = SIZE(tokens)
        num_tokens = 0
        remaining_line = TRIM(ADJUSTL(line))
        
        start_pos = 1
        DO WHILE (start_pos <= LEN_TRIM(remaining_line) .AND. num_tokens < max_tokens)
            space_pos = INDEX(remaining_line(start_pos:), ' ')
            IF (space_pos == 0) THEN
                ! Last token
                num_tokens = num_tokens + 1
                tokens(num_tokens) = remaining_line(start_pos:)
                EXIT
            ELSE
                space_pos = space_pos + start_pos - 1
                num_tokens = num_tokens + 1
                tokens(num_tokens) = remaining_line(start_pos:space_pos-1)
                start_pos = space_pos + 1
                ! Skip multiple spaces
                DO WHILE (start_pos <= LEN_TRIM(remaining_line) .AND. &
                         remaining_line(start_pos:start_pos) == ' ')
                    start_pos = start_pos + 1
                END DO
            END IF
        END DO
        
        status%status_code = IF_STATUS_OK
    END SUBROUTINE AP_Parse_SplitTokens

    FUNCTION AP_Parse_TrimWhitespace(line) RESULT(trimmed_line)
        CHARACTER(len=*), INTENT(IN) :: line
        CHARACTER(len=LEN(line)) :: trimmed_line
        
        trimmed_line = TRIM(ADJUSTL(line))
    END FUNCTION AP_Parse_TrimWhitespace

    SUBROUTINE AP_ParserUtils_Unified_Cfg(operation, status)
        !! Unified parser utils configuration (placeholder).
        !! Task: 13750-13799
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_ParserUtils_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_ParserUtils_Unified_Cfg
END MODULE AP_Parser_Util