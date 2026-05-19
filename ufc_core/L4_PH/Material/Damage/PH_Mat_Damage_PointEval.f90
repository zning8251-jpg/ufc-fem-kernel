!===============================================================================
! MODULE: PH_Mat_Damage_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Damage
! ROLE:   Eval (legacy point-model SIO — C2 split from PH_MatEval)
! BRIEF:  Ductile / brittle scalar damage point Eval.
! Purpose: Family-owned Arg types; brittle delegates to ductile path.
! Theory: (1-D) stiffness degrade from damage variable.
! Status: Production (legacy point) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Damage_PointEval
  USE IF_Base_Def, ONLY: ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_DamageDuctile_Eval_Arg, PH_Mat_DamageBrittle_Eval_Arg
  PUBLIC :: PH_Mat_DamageDuctile_Eval, PH_Mat_DamageBrittle_Eval

  TYPE, PUBLIC :: PH_Mat_DamageDuctile_Eval_Arg
    REAL(wp) :: damage = 0.0_wp
    REAL(wp) :: stress_undamaged(6) = 0.0_wp
    REAL(wp) :: D_matrix_undamaged(6, 6) = 0.0_wp
    REAL(wp) :: stress_damaged(6) = 0.0_wp
    REAL(wp) :: D_matrix_damaged(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_DamageDuctile_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_DamageBrittle_Eval_Arg
    REAL(wp) :: damage = 0.0_wp
    REAL(wp) :: stress_undamaged(6) = 0.0_wp
    REAL(wp) :: D_matrix_undamaged(6, 6) = 0.0_wp
    REAL(wp) :: stress_damaged(6) = 0.0_wp
    REAL(wp) :: D_matrix_damaged(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_DamageBrittle_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_DamageDuctile_Eval(arg)
    TYPE(PH_Mat_DamageDuctile_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: damage_factor
    INTEGER(i4) :: i, j
    CALL init_error_status(arg%status)
    damage_factor = MAX(ONE - arg%damage, 1.0e-6_wp)
    arg%stress_damaged = damage_factor * arg%stress_undamaged
    DO i = 1, 6
      DO j = 1, 6
        arg%D_matrix_damaged(i,j) = damage_factor * arg%D_matrix_undamaged(i,j)
      END DO
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_DamageDuctile_Eval

  SUBROUTINE PH_Mat_DamageBrittle_Eval(arg)
    TYPE(PH_Mat_DamageBrittle_Eval_Arg), INTENT(INOUT) :: arg
    TYPE(PH_Mat_DamageDuctile_Eval_Arg) :: ductile_arg
    ductile_arg%damage = arg%damage
    ductile_arg%stress_undamaged = arg%stress_undamaged
    ductile_arg%D_matrix_undamaged = arg%D_matrix_undamaged
    CALL PH_Mat_DamageDuctile_Eval(ductile_arg)
    arg%stress_damaged = ductile_arg%stress_damaged
    arg%D_matrix_damaged = ductile_arg%D_matrix_damaged
    arg%status = ductile_arg%status
  END SUBROUTINE PH_Mat_DamageBrittle_Eval

END MODULE PH_Mat_Damage_PointEval
