!===============================================================================
! MODULE: RT_Mat_Elas_Core
! LAYER:  L5_RT
! DOMAIN: Material / Elas
! ROLE:   Core
! BRIEF:  Core routing and dispatch for elastic material family.
!         Manages dispatch table, state tracking, and L4 coordination.
!         SIO: uses RT_Mat_Elas_Dispatch_Arg bundle with [IN]/[OUT] comments.
!
!         Cross-layer:
!           L5 dispatch --[call]--> L4 PH_Mat_Elas_IP_Incr_Eval
!           L5 state   --[sync]--> L3 MD_Mat_Elas_State
!===============================================================================
MODULE RT_Mat_Elas_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Mat_Elas_Def, ONLY: RT_Mat_Elas_Desc, &
                              RT_Mat_Elas_State, &
                              RT_Mat_Elas_Algo, &
                              RT_Mat_Elas_Ctx, &
                              RT_Mat_Elas_Route_Entry, &
                              RT_Mat_Elas_Dispatch_Table, &
                              RT_Mat_Elas_Dispatch_Arg
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Elas_Init_Table
  PUBLIC :: RT_Mat_Elas_Build_Table
  PUBLIC :: RT_Mat_Elas_Dispatch_Run
  PUBLIC :: RT_Mat_Elas_Add_Route
  PUBLIC :: RT_Mat_Elas_Find_Route

  !-----------------------------------------------------------------------------
  ! Module-level dispatch table (singleton)
  !-----------------------------------------------------------------------------
  TYPE(RT_Mat_Elas_Dispatch_Table), SAVE :: g_dispatch_table

CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Mat_Elas_Init_Table
  ! Initialize the dispatch table
  ! Spatial: - | Temporal: Init | Action: Init (COLD_PATH)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Elas_Init_Table(max_entries, status)
    INTEGER(i4), INTENT(IN) :: max_entries
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL g_dispatch_table%Init(max_entries, status)
  END SUBROUTINE RT_Mat_Elas_Init_Table

  !-----------------------------------------------------------------------------
  ! RT_Mat_Elas_Build_Table
  ! Build dispatch table from L4 material descriptors
  ! Spatial: - | Temporal: Init | Action: Build (COLD_PATH)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Elas_Build_Table(l4_mat_ids, l4_sub_types, &
                                      l4_slot_indices, num_mats, status)
    INTEGER(i4), INTENT(IN) :: l4_mat_ids(:)
    INTEGER(i4), INTENT(IN) :: l4_sub_types(:)
    INTEGER(i4), INTENT(IN) :: l4_slot_indices(:)
    INTEGER(i4), INTENT(IN) :: num_mats
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    IF (num_mats <= 0) THEN
      status%status_code = 1; status%message = "No materials"
      RETURN
    END IF

    IF (.NOT. g_dispatch_table%initialized) THEN
      CALL RT_Mat_Elas_Init_Table(num_mats, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    DO i = 1, num_mats
      CALL RT_Mat_Elas_Add_Route(l4_mat_ids(i), l4_sub_types(i), &
                                  l4_slot_indices(i), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Elas_Build_Table

  !-----------------------------------------------------------------------------
  ! RT_Mat_Elas_Add_Route
  ! Add a single route entry to dispatch table
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Elas_Add_Route(mat_id, sub_type, l4_slot_index, status)
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: l4_slot_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. g_dispatch_table%initialized) THEN
      status%status_code = -1; status%message = "Table not initialized"
      RETURN
    END IF

    IF (g_dispatch_table%num_entries >= SIZE(g_dispatch_table%entries)) THEN
      status%status_code = -2; status%message = "Table full"
      RETURN
    END IF

    g_dispatch_table%num_entries = g_dispatch_table%num_entries + 1
    g_dispatch_table%entries(g_dispatch_table%num_entries)%mat_id = mat_id
    g_dispatch_table%entries(g_dispatch_table%num_entries)%sub_type = sub_type
    g_dispatch_table%entries(g_dispatch_table%num_entries)%l4_slot_index = l4_slot_index

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Elas_Add_Route

  !-----------------------------------------------------------------------------
  ! RT_Mat_Elas_Find_Route
  ! Find route entry by material ID
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Elas_Find_Route(mat_id, sub_type, l4_slot_index, found, status)
    INTEGER(i4), INTENT(IN) :: mat_id
    INTEGER(i4), INTENT(OUT) :: sub_type
    INTEGER(i4), INTENT(OUT) :: l4_slot_index
    LOGICAL, INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    found = .FALSE.
    sub_type = 0_i4
    l4_slot_index = 0_i4

    DO i = 1, g_dispatch_table%num_entries
      IF (g_dispatch_table%entries(i)%mat_id == mat_id) THEN
        sub_type = g_dispatch_table%entries(i)%sub_type
        l4_slot_index = g_dispatch_table%entries(i)%l4_slot_index
        found = .TRUE.
        EXIT
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Elas_Find_Route

  !-----------------------------------------------------------------------------
  ! RT_Mat_Elas_Dispatch_Run
  ! Main dispatch: route material evaluation to L4 via dispatch arg.
  ! Returns the L4 slot index for the caller (e.g., StepDriver) to invoke L4.
  !
  ! Spatial: IP | Temporal: Incr | Action: Dispatch (WARM_PATH)
  ! SIO: uses RT_Mat_Elas_Dispatch_Arg bundle
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Elas_Dispatch_Run(desc, state, algo, ctx, args, status)
    TYPE(RT_Mat_Elas_Desc),        INTENT(IN)    :: desc
    TYPE(RT_Mat_Elas_State),       INTENT(INOUT) :: state
    TYPE(RT_Mat_Elas_Algo),        INTENT(IN)    :: algo
    TYPE(RT_Mat_Elas_Ctx),         INTENT(INOUT) :: ctx
    TYPE(RT_Mat_Elas_Dispatch_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),         INTENT(OUT)   :: status

    INTEGER(i4) :: l4_slot
    LOGICAL :: found
    INTEGER(i4) :: sub_type_dummy

    CALL init_error_status(status)

    ! Locate route
    CALL RT_Mat_Elas_Find_Route(args%mat_id, sub_type_dummy, l4_slot, found, status)
    IF (.NOT. found) THEN
      status%status_code = -1
      status%message = "Material not found in dispatch table"
      RETURN
    END IF

    ! Write back L4 slot index into args for caller to use
    args%status_code = l4_slot  ! The L4 slot index is returned in status_code
    ! In production, the caller (RT_StepDriver) uses l4_slot to invoke
    ! PH_Mat_Elas_IP_Incr_Eval on the appropriate L4 slot pool

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Elas_Dispatch_Run

END MODULE RT_Mat_Elas_Core