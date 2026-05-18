!===============================================================================
! MODULE: RT_Mat_Core
! LAYER:  L5_RT
! DOMAIN: Material
! ROLE:   Core — pure routing dispatcher (NO local constitutive computation)
! BRIEF:  Routes mat_type to L4 PH_Mat kernel via PH_MatReg dispatch table.
!   W1: 表由 **`RT_Mat_Brg_BuildTable_FromMaterial`** 从 **`PH_Mat_Domain`** + 槽 **`desc`**
!   填充；**`entries%mat_type`** 对齐 **`PH_Mat_Desc_Effective_Model`**；**`RT_Mat_Dispatch_Ctx`**
!   见 **`RT_Mat_Def`**（与 L4 族枚举一致）。
!===============================================================================
MODULE RT_Mat_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  USE RT_Mat_Def
  USE PH_Mat_Def, ONLY: PH_Mat_Domain
  USE PH_Mat_Core, ONLY: PH_Mat_Execute_Flow, PH_Mat_Execute_Tangent_Flow
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Init_Table
  PUBLIC :: RT_Mat_Finalize_Table
  PUBLIC :: RT_Mat_Register_Route
  PUBLIC :: RT_Mat_Dispatch_Stress
  PUBLIC :: RT_Mat_Dispatch_Tangent
  PUBLIC :: RT_Mat_Get_Route
  PUBLIC :: RT_Mat_Get_Table_Summary
  PUBLIC :: RT_Mat_Swap_State
  PUBLIC :: RT_Mat_Cache_State
  PUBLIC :: RT_Mat_Restore_Cache
  PUBLIC :: RT_Mat_Checkpoint
  PUBLIC :: RT_Mat_Restore_Checkpoint
  PUBLIC :: RT_Mat_Alloc_StateVars
  PUBLIC :: RT_Mat_Dealloc_StateVars

CONTAINS

  !---------------------------------------------------------------------------
  ! Init: reset dispatch table
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Init_Table(table, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(INOUT) :: table
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, RT_MAT_TABLE_MAX
      table%entries(i)%mat_type   = 0_i4
      table%entries(i)%mat_id     = 0_i4
      table%entries(i)%mat_pt_idx = 0_i4
      table%entries(i)%is_user    = .FALSE.
      table%entries(i)%active     = .FALSE.
    END DO
    table%n_entries   = 0_i4
    table%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Init_Table

  !---------------------------------------------------------------------------
  ! Finalize: mark table as inactive
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Finalize_Table(table, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(INOUT) :: table
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, RT_MAT_TABLE_MAX
      table%entries(i)%active = .FALSE.
    END DO
    table%n_entries   = 0_i4
    table%initialized = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Finalize_Table

  !---------------------------------------------------------------------------
  ! Register a routing entry (called during Populate / step init)
  !   mat_type  : L4 MAT_* constant (101-1102)
  !   mat_id    : L3 material id (for diagnostics/traceability)
  !   mat_pt_idx: L4 slot_pool index
  !   is_user   : .TRUE. if UMAT/VUMAT
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Register_Route(table, mat_type, mat_id, mat_pt_idx, &
                                    is_user, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(INOUT) :: table
    INTEGER(i4),                 INTENT(IN)    :: mat_type
    INTEGER(i4),                 INTENT(IN)    :: mat_id
    INTEGER(i4),                 INTENT(IN)    :: mat_pt_idx
    LOGICAL,                     INTENT(IN)    :: is_user
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    INTEGER(i4) :: idx

    CALL init_error_status(status)

    IF (.NOT. table%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Register_Route] table not initialized"
      RETURN
    END IF

    IF (table%n_entries >= RT_MAT_TABLE_MAX) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Register_Route] table full"
      RETURN
    END IF

    idx = table%n_entries + 1_i4
    table%entries(idx)%mat_type   = mat_type
    table%entries(idx)%mat_id     = mat_id
    table%entries(idx)%mat_pt_idx = mat_pt_idx
    table%entries(idx)%is_user    = is_user
    table%entries(idx)%active     = .TRUE.
    table%n_entries = idx
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Register_Route

  !---------------------------------------------------------------------------
  ! Get_Route: lookup by mat_id → dispatch context
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Get_Route(table, mat_id, ctx, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(IN)  :: table
    INTEGER(i4),                 INTENT(IN)  :: mat_id
    TYPE(RT_Mat_Dispatch_Ctx),   INTENT(OUT) :: ctx
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, table%n_entries
      IF (table%entries(i)%active .AND. table%entries(i)%mat_id == mat_id) THEN
        ctx%mat_type    = table%entries(i)%mat_type
        ctx%mat_id      = table%entries(i)%mat_id
        ctx%mat_pt_idx  = table%entries(i)%mat_pt_idx
        ctx%is_user_sub = table%entries(i)%is_user
        ctx%route_status = RT_MAT_ROUTE_OK
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    ctx%route_status   = RT_MAT_ROUTE_NOT_FOUND
    status%status_code = IF_STATUS_INVALID
    status%message     = "[RT_Mat_Get_Route] mat_id not found in table"
  END SUBROUTINE RT_Mat_Get_Route

  !---------------------------------------------------------------------------
  ! Dispatch_Stress: route stress update to L4 PH_Mat kernel
  !
  ! This is the L5 entry point called from element loop.
  ! Delegates actual computation to L4 via PH_Mat_Update_Stress.
  !
  ! NOTE: Currently implemented as a routing stub that validates the
  ! dispatch context and delegates to L4. Full L4 integration requires
  ! USE PH_MatDispatch at the call site (RT_AsmSolv), which already
  ! exists in the golden-line code path.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Dispatch_Stress(ctx, status, material_dom)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    TYPE(PH_Mat_Domain), INTENT(IN), OPTIONAL, TARGET :: material_dom

    CALL init_error_status(status)

    IF (PRESENT(material_dom)) THEN
      IF (ctx%mat_pt_idx < 1_i4 .OR. ctx%mat_pt_idx > material_dom%pool_count) THEN
        ctx%route_status   = RT_MAT_ROUTE_NO_KERNEL
        status%status_code = IF_STATUS_INVALID
        status%message     = "[RT_Mat_Dispatch_Stress] mat_pt_idx out of range"
        RETURN
      END IF
      IF (.NOT. material_dom%slot_pool(ctx%mat_pt_idx)%active) THEN
        ctx%route_status   = RT_MAT_ROUTE_NO_KERNEL
        status%status_code = IF_STATUS_INVALID
        status%message     = "[RT_Mat_Dispatch_Stress] inactive material slot"
        RETURN
      END IF
      CALL PH_Mat_Execute_Flow(material_dom, ctx%mat_pt_idx, status)
      IF (status%status_code == IF_STATUS_OK) THEN
        ctx%route_status = RT_MAT_ROUTE_OK
      ELSE
        ctx%route_status = RT_MAT_ROUTE_NO_KERNEL
      END IF
      RETURN
    END IF

    IF (ctx%mat_type <= 0_i4) THEN
      ctx%route_status   = RT_MAT_ROUTE_NOT_FOUND
      status%status_code = IF_STATUS_INVALID
      status%message     = "[RT_Mat_Dispatch_Stress] invalid mat_type"
      RETURN
    END IF

    IF (ctx%mat_pt_idx <= 0_i4) THEN
      ctx%route_status   = RT_MAT_ROUTE_NO_KERNEL
      status%status_code = IF_STATUS_INVALID
      status%message     = "[RT_Mat_Dispatch_Stress] invalid slot index"
      RETURN
    END IF

    ! L5 routing validated — actual computation delegated to L4.
    ! The golden-line call chain is:
    !   RT_AsmSolv → PH_Mat_Update_Stress(ctx%mat_type, arg, st)
    ! L5 provides the routing context; L4 executes the kernel.
    ctx%route_status   = RT_MAT_ROUTE_OK
    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_Mat_Dispatch_Stress

  !---------------------------------------------------------------------------
  ! Dispatch_Tangent: route tangent computation to L4
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Dispatch_Tangent(ctx, status, material_dom)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    TYPE(PH_Mat_Domain), INTENT(IN), OPTIONAL, TARGET :: material_dom

    CALL init_error_status(status)

    IF (PRESENT(material_dom)) THEN
      IF (ctx%mat_pt_idx < 1_i4 .OR. ctx%mat_pt_idx > material_dom%pool_count) THEN
        ctx%route_status   = RT_MAT_ROUTE_NO_KERNEL
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      IF (.NOT. material_dom%slot_pool(ctx%mat_pt_idx)%active) THEN
        ctx%route_status   = RT_MAT_ROUTE_NO_KERNEL
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      CALL PH_Mat_Execute_Tangent_Flow(material_dom, ctx%mat_pt_idx, status)
      IF (status%status_code == IF_STATUS_OK) THEN
        ctx%route_status = RT_MAT_ROUTE_OK
      ELSE
        ctx%route_status = RT_MAT_ROUTE_NO_KERNEL
      END IF
      RETURN
    END IF

    IF (ctx%mat_type <= 0_i4) THEN
      ctx%route_status   = RT_MAT_ROUTE_NOT_FOUND
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ctx%route_status   = RT_MAT_ROUTE_OK
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Dispatch_Tangent

  !---------------------------------------------------------------------------
  ! Get_Table_Summary: diagnostic output
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Get_Table_Summary(table, n_active, n_user)
    TYPE(RT_Mat_Dispatch_Table), INTENT(IN)  :: table
    INTEGER(i4),                 INTENT(OUT) :: n_active
    INTEGER(i4),                 INTENT(OUT) :: n_user
    INTEGER(i4) :: i

    n_active = 0_i4
    n_user   = 0_i4

    DO i = 1, table%n_entries
      IF (table%entries(i)%active) THEN
        n_active = n_active + 1_i4
        IF (table%entries(i)%is_user) n_user = n_user + 1_i4
      END IF
    END DO
  END SUBROUTINE RT_Mat_Get_Table_Summary

  !---------------------------------------------------------------------------
  ! Swap: exchange new/old state variables after converged increment
  !   stress_new <-> stress_old, sdv_new <-> sdv_old
  !   Thin router: only manages pointer swaps; actual data in L4.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Swap_State(table, n_ip, stress_old, stress_new, &
                                sdv_old, sdv_new, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(IN)    :: table
    INTEGER(i4),                 INTENT(IN)    :: n_ip
    REAL(wp),                    INTENT(INOUT) :: stress_old(:,:)  ! [n_comp, n_ip]
    REAL(wp),                    INTENT(INOUT) :: stress_new(:,:)
    REAL(wp),                    INTENT(INOUT) :: sdv_old(:,:)     ! [n_sdv, n_ip]
    REAL(wp),                    INTENT(INOUT) :: sdv_new(:,:)
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: ip, nc, ns
    REAL(wp), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)

    IF (.NOT. table%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Swap_State] table not initialized"
      RETURN
    END IF

    nc = SIZE(stress_old, 1)
    ns = SIZE(sdv_old, 1)

    ! Swap stress: old <-> new
    IF (nc > 0 .AND. n_ip > 0) THEN
      ALLOCATE(tmp(nc))
      DO ip = 1, n_ip
        tmp(:) = stress_old(:, ip)
        stress_old(:, ip) = stress_new(:, ip)
        stress_new(:, ip) = tmp(:)
      END DO
      DEALLOCATE(tmp)
    END IF

    ! Swap SDV: old <-> new
    IF (ns > 0 .AND. n_ip > 0) THEN
      ALLOCATE(tmp(ns))
      DO ip = 1, n_ip
        tmp(:) = sdv_old(:, ip)
        sdv_old(:, ip) = sdv_new(:, ip)
        sdv_new(:, ip) = tmp(:)
      END DO
      DEALLOCATE(tmp)
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Swap_State

  !---------------------------------------------------------------------------
  ! Cache: save current state to cache buffer (for cutback recovery)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Cache_State(n_ip, stress_src, sdv_src, &
                                 stress_cache, sdv_cache, status)
    INTEGER(i4),           INTENT(IN)    :: n_ip
    REAL(wp),              INTENT(IN)    :: stress_src(:,:)   ! [n_comp, n_ip]
    REAL(wp),              INTENT(IN)    :: sdv_src(:,:)      ! [n_sdv, n_ip]
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: stress_cache(:,:)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: sdv_cache(:,:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: nc, ns

    CALL init_error_status(status)

    nc = SIZE(stress_src, 1)
    ns = SIZE(sdv_src, 1)

    ! Allocate cache if needed
    IF (ALLOCATED(stress_cache)) THEN
      IF (SIZE(stress_cache, 1) /= nc .OR. SIZE(stress_cache, 2) /= n_ip) THEN
        DEALLOCATE(stress_cache)
      END IF
    END IF
    IF (.NOT. ALLOCATED(stress_cache)) ALLOCATE(stress_cache(nc, n_ip))

    IF (ALLOCATED(sdv_cache)) THEN
      IF (SIZE(sdv_cache, 1) /= ns .OR. SIZE(sdv_cache, 2) /= n_ip) THEN
        DEALLOCATE(sdv_cache)
      END IF
    END IF
    IF (.NOT. ALLOCATED(sdv_cache)) ALLOCATE(sdv_cache(ns, n_ip))

    stress_cache(:, 1:n_ip) = stress_src(:, 1:n_ip)
    sdv_cache(:, 1:n_ip)    = sdv_src(:, 1:n_ip)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Cache_State

  !---------------------------------------------------------------------------
  ! Restore_Cache: restore state from cache (after cutback)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Restore_Cache(n_ip, stress_cache, sdv_cache, &
                                   stress_dst, sdv_dst, status)
    INTEGER(i4),           INTENT(IN)    :: n_ip
    REAL(wp),              INTENT(IN)    :: stress_cache(:,:)
    REAL(wp),              INTENT(IN)    :: sdv_cache(:,:)
    REAL(wp),              INTENT(INOUT) :: stress_dst(:,:)
    REAL(wp),              INTENT(INOUT) :: sdv_dst(:,:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. ALLOCATED(stress_cache) .OR. .NOT. ALLOCATED(sdv_cache)) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Restore_Cache] cache not allocated"
      RETURN
    END IF

    stress_dst(:, 1:n_ip) = stress_cache(:, 1:n_ip)
    sdv_dst(:, 1:n_ip)    = sdv_cache(:, 1:n_ip)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Restore_Cache

  !---------------------------------------------------------------------------
  ! Checkpoint: save state to persistent checkpoint (for restart)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Checkpoint(table, n_ip, stress, sdv, &
                                chk_stress, chk_sdv, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(IN)    :: table
    INTEGER(i4),                 INTENT(IN)    :: n_ip
    REAL(wp),                    INTENT(IN)    :: stress(:,:)
    REAL(wp),                    INTENT(IN)    :: sdv(:,:)
    REAL(wp), ALLOCATABLE,       INTENT(INOUT) :: chk_stress(:,:)
    REAL(wp), ALLOCATABLE,       INTENT(INOUT) :: chk_sdv(:,:)
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: nc, ns

    CALL init_error_status(status)

    IF (.NOT. table%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Checkpoint] table not initialized"
      RETURN
    END IF

    nc = SIZE(stress, 1)
    ns = SIZE(sdv, 1)

    IF (ALLOCATED(chk_stress)) THEN
      IF (SIZE(chk_stress, 1) /= nc .OR. SIZE(chk_stress, 2) /= n_ip) THEN
        DEALLOCATE(chk_stress)
      END IF
    END IF
    IF (.NOT. ALLOCATED(chk_stress)) ALLOCATE(chk_stress(nc, n_ip))

    IF (ALLOCATED(chk_sdv)) THEN
      IF (SIZE(chk_sdv, 1) /= ns .OR. SIZE(chk_sdv, 2) /= n_ip) THEN
        DEALLOCATE(chk_sdv)
      END IF
    END IF
    IF (.NOT. ALLOCATED(chk_sdv)) ALLOCATE(chk_sdv(ns, n_ip))

    chk_stress(:, 1:n_ip) = stress(:, 1:n_ip)
    chk_sdv(:, 1:n_ip)    = sdv(:, 1:n_ip)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Checkpoint

  !---------------------------------------------------------------------------
  ! Restore_Checkpoint: restore state from checkpoint (for restart)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Restore_Checkpoint(chk_stress, chk_sdv, n_ip, &
                                        stress, sdv, status)
    REAL(wp),              INTENT(IN)    :: chk_stress(:,:)
    REAL(wp),              INTENT(IN)    :: chk_sdv(:,:)
    INTEGER(i4),           INTENT(IN)    :: n_ip
    REAL(wp),              INTENT(INOUT) :: stress(:,:)
    REAL(wp),              INTENT(INOUT) :: sdv(:,:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    stress(:, 1:n_ip) = chk_stress(:, 1:n_ip)
    sdv(:, 1:n_ip)    = chk_sdv(:, 1:n_ip)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Restore_Checkpoint

  !---------------------------------------------------------------------------
  ! Alloc_StateVars: allocate stress/SDV arrays for n_ip integration points
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Alloc_StateVars(n_comp, n_sdv, n_ip, &
                                     stress, sdv, status)
    INTEGER(i4),           INTENT(IN)    :: n_comp  ! stress components (e.g. 6)
    INTEGER(i4),           INTENT(IN)    :: n_sdv   ! SDVs per IP
    INTEGER(i4),           INTENT(IN)    :: n_ip    ! integration points
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: stress(:,:)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: sdv(:,:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (n_comp <= 0_i4 .OR. n_ip <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Mat_Alloc_StateVars] invalid dimensions"
      RETURN
    END IF

    IF (ALLOCATED(stress)) DEALLOCATE(stress)
    IF (ALLOCATED(sdv))    DEALLOCATE(sdv)

    ALLOCATE(stress(n_comp, n_ip))
    stress = 0.0_wp

    IF (n_sdv > 0_i4) THEN
      ALLOCATE(sdv(n_sdv, n_ip))
      sdv = 0.0_wp
    ELSE
      ALLOCATE(sdv(1, n_ip))
      sdv = 0.0_wp
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Alloc_StateVars

  !---------------------------------------------------------------------------
  ! Dealloc_StateVars: deallocate stress/SDV arrays
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Dealloc_StateVars(stress, sdv, status)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: stress(:,:)
    REAL(wp), ALLOCATABLE, INTENT(INOUT) :: sdv(:,:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (ALLOCATED(stress)) DEALLOCATE(stress)
    IF (ALLOCATED(sdv))    DEALLOCATE(sdv)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Dealloc_StateVars

END MODULE RT_Mat_Core
