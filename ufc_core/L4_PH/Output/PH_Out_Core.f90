!===============================================================================
! MODULE: PH_Out_Core
! LAYER:  L4_PH
! DOMAIN: Output
! ROLE:   Core — core output physics computation
! BRIEF:  Coordinate transformations, tensor rotations, IP→node extrapolation.
!         Called by PH_Out_Brg as physics engine.
!
! DESIGN NOTE: This module is the L4 "hot path" for output physics.
!   It computes but does NOT trigger or schedule — trigger/IO is L5 responsibility.
!===============================================================================
MODULE PH_Out_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Out_Def, ONLY: PH_Out_Desc, PH_Out_State, PH_Out_Algo, PH_Out_Ctx, PH_Out_Arg
  IMPLICIT NONE
  PRIVATE

  ! Public procedures
  PUBLIC :: PH_Out_CoordTransform
  PUBLIC :: PH_Out_TensorRotate
  PUBLIC :: PH_Out_IPtoNode_Extrapolate
  PUBLIC :: PH_Out_FieldInterpolate

CONTAINS

  !=============================================================================
  !> Coordinate transformation (global → local system)
  !=============================================================================
  SUBROUTINE PH_Out_CoordTransform(coords_global, rotation_matrix, coords_local, status)
    REAL(wp), INTENT(IN)  :: coords_global(:,:)
    REAL(wp), INTENT(IN)  :: rotation_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: coords_local(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, npts

    CALL init_error_status(status)

    npts = SIZE(coords_global, 2)
    IF (SIZE(coords_global, 1) /= 3 .OR. SIZE(coords_local, 1) /= 3 .OR. &
        SIZE(coords_local, 2) < npts) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_Out_CoordTransform: dimension mismatch'
      RETURN
    END IF

    DO i = 1, npts
      coords_local(:, i) = MATMUL(rotation_matrix, coords_global(:, i))
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Out_CoordTransform

  !=============================================================================
  !> Tensor rotation (Voigt stress/strain → rotated coordinate system)
  !=============================================================================
  SUBROUTINE PH_Out_TensorRotate(tensor_in, rotation_matrix, tensor_out, status)
    REAL(wp), INTENT(IN)  :: tensor_in(6)
    REAL(wp), INTENT(IN)  :: rotation_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: tensor_out(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: full(3, 3), rot_full(3, 3)

    CALL init_error_status(status)

    ! Voigt → full tensor
    full(1,1) = tensor_in(1)  ! σxx
    full(2,2) = tensor_in(2)  ! σyy
    full(3,3) = tensor_in(3)  ! σzz
    full(1,2) = tensor_in(4)  ! σxy
    full(2,1) = tensor_in(4)
    full(2,3) = tensor_in(5)  ! σyz
    full(3,2) = tensor_in(5)
    full(1,3) = tensor_in(6)  ! σzx
    full(3,1) = tensor_in(6)

    ! R * tensor * R^T
    rot_full = MATMUL(rotation_matrix, MATMUL(full, TRANSPOSE(rotation_matrix)))

    ! Full → Voigt
    tensor_out(1) = rot_full(1,1)
    tensor_out(2) = rot_full(2,2)
    tensor_out(3) = rot_full(3,3)
    tensor_out(4) = rot_full(1,2)
    tensor_out(5) = rot_full(2,3)
    tensor_out(6) = rot_full(1,3)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Out_TensorRotate

  !=============================================================================
  !> IP→Node extrapolation (field data at integration points to nodes)
  !=============================================================================
  SUBROUTINE PH_Out_IPtoNode_Extrapolate(ip_values, shape_func_at_nodes, &
      n_nodes, n_ip, n_comp, node_values, status)
    REAL(wp), INTENT(IN)  :: ip_values(:,:)         ! (n_comp, n_ip)
    REAL(wp), INTENT(IN)  :: shape_func_at_nodes(:,:) ! (n_ip, n_nodes)
    INTEGER(i4), INTENT(IN) :: n_nodes, n_ip, n_comp
    REAL(wp), INTENT(OUT) :: node_values(:,:)       ! (n_comp, n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: c

    CALL init_error_status(status)

    IF (n_ip < 1 .OR. n_nodes < 1 .OR. n_comp < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_Out_IPtoNode_Extrapolate: invalid dimensions'
      RETURN
    END IF

    DO c = 1, n_comp
      node_values(c, :) = MATMUL(ip_values(c, :), shape_func_at_nodes)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Out_IPtoNode_Extrapolate

  !=============================================================================
  !> Field variable interpolation (arbitrary location within element)
  !=============================================================================
  SUBROUTINE PH_Out_FieldInterpolate(node_values, shape_func, n_nodes, &
      n_comp, interp_values, status)
    REAL(wp), INTENT(IN)  :: node_values(:,:)   ! (n_comp, n_nodes)
    REAL(wp), INTENT(IN)  :: shape_func(:)       ! (n_nodes)
    INTEGER(i4), INTENT(IN) :: n_nodes, n_comp
    REAL(wp), INTENT(OUT) :: interp_values(:)   ! (n_comp)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: c

    CALL init_error_status(status)

    IF (n_nodes < 1 .OR. n_comp < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_Out_FieldInterpolate: invalid dimensions'
      RETURN
    END IF

    DO c = 1, n_comp
      interp_values(c) = DOT_PRODUCT(node_values(c, :), shape_func)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Out_FieldInterpolate

END MODULE PH_Out_Core
