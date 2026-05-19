!===============================================================================
! MODULE: MD_MatLibPH_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L4
! ROLE:   Brg — Material L3→L4 bridge
! BRIEF:  Bridge L3_MD material definitions to L4_PH constitutive evaluation.
! **W1**：**冷路径·LEGACY** L3→L4 桥；热路径真源为槽 **`desc%props`**（Populate **`PH_Mat_Desc`**）；**禁止**
!         热路径调用 **`MD_PH_RouteToConstitutive_Idx`**（详见下文 **D1**）；编排金线 **`PH_Mat_Core`** / **`RT_Mat_Brg`**。
!===============================================================================
!
! D1 Bridge role (vs UF_Brg_L4_TO_L3_MD):
!   [DEPRECATED 2026-04-18] MD_MatLibPH_Brg is now LEGACY for hot-path use.
!   Replacement: L4 hot-path reads slot_pool%desc%props (Populate-filled),
!                NOT via MD_MatLibPH_Brg::MD_PH_RouteToConstitutive_Idx.
!   Retained: Non-hot-path material routing (e.g., material parameter validation,
!             post-step processing). See ../docs/D1_Bridge_Migration.md (TBD).
!   Status:  Code retained for backward compatibility. New code should NOT call
!            MD_PH_RouteToConstitutive_Idx in hot path. Plan removal in v2027-Q1.
!   Governance freeze 2026-04-27: keep this module as a cold-path / registration
!            compatibility bridge only. New material computation paths must use
!            L4 Material slots plus L5 RT_Mat routing context.
!
!   - MD_MatLibPH_Brg: L3 -> L4 (now LEGACY for hot path, see above).
!   - UF_Brg_L4_TO_L3_MD (L4): L4 -> L3 fallback (also LEGACY after D2b fix).
!
! Theory chain:
!   Constitutive relations: sigma = f(epsilon, material_params) where sigma is
!   stress, epsilon is strain. Material types: Elastic (sigma = C:epsilon),
!   Plastic (sigma = f(epsilon, sigma_y, hardening)), Viscoelastic (sigma =
!   f(epsilon, epsilon_dot, time)), Hyperelastic (sigma = f(F, params)).
!   Ref: continuum mechanics, constitutive modeling. This module: bridge only,
!   routes mat_type to L4_PH evaluator.
!
! Logic chain:
!   L3_MD (caller needing constitutive eval) -> MD_MatLibPH_Brg
!   MD_MatLibPH_Brg -> MD_PH_GetMaterialType, MD_PH_RouteToConstitutive ->
!   MD_PH_Legacy_MatEval_Ctx (flat legacy bundle, cold path). Dependency: L3_MD -> L4_PH (bridge only).
!
! Computation chain:
!   mat_def%type -> mat_type (MAT_TYPE_ELASTIC/PLASTIC/VISCOELASTIC/HYPERELASTIC).
!   Route mat_type -> PH_Mat_*_Eval (L4_PH). Bridge forwards to L4_PH evaluator.
!
! Data chain:
!   L3: MD_Mat_Desc / MatPropertyDef / mat_idx -> mat_id (UFC numbering, 101..708).
!   L4: PH_Mat_Domain%slot_pool(mat_pt_idx) with family from desc%cfg%matModel
!   (PH_Mat_Desc_SyncDeprecatedFlat for flat matModel), desc%props(:),
!   state%stress, state%stateVars; constitutive dispatch uses mat_id via
!   PH_Mat_Reg_Get -> PH_Mat_Reg_Entry (category, integration_family, impl_status,
!   num_props, nStatev, props_schema after PH_Mat_Reg_InitAll).
!   This bridge: Input MD_MatDef_Type / desc-by-idx; Output MD_PH_Legacy_MatEval_Ctx
!   for L4 evaluators. No new Desc/Algo/Ctx/State types here - mapping only.
!
! Data structure:
!   No container path in this module (bridge). Input: MD_MatDef_Type (L3, material
!   definition). Output: MD_PH_Legacy_MatEval_Ctx (L4, legacy flat bundle for constitutive
!   eval). Bridge maps L3 material def to L4 material ctx; no four-category types
!   defined here.
!
! Three-step mapping:
! [D1-fix 2026-03-15] MD_MatLibPH_Brg L3->L4 Populate
! - GP MD_PH_RouteToConstitutive_Idx
! - Populate slot%desc%props Compute_Ctan
! - PH_BrgL3_Algo L4 L4->L3 Populate L3
! See module header.
! * MD_MatLibPH_Brg L3->L4 Populate L4 evaluator
! * PH_BrgL3_Algo L4->L3 Populate L3 props slot%desc%props
!
! Contents (A-Z):
!   Functions: MD_PH_GetMaterialType, MD_PH_GetMaterialType_FromDesc
!   Subroutines: MD_PH_RouteToConstitutive, MD_PH_RouteToConstitutive_Idx,
!     MD_PH_TransferModelDef
!
! Index-based API (Phase 4 entity_idx migration):
!   MD_PH_RouteToConstitutive_Idx(mat_idx, mat_ctx, status) - fetches desc from
!   Domain via MD_Mat_GetDesc_Idx, routes to constitutive evaluator.
!
! Notes:
!   L3_MD Brg: only USE L3_MD (MD_Base_Def, MD_Model_Ctx), L4_PH (PH_MatPLMEval); bundle MD_PH_Legacy_MatEval_Ctx.
!   No Amp Eval; no L5_RT USE in this module.
!   Logic/Computation chain diagrams: see MD_MatLib_PH_Brg_Chains.md
!
! Status: ACTIVE (LEGACY hot-path) | Last verified: 2026-04-26
!===============================================================================


MODULE MD_MatLibPH_Brg
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID, IF_STATUS_OK
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE MD_Base_Def, ONLY: MD_MatDef_Type
    USE MD_Mat_Def, ONLY: MD_Mat_Desc, MatProps
    USE MD_Mat_Lib, ONLY: MatPropertyDef
    USE PH_Mat_Defn_UMAT_Bridge, ONLY: PH_Mat_TypeToId, CAT_ELASTIC, CAT_PLAST, CAT_HYPERELAS, CAT_VISC, &
        PH_MAT_ID_INVALID, Defn_Invoke_UMAT, Defn_Invoke_UMAT_Arg
    USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
    USE PH_MatPLMEval, ONLY: UF_Plastic_Eval_Dispatch, UF_Plastic_Eval_Dispatch_Arg, &
         UF_Plastic_UMAT_Dispatch, UF_Plastic_UMAT_Dispatch_Arg, &
         UF_Plastic_UMAT_Wrapper, PH_MAT_UMAT_Plastic_Dispatch, UF_Plastic_GetLegacyID, &
         UF_Plastic_Legacy_VonMises, UF_Plastic_Legacy_Hill, UF_Plastic_Legacy_CamClay, &
         UF_Plastic_Leg_MohrCoulomb, UF_Plastic_Leg_ConcreteDmg, UF_Plastic_Leg_DruckerPrager, &
         UF_Plastic_Legacy_SoftRock, UF_Plastic_Legacy_Cap, UF_Plastic_Leg_CrushableFoam, &
         UF_Plastic_Legacy_CastIron, UF_Plastic_Leg_JohnsonCook, UF_Plastic_Legacy_Gurson, &
         UF_Plastic_Legacy_Chaboche, UF_Plastic_Leg_CompProgressive, UF_Plastic_Legacy_Foam3Stage, &
         UF_Plastic_Leg_Biomaterial, UF_Plastic_Legacy_Ceramic, UF_Plastic_Leg_ViscoplasticDmgEM, &
         UF_Plastic_Leg_Nanomaterial, UF_Plastic_Legacy_FGM, UF_Plastic_Leg_SmartMat, &
         UF_Plastic_Leg_ViscoelasticDmg, UF_Plastic_Leg_ThermoViscoplastic, &
         UF_Plastic_Leg_MultiscaleDmg, UF_Plastic_Leg_ThermoElectroMagneto, &
         UF_Plastic_Leg_PuckComp, UF_Plastic_Leg_Geotechnical, UF_Plastic_Leg_HashinComp
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! Material type constants
    !=============================================================================
    ! [D3-fix 2026-03-15] PH_Mat_Domain_Core.f90::PH_MAT_*
    !   ELASTIC=1, PLASTIC=2, HYPERELASTIC=3, VISCOELASTIC=4
    ! PH_Mat_Domain_Core.f90
    INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_ELASTIC = 1_i4       ! PH_MAT_ELASTIC
    INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_PLASTIC = 2_i4       ! PH_MAT_ELASTO_PLASTIC
    INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_HYPERELASTIC = 3_i4  ! PH_MAT_HYPERELASTIC D3 Hyper=3
    INTEGER(i4), PARAMETER, PUBLIC :: MAT_TYPE_VISCOELASTIC = 4_i4  ! PH_MAT_VISCOELASTIC D3 Visco=4

    ! Legacy flat bundle for Defn/UMAT shim (not nested PH_Mat_Ctx / PH_Mat_Slot).
    TYPE, PUBLIC :: MD_PH_Legacy_MatEval_Ctx
      INTEGER(i4) :: nStateVars = 0_i4
      REAL(wp), ALLOCATABLE :: props(:)
      REAL(wp), ALLOCATABLE :: strain(:)
      REAL(wp), ALLOCATABLE :: dStrain(:)
      REAL(wp), ALLOCATABLE :: stress(:)
      REAL(wp), ALLOCATABLE :: tangent(:, :)
      REAL(wp), ALLOCATABLE :: state_vars(:)
      LOGICAL :: success = .FALSE.
    END TYPE MD_PH_Legacy_MatEval_Ctx

    !=============================================================================
    ! PUBLIC PROCEDURES
    !=============================================================================
    PUBLIC :: MD_PH_RouteToConstitutive
    PUBLIC :: MD_PH_RouteToConstitutive_Idx
    PUBLIC :: MD_PH_GetMaterialType
    PUBLIC :: MD_PH_GetMaterialType_FromDesc
    ! Data transfer functions for Flow domain (L4_PH to L3_MD)
    PUBLIC :: MD_PH_TransferModelDef
    PUBLIC :: UF_Plastic_Eval_Dispatch, UF_Plastic_Eval_Dispatch_Arg
    PUBLIC :: UF_Plastic_UMAT_Dispatch, UF_Plastic_UMAT_Dispatch_Arg
    PUBLIC :: UF_Plastic_UMAT_Wrapper, PH_MAT_UMAT_Plastic_Dispatch, UF_Plastic_GetLegacyID
    PUBLIC :: UF_Plastic_Legacy_VonMises, UF_Plastic_Legacy_Hill, UF_Plastic_Legacy_CamClay
    PUBLIC :: UF_Plastic_Leg_MohrCoulomb, UF_Plastic_Leg_ConcreteDmg, UF_Plastic_Leg_DruckerPrager
    PUBLIC :: UF_Plastic_Legacy_SoftRock, UF_Plastic_Legacy_Cap, UF_Plastic_Leg_CrushableFoam
    PUBLIC :: UF_Plastic_Legacy_CastIron, UF_Plastic_Leg_JohnsonCook, UF_Plastic_Legacy_Gurson
    PUBLIC :: UF_Plastic_Legacy_Chaboche, UF_Plastic_Leg_CompProgressive, UF_Plastic_Legacy_Foam3Stage
    PUBLIC :: UF_Plastic_Leg_Biomaterial, UF_Plastic_Legacy_Ceramic, UF_Plastic_Leg_ViscoplasticDmgEM
    PUBLIC :: UF_Plastic_Leg_Nanomaterial, UF_Plastic_Legacy_FGM, UF_Plastic_Leg_SmartMat
    PUBLIC :: UF_Plastic_Leg_ViscoelasticDmg, UF_Plastic_Leg_ThermoViscoplastic
    PUBLIC :: UF_Plastic_Leg_MultiscaleDmg, UF_Plastic_Leg_ThermoElectroMagneto
    PUBLIC :: UF_Plastic_Leg_PuckComp, UF_Plastic_Leg_Geotechnical, UF_Plastic_Leg_HashinComp

CONTAINS

    !---------------------------------------------------------------------------
    ! FUNCTION: MD_PH_GetMaterialType
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Map material definition type string to mat_type constant
    !---------------------------------------------------------------------------
  FUNCTION MD_PH_GetMaterialType(mat_def) RESULT(mat_type)
    TYPE(MD_MatDef_Type), INTENT(IN) :: mat_def
    INTEGER(i4) :: mat_type

    ! Map material definition type string to material type constant
    SELECT CASE(TRIM(mat_def%type))
    CASE("ELASTIC", "ELASTIC_ISOTROPIC", "ELASTIC_ORTHOTROPIC")
      mat_type = MAT_TYPE_ELASTIC
    CASE("PLASTIC", "VON_MISES", "J2_PLASTICITY")
      mat_type = MAT_TYPE_PLASTIC
    CASE("VISCOELASTIC", "VISCO")
      mat_type = MAT_TYPE_VISCOELASTIC
    CASE("HYPERELASTIC", "NEO_HOOKEAN", "MOONEY_RIVLIN")
      mat_type = MAT_TYPE_HYPERELASTIC
    CASE DEFAULT
      mat_type = 0_i4  ! Unknown material type
    END SELECT

  END FUNCTION MD_PH_GetMaterialType

    !---------------------------------------------------------------------------
    ! FUNCTION: MD_PH_GetMaterialType_FromDesc
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Map MD_Mat_Desc materialType/behavior to mat_type constant
    !---------------------------------------------------------------------------
  FUNCTION MD_PH_GetMaterialType_FromDesc(desc) RESULT(mat_type)
    TYPE(MD_Mat_Desc), INTENT(IN) :: desc
    INTEGER(i4) :: mat_type
    CHARACTER(LEN=32) :: type_str

    ! W1 Step3: nested cfg first; DEPRECATED flat fallback (Populate / legacy)
    type_str = TRIM(desc%cfg%materialType)
    IF (LEN_TRIM(type_str) == 0) type_str = TRIM(desc%cfg%behavior)
    IF (LEN_TRIM(type_str) == 0) type_str = TRIM(desc%materialType)
    IF (LEN_TRIM(type_str) == 0) type_str = TRIM(desc%behavior)
    SELECT CASE(type_str)
    CASE("ELASTIC", "ELASTIC_ISOTROPIC", "ELASTIC_ORTHOTROPIC")
      mat_type = MAT_TYPE_ELASTIC
    CASE("PLASTIC", "VON_MISES", "J2_PLASTICITY")
      mat_type = MAT_TYPE_PLASTIC
    CASE("VISCOELASTIC", "VISCO")
      mat_type = MAT_TYPE_VISCOELASTIC
    CASE("HYPERELASTIC", "NEO_HOOKEAN", "MOONEY_RIVLIN")
      mat_type = MAT_TYPE_HYPERELASTIC
    CASE DEFAULT
      mat_type = 0_i4
    END SELECT

  END FUNCTION MD_PH_GetMaterialType_FromDesc

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_PH_RouteToConstitutive
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Route material to constitutive evaluator (Defn/UMAT)
    !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_RouteToConstitutive(mat_def, mat_ctx, status)
    TYPE(MD_MatDef_Type), INTENT(IN) :: mat_def
    TYPE(MD_PH_Legacy_MatEval_Ctx), INTENT(INOUT) :: mat_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: mat_type, mat_id
    TYPE(MatPropertyDef) :: mat_prop
    TYPE(ErrorStatusType) :: st
    TYPE(Defn_Invoke_UMAT_Arg) :: du
    REAL(wp) :: strain_in(6), stress_out(6), tangent_out(6,6)
    INTEGER(i4) :: i, j, ncopy

    IF (PRESENT(status)) CALL init_error_status(status)

    mat_type = MD_PH_GetMaterialType(mat_def)
    IF (mat_type == 0_i4) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_PH_RouteToConstitutive: Unknown material type"
      END IF
      RETURN
    END IF

    ! mat_type -> mat_id (MAT_TYPE_* -> Reg mat_id 101/201/303/401)
    mat_id = PH_MAT_ID_INVALID
    SELECT CASE(mat_type)
    CASE(MAT_TYPE_ELASTIC)
      mat_id = PH_Mat_TypeToId(CAT_ELASTIC, 1_i4)   ! Isotropic elastic -> 101
    CASE(MAT_TYPE_PLASTIC)
      mat_id = PH_Mat_TypeToId(CAT_PLAST, 1_i4)     ! J2 -> 201
    CASE(MAT_TYPE_HYPERELASTIC)
      mat_id = PH_Mat_TypeToId(CAT_HYPERELAS, 16_i4) ! Neo-Hookean -> 303
    CASE(MAT_TYPE_VISCOELASTIC)
      mat_id = PH_Mat_TypeToId(CAT_VISC, 1_i4)      ! Linear visco -> 401
    END SELECT

    IF (mat_id == PH_MAT_ID_INVALID) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "MD_PH_RouteToConstitutive: mat_id not registered"
      END IF
      RETURN
    END IF

    ! Build MatPropertyDef from mat_def / mat_ctx
    mat_prop%mat_id = mat_id
    mat_prop%num_state_vars = MAX(0_i4, mat_ctx%nStateVars)
    IF (ALLOCATED(mat_ctx%props) .AND. SIZE(mat_ctx%props) >= 1) THEN
      ncopy = MIN(50_i4, SIZE(mat_ctx%props))
      IF (.NOT. ALLOCATED(mat_prop%props)) ALLOCATE(mat_prop%props(ncopy))
      IF (SIZE(mat_prop%props) < ncopy) THEN
        IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
        ALLOCATE(mat_prop%props(ncopy))
      END IF
      mat_prop%props(1:ncopy) = mat_ctx%props(1:ncopy)
      mat_prop%num_props = ncopy
    ELSE IF (ALLOCATED(mat_def%props) .AND. SIZE(mat_def%props) >= 1) THEN
      ncopy = MIN(50_i4, SIZE(mat_def%props))
      IF (.NOT. ALLOCATED(mat_prop%props)) ALLOCATE(mat_prop%props(ncopy))
      IF (SIZE(mat_prop%props) < ncopy) THEN
        IF (ALLOCATED(mat_prop%props)) DEALLOCATE(mat_prop%props)
        ALLOCATE(mat_prop%props(ncopy))
      END IF
      mat_prop%props(1:ncopy) = mat_def%props(1:ncopy)
      mat_prop%num_props = ncopy
    ELSE
      mat_prop%num_props = 0_i4
    END IF

    ! Strain input: use strain or dStrain
    strain_in = 0.0_wp
    IF (ALLOCATED(mat_ctx%strain) .AND. SIZE(mat_ctx%strain) >= 6) THEN
      strain_in(1:6) = mat_ctx%strain(1:6)
    ELSE IF (ALLOCATED(mat_ctx%dStrain) .AND. SIZE(mat_ctx%dStrain) >= 6) THEN
      strain_in(1:6) = mat_ctx%dStrain(1:6)
    END IF

    ! Ensure stress/tangent allocated
    IF (.NOT. ALLOCATED(mat_ctx%stress)) ALLOCATE(mat_ctx%stress(6))
    IF (SIZE(mat_ctx%stress) < 6) THEN
      IF (ALLOCATED(mat_ctx%stress)) DEALLOCATE(mat_ctx%stress)
      ALLOCATE(mat_ctx%stress(6))
    END IF
    IF (.NOT. ALLOCATED(mat_ctx%tangent)) ALLOCATE(mat_ctx%tangent(6,6))
    IF (SIZE(mat_ctx%tangent,1) < 6 .OR. SIZE(mat_ctx%tangent,2) < 6) THEN
      IF (ALLOCATED(mat_ctx%tangent)) DEALLOCATE(mat_ctx%tangent)
      ALLOCATE(mat_ctx%tangent(6,6))
    END IF

    ! Call Defn/UMAT (INTF-001: Defn_Invoke_UMAT_Arg; statev not in stub Arg yet)
    du%mat_id = mat_id
    du%strain_in = strain_in
    du%want_tangent = .TRUE.
    IF (ALLOCATED(du%mat)) DEALLOCATE (du%mat)
    ALLOCATE (MatProps :: du%mat)
    du%mat%material_id = mat_id
    du%mat%nprops = mat_prop%num_props
    IF (mat_prop%num_props > 0_i4 .AND. ALLOCATED(mat_prop%props)) THEN
      ALLOCATE (du%mat%props(mat_prop%num_props))
      du%mat%props(1:mat_prop%num_props) = mat_prop%props(1:mat_prop%num_props)
    END IF

    CALL Defn_Invoke_UMAT(du)
    st = du%status
    stress_out = du%stress_out
    tangent_out = du%tangent_out
    IF (ALLOCATED(du%mat)) DEALLOCATE (du%mat)

    IF (PRESENT(status)) status = st
    IF (st%status_code /= IF_STATUS_OK) RETURN

    mat_ctx%stress(1:6) = stress_out(1:6)
    DO j = 1, 6
      DO i = 1, 6
        mat_ctx%tangent(i,j) = tangent_out(i,j)
      END DO
    END DO
    mat_ctx%success = .TRUE.

  END SUBROUTINE MD_PH_RouteToConstitutive

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_PH_RouteToConstitutive_Idx
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Route material to constitutive evaluator by entity index
    !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_RouteToConstitutive_Idx(mat_idx, mat_ctx, status)
    INTEGER(i4), INTENT(IN) :: mat_idx
    TYPE(MD_PH_Legacy_MatEval_Ctx), INTENT(INOUT) :: mat_ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Mat_GetDesc_Arg) :: arg
    TYPE(MD_MatDef_Type) :: mat_def
    INTEGER(i4) :: n

    CALL init_error_status(status)
    IF (.NOT. g_ufc_global%IsReady()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_PH_RouteToConstitutive_Idx: g_ufc_global not ready"
      RETURN
    END IF

    CALL MD_Mat_GetDesc_Idx(mat_idx, arg, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Convert MD_Mat_Desc to MD_MatDef_Type for existing RouteToConstitutive
    ! [D1-note] mat_def ALLOCATE Populate
    mat_def%name = arg%desc%name
    mat_def%type = TRIM(arg%desc%cfg%materialType)
    IF (LEN_TRIM(mat_def%type) == 0) mat_def%type = TRIM(arg%desc%cfg%behavior)
    IF (LEN_TRIM(mat_def%type) == 0) mat_def%type = TRIM(arg%desc%materialType)
    IF (LEN_TRIM(mat_def%type) == 0) mat_def%type = TRIM(arg%desc%behavior)
    mat_def%pop%nProps = arg%desc%pop%nProps
    IF (mat_def%pop%nProps <= 0) mat_def%pop%nProps = arg%desc%nProps
    n = 0
    IF (arg%desc%pop%nProps > 0) THEN
      n = arg%desc%pop%nProps
    ELSE IF (arg%desc%nProps > 0) THEN
      n = arg%desc%nProps
    END IF
    IF (n > 0 .AND. ALLOCATED(arg%desc%props)) THEN
      n = MIN(n, SIZE(arg%desc%props))
      IF (n > 0) THEN
        IF (ALLOCATED(mat_def%props)) DEALLOCATE(mat_def%props)
        ALLOCATE(mat_def%props(n))
        mat_def%props(1:n) = arg%desc%props(1:n)
      END IF
    END IF

    ! [D1-note] mat_ctx%props Populate ALLOCATE
    ! slot%desc%props Populate
    IF (.NOT. ALLOCATED(mat_ctx%props)) THEN
      IF (ALLOCATED(arg%desc%props) .AND. SIZE(arg%desc%props) > 0) THEN
        ALLOCATE(mat_ctx%props(SIZE(arg%desc%props)))
        mat_ctx%props = arg%desc%props
      END IF
    END IF

    CALL MD_PH_RouteToConstitutive(mat_def, mat_ctx, status)

  END SUBROUTINE MD_PH_RouteToConstitutive_Idx

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_PH_TransferModelDef
    ! PHASE:      P1 (温路径-数据映射)
    ! PURPOSE:    Transfer model definition from PH layer to MD layer
    !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_TransferModelDef(ph_model_ctx, md_model_ctx, status)
    ! Note: PH_Model_Ctx and MD_Model_Ctx types need to be defined or imported
    ! For now, using placeholder - actual implementation depends on context structures
    USE MD_Model_Mgr, ONLY: MD_Model_Ctx
    TYPE(MD_Model_Ctx), INTENT(INOUT) :: md_model_ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    ! TODO: Transfer model definition from PH layer to MD layer
    ! Example transfer logic:
    !   md_model_ctx%material_lib => ph_model_ctx%material_lib
    !   md_model_ctx%section_defs => ph_model_ctx%section_defs
    !   md_model_ctx%load_defs => ph_model_ctx%load_defs
    !   md_model_ctx%bc_defs => ph_model_ctx%bc_defs

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_PH_TransferModelDef
END MODULE MD_MatLibPH_Brg
