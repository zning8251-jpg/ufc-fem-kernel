!===============================================================================
! MODULE:  MD_Mesh_Search
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Spatial node search — P0 Search: bucket grid for O(1) lookup,
!          range search, nearest-node search.
!===============================================================================
MODULE MD_Mesh_Search
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mesh_Def, ONLY: MD_Mesh_Desc
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! MD_Mesh_BucketGrid — uniform spatial bucket grid for node lookup
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_BUCKET_MAX_PER_CELL = 64

  TYPE, PUBLIC :: MD_Mesh_BucketGrid
    INTEGER(i4) :: nx = 0, ny = 0, nz = 0       ! Grid dimensions
    REAL(wp)    :: x_min = 0.0_wp, y_min = 0.0_wp, z_min = 0.0_wp
    REAL(wp)    :: dx = 1.0_wp, dy = 1.0_wp, dz = 1.0_wp
    INTEGER(i4), ALLOCATABLE :: cell_count(:,:,:)            ! (nx,ny,nz)
    INTEGER(i4), ALLOCATABLE :: cell_nodes(:,:,:,:)          ! (max_per_cell,nx,ny,nz)
    LOGICAL :: initialized = .FALSE.
  END TYPE MD_Mesh_BucketGrid

  PUBLIC :: MD_Mesh_Search_Build_Grid
  PUBLIC :: MD_Mesh_Search_Finalize
  PUBLIC :: MD_Mesh_Search_Find_Nearest
  PUBLIC :: MD_Mesh_Search_Find_In_Box

CONTAINS

  !====================================================================
  ! MD_Mesh_Search_Build_Grid — build uniform bucket grid from mesh nodes
  !
  ! n_buckets_per_dim: number of cells per axis (e.g. 10→10x10x10 grid)
  !====================================================================
  SUBROUTINE MD_Mesh_Search_Build_Grid(desc, grid, n_buckets_per_dim, status)
    TYPE(MD_Mesh_Desc),       INTENT(IN)    :: desc
    TYPE(MD_Mesh_BucketGrid), INTENT(INOUT) :: grid
    INTEGER(i4),               INTENT(IN)    :: n_buckets_per_dim
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i, ix, iy, iz, nb, cnt
    REAL(wp) :: xmin, ymin, zmin, xmax, ymax, zmax, eps

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(desc%coords) .OR. desc%pop%n_nodes <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! Compute bounding box
    xmin = desc%coords(1, 1); xmax = xmin
    ymin = desc%coords(2, 1); ymax = ymin
    zmin = 0.0_wp; zmax = 0.0_wp
    IF (desc%cfg%ndim >= 3) THEN
      zmin = desc%coords(3, 1); zmax = zmin
    END IF

    DO i = 2, desc%pop%n_nodes
      xmin = MIN(xmin, desc%coords(1, i))
      xmax = MAX(xmax, desc%coords(1, i))
      ymin = MIN(ymin, desc%coords(2, i))
      ymax = MAX(ymax, desc%coords(2, i))
      IF (desc%cfg%ndim >= 3) THEN
        zmin = MIN(zmin, desc%coords(3, i))
        zmax = MAX(zmax, desc%coords(3, i))
      END IF
    END DO

    ! Pad bounding box
    eps = 1.0E-10_wp
    nb = MAX(1_i4, n_buckets_per_dim)

    grid%nx = nb; grid%ny = nb
    grid%nz = MERGE(nb, 1_i4, desc%cfg%ndim >= 3)
    grid%x_min = xmin - eps
    grid%y_min = ymin - eps
    grid%z_min = zmin - eps
    grid%dx = (xmax - xmin + 2.0_wp * eps) / REAL(grid%nx, wp)
    grid%dy = (ymax - ymin + 2.0_wp * eps) / REAL(grid%ny, wp)
    grid%dz = MERGE((zmax - zmin + 2.0_wp * eps) / REAL(grid%nz, wp), &
                    1.0_wp, desc%cfg%ndim >= 3)

    IF (grid%dx <= 0.0_wp) grid%dx = 1.0_wp
    IF (grid%dy <= 0.0_wp) grid%dy = 1.0_wp
    IF (grid%dz <= 0.0_wp) grid%dz = 1.0_wp

    IF (ALLOCATED(grid%cell_count)) DEALLOCATE(grid%cell_count)
    IF (ALLOCATED(grid%cell_nodes)) DEALLOCATE(grid%cell_nodes)
    ALLOCATE(grid%cell_count(grid%nx, grid%ny, grid%nz))
    ALLOCATE(grid%cell_nodes(MD_BUCKET_MAX_PER_CELL, grid%nx, grid%ny, grid%nz))
    grid%cell_count = 0
    grid%cell_nodes = 0

    ! Insert nodes into grid
    DO i = 1, desc%pop%n_nodes
      ix = node_to_cell_x(desc%coords(1, i), grid)
      iy = node_to_cell_y(desc%coords(2, i), grid)
      iz = 1
      IF (desc%cfg%ndim >= 3) iz = node_to_cell_z(desc%coords(3, i), grid)

      cnt = grid%cell_count(ix, iy, iz)
      IF (cnt < MD_BUCKET_MAX_PER_CELL) THEN
        grid%cell_count(ix, iy, iz) = cnt + 1
        grid%cell_nodes(cnt + 1, ix, iy, iz) = i
      END IF
    END DO

    grid%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Search_Build_Grid

  !====================================================================
  ! MD_Mesh_Search_Finalize — release bucket grid memory
  !====================================================================
  SUBROUTINE MD_Mesh_Search_Finalize(grid)
    TYPE(MD_Mesh_BucketGrid), INTENT(INOUT) :: grid

    IF (ALLOCATED(grid%cell_count)) DEALLOCATE(grid%cell_count)
    IF (ALLOCATED(grid%cell_nodes)) DEALLOCATE(grid%cell_nodes)
    grid%initialized = .FALSE.
  END SUBROUTINE MD_Mesh_Search_Finalize

  !====================================================================
  ! MD_Mesh_Search_Find_Nearest — find closest node to query point
  !====================================================================
  SUBROUTINE MD_Mesh_Search_Find_Nearest(desc, grid, query_pt, &
                                          nearest_id, dist, status)
    TYPE(MD_Mesh_Desc),       INTENT(IN)  :: desc
    TYPE(MD_Mesh_BucketGrid), INTENT(IN)  :: grid
    REAL(wp),                  INTENT(IN)  :: query_pt(3)
    INTEGER(i4),               INTENT(OUT) :: nearest_id
    REAL(wp),                  INTENT(OUT) :: dist
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: cx, cy, cz, di, dj, dk, ix, iy, iz, k, nid
    REAL(wp) :: d2, best_d2

    CALL init_error_status(status)
    nearest_id = 0
    dist = HUGE(1.0_wp)

    IF (.NOT. grid%initialized .OR. .NOT. ASSOCIATED(desc%coords)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    cx = node_to_cell_x(query_pt(1), grid)
    cy = node_to_cell_y(query_pt(2), grid)
    cz = node_to_cell_z(query_pt(3), grid)

    best_d2 = HUGE(1.0_wp)

    ! Search 3x3x3 neighborhood around target cell
    DO di = -1, 1
      ix = cx + di
      IF (ix < 1 .OR. ix > grid%nx) CYCLE
      DO dj = -1, 1
        iy = cy + dj
        IF (iy < 1 .OR. iy > grid%ny) CYCLE
        DO dk = -1, 1
          iz = cz + dk
          IF (iz < 1 .OR. iz > grid%nz) CYCLE

          DO k = 1, grid%cell_count(ix, iy, iz)
            nid = grid%cell_nodes(k, ix, iy, iz)
            IF (nid < 1 .OR. nid > desc%pop%n_nodes) CYCLE
            d2 = (desc%coords(1, nid) - query_pt(1))**2 + &
                 (desc%coords(2, nid) - query_pt(2))**2
            IF (desc%cfg%ndim >= 3) d2 = d2 + (desc%coords(3, nid) - query_pt(3))**2
            IF (d2 < best_d2) THEN
              best_d2 = d2
              nearest_id = nid
            END IF
          END DO
        END DO
      END DO
    END DO

    dist = SQRT(best_d2)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Search_Find_Nearest

  !====================================================================
  ! MD_Mesh_Search_Find_In_Box — find all nodes in bounding box
  !====================================================================
  SUBROUTINE MD_Mesh_Search_Find_In_Box(desc, grid, box_min, box_max, &
                                         node_ids, n_found, status)
    TYPE(MD_Mesh_Desc),       INTENT(IN)  :: desc
    TYPE(MD_Mesh_BucketGrid), INTENT(IN)  :: grid
    REAL(wp),                  INTENT(IN)  :: box_min(3), box_max(3)
    INTEGER(i4),               INTENT(OUT) :: node_ids(:)
    INTEGER(i4),               INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: ix_lo, ix_hi, iy_lo, iy_hi, iz_lo, iz_hi
    INTEGER(i4) :: ix, iy, iz, k, nid
    REAL(wp)    :: px, py, pz

    CALL init_error_status(status)
    n_found = 0
    node_ids = 0

    IF (.NOT. grid%initialized .OR. .NOT. ASSOCIATED(desc%coords)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ix_lo = MAX(1_i4, node_to_cell_x(box_min(1), grid))
    ix_hi = MIN(grid%nx, node_to_cell_x(box_max(1), grid))
    iy_lo = MAX(1_i4, node_to_cell_y(box_min(2), grid))
    iy_hi = MIN(grid%ny, node_to_cell_y(box_max(2), grid))
    iz_lo = MAX(1_i4, node_to_cell_z(box_min(3), grid))
    iz_hi = MIN(grid%nz, node_to_cell_z(box_max(3), grid))

    DO ix = ix_lo, ix_hi
      DO iy = iy_lo, iy_hi
        DO iz = iz_lo, iz_hi
          DO k = 1, grid%cell_count(ix, iy, iz)
            nid = grid%cell_nodes(k, ix, iy, iz)
            IF (nid < 1 .OR. nid > desc%pop%n_nodes) CYCLE
            px = desc%coords(1, nid)
            py = desc%coords(2, nid)
            pz = 0.0_wp
            IF (desc%cfg%ndim >= 3) pz = desc%coords(3, nid)

            IF (px >= box_min(1) .AND. px <= box_max(1) .AND. &
                py >= box_min(2) .AND. py <= box_max(2) .AND. &
                pz >= box_min(3) .AND. pz <= box_max(3)) THEN
              IF (n_found < SIZE(node_ids)) THEN
                n_found = n_found + 1
                node_ids(n_found) = nid
              END IF
            END IF
          END DO
        END DO
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Search_Find_In_Box

  !====================================================================
  ! PRIVATE helpers: coordinate-to-cell mapping
  !====================================================================
  PURE INTEGER(i4) FUNCTION node_to_cell_x(x, grid) RESULT(ix)
    REAL(wp),                  INTENT(IN) :: x
    TYPE(MD_Mesh_BucketGrid), INTENT(IN) :: grid
    ix = MAX(1_i4, MIN(grid%nx, INT((x - grid%x_min) / grid%dx, i4) + 1_i4))
  END FUNCTION node_to_cell_x

  PURE INTEGER(i4) FUNCTION node_to_cell_y(y, grid) RESULT(iy)
    REAL(wp),                  INTENT(IN) :: y
    TYPE(MD_Mesh_BucketGrid), INTENT(IN) :: grid
    iy = MAX(1_i4, MIN(grid%ny, INT((y - grid%y_min) / grid%dy, i4) + 1_i4))
  END FUNCTION node_to_cell_y

  PURE INTEGER(i4) FUNCTION node_to_cell_z(z, grid) RESULT(iz)
    REAL(wp),                  INTENT(IN) :: z
    TYPE(MD_Mesh_BucketGrid), INTENT(IN) :: grid
    iz = MAX(1_i4, MIN(grid%nz, INT((z - grid%z_min) / grid%dz, i4) + 1_i4))
  END FUNCTION node_to_cell_z

END MODULE MD_Mesh_Search
