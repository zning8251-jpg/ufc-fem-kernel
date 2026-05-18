!===================================================================
! MODULE : MD_KWAP_Brg
! LAYER  : L3_MD
! DOMAIN : KeyWord (KW)
! ROLE   : Brg / Bridge  (L3 -> L6)
! BRIEF  : Bridge re-exporting output-format and parser keyword
!          types from L6_AP into L3_MD.  MD_KW_Mapper consumes
!          Parse_*_Keyword / *Properties from L6_AP for EL_FILE,
!          NODE_FILE, FILE_FORMAT, PREPRINT, USER_OUTPUT, INCLUDE.
!===================================================================

MODULE MD_KWAP_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE AP_Out_Fmt, ONLY: Parse_EL_FILE_Keyword, ElFileProperties, &
                          Parse_FILE_FORMAT_Keyword, FormatProperties, &
                          Parse_NODE_FILE_Keyword, NodeFileProperties, &
                          Parse_PREPRINT_Keyword, PreprintProperties
  USE AP_Output_UserOutput_Parse, ONLY: Parse_USER_OUTPUT_Keyword
  USE AP_Output_UserOutput_Type, ONLY: UserOutputProperties
  USE AP_Parser_Include_Parse, ONLY: Parse_INCLUDE_Keyword
  USE AP_Parser_Include_Type, ONLY: IncludeProperties
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Re-export L6_AP types and procedures for L3_MD use
  !=============================================================================
  PUBLIC :: Parse_EL_FILE_Keyword, ElFileProperties
  PUBLIC :: Parse_FILE_FORMAT_Keyword, FormatProperties
  PUBLIC :: Parse_NODE_FILE_Keyword, NodeFileProperties
  PUBLIC :: Parse_PREPRINT_Keyword, PreprintProperties
  PUBLIC :: Parse_USER_OUTPUT_Keyword, UserOutputProperties
  PUBLIC :: Parse_INCLUDE_Keyword, IncludeProperties

END MODULE MD_KWAP_Brg
