!======================================================================
! MODULE:  MD_Int_Sync
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Sync
! BRIEF:   Sync legacy UF_ModelDef contact data to
!          MD_Interaction_Domain. Verify consistency.
! PILOT:   Single entry `MD_Interaction_SyncFromLegacy` — Legacy/union → `md_layer%interaction` 竖切，桥接不放在本域。
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Sync
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Model_Lib_Core,            ONLY: UF_ModelDef
  USE MD_Constr_Prop,    ONLY: UF_ContactPropertyDB, UF_ContactPropertyDef
  USE MD_Cont_Mgr, ONLY: MD_Interaction_Domain, MD_ContactProperty, MD_ContactPairDef
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE MD_Int_Def,     ONLY: MD_Friction_Type
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Interaction_SyncFromLegacy

CONTAINS

  !====================================================================
  ! MD_Interaction_SyncFromLegacy
  ! Sync UF_ModelDef%contact_db (props) ?md_layer%interaction
  ! Pairs: when assembly%interaction_union exists, sync from there.
  ! Step pair_ids: when step-level pair data exists, populate.
  !====================================================================
  SUBROUTINE MD_Interaction_SyncFromLegacy(model_def, md_layer, status)
    TYPE(UF_ModelDef),          INTENT(IN)    :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, n_props, n_pairs, pair_id, n_steps
    TYPE(MD_ContactProperty) :: prop_desc
    TYPE(MD_ContactPairDef) :: pair_def

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_IntSync: md_layer not initialized"
      RETURN
    END IF

    IF (.NOT. md_layer%interaction%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_IntSync: interaction domain not initialized"
      RETURN
    END IF

    !------------------------------------------------------------------
    ! 1) Sync contact properties from model_def%contact_db
    !------------------------------------------------------------------
    n_props = model_def%contact_db%num_props
    IF (n_props > 0 .AND. ALLOCATED(model_def%contact_db%props)) THEN
      DO i = 1, n_props
        IF (i > SIZE(model_def%contact_db%props)) EXIT
        CALL UF_ContactPropertyDef_To_MD_ContactProperty( &
             model_def%contact_db%props(i), prop_desc)
        CALL md_layer%interaction%AddProperty(prop_desc, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END DO
    END IF

    !------------------------------------------------------------------
    ! 2) Pairs: sync from assembly%interaction_union (Phase F)
    !------------------------------------------------------------------
    n_pairs = md_layer%assembly%interaction_union%n_pairs
    n_steps = md_layer%step%n_steps
    IF (n_pairs > 0 .AND. ALLOCATED(md_layer%assembly%interaction_union%contact_pairs)) THEN
      DO i = 1, n_pairs
        pair_def = md_layer%assembly%interaction_union%contact_pairs(i)
        CALL md_layer%interaction%AddPair(pair_def, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END DO
    END IF

    !------------------------------------------------------------------
    ! 3) Step pair_ids: UF_StepDef%pair_ids (parse) or pair_def%step_refs
    ! Phase F: when model_def%step_mgr%steps(s)%pair_ids present, use it
    !------------------------------------------------------------------
    DO j = 1, n_steps
      IF (ALLOCATED(model_def%step_mgr%steps) .AND. j <= model_def%step_mgr%num_steps .AND. &
          j <= SIZE(model_def%step_mgr%steps) .AND. &
          ALLOCATED(model_def%step_mgr%steps(j)%pair_ids) .AND. &
          SIZE(model_def%step_mgr%steps(j)%pair_ids) > 0) THEN
        ! Use step-level pair_ids from parse (map_contact_pair / map_surface_to_surface_contact)
        DO i = 1, SIZE(model_def%step_mgr%steps(j)%pair_ids)
          pair_id = model_def%step_mgr%steps(j)%pair_ids(i)
          CALL md_layer%step%AddPairId(j, pair_id, status)
          IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO
      ELSE
        ! Fallback: pair_def%step_refs or active_in_all_steps
        IF (n_pairs > 0 .AND. ALLOCATED(md_layer%assembly%interaction_union%contact_pairs)) THEN
          DO i = 1, n_pairs
            pair_def = md_layer%assembly%interaction_union%contact_pairs(i)
            pair_id = i
            IF (ALLOCATED(pair_def%step_refs) .AND. SIZE(pair_def%step_refs) > 0) THEN
              IF (ANY(pair_def%step_refs == j)) THEN
                CALL md_layer%step%AddPairId(j, pair_id, status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
              END IF
            ELSE IF (pair_def%active_in_all_steps) THEN
              CALL md_layer%step%AddPairId(j, pair_id, status)
              IF (status%status_code /= IF_STATUS_OK) RETURN
            END IF
          END DO
        END IF
      END IF
    END DO

    ! Release parse buffer; single source: md_layer%interaction (index tree + flat domain)
    CALL md_layer%assembly%ReleaseInteractionUnion()

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Interaction_SyncFromLegacy

  !====================================================================
  ! UF_ContactPropertyDef_To_MD_ContactProperty
  ! Conversion helper: UF_* ?MD_ContactProperty
  !====================================================================
  SUBROUTINE UF_ContactPropertyDef_To_MD_ContactProperty(uf_prop, prop)
    TYPE(UF_ContactPropertyDef), INTENT(IN)  :: uf_prop
    TYPE(MD_ContactProperty),    INTENT(OUT) :: prop

    prop%name = uf_prop%name
    prop%friction%mu_static  = uf_prop%mu_s
    prop%friction%mu_kinetic = uf_prop%mu_k
    prop%has_friction = (uf_prop%mu_s > 0.0_wp .OR. uf_prop%mu_k > 0.0_wp)
    prop%has_cohesion = .FALSE.
    prop%has_damping  = .FALSE.
    ! penalty_scale from UF maps to penalty_stiffness (scale factor; use 1e6 * scale as default)
    prop%pressure_overclosure%penalty_stiffness = 1.0e6_wp * MAX(1.0_wp, uf_prop%penalty_scale)
  END SUBROUTINE UF_ContactPropertyDef_To_MD_ContactProperty

END MODULE MD_Int_Sync