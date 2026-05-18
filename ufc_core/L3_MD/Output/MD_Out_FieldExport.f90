!======================================================================
! Module: MD_OutFieldExport
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Field Export
! Purpose: Export field data (U/S/PEEQ) from Model tree for Output.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Out_FieldExport
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md
!> Status: Production | Last verified: 2026-03-01
!> Theory: Field output export (VTK/HDF5/ODB) | Ref: VTK File Format Spec
  use IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                  IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  use IF_Prec_Core, only: wp, i4
  ! Model core types
  use MD_Asm_Sync, only: UF_AssemblyDef
  use MD_Field_Mgr, only: MD_NodalField, MD_ElemIPData
  use MD_Model_Mgr, only: UF_ModelDef
  use UFC_GlobalContainer_Core, only: g_ufc_global
  use MD_Mesh_API, only: MD_Mesh_IsAvailable
  USE MD_Mesh_API, only: MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg, &
                                 MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg

  implicit none
  private

  public :: MD_Out_ExportField
  public :: MD_Out_GetNodeCoords
  public :: MD_Out_GetElemConnectivity

  ! Variable ID constants (match MD_OutVarReg)
  integer(i4), parameter, public :: VAR_ID_U     = 1   ! displacement
  integer(i4), parameter, public :: VAR_ID_V     = 2   ! velocity
  integer(i4), parameter, public :: VAR_ID_A     = 3   ! acceleration
  integer(i4), parameter, public :: VAR_ID_S     = 10  ! stress
  integer(i4), parameter, public :: VAR_ID_E     = 11  ! strain
  integer(i4), parameter, public :: VAR_ID_PEEQ  = 14  ! equiv. plastic strain

  ! Output position enum (match MD_Out)
  integer(i4), parameter, public :: OUT_POS_NODE         = 1
  integer(i4), parameter, public :: OUT_POS_INT_POINT    = 2
  integer(i4), parameter, public :: OUT_POS_CENTROID     = 3

  ! Region type enum
  integer(i4), parameter, public :: REGION_TYPE_WHOLE   = 0
  integer(i4), parameter, public :: REGION_TYPE_NSET    = 1
  integer(i4), parameter, public :: REGION_TYPE_ELSET   = 2

contains

  subroutine MD_Out_ExportField(model, var_id, region_type, region_name, &
                                 position, n_points, point_ids, data, status)
    !! Extract field variable from Model to Output
    !!
    !! Strategy:
    !!   1. select type(model) to get UF_ModelDef
    !!   2. Resolve node/elem set from region_type/region_name
    !!   3. By var_id and position:
    !!      - U (VAR_ID_U): field_mgr%get_field("U")%values(:, node_ids)
    !!      - S (VAR_ID_S): elem_states%sigma interpolate to nodes (TODO)
    !! - PEEQ (VAR_ID_PEEQ): elem_states%ip_states%sdv(PEEQ_IDX) (TODO) ?TODO)
    !!   4. Fill n_points, point_ids, data
    
    type(*), intent(in) :: model
    integer(i4), intent(in) :: var_id, region_type, position
    character(len=*), intent(in) :: region_name
    integer(i4), intent(out) :: n_points
    integer(i4), intent(inout) :: point_ids(:)
    real(wp), intent(inout) :: data(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, comp, nset_idx, n_total_nodes, n_total_elems
    logical :: found
    type(MD_NodalField), pointer :: field_ptr

    call init_error_status(status)
    n_points = 0

    select type(m => model)
    type is (UF_ModelDef)
      ! Mesh : md_layer%mesh ?assembly
      if (g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized) then
        n_total_nodes = int(g_ufc_global%md_layer%mesh%desc%nNodes, i4)
        n_total_elems = int(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
      else
        n_total_nodes = m%assembly%total_nodes
        n_total_elems = m%assembly%total_elements
      end if
      
      ! =========================================================================
      ! VAR_ID_U: displacement field (from field_mgr)
      ! =========================================================================
      if (var_id == VAR_ID_U) then
        
        ! Get displacement field
        field_ptr => m%field_mgr%get_field("U")
        if (.not. associated(field_ptr)) then
          status%status_code = IF_STATUS_NOT_FOUND
          status%message = 'MD_Out_ExportField: displacement field "U" not found'
          return
        end if
        
        if (field_ptr%num_components /= 3) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: displacement field must have 3 components'
          return
        end if
        
        ! Resolve target nodes by region type
        if (region_type == REGION_TYPE_WHOLE) then
          ! Whole model: all nodes
          n_points = n_total_nodes
          if (n_points > size(point_ids)) then
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Out_ExportField: point_ids array too small'
            return
          end if
          
          do i = 1, n_points
            point_ids(i) = i
            do comp = 1, 3
              data(comp, i) = field_ptr%values(comp, i)
            end do
          end do
          
        else if (region_type == REGION_TYPE_NSET) then
          ! Node set: lookup by name
          found = .false.
          do j = 1, m%assembly%nNodeSets
            if (trim(m%assembly%node_sets(j)%name) == trim(region_name)) then
              found = .true.
              nset_idx = j
              exit
            end if
          end do
          
          if (.not. found) then
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = 'MD_Out_ExportField: node set not found: ' // trim(region_name)
            return
          end if
          
          n_points = m%assembly%node_sets(nset_idx)%nNodes
          if (n_points > size(point_ids)) then
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Out_ExportField: point_ids array too small'
            return
          end if
          
          do i = 1, n_points
            point_ids(i) = m%assembly%node_sets(nset_idx)%node_ids(i)
            do comp = 1, 3
              data(comp, i) = field_ptr%values(comp, point_ids(i))
            end do
          end do
          
        else
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: unsupported region type for U'
          return
        end if
        
      ! =========================================================================
      ! VAR_ID_S: stress field (interpolate from elem IP to nodes)
      ! =========================================================================
      else if (var_id == VAR_ID_S) then
        
        ! Simple average interpolation: node stress = avg of IP stress from adjacent elems
        
        integer(i4) :: elem_id, node_id, local_node_idx, ip, nip
        integer(i4) :: n_target_nodes, target_node_idx
        integer(i4), allocatable :: target_node_ids(:)
        real(wp), allocatable :: node_stress_sum(:,:)  ! (6, n_nodes)
        integer(i4), allocatable :: node_elem_count(:)  ! contrib elem count per node
        integer(i4) :: max_nodes_per_elem, elem_node_id
        type(MD_ElemIPData), pointer :: elem_state_ptr
        logical :: is_target_node
        
        ! 1. Resolve target node set
        if (region_type == REGION_TYPE_WHOLE) then
          n_target_nodes = n_total_nodes
        else if (region_type == REGION_TYPE_NSET) then
          found = .false.
          do j = 1, m%assembly%nNodeSets
            if (trim(m%assembly%node_sets(j)%name) == trim(region_name)) then
              found = .true.
              nset_idx = j
              exit
            end if
          end do
          if (.not. found) then
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = 'MD_Out_ExportField: node set not found for sigma: ' // trim(region_name)
            return
          end if
          n_target_nodes = m%assembly%node_sets(nset_idx)%nNodes
        else
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: unsupported region type for S'
          return
        end if
        
        if (n_target_nodes > size(point_ids)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: point_ids array too small for sigma'
          return
        end if
        
        ! 2. Alloc target node ID list
        allocate(target_node_ids(n_target_nodes))
        if (region_type == REGION_TYPE_WHOLE) then
          do i = 1, n_target_nodes
            target_node_ids(i) = i
          end do
        else
          target_node_ids = m%assembly%node_sets(nset_idx)%node_ids(1:n_target_nodes)
        end if
        
        ! 3. Init accumulators (mesh )
        allocate(node_stress_sum(6, n_total_nodes))
        allocate(node_elem_count(n_total_nodes))
        node_stress_sum = 0.0_wp
        node_elem_count = 0
        
        ! 4. Loop elems, accumulate IP stress to nodes ( ? ? mesh )
        if (.not. MD_Mesh_IsAvailable()) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: mesh not available for S export'
          return
        end if
        max_nodes_per_elem = 27
        do elem_id = 1, n_total_elems
          elem_state_ptr => m%field_mgr%get_elem_state(elem_id)
          if (.not. associated(elem_state_ptr)) cycle
          nip = elem_state_ptr%nIntPoints
          if (nip <= 0) cycle
          real(wp) :: elem_avg_stress(6)
          elem_avg_stress = 0.0_wp
          do ip = 1, nip
            do comp = 1, 6
              elem_avg_stress(comp) = elem_avg_stress(comp) + elem_state_ptr%sigma(comp, ip)
            end do
          end do
          elem_avg_stress = elem_avg_stress / real(nip, wp)
          do local_node_idx = 1, max_nodes_per_elem
            elem_node_id = int(g_ufc_global%md_layer%mesh%raw_data%element_connect(local_node_idx, elem_id), i4)
            if (elem_node_id <= 0) exit
            do comp = 1, 6
              node_stress_sum(comp, elem_node_id) = node_stress_sum(comp, elem_node_id) + elem_avg_stress(comp)
            end do
            node_elem_count(elem_node_id) = node_elem_count(elem_node_id) + 1
          end do
        end do
        
        ! 5. Normalize and fill output
        n_points = n_target_nodes
        do i = 1, n_target_nodes
          node_id = target_node_ids(i)
          point_ids(i) = node_id
          
          if (node_elem_count(node_id) > 0) then
            do comp = 1, 6
              data(comp, i) = node_stress_sum(comp, node_id) / real(node_elem_count(node_id), wp)
            end do
          else
            ! Isolated node, stress zero
            data(:, i) = 0.0_wp
          end if
        end do
        
        deallocate(target_node_ids, node_stress_sum, node_elem_count)
        
      ! =========================================================================
      ! VAR_ID_PEEQ: equiv plastic strain (from SDV, interpolate)
      ! =========================================================================
      else if (var_id == VAR_ID_PEEQ) then
        
        ! PEEQ extraction (similar to stress interpolation)
        ! Node PEEQ = avg of IP PEEQ from adjacent elems
        ! 
        ! Note: PEEQ in SDV at index 1 (PEEQ_IDX=1)
        ! Index may depend on material model
        
        integer(i4), parameter :: PEEQ_SDV_IDX = 1  ! PEEQ index in SDV
        integer(i4) :: elem_id, node_id, local_node_idx, ip, nip
        integer(i4) :: n_target_nodes
        integer(i4), allocatable :: target_node_ids(:)
        real(wp), allocatable :: node_peeq_sum(:)     ! (n_nodes)
        integer(i4), allocatable :: node_elem_count(:) ! Contrib elem count per node
        integer(i4) :: max_nodes_per_elem, elem_node_id
        type(MD_ElemIPData), pointer :: elem_state_ptr
        real(wp) :: elem_avg_peeq
        
        ! 1. Resolve target node set
        if (region_type == REGION_TYPE_WHOLE) then
          n_target_nodes = n_total_nodes
        else if (region_type == REGION_TYPE_NSET) then
          found = .false.
          do j = 1, m%assembly%nNodeSets
            if (trim(m%assembly%node_sets(j)%name) == trim(region_name)) then
              found = .true.
              nset_idx = j
              exit
            end if
          end do
          if (.not. found) then
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = 'MD_Out_ExportField: node set not found for PEEQ: ' // trim(region_name)
            return
          end if
          n_target_nodes = m%assembly%node_sets(nset_idx)%nNodes
        else
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: unsupported region type for PEEQ'
          return
        end if
        
        if (n_target_nodes > size(point_ids)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: point_ids array too small for PEEQ'
          return
        end if
        
        ! 2. Alloc target node ID list
        allocate(target_node_ids(n_target_nodes))
        if (region_type == REGION_TYPE_WHOLE) then
          do i = 1, n_target_nodes
            target_node_ids(i) = i
          end do
        else
          target_node_ids = m%assembly%node_sets(nset_idx)%node_ids(1:n_target_nodes)
        end if
        
        ! 3. Init accumulators (mesh )
        allocate(node_peeq_sum(n_total_nodes))
        allocate(node_elem_count(n_total_nodes))
        node_peeq_sum = 0.0_wp
        node_elem_count = 0
        
        ! 4. Loop elems, accumulate IP PEEQ to nodes ( ? ? mesh )
        if (.not. MD_Mesh_IsAvailable()) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_ExportField: mesh not available for PEEQ export'
          return
        end if
        max_nodes_per_elem = 27
        do elem_id = 1, n_total_elems
          elem_state_ptr => m%field_mgr%get_elem_state(elem_id)
          if (.not. associated(elem_state_ptr)) cycle
          nip = elem_state_ptr%nIntPoints
          if (nip <= 0) cycle
          elem_avg_peeq = 0.0_wp
          do ip = 1, nip
            if (elem_state_ptr%num_sdv >= PEEQ_SDV_IDX) then
              elem_avg_peeq = elem_avg_peeq + elem_state_ptr%sdv(PEEQ_SDV_IDX, ip)
            end if
          end do
          elem_avg_peeq = elem_avg_peeq / real(nip, wp)
          do local_node_idx = 1, max_nodes_per_elem
            elem_node_id = int(g_ufc_global%md_layer%mesh%raw_data%element_connect(local_node_idx, elem_id), i4)
            if (elem_node_id <= 0) exit
            node_peeq_sum(elem_node_id) = node_peeq_sum(elem_node_id) + elem_avg_peeq
            node_elem_count(elem_node_id) = node_elem_count(elem_node_id) + 1
          end do
        end do
        
        ! 5. Normalize and fill output
        n_points = n_target_nodes
        do i = 1, n_target_nodes
          node_id = target_node_ids(i)
          point_ids(i) = node_id
          
          if (node_elem_count(node_id) > 0) then
            data(1, i) = node_peeq_sum(node_id) / real(node_elem_count(node_id), wp)
          else
            ! Isolated node, PEEQ zero
            data(1, i) = 0.0_wp
          end if
        end do
        
        deallocate(target_node_ids, node_peeq_sum, node_elem_count)
        
      else
        status%status_code = IF_STATUS_INVALID
        status%message = 'MD_Out_ExportField: unsupported variable ID'
        return
      end if
      
    class default
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_Out_ExportField: model type not UF_ModelDef'
      return
    end select

    status%status_code = IF_STATUS_OK

  end subroutine MD_Out_ExportField

  subroutine MD_Out_GetElemConnectivity(model, region_type, region_name, &
                                         n_elems, elem_ids, connectivity, &
                                         elem_types, status)
    !! Get elem conn ( ? ? md_layer%mesh)

    type(*), intent(in) :: model
    integer(i4), intent(in) :: region_type
    character(len=*), intent(in) :: region_name
    integer(i4), intent(out) :: n_elems
    integer(i4), intent(inout) :: elem_ids(:)
    integer(i4), intent(inout) :: connectivity(:,:)
    integer(i4), intent(inout) :: elem_types(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, eset_idx, npe
    logical :: found
    type(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    type(ErrorStatusType) :: conn_status

    call init_error_status(status)
    n_elems = 0

    select type(m => model)
    type is (UF_ModelDef)
      
      if (region_type == REGION_TYPE_WHOLE) then
        if (.not. MD_Mesh_IsAvailable()) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetElemConnectivity: mesh not available'
          return
        end if
        n_elems = int(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
        if (n_elems > size(elem_ids)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetElemConnectivity: elem_ids array too small'
          return
        end if
        do i = 1, n_elems
          elem_ids(i) = i
          call MD_Mesh_GetElemConnect_Idx(i, arg_conn, conn_status)
          if (conn_status%status_code == IF_STATUS_OK) then
            npe = min(arg_conn%npe, size(connectivity, 1))
            do k = 1, npe
              connectivity(k, i) = int(arg_conn%connect(k), i4)
            end do
            do k = npe + 1, size(connectivity, 1)
              connectivity(k, i) = 0_i4
            end do
          end if
          elem_types(i) = g_ufc_global%md_layer%mesh%raw_data%element_types(i)
        end do

      else if (region_type == REGION_TYPE_ELSET) then
        ! Elem set: lookup by name
        found = .false.
        do j = 1, m%assembly%nElemSets
          if (trim(m%assembly%elem_sets(j)%name) == trim(region_name)) then
            found = .true.
            eset_idx = j
            exit
          end if
        end do
        
        if (.not. found) then
          status%status_code = IF_STATUS_NOT_FOUND
          status%message = 'MD_Out_GetElemConnectivity: elem set not found: ' // trim(region_name)
          return
        end if
        
        n_elems = m%assembly%elem_sets(eset_idx)%num_elems
        if (n_elems > size(elem_ids)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetElemConnectivity: elem_ids array too small'
          return
        end if
        
        if (.not. MD_Mesh_IsAvailable()) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetElemConnectivity: mesh not available'
          return
        end if
        do i = 1, n_elems
          elem_ids(i) = m%assembly%elem_sets(eset_idx)%elem_ids(i)
          call MD_Mesh_GetElemConnect_Idx(elem_ids(i), arg_conn, conn_status)
          if (conn_status%status_code == IF_STATUS_OK) then
            npe = min(arg_conn%npe, size(connectivity, 1))
            do k = 1, npe
              connectivity(k, i) = int(arg_conn%connect(k), i4)
            end do
            do k = npe + 1, size(connectivity, 1)
              connectivity(k, i) = 0_i4
            end do
          end if
          elem_types(i) = g_ufc_global%md_layer%mesh%raw_data%element_types(elem_ids(i))
        end do

      else
        status%status_code = IF_STATUS_INVALID
        status%message = 'MD_Out_GetElemConnectivity: unsupported region type'
        return
      end if
      
    class default
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_Out_GetElemConnectivity: model type not UF_ModelDef'
      return
    end select

    status%status_code = IF_STATUS_OK

  end subroutine MD_Out_GetElemConnectivity

  subroutine MD_Out_GetNodeCoords(model, region_type, region_name, &
                                   n_nodes, node_ids, coords, status)
    !! Get node coordinates ( ? ? md_layer%mesh)

    type(*), intent(in) :: model
    integer(i4), intent(in) :: region_type
    character(len=*), intent(in) :: region_name
    integer(i4), intent(out) :: n_nodes
    integer(i4), intent(inout) :: node_ids(:)
    real(wp), intent(inout) :: coords(:,:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, nset_idx
    logical :: found
    type(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    type(ErrorStatusType) :: coord_status

    call init_error_status(status)
    n_nodes = 0

    select type(m => model)
    type is (UF_ModelDef)
      
      if (region_type == REGION_TYPE_WHOLE) then
        if (.not. MD_Mesh_IsAvailable()) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetNodeCoords: mesh not available'
          return
        end if
        n_nodes = int(g_ufc_global%md_layer%mesh%raw_data%nNodes, i4)
        if (n_nodes > size(node_ids)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetNodeCoords: node_ids array too small'
          return
        end if
        do i = 1, n_nodes
          node_ids(i) = i
          call MD_Mesh_GetNodeCoords_Idx(i, arg_coords, coord_status)
          if (coord_status%status_code == IF_STATUS_OK) then
            coords(1:min(3, size(coords,1)), i) = arg_coords%coords(1:min(3, size(coords,1)))
          end if
        end do
        
      else if (region_type == REGION_TYPE_NSET) then
        ! Node set: lookup by name
        found = .false.
        do j = 1, m%assembly%nNodeSets
          if (trim(m%assembly%node_sets(j)%name) == trim(region_name)) then
            found = .true.
            nset_idx = j
            exit
          end if
        end do
        
        if (.not. found) then
          status%status_code = IF_STATUS_NOT_FOUND
          status%message = 'MD_Out_GetNodeCoords: node set not found: ' // trim(region_name)
          return
        end if
        
        n_nodes = m%assembly%node_sets(nset_idx)%nNodes
        if (n_nodes > size(node_ids)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetNodeCoords: node_ids array too small'
          return
        end if
        
        if (.not. MD_Mesh_IsAvailable()) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_Out_GetNodeCoords: mesh not available'
          return
        end if
        do i = 1, n_nodes
          node_ids(i) = m%assembly%node_sets(nset_idx)%node_ids(i)
          call MD_Mesh_GetNodeCoords_Idx(node_ids(i), arg_coords, coord_status)
          if (coord_status%status_code == IF_STATUS_OK) then
            coords(1:min(3, size(coords,1)), i) = arg_coords%coords(1:min(3, size(coords,1)))
          end if
        end do

      else
        status%status_code = IF_STATUS_INVALID
        status%message = 'MD_Out_GetNodeCoords: unsupported region type'
        return
      end if
      
    class default
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_Out_GetNodeCoords: model type not UF_ModelDef'
      return
    end select

    status%status_code = IF_STATUS_OK

  end subroutine MD_Out_GetNodeCoords
end module MD_Out_FieldExport