!===============================================================================
! MODULE: AP_Reg_Def
! LAYER:  L6_AP
! DOMAIN: Registry
! ROLE:   Def — type definitions
! BRIEF:  Type definitions for application-level element/material registry.
!===============================================================================
! Types: AP_RegEntry, AP_Registry_Desc, AP_Registry_State
! Constants: AP_REG_MAX_ENTRIES, AP_REG_NAME_LEN
!===============================================================================
MODULE AP_Reg_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: AP_REG_MAX_ENTRIES = 128
  INTEGER(i4), PARAMETER, PUBLIC :: AP_REG_NAME_LEN    = 64

  PUBLIC :: AP_RegEntry
  PUBLIC :: AP_Registry_Desc
  PUBLIC :: AP_Registry_State

  TYPE :: AP_RegEntry
    CHARACTER(LEN=AP_REG_NAME_LEN) :: name = ""
    INTEGER(i4) :: type_id  = 0
    INTEGER(i4) :: category = 0
    LOGICAL     :: valid    = .FALSE.
  END TYPE AP_RegEntry

  TYPE :: AP_Registry_Desc
    INTEGER(i4) :: max_entries = AP_REG_MAX_ENTRIES
  END TYPE AP_Registry_Desc

  TYPE :: AP_Registry_State
    TYPE(AP_RegEntry) :: entries(AP_REG_MAX_ENTRIES)
    INTEGER(i4)       :: n_entries = 0
  END TYPE AP_Registry_State

END MODULE AP_Reg_Def
