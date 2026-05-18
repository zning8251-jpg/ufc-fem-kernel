!===============================================================================
! MODULE: RT_Mat_Brg
! LAYER:  L5_RT
! DOMAIN: Material
! ROLE:   Brg — cross-layer bridge (BuildTable / MakeCtx / WriteBackHook)
! BRIEF:  Populates RT_Mat_Dispatch_Table from L4 PH_MatReg registry.
! **W1**：**`RT_Mat_Brg_BuildTable_FromMaterial`** 从 **`PH_Mat_Domain`** 槽读 **`PH_Mat_Desc`**，经
!         **`PH_Mat_Desc_Effective_Model`**、**`desc%cfg%matId`** 填 **路由表**；**`RT_Mat_Dispatch_Ctx%mat_type`**
!         与 L4 **`PH_Mat_Core`** 族金线一致。
!===============================================================================
MODULE RT_Mat_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_Mat_Def, ONLY: RT_Mat_Dispatch_Table, RT_Mat_Dispatch_Ctx, &
                              RT_Mat_Route_Entry, RT_MAT_TABLE_MAX, &
                              RT_MAT_ROUTE_OK
  USE PH_Mat_Def, ONLY: PH_Mat_Domain, PH_MAT_USER, PH_MAT_USER_VUMAT
  USE PH_Mat_Core, ONLY: PH_Mat_Desc_Effective_Model
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Brg_BuildTable
  PUBLIC :: RT_Mat_Brg_BuildTable_FromMaterial
  PUBLIC :: RT_Mat_Brg_MakeCtx
  PUBLIC :: RT_Mat_Brg_WriteBackHook

CONTAINS

  !---------------------------------------------------------------------------
  ! BuildTable: populate dispatch table from L4 material registry info.
  !
  ! Called once per step during Populate phase.
  ! Receives arrays of (mat_type, mat_id, slot_idx, is_user) from
  ! the L4 Populate layer, and fills the L5 routing table.
  !
  ! Parameters:
  !   table     [INOUT] - L5 dispatch table to populate
  !   n_mats    [IN]    - number of materials to register
  !   mat_types [IN]    - array of L4 MAT_* constants
  !   mat_ids   [IN]    - array of L3 material IDs
  !   slot_idxs [IN]    - array of L4 slot_pool indices
  !   is_users  [IN]    - array of UMAT/VUMAT flags
  !   status    [OUT]   - error status
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Brg_BuildTable(table, n_mats, mat_types, mat_ids, &
                                    slot_idxs, is_users, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(INOUT) :: table
    INTEGER(i4),                 INTENT(IN)    :: n_mats
    INTEGER(i4),                 INTENT(IN)    :: mat_types(:)
    INTEGER(i4),                 INTENT(IN)    :: mat_ids(:)
    INTEGER(i4),                 INTENT(IN)    :: slot_idxs(:)
    LOGICAL,                     INTENT(IN)    :: is_users(:)
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    INTEGER(i4) :: i, n_to_fill

    CALL init_error_status(status)

    IF (.NOT. table%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Brg_BuildTable] table not initialized"
      RETURN
    END IF

    n_to_fill = MIN(n_mats, RT_MAT_TABLE_MAX - table%n_entries)

    DO i = 1, n_to_fill
      table%n_entries = table%n_entries + 1_i4
      table%entries(table%n_entries)%mat_type   = mat_types(i)
      table%entries(table%n_entries)%mat_id     = mat_ids(i)
      table%entries(table%n_entries)%mat_pt_idx = slot_idxs(i)
      table%entries(table%n_entries)%is_user    = is_users(i)
      table%entries(table%n_entries)%active     = .TRUE.
    END DO

    IF (n_mats > n_to_fill) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Brg_BuildTable] table overflow, some mats not registered"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Brg_BuildTable

  !---------------------------------------------------------------------------
  ! BuildTable_FromMaterial: derive L5 routing entries from populated L4 slots.
  !
  ! This is the P1 Material pillar handoff after PH_L4_Populate_Material:
  !   L3 Desc -> L4 slot_pool -> L5 RT_Mat_Dispatch_Table.
  ! L5 stores only route metadata, not Material Desc or IP State.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Brg_BuildTable_FromMaterial(table, material_dom, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(INOUT) :: table
    TYPE(PH_Mat_Domain),         INTENT(IN)    :: material_dom
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    INTEGER(i4) :: i, ph_m, mid
    LOGICAL :: is_user

    CALL init_error_status(status)

    IF (.NOT. table%initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Brg_BuildTable_FromMaterial] table not initialized"
      RETURN
    END IF
    IF (.NOT. material_dom%initialized .OR. .NOT. ALLOCATED(material_dom%slot_pool)) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "[RT_Mat_Brg_BuildTable_FromMaterial] material domain not initialized"
      RETURN
    END IF

    DO i = 1, material_dom%pool_count
      IF (.NOT. material_dom%slot_pool(i)%active) CYCLE
      mid = material_dom%slot_pool(i)%desc%cfg%matId
      IF (mid <= 0_i4) CYCLE
      ph_m = PH_Mat_Desc_Effective_Model(material_dom%slot_pool(i)%desc)
      IF (ph_m <= 0_i4) CYCLE
      IF (table%n_entries >= RT_MAT_TABLE_MAX) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "[RT_Mat_Brg_BuildTable_FromMaterial] table full"
        RETURN
      END IF

      is_user = (ph_m == PH_MAT_USER .OR. ph_m == PH_MAT_USER_VUMAT)
      table%n_entries = table%n_entries + 1_i4
      table%entries(table%n_entries)%mat_type = ph_m
      table%entries(table%n_entries)%mat_id = mid
      table%entries(table%n_entries)%mat_pt_idx = i
      table%entries(table%n_entries)%is_user = is_user
      table%entries(table%n_entries)%active = .TRUE.
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Brg_BuildTable_FromMaterial

  !---------------------------------------------------------------------------
  ! MakeCtx: build a dispatch context from a table entry for a given mat_id.
  !
  ! Used by element loop to obtain routing info before calling L4.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Brg_MakeCtx(table, mat_id, ctx, status)
    TYPE(RT_Mat_Dispatch_Table), INTENT(IN)  :: table
    INTEGER(i4),                 INTENT(IN)  :: mat_id
    TYPE(RT_Mat_Dispatch_Ctx),   INTENT(OUT) :: ctx
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, table%n_entries
      IF (table%entries(i)%active .AND. table%entries(i)%mat_id == mat_id) THEN
        ctx%mat_type    = table%entries(i)%mat_type
        ctx%mat_id      = mat_id
        ctx%mat_pt_idx  = table%entries(i)%mat_pt_idx
        ctx%is_user_sub = table%entries(i)%is_user
        ctx%route_status = RT_MAT_ROUTE_OK
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    ctx%mat_type     = 0_i4
    ctx%mat_id       = mat_id
    ctx%mat_pt_idx   = 0_i4
    ctx%is_user_sub  = .FALSE.
    ctx%route_status = -1_i4
    status%status_code = IF_STATUS_ERROR
    status%message = "[RT_Mat_Brg_MakeCtx] mat_id not found"
  END SUBROUTINE RT_Mat_Brg_MakeCtx

  !---------------------------------------------------------------------------
  ! WriteBackHook: diagnostic/filter before stress commit to L3.
  !
  ! Called by RT_WBDomain after convergence, before data flows back to L3.
  ! Currently a pass-through; future: add NaN checks, logging, filtering.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Brg_WriteBackHook(ctx, stress, n_comp, status)
    TYPE(RT_Mat_Dispatch_Ctx), INTENT(IN)    :: ctx
    REAL(wp),                  INTENT(IN)    :: stress(:)
    INTEGER(i4),               INTENT(IN)    :: n_comp
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! NaN guard on stress before commit
    DO i = 1, MIN(n_comp, SIZE(stress))
      IF (stress(i) /= stress(i)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "[RT_Mat_Brg_WriteBackHook] NaN in stress"
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Brg_WriteBackHook

END MODULE RT_Mat_Brg
