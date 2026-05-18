!===============================================================================
! MODULE: AP_UI_Def
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Def — descriptor for console UI formatting
! BRIEF:  Immutable descriptor type for console output unit and formatting.
!===============================================================================
MODULE AP_UI_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_UI_Desc

  TYPE :: AP_UI_Desc
    INTEGER(i4)       :: output_unit = 6
    INTEGER(i4)       :: line_width  = 80
    CHARACTER(LEN=32) :: banner_char = "="
  END TYPE AP_UI_Desc

END MODULE AP_UI_Def
