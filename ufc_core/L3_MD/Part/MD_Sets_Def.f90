!===============================================================================
! MODULE:  MD_Sets_Def
! LAYER:   L3_MD
! DOMAIN:  Part / Sets
! ROLE:    _Def
! BRIEF:   Node sets, element sets, surface definitions — Desc types
!          for FEM model set operations (union, intersect, difference).
!===============================================================================
MODULE MD_Sets_Def
  USE IF_Err_Brg,         only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core,        only: i4, wp
  USE MD_Base_ObjModel,            only: UF_CoreObjectBase, CAT_DESC
  use MD_MathUtils,        only: SortInt, UniqueInt

  implicit none
  private

  public :: MD_NodeSet
  public :: MD_ElemSet
  public :: MD_Surface
  public :: MD_SurfFacet
  public :: MD_SetStatistics
  public :: MD_SetBoundingBox
  public :: MD_SetDistanceResult
  public :: MD_SetOverlapResult
  public :: MD_SetSymmetryResult
  public :: MD_SetGenerationCriteria
  public :: MD_SetExportFormat
  public :: MD_SetBoundingBox_Calc
  public :: MD_SetDistance_Calc
  public :: MD_SetOverlap_Check
  public :: MD_SetSymmetry_Detect
  public :: MD_SetGenerateByBox
  public :: MD_SetGenerateBySphere
  public :: MD_SetGenerateByCylinder
  public :: MD_SetGenerateByPlane
  public :: MD_SetGenerateBySurface
  public :: MD_SetExport
  public :: MD_SetImport
  public :: MAX_SET_NAME
  public :: SURF_TYPE_ELEME
  public :: SURF_TYPE_NODE

  integer(i4), parameter, public :: MAX_SET_NAME = 80
  integer(i4), parameter, public :: SURF_TYPE_ELEME = 1
  integer(i4), parameter, public :: SURF_TYPE_NODE = 2

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SurfFacet
  ! KIND:  Desc
  ! DESC:  Single surface facet — element face with area/normal/centroid
  !---------------------------------------------------------------------------
  type, public :: MD_SurfFacet
    integer(i4) :: element_id = 0      ! Element ID  ? ?
    integer(i4) :: face_id = 0         ! Face ID  ? ?
    real(wp) :: area = 0.0_wp          ! Facet area A  ? ?
    real(wp) :: normal(3) = 0.0_wp     ! Normal vector n  ?? ?
    real(wp) :: centroid(3) = 0.0_wp  ! Centroid x_c  ?? ?
  end type MD_SurfFacet

  !---------------------------------------------------------------------------
  ! TYPE:  MD_NodeSet
  ! KIND:  Desc
  ! DESC:  Node set — collection of node IDs for BC/load application
  !---------------------------------------------------------------------------
  type, public, extends(UF_CoreObjectBase) :: MD_NodeSet
    character(len=MAX_SET_NAME) :: name = ""  ! Set name
    integer(i4) :: set_id = 0_i4              ! Set ID  ? ?
    integer(i4) :: nNodes = 0_i4              ! Number of nodes n_nodes  ? ?
    integer(i4), allocatable :: node_ids(:)   ! Node ID array n_i  ??^n_nodes
    logical :: init = .false.                  ! Initialization flag
  contains
    procedure :: AddNode
    procedure :: AddNodes
    procedure :: RemoveNode
    procedure :: Clear
    procedure :: Finalize
    procedure :: Init
    procedure :: Contains
    procedure :: FindNode
    procedure :: GetNodeAt
    procedure :: GetNodeIds
    procedure :: GetSize
    procedure :: GetStatistics
    procedure :: Valid
    procedure :: Sort
    procedure :: Unique
    procedure :: Union
    procedure :: Intersect
    procedure :: Difference
    procedure :: Equals
    procedure :: IsSubset
  end type MD_NodeSet

  !---------------------------------------------------------------------------
  ! TYPE:  MD_ElemSet
  ! KIND:  Desc
  ! DESC:  Element set — collection of element IDs for section/material assignment
  !---------------------------------------------------------------------------
  type, public, extends(UF_CoreObjectBase) :: MD_ElemSet
    character(len=MAX_SET_NAME) :: name = ""     ! Set name
    integer(i4) :: set_id = 0_i4                 ! Set ID  ? ?
    integer(i4) :: num_elems = 0_i4              ! Number of elements n_elems  ? ?
    integer(i4), allocatable :: element_ids(:)   ! Element ID array e_i  ??^n_elems
    logical :: init = .false.                     ! Initialization flag
  contains
    procedure :: AddElem
    procedure :: AddElems
    procedure :: RemoveElem
    procedure :: Clear
    procedure :: Finalize
    procedure :: Init
    procedure :: Contains
    procedure :: FindElem
    procedure :: GetElemAt
    procedure :: GetElemIds
    procedure :: GetSize
    procedure :: GetStatistics
    procedure :: Valid
    procedure :: Sort
    procedure :: Unique
    procedure :: Union
    procedure :: Intersect
    procedure :: Difference
    procedure :: Equals
    procedure :: IsSubset
  end type MD_ElemSet

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Surface
  ! KIND:  Desc
  ! DESC:  Surface — facet collection for contact and distributed loads
  !---------------------------------------------------------------------------
  type, public, extends(UF_CoreObjectBase) :: MD_Surface
    character(len=MAX_SET_NAME) :: name = ""     ! Surface name
    integer(i4) :: surface_id = 0_i4             ! Surface ID  ? ?
    integer(i4) :: surface_type = SURF_TYPE_ELEME  ! Surface type (element/node)
    integer(i4) :: num_facets = 0_i4             ! Number of facets n_facets  ? ?
    type(MD_SurfFacet), allocatable :: facets(:) ! Facet array
    real(wp) :: total_area = 0.0_wp             ! Total area A_total  ? ?
    real(wp) :: centroid(3) = 0.0_wp            ! Centroid x_c  ?? ?
    logical :: init = .false.                     ! Initialization flag
  contains
    procedure :: AddFacet
    procedure :: AddFacets
    procedure :: RemoveFacet
    procedure :: Clear
    procedure :: Finalize
    procedure :: Init
    procedure :: FindFacet
    procedure :: GetFacet
    procedure :: GetNormal
    procedure :: GetSize
    procedure :: GetTotalArea
    procedure :: GetCentroid
    procedure :: GetStatistics
    procedure :: ComputeCentroid
    procedure :: Valid
  end type MD_Surface

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetStatistics
  ! KIND:  Desc
  ! DESC:  Set statistics — count, min/max IDs, mean, std_dev
  !---------------------------------------------------------------------------
  type, public :: MD_SetStatistics
    integer(i4) :: count = 0_i4          ! Count n  ? ?
    integer(i4) :: min_id = 0_i4         ! Minimum ID  ? ?
    integer(i4) :: max_id = 0_i4         ! Maximum ID  ? ?
    integer(i4) :: unique_count = 0_i4   ! Unique count  ? ?
    real(wp) :: mean_id = 0.0_wp         ! Mean ID ?  ? ?
    real(wp) :: std_dev = 0.0_wp         ! Standard deviation ?  ? ?
  end type MD_SetStatistics

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetBoundingBox
  ! KIND:  Desc
  ! DESC:  Bounding box — min/max coordinates, center, dimensions
  !---------------------------------------------------------------------------
  type, public :: MD_SetBoundingBox
    real(wp) :: min_coord(3) = 0.0_wp   ! Minimum coordinates x_min  ?? ?
    real(wp) :: max_coord(3) = 0.0_wp   ! Maximum coordinates x_max  ?? ?
    real(wp) :: center(3) = 0.0_wp      ! Center x_c  ?? ?
    real(wp) :: dimensions(3) = 0.0_wp  ! Dimensions d  ?? ?
  end type MD_SetBoundingBox

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetDistanceResult
  ! KIND:  Desc
  ! DESC:  Distance statistics between two sets
  !---------------------------------------------------------------------------
  type, public :: MD_SetDistanceResult
    real(wp) :: min_distance = 0.0_wp    ! Minimum distance d_min  ? ?
    real(wp) :: max_distance = 0.0_wp    ! Maximum distance d_max  ? ?
    real(wp) :: mean_distance = 0.0_wp  ! Mean distance d_mean  ? ?
    integer(i4) :: closest_pair(2) = 0   ! Closest pair indices  ?? ?
    integer(i4) :: farthest_pair(2) = 0  ! Farthest pair indices  ?? ?
  end type MD_SetDistanceResult

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetOverlapResult
  ! KIND:  Desc
  ! DESC:  Overlap information between two sets
  !---------------------------------------------------------------------------
  type, public :: MD_SetOverlapResult
    logical :: is_overlapping = .false.  ! Overlap flag
    real(wp) :: overlap_volume = 0.0_wp ! Overlap volume V_overlap  ? ?
    real(wp) :: overlap_area = 0.0_wp   ! Overlap area A_overlap  ? ?
    integer(i4), allocatable :: overlap_nodes(:)  ! Overlapping node IDs  ??^n
    integer(i4), allocatable :: overlap_elems(:)  ! Overlapping element IDs  ??^m
  end type MD_SetOverlapResult

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetSymmetryResult
  ! KIND:  Desc
  ! DESC:  Symmetry detection results
  !---------------------------------------------------------------------------
  type, public :: MD_SetSymmetryResult
    logical :: has_symmetry = .false.    ! Symmetry flag
    integer(i4) :: symmetry_type = 0     ! Symmetry type  ? ?(1=x, 2=y, 3=z)
    real(wp) :: symmetry_plane(4) = 0.0_wp  ! Plane eq [n_x, n_y, n_z, d]
    real(wp) :: tolerance = 1.0e-6_wp    ! Tolerance ?  ? ?
  end type MD_SetSymmetryResult

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetGenerationCriteria
  ! KIND:  Desc
  ! DESC:  Criteria for set generation by geometry (box/sphere/cylinder/plane)
  !---------------------------------------------------------------------------
  type, public :: MD_SetGenerationCriteria
    real(wp) :: box_min(3) = 0.0_wp      ! Box minimum x_min  ?? ?
    real(wp) :: box_max(3) = 0.0_wp      ! Box maximum x_max  ?? ?
    real(wp) :: sphere_center(3) = 0.0_wp  ! Sphere center x_c  ?? ?
    real(wp) :: sphere_radius = 0.0_wp   ! Sphere radius r  ? ?
    real(wp) :: cylinder_center(3) = 0.0_wp  ! Cylinder center x_c  ?? ?
    real(wp) :: cylinder_axis(3) = 0.0_wp    ! Cylinder axis direction n  ?? ?
    real(wp) :: cylinder_radius = 0.0_wp ! Cylinder radius r  ? ?
    real(wp) :: cylinder_height = 0.0_wp ! Cylinder height h  ? ?
    real(wp) :: plane_point(3) = 0.0_wp  ! Plane point x_p  ?? ?
    real(wp) :: plane_normal(3) = 0.0_wp ! Plane normal n  ?? ?
  end type MD_SetGenerationCriteria

  !---------------------------------------------------------------------------
  ! TYPE:  MD_SetExportFormat
  ! KIND:  Desc
  ! DESC:  Format specification for set export
  !---------------------------------------------------------------------------
  type, public :: MD_SetExportFormat
    character(len=256) :: filename = ""  ! Output filename
    logical :: include_metadata = .true. ! Include metadata flag
  end type MD_SetExportFormat

contains

  !=============================================================================
  ! MD_ElemSet methods
  !=============================================================================
  subroutine AddElem(this, element_id, status)
    class(MD_ElemSet), intent(inout) :: this
    integer(i4), intent(in) :: element_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4), allocatable :: temp(:)

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    if (this%num_elems >= size(this%element_ids)) then
      allocate(temp(size(this%element_ids)*2))
      temp(1:this%num_elems) = this%element_ids(1:this%num_elems)
      call move_alloc(temp, this%element_ids)
    end if

    this%num_elems = this%num_elems + 1_i4
    this%element_ids(this%num_elems) = element_id

    status%status_code = IF_STATUS_OK
  end subroutine AddElem

  subroutine AddElems(this, element_ids, count, status)
    class(MD_ElemSet), intent(inout) :: this
    integer(i4), intent(in) :: element_ids(:)
    integer(i4), intent(in) :: count
    type(ErrorStatusType), intent(out) :: status

    integer(i4), allocatable :: temp(:)
    integer(i4) :: i, new_size

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    new_size = this%num_elems + count
    if (new_size > size(this%element_ids)) then
      allocate(temp(max(new_size, size(this%element_ids)*2))
      temp(1:this%num_elems) = this%element_ids(1:this%num_elems)
      call move_alloc(temp, this%element_ids)
    end if

    do i = 1, count
      this%num_elems = this%num_elems + 1_i4
      this%element_ids(this%num_elems) = element_ids(i)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine AddElems

  subroutine AddFacet(this, facet, status)
    class(MD_Surface), intent(inout) :: this
    type(MD_SurfFacet), intent(in) :: facet
    type(ErrorStatusType), intent(out) :: status

    type(MD_SurfFacet), allocatable :: temp(:)

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    if (this%num_facets >= size(this%facets)) then
      allocate(temp(size(this%facets)*2))
      temp(1:this%num_facets) = this%facets(1:this%num_facets)
      call move_alloc(temp, this%facets)
    end if

    this%num_facets = this%num_facets + 1_i4
    this%facets(this%num_facets) = facet
    this%total_area = this%total_area + facet%area

    status%status_code = IF_STATUS_OK
  end subroutine AddFacet

  subroutine AddFacets(this, facets, count, status)
    class(MD_Surface), intent(inout) :: this
    type(MD_SurfFacet), intent(in) :: facets(:)
    integer(i4), intent(in) :: count
    type(ErrorStatusType), intent(out) :: status

    type(MD_SurfFacet), allocatable :: temp(:)
    integer(i4) :: i, new_size

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    new_size = this%num_facets + count
    if (new_size > size(this%facets)) then
      allocate(temp(max(new_size, size(this%facets)*2))
      temp(1:this%num_facets) = this%facets(1:this%num_facets)
      call move_alloc(temp, this%facets)
    end if

    do i = 1, count
      this%num_facets = this%num_facets + 1_i4
      this%facets(this%num_facets) = facets(i)
      this%total_area = this%total_area + facets(i)%area
    end do

    status%status_code = IF_STATUS_OK
  end subroutine AddFacets

  !=============================================================================
  !> @brief Add node to set (legacy interface)
  !! @details Appends node ID to set, auto-expands if needed
  !! @param[inout] this Node set instance
  !! @param[in] node_id Node ID n_id ? ?
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine AddNode(this, node_id, status)
    class(MD_NodeSet), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4), allocatable :: temp(:)

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    if (this%nNodes >= size(this%node_ids)) then
      allocate(temp(size(this%node_ids)*2))
      temp(1:this%nNodes) = this%node_ids(1:this%nNodes)
      call move_alloc(temp, this%node_ids)
    end if

    this%nNodes = this%nNodes + 1_i4
    this%node_ids(this%nNodes) = node_id

    status%status_code = IF_STATUS_OK
  end subroutine AddNode

  subroutine AddNodes(this, node_ids, count, status)
    class(MD_NodeSet), intent(inout) :: this
    integer(i4), intent(in) :: node_ids(:)
    integer(i4), intent(in) :: count
    type(ErrorStatusType), intent(out) :: status

    integer(i4), allocatable :: temp(:)
    integer(i4) :: i, new_size

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    new_size = this%nNodes + count
    if (new_size > size(this%node_ids)) then
      allocate(temp(max(new_size, size(this%node_ids)*2))
      temp(1:this%nNodes) = this%node_ids(1:this%nNodes)
      call move_alloc(temp, this%node_ids)
    end if

    do i = 1, count
      this%nNodes = this%nNodes + 1_i4
      this%node_ids(this%nNodes) = node_ids(i)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine AddNodes

  subroutine Clear(this, status)
    class(MD_NodeSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    this%nNodes = 0_i4

    status%status_code = IF_STATUS_OK
  end subroutine Clear

  subroutine Clear(this, status)
    class(MD_ElemSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    this%num_elems = 0_i4

    status%status_code = IF_STATUS_OK
  end subroutine Clear

  subroutine Clear(this, status)
    class(MD_Surface), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    this%num_facets = 0_i4
    this%total_area = 0.0_wp
    this%centroid = 0.0_wp

    status%status_code = IF_STATUS_OK
  end subroutine Clear

  subroutine ComputeCentroid(this, status)
    class(MD_Surface), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    if (this%num_facets == 0 .or. this%total_area == 0.0_wp) then
      this%centroid = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if

    this%centroid = 0.0_wp
    do i = 1, this%num_facets
      this%centroid = this%centroid + this%facets(i)%area * this%facets(i)%centroid
    end do

    this%centroid = this%centroid / this%total_area

    status%status_code = IF_STATUS_OK
  end subroutine ComputeCentroid

  function Contains(this, node_id) result(found)
    class(MD_NodeSet), intent(in) :: this
    integer(i4), intent(in) :: node_id
    logical :: found
    integer(i4) :: i

    found = .false.

    if (.not. this%init) return

    do i = 1, this%nNodes
      if (this%node_ids(i) == node_id) then
        found = .true.
        return
      end if
    end do
  end function Contains

  function Contains(this, element_id) result(found)
    class(MD_ElemSet), intent(in) :: this
    integer(i4), intent(in) :: element_id
    logical :: found
    integer(i4) :: i

    found = .false.

    if (.not. this%init) return

    do i = 1, this%num_elems
      if (this%element_ids(i) == element_id) then
        found = .true.
        return
      end if
    end do
  end function Contains

  subroutine Difference(this, other, result, status)
    class(MD_NodeSet), intent(in) :: this
    type(MD_NodeSet), intent(in) :: other
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init .or. .not. other%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    call result%Init(this%set_id, trim(this%name)//"_diff", this%nNodes, status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, this%nNodes
      if (.not. other%Contains(this%node_ids(i))) then
        call result%AddNode(this%node_ids(i), status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine Difference

  subroutine Difference(this, other, result, status)
    class(MD_ElemSet), intent(in) :: this
    type(MD_ElemSet), intent(in) :: other
    type(MD_ElemSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init .or. .not. other%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    call result%Init(this%set_id, trim(this%name)//"_diff", this%num_elems, status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, this%num_elems
      if (.not. other%Contains(this%element_ids(i))) then
        call result%AddElem(this%element_ids(i), status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine Difference

  function Equals(this, other) result(equals)
    class(MD_NodeSet), intent(in) :: this
    type(MD_NodeSet), intent(in) :: other
    logical :: equals
    integer(i4) :: i

    equals = .false.

    if (.not. this%init .or. .not. other%init) return
    if (this%nNodes /= other%nNodes) return

    do i = 1, this%nNodes
      if (.not. other%Contains(this%node_ids(i))) then
        return
      end if
    end do

    equals = .true.
  end function Equals

  function Equals(this, other) result(equals)
    class(MD_ElemSet), intent(in) :: this
    type(MD_ElemSet), intent(in) :: other
    logical :: equals
    integer(i4) :: i

    equals = .false.

    if (.not. this%init .or. .not. other%init) return
    if (this%num_elems /= other%num_elems) return

    do i = 1, this%num_elems
      if (.not. other%Contains(this%element_ids(i))) then
        return
      end if
    end do

    equals = .true.
  end function Equals

  subroutine Finalize(this, status)
    class(MD_NodeSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (allocated(this%node_ids)) deallocate(this%node_ids)

    this%nNodes = 0_i4
    this%init = .false.

    status%status_code = IF_STATUS_OK
  end subroutine Finalize

  subroutine Finalize(this, status)
    class(MD_ElemSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (allocated(this%element_ids)) deallocate(this%element_ids)

    this%num_elems = 0_i4
    this%init = .false.

    status%status_code = IF_STATUS_OK
  end subroutine Finalize

  subroutine Finalize(this, status)
    class(MD_Surface), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (allocated(this%facets)) deallocate(this%facets)

    this%num_facets = 0_i4
    this%total_area = 0.0_wp
    this%centroid = 0.0_wp
    this%init = .false.

    status%status_code = IF_STATUS_OK
  end subroutine Finalize

  function FindElem(this, element_id) result(index)
    class(MD_ElemSet), intent(in) :: this
    integer(i4), intent(in) :: element_id
    integer(i4) :: index
    integer(i4) :: i

    index = 0_i4

    if (.not. this%init) return

    do i = 1, this%num_elems
      if (this%element_ids(i) == element_id) then
        index = i
        return
      end if
    end do
  end function FindElem

  function FindFacet(this, element_id, face_id) result(index)
    class(MD_Surface), intent(in) :: this
    integer(i4), intent(in) :: element_id
    integer(i4), intent(in), optional :: face_id
    integer(i4) :: index
    integer(i4) :: i

    index = 0_i4

    if (.not. this%init) return

    do i = 1, this%num_facets
      if (this%facets(i)%element_id == element_id) then
        if (present(face_id)) then
          if (this%facets(i)%face_id == face_id) then
            index = i
            return
          end if
        else
          index = i
          return
        end if
      end if
    end do
  end function FindFacet

  function FindNode(this, node_id) result(index)
    class(MD_NodeSet), intent(in) :: this
    integer(i4), intent(in) :: node_id
    integer(i4) :: index
    integer(i4) :: i

    index = 0_i4

    if (.not. this%init) return

    do i = 1, this%nNodes
      if (this%node_ids(i) == node_id) then
        index = i
        return
      end if
    end do
  end function FindNode

  function GetCentroid(this) result(centroid)
    class(MD_Surface), intent(in) :: this
    real(wp) :: centroid(3)

    if (this%init) then
      centroid = this%centroid
    else
      centroid = 0.0_wp
    end if
  end function GetCentroid

  function GetElemAt(this, index) result(element_id)
    class(MD_ElemSet), intent(in) :: this
    integer(i4), intent(in) :: index
    integer(i4) :: element_id

    element_id = 0_i4

    if (.not. this%init) return
    if (index < 1 .or. index > this%num_elems) return

    element_id = this%element_ids(index)
  end function GetElemAt

  function GetElemIds(this) result(element_ids)
    class(MD_ElemSet), intent(in) :: this
    integer(i4), pointer :: element_ids(:)

    if (this%init .and. this%num_elems > 0) then
      element_ids => this%element_ids(1:this%num_elems)
    else
      element_ids => null()
    end if
  end function GetElemIds

  function GetFacet(this, index) result(facet)
    class(MD_Surface), intent(in) :: this
    integer(i4), intent(in) :: index
    type(MD_SurfFacet) :: facet

    facet = MD_SurfFacet(0_i4, 0_i4, 0.0_wp, [0.0_wp, 0.0_wp, 0.0_wp])

    if (.not. this%init) return
    if (index < 1 .or. index > this%num_facets) return

    facet = this%facets(index)
  end function GetFacet

  function GetNodeAt(this, index) result(node_id)
    class(MD_NodeSet), intent(in) :: this
    integer(i4), intent(in) :: index
    integer(i4) :: node_id

    node_id = 0_i4

    if (.not. this%init) return
    if (index < 1 .or. index > this%nNodes) return

    node_id = this%node_ids(index)
  end function GetNodeAt

  function GetNodeIds(this) result(node_ids)
    class(MD_NodeSet), intent(in) :: this
    integer(i4), pointer :: node_ids(:)

    if (this%init .and. this%nNodes > 0) then
      node_ids => this%node_ids(1:this%nNodes)
    else
      node_ids => null()
    end if
  end function GetNodeIds

  function GetNormal(this, index) result(normal)
    class(MD_Surface), intent(in) :: this
    integer(i4), intent(in) :: index
    real(wp) :: normal(3)

    normal = 0.0_wp

    if (.not. this%init) return
    if (index < 1 .or. index > this%num_facets) return

    normal = this%facets(index)%normal
  end function GetNormal

  function GetSize(this) result(size)
    class(MD_NodeSet), intent(in) :: this
    integer(i4) :: size

    if (this%init) then
      size = this%nNodes
    else
      size = 0_i4
    end if
  end function GetSize

  function GetSize(this) result(size)
    class(MD_ElemSet), intent(in) :: this
    integer(i4) :: size

    if (this%init) then
      size = this%num_elems
    else
      size = 0_i4
    end if
  end function GetSize

  function GetSize(this) result(size)
    class(MD_Surface), intent(in) :: this
    integer(i4) :: size

    if (this%init) then
      size = this%num_facets
    else
      size = 0_i4
    end if
  end function GetSize

  subroutine GetStatistics(this, stats, status)
    class(MD_NodeSet), intent(in) :: this
    type(MD_SetStatistics), intent(out) :: stats
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i
    real(wp) :: sum_id, sum_sq, variance

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    stats%count = this%nNodes

    if (this%nNodes == 0) then
      stats%min_id = 0_i4
      stats%max_id = 0_i4
      stats%unique_count = 0_i4
      stats%mean_id = 0.0_wp
      stats%std_dev = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if

    stats%min_id = minval(this%node_ids(1:this%nNodes))
    stats%max_id = maxval(this%node_ids(1:this%nNodes))

    sum_id = sum(real(this%node_ids(1:this%nNodes), kind=wp))
    stats%mean_id = sum_id / real(this%nNodes, kind=wp)

    sum_sq = sum(real(this%node_ids(1:this%nNodes), kind=wp)**2)
    variance = (sum_sq - sum_id**2 / real(this%nNodes, kind=wp)) / real(this%nNodes - 1, kind=wp)
    if (variance > 0.0_wp) then
      stats%std_dev = sqrt(variance)
    else
      stats%std_dev = 0.0_wp
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetStatistics

  subroutine GetStatistics(this, stats, status)
    class(MD_ElemSet), intent(in) :: this
    type(MD_SetStatistics), intent(out) :: stats
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i
    real(wp) :: sum_id, sum_sq, variance

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    stats%count = this%num_elems

    if (this%num_elems == 0) then
      stats%min_id = 0_i4
      stats%max_id = 0_i4
      stats%unique_count = 0_i4
      stats%mean_id = 0.0_wp
      stats%std_dev = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if

    stats%min_id = minval(this%element_ids(1:this%num_elems))
    stats%max_id = maxval(this%element_ids(1:this%num_elems))

    sum_id = sum(real(this%element_ids(1:this%num_elems), kind=wp))
    stats%mean_id = sum_id / real(this%num_elems, kind=wp)

    sum_sq = sum(real(this%element_ids(1:this%num_elems), kind=wp)**2)
    variance = (sum_sq - sum_id**2 / real(this%num_elems, kind=wp)) / real(this%num_elems - 1, kind=wp)
    if (variance > 0.0_wp) then
      stats%std_dev = sqrt(variance)
    else
      stats%std_dev = 0.0_wp
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetStatistics

  subroutine GetStatistics(this, stats, status)
    class(MD_Surface), intent(in) :: this
    type(MD_SetStatistics), intent(out) :: stats
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i
    real(wp) :: sum_id, sum_sq, variance

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    stats%count = this%num_facets

    if (this%num_facets == 0) then
      stats%min_id = 0_i4
      stats%max_id = 0_i4
      stats%unique_count = 0_i4
      stats%mean_id = 0.0_wp
      stats%std_dev = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if

    stats%min_id = minval(this%facets(1:this%num_facets)%element_id)
    stats%max_id = maxval(this%facets(1:this%num_facets)%element_id)

    sum_id = sum(real(this%facets(1:this%num_facets)%element_id, kind=wp))
    stats%mean_id = sum_id / real(this%num_facets, kind=wp)

    sum_sq = sum(real(this%facets(1:this%num_facets)%element_id, kind=wp)**2)
    variance = (sum_sq - sum_id**2 / real(this%num_facets, kind=wp)) / real(this%num_facets - 1, kind=wp)
    if (variance > 0.0_wp) then
      stats%std_dev = sqrt(variance)
    else
      stats%std_dev = 0.0_wp
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetStatistics

  function GetTotalArea(this) result(area)
    class(MD_Surface), intent(in) :: this
    real(wp) :: area

    if (this%init) then
      area = this%total_area
    else
      area = 0.0_wp
    end if
  end function GetTotalArea

  subroutine Init(this, set_id, name, capacity, status)
    class(MD_NodeSet), intent(out) :: this
    integer(i4), intent(in) :: set_id
    character(len=*), intent(in) :: name
    integer(i4), intent(in), optional :: capacity
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: cap

    call init_error_status(status)

    this%category = CAT_DESC
    this%typeName = "MD_NodeSet"
    this%varName = "nodeset"

    this%set_id = set_id
    this%name = trim(name)
    this%nNodes = 0_i4

    cap = 1000_i4
    if (present(capacity)) cap = capacity

    allocate(this%node_ids(cap))

    this%init = .true.

    status%status_code = IF_STATUS_OK
  end subroutine Init

  subroutine Init(this, set_id, name, capacity, status)
    class(MD_ElemSet), intent(out) :: this
    integer(i4), intent(in) :: set_id
    character(len=*), intent(in) :: name
    integer(i4), intent(in), optional :: capacity
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: cap

    call init_error_status(status)

    this%category = CAT_DESC
    this%typeName = "MD_ElemSet"
    this%varName = "elemset"

    this%set_id = set_id
    this%name = trim(name)
    this%num_elems = 0_i4

    cap = 1000_i4
    if (present(capacity)) cap = capacity

    allocate(this%element_ids(cap))

    this%init = .true.

    status%status_code = IF_STATUS_OK
  end subroutine Init

  subroutine Init(this, surface_id, name, surface_type, capacity, status)
    class(MD_Surface), intent(out) :: this
    integer(i4), intent(in) :: surface_id
    character(len=*), intent(in) :: name
    integer(i4), intent(in) :: surface_type
    integer(i4), intent(in), optional :: capacity
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: cap

    call init_error_status(status)

    this%category = CAT_DESC
    this%typeName = "MD_Surface"
    this%varName = "surface"

    this%surface_id = surface_id
    this%name = trim(name)
    this%surface_type = surface_type
    this%num_facets = 0_i4
    this%total_area = 0.0_wp
    this%centroid = 0.0_wp

    cap = 1000_i4
    if (present(capacity)) cap = capacity

    allocate(this%facets(cap))

    this%init = .true.

    status%status_code = IF_STATUS_OK
  end subroutine Init

  subroutine Intersect(this, other, result, status)
    class(MD_NodeSet), intent(in) :: this
    type(MD_NodeSet), intent(in) :: other
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init .or. .not. other%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    call result%Init(this%set_id, trim(this%name)//"_intersect", min(this%nNodes, other%nNodes), status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, this%nNodes
      if (other%Contains(this%node_ids(i))) then
        call result%AddNode(this%node_ids(i), status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine Intersect

  subroutine Intersect(this, other, result, status)
    class(MD_ElemSet), intent(in) :: this
    type(MD_ElemSet), intent(in) :: other
    type(MD_ElemSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init .or. .not. other%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    call result%Init(this%set_id, trim(this%name)//"_intersect", min(this%num_elems, other%num_elems), status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, this%num_elems
      if (other%Contains(this%element_ids(i))) then
        call result%AddElem(this%element_ids(i), status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine Intersect

  function IsSubset(this, other) result(is_subset)
    class(MD_NodeSet), intent(in) :: this
    type(MD_NodeSet), intent(in) :: other
    logical :: is_subset
    integer(i4) :: i

    is_subset = .false.

    if (.not. this%init .or. .not. other%init) return

    do i = 1, this%nNodes
      if (.not. other%Contains(this%node_ids(i))) then
        return
      end if
    end do

    is_subset = .true.
  end function IsSubset

  function IsSubset(this, other) result(is_subset)
    class(MD_ElemSet), intent(in) :: this
    type(MD_ElemSet), intent(in) :: other
    logical :: is_subset
    integer(i4) :: i

    is_subset = .false.

    if (.not. this%init .or. .not. other%init) return

    do i = 1, this%num_elems
      if (.not. other%Contains(this%element_ids(i))) then
        return
      end if
    end do

    is_subset = .true.
  end function IsSubset

  !=============================================================================
  !> @brief Calculate bounding box for node set (legacy interface)
  !! @details Computes x_min, x_max ?? ? center = (x_min + x_max)/2, dimensions = x_max - x_min
  !!   Theory: Bounding box: x_min = min(x_i), x_max = max(x_i), center = (x_min + x_max)/2
  !! @param[in] nodeset Node set instance
  !! @param[in] coords Node coordinates X ??^(ndim nnode)
  !! @param[out] bbox Bounding box result
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine MD_SetBoundingBox_Calc(nodeset, coords, bbox, status)
    type(MD_NodeSet), intent(in) :: nodeset
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetBoundingBox), intent(out) :: bbox
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id, nNodes
    real(wp) :: x, y, z

    call init_error_status(status)
    nNodes = nodeset%GetSize()

    if (nNodes == 0) then
      bbox%min_coord = 0.0_wp
      bbox%max_coord = 0.0_wp
      bbox%center = 0.0_wp
      bbox%dimensions = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if

    bbox%min_coord = huge(1.0_wp)
    bbox%max_coord = -huge(1.0_wp)

    do i = 1, nNodes
      node_id = nodeset%GetNodeAt(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        x = coords(1, node_id)
        y = coords(2, node_id)
        z = coords(3, node_id)
        bbox%min_coord(1) = min(bbox%min_coord(1), x)
        bbox%min_coord(2) = min(bbox%min_coord(2), y)
        bbox%min_coord(3) = min(bbox%min_coord(3), z)
        bbox%max_coord(1) = max(bbox%max_coord(1), x)
        bbox%max_coord(2) = max(bbox%max_coord(2), y)
        bbox%max_coord(3) = max(bbox%max_coord(3), z)
      end if
    end do

    bbox%center = (bbox%min_coord + bbox%max_coord) / 2.0_wp
    bbox%dimensions = bbox%max_coord - bbox%min_coord
    status%status_code = IF_STATUS_OK
  end subroutine MD_SetBoundingBox_Calc

  !=============================================================================
  !> @brief Calculate distances between two node sets (legacy interface)
  !! @details Computes min/max/mean distances d = ||x ?- x?|| ? ?
  !! Theory: Distance d = ??(x?? - x??) ?, min/max/mean over all pairs
  !! @param[in] set1 First node set
  !! @param[in] set2 Second node set
  !! @param[in] coords Node coordinates X ??^(ndim nnode)
  !! @param[out] result Distance result
  !! @param[out] status Error status
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine MD_SetDistance_Calc(set1, set2, coords, result, status)
    type(MD_NodeSet), intent(in) :: set1
    type(MD_NodeSet), intent(in) :: set2
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetDistanceResult), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, node_id1, node_id2
    integer(i4) :: nNodes1, nNodes2
    real(wp) :: dist, min_dist, max_dist, sum_dist
    real(wp) :: coord1(3), coord2(3)

    call init_error_status(status)
    nNodes1 = set1%GetSize()
    nNodes2 = set2%GetSize()

    if (nNodes1 == 0 .or. nNodes2 == 0) then
      result%min_distance = 0.0_wp
      result%max_distance = 0.0_wp
      result%mean_distance = 0.0_wp
      result%closest_pair = 0
      result%farthest_pair = 0
      status%status_code = IF_STATUS_OK
      return
    end if

    min_dist = huge(1.0_wp)
    max_dist = 0.0_wp
    sum_dist = 0.0_wp
    result%closest_pair = 0
    result%farthest_pair = 0

    do i = 1, nNodes1
      node_id1 = set1%GetNodeAt(i)
      if (node_id1 > 0 .and. node_id1 <= size(coords, 2)) then
        coord1 = coords(:, node_id1)
        do j = 1, nNodes2
          node_id2 = set2%GetNodeAt(j)
          if (node_id2 > 0 .and. node_id2 <= size(coords, 2)) then
            coord2 = coords(:, node_id2)
            dist = sqrt(sum((coord1 - coord2)**2))
            if (dist < min_dist) then
              min_dist = dist
              result%closest_pair(1) = node_id1
              result%closest_pair(2) = node_id2
            end if
            if (dist > max_dist) then
              max_dist = dist
              result%farthest_pair(1) = node_id1
              result%farthest_pair(2) = node_id2
            end if
            sum_dist = sum_dist + dist
          end if
        end do
      end if
    end do

    result%min_distance = min_dist
    result%max_distance = max_dist
    result%mean_distance = sum_dist / real(nNodes1 * nNodes2, kind=wp)
    status%status_code = IF_STATUS_OK
  end subroutine MD_SetDistance_Calc

  subroutine MD_SetExport(nodeset, coords, export_format, status)
    type(MD_NodeSet), intent(in) :: nodeset
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetExportFormat), intent(in) :: export_format
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id, nNodes, unit
    real(wp) :: coord(3)

    call init_error_status(status)
    nNodes = nodeset%GetSize()

    if (nNodes == 0) then
      status%status_code = IF_STATUS_OK
      return
    end if

    open(newunit=unit, file=trim(export_format%filename), status='replace', action='write', iostat=status%status_code)
    if (status%status_code /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Failed to open file for writing"
      return
    end if

    if (export_format%include_metadata) then
      write(unit, '(A)') '*Node Set Export'
      write(unit, '(A,I0)') '*Number of nodes: ', nNodes
      write(unit, '(A)') '*Node ID, X, Y, Z'
    end if

    do i = 1, nNodes
      node_id = nodeset%GetNodeAt(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        coord = coords(:, node_id)
        write(unit, '(I0,3(1X,E15.8))') node_id, coord(1), coord(2), coord(3)
      end if
    end do

    close(unit)
    status%status_code = IF_STATUS_OK
  end subroutine MD_SetExport

  subroutine MD_SetGenerateByBox(all_nodes, coords, criteria, result, status)
    integer(i4), intent(in) :: all_nodes(:)
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetGenerationCriteria), intent(in) :: criteria
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id
    real(wp) :: coord(3)

    call init_error_status(status)
    call result%Init(0, "GeneratedByBox", size(all_nodes), status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, size(all_nodes)
      node_id = all_nodes(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        coord = coords(:, node_id)
        if (coord(1) >= criteria%box_min(1) .and. coord(1) <= criteria%box_max(1) .and. &
            coord(2) >= criteria%box_min(2) .and. coord(2) <= criteria%box_max(2) .and. &
            coord(3) >= criteria%box_min(3) .and. coord(3) <= criteria%box_max(3)) then
          call result%AddNode(node_id, status)
          if (status%status_code /= IF_STATUS_OK) return
        end if
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MD_SetGenerateByBox

  subroutine MD_SetGenerateByCylinder(all_nodes, coords, criteria, result, status)
    integer(i4), intent(in) :: all_nodes(:)
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetGenerationCriteria), intent(in) :: criteria
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id
    real(wp) :: coord(3), radial_dist, axial_dist
    real(wp) :: axis_dir(3), proj_point, axis_norm

    call init_error_status(status)
    call result%Init(0, "GeneratedByCylinder", size(all_nodes), status)
    if (status%status_code /= IF_STATUS_OK) return

    axis_norm = sqrt(sum(criteria%cylinder_axis**2))
    if (axis_norm > 1.0e-12_wp) then
      axis_dir = criteria%cylinder_axis / axis_norm
    else
      axis_dir = (/0.0_wp, 0.0_wp, 1.0_wp/)
    end if

    do i = 1, size(all_nodes)
      node_id = all_nodes(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        coord = coords(:, node_id)
        proj_point = sum((coord - criteria%cylinder_center) * axis_dir)
        axial_dist = abs(proj_point)
        radial_dist = sqrt(sum((coord - criteria%cylinder_center)**2) - proj_point**2)
        if (radial_dist <= criteria%cylinder_radius .and. axial_dist <= criteria%cylinder_height / 2.0_wp) then
          call result%AddNode(node_id, status)
          if (status%status_code /= IF_STATUS_OK) return
        end if
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MD_SetGenerateByCylinder

  subroutine MD_SetGenerateByPlane(all_nodes, coords, criteria, result, status)
    integer(i4), intent(in) :: all_nodes(:)
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetGenerationCriteria), intent(in) :: criteria
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id
    real(wp) :: coord(3), dist, normal_norm

    call init_error_status(status)
    call result%Init(0, "GeneratedByPlane", size(all_nodes), status)
    if (status%status_code /= IF_STATUS_OK) return

    normal_norm = sqrt(sum(criteria%plane_normal**2))
    if (normal_norm > 1.0e-12_wp) then
      do i = 1, size(all_nodes)
        node_id = all_nodes(i)
        if (node_id > 0 .and. node_id <= size(coords, 2)) then
          coord = coords(:, node_id)
          dist = sum((coord - criteria%plane_point) * criteria%plane_normal) / normal_norm
          if (abs(dist) <= 1.0e-6_wp) then
            call result%AddNode(node_id, status)
            if (status%status_code /= IF_STATUS_OK) return
          end if
        end if
      end do
    end if

    status%status_code = IF_STATUS_OK
  end subroutine MD_SetGenerateByPlane

  subroutine MD_SetGenerateBySphere(all_nodes, coords, criteria, result, status)
    integer(i4), intent(in) :: all_nodes(:)
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetGenerationCriteria), intent(in) :: criteria
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id
    real(wp) :: coord(3), dist

    call init_error_status(status)
    call result%Init(0, "GeneratedBySphere", size(all_nodes), status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, size(all_nodes)
      node_id = all_nodes(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        coord = coords(:, node_id)
        dist = sqrt(sum((coord - criteria%sphere_center)**2))
        if (dist <= criteria%sphere_radius) then
          call result%AddNode(node_id, status)
          if (status%status_code /= IF_STATUS_OK) return
        end if
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MD_SetGenerateBySphere

  subroutine MD_SetGenerateBySurface(surface, coords, result, status)
    type(MD_Surface), intent(in) :: surface
    real(wp), intent(in) :: coords(:,:)
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, element_id, num_facets
    type(MD_SurfFacet) :: facet

    call init_error_status(status)
    num_facets = surface%GetSize()

    call result%Init(0, trim(surface%name)//"_nodes", num_facets * 4, status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, num_facets
      facet = surface%GetFacet(i)
      element_id = facet%element_id

      if (element_id > 0) then
        call result%AddNode(element_id, status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    call result%Unique(status)
    status%status_code = IF_STATUS_OK
  end subroutine MD_SetGenerateBySurface

  subroutine MD_SetImport(filename, result, status)
    character(len=*), intent(in) :: filename
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: unit, node_id, ios
    real(wp) :: coord(3)
    character(len=256) :: line

    call init_error_status(status)

    open(newunit=unit, file=trim(filename), status='old', iostat=ios)
    if (ios /= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Failed to open file for reading"
      return
    end if

    call result%Init(0, "Imported", 1000, status)
    if (status%status_code /= IF_STATUS_OK) then
      close(unit)
      return
    end if

    do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit

      if (line(1:1) == '*') cycle

      read(line, *, iostat=ios) node_id, coord(1), coord(2), coord(3)
      if (ios == 0 .and. node_id > 0) then
        call result%AddNode(node_id, status)
        if (status%status_code /= IF_STATUS_OK) then
          close(unit)
          return
        end if
      end if
    end do

    close(unit)
    status%status_code = IF_STATUS_OK
  end subroutine MD_SetImport

  subroutine MD_SetOverlap_Check(set1, set2, coords, result, status)
    type(MD_NodeSet), intent(in) :: set1
    type(MD_NodeSet), intent(in) :: set2
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetOverlapResult), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id, nNodes1, nNodes2, overlap_count
    integer(i4), allocatable :: temp_nodes(:)

    call init_error_status(status)
    nNodes1 = set1%GetSize()
    nNodes2 = set2%GetSize()

    result%is_overlapping = .false.
    result%overlap_volume = 0.0_wp
    result%overlap_area = 0.0_wp

    if (nNodes1 == 0 .or. nNodes2 == 0) then
      status%status_code = IF_STATUS_OK
      return
    end if

    allocate(temp_nodes(min(nNodes1, nNodes2)))
    overlap_count = 0

    do i = 1, nNodes1
      node_id = set1%GetNodeAt(i)
      if (set2%Contains(node_id)) then
        overlap_count = overlap_count + 1
        temp_nodes(overlap_count) = node_id
      end if
    end do

    if (overlap_count > 0) then
      result%is_overlapping = .true.
      allocate(result%overlap_nodes(overlap_count))
      result%overlap_nodes(1:overlap_count) = temp_nodes(1:overlap_count)
    else
      allocate(result%overlap_nodes(0))
    end if

    allocate(result%overlap_elems(0))
    deallocate(temp_nodes)
    status%status_code = IF_STATUS_OK
  end subroutine MD_SetOverlap_Check

  function MD_SetSymmetry_CheckMirrored(nodeset, coords, mirrored_coord, tolerance) result(found)
    type(MD_NodeSet), intent(in) :: nodeset
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: mirrored_coord(3)
    real(wp), intent(in) :: tolerance
    logical :: found
    integer(i4) :: i, node_id, nNodes
    real(wp) :: dist

    found = .false.
    nNodes = nodeset%GetSize()

    do i = 1, nNodes
      node_id = nodeset%GetNodeAt(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        dist = sqrt(sum((coords(:, node_id) - mirrored_coord)**2))
        if (dist < tolerance) then
          found = .true.
          return
        end if
      end if
    end do
  end function MD_SetSymmetry_CheckMirrored

  subroutine MD_SetSymmetry_Detect(nodeset, coords, result, status)
    type(MD_NodeSet), intent(in) :: nodeset
    real(wp), intent(in) :: coords(:,:)
    type(MD_SetSymmetryResult), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, node_id, nNodes
    real(wp) :: coord(3), mirrored_coord(3)
    logical :: has_sym_x, has_sym_y, has_sym_z
    real(wp) :: tolerance

    call init_error_status(status)
    nNodes = nodeset%GetSize()

    if (nNodes == 0) then
      result%has_symmetry = .false.
      result%symmetry_type = 0
      result%symmetry_plane = 0.0_wp
      status%status_code = IF_STATUS_OK
      return
    end if

    tolerance = result%tolerance
    has_sym_x = .true.
    has_sym_y = .true.
    has_sym_z = .true.

    do i = 1, nNodes
      node_id = nodeset%GetNodeAt(i)
      if (node_id > 0 .and. node_id <= size(coords, 2)) then
        coord = coords(:, node_id)
        mirrored_coord(1) = -coord(1)
        mirrored_coord(2) = coord(2)
        mirrored_coord(3) = coord(3)
        has_sym_x = has_sym_x .and. MD_SetSymmetry_CheckMirrored(nodeset, coords, mirrored_coord, tolerance)
        mirrored_coord(1) = coord(1)
        mirrored_coord(2) = -coord(2)
        mirrored_coord(3) = coord(3)
        has_sym_y = has_sym_y .and. MD_SetSymmetry_CheckMirrored(nodeset, coords, mirrored_coord, tolerance)
        mirrored_coord(1) = coord(1)
        mirrored_coord(2) = coord(2)
        mirrored_coord(3) = -coord(3)
        has_sym_z = has_sym_z .and. MD_SetSymmetry_CheckMirrored(nodeset, coords, mirrored_coord, tolerance)
      end if
    end do

    result%has_symmetry = has_sym_x .or. has_sym_y .or. has_sym_z

    if (has_sym_x) then
      result%symmetry_type = 1
      result%symmetry_plane = (/1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp/)
    else if (has_sym_y) then
      result%symmetry_type = 2
      result%symmetry_plane = (/0.0_wp, 1.0_wp, 0.0_wp, 0.0_wp/)
    else if (has_sym_z) then
      result%symmetry_type = 3
      result%symmetry_plane = (/0.0_wp, 0.0_wp, 1.0_wp, 0.0_wp/)
    else
      result%symmetry_type = 0
      result%symmetry_plane = 0.0_wp
    end if

    status%status_code = IF_STATUS_OK
  end subroutine MD_SetSymmetry_Detect

  subroutine RemoveElem(this, element_id, status)
    class(MD_ElemSet), intent(inout) :: this
    integer(i4), intent(in) :: element_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, found_idx

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    found_idx = this%FindElem(element_id)
    if (found_idx == 0_i4) then
      status%status_code = IF_STATUS_OK
      return
    end if

    do i = found_idx, this%num_elems - 1
      this%element_ids(i) = this%element_ids(i + 1)
    end do

    this%num_elems = this%num_elems - 1_i4

    status%status_code = IF_STATUS_OK
  end subroutine RemoveElem

  subroutine RemoveFacet(this, index, status)
    class(MD_Surface), intent(inout) :: this
    integer(i4), intent(in) :: index
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    if (index < 1 .or. index > this%num_facets) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid facet index"
      return
    end if

    this%total_area = this%total_area - this%facets(index)%area

    do i = index, this%num_facets - 1
      this%facets(i) = this%facets(i + 1)
    end do

    this%num_facets = this%num_facets - 1_i4

    status%status_code = IF_STATUS_OK
  end subroutine RemoveFacet

  subroutine RemoveNode(this, node_id, status)
    class(MD_NodeSet), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, found_idx

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    found_idx = this%FindNode(node_id)
    if (found_idx == 0_i4) then
      status%status_code = IF_STATUS_OK
      return
    end if

    do i = found_idx, this%nNodes - 1
      this%node_ids(i) = this%node_ids(i + 1)
    end do

    this%nNodes = this%nNodes - 1_i4

    status%status_code = IF_STATUS_OK
  end subroutine RemoveNode

  subroutine Sort(this, status)
    class(MD_NodeSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    if (this%nNodes > 0) then
      call SortInt(this%node_ids(1:this%nNodes))
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Sort

  subroutine Sort(this, status)
    class(MD_ElemSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    if (this%num_elems > 0) then
      call SortInt(this%element_ids(1:this%num_elems))
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Sort

  subroutine Union(this, other, result, status)
    class(MD_NodeSet), intent(in) :: this
    type(MD_NodeSet), intent(in) :: other
    type(MD_NodeSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init .or. .not. other%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    call result%Init(this%set_id, trim(this%name)//"_union", this%nNodes + other%nNodes, status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, this%nNodes
      call result%AddNode(this%node_ids(i), status)
      if (status%status_code /= IF_STATUS_OK) return
    end do

    do i = 1, other%nNodes
      if (.not. result%Contains(other%node_ids(i))) then
        call result%AddNode(other%node_ids(i), status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine Union

  subroutine Union(this, other, result, status)
    class(MD_ElemSet), intent(in) :: this
    type(MD_ElemSet), intent(in) :: other
    type(MD_ElemSet), intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init .or. .not. other%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    call result%Init(this%set_id, trim(this%name)//"_union", this%num_elems + other%num_elems, status)
    if (status%status_code /= IF_STATUS_OK) return

    do i = 1, this%num_elems
      call result%AddElem(this%element_ids(i), status)
      if (status%status_code /= IF_STATUS_OK) return
    end do

    do i = 1, other%num_elems
      if (.not. result%Contains(other%element_ids(i))) then
        call result%AddElem(other%element_ids(i), status)
        if (status%status_code /= IF_STATUS_OK) return
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine Union

  subroutine Unique(this, status)
    class(MD_NodeSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: unique_count

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    if (this%nNodes > 0) then
      call SortInt(this%node_ids(1:this%nNodes))
      unique_count = UniqueInt(this%node_ids(1:this%nNodes), this%node_ids(1:this%nNodes))
      this%nNodes = unique_count
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Unique

  subroutine Unique(this, status)
    class(MD_ElemSet), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: unique_count

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    if (this%num_elems > 0) then
      call SortInt(this%element_ids(1:this%num_elems))
      unique_count = UniqueInt(this%element_ids(1:this%num_elems), this%element_ids(1:this%num_elems))
      this%num_elems = unique_count
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Unique

  subroutine Valid(this, status)
    class(MD_NodeSet), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet is not initialized"
      return
    end if

    if (this%set_id <= 0_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid set ID"
      return
    end if

    if (len_trim(this%name) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "NodeSet name is empty"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Valid

  subroutine Valid(this, status)
    class(MD_ElemSet), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet is not initialized"
      return
    end if

    if (this%set_id <= 0_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid set ID"
      return
    end if

    if (len_trim(this%name) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElemSet name is empty"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Valid

  subroutine Valid(this, status)
    class(MD_Surface), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface is not initialized"
      return
    end if

    if (this%surface_id <= 0_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid surface ID"
      return
    end if

    if (len_trim(this%name) == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Surface name is empty"
      return
    end if

    if (this%surface_type /= SURF_TYPE_ELEME .and. this%surface_type /= SURF_TYPE_NODE) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid surface type"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Valid
end MODULE MD_Sets_Def
