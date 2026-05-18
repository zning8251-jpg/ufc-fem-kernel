!===============================================================================
! MODULE: AP_Solv_Def
! LAYER:  L6_AP
! DOMAIN: Solver
! ROLE:   Def — type definitions
! BRIEF:  Type definitions for application-level solver configuration.
!===============================================================================
! Types: AP_Solver_Desc, AP_Solver_Algo
! Constants: AP_SOLVER_IMPLICIT, AP_SOLVER_EXPLICIT
!===============================================================================
MODULE AP_Solv_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Solver_Desc
  PUBLIC :: AP_Solver_Algo

  INTEGER(i4), PARAMETER, PUBLIC :: AP_SOLVER_IMPLICIT = 1
  INTEGER(i4), PARAMETER, PUBLIC :: AP_SOLVER_EXPLICIT = 2

  TYPE :: AP_Solver_Desc
    CHARACTER(LEN=64) :: solver_name = ""
  END TYPE AP_Solver_Desc

  TYPE :: AP_Solver_Algo
    INTEGER(i4) :: solver_type = AP_SOLVER_IMPLICIT
    REAL(wp)    :: tolerance   = 1.0E-6_wp
    INTEGER(i4) :: max_iter    = 100
  END TYPE AP_Solver_Algo

END MODULE AP_Solv_Def
