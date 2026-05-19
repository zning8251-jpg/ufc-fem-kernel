!===============================================================================
! MODULE: PH_MatEval
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Eval
! BRIEF:  Legacy aggregate Eval facade; C2 complete — implementations in family PointEval modules.
!   W1 gold path: `PH_Mat_Core` + slot `PH_Mat_Desc`; Arg-only public API (no Eval_In/Out pairs).
! Purpose: Re-export legacy point Eval symbols; UMAT workspace stub remains here.
! Theory: Point models delegated to Elas/Plast/Hyper/Damage/Creep/Viscoelas/Composite.
! Status: Production (facade) | Last verified: 2026-05-19
! Contract: L4_PH/Material/CONTRACT.md — "Legacy PH_MatEval aggregate" table.
!===============================================================================
MODULE PH_MatEval
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: i4, wp
  USE PH_Mat_Elas_PointEval, ONLY: PH_Mat_ElasticIsotropic_Eval_Arg, PH_Mat_ElasticOrthotropic_Eval_Arg, &
      PH_Mat_ElasticIsotropic_Eval, PH_Mat_ElasticOrthotropic_Eval
  USE PH_Mat_Plast_PointEval, ONLY: PH_Mat_PlasticVonMises_Eval_Arg, PH_Mat_PlasticHill_Eval_Arg, &
      PH_Mat_PlasticVonMises_Eval, PH_Mat_PlasticHill_Eval
  USE PH_Mat_Hyper_PointEval, ONLY: PH_Mat_HyperelasticNeoHookean_Eval_Arg, &
      PH_Mat_HyperelasticMooneyRivlin_Eval_Arg, PH_Mat_HyperelasticNeoHookean_Eval, &
      PH_Mat_HyperelasticMooneyRivlin_Eval
  USE PH_Mat_Damage_PointEval, ONLY: PH_Mat_DamageDuctile_Eval_Arg, PH_Mat_DamageBrittle_Eval_Arg, &
      PH_Mat_DamageDuctile_Eval, PH_Mat_DamageBrittle_Eval
  USE PH_Mat_Creep_PointEval, ONLY: PH_Mat_CreepNorton_Eval_Arg, PH_Mat_CreepNorton_Eval
  USE PH_Mat_Visco_PointEval, ONLY: PH_Mat_ViscoelasticProny_Eval_Arg, PH_Mat_ViscoelasticMaxwell_Eval_Arg, &
      PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg, PH_Mat_ViscoelasticProny_Eval, &
      PH_Mat_ViscoelasticMaxwell_Eval, PH_Mat_ViscoelasticKelvinVoigt_Eval
  USE PH_Mat_Comp_PointEval, ONLY: PH_Mat_CompositeLaminate_Eval_Arg, &
      PH_Mat_CompositeFiberReinforced_Eval_Arg, PH_Mat_CompositeLaminate_Eval, &
      PH_Mat_CompositeFiberReinforced_Eval
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_ElasticIsotropic_Eval_Arg
  PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
  PUBLIC :: PH_Mat_PlasticVonMises_Eval_Arg
  PUBLIC :: PH_Mat_PlasticHill_Eval_Arg
  PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval_Arg
  PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
  PUBLIC :: PH_Mat_DamageDuctile_Eval_Arg
  PUBLIC :: PH_Mat_DamageBrittle_Eval_Arg
  PUBLIC :: PH_Mat_CreepNorton_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticProny_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
  PUBLIC :: PH_Mat_CompositeLaminate_Eval_Arg
  PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval_Arg
  PUBLIC :: PH_Mat_UMATEnsureWorkspace_Arg
  PUBLIC :: PH_Mat_ElasticIsotropic_Eval
  PUBLIC :: PH_Mat_ElasticOrthotropic_Eval
  PUBLIC :: PH_Mat_PlasticVonMises_Eval
  PUBLIC :: PH_Mat_PlasticHill_Eval
  PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval
  PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval
  PUBLIC :: PH_Mat_DamageDuctile_Eval
  PUBLIC :: PH_Mat_DamageBrittle_Eval
  PUBLIC :: PH_Mat_CreepNorton_Eval
  PUBLIC :: PH_Mat_ViscoelasticProny_Eval
  PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval
  PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval
  PUBLIC :: PH_Mat_CompositeLaminate_Eval
  PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval
  PUBLIC :: PH_Mat_UMATEnsureWorkspace

  TYPE, PUBLIC :: PH_Mat_UMATEnsureWorkspace_Arg
    INTEGER(i4) :: nstate_target = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_UMATEnsureWorkspace_Arg

CONTAINS

  SUBROUTINE PH_Mat_UMATEnsureWorkspace(arg)
    TYPE(PH_Mat_UMATEnsureWorkspace_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    IF (arg%nstate_target < 0_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_UMATEnsureWorkspace

END MODULE PH_MatEval
