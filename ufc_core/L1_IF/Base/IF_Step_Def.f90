!===============================================================================
! MODULE: IF_Step_Def
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Def — canonical runtime step type constants
! BRIEF:  Single source of truth for RT_STEP_TYPE_* (PROC_* -> RT routing).
!         Used by MD_Step_Proc::ProcToRTStepType and L5_RT step dispatch.
!===============================================================================
MODULE IF_Step_Def
    USE IF_Prec_Core, ONLY: i4
    IMPLICIT NONE
    PRIVATE

    ! --------------------------------------------------------------------------
    ! Canonical RT step type constants (must match RT_Step_Core / RT_Step_Drv)
    ! --------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_STATIC            = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_IMPL_DYN         = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_EXPL_DYN         = 3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_ARC               = 4_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_CONTACT           = 5_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_HEAT             = 6_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_CPL_TD           = 7_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_EIGEN            = 8_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_FREQUENCY_RESP   = 9_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_RANDOM_RESP      = 10_i4
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_SUBSTRUCTURE     = 11_i4

    ! Max valid type for validation
    INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_MAX = 11_i4

END MODULE IF_Step_Def
