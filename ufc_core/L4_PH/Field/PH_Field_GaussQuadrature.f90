!===============================================================================
! MODULE: PH_Field_GaussQuadrature
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — unified Gaussian quadrature adapter for field domain
! BRIEF:  Volume/surface/edge Gauss-point generation; delegates rule
!         generation to element integration-point utilities.
! PILOT:  Single entry `PH_Field_GetGaussPoints(rule_type, order, out)`;
!         use `PH_FIELD_GAUSS_RULE_*` — removed thin Volume/Surface/Edge wrappers.
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Quadrature | FuncSet:Gauss
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_GaussQuadrature
  USE IF_Base_Def, ONLY: ZERO, ONE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  
  ! Element domain quadrature interfaces
  USE PH_Elem_IntegPts, ONLY: ET_IP_Gauss1D, &
                               ET_IP_Gauss2D_Quad, &
                               ET_IP_Gauss2D_Tri, &
                               ET_IP_Gauss3D_Hex, &
                               ET_IP_Gauss3D_Tet, &
                               PH_Elem_IP_GetNumPoints

  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC API - Quadrature adapter
  ! ==========================================================================
  PUBLIC :: PH_Field_GetGaussPoints

  ! Rule codes for `PH_Field_GetGaussPoints` (must match SELECT CASE below)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_GAUSS_RULE_1D = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_GAUSS_RULE_2D_QUAD = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_GAUSS_RULE_2D_TRI = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_GAUSS_RULE_3D_HEX = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_GAUSS_RULE_3D_TET = 5_i4

  ! ==========================================================================
  ! PUBLIC TYPES - Quadrature structures
  ! ==========================================================================
  PUBLIC :: PH_Field_GaussPt_Arg

  !> @brief Unified Gauss-point request / result bundle
  TYPE, PUBLIC :: PH_Field_GaussPt_Arg
    INTEGER(i4) :: rule_type = 0_i4                 ! [IN] 1=1D, 2=2D_Quad, 3=2D_Tri, 4=3D_Hex, 5=3D_Tet
    INTEGER(i4) :: order = 2_i4                     ! [IN]
    INTEGER(i4) :: n_ip = 0_i4                      ! [OUT]
    REAL(wp), ALLOCATABLE :: xi(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: eta(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: zeta(:)                  ! [OUT]
    REAL(wp), ALLOCATABLE :: weights(:)              ! [OUT]
    TYPE(ErrorStatusType) :: status                 ! [OUT]
  END TYPE PH_Field_GaussPt_Arg


CONTAINS

  ! ==========================================================================
  ! UNIFIED GAUSS POINT QUADRATURE
  ! ==========================================================================
  !> @brief Get Gauss points for integration rules used by Field kernels.
  !! @param[in] rule_type Use `PH_FIELD_GAUSS_RULE_*` (1D … 3D Tet)
  !! @param[in] order Integration order
  !! @param[out] out Gauss points and weights
  SUBROUTINE PH_Field_GetGaussPoints(rule_type, order, out)
    INTEGER(i4), INTENT(IN) :: rule_type
    INTEGER(i4), INTENT(IN) :: order
    TYPE(PH_Field_GaussPt_Arg), INTENT(OUT) :: out

    INTEGER(i4) :: n_ip
    TYPE(ErrorStatusType) :: status

    CALL init_error_status(out%status)

    SELECT CASE (rule_type)
    CASE (PH_FIELD_GAUSS_RULE_1D)  ! 1D
      n_ip = order
      CALL PH_Field_EnsureGaussAlloc(out, n_ip)
      CALL ET_IP_Gauss1D(order, out%xi, out%weights, status)
      out%eta = ZERO
      out%zeta = ZERO

    CASE (PH_FIELD_GAUSS_RULE_2D_QUAD)  ! 2D Quadrilateral
      n_ip = order * order
      CALL PH_Field_EnsureGaussAlloc(out, n_ip)
      CALL ET_IP_Gauss2D_Quad(order, out%xi, out%eta, out%weights, status)
      out%zeta = ZERO

    CASE (PH_FIELD_GAUSS_RULE_2D_TRI)  ! 2D Triangle
      n_ip = PH_Elem_IP_GetNumPoints(order)
      CALL PH_Field_EnsureGaussAlloc(out, n_ip)
      CALL ET_IP_Gauss2D_Tri(order, out%xi, out%eta, out%weights, status)
      out%zeta = ZERO

    CASE (PH_FIELD_GAUSS_RULE_3D_HEX)  ! 3D Hexahedron
      n_ip = order * order * order
      CALL PH_Field_EnsureGaussAlloc(out, n_ip)
      CALL ET_IP_Gauss3D_Hex(order, out%xi, out%eta, out%zeta, out%weights, status)

    CASE (PH_FIELD_GAUSS_RULE_3D_TET)  ! 3D Tetrahedron
      n_ip = PH_Elem_IP_GetNumPoints(order)
      CALL PH_Field_EnsureGaussAlloc(out, n_ip)
      CALL ET_IP_Gauss3D_Tet(order, out%xi, out%eta, out%zeta, out%weights, status)

    CASE DEFAULT
      out%status%status_code = IF_STATUS_INVALID
      out%status%error_message = 'PH_Field_GetGaussPoints: Unknown rule_type'
      RETURN
    END SELECT

    IF (status%status_code /= IF_STATUS_OK) THEN
      out%status = status
      RETURN
    END IF

    out%n_ip = n_ip
    out%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_GetGaussPoints

  ! ==========================================================================
  ! INTERNAL: Ensure allocation
  ! ==========================================================================
  SUBROUTINE PH_Field_EnsureGaussAlloc(out, n_ip)
    TYPE(PH_Field_GaussPt_Arg), INTENT(INOUT) :: out
    INTEGER(i4), INTENT(IN) :: n_ip

    IF (ALLOCATED(out%xi)) DEALLOCATE(out%xi)
    IF (ALLOCATED(out%eta)) DEALLOCATE(out%eta)
    IF (ALLOCATED(out%zeta)) DEALLOCATE(out%zeta)
    IF (ALLOCATED(out%weights)) DEALLOCATE(out%weights)

    ALLOCATE(out%xi(n_ip))
    ALLOCATE(out%eta(n_ip))
    ALLOCATE(out%zeta(n_ip))
    ALLOCATE(out%weights(n_ip))

    out%xi = ZERO
    out%eta = ZERO
    out%zeta = ZERO
    out%weights = ZERO
  END SUBROUTINE PH_Field_EnsureGaussAlloc

END MODULE PH_Field_GaussQuadrature