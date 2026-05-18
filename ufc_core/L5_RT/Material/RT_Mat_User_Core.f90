!===============================================================================
! MODULE: RT_Mat_User_Core
! LAYER:  L5_RT
! DOMAIN: Material / User
! ROLE:   Core
! BRIEF:  Core routing and dispatch for user-defined material family.
!         Follows RT_Mat_Plast_Core pattern with dispatch table lookup.
!         SIO: uses RT_Mat_User_Dispatch_Arg bundle.
!===============================================================================
MODULE RT_Mat_User_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Mat_User_Def, ONLY: RT_Mat_User_Desc, RT_Mat_User_State, &
                              RT_Mat_User_Algo, RT_Mat_User_Ctx, &
                              RT_Mat_User_Dispatch_Arg, &
                              RT_Mat_User_Dispatch_Ctx, &
                              RT_Mat_User_Route_Entry, &
                              RT_Mat_User_Dispatch_Table
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context
  USE PH_Mat_UMAT_Brg, ONLY: PH_UMAT_Call_Enhanced, PH_MAT_UMAT_MaterialClassifier
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_User_Dispatch_Run
  PUBLIC :: RT_Mat_User_Init_Dispatch_Table
  PUBLIC :: RT_Mat_User_Build_Table_From_L4
  PUBLIC :: RT_Mat_User_Dispatch
  PUBLIC :: RT_Mat_User_Commit_State
  PUBLIC :: RT_Mat_User_Rollback_State
  PUBLIC :: RT_Mat_User_Assemble_UMAT_Context

  TYPE(RT_Mat_User_Dispatch_Table), SAVE :: g_user_dispatch_table

CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Mat_User_Dispatch_Run
  ! Spatial: IP | Temporal: Incr | Action: Dispatch
  ! 5-parameter form: (desc, state, algo, ctx, args, status)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_User_Dispatch_Run(desc, state, algo, ctx, args, status)
    TYPE(RT_Mat_User_Desc),        INTENT(IN)    :: desc
    TYPE(RT_Mat_User_State),       INTENT(INOUT) :: state
    TYPE(RT_Mat_User_Algo),        INTENT(IN)    :: algo
    TYPE(RT_Mat_User_Ctx),         INTENT(INOUT) :: ctx
    TYPE(RT_Mat_User_Dispatch_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),         INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. desc%is_active) THEN
      status%status_code = -1; status%message = "Inactive material"; RETURN
    END IF

    ! Return L4 slot index for caller to invoke PH_Mat_User_IP_Incr_Eval
    args%status_code = desc%l4_slot_index

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_User_Dispatch_Run

  SUBROUTINE RT_Mat_User_Init_Dispatch_Table(max_entries, status)
    INTEGER(i4), INTENT(IN) :: max_entries
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (g_user_dispatch_table%initialized) THEN
      IF (ALLOCATED(g_user_dispatch_table%entries)) DEALLOCATE(g_user_dispatch_table%entries)
    END IF
    ALLOCATE(g_user_dispatch_table%entries(max_entries))
    g_user_dispatch_table%num_entries = 0
    g_user_dispatch_table%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_User_Init_Dispatch_Table

  SUBROUTINE RT_Mat_User_Build_Table_From_L4(l4_mat_ids, l4_sub_types, &
                                               l4_slot_indices, num_mats, status)
    INTEGER(i4), INTENT(IN) :: l4_mat_ids(:), l4_sub_types(:), l4_slot_indices(:)
    INTEGER(i4), INTENT(IN) :: num_mats
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (.NOT. g_user_dispatch_table%initialized) THEN
      CALL RT_Mat_User_Init_Dispatch_Table(num_mats, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    DO i = 1, num_mats
      g_user_dispatch_table%entries(i)%mat_id = l4_mat_ids(i)
      g_user_dispatch_table%entries(i)%sub_type = l4_sub_types(i)
      g_user_dispatch_table%entries(i)%l4_slot_index = l4_slot_indices(i)
      g_user_dispatch_table%entries(i)%eval_proc => NULL()
    END DO

    g_user_dispatch_table%num_entries = num_mats
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_User_Build_Table_From_L4

  SUBROUTINE RT_Mat_User_Dispatch(mat_id, ip_index, strain, stress, ddsdde, status)
    INTEGER(i4), INTENT(IN) :: mat_id, ip_index
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, l4_slot_index
    LOGICAL :: found

    CALL init_error_status(status)
    found = .FALSE.
    DO i = 1, g_user_dispatch_table%num_entries
      IF (g_user_dispatch_table%entries(i)%mat_id == mat_id) THEN
        found = .TRUE.
        l4_slot_index = g_user_dispatch_table%entries(i)%l4_slot_index
        EXIT
      END IF
    END DO

    IF (.NOT. found) THEN
      status%status_code = 1
      status%message = "User material not found in dispatch table"
      RETURN
    END IF

    IF (ASSOCIATED(g_user_dispatch_table%entries(i)%eval_proc)) THEN
      CALL g_user_dispatch_table%entries(i)%eval_proc(l4_slot_index, ip_index, &
                                                      strain, stress, ddsdde, status)
    ELSE
      ! No eval_proc bound — return zero stress / identity tangent
      stress = 0.0_wp
      ddsdde = 0.0_wp
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE RT_Mat_User_Dispatch

  SUBROUTINE RT_Mat_User_Commit_State(mat_id, ip_index, status)
    INTEGER(i4), INTENT(IN) :: mat_id, ip_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_User_Commit_State

  SUBROUTINE RT_Mat_User_Rollback_State(mat_id, ip_index, status)
    INTEGER(i4), INTENT(IN) :: mat_id, ip_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_User_Rollback_State

  !=============================================================================
  ! RT_Mat_User_Assemble_UMAT_Context
  !   Assembles PH_UMAT_Context from element-level runtime data.
  !   Called by element loop to prepare data for PH_Mat_User_Eval dispatch.
  !
  !   When element caller provides all ABAQUS UMAT fields:
  !     - coords, drot, dfgrd0/dfgrd1  -> ctx%coords, ctx%drot, ctx%dfgrd0/dfgrd1
  !     - noel, npt                     -> ctx%noel, ctx%npt
  !     - kstep, kinc                   -> ctx%kstep, ctx%kinc
  !   For standalone L4_Eval tests, defaults are used for element-geometry fields.
  !=============================================================================
  SUBROUTINE RT_Mat_User_Assemble_UMAT_Context( &
      ndi, nshr, ntens, nstatv, nprops, &
      sigma_in, statev_in, stran_in, dstran_in, &
      time, dtime, temp, dtemp, props, &
      coords_in, drot_in, dfgrd0_in, dfgrd1_in, &
      noel, npt, layer, kspt, kstep, kinc, &
      celent, cmname, ctx, status)
    INTEGER(i4), INTENT(IN) :: ndi, nshr, ntens, nstatv, nprops
    REAL(wp), INTENT(IN) :: sigma_in(:)
    REAL(wp), INTENT(INOUT) :: statev_in(:)
    REAL(wp), INTENT(IN) :: stran_in(:), dstran_in(:)
    REAL(wp), INTENT(IN) :: time(2), dtime, temp, dtemp
    REAL(wp), INTENT(IN) :: props(:)
    REAL(wp), INTENT(IN) :: coords_in(3)
    REAL(wp), INTENT(IN) :: drot_in(3,3)
    REAL(wp), INTENT(IN) :: dfgrd0_in(3,3), dfgrd1_in(3,3)
    INTEGER(i4), INTENT(IN) :: noel, npt, layer, kspt, kstep, kinc
    REAL(wp), INTENT(IN) :: celent
    CHARACTER(LEN=*), INTENT(IN) :: cmname
    TYPE(PH_UMAT_Context), INTENT(OUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    ! Init allocatable arrays
    CALL ctx%Init(ndi, nshr, nstatv, nprops)

    ! Stress
    ctx%sigma(1:ntens) = sigma_in(1:ntens)

    ! State variables
    ctx%statev(1:MIN(nstatv, SIZE(statev_in))) = &
      statev_in(1:MIN(nstatv, SIZE(statev_in)))

    ! Strain
    ctx%stran(1:ntens) = stran_in(1:ntens)
    ctx%dstran(1:ntens) = dstran_in(1:ntens)

    ! Time / temperature
    ctx%time(1:2) = time(1:2)
    ctx%dtime = dtime
    ctx%temp = temp
    ctx%dtemp = dtemp

    ! Properties
    ctx%props(1:MIN(nprops, SIZE(props))) = &
      props(1:MIN(nprops, SIZE(props)))

    ! Coordinates and rotation
    ctx%coords(1:3) = coords_in(1:3)
    DO i = 1, 3
      DO j = 1, 3
        ctx%drot(i,j) = drot_in(i,j)
      END DO
    END DO

    ! Deformation gradient
    DO i = 1, 3
      DO j = 1, 3
        ctx%dfgrd0(i,j) = dfgrd0_in(i,j)
        ctx%dfgrd1(i,j) = dfgrd1_in(i,j)
      END DO
    END DO

    ! Element info
    ctx%noel = noel
    ctx%npt = npt
    ctx%layer = layer
    ctx%kspt = kspt
    ctx%kinc = kinc
    ctx%kstep = kstep
    ctx%celent = celent
    ctx%cmname = cmname

    ! Initialize work fields
    ctx%sse = 0.0_wp
    ctx%spd = 0.0_wp
    ctx%scd = 0.0_wp
    ctx%rpl = 0.0_wp
    ctx%pnewdt = 1.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_User_Assemble_UMAT_Context

  !=============================================================================
  ! RT_Mat_User_Call_Enhanced_From_Context
  !   Unpacks PH_UMAT_Context and calls PH_UMAT_Call_Enhanced.
  !   Returns updated stress/statev/ddsdde in the context.
  !=============================================================================
  SUBROUTINE RT_Mat_User_Call_Enhanced_From_Context(ctx, mat_classifier, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(PH_MAT_UMAT_MaterialClassifier), INTENT(IN) :: mat_classifier
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: err_stat, ntens

    CALL init_error_status(status)

    ntens = ctx%ndi + ctx%nshr

    CALL PH_UMAT_Call_Enhanced( &
      ctx%sigma, ctx%statev, ctx%ddsdde, &
      ctx%stran, ctx%dstran, ctx%time, ctx%dtime, ctx%temp, ctx%dtemp, &
      ctx%props, ctx%nprops, ctx%coords, ctx%drot, ctx%pnewdt, &
      ctx%sse, ctx%spd, ctx%scd, ctx%rpl, 0.0_wp, ctx%celent, &
      ctx%dfgrd0, ctx%dfgrd1, ctx%noel, ctx%npt, ctx%layer, ctx%kspt, &
      [ctx%kstep, 0, 0, 0], ctx%kinc, &
      mat_classifier, err_stat)

    IF (err_stat /= 0) THEN
      status%status_code = 1
      status%message = "RT_Mat_User_Call_Enhanced_From_Context failed"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE RT_Mat_User_Call_Enhanced_From_Context

END MODULE RT_Mat_User_Core
