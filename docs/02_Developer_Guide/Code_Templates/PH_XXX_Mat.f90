!==============================================================================!
! Template: PH_XXX_Mat.f90                                    [Template v1.2]
! Layer  : L4_PH — Physics Layer
! Domain : Material / [Family]  (e.g., ELA / PLM / HYP / DMG / CMP / ...)
!
! Purpose:
!   Single-track ("single-module") material MatPoint template.
!   Consolidates into ONE module:
!     1. MD_Mat_XXX_Desc    — model parameter descriptor (L3_MD role, embedded)
!     2. PH_Mat_XXX_State   — per-IP run-time state (L4_PH role)
!     3. PH_Mat_XXX_UMAT_API  — UFC constitutive entry (thin API wrapper)
!     4. PH_Mat_XXX_UMAT_Impl — PRIVATE hot-path constitutive algorithm
!     5. PH_Mat_XXX_UpdateStress — MatPoint thin entry (called by UEL kernel)
!     6. PH_Mat_XXX_UMAT      — PH_UMAT_Intf registry entry (context form)
!
! Distinction from PH_XXX_UMAT.f90 (which to copy first):
!   **Default:** use **PH_XXX_UMAT.f90** for new material models (Desc in L3_MD,
!   standard UMAT ABI, full adapter commentary).
!   PH_XXX_Mat.f90 **(THIS)** — optional **single-module** pattern: embedded
!   `MD_Mat_XXX_Desc` in L4_PH, plus `UpdateStress` / registry-oriented glue in one
!   file. Use only when you explicitly want that consolidation; it is **not** the
!   default recommendation vs. `PH_XXX_UMAT.f90`.
!
! Call chain:
!   UEL kernel (PH_Elem_XXX / PH_XXX_UEL)
!     └─ PH_Mat_XXX_UpdateStress(MatPoint_In, MatPoint_Out)
!          └─ PH_Mat_XXX_UMAT_API(desc, state, md_algo, ph_algo, ph_ctx, rt_ctx, pnewdt)
!               └─ PH_Mat_XXX_UMAT_Impl(desc, state, md_algo, ph_algo, mat_arg)
!
!   Registry entry:
!     PH_Mat_Reg_Add(mat_id, ..., umat_proc=PH_Mat_XXX_UMAT, init_proc=...)
!     Caller: CALL PH_Mat_XXX_UMAT(ctx, status)
!
! SIO compliance (Principle #14):
!   SIO-01 ✓  UMAT_API: 7 params (6 SIO + pnewdt bare scalar, ABI exception)
!   SIO-02 ✓  _Impl 5th param is unified PH_Mat_XXX_Arg ([IN]/[OUT] in comments)
!   SIO-03 ✓  PH_Mat_XXX_Arg carries structured ErrorStatusType status; check %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  Arg TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  [IN] slice of Arg has no ALLOCATABLE members
!
! Naming:
!   Replace XXX with [Family]_[Model], e.g.:
!     ELA_ISO   → isotropic linear elastic
!     PLM_J2    → J2 von Mises plasticity
!     HYP_NeoH  → Neo-Hookean hyperelastic
!     DMG_LEMA  → Lemaitre continuum damage
!
! HOW TO USE:
!   1. Copy to L4_PH/Material/[Family]/PH_Mat_[Family]_[Model].f90
!   2. Replace XXX → [Family]_[Model] throughout
!   3. Add model-specific fields to MD_Mat_XXX_Desc (props layout below)
!   4. Add model-specific fields to PH_Mat_XXX_State (SDV layout below)
!   5. Implement constitutive algorithm in PH_Mat_XXX_UMAT_Impl
!   6. Register: CALL PH_Mat_Reg_Add(MAT_ID_XXX, ..., umat_proc=PH_Mat_XXX_UMAT)
!
! Desc / TBP (v1.2):
!   Do NOT add module subroutines named *_TBP that only CALL the real routine
!   with the same argument list — that is redundant. Bind type-bound procedures
!   directly:  PROCEDURE :: Foo => MD_Mat_XXX_Foo  where MD_Mat_XXX_Foo's
!   first dummy is CLASS(MD_Mat_XXX_Desc) (pass-object).
!==============================================================================!
MODULE PH_XXX_Mat
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
  !-- L3_MD base types (Desc, Algo)
  USE MD_Mat_Types, ONLY: MD_Mat_Base_Desc, MD_Mat_Base_Algo
  !-- L4_PH base types (State, Ctx, Algo)
  USE PH_Mat_Types, ONLY: PH_Mat_Base_Ctx, PH_Mat_Base_Algo
  !-- L5_RT context (read-only in L4_PH)
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  !-- Public exports
  PUBLIC :: MD_Mat_XXX_Desc          ! L3_MD descriptor (embedded in this module)
  PUBLIC :: PH_Mat_XXX_State         ! L4_PH per-IP state
  PUBLIC :: PH_Mat_XXX_Arg           ! Unified SIO bundle ([IN]/[OUT] in comments)
  PUBLIC :: PH_Mat_XXX_UMAT_API      ! UFC constitutive API (thin wrapper)
  PUBLIC :: PH_Mat_XXX_UpdateStress  ! MatPoint thin entry for UEL kernel
  PUBLIC :: PH_Mat_XXX_UMAT          ! PH_UMAT_Intf registry entry (context form)
  ! PH_Mat_XXX_UMAT_Impl is PRIVATE — hot-path physics, not part of ABI

  !=============================================================================
  ! ① MD_Mat_XXX_Desc                           [L3_MD role, embedded in L4_PH]
  !
  ! Model-specific material parameter descriptor.
  ! Populated once (from PROPS array) per UMAT call and reused across all IPs.
  !
  ! Props layout — document every slot:
  !   props(1) = ???    [unit]   e.g., E = Young's modulus [Pa]
  !   props(2) = ???    [unit]   e.g., nu = Poisson's ratio [-]
  !   props(3) = ???    [unit]   model-specific parameter
  !   ...
  !   Add derived quantities (G, lambda, K, sin_phi …) as pre-computed fields.
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_XXX_Desc
    !-- Primary parameters (from PROPS array)
    REAL(wp) :: param1 = 0.0_wp     ! Physical meaning [unit]  ← rename
    REAL(wp) :: param2 = 0.0_wp     ! Physical meaning [unit]  ← rename
    REAL(wp) :: param3 = 0.0_wp     ! Physical meaning [unit]  ← rename

    !-- Derived / pre-computed constants (filled once in InitFromProps)
    REAL(wp) :: derived1 = 0.0_wp   ! e.g., G = E/(2*(1+nu))  [Pa]
    REAL(wp) :: derived2 = 0.0_wp   ! e.g., lambda             [Pa]

    !-- Minimum props count required
    INTEGER(i4) :: nprops_min = 2_i4

    !-- Validation flag
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: ValidateProps => MD_Mat_XXX_ValidateProps
    PROCEDURE :: InitFromProps => MD_Mat_XXX_InitFromProps
  END TYPE MD_Mat_XXX_Desc

  !=============================================================================
  ! ② PH_Mat_XXX_State                                   [L4_PH per-IP state]
  !
  ! Run-time evolving state at one integration point.
  ! Updated in-place by each constitutive call.
  !
  ! SDV layout (statev slots) — document every entry:
  !   statev(1)  = ???   e.g., equivalent plastic strain ε̄ᵖ [-]
  !   statev(2)  = ???   e.g., isotropic hardening variable κ [Pa]
  !   statev(3)  = ???   e.g., damage variable D [-]
  !   statev(4..9) = ???  e.g., back-stress tensor α (Voigt 6) [Pa]
  !   ...
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_XXX_State
    !-- Stress and strain at START of increment (converged previous step)
    REAL(wp) :: stress(6)  = 0.0_wp   ! Cauchy stress σ [Pa], Voigt order
    REAL(wp) :: stran(6)   = 0.0_wp   ! Total strain ε at start of increment
    REAL(wp) :: dfgrd0(3,3) = 0.0_wp  ! Deformation gradient F₀ at start

    !-- Internal / state-dependent variables (SDV)
    REAL(wp) :: peeq       = 0.0_wp   ! Equivalent plastic strain ε̄ᵖ [-]
    REAL(wp) :: kappa      = 0.0_wp   ! Isotropic hardening variable [Pa]
    REAL(wp) :: back_stress(6) = 0.0_wp  ! Kinematic hardening (Voigt 6) [Pa]
    REAL(wp) :: damage     = 0.0_wp   ! Scalar damage variable D [0..1]

    !-- Tangent modulus from last converged call
    REAL(wp) :: ddsdde(6,6) = 0.0_wp  ! Consistent tangent ∂σ/∂ε [Pa]

    !-- Iteration diagnostics
    INTEGER(i4) :: n_iters  = 0_i4    ! Return-mapping iterations used
    LOGICAL     :: converged = .FALSE. ! Return-mapping convergence flag
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_XXX_State

  !=============================================================================
  ! ③ PH_Mat_XXX_Arg — unified per-call bundle (Principle #14)
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_XXX_Arg
    !-- [IN] Kinematic driving inputs (mirrors PH_Mat_Base_Ctx fields)
    REAL(wp) :: dstran(6)   = 0.0_wp  ! Strain increment Δε (Voigt)
    REAL(wp) :: drot(3,3)   = 0.0_wp  ! Rotation increment ΔR
    REAL(wp) :: dfgrd1(3,3) = 0.0_wp  ! Deformation gradient F₁ at end
    !-- [IN] Thermal inputs
    REAL(wp) :: temp         = 0.0_wp  ! Temperature at end of increment [K]
    REAL(wp) :: dtemp        = 0.0_wp  ! Temperature increment ΔT [K]
    !-- [IN] Spatial context
    REAL(wp) :: coords(3)   = 0.0_wp  ! IP coordinates
    REAL(wp) :: celent       = 0.0_wp  ! Characteristic element length [m]
    !-- [IN] Control flags
    LOGICAL  :: compute_tangent = .TRUE.  ! .TRUE. → compute ddsdde
    LOGICAL  :: first_call      = .FALSE. ! .TRUE. → first call this increment
    INTEGER(i4) :: ntens = 6_i4          ! Active Voigt size (from MD_Mat_Base_Algo)
    INTEGER(i4) :: ndi   = 3_i4
    INTEGER(i4) :: nshr  = 3_i4

    !-- [OUT] Status and results
    TYPE(ErrorStatusType) :: status
    LOGICAL  :: success   = .FALSE.
    REAL(wp) :: stress(6)  = 0.0_wp   ! Updated Cauchy stress σ_{n+1} [Pa]
    REAL(wp) :: ddsdde(6,6) = 0.0_wp  ! Consistent tangent [Pa]
    REAL(wp) :: pnewdt     = 1.0_wp   ! pnewdt suggestion (1.0 = no change)
    INTEGER(i4) :: n_iters  = 0_i4
    LOGICAL     :: converged = .FALSE.
  END TYPE PH_Mat_XXX_Arg

CONTAINS

  !============================================================================!
  ! SUBROUTINE MD_Mat_XXX_ValidateProps                           [Public]
  ! Validates the flat PROPS array before populating Desc.
  ! First dummy CLASS(...) for direct TBP binding (no *_TBP forwarding stub).
  !============================================================================!
  SUBROUTINE MD_Mat_XXX_ValidateProps(desc, nprops, props, st)
    CLASS(MD_Mat_XXX_Desc), INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Minimum props count check
    IF (nprops < desc%nprops_min) THEN
      st%status_code = IF_STATUS_ERROR
      WRITE(st%message, '(A,I3,A,I3)') &
        'MD_Mat_XXX_ValidateProps: nprops=', nprops, &
        ' < nprops_min=', desc%nprops_min
      RETURN
    END IF

    !-- param1 physical range check (example: Young's modulus must be > 0)
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = IF_STATUS_ERROR
      WRITE(st%message, '(A,ES12.4)') &
        'MD_Mat_XXX_ValidateProps: props(1) must be > 0, got ', props(1)
      RETURN
    END IF

    !-- param2 physical range check (example: Poisson's ratio -1 < nu < 0.5)
    IF (nprops >= 2) THEN
      IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
        st%status_code = IF_STATUS_WARN
        WRITE(st%message, '(A,ES12.4)') &
          'MD_Mat_XXX_ValidateProps: props(2) (Poisson) out of (-1,0.5): ', props(2)
      END IF
    END IF

    !-- Add additional range / consistency checks here:
    !   e.g., yield stress > 0, hardening modulus >= 0, ...

  END SUBROUTINE MD_Mat_XXX_ValidateProps


  !============================================================================!
  ! SUBROUTINE MD_Mat_XXX_InitFromProps                           [Public]
  ! Unpacks the flat PROPS array into the Desc struct.
  ! Called once per UMAT invocation before constitutive evaluation.
  !============================================================================!
  SUBROUTINE MD_Mat_XXX_InitFromProps(desc, nprops, props, st)
    CLASS(MD_Mat_XXX_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(nprops)
    TYPE(ErrorStatusType), INTENT(OUT)   :: st

    CALL init_error_status(st)

    !-- Step 1: Validate first
    CALL MD_Mat_XXX_ValidateProps(desc, nprops, props, st)
    IF (st%status_code == IF_STATUS_ERROR) RETURN

    !-- Step 2: Unpack primary parameters
    desc%param1 = props(1)   ! e.g., E = Young's modulus [Pa]
    IF (nprops >= 2) desc%param2 = props(2)   ! e.g., nu = Poisson's ratio [-]
    IF (nprops >= 3) desc%param3 = props(3)   ! model-specific

    !-- Step 3: Compute derived quantities
    !   For isotropic elastic (example):
    !     G      = E / (2*(1+nu))
    !     lambda = E*nu / ((1+nu)*(1-2*nu))
    !     K      = E / (3*(1-2*nu))
    !
    !   Replace with model-appropriate derived quantities:
    IF (ABS(1.0_wp + desc%param2) > 1.0e-14_wp .AND. &
        ABS(1.0_wp - 2.0_wp*desc%param2) > 1.0e-14_wp) THEN
      desc%derived1 = desc%param1 / (2.0_wp * (1.0_wp + desc%param2))   ! G
      desc%derived2 = desc%param1 * desc%param2 / &
                      ((1.0_wp + desc%param2) * (1.0_wp - 2.0_wp*desc%param2)) ! λ
    ELSE
      st%status_code = IF_STATUS_ERROR
      st%message = 'MD_Mat_XXX_InitFromProps: singular derived constants (check param2)'
      RETURN
    END IF

    desc%is_initialized = .TRUE.

  END SUBROUTINE MD_Mat_XXX_InitFromProps


  !============================================================================!
  ! SUBROUTINE PH_Mat_XXX_UMAT_API                    [Public, UFC entry point]
  !
  ! Thin wrapper — UFC constitutive interface (7-parameter form with pnewdt
  ! bare scalar ABI exception, Principle #14 §3.1).
  !
  ! On entry: desc and state reflect converged state at t_n.
  !           ph_ctx carries strain increment Δε and thermal inputs.
  ! On exit:  state is updated to t_{n+1} (in-place).
  !           pnewdt carries step-size suggestion (1.0 = no change).
  !============================================================================!
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_Mat_XXX_UMAT_API(MD_Mat_Desc, PH_Mat_State, MD_Mat_Algo, &
                                   PH_Mat_Algo, PH_Mat_Ctx, RT_Com_Ctx, pnewdt)
    TYPE(MD_Mat_XXX_Desc),   INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_XXX_State),  INTENT(INOUT) :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo),  INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo),  INTENT(IN)    :: PH_Mat_Algo
    TYPE(PH_Mat_Base_Ctx),   INTENT(IN)    :: PH_Mat_Ctx
    TYPE(RT_Com_Base_Ctx),   INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                INTENT(INOUT) :: pnewdt   ! ABI exception bare scalar

    TYPE(PH_Mat_XXX_Arg) :: mat_arg

    !-- Guard: Desc must be initialized
    IF (.NOT. MD_Mat_Desc%is_initialized) THEN
      PH_Mat_State%status%status_code = IF_STATUS_ERROR
      PH_Mat_State%status%message = 'PH_Mat_XXX_UMAT_API: Desc not initialized'
      pnewdt = 0.25_wp   ! Signal cutback
      RETURN
    END IF

    !-- Marshal PH_Mat_Base_Ctx + MD algo → PH_Mat_XXX_Arg [IN] slice
    mat_arg%dstran          = PH_Mat_Ctx%dstran
    mat_arg%drot            = PH_Mat_Ctx%drot
    mat_arg%dfgrd1          = PH_Mat_Ctx%dfgrd1
    mat_arg%temp            = PH_Mat_Ctx%temp
    mat_arg%dtemp           = PH_Mat_Ctx%dtemp
    mat_arg%coords          = PH_Mat_Ctx%coords
    mat_arg%celent          = PH_Mat_Ctx%celent
    mat_arg%compute_tangent = MD_Mat_Algo%compute_tangent
    mat_arg%ntens           = MD_Mat_Algo%ntens
    mat_arg%ndi             = MD_Mat_Algo%ndi
    mat_arg%nshr            = MD_Mat_Algo%nshr

    !-- Delegate to PRIVATE physics implementation
    CALL PH_Mat_XXX_UMAT_Impl(MD_Mat_Desc, PH_Mat_State, MD_Mat_Algo, &
                                PH_Mat_Algo, mat_arg)

    !-- Scatter [OUT] slice → state and pnewdt
    IF (mat_arg%success) THEN
      PH_Mat_State%stress  = mat_arg%stress
      PH_Mat_State%ddsdde  = mat_arg%ddsdde
      PH_Mat_State%n_iters = mat_arg%n_iters
      PH_Mat_State%converged = mat_arg%converged
    END IF
    PH_Mat_State%status = mat_arg%status
    pnewdt = mat_arg%pnewdt

  END SUBROUTINE PH_Mat_XXX_UMAT_API


  !============================================================================!
  ! SUBROUTINE PH_Mat_XXX_UMAT_Impl                  [PRIVATE, hot-path physics]
  !
  ! Constitutive algorithm implementation.
  ! Receives unified mat_arg; updates [OUT] fields in-place.
  ! NEVER allocates dynamic memory.
  !
  ! Algorithm outline (replace with model-specific physics):
  !   1. Elastic predictor: σ_trial = σ_n + C : Δε
  !   2. Yield check: f(σ_trial, state) ≤ 0 → elastic step
  !   3. Return mapping (if plastic): local Newton to satisfy f = 0
  !   4. Consistent tangent update
  !============================================================================!
  SUBROUTINE PH_Mat_XXX_UMAT_Impl(desc, state, md_algo, ph_algo, mat_arg)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: state
    TYPE(MD_Mat_Base_Algo), INTENT(IN)    :: md_algo
    TYPE(PH_Mat_Base_Algo), INTENT(IN)    :: ph_algo
    TYPE(PH_Mat_XXX_Arg),   INTENT(INOUT) :: mat_arg

    !-- Local variables (all stack-allocated — no ALLOCATABLE)
    REAL(wp) :: sigma_trial(6), ddsdde_e(6,6)
    REAL(wp) :: G, lam, K
    REAL(wp) :: f_yield
    INTEGER(i4) :: iter, nt
    LOGICAL :: elastic_step

    CALL init_error_status(mat_arg%status)
    mat_arg%success   = .FALSE.
    mat_arg%pnewdt    = RT_PNEWDT_NO_CHANGE
    mat_arg%n_iters   = 0_i4
    mat_arg%converged = .FALSE.

    nt  = mat_arg%ntens
    G   = desc%derived1  ! Shear modulus
    lam = desc%derived2  ! Lamé λ

    !==========================================================================!
    ! Step 1: Elastic stiffness tensor C (isotropic, Voigt 6×6)
    !   C_ijkl = λ δᵢⱼδₖₗ + G(δᵢₖδⱼₗ + δᵢₗδⱼₖ)
    !   Voigt: diagonal normal = λ+2G; off-diagonal normal = λ; shear = G
    !==========================================================================!
    ddsdde_e = 0.0_wp
    ddsdde_e(1,1) = lam + 2.0_wp*G
    ddsdde_e(2,2) = lam + 2.0_wp*G
    ddsdde_e(3,3) = lam + 2.0_wp*G
    ddsdde_e(1,2) = lam;  ddsdde_e(2,1) = lam
    ddsdde_e(1,3) = lam;  ddsdde_e(3,1) = lam
    ddsdde_e(2,3) = lam;  ddsdde_e(3,2) = lam
    ddsdde_e(4,4) = G
    ddsdde_e(5,5) = G
    ddsdde_e(6,6) = G

    !==========================================================================!
    ! Step 2: Elastic predictor  σ_trial = σ_n + C_e : Δε
    !==========================================================================!
    BLOCK
      INTEGER(i4) :: ii, jj
      sigma_trial = state%stress
      DO ii = 1, nt
        DO jj = 1, nt
          sigma_trial(ii) = sigma_trial(ii) + ddsdde_e(ii,jj) * mat_arg%dstran(jj)
        END DO
      END DO
    END BLOCK

    !==========================================================================!
    ! Step 3: Yield function evaluation
    !   f(σ_trial, state) = ||s_trial|| - sqrt(2/3) * σ_y(peeq)
    !   Substitute with model-specific yield function:
    !     Von Mises:      f = q - σ_y
    !     Drucker-Prager: f = q + p*tan(φ) - c
    !     ...
    !==========================================================================!
    f_yield = -1.0_wp   ! < 0 → elastic (placeholder; implement f(σ_trial))
    elastic_step = (f_yield <= 0.0_wp)

    IF (elastic_step) THEN
      !==========================================================================!
      ! Elastic step: accept trial stress directly
      !==========================================================================!
      mat_arg%stress    = sigma_trial
      mat_arg%ddsdde    = ddsdde_e
      mat_arg%converged = .TRUE.
      mat_arg%n_iters   = 0_i4

    ELSE
      !==========================================================================!
      ! Step 4: Return mapping (plastic corrector)
      !   Implement local Newton iteration to satisfy:
      !     f(σ_{n+1}, state_{n+1}) = 0
      !     σ_{n+1} = σ_trial - C : n̂ * Δγ
      !     state_{n+1} = state_n + hardening rules
      !
      !   Stub: copy trial stress (map_ok = .FALSE. until implemented)
      !==========================================================================!
      mat_arg%stress = sigma_trial   ! ← STUB: replace with return-mapped stress
      mat_arg%ddsdde = ddsdde_e      ! ← STUB: replace with consistent tangent

      !-- Local Newton stub (replace with actual return mapping)
      mat_arg%converged = .FALSE.  ! Set .TRUE. when return mapping converges
      mat_arg%n_iters   = 0_i4

      IF (.NOT. mat_arg%converged) THEN
        !-- Request cutback if return mapping fails (design choice)
        mat_arg%pnewdt = ph_algo%pnewdt_min
        mat_arg%status%status_code = IF_STATUS_WARN
        mat_arg%status%message     = 'PH_Mat_XXX_UMAT_Impl: return-mapping not converged (stub)'
      END IF

    END IF

    !==========================================================================!
    ! Step 5: Update state (strain, dfgrd0) for next increment
    !==========================================================================!
    state%stran  = state%stran  + mat_arg%dstran   ! ε_n → ε_{n+1}
    state%dfgrd0 = mat_arg%dfgrd1                   ! F₀ ← F₁

    !==========================================================================!
    ! Step 6: Clamp pnewdt to allowable range
    !==========================================================================!
    IF (mat_arg%pnewdt < ph_algo%pnewdt_min) mat_arg%pnewdt = ph_algo%pnewdt_min
    IF (mat_arg%pnewdt > ph_algo%pnewdt_max) mat_arg%pnewdt = ph_algo%pnewdt_max

    mat_arg%success = (mat_arg%status%status_code /= IF_STATUS_ERROR)

  END SUBROUTINE PH_Mat_XXX_UMAT_Impl


  !============================================================================!
  ! SUBROUTINE PH_Mat_XXX_UpdateStress              [Public, MatPoint UEL entry]
  !
  ! Thin MatPoint entry called by UEL kernel (PH_Elem_XXX_API / PH_XXX_UEL).
  ! Marshals context into UMAT_API (which builds PH_Mat_XXX_Arg).
  !
  ! MatPoint_In / MatPoint_Out are lightweight structs defined locally here;
  ! in production, define them in a shared MatPoint_Types module.
  !============================================================================!
  SUBROUTINE PH_Mat_XXX_UpdateStress(desc, state, md_algo, ph_algo, &
                                      ph_ctx, rt_ctx, pnewdt, uel_status)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: state
    TYPE(MD_Mat_Base_Algo), INTENT(IN)    :: md_algo
    TYPE(PH_Mat_Base_Algo), INTENT(IN)    :: ph_algo
    TYPE(PH_Mat_Base_Ctx),  INTENT(IN)    :: ph_ctx
    TYPE(RT_Com_Base_Ctx),  INTENT(IN)    :: rt_ctx
    REAL(wp),               INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),  INTENT(OUT)   :: uel_status

    !-- Delegate directly to UMAT_API (same 7-parameter form)
    CALL PH_Mat_XXX_UMAT_API(desc, state, md_algo, ph_algo, ph_ctx, rt_ctx, pnewdt)
    uel_status = state%status

  END SUBROUTINE PH_Mat_XXX_UpdateStress


  !============================================================================!
  ! SUBROUTINE PH_Mat_XXX_UMAT                    [Public, registry context form]
  !
  ! PH_UMAT_Intf-compatible entry for material registry.
  ! Signature: (ctx, status) where ctx carries all needed typed structs as
  ! pointers.  Called via function pointer: PH_Mat_Reg_Add(mat_id, ..., umat_proc=)
  !
  ! Note: In production, ctx is a polymorphic TYPE(PH_UMAT_Context) carrying
  ! pointers to desc/state/algo/rt_ctx.  This stub uses a placeholder approach
  ! (separate explicit arguments) that is compatible with the registry interface.
  !============================================================================!
  SUBROUTINE PH_Mat_XXX_UMAT(MD_Mat_Desc, PH_Mat_State, MD_Mat_Algo, &
                               PH_Mat_Algo, PH_Mat_Ctx, RT_Com_Ctx,   &
                               pnewdt, status)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo), INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo), INTENT(IN)    :: PH_Mat_Algo
    TYPE(PH_Mat_Base_Ctx),  INTENT(IN)    :: PH_Mat_Ctx
    TYPE(RT_Com_Base_Ctx),  INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),               INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    !-- Delegate to API
    CALL PH_Mat_XXX_UMAT_API(MD_Mat_Desc, PH_Mat_State, MD_Mat_Algo, &
                               PH_Mat_Algo, PH_Mat_Ctx, RT_Com_Ctx, pnewdt)
    status = PH_Mat_State%status

  END SUBROUTINE PH_Mat_XXX_UMAT

END MODULE PH_XXX_Mat
