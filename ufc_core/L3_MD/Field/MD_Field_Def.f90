!===============================================================================
! MODULE: MD_Field_Def
! LAYER:  L3_MD
! DOMAIN: Field
! ROLE:   Def — Desc+State+Ctx type definitions (no Algo)
! BRIEF:  Field variable registry types and semantic constants.
!===============================================================================
!
! Type catalogue (3-TYPE system, Algo clipped):
!   [Desc]  MD_FieldRegionRef — Region/set/entity-id reference for field scope
!   [Desc]  MD_FieldInitCond  — Initial condition descriptor
!   [Desc]  MD_FieldEntry     — Single field variable record
!   [Desc]  MD_Field_Desc     — Field variable registry (immutable after parse)
!   [State] MD_Field_State    — Field allocation and runtime status (warm)
!   [Ctx]   MD_Field_Ctx      — Transient workspace for field evaluation (hot)
!
! Constants (MD_FIELD_* canonical prefix):
!   MD_FIELD_USER/DISPLACEMENT/VELOCITY/..  — field type enum
!   MD_FIELD_ENTITY_NODE/ELEMENT/IP/..       — entity ownership enum
!   MD_FIELD_DIST_UNIFORM/TABLE/..           — distribution enum
!   MD_FIELD_REGION_ALL/NAME/RANGE/..        — region reference enum
!
! Clipping: Algo not needed — no algorithm selection at data layer.
!
! Status: FOUR-TYPE | AUTHORITY (L3 Field) | Last verified: 2026-04-28
!===============================================================================
MODULE MD_Field_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Field_Desc
  PUBLIC :: MD_FieldEntry
  PUBLIC :: MD_FieldRegionRef
  PUBLIC :: MD_FieldInitCond

  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_MAX      = 64
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_NAME_LEN = 32
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_REGION_NAME_LEN = 64
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_AMP_NAME_LEN    = 32

  ! Field type enum: model-level field category, not solver algorithm.
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_USER          = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_DISPLACEMENT  = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_VELOCITY      = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ACCELERATION  = 3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_TEMPERATURE   = 11
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_PORE_PRESSURE = 12
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_CONCENTRATION = 13
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ELECTRIC_POT  = 21
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_MAGNETIC_POT  = 22

  ! Entity ownership enum: where the field is defined.
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ENTITY_UNKNOWN = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ENTITY_NODE    = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ENTITY_ELEMENT = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ENTITY_IP      = 3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ENTITY_SURFACE = 4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_ENTITY_SET     = 5

  ! Distribution enum: how initial values are prescribed.
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_DIST_UNIFORM  = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_DIST_TABLE    = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_DIST_ANALYTIC = 3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_DIST_BY_SET   = 4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_DIST_BY_COORD = 5

  ! Region reference enum: how a field scope points to model entities.
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_REGION_ALL       = 0
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_REGION_NAME      = 1
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_REGION_RANGE     = 2
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_REGION_ID_LIST   = 3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_REGION_SET_NAME  = 4

  !-----------------------------------------------------------------------------
  ! [Desc] MD_FieldRegionRef — where a field or initial condition applies
  !-----------------------------------------------------------------------------
  TYPE :: MD_FieldRegionRef
    INTEGER(i4) :: region_kind  = MD_FIELD_REGION_ALL
    INTEGER(i4) :: entity_kind  = MD_FIELD_ENTITY_UNKNOWN
    CHARACTER(LEN=MD_FIELD_REGION_NAME_LEN) :: region_name = ""
    CHARACTER(LEN=MD_FIELD_REGION_NAME_LEN) :: set_name    = ""
    INTEGER(i4) :: entity_start = 0
    INTEGER(i4) :: entity_end   = 0
    INTEGER(i4) :: n_entity_ids = 0
    INTEGER(i4), ALLOCATABLE :: entity_ids(:)
  END TYPE MD_FieldRegionRef

  !-----------------------------------------------------------------------------
  ! [Desc] MD_FieldInitCond — scalar/vector/table-backed value prescription
  !-----------------------------------------------------------------------------
  TYPE :: MD_FieldInitCond
    INTEGER(i4) :: field_id          = 0
    INTEGER(i4) :: distribution_kind = MD_FIELD_DIST_UNIFORM
    TYPE(MD_FieldRegionRef) :: region
    INTEGER(i4) :: n_values = 0
    REAL(wp), ALLOCATABLE :: values(:)
    INTEGER(i4) :: table_id = 0
    CHARACTER(LEN=MD_FIELD_AMP_NAME_LEN) :: amplitude_name = ""
  END TYPE MD_FieldInitCond

  !-----------------------------------------------------------------------------
  ! [Desc] MD_FieldEntry — single field variable record
  !-----------------------------------------------------------------------------
  TYPE :: MD_FieldEntry
    INTEGER(i4)                      :: id                = 0
    CHARACTER(LEN=MD_FIELD_NAME_LEN) :: name              = ""
    INTEGER(i4)                      :: field_type        = MD_FIELD_USER
    INTEGER(i4)                      :: n_comp            = 1
    INTEGER(i4)                      :: entity_kind       = MD_FIELD_ENTITY_UNKNOWN
    INTEGER(i4)                      :: distribution_kind = MD_FIELD_DIST_UNIFORM
    TYPE(MD_FieldRegionRef)          :: region
    TYPE(MD_FieldInitCond)           :: initial_condition
    ! Compatibility aliases for legacy consumers. New code should prefer
    ! entity_kind and initial_condition.
    INTEGER(i4)                      :: entity   = MD_FIELD_ENTITY_UNKNOWN
    REAL(wp)                         :: init_val = 0.0_wp
    LOGICAL                          :: valid    = .FALSE.
  END TYPE MD_FieldEntry

  !-----------------------------------------------------------------------------
  ! [Desc] MD_Field_Desc — cold, INTENT(IN/INOUT): field variable database
  !-----------------------------------------------------------------------------
  TYPE :: MD_Field_Desc
    TYPE(MD_FieldEntry) :: fields(MD_FIELD_MAX)
    INTEGER(i4)         :: n_fields = 0
  END TYPE MD_Field_Desc

  !-----------------------------------------------------------------------------
  ! [State] MD_Field_State — warm: field allocation and runtime status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_State
    LOGICAL     :: allocated   = .FALSE.
    LOGICAL     :: initialized = .FALSE.
    INTEGER(i4) :: n_allocated = 0
    INTEGER(i4) :: total_dof   = 0
  END TYPE MD_Field_State

  !-----------------------------------------------------------------------------
  ! [Ctx] MD_Field_Ctx — hot: transient workspace for field evaluation
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_Ctx
    INTEGER(i4) :: current_step = 0
    INTEGER(i4) :: current_incr = 0
    REAL(wp)    :: current_time = 0.0_wp
  END TYPE MD_Field_Ctx

END MODULE MD_Field_Def
