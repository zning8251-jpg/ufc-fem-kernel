!===============================================================================
! Template: PH_XXX_VUMAT.f90                                     [Template v1.0]
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.0 (2026-04)  First release; vector algorithm for Explicit; aligned with
!                   PH_XXX_UMAT; SIO-compliant (Principle #14)
!
! Layer:  L4_PH - Physics Layer
! Domain: Material / [Family] (e.g., ELA, PLM, HYP, DMG, CMP, ...)
!
! PURPOSE:
!   UFC-native VUMAT (Vectorized User MATerial) for Abaqus/Explicit solver.
!   Single-step direct return mapping; strain-rate dependent; energy tracking.
!
! DESIGN PRINCIPLES:
!   - Prefer direct stress return (no NR iteration, unlike UMAT)
!   - Support strain-rate effects (Johnson-Cook, Cowper-Symonds, etc.)
!   - Vectorized processing (NBLOCK integration points simultaneously)
!   - Energy dissipation tracking for field-output / energy checks
!   - CFL stability monitoring for adaptive time-stepping
!
! KEY DIFFERENCES VS UMAT:
!
!   The ONLY criterion for UMAT vs VUMAT is SOLVER TYPE (Standard vs Explicit).
!   Rate-dependent materials (viscoplastic, creep, JC, etc.) exist in BOTH paths.
!
!   UMAT (Abaqus/Standard — implicit time integration):
!     - MUST return D_tang (consistent tangent 6x6), used by global Newton-Raphson
!     - Can iterate within increment: NR return mapping until convergence
!     - Rate-dependence: compute ε̇ = Δε/Δt internally (DTIME available)
!       e.g. viscoplastic (Perzyna, Duvaut-Lions), creep (Norton), JC rate term
!       BUT must also provide rate-consistent tangent ∂σ/∂Δε (extra work vs Explicit)
!     - Δt is solver-controlled (adaptive), not necessarily CFL-safe
!     - Scalar call: one integration point per invocation
!
!   VUMAT (Abaqus/Explicit — central-difference time integration):
!     - D_tang NOT needed (no global stiffness assembly in explicit)
!     - Single-step direct return: one pass, no inner iteration
!     - Rate-dependence: ABAQUS passes DENSITY, STRAININC, DTIME externally;
!       ε̇ per IP is trivially available and physically meaningful (high-speed events)
!       No need to derive consistent rate tangent
!     - Δt MUST be CFL-safe: Δt < celent / c_sound (material must check/report)
!     - Vectorized call: NBLOCK integration points per invocation
!
! VECTORIZATION NOTES:
!   - All strain/stress arrays have first dimension NBLOCK
!   - Props, constants, material properties: shared across all IPs
!   - Internal state: per-IP (allocate nblock-sized arrays if needed)
!   - Loop over NBLOCK manually or use FORALL for vectorization
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  PH_XXX_VUMAT_API: 5 params (6 + pnewdt bare scalar)
!   SIO-02 ✓  _Impl last param is PH_XXX_VUMAT_Args (INOUT unified bundle)
!   SIO-03 ✓  PH_XXX_VUMAT_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members (except [OUT] diagnostics)
!
! MULTI-MATERIAL DISPATCH:
!   Similar to UMAT: props-based evaluation → use L3_MD dispatch entry.
!   Keep material-specific logic out of this wrapper; implement in _Impl.
!
! HOW TO USE:
!   1. Copy to L4_PH/Material/[Family]/
!   2. Rename: PH_[Family]_[Model]_VUMAT.f90
!   3. Replace XXX -> [Family]_[Model] throughout (same as UMAT)
!   4. USE matching Desc from L3_MD
!   5. Implement constitutive algorithm in PRIVATE PH_XXX_VUMAT_Impl
!      (follow the _Core/_Standard/_Explicit pattern if need code reuse)
!
! NAMING CONVENTION:
!   Module:      PH_[Family]_[Model]_VUMAT  -> PH_ELA_VUMAT, PH_PLM_J2_VUMAT
!   Subroutine:  SUBROUTINE PH_XXX_VUMAT_API(...)
!   Helper:      PRIVATE SUBROUTINE XXX_<Verb>_<Noun>
!
! ABAQUS VUMAT SIGNATURE (37 parameters, packed into structs):
!   SUBROUTINE VUMAT(NBLOCK, NDIR, NSHR, NSTATEV, NFIELDV, NPROPS,
!     & JSTEP, KINC, TIME, DTIME, CMNAME, ORNAME, PROPS, DENSITY,
!     & STRAININC, RELSPININC, STRESSOLD, STRAN, D, STRESS, STATEV,
!     & ENERINC, FIELD, FIELDOLD, NOEL, NPT, LAYER, KSPT, LFLAGS,
!     & MLVARX, CELENT, FEETIM, NTERMS, PREDEF)
!
! Contract: L4_PH/contracts/CONTRACT_VUMAT_Explicit.md
!===============================================================================
MODULE PH_XXX_VUMAT
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Base types
  USE MD_Mat_Types,  ONLY: MD_Mat_Base_State
  !-- [MD] Model-specific Desc
  USE MD_Mat_XXX,    ONLY: MD_Mat_XXX_Desc
  !-- [PH] Per-increment types
  USE PH_Mat_Types,  ONLY: PH_Mat_Base_Ctx, &
                           PH_Mat_Base_Algo
  !-- [RT] Runtime context
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, &
                          RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_XXX_State   ! State type (export for tests)
  PUBLIC :: PH_XXX_VUMAT_Args  ! Unified call-time IO bundle
  PUBLIC :: PH_XXX_VUMAT_API   ! UFC-native VUMAT entry

  !-----------------------------------------------------------------------------
  ! STATE type: identical to UMAT for state persistence
  !   (Can be instantiated per-IP or as array[NBLOCK])
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Mat_Base_State) :: PH_Mat_XXX_State
    !-- TODO: replace placeholders with actual model internal state variables
    !   REAL(wp) :: peeq           = 0.0_wp    ! Equiv. plastic strain
    !   REAL(wp) :: D              = 0.0_wp    ! Damage variable
    REAL(wp) :: ivar1 = 0.0_wp     ! Placeholder ISV 1
    REAL(wp) :: ivar2 = 0.0_wp     ! Placeholder ISV 2
  END TYPE PH_Mat_XXX_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_VUMAT_Args — unified bundle for _Impl (SIO Principle #14)
  !
  !   [IN]  scalars / fixed arrays only; no ALLOCATABLE per SIO-14
  !   [OUT] status, diagnostics, energy; ALLOCATABLE allowed for [OUT]
  !
  !   Key differences vs UMAT_Args:
  !     - nblock: number of integration points in this block
  !     - strain_rate(:,:), density(:), celent(:): per-IP vectors
  !     - enerinc(:): per-IP energy dissipation output
  !     - no pnewdt_min/max (ABAQUS controls CFL via dtime)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_VUMAT_Args
    !-- [IN] Explicit-specific
    INTEGER(i4) :: nblock         = 1_i4
    LOGICAL     :: flag_nlgeom    = .FALSE.
    LOGICAL     :: flag_firstinc  = .FALSE.
    INTEGER(i4) :: ip_index_base  = 0_i4      ! First IP index in block
    !-- TODO: model-specific [IN] scalars (POINTER ok per SIO-05)
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success      = .FALSE.
    REAL(wp)              :: pnewdt       = 1.0_wp
    REAL(wp), ALLOCATABLE :: residual_norm(:)      ! [nblock] convergence
    INTEGER(i4), ALLOCATABLE :: iterations(:)      ! [nblock]
    REAL(wp), ALLOCATABLE :: cfl_number(:)         ! [nblock] CFL safety
    
    !-- [OUT] Energy dissipation (required by Explicit)
    REAL(wp), ALLOCATABLE :: enerinc(:,:)  ! [nblock, 8] energy breakdown
                                           ! (1:plastic, 2:damage, 3:friction, ...)
  END TYPE PH_XXX_VUMAT_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO)
  !============================================================================
  !> PH_XXX_VUMAT_API
  !>
  !> ROLE: THIN WRAPPER — fills PH_XXX_VUMAT_Args, delegates to PH_XXX_VUMAT_Impl.
  !>   DO NOT add constitutive physics here; implement in _Impl.
  !>
  !> Vectorization:
  !>   - Typically called ONCE per element per time-step
  !>   - Processes NBLOCK integration points simultaneously
  !>   - No explicit loop; all arrays are [NBLOCK, ntens] or similar
  !>
  !> Parameters:
  !>   MD_Mat_Desc  [MD] material parameters (read-only, built once)
  !>   PH_Mat_Ctx   [PH] driving inputs: dstran, strain_rate, dfgrd1, drot, temp
  !>   PH_Mat_State [PH] material state array or scalar (depends on caller)
  !>   MD_Mat_Algo  [MD] pre-analysis config (ndi, nshr, ntens, etc.)
  !>   PH_Mat_Algo  [PH] iteration control (currently minimal for Explicit)
  !>   RT_Com_Ctx   [RT] bookkeeping: kstep, kinc, elem_id, dtime, nlgeom
  !>   pnewdt       [RT] INOUT step-ratio feedback (typically left at 1.0 for Explicit)
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_VUMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, &
      PH_Mat_Algo, RT_Com_Ctx, pnewdt)
    TYPE(MD_Mat_XXX_Desc),    INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Base_Ctx),    INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_XXX_State),   INTENT(INOUT) :: PH_Mat_State  ! per-IP or array
    TYPE(MD_Mat_Base_Algo),   INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo),   INTENT(IN)    :: PH_Mat_Algo
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                 INTENT(INOUT) :: pnewdt

    TYPE(PH_XXX_VUMAT_Args) :: vumat_args

    !-- Initialize args
    vumat_args%nblock   = 1_i4  ! TODO: fill from L5_RT if vectorized call
    vumat_args%flag_nlgeom   = RT_Com_Ctx%nlgeom
    vumat_args%flag_firstinc = RT_Com_Ctx%first_increment
    vumat_args%ip_index_base = 1_i4

    !-- Allocate [OUT] arrays
    IF (ALLOCATED(vumat_args%residual_norm)) DEALLOCATE(vumat_args%residual_norm)
    IF (ALLOCATED(vumat_args%iterations))    DEALLOCATE(vumat_args%iterations)
    IF (ALLOCATED(vumat_args%cfl_number))    DEALLOCATE(vumat_args%cfl_number)
    IF (ALLOCATED(vumat_args%enerinc))       DEALLOCATE(vumat_args%enerinc)
    
    ALLOCATE(vumat_args%residual_norm(vumat_args%nblock))
    ALLOCATE(vumat_args%iterations(vumat_args%nblock))
    ALLOCATE(vumat_args%cfl_number(vumat_args%nblock))
    ALLOCATE(vumat_args%enerinc(vumat_args%nblock, 8))
    
    vumat_args%success = .FALSE.

    CALL PH_XXX_VUMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, &
        PH_Mat_Algo, vumat_args)

    pnewdt = vumat_args%pnewdt
  END SUBROUTINE PH_XXX_VUMAT_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all constitutive physics here
  !============================================================================
  !> PH_XXX_VUMAT_Impl
  !>
  !> Single-step direct return mapping (no NR iteration):
  !>   1. Elastic predictor
  !>   2. Yield check
  !>   3. Plastic correction (if needed)
  !>   4. Energy tracking
  !>   5. CFL check
  !>
  !> Contract:
  !>   args%success .TRUE. IFF increment computed; state valid
  !>   args%enerinc(:,:) filled; args%cfl_number(:) checked
  !>   PH_Mat_State updated in-place
  SUBROUTINE PH_XXX_VUMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &
      MD_Mat_Algo, PH_Mat_Algo, args)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Base_Ctx),  INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo), INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo), INTENT(IN)    :: PH_Mat_Algo
    TYPE(PH_XXX_VUMAT_Args), INTENT(INOUT) :: args

    !-- Local variables (stack-allocated for hot-path)
    !$UFC HOT_PATH
    REAL(wp)    :: D_el(6,6)         ! Elastic stiffness
    REAL(wp)    :: stress_trial(6)   ! Trial stress
    REAL(wp)    :: f_yield           ! Yield function
    REAL(wp)    :: strain_rate_mag   ! Strain rate magnitude
    REAL(wp)    :: strain_rate_coef  ! Strain rate multiplier (Johnson-Cook, etc.)
    INTEGER(i4) :: ntens
    REAL(wp)    :: cfl_limit

    CALL init_error_status(args%status)
    args%success = .FALSE.
    args%pnewdt  = RT_PNEWDT_NO_CHANGE
    args%residual_norm = 0.0_wp
    args%iterations    = 0_i4
    args%cfl_number    = 0.0_wp
    args%enerinc       = 0.0_wp

    CALL init_error_status(PH_Mat_State%status)
    PH_Mat_State%converged  = .TRUE.

    ntens = MD_Mat_Algo%ntens
    IF (ntens < 1 .OR. ntens > 6) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_VUMAT_Impl]: ntens out of range [1,6]')
      PH_Mat_State%status = args%status
      RETURN
    END IF

    IF (.NOT. MD_Mat_Desc%is_initialized) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_VUMAT_Impl]: MD_Mat_XXX_Desc not initialized')
      PH_Mat_State%status = args%status
      RETURN
    END IF

    !=========================================================================
    ! Step 1: Build elastic stiffness
    !=========================================================================
    CALL XXX_Build_D_el(MD_Mat_Desc, D_el)

    !=========================================================================
    ! Step 2: Elastic predictor (direct, single-step)
    !=========================================================================
    stress_trial(1:ntens) = PH_Mat_State%stress(1:ntens) &
                          + MATMUL(D_el(1:ntens,1:ntens), PH_Mat_Ctx%dstran(1:ntens))

    !=========================================================================
    ! Step 3: Strain-rate effects (Explicit-specific)
    !   For J2 plasticity: σ_y(eps_rate) = σ_y0 * (1 + (eps_rate/C)^(1/p))
    !   Replace with your model (Johnson-Cook, Zerilli-Armstrong, etc.)
    !=========================================================================
    strain_rate_mag = XXX_Strain_Rate_Magnitude(MD_Mat_Desc, PH_Mat_Ctx%dstran)
    strain_rate_coef = XXX_Strain_Rate_Multiplier(MD_Mat_Desc, strain_rate_mag)

    !=========================================================================
    ! Step 4: Yield check (direct, no iteration)
    !=========================================================================
    f_yield = XXX_Yield_F(MD_Mat_Desc, stress_trial, PH_Mat_State%ivar1, &
                         strain_rate_coef)

    IF (f_yield <= 0.0_wp) THEN
      !-- Elastic step
      PH_Mat_State%stress(1:ntens) = stress_trial(1:ntens)
      ! D_tang not used in Explicit, but can be computed if needed
      ! PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens)

    ELSE
      !-- Elasto-plastic step (direct return, single-step)
      !   Stub: implement plastic correction here
      !   d_lambda = f_yield / H_tangent  (single scalar equation)
      !   sigma_new = sigma_trial - d_lambda * C : flow_direction
      !
      !   TODO: implement XXX_Plastic_Direct_Return(...) subroutine
      CALL XXX_Plastic_Direct_Return(MD_Mat_Desc, strain_rate_coef, &
          stress_trial, D_el, PH_Mat_State)
    END IF

    !=========================================================================
    ! Step 5: Energy dissipation tracking (required by Explicit)
    !=========================================================================
    !   args%enerinc(:, 1) = plastic dissipation density [J/m³]
    !   args%enerinc(:, 2) = damage dissipation density
    !   args%enerinc(:, 3) = friction dissipation density
    !   etc.
    !=========================================================================
    CALL XXX_Compute_Energy_Dissipation(MD_Mat_Desc, PH_Mat_Ctx, &
        PH_Mat_State, args%enerinc)

    !=========================================================================
    ! Step 6: CFL stability check (Explicit-specific)
    !   sound_speed = sqrt(E/rho)  for acoustic wave in material
    !   CFL = sound_speed * dtime / celent  (should be < 1 for stability)
    !=========================================================================
    args%cfl_number(1) = XXX_Compute_CFL(MD_Mat_Desc, PH_Mat_Ctx%celent)
    IF (args%cfl_number(1) >= 1.0_wp) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_VUMAT_Impl]: CFL criterion violated')
      RETURN
    END IF

    !=========================================================================
    ! Step 7: Update total strain history
    !=========================================================================
    PH_Mat_State%stran(1:ntens) = PH_Mat_State%stran(1:ntens) &
                                + PH_Mat_Ctx%dstran(1:ntens)

    !-- Finalise
    args%success = .TRUE.
    PH_Mat_State%status%status_code = IF_STATUS_OK
    args%status%status_code          = IF_STATUS_OK
  END SUBROUTINE PH_XXX_VUMAT_Impl

  !============================================================================
  ! PRIVATE HELPERS
  !============================================================================

  SUBROUTINE XXX_Build_D_el(MD_Mat_Desc, D)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN)  :: MD_Mat_Desc
    REAL(wp),              INTENT(OUT) :: D(6,6)
    REAL(wp) :: lam, mu
    !-- TODO: Extract from MD_Mat_Desc
    lam = 0.0_wp
    mu  = 0.0_wp
    D = 0.0_wp
    D(1,1) = lam + 2.0_wp*mu;  D(1,2) = lam;  D(1,3) = lam
    D(2,1) = lam;  D(2,2) = lam + 2.0_wp*mu;  D(2,3) = lam
    D(3,1) = lam;  D(3,2) = lam;  D(3,3) = lam + 2.0_wp*mu
    D(4,4) = mu;  D(5,5) = mu;  D(6,6) = mu
  END SUBROUTINE XXX_Build_D_el

  PURE FUNCTION XXX_Strain_Rate_Magnitude(MD_Mat_Desc, dstran) RESULT(rate_mag)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN) :: MD_Mat_Desc
    REAL(wp),              INTENT(IN) :: dstran(6)
    REAL(wp) :: rate_mag
    !-- von Mises strain rate
    !   dstran has units [strain/time]
    rate_mag = SQRT(2.0_wp/3.0_wp * &
        ((dstran(1)-dstran(2))**2 + (dstran(2)-dstran(3))**2 + &
         (dstran(3)-dstran(1))**2 + 2.0_wp*(dstran(4)**2 + dstran(5)**2 + dstran(6)**2)))
  END FUNCTION XXX_Strain_Rate_Magnitude

  PURE FUNCTION XXX_Strain_Rate_Multiplier(MD_Mat_Desc, strain_rate_mag) RESULT(coef)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN) :: MD_Mat_Desc
    REAL(wp),              INTENT(IN) :: strain_rate_mag
    REAL(wp) :: coef
    !-- Johnson-Cook: k = (1 + (eps_rate / C)^(1/p))
    !-- TODO: extract C, p from MD_Mat_Desc
    REAL(wp) :: C, p
    C = 1.0_wp
    p = 1.0_wp
    coef = 1.0_wp + (strain_rate_mag / MAX(C, 1.0e-30_wp))**p
  END FUNCTION XXX_Strain_Rate_Multiplier

  PURE FUNCTION XXX_Yield_F(MD_Mat_Desc, sigma, kappa, strain_rate_coef) RESULT(f)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN) :: MD_Mat_Desc
    REAL(wp),              INTENT(IN) :: sigma(6), kappa, strain_rate_coef
    REAL(wp) :: f, p, q
    !-- von Mises with strain-rate multiplier
    p = (sigma(1)+sigma(2)+sigma(3)) / 3.0_wp
    q = SQRT(1.5_wp * ((sigma(1)-p)**2 + (sigma(2)-p)**2 + (sigma(3)-p)**2 &
                       + 2.0_wp*(sigma(4)**2 + sigma(5)**2 + sigma(6)**2)))
    !-- TODO: replace 0.0_wp with actual yield stress expression
    f = q - 0.0_wp * strain_rate_coef
  END FUNCTION XXX_Yield_F

  SUBROUTINE XXX_Plastic_Direct_Return(MD_Mat_Desc, strain_rate_coef, &
      stress_trial, D_el, state)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: MD_Mat_Desc
    REAL(wp),               INTENT(IN)    :: strain_rate_coef
    REAL(wp),               INTENT(IN)    :: stress_trial(6), D_el(6,6)
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: state
    !-- TODO: implement direct return mapping (single step, no iteration)
    !   Placeholder: just accept trial stress
    state%stress = stress_trial
  END SUBROUTINE XXX_Plastic_Direct_Return

  SUBROUTINE XXX_Compute_Energy_Dissipation(MD_Mat_Desc, PH_Mat_Ctx, &
      state, enerinc)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)  :: MD_Mat_Desc
    TYPE(PH_Mat_Base_Ctx),  INTENT(IN)  :: PH_Mat_Ctx
    TYPE(PH_Mat_XXX_State), INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: enerinc(:,:)
    !-- TODO: compute plastic work, damage dissipation, etc.
    enerinc = 0.0_wp
  END SUBROUTINE XXX_Compute_Energy_Dissipation

  PURE FUNCTION XXX_Compute_CFL(MD_Mat_Desc, celent) RESULT(cfl)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN) :: MD_Mat_Desc
    REAL(wp),              INTENT(IN) :: celent  ! element characteristic length
    REAL(wp) :: cfl, sound_speed
    !-- Acoustic wave speed: c = sqrt(E/rho)
    !-- TODO: extract E, rho from MD_Mat_Desc
    sound_speed = 1.0_wp  ! placeholder
    cfl = sound_speed / MAX(celent, 1.0e-30_wp)
  END FUNCTION XXX_Compute_CFL

END MODULE PH_XXX_VUMAT

!===============================================================================
! STRUCT REFERENCE CARD — VUMAT-specific fields
!
! Type: PH_XXX_VUMAT_Args
!   [IN]  nblock: typically 8 or 16 (integration points in vectorized block)
!   [IN]  flag_nlgeom: nonlinear geometry flag
!   [OUT] enerinc(nblock, 8): energy dissipation breakdown per IP
!   [OUT] cfl_number(nblock): CFL criterion safety factor per IP
!   [OUT] success: .FALSE. if ANY IP failed; all-or-nothing policy
!===============================================================================
