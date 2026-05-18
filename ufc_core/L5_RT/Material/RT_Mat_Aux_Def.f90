!===============================================================================
! MODULE: RT_Mat_Aux_Def
! LAYER:  L5_RT
! DOMAIN: Material
! ROLE:   Aux Def — auxiliary TYPE definition for Material step-level
!         dispatch algorithm control, bridging the P2 gap identified in
!         Procedure_Algorithm_L3L4L5_synthesis.md §C.
! BRIEF:  RT_Mat_Stp_Ctl_Algo (步级材料分发/NaN检测/子增量控制),
!         aligned with RT_Out_Stp_Ctl_Algo / RT_WB_Stp_Ctl_Algo /
!         PH_LoadBC_Stp_Ctl_Algo / MD_Cont_Stp_Ctl_Algo pattern.
!
! NOTE:   L5 Material is a pure routing domain; this Stp_Ctl_Algo governs
!         L5-level dispatch strategy, NOT constitutive algorithm parameters
!         (those remain at L4 PH_Mat_Stp_Ctl_Algo / PH_Mat_Algo).
!===============================================================================
MODULE RT_Mat_Aux_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-- Dispatch mode constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_DISPATCH_DIRECT = 0_i4   ! SELECT CASE dispatch
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_DISPATCH_BUFFERED = 1_i4 ! Buffered batch dispatch

  !-- NaN policy constants (aligned with RT_WB_Stp_Ctl_Algo%nan_policy)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_NAN_TRUNCATE_WARN = 0_i4  ! Truncate + warn
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_NAN_SKIP = 1_i4           ! Skip this IP
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_NAN_ABORT = 2_i4          ! Abort simulation

  ! ==========================================================================
  ! RT_Mat_Stp_Ctl_Algo — Step-level material dispatch algorithm control
  ! [Phase:Stp|Verb:Ctl]
  !
  ! Controls how the L5 material routing domain dispatches material
  ! computations to L4 kernels, including error handling, NaN detection,
  ! sub-incrementation, and fallback strategies.
  ! ==========================================================================
  TYPE, PUBLIC :: RT_Mat_Stp_Ctl_Algo
    ! --- Dispatch strategy ---
    INTEGER(i4) :: dispatch_mode = RT_MAT_DISPATCH_DIRECT
    LOGICAL     :: error_on_dispatch_failure = .TRUE.   ! FATAL on route not found
    LOGICAL     :: elastic_fallback_on_failure = .FALSE. ! Use elastic as fallback

    ! --- NaN detection ---
    LOGICAL     :: nan_check_enabled = .TRUE.    ! Check NaN after material computation
    INTEGER(i4) :: nan_policy = RT_MAT_NAN_TRUNCATE_WARN  ! What to do on NaN

    ! --- Sub-incrementation control (L5 dispatch level) ---
    LOGICAL     :: sub_increment_enabled = .FALSE.  ! Enable L5-level sub-incrementation
    INTEGER(i4) :: max_sub_increments = 10_i4       ! Max sub-increments per IP
    REAL(wp)    :: sub_increment_tolerance = 1.0e-6_wp  ! Convergence tolerance

    ! --- Retry / divergence handling ---
    LOGICAL     :: retry_on_divergence = .FALSE.  ! Retry on divergent material
    INTEGER(i4) :: max_retries = 3_i4             ! Max retries per IP

    ! --- Override ---
    LOGICAL     :: force_dispatch = .FALSE.        ! Force dispatch even if route missing
    LOGICAL     :: suppress_material_update = .FALSE. ! Suppress all updates (debug)
  END TYPE RT_Mat_Stp_Ctl_Algo

END MODULE RT_Mat_Aux_Def
