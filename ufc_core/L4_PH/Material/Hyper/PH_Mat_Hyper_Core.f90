!===============================================================================
! MODULE: PH_Mat_Hyper_Core
! LAYER:  L4_PH
! DOMAIN: Material / Hyper
! ROLE:   Core
! BRIEF:  Core computation routines for hyperelastic material family.
!===============================================================================
MODULE PH_Mat_Hyper_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Hyper_Def, ONLY: PH_Mat_Hyper_Desc, PH_Mat_Hyper_State, &
                               PH_Mat_Hyper_Algo, PH_Mat_Hyper_Ctx, &
                               PH_MAT_HYPER_SUB_NEO_HOOKEAN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Hyper_Populate_From_L3
  PUBLIC :: PH_Mat_Hyper_Compute_Invariants
  PUBLIC :: PH_Mat_Hyper_Compute_Stress
  PUBLIC :: PH_Mat_Hyper_Update_State

CONTAINS

  SUBROUTINE PH_Mat_Hyper_Populate_From_L3(desc, l3_props, l3_nprops, &
                                            l3_sub_type, status)
    TYPE(PH_Mat_Hyper_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops, l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    desc%cfg%sub_type = l3_sub_type

    IF (l3_nprops >= 2) THEN
      desc%C10 = l3_props(1)
      desc%D1 = l3_props(2)
    END IF
    IF (l3_nprops >= 3) desc%C01 = l3_props(3)

    desc%pop%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Hyper_Populate_From_L3

  SUBROUTINE PH_Mat_Hyper_Compute_Invariants(F, I1, I2, I3, J, status)
    REAL(wp), INTENT(IN) :: F(3,3)
    REAL(wp), INTENT(OUT) :: I1, I2, I3, J
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: C(3,3)
    INTEGER(i4) :: i, j, k

    CALL init_error_status(status)

    ! C = F^T * F
    DO i = 1, 3
      DO j = 1, 3
        C(i,j) = 0.0_wp
        DO k = 1, 3
          C(i,j) = C(i,j) + F(k,i) * F(k,j)
        END DO
      END DO
    END DO

    ! Invariants
    I1 = C(1,1) + C(2,2) + C(3,3)
    I2 = 0.5_wp * (I1**2 - (C(1,1)**2 + C(2,2)**2 + C(3,3)**2 + &
                             2.0_wp*(C(1,2)**2 + C(1,3)**2 + C(2,3)**2)))
    J = F(1,1)*(F(2,2)*F(3,3) - F(2,3)*F(3,2)) - &
        F(1,2)*(F(2,1)*F(3,3) - F(2,3)*F(3,1)) + &
        F(1,3)*(F(2,1)*F(3,2) - F(2,2)*F(3,1))
    I3 = J**2

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Hyper_Compute_Invariants

  SUBROUTINE PH_Mat_Hyper_Compute_Stress(desc, state, algo, ctx, &
                                          F, stress, ddsdde, status)
    TYPE(PH_Mat_Hyper_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Hyper_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Hyper_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Hyper_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: F(3,3)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: I1, I2, I3, J

    CALL init_error_status(status)

    ! Compute invariants
    CALL PH_Mat_Hyper_Compute_Invariants(F, I1, I2, I3, J, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Neo-Hookean stress computation
    ! S = 2 * (C10 * J^(-2/3)) * (I - (1/3)*I1*C^{-1}) + 2/D1 * (J-1) * J * C^{-1}
    ! Cauchy stress: sigma = (1/J) * F * S * F^T

    SELECT CASE (desc%cfg%sub_type)
    CASE (PH_MAT_HYPER_SUB_NEO_HOOKEAN)
      ! Compressible Neo-Hookean: W = C10*(I1-3) + (1/D1)*(J-1)^2
      ! Kirchhoff stress: tau = 2*C10*dev(b_bar) + (2/D1)*J*(J-1)*I
      ! where b_bar = J^(-2/3) * b, b = F * F^T
      CALL NeoHookean_Stress(desc, I1, I2, I3, J, F, stress, ddsdde, status)

    CASE DEFAULT
      ! Fallback: identity-based approximation
      stress(1:3) = (2.0_wp * desc%C10 / J) * (1.0_wp - 1.0_wp / (3.0_wp * I1))
      stress(4:6) = 0.0_wp
      ddsdde = 0.0_wp
    END SELECT
  END SUBROUTINE PH_Mat_Hyper_Compute_Stress

  SUBROUTINE PH_Mat_Hyper_Update_State(state, stress, F, status)
    TYPE(PH_Mat_Hyper_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(6), F(3,3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%stress = stress
    state%F = F
    state%num_evaluations = state%num_evaluations + 1
    state%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Hyper_Update_State

  !-----------------------------------------------------------------------------
  ! NeoHookean_Stress
  ! Compressible Neo-Hookean: W = C10*(I1-3) + (1/D1)*(J-1)^2
  ! Returns Cauchy stress in Voigt notation (6-component) and tangent stiffness
  !-----------------------------------------------------------------------------
  SUBROUTINE NeoHookean_Stress(desc, I1, I2, I3, J, F, stress, ddsdde, status)
    TYPE(PH_Mat_Hyper_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: I1, I2, I3, J, F(3,3)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: Jm23, b_dev(3,3), b(3,3), tau(3,3), sigma(3,3)
    REAL(wp) :: p, mu, K_vol
    INTEGER(i4) :: i, j, k, l

    CALL init_error_status(status)

    ! Material parameters
    mu = 2.0_wp * desc%C10          ! Shear modulus
    K_vol = 2.0_wp / desc%D1        ! Bulk modulus

    ! Left Cauchy-Green: b = F * F^T
    b = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        DO k = 1, 3
          b(i,j) = b(i,j) + F(i,k) * F(j,k)
        END DO
      END DO
    END DO

    ! Isochoric part: b_bar = J^(-2/3) * b
    Jm23 = J**(-2.0_wp / 3.0_wp)

    ! Deviatoric part of b_bar
    b_dev = b
    DO i = 1, 3
      b_dev(i,i) = b_dev(i,i) - (I1 / 3.0_wp)
    END DO
    b_dev = Jm23 * b_dev

    ! Pressure from volumetric term: p = (2/D1)*(J-1)
    p = K_vol * (J - 1.0_wp)

    ! Kirchhoff stress: tau = mu * dev(b_bar) + p * J * I
    tau = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        tau(i,j) = mu * b_dev(i,j)
      END DO
    END DO
    DO i = 1, 3
      tau(i,i) = tau(i,i) + p * J
    END DO

    ! Cauchy stress: sigma = tau / J
    sigma = tau / J

    ! Convert Cauchy to Voigt (6-component): [sig11, sig22, sig33, tau12, tau13, tau23]
    stress(1) = sigma(1,1)
    stress(2) = sigma(2,2)
    stress(3) = sigma(3,3)
    stress(4) = sigma(1,2)
    stress(5) = sigma(1,3)
    stress(6) = sigma(2,3)

    ! Simplified tangent (isotropic elastic tangent for small-strain approximation)
    ddsdde = 0.0_wp
    ddsdde(1,1) = K_vol + 4.0_wp*mu/3.0_wp
    ddsdde(1,2) = K_vol - 2.0_wp*mu/3.0_wp
    ddsdde(1,3) = K_vol - 2.0_wp*mu/3.0_wp
    ddsdde(2,1) = ddsdde(1,2)
    ddsdde(2,2) = K_vol + 4.0_wp*mu/3.0_wp
    ddsdde(2,3) = ddsdde(1,2)
    ddsdde(3,1) = ddsdde(1,3)
    ddsdde(3,2) = ddsdde(2,3)
    ddsdde(3,3) = K_vol + 4.0_wp*mu/3.0_wp
    ddsdde(4,4) = mu
    ddsdde(5,5) = mu
    ddsdde(6,6) = mu

    status%status_code = IF_STATUS_OK
  END SUBROUTINE NeoHookean_Stress

END MODULE PH_Mat_Hyper_Core
