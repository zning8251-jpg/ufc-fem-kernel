!==============================================================================!
! MODULE MD_Output_XXX                                    [Template v1.0]
! Layer  : L3_MD  (What — model description)
! Domain : Output
! Feature: XXX_XXX  ← replace with concrete output request name
!          e.g. MD_Output_Std_Field   (standard full-model field output request)
!               MD_Output_Hist_NodeSet (history output for a specific node set)
!
! Purpose:
!   Instantiates and validates a concrete Output request descriptor for one
!   *OUTPUT,FIELD or *OUTPUT,HISTORY block parsed from the INP file.
!   Extends the base descriptor types from MD_Output_Types and provides
!   the InitFromDeck / Validate entry points consumed by the model reader.
!
! Four-TYPE catalogue (L3_MD Desc pattern — Output domain):
!   MD_XXX_FieldOut_Desc  EXTENDS MD_FieldOut_Desc
!     → Adds INP-keyword-level fields: variables, set names, restart flag
!   MD_XXX_HistOut_Desc   EXTENDS MD_HistOut_Desc
!     → Adds target node/element and time-based frequency fields
!   (No State/Algo/Ctx in L3_MD Output — pure cold-path description)
!
! Naming convention:
!   Replace XXX_XXX with the specific request variant, e.g.:
!     MD_Output_Std_Field   → standard element/node field output
!     MD_Output_Energy      → global energy output (*OUTPUT,HISTORY + ENERGY)
!     MD_Output_Disp_Set    → displacement history on node set NSET1
!
! Module catalogue:
!   TYPE MD_XXX_FieldOut_Desc      — field output request instance descriptor
!   TYPE MD_XXX_HistOut_Desc       — history output request instance descriptor
!   SUBROUTINE MD_XXX_FieldOut_Init        — public init entry (from INP deck)
!   SUBROUTINE MD_XXX_FieldOut_Validate    — validate descriptor consistency
!   SUBROUTINE MD_XXX_HistOut_Init         — public init entry (from INP deck)
!   SUBROUTINE MD_XXX_HistOut_Validate     — validate descriptor consistency
!   SUBROUTINE MD_XXX_FieldOut_AddVar      — append variable to request
!   SUBROUTINE MD_XXX_HistOut_AddVar       — append variable to request
!==============================================================================!
MODULE MD_Output_XXX
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_WARN, IF_STATUS_ERROR
  USE MD_Output_Types, ONLY: MD_FieldOut_Desc, MD_HistOut_Desc, &
                              MD_FieldOut_Var,                   &
                              MD_OUTPUT_OUTFREQ_ALL,             &
                              MD_OUTPUT_OUTFREQ_LAST,            &
                              MD_OUTPUT_OUTFREQ_INTERVAL,        &
                              MD_OUTPUT_OUTFREQ_TIME,            &
                              MD_OUTPUT_OUTPOS_INTEGRATION_PTS,  &
                              MD_OUTPUT_OUTPOS_NODES,            &
                              MD_OUTPUT_OUTPOS_CENTROID,         &
                              MD_OUTPUT_OUTPOS_ELEMENT_NODAL,    &
                              MD_OUTPUT_MAX_OUT_VARS
  IMPLICIT NONE
  PRIVATE

  !-- Default variable pre-sets (common bundles)
  INTEGER(i4), PARAMETER :: OUT_PRESET_NONE   = 0_i4  ! No pre-set, manual vars
  INTEGER(i4), PARAMETER :: OUT_PRESET_STD    = 1_i4  ! S + E + U + RF
  INTEGER(i4), PARAMETER :: OUT_PRESET_FULL   = 2_i4  ! All standard variables
  INTEGER(i4), PARAMETER :: OUT_PRESET_SDV    = 3_i4  ! SDV only
  INTEGER(i4), PARAMETER :: OUT_PRESET_ENERGY = 4_i4  ! ALLSE + ALLKE + ETOTAL

  !============================================================================!
  ! TYPE MD_XXX_FieldOut_Desc           [EXTENDS MD_FieldOut_Desc]
  ! Instance-level field output request descriptor.
  ! Adds:
  !   - variable preset shortcut (OUT_PRESET_XXX)
  !   - additional INP keyword fields (e.g., POSITION= keyword, TIME POINTS=)
  !   - derived counts for rapid runtime dispatch
  !============================================================================!
  TYPE, PUBLIC, EXTENDS(MD_FieldOut_Desc) :: MD_XXX_FieldOut_Desc
    !-- Variable pre-set shortcut (applied during InitFromDeck)
    INTEGER(i4) :: var_preset   = OUT_PRESET_STD  ! OUT_PRESET_XXX constant

    !-- Additional scope options
    LOGICAL     :: include_surface_nodes = .FALSE. ! Write surface-only nodes
    LOGICAL     :: exclude_interior      = .FALSE. ! Skip interior elements

    !-- Time-points scheduling (OUTFREQ_TIME mode)
    REAL(wp)    :: time_points(32) = 0.0_wp        ! User-specified write times
    INTEGER(i4) :: n_time_points   = 0_i4          ! 0 = not used

    !-- Restart flag (copied from INP *RESTART,WRITE keyword)
    LOGICAL     :: write_restart   = .FALSE.

    !-- Derived
    INTEGER(i4) :: n_elem_vars = 0_i4  ! Count of element-type variables
    INTEGER(i4) :: n_node_vars = 0_i4  ! Count of node-type variables

    !-- Validation
    LOGICAL     :: is_validated = .FALSE.
  END TYPE MD_XXX_FieldOut_Desc

  !============================================================================!
  ! TYPE MD_XXX_HistOut_Desc            [EXTENDS MD_HistOut_Desc]
  ! Instance-level history output request descriptor.
  ! Adds:
  !   - specific node / element ID target (single-point history)
  !   - time-interval frequency (min time between writes, seconds)
  !   - ODB section name for xy-data grouping
  !============================================================================!
  TYPE, PUBLIC, EXTENDS(MD_HistOut_Desc) :: MD_XXX_HistOut_Desc
    !-- Variable preset
    INTEGER(i4) :: var_preset = OUT_PRESET_NONE

    !-- Single-entity target (if target_id > 0 in MD_HistOut_Desc)
    INTEGER(i4) :: target_dof = 0_i4   ! DOF index at target node (1=X,2=Y,3=Z)
    INTEGER(i4) :: target_gp  = 0_i4   ! GP index at target element (0 = average)

    !-- Time-based write interval (independent of increment frequency)
    REAL(wp)    :: min_time_interval = 0.0_wp  ! 0 = every eligible increment

    !-- ODB xy-data labelling
    CHARACTER(LEN=64) :: xy_data_name = ''  ! Curve label in ODB
    CHARACTER(LEN=32) :: x_label      = 'Time'
    CHARACTER(LEN=32) :: y_label      = ''

    !-- Validation
    LOGICAL     :: is_validated = .FALSE.
  END TYPE MD_XXX_HistOut_Desc

  !-- Public interface
  PUBLIC :: MD_XXX_FieldOut_Init
  PUBLIC :: MD_XXX_FieldOut_Validate
  PUBLIC :: MD_XXX_FieldOut_AddVar
  PUBLIC :: MD_XXX_HistOut_Init
  PUBLIC :: MD_XXX_HistOut_Validate
  PUBLIC :: MD_XXX_HistOut_AddVar

CONTAINS

  !============================================================================!
  ! SUBROUTINE MD_XXX_FieldOut_Init                               [Public]
  ! Initialises a field output request descriptor from INP-level arguments.
  ! Applies variable preset if var_preset /= OUT_PRESET_NONE.
  !============================================================================!
  SUBROUTINE MD_XXX_FieldOut_Init(desc, request_id, elem_set, node_set, &
                                   freq_policy, freq_interval, var_preset, st)
    TYPE(MD_XXX_FieldOut_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),                INTENT(IN)    :: request_id
    CHARACTER(LEN=*),           INTENT(IN)    :: elem_set, node_set
    INTEGER(i4),                INTENT(IN)    :: freq_policy, freq_interval
    INTEGER(i4),                INTENT(IN)    :: var_preset
    TYPE(ErrorStatusType),      INTENT(OUT)   :: st

    TYPE(ErrorStatusType) :: st_add

    CALL init_error_status(st)
    desc%request_id    = request_id
    desc%elem_set_name = TRIM(elem_set)
    desc%node_set_name = TRIM(node_set)
    desc%freq_policy   = freq_policy
    desc%freq_interval = MAX(1_i4, freq_interval)
    desc%var_preset    = var_preset
    desc%nvars         = 0_i4
    desc%n_elem_vars   = 0_i4
    desc%n_node_vars   = 0_i4
    desc%is_initialized = .TRUE.
    desc%is_validated   = .FALSE.

    !-- Apply variable preset
    SELECT CASE (var_preset)

      CASE (OUT_PRESET_STD)
        !-- Stress + Strain (integration pts) + Displacement + Reaction force
        CALL MD_XXX_FieldOut_AddVar(desc, 'S',  0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'E',  0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'U',  0_i4, &
             MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'RF', 0_i4, &
             MD_OUTPUT_OUTPOS_NODES, st_add)

      CASE (OUT_PRESET_FULL)
        !-- Standard + SDV + contact + plastic strain
        CALL MD_XXX_FieldOut_AddVar(desc, 'S',   0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'E',   0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'PE',  0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'PEEQ',0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'SDV', 0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'U',   0_i4, &
             MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'RF',  0_i4, &
             MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'CF',  0_i4, &
             MD_OUTPUT_OUTPOS_NODES, st_add)

      CASE (OUT_PRESET_SDV)
        !-- State-dependent variables only
        CALL MD_XXX_FieldOut_AddVar(desc, 'SDV', 0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)

      CASE (OUT_PRESET_ENERGY)
        !-- Energy scalars (written as node-type in Abaqus convention)
        CALL MD_XXX_FieldOut_AddVar(desc, 'ELEN', 0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)
        CALL MD_XXX_FieldOut_AddVar(desc, 'ELEDEN', 0_i4, &
             MD_OUTPUT_OUTPOS_INTEGRATION_PTS, st_add)

      CASE DEFAULT  ! OUT_PRESET_NONE or unknown: no auto-add
        CONTINUE

    END SELECT

  END SUBROUTINE MD_XXX_FieldOut_Init


  !============================================================================!
  ! SUBROUTINE MD_XXX_FieldOut_Validate                           [Public]
  ! Checks consistency of a completed field output request descriptor.
  !============================================================================!
  SUBROUTINE MD_XXX_FieldOut_Validate(desc, st)
    TYPE(MD_XXX_FieldOut_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType),      INTENT(OUT)   :: st

    CALL init_error_status(st)

    IF (.NOT. desc%is_initialized) THEN
      st%status_code = IF_STATUS_ERROR
      st%message     = 'MD_XXX_FieldOut_Validate: descriptor not initialized'
      RETURN
    END IF

    IF (desc%nvars == 0_i4) THEN
      st%status_code = IF_STATUS_WARN
      st%message     = 'MD_XXX_FieldOut_Validate: no output variables defined'
    END IF

    IF (desc%freq_interval < 1_i4) THEN
      desc%freq_interval = 1_i4
      st%status_code = IF_STATUS_WARN
      st%message     = 'MD_XXX_FieldOut_Validate: freq_interval clamped to 1'
    END IF

    !-- Validate time points (must be strictly increasing)
    IF (desc%freq_policy == MD_OUTPUT_OUTFREQ_TIME .AND. &
        desc%n_time_points > 1_i4) THEN
      BLOCK
        INTEGER(i4) :: itp
        DO itp = 2, desc%n_time_points
          IF (desc%time_points(itp) <= desc%time_points(itp-1)) THEN
            st%status_code = IF_STATUS_ERROR
            WRITE(st%message, '(A,I4,A)') &
              'MD_XXX_FieldOut_Validate: time_points not strictly increasing at index ', itp, ''
            RETURN
          END IF
        END DO
      END BLOCK
    END IF

    desc%is_validated = .TRUE.

  END SUBROUTINE MD_XXX_FieldOut_Validate


  !============================================================================!
  ! SUBROUTINE MD_XXX_FieldOut_AddVar                             [Public]
  ! Appends a single output variable to the request descriptor.
  !============================================================================!
  SUBROUTINE MD_XXX_FieldOut_AddVar(desc, var_name, var_index, position, st)
    TYPE(MD_XXX_FieldOut_Desc), INTENT(INOUT) :: desc
    CHARACTER(LEN=*),           INTENT(IN)    :: var_name
    INTEGER(i4),                INTENT(IN)    :: var_index  ! 0 = all components
    INTEGER(i4),                INTENT(IN)    :: position   ! MD_OUTPUT_OUTPOS_XXX
    TYPE(ErrorStatusType),      INTENT(OUT)   :: st

    CALL init_error_status(st)

    IF (desc%nvars >= MD_OUTPUT_MAX_OUT_VARS) THEN
      st%status_code = IF_STATUS_WARN
      st%message     = 'MD_XXX_FieldOut_AddVar: MAX_OUT_VARS reached, variable skipped'
      RETURN
    END IF

    desc%nvars = desc%nvars + 1_i4
    desc%vars(desc%nvars)%var_name  = TRIM(var_name)
    desc%vars(desc%nvars)%var_index = var_index
    desc%vars(desc%nvars)%position  = position

    !-- Update node vs element variable counters
    IF (position == MD_OUTPUT_OUTPOS_NODES) THEN
      desc%n_node_vars = desc%n_node_vars + 1_i4
    ELSE
      desc%n_elem_vars = desc%n_elem_vars + 1_i4
    END IF

  END SUBROUTINE MD_XXX_FieldOut_AddVar


  !============================================================================!
  ! SUBROUTINE MD_XXX_HistOut_Init                                [Public]
  ! Initialises a history output request descriptor.
  !============================================================================!
  SUBROUTINE MD_XXX_HistOut_Init(desc, request_id, set_name, target_id, &
                                  freq_policy, freq_interval, var_preset, st)
    TYPE(MD_XXX_HistOut_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),               INTENT(IN)    :: request_id
    CHARACTER(LEN=*),          INTENT(IN)    :: set_name
    INTEGER(i4),               INTENT(IN)    :: target_id, freq_policy
    INTEGER(i4),               INTENT(IN)    :: freq_interval, var_preset
    TYPE(ErrorStatusType),     INTENT(OUT)   :: st

    TYPE(ErrorStatusType) :: st_add

    CALL init_error_status(st)
    desc%request_id   = request_id
    desc%set_name     = TRIM(set_name)
    desc%target_id    = target_id
    desc%freq_policy  = freq_policy
    desc%freq_interval = MAX(1_i4, freq_interval)
    desc%var_preset   = var_preset
    desc%nvars        = 0_i4
    desc%is_initialized = .TRUE.
    desc%is_validated   = .FALSE.

    !-- Apply variable preset
    SELECT CASE (var_preset)

      CASE (OUT_PRESET_STD)
        CALL MD_XXX_HistOut_AddVar(desc, 'U1',  0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'U2',  0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'U3',  0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'RF1', 0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'RF2', 0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'RF3', 0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)

      CASE (OUT_PRESET_ENERGY)
        CALL MD_XXX_HistOut_AddVar(desc, 'ALLSE',  0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'ALLKE',  0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'ALLWK',  0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)
        CALL MD_XXX_HistOut_AddVar(desc, 'ETOTAL', 0_i4, MD_OUTPUT_OUTPOS_NODES, st_add)

      CASE DEFAULT
        CONTINUE

    END SELECT

  END SUBROUTINE MD_XXX_HistOut_Init


  !============================================================================!
  ! SUBROUTINE MD_XXX_HistOut_Validate                            [Public]
  ! Validates a completed history output request descriptor.
  !============================================================================!
  SUBROUTINE MD_XXX_HistOut_Validate(desc, st)
    TYPE(MD_XXX_HistOut_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType),     INTENT(OUT)   :: st

    CALL init_error_status(st)

    IF (.NOT. desc%is_initialized) THEN
      st%status_code = IF_STATUS_ERROR
      st%message     = 'MD_XXX_HistOut_Validate: descriptor not initialized'
      RETURN
    END IF

    IF (desc%nvars == 0_i4) THEN
      st%status_code = IF_STATUS_WARN
      st%message     = 'MD_XXX_HistOut_Validate: no history variables defined'
    END IF

    IF (desc%freq_interval < 1_i4) THEN
      desc%freq_interval = 1_i4
    END IF

    IF (desc%target_id < 0_i4) THEN
      st%status_code = IF_STATUS_ERROR
      st%message     = 'MD_XXX_HistOut_Validate: invalid target_id (negative)'
      RETURN
    END IF

    IF (desc%min_time_interval < 0.0_wp) THEN
      desc%min_time_interval = 0.0_wp
    END IF

    !-- Auto-fill xy_data_name if blank
    IF (LEN_TRIM(desc%xy_data_name) == 0) THEN
      WRITE(desc%xy_data_name, '(A,I6.6)') 'HIST_', desc%request_id
    END IF

    desc%is_validated = .TRUE.

  END SUBROUTINE MD_XXX_HistOut_Validate


  !============================================================================!
  ! SUBROUTINE MD_XXX_HistOut_AddVar                              [Public]
  ! Appends a single history variable to the request descriptor.
  !============================================================================!
  SUBROUTINE MD_XXX_HistOut_AddVar(desc, var_name, var_index, position, st)
    TYPE(MD_XXX_HistOut_Desc), INTENT(INOUT) :: desc
    CHARACTER(LEN=*),          INTENT(IN)    :: var_name
    INTEGER(i4),               INTENT(IN)    :: var_index
    INTEGER(i4),               INTENT(IN)    :: position
    TYPE(ErrorStatusType),     INTENT(OUT)   :: st

    CALL init_error_status(st)

    IF (desc%nvars >= MD_OUTPUT_MAX_OUT_VARS) THEN
      st%status_code = IF_STATUS_WARN
      st%message     = 'MD_XXX_HistOut_AddVar: MAX_OUT_VARS reached, variable skipped'
      RETURN
    END IF

    desc%nvars = desc%nvars + 1_i4
    desc%vars(desc%nvars)%var_name  = TRIM(var_name)
    desc%vars(desc%nvars)%var_index = var_index
    desc%vars(desc%nvars)%position  = position

    !-- Auto-set y_label from first variable if blank
    IF (LEN_TRIM(desc%y_label) == 0) THEN
      desc%y_label = TRIM(var_name)
    END IF

  END SUBROUTINE MD_XXX_HistOut_AddVar

END MODULE MD_Output_XXX
