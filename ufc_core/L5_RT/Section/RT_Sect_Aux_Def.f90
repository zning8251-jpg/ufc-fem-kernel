!===============================================================================
! MODULE: RT_Sect_Aux_Def
! LAYER:  L5_RT
! DOMAIN: Section
! ROLE:   Aux Def — auxiliary TYPE definition for Section step-level
!         algorithm control, bridging the P3 gap identified in
!         Procedure_Algorithm_L3L4L5_synthesis.md §C.
! BRIEF:  RT_Sect_Stp_Ctl_Algo (步级截面校验/Populate/查询策略),
!         aligned with RT_Mat_Stp_Ctl_Algo / RT_Out_Stp_Ctl_Algo /
!         RT_WB_Stp_Ctl_Algo / PH_LoadBC_Stp_Ctl_Algo pattern.
!
! NOTE:   Section is an orthogonal dimension (正交维) — L5 Section does not
!         have a hot-path compute role. This Stp_Ctl_Algo governs
!         L5-level Populate/M-S-E validation/query control, NOT
!         constitutive or element-level computation.
!===============================================================================
MODULE RT_Sect_Aux_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-- M-S-E compatibility check mode constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_COMPAT_STRICT  = 0_i4  ! Abort on M-S-E mismatch
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_COMPAT_RELAXED = 1_i4  ! Warn on M-S-E mismatch
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_COMPAT_SKIP    = 2_i4  ! Skip M-S-E check

  !-- Integration rule override constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_IRULE_USE_L3   = 0_i4  ! Use L3 default_integration_rule
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_IRULE_USE_ELEM = 1_i4  ! Element override takes priority
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_IRULE_FATAL    = 2_i4  ! Fatal on conflict

  !-- Missing section policy constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_MISSING_ERROR   = 0_i4  ! Error on missing section_id
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_MISSING_DEFAULT = 1_i4  ! Return default solid section
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SECT_MISSING_SKIP    = 2_i4  ! Skip this element

  ! ==========================================================================
  ! RT_Sect_Stp_Ctl_Algo — Step-level section Populate/validation control
  ! [Phase:Stp|Verb:Ctl]
  !
  ! Controls how the L5 section layer handles Populate, M-S-E compatibility
  ! validation, integration rule resolution, and section query behavior.
  ! ==========================================================================
  TYPE, PUBLIC :: RT_Sect_Stp_Ctl_Algo
    ! --- M-S-E compatibility check ---
    INTEGER(i4) :: compat_check_mode = RT_SECT_COMPAT_STRICT
    LOGICAL     :: validate_on_populate = .TRUE.    ! Validate during L3→L5 Populate

    ! --- Integration rule resolution ---
    INTEGER(i4) :: integration_rule_override = RT_SECT_IRULE_USE_L3
    LOGICAL     :: allow_integration_conflict = .FALSE.  ! Allow L3↔Element mismatch

    ! --- Material association ---
    LOGICAL     :: allow_missing_material = .FALSE.  ! Allow sections without material

    ! --- Section query ---
    INTEGER(i4) :: missing_section_policy = RT_SECT_MISSING_ERROR
    LOGICAL     :: section_cache_enabled  = .TRUE.  ! Cache section lookups at L5

    ! --- Override ---
    LOGICAL     :: force_repopulate = .FALSE.  ! Force repopulate even if already populated
    LOGICAL     :: suppress_compat_check = .FALSE.  ! Suppress all compat checks (debug)
  END TYPE RT_Sect_Stp_Ctl_Algo

END MODULE RT_Sect_Aux_Def
