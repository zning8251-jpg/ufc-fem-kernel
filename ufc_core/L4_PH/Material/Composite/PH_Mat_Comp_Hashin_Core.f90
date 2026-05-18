!===============================================================================
! MODULE: PH_Mat_Comp_Hashin_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Composite FRP laminates — Hashin/Tsai-Wu with progressive damage —
!         **W1**：Hashin/Tsai-Wu/MLT 参数写入槽 **`desc%props`**；与 **PH_Mat_Desc** /
!         **PH_MAT_*** 复合材料族、**Effective_Model** 一致。
!===============================================================================
!
! Design Document: DESIGN_Mat_ConstitutiveKernels.md §9
! Reference: Hashin (1980) Failure Criteria for Unidirectional Fiber Composites
!            Tsai & Wu (1971) A General Theory of Strength for Anisotropic Materials
!            Matzenmiller, Lubliner & Taylor (1995) A constitutive model for
!              anisotropic damage in fiber-composites (MLT model)
!
! Hashin Failure Criteria (§9.2) — 4 modes:
!   [FT] Fiber Tension:     (σ11/X_T)² + (τ12/S_L)² = 1
!   [FC] Fiber Compression: (σ11/X_C)² = 1
!   [MT] Matrix Tension:    (σ22/Y_T)² + (τ12/S_L)² = 1
!   [MC] Matrix Compression: (σ22/(2*S_T))² + [(Y_C/(2*S_T))²-1]*(σ22/Y_C)
!                           + (τ12/S_L)² = 1
!
! Tsai-Wu Strength Criterion (§9.3):
!   F = F1·σ1 + F2·σ2 + F11·σ1² + F22·σ2² + F66·τ12²
!     + 2·F12·σ1·σ2 = 1
!   F1 = 1/X_T - 1/X_C,  F2 = 1/Y_T - 1/Y_C
!   F11 = 1/(X_T·X_C),   F22 = 1/(Y_T·Y_C),   F66 = 1/S_L²
!   F12 = -0.5/sqrt(X_T·X_C·Y_T·Y_C) (default interaction coeff)
!
! Damage Evolution (§9.4, MLT model):
!   D_f, D_m, D_s — fiber, matrix, shear damage variables
!   Degraded stiffness: C_dmg(D_f, D_m, D_s)
!
! CONTRACT Compliance:
!   - ErrorStatusType on all public procedures (no STOP)
!   - wp/i4 precision from IF_Prec_Core
!   - Intent declarations on all arguments
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
!
!>>> UFC_PH_QUENCH | Domain:Material/Composite | Role:Core | FuncSet:Compute,Init,Validate | HotPath:Yes
!>>> UFC_PH_CONTRACT | Material/CONTRACT.md
!
MODULE PH_Mat_Comp_Hashin_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public Interface
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_Mat_Comp_Compute_Stress
  PUBLIC :: PH_Mat_Comp_Compute_Tangent
  PUBLIC :: PH_Mat_Comp_Update_State
  PUBLIC :: PH_Mat_Comp_Validate_Params
  PUBLIC :: PH_Mat_Comp_Init
  PUBLIC :: PH_Mat_Comp_Hashin_Check
  PUBLIC :: PH_Mat_Comp_TsaiWu_Check

  !-----------------------------------------------------------------------------
  ! Failure mode indices
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_HASHIN_FAIL_FT = 1_i4  ! Fiber tension
  INTEGER(i4), PARAMETER, PUBLIC :: PH_HASHIN_FAIL_FC = 2_i4  ! Fiber compression
  INTEGER(i4), PARAMETER, PUBLIC :: PH_HASHIN_FAIL_MT = 3_i4  ! Matrix tension
  INTEGER(i4), PARAMETER, PUBLIC :: PH_HASHIN_FAIL_MC = 4_i4  ! Matrix compression

  !-----------------------------------------------------------------------------
  ! TYPE: PH_Comp_Props — Composite ply properties (orthotropic)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Comp_Props
    !-- Elastic (orthotropic ply)
    REAL(wp) :: E1     = 0.0_wp   ! Longitudinal modulus (fiber dir) [Pa]
    REAL(wp) :: E2     = 0.0_wp   ! Transverse modulus [Pa]
    REAL(wp) :: nu12   = 0.0_wp   ! Major Poisson's ratio [-]
    REAL(wp) :: G12    = 0.0_wp   ! In-plane shear modulus [Pa]
    !-- Strength
    REAL(wp) :: X_T    = 0.0_wp   ! Fiber tensile strength [Pa]
    REAL(wp) :: X_C    = 0.0_wp   ! Fiber compressive strength [Pa]
    REAL(wp) :: Y_T    = 0.0_wp   ! Matrix tensile strength [Pa]
    REAL(wp) :: Y_C    = 0.0_wp   ! Matrix compressive strength [Pa]
    REAL(wp) :: S_L    = 0.0_wp   ! Longitudinal shear strength [Pa]
    REAL(wp) :: S_T    = 0.0_wp   ! Transverse shear strength [Pa]
    !-- Tsai-Wu interaction coefficient
    REAL(wp) :: F12_star = -0.5_wp ! Normalized interaction [-1,1]
    !-- Damage evolution (fracture energy regularization)
    REAL(wp) :: Gf_ft  = 0.0_wp   ! Fracture energy, fiber tension [J/m²]
    REAL(wp) :: Gf_fc  = 0.0_wp   ! Fracture energy, fiber compression [J/m²]
    REAL(wp) :: Gf_mt  = 0.0_wp   ! Fracture energy, matrix tension [J/m²]
    REAL(wp) :: Gf_mc  = 0.0_wp   ! Fracture energy, matrix compression [J/m²]
    REAL(wp) :: l_char = 1.0_wp   ! Characteristic element length [m]
  END TYPE PH_Comp_Props

  !-----------------------------------------------------------------------------
  ! TYPE: PH_Comp_State — Integration point state
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Comp_State
    REAL(wp) :: stress(6)    = 0.0_wp   ! Stress (Voigt, 3D or plane stress) [Pa]
    REAL(wp) :: C_tan(6,6)   = 0.0_wp   ! Algorithmic tangent [Pa]
    !-- Damage variables [0,1]
    REAL(wp) :: D_ft         = 0.0_wp   ! Fiber tension damage
    REAL(wp) :: D_fc         = 0.0_wp   ! Fiber compression damage
    REAL(wp) :: D_mt         = 0.0_wp   ! Matrix tension damage
    REAL(wp) :: D_mc         = 0.0_wp   ! Matrix compression damage
    REAL(wp) :: D_s          = 0.0_wp   ! Shear damage (derived)
    !-- Failure indicators (Hashin)
    REAL(wp) :: f_hashin(4)  = 0.0_wp   ! Failure indices [FT, FC, MT, MC]
    !-- Tsai-Wu
    REAL(wp) :: f_tsaiwu     = 0.0_wp   ! Tsai-Wu failure index
    !-- Flags
    LOGICAL  :: failed       = .FALSE.  ! Any mode fully damaged
  END TYPE PH_Comp_State

CONTAINS

  !===========================================================================
  ! PH_Mat_Comp_Validate_Params — Validate composite parameters
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_Validate_Params(props, ierr)
    TYPE(PH_Comp_Props),    INTENT(IN)  :: props
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)

    IF (props%E1 <= 0.0_wp .OR. props%E2 <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Comp]: E1 and E2 must be positive'
      RETURN
    END IF
    IF (props%G12 <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Comp]: G12 must be positive'
      RETURN
    END IF
    IF (props%X_T <= 0.0_wp .OR. props%X_C <= 0.0_wp .OR. &
        props%Y_T <= 0.0_wp .OR. props%Y_C <= 0.0_wp .OR. &
        props%S_L <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Comp]: All strengths must be positive'
      RETURN
    END IF
    IF (props%S_T <= 0.0_wp) THEN
      ! S_T defaults to Y_C/2 if not set (checked in Init)
    END IF

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Validate_Params

  !===========================================================================
  ! PH_Mat_Comp_Init — Initialize composite context
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_Init(props, state, ierr)
    TYPE(PH_Comp_Props),    INTENT(INOUT) :: props
    TYPE(PH_Comp_State),    INTENT(OUT)   :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL PH_Mat_Comp_Validate_Params(props, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN

    ! Default S_T if not set
    IF (props%S_T <= 0.0_wp) THEN
      props%S_T = props%Y_C / 2.0_wp
    END IF

    state%stress   = 0.0_wp
    state%C_tan    = 0.0_wp
    state%D_ft     = 0.0_wp
    state%D_fc     = 0.0_wp
    state%D_mt     = 0.0_wp
    state%D_mc     = 0.0_wp
    state%D_s      = 0.0_wp
    state%f_hashin = 0.0_wp
    state%f_tsaiwu = 0.0_wp
    state%failed   = .FALSE.

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Init

  !===========================================================================
  ! PH_Mat_Comp_Hashin_Check — Evaluate Hashin failure criteria
  !
  ! Input: stress in material (ply) coordinates
  !   stress(1) = σ11 (fiber direction)
  !   stress(2) = σ22 (transverse)
  !   stress(4) = τ12 (in-plane shear)
  !
  ! Output: f_hashin(4) — failure indices for 4 modes
  !   f > 1 means failure initiated
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_Hashin_Check(props, stress, f_hashin, ierr)
    TYPE(PH_Comp_Props),    INTENT(IN)  :: props
    REAL(wp),               INTENT(IN)  :: stress(6)
    REAL(wp),               INTENT(OUT) :: f_hashin(4)
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    REAL(wp) :: s11, s22, t12

    CALL init_error_status(ierr)

    s11 = stress(1)
    s22 = stress(2)
    t12 = stress(4)

    f_hashin = 0.0_wp

    ! [FT] Fiber Tension: σ11 >= 0
    IF (s11 >= 0.0_wp) THEN
      f_hashin(PH_HASHIN_FAIL_FT) = (s11 / props%X_T)**2 + (t12 / props%S_L)**2
    END IF

    ! [FC] Fiber Compression: σ11 < 0
    IF (s11 < 0.0_wp) THEN
      f_hashin(PH_HASHIN_FAIL_FC) = (s11 / props%X_C)**2
    END IF

    ! [MT] Matrix Tension: σ22 >= 0
    IF (s22 >= 0.0_wp) THEN
      f_hashin(PH_HASHIN_FAIL_MT) = (s22 / props%Y_T)**2 + (t12 / props%S_L)**2
    END IF

    ! [MC] Matrix Compression: σ22 < 0
    IF (s22 < 0.0_wp) THEN
      f_hashin(PH_HASHIN_FAIL_MC) = (s22 / (2.0_wp * props%S_T))**2 &
        + ((props%Y_C / (2.0_wp * props%S_T))**2 - 1.0_wp) * (s22 / props%Y_C) &
        + (t12 / props%S_L)**2
    END IF

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Hashin_Check

  !===========================================================================
  ! PH_Mat_Comp_TsaiWu_Check — Evaluate Tsai-Wu strength criterion
  !
  ! F = F1·σ1 + F2·σ2 + F11·σ1² + F22·σ2² + F66·τ12²
  !   + 2·F12·σ1·σ2
  ! F >= 1 means failure
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_TsaiWu_Check(props, stress, f_tw, ierr)
    TYPE(PH_Comp_Props),    INTENT(IN)  :: props
    REAL(wp),               INTENT(IN)  :: stress(6)
    REAL(wp),               INTENT(OUT) :: f_tw
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    REAL(wp) :: F1, F2, F11, F22, F66, F12
    REAL(wp) :: s1, s2, t12

    CALL init_error_status(ierr)

    s1  = stress(1)
    s2  = stress(2)
    t12 = stress(4)

    ! Tsai-Wu coefficients
    F1  = 1.0_wp / props%X_T - 1.0_wp / props%X_C
    F2  = 1.0_wp / props%Y_T - 1.0_wp / props%Y_C
    F11 = 1.0_wp / (props%X_T * props%X_C)
    F22 = 1.0_wp / (props%Y_T * props%Y_C)
    F66 = 1.0_wp / (props%S_L**2)
    F12 = props%F12_star * SQRT(F11 * F22)

    ! Failure index
    f_tw = F1 * s1 + F2 * s2 &
         + F11 * s1**2 + F22 * s2**2 + F66 * t12**2 &
         + 2.0_wp * F12 * s1 * s2

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_TsaiWu_Check

  !===========================================================================
  ! PH_Mat_Comp_Compute_Stress — Compute stress with progressive damage
  !
  ! Algorithm:
  !   1. Build undamaged orthotropic stiffness Q
  !   2. Compute trial stress: σ_trial = Q_dmg : ε
  !   3. Evaluate Hashin failure criteria
  !   4. Update damage variables (exponential softening)
  !   5. Recompute degraded stiffness and stress
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_Compute_Stress(props, strain, state, stress, ierr)
    TYPE(PH_Comp_Props),    INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain(6)
    TYPE(PH_Comp_State),    INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: stress(6)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    ! Local
    REAL(wp) :: Q(6,6)         ! Degraded stiffness
    REAL(wp) :: d_f, d_m, d_s  ! Active damage variables
    REAL(wp) :: nu21            ! Minor Poisson's ratio
    REAL(wp) :: denom           ! Compliance denominator
    REAL(wp) :: f_hashin(4)

    CALL init_error_status(ierr)

    ! Active damage variables (max of tension/compression)
    d_f = MAX(state%D_ft, state%D_fc)
    d_m = MAX(state%D_mt, state%D_mc)
    d_s = 1.0_wp - (1.0_wp - d_f) * (1.0_wp - d_m)
    state%D_s = d_s

    ! Minor Poisson's ratio: ν21 = ν12 * E2/E1
    nu21 = props%nu12 * props%E2 / props%E1

    ! Denominator for plane stress stiffness
    denom = 1.0_wp - props%nu12 * nu21 * (1.0_wp - d_f) * (1.0_wp - d_m)
    IF (ABS(denom) < 1.0E-30_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_Comp]: Stiffness denominator near zero'
      RETURN
    END IF

    ! Build degraded stiffness (plane stress: indices 1,2,4 active)
    Q = 0.0_wp
    Q(1,1) = (1.0_wp - d_f) * props%E1 / denom
    Q(2,2) = (1.0_wp - d_m) * props%E2 / denom
    Q(1,2) = (1.0_wp - d_f) * (1.0_wp - d_m) * props%nu12 * props%E2 / denom
    Q(2,1) = Q(1,2)
    Q(4,4) = (1.0_wp - d_s) * props%G12
    ! Out-of-plane (3D extension, simplified)
    Q(3,3) = props%E2 / (1.0_wp + nu21)  ! Approximate
    Q(5,5) = props%G12 * 0.5_wp  ! Approximate transverse shear
    Q(6,6) = props%G12 * 0.5_wp

    ! Compute stress
    stress = MATMUL(Q, strain)

    ! Evaluate Hashin criteria on trial stress
    CALL PH_Mat_Comp_Hashin_Check(props, stress, f_hashin, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN
    state%f_hashin = f_hashin

    ! Update damage if failure initiated (exponential softening)
    CALL update_damage_mode(f_hashin(PH_HASHIN_FAIL_FT), state%D_ft, &
                             props%Gf_ft, props%X_T, props%E1, props%l_char)
    CALL update_damage_mode(f_hashin(PH_HASHIN_FAIL_FC), state%D_fc, &
                             props%Gf_fc, props%X_C, props%E1, props%l_char)
    CALL update_damage_mode(f_hashin(PH_HASHIN_FAIL_MT), state%D_mt, &
                             props%Gf_mt, props%Y_T, props%E2, props%l_char)
    CALL update_damage_mode(f_hashin(PH_HASHIN_FAIL_MC), state%D_mc, &
                             props%Gf_mc, props%Y_C, props%E2, props%l_char)

    ! Recompute with updated damage if any mode newly initiated
    IF (ANY(f_hashin > 1.0_wp)) THEN
      d_f = MAX(state%D_ft, state%D_fc)
      d_m = MAX(state%D_mt, state%D_mc)
      d_s = 1.0_wp - (1.0_wp - d_f) * (1.0_wp - d_m)
      state%D_s = d_s

      denom = 1.0_wp - props%nu12 * nu21 * (1.0_wp - d_f) * (1.0_wp - d_m)
      IF (ABS(denom) < 1.0E-30_wp) THEN
        state%failed = .TRUE.
        stress = 0.0_wp
        ierr%status_code = IF_STATUS_OK
        RETURN
      END IF

      Q = 0.0_wp
      Q(1,1) = (1.0_wp - d_f) * props%E1 / denom
      Q(2,2) = (1.0_wp - d_m) * props%E2 / denom
      Q(1,2) = (1.0_wp - d_f) * (1.0_wp - d_m) * props%nu12 * props%E2 / denom
      Q(2,1) = Q(1,2)
      Q(4,4) = (1.0_wp - d_s) * props%G12
      Q(3,3) = props%E2 / (1.0_wp + nu21)
      Q(5,5) = props%G12 * 0.5_wp
      Q(6,6) = props%G12 * 0.5_wp

      stress = MATMUL(Q, strain)
    END IF

    ! Evaluate Tsai-Wu on final stress
    CALL PH_Mat_Comp_TsaiWu_Check(props, stress, state%f_tsaiwu, ierr)

    ! Check for complete failure
    IF (d_f >= 0.99_wp .OR. d_m >= 0.99_wp) THEN
      state%failed = .TRUE.
    END IF

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Compute_Stress

  !===========================================================================
  ! PH_Mat_Comp_Compute_Tangent — Compute damaged tangent
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_Compute_Tangent(props, state, C_tangent, ierr)
    TYPE(PH_Comp_Props),    INTENT(IN)  :: props
    TYPE(PH_Comp_State),    INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: C_tangent(6,6)
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    REAL(wp) :: d_f, d_m, d_s, nu21, denom

    CALL init_error_status(ierr)

    d_f  = MAX(state%D_ft, state%D_fc)
    d_m  = MAX(state%D_mt, state%D_mc)
    d_s  = state%D_s
    nu21 = props%nu12 * props%E2 / props%E1

    denom = 1.0_wp - props%nu12 * nu21 * (1.0_wp - d_f) * (1.0_wp - d_m)
    IF (ABS(denom) < 1.0E-30_wp) THEN
      C_tangent = 0.0_wp
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    C_tangent = 0.0_wp
    C_tangent(1,1) = (1.0_wp - d_f) * props%E1 / denom
    C_tangent(2,2) = (1.0_wp - d_m) * props%E2 / denom
    C_tangent(1,2) = (1.0_wp - d_f) * (1.0_wp - d_m) * props%nu12 * props%E2 / denom
    C_tangent(2,1) = C_tangent(1,2)
    C_tangent(4,4) = (1.0_wp - d_s) * props%G12
    C_tangent(3,3) = props%E2 / (1.0_wp + nu21)
    C_tangent(5,5) = props%G12 * 0.5_wp
    C_tangent(6,6) = props%G12 * 0.5_wp

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Compute_Tangent

  !===========================================================================
  ! PH_Mat_Comp_Update_State — Update composite state after convergence
  !===========================================================================
  SUBROUTINE PH_Mat_Comp_Update_State(props, stress, C_tangent, state, ierr)
    TYPE(PH_Comp_Props),    INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: stress(6)
    REAL(wp),               INTENT(IN)    :: C_tangent(6,6)
    TYPE(PH_Comp_State),    INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)
    state%stress = stress
    state%C_tan  = C_tangent
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Update_State

  !===========================================================================
  ! PRIVATE: update_damage_mode — Exponential damage evolution for one mode
  !
  ! If f > 1 (failure initiated), damage grows:
  !   D = 1 - (1/sqrt(f)) * exp(-2*G_f / (sigma_0 * l_char * (sqrt(f)-1)))
  ! Simplified: linear growth with cap
  !===========================================================================
  SUBROUTINE update_damage_mode(f_fail, D_mode, Gf, sigma_0, E_mod, l_char)
    REAL(wp), INTENT(IN)    :: f_fail    ! Failure index (f > 1 = failed)
    REAL(wp), INTENT(INOUT) :: D_mode    ! Damage variable [0,1]
    REAL(wp), INTENT(IN)    :: Gf        ! Fracture energy [J/m²]
    REAL(wp), INTENT(IN)    :: sigma_0   ! Strength [Pa]
    REAL(wp), INTENT(IN)    :: E_mod     ! Modulus [Pa]
    REAL(wp), INTENT(IN)    :: l_char    ! Characteristic length [m]

    REAL(wp) :: D_new, eps_0, eps_f

    IF (f_fail <= 1.0_wp) RETURN  ! No failure initiation
    IF (D_mode >= 0.999_wp) RETURN ! Already fully damaged

    ! Characteristic strains
    eps_0 = sigma_0 / E_mod  ! Failure initiation strain
    IF (Gf > 0.0_wp .AND. l_char > 0.0_wp) THEN
      eps_f = 2.0_wp * Gf / (sigma_0 * l_char)  ! Complete failure strain
    ELSE
      eps_f = 10.0_wp * eps_0  ! Fallback: brittle-like
    END IF

    ! Linear softening damage evolution
    ! D = (eps_f * (eps - eps_0)) / (eps * (eps_f - eps_0))
    ! Using failure index as proxy: eps/eps_0 ≈ sqrt(f)
    IF (eps_f > eps_0) THEN
      D_new = (SQRT(f_fail) - 1.0_wp) * eps_f / ((eps_f - eps_0) * SQRT(f_fail))
      D_new = MIN(D_new, 0.999_wp)
      D_mode = MAX(D_mode, D_new)  ! Damage irreversibility
    ELSE
      D_mode = 0.999_wp  ! Snap-back: immediate failure
    END IF

  END SUBROUTINE update_damage_mode

END MODULE PH_Mat_Comp_Hashin_Core
