!===============================================================================
! MODULE: PH_Brg_L2
! LAYER:  L4_PH
! DOMAIN: Bridge
! ROLE:   Brg
! BRIEF:  L4->L2 bridge (elem connectivity, node coords, Gauss points)
!
! Contract: Bridge/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Bridge | Role:Brg_L2 | FuncSet:NM_Adapter
!>>> UFC_PH_CONTRACT | Bridge/CONTRACT.md

MODULE PH_Brg_L2
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Geom_Def, ONLY: MD_Geom_Ctx
  USE MD_Mesh_API, ONLY: MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg
  USE MD_GeomPH_Brg, ONLY: MD_PH_Geom_FillElemCtx_Idx, MD_PH_Geom_FillElemCtx_Arg
  USE NM_NumInt_Gauss_Core, ONLY: NM_Gauss1D_GetPoints, NM_Gauss2D_GetPoints, NM_Gauss3D_GetPoints
  USE PH_Elem_Def, ONLY: PH_Elem_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Brg_GetElemConnectivity_Arg
  PUBLIC :: PH_Brg_GetNodeCoords_Arg
  PUBLIC :: PH_Brg_GetGauss_Pts1D_Arg
  PUBLIC :: PH_Brg_GetGauss_Pts2D_Arg
  PUBLIC :: PH_Brg_GetGauss_Pts3D_Arg
  PUBLIC :: PH_Brg_ElemId_Desc
  PUBLIC :: PH_Brg_GetElemConnectivity, PH_Brg_GetElemConnectivity_Idx
  PUBLIC :: PH_Brg_GetNodeCoords, PH_Brg_GetNodeCoords_Idx
  PUBLIC :: PH_Brg_GetGaussPoints1D, PH_Brg_GetGaussPoints2D, PH_Brg_GetGaussPoints3D

  TYPE, PUBLIC :: PH_Brg_ElemId_Desc
    INTEGER(i4) :: elem_id = 0
  END TYPE PH_Brg_ElemId_Desc

  TYPE, PUBLIC :: PH_Brg_GetElemConnectivity_Arg
    TYPE(MD_Geom_Ctx) :: geom_ctx                   ! [IN]
    INTEGER(i4) :: elem_id                          ! [IN]
    INTEGER(i4), ALLOCATABLE :: conn(:)             ! [OUT]
    INTEGER(i4) :: n_nodes                          ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetElemConnectivity_Arg

  TYPE, PUBLIC :: PH_Brg_GetNodeCoords_Arg
    TYPE(PH_Elem_Ctx) :: elem_ctx                   ! [IN]
    REAL(wp), ALLOCATABLE :: coords(:,:)              ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetNodeCoords_Arg

  TYPE, PUBLIC :: PH_Brg_GetGauss_Pts1D_Arg
    INTEGER(i4) :: n_gp                             ! [IN]
    REAL(wp), ALLOCATABLE :: xi(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)             ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetGauss_Pts1D_Arg

  TYPE, PUBLIC :: PH_Brg_GetGauss_Pts2D_Arg
    INTEGER(i4) :: n_gp_per_dim                     ! [IN]
    REAL(wp), ALLOCATABLE :: xi(:,:)                ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)             ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetGauss_Pts2D_Arg

  TYPE, PUBLIC :: PH_Brg_GetGauss_Pts3D_Arg
    INTEGER(i4) :: n_gp_per_dim                     ! [IN]
    REAL(wp), ALLOCATABLE :: xi(:,:)                ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)             ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Brg_GetGauss_Pts3D_Arg

CONTAINS

  SUBROUTINE PH_Brg_GetElemConnectivity(arg)
    TYPE(PH_Brg_GetElemConnectivity_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    IF (.NOT. ALLOCATED(arg%geom_ctx%elem_descs) .OR. &
        arg%elem_id < 1 .OR. arg%elem_id > SIZE(arg%geom_ctx%elem_descs)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'PH_Brg_GetElemConnectivity: Invalid elem_id or geom_ctx'
      RETURN
    END IF
    arg%pop%n_nodes = arg%geom_ctx%elem_descs(arg%elem_id)%pop%n_nodes
    IF (ALLOCATED(arg%geom_ctx%elem_descs(arg%elem_id)%conn)) THEN
      IF (ALLOCATED(arg%conn)) DEALLOCATE(arg%conn)
      ALLOCATE(arg%conn(SIZE(arg%geom_ctx%elem_descs(arg%elem_id)%conn)))
      DO i = 1, SIZE(arg%geom_ctx%elem_descs(arg%elem_id)%conn)
        arg%conn(i) = arg%geom_ctx%elem_descs(arg%elem_id)%conn(i)
      END DO
    ELSE
      IF (ALLOCATED(arg%conn)) DEALLOCATE(arg%conn)
      ALLOCATE(arg%conn(0))
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Brg_GetElemConnectivity

  SUBROUTINE PH_Brg_GetElemConnectivity_Idx(elem_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(PH_Brg_GetElemConnectivity_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Mesh_GetElemConnect_Arg) :: arg_conn
    INTEGER(i4) :: k, npe
    CALL init_error_status(status)
    IF (ALLOCATED(arg%conn)) DEALLOCATE(arg%conn)
    arg%pop%n_nodes = 0_i4
    arg%status = status
    CALL MD_Mesh_GetElemConnect_Idx(elem_idx, arg_conn, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      arg%status = status
      RETURN
    END IF
    npe = arg_conn%npe
    arg%pop%n_nodes = npe
    IF (npe <= 0) THEN
      IF (ALLOCATED(arg%conn)) DEALLOCATE(arg%conn)
      ALLOCATE(arg%conn(0))
      status%status_code = IF_STATUS_OK
      arg%status = status
      RETURN
    END IF
    IF (ALLOCATED(arg%conn)) DEALLOCATE(arg%conn)
    ALLOCATE(arg%conn(npe))
    DO k = 1, npe
      arg%conn(k) = INT(arg_conn%connect(k), i4)
    END DO
    status%status_code = IF_STATUS_OK
    arg%status = status
  END SUBROUTINE PH_Brg_GetElemConnectivity_Idx

  SUBROUTINE PH_Brg_GetGaussPoints1D(arg)
    TYPE(PH_Brg_GetGauss_Pts1D_Arg), INTENT(INOUT) :: arg
    REAL(wp), ALLOCATABLE :: xi_local(:), weights_local(:)
    CALL init_error_status(arg%status)
    IF (arg%n_gp < 1 .OR. arg%n_gp > 10) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'PH_Brg_GetGaussPoints1D: Invalid n_gp (must be 1-10)'
      RETURN
    END IF
    ALLOCATE(xi_local(arg%n_gp), weights_local(arg%n_gp))
    CALL NM_Gauss1D_GetPoints(arg%n_gp, xi_local, weights_local, arg%status)
    IF (arg%status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(arg%xi)) DEALLOCATE(arg%xi)
      ALLOCATE(arg%xi(arg%n_gp))
      arg%xi = xi_local
      IF (ALLOCATED(arg%weights)) DEALLOCATE(arg%weights)
      ALLOCATE(arg%weights(arg%n_gp))
      arg%weights = weights_local
    END IF
    DEALLOCATE(xi_local, weights_local)
  END SUBROUTINE PH_Brg_GetGaussPoints1D

  SUBROUTINE PH_Brg_GetGaussPoints2D(arg)
    TYPE(PH_Brg_GetGauss_Pts2D_Arg), INTENT(INOUT) :: arg
    REAL(wp), ALLOCATABLE :: xi_local(:,:), weights_local(:)
    INTEGER(i4) :: n_total
    CALL init_error_status(arg%status)
    IF (arg%n_gp_per_dim < 1 .OR. arg%n_gp_per_dim > 10) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'PH_Brg_GetGaussPoints2D: Invalid n_gp_per_dim (must be 1-10)'
      RETURN
    END IF
    n_total = arg%n_gp_per_dim * arg%n_gp_per_dim
    ALLOCATE(xi_local(2, n_total), weights_local(n_total))
    CALL NM_Gauss2D_GetPoints(arg%n_gp_per_dim, xi_local, weights_local, arg%status)
    IF (arg%status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(arg%xi)) DEALLOCATE(arg%xi)
      ALLOCATE(arg%xi(2, n_total))
      arg%xi = xi_local
      IF (ALLOCATED(arg%weights)) DEALLOCATE(arg%weights)
      ALLOCATE(arg%weights(n_total))
      arg%weights = weights_local
    END IF
    DEALLOCATE(xi_local, weights_local)
  END SUBROUTINE PH_Brg_GetGaussPoints2D

  SUBROUTINE PH_Brg_GetGaussPoints3D(arg)
    TYPE(PH_Brg_GetGauss_Pts3D_Arg), INTENT(INOUT) :: arg
    REAL(wp), ALLOCATABLE :: xi_local(:,:), weights_local(:)
    INTEGER(i4) :: n_total
    CALL init_error_status(arg%status)
    IF (arg%n_gp_per_dim < 1 .OR. arg%n_gp_per_dim > 10) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'PH_Brg_GetGaussPoints3D: Invalid n_gp_per_dim (must be 1-10)'
      RETURN
    END IF
    n_total = arg%n_gp_per_dim * arg%n_gp_per_dim * arg%n_gp_per_dim
    ALLOCATE(xi_local(3, n_total), weights_local(n_total))
    CALL NM_Gauss3D_GetPoints(arg%n_gp_per_dim, xi_local, weights_local, arg%status)
    IF (arg%status%status_code == IF_STATUS_OK) THEN
      IF (ALLOCATED(arg%xi)) DEALLOCATE(arg%xi)
      ALLOCATE(arg%xi(3, n_total))
      arg%xi = xi_local
      IF (ALLOCATED(arg%weights)) DEALLOCATE(arg%weights)
      ALLOCATE(arg%weights(n_total))
      arg%weights = weights_local
    END IF
    DEALLOCATE(xi_local, weights_local)
  END SUBROUTINE PH_Brg_GetGaussPoints3D

  SUBROUTINE PH_Brg_GetNodeCoords(arg)
    TYPE(PH_Brg_GetNodeCoords_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: n_dim, n_nodes, i, j
    CALL init_error_status(arg%status)
    IF (.NOT. arg%elem_ctx%is_initialized .OR. .NOT. ALLOCATED(arg%elem_ctx%coords)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'PH_Brg_GetNodeCoords: Element context not initialized'
      RETURN
    END IF
    n_dim = SIZE(arg%elem_ctx%coords, 1)
    n_nodes = SIZE(arg%elem_ctx%coords, 2)
    IF (ALLOCATED(arg%coords)) DEALLOCATE(arg%coords)
    ALLOCATE(arg%coords(n_dim, n_nodes))
    DO j = 1, n_nodes
      DO i = 1, n_dim
        arg%coords(i, j) = arg%elem_ctx%coords(i, j)
      END DO
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Brg_GetNodeCoords

  SUBROUTINE PH_Brg_GetNodeCoords_Idx(elem_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(PH_Brg_GetNodeCoords_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_PH_Geom_FillElemCtx_Arg) :: arg_ctx
    INTEGER(i4) :: n_dim, n_nodes, i, j
    CALL init_error_status(status)
    arg%status = status
    CALL MD_PH_Geom_FillElemCtx_Idx(elem_idx, arg_ctx)
    IF (arg_ctx%status%status_code /= IF_STATUS_OK) THEN
      status = arg_ctx%status
      arg%status = status
      RETURN
    END IF
    IF (.NOT. arg_ctx%elem_ctx%is_initialized .OR. .NOT. ALLOCATED(arg_ctx%elem_ctx%coords)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_Brg_GetNodeCoords_Idx: Element context not initialized'
      arg%status = status
      RETURN
    END IF
    n_dim = SIZE(arg_ctx%elem_ctx%coords, 1)
    n_nodes = SIZE(arg_ctx%elem_ctx%coords, 2)
    IF (ALLOCATED(arg%coords)) DEALLOCATE(arg%coords)
    ALLOCATE(arg%coords(n_dim, n_nodes))
    DO j = 1, n_nodes
      DO i = 1, n_dim
        arg%coords(i, j) = arg_ctx%elem_ctx%coords(i, j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
    arg%status = status
  END SUBROUTINE PH_Brg_GetNodeCoords_Idx
END MODULE PH_Brg_L2