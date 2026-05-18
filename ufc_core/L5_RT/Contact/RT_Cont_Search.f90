!===============================================================================
! MODULE: RT_Cont_Search
! LAYER:  L5_RT
! DOMAIN: Contact
! ROLE:   Search — contact search adapter (delegates to L4_PH)
! BRIEF:  Spatial hash, octree, BVH, broad/narrow phase search strategies.
!===============================================================================
MODULE RT_Cont_Search
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Int_API, ONLY: ContPairDef, ContCandidate
  USE PH_Cont_Search, ONLY: PH_Cont_SearchPairs, PH_ContSearch_Result

  IMPLICIT NONE
  PRIVATE

  !===============================================================================
  ! PUBLIC INTERFACES
  !===============================================================================
  public :: RT_Cont_Search_SpatHash
  public :: RT_Cont_Search_Octree
  public :: RT_Cont_Search_BVH
  public :: RT_Cont_Search_BroadPhase
  public :: RT_Cont_Search_NarrowPhase
  public :: RT_Cont_InitSpatHash
  public :: RT_Cont_InitSpatHashFromRadius
  public :: RT_Cont_InitOctree
  public :: RT_Cont_BuildBVH
  public :: RT_Cont_ProjectPointToSeg
  public :: RT_Cont_ProjectPointToTri
  public :: RT_Cont_GapAndNormal
  public :: RT_Cont_Search_SpatHash_SlavePartition
  public :: RT_Cont_MergeCandidates
  public :: RT_Cont_FilterSameNode
  public :: RT_Cont_FilterSameSurface
  public :: RT_Cont_Search_WithStrategy
  public :: RT_Cont_SearchStrategy

  !===============================================================================
  ! TYPES
  !===============================================================================
  type :: RT_Cont_SearchStrategy
    logical :: use_global_sear = .true.
    logical :: use_candidate_c = .false.
    real(wp) :: cache_valid_rad = 0.0_wp
    integer(i4) :: max_cached_pair = 0
  end type RT_Cont_SearchStrategy

  !===============================================================================
  ! TYPES (continued)
  !===============================================================================
  type :: RT_Cont_SpatHashGrid
    integer(i4) :: nx, ny, nz              ! Grid dimensions
    real(wp) :: cell_size(3)                ! Cell size in each direction
    real(wp) :: bbox_min(3), bbox_max(3)   ! Bounding box
    integer(i4), allocatable :: cell_indices(:,:,:)  ! Cell index array
    integer(i4), allocatable :: cell_lists(:)        ! Flat list of node indices
    integer(i4), allocatable :: cell_starts(:)       ! Start index for each cell
    integer(i4), allocatable :: cell_counts(:)       ! Count per cell
    integer(i4) :: max_nodes_per_c               ! Maximum nodes per cell
  end type RT_Cont_SpatHashGrid

  type :: RT_Cont_OctreeNode
    real(wp) :: center(3)                   ! Node center
    real(wp) :: half_size(3)                ! Half size of bounding box
    integer(i4) :: node_count               ! Number of nodes in this node
    integer(i4), allocatable :: node_indices(:)  ! Indices of nodes
    type(RT_Cont_OctreeNode), pointer :: children(2,2,2) => null()  ! 8 children
    logical :: is_leaf                      ! Leaf node flag
  end type RT_Cont_OctreeNode

  type :: RT_Cont_BVHNode
    real(wp) :: bbox_min(3), bbox_max(3)   ! Bounding box
    integer(i4) :: left_child              ! Left child index (-1 if leaf)
    integer(i4) :: right_child             ! Right child index (-1 if leaf)
    integer(i4) :: node_count              ! Number of nodes in this node
    integer(i4), allocatable :: node_indices(:)  ! Indices of nodes (if leaf)
  end type RT_Cont_BVHNode

  type :: RT_Cont_BVHTree
    type(RT_Cont_BVHNode), allocatable :: nodes(:)
    integer(i4) :: root_index
    integer(i4) :: node_count
  end type RT_Cont_BVHTree
  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: RT_Cont_Search_Core_Args
  TYPE :: RT_Cont_Search_Core_Args
  ! Purpose: ����
  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Cont_Search_Core_Args


CONTAINS

  subroutine barycentric_triangle(a, b, c, p, xi, eta, status)
    real(wp), intent(in) :: a(3), b(3), c(3), p(3)
    real(wp), intent(out) :: xi, eta
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: v0(3), v1(3), v2(3), dot00, dot01, dot02, dot11, dot12, den
    call init_error_status(status)
    v0 = c - a
    v1 = b - a
    v2 = p - a
    dot00 = sum(v0*v0)
    dot01 = sum(v0*v1)
    dot02 = sum(v0*v2)
    dot11 = sum(v1*v1)
    dot12 = sum(v1*v2)
    den = dot00*dot11 - dot01*dot01
    if (abs(den) <= 1.0e-20_wp) then
      xi = 0.0_wp
      eta = 0.0_wp
      return
    end if
    eta = (dot11*dot02 - dot01*dot12) / den
    xi = (dot00*dot12 - dot01*dot02) / den
    status%status_code = IF_STATUS_OK
  end subroutine barycentric_triangle

  recursive subroutine BuildOctreeRecursive(node, coords, max_nodes_per_l, status)
    type(RT_Cont_OctreeNode), pointer, intent(inout) :: node
    real(wp), intent(in) :: coords(:,:)
    integer(i4), intent(in) :: max_nodes_per_l
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, child_idx, node_idx
    integer(i4) :: child_counts(2,2,2)
    real(wp) :: child_center(3), offset(3)
    integer(i4), allocatable :: child_node_indi(:,:)

    call init_error_status(status)

    ! If node has fewer nodes than threshold, keep as leaf
    if (node%node_count <= max_nodes_per_l) then
      node%is_leaf = .true.
      status%status_code = IF_STATUS_OK
      return
    end if

    ! Subdivide into 8 children
    node%is_leaf = .false.
    child_counts = 0

    ! Count nodes in each octant
    do i = 1, node%node_count
      node_idx = node%node_indices(i)
      offset = coords(node_idx, :) - node%center
      
      ! Determine octant
      j = 1
      if (offset(1) >= 0.0_wp) j = 2
      k = 1
      if (offset(2) >= 0.0_wp) k = 2
      i = 1
      if (offset(3) >= 0.0_wp) i = 2
      
      child_counts(i, k, j) = child_counts(i, k, j) + 1
    end do

    ! Create children
    do i = 1, 2
      do j = 1, 2
        do k = 1, 2
          if (child_counts(i, j, k) > 0) then
            allocate(node%children(i, j, k))
            child_center = node%center
            child_center(1) = child_center(1) + (i - 1.5_wp) * node%half_size(1)
            child_center(2) = child_center(2) + (j - 1.5_wp) * node%half_size(2)
            child_center(3) = child_center(3) + (k - 1.5_wp) * node%half_size(3)
            
            node%children(i, j, k)%center = child_center
            node%children(i, j, k)%half_size = node%half_size * 0.5_wp
            node%children(i, j, k)%node_count = child_counts(i, j, k)
            allocate(node%children(i, j, k)%node_indices(child_counts(i, j, k)))
            
            ! Fill node indices
            child_idx = 1
            do node_idx = 1, node%node_count
              offset = coords(node%node_indices(node_idx), :) - node%center
              if (offset(1) >= 0.0_wp .eqv. (i == 2) .and. &
                  offset(2) >= 0.0_wp .eqv. (j == 2) .and. &
                  offset(3) >= 0.0_wp .eqv. (k == 2)) then
                node%children(i, j, k)%node_indices(child_idx) = node%node_indices(node_idx)
                child_idx = child_idx + 1
              end if
            end do
            
            ! Recursively build child
            call BuildOctreeRecursive(node%children(i, j, k), coords, &
                                     max_nodes_per_l, status)
            if (status%status_code /= IF_STATUS_OK) return
          end if
        end do
      end do
    end do

    status%status_code = IF_STATUS_OK

  end subroutine BuildOctreeRecursive

  recursive subroutine BVHBuildRecursive(bvh_tree, coords, indices, start, end_idx, bmin, bmax, max_leaf, status)
    type(RT_Cont_BVHTree), intent(inout) :: bvh_tree
    real(wp), intent(in) :: coords(:,:)
    integer(i4), intent(inout) :: indices(:)
    integer(i4), intent(in) :: start, end_idx
    real(wp), intent(in) :: bmin(3), bmax(3)
    integer(i4), intent(in) :: max_leaf
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, mid, axis, j, left_count, this_idx
    real(wp) :: extent(3), split_val
    integer(i4) :: new_cap
    type(RT_Cont_BVHNode), allocatable :: tmp(:)

    call init_error_status(status)
    n = end_idx - start + 1
    if (n <= 0) return
    if (.not. allocated(bvh_tree%nodes)) then
      allocate(bvh_tree%nodes(64))
      bvh_tree%node_count = 0
    end if
    if (bvh_tree%node_count >= size(bvh_tree%nodes)) then
      new_cap = 2 * size(bvh_tree%nodes)
      allocate(tmp(new_cap))
      tmp(1:size(bvh_tree%nodes)) = bvh_tree%nodes(1:size(bvh_tree%nodes))
      call move_alloc(tmp, bvh_tree%nodes)
    end if
    bvh_tree%node_count = bvh_tree%node_count + 1
    this_idx = bvh_tree%node_count
    bvh_tree%nodes(this_idx)%bbox_min = bmin
    bvh_tree%nodes(this_idx)%bbox_max = bmax
    if (n <= max_leaf) then
      bvh_tree%nodes(this_idx)%left_child = -1
      bvh_tree%nodes(this_idx)%right_child = -1
      bvh_tree%nodes(this_idx)%node_count = n
      allocate(bvh_tree%nodes(this_idx)%node_indices(n))
      bvh_tree%nodes(this_idx)%node_indices(1:n) = indices(start:end_idx)
      status%status_code = IF_STATUS_OK
      return
    end if
    extent = bmax - bmin
    axis = 1
    if (extent(2) >= extent(1) .and. extent(2) >= extent(3)) axis = 2
    if (extent(3) >= extent(1) .and. extent(3) >= extent(2)) axis = 3
    split_val = (bmin(axis) + bmax(axis)) * 0.5_wp
    mid = start
    do j = start, end_idx
      if (coords(indices(j), axis) < split_val) then
        call swap_int(indices(mid), indices(j))
        mid = mid + 1
      end if
    end do
    left_count = mid - start
    if (left_count <= 0 .or. left_count >= n) mid = start + n / 2
    bvh_tree%nodes(this_idx)%node_count = 0
    bvh_tree%nodes(this_idx)%left_child = bvh_tree%node_count + 1
    call BVHBuildRecursive(bvh_tree, coords, indices, start, mid - 1, bmin, bmax, max_leaf, status)
    if (status%status_code /= IF_STATUS_OK) return
    bvh_tree%nodes(this_idx)%right_child = bvh_tree%node_count + 1
    call BVHBuildRecursive(bvh_tree, coords, indices, mid, end_idx, bmin, bmax, max_leaf, status)
  end subroutine BVHBuildRecursive

  recursive subroutine BVHSearchRecursive(bvh_tree, node_idx, coords, &
                                         search_radius_s, candidates, &
                                         n_candidates, status)
    type(RT_Cont_BVHTree), intent(in) :: bvh_tree
    integer(i4), intent(in) :: node_idx
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius_s
    type(ContCandidate), intent(inout) :: candidates(:)
    integer(i4), intent(inout) :: n_candidates
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j
    real(wp) :: dist_sq, dist_vec(3)

    call init_error_status(status)

    if (node_idx < 1 .or. node_idx > size(bvh_tree%nodes)) then
      status%status_code = IF_STATUS_OK
      return
    end if

    ! Check if bounding box intersects search sphere (simplified)
    ! In production, use proper sphere-AABB intersection test

    if (bvh_tree%nodes(node_idx)%left_child < 0) then
      ! Leaf node: check distances between nodes
      do i = 1, bvh_tree%nodes(node_idx)%node_count
        do j = i + 1, bvh_tree%nodes(node_idx)%node_count
          dist_vec = coords(bvh_tree%nodes(node_idx)%node_indices(i), :) - &
                     coords(bvh_tree%nodes(node_idx)%node_indices(j), :)
          dist_sq = sum(dist_vec**2)
          if (dist_sq <= search_radius_s) then
            n_candidates = n_candidates + 1
            if (n_candidates <= size(candidates)) then
              candidates(n_candidates)%slave_node = &
                bvh_tree%nodes(node_idx)%node_indices(i)
              candidates(n_candidates)%master_segment = &
                bvh_tree%nodes(node_idx)%node_indices(j)
              candidates(n_candidates)%distance = sqrt(dist_sq)
            end if
          end if
        end do
      end do
    else
      ! Internal node: recursively search children
      call BVHSearchRecursive(bvh_tree, bvh_tree%nodes(node_idx)%left_child, &
                             coords, search_radius_s, candidates, &
                             n_candidates, status)
      if (status%status_code /= IF_STATUS_OK) return

      call BVHSearchRecursive(bvh_tree, bvh_tree%nodes(node_idx)%right_child, &
                             coords, search_radius_s, candidates, &
                             n_candidates, status)
      if (status%status_code /= IF_STATUS_OK) return
    end if

    status%status_code = IF_STATUS_OK

  end subroutine BVHSearchRecursive

  recursive subroutine OctreeSearchRecursive(node, coords, search_radius_s, &
                                            candidates, n_candidates, status)
    type(RT_Cont_OctreeNode), pointer, intent(in) :: node
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius_s
    type(ContCandidate), intent(inout) :: candidates(:)
    integer(i4), intent(inout) :: n_candidates
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k
    real(wp) :: bbox_min(3), bbox_max(3), dist_vec(3)
    real(wp) :: dist_sq

    call init_error_status(status)

    if (.not. associated(node)) then
      status%status_code = IF_STATUS_OK
      return
    end if

    ! Compute bounding box
    bbox_min = node%center - node%half_size
    bbox_max = node%center + node%half_size

    ! Check if bounding box intersects search sphere (simplified)
    ! In production, use proper sphere-AABB intersection test

    if (node%is_leaf) then
      ! Check distances between nodes in this leaf
      do i = 1, node%node_count
        do j = i + 1, node%node_count
          dist_vec = coords(node%node_indices(i), :) - coords(node%node_indices(j), :)
          dist_sq = sum(dist_vec**2)
          if (dist_sq <= search_radius_s) then
            n_candidates = n_candidates + 1
            if (n_candidates <= size(candidates)) then
              candidates(n_candidates)%slave_node = node%node_indices(i)
              candidates(n_candidates)%master_segment = node%node_indices(j)
              candidates(n_candidates)%distance = sqrt(dist_sq)
            end if
          end if
        end do
      end do
    else
      ! Recursively search children
      do i = 1, 2
        do j = 1, 2
          do k = 1, 2
            if (associated(node%children(i, j, k))) then
              call OctreeSearchRecursive(node%children(i, j, k), coords, &
                                        search_radius_s, candidates, &
                                        n_candidates, status)
              if (status%status_code /= IF_STATUS_OK) return
            end if
          end do
        end do
      end do
    end if

    status%status_code = IF_STATUS_OK

  end subroutine OctreeSearchRecursive

  subroutine swap_int(a, b)
    integer(i4), intent(inout) :: a, b
    integer(i4) :: t
    t = a
    a = b
    b = t
  end subroutine swap_int

  subroutine RT_Cont_InitSpatHashFromRadius(coords, search_radius, &
      cell_size_facto, grid, status)
    !! Init spatial hash with cell_size from search_radius (B1 adaptive).
    !! cell_size = search_radius * cell_size_facto (e.g. 1.0). 3x3x3 in RT_Cont_Search_SpatHash.
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius
    real(wp), intent(in) :: cell_size_facto
    type(RT_Cont_SpatHashGrid), intent(out) :: grid
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: cell_size_unifo
    integer(i4) :: n_nodes, i, cell_i, cell_j, cell_k, cell_idx
    real(wp) :: bbox_size(3)

    call init_error_status(status)
    n_nodes = size(coords, 1)
    if (n_nodes == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Cont_InitSpatHashFromRadius: No nodes'
      return
    end if
    if (search_radius <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Cont_InitSpatHashFromRadius: search_radius <= 0'
      return
    end if
    grid%bbox_min = minval(coords, dim=1)
    grid%bbox_max = maxval(coords, dim=1)
    bbox_size = grid%bbox_max - grid%bbox_min
    cell_size_unifo = search_radius * max(0.25_wp, min(2.0_wp, cell_size_facto))
    grid%cell_size(1) = cell_size_unifo
    grid%cell_size(2) = cell_size_unifo
    grid%cell_size(3) = cell_size_unifo
    grid%nx = max(1, int(bbox_size(1) / grid%cell_size(1)) + 1)
    grid%ny = max(1, int(bbox_size(2) / grid%cell_size(2)) + 1)
    grid%nz = max(1, int(bbox_size(3) / grid%cell_size(3)) + 1)
    allocate(grid%cell_starts(grid%nx * grid%ny * grid%nz))
    allocate(grid%cell_counts(grid%nx * grid%ny * grid%nz))
    allocate(grid%cell_lists(n_nodes))
    grid%cell_starts = 0
    grid%cell_counts = 0
    do i = 1, n_nodes
      cell_i = int((coords(i, 1) - grid%bbox_min(1)) / grid%cell_size(1)) + 1
      cell_j = int((coords(i, 2) - grid%bbox_min(2)) / grid%cell_size(2)) + 1
      cell_k = int((coords(i, 3) - grid%bbox_min(3)) / grid%cell_size(3)) + 1
      cell_i = max(1, min(grid%nx, cell_i))
      cell_j = max(1, min(grid%ny, cell_j))
      cell_k = max(1, min(grid%nz, cell_k))
      cell_idx = (cell_k - 1) * grid%nx * grid%ny + (cell_j - 1) * grid%nx + cell_i
      grid%cell_counts(cell_idx) = grid%cell_counts(cell_idx) + 1
    end do
    grid%cell_starts(1) = 1
    do i = 2, size(grid%cell_starts)
      grid%cell_starts(i) = grid%cell_starts(i-1) + grid%cell_counts(i-1)
    end do
    grid%cell_counts = 0
    do i = 1, n_nodes
      cell_i = int((coords(i, 1) - grid%bbox_min(1)) / grid%cell_size(1)) + 1
      cell_j = int((coords(i, 2) - grid%bbox_min(2)) / grid%cell_size(2)) + 1
      cell_k = int((coords(i, 3) - grid%bbox_min(3)) / grid%cell_size(3)) + 1
      cell_i = max(1, min(grid%nx, cell_i))
      cell_j = max(1, min(grid%ny, cell_j))
      cell_k = max(1, min(grid%nz, cell_k))
      cell_idx = (cell_k - 1) * grid%nx * grid%ny + (cell_j - 1) * grid%nx + cell_i
      grid%cell_counts(cell_idx) = grid%cell_counts(cell_idx) + 1
      grid%cell_lists(grid%cell_starts(cell_idx) + grid%cell_counts(cell_idx) - 1) = i
    end do
    grid%max_nodes_per_c = maxval(grid%cell_counts)
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_InitSpatHashFromRadius

  subroutine RT_Cont_ProjectPointToSeg(p, seg_a, seg_b, proj, t, dist_sq, status)
    !! Project point p onto segment [seg_a, seg_b]. proj = seg_a + t*(seg_b - seg_a), t in [0,1].
    real(wp), intent(in) :: p(3), seg_a(3), seg_b(3)
    real(wp), intent(out) :: proj(3)
    real(wp), intent(out) :: t
    real(wp), intent(out) :: dist_sq
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: ab(3), ap(3), len_sq, den

    call init_error_status(status)
    ab = seg_b - seg_a
    ap = p - seg_a
    len_sq = sum(ab**2)
    if (len_sq <= 1.0e-20_wp) then
      proj = seg_a
      t = 0.0_wp
      dist_sq = sum(ap**2)
      status%status_code = IF_STATUS_OK
      return
    end if
    t = (ap(1)*ab(1) + ap(2)*ab(2) + ap(3)*ab(3)) / len_sq
    t = max(0.0_wp, min(1.0_wp, t))
    proj = seg_a + t * ab
    dist_sq = sum((p - proj)**2)
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_ProjectPointToSeg

  subroutine RT_Cont_ProjectPointToTri(p, tri_a, tri_b, tri_c, proj, xi, eta, dist_sq, normal, status)
    !! Project point p onto triangle (tri_a, tri_b, tri_c). Barycentric xi, eta; normal outward.
    real(wp), intent(in) :: p(3), tri_a(3), tri_b(3), tri_c(3)
    real(wp), intent(out) :: proj(3)
    real(wp), intent(out) :: xi, eta
    real(wp), intent(out) :: dist_sq
    real(wp), intent(out) :: normal(3)
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: ab(3), ac(3), ap(3), n(3), len_n
    real(wp) :: d, t, u, v

    call init_error_status(status)
    ab = tri_b - tri_a
    ac = tri_c - tri_a
    n(1) = ab(2)*ac(3) - ab(3)*ac(2)
    n(2) = ab(3)*ac(1) - ab(1)*ac(3)
    n(3) = ab(1)*ac(2) - ab(2)*ac(1)
    len_n = sqrt(sum(n**2))
    if (len_n <= 1.0e-20_wp) then
      proj = tri_a
      xi = 0.0_wp
      eta = 0.0_wp
      dist_sq = sum((p - tri_a)**2)
      normal = [0.0_wp, 0.0_wp, 1.0_wp]
      status%status_code = IF_STATUS_OK
      return
    end if
    normal = n / len_n
    ap = p - tri_a
    d = ap(1)*normal(1) + ap(2)*normal(2) + ap(3)*normal(3)
    proj = p - d * normal
    call barycentric_triangle(tri_a, tri_b, tri_c, proj, xi, eta, status)
    if (status%status_code /= IF_STATUS_OK) return
    xi = max(0.0_wp, min(1.0_wp, xi))
    eta = max(0.0_wp, min(1.0_wp, eta))
    if (xi + eta > 1.0_wp) then
      t = xi + eta
      xi = xi / t
      eta = eta / t
    end if
    proj = tri_a + xi * (tri_b - tri_a) + eta * (tri_c - tri_a)
    dist_sq = sum((p - proj)**2)
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_ProjectPointToTri

  subroutine RT_Cont_SpatHashSlavePartition(grid, coords, search_radius, &
      slave_start, slave_end, candidates, status)
    !! Search contact pairs for slave nodes in [slave_start, slave_end]. Master = all nodes (read-only grid).
    !! Caller can partition slave range for parallel; then merge with RT_Cont_MergeCandidates.
    type(RT_Cont_SpatHashGrid), intent(in) :: grid
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius
    integer(i4), intent(in) :: slave_start, slave_end
    type(ContCandidate), allocatable, intent(out) :: candidates(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i, j, cell_i, cell_j, cell_k, di, dj, dk
    integer(i4) :: neighbor_i, neighbor_j, neighbor_k, cell_idx, neighbor_idx
    integer(i4) :: n_candidates
    real(wp) :: search_radius_s
    type(ContCandidate), allocatable :: temp_candidates(:)

    call init_error_status(status)
    n_nodes = size(coords, 1)
    search_radius_s = search_radius * search_radius
    n_candidates = 0
    allocate(temp_candidates(max(1, (slave_end - slave_start + 1) * 27)))
    do i = slave_start, slave_end
      cell_i = int((coords(i, 1) - grid%bbox_min(1)) / grid%cell_size(1)) + 1
      cell_j = int((coords(i, 2) - grid%bbox_min(2)) / grid%cell_size(2)) + 1
      cell_k = int((coords(i, 3) - grid%bbox_min(3)) / grid%cell_size(3)) + 1
      cell_i = max(1, min(grid%nx, cell_i))
      cell_j = max(1, min(grid%ny, cell_j))
      cell_k = max(1, min(grid%nz, cell_k))
      do di = -1, 1
        do dj = -1, 1
          do dk = -1, 1
            neighbor_i = cell_i + di
            neighbor_j = cell_j + dj
            neighbor_k = cell_k + dk
            if (neighbor_i < 1 .or. neighbor_i > grid%nx .or. neighbor_j < 1 .or. neighbor_j > grid%ny .or. neighbor_k < 1 .or. neighbor_k > grid%nz) cycle
            cell_idx = (neighbor_k - 1) * grid%nx * grid%ny + (neighbor_j - 1) * grid%nx + neighbor_i
            if (cell_idx > size(grid%cell_starts)) cycle
            do j = grid%cell_starts(cell_idx), grid%cell_starts(cell_idx) + grid%cell_counts(cell_idx) - 1
              neighbor_idx = grid%cell_lists(j)
              if (neighbor_idx == i) cycle
              if (sum((coords(i, :) - coords(neighbor_idx, :))**2) <= search_radius_s) then
                n_candidates = n_candidates + 1
                if (n_candidates <= size(temp_candidates)) then
                  temp_candidates(n_candidates)%slave_node = i
                  temp_candidates(n_candidates)%master_segment = neighbor_idx
                  temp_candidates(n_candidates)%distance = sqrt(sum((coords(i, :) - coords(neighbor_idx, :))**2))
                end if
              end if
            end do
          end do
        end do
      end do
    end do
    if (n_candidates > 0 .and. n_candidates <= size(temp_candidates)) then
      allocate(candidates(n_candidates))
      candidates(1:n_candidates) = temp_candidates(1:n_candidates)
    else
      allocate(candidates(0))
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_Search_SpatHash_SlavePartition

  subroutine RT_Cont_FilterSameNode(candidates, filtered, status)
    !! Remove pairs where slave_node == master_segment (same node).
    type(ContCandidate), intent(in) :: candidates(:)
    type(ContCandidate), allocatable, intent(out) :: filtered(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, i, m
    call init_error_status(status)
    n = size(candidates)
    m = 0
    do i = 1, n
      if (candidates(i)%slave_node /= candidates(i)%master_segment) m = m + 1
    end do
    allocate(filtered(m))
    m = 0
    do i = 1, n
      if (candidates(i)%slave_node /= candidates(i)%master_segment) then
        m = m + 1
        filtered(m) = candidates(i)
      end if
    end do
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_FilterSameNode

  subroutine RT_Cont_FilterSameSurface(candidates, node_surf_id, seg_surf_id, filtered, status)
    !! Remove pairs where slave and master belong to same surface (optional self-contact filter).
    type(ContCandidate), intent(in) :: candidates(:)
    integer(i4), intent(in) :: node_surf_id(:)
    integer(i4), intent(in) :: seg_surf_id(:)
    type(ContCandidate), allocatable, intent(out) :: filtered(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n, i, m, sn, ms
    call init_error_status(status)
    n = size(candidates)
    m = 0
    do i = 1, n
      sn = candidates(i)%slave_node
      ms = candidates(i)%master_segment
      if (sn < 1 .or. sn > size(node_surf_id)) cycle
      if (ms < 1 .or. ms > size(seg_surf_id)) cycle
      if (node_surf_id(sn) /= seg_surf_id(ms)) m = m + 1
    end do
    allocate(filtered(m))
    m = 0
    do i = 1, n
      sn = candidates(i)%slave_node
      ms = candidates(i)%master_segment
      if (sn >= 1 .and. sn <= size(node_surf_id) .and. ms >= 1 .and. ms <= size(seg_surf_id)) then
        if (node_surf_id(sn) /= seg_surf_id(ms)) then
          m = m + 1
          filtered(m) = candidates(i)
        end if
      end if
    end do
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_FilterSameSurface

  subroutine RT_Cont_GapAndNormal(slave_pt, master_pts, n_master, master_type, gap, normal, status)
    !! Gap = (slave_pt - proj) �� normal; normal outward from master. Penetration: gap < 0.
    real(wp), intent(in) :: slave_pt(3)
    real(wp), intent(in) :: master_pts(3, *)
    integer(i4), intent(in) :: n_master
    integer(i4), intent(in) :: master_type
    real(wp), intent(out) :: gap
    real(wp), intent(out) :: normal(3)
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: proj(3), seg_a(3), seg_b(3), tri_a(3), tri_b(3), tri_c(3)
    real(wp) :: t, xi, eta, dist_sq

    call init_error_status(status)
    if (master_type == 1 .and. n_master >= 2) then
      seg_a = master_pts(1:3, 1)
      seg_b = master_pts(1:3, 2)
      call RT_Cont_ProjectPointToSeg(slave_pt, seg_a, seg_b, proj, t, dist_sq, status)
      if (status%status_code /= IF_STATUS_OK) return
      normal = (slave_pt - proj)
      if (sum(normal**2) > 1.0e-20_wp) normal = normal / sqrt(sum(normal**2))
      gap = sqrt(dist_sq)
      if (sum((slave_pt - proj)*normal) < 0.0_wp) gap = -gap
    else if (master_type == 2 .and. n_master >= 3) then
      tri_a = master_pts(1:3, 1)
      tri_b = master_pts(1:3, 2)
      tri_c = master_pts(1:3, 3)
      call RT_Cont_ProjectPointToTri(slave_pt, tri_a, tri_b, tri_c, proj, xi, eta, dist_sq, normal, status)
      if (status%status_code /= IF_STATUS_OK) return
      gap = (slave_pt(1) - proj(1))*normal(1) + (slave_pt(2) - proj(2))*normal(2) + (slave_pt(3) - proj(3))*normal(3)
    else
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Cont_GapAndNormal: invalid master_type or n_master'
      gap = 0.0_wp
      normal = [0.0_wp, 0.0_wp, 1.0_wp]
    end if
  end subroutine RT_Cont_GapAndNormal

  subroutine RT_Cont_InitSpatHash(coords, cell_size_facto, grid, status)
    !! Init spatial hash grid from node coordinates
    
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: cell_size_facto  ! Factor for cell size
    type(RT_Cont_SpatHashGrid), intent(out) :: grid
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i, cell_i, cell_j, cell_k, cell_idx
    real(wp) :: bbox_size(3), avg_cell_size

    call init_error_status(status)

    n_nodes = size(coords, 1)
    if (n_nodes == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Cont_InitSpatHash: No nodes'
      return
    end if

    ! Compute bounding box
    grid%bbox_min = minval(coords, dim=1)
    grid%bbox_max = maxval(coords, dim=1)
    bbox_size = grid%bbox_max - grid%bbox_min

    ! Compute cell size
    avg_cell_size = (bbox_size(1) + bbox_size(2) + bbox_size(3)) / 3.0_wp
    grid%cell_size = avg_cell_size * cell_size_facto

    ! Compute grid dimensions
    grid%nx = max(1, int(bbox_size(1) / grid%cell_size(1)) + 1)
    grid%ny = max(1, int(bbox_size(2) / grid%cell_size(2)) + 1)
    grid%nz = max(1, int(bbox_size(3) / grid%cell_size(3)) + 1)

    ! Allocate cell arrays
    allocate(grid%cell_starts(grid%nx * grid%ny * grid%nz))
    allocate(grid%cell_counts(grid%nx * grid%ny * grid%nz))
    allocate(grid%cell_lists(n_nodes))
    grid%cell_starts = 0
    grid%cell_counts = 0

    ! First pass: count nodes per cell
    do i = 1, n_nodes
      cell_i = int((coords(i, 1) - grid%bbox_min(1)) / grid%cell_size(1)) + 1
      cell_j = int((coords(i, 2) - grid%bbox_min(2)) / grid%cell_size(2)) + 1
      cell_k = int((coords(i, 3) - grid%bbox_min(3)) / grid%cell_size(3)) + 1

      cell_i = max(1, min(grid%nx, cell_i))
      cell_j = max(1, min(grid%ny, cell_j))
      cell_k = max(1, min(grid%nz, cell_k))

      cell_idx = (cell_k - 1) * grid%nx * grid%ny + &
                 (cell_j - 1) * grid%nx + cell_i
      grid%cell_counts(cell_idx) = grid%cell_counts(cell_idx) + 1
    end do

    ! Compute start indices
    grid%cell_starts(1) = 1
    do i = 2, size(grid%cell_starts)
      grid%cell_starts(i) = grid%cell_starts(i-1) + grid%cell_counts(i-1)
    end do

    ! Second pass: fill cell lists
    grid%cell_counts = 0  ! Reset for second pass
    do i = 1, n_nodes
      cell_i = int((coords(i, 1) - grid%bbox_min(1)) / grid%cell_size(1)) + 1
      cell_j = int((coords(i, 2) - grid%bbox_min(2)) / grid%cell_size(2)) + 1
      cell_k = int((coords(i, 3) - grid%bbox_min(3)) / grid%cell_size(3)) + 1

      cell_i = max(1, min(grid%nx, cell_i))
      cell_j = max(1, min(grid%ny, cell_j))
      cell_k = max(1, min(grid%nz, cell_k))

      cell_idx = (cell_k - 1) * grid%nx * grid%ny + &
                 (cell_j - 1) * grid%nx + cell_i
      
      grid%cell_counts(cell_idx) = grid%cell_counts(cell_idx) + 1
      grid%cell_lists(grid%cell_starts(cell_idx) + grid%cell_counts(cell_idx) - 1) = i
    end do

    grid%max_nodes_per_c = maxval(grid%cell_counts)
    status%status_code = IF_STATUS_OK

  end subroutine RT_Cont_InitSpatHash

  subroutine RT_Cont_MergeCandidates(cand_all, part_counts, n_parts, merged, status)
    !! Merge candidate lists from n_parts partitions. cand_all is concatenated; part_counts(i) = length of part i.
    type(ContCandidate), intent(in) :: cand_all(:)
    integer(i4), intent(in) :: part_counts(:)
    integer(i4), intent(in) :: n_parts
    type(ContCandidate), allocatable, intent(out) :: merged(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: total
    call init_error_status(status)
    if (n_parts <= 0) then
      allocate(merged(0))
      status%status_code = IF_STATUS_OK
      return
    end if
    total = sum(part_counts(1:n_parts))
    if (total <= 0 .or. total > size(cand_all)) then
      allocate(merged(0))
      status%status_code = IF_STATUS_OK
      return
    end if
    allocate(merged(total))
    merged(1:total) = cand_all(1:total)
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_MergeCandidates

  subroutine RT_Cont_Search_NarrowPhase(coords, candidates, search_radius, &
                                           refined_candida, status)
    !! Narrow phase search with exact distance computation
    
    real(wp), intent(in) :: coords(:,:)
    type(ContCandidate), intent(in) :: candidates(:)
    real(wp), intent(in) :: search_radius
    type(ContCandidate), allocatable, intent(out) :: refined_candida(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_candidates, i, n_refined
    real(wp) :: dist, dist_sq
    real(wp) :: search_radius_s
    type(ContCandidate), allocatable :: temp_refined(:)

    call init_error_status(status)

    n_candidates = size(candidates)
    search_radius_s = search_radius * search_radius
    allocate(temp_refined(n_candidates))
    n_refined = 0

    ! Compute exact distances
    do i = 1, n_candidates
      if (candidates(i)%slave_node > 0 .and. &
          candidates(i)%master_segment > 0) then
        dist_sq = sum((coords(candidates(i)%slave_node, :) - &
                       coords(candidates(i)%master_segment, :))**2)
        dist = sqrt(dist_sq)

        if (dist <= search_radius) then
          n_refined = n_refined + 1
          temp_refined(n_refined) = candidates(i)
          temp_refined(n_refined)%distance = dist
        end if
      end if
    end do

    ! Allocate final refined candidates array
    if (n_refined > 0) then
      allocate(refined_candida(n_refined))
      refined_candida(1:n_refined) = temp_refined(1:n_refined)
    else
      allocate(refined_candida(0))
    end if

    status%status_code = IF_STATUS_OK

  end subroutine RT_Cont_Search_NarrowPhase

  subroutine RT_Cont_Search_Octree(octree_root, coords, search_radius, &
                                     candidates, status)
    !! Octree search for contact pairs
    !!
    !! Algorithm:
    !!   1. Traverse octree nodes
    !!   2. Check bounding box intersections
    !!   3. Compute distances within search radius
    !!
    !! Reference: Ericson (2005), Chapter 6.2
    
    type(RT_Cont_OctreeNode), pointer, intent(in) :: octree_root
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius
    type(ContCandidate), allocatable, intent(out) :: candidates(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, n_candidates
    type(ContCandidate), allocatable :: temp_candidates(:)
    real(wp) :: search_radius_s

    call init_error_status(status)

    n_nodes = size(coords, 1)
    search_radius_s = search_radius * search_radius
    allocate(temp_candidates(n_nodes * 8))  ! Estimate
    n_candidates = 0

    ! Recursive search
    call OctreeSearchRecursive(octree_root, coords, search_radius_s, &
                               temp_candidates, n_candidates, status)
    if (status%status_code /= IF_STATUS_OK) return

    ! Allocate final candidates array
    if (n_candidates > 0) then
      allocate(candidates(n_candidates))
      candidates(1:n_candidates) = temp_candidates(1:n_candidates)
    else
      allocate(candidates(0))
    end if

  end subroutine RT_Cont_Search_Octree

  subroutine RT_Cont_Search_SpatHash(grid, coords, search_radius, &
                                           candidates, status)
    !! Spatial Hash Grid search for contact pairs
    !!
    !! Algorithm:
    !!   1. Hash each node to a cell
    !!   2. Check neighboring cells (3x3x3 neighborhood)
    !!   3. Compute distances within search radius
    !!
    !! Reference: Ericson (2005), Chapter 3.3
    
    type(RT_Cont_SpatHashGrid), intent(in) :: grid
    real(wp), intent(in) :: coords(:,:)        ! Node coordinates (n_nodes, 3)
    real(wp), intent(in) :: search_radius
    type(ContCandidate), allocatable, intent(out) :: candidates(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i, j, k, cell_i, cell_j, cell_k
    integer(i4) :: di, dj, dk, neighbor_i, neighbor_j, neighbor_k
    integer(i4) :: node_idx, neighbor_idx, n_candidates
    integer(i4) :: cell_idx, neighbor_cell_i
    real(wp) :: dist, dist_sq
    real(wp) :: search_radius_s
    type(ContCandidate), allocatable :: temp_candidates(:)

    call init_error_status(status)

    n_nodes = size(coords, 1)
    search_radius_s = search_radius * search_radius
    n_candidates = 0
    allocate(temp_candidates(n_nodes * 27))  ! Max 27 neighbors per node

    ! For each node, search in 3x3x3 neighborhood
    do i = 1, n_nodes
      ! Compute cell indices for current node
      cell_i = int((coords(i, 1) - grid%bbox_min(1)) / grid%cell_size(1)) + 1
      cell_j = int((coords(i, 2) - grid%bbox_min(2)) / grid%cell_size(2)) + 1
      cell_k = int((coords(i, 3) - grid%bbox_min(3)) / grid%cell_size(3)) + 1

      ! Clamp to valid range
      cell_i = max(1, min(grid%nx, cell_i))
      cell_j = max(1, min(grid%ny, cell_j))
      cell_k = max(1, min(grid%nz, cell_k))

      ! Search in 3x3x3 neighborhood
      do di = -1, 1
        do dj = -1, 1
          do dk = -1, 1
            neighbor_i = cell_i + di
            neighbor_j = cell_j + dj
            neighbor_k = cell_k + dk

            ! Check bounds
            if (neighbor_i < 1 .or. neighbor_i > grid%nx .or. &
                neighbor_j < 1 .or. neighbor_j > grid%ny .or. &
                neighbor_k < 1 .or. neighbor_k > grid%nz) cycle

            ! Get cell index
            cell_idx = (neighbor_k - 1) * grid%nx * grid%ny + &
                       (neighbor_j - 1) * grid%nx + neighbor_i

            ! Check nodes in this cell
            if (cell_idx <= size(grid%cell_starts)) then
              do j = grid%cell_starts(cell_idx), &
                     grid%cell_starts(cell_idx) + grid%cell_counts(cell_idx) - 1
                neighbor_idx = grid%cell_lists(j)

                ! Skip self
                if (neighbor_idx == i) cycle

                ! Compute distance
                dist_sq = sum((coords(i, :) - coords(neighbor_idx, :))**2)

                if (dist_sq <= search_radius_s) then
                  n_candidates = n_candidates + 1
                  if (n_candidates <= size(temp_candidates)) then
                    temp_candidates(n_candidates)%slave_node = i
                    temp_candidates(n_candidates)%master_segment = neighbor_idx
                    temp_candidates(n_candidates)%distance = sqrt(dist_sq)
                  end if
                end if
              end do
            end if
          end do
        end do
      end do
    end do

    ! Allocate final candidates array
    if (n_candidates > 0) then
      allocate(candidates(n_candidates))
      candidates(1:n_candidates) = temp_candidates(1:n_candidates)
    else
      allocate(candidates(0))
    end if

    status%status_code = IF_STATUS_OK

  end subroutine RT_Cont_Search_SpatHash

  subroutine RT_Cont_Search_WithStrategy(grid, coords, search_radius, strategy, &
      previous_candid, candidates, status)
    !! Full search or reuse previous_candid (narrow-phase only) based on strategy.
    type(RT_Cont_SpatHashGrid), intent(in) :: grid
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius
    type(RT_Cont_SearchStrategy), intent(in) :: strategy
    type(ContCandidate), intent(in), optional :: previous_candid(:)
    type(ContCandidate), allocatable, intent(out) :: candidates(:)
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: search_radius_s
    integer(i4) :: i, n_prev, n_refined, n_nodes, sn, ms
    type(ContCandidate), allocatable :: refined(:)

    call init_error_status(status)
    if (strategy%use_candidate_c .and. present(previous_candid) .and. size(previous_candid) > 0) then
      n_prev = size(previous_candid)
      n_nodes = size(coords, 1)
      search_radius_s = search_radius * search_radius
      n_refined = 0
      allocate(refined(n_prev))
      do i = 1, n_prev
        sn = previous_candid(i)%slave_node
        ms = previous_candid(i)%master_segment
        if (sn > 0 .and. sn <= n_nodes .and. ms > 0 .and. ms <= n_nodes) then
          if (sum((coords(sn, :) - coords(ms, :))**2) <= search_radius_s) then
            n_refined = n_refined + 1
            refined(n_refined) = previous_candid(i)
            refined(n_refined)%distance = sqrt(sum((coords(sn, :) - coords(ms, :))**2))
          end if
        end if
      end do
      allocate(candidates(n_refined))
      candidates(1:n_refined) = refined(1:n_refined)
    else
      call RT_Cont_Search_SpatHash(grid, coords, search_radius, candidates, status)
    end if
    status%status_code = IF_STATUS_OK
  end subroutine RT_Cont_Search_WithStrategy

  subroutine RT_Cont_BuildBVH(coords, max_leaf_size, bvh_tree, status)
    !! Build BVH from node coordinates; median split along longest axis.
    type(RT_Cont_BVHTree), intent(inout) :: bvh_tree
    real(wp), intent(in) :: coords(:,:)
    integer(i4), intent(in) :: max_leaf_size
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i
    integer(i4), allocatable :: indices(:)
    real(wp) :: bmin(3), bmax(3)

    call init_error_status(status)
    n_nodes = size(coords, 1)
    if (allocated(bvh_tree%nodes)) deallocate(bvh_tree%nodes)
    bvh_tree%node_count = 0
    bvh_tree%root_index = -1
    if (n_nodes == 0) then
      status%status_code = IF_STATUS_OK
      return
    end if
    allocate(indices(n_nodes))
    do i = 1, n_nodes
      indices(i) = i
    end do
    bmin = minval(coords, dim=1)
    bmax = maxval(coords, dim=1)
    bvh_tree%root_index = -1
    call BVHBuildRecursive(bvh_tree, coords, indices, 1, n_nodes, bmin, bmax, max_leaf_size, status)
    if (bvh_tree%node_count >= 1) bvh_tree%root_index = 1
    deallocate(indices)
  end subroutine RT_Cont_BuildBVH

  subroutine RT_Cont_InitOctree(coords, max_nodes_per_l, &
                                        octree_root, status)
    !! Init octree from node coordinates
    
    real(wp), intent(in) :: coords(:,:)
    integer(i4), intent(in) :: max_nodes_per_l
    type(RT_Cont_OctreeNode), pointer, intent(out) :: octree_root
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i
    real(wp) :: bbox_min(3), bbox_max(3), center(3), half_size(3)
    integer(i4), allocatable :: node_indices(:)

    call init_error_status(status)

    n_nodes = size(coords, 1)
    if (n_nodes == 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Cont_InitOctree: No nodes'
      return
    end if

    ! Compute bounding box
    bbox_min = minval(coords, dim=1)
    bbox_max = maxval(coords, dim=1)
    center = (bbox_min + bbox_max) * 0.5_wp
    half_size = (bbox_max - bbox_min) * 0.5_wp

    ! Allocate root node
    allocate(octree_root)
    octree_root%center = center
    octree_root%half_size = half_size
    octree_root%node_count = n_nodes
    allocate(octree_root%node_indices(n_nodes))
    do i = 1, n_nodes
      octree_root%node_indices(i) = i
    end do
    octree_root%is_leaf = .true.

    ! Build octree recursively
    call BuildOctreeRecursive(octree_root, coords, max_nodes_per_l, status)

  end subroutine RT_Cont_InitOctree

  subroutine RT_Cont_Search_BroadPhase(coords, bbox_min, bbox_max, &
                                          candidates, status)
    !! Broad phase search using axis-aligned bounding boxes
    
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: bbox_min(3), bbox_max(3)
    type(ContCandidate), allocatable, intent(out) :: candidates(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, i, n_candidates
    type(ContCandidate), allocatable :: temp_candidates(:)

    call init_error_status(status)

    n_nodes = size(coords, 1)
    allocate(temp_candidates(n_nodes))
    n_candidates = 0

    ! Check which nodes are within bounding box
    do i = 1, n_nodes
      if (coords(i, 1) >= bbox_min(1) .and. coords(i, 1) <= bbox_max(1) .and. &
          coords(i, 2) >= bbox_min(2) .and. coords(i, 2) <= bbox_max(2) .and. &
          coords(i, 3) >= bbox_min(3) .and. coords(i, 3) <= bbox_max(3)) then
        n_candidates = n_candidates + 1
        temp_candidates(n_candidates)%slave_node = i
        temp_candidates(n_candidates)%master_segment = 0  ! Will be set in narrow phase
      end if
    end do

    ! Allocate final candidates array
    if (n_candidates > 0) then
      allocate(candidates(n_candidates))
      candidates(1:n_candidates) = temp_candidates(1:n_candidates)
    else
      allocate(candidates(0))
    end if

    status%status_code = IF_STATUS_OK

  end subroutine RT_Cont_Search_BroadPhase

  subroutine RT_Cont_Search_BVH(bvh_tree, coords, search_radius, &
                                   candidates, status)
    !! Bounding Volume Hierarchy search for contact pairs
    !!
    !! Algorithm:
    !!   1. Traverse BVH tree
    !!   2. Check bounding box intersections
    !!   3. Compute distances within search radius
    !!
    !! Reference: Ericson (2005), Chapter 6.4
    
    type(RT_Cont_BVHTree), intent(in) :: bvh_tree
    real(wp), intent(in) :: coords(:,:)
    real(wp), intent(in) :: search_radius
    type(ContCandidate), allocatable, intent(out) :: candidates(:)
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n_nodes, n_candidates
    type(ContCandidate), allocatable :: temp_candidates(:)
    real(wp) :: search_radius_s

    call init_error_status(status)

    n_nodes = size(coords, 1)
    search_radius_s = search_radius * search_radius
    allocate(temp_candidates(n_nodes * 8))  ! Estimate
    n_candidates = 0

    ! Recursive search starting from root
    if (bvh_tree%root_index > 0 .and. bvh_tree%root_index <= size(bvh_tree%nodes)) then
      call BVHSearchRecursive(bvh_tree, bvh_tree%root_index, coords, &
                              search_radius_s, temp_candidates, n_candidates, status)
      if (status%status_code /= IF_STATUS_OK) return
    end if

    ! Allocate final candidates array
    if (n_candidates > 0) then
      allocate(candidates(n_candidates))
      candidates(1:n_candidates) = temp_candidates(1:n_candidates)
    else
      allocate(candidates(0))
    end if

  end subroutine RT_Cont_Search_BVH
END MODULE RT_Cont_Search