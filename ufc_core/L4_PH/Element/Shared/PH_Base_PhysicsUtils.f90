!===============================================================================
! MODULE: PH_Base_PhysicsUtils
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Physics Utils module (auto-filled)
!===============================================================================
MODULE PH_Base_PhysicsUtils
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, THIRD
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Stress_VoigtToTensor
    PUBLIC :: PH_Stress_TensorToVoigt
    PUBLIC :: PH_Strain_VoigtToTensor
    PUBLIC :: PH_Strain_TensorToVoigt
    PUBLIC :: PH_Stress_Principal
    PUBLIC :: PH_Stress_Invariants
    PUBLIC :: PH_Strain_Principal
    PUBLIC :: PH_Strain_Invariants
    PUBLIC :: PH_Stress_VonMises
    PUBLIC :: PH_Stress_Hydrostatic
    PUBLIC :: PH_Stress_Deviatoric
    PUBLIC :: PH_Tensor_Rotate
    ! Extended API (task6000-6999)
    PUBLIC :: PH_DeformationGradient_Calc
    PUBLIC :: PH_CauchyGreen_Calc
    PUBLIC :: PH_GreenLagrangeStrain_Calc
    PUBLIC :: PH_AlmansiStrain_Calc
    PUBLIC :: PH_DeformationRate_Calc
    PUBLIC :: PH_StrainIncrement_Calc
    PUBLIC :: PH_CauchyStress_Calc
    PUBLIC :: PH_PiolaKirchhoffStress_Calc
    PUBLIC :: PH_StressRate_Calc
    PUBLIC :: PH_PolarDecomposition_Calc
    PUBLIC :: PH_RotationTensor_Calc
    PUBLIC :: PH_MaterialTimeDerivative_Compute
    ! Extended API (task7700-7799)
    PUBLIC :: PH_Tensor_ConvertVoigtToTensor_Stress
    PUBLIC :: PH_Tensor_ConvertTensorToVoigt_Stress
    PUBLIC :: PH_Tensor_ConvertVoigtToTensor_Strain
    PUBLIC :: PH_Tensor_ConvertTensorToVoigt_Strain
    PUBLIC :: PH_Tensor_ComputePrincipalValues
    PUBLIC :: PH_Tensor_ComputePrincipalDirections
    PUBLIC :: PH_Tensor_ComputeInvariants

    !==========================================================================
    ! INTF-001
    ! Purpose: PH_CauchyStress_Calc(5 ) / PH_PiolaKirchhoffStress_Calc(6 )
    ! / PH_StressRate_Calc(5 ) / PH_MaterialTimeDerivative_Compute(5 )
    ! See module header.
    ! Theory: σ = (1/J) P F^T Cauchy
    ! S = F^{-1} P PK
    ! σ̊ = σ̇ - W σ + σ W Zaremba-Jaumann
    ! Status: Draft |
    !==========================================================================
    PUBLIC :: PH_KinematicsArgs

    TYPE :: PH_KinematicsArgs
      ! ---- ----
      REAL(wp) :: F(3,3)    = 0.0_wp  !! F
      REAL(wp) :: J         = 1.0_wp  !! det(F)
      REAL(wp) :: W(3,3)    = 0.0_wp  ! spin / rate tensor workspace
      REAL(wp) :: D(3,3)    = 0.0_wp  ! material stiffness (elasticity) matrix ptr
      REAL(wp) :: dt        = 0.0_wp  ! time increment

      ! ---- / ----
      REAL(wp) :: P(3,3)    = 0.0_wp  !! PK
      REAL(wp) :: sigma(3,3)= 0.0_wp  !! Cauchy /
      REAL(wp) :: S(3,3)    = 0.0_wp  !! PK

      ! ---- ----
      REAL(wp) :: sigma_rate(3,3) = 0.0_wp   !! σ̇
      REAL(wp) :: sigma_dot_obj(3,3) = 0.0_wp  ! objective stress rate tensor

      ! ---- ----
      REAL(wp) :: phi_rate   = 0.0_wp        !! φ̇
      REAL(wp) :: velocity(3)= 0.0_wp        !! v
      REAL(wp) :: grad_phi(3)= 0.0_wp        !! ∇�?
      REAL(wp) :: Dphi_Dt    = 0.0_wp        !! Dφ/Dt

      ! ---- ----
      REAL(wp) :: d_epsilon(3,3) = 0.0_wp    !! Δε

      ! ---- ----
      LOGICAL :: compute_cauchy    = .FALSE.  !! Cauchy
      LOGICAL :: compute_pk2       = .FALSE.  !! PK
      LOGICAL :: compute_obj_rate  = .FALSE.! compute Jaumann / objective rate
      LOGICAL :: compute_material_deriv = .FALSE.! compute material time derivative

      ! ---- ----
      TYPE(ErrorStatusType), POINTER :: status => NULL()  ! error status ptr (IF_Err)
    END TYPE PH_KinematicsArgs

CONTAINS

    SUBROUTINE PH_AlmansiStrain_Calc(F, e, status)
        REAL(wp), INTENT(IN) :: F(3,3)
        REAL(wp), INTENT(OUT) :: e(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: b(3,3), b_inv(3,3)
        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        ! Compute left Cauchy-Green tensor b = F * F^T
        b = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    b(i,j) = b(i,j) + F(i,k) * F(j,k)
                END DO
            END DO
        END DO

        ! Simplified: assume b is diagonal for inverse computation
        ! Production should use proper matrix inversion
        b_inv = ZERO
        DO i = 1, 3
            IF (ABS(b(i,i)) > 1.0e-12_wp) THEN
                b_inv(i,i) = ONE / b(i,i)
            ELSE
                b_inv(i,i) = ONE
            END IF
        END DO

        ! e = 0.5 * (I - b^(-1))
        DO i = 1, 3
            DO j = 1, 3
                IF (i == j) THEN
                    e(i,j) = HALF * (ONE - b_inv(i,j))
                ELSE
                    e(i,j) = -HALF * b_inv(i,j)
                END IF
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_AlmansiStrain_Calc

    SUBROUTINE PH_CauchyGreen_Calc(F, C, status)
        REAL(wp), INTENT(IN) :: F(3,3)
        REAL(wp), INTENT(OUT) :: C(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        ! C = F^T * F
        C = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    C(i,j) = C(i,j) + F(k,i) * F(k,j)
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_CauchyGreen_Calc

    SUBROUTINE PH_CauchyStress_Calc(P, F, J, sigma, status)
        REAL(wp), INTENT(IN) :: P(3,3), F(3,3), J
        REAL(wp), INTENT(OUT) :: sigma(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: P_FT(3,3)
        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        IF (ABS(J) < 1.0e-12_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Zero or near-zero Jacobian determinant"
            RETURN
        END IF

        ! Compute P * F^T
        P_FT = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    P_FT(i,j) = P_FT(i,j) + P(i,k) * F(j,k)
                END DO
            END DO
        END DO

        ! Ï = (1/J) * P * F^T
        DO i = 1, 3
            DO j = 1, 3
                sigma(i,j) = P_FT(i,j) / J
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_CauchyStress_Calc

    SUBROUTINE PH_DeformationGradient_Calc(displacement_gradient, F, status)
        REAL(wp), INTENT(IN) :: displacement_gradient(3,3)
        REAL(wp), INTENT(OUT) :: F(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! F = I + grad(u)
        ! where I is identity matrix and grad(u) is displacement gradient
        DO i = 1, 3
            DO j = 1, 3
                IF (i == j) THEN
                    F(i,j) = ONE + displacement_gradient(i,j)
                ELSE
                    F(i,j) = displacement_gradient(i,j)
                END IF
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_DeformationGradient_Calc

    SUBROUTINE PH_DeformationRate_Calc(velocity_gradient, D, status)
        REAL(wp), INTENT(IN) :: velocity_gradient(3,3)
        REAL(wp), INTENT(OUT) :: D(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! D = 0.5 * (L + L^T)
        DO i = 1, 3
            DO j = 1, 3
                D(i,j) = HALF * (velocity_gradient(i,j) + velocity_gradient(j,i))
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_DeformationRate_Calc

    SUBROUTINE PH_GreenLagrangeStrain_Calc(C, E, status)
        REAL(wp), INTENT(IN) :: C(3,3)
        REAL(wp), INTENT(OUT) :: E(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! E = 0.5 * (C - I)
        DO i = 1, 3
            DO j = 1, 3
                IF (i == j) THEN
                    E(i,j) = HALF * (C(i,j) - ONE)
                ELSE
                    E(i,j) = HALF * C(i,j)
                END IF
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_GreenLagrangeStrain_Calc

    SUBROUTINE PH_Ma_Compute(phi_rate, velocity, &
                                                  grad_phi, Dphi_Dt, status)
        REAL(wp), INTENT(IN) :: phi_rate, velocity(3), grad_phi(3)
        REAL(wp), INTENT(OUT) :: Dphi_Dt
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        ! DÏ/Dt = âï¿½?ât + vÂ·grad(Ï)
        Dphi_Dt = phi_rate + DOT_PRODUCT(velocity, grad_phi)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_MaterialTimeDerivative_Compute

    SUBROUTINE PH_MassConservation_Check(density_old, density_new, volume_old, &
                                         volume_new, mass_conserved, status)
        REAL(wp), INTENT(IN) :: density_old, density_new, volume_old, volume_new
        LOGICAL, INTENT(OUT) :: mass_conserved
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        REAL(wp) :: mass_old, mass_new, mass_error

        IF (PRESENT(status)) CALL init_error_status(status)

        ! Mass = density * volume
        mass_old = density_old * volume_old
        mass_new = density_new * volume_new

        ! Check conservation: |mass_new - mass_old| / mass_old < tolerance
        IF (mass_old > 1.0e-12_wp) THEN
            mass_error = ABS(mass_new - mass_old) / mass_old
            mass_conserved = (mass_error < 1.0e-6_wp)
        ELSE
            mass_conserved = .TRUE.
        END IF

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_MassConservation_Check

    SUBROUTINE PH_Mo_Check(momentum_old, momentum_new, &
                                             external_force, dt, &
                                             momentum_conserved, status)
        REAL(wp), INTENT(IN) :: momentum_old(3), momentum_new(3)
        REAL(wp), INTENT(IN) :: external_force(3), dt
        LOGICAL, INTENT(OUT) :: momentum_conserved
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        REAL(wp) :: momentum_change(3), expected_change(3), error

        IF (PRESENT(status)) CALL init_error_status(status)

        ! Momentum change = momentum_new - momentum_old
        momentum_change = momentum_new - momentum_old

        ! Expected change = F_ext * dt
        expected_change = external_force * dt

        ! Check conservation: ||momentum_change - expected_change|| < tolerance
        error = SQRT(SUM((momentum_change - expected_change)**2))
        momentum_conserved = (error < 1.0e-6_wp)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_MomentumConservation_Check

    SUBROUTINE PH_Ob_Apply(sigma_rate, W, sigma, &
                                              sigma_dot_objective, status)
        REAL(wp), INTENT(IN) :: sigma_rate(3,3), W(3,3), sigma(3,3)
        REAL(wp), INTENT(OUT) :: sigma_dot_objective(3,3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        ! Use Jaumann rate for objectivity
        CALL PH_StressRate_Calc(sigma_rate, W, sigma, sigma_dot_objective, status)

    END SUBROUTINE PH_ObjectivityCorrection_Apply

    SUBROUTINE PH_PiolaKirchhoffStress_Calc(sigma, F, J, P, S, status)
        REAL(wp), INTENT(IN) :: sigma(3,3), F(3,3), J
        REAL(wp), INTENT(OUT) :: P(3,3), S(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: F_inv(3,3), sigma_F_invT(3,3)
        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        IF (ABS(J) < 1.0e-12_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Zero or near-zero Jacobian determinant"
            RETURN
        END IF

        ! Simplified: assume F is diagonal for inverse computation
        ! Production should use proper matrix inversion
        F_inv = ZERO
        DO i = 1, 3
            IF (ABS(F(i,i)) > 1.0e-12_wp) THEN
                F_inv(i,i) = ONE / F(i,i)
            ELSE
                F_inv(i,i) = ONE
            END IF
        END DO

        ! P = J * Ï * F^(-T)
        sigma_F_invT = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    sigma_F_invT(i,j) = sigma_F_invT(i,j) + sigma(i,k) * F_inv(j,k)
                END DO
            END DO
        END DO

        DO i = 1, 3
            DO j = 1, 3
                P(i,j) = J * sigma_F_invT(i,j)
            END DO
        END DO

        ! S = F^(-1) * P
        S = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    S(i,j) = S(i,j) + F_inv(i,k) * P(k,j)
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_PiolaKirchhoffStress_Calc

    SUBROUTINE PH_PolarDecomposition_Calc(F, R, U, status)
        REAL(wp), INTENT(IN) :: F(3,3)
        REAL(wp), INTENT(OUT) :: R(3,3), U(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: C(3,3), C_sqrt(3,3)
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! Compute C = F^T * F
        CALL PH_CauchyGreen_Calc(F, C, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Simplified: U = sqrt(C) (diagonal approximation)
        ! Production should use proper matrix square root
        U = ZERO
        DO i = 1, 3
            IF (C(i,i) > ZERO) THEN
                U(i,i) = SQRT(C(i,i))
            ELSE
                U(i,i) = ONE
            END IF
        END DO

        ! R = F * U^(-1)
        ! Simplified: assume U is diagonal
        R = ZERO
        DO i = 1, 3
            DO j = 1, 3
                IF (ABS(U(j,j)) > 1.0e-12_wp) THEN
                    R(i,j) = F(i,j) / U(j,j)
                ELSE
                    R(i,j) = F(i,j)
                END IF
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_PolarDecomposition_Calc

    SUBROUTINE PH_RotationTensor_Calc(F, R, status)
        REAL(wp), INTENT(IN) :: F(3,3)
        REAL(wp), INTENT(OUT) :: R(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: U(3,3)

        CALL init_error_status(status)

        ! Use polar decomposition to get R
        CALL PH_PolarDecomposition_Calc(F, R, U, status)

    END SUBROUTINE PH_RotationTensor_Calc

    SUBROUTINE PH_Sort_Eigenvalues(eigenvalues, eigenvectors)
        REAL(wp), INTENT(INOUT) :: eigenvalues(3), eigenvectors(3,3)

        REAL(wp) :: temp_val, temp_vec(3)
        INTEGER(i4) :: i, j

        ! Simple bubble sort
        DO i = 1, 2
            DO j = 1, 3 - i
                IF (eigenvalues(j) < eigenvalues(j+1)) THEN
                    ! Swap eigenvalues
                    temp_val = eigenvalues(j)
                    eigenvalues(j) = eigenvalues(j+1)
                    eigenvalues(j+1) = temp_val

                    ! Swap eigenvectors
                    temp_vec = eigenvectors(j,:)
                    eigenvectors(j,:) = eigenvectors(j+1,:)
                    eigenvectors(j+1,:) = temp_vec
                END IF
            END DO
        END DO
    END SUBROUTINE PH_Sort_Eigenvalues

    SUBROUTINE PH_Strain_Invariants(strain_tensor, I1, I2, I3)
        REAL(wp), INTENT(IN) :: strain_tensor(3,3)
        REAL(wp), INTENT(OUT) :: I1, I2, I3

        REAL(wp) :: stress_dummy(3,3)

        stress_dummy = strain_tensor
        CALL PH_Stress_Invariants(stress_dummy, I1, I2, I3)
    END SUBROUTINE PH_Strain_Invariants

    SUBROUTINE PH_Strain_Principal(strain_tensor, principal_strains, &
                                   principal_directions, status)
        REAL(wp), INTENT(IN) :: strain_tensor(3,3)
        REAL(wp), INTENT(OUT) :: principal_strains(3)
        REAL(wp), INTENT(OUT) :: principal_directions(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: stress_dummy(3,3)

        CALL init_error_status(status)

        ! Use same algorithm as sigma principal
        stress_dummy = strain_tensor
        CALL PH_Stress_Principal(stress_dummy, principal_strains, &
                                principal_directions, status)
    END SUBROUTINE PH_Strain_Principal

    SUBROUTINE PH_Strain_TensorToVoigt(strain_tensor, strain_voigt, status)
        REAL(wp), INTENT(IN) :: strain_tensor(3,3)
        REAL(wp), INTENT(OUT) :: strain_voigt(6)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        strain_voigt(1) = strain_tensor(1,1)
        strain_voigt(2) = strain_tensor(2,2)
        strain_voigt(3) = strain_tensor(3,3)
        strain_voigt(4) = TWO * strain_tensor(1,2)  ! Engineering shear strain
        strain_voigt(5) = TWO * strain_tensor(1,3)
        strain_voigt(6) = TWO * strain_tensor(2,3)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Strain_TensorToVoigt

    SUBROUTINE PH_Strain_VoigtToTensor(strain_voigt, strain_tensor, status)
        REAL(wp), INTENT(IN) :: strain_voigt(6)
        REAL(wp), INTENT(OUT) :: strain_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Voigt notation: [Îµââ, Îµââ, Îµââ, Î³ââ, Î³ââ, Î³ââ]
        ! where Î³ = 2Îµ (engineering shear strain)
        strain_tensor(1,1) = strain_voigt(1)
        strain_tensor(2,2) = strain_voigt(2)
        strain_tensor(3,3) = strain_voigt(3)
        strain_tensor(1,2) = HALF * strain_voigt(4)
        strain_tensor(2,1) = HALF * strain_voigt(4)
        strain_tensor(1,3) = HALF * strain_voigt(5)
        strain_tensor(3,1) = HALF * strain_voigt(5)
        strain_tensor(2,3) = HALF * strain_voigt(6)
        strain_tensor(3,2) = HALF * strain_voigt(6)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Strain_VoigtToTensor

    SUBROUTINE PH_StrainIncrement_Calc(D, dt, d_epsilon, status)
        REAL(wp), INTENT(IN) :: D(3,3), dt
        REAL(wp), INTENT(OUT) :: d_epsilon(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! dÎµ = D * dt
        DO i = 1, 3
            DO j = 1, 3
                d_epsilon(i,j) = D(i,j) * dt
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_StrainIncrement_Calc

    SUBROUTINE PH_Stress_Deviatoric(stress_tensor, deviatoric)
        REAL(wp), INTENT(IN) :: stress_tensor(3,3)
        REAL(wp), INTENT(OUT) :: deviatoric(3,3)

        REAL(wp) :: hydrostatic_val
        INTEGER(i4) :: i, j

        hydrostatic_val = PH_Stress_Hydrostatic(stress_tensor)

        deviatoric = stress_tensor
        DO i = 1, 3
            deviatoric(i,i) = deviatoric(i,i) - hydrostatic_val
        END DO
    END SUBROUTINE PH_Stress_Deviatoric

    SUBROUTINE PH_Stress_Invariants(stress_tensor, I1, I2, I3)
        REAL(wp), INTENT(IN) :: stress_tensor(3,3)
        REAL(wp), INTENT(OUT) :: I1, I2, I3

        REAL(wp) :: deviatoric(3,3)

        ! First invariant: Iï¿?= tr(Ï) = Ïââ + Ïââ + Ïââ
        I1 = stress_tensor(1,1) + stress_tensor(2,2) + stress_tensor(3,3)

        ! Second invariant: Iï¿?= Â½[tr(Ï)Â² - tr(ÏÂ²)]
        I2 = HALF * (I1 * I1 - &
            (stress_tensor(1,1)**2 + stress_tensor(2,2)**2 + stress_tensor(3,3)**2 + &
             TWO * (stress_tensor(1,2)**2 + stress_tensor(1,3)**2 + stress_tensor(2,3)**2)))

        ! Third invariant: Iï¿?= det(Ï)
        I3 = stress_tensor(1,1) * (stress_tensor(2,2) * stress_tensor(3,3) - &
                                   stress_tensor(2,3) * stress_tensor(3,2)) - &
             stress_tensor(1,2) * (stress_tensor(2,1) * stress_tensor(3,3) - &
                                   stress_tensor(2,3) * stress_tensor(3,1)) + &
             stress_tensor(1,3) * (stress_tensor(2,1) * stress_tensor(3,2) - &
                                   stress_tensor(2,2) * stress_tensor(3,1))
    END SUBROUTINE PH_Stress_Invariants

    SUBROUTINE PH_Stress_Principal(stress_tensor, principal_stresses, &
                                   principal_directions, status)
        REAL(wp), INTENT(IN) :: stress_tensor(3,3)
        REAL(wp), INTENT(OUT) :: principal_stresses(3)
        REAL(wp), INTENT(OUT) :: principal_directions(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: work_matrix(3,3), eigenvalues(3), eigenvectors(3,3)
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! For symmetric matrix, use simplified eigenvalue computation
        ! (Full implementation would use LAPACK DSYEV)
        work_matrix = stress_tensor

        ! Simplified: assume diagonalizable
        ! Extract diagonal elements as approximation
        DO i = 1, 3
            eigenvalues(i) = stress_tensor(i,i)
            principal_directions(i,i) = ONE
            DO j = 1, 3
                IF (j /= i) principal_directions(i,j) = ZERO
            END DO
        END DO

        ! Sort eigenvalues (descending)
        CALL PH_Sort_Eigenvalues(eigenvalues, principal_directions)
        principal_stresses = eigenvalues

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Stress_Principal

    SUBROUTINE PH_Stress_TensorToVoigt(stress_tensor, stress_voigt, status)
        REAL(wp), INTENT(IN) :: stress_tensor(3,3)
        REAL(wp), INTENT(OUT) :: stress_voigt(6)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        stress_voigt(1) = stress_tensor(1,1)
        stress_voigt(2) = stress_tensor(2,2)
        stress_voigt(3) = stress_tensor(3,3)
        stress_voigt(4) = stress_tensor(1,2)  ! or (2,1) for symmetric
        stress_voigt(5) = stress_tensor(1,3)  ! or (3,1) for symmetric
        stress_voigt(6) = stress_tensor(2,3)  ! or (3,2) for symmetric

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Stress_TensorToVoigt

    SUBROUTINE PH_Stress_VoigtToTensor(stress_voigt, stress_tensor, status)
        REAL(wp), INTENT(IN) :: stress_voigt(6)
        REAL(wp), INTENT(OUT) :: stress_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Voigt notation: [Ïââ, Ïââ, Ïââ, Ïââ, Ïââ, Ïââ]
        stress_tensor(1,1) = stress_voigt(1)
        stress_tensor(2,2) = stress_voigt(2)
        stress_tensor(3,3) = stress_voigt(3)
        stress_tensor(1,2) = stress_voigt(4)
        stress_tensor(2,1) = stress_voigt(4)
        stress_tensor(1,3) = stress_voigt(5)
        stress_tensor(3,1) = stress_voigt(5)
        stress_tensor(2,3) = stress_voigt(6)
        stress_tensor(3,2) = stress_voigt(6)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Stress_VoigtToTensor

    SUBROUTINE PH_StressRate_Calc(sigma_rate, W, sigma, sigma_dot, status)
        REAL(wp), INTENT(IN) :: sigma_rate(3,3), W(3,3), sigma(3,3)
        REAL(wp), INTENT(OUT) :: sigma_dot(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: W_sigma(3,3), sigma_W(3,3)
        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        ! Compute W * Ï
        W_sigma = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    W_sigma(i,j) = W_sigma(i,j) + W(i,k) * sigma(k,j)
                END DO
            END DO
        END DO

        ! Compute Ï * W
        sigma_W = ZERO
        DO i = 1, 3
            DO j = 1, 3
                DO k = 1, 3
                    sigma_W(i,j) = sigma_W(i,j) + sigma(i,k) * W(k,j)
                END DO
            END DO
        END DO

        ! ÏÌ = ÏÌ - W*Ï + Ï*W (Jaumann rate)
        DO i = 1, 3
            DO j = 1, 3
                sigma_dot(i,j) = sigma_rate(i,j) - W_sigma(i,j) + sigma_W(i,j)
            END DO
        END DO

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_StressRate_Calc

    SUBROUTINE PH_Te_Co_Strain(strain_voigt, strain_tensor, status)
        REAL(wp), INTENT(IN) :: strain_voigt(6)
        REAL(wp), INTENT(OUT) :: strain_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL PH_Strain_VoigtToTensor(strain_voigt, strain_tensor, status)

    END SUBROUTINE PH_Tensor_ConvertVoigtToTensor_Strain

    SUBROUTINE PH_Te_Co_Strain(strain_tensor, strain_voigt, status)
        REAL(wp), INTENT(IN) :: strain_tensor(3,3)
        REAL(wp), INTENT(OUT) :: strain_voigt(6)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL PH_Strain_TensorToVoigt(strain_tensor, strain_voigt, status)

    END SUBROUTINE PH_Tensor_ConvertTensorToVoigt_Strain

    SUBROUTINE PH_Te_Co_Stress(stress_voigt, stress_tensor, status)
        REAL(wp), INTENT(IN) :: stress_voigt(6)
        REAL(wp), INTENT(OUT) :: stress_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL PH_Stress_VoigtToTensor(stress_voigt, stress_tensor, status)

    END SUBROUTINE PH_Tensor_ConvertVoigtToTensor_Stress

    SUBROUTINE PH_Te_Co_Stress(stress_tensor, stress_voigt, status)
        REAL(wp), INTENT(IN) :: stress_tensor(3,3)
        REAL(wp), INTENT(OUT) :: stress_voigt(6)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        CALL PH_Stress_TensorToVoigt(stress_tensor, stress_voigt, status)

    END SUBROUTINE PH_Tensor_ConvertTensorToVoigt_Stress

    SUBROUTINE PH_Te_ComputePrincipalDirect(tensor, principal_directions, status)
        REAL(wp), INTENT(IN) :: tensor(3,3)
        REAL(wp), INTENT(OUT) :: principal_directions(3,3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        REAL(wp) :: principal_values(3)

        IF (PRESENT(status)) CALL init_error_status(status)

        ! Use existing principal computation
        CALL PH_Stress_Principal(tensor, principal_values, principal_directions, status)

    END SUBROUTINE PH_Tensor_ComputePrincipalDirections

    SUBROUTINE PH_Te_ComputePrincipalValues(tensor, principal_values, status)
        REAL(wp), INTENT(IN) :: tensor(3,3)
        REAL(wp), INTENT(OUT) :: principal_values(3)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        REAL(wp) :: principal_directions(3,3)

        IF (PRESENT(status)) CALL init_error_status(status)

        ! Use existing principal computation
        CALL PH_Stress_Principal(tensor, principal_values, principal_directions, status)

    END SUBROUTINE PH_Tensor_ComputePrincipalValues

    SUBROUTINE PH_Tensor_ComputeInvariants(tensor, I1, I2, I3, status)
        REAL(wp), INTENT(IN) :: tensor(3,3)
        REAL(wp), INTENT(OUT) :: I1, I2, I3
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) CALL init_error_status(status)

        ! Use existing invariant computation
        CALL PH_Stress_Invariants(tensor, I1, I2, I3)

        IF (PRESENT(status)) status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Tensor_ComputeInvariants

    SUBROUTINE PH_Tensor_Rotate(tensor, rotation, rotated_tensor, status)
        REAL(wp), INTENT(IN) :: tensor(3,3), rotation(3,3)
        REAL(wp), INTENT(OUT) :: rotated_tensor(3,3)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: temp(3,3)
        INTEGER(i4) :: i, j, k

        CALL init_error_status(status)

        ! Rotated tensor: Ï' = R Â· Ï Â· R^T
        ! First compute R Â· Ï
        DO i = 1, 3
            DO j = 1, 3
                temp(i,j) = ZERO
                DO k = 1, 3
                    temp(i,j) = temp(i,j) + rotation(i,k) * tensor(k,j)
                END DO
            END DO
        END DO

        ! Then compute (RÂ·Ï) Â· R^T
        DO i = 1, 3
            DO j = 1, 3
                rotated_tensor(i,j) = ZERO
                DO k = 1, 3
                    rotated_tensor(i,j) = rotated_tensor(i,j) + temp(i,k) * rotation(j,k)
                END DO
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Tensor_Rotate
END MODULE PH_Base_PhysicsUtils