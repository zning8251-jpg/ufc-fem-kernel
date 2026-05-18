!===============================================================================
! MODULE: RT_Sect_Def
! LAYER:  L5_RT
! DOMAIN: Section
! ROLE:   Def — thin definition wrapper for L5 Section algorithm control types
! BRIEF:  Defines RT_Sect_Algo which embeds RT_Sect_Stp_Ctl_Algo for step-level
!         Populate/validation/query control. Section is an orthogonal dimension
!         (正交维) — no hot-path compute, only Populate cold-path consumption.
!===============================================================================
MODULE RT_Sect_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE RT_Sect_Aux_Def,  ONLY: RT_Sect_Stp_Ctl_Algo
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Sect_Algo
  PUBLIC :: RT_Sect_Stp_Ctl_Algo

  !-----------------------------------------------------------------------------
  ! RT_Sect_Algo — L5 Section Algorithm Parameters (P3 gap-fill)
  !   Embeds RT_Sect_Stp_Ctl_Algo for step-level Populate/validation control.
  !   NOTE: Section is an orthogonal dimension — this governs L5 Populate
  !   strategy (M-S-E compat, integration rule, query), NOT constitutive
  !   parameters (those remain at L3 MD_Sect_Algo / L4 embedded in Element).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Sect_Algo
    TYPE(RT_Sect_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] compat/populate/query
  END TYPE RT_Sect_Algo

END MODULE RT_Sect_Def
