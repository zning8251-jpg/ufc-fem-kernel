!===============================================================================
! MODULE: PH_Mat_Constit_Def
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def [DEPRECATED 2026-05]
! BRIEF:  Legacy material constitutive point-level TYPEs.
!
! DEPRECATION NOTICE (2026-05-06):
!   PH_MatPoint_State and PH_MatPoint_StressStrain are flat legacy types
!   retained for backward compatibility with ~50 element files.
!
!   REPLACEMENT: Use PH_Mat_State (nested PH_Mat_Lcl_Comp_State + PH_Mat_Lcl_Evo_State)
!   from PH_Mat_Domain_Core / PH_Mat_Def.
!
!   MIGRATION PATH:
!     PH_MatPoint_State fields → PH_Mat_State mapping:
!       statev(:)    → state%evo%stateVars(:)
!       statev_old(:) → state%evo%stateVars_n(:)
!       temp         → (via PH_Mat_Ctx or slot context)
!       mat_id, nStatev, time_step, total_time → (via PH_Mat_Ctx or slot)
!
!   STATUS:  Code retained for backward compatibility.
!   PLAN:    Migrate ~50 element files in a dedicated batch, then remove.
!===============================================================================
MODULE PH_Mat_Constit_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !--- [PUBLIC TYPES] ---
  PUBLIC :: PH_MatPoint_State
  PUBLIC :: PH_MatPoint_StressStrain

  !--- SECTION 1: TYPE DEFINITIONS ---

  !=============================================================================
  ! TYPE: PH_MatPoint_State
  ! KIND: State (mutable runtime)
  ! DESC: Runtime state with SDVs at a material point.
  ! DEPRECATED: Use PH_Mat_State (nested) for new code.
  !=============================================================================
  TYPE :: PH_MatPoint_State
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: nStatev = 0_i4
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: statev_old(:)
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: temp_old = 0.0_wp
    REAL(wp) :: time_step = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  END TYPE PH_MatPoint_State

  !=============================================================================
  ! TYPE: PH_MatPoint_StressStrain
  ! KIND: State (mutable runtime)
  ! DESC: Stress/strain tensor pair at a material point (Voigt 6).
  ! DEPRECATED: Use PH_Mat_State%comp for new code.
  !=============================================================================
  TYPE :: PH_MatPoint_StressStrain
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: strain_inc(6) = 0.0_wp
    REAL(wp) :: strain_old(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: tangent(6,6) = 0.0_wp
  END TYPE PH_MatPoint_StressStrain

END MODULE PH_Mat_Constit_Def
