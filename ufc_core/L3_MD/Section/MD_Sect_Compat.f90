!===============================================================================
! MODULE:  MD_Sect_Compat
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Impl
! BRIEF:   Compatibility check — P0 Check: Material x Section x Element
!          orthogonal sparse compatibility matrix.
!===============================================================================
MODULE MD_Sect_Compat
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Sect_Def, ONLY: SECT_FAM_SOLID, SECT_FAM_SHELL, SECT_FAM_BEAM, &
                          SECT_FAM_MEMBRANE, SECT_FAM_TRUSS, SECT_FAM_COHESIVE, &
                          SECT_FAM_GASKET, SECT_FAM_ACOUSTIC, SECT_FAM_CONNECTOR, &
                          SECT_FAM_COUNT
  USE MD_Elem_Family, ONLY: MD_MESH_ELEM_FAMILY_SOLID_3D, &
                            MD_MESH_ELEM_FAMILY_SOLID_2D, &
                            MD_MESH_ELEM_FAMILY_SHELL, &
                            MD_MESH_ELEM_FAMILY_MEMBRANE, &
                            MD_MESH_ELEM_FAMILY_BEAM, &
                            MD_MESH_ELEM_FAMILY_TRUSS, &
                            MD_MESH_ELEM_FAMILY_COHESIVE, &
                            MD_MESH_ELEM_FAMILY_INFINITE, &
                            MD_MESH_ELEM_FAMILY_ACOUSTIC, &
                            MD_MESH_ELEM_FAMILY_GASKET, &
                            MD_MESH_ELEM_FAMILY_CONN, &
                            MD_MESH_ELEM_FAMILY_MASS, &
                            MD_MESH_ELEM_FAMILY_COUNT
  IMPLICIT NONE
  PRIVATE

  !=====================================================================
  ! Material family indices (map mat_type ranges to 1..11)
  !=====================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_ELASTIC    = 1_i4   ! 101-103
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_PLASTIC    = 2_i4   ! 201-212
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_GEO        = 3_i4   ! 301-308
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_HYPER      = 4_i4   ! 401-411
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_VISCOELAS  = 5_i4   ! 501-504
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_VISCOPLAST = 6_i4   ! 601-608
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_DAMAGE     = 7_i4   ! 701-706
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_COMPOSITE  = 8_i4   ! 801-805
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_HEAT       = 9_i4   ! 901-903
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_ACOUSTIC   = 10_i4  ! 1001-1002
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAM_USER       = 11_i4  ! 1101-1102
  INTEGER(i4), PARAMETER, PUBLIC :: N_MAT_FAM          = 11_i4

  !=====================================================================
  ! Stress state enums (mirrors PH_MatBaseDefn but owned here for L3)
  !=====================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: SS_3D           = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_PLANE_STRESS = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_PLANE_STRAIN = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_AXISYMMETRIC = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_TRUSS        = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_SHELL        = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_ACOUSTIC     = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_BEAM         = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_MEMBRANE     = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_COHESIVE     = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_GASKET       = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: SS_UNDEFINED    = -1_i4

  !=====================================================================
  ! Level 1: Section x Material family compatibility  (9 x 11)
  ! Index: SECT_MAT_COMPAT(sect_fam, mat_fam)
  ! .TRUE. = combination is valid at the family level
  ! Fortran RESHAPE fills column-major: data grouped by mat_fam column,
  ! each column lists sect_fam 1..9 (Solid,Shell,Beam,Memb,Truss,Cohe,Gask,Acou,Conn)
  !=====================================================================
  LOGICAL, PARAMETER, PUBLIC :: SECT_MAT_COMPAT(SECT_FAM_COUNT, N_MAT_FAM) = RESHAPE( (/ &
  ! Col 1: Elastic  (So Sh Be Me Tr Co Ga Ac Cn)
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., &
  ! Col 2: Plastic
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 3: Geo
    .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 4: Hyper
    .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 5: VE
    .TRUE.,  .TRUE.,  .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 6: VP
    .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 7: Dmg
    .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., &
  ! Col 8: Comp
    .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 9: Heat
    .TRUE.,  .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 10: Acoustic
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., &
  ! Col 11: User
    .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .TRUE.,  .FALSE., .TRUE.  &
  /), SHAPE = (/ SECT_FAM_COUNT, N_MAT_FAM /))

  !=====================================================================
  ! Level 1: Section x Element family compatibility  (9 x 12)
  ! Index: SECT_ELEM_COMPAT(sect_fam, elem_fam)
  ! Fortran RESHAPE fills column-major: data grouped by elem_fam column,
  ! each column lists sect_fam 1..9 (Solid,Shell,Beam,Memb,Truss,Cohe,Gask,Acou,Conn)
  !=====================================================================
  LOGICAL, PARAMETER, PUBLIC :: SECT_ELEM_COMPAT(SECT_FAM_COUNT, MD_MESH_ELEM_FAMILY_COUNT) = RESHAPE( (/ &
  ! Col 1: Solid3D  (So Sh Be Me Tr Co Ga Ac Cn)
    .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 2: Solid2D
    .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 3: Shell
    .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 4: Membrane
    .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 5: Beam
    .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 6: Truss
    .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 7: Cohesive
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., .FALSE., &
  ! Col 8: Infinite
    .TRUE.,  .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., &
  ! Col 9: Acoustic
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., &
  ! Col 10: Gasket
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  .FALSE., .FALSE., &
  ! Col 11: Connector
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.,  &
  ! Col 12: Mass
    .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .FALSE., .TRUE.   &
  /), SHAPE = (/ SECT_FAM_COUNT, MD_MESH_ELEM_FAMILY_COUNT /))

  !=====================================================================
  ! Level 2: Model-level override registry
  !=====================================================================
  INTEGER(i4), PARAMETER :: MAX_MODEL_OVERRIDES = 32_i4

  TYPE :: ModelOverrideEntry
    INTEGER(i4) :: mat_type          ! specific material model ID (e.g. 212)
    INTEGER(i4) :: n_allowed_elem    ! number of allowed element families
    INTEGER(i4) :: allowed_elem(6)   ! up to 6 allowed element families
  END TYPE ModelOverrideEntry

  TYPE :: ModelOverrideRegistry
    INTEGER(i4) :: n_entries = 0_i4
    TYPE(ModelOverrideEntry) :: entries(MAX_MODEL_OVERRIDES)
  END TYPE ModelOverrideRegistry

  TYPE(ModelOverrideRegistry), SAVE :: g_model_overrides

  !=====================================================================
  ! Public API
  !=====================================================================
  PUBLIC :: MatTypeToFamily
  PUBLIC :: MD_SectCompat_Init
  PUBLIC :: MD_SectCompat_Check_Triple
  PUBLIC :: MD_SectCompat_Check_SectMat
  PUBLIC :: MD_SectCompat_Check_SectElem
  PUBLIC :: SectCompat_Get_StressState
  PUBLIC :: SectCompat_Register_Model_Override
  PUBLIC :: SectCompat_Check_Model_Override

CONTAINS

  !--------------------------------------------------------------------
  ! MatTypeToFamily: Convert material type constant to family index 1..11
  !--------------------------------------------------------------------
  PURE FUNCTION MatTypeToFamily(mat_type) RESULT(fam)
    INTEGER(i4), INTENT(IN) :: mat_type
    INTEGER(i4) :: fam

    SELECT CASE (mat_type)
    CASE (101:199)
      fam = MAT_FAM_ELASTIC
    CASE (201:299)
      fam = MAT_FAM_PLASTIC
    CASE (301:399)
      fam = MAT_FAM_GEO
    CASE (401:499)
      fam = MAT_FAM_HYPER
    CASE (501:599)
      fam = MAT_FAM_VISCOELAS
    CASE (601:699)
      fam = MAT_FAM_VISCOPLAST
    CASE (701:799)
      fam = MAT_FAM_DAMAGE
    CASE (801:899)
      fam = MAT_FAM_COMPOSITE
    CASE (901:999)
      fam = MAT_FAM_HEAT
    CASE (1001:1099)
      fam = MAT_FAM_ACOUSTIC
    CASE (1101:1199)
      fam = MAT_FAM_USER
    CASE DEFAULT
      fam = 0_i4
    END SELECT
  END FUNCTION MatTypeToFamily

  !--------------------------------------------------------------------
  ! MD_SectCompat_Init: Register built-in model-level overrides
  !--------------------------------------------------------------------
  SUBROUTINE MD_SectCompat_Init()

    g_model_overrides%n_entries = 0_i4

    ! Crystal plasticity: Solid3D only
    CALL SectCompat_Register_Model_Override(212_i4, &
      (/ MD_MESH_ELEM_FAMILY_SOLID_3D, 0_i4, 0_i4, 0_i4, 0_i4, 0_i4 /), 1_i4)

    ! Hyperfoam: Solid3D only
    CALL SectCompat_Register_Model_Override(409_i4, &
      (/ MD_MESH_ELEM_FAMILY_SOLID_3D, 0_i4, 0_i4, 0_i4, 0_i4, 0_i4 /), 1_i4)

    ! CLT composite: Shell only
    CALL SectCompat_Register_Model_Override(801_i4, &
      (/ MD_MESH_ELEM_FAMILY_SHELL, 0_i4, 0_i4, 0_i4, 0_i4, 0_i4 /), 1_i4)

    ! Hashin damage composite: Shell only
    CALL SectCompat_Register_Model_Override(802_i4, &
      (/ MD_MESH_ELEM_FAMILY_SHELL, 0_i4, 0_i4, 0_i4, 0_i4, 0_i4 /), 1_i4)

  END SUBROUTINE MD_SectCompat_Init

  !--------------------------------------------------------------------
  ! MD_SectCompat_Check_SectMat: Check Section-Material family compat
  !   Returns .TRUE. if compatible
  !--------------------------------------------------------------------
  PURE FUNCTION MD_SectCompat_Check_SectMat(sect_fam, mat_fam) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: sect_fam, mat_fam
    LOGICAL :: ok

    ok = .FALSE.
    IF (sect_fam < 1_i4 .OR. sect_fam > SECT_FAM_COUNT) RETURN
    IF (mat_fam < 1_i4 .OR. mat_fam > N_MAT_FAM) RETURN
    ok = SECT_MAT_COMPAT(sect_fam, mat_fam)
  END FUNCTION MD_SectCompat_Check_SectMat

  !--------------------------------------------------------------------
  ! MD_SectCompat_Check_SectElem: Check Section-Element family compat
  !   Returns .TRUE. if compatible
  !--------------------------------------------------------------------
  PURE FUNCTION MD_SectCompat_Check_SectElem(sect_fam, elem_fam) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: sect_fam, elem_fam
    LOGICAL :: ok

    ok = .FALSE.
    IF (sect_fam < 1_i4 .OR. sect_fam > SECT_FAM_COUNT) RETURN
    IF (elem_fam < 1_i4 .OR. elem_fam > MD_MESH_ELEM_FAMILY_COUNT) RETURN
    ok = SECT_ELEM_COMPAT(sect_fam, elem_fam)
  END FUNCTION MD_SectCompat_Check_SectElem

  !--------------------------------------------------------------------
  ! MD_SectCompat_Check_Triple: Full (sect, mat, elem) family validation
  !   status = 0: OK
  !   status = 1: Section-Material incompatible
  !   status = 2: Section-Element incompatible
  !   status = 3: Both incompatible
  !   status = 4: Model-level override restricts this element family
  !   status = -1: Invalid family index
  !--------------------------------------------------------------------
  SUBROUTINE MD_SectCompat_Check_Triple(sect_fam, mat_fam, elem_fam, &
                                         status, mat_type)
    INTEGER(i4), INTENT(IN)  :: sect_fam
    INTEGER(i4), INTENT(IN)  :: mat_fam
    INTEGER(i4), INTENT(IN)  :: elem_fam
    INTEGER(i4), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: mat_type

    LOGICAL :: sm_ok, se_ok

    status = 0_i4

    IF (sect_fam < 1_i4 .OR. sect_fam > SECT_FAM_COUNT .OR. &
        mat_fam < 1_i4 .OR. mat_fam > N_MAT_FAM .OR. &
        elem_fam < 1_i4 .OR. elem_fam > MD_MESH_ELEM_FAMILY_COUNT) THEN
      status = -1_i4
      RETURN
    END IF

    sm_ok = SECT_MAT_COMPAT(sect_fam, mat_fam)
    se_ok = SECT_ELEM_COMPAT(sect_fam, elem_fam)

    IF (.NOT. sm_ok .AND. .NOT. se_ok) THEN
      status = 3_i4
      RETURN
    END IF
    IF (.NOT. sm_ok) THEN
      status = 1_i4
      RETURN
    END IF
    IF (.NOT. se_ok) THEN
      status = 2_i4
      RETURN
    END IF

    ! Level 2: model-level override check
    IF (PRESENT(mat_type)) THEN
      IF (.NOT. SectCompat_Check_Model_Override(mat_type, elem_fam)) THEN
        status = 4_i4
        RETURN
      END IF
    END IF

  END SUBROUTINE MD_SectCompat_Check_Triple

  !--------------------------------------------------------------------
  ! SectCompat_Get_StressState: Determine stress state from sect+elem
  !   Centralizes the ntens determination logic
  !--------------------------------------------------------------------
  PURE FUNCTION SectCompat_Get_StressState(sect_fam, elem_fam) RESULT(ss)
    INTEGER(i4), INTENT(IN) :: sect_fam, elem_fam
    INTEGER(i4) :: ss

    ss = SS_UNDEFINED

    SELECT CASE (sect_fam)
    CASE (1_i4)  ! SECT_FAM_SOLID
      SELECT CASE (elem_fam)
      CASE (MD_MESH_ELEM_FAMILY_SOLID_3D, MD_MESH_ELEM_FAMILY_INFINITE)
        ss = SS_3D
      CASE (MD_MESH_ELEM_FAMILY_SOLID_2D)
        ss = SS_PLANE_STRAIN   ! default; caller may refine to CPS/CAX
      END SELECT

    CASE (2_i4)  ! SECT_FAM_SHELL
      ss = SS_SHELL

    CASE (3_i4)  ! SECT_FAM_BEAM
      ss = SS_BEAM

    CASE (4_i4)  ! SECT_FAM_MEMBRANE
      ss = SS_MEMBRANE

    CASE (5_i4)  ! SECT_FAM_TRUSS
      ss = SS_TRUSS

    CASE (6_i4)  ! SECT_FAM_COHESIVE
      ss = SS_COHESIVE

    CASE (7_i4)  ! SECT_FAM_GASKET
      ss = SS_GASKET

    CASE (8_i4)  ! SECT_FAM_ACOUSTIC
      ss = SS_ACOUSTIC

    CASE (9_i4)  ! SECT_FAM_CONNECTOR
      ss = SS_UNDEFINED  ! connectors: stress state N/A
    END SELECT
  END FUNCTION SectCompat_Get_StressState

  !--------------------------------------------------------------------
  ! SectCompat_Register_Model_Override: Add a model-level restriction
  !--------------------------------------------------------------------
  SUBROUTINE SectCompat_Register_Model_Override(mat_type, allowed_elem, n_elem)
    INTEGER(i4), INTENT(IN) :: mat_type
    INTEGER(i4), INTENT(IN) :: allowed_elem(6)
    INTEGER(i4), INTENT(IN) :: n_elem

    INTEGER(i4) :: idx

    IF (g_model_overrides%n_entries >= MAX_MODEL_OVERRIDES) RETURN

    idx = g_model_overrides%n_entries + 1_i4
    g_model_overrides%entries(idx)%mat_type       = mat_type
    g_model_overrides%entries(idx)%n_allowed_elem  = n_elem
    g_model_overrides%entries(idx)%allowed_elem    = allowed_elem
    g_model_overrides%n_entries = idx
  END SUBROUTINE SectCompat_Register_Model_Override

  !--------------------------------------------------------------------
  ! SectCompat_Check_Model_Override: Check if a specific model has
  !   element family restrictions. Returns .TRUE. if allowed (or no
  !   override registered for this model).
  !--------------------------------------------------------------------
  FUNCTION SectCompat_Check_Model_Override(mat_type, elem_fam) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: mat_type, elem_fam
    LOGICAL :: ok
    INTEGER(i4) :: i, j

    ok = .TRUE.
    DO i = 1_i4, g_model_overrides%n_entries
      IF (g_model_overrides%entries(i)%mat_type == mat_type) THEN
        ok = .FALSE.
        DO j = 1_i4, g_model_overrides%entries(i)%n_allowed_elem
          IF (g_model_overrides%entries(i)%allowed_elem(j) == elem_fam) THEN
            ok = .TRUE.
            RETURN
          END IF
        END DO
        RETURN
      END IF
    END DO
  END FUNCTION SectCompat_Check_Model_Override

END MODULE MD_Sect_Compat
