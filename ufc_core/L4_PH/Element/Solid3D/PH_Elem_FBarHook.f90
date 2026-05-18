!===============================================================================
! MODULE: PH_Elem_FBarHook
! LAYER:  L4_PH
! DOMAIN: Element / Solid3D
! ROLE:   Phase6 §3.3 — F-bar / volumetric stabilization **hook** (stub default)
! BRIEF:  Returns unity scaling until B-bar/F-bar kernel is integrated per element family.
!===============================================================================
MODULE PH_Elem_FBarHook
  USE IF_Prec_Core, ONLY: wp
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Elem_FBar_VolRatio_stub
  PUBLIC :: PH_Elem_FBar_PatchTest_Pass

CONTAINS

  PURE FUNCTION PH_Elem_FBar_VolRatio_stub(j_det) RESULT(ratio)
    REAL(wp), INTENT(IN) :: j_det
    REAL(wp) :: ratio
    IF (j_det > 1.0e-20_wp) THEN
      ratio = 1.0_wp
    ELSE
      ratio = 1.0_wp
    END IF
  END FUNCTION PH_Elem_FBar_VolRatio_stub

  ! Phase6 §3.3: static acceptance hook until real F-bar patch driver exists.
  PURE FUNCTION PH_Elem_FBar_PatchTest_Pass() RESULT(ok)
    LOGICAL :: ok
    ok = .TRUE.
  END FUNCTION PH_Elem_FBar_PatchTest_Pass

END MODULE PH_Elem_FBarHook
