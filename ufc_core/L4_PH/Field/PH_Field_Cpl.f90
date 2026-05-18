!===============================================================================
! MODULE: PH_Field_Cpl
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — multiphysics scalar coupling kernels
! BRIEF:  Element-level acoustic, eddy-current, transport, piezo stiffness,
!         and thermo-mech/hydro-mech/mass-diffusion coupling interfaces.
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Coupling | FuncSet:MultiPhysics
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_Cpl
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  ! --- Coupling type enumerations (PH_FIELD_CPL_ prefix) ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_CPL_THERMO_MECH    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_CPL_HYDRO_MECH     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FIELD_CPL_MASS_DIFFUSION = 3_i4

  ! --- Existing element-level FE contribution kernels ---
  PUBLIC :: PH_Acoustic_StiffnessContrib
  PUBLIC :: PH_ElectroMag_StiffnessContrib
  PUBLIC :: PH_SSTrans_ConvectiveContrib
  PUBLIC :: PH_Piezo_CouplingContrib

  ! --- Multi-physics coupling interfaces ---
  PUBLIC :: PH_Field_Cpl_ThermoMech
  PUBLIC :: PH_Field_Cpl_HydroMech
  PUBLIC :: PH_Field_Cpl_MassDiffusion
  PUBLIC :: PH_Field_Cpl_Apply
  PUBLIC :: PH_Field_Cpl_Update

CONTAINS

  !> Acoustic (pressure) Laplacian-like stiffness: add rho_inv * w * detJ * (∇N_i·∇N_j).
  SUBROUTINE PH_Acoustic_StiffnessContrib(dNdx, rho_inv, detJ, weight, npe, K_e, mesh_st)
    REAL(wp), INTENT(IN) :: dNdx(:, :)
    REAL(wp), INTENT(IN) :: rho_inv, detJ, weight
    INTEGER(i4), INTENT(IN) :: npe
    REAL(wp), INTENT(INOUT) :: K_e(:, :)
    TYPE(ErrorStatusType), INTENT(INOUT) :: mesh_st

    INTEGER(i4) :: i, j, k
    REAL(wp) :: c, kij

    IF (npe < 1_i4) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (SIZE(dNdx, 2) < npe .OR. SIZE(K_e, 1) < npe .OR. SIZE(K_e, 2) < npe) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    c = rho_inv * weight * detJ
    DO j = 1, npe
      DO i = 1, npe
        kij = 0.0_wp
        DO k = 1, 3
          kij = kij + dNdx(k, i) * dNdx(k, j)
        END DO
        K_e(i, j) = K_e(i, j) + c * kij
      END DO
    END DO
    mesh_st%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Acoustic_StiffnessContrib

  !> Eddy-current / magnetostatic scalar potential: add mu_inv * w * detJ * (∇N_i·∇N_j).
  SUBROUTINE PH_ElectroMag_StiffnessContrib(dNdx, mu_inv, detJ, weight, npe, K_e, mesh_st)
    REAL(wp), INTENT(IN) :: dNdx(:, :)
    REAL(wp), INTENT(IN) :: mu_inv, detJ, weight
    INTEGER(i4), INTENT(IN) :: npe
    REAL(wp), INTENT(INOUT) :: K_e(:, :)
    TYPE(ErrorStatusType), INTENT(INOUT) :: mesh_st

    INTEGER(i4) :: i, j, k
    REAL(wp) :: c, kij

    IF (npe < 1_i4) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (SIZE(dNdx, 2) < npe .OR. SIZE(K_e, 1) < npe .OR. SIZE(K_e, 2) < npe) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    c = mu_inv * weight * detJ
    DO j = 1, npe
      DO i = 1, npe
        kij = 0.0_wp
        DO k = 1, 3
          kij = kij + dNdx(k, i) * dNdx(k, j)
        END DO
        K_e(i, j) = K_e(i, j) + c * kij
      END DO
    END DO
    mesh_st%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ElectroMag_StiffnessContrib

  !> Steady scalar transport convection: add ∫ N_i (v·∇N_j) dV (Galerkin).
  SUBROUTINE PH_SSTrans_ConvectiveContrib(N, dNdx, v, detJ, weight, npe, K_conv_e, mesh_st)
    REAL(wp), INTENT(IN) :: N(:)
    REAL(wp), INTENT(IN) :: dNdx(:, :)
    REAL(wp), INTENT(IN) :: v(3)
    REAL(wp), INTENT(IN) :: detJ, weight
    INTEGER(i4), INTENT(IN) :: npe
    REAL(wp), INTENT(INOUT) :: K_conv_e(:, :)
    TYPE(ErrorStatusType), INTENT(INOUT) :: mesh_st

    INTEGER(i4) :: i, j
    REAL(wp) :: vdN

    IF (npe < 1_i4) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (SIZE(dNdx, 2) < npe .OR. SIZE(K_conv_e, 1) < npe .OR. SIZE(K_conv_e, 2) < npe) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO j = 1, npe
      vdN = v(1) * dNdx(1, j) + v(2) * dNdx(2, j) + v(3) * dNdx(3, j)
      DO i = 1, npe
        K_conv_e(i, j) = K_conv_e(i, j) + weight * detJ * N(i) * vdN
      END DO
    END DO
    mesh_st%status_code = IF_STATUS_OK
  END SUBROUTINE PH_SSTrans_ConvectiveContrib

  !> Piezoelectric coupling increment: K_ue += w * detJ * B_u^T * d * (∇N_phi) per column.
  SUBROUTINE PH_Piezo_CouplingContrib(B_u, dNdx, d_piezo, detJ, weight, K_ue_e, mesh_st)
    REAL(wp), INTENT(IN) :: B_u(:, :)
    REAL(wp), INTENT(IN) :: dNdx(:, :)
    REAL(wp), INTENT(IN) :: d_piezo(6, 3)
    REAL(wp), INTENT(IN) :: detJ, weight
    REAL(wp), INTENT(INOUT) :: K_ue_e(:, :)
    TYPE(ErrorStatusType), INTENT(INOUT) :: mesh_st

    INTEGER(i4) :: npe, nu, i, j
    REAL(wp) :: fvec(6)

    npe = INT(SIZE(dNdx, 2), i4)
    nu = INT(SIZE(B_u, 2), i4)
    IF (npe < 1_i4 .OR. nu < 1_i4) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (SIZE(B_u, 1) < 6_i4 .OR. SIZE(K_ue_e, 1) < nu .OR. SIZE(K_ue_e, 2) < npe) THEN
      mesh_st%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO j = 1, npe
      fvec(1:6) = MATMUL(d_piezo(1:6, 1:3), dNdx(1:3, j))
      DO i = 1, nu
        K_ue_e(i, j) = K_ue_e(i, j) + weight * detJ * DOT_PRODUCT(B_u(1:6, i), fvec(1:6))
      END DO
    END DO
    mesh_st%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Piezo_CouplingContrib

  ! ========================================================================
  ! MULTI-PHYSICS COUPLING: Temperature -> Material (Thermo-Mechanical)
  ! ========================================================================
  !> @brief Compute thermal expansion strain increment at Gauss points.
  !! eps_th(i) = alpha(i) * (T_gp - T_ref) for i=1..ndim (normal components)
  !! Shear components remain zero (isotropic CTE assumed).
  !!
  !! @param[in]  T_gp      Temperature at current Gauss point
  !! @param[in]  T_ref     Reference (stress-free) temperature
  !! @param[in]  alpha     Thermal expansion coefficient [1/K] (isotropic)
  !! @param[in]  ndim      Spatial dimension (2 or 3)
  !! @param[out] eps_th    Thermal strain increment (Voigt: 6)
  !! @param[out] status    Error status
  SUBROUTINE PH_Field_Cpl_ThermoMech(T_gp, T_ref, alpha, ndim, &
                                      eps_th, status)
    REAL(wp),    INTENT(IN)  :: T_gp
    REAL(wp),    INTENT(IN)  :: T_ref
    REAL(wp),    INTENT(IN)  :: alpha
    INTEGER(i4), INTENT(IN)  :: ndim
    REAL(wp),    INTENT(OUT) :: eps_th(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: dT

    CALL init_error_status(status)

    ! Validate dimension
    IF (ndim < 2_i4 .OR. ndim > 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_ThermoMech: ndim must be 2 or 3'
      RETURN
    END IF

    ! Temperature increment from reference
    dT = T_gp - T_ref

    ! Isotropic thermal strain: eps_th = alpha * dT * I (normal components)
    eps_th = 0.0_wp
    eps_th(1) = alpha * dT   ! eps_11
    eps_th(2) = alpha * dT   ! eps_22
    IF (ndim == 3_i4) THEN
      eps_th(3) = alpha * dT ! eps_33
    END IF
    ! eps_th(4:6) = 0 (shear components, isotropic CTE)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Cpl_ThermoMech

  ! ========================================================================
  ! MULTI-PHYSICS COUPLING: Pore Pressure -> Constitutive (Hydro-Mechanical)
  ! ========================================================================
  !> @brief Compute effective stress via Terzaghi-Biot principle.
  !! sigma_eff(i) = sigma_total(i) - biot_alpha * p  for i=1..3 (normals)
  !! sigma_eff(i) = sigma_total(i)                   for i=4..6 (shears)
  !!
  !! @param[in]  sigma_total  Total stress tensor (Voigt: 6)
  !! @param[in]  pore_p       Pore pressure at Gauss point
  !! @param[in]  biot_alpha   Biot coefficient (0 < biot_alpha <= 1)
  !! @param[out] sigma_eff    Effective stress tensor (Voigt: 6)
  !! @param[out] status       Error status
  SUBROUTINE PH_Field_Cpl_HydroMech(sigma_total, pore_p, biot_alpha, &
                                     sigma_eff, status)
    REAL(wp), INTENT(IN)  :: sigma_total(6)
    REAL(wp), INTENT(IN)  :: pore_p
    REAL(wp), INTENT(IN)  :: biot_alpha
    REAL(wp), INTENT(OUT) :: sigma_eff(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Validate Biot coefficient range
    IF (biot_alpha < 0.0_wp .OR. biot_alpha > 1.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_HydroMech: biot_alpha must be in [0,1]'
      RETURN
    END IF

    ! Effective stress: sigma_eff = sigma_total - biot_alpha * p * I
    ! Normal components: subtract pore pressure contribution
    sigma_eff(1) = sigma_total(1) - biot_alpha * pore_p
    sigma_eff(2) = sigma_total(2) - biot_alpha * pore_p
    sigma_eff(3) = sigma_total(3) - biot_alpha * pore_p
    ! Shear components: unaffected by pore pressure
    sigma_eff(4) = sigma_total(4)
    sigma_eff(5) = sigma_total(5)
    sigma_eff(6) = sigma_total(6)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Cpl_HydroMech

  ! ========================================================================
  ! MULTI-PHYSICS COUPLING: Concentration -> Diffusion (Mass Transport)
  ! ========================================================================
  !> @brief Compute diffusion flux at a Gauss point via Fick's first law.
  !! J(k) = -D * grad_c(k)  for k=1..ndim
  !!
  !! @param[in]  grad_c     Concentration gradient at GP [ndim]
  !! @param[in]  D_coeff    Diffusion coefficient [m^2/s] (isotropic scalar)
  !! @param[in]  ndim       Spatial dimension (2 or 3)
  !! @param[out] flux       Diffusion flux vector [3] (zero-padded if ndim<3)
  !! @param[out] status     Error status
  SUBROUTINE PH_Field_Cpl_MassDiffusion(grad_c, D_coeff, ndim, flux, status)
    REAL(wp),    INTENT(IN)  :: grad_c(:)
    REAL(wp),    INTENT(IN)  :: D_coeff
    INTEGER(i4), INTENT(IN)  :: ndim
    REAL(wp),    INTENT(OUT) :: flux(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)

    ! Validate inputs
    IF (ndim < 2_i4 .OR. ndim > 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_MassDiffusion: ndim must be 2 or 3'
      RETURN
    END IF
    IF (SIZE(grad_c) < ndim) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_MassDiffusion: grad_c size < ndim'
      RETURN
    END IF
    IF (D_coeff < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_MassDiffusion: D_coeff must be >= 0'
      RETURN
    END IF

    ! Fick's first law: J = -D * grad(c)
    flux = 0.0_wp
    DO k = 1, ndim
      flux(k) = -D_coeff * grad_c(k)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Cpl_MassDiffusion

  ! ========================================================================
  ! GENERIC COUPLING DISPATCHER
  ! ========================================================================
  !> @brief Dispatch coupling computation by type enumeration.
  !! Routes to ThermoMech / HydroMech / MassDiffusion based on cpl_type.
  !!
  !! @param[in]    cpl_type      Coupling type (PH_FIELD_CPL_THERMO_MECH, etc.)
  !! @param[in]    scalar_field  Primary scalar field value at GP (T, p, or c)
  !! @param[in]    ref_value     Reference value (T_ref, 0, or 0)
  !! @param[in]    coeff         Coupling coefficient (alpha, biot, D)
  !! @param[in]    ndim          Spatial dimension
  !! @param[in]    grad_in       Gradient input [3] (used by MassDiffusion)
  !! @param[in]    stress_in     Total stress input [6] (used by HydroMech)
  !! @param[out]   result_vec6   Result vector [6] (strain or stress output)
  !! @param[out]   result_vec3   Result vector [3] (flux output)
  !! @param[out]   status        Error status
  SUBROUTINE PH_Field_Cpl_Apply(cpl_type, scalar_field, ref_value, coeff, &
                                 ndim, grad_in, stress_in, &
                                 result_vec6, result_vec3, status)
    INTEGER(i4), INTENT(IN)  :: cpl_type
    REAL(wp),    INTENT(IN)  :: scalar_field
    REAL(wp),    INTENT(IN)  :: ref_value
    REAL(wp),    INTENT(IN)  :: coeff
    INTEGER(i4), INTENT(IN)  :: ndim
    REAL(wp),    INTENT(IN)  :: grad_in(3)
    REAL(wp),    INTENT(IN)  :: stress_in(6)
    REAL(wp),    INTENT(OUT) :: result_vec6(6)
    REAL(wp),    INTENT(OUT) :: result_vec3(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    result_vec6 = 0.0_wp
    result_vec3 = 0.0_wp

    SELECT CASE (cpl_type)

    CASE (PH_FIELD_CPL_THERMO_MECH)
      ! scalar_field = T_gp, ref_value = T_ref, coeff = alpha
      CALL PH_Field_Cpl_ThermoMech(scalar_field, ref_value, coeff, ndim, &
                                    result_vec6, status)

    CASE (PH_FIELD_CPL_HYDRO_MECH)
      ! scalar_field = pore_p, coeff = biot_alpha
      CALL PH_Field_Cpl_HydroMech(stress_in, scalar_field, coeff, &
                                   result_vec6, status)

    CASE (PH_FIELD_CPL_MASS_DIFFUSION)
      ! coeff = D, grad_in = concentration gradient
      CALL PH_Field_Cpl_MassDiffusion(grad_in, coeff, ndim, &
                                       result_vec3, status)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_Apply: unknown cpl_type'
      RETURN

    END SELECT
  END SUBROUTINE PH_Field_Cpl_Apply

  ! ========================================================================
  ! COUPLING SYNCHRONIZATION AFTER TIME STEP UPDATE
  ! ========================================================================
  !> @brief Synchronize coupling quantities after a converged time step.
  !! Recomputes thermal strain, effective stress, and diffusion flux arrays
  !! over all Gauss points for a single element.
  !!
  !! @param[in]    n_ip          Number of integration points
  !! @param[in]    ndim          Spatial dimension
  !! @param[in]    dt            Time step size (for rate-dependent coupling)
  !! @param[in]    T_gp          Temperature at each GP [n_ip]
  !! @param[in]    T_ref         Reference temperature
  !! @param[in]    alpha         Thermal expansion coefficient
  !! @param[in]    pore_p_gp     Pore pressure at each GP [n_ip]
  !! @param[in]    biot          Biot coefficient
  !! @param[in]    sigma_gp      Total stress at each GP [6, n_ip]
  !! @param[in]    grad_c_gp     Concentration gradient at each GP [3, n_ip]
  !! @param[in]    D_coeff       Diffusion coefficient
  !! @param[out]   eps_th_gp     Thermal strain at each GP [6, n_ip]
  !! @param[out]   sigma_eff_gp  Effective stress at each GP [6, n_ip]
  !! @param[out]   flux_gp       Diffusion flux at each GP [3, n_ip]
  !! @param[out]   status        Error status
  SUBROUTINE PH_Field_Cpl_Update(n_ip, ndim, dt, &
                                  T_gp, T_ref, alpha, &
                                  pore_p_gp, biot, sigma_gp, &
                                  grad_c_gp, D_coeff, &
                                  eps_th_gp, sigma_eff_gp, flux_gp, &
                                  status)
    INTEGER(i4), INTENT(IN)  :: n_ip
    INTEGER(i4), INTENT(IN)  :: ndim
    REAL(wp),    INTENT(IN)  :: dt
    REAL(wp),    INTENT(IN)  :: T_gp(:)
    REAL(wp),    INTENT(IN)  :: T_ref
    REAL(wp),    INTENT(IN)  :: alpha
    REAL(wp),    INTENT(IN)  :: pore_p_gp(:)
    REAL(wp),    INTENT(IN)  :: biot
    REAL(wp),    INTENT(IN)  :: sigma_gp(:,:)
    REAL(wp),    INTENT(IN)  :: grad_c_gp(:,:)
    REAL(wp),    INTENT(IN)  :: D_coeff
    REAL(wp),    INTENT(OUT) :: eps_th_gp(:,:)
    REAL(wp),    INTENT(OUT) :: sigma_eff_gp(:,:)
    REAL(wp),    INTENT(OUT) :: flux_gp(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: ip
    TYPE(ErrorStatusType) :: sub_st

    CALL init_error_status(status)

    ! Validate array sizes
    IF (n_ip < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_Update: n_ip must be >= 1'
      RETURN
    END IF
    IF (SIZE(T_gp) < n_ip .OR. SIZE(pore_p_gp) < n_ip) THEN
      status%status_code = IF_STATUS_INVALID
      status%error_message = 'PH_Field_Cpl_Update: input array size < n_ip'
      RETURN
    END IF

    eps_th_gp     = 0.0_wp
    sigma_eff_gp  = 0.0_wp
    flux_gp       = 0.0_wp

    DO ip = 1, n_ip
      ! 1. Thermo-mechanical coupling: thermal strain
      CALL PH_Field_Cpl_ThermoMech(T_gp(ip), T_ref, alpha, ndim, &
                                    eps_th_gp(:, ip), sub_st)
      IF (sub_st%status_code /= IF_STATUS_OK) THEN
        status = sub_st
        RETURN
      END IF

      ! 2. Hydro-mechanical coupling: effective stress
      CALL PH_Field_Cpl_HydroMech(sigma_gp(:, ip), pore_p_gp(ip), biot, &
                                   sigma_eff_gp(:, ip), sub_st)
      IF (sub_st%status_code /= IF_STATUS_OK) THEN
        status = sub_st
        RETURN
      END IF

      ! 3. Mass diffusion coupling: diffusion flux
      CALL PH_Field_Cpl_MassDiffusion(grad_c_gp(:, ip), D_coeff, ndim, &
                                       flux_gp(:, ip), sub_st)
      IF (sub_st%status_code /= IF_STATUS_OK) THEN
        status = sub_st
        RETURN
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Field_Cpl_Update

END MODULE PH_Field_Cpl
