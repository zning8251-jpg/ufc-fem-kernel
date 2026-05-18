!===============================================================================
! MODULE: NM_TimeInt_Def
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Def — Four-type definitions for time integration schemes
! BRIEF:  NM_TimeInt_Desc / _State / _Algo / _Ctx type definitions
!         + Phase 6B: NM_TInt_Scheme_Ifc Procedure-as-Parameter strategy
!===============================================================================
MODULE NM_TimeInt_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_TimeInt_Desc
  PUBLIC :: NM_TimeInt_State
  PUBLIC :: NM_TimeInt_Algo
  PUBLIC :: NM_TimeInt_Ctx
  ! Phase 6B: Procedure-as-Parameter strategy interface
  PUBLIC :: NM_TInt_Scheme_Ifc
  PUBLIC :: NM_TInt_Step_Arg

  INTEGER(i4), PARAMETER, PUBLIC :: NM_TINT_NEWMARK      = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TINT_CENTRAL_DIFF = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TINT_HHT_ALPHA    = 3

  !-----------------------------------------------------------------------------
  ! NM_TimeInt_Desc — cold, INTENT(IN): problem size
  !-----------------------------------------------------------------------------
  TYPE :: NM_TimeInt_Desc
    INTEGER(i4) :: ndof = 0
  END TYPE NM_TimeInt_Desc

  !-----------------------------------------------------------------------------
  ! NM_TimeInt_State — warm, INTENT(INOUT): evolving dynamic state
  !-----------------------------------------------------------------------------
  TYPE :: NM_TimeInt_State
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dt   = 0.0_wp
    REAL(wp), POINTER :: u(:)      => NULL()
    REAL(wp), POINTER :: v(:)      => NULL()
    REAL(wp), POINTER :: a(:)      => NULL()
    REAL(wp), POINTER :: u_pred(:) => NULL()
    REAL(wp), POINTER :: v_pred(:) => NULL()
  END TYPE NM_TimeInt_State

  !-----------------------------------------------------------------------------
  ! NM_TimeInt_Ctx — hot, INTENT(INOUT): current sub-step timing
  !-----------------------------------------------------------------------------
  TYPE :: NM_TimeInt_Ctx
    REAL(wp)    :: dt_current  = 0.0_wp
    REAL(wp)    :: dt_previous = 0.0_wp
    REAL(wp)    :: t_current   = 0.0_wp
    INTEGER(i4) :: substep     = 0
  END TYPE NM_TimeInt_Ctx

  !-----------------------------------------------------------------------------
  ! Phase 6B: Structured argument for time integration scheme dispatch
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_TInt_Step_Arg
    REAL(wp) :: dt       = 0.0_wp    ! [IN]  time step size
    REAL(wp) :: beta     = 0.25_wp   ! [IN]  Newmark beta
    REAL(wp) :: gamma    = 0.5_wp    ! [IN]  Newmark gamma
    REAL(wp) :: alpha_hht= 0.0_wp    ! [IN]  HHT alpha parameter
    INTEGER(i4) :: ndof  = 0         ! [IN]  number of DOFs
    TYPE(ErrorStatusType) :: status   ! [OUT]
  END TYPE NM_TInt_Step_Arg

  !-----------------------------------------------------------------------------
  ! Phase 6B: ABSTRACT INTERFACE for pluggable time integration scheme
  ! Procedure-as-Parameter: allows Newmark, HHT-alpha, or custom strategies
  ! Must be defined BEFORE NM_TimeInt_Algo which references it.
  !-----------------------------------------------------------------------------
  ABSTRACT INTERFACE
    SUBROUTINE NM_TInt_Scheme_Ifc(algo, state, arg, status)
      IMPORT :: NM_TimeInt_Algo, NM_TimeInt_State, NM_TInt_Step_Arg, ErrorStatusType
      TYPE(NM_TimeInt_Algo),  INTENT(IN)    :: algo
      TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
      TYPE(NM_TInt_Step_Arg), INTENT(INOUT) :: arg
      TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    END SUBROUTINE
  END INTERFACE

  !-----------------------------------------------------------------------------
  ! NM_TimeInt_Algo — cold, INTENT(IN): algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE :: NM_TimeInt_Algo
    INTEGER(i4) :: method    = NM_TINT_NEWMARK
    REAL(wp)    :: beta      = 0.25_wp
    REAL(wp)    :: gamma     = 0.5_wp
    REAL(wp)    :: alpha_hht = 0.0_wp
    ! --- Phase 6B: Procedure-as-Parameter time integration strategy pointer ---
    PROCEDURE(NM_TInt_Scheme_Ifc), POINTER, NOPASS :: scheme_strategy => NULL()
  END TYPE NM_TimeInt_Algo

END MODULE NM_TimeInt_Def
