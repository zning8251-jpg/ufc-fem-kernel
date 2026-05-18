!===============================================================================
! MODULE: NM_Conv_Def
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Def (four-type definitions for convergence monitoring)
! BRIEF:  Four-type definitions: NM_Conv_Desc/State/Algo/Ctx
!
! Status: FOUR-TYPE | Last verified: 2026-04-25
!===============================================================================
MODULE NM_Conv_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! NM_Conv_Desc — cold, INTENT(IN): convergence criteria
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Conv_Desc
    INTEGER(i4) :: max_iterations = 100
    REAL(wp)    :: abs_tol        = 1.0E-10_wp
    REAL(wp)    :: rel_tol        = 1.0E-6_wp
    INTEGER(i4) :: norm_type      = 2
  END TYPE NM_Conv_Desc

  !-----------------------------------------------------------------------------
  ! NM_Conv_State — warm, INTENT(INOUT): live iteration state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Conv_State
    INTEGER(i4) :: iteration      = 0
    REAL(wp)    :: residual_norm  = 0.0_wp
    REAL(wp)    :: initial_norm   = 0.0_wp
    LOGICAL     :: converged      = .FALSE.
    LOGICAL     :: diverged       = .FALSE.
  END TYPE NM_Conv_State

  !-----------------------------------------------------------------------------
  ! NM_Conv_Algo — cold, INTENT(IN): acceleration strategy
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Conv_Algo
    LOGICAL     :: use_line_search = .FALSE.
    REAL(wp)    :: relaxation      = 1.0_wp
    INTEGER(i4) :: check_frequency = 1
  END TYPE NM_Conv_Algo

  !-----------------------------------------------------------------------------
  ! NM_Conv_Ctx — hot, INTENT(INOUT): convergence rate tracking
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Conv_Ctx
    REAL(wp)    :: prev_residual  = 0.0_wp
    REAL(wp)    :: conv_rate      = 0.0_wp
    INTEGER(i4) :: stagnation_cnt = 0
  END TYPE NM_Conv_Ctx

END MODULE NM_Conv_Def
