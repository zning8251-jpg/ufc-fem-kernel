!===============================================================================
! MODULE: AP_Config_Def
! LAYER:  L6_AP
! DOMAIN: Config
! ROLE:   Def — type definitions
! BRIEF:  Type definitions for application configuration management.
!===============================================================================
! Types: AP_ConfigEntry, AP_Config_Desc, AP_Config_State
! Constants: AP_CFG_MAX, AP_CFG_KEY_LEN
!===============================================================================
MODULE AP_Config_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: AP_CFG_MAX     = 128
  INTEGER(i4), PARAMETER, PUBLIC :: AP_CFG_KEY_LEN = 64

  PUBLIC :: AP_ConfigEntry
  PUBLIC :: AP_Config_Desc
  PUBLIC :: AP_Config_State

  TYPE :: AP_ConfigEntry
    CHARACTER(LEN=AP_CFG_KEY_LEN) :: key = ""
    INTEGER(i4)    :: int_val  = 0
    REAL(wp)       :: real_val = 0.0_wp
    CHARACTER(LEN=128) :: str_val = ""
    LOGICAL        :: valid = .FALSE.
  END TYPE AP_ConfigEntry

  TYPE :: AP_Config_Desc
    INTEGER(i4) :: max_entries = AP_CFG_MAX
  END TYPE AP_Config_Desc

  TYPE :: AP_Config_State
    TYPE(AP_ConfigEntry) :: entries(AP_CFG_MAX)
    INTEGER(i4)          :: n_entries = 0
  END TYPE AP_Config_State

END MODULE AP_Config_Def
