!===============================================================================
! MODULE: RT_Asm_Util
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Util
! BRIEF:  Assembly utilities -- scatter/gather, DOF mapping, CSR conversion
!===============================================================================

MODULE RT_Asm_Util
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE MD_Base_ElemLib, ONLY: UF_GetGaussPoints, UF_GetShapeFunctions, &
                                   UF_ComputeJacobian, ShapeFuncResult
  USE MD_Base_ObjModel, ONLY: UF_Part, UF_Element, UF_Node
  USE MD_Mesh_Elem_Types, ONLY: UF_TOPO_Hex, UF_TOPO_Tet, UF_TOPO_Quad, &
                                 UF_TOPO_Tri, UF_TOPO_Line
  USE MD_Model_Lib_Core, ONLY: UF_Model
  USE NM_Solv_LinDir, ONLY: CSR_Matrix
  USE RT_Solv_Def, ONLY: RT_CSRMatrix
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Mesh_Domain, ONLY: MD_Mesh_Domain
  
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! Public Interfaces
  !=============================================================================
  PUBLIC :: RT_Asm_ElemLoop_Info
  PUBLIC :: RT_Asm_GetElemInfo
  PUBLIC :: RT_Asm_GetElemDensity
  PUBLIC :: RT_Asm_GetElemDOFs
  PUBLIC :: RT_Asm_GetElemCoords
  PUBLIC :: RT_Asm_CSR_ToCSR
  PUBLIC :: RT_Asm_CSR_FromCSR
  
  !=============================================================================
  ! Element Loop Information Type
  !=============================================================================
  TYPE, PUBLIC :: RT_Asm_ElemLoop_Info
    INTEGER(i4) :: elem_id = 0
    INTEGER(i4) :: elem_type = 0
    INTEGER(i4) :: n_nodes = 0
    INTEGER(i4) :: n_dofs_per_node = 3  ! Default: 3 DOFs per node (x, y, z)
    INTEGER(i4) :: n_elem_dofs = 0
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: elem_dofs(:)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! (nDim, n_nodes)
    REAL(wp) :: density = 0.0_wp
    CHARACTER(LEN=32) :: elem_name = ""
    INTEGER(i4) :: topology = UF_TOPO_Hex
    INTEGER(i4) :: nDim = 3
  END TYPE RT_Asm_ElemLoop_Info
  
CONTAINS

  SUBROUTINE RT_Asm_CSR_FromCSR(csr, rt_csr, error)
    TYPE(CSR_Matrix), INTENT(IN) :: csr
    TYPE(RT_CSRMatrix), INTENT(OUT) :: rt_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    INTEGER(i4) :: i
    
    CALL init_error_status(error)
    
    ! Validate input
    IF (csr%n_rows <= 0 .OR. csr%n_cols <= 0) THEN
      CALL init_error_status(error, IF_STATUS_ERROR, "Invalid matrix dimensions")
      RETURN
    END IF
    
    ! Set dimensions
    rt_csr%nRows = INT(csr%n_rows, i4)
    rt_csr%nCols = INT(csr%n_cols, i4)
    rt_csr%nnz = INT(csr%n_nonzeros, i4)
    
    ! Allocate arrays
    IF (ALLOCATED(rt_csr%rowPtr)) DEALLOCATE(rt_csr%rowPtr)
    IF (ALLOCATED(rt_csr%colInd)) DEALLOCATE(rt_csr%colInd)
    IF (ALLOCATED(rt_csr%values)) DEALLOCATE(rt_csr%values)
    
    ALLOCATE(rt_csr%rowPtr(rt_csr%nRows + 1))
    ALLOCATE(rt_csr%colInd(rt_csr%nnz))
    ALLOCATE(rt_csr%values(rt_csr%nnz))
    
    ! Copy row pointer (convert INTEGER to i4)
    DO i = 1, SIZE(csr%row_ptr)
      rt_csr%rowPtr(i) = INT(csr%row_ptr(i), i4)
    END DO
    
    ! Copy column indices (convert INTEGER to i4)
    DO i = 1, SIZE(csr%col_idx)
      rt_csr%colInd(i) = INT(csr%col_idx(i), i4)
    END DO
    
    ! Copy values (convert DP to wp)
    DO i = 1, SIZE(csr%values)
      rt_csr%values(i) = REAL(csr%values(i), wp)
    END DO
    
    rt_csr%init = .true.
    rt_csr%is_symmetric = .false.  ! Default, can be set separately
    
  END SUBROUTINE RT_Asm_CSR_FromCSR

  SUBROUTINE RT_Asm_CSR_ToCSR(rt_csr, csr, error)
    TYPE(RT_CSRMatrix), INTENT(IN) :: rt_csr
    TYPE(CSR_Matrix), INTENT(OUT) :: csr
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    INTEGER(i4) :: i
    
    CALL init_error_status(error)
    
    ! Validate input
    IF (.NOT. rt_csr%init) THEN
      CALL init_error_status(error, IF_STATUS_ERROR, "RT_CSRMatrix not initialized")
      RETURN
    END IF
    
    IF (rt_csr%nRows <= 0 .OR. rt_csr%nCols <= 0) THEN
      CALL init_error_status(error, IF_STATUS_ERROR, "Invalid matrix dimensions")
      RETURN
    END IF
    
    ! Set dimensions
    csr%n_rows = rt_csr%nRows
    csr%n_cols = rt_csr%nCols
    csr%n_nonzeros = rt_csr%nnz
    
    ! Allocate arrays
    IF (ALLOCATED(csr%row_ptr)) DEALLOCATE(csr%row_ptr)
    IF (ALLOCATED(csr%col_idx)) DEALLOCATE(csr%col_idx)
    IF (ALLOCATED(csr%values)) DEALLOCATE(csr%values)
    
    ALLOCATE(csr%row_ptr(csr%n_rows + 1))
    ALLOCATE(csr%col_idx(csr%n_nonzeros))
    ALLOCATE(csr%values(csr%n_nonzeros))
    
    ! Copy row pointer (convert i4 to INTEGER)
    DO i = 1, SIZE(rt_csr%rowPtr)
      csr%row_ptr(i) = INT(rt_csr%rowPtr(i))
    END DO
    
    ! Copy column indices (convert i4 to INTEGER)
    DO i = 1, SIZE(rt_csr%colInd)
      csr%col_idx(i) = INT(rt_csr%colInd(i))
    END DO
    
    ! Copy values (convert wp to DP)
    DO i = 1, SIZE(rt_csr%values)
      csr%values(i) = REAL(rt_csr%values(i), wp)
    END DO
    
  END SUBROUTINE RT_Asm_CSR_ToCSR

  !=============================================================================
  ! RT_Asm_GetElemCoords - Get element node coordinates
  ! [L5-P0-2 fix 2026-03-15] L3 GetNodeCoords API
  !=============================================================================
  !> @brief Get element node coordinates from L3 mesh
  !! @param[in] model UF_Model reference
  !! @param[in] part_idx Part index
  !! @param[in] elem_idx Element index
  !! @param[in] nDim Spatial dimension
  !! @param[out] coords Node coordinates (nDim, n_nodes)
  !! @param[out] error Error status
  !!
  ! ! [Theory] X_i = (x_i, y_i, z_i) L3 Mesh
  !! [Logic] elem_idx �?L3 GetElemConnectivity �?L3 GetNodeCoords �?coords
  ! ! [Compute]
  ! ! [Data chain] L3 �?coords
  !=============================================================================
  SUBROUTINE RT_Asm_GetElemCoords(model, part_idx, elem_idx, nDim, coords, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: part_idx
    INTEGER(i4), INTENT(IN) :: elem_idx
    INTEGER(i4), INTENT(IN) :: nDim
    REAL(wp), INTENT(OUT), ALLOCATABLE :: coords(:,:)  ! (nDim, n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT) :: error

    INTEGER(i4) :: n_nodes, i, node_idx
    INTEGER(i8) :: conn(27)  ! Max 27 nodes for higher-order elements
    INTEGER(i4) :: npe, k
    REAL(wp) :: node_coords(3)

    CALL init_error_status(error)

    ! Check L3 mesh availability
    IF (.NOT. g_ufc_global%md_layer%mesh%initialized) THEN
      error%status_code = IF_STATUS_INVALID
      error%message = "RT_Asm_GetElemCoords: L3 mesh not initialized"
      RETURN
    END IF

    ! [L5-P0-2 fix 2026-03-15] Get element connectivity from L3 Mesh
    CALL g_ufc_global%md_layer%mesh%GetElemConnect(int(elem_idx, i8), conn, error)
    IF (error%status_code /= IF_STATUS_OK) THEN
      error%message = "RT_Asm_GetElemCoords: GetElemConnect failed"
      RETURN
    END IF

    ! Calculate number of valid nodes
    npe = 0_i4
    DO k = 1, 27
      IF (conn(k) <= 0_i8) EXIT
      npe = npe + 1_i4
    END DO
    n_nodes = npe

    ALLOCATE(coords(nDim, n_nodes))

    ! [L5-P0-2 fix 2026-03-15] Get coordinates from L3 Mesh nodes
    DO i = 1, n_nodes
      node_idx = INT(conn(i), i4)
      CALL g_ufc_global%md_layer%mesh%GetNodeCoords(int(conn(i), i8), node_coords, error)
      IF (error%status_code /= IF_STATUS_OK) THEN
        error%message = "RT_Asm_GetElemCoords: GetNodeCoords failed"
        DEALLOCATE(coords)
        RETURN
      END IF
      coords(1:min(nDim,3), i) = node_coords(1:min(nDim,3))
      IF (nDim > 3) coords(4:nDim, i) = 0.0_wp
    END DO

  END SUBROUTINE RT_Asm_GetElemCoords

  !=============================================================================
  ! RT_Asm_GetElemDensity - Get element material density
  ! [L5-P0-2 fix 2026-03-15] L3 Section/GetMaterialID API
  !=============================================================================
  !> @brief Get element material density from L3 Section/Material
  !! @param[in] model UF_Model reference
  !! @param[in] part_idx Part index
  !! @param[in] elem_idx Element index
  !! @param[out] density Material density
  !! @param[out] error Error status
  !!
  ! ! [Theory] ρ / L3 Material
  !! [Logic] elem_idx �?L3 Section GetMaterialId �?L3 Material GetDensity
  ! ! [Compute]
  ! ! [Data chain] L3 �?density
  !=============================================================================
  SUBROUTINE RT_Asm_GetElemDensity(model, part_idx, elem_idx, density, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: part_idx
    INTEGER(i4), INTENT(IN) :: elem_idx
    REAL(wp), INTENT(OUT) :: density
    TYPE(ErrorStatusType), INTENT(OUT) :: error

    INTEGER(i4) :: section_ref, material_ref
    TYPE(MD_Sect_Desc) :: sect_desc

    CALL init_error_status(error)

    ! Check L3 mesh availability
    IF (.NOT. g_ufc_global%md_layer%mesh%initialized) THEN
      error%status_code = IF_STATUS_INVALID
      error%message = "RT_Asm_GetElemDensity: L3 mesh not initialized"
      density = 7800.0_wp  ! Default: steel
      RETURN
    END IF

    ! [L5-P0-2 fix 2026-03-15] Get section_ref for element
    CALL g_ufc_global%md_layer%mesh%GetElemSection(int(elem_idx, i8), section_ref, error)
    IF (error%status_code /= IF_STATUS_OK .OR. section_ref <= 0) THEN
      ! Default to steel density if section not found
      density = 7800.0_wp
      RETURN
    END IF

    ! [L5-P0-2 fix pending] Get material_ref from section - TODO: full implementation
    ! For now, use placeholder density
    ! See module header.
    ! 1. g_ufc_global%md_layer%section%GetSection(section_ref, sect_desc)
    !   2. mat_id = sect_desc%mat_id
    ! 3. g_ufc_global%md_layer%material%GetMaterialProps(material_ref, 'DENSITY', density)
    density = 7800.0_wp  ! Steel density (kg/m³) - PLACEHOLDER

  END SUBROUTINE RT_Asm_GetElemDensity

  !=============================================================================
  ! RT_Asm_GetElemDOFs - Get element DOF indices
  ! [L5-P0-2 fix 2026-03-15] L3 Mesh/GetDOF API
  !=============================================================================
  !> @brief Get element DOF global indices from L3 Mesh
  !! @param[in] model UF_Model reference
  !! @param[in] part_idx Part index
  !! @param[in] elem_idx Element index
  !! @param[in] n_dofs_per_node DOFs per node
  !! @param[out] elem_dofs Global DOF indices
  !! @param[out] error Error status
  !!
  ! ! [Theory] u_e = {u_1, v_1, w_1, u_2, ...} L3 Mesh DOF
  ! ! [Logic] elem_idx �?L3 GetElemConnectivity �?L3 GetNodeDOF �?elem_dofs
  ! ! [Compute]
  ! ! [Data chain] L3 �?elem_dofs
  !=============================================================================
  SUBROUTINE RT_Asm_GetElemDOFs(model, part_idx, elem_idx, n_dofs_per_node, &
                                elem_dofs, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: part_idx
    INTEGER(i4), INTENT(IN) :: elem_idx
    INTEGER(i4), INTENT(IN) :: n_dofs_per_node
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: elem_dofs(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: error

    INTEGER(i4) :: n_nodes, n_elem_dofs, i, dof_idx
    INTEGER(i8) :: conn(27)
    INTEGER(i4) :: npe, k
    INTEGER(i4) :: global_dof_start, nDof_node

    CALL init_error_status(error)

    ! Check L3 mesh availability
    IF (.NOT. g_ufc_global%md_layer%mesh%initialized) THEN
      error%status_code = IF_STATUS_INVALID
      error%message = "RT_Asm_GetElemDOFs: L3 mesh not initialized"
      RETURN
    END IF

    ! Get element connectivity
    CALL g_ufc_global%md_layer%mesh%GetElemConnect(int(elem_idx, i8), conn, error)
    IF (error%status_code /= IF_STATUS_OK) THEN
      error%message = "RT_Asm_GetElemDOFs: GetElemConnect failed"
      RETURN
    END IF

    ! Calculate number of valid nodes
    npe = 0_i4
    DO k = 1, 27
      IF (conn(k) <= 0_i8) EXIT
      npe = npe + 1_i4
    END DO
    n_nodes = npe

    n_elem_dofs = n_nodes * n_dofs_per_node
    ALLOCATE(elem_dofs(n_elem_dofs))

    ! [L5-P0-2 fix 2026-03-15] Map node IDs to global DOF indices
    DO i = 1, n_nodes
      ! Get DOF mapping for this node
      CALL g_ufc_global%md_layer%mesh%GetDofMap(INT(conn(i), i4), global_dof_start, nDof_node, error)
      IF (error%status_code /= IF_STATUS_OK) THEN
        ! Fallback: assume contiguous DOFs
        global_dof_start = (INT(conn(i), i4) - 1_i4) * n_dofs_per_node + 1_i4
      END IF

      ! Map each DOF at this node
      DO dof_idx = 1, n_dofs_per_node
        elem_dofs((i-1)*n_dofs_per_node + dof_idx) = global_dof_start + dof_idx - 1_i4
      END DO
    END DO

  END SUBROUTINE RT_Asm_GetElemDOFs

  SUBROUTINE RT_Asm_GetElemInfo(model, part_idx, elem_idx, elem_info, error)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: part_idx
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(RT_Asm_ElemLoop_Info), INTENT(OUT) :: elem_info
    TYPE(ErrorStatusType), INTENT(OUT) :: error
    
    INTEGER(i4) :: i, node_idx, dof_idx
    TYPE(UF_Part), POINTER :: part_ptr
    TYPE(UF_Element), POINTER :: elem_ptr
    TYPE(UF_Node), POINTER :: node_ptr
    
    CALL init_error_status(error)
    
    ! TODO: Get part from model
    ! For now, placeholder implementation
    ! part_ptr => model%parts(part_idx)
    ! elem_ptr => part_ptr%elements(elem_idx)
    
    ! Initialize element info
    elem_info%elem_id = elem_idx
    elem_info%elem_type = 0  ! TODO: Get from element
    elem_info%pop%n_nodes = 8  ! Default: 8-node hex
    elem_info%nDim = 3
    
    ! Allocate arrays
    IF (ALLOCATED(elem_info%node_ids)) DEALLOCATE(elem_info%node_ids)
    IF (ALLOCATED(elem_info%elem_dofs)) DEALLOCATE(elem_info%elem_dofs)
    IF (ALLOCATED(elem_info%node_coords)) DEALLOCATE(elem_info%node_coords)
    
    ALLOCATE(elem_info%node_ids(elem_info%pop%n_nodes))
    ALLOCATE(elem_info%node_coords(elem_info%nDim, elem_info%pop%n_nodes))
    
    ! TODO: Get node IDs and coordinates from element
    ! DO i = 1, elem_info%n_nodes
    !   node_idx = elem_ptr%conn(i)
    !   elem_info%node_ids(i) = node_idx
    !   node_ptr => part_ptr%nodes(node_idx)
    !   elem_info%node_coords(:, i) = node_ptr%coords(1:elem_info%nDim)
    ! END DO
    
    ! Placeholder: initialize with zeros
    elem_info%node_ids = 0
    elem_info%node_coords = 0.0_wp
    
    ! Compute element DOFs
    elem_info%n_elem_dofs = elem_info%pop%n_nodes * elem_info%n_dofs_per_node
    ALLOCATE(elem_info%elem_dofs(elem_info%n_elem_dofs))
    
    ! TODO: Map node DOFs to element DOFs
    ! DO i = 1, elem_info%n_nodes
    !   DO dof_idx = 1, elem_info%n_dofs_per_node
    !     elem_info%elem_dofs((i-1)*elem_info%n_dofs_per_node + dof_idx) = ...
    !   END DO
    ! END DO
    
    elem_info%elem_dofs = 0  ! Placeholder
    
  END SUBROUTINE RT_Asm_GetElemInfo
END MODULE RT_Asm_Util