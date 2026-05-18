!===============================================================================
! MODULE:  MD_Model_Def
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Def (type definition authority)
! BRIEF:   Model-level four-type definitions: Desc, Ctx, State, Algo.
!          L3 SSOT for model identity, build context, progress state, and
!          model-level strategy selection.
!
!          v2.2 — unified MD_Model_Desc combining metadata from MD_Model_Def
!          (lightweight) and MD_Model_Mgr (extended). Added auxiliary types
!          (Cfg_Init_Desc, Pop_Vld_Desc) with cfg%/pop% nesting per UFC four-type
!          convention.
!===============================================================================
MODULE MD_Model_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Constants: Analysis type enumerations
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_STATIC           = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_DYNAMIC_IMPLICIT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_DYNAMIC_EXPLICIT = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_EIGENVALUE       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_HEAT_TRANSFER    = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_COUPLED_TEMP     = 6_i4

  !=============================================================================
  ! Auxiliary types (for cfg%/pop% nesting)
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Cfg_Init_Desc
  ! KIND:  Cfg (cold, set-once during model initialization)
  ! DESC:  Model configuration metadata (frozen after parsing)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Cfg_Init_Desc
    INTEGER(i4) :: analysis_type = MD_MODEL_ANALYSIS_STATIC   ! analysis type code
    INTEGER(i4) :: sub_type      = 0                           ! model sub-type
    INTEGER(i4) :: property_flags = 0                          ! property control flags
  END TYPE MD_Model_Cfg_Init_Desc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Pop_Vld_Desc
  ! KIND:  Pop (set after L3→L4 population)
  ! DESC:  Descriptor population/validation metadata
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.  ! .TRUE. after successful population
  END TYPE MD_Model_Pop_Vld_Desc

  !=============================================================================
  ! Primary types
  !=============================================================================

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Desc
  ! KIND:  Desc (cold descriptor, immutable after parse)
  ! DESC:  Unified model descriptor — identity, topology summary, and
  !        sub-domain counts. Merged from lightweight (Def) and extended (Mgr)
  !        versions. Uses cfg%/pop% nested auxiliary types.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Desc
    !-- Nested auxiliary descriptors
    TYPE(MD_Model_Cfg_Init_Desc) :: cfg
    TYPE(MD_Model_Pop_Vld_Desc) :: pop

    !-- Model identity
    CHARACTER(LEN=256) :: model_name  = ""       ! model name identifier
    INTEGER(i4)        :: spatial_dim = 3         ! spatial dimension {2,3}

    !-- Sub-domain counts
    INTEGER(i4) :: n_parts        = 0             ! registered part count
    INTEGER(i4) :: n_steps        = 0             ! registered step count
    INTEGER(i4) :: n_materials    = 0             ! material count
    INTEGER(i4) :: n_sections     = 0             ! section count
    INTEGER(i4) :: n_loadbcs      = 0             ! load/BC count
    INTEGER(i4) :: n_amplitudes   = 0             ! amplitude count
    INTEGER(i4) :: n_interactions = 0             ! interaction count
    INTEGER(i4) :: n_outputs      = 0             ! output count

    !-- ID registries (fixed-length, for simple P0 tracking)
    INTEGER(i4) :: part_ids(256) = 0              ! part ID registry
    INTEGER(i4) :: step_ids(100) = 0              ! step ID registry
  CONTAINS
    PROCEDURE, PASS :: Init  => MD_Model_Desc_Init
    PROCEDURE, PASS :: Valid => MD_Model_Desc_Valid
    PROCEDURE, PASS :: Clean => MD_Model_Desc_Clean
  END TYPE MD_Model_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Ctx
  ! KIND:  Ctx (build-time context, transient during construction)
  ! DESC:  Construction context for model building pipeline
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Ctx
    INTEGER(i4)        :: parse_unit   = 0          ! active file unit during parse
    INTEGER(i4)        :: current_line = 0          ! current input line number
    CHARACTER(LEN=256) :: source_file  = ""         ! source input file path
    LOGICAL            :: echo_input   = .FALSE.    ! echo parsed input flag
    LOGICAL            :: strict_mode  = .TRUE.     ! strict validation mode
  END TYPE MD_Model_Ctx


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_State
  ! KIND:  State (warm, tracks build/validate progress)
  ! DESC:  Model lifecycle state tracking
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_State
    LOGICAL     :: parsed      = .FALSE.  ! input parsing completed
    LOGICAL     :: populated   = .FALSE.  ! data population completed
    LOGICAL     :: validated   = .FALSE.  ! validation passed
    INTEGER(i4) :: n_warnings  = 0        ! accumulated warning count
    INTEGER(i4) :: n_errors    = 0        ! accumulated error count
    INTEGER(i4) :: build_phase = 0        ! current build phase index
  END TYPE MD_Model_State


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Algo
  ! KIND:  Algo (strategy selection, cold after configuration)
  ! DESC:  Model-level algorithm/strategy configuration
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Algo
    INTEGER(i4) :: renumber_strategy = 0  ! node renumbering: 0=none,1=RCM,2=Metis
    INTEGER(i4) :: partition_method  = 0  ! domain decomp: 0=none,1=greedy,2=metis
    LOGICAL     :: auto_contact      = .FALSE.  ! auto-detect contact pairs
    LOGICAL     :: adaptive_mesh     = .FALSE.  ! adaptive mesh refinement
  END TYPE MD_Model_Algo

CONTAINS

  !=============================================================================
  ! MD_Model_Desc TBP implementations
  !=============================================================================

  SUBROUTINE MD_Model_Desc_Init(this)
    CLASS(MD_Model_Desc), INTENT(INOUT) :: this
    this%cfg%analysis_type  = MD_MODEL_ANALYSIS_STATIC
    this%cfg%sub_type       = 0
    this%cfg%property_flags = 0
    this%pop%is_valid       = .FALSE.
    this%model_name         = ""
    this%spatial_dim        = 3
    this%n_parts            = 0
    this%n_steps            = 0
    this%n_materials        = 0
    this%n_sections         = 0
    this%n_loadbcs          = 0
    this%n_amplitudes       = 0
    this%n_interactions     = 0
    this%n_outputs          = 0
    this%part_ids           = 0
    this%step_ids           = 0
  END SUBROUTINE MD_Model_Desc_Init

  SUBROUTINE MD_Model_Desc_Valid(this)
    CLASS(MD_Model_Desc), INTENT(INOUT) :: this
    this%pop%is_valid = .TRUE.
  END SUBROUTINE MD_Model_Desc_Valid

  SUBROUTINE MD_Model_Desc_Clean(this)
    CLASS(MD_Model_Desc), INTENT(INOUT) :: this
    this%cfg%analysis_type  = MD_MODEL_ANALYSIS_STATIC
    this%cfg%sub_type       = 0
    this%cfg%property_flags = 0
    this%pop%is_valid       = .FALSE.
    this%model_name         = ""
    this%spatial_dim        = 3
    this%n_parts            = 0
    this%n_steps            = 0
    this%n_materials        = 0
    this%n_sections         = 0
    this%n_loadbcs          = 0
    this%n_amplitudes       = 0
    this%n_interactions     = 0
    this%n_outputs          = 0
    this%part_ids           = 0
    this%step_ids           = 0
  END SUBROUTINE MD_Model_Desc_Clean

END MODULE MD_Model_Def
