!===============================================================================
! MODULE:  MD_Model_Builder
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Impl (build pipeline)
! BRIEF:   P1 Build/Populate: Unified entry to build UF_ModelDef from Abaqus
!          INP file. Four-type interface: Desc/Algo/Ctx/State bundles.
!          Orchestrates parse -> sync -> assemble -> prepare pipeline.
!===============================================================================
MODULE MD_Model_Builder
  USE IF_Err_Brg,               ONLY: ErrorStatusType, init_error_status, &
                                       MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID
  USE IF_Prec_Core,             ONLY: wp, i4
  USE MD_KW_Abaqus,             ONLY: kw_parse_inp_file
  USE MD_Model_Lib_Core,             ONLY: UF_ModelDef, MD_MODEL_MODEL_DEFINED
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Step_Sync,             ONLY: MD_Step_SyncFromLegacy
  USE MD_Solv_Sync,             ONLY: MD_Solver_SyncFromStep
  USE MD_Amp_Mgr,               ONLY: MD_Amp_SyncFromLegacy
  USE MD_LoadBC_Sync,           ONLY: MD_LoadBC_SyncFromLegacy
  USE MD_Constr_Sync,           ONLY: MD_Constraint_SyncFromLegacy
  USE MD_Int_Sync,              ONLY: MD_Interaction_SyncFromLegacy
  USE MD_Mat_Sync,              ONLY: MD_Mat_SyncFromLegacy
  USE MD_Sect_Sync,          ONLY: MD_Section_SyncFromLegacy, &
                                       MD_Section_PopulateLegacyFromDomain
  USE MD_Mesh_Sync,             ONLY: MD_Mesh_SyncFromLegacy
  USE MD_Out_Sync,              ONLY: MD_Output_SyncFromLegacy
  USE MD_Part_Sync,             ONLY: MD_Part_SyncFromLegacy
  USE MD_Asm_Sync,              ONLY: MD_Assembly_SyncFromLegacy
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_build_model_from_inp
  PUBLIC :: MD_Model_Builder_Build
  PUBLIC :: MD_Model_Builder_Build_In, MD_Model_Builder_Build_Out
  PUBLIC :: MD_Model_Builder_Build_Desc, MD_Model_Builder_Build_Algo
  PUBLIC :: MD_Model_Builder_Build_Ctx, MD_Model_Builder_Build_State

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Builder_Desc
  ! KIND:  Desc
  ! DESC:  Builder descriptor (filename, model name)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Builder_Build_Desc
    CHARACTER(LEN=512) :: filename   = ""  ! INP file path
    CHARACTER(LEN=256) :: model_name = ""  ! model name (optional)
  END TYPE MD_Model_Builder_Build_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Builder_Algo
  ! KIND:  Algo
  ! DESC:  Algorithm parameters for build pipeline
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Builder_Build_Algo
    INTEGER(i4) :: parsing_method    = 1_i4    ! 1=Abaqus keyword, 2=XML
    LOGICAL     :: validate_input    = .TRUE.  ! validate input format
    LOGICAL     :: check_consistency = .TRUE.  ! check model consistency
  END TYPE MD_Model_Builder_Build_Algo


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Builder_Ctx
  ! KIND:  Ctx
  ! DESC:  Context for build pipeline execution
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Builder_Build_Ctx
    LOGICAL     :: verbose    = .FALSE.  ! verbose output flag
    LOGICAL     :: echo_input = .FALSE.  ! echo input content flag
    INTEGER(i4) :: log_level  = 0_i4     ! log level (0=silent,1=info,2=debug)
  END TYPE MD_Model_Builder_Build_Ctx


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Builder_State
  ! KIND:  State
  ! DESC:  Build pipeline state tracking
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Builder_Build_State
    LOGICAL     :: parse_successful = .FALSE.  ! parse success flag
    INTEGER(i4) :: num_parts    = 0_i4         ! parts parsed
    INTEGER(i4) :: num_elements = 0_i4         ! elements parsed
    INTEGER(i4) :: num_nodes    = 0_i4         ! nodes parsed
  END TYPE MD_Model_Builder_Build_State


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Builder_In_Arg
  ! KIND:  Arg
  ! DESC:  Input argument bundle for Build operation
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Builder_Build_In
    TYPE(MD_Model_Builder_Build_Desc)  :: desc   ! [in] build descriptor
    TYPE(MD_Model_Builder_Build_Algo)  :: algo   ! [in] algorithm params
    TYPE(MD_Model_Builder_Build_Ctx)   :: ctx    ! [in] build context
    TYPE(MD_Model_Builder_Build_State) :: state  ! [in] initial state
  END TYPE MD_Model_Builder_Build_In


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Builder_Out_Arg
  ! KIND:  Arg
  ! DESC:  Output argument bundle for Build operation
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Builder_Build_Out
    TYPE(UF_ModelDef)                 :: model   ! [out] built model
    TYPE(MD_Model_Builder_Build_State) :: state   ! [out] final state
    TYPE(ErrorStatusType)             :: status  ! [out] error status
  END TYPE MD_Model_Builder_Build_Out

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Builder_Build
  ! PHASE:      P1
  ! PURPOSE:    Build complete UF_ModelDef from INP file via structured interface
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Builder_Build(in, out)
    TYPE(MD_Model_Builder_Build_In), INTENT(IN)   :: in   ! [in] input bundle
    TYPE(MD_Model_Builder_Build_Out), INTENT(OUT)  :: out  ! [out] output bundle

    LOGICAL :: parse_ok
    LOGICAL :: be_verbose

    CALL init_error_status(out%status)

    ! Initialize model metadata
    IF (LEN_TRIM(in%desc%model_name) > 0) THEN
      CALL out%model%initialize(TRIM(in%desc%model_name))
    ELSE
      CALL out%model%initialize(TRIM(in%desc%filename))
    END IF
    out%model%input_file = TRIM(in%desc%filename)

    ! Parse INP via keyword system
    be_verbose = in%ctx%verbose
    CALL kw_parse_inp_file(in%desc%filename, out%model, parse_ok, be_verbose)
    IF (.NOT. parse_ok) THEN
      out%status%status_code = MD_MODEL_STATUS_INVALID
      out%status%message = "MD_Model_Builder_Build: Parse failed"
      out%state%parse_successful = .FALSE.
      RETURN
    END IF

    ! Sync legacy domains to md_layer (if global container ready)
    IF (g_ufc_global%IsReady()) THEN
      IF (g_ufc_global%md_layer%l3Frozen) THEN
        out%status%status_code = MD_MODEL_STATUS_INVALID
        out%status%message = "MD_Model_Builder_Build: L3 frozen; sync disallowed"
        RETURN
      END IF
      CALL MD_Step_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Solver_SyncFromStep(g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Amp_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_LoadBC_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Assembly_SyncFromLegacy(out%model%assembly, g_ufc_global%md_layer, &
                                      out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Constraint_SyncFromLegacy(g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Interaction_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Mat_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Section_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Section_PopulateLegacyFromDomain(g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Part_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      CALL MD_Output_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
    ELSE
      ! Partial sync: assembly only when md_layer initialized and not frozen
      IF (g_ufc_global%md_layer%initialized .AND. &
          (.NOT. g_ufc_global%md_layer%l3Frozen) .AND. &
          g_ufc_global%md_layer%assembly%initialized) THEN
        CALL MD_Assembly_SyncFromLegacy(out%model%assembly, g_ufc_global%md_layer, &
                                        out%status)
        IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
      END IF
    END IF

    ! Assemble global geometry
    CALL out%model%assembly%assemble(out%model%parts, out%model%num_parts)

    ! Sync mesh to md_layer
    IF (g_ufc_global%IsReady()) THEN
      CALL MD_Mesh_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
    ELSE IF (g_ufc_global%md_layer%initialized .AND. &
             (.NOT. g_ufc_global%md_layer%l3Frozen) .AND. &
             g_ufc_global%md_layer%mesh%initialized) THEN
      CALL MD_Mesh_SyncFromLegacy(out%model, g_ufc_global%md_layer, out%status)
      IF (out%status%status_code /= MD_MODEL_STATUS_OK) RETURN
    END IF

    ! Prepare analysis (DOF manager, equation numbering)
    CALL out%model%prepare_analysis()

    ! Update build state
    out%state%parse_successful = .TRUE.
    out%state%num_parts    = out%model%num_parts
    out%state%num_elements = out%model%assembly%total_elements
    out%state%num_nodes    = out%model%assembly%total_nodes

    out%status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Builder_Build


  !---------------------------------------------------------------------------
  ! SUBROUTINE: UF_build_model_from_inp
  ! PHASE:      P1
  ! PURPOSE:    Legacy interface - build model from INP file
  !---------------------------------------------------------------------------
  SUBROUTINE UF_build_model_from_inp(filename, model, ierr, verbose)
    CHARACTER(LEN=*), INTENT(IN)  :: filename  ! [in] INP file path
    TYPE(UF_ModelDef), INTENT(OUT) :: model    ! [out] built model
    INTEGER(i4), INTENT(OUT)      :: ierr      ! [out] error code (0=OK)
    LOGICAL, OPTIONAL, INTENT(IN) :: verbose   ! [in] verbose flag

    TYPE(MD_Model_Builder_Build_In)  :: in_struct
    TYPE(MD_Model_Builder_Build_Out) :: out_struct
    LOGICAL :: be_verbose

    ierr = 0
    be_verbose = .FALSE.
    IF (PRESENT(verbose)) be_verbose = verbose

    in_struct%desc%filename = TRIM(filename)
    in_struct%ctx%verbose = be_verbose

    CALL MD_Model_Builder_Build(in_struct, out_struct)

    model = out_struct%model
    IF (out_struct%status%status_code /= MD_MODEL_STATUS_OK) THEN
      ierr = -1
    END IF
  END SUBROUTINE UF_build_model_from_inp

END MODULE MD_Model_Builder
