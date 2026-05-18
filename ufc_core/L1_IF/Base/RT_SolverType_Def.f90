!===============================================================================
! MODULE: RT_SolverType_Def
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Def — canonical solver routing type constants (LEGACY cross-layer name)
! BRIEF:  Single source of truth for 8 solver routing IDs.
!         Maps computational pathways for analysis dispatch.
!===============================================================================
! NAMING NOTE: MODULE RT_SolverType_Def is a LEGACY cross-layer name kept
!   intentionally in L1_IF because it is a shared enum used by all layers.
MODULE RT_SolverType_Def
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_UNKNOWN  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_IMPLICIT = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_EXPLICIT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_CFD      = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_EMF      = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_THM      = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_PMF      = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_DIF      = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_CPL      = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLVER_COUNT    = 8_i4

END MODULE RT_SolverType_Def
