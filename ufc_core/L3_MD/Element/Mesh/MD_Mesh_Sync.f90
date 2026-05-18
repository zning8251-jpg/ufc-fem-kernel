!===============================================================================
! MODULE:  MD_Mesh_Sync
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Sync
! BRIEF:   Mesh sync — P1 Sync/Verify: legacy UF_AssemblyDef to
!          MD_Mesh_Domain raw_data.
!===============================================================================
!
! Design: MESH_DOMAIN_DESIGN.md ?? ?12.2
!   - Legacy: model_def%assembly%global_coords, global_conn, global_elem_type
!   - New:    md_layer%mesh%raw_data (MeshData)
!
! Call: After assembly%assemble completes (ModelBuilder, UF_register_model).
!   CALL MD_Mesh_SyncFromLegacy(model_def, md_layer, status)
!
! Note: MeshData supports up to 27 nodes/element (MD_MESH_MAX_NODES_PER_ELEM).
!       Full connectivity copied from assembly%global_conn.
!
! Status: Phase B | Last verified: 2026-03-11
! Theory: N/A
!======================================================================
!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Sync | FuncSet:Sync | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Sync | FuncSet:Sync | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Mesh_Sync
  USE IF_Prec_Core,    ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mesh_Data,      ONLY: MeshData, MD_MESH_MAX_NODES_PER_ELEM
  USE MD_Mesh_API, ONLY: MD_Mesh_Domain
  USE MD_Mesh_GlobalNum, ONLY: GlobalNum_BuildFromFlat
  USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
  USE MD_Model_Lib_Core,     ONLY: UF_ModelDef
  USE MD_Asm_Sync,      ONLY: UF_AssemblyDef
  USE MD_Sect_Lib,   ONLY: UF_SectionDef, UF_SectionDBType
  USE MD_Sets_Mgr,      ONLY: UF_ElemSet
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mesh_SyncFromLegacy

CONTAINS

  !====================================================================
  ! MD_Mesh_SyncFromLegacy
  ! Sync assembly%global_coords, global_conn, global_elem_type ??mesh%raw_data
  !====================================================================
  SUBROUTINE MD_Mesh_SyncFromLegacy(model_def, md_layer, status)
    TYPE(UF_ModelDef),          INTENT(INOUT) :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i8) :: nNodes, nElems
    INTEGER(i4) :: spatial_dim, conn_rows, max_npe
    INTEGER(i8) :: i, e

    CALL init_error_status(status)
    IF (.NOT. md_layer%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_MeshSync_Algo: md_layer not initialized"
      RETURN
    END IF

    nNodes = INT(model_def%assembly%total_nodes, i8)
    nElems = INT(model_def%assembly%total_elements, i8)
    spatial_dim = model_def%dimension
    IF (spatial_dim <= 0) spatial_dim = 3_i4

    IF (nNodes <= 0_i8 .OR. nElems <= 0_i8) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (.NOT. ALLOCATED(model_def%assembly%global_coords) .OR. &
        .NOT. ALLOCATED(model_def%assembly%global_conn)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "MD_MeshSync_Algo: assembly global arrays not allocated"
      RETURN
    END IF

    ! Re-init mesh with correct sizes (Finalize if already initialized)
    IF (md_layer%mesh%initialized) THEN
      CALL md_layer%mesh%Finalize()
    END IF

    conn_rows = SIZE(model_def%assembly%global_conn, 1)
    max_npe = MIN(conn_rows, MD_MESH_MAX_NODES_PER_ELEM)
    CALL md_layer%mesh%Init(nNodes, nElems, spatial_dim, status, max_nodes_per_elem=max_npe)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Copy node coordinates
    DO i = 1_i8, nNodes
      CALL md_layer%mesh%raw_data%SetNodeCoords(i, &
        model_def%assembly%global_coords(1:spatial_dim, INT(i, i4)), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    ! Copy element connectivity (full, up to 27 nodes per element)
    DO e = 1_i8, nElems
      CALL md_layer%mesh%raw_data%SetElementConnectivity(e, &
        INT(model_def%assembly%global_conn(1:max_npe, INT(e, i4)), i8), status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    ! Copy element types
    IF (ALLOCATED(model_def%assembly%global_elem_type)) THEN
      IF (SIZE(model_def%assembly%global_elem_type) >= INT(nElems, i4)) THEN
        md_layer%mesh%raw_data%element_types(1:INT(nElems, i4)) = &
          model_def%assembly%global_elem_type(1:INT(nElems, i4))
      END IF
    END IF

    ! Build global numbering from flat mesh data (??A)
    CALL GlobalNum_BuildFromFlat(nNodes, nElems, &
         md_layer%mesh%raw_data%element_connect, md_layer%mesh%global_num, &
         status=status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Populate elem_section_ref from section_db + assembly elem_sets (MD_MESH_ELEMENT_INDEX_FLAT_MIGRATION Phase A)
    CALL Mesh_Sync_PopulateElemSectionRef(model_def, md_layer, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Eliminate dual-track: release assembly global_* after sync, keep index tree only
    CALL model_def%assembly%release_global_arrays()

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Mesh_SyncFromLegacy

  !====================================================================
  ! Mesh_Sync_PopulateElemSectionRef
  ! Populate raw_data%elem_section_ref from section_db (elset_name) and
  ! assembly elem_sets. Section index i -> elem_section_ref(elem_id) = i.
  !====================================================================
  SUBROUTINE Mesh_Sync_PopulateElemSectionRef(model_def, md_layer, status)
    TYPE(UF_ModelDef),          INTENT(IN)    :: model_def
    TYPE(MD_L3_LayerContainer), INTENT(INOUT) :: md_layer
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, k, nsec, n_esets, n_elems
    CHARACTER(LEN=80) :: elset_name

    CALL init_error_status(status)
    IF (.NOT. md_layer%mesh%initialized) RETURN
    IF (.NOT. ALLOCATED(md_layer%mesh%raw_data%elem_section_ref)) RETURN

    nsec = model_def%section_db%num_sections
    IF (nsec <= 0 .OR. .NOT. ALLOCATED(model_def%section_db%sections)) RETURN

    n_esets = model_def%assembly%num_elem_sets
    IF (n_esets <= 0 .OR. .NOT. ALLOCATED(model_def%assembly%elem_sets)) RETURN

    n_elems = INT(md_layer%mesh%raw_data%nElems, i4)

    DO i = 1, MIN(nsec, SIZE(model_def%section_db%sections))
      elset_name = TRIM(model_def%section_db%sections(i)%elset_name)
      IF (LEN_TRIM(elset_name) == 0) CYCLE

      DO j = 1, n_esets
        IF (j > SIZE(model_def%assembly%elem_sets)) EXIT
        IF (TRIM(model_def%assembly%elem_sets(j)%name) /= TRIM(elset_name) .AND. &
            INDEX(TRIM(model_def%assembly%elem_sets(j)%name), "." // TRIM(elset_name)) <= 0) CYCLE

        IF (.NOT. ALLOCATED(model_def%assembly%elem_sets(j)%elem_ids)) CYCLE
        DO k = 1, model_def%assembly%elem_sets(j)%num_elems
          IF (k > SIZE(model_def%assembly%elem_sets(j)%elem_ids)) EXIT
          IF (model_def%assembly%elem_sets(j)%elem_ids(k) >= 1 .AND. &
              model_def%assembly%elem_sets(j)%elem_ids(k) <= n_elems) THEN
            md_layer%mesh%raw_data%elem_section_ref(model_def%assembly%elem_sets(j)%elem_ids(k)) = i
          END IF
        END DO
        EXIT
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE Mesh_Sync_PopulateElemSectionRef

END MODULE MD_Mesh_Sync