!======================================================================
! MODULE:  MD_Int_Def
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Def
! BRIEF:   Core type definitions for Interaction domain.
!          Four-type pattern: Desc / Ctx / State / Algo.
!          Contact pairs, surface interactions, friction models,
!          domain-layer property types, and legacy Ctrl types.
! STATUS:  FOUR-TYPE-REFACTORED
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! PUBLIC: Four core types
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_Desc
  PUBLIC :: MD_Int_Ctx
  PUBLIC :: MD_Int_State
  PUBLIC :: MD_Int_Algo
  !--- P2 auxiliary nested types (Depth 2 cap) ---
  PUBLIC :: MD_Int_Cfg_Id_Desc
  PUBLIC :: MD_Int_Cfg_Container_Desc
  PUBLIC :: MD_Int_Cfg_API_Desc
  PUBLIC :: MD_Int_Itr_Whitelist_State
  PUBLIC :: MD_Int_Itr_PerPoint_State
  PUBLIC :: MD_Int_Stp_Penalty_Algo
  PUBLIC :: MD_Int_Stp_Conv_Algo
  PUBLIC :: MD_Int_Stp_FricDamp_Algo
  PUBLIC :: MD_Int_Lcl_IO_Ctx
  PUBLIC :: MD_Int_Lcl_Work_Ctx

  !--------------------------------------------------------------------
  ! PUBLIC: Helper Desc types (contact pair / surface / friction)
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_Pair_Desc
  PUBLIC :: MD_Int_SurfInt_Desc
  PUBLIC :: MD_Int_FricModel_Desc

  !--------------------------------------------------------------------
  ! PUBLIC: Core-API entry types (used by MD_Int_Core)
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_SurfEntry_Desc
  PUBLIC :: MD_Int_PairEntry_Desc

  !--------------------------------------------------------------------
  ! PUBLIC: Domain-layer types (friction/cohesion/damping/property/pair)
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_Fric_Algo
  PUBLIC :: MD_Int_Cohesion_Desc
  PUBLIC :: MD_Int_Damping_Algo
  PUBLIC :: MD_Int_Property_Desc
  PUBLIC :: MD_Int_PairDef_Desc
  PUBLIC :: MD_Int_Union_Ctx

  !--------------------------------------------------------------------
  ! PUBLIC: Legacy Ctrl types (MD_Int_Mgr / MD_Base_Def)
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_SurfRef_Desc
  PUBLIC :: MD_Int_CtrlPair_Desc
  PUBLIC :: MD_Int_Ctrl_Ctx

  !--------------------------------------------------------------------
  ! PUBLIC: Procedures
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_IsValidPair
  PUBLIC :: MD_Int_IsValidSurfInt
  PUBLIC :: MD_Int_IsValidFric
  PUBLIC :: MD_Int_InitDesc
  PUBLIC :: MD_Int_AddPair
  PUBLIC :: MD_Int_CtrlInit
  PUBLIC :: MD_Int_CtrlFree
  PUBLIC :: MD_Int_CtrlAddPair
  PUBLIC :: MD_Int_CtrlAddProp

  !--------------------------------------------------------------------
  ! Constants: Contact type enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CONTACT_S2S  = 1_i4  ! Surface-to-Surface
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CONTACT_P2S  = 2_i4  ! Point-to-Surface
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CONTACT_E2E  = 3_i4  ! Edge-to-Edge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CONTACT_SELF = 4_i4  ! Self-Contact

  !--------------------------------------------------------------------
  ! Constants: Friction model enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FRIC_COULOMB = 1_i4  ! Coulomb friction
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FRIC_VISCOUS = 2_i4  ! Viscous friction
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FRIC_PENALTY = 3_i4  ! Penalty friction

  !--------------------------------------------------------------------
  ! Constants: Algorithm enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ALGO_PENALTY     = 1_i4  ! Penalty method
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ALGO_LAGRANGE    = 2_i4  ! Lagrange multiplier
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ALGO_AUG_LAGR    = 3_i4  ! Augmented Lagrange

  !--------------------------------------------------------------------
  ! Constants: Formulation enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FORM_SURFACE = 1_i4  ! Surface-to-surface
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FORM_NODE    = 2_i4  ! Node-to-surface
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FORM_GENERAL = 3_i4  ! General contact

  !--------------------------------------------------------------------
  ! Constants: Contact state enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_STATE_OPEN    = 0_i4  ! Open (separated)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_STATE_CLOSED  = 1_i4  ! Closed (in contact)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_STATE_SLIDING = 2_i4  ! Sliding (friction)

  !--------------------------------------------------------------------
  ! Constants: Capacity limits
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_PAIRS        = 100_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_INTERACTIONS = 100_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_FRIC_MODELS  = 50_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_SURFACES     = 200_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_PAIR_ENTRIES = 200_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_CTRL_PAIRS   = 200_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_CTRL_PROPS   = 100_i4


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_SurfEntry_Desc
  ! KIND: Desc
  ! DESC: Surface entry for Core-API registration
  !--------------------------------------------------------------------
  TYPE :: MD_Int_SurfEntry_Desc
    INTEGER(i4)       :: id           = 0_i4           ! [in] Surface ID
    CHARACTER(LEN=64) :: name         = ""             ! [in] Surface name
    INTEGER(i4)       :: surface_type = 0_i4           ! [in] Surface type enum
    LOGICAL           :: valid        = .FALSE.        ! [out] Validity flag
  END TYPE MD_Int_SurfEntry_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_PairEntry_Desc
  ! KIND: Desc
  ! DESC: Pair entry for Core-API registration
  !--------------------------------------------------------------------
  TYPE :: MD_Int_PairEntry_Desc
    INTEGER(i4) :: pair_id      = 0_i4                 ! [in] Pair ID
    INTEGER(i4) :: master_id    = 0_i4                 ! [in] Master surface ID
    INTEGER(i4) :: slave_id     = 0_i4                 ! [in] Slave surface ID
    REAL(wp)    :: mu_friction  = 0.0_wp               ! [in] Friction coefficient
    LOGICAL     :: valid        = .FALSE.              ! [out] Validity flag
  END TYPE MD_Int_PairEntry_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Fric_Algo
  ! KIND: Algo
  ! DESC: Friction algorithm parameters
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Fric_Algo
    REAL(wp)    :: mu_static    = 0.0_wp               ! [in] Static friction coeff
    REAL(wp)    :: mu_kinetic   = 0.0_wp               ! [in] Kinetic friction coeff
    REAL(wp)    :: decay_coeff  = 0.0_wp               ! [in] Exponential decay coeff
    INTEGER(i4) :: model        = MD_INT_FRIC_COULOMB  ! [in] Friction model enum
  END TYPE MD_Int_Fric_Algo


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Cohesion_Desc
  ! KIND: Desc
  ! DESC: Cohesive zone descriptor
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Cohesion_Desc
    REAL(wp) :: max_stress  = 0.0_wp                   ! [in] Maximum cohesive stress
    REAL(wp) :: max_disp    = 0.0_wp                   ! [in] Maximum separation disp
    REAL(wp) :: energy      = 0.0_wp                   ! [in] Fracture energy
    LOGICAL  :: is_active   = .FALSE.                  ! [in] Active flag
  END TYPE MD_Int_Cohesion_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Damping_Algo
  ! KIND: Algo
  ! DESC: Contact damping algorithm parameters
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Damping_Algo
    REAL(wp) :: viscous_coeff  = 0.0_wp                ! [in] Viscous damping coeff
    REAL(wp) :: critical_ratio = 0.0_wp                ! [in] Critical damping ratio
    LOGICAL  :: is_active      = .FALSE.               ! [in] Active flag
  END TYPE MD_Int_Damping_Algo


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Property_Desc
  ! KIND: Desc
  ! DESC: Contact property definition (overclosure, stiffness, friction)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Property_Desc
    CHARACTER(LEN=64) :: name              = ""        ! [in] Property name
    INTEGER(i4)       :: id                = 0_i4      ! [in] Property ID
    CHARACTER(LEN=32) :: overclosure       = "HARD"    ! [in] HARD/SOFT/EXPONENTIAL
    REAL(wp)          :: clearance          = 0.0_wp    ! [in] Initial clearance
    REAL(wp)          :: stiffness_scale    = 1.0_wp    ! [in] Stiffness scale factor
    REAL(wp)          :: penalty_stiffness  = 1.0e6_wp  ! [in] Penalty stiffness
    TYPE(MD_Int_Fric_Algo) :: friction                 ! [in] Friction parameters
  END TYPE MD_Int_Property_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_PairDef_Desc
  ! KIND: Desc
  ! DESC: Contact pair definition for domain-layer (MD_Cont_Mgr)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_PairDef_Desc
    INTEGER(i4)       :: pair_id             = 0_i4               ! [in] Pair ID
    CHARACTER(LEN=64) :: master_surface      = ""                 ! [in] Master surface name
    CHARACTER(LEN=64) :: slave_surface       = ""                 ! [in] Slave surface name
    CHARACTER(LEN=64) :: prop_name           = ""                 ! [in] Property name ref
    INTEGER(i4)       :: formulation         = MD_INT_FORM_SURFACE ! [in] Formulation enum
    REAL(wp)          :: adjust              = 0.0_wp             ! [in] Adjust tolerance
    LOGICAL           :: active_in_all_steps = .TRUE.             ! [in] Active-all flag
    INTEGER(i4)       :: step_ref            = 0_i4               ! [in] Step reference
    LOGICAL           :: small_sliding       = .FALSE.            ! [in] Small sliding flag
    INTEGER(i4), ALLOCATABLE :: step_refs(:)                      ! [in] Multi-step refs
  END TYPE MD_Int_PairDef_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Union_Ctx
  ! KIND: Ctx
  ! DESC: Union container for domain-layer interaction data
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Union_Ctx
    TYPE(MD_Int_PairDef_Desc), ALLOCATABLE :: contact_pairs(:)   ! [inout] Pair array
    INTEGER(i4)                            :: n_pairs = 0_i4     ! [inout] Count
  END TYPE MD_Int_Union_Ctx


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_SurfRef_Desc
  ! KIND: Desc
  ! DESC: Legacy surface reference (Ctrl subsystem)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_SurfRef_Desc
    CHARACTER(LEN=64) :: name = ""                                ! [in] Surface name
  END TYPE MD_Int_SurfRef_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_CtrlPair_Desc
  ! KIND: Desc
  ! DESC: Legacy contact pair for Ctrl subsystem
  !--------------------------------------------------------------------
  TYPE :: MD_Int_CtrlPair_Desc
    INTEGER(i4)              :: id            = 0_i4              ! [in] Pair ID
    CHARACTER(LEN=64)        :: name          = ""                ! [in] Pair name
    TYPE(MD_Int_SurfRef_Desc) :: masterSurface                    ! [in] Master surface ref
    TYPE(MD_Int_SurfRef_Desc) :: slaveSurface                     ! [in] Slave surface ref
    CHARACTER(LEN=64)        :: propertyName  = ""                ! [in] Property name
    LOGICAL                  :: small_sliding = .FALSE.           ! [in] Small sliding flag
    INTEGER(i4)              :: stepId        = 0_i4              ! [in] Step ID
  END TYPE MD_Int_CtrlPair_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Ctrl_Ctx
  ! KIND: Ctx
  ! DESC: Legacy contact controller context (MD_Int_Mgr)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Ctrl_Ctx
    INTEGER(i4)                :: nPairs      = 0_i4                        ! [inout] Pair count
    TYPE(MD_Int_CtrlPair_Desc) :: pairs(MD_INT_MAX_CTRL_PAIRS)              ! [inout] Pair array
    INTEGER(i4)                :: nProperties = 0_i4                        ! [inout] Property count
    TYPE(MD_Int_Property_Desc) :: properties(MD_INT_MAX_CTRL_PROPS)         ! [inout] Property array
  END TYPE MD_Int_Ctrl_Ctx


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Pair_Desc
  ! KIND: Desc
  ! DESC: Contact pair helper type
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Pair_Desc
    CHARACTER(LEN=64) :: pair_name      = ""                      ! [in] Pair name
    INTEGER(i4)       :: pair_id        = 0_i4                    ! [in] Pair ID
    CHARACTER(LEN=64) :: slave_surface  = ""                      ! [in] Slave surface
    CHARACTER(LEN=64) :: master_surface = ""                      ! [in] Master surface
    INTEGER(i4)       :: contact_type   = MD_INT_CONTACT_S2S      ! [in] Contact type enum
    LOGICAL           :: is_active      = .TRUE.                  ! [in] Active flag
  END TYPE MD_Int_Pair_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_SurfInt_Desc
  ! KIND: Desc
  ! DESC: Surface interaction descriptor (normal + tangent behavior)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_SurfInt_Desc
    CHARACTER(LEN=64) :: interaction_name = ""                    ! [in] Interaction name
    INTEGER(i4)       :: interaction_id   = 0_i4                  ! [in] Interaction ID
    CHARACTER(LEN=64) :: paired_surfaces  = ""                    ! [in] Paired surface name
    CHARACTER(LEN=32) :: normal_behavior  = "HARD"                ! [in] Normal behavior
    REAL(wp)          :: normal_stiffness = 0.0_wp                ! [in] Normal stiffness
    CHARACTER(LEN=32) :: tangent_behavior = "FRICTIONLESS"        ! [in] Tangent behavior
    REAL(wp)          :: tangent_stiffness = 0.0_wp               ! [in] Tangent stiffness
  END TYPE MD_Int_SurfInt_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_FricModel_Desc
  ! KIND: Desc
  ! DESC: Friction model descriptor
  !--------------------------------------------------------------------
  TYPE :: MD_Int_FricModel_Desc
    CHARACTER(LEN=64) :: friction_name   = ""                     ! [in] Friction name
    INTEGER(i4)       :: friction_id     = 0_i4                   ! [in] Friction ID
    INTEGER(i4)       :: model_type      = MD_INT_FRIC_COULOMB    ! [in] Model type enum
    REAL(wp)          :: static_coeff    = 0.3_wp                 ! [in] Static friction coeff
    REAL(wp)          :: kinetic_coeff   = 0.2_wp                 ! [in] Kinetic friction coeff
    REAL(wp)          :: stick_slip_ratio = 1.0_wp                ! [in] Stick-slip ratio
    REAL(wp)          :: damping_coeff   = 0.0_wp                 ! [in] Damping coefficient
  END TYPE MD_Int_FricModel_Desc


  !--------------------------------------------------------------------
  ! AUXILIARY DESC TYPES (Depth 2 cap — nested auxiliary types)
  !--------------------------------------------------------------------

  TYPE :: MD_Int_Cfg_Id_Desc
    CHARACTER(LEN=64) :: interaction_name = ""                    ! [in] Interaction name
    INTEGER(i4)       :: interaction_id   = 0_i4                  ! [in] Interaction ID
    INTEGER(i4)       :: contact_type     = MD_INT_CONTACT_S2S    ! [in] Contact type enum
    CHARACTER(LEN=64) :: slave_surface    = ""                    ! [in] Slave surface name
    CHARACTER(LEN=64) :: master_surface   = ""                    ! [in] Master surface name
  END TYPE MD_Int_Cfg_Id_Desc

  TYPE :: MD_Int_Cfg_Container_Desc
    INTEGER(i4) :: num_contact_pairs = 0_i4                       ! [inout] Pair count
    TYPE(MD_Int_Pair_Desc), ALLOCATABLE :: contact_pairs(:)       ! [inout] Pair array
    INTEGER(i4) :: num_surface_interactions = 0_i4                ! [inout] Interaction count
    TYPE(MD_Int_SurfInt_Desc), ALLOCATABLE :: surface_interactions(:) ! [inout] Interaction array
    INTEGER(i4) :: num_friction_models = 0_i4                     ! [inout] Model count
    TYPE(MD_Int_FricModel_Desc), ALLOCATABLE :: friction_models(:) ! [inout] Model array
  END TYPE MD_Int_Cfg_Container_Desc

  TYPE :: MD_Int_Cfg_API_Desc
    INTEGER(i4) :: n_surfaces = 0_i4                              ! [inout] Surface count
    TYPE(MD_Int_SurfEntry_Desc) :: surfaces(MD_INT_MAX_SURFACES)  ! [inout] Surface entries
    INTEGER(i4) :: n_pairs = 0_i4                                 ! [inout] Pair count (v2)
    TYPE(MD_Int_PairEntry_Desc) :: pairs(MD_INT_MAX_PAIR_ENTRIES) ! [inout] Pair entries
  END TYPE MD_Int_Cfg_API_Desc

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Desc
  ! KIND: Desc
  ! DESC: Interaction domain descriptor (cold data, write-once).
  !       Holds contact pairs, surface interactions, friction models,
  !       and Core-API surface/pair arrays.
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Desc
    TYPE(MD_Int_Cfg_Id_Desc)        :: cfg_id
    TYPE(MD_Int_Cfg_Container_Desc) :: cfg_container
    TYPE(MD_Int_Cfg_API_Desc)       :: cfg_api
    CHARACTER(LEN=32) :: output_format = "ODB"                    ! [in] Output format
  END TYPE MD_Int_Desc


  !--------------------------------------------------------------------
  ! AUXILIARY STATE TYPES (Depth 2 cap — nested auxiliary types)
  !--------------------------------------------------------------------

  TYPE :: MD_Int_Itr_Whitelist_State
    REAL(wp)    :: contact_pressure    = 0.0_wp                  ! [inout] WHITE-LIST 1/3
    REAL(wp)    :: slip_distance       = 0.0_wp                  ! [inout] WHITE-LIST 2/3
    INTEGER(i4) :: total_contact_points = 0_i4                   ! [inout] WHITE-LIST 3/3
  END TYPE MD_Int_Itr_Whitelist_State

  TYPE :: MD_Int_Itr_PerPoint_State
    REAL(wp), ALLOCATABLE :: normal_stress(:)                     ! [inout] Normal stress
    REAL(wp), ALLOCATABLE :: tangent_stress(:)                    ! [inout] Tangent stress
    REAL(wp), ALLOCATABLE :: slip_rate(:)                         ! [inout] Slip rate
  END TYPE MD_Int_Itr_PerPoint_State

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_State
  ! KIND: State
  ! DESC: Interaction runtime state (hot data, writeback whitelist)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_State
    LOGICAL     :: is_active           = .TRUE.                   ! [inout] Active flag
    INTEGER(i4) :: contact_status      = 0_i4                    ! [inout] 0=open,1=closed,2=sliding
    REAL(wp)    :: contact_area        = 0.0_wp                  ! [inout] Contact area
    TYPE(MD_Int_Itr_Whitelist_State)  :: itr_whitelist
    TYPE(MD_Int_Itr_PerPoint_State)   :: itr_perpoint
    TYPE(ErrorStatusType) :: status                               ! [out] Error status
  END TYPE MD_Int_State


  !--------------------------------------------------------------------
  ! AUXILIARY ALGO TYPES (Depth 2 cap — nested auxiliary types)
  !--------------------------------------------------------------------

  TYPE :: MD_Int_Stp_Penalty_Algo
    LOGICAL     :: use_penalty          = .TRUE.                  ! [in] Use penalty method
    REAL(wp)    :: penalty_stiffness    = 1.0e6_wp                ! [in] Penalty stiffness
  END TYPE MD_Int_Stp_Penalty_Algo

  TYPE :: MD_Int_Stp_Conv_Algo
    REAL(wp)    :: convergence_tolerance = 1.0e-4_wp              ! [in] Convergence tol
  END TYPE MD_Int_Stp_Conv_Algo

  TYPE :: MD_Int_Stp_FricDamp_Algo
    LOGICAL     :: use_friction         = .TRUE.                  ! [in] Enable friction
    LOGICAL     :: use_damping          = .FALSE.                 ! [in] Enable damping
    REAL(wp)    :: damping_factor       = 0.1_wp                  ! [in] Damping factor
  END TYPE MD_Int_Stp_FricDamp_Algo

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Algo
  ! KIND: Algo
  ! DESC: Interaction algorithm parameters (tunable, frozen after parse)
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Algo
    INTEGER(i4) :: algorithm_type       = MD_INT_ALGO_PENALTY     ! [in] Algorithm enum
    TYPE(MD_Int_Stp_Penalty_Algo)  :: stp_penalty
    TYPE(MD_Int_Stp_Conv_Algo)     :: stp_conv
    TYPE(MD_Int_Stp_FricDamp_Algo) :: stp_fricdamp
  END TYPE MD_Int_Algo


  !--------------------------------------------------------------------
  ! AUXILIARY CTX TYPES (Depth 2 cap — nested auxiliary types)
  !--------------------------------------------------------------------

  TYPE :: MD_Int_Lcl_IO_Ctx
    INTEGER(i4)       :: contact_ctx_id  = 0_i4                   ! [in] Context ID
    CHARACTER(LEN=256) :: contact_dir    = "./"                   ! [in] Working directory
    INTEGER(i4)       :: result_unit     = 0_i4                   ! [inout] Result file unit
    CHARACTER(LEN=256) :: result_filename = ""                    ! [in] Result filename
  END TYPE MD_Int_Lcl_IO_Ctx

  TYPE :: MD_Int_Lcl_Work_Ctx
    REAL(wp), ALLOCATABLE :: work_array(:,:)                      ! [inout] Work array
  END TYPE MD_Int_Lcl_Work_Ctx

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Ctx
  ! KIND: Ctx
  ! DESC: Interaction execution context
  !--------------------------------------------------------------------
  TYPE :: MD_Int_Ctx
    TYPE(MD_Int_Lcl_IO_Ctx)  :: lcl_io
    TYPE(MD_Int_Lcl_Work_Ctx) :: lcl_work
  END TYPE MD_Int_Ctx

CONTAINS

  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_IsValidPair
  ! PHASE:      P0
  ! PURPOSE:    Validate a contact pair descriptor
  !--------------------------------------------------------------------
  LOGICAL FUNCTION MD_Int_IsValidPair(pair) RESULT(valid)
    TYPE(MD_Int_Pair_Desc), INTENT(IN) :: pair                    ! [in] Pair to validate

    valid = .FALSE.

    ! Check pair name is not empty
    IF (LEN_TRIM(pair%pair_name) == 0) RETURN

    ! Check surface names are not empty
    IF (LEN_TRIM(pair%slave_surface) == 0 .OR. &
        LEN_TRIM(pair%master_surface) == 0) RETURN

    ! Check contact type is valid (1..4)
    IF (pair%contact_type < 1_i4 .OR. pair%contact_type > 4_i4) RETURN

    ! Check slave /= master
    IF (TRIM(pair%slave_surface) == TRIM(pair%master_surface)) RETURN

    valid = .TRUE.
  END FUNCTION MD_Int_IsValidPair


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_IsValidSurfInt
  ! PHASE:      P0
  ! PURPOSE:    Validate a surface interaction descriptor
  !--------------------------------------------------------------------
  LOGICAL FUNCTION MD_Int_IsValidSurfInt(interaction) RESULT(valid)
    TYPE(MD_Int_SurfInt_Desc), INTENT(IN) :: interaction          ! [in] Interaction to validate

    valid = .FALSE.

    ! Check interaction name
    IF (LEN_TRIM(interaction%interaction_name) == 0) RETURN

    ! Check paired surfaces name
    IF (LEN_TRIM(interaction%paired_surfaces) == 0) RETURN

    ! Check normal behavior is set
    IF (LEN_TRIM(interaction%normal_behavior) == 0) RETURN

    ! If penalty method, stiffness must be positive
    IF (TRIM(interaction%normal_behavior) == "PENALTY" .AND. &
        interaction%normal_stiffness <= 0.0_wp) RETURN

    valid = .TRUE.
  END FUNCTION MD_Int_IsValidSurfInt


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_IsValidFric
  ! PHASE:      P0
  ! PURPOSE:    Validate a friction model descriptor
  !--------------------------------------------------------------------
  LOGICAL FUNCTION MD_Int_IsValidFric(friction) RESULT(valid)
    TYPE(MD_Int_FricModel_Desc), INTENT(IN) :: friction           ! [in] Friction to validate

    valid = .FALSE.

    ! Check friction name
    IF (LEN_TRIM(friction%friction_name) == 0) RETURN

    ! Check model type (1..3)
    IF (friction%model_type < 1_i4 .OR. friction%model_type > 3_i4) RETURN

    ! Check static friction coeff in [0, 1]
    IF (friction%static_coeff < 0.0_wp .OR. friction%static_coeff > 1.0_wp) RETURN
    IF (friction%kinetic_coeff < 0.0_wp .OR. friction%kinetic_coeff > 1.0_wp) RETURN

    ! Check stick-slip ratio >= 1.0
    IF (friction%stick_slip_ratio < 1.0_wp) RETURN

    ! Check damping coeff >= 0.0
    IF (friction%damping_coeff < 0.0_wp) RETURN

    valid = .TRUE.
  END FUNCTION MD_Int_IsValidFric


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_InitDesc
  ! PHASE:      P0
  ! PURPOSE:    Initialize an Interaction descriptor with containers
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_InitDesc(desc, name, contact_type, status)
    TYPE(MD_Int_Desc),    INTENT(INOUT) :: desc                   ! [inout] Descriptor
    CHARACTER(LEN=*),     INTENT(IN)    :: name                   ! [in]    Interaction name
    INTEGER(i4),          INTENT(IN)    :: contact_type           ! [in]    Contact type enum
    TYPE(ErrorStatusType), INTENT(OUT)  :: status                 ! [out]   Error status

    status%status_code = 0_i4

    ! Set basic info
    desc%cfg_id%interaction_name = TRIM(name)
    desc%cfg_id%contact_type     = contact_type
    desc%cfg_container%num_contact_pairs = 0_i4

    ! Allocate contact pair container
    IF (.NOT. ALLOCATED(desc%cfg_container%contact_pairs)) THEN
      ALLOCATE(desc%cfg_container%contact_pairs(MD_INT_MAX_PAIRS), STAT=status%status_code)
      IF (status%status_code /= 0) RETURN
    END IF

    ! Allocate surface interaction container
    IF (.NOT. ALLOCATED(desc%cfg_container%surface_interactions)) THEN
      ALLOCATE(desc%cfg_container%surface_interactions(MD_INT_MAX_INTERACTIONS), &
               STAT=status%status_code)
      IF (status%status_code /= 0) RETURN
    END IF

    ! Allocate friction model container
    IF (.NOT. ALLOCATED(desc%cfg_container%friction_models)) THEN
      ALLOCATE(desc%cfg_container%friction_models(MD_INT_MAX_FRIC_MODELS), &
               STAT=status%status_code)
      IF (status%status_code /= 0) RETURN
    END IF
  END SUBROUTINE MD_Int_InitDesc


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_AddPair
  ! PHASE:      P0
  ! PURPOSE:    Add a contact pair to an Interaction descriptor
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_AddPair(desc, pair_name, slave_surf, master_surf, &
                            contact_type, status)
    TYPE(MD_Int_Desc),    INTENT(INOUT) :: desc                   ! [inout] Descriptor
    CHARACTER(LEN=*),     INTENT(IN)    :: pair_name              ! [in]    Pair name
    CHARACTER(LEN=*),     INTENT(IN)    :: slave_surf             ! [in]    Slave surface
    CHARACTER(LEN=*),     INTENT(IN)    :: master_surf            ! [in]    Master surface
    INTEGER(i4),          INTENT(IN)    :: contact_type           ! [in]    Contact type
    TYPE(ErrorStatusType), INTENT(OUT)  :: status                 ! [out]   Error status

    TYPE(MD_Int_Pair_Desc) :: new_pair

    status%status_code = 0_i4

    ! Check capacity
    IF (desc%cfg_container%num_contact_pairs >= MD_INT_MAX_PAIRS) THEN
      status%status_code = 1_i4
      RETURN
    END IF

    ! Build new pair
    new_pair%pair_name      = TRIM(pair_name)
    new_pair%pair_id        = desc%cfg_container%num_contact_pairs + 1_i4
    new_pair%slave_surface  = TRIM(slave_surf)
    new_pair%master_surface = TRIM(master_surf)
    new_pair%contact_type   = contact_type

    ! Validate
    IF (.NOT. MD_Int_IsValidPair(new_pair)) THEN
      status%status_code = 1_i4
      RETURN
    END IF

    ! Append
    desc%cfg_container%num_contact_pairs = desc%cfg_container%num_contact_pairs + 1_i4
    desc%cfg_container%contact_pairs(desc%cfg_container%num_contact_pairs) = new_pair
  END SUBROUTINE MD_Int_AddPair


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_CtrlInit
  ! PHASE:      P0
  ! PURPOSE:    Initialize legacy Ctrl context
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_CtrlInit(ctrl)
    TYPE(MD_Int_Ctrl_Ctx), INTENT(INOUT) :: ctrl                  ! [inout] Ctrl context
    ctrl%nPairs      = 0_i4
    ctrl%nProperties = 0_i4
  END SUBROUTINE MD_Int_CtrlInit


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_CtrlFree
  ! PHASE:      P0
  ! PURPOSE:    Free / reset legacy Ctrl context
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_CtrlFree(ctrl)
    TYPE(MD_Int_Ctrl_Ctx), INTENT(INOUT) :: ctrl                  ! [inout] Ctrl context
    ctrl%nPairs      = 0_i4
    ctrl%nProperties = 0_i4
  END SUBROUTINE MD_Int_CtrlFree


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_CtrlAddPair
  ! PHASE:      P0
  ! PURPOSE:    Add a pair to legacy Ctrl context
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_CtrlAddPair(ctrl, pair)
    TYPE(MD_Int_Ctrl_Ctx),      INTENT(INOUT) :: ctrl             ! [inout] Ctrl context
    TYPE(MD_Int_CtrlPair_Desc), INTENT(IN)    :: pair             ! [in]    Pair to add
    IF (ctrl%nPairs >= MD_INT_MAX_CTRL_PAIRS) RETURN
    ctrl%nPairs = ctrl%nPairs + 1_i4
    ctrl%pairs(ctrl%nPairs) = pair
  END SUBROUTINE MD_Int_CtrlAddPair


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_CtrlAddProp
  ! PHASE:      P0
  ! PURPOSE:    Add a property to legacy Ctrl context
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_CtrlAddProp(ctrl, property)
    TYPE(MD_Int_Ctrl_Ctx),      INTENT(INOUT) :: ctrl             ! [inout] Ctrl context
    TYPE(MD_Int_Property_Desc), INTENT(IN)    :: property         ! [in]    Property to add
    IF (ctrl%nProperties >= MD_INT_MAX_CTRL_PROPS) RETURN
    ctrl%nProperties = ctrl%nProperties + 1_i4
    ctrl%properties(ctrl%nProperties) = property
  END SUBROUTINE MD_Int_CtrlAddProp

END MODULE MD_Int_Def
