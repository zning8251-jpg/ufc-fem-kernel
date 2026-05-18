!===============================================================================
! Module: PH_Out
! Layer:  L4_PH - Physics Layer
! Domain: Output - Core physics computation for output formatting
! Purpose:
!   Pure physics computation for output data transformation:
!     - Coordinate transformations (global �?local)
!     - Tensor transformations (stress/strain Voigt �?full)
!     - Field variable interpolation
!     - Component extraction (scalar/vector/tensor)
! Theory:  Continuum mechanics tensor transformations
! Status:  ACTIVE | AUTHORITY (L4 Output) | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output
!   L3: MD_Output_Def (AUTHORITY for output request schema)
!   L4: PH_Out (THIS MODULE — AUTHORITY for L4 physics transforms)
!   L5: RT_Out_Def (AUTHORITY for L5 runtime output types)
!
! Contents (A-Z):
!   Types:
!     - PH_Output_Params: Output parameters (Desc)
!     - PH_Output_State: Output state (State)
!   Subroutines:
!     - PH_Output_CoordTransform: Coordinate transformation
!     - PH_Output_TensorTransform: Tensor transformation (Voigt �?full)
!     - PH_Output_FieldInterpolate: Field variable interpolation
!     - PH_Output_ExtractScalar: Extract scalar component
!     - PH_Output_ExtractVector: Extract vector component
!     - PH_Output_ExtractTensor: Extract tensor component
!===============================================================================

MODULE PH_Out_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  
  IMPLICIT NONE
  PRIVATE
  
  !===========================================================================
  ! Public types �?output parameters and state
  !===========================================================================
  PUBLIC :: PH_Output_Params
  PUBLIC :: PH_Output_State
  
  !-- Output format type constants
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUTPUT_VTK   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUTPUT_HDF5  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUTPUT_ODB   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_OUTPUT_BINARY = 4_i4
  
  !-- Tensor component indices (Voigt notation)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_XX = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_YY = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_ZZ = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_XY = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_YZ = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_VOIGT_ZX = 6_i4
  
  !-- Output parameters (Desc �?read-only configuration)
  TYPE, PUBLIC :: PH_Output_Params
    INTEGER(i4) :: format_type = PH_OUTPUT_VTK
    INTEGER(i4) :: n_components = 3_i4        ! Number of field components
    INTEGER(i4) :: tensor_rank = 1_i4         ! 0=scalar, 1=vector, 2=tensor
    LOGICAL     :: write_binary = .FALSE.
    CHARACTER(LEN=256) :: field_name = ''
    CHARACTER(LEN=256) :: units = ''
  END TYPE PH_Output_Params
  
  !-- Output state (State �?dynamic, per write operation)
  TYPE, PUBLIC :: PH_Output_State
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    REAL(wp), ALLOCATABLE :: nodal_coords(:,:)    ! [3 × n_nodes]
    REAL(wp), ALLOCATABLE :: elem_connect(:,:)    ! [n_nodes_per_elem × n_elems]
    REAL(wp), ALLOCATABLE :: field_data(:,:)      ! [n_components × n_points]
    REAL(wp) :: time_value = 0.0_wp
    INTEGER(i4) :: step_number = 0_i4
  END TYPE PH_Output_State
  
  !===========================================================================
  ! Public API �?pure output computation
  !===========================================================================
  PUBLIC :: PH_Output_CoordTransform
  PUBLIC :: PH_Output_TensorTransform
  PUBLIC :: PH_Output_FieldInterpolate
  PUBLIC :: PH_Output_ExtractScalar
  PUBLIC :: PH_Output_ExtractVector
  PUBLIC :: PH_Output_ExtractTensor
  
CONTAINS

  !===========================================================================
  !> @brief Coordinate transformation: x_local = R * x_global
  !===========================================================================
  SUBROUTINE PH_Output_CoordTransform(coords_global, rotation_matrix, &
                                       coords_local, status)
    !! Transform coordinates from global to local coordinate system
    !! @param[in] coords_global Global coordinates [3 × n]
    !! @param[in] rotation_matrix Rotation matrix [3 × 3]
    !! @param[out] coords_local Local coordinates [3 × n]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: coords_global(:,:)
    REAL(wp), INTENT(IN)  :: rotation_matrix(3, 3)
    REAL(wp), INTENT(OUT) :: coords_local(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n
    REAL(wp) :: temp(3)
    
    CALL init_error_status(status)
    
    ! Validate dimensions
    IF (SIZE(coords_global, 1) /= 3) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_CoordTransform: coords_global must have 3 rows'
      RETURN
    END IF
    
    n = SIZE(coords_global, 2)
    IF (SIZE(coords_local, 1) /= 3 .OR. SIZE(coords_local, 2) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_CoordTransform: coords_local dimension mismatch'
      RETURN
    END IF
    
    ! Transform each node
    DO i = 1, n
      temp = MATMUL(rotation_matrix, coords_global(:, i))
      coords_local(:, i) = temp
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_CoordTransform

  !===========================================================================
  !> @brief Tensor transformation between Voigt and full tensor notation
  !===========================================================================
  SUBROUTINE PH_Output_TensorTransform(tensor_voigt, tensor_full, direction, status)
    !! Transform stress/strain between Voigt (6) and full tensor (3×3) notation
    !! @param[in] tensor_voigt Voigt notation [6] (xx, yy, zz, xy, yz, zx)
    !! @param[out] tensor_full Full tensor [3 × 3]
    !! @param[in] direction 'VOIGT_TO_FULL' or 'FULL_TO_VOIGT'
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: tensor_voigt(6)
    REAL(wp), INTENT(OUT) :: tensor_full(3, 3)
    CHARACTER(LEN=*), INTENT(IN) :: direction
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    SELECT CASE (TRIM(direction))
    CASE ('VOIGT_TO_FULL', 'voigt_to_full')
      ! Symmetric tensor: σ_ij = σ_ji
      tensor_full = RESHAPE([ &
        tensor_voigt(PH_VOIGT_XX), tensor_voigt(PH_VOIGT_XY), tensor_voigt(PH_VOIGT_ZX), &
        tensor_voigt(PH_VOIGT_XY), tensor_voigt(PH_VOIGT_YY), tensor_voigt(PH_VOIGT_YZ), &
        tensor_voigt(PH_VOIGT_ZX), tensor_voigt(PH_VOIGT_YZ), tensor_voigt(PH_VOIGT_ZZ) &
      ], [3, 3])
      
    CASE ('FULL_TO_VOIGT', 'full_to_voigt')
      tensor_voigt = [ &
        tensor_full(1, 1), tensor_full(2, 2), tensor_full(3, 3), &
        tensor_full(1, 2), tensor_full(2, 3), tensor_full(3, 1) &
      ]
      
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_TensorTransform: Invalid direction'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_TensorTransform

  !===========================================================================
  !> @brief Field variable interpolation using shape functions
  !===========================================================================
  SUBROUTINE PH_Output_FieldInterpolate(nodal_values, shape_funcs, &
                                         interpolated_value, status)
    !! Interpolate field variable at integration point using shape functions
    !! @param[in] nodal_values Nodal values [n_nodes × n_components]
    !! @param[in] shape_funcs Shape functions [n_nodes]
    !! @param[out] interpolated_value Interpolated value [n_components]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: nodal_values(:,:)
    REAL(wp), INTENT(IN)  :: shape_funcs(:)
    REAL(wp), INTENT(OUT) :: interpolated_value(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, n_comp, n_nodes
    REAL(wp) :: sum_val
    
    CALL init_error_status(status)
    
    n_nodes = SIZE(shape_funcs)
    IF (SIZE(nodal_values, 1) /= n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_FieldInterpolate: nodal_values dimension mismatch'
      RETURN
    END IF
    
    n_comp = SIZE(nodal_values, 2)
    IF (SIZE(interpolated_value) /= n_comp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_FieldInterpolate: interpolated_value dimension mismatch'
      RETURN
    END IF
    
    ! Interpolate each component
    DO i = 1, n_comp
      sum_val = 0.0_wp
      DO j = 1, n_nodes
        sum_val = sum_val + shape_funcs(j) * nodal_values(j, i)
      END DO
      interpolated_value(i) = sum_val
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_FieldInterpolate

  !===========================================================================
  !> @brief Extract scalar component from field data
  !===========================================================================
  SUBROUTINE PH_Output_ExtractScalar(field_data, component_idx, scalar_value, status)
    !! Extract scalar component from multi-component field
    !! @param[in] field_data Field data [n_points × n_components]
    !! @param[in] component_idx Component index to extract (1-based)
    !! @param[out] scalar_value Scalar values [n_points]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: field_data(:,:)
    INTEGER(i4), INTENT(IN) :: component_idx
    REAL(wp), INTENT(OUT) :: scalar_value(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_points, n_comp
    
    CALL init_error_status(status)
    
    n_points = SIZE(field_data, 1)
    n_comp = SIZE(field_data, 2)
    
    IF (component_idx < 1 .OR. component_idx > n_comp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractScalar: component_idx out of range'
      RETURN
    END IF
    
    IF (SIZE(scalar_value) /= n_points) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractScalar: scalar_value dimension mismatch'
      RETURN
    END IF
    
    DO i = 1, n_points
      scalar_value(i) = field_data(i, component_idx)
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_ExtractScalar

  !===========================================================================
  !> @brief Extract vector components from field data
  !===========================================================================
  SUBROUTINE PH_Output_ExtractVector(field_data, vector_values, status)
    !! Extract vector components (3 components) from field data
    !! @param[in] field_data Field data [n_points × 3]
    !! @param[out] vector_values Vector values [3 × n_points]
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: field_data(:,:)
    REAL(wp), INTENT(OUT) :: vector_values(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_points
    
    CALL init_error_status(status)
    
    n_points = SIZE(field_data, 1)
    
    IF (SIZE(field_data, 2) /= 3) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractVector: field_data must have 3 components'
      RETURN
    END IF
    
    IF (SIZE(vector_values, 1) /= 3 .OR. SIZE(vector_values, 2) /= n_points) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractVector: vector_values dimension mismatch'
      RETURN
    END IF
    
    ! Transpose: [n_points × 3] �?[3 × n_points]
    DO i = 1, 3
      vector_values(i, :) = field_data(:, i)
    END DO
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_ExtractVector

  !===========================================================================
  !> @brief Extract tensor components from field data
  !===========================================================================
  SUBROUTINE PH_Output_ExtractTensor(field_data, tensor_values, notation, status)
    !! Extract tensor components (6 Voigt components) from field data
    !! @param[in] field_data Field data [n_points × 6]
    !! @param[out] tensor_values Tensor values [3 × 3 × n_points]
    !! @param[in] notation 'VOIGT' or 'FULL'
    !! @param[out] status Error status
    REAL(wp), INTENT(IN)  :: field_data(:,:)
    REAL(wp), INTENT(OUT) :: tensor_values(:,:,:)
    CHARACTER(LEN=*), INTENT(IN) :: notation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_points
    REAL(wp) :: tensor_voigt(6), tensor_full(3, 3)
    TYPE(ErrorStatusType) :: local_status
    
    CALL init_error_status(status)
    
    n_points = SIZE(field_data, 1)
    
    IF (SIZE(field_data, 2) /= 6) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractTensor: field_data must have 6 Voigt components'
      RETURN
    END IF
    
    IF (SIZE(tensor_values, 1) /= 3 .OR. SIZE(tensor_values, 2) /= 3 .OR. &
        SIZE(tensor_values, 3) /= n_points) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractTensor: tensor_values dimension mismatch'
      RETURN
    END IF
    
    SELECT CASE (TRIM(notation))
    CASE ('VOIGT', 'voigt')
      ! Convert each point's Voigt notation to full tensor
      DO i = 1, n_points
        tensor_voigt = field_data(i, :)
        CALL PH_Output_TensorTransform(tensor_voigt, tensor_full, 'VOIGT_TO_FULL', local_status)
        tensor_values(:, :, i) = tensor_full
      END DO
      
    CASE ('FULL', 'full')
      ! Input is already full tensor format [n_points × 9]
      ! Reshape to [3 × 3 × n_points]
      DO i = 1, n_points
        tensor_values(:, :, i) = RESHAPE(field_data(i, :), [3, 3])
      END DO
      
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Output_ExtractTensor: Invalid notation'
      RETURN
    END SELECT
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Output_ExtractTensor

END MODULE PH_Out_Mgr