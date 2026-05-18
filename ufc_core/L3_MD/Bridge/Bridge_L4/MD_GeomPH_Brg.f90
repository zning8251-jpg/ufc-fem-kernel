!===============================================================================
! MODULE: MD_GeomPH_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L4
! ROLE:   Brg — Geometry L3→L4 bridge
! BRIEF:  Bridge L3_MD geometry context to L4_PH element context.
!===============================================================================

MODULE MD_GeomPH_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Geom_Def, ONLY: MD_Geom_Ctx, MD_Node_Desc, MD_Elem_Desc
  USE MD_Base_Def, ONLY: MD_MatCtrl_Type
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx
  USE MD_Mesh_API, ONLY: MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg, &
                                 MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg, &
                                 MD_Mesh_GetElemSection_Idx, MD_Mesh_GetElemSection_Arg
  USE MD_Sect_Domain, ONLY: MD_Section_GetSection_Idx, MD_Sect_Get_Arg
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_PH_Geom_FillElemCtx
  ! Index-based API (Phase 4 Bridge entity_idx migration)
  PUBLIC :: MD_PH_Geom_FillElemCtx_Idx
  PUBLIC :: MD_PH_Geom_FillElemCtx_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_PH_Geom_FillElemCtx_Arg
  ! KIND: Arg
  ! DESC: Arg bundle for FillElemCtx_Idx (elem_ctx + status)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_PH_Geom_FillElemCtx_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx
    TYPE(ErrorStatusType) :: status
  END TYPE MD_PH_Geom_FillElemCtx_Arg

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Geom_FillElemCtx
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Fill L4 element context from L3 geometry context (legacy)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Geom_FillElemCtx(geom_ctx, elem_id, elem_ctx, mat_ctrl)
    TYPE(MD_Geom_Ctx), INTENT(IN) :: geom_ctx
    INTEGER(i4), INTENT(IN) :: elem_id
    TYPE(PH_Elem_Ctx), INTENT(INOUT) :: elem_ctx
    TYPE(MD_MatCtrl_Type), INTENT(IN), OPTIONAL :: mat_ctrl
    INTEGER(i4) :: i, n_nodes, n_dim
    INTEGER(i4) :: inode, node_id
    INTEGER(i4) :: mat_id

    ! PH_Elem_Ctx_Init removed: PH_Elem_Ctx is now auto-initialized pure TYPE
    IF (.NOT. ALLOCATED(geom_ctx%elem_descs) .OR. elem_id < 1 .OR. elem_id > SIZE(geom_ctx%elem_descs)) RETURN
    IF (.NOT. ALLOCATED(geom_ctx%node_descs)) RETURN

    n_nodes = geom_ctx%elem_descs(elem_id)%pop%n_nodes
    n_dim = 3_i4
    IF (n_nodes <= 0) RETURN

    ALLOCATE(elem_ctx%coords(n_dim, n_nodes))
    elem_ctx%coords = 0.0_wp
    DO i = 1, n_nodes
      IF (ALLOCATED(geom_ctx%elem_descs(elem_id)%conn) .AND. i <= SIZE(geom_ctx%elem_descs(elem_id)%conn)) THEN
        node_id = geom_ctx%elem_descs(elem_id)%conn(i)
        IF (node_id >= 1 .AND. node_id <= SIZE(geom_ctx%node_descs)) THEN
          elem_ctx%coords(1:n_dim, i) = geom_ctx%node_descs(node_id)%coords(1:n_dim)
        END IF
      END IF
    END DO
    ! Elastic parameters: If mat_ctrl and element mat_id valid, get real values from L3 material
    elem_ctx%E_young = 1.0_wp
    elem_ctx%nu = 0.3_wp
    IF (PRESENT(mat_ctrl)) THEN
      mat_id = geom_ctx%elem_descs(elem_id)%mat_id
      IF (mat_id >= 1_i4 .AND. mat_ctrl%MatLib%nMats >= 1_i4 .AND. &
          ALLOCATED(mat_ctrl%MatLib%MatDefs) .AND. mat_id <= SIZE(mat_ctrl%MatLib%MatDefs)) THEN
        IF (ALLOCATED(mat_ctrl%MatLib%MatDefs(mat_id)%props) .AND. &
            SIZE(mat_ctrl%MatLib%MatDefs(mat_id)%props) >= 2_i4) THEN
          elem_ctx%E_young = mat_ctrl%MatLib%MatDefs(mat_id)%props(1)
          elem_ctx%nu = mat_ctrl%MatLib%MatDefs(mat_id)%props(2)
        END IF
      END IF
    END IF
    IF (ASSOCIATED(elem_ctx%evo%Ke)) DEALLOCATE(elem_ctx%evo%Ke)
    elem_ctx%is_initialized = .TRUE.
  END SUBROUTINE MD_PH_Geom_FillElemCtx

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_PH_Geom_FillElemCtx_Idx
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Fill L4 element context from L3_MD by entity_idx (Phase 4)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_PH_Geom_FillElemCtx_Idx(elem_idx, arg)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(MD_PH_Geom_FillElemCtx_Arg), INTENT(INOUT) :: arg

    INTEGER(i4) :: k, npe, n_dim
    INTEGER(i4) :: node_idx, section_idx, material_ref
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    TYPE(MD_Mesh_GetElemSection_Arg) :: arg_sect_elem
    TYPE(MD_Sect_Get_Arg) :: arg_sect
    TYPE(MD_Mat_GetDesc_Arg) :: arg_mat
    TYPE(ErrorStatusType) :: st

    CALL init_error_status(arg%status)
    ! PH_Elem_Ctx_Init removed: PH_Elem_Ctx is now auto-initialized pure TYPE

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%mesh%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Mesh not initialized"
      RETURN
    END IF

    CALL MD_Mesh_GetElemConnect_Idx(elem_idx, arg_conn, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      arg%status = st
      RETURN
    END IF

    npe = arg_conn%npe
    IF (npe <= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    n_dim = 3_i4
    arg%elem_ctx%element_id = elem_idx
    arg%elem_ctx%pop%n_nodes = npe
    arg%elem_ctx%n_dim = n_dim

    ! D2/HOT-003: Use fixed max size (3,8) to avoid DEALLOCATE+ALLOCATE when caller reuses arg
    ! If caller passes fresh arg each call, we allocate once with standard max; no realloc in loop
    IF (.NOT. ALLOCATED(arg%elem_ctx%coords) .OR. SIZE(arg%elem_ctx%coords,1) < 3_i4 .OR. &
        SIZE(arg%elem_ctx%coords,2) < 8_i4) THEN
      IF (ALLOCATED(arg%elem_ctx%coords)) DEALLOCATE(arg%elem_ctx%coords)
      ALLOCATE(arg%elem_ctx%coords(3_i4, 8_i4))
    END IF
    arg%elem_ctx%coords(1:n_dim, 1:npe) = 0.0_wp

    DO k = 1, npe
      node_idx = INT(arg_conn%connect(k), i4)
      IF (node_idx <= 0) EXIT
      CALL MD_Mesh_GetNodeCoords_Idx(node_idx, arg_coords, st)
      IF (st%status_code == IF_STATUS_OK) THEN
        arg%elem_ctx%coords(1:n_dim, k) = arg_coords%coords(1:n_dim)
      END IF
    END DO

    arg%elem_ctx%E_young = 1.0_wp
    arg%elem_ctx%nu = 0.3_wp

    CALL MD_Mesh_GetElemSection_Idx(elem_idx, arg_sect_elem, st)
    IF (st%status_code == IF_STATUS_OK .AND. arg_sect_elem%section_idx > 0_i4) THEN
      CALL MD_Section_GetSection_Idx(g_ufc_global%md_layer%desc%section, arg_sect_elem%section_idx, arg_sect, st)
      IF (st%status_code == IF_STATUS_OK) THEN
        material_ref = arg_sect%desc%material_ref
        IF (material_ref > 0_i4) THEN
          CALL MD_Mat_GetDesc_Idx(material_ref, arg_mat, st)
          IF (st%status_code == IF_STATUS_OK .AND. arg_mat%desc%pop%nProps >= 2_i4 .AND. &
              ALLOCATED(arg_mat%desc%props) .AND. SIZE(arg_mat%desc%props) >= 2_i4) THEN
            arg%elem_ctx%E_young = arg_mat%desc%props(1)
            arg%elem_ctx%nu = arg_mat%desc%props(2)
          END IF
        END IF
      END IF
    END IF

    arg%elem_ctx%is_initialized = .TRUE.
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_PH_Geom_FillElemCtx_Idx

END MODULE MD_GeomPH_Brg
