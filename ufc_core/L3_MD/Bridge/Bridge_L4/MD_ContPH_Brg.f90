!===============================================================================
! MODULE: MD_ContPH_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L4
! ROLE:   Brg — Contact L3→L4 bridge
! BRIEF:  Map L3 interaction descriptors to L4 PH_Contact_Params.
!===============================================================================

MODULE MD_ContPH_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core,    ONLY: wp, i4
  USE MD_Cont_Mgr, ONLY: MD_ContactProperty
  USE MD_Int_Def, ONLY: MD_ContactProperty_Type, MD_ContactPairDef, &
      CONTACT_ALG_PENALTY, CONTACT_ALG_LAGRANGE, CONTACT_ALG_AUG_LAGRANGE, CONTACT_ALG_MORTAR, &
      CONT_FORM_NODE
  USE PH_Cont_Domain, ONLY: PH_Contact_Params, PH_CONT_SURF_TO_SURF, PH_CONT_MORTAR, &
      PH_CONT_NODE_TO_SURF, PH_FRIC_COULOMB, PH_FRIC_EXPONENTIAL
  IMPLICIT NONE
  PRIVATE

  INTERFACE MD_Cont_PH_FillParams_FromMD
    MODULE PROCEDURE MD_Cont_PH_Fill_From_Type
    MODULE PROCEDURE MD_Cont_PH_Fill_From_Union
  END INTERFACE MD_Cont_PH_FillParams_FromMD

  PUBLIC :: MD_Cont_PH_FillParams_FromMD

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Cont_PH_Fill_From_Type
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Fill PH params from flat MD_ContactProperty_Type
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Cont_PH_Fill_From_Type(prop, params, status, pair_def)
    TYPE(MD_ContactProperty_Type), INTENT(IN)    :: prop
    TYPE(PH_Contact_Params),       INTENT(INOUT) :: params
    TYPE(ErrorStatusType),         INTENT(OUT)   :: status
    TYPE(MD_ContactPairDef),       INTENT(IN), OPTIONAL :: pair_def

    REAL(wp) :: mu_eff

    CALL init_error_status(status)

    params%phys%penaltyNormal  = prop%penalty_stiffness
    params%ctrl%contactTol     = prop%friction%stick_tolerance
    params%ctrl%searchTol      = prop%search_radius
    params%ctrl%maxAugIter     = 10_i4
    params%ctrl%adjustPenalty  = .FALSE.

    IF (prop%cohesion%enabled .AND. prop%cohesion%shear_stiffness > 0.0_wp) THEN
      params%phys%penaltyTangent = prop%cohesion%shear_stiffness
    ELSE
      params%phys%penaltyTangent = params%phys%penaltyNormal
    END IF

    mu_eff = prop%friction%mu_static
    IF (mu_eff <= 0.0_wp) mu_eff = prop%friction%mu_kinetic
    params%phys%frictionCoeff = mu_eff

    SELECT CASE (prop%algorithm)
    CASE (CONTACT_ALG_MORTAR)
      params%algo%algorithm = PH_CONT_MORTAR
    CASE (CONTACT_ALG_PENALTY, CONTACT_ALG_LAGRANGE, CONTACT_ALG_AUG_LAGRANGE)
      params%algo%algorithm = PH_CONT_SURF_TO_SURF
    CASE DEFAULT
      params%algo%algorithm = PH_CONT_SURF_TO_SURF
    END SELECT

    IF (TRIM(ADJUSTL(prop%friction%model)) == "EXPONENTIAL") THEN
      params%algo%frictionModel = PH_FRIC_EXPONENTIAL
    ELSE
      params%algo%frictionModel = PH_FRIC_COULOMB
    END IF

    IF (PRESENT(pair_def)) THEN
      IF (pair_def%small_sliding .AND. pair_def%finite_sliding) THEN
        params%ctrl%finiteSlidng = .TRUE.
      ELSE IF (pair_def%small_sliding .AND. .NOT. pair_def%finite_sliding) THEN
        params%ctrl%finiteSlidng = .FALSE.
      ELSE IF (pair_def%finite_sliding) THEN
        params%ctrl%finiteSlidng = .TRUE.
      ELSE
        params%ctrl%finiteSlidng = .TRUE.
      END IF
      IF (pair_def%formulation == CONT_FORM_NODE) THEN
        params%algo%algorithm = PH_CONT_NODE_TO_SURF
      END IF
    ELSE
      params%ctrl%finiteSlidng = .TRUE.
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Cont_PH_Fill_From_Type

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Cont_PH_Fill_From_Union
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Merge MD_ContactProperty union into effective type then fill PH
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Cont_PH_Fill_From_Union(mdprop, params, status, pair_def)
    TYPE(MD_ContactProperty),       INTENT(IN)    :: mdprop
    TYPE(PH_Contact_Params),        INTENT(INOUT) :: params
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status
    TYPE(MD_ContactPairDef),        INTENT(IN), OPTIONAL :: pair_def

    TYPE(MD_ContactProperty_Type) :: eff

    eff = mdprop%pressure_overclosure
    IF (mdprop%has_friction) eff%friction = mdprop%friction
    IF (mdprop%has_cohesion) eff%cohesion = mdprop%cohesion

    CALL MD_Cont_PH_Fill_From_Type(eff, params, status, pair_def)
  END SUBROUTINE MD_Cont_PH_Fill_From_Union

END MODULE MD_ContPH_Brg
