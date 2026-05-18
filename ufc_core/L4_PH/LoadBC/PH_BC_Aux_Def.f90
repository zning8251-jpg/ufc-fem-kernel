!===============================================================================
! MODULE:  PH_BC_Aux_Def
! LAYER:   L4_PH
! DOMAIN:  BC
! ROLE:    Aux Def
! BRIEF:   BC enforcement constants and step-level BC algorithm control.
!===============================================================================
MODULE PH_BC_Aux_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: &
    PH_BC_BC_PENALTY     = 1_i4, &
    PH_BC_BC_LAGRANGE    = 2_i4, &
    PH_BC_BC_ELIMINATION = 3_i4

  TYPE, PUBLIC :: PH_BC_Stp_Ctl_Algo
    INTEGER(i4) :: bc_method = PH_BC_BC_PENALTY
    REAL(wp) :: penalty_param = 1.0E12_wp
    REAL(wp) :: lagrange_tol = 1.0E-8_wp
    REAL(wp) :: conv_tol = 1.0E-6_wp
    LOGICAL :: auto_cutback = .TRUE.
    INTEGER(i4) :: max_cutbacks = 5_i4
    REAL(wp) :: cutback_factor = 0.25_wp
  END TYPE

END MODULE PH_BC_Aux_Def
