!===============================================================================
! MODULE: PH_L4_Populate
! LAYER:  L4_PH
! DOMAIN: Material / Populate
! BRIEF:  PH_L4_Populate_Material — L3 registry (typed Desc) → PH_Mat_Domain slot.
! Purpose: Cold-path Populate from L3 MD_Mat_Desc into L4 PH_Mat_Slot (cfg/props/state seed).
! Theory: Typed SELECT TYPE over MD_Mat_*_Desc; slot allocation via PH_Mat_AllocSlot_Idx per CONTRACT.
! Status: ACTIVE
!===============================================================================
MODULE PH_L4_Populate
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE MD_Mat_Registry, ONLY: MD_Mat_Registry_Access_Desc
  USE MD_Mat_Elas_Def, ONLY: MD_Mat_Elas_Desc
  USE MD_Mat_Plast_Def, ONLY: MD_Mat_Plast_Desc
  USE MD_Mat_Geo_Def, ONLY: MD_Mat_Geo_Desc
  USE MD_Mat_Hyper_Def, ONLY: MD_Mat_Hyper_Desc
  USE MD_Mat_Visco_Def, ONLY: MD_Mat_Visco_Desc
  USE MD_Mat_Creep_Def, ONLY: MD_Mat_Creep_Desc
  USE MD_Mat_Damage_Def, ONLY: MD_Mat_Damage_Desc
  USE MD_Mat_Comp_Def, ONLY: MD_Mat_Comp_Desc
  USE MD_Mat_Therm_Def, ONLY: MD_Mat_Therm_Desc
  USE MD_Mat_Acou_Def, ONLY: MD_Mat_Acou_Desc
  USE MD_Mat_User_Def, ONLY: MD_Mat_User_Desc
  USE PH_Mat_Domain_Core, ONLY: PH_Mat_Domain, PH_Mat_AllocSlot_Idx
  USE PH_L4_L3MatContract, ONLY: PH_MapL3MatTypeToL4
  USE IF_Mem_Algo, ONLY: IF_Mem_Algo_Scratch_Real1D, IF_Mem_Algo_Release_Real1D
  USE PH_Mat_Enum, ONLY: PH_MAT_ELASTIC, PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
    PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, PH_MAT_GEOTECH, PH_MAT_COMPOSITE, &
    PH_MAT_THERMAL, PH_MAT_ACOUSTIC, PH_MAT_USER, PH_MAT_USER_VUMAT
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_L4_Populate_Material

CONTAINS

  PURE SUBROUTINE PH_L4_Build_D_iso6(E, nu, D)
    REAL(wp), INTENT(IN) :: E, nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: lam, mu, c1, c2
    D = 0.0_wp
    IF (E <= 0.0_wp .OR. nu <= -1.0_wp .OR. nu >= 0.5_wp) RETURN
    lam = E * nu / MAX((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu), 1.0E-30_wp)
    mu = E / (2.0_wp * (1.0_wp + nu))
    c1 = lam + 2.0_wp * mu
    c2 = lam
    D(1, 1) = c1; D(2, 2) = c1; D(3, 3) = c1
    D(1, 2) = c2; D(1, 3) = c2; D(2, 1) = c2
    D(2, 3) = c2; D(3, 1) = c2; D(3, 2) = c2
    D(4, 4) = mu; D(5, 5) = mu; D(6, 6) = mu
  END SUBROUTINE PH_L4_Build_D_iso6

  SUBROUTINE PH_L4_Pack_Props_From_L3(md, ph_dom, idx, np, status)
    CLASS(MD_Mat_Desc), POINTER, INTENT(IN) :: md
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: ph_dom
    INTEGER(i4), INTENT(IN) :: idx
    INTEGER(i4), INTENT(INOUT) :: np
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    INTEGER(i4) :: npack

    ASSOCIATE(s => ph_dom%slot_pool(idx))
    SELECT TYPE (mdd => md)
    TYPE IS (MD_Mat_Elas_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
      IF (((.NOT. ALLOCATED(s%desc%props)) .OR. (np < 2_i4)) &
          .AND. (mdd%E > 0.0_wp)) THEN
        np = 2_i4
        IF (ALLOCATED(ph_dom%slot_pool(idx)%desc%props)) DEALLOCATE (ph_dom%slot_pool(idx)%desc%props)
        ALLOCATE (ph_dom%slot_pool(idx)%desc%props(np))
        s%desc%props(1) = mdd%E
        s%desc%props(2) = mdd%nu
      END IF
    TYPE IS (MD_Mat_Plast_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
      npack = 4_i4
      IF ((.NOT. ALLOCATED(s%desc%props)) .OR. (np < npack)) THEN
        np = npack
        IF (ALLOCATED(ph_dom%slot_pool(idx)%desc%props)) DEALLOCATE (ph_dom%slot_pool(idx)%desc%props)
        ALLOCATE (ph_dom%slot_pool(idx)%desc%props(np))
        s%desc%props(1) = mdd%E
        s%desc%props(2) = mdd%nu
        s%desc%props(3) = mdd%sigma_y
        s%desc%props(4) = mdd%H_iso
      END IF
    TYPE IS (MD_Mat_Geo_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Hyper_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Visco_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Creep_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Damage_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Comp_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Therm_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_Acou_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    TYPE IS (MD_Mat_User_Desc)
      s%desc%pop%mat_model_id = mdd%sub_type
    CLASS DEFAULT
      CONTINUE
    END SELECT
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_L4_Pack_Props_From_L3

  SUBROUTINE PH_L4_Alloc_State_ForFamily(ph_dom, idx, phm)
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: ph_dom
    INTEGER(i4), INTENT(IN) :: idx, phm
    INTEGER(i4) :: np
    REAL(wp) :: D6(6, 6)

    ASSOCIATE(s => ph_dom%slot_pool(idx))
    IF (ALLOCATED(ph_dom%slot_pool(idx)%state%comp%C_tan)) &
      DEALLOCATE (ph_dom%slot_pool(idx)%state%comp%C_tan)
    IF (ALLOCATED(ph_dom%slot_pool(idx)%state%comp%stress)) &
      DEALLOCATE (ph_dom%slot_pool(idx)%state%comp%stress)
    IF (ALLOCATED(ph_dom%slot_pool(idx)%state%evo%stateVars)) &
      DEALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars)
    IF (ALLOCATED(ph_dom%slot_pool(idx)%state%evo%stateVars_n)) &
      DEALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars_n)

    SELECT CASE (phm)
    CASE (PH_MAT_ELASTIC)
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%C_tan(6, 6))
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%stress(6))
      s%state%comp%stress = 0.0_wp
      np = 0_i4
      IF (ALLOCATED(s%desc%props)) np = SIZE(s%desc%props)
      IF (np >= 2_i4) THEN
        CALL PH_L4_Build_D_iso6(s%desc%props(1), s%desc%props(2), D6)
        s%state%comp%C_tan(:, :) = D6(:, :)
      ELSE
        s%state%comp%C_tan = 0.0_wp
      END IF

    CASE (PH_MAT_ELASTO_PLASTIC)
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%stress(6))
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%C_tan(6, 6))
      s%state%comp%stress = 0.0_wp
      np = 0_i4
      IF (ALLOCATED(s%desc%props)) np = SIZE(s%desc%props)
      IF (np >= 2_i4) THEN
        CALL PH_L4_Build_D_iso6(s%desc%props(1), s%desc%props(2), D6)
        s%state%comp%C_tan(:, :) = D6(:, :)
      ELSE
        s%state%comp%C_tan = 0.0_wp
      END IF
      ALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars(7))
      ALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars_n(7))
      s%state%evo%stateVars = 0.0_wp
      s%state%evo%stateVars_n = 0.0_wp

    CASE (PH_MAT_USER)
      ! User-defined material: allocate stress/tangent + stateVars from Desc
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%stress(6))
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%C_tan(6, 6))
      s%state%comp%stress = 0.0_wp
      s%state%comp%C_tan = 0.0_wp
      np = 0_i4
      IF (ALLOCATED(s%desc%props)) np = SIZE(s%desc%props)
      IF (np >= 2_i4) THEN
        CALL PH_L4_Build_D_iso6(s%desc%props(1), s%desc%props(2), D6)
        s%state%comp%C_tan(:, :) = D6(:, :)
      END IF
      ! Allocate stateVars: default 1, or read from Desc if available
      np = MAX(s%desc%pop%nStateV, 1_i4)
      ALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars(np))
      ALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars_n(np))
      s%state%evo%stateVars = 0.0_wp
      s%state%evo%stateVars_n = 0.0_wp

    CASE DEFAULT
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%stress(6))
      ALLOCATE (ph_dom%slot_pool(idx)%state%comp%C_tan(6, 6))
      s%state%comp%stress = 0.0_wp
      np = 0_i4
      IF (ALLOCATED(s%desc%props)) np = SIZE(s%desc%props)
      IF (np >= 2_i4) THEN
        CALL PH_L4_Build_D_iso6(s%desc%props(1), s%desc%props(2), D6)
        s%state%comp%C_tan(:, :) = D6(:, :)
      ELSE
        s%state%comp%C_tan = 0.0_wp
      END IF
      ALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars(8))
      ALLOCATE (ph_dom%slot_pool(idx)%state%evo%stateVars_n(8))
      s%state%evo%stateVars = 0.0_wp
      s%state%evo%stateVars_n = 0.0_wp
    END SELECT
    END ASSOCIATE
  END SUBROUTINE PH_L4_Alloc_State_ForFamily

  SUBROUTINE PH_L4_Populate_Material(ph_dom, mat_id, status, md_src)
    TYPE(PH_Mat_Domain), INTENT(INOUT) :: ph_dom
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_src

    CLASS(MD_Mat_Desc), POINTER :: md
    INTEGER(i4) :: idx, np, phm, mid_pop
    LOGICAL :: early_exit

    CALL init_error_status(status)

    CALL MD_Mat_Registry_Access_Desc(mat_id, md, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    IF (.NOT. ASSOCIATED(md)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_L4_Populate_Material]: null L3 descriptor"
      RETURN
    END IF

    CALL PH_Mat_AllocSlot_Idx(ph_dom, idx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    early_exit = .FALSE.
    ASSOCIATE(s => ph_dom%slot_pool(idx))
      s%desc%cfg%matId = mat_id
      s%desc%cfg%matModel = PH_MapL3MatTypeToL4(md%class_id)

      mid_pop = md%id
      IF (mid_pop <= 0_i4) mid_pop = md%pop%mat_model_id
      s%desc%pop%mat_model_id = mid_pop

      np = md%nProps
      IF (np <= 0_i4) np = md%pop%nProps
      IF (np > 0_i4 .AND. ALLOCATED(md%props)) THEN
        IF (ALLOCATED(ph_dom%slot_pool(idx)%desc%props)) &
          DEALLOCATE (ph_dom%slot_pool(idx)%desc%props)
        ALLOCATE (ph_dom%slot_pool(idx)%desc%props(np))
        s%desc%props(1:np) = md%props(1:np)
      END IF

      CALL PH_L4_Pack_Props_From_L3(md, ph_dom, idx, np, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        early_exit = .TRUE.
      END IF

      IF (.NOT. early_exit) THEN
        phm = s%desc%cfg%matModel
        CALL PH_L4_Alloc_State_ForFamily(ph_dom, idx, phm)
        s%active = .TRUE.
      END IF
    END ASSOCIATE

    IF (early_exit) RETURN

    ! Phase6 Track21: exercise IF_Mem_Algo scratch path (Populate-time, O(1)).
    BLOCK
      REAL(wp), POINTER :: scratch(:)
      INTEGER(i4) :: sc_id
      TYPE(ErrorStatusType) :: st_mem
      CALL IF_Mem_Algo_Scratch_Real1D(1_i4, 'PH_L4_Populate_anchor', scratch, sc_id, st_mem)
      IF (st_mem%status_code == IF_STATUS_OK) THEN
        CALL IF_Mem_Algo_Release_Real1D(sc_id, st_mem)
      END IF
    END BLOCK

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_L4_Populate_Material

END MODULE PH_L4_Populate

