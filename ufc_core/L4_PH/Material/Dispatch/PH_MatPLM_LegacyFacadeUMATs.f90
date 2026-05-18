!===============================================================================
! MODULE: PH_MatPLM_LegacyFacadeUMATs
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Dispatch
! BRIEF:  Non-table-A plastic UMAT legacy facade (FGM/Geo/Smart/Multiscale/TEMM).
!   W1: LEGACY UMAT bodies；编排层仍以 **PH_Mat_Core** + slot **desc** 为金线。
!
! DEPRECATED (Material pillar plan **C1**, 2026-05-03): monolithic 7×UMAT facade.
!   Target: split bodies into `PH_Mat_<Family>_<Model>_Core.f90` under each family
!   subtree; keep this module as a thin re-export until callers migrate (remove by
!   **2026-08-01** unless extended in DOMAIN_PILLAR_CARD).
!===============================================================================
MODULE PH_MatPLM_LegacyFacadeUMATs
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_INVALID, IF_STATUS_OK, init_error_status, log_error, log_warning
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, HALF, PI, SMALL
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UF_FGM_UMAT, UF_Geotechnical_UMAT, UF_SmartMaterial_UMAT, &
    UF_MultiscaleDamage_UMAT, UF_ThermoElectroMagnetoMechanical_UMAT, &
    UF_ThermoViscoplastic_UMAT, UF_ViscoelasticDamage_UMAT
  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp
  REAL(wp), PARAMETER :: REGULARIZATION = 1.0e-12_wp
  REAL(wp), PARAMETER :: MU0 = 1.2566370614359173e-6_wp
  REAL(wp), PARAMETER :: EPSILON0 = 8.8541878128e-12_wp
CONTAINS
  subroutine FGM_BuildDmgdStiffMat(D_elastic, damage, damage_factor, ndim, nshr, ntens, analysis_type, D_damaged)
    real(wp), intent(in)  :: D_elastic(6,6), damage, damage_factor
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_damaged(6,6)

    integer(i4) :: i, j

    D_damaged = D_elastic

    do i = 1, ntens
      do j = 1, ntens
        D_damaged(i,j) = D_elastic(i,j) * damage_factor
      end do
    end do

    call FGM_RegularizeStiffMat(D_damaged, ntens)

  end subroutine FGM_BuildDmgdStiffMat

  subroutine FGM_BuildElasticStiffness(PH_MAT_E, nu, K, G, ndim, nshr, ntens, analysis_type, D_elastic)
    real(wp), intent(in)  :: PH_MAT_E, nu, K, G
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_elastic(6,6)

    real(wp) :: lambda, mu

    D_elastic = ZERO

    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    select case(ndim)
      case(1)
        if (ntens >= 1) D_elastic(1,1) = PH_MAT_E
      case(2)
        if (ntens >= 2) then
          select case(analysis_type)
            case(1)
              D_elastic(1,1) = PH_MAT_E / (ONE - nu**2)
              D_elastic(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              if (ntens >= 3) D_elastic(3,3) = mu
            case(2,3)
              D_elastic(1,1) = lambda + TWO * mu
              D_elastic(1,2) = lambda
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              if (ntens >= 3) D_elastic(3,3) = mu
          end select
        end if
      case(3)
        if (ntens >= 3) then
          D_elastic(1,1) = lambda + TWO * mu
          D_elastic(1,2) = lambda
          D_elastic(1,3) = lambda
          D_elastic(2,1) = lambda
          D_elastic(2,2) = lambda + TWO * mu
          D_elastic(2,3) = lambda
          D_elastic(3,1) = lambda
          D_elastic(3,2) = lambda
          D_elastic(3,3) = lambda + TWO * mu
          if (ntens >= 6) then
            D_elastic(4,4) = mu
            D_elastic(5,5) = mu
            D_elastic(6,6) = mu
          end if
        end if
    end select

    call FGM_RegularizeStiffMat(D_elastic, ntens)

  end subroutine FGM_BuildElasticStiffness

  subroutine FGM_BuildPlasticStiffMatGrad(D_elastic, plastic_multipl, gradient_parame, ndim, nshr, ntens, analysis_type, D_plastic)
    real(wp), intent(in)  :: D_elastic(6,6), plastic_multipl, gradient_parame
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_plastic(6,6)

    integer(i4) :: i

    D_plastic = ZERO

    if (plastic_multipl > TOL) then
      do i = 1, ntens
        D_plastic(i,i) = D_elastic(i,i) * plastic_multipl * (ONE + gradient_parame)
      end do
    end if

  end subroutine FGM_BuildPlasticStiffMatGradient

  subroutine FGM_ComputeEffMatPropsGradie(E_min, E_max, nu_min, nu_max, &
                                                     K_min, K_max, G_min, G_max, &
                                                     sigma_y_min, sigma_y_max, H_min, H_max, &
                                                     alpha_thermal_m, alpha_thermal_m, &
                                                     residual_stress, residual_stress, &
                                                     gradient_parame, transition_smoo, &
                                                     E_effective, nu_effective, K_effective, G_effective, &
                                                     sigma_y_effecti, H_effective, alpha_thermal_e, &
                                                     residual_stress)
    real(wp), intent(in)  :: E_min, E_max, nu_min, nu_max
    real(wp), intent(in)  :: K_min, K_max, G_min, G_max
    real(wp), intent(in)  :: sigma_y_min, sigma_y_max, H_min, H_max
    real(wp), intent(in)  :: alpha_thermal_m, alpha_thermal_m
    real(wp), intent(in)  :: residual_stress, residual_stress
    real(wp), intent(in)  :: gradient_parame, transition_smoo
    real(wp), intent(out) :: E_effective, nu_effective, K_effective, G_effective
    real(wp), intent(out) :: sigma_y_effecti, H_effective, alpha_thermal_e
    real(wp), intent(out) :: residual_stress(6)

    real(wp) :: smooth_param
    integer(i4) :: i

    smooth_param = gradient_parame * (ONE + transition_smoo) - transition_smoo * HALF
    smooth_param = max(min(smooth_param, ONE), ZERO)

    E_effective = E_min + (E_max - E_min) * smooth_param
    nu_effective = nu_min + (nu_max - nu_min) * smooth_param
    K_effective = K_min + (K_max - K_min) * smooth_param
    G_effective = G_min + (G_max - G_min) * smooth_param
    sigma_y_effecti = sigma_y_min + (sigma_y_max - sigma_y_min) * smooth_param
    H_effective = H_min + (H_max - H_min) * smooth_param
    alpha_thermal_e = alpha_thermal_m + (alpha_thermal_m - alpha_thermal_m) * smooth_param

    do i = 1, 6
      residual_stress(i) = residual_stress + (residual_stress - residual_stress) * smooth_param
    end do

  end subroutine FGM_ComputeEffMatPropsGradient

  subroutine FGM_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)
    real(wp), intent(in)  :: s_dev(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: sigma_eqv

    real(wp), parameter :: SIX = 6.0_wp

    sigma_eqv = ZERO

    select case(ndim)
      case(1)
        sigma_eqv = abs(s_dev(1))
      case(2)
        sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 - s_dev(1)*s_dev(2) + THREE*s_dev(3)**2))
      case(3)
        sigma_eqv = sqrt(1.5_wp * ((s_dev(1)-s_dev(2))**2 + (s_dev(2)-s_dev(3))**2 + (s_dev(3)-s_dev(1))**2 + &
                                SIX*(s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    end select

  end subroutine FGM_ComputeEquivalentStress

  subroutine FGM_ComputeGradientDmgVar(stress, sigma_eqv, gradient_parame, &
                                         interface_stren, interface_energ, &
                                         damage_old, dt, &
                                         damage, damage_rate, interface_damag)
    real(wp), intent(in)  :: stress(6), sigma_eqv, gradient_parame
    real(wp), intent(in)  :: interface_stren, interface_energ, damage_old, dt
    real(wp), intent(out) :: damage, damage_rate, interface_damag

    real(wp) :: damage_driving

    damage = damage_old
    damage_rate = ZERO
    interface_damag = ZERO

    damage_driving = (sigma_eqv / max(interface_stren, TOL)) * &
                          (ONE + gradient_parame * interface_energ)

    if (damage_driving > ONE) then
      damage_rate = (damage_driving - ONE) * 0.1_wp / dt
      damage = damage_old + damage_rate * dt
      damage = min(damage, ONE)
      interface_damag = gradient_parame * damage
    end if

  end subroutine FGM_ComputeGradientDmgVar

  subroutine FGM_ComputeGradientEnergyDen(stress, strain_elastic, strain_plastic, &
                                       damage, damage_rate, interface_damag, dt, &
                                       sse, spd, scd)
    real(wp), intent(in)  :: stress(6), strain_elastic(6), strain_plastic(6)
    real(wp), intent(in)  :: damage, damage_rate, interface_damag, dt
    real(wp), intent(out) :: sse, spd, scd

    sse = HALF * dot_product(stress, strain_elastic)
    spd = HALF * dot_product(stress, strain_plastic)
    scd = damage_rate * dt + interface_damag

  end subroutine FGM_ComputeGradientEnergyDensity

  subroutine FGM_ComputeGradientParameter(position, gradient_direct, gradient_length, &
                                  gradient_expone, gradient_type, ndim, nshr, ntens, analysis_type, gradient_parame)
    real(wp), intent(in)  :: position(3), gradient_direct(3), gradient_length
    real(wp), intent(in)  :: gradient_expone, gradient_type
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: gradient_parame

    real(wp) :: distance, direction_norm
    integer(i4) :: i

    distance = ZERO
    direction_norm = sqrt(dot_product(gradient_direct, gradient_direct))

    if (direction_norm > TOL) then
      do i = 1, min(ndim, 3)
        distance = distance + position(i) * gradient_direct(i) / direction_norm
      end do
    end if

    distance = distance / max(gradient_length, TOL)

    select case(nint(gradient_type))
      case(0)
        gradient_parame = distance
      case(1)
        gradient_parame = distance**gradient_expone
      case(2)
        gradient_parame = exp(-distance**2)
      case(3)
        gradient_parame = HALF * (ONE + tanh(distance))
      case default
        gradient_parame = distance
    end select

    gradient_parame = max(min(gradient_parame, ONE), ZERO)

  end subroutine FGM_ComputeGradientParameter

  subroutine FGM_ComputePlasticMultiplier(sigma_eqv, sigma_y, H, gradient_parame, temp_multiplier, dt, plastic_multipl)
    real(wp), intent(in)  :: sigma_eqv, sigma_y, H, gradient_parame, temp_multiplier, dt
    real(wp), intent(out) :: plastic_multipl

    real(wp) :: overstress

    plastic_multipl = ZERO

    overstress = sigma_eqv - sigma_y * temp_multiplier

    if (overstress > TOL) then
      plastic_multipl = overstress / (H * temp_multiplier + TOL) * dt * (ONE + gradient_parame)
    end if

  end subroutine FGM_ComputePlasticMultiplierGradient

  subroutine FGM_ComputePlasticStrainIncr(s_dev, plastic_multipl, ndim, nshr, ntens, analysis_type, dstra_plastic)
    real(wp), intent(in)  :: s_dev(6), plastic_multipl
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: dstra_plastic(6)

    real(wp) :: sigma_eqv
    integer(i4) :: i

    dstra_plastic = ZERO

    call FGM_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)

    if (sigma_eqv > TOL) then
      do i = 1, ntens
        dstra_plastic(i) = plastic_multipl * (THREE/TWO) * s_dev(i) / sigma_eqv
      end do
    end if

  end subroutine FGM_ComputePlasticStrainIncrGradient

  subroutine FGM_ComputeStressInvariants(stress, ndim, nshr, ntens, analysis_type, p, s_dev)
    real(wp), intent(in)  :: stress(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: p, s_dev(6)

    integer(i4) :: i

    p = ZERO
    s_dev = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) then
          p = stress(1) / THREE
          s_dev(1) = stress(1) - p
        end if
      case(2)
        if (ntens >= 2) then
          p = (stress(1) + stress(2)) / THREE
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (ntens >= 3) s_dev(3) = stress(3)
        end if
      case(3)
        if (ntens >= 3) then
          p = (stress(1) + stress(2) + stress(3)) / THREE
          do i = 1, 3
            s_dev(i) = stress(i) - p
          end do
          if (ntens >= 6) then
            do i = 4, 6
              s_dev(i) = stress(i)
            end do
          end if
        end if
    end select

  end subroutine FGM_ComputeStressInvariants

  subroutine FGM_ComputeTemperatureEffect(temp, temperature_dependence_facto, temperature_effect_multiplie)
    real(wp), intent(in)  :: temp, temperature_dependence_facto
    real(wp), intent(out) :: temperature_effect_multiplie

    temperature_effect_multiplie = ONE + temperature_dependence_facto * (temp - 300.0_wp) / 300.0_wp

  end subroutine FGM_ComputeTemperatureEffectMultiplier

  subroutine FGM_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, dT
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    integer(i4) :: i

    strain_thermal = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_thermal(1) = alpha * dT
      case(2)
        if (ntens >= 2) then
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_thermal(3) = alpha * dT
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_thermal(i) = alpha * dT
          end do
        end if
    end select

  end subroutine FGM_ComputeThermalStrain

  function FGM_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function FGM_DetectAnalysisType

  subroutine FGM_RegularizeStiffMat(D, ntens)
    real(wp), intent(inout) :: D(6,6)
    integer(i4), intent(in) :: ntens

    real(wp), parameter :: MIN_STIFFNESS = 1.0e-10_wp
    integer(i4) :: i

    do i = 1, ntens
      if (D(i,i) < MIN_STIFFNESS) then
        D(i,i) = MIN_STIFFNESS
      end if
    end do

  end subroutine FGM_RegularizeStiffMat


  subroutine U258_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)
    real(wp), intent(in)  :: PH_MAT_E, nu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_elastic(6,6)

    real(wp) :: lambda, mu

    D_elastic = ZERO

    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    select case(ndim)
      case(1)
        if (ntens >= 1) D_elastic(1,1) = PH_MAT_E
      case(2)
        if (ntens >= 2) then
          select case(analysis_type)
            case(1)
              D_elastic(1,1) = PH_MAT_E / (ONE - nu**2)
              D_elastic(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              if (ntens >= 3) D_elastic(3,3) = mu
            case(2,3)
              D_elastic(1,1) = lambda + TWO * mu
              D_elastic(1,2) = lambda
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              if (ntens >= 3) D_elastic(3,3) = mu
          end select
        end if
      case(3)
        if (ntens >= 3) then
          D_elastic(1,1) = lambda + TWO * mu
          D_elastic(1,2) = lambda
          D_elastic(1,3) = lambda
          D_elastic(2,1) = lambda
          D_elastic(2,2) = lambda + TWO * mu
          D_elastic(2,3) = lambda
          D_elastic(3,1) = lambda
          D_elastic(3,2) = lambda
          D_elastic(3,3) = lambda + TWO * mu
          if (ntens >= 6) then
            D_elastic(4,4) = mu
            D_elastic(5,5) = mu
            D_elastic(6,6) = mu
          end if
        end if
    end select

    call U258_RegularizeStiffMat(D_elastic, ntens)

  end subroutine U258_BuildElasticStiffness

  subroutine U258_ComputeEffMatPropsSmart(E_a, E_m, nu_a, nu_m, &
                                                    alpha_thermal_a, alpha_thermal_m, &
                                                    martensite_frac, &
                                                    E_effective, nu_effective, alpha_thermal_e)
    real(wp), intent(in)  :: E_a, E_m, nu_a, nu_m
    real(wp), intent(in)  :: alpha_thermal_a, alpha_thermal_m
    real(wp), intent(in)  :: martensite_frac
    real(wp), intent(out) :: E_effective, nu_effective, alpha_thermal_e

    E_effective = E_a + (E_m - E_a) * martensite_frac
    nu_effective = nu_a + (nu_m - nu_a) * martensite_frac
    alpha_thermal_e = alpha_thermal_a + (alpha_thermal_m - alpha_thermal_a) * martensite_frac

  end subroutine U258_ComputeEffMatPropsSmart

  subroutine U258_ComputeMagneticStress(B, H, ndim, nshr, ntens, analysis_type, stress_magnetic)
    real(wp), intent(in)  :: B(3), H(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_magnetic(6)

    real(wp) :: B_magnitude_sq, magnetic_pressu
    integer(i4) :: i

    stress_magnetic = ZERO

    B_magnitude_sq = dot_product(B, B)
    magnetic_pressu = B_magnitude_sq / (TWO * MU0)

    select case(ndim)
      case(1)
        if (ntens >= 1) stress_magnetic(1) = B(1)**2 / MU0 - magnetic_pressu
      case(2)
        if (ntens >= 2) then
          stress_magnetic(1) = B(1)**2 / MU0 - magnetic_pressu
          stress_magnetic(2) = B(2)**2 / MU0 - magnetic_pressu
          if (ntens >= 3) stress_magnetic(3) = B(1) * B(2) / MU0
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            stress_magnetic(i) = B(i)**2 / MU0 - magnetic_pressu
          end do
          if (ntens >= 6) then
            stress_magnetic(4) = B(2) * B(3) / MU0
            stress_magnetic(5) = B(1) * B(3) / MU0
            stress_magnetic(6) = B(1) * B(2) / MU0
          end if
        end if
    end select

  end subroutine U258_ComputeMagneticStress

  subroutine U258_ComputeMagnetization(B, H, mu_r, mu0, magnetization)
    real(wp), intent(in)  :: B(3), H(3), mu_r, mu0
    real(wp), intent(out) :: magnetization(3)

    integer(i4) :: i

    do i = 1, 3
      magnetization(i) = (B(i) / mu0) - H(i)
    end do

  end subroutine U258_ComputeMagnetization

  subroutine U258_ComputePolarization(D, E_field, epsilon_r, epsilon0, polarization)
    real(wp), intent(in)  :: D(3), E_field(3), epsilon_r, epsilon0
    real(wp), intent(out) :: polarization(3)

    integer(i4) :: i

    do i = 1, 3
      polarization(i) = D(i) - epsilon_r * epsilon0 * E_field(i)
    end do

  end subroutine U258_ComputePolarization

  subroutine U258_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, dT
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    integer(i4) :: i

    strain_thermal = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_thermal(1) = alpha * dT
      case(2)
        if (ntens >= 2) then
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_thermal(3) = alpha * dT
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_thermal(i) = alpha * dT
          end do
        end if
    end select

  end subroutine U258_ComputeThermalStrain

  function U258_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function U258_DetectAnalysisType

  subroutine U258_RegularizeStiffMat(D, ntens)
    real(wp), intent(inout) :: D(6,6)
    integer(i4), intent(in) :: ntens

    real(wp), parameter :: MIN_STIFFNESS = 1.0e-10_wp
    integer(i4) :: i

    do i = 1, ntens
      if (D(i,i) < MIN_STIFFNESS) then
        D(i,i) = MIN_STIFFNESS
      end if
    end do

  end subroutine U258_RegularizeStiffMat

  subroutine U264_build_plastic_Stiff(PH_MAT_E, nu, phi, psi, p_trial, q_trial, &
                                       delta_lambda, ndim, analysis_type, D_plastic)
    real(wp), intent(in) :: PH_MAT_E, nu, phi, psi, p_trial, q_trial, delta_lambda
    integer, intent(in) :: ndim, analysis_type
    real(wp), intent(out) :: D_plastic(6,6)

    real(wp) :: D_elastic(6,6), n_flow(6), n_yield(6)
    real(wp) :: phi_rad, psi_rad, sin_phi, sin_psi, M
    real(wp) :: dFdp, dFdq, dGdp, dGdq
    real(wp) :: H, denominator
    integer :: i, j

    call U264_build_elastic_stiffness(PH_MAT_E, nu, ndim, analysis_type, D_elastic)

    phi_rad = phi * PI / 180.0_wp
    psi_rad = psi * PI / 180.0_wp

    sin_phi = sin(phi_rad)
    sin_psi = sin(psi_rad)

    M = (SIX * sin_phi) / (THREE - sin_phi)

    dFdp = -M
    dFdq = ONE
    dGdp = -M
    dGdq = ONE

    n_flow = ZERO
    n_yield = ZERO

    n_flow(1) = dGdp / THREE
    n_flow(2) = dGdp / THREE
    n_flow(3) = dGdp / THREE

    n_yield(1) = dFdp / THREE
    n_yield(2) = dFdp / THREE
    n_yield(3) = dFdp / THREE

    H = PH_MAT_E / (ONE + nu)

    denominator = dFdp * dGdp * H + dFdq * dGdq * (TWO * U264_G_current_value(PH_MAT_E, nu))

    D_plastic = D_elastic

    do i = 1, 6
      do j = 1, 6
        D_plastic(i,j) = D_plastic(i,j) - (D_elastic(i,1) * n_flow(1) + D_elastic(i,2) * n_flow(2) + &
                                         D_elastic(i,3) * n_flow(3)) * &
                                        (D_elastic(1,j) * n_yield(1) + D_elastic(2,j) * n_yield(2) + &
                                         D_elastic(3,j) * n_yield(3)) / (denominator + REGULARIZATION)
      end do
    end do

  end subroutine U264_build_plastic_Stiff

  subroutine U264_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)
    real(wp), intent(in)  :: PH_MAT_E, nu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_elastic(6,6)

    real(wp) :: lambda, mu, factor
    integer :: i, j

    D_elastic = ZERO

    mu = PH_MAT_E / (TWO * (ONE + nu))
    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))

    select case(ndim)
      case(1)
        D_elastic(1,1) = PH_MAT_E

      case(2)
        select case(analysis_type)
          case(1)
            D_elastic(1,1) = PH_MAT_E / (ONE - nu * nu)
            D_elastic(1,2) = PH_MAT_E * nu / (ONE - nu * nu)
            D_elastic(2,1) = D_elastic(1,2)
            D_elastic(2,2) = D_elastic(1,1)
            D_elastic(3,3) = mu

          case(2,3)
            factor = PH_MAT_E / ((ONE + nu) * (ONE - TWO * nu))
            D_elastic(1,1) = factor * (ONE - nu)
            D_elastic(1,2) = factor * nu
            D_elastic(1,3) = factor * nu
            D_elastic(2,1) = D_elastic(1,2)
            D_elastic(2,2) = D_elastic(1,1)
            D_elastic(2,3) = factor * nu
            D_elastic(3,1) = D_elastic(1,3)
            D_elastic(3,2) = D_elastic(2,3)
            D_elastic(3,3) = D_elastic(1,1)
            D_elastic(4,4) = mu
            if (analysis_type == 3) then
              D_elastic(5,5) = mu
              D_elastic(6,6) = mu
            end if
        end select

      case(3)
        factor = PH_MAT_E / ((ONE + nu) * (ONE - TWO * nu))
        D_elastic(1,1) = factor * (ONE - nu)
        D_elastic(1,2) = factor * nu
        D_elastic(1,3) = factor * nu
        D_elastic(2,1) = D_elastic(1,2)
        D_elastic(2,2) = D_elastic(1,1)
        D_elastic(2,3) = factor * nu
        D_elastic(3,1) = D_elastic(1,3)
        D_elastic(3,2) = D_elastic(2,3)
        D_elastic(3,3) = D_elastic(1,1)
        D_elastic(4,4) = mu
        D_elastic(5,5) = mu
        D_elastic(6,6) = mu
    end select

  end subroutine U264_build_elastic_stiffness

  subroutine U264_Calc_stress_invariants(stress, ndim, analysis_type, p, q, eta)
    real(wp), intent(in) :: stress(6)
    integer, intent(in) :: ndim, analysis_type
    real(wp), intent(out) :: p, q, eta

    real(wp) :: s_dev(6), J2, J3

    p = ZERO
    q = ZERO
    eta = ZERO

    select case(ndim)
      case(1)
        p = stress(1) / THREE
        s_dev(1) = stress(1) - p
        J2 = HALF * s_dev(1)**2
        q = sqrt(THREE * J2)

      case(2)
        p = (stress(1) + stress(2)) / THREE
        s_dev(1) = stress(1) - p
        s_dev(2) = stress(2) - p
        s_dev(3) = stress(3) - p
        s_dev(4) = stress(3)
        J2 = HALF * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2) + s_dev(4)**2
        q = sqrt(THREE * J2)

      case(3)
        p = (stress(1) + stress(2) + stress(3)) / THREE
        s_dev(1) = stress(1) - p
        s_dev(2) = stress(2) - p
        s_dev(3) = stress(3) - p
        s_dev(4) = stress(4)
        s_dev(5) = stress(5)
        s_dev(6) = stress(6)
        J2 = HALF * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2) + s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2
        q = sqrt(THREE * J2)
    end select

    if (p > REGULARIZATION) then
      eta = q / p
    end if

  end subroutine U264_Calc_stress_invariants

  subroutine U264_ComputeEffectiveStress(stress, ndim, nshr, ntens, analysis_type, stress_effectiv)
    real(wp), intent(in)  :: stress(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_effectiv(6)

    real(wp) :: p_pore = ZERO

    stress_effectiv = stress

    select case(ndim)
      case(1)
        stress_effectiv(1) = stress(1) - p_pore
      case(2)
        stress_effectiv(1) = stress(1) - p_pore
        stress_effectiv(2) = stress(2) - p_pore
        if (analysis_type == 3) then
          stress_effectiv(3) = stress(3) - p_pore
        end if
      case(3)
        stress_effectiv(1) = stress(1) - p_pore
        stress_effectiv(2) = stress(2) - p_pore
        stress_effectiv(3) = stress(3) - p_pore
    end select

  end subroutine U264_compute_effective_stress

  subroutine U264_ComputeThermalStrain(alpha, delta_temp, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, delta_temp
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    strain_thermal = ZERO

    if (analysis_type == 1) then
      strain_thermal(1) = alpha * delta_temp
      strain_thermal(2) = alpha * delta_temp
    else if (analysis_type == 2 .or. analysis_type == 3) then
      strain_thermal(1) = alpha * delta_temp
      strain_thermal(2) = alpha * delta_temp
      strain_thermal(3) = alpha * delta_temp
    else
      strain_thermal(1) = alpha * delta_temp
      strain_thermal(2) = alpha * delta_temp
      strain_thermal(3) = alpha * delta_temp
    end if

  end subroutine U264_compute_thermal_strain

  function U264_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function U264_DetectAnalysisType

  function U264_G_current_value(PH_MAT_E, nu) result(G)
    real(wp), intent(in) :: PH_MAT_E, nu
    real(wp) :: G

    G = PH_MAT_E / (TWO * (ONE + nu))

  end function U264_G_current_value

  subroutine U264_RegularizeStiffMat(D, n)
    real(wp), intent(inout) :: D(:,:)
    integer, intent(in) :: n

    integer :: i
    real(wp) :: min_eigenvalue

    do i = 1, n
      if (D(i,i) < REGULARIZATION) then
        D(i,i) = D(i,i) + REGULARIZATION
      end if
    end do

  end subroutine U264_RegularizeStiffMat

  subroutine U264_UpdateElasticProperties(p_current, p0, E_ref, G0, m_comp, m_shear, E_current, G_current)
    real(wp), intent(in)  :: p_current, p0, E_ref, G0, m_comp, m_shear
    real(wp), intent(out) :: E_current, G_current

    real(wp) :: pressure_ratio

    pressure_ratio = p_current / (p0 + REGULARIZATION)

    E_current = E_ref * (pressure_ratio)**m_comp
    G_current = G0 * (pressure_ratio)**m_shear

  end subroutine U264_update_elastic_properties

  subroutine U2_co_cr_st_state(p, phi, psi, c, R_f, p_critical, q_critical)
    real(wp), intent(in) :: p, phi, psi, c, R_f
    real(wp), intent(out) :: p_critical, q_critical

    real(wp) :: phi_rad, psi_rad, sin_phi, sin_psi
    real(wp) :: M

    phi_rad = phi * PI / 180.0_wp
    psi_rad = psi * PI / 180.0_wp

    sin_phi = sin(phi_rad)
    sin_psi = sin(psi_rad)

    M = (SIX * sin_phi) / (THREE - sin_phi)

    p_critical = max(p, REGULARIZATION)
    q_critical = M * p_critical + (SIX * c * cos(phi_rad)) / (THREE - sin_phi)

    q_critical = q_critical * R_f

  end subroutine U264_compute_critical_stress_state

  subroutine U2_co_pl_st_increment(delta_lambda, p_trial, q_trial, phi, psi, &
                                             ndim, analysis_type, dstra_plastic, dgamma, dvol)
    real(wp), intent(in) :: delta_lambda, p_trial, q_trial, phi, psi
    integer, intent(in) :: ndim, analysis_type
    real(wp), intent(out) :: dstra_plastic(6), dgamma, dvol

    real(wp) :: s_dev(6), n_flow(6)
    real(wp) :: phi_rad, psi_rad, sin_phi, sin_psi, M
    real(wp) :: dGdp, dGdq
    integer :: i

    phi_rad = phi * PI / 180.0_wp
    psi_rad = psi * PI / 180.0_wp

    sin_phi = sin(phi_rad)
    sin_psi = sin(psi_rad)

    M = (SIX * sin_phi) / (THREE - sin_phi)

    dGdp = -M
    dGdq = ONE

    s_dev = ZERO
    select case(ndim)
      case(1)
        s_dev(1) = p_trial
      case(2)
        s_dev(1) = p_trial
        s_dev(2) = p_trial
        s_dev(3) = p_trial
        s_dev(4) = ZERO
      case(3)
        s_dev(1) = p_trial
        s_dev(2) = p_trial
        s_dev(3) = p_trial
        s_dev(4) = ZERO
        s_dev(5) = ZERO
        s_dev(6) = ZERO
    end select

    n_flow = dGdp * (ONE / THREE) + dGdq * (THREE / (TWO * q_trial + REGULARIZATION)) * s_dev

    dstra_plastic = delta_lambda * n_flow

    dvol = delta_lambda * dGdp
    dgamma = delta_lambda * dGdq

  end subroutine U264_compute_plastic_strain_increment

  subroutine U2_ComputeElectrostrictiveSt(alpha_ed, E_field, ndim, nshr, ntens, analysis_type, strain_ed)
    real(wp), intent(in)  :: alpha_ed
    real(wp), intent(in)  :: E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_ed(6)

    real(wp) :: E_magnitude_sq
    integer(i4) :: i

    strain_ed = ZERO

    E_magnitude_sq = dot_product(E_field, E_field)

    if (E_magnitude_sq > TOL) then
      select case(ndim)
        case(1)
          if (ntens >= 1) strain_ed(1) = alpha_ed * E_magnitude_sq
        case(2)
          if (ntens >= 2) then
            strain_ed(1) = alpha_ed * E_magnitude_sq
            strain_ed(2) = alpha_ed * E_magnitude_sq
            if (analysis_type == 3 .and. ntens >= 3) then
              strain_ed(3) = alpha_ed * E_magnitude_sq
            end if
          end if
        case(3)
          if (ntens >= 3) then
            do i = 1, 3
              strain_ed(i) = alpha_ed * E_magnitude_sq
            end do
          end if
      end select
    end if

  end subroutine U258_ComputeElectrostrictiveStrain

  subroutine U2_ComputeMagnetostrictionSt(alpha_magnetost, B, H, ndim, nshr, ntens, analysis_type, strain_magnetos)
    real(wp), intent(in)  :: alpha_magnetost
    real(wp), intent(in)  :: B(3), H(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_magnetos(6)

    real(wp) :: B_magnitude, H_magnitude, magnetostrictio
    integer(i4) :: i

    strain_magnetos = ZERO

    B_magnitude = sqrt(dot_product(B, B))
    H_magnitude = sqrt(dot_product(H, H))

    if (B_magnitude > TOL .and. H_magnitude > TOL) then
      magnetostrictio = alpha_magnetost * B_magnitude * H_magnitude
      select case(ndim)
        case(1)
          if (ntens >= 1) strain_magnetos(1) = magnetostrictio
        case(2)
          if (ntens >= 2) then
            strain_magnetos(1) = magnetostrictio
            strain_magnetos(2) = magnetostrictio
            if (analysis_type == 3 .and. ntens >= 3) then
              strain_magnetos(3) = magnetostrictio
            end if
          end if
        case(3)
          if (ntens >= 3) then
            do i = 1, 3
              strain_magnetos(i) = magnetostrictio
            end do
          end if
      end select
    end if

  end subroutine U258_ComputeMagnetostrictionStrain

  subroutine U2_ComputePhaseTransformatio(martensite_frac, temp, temp_old, dt, &
                                    sigma_ms, sigma_mf, sigma_as, sigma_af, &
                                    T_ms, T_mf, T_as, T_af, epsilon_L, C_M, &
                                    martensite_frac, phase_rate)
    real(wp), intent(in)  :: martensite_frac, temp, temp_old, dt
    real(wp), intent(in)  :: sigma_ms, sigma_mf, sigma_as, sigma_af
    real(wp), intent(in)  :: T_ms, T_mf, T_as, T_af, epsilon_L, C_M
    real(wp), intent(out) :: martensite_frac, phase_rate

    real(wp) :: T_effective, sigma_effective

    martensite_frac = martensite_frac
    phase_rate = ZERO

    T_effective = temp
    sigma_effective = ZERO

    if (T_effective < T_mf) then
      martensite_frac = ONE
    else if (T_effective > T_af) then
      martensite_frac = ZERO
    else if (T_effective >= T_ms .and. T_effective <= T_mf) then
      martensite_frac = ONE - (T_effective - T_ms) / (T_mf - T_ms)
    else if (T_effective >= T_as .and. T_effective <= T_af) then
      martensite_frac = (T_af - T_effective) / (T_af - T_as)
    end if

    martensite_frac = max(min(martensite_frac, ONE), ZERO)
    phase_rate = (martensite_frac - martensite_frac) / max(dt, TOL)

  end subroutine U258_ComputePhaseTransformation

  subroutine U2_ComputePiezoelectricStrai(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, strain_piezoele)
    real(wp), intent(in)  :: alpha_piezoelec(3,3), E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_piezoele(6)

    integer(i4) :: i, j

    strain_piezoele = ZERO

    do i = 1, min(ndim, 3)
      do j = 1, 3
        if (i <= ntens) then
          strain_piezoele(i) = strain_piezoele(i) + alpha_piezoelec(i,j) * E_field(j)
        end if
      end do
    end do

  end subroutine U258_ComputePiezoelectricStrain

  subroutine U2_ComputePiezoelectricStres(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, stress_piezoele)
    real(wp), intent(in)  :: alpha_piezoelec(3,3), E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_piezoele(6)

    integer(i4) :: i, j

    stress_piezoele = ZERO

    do i = 1, min(ndim, 3)
      do j = 1, 3
        if (i <= ntens) then
          stress_piezoele(i) = stress_piezoele(i) + alpha_piezoelec(i,j) * E_field(j)
        end if
      end do
    end do

  end subroutine U258_ComputePiezoelectricStress

  subroutine U2_ComputeSmartMatEnergyDens(stress, strain_elastic, strain_transfor, &
                                            strain_piezoele, strain_magnetos, strain_ed, &
                                            B, H, D, E_field, magnetization, polarization, &
                                            phase_rate, dt, &
                                            electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating)
    real(wp), intent(in)  :: stress(6), strain_elastic(6), strain_transfor(6)
    real(wp), intent(in)  :: strain_piezoele(6), strain_magnetos(6), strain_ed(6)
    real(wp), intent(in)  :: B(3), H(3), D(3), E_field(3)
    real(wp), intent(in)  :: magnetization(3), polarization(3)
    real(wp), intent(in)  :: phase_rate, dt
    real(wp), intent(out) :: electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating

    mech_energy = HALF * dot_product(stress, strain_elastic)
    electric_energy = HALF * dot_product(D, E_field)
    magnetic_energy = HALF * dot_product(B, H)
    thermal_energy = phase_rate * dt
    joule_heating = dot_product(E_field, E_field) * dt

  end subroutine U258_ComputeSmartMatEnergyDensity

  subroutine U2_ComputeTransformationStra(martensite_frac, epsilon_L, ndim, nshr, ntens, analysis_type, strain_transfor)
    real(wp), intent(in)  :: martensite_frac, epsilon_L
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_transfor(6)

    integer(i4) :: i

    strain_transfor = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_transfor(1) = martensite_frac * epsilon_L
      case(2)
        if (ntens >= 2) then
          strain_transfor(1) = martensite_frac * epsilon_L
          strain_transfor(2) = martensite_frac * epsilon_L
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_transfor(3) = martensite_frac * epsilon_L
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_transfor(i) = martensite_frac * epsilon_L
          end do
        end if
    end select

  end subroutine U258_ComputeTransformationStrain

  subroutine U2_ComputeTransformationStre(strain_transfor, D_elastic, ndim, nshr, ntens, analysis_type, stress_transfor)
    real(wp), intent(in)  :: strain_transfor(6), D_elastic(6,6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_transfor(6)

    integer(i4) :: i, j

    stress_transfor = ZERO

    do i = 1, ntens
      do j = 1, ntens
        stress_transfor(i) = stress_transfor(i) + D_elastic(i,j) * strain_transfor(j)
      end do
    end do

  end subroutine U258_ComputeTransformationStress

  subroutine U2_ge_re_mapping(stress_trial, p_trial, q_trial, p_critical, q_critical, &
                                          phi, psi, c, PH_MAT_E, nu, &
                                          ndim, analysis_type, delta_lambda, stress_effectiv)
    real(wp), intent(in) :: stress_trial(6), p_trial, q_trial, p_critical, q_critical
    real(wp), intent(in) :: phi, psi, c, PH_MAT_E, nu
    integer, intent(in) :: ndim, analysis_type
    real(wp), intent(out) :: delta_lambda, stress_effectiv(6)

    real(wp) :: s_dev(6), n_flow(6), p, q, eta
    real(wp) :: dFdp, dFdq, dGdp, dGdq
    real(wp) :: phi_rad, psi_rad, sin_phi, sin_psi, M
    real(wp) :: H, denominator
    integer :: i

    phi_rad = phi * PI / 180.0_wp
    psi_rad = psi * PI / 180.0_wp

    sin_phi = sin(phi_rad)
    sin_psi = sin(psi_rad)

    M = (SIX * sin_phi) / (THREE - sin_phi)

    call U264_Calc_stress_invariants(stress_trial, ndim, analysis_type, p, q, eta)

    dFdp = -M
    dFdq = ONE

    dGdp = -M
    dGdq = ONE

    H = PH_MAT_E / (ONE + nu)

    denominator = dFdp * dGdp * H + dFdq * dGdq * (TWO * U264_G_current_value(PH_MAT_E, nu))

    delta_lambda = (q_trial - q_critical) / (denominator + REGULARIZATION)

    s_dev = ZERO
    select case(ndim)
      case(1)
        s_dev(1) = stress_trial(1) - p
      case(2)
        s_dev(1) = stress_trial(1) - p
        s_dev(2) = stress_trial(2) - p
        s_dev(3) = stress_trial(3) - p
        s_dev(4) = stress_trial(3)
      case(3)
        s_dev(1) = stress_trial(1) - p
        s_dev(2) = stress_trial(2) - p
        s_dev(3) = stress_trial(3) - p
        s_dev(4) = stress_trial(4)
        s_dev(5) = stress_trial(5)
        s_dev(6) = stress_trial(6)
    end select

    n_flow = dGdp * (ONE / THREE) + dGdq * (THREE / (TWO * q + REGULARIZATION)) * s_dev

    stress_effectiv = stress_trial - delta_lambda * n_flow

  end subroutine U264_geoplasticity_return_mapping

  SUBROUTINE UF_FGM_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: E_min, E_max, nu_min, nu_max
    real(wp) :: K_min, K_max, G_min, G_max
    real(wp) :: sigma_y_min, sigma_y_max, H_min, H_max
    real(wp) :: alpha_thermal_m, alpha_thermal_m
    real(wp) :: gradient_direct(3), gradient_length
    real(wp) :: gradient_expone, transition_smoo
    real(wp) :: temperature_dependence_facto
    real(wp) :: residual_stress, residual_stress
    real(wp) :: interface_stren, interface_energ, gradient_type

    real(wp) :: damage_variable, position_old(3)
    real(wp) :: material_proper(10), strain_plastic(6)
    real(wp) :: temp_old, time_old, energy_density
    real(wp) :: interface_damag, residual_stress(6)

    real(wp) :: strain_total(6), strain_elastic(6)
    real(wp) :: strain_plastic(6), strain_thermal(6)
    real(wp) :: strain_residual(6), dstra_plastic(6)

    real(wp) :: stress_trial(6), stress_effectiv(6)
    real(wp) :: stress_residual(6), s_dev(6), p
    real(wp) :: sigma_eqv, sigma_mises, sigma_hydrostat

    real(wp) :: damage_variable, damage_rate, damage_factor
    real(wp) :: position(3), gradient_parame
    real(wp) :: E_effective, nu_effective, K_effective, G_effective
    real(wp) :: sigma_y_effecti, H_effective, alpha_thermal_e
    real(wp) :: residual_stress(6)
    real(wp) :: temperature_effect_multiplie
    real(wp) :: interface_damag, interface_stres

    real(wp) :: D_elastic(6,6), D_plastic(6,6)
    real(wp) :: D_damaged(6,6), D_coupled(6,6)

    integer(i4) :: analysis_type, i, j, ntens
    real(wp) :: dt, strain_magnitud, plastic_multipl

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    !-------------------------------------------------------------------
    ! Determine Tensor Dimension
    !-------------------------------------------------------------------
    ntens = ndir + nshr

    !-------------------------------------------------------------------
    ! Valid Mat Parameters
    !-------------------------------------------------------------------
    if (nprops < 26) then
            CALL log_error('MD_MatLib_Plastic_FGM', 'Insufficient Mat parameters')
      status%status_code = IF_STATUS_INVALID
      RETURN
        end if

    E_min = props(1)
    E_max = props(2)
    nu_min = props(3)
    nu_max = props(4)
    K_min = props(5)
    K_max = props(6)
    G_min = props(7)
    G_max = props(8)
    sigma_y_min = props(9)
    sigma_y_max = props(10)
    H_min = props(11)
    H_max = props(12)
    alpha_thermal_m = props(13)
    alpha_thermal_m = props(14)
    gradient_direct(1) = props(15)
    gradient_direct(2) = props(16)
    gradient_direct(3) = props(17)
    gradient_length = props(18)
    gradient_expone = props(19)
    transition_smoo = props(20)
    temperature_dependence_facto = props(21)
    residual_stress = props(22)
    residual_stress = props(23)
    interface_stren = props(24)
    interface_energ = props(25)
    gradient_type = props(26)

    if (E_min <= ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'E_min must be greater than 0')
      return
      return
    end if

    if (E_max < E_min) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'E_max must be non-negative')
      return
      return
    end if

    if (nu_min < -ONE .or. nu_min >= HALF) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'nu_min must be in range [-1, 0.5)')
      return
    end if

    if (nu_max < -ONE .or. nu_max >= HALF) then
      call log_error('MD_MatLib_Plastic_FGM', 'nu_max must be in [-1, 0.5)')
      return
    end if

    if (K_min <= ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'K_min must be greater than 0')
      return
      return
    end if

    if (K_max < K_min) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'K_max must be non-negative')
      return
      return
    end if

    if (G_min <= ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'G_min must be greater than 0')
      return
      return
    end if

    if (G_max < G_min) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'G_max must be non-negative')
      return
      return
    end if

    if (sigma_y_min < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'sigma_y_min must be non-negative')
      return
      return
    end if

    if (sigma_y_max < sigma_y_min) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'sigma_y_max must be non-negative')
      return
      return
    end if

    if (H_min < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'H_min must be non-negative')
      return
      return
    end if

    if (H_max < H_min) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'H_max must be non-negative')
      return
      return
    end if

    if (alpha_thermal_m < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'alpha_thermal_m must be non-negative')
      return
      return
    end if

    if (alpha_thermal_m < alpha_thermal_m) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'alpha_thermal_m must be non-negative')
      return
      return
    end if

    if (gradient_length <= ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'gradient_length must be greater than 0')
      return
      return
    end if

    if (gradient_expone < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'gradient_expone must be non-negative')
      return
      return
    end if

    if (transition_smoo < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'transition_smoo must be non-negative')
      return
      return
    end if

    if (temperature_dependence_facto < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'temperature_dependence_facto must be non-negative')
      return
      return
    end if

    if (residual_stress < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'residual_stress must be non-negative')
      return
      return
    end if

    if (residual_stress < residual_stress) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'residual_stress must be non-negative')
      return
      return
    end if

    if (interface_stren < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'interface_stren must be non-negative')
      return
      return
    end if

    if (interface_energ < ZERO) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'interface_energ must be non-negative')
      return
      return
    end if

    if (gradient_type < ZERO .or. gradient_type > THREE) then
            call log_error('MD_MaterialLib_Plastic_Core::PH_MAT_UMAT_257', 'gradient_type must be in range [0, 3]')
      return
    end if

    !-------------------------------------------------------------------
    ! Determine Analysis Type
    !-------------------------------------------------------------------
    analysis_type = FGM_DetectAnalysisType(ndim, nshr)

    damage_variable = ZERO
    position_old = ZERO
    material_proper = ZERO
    strain_plastic = ZERO
    temp_old = 300.0_wp
    time_old = time(1) - dtime
    energy_density = ZERO
    interface_damag = ZERO
    residual_stress = ZERO

    if (nstatv >= 2) damage_variable = statev(2)
    if (nstatv >= 5) then
      do i = 1, 3
        if (2 + i <= nstatv) then
          position_old(i) = statev(2 + i)
        end if
      end do
    end if
    if (nstatv >= 15) then
      do i = 1, 10
        if (5 + i <= nstatv) then
          material_proper(i) = statev(5 + i)
        end if
      end do
    end if
    if (nstatv >= 21) then
      do i = 1, 6
        if (15 + i <= nstatv) then
          strain_plastic(i) = statev(15 + i)
        end if
      end do
    end if
    if (nstatv >= 22) temp_old = statev(22)
    if (nstatv >= 23) time_old = statev(23)
    if (nstatv >= 24) energy_density = statev(24)
    if (nstatv >= 25) interface_damag = statev(25)
    if (nstatv >= 31) then
      do i = 1, 6
        if (25 + i <= nstatv) then
          residual_stress(i) = statev(25 + i)
        end if
      end do
    end if

    dt = time(1) - time_old
    if (dt < ZERO) dt = dtime

    position = coords

    call FGM_ComputeGradientParameter(position, gradient_direct, gradient_length, &
                                  gradient_expone, gradient_type, ndim, nshr, ntens, analysis_type, gradient_parame)

    call FGM_ComputeEffMatPropsGradient(E_min, E_max, nu_min, nu_max, &
                                                     K_min, K_max, G_min, G_max, &
                                                     sigma_y_min, sigma_y_max, H_min, H_max, &
                                                     alpha_thermal_m, alpha_thermal_m, &
                                                     residual_stress, residual_stress, &
                                                     gradient_parame, transition_smoo, &
                                                     E_effective, nu_effective, K_effective, G_effective, &
                                                     sigma_y_effecti, H_effective, alpha_thermal_e, &
                                                     residual_stress)

    call FGM_ComputeTemperatureEffectMultiplier(temp, temperature_dependence_facto, temperature_effect_multiplie)

    strain_total = stran + dstran

    call FGM_ComputeThermalStrain(alpha_thermal_e, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)

    strain_plastic = strain_plastic
    do i = 1, ntens
      strain_residual(i) = residual_stress(i) / E_effective
      strain_elastic(i) = strain_total(i) - strain_plastic(i) - strain_thermal(i) - strain_residual(i)
    end do

    call FGM_BuildElasticStiffness(E_effective, nu_effective, K_effective, G_effective, ndim, nshr, ntens, analysis_type, D_elastic)

    stress_trial = ZERO
    do i = 1, 6
      do j = 1, 6
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
      end do
    end do

    stress_residual = residual_stress

    call FGM_ComputeStressInvariants(stress_trial, ndim, nshr, ntens, analysis_type, p, s_dev)
    call FGM_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)

    call FGM_ComputePlasticMultiplierGradient(sigma_eqv, sigma_y_effecti, H_effective, &
                                          gradient_parame, temperature_effect_multiplie, &
                                          dt, plastic_multipl)

    if (plastic_multipl > TOL) then
      call FGM_ComputePlasticStrainIncrGradient(s_dev, plastic_multipl, ndim, nshr, ntens, analysis_type, dstra_plastic)

      strain_plastic = strain_plastic + dstra_plastic

      strain_elastic = strain_elastic - dstra_plastic

      stress_trial = ZERO
      do i = 1, 6
        do j = 1, 6
          stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
        end do
      end do
    end if

    stress_effectiv = stress_trial + stress_residual

    call FGM_ComputeGradientDmgVar(stress_effectiv, sigma_eqv, gradient_parame, &
                                         interface_stren, interface_energ, &
                                         damage_variable, dt, &
                                         damage_variable, damage_rate, interface_damag)

    damage_factor = ONE - damage_variable
    do i = 1, ntens
      stress_effectiv(i) = stress_effectiv(i) * damage_factor
    end do

    call FGM_BuildDmgdStiffMat(D_elastic, damage_variable, damage_factor, ndim, nshr, ntens, analysis_type, D_damaged)

    call FGM_BuildPlasticStiffMatGradient(D_elastic, plastic_multipl, gradient_parame, ndim, nshr, ntens, analysis_type, D_plastic)

    D_coupled = D_damaged + D_plastic

    call FGM_ComputeGradientEnergyDensity(stress_effectiv, strain_elastic, strain_plastic, &
                                       damage_variable, damage_rate, interface_damag, dt, &
                                       sse, spd, scd)

    stress = stress_effectiv
    ddsdde = D_coupled

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 2) statev(2) = damage_variable
    if (nstatv >= 5) then
      do i = 1, 3
        if (2 + i <= nstatv) then
          statev(2 + i) = position(i)
        end if
      end do
    end if
    if (nstatv >= 15) then
      do i = 1, 10
        if (5 + i <= nstatv) then
          statev(5 + i) = material_proper(i)
        end if
      end do
    end if
    if (nstatv >= 21) then
      do i = 1, 6
        if (15 + i <= nstatv) then
          statev(15 + i) = strain_plastic(i)
        end if
      end do
    end if
    if (nstatv >= 22) statev(22) = temp
    if (nstatv >= 23) statev(23) = time(1)
    if (nstatv >= 24) statev(24) = sse + spd + scd
    if (nstatv >= 25) statev(25) = interface_damag
    if (nstatv >= 31) then
      do i = 1, 6
        if (25 + i <= nstatv) then
          statev(25 + i) = residual_stress(i)
        end if
      end do
    end if

  contains

    function FGM_detect_analysis_type(ndim, nshr) result(analysis_type)
      integer, intent(in) :: ndim, nshr
      integer :: analysis_type

      select case(ndim)
        case(1)
          analysis_type = 0
        case(2)
          if (nshr == 1) then
            analysis_type = 2
          else
            analysis_type = 1
          end if
        case(3)
          analysis_type = 0
        case default
          analysis_type = 0
      end select

    end function FGM_detect_analysis_type

    subroutine FGM_Calc_gradient_Param(position, gradient_direct, gradient_length, &
                                        gradient_expone, gradient_type, gradient_parame)
      real(wp), intent(in)  :: position(3), gradient_direct(3)
      real(wp), intent(in)  :: gradient_length, gradient_expone
      integer, intent(in)  :: gradient_type
      real(wp), intent(out) :: gradient_parame

      real(wp) :: normalized_posi, direction_magni

      direction_magni = sqrt(dot_product(gradient_direct, gradient_direct))
      if (direction_magni < 1.0e-10_wp) then
        gradient_parame = ZERO
        return
      end if

      normalized_posi = dot_product(position, gradient_direct) / direction_magni / gradient_length

      select case(nint(gradient_type))
        case(0)
          gradient_parame = normalized_posi
        case(1)
          gradient_parame = ONE - exp(-gradient_expone * normalized_posi)
        case(2)
          gradient_parame = normalized_posi**gradient_expone
        case(3)
          gradient_parame = HALF * (ONE - cos(PI * normalized_posi))
        case default
          gradient_parame = normalized_posi
      end select

      gradient_parame = max(min(gradient_parame, ONE), ZERO)

    end subroutine FGM_Calc_gradient_Param

    subroutine FGM_co_ef_mat_pr_gradient(E_min, E_max, nu_min, nu_max, &
                                                             K_min, K_max, G_min, G_max, &
                                                             sigma_y_min, sigma_y_max, H_min, H_max, &
                                                             alpha_thermal_m, alpha_thermal_m, &
                                                             residual_stress, residual_stress, &
                                                             gradient_parame, transition_smoo, &
                                                             E_effective, nu_effective, K_effective, G_effective, &
                                                             sigma_y_effecti, H_effective, alpha_thermal_e, &
                                                             residual_stress)
      real(wp), intent(in)  :: E_min, E_max, nu_min, nu_max
      real(wp), intent(in)  :: K_min, K_max, G_min, G_max
      real(wp), intent(in)  :: sigma_y_min, sigma_y_max, H_min, H_max
      real(wp), intent(in)  :: alpha_thermal_m, alpha_thermal_m
      real(wp), intent(in)  :: residual_stress, residual_stress
      real(wp), intent(in)  :: gradient_parame, transition_smoo
      real(wp), intent(out) :: E_effective, nu_effective, K_effective, G_effective
      real(wp), intent(out) :: sigma_y_effecti, H_effective, alpha_thermal_e
      real(wp), intent(out) :: residual_stress(6)

      real(wp) :: smoothed_parame
      integer :: i

      smoothed_parame = gradient_parame

      if (transition_smoo > ZERO) then
        smoothed_parame = (ONE - exp(-transition_smoo * gradient_parame)) / &
                           (ONE - exp(-transition_smoo))
      end if

      E_effective = E_min + (E_max - E_min) * smoothed_parame
      nu_effective = nu_min + (nu_max - nu_min) * smoothed_parame
      K_effective = K_min + (K_max - K_min) * smoothed_parame
      G_effective = G_min + (G_max - G_min) * smoothed_parame
      sigma_y_effecti = sigma_y_min + (sigma_y_max - sigma_y_min) * smoothed_parame
      H_effective = H_min + (H_max - H_min) * smoothed_parame
      alpha_thermal_e = alpha_thermal_m + (alpha_thermal_m - alpha_thermal_m) * smoothed_parame

      do i = 1, 6
        residual_stress(i) = residual_stress + (residual_stress - residual_stress) * smoothed_parame
      end do

    end subroutine FGM_compute_effective_material_properties_gradient

    subroutine FGM_co_te_ef_multiplier(temp, temperature_dependence_facto, temperature_effect_multiplie)
      real(wp), intent(in)  :: temp, temperature_dependence_facto
      real(wp), intent(out) :: temperature_effect_multiplie

      temperature_effect_multiplie = exp(-temperature_dependence_facto * (temp - 300.0_wp) / 300.0_wp)

    end subroutine FGM_compute_temperature_effect_multiplier

    subroutine FGM_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)
      real(wp), intent(in)  :: alpha, dT
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: strain_thermal(6)

      strain_thermal = ZERO

      select case(ndim)
        case(1)
          strain_thermal(1) = alpha * dT
        case(2)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3) then
            strain_thermal(3) = alpha * dT
          end if
        case(3)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          strain_thermal(3) = alpha * dT
      end select

    end subroutine FGM_Calc_thermal_strain

    subroutine FGM_build_elastic_Stiff(PH_MAT_E, nu, K, G, ndim, analysis_type, D_elastic)
      real(wp), intent(in)  :: PH_MAT_E, nu, K, G
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: D_elastic(6,6)

      real(wp) :: lambda, mu

      D_elastic = ZERO

      lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
      mu = PH_MAT_E / (TWO * (ONE + nu))

      select case(ndim)
        case(1)
          D_elastic(1,1) = PH_MAT_E
        case(2)
          select case(analysis_type)
            case(1)
              D_elastic(1,1) = PH_MAT_E / (ONE - nu**2)
              D_elastic(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              D_elastic(3,3) = G
            case(2,3)
              D_elastic(1,1) = lambda + TWO * mu
              D_elastic(1,2) = lambda
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              D_elastic(3,3) = mu
              if (analysis_type == 3) then
                D_elastic(1,3) = lambda
                D_elastic(3,1) = lambda
                D_elastic(2,3) = lambda
                D_elastic(3,2) = lambda
                D_elastic(3,3) = D_elastic(1,1)
              end if
          end select
        case(3)
          D_elastic(1,1) = lambda + TWO * mu
          D_elastic(1,2) = lambda
          D_elastic(1,3) = lambda
          D_elastic(2,1) = lambda
          D_elastic(2,2) = lambda + TWO * mu
          D_elastic(2,3) = lambda
          D_elastic(3,1) = lambda
          D_elastic(3,2) = lambda
          D_elastic(3,3) = lambda + TWO * mu
          D_elastic(4,4) = mu
          D_elastic(5,5) = mu
          D_elastic(6,6) = mu
      end select

      call FGM_regularize_Stiff_Mtx(D_elastic)

    end subroutine FGM_build_elastic_Stiff

    subroutine FGM_Calc_stress_invariants(stress, ndim, analysis_type, p, s_dev, p_out)
      real(wp), intent(in)  :: stress(6)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: p, s_dev(6), p_out

      s_dev = stress

      select case(ndim)
        case(1)
          p = stress(1) / THREE
        case(2)
          p = (stress(1) + stress(2)) / THREE
          if (analysis_type == 3) then
            p = (stress(1) + stress(2) + stress(3)) / THREE
          end if
        case(3)
          p = (stress(1) + stress(2) + stress(3)) / THREE
      end select

      p_out = p

      select case(ndim)
        case(1)
          s_dev(1) = stress(1) - p
        case(2)
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (analysis_type == 3) then
            s_dev(3) = stress(3) - p
          end if
        case(3)
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          s_dev(3) = stress(3) - p
      end select

    end subroutine FGM_Calc_stress_invariants

    subroutine FGM_Calc_equivalent_stress(s_dev, ndim, analysis_type, sigma_eqv)
      real(wp), intent(in)  :: s_dev(6)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: sigma_eqv

      sigma_eqv = ZERO

      select case(ndim)
        case(1)
          sigma_eqv = abs(s_dev(1))
        case(2)
          sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 - s_dev(1)*s_dev(2) + THREE*s_dev(3)**2))
        case(3)
          sigma_eqv = sqrt(1.5_wp * ((s_dev(1)-s_dev(2))**2 + (s_dev(2)-s_dev(3))**2 + (s_dev(3)-s_dev(1))**2 + &
                                    SIX*(s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
      end select

    end subroutine FGM_Calc_equivalent_stress

    subroutine FGM_co_pl_mu_gradient(sigma_eqv, sigma_y, H, gradient_parame, temp_multiplier, dt, plastic_multipl)
      real(wp), intent(in)  :: sigma_eqv, sigma_y, H, gradient_parame, temp_multiplier, dt
      real(wp), intent(out) :: plastic_multipl

      real(wp) :: overstress

      plastic_multipl = ZERO

      overstress = sigma_eqv - sigma_y

      if (overstress > ZERO) then
        plastic_multipl = overstress / (H + 1000.0_wp) * temp_multiplier * dt
      end if

    end subroutine FGM_compute_plastic_multiplier_gradient

    subroutine FGM_co_pl_st_in_gradient(s_dev, plastic_multipl, ndim, analysis_type, dstra_plastic)
      real(wp), intent(in)  :: s_dev(6), plastic_multipl
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: dstra_plastic(6)

      real(wp) :: sigma_eqv, norm_factor

      dstra_plastic = ZERO

      if (plastic_multipl < 1.0e-10_wp) return

      call FGM_Calc_equivalent_stress(s_dev, ndim, analysis_type, sigma_eqv)

      if (sigma_eqv < 1.0e-10_wp) return

      norm_factor = (TWO/THREE) * plastic_multipl / sigma_eqv

      dstra_plastic = s_dev * norm_factor

    end subroutine FGM_compute_plastic_strain_increment_gradient

    subroutine FGM_co_gr_da_var(stress, sigma_eqv, gradient_parame, interface_stren, interface_energ, damage_old, dt, damage, damage_rate, interface_damag)
      real(wp), intent(in)    :: stress(6), sigma_eqv, gradient_parame
      real(wp), intent(in)    :: interface_stren, interface_energ, damage_old, dt
      real(wp), intent(out)   :: damage, damage_rate, interface_damag

      real(wp) :: stress_magnitud, damage_driving

      damage = damage_old
      damage_rate = ZERO
      interface_damag = ZERO

      stress_magnitud = sqrt(dot_product(stress, stress))

      damage_driving = stress_magnitud / interface_stren

      if (damage_driving > ONE) then
        interface_damag = (damage_driving - ONE) * 0.1_wp
        damage_rate = interface_damag * gradient_parame / dt
        damage = damage_old + damage_rate * dt
        damage = min(damage, ONE)
      end if

    end subroutine FGM_compute_gradient_damage_variable

    subroutine FGM_build_damaged_Stiff_Mtx(D_elastic, damage, damage_factor, ndim, analysis_type, D_damaged)
      real(wp), intent(in)  :: D_elastic(6,6), damage, damage_factor
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: D_damaged(6,6)
      integer :: i, j

      D_damaged = D_elastic

      do i = 1, 6
        do j = 1, 6
          D_damaged(i,j) = D_damaged(i,j) * damage_factor
        end do
      end do

      call FGM_regularize_Stiff_Mtx(D_damaged)

    end subroutine FGM_build_damaged_Stiff_Mtx

    subroutine FGM_bu_pl_st_mtx_gradient(D_elastic, plastic_multipl, gradient_parame, ndim, analysis_type, D_plastic)
      real(wp), intent(in)  :: D_elastic(6,6), plastic_multipl, gradient_parame
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: D_plastic(6,6)
      integer :: i

      D_plastic = ZERO

      if (plastic_multipl > 1.0e-10_wp) then
        do i = 1, 6
          D_plastic(i,i) = D_elastic(i,i) * plastic_multipl * gradient_parame
        end do
      end if

    end subroutine FGM_build_plastic_stiffness_matrix_gradient

    subroutine FGM_co_gr_en_density(stress, strain_elastic, strain_plastic, damage, damage_rate, interface_damag, dt, sse, spd, scd)
      real(wp), intent(in)  :: stress(6), strain_elastic(6), strain_plastic(6), damage, damage_rate, interface_damag, dt
      real(wp), intent(out) :: sse, spd, scd

      sse = HALF * dot_product(stress, strain_elastic)
      spd = HALF * dot_product(stress, strain_plastic)
      scd = damage_rate * dt + interface_damag * dt

    end subroutine FGM_compute_gradient_energy_density

    subroutine FGM_regularize_Stiff_Mtx(D)
      real(wp), intent(inout) :: D(6,6)
      integer :: i

      do i = 1, 6
        if (D(i,i) < REGULARIZATION) then
          D(i,i) = REGULARIZATION
        end if
      end do

    end subroutine FGM_regularize_Stiff_Mtx

  END SUBROUTINE UF_FGM_UMAT

  SUBROUTINE UF_Geotechnical_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: K0, phi, psi, c
    real(wp) :: E_ref, nu
    real(wp) :: R_f, G0
    real(wp) :: m_comp, m_shear
    real(wp) :: gamma_ref
    real(wp) :: alpha_thermal

    real(wp) :: p0, e0, e_current
    real(wp) :: p_current, q_current, eta_current
    real(wp) :: alpha_current
    real(wp) :: E_current, G_current
    real(wp) :: strain_volumetr, strain_shear
    real(wp) :: temp_old

    real(wp) :: strain_total(6), strain_elastic(6)
    real(wp) :: strain_plastic(6), strain_thermal(6)
    real(wp) :: dstra_plastic(6)

    real(wp) :: stress_trial(6), stress_effectiv(6)
    real(wp) :: p_trial, q_trial, eta_trial
    real(wp) :: p_critical, q_critical

    real(wp) :: D_elastic(6,6), D_plastic(6,6)

    integer(i4) :: analysis_type, i, j, ntens
    real(wp) :: delta_lambda, dgamma, dvol
    real(wp) :: F, dFdp, dFdq
    real(wp) :: dGdp, dGdq

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    !-------------------------------------------------------------------
    ! Determine Tensor Dimension
    !-------------------------------------------------------------------
    ntens = ndir + nshr

    !-------------------------------------------------------------------
    ! Valid Mat Parameters
    !-------------------------------------------------------------------
    if (nprops < 12) then
            CALL log_error('MD_MatLib_Plastic_Geotechnical', 'Insufficient Mat parameters')
      status%status_code = IF_STATUS_INVALID
      RETURN
        end if

    K0 = props(1)
    phi = props(2)
    psi = props(3)
    c = props(4)
    E_ref = props(5)
    nu = props(6)
    R_f = props(7)
    G0 = props(8)
    m_comp = props(9)
    m_shear = props(10)
    gamma_ref = props(11)
    alpha_thermal = props(12)

    if (K0 < ZERO .or. K0 > THREE) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'K0 must be in range [0, 3]')
      return
    end if

    if (phi < ZERO .or. phi > 45.0_wp) then
      call log_error('MD_MatLib_Plastic_Geotechnical', 'phi must be in [0, 45]')
      return
    end if

    if (psi < -15.0_wp .or. psi > 30.0_wp) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'psi must be non-negative')
      return
      return
    end if

    if (c < ZERO) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'c must be non-negative')
      return
      return
    end if

    if (E_ref <= ZERO) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'E_ref must be greater than 0')
      return
      return
    end if

    if (nu < ZERO .or. nu >= HALF) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'nu must be in range [0, 0.5)')
      return
    end if

    if (R_f <= ZERO .or. R_f > ONE) then
      call log_error('MD_MatLib_Plastic_Geotechnical', 'R_f must be in (0, 1]')
      return
    end if

    if (G0 <= ZERO) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'G0 must be greater than 0')
      return
      return
    end if

    if (m_comp < ZERO) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'm_comp must be non-negative')
      return
      return
    end if

    if (m_shear < ZERO) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'm_shear must be non-negative')
      return
      return
    end if

    if (gamma_ref <= ZERO) then
            call log_error('MD_MatLib_Plastic_Geotechnical', 'gamma_ref must be greater than 0')
      return
      return
    end if

    !-------------------------------------------------------------------
    ! Determine Analysis Type
    !-------------------------------------------------------------------
    analysis_type = U264_DetectAnalysisType(ndim, nshr)

    ndim = ndi

    p0 = 100.0_wp
    e0 = 0.8_wp
    e_current = e0
    p_current = p0
    q_current = ZERO
    eta_current = ZERO
    alpha_current = ZERO
    E_current = E_ref
    G_current = G0
    strain_volumetr = ZERO
    strain_shear = ZERO
    temp_old = 293.15_wp
    strain_plastic = ZERO

    if (nstatv >= 2) p_current = statev(2)
    if (nstatv >= 3) q_current = statev(3)
    if (nstatv >= 4) e_current = statev(4)
    if (nstatv >= 5) alpha_current = statev(5)
    if (nstatv >= 6) E_current = statev(6)
    if (nstatv >= 7) G_current = statev(7)
    if (nstatv >= 8) strain_volumetr = statev(8)
    if (nstatv >= 9) strain_shear = statev(9)
    if (nstatv >= 10) temp_old = statev(10)

    if (nstatv >= 16) then
      do i = 1, 6
        if (10 + i <= nstatv) then
          strain_plastic(i) = statev(10 + i)
        end if
      end do
    end if

    strain_total = stran + dstran

    call U264_ComputeThermalStrain(alpha_thermal, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)

    call U264_ComputeEffectiveStress(stress, ndim, nshr, ntens, analysis_type, stress_effectiv)

    call ComputeStressInvariants(stress_effectiv, ndim, nshr, ntens, analysis_type, p_current, q_current, eta_current)

    call U264_UpdateElasticProperties(p_current, p0, E_ref, G0, m_comp, m_shear, E_current, G_current)

    call U264_BuildElasticStiffness(E_current, nu, ndim, nshr, ntens, analysis_type, D_elastic)

    do i = 1, ntens
      strain_elastic(i) = strain_total(i) - strain_plastic(i) - strain_thermal(i)
    end do

    stress_trial = ZERO
    do i = 1, 6
      do j = 1, 6
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
      end do
    end do

    call ComputeStressInvariants(stress_trial, ndim, nshr, ntens, analysis_type, p_trial, q_trial, eta_trial)

    call ComputeCriticalStressState(p_trial, phi, psi, c, R_f, p_critical, q_critical)

    if (q_trial > q_critical - TOL) then
      call GeoplasticityReturnMapping(stress_trial, p_trial, q_trial, p_critical, q_critical, &
                                        phi, psi, c, E_current, nu, &
                                        ndim, nshr, ntens, analysis_type, delta_lambda, stress_effectiv)

      call ComputePlasticStrainIncrement(delta_lambda, p_trial, q_trial, phi, psi, &
                                           ndim, nshr, ntens, analysis_type, dstra_plastic, dgamma, dvol)

      strain_plastic = strain_plastic + dstra_plastic

      strain_volumetr = strain_volumetr + dvol
      strain_shear = strain_shear + dgamma

      e_current = e0 * exp(-strain_volumetr)

      call BuildPlasticStiffness(E_current, nu, phi, psi, p_trial, q_trial, &
                                   delta_lambda, ndim, nshr, ntens, analysis_type, D_plastic)

      stress = stress_effectiv
      ddsdde = D_plastic

      do i = 1, ntens
        spd = spd + HALF * (stress_trial(i) + stress_effectiv(i)) * dstra_plastic(i)
      end do
    else
      stress = stress_trial
      ddsdde = D_elastic
    end if

    sse = HALF * dot_product(stress, strain_elastic)

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 2) statev(2) = p_current
    if (nstatv >= 3) statev(3) = q_current
    if (nstatv >= 4) statev(4) = e_current
    if (nstatv >= 5) statev(5) = alpha_current
    if (nstatv >= 6) statev(6) = E_current
    if (nstatv >= 7) statev(7) = G_current
    if (nstatv >= 8) statev(8) = strain_volumetr
    if (nstatv >= 9) statev(9) = strain_shear
    if (nstatv >= 10) statev(10) = temp

    if (nstatv >= 16) then
      do i = 1, 6
        if (10 + i <= nstatv) then
          statev(10 + i) = strain_plastic(i)
        end if
      end do
    end if

    call U264_RegularizeStiffMat(ddsdde, ntens)

  END SUBROUTINE UF_Geotechnical_UMAT


  SUBROUTINE UF_SmartMaterial_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: E_a, E_m, nu_a, nu_m
    real(wp) :: sigma_ms, sigma_mf, sigma_as, sigma_af
    real(wp) :: T_ms, T_mf, T_as, T_af
    real(wp) :: epsilon_L, C_M
    real(wp) :: alpha_thermal_a, alpha_thermal_m
    real(wp) :: alpha_magnetost, Q_THERMOELECTRI
    real(wp) :: S_THERMOMAGNETI, alpha_ed, mu_r, epsilon_r
    real(wp) :: alpha_piezoelec(3,3)

    real(wp) :: martensite_volume_fraction_o
    real(wp) :: strain_plastic(6), B_old(3), H_old(3)
    real(wp) :: D_old(3), E_field_old(3)
    real(wp) :: temp_old, time_old
    real(wp) :: magnetization_o(3), polarization_ol(3)
    real(wp) :: energy_density

    real(wp) :: B(3), H(3), D(3), E_field(3)
    real(wp) :: dB(3), dH(3), dD(3), dE_field(3)
    real(wp) :: magnetization(3), polarization(3)

    real(wp) :: strain_total(6), strain_elastic(6)
    real(wp) :: strain_transfor(6), strain_piezoele(6)
    real(wp) :: strain_magnetos(6), strain_ed(6)
    real(wp) :: strain_thermal(6), strain_plastic(6)
    real(wp) :: dstra_plastic(6)

    real(wp) :: stress_trial(6), stress_effectiv(6)
    real(wp) :: stress_transfor(6), stress_piezoele(6)
    real(wp) :: stress_magnetic(6), s_dev(6), p

    real(wp) :: martensite_volu, phase_transform
    real(wp) :: E_effective, nu_effective, alpha_thermal_e

    real(wp) :: D_elastic(6,6), D_TRANSFORMATIO(6,6)
    real(wp) :: D_piezoelectric(6,6), D_magnetic(6,6)
    real(wp) :: D_coupled(6,6)

    integer(i4) :: analysis_type, i, j, ntens
    real(wp) :: dt, electric_energy, magnetic_energy
    real(wp) :: thermal_energy, mech_energy, joule_heating

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    if (nprops < 22) then
      call log_error('MD_MatLib_Plastic_SmartMaterial', 'Insufficient props for shape memory alloy')
      return
    end if

    E_a = props(1)
    E_m = props(2)
    nu_a = props(3)
    nu_m = props(4)
    sigma_ms = props(5)
    sigma_mf = props(6)
    sigma_as = props(7)
    sigma_af = props(8)
    T_ms = props(9)
    T_mf = props(10)
    T_as = props(11)
    T_af = props(12)
    epsilon_L = props(13)
    C_M = props(14)
    alpha_thermal_a = props(15)
    alpha_thermal_m = props(16)
    alpha_magnetost = props(17)
    Q_THERMOELECTRI = props(18)
    S_THERMOMAGNETI = props(19)
    alpha_ed = props(20)
    mu_r = props(21)
    epsilon_r = props(22)

    alpha_piezoelec = ZERO
    if (nprops >= 31) then
      do i = 1, 3
        do j = 1, 3
          if (22 + (i-1)*3 + j <= nprops) then
            alpha_piezoelec(i,j) = props(22 + (i-1)*3 + j)
          end if
        end do
      end do
    end if

    if (E_a <= ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'E_a must be greater than 0')
      return
      return
    end if

    if (E_m <= ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'E_m must be greater than 0')
      return
      return
    end if

    if (nu_a < -ONE .or. nu_a >= HALF) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'nu_a must be in range [-1, 0.5)')
      return
    end if

    if (nu_m < -ONE .or. nu_m >= HALF) then
      call log_error('MD_MatLib_Plastic_SmartMaterial', 'nu_m must be in [-1, 0.5)')
      return
    end if

    if (sigma_ms < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'sigma_ms must be non-negative')
      return
      return
    end if

    if (sigma_mf < sigma_ms) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'sigma_mf must be non-negative')
      return
      return
    end if

    if (sigma_as < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'sigma_as must be non-negative')
      return
      return
    end if

    if (sigma_af < sigma_as) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'sigma_af must be non-negative')
      return
      return
    end if

    if (epsilon_L < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'epsilon_L must be non-negative')
      return
      return
    end if

    if (C_M < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'C_M must be non-negative')
      return
      return
    end if

    if (alpha_thermal_a < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'alpha_thermal_a must be non-negative')
      return
      return
    end if

    if (alpha_thermal_m < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'alpha_thermal_m must be non-negative')
      return
      return
    end if

    if (mu_r < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'mu_r must be non-negative')
      return
      return
    end if

    if (epsilon_r < ZERO) then
            call log_error('MD_MatLib_Plastic_SmartMaterial', 'epsilon_r must be non-negative')
      return
      return
    end if

    !-------------------------------------------------------------------
    ! Determine Analysis Type
    !-------------------------------------------------------------------
    analysis_type = U258_DetectAnalysisType(ndim, nshr)

    martensite_volume_fraction_o = ZERO
    strain_plastic = ZERO
    B_old = ZERO
    H_old = ZERO
    D_old = ZERO
    E_field_old = ZERO
    temp_old = 300.0_wp
    time_old = time(1) - dtime
    magnetization_o = ZERO
    polarization_ol = ZERO
    energy_density = ZERO

    if (nstatv >= 2) martensite_volume_fraction_o = statev(2)
    if (nstatv >= 8) then
      do i = 1, 6
        if (2 + i <= nstatv) then
          strain_plastic(i) = statev(2 + i)
        end if
      end do
    end if
    if (nstatv >= 11) then
      do i = 1, 3
        if (8 + i <= nstatv) then
          B_old(i) = statev(8 + i)
        end if
      end do
    end if
    if (nstatv >= 14) then
      do i = 1, 3
        if (11 + i <= nstatv) then
          H_old(i) = statev(11 + i)
        end if
      end do
    end if
    if (nstatv >= 17) then
      do i = 1, 3
        if (14 + i <= nstatv) then
          D_old(i) = statev(14 + i)
        end if
      end do
    end if
    if (nstatv >= 20) then
      do i = 1, 3
        if (17 + i <= nstatv) then
          E_field_old(i) = statev(17 + i)
        end if
      end do
    end if
    if (nstatv >= 21) temp_old = statev(21)
    if (nstatv >= 22) time_old = statev(22)
    if (nstatv >= 25) then
      do i = 1, 3
        if (22 + i <= nstatv) then
          magnetization_o(i) = statev(22 + i)
        end if
      end do
    end if
    if (nstatv >= 28) then
      do i = 1, 3
        if (25 + i <= nstatv) then
          polarization_ol(i) = statev(25 + i)
        end if
      end do
    end if
    if (nstatv >= 29) energy_density = statev(29)

    dt = time(1) - time_old
    if (dt < ZERO) dt = dtime

    B = B_old
    if (size(predef) >= 3) then
      B(1) = predef(1)
      B(2) = predef(2)
      B(3) = predef(3)
    end if
    dB = B - B_old

    H = H_old
    if (size(predef) >= 6) then
      H(1) = predef(4)
      H(2) = predef(5)
      H(3) = predef(6)
    end if
    dH = H - H_old

    D = D_old
    if (size(predef) >= 9) then
      D(1) = predef(7)
      D(2) = predef(8)
      D(3) = predef(9)
    end if
    dD = D - D_old

    E_field = E_field_old
    if (size(predef) >= 12) then
      E_field(1) = predef(10)
      E_field(2) = predef(11)
      E_field(3) = predef(12)
    end if
    dE_field = E_field - E_field_old

    strain_total = stran + dstran

    call U258_compute_phase_transformation(martensite_volume_fraction_o, temp, temp_old, dt, &
                                   sigma_ms, sigma_mf, sigma_as, sigma_af, &
                                   T_ms, T_mf, T_as, T_af, epsilon_L, C_M, &
                                   martensite_volu, phase_transform)

    call U258_compute_effective_material_properties_smart(E_a, E_m, nu_a, nu_m, &
                                                  martensite_volu, &
                                                  alpha_thermal_a, alpha_thermal_m, &
                                                  E_effective, nu_effective, alpha_thermal_e)

    call U258_ComputeTransformationStrain(martensite_volu, epsilon_L, ndim, nshr, ntens, analysis_type, strain_transfor)

    call U258_ComputePiezoelectricStrain(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, strain_piezoele)

    call U258_ComputeMagnetostrictionStrain(alpha_magnetost, B, H, ndim, nshr, ntens, analysis_type, strain_magnetos)

    call U258_ComputeElectrostrictiveStrain(alpha_ed, E_field, ndim, nshr, ntens, analysis_type, strain_ed)

    call U258_ComputeThermalStrain(alpha_thermal_e, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)

    strain_plastic = strain_plastic
    do i = 1, ntens
      strain_elastic(i) = strain_total(i) - strain_plastic(i) - strain_transfor(i) - strain_piezoele(i) - &
                     strain_magnetos(i) - strain_ed(i) - strain_thermal(i)
    end do

    call U258_BuildElasticStiffness(E_effective, nu_effective, ndim, nshr, ntens, analysis_type, D_elastic)

    stress_trial = ZERO
    do i = 1, 6
      do j = 1, 6
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
      end do
    end do

    call U258_ComputeTransformationStress(strain_transfor, D_elastic, ndim, nshr, ntens, analysis_type, stress_transfor)

    call U258_ComputePiezoelectricStress(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, stress_piezoele)

    call U258_ComputeMagneticStress(B, H, ndim, nshr, ntens, analysis_type, stress_magnetic)

    do i = 1, ntens
      stress_effectiv(i) = stress_trial(i) + stress_transfor(i) + stress_piezoele(i) + stress_magnetic(i)
    end do

    call U258_ComputeMagnetization(B, H, mu_r, MU0, magnetization)

    call U258_ComputePolarization(D, E_field, epsilon_r, EPSILON0, polarization)

    call U258_ComputeSmartMatEnergyDensity(stress_effectiv, strain_elastic, strain_transfor, &
                                            strain_piezoele, strain_magnetos, strain_ed, &
                                            B, H, D, E_field, magnetization, polarization, &
                                            phase_transform, dt, &
                                            electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating)

    sse = mech_energy
    spd = phase_transform * dt
    scd = electric_energy + magnetic_energy + thermal_energy + joule_heating

    stress = stress_effectiv

    D_coupled = D_elastic
    ddsdde = D_coupled

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 2) statev(2) = martensite_volu
    if (nstatv >= 8) then
      do i = 1, 6
        if (2 + i <= nstatv) then
          statev(2 + i) = strain_plastic(i)
        end if
      end do
    end if
    if (nstatv >= 11) then
      do i = 1, 3
        if (8 + i <= nstatv) then
          statev(8 + i) = B(i)
        end if
      end do
    end if
    if (nstatv >= 14) then
      do i = 1, 3
        if (11 + i <= nstatv) then
          statev(11 + i) = H(i)
        end if
      end do
    end if
    if (nstatv >= 17) then
      do i = 1, 3
        if (14 + i <= nstatv) then
          statev(14 + i) = D(i)
        end if
      end do
    end if
    if (nstatv >= 20) then
      do i = 1, 3
        if (17 + i <= nstatv) then
          statev(17 + i) = E_field(i)
        end if
      end do
    end if
    if (nstatv >= 21) statev(21) = temp
    if (nstatv >= 22) statev(22) = time(1)
    if (nstatv >= 25) then
      do i = 1, 3
        if (22 + i <= nstatv) then
          statev(22 + i) = magnetization(i)
        end if
      end do
    end if
    if (nstatv >= 28) then
      do i = 1, 3
        if (25 + i <= nstatv) then
          statev(25 + i) = polarization(i)
        end if
      end do
    end if
    if (nstatv >= 29) statev(29) = sse + spd + scd

  contains

    function U258_detect_analysis_type(ndim, nshr) result(analysis_type)
      integer, intent(in) :: ndim, nshr
      integer :: analysis_type

      select case(ndim)
        case(1)
          analysis_type = 0
        case(2)
          if (nshr == 1) then
            analysis_type = 2
          else
            analysis_type = 1
          end if
        case(3)
          analysis_type = 0
        case default
          analysis_type = 0
      end select

    end function U258_detect_analysis_type

    subroutine U2_co_ph_transformation(martensite_frac, temp, temp_old, dt, sigma_ms, sigma_mf, sigma_as, sigma_af, T_ms, T_mf, T_as, T_af, epsilon_L, C_M, martensite_frac, phase_rate)
      real(wp), intent(in)  :: martensite_frac, temp, temp_old, dt
      real(wp), intent(in)  :: sigma_ms, sigma_mf, sigma_as, sigma_af
      real(wp), intent(in)  :: T_ms, T_mf, T_as, T_af, epsilon_L, C_M
      real(wp), intent(out) :: martensite_frac, phase_rate

      real(wp) :: temp_rate, driving_force, transformation

      martensite_frac = martensite_frac
      phase_rate = ZERO

      temp_rate = (temp - temp_old) / dt

      if (temp < T_mf) then
        driving_force = (T_mf - temp) / (T_mf - T_ms)
        transformation = driving_force * 0.1_wp
      else if (temp > T_af) then
        driving_force = (temp - T_af) / (T_af - T_as)
        transformation = -driving_force * 0.1_wp
      else
        transformation = ZERO
      end if

      phase_rate = transformation
      martensite_frac = martensite_frac + phase_rate * dt
      martensite_frac = max(min(martensite_frac, ONE), ZERO)

    end subroutine U258_compute_phase_transformation

    subroutine U2_co_ef_mat_pr_smart(E_a, E_m, nu_a, nu_m, martensite_frac, alpha_thermal_a, alpha_thermal_m, E_effective, nu_effective, alpha_thermal_e)
      real(wp), intent(in)  :: E_a, E_m, nu_a, nu_m, martensite_frac
      real(wp), intent(in)  :: alpha_thermal_a, alpha_thermal_m
      real(wp), intent(out) :: E_effective, nu_effective, alpha_thermal_e

      E_effective = E_a * (ONE - martensite_frac) + E_m * martensite_frac
      nu_effective = nu_a * (ONE - martensite_frac) + nu_m * martensite_frac
      alpha_thermal_e = alpha_thermal_a * (ONE - martensite_frac) + alpha_thermal_m * martensite_frac

    end subroutine U258_compute_effective_material_properties_smart

    subroutine U2_co_tr_strain(martensite_frac, epsilon_L, ndim, analysis_type, strain_transfor)
      real(wp), intent(in)  :: martensite_frac, epsilon_L
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: strain_transfor(6)

      strain_transfor = ZERO

      select case(ndim)
        case(1)
          strain_transfor(1) = martensite_frac * epsilon_L
        case(2)
          strain_transfor(1) = martensite_frac * epsilon_L
          strain_transfor(2) = martensite_frac * epsilon_L
          if (analysis_type == 3) then
            strain_transfor(3) = martensite_frac * epsilon_L
          end if
        case(3)
          strain_transfor(1) = martensite_frac * epsilon_L
          strain_transfor(2) = martensite_frac * epsilon_L
          strain_transfor(3) = martensite_frac * epsilon_L
      end select

    end subroutine U258_compute_transformation_strain

    subroutine U2_co_pi_strain(alpha_piezoelec, E_field, ndim, analysis_type, strain_piezoele)
      real(wp), intent(in)  :: alpha_piezoelec(3,3), E_field(3)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: strain_piezoele(6)

      real(wp) :: piezo_strain(3,3)
      integer :: i, j

      strain_piezoele = ZERO

      do i = 1, 3
        do j = 1, 3
          piezo_strain(i,j) = ZERO
          do k = 1, 3
            piezo_strain(i,j) = piezo_strain(i,j) + alpha_piezoelec(i,k) * E_field(k)
          end do
        end do
      end do

      select case(ndim)
        case(1)
          strain_piezoele(1) = piezo_strain(1,1)
        case(2)
          strain_piezoele(1) = piezo_strain(1,1)
          strain_piezoele(2) = piezo_strain(2,2)
          strain_piezoele(3) = TWO * piezo_strain(1,2)
        case(3)
          strain_piezoele(1) = piezo_strain(1,1)
          strain_piezoele(2) = piezo_strain(2,2)
          strain_piezoele(3) = piezo_strain(3,3)
          strain_piezoele(4) = TWO * piezo_strain(2,3)
          strain_piezoele(5) = TWO * piezo_strain(1,3)
          strain_piezoele(6) = TWO * piezo_strain(1,2)
      end select

    end subroutine U258_compute_piezoelectric_strain

    subroutine U2_co_ma_strain(alpha_magnetost, B, H, ndim, analysis_type, strain_magnetos)
      real(wp), intent(in)  :: alpha_magnetost, B(3), H(3)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: strain_magnetos(6)

      real(wp) :: B_magnitude, H_magnitude, magnetostrictio

      strain_magnetos = ZERO

      if (alpha_magnetost < 1.0e-10_wp) return

      B_magnitude = sqrt(dot_product(B, B))
      H_magnitude = sqrt(dot_product(H, H))

      if (B_magnitude < 1.0e-10_wp .or. H_magnitude < 1.0e-10_wp) return

      magnetostrictio = alpha_magnetost * B_magnitude * H_magnitude

      select case(ndim)
        case(1)
          strain_magnetos(1) = magnetostrictio
        case(2)
          strain_magnetos(1) = magnetostrictio
          strain_magnetos(2) = magnetostrictio
          if (analysis_type == 3) then
            strain_magnetos(3) = magnetostrictio
          end if
        case(3)
          strain_magnetos(1) = magnetostrictio
          strain_magnetos(2) = magnetostrictio
          strain_magnetos(3) = magnetostrictio
      end select

    end subroutine U258_compute_magnetostriction_strain

    subroutine U2_co_el_strain(alpha_ed, E_field, ndim, analysis_type, strain_ed)
      real(wp), intent(in)  :: alpha_ed, E_field(3)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: strain_ed(6)

      real(wp) :: E_magnitude, electrostrictiv

      strain_ed = ZERO

      if (alpha_ed < 1.0e-10_wp) return

      E_magnitude = sqrt(dot_product(E_field, E_field))

      if (E_magnitude < 1.0e-10_wp) return

      electrostrictiv = alpha_ed * E_magnitude**2

      select case(ndim)
        case(1)
          strain_ed(1) = electrostrictiv
        case(2)
          strain_ed(1) = electrostrictiv
          strain_ed(2) = electrostrictiv
          if (analysis_type == 3) then
            strain_ed(3) = electrostrictiv
          end if
        case(3)
          strain_ed(1) = electrostrictiv
          strain_ed(2) = electrostrictiv
          strain_ed(3) = electrostrictiv
      end select

    end subroutine U258_compute_electrostrictive_strain

    subroutine U258_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)
      real(wp), intent(in)  :: alpha, dT
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: strain_thermal(6)

      strain_thermal = ZERO

      select case(ndim)
        case(1)
          strain_thermal(1) = alpha * dT
        case(2)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3) then
            strain_thermal(3) = alpha * dT
          end if
        case(3)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          strain_thermal(3) = alpha * dT
      end select

    end subroutine U258_Calc_thermal_strain

    subroutine U258_build_elastic_Stiff(PH_MAT_E, nu, ndim, analysis_type, D_elastic)
      real(wp), intent(in)  :: PH_MAT_E, nu
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: D_elastic(6,6)

      real(wp) :: lambda, mu

      D_elastic = ZERO

      lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
      mu = PH_MAT_E / (TWO * (ONE + nu))

      select case(ndim)
        case(1)
          D_elastic(1,1) = PH_MAT_E
        case(2)
          select case(analysis_type)
            case(1)
              D_elastic(1,1) = PH_MAT_E / (ONE - nu**2)
              D_elastic(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              D_elastic(3,3) = mu
            case(2,3)
              D_elastic(1,1) = lambda + TWO * mu
              D_elastic(1,2) = lambda
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              D_elastic(3,3) = mu
              if (analysis_type == 3) then
                D_elastic(1,3) = lambda
                D_elastic(3,1) = lambda
                D_elastic(2,3) = lambda
                D_elastic(3,2) = lambda
                D_elastic(3,3) = D_elastic(1,1)
              end if
          end select
        case(3)
          D_elastic(1,1) = lambda + TWO * mu
          D_elastic(1,2) = lambda
          D_elastic(1,3) = lambda
          D_elastic(2,1) = lambda
          D_elastic(2,2) = lambda + TWO * mu
          D_elastic(2,3) = lambda
          D_elastic(3,1) = lambda
          D_elastic(3,2) = lambda
          D_elastic(3,3) = lambda + TWO * mu
          D_elastic(4,4) = mu
          D_elastic(5,5) = mu
          D_elastic(6,6) = mu
      end select

      call U258_regularize_Stiff_Mtx(D_elastic)

    end subroutine U258_build_elastic_Stiff

    subroutine U2_co_tr_stress(strain_transfor, D_elastic, ndim, analysis_type, stress_transfor)
      real(wp), intent(in)  :: strain_transfor(6), D_elastic(6,6)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: stress_transfor(6)
      integer :: i, j

      stress_transfor = ZERO

      do i = 1, 6
        do j = 1, 6
          stress_transfor(i) = stress_transfor(i) + D_elastic(i,j) * strain_transfor(j)
        end do
      end do

    end subroutine U258_compute_transformation_stress

    subroutine U2_co_pi_stress(alpha_piezoelec, E_field, ndim, analysis_type, stress_piezoele)
      real(wp), intent(in)  :: alpha_piezoelec(3,3), E_field(3)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: stress_piezoele(6)

      stress_piezoele = ZERO

    end subroutine U258_compute_piezoelectric_stress

    subroutine U258_Calc_magnetic_stress(B, H, ndim, analysis_type, stress_magnetic)
      real(wp), intent(in)  :: B(3), H(3)
      integer, intent(in)  :: ndim, analysis_type
      real(wp), intent(out) :: stress_magnetic(6)

      real(wp) :: maxwell_stress(3,3)
      integer :: i, j

      stress_magnetic = ZERO

      do i = 1, 3
        do j = 1, 3
          maxwell_stress(i,j) = B(i) * H(j) - HALF * (i == j) * dot_product(B, H)
        end do
      end do

      select case(ndim)
        case(1)
          stress_magnetic(1) = maxwell_stress(1,1)
        case(2)
          stress_magnetic(1) = maxwell_stress(1,1)
          stress_magnetic(2) = maxwell_stress(2,2)
          stress_magnetic(3) = maxwell_stress(1,2)
          if (analysis_type == 3) then
            stress_magnetic(3) = maxwell_stress(3,3)
          end if
        case(3)
          stress_magnetic(1) = maxwell_stress(1,1)
          stress_magnetic(2) = maxwell_stress(2,2)
          stress_magnetic(3) = maxwell_stress(3,3)
          stress_magnetic(4) = maxwell_stress(2,3)
          stress_magnetic(5) = maxwell_stress(1,3)
          stress_magnetic(6) = maxwell_stress(1,2)
      end select

    end subroutine U258_Calc_magnetic_stress

    subroutine U258_Calc_magnetization(B, H, mu_r, mu0, magnetization)
      real(wp), intent(in)  :: B(3), H(3), mu_r, mu0
      real(wp), intent(out) :: magnetization(3)
      integer :: i

      do i = 1, 3
        magnetization(i) = (B(i) - mu0 * H(i)) / mu0
      end do

    end subroutine U258_Calc_magnetization

    subroutine U258_Calc_polarization(D, E_field, epsilon_r, epsilon0, polarization)
      real(wp), intent(in)  :: D(3), E_field(3), epsilon_r, epsilon0
      real(wp), intent(out) :: polarization(3)
      integer :: i

      do i = 1, 3
        polarization(i) = D(i) - epsilon0 * epsilon_r * E_field(i)
      end do

    end subroutine U258_Calc_polarization

    subroutine U2_co_sm_mat_en_density(stress, strain_elastic, strain_transfor, strain_piezoele, strain_magnetos, strain_ed, B, H, D, E_field, magnetization, polarization, phase_rate, dt, electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating)
      real(wp), intent(in)  :: stress(6), strain_elastic(6), strain_transfor(6)
      real(wp), intent(in)  :: strain_piezoele(6), strain_magnetos(6), strain_ed(6)
      real(wp), intent(in)  :: B(3), H(3), D(3), E_field(3), magnetization(3), polarization(3)
      real(wp), intent(in)  :: phase_rate, dt
      real(wp), intent(out) :: electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating

      mech_energy = HALF * dot_product(stress, strain_elastic)

      magnetic_energy = HALF * dot_product(B, H) * dt

      electric_energy = HALF * dot_product(E_field, D) * dt

      thermal_energy = phase_rate * dt

      joule_heating = dot_product(E_field, D - epsilon0 * polarization) * dt

    end subroutine U258_compute_smart_material_energy_density

    subroutine U258_regularize_Stiff_Mtx(D)
      real(wp), intent(inout) :: D(6,6)
      integer :: i

      do i = 1, 6
        if (D(i,i) < REGULARIZATION) then
          D(i,i) = REGULARIZATION
        end if
      end do

    end subroutine U258_regularize_Stiff_Mtx

  END SUBROUTINE UF_SmartMaterial_UMAT



    ! 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
    ! Procedures from: MD_MAT_PLAST_VISCDMGEM
    ! 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  subroutine U259_BuildDamagedStiffness(D_viscoelastic, damage_factor, damage_variable, &
                                  stress, strain, ndim, nshr, ntens, analysis_type, D_damaged)
    real(wp), intent(in)  :: D_viscoelastic(6,6), damage_factor, damage_variable
    real(wp), intent(in)  :: stress(6), strain(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_damaged(6,6)

    integer(i4) :: i, j

    D_damaged = D_viscoelastic

    do i = 1, ntens
      do j = 1, ntens
        D_damaged(i,j) = D_viscoelastic(i,j) * damage_factor
      end do
    end do

    call U259_RegularizeStiffMat(D_damaged, ntens)

  end subroutine U259_BuildDamagedStiffness

  subroutine U259_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D)
    real(wp), intent(in)  :: PH_MAT_E, nu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D(6,6)

    real(wp) :: lambda, mu

    D = ZERO

    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    select case(ndim)
      case(1)
        if (ntens >= 1) D(1,1) = PH_MAT_E
      case(2)
        if (ntens >= 2) then
          select case(analysis_type)
            case(1)
              D(1,1) = PH_MAT_E / (ONE - nu**2)
              D(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              if (ntens >= 3) D(3,3) = mu
            case(2,3)
              D(1,1) = lambda + TWO * mu
              D(1,2) = lambda
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              if (ntens >= 3) D(3,3) = mu
          end select
        end if
      case(3)
        if (ntens >= 3) then
          D(1,1) = lambda + TWO * mu
          D(1,2) = lambda
          D(1,3) = lambda
          D(2,1) = lambda
          D(2,2) = lambda + TWO * mu
          D(2,3) = lambda
          D(3,1) = lambda
          D(3,2) = lambda
          D(3,3) = lambda + TWO * mu
          if (ntens >= 6) then
            D(4,4) = mu
            D(5,5) = mu
            D(6,6) = mu
          end if
        end if
    end select

    call U259_RegularizeStiffMat(D, ntens)

  end subroutine U259_BuildElasticStiffness

  subroutine U259_BuildViscoelasticStiff(D_elastic, dt, n_prony, &
                                     g_prony, tau_prony, k_prony, tau_k_prony, &
                                     G_inf, K_inf, G_g, K_g, &
                                     ndim, nshr, ntens, analysis_type, D_viscoelastic)
    real(wp), intent(in)  :: D_elastic(6,6), dt
    integer(i4), intent(in)  :: n_prony
    real(wp), intent(in)  :: g_prony(n_prony), tau_prony(n_prony)
    real(wp), intent(in)  :: k_prony(n_prony), tau_k_prony(n_prony)
    real(wp), intent(in)  :: G_inf, K_inf, G_g, K_g
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_viscoelastic(6,6)

    real(wp) :: G_effective, K_effective, E_effective, nu_effective
    real(wp) :: lambda, mu
    integer(i4) :: i

    D_viscoelastic = D_elastic

    G_effective = G_inf
    K_effective = K_inf

    do i = 1, n_prony
      G_effective = G_effective + g_prony(i) * G_g * (ONE - exp(-dt / max(tau_prony(i), TOL)))
      K_effective = K_effective + k_prony(i) * K_g * (ONE - exp(-dt / max(tau_k_prony(i), TOL)))
    end do

    nu_effective = (THREE * K_effective - TWO * G_effective) / (TWO * (THREE * K_effective + G_effective))
    E_effective = TWO * G_effective * (ONE + nu_effective)

    lambda = E_effective * nu_effective / ((ONE + nu_effective) * (ONE - TWO * nu_effective))
    mu = G_effective

    select case(ndim)
      case(1)
        if (ntens >= 1) D_viscoelastic(1,1) = E_effective
      case(2)
        if (ntens >= 2) then
          D_viscoelastic(1,1) = lambda + TWO * mu
          D_viscoelastic(1,2) = lambda
          D_viscoelastic(2,1) = lambda
          D_viscoelastic(2,2) = lambda + TWO * mu
          if (ntens >= 3) D_viscoelastic(3,3) = mu
        end if
      case(3)
        if (ntens >= 3) then
          D_viscoelastic(1,1) = lambda + TWO * mu
          D_viscoelastic(1,2) = lambda
          D_viscoelastic(1,3) = lambda
          D_viscoelastic(2,1) = lambda
          D_viscoelastic(2,2) = lambda + TWO * mu
          D_viscoelastic(2,3) = lambda
          D_viscoelastic(3,1) = lambda
          D_viscoelastic(3,2) = lambda
          D_viscoelastic(3,3) = lambda + TWO * mu
          if (ntens >= 6) then
            D_viscoelastic(4,4) = mu
            D_viscoelastic(5,5) = mu
            D_viscoelastic(6,6) = mu
          end if
        end if
    end select

    call U259_RegularizeStiffMat(D_viscoelastic, ntens)

  end subroutine U259_BuildViscoelasticStiff

  subroutine U259_ComputeDamageVariable(stress, sigma_eqv, sigma_critical, &
                                alpha_damage, beta_damage, G_c, dt, &
                                damage_old, damage, damage_rate)
    real(wp), intent(in)  :: stress(6), sigma_eqv, sigma_critical
    real(wp), intent(in)  :: alpha_damage, beta_damage, G_c, dt, damage_old
    real(wp), intent(out) :: damage, damage_rate

    real(wp) :: damage_driving

    damage = damage_old
    damage_rate = ZERO

    if (sigma_eqv > sigma_critical) then
      damage_driving = alpha_damage * (sigma_eqv / max(sigma_critical, TOL))**beta_damage
      damage_rate = (damage_driving - damage_old) / max(dt, TOL)
      damage = damage_old + damage_rate * dt
      damage = min(damage, ONE)
    end if

  end subroutine U259_ComputeDamageVariable

  subroutine U259_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)
    real(wp), intent(in)  :: s_dev(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: sigma_eqv

    real(wp), parameter :: SIX = 6.0_wp

    sigma_eqv = ZERO

    select case(ndim)
      case(1)
        sigma_eqv = abs(s_dev(1))
      case(2)
        sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 - s_dev(1)*s_dev(2) + THREE*s_dev(3)**2))
      case(3)
        sigma_eqv = sqrt(1.5_wp * ((s_dev(1)-s_dev(2))**2 + (s_dev(2)-s_dev(3))**2 + (s_dev(3)-s_dev(1))**2 + &
                                SIX*(s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    end select

  end subroutine U259_ComputeEquivalentStress

  subroutine U259_ComputeStrainInvariants(strain, ndim, nshr, ntens, analysis_type, strain_vol, strain_dev)
    real(wp), intent(in)  :: strain(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_vol, strain_dev(6)

    integer(i4) :: i

    strain_vol = ZERO
    strain_dev = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) then
          strain_vol = strain(1)
          strain_dev(1) = strain(1) - strain_vol / THREE
        end if
      case(2)
        if (ntens >= 2) then
          strain_vol = strain(1) + strain(2)
          strain_dev(1) = strain(1) - strain_vol / THREE
          strain_dev(2) = strain(2) - strain_vol / THREE
          if (ntens >= 3) strain_dev(3) = strain(3)
        end if
      case(3)
        if (ntens >= 3) then
          strain_vol = strain(1) + strain(2) + strain(3)
          do i = 1, 3
            strain_dev(i) = strain(i) - strain_vol / THREE
          end do
          if (ntens >= 6) then
            do i = 4, 6
              strain_dev(i) = strain(i)
            end do
          end if
        end if
    end select

  end subroutine U259_ComputeStrainInvariants

  subroutine U259_ComputeStressInvariants(stress, ndim, nshr, ntens, analysis_type, p, s_dev)
    real(wp), intent(in)  :: stress(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: p, s_dev(6)

    integer(i4) :: i

    p = ZERO
    s_dev = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) then
          p = stress(1) / THREE
          s_dev(1) = stress(1) - p
        end if
      case(2)
        if (ntens >= 2) then
          p = (stress(1) + stress(2)) / THREE
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (ntens >= 3) s_dev(3) = stress(3)
        end if
      case(3)
        if (ntens >= 3) then
          p = (stress(1) + stress(2) + stress(3)) / THREE
          do i = 1, 3
            s_dev(i) = stress(i) - p
          end do
          if (ntens >= 6) then
            do i = 4, 6
              s_dev(i) = stress(i)
            end do
          end if
        end if
    end select

  end subroutine U259_ComputeStressInvariants

  subroutine U259_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, dT
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    integer(i4) :: i

    strain_thermal = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_thermal(1) = alpha * dT
      case(2)
        if (ntens >= 2) then
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_thermal(3) = alpha * dT
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_thermal(i) = alpha * dT
          end do
        end if
    end select

  end subroutine U259_ComputeThermalStrain

  function U259_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function U259_DetectAnalysisType

  subroutine U259_RegularizeStiffMat(D, ntens)
    real(wp), intent(inout) :: D(6,6)
    integer(i4), intent(in) :: ntens

    real(wp), parameter :: MIN_STIFFNESS = 1.0e-10_wp
    integer(i4) :: i

    do i = 1, ntens
      if (D(i,i) < MIN_STIFFNESS) then
        D(i,i) = MIN_STIFFNESS
      end if
    end do

  end subroutine U259_RegularizeStiffMat

  subroutine U260_BuildElasticStiffness(lambda, mu, ndim, nshr, ntens, analysis_type, D)
    real(wp), intent(in)  :: lambda, mu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D(6,6)

    D = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) D(1,1) = lambda + TWO * mu
      case(2)
        if (ntens >= 2) then
          select case(analysis_type)
            case(1)
              D(1,1) = (lambda + TWO * mu) / (ONE - nu**2)
              D(1,2) = lambda / (ONE - nu**2)
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              if (ntens >= 3) D(3,3) = mu
            case(2,3)
              D(1,1) = lambda + TWO * mu
              D(1,2) = lambda
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              if (ntens >= 3) D(3,3) = mu
          end select
        end if
      case(3)
        if (ntens >= 3) then
          D(1,1) = lambda + TWO * mu
          D(1,2) = lambda
          D(1,3) = lambda
          D(2,1) = lambda
          D(2,2) = lambda + TWO * mu
          D(2,3) = lambda
          D(3,1) = lambda
          D(3,2) = lambda
          D(3,3) = lambda + TWO * mu
          if (ntens >= 6) then
            D(4,4) = mu
            D(5,5) = mu
            D(6,6) = mu
          end if
        end if
    end select

    call U260_RegularizeStiffMat(D, ntens)

  end subroutine U260_BuildElasticStiffness

  subroutine U260_BuildViscoplasticStiff(lambda, mu, H, eta, sigma_eqv, s_dev, delta_lambda, &
                                     ndim, nshr, ntens, analysis_type, D_viscoplastic)
    real(wp), intent(in)  :: lambda, mu, H, eta, sigma_eqv, s_dev(6), delta_lambda
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_viscoplastic(6,6)

    real(wp) :: factor, N(6)
    integer(i4) :: i, j

    D_viscoplastic = ZERO

    call U260_BuildElasticStiffness(lambda, mu, ndim, nshr, ntens, analysis_type, D_viscoplastic)

    if (delta_lambda > TOL .and. sigma_eqv > TOL) then
      do i = 1, ntens
        N(i) = (THREE/TWO) * s_dev(i) / sigma_eqv
      end do

      factor = ONE / (ONE + (THREE/TWO) * mu * delta_lambda / sigma_eqv + H * delta_lambda / sigma_eqv)

      do i = 1, ntens
        do j = 1, ntens
          D_viscoplastic(i,j) = D_viscoplastic(i,j) - factor * (THREE/TWO) * mu * N(i) * N(j)
        end do
      end do
    end if

    call U260_RegularizeStiffMat(D_viscoplastic, ntens)

  end subroutine U260_BuildViscoplasticStiff

  subroutine U260_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)
    real(wp), intent(in)  :: s_dev(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: sigma_eqv

    real(wp), parameter :: SIX = 6.0_wp

    sigma_eqv = ZERO

    select case(ndim)
      case(1)
        sigma_eqv = abs(s_dev(1))
      case(2)
        sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 - s_dev(1)*s_dev(2) + THREE*s_dev(3)**2))
      case(3)
        sigma_eqv = sqrt(1.5_wp * ((s_dev(1)-s_dev(2))**2 + (s_dev(2)-s_dev(3))**2 + (s_dev(3)-s_dev(1))**2 + &
                                SIX*(s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    end select

  end subroutine U260_ComputeEquivalentStress

  subroutine U260_ComputeStrainRate(dstra, dtime, strain_rate)
    real(wp), intent(in)  :: dstra(6), dtime
    real(wp), intent(out) :: strain_rate(6)

    integer(i4) :: i

    do i = 1, 6
      strain_rate(i) = dstra(i) / max(dtime, TOL)
    end do

  end subroutine U260_ComputeStrainRate

  subroutine U260_ComputeStressInvariants(stress, ndim, nshr, ntens, analysis_type, p, s_dev)
    real(wp), intent(in)  :: stress(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: p, s_dev(6)

    integer(i4) :: i

    p = ZERO
    s_dev = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) then
          p = stress(1) / THREE
          s_dev(1) = stress(1) - p
        end if
      case(2)
        if (ntens >= 2) then
          p = (stress(1) + stress(2)) / THREE
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (ntens >= 3) s_dev(3) = stress(3)
        end if
      case(3)
        if (ntens >= 3) then
          p = (stress(1) + stress(2) + stress(3)) / THREE
          do i = 1, 3
            s_dev(i) = stress(i) - p
          end do
          if (ntens >= 6) then
            do i = 4, 6
              s_dev(i) = stress(i)
            end do
          end if
        end if
    end select

  end subroutine U260_ComputeStressInvariants

  subroutine U260_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, dT
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    integer(i4) :: i

    strain_thermal = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_thermal(1) = alpha * dT
      case(2)
        if (ntens >= 2) then
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_thermal(3) = alpha * dT
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_thermal(i) = alpha * dT
          end do
        end if
    end select

  end subroutine U260_ComputeThermalStrain

  function U260_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function U260_DetectAnalysisType

  subroutine U260_RegularizeStiffMat(D, ntens)
    real(wp), intent(inout) :: D(6,6)
    integer(i4), intent(in) :: ntens

    real(wp), parameter :: MIN_STIFFNESS = 1.0e-10_wp
    integer(i4) :: i

    do i = 1, ntens
      if (D(i,i) < MIN_STIFFNESS) then
        D(i,i) = MIN_STIFFNESS
      end if
    end do

  end subroutine U260_RegularizeStiffMat

  subroutine U261_BuildDamagedStiffness(D_elastic, damage_factor, damage_variable, &
                                       stress, strain, ndim, nshr, ntens, analysis_type, D_damaged)
    real(wp), intent(in)  :: D_elastic(6,6), damage_factor, damage_variable
    real(wp), intent(in)  :: stress(6), strain(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_damaged(6,6)

    real(wp) :: stiffness_reduc
    integer(i4) :: i, j

    D_damaged = D_elastic

    if (damage_factor < TOL .or. damage_variable < TOL) return

    stiffness_reduc = ONE - damage_factor

    do i = 1, ntens
      do j = 1, ntens
        D_damaged(i,j) = D_damaged(i,j) * stiffness_reduc
      end do
    end do

    call U261_RegularizeStiffMat(D_damaged, ntens)

  end subroutine U261_BuildDamagedStiffness

  subroutine U261_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D)
    real(wp), intent(in)  :: PH_MAT_E, nu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D(6,6)

    real(wp) :: lambda, mu

    D = ZERO

    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    select case(ndim)
      case(1)
        if (ntens >= 1) D(1,1) = PH_MAT_E
      case(2)
        if (ntens >= 2) then
          select case(analysis_type)
            case(1)
              D(1,1) = PH_MAT_E / (ONE - nu**2)
              D(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              if (ntens >= 3) D(3,3) = mu
            case(2,3)
              D(1,1) = lambda + TWO * mu
              D(1,2) = lambda
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              if (ntens >= 3) D(3,3) = mu
          end select
        end if
      case(3)
        if (ntens >= 3) then
          D(1,1) = lambda + TWO * mu
          D(1,2) = lambda
          D(1,3) = lambda
          D(2,1) = lambda
          D(2,2) = lambda + TWO * mu
          D(2,3) = lambda
          D(3,1) = lambda
          D(3,2) = lambda
          D(3,3) = lambda + TWO * mu
          if (ntens >= 6) then
            D(4,4) = mu
            D(5,5) = mu
            D(6,6) = mu
          end if
        end if
    end select

    call U261_RegularizeStiffMat(D, ntens)

  end subroutine U261_BuildElasticStiffness

  subroutine U261_ComputeEquivalentStress(stress, ndim, nshr, ntens, analysis_type, sigma_eqv)
    real(wp), intent(in)  :: stress(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: sigma_eqv

    real(wp), parameter :: SIX = 6.0_wp

    sigma_eqv = ZERO

    select case(ndim)
      case(1)
        sigma_eqv = abs(stress(1))
      case(2)
        sigma_eqv = sqrt(1.5_wp * (stress(1)**2 + stress(2)**2 - stress(1)*stress(2) + THREE * stress(3)**2))
      case(3)
        sigma_eqv = sqrt(1.5_wp * ((stress(1)-stress(2))**2 + (stress(2)-stress(3))**2 + (stress(3)-stress(1))**2 + &
                              SIX * (stress(4)**2 + stress(5)**2 + stress(6)**2)))
    end select

  end subroutine U261_ComputeEquivalentStress

  subroutine U261_ComputeStressDeviator(stress, ndim, nshr, ntens, analysis_type, s_dev)
    real(wp), intent(in)  :: stress(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: s_dev(6)

    real(wp) :: p
    integer(i4) :: i

    s_dev = stress

    select case(ndim)
      case(1)
        if (ntens >= 1) then
          p = stress(1) / THREE
          s_dev(1) = stress(1) - p
        end if
      case(2)
        if (ntens >= 2) then
          p = (stress(1) + stress(2)) / THREE
          if (analysis_type == 3 .and. ntens >= 3) then
            p = (stress(1) + stress(2) + stress(3)) / THREE
          end if
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (ntens >= 3) s_dev(3) = stress(3)
        end if
      case(3)
        if (ntens >= 3) then
          p = (stress(1) + stress(2) + stress(3)) / THREE
          do i = 1, 3
            s_dev(i) = stress(i) - p
          end do
          if (ntens >= 6) then
            do i = 4, 6
              s_dev(i) = stress(i)
            end do
          end if
        end if
    end select

  end subroutine U261_ComputeStressDeviator

  subroutine U261_ComputeThermalStrain(alpha, dT, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, dT
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    integer(i4) :: i

    strain_thermal = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_thermal(1) = alpha * dT
      case(2)
        if (ntens >= 2) then
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_thermal(3) = alpha * dT
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_thermal(i) = alpha * dT
          end do
        end if
    end select

  end subroutine U261_ComputeThermalStrain

  function U261_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function U261_DetectAnalysisType

  subroutine U261_RegularizeStiffMat(D, ntens)
    real(wp), intent(inout) :: D(6,6)
    integer(i4), intent(in) :: ntens

    integer(i4) :: i

    do i = 1, ntens
      if (D(i,i) < REGULARIZATION) then
        D(i,i) = REGULARIZATION
      end if
    end do

  end subroutine U261_RegularizeStiffMat

  subroutine U262_BuildCoupledStiffness(D_elastic, alpha_piezo, alpha_mag, alpha_ed, Q_te, S_tm, &
                                   B, H, E_field, temp, temp_old, &
                                   ndim, nshr, ntens, analysis_type, D_coupled)
    real(wp), intent(in)  :: D_elastic(6,6), alpha_piezo(3,3), alpha_mag, alpha_ed, Q_te, S_tm
    real(wp), intent(in)  :: B(3), H(3), E_field(3), temp, temp_old
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_coupled(6,6)

    integer(i4) :: i, j
    real(wp) :: B_mag, H_mag, E_mag, coupling_factor, delta_temp

    D_coupled = D_elastic

    B_mag = sqrt(dot_product(B, B))
    H_mag = sqrt(dot_product(H, H))
    E_mag = sqrt(dot_product(E_field, E_field))
    delta_temp = temp - temp_old

    coupling_factor = ONE + alpha_mag * B_mag * H_mag + alpha_ed * E_mag * E_mag + &
                     Q_te * delta_temp * E_mag + S_tm * delta_temp * B_mag

    do i = 1, ntens
      do j = 1, ntens
        D_coupled(i,j) = D_coupled(i,j) * coupling_factor
      end do
    end do

    do i = 1, min(ndim, 3)
      do j = 1, 3
        if (i <= ntens .and. j <= 3) then
          if (i == j) then
            D_coupled(i,i) = D_coupled(i,i) + alpha_piezo(i,j) * E_field(j) / (E_mag + REGULARIZATION)
          end if
        end if
      end do
    end do

    call U262_RegularizeStiffMat(D_coupled, ntens)

  end subroutine U262_BuildCoupledStiffness

  subroutine U262_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)
    real(wp), intent(in)  :: PH_MAT_E, nu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: D_elastic(6,6)

    real(wp) :: lambda, mu, factor

    D_elastic = ZERO

    mu = PH_MAT_E / (TWO * (ONE + nu))
    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))

    select case(ndim)
      case(1)
        if (ntens >= 1) D_elastic(1,1) = PH_MAT_E
      case(2)
        if (ntens >= 2) then
          select case(analysis_type)
            case(1)
              D_elastic(1,1) = PH_MAT_E / (ONE - nu * nu)
              D_elastic(1,2) = PH_MAT_E * nu / (ONE - nu * nu)
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              if (ntens >= 3) D_elastic(3,3) = mu
            case(2,3)
              factor = PH_MAT_E / ((ONE + nu) * (ONE - TWO * nu))
              D_elastic(1,1) = factor * (ONE - nu)
              D_elastic(1,2) = factor * nu
              D_elastic(2,1) = D_elastic(1,2)
              D_elastic(2,2) = D_elastic(1,1)
              if (ntens >= 3) D_elastic(3,3) = mu
              if (analysis_type == 3 .and. ntens >= 3) then
                D_elastic(1,3) = factor * nu
                D_elastic(3,1) = D_elastic(1,3)
                D_elastic(2,3) = factor * nu
                D_elastic(3,2) = D_elastic(2,3)
                D_elastic(3,3) = D_elastic(1,1)
              end if
          end select
        end if
      case(3)
        if (ntens >= 3) then
          factor = PH_MAT_E / ((ONE + nu) * (ONE - TWO * nu))
          D_elastic(1,1) = factor * (ONE - nu)
          D_elastic(1,2) = factor * nu
          D_elastic(1,3) = factor * nu
          D_elastic(2,1) = D_elastic(1,2)
          D_elastic(2,2) = D_elastic(1,1)
          D_elastic(2,3) = factor * nu
          D_elastic(3,1) = D_elastic(1,3)
          D_elastic(3,2) = D_elastic(2,3)
          D_elastic(3,3) = D_elastic(1,1)
          if (ntens >= 6) then
            D_elastic(4,4) = mu
            D_elastic(5,5) = mu
            D_elastic(6,6) = mu
          end if
        end if
    end select

    call U262_RegularizeStiffMat(D_elastic, ntens)

  end subroutine U262_BuildElasticStiffness

  subroutine U262_ComputeCoupledEnergy(B, H, D, E_field, J, dt, temp, temp_old, &
                                   strain_elastic, stress_effectiv, &
                                   electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating)
    real(wp), intent(in)  :: B(3), H(3), D(3), E_field(3), J(3), dt, temp, temp_old
    real(wp), intent(in)  :: strain_elastic(6), stress_effectiv(6)
    real(wp), intent(out) :: electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating

    electric_energy = HALF * dot_product(D, E_field)
    magnetic_energy = HALF * dot_product(B, H)
    mech_energy = HALF * dot_product(stress_effectiv, strain_elastic)
    thermal_energy = ZERO
    joule_heating = dot_product(J, J) * dt

  end subroutine U262_ComputeCoupledEnergy

  subroutine U262_ComputeCurrentDensity(sigma_e, E_field, temp, temp_old, Q_te, J)
    real(wp), intent(in)  :: sigma_e, E_field(3), temp, temp_old, Q_te
    real(wp), intent(out) :: J(3)

    integer(i4) :: i
    real(wp) :: delta_temp

    delta_temp = temp - temp_old

    do i = 1, 3
      J(i) = sigma_e * E_field(i) + Q_te * delta_temp * E_field(i)
    end do

  end subroutine U262_ComputeCurrentDensity

  subroutine U262_ComputeMagnetization(B, H, mu_r, mu0, magnetization)
    real(wp), intent(in)  :: B(3), H(3), mu_r, mu0
    real(wp), intent(out) :: magnetization(3)

    integer(i4) :: i

    do i = 1, 3
      magnetization(i) = B(i) / (mu_r * mu0) - H(i)
    end do

  end subroutine U262_ComputeMagnetization

  subroutine U262_ComputePolarization(D, E_field, epsilon_r, epsilon0, polarization)
    real(wp), intent(in)  :: D(3), E_field(3), epsilon_r, epsilon0
    real(wp), intent(out) :: polarization(3)

    integer(i4) :: i

    do i = 1, 3
      polarization(i) = D(i) - epsilon_r * epsilon0 * E_field(i)
    end do

  end subroutine U262_ComputePolarization

  subroutine U262_ComputeThermalStrain(alpha, delta_temp, ndim, nshr, ntens, analysis_type, strain_thermal)
    real(wp), intent(in)  :: alpha, delta_temp
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_thermal(6)

    integer(i4) :: i

    strain_thermal = ZERO

    select case(ndim)
      case(1)
        if (ntens >= 1) strain_thermal(1) = alpha * delta_temp
      case(2)
        if (ntens >= 2) then
          strain_thermal(1) = alpha * delta_temp
          strain_thermal(2) = alpha * delta_temp
          if (analysis_type == 3 .and. ntens >= 3) then
            strain_thermal(3) = alpha * delta_temp
          end if
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            strain_thermal(i) = alpha * delta_temp
          end do
        end if
    end select

  end subroutine U262_ComputeThermalStrain

  subroutine U262_ComputeThermalStress(D_elastic, strain_thermal, ndim, nshr, ntens, analysis_type, stress_thermal)
    real(wp), intent(in)  :: D_elastic(6,6), strain_thermal(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_thermal(6)

    integer(i4) :: i, j

    stress_thermal = ZERO

    do i = 1, ntens
      do j = 1, ntens
        stress_thermal(i) = stress_thermal(i) + D_elastic(i,j) * strain_thermal(j)
      end do
    end do

  end subroutine U262_ComputeThermalStress

  function U262_DetectAnalysisType(ndim, nshr) result(analysis_type)
    integer(i4), intent(in) :: ndim, nshr
    integer(i4) :: analysis_type

    select case(ndim)
      case(1)
        analysis_type = 0
      case(2)
        if (nshr == 1) then
          analysis_type = 2
        else if (nshr == 2) then
          analysis_type = 3
        else
          analysis_type = 1
        end if
      case(3)
        analysis_type = 0
      case default
        analysis_type = 0
    end select

  end function U262_DetectAnalysisType

  subroutine U262_RegularizeStiffMat(D, n)
    real(wp), intent(inout) :: D(6,6)
    integer(i4), intent(in) :: n

    integer(i4) :: i

    do i = 1, n
      if (D(i,i) < REGULARIZATION) then
        D(i,i) = D(i,i) + REGULARIZATION
      end if
    end do

  end subroutine U262_RegularizeStiffMat

  subroutine U2_ComputeDmgVarWithScaleEff(stress, sigma_critical, alpha_damage, &
                                                     beta_damage, G_c, length_scale, &
                                                     volume_fraction, dt, strain_plastic, &
                                                     damage_variable, damage_variable, damage_rate)
    real(wp), intent(in)  :: stress(6), sigma_critical, alpha_damage, beta_damage, G_c, length_scale
    real(wp), intent(in)  :: volume_fraction, dt, strain_plastic(6), damage_variable
    real(wp), intent(out) :: damage_variable, damage_rate

    real(wp) :: sigma_eqv, plastic_strain
    real(wp) :: damage_driving, scale_factor, volume_factor
    real(wp), parameter :: FIVE = 5.0_wp

    damage_variable = damage_variable
    damage_rate = ZERO

    call U261_ComputeEquivalentStress(stress, 3, 0, 0, sigma_eqv)

    plastic_strain = sqrt(dot_product(strain_plastic, strain_plastic))

    scale_factor = ONE + 0.2_wp * exp(-length_scale / 1.0e-6_wp)
    volume_factor = ONE + 0.3_wp * (ONE - volume_fraction)

    if (sigma_eqv > sigma_critical * scale_factor * volume_factor .or. plastic_strain > 0.01_wp) then
      damage_driving = (sigma_eqv / (sigma_critical * scale_factor * volume_factor) - ONE) + &
                            FIVE * plastic_strain

      if (damage_driving > ZERO) then
        damage_rate = alpha_damage * damage_driving**beta_damage * scale_factor
        damage_variable = damage_variable + damage_rate * dt
        damage_variable = max(min(damage_variable, ONE), ZERO)
      end if
    end if

  end subroutine U261_ComputeDmgVarWithScaleEffect

  subroutine U2_ComputeElectromagneticStr(B, H, J, ndim, nshr, ntens, analysis_type, stress_mag)
    real(wp), intent(in)  :: B(3), H(3), J(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_mag(6)

    real(wp) :: B_mag, H_mag, J_mag, magnetic_pressu
    integer(i4) :: i

    stress_mag = ZERO

    B_mag = sqrt(dot_product(B, B))
    H_mag = sqrt(dot_product(H, H))
    J_mag = sqrt(dot_product(J, J))

    magnetic_pressu = B_mag * H_mag / (TWO * MU0)

    select case(ndim)
      case(1)
        if (ntens >= 1) stress_mag(1) = B(1)**2 / MU0 - magnetic_pressu
      case(2)
        if (ntens >= 2) then
          stress_mag(1) = B(1)**2 / MU0 - magnetic_pressu
          stress_mag(2) = B(2)**2 / MU0 - magnetic_pressu
          if (ntens >= 3) stress_mag(3) = B(1) * B(2) / MU0
        end if
      case(3)
        if (ntens >= 3) then
          do i = 1, 3
            stress_mag(i) = B(i)**2 / MU0 - magnetic_pressu
          end do
          if (ntens >= 6) then
            stress_mag(4) = B(2) * B(3) / MU0
            stress_mag(5) = B(1) * B(3) / MU0
            stress_mag(6) = B(1) * B(2) / MU0
          end if
        end if
    end select

  end subroutine U262_ComputeElectromagneticStress

  subroutine U2_ComputeElectrostrictiveSt(alpha_ed, E_field, ndim, nshr, ntens, analysis_type, strain_ed)
    real(wp), intent(in)  :: alpha_ed
    real(wp), intent(in)  :: E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_ed(6)

    real(wp) :: E_mag_sq
    integer(i4) :: i

    strain_ed = ZERO

    E_mag_sq = dot_product(E_field, E_field)

    if (E_mag_sq > TOL) then
      select case(ndim)
        case(1)
          if (ntens >= 1) strain_ed(1) = alpha_ed * E_mag_sq
        case(2)
          if (ntens >= 2) then
            strain_ed(1) = alpha_ed * E_mag_sq
            strain_ed(2) = alpha_ed * E_mag_sq
            if (analysis_type == 3 .and. ntens >= 3) then
              strain_ed(3) = alpha_ed * E_mag_sq
            end if
          end if
        case(3)
          if (ntens >= 3) then
            do i = 1, 3
              strain_ed(i) = alpha_ed * E_mag_sq
            end do
          end if
      end select
    end if

  end subroutine U262_ComputeElectrostrictiveStrain

  subroutine U2_ComputeEquivalentStrainRa(strain_rate, ndim, nshr, ntens, analysis_type, eps_eqv_rate)
    real(wp), intent(in)  :: strain_rate(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: eps_eqv_rate

    real(wp), parameter :: SIX = 6.0_wp

    eps_eqv_rate = ZERO

    select case(ndim)
      case(1)
        eps_eqv_rate = abs(strain_rate(1))
      case(2)
        eps_eqv_rate = sqrt((TWO/THREE) * (strain_rate(1)**2 + strain_rate(2)**2 - strain_rate(1)*strain_rate(2) + THREE*strain_rate(3)**2))
      case(3)
        eps_eqv_rate = sqrt((TWO/THREE) * ((strain_rate(1)-strain_rate(2))**2 + (strain_rate(2)-strain_rate(3))**2 + &
                                         (strain_rate(3)-strain_rate(1))**2 + SIX*(strain_rate(4)**2 + strain_rate(5)**2 + strain_rate(6)**2)))
    end select

  end subroutine U260_ComputeEquivalentStrainRate

  subroutine U2_ComputeMagnetostrictionSt(alpha_mag, B, H, ndim, nshr, ntens, analysis_type, strain_mag)
    real(wp), intent(in)  :: alpha_mag
    real(wp), intent(in)  :: B(3), H(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_mag(6)

    real(wp) :: B_mag, H_mag
    integer(i4) :: i

    strain_mag = ZERO

    B_mag = sqrt(dot_product(B, B))
    H_mag = sqrt(dot_product(H, H))

    if (B_mag > TOL .and. H_mag > TOL) then
      select case(ndim)
        case(1)
          if (ntens >= 1) strain_mag(1) = alpha_mag * B_mag * H_mag
        case(2)
          if (ntens >= 2) then
            strain_mag(1) = alpha_mag * B_mag * H_mag
            strain_mag(2) = alpha_mag * B_mag * H_mag
            if (analysis_type == 3 .and. ntens >= 3) then
              strain_mag(3) = alpha_mag * B_mag * H_mag
            end if
          end if
        case(3)
          if (ntens >= 3) then
            do i = 1, 3
              strain_mag(i) = alpha_mag * B_mag * H_mag
            end do
          end if
      end select
    end if

  end subroutine U262_ComputeMagnetostrictionStrain

  subroutine U2_ComputePiezoelectricStrai(alpha_piezo, E_field, ndim, nshr, ntens, analysis_type, strain_piezo)
    real(wp), intent(in)  :: alpha_piezo(3,3), E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_piezo(6)

    integer(i4) :: i, j

    strain_piezo = ZERO

    do i = 1, min(ndim, 3)
      do j = 1, 3
        if (i <= ntens) then
          strain_piezo(i) = strain_piezo(i) + alpha_piezo(i,j) * E_field(j)
        end if
      end do
    end do

  end subroutine U262_ComputePiezoelectricStrain

  subroutine U2_ComputePiezoelectricStres(alpha_piezo, E_field, ndim, nshr, ntens, analysis_type, stress_piezo)
    real(wp), intent(in)  :: alpha_piezo(3,3), E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_piezo(6)

    integer(i4) :: i, j

    stress_piezo = ZERO

    do i = 1, min(ndim, 3)
      do j = 1, 3
        if (i <= ntens) then
          stress_piezo(i) = stress_piezo(i) + alpha_piezo(i,j) * E_field(j)
        end if
      end do
    end do

  end subroutine U262_ComputePiezoelectricStress

  subroutine U2_ComputePlasticStrainIncr(stress, plastic_multipl, ndim, nshr, ntens, analysis_type, dstra_plastic)
    real(wp), intent(in)  :: stress(6), plastic_multipl
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: dstra_plastic(6)

    real(wp) :: s_dev(6), sigma_eqv, factor
    integer(i4) :: i

    dstra_plastic = ZERO

    call U261_ComputeEquivalentStress(stress, ndim, nshr, ntens, analysis_type, sigma_eqv)

    if (sigma_eqv < TOL) return

    call U261_ComputeStressDeviator(stress, ndim, nshr, ntens, analysis_type, s_dev)

    factor = 1.5_wp * plastic_multipl / sigma_eqv
    do i = 1, ntens
      dstra_plastic(i) = factor * s_dev(i)
    end do

  end subroutine U261_ComputePlasticStrainIncr

  subroutine U2_ComputePlasticStrainIncrW(stress, strain_plastic, &
                                                               sigma_y, H, length_scale, &
                                                               volume_fraction, ndim, nshr, ntens, analysis_type, &
                                                               dstra_plastic, strain_plastic)
    real(wp), intent(in)  :: stress(6), strain_plastic(6), sigma_y, H, length_scale, volume_fraction
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: dstra_plastic(6), strain_plastic(6)

    real(wp) :: sigma_eqv, sigma_y_effecti, plastic_multipl
    real(wp) :: scale_factor, volume_factor
    real(wp) :: plastic_strain, sigma_y_hardene
    real(wp) :: mu, E_local

    dstra_plastic = ZERO
    strain_plastic = strain_plastic

    call U261_ComputeEquivalentStress(stress, ndim, nshr, ntens, analysis_type, sigma_eqv)

    scale_factor = ONE + 0.1_wp * exp(-length_scale / 1.0e-6_wp)
    volume_factor = ONE + 0.5_wp * (ONE - volume_fraction)

    sigma_y_effecti = sigma_y * scale_factor * volume_factor

    if (sigma_eqv > sigma_y_effecti) then
      plastic_strain = sqrt(dot_product(strain_plastic, strain_plastic))
      sigma_y_hardene = sigma_y_effecti + H * plastic_strain

      if (sigma_eqv > sigma_y_hardene) then
        E_local = sigma_y / 0.002_wp
        mu = E_local / (TWO * (ONE + 0.3_wp))
        plastic_multipl = (sigma_eqv - sigma_y_hardene) / (H + THREE * mu) * 0.1_wp

        call U261_ComputePlasticStrainIncr(stress, plastic_multipl, ndim, nshr, ntens, analysis_type, dstra_plastic)

        strain_plastic = strain_plastic + dstra_plastic
      end if
    end if

  end subroutine U261_ComputePlasticStrainIncrWithScaleEffect

  subroutine U2_ComputePronyViscoelasticS(dstra_elastic, dt, n_prony, &
                                          g_prony, tau_prony, k_prony, tau_k_prony, &
                                          G_inf, K_inf, G_g, K_g, &
                                          s_old, p_old, s_current, p_current, &
                                          ndim, nshr, ntens, analysis_type, stress_visc)
    real(wp), intent(in)  :: dstra_elastic(6), dt
    integer(i4), intent(in)  :: n_prony
    real(wp), intent(in)  :: g_prony(n_prony), tau_prony(n_prony)
    real(wp), intent(in)  :: k_prony(n_prony), tau_k_prony(n_prony)
    real(wp), intent(in)  :: G_inf, K_inf, G_g, K_g
    real(wp), intent(inout) :: s_old(n_prony, 6), p_old(n_prony)
    real(wp), intent(out) :: s_current(6), p_current
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_visc(6)

    real(wp) :: strain_vol, strain_dev(6)
    real(wp) :: exp_factor
    integer(i4) :: i, j

    stress_visc = ZERO
    s_current = ZERO
    p_current = ZERO

    call U259_ComputeStrainInvariants(dstra_elastic, ndim, nshr, ntens, analysis_type, strain_vol, strain_dev)

    do i = 1, n_prony
      exp_factor = exp(-dt / max(tau_prony(i), TOL))
      do j = 1, ntens
        s_old(i,j) = s_old(i,j) * exp_factor + g_prony(i) * G_g * strain_dev(j) * (ONE - exp_factor)
        s_current(j) = s_current(j) + s_old(i,j)
      end do
    end do

    do i = 1, n_prony
      exp_factor = exp(-dt / max(tau_k_prony(i), TOL))
      p_old(i) = p_old(i) * exp_factor + k_prony(i) * K_g * strain_vol * (ONE - exp_factor)
      p_current = p_current + p_old(i)
    end do

    do j = 1, ntens
      stress_visc(j) = G_inf * strain_dev(j) + s_current(j)
    end do

    select case(ndim)
      case(1)
        stress_visc(1) = stress_visc(1) + K_inf * strain_vol + p_current
      case(2)
        if (ntens >= 2) then
          stress_visc(1) = stress_visc(1) + K_inf * strain_vol + p_current
          stress_visc(2) = stress_visc(2) + K_inf * strain_vol + p_current
        end if
      case(3)
        if (ntens >= 3) then
          do j = 1, 3
            stress_visc(j) = stress_visc(j) + K_inf * strain_vol + p_current
          end do
        end if
    end select

  end subroutine U259_ComputePronyViscoelasticStress

  subroutine U2_ComputeStressTemperatureD(alpha_thermal, PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, ddsddt)
    real(wp), intent(in)  :: alpha_thermal, PH_MAT_E, nu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: ddsddt(6)

    real(wp) :: lambda, mu
    integer(i4) :: i

    ddsddt = ZERO

    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    do i = 1, min(ndim, ntens)
      ddsddt(i) = -(lambda + TWO * mu) * alpha_thermal
    end do

  end subroutine U260_ComputeStressTemperatureDerivative

  subroutine U2_ComputeTemperatureDepende(temp, T_ref, Q_activation, R_gas, &
                                               E_ref, stress_y0_ref, H_ref, eps0_ref, &
                                               PH_MAT_E, sigma_y0, H, eps0)
    real(wp), intent(in)  :: temp, T_ref, Q_activation, R_gas
    real(wp), intent(in)  :: E_ref, stress_y0_ref, H_ref, eps0_ref
    real(wp), intent(out) :: PH_MAT_E, sigma_y0, H, eps0

    real(wp) :: temp_factor

    temp_factor = exp(Q_activation / R_gas * (ONE/temp - ONE/T_ref))

    PH_MAT_E = E_ref * temp_factor
    sigma_y0 = stress_y0_ref * temp_factor
    H = H_ref * temp_factor
    eps0 = eps0_ref * temp_factor

  end subroutine U260_ComputeTemperatureDependentParameters

  subroutine U2_ComputeThermoelectricStra(Q_te, delta_temp, E_field, ndim, nshr, ntens, analysis_type, strain_te)
    real(wp), intent(in)  :: Q_te, delta_temp
    real(wp), intent(in)  :: E_field(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_te(6)

    real(wp) :: E_mag
    integer(i4) :: i

    strain_te = ZERO

    E_mag = sqrt(dot_product(E_field, E_field))

    if (E_mag > TOL) then
      select case(ndim)
        case(1)
          if (ntens >= 1) strain_te(1) = Q_te * delta_temp * E_mag
        case(2)
          if (ntens >= 2) then
            strain_te(1) = Q_te * delta_temp * E_mag
            strain_te(2) = Q_te * delta_temp * E_mag
            if (analysis_type == 3 .and. ntens >= 3) then
              strain_te(3) = Q_te * delta_temp * E_mag
            end if
          end if
        case(3)
          if (ntens >= 3) then
            do i = 1, 3
              strain_te(i) = Q_te * delta_temp * E_mag
            end do
          end if
      end select
    end if

  end subroutine U262_ComputeThermoelectricStrain

  subroutine U2_ComputeThermomagneticStra(S_tm, delta_temp, B, ndim, nshr, ntens, analysis_type, strain_tm)
    real(wp), intent(in)  :: S_tm, delta_temp
    real(wp), intent(in)  :: B(3)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: strain_tm(6)

    real(wp) :: B_mag
    integer(i4) :: i

    strain_tm = ZERO

    B_mag = sqrt(dot_product(B, B))

    if (B_mag > TOL) then
      select case(ndim)
        case(1)
          if (ntens >= 1) strain_tm(1) = S_tm * delta_temp * B_mag
        case(2)
          if (ntens >= 2) then
            strain_tm(1) = S_tm * delta_temp * B_mag
            strain_tm(2) = S_tm * delta_temp * B_mag
            if (analysis_type == 3 .and. ntens >= 3) then
              strain_tm(3) = S_tm * delta_temp * B_mag
            end if
          end if
        case(3)
          if (ntens >= 3) then
            do i = 1, 3
              strain_tm(i) = S_tm * delta_temp * B_mag
            end do
          end if
      end select
    end if

  end subroutine U262_ComputeThermomagneticStrain

  subroutine U2_ComputeViscoplasticStrain(delta_lambda, sigma_eqv, s_dev, &
                                              ndim, nshr, ntens, analysis_type, dstra_viscoplas)
    real(wp), intent(in)  :: delta_lambda, sigma_eqv, s_dev(6)
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: dstra_viscoplas(6)

    integer(i4) :: i

    dstra_viscoplas = ZERO

    if (sigma_eqv > TOL) then
      do i = 1, ntens
        dstra_viscoplas(i) = delta_lambda * (THREE/TWO) * s_dev(i) / sigma_eqv
      end do
    end if

  end subroutine U260_ComputeViscoplasticStrainIncr

  subroutine U2_ComputeViscoplasticStress(stress_trial, delta_lambda, sigma_eqv, s_dev, &
                                    lambda, mu, ndim, nshr, ntens, analysis_type, stress_elastic)
    real(wp), intent(in)  :: stress_trial(6), delta_lambda, sigma_eqv, s_dev(6)
    real(wp), intent(in)  :: lambda, mu
    integer(i4), intent(in)  :: ndim, nshr, ntens, analysis_type
    real(wp), intent(out) :: stress_elastic(6)

    integer(i4) :: i

    stress_elastic = stress_trial

    if (delta_lambda > TOL .and. sigma_eqv > TOL) then
      do i = 1, ntens
        stress_elastic(i) = stress_trial(i) - delta_lambda * (THREE/TWO) * mu * s_dev(i) / sigma_eqv
      end do
    end if

  end subroutine U260_ComputeViscoplasticStress

  subroutine U2_ComputeViscosityCoefficie(sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0, eta)
    real(wp), intent(in)  :: sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0
    real(wp), intent(out) :: eta

    real(wp) :: overstress

    overstress = max(sigma_eqv - sigma_y, ZERO)

    if (overstress > TOL .and. eps_eqv_rate > TOL) then
      eta = overstress / (eps_eqv_rate / eps0)**m_rate
    else
      eta = 1.0e10_wp
    end if

  end subroutine U260_ComputeViscosityCoefficient



  SUBROUTINE UF_MultiscaleDamage_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: E_micro, nu_micro
    real(wp) :: E_meso, nu_meso
    real(wp) :: E_macro, nu_macro
    real(wp) :: sigma_y_micro, sigma_y_meso, sigma_y_macro
    real(wp) :: H_micro, H_meso, H_macro
    real(wp) :: alpha_damage_mi, alpha_damage_me, alpha_damage_ma
    real(wp) :: beta_damage_mic, beta_damage_mes, beta_damage_mac
    real(wp) :: sigma_critical, sigma_critical, sigma_critical
    real(wp) :: G_c_micro, G_c_meso, G_c_macro
    real(wp) :: alpha_thermal_m, alpha_thermal_m, alpha_thermal_m
    real(wp) :: c_p_micro, c_p_meso, c_p_macro
    real(wp) :: k_thermal_micro, k_thermal_meso, k_thermal_macro
    real(wp) :: length_scale_mi, length_scale_me, length_scale_ma
    real(wp) :: volume_fraction, volume_fraction, volume_fraction

    real(wp) :: strain_plastic(6), strain_plastic(6), strain_plastic(6)
    real(wp) :: damage_variable, damage_variable, damage_variable
    real(wp) :: temp_old, time_old
    real(wp) :: energy_density, energy_density, energy_density
    real(wp) :: stress_micro_ol(6), stress_meso_old(6), stress_macro_ol(6)

    real(wp) :: strain_total(6), strain_elas_mic(6), strain_elas_mes(6), strain_elas_mac(6)
    real(wp) :: strain_plastic(6), strain_plastic(6), strain_plastic(6)
    real(wp) :: strain_thermal(6), strain_thermal(6), strain_thermal(6)
    real(wp) :: dstra_plastic_m(6), dstra_plastic_m(6), dstra_plastic_m(6)

    real(wp) :: stress_trial_mi(6), stress_trial_me(6), stress_trial_ma(6)
    real(wp) :: stress_effectiv(6), stress_micro(6), stress_meso(6), stress_macro(6)
    real(wp) :: s_dev_micro(6), p_micro, s_dev_meso(6), p_meso, s_dev_macro(6), p_macro
    real(wp) :: sigma_eqv_micro, sigma_eqv_meso, sigma_eqv_macro

    real(wp) :: damage_variable, damage_variable, damage_variable
    real(wp) :: damage_rate_mic, damage_rate_mes, damage_rate_mac
    real(wp) :: damage_factor_m, damage_factor_m, damage_factor_m

    real(wp) :: D_elastic_micro(6,6), D_elastic_meso(6,6), D_elastic_macro(6,6)
    real(wp) :: D_damaged_micro(6,6), D_damaged_meso(6,6), D_damaged_macro(6,6)
    real(wp) :: D_coupled(6,6)

    integer(i4) :: analysis_type, i, j, ntens
    real(wp) :: dt
    real(wp) :: thermal_energy, thermal_energy, thermal_energy
    real(wp) :: mech_energy_mic, mech_energy_mes, mech_energy_mac
    real(wp) :: damage_energy_m, damage_energy_m, damage_energy_m
    real(wp) :: volume_fraction

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    !-------------------------------------------------------------------
    ! Determine Tensor Dimension
    !-------------------------------------------------------------------
    ntens = ndir + nshr

    !-------------------------------------------------------------------
    ! Valid Mat Parameters
    !-------------------------------------------------------------------
    if (nprops < 39) then
            CALL log_error('MD_MatLib_Plastic_MultiscaleDamage', 'Insufficient Mat parameters')
      status%status_code = IF_STATUS_INVALID
      RETURN
        end if

    E_micro = props(1)
    nu_micro = props(2)
    E_meso = props(3)
    nu_meso = props(4)
    E_macro = props(5)
    nu_macro = props(6)
    sigma_y_micro = props(7)
    sigma_y_meso = props(8)
    sigma_y_macro = props(9)
    H_micro = props(10)
    H_meso = props(11)
    H_macro = props(12)
    alpha_damage_mi = props(13)
    alpha_damage_me = props(14)
    alpha_damage_ma = props(15)
    beta_damage_mic = props(16)
    beta_damage_mes = props(17)
    beta_damage_mac = props(18)
    sigma_critical = props(19)
    sigma_critical = props(20)
    sigma_critical = props(21)
    G_c_micro = props(22)
    G_c_meso = props(23)
    G_c_macro = props(24)
    alpha_thermal_m = props(25)
    alpha_thermal_m = props(26)
    alpha_thermal_m = props(27)
    c_p_micro = props(28)
    c_p_meso = props(29)
    c_p_macro = props(30)
    k_thermal_micro = props(31)
    k_thermal_meso = props(32)
    k_thermal_macro = props(33)
    length_scale_mi = props(34)
    length_scale_me = props(35)
    length_scale_ma = props(36)
    volume_fraction = props(37)
    volume_fraction = props(38)
    volume_fraction = props(39)

    if (E_micro <= ZERO .or. E_meso <= ZERO .or. E_macro <= ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'E_micro must be greater than 0')
      return
      return
    end if

    if (nu_micro < -ONE .or. nu_micro >= HALF .or. nu_meso < -ONE .or. nu_meso >= HALF .or. nu_macro < -ONE .or. nu_macro >= HALF) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'nu must be in range [-1, 0.5)')
      return
    end if

    if (sigma_y_micro < ZERO .or. sigma_y_meso < ZERO .or. sigma_y_macro < ZERO) then
      call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'sigma_y must be non-negative')
      return
    end if

    if (H_micro < ZERO .or. H_meso < ZERO .or. H_macro < ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'H_micro must be non-negative')
      return
      return
    end if

    if (alpha_damage_mi < ZERO .or. alpha_damage_me < ZERO .or. alpha_damage_ma < ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'alpha_damage_mi must be non-negative')
      return
      return
    end if

    if (beta_damage_mic < ZERO .or. beta_damage_mes < ZERO .or. beta_damage_mac < ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'beta_damage_mic must be non-negative')
      return
      return
    end if

    if (sigma_critical < ZERO .or. sigma_critical < ZERO .or. sigma_critical < ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'sigma_critical must be non-negative')
      return
      return
    end if

    if (G_c_micro < ZERO .or. G_c_meso < ZERO .or. G_c_macro < ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'G_c must be non-negative')
      return
    end if

    if (alpha_thermal_m < ZERO .or. alpha_thermal_m < ZERO .or. alpha_thermal_m < ZERO) then
      call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'alpha_thermal must be non-negative')
      return
    end if

    if (c_p_micro < ZERO .or. c_p_meso < ZERO .or. c_p_macro < ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'c_p must be non-negative')
      return
    end if

    if (k_thermal_micro < ZERO .or. k_thermal_meso < ZERO .or. k_thermal_macro < ZERO) then
      call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'k_thermal must be positive')
      return
    end if

    if (length_scale_mi <= ZERO .or. length_scale_me <= ZERO .or. length_scale_ma <= ZERO) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'length_scale_mi must be greater than 0')
      return
      return
    end if

    if (volume_fraction < ZERO .or. volume_fraction > ONE .or. volume_fraction < ZERO .or. volume_fraction > ONE .or. volume_fraction < ZERO .or. volume_fraction > ONE) then
            call log_error('MD_MatLib_Plastic_MultiscaleDamage', 'volume_fraction must be in range [0, 1]')
      return
    end if

    volume_fraction = volume_fraction + volume_fraction + volume_fraction
    if (volume_fraction < 1.0e-10_wp) then
      volume_fraction = ONE
      volume_fraction = ZERO
      volume_fraction = ZERO
    else
      volume_fraction = volume_fraction / volume_fraction
      volume_fraction = volume_fraction / volume_fraction
      volume_fraction = volume_fraction / volume_fraction
    end if

    analysis_type = 0
    ndim = ndi

    if (nstatv >= 1) then
      if (statev(1) >= ONE .and. statev(1) <= THREE) then
        analysis_type = nint(statev(1))
      else
        analysis_type = detect_analysis_type(ndim, nshr)
        statev(1) = real(analysis_type, wp)
      end if
    end if

    strain_plastic = ZERO
    strain_plastic = ZERO
    strain_plastic = ZERO
    damage_variable = ZERO
    damage_variable = ZERO
    damage_variable = ZERO
    temp_old = 300.0_wp
    time_old = time(1) - dtime
    energy_density = ZERO
    energy_density = ZERO
    energy_density = ZERO
    stress_micro_ol = ZERO
    stress_meso_old = ZERO
    stress_macro_ol = ZERO

    if (nstatv >= 7) then
      do i = 1, 6
        if (1 + i <= nstatv) then
          strain_plastic(i) = statev(1 + i)
        end if
      end do
    end if

    if (nstatv >= 13) then
      do i = 1, 6
        if (7 + i <= nstatv) then
          strain_plastic(i) = statev(7 + i)
        end if
      end do
    end if

    if (nstatv >= 19) then
      do i = 1, 6
        if (13 + i <= nstatv) then
          strain_plastic(i) = statev(13 + i)
        end if
      end do
    end if

    if (nstatv >= 20) damage_variable = statev(20)
    if (nstatv >= 21) damage_variable = statev(21)
    if (nstatv >= 22) damage_variable = statev(22)
    if (nstatv >= 23) temp_old = statev(23)
    if (nstatv >= 24) time_old = statev(24)
    if (nstatv >= 25) energy_density = statev(25)
    if (nstatv >= 26) energy_density = statev(26)
    if (nstatv >= 27) energy_density = statev(27)

    dt = time(1) - time_old
    if (dt < ZERO) dt = dtime

    strain_total = stran + dstran

    call U261_ComputeThermalStrain(alpha_thermal_m, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)
    call U261_ComputeThermalStrain(alpha_thermal_m, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)
    call U261_ComputeThermalStrain(alpha_thermal_m, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)

    strain_plastic = strain_plastic
    strain_plastic = strain_plastic
    strain_plastic = strain_plastic

    call U261_BuildElasticStiffness(E_micro, nu_micro, ndim, nshr, ntens, analysis_type, D_elastic_micro)
    call U261_BuildElasticStiffness(E_meso, nu_meso, ndim, nshr, ntens, analysis_type, D_elastic_meso)
    call U261_BuildElasticStiffness(E_macro, nu_macro, ndim, nshr, ntens, analysis_type, D_elastic_macro)

    strain_elas_mic = strain_total - strain_thermal - strain_plastic
    strain_elas_mes = strain_total - strain_thermal - strain_plastic
    strain_elas_mac = strain_total - strain_thermal - strain_plastic

    stress_trial_mi = ZERO
    stress_trial_me = ZERO
    stress_trial_ma = ZERO

    do i = 1, 6
      do j = 1, 6
        stress_trial_mi(i) = stress_trial_mi(i) + D_elastic_micro(i,j) * strain_elas_mic(j)
        stress_trial_me(i) = stress_trial_me(i) + D_elastic_meso(i,j) * strain_elas_mes(j)
        stress_trial_ma(i) = stress_trial_ma(i) + D_elastic_macro(i,j) * strain_elas_mac(j)
      end do
    end do

    call U261_ComputeEquivalentStress(stress_trial_mi, ndim, nshr, ntens, analysis_type, sigma_eqv_micro)
    call U261_ComputeEquivalentStress(stress_trial_me, ndim, nshr, ntens, analysis_type, sigma_eqv_meso)
    call U261_ComputeEquivalentStress(stress_trial_ma, ndim, nshr, ntens, analysis_type, sigma_eqv_macro)

    call U261_ComputePlasticStrainIncrWithScaleEffect(stress_trial_mi, strain_plastic, &
                                                            sigma_y_micro, H_micro, length_scale_mi, &
                                                            volume_fraction, ndim, nshr, ntens, analysis_type, &
                                                            dstra_plastic_m, strain_plastic)

    call U261_ComputePlasticStrainIncrWithScaleEffect(stress_trial_me, strain_plastic, &
                                                            sigma_y_meso, H_meso, length_scale_me, &
                                                            volume_fraction, ndim, nshr, ntens, analysis_type, &
                                                            dstra_plastic_m, strain_plastic)

    call U261_ComputePlasticStrainIncrWithScaleEffect(stress_trial_ma, strain_plastic, &
                                                            sigma_y_macro, H_macro, length_scale_ma, &
                                                            volume_fraction, ndim, nshr, ntens, analysis_type, &
                                                            dstra_plastic_m, strain_plastic)

    strain_elas_mic = strain_elas_mic - dstra_plastic_m
    strain_elas_mes = strain_elas_mes - dstra_plastic_m
    strain_elas_mac = strain_elas_mac - dstra_plastic_m

    stress_micro = ZERO
    stress_meso = ZERO
    stress_macro = ZERO

    do i = 1, 6
      do j = 1, 6
        stress_micro(i) = stress_micro(i) + D_elastic_micro(i,j) * strain_elas_mic(j)
        stress_meso(i) = stress_meso(i) + D_elastic_meso(i,j) * strain_elas_mes(j)
        stress_macro(i) = stress_macro(i) + D_elastic_macro(i,j) * strain_elas_mac(j)
      end do
    end do

    call U261_ComputeDmgVarWithScaleEffect(stress_micro, sigma_critical, alpha_damage_mi, &
                                               beta_damage_mic, G_c_micro, length_scale_mi, &
                                               volume_fraction, dt, strain_plastic, &
                                               damage_variable, damage_variable, damage_rate_mic)

    call U261_ComputeDmgVarWithScaleEffect(stress_meso, sigma_critical, alpha_damage_me, &
                                               beta_damage_mes, G_c_meso, length_scale_me, &
                                               volume_fraction, dt, strain_plastic, &
                                               damage_variable, damage_variable, damage_rate_mes)

    call U261_ComputeDmgVarWithScaleEffect(stress_macro, sigma_critical, alpha_damage_ma, &
                                               beta_damage_mac, G_c_macro, length_scale_ma, &
                                               volume_fraction, dt, strain_plastic, &
                                               damage_variable, damage_variable, damage_rate_mac)

    damage_factor_m = ONE - exp(-alpha_damage_mi * damage_variable**beta_damage_mic)
    damage_factor_m = ONE - exp(-alpha_damage_me * damage_variable**beta_damage_mes)
    damage_factor_m = ONE - exp(-alpha_damage_ma * damage_variable**beta_damage_mac)

    do i = 1, ntens
      stress_micro(i) = stress_micro(i) * (ONE - damage_factor_m)
      stress_meso(i) = stress_meso(i) * (ONE - damage_factor_m)
      stress_macro(i) = stress_macro(i) * (ONE - damage_factor_m)
    end do

    call U261_BuildDamagedStiffness(D_elastic_micro, damage_factor_m, damage_variable, &
                                  stress_micro, strain_elas_mic, ndim, nshr, ntens, analysis_type, D_damaged_micro)

    call U261_BuildDamagedStiffness(D_elastic_meso, damage_factor_m, damage_variable, &
                                  stress_meso, strain_elas_mes, ndim, nshr, ntens, analysis_type, D_damaged_meso)

    call U261_BuildDamagedStiffness(D_elastic_macro, damage_factor_m, damage_variable, &
                                  stress_macro, strain_elas_mac, ndim, nshr, ntens, analysis_type, D_damaged_macro)

    thermal_energy = HALF * c_p_micro * (temp**2 - temp_old**2) * dt
    thermal_energy = HALF * c_p_meso * (temp**2 - temp_old**2) * dt
    thermal_energy = HALF * c_p_macro * (temp**2 - temp_old**2) * dt

    mech_energy_mic = HALF * dot_product(stress_micro, strain_elas_mic)
    mech_energy_mes = HALF * dot_product(stress_meso, strain_elas_mes)
    mech_energy_mac = HALF * dot_product(stress_macro, strain_elas_mac)

    damage_energy_m = G_c_micro * damage_rate_mic * dt
    damage_energy_m = G_c_meso * damage_rate_mes * dt
    damage_energy_m = G_c_macro * damage_rate_mac * dt

    do i = 1, ntens
      stress_effectiv(i) = volume_fraction * stress_micro(i) + &
                       volume_fraction * stress_meso(i) + &
                       volume_fraction * stress_macro(i)
    end do

    D_coupled = ZERO
    do i = 1, ntens
      do j = 1, ntens
        D_coupled(i,j) = volume_fraction * D_damaged_micro(i,j) + &
                 volume_fraction * D_damaged_meso(i,j) + &
                 volume_fraction * D_damaged_macro(i,j)
      end do
    end do

    stress = stress_effectiv
    ddsdde = D_coupled

    sse = volume_fraction * mech_energy_mic + &
           volume_fraction * mech_energy_mes + &
           volume_fraction * mech_energy_mac

    scd = volume_fraction * (thermal_energy + damage_energy_m) + &
           volume_fraction * (thermal_energy + damage_energy_m) + &
           volume_fraction * (thermal_energy + damage_energy_m)

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 7) then
      do i = 1, 6
        if (1 + i <= nstatv) then
          statev(1 + i) = strain_plastic(i)
        end if
      end do
    end if
    if (nstatv >= 13) then
      do i = 1, 6
        if (7 + i <= nstatv) then
          statev(7 + i) = strain_plastic(i)
        end if
      end do
    end if
    if (nstatv >= 19) then
      do i = 1, 6
        if (13 + i <= nstatv) then
          statev(13 + i) = strain_plastic(i)
        end if
      end do
    end if
    if (nstatv >= 20) statev(20) = damage_variable
    if (nstatv >= 21) statev(21) = damage_variable
    if (nstatv >= 22) statev(22) = damage_variable
    if (nstatv >= 23) statev(23) = temp
    if (nstatv >= 24) statev(24) = time(1)
    if (nstatv >= 25) statev(25) = mech_energy_mic + thermal_energy + damage_energy_m
    if (nstatv >= 26) statev(26) = mech_energy_mes + thermal_energy + damage_energy_m
    if (nstatv >= 27) statev(27) = mech_energy_mac + thermal_energy + damage_energy_m

  END SUBROUTINE UF_MultiscaleDamage_UMAT

  SUBROUTINE UF_ThermoElectroMagnetoMechanical_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: PH_MAT_E, nu
    real(wp) :: alpha_thermal
    real(wp) :: k_thermal
    real(wp) :: c_p
    real(wp) :: sigma_e
    real(wp) :: mu_r
    real(wp) :: epsilon_r
    real(wp) :: alpha_magnetost
    real(wp) :: Q_THERMOELECTRI
    real(wp) :: S_THERMOMAGNETI
    real(wp) :: alpha_ed
    real(wp) :: alpha_piezoelec(3,3)

    real(wp) :: B_old(3), H_old(3), D_old(3), E_field_old(3), J_old(3)
    real(wp) :: temp_old, time_old
    real(wp) :: magnetization_o(3), polarization_ol(3)
    real(wp) :: energy_density

    real(wp) :: B(3), H(3), D(3), E_field(3), J(3)
    real(wp) :: magnetization(3), polarization(3)
    real(wp) :: dB(3), dH(3), dD(3), dE_field(3), dJ(3)

    real(wp) :: strain_total(6), strain_elastic(6), strain_thermal(6)
    real(wp) :: strain_piezoele(6), strain_magnetos(6)
    real(wp) :: strain_ed(6), strain_thermoel(6), strain_thermoma(6)

    real(wp) :: stress_trial(6), stress_effectiv(6)
    real(wp) :: stress_piezoele(6), stress_magnetic(6), stress_thermal(6)
    real(wp) :: s_dev(6), p

    real(wp) :: D_elastic(6,6), D_coupled(6,6)

    integer(i4) :: analysis_type, i, j, ntens
    real(wp) :: dt
    real(wp) :: electric_energy, magnetic_energy
    real(wp) :: thermal_energy, mech_energy
    real(wp) :: joule_heating
    real(wp) :: heat_flux(3)

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    !-------------------------------------------------------------------
    ! Determine Tensor Dimension
    !-------------------------------------------------------------------
    ntens = ndir + nshr

    !-------------------------------------------------------------------
    ! Valid Mat Parameters
    !-------------------------------------------------------------------
    if (nprops < 21) then
            CALL log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'Insufficient Mat parameters')
      status%status_code = IF_STATUS_INVALID
      RETURN
        end if

    PH_MAT_E = props(1)
    nu = props(2)
    alpha_thermal = props(3)
    k_thermal = props(4)
    c_p = props(5)
    sigma_e = props(6)
    mu_r = props(7)
    epsilon_r = props(8)
    alpha_magnetost = props(9)
    Q_THERMOELECTRI = props(10)
    S_THERMOMAGNETI = props(11)
    alpha_ed = props(12)

    alpha_piezoelec = ZERO
    if (nprops >= 21) then
      do i = 1, 3
        do j = 1, 3
          if (12 + (i-1)*3 + j <= nprops) then
            alpha_piezoelec(i,j) = props(12 + (i-1)*3 + j)
          end if
        end do
      end do
    end if

    if (PH_MAT_E <= ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'PH_MAT_E must be greater than 0')
      return
      return
    end if

    if (nu < -ONE .or. nu >= HALF) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'nu must be in range [-1, 0.5)')
      return
    end if

    if (alpha_thermal < ZERO) then
      call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'alpha_thermal must be non-negative')
      return
    end if

    if (k_thermal < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'k_thermal must be non-negative')
      return
      return
    end if

    if (c_p < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'c_p must be non-negative')
      return
      return
    end if

    if (sigma_e < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'sigma_e must be non-negative')
      return
      return
    end if

    if (mu_r < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'mu_r must be non-negative')
      return
      return
    end if

    if (epsilon_r < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'epsilon_r must be non-negative')
      return
      return
    end if

    !-------------------------------------------------------------------
    ! Determine Analysis Type
    !-------------------------------------------------------------------
    analysis_type = U262_DetectAnalysisType(ndim, nshr)

    required_statev = 25

    if (nstatv < required_statev) then
      call log_error('MD_MatLib_Plastic_ThermoElectroMagnetoMechanical', 'Insufficient statev')
      return
    end if

    B_old = ZERO
    H_old = ZERO
    D_old = ZERO
    E_field_old = ZERO
    J_old = ZERO
    temp_old = 293.15_wp
    time_old = time(1) - dtime
    magnetization_o = ZERO
    polarization_ol = ZERO
    energy_density = ZERO

    if (nstatv >= 4) then
      do i = 1, 3
        if (1 + i <= nstatv) then
          B_old(i) = statev(1 + i)
        end if
      end do
    end if
    if (nstatv >= 7) then
      do i = 1, 3
        if (4 + i <= nstatv) then
          H_old(i) = statev(4 + i)
        end if
      end do
    end if
    if (nstatv >= 10) then
      do i = 1, 3
        if (7 + i <= nstatv) then
          D_old(i) = statev(7 + i)
        end if
      end do
    end if
    if (nstatv >= 13) then
      do i = 1, 3
        if (10 + i <= nstatv) then
          E_field_old(i) = statev(10 + i)
        end if
      end do
    end if
    if (nstatv >= 16) then
      do i = 1, 3
        if (13 + i <= nstatv) then
          J_old(i) = statev(13 + i)
        end if
      end do
    end if
    if (nstatv >= 17) temp_old = statev(17)
    if (nstatv >= 18) time_old = statev(18)
    if (nstatv >= 21) then
      do i = 1, 3
        if (18 + i <= nstatv) then
          magnetization_o(i) = statev(18 + i)
        end if
      end do
    end if
    if (nstatv >= 24) then
      do i = 1, 3
        if (21 + i <= nstatv) then
          polarization_ol(i) = statev(21 + i)
        end if
      end do
    end if
    if (nstatv >= 25) energy_density = statev(25)

    dt = time(1) - time_old
    if (dt < ZERO) dt = dtime

    B = B_old
    if (size(predef) >= 3) then
      B(1) = predef(1)
      B(2) = predef(2)
      B(3) = predef(3)
    end if
    dB = B - B_old

    H = H_old
    if (size(predef) >= 6) then
      H(1) = predef(4)
      H(2) = predef(5)
      H(3) = predef(6)
    end if
    dH = H - H_old

    D = D_old
    if (size(predef) >= 9) then
      D(1) = predef(7)
      D(2) = predef(8)
      D(3) = predef(9)
    end if
    dD = D - D_old

    E_field = E_field_old
    if (size(predef) >= 12) then
      E_field(1) = predef(10)
      E_field(2) = predef(11)
      E_field(3) = predef(12)
    end if
    dE_field = E_field - E_field_old

    J = J_old
    if (size(predef) >= 15) then
      J(1) = predef(13)
      J(2) = predef(14)
      J(3) = predef(15)
    end if
    dJ = J - J_old

    strain_total = stran + dstran

    call U262_ComputeThermalStrain(alpha_thermal, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)
    call U262_ComputePiezoelectricStrain(alpha_piezoelec, E_field, ndim, nshr, ntens, analysis_type, strain_piezoele)
    call U262_ComputeMagnetostrictionStrain(alpha_magnetost, B, H, ndim, nshr, ntens, analysis_type, strain_magnetos)
    call U262_ComputeElectrostrictiveStrain(alpha_ed, E_field, ndim, nshr, ntens, analysis_type, strain_ed)
    call U262_ComputeThermoelectricStrain(Q_THERMOELECTRI, temp - temp_old, E_field, ndim, nshr, ntens, analysis_type, strain_thermoel)
    call U262_ComputeThermomagneticStrain(S_THERMOMAGNETI, temp - temp_old, B, ndim, nshr, ntens, analysis_type, strain_thermoma)

    do i = 1, ntens
      strain_elastic(i) = strain_total(i) - strain_thermal(i) - strain_piezoele(i) - &
                    strain_magnetos(i) - strain_ed(i) - strain_thermoel(i) - strain_thermoma(i)
    end do

    call U262_BuildElasticStiffness(PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, D_elastic)

    stress_trial = ZERO
    do i = 1, 6
      do j = 1, 6
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
      end do
    end do

    call compute_piezoelectric_stress(alpha_piezoelec, E_field, ndi, analysis_type, stress_piezoele)
    call compute_electromagnetic_stress(B, H, J, ndi, analysis_type, stress_magnetic)
    call compute_thermal_stress(D_elastic, strain_thermal, ndi, analysis_type, stress_thermal)

    stress_effectiv = stress_trial + stress_piezoele + stress_magnetic + stress_thermal

    call compute_magnetization(B, H, mu_r, MU0, magnetization)
    call compute_polarization(D, E_field, epsilon_r, EPSILON0, polarization)
    call compute_current_density(sigma_e, E_field, temp, temp_old, Q_THERMOELECTRI, J)

    call compute_coupled_energy(B, H, D, E_field, J, dt, temp, temp_old, &
                             electric_energy, magnetic_energy, thermal_energy, mech_energy, joule_heating)

    call build_coupled_stiffness(D_elastic, alpha_piezoelec, alpha_magnetost, &
                             alpha_ed, Q_THERMOELECTRI, S_THERMOMAGNETI, B, H, E_field, &
                             dt, ndi, analysis_type, D_coupled)

    call U262_RegularizeStiffMat(D_coupled, 6)

    call ComputeHeatFlux(k_thermal, temp, coords, heat_flux)

    stress = stress_effectiv
    ddsdde = D_coupled

    sse = HALF * dot_product(stress_effectiv, strain_elastic) + magnetic_energy + electric_energy
    scd = thermal_energy + joule_heating

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 4) then
      do i = 1, 3
        if (1 + i <= nstatv) then
          statev(1 + i) = B(i)
        end if
      end do
    end if
    if (nstatv >= 7) then
      do i = 1, 3
        if (4 + i <= nstatv) then
          statev(4 + i) = H(i)
        end if
      end do
    end if
    if (nstatv >= 10) then
      do i = 1, 3
        if (7 + i <= nstatv) then
          statev(7 + i) = D(i)
        end if
      end do
    end if
    if (nstatv >= 13) then
      do i = 1, 3
        if (10 + i <= nstatv) then
          statev(10 + i) = E_field(i)
        end if
      end do
    end if
    if (nstatv >= 16) then
      do i = 1, 3
        if (13 + i <= nstatv) then
          statev(13 + i) = J(i)
        end if
      end do
    end if
    if (nstatv >= 17) statev(17) = temp
    if (nstatv >= 18) statev(18) = time(1)
    if (nstatv >= 21) then
      do i = 1, 3
        if (18 + i <= nstatv) then
          statev(18 + i) = magnetization(i)
        end if
      end do
    end if
    if (nstatv >= 24) then
      do i = 1, 3
        if (21 + i <= nstatv) then
          statev(21 + i) = polarization(i)
        end if
      end do
    end if
    if (nstatv >= 25) statev(25) = sse + scd

  END SUBROUTINE UF_ThermoElectroMagnetoMechanical_UMAT

  SUBROUTINE UF_ThermoViscoplastic_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: E_ref, nu
    real(wp) :: stress_y0_ref, H_ref
    real(wp) :: m_rate, eps0_ref
    real(wp) :: Q_activation, R_gas, T_ref
    real(wp) :: alpha_thermal

    real(wp) :: PH_MAT_E, nu_T
    real(wp) :: sigma_y0, H
    real(wp) :: eps0

    real(wp) :: lambda, mu

    real(wp) :: D_elastic(6,6), D_viscoplastic(6,6)

    real(wp) :: strain_total(6), strain_elastic(6), strain_viscopla(6)
    real(wp) :: dstra_viscoplas(6), strain_thermal(6)

    real(wp) :: stress_trial(6), stress_elastic(6)

    real(wp) :: eps_eqv_viscopl, temp_old, strain_rate_old(6)

    integer(i4) :: analysis_type, i, j, ntens
    real(wp) :: delta_lambda, sigma_eqv, s_dev(6), p
    real(wp) :: sigma_y, eps_eqv_viscopl
    real(wp) :: strain_rate(6), eps_eqv_rate, eta

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    !-------------------------------------------------------------------
    ! Determine Tensor Dimension
    !-------------------------------------------------------------------
    ntens = ndir + nshr

    !-------------------------------------------------------------------
    ! Valid Mat Parameters
    !-------------------------------------------------------------------
    if (nprops < 10) then
            CALL log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'Insufficient Mat parameters')
      status%status_code = IF_STATUS_INVALID
      RETURN
        end if

    E_ref = props(1)
    nu = props(2)
    stress_y0_ref = props(3)
    H_ref = props(4)
    m_rate = props(5)
    eps0_ref = props(6)
    Q_activation = props(7)
    R_gas = props(8)
    T_ref = props(9)

    alpha_thermal = ZERO
    if (nprops >= 10) alpha_thermal = props(10)

    if (E_ref <= ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'E_ref must be greater than 0')
      return
      return
    end if

    if (nu < -ONE .or. nu >= HALF) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'nu must be in range [-1, 0.5)')
      return
    end if

    if (stress_y0_ref <= ZERO) then
      call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'stress_y0_ref must be positive')
      return
    end if

    if (H_ref < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'H_ref must be non-negative')
      return
      return
    end if

    if (m_rate < ZERO .or. m_rate > ONE) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'm_rate must be in range [0, 1]')
      return
    end if

    if (eps0_ref <= ZERO) then
      call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'eps0_ref must be positive')
      return
    end if

    if (Q_activation < ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'Q_activation must be non-negative')
      return
      return
    end if

    if (R_gas <= ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'R_gas must be greater than 0')
      return
      return
    end if

    if (T_ref <= ZERO) then
            call log_error('MD_MatLib_Plastic_ThermoViscoplastic', 'T_ref must be greater than 0')
      return
      return
    end if

    !-------------------------------------------------------------------
    ! Determine Analysis Type
    !-------------------------------------------------------------------
    analysis_type = U260_DetectAnalysisType(ndim, nshr)

    eps_eqv_viscopl = ZERO
    temp_old = T_ref
    strain_viscopla = ZERO
    strain_rate_old = ZERO

    if (nstatv >= 2) eps_eqv_viscopl = statev(2)
    if (nstatv >= 3) temp_old = statev(3)

    if (nstatv >= 9) then
      do i = 1, 6
        if (3 + i <= nstatv) then
          strain_viscopla(i) = statev(3 + i)
        end if
      end do
    end if

    if (nstatv >= 15) then
      do i = 1, 6
        if (9 + i <= nstatv) then
          strain_rate_old(i) = statev(9 + i)
        end if
      end do
    end if

    call U260_ComputeTemperatureDependentParameters(temp, T_ref, Q_activation, R_gas, &
                                               E_ref, stress_y0_ref, H_ref, eps0_ref, &
                                               PH_MAT_E, sigma_y0, H, eps0)

    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    call U260_BuildElasticStiffness(lambda, mu, ndim, nshr, ntens, analysis_type, D_elastic)

    strain_total = stran + dstran

    call U260_ComputeThermalStrain(alpha_thermal, temp - T_ref, ndim, nshr, ntens, analysis_type, strain_thermal)

    do i = 1, ntens
      strain_elastic(i) = strain_total(i) - strain_viscopla(i) - strain_thermal(i)
    end do

    call U260_ComputeStrainRate(dstran, dtime, strain_rate)

    call U260_ComputeEquivalentStrainRate(strain_rate, ndim, nshr, ntens, analysis_type, eps_eqv_rate)

    stress_trial = ZERO
    do i = 1, 6
      do j = 1, 6
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
      end do
    end do

    call U260_ComputeStressInvariants(stress_trial, ndim, nshr, ntens, analysis_type, p, s_dev)
    call U260_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)

    sigma_y = sigma_y0 + H * eps_eqv_viscopl

    real(wp) :: rate_factor
    if (eps_eqv_rate > TOL .and. sigma_eqv > TOL) then
      rate_factor = (eps_eqv_rate / eps0)**m_rate
      sigma_y = sigma_y * rate_factor
    end if

    call U260_ComputeViscosityCoefficient(sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0, eta)

    delta_lambda = ZERO
    if (sigma_eqv > sigma_y .and. eta > TOL) then
      delta_lambda = (sigma_eqv - sigma_y) / eta
    end if

    call U260_ComputeViscoplasticStrainIncr(delta_lambda, sigma_eqv, s_dev, &
                                              ndim, nshr, ntens, analysis_type, dstra_viscoplas)

    strain_viscopla = strain_viscopla + dstra_viscoplas

    eps_eqv_viscopl = eps_eqv_viscopl + delta_lambda

    call U260_ComputeViscoplasticStress(stress_trial, delta_lambda, sigma_eqv, s_dev, &
                                    lambda, mu, ndim, nshr, ntens, analysis_type, stress_elastic)

    call U260_BuildViscoplasticStiff(lambda, mu, H, eta, sigma_eqv, s_dev, delta_lambda, &
                                     ndim, nshr, ntens, analysis_type, D_viscoplastic)

    stress = stress_elastic
    ddsdde = D_viscoplastic

    sse = HALF * dot_product(stress, strain_elastic)
    do i = 1, ntens
      spd = spd + HALF * (stress_trial(i) + stress_elastic(i)) * dstra_viscoplas(i)
    end do
    scd = 0.9_wp * spd

    call U260_ComputeStressTemperatureDerivative(alpha_thermal, PH_MAT_E, nu, ndim, nshr, ntens, analysis_type, ddsddt)

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 2) statev(2) = eps_eqv_viscopl
    if (nstatv >= 3) statev(3) = temp

    if (nstatv >= 9) then
      do i = 1, 6
        if (3 + i <= nstatv) then
          statev(3 + i) = strain_viscopla(i)
        end if
      end do
    end if

    if (nstatv >= 15) then
      do i = 1, 6
        if (9 + i <= nstatv) then
          statev(9 + i) = strain_rate(i)
        end if
      end do
    end if

  contains

    function U260_detect_analysis_type(ndim, nshr) result(analysis_type)
      integer, intent(in) :: ndim, nshr
      integer :: analysis_type

      select case(ndim)
        case(1)
          analysis_type = 0
        case(2)
          if (nshr == 1) then
            analysis_type = 2
          else
            analysis_type = 1
          end if
        case(3)
          analysis_type = 0
        case default
          analysis_type = 0
      end select

    end function U260_detect_analysis_type

    subroutine U2_co_te_de_parameters(temp, T_ref, Q_activation, R_gas, &
                                                      E_ref, stress_y0_ref, H_ref, eps0_ref, &
                                                      PH_MAT_E, sigma_y0, H, eps0)
      real(wp), intent(in) :: temp, T_ref, Q_activation, R_gas
      real(wp), intent(in) :: E_ref, stress_y0_ref, H_ref, eps0_ref
      real(wp), intent(out) :: PH_MAT_E, sigma_y0, H, eps0

      real(wp) :: exponent

      if (temp > 1.0e-10_wp) then
        exponent = Q_activation / (R_gas * temp) - Q_activation / (R_gas * T_ref)

        PH_MAT_E = E_ref * max(ONE - 0.001_wp*(temp - T_ref), 0.1_wp)

        sigma_y0 = stress_y0_ref * exp(exponent)

        H = H_ref * max(ONE - 0.001_wp*(temp - T_ref), 0.1_wp)

        eps0 = eps0_ref * exp(-exponent)
      else
        PH_MAT_E = E_ref
        sigma_y0 = stress_y0_ref
        H = H_ref
        eps0 = eps0_ref
      end if

      sigma_y0 = max(sigma_y0, 1.0e-10_wp)
      H = max(H, 1.0e-10_wp)
      eps0 = max(eps0, 1.0e-10_wp)

    end subroutine U260_compute_temperature_dependent_parameters

    subroutine U260_build_elastic_Stiff(lambda, mu, ndim, analysis_type, D)
      real(wp), intent(in) :: lambda, mu
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: D(6,6)

      D = ZERO

      select case(ndim)
        case(1)
          D(1,1) = lambda + TWO * mu
        case(2)
          select case(analysis_type)
            case(1)
              D(1,1) = PH_MAT_E / (ONE - nu**2)
              D(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              D(3,3) = mu
            case(2,3)
              D(1,1) = lambda + TWO * mu
              D(1,2) = lambda
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              D(3,3) = mu
              if (analysis_type == 3) then
                D(1,3) = lambda
                D(3,1) = lambda
                D(2,3) = lambda
                D(3,2) = lambda
                D(3,3) = D(1,1)
              end if
          end select
        case(3)
          D(1,1) = lambda + TWO * mu
          D(1,2) = lambda
          D(1,3) = lambda
          D(2,1) = lambda
          D(2,2) = lambda + TWO * mu
          D(2,3) = lambda
          D(3,1) = lambda
          D(3,2) = lambda
          D(3,3) = lambda + TWO * mu
          D(4,4) = mu
          D(5,5) = mu
          D(6,6) = mu
      end select

      call U260_regularize_Stiff_Mtx(D)

    end subroutine U260_build_elastic_Stiff

    subroutine U260_regularize_Stiff_Mtx(D)
      real(wp), intent(inout) :: D(6,6)
      integer :: i

      do i = 1, 6
        if (D(i,i) < REGULARIZATION) then
          D(i,i) = REGULARIZATION
        end if
      end do

    end subroutine U260_regularize_Stiff_Mtx

    subroutine U260_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)
      real(wp), intent(in) :: alpha, dT
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: strain_thermal(6)

      strain_thermal = ZERO

      select case(ndim)
        case(1)
          strain_thermal(1) = alpha * dT
        case(2)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3) then
            strain_thermal(3) = alpha * dT
          end if
        case(3)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          strain_thermal(3) = alpha * dT
      end select

    end subroutine U260_Calc_thermal_strain

    subroutine U260_Calc_strain_rate(dstra, dtime, strain_rate)
      real(wp), intent(in) :: dstra(6), dtime
      real(wp), intent(out) :: strain_rate(6)
      integer :: i

      strain_rate = ZERO

      if (dtime < 1.0e-10_wp) return

      do i = 1, 6
        strain_rate(i) = dstra(i) / dtime
      end do

    end subroutine U260_Calc_strain_rate

    subroutine U2_co_eq_st_rate(strain_rate, ndim, analysis_type, eps_eqv_rate)
      real(wp), intent(in) :: strain_rate(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: eps_eqv_rate

      real(wp) :: strain_rate_dev(6), p_rate
      integer :: i

      strain_rate_dev = strain_rate
      eps_eqv_rate = ZERO

      select case(ndim)
        case(1)
          p_rate = strain_rate(1) / THREE
        case(2)
          p_rate = (strain_rate(1) + strain_rate(2)) / THREE
          if (analysis_type == 3) then
            p_rate = (strain_rate(1) + strain_rate(2) + strain_rate(3)) / THREE
          end if
        case(3)
          p_rate = (strain_rate(1) + strain_rate(2) + strain_rate(3)) / THREE
      end select

      select case(ndim)
        case(1)
          strain_rate_dev(1) = strain_rate(1) - p_rate
        case(2)
          strain_rate_dev(1) = strain_rate(1) - p_rate
          strain_rate_dev(2) = strain_rate(2) - p_rate
          if (analysis_type == 3) then
            strain_rate_dev(3) = strain_rate(3) - p_rate
          end if
        case(3)
          strain_rate_dev(1) = strain_rate(1) - p_rate
          strain_rate_dev(2) = strain_rate(2) - p_rate
          strain_rate_dev(3) = strain_rate(3) - p_rate
      end select

      select case(ndim)
        case(1)
          eps_eqv_rate = abs(strain_rate(1))
        case(2)
          eps_eqv_rate = sqrt((TWO/THREE) * (strain_rate_dev(1)**2 + strain_rate_dev(2)**2 + TWO*strain_rate_dev(3)**2))
        case(3)
          eps_eqv_rate = sqrt((TWO/THREE) * (strain_rate_dev(1)**2 + strain_rate_dev(2)**2 + strain_rate_dev(3)**2 + &
                              TWO * (strain_rate_dev(4)**2 + strain_rate_dev(5)**2 + strain_rate_dev(6)**2)))
      end select

    end subroutine U260_compute_equivalent_strain_rate

    subroutine U260_Calc_stress_invariants(stress, ndim, analysis_type, sigma_eqv, s_dev, p)
      real(wp), intent(in) :: stress(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: sigma_eqv, s_dev(6), p

      s_dev = stress

      select case(ndim)
        case(1)
          p = stress(1) / THREE
        case(2)
          p = (stress(1) + stress(2)) / THREE
          if (analysis_type == 3) then
            p = (stress(1) + stress(2) + stress(3)) / THREE
          end if
        case(3)
          p = (stress(1) + stress(2) + stress(3)) / THREE
      end select

      select case(ndim)
        case(1)
          s_dev(1) = stress(1) - p
        case(2)
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (analysis_type == 3) then
            s_dev(3) = stress(3) - p
          end if
        case(3)
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          s_dev(3) = stress(3) - p
      end select

      select case(ndim)
        case(1)
          sigma_eqv = abs(stress(1))
        case(2)
          sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + TWO * s_dev(3)**2))
        case(3)
          sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                              TWO * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
      end select

    end subroutine U260_Calc_stress_invariants

    subroutine U2_co_vi_coefficient(sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0, eta)
      real(wp), intent(in) :: sigma_eqv, sigma_y, m_rate, eps_eqv_rate, eps0
      real(wp), intent(out) :: eta

      real(wp) :: overstress, rate_factor

      eta = 1.0d10

      if (sigma_eqv < 1.0e-10_wp .or. eps_eqv_rate < 1.0e-10_wp) return

      overstress = sigma_eqv - sigma_y

      if (overstress <= ZERO) return

      rate_factor = (eps_eqv_rate / eps0)**m_rate

      eta = overstress / (eps_eqv_rate / rate_factor)

      eta = max(eta, 1.0e-10_wp)
      eta = min(eta, 1.0d10)

    end subroutine U260_compute_viscosity_coefficient

    subroutine U2_co_vi_st_increment(delta_lambda, sigma_eqv, s_dev, &
                                                   ndim, analysis_type, dstra_viscoplas)
      real(wp), intent(in) :: delta_lambda, sigma_eqv, s_dev(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: dstra_viscoplas(6)

      real(wp) :: flow_factor

      dstra_viscoplas = ZERO

      if (sigma_eqv < 1.0e-10_wp .or. delta_lambda < 1.0e-10_wp) return

      flow_factor = 1.5_wp * delta_lambda / sigma_eqv

      select case(ndim)
        case(1)
          dstra_viscoplas(1) = flow_factor * s_dev(1)
        case(2)
          dstra_viscoplas(1) = flow_factor * s_dev(1)
          dstra_viscoplas(2) = flow_factor * s_dev(2)
          dstra_viscoplas(3) = flow_factor * s_dev(3)
          if (analysis_type == 3) then
            dstra_viscoplas(3) = flow_factor * s_dev(3)
          end if
        case(3)
          dstra_viscoplas(1) = flow_factor * s_dev(1)
          dstra_viscoplas(2) = flow_factor * s_dev(2)
          dstra_viscoplas(3) = flow_factor * s_dev(3)
          dstra_viscoplas(4) = flow_factor * s_dev(4)
          dstra_viscoplas(5) = flow_factor * s_dev(5)
          dstra_viscoplas(6) = flow_factor * s_dev(6)
      end select

    end subroutine U260_compute_viscoplastic_strain_increment

    subroutine U2_co_vi_stress(stress_trial, delta_lambda, sigma_eqv, s_dev, &
                                           lambda, mu, ndim, analysis_type, stress_viscopla)
      real(wp), intent(in) :: stress_trial(6), delta_lambda, sigma_eqv, s_dev(6)
      real(wp), intent(in) :: lambda, mu
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: stress_viscopla(6)

      real(wp) :: p, s_dev_new(6)
      integer :: i

      stress_viscopla = stress_trial

      if (sigma_eqv < 1.0e-10_wp .or. delta_lambda < 1.0e-10_wp) return

      s_dev_new = s_dev * (ONE - THREE*mu*delta_lambda/sigma_eqv)

      call U260_Calc_stress_invariants(stress_trial, ndim, analysis_type, sigma_eqv, s_dev, p)

      select case(ndim)
        case(1)
          stress_viscopla(1) = s_dev_new(1) + p
        case(2)
          stress_viscopla(1) = s_dev_new(1) + p
          stress_viscopla(2) = s_dev_new(2) + p
          stress_viscopla(3) = s_dev_new(3)
          if (analysis_type == 3) then
            stress_viscopla(3) = s_dev_new(3) + p
          end if
        case(3)
          stress_viscopla(1) = s_dev_new(1) + p
          stress_viscopla(2) = s_dev_new(2) + p
          stress_viscopla(3) = s_dev_new(3) + p
          stress_viscopla(4) = s_dev_new(4)
          stress_viscopla(5) = s_dev_new(5)
          stress_viscopla(6) = s_dev_new(6)
      end select

    end subroutine U260_compute_viscoplastic_stress

    subroutine U2_bu_vi_stiff(lambda, mu, H, eta, sigma_eqv, s_dev, delta_lambda, &
                                           ndim, analysis_type, D_viscoplastic)
      real(wp), intent(in) :: lambda, mu, H, eta, sigma_eqv, s_dev(6), delta_lambda
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: D_viscoplastic(6,6)

      real(wp) :: elastic_modulus, viscoplastic_mo
      real(wp) :: beta
      integer :: i, j

      D_viscoplastic = ZERO

      if (sigma_eqv < 1.0e-10_wp .or. delta_lambda < 1.0e-10_wp) then
        call U260_build_elastic_Stiff(lambda, mu, ndim, analysis_type, D_viscoplastic)
        return
      end if

      elastic_modulus = lambda + TWO * mu

      viscoplastic_mo = THREE * mu + H + THREE * mu * mu / eta

      beta = (THREE * mu) / viscoplastic_mo

      select case(ndim)
        case(1)
          D_viscoplastic(1,1) = elastic_modulus * (ONE - beta)
        case(2)
          select case(analysis_type)
            case(1)
              D_viscoplastic(1,1) = PH_MAT_E / (ONE - nu**2) * (ONE - beta)
              D_viscoplastic(1,2) = PH_MAT_E * nu / (ONE - nu**2) * (ONE - beta)
              D_viscoplastic(2,1) = D_viscoplastic(1,2)
              D_viscoplastic(2,2) = D_viscoplastic(1,1)
              D_viscoplastic(3,3) = mu * (ONE - beta)
            case(2,3)
              do i = 1, 3
                do j = 1, 3
                  if (i <= 2 .and. j <= 2) then
                    D_viscoplastic(i,j) = lambda * (ONE - beta) + TWO * mu * (ONE - beta) * (i == j)
                  else if (i == 3 .and. j == 3) then
                    D_viscoplastic(i,j) = mu * (ONE - beta)
                  end if
                end do
              end do
              if (analysis_type == 3) then
                D_viscoplastic(1,3) = lambda * (ONE - beta)
                D_viscoplastic(3,1) = D_viscoplastic(1,3)
                D_viscoplastic(2,3) = lambda * (ONE - beta)
                D_viscoplastic(3,2) = D_viscoplastic(2,3)
                D_viscoplastic(3,3) = lambda + TWO * mu * (ONE - beta)
              end if
          end select
        case(3)
          do i = 1, 6
            do j = 1, 6
              if (i <= 3 .and. j <= 3) then
                D_viscoplastic(i,j) = lambda * (ONE - beta) + TWO * mu * (ONE - beta) * (i == j)
              else if (i > 3 .and. j > 3) then
                D_viscoplastic(i,j) = mu * (ONE - beta) * (i == j)
              end if
            end do
          end do
      end select

      call U260_regularize_Stiff_Mtx(D_viscoplastic)

    end subroutine U260_build_viscoplastic_stiffness

    subroutine U2_co_st_te_derivative(alpha_thermal, PH_MAT_E, nu, ndim, analysis_type, ddsddt)
      real(wp), intent(in) :: alpha_thermal, PH_MAT_E, nu
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: ddsddt(6)

      real(wp) :: stress_thermal

      ddsddt = ZERO

      if (alpha_thermal == ZERO) return

      select case(analysis_type)
        case(1)
          stress_thermal = PH_MAT_E * alpha_thermal / (ONE - nu)
        case default
          stress_thermal = PH_MAT_E * alpha_thermal / ((ONE + nu) * (ONE - TWO * nu))
      end select

      select case(ndim)
        case(1)
          ddsddt(1) = -stress_thermal
        case(2)
          ddsddt(1) = -stress_thermal
          ddsddt(2) = -stress_thermal
          if (analysis_type == 3) then
            ddsddt(3) = -stress_thermal
          end if
        case(3)
          ddsddt(1) = -stress_thermal
          ddsddt(2) = -stress_thermal
          ddsddt(3) = -stress_thermal
      end select

    end subroutine U260_compute_stress_temperature_derivative

  END SUBROUTINE UF_ThermoViscoplastic_UMAT

  SUBROUTINE UF_ViscoelasticDamage_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc, status)

    implicit none

    !-------------------------------------------------------------------
    ! Abaqus UMAT Standard Interface Parameters
    !-------------------------------------------------------------------
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt

    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)

    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    real(wp) :: E_inf, E_g, nu
    integer(i4) :: n_prony
    real(wp), allocatable :: g_prony(:), tau_prony(:)
    real(wp), allocatable :: k_prony(:), tau_k_prony(:)
    real(wp) :: alpha_damage, beta_damage, sigma_critical, G_c
    real(wp) :: alpha_thermal

    real(wp) :: time_old, temp_old, strain_old(6), stress_old(6)
    real(wp) :: damage_variable, damage_variable, energy_density
    real(wp), allocatable :: s_old(:,:), p_old(:)

    real(wp) :: strain_total(6), strain_elastic(6), strain_visc(6)
    real(wp) :: strain_thermal(6), dstra_elastic(6), dstra_visc(6)

    real(wp) :: stress_elastic(6), stress_visc(6), stress_trial(6)
    real(wp) :: stress_effectiv(6), s_dev(6), p, sigma_eqv

    real(wp) :: D_elastic(6,6), D_viscoelastic(6,6), D_damaged(6,6)

    integer(i4) :: analysis_type, i, j, k, ntens
    real(wp) :: dt, G_inf, K_inf, G_g, K_g
    real(wp) :: s_current(6), p_current
    real(wp) :: damage_factor, damage_rate, energy_density

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    !-------------------------------------------------------------------
    ! Determine Tensor Dimension
    !-------------------------------------------------------------------
    ntens = ndir + nshr

    !-------------------------------------------------------------------
    ! Valid Mat Parameters
    !-------------------------------------------------------------------
    if (nprops < 12) then
            CALL log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'Insufficient Mat parameters')
      status%status_code = IF_STATUS_INVALID
      RETURN
        end if

    E_inf = props(1)
    E_g = props(2)
    nu = props(3)
    n_prony = nint(props(4))
    alpha_thermal = props(5)
    alpha_damage = props(6)
    beta_damage = props(7)
    sigma_critical = props(8)
    G_c = props(9)

    if (E_inf <= ZERO .or. E_g <= ZERO) then
            call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'E_inf must be greater than 0')
      return
      return
    end if

    if (nu < -ONE .or. nu >= HALF) then
            call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'nu must be in range [-1, 0.5)')
      return
    end if

    if (n_prony < 1 .or. n_prony > 10) then
      call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'n_prony must be in [1,10]')
      return
    end if

    if (alpha_damage < ZERO) then
            call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'alpha_damage must be non-negative')
      return
      return
    end if

    if (beta_damage < ZERO) then
            call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'beta_damage must be non-negative')
      return
      return
    end if

    if (sigma_critical < ZERO) then
            call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'sigma_critical must be non-negative')
      return
      return
    end if

    if (G_c < ZERO) then
            call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'G_c must be non-negative')
      return
      return
    end if

    required_props = 9 + 4*n_prony
    if (nprops < required_props) then
      call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'Insufficient props for Prony series')
      return
    end if

    allocate(g_prony(n_prony), tau_prony(n_prony))
    allocate(k_prony(n_prony), tau_k_prony(n_prony))

    do i = 1, n_prony
      g_prony(i) = props(9 + i)
      tau_prony(i) = props(9 + n_prony + i)
      k_prony(i) = props(9 + 2*n_prony + i)
      tau_k_prony(i) = props(9 + 3*n_prony + i)

      if (g_prony(i) < ZERO .or. g_prony(i) > ONE) then
              call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'Prony series g_prony must be in range [0, 1]')
        return
      end if

      if (tau_prony(i) <= ZERO) then
        call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'tau_prony must be positive')
        return
      end if

      if (k_prony(i) < ZERO .or. k_prony(i) > ONE) then
              call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'Prony series k_prony must be in range [0, 1]')
        return
      end if

      if (tau_k_prony(i) <= ZERO) then
        call log_error('MD_MatLib_Plastic_ViscoelasticDamage', 'tau_k_prony must be positive')
        return
      end if
    end do

    !-------------------------------------------------------------------
    ! Determine Analysis Type
    !-------------------------------------------------------------------
    analysis_type = U259_DetectAnalysisType(ndim, nshr)

    time_old = time(1) - dtime
    temp_old = temp
    strain_old = ZERO
    stress_old = ZERO
    damage_variable = ZERO
    energy_density = ZERO

    allocate(s_old(n_prony, 6), p_old(n_prony))
    s_old = ZERO
    p_old = ZERO

    if (nstatv >= 2) time_old = statev(2)
    if (nstatv >= 3) temp_old = statev(3)
    if (nstatv >= 9) then
      do i = 1, 6
        if (3 + i <= nstatv) then
          strain_old(i) = statev(3 + i)
        end if
      end do
    end if
    if (nstatv >= 15) then
      do i = 1, 6
        if (9 + i <= nstatv) then
          stress_old(i) = statev(9 + i)
        end if
      end do
    end if
    if (nstatv >= 16) damage_variable = statev(16)
    if (nstatv >= 17) energy_density = statev(17)

    if (nstatv >= 17 + 6*n_prony) then
      do i = 1, n_prony
        do j = 1, 6
          if (17 + (i-1)*6 + j <= nstatv) then
            s_old(i,j) = statev(17 + (i-1)*6 + j)
          end if
        end do
      end do
    end if

    if (nstatv >= 17 + 6*n_prony + n_prony) then
      do i = 1, n_prony
        if (17 + 6*n_prony + i <= nstatv) then
          p_old(i) = statev(17 + 6*n_prony + i)
        end if
      end do
    end if

    dt = time(1) - time_old
    if (dt < ZERO) dt = dtime

    strain_total = stran + dstran

    call U259_ComputeThermalStrain(alpha_thermal, temp - temp_old, ndim, nshr, ntens, analysis_type, strain_thermal)

    do i = 1, ntens
      dstra_elastic(i) = dstran(i) - strain_thermal(i)
      strain_elastic(i) = strain_total(i) - strain_thermal(i)
    end do

    G_inf = E_inf / (TWO * (ONE + nu))
    K_inf = E_inf / (THREE * (ONE - TWO * nu))
    G_g = E_g / (TWO * (ONE + nu))
    K_g = E_g / (THREE * (ONE - TWO * nu))

    call U259_BuildElasticStiffness(E_inf, nu, ndim, nshr, ntens, analysis_type, D_elastic)

    stress_trial = ZERO
    do i = 1, ntens
      do j = 1, ntens
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * strain_elastic(j)
      end do
    end do

    call U259_ComputeStressInvariants(stress_trial, ndim, nshr, ntens, analysis_type, p, s_dev)

    call U259_ComputeEquivalentStress(s_dev, ndim, nshr, ntens, analysis_type, sigma_eqv)

    call U259_ComputePronyViscoelasticStress(dstra_elastic, dt, n_prony, &
                                          g_prony, tau_prony, k_prony, tau_k_prony, &
                                          G_inf, K_inf, G_g, K_g, &
                                          s_old, p_old, s_current, p_current, &
                                          ndim, nshr, ntens, analysis_type, stress_visc)

    do i = 1, ntens
      stress_effectiv(i) = stress_trial(i) + stress_visc(i)
    end do

    call U259_ComputeDamageVariable(stress_effectiv, sigma_eqv, sigma_critical, &
                                alpha_damage, beta_damage, G_c, dt, &
                                damage_variable, damage_variable, damage_rate)

    if (damage_variable > TOL) then
      damage_factor = ONE - exp(-alpha_damage * damage_variable**beta_damage)
      do i = 1, ntens
        stress_effectiv(i) = stress_effectiv(i) * (ONE - damage_factor)
      end do
      scd = G_c * damage_rate * dtime
    end if

    call U259_BuildViscoelasticStiff(D_elastic, dt, n_prony, &
                                     g_prony, tau_prony, k_prony, tau_k_prony, &
                                     G_inf, K_inf, G_g, K_g, &
                                     ndim, nshr, ntens, analysis_type, D_viscoelastic)

    if (damage_variable > TOL) then
      call U259_BuildDamagedStiffness(D_viscoelastic, damage_factor, damage_variable, &
                                  stress_effectiv, strain_elastic, ndim, nshr, ntens, analysis_type, D_damaged)
      ddsdde = D_damaged
    else
      ddsdde = D_viscoelastic
    end if

    stress = stress_effectiv

    sse = HALF * dot_product(stress_effectiv, strain_elastic)
    if (damage_variable > 1.0e-10_wp) then
      scd = G_c * damage_rate * dtime
    end if

    if (nstatv >= 1) statev(1) = real(analysis_type, wp)
    if (nstatv >= 2) statev(2) = time(1)
    if (nstatv >= 3) statev(3) = temp
    if (nstatv >= 9) then
      do i = 1, 6
        if (3 + i <= nstatv) then
          statev(3 + i) = strain_total(i)
        end if
      end do
    end if
    if (nstatv >= 15) then
      do i = 1, 6
        if (9 + i <= nstatv) then
          statev(9 + i) = stress_effectiv(i)
        end if
      end do
    end if
    if (nstatv >= 16) statev(16) = damage_variable
    if (nstatv >= 17) statev(17) = sse + scd

    if (nstatv >= 17 + 6*n_prony) then
      do i = 1, n_prony
        do j = 1, 6
          if (17 + (i-1)*6 + j <= nstatv) then
            statev(17 + (i-1)*6 + j) = s_current(j)
          end if
        end do
      end do
    end if

    if (nstatv >= 17 + 6*n_prony + n_prony) then
      do i = 1, n_prony
        if (17 + 6*n_prony + i <= nstatv) then
          statev(17 + 6*n_prony + i) = p_current(i)
        end if
      end do
    end if

    deallocate(g_prony, tau_prony, k_prony, tau_k_prony)
    deallocate(s_old, p_old)

  contains

    function U259_detect_analysis_type(ndim, nshr) result(analysis_type)
      integer, intent(in) :: ndim, nshr
      integer :: analysis_type

      select case(ndim)
        case(1)
          analysis_type = 0
        case(2)
          if (nshr == 1) then
            analysis_type = 2
          else
            analysis_type = 1
          end if
        case(3)
          analysis_type = 0
        case default
          analysis_type = 0
      end select

    end function U259_detect_analysis_type

    subroutine U259_Calc_thermal_strain(alpha, dT, ndim, analysis_type, strain_thermal)
      real(wp), intent(in) :: alpha, dT
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: strain_thermal(6)

      strain_thermal = ZERO

      select case(ndim)
        case(1)
          strain_thermal(1) = alpha * dT
        case(2)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          if (analysis_type == 3) then
            strain_thermal(3) = alpha * dT
          end if
        case(3)
          strain_thermal(1) = alpha * dT
          strain_thermal(2) = alpha * dT
          strain_thermal(3) = alpha * dT
      end select

    end subroutine U259_Calc_thermal_strain

    subroutine U259_Calc_stress_invariants(stress, ndim, analysis_type, p, s_dev, p_out)
      real(wp), intent(in) :: stress(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: p, s_dev(6), p_out

      s_dev = stress

      select case(ndim)
        case(1)
          p = stress(1) / THREE
        case(2)
          p = (stress(1) + stress(2)) / THREE
          if (analysis_type == 3) then
            p = (stress(1) + stress(2) + stress(3)) / THREE
          end if
        case(3)
          p = (stress(1) + stress(2) + stress(3)) / THREE
      end select

      p_out = p

      select case(ndim)
        case(1)
          s_dev(1) = stress(1) - p
        case(2)
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          if (analysis_type == 3) then
            s_dev(3) = stress(3) - p
          end if
        case(3)
          s_dev(1) = stress(1) - p
          s_dev(2) = stress(2) - p
          s_dev(3) = stress(3) - p
      end select

    end subroutine U259_Calc_stress_invariants

    subroutine U259_Calc_equivalent_stress(s_dev, ndim, analysis_type, sigma_eqv)
      real(wp), intent(in) :: s_dev(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: sigma_eqv

      sigma_eqv = ZERO

      select case(ndim)
        case(1)
          sigma_eqv = abs(s_dev(1))
        case(2)
          sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + TWO * s_dev(3)**2))
        case(3)
          sigma_eqv = sqrt(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                          TWO * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
      end select

    end subroutine U259_Calc_equivalent_stress

    subroutine U259_build_elastic_Stiff(PH_MAT_E, nu, ndim, analysis_type, D)
      real(wp), intent(in) :: PH_MAT_E, nu
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: D(6,6)

      real(wp) :: lambda, mu

      D = ZERO

      lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
      mu = PH_MAT_E / (TWO * (ONE + nu))

      select case(ndim)
        case(1)
          D(1,1) = PH_MAT_E
        case(2)
          select case(analysis_type)
            case(1)
              D(1,1) = PH_MAT_E / (ONE - nu**2)
              D(1,2) = PH_MAT_E * nu / (ONE - nu**2)
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              D(3,3) = mu
            case(2,3)
              D(1,1) = lambda + TWO * mu
              D(1,2) = lambda
              D(2,1) = D(1,2)
              D(2,2) = D(1,1)
              D(3,3) = mu
              if (analysis_type == 3) then
                D(1,3) = lambda
                D(3,1) = lambda
                D(2,3) = lambda
                D(3,2) = lambda
                D(3,3) = D(1,1)
              end if
          end select
        case(3)
          D(1,1) = lambda + TWO * mu
          D(1,2) = lambda
          D(1,3) = lambda
          D(2,1) = lambda
          D(2,2) = lambda + TWO * mu
          D(2,3) = lambda
          D(3,1) = lambda
          D(3,2) = lambda
          D(3,3) = lambda + TWO * mu
          D(4,4) = mu
          D(5,5) = mu
          D(6,6) = mu
      end select

      call U259_regularize_Stiff_Mtx(D)

    end subroutine U259_build_elastic_Stiff

    subroutine U259_regularize_Stiff_Mtx(D)
      real(wp), intent(inout) :: D(6,6)
      integer :: i

      do i = 1, 6
        if (D(i,i) < REGULARIZATION) then
          D(i,i) = REGULARIZATION
        end if
      end do

    end subroutine U259_regularize_Stiff_Mtx

    subroutine U2_co_pr_vi_stress(dstra_elastic, dt, n_prony, &
                                               g_prony, tau_prony, k_prony, tau_k_prony, &
                                               G_inf, K_inf, G_g, K_g, &
                                               s_old, p_old, s_current, p_current, &
                                               ndim, analysis_type, stress_visc)
      real(wp), intent(in) :: dstra_elastic(6), dt
      integer, intent(in) :: n_prony, ndim, analysis_type
      real(wp), intent(in) :: g_prony(n_prony), tau_prony(n_prony)
      real(wp), intent(in) :: k_prony(n_prony), tau_k_prony(n_prony)
      real(wp), intent(in) :: G_inf, K_inf, G_g, K_g
      real(wp), intent(in) :: s_old(n_prony,6), p_old(n_prony)
      real(wp), intent(out) :: s_current(6), p_current(n_prony)
      real(wp), intent(out) :: stress_visc(6)

      real(wp) :: strain_dev(6), strain_vol
      real(wp) :: dstra_dev(6), dstra_vol
      real(wp) :: relaxation_fact, viscosity_facto
      real(wp) :: G_i, K_i, tau_i, tau_ki
      integer :: i, j

      stress_visc = ZERO
      s_current = ZERO
      p_current = ZERO

      if (dt < 1.0e-10_wp) return

      call U259_Calc_strain_invariants(dstra_elastic, ndim, analysis_type, dstra_vol, dstra_dev, dstra_vol)

      do i = 1, n_prony
        G_i = g_prony(i) * (G_g - G_inf)
        tau_i = tau_prony(i)

        relaxation_fact = exp(-dt / tau_i)
        viscosity_facto = G_i * (ONE - relaxation_fact) * tau_i / dt

        do j = 1, 6
          s_current(j) = s_current(j) + relaxation_fact * s_old(i,j) + viscosity_facto * dstra_dev(j)
        end do
      end do

      do i = 1, n_prony
        K_i = k_prony(i) * (K_g - K_inf)
        tau_ki = tau_k_prony(i)

        relaxation_fact = exp(-dt / tau_ki)
        viscosity_facto = K_i * (ONE - relaxation_fact) * tau_ki / dt

        p_current(i) = relaxation_fact * p_old(i) + viscosity_facto * dstra_vol
      end do

      select case(ndim)
        case(1)
          stress_visc(1) = s_current(1) + sum(p_current)
        case(2)
          stress_visc(1) = s_current(1) + sum(p_current)
          stress_visc(2) = s_current(2) + sum(p_current)
          stress_visc(3) = s_current(3)
          if (analysis_type == 3) then
            stress_visc(3) = s_current(3) + sum(p_current)
          end if
        case(3)
          stress_visc(1) = s_current(1) + sum(p_current)
          stress_visc(2) = s_current(2) + sum(p_current)
          stress_visc(3) = s_current(3) + sum(p_current)
          stress_visc(4) = s_current(4)
          stress_visc(5) = s_current(5)
          stress_visc(6) = s_current(6)
      end select

    end subroutine U259_compute_prony_viscoelastic_stress

    subroutine U259_Calc_strain_invariants(strain, ndim, analysis_type, strain_vol, strain_dev, strain_vol_out)
      real(wp), intent(in) :: strain(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: strain_vol, strain_dev(6), strain_vol_out

      strain_dev = strain

      select case(ndim)
        case(1)
          strain_vol = strain(1)
        case(2)
          strain_vol = strain(1) + strain(2)
          if (analysis_type == 3) then
            strain_vol = strain(1) + strain(2) + strain(3)
          end if
        case(3)
          strain_vol = strain(1) + strain(2) + strain(3)
      end select

      strain_vol_out = strain_vol

      select case(ndim)
        case(1)
          strain_dev(1) = strain(1) - strain_vol / THREE
        case(2)
          strain_dev(1) = strain(1) - strain_vol / THREE
          strain_dev(2) = strain(2) - strain_vol / THREE
          if (analysis_type == 3) then
            strain_dev(3) = strain(3) - strain_vol / THREE
          end if
        case(3)
          strain_dev(1) = strain(1) - strain_vol / THREE
          strain_dev(2) = strain(2) - strain_vol / THREE
          strain_dev(3) = strain(3) - strain_vol / THREE
      end select

    end subroutine U259_Calc_strain_invariants

    subroutine U259_Calc_damage_variable(stress, sigma_eqv, sigma_critical, &
                                       alpha_damage, beta_damage, G_c, dt, &
                                       damage_variable, damage_variable, damage_rate)
      real(wp), intent(in) :: stress(6), sigma_eqv, sigma_critical
      real(wp), intent(in) :: alpha_damage, beta_damage, G_c, dt
      real(wp), intent(in) :: damage_variable
      real(wp), intent(out) :: damage_variable, damage_rate

      real(wp) :: stress_magnitud, damage_driving
      real(wp) :: damage_function, d_damage_ddriving

      damage_variable = damage_variable
      damage_rate = ZERO

      if (sigma_eqv < sigma_critical .or. alpha_damage < 1.0e-10_wp) return

      stress_magnitud = sqrt(dot_product(stress, stress))
      damage_driving = (sigma_eqv - sigma_critical) / sigma_critical

      if (damage_driving < 1.0e-10_wp) return

      damage_function = alpha_damage * damage_driving**beta_damage
      damage_rate = damage_function / (ONE + damage_variable)

      damage_variable = damage_variable + damage_rate * dt
      damage_variable = max(min(damage_variable, ONE), ZERO)

    end subroutine U259_Calc_damage_variable

    subroutine U2_bu_vi_stiff(D_elastic, dt, n_prony, &
                                          g_prony, tau_prony, k_prony, tau_k_prony, &
                                          G_inf, K_inf, G_g, K_g, &
                                          ndim, analysis_type, D_viscoelastic)
      real(wp), intent(in) :: D_elastic(6,6), dt
      integer, intent(in) :: n_prony, ndim, analysis_type
      real(wp), intent(in) :: g_prony(n_prony), tau_prony(n_prony)
      real(wp), intent(in) :: k_prony(n_prony), tau_k_prony(n_prony)
      real(wp), intent(in) :: G_inf, K_inf, G_g, K_g
      real(wp), intent(out) :: D_viscoelastic(6,6)

      real(wp) :: relaxation_fact, viscosity_facto
      real(wp) :: G_i, K_i, tau_i, tau_ki
      real(wp) :: D_viscous(6,6)
      integer :: i, j

      D_viscoelastic = D_elastic
      D_viscous = ZERO

      if (dt < 1.0e-10_wp) return

      do i = 1, n_prony
        G_i = g_prony(i) * (G_g - G_inf)
        tau_i = tau_prony(i)

        relaxation_fact = exp(-dt / tau_i)
        viscosity_facto = G_i * (ONE - relaxation_fact) * tau_i / dt

        do j = 1, 3
          D_viscous(j,j) = D_viscous(j,j) + TWO * viscosity_facto
        end do

        do j = 4, 6
          D_viscous(j,j) = D_viscous(j,j) + viscosity_facto
        end do
      end do

      do i = 1, n_prony
        K_i = k_prony(i) * (K_g - K_inf)
        tau_ki = tau_k_prony(i)

        relaxation_fact = exp(-dt / tau_ki)
        viscosity_facto = K_i * (ONE - relaxation_fact) * tau_ki / dt

        do j = 1, 3
          D_viscous(j,j) = D_viscous(j,j) + viscosity_facto
        end do
      end do

      do i = 1, 6
        do j = 1, 6
          D_viscoelastic(i,j) = D_viscoelastic(i,j) + D_viscous(i,j)
        end do
      end do

      call U259_regularize_Stiff_Mtx(D_viscoelastic)

    end subroutine U259_build_viscoelastic_stiffness

    subroutine U259_build_damaged_Stiff(D_viscoelastic, damage_factor, damage_variable, &
                                       stress, strain, ndim, analysis_type, D_damaged)
      real(wp), intent(in) :: D_viscoelastic(6,6)
      real(wp), intent(in) :: damage_factor, damage_variable
      real(wp), intent(in) :: stress(6), strain(6)
      integer, intent(in) :: ndim, analysis_type
      real(wp), intent(out) :: D_damaged(6,6)

      real(wp) :: d_damage_dstrai(6), d_damage_dstres(6,6)
      real(wp) :: damage_stiffnes(6,6)
      integer :: i, j, k

      D_damaged = D_viscoelastic

      if (damage_factor < 1.0e-10_wp .or. damage_variable < 1.0e-10_wp) return

      real(wp) :: stiffness_reduc = ONE - damage_factor

      do i = 1, 6
        do j = 1, 6
          D_damaged(i,j) = D_damaged(i,j) * stiffness_reduc
        end do
      end do

      call U259_regularize_Stiff_Mtx(D_damaged)

    end subroutine U259_build_damaged_Stiff

  END SUBROUTINE UF_ViscoelasticDamage_UMAT

END MODULE PH_MatPLM_LegacyFacadeUMATs
