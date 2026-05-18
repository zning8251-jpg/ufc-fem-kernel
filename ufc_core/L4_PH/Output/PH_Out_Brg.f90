!===============================================================================
! MODULE: PH_Out_Brg
! LAYER:  L4_PH
! DOMAIN: Output
! ROLE:   Brg — L4→L5 output bridge (thin wrapper over PH_Out_Core)
! BRIEF:  Unified public API for L5_RT to access output physics computation.
!         Routes calls from L5 (RT_Out_Mgr) to L4 physics engine (PH_Out_Core).
!
! DESIGN NOTE: This module is the canonical bridge location.
!   Old location: L4_PH/Bridge/Output/PH_Out_Brg.f90 (DEPRECATED — retained)
!===============================================================================
MODULE PH_Out_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Out_Core, ONLY: &
    PH_Out_CoordTransform, &
    PH_Out_TensorRotate, &
    PH_Out_IPtoNode_Extrapolate, &
    PH_Out_FieldInterpolate
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Output_TransformCoords
  PUBLIC :: PH_Output_TransformTensor
  PUBLIC :: PH_Output_InterpolateField
  PUBLIC :: PH_Output_GetScalar
  PUBLIC :: PH_Output_GetVector
  PUBLIC :: PH_Output_GetTensor

CONTAINS

  !===========================================================================
  !> @brief Public API: Coordinate transformation (global → local)
  !===========================================================================
  SUBROUTINE PH_Output_TransformCoords(coords_global, rotation_matrix, &
                                        coords_local, status)
    REAL(wp), INTENT(IN)  :: coords_global(:,:)
    REAL(wp), INTENT(IN)  :: rotation_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: coords_local(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL PH_Out_CoordTransform(coords_global, rotation_matrix, coords_local, status)
  END SUBROUTINE PH_Output_TransformCoords

  !===========================================================================
  !> @brief Public API: Tensor transformation (Voigt ↔ full)
  !===========================================================================
  SUBROUTINE PH_Output_TransformTensor(tensor_voigt, rotation_matrix, &
                                        tensor_out, status)
    REAL(wp), INTENT(IN)  :: tensor_voigt(6)
    REAL(wp), INTENT(IN)  :: rotation_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: tensor_out(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL PH_Out_TensorRotate(tensor_voigt, rotation_matrix, tensor_out, status)
  END SUBROUTINE PH_Output_TransformTensor

  !===========================================================================
  !> @brief Public API: Field variable interpolation
  !===========================================================================
  SUBROUTINE PH_Output_InterpolateField(node_values, shape_func, n_nodes, &
                                         n_comp, interp_values, status)
    REAL(wp), INTENT(IN)  :: node_values(:,:)
    REAL(wp), INTENT(IN)  :: shape_func(:)
    INTEGER(i4), INTENT(IN) :: n_nodes, n_comp
    REAL(wp), INTENT(OUT) :: interp_values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL PH_Out_FieldInterpolate(node_values, shape_func, n_nodes, &
                                  n_comp, interp_values, status)
  END SUBROUTINE PH_Output_InterpolateField

  !===========================================================================
  !> @brief Public API: Extract scalar component from stress/strain
  !===========================================================================
  SUBROUTINE PH_Output_GetScalar(tensor, component, value, status)
    REAL(wp), INTENT(IN)  :: tensor(6)
    INTEGER(i4), INTENT(IN) :: component  ! PH_VOIGT_XX etc.
    REAL(wp), INTENT(OUT) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (component < 1 .OR. component > 6) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_Output_GetScalar: invalid component'
      RETURN
    END IF
    value = tensor(component)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_GetScalar

  !===========================================================================
  !> @brief Public API: Extract vector components from tensor
  !===========================================================================
  SUBROUTINE PH_Output_GetVector(tensor, components, values, status)
    REAL(wp), INTENT(IN)  :: tensor(6)
    INTEGER(i4), INTENT(IN) :: components(:)  ! Array of PH_VOIGT_* indices
    REAL(wp), INTENT(OUT) :: values(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    CALL init_error_status(status)
    IF (SIZE(values) < SIZE(components)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_Output_GetVector: size mismatch'
      RETURN
    END IF
    DO i = 1, SIZE(components)
      values(i) = tensor(components(i))
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_GetVector

  !===========================================================================
  !> @brief Public API: Extract full tensor (6-component Voigt)
  !===========================================================================
  SUBROUTINE PH_Output_GetTensor(tensor, values, status)
    REAL(wp), INTENT(IN)  :: tensor(6)
    REAL(wp), INTENT(OUT) :: values(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    values(:) = tensor(:)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_GetTensor

END MODULE PH_Out_Brg
