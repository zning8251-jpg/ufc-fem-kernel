!===============================================================================
! MODULE: MD_Cont_Aux_Def
! LAYER:  L3_MD
! DOMAIN: Interaction / Contact
! ROLE:   Aux Def — auxiliary TYPE definitions for Contact step-level algorithm
!         control, bridging the P1 Algo gap identified in
!         Procedure_Algorithm_L3L4L5_synthesis.md §C.
! BRIEF:  MD_Cont_Stp_Ctl_Algo (步级接触算法控制) aligned with
!         PH_Mat_Stp_Ctl_Algo (Material) and PH_Elem_Stp_Ctl_Algo (Element).
!         Covers: enforcement / penalty / search / friction / convergence.
!===============================================================================
MODULE MD_Cont_Aux_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! Enforcement method constants (aligned with MD_INT_CALGO_* in MD_Int_Types)
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_ENFORCE_PENALTY   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_ENFORCE_LAGRANGE  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_ENFORCE_AUG_LAG   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_ENFORCE_DIRECT    = 4_i4

  ! ==========================================================================
  ! Search strategy constants
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_SEARCH_BRUTE   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_SEARCH_BVH     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_SEARCH_BUCKET  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_SEARCH_GLOBAL  = 4_i4

  ! ==========================================================================
  ! Sliding formulation constants
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_SLIDE_SMALL  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_CONT_SLIDE_FINITE = 2_i4

  ! ==========================================================================
  ! MD_Cont_Stp_Ctl_Algo — Step-level contact algorithm control
  ! [Phase:Stp|Verb:Ctl]
  !
  ! Unifies the step-level algorithm parameters that were previously scattered
  ! across ContAlgo (MD_Cont_Mgr) and MD_Int_AlgoCtrl_Algo (MD_Int_Types).
  ! ==========================================================================
  TYPE, PUBLIC :: MD_Cont_Stp_Ctl_Algo
    ! --- Enforcement method ---
    INTEGER(i4) :: enforcement_method = MD_CONT_ENFORCE_PENALTY  ! PH_LDBC_BC_* aligned
    INTEGER(i4) :: sliding_type      = MD_CONT_SLIDE_SMALL       ! Small / Finite

    ! --- Penalty parameters ---
    REAL(wp)    :: penalty_normal    = 1.0E6_wp    ! Normal penalty stiffness
    REAL(wp)    :: penalty_tangent   = 1.0E5_wp    ! Tangent penalty stiffness
    REAL(wp)    :: penalty_scale     = 1.0_wp      ! Penalty scale factor
    LOGICAL     :: auto_penalty      = .TRUE.      ! Automatic penalty calculation

    ! --- Augmented Lagrange parameters ---
    REAL(wp)    :: lagrange_tol      = 1.0E-8_wp   ! Lagrange multiplier convergence
    INTEGER(i4) :: max_aug_iter      = 20_i4       ! Max AugLag iterations per step
    REAL(wp)    :: rho_aug           = 1.0_wp      ! AugLag update factor

    ! --- Search parameters ---
    INTEGER(i4) :: search_strategy   = MD_CONT_SEARCH_BVH    ! Search algorithm
    REAL(wp)    :: search_radius     = 0.0_wp                ! Contact detection radius
    INTEGER(i4) :: max_search_iter   = 10_i4                 ! Max search iterations
    LOGICAL     :: adjust_midplane   = .FALSE.               ! Adjust midplane for shells

    ! --- Friction switch ---
    LOGICAL     :: include_friction  = .TRUE.                ! Include friction flag
    REAL(wp)    :: friction_coeff    = 0.3_wp                ! Coulomb friction coeff
    REAL(wp)    :: tolerance_gap     = 1.0E-6_wp             ! Gap tolerance
    REAL(wp)    :: tolerance_slip    = 1.0E-8_wp             ! Slip tolerance

    ! --- Stabilization ---
    LOGICAL     :: use_stabilization = .FALSE.               ! Contact stabilization
    REAL(wp)    :: stab_factor       = 0.0_wp                ! Stabilization factor
  END TYPE MD_Cont_Stp_Ctl_Algo

END MODULE MD_Cont_Aux_Def
