!===============================================================================
! MODULE: PH_Mat_Geo_MohrCoulomb_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Mohr-Coulomb plasticity for soils and rocks
!   W1: **props** / validation bridge from L3 **MohrCoulomb_MatDesc**; runtime carrier remains slot **desc%props**.
!===============================================================================
!
! Theory:
!   - Yield function:      f = q - p·sin(φ) - c·cos(φ) �?0
!   - Flow rule:           Non-associated (ψ �?φ)
!   - Hardening:           Isotropic (c, φ, ψ evolution)
!   where:
!     p = -I�?3 (mean stress, compression positive)
!     q = �?3J�? (von Mises equivalent stress)
!     φ = friction angle, ψ = dilation angle, c = cohesion
!
! Statev layout (11):
!   statev(1)  = εᵖ_eq  : Equivalent plastic strain
!   statev(2)  = W�?    : Plastic work
!   statev(3)  = c_curr : Current cohesion
!   statev(4)  = φ_curr : Current friction angle [rad]
!   statev(5)  = ψ_curr : Current dilation angle [rad]
!   statev(6:11) = ε�?  : Plastic strain tensor (6 components)
!===============================================================================
MODULE PH_Mat_Geo_MohrCoulomb_Core
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Ids, ONLY: MAT_ID_204
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  USE PH_Mat_Core_Types, ONLY: MatPoint_In, MatPoint_Out
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, Pack_To_UMAT_Context
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context
  USE PH_Mat_Geo_Def, ONLY: PH_Mat_Geo_Desc, PH_Mat_Geo_State, PH_Mat_Geo_Algo

  ! Legacy stub definitions (module MD_MatPLG_MohrCoulomb deleted in material domain cleanup)
  TYPE :: MohrCoulomb_MatDesc
    REAL(wp) :: c = 0.0_wp
    REAL(wp) :: phi = 0.0_wp
    REAL(wp) :: psi = 0.0_wp
    REAL(wp) :: H_c = 0.0_wp
    REAL(wp) :: H_phi = 0.0_wp
    REAL(wp) :: H_psi = 0.0_wp
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: mu = 0.0_wp
    REAL(wp) :: K = 0.0_wp
  END TYPE MohrCoulomb_MatDesc

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MohrCoulomb_UpdateStress
  PUBLIC :: UF_MohrCoulomb_UMAT
  PUBLIC :: PH_Mat_Geo_MC_Eval_Wrapper

CONTAINS

  SUBROUTINE UF_MohrCoulomb_L3_InitFromProps(desc, nprops, props, status)
    TYPE(MohrCoulomb_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "MohrCoulomb: need at least 5 props"
      RETURN
    END IF
    desc%c = props(1)
    desc%phi = props(2)
    desc%psi = props(3)
    desc%PH_MAT_E = props(4)
    desc%nu = props(5)
    desc%mu = desc%PH_MAT_E / (2.0_wp * (1.0_wp + desc%nu))
    desc%K = desc%PH_MAT_E / (3.0_wp * (1.0_wp - 2.0_wp * desc%nu))
    IF (nprops >= 6) desc%H_c = props(6)
    IF (nprops >= 7) desc%H_phi = props(7)
    IF (nprops >= 8) desc%H_psi = props(8)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_MohrCoulomb_L3_InitFromProps

  !----------------------------------------------------------------------------
  ! MohrCoulomb_UpdateStress
  !   Pure algorithm: MatPoint_In/Out paradigm, no side effects.
  !----------------------------------------------------------------------------
  SUBROUTINE MohrCoulomb_UpdateStress(in, out)
    TYPE(MatPoint_In), INTENT(IN) :: in
    TYPE(MatPoint_Out), INTENT(OUT) :: out
    TYPE(MohrCoulomb_MatDesc) :: desc
    REAL(wp) :: D(6,6), sig_new(6), strain_inc(6)
    REAL(wp) :: eps_p_eqv_old, plastic_work_old
    REAL(wp) :: c_curr, phi_curr, psi_curr
    REAL(wp) :: sin_phi, cos_phi, sin_psi
    REAL(wp) :: p_trial, q_trial, s_dev(6)
    REAL(wp) :: yield_val, dlambda
    REAL(wp) :: plastic_strain(6)
    INTEGER(i4) :: ntens, i, j
    CALL init_error_status(out%status)
    ntens = in%ntens
    IF (ntens <= 0) ntens = 6
    IF (.NOT. ALLOCATED(in%props) .OR. SIZE(in%props) < 5) THEN
      out%status%status_code = IF_STATUS_ERROR
      out%status%message = "MohrCoulomb: need at least 5 props"
      RETURN
    END IF
    CALL UF_MohrCoulomb_L3_InitFromProps(desc, SIZE(in%props), in%props, out%status)
    IF (out%status%status_code /= IF_STATUS_OK) RETURN
    eps_p_eqv_old = ZERO
    plastic_work_old = ZERO
    c_curr = desc%c
    phi_curr = desc%phi
    psi_curr = desc%psi
    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= 5) THEN
      eps_p_eqv_old = in%statev(1)
      plastic_work_old = in%statev(2)
      c_curr = in%statev(3)
      phi_curr = in%statev(4)
      psi_curr = in%statev(5)
    END IF
    sin_phi = SIN(phi_curr)
    cos_phi = COS(phi_curr)
    sin_psi = SIN(psi_curr)
    IF (desc%H_c > ZERO) THEN
      c_curr = desc%c + desc%H_c * eps_p_eqv_old
    END IF
    IF (desc%H_phi > ZERO) THEN
      phi_curr = desc%phi + desc%H_phi * eps_p_eqv_old
      phi_curr = MIN(phi_curr, PI/2.0_wp - 1.0e-10_wp)
      sin_phi = SIN(phi_curr)
      cos_phi = COS(phi_curr)
    END IF
    IF (desc%H_psi > ZERO) THEN
      psi_curr = desc%psi + desc%H_psi * eps_p_eqv_old
      psi_curr = MIN(psi_curr, phi_curr)
      sin_psi = SIN(psi_curr)
    END IF
    CALL Construct_Elastic_D(desc%PH_MAT_E, desc%nu, D)
    strain_inc(1:ntens) = in%strain_inc(1:ntens)
    IF (ntens < 6) strain_inc(ntens+1:6) = ZERO
    CALL mc_compute_stress_invariants_pq(in%sigma_old, ntens, p_trial, q_trial, s_dev)
    yield_val = q_trial - (-p_trial) * sin_phi - c_curr * cos_phi
    IF (yield_val > 1.0e-10_wp) THEN
      dlambda = yield_val / (THREE * desc%mu + desc%K * sin_phi * sin_psi + desc%H_c * cos_phi)
      dlambda = MAX(dlambda, ZERO)
      IF (q_trial > 1.0e-12_wp) THEN
        DO i = 1, 3
          plastic_strain(i) = sin_psi * dlambda / THREE + s_dev(i) / q_trial * dlambda
        END DO
        IF (ntens >= 4) THEN
          plastic_strain(4:ntens) = s_dev(4:ntens) / q_trial * dlambda
        END IF
      ELSE
        plastic_strain(1:3) = sin_psi * dlambda / THREE
        plastic_strain(4:6) = ZERO
      END IF
      q_trial = q_trial - THREE * desc%mu * dlambda
      q_trial = MAX(q_trial, ZERO)
      p_trial = p_trial - desc%K * sin_psi * dlambda
      IF (SIZE(s_dev) > 0 .AND. q_trial > 1.0e-12_wp) THEN
        sig_new(1:3) = -p_trial / THREE + s_dev(1:3) * (q_trial / q_trial)
        IF (ntens >= 4) THEN
          sig_new(4:ntens) = s_dev(4:ntens) * (q_trial / q_trial)
        END IF
      ELSE
        sig_new(1:3) = -p_trial / THREE
        sig_new(4:ntens) = ZERO
      END IF
      CALL mc_compute_tangent(D, desc%K, desc%mu, sin_phi, sin_psi, cos_phi, desc%H_c, q_trial, ntens, out%ddsdde)
      out%pnewdt = 0.5_wp
    ELSE
      sig_new(1:ntens) = in%sigma_old(1:ntens) + MATMUL(D(1:ntens,1:ntens), strain_inc(1:ntens))
      plastic_strain = ZERO
      dlambda = ZERO
      out%ddsdde(1:ntens,1:ntens) = D(1:ntens,1:ntens)
      out%pnewdt = 1.0_wp
    END IF
    out%sigma(1:ntens) = sig_new(1:ntens)
    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= 11) THEN
      IF (.NOT. ALLOCATED(out%statev)) ALLOCATE(out%statev(SIZE(in%statev)))
      out%statev(1) = eps_p_eqv_old + dlambda
      out%statev(2) = plastic_work_old + c_curr * cos_phi * dlambda
      out%statev(3) = c_curr
      out%statev(4) = phi_curr
      out%statev(5) = psi_curr
      DO i = 1, MIN(6, SIZE(in%statev) - 5)
        out%statev(5+i) = in%statev(5+i) + plastic_strain(i)
      END DO
    END IF
    out%status%status_code = IF_STATUS_OK
  END SUBROUTINE MohrCoulomb_UpdateStress

  !----------------------------------------------------------------------------
  ! UF_MohrCoulomb_UMAT
  !   Standard UMAT interface wrapper for Mohr-Coulomb plasticity.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_MohrCoulomb_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, ndir, nshr, nstatev, nprops, &
                                  props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MatPoint_In) :: in
    TYPE(MatPoint_Out) :: out
    CALL init_error_status(status)
    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    in%ntens = ndir + nshr
    in%cfg%ndim = ndim
    in%props => props
    in%sigma_old => stress
    in%strain_inc => dstran
    in%statev => statev
    in%temp = temp
    in%dtime = dtime
    in%kstep = kstep
    in%kinc = kinc
    CALL MohrCoulomb_UpdateStress(in, out)
    IF (out%status%status_code == IF_STATUS_OK) THEN
      stress(1:in%ntens) = out%sigma(1:in%ntens)
      ddsdde(1:in%ntens,1:in%ntens) = out%ddsdde(1:in%ntens,1:in%ntens)
      IF (ALLOCATED(out%statev)) THEN
        statev(1:MIN(SIZE(statev),SIZE(out%statev))) = out%statev(1:MIN(SIZE(statev),SIZE(out%statev)))
      END IF
      spd = out%plastic_dissipation
      sse = out%elastic_energy
    END IF
    status = out%status
  END SUBROUTINE UF_MohrCoulomb_UMAT

  !----------------------------------------------------------------------------
  ! mc_compute_stress_invariants_pq
  !   Compute mean stress p and von Mises q from stress tensor.
  !----------------------------------------------------------------------------
  SUBROUTINE mc_compute_stress_invariants_pq(stress, ntens, p, q, s_dev)
    REAL(wp), INTENT(IN) :: stress(6)
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp), INTENT(OUT) :: p, q, s_dev(6)
    REAL(wp) :: p_mean, J2
    INTEGER(i4) :: i
    p_mean = ZERO
    DO i = 1, MIN(3, ntens)
      p_mean = p_mean + stress(i)
    END DO
    p_mean = p_mean / THREE
    p = -p_mean
    s_dev = stress
    DO i = 1, MIN(3, ntens)
      s_dev(i) = s_dev(i) - p_mean
    END DO
    J2 = 0.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2)
    IF (ntens >= 4) THEN
      J2 = J2 + s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2
    ELSE IF (ntens == 2) THEN
      J2 = J2 + s_dev(4)**2
    END IF
    q = SQRT(THREE * J2)
  END SUBROUTINE mc_compute_stress_invariants_pq

  !----------------------------------------------------------------------------
  ! mc_compute_tangent
  !   Compute consistent tangent stiffness matrix.
  !----------------------------------------------------------------------------
  SUBROUTINE mc_compute_tangent(D_elastic, K, mu, sin_phi, sin_psi, &
                               cos_phi, H_c, q_trial, ntens, D_tangent)
    REAL(wp), INTENT(IN) :: D_elastic(6,6)
    REAL(wp), INTENT(IN) :: K, mu, sin_phi, sin_psi, cos_phi, H_c, q_trial
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp), INTENT(OUT) :: D_tangent(6,6)
    INTEGER(i4) :: i, j
    REAL(wp) :: denominator, theta
    D_tangent = D_elastic
    IF (q_trial < 1.0e-12_wp) RETURN
    denominator = THREE * mu + K * sin_phi * sin_psi + H_c * cos_phi
    IF (ABS(denominator) < 1.0e-12_wp) RETURN
    theta = ONE / denominator
    DO i = 1, ntens
      DO j = 1, ntens
        IF (i <= 3 .AND. j <= 3) THEN
          D_tangent(i,j) = D_tangent(i,j) - K**2 * sin_phi * sin_psi * theta
        END IF
        IF (i > 3 .OR. j > 3) THEN
          IF (i == j) THEN
            D_tangent(i,j) = D_tangent(i,j) - THREE * mu**2 * theta / q_trial
          END IF
        END IF
      END DO
    END DO
  END SUBROUTINE mc_compute_tangent

  !=============================================================================
  ! PH_Mat_Geo_MC_Eval_Wrapper
  !   Four-type wrapper around MohrCoulomb_UpdateStress.
  !   Bridges PH_Mat_Geo_Desc/State/Algo -> MatPoint_In/Out.
  !=============================================================================
  SUBROUTINE PH_Mat_Geo_MC_Eval_Wrapper(desc, state, algo, strain, stress, ddsdde, status)
    TYPE(PH_Mat_Geo_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Geo_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Geo_Algo), INTENT(IN) :: algo
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MatPoint_In) :: mp_in
    TYPE(MatPoint_Out) :: mp_out
    REAL(wp) :: props_local(8), strain_inc(6), sigma_old(6)
    REAL(wp), ALLOCATABLE :: statev_local(:)
    INTEGER(i4) :: i

    CALL init_error_status(status)

    !--- Assemble props array: [c, phi, psi, E, nu, Hc, Hphi, Hpsi]
    props_local(1) = desc%cohesion
    props_local(2) = desc%phi
    props_local(3) = desc%psi
    props_local(4) = desc%E
    props_local(5) = desc%nu
    props_local(6) = 0.0_wp   ! H_c (no hardening from Desc)
    props_local(7) = 0.0_wp   ! H_phi
    props_local(8) = 0.0_wp   ! H_psi

    !--- Strain increment = total strain - accumulated strain
    strain_inc = strain - state%strain

    !--- Previous stress from state
    sigma_old = state%stress

    !--- State variable array (11 components)
    ALLOCATE(statev_local(11))
    statev_local = 0.0_wp
    statev_local(1) = state%equiv_plastic_strain
    DO i = 1, 6
      statev_local(5 + i) = state%plastic_strain(i)
    END DO

    !--- Fill MatPoint_In
    mp_in%ntens = 6
    ALLOCATE(mp_in%props, SOURCE=props_local)
    mp_in%sigma_old = sigma_old
    mp_in%strain_inc = strain_inc
    IF (ALLOCATED(mp_in%statev)) DEALLOCATE(mp_in%statev)
    ALLOCATE(mp_in%statev, SOURCE=statev_local)

    !--- Call core algorithm
    CALL MohrCoulomb_UpdateStress(mp_in, mp_out)

    !--- Check status
    IF (mp_out%status%status_code /= IF_STATUS_OK) THEN
      status = mp_out%status
      DEALLOCATE(statev_local)
      RETURN
    END IF

    !--- Extract results
    stress = mp_out%sigma
    ddsdde = mp_out%ddsdde

    !--- Update state
    state%stress = stress
    state%strain = strain
    IF (ALLOCATED(mp_out%statev)) THEN
      state%equiv_plastic_strain = mp_out%statev(1)
      DO i = 1, 6
        state%plastic_strain(i) = mp_out%statev(5 + i)
      END DO
    END IF
    state%initialized = .TRUE.

    DEALLOCATE(statev_local)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Geo_MC_Eval_Wrapper

END MODULE PH_Mat_Geo_MohrCoulomb_Core