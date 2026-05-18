!===============================================================================
! MODULE: PH_Field_Interpolate
! LAYER:  L4_PH
! DOMAIN: Field
! ROLE:   Eval — hot-path GP-level interpolation/extrapolation kernels
! BRIEF:  Node→GP interpolation, GP→node extrapolation (least-squares),
!         thermal strain, effective stress, Fick flux computation.
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Field | role:Interpolate | FuncSet:HotPath
!>>> UFC_PH_CONTRACT | Field/CONTRACT.md

MODULE PH_Field_Interpolate
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC INTERFACES
  ! ==========================================================================
  PUBLIC :: PH_Field_NodeToGP          ! Node values → GP interpolation
  PUBLIC :: PH_Field_GradAtGP          ! GP gradient computation
  PUBLIC :: PH_Field_GPToNode          ! GP → Node extrapolation (least-squares)
  PUBLIC :: PH_Field_ThermalStrain     ! Thermal expansion strain ε_th = α*(T-T0)*I
  PUBLIC :: PH_Field_ThermalStrain_Aniso ! Anisotropic thermal expansion
  PUBLIC :: PH_Field_EffStress         ! Biot effective stress σ' = σ + α_B*p*I
  PUBLIC :: PH_Field_FickFlux          ! Fick diffusion flux J = -D*∇c
  PUBLIC :: PH_Field_FickFlux_Aniso    ! Anisotropic Fick flux J = -D_ij*∇c
  PUBLIC :: PH_Field_BuildExtrapC3D8   ! Build C3D8 8×8 extrapolation matrix

  ! ==========================================================================
  ! CONSTANTS
  ! ==========================================================================
  INTEGER(i4), PARAMETER :: MAX_NPE   = 27_i4   ! Max nodes per element (C3D27)
  INTEGER(i4), PARAMETER :: MAX_N_GP  = 27_i4   ! Max Gauss points (3×3×3)
  INTEGER(i4), PARAMETER :: VOIGT_DIM = 6_i4    ! Voigt notation components

  ! --------------------------------------------------------------------------
  ! C3D8 Extrapolation constants (2×2×2 Gauss → 8 nodes)
  ! 1D extrapolation: evaluate linear Lagrange through GP at ξ=±1/√3
  !   onto node at ξ=±1.
  !   a = (1+√3)/2,  b = (1-√3)/2
  ! 3D tensor product: E(I,g) = e1(ix,gx)*e1(iy,gy)*e1(iz,gz)
  ! --------------------------------------------------------------------------
  REAL(wp), PARAMETER :: EXTRAP_A = 1.3660254037844386_wp  ! (1+√3)/2
  REAL(wp), PARAMETER :: EXTRAP_B = -0.3660254037844386_wp  ! (1-√3)/2

  ! Node/GP local sign pattern for C3D8 (ξ,η,ζ signs per node)
  !   Node 1(-,-,-), 2(+,-,-), 3(+,+,-), 4(-,+,-),
  !   Node 5(-,-,+), 6(+,-,+), 7(+,+,+), 8(-,+,+)
  INTEGER(i4), PARAMETER :: C3D8_SIGN(3,8) = RESHAPE( &
    (/ -1, -1, -1,   1, -1, -1,   1, 1, -1,  -1, 1, -1, &
       -1, -1,  1,   1, -1,  1,   1, 1,  1,  -1, 1,  1 /), &
    (/ 3, 8 /))

CONTAINS

  !---------------------------------------------------------------------------
  ! PH_Field_NodeToGP: Interpolate scalar field from nodes to Gauss point
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §2.1
  ! Formula:
  !   T(ξ_g) = Σ_{I=1}^{npe} N_I(ξ_g) * T_I
  !   Vector form: T_gp = N^T * T_e
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_NodeToGP(T_nodal, N_shape, npe, T_gp, status)
    REAL(wp), INTENT(IN)  :: T_nodal(:)    ! [IN] Nodal field values (npe)
    REAL(wp), INTENT(IN)  :: N_shape(:)    ! [IN] Shape functions at GP (npe)
    INTEGER(i4), INTENT(IN) :: npe         ! [IN] Nodes per element
    REAL(wp), INTENT(OUT) :: T_gp          ! [OUT] Field value at GP
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    INTEGER(i4) :: I

    T_gp = 0.0_wp
    DO I = 1, npe
      T_gp = T_gp + N_shape(I) * T_nodal(I)
    END DO

  END SUBROUTINE PH_Field_NodeToGP

  !---------------------------------------------------------------------------
  ! PH_Field_GradAtGP: Compute field gradient at Gauss point
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §2.2
  ! Formula:
  !   ∇T(ξ_g) = Σ_{I=1}^{npe} (∂N_I/∂x) * T_I
  !   where ∂N/∂x = J^{-1} * ∂N/∂ξ  (physical gradient via Jacobian inverse)
  !
  !   J = ∂x/∂ξ = Σ_I (∂N_I/∂ξ) ⊗ x_I
  !   gradT = dNdx * T_nodal  →  (ndim) = (ndim, npe) × (npe)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_GradAtGP(T_nodal, dNdx, npe, ndim, gradT, status)
    REAL(wp), INTENT(IN)  :: T_nodal(:)     ! [IN] Nodal field values (npe)
    REAL(wp), INTENT(IN)  :: dNdx(:,:)      ! [IN] Physical shape func gradient (ndim, npe)
    INTEGER(i4), INTENT(IN) :: npe          ! [IN] Nodes per element
    INTEGER(i4), INTENT(IN) :: ndim         ! [IN] Spatial dimension (2 or 3)
    REAL(wp), INTENT(OUT) :: gradT(:)       ! [OUT] Field gradient at GP (ndim)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    INTEGER(i4) :: I, d

    gradT(1:ndim) = 0.0_wp
    DO I = 1, npe
      DO d = 1, ndim
        gradT(d) = gradT(d) + dNdx(d, I) * T_nodal(I)
      END DO
    END DO

  END SUBROUTINE PH_Field_GradAtGP

  !---------------------------------------------------------------------------
  ! PH_Field_GPToNode: Extrapolate GP values to nodes (superconvergent)
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §6
  ! Algorithm:
  !   For 2×2×2 Gauss → 8-node hex (C3D8):
  !     T_I^node = Σ_{g=1}^{ngp} E_{Ig} * T_g^gp
  !     E_{Ig} = N_I(ξ_g^extrap)
  !     ξ_g^extrap = sqrt(3) * ξ_g^gauss  (superconvergent extrapolation points)
  !
  !   For global smoothing (multi-element shared nodes):
  !     T_I^smooth = Σ_{e ∈ patch(I)} T_I^e / count(I)
  !     Handled by PH_Field_Ops.f90 node averaging.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_GPToNode(T_gp, ngp, npe, extrap_matrix, T_nodal, status)
    REAL(wp), INTENT(IN)  :: T_gp(:)               ! [IN] GP values (ngp)
    INTEGER(i4), INTENT(IN) :: ngp                  ! [IN] Number of Gauss points
    INTEGER(i4), INTENT(IN) :: npe                  ! [IN] Nodes per element
    REAL(wp), INTENT(IN)  :: extrap_matrix(:,:)     ! [IN] Extrapolation matrix E(npe, ngp)
    REAL(wp), INTENT(OUT) :: T_nodal(:)             ! [OUT] Extrapolated nodal values (npe)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status  ! [INOUT] Error status

    INTEGER(i4) :: I, g

    ! T_I = Σ_g E(I,g) * T_g
    T_nodal(1:npe) = 0.0_wp
    DO I = 1, npe
      DO g = 1, ngp
        T_nodal(I) = T_nodal(I) + extrap_matrix(I, g) * T_gp(g)
      END DO
    END DO

  END SUBROUTINE PH_Field_GPToNode

  !---------------------------------------------------------------------------
  ! PH_Field_BuildExtrapC3D8: Build 8×8 extrapolation matrix for C3D8
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §6.1
  ! Algorithm:
  !   1D extrapolation matrix e(i,g):
  !     same sign → a = (1+√3)/2,  opposite sign → b = (1-√3)/2
  !   3D tensor product:
  !     E(I,g) = e_x(I_x, g_x) * e_y(I_y, g_y) * e_z(I_z, g_z)
  !   This gives the superconvergent extrapolation from 2×2×2 GP to 8 nodes.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_BuildExtrapC3D8(E_mat, status)
    REAL(wp), INTENT(OUT) :: E_mat(8, 8)       ! [OUT] Extrapolation matrix (npe=8, ngp=8)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    INTEGER(i4) :: I, g, d
    REAL(wp) :: val

    ! Build via tensor product of 1D extrapolation coefficients
    ! e_1D(same_sign) = a,  e_1D(diff_sign) = b
    DO I = 1, 8
      DO g = 1, 8
        val = 1.0_wp
        DO d = 1, 3
          IF (C3D8_SIGN(d, I) == C3D8_SIGN(d, g)) THEN
            val = val * EXTRAP_A
          ELSE
            val = val * EXTRAP_B
          END IF
        END DO
        E_mat(I, g) = val
      END DO
    END DO

  END SUBROUTINE PH_Field_BuildExtrapC3D8

  !---------------------------------------------------------------------------
  ! PH_Field_ThermalStrain: Isotropic thermal expansion strain
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §3.1
  ! Formula:
  !   ε_th = α * (T - T_ref) * I
  !   Voigt notation (6-component):
  !     ε_th = α * ΔT * [1, 1, 1, 0, 0, 0]^T
  !   2D (plane strain/stress): only ε_th(1:2) non-zero
  !   3D: ε_th(1:3) non-zero
  !
  ! Existing impl: PH_Field_Cpl_ThermoMech (PH_Field_Cpl.f90 L186-219)
  ! This provides a lightweight direct-call kernel for hot-path use.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_ThermalStrain(T_gp, T_ref, alpha, ndim, eps_th, status)
    REAL(wp), INTENT(IN)  :: T_gp          ! [IN] Temperature at Gauss point
    REAL(wp), INTENT(IN)  :: T_ref         ! [IN] Reference temperature
    REAL(wp), INTENT(IN)  :: alpha         ! [IN] Thermal expansion coefficient [1/K]
    INTEGER(i4), INTENT(IN) :: ndim        ! [IN] Spatial dimension (2 or 3)
    REAL(wp), INTENT(OUT) :: eps_th(VOIGT_DIM)  ! [OUT] Thermal strain (Voigt)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    REAL(wp) :: delta_T

    eps_th(:) = 0.0_wp
    delta_T = T_gp - T_ref

    ! Validate thermal expansion coefficient
    IF (alpha < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_ThermalStrain: negative alpha'
      RETURN
    END IF

    ! ε_th = α * ΔT * [1, 1, 1, 0, 0, 0]^T
    SELECT CASE (ndim)
    CASE (2_i4)
      ! Plane strain/stress: ε_th(1) = ε_th(2) = α*ΔT
      eps_th(1) = alpha * delta_T
      eps_th(2) = alpha * delta_T
      ! eps_th(3) = α*ΔT for plane strain out-of-plane (context-dependent)
    CASE (3_i4)
      eps_th(1) = alpha * delta_T
      eps_th(2) = alpha * delta_T
      eps_th(3) = alpha * delta_T
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_ThermalStrain: invalid ndim'
    END SELECT
    ! Shear components eps_th(4:6) remain zero for isotropic expansion

  END SUBROUTINE PH_Field_ThermalStrain

  !---------------------------------------------------------------------------
  ! PH_Field_ThermalStrain_Aniso: Anisotropic thermal expansion strain
  !---------------------------------------------------------------------------
  ! Formula:
  !   ε_th(1) = α_1 * (T - T_ref)   (x-direction)
  !   ε_th(2) = α_2 * (T - T_ref)   (y-direction)
  !   ε_th(3) = α_3 * (T - T_ref)   (z-direction)
  !   ε_th(4:6) = 0                  (shear components)
  !   where α_i are direction-dependent CTE values.
  !   For 2D: only α_1, α_2 are used.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_ThermalStrain_Aniso(T_gp, T_ref, alpha_vec, ndim, eps_th, status)
    REAL(wp), INTENT(IN)  :: T_gp              ! [IN] Temperature at Gauss point
    REAL(wp), INTENT(IN)  :: T_ref             ! [IN] Reference temperature
    REAL(wp), INTENT(IN)  :: alpha_vec(:)      ! [IN] CTE vector [α_1, α_2, α_3] (ndim)
    INTEGER(i4), INTENT(IN) :: ndim            ! [IN] Spatial dimension (2 or 3)
    REAL(wp), INTENT(OUT) :: eps_th(VOIGT_DIM) ! [OUT] Thermal strain (Voigt)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    REAL(wp) :: delta_T
    INTEGER(i4) :: d

    eps_th(:) = 0.0_wp
    delta_T = T_gp - T_ref

    ! Validate inputs
    IF (ndim < 2_i4 .OR. ndim > 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_ThermalStrain_Aniso: invalid ndim'
      RETURN
    END IF
    IF (SIZE(alpha_vec) < ndim) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_ThermalStrain_Aniso: alpha_vec size < ndim'
      RETURN
    END IF

    ! ε_th(d) = α_d * ΔT  for d = 1..ndim (normal components)
    DO d = 1, ndim
      eps_th(d) = alpha_vec(d) * delta_T
    END DO
    ! Shear components eps_th(4:6) remain zero

  END SUBROUTINE PH_Field_ThermalStrain_Aniso

  !---------------------------------------------------------------------------
  ! PH_Field_EffStress: Biot effective stress modification
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §4.2
  ! Formula:
  !   σ'_ij = σ_ij + α_B * p * δ_ij   (Terzaghi when α_B = 1)
  !   Voigt: σ'(i) = σ(i) - α_B * p  for i = 1,2,3 (normal components)
  !          σ'(i) = σ(i)             for i = 4,5,6 (shear components)
  !   Sign convention: compression positive for pore pressure,
  !     so σ_eff = σ_total - α_B * p  (matches PH_Field_Cpl_HydroMech)
  !
  ! Existing impl: PH_Field_Cpl_HydroMech (PH_Field_Cpl.f90 L233-261)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_EffStress(sigma_total, pore_p, biot_alpha, sigma_eff, status)
    REAL(wp), INTENT(IN)  :: sigma_total(VOIGT_DIM) ! [IN] Total stress (Voigt)
    REAL(wp), INTENT(IN)  :: pore_p                 ! [IN] Pore pressure
    REAL(wp), INTENT(IN)  :: biot_alpha             ! [IN] Biot coefficient (0 ≤ α_B ≤ 1)
    REAL(wp), INTENT(OUT) :: sigma_eff(VOIGT_DIM)   ! [OUT] Effective stress (Voigt)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status  ! [INOUT] Error status

    ! Validate Biot coefficient
    IF (biot_alpha < 0.0_wp .OR. biot_alpha > 1.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_EffStress: biot_alpha out of [0,1]'
      RETURN
    END IF

    ! σ' = σ - α_B * p * I  (Voigt: modify normal components only)
    sigma_eff(1) = sigma_total(1) - biot_alpha * pore_p
    sigma_eff(2) = sigma_total(2) - biot_alpha * pore_p
    sigma_eff(3) = sigma_total(3) - biot_alpha * pore_p
    ! Shear components unchanged
    sigma_eff(4) = sigma_total(4)
    sigma_eff(5) = sigma_total(5)
    sigma_eff(6) = sigma_total(6)

  END SUBROUTINE PH_Field_EffStress

  !---------------------------------------------------------------------------
  ! PH_Field_FickFlux: Fick diffusion flux computation
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §5.1
  ! Formula:
  !   J = -D * ∇c   (Fick's first law)
  !   where D is diffusion coefficient [m^2/s], c is concentration,
  !   ∇c is concentration gradient at Gauss point.
  !
  ! Existing impl: PH_Field_Cpl_MassDiffusion (PH_Field_Cpl.f90 L274-316)
  ! Extension: anisotropic diffusion tensor D_ij via PH_Field_FickFlux_Aniso
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_FickFlux(grad_c, D_coeff, ndim, flux, status)
    REAL(wp), INTENT(IN)  :: grad_c(:)     ! [IN] Concentration gradient at GP (ndim)
    REAL(wp), INTENT(IN)  :: D_coeff       ! [IN] Isotropic diffusion coefficient [m^2/s]
    INTEGER(i4), INTENT(IN) :: ndim        ! [IN] Spatial dimension (2 or 3)
    REAL(wp), INTENT(OUT) :: flux(3)       ! [OUT] Diffusion flux vector (zero-padded to 3D)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    INTEGER(i4) :: d

    flux(:) = 0.0_wp

    ! Validate diffusion coefficient
    IF (D_coeff < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_FickFlux: negative diffusion coefficient'
      RETURN
    END IF

    ! J = -D * ∇c  (isotropic)
    DO d = 1, ndim
      flux(d) = -D_coeff * grad_c(d)
    END DO

    ! For anisotropic diffusion tensor, use PH_Field_FickFlux_Aniso below.

  END SUBROUTINE PH_Field_FickFlux

  !---------------------------------------------------------------------------
  ! PH_Field_FickFlux_Aniso: Anisotropic Fick diffusion flux
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Field_HotPath.md §8 完善点清単: 各向異性扩散
  ! Formula:
  !   J_i = -Σ_j D_ij * (∂c/∂x_j)    (Fick's first law, anisotropic)
  !   where D_ij is the symmetric diffusion tensor (3×3)
  !   Vector form: J = -D · ∇c  = -MATMUL(D_tensor, grad_c)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Field_FickFlux_Aniso(grad_c, D_tensor, ndim, flux, status)
    REAL(wp), INTENT(IN)  :: grad_c(:)         ! [IN] Concentration gradient at GP (ndim)
    REAL(wp), INTENT(IN)  :: D_tensor(:,:)     ! [IN] Anisotropic diffusion tensor (3,3)
    INTEGER(i4), INTENT(IN) :: ndim            ! [IN] Spatial dimension (2 or 3)
    REAL(wp), INTENT(OUT) :: flux(3)           ! [OUT] Diffusion flux vector (zero-padded to 3D)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    INTEGER(i4) :: i, j

    flux(:) = 0.0_wp

    ! Validate inputs
    IF (ndim < 2_i4 .OR. ndim > 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_FickFlux_Aniso: invalid ndim'
      RETURN
    END IF
    IF (SIZE(grad_c) < ndim) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_FickFlux_Aniso: grad_c size < ndim'
      RETURN
    END IF
    IF (SIZE(D_tensor, 1) < ndim .OR. SIZE(D_tensor, 2) < ndim) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Field_FickFlux_Aniso: D_tensor size < ndim'
      RETURN
    END IF

    ! J_i = -Σ_j D_ij * ∂c/∂x_j  (tensor diffusion)
    DO i = 1, ndim
      DO j = 1, ndim
        flux(i) = flux(i) - D_tensor(i, j) * grad_c(j)
      END DO
    END DO

  END SUBROUTINE PH_Field_FickFlux_Aniso

END MODULE PH_Field_Interpolate
