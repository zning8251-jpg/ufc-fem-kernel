!======================================================================
! Test: PH_Mat_Domain smoke (formerly populate-without-global scaffold)
! Purpose: Compile-time / runtime smoke for `PH_Mat_Domain` lifecycle.
!          Full `PH_L4_Populate_Material` + registry mock is tracked separately.
!======================================================================
PROGRAM test_populate_material_no_global
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  USE PH_Mat_Domain_Core, ONLY: PH_Mat_Domain
  IMPLICIT NONE

  TYPE(PH_Mat_Domain) :: material_dom
  TYPE(ErrorStatusType) :: status

  PRINT *, '=== Smoke: PH_Mat_Domain Init/Finalize ==='

  CALL material_dom%Init(1_i4, status)
  IF (status%status_code /= IF_STATUS_OK) THEN
    PRINT *, 'FAIL: Init status=', status%status_code
    STOP 1
  END IF

  CALL material_dom%Finalize()

  PRINT *, '=== PASS: PH_Mat_Domain lifecycle ==='
END PROGRAM test_populate_material_no_global
