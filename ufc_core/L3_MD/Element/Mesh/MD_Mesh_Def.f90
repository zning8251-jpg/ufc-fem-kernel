!===============================================================================
! MODULE:  MD_Mesh_Def
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Def
! BRIEF:   Mesh topology types — Desc + State. L3-only SSOT for connectivity.
!          Algo/Ctx omitted (topology data, no algorithm parameters).
!===============================================================================
MODULE MD_Mesh_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Constants
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_SETS       = 128
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_SET_LEN    = 4096
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_FACE_NODES = 9
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_FACES      = 65536


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_NodeSetEntry_Desc
  ! KIND:  Desc
  ! DESC:  Node set record — set ID + node ID array
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_NodeSetEntry_Desc
    INTEGER(i4) :: set_id  = 0                               ! [in] set ID
    INTEGER(i4) :: n_nodes = 0                               ! [in] node count
    INTEGER(i4) :: node_ids(MD_MESH_MAX_SET_LEN) = 0         ! [in] node ID array
    LOGICAL     :: valid   = .FALSE.                         ! [in] entry validity
  END TYPE MD_Mesh_NodeSetEntry_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_ElemSetEntry_Desc
  ! KIND:  Desc
  ! DESC:  Element set record — set ID + element ID array
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_ElemSetEntry_Desc
    INTEGER(i4) :: set_id  = 0                               ! [in] set ID
    INTEGER(i4) :: n_elems = 0                               ! [in] element count
    INTEGER(i4) :: elem_ids(MD_MESH_MAX_SET_LEN) = 0         ! [in] element ID array
    LOGICAL     :: valid   = .FALSE.                         ! [in] entry validity
  END TYPE MD_Mesh_ElemSetEntry_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_FaceDesc
  ! KIND:  Desc
  ! DESC:  Face descriptor — element face with normal and area
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_FaceDesc
    INTEGER(i4) :: face_id       = 0                         ! [in] global face ID
    INTEGER(i4) :: elem_id       = 0                         ! [in] parent element ID
    INTEGER(i4) :: local_face_id = 0                         ! [in] local face index
    INTEGER(i4) :: n_face_nodes  = 0                         ! [in] number of face nodes
    INTEGER(i4) :: face_nodes(MD_MESH_MAX_FACE_NODES) = 0    ! [in] face node IDs
    REAL(wp)    :: normal(3)     = 0.0_wp                    ! [out] outward normal
    REAL(wp)    :: area          = 0.0_wp                    ! [out] face area
    LOGICAL     :: is_boundary   = .FALSE.                   ! [out] boundary flag
  END TYPE MD_Mesh_FaceDesc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_NodeDesc
  ! KIND:  Desc
  ! DESC:  Single node descriptor — ID + coordinates
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_NodeDesc
    INTEGER(i4) :: node_id = 0                               ! [in] node ID
    REAL(wp)    :: coords(3) = 0.0_wp                        ! [in] nodal coordinates
  END TYPE MD_Mesh_NodeDesc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_ElemDesc
  ! KIND:  Desc
  ! DESC:  Single element descriptor — ID, type, connectivity
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_ElemDesc
    INTEGER(i4) :: elem_id   = 0                             ! [in] element ID
    INTEGER(i4) :: elem_type = 0                             ! [in] element type code
    INTEGER(i4) :: n_nodes   = 0                             ! [in] number of nodes
    INTEGER(i4), ALLOCATABLE :: node_conn(:)                 ! [in] connectivity array
  END TYPE MD_Mesh_ElemDesc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_Desc
  ! KIND:  Desc
  ! DESC:  Mesh topology descriptor — nodes, connectivity, adjacency, sets
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_Desc
    INTEGER(i4) :: n_nodes    = 0                            ! [in] total node count
    INTEGER(i4) :: n_elements = 0                            ! [in] total element count
    INTEGER(i4) :: ndim       = 3                            ! [in] spatial dimension
    INTEGER(i4) :: max_nn     = 8                            ! [in] max nodes per element
    REAL(wp), POINTER    :: coords(:,:)   => NULL()          ! [in] (ndim, n_nodes)
    INTEGER(i4), POINTER :: conn(:,:)     => NULL()          ! [in] (max_nn, n_elements)
    INTEGER(i4), POINTER :: elem_type(:)  => NULL()          ! [in] (n_elements)
    ! --- Topology adjacency (populated by MD_Mesh_Topo) ---
    INTEGER(i4), POINTER :: node_to_elem_ptr(:) => NULL()    ! [out] CSR row pointer
    INTEGER(i4), POINTER :: node_to_elem_col(:) => NULL()    ! [out] CSR column indices
    LOGICAL :: topo_built = .FALSE.                          ! [out] adjacency built flag
    ! --- Face table ---
    INTEGER(i4) :: n_faces = 0                               ! [out] face count
    TYPE(MD_Mesh_FaceDesc), ALLOCATABLE :: faces(:)          ! [out] face array
    ! --- Sets ---
    INTEGER(i4) :: n_nodesets = 0                            ! [in] node set count
    INTEGER(i4) :: n_elemsets = 0                            ! [in] element set count
    TYPE(MD_Mesh_NodeSetEntry_Desc) :: nodesets(MD_MESH_MAX_SETS) ! [in] node sets
    TYPE(MD_Mesh_ElemSetEntry_Desc) :: elemsets(MD_MESH_MAX_SETS) ! [in] element sets
  END TYPE MD_Mesh_Desc


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Mesh_State
  ! KIND:  State
  ! DESC:  Mesh runtime state — tracks loading, build, and validation status
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_State
    LOGICAL     :: nodes_loaded     = .FALSE.                ! [inout] nodes loaded
    LOGICAL     :: conn_loaded      = .FALSE.                ! [inout] connectivity loaded
    LOGICAL     :: topo_built       = .FALSE.                ! [inout] topology built
    LOGICAL     :: faces_built      = .FALSE.                ! [inout] face table built
    LOGICAL     :: validated        = .FALSE.                ! [inout] mesh validated
    INTEGER(i4) :: n_orphan_nodes   = 0                      ! [out]   orphan node count
    INTEGER(i4) :: n_degenerate     = 0                      ! [out]   degenerate element count
    INTEGER(i4) :: n_boundary_faces = 0                      ! [out]   boundary face count
    INTEGER(i4) :: modification_gen = 0                      ! [inout] modification generation
    ! Kinematic state tracking (for WriteBack)
    LOGICAL     :: disp_loaded      = .FALSE.                ! [inout] displacement loaded
    LOGICAL     :: vel_loaded       = .FALSE.                ! [inout] velocity loaded
    LOGICAL     :: acc_loaded       = .FALSE.                ! [inout] acceleration loaded
  END TYPE MD_Mesh_State

!---------------------------------------------------------------------------
! TYPE:  MD_Mesh_Get_Node_Arg
! KIND:  Arg
! DESC:  SIO unified Arg type — query node coordinates by ID
!---------------------------------------------------------------------------
TYPE, PUBLIC :: MD_Mesh_Get_Node_Arg
  ! [IN] mesh state
  TYPE(MD_Mesh_Desc) :: desc             ! [IN]  mesh descriptor
  TYPE(MD_Mesh_State) :: state           ! [INOUT] mesh state

  ! [IN] query parameters
  INTEGER(i4) :: node_id                 ! [IN]  node ID to query

  ! [OUT] node data
  REAL(wp) :: coords(3)                  ! [OUT] node coordinates
  INTEGER(i4) :: status_code             ! [OUT] query status
  CHARACTER(len=256) :: message          ! [OUT] status message
END TYPE MD_Mesh_Get_Node_Arg

END MODULE MD_Mesh_Def
