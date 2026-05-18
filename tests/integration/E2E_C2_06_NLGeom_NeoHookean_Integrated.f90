!===============================================================================
! E2E Test C2-06: NLGeom_NeoHookean (INTEGRATED VERSION)
! Layer:  Integration Test (E2E)
! Purpose: Verify large deformation Neo-Hookean constitutive model.
!
! Integration Status: FULL
!   - USE PH_Mat_NeoHookean: PH_NeoHk_Props, PH_NeoHk_State,
!     PH_NeoHk_Init, PH_NeoHk_ComputeStress
!     Module .mod file available in build_mod/
!   - USE PH_Elem_NLGeom_Core: PH_NLGeom_State, NLGEOM_TL
!     Module .mod file available in build_mod/
!   - USE IF_Prec_Core: wp, i4
!   - USE IF_Err_Brg: ErrorStatusType
!
! Changes from self-contained version:
!   1. PH_NeoHk_Props replaces inline C10/D1/mu/kappa parameters
!   2. PH_NeoHk_State replaces inline S/sigma/W computation
!   3. PH_NeoHk_ComputeStress replaces inline PK2/Cauchy/energy calculation
!   4. PH_NLGeom_State integrated for deformation gradient tracking
!   5. Verification checks use module state fields
!
! Original: E2E_C2_06_NLGeom_NeoHookean.f90 (self-contained, PASS)
! Status: ACTIVE | Created: 2026-04-28 | Integrated: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_06_NLGeom_NeoHookean_Integrated
  ! === INTEGRATED: USE actual UFC modules ===
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_NeoHookean, ONLY: PH_NeoHk_Props, PH_NeoHk_State, &
                                PH_NeoHk_Init, PH_NeoHk_ComputeStress
  USE PH_Elem_NLGeom_Core, ONLY: PH_NLGeom_State, NLGEOM_TL
  IMPLICIT NONE

  ! Material parameters
  REAL(wp), PARAMETER :: MU_SHEAR = 80.194_wp
  REAL(wp), PARAMETER :: C10      = 40.097_wp
  REAL(wp), PARAMETER :: KAPPA    = 400000.0_wp
  REAL(wp), PARAMETER :: D1       = 2.0_wp / KAPPA

  ! Stretch
  REAL(wp), PARAMETER :: LAMBDA_STRETCH = 1.5_wp

  ! Tolerances
  REAL(wp), PARAMETER :: TOL_STRESS = 0.02_wp
  REAL(wp), PARAMETER :: TOL_DET    = 1.0E-12_wp

  ! === INTEGRATED: Module types ===
  TYPE(PH_NeoHk_Props) :: nh_props
  TYPE(PH_NeoHk_State) :: nh_state
  TYPE(PH_NLGeom_State) :: nlg_state
  TYPE(ErrorStatusType) :: ierr

  ! Variables
  REAL(wp) :: F(3,3)
  REAL(wp) :: sigma_11_exact, sigma_11_computed
  REAL(wp) :: W_exact
  REAL(wp) :: lambda_lat, err_rel
  REAL(wp) :: I1
  INTEGER(i4) :: n_pass, n_total, i

  n_pass = 0; n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-06: NLGeom_NeoHookean [INTEGRATED] ==='
  WRITE(*,'(A)') '  Using: PH_Mat_NeoHookean (PH_NeoHk_ComputeStress)'
  WRITE(*,'(A)') '  Using: PH_Elem_NLGeom_Core (PH_NLGeom_State)'
  WRITE(*,'(A)') ''

  lambda_lat = 1.0_wp / SQRT(LAMBDA_STRETCH)

  ! === INTEGRATED: Initialize NeoHookean material via module ===
  nh_props%C10   = C10
  nh_props%D1    = D1
  ! mu and kappa will be derived by PH_NeoHk_Init
  CALL PH_NeoHk_Init(nh_props, nh_state, ierr)
  IF (ierr%status_code /= IF_STATUS_OK) THEN
    WRITE(*,'(A)') 'ERROR: PH_NeoHk_Init failed'
    STOP 1
  END IF

  ! Setup deformation gradient F = diag(lambda, 1/sqrt(lambda), 1/sqrt(lambda))
  F = 0.0_wp
  F(1,1) = LAMBDA_STRETCH
  F(2,2) = lambda_lat
  F(3,3) = lambda_lat

  ! === INTEGRATED: Store F in NLGeom state ===
  nlg_state%frame = NLGEOM_TL
  nlg_state%F     = F
  nlg_state%detF  = F(1,1) * F(2,2) * F(3,3)

  ! Check 1: Determinant J = 1
  n_total = n_total + 1
  IF (ABS(nlg_state%detF - 1.0_wp) < TOL_DET) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F12.8,A)') &
      'Check 1: det(F)=1 (incompressible) ... PASS (J=', nlg_state%detF, ')'
  ELSE
    WRITE(*,'(A,F12.8,A)') &
      'Check 1: det(F)=1 (incompressible) ... FAIL (J=', nlg_state%detF, ')'
  END IF

  ! === INTEGRATED: Call module PH_NeoHk_ComputeStress ===
  CALL PH_NeoHk_ComputeStress(nh_props, F, nh_state, ierr)
  IF (ierr%status_code /= IF_STATUS_OK) THEN
    WRITE(*,'(A)') 'ERROR: PH_NeoHk_ComputeStress failed'
    STOP 1
  END IF

  ! Check 2: Strain energy
  n_total = n_total + 1
  I1 = LAMBDA_STRETCH**2 + 2.0_wp / LAMBDA_STRETCH
  W_exact = C10 * (I1 - 3.0_wp)

  err_rel = ABS(nh_state%energy%W - W_exact) / MAX(ABS(W_exact), 1.0E-15_wp)
  IF (err_rel < 1.0E-10_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 2: Strain energy W ... PASS (expected=', W_exact, &
      ', got=', nh_state%energy%W, ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 2: Strain energy W ... FAIL (expected=', W_exact, &
      ', got=', nh_state%energy%W, ')'
  END IF

  ! Check 3: Cauchy stress sigma_11 - sigma_22 (analytical for incomp uniaxial)
  n_total = n_total + 1
  sigma_11_exact = MU_SHEAR * (LAMBDA_STRETCH**2 - 1.0_wp / LAMBDA_STRETCH)

  ! === INTEGRATED: Read Cauchy stress from module state (Voigt: 11,22,33,12,23,13) ===
  sigma_11_computed = nh_state%stress%sigma(1) - nh_state%stress%sigma(2)

  err_rel = ABS(sigma_11_computed - sigma_11_exact) / ABS(sigma_11_exact)
  IF (err_rel < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A,F6.2,A)') &
      'Check 3: Cauchy stress s11-s22 ... PASS (expected=', sigma_11_exact, &
      ', got=', sigma_11_computed, ', err=', err_rel*100.0_wp, '%)'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A,F6.2,A)') &
      'Check 3: Cauchy stress s11-s22 ... FAIL (expected=', sigma_11_exact, &
      ', got=', sigma_11_computed, ', err=', err_rel*100.0_wp, '%)'
  END IF

  ! Check 4: Lateral symmetry sigma_22 = sigma_33
  n_total = n_total + 1
  IF (ABS(nh_state%stress%sigma(2) - nh_state%stress%sigma(3)) < 1.0E-10_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Lateral symmetry s22=s33 ... PASS (s22=', nh_state%stress%sigma(2), &
      ', s33=', nh_state%stress%sigma(3), ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Lateral symmetry s22=s33 ... FAIL (s22=', nh_state%stress%sigma(2), &
      ', s33=', nh_state%stress%sigma(3), ')'
  END IF

  ! Check 5: Stress-free at lambda=1
  n_total = n_total + 1
  BLOCK
    TYPE(PH_NeoHk_Props)  :: nh_props_id
    TYPE(PH_NeoHk_State)  :: nh_state_id
    TYPE(ErrorStatusType)  :: ierr_id
    REAL(wp) :: F_id(3,3), stress_norm

    nh_props_id%C10 = C10
    nh_props_id%D1  = D1
    CALL PH_NeoHk_Init(nh_props_id, nh_state_id, ierr_id)

    F_id = 0.0_wp; F_id(1,1)=1.0_wp; F_id(2,2)=1.0_wp; F_id(3,3)=1.0_wp
    CALL PH_NeoHk_ComputeStress(nh_props_id, F_id, nh_state_id, ierr_id)

    stress_norm = SQRT(nh_state_id%S(1)**2 + nh_state_id%S(2)**2 + nh_state_id%S(3)**2)
    IF (stress_norm < 1.0E-10_wp) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A,ES10.3,A)') 'Check 5: Stress-free at lam=1 ... PASS (|S|=', stress_norm, ')'
    ELSE
      WRITE(*,'(A,ES10.3,A)') 'Check 5: Stress-free at lam=1 ... FAIL (|S|=', stress_norm, ')'
    END IF
  END BLOCK

  ! Check 6: Positive strain energy
  n_total = n_total + 1
  IF (nh_state%energy%W > 0.0_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A)') 'Check 6: Positive strain energy W>0 ... PASS (W=', nh_state%energy%W, ')'
  ELSE
    WRITE(*,'(A,F10.4,A)') 'Check 6: Positive strain energy W>0 ... FAIL (W=', nh_state%energy%W, ')'
  END IF

  ! Summary
  WRITE(*,'(A)') ''
  IF (n_pass == n_total) THEN
    WRITE(*,'(A,I0,A,I0,A)') '=== RESULT: PASS (', n_pass, '/', n_total, ' checks passed) ==='
  ELSE
    WRITE(*,'(A,I0,A,I0,A)') '=== RESULT: FAIL (', n_pass, '/', n_total, ' checks passed) ==='
  END IF

END PROGRAM E2E_C2_06_NLGeom_NeoHookean_Integrated
