!===============================================================================
! MODULE: IF_Sym_Mgr
! LAYER:  L1_IF
! DOMAIN: Symbol
! ROLE:   Mgr — FEM constants unified symbol table (compile-time PARAMETER)
! BRIEF:  Single source of truth for BC/DOF/Contact constants across L1-L6.
!         Layer prefix isolation (MD_/RT_/PH_/NM_/IF_/UFC_).
!===============================================================================
MODULE IF_Sym_Mgr
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! Public exports
  !============================================================================
  PUBLIC :: IF_Sym_Init

  !============================================================================
  ! Part 1: BC Family Constants (L3/MD layer - by physical field)
  !============================================================================
  !
  ! Usage: MD_BC_Base_Desc%bc_family = MD_BC_FIELD_DISP
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    MD_BC_FIELD_DISP   = 1_i4,   &
    MD_BC_FIELD_VEL    = 2_i4,   &
    MD_BC_FIELD_ACC    = 3_i4,   &
    MD_BC_FIELD_POT    = 4_i4,   &
    MD_BC_FIELD_TEMP   = 5_i4,   &
    MD_BC_FIELD_MASFL  = 6_i4

  !============================================================================
  ! Part 2: BC Constraint Constants (L5/RT layer - by behavior)
  !============================================================================
  !
  ! Usage: RT_LoadBC_Desc%bc_types(i) = RT_BC_CONSTRAIN_FIXED
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_BC_CONSTRAIN_FIXED      = 1_i4,  &
    RT_BC_CONSTRAIN_PRESCRIBED = 2_i4,  &
    RT_BC_CONSTRAIN_SYMMETRIC  = 3_i4,  &
    RT_BC_CONSTRAIN_ANTISYMM   = 4_i4,  &
    RT_BC_CONSTRAIN_CYCLIC     = 5_i4

  !============================================================================
  ! Part 3: Compile-time BC Field �?Constraint Mapping
  !============================================================================
  !
  ! Purpose: Cross-layer compatibility without runtime overhead
  ! Format:  BC_FIELD_TO_CONSTRAIN(MD_BC_FIELD_XXX) = RT_BC_CONSTRAIN_YYY
  !
  ! Example usage:
  !   INTEGER(i4) :: constrain_type
  !   constrain_type = BC_FIELD_TO_CONSTRAIN(MD_BC_FIELD_DISP)  ! Returns 1 (FIXED)
  !
  ! This mapping is resolved at compile time - zero runtime cost.
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    BC_FIELD_TO_CONSTRAIN(6) = &
      [RT_BC_CONSTRAIN_FIXED,       &
       RT_BC_CONSTRAIN_FIXED,       &
       RT_BC_CONSTRAIN_FIXED,       &
       RT_BC_CONSTRAIN_PRESCRIBED, &
       RT_BC_CONSTRAIN_PRESCRIBED, &
       RT_BC_CONSTRAIN_PRESCRIBED]

  !============================================================================
  ! Part 4: DOF Index Constants
  !============================================================================
  !
  ! Usage: DOF index for displacement/rotation/temperature DOFs
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    DOF_UX    = 1_i4,  &
    DOF_UY    = 2_i4,  &
    DOF_UZ    = 3_i4,  &
    DOF_RX    = 4_i4,  &
    DOF_RY    = 5_i4,  &
    DOF_RZ    = 6_i4,  &
    DOF_TEMP  = 7_i4

  !============================================================================
  ! Part 5: Load Constants (L5/RT layer)
  !============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_LOAD_CONCENTRATED = 1_i4, &
    RT_LOAD_PRESSURE    = 2_i4, &
    RT_LOAD_TEMPERATURE  = 3_i4, &
    RT_LOAD_BODY         = 4_i4

  !============================================================================
  ! Part 6: Amplitude Interpolation Constants
  !============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_AMP_INTERP_LINEAR  = 0_i4, &
    RT_AMP_INTERP_SPLINE  = 1_i4, &
    RT_AMP_INTERP_STEP    = 2_i4, &
    RT_AMP_INTERP_TABULAR = 3_i4

  !============================================================================
  ! Part 7: Contact Constants (L5/RT layer)
  !============================================================================
  ! Contact formulation types
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_CONTACT_FORM_PENALTY      = 0_i4, &
    RT_CONTACT_FORM_LAGRANGE     = 1_i4, &
    RT_CONTACT_FORM_AUG_LAGRANGE = 2_i4

  ! Contact pair status
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_PAIR_OPEN     = 0_i4, &
    RT_PAIR_CLOSED   = 1_i4, &
    RT_PAIR_SLIDING  = 2_i4, &
    RT_PAIR_STICKING = 3_i4

  ! Friction model types
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_FRICTION_NONE    = 0_i4, &
    RT_FRICTION_COULOMB = 1_i4, &
    RT_FRICTION_VISCOUS = 2_i4

  !============================================================================
  ! Part 8: Ctx Hot Path Constants (for pre-allocation sizing)
  !============================================================================
  !
  ! Usage: Sizing for RT_XXX_Ctx%work_array(max_dim)
  ! All Ctx types MUST use these constants for pre-allocation - no ALLOCATE in hot path.
  !
  INTEGER(i4), PARAMETER, PUBLIC :: &
    RT_MAX_CONTACT_PAIRS = 10000_i4, &
    RT_MAX_GP_PER_PAIR   = 4_i4,      &
    RT_MAX_ELEM_NODES    = 27_i4,     &
    RT_MAX_ELEM_DOFS     = 81_i4,     &
    RT_MAX_GLOBAL_DOFS   = 1000000_i4

CONTAINS

  !============================================================================
  ! Subroutine: IF_Sym_Init
  ! Purpose: Module initialization (compile-time constants, no runtime setup)
  !============================================================================
  SUBROUTINE IF_Sym_Init()
    ! All constants are compile-time PARAMETER, no runtime initialization needed.
    ! This subroutine exists for API consistency with other UFC modules.
    RETURN
  END SUBROUTINE IF_Sym_Init

END MODULE IF_Sym_Mgr