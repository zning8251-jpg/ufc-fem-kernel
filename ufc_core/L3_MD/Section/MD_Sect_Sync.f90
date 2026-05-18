!===============================================================================
! MODULE:  MD_Sect_Sync
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Sync
! BRIEF:   Sync legacy UF_ModelDef%section_db -> MD_Sect_Domain desc_array.
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Sect | Role:Sync | FuncSet:Sync | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Section/CONTRACT.md

MODULE MD_Sect_Sync
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Sect_Def,     ONLY: MD_Sect_Desc, MD_Sect_Add_Arg, &
                              SECT_SOLID_3D, SECT_SOLID_2D, SECT_ACOUSTIC_SOLID, &
                              SECT_SHELL, SECT_SHELL_COMPOSITE, SECT_SURFACE_SHELL, &
                              SECT_THERMAL_SHELL, SECT_ACOUSTIC_SHELL, &
                              SECT_BEAM_EULER, SECT_BEAM_TIMOSHENKO, SECT_BEAM_GENERAL, &
                              SECT_MEMBRANE, SECT_TRUSS, SECT_COHESIVE, &
                              SECT_GASKET, SECT_GASKET_THIN, SECT_ACOUSTIC_SOLID, &
                              SECT_CONNECTOR
  USE MD_Sect_Domain,  ONLY: MD_Sect_Domain
  USE MD_Sect_Lib,     ONLY: UF_SectionDef, SECTION_SOLID, &
                              SECTION_SHELL, SECTION_BEAM, SECTION_MEMBRANE, &
                              SECTION_TRUSS, SECTION_COHESIVE, SECTION_GASKET, &
                              SECTION_CONNECTOR, SECTION_ACOUSTIC
  USE MD_L3_Layer,     ONLY: MD_L3_LayerContainer
  USE MD_Model_Lib_Core,    ONLY: UF_ModelDef
  USE MD_Sect_Mgr,     ONLY: UF_Section_Init, UF_Section_AddSection
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Section_SyncFromLegacy
  PUBLIC :: MD_Section_PopulateLegacyFromDomain

CONTAINS

  !---------------------------------------------------------------------------
  ! FUNCTION:  MapSectionType
  ! PHASE:     P1
  ! PURPOSE:   Map legacy section_type integer to MD_Sect_Desc section_type
  !---------------------------------------------------------------------------
  FUNCTION MapSectionType(legacy_type) RESULT(sect_type)
    INTEGER(i4), INTENT(IN) :: legacy_type
    INTEGER(i4)             :: sect_type

    SELECT CASE (legacy_type)
    CASE (SECTION_SOLID)
      sect_type = SECT_SOLID_3D
    CASE (SECTION_SHELL)
      sect_type = SECT_SHELL
    CASE (SECTION_BEAM)
      sect_type = SECT_BEAM_EULER
    CASE (SECTION_MEMBRANE)
      sect_type = SECT_MEMBRANE
    CASE (SECTION_TRUSS)
      sect_type = SECT_TRUSS
    CASE DEFAULT
      sect_type = MAX(1_i4, MIN(legacy_type, 30_i4))
    END SELECT
  END FUNCTION MapSectionType

  !---------------------------------------------------------------------------
  ! Map MD_SectDef canonical SECT_* code -> legacy UF SECTION_* for Mgr cache
  !---------------------------------------------------------------------------
  PURE FUNCTION MdSectType_To_UFSectionType(md_ty) RESULT(uf_ty)
    INTEGER(i4), INTENT(IN) :: md_ty
    INTEGER(i4)             :: uf_ty

    SELECT CASE (md_ty)
    CASE (SECT_SOLID_3D, SECT_SOLID_2D)
      uf_ty = SECTION_SOLID
    CASE (SECT_SHELL, SECT_SHELL_COMPOSITE, SECT_SURFACE_SHELL, &
          SECT_THERMAL_SHELL, SECT_ACOUSTIC_SHELL)
      uf_ty = SECTION_SHELL
    CASE (SECT_BEAM_EULER, SECT_BEAM_TIMOSHENKO, SECT_BEAM_GENERAL)
      uf_ty = SECTION_BEAM
    CASE (SECT_MEMBRANE)
      uf_ty = SECTION_MEMBRANE
    CASE (SECT_TRUSS)
      uf_ty = SECTION_TRUSS
    CASE (SECT_COHESIVE)
      uf_ty = SECTION_COHESIVE
    CASE (SECT_GASKET, SECT_GASKET_THIN)
      uf_ty = SECTION_GASKET
    CASE (SECT_ACOUSTIC_SOLID)
      uf_ty = SECTION_ACOUSTIC
    CASE (SECT_CONNECTOR)
      uf_ty = SECTION_CONNECTOR
    CASE DEFAULT
      uf_ty = SECTION_SOLID
    END SELECT
  END FUNCTION MdSectType_To_UFSectionType

  !---------------------------------------------------------------------------
  ! SUBROUTINE: UF_SectionDef_To_MD_Sect_Desc
  ! PHASE:      P1
  ! PURPOSE:    Convert UF_SectionDef (legacy) to MD_Sect_Desc (flat)
  !---------------------------------------------------------------------------
  SUBROUTINE UF_SectionDef_To_MD_Sect_Desc(legacy_def, mat_ref, sect_desc)
    TYPE(UF_SectionDef), INTENT(IN)  :: legacy_def
    INTEGER(i4),         INTENT(IN)  :: mat_ref
    TYPE(MD_Sect_Desc),   INTENT(OUT) :: sect_desc

    INTEGER(i4) :: lt

    lt = legacy_def%section_type

    sect_desc%section_name = TRIM(legacy_def%name)
    sect_desc%section_id = legacy_def%id
    IF (sect_desc%section_id <= 0) sect_desc%section_id = 0_i4
    sect_desc%section_type = MapSectionType(lt)
    sect_desc%mat_id = mat_ref

    IF (lt == SECTION_SHELL) THEN
      sect_desc%thickness = legacy_def%shell_thickness
    ELSE IF (lt == SECTION_MEMBRANE) THEN
      sect_desc%thickness = legacy_def%membrane_thickness
    ELSE
      sect_desc%thickness = legacy_def%thickness
    END IF

    IF (lt == SECTION_TRUSS) THEN
      sect_desc%area = legacy_def%truss_area
    ELSE IF (lt == SECTION_BEAM) THEN
      sect_desc%area = legacy_def%area
    ELSE
      sect_desc%area = 1.0_wp
    END IF
    IF (sect_desc%area <= 1.0e-12_wp) sect_desc%area = 1.0_wp

    sect_desc%integ_npts = legacy_def%num_integration_points
    IF (sect_desc%integ_npts <= 0) sect_desc%integ_npts = 5_i4
    sect_desc%orientation = 0.0_wp
    sect_desc%nlayer = 1_i4
    sect_desc%valid = .TRUE.
  END SUBROUTINE UF_SectionDef_To_MD_Sect_Desc

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Section_SyncFromLegacy
  ! PHASE:      P1
  ! PURPOSE:    Sync UF_ModelDef%section_db (legacy) -> md_layer%desc%section
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Section_SyncFromLegacy(model_def, md_layer, status)
    TYPE(UF_ModelDef),          INTENT(IN)    :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4)       :: i, nsec, mat_ref
    TYPE(MD_Sect_Desc) :: sect_desc
    TYPE(MD_Sect_Add_Arg) :: add_arg

    CALL init_error_status(status)
    IF (.NOT. md_layer%state%is_initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_SectionSync: md_layer not initialized"
      RETURN
    END IF

    nsec = model_def%section_db%num_sections
    IF (nsec <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (.NOT. ALLOCATED(model_def%section_db%sections)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    DO i = 1, MIN(nsec, SIZE(model_def%section_db%sections))
      mat_ref = 0_i4
      IF (model_def%section_db%sections(i)%material_id > 0) THEN
        mat_ref = md_layer%desc%material%GetById(model_def%section_db%sections(i)%material_id)
      END IF
      IF (mat_ref <= 0 .AND. LEN_TRIM(model_def%section_db%sections(i)%material_name) > 0) THEN
        BLOCK
          INTEGER(i4) :: mid_l
          LOGICAL :: got_l
          TYPE(ErrorStatusType) :: st_l
          CALL md_layer%desc%material%GetByName(TRIM(model_def%section_db%sections(i)%material_name), &
               mid_l, got_l, st_l)
          IF (got_l) mat_ref = mid_l
        END BLOCK
      END IF

      CALL UF_SectionDef_To_MD_Sect_Desc(model_def%section_db%sections(i), mat_ref, sect_desc)
      add_arg%desc = sect_desc
      CALL init_error_status(add_arg%status)
      CALL md_layer%desc%section%Add(add_arg)
      status = add_arg%status
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Section_SyncFromLegacy

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Section_PopulateLegacyFromDomain
  ! PHASE:      P1
  ! PURPOSE:    Populate MD_Sect global sections from Domain (for L4 UEL/UMAT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Section_PopulateLegacyFromDomain(md_layer, status)
    TYPE(MD_L3_LayerContainer), INTENT(IN)  :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT) :: status

    INTEGER(i4) :: i, nsec, reg_id
    REAL(wp)    :: props(10)

    CALL init_error_status(status)
    IF (.NOT. md_layer%state%is_initialized .OR. &
        md_layer%desc%section%n_sections <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    nsec = md_layer%desc%section%n_sections
    IF (.NOT. ALLOCATED(md_layer%desc%section%desc_array)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    CALL UF_Section_Init()
    props = 0.0_wp

    DO i = 1, nsec
      props(1) = md_layer%desc%section%desc_array(i)%thickness
      props(2) = 0.0_wp
      CALL UF_Section_AddSection( &
        MdSectType_To_UFSectionType(md_layer%desc%section%desc_array(i)%section_type), &
        props, 2_i4, &
        name=TRIM(md_layer%desc%section%desc_array(i)%section_name), &
        section_id=reg_id)
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Section_PopulateLegacyFromDomain

END MODULE MD_Sect_Sync
