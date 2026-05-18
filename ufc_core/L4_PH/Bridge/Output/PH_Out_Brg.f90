!===============================================================================
! Module: PH_Out_Brg
! Layer:  L4_PH - Physics Layer
! Domain: Output - Public API for output physics computation
! Purpose:
!   Unified public API for L5_RT to access Output physical computation
! Theory:  Thin wrapper around PH_Out, providing simplified interface
!          for runtime layer. No scheduling logic, pure physics routing.
! Status:  ACTIVE | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output (L4 AUTHORITY: PH_Out.f90)
!
! Contents (A-Z):
!   Subroutines:
!     - PH_Output_TransformCoords: Coordinate transformation API
!     - PH_Output_TransformTensor: Tensor transformation API
!     - PH_Output_InterpolateField: Field interpolation API
!     - PH_Output_GetScalar: Extract scalar component API
!     - PH_Output_GetVector: Extract vector component API
!     - PH_Output_GetTensor: Extract tensor component API
!===============================================================================

MODULE PH_Out_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE PH_Out_Mgr, ONLY: PH_Output_Params, PH_Output_State, &
                            PH_Output_CoordTransform, PH_Output_TensorTransform, &
                            PH_Output_FieldInterpolate, PH_Output_ExtractScalar, &
                            PH_Output_ExtractVector, PH_Output_ExtractTensor, &
                            PH_OUTPUT_VTK, PH_OUTPUT_HDF5, PH_OUTPUT_ODB, &
                            PH_VOIGT_XX, PH_VOIGT_YY, PH_VOIGT_ZZ, &
                            PH_VOIGT_XY, PH_VOIGT_YZ, PH_VOIGT_ZX
  
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
  !> @brief Public API: Coordinate transformation
  !===========================================================================
  SUBROUTINE PH_Output_TransformCoords(coords_global, rotation_matrix, &
                                        coords_local, status)
    !! Transform coordinates from global to local system
    !! @param[in] coords_global Global coordinates [3 × n]
    !! @param[in] rotation_matrix Rotation matrix [3 × 3]
    !! @param[out] coords_local Local coordinates [3 × n]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: coords_global(:,:)
    REAL(wp), INTENT(IN)  :: rotation_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: coords_local(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Output_CoordTransform(coords_global, rotation_matrix, &
                                  coords_local, status)
  END SUBROUTINE PH_Output_TransformCoords

  !===========================================================================
  !> @brief Public API: Tensor transformation (Voigt �?full)
  !===========================================================================
  SUBROUTINE PH_Output_TransformTensor(tensor_voigt, tensor_full, direction, status)
    !! Transform stress/strain between Voigt and full tensor notation
    !! @param[in] tensor_voigt Voigt notation [6]
    !! @param[out] tensor_full Full tensor [3 × 3]
    !! @param[in] direction 'VOIGT_TO_FULL' or 'FULL_TO_VOIGT'
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: tensor_voigt(6)
    REAL(wp), INTENT(OUT) :: tensor_full(3, 3)
    CHARACTER(LEN=*), INTENT(IN) :: direction
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Output_TensorTransform(tensor_voigt, tensor_full, direction, status)
  END SUBROUTINE PH_Output_TransformTensor

  !===========================================================================
  !> @brief Public API: Field variable interpolation
  !===========================================================================
  SUBROUTINE PH_Output_InterpolateField(nodal_values, shape_funcs, &
                                         interpolated_value, status)
    !! Interpolate field variable at integration point
    !! @param[in] nodal_values Nodal values [n_nodes × n_components]
    !! @param[in] shape_funcs Shape functions [n_nodes]
    !! @param[out] interpolated_value Interpolated value [n_components]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: nodal_values(:,:)
    REAL(wp), INTENT(IN)  :: shape_funcs(:)
    REAL(wp), INTENT(OUT) :: interpolated_value(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Output_FieldInterpolate(nodal_values, shape_funcs, &
                                    interpolated_value, status)
  END SUBROUTINE PH_Output_InterpolateField

  !===========================================================================
  !> @brief Public API: Extract scalar component
  !===========================================================================
  SUBROUTINE PH_Output_GetScalar(field_data, component_idx, scalar_value, status)
    !! Extract scalar component from multi-component field
    !! @param[in] field_data Field data [n_points × n_components]
    !! @param[in] component_idx Component index (1-based)
    !! @param[out] scalar_value Scalar values [n_points]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: field_data(:,:)
    INTEGER(i4), INTENT(IN) :: component_idx
    REAL(wp), INTENT(OUT) :: scalar_value(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Output_ExtractScalar(field_data, component_idx, scalar_value, status)
  END SUBROUTINE PH_Output_GetScalar

  !===========================================================================
  !> @brief Public API: Extract vector components
  !===========================================================================
  SUBROUTINE PH_Output_GetVector(field_data, vector_values, status)
    !! Extract vector components (3 components) from field data
    !! @param[in] field_data Field data [n_points × 3]
    !! @param[out] vector_values Vector values [3 × n_points]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: field_data(:,:)
    REAL(wp), INTENT(OUT) :: vector_values(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Output_ExtractVector(field_data, vector_values, status)
  END SUBROUTINE PH_Output_GetVector

  !===========================================================================
  !> @brief Public API: Extract tensor components
  !===========================================================================
  SUBROUTINE PH_Output_GetTensor(field_data, tensor_values, notation, status)
    !! Extract tensor components from field data
    !! @param[in] field_data Field data [n_points × 6] (Voigt notation)
    !! @param[out] tensor_values Tensor values [3 × 3 × n_points]
    !! @param[in] notation 'VOIGT' or 'FULL'
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: field_data(:,:)
    REAL(wp), INTENT(OUT) :: tensor_values(:,:,:)
    CHARACTER(LEN=*), INTENT(IN) :: notation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_Output_ExtractTensor(field_data, tensor_values, notation, status)
  END SUBROUTINE PH_Output_GetTensor

END MODULE PH_Out_Brg
