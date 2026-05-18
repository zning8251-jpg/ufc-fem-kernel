!===============================================================================
! MODULE: AP_Input_Def
! LAYER:  L6_AP
! DOMAIN: Input
! ROLE:   Def
! BRIEF:  Type definitions for input file reading and keyword parsing.
!
! Four-Type Catalogue:
!   AP_Input_Desc  — file path and format specification (Desc)
!   AP_Input_State — parse progress counters (State)
!   AP_Inp_Algo    — algorithm/solver configuration (Algo)
!   AP_Inp_Arg     — step-level IO bundle (Arg)
!
! Status: FOUR-TYPE | Last verified: 2026-04-29
!===============================================================================
MODULE AP_Input_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Input_Desc
  PUBLIC :: AP_Input_State
  PUBLIC :: AP_Inp_Algo
  PUBLIC :: AP_Inp_Arg

  !-----------------------------------------------------------------------------
  ! TYPE: AP_Input_Desc (Desc — file path and format specification)
  !-----------------------------------------------------------------------------
  TYPE :: AP_Input_Desc
    CHARACTER(LEN=256) :: file_path = ""     ! Input file path
    CHARACTER(LEN=32)  :: format    = "ABAQUS" ! File format tag
  END TYPE AP_Input_Desc

  !-----------------------------------------------------------------------------
  ! TYPE: AP_Input_State (State — parse progress counters)
  !-----------------------------------------------------------------------------
  TYPE :: AP_Input_State
    INTEGER(i4) :: lines_read   = 0          ! Total lines read
    INTEGER(i4) :: parse_errors = 0          ! Accumulated parse errors
    INTEGER(i4) :: n_keywords   = 0          ! Keywords recognised
    INTEGER(i4) :: n_tokens     = 0          ! Tokens produced by S1
    LOGICAL     :: is_complete  = .FALSE.    ! Parse finished flag
    LOGICAL     :: model_built  = .FALSE.    ! S4 BuildModel done flag
  END TYPE AP_Input_State

  !-----------------------------------------------------------------------------
  ! TYPE: AP_Inp_Algo (Algo — algorithm/solver configuration for parsing)
  !-----------------------------------------------------------------------------
  TYPE :: AP_Inp_Algo
    LOGICAL :: strict_mode    = .TRUE.       ! Abort on first error
    LOGICAL :: echo_keywords  = .FALSE.      ! Echo recognised keywords
    LOGICAL :: skip_comments  = .TRUE.       ! Skip ** comment lines
    INTEGER(i4) :: max_errors  = 100_i4      ! Error threshold before abort
    INTEGER(i4) :: verbosity   = 1_i4        ! 0=silent,1=normal,2=verbose
  END TYPE AP_Inp_Algo

  !-----------------------------------------------------------------------------
  ! TYPE: AP_Inp_Arg (Arg — step-level IO bundle for Execute pipeline)
  !-----------------------------------------------------------------------------
  TYPE :: AP_Inp_Arg
    INTEGER(i4) :: unit_id      = -1_i4      ! Fortran IO unit (set by S1)
    INTEGER(i4) :: current_line = 0_i4       ! Current line cursor
    INTEGER(i4) :: token_count  = 0_i4       ! Tokens produced by S1
    INTEGER(i4) :: kw_count     = 0_i4       ! Keywords parsed by S2
    CHARACTER(LEN=256) :: last_keyword = ''  ! Last keyword processed
    CHARACTER(LEN=512) :: diag_msg    = ''   ! Diagnostic message buffer
  END TYPE AP_Inp_Arg

END MODULE AP_Input_Def
