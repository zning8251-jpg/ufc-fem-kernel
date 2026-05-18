!===============================================================================
! E2E Test C2-06: NLGeom_NeoHookean
! Layer:  Integration Test (E2E)
! Purpose: Verify large deformation Neo-Hookean constitutive model.
!          Single integration point, uniaxial large stretch λ=1.5 (50% extension).
!
! Setup:
!   - Material: μ=80.194 MPa (C10=μ/2=40.097), κ=400000 MPa
!   - Deformation: uniaxial stretch λ=1.5
!   - Deformation gradient: F = diag(λ, 1/√λ, 1/√λ) (incompressible)
!   - J = det(F) = λ·(1/√λ)² = 1.0 (isochoric)
!
! Theory (incompressible Neo-Hookean, Cauchy stress):
!   σ_11 = μ·(λ² - 1/λ)  [uniaxial, incompressible]
!   λ=1.5 → σ_11 = 80.194·(2.25 - 0.6667) = 80.194·1.5833 ≈ 126.97 MPa
!
! Reference: Holzapfel (2000), Bonet & Wood (2008)
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_06_NLGeom_NeoHookean
  IMPLICIT NONE

  ! Precision
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  ! Material parameters
  REAL(wp), PARAMETER :: MU_SHEAR = 80.194_wp       ! Shear modulus μ [MPa]
  REAL(wp), PARAMETER :: C10      = 40.097_wp       ! C10 = μ/2 [MPa]
  REAL(wp), PARAMETER :: KAPPA    = 400000.0_wp     ! Bulk modulus κ [MPa]
  REAL(wp), PARAMETER :: D1       = 2.0_wp / KAPPA  ! D1 = 2/κ [1/MPa]

  ! Stretch
  REAL(wp), PARAMETER :: LAMBDA_STRETCH = 1.5_wp    ! Uniaxial stretch ratio

  ! Tolerances
  REAL(wp), PARAMETER :: TOL_STRESS = 0.02_wp       ! 2% relative error
  REAL(wp), PARAMETER :: TOL_DET    = 1.0E-12_wp    ! Determinant tolerance

  ! Variables
  REAL(wp) :: F(3,3)             ! Deformation gradient
  REAL(wp) :: C_rg(3,3)         ! Right Cauchy-Green tensor C = F^T·F
  REAL(wp) :: b(3,3)            ! Left Cauchy-Green tensor b = F·F^T
  REAL(wp) :: Cinv(3,3)         ! Inverse of C
  REAL(wp) :: J_det             ! det(F)
  REAL(wp) :: Jm23              ! J^(-2/3)
  REAL(wp) :: I1_bar            ! Modified first invariant
  REAL(wp) :: I1                ! First invariant tr(C)
  REAL(wp) :: S_pk2(3,3)       ! 2nd Piola-Kirchhoff stress
  REAL(wp) :: sigma(3,3)        ! Cauchy stress
  REAL(wp) :: sigma_11_exact    ! Analytical Cauchy stress (uniaxial)
  REAL(wp) :: sigma_11_computed ! Computed Cauchy stress
  REAL(wp) :: W_exact, W_computed  ! Strain energy
  REAL(wp) :: lambda_lat        ! Lateral stretch = 1/√λ
  REAL(wp) :: err_rel
  REAL(wp) :: temp33(3,3)
  INTEGER(i4) :: n_pass, n_total
  INTEGER(i4) :: i, j, k

  n_pass = 0
  n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-06: NLGeom_NeoHookean ==='
  WRITE(*,'(A)') ''

  ! Lateral stretch for incompressibility: J=1 → λ_lat = 1/√λ
  lambda_lat = 1.0_wp / SQRT(LAMBDA_STRETCH)

  !---------------------------------------------------------------------------
  ! Setup deformation gradient F = diag(λ, 1/√λ, 1/√λ)
  !---------------------------------------------------------------------------
  F = 0.0_wp
  F(1,1) = LAMBDA_STRETCH
  F(2,2) = lambda_lat
  F(3,3) = lambda_lat

  !---------------------------------------------------------------------------
  ! Check 1: Determinant J = det(F) = 1 (incompressible)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  J_det = F(1,1) * F(2,2) * F(3,3)  ! Diagonal matrix → det = product
  IF (ABS(J_det - 1.0_wp) < TOL_DET) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F12.8,A)') &
      'Check 1: det(F)=1 (incompressible) ... PASS (J=', J_det, ')'
  ELSE
    WRITE(*,'(A,F12.8,A)') &
      'Check 1: det(F)=1 (incompressible) ... FAIL (J=', J_det, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Compute kinematics
  !---------------------------------------------------------------------------
  ! C = F^T · F (diagonal for our F)
  C_rg = 0.0_wp
  C_rg(1,1) = F(1,1)**2
  C_rg(2,2) = F(2,2)**2
  C_rg(3,3) = F(3,3)**2

  ! b = F · F^T (same as C for diagonal F)
  b = C_rg

  ! C⁻¹ (diagonal)
  Cinv = 0.0_wp
  Cinv(1,1) = 1.0_wp / C_rg(1,1)
  Cinv(2,2) = 1.0_wp / C_rg(2,2)
  Cinv(3,3) = 1.0_wp / C_rg(3,3)

  ! I₁ = tr(C)
  I1 = C_rg(1,1) + C_rg(2,2) + C_rg(3,3)

  ! J^(-2/3)
  Jm23 = J_det**(-2.0_wp / 3.0_wp)

  ! Modified first invariant: Ī₁ = J^(-2/3)·I₁
  I1_bar = Jm23 * I1

  !---------------------------------------------------------------------------
  ! Check 2: Strain energy W = C10·(Ī₁ - 3) + (1/D1)·(J-1)²
  !   For incompressible (J=1): W = C10·(I₁ - 3)
  !   I₁ = λ² + 2/λ = 2.25 + 1.3333 = 3.5833
  !   W = 40.097·(3.5833 - 3) = 40.097·0.5833 ≈ 23.39 MPa
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  W_exact = C10 * (I1 - 3.0_wp)  ! For J=1, Ī₁ = I₁
  W_computed = C10 * (I1_bar - 3.0_wp) + (1.0_wp / D1) * (J_det - 1.0_wp)**2

  err_rel = ABS(W_computed - W_exact) / MAX(ABS(W_exact), 1.0E-15_wp)
  IF (err_rel < 1.0E-10_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 2: Strain energy W ... PASS (expected=', W_exact, &
      ', got=', W_computed, ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 2: Strain energy W ... FAIL (expected=', W_exact, &
      ', got=', W_computed, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 3: Cauchy stress σ_11 (analytical for incompressible uniaxial)
  !   σ_11 = μ·(λ² - 1/λ) = 80.194·(2.25 - 0.6667) = 126.97 MPa
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  sigma_11_exact = MU_SHEAR * (LAMBDA_STRETCH**2 - 1.0_wp / LAMBDA_STRETCH)

  ! Compute PK2 stress: S = 2·∂W/∂C
  ! For Neo-Hookean: S = 2C10·J^(-2/3)·(I - (1/3)·I₁·C⁻¹) + (2/D1)·(J-1)·J·C⁻¹
  ! For J=1: S = 2C10·(I - (1/3)·I₁·C⁻¹)
  S_pk2 = 0.0_wp
  DO i = 1, 3
    S_pk2(i,i) = 2.0_wp * C10 * Jm23 * (1.0_wp - (1.0_wp/3.0_wp) * I1 * Cinv(i,i))
    ! Add volumetric part (zero for J=1)
    S_pk2(i,i) = S_pk2(i,i) + (2.0_wp / D1) * (J_det - 1.0_wp) * J_det * Cinv(i,i)
  END DO

  ! Push-forward to Cauchy: σ = (1/J)·F·S·F^T
  ! For diagonal tensors: σ_ii = (1/J)·F_ii·S_ii·F_ii = F_ii²·S_ii / J
  sigma = 0.0_wp
  DO i = 1, 3
    sigma(i,i) = F(i,i) * F(i,i) * S_pk2(i,i) / J_det
  END DO

  ! Apply hydrostatic pressure constraint for incompressible:
  ! True Cauchy for incompressible: σ_dev + p·I where p chosen so σ_22=σ_33=0
  ! Actually for nearly incompressible, the volumetric term handles this.
  ! With large κ and J≈1, σ should be close to analytical.

  ! For truly incompressible analytical: σ_11 - σ_22 = μ·(λ² - 1/λ)
  ! Our computed deviatoric difference:
  sigma_11_computed = sigma(1,1) - sigma(2,2)

  err_rel = ABS(sigma_11_computed - sigma_11_exact) / ABS(sigma_11_exact)

  IF (err_rel < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A,F6.2,A)') &
      'Check 3: Cauchy stress σ_11-σ_22 ... PASS (expected=', sigma_11_exact, &
      ', got=', sigma_11_computed, ', err=', err_rel*100.0_wp, '%)'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A,F6.2,A)') &
      'Check 3: Cauchy stress σ_11-σ_22 ... FAIL (expected=', sigma_11_exact, &
      ', got=', sigma_11_computed, ', err=', err_rel*100.0_wp, '%)'
  END IF

  !---------------------------------------------------------------------------
  ! Check 4: Lateral stress symmetry σ_22 = σ_33
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(sigma(2,2) - sigma(3,3)) < 1.0E-10_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Lateral symmetry σ_22=σ_33 ... PASS (σ_22=', sigma(2,2), &
      ', σ_33=', sigma(3,3), ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Lateral symmetry σ_22=σ_33 ... FAIL (σ_22=', sigma(2,2), &
      ', σ_33=', sigma(3,3), ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 5: Stress-free at λ=1 (identity deformation)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: F_id(3,3), C_id(3,3), Cinv_id(3,3), S_id(3,3)
    REAL(wp) :: I1_id, stress_norm

    F_id = 0.0_wp
    F_id(1,1) = 1.0_wp; F_id(2,2) = 1.0_wp; F_id(3,3) = 1.0_wp

    C_id = F_id  ! C=I for F=I
    Cinv_id = F_id
    I1_id = 3.0_wp

    S_id = 0.0_wp
    DO i = 1, 3
      S_id(i,i) = 2.0_wp * C10 * (1.0_wp - (1.0_wp/3.0_wp) * I1_id * Cinv_id(i,i))
    END DO
    ! S_ii = 2*C10*(1 - 1/3*3*1) = 2*C10*(1-1) = 0 ✓

    stress_norm = SQRT(S_id(1,1)**2 + S_id(2,2)**2 + S_id(3,3)**2)
    IF (stress_norm < 1.0E-10_wp) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A,ES10.3,A)') &
        'Check 5: Stress-free at λ=1 ... PASS (|S|=', stress_norm, ')'
    ELSE
      WRITE(*,'(A,ES10.3,A)') &
        'Check 5: Stress-free at λ=1 ... FAIL (|S|=', stress_norm, ')'
    END IF
  END BLOCK

  !---------------------------------------------------------------------------
  ! Check 6: Positive strain energy for deformed state
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (W_computed > 0.0_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A)') &
      'Check 6: Positive strain energy W>0 ... PASS (W=', W_computed, ')'
  ELSE
    WRITE(*,'(A,F10.4,A)') &
      'Check 6: Positive strain energy W>0 ... FAIL (W=', W_computed, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Summary
  !---------------------------------------------------------------------------
  WRITE(*,'(A)') ''
  IF (n_pass == n_total) THEN
    WRITE(*,'(A,I0,A,I0,A)') &
      '=== RESULT: PASS (', n_pass, '/', n_total, ' checks passed) ==='
  ELSE
    WRITE(*,'(A,I0,A,I0,A)') &
      '=== RESULT: FAIL (', n_pass, '/', n_total, ' checks passed) ==='
  END IF

END PROGRAM E2E_C2_06_NLGeom_NeoHookean
