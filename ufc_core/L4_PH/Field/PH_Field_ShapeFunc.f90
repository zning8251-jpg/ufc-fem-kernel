!===============================================================================
! MODULE: PH_Field_ShapeFunc
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — unified shape function adapter for field computations
! BRIEF:  GetShapeFunctions, GetShapeFunctionGradient, ComputeJacobian;
!         PH_Field_ShapeFunc_Arg and PH_Field_Gradient_Arg bundles.
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Support | FuncSet:ShapeFunc
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_ShapeFunc
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  
  ! Element domain interfaces
  USE PH_Elem_C3D8, ONLY: PH_Elem_C3D8_ShapeFunc, &
                               PH_Elem_C3D8_ShapeFunc_Arg, &
                               PH_Elem_C3D8_Jac, &
                               PH_Elem_C3D8_Jac_Arg

  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC API - Shape function adapter
  ! ==========================================================================
  PUBLIC :: PH_Field_GetShapeFunctions
  PUBLIC :: PH_Field_GetShapeFunctionGradient
  PUBLIC :: PH_Field_ComputeJacobian

  ! ==========================================================================
  ! PUBLIC TYPES - Field-local support structures
  ! ==========================================================================
  PUBLIC :: PH_Field_ShapeFunc_Arg
  PUBLIC :: PH_Field_Gradient_Arg

  !> @brief Shape function values and parent-domain derivatives at one point
  TYPE, PUBLIC :: PH_Field_ShapeFunc_Arg
    REAL(wp), ALLOCATABLE :: N(:)        ! [OUT] Shape functions [npe]
    REAL(wp), ALLOCATABLE :: dN_dxi(:,:) ! [OUT] dN/dxi [3, npe]
    TYPE(ErrorStatusType) :: status     ! [OUT]
  END TYPE PH_Field_ShapeFunc_Arg

  !> @brief Physical gradients dN/dx and Jacobian data at one point
  TYPE, PUBLIC :: PH_Field_Gradient_Arg
    REAL(wp), ALLOCATABLE :: dN_dx(:,:) ! [OUT] dN/dx [3, npe]
    REAL(wp) :: detJ = 0.0_wp           ! [OUT] Jacobian determinant
    TYPE(ErrorStatusType) :: status     ! [OUT]
  END TYPE PH_Field_Gradient_Arg

  TYPE(PH_Field_ShapeFunc_Arg), SAVE :: PH_Field_ShapeFunc_Work

CONTAINS

  ! ==========================================================================
  ! SHAPE FUNCTIONS - Unified interface
  ! ==========================================================================
  !> @brief Get shape functions N(ξ,η,ζ) for given element type
  !! @param[in] elem_type Element type (e.g., 'C3D8')
  !! @param[in] xi Natural coordinate ξ
  !! @param[in] eta Natural coordinate η
  !! @param[in] zeta Natural coordinate ζ
  !! @param[in] npe Number of nodes per element
  !! @param[out] out Shape functions and derivatives
  SUBROUTINE PH_Field_GetShapeFunctions(elem_type, xi, eta, zeta, npe, arg)
    CHARACTER(LEN=*), INTENT(IN) :: elem_type
    REAL(wp), INTENT(IN) :: xi, eta, zeta
    INTEGER(i4), INTENT(IN) :: npe
    TYPE(PH_Field_ShapeFunc_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)

    IF (ALLOCATED(arg%N)) DEALLOCATE(arg%N)
    IF (ALLOCATED(arg%dN_dxi)) DEALLOCATE(arg%dN_dxi)
    ALLOCATE(arg%N(npe))
    ALLOCATE(arg%dN_dxi(3, npe))

    SELECT CASE (TRIM(elem_type))
    CASE ('C3D8', 'c3d8')
      CALL PH_Field_ShapeFunc_C3D8(xi, eta, zeta, arg%N, arg%dN_dxi, arg%status)

    CASE DEFAULT
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%error_message = 'PH_Field_GetShapeFunctions: Unsupported element type ' // TRIM(elem_type)
      RETURN
    END SELECT

    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_GetShapeFunctions

  ! ==========================================================================
  ! SHAPE FUNCTION GRADIENT - dN/dx via Jacobian
  ! ==========================================================================
  !> @brief Compute shape function gradients dN/dx in physical coordinates
  !! @param[in] coords Node coordinates [3, npe]
  !! @param[in] xi Natural coordinate ξ
  !! @param[in] eta Natural coordinate η
  !! @param[in] zeta Natural coordinate ζ
  !! @param[in] npe Number of nodes per element
  !! @param[out] out Gradients dN/dx and Jacobian determinant
  SUBROUTINE PH_Field_GetShapeFunctionGradient(coords, xi, eta, zeta, npe, arg)
    REAL(wp), INTENT(IN) :: coords(:,:)   ! [3, npe]
    REAL(wp), INTENT(IN) :: xi, eta, zeta
    INTEGER(i4), INTENT(IN) :: npe
    TYPE(PH_Field_Gradient_Arg), INTENT(INOUT) :: arg

    REAL(wp), ALLOCATABLE :: dN_dxi(:,:)
    REAL(wp) :: J(3,3), J_inv(3,3)
    REAL(wp) :: detJ
    INTEGER(i4) :: i, dim
    TYPE(ErrorStatusType) :: jac_status

    CALL init_error_status(arg%status)

    IF (SIZE(coords, 1) < 3 .OR. SIZE(coords, 2) < npe) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%error_message = 'PH_Field_GetShapeFunctionGradient: Invalid coords dimensions'
      RETURN
    END IF

    IF (ALLOCATED(arg%dN_dx)) DEALLOCATE(arg%dN_dx)
    ALLOCATE(arg%dN_dx(3, npe))

    CALL PH_Field_GetShapeFunctions('C3D8', xi, eta, zeta, npe, PH_Field_ShapeFunc_Work)
    dN_dxi = PH_Field_ShapeFunc_Work%dN_dxi
    IF (ALLOCATED(PH_Field_ShapeFunc_Work%N)) DEALLOCATE(PH_Field_ShapeFunc_Work%N)
    IF (ALLOCATED(PH_Field_ShapeFunc_Work%dN_dxi)) DEALLOCATE(PH_Field_ShapeFunc_Work%dN_dxi)

    CALL PH_Field_ComputeJacobian(coords, dN_dxi, npe, J, detJ, jac_status)
    IF (jac_status%status_code /= IF_STATUS_OK) THEN
      arg%status = jac_status
      RETURN
    END IF

    IF (ABS(detJ) < 1.0e-12_wp) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%error_message = 'PH_Field_GetShapeFunctionGradient: Singular Jacobian'
      RETURN
    END IF

    arg%detJ = detJ

    CALL PH_Field_InverseJacobian3D(J, detJ, J_inv, jac_status)
    IF (jac_status%status_code /= IF_STATUS_OK) THEN
      arg%status = jac_status
      RETURN
    END IF

    dim = 3
    DO i = 1, npe
      arg%dN_dx(1, i) = J_inv(1,1)*dN_dxi(1,i) + J_inv(1,2)*dN_dxi(2,i) + J_inv(1,3)*dN_dxi(3,i)
      arg%dN_dx(2, i) = J_inv(2,1)*dN_dxi(1,i) + J_inv(2,2)*dN_dxi(2,i) + J_inv(2,3)*dN_dxi(3,i)
      arg%dN_dx(3, i) = J_inv(3,1)*dN_dxi(1,i) + J_inv(3,2)*dN_dxi(2,i) + J_inv(3,3)*dN_dxi(3,i)
    END DO

    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_GetShapeFunctionGradient

  ! ==========================================================================
  ! JACOBIAN COMPUTATION
  ! ==========================================================================
  !> @brief Compute Jacobian matrix J = dx/dξ
  !! @param[in] coords Node coordinates [3, npe]
  !! @param[in] dN_dxi Shape function derivatives [3, npe]
  !! @param[in] npe Number of nodes per element
  !! @param[out] J Jacobian matrix [3, 3]
  !! @param[out] detJ Determinant of Jacobian
  !! @param[out] status Error status
  SUBROUTINE PH_Field_ComputeJacobian(coords, dN_dxi, npe, J, detJ, status)
    REAL(wp), INTENT(IN) :: coords(:,:)    ! [3, npe]
    REAL(wp), INTENT(IN) :: dN_dxi(:,:)    ! [3, npe]
    INTEGER(i4), INTENT(IN) :: npe
    REAL(wp), INTENT(OUT) :: J(3,3)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Validate input
    IF (SIZE(coords, 1) < 3 .OR. SIZE(coords, 2) < npe) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_ComputeJacobian: Invalid coords dimensions'
      RETURN
    END IF

    IF (SIZE(dN_dxi, 1) < 3 .OR. SIZE(dN_dxi, 2) < npe) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_ComputeJacobian: Invalid dN_dxi dimensions'
      RETURN
    END IF

    ! J = Σ (dN_i/dξ_j · x_i)
    J = ZERO
    DO i = 1, npe
      J(1, 1) = J(1, 1) + dN_dxi(1, i) * coords(1, i)  ! dx/dξ
      J(1, 2) = J(1, 2) + dN_dxi(1, i) * coords(2, i)  ! dy/dξ
      J(1, 3) = J(1, 3) + dN_dxi(1, i) * coords(3, i)  ! dz/dξ
      J(2, 1) = J(2, 1) + dN_dxi(2, i) * coords(1, i)  ! dx/dη
      J(2, 2) = J(2, 2) + dN_dxi(2, i) * coords(2, i)  ! dy/dη
      J(2, 3) = J(2, 3) + dN_dxi(2, i) * coords(3, i)  ! dz/dη
      J(3, 1) = J(3, 1) + dN_dxi(3, i) * coords(1, i)  ! dx/dζ
      J(3, 2) = J(3, 2) + dN_dxi(3, i) * coords(2, i)  ! dy/dζ
      J(3, 3) = J(3, 3) + dN_dxi(3, i) * coords(3, i)  ! dz/dζ
    END DO

    ! Determinant
    detJ = J(1,1)*(J(2,2)*J(3,3) - J(2,3)*J(3,2)) &
         - J(1,2)*(J(2,1)*J(3,3) - J(2,3)*J(3,1)) &
         + J(1,3)*(J(2,1)*J(3,2) - J(2,2)*J(3,1))

    IF (ABS(detJ) < 1.0e-15_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_ComputeJacobian: Singular Jacobian (detJ ≈ 0)'
      RETURN
    END IF

    ! Check for negative Jacobian (inverted element)
    IF (detJ < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_ComputeJacobian: Negative Jacobian (inverted element)'
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_ComputeJacobian

  ! ==========================================================================
  ! C3D8 SHAPE FUNCTIONS - Internal implementation
  ! ==========================================================================
  !> @brief C3D8 shape functions: N_i = (1/8)(1+ξ_i·ξ)(1+η_i·η)(1+ζ_i·ζ)
  SUBROUTINE PH_Field_ShapeFunc_C3D8(xi, eta, zeta, N, dN_dxi, status)
    REAL(wp), INTENT(IN) :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(8), dN_dxi(3, 8)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: xi_p(8), eta_p(8), zeta_p(8)
    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Node natural coordinates (ABAQUS hex8 order)
    xi_p(1:8)   = [-ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE]
    eta_p(1:8)  = [-ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE]
    zeta_p(1:8) = [-ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE]

    DO i = 1, 8
      N(i) = 0.125_wp * (ONE + xi_p(i)*xi) * (ONE + eta_p(i)*eta) * (ONE + zeta_p(i)*zeta)
      dN_dxi(1, i) = 0.125_wp * xi_p(i)   * (ONE + eta_p(i)*eta) * (ONE + zeta_p(i)*zeta)
      dN_dxi(2, i) = 0.125_wp * (ONE + xi_p(i)*xi) * eta_p(i)    * (ONE + zeta_p(i)*zeta)
      dN_dxi(3, i) = 0.125_wp * (ONE + xi_p(i)*xi) * (ONE + eta_p(i)*eta) * zeta_p(i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_ShapeFunc_C3D8

  ! ==========================================================================
  ! JACOBIAN INVERSE - 3D
  ! ==========================================================================
  !> @brief Compute inverse of 3x3 Jacobian matrix
  SUBROUTINE PH_Field_InverseJacobian3D(J, detJ, J_inv, status)
    REAL(wp), INTENT(IN) :: J(3,3)
    REAL(wp), INTENT(IN) :: detJ
    REAL(wp), INTENT(OUT) :: J_inv(3,3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (ABS(detJ) < 1.0e-15_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_InverseJacobian3D: Singular matrix'
      RETURN
    END IF

    ! Adjugate matrix / det(J)
    J_inv(1, 1) = (J(2,2)*J(3,3) - J(2,3)*J(3,2)) / detJ
    J_inv(1, 2) = -(J(1,2)*J(3,3) - J(1,3)*J(3,2)) / detJ
    J_inv(1, 3) = (J(1,2)*J(2,3) - J(1,3)*J(2,2)) / detJ

    J_inv(2, 1) = -(J(2,1)*J(3,3) - J(2,3)*J(3,1)) / detJ
    J_inv(2, 2) = (J(1,1)*J(3,3) - J(1,3)*J(3,1)) / detJ
    J_inv(2, 3) = -(J(1,1)*J(2,3) - J(1,3)*J(2,1)) / detJ

    J_inv(3, 1) = (J(2,1)*J(3,2) - J(2,2)*J(3,1)) / detJ
    J_inv(3, 2) = -(J(1,1)*J(3,2) - J(1,2)*J(3,1)) / detJ
    J_inv(3, 3) = (J(1,1)*J(2,2) - J(1,2)*J(2,1)) / detJ

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_InverseJacobian3D

END MODULE PH_Field_ShapeFunc
