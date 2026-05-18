!===============================================================================
! MODULE: PH_Elem_MatIntegration
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Unified material constitutive integration for element kernels
!===============================================================================
MODULE PH_Elem_MatIntegration
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE PH_Elem_Def, ONLY: PH_Elem_Desc, PH_Elem_State, &
                           PH_Elem_Algo, PH_Elem_Ctx

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! TYPE: PH_Mat_Integration_Args
  ! Material integration arguments at Gauss point level
  !============================================================================
  TYPE, PUBLIC :: PH_Mat_Integration_Args
    !-- Input: strain measures
    REAL(wp), ALLOCATABLE :: strain(:)        ! Strain increment [n_strain]
    REAL(wp), ALLOCATABLE :: dtime            ! Time increment
    
    !-- Input: material parameters (from L3_MD via L4_PH)
    REAL(wp), ALLOCATABLE :: props(:)         ! Material properties
    INTEGER(i4), ALLOCATABLE :: nprops        ! Number of props
    
    !-- Input/Output: state variables
    REAL(wp), ALLOCATABLE :: statev_in(:)     ! State vars at start of incr
    REAL(wp), ALLOCATABLE :: statev_out(:)    ! State vars at end of incr
    INTEGER(i4), ALLOCATABLE :: nstatev       ! Number of state vars
    
    !-- Output: stress and tangent
    REAL(wp), ALLOCATABLE :: stress(:)        ! Updated stress [n_strain]
    REAL(wp), ALLOCATABLE :: ddsdde(:,:)      ! Material tangent [n_strain, n_strain]
    
    !-- Output: energy and diagnostics
    REAL(wp) :: sse = 0.0_wp                  ! Strain energy density
    REAL(wp) :: spd = 0.0_wp                  ! Plastic dissipation
    REAL(wp) :: rpl = 0.0_wp                  ! Creep energy
    
    !-- Metadata
    INTEGER(i4) :: ndim = 3                   ! Spatial dimension
    INTEGER(i4) :: nstrain = 6                ! Strain components (6 for 3D)
    LOGICAL :: is_linear = .FALSE.            ! Linear material flag
    LOGICAL :: is_valid = .FALSE.             ! Validation flag
    
  END TYPE PH_Mat_Integration_Args

  !============================================================================
  ! Public interfaces
  !============================================================================
  PUBLIC :: PH_Update_Stress_Tangent
  PUBLIC :: PH_Compute_Strain_Energy
  PUBLIC :: PH_Init_Material_State

CONTAINS

  !============================================================================
  ! Subroutine: PH_Update_Stress_Tangent
  ! Purpose: Update stress and compute tangent stiffness
  !          Generic interface for all material models
  !============================================================================
  SUBROUTINE PH_Update_Stress_Tangent(args, status)
    TYPE(PH_Mat_Integration_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    ! Placeholder: This would call the actual material model
    ! For now, implement linear elastic as default
    
    IF (args%is_linear) THEN
      CALL PH_Linear_Elastic_Update(args, status)
    ELSE
      ! TODO: Call nonlinear material model from PH_MatConstitutive_Core
      CALL init_error_status(status, STATUS_ERR, "Nonlinear mat not implemented")
      RETURN
    END IF

    IF (status%status_code /= IF_STATUS_OK) THEN
      RETURN
    END IF

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Update_Stress_Tangent

  !============================================================================
  ! Subroutine: PH_Compute_Strain_Energy
  ! Purpose: Compute strain energy density and dissipation
  !============================================================================
  SUBROUTINE PH_Compute_Strain_Energy(args, status)
    TYPE(PH_Mat_Integration_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (.NOT. args%is_valid) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid args")
      RETURN
    END IF

    ! SSE = 0.5 * strain : stress (elastic)
    args%sse = 0.0_wp
    DO i = 1, args%nstrain
      args%sse = args%sse + 0.5_wp * args%strain(i) * args%stress(i)
    END DO

    ! Add plastic dissipation if applicable
    args%spd = args%spd + args%rpl

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Compute_Strain_Energy

  !============================================================================
  ! Subroutine: PH_Init_Material_State
  ! Purpose: Initialize material state variables
  !============================================================================
  SUBROUTINE PH_Init_Material_State(args, nstatev_in, status)
    TYPE(PH_Mat_Integration_Args), INTENT(INOUT) :: args
    INTEGER(i4), INTENT(IN) :: nstatev_in
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    IF (nstatev_in <= 0) THEN
      CALL init_error_status(status, STATUS_ERR, "Invalid nstatev")
      RETURN
    END IF

    IF (ALLOCATED(args%statev_in)) DEALLOCATE(args%statev_in)
    IF (ALLOCATED(args%statev_out)) DEALLOCATE(args%statev_out)

    ALLOCATE(args%statev_in(nstatev_in))
    ALLOCATE(args%statev_out(nstatev_in))

    args%statev_in = 0.0_wp
    args%statev_out = 0.0_wp
    args%nstatev = nstatev_in

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Init_Material_State

  !============================================================================
  ! Private helper: Linear elastic update (default fallback)
  !============================================================================
  SUBROUTINE PH_Linear_Elastic_Update(args, status)
    TYPE(PH_Mat_Integration_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: E, nu, lambda, mu
    INTEGER(i4) :: i, j

    ! Extract material properties (standard ordering)
    IF (SIZE(args%props) < 2) THEN
      CALL init_error_status(status, STATUS_ERR, "Insufficient props")
      RETURN
    END IF

    E = args%props(1)
    nu = args%props(2)

    ! Compute Lamé parameters
    mu = E / (2.0_wp * (1.0_wp + nu))
    lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))

    ! Initialize tangent
    args%ddsdde = 0.0_wp

    ! Fill isotropic elastic tangent
    DO i = 1, args%nstrain
      DO j = 1, args%nstrain
        IF (i <= 3 .AND. j <= 3) THEN
          ! Normal components
          IF (i == j) THEN
            args%ddsdde(i,j) = lambda + 2.0_wp * mu
          ELSE
            args%ddsdde(i,j) = lambda
          END IF
        ELSE IF (i == j) THEN
          ! Shear components (4,5,6)
          args%ddsdde(i,j) = mu
        END IF
      END DO
    END DO

    ! Update stress: sigma = D : epsilon
    args%stress = MATMUL(args%ddsdde, args%strain)

    CALL init_error_status(status, IF_STATUS_OK)

  END SUBROUTINE PH_Linear_Elastic_Update

END MODULE PH_Elem_MatIntegration