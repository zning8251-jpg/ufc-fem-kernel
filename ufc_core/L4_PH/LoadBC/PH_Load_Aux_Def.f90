!===============================================================================
! MODULE:  PH_Load_Aux_Def
! LAYER:   L4_PH
! DOMAIN:  Load
! ROLE:    Aux Def
! BRIEF:   Load-specific auxiliary TYPE definitions.
!===============================================================================
MODULE PH_Load_Aux_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: &
    PH_LOAD_QUAD_GAUSS_1 = 1_i4, &
    PH_LOAD_QUAD_GAUSS_2 = 2_i4, &
    PH_LOAD_QUAD_GAUSS_3 = 3_i4

  TYPE, PUBLIC :: PH_Load_Stp_Ctl_Algo
    INTEGER(i4) :: quad_order = PH_LOAD_QUAD_GAUSS_2
    LOGICAL :: use_follower = .FALSE.
    LOGICAL :: use_nodal_proj = .TRUE.
    LOGICAL :: use_amplitude = .TRUE.
    INTEGER(i4) :: amp_interp = 1_i4
    REAL(wp) :: load_tol = 1.0E-6_wp
    REAL(wp) :: disp_tol = 1.0E-6_wp
    LOGICAL :: auto_cutback = .TRUE.
    INTEGER(i4) :: max_cutbacks = 5_i4
    REAL(wp) :: cutback_factor = 0.25_wp
    REAL(wp) :: growth_factor = 1.5_wp
  END TYPE

END MODULE PH_Load_Aux_Def
