!===============================================================================
! MODULE: MD_Constr_Sync
! LAYER:  L3_MD
! DOMAIN: Constraint
! ROLE:   Sync — Legacy assembly union → domain container sync
! BRIEF:  Sync assembly%constraint_union -> md_layer%constraint.
! PILOT:  Vertical slice anchor — single Sync entry; callers chain Sync→Populate→RT_Asm.
!===============================================================================
!
! Procedures:
!   [P1] MD_Constraint_SyncFromLegacy — Copy+release legacy constraint union
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Const | Role:Sync | FuncSet:Sync | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Constraint/CONTRACT.md

MODULE MD_Constr_Sync
  USE IF_Prec_Core,    ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Constr_Mgr, ONLY: MD_Constraint_Domain
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Constraint_SyncFromLegacy

CONTAINS

  !====================================================================
  ! MD_Constraint_SyncFromLegacy
  ! Sync assembly%constraint_union -> md_layer%constraint
  !====================================================================
  SUBROUTINE MD_Constraint_SyncFromLegacy(md_layer, status)
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_ConstraintSync: md_layer not initialized"
      RETURN
    END IF

    IF (.NOT. md_layer%constraint%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_ConstraintSync: constraint domain not initialized"
      RETURN
    END IF

    CALL md_layer%constraint%SyncFromUnion(md_layer%assembly%constraint_union, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL md_layer%assembly%ReleaseConstraintUnion()

  END SUBROUTINE MD_Constraint_SyncFromLegacy

END MODULE MD_Constr_Sync