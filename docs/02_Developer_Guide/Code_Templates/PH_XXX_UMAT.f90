!===============================================================================
! Template: PH_XXX_UMAT.f90                                     [Template v4.3]
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v4.3 (2026-03)  Single PH_XXX_UMAT_Args (replaces _In/_Out); _Impl(args).
!   v4.2 (2026-03)  Add _In/_Out TYPE pair (Principle #14 SIO); split API/Impl;
!                   add is_initialized guard; stran update in Step 5; pnewdt in Out
!   v4.1 (prev)     ntens read from MD_Mat_Base_Algo
!   v4.0 (prev)     8-TYPE minimal design baseline
! Layer:  L4_PH - Physics Layer
! Domain: Material / [Family] (e.g., ELA / PLM / HYP / DMG / CMP / ...)
!
! PURPOSE:
!   UFC-native material compute interface.
!
! Template choice (UFC 默认):
!   **Preferred** entry for new **constitutive (UMAT)** work vs. `PH_XXX_Mat.f90`
!   (single-module Mat+Desc embedded). Use this file when Desc lives in **L3_MD**
!   and you follow the standard 7-param `PH_XXX_UMAT_API` + `_Impl` split.
!
!   "Unified Fortran Constitutive" (UFC) style:
!     - Module name = Subroutine name  (PH_ELA_UMAT, PH_PLM_J2_UMAT, ...)
!     - Typed structs replace 37 ABAQUS UMAT flat parameters
!     - No flat arrays visible beyond this subroutine
!     - L5_RT and ABAQUS adapters BOTH call THIS interface
!
! DESIGN: "shen si ABAQUS UMAT er xing bu si"  [8-TYPE minimal, v4.2]
!   v4.2 (Principle #14 / SIO-compliant upgrade):
!     - PH_XXX_UMAT_Args holds call-time [IN]/[OUT] fields (single TYPE, INOUT)
!     - PH_XXX_UMAT_API is a THIN WRAPPER that fills args and delegates to _Impl
!     - _Impl carries the actual hot-path computation; API is pure glue
!     - Callers at L5_RT/ABAQUS adapter level use PH_XXX_UMAT_API (unchanged ABI)
!     - PH_XXX_UMAT_Args is PUBLIC for unit-test harness
!
!   v4.1: Active Voigt size ntens (and ndi/nshr) read from MD_Mat_Base_Algo.
!   v4.0: Original 8-TYPE minimal design.
!
!   UFC wraps parameters into typed structs (8-TYPE lower-bound):
!     desc    <- material parameters  [MD layer, read-only]
!     state   <- material state       [PH layer, evolves in-place]
!     md_algo <- pre-analysis config  [MD layer]
!     ph_algo <- iteration control    [PH layer]
!     ph_ctx  <- per-increment input  [PH layer]
!     rt_ctx  <- runtime bookkeeping  [RT layer]
!     pnewdt  <- bare REAL scalar     [RT layer, INOUT, replaces RT_Com_Base_Algo]
!
! MULTI-MATERIAL / DISPATCH (contract Pattern B):
!   Props-based evaluation → use L3_MD/Material/Dispatch/MD_Mat_Lib.f90 entry
!   UF_Mat_Eval_Dispatch (or successor). Do not mix that control flow inside this
!   single-model UMAT file; keep one concrete MD_Mat_*_Desc per PH_*_UMAT module.
!
! PLASTIC BRANCH:
!   The return-mapping block below is a STUB: map_ok stays .FALSE. until you
!   implement consistent stress/tangent update and set map_ok=.TRUE. on convergence.
!   Under quasi-Newton global solvers, document whether ddsdde is a consistent
!   tangent or an optional approximation (see L5_RT/Solver/CONTRACT.md).
!
! ABAQUS COMPATIBILITY:
!   If ABAQUS UMAT interop is needed, use the companion adapter in
!   PH_Mat_XXX_XXX.f90 (SECTION 2 therein), which packs the 37 UMAT flat
!   parameters into these structs and calls PH_XXX_UMAT_API directly.
!   Flat arrays ONLY appear in that adapter; NEVER in this file.
!
! NAMING CONVENTION:
!   Module:      PH_[Family]_[Model]_UMAT  -> PH_ELA_UMAT, PH_PLM_J2_UMAT
!   Subroutine:  same name as module
!   XXX: [Family]_[Model] abbreviation (ELA, PLM_J2, DMG_LEMA, HYP_NeoH, ...)
!
!   FORTRAN NOTE: Fortran does not allow a MODULE and a SUBROUTINE inside it
!   to share the same identifier.  The solution is to name the module
!   PH_XXX_UMAT (matching the subroutine base name) and append _API suffix
!   to the actual subroutine: SUBROUTINE PH_XXX_UMAT_API.
!   Callers USE PH_XXX_UMAT and call PH_XXX_UMAT_API(...).
!   When instantiating: rename both MODULE PH_XXX_UMAT -> PH_ELA_UMAT
!   and SUBROUTINE PH_XXX_UMAT_API -> PH_ELA_UMAT_API.
!
! HOW TO USE:
!   1. Copy to L4_PH/Material/[Family]/
!   2. Rename: PH_[Family]_[Model]_UMAT.f90
!   3. Replace XXX -> [Family]_[Model] throughout
!   4. USE matching Desc from L3_MD; define State here
!   5. Add model-specific fields to PH_XXX_UMAT_Args if needed
!   6. Implement constitutive algorithm in PRIVATE SUBROUTINE PH_XXX_UMAT_Impl
!      PH_XXX_UMAT_API is generated glue — do NOT add physics there
!
! When called from UEL (see PH_XXX_UEL.f90 header):
!   Multi-IP persistence is owned by PH_Elem_Base_State % svars(:); load/store
!   slices around each PH_XXX_UMAT_API call — do not assume the UEL passes a
!   distinct PH_Mat_State per IP without unpacking from svars.
!   Slice formulas + nsvars_total: ufc_core/L4_PH/contracts/CONTRACT_SVARS_IP_LAYOUT.md
!   statev slot table per mat_id: docs/05_Project_Planning/PPLAN/06_核心架构/UFC_UMAT_Props_Statev_Layout.md
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  PH_XXX_UMAT_API: 7 params (6 + pnewdt bare scalar, see §3.1 exception note)
!   SIO-02 ✓  _Impl last param is PH_XXX_UMAT_Args (INOUT unified bundle)
!   SIO-03 ✓  PH_XXX_UMAT_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!   NOTE: L4_PH hot-path (pnewdt bare scalar) is a documented ABI exception;
!         L5_RT Proc wrappers add the strict 6-param shell above this layer.
!===============================================================================
MODULE PH_XXX_UMAT
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Base types
  USE MD_Mat_Types,  ONLY: MD_Mat_Base_State, &  ! State base (PH extends)
                           MD_Mat_Base_Algo       ! Pre-analysis config
  !-- [MD] Model-specific Desc (defined in MD_Mat_XXX, NOT in MD_Mat_Types)
  USE MD_Mat_XXX,    ONLY: MD_Mat_XXX_Desc        ! Material parameters
  !-- [PH] Per-increment types
  USE PH_Mat_Types,  ONLY: PH_Mat_Base_Ctx,    &  ! Driving inputs per increment
                           PH_Mat_Base_Algo        ! Newton/convergence control
  !-- [RT] Runtime context only (pnewdt is now a bare scalar parameter)
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, &  ! Step/inc bookkeeping
                          RT_PNEWDT_NO_CHANGE  ! convenience init constant
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_XXX_State   ! L4_PH state type (export for unit tests / UEL)
  PUBLIC :: PH_XXX_UMAT_Args   ! Unified call-time IO bundle (SIO Principle #14)
  PUBLIC :: PH_XXX_UMAT_API    ! UFC-native UMAT entry (thin wrapper -> _Impl)
  ! NOTE: Module is named PH_XXX_UMAT (matching subroutine base name).
  !       All PUBLIC symbols must be declared explicitly (module uses PRIVATE default).
  !       PH_XXX_UMAT_Impl is PRIVATE — physics lives there; API is pure glue.

  !-----------------------------------------------------------------------------
  ! STATE type: PH-owned internal state variables.
  !   EXTENDS MD_Mat_Base_State which provides:
  !     stress(6), statev(:), ddsdde(6,6)  <- constitutive response
  !     stran(6),  dfgrd0(3,3)             <- history at increment START
  !     elastic_energy, plastic_work, ...  <- energy bookkeeping
  !     converged, iterations, status      <- convergence
  !
  !   Add model-specific internal variables below.
  !   Template placeholders ivar1/ivar2: replace with real ISVs, e.g.:
  !     peeq (equiv. plastic strain), D (damage), back_stress(6) (kinematic)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Mat_Base_State) :: PH_Mat_XXX_State
    !-- TODO: replace placeholders with actual model internal state variables
    !   REAL(wp) :: peeq           = 0.0_wp    ! Equiv. plastic strain   [-]
    !   REAL(wp) :: D              = 0.0_wp    ! Damage variable D       [0,1]
    !   REAL(wp) :: back_stress(6) = 0.0_wp    ! Kinematic back-stress   [Pa]
    REAL(wp) :: ivar1 = 0.0_wp     ! Placeholder ISV 1 — rename or replace
    REAL(wp) :: ivar2 = 0.0_wp     ! Placeholder ISV 2 — rename or replace
  END TYPE PH_Mat_XXX_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_UMAT_Args — unified bundle (Principle #14, L4 adaptation)
  !
  !   [IN]  scalars only on this TYPE — SIO-14: no ALLOCATABLE; SIO-13: no
  !         _Desc/_State/_Algo/_Ctx members (those stay as formal parameters).
!   [OUT] status, pnewdt, diagnostics — SIO-03: structured ErrorStatusType
!         status; initialize with init_error_status(...) and inspect via %status_code.
  !
  !   Usage (L5_RT / harness calling _Impl directly):
  !     TYPE(PH_XXX_UMAT_Args) :: umat_args
  !     umat_args%flag_nlgeom = RT_Com_Ctx%nlgeom
  !     umat_args%success     = .FALSE.
  !     CALL PH_XXX_UMAT_Impl(..., umat_args)
!     IF (umat_args%status%status_code == IF_STATUS_OK) pnewdt = umat_args%pnewdt
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_UMAT_Args
    !-- [IN]
    LOGICAL     :: flag_nlgeom   = .FALSE.
    LOGICAL     :: flag_firstinc = .FALSE.
    INTEGER(i4) :: ip_index      = 0_i4
    !-- TODO: model-specific [IN] (scalars / fixed arrays; POINTER ok per SIO-05)
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success      = .FALSE.
    REAL(wp)              :: pnewdt       = 1.0_wp
    REAL(wp)              :: residual_norm = 0.0_wp
    INTEGER(i4)           :: iterations   = 0_i4
    !-- TODO: model-specific [OUT] diagnostics; ALLOCATABLE allowed on [OUT] only
  END TYPE PH_XXX_UMAT_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH)
  !============================================================================
  !> PH_XXX_UMAT_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_UMAT_Args, delegates to PH_XXX_UMAT_Impl.
  !>   DO NOT add constitutive physics here; implement in PH_XXX_UMAT_Impl.
  !>
  !> Design notes:
  !>   - No flat arrays; all UMAT fields carried by typed structs
  !>   - state uses INTENT(INOUT) for in-place update (hot-path performance)
  !>   - Constitutive evolution: sigma_n -> sigma_{n+1}, kappa_n -> kappa_{n+1}
  !>   - pnewdt (bare REAL scalar, INOUT): step-ratio feedback; init to NO_CHANGE
  !>   - On error: PH_Mat_State%status carries details; pnewdt < 1.0 if auto_cut
  !>
  !> Calling convention (L5_RT solver, UFC native path):
  !>   TYPE(MD_Mat_XXX_Desc)     :: MD_Mat_Desc    ! pre-built once at model load
  !>   TYPE(PH_Mat_Base_Ctx)     :: PH_Mat_Ctx     ! filled from UEL at each call
  !>   TYPE(PH_Mat_XXX_State)    :: PH_Mat_State   ! per-IP state, evolves each increment
  !>   TYPE(MD_Mat_Base_Algo)    :: MD_Mat_Algo
  !>   TYPE(PH_Mat_Base_Algo)    :: PH_Mat_Algo
  !>   TYPE(RT_Com_Base_Ctx)     :: RT_Com_Ctx
  !>   REAL(wp)                  :: pnewdt         ! bare scalar, init RT_PNEWDT_NO_CHANGE
  !>
  !> Calling convention (ABAQUS UMAT adapter, in PH_Mat_XXX_XXX.f90 Sect.2):
  !>   packs 37 flat params -> structs -> CALL PH_XXX_UMAT_API(...) -> unpacks
  !>
  !> Parameters:
  !>   MD_Mat_Desc  [MD] material parameters (read-only, built once at model load)
  !>   PH_Mat_Ctx   [PH] driving inputs: dstran, dfgrd1, drot, temp, dtemp, predef
  !>   PH_Mat_State [PH] material state: sigma_n on entry; sigma_{n+1} on exit
  !>   MD_Mat_Algo  [MD] pre-analysis config: integration scheme, tangent flag
  !>   PH_Mat_Algo  [PH] per-increment iteration: max_iter, tolerance, cutback
  !>   RT_Com_Ctx   [RT] bookkeeping: kstep, kinc, elem_id, gauss_pt, nlgeom
  !>   pnewdt       [RT] REAL(wp) INOUT: step-ratio feedback
  !>                     init to RT_PNEWDT_NO_CHANGE (=1.0) before call
  !>                     < 1.0 => cut step; > 1.0 => allow larger step
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, &
      PH_Mat_Algo, RT_Com_Ctx, pnewdt)
    TYPE(MD_Mat_XXX_Desc),    INTENT(IN)    :: MD_Mat_Desc    ! [MD] parameters
    TYPE(PH_Mat_Base_Ctx),    INTENT(IN)    :: PH_Mat_Ctx     ! [PH] driving inputs
    TYPE(PH_Mat_XXX_State),   INTENT(INOUT) :: PH_Mat_State   ! [PH] state (in/out)
    TYPE(MD_Mat_Base_Algo),   INTENT(IN)    :: MD_Mat_Algo    ! [MD] analysis config
    TYPE(PH_Mat_Base_Algo),   INTENT(IN)    :: PH_Mat_Algo    ! [PH] iteration ctrl
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx     ! [RT] runtime context
    REAL(wp),                 INTENT(INOUT) :: pnewdt         ! [RT] step-ratio feedback

    TYPE(PH_XXX_UMAT_Args) :: umat_args

    umat_args%flag_nlgeom   = RT_Com_Ctx%nlgeom
    umat_args%flag_firstinc = RT_Com_Ctx%first_increment
    umat_args%ip_index      = RT_Com_Ctx%gauss_pt
    !-- TODO: fill any additional model-specific umat_args [IN] fields here

    umat_args%success = .FALSE.    ! always reset before delegate call

    CALL PH_XXX_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, MD_Mat_Algo, &
        PH_Mat_Algo, umat_args)

    pnewdt = umat_args%pnewdt
  END SUBROUTINE PH_XXX_UMAT_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all constitutive physics here
  !============================================================================
  !> PH_XXX_UMAT_Impl
  !>
  !>  Six-parameter inner interface (Principle #14 §3.1, L4 hot-path form).
  !>  Callers: PH_XXX_UMAT_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%flag_nlgeom   .TRUE. => use updated-Lagrangian branch (dfgrd1, drot)
  !>    args%flag_firstinc .TRUE. => cold-start initialization permitted
  !>    args%success       .TRUE. IFF the increment converged and state is valid
  !>    args%status        structured error/warning details
  !>    args%pnewdt        step-ratio feedback (<1 cut, >1 grow, =1 no change)
  !>    PH_Mat_State       updated in-place; undefined if args%success = .FALSE.
  SUBROUTINE PH_XXX_UMAT_Impl(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &
      MD_Mat_Algo, PH_Mat_Algo, args)
    TYPE(MD_Mat_XXX_Desc),  INTENT(IN)    :: MD_Mat_Desc
    TYPE(PH_Mat_Base_Ctx),  INTENT(IN)    :: PH_Mat_Ctx
    TYPE(PH_Mat_XXX_State), INTENT(INOUT) :: PH_Mat_State
    TYPE(MD_Mat_Base_Algo), INTENT(IN)    :: MD_Mat_Algo
    TYPE(PH_Mat_Base_Algo), INTENT(IN)    :: PH_Mat_Algo
    TYPE(PH_XXX_UMAT_Args), INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; no ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    REAL(wp)    :: D_el(6,6)         ! Isotropic elastic stiffness C^e  [Pa]
    REAL(wp)    :: stress_trial(6)   ! Trial stress sigma_trial          [Pa]
    REAL(wp)    :: f_yield           ! Yield function f(sigma, kappa)    [-]
    REAL(wp)    :: d_lambda          ! Incremental plastic multiplier     [-]
    INTEGER(i4) :: it                ! Return-mapping iteration counter
    INTEGER(i4) :: ntens             ! Active Voigt components (1..6)
    LOGICAL     :: map_ok            ! Return-mapping convergence flag

    !-------------------------------------------------------------------------
    ! Guard: validate ntens from MD_Mat_Algo (v4.1 contract)
    !-------------------------------------------------------------------------
    CALL init_error_status(args%status)
    args%success  = .FALSE.
    args%pnewdt   = RT_PNEWDT_NO_CHANGE
    args%iterations = 0
    args%residual_norm = 0.0_wp

    CALL init_error_status(PH_Mat_State%status)
    PH_Mat_State%converged  = .TRUE.
    PH_Mat_State%iterations = 0

    ntens = MD_Mat_Algo%ntens
    IF (ntens < 1 .OR. ntens > 6) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UMAT_Impl]: MD_Mat_Algo%ntens out of range [1,6]')
      PH_Mat_State%status = args%status
      RETURN
    END IF

    !-- Guard: Desc must be initialized (check mat_id sentinel or is_initialized flag)
    IF (.NOT. MD_Mat_Desc%is_initialized) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_UMAT_Impl]: MD_Mat_XXX_Desc not initialized (call InitFromProps first)')
      PH_Mat_State%status = args%status
      RETURN
    END IF

    !=========================================================================
    ! Step 1: Construct elastic stiffness C^e
    !   For isotropic small-strain:  C^e_{ijkl} = lam*delta_ij*delta_kl + 2*mu*I_sym
    !   Voigt 6x6: diag = [lam+2mu, lam+2mu, lam+2mu, mu, mu, mu]
    !              off-diag [1..3,1..3]: lam
    !   PH_Mat_Ctx%dstran  = Delta_eps (strain increment this step)
    !   PH_Mat_State%stran = eps_n     (total strain at START; from MD_Mat_Base_State)
    !   PH_Mat_State%dfgrd0= F_0       (deformation gradient at start, for NLGEOM)
    !   If args%flag_nlgeom: consider using PH_Mat_Ctx%dfgrd1 for push-forward
    !=========================================================================
    CALL XXX_Build_D_el(MD_Mat_Desc, D_el)

    !=========================================================================
    ! Step 2: Elastic predictor
    !   sigma_trial = sigma_n + C^e : Delta_eps
    !   NOTE: for finite strain, replace with appropriate push-forward of C^e
    !=========================================================================
    stress_trial(1:ntens) = PH_Mat_State%stress(1:ntens) &
                          + MATMUL(D_el(1:ntens,1:ntens), PH_Mat_Ctx%dstran(1:ntens))

    !=========================================================================
    ! Step 3: Yield check  f(sigma_trial, kappa_n) <= 0
    !   kappa_n = PH_Mat_State%ivar1  (or model-specific ISV — update field name)
    !=========================================================================
    f_yield = XXX_Yield_F(MD_Mat_Desc, stress_trial, PH_Mat_State%ivar1)

    IF (f_yield <= 0.0_wp) THEN
      !-- Elastic step: accept trial state
      PH_Mat_State%stress(1:ntens) = stress_trial(1:ntens)
      IF (MD_Mat_Algo%compute_tangent) &
        PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens)

    ELSE
      !-- Elasto-plastic step: Newton-Raphson return mapping
      !   Stub: map_ok remains .FALSE. until you implement the actual mapping.
      !   Steps to implement:
      !     a) Compute normal n = df/dsigma
      !     b) Consistency condition: f(sigma_trial - 2*mu*d_lambda*n, kappa + h*d_lambda) = 0
      !     c) Solve for d_lambda (scalar; 1-eq Newton)
      !     d) Update sigma_{n+1}, kappa_{n+1}
      !     e) Set map_ok=.TRUE. when |f_{n+1}| / sigma_y < ph_algo%tolerance
      d_lambda = 0.0_wp
      map_ok = .FALSE.
      DO it = 1, PH_Mat_Algo%max_iter
        !-- TODO: implement return mapping iteration body here
        PH_Mat_State%iterations = it
        EXIT  ! remove this EXIT once the loop body is implemented
      END DO
      args%iterations    = PH_Mat_State%iterations
      args%residual_norm = ABS(f_yield)  ! TODO: replace with actual post-NR residual

      IF (.NOT. map_ok) THEN
        PH_Mat_State%converged = .FALSE.
        CALL init_error_status(args%status, IF_STATUS_ERROR, &
            message='[XXX_UMAT_Impl]: return mapping stub — implement before use')
        PH_Mat_State%status = args%status
        IF (PH_Mat_Algo%auto_cut) args%pnewdt = PH_Mat_Algo%pnewdt_min
        RETURN
      END IF

      PH_Mat_State%converged = .TRUE.
      IF (MD_Mat_Algo%compute_tangent) THEN
        !-- TODO: compute consistent algorithmic tangent D_ep = D_el - correction
        !   For J2: D_ep = D_el - (2mu)^2 * n(x)n / (n:D_el:n + h)
        PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens) ! stub: elastic tangent
      END IF
    END IF

    !=========================================================================
    ! Step 4: Energy bookkeeping (optional; required for thermal coupling)
    !   Populate MD_Mat_Base_State energy scalars.
    !   See ABAQUS UMAT doc §3.1.1 for field semantics.
    !=========================================================================
    ! PH_Mat_State%elastic_energy = 0.5_wp * DOT_PRODUCT( &
    !     PH_Mat_State%stress(1:ntens), &
    !     PH_Mat_State%stran(1:ntens) + PH_Mat_Ctx%dstran(1:ntens))
    ! PH_Mat_State%plastic_work   = PH_Mat_State%plastic_work + d_lambda * sigma_bar
    ! PH_Mat_State%rpl            = taylor_quinney_coeff &
    !                             * PH_Mat_State%plastic_work / RT_Com_Ctx%dtime
    ! PH_Mat_State%drplde(1:ntens)= ...   ! ∂RPL/∂ε (for coupled thermo-mech)

    !-- Step 5: Update total strain history (stran_{n+1} = stran_n + dstran)
    PH_Mat_State%stran(1:ntens) = PH_Mat_State%stran(1:ntens) &
                                + PH_Mat_Ctx%dstran(1:ntens)

    !-- Finalise output
    args%success = .TRUE.
    args%pnewdt  = RT_PNEWDT_NO_CHANGE
    PH_Mat_State%status%status_code = IF_STATUS_OK
    args%status%status_code          = IF_STATUS_OK
  END SUBROUTINE PH_XXX_UMAT_Impl

  !============================================================================
  ! PRIVATE HELPERS
  !   Name pattern: XXX_<Verb>_<Noun>   (all PRIVATE; only _Impl calls these)
  !   Do NOT make helpers PUBLIC — callers must go through PH_XXX_UMAT_API.
  !============================================================================

  !> XXX_Build_D_el
  !>   Build isotropic elastic stiffness C^e in Voigt 6x6 notation.
  !>   Requires MD_Mat_XXX_Desc to expose lambda [Pa] and G [Pa].
  !>   If Desc stores (E, nu) instead, derive:
  !>     lam = E * nu / ((1+nu)*(1-2*nu))
  !>     mu  = E / (2*(1+nu))
  !>   For anisotropic or transversely-isotropic: replace entire body.
  SUBROUTINE XXX_Build_D_el(MD_Mat_Desc, D)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN)  :: MD_Mat_Desc
    REAL(wp),              INTENT(OUT) :: D(6,6)
    REAL(wp) :: lam, mu
    !-- TODO: replace with actual desc fields (lambda/G or derived from E/nu)
    lam = 0.0_wp   ! <- MD_Mat_Desc%lambda  [Pa]
    mu  = 0.0_wp   ! <- MD_Mat_Desc%G       [Pa]
    D = 0.0_wp
    !-- Voigt layout (1-based): [11,22,33,12,13,23] or [11,22,33,23,13,12]
    !   Check MD_Mat_Base_Algo%voigt_order for the convention used in this run.
    D(1,1) = lam + 2.0_wp*mu
    D(1,2) = lam
    D(1,3) = lam
    D(2,1) = lam
    D(2,2) = lam + 2.0_wp*mu
    D(2,3) = lam
    D(3,1) = lam
    D(3,2) = lam
    D(3,3) = lam + 2.0_wp*mu
    D(4,4) = mu
    D(5,5) = mu
    D(6,6) = mu
  END SUBROUTINE XXX_Build_D_el

  !> XXX_Yield_F
  !>   Evaluate yield function f(sigma, kappa).  f <= 0 => elastic domain.
  !>   PURE to enable compile-time inlining on hot path.
  !>   Replace body with the actual criterion for this material family:
  !>     ELA  — always returns a large negative number (no plasticity)
  !>     PLM J2 — von Mises: f = q - (sigma_y + H*kappa)
  !>     DMG LEMA — f = Y - Y_c  (energy release rate threshold)
  PURE FUNCTION XXX_Yield_F(MD_Mat_Desc, sigma, kappa) RESULT(f)
    TYPE(MD_Mat_XXX_Desc), INTENT(IN) :: MD_Mat_Desc
    REAL(wp),              INTENT(IN) :: sigma(6)  ! Cauchy stress   [Pa]
    REAL(wp),              INTENT(IN) :: kappa     ! Hardening variable (peeq, D, ...)
    REAL(wp) :: f, p, q
    !-- J2 von Mises reference (replace or extend for other criteria):
    !   Deviatoric: s = sigma - p*I;  p = trace(sigma)/3
    !   Effective:  q = sqrt(3/2 * s:s)
    !   Yield:      f = q - (sigma_y + H * kappa)
    p = (sigma(1)+sigma(2)+sigma(3)) / 3.0_wp
    q = SQRT(1.5_wp * ( (sigma(1)-p)**2 + (sigma(2)-p)**2 + (sigma(3)-p)**2 &
                       + 2.0_wp*(sigma(4)**2 + sigma(5)**2 + sigma(6)**2) ))
    !-- TODO: replace 0.0_wp with (desc%sigma_y + desc%H * kappa)
    f = q - 0.0_wp
  END FUNCTION XXX_Yield_F

END MODULE PH_XXX_UMAT

!===============================================================================
! STRUCT REFERENCE CARD — Four-type system  (Layer / Domain / Role)
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain  Role   Type name              Variable name    Key members
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) — model description, static, set once before analysis ──
!
!  MD  Mat   Desc  MD_Mat_XXX_Desc        MD_Mat_Desc
!    Concrete extension of MD_Mat_Base_Desc; holds model-specific parameters:
!      mat_id          [i4]  material ID constant (MAT_ID_XXX)
!      mat_family      [i4]  family enum (ELA/PLG/DMG/HYP/…)
!      model_name    [c64]  human-readable label
!      rho            [wp]  density [kg/m³]
!      is_initialized [L]   .TRUE. after InitFromProps
!      + XXX-specific parameters (E, nu, yield_stress, H, …)
!
!  MD  Mat   Algo  MD_Mat_Base_Algo       MD_Mat_Algo
!    Pre-analysis solver configuration; NOT per-increment:
!      integ_scheme   [i4]  1=implicit, 2=explicit, 3=midpoint
!      theta          [wp]  generalised mid-point θ  (0→explicit, 1→implicit)
!      ndi / nshr / ntens [i4]  Voigt layout (v4.1); default 3/3/6 for 3D solid
!      compute_tangent [L]  compute consistent tangent?
!      use_algorithmic [L]  algorithmic vs continuum tangent
!      print_debug     [L]  enable debug printout
!
!  MD  Elem  Desc  MD_Elem_Base_Desc      MD_Elem_Desc
!    Element topology / property descriptor:
!      ndofel  [i4]  total DOFs for this element
!      nsvars  [i4]  no. of state variables (storage in PH_Elem_Base_State)
!      nnode   [i4]  no. of nodes
!      mcrd    [i4]  max coordinates per node (2 or 3)
!      jtype   [i4]  element type flag (user-defined enum)
!      nprops  [i4]  length of props(:)
!      props   [wp,alloc]  real element properties
!      npredf  [i4]  no. of predefined field variables
!      mdload  [i4]  no. of distributed load entries
!      jdltyp  [i4,alloc]  distributed load type table  [mdload,*]
!      njprop  [i4]  length of jprops(:)
!      jprops  [i4,alloc]  integer element properties
!      is_initialized [L]
!
! ── PH layer (L4_PH) — physical computation, per-increment ──────────────────
!
!  PH  Mat   State PH_Mat_XXX_State       PH_Mat_State
!    Extends MD_Mat_Base_State; holds all material-point history + output:
!      stress(6)       [wp]  Cauchy stress σ  [Pa]    (in/out)
!      statev(:)       [wp,alloc]  solution-dep. ISVs      (in/out)
!      ddsdde(6,6)     [wp]  consistent tangent C_tan (out)
!      stran(6)        [wp]  strain at start of increment
!      dfgrd0(3,3)     [wp]  deformation gradient F₀ at start
!      elastic_energy  [wp]  SSE elastic strain energy density
!      plastic_work    [wp]  SPD plastic dissipation density
!      creep_dissip    [wp]  SCD creep dissipation density
!      rpl             [wp]  RPL volumetric heat generation rate
!      ddsddt(6)       [wp]  ∂σ/∂T  (NTENS components)
!      drplde(6)       [wp]  ∂RPL/∂ε
!      drpldt          [wp]  ∂RPL/∂T
!      converged       [L]   Newton convergence flag
!      iterations      [i4]  iteration count this increment
!      status          structured ErrorStatusType status
!      + XXX-specific ISVs  ivar1, ivar2, …
!
!  PH  Mat   Ctx   PH_Mat_Base_Ctx        PH_Mat_Ctx
!    Per-increment UMAT driving inputs ("where we are going"):
!      dstran(6)       [wp]  strain increment Δε
!      drot(3,3)       [wp]  rotation increment ΔR
!      dfgrd1(3,3)     [wp]  deformation gradient F₁ at end of increment
!      temp            [wp]  temperature at end of increment
!      dtemp           [wp]  temperature increment ΔT
!      predef(:)       [wp,alloc]  predefined field values at end
!      dpred(:)        [wp,alloc]  predefined field increments
!      coords(3)       [wp]  integration point coordinates
!      celent          [wp]  characteristic element length
!
!  PH  Mat   Algo  PH_Mat_Base_Algo       PH_Mat_Algo
!    Per-increment Newton-Raphson iteration control:
!      max_iter        [i4]  maximum Newton iterations  (default 100)
!      tolerance       [wp]  relative convergence tolerance  (1e-8)
!      abs_tol         [wp]  absolute tolerance floor        (1e-12)
!      pnewdt_min      [wp]  min acceptable pnewdt  (0.1)
!      pnewdt_max      [wp]  max allowed pnewdt growth (1.5)
!      auto_cut        [L]   auto cut step on non-convergence
!      line_search     [L]   enable line-search in Newton loop
!
!  PH  Elem  Ctx   PH_Elem_Base_Ctx       PH_Elem_Ctx
!    Per-increment UEL element driving inputs:
!      mat_ctx         PH_Mat_Base_Ctx  (embedded; filled from element fields)
!      coords(:,:)     [wp,alloc]  nodal coordinates  [mcrd, nnode]
!      du(:,:)         [wp,alloc]  displacement increment  [mlvarx, ndofel]
!      predef(:,:,:)   [wp,alloc]  predefined fields  [2, npredf, nnode]
!      adlmag(:,:)     [wp,alloc]  dist. load magnitudes at end  [mdload, nrhs]
!      ddlmag(:,:)     [wp,alloc]  dist. load increments  [mdload, nrhs]
!
!  PH  Elem  State PH_Elem_Base_State     PH_Elem_State
!    UEL outputs written back to solver:
!      rhs(:,:)        [wp,alloc]  residual force vector  [ndofel, nrhs]   (out)
!      amatrx(:,:)     [wp,alloc]  stiffness matrix  [ndofel, ndofel]      (out)
!      svars(:)        [wp,alloc]  solution-dep. state variables  [nsvars] (in/out)
!      energy(8)       [wp]  8-component energy contributions vector       (out)
!      u(:)            [wp,alloc]  total displacement  [ndofel]            (in)
!      v(:)            [wp,alloc]  velocity            [ndofel]            (in)
!      a(:)            [wp,alloc]  acceleration        [ndofel]            (in)
!
!  PH  Elem  Algo  ELIMINATED (v4.0)
!    Newmark/HHT-α parameters moved to RT_Com_Base_Ctx%newmark_params(3).
!    The framework injects them; UEL reads RT_Com_Ctx%newmark_params.
!
! ── RT layer (L5_RT) — runtime, shared by UMAT and UEL ─────────────────────
!
!  RT  Com   Ctx   RT_Com_Base_Ctx        RT_Com_Ctx
!    Increment bookkeeping + Newmark parameters (read-only from physics side):
!      time_step       [wp]  TIME(1)  step time at start of increment
!      time_total      [wp]  TIME(2)  total analysis time at start
!      dtime           [wp]  DTIME    increment time length Δt [s]
!      kstep           [i4]  KSTEP    step number (1-based)
!      kinc            [i4]  KINC     increment number within step
!      iter            [i4]  (derived) current equilibrium iteration
!      analysis_type   [i4]  1=static, 2=dynamic, 3=thermal, …
!      nlgeom          [L]   NLGEOM large-deformation flag
!      first_increment [L]   .TRUE. on very first increment of step
!      lflags(6)       [i4]  ABAQUS LFLAGS procedure/status flags
!      elem_id         [i4]  NOEL / JELEM  element number
!      gauss_pt        [i4]  integration point index within element
!      layer_id        [i4]  LAYER composite layer index
!      kspt            [i4]  KSPT  section point within layer
!      nrhs            [i4]  [UEL] NRHS  no. of RHS columns
!      mlvarx          [i4]  [UEL] MLVARX  max variable storage index
!      ndload          [i4]  [UEL] NDLOAD  no. of active dist. load types
!      period          [wp]  [UEL] PERIOD  analysis step period [s]
!      newmark_params(3) [wp] [β, γ, α]  Newmark/HHT-α (migrated from PH_Elem_Base_Algo)
!
!  pnewdt  REAL(wp) INOUT bare scalar  (replaces RT_Com_Base_Algo)
!    One-way step-ratio feedback signal from physics → ABAQUS framework:
!      < 1.0 → cut increment; > 1.0 → allow larger step; = 1.0 → no change
!      RT_PNEWDT_NO_CHANGE constant (from RT_Com_Types) → use for initialisation
!      In UEL: declare  REAL(wp) :: pnewdt_ip  for per-IP buffer; MIN across IPs
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================
