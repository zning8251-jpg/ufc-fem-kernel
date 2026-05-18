!===============================================================================
! MODULE:  MD_LBC_Core
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Core
! BRIEF:   Legacy conversion, bidirectional mapping, amplitude helper.
!          Sync UF_ModelDef step%loadbc -> MD_LoadBC_Domain.
!===============================================================================
MODULE MD_LBC_Core
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
    USE MD_Amp_Mgr, ONLY: Amp_GetFactor
    USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
    USE MD_Model_Lib_Core, ONLY: UF_Model
    USE MD_Load_Def, ONLY: MD_Load_Dist_Desc => MD_Load_Dist_Desc
    USE MD_BC_Def, ONLY: MD_BC_Disp_Desc => MD_BC_Disp_Desc
    USE MD_Load_Mgr, ONLY: LOAD_CONCENTRAT, LOAD_DISTRIBUTE, LOAD_PRESSURE, &
                            LOAD_BODY_FORCE, LOAD_GRAVITY, LOAD_CENTRIFUGA, &
                            LOAD_CORIOLIS, LOAD_THERMAL, LOAD_EDGE_DISTR
    IMPLICIT NONE
    PRIVATE

    ! Invalid constant for LoadBC mapping
    INTEGER(i4), PARAMETER, PUBLIC :: MD_LOADBC_LDBC_INVALID = -1_i4

    ! Exported from merged MD_LoadBC_Map
    PUBLIC :: MD_LoadBC_ToLdbcLoadType
    PUBLIC :: MD_LdbcTo_LoadBCCoreLoadType

    ! Exported from merged MD_LoadBC_Sync
    PUBLIC :: MD_LoadBC_SyncFromLegacy
    PUBLIC :: UF_BCDef_To_MD_BC_Desc
    PUBLIC :: UF_CLoadDef_To_MD_Load_Desc
    PUBLIC :: UF_DLoadDef_To_MD_Load_Desc
    PUBLIC :: UF_BodyForceDef_To_MD_Load_Desc

    ! Amplitude helper (domain-first A(t); optional md_layer)
    PUBLIC :: md_lbc_amp_from_uf

CONTAINS

  !> A(t) for Load/BC: when **md_layer** present, pass **md_layer%amplitude** into Amp_GetFactor
  !> (aligned with L4 Bridge / L5 RT_Amp_FactorAt); else UF-only three-arg call.
  FUNCTION md_lbc_amp_from_uf(model_amps, amp_id, time, md_layer) RESULT(fac)
    TYPE(MD_Amp_Slot_Desc), ALLOCATABLE, INTENT(IN) :: model_amps(:)
    INTEGER(i4), INTENT(IN) :: amp_id
    REAL(wp), INTENT(IN) :: time
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    REAL(wp) :: fac

    IF (PRESENT(md_layer)) THEN
      fac = Amp_GetFactor(model_amps, amp_id, time, md_layer%amplitude)
    ELSE
      fac = Amp_GetFactor(model_amps, amp_id, time)
    END IF
  END FUNCTION md_lbc_amp_from_uf

  !=============================================================================
  ! Section: MD_LoadBC_Map (merged from MD_LoadBC_Map.f90)
  ! Purpose: Bidirectional mapping between MD_LBC load kind integers and
  !          MD_LBC_Domain load enumerations.
  !=============================================================================

  !> Map MD_LBC load constant -> MD_LBC_Domain load constant.
  INTEGER(i4) FUNCTION MD_LoadBC_ToLdbcLoadType(md_kind)
    INTEGER(i4), INTENT(IN) :: md_kind

    SELECT CASE (md_kind)
    CASE (LOAD_CONCENTRAT)
      MD_LoadBC_ToLdbcLoadType = 1  ! LOAD_CLOAD
    CASE (LOAD_DISTRIBUTE)
      MD_LoadBC_ToLdbcLoadType = 2  ! LOAD_DLOAD
    CASE (LOAD_PRESSURE)
      MD_LoadBC_ToLdbcLoadType = 3  ! LOAD_DSLOAD
    CASE (LOAD_BODY_FORCE)
      MD_LoadBC_ToLdbcLoadType = 4  ! LOAD_BODY_FORCE
    CASE (LOAD_GRAVITY)
      MD_LoadBC_ToLdbcLoadType = 5  ! LOAD_GRAVITY
    CASE (LOAD_CENTRIFUGA)
      MD_LoadBC_ToLdbcLoadType = 6  ! LOAD_CENTRIFUGAL
    CASE (LOAD_THERMAL)
      MD_LoadBC_ToLdbcLoadType = 7  ! LOAD_TEMPERATURE
    CASE (LOAD_EDGE_DISTR)
      MD_LoadBC_ToLdbcLoadType = 2  ! LOAD_DLOAD
    CASE (LOAD_CORIOLIS)
      MD_LoadBC_ToLdbcLoadType = -1  ! INVALID
    CASE DEFAULT
      MD_LoadBC_ToLdbcLoadType = -1  ! INVALID
    END SELECT
  END FUNCTION MD_LoadBC_ToLdbcLoadType

  !> Inverse: MD_LBC_Domain -> MD_LBC
  INTEGER(i4) FUNCTION MD_LdbcTo_LoadBCCoreLoadType(ldbc_kind)
    INTEGER(i4), INTENT(IN) :: ldbc_kind

    SELECT CASE (ldbc_kind)
    CASE (1)  ! LOAD_CLOAD
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_CONCENTRAT
    CASE (2)  ! LOAD_DLOAD
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_DISTRIBUTE
    CASE (3)  ! LOAD_DSLOAD
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_PRESSURE
    CASE (4)  ! LOAD_BODY_FORCE
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_BODY_FORCE
    CASE (5)  ! LOAD_GRAVITY
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_GRAVITY
    CASE (6)  ! LOAD_CENTRIFUGAL
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_CENTRIFUGA
    CASE (7)  ! LOAD_TEMPERATURE
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_THERMAL
    CASE (8)  ! LOAD_PRESSURE
      MD_LdbcTo_LoadBCCoreLoadType = LOAD_PRESSURE
    CASE DEFAULT
      MD_LdbcTo_LoadBCCoreLoadType = -1  ! INVALID
    END SELECT
  END FUNCTION MD_LdbcTo_LoadBCCoreLoadType

  !=============================================================================
  ! Section: MD_LoadBC_Sync (merged from MD_LoadBC_Sync.f90)
  ! Purpose: Legacy UF_ModelDef (step%loadbc) sync to MD_LoadBC_Domain.
  !=============================================================================

  !> @brief Sync UF_ModelDef (legacy nested) -> MD_L3_LayerContainer (index+flat)
  SUBROUTINE MD_LoadBC_SyncFromLegacy(model_def, md_layer, status)
    USE MD_Model_Lib_Core, ONLY: UF_ModelDef
    TYPE(UF_ModelDef),          INTENT(IN)    :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: n_steps, s, i, bc_id, load_id
    TYPE(MD_BC_Disp_Desc)   :: bc_desc
    TYPE(MD_Load_Dist_Desc) :: load_desc

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_Sync: md_layer not initialized"
      RETURN
    END IF

    n_steps = model_def%step_mgr%num_steps
    IF (n_steps <= 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Steps must already exist from MD_Step_SyncFromLegacy
    IF (md_layer%step%n_steps < n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_LoadBC_Sync: steps not synced; call MD_Step_SyncFromLegacy first"
      RETURN
    END IF

    ! Sync each step's loadbc -> Domain + step%load_ids/bc_ids
    DO s = 1, n_steps
      ! BCs
      IF (ALLOCATED(model_def%step_mgr%steps(s)%loadbc%bcs)) THEN
        DO i = 1, model_def%step_mgr%steps(s)%loadbc%num_bcs
          IF (i > SIZE(model_def%step_mgr%steps(s)%loadbc%bcs)) EXIT
          CALL UF_BCDef_To_MD_BC_Desc(model_def%step_mgr%steps(s)%loadbc%bcs(i), s, bc_desc, md_layer)
          bc_id = i
          load_id = 0
        END DO
      END IF

      ! CLOADs
      IF (ALLOCATED(model_def%step_mgr%steps(s)%loadbc%cloads)) THEN
        DO i = 1, model_def%step_mgr%steps(s)%loadbc%num_cloads
          IF (i > SIZE(model_def%step_mgr%steps(s)%loadbc%cloads)) EXIT
          bc_id = 0
          load_id = i
        END DO
      END IF

      ! DLOADs
      IF (ALLOCATED(model_def%step_mgr%steps(s)%loadbc%dloads)) THEN
        DO i = 1, model_def%step_mgr%steps(s)%loadbc%num_dloads
          IF (i > SIZE(model_def%step_mgr%steps(s)%loadbc%dloads)) EXIT
          bc_id = 0
          load_id = i
        END DO
      END IF

      ! Body forces
      IF (ALLOCATED(model_def%step_mgr%steps(s)%loadbc%bforces)) THEN
        DO i = 1, model_def%step_mgr%steps(s)%loadbc%num_bforces
          IF (i > SIZE(model_def%step_mgr%steps(s)%loadbc%bforces)) EXIT
          bc_id = 0
          load_id = i
        END DO
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_LoadBC_SyncFromLegacy

  !> Conversion helper: UF_BCDef -> MD_BC_Disp_Desc
  SUBROUTINE UF_BCDef_To_MD_BC_Desc(uf_bc, step_ref, desc, md_layer)
    TYPE(UF_BCDef),    INTENT(IN)  :: uf_bc
    INTEGER(i4),       INTENT(IN)  :: step_ref
    TYPE(MD_BC_Disp_Desc), INTENT(OUT) :: desc
    TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer

    desc%cfg%id = 0_i4
    desc%name = TRIM(uf_bc%name)
    desc%stepId = step_ref
    desc%nodeSet = TRIM(uf_bc%region_name)
    desc%dof = uf_bc%dof_first
    desc%magnitude = uf_bc%magnitude
    desc%ampName = TRIM(uf_bc%amplitude_name)
    desc%bcType = "DISPLACEMENT"
    desc%isFixed = .FALSE.
  END SUBROUTINE UF_BCDef_To_MD_BC_Desc

  !> Conversion helper: UF_CLoadDef -> MD_Load_Dist_Desc
  SUBROUTINE UF_CLoadDef_To_MD_Load_Desc(uf_cload, step_ref, desc, md_layer)
    TYPE(UF_CLoadDef),  INTENT(IN)  :: uf_cload
    INTEGER(i4),       INTENT(IN)  :: step_ref
    TYPE(MD_Load_Dist_Desc), INTENT(OUT) :: desc
    TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer

    desc%cfg%id = 0_i4
    desc%name = TRIM(uf_cload%name)
    desc%stepId = step_ref
    desc%loadType = "CLOAD"
    desc%target = TRIM(uf_cload%nset_name)
    desc%dof = uf_cload%dof
    desc%magnitude(1) = uf_cload%magnitude
    desc%ampName = TRIM(uf_cload%amplitude_name)
  END SUBROUTINE UF_CLoadDef_To_MD_Load_Desc

  !> Conversion helper: UF_DLoadDef -> MD_Load_Dist_Desc
  SUBROUTINE UF_DLoadDef_To_MD_Load_Desc(uf_dload, step_ref, desc, md_layer)
    TYPE(UF_DLoadDef),  INTENT(IN)  :: uf_dload
    INTEGER(i4),       INTENT(IN)  :: step_ref
    TYPE(MD_Load_Dist_Desc), INTENT(OUT) :: desc
    TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer

    desc%cfg%id = 0_i4
    desc%name = TRIM(uf_dload%name)
    desc%stepId = step_ref
    desc%loadType = "DLOAD"
    desc%target = TRIM(uf_dload%surface_name)
    desc%dof = 0_i4
    desc%magnitude(1) = uf_dload%magnitude
    desc%ampName = TRIM(uf_dload%amplitude_name)
  END SUBROUTINE UF_DLoadDef_To_MD_Load_Desc

  !> Conversion helper: UF_BodyForceDef -> MD_Load_Dist_Desc
  SUBROUTINE UF_BodyForceDef_To_MD_Load_Desc(uf_bforce, step_ref, desc, md_layer)
    TYPE(UF_BodyForceDef), INTENT(IN)  :: uf_bforce
    INTEGER(i4),          INTENT(IN)  :: step_ref
    TYPE(MD_Load_Dist_Desc), INTENT(OUT) :: desc
    TYPE(MD_L3_LayerContainer), INTENT(IN) :: md_layer

    desc%cfg%id = 0_i4
    desc%name = TRIM(uf_bforce%name)
    desc%stepId = step_ref
    desc%loadType = "BODY_FORCE"
    desc%target = TRIM(uf_bforce%elset_name)
    desc%dof = 0_i4
    desc%magnitude(1) = SQRT(SUM(uf_bforce%components(:)**2))
    IF (desc%magnitude(1) < 1.0e-12_wp) desc%magnitude(1) = 1.0_wp
    desc%ampName = TRIM(uf_bforce%amplitude_name)
  END SUBROUTINE UF_BodyForceDef_To_MD_Load_Desc

END MODULE MD_LBC_Core
