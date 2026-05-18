!===============================================================================
! MODULE: RT_Mat_Def
! LAYER:  L5_RT
! DOMAIN: Material
! ROLE:   Def — thin re-export wrapper for L5 material dispatch types
! BRIEF:  Re-exports RT_Mat_Dispatch_Ctx/Route_Entry/Table from IF_Mat_Dispatch_Def.
!   W1: **RT_Mat_Dispatch_Ctx%mat_type** for 11-family markers should match
!   **PH_Mat_Desc_Effective_Model** when built from L4 **slot_pool%desc** (see **RT_Mat_Brg**).
!--- COLD (dispatch TYPE + route constants) vs HOT (RT_Mat_*_Core / RT_Mat_Brg) ---
!===============================================================================
MODULE RT_Mat_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Mat_Dispatch_Def, ONLY: &
    RT_Mat_Dispatch_Ctx,    &
    RT_Mat_Route_Entry,     &
    RT_Mat_Dispatch_Table,  &
    IF_MAT_ROUTE_OK,        &
    IF_MAT_ROUTE_NOT_FOUND, &
    IF_MAT_ROUTE_NO_KERNEL, &
    IF_MAT_TABLE_MAX
  USE RT_Mat_Aux_Def, ONLY: RT_Mat_Stp_Ctl_Algo
  IMPLICIT NONE
  PRIVATE

  ! Re-export types from IF_Mat_Dispatch_Def
  PUBLIC :: RT_Mat_Dispatch_Ctx
  PUBLIC :: RT_Mat_Route_Entry
  PUBLIC :: RT_Mat_Dispatch_Table

  ! Re-export RT_Mat_Algo (P2 gap-fill)
  PUBLIC :: RT_Mat_Algo

  ! Re-export constants (backward-compatible aliases)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_ROUTE_OK        = IF_MAT_ROUTE_OK
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_ROUTE_NOT_FOUND = IF_MAT_ROUTE_NOT_FOUND
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_ROUTE_NO_KERNEL = IF_MAT_ROUTE_NO_KERNEL
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MAT_TABLE_MAX       = IF_MAT_TABLE_MAX

  !-----------------------------------------------------------------------------
  ! RT_Mat_Algo — L5 Material Dispatch Algorithm Parameters (P2 gap-fill)
  !   Embeds RT_Mat_Stp_Ctl_Algo for step-level dispatch control.
  !   NOTE: This governs L5 dispatch strategy, NOT constitutive parameters
  !   (those remain at L4 PH_Mat_Stp_Ctl_Algo / PH_Mat_Algo).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mat_Algo
    TYPE(RT_Mat_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] dispatch/NaN/sub-inc
  END TYPE RT_Mat_Algo

END MODULE RT_Mat_Def
